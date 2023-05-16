/**
 * @description       Apex Trigger Handler for PlanSupportPreferenceLineItem__c Object
 * @company           Cloudwerx
 * @date              25/1/2023
 * @testClass         PlanSupportPrefLineItemTriggerHandlerTest
**/
public class PlanSupportPrefLineItemTriggerHandler {
    
    //Fetch record type Id for Locked Budget Record Type
    public static final Id PSP_RESERVED_BUDGET_RECORD_TYPE_ID = 
        RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID; 

    /**
     * @description         Generic Method to handle The trigger handler methods
     * @author              Sonali Bhat
     * @param               newList : Holds trigger.new 
     * @return              -     
    **/
    public static void methodHandler(List<PlanSupportPreferenceLineItem__c> newList) {

        Set<Id> pspIdSet = new Set<Id>();
        Set<Id> planIdSet = new Set<Id>();
        Set<Id> supportItemSet = new Set<Id>();
        Set<String> supportItemNumberSet = new Set<String>();
        List<PlanSupportPreferenceLineItem__c> allPSPLineItems = 
            new List<PlanSupportPreferenceLineItem__c>();
 
        for (PlanSupportPreferenceLineItem__c eachRecord : newList) {
            pspIdSet.add(eachRecord.ClientBudgetPreference__c);
            supportItemSet.add(eachRecord.SupportItem__c);
        }
        System.debug('newListt-->'+newList);
        // Map of Plan Support Preference
        Map<Id, PlanSupportPreference__c> pspMap = 
            new Map<Id, PlanSupportPreference__c> ([SELECT Id, Plan__c, RecordTypeId,
                                                    EndDate__c,StartDate__c
                                                    FROM PlanSupportPreference__c 
                                                    WHERE  ID IN : pspIdSet]);
        
        for (Id pspId : pspMap.keySet()) {
            // add Plan Ids of Locked Budget Preferences
            if (pspMap.get(pspId).RecordTypeId == PSP_RESERVED_BUDGET_RECORD_TYPE_ID) {
                planIdSet.add(pspMap.get(pspId).Plan__c);
            }  
        }
                            
        // Map of Support Item
        Map<Id, SupportItem__c> supportItemMap = 
            new Map<Id, SupportItem__c>([SELECT Id, SupportItemNumber__c 
                                        FROM SupportItem__c WHERE Id IN : supportItemSet]);
        
        for (PlanSupportPreferenceLineItem__c eachRecord : newList) {
            if (pspMap.get(eachRecord.ClientBudgetPreference__c).RecordTypeId == 
                PSP_RESERVED_BUDGET_RECORD_TYPE_ID
            ) {
                System.debug('eachRecord'+eachRecord);
                System.debug('Support Item'+eachRecord.SupportItem__c);
                System.debug('supportItem Map'+supportItemMap);
                allPSPLineItems.add(eachRecord);
                supportItemNumberSet.add
                    (supportItemMap.get(eachRecord.SupportItem__c).SupportItemNumber__c);
            }
        }

        Map<Id, Plan__c> IdVsPlanMap = 
            new Map<Id, Plan__c>([SELECT 
                                        id, 
                                        Client_Name__r.ModifiedMonashModelScore__c, 
                                        Client_Name__r.BillingStateCode 
                                FROM Plan__c 
                                WHERE Id IN : planIdSet]);    

        calculatePGRate(allPSPLineItems, 
            supportItemNumberSet, planIdSet, supportItemMap, pspMap, IdVsPlanMap);
    }

