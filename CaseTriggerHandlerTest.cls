@IsTest
private class CaseTriggerHandlerTest {


    @TestSetup
    static void createData() {
        Reconnection_Trigger_Configuration__c recon = new Reconnection_Trigger_Configuration__c();
        recon.Case_Trigger_Activated__c = true;
        insert recon;

        //create Accounts
        Account clientAccount1 = new Account(FirstName = 'Test', LastName = 'Doe', NDIS__c = '431231981', Status__c = 'Active',  RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID);
        insert clientAccount1;
        Account clientAccount2 = new Account(FirstName = 'Amitabh', LastName = 'Player', NDIS__c = '431231671', Status__c = 'Active',  RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID);
        insert clientAccount2;

        //TTP-164
        TestClassDataUtil.createClaimsAutomationSettings();
        //User testUser = TestClassDataUtil.createTestStandardUser();
        Case c1 = TestClassDataUtil.createCase(UserInfo.getUserId());
        //TTP-7 - Case without subject
        Case c2 = new Case(Origin='Email', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID);
        insert c2;
        Case c3 = new Case(Origin = 'Email',OwnerId=UserInfo.getUserId(), Subject = 'Claims Notification Case',Master_Case__c = c1.Id,
                            Document_Type__c = 'duplicate',Type = 'Claims Processing',Sub_Type__c = 'Duplicate Invoice',
                            Description = 'Test case description', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID);
        insert c3;
        Group TRICKY_ACCOUNTS_QUEUE = new Group(Name='Tricky Accounts');
    }

    @IsTest
    private static void testOCRClaimsQueue() {
        Contact contact = TestClassDataUtil.createContact(TestClassDataUtil.createDefaultAccount().Id);
        Account clientAccount = TestClassDataUtil.createClientAccount();

        AccountContactRelation accountContactRelation = new AccountContactRelation(AccountId = clientAccount.Id, ContactId = contact.Id, Relationship__c = 'Father');
        insert accountContactRelation;
        
        Test.startTest();

        Id generalRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId();
        Case c = new Case(SuppliedEmail = contact.Email, Subject = 'test', Origin = 'Email', Status = 'New', RecordTypeId = generalRecordTypeId);
        insert c;
        c.OwnerId = CaseTriggerHandler.ACCOUNTS_QUEUE.Id;
        update c;//either comment this or disable the flow
        Test.stopTest();
    }

    @IsTest
    private static void testOCRClaimsQueueWithFiles() {
        Contact contact = TestClassDataUtil.createContact(TestClassDataUtil.createDefaultAccount().Id);
        Account clientAccount = TestClassDataUtil.createClientAccount();

        AccountContactRelation accountContactRelation = new AccountContactRelation(AccountId = clientAccount.Id, ContactId = contact.Id, Relationship__c = 'Father');
        insert accountContactRelation;
        
        Test.startTest();

        Id generalRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId();
        Case c = new Case(SuppliedEmail = contact.Email, Subject = 'test', Origin = 'Email', Status = 'New', RecordTypeId = generalRecordTypeId);
        insert c;
        
        Case c2 = new Case(SuppliedEmail = contact.Email, Subject = 'test2', Origin = 'Phone', Client__c = clientAccount.Id,Status = 'New',PodSkillRequirement__c='', RecordTypeId = generalRecordTypeId,Type = 'Client Setup/Admin',Sub_Type__c = 'Client Reconnection');
        insert c2;
        
        c.OwnerId = CaseTriggerHandler.ACCOUNTS_QUEUE.Id;
        c.Master_Case__c = c2.Id;
        c.Type = 'Claims Processing';
        c.Sub_Type__c = 'OCR Claim';
        update c;//either comment this or disable the flow
        Test.stopTest();
    }
    
    @IsTest
    private static void testUdpatePodSkillRequirement() {
        Contact contact = TestClassDataUtil.createContact(TestClassDataUtil.createDefaultAccount().Id);
        Account clientAccount = TestClassDataUtil.createClientAccount();
        Pod__c podRecord = new Pod__c(Name='Test_Queensland', Pod_Skill_New__c='Queensland');
        insert podRecord;
        AccountContactRelation accountContactRelation = new AccountContactRelation(AccountId = clientAccount.Id, ContactId = contact.Id, Relationship__c = 'Father');
        insert accountContactRelation;
                
        Test.startTest();        
        clientAccount.Pod__c = podRecord.Id;
        update clientAccount;
        Id generalRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId();
        Case c1 = new Case(SuppliedEmail = contact.Email, Subject = 'test1', Origin = 'Email', Client__c = clientAccount.Id,Status = 'New',PodSkillRequirement__c='', RecordTypeId = generalRecordTypeId);
        Case c2 = new Case(SuppliedEmail = contact.Email, Subject = 'test2', Origin = 'Phone', Client__c = clientAccount.Id,Status = 'New',PodSkillRequirement__c='', RecordTypeId = generalRecordTypeId,Type = 'Client Setup/Admin',Sub_Type__c = 'Client Reconnection');
        insert c1;
        insert c2;
        c2.Status = 'Response Received';
        update c2;    
        Test.stopTest();
    }  
    
