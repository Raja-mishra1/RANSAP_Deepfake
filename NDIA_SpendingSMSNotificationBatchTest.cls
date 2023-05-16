/**
 * @description  Test class for NDIA_SpendingSMSNotificationBatch, NDIA_SpendingSMSNotificationBatchJob
 * @company      Cloudwerx
 * @date         28/07/2022
**/

@isTest 
public with sharing class NDIA_SpendingSMSNotificationBatchTest {
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
        List<Plan__c> planList = TestClassDataUtil.createPlanRecords(true, 2, clientAccount.Id);
        
        /* CREATE SUPPORT CATEGORY */
        List<SupportCategory__c> scList = TestClassDataUtil.createSupportCategoryRecords(true,1);

        /*CREATE PLAN SUPPORT RECORD*/
        List<PlanSupport__c> planSupportsList = TestClassDataUtil.createPlanSupports(
            false, 5, planList[0].Id, scList[0].Id
        );
        planSupportsList[0].PlanManager__c = 'MPM';
        planSupportsList[1].PlanManager__c = 'MPM';
        planSupportsList[2].PlanManager__c = 'MPM';
        planSupportsList[3].PlanManager__c = 'MPM';
        planSupportsList[4].PlanManager__c = 'MPM';

        planSupportsList[0].MPMFundsSpent__c = 380;
        planSupportsList[1].MPMFundsSpent__c = 550;
        planSupportsList[2].MPMFundsSpent__c = 400;
        planSupportsList[3].MPMFundsSpent__c = 540;
        planSupportsList[4].MPMFundsSpent__c = 350;
        planSupportsList[0].FundsApproved__c = 700; //56 SpentPercentage__c
        planSupportsList[1].FundsApproved__c = 600;  //84
        planSupportsList[2].FundsApproved__c = 580;  //89
        planSupportsList[3].FundsApproved__c = 550;  //92
        planSupportsList[4].FundsApproved__c = 500; //98
        Insert planSupportsList;
    }
    
    public static void createUser() {
        List<User> userList =  TestClassDataUtil.createUserRecords(1, false, 'System Administrator');
        userList[0].email = 'mpmit@myplanmanager.com.au';
        Insert userList;
    }

    @isTest 
    public static void unitTest_notificationSucccess () {
        createUser();
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(201, '{"sid":"SM6ff06e8c1ce745b1a0f0ee062cd01e67","date_created":"Fri, 25 Feb 2022 07:05:44 +0000","date_updated":"Fri, 25 Feb 2022 07:05:44 +0000","date_sent":null,"account_sid":"AC68b3662de1f550583f5457da1bcb0a77","to":"+5571981265131","from":"+15005550006","messaging_service_sid":null,"body":"All in the game, yo","status":"queued","num_segments":"1","num_media":"0","direction":"outbound-api","api_version":"2010-04-01","price":null,"price_unit":"USD","error_code":null,"error_message":null,"uri":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67.json","subresource_uris":{"media":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67/Media.json"}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        Test.startTest();
            AsyncApexFramework.submitBatch(new NDIA_SpendingSMSNotificationBatch(), 200, 99);
            AsyncApexFramework.flush();
        Test.stopTest();
    }

    @isTest 
    public static void unitTest_notificationFailure () {
        createUser();
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(400, '{"sid":"SM6ff06e8c1ce745b1a0f0ee062cd01e67","date_created":"Fri, 25 Feb 2022 07:05:44 +0000","date_updated":"Fri, 25 Feb 2022 07:05:44 +0000","date_sent":null,"account_sid":"AC68b3662de1f550583f5457da1bcb0a77","to":"+5571981265131","from":"+15005550006","messaging_service_sid":null,"body":"All in the game, yo","status":"queued","num_segments":"1","num_media":"0","direction":"outbound-api","api_version":"2010-04-01","price":null,"price_unit":"USD","error_code":null,"error_message":null,"uri":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67.json","subresource_uris":{"media":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67/Media.json"}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        Test.startTest();
            AsyncApexFramework.submitBatch(new NDIA_SpendingSMSNotificationBatch(), 200, 99);
            AsyncApexFramework.flush();
        Test.stopTest();
    }

    @isTest 
    public static void unitTest_schedularTest() {
        createUser();
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(201, '{"sid":"SM6ff06e8c1ce745b1a0f0ee062cd01e67","date_created":"Fri, 25 Feb 2022 07:05:44 +0000","date_updated":"Fri, 25 Feb 2022 07:05:44 +0000","date_sent":null,"account_sid":"AC68b3662de1f550583f5457da1bcb0a77","to":"+5571981265131","from":"+15005550006","messaging_service_sid":null,"body":"All in the game, yo","status":"queued","num_segments":"1","num_media":"0","direction":"outbound-api","api_version":"2010-04-01","price":null,"price_unit":"USD","error_code":null,"error_message":null,"uri":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67.json","subresource_uris":{"media":"/2010-04-01/Accounts/AC68b3662de1f550583f5457da1bcb0a77/Messages/SM6ff06e8c1ce745b1a0f0ee062cd01e67/Media.json"}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        Test.startTest();
            NDIA_SpendingSMSNotificationBatchJob.scheduleSMSNotificationBatch();
        Test.stopTest();
    }
}