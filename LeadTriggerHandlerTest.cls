@IsTest
private class LeadTriggerHandlerTest {

    @TestSetup
    static void createData() {
        Reconnection_Trigger_Configuration__c recon = new Reconnection_Trigger_Configuration__c();
        recon.LeadTriggerActivated__c = true;
        recon.ContactTriggerActivated__c = true;
        insert recon;
        My_Plan_Manager_Contact_Settings__c mpm = new My_Plan_Manager_Contact_Settings__c();
        mpm.My_Plan_Manager_Label__c = 'My Plan Manager';
        mpm.Business_Email__c = 'test@test.com';
        mpm.Counter__c = 1;
        mpm.Maximum_Allowed_Contacts__c = 2;
        insert mpm;
    }

    @IsTest
    private static void testLeadContactCreation() {
        Lead lead = TestClassDataUtil.createLead();
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(lead.Id);
        leadConvert.setDoNotCreateOpportunity(true);
        leadConvert.setOwnerId(UserInfo.getUserId());
        LeadStatus convertStatus = [Select Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        leadConvert.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConvert);

        Contact createdContact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE IsPersonAccount = false];
        Account createdAccount = [SELECT Id, PersonBirthdate FROM Account where (not Account.Name Like 'My Plan Manager%')];

        System.assert(leadConvertResult.success);

        System.assertEquals(lead.Contact_First_Name__c, createdContact.FirstName);
        System.assertEquals(lead.Contact_Last_Name__c, createdContact.LastName);
        System.assertEquals(lead.Email, createdContact.Email);
        System.assertEquals(lead.Date_of_Birth__c, createdAccount.PersonBirthdate);
    }

    @IsTest
    private static void testLeadExistingContactLink() {
        Lead lead = TestClassDataUtil.createLead();
        Contact contact = new Contact(FirstName = lead.Contact_First_Name__c, LastName = lead.Contact_Last_Name__c, Email = lead.Email, MobilePhone = lead.Contact_Phone_Number__c = '0433333333', Phone = lead.Contact_Alternate_Phone_Number__c = '0299999999');
        insert contact;
        //Sprint-8[BT-689] Start -- removed Signed By
        Service_Agreement__c ser = new Service_Agreement__c(Lead__c = lead.Id ,Service_Agreement_Type__c = 'Email - Click to Accept', Name ='Test Service Agreement', Status__c ='Current', Commencement_Date__c = System.Today(), Activated_Date__c = System.Today());
        insert ser;
        //Sprint-8[BT-689] End 
        Guardianship_Document__c objGD = new Guardianship_Document__c(Name ='Test GD', Lead__c = lead.id, Status__c ='Current', Order_Date__c = System.Today(), Order_Reassessment_Date__c = System.Today(), Tribunal_Body__c = 'Guardianship of the Chief Executive');
        insert objGD;
        Consent_Document__c consentDocument = new Consent_Document__c (Lead__c = lead.Id);
        insert consentDocument; 
        Database.LeadConvert leadConvert = new Database.LeadConvert();
        leadConvert.setLeadId(lead.Id);
        leadConvert.setDoNotCreateOpportunity(true);
        leadConvert.setOwnerId(UserInfo.getUserId());
        LeadStatus convertStatus = [Select Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        leadConvert.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult leadConvertResult = Database.convertLead(leadConvert);

        Account createdAccount = [SELECT Id FROM Account where (not Account.Name Like 'My Plan Manager%')];
        AccountContactRelation createdAccountContactRelation = [SELECT Id, ContactId FROM AccountContactRelation WHERE AccountId = :createdAccount.Id];

        System.assert(leadConvertResult.success);
        System.assertEquals(contact.Id, createdAccountContactRelation.ContactId);
    }

    @isTest
    private static void testCalculateNumberOfLeads() {
        test.startTest();
        Account acc = new Account(Name = 'SonaliTest', Business_Email__c = 'businessemail@test.com', RecordTypeId = RecordTypeUtil.PROVIDER_ACCOUNT_RECORD_TYPE_ID, Number_of_Leads__c = 0, Status__c = 'Active');
        insert acc;
        Account acc1 = new Account(Name = 'SonaliTest1', Business_Email__c = 'sonaliemail@test.com', RecordTypeId = RecordTypeUtil.PROVIDER_ACCOUNT_RECORD_TYPE_ID, Number_of_Leads__c = 0, Status__c = 'Active');
        insert acc1;
        Lead lead = new Lead(LeadSource = 'Family', FirstName = 'Tom', LastName = 'Bobbo', Contact_First_Name__c = 'Dob', Contact_Last_Name__c = 'Dobbo', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433333333', Contact_Alternate_Phone_Number__c = '0299999999', Provider__c = acc.Id, Status = 'New',NDIS__c='431234567'); 
        insert lead;
        Account accountObj = [Select Id, Number_of_Leads__c FROM Account WHERE Name = 'SonaliTest'];
        System.assertEquals(1, accountObj.Number_of_Leads__c);
        lead.Provider__c = acc1.Id;
        Update lead;
        Account accountObj1 = [Select Id, Number_of_Leads__c FROM Account WHERE Name = 'SonaliTest1'];
        Account account1 = [Select Id, Number_of_Leads__c FROM Account WHERE Name = 'SonaliTest'];
        System.assertEquals(0, account1.Number_of_Leads__c);
        System.assertEquals(1, accountObj1.Number_of_Leads__c);
        delete lead;
        test.stopTest();
    }
}