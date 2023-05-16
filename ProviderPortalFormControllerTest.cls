/**
* TestData Factory: TestClassDataUtil
* Class Name: ProviderPortalFormController
* Description: Test class for ProviderPortalFormController
* Created By: Cloudwerx
* Created Date: 20/01/2021
*/
@isTest(SeeAllData=false)
public class ProviderPortalFormControllerTest {
    //Record Types Ids
    private static Id generalRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId();
    
    //private static Id profileId = [SELECT Id FROM Profile WHERE Name ='MPM Provider Portal User' LIMIT 1].Id;
    //private static User adminUser = [Select Id, UserRoleId From User Where Email ='test.1@example.com' LIMIT 1];
    
    @testSetup static void setup() {
        UserRole userrole = [Select Id, DeveloperName From UserRole Where DeveloperName = 'MPM_Standard_Role' Limit 1];
        
         Profile testProfile = [SELECT Id 
                           FROM profile
                           WHERE Name = 'System Administrator' 
                           LIMIT 1];

        User adminUser= new User(LastName = 'test user 1', 
                                 Username = 'test.user.123@example.com', 
                                 Email = 'test.123@example.com', 
                                 Alias = 'testu1', 
                                 TimeZoneSidKey = 'GMT', 
                                 LocaleSidKey = 'en_GB', 
                                 EmailEncodingKey = 'ISO-8859-1', 
                                 UserRoleId = userrole.Id,
                                 ProfileId = testProfile.Id, 
                                 LanguageLocaleKey = 'en_US',
                                 IsActive =true);
       
        System.runAs(adminUser){
            Id p = [select id from profile where name='MPM Provider Portal User'].id;
            
            /* Account ac = new Account(name ='Grazitti',ABN__c='11111111111') ;
            insert ac;  */

            //TTP-232                                 
            /*CREATE CLIENT ACCOUNT*/
            Account clientAccount = TestClassDataUtil.createClientAccount();

            /*CREATE PROVIDER ACCOUNT*/
            Account providerAccount = TestClassDataUtil.createProviderAccount(true, null, '51824753556');

            List<Invoice__c> invoiceList = TestClassDataUtil.createInvoiceRecords(true, 2, clientAccount.Id, providerAccount.Id, null);
            
            Contact con = new Contact(LastName ='testCon',AccountId = providerAccount.Id,Email='test123@testmail.com',MobilePhone='0412312311',PlanManager__c = 'NDSP');
            insert con;
            
            AccountContactRelation acrRec = [SELECT Id, AccountId FROM AccountContactRelation WHERE AccountId =: providerAccount.Id AND ContactId =: con.Id];
            acrRec.Relationship__c = 'Self';
            update acrRec;
            
            Id profileId = [SELECT Id FROM Profile WHERE Name ='MPM Provider Portal User' LIMIT 1].Id;
            
            User user = new User(alias = 'test123', email='testMethodClass@noemail.com',
                                 emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = profileId,IsActive =true,
                                 ContactId = con.Id,
                                 timezonesidkey='America/Los_Angeles', username='tester123@noemail.com');
            List<AccountContactRelation> accountContactRelation = [SELECT Id, AccountId,Relationship__c FROM AccountContactRelation WHERE ContactId =: user.ContactId AND Relationship__c = 'Self'];
            insert user;
            
            Case c = new Case(Origin = 'Email',Subject = 'Test OCR Claim Case Subject',PlanManager__c = 'NDSP', Description = 'Test case description',RecordTypeId = RecordTypeUtil.GENERAL_CASE_RECORD_TYPE_ID);
            insert c;

            /* CREATE SUPPORT CATEGORY */
            List<SupportCategory__c> scList = TestClassDataUtil.createSupportCategoryRecords(false,1);
            scList[0].SupportCategoryName__c = 'Assistance with Daily Life';
            scList[0].SupportCategoryCode__c = 'DAILY_ACTIVITIES';
            scList[0].Name = 'Assistance with Daily Life';
            insert scList;

            /*CREATE SUPPORT ITEMS*/
            List<SupportItem__c> supportItemList = TestClassDataUtil.createSupportItemRecords(true, 1, scList[0].Id);
            
            
            
        } 
    }
    
