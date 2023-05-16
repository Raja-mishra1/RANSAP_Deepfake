/**
* Class Name: ClientExitWizardController
* Description: Controller for Client Exit Wizard Lightning Component
* Created By: Cloudwerx
* Created Date: 16/02/2021
*/

public without sharing class ClientExitWizardController{

    @AuraEnabled
    public static Account fetchAccountdata(Id clientId){
        Account acc = [Select Id,FirstName,Client_exit_current_step__c,Last_Used_By__c,Last_Used_By_Date_Time__c,Client_Performed_Final_Step__c,AccountStatus__c,Client_Exit_in_Progress__c,Last_Exit_Date__c,View_in_MPM__c,LastName,Status__c,Attempted_Exit_Type__c,Attempted_Exit_Reason__c,Attempted_Exit_Date__c,Attempted_Exit_Notes__c,Client_Attempted_Exit__c,Exit_Type__c,Reason_For_Leaving__c, CreatedDate from Account where id = :clientId LIMIT 1];
        return acc;
    }
    
    /*Fetch Custom Metadata to display in ClientExitWizard component*/
    @AuraEnabled
    public static List<Client_Exit_Wizard_Configuration__mdt> retrieveClientExitWizardCustomMetadata(){
        return [SELECT Content__c,Header__c,Order__c,Screen_Name__c FROM Client_Exit_Wizard_Configuration__mdt ORDER BY Order__c];
    }
    
    /*Fetch Custom Settings to display in ClientExitWizard component*/
    @AuraEnabled
    public static MPM_URLs__c retrieveClientExitWizardCustomSettings(){
        return   [SELECT MPM_Client_URL__c  from MPM_URLs__c limit 1];
    }
    
    @AuraEnabled
    public static Service_Agreement__c retrieveSARecord(Id accountId){ //End_Date_for_Processing_Refunds__c,End_Date_for_Processing_Invoices__c, 
        List<Service_Agreement__c> SAList = new List<Service_Agreement__c>();
        SAList = [SELECT Id,Name,Commencement_Date__c,Activated_Date__c,Date_Signed__c,Destination_on_Leaving__c,Date_of_Death__c,Outstanding_Task__c,Outstanding_Task_Notes__c,
        Request_Made_by_Primary_Decision_Maker__c,Contact_Made_with_Primary_Decision_Maker__c,Contact_Made_with__c,Reason_For_Leaving__c,Exit_Type__c,Request_Made_by__c,List_of_Plan_Managers__c,
        Exit_Date__c, Other_Plan_Manager__c,Exit_Notes__c,ABN__c,Client_response_to_Notice_Period__c,Effective_Exit_Date__c,End_Date_Processing_Invoices_Refund__c
        FROM Service_Agreement__c WHERE NDIS_Participant__c = :accountId AND Status__c = 'Current' LIMIT 1];
        if(SAList.IsEmpty()) {
            return null;
        } else {
            return SAList[0];
        }
    }
    
    /**
    * @author: Yash Bhalerao
	* @company: Cloudwerx
    * @description : This method returns the latest Service Agreement record on the Client
    * @param   :  Account Id of Client
    * @return  :   Service Agreement
    * @ticket  :  [CS-243]
    **/
    @AuraEnabled
    public static Service_Agreement__c retrieveServiceAgreement(Id accountId){
        List<Service_Agreement__c> SAList = new List<Service_Agreement__c>();
        SAList = [SELECT Id,Name,Commencement_Date__c,Activated_Date__c,Date_Signed__c,Destination_on_Leaving__c,Date_of_Death__c,Outstanding_Task__c,Outstanding_Task_Notes__c,
        Request_Made_by_Primary_Decision_Maker__c,Contact_Made_with_Primary_Decision_Maker__c,Contact_Made_with__c,Reason_For_Leaving__c,Exit_Type__c,Request_Made_by__c,List_of_Plan_Managers__c,
        Exit_Date__c, Other_Plan_Manager__c,Exit_Notes__c,ABN__c,Client_response_to_Notice_Period__c,Effective_Exit_Date__c,End_Date_Processing_Invoices_Refund__c
        FROM Service_Agreement__c 
        WHERE NDIS_Participant__c = :accountId 
        AND Client_response_to_Notice_Period__c != null LIMIT 1];
        if(SAList.IsEmpty()) {
            return null;
        } else {
            return SAList[0];
        }
    }
    
    /* Method to create/update Service Agreement Record */
    @AuraEnabled
    public static Service_Agreement__c createServiceAgreementRecord(Service_Agreement__c serviceAgreementRecord){
        if(serviceAgreementRecord != null) {
            upsert serviceAgreementRecord;
        }
        return serviceAgreementRecord;
    }
    
   	@AuraEnabled(cacheable=true)
    public static Map <String,Map<String, List<ReconnectionsUtil.PicklistValuesWrapper>>> getFieldsPicklistValuesMap(String json)
    {
        return ReconnectionsUtil.getFieldsPicklistValuesMap(json); 
    }
    
    /* Method to update Service Aggrement File*/
    @AuraEnabled
    public static List<ContentDocument> updateSAFiles(string documentId,string title,string recordId){ 
        return ReconnectionsUtil.updateFiles(documentId, title, recordId,'ClientExitWizard');
	}
    
    @AuraEnabled//method to transfer the latest SA document from account to new SA 
    public static void updateServiceAgreementDocument(Id clientId,Id entityId,String entityType) {   
        String extraFilter = '';
        
        String query = 'SELECT id,LinkedEntityId,ContentDocumentId,ShareType FROM ContentDocumentLink ';
        
        if (entityType == 'Service Agreement') {
            extraFilter = ' AND ContentDocument.Title LIKE \'%Service Agreement%\'';
        }
        query += ' WHERE LinkedEntityId = \''+ clientId + '\'' + extraFilter + ' ORDER BY ContentDocument.CreatedDate DESC LIMIT 1';
        
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
    
    
    @AuraEnabled
    public static Account saveClientRecord(Account clientRecord){
        if(clientRecord != null) {
            upsert clientRecord;
        }
        return clientRecord;
    }

    /*Method to Retrive contact records*/
    @AuraEnabled
    public static List<primaryContactDetailsWrapper> retrieveContact(Id accountId){
        Set<Id> contactIds = new Set<Id>();
        Map<Id,String> idrelationship = new Map<Id,String>(); 
        Map<Id,Boolean> isPrimaryLst = new Map<Id,Boolean>(); 
        List<primaryContactDetailsWrapper> contactDetails = new List<primaryContactDetailsWrapper>();
        for(AccountContactRelation accrelatio:[SELECT ContactId,contact.Name,contact.FirstName, contact.LastName,Relationship__c,Primary_Contact__c from AccountContactRelation WHERE AccountId=:accountId])
        {
            contactIds.add(accrelatio.ContactId);
            idrelationship.put(accrelatio.ContactId,accrelatio.Relationship__c);
            isPrimaryLst.put(accrelatio.ContactId,accrelatio.Primary_Contact__c);
        }
        List<Contact> contactList = new List<Contact>();
        contactList = [SELECT Id,Name,Email FROM Contact WHERE Id IN:contactIds];
        //return contactList;
        if(!contactList.IsEmpty())
        {
        for(Contact con:contactList)
        {
            contactDetails.add(new primaryContactDetailsWrapper(con.Name,idrelationship.get(con.id),con.Email,con.Id,isPrimaryLst.get(con.id)));
        }
    }
    return contactDetails;
    }

    /*Method to Retrive Case records*/
    @AuraEnabled
    public static caseDetailsWrapper retrieveCaseDetails(Id accountId)
    {
       
        List<Case> caseLst = new List<Case>();
        Boolean isLevel2CaseOpen = false;
        Boolean isLevel3CaseOpen = false;
        Boolean isReportableIncidentCaseOpen = false;
        Boolean noCaseOpen =false;

        for(Case caseObj:[SELECT id,CaseNumber,RecordType.Name,Owner.Name,Status,Priority,Subject,Sub_Type__c,CreatedDate,Age__c,Client__c  from Case WHERE (AccountId  =: accountId OR Client__c =:accountId) AND Status != 'Closed'])
        { 
            if(caseObj.RecordType.Name == 'General' && ((caseObj.Sub_Type__c == null) || !caseObj.Sub_Type__c.contains('Reduced Plans/Funds') && !caseObj.Sub_Type__c.contains('Insufficient Funds')))
            {
                caseLst.add(caseObj);
            }  //Sprint-20 [SFDC-1338] start
            else if (caseObj.RecordType.Name == 'Milestone Conversation') 
            {
                caseLst.add(caseObj);
            } 
            //Sprint-20 [SFDC-1338] end
            else if(caseObj.RecordType.Name == 'Complaints Level 2')
            {
                isLevel2CaseOpen = true;
            }
            else if(caseObj.RecordType.Name == 'Complaints Level 3')
            {
                isLevel3CaseOpen = true;
            }
            else if(caseObj.RecordType.Name == 'Reportable Incident')
            {
                isReportableIncidentCaseOpen = true;
            }
        }
        if( caseLst.IsEmpty())
        {
            noCaseOpen = true;
        }
        caseDetailsWrapper caseDetailsObj = new caseDetailsWrapper(caseLst,isLevel2CaseOpen,isLevel3CaseOpen,isReportableIncidentCaseOpen,noCaseOpen);
        return caseDetailsObj;
    }

    /*Wrapper class used to fetch contact details*/
    public class primaryContactDetailsWrapper
    {
        @AuraEnabled public String Name;
        @AuraEnabled public String Relationship;
        @AuraEnabled public String email;
        @AuraEnabled public String Id;
        @AuraEnabled public Boolean isPrimary;

        

        public primaryContactDetailsWrapper(String Name,String Relationship,String email,String Id,Boolean isPrimary)
        {
            this.Name= Name;
            this.Relationship = Relationship;
            this.email = email;
            this.Id = Id;
            this.isPrimary = isPrimary;
        }
    }

    /*Wrapper class used to fetch case details*/
    public class caseDetailsWrapper
    {
        @AuraEnabled public List<Case> caseData;
        @AuraEnabled public Boolean isLevel2CaseOpen;
        @AuraEnabled public Boolean isLevel3CaseOpen;
        @AuraEnabled public Boolean isReportableIncidentCaseOpen;
        @AuraEnabled public Boolean noCaseOpen;


        public caseDetailsWrapper(List<Case> caseData,Boolean isLevel2CaseOpen,Boolean isLevel3CaseOpen,Boolean isReportableIncidentCaseOpen,Boolean noCaseOpen)
        {
            this.caseData= caseData;
            this.isLevel2CaseOpen = isLevel2CaseOpen;
            this.isLevel3CaseOpen = isLevel3CaseOpen;
            this.isReportableIncidentCaseOpen = isReportableIncidentCaseOpen;
            this.noCaseOpen = noCaseOpen;
        }
    }
    
    /*Method used to update communication facility on wizard completion*/
    @AuraEnabled
    public static void updateClientCommunicationFacility(String contactList,String clientId) { 
        
        Type idArrType = Type.forName('List<string>');
    	List<string> wrapperList = (List<string>) JSON.deserialize(contactList, idArrType);
        
		Map<Id,contact> primaryContactListToUpdate = new Map<Id,contact>();
        List<AccountContactRelation> accountContactRelationListToUpdate = new List<AccountContactRelation>();

        
        for(AccountContactRelation accountContactvar:[SELECT ContactId,Contact.Name,AccountId, Primary_Contact__c from AccountContactRelation WHERE ContactId=:wrapperList AND AccountId=:clientId])
        {
            
            if(accountContactvar.Primary_Contact__c == true) {
                Contact contactObject = new Contact();
                contactObject.Id = accountContactvar.ContactId;
                contactObject.Survey_Opt_out__c = true;
                contactObject.Client_Portal_Survey_Opt_out__c = true;
                primaryContactListToUpdate.put(accountContactvar.ContactId,contactObject);
            }

            AccountContactRelation accountContactObject = new AccountContactRelation();
            accountContactObject.Id = accountContactvar.Id;
            accountContactObject.Client_Portal_Access_Level__c = 'Read only';
            accountContactObject.Send_NPS_Survey__c = false;
            accountContactRelationListToUpdate.add(accountContactObject);
        }
        
        List<Account> accountList = new List<Account>();
        Account accountObject = new Account();
        accountObject.Id = clientId;
        accountObject.Date_stamp_for_Client_portal_access__c = System.today().addDays(90);
        accountList.add(accountObject);
        

        if(!primaryContactListToUpdate.IsEmpty())
        { 
            update primaryContactListToUpdate.values();
        }
        
        if(!accountContactRelationListToUpdate.IsEmpty())
        { 
            update accountContactRelationListToUpdate;
        }
        
        if(!accountList.IsEmpty())
        { 
            update accountList;
        }
       
        ClientExitWizardController.createTask(clientId); 
        ClientExitWizardController.updateMilestoneRecord(clientId);
        //Relationships-Sprint-11/SFDC-1149 Start
        ClientExitWizardController.updateServiceAgreementRecord(clientId);
        //Relationships-Sprint-11/SFDC-1149 End
    }
    
    //Relationships-Sprint-11/SFDC-1149 Start
    public static void updateServiceAgreementRecord(String accountId) {
        List<Service_Agreement__c> SAList = new List<Service_Agreement__c>();
        
        for(Service_Agreement__c SA : [SELECT Id,Status__c,Client_response_to_Notice_Period__c FROM Service_Agreement__c WHERE NDIS_Participant__c = :accountId Limit 50000]) { //ACEM-2 added query limit
            
            if(SA.Status__c == 'Current' && SA.Client_response_to_Notice_Period__c == 'Exit me today') {
                Service_Agreement__c SAObject = new Service_Agreement__c();
                SAObject.Id = SA.Id;
                SAObject.Status__c = 'Inactive';
                SAObject.Service_End_Date__c = System.today();
                SAList.add(SAObject);
            }
        }
        
        if(!SAList.IsEmpty()) {
            update SAList;
        }
    } 
    //Relationships-Sprint-11/SFDC-1149 End
    
    /*Method to update Update Milestone Record and its related Case record*/
    public static void updateMilestoneRecord(String accountId) {
        List<Milestone__c> milestoneList = new List<Milestone__c>();
        Set<Id> milestoneIdSet = new Set<Id>();
        List<Case> milestoneCaseList = new List<Case>();
        
        for(Milestone__c milestoneRecord : [Select id,Status__c,Opt_Out_Reason__c from Milestone__c where Client__c = :accountId AND plan__r.Active__c = true Limit 50000]) { //ACEM-2 added query limit
            milestoneIdSet.add(milestoneRecord.Id);
            if(milestoneRecord.Status__c != 'Done') {
                milestoneRecord.Status__c = 'Opted-Out';
                milestoneRecord.Opt_Out_Reason__c = 'Client exited MPM';
                milestoneList.add(milestoneRecord);
            }
            system.debug('----MileStone Record ---'+milestoneRecord);
        }
        
        for(Case caseRecord : [Select id,Status,CaseNumber,Sub_Type__c from Case where Milestone__c in :milestoneIdSet Limit 50000]) { //ACEM-2 added query limit
            if(caseRecord.Status != 'Closed' && caseRecord.Sub_Type__c == 'Client Milestone Conversation') {
                caseRecord.Status = 'Closed';
                milestoneCaseList.add(caseRecord);
            }
            system.debug('---- Case belonging to MileStone Record ---'+caseRecord);
        }
        
        if(!milestoneList.IsEmpty())
        { 
            update milestoneList;
        }
        
        if(!milestoneCaseList.IsEmpty())
        { 
            update milestoneCaseList;
        }
    } 
    
    /*Method used to create task*/
    public static void createTask(String accountId) {
        Account acc = [Select Id, OwnerId FROM Account WHERE Id =: accountId];
        try {
            Task tsk= new Task();
            tsk.Subject = 'Send Financial Statement ';
            tsk.ActivityDate = system.today();
            tsk.Status = 'Open';
            tsk.Priority = 'Normal';
            tsk.OwnerId = UserInfo.getUserId();
            tsk.WhatId = accountId;
            tsk.IsReminderSet = true;
            tsk.ReminderDateTime = system.today();
            
            insert tsk;
        }
        catch(Exception e){
            
        }          
    }
    
    /*Method  used to send email to client depending on Exit Type*/
    @AuraEnabled
    public static void sendEmailToClients(String recordId, String emailAddress,String primaryContactId, String emailTemplateName) {
       
        ClientExitWizardController.sendEmail(recordId,emailAddress,primaryContactId,emailTemplateName);
    }
    
    public static String sendEmail(Id clientId,String emailAddress,Id contactId, String emailTemplateName) {        
        List<String> clientEmailAddress = emailAddress.split(',');
        System.debug('EmailTemplatename--->'+emailTemplateName);
        EmailTemplate exitClientTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = :emailTemplateName];
        OrgWideEmailAddress welcomeOrgWideEmailAddress;
        String NO_REPLY_EMAIL = Label.Client_exit_wizard_email;
        
        if(Test.IsRunningTest()){
            welcomeOrgWideEmailAddress = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        }
        else{
            welcomeOrgWideEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: NO_REPLY_EMAIL];
        }
        
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();

        emailMessage.setTemplateId(exitClientTemplate.Id);
        emailMessage.setTargetObjectId(contactId);
        emailMessage.setWhatId(clientId);
        emailMessage.setToAddresses(clientEmailAddress);
        emailMessage.setTreatTargetObjectAsRecipient(false);
        emailMessage.setOrgWideEmailAddressId(welcomeOrgWideEmailAddress.Id);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { emailMessage });

        return 'Click to accept sent successfully';
    }

    @AuraEnabled
    public static void sendEmailforComplaintsQueue(Account acc)
    {
        Boolean isLevel2CaseOpen = false;
        String clientName ;
        for(Case caseObj:[SELECT id,CaseNumber,Client__c,Client__r.Name,Account.Name,RecordType.Name,Owner.Name,Status,Priority,Subject,Sub_Type__c,CreatedDate,Age__c 
                         from Case WHERE (AccountId  =: acc.id OR Client__c =:acc.id) AND Status != 'Closed' AND RecordType.Name = 'Complaints Level 2' Limit 50000]) //ACEM-2 added query limit
        {
            isLevel2CaseOpen = true;
            if(caseObj.Account!=null)
            {
            clientName = caseObj.Account.Name;
            }
            else
            {
                clientName = caseObj.Client__r.Name;
            }
        }
        if(isLevel2CaseOpen)
        {
            OrgWideEmailAddress welcomeOrgWideEmailAddress;
            String NO_REPLY_EMAIL = Label.Client_exit_wizard_email;
            if(Test.IsRunningTest()){
                welcomeOrgWideEmailAddress = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
            }
            else{
                welcomeOrgWideEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: NO_REPLY_EMAIL];
            }
            Group grp = [select Id from Group where Name='Complaints' and Type = 'Queue'];
            for(User users:[SELECT Email,Name FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.id=:grp.id)])
            {
                List<String> emailaddress = new List<String>();
                emailaddress.add(users.Email);
                system.debug('user email---'+users.Email);
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                msg.setToAddresses(emailaddress);
                msg.setsubject(clientName+' exited');
                String url =  URL.getSalesforceBaseUrl().toExternalForm();
                url = url+'/'+acc.id;
                system.debug('URL generated is'+url);
                String  body = 'Hi '+users.Name+' <br />';
                body +='<br />';
                body +='This email has been generated to inform you that a Client has been exited with a pending Level 2 Complaint. Please click on the following link to view the record in Salesforce. <br />';
                body +=url+'<br />';
                body +='<br />';
                body +='<br />';
                body +='Kind Regards, <br />';
                body +='Salesforce Administrator';
                msg.setHTMLbody(body);
                msg.setOrgWideEmailAddressId(welcomeOrgWideEmailAddress.Id);
                Messaging.sendEmail(new list<Messaging.SingleEmailMessage>{msg});
            }   
    
        }
    }

    /**
     * @description  [TFR-164] This method creates invoice and line items on client exit
     * @author       Sonali Bhat
     * @param        clientId : Client Id
                     lastExitDate  : Exit Date of Client
                     clientCreatedDate : Created Date of Client
     * @return       NA
     */

    @AuraEnabled
    public static void handleInvoiceAndLineItemCreation(Id clientId, DateTime lastExitDate, String clientCreatedDate) {
        try {
            String mpmProviderId = Fee_Invoice_Rule_Configuration__mdt.getInstance('FeeConfig1').MyPlanManagerRecordId__c;
            String ndspProviderId = Fee_Invoice_Rule_Configuration__mdt.getInstance('FeeConfig1').NDSPRecordId__c;
            Date clientCreatedDateValue = Date.valueOf(clientCreatedDate);
            Date lastExitDateValue = lastExitDate.date();
            DateTime currentMonthStartDate = Date.today().toStartOfMonth();
            DateTime currentMonthEndDate = date.today().addMonths(1).toStartofMonth().addDays(-1);
            String currentMonth = currentMonthStartDate.format('MMMM');
            Integer currentYear = currentMonthStartDate.year();
            DateTime nextMonthStartDate = Date.today().addMonths(1).toStartOfMonth();

            List<Invoice__c> listOfInvoices = new List<Invoice__c>();
            Map<Id,Integer> invoicesWithCount = new Map<Id,Integer>();
        

            Date supportStartDate =  clientCreatedDateValue > currentMonthStartDate.date() ?
                                    clientCreatedDateValue : currentMonthStartDate.date();

        
            // Get Plan Manager value from Client                      
            List<Account> clientAcc =  
                [
                    SELECT PlanManager__c
                    FROM Account 
                    WHERE Id =:clientId
                ];
            
            if (lastExitDateValue > Date.today() 
                && (
                    (lastExitDateValue.month() > Date.today().month() 
                    && lastExitDateValue.year() == Date.today().year()) 
                    || lastExitDateValue.year() > Date.today().year()
                    )
            ) {
                // create 2 invoices in case exit date is greater than current month
                listOfInvoices.add(getInvoiceForClient(
                    supportStartDate, currentMonthEndDate.date(), 
                    clientId, 
                    clientAcc[0].PlanManager__c == NDSPConstants.MPM  
                    ? mpmProviderId 
                    : clientAcc[0].PlanManager__c == NDSPConstants.NDSP
                    ? ndspProviderId : null, 
                    currentMonthStartDate));

                listOfInvoices.add(getInvoiceForClient(
                    nextMonthStartDate.date(), lastExitDateValue, 
                    clientId, 
                    clientAcc[0].PlanManager__c == NDSPConstants.MPM  
                    ? mpmProviderId 
                    : clientAcc[0].PlanManager__c == NDSPConstants.NDSP
                    ? ndspProviderId : null, 
                    nextMonthStartDate));
            } else {
                // create 1 invoice
                listOfInvoices.add(getInvoiceForClient(
                    supportStartDate, lastExitDateValue, 
                    clientId, 
                    clientAcc[0].PlanManager__c == NDSPConstants.MPM  
                    ? mpmProviderId 
                    : clientAcc[0].PlanManager__c == NDSPConstants.NDSP
                    ? ndspProviderId : null, 
                    currentMonthStartDate));
            }

            insert listOfInvoices;  // insert invoices

            // Create Line Items
            List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();

            for (invoice__c inv : listOfInvoices) {
                /* get plans for invoice, it's a query inside for loop 
                    but there would be either 1 invoice or 2 invoices only
                */
                List<Plan__c> listOfPlans = getPlans(clientId, inv); 
                if (!listOfPlans.isEmpty()) {
                    /*if plan list is not empty, 
                        create line items as per the logic in getLineItems Method
                    */
                    lineItems.addAll(getLineItems(inv, listOfPlans, invoicesWithCount));
                    
                } else {
                    // if plan list is empty, create only 1 line item
                    lineItems.add(getSingleLineItem(inv, inv.Support_Start_Date__c, inv.Support_End_Date__c));
                    invoicesWithCount.put(inv.id, 1); // maintain the count of line items
                }
            }

            if (!lineItems.isEmpty()) {
                insert lineItems;   // insert line items
            }

            // initiate invoice rule engine
            List<Invoice_Engine_Trigger__e> events = new List<Invoice_Engine_Trigger__e>();
            for (String inv: invoicesWithCount.keySet()) {
                events.add(TTPUtil.getInvoiceTriggerEvent(inv, invoicesWithCount.get(inv)));
            }
            if (events.size() > 0) {
                TTPUtil.publishInvoiceTriggerEvent(events); // publish event which will execute the rules
            }

        } catch (Exception e) {
            LogService.insertLog(new List<EventLog__e> {LogService.logSaveResult('ClientExitWizardController',
                        'handleInvoiceAndLineItemCreation', e.getMessage(), '' , '', '')});
        }
    }

    /**
     * @description  [TFR-164] This method returns invoice object with field mappings
     * @author       Sonali Bhat
     * @param        supportStartDate : Invoice Start Date
                     supportEndDate  : Invoice End Date
                     clientId : Client Id
                     providerId : Provider Account Id
                     referenceDate : Date to be used in Reference Number
     * @return       Invoice 
     */

    @AuraEnabled
    public static Invoice__c getInvoiceForClient(Date supportStartDate, Date supportEndDate, Id clientId, String providerId, DateTime referenceDate) {
        return new Invoice__c(
            Reference_Number__c = referenceDate.format('MMMM').toUppercase()+referenceDate.year()+'MONTHLYFEE',
            Document_Type__c = InvoiceRuleConstant.DOCUMENT_TYPE_FEE,
            Invoice_Origin__c = 'Client Exit',
            FeeType__c = InvoiceRuleConstant.INVOICE_FEETYPE_MONTHLY,
            Client__c = clientId,
            Provider__c = providerId,
            Support_Start_Date__c = supportStartDate,
            Support_End_Date__c = supportEndDate,
            Status__c = 'New'
        );
    }

    /**
     * @description  This method gets list of plans falling within invoice dates
     * @author       Sonali Bhat
     * @param        clientId : Client Id
                     inv  : Invoice object
     * @return       List of Plans 
     */

    @AuraEnabled
    public static List<Plan__c> getPlans(Id clientId, Invoice__c inv) {
        return [
            SELECT Id, PRODA_Plan_Id__c, Plan_Start_Date__c, Plan_End_Date__c,
                    Client_Name__c 
            FROM Plan__c 
            WHERE ((Plan_Start_Date__c <=
                :inv.Support_Start_Date__c AND Plan_End_Date__c >=
                :inv.Support_Start_Date__c) OR (Plan_Start_Date__c <=
                :inv.Support_End_Date__c AND Plan_End_Date__c >=
                :inv.Support_End_Date__c )) AND  Client_Name__c =:clientId
            ORDER BY Plan_Start_Date__c ASC
        ];   
    }

    /**
     * @description  [TFR-164] This method returns single line item to be created
     * @author       Sonali Bhat
     * @param        invoice : Invoice object
                     clientId  : Client Id
                     startDate : Service Date From
                     endDate   : Service Date To
     * @return       Invoice Line Item
     */

    @AuraEnabled
    public static Invoice_Line_Item__c getSingleLineItem(Invoice__c invoice, Date startDate, Date endDate) {
        return new Invoice_Line_Item__c(
            Service_Date_From__c = startDate,
            Service_Date_To__c = endDate,
            Invoice__c = invoice.Id,
            Status__c = 'New'
        );
    }

    /**
     * @description  [TFR-164] This method returns line items to be created
     * @author       Sonali Bhat
     * @param        invoice : Invoice object
                     listOfPlans  : Plan List
                     invoicesWithCount : Map to maintain counter of line items for invoice
     * @return       List of Invoice Line Items
     */

    @AuraEnabled
    public static List<Invoice_Line_Item__c> getLineItems(Invoice__c invoice, List<Plan__c> listOfPlans, Map<Id,Integer> invoicesWithCount) {
       
        List<Date> serviceDates = new List<Date>();
        List<Invoice_Line_Item__c> invoiceLineList = new List<Invoice_Line_Item__c>();
        Set<Date> setOfPlanEndDates = new Set<Date>();
        
        // add plan start date to the list
        if (listOfPlans[0].Plan_Start_Date__c > invoice.Support_Start_Date__c) {
            serviceDates.add(listOfPlans[0].Plan_Start_Date__c);
        }

        // add distinct plan end dates to the list
        for (Plan__c plan : listOfPlans) {
            if (!setOfPlanEndDates.contains(plan.Plan_End_Date__c) 
                && plan.Plan_End_Date__c < invoice.Support_End_Date__c
            ) {
                serviceDates.add(plan.Plan_End_Date__c);
                setOfPlanEndDates.add(plan.Plan_End_Date__c);  // distinct plan end dates
            }
        }
        
        if (serviceDates.size() > 0) {

            // add Ist Invoice Line which starts from Invoice Start Date
            invoiceLineList.add(getSingleLineItem(invoice, invoice.Support_Start_Date__c,  serviceDates[0]));
            
            // add other invoice line items
            for (Integer i = 1; i+1 < serviceDates.size(); i++) {
                invoiceLineList.add(getSingleLineItem(invoice, serviceDates[i],  serviceDates[++i]));
            }

            // add Last Invoice Line whose end date will be equal to Invoice-> Support End Date
            if (Math.mod(serviceDates.size(), 2) == 0) { 
                invoiceLineList.add(getSingleLineItem(invoice, serviceDates[serviceDates.size()-1],  invoice.Support_End_Date__c));
            } else {
                invoiceLineList.add(getSingleLineItem(invoice, serviceDates[serviceDates.size()-1]+1,  invoice.Support_End_Date__c));
            }

        } else {
            // if serviceDates List has no dates, create a single line item
            invoiceLineList.add(getSingleLineItem(invoice, invoice.Support_Start_Date__c, invoice.Support_End_Date__c));
        }

        invoicesWithCount.put(invoice.Id,invoiceLineList.size()); // maintain the count of line items
        return invoiceLineList;
    }
}