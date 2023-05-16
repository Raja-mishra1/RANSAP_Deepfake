@isTest
public class ClientExitWizardControllerTest {
	
    public static Id getId() {
    	Account a = new Account();
        a.Name = 'Test Account';
        a.NDIS__c = '435678465';
        insert a;
        return a.Id;
    }
    
    @istest
    static void testretrieveClientExitWizardCustomMetadata() {  
        test.startTest();
        ClientExitWizardController.retrieveClientExitWizardCustomMetadata();
        test.stopTest();
    }
    
    @istest
    public static void testToFecthAccountRecords() {
        Id accountId = ClientExitWizardControllerTest.getId();
        test.startTest();
        ClientExitWizardController.fetchAccountdata(accountId);
        test.stopTest();
    }
    
    @istest
    public static void testretrieveSARecord() {
        Id accountId = ClientExitWizardControllerTest.getId();
        test.startTest();
        ClientExitWizardController.retrieveSARecord(accountId);
        
        Service_Agreement__c SA =new Service_Agreement__c();
        SA.Name = 'Test SA';
        SA.Status__c ='Current';
        SA.Commencement_Date__c = System.Today();
        SA.Activated_Date__c = System.Today();
        
        insert SA;
       
        ClientExitWizardController.retrieveSARecord(accountId);
        ClientExitWizardController.retrieveServiceAgreement(accountId);
       
        test.stopTest();
        
    }
    
    @istest
    public static void testcreateServiceAgreementRecord() {
        Service_Agreement__c SA =new Service_Agreement__c();
        SA.Name = 'Test SA';
        SA.Status__c ='Current';
        SA.Commencement_Date__c = System.Today();
        SA.Activated_Date__c = System.Today();
        
       	test.startTest();
        ClientExitWizardController.createServiceAgreementRecord(SA);
        test.stopTest();
    }
     
    @istest
    static void testgetFieldsPicklistMethod() {  
        String str = '{"Account":["Attempted_Exit_Type__c"]}';
        test.startTest();
        ClientExitWizardController.getFieldsPicklistValuesMap(str);
        test.stopTest();
    }
    
    @istest
    public static void saveClientRecord() {
        Account a = new Account();
        a.Name = 'Test Account';
        a.NDIS__c = '435678465';
        
        test.startTest();
        ClientExitWizardController.saveClientRecord(a);
        test.stopTest();
    }
    
    @istest
    public static void testCustomSettings() {
       	MPM_URLs__c m = new MPM_URLs__c();
        m.MPM_Client_URL__c = 'test.com';
        insert m;
        
        test.startTest();
        ClientExitWizardController.retrieveClientExitWizardCustomSettings();
        test.stopTest();
    }
    
   	@istest
    public static void testUploadFiles() {  
        Account a = new Account();
        a.Name = 'Test Account';
        a.NDIS__c = '435678465';
        insert a;
        
        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Version
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        System.assertEquals(cvList.size(), 1);
        test.startTest();
        ClientExitWizardController.updateSAFiles(cvList[0].ContentDocumentId,'Family Jon Service Agreement',a.Id);
        test.stopTest();
    } 
    
    @istest
    public static void testupdateServiceAgreementDocument() { 
    	Id accountId = ClientExitWizardControllerTest.getId();
        Service_Agreement__c SA =new Service_Agreement__c();
        SA.Name = 'Test SA';
        SA.Status__c ='Current';
        SA.Commencement_Date__c = System.Today();
        SA.Activated_Date__c = System.Today();
        insert SA;
        test.startTest();
        ClientExitWizardController.updateServiceAgreementDocument(accountId,SA.Id,'Service Agreement');
        test.stopTest();
        
    }
    
    @istest
    public static void testretriveCaseRecord() { 

        Id clientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        
        Account clientAccount = new Account(FirstName = 'Bobby', LastName = 'Bobbo', NDIS__c = '431231232',PlanManager__c = 'MPM', PersonBirthdate = Date.today(), RecordTypeId = clientRecordTypeId );
        insert clientAccount;
        
        Case c = new Case(Origin = 'Email',Subject = 'Test Case Subject',PlanManager__c = 'MPM', Description = 'Test case description', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID, Client__c = clientAccount.Id);
        insert c;
        
        Case c1 = new Case(Origin = 'Email',Subject = 'Test Case Subject 1',PlanManager__c = 'MPM', Description = 'Test case description', RecordTypeId = RecordTypeUtil.COMPLAINT_L2_CASE_RECORD_TYPE_ID, Client__c = clientAccount.Id);
        insert c1;

        Case c2 = new Case(Origin = 'Email',Subject = 'Test Case Subject 1',PlanManager__c = 'MPM', Description = 'Test case description', RecordTypeId = RecordTypeUtil.COMPLAINT_L3_CASE_RECORD_TYPE_ID, Client__c = clientAccount.Id);
        insert c2;

        Case c3 = new Case(Origin = 'Email',Subject = 'Test Case Subject 1',PlanManager__c = 'MPM', Description = 'Test case description', RecordTypeId = RecordTypeUtil.REPORTABLE_INCIDENT_RECORD_TYPE_ID, Client__c = clientAccount.Id);
        insert c3;
        
        Group grp = new Group(Name = 'test');
        insert grp;
        test.startTest();
        ClientExitWizardController.retrieveCaseDetails(clientAccount.id);
        test.stopTest();
    }
    