    @IsTest
    private static void testNDISNumberExist() {
        Test.startTest();
        
        Account clientAccount = [SELECT Id, NDIS__c 
                                    FROM Account 
                                    WHERE RecordTypeId =: RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID
                                    LIMIT 1];
        clientAccount.NDIS__c = '431234567';
        update clientAccount;
        
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('firstName', 'Bobby');
        gen.writeStringField('lastName', 'Bobbo');
        gen.writeStringField('ndisNumber','431231232');
        gen.writeStringField('dobConvert','2021-03-01');
        gen.writeStringField('street','street');
        gen.writeStringField('suburb','suburb');
        gen.writeStringField('postcode','2021');
        gen.writeEndObject();
        String pretty = gen.getAsString();
        
        //String x = '':'Bobby','lastName':'Bobbo','ndisNumber':'431231232'}';
        ProviderPortalFormController.searchClient(pretty);
        ProviderPortalFormController.fetchCaseMetadataRecord();
        ProviderPortalFormController.fetchPortalCustomSettings();
        ProviderPortalFormController.fetchSessionId();
        Case caseRec = new Case();
        caseRec.PlanManager__c = 'NDSP';
        ProviderPortalFormController.createCaseRecord(caseRec,5);
        //System.assertEquals(clientAccount.Id, ProviderPortalFormController.NDISNumberExist(clientAccount.NDIS__c));   
        
        Test.stopTest();
    }
    
