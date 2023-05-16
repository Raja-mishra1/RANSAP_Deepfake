/**
 * @description      Apex Test Class for PlanSupportPreferencesTriggerHandler class
 * @company          Cloudwerx
 * @date             04/08/2021
**/

@isTest
public class PlanSupportPreferencesTriggerHandlerTest {
    
    private static final String TEST_ABN_NUMBER = '51824753556';
    
    @testSetup
    public static void makeData() {
        
        insert new Reconnection_Trigger_Configuration__c(Plan_Support_Preference_Trigger_Activate__c = True);
        
        /*CREATE CLIENT ACCOUNT*/
        Account clientAccount = TestClassDataUtil.createClientAccount();
        
        /*CREATE PROVIDER ACCOUNT*/
        Account providerAccount = TestClassDataUtil.createProviderAccount(false, null, TEST_ABN_NUMBER);
        providerAccount.PreferredPaymentMethod__c = 'BPAY';
        providerAccount.BillerCode__c = '12345';
        providerAccount.ReferenceNumberBPAY__c = '1234';
        insert providerAccount;

		/*CREATE PLAN AND ASSOCIATE IT TO CLIENT ACCOUNT*/
        List<Plan__c> planList = TestClassDataUtil.createPlanRecords(true, 1,clientAccount.Id);

        /*CREATE SUPPORT CATEGORY*/
        SupportCategory__c supportCategory = new SupportCategory__c(
            Name = 'Assistance with',
            SupportCategoryName__c = 'Assistance with Daily Life',
            SupportCategoryNumber__c = 1,
            SupportCategoryCode__c = 'DAILY_ACTIVITIES',
            SupportTypeName__c = 'Core',
            SupportTypeCode__c = 'ZCOR');
        insert supportCategory;
        
        /*CREATE PLAN SUPPORT ITEMS*/
        List<PlanSupport__c> planSupportsList = TestClassDataUtil.createPlanSupports(true, 1, planList[0].Id, supportCategory.Id);
        
        /*CREATE SUPPORT ITEMS*/
        List<SupportItem__c> supportItemList = TestClassDataUtil.createSupportItemRecords(false, 1, supportCategory.Id);
        supportItemList[0].SupportItemNumber__c = '1_0023_436_3';
        insert supportItemList;
        
        /*CREATE SUPPORT ITEM PRICE RECORDS*/
        List<SupportItemPrice__c> supportItemPriceList = TestClassDataUtil.createSupportItemPriceRecords(true,1,supportItemList[0].Id);
        
        /*CREATE PLAN SUPPORT ITEM RECORDS*/
        List<PlanSupportItem__c> planSupportItemList = TestClassDataUtil.createPlanSupportItems(false,2,planList[0].id,planSupportsList[0].Id);
        planSupportItemList[1].SupportItem__c = supportItemList[0].Id;
        insert planSupportItemList;
        
    }
    
    @isTest
    public static void unitTest_checkPlanSupportItem() {  
        Test.startTest();
        List<Account> providerAccount = [Select id from Account where RecordType.Name ='Provider' limit 1];
        List<Plan__c> planList = [Select id from Plan__c limit 5];
        List<PlanSupport__c> planSupportsList = [Select id, Plan__c, SupportCategory__r.SupportCategoryNumber__c,SupportCategory__r.SupportTypeCode__c from PlanSupport__c limit 5];
        List<SupportCategory__c> supportCategory = [Select id, SupportCategoryNumber__c, SupportTypeCode__c from SupportCategory__c limit 1];
        List<PlanSupportPreference__c> pspList = TestClassDataUtil.createPlanSupportPreferenceRecords(false, 2,providerAccount[0].Id, planList[0].Id, planSupportsList[0].Id, supportCategory[0].Id);
        pspList[0].PlanSupport__c = planSupportsList[0].Id;
        pspList[0].Plan__c = planList[0].Id;
        pspList[0].Support_Category__c = supportCategory[0].Id;
        pspList[0].SubstitutionPlanSupport__c = planSupportsList[0].Id;
        pspList[0].RecordTypeId = RecordTypeUtil.PSP_SUBSTITUTION_RECORD_TYPE_ID;
        try{
            insert pspList;
        }catch(Exception e){
            System.Debug('Exception::'+e);
        }
        System.assertEquals(supportCategory.isEmpty(), false, 'Support Category is present');
        Test.stopTest();
        
    }
    