    // Sprint-7[BT-613] start
    @isTest
    private static void testCountOfCases() {
        test.startTest();
        Account clientAccount1 = new Account(FirstName = 'John', LastName = 'Parker', NDIS__c = '431231983', Status__c = 'Active',  RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID);
        insert clientAccount1;
        Account clientAccount2 = new Account(FirstName = 'joe', LastName = 'Don', NDIS__c = '431231678', Status__c = 'Active',  RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID);
        insert clientAccount2;
        Case caseObj = new Case(Origin = 'Email', Subject = 'Test Reconnection', Client__c = clientAccount1.Id, RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID, Status = 'New'); 
        insert caseObj;
        Account accountObj = [Select Id, Count_of_Open_Reconnection_Cases__c FROM Account WHERE FirstName = 'John'];
        System.assertEquals(1, accountObj.Count_of_Open_Reconnection_Cases__c);
        caseObj.Client__c = clientAccount2.Id;
        Update caseObj;
        Account accountObj1 = [Select Id, Count_of_Open_Reconnection_Cases__c FROM Account WHERE FirstName = 'joe'];
        Account account1 = [Select Id, Count_of_Open_Reconnection_Cases__c FROM Account WHERE FirstName = 'John'];
        System.assertEquals(0, account1.Count_of_Open_Reconnection_Cases__c);
        System.assertEquals(1, accountObj1.Count_of_Open_Reconnection_Cases__c);
        delete caseObj;
        test.stopTest();
    }
    // Sprint-7[BT-613] end

    /*
    @author     :   Prithviraj Deshmukh
    @company    :   Cloudwerx
    @ticket     :   [SFDC-980]
    @description:   Test Method to cover updatePSRRecord method.
    */
    @isTest
    private static void testUpdatePSRRecord() {
        test.startTest();

        Account clientAccount2 = [SELECT Id, Name FROM Account LIMIT 1];
        Case caseObj = new Case(Origin = 'Email', Subject = 'Test PSR Update', Client__c = clientAccount2.Id, 
                                RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID, Status = 'New', PodSkillRequirement__c ='Queensland',
                                OwnerId=CaseTriggerHandler.RELATIONSHIP_QUEUE.Id, Type = 'Client Setup/Admin', Sub_Type__c = 'Generate Budget Report'); 
        insert caseObj;

        /* SkillsBasedRouting.createPendingServiceRoutingWithoutUser(caseObj);
        PendingServiceRouting existingPSR = [SELECT Id,WorkItemId FROM PendingServiceRouting WHERE WorkItemId =:caseObj.Id];
        System.assertEquals(true, existingPSR!=null);
        
        String skillLevelBeforeUpdate = '';
        if (existingPSR!=null) {
            SkillRequirement skillRequirementRecord = [SELECT Id, RelatedRecordId, SkillLevel FROM SkillRequirement WHERE RelatedRecordId =: existingPSR.Id LIMIT 1];
            skillLevelBeforeUpdate = string.valueOf(skillRequiremen\tRecord.SkillLevel);
        }       */ 
        
        //update the subtype to one with different level
        caseObj.Sub_Type__c = 'NDIA Request';
        caseObj.OwnerId = CaseTriggerHandler.RELATIONSHIP_QUEUE.Id;
        update caseObj;

       /*  PendingServiceRouting newPSR = [SELECT Id,WorkItemId FROM PendingServiceRouting WHERE WorkItemId =:caseObj.Id];
        System.assertEquals(true, newPSR!=null);
        String skillLevelAfterUpdate = '';
        if (newPSR!=null) {
            SkillRequirement skillRequirementRecord = [SELECT Id, RelatedRecordId, SkillLevel FROM SkillRequirement WHERE RelatedRecordId =: newPSR.Id LIMIT 1];
            skillLevelAfterUpdate = string.valueOf(skillRequirementRecord.SkillLevel);
        }
        System.assertNotEquals(skillLevelBeforeUpdate, skillLevelAfterUpdate); */
        test.stopTest();
    }

