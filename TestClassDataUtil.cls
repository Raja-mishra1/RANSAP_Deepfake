/**
 * @description       : 
 * @author            : Cloudwerx
 * @group             : 
 * @last modified on  : 02-19-2022
 * @last modified by  : Aman Agarwal
**/
@IsTest
public class TestClassDataUtil {

    public static List<Schema.PicklistEntry> pickListValuesList = PlanSupport__c.PlanManagementType__c.getDescribe().getPicklistValues();
   
    public static Account createDefaultAccount() {
        Account defaultAccount = new Account(Name = 'MPM', ABN__c = '1231234', RecordTypeId = RecordTypeUtil.COMPANY_ACCOUNT_RECORD_TYPE_ID);
        insert defaultAccount;

        return defaultAccount;
    }

    public static Contact createContact(Id defaultAccountId) {
        Contact contact = new Contact(FirstName = 'Bob', LastName = 'Barker', Email = 'bob@example.com', AccountId = defaultAccountId,PlanManager__c = 'MPM');
        insert contact;

        return contact;
    }

    //added by Sumita 
    public static AccountContactRelation createAccountContactRelation(Id accountId, Id contactId) {
        AccountContactRelation acr = new AccountContactRelation(AccountId = accountId, ContactId = contactId, Primary_Contact__c = true, Relationship__c = 'Plan Nominee');
        insert acr;

        return acr;
    }
    
    public static Account createProviderAccount(Id parentId) {
        return createProviderAccount(parentId, '51824753556');
    }

    public static Account createProviderAccount(Id parentId, String abn) {
        return createProviderAccount(true, parentId, abn);
    }

    public static Account createProviderAccount(Boolean doInsert, Id parentId, String abn) {
        Test_GenericMockCallouts();
        Account providerAccount = new Account(
            Name = 'Bobbo', 
            ABN__c = abn, 
            ParentId = parentId,
            Business_Email__c = 'businessemail@test.com',
            RecordTypeId = RecordTypeUtil.PROVIDER_ACCOUNT_RECORD_TYPE_ID
        );

        if (doInsert) {
            insert providerAccount;
        }

        return providerAccount;
    }

    public static Account createClientAccount() {
        Test_GenericMockCallouts();
        Pod__c exPod = new Pod__c(Name = 'Exception', Pod_Type__c = 'Regional', PlanManager__c = 'MPM');
        insert exPod;

        Account clientAccount = new Account(
            FirstName = 'Bobby', 
            LastName = 'Bobbo', 
            NDIS__c = '431231232', 
            PersonBirthdate = Date.today(), 
            MPM_Critical_Note_Exclusion__c = false,
            RecordTypeId = RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID,
            PlanManager__c = 'MPM'
        );
        insert clientAccount;

        return clientAccount;
    }

    public static Case createCase(String ownerId) {
        Case c = new Case(
            Origin = 'Email',
            Subject = 'Test OCR Claim Case Subject Master', 
            Description = 'Test case description', 
            OwnerId = ownerId,
            PlanManager__c = 'MPM',
            RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID
           );
        insert c;

        return c;
    }

