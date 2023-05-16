/**
 * @description  [AHOD-394] Test class for NDIA_CoreSpendingSMSNotificationBatch, NDIA_CoreSpendingSMSNotificationBatchJob
 * @company      Cloudwerx
 * @date         28/07/2022
**/

@isTest
public class NDIA_CoreSpendingSMSNtfBatchTest {
    private static final String TEST_ABN_NUMBER = '51824753556';

    @testSetup
    public static void makeData() {
        /*CREATE CLIENT ACCOUNT*/
        Account clientAccount = TestClassDataUtil.createClientAccount();
        clientAccount.Salesforce_Claiming_Experience__c = true;
        update clientAccount;

        /*CREATE PROVIDER ACCOUNT*/
        Account providerAccount = TestClassDataUtil.createProviderAccount(true, null, TEST_ABN_NUMBER);

        /*CREATE CONTACT*/
        List<Contact> primaryContact = TestClassDataUtil.createContactRecords(1 ,false, providerAccount.Id);
        primaryContact[0].MobilePhone = '0423456789';
        primaryContact[0].PlanManager__c = 'MPM';   // [OPSNBOTS-271]
        Insert primaryContact;
        
        /*CREATE ACCOUNT CONTACT RELATION*/
        AccountContactRelation acr = TestClassDataUtil.createAccountContactRelationRecords(
            false,clientAccount.Id,primaryContact[0].Id
        );
        acr.SMS_Notification__c = true;
        Insert acr;

        /*CREATE PLAN AND ASSOCIATE IT TO CLIENT ACCOUNT*/
        List<Plan__c> planList = TestClassDataUtil.createPlanRecords(false, 2, clientAccount.Id);
        planList[0].PlanManager__c = 'MPM';
        planList[1].PlanManager__c = 'MPM';
        insert planList;
        
        /* CREATE SUPPORT CATEGORY */
        List<SupportCategory__c> scList = TestClassDataUtil.createSupportCategoryRecords(false,5);
        scList[0].SupportCategoryCode__c = 'DAILY_ACTIVITIES';
        scList[1].SupportCategoryCode__c = 'SOCIAL_COMMUNITY_CIVIC';
        scList[2].SupportCategoryCode__c = 'CONSUMABLES';
        scList[3].SupportCategoryCode__c = 'HOME_MODIFICATIONS';
        insert scList;
        
        /*CREATE PLAN SUPPORT RECORD*/
        List<PlanSupport__c> planSupportsList1 = TestClassDataUtil.createPlanSupports(
            false, 1, planList[0].Id, scList[0].Id
        );
        List<PlanSupport__c> planSupportsList2 = TestClassDataUtil.createPlanSupports(
            false, 1, planList[0].Id, scList[1].Id
        );
        List<PlanSupport__c> planSupportsList3 = TestClassDataUtil.createPlanSupports(
            false, 1, planList[0].Id, scList[2].Id
        );
        List<PlanSupport__c> planSupportsList4 = TestClassDataUtil.createPlanSupports(
            false, 1, planList[0].Id, scList[3].Id
        );
        List<PlanSupport__c> planSupportsList5 = TestClassDataUtil.createPlanSupports(
            false, 1, planList[0].Id, scList[4].Id
        );
        
        planSupportsList1[0].FundsApproved__c = 700; //56 SpentPercentage__c
        planSupportsList1[0].PlanManagementType__c = 'ZCOR_PLAN';
        planSupportsList2[0].PlanManagementType__c = 'ZCOR_PLAN';
        planSupportsList3[0].PlanManagementType__c = 'ZCOR_PLAN';
        planSupportsList4[0].PlanManagementType__c = 'ZCOR_PLAN';
        planSupportsList5[0].PlanManagementType__c = 'ZCOR_PLAN';
        planSupportsList2[0].FundsApproved__c = 600;  //84
        planSupportsList3[0].FundsApproved__c = 580;  //89
        planSupportsList4[0].FundsApproved__c = 550;  //92
        planSupportsList5[0].FundsApproved__c = 500; //98
        planSupportsList1[0].MPMFundsSpent__c = 500;
        planSupportsList2[0].MPMFundsSpent__c = 600;
        planSupportsList3[0].MPMFundsSpent__c = 500;
        planSupportsList4[0].MPMFundsSpent__c = 500;
        planSupportsList5[0].MPMFundsSpent__c = 500;
        
        List<PlanSUpport__c> planSupportList = new List<PlanSupport__c>();
        planSupportList.addAll(planSupportsList1);
        planSupportList.addAll(planSupportsList2);
        planSupportList.addAll(planSupportsList3);
        planSupportList.addAll(planSupportsList4);
        planSupportList.addAll(planSupportsList5);
        Insert planSupportList;
        Formula.recalculateFormulas(planSupportList);
        Formula.recalculateFormulas(planList);
    }

