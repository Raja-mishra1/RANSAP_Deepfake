/**
 * @description     Test Class for ExportViewerController
 * @company         Cloudwerx
 * @date            18/02/2022
**/
@isTest
public class ExportViewerControllerTest {

    @testSetup 
    static void makeData() {
        Account clientAccount = TestClassDataUtil.createClientAccount(); // create client account
        Plan__c plan = TestClassDataUtil.createPlan(clientAccount.Id); // create plan 
        Account acc = TestClassDataUtil.createProviderAccount(true, null, '51824753556'); // create provider account
        List<Payment_Request__c> paymentReqtList = TestClassDataUtil.createPaymentRequest(false, 4, plan,acc.Id);
        paymentReqtList[0].Status__c = 'Failed';
        paymentReqtList[0].Provider__c = acc.Id;
        paymentReqtList[1].Status__c = 'Failed';
        paymentReqtList[1].Provider__c = acc.Id;
        paymentReqtList[2].Status__c = 'Pending';
        paymentReqtList[2].Provider__c = acc.Id;
        paymentReqtList[3].Status__c = 'NDIA Rejected';
        paymentReqtList[3].Provider__c = acc.Id;
        paymentReqtList[0].Service_Date_From__c = system.today();
        paymentReqtList[0].Service_Date_To__c = system.today();
        insert paymentReqtList;
    }
    
    @isTest
    private static void unitTest_fetchRecordsWithFilter() {
        test.startTest();
        String soqlFilter = 'Status__c = \'Pending\'';
        ExportViewerController.fetchRecords(
            'Payment_Request__c',
            'Status__c',
            '',
            '\'Failed\',\'NDIA Rejected\'',
            new List<String>{'Provider__r.Name'},
            soqlFilter,
            'Bobby',
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            '\'Failed\',\'NDIA Rejected\',\'Pending\'',
            '\'Invoice\',\'Invoice - Fee\'',
            'Name ASC');
        test.stopTest();
    }

    @isTest
    private static void unitTest_fetchRecordsWithPendingStatusFilter() {
        test.startTest();
        String soqlFilter = 'Status__c = \'Pending\'';
        ExportViewerController.fetchRecords(
            'Payment_Request__c',
            'Status__c',
            '',
            '\'Failed\',\'NDIA Rejected\'',
            new List<String>{'Provider__r.Name'},
            soqlFilter,
            'Bobby',
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            '\'Pending\'',
            '\'Invoice\',\'Invoice - Fee\'',
            'Name ASC');
        test.stopTest();
    }

    @isTest
    private static void unitTest_fetchRecordsWithoutFilter() {
        test.startTest();
        String soqlFilter = 'Status__c = \'Pending\'';
        ExportViewerController.fetchRecords(
            'Payment_Request__c',
            'Status__c',
            '',
            '\'Failed\',\'NDIA Rejected\'',
            new List<String>{'Provider__r.Name'},
            soqlFilter,
            'Bobby',
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            String.valueOf(system.today()),
            '',
            '\'Invoice\',\'Invoice - Fee\'',
            'Name ASC');
        test.stopTest();
    }
    
    @isTest
    private static void unitTest_ExportWithError() {
        test.startTest();
        Payment_Request__c prRecord = [SELECT Id FROM Payment_Request__c LIMIT 1];
        String exportJson = '{"paymentReqIds":["'+prRecord.Id+'"],"csvBlob":""}';
        String bulkPaymentReqId = ExportViewerController.createBulkPaymentRequest(exportJson);
        test.stopTest();
    }
    
    @isTest
    private static void unitTest_ExportWithSuccess() {
        test.startTest();
        Payment_Request__c prRecord = [SELECT Id FROM Payment_Request__c LIMIT 1];
        ExportViewerController.BulkPaymentWrapper wrap = new ExportViewerController.BulkPaymentWrapper();
        wrap.paymentReqIds = new List<String>{prRecord.Id};
        wrap.csvBlob = '"\"RegistrationNumber\",\"NDISNumber\"\n\"123456789\",\"438768678\""';
        String bulkPaymentReqId = ExportViewerController.createBulkPaymentRequest(JSON.serialize(wrap));
        test.stopTest();
    }
    
    @isTest
    private static void unitTest_NextString(){
        String nextString = ExportViewerController.getNextTwoDigitString('AZ');
        System.assertEquals('BA', nextString);
    }
}