    public static Lead createLead() {
        Lead lead = new Lead(LeadSource = 'Family', FirstName = 'Bob', LastName = 'Bobbo', Contact_First_Name__c = 'Dob', Contact_Last_Name__c = 'Dobbo', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433333333', Contact_Alternate_Phone_Number__c = '0299999999',NDIS__c='431234567');
        insert lead;

        return lead;
    }
	
    public static User createTestStandardUser() {
        Profile mpmStandardUserProfile = [SELECT Id FROM Profile WHERE Name = 'MPM Standard User'];
		
        User testUser = new User(
            LastName = 'McTest',
            Email = 'test@myplanmanager.com.au',
            ProfileId = mpmStandardUserProfile.Id,
            Username = 'test@myplanmanager.com.au',
            Alias = 'testmct',
            TimeZoneSidKey = 'Pacific/Auckland',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8'
        );

        insert testUser;

        return testUser;
    }

    public static List<User> createUserRecords(Integer count, Boolean performDml, String profileName) {
        Profile profile = [SELECT Id FROM Profile WHERE Name =:profileName];
        List<User> userList = new List<User>();
        for (Integer i=0; i<count; i++) {
            User testUser = new User(
                LastName = 'McAdmin',
                Email = 'sysadmin@myplanmanager.com.au',
                ProfileId = profile.Id,
                Username = 'sysadmin@myplanmanager.com.au',
                Alias = 'testmca',
                TimeZoneSidKey = 'Pacific/Auckland',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8'
            );
            userList.add(testUser);
        }
        if(performDml) {
            insert userList;
        }
            
        return userList;
    }

    public static List<Contact> createContactRecords(Integer count, Boolean performDML, Id accountId) {
        List<Contact> contactList = new List<Contact>();
        for (integer i = 0;i< count; i++) {
            Contact contact = new Contact(
                FirstName = 'Bob'+i, 
                LastName = 'Barker'+i, 
                Email = 'bob' +i +'@example.com', 
                AccountId = accountId,
                PlanManager__c = 'MPM'
            );
            contactList.add(contact);
        }

        if(performDml) {
            insert contactList;
        }

        return contactList;
    }

    public static AccountContactRelation createAccountContactRelationRecords(Boolean performDML, Id accountId, Id contactId) {
            AccountContactRelation acr = new AccountContactRelation(
                AccountId = accountId, 
                ContactId = contactId, 
                Primary_Contact__c = true, 
                SMS_Notification__c = true,
                Relationship__c = 'Plan Nominee'
            );

        if(performDml) {
            insert acr;
        }

        return acr;
    }

    public static User createTestSystemAdminUser() {
        Profile systemAdministratorProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        User testUser = new User(
            LastName = 'McAdmin',
            Email = 'sysadmin@myplanmanager.com.au',
            ProfileId = systemAdministratorProfile.Id,
            Username = 'sysadmin@myplanmanager.com.au',
            Alias = 'testmca',
            TimeZoneSidKey = 'Pacific/Auckland',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8'
        );

        insert testUser;

        return testUser;
    }

    public static Claims_Automation_Settings__c createClaimsAutomationSettings() {
        Claims_Automation_Settings__c claimsAutomationSettings = new Claims_Automation_Settings__c();
        claimsAutomationSettings.Claims_Automation_Endpoint__c = 'https://test.salesforce.com';
        claimsAutomationSettings.Bearer_Token__c = 'bearerofbadnews';

        insert claimsAutomationSettings;

        return claimsAutomationSettings;
    }
    
    public static void createMPMEmailSettings() {
        MPM_Email_Addresses__c mpmEmails = MPM_Email_Addresses__c.getOrgDefaults();

        mpmEmails.Welcome__c = 'no-replytest@myplanmanager.com.au';

        insert mpmEmails;
    }

    public static ContentNote createNote(Id parentId) {
        ContentNote note = new ContentNote(Title = 'Test Note', Content = Blob.valueOf('test note'));

        insert note;

        ContentDocumentLink contentDocumentLink = new ContentDocumentLink(ContentDocumentId = note.Id, LinkedEntityId = parentId);

        insert contentDocumentLink;

        return note;
    }

    public static List<ServiceBookingRequest__c> createServiceBookingRequests(Integer count, Boolean performDml, Id accountId) {
        List<ServiceBookingRequest__C> sbrList = new List<ServiceBookingRequest__C>();

        for (Integer i = 0; i < count; i++) {
            ServiceBookingRequest__C sbrObj = new ServiceBookingRequest__C(
                Account__c = accountId,
                Status__c = 'Not Started',
                ClientLastName__c = 'Test LastName' + i,
                ClientNDISNumber__c = '43131231' + i,
                RequestType__c = 'Full Booking',
                PriceGuideAmount14_034__c = 2244 + (i * 100),
                PriceGuideAmount14_033__c = 4335 + (i * 100),
                PriceGuideAmount14_032__c = 5243 + (i * 100),
                PlanStartDate__c = Date.newInstance(2021, 3, 1),
                PlanEndDate__c = Date.newInstance(2021, 6, 1),
                ClientDateOfBirth__c = Date.newInstance(2020, 10, 23)
            );

            sbrList.add(sbrObj);
        }

        if (performDml) {
            insert sbrList;
        }
        return sbrList;
    }

    public static SupportItem__c createSupportItem(Id categoryId) {
        SupportItem__c supportItem = new SupportItem__c(
            ExternalId__c = '09_006_0106_6_3_2020-12-01_4000-12-31',
            SupportCategory__c = categoryId
            );
        insert supportItem;

        return supportItem;
    }
    
    
    public static SupportCategory__c createSupportCategory() {
        SupportCategory__c category = new SupportCategory__c(
            Name = 'CB_HEALTH_WELLBEING',
            SupportCategoryName__c = 'Improved Health and Wellbeing',
            SupportCategoryNumber__c = 12,
            SupportCategoryCode__c = 'CB_HEALTH_WELLBEING',
            SupportTypeName__c = 'Capacity Building',
            SupportTypeCode__c = 'ZCAP');
        insert category;

        return category;
    }

    public static Invoice__c createInvoice() {
        Invoice__c inv = new Invoice__c();
        insert inv;
        return inv;
    }

    public static ServiceBooking__c createServiceBooking() {
        ServiceBooking__c sb = new ServiceBooking__c();
        insert sb;
        return sb;
    }

    public static Plan__c createPlan(Id accId) {
        Plan__c plan = new Plan__c();
        plan.Plan_Start_Date__c = System.today();
        plan.Plan_End_Date__c = System.today().addMonths(1);
        plan.Client_Name__c = accId;
        insert plan;
        return plan;
    }

    public static PlanSupport__c createPlanSupport(Id planId, Id supportCategoryId) {
        PlanSupport__c planSupport = new PlanSupport__c();
        planSupport.Plan__c = planId;
        planSupport.SupportCategory__c = supportCategoryId;
        planSupport.AllocatedFunds__c = 100;
        planSupport.FundsApproved__c = 80;
        insert planSupport;
        return planSupport;
    }

    public static PlanSupportItem__c createPlanSupportItem(Id planId, Id planSupportId) {
        PlanSupportItem__c planSupportItem = new PlanSupportItem__c();
        planSupportItem.Plan__c = planId;
        planSupportItem.PlanSupport__c = planSupportId;
        insert planSupportItem;
        return planSupportItem;
    }

    public static Invoice_Line_Item__c createInvoiceLineItem(Id invId, Id planId, Id planSupportId, Id planSupportItemId, Id sbId, Id supportItemId) {
        Invoice_Line_Item__c item = new Invoice_Line_Item__c();
        item.Invoice__c = invId;
        item.UOM__c = 'WK';
        item.Quantity__c = 20;
        item.Plan__c = planId;
        item.Plan_Support__c = planSupportId;
        item.Plan_Support_Item__c = planSupportItemId;
        item.Support_Item__c = supportItemId;
        item.Service_Booking__c = sbId;
        insert item;
        return item;
    }

    //TTP-869
    public static List<Payment_Request__c> createPaymentRequest(Boolean isInsert, Integer recordCount, Plan__c plan, Id providerId) {
        List<Payment_Request__c> paymentRequestList = new List<Payment_Request__c>();

        for (Integer i = 1; i<=recordCount; i++) {
            Payment_Request__c  paymentRequestRecord = new Payment_Request__c ();
            paymentRequestRecord.Plan__c = plan.Id;
            paymentRequestRecord.Client__c = plan.Client_Name__c;
            paymentRequestRecord.Provider__c = providerId;
            paymentRequestList.add(paymentRequestRecord);
        }


        if(isInsert)
        	insert paymentRequestList;
        return paymentRequestList;
    }

    public static void Test_GenericMockCallouts() {
        GenericMockCallouts fakeResponse = new GenericMockCallouts(200,'{"access_token": "","expires_in":3600, "token_type" : "Bearer"}');
        Test.setMock(HttpCalloutMock.class, fakeResponse);
    }
    
    /* METHOD TO INSERT CHILD CASE RECORD */
    public static Case createChildCase(Boolean isInsert, String ownerId, String ParentId) {
        Case c = new Case(
            Origin = 'Email',
            Subject = 'Test OCR Claim Case Subject Child', 
            Description = 'Test case description', 
            OwnerId = ownerId, 
            ParentId = ParentId,
            PlanManager__c = 'MPM',
            RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID
           );
        if(isInsert)
        	insert c;

        return c;
    }
    
    /* METHOD TO INSERT LIST OF PLAN RECORDS */
    public static List<Plan__c> createPlanRecords(Boolean isInsert, Integer recordCount, Id clientId) {
        List<Plan__c> planList= new List<Plan__c>();
        for(integer i = 1; i<=recordCount; i++){
            Plan__c plan = new Plan__c();
            plan.Plan_Start_Date__c = System.today();
            plan.Plan_End_Date__c = System.today().addMonths(i);
            plan.Client_Name__c = clientId;
            plan.PRODA_Plan_Id__c = String.valueOf(i);//Validation error fix Aman/Prithvi/Mehul - E2E
            planList.add(plan);
        }
        if(!planList.isEmpty() && isInsert)
        	insert planList;
        
        return planList;
    }
    
    /* METHOD TO INSERT INVOICE RECORDS */
    public static List<Invoice__c> createInvoiceRecords(Boolean isInsert, Integer recordCount, Id clientId, Id providerId, Id caseId) {
        //TTP-607-TTP-36
        DocumentDTO parsedDocumentData = DocumentDTO.parse(DocumentRestServiceTestDataHelper.getInvoiceJSON(
            caseId, '395cc8dc-42b1-49c5-9fa5-6578','09_006_0106_6_3_2020-12-01_4000-12-31'
        ));

        List<Invoice__c> invoiceList= new List<Invoice__c>();
        for(integer i = 1; i<=recordCount; i++){
            Invoice__c invoice = new Invoice__c();
            invoice.Client__c = clientId;
            invoice.Provider__c = providerId;
            invoice.Case__c = caseId;
            invoice.Document_Type__c = 'invoice';
            invoice.Document_JSON__c = JSON.serialize(parsedDocumentData);//TTP-607-TTP-36
            invoice.Total__c = 1387.74;
            invoice.Invoice_Origin__c = 'Manual';
			invoice.PlanManager__c = 'MPM';
            invoiceList.add(invoice);
        }
        if(!invoiceList.isEmpty() && isInsert)
        	insert invoiceList;
        
        return invoiceList;
    }
    
    /* METHOD TO INSERT INVOICE LINE ITEM RECORDS */
    public static List<Invoice_Line_Item__c> createInvoiceLineItemRecords(Boolean isInsert, Integer recordCount, Id invId, Id planId, Id planSupportId, Id planSupportItemId, Id sbId, Id supportItemId) {
        List<Invoice_Line_Item__c> lineItemList= new List<Invoice_Line_Item__c>();
        for(integer i = 1; i<=recordCount; i++){
            Invoice_Line_Item__c item = new Invoice_Line_Item__c();
            item.Invoice__c = invId;
            item.UOM__c = 'WK';
            item.Quantity__c = 20;
            item.Total__c = 20;
            item.Plan__c = planId;
            item.Plan_Support__c = planSupportId;
            item.Plan_Support_Item__c = planSupportItemId;
            item.Support_Item__c = supportItemId;
            item.Service_Booking__c = sbId;
            //item.Support_Code__c = '1_0023_436_' + i;
            item.Service_Date_From__c = System.today().addDays(12);
            item.Service_Date_To__c =  System.today().addDays(24);
            item.Description__c = 'Test';
            item.Rate__c = item.Total__c/ item.Quantity__c;
            item.GST__c = 0;
            lineItemList.add(item);
        }
        if(!lineItemList.isEmpty() && isInsert)
        	insert lineItemList;
        
        return lineItemList;
        
    }

    public static List<SupportItem__c> createSupportItemRecords(Boolean isInsert, Integer recordCount, Id supportCategoryId) {
        List<SupportItem__c> supportItemList = new List<SupportItem__c>();
        for(integer i = 1; i<=recordCount; i++){
            SupportItem__c sItem = new SupportItem__c();
            sItem.SupportCategory__c = supportCategoryId;
            sItem.SupportItemNumber__c = '1_0023_436_' + i;
            // sItem.NSWPrice__c = 23.24;
            // sItem.NTPrice__c = 29.43;
            // sItem.RemotePrice__c = 120.0;
            supportItemList.add(sItem);
        }

        if(!supportItemList.isEmpty() && isInsert) {
            insert supportItemList;
        }

        return supportItemList;
    }

    public static List<SupportItemPrice__c> createSupportItemPriceRecords(Boolean isInsert, Integer recordCount, Id supportItemId) {
        List<SupportItemPrice__c> supportItemPriceList = new List<SupportItemPrice__c>();
        for(integer i = 1; i<=recordCount; i++) {
            SupportItemPrice__c sPrice = new SupportItemPrice__c();
            sPrice.SupportItem__c = supportItemId;
            sPrice.StartDate__c = System.today().addMonths(-12);
            sPrice.EndDate__c = System.today().addMonths(36);
            supportItemPriceList.add(sPrice);
        }
        if(!supportItemPriceList.isEmpty() && isInsert) {
            insert supportItemPriceList;
        }

        return supportItemPriceList;
    }

    public static List<PlanSupport__c> createPlanSupports(Boolean isInsert, Integer recordCount, Id planId, Id supportCategoryId) {

        List<PlanSupport__c> psList = new List<PlanSupport__c>();

        for(Integer i=1; i<=recordCount; i++) {
            PlanSupport__c ps = new PlanSupport__c();
            ps.Plan__c = planId;
            ps.SupportCategory__c = supportCategoryId;
            ps.FundsApproved__c = 3000 + i;
            ps.FundsSpent__c = 500 + i;
            ps.AllocatedFunds__c = 100+i;
            ps.MPM_Reference_Id__c = Integer.valueof(Math.random() * 1000) + i;
            ps.PlanManagementType__c = pickListValuesList[Math.mod(i, 8)].getValue();
            psList.add(ps);
        }

        if(isInsert && !psList.isEmpty()) {
            insert psList;
        }

        return psList;
    }

    public static List<PlanSupportItem__c> createPlanSupportItems(Boolean isInsert, Integer recordCount, Id planId, Id planSupportId) {
        List<PlanSupportItem__c> psItemList = new List<PlanSupportItem__c>();
        for(Integer i=0; i<recordCount; i++) {
            PlanSupportItem__c obj = new PlanSupportItem__c();
            obj.Name = 'Test ' + i;
            obj.Plan__c = planId;
            obj.PlanSupport__c = planSupportId;
            obj.Item_Type__c ='ZSTA';
            obj.QuoteRequired__c = 'Yes';
            obj.FundsApproved__c= 100;
            obj.AllocatedFunds__c = 200;
               
            psItemList.add(obj);
        }

        if(isInsert && !psItemList.isEmpty()) {
            insert psItemList;
        }

        return psItemList;
    }
    
    /* METHOD TO INSERT Plan Support Preference RECORDS */
    public static List<PlanSupportPreference__c> createPlanSupportPreferenceRecords(Boolean isInsert, Integer recordCount,Id accId, Id planId, Id planSupportId, Id supportCategoryId) {
		List<PlanSupportPreference__c> pspList = new List<PlanSupportPreference__c>();
        for(integer i = 1; i<=recordCount; i++){            
            PlanSupportPreference__c obj= new PlanSupportPreference__c();
            obj.Provider__c = accId;
            obj.Plan__c = planId;
            obj.PlanSupport__c = planSupportId;
            obj.SupportItemNumber__c = '1_0023_436_' + i;
            obj.Support_Category__c = supportCategoryId;
            obj.SubstitutionPlanSupport__c = planSupportId;
            obj.SubstitutionSupportItemNumber__c = '1_0023_436_' + i;
            obj.StartDate__c = System.today();
            obj.EndDate__c = System.today().addDays(2);
            pspList.add(obj);
        }
        if(!pspList.isEmpty() && isInsert)
        	insert pspList;
        
        return pspList;
        
    }
    
    /* METHOD TO INSERT Locked Budget Line Item RECORDS*/
    public static List<PlanSupportPreferenceLineItem__c> createPlanSupportPreferenceLineItemRecord(Boolean isInsert, Integer recordCount,Id pspList,Id supportItemId ) {
        List<PlanSupportPreferenceLineItem__c> lockedBudgetLineItem = new list<PlanSupportPreferenceLineItem__c>();
        for(integer i = 1; i<=recordCount; i++){
            PlanSupportPreferenceLineItem__c pspLineItem= new PlanSupportPreferenceLineItem__c();
            pspLineItem.ClientBudgetPreference__c = pspList;
            pspLineItem.Active__c = true;
            pspLineItem.SupportItem__c = supportItemId;
            lockedBudgetLineItem.add(pspLineItem);
        }
        if(!lockedBudgetLineItem.isEmpty() && isInsert)
            insert lockedBudgetLineItem;
        
        return lockedBudgetLineItem;
    }
    
    /* METHOD TO INSERT Support Category RECORDS*/
     public static List<SupportCategory__c> createSupportCategoryRecords(Boolean isInsert, Integer recordCount) {
		List<SupportCategory__c> scList = new List<SupportCategory__c>();
        for (integer i = 1; i<=recordCount; i++) {            
            SupportCategory__c obj= new SupportCategory__c();
            obj.Name = 'ASSISTIVE_TECHNOLOGY';
            obj.SupportCategoryName__c = 'Assistive Technology';
            obj.SupportCategoryNumber__c = 5+i;
            obj.SupportCategoryCode__c = 'ASSISTIVE_TECHNOLOGY';
            obj.SupportTypeName__c = 'Core';
            obj.SupportTypeCode__c = 'ZCOR';
            scList.add(obj);
        }
        if(!scList.isEmpty() && isInsert)
        	insert scList;
        
        return scList;
        
    }
    
    /* METHOD TO INSERT MMM RECORDS*/
     public static List<ModifiedMonashModel__c> createMMMRecords(Boolean isInsert, Integer recordCount, String postCode) {
		List<ModifiedMonashModel__c> mmmList = new List<ModifiedMonashModel__c>();
        for(integer i = 1; i<=recordCount; i++){            
            ModifiedMonashModel__c mmmObj= new ModifiedMonashModel__c();
            mmmObj.NDISMMMClassification__c = 1;
            mmmObj.MMMClassification__c = 2;
            mmmObj.Postcode__c = postCode != null ? postCode : '';
            mmmObj.Sa1CodeMain__c = 'testSa';
            mmmObj.LocationName__c = 'loc';
            mmmObj.MMMYear__c = '2011';
            mmmList.add(mmmObj);
        }
        if(!mmmList.isEmpty() && isInsert)
        	insert mmmList;
        
        return mmmList;        
    }

    /* METHOD TO INSERT Support Category RECORDS*/
    public static List<ServiceBooking__c> createServiceBookingRecords(Boolean isInsert, Integer recordCount) {
        List<ServiceBooking__c> SBList = new List<ServiceBooking__c>();
        for (integer i = 1; i<=recordCount; i++) {            
            ServiceBooking__c record= new ServiceBooking__c();
            record.ExternalId__c = '123'+i;
            SBList.add(record);
        }
        if(!SBList.isEmpty() && isInsert)
        	insert SBList;
        return SBList;
    }

     /* METHOD TO INSERT CREDIT NOTE RECORDS*/

     public static List<CreditNote__c> createCreditNoteRecords(Boolean isInsert, Integer recordCount) {
        List<CreditNote__c> creditNoteList = new List<CreditNote__c>();
        for (integer i = 1; i<= recordCount; i++) {            
            CreditNote__c record= new CreditNote__c();
            record.Total__c = 100;
            record.FundsSpent__c = 50;
            record.DateIssued__c = Date.today();
            record.DateReceived__c = Date.today();
            record.Origin__c = 'MPM';
            record.CreditNoteReference__c = 'Test';
            creditNoteList.add(record);
        }

        if(!creditNoteList.isEmpty() && isInsert) insert creditNoteList;
        return creditNoteList;
    }

     // To create LOR Directory records
     public static List<LORDirectory__c> createLORDirectoryRecords (Boolean isInsert, Integer recordCount) {
        List<LORDirectory__c> records = new List<LORDirectory__c>();
        for (Integer i=0; i<recordCount; i++) {
            LORDirectory__c lor = new LORDirectory__c();
            lor.SupportItemNumber__c = '1_0023_436_' + i;
            lor.StartDate__c = System.today().addDays(-30);
            lor.EndDate__c = System.today().addDays(30);
            lor.AssessmentLevel__c = 'Level 2';
            records.add(lor);
        }

        if (isInsert) {
            insert records;
        }

        return records;
    }
    
    //added By Anil 
    //Created data for Service Resources  [CS-287]
    public static ServiceResource CreateServiceResourecesData() {
        User u = TestClassDataUtil.createTestStandardUser();
           ServiceResource servResource = new ServiceResource();
           servResource.Name = 'TestServiceResourceForCaseReassignment';
           servResource.IsActive = True;
           servResource.ResourceType = 'A';
           servResource.RelatedRecordId = u.Id;
           insert servResource;
           return servResource;
   }
}