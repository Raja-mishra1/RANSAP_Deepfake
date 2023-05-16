/**
 * @description       Apex Trigger for PlanSupportPreference__c Object
 * @company           Cloudwerx
 * @date              03/08/2021
 * @testClass         PlanSupportPreferencesTriggerHandlerTest
**/
public class PlanSupportPreferencesTriggerHandler {

    public static final Id SUBSTITUTION_RECORD_TYPE_ID = RecordTypeUtil.PSP_SUBSTITUTION_RECORD_TYPE_ID; //Fetch record type Id for Substitution Record Type
    public static final Id PSP_RESERVED_BUDGET_RECORD_TYPE_ID = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID; //Fetch record type Id for Locked Budget Record Type
   
    /**
     * @description         Generic Method to handle The trigger handler methods
     * @author              Rohit Tikoo
     * @param               newList : Holds trigger.new 
     * @return              -     
    **/
    public static void methodHandler(List<PlanSupportPreference__c> newList) {

        Map<Id, List<PlanSupportPreference__c>> recordTypeIdVsPSPRecord = new Map<Id, List<PlanSupportPreference__c>>();
        Map<Id, Set<String>> recordTypeIdVsSupportItemNumberSet = new Map<Id, Set<String>>();
        Map<Id, Set<String>> recordTypeIdVsSubstSupportItemNumberSet = new Map<Id, Set<String>>();
        Map<Id, Set<Id>> recordTypeIdVsplanIdSet = new Map<Id, Set<Id>>();
        Set<Id> pspIdSet = new Set<Id>();
        
        for (PlanSupportPreference__c eachRecord : newList) {    
            
            //Adding Record Id in a Set
            if (Trigger.isUpdate) {
                pspIdSet.add(eachRecord.Id);
                
                if (!eachRecord.Active__c) {
                    eachRecord.Total__c = eachRecord.FundsSpent__c != null ? eachRecord.FundsSpent__c : 0;
                }
            }

            //POPULATE recordTypeIdVsPSPRecord MAP
            if (!recordTypeIdVsPSPRecord.containsKey(eachRecord.RecordTypeId)) {
                recordTypeIdVsPSPRecord.put(eachRecord.RecordTypeId, new List<PlanSupportPreference__c> {eachRecord});
            } else {
                recordTypeIdVsPSPRecord.get(eachRecord.RecordTypeId).add(eachRecord);
            }

            //POPULATE recordTypeIdVsSupportItemNumberSet MAP
            if (!recordTypeIdVsSupportItemNumberSet.containsKey(eachRecord.RecordTypeId)) {
                recordTypeIdVsSupportItemNumberSet.put(eachRecord.RecordTypeId, new Set<String> {eachRecord.SupportItemNumber__c});
            } else {
                recordTypeIdVsSupportItemNumberSet.get(eachRecord.RecordTypeId).add(eachRecord.SupportItemNumber__c);
            }

            //POPULATE recordTypeIdVsSubstSupportItemNumberSet MAP
            if (!recordTypeIdVsSubstSupportItemNumberSet.containsKey(eachRecord.RecordTypeId)) {
                recordTypeIdVsSubstSupportItemNumberSet.put(eachRecord.RecordTypeId, new Set<String> {eachRecord.SubstitutionSupportItemNumber__c});
            } else {
                recordTypeIdVsSubstSupportItemNumberSet.get(eachRecord.RecordTypeId).add(eachRecord.SubstitutionSupportItemNumber__c);
            }
            
            //POPULATE recordTypeIdVsplanIdSet MAP
            if (!recordTypeIdVsplanIdSet.containsKey(eachRecord.RecordTypeId)) {
                recordTypeIdVsplanIdSet.put(eachRecord.RecordTypeId, new Set<Id> {eachRecord.Plan__c});
            } else {
                recordTypeIdVsplanIdSet.get(eachRecord.RecordTypeId).add(eachRecord.Plan__c);
            }           
        }

        //CALL METHODS RELATED TO SUBSTITUTION RECORD TYPE
        if (recordTypeIdVsPSPRecord.containsKey(SUBSTITUTION_RECORD_TYPE_ID) 
            && !recordTypeIdVsPSPRecord.get(SUBSTITUTION_RECORD_TYPE_ID).isEmpty()
            && recordTypeIdVsSubstSupportItemNumberSet.containsKey(SUBSTITUTION_RECORD_TYPE_ID) 
            && !recordTypeIdVsSubstSupportItemNumberSet.get(SUBSTITUTION_RECORD_TYPE_ID).isEmpty()
            && recordTypeIdVsplanIdSet.containsKey(SUBSTITUTION_RECORD_TYPE_ID) 
            && !recordTypeIdVsplanIdSet.get(SUBSTITUTION_RECORD_TYPE_ID).isEmpty()) {

                checkPlanSupportItem(recordTypeIdVsPSPRecord.get(SUBSTITUTION_RECORD_TYPE_ID), recordTypeIdVsSupportItemNumberSet.get(SUBSTITUTION_RECORD_TYPE_ID), recordTypeIdVsplanIdSet.get(SUBSTITUTION_RECORD_TYPE_ID));
                supportItemCheckSubstitution(recordTypeIdVsPSPRecord.get(SUBSTITUTION_RECORD_TYPE_ID), recordTypeIdVsSupportItemNumberSet.get(SUBSTITUTION_RECORD_TYPE_ID), recordTypeIdVsSubstSupportItemNumberSet.get(SUBSTITUTION_RECORD_TYPE_ID), recordTypeIdVsplanIdSet.get(SUBSTITUTION_RECORD_TYPE_ID));
                checkEndDateWithLineItem(recordTypeIdVsPSPRecord.get(SUBSTITUTION_RECORD_TYPE_ID),pspIdSet);
        }

        //CALL METHODS RELATED TO LOCKED BUDGET RECORD TYPE
        if (recordTypeIdVsPSPRecord.containsKey(PSP_RESERVED_BUDGET_RECORD_TYPE_ID) 
            && !recordTypeIdVsPSPRecord.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID).isEmpty()
            && recordTypeIdVsSupportItemNumberSet.containsKey(PSP_RESERVED_BUDGET_RECORD_TYPE_ID) 
            && !recordTypeIdVsSupportItemNumberSet.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID).isEmpty()
            && recordTypeIdVsplanIdSet.containsKey(PSP_RESERVED_BUDGET_RECORD_TYPE_ID) 
            && !recordTypeIdVsplanIdSet.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID).isEmpty()) {

                //commented out restrictNotQuoteRequired check as part of TTP-3523
                //restrictNotQuoteRequired(recordTypeIdVsPSPRecord.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID), recordTypeIdVsSupportItemNumberSet.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID), recordTypeIdVsplanIdSet.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID));
                //calculatePGRate(recordTypeIdVsPSPRecord.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID), recordTypeIdVsSupportItemNumberSet.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID), recordTypeIdVsplanIdSet.get(PSP_RESERVED_BUDGET_RECORD_TYPE_ID));
       
        } 
    }
   
  
    /**
     * @description         Validation Rule to check Substitution Configuration on Plan Support Item
     * @author              Rohit Tikoo
     * @param               newList : Holds trigger.new  
     *                      supportItemNumberSet : Contains Set of Support Item Numbers
     *                      planIdSet : Contains Set of Plan Id's
     * @return              -    
    **/
    public static void checkPlanSupportItem(List<PlanSupportPreference__c> newList, Set<String> supportItemNumberSet, Set<Id> planIdSet) {
        
        Map<Id, List<PlanSupportItem__c>> planIdVsPlanSupportItem = new Map<Id, List<PlanSupportItem__c>>();

        for (PlanSupportItem__c eachPlanSupportItem : [SELECT Id, 
                                                              Plan__c, 
                                                              SupportItem__r.SupportItemNumber__c,
                                                              Item_Type__c  
                                                        FROM PlanSupportItem__c 
                                                        WHERE Plan__c IN : planIdSet 
                                                        AND SupportItem__r.SupportItemNumber__c IN : supportItemNumberSet limit 49999]) {
            if (!planIdVsPlanSupportItem.containsKey(eachPlanSupportItem.Plan__c)) {
                planIdVsPlanSupportItem.put(eachPlanSupportItem.Plan__c, new List<PlanSupportItem__c> {eachPlanSupportItem});
            } else {
                planIdVsPlanSupportItem.get(eachPlanSupportItem.Plan__c).add(eachPlanSupportItem);
            }
        }
        
        if (planIdVsPlanSupportItem != null) {
            for (PlanSupportPreference__c eachRecord : newList) {
                Integer count = 0;
                if (eachRecord.SupportItemNumber__c != null && planIdVsPlanSupportItem.containsKey(eachRecord.Plan__c)) {
                    for (PlanSupportItem__c eachPlanSupportItem : planIdVsPlanSupportItem.get(eachRecord.Plan__c)) { // ideally this loop will contain only one record
                        if (eachRecord.SupportItemNumber__c == eachPlanSupportItem.SupportItem__r.SupportItemNumber__c) {
                            count = count + 1; 
                        }
                    }
                    if (count >= 1) {
                        eachRecord.addError('Substitution configuration is not allowed for '+planIdVsPlanSupportItem.get(eachRecord.Plan__c)[0].SupportItem__c+ ' of type '+ planIdVsPlanSupportItem.get(eachRecord.Plan__c)[0].Item_Type__c);
                    }
                }
            } //END OF FOR LOOP
        }
    }

    /**
     * @description         Validation Rule to ensure Support Item should belong to the Support Category selected above
     * @author              Rohit Tikoo
     * @param               newList : Holds trigger.new  
     *                      supportItemNumberSet : Contains Set of Support Item Numbers
     *                      planIdSet : Contains Set of Plan Id's 
     * @return              -     
    **/
    public static void supportItemCheckSubstitution(List<PlanSupportPreference__c> newList, Set<String> supportItemNumberSet, Set<String> substSupportItemNumberSet, Set<Id> planIdSet) {                  
        
        //FETCH SUPPORT ITEM RECORD RELATED TO THE SUBSTITUTION SUPPORT ITEM NUMBER
        Map<String, SupportItem__c> substSupportItemNumberVsSuppItemRec = getSupportItemVsSupportItemRec(substSupportItemNumberSet);
        Map<String, SupportItem__c> supportItemNumberVsSuppItemRec;

        //FETCH PLAN SUPPORT RECORDS RELATED TO THE PLAN
        Map<Id, PlanSupport__c> planSupportIdVsSubstPlanSupport = new Map<Id, PlanSupport__c>([SELECT Id, Plan__c, SupportCategory__r.SupportCategoryNumber__c FROM PlanSupport__c WHERE Plan__c IN : planIdSet LIMIT 49999]);
        
        //FETCH SUPPORT ITEM RECORD RELATED TO THE SUPPORT ITEM NUMBER
        if (!supportItemNumberSet.isEmpty()) {    
            supportItemNumberVsSuppItemRec = getSupportItemVsSupportItemRec(supportItemNumberSet);
        }

        for (PlanSupportPreference__c eachRecord : newList) {
            if ((substSupportItemNumberVsSuppItemRec.isEmpty() 
                || !planSupportIdVsSubstPlanSupport.containsKey(eachRecord.SubstitutionPlanSupport__c))
                || (String.isNotBlank(eachRecord.SubstitutionSupportItemNumber__c) 
                && planSupportIdVsSubstPlanSupport.containsKey(eachRecord.SubstitutionPlanSupport__c) && substSupportItemNumberVsSuppItemRec.containsKey(eachRecord.SubstitutionSupportItemNumber__c)
                && planSupportIdVsSubstPlanSupport.get(eachRecord.SubstitutionPlanSupport__c)?.SupportCategory__r?.SupportCategoryNumber__c != substSupportItemNumberVsSuppItemRec.get(eachRecord.SubstitutionSupportItemNumber__c)?.SupportCategory__r?.SupportCategoryNumber__c)) {
                    eachRecord.addError(System.Label.PSP_SubstSupportItemPlanSupportCheck);
            }

            if (supportItemNumberVsSuppItemRec.isEmpty() 
                && (String.isNotBlank(eachRecord.SupportItemNumber__c) 
                && supportItemNumberVsSuppItemRec.containsKey(eachRecord.SupportItemNumber__c) 
                && eachRecord.Support_Category__c != supportItemNumberVsSuppItemRec.get(eachRecord.SupportItemNumber__c)?.SupportCategory__c)) {
                    eachRecord.addError(System.Label.PSP_SupportItemSupportCategoryCheck);
            }
        } //END OF FOR LOOP     
    }

    /**
     * @description         Validation to restrict user from entering a Support Item Number against which Plan Stated Support
     *                      is not Quote Required
     * @author              Rohit Tikoo
     * @param               newList : Holds trigger.new  
     *                      supportItemNumberSet : Contains Set of Support Item Numbers
     *                      planIdSet : Contains Set of Plan Id's
     * @return              -
    **/
    public static void restrictNotQuoteRequired(List<PlanSupportPreference__c> newList, Set<String> supportItemNumberSet, Set<Id> planIdSet) {
        
        Map<Id, List<PlanSupportItem__c>> planIdVsPlanSupportItem = new Map<Id, List<PlanSupportItem__c>>();
        
        for (PlanSupportItem__c eachPlanSupportItem : [SELECT Id, 
                                                              Plan__c, 
                                                              QuoteRequired__c, 
                                                              SupportItem__r.SupportItemNumber__c
                                                        FROM PlanSupportItem__c 
                                                        WHERE Plan__c IN:planIdSet 
                                                        AND SupportItem__r.SupportItemNumber__c IN:supportItemNumberSet limit 49999]) {

            if (!planIdVsPlanSupportItem.containsKey(eachPlanSupportItem.Plan__c)) {
                planIdVsPlanSupportItem.put(eachPlanSupportItem.Plan__c, new List<PlanSupportItem__c> {eachPlanSupportItem});
            } else {
                planIdVsPlanSupportItem.get(eachPlanSupportItem.Plan__c).add(eachPlanSupportItem);
            }
        }
        
        for (PlanSupportPreference__c eachRecord : newList) {
            if (String.isNotBlank(eachRecord.SupportItemNumber__c) && planIdVsPlanSupportItem.containsKey(eachRecord.Plan__c)) {
                for (PlanSupportItem__c eachPlanSupportItem : planIdVsPlanSupportItem.get(eachRecord.Plan__c)) {
                    if (eachRecord.SupportItemNumber__c == eachPlanSupportItem.SupportItem__r.SupportItemNumber__c 
                        && eachPlanSupportItem.QuoteRequired__c == 'No') {
                            eachRecord.addError(System.Label.PSP_BudgetLockCheck);
                    }
                }
            }
        } //END OF FOR LOOP
    }


    /**
     * @description         Trigger Handler for PlanSupportPreference__c Object's Trigger
     * @author              Rohit Tikoo
     * @param               newList : Holds trigger.new
     *                      supportItemNumberSet :  holds set of SupportItemNumber    
     *                      planIdSet  : holds set of Plan Ids 
     * @return              It returns pg rate   
    **/
    public static Decimal calculatePGRate(List<PlanSupportPreference__c> newList, Set<String> supportItemNumberSet, Set<Id> planIdSet) {
        Decimal max = 0.0;
        //FETCH CLIENT DATA FROM PLAN
        Map<Id, Plan__c> IdVsPlanMap = new Map<Id, Plan__c>([SELECT 
                                                                id, 
                                                                Client_Name__r.ModifiedMonashModelScore__c, 
                                                                Client_Name__r.BillingStateCode 
                                                            FROM Plan__c 
                                                            WHERE Id IN : planIdSet]);    
        
        //FETCH LIST OF SUPPORT ITEMS RELATED TO THE SUPPORT ITEM NUMBER
        Map<String, List<SupportItemPrice__c>> supportItemNumberVsListOfSupportItemPrices = getSupportItemPrice(supportItemNumberSet);

        for (PlanSupportPreference__c eachRecord : newList) {
            max = 0.0;
            if (supportItemNumberVsListOfSupportItemPrices.containsKey(eachRecord.SupportItemNumber__c)) { //CHECK IF SUPPORT ITEM NUMBER ENTERED IS VALID OR NOT
                for (SupportItemPrice__c supportItemPrice :supportItemNumberVsListOfSupportItemPrices.get(eachRecord.SupportItemNumber__c)) {
                    if  (supportItemPrice.StartDate__c <= eachRecord.EndDate__c 
                        && supportItemPrice.EndDate__c >= eachRecord.StartDate__c) {
                            if (IdVsPlanMap.containsKey(eachRecord.Plan__c) && supportItemPrice!= null) {
                                if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.ModifiedMonashModelScore__c == 7) {
                                    eachRecord.PGRate__c = supportItemPrice.VeryRemotePrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.ModifiedMonashModelScore__c == 6) {
                                    eachRecord.PGRate__c = supportItemPrice.RemotePrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.BillingStateCode == 'ACT') {
                                    eachRecord.PGRate__c = supportItemPrice.ACTPrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.BillingStateCode == 'NSW') {
                                    eachRecord.PGRate__c = supportItemPrice.NSWPrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.BillingStateCode == 'VIC') {
                                    eachRecord.PGRate__c = supportItemPrice.VICPrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.BillingStateCode == 'QLD') {
                                    eachRecord.PGRate__c = supportItemPrice.QLDPrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.BillingStateCode == 'WA') {
                                    eachRecord.PGRate__c = supportItemPrice.WAPrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.BillingStateCode == 'NT') {
                                    eachRecord.PGRate__c = supportItemPrice.NTPrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.BillingStateCode == 'SA') {
                                    eachRecord.PGRate__c = supportItemPrice.SAPrice__c;
                                } else if (IdVsPlanMap.get(eachRecord.Plan__c)?.Client_Name__r?.BillingStateCode == 'TAS') {
                                    eachRecord.PGRate__c = supportItemPrice.TASPrice__c;
                                } else {
                                    eachRecord.PGRate__c = 0;
                                }
                            }

                            if (eachRecord.PGRate__c > max) {   // [TTP-3719] Logic to fetch the max PG Rate from the set of Support Item Prices
                                max = eachRecord.PGRate__c;
                            }
                    } 
                }
            }  
        }

        return max;
    }

    /**
     * @description         Generic method to get the supportItemNumber vs List<SupportItem> Map
     * @author              Rohit Tikoo
     * @param               supportItemNumberSet : contains support Item Numbers
     * @return              Map<String, List<SupportItem__c>>      
    **/

    public static Map<String, List<SupportItemPrice__c>> getSupportItemPrice(Set<String> supportItemNumberSet) {
        Map<String, List<SupportItemPrice__c>> supportItemNumberVsListOfSupportItemPrices = new Map<String, List<SupportItemPrice__c>>();

        for (SupportItemPrice__c supportItemPrice : [SELECT EndDate__c,
                                                            StartDate__c, 
                                                            SupportItemNumber__c, SupportItem__r.SupportCategory__c, SupportItem__r.SupportCategory__r.SupportCategoryCode__c, SupportItemPriceName__c,
                                                            VeryRemotePrice__c, RemotePrice__c, ACTPrice__c, NSWPrice__c, VICPrice__c, QLDPrice__c,
                                                            WAPrice__c, NTPrice__c, SAPrice__c, TASPrice__c 
                                                            FROM SupportItemPrice__c 
                                                            WHERE SupportItemNumber__c IN :supportItemNumberSet]) {
            if (supportItemNumberVsListOfSupportItemPrices.containsKey(supportItemPrice.SupportItemNumber__c)) {
                supportItemNumberVsListOfSupportItemPrices.get(supportItemPrice.SupportItemNumber__c).add(supportItemPrice);
            } else {
                supportItemNumberVsListOfSupportItemPrices.put(supportItemPrice.SupportItemNumber__c, new List<SupportItemPrice__c>{supportItemPrice});
            }
        }

        return supportItemNumberVsListOfSupportItemPrices;
    }

    /**
     * @description         Generic method to get the supportItemNumber vs SupportItem__c
     * @author              Rohit Tikoo
     * @param               supportItemNumberSet : contains support Item Numbers    
     * @return              Map<String, SupportItem__c>  
    **/

    public static Map<String,SupportItem__c> getSupportItemVsSupportItemRec(Set<String> supportItemNumberSet) {
        Map<String, SupportItem__c> supportItemNumberVsSupportItemRec = new Map<String, SupportItem__c>();

        for (SupportItem__c eachSupportItem : [SELECT SupportItemNumber__c, 
                                                      SupportCategory__c, 
                                                      SupportCategory__r.SupportCategoryNumber__c 
                                                FROM  SupportItem__c 
                                                WHERE SupportItemNumber__c IN :supportItemNumberSet]) {                                               
            supportItemNumberVsSupportItemRec.put(eachSupportItem.SupportItemNumber__c,eachSupportItem);                                            
        }

        return supportItemNumberVsSupportItemRec;
    }

    /**
     * @description         Invocable method to be called from flow to calculate the PG rate
     * @author              Rohit Tikoo
     * @param               pspRecord : Holds Trigger.new 
     * @return              List<String> of pgRate     
    **/

    @InvocableMethod(label='Calculate PG Rate' description='Calculates PG Rate on CLient Budget Preference' category='Client Budget Preferences')
    public static List<String> getPGRate(List<PlanSupportPreference__c> pspRecord) {
        
        Decimal pgRate = calculatePGRate(new List<PlanSupportPreference__c> {pspRecord[0]}, new Set<String> {pspRecord[0].SupportItemNumber__c}, new Set<Id> {pspRecord[0].Plan__c});

        return new List<String> {String.ValueOf(pgRate)};
    }

    /**
     * @description         Method to restrict EndDate on ClaimAs Record in comparision to child Line Items
     * @author              Rohit Tikoo
     * @param               pspRecordList : Holds Trigger.new of Plan Support Preference
     *                      pspIdSet : Holds Set<Id> of Plan Support Preference          
     * @return              -
    **/

    public static void checkEndDateWithLineItem(List<PlanSupportPreference__c> pspRecordList, Set<Id> pspIdSet) {
        
        Map<Id, Date> idVsEndDateMap = new Map<Id, Date>();       
        if (!pspIdSet.isEmpty()) {
            for (AggregateResult eachRecord : [SELECT Substitution_Plan_Support_Preferences__c,  
                                                      MAX(Service_Date_To__c) maxEndDate 
                                                FROM Invoice_Line_Item__c 
                                                WHERE Status__c != 'Cancelled' 
                                                AND Substitution_Plan_Support_Preferences__c IN : pspIdSet 
                                                GROUP BY Substitution_Plan_Support_Preferences__c]) {   
                idVsEndDateMap.put(String.ValueOf(eachRecord.get('Substitution_Plan_Support_Preferences__c')), Date.ValueOf(eachRecord.get('maxEndDate')));
            }
    
            for (PlanSupportPreference__c eachRecord : pspRecordList) {
                if (idVsEndDateMap.containsKey(eachRecord.Id) && eachRecord.EndDate__c < idVsEndDateMap.get(eachRecord.Id)) {
                    eachRecord.addError('End Date should be greater than maximum end date ('+String.ValueOf(idVsEndDateMap.get(eachRecord.Id)).removeEnd(' 00:00:00')+') of associated child Invoice Line Items');
                }
            }
        }
    }
}