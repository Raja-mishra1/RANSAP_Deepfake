/**
* Class Name: OnBoardingWizardController
* Description: Controller for Onboaring Wizard Lightning Component
* Created By: Cloudwerx
* Created Date: 12/08/2020
*/

/*  @Modified Date : 20/04/2021
    @Modified By : Yash Bhalerao
	@Modification : Added insertTask method to log activity for SMS CTA
    @Ticket : [CS-105]
*/
public class OnBoardingWizardController {
    
    /*Called at initialize to get the current values of Lead*/
    @AuraEnabled
    public static Lead retrieveLeadRecord(Id leadId){
        //Relationship-Sprint-9/SFDC-1063 Start
        //Relationship-Sprint-10/RPA/SFDC-1123 Start
        //TTP-Sprint-10/Swapnil/TTP-122
        return [SELECT Accessibility_Requirements__c,CreatedDate, Company, Service_Agreement_JSON__c, Address, City, Start_Time__c, Client_Discovery_Notes__c, Communication_Preferences__c, Contact_Phone_Number__c, Contact_Alternate_Phone_Number__c,
                Correspondence_Nominee_JSON__c,Correspondence_Nominee__c, Country, Cultural_Needs__c, Current_Step__c,Contact_First_Name__c, Contact_Middle_Name__c, Contact_Last_Name__c, Contact_Relationship__c, Contact_Relationship_Others__c, Date_of_Birth__c, Declined_Reason__c,
                Disability_Type__c, Email, End_Time__c,  FirstName, First_Plan__c, id,Is_Primary_Contact__c, Language__c, LastName, LeadSource, Lead_Source_Other__c, Living_Arrangements__c, MiddleName, MobilePhone, Name, NDIS__c, Notes_for_Relationships_Consultant__c, No_Contact_Details__c, Other_Language__c, 
                Other_Cultural_Needs__c, Other_Declined_Reason__c ,Manually_Resolved_Exception__c,Other_Living_Arrangement__c, Phone, PostalCode, Plan_Start_Date__c, Plan_End_Date__c, Preferred_MPM_Products__c, Previous_Plan_Management__c, Primary_Decision_Maker_JSON__c, Provider__c,Plan_Record_JSON__c, Reason_for_leaving_MPM__c, Referred_By__c, Other_Reason_for_Leaving__c,  
                ModifiedMonashModelScore__c, Sa1CodeMain__c, Sa2CodeMain__c, Sa2Name__c, Sa3Code__c, Sa3Name__c, Sa4Code__c, Sa4Name__c, Secondary_Decision_Maker_JSON__c, Service_Agreement_Skip_Reason_Other__c, State, Street,Includes_Life_Choices__c, Support_Coordinator_1_JSON__c, Service_Agreement_Skip_Reason__c,Gender__c,PreferredName__c,
                PlanManagedByAnotherPlanManager__c,Title,Salutation, Primary_Decision_Maker__c, Secondary_Decision_Maker__c,Standard_Service_Booking_Status__c,Service_Booking_Exception_Description__c, PRODA_Plan_Id__c,PlanManager__c,//TTP-1635
                (SELECT Id,Service_Agreement_Type__c,Status__c,Consent_Documented_Method__c,X3rd_Party_evidenced_consent_by__c,X3rd_Party_evidenced_consent_date__c,X3rd_Party_evidenced_consent_via__c,Unable_to_Sign_Reason__c,Unable_to_Sign_Reason_Type__c FROM Service_Agreements__r)
                FROM Lead WHERE Id =: leadId];
        //Relationship-Sprint-10/RPA/SFDC-1123 End
        //Relationship-Sprint-9/SFDC-1063 End
    }
    
    /*Fetch Custom Metadata to display in IntoToMPM component*/
    @AuraEnabled
    public static List<Onboard_Wizard_Configuration__mdt> retrieveIntroToMPMCards(){
        return [SELECT Content__c,Header__c,Order__c,Screen_Name__c FROM Onboard_Wizard_Configuration__mdt ORDER BY Order__c];
    }
    
    /*Get picklist value*/
    @AuraEnabled(cacheable=true)
    public static Map <String,Map<String, List<ReconnectionsUtil.PicklistValuesWrapper>>> getFieldsPicklistValuesMap(String json)
    {
        return ReconnectionsUtil.getFieldsPicklistValuesMap(json); 
    }
    
    /*Method to save lead record*/
    @AuraEnabled
    public static Lead saveLead(Lead leadRecord){
        if(leadRecord != null) {
            upsert leadRecord;
        }
        return leadRecord;
    }
        
    //Sprint-5 [BT-578] changes start.
    /*Method to save Start and End Time and service agreement signed flag on lead record*/ 
    @AuraEnabled
    public static Lead setLeadRecordAttributes(Id leadRecordId, String labelString){
        Lead leadObject = new Lead();
        leadObject.Id = leadRecordId;
        if(labelString == 'Start time') {
            leadObject.Start_Time__c  = System.now();
        }
        if(labelString == 'End time') {
            leadObject.End_Time__c  = System.now();
        }
        
        if(leadObject != null) {
            upsert leadObject; 
        }
        return leadObject;
    } 
    //Sprint-5 [BT-578] changes ends.
    
