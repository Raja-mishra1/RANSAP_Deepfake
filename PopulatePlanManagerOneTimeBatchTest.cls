@IsTest
private class PopulatePlanManagerOneTimeBatchTest {
    @TestSetup
    static void setup(){
        Account clientAccount = new Account(
            FirstName = 'Bobby', 
            LastName = 'Bobbo', 
            NDIS__c = '431231232', 
            PersonBirthdate = Date.today(), 
            MPM_Critical_Note_Exclusion__c = false,
            RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID
        );
        insert clientAccount;
    } 
    @IsTest
    static void testBatch() {
        Test.startTest();
        List<String> objects = new List<String>{'Pod__c', 'Account'};
        Database.executeBatch(new PopulatePlanManagerOneTimeBatch(objects), 200); 
        Test.stopTest();
        Account acc = [SELECT Id, Name, PlanManager__c FROM Account WHERE NDIS__c = '431231232' LIMIT 1];
        System.assertEquals('MPM', acc.PlanManager__c, 'Plan Manager should be MPM');
        PopulatePlanManagerOneTimeBatch.SendEmailNotification('Account', new List<Id>{acc.Id});
    }
}