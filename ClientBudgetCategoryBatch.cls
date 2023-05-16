global with sharing class ClientBudgetCategoryBatch implements Database.Batchable<sObject>, Database.Stateful {

    global Database.QueryLocator start (Database.BatchableContext BC) {

        String LockedBudgetReportTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;

        String 	query =  'SELECT Id, SupportItemNumber__c, PGRate__c, Rate__c, Consent_to_Pay_over_PG__c,Active__c  FROM PlanSupportPreference__c ';
        query += 'WHERE RecordTypeId = :LockedBudgetReportTypeId ';
        return Database.getQueryLocator(query);
    }
    

    global void execute (Database.BatchableContext BC, List<PlanSupportPreference__c> recordsList) {
        Map<String,String> supportItemNumberMap = new Map<String,String>();
        Set<String> supportItemSet = new Set<String>();
        List<PlanSupportPreferenceLineItem__c> PlanSupportPreferenceList = new List<PlanSupportPreferenceLineItem__c>();

        for(PlanSupportPreference__c lockedBudgetObj : recordsList){
            if(lockedBudgetObj.SupportItemNumber__c != null){
                supportItemSet.add(lockedBudgetObj.SupportItemNumber__c);
            }
        }

        List<SupportItem__c> supportItemList = [SELECT Id,SupportItemNumber__c FROM SupportItem__c where SupportItemNumber__c in: supportItemSet];

            for(SupportItem__c item : supportItemList){
                supportItemNumberMap.put(item.SupportItemNumber__c,item.Id);
            }

        for(PlanSupportPreference__c lockedBudgetObj : recordsList){
            if(lockedBudgetObj.SupportItemNumber__c != null){
                PlanSupportPreferenceLineItem__c supportLineItemObj = new PlanSupportPreferenceLineItem__c ();
                supportLineItemObj.SupportItem__c = supportItemNumberMap.get(lockedBudgetObj.SupportItemNumber__c);
                supportLineItemObj.ClientBudgetPreference__c = lockedBudgetObj.Id;
                supportLineItemObj.PGUnitPrice__c = lockedBudgetObj.PGRate__c;
                supportLineItemObj.UnitPrice__c = lockedBudgetObj.Rate__c;
                supportLineItemObj.Consent_to_Pay_over_PG__c = lockedBudgetObj.Consent_to_Pay_over_PG__c;
                if(lockedBudgetObj.Rate__c == lockedBudgetObj.PGRate__c){
                    supportLineItemObj.SetUnitPriceToPGUnitPrice__c = true;
                }
                supportLineItemObj.Active__c = true;
                PlanSupportPreferenceList.add(supportLineItemObj);
            }
        }
        if(!PlanSupportPreferenceList.isEmpty()){
            Database.insert(PlanSupportPreferenceList,false);
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
    
}