/**
 * @description     Test class for handler
 * @company         Cloudwerx
 * @date            28/05/2020
**/
@IsTest
private class AutoCreateExpiredCaseBatchClassTest   {
    @testSetup static void setup() {
        RecordType caseRecordType = [SELECT Id FROM RecordType WHERE sObjectType ='Case'][0];
        insert new Reconnect_Auto_Case_Create_Settings__c(Case_Record_Type_Id__c = caseRecordType.Id, 
               Description__c = 'This case has been automatically created because a new plan needs to be reconnected for \''+'Client__c.Name'+'\'',
               Owner_Id__c = UserInfo.getUserId(),  Relationship_QLD_Queue__c = UserInfo.getUserId(), Priority__c ='Medium', Status__c= 'New', Subject__c= 'Test Subject', Type__c = 'Client Setup/Admin', Sub_Type__c = 'Client Reconnection');

        List <RecordType> accountListRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Client'];     
        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        for (Integer i=0;i<2;i++) {
            testAccts.add(new Account(FirstName = 'TestAcct'+i, LastName = 'LastName', Status__c = 'Active',
                                 RecordTypeId = accountListRecordType[0].Id, NDIS__c = '43334234' + i));
        }
        insert testAccts;      
        
        Plan__c testPlan = new Plan__c(Name = 'TestPlan1', PlanManager__c = 'MPM', Client_Name__c = testAccts[0].Id, Plan_Start_Date__c = System.today().addDays(-10),
                                                Plan_End_Date__c = System.today().addDays(-2));
        insert testPlan;
    }
    
    @isTest 
    static void testMethodInsert() {
        Test.StartTest();
        AutoCreateExpiredCaseBatchClass sh1 = new AutoCreateExpiredCaseBatchClass();
        String sch = '0 0 23 * * ?'; 
        System.schedule('AutoCreateExpiredCaseBatchClass', sch, sh1); 
        Test.stopTest();
    }
}