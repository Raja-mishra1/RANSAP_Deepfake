/**
 * @description     [ACEM-10][ACEM-11] Test class for Queuable Class Invoked via Invoice trigger to send   email Notification To Provider on Invoice
 * @company         Cloudwerx
 * @date            05/09/2022
 * @testClass       InvoiceCancelNotificationQueuableTest
 **/
@isTest
public class InvoiceCancelNotificationQueuableTest {
  @TestSetup
  static void makeData() {
    /*CREATE MASTER CASE*/
    Id caseOwnerId = UserInfo.getUserId();
    Case masterCase = TestClassDataUtil.createCase(caseOwnerId);

    /*CREATE CASE GENERAL RECORD TYPE - ASSOCIATE TO MASTER CASE VIA PARENTID*/
    Case childCase = TestClassDataUtil.createChildCase(true, caseOwnerId, masterCase.Id);

    /*CREATE CLIENT ACCOUNT*/
    Account clientAccount = TestClassDataUtil.createClientAccount();

    /*CREATE PROVIDER ACCOUNT*/
    Account providerAccount = TestClassDataUtil.createProviderAccount(false, null, '51824753556');
    providerAccount.PreferredPaymentMethod__c = 'BPAY';
    providerAccount.BillerCode__c = '12345';
    providerAccount.ReferenceNumberBPAY__c = '1234';
    insert providerAccount;

    /*CREATE CONTACT*/
    List<Contact> contactList = TestClassDataUtil.createContactRecords(3, false, TestClassDataUtil.createDefaultAccount().Id);
    for (integer i = 0; i < contactList.size(); i++) {
      contactList[i].MobilePhone = '042345678' + i;
    }
    insert contactList; // insert contacts

    /*CREATE ACCOUNT CONTACT RELATION*/
    //pick this
    
    List<AccountContactRelation> accConRelList = new List<AccountContactRelation>();
    accConRelList.add(
      TestClassDataUtil.createAccountContactRelationRecords(false, providerAccount.Id, contactList[0].Id)
    );
    accConRelList.add(
      TestClassDataUtil.createAccountContactRelationRecords(false, clientAccount.Id, contactList[1].Id)
    );
    accConRelList.add(
      TestClassDataUtil.createAccountContactRelationRecords(false, clientAccount.Id, contactList[2].Id)
    );

    insert accConRelList;

    List<Invoice__c> invoiceList = TestClassDataUtil.createInvoiceRecords(
      false,
      10,
      clientAccount.id,
      providerAccount.Id,
      childCase.id
    );
    integer count = 0;
    for (Invoice__c inv : invoiceList) {
      inv.Support_Start_Date__c = System.today();
      inv.Reference_Number__c = 'testReference';
      inv.Client_Approval_Status__c = '';
      inv.Sypht_File_Id__c = '';
      inv.Status__c = 'New';
    }
    insert invoiceList; // insert invoices

    insert new Reconnection_Trigger_Configuration__c(Invoice_Trigger_Activated__c = true);
  }

  @isTest
  public static void unitTest_rejectionNotificationSuccess() {
    List<Invoice__c> invoiceList = new List<Invoice__c>();
    Test.startTest();
    for (Invoice__c inv : [
      SELECT
        Id,
        Name,
        Case__r.SuppliedEmail,
        Case__r.OwnerId,
        Client__c,
        Client__r.Name,
        Client__r.PersonContactId,
        ClientNameFormula__c,
        Provider__c,
        Provider_Name__c,
        Reference_Number__c
      FROM Invoice__c
      LIMIT 10
    ]) {
      inv.Client_Approval_Status__c = 'Rejected';
      invoiceList.add(inv);
    }
    update invoiceList;

    Test.stopTest();
    List<Task> taskList = [SELECT Id FROM Task];
    System.debug('taskList=>' + taskList.size());
    System.assertEquals(40, taskList.size());
  }

  /* This method covers the part where there is no contact on Provider or Client */
  @isTest
  public static void unitTest_rejectionNotificationNoEmail() {
    List<Invoice__c> invoiceList = new List<Invoice__c>();
    Test.startTest();
    List<AccountContactRelation> accConRelList = new List<AccountContactRelation>();
    for (AccountContactRelation acrRec : [SELECT Id,Primary_Contact__c FROM AccountContactRelation]) {
      acrRec.Primary_Contact__c = false;
      accConRelList.add(acrRec);
    }
    update accConRelList;

    for (Invoice__c inv : [
      SELECT
        Id,
        Name,
        Case__r.SuppliedEmail,
        Case__r.OwnerId,
        Client__c,
        Client__r.Name,
        Client__r.PersonContactId,
        ClientNameFormula__c,
        Provider__c,
        Provider_Name__c,
        Reference_Number__c
      FROM Invoice__c
      LIMIT 10
    ]) {
      inv.Client_Approval_Status__c = 'Rejected';
      invoiceList.add(inv);
    }
    update invoiceList; // The trigger will submit the queuable job
    Test.stopTest();
    List<Task> taskList = [SELECT Id FROM Task];
    System.assertEquals(0,Limits.getEmailInvocations());
    System.assertEquals(40, taskList.size());
  }
}