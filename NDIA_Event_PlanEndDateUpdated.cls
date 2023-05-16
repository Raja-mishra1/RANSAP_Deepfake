/**
 * @description      [TTP-230] Apex Trigger Handler for NDIA_Notification__e Platform Event Object
 * @company          Cloudwerx
 * @date             30/08/2021
 * @testClass        NDIA_Event_PlanEndDateUpdatedTest
**/
public without sharing class NDIA_Event_PlanEndDateUpdated implements NDIA_NotificationHandler{
    
    Map <String,NDIA_NotificationDTO.PlanDateUpdate> prodaIdVsNotificationMap = new Map <String,NDIA_NotificationDTO.PlanDateUpdate>();
    public static List<EventLog__e> dmlLogs;

   /**
    * @description     Method parses the Data received from the platform Event & calls method for further processing
    * @author          Rohit Tikoo
    * @param           listOfResponse : List of messages published to platform Event Json 
   **/  
    public void run(List <String> listOfResponse) {
        List<EventLog__e> errorLogs = new List <EventLog__e>();
        NDIA_NotificationHelper.eventName = 'PLAN_END_DT_UPDATED'; // static variable used to pass the event name

        for (String rawResponse : listOfResponse) {
            try {
                NDIA_NotificationDTO.PlanDateUpdate planWrapperObj = NDIA_NotificationDTO.parsePlanInfo(rawResponse);

                if (planWrapperObj.planId != null && planWrapperObj.planId != '') { //plan Id check

                    if (!NDIA_NotificationHelper.verifyDateFormat(planWrapperObj.startDate)) {
                        EventLog__e event = LogService.logSaveResult(
                            'NDIA_Event_PlanEndDateUpdated', 'run', 'Start Date is invalid : ' + planWrapperObj.startDate, '', 
                            NDIA_NotificationHelper.eventName, planWrapperObj.event_replay_id);
                        event.HTTPResponse__c = rawResponse;
                        errorLogs.add(event);
                    } else if (!NDIA_NotificationHelper.verifyDateFormat(planWrapperObj.endDate)) {
                        EventLog__e event = LogService.logSaveResult(
                            'NDIA_Event_PlanEndDateUpdated', 'run', 'End Date is invalid : ' + planWrapperObj.endDate, '', 
                            NDIA_NotificationHelper.eventName, planWrapperObj.event_replay_id);
                        event.HTTPResponse__c = rawResponse;
                        errorLogs.add(event);
                    } else if (!NDIA_NotificationHelper.verifyDateFormat(planWrapperObj.birthDate)) {
                        EventLog__e event = LogService.logSaveResult(
                            'NDIA_Event_PlanEndDateUpdated', 'run', 'Birth Date is invalid : ' + planWrapperObj.birthDate, '', 
                            NDIA_NotificationHelper.eventName, planWrapperObj.event_replay_id);
                        event.HTTPResponse__c = rawResponse;
                        errorLogs.add(event);
                    } else {
                        prodaIdVsNotificationMap.put(planWrapperObj.planId,planWrapperObj);
                        // static map of plan Id with Notification Event Replay Id 
                        NDIA_NotificationHelper.uniqueIdVsReplayIdMap.put(planWrapperObj.planId, planWrapperObj.event_replay_id);
                        // static map of plan id with Event Response
                        NDIA_NotificationHelper.uniqueIdVsEventResponseMap.put(planWrapperObj.planId, rawResponse);
                    }                    
                } else {
                    // plan id is not present
                    EventLog__e event = LogService.logSaveResult(
                    'NDIA_Event_PlanEndDateUpdated', 'run', 'Plan Id is blank in the event json response', '', 
                    NDIA_NotificationHelper.eventName, planWrapperObj.event_replay_id);
                    event.HTTPResponse__c = rawResponse;
                    errorLogs.add(event);
                }
            } catch (Exception e) {
                // parsing error
                EventLog__e event = LogService.logSaveResult(
                        'NDIA_Event_PlanEndDateUpdated', 'run', 'Parsing Error - ' + e.getMessage(), '', 
                        NDIA_NotificationHelper.eventName, '');
                event.HTTPResponse__c = rawResponse;
                errorLogs.add(event);
            }
        }

        if (!errorLogs.isEmpty()) {
            LogService.insertLog(errorLogs);
        }

        processResponse();
    }

    /**
     * @description         Method upserts plan End Date with Data received from the platform Event
     * @author              Rohit Tikoo           
    **/   
    public void processResponse() {
        List<Plan__c> planList = new List<Plan__c>(); // Plan List to upsert the plan records
        Set<Id> updatedPlanIdSet = new Set<Id>(); //Plan ID set which contains plan ID of successful Plans
        Set<String> prodaObjectIdSet = new Set<String>(); //To Store Proda Plan ID set which were found in Salesforce
        dmlLogs = new List <EventLog__e>(); //Initializing DMLLogs List

        //Query Plan Records from Salesforce and Prepare Plan List to be Updated 
        if (prodaIdVsNotificationMap.keySet() != null) {
            for (Plan__c eachPlan : [
                    SELECT id, PRODA_Plan_Id__c,PlanManager__c 
                    FROM Plan__c 
                    WHERE PRODA_Plan_Id__c IN :prodaIdVsNotificationMap.keySet()
                ]
            ) {	
                //Condition to check for planManger NAP5-117 Added by Nishant Singh
                if( prodaIdVsNotificationMap.containsKey( eachPlan.PRODA_Plan_Id__c ) && 
                   prodaIdVsNotificationMap.get(eachPlan.PRODA_Plan_Id__c).planManager.equalsIgnoreCase( eachPlan.PlanManager__c ) ){
                    prodaObjectIdSet.add(eachPlan.PRODA_Plan_Id__c);
                    NDIA_NotificationDTO.PlanDateUpdate planWrapperObj = prodaIdVsNotificationMap.get(eachPlan.PRODA_Plan_Id__c);
                    Plan__c planRecord = new Plan__c(Id=eachPlan.Id, PRODA_Plan_Id__c=planWrapperObj.planId, Plan_End_Date__c = Date.valueOf(planWrapperObj.endDate));
                    planList.add(planRecord);
                }
            }
    
            //Loop to Find out the PRODA ID's which are present in the Platform Event but not in Salesforce
            for (String ID : prodaIdVsNotificationMap.keySet()) {
                if (!prodaObjectIdSet.contains(ID)) {
                    // Plan Id not present
                    EventLog__e evt = LogService.logSaveResult(
                        'NDIA_Event_PlanEndDateUpdated', 'processResponse', 
                        'Plan End Date update via NDIA Notification could not be completed for Proda Plan Id ' + ID +
                        ' as it was not found in Salesforce', '',
                        NDIA_NotificationHelper.eventName, NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(ID));
                    evt.HTTPResponse__c =  NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(ID); 
                    dmlLogs.add(evt);
                }
            }
        }   
        if(test.isRunningTest()) { // To test database.error logic
           planList[0].Id = null; 
        }     
        if (!planList.isEmpty()) {
            /*NOTE : We are using Update instead of Upsert because if Proda Plan ID is not Present in Salesforce then
            upsert tries to create a new Record in Salesforce and It throws a Required field error (As the payload doesn't contain all the details)*/
            Database.SaveResult[] srList = Database.Update(planList,false);
            for (Integer i = 0; i < planList.size(); i++) {        
                if (!srList[i].isSuccess()) { 
                    String dmlError = '';
                    for (Database.Error err : srList[i].getErrors()) { //If error append error message in description field for each error record
                        dmlError += err + ',';
                    }
                    
                    dmlError = dmlError.removeEnd(',');
                    EventLog__e evt = LogService.logSaveResult (
                        'NDIA_Event_PlanEndDateUpdated', 'processResponse', 
                        dmlError + '. Record Id :' + planList[i].Id, '',
                        NDIA_NotificationHelper.eventName, NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(planList[i].Proda_Plan_Id__c)
                    );
                    evt.HTTPResponse__c =  NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(planList[i].Proda_Plan_Id__c);
                    dmlLogs.add(evt);                
                } 
                // else {
                //     updatedPlanIdSet.add(planList[i].Id);
                // }
            }           
        }

        //Insert Logs
        if (!dmlLogs.isEmpty()) {
            LogService.insertLog(dmlLogs);
        }

        /* NOTE : commenting the code as the current API limit for NDIA Budget sync is 100 calls per hour, 
                  can be uncommented later if limit is increased */ 

        // if (!updatedPlanIdSet.isEmpty()) {
        //     List<Plan__c> planRecordList = [Select id, Name, NDIS__c, PRODA_Plan_Id__c, Client_Name__c, Client_Name__r.Name, Client_Name__r.LastName, Client_Name__r.PersonBirthdate, Client_Name__r.NDIS__c, Plan_Start_Date__c, Plan_End_Date__c from Plan__c where Id IN :updatedPlanIdSet];
        //     String planAsJSON = JSON.serialize(planRecordList);
        //     getBudgetsViaFuture(planAsJSON, NDIA_NotificationHelper.eventName, NDIA_NotificationHelper.uniqueIdVsReplayIdMap);
        // }
    }

    /**
     * @description     Method calls NDIA Get callout function in NDIA_BudgetDataSync Class for Budget related objects
     * @author          Rohit Tikoo
     * @param           planAsJSON            : List of Plan records in Serialized form  
     *                  eventName             : NDIA Notification Event Name
     *                  uniqueIdVsReplayIdMap : Map of proda plan id vs event replay id
     * @return          void
    **/  

    // @future (callout = true)
    // public static void getBudgetsViaFuture(String planAsJSON, String eventName, Map<String, String> uniqueIdVsReplayIdMap) {
    //     NDIA_NotificationHelper.eventName = eventName;
    //     NDIA_NotificationHelper.uniqueIdVsReplayIdMap = uniqueIdVsReplayIdMap;
    //     List <Plan__c> planList = (List<Plan__c>) JSON.deserialize(planAsJSON, List<Plan__c>.class);
    //     Map <String, List<NDIA_DTO.PlanManagedResponse>> prodaIdVsBudgetResponseMap = NDIA_BudgetDataSync.getBudgets(planList, null);
    //     NDIA_BudgetDataSync.processBudgets(prodaIdVsBudgetResponseMap);
    // }
}