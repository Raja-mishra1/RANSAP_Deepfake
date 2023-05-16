/*
* Name : AccountTriggerHandler
* Created by: Sumita Dabas
* Created Date: 23 Dec 2019
*/

@IsTest
private class AccountTriggerHandlerTest {

    private static final String TEST_ABN_NUMBER = '51824753556';

    @TestSetup
    static void makeData(){
        insert new Reconnection_Trigger_Configuration__c(Account_Trigger_Activated__c = True, MPMAccountNumberMethodActivated__c = true);
        insert new EditFieldSettings__c(IsMPMAccountNumberEditable__c = True);
    }

    // Call this method in every test method
    public static void test_mockCallout() {
        GenericMockCallouts fakeResponse = new GenericMockCallouts(200,'{"access_token": "","expires_in":3600, "token_type" : "Bearer"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse);
    }

    @IsTest
    private static void testCopyNameFieldForAccounts() {
        test_mockCallout();
        Account account = TestClassDataUtil.createClientAccount();
        account = [SELECT Id, Name, RO_Name__c FROM Account WHERE Id = :account.Id];

        System.assertEquals(account.Name, account.RO_Name__c);
    }

    @IsTest
    private static void testCheckABNChangeOnProvider() {
        test_mockCallout();
        Exception ex;

        Account parentAccount = TestClassDataUtil.createProviderAccount(null, TEST_ABN_NUMBER);
        Account childAccount = TestClassDataUtil.createProviderAccount(parentAccount.Id, TEST_ABN_NUMBER);

        parentAccount.ABN__c = '101';

        try {
            update parentAccount;
        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
        System.assert(ex.getMessage().contains(AccountTriggerHandler.PROVIDER_HIERARCHY_ABN_ERROR_MESSAGE));
    }

    @IsTest
    private static void testCheckProviderHierarchyLimit() {
        test_mockCallout();
        Exception ex;

        Account unrelatedAccount = TestClassDataUtil.createProviderAccount(null, null);
        Account parentAccount = TestClassDataUtil.createProviderAccount(null, TEST_ABN_NUMBER);
        Account childAccount = TestClassDataUtil.createProviderAccount(parentAccount.Id, TEST_ABN_NUMBER);

        parentAccount.ParentId = unrelatedAccount.Id;
        try {
            update parentAccount;
        } catch (Exception e) {
            ex = e;
        }

        System.assertNotEquals(null, ex);
        System.assert(ex.getMessage().contains(AccountTriggerHandler.PROVIDER_HIERARCHY_LIMIT_ERROR_MESSAGE));
    }

    @IsTest
    private static void testFollowCasesForOneToOneAccount() {
        test_mockCallout();
        Case c;
        User testUser = TestClassDataUtil.createTestStandardUser();
        system.runAs(testUser){
            c = TestClassDataUtil.createCase(testUser.Id);
            Account account = TestClassDataUtil.createClientAccount();
            account.Pod__c = null;
            account.One_to_One_Account__c = true;
            account.OwnerId = testUser.Id;
            c.Client__c = account.Id;

            update c;
            update account;
        }
        List<EntitySubscription> caseFollows = [SELECT Id, SubscriberId FROM EntitySubscription WHERE ParentId = :c.Id];
        System.assertEquals(0, caseFollows.size());
        //System.assertEquals(testUser.Id, caseFollows[0].SubscriberId);
    }

    @IsTest
    private static void testFollowCasesForOneToOneProviderAccount() {
        test_mockCallout();
        Case c;
        User testUser = TestClassDataUtil.createTestStandardUser();
        system.runAs(testUser){
            c = TestClassDataUtil.createCase(testUser.Id);
            Account clientAccount = TestClassDataUtil.createClientAccount();
            Account providerAccount = TestClassDataUtil.createProviderAccount(null, TEST_ABN_NUMBER);
            providerAccount.One_to_One_Account__c = true;
            providerAccount.OwnerId = testUser.Id;
            update providerAccount;
        }
        List<EntitySubscription> caseFollows = [SELECT Id, SubscriberId FROM EntitySubscription WHERE ParentId = :c.Id];
        System.assertEquals(0, caseFollows.size());
    }

    @IsTest
    private static void testCopyProviderBusinessEmailToRemittance() {
        test_mockCallout();
        Account account = TestClassDataUtil.createProviderAccount(null);
        account = [SELECT Id, Name, Business_Email__c, Provider_Remittance_Email_Address__c FROM Account WHERE Id = :account.Id ];
        System.assertEquals(account.Business_Email__c, account.Provider_Remittance_Email_Address__c);
    }

    @IsTest
    private static void testhandleBeforeClientTrigger() {
        test_mockCallout();
        General_T2P_Settings__c custSetting = new General_T2P_Settings__c(ACE_Pod_Names__c = 'Exception,AccountTest');
        insert custSetting;

        List<Pod__c> podList = new List<Pod__c>();
        test.startTest();
        for(integer i =0; i<=1; i++) {
            Pod__c pod = new Pod__c(Name ='Test' +i, Pod_Type__c = 'Regional', PlanManager__c = 'MPM');
            podList.add(pod);
        }
        insert podList;
        Pod__c exPod = new Pod__c(Name = 'Exception', Pod_Type__c = 'Regional');
        insert exPod;
        List<Pod_Territory__c> podTerList = new List<Pod_Territory__c>();
        Pod_Territory__c podT1 = new Pod_Territory__c(Pod__c = podList[0].Id, StartingPostCode__c = 4000, EndingPostCode__c = 5000, PlanManager__c = 'MPM');
        Pod_Territory__c podT2 = new Pod_Territory__c(Pod__c = podList[1].Id, StartingPostCode__c = 6000, EndingPostCode__c = 7000, PlanManager__c = 'MPM');
        podTerList.add(podT1);
        podTerList.add(podT2);
        insert podTerList;
        Account acc = new Account(FirstName = 'Test', Pod__c = null,Status__c = 'Active', Last_Exit_Date__c = System.today(), LastName = 'HelloTest', Cultural_Needs__c = False, NDIS__c = '432156987', BillingPostalCode='4001', RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID, PlanManager__c='MPM');
        try {
            insert acc;
        } catch(Exception ex) {
            System.debug('Following Exception came'+ ex);
        }
        
        Account ExceptionAccount = new Account(FirstName = 'Test', Pod__c = exPod.Id, Status__c = 'Active', Last_Exit_Date__c = System.today(), LastName = 'Hello', Cultural_Needs__c = False, NDIS__c = '432156787', BillingPostalCode='', RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID, PlanManager__c = 'MPM');
        insert ExceptionAccount;
        Account a = [Select Id, Pod__c ,BillingPostalCode FROM Account where id=: acc.Id];
        a.BillingPostalCode = '6000';
        update a;
        Test.stopTest();
        Account accupdate = [Select Id, Pod__c ,BillingPostalCode FROM Account where id=: a.Id];
        System.assertEquals(accupdate.Pod__c, podT2.Pod__c);

        Account podAccount = new Account(FirstName = 'Test', Pod__c = exPod.Id, Status__c = 'Active', Last_Exit_Date__c = System.today(), LastName = 'Hello', Cultural_Needs__c = False, NDIS__c = '43215678', BillingPostalCode='6000', RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID, PlanManager__c = 'MPM');
        insert podAccount;
        System.assertEquals(podAccount.Pod__c, exPod.Id);
    }

    @IsTest
    private static void testhandleBeforeClientTriggerNDSP() {
        test_mockCallout();
        General_T2P_Settings__c custSetting = new General_T2P_Settings__c(ACE_Pod_Names__c = 'NDSP Exception,AccountTest');
        insert custSetting;

        List<Pod__c> podList = new List<Pod__c>();
        test.startTest();
        for(integer i =0; i<=1; i++) {
            Pod__c pod = new Pod__c(Name ='Test' +i, Pod_Type__c = 'Regional', PlanManager__c = 'NDSP');
            podList.add(pod);
        }
        insert podList;
        Pod__c exPod = new Pod__c(Name = 'NDSP Exception', Pod_Type__c = 'Regional');
        insert exPod;
        List<Pod_Territory__c> podTerList = new List<Pod_Territory__c>();
        Pod_Territory__c podT1 = new Pod_Territory__c(Pod__c = podList[0].Id, StartingPostCode__c = 4000, EndingPostCode__c = 5000, PlanManager__c = 'NDSP');
        Pod_Territory__c podT2 = new Pod_Territory__c(Pod__c = podList[1].Id, StartingPostCode__c = 6000, EndingPostCode__c = 7000, PlanManager__c = 'NDSP');
        podTerList.add(podT1);
        podTerList.add(podT2);
        insert podTerList;
        Account acc = new Account(FirstName = 'Test', Pod__c = null,Status__c = 'Active', Last_Exit_Date__c = System.today(), LastName = 'HelloTest', Cultural_Needs__c = False, NDIS__c = '432156987', BillingPostalCode='4001', RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID, PlanManager__c='NDSP');
        try {
            insert acc;
        } catch(Exception ex) {
            System.debug('Following Exception came'+ ex);
        }
        
        Account ExceptionAccount = new Account(FirstName = 'Test', Pod__c = exPod.Id, Status__c = 'Active', Last_Exit_Date__c = System.today(), LastName = 'Hello', Cultural_Needs__c = False, NDIS__c = '432156787', BillingPostalCode='', RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID, PlanManager__c = 'NDSP');
        insert ExceptionAccount;
        Account a = [Select Id, Pod__c ,BillingPostalCode FROM Account where id=: acc.Id];
        a.BillingPostalCode = '6000';
        update a;
        Test.stopTest();
        Account accupdate = [Select Id, Pod__c ,BillingPostalCode FROM Account where id=: a.Id];
        System.assertEquals(accupdate.Pod__c, podT2.Pod__c);

        Account podAccount = new Account(FirstName = 'Test', Pod__c = exPod.Id, Status__c = 'Active', Last_Exit_Date__c = System.today(), LastName = 'Hello', Cultural_Needs__c = False, NDIS__c = '43215678', BillingPostalCode='6000', RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID, PlanManager__c = 'NDSP');
        insert podAccount;
        System.assertEquals(podAccount.Pod__c, exPod.Id);
    }

    @IsTest
    private static void test_updateAccount() {
        test_mockCallout();
        List<Account> accList = new List<Account>();
        Test.startTest();
        Account providerAccount = TestClassDataUtil.createProviderAccount(null, TEST_ABN_NUMBER);
        providerAccount.Business_Email__c = 'test@example.com';
        accList.add(providerAccount);
        System.debug('PROVIDER ACC : ' + providerAccount);
        System.debug('PROVIDER ACC NUMBER : ' + providerAccount.MPMAccountNumber__c);
        Account clientAccount = TestClassDataUtil.createClientAccount();
        
        System.debug('CLIENT ACC NUMBER : ' + clientAccount.MPMAccountNumber__c);
        clientAccount.NDIS__c = '431231230';
        accList.add(clientAccount);
        update accList;

        // Id userId = userinfo.getUserId();
        // EditFieldSettings__c obj = EditFieldSettings__c.getInstance(userId);
        // obj.IsMPMAccountNumberEditable__c = false;
        // upsert obj EditFieldSettings__c.Id;
        
        // clientAccount.MPMAccountNumber__c = '210101-12098';
        // update clientAccount;
        
        Test.stopTest();
    }
}