    @istest
    public static void testretrievePrimaryontact() { 
       	My_Plan_Manager_Contact_Settings__c mpm = new My_Plan_Manager_Contact_Settings__c();
        mpm.My_Plan_Manager_Label__c = 'My Plan Manager';
        mpm.Business_Email__c = 'test@test.com';
        mpm.Counter__c = 1;
        mpm.Maximum_Allowed_Contacts__c = 2;
        insert mpm;
      
        Reconnection_Trigger_Configuration__c recon = new Reconnection_Trigger_Configuration__c();
        recon.ContactTriggerActivated__c = True;
        insert recon;
    
        Contact c = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',PlanManager__c = 'MPM',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com');
        insert c;
        Id accountId = ClientExitWizardControllerTest.getId();
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = accountId;
        acr.Primary_Contact__c = true;
        acr.IsActive = true;
        acr.Relationship__c = 'Brother';
        acr.ContactId = c.id;
        insert acr;
        test.startTest();
        ClientExitWizardController.retrieveContact(accountId);
        test.stopTest();
        
    }
    
    @istest
    public static void testSendEmail() { 
        Id accountId = ClientExitWizardControllerTest.getId();
        Contact c = new Contact();
       	c.LastName = 'Test Contact';
        c.Email = 'test@gmail.com';
        c.PlanManager__c = 'MPM';
        insert c;
        test.startTest();
        ClientExitWizardController.sendEmailToClients(accountId,'test@gmail.com',c.Id,'Deceased Client Exit');
        test.stopTest();
        
    }
    
    @istest
    public static void testUpdateClientCommunicationFacility() { 
        Id accountId = ClientExitWizardControllerTest.getId();
        List<String> cList = new List<String>();
        AccountContactRelation acr = new AccountContactRelation();
        Contact c = new Contact();
       	c.LastName = 'Test Contact';
        c.Email = 'test@gmail.com';
        c.PlanManager__c = 'MPM';
        insert c;
        cList.add(c.Id);
        String myJSON = JSON.serialize(cList);

        acr.AccountId = accountId;
        acr.Primary_Contact__c = true;
        acr.IsActive = true;
        acr.Relationship__c = 'Brother';
        acr.ContactId = c.id;
        insert acr;
        test.startTest();
        ClientExitWizardController.updateClientCommunicationFacility(myJSON,accountId);
        test.stopTest();
        
    }
    
    @istest
    static void testSendEmailforComplaintsQueue() {  
        Account a = new Account();
        a.Name = 'Test Account';
        a.NDIS__c = '435678465';
        
        insert a;
        
        Id generalRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaints Level 2').getRecordTypeId();
        Case caseObj1 = new Case (Subject = 'Test  From TestClass',PlanManager__c = 'MPM', Origin = 'Email',OwnerId = UserInfo.getUserId(),RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID, Type ='Claims Processing' ,AccountId =a.Id ,Sub_Type__c = 'Invoice Over $20,000', PodSkillRequirement__c ='Queensland');
        insert caseObj1;
        
        
        test.startTest();
        ClientExitWizardController.sendEmailforComplaintsQueue(a);
        test.stopTest();
    }

    @istest
    static void testhandleInvoiceAndLineItemCreation() {
        test.startTest();
            // insert My Plan Manager Provider Account  
            Account a = new Account();
            a.Name = 'My Plan Manager';
            a.NDIS__c = '435678465';
            a.RecordTypeId = RecordTypeUtil.PROVIDER_ACCOUNT_RECORD_TYPE_ID;
            insert a;
            // insert Client
            Account acc = TestClassDataUtil.createClientAccount();
            acc.PlanManager__c = 'MPM';
            update acc;
            // insert Plan
            Plan__c plan = TestClassDataUtil.createPlan(acc.Id);
            String clientCreatedDate = String.valueOf(date.today());

            // Scenario 1: exit today
            DateTime exitDateToday = System.now(); 
    
            ClientExitWizardController.handleInvoiceAndLineItemCreation(acc.Id, exitDateToday, clientCreatedDate);
            List<Invoice__c> invoiceList1 = [SELECT Id FROM Invoice__c WHERE Client__c =: acc.Id AND FeeType__c =: InvoiceRuleConstant.INVOICE_FEETYPE_MONTHLY];
            System.assertEquals(1,invoiceList1.size());
            delete invoiceList1;

            // Scenario 2: exit in future
            DateTime exitDateFuture = System.now().addMonths(3); 
            ClientExitWizardController.handleInvoiceAndLineItemCreation(acc.Id, exitDateFuture, clientCreatedDate);
            List<Invoice__c> invoiceList2 = [SELECT Id FROM Invoice__c WHERE Client__c =: acc.Id AND FeeType__c =: InvoiceRuleConstant.INVOICE_FEETYPE_MONTHLY];
            System.assertEquals(2,invoiceList2.size());

            // Scenario 3: No Plan found
            delete plan;
            delete invoiceList2;
            ClientExitWizardController.handleInvoiceAndLineItemCreation(acc.Id, exitDateFuture, clientCreatedDate);
            List<Invoice__c> invoiceList3 = [SELECT Id FROM Invoice__c WHERE Client__c =: acc.Id AND FeeType__c =: InvoiceRuleConstant.INVOICE_FEETYPE_MONTHLY];
            System.assertEquals(2,invoiceList3.size());

        test.stopTest();
    }
}