/**
 * @description  Test Class for OwnerUpdateComponentController 
 * @author       Sonali Bhat
 * @company      CloudWerx
**/
@isTest
public class OwnerUpdateComponentControllerTest {
    @testSetup
    static void setup() {
        
        Id clientRecordTypeId = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        
        // Create Client Account
        Account clientAccount = new Account(
            FirstName = 'Bobby', LastName = 'Bobbo', NDIS__c = '431231232', 
            PersonBirthdate = Date.today(), RecordTypeId = clientRecordTypeId,
            PlanManager__c = 'MPM');
        insert clientAccount;

        Account clientAcc = [SELECT Id, 
                                        PlanManager__c 
                                FROM Account 
                                WHERE FirstName =: clientAccount.FirstName];

        // insert invoice
        List<Invoice__c> invList = 
            TestClassDataUtil.createInvoiceRecords(false, 1, clientAcc.Id, null, null);
            invList[0].PlanManager__c = 'MPM';
            insert invList;

        createGroup();

    }

    @future
    public static void createGroup() {
        Group grp = new Group(Name = 'MPM');
        insert grp;
    }

    @isTest 
    static void unitTest_retrieveSObjectRecords() {
        List<Invoice__c> invList = [SELECT Id, PlanManager__c FROM Invoice__c];
        Group g = [SELECT Id FROM Group WHERE Name = 'MPM'];
        Test.StartTest();
        OwnerUpdateComponentController.retrieveSObjectRecords(invList, 'Client__c', 'Invoice__c');
        invList[0].PlanManager__c ='';
        update invList;
        OwnerUpdateComponentController.retrieveSObjectRecords(invList, 'Client__c', 'Invoice__c');
        List<OwnerUpdateComponentCtrlHelper.RecordsData> recordData = 
            OwnerUpdateComponentController.fetchRecords('group','Invoice__c', 'MPM', 'MPM');
            OwnerUpdateComponentController.fetchRecords('user','',UserInfo.getFirstName(),'MPM');
            OwnerUpdateComponentController.fetchRecords('group','Invoice__c','NDSP','NDSP');
            OwnerUpdateComponentController.updateOwner(invList);
        Test.stopTest();
    }
}