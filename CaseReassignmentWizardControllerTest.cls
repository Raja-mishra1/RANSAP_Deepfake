/*
* Name : CaseReassignmentWizardControllerTest
* Created by: Cloudwerx
* Description: Test Class for CaseReassignmentWizardController
* Created Date: 08/02/2021
*/

@IsTest
public class CaseReassignmentWizardControllerTest {
    @testSetup 
    static void setup(){
        
        Id clientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        
        Account clientAccount = new Account(FirstName = 'Bobby', LastName = 'Bobbo', NDIS__c = '431231232', PersonBirthdate = Date.today(), RecordTypeId = clientRecordTypeId );
        insert clientAccount;
        
        //Contact cont = TestClassDataUtil.createContact(clientAccount.Id); 
        Contact contact = TestClassDataUtil.createContact(TestClassDataUtil.createDefaultAccount().Id);
        
        Case c = new Case(Origin = 'Email',Subject = 'Test Case Subject', Description = 'Test case description',Status='New', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID, Client__c = clientAccount.Id);
        insert c;
        
        Case c1 = new Case(Origin = 'Email',Subject = 'Test Case Subject 1', Description = 'Test case description',Status='New', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID, Client__c = clientAccount.Id);
        insert c1;
        createGroup();
    }
    @future
    public static void createGroup(){
        Group grp = new Group(Name = 'test');
        insert grp;
    }
    @isTest 
    static void testMethodToCallLightningMethods(){
        Group g = [SELECT ID FROM Group WHERE Name = 'test'];
        
        List<Account> accountList = [SELECT Id from Account];
        List<Contact> contactList = [SELECT Id from Contact];
        
        List<Case> caseList = [SELECT Id, Re_Assignment_Notes__c, Client__r.PlanManager__c from Case];
        
        String[] accountStringArray = new String[]{String.valueOf(accountList[0].Id)};
        String[] contactStringArray = new String[]{String.valueOf(contactList[0].Id)};
        
        Test.StartTest();
        CaseReassignmentWizardController.fetchReassignmentMetadataRecords('MPM');
        CaseReassignmentWizardController.fetchReassignmentMetadataRecords('NDSP');
        CaseReassignmentWizardController.fetchReassignmentMetadataRecords(null);
        CaseReassignmentWizardController.getCase(caseList[0].Id);
        
        CaseReassignmentWizardController.fetchRecords('group','Case','Wel', 'MPM');
        CaseReassignmentWizardController.fetchRecords('group','Case','Com', 'NDSP');
        CaseReassignmentWizardController.fetchRecords('group','Case','Sol', null);
        CaseReassignmentWizardController.fetchRecords('user','',UserInfo.getFirstName(),'MPM');
        CaseReassignmentWizardController.fetchRecords('user','',UserInfo.getFirstName(),'NDSP');
        CaseReassignmentWizardController.fetchRecords('user','',UserInfo.getFirstName(),null);
        
        CaseReassignmentWizardController.getRelatedRecords(accountStringArray);
        CaseReassignmentWizardController.getRelatedRecords(contactStringArray);
        
        CaseReassignmentWizardController.retrieveCaseRecord(caseList[0].Id);
        caseList[0].PlanManager__c = 'MPM';
        update caseList[0];
        
        CaseReassignmentWizardController.retrieveCaseRecord(caseList[0].Id);
        caseList[1].Client__r.PlanManager__c = 'MPM';
        update caseList[1].Client__r;
        
        CaseReassignmentWizardController.retrieveCaseRecord(caseList[1].Id);
        
        caseList[0].Re_Assignment_Notes__c = 'Updated Value';
        CaseReassignmentWizardController.setCaseRecords(caseList);
                
        Test.stopTest();
     }

}