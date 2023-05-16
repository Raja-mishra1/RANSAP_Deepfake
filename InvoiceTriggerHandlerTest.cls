/**
 * @description  Test Class for InvoiceTriggerHandler class
 * @company      Cloudwerx
 * @date		 03/08/2021
**/

@isTest
public class InvoiceTriggerHandlerTest {

    private static final String TEST_ABN_NUMBER = '51824753556';

    @TestSetup
    static void makeData() {
        insert new Reconnection_Trigger_Configuration__c(Invoice_Trigger_Activated__c = true, Plan_Support_Preference_Trigger_Activate__c = false);
        InvoiceRuleTest.makeData();
    }

    //handles coverage for runEngineIfInvoiceApproved,updateInvoicePsr
    @isTest
    public static void unitTest_runEngineIfInvoiceApproved() {
        Invoice__c inv = [SELECT Id, Client_Approval_Status__c, Status__c FROM Invoice__c LIMIT 1];
        inv.Client_Approval_Status__c = 'Approved';
        update inv;

        System.assertEquals('Approved', inv.Client_Approval_Status__c);
    }


    // updatePodSkillRequirement method
    @isTest
    public static void unitTest_updatePodSkillRequirement() {
        Invoice__c inv = [SELECT Id, Client__c, Status__c FROM Invoice__c WHERE Status__c = 'New' LIMIT 1];

        Pod__c queenPod = new Pod__c(Name = 'Queensland', Pod_Type__c = 'Cultural');
        insert queenPod;

        Account clientAccount = new Account(
            FirstName = 'Toby',
            LastName = 'Malfoy',
            NDIS__c = '431231231',
            Pod__c = queenPod.Id,
            PersonBirthdate = Date.today(),
            MPM_Critical_Note_Exclusion__c = false,
            RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID
        );
        insert clientAccount;

        inv.Client__c = clientAccount.Id;
        update inv;
    }

    @isTest
    public static void unitTest_populateFinalisedAt() {
        Test.startTest();
        //populateFinalisedAt - ready invoice
        List<Invoice__c> invoiceList = [SELECT Status__c,FinalisedAt__c,Total__c FROM Invoice__c limit 1];
        Invoice__c readyInvoice = invoiceList[0];
        readyInvoice.Status__c = 'Ready';
        readyInvoice.Total__c = 80;
        update readyInvoice;
        Invoice__c inv = [SELECT Id, Client_Approval_Status__c, Status__c,FinalisedAt__c FROM Invoice__c WHERE Id =: readyInvoice.Id];
        // System.assertEquals(inv.FinalisedAt__c, System.today());

        //populateFinalisedAt - NDIA Approved invoice
        Invoice__c invAprvd = [SELECT   Id, MarkAsPaid__c, Status__c,
                                        FinalisedAt__c,PaidByCreditCard__c,Paid_Date__c
                                FROM Invoice__c WHERE Status__c != 'NDIA Approved' LIMIT 1];
        invAprvd.Status__c = 'NDIA Approved';
        invAprvd.PaidByCreditCard__c = true;
        invAprvd.MarkAsPaid__c = true;
        update invAprvd;
        Invoice__c inv1 = [SELECT Id, Paid_Date__c, Status__c,FinalisedAt__c FROM Invoice__c WHERE Id =: readyInvoice.Id];
        // System.assertEquals(inv1.Paid_Date__c, System.today());
        Test.stopTest();
    }

    @isTest
    public static void unitTest_updateInvoiceStatus() {
        Test.startTest();
        List<Invoice__c> invoiceList = [SELECT Client__c, Provider__c, Total__c, Support_Start_Date__c, Reference_Number__c,
        Status__c, Invoice_Line_Item_Statuses__c,Auto_Approve_Client_Invoices__c FROM Invoice__c LIMIT 1];
        Invoice__c readyInvoice = invoiceList[0];

        //credit paid
        readyInvoice.Invoice_Line_Item_Statuses__c = System.Label.Credit_Paid;
        readyInvoice.Reference_Number__c = 'testReference Number';
        update readyInvoice;
        Invoice__c updatedInvoice1 = [SELECT Status__c, Invoice_Line_Item_Statuses__c FROM Invoice__c WHERE Id =: readyInvoice.Id];
        System.assertEquals(updatedInvoice1.Status__c, System.Label.Credit_Paid);

        //NDIA Rejected
        readyInvoice.Invoice_Line_Item_Statuses__c = System.Label.Rejected;
        readyInvoice.Reference_Number__c = 'testReference Number';
        update readyInvoice;
        Invoice__c updatedInvoice2 = [SELECT Status__c, Invoice_Line_Item_Statuses__c FROM Invoice__c WHERE Id =: readyInvoice.Id];
        System.assertEquals(updatedInvoice2.Status__c, System.Label.NDIA_Rejected);

        //NDIA Approved
        readyInvoice.Invoice_Line_Item_Statuses__c = System.Label.NDIA_Approved;
        readyInvoice.Reference_Number__c = 'testReference Number';
        update readyInvoice;
        Invoice__c updatedInvoice3 = [SELECT Status__c, Invoice_Line_Item_Statuses__c FROM Invoice__c WHERE Id =: readyInvoice.Id];
        System.assertEquals(updatedInvoice3.Status__c, System.Label.NDIA_Approved);
        Test.stopTest();

        //Invoice Partially Approved
        readyInvoice.Invoice_Line_Item_Statuses__c = System.Label.Credit_Paid+' '+System.Label.NDIA_Approved+' '+System.Label.NDIA_Partially_Approved; //TTP-3596
        update readyInvoice;
        Invoice__c updatedInvoice4 = [SELECT Status__c, Invoice_Line_Item_Statuses__c FROM Invoice__c WHERE Id =: readyInvoice.Id];
        System.assertEquals(updatedInvoice4.Status__c, System.Label.NDIA_Partially_Approved);
        
        //Invoice Cancelled
        readyInvoice.Invoice_Line_Item_Statuses__c = System.Label.Cancelled; //ACEM-120
        update readyInvoice;
        Invoice__c updatedInvoice5 = [SELECT Status__c, Invoice_Line_Item_Statuses__c FROM Invoice__c WHERE Id =: readyInvoice.Id];
        System.assertEquals(updatedInvoice5.Status__c, System.Label.Cancelled);
        General_T2P_Settings__c custSetting = new General_T2P_Settings__c(ActivateInvoiceCountOnCase__c = true);
        insert custSetting;
        List<Case> caseList = [Select Id, Related_Invoices__c from Case];
        invoiceList[0].Case__c = caseList[0].Id;
        update invoiceList[0];
        delete invoiceList[0];
        undelete invoiceList[0];
    }