    /*Method to send service agreement*/
    @AuraEnabled
    public static String sendClickToAcceptLead(Id recordId, String email) {
        Lead lead = new Lead();
        lead.Id = recordId;
         //Sprint-6 [BT-392] start
        lead.Click_to_Accept_Identifier__c = ReconnectionsUtil.generateHashKey();
         //Sprint-6 [BT-392] end
        lead.Click_to_Accept_Identifier_Generated_At__c = DateTime.now();

        update lead;

        EmailTemplate clickToAcceptTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Click_to_Accept'];
        MPM_Email_Addresses__c mpmEmails = MPM_Email_Addresses__c.getOrgDefaults();
        String WELCOME_EMAIL = mpmEmails.Welcome__c;
        OrgWideEmailAddress welcomeOrgWideEmailAddress;
        
        if(Test.IsRunningTest()){
            welcomeOrgWideEmailAddress = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        }
        else{
            welcomeOrgWideEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: WELCOME_EMAIL];
        }

        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();

        emailMessage.setTemplateId(clickToAcceptTemplate.Id);
        emailMessage.setTargetObjectId(recordId);
        emailMessage.setToAddresses(new List<String> { email });
        emailMessage.setTreatTargetObjectAsRecipient(false);
        emailMessage.setOrgWideEmailAddressId(welcomeOrgWideEmailAddress.Id);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { emailMessage });

        return 'Click to accept sent successfully';
    }
    //Relationships-Sprint-12/Akshay/SFDC-1153,SFDC-1156
    
   
    /*Method is fired by 4th step to track if any Service Agreement is created after validation*/
    @AuraEnabled
    public static String fetchServiceAgreement(Id recordId, List <String> serviceAgreementIds){
        List <Service_Agreement__c> listServiceAgreement = [SELECT Id FROM Service_Agreement__c WHERE Lead__c =:  recordId AND Id IN: serviceAgreementIds AND Service_Agreement_Type__c = 'Email - Click to Accept'];
        if(!listServiceAgreement.IsEmpty()){
            return 'found';
        }       
        else{
            return 'notfound';
        }
    }
    
    /*Method is used to get logged in user details for service agreement*/
    @AuraEnabled
    public static User fetchloggedInUser(){
        User u = [select Id,FirstName from user where id=:userinfo.getuserid()];
        return u;
    }
    
    @AuraEnabled
    public static Boolean verifyNDISExists(String ndisVar,String leadId, String leadPlanManager){
        boolean ndisExists = false;
        List <Lead> listLead = new List <Lead>();
        listLead = [SELECT  Id, NDIS__c,PlanManager__c  FROM Lead WHERE NDIS__c =: ndisVar AND Id != :leadId Limit 50000]; //ACEM-2 added query limit
        //if((!listLead.IsEmpty() && listLead.size() != 1) || (listLead.size() == 1 && listLead[0].Id != leadId)){
        if(!listLead.IsEmpty()){
            ndisExists = true;
        } 
        List <Account> listAccount = new List <Account>();
        listAccount = [SELECT  Id, NDIS__c   FROM Account WHERE NDIS__c =: ndisVar AND PlanManager__c =: leadPlanManager Limit 50000]; //ACEM-2 added query limit
        if (!listLead.IsEmpty()) { //listLead.size() != 1
            ndisExists = true;
        }
        return ndisExists;
    }
    
   
    /*This method is executed on Submit button which convert leads */
    @AuraEnabled
    public static OnBoardingWizardController.WrapperExecuteLead executeLeadConversion(Lead leadRecord){
        Savepoint sp;
        OnBoardingWizardController.WrapperExecuteLead objWrap = new OnBoardingWizardController.WrapperExecuteLead();
        try{
            sp = Database.setSavepoint();
            setLeadRecordAttributes(leadRecord.Id,'End time'); //Sprint-5 [BT-578]. 
            //Sprint 5 - BT-579
            List <Service_Agreement__c> serviceAgreementList =[SELECT id,name,Service_Agreement_Type__c FROM Service_Agreement__c WHERE Lead__r.Id =: leadRecord.Id AND Service_Agreement_Type__c = 'Email - Click to Accept' ];
            Database.LeadConvert leadConvert = new database.LeadConvert();
            leadConvert.setLeadId(leadRecord.Id);
            leadConvert.setDoNotCreateOpportunity(true);
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
            leadConvert.setConvertedStatus(convertStatus.MasterLabel);
            leadConvert.setOwnerId(UserInfo.getUserId());
            Database.LeadConvertResult leadConvertedResult = Database.convertLead(leadConvert); 
            Id contactId = leadConvertedResult.getContactId(); 
            Id accountId = leadConvertedResult.getAccountId();
            Id primaryContactId = createContactWithRelationship(leadRecord, accountId, contactId); //this might be the duplciate call
            if(primaryContactId == null){
                //primaryContactId = [SELECT Id, ContactId FROM AccountContactRelation WHERE AccountId =: accountId][0].ContactId;
                list<AccountContactRelation> aclist = [SELECT Id, ContactId FROM AccountContactRelation WHERE AccountId =: accountId];
                if(aclist.IsEmpty()){
                    primaryContactId = null;
                } else {
                    primaryContactId = aclist[0].ContactId;
                }
                
            }
            //mapAccountContactFields(contactId, accountId, leadRecord);

            //[Sprint-8] BT-689 Start
            String primaryContactName = [Select Name From Contact where Id = :primaryContactId][0].Name;
            //[Sprint-8] BT-689 End
            if (!serviceAgreementList.isEmpty()) {
                serviceAgreementList[0].Signed_By__c = primaryContactName;
                update serviceAgreementList;
            }

            if (leadRecord.Service_Agreement_JSON__c != '' && leadRecord.Service_Agreement_JSON__c != 'undefined' && leadRecord.Service_Agreement_JSON__c != null) {
                Map<String, Object> serviceAgreementRecord = (Map<String, Object>) JSON.deserializeUntyped(leadRecord.Service_Agreement_JSON__c);
                if ((String) serviceAgreementRecord.get('Service_Agreement_Type__c') == 'Verbal Acceptance' || (String) serviceAgreementRecord.get('Service_Agreement_Type__c') == 'Gestured Consent' || (String) serviceAgreementRecord.get('Service_Agreement_Type__c') == 'Uploaded File') {
                    createServiceAgreementRecord(leadRecord,accountId,primaryContactName); //To create service agreement [Sprint-8] BT-689 - Send PrimaryContactName for Signed By field
                }                
            }
            
            //Relationship-Sprint-9/SFDC-1063 Start
            Plan__c planRecord = createPlan(leadRecord,accountId);
            //Relationship-Sprint-9/SFDC-1063 End
            
            Case caseRecord = createCase(leadRecord,accountId,primaryContactId);
            
            //Relationship-Sprint-9/SFDC-1063 Start
            createServiceBookingRequestRecord(leadRecord,planRecord,accountId,caseRecord);
            //Relationship-Sprint-9/SFDC-1063 End
            
            objWrap.accountId = accountId;
            objWrap.caseId = caseRecord.Id;
            objWrap.message = 'Converted';
            return objWrap;
        }
        catch(Exception e){
            Database.rollback(sp);
            objWrap.message =e.getMessage();
            return objWrap;
            //return e.getMessage();
        }        
    }
    
    /* @AuraEnabled
    public static NDISRestHelper.Result searchForNDIS(String lastname, String ndisNumber, Date dateOfBirth){
        NDISRestHelper.Result result = NDISRestHelper.searchForNDIS(lastname, ndisNumber, dateOfBirth);
        return result;
    } */
   
    //Wrapper Class
    public class WrapperExecuteLead {
        @AuraEnabled public String accountId{get;set;}
        @AuraEnabled public String caseId{get;set;}
        @AuraEnabled public String message{get;set;}
    }

    // Method to create Case on Lead Conversion
    public static Case createCase(Lead lead, Id accountId, Id contactId) {
        String generalCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId();
        Account acc = [Select Id, FirstName, LastName FROM Account WHERE Id =:accountId];
        Case caseObj = new Case();
        caseObj.Subject = acc.FirstName + ' ' + acc.LastName + ' ' +'New Client Setup';
        caseObj.Status = 'New'; 
        caseObj.Client__c = acc.id;
        caseObj.Type = 'Client Setup/Admin';
        caseObj.Sub_Type__c = 'Client Onboarding';
        caseObj.PlanManager__c = lead.PlanManager__c; //NAP5-17
        if(lead.CreatedDate != null) {
            caseObj.Lead_Created_Date__c = (lead.CreatedDate).date(); 
        }
        caseObj.Origin = 'Auto Generated';
        caseObj.RecordTypeId = generalCaseRecordTypeId;
        caseObj.ContactId = contactId;
        try{
            insert caseObj;
        } catch(Exception ex) {
            System.debug('Case cannot be created' +ex);
        }
        return caseObj;
    }

    /*This method fetches Lead mapping custom metadata & maps fields on Account & Contact*/
    public static void mapAccountContactFields(Id contactId, Id accountId, Lead leadRecord){
        Account accountRecord = new Account();
        accountRecord.Id = accountId;

        //Sprint 5 - BT-576
        accountRecord.Status__c = 'Active';

        accountRecord.Cultural_Needs__c = leadRecord.Cultural_Needs__c  == 'Yes' ? True : False;
        update accountRecord;
        
    }
    
    /*Method to create Contact & Account Contact relationship*/
    public static Id createContactWithRelationship(Lead leadRecord, Id accountId, Id contactId){
        Id primaryContactId;
        if(leadRecord.Primary_Decision_Maker_JSON__c != null && leadRecord.Primary_Decision_Maker_JSON__c != ''){
            primaryContactId = createContactandAccountContactRelation(leadRecord.Primary_Decision_Maker_JSON__c, accountId, 'Primary Decision Maker', leadRecord.PlanManager__c);
        }
        if(leadRecord.Secondary_Decision_Maker_JSON__c != null && leadRecord.Secondary_Decision_Maker_JSON__c != ''){
            createContactandAccountContactRelation(leadRecord.Secondary_Decision_Maker_JSON__c, accountId,'Secondary Decision Maker', leadRecord.PlanManager__c);
        }
        if(leadRecord.Correspondence_Nominee_JSON__c != null && leadRecord.Correspondence_Nominee_JSON__c != ''){
            createContactandAccountContactRelation(leadRecord.Correspondence_Nominee_JSON__c, accountId, 'Correspondence Nominee', leadRecord.PlanManager__c);
        }
        if(leadRecord.Support_Coordinator_1_JSON__c != null && leadRecord.Support_Coordinator_1_JSON__c != ''){
            createContactandAccountContactRelation(leadRecord.Support_Coordinator_1_JSON__c , accountId, 'Support Coordinator', leadRecord.PlanManager__c);
        }
        return primaryContactId;
    }
    
    public static Id createContactandAccountContactRelation(String jsonString, Id accountId, String contactType, String planManager){
        Contact newContact = (Contact)JSON.deserialize(jsonString, Contact.class);
        if(newContact.LastName != null && newContact.LastName != ''){
            newContact = wrapContact(newContact, planManager);
            Database.UpsertResult saveResult = Database.upsert(newContact, false);
            
            for (Database.Error error : saveResult.getErrors()) {
                if (error instanceof Database.DuplicateError) {
                    Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                    Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                    
                    List<sObject> duplicateRecords = new List<sObject>();
                    Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                    Datacloud.MatchResult matchResult = matchResults[0];
                    Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();
                    sObject contactRecord = matchRecords[0].getRecord();
                    
                    String errorMessage = 'Duplicate Error! You' +  '\'' +'re creating a duplicate record with Name '+  '\'' +contactRecord.get('Name')+  '\'' + ' as '+contactType;
                    throw new OnboardingException(errorMessage); 
                }
            }
            
            AccountContactRelation accountContactRelationRecord = (AccountContactRelation)JSON.deserialize(jsonString, AccountContactRelation.class);
            accountContactRelationRecord.Id = null;
            accountContactRelationRecord.AccountId = accountId;
            accountContactRelationRecord.ContactId = newContact.Id;
            insert accountContactRelationRecord;
        }
        return newContact.Id;
    }
    
    public static List <sObject> populateLookup(List <sObject> listOfsObject, Id accountId){
        if(!listOfsObject.IsEmpty()){
            for(sObject sobj : listOfsObject){
                sobj.put('NDIS_Participant__c',accountId);
            }
        }
        return listOfsObject;
    }
    
    
    public static Contact wrapContact(Contact con, String planManager){
        Contact newContact = new Contact();
        if(!String.IsBlank(con.Id)){
            newContact.Id = String.valueOf(con.Id);
        }
        newContact.Salutation = con.Salutation;
        newContact.FirstName = con.FirstName;
        newContact.LastName = con.LastName;
        newContact.MiddleName = con.MiddleName ;
        newContact.MailingStreet = con.MailingStreet ;
        newContact.MailingCity = con.MailingCity;
        newContact.MailingState = con.MailingState;
        newContact.MailingPostalCode = con.MailingPostalCode;
        newContact.MailingCountry = con.MailingCountry;
        newContact.MobilePhone = con.MobilePhone;
        newContact.Email = con.Email;
        newContact.Phone= con.Phone;
        newContact.Communication_Preferences__c = con.Communication_Preferences__c;
        if(!String.IsBlank(con.AccountId)){
            newContact.AccountId  = String.valueOf(con.AccountId);
        }
        newContact.PlanManager__c = planManager;
        return newContact;
    }
    
    public class OnboardingException extends Exception {} 
    
    /*This method is used to check if duplicate contact exsist using duplicate rules */
    @AuraEnabled
    public static List<Contact> findContacts(String FirstName,String LastName, String emailVar,String mobileVar,String phoneVar) {

        List<Contact> cons = new List<Contact>();
        Contact c = new Contact();
        c.FirstName = FirstName;
        c.LastName = LastName;
        c.Email = emailVar;
        c.MobilePhone = mobileVar;
        c.Phone = phoneVar;
        cons.add(c);

        List<Contact> foundContacts = new List<Contact>();
        List<Datacloud.FindDuplicatesResult> results;
        
        try {
            results = Datacloud.FindDuplicates.findDuplicates(cons);
        } catch (Exception ex) {
            // FYI if there are no active rules for an object, then the exception is
            // System.HandledException: No active duplicate rules are defined for the [objname] object type
            return null;
        }
        
        // Loop the original contacts
        for (Integer i = 0; i < cons.size(); i++) {
            Contact foundCon = null;
            // Find the first duplicate result with a match result, then use the first match record.
            for (Datacloud.DuplicateResult dr : results[i].getDuplicateResults()) {
                if(dr.getDuplicateRule() == System.Label.Onboard_Wizard_Configuration_Contact_Duplicate_Rule) { //Contact_Duplicate_Rule
                    if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() > 0) {
                        foundCon = (Contact) dr.getMatchResults()[0].getMatchRecords()[0].getRecord();
                        break;
                    }
                }

            }
            foundContacts.add(foundCon);
        }
        return foundContacts;
    }

       
    public static void createServiceAgreementRecord(lead leadRecord,Id accountId, String contactName) {
        Map<String, Object> serviceAgreementRecord = (Map<String, Object>) JSON.deserializeUntyped(leadRecord.Service_Agreement_JSON__c);
        Service_Agreement__c SA = new Service_Agreement__c();

        //Getting date formate.
        Date formattedCommencementDate = Date.valueOf(String.ValueOf(serviceAgreementRecord.get('Commencement_Date__c')));
        Date formattedActivatedDate = Date.valueOf(String.ValueOf(serviceAgreementRecord.get('Activated_Date__c')));
        Date formattedDateSigned = Date.valueOf(String.ValueOf(serviceAgreementRecord.get('Date_Signed__c')));
        String serviceAgreementTypeValue = (String) serviceAgreementRecord.get('Service_Agreement_Type__c');
        String consentDocMethod = (String)serviceAgreementRecord.get('Consent_Documented_Method__c');
        String signReasonType = (String) serviceAgreementRecord.get('Unable_to_Sign_Reason_Type__c');
        
        if (consentDocMethod == System.Label.VerbalConsent) {
            Map<String, Object> getContactMap = (Map<String, Object>)serviceAgreementRecord.get('Signed_By__r');
            Date formattedSAVerbalAcceptanceDate = Date.valueOf(String.ValueOf(serviceAgreementRecord.get('SA_Verbal_Acceptance_Date__c')));
            SA.Verbal_Agreement_Received_by__c = (String) serviceAgreementRecord.get('Verbal_Agreement_Received_by__c');
            SA.SA_Verbal_Acceptance_Date__c = formattedSAVerbalAcceptanceDate;
            SA.Unable_to_Sign_Reason__c = (String) serviceAgreementRecord.get('Unable_to_Sign_Reason__c');
            SA.Unable_to_Sign_Reason_Type__c = (String) serviceAgreementRecord.get('Unable_to_Sign_Reason_Type__c');
            SA.Consent_Documented_Method__c = (String)serviceAgreementRecord.get('Consent_Documented_Method__c');
            
            //Fetching contact id
            List<Contact> contactList = [Select id, Name from contact where Name like :(String)getContactMap.get('Name') Limit 50000]; //ACEM-2 added query limit
            
            if(!contactList.IsEmpty()) {
                //if(contactList[0].Id != '' && contactList[0].Id != null) {
                SA.Signed_By__c = contactList[0].Name;
                //}    
            }

        } else if(consentDocMethod == System.Label.ThirdPartyConsent) {
            SA.Unable_to_Sign_Reason_Type__c = (String) serviceAgreementRecord.get('Unable_to_Sign_Reason_Type__c');
            SA.Unable_to_Sign_Reason__c = (String) serviceAgreementRecord.get('Unable_to_Sign_Reason__c');
            SA.Consent_Documented_Method__c = (String)serviceAgreementRecord.get('Consent_Documented_Method__c');
            SA.X3rd_Party_evidenced_consent_by__c = (String) serviceAgreementRecord.get('X3rd_Party_evidenced_consent_by__c');
            SA.X3rd_Party_evidenced_consent_via__c = (String) serviceAgreementRecord.get('X3rd_Party_evidenced_consent_via__c');
            SA.X3rd_Party_evidenced_consent_date__c = Date.valueOf(String.ValueOf(serviceAgreementRecord.get('X3rd_Party_evidenced_consent_date__c')));
            SA.Signed_By__c = contactName; 
        } else {
            SA.Unable_to_Sign_Reason_Type__c = (String) serviceAgreementRecord.get('Unable_to_Sign_Reason_Type__c');
            SA.Unable_to_Sign_Reason__c = (String) serviceAgreementRecord.get('Unable_to_Sign_Reason__c');
            SA.Consent_Documented_Method__c = (String)serviceAgreementRecord.get('Consent_Documented_Method__c');
            SA.Signed_By__c = contactName; 
        }
        
        if ((String) serviceAgreementRecord.get('Service_Agreement_Type__c') == 'Uploaded File') {
            SA.Signed_By__c = contactName;            
        }
        
        SA.Lead__c = leadRecord.Id;
        SA.Name = (String)serviceAgreementRecord.get('Name'); //Mandatory field
        SA.Status__c = (String)serviceAgreementRecord.get('Status__c'); //Mandatory field
        SA.Commencement_Date__c = formattedCommencementDate; //Mandatory field
        SA.Activated_Date__c = formattedActivatedDate; //Mandatory field
        SA.Date_Signed__c = formattedDateSigned; //Mandatory field
        SA.NDIS_Participant__c = accountId; 
        SA.Service_Agreement_Type__c = (String) serviceAgreementRecord.get('Service_Agreement_Type__c');
        SA.PlanManager__c = leadRecord.PlanManager__c;
        
        try {
            upsert SA;    
            
            if (signReasonType == 'Temporary') {  // Create Task for Temporary Value
                //Creating task
                //pass the account owner
                Account acc = [Select Id, OwnerId FROM Account WHERE Id =: accountId];
                Date myDate = Date.today();
                myDate = myDate.addDays(30);
                ReconnectionsUtil.createTask('Follow up with Client about Service Agreement',myDate,'Open','Normal',acc.OwnerId,accountId);
            }
            
            if (serviceAgreementTypeValue == 'Uploaded File') {
                //update the document from lead 
                updateServiceAgreementDocument(leadRecord,SA.Id,'Service Agreement');
            }
            
        } catch(Exception e) {
            system.debug('Exception is :'+e.getMessage());  
        }        
    }
    
    //method to transfer the latest SA document from lead to new SA
    public static void updateServiceAgreementDocument(lead leadRecord,Id entityId,String entityType) {   
        String extraFilter = '';
        
        String query = 'SELECT id,LinkedEntityId,ContentDocumentId,ShareType FROM ContentDocumentLink ';
        
        if (entityType == 'Plan Document') {
            extraFilter = ' AND ContentDocument.Title LIKE \'%Plan Document%\'';
        } else if (entityType == 'Service Agreement') {
            extraFilter = ' AND ContentDocument.Title LIKE \'%Service Agreement%\'';
        }
        query += ' WHERE LinkedEntityId = \''+ leadRecord.Id + '\'' + extraFilter + ' ORDER BY ContentDocument.CreatedDate DESC LIMIT 1';
        
        List<ContentDocumentLink> cdLink= Database.query(query);  
        ContentDocumentLink createContentDocument = New ContentDocumentLink();
        if(!cdLink.IsEmpty()) {      
            createContentDocument.LinkedEntityId = entityId; //Plan Id
            createContentDocument.ContentDocumentId = cdLink[0].ContentDocumentId; 
            createContentDocument.shareType = 'V';
        }

        try {
            if(createContentDocument != null) {
                insert createContentDocument;    
            }
            
            //delete cdl[0];  
        } catch(Exception e) {
          system.debug('Exception is :'+e.getMessage());  
        }        
    }
    
    //Relationship/Sprint-6/[SFDC-832] 
    //Relationship-Sprint-9/SFDC-1063 Start
    public static Plan__c createPlan(Lead leadRecord,Id accountId) {
        //local attributes
        String budgetConversationMilestonePreference;
        String budgetConversationDeclineReason;
        DateTime budgetConversationDeclineDateTime;
        String budgetConversationNotes;
        
        if(leadRecord.Plan_Record_JSON__c != null) {
            //Fetching fields from json
            Map<String, Object> planRecord = (Map<String, Object>) JSON.deserializeUntyped(leadRecord.Plan_Record_JSON__c);
            budgetConversationMilestonePreference = (String) planRecord.get('Budget_Conversation_Milestone_Preference__c');
            
            if(planRecord.get('Budget_Conversation_Declined_Reason__c') != null) {
                budgetConversationDeclineReason = (String) planRecord.get('Budget_Conversation_Declined_Reason__c');
            }
            
            if(planRecord.get('Budget_Conversation_Declined_Date_Time__c') != null) {
               	String dateTimeString = (String) planRecord.get('Budget_Conversation_Declined_Date_Time__c');                
                budgetConversationDeclineDateTime = DateTime.ValueofGmt(dateTimeString.replace('T', ' '));
            }
            
            if(planRecord.get('Budget_Conversation_Notes__c') != null) {
                budgetConversationNotes = (String) planRecord.get('Budget_Conversation_Notes__c');
            }
        }

        //Updating budget conversation fields on Account
        Account a = new Account();
        a.Id = accountId;
        a.Budget_Conversation_Milestone_Preference__c = budgetConversationMilestonePreference;
        
        if(budgetConversationDeclineReason != null) {
            a.Budget_Conversation_Declined_Reason__c = budgetConversationDeclineReason;
        }
        
        if(budgetConversationDeclineDateTime != null) {
            a.Budget_Conversation_Declined_Date_Time__c = budgetConversationDeclineDateTime;
        }
        
        if(budgetConversationNotes != null) {
            a.Budget_Conversation_Notes__c = budgetConversationNotes;
        }
        
        
        if(a != null) {
            update a;               
        }
        
        Plan__c p =new Plan__c();
        if(leadRecord.Plan_Start_Date__c != null && leadRecord.Plan_End_Date__c != null) {
            
            p.Client_Name__c = accountId;
            p.Name = 'Client Plan -'+' '+leadRecord.Name;
            p.Plan_Start_Date__c =leadRecord.Plan_Start_Date__c;
            p.Plan_End_Date__c = leadRecord.Plan_End_Date__c;
            p.Actual_Plan_End_Date__c = leadRecord.Plan_End_Date__c;
            p.Budget_Conversation_Milestone_Preference__c = budgetConversationMilestonePreference;
            p.PRODA_Plan_Id__c = leadRecord.PRODA_Plan_Id__c;//TTP-1635
            p.PlanManager__c = leadRecord.PlanManager__c; //NAP5-17
            p.PlanManagedByAnotherPlanManager__c = leadRecord.PlanManagedByAnotherPlanManager__c; // TTP-3769
            
            if(budgetConversationDeclineReason != null) {
                p.Budget_Conversation_Declined_Reason__c = budgetConversationDeclineReason;
            }
            
            if(budgetConversationDeclineDateTime != null) {
               p.Budget_Conversation_Declined_Date_Time__c = budgetConversationDeclineDateTime;
            } 
            
            if(budgetConversationNotes != null) {
                p.Budget_Conversation_Notes__c = budgetConversationNotes;
            }
            
            if(p != null) {
                insert p;       
            }

            //call updateServiceAgreementDocument(leadRecord, entityId); //p.Id
            updateServiceAgreementDocument(leadRecord,p.Id,'Plan Document');
        }
        if(p != null) {
            return p;    
        } else {
            return null;
        }
    }
    //Relationship-Sprint-9/SFDC-1063 End
    //Relationship/Sprint-6/[SFDC-832] 
    
    //Relationships-Sprint-1 [BT-756] start
     @AuraEnabled  //method to update name of files after upload on service agreement
    public static List<ContentDocument> updateFiles(string documentId,string title,string recordId){  
    	return ReconnectionsUtil.updateFiles(documentId, title, recordId,'OnboardingWizard');
    }
    //Relationships-Sprint-1 [BT-756] end
    // Sprint-6 [BT-392] start
    @AuraEnabled
    public static void updateSMSRecordOnLead(lead leadRecord) {
        Lead leadObject = new Lead();
        leadObject.Id = leadRecord.Id;
        leadObject.Click_to_Accept_Identifier__c = ReconnectionsUtil.generateHashKey();
        leadObject.Click_to_Accept_Identifier_Generated_At__c = DateTime.now();
        update leadObject;
    }
    // Sprint-6 [BT-392] end
    
    // Sprint-6 [BT-392] start
    //Class for messaging service
    @AuraEnabled(continuation=true cacheable=true)
    public static Object sendSMSviaTwilio(Id recordId,String mobileNumber,String clientName) {
        
        MPM_URLs__c mpmUrl = [SELECT Id, Name ,MPM_Click_to_Accept_URL__c  from MPM_URLs__c limit 1];
        
        
        Lead  updatedLead = [select id,Click_to_Accept_Identifier__c,Click_to_Accept_Identifier_Generated_At__c from Lead where id = :recordId LIMIT 1];
        String SMS_URL = mpmUrl.MPM_Click_to_Accept_URL__c + updatedLead.Click_to_Accept_Identifier__c;
        if(updatedLead.Click_to_Accept_Identifier__c != null) {
            SMS_URL = SMS_URL+ '?l=true&source=sms';
        }
            
        Twilio_API_Configuration__mdt twilioConfig = [SELECT Id, Account_SID__c, Authorization_Token__c, Endpoint_URL__c, SMS_Body__c, From_Number__c FROM Twilio_API_Configuration__mdt WHERE DeveloperName =: 'TwilioConfig_1'];
        String SMS_Context = clientName + ' '+twilioConfig.SMS_Body__c+' '+SMS_URL;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(twilioConfig.Endpoint_URL__c+'/'+twilioConfig.Account_SID__c+'/Messages.json');
        req.setMethod('POST');
        req.setHeader('Authorization', getAuthorizationHeader(twilioConfig));
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('To='+EncodingUtil.urlEncode(mobileNumber,'UTF-8')+'&From='+twilioConfig.From_Number__c+'&Body='+EncodingUtil.urlEncode(SMS_Context,'UTF-8'));
        
        //[CS-105]
        //Create wrapper to pass values to Callback method
        taskDetailWrapper tdw = new taskDetailWrapper();
        tdw.leadId = recordId;
        tdw.messageBody = SMS_Context;
        tdw.mobile = mobileNumber;
        
        Continuation con = new Continuation(60);
        con.continuationMethod='getTwilioRequest';
        con.addHttpRequest(req);
        con.state = tdw; //wrapper - how do we send the record id here
		system.debug('Continuation callout request :'+con);
        return con;
    }
    
    // Callback method
    @AuraEnabled(cacheable=true)
    public static Object getTwilioRequest(List<String> labels, Object state) { 
        
        //[CS-105] Start
        Id leadId;
        string messageBody;
        string mobileNumber;
        
        //Convert to JSON and parse to retrieve required values
        string JSONstring = JSON.serialize(state);
        system.debug('Continuation callout response :'+JSONstring);
        JSONParser parser = JSON.createParser(JSONstring);
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                String fieldName = parser.getText();
                parser.nextToken();
                if (fieldName == 'leadId') {
                    leadId = parser.getText();
                }
                else if (fieldName == 'messageBody') {
                    messageBody = parser.getText();
                }
                else if (fieldname == 'mobile') {
                    mobileNumber = parser.getText();
                }
            }
        }
        //[CS-105] End
        
        HttpResponse response = Continuation.getResponse(labels[0]);
        
        errorResponse errResponse;

        String result = response.getBody();
        
        if(response.getStatusCode() == 201){
            insertTask(leadId, mobileNumber, messageBody); //[CS-105]
            return result;
        } else {
            errResponse = (errorResponse)JSON.deserialize(response.getBody(),errorResponse.class);  
        }
        return result;
    }
    
    /**
    * @author: Yash Bhalerao
	* @company: Cloudwerx
    * @description : Wrapper class to pass parameters from Continuation to getTwilioRequest method
    * @param   :   ``
    * @return  :   ``
    * @ticket  :  [CS-105]
    **/
    public class taskDetailWrapper {
        public Id leadId;
        public string messageBody;
        public string mobile;
    }
    
    /**
    * @author: Yash Bhalerao
	* @company: Cloudwerx
    * @description : This method inserts Task record if SMS is sent successfully via Twilio
    * @param   :    LeadId on which Task is to be inserted, mobile number of SMS, messageBody of SMS
    * 				to be filled in Task Description
    * @return  :   ``
    * @ticket  :  [CS-105]
    **/
    @future
    public static void insertTask(Id leadId, string mobile, string messageBody) {
        
        Task tsk= new Task();
        tsk.Subject = 'SMS CTA sent to mobile number : ' + mobile + ' on date : ' + Date.today().format();
        tsk.Description = messageBody;
        tsk.Status = 'Completed';
        tsk.OwnerId = UserInfo.getUserId();
        tsk.WhoId = leadId;
        
        try {
            insert tsk;
        }
        catch(Exception e) {
            system.debug('Cannot insert task : ' + e);
        }    
    }
    
    private static String getAuthorizationHeader(Twilio_API_Configuration__mdt twilioConfig){
        Blob headerValue = Blob.valueOf(twilioConfig.Account_SID__c+ ':' + twilioConfig.Authorization_Token__c);
        return 'BASIC ' + EncodingUtil.base64Encode(headerValue);
    }
    
    public class errorResponse{
        String code;
        String message;
        String moreInfo;
        String status;    
    }
    // Sprint-6 [BT-392] end
    
    //Relationship-Sprint-9/SFDC-1063 Start
    public static void createServiceBookingRequestRecord(lead leadRecord, Plan__c planRecord, Id accountId,Case caseRecord) {
        try {
            
            Account clientAccount = [Select FirstName,LastName,PersonBirthdate,NDIS__c FROM Account WHERE id = :accountId];
            Contact c = [SELECT Email FROM Contact WHERE Id =: caseRecord.ContactId];
            Lead l = [SELECT Id, (SELECT Id, NoPhysicalPlan__c, UserProvidedStatedSupports__c FROM ServiceBookingRequests__r WHERE Status__c = 'Complete' OR ManuallyResolvedException__c = true ORDER BY CreatedDate DESC LIMIT 1) FROM Lead WHERE Id =: leadRecord.Id];
            
            ServiceBookingRequest__c serviceBookingRequest = new ServiceBookingRequest__c();
            List<StandardBookingFees__mdt> fees = [SELECT ItemNumber__c, VeryRemotePrice__c, EffectiveDate__c FROM StandardBookingFees__mdt ];
            
            for(StandardBookingFees__mdt record : fees) {
                if(record.ItemNumber__c == '14_034_0127_8_3' && record.EffectiveDate__c <= System.today()) {
                    serviceBookingRequest.PriceGuideAmount14_034__c = record.VeryRemotePrice__c;
                } else if(record.ItemNumber__c == '14_033_0127_8_3' && record.EffectiveDate__c <= System.today()) {
                    serviceBookingRequest.PriceGuideAmount14_033__c = record.VeryRemotePrice__c;
                } else if(record.ItemNumber__c == '14_032_0127_8_3' && record.EffectiveDate__c <= System.today()) {
                    serviceBookingRequest.PriceGuideAmount14_032__c = record.VeryRemotePrice__c;
                }
            }
            
            //Sprint-15/[SFDC-1247] Start
            serviceBookingRequest.RequestType__c = 'Full Booking';
            serviceBookingRequest.RequestedBy__c = 'Community Relations';
            //Sprint-15/[SFDC-1247] End
            
            // [AHOD-388] Populate Budget Allocation
            if (clientAccount?.PersonBirthdate != null) {
                Integer days = clientAccount.PersonBirthdate.daysBetween(Date.Today());
                Integer age = Date.isLeapYear(Date.Today().Year()) ? Integer.valueOf(days/366) : Integer.valueOf(days/365);
                serviceBookingRequest.BudgetAllocation__c = TTPUtil.getCoreValues(age);
            }

            serviceBookingRequest.CaseSubType__c = caseRecord.Sub_Type__c; //TTP-3502
            serviceBookingRequest.Status__c = 'Not Started';
            serviceBookingRequest.Case__c = caseRecord.Id;
            serviceBookingRequest.Account__c = accountId;
            serviceBookingRequest.ClientLastName__c = clientAccount.lastName;
            serviceBookingRequest.ClientDateOfBirth__c = clientAccount.PersonBirthdate;
            serviceBookingRequest.ClientNDISNumber__c = clientAccount.NDIS__c;       
            serviceBookingRequest.Plan__c = planRecord.Id;
            serviceBookingRequest.PlanStartDate__c = planRecord.Plan_Start_Date__c;
            serviceBookingRequest.PlanEndDate__c = planRecord.Plan_End_Date__c;
            
            // [SFDC-1264, 1265] - Start
            if(l.ServiceBookingRequests__r.size() != 0) {
                serviceBookingRequest.NoPhysicalPlan__c = l.ServiceBookingRequests__r[0].NoPhysicalPlan__c;
                serviceBookingRequest.UserProvidedStatedSupports__c = l.ServiceBookingRequests__r[0].UserProvidedStatedSupports__c;
            } 
            // [SFDC-1264, 1265] - End

            if (serviceBookingRequest != null) {
                insert serviceBookingRequest;   
            }
        } catch(Exception e) {
            system.debug('Exception :'+e);
        }
    }
    //Relationship-Sprint-9/SFDC-1063 End
    
    //Method to check if User is Assigned to CreateServiceBookingRequests permission set
    //Relationship-Sprint-15/SFDC-1235 Start
    @AuraEnabled
    public static Boolean checkUserIsAssignedToPermissionSet() {
        for(PermissionSetAssignment assignedUser : [SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE PermissionSet.Name = 'CreateServiceBookingRequests' AND AssigneeId= :UserInfo.getUserId()]) {
            return true;
        }
        return false;
    }
    //Relationship-Sprint-15/SFDC-1235 End
    
        //Relationship-Sprint-9/SFDC-1063 End
    
    //Method to get the MMM Year from custom setting
    //TTP-Sprint-6/TTP-482 Start
    @AuraEnabled
    public static ModifiedMonashModelCustomSetting__c getmmmyear() {
       return ModifiedMonashModelCustomSetting__c.getInstance();
    }
    //TTP-Sprint-6/TTP-482 end

        /**
    * @description This method identifies if Budget section on onboarding wizard should be visible, decided on pod names present in custom label.
    * @param       leadRecord lead record to identify pod name for and if budget section should be visible.
    * @Ticket      SFDC - 1276 
    * @return     `Boolean`
    **/
    @AuraEnabled
    public static Boolean showBudgetSection(lead leadRecord) {
        string leadPodName;
        String pods = System.Label.PodName;
        List<String> podNames = pods.split(',');
        Decimal leadPostalCode = Decimal.valueOf(leadRecord.PostalCode);
        List<Pod_Territory__c> podTerritories = [SELECT pod__C, Pod__r.Name, Id, StartingPostCode__c, EndingPostCode__c
                                                FROM Pod_Territory__c 
                                                WHERE StartingPostCode__c <= :leadPostalCode
                                                AND EndingPostCode__c >= :leadPostalCode Limit 50000]; //ACEM-2 added query limit
        if (podTerritories.size() == 1) {
            leadPodName = podTerritories[0].pod__r.Name;
            if (podNames.contains(leadPodName)) {
                return true;
            } else {
                return false;
            }
        } else if (podNames.contains('Exception')){ //Sprint 25-[SFDC-1431]
            return true;
        } else {
            return false;
        }
    } 
}