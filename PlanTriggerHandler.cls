/**
 * @description	 Handler class for PlanTrigger
 * @company		 Cloudwerx
 * @date	     13/05/2020
 * @testClass	 PlanTriggerHandlerTest
**/

public with sharing class PlanTriggerHandler{  
    private final static List <Milestone_Configurations__mdt> listOfMilestoneData = [SELECT QualifiedApiName, MasterLabel, Sort_Order__c, Milestone_Type__c
                                                                                          FROM Milestone_Configurations__mdt ORDER BY Sort_Order__c];
    private final static String initialMilestone =  listOfMilestoneData[0].Milestone_Type__c;
    private final static String recurringMilestone =  listOfMilestoneData[1].Milestone_Type__c;
    private final static String additionalMilestone =  listOfMilestoneData[2].Milestone_Type__c;
    public static final String PLAN_MANAGER_NDSP = 'NDSP';
    public static final String PLAN_MANAGER_MPM = 'MPM';

    /**
     * @description	 [TTP-2001] This method gets the list of plans on after insert/update and checks for overlapping dates
     * @author		 Sonali Bhat
     * @param	     listOfTriggerNew : list of new plans
     *               oldMap : old Map of Plans
     * @return	     NA
    **/
    public static void handleOverlappingOnAfterTrigger(List <Plan__c> listOfTriggerNew, Map <Id, Plan__c> oldMap){
        List <Plan__c> listOfCurrentPlansMPM = new List <Plan__c>();
        List <Plan__c> listOfCurrentPlansNDSP = new List <Plan__c>();
        Set<Id> currentNDSPPlanIds = new Set<Id>();
        Set<Id> currentMPMPlanIds = new Set<Id>();
        Set<Id> clientIdsNDSP = new Set<Id>();
        Set<Id> clientIdsMPM = new Set<Id>();
        Map<Id, List<Plan__c>> mapOfAccountWithNewPlansNDSP = new Map<Id, List<Plan__c>>();
        Map<Id, List<Plan__c>> mapOfAccountWithNewPlansMPM = new Map<Id, List<Plan__c>>();
        Map<Id, Plan__c> mapOfNDSPPlansToBeUpdated = new Map<Id, Plan__c>();
        Map<Id, Plan__c> mapOfMPMPlansToBeUpdated = new Map<Id, Plan__c>();
        
        for(Plan__c plan: listOfTriggerNew) {
            if (!oldMap.isEmpty()
                && oldMap.get(plan.Id).Plan_Start_Date__c != null && oldMap.get(plan.Id).Plan_End_Date__c != null 
                && plan.Plan_Start_Date__c != null && plan.Plan_End_Date__c != null 
                && (oldMap.get(plan.Id).Plan_Start_Date__c.isSameDay(oldMap.get(plan.Id).Plan_End_Date__c)) 
                && (!plan.Plan_Start_Date__c.isSameDay(plan.Plan_End_Date__c))
                && (plan.Invalid_1_Day_Plan__c)
            ) {
                //One day plan becomes non-one day plan
                if(String.isNotBlank(plan.PlanManager__c) && PLAN_MANAGER_NDSP.equalsIgnoreCase(plan.PlanManager__c)) {
                    Plan__c planNDSP = new Plan__c(Id = plan.Id, Invalid_1_Day_Plan__c = false);
                    mapOfNDSPPlansToBeUpdated.put(planNDSP.Id, planNDSP);
                }
                else if(String.isNotBlank(plan.PlanManager__c) && PLAN_MANAGER_MPM.equalsIgnoreCase(plan.PlanManager__c)) {
                    Plan__c planMPM = new Plan__c(Id = plan.Id, Invalid_1_Day_Plan__c = false);
                    mapOfMPMPlansToBeUpdated.put(planMPM.Id, planMPM);
                }
            }
            if(String.isNotBlank(plan.PlanManager__c) && PLAN_MANAGER_NDSP.equalsIgnoreCase(plan.PlanManager__c)) {
                listOfCurrentPlansNDSP.add(plan);
                currentNDSPPlanIds.add(plan.Id);
                clientIdsNDSP.add(plan.Client_Name__c);
                if(mapOfAccountWithNewPlansNDSP.containsKey(plan.Client_Name__c)) {
                    mapOfAccountWithNewPlansNDSP.get(plan.Client_Name__c).add(plan);
                } else {
                    mapOfAccountWithNewPlansNDSP.put(plan.Client_Name__c, new List <Plan__c>{plan});
                }
            }
            else if(String.isNotBlank(plan.PlanManager__c) && PLAN_MANAGER_MPM.equalsIgnoreCase(plan.PlanManager__c)) {
                listOfCurrentPlansMPM.add(plan);
                currentMPMPlanIds.add(plan.Id);
                clientIdsMPM.add(plan.Client_Name__c);
                if(mapOfAccountWithNewPlansMPM.containsKey(plan.Client_Name__c)) {
                    mapOfAccountWithNewPlansMPM.get(plan.Client_Name__c).add(plan);
                } else {
                    mapOfAccountWithNewPlansMPM.put(plan.Client_Name__c, new List <Plan__c>{plan});
                }
            }
        }

        if(clientIdsMPM?.size() > 0 && listOfCurrentPlansMPM?.size() > 0){
            PlanTriggerHandler.verifyOverlappingDates(listOfCurrentPlansMPM, clientIdsMPM, currentMPMPlanIds, mapOfAccountWithNewPlansMPM, mapOfMPMPlansToBeUpdated, PLAN_MANAGER_MPM);
        }
        if(clientIdsNDSP?.size() > 0 && listOfCurrentPlansNDSP?.size() > 0){
            PlanTriggerHandler.verifyOverlappingDates(listOfCurrentPlansNDSP, clientIdsNDSP, currentNDSPPlanIds, mapOfAccountWithNewPlansNDSP,mapOfNDSPPlansToBeUpdated, PLAN_MANAGER_NDSP);
        }
    }
    
    /**
     * @description	 [TTP-2001] This method updates the invalid one day plan attribute of existing single day plans
     * @author		 Sonali Bhat
     * @param	     listOfCurrentPlans : list of current plans
     *               setOfClientIds : set of client ids for which plans are being synced
     *               setOfCurrentPlanIds : set of existing plan ids
     *               mapOfAccountWithNewPlans : map of account with the new plans
     *               mapOfPlansToBeUpdated : map of plan records to be updated
     * @return	     NA
    **/
    public static void verifyOverlappingDates(List <Plan__c> listOfCurrentPlans, Set <Id> setOfClientIds, Set <Id> setOfCurrentPlanIds, Map<Id, List<Plan__c>> mapOfAccountWithNewPlans, Map<Id, Plan__c> mapOfPlansToBeUpdated, String planManager){
        Map <Id, List <Plan__c>> mapOfAccountWithExistingPlans = new Map <Id, List <Plan__c>>();
        // List of Existing Plans
        List <Plan__c> listOfExistingPlans = [SELECT Id, Plan_Start_Date__c, Plan_End_Date__c, Client_Name__c, Invalid_1_Day_Plan__c FROM Plan__c 
                                              WHERE Client_Name__c IN: setOfClientIds 
                                              AND ID NOT IN : setOfCurrentPlanIds AND PlanManager__c =: planManager Limit 50000]; //ACEM-2 Added query limit

        if(!listOfExistingPlans.IsEmpty()) {
            for(Plan__c plan: listOfExistingPlans) {
                if(mapOfAccountWithExistingPlans.containsKey(plan.Client_Name__c)) {
                    mapOfAccountWithExistingPlans.get(plan.Client_Name__c).add(plan);
                }
                else {
                    mapOfAccountWithExistingPlans.put(plan.Client_Name__c, new List <Plan__c>{plan});
                }
            }
        }
            
        for(Plan__c plan : listOfCurrentPlans) {
            List<Plan__c> newList = new List<Plan__c>();
            if(mapOfAccountWithExistingPlans.containsKey(plan.Client_Name__c)) {
                // existing plan records of client
                newList.addAll(mapOfAccountWithExistingPlans.get(plan.Client_Name__c));
            }
            if (mapOfAccountWithNewPlans.containsKey(plan.Client_Name__c) && mapOfAccountWithNewPlans.get(plan.Client_Name__c).size() >1) {
                // new plan records of client
                newList.addAll(mapOfAccountWithNewPlans.get(plan.Client_Name__c));
            }
            if (!newList.isEmpty()) {
                validatePlan(plan, newList, mapOfPlansToBeUpdated);  // check overlapping
            }   
        }
        
        if(!mapOfPlansToBeUpdated.isEmpty()) {
            try {
                update mapOfPlansToBeUpdated.values();
            } catch(Exception ex) {
                System.debug('following error occurred while updating One day plans'+ex);
            }
        }
    }
    
    /**
     * @description	 [TTP-2001] It displays error if plan overlapping found
     * @author		 Sonali Bhat
     * @param	     currentPlan : plan record to validate
     *               existingPlans : existing plan record for the current plan client
     *               mapOfPlansToBeUpdated : map of plan records to be updated
     * @return	     NA
    **/
    private static void validatePlan(Plan__c currentPlan, List <Plan__c> existingPlans, Map<Id, Plan__c> mapOfPlansToBeUpdated){
        Boolean found = false;
        for(Plan__c existingPlan : existingPlans) {
            // Plan Overlapping condition
            if(
                currentPlan.Id != existingPlan.Id &&
                ((currentPlan.Plan_Start_Date__c >= existingPlan.Plan_Start_Date__c && currentPlan.Plan_Start_Date__c <= existingPlan.Plan_End_Date__c)
                || (currentPlan.Plan_End_Date__c >= existingPlan.Plan_Start_Date__c && currentPlan.Plan_End_Date__c <= existingPlan.Plan_End_Date__c)
                || (currentPlan.Plan_Start_Date__c < existingPlan.Plan_Start_Date__c &&  currentPlan.Plan_End_Date__c > existingPlan.Plan_End_Date__c))
                ) {
                    // Plan OverLaps
                    if((currentPlan.Plan_Start_Date__c != NULL && currentPlan.Plan_End_Date__c != NULL)
                        && currentPlan.Plan_Start_Date__c.isSameDay(currentPlan.Plan_End_Date__c)
                    ) {
                        // current plan is a one day plan
                        Plan__c temp = new Plan__c(Id = currentPlan.Id,Invalid_1_Day_Plan__c = true);
                        mapOfPlansToBeUpdated.put(temp.Id, temp);
                        if( existingPlan.Plan_Start_Date__c != NULL && existingPlan.Plan_End_Date__c != NULL
                            && existingPlan.Plan_Start_Date__c.isSameDay(existingPlan.Plan_End_Date__c) && !existingPlan.Invalid_1_Day_Plan__c
                        ) {
                            // Existing Overlapped Plan is also one day plan
                            Plan__c temp1 = new Plan__c(Id = existingPlan.Id,Invalid_1_Day_Plan__c = true);
                            mapOfPlansToBeUpdated.put(temp1.Id, temp1);
                        }
                    } else {
                        // current plan is not a one day plan
                        if( existingPlan.Plan_Start_Date__c != NULL && existingPlan.Plan_End_Date__c != NULL
                            && existingPlan.Plan_Start_Date__c.isSameDay(existingPlan.Plan_End_Date__c)
                        ) {
                            // Existing Overlapped Plan is a one day plan
                            if (!existingPlan.Invalid_1_Day_Plan__c) {
                                Plan__c temp2 = new Plan__c(Id = existingPlan.Id,Invalid_1_Day_Plan__c = true);
                                mapOfPlansToBeUpdated.put(temp2.Id, temp2);
                            }
                        } else {
                            // Existing Overlapped Plan is not a one day plan
                            found = true;
                            if (!mapOfPlansToBeUpdated.isEmpty() && mapOfPlansToBeUpdated.containsKey(currentPlan.Id)) 
                                mapOfPlansToBeUpdated.remove(currentPlan.Id);
                        }
                    }
            }
        }
        if(found) {
            currentPlan.addError(Label.Plan_Dates_Overlap_Error);
        }
    }

    /**
     * @description	 [TTP-1274] Method to create milestones for Plans on after insert
     * @author		 
     * @param	     listOfNewPlans : list of new plan records
     * @return	     NA
    **/
    public static void afterInsertOfPlan(List <Plan__c> listOfNewPlans) {
        Set<Id> setOfClientIds = new Set<Id>();
        List<Plan__c> listOfQLDPlans = new List<Plan__c>();
        String pods = System.Label.PodName;
        List<String> podNames = pods.split(',');  // Split Pod Names present in custom label

        List<Plan__c> listOfPlans = [SELECT Id, Client_Name__c, Client_Name__r.Pod__c, Client_Name__r.Pod_Name__c, Plan_Start_Date__c,  
                                     Plan_End_Date__c, CreatedDate, Active__c, Budget_Conversation_Milestone_Preference__c FROM Plan__c 
                                     WHERE Id IN : listOfNewPlans 
                                     AND Active__c = true 
                                     AND Client_Name__r.Pod__c != null
                                     AND Client_Name__r.Pod_Name__c IN : podNames];
        
        // If Plans found with matching pods in custom label
        if(!listOfPlans.isEmpty()) {
            for(Plan__c plan : listOfPlans) {
                setOfClientIds.add(plan.Client_Name__c); // set of Client Ids
            }

            // get list of milestones to be inserted
            List<Milestone__c> listOfMilestones = getListOfMilestonesToInsert(listOfPlans,setOfClientIds); 
            if(!listOfMilestones.isEmpty()) {
                try {
                    insert(listOfMilestones);
                } catch (Exception ex) {
                    System.debug('cannot insert milestones'+ex.getMessage());
                }
            }
        }
    }

    /**
     * @description	 [TTP-1274] Returns list of Milestones to be created for plans
     * @author		 
     * @param	     listOfPlans : list of plan records
     *               setOfClientIds : set of client ids
     * @return	     List<Milestone__c>
    **/
    public static List<Milestone__c>  getListOfMilestonesToInsert(List<Plan__c> listOfPlans, Set<Id> setOfClientIds) {
        Map<Id, List<Id>> mapOfClientWithPrimaryCon = new Map<Id, List<Id>>();
        List<Milestone__c> listOfMilestones = new List<Milestone__c>();
        mapOfClientWithPrimaryCon = getPrimaryContacts(setOfClientIds); // Get Map of Account with Primary Contacts

        for(Plan__c p : listOfPlans) {
            // find the difference between plan created date and plan end date
            Double planDateDiff = p.CreatedDate.date().daysBetween(p.Plan_End_Date__c); 
            Double noOfMonths = math.ceil(planDateDiff/30.0);
            Double noOfYears = integer.valueOf(math.ceil(noOfMonths/12.0));  // Number of diff in years between dates
            Boolean isBudgetConvSelected = true;
            Date planCreatedDate =  p.CreatedDate.date();
            Date budgetConvDate;
            // Iterate over number of years in a plan
            for (integer i = 0; i<noOfYears; i++) {
                if(p.Budget_Conversation_Milestone_Preference__c == System.Label.ScheduleConversation 
                    && isBudgetConvSelected 
                    && !system.isBatch()) { 
                        /* Budget Conversation for first year */
                            isBudgetConvSelected = false;
                            budgetConvDate = p.CreatedDate.date();
                            budgetConvDate = budgetConvDate.addDays(14);
                            Milestone__c mileObj = createMilestones(p,initialMilestone,budgetConvDate,mapOfClientWithPrimaryCon);
                            if(mileObj.Due_Date__c >= System.Today() && mileObj.Due_Date__c <= p.Plan_End_Date__c) {
                                listOfMilestones.add(mileObj);
                            }
                }
                if(i > 0) {
                    /* Budget Conversation for following years */
                    budgetConvDate = planCreatedDate.addDays(14);
                    Milestone__c mileObj = createMilestones(p,initialMilestone,budgetConvDate,mapOfClientWithPrimaryCon);
                    if(mileObj.Due_Date__c >= System.Today() && mileObj.Due_Date__c <= p.Plan_End_Date__c) {
                        listOfMilestones.add(mileObj);
                    }
                }
                /* 9 month conversation */
                /* if Budget Conversation is present for the year, 
                * then add 9 months to it, 
                * else add 9 months to plan created date 
                */
                Date dueDate = budgetConvDate != null ? budgetConvDate.addMonths(9): planCreatedDate.addMonths(9);
                Milestone__c mileObj = createMilestones(p,recurringMilestone,dueDate,mapOfClientWithPrimaryCon);
                if(mileObj.Due_Date__c >= System.Today() && mileObj.Due_Date__c <= p.Plan_End_Date__c) {
                    listOfMilestones.add(mileObj);
                }
                planCreatedDate = planCreatedDate.addYears(1);  
            }
        }
        return listOfMilestones;
    }

    /**
     * @description	 [TTP-898] This Method sets the Milestone fields with values
     * @author		 Rohit
     * @param	     plan : plan record
     *               milestoneType : milestone Type as String
     *               dueDate : date 
     *               mapOfClientWithPrimaryCon : map of client with their primary contact ids
     * @return	     Milestone__c
    **/
    public static Milestone__c createMilestones(Plan__c plan, String milestoneType, Date dueDate, Map<Id, List<Id>> mapOfClientWithPrimaryCon){
        List<Milestone__c> listOfMilestonerecords = new List<Milestone__c>();
        Milestone__c milestoneObj = new Milestone__c();
        milestoneObj.Plan__c = plan.Id;
        milestoneObj.Client__c = plan.Client_Name__c;
        milestoneObj.Milestone_Type__c = milestoneType;
        milestoneObj.Due_Date__c = getDueDate(dueDate);
        if(mapOfClientWithPrimaryCon.containsKey(plan.Client_Name__c)) {
            List<Id> listOfPrimaryConId = mapOfClientWithPrimaryCon.get(plan.Client_Name__c);
            if(listOfPrimaryConId.size() == 1) {
               milestoneObj.Primary_Contact__c = listOfPrimaryConId[0];  
            }
        }
        return milestoneObj;
    }

    /**
     * @description	 [TTP-898] This Method check the due date of milestone and returns non-weekend date
     * @author		 Rohit
     * @param	     dueDate : date
     * @return	     Date : due date after weekend
    **/
    public static Date getDueDate (Date dueDate) {
        Date getDate = dueDate;
        DateTime dt =(DateTime)getDate;
        String dayOfWeek = dt.format('EEEE');
        if(dayOfWeek == 'Saturday') {
            getDate = getDate +2;
        }
        else if(dayOfWeek == 'Sunday') {
            getDate = getDate+1;
        }
        return getDate;
    }

    /**
     * @description	 [TTP-898] This Method is called on delete of plan records and delete Milestones
     * @author		 Rohit
     * @param	     listOfPlan : list of plans
     * @return	     NA
    **/
    public static void onBeforeDeleteOfPlan(List<Plan__c> listOfPlan) {
        List<Milestone__c> listOfMilestones = [SELECT Id FROM Milestone__c WHERE Plan__c IN: listOfPlan];
        if(!listOfMilestones.isEmpty()) {
            try {
                delete(listOfMilestones);
            } catch(Exception ex) {
                System.debug('cannot delete milestones'+ex);
            }
        }
    }

    /**
     * @description	 [TTP-1285] This Method is called on update of plan end date and adjusts the milestones on plan
     * @author		 
     * @param	     listOfUpdatedPlans : list of plans
     * @return	     NA
    **/
    public static void afterUpdateOfPlan(List<Plan__c> listOfUpdatedPlans) {
        Map<Id, Plan__c> mapOfActivePlans = new Map<Id, Plan__c>();
        Map<Id, Plan__c> mapOfInactivePlans = new Map<Id, Plan__c>();
        Set<Id> setOfClientIds = new Set<Id>();

        List<Milestone__c> listOfMilestonesToBeDeleted = new List<Milestone__c>();
        List<Milestone__c> listOfMilestonesToBeCreated = new List<Milestone__c>();

        Map<Id, List<Milestone__c>> mapOfPlansWithActualMilestones = new Map<Id, List<Milestone__c>>();
        Map<Id, List<Milestone__c>> mapOfPlansWithExistingMilestones = new Map<Id, List<Milestone__c>>();

        String pods = System.Label.PodName;
        List<String> podNames = pods.split(',');  // Split Pod Names present in custom label

        // if any plan is found that belong to Pods present in custom label
        List<Plan__c> listOfPlans = [SELECT Id, Client_Name__c, Client_Name__r.Pod__c, Client_Name__r.Pod_Name__c, Plan_Start_Date__c,  
                                     Plan_End_Date__c, CreatedDate, Active__c, Budget_Conversation_Milestone_Preference__c FROM Plan__c 
                                     WHERE Id IN : listOfUpdatedPlans 
                                     AND Client_Name__r.Pod_Name__c IN : podNames];
        
        if(!listOfPlans.isEmpty()) {
            for(Plan__c p : listOfPlans) {
                if(p.Active__c) {
                    mapOfActivePlans.put(p.Id, p);
                    setOfClientIds.add(p.Client_Name__c);
                } else {
                    MapOfInactivePlans.put(p.Id, p);
                } 
            }

            // query milestones of inactive plans
            if(!MapOfInactivePlans.isEmpty()) {
                List<Milestone__c> listOfToDoMilestones = [SELECT Id, Plan__c, Milestone_Type__c, Status__c, Due_Date__c FROM Milestone__c 
                                                           WHERE Plan__c IN : MapOfInactivePlans.keySet()
                                                           AND Status__c = 'To Do'];
                if (!listOfToDoMilestones.isEmpty()) {
                    listOfMilestonesToBeDeleted.addAll(listOfToDoMilestones);  // add milestones of inactive plans
                } 
            }

            // List of Actual Milestones to be present on plan
            List<Milestone__c> listOfActualMilestones = getListOfMilestonesToInsert(mapOfActivePlans.values(),setOfClientIds);
            // List of Existing Milestones to be present on plan
            List<Milestone__c> listOfExistingMilestones = [SELECT Id, Plan__c, Milestone_Type__c, Status__c, Due_Date__c FROM Milestone__c 
                                                           WHERE Plan__c IN : mapOfActivePlans.keySet()
                                                           AND Milestone_Type__c !=: additionalMilestone
                                                           ORDER BY Due_Date__c ASC];
            
            // create Map of Plans with actual Milestones                                                
            for (Milestone__c mile : listOfActualMilestones) {
                if(mapOfPlansWithActualMilestones.containsKey(mile.Plan__c)) {
                    mapOfPlansWithActualMilestones.get(mile.Plan__c).add(mile);
                }
                else {
                    mapOfPlansWithActualMilestones.put((mile.Plan__c), new List <Milestone__c>{mile});
                }
            }

            // create Map of Plans with existing Milestones                                                
            for (Milestone__c mile : listOfExistingMilestones) {
                if(mapOfPlansWithExistingMilestones.containsKey(mile.Plan__c)) {
                    mapOfPlansWithExistingMilestones.get(mile.Plan__c).add(mile);
                }
                else {
                    mapOfPlansWithExistingMilestones.put((mile.Plan__c), new List <Milestone__c>{mile});
                }
            }

            // compare the milestones from both maps 
            for (Id planId : mapOfActivePlans.keySet()) {
                Plan__c plan = mapOfActivePlans.get(planId);
                if(!mapOfPlansWithExistingMilestones.containsKey(planId) && mapOfPlansWithActualMilestones.containsKey(planId)) {
                    /*  scenario  : 1 
                        condition : Existing Milestones list is empty and actual milestone list is not empty 
                        outcome   : create new milestones
                    */
                    List<Milestone__c> listOfNewMilestones = mapOfPlansWithActualMilestones.get(planId);
                    listOfMilestonesToBeCreated.addAll(listOfNewMilestones);  
                } else if(mapOfPlansWithExistingMilestones.containsKey(planId) && !mapOfPlansWithActualMilestones.containsKey(planId)) {
                    /*  scenario  : 2
                        condition : existing milestones list is not empty and actual milestone list is empty, 
                        outcome   : delete all existing milestones
                    */
                    List<Milestone__c> listOfexistingMiles = mapOfPlansWithExistingMilestones.get(planId);
                    listOfMilestonesToBeDeleted.addAll(listOfexistingMiles);  
                } else if (mapOfPlansWithExistingMilestones.containsKey(planId) && mapOfPlansWithActualMilestones.containsKey(planId)) {
                     /* scenario  : 3
                        condition : existing milestones list is not empty and actual milestone list is not empty, 
                        outcome   : compare the milestones and create/delete as per the plan length
                    */
                    List<Milestone__c> listOfExistingMiles = mapOfPlansWithExistingMilestones.get(planId);
                    List<Milestone__c> listOfActualMiles = mapOfPlansWithActualMilestones.get(planId);
                   
                    if(listOfExistingMiles.size() > listOfActualMiles.size()) {
                        // plan is shortened, delete extra milestones
                        listOfMilestonesToBeDeleted.addAll(handleMilestones(listOfExistingMiles,listOfActualMiles, 'delete'));

                    } else if (listOfExistingMiles.size() < listOfActualMiles.size()) {
                        // plan is extended, create more milestones
                        listOfMilestonesToBeCreated.addAll(handleMilestones(listOfExistingMiles,listOfActualMiles, 'add'));
                    }
                }
            }

            if(!listOfMilestonesToBeDeleted.isEmpty()) {
                List<Milestone__c> listOfdelMilestones = new List<Milestone__c>();
                for(Milestone__c mile :listOfMilestonesToBeDeleted ) {
                    if(mile.Status__c == 'To Do') { // only to do milestones need to be deleted
                        listOfdelMilestones.add(mile);
                    }
                }
                if(!listOfdelMilestones.isEmpty()) {
                    try {
                        delete listOfdelMilestones;
                    } catch (Exception ex) {
                        System.debug('error occurred while deleting To Do milestones'+ex);
                    }
                }
            }

            if(!listOfMilestonesToBeCreated.isEmpty()) {
                try {
                    insert listOfMilestonesToBeCreated;
                } catch (Exception ex) {
                    System.debug('error occurred while creating new milestones'+ex);
                }
            }
        }
    }

    /**
     * @description	 [TTP-1285] This Method returns the list of extra milestones to be deleted/added when plan shortens/extends
     * @author		 
     * @param	     listOfExistingMiles : list of existing Milestone__c
     *               listOfActualMiles : list of Milestone__c
     *               operation : dml operation
     * @return	     List<Milestone__c>
    **/
    public static List<Milestone__c> handleMilestones(List<Milestone__c> listOfExistingMiles, List<Milestone__c> listOfActualMiles, String operation) {
        integer counter;
        List<Milestone__c> listOfMilestones = new List<Milestone__c>();
        List<Milestone__c> listOfExtraMilestones = new List<Milestone__c>();

        if(operation == 'delete') { // plan shortened
            counter = listOfActualMiles.size();
            listOfMilestones.addAll(listOfExistingMiles);
        } else if(operation == 'add') { // plan extended
            counter = listOfExistingMiles.size();
            listOfMilestones.addAll(listOfActualMiles);
        }
        for(integer i = counter ; i< listOfMilestones.size(); i++) {
            listOfExtraMilestones.add(listOfMilestones[i]); 
        }
        return listOfExtraMilestones;
    }

    /**
     * @description	 [SFDC-869] [SFDC-898] This method returns the list of Primary Contacts related to Client
     * @author		 
     * @param	     setOfClientIds : set of client ids
     * @return	     Map<Id, List<Id>> : account id Vs List of Account Contact Relation id
    **/
    public static Map<Id, List<Id>> getPrimaryContacts(Set<Id> setOfClientIds) { 
        List<AccountContactRelation> listOfACR = [SELECT Id, AccountId, ContactId ,Primary_Contact__c FROM AccountContactRelation WHERE AccountId IN : setOfClientIds
                                                    AND Primary_Contact__c = true];
        
        Map<Id, List<Id>> mapOfClientWithPrimaryCon = new Map<Id, List<Id>>();

        // Get a Map of Accounts With Primary Contacts
        if(!listOfACR.isEmpty()) {
            for(AccountContactRelation acr : listOfACR) {
                if(mapOfClientWithPrimaryCon.containsKey(acr.AccountId)) {
                    mapOfClientWithPrimaryCon.get(acr.AccountId).add(acr.ContactId);
                }
                else {
                    mapOfClientWithPrimaryCon.put(acr.AccountId, new List<Id>{acr.ContactId});
                }
            }
        }
        return mapOfClientWithPrimaryCon;
    }

    /**
     * @description	 [AHOD-571] [AHOD-722] This method updates Client Budget Preference(PlanSupportPreference__c) records
     * @author		 Sonali Bhat 
     * @param	     newMap : new map of plan
     *               oldMap : old map of plan
     * @return	     NA
    **/
    public static void updatePlanSupportPreferences(Map<Id, Plan__c> newMap, Map<Id, Plan__c> oldMap) {
        List<PlanSupportPreference__c> listOfUpdatePSPs = new List<PlanSupportPreference__c>();

        List<PlanSupportPreference__c> listOfAllPSPs = [SELECT Id, 
                                                                Plan__c, Plan__r.Plan_End_Date__c,
                                                                EndDate__c, RecordTypeId
                                                                FROM PlanSupportPreference__c
                                                        WHERE Plan__c IN : newMap.keySet()];

        for (PlanSupportPreference__c psp : listOfAllPSPs) {

            if (newMap.get(psp.Plan__c).Plan_End_Date__c < oldMap.get(psp.Plan__c).Plan_End_Date__c) {
                
                /*scenario 1 
                    if plan duration is shortened,
                    update all child PSPs where end date is matching with old plan end date
                */
                if (psp.EndDate__c == oldMap.get(psp.Plan__c).Plan_End_Date__c) {
                    psp.EndDate__c = psp.plan__r.Plan_End_Date__c;
                    listOfUpdatePSPs.add(psp);
                }

            } else if (newMap.get(psp.Plan__c).Plan_End_Date__c > oldMap.get(psp.Plan__c).Plan_End_Date__c) {
                
                /*scenario 2 
                    if plan duration is extended,
                    update all Claim As PSPs where end date is matching with old plan end date
                */
                if (psp.EndDate__c == oldMap.get(psp.Plan__c).Plan_End_Date__c 
                    && psp.RecordTypeId == RecordTypeUtil.PSP_SUBSTITUTION_RECORD_TYPE_ID
                ) {
                    psp.EndDate__c = psp.plan__r.Plan_End_Date__c;
                    listOfUpdatePSPs.add(psp);
                }
            }
        }

        if (!listOfUpdatePSPs.isEmpty()) {
            // update PSPs
            try {
                update listOfUpdatePSPs;
            } catch (Exception ex) {
                System.debug('cannot update Plan Support Preferences'+ex);
            }
        }
    }
}