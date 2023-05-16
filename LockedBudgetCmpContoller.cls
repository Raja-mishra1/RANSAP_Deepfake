/**
 * @description       : [NAP5-344] This class is used by LockedBudgetCmp LWC to add or edit Locked Budget
 *                      and Locked Budget Line Items. The component is present on PlanSupport incase
 *                      of Add and on Locked Budget in case of Edit Locked Budget
 *                      Locked Budget
 * @company           : Cloudwerx
 * @date              : 12/02/2022
 * @testClass         : LockedBudgetCmpContollerTest
**/
public with sharing class LockedBudgetCmpContoller {

    /**
     * @description      Method to get the data on Load of the LWC
     * @author           Cloudwerx
     * @param            recordId, objectName
     * @return           LockedBudgetDataWrapper       
    **/
    @AuraEnabled
    public static LockedBudgetDataWrapper getLockedBudgetData(
        string recordId, string objectName
    ) {
        LockedBudgetDataWrapper lockedBudgetData = new LockedBudgetDataWrapper();
        lockedBudgetData.addLockedBudget = false;
        lockedBudgetData.editLockedBudget = false;
        List<PlanSupportItem__c> planSupportItemLst = new List<PlanSupportItem__c>();

        if (objectName == 'PlanSupport__c') {

            // query PlanSupport , PlanSupportItems 
            List<PlanSupport__c> planBudgetCategoryLst = [SELECT Id,
                                                                Name, 
                                                                Plan__c, 
                                                                FundsApproved__c, 
                                                                AllocatedFunds__c, 
                                                                Spent__c, 
                                                                Remaining__c,
                                                                TotalFundsRemaining__c,
                                                                Plan__r.Name, 
                                                                Plan__r.Plan_Start_Date__c, 
                                                                Plan__r.Plan_End_Date__c,
                                                                SupportCategory__c,
                                                                (SELECT Id, 
                                                                    Client__c, 
                                                                    PlanSupport__c, 
                                                                    Plan__c, SupportItem__c, 
                                                                    Name, Item_Type__c, 
                                                                    In_Kind__c, 
                                                                    QuoteRequired__c, 
                                                                    QuoteApproved__c, 
                                                                    FundsApproved__c, 
                                                                    AllocatedFunds__c, 
                                                                    LockedFunds__c, 
                                                                    TotalFundsRemaining__c, 
                                                                    TotalFundsSpent__c, 
                                                                    UnlockedStatedFundsRemaining__c 
                                                                FROM Plan_Support_Items__r) 
                                                        FROM PlanSupport__c 
                                                        WHERE Id =: recordId LIMIT 1];

            lockedBudgetData.supportCategory = planBudgetCategoryLst[0].SupportCategory__c;
            for(PlanSupport__c currentPlanBudgetCategory : planBudgetCategoryLst){	
                planSupportItemLst.AddAll(currentPlanBudgetCategory.Plan_Support_Items__r);
            }
            lockedBudgetData.planBudgetCategory = planBudgetCategoryLst[0];
            lockedBudgetData.planSupportItems = planSupportItemLst;
            lockedBudgetData.addLockedBudget = true;

        } else if (objectName == 'PlanSupportPreference__c') {

            // query PlanSupportPreference and Locked Budget Line Items
            List<PlanSupportPreferenceLineItem__c> planSupportPreferenceLineItemLst = 
                new List<PlanSupportPreferenceLineItem__c>();
            List<PlanSupportPreference__c> planSupportPreferenceLst = 
                [SELECT Id, 
                        Type__c, 
                        Plan__c, 
                        PlanSupport__c, 
                        Plan__r.Name,
                        PlanSupport__r.Name,
                        PlanSupport__r.FundsApproved__c,
                        PlanSupport__r.AllocatedFunds__c,
                        PlanSupport__r.Spent__c,
                        PlanSupport__r.Remaining__c,
                        SupportItemNumber__c, 
                        Active__c, 
                        Total__c, 
                        Rate__c, 
                        PGRate__c, 
                        StartDate__c,
                        FundsSpent__c,
                        RecordType.DeveloperName, 
                        EndDate__c, 
                        Provider__c,
                        Provider__r.Name,
                        ServiceAgreementCase__c,  
                        Case__c,
                        Comments__c, 	
                        ServiceAgreementCase__r.CaseNumber, 	
                        Consent_to_Pay_over_PG__c,
                        PlanSupport__r.SupportCategory__c,
                        (SELECT Id, Active__c, ClientBudgetPreference__c, 
                            Name,UnitPrice__c,SetUnitPriceToPGUnitPrice__c,
                            Consent_to_Pay_over_PG__c, PGUnitPrice__c, SupportItem__c, 
                            SupportItem__r.Name, SupportItemNumer__c  
                        FROM Client_Budget_Preferences__r)   
                    FROM PlanSupportPreference__c 
                    WHERE Id =: recordId LIMIT 1];

            planSupportItemLst = [SELECT Id, 
                                         Client__c, 
                                         PlanSupport__c, 
                                         Plan__c, SupportItem__c, 
                                         Name, Item_Type__c, In_Kind__c, QuoteRequired__c, 
                                         QuoteApproved__c, FundsApproved__c, AllocatedFunds__c, 
                                         LockedFunds__c, TotalFundsRemaining__c, 
                                         TotalFundsSpent__c, UnlockedStatedFundsRemaining__c 
                                FROM PlanSupportItem__c 
                                WHERE PlanSupport__c =: planSupportPreferenceLst[0].PlanSupport__c];

            lockedBudgetData.supportCategory = 
                planSupportPreferenceLst[0].PlanSupport__r.SupportCategory__c;

            for(PlanSupportPreference__c currentPlanSupportPreference : planSupportPreferenceLst){
                planSupportPreferenceLineItemLst.AddAll(currentPlanSupportPreference.Client_Budget_Preferences__r);
            }

            lockedBudgetData.planSupportPreference = planSupportPreferenceLst[0];
            lockedBudgetData.planSupportItems = planSupportItemLst;
            lockedBudgetData.planSupportPreferenceLineItem = planSupportPreferenceLineItemLst;
            lockedBudgetData.editLockedBudget = true;
        }

        return lockedBudgetData;

    }

    /*Wrapper class used to populate Locked Budget Data on load*/
    public Class LockedBudgetDataWrapper {
        @AuraEnabled
        public PlanSupport__c planBudgetCategory{get;set;}
        @AuraEnabled
        public list<PlanSupportItem__c> planSupportItems{get;set;}
        @AuraEnabled
        public PlanSupportPreference__c planSupportPreference{get;set;}
        @AuraEnabled
        public list<PlanSupportPreferenceLineItem__c> planSupportPreferenceLineItem{get;set;}
        @AuraEnabled
        public string supportCategory{get;set;}
        @AuraEnabled
        public boolean addLockedBudget{get;set;}
        @AuraEnabled
        public boolean editLockedBudget{get;set;}
    }

    /**
     * @description      Method to save the data of Locked Budget and Locked Budget Lines
     * @author           Cloudwerx
     * @param            objCbp : LockedBudgetCreationDataWrapper
     *                   lineItem : List of PlanSupportPreferenceLineItem__c
     *                   recordIdOfLockedBudget : Id of Locked Budget Record
     *                   recordIdsToDelete : List of Ids of PlanSupportPreferenceLineItem__c
     * @return           PlanSupportPreference__c : Locked Budget Record       
    **/
    @AuraEnabled
    public static PlanSupportPreference__c saveClientBudgetPerferenceRecord(
        LockedBudgetCreationDataWrapper objCbp,
        List<PlanSupportPreferenceLineItem__c> lineItem, 
        String recordIdOfLockedBudget,
        List<Id> recordIdsToDelete
    ) {
        
        try {
            String supportItemNumbers;
            List<PlanSupportPreferenceLineItem__c> LockedBudgetLinesToBeUpserted = 
                new List<PlanSupportPreferenceLineItem__c>();
    
            if (recordIdsToDelete?.size() > 0) {
                // delete the Locked Budget Lines
                deleteRecords(recordIdsToDelete);
            }
        
            String recordTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;

            // Concatenate Support Item Numbers
            if (lineItem?.size() > 0) {
                supportItemNumbers = concatenateNumber(lineItem);
            }

            PlanSupportPreference__c lockedBudgetRec = new PlanSupportPreference__c();
            
            if(recordIdOfLockedBudget != null){
                lockedBudgetRec.Id = recordIdOfLockedBudget;
            }

            lockedBudgetRec.RecordTypeId  = recordTypeId;
            lockedBudgetRec.Type__c = objCbp.strType;
            lockedBudgetRec.Comments__c = objCbp.strComment;
            lockedBudgetRec.Total__c = objCbp.strTotal;
            lockedBudgetRec.SupportItemNumber__c = supportItemNumbers;
            lockedBudgetRec.Provider__c = objCbp.strProvider;
            lockedBudgetRec.ServiceAgreementCase__c = objCbp.strCase;
            lockedBudgetRec.Plan__c = objCbp.strplan;
            lockedBudgetRec.PlanSupport__c = objCbp.strPlanBudget;
            lockedBudgetRec.StartDate__c = objCbp.fromdate;
            lockedBudgetRec.EndDate__c = objCbp.todate;

            upsert lockedBudgetRec;
        

            Map<String, PlanSupportPreferenceLineItem__c> existingRecordsMap = 
                new Map<String, PlanSupportPreferenceLineItem__c>
                    ([SELECT Id, Name, UnitPrice__c 
                    FROM PlanSupportPreferenceLineItem__c 
                    WHERE ClientBudgetPreference__c =: lockedBudgetRec.Id]);
            
            for (PlanSupportPreferenceLineItem__c lst : lineItem) {
                if (lst.Id == null) {
                    // for new lines           
                    if (lst.SetUnitPriceToPGUnitPrice__c) {
                        lst.UnitPrice__c = lst.PGUnitPrice__c;
                    }
                    if (lst.ClientBudgetPreference__c == null) {
                        lst.ClientBudgetPreference__c = lockedBudgetRec.Id;
                    }
                    LockedBudgetLinesToBeUpserted.add(lst);
                } else {
                    // for existing records
                    if (existingRecordsMap?.size() > 0 
                        && existingRecordsMap.containsKey(lst.Id)
                    ) {
                        PlanSupportPreferenceLineItem__c pspLine = 
                            existingRecordsMap.get(lst.Id);

                        if (lst.SetUnitPriceToPGUnitPrice__c) {
                            pspLine.UnitPrice__c = lst.PGUnitPrice__c;                         
                        } else {
                            pspLine.UnitPrice__c = lst.UnitPrice__c; 
                        }
                        pspLine.SupportItem__c = lst.SupportItem__c;
                        pspLine.SetUnitPriceToPGUnitPrice__c = lst.SetUnitPriceToPGUnitPrice__c;
                        pspLine.Consent_to_Pay_over_PG__c = lst.Consent_to_Pay_over_PG__c;
                        LockedBudgetLinesToBeUpserted.add(pspLine);
                    }
                }   
            }

            if (LockedBudgetLinesToBeUpserted?.size() > 0 ) {
                upsert LockedBudgetLinesToBeUpserted Id;
            }

            PlanSupportPreference__c planSupportPreferenceObj = 
                [SELECT Id, Name 
                FROM PlanSupportPreference__c WHERE Id =: lockedBudgetRec.Id];
                
            return planSupportPreferenceObj;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description      Method to concatenate the Support Item Numbers on Locked Budget
     * @author           Cloudwerx
     * @param            lineItems : list of PlanSupportPreferenceLineItem__c
     * @return           String value      
    **/
    public static String concatenateNumber(List<PlanSupportPreferenceLineItem__c> lineItems) {
        String concatenatedValues;
        Set<Id> supportItemSet = new Set<Id>();

        for (PlanSupportPreferenceLineItem__c eachRecord : lineItems) {
            supportItemSet.add(eachRecord.SupportItem__c);
        }

        for (SupportItem__c supportItemObj : 
            [SELECT id, 
                SupportItemNumber__c 
                FROM SupportItem__c 
                WHERE id IN: supportItemSet
            ]
        ) {
            concatenatedValues +=  ', ' +supportItemObj.SupportItemNumber__c;
        }

        concatenatedValues = concatenatedValues.removeStart('null')
                                .removeStart(',')
                                .removeStart(' ');

        return concatenatedValues;
    }
    
    /*Wrapper class used to fetch Locked Budget Data on edit*/
    public Class LockedBudgetCreationDataWrapper {
        @AuraEnabled
        public String strType{get;set;}
        @AuraEnabled
        public String strComment{get;set;}
        @AuraEnabled
        public Integer strTotal{get;set;}
        @AuraEnabled
        public String strProvider{get;set;}
        @AuraEnabled
        public string strCase{get;set;}
        @AuraEnabled
        public String strplan{get;set;}
        @AuraEnabled
        public String strPlanBudget{get;set;}
        @AuraEnabled
        public Date fromdate{get;set;}
        @AuraEnabled
        public Date todate{get;set;}
    }


    /**
     * @description      Method to get the PGRate for Locked Budget Lines
     * @author           Cloudwerx
     * @param            LockedBudgetCreationDataWrapper :wrapper of Locked Budget
     *                   lineItem : list of PlanSupportPreferenceLineItem__c
     * @return           List of PlanSupportPreferenceLineItem__c      
    **/
    @AuraEnabled
    public static List<PlanSupportPreferenceLineItem__c> getPGRate(
        LockedBudgetCreationDataWrapper objCbp,
        List<PlanSupportPreferenceLineItem__c> lineItems
    ) {

        try {
            Set<Id> supportItemSet = new Set<Id>();
            Set<String> supportItemNumberSet = new Set<String>();

            for (PlanSupportPreferenceLineItem__c eachRecord : lineItems) {
                supportItemSet.add(eachRecord.SupportItem__c);
            }

            Map<Id, SupportItem__c> supportItemMap = 
                new Map<Id, SupportItem__c>([SELECT Id, SupportItemNumber__c 
                                            FROM SupportItem__c WHERE Id IN : supportItemSet]);

            for (PlanSupportPreferenceLineItem__c eachRecord : lineItems) {
                    supportItemNumberSet.add
                        (supportItemMap.get(eachRecord.SupportItem__c).SupportItemNumber__c);
            }


            if (objCbp.strplan != null 
                && supportItemNumberSet?.size() > 0
            ) {
                calculatePGRate(lineItems, supportItemNumberSet,supportItemMap,objCbp);
            }
            return lineItems;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        } 
    }

    /**
     * @description      Method to calculate the PGRate for Locked Budget Lines
     * @author           Cloudwerx
     * @param            newList : list of PlanSupportPreferenceLineItem__c
     *                   supportItemNumberSet : Set of SupportItemNumbers
     *                   supportItemMap : Map of Support Item
     *                   objCbp : LockedBudgetCreationDataWrapper
     * 
     * @return           NA      
    **/
    public static void calculatePGRate(
        List<PlanSupportPreferenceLineItem__c> newList, 
        Set<String> supportItemNumberSet,
        Map<Id, SupportItem__c> supportItemMap,
        LockedBudgetCreationDataWrapper objCbp
    ) {
        Decimal max = 0.0;

        // //FETCH CLIENT DATA FROM PLAN
        Map<Id, Plan__c> IdVsPlanMap = 
         new Map<Id, Plan__c>([SELECT 
                                    id, 
                                    Client_Name__r.ModifiedMonashModelScore__c, 
                                    Client_Name__r.BillingStateCode 
                                    FROM Plan__c 
                                    WHERE Id =: objCbp.strplan]);   
        
        //FETCH LIST OF SUPPORT ITEMS RELATED TO THE SUPPORT ITEM NUMBER
        Map<String, List<SupportItemPrice__c>> supportItemNumberVsListOfSupportItemPrices = 
            PlanSupportPrefLineItemTriggerHandler.getSupportItemPrice(supportItemNumberSet);

        for (PlanSupportPreferenceLineItem__c eachRecord : newList) {
            max = 0.0;
            if (supportItemNumberVsListOfSupportItemPrices.containsKey(
                supportItemMap.get(eachRecord.SupportItem__c).SupportItemNumber__c)) { 
                    //CHECK IF SUPPORT ITEM NUMBER ENTERED IS VALID OR NOT
                
                for (SupportItemPrice__c supportItemPrice :
                    supportItemNumberVsListOfSupportItemPrices.get(
                        supportItemMap.get(eachRecord.SupportItem__c).SupportItemNumber__c)
                ) {
                    if  (supportItemPrice.StartDate__c <= 
                        objCbp.todate
                        && supportItemPrice.EndDate__c >= 
                        objCbp.fromdate
                    ) {
                        if (IdVsPlanMap.containsKey(
                            objCbp.strplan)
                            && supportItemPrice!= null
                        ) {
                            Decimal modifiedMonashModelScore =  
                                IdVsPlanMap.get(
                                    objCbp.strplan)
                                    ?.Client_Name__r?.ModifiedMonashModelScore__c;

                            if (modifiedMonashModelScore == 7) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.VeryRemotePrice__c;
                            } else if (modifiedMonashModelScore == 6) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.RemotePrice__c;
                            } else {
                                String billingCode = 
                                    IdVsPlanMap.get(
                                        objCbp.strplan)
                                            ?.Client_Name__r?.BillingStateCode;

                                if (billingCode == 'ACT') {
                                    eachRecord.PGUnitPrice__c = supportItemPrice.ACTPrice__c;
                                } else if (billingCode == 'NSW') {
                                    eachRecord.PGUnitPrice__c = supportItemPrice.NSWPrice__c;
                                } else if (billingCode == 'VIC') {
                                    eachRecord.PGUnitPrice__c = supportItemPrice.VICPrice__c;
                                } else if (billingCode == 'QLD') {
                                    eachRecord.PGUnitPrice__c = supportItemPrice.QLDPrice__c;
                                } else if (billingCode == 'WA') {
                                    eachRecord.PGUnitPrice__c = supportItemPrice.WAPrice__c;
                                } else if (billingCode == 'NT') {
                                    eachRecord.PGUnitPrice__c = supportItemPrice.NTPrice__c;
                                } else if (billingCode == 'SA') {
                                    eachRecord.PGUnitPrice__c = supportItemPrice.SAPrice__c;
                                } else if (billingCode == 'TAS') {
                                    eachRecord.PGUnitPrice__c = supportItemPrice.TASPrice__c;
                                } else {
                                    eachRecord.PGUnitPrice__c = 0;
                                }
                            }
                        }

                        if (eachRecord.PGUnitPrice__c > max) {
                            max = eachRecord.PGUnitPrice__c;
                        } else {
                            eachRecord.PGUnitPrice__c = max;
                        }
                    } 
                }
            }  
        }
    }

    /**
     * @description      Method to delete the Locked Budget Lines
     * @author           Cloudwerx
     * @param            recordIdsToDelete : Ids of PlanSupportPreferenceLineItem__c
     * @return           NA      
    **/
    @AuraEnabled
    public static void deleteRecords(List<Id> recordIdsToDelete) {
        List<PlanSupportPreferenceLineItem__c> lineItemsDeleteList = 
            new List<PlanSupportPreferenceLineItem__c>();

        for (Id recordId : recordIdsToDelete) {
            if (recordId != null) {
                lineItemsDeleteList.add(new PlanSupportPreferenceLineItem__c(id = recordId));
            }
        }    
        
        if (lineItemsDeleteList?.size() > 0) {
            delete lineItemsDeleteList;
        } 
    }
}