    /**
     * @description         Calculate PG Rate
     * @author              Sonali Bhat
     * @param               newList : Holds Plan Support Preference Line items
     *                      supportItemNumberSet :  holds set of SupportItemNumber    
     *                      planIdSet  : holds set of Plan Ids 
     * @return              It returns pg rate   
    **/
    public static void calculatePGRate(
        List<PlanSupportPreferenceLineItem__c> newList, 
        Set<String> supportItemNumberSet, 
        Set<Id> planIdSet, 
        Map<Id, SupportItem__c> supportItemMap,
        Map<Id, PlanSupportPreference__c> pspMap,
        Map<Id, Plan__c> IdVsPlanMap
    ) {
        Decimal max = 0.0;
        // //FETCH CLIENT DATA FROM PLAN
        // Map<Id, Plan__c> IdVsPlanMap = 
        //     new Map<Id, Plan__c>([SELECT 
        //                                 id, 
        //                                 Client_Name__r.ModifiedMonashModelScore__c, 
        //                                 Client_Name__r.BillingStateCode 
        //                         FROM Plan__c 
        //                         WHERE Id IN : planIdSet]);    
        
        //FETCH LIST OF SUPPORT ITEMS RELATED TO THE SUPPORT ITEM NUMBER
        Map<String, List<SupportItemPrice__c>> supportItemNumberVsListOfSupportItemPrices = 
            getSupportItemPrice(supportItemNumberSet);

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
                            pspMap.get(eachRecord.ClientBudgetPreference__c).EndDate__c 
                        && supportItemPrice.EndDate__c >= 
                            pspMap.get(eachRecord.ClientBudgetPreference__c).StartDate__c
                    ) {
                        if (IdVsPlanMap.containsKey(
                            pspMap.get(eachRecord.ClientBudgetPreference__c).Plan__c) 
                            && supportItemPrice!= null
                        ) {
                            if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.ModifiedMonashModelScore__c == 7
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.VeryRemotePrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.ModifiedMonashModelScore__c == 6
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.RemotePrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.BillingStateCode == 'ACT'
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.ACTPrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.BillingStateCode == 'NSW'
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.NSWPrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.BillingStateCode == 'VIC'
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.VICPrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.BillingStateCode == 'QLD'
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.QLDPrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.BillingStateCode == 'WA'
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.WAPrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.BillingStateCode == 'NT'
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.NTPrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.BillingStateCode == 'SA'
                            ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.SAPrice__c;
                            } else if (IdVsPlanMap.get(
                                pspMap.get(
                                    eachRecord.ClientBudgetPreference__c).Plan__c)
                                    ?.Client_Name__r?.BillingStateCode == 'TAS'
                                    ) {
                                eachRecord.PGUnitPrice__c = supportItemPrice.TASPrice__c;
                            } else {
                                eachRecord.PGUnitPrice__c = 0;
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

        //return max;
    }

    /**
     * @description         Generic method to get the supportItemNumber vs List<SupportItem> Map
     * @author              Sonali Bhat
     * @param               supportItemNumberSet : contains support Item Numbers
     * @return              Map<String, List<SupportItem__c>>      
    **/

    public static Map<String, List<SupportItemPrice__c>> getSupportItemPrice(
        Set<String> supportItemNumberSet
    ) {
        Map<String, List<SupportItemPrice__c>> supportItemNumberVsListOfSupportItemPrices =
            new Map<String, List<SupportItemPrice__c>>();

        for (SupportItemPrice__c supportItemPrice : 
            [SELECT EndDate__c,
                    StartDate__c, 
                    SupportItemNumber__c, 
                    SupportItem__r.SupportCategory__c, 
                    SupportItem__r.SupportCategory__r.SupportCategoryCode__c, 
                    SupportItemPriceName__c, VeryRemotePrice__c, RemotePrice__c, ACTPrice__c, 
                    NSWPrice__c, VICPrice__c, QLDPrice__c,
                    WAPrice__c, NTPrice__c, SAPrice__c, TASPrice__c 
                    FROM SupportItemPrice__c 
                    WHERE SupportItemNumber__c IN :supportItemNumberSet]
        ) {
            if (supportItemNumberVsListOfSupportItemPrices.containsKey(
                supportItemPrice.SupportItemNumber__c)) {
                supportItemNumberVsListOfSupportItemPrices.get(
                    supportItemPrice.SupportItemNumber__c).add(supportItemPrice);
            } else {
                supportItemNumberVsListOfSupportItemPrices.put(
                    supportItemPrice.SupportItemNumber__c, 
                    new List<SupportItemPrice__c>{supportItemPrice});
            }
        }

        return supportItemNumberVsListOfSupportItemPrices;
    }
}