    public static void createUser() {
        List<User> userList =  TestClassDataUtil.createUserRecords(1, false, 'System Administrator');
        userList[0].email = 'mpmit@myplanmanager.com.au';
        Insert userList;
    }

    @isTest
    public static void unitTest_notificationSuccess() {
        createUser();

        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(201, '{"sid":"SM6ff06e8c1ce745b1a0f0ee062cd01e67","date_created":"Fri, 25 Feb 2022 07:05:44 +0000","date_updated":"Fri, 25 Feb 2022 07:05:44 +0000","date_sent":null,"account_sid":"AC68b3662de1f550583f5457da1bcb0a77","to":"+5571981265131","from":"+15005550006","messaging_service_sid":null,"body":"All in the game, yo","status":"queued","num_segments":"1","num_media":"0","direction":"outbound-api","api_version":"2010-04-01","price":null,"price_unit":"USD","error_code":null,"error_message":null,"uri":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67.json","subresource_uris":{"media":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67/Media.json"}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        Test.startTest();
            AsyncApexFramework.submitBatch(new NDIA_CoreSpendingSMSNotificationBatch(), 200, 99);
            AsyncApexFramework.flush();
        Test.stopTest();
    }

    @isTest 
    public static void unitTest_notificationFailure() {
        createUser();

        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(400, '{"sid":"SM6ff06e8c1ce745b1a0f0ee062cd01e67","date_created":"Fri, 25 Feb 2022 07:05:44 +0000","date_updated":"Fri, 25 Feb 2022 07:05:44 +0000","date_sent":null,"account_sid":"AC68b3662de1f550583f5457da1bcb0a77","to":"+5571981265131","from":"+15005550006","messaging_service_sid":null,"body":"All in the game, yo","status":"queued","num_segments":"1","num_media":"0","direction":"outbound-api","api_version":"2010-04-01","price":null,"price_unit":"USD","error_code":null,"error_message":null,"uri":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67.json","subresource_uris":{"media":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67/Media.json"}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        Test.startTest();
            AsyncApexFramework.submitBatch(new NDIA_CoreSpendingSMSNotificationBatch(), 200, 99);
            AsyncApexFramework.flush();
        Test.stopTest();
    }

    @isTest 
    public static void unitTest_scheduler() {
        createUser();

        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(201, '{"sid":"SM6ff06e8c1ce745b1a0f0ee062cd01e67","date_created":"Fri, 25 Feb 2022 07:05:44 +0000","date_updated":"Fri, 25 Feb 2022 07:05:44 +0000","date_sent":null,"account_sid":"AC68b3662de1f550583f5457da1bcb0a77","to":"+5571981265131","from":"+15005550006","messaging_service_sid":null,"body":"All in the game, yo","status":"queued","num_segments":"1","num_media":"0","direction":"outbound-api","api_version":"2010-04-01","price":null,"price_unit":"USD","error_code":null,"error_message":null,"uri":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67.json","subresource_uris":{"media":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67/Media.json"}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        Test.startTest();
            NDIA_CoreSpendingSMSNotificationBatchJob.scheduleSMSNotificationBatch();
        Test.stopTest();
    }
}