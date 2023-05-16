@isTest
public with sharing class ClientBudgetCategoryBatchTest {

    private static final String TEST_ABN_NUMBER = '51824753556';
    
    @testSetup
    public static void makeData() {
          /*CREATE CLIENT ACCOUNT*/
        Account clientAccount = TestClassDataUtil.createClientAccount();
        clientAccount.MPM_ID__c = 1234;
        update clientAccount;
        
        Account testProviderAccount = TestClassDataUtil.createProviderAccount(false, null, '29009415703');
        insert testProviderAccount;

        /*CREATE PLAN AND ASSOCIATE IT TO CLIENT ACCOUNT*/
        List<Plan__c> planList = TestClassDataUtil.createPlanRecords(false, 1,clientAccount.Id);
        planList[0].MPM_Plan_Id__c = 5678;
        insert planList;

        /* CREATE SUPPORT CATEGORY */
        List<SupportCategory__c> scList = TestClassDataUtil.createSupportCategoryRecords(true,1);

        /*CREATE PLAN SUPPORT RECORD*/
        List<PlanSupport__c> planSupportsList1 = TestClassDataUtil.createPlanSupports(true, 1, planList[0].Id, scList[0].Id);
        
        List<PlanSupportItem__c> planSupportItemList = TestClassDataUtil.createPlanSupportItems(true,1,planList[0].id,planSupportsList1[0].Id);
        
        List<PlanSupportPreference__c> lockedBudgetList = TestClassDataUtil.createPlanSupportPreferenceRecords(true,1,testProviderAccount.Id,planList[0].Id,planSupportsList1[0].Id,scList[0].Id);
        lockedBudgetList[0].RecordTypeId = RecordTypeUtil.PSP_RESERVED_BUDGET_RECORD_TYPE_ID;
        update lockedBudgetList[0];
        
        List<SupportItem__c> supportItem = TestClassDataUtil.createSupportItemRecords(true,1,scList[0].Id);
    }

    @isTest
    public static void unitTest_checkPlanSupportItem() {
        Test.startTest();
        Database.executeBatch(new ClientBudgetCategoryBatch());
        Test.stopTest();
    }

}