    @isTest
    private static void testClaimsAutomation() {
        TestClassDataUtil.createClaimsAutomationSettings();
        Test.setMock(HttpCalloutMock.class, new ClaimsAutomationServiceMock());
        Test.startTest();   
        Case c = [SELECT Id FROM Case WHERE Subject = 'Test OCR Claim Case Subject'];
        
        ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document';
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = true;
            Insert cv;
        
        List<ContentVersion> cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion];
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = c.Id;
        cdl.ContentDocumentId = cvList[0].ContentDocumentId;
        cdl.shareType = 'V';
        insert cdl;
        ProviderPortalFormController.sentCasesToClaimAutomation(new List<Case> { c });
        Test.stopTest();
    }
    
    @IsTest
    private static void testFetchAccountDetails() {
        Test.startTest();           
        Id profileId = [SELECT Id FROM Profile WHERE Name ='MPM Provider Portal User' LIMIT 1].Id;
        User adminUser = [Select Id, UserRoleId From User Where Email ='test.123@example.com' LIMIT 1];
    
        ProviderPortalFormController.fetchAccountData(adminUser.Id);
        User providerUser = [Select Id, Name, UserRoleId, IsActive From User Where ProfileId =: profileId AND IsActive = true AND CreatedDate = TODAY Limit 1];
        System.runAs(providerUser){            
            ProviderPortalFormController.fetchAccountDetails();
            ProviderPortalFormController.fetchAccountData(providerUser.Id);
            try {
                ProviderPortalFormController.fetchAccountData(providerUser.Id);
            } catch (Exception e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateProviderPortalSurveyPreference(){
        Id profileId = [SELECT Id FROM Profile WHERE Name ='MPM Provider Portal User' LIMIT 1].Id;
        User providerUser = [Select Id, Name, UserRoleId, IsActive From User Where ProfileId =: profileId AND Email = 'testMethodClass@noemail.com' AND IsActive = true  Limit 1];
        Test.startTest();
            Id contactId = ProviderPortalFormController.updateProviderPortalSurveyPreference(providerUser.Id, false);
        Test.stopTest();
        System.assertNotEquals(null, contactId, 'Contact id is not null');
    }
    
     public class ClaimsAutomationServiceMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();

            response.setStatusCode(200);

            return response;
        }
    }

    //TTP-232
    @IsTest
    private static void testFetchInvoiceList() {
        Test.startTest();           
        Id profileId = [SELECT Id FROM Profile WHERE Name ='MPM Provider Portal User' LIMIT 1].Id;
        User adminUser = [Select Id, UserRoleId From User Where Email ='test.123@example.com' LIMIT 1];
    
        User providerUser = [Select Id, Name, UserRoleId, IsActive From User Where ProfileId =: profileId AND CreatedDate = TODAY Limit 1];
        System.runAs(providerUser){            
            List<String> filterStatus = new List<String>();//System.today().addMonths(-2).format()
            //filterStatus.add('In Progess');
            ProviderPortalFormController.fetchInvoiceList(10, 1, 'CreatedDate',true,filterStatus,'','','Bobby');
            try {
                //filterStatus.add('Cancelled');
                //filterStatus.add('In Progess');
                ProviderPortalFormController.fetchInvoiceList(10, 1, '',null,filterStatus,'','','');
            } catch (Exception e) {
                System.debug(e);
            }
        }
        Test.stopTest();
    }

    @isTest
    public static void testCreateInvoiceAndLineItem() {
        
        Id profileId = [SELECT Id FROM Profile WHERE Name ='MPM Provider Portal User' LIMIT 1].Id;
        User providerUser = [Select Id, Name, UserRoleId, IsActive From User Where ProfileId =: profileId AND IsActive = true AND CreatedDate = TODAY Limit 1];
        SupportItem__c supportItem = [SELECT Id FROM SupportItem__c LIMIT 1];
        
        //code changes - to validate package  28/11
        Case obj = [SELECT Id, CaseNumber FROM Case LIMIT 1];
        Account providerAccount = [SELECT Id FROM Account WHERE RecordTypeId =: RecordTypeUtil.PROVIDER_ACCOUNT_RECORD_TYPE_ID];        
        
        System.runAs(providerUser) {
            String formData = '{ \"abn\": \"12 345 678 901\", \"invoiceDate\": \"28 Oct 2021\", \"invoiceNo\": \"INV0090\", \"firstName\": \"Seth\", \"lastName\": \"Davis\", \"street\": \"WILL GO 20348 CASTLEREAGH HWY\", \"suburb\": \"LIGHTNING RIDGE\", \"state\": \"NSW\", \"postcode\": \"2834\", \"latitude\": -29.323675, \"longitude\": 147.97092975, \"ndisNumber\": \"434532124\", \"totalPrice\": 700, \"dob\": \"01 Oct 2000\", \"supportItem\": [ { \"supportCode\": \"03_509001024_0130_1_1Assistance Dog (Including Guide Dog) Ongoing Costs\", \"description\": \"Assistance Dog (Including Guide Dog) Ongoing Costs\", \"quantity\": 5, \"unitPrice\": \"100\", \"disableProductLookup\": false, \"productLookupPopulated\": false, \"_id\": 2, \"dateFrom\": \"01 Aug 2021\", \"dateTo\": \"15 Oct 2021\", \"dateFromConverted\": \"2021-08-01\", \"dateToConverted\": \"2021-10-15\", \"supportId\": "'+supportItem.Id+'", \"isExpanded\": false, \"inAccordian\": true } ], \"companyName\": \"Baboorao Industries\", \"providerId\": "'+providerAccount.Id+'", \"supportStartDate\": \"2021-08-01\", \"supportEndDate\": \"2021-10-15\", \"dobConvert\": \"2000-10-01\", \"casenumber\": \"' + obj.CaseNumber + '\"}';    
            //String formData = '{ \"abn\": \"12 345 678 901\", \"invoiceDate\": \"28 Oct 2021\", \"invoiceNo\": \"INV0090\", \"firstName\": \"Seth\", \"lastName\": \"Davis\", \"street\": \"WILL GO 20348 CASTLEREAGH HWY\", \"suburb\": \"LIGHTNING RIDGE\", \"state\": \"NSW\", \"postcode\": \"2834\", \"latitude\": -29.323675, \"longitude\": 147.97092975, \"ndisNumber\": \"434532124\", \"totalPrice\": 700, \"dob\": \"01 Oct 2000\", \"supportItem\": [ { \"supportCode\": \"03_509001024_0130_1_1Assistance Dog (Including Guide Dog) Ongoing Costs\", \"description\": \"Assistance Dog (Including Guide Dog) Ongoing Costs\", \"quantity\": 5, \"unitPrice\": \"100\", \"disableProductLookup\": false, \"productLookupPopulated\": false, \"_id\": 2, \"dateFrom\": \"01 Aug 2021\", \"dateTo\": \"15 Oct 2021\", \"dateFromConverted\": \"2021-08-01\", \"dateToConverted\": \"2021-10-15\", \"supportId\": "'+supportItem.Id+'", \"isExpanded\": false, \"inAccordian\": true } ], \"companyName\": \"Baboorao Industries\", \"providerId\": \"0015O000007Wqu8QAC\", \"supportStartDate\": \"2021-08-01\", \"supportEndDate\": \"2021-10-15\", \"dobConvert\": \"2000-10-01\", \"casenumber\": \"02330519\" }';
            String invoiceId = ProviderPortalFormController.createInvoiceAndLineItems(formData);
            System.assert(invoiceId != null);
        }
    }
    
    @isTest
    public static void testAttachFileAsPDF(){
        Id invoiceId = [Select id from Invoice__c limit 1].Id;
        ProviderPortalFormController.attachFileAsPDF(invoiceId);
        //System.assert([Select id from ContentVersion].size() > 0);
    }
    
}