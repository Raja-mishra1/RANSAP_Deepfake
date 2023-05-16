/**
 * @description  [SFDC-1118] Test class for PlanExtensionCaseBatchClass.
 * @company      Cloudwerx
 * @date         04/05/2021
 * @testclass    NA
**/
@IsTest
private class PlanExtensionCaseBatchClassTest{
    @testSetup static void setup() {
        Account defaultAccount = TestClassDataUtil.createDefaultAccount();
        Account client = TestClassDataUtil.createClientAccount();
        List<Contact> primaryContact = TestClassDataUtil.createContactRecords(1 ,false, defaultAccount.Id);
        primaryContact[0].MobilePhone = '0423456789';
        primaryContact[0].PlanManager__c = 'MPM';   // [OPSNBOTS-271]
        Insert primaryContact;
        AccountContactRelation acr = TestClassDataUtil.createAccountContactRelation(client.Id, primaryContact[0].Id);
        
        List <Case_Batch_Configuration__mdt> listOfCaseConfigurations = [SELECT QualifiedApiName, MasterLabel, Case_Record_Type_Id__c, Owner_Id__c, Priority__c, Status__c, Subject__c, Description__c, Case_Origin__c, Type__c, Sub_Type__c
                                                                        FROM Case_Batch_Configuration__mdt WHERE Sub_Type__c = 'Client Plan Extension' ];
        
        List <RecordType> accountListRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Client'];     // Create common test accounts
        List<Account> testAccts = new List<Account>();
        
        for(Integer i=0;i<2;i++) {
            testAccts.add(new Account(FirstName = 'TestAcct'+i, LastName = 'LastName', Status__c = 'Active',NDIS__c = '43123121'+i,
                                 RecordTypeId = accountListRecordType[0].Id));
        }
        insert testAccts;      
        
        Plan__c testPlan = new Plan__c(Name = 'TestPlan1', PlanManager__c = 'MPM', Client_Name__c = testAccts[0].Id, Plan_Start_Date__c = System.today().addDays(-10),Actual_Plan_End_Date__c= System.today().addDays(-5),
                                                Plan_End_Date__c = System.today().addDays(-5));
        insert testPlan;     
    }
    
    @isTest 
    static void unitTest_PlanInsertion() {
        Plan__c testPlan = [SELECT Id,Actual_Plan_End_Date__c, Plan_End_Date__c FROM Plan__c LIMIT 1];
        Test.StartTest();
        testPlan.Plan_End_Date__c = testPlan.Actual_Plan_End_Date__c.addDays(75);
        update testPlan;
        PlanExtensionCaseBatchClass sh1 = new PlanExtensionCaseBatchClass();
        String sch = '0 0 23 * * ?'; 
        System.schedule('PlanExtensionCaseBatchClass', sch, sh1); 
        Test.stopTest();
    }
}