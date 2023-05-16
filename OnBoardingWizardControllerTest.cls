/**
 * Class Name: OnBoardingWizardControllerTest
 * Description: Test class for OnBoardingWizardController
 * Created By: Cloudwerx
 * Created Date: 04/09/2020
*/

/*  @Modified Date : 20/04/2021
    @Modified By : Yash Bhalerao
	@Modification : Added test method to cover insertTask method
    @Ticket : [CS-105]
*/

@isTest
public class OnBoardingWizardControllerTest { 
    
  	@TestSetup
    static void checkCustomSetting(){ 
        Reconnection_Trigger_Configuration__c recon = new Reconnection_Trigger_Configuration__c();
        recon.ContactTriggerActivated__c = True;
        insert recon;
        
        My_Plan_Manager_Contact_Settings__c mpm = new My_Plan_Manager_Contact_Settings__c();
        mpm.My_Plan_Manager_Label__c = 'My Plan Manager';
        mpm.Business_Email__c = 'test@test.com';
        mpm.Counter__c = 1;
        mpm.Maximum_Allowed_Contacts__c = 2;
        insert mpm;
    }
    
    
    @istest
    static void testOnBoardingWizardControllerMethods() {
       // test.startTest();
        Lead l = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New', PlanManager__c = 'MPM',
        Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '2000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',
        Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
        Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}',
        Correspondence_Nominee_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Correspondence","LastName":"Nominee","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testCnominee@test.com"}',
        Support_Coordinator_1_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 1","MiddleName":"Correspondence","LastName":"Support Nominee 1","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnomineeq@test.com"}',
        Service_Agreement_JSON__c = '{"sobjectType":"Service_Agreement__c","Id":"","Name":"Jimmy Walking Service Agreement","Status__c":"Current","Commencement_Date__c":"2020-09-29T07:48:29.021Z","Activated_Date__c":"2020-09-29T07:48:29.021Z","Date_Signed__c":"2020-09-29T07:48:29.021Z","NDIS_Participant__c":null,"Signed_By__r.Name":"","Signed_By__c":"Jimmy Walking","Service_Agreement_Type__c":"Uploaded File","Verbal_Agreement_Received_by__c":"0054Y000000aKwNQAU","SA_Verbal_Acceptance_Date__c":"2020-09-22T15:18:48.637Z","Service_Agreement_Skip_Reason_Other__c":"","Signed_By__r":{"Name":"Jimmy Walking"},"Lead__c":"00Q4Y000001LeWGUA0"}'                 
        /* Support_Coordinator_2_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 2","MiddleName":"Correspondence","LastName":"Support Nominee 2","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee2@test.com"}',
        Support_Coordinator_3_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 3","MiddleName":"Correspondence","LastName":"Support Nominee 3","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee3@test.com"}',
        Support_Coordinator_4_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 4","MiddleName":"Correspondence","LastName":"Support Nominee 4","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee4@test.com"}',
        Support_Coordinator_5_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 5","MiddleName":"Correspondence","LastName":"Support Nominee 5","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee5@test.com"}' */
                         );
        insert l;
       //calling OnBoardingWizardController Methods
        MPM_Email_Addresses__c mpmEmails = MPM_Email_Addresses__c.getOrgDefaults();
        mpmEmails.Welcome__c = 'welcome@test.com.au';
        insert mpmEmails;
        test.startTest();
        OnBoardingWizardController.retrieveLeadRecord(l.Id);
        //OnBoardingWizardController.sendClickToAcceptLead(l.Id, 'testing@test.com');
        OnBoardingWizardController.saveLead(l);
        OnBoardingWizardController.executeLeadConversion(l);    
        test.stopTest();
    } 
    
    @isTest
    static void testsendEmail() { 
        //OnBoardingWizardController.sendClickToAcceptLead();
    }
    
    
    @istest
    static void testCreateContactAndAccountRelation() { 
        Account a = TestClassDataUtil.createClientAccount();
        Contact co = new Contact();
        co.LastName = 'Test Sanpat';
        co.FirstName = 'Sanpat';
        co.Email = 'sad@test.com';
        insert co;
        String primaryContactJson = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sanpat","MiddleName":"Sanpat test","LastName":"Test Sanpat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"sad@test.com"}';
        test.startTest();
        
        try {
            
            OnBoardingWizardController.createContactandAccountContactRelation(primaryContactJson,a.Id,'Primary Decision Maker', 'MPM');
        }catch (Exception e) {
            
        }
        test.stopTest();
    }
    
    @istest
    static void testFindContactMethod() {  
        test.startTest();
        OnBoardingWizardController.findContacts('Test','Test', 'test@gmail.com','4377777777', '43777777777'); //For No duplicate record
        OnBoardingWizardController.findContacts('Sonali','test', 'sonali@example.com','', ''); //For duplicate record
        OnBoardingWizardController.findContacts('','', '','', ''); //For duplicate record
        test.stopTest();
    }
    
    @istest
    static void testSaveDateMethod() {  
        Lead lr = new Lead();
        lr.LastName = 'Blob';
        lr.FirstName = 'Builder';
        lr.LeadSource = 'Google';
        insert lr;
        test.startTest();
        OnBoardingWizardController.setLeadRecordAttributes(lr.Id,'Start time');
        OnBoardingWizardController.setLeadRecordAttributes(lr.Id,'End time');
        test.stopTest();
    }
    
    @istest
    static void testLoginUserMethod() {  
        test.startTest();
        OnBoardingWizardController.fetchloggedInUser();
        test.stopTest();
    }
    
    @istest
    static void testPopulateLookup() {  
        Account a = TestClassDataUtil.createClientAccount();
        List<Service_Agreement__c> sList = new List<Service_Agreement__c>();
        Service_Agreement__c sa = new Service_Agreement__c();
        sa.Name = 'Test Agreement';
        sa.PlanManager__c = 'MPM';
        sList.add(sa);
        test.startTest();
        OnBoardingWizardController.populateLookup(sList,a.Id);
        test.stopTest();
    }
    
    @istest
    public static void testVerifyNDIS_ID() {  
        Lead l = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New', PlanManager__c = 'MPM',
        Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '2000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',
        Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
        Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}',
        Correspondence_Nominee_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Correspondence","LastName":"Nominee","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testCnominee@test.com"}',
        Support_Coordinator_1_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 1","MiddleName":"Correspondence","LastName":"Support Nominee 1","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnomineeq@test.com"}'
        /* Support_Coordinator_2_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 2","MiddleName":"Correspondence","LastName":"Support Nominee 2","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee2@test.com"}',
        Support_Coordinator_3_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 3","MiddleName":"Correspondence","LastName":"Support Nominee 3","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee3@test.com"}',
        Support_Coordinator_4_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 4","MiddleName":"Correspondence","LastName":"Support Nominee 4","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee4@test.com"}',
        Support_Coordinator_5_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 5","MiddleName":"Correspondence","LastName":"Support Nominee 5","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee5@test.com"}' */
                         );
        insert l;
        test.startTest();
        OnBoardingWizardController.verifyNDISExists('431231232', l.Id, 'MPM');
        OnBoardingWizardController.verifyNDISExists('', l.Id, 'MPM');
        test.stopTest();
    }
    
    @istest
    static void testmapAccountContactFieldsMethod() {  
        Lead l = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New',PlanManager__c = 'MPM',
        Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '2000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',
                         // Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '2000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',
                          Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
                          Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}',
                          Correspondence_Nominee_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Correspondence","LastName":"Nominee","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testCnominee@test.com"}'
                          /* Support_Coordinator_1_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 1","MiddleName":"Correspondence","LastName":"Support Nominee 1","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnomineeq@test.com"}',
                          Support_Coordinator_2_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 2","MiddleName":"Correspondence","LastName":"Support Nominee 2","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee2@test.com"}',
                          Support_Coordinator_3_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 3","MiddleName":"Correspondence","LastName":"Support Nominee 3","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee3@test.com"}',
                          Support_Coordinator_4_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 4","MiddleName":"Correspondence","LastName":"Support Nominee 4","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee4@test.com"}',
                          Support_Coordinator_5_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 5","MiddleName":"Correspondence","LastName":"Support Nominee 5","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee5@test.com"}' */
                         );
        insert l;
        Account a = TestClassDataUtil.createClientAccount();
        Contact c = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com', PlanManager__c = 'MPM');
        insert c;
        Opportunity opp = new Opportunity(Name= 'Test Opp',StageName = 'Qualification', AccountId = a.Id);
        test.startTest();
        OnBoardingWizardController.mapAccountContactFields(c.Id,a.Id,l);
        test.stopTest();
        
    }
    
    @istest
    static void testwrapContact() {  
        Contact c = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com', PlanManager__c = 'MPM');
        insert c;
        test.startTest();
        OnBoardingWizardController.wrapContact(c,'MPM');
        test.stopTest();
    }
    
    @istest
    static void testserviceAgreementMethod() {  
        Lead l = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New', PlanManager__c ='MPM',
                          Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '2000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',
                          Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
                          Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}',
                          Correspondence_Nominee_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Correspondence","LastName":"Nominee","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testCnominee@test.com"}',
                          Support_Coordinator_1_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 1","MiddleName":"Correspondence","LastName":"Support Nominee 1","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnomineeq@test.com"}'
                          /* Support_Coordinator_2_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 2","MiddleName":"Correspondence","LastName":"Support Nominee 2","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee2@test.com"}',
                          Support_Coordinator_3_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 3","MiddleName":"Correspondence","LastName":"Support Nominee 3","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee3@test.com"}',
                          Support_Coordinator_4_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 4","MiddleName":"Correspondence","LastName":"Support Nominee 4","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee4@test.com"}',
                          Support_Coordinator_5_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 5","MiddleName":"Correspondence","LastName":"Support Nominee 5","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee5@test.com"}' */
                         );
        insert l;
        Contact c = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com',PlanManager__c ='MPM');
        insert c;
        Service_Agreement__c ser = new Service_Agreement__c(Lead__c = l.Id ,Service_Agreement_Type__c = 'Email - Click to Accept',Name ='Test Service Agreement',Status__c ='Current',Signed_By__c = c.id,  Commencement_Date__c = System.Today(), Activated_Date__c = System.Today(), PlanManager__c = 'MPM');
        insert ser;
        Service_Agreement__c ser1 = new Service_Agreement__c(Lead__c = l.Id ,Service_Agreement_Type__c = 'Verbal Acceptance',Name ='Test Service Agreement',Status__c ='Current',Signed_By__c = c.id,  Commencement_Date__c = System.Today(), Activated_Date__c = System.Today(), PlanManager__c = 'MPM');
        insert ser1;
        List<String> serObjIds = new List<String>();
        serObjIds.add(ser.Id);
        List<String> serObjIds1 = new List<String>();
        serObjIds1.add(ser1.Id);
        test.startTest();
        OnBoardingWizardController.fetchServiceAgreement(l.Id, serObjIds);
        OnBoardingWizardController.fetchServiceAgreement(l.Id, serObjIds1);
        test.stopTest();
    }
    
    @istest
    static void testgetFieldsPicklistMethod() {  
        String str = '{"Lead":["Includes_Life_Choices__c"]}';
        test.startTest();
        OnBoardingWizardController.getFieldsPicklistValuesMap(str);
        test.stopTest();
    }
    
    @istest
    static void testIntroToMPMMethod() {  
        test.startTest();
        OnBoardingWizardController.retrieveIntroToMPMCards();
        test.stopTest();
    }

    @istest
    static void testCreateContactWithRelationship() {  
        
        Lead l = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New', PlanManager__c = 'MPM',
                          Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '2000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',
                          Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
                          Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}',
                          Correspondence_Nominee_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Correspondence","LastName":"Nominee","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testCnominee@test.com"}',
                          Support_Coordinator_1_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 1","MiddleName":"Correspondence","LastName":"Support Nominee 1","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnomineeq@test.com"}'
                          /* Support_Coordinator_2_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 2","MiddleName":"Correspondence","LastName":"Support Nominee 2","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee2@test.com"}',
                          Support_Coordinator_3_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 3","MiddleName":"Correspondence","LastName":"Support Nominee 3","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee3@test.com"}',
                          Support_Coordinator_4_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 4","MiddleName":"Correspondence","LastName":"Support Nominee 4","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee4@test.com"}',
                          Support_Coordinator_5_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 5","MiddleName":"Correspondence","LastName":"Support Nominee 5","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnominee5@test.com"}' */
                         );
        insert l;
        Contact c = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com', PlanManager__c = 'MPM');
        insert c;
        Account a = TestClassDataUtil.createClientAccount();
        test.startTest();
        try{
        	//OnBoardingWizardController.createContactWithRelationship(l, a.Id, c.Id);    
        } catch(Exception e) {
            

        }
        
        test.stopTest();
    }    
    
        @istest
    public static void testCreatePlan() {  
        Lead l = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New',Plan_Start_Date__c=Date.today(),Plan_End_Date__c=Date.today().addDays(30), PlanManager__c = 'MPM',
                          Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '2000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',
                          Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
                          Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}',
                          Correspondence_Nominee_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Correspondence","LastName":"Nominee","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testCnominee@test.com"}'
                          //Support_Coordinator_1_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 1","MiddleName":"Correspondence","LastName":"Support Nominee 1","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnomineeq@test.com"}',
                          //Plan_Record_JSON__c = '{"sobjectType":"Plan__c","Budget_Conversation_Milestone_Preference__c":"Client chose not to have Budget Conversation","Budget_Conversation_Declined_Reason__c":"Support Coordinator has explained","Budget_Conversation_Declined_Date_Time__c":"2021-03-03T03:41:45.330Z","Budget_Conversation_Notes__c":"Test"}'
                         );
        insert l;
        Account a = TestClassDataUtil.createClientAccount();        
        test.startTest();
        OnBoardingWizardController.createPlan(l,a.Id);
        test.stopTest();
    } 
    
    @istest
    public static void testServiceBookingRecord() {  
        Lead l = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New',Plan_Start_Date__c=Date.today(),Plan_End_Date__c=Date.today().addDays(30), PlanManager__c = 'MPM',
                          Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '2000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',
                          Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
                          Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}'
                          //Correspondence_Nominee_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Correspondence","LastName":"Nominee","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testCnominee@test.com"}',
                          //Support_Coordinator_1_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Father","Address":"","Relationship_Others__c":null,"Id":"","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test Support Nominee 1","MiddleName":"Correspondence","LastName":"Support Nominee 1","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"testSnomineeq@test.com"}',
                          //Plan_Record_JSON__c = '{"sobjectType":"Plan__c","Budget_Conversation_Milestone_Preference__c":"Client chose not to have Budget Conversation","Budget_Conversation_Declined_Reason__c":"Support Coordinator has explained","Budget_Conversation_Declined_Date_Time__c":"2021-03-03T03:41:45.330Z","Budget_Conversation_Notes__c":"Test"}'
                         );
        insert l;
        Account a = TestClassDataUtil.createClientAccount();       
       	Plan__c p = OnBoardingWizardController.createPlan(l,a.Id);
        Contact con = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com', PlanManager__c = 'MPM');
        insert con;
        AccountContactRelation acr = new AccountContactRelation();
        acr.AccountId = a.id;
        acr.Primary_Contact__c = true;
        acr.IsActive = true;
        acr.Relationship__c = 'Brother';
        acr.ContactId = con.id;
        insert acr;
       Case c = OnBoardingWizardController.createCase(l, a.Id,con.Id);
        
        test.startTest();
        
        //OnBoardingWizardController.createServiceBookingRequestRecord(l,p,a.Id,c);
        test.stopTest();
    } 
    
    @istest
    public static void testCreateServiceAgreementRecordForUploadFiles() {  
        //String serviceJson  = '{"sobjectType":"Service_Agreement__c","Id":"","Name":"Jermy Mingle","Status__c":"Current","Commencement_Date__c":"2020-09-22T11:51:47.098Z","Activated_Date__c":"2020-09-22T11:51:47.098Z","Date_Signed__c":"2020-09-22T11:51:47.098Z","NDIS_Participant__c":null,"Signed_By__r.Name":"","Signed_By__c":"","Service_Agreement_Type__c":"Verbal Acceptance","Verbal_Agreement_Received_by__c":"0054Y000000aKwNQAU","SA_Verbal_Acceptance_Date__c":"2020-09-22T11:49:58.078Z","Service_Agreement_Skip_Reason_Other__c":"","Signed_By__r":{"Name":"Khal Drogo"}';
        Lead l =new Lead();
        l.LeadSource = 'Family';
        l.FirstName = 'Jon';
        l.LastName = 'TestSnow';
        l.Service_Agreement_JSON__c = '{"sobjectType":"Service_Agreement__c","Id":"","Name":"Jimmy Walking Service Agreement","Status__c":"Current","Commencement_Date__c":"2020-09-29T07:48:29.021Z","Activated_Date__c":"2020-09-29T07:48:29.021Z","Date_Signed__c":"2020-09-29T07:48:29.021Z","NDIS_Participant__c":null,"Signed_By__r.Name":"","Signed_By__c":"Jimmy Walking","Service_Agreement_Type__c":"Uploaded File","Verbal_Agreement_Received_by__c":"0054Y000000aKwNQAU","SA_Verbal_Acceptance_Date__c":"2020-09-22T15:18:48.637Z","Service_Agreement_Skip_Reason_Other__c":"","Signed_By__r":{"Name":"Jimmy Walking"},"Lead__c":"00Q4Y000001LeWGUA0","Unable_to_Sign_Reason_Type__c":"Temporary"}';
        insert l;
        Account a = TestClassDataUtil.createClientAccount();   
        Contact c = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com', PlanManager__c = 'MPM');
        insert c;
        test.startTest();
        OnBoardingWizardController.createServiceAgreementRecord(l,a.Id,c.Id);
        test.stopTest();
    } 
    
        @istest
    public static void testCreateServiceAgreementRecordForVerbalAcceptance() {  
        //String serviceJson  = '{"sobjectType":"Service_Agreement__c","Id":"","Name":"Jermy Mingle","Status__c":"Current","Commencement_Date__c":"2020-09-22T11:51:47.098Z","Activated_Date__c":"2020-09-22T11:51:47.098Z","Date_Signed__c":"2020-09-22T11:51:47.098Z","NDIS_Participant__c":null,"Signed_By__r.Name":"","Signed_By__c":"","Service_Agreement_Type__c":"Verbal Acceptance","Verbal_Agreement_Received_by__c":"0054Y000000aKwNQAU","SA_Verbal_Acceptance_Date__c":"2020-09-22T11:49:58.078Z","Service_Agreement_Skip_Reason_Other__c":"","Signed_By__r":{"Name":"Khal Drogo"}';
        Lead l =new Lead();
        l.LeadSource = 'Family';
        l.FirstName = 'Jon';
        l.LastName = 'TestSnow';
        l.Service_Agreement_JSON__c = '{"sobjectType":"Service_Agreement__c","Id":"","Consent_Documented_Method__c":"Primary Decision Maker provided Verbal Consent","Name":"Jimmy Walking Service Agreement","Status__c":"Current","Commencement_Date__c":"2020-09-29T07:48:29.021Z","Activated_Date__c":"2020-09-29T07:48:29.021Z","Date_Signed__c":"2020-09-29T07:48:29.021Z","NDIS_Participant__c":null,"Signed_By__r.Name":"","Signed_By__c":"Jimmy Walking","Service_Agreement_Type__c":"Verbal Acceptance","Verbal_Agreement_Received_by__c":"0054Y000000aKwNQAU","SA_Verbal_Acceptance_Date__c":"2020-09-22T15:18:48.637Z","Service_Agreement_Skip_Reason_Other__c":"","Signed_By__r":{"Name":"Jimmy Walking"},"Lead__c":"00Q4Y000001LeWGUA0","Unable_to_Sign_Reason_Type__c":"Temporary"}';
        insert l;
        Account a = TestClassDataUtil.createClientAccount();   
        Contact c = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com');
        insert c;
        test.startTest();
        OnBoardingWizardController.createServiceAgreementRecord(l,a.Id,c.Id);
        test.stopTest();
    }  
    
    @istest
    public static void testCreateServiceAgreementRecordForVerbalAcceptance2() {  
        //String serviceJson  = '{"sobjectType":"Service_Agreement__c","Id":"","Name":"Jermy Mingle","Status__c":"Current","Commencement_Date__c":"2020-09-22T11:51:47.098Z","Activated_Date__c":"2020-09-22T11:51:47.098Z","Date_Signed__c":"2020-09-22T11:51:47.098Z","NDIS_Participant__c":null,"Signed_By__r.Name":"","Signed_By__c":"","Service_Agreement_Type__c":"Verbal Acceptance","Verbal_Agreement_Received_by__c":"0054Y000000aKwNQAU","SA_Verbal_Acceptance_Date__c":"2020-09-22T11:49:58.078Z","Service_Agreement_Skip_Reason_Other__c":"","Signed_By__r":{"Name":"Khal Drogo"}';
        Lead l =new Lead();
        l.LeadSource = 'Family';
        l.FirstName = 'Jon';
        l.LastName = 'TestSnow';
        l.Service_Agreement_JSON__c = '{"sobjectType":"Service_Agreement__c","Id":"","Consent_Documented_Method__c":"3rd Party evidenced consent","X3rd_Party_evidenced_consent_by__c":"Family Member","X3rd_Party_evidenced_consent_via__c":"Email","X3rd_Party_evidenced_consent_date__c":"2020-09-22T11:51:47.098Z","Name":"Jimmy Walking Service Agreement","Status__c":"Current","Commencement_Date__c":"2020-09-29T07:48:29.021Z","Activated_Date__c":"2020-09-29T07:48:29.021Z","Date_Signed__c":"2020-09-29T07:48:29.021Z","NDIS_Participant__c":null,"Signed_By__r.Name":"","Signed_By__c":"Jimmy Walking","Service_Agreement_Type__c":"Verbal Acceptance","Verbal_Agreement_Received_by__c":"0054Y000000aKwNQAU","SA_Verbal_Acceptance_Date__c":"2020-09-22T15:18:48.637Z","Service_Agreement_Skip_Reason_Other__c":"","Signed_By__r":{"Name":"Jimmy Walking"},"Lead__c":"00Q4Y000001LeWGUA0","Unable_to_Sign_Reason_Type__c":"Temporary"}';
        insert l;
        Account a = TestClassDataUtil.createClientAccount();   
        Contact c = new Contact(FirstName = 'Sonali', LastName = 'test',MiddleName = 'Test',MailingStreet= 'Test Street',MailingCity= 'Test City',MailingState = 'SA' ,MailingPostalCode = '140007',MailingCountry= 'Australia',Email = 'sonali@example.com');
        insert c;
        test.startTest();
        OnBoardingWizardController.createServiceAgreementRecord(l,a.Id,c.Id);
        test.stopTest();
    } 
    
  /*@istest
    public static void testSearchForNDIS() {  
        test.startTest();
        OnBoardingWizardController.searchForNDIS('Plan','430193319',Date.today());
        test.stopTest();
    } */
    
    @istest
    public static void testUploadFiles() {  
        Lead l =new Lead();
        l.LeadSource = 'Family';
        l.FirstName = 'Jon';
        l.LastName = 'TestSnow';
        insert l;
        
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
        OnBoardingWizardController.updateFiles(cvList[0].ContentDocumentId,'Family Jon Service Agreement',l.Id);
        test.stopTest();
    } 
    
    @istest
    public static void testSendSMSviaTwilio() {
        
        Test.startTest();
        Lead l =new Lead();
        l.LeadSource = 'Family';
        l.FirstName = 'Jon';
        l.LastName = 'TestSnow';
        insert l;
        
        OnBoardingWizardController.updateSMSRecordOnLead(l);
        
        MPM_URLs__c MPMurl = new MPM_URLs__c();
        MPMurl.MPM_Click_to_Accept_URL__c = 'https://testapi/';
        insert MPMurl;
        //OnBoardingWizardController.sendSMSviaTwilio(l.Id,'+15005550008','Test User');
        OnBoardingWizardController con = new OnBoardingWizardController();
        
        HttpResponse response = new HttpResponse();
        response.setBody('Mock response body');
        //response.setStatusCode(201);
        Continuation conti = (Continuation)OnBoardingWizardController.sendSMSviaTwilio(l.Id,'+15005550008','Test User');
        // Set the fake response for the continuation     
        Test.setContinuationResponse('continuation-1', response);
        // Invoke callback method
        try {
            Object result = Test.invokeContinuationMethod(OnBoardingWizardController.getTwilioRequest(new List<String>{'continuation-1'}, con), conti);    
            system.assert(result!=null);
        } Catch(Exception e) {
            
        }
        Test.stopTest();   
    }
    
    /**
    * @author: Yash Bhalerao
	* @company: Cloudwerx
    * @description : Test method to cover insertTask method
    * @param   :   ``
    * @return  :   ``
    * @ticket  :  [CS-105]
    **/
    @isTest
    public static void insertTaskTest() {
        Lead l = new Lead();
        l.LastName = 'Test';
        l.FirstName = 'New';
        l.LeadSource = 'Test';
        insert l;
        
        string mobileNumber = '1234567890';
        string messageBody = 'Test';
        
        Test.startTest();
        OnBoardingWizardController.insertTask(l.Id, mobileNumber, messageBody);
        Test.stopTest();
    }
    
        /**
    * @author: Akshay Waikar
	* @company: Cloudwerx
    * @description : Test method to cover checkUserIsAssignedToPermissionSet method
    * @ticket  :  [SFDC-1235]
    **/
    @isTest
    public static void testcheckUserIsAssignedToPermissionSet() {
        Test.startTest();
        OnBoardingWizardController.checkUserIsAssignedToPermissionSet();
        Test.stopTest();
    }

    /**
    * @description Test method for showBudgetSection.
    * @Author: Cloudwerx   
    * @Ticket:[SFDC-1276]
    **/
    @IsTest
    static void testShowBudgetSection(){
        List <Pod__c> listOfPodsToInsert = new List <Pod__c>();
        listOfPodsToInsert.add(new Pod__c(Name='NSW North & East', Pod_Skill_New__c='ADL Central + SA North + NT', PlanManager__c = 'MPM'));
        listOfPodsToInsert.add(new Pod__c(Name='NSW Central', Pod_Skill_New__c='NSW Central', PlanManager__c = 'MPM'));
        listOfPodsToInsert.add(new Pod__c(Name='Queensland', Pod_Skill_New__c='Queensland', PlanManager__c = 'MPM'));
        insert listOfPodsToInsert;
        List<Pod_Territory__c> podTerritoryList = new List<Pod_Territory__c>();
        podTerritoryList.add(new Pod_Territory__c(Pod__c = listOfPodsToInsert[2].Id, StartingPostCode__c= 4000, EndingPostCode__c = 4999, PlanManager__c = 'MPM'));
        podTerritoryList.add(new Pod_Territory__c(Pod__c = listOfPodsToInsert[0].Id, StartingPostCode__c= 2000, EndingPostCode__c = 2000, PlanManager__c = 'MPM'));
        insert podTerritoryList;
        List<Lead> leadList = new List<Lead>();
        Lead leadObjectToHideSection = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New',Plan_Start_Date__c=Date.today(),Plan_End_Date__c=Date.today().addDays(30),
                                                Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '1000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',PlanManager__c = 'MPM',
                                                Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
                                                Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}'
                                                );
        leadList.add(leadObjectToHideSection);
        Lead leadObjectToShowSection = new Lead(LeadSource = 'Family', FirstName = 'Jon', LastName = 'TestSnow', Contact_First_Name__c = 'Jon', Contact_Last_Name__c = 'TestSnowCon', Email = 'test@test.com', Contact_Relationship__c = 'Father', Date_of_Birth__c = Date.today(), Contact_Phone_Number__c = '0433893333', Contact_Alternate_Phone_Number__c = '0499999988', Status = 'New',Plan_Start_Date__c=Date.today(),Plan_End_Date__c=Date.today().addDays(30),
                                                Accessibility_Requirements__c = 'Interpreter',Street ='Test Street', City = 'Test City', State = 'SA',Country = 'Australia',PostalCode = '4000', Client_Discovery_Notes__c = 'Test Notes',Communication_Preferences__c = 'Email',NDIS__c = '431231232',PlanManager__c = 'MPM',
                                                Primary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Ms.","FirstName":"Sonali","MiddleName":"Test","LastName":"Bhat","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"test@test.com"})',
                                                Secondary_Decision_Maker_JSON__c = '{"sobjectType":"Contact","Title":"","Name":"","MobilePhone":"","Phone":"","Relationship__c":"Brother","Address":"","Relationship_Others__c":null,"Id":"","Mailingcountry":"Australia","Communication_Preferences__c":"Email","Salutation":"Mr.","FirstName":"Test","MiddleName":"Secondary","LastName":"Maker","Mailingstreet":"test","Mailingcity":"test city","Mailingstate":"ACT","MailingpostalCode":"3000","Email":"secondarymaker@test.com"}'
                                                );
        leadList.add(leadObjectToShowSection);
        insert leadList;
        Test.startTest();
        boolean resultToHideSection = OnBoardingWizardController.showBudgetSection(leadObjectToHideSection);
        boolean resultToShowSection = OnBoardingWizardController.showBudgetSection(leadObjectToShowSection);
        Test.stopTest();
        //System.assertEquals(false, resultToHideSection, 'returned true for non pod names'); Sprint 25-[SFDC-1431] Commented for all milestone pods release.
        System.assertEquals(true, resultToShowSection, 'returned false for pod names');      
    }
}