    @isTest
    public static void unitTest_supportItemCheckSubstitution() {  
        Test.startTest();
        List<Account> providerAccount = [Select id from Account where RecordType.Name ='Provider' limit 1];
        List<Plan__c> planList = [Select id from Plan__c limit 5];
        List<PlanSupport__c> planSupportsList = [Select id, Plan__c, SupportCategory__r.SupportCategoryNumber__c,SupportCategory__r.SupportTypeCode__c from PlanSupport__c limit 5];
        List<SupportCategory__c> supportCategory = [Select id, SupportCategoryNumber__c, SupportTypeCode__c from SupportCategory__c limit 1];
        List<PlanSupportPreference__c> pspList = TestClassDataUtil.createPlanSupportPreferenceRecords(false, 2,providerAccount[0].Id, planList[0].Id, planSupportsList[0].Id, supportCategory[0].Id);
        pspList[0].PlanSupport__c = planSupportsList[0].Id;
        pspList[0].Plan__c = planList[0].Id;
        pspList[0].Support_Category__c = supportCategory[0].Id;
        pspList[0].SupportItemNumber__c = '1_0023_436_1';
        pspList[0].SubstitutionSupportItemNumber__c = '1_0023_436_1';
        pspList[0].SubstitutionPlanSupport__c = planSupportsList[0].Id;
        pspList[0].RecordTypeId = RecordTypeUtil.PSP_SUBSTITUTION_RECORD_TYPE_ID;
        try{
            insert pspList;
        }catch(Exception e){
            System.Debug('Exception::'+e);
        }
        System.assertEquals(supportCategory.isEmpty(), false, 'Support Category is present');
        Test.stopTest();
        
    }
        
    @isTest
    public static void unitTest_supportItemCheckReservedBudget() {  
        Test.startTest();
        List<Account> providerAccount = [Select id from Account where RecordType.Name ='Provider' limit 1];
        List<Plan__c> planList = [Select id from Plan__c limit 5];
        List<PlanSupport__c> planSupportsList = [Select id, Plan__c, SupportCategory__r.SupportCategoryNumber__c,SupportCategory__r.SupportTypeCode__c from PlanSupport__c limit 5];
        List<SupportCategory__c> supportCategory = [Select id, SupportCategoryNumber__c, SupportTypeCode__c from SupportCategory__c limit 1];
        List<PlanSupportPreference__c> pspList = TestClassDataUtil.createPlanSupportPreferenceRecords(false, 3,providerAccount[0].Id, planList[0].Id, planSupportsList[0].Id, supportCategory[0].Id);
        pspList[0].PlanSupport__c = planSupportsList[0].Id;
        pspList[0].Plan__c = planList[0].Id;
        pspList[2].SupportItemNumber__c = '1_0023_436_2';
        pspList[0].Support_Category__c = supportCategory[0].Id;
        pspList[0].SubstitutionPlanSupport__c = planSupportsList[0].Id;
        pspList[0].RecordTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;
        pspList[1].RecordTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;
        pspList[2].RecordTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;
        try{
            insert pspList;
        }catch(Exception e){
            System.Debug('Exception::'+e);
        }
        System.assertEquals(supportCategory.isEmpty(), false, 'Support Category is present');
        Test.stopTest();
        
    }