    /**
    * @author: Yash Bhalerao
	* @company: Cloudwerx
    * @description : Test method to cover updateCDLForUpdatedCase method
    * @param   :   `` 
    * @return  :   ``
    * @ticket  :  [CS-104]
    **/
    @isTest
    public static void updateCDLForUpdatedCaseTest() {
        //User testUser = [SELECT Id FROM User LIMIT 1];
		Account clientAccount = TestClassDataUtil.createClientAccount();
        Account providerAccount = TestClassDataUtil.createProviderAccount(null);
        Account providerAccount1 = TestClassDataUtil.createProviderAccount(null);

        Set<Case> setOfClosedCases = new Set<Case>();
        Case cas = [SELECT Id,Subject,Description,OwnerId FROM Case LIMIT 1];
        cas.Client__c = clientAccount.Id;
        cas.Provider__c = providerAccount.Id;
        update cas;

        List<Case> list1 = new List<Case>();
        list1.add(cas);
        
        cas.Provider__c = providerAccount1.Id;
        update cas;
        
        List<Case> list2 = new List<Case>();
        list2.add(cas);
        
        ContentNote cn = new ContentNote();
        cn.Title = 'Test';
        insert cn;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cn.Id;
        cdl.LinkedEntityId = cas.Id;
        insert cdl;
        
        Test.startTest();
        CaseTriggerHandler.updateCDLForUpdatedCase(list1, list2); 
        cas.Status = 'Closed';
        update cas;
        setOfClosedCases.add(cas);
        CaseTriggerHandler.insertCDLForClosedCases(setOfClosedCases);
        Test.stopTest();
    }

    /**[SFDC-1004/1158] Sprint-13 - Insert Email Message with file without inserting file on Child Case */
    static testmethod void testmethodToInsertFile1(){
        Test.startTest();

        Case c1 = new Case(Origin = 'Email',Subject = 'Test OCR Claim Case Subject1', Description = 'Test case description', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID);
        insert c1;

        Case c2 = new Case(Origin = 'Email',Subject = 'Test OCR Claim Case Subject2', Original_Case__c = c1.Id, Description = 'Test case description', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID);
        insert c2;

        c1.Status = 'Closed';
        c1.Child_Case__c = c2.Id;
        update c1;

        EmailMessage emailMessage = new EmailMessage(); 
        emailMessage.status = '3'; 
        emailMessage.ParentId = c1.Id;
        emailMessage.fromName = 'Test Test';
        emailMessage.subject = 'This is the Subject!'; 
        emailMessage.htmlBody = '<html><body><b>Hello</b></body></html>';
        emailMessage.Incoming = true;

        String[] toIds = new String[]{ c1.Id };  
        emailMessage.toIds = toIds; 
        emailMessage.toAddress = 'anotherone@toexample.com'; 
        insert emailMessage; 

        ContentVersion content = new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId=emailMessage.id;
        contentlink.contentdocumentid=[SELECT Contentdocumentid FROM Contentversion WHERE id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        contentlink.Visibility = 'InternalUsers';
        
        insert contentlink;

        Test.stopTest();
        System.assertEquals(c1.Status, 'Closed');
        
    }

    /**[SFDC-1004/1158] Sprint-13  - Insert Email Message with file with inserting file on Child Case too*/
    static testmethod void testmethodToInsertFile2(){

        Case c1 = new Case(Origin = 'Email',Subject = 'Test OCR Claim Case Subject1', Description = 'Test case description', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID);
        insert c1;

        Case c2 = new Case(Origin = 'Email',Subject = 'Test OCR Claim Case Subject2', Original_Case__c = c1.Id, Description = 'Test case description', RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID);
        insert c2;
        c1.Status = 'Closed';
        c1.Child_Case__c = c2.Id;
        update c1;

        EmailMessage emailMessage = new EmailMessage(); 
        emailMessage.status = '3'; 
        emailMessage.ParentId = c1.Id;
        emailMessage.fromName = 'Test Test';
        emailMessage.subject = 'This is the Subject!'; 
        emailMessage.htmlBody = '<html><body><b>Hello</b></body></html>';
        emailMessage.Incoming = true;

        String[] toIds = new String[]{ c1.Id };  
        emailMessage.toIds = toIds; 
        emailMessage.toAddress = 'anotherone@toexample.com'; 
        insert emailMessage; 

        ContentVersion content1 = new ContentVersion(); 
        content1.Title='Header_Picture1'; 
        content1.PathOnClient='/' + content1.Title + '.jpg'; 
        Blob bodyBlob1=Blob.valueOf('Unit Test ContentVersion Body'); 
        content1.VersionData=bodyBlob1; 
        content1.origin = 'H';
        insert content1;

        ContentDocumentLink contentlink1 = new ContentDocumentLink();
        contentlink1.LinkedEntityId = c2.Id;
        contentlink1.contentdocumentid = [SELECT Contentdocumentid FROM Contentversion WHERE Id =: content1.id].contentdocumentid;
        contentlink1.ShareType = 'V';
        contentlink1.Visibility = 'InternalUsers';
        insert contentlink1;

        Test.startTest();

        ContentVersion content = new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;

        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=emailMessage.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        contentlink.Visibility = 'InternalUsers'; 
        insert contentlink;
        Test.stopTest();

        System.assertEquals(c1.Status, 'Closed');
    }
}