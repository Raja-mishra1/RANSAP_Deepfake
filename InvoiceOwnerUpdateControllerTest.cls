/* @description  Test Class for InvoiceOwnerUpdateController 
 * @author       Sonali Bhat
 * @company      CloudWerx
**/
@isTest
public class InvoiceOwnerUpdateControllerTest {
    @TestSetup
    static void makeData() {
        /*CREATE CLIENT ACCOUNT*/
        Account clientAccount = TestClassDataUtil.createClientAccount();
        List<Invoice__c> invoiceList = 
            TestClassDataUtil.createInvoiceRecords(
                true, 1, clientAccount.id, null, null);
    }

    @isTest
    public static void unitTest_redirectToAura() {
        List<Invoice__c> invoiceList = [SELECT Id, OwnerId FROM Invoice__c LIMIT 2];
        ApexPages.StandardSetController inv = new ApexPages.StandardSetController(invoiceList);
        InvoiceOwnerUpdateController obj = new InvoiceOwnerUpdateController(inv);
        obj.redirectToAura();
    }
}