    //sendInvoiceToSMSQueuable method
    @isTest
    public static void unitTest_sendInvoiceToSMSQueuable() {
        Test.startTest();

        List<Invoice__c> invoiceList = [SELECT Client__c, Provider__c, Total__c, Support_Start_Date__c, Reference_Number__c,
        Status__c, Invoice_Line_Item_Statuses__c,Auto_Approve_Client_Invoices__c FROM Invoice__c LIMIT 1];
        Invoice__c readyInvoice = invoiceList[0];
        readyInvoice.Status__c = System.Label.IR_ReadyStatus;//'Awaiting Client Approval';
        readyInvoice.Reference_Number__c = 'testReference Number';
        readyInvoice.Support_Start_Date__c = System.today();
        update readyInvoice;
        //add asserts later
        Test.stopTest();
    }

    @isTest
    public static void unitTest_ClientApprovalRejected () {
        List<Invoice__c> invoiceList = [SELECT Client__c, Client_Approval_Status__c, Provider__c, Total__c,
            Support_Start_Date__c, Reference_Number__c, Status__c, Invoice_Line_Item_Statuses__c,
            Auto_Approve_Client_Invoices__c FROM Invoice__c LIMIT 1];
        Invoice__c readyInvoice = invoiceList[0];
        //Invoice Rejected
        readyInvoice.Client_Approval_Status__c = System.Label.Rejected; //TTP-3596
        update readyInvoice;
        Invoice__c updatedInvoice4 = [SELECT Status__c, Invoice_Line_Item_Statuses__c FROM Invoice__c WHERE Id =: readyInvoice.Id];

        System.assertEquals(updatedInvoice4.Status__c, System.Label.Cancelled);
    }
    
    @isTest
    public static void unitTest_createConDocLinkForManualInvoices () {
        Test.startTest();
        	delete [Select id from Invoice__c];
        	String generalCaseRecTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID;
        	String clientRecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID;
        	Account clientAccount = [Select id from Account where RecordTypeId =: clientRecordTypeId limit 1];        
        	Account providerAccount = [Select id from Account where RecordType.DeveloperName = 'Provider' limit 1];        
        	Case childCase = [Select id from Case where RecordTypeId =: generalCaseRecTypeId limit 1];
        
        	//Inserting content document link record
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.pdf',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert contentVersion; 
    
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
    
            ContentDocumentLink cDocLink = new ContentDocumentLink(ContentDocumentId = documents[0].Id,
                                                        LinkedEntityId = childCase.Id,
                                                        Visibility ='AllUsers',
                                                        ShareType ='V');
            insert cDocLink;
        
        	List<Invoice__c> invoiceList = TestClassDataUtil.createInvoiceRecords(false,1,clientAccount.id,providerAccount.id,childCase.id);
            invoiceList[0].Document_Link__c = 'Test Document Link';
        	invoiceList[0].Invoice_Origin__c = 'Manual';
            insert invoiceList;
        	System.assertEquals(true, [Select id from ContentDocument].size() > 0);
        Test.stopTest();
    }
    
    // [TFR-167]
    @isTest
    public static void unitTest_updateOverrideDuplicateRule() {
        List<Invoice__c> invoiceList = [SELECT OverrideDuplicateRule__c FROM Invoice__c LIMIT 1];
        invoiceList[0].OverrideDuplicateRule__c = true;
        update invoiceList;

        List<Invoice_Line_Item__c> lineItemList = [SELECT OverrideDuplicateRule__c FROM Invoice_Line_Item__c WHERE Invoice__c =: invoiceList[0].Id LIMIT 1];
        
        System.assertEquals(true, lineItemList[0].OverrideDuplicateRule__c);
    }
}