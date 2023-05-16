/**
 * @description         Test class for PodAssignmentController
 * @company             Cloudwerx
 * @date                05/06/2020
**/

@IsTest
public class PodAssignmentControllerTest {

    @testSetup static void setup() {

        List <RecordType> accountListRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Client'];     
        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        for (Integer i=0;i<2;i++) {
            testAccts.add(new Account(FirstName = 'TestAcct'+i, LastName = 'LastName', Status__c = 'Active', BillingPostalCode = '2004', PlanManager__c = 'NDSP',
                                 RecordTypeId = accountListRecordType[0].Id, NDIS__c = '43234567'+i));
        }
        insert testAccts;      
        
        Pod__c pod = new Pod__c(Name = 'Test Pod', Pod_Type__c = 'Regional',PlanManager__c = 'NDSP');
        insert pod;

        Pod__c exPod = new Pod__c(Name = 'Exception', Pod_Type__c = 'Regional', PlanManager__c = 'NDSP');
        insert exPod;

        Pod_Territory__c podT = new Pod_Territory__c(Pod__c = pod.Id, StartingPostCode__c = 2000, EndingPostCode__c = 2005);
        insert podT;
        
    }
    
    @isTest 
    static void testMethodToCallLightningMethods() {
        Test.StartTest();
        Pod__c pod = [SELECT Id FROM Pod__c WHERE Name = 'Test Pod'];
        List <Pod_Territory__c> listPodTerritory = [SELECT Id FROM Pod_Territory__c WHERE Pod__c =: pod.Id];
        PodAssignmentController.retrievePodRecord(pod.Id);  
        PodAssignmentController.retriveRecordCountInformation(pod.Id);   
        PodAssignmentController.executeBatch(pod.Id);
        PodAssignmentController.getBatchResults(pod.Id);
        PodAssignmentController.updatePodRecord(pod);
        Test.stopTest();
        
    }

    @isTest 
    static void testMethodToUpdateExceptionClients() {
        Test.StartTest();
        Pod__c pod = [SELECT Id FROM Pod__c WHERE Name = 'Exception'];
        PodAssignmentController.retrievePodRecord(pod.Id);  
        PodAssignmentController.retriveRecordCountInformation(pod.Id);   
        PodAssignmentController.executeBatch(pod.Id);
        PodAssignmentController.getBatchResults(pod.Id);
        PodAssignmentController.updatePodRecord(pod);
        Test.stopTest();
    }

}