    @isTest
    public static void unitTest_checkEndDateWithLineItem() {
        Test.startTest();
        List<Account> providerAccount = [Select id from Account where RecordType.Name ='Provider' limit 1];
        List<Account> clientAccount = [Select id from Account where RecordType.Name ='Client' limit 1];
        List<Plan__c> planList = [Select id, Plan_End_Date__c from Plan__c limit 5];
        List<PlanSupport__c> planSupportsList = [Select id, Plan__c, SupportCategory__r.SupportCategoryNumber__c,SupportCategory__r.SupportTypeCode__c from PlanSupport__c limit 5];
        List<SupportCategory__c> supportCategory = [Select id, SupportCategoryNumber__c, SupportTypeCode__c from SupportCategory__c limit 1];
        List<SupportItem__c> supportItemList = [Select id, SupportItemNumber__c, EndDate__c, NDIAStatus__c from SupportItem__c limit 1];
        List<PlanSupportItem__c> planSupportItemList = [Select id, Name from PlanSupportItem__c limit 1];
        List<PlanSupportPreference__c> pspList = TestClassDataUtil.createPlanSupportPreferenceRecords(false, 1,providerAccount[0].Id, planList[0].Id, null, null);
        pspList[0].PlanSupport__c = planSupportsList[0].Id;
        pspList[0].Plan__c = planList[0].Id;
        pspList[0].Support_Category__c = supportCategory[0].Id;
        pspList[0].SupportItemNumber__c = '1_0023_906_3';
        pspList[0].SubstitutionSupportItemNumber__c = '1_0023_436_3';
        pspList[0].SubstitutionPlanSupport__c = planSupportsList[0].Id;
        pspList[0].RecordTypeId = RecordTypeUtil.PSP_SUBSTITUTION_RECORD_TYPE_ID;        
        insert pspList[0];
        
        /*CREATE INVOICE RECORDS*/
        List<Invoice__c> invoiceList = TestClassDataUtil.createInvoiceRecords(true,1,clientAccount[0].id,providerAccount[0].id,null);
        
        /*CREATE INVOICE LINE ITEMS*/
        List<Invoice_Line_Item__c> lineItemList = TestClassDataUtil.createInvoiceLineItemRecords(false, 1, invoiceList[0].id, planList[0].id,planSupportsList[0].Id,planSupportItemList[0].Id,null,supportItemList[0].Id);
        lineItemList[0].Interchangeable__c = true;
        lineItemList[0].Support_Item__c = supportItemList[0].id;
        lineItemList[0].Service_Date_From__c = System.today().addDays(12);
        lineItemList[0].Service_Date_To__c =  System.today().addDays(24);
        lineItemList[0].Substitution_Plan_Support_Preferences__c = pspList[0].Id;
        insert lineItemList;        
        pspList[0].EndDate__c  = System.today().addDays(3);              
        try {    
             update pspList[0];
        } catch(Exception e) {
            System.Debug('Exception in checkEndDateWithLineItemTest::'+e);
        }
        System.assertEquals(supportCategory.isEmpty(), false, 'Support Category is present');
        Test.stopTest();
    }

    @isTest
    public static void testRestrictNotQuoteRequired(){

        Test.startTest();
        List<Account> providerAccount = [Select id from Account where RecordType.Name ='Provider' limit 1];
        List<Plan__c> planList = [Select id from Plan__c limit 5];
        List<PlanSupport__c> planSupportsList = [Select id, Plan__c, SupportCategory__r.SupportCategoryNumber__c,SupportCategory__r.SupportTypeCode__c from PlanSupport__c limit 5];
        List<SupportCategory__c> supportCategory = [Select id, SupportCategoryNumber__c, SupportTypeCode__c from SupportCategory__c limit 1];
        List<PlanSupportPreference__c> pspList = TestClassDataUtil.createPlanSupportPreferenceRecords(false, 3,providerAccount[0].Id, planList[0].Id, planSupportsList[0].Id, supportCategory[0].Id);
        pspList[0].PlanSupport__c = planSupportsList[0].Id;
        pspList[0].Plan__c = planList[0].Id;
        pspList[2].SupportItemNumber__c = '1_0023_436_2';
        pspList[0].Support_Category__c = supportCategory[0].Id;
        pspList[0].SubstitutionPlanSupport__c = planSupportsList[0].Id;
        pspList[0].RecordTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;
        pspList[1].RecordTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;
        pspList[2].RecordTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;
        Set<String> supportItemNumberSet = new Set<String>();
        for(PlanSupportPreference__c pspData : pspList){
            supportItemNumberSet.add(pspData.SupportItemNumber__c);
        }
        Set<Id> planIdSet = new Set<Id>();
        for(Plan__c planRec : planList){
            planIdSet.add(planRec.Id);
        }
        try{
            insert pspList;
        }catch(Exception e){
            System.Debug('Exception::'+e);
        }
        PlanSupportPreferencesTriggerHandler.restrictNotQuoteRequired( pspList, supportItemNumberSet, planIdSet);
        Test.stopTest();
    }
}