/** Name: ProviderPortalFormController
 * Description : This class used by Provider portal to get Account/Contact details, create Cases, fetch metadata records
 * Created By : Cloudwerx
 * Created Date : 2/11/2020
*/
public without sharing class ProviderPortalFormController {

    /* Fetches custom metadata to get field value when creating cases*/
    @AuraEnabled(cacheable=true)
    public static List<Case_Batch_Configuration__mdt> fetchCaseMetadataRecord(){

        try {
            Case_Batch_Configuration__mdt [] metadataRecord = [SELECT Id, Case_Origin__c, Case_Record_Type_Id__c, Description__c, Owner_Id__c, Priority__c, PlanManager__c, //NAP5-306
                                                                Status__c, Subject__c, Sub_Type__c, Type__c  FROM Case_Batch_Configuration__mdt WHERE Id =: System.Label.Provider_Portal_ProfileUpdateCase];
            if (!metadataRecord.isEmpty()) {
                return metadataRecord;
            } else {
                return null;
            }    
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Account fetchAccountDetails(){
        User user = [SELECT Id, ContactId FROM User WHERE Id =: UserInfo.getUserId()];
        Account provider;
        List<Contact> contactList =  [SELECT Id,Name,AccountId FROM Contact WHERE Id =:user.ContactId];
        if (!contactList.isEmpty()) {
            provider = [SELECT Id, Name, ABN__c, MPM_ID__c,MPM_ID_Auto_Inc__c FROM Account WHERE Id =: contactList[0].AccountId];    
        }        
        return provider;
    }
  
    @AuraEnabled(cacheable=true)
    public static List<AccountContactListWrapper> fetchAccountData(String userId)
    {
        String accountId;
        try {
            List<User> userList = new List<User>(); 
            List<Contact> contactList = new List<Contact>();
            List<AccountContactListWrapper> accConList = new List<AccountContactListWrapper>();
            List<Contact> contactLst = new List<Contact>();
            List<Account> accountLst = new List<Account>();
            userList = [SELECT id,Name,ContactId FROM User WHERE Id =:userId LIMIT 1];
            
            contactList =  [SELECT id,Name, Email, MobilePhone, AccountId, Provider_Portal_Survey_Opt_out__c FROM Contact WHERE Id =:userList[0].ContactId];
            if (!contactList.isEmpty()) {                
                accountLst = [SELECT id,Name, ABN__c, MPM_ID__c,MPM_ID_Auto_Inc__c FROM Account WHERE Id =: contactList[0].AccountId];
                contactList[0].MobilePhone = contactList[0].MobilePhone != null ? contactList[0].MobilePhone.replaceAll( '.(?=.{2})', '*' ) : '';
                if (contactList[0].MobilePhone.length()==10) {
                    String[] mobileArray = contactList[0].MobilePhone.split('');
                    contactList[0].MobilePhone = '('+mobileArray[0]+mobileArray[1]+')'+mobileArray[2]+mobileArray[3]+mobileArray[4]+mobileArray[5]+' '+mobileArray[6]+mobileArray[7]+mobileArray[8]+mobileArray[9];
                }
                
                AccountContactListWrapper accWrapper = new AccountContactListWrapper(accountLst[0],contactList[0]);
                accConList.add(accWrapper);
            }
            
            if (!accConList.isEmpty()) {
                return accConList;
            } else {
                return null;
            }            
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class AccountContactListWrapper {

        @AuraEnabled public Account acc {get; set;}
        @AuraEnabled public Contact con {get; set;}
        
        public AccountContactListWrapper(Account a, Contact c) {
            if (a.ABN__c != null && a.ABN__c.length() == 11) {
                String[] abnArray = a.ABN__c.split('');
                a.ABN__c = abnArray[0]+abnArray[1]+' '+abnArray[2]+abnArray[3]+abnArray[4]+' '+abnArray[5]+abnArray[6]+abnArray[7]+' '+abnArray[8]+abnArray[9]+abnArray[10];
            }
            this.acc = a;
            this.con = c;
        }
    }

    /** This method creates Case records*/
    @AuraEnabled
    public static List <Case> createCaseRecord(Case caseRec, Integer count) {
        if (caseRec != null) {
            List <Case> listOfCaseToInsert = new List <Case>();
            Integer i=0;
            while (i < count) {
                Case nCase =  caseRec.clone(false, false, false, false);
                listOfCaseToInsert.add(nCase);
                i++;
              }
            insert listOfCaseToInsert;
            List <Case> listOfCaseToReturn = [SELECT Id, CaseNumber FROM Case WHERE Id IN :listOfCaseToInsert];
            return listOfCaseToReturn;
        } else {
            return null;
        }
    }

    /** Method called from Create Invoice to identify if the MPM Id of the Client entered */
    @AuraEnabled
    public static Account searchClient(String clientLoad){
        try {
            Client client = (Client)JSON.deserialize(clientLoad, Client.class);
            client.convertDate();

            String query = 'SELECT Id, MPM_ID__c, MPM_ID_Auto_Inc__c FROM Account WHERE (isPersonAccount = True AND FirstName = \'' +  String.escapeSingleQuotes(client.firstName) + '\'' + ' AND LastName = \'' +String.escapeSingleQuotes(client.lastName) +  '\') AND (';
            
            if(client.ndisNumber != null && ! String.isBlank(client.ndisNumber)){
                query+= ' NDIS__c = \'' + String.escapeSingleQuotes(client.ndisNumber) + '\' OR';
            }
            if(client.dateOfBirth != null){
                query+= ' PersonBirthdate =  '+ DateTime.newInstance( client.dateOfBirth, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd') + ' OR';
            }
            if( client.street != null && !String.isBlank(client.street) &&  (client.suburb != null && !String.isBlank(client.suburb)) && (client.postcode != null && !String.isBlank(client.postcode))){
                query+= ' (BillingStreet = ' + '\'' + String.escapeSingleQuotes(client.street) + '\''+ ' AND BillingCity = \'' + String.escapeSingleQuotes(client.suburb) + '\'' + ' AND BillingPostalCode =' + '\'' + String.escapeSingleQuotes(client.postcode) + '\')';
            }
            query = query.removeEnd('OR');
            query += ') ORDER BY NDIS__c Limit 50000'; //ACEM-2 Added query limit

            List<Account> clientAccountList = Database.query(query);

            if(!clientAccountList.isEmpty()){
                if(clientAccountList.size() == 1){
                    return clientAccountList[0];
                }
                else{
                    return null;
                }
            }
            else{
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description This method updates survey opt out preference of provider portal user.
    * @param       userId user id of provider.
    * @param       newValue new value to be updates.
    * @return     `String`
    * For Ticket [SFDC-1177]
    **/
    @AuraEnabled
    public static String updateProviderPortalSurveyPreference(String userId, boolean newValue){
        boolean success;
        try {
            List<User> userList = [SELECT id,Name,ContactId FROM User WHERE Id =:userId LIMIT 1];
            List<Contact> contactList =  [SELECT id,Name, Email, MobilePhone, AccountId, Provider_Portal_Survey_Opt_out__c FROM Contact WHERE Id =:userList[0].ContactId];
            Contact contactToUpdate = contactList[0];
            contactToUpdate.Provider_Portal_Survey_Opt_out__c = !newValue; 
            update contactToUpdate;
            return contactToUpdate.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    private class Client{
        private String firstName; 
        private String lastName;
        private String street;
        private String suburb;
        private String state;
        private String postcode;
        private String latitude;
        private String longitude;
        private String ndisNumber;
        private String dob;
        private String dobConvert;
        private Date dateOfBirth;
 
        private void convertDate(){
            if(dobConvert != null){
                dateOfBirth = date.ValueOf(dobConvert);
            }
        }
    }

    /** Fetches Portal config custom settings used by Create Invoice */
    @AuraEnabled
    public static MPM_Provider_Configurations__c fetchPortalCustomSettings(){
        return MPM_Provider_Configurations__c.getOrgDefaults();
    }

    /** Fetches session Id of logged in portal users, helps to call Salesforce API*/
    @AuraEnabled
    public static String fetchSessionId(){
        return UserInfo.getSessionId();
    }

    /** Method to send uploaded invoices to Claims queue */
    @AuraEnabled
    public static void sentCasesToClaimAutomation(List <Case> caseList){
        try {
            //confirmed on TFR-184
            ReconnectionsUtil.sentCasesToClaimAutomation(new Map<Id,SObject>(caseList).keySet());
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //TTP-3059 Commenting out
    /**TTP-232
     ** TFR-183 , TFR-184 (Re-Enabling the Provider Portal)
    * @ description                 Method fetches the invoices for the current provider
    * @ return                      List of Invoice__c record for the current provider
    * @ param providerAccountId     Provider Account id of current user
    */
    @AuraEnabled(cacheable=true)
    public static String fetchInvoiceList(Integer pageSize, Integer pageNumber,String sortingField, Boolean isSortAsc, List<String> filterstatus, String filterStartDate, String filterEndDate, String searchString){
        String jsonDT = '';               
        //Offset for SOQL
        Integer offset = (pageNumber - 1) * pageSize;

        Account provider;
        Id contactId;
        
        if (Test.isRunningTest()) {
            contactId = [SELECT Id FROM Contact LIMIT 1].Id;
        } else {            
            contactId = [Select contactid from User where id =: Userinfo.getUserid()].contactId;
        }

        if (contactId != null) {
            provider = [SELECT Id, Name, ABN__c, MPM_ID__c,MPM_ID_Auto_Inc__c 
                                    FROM Account 
                                    WHERE Id =: [Select AccountId from Contact WHERE id =: contactId].AccountId];
        }

        try {
            //TFR-184
            String query =  'SELECT Reference_Number__c, Client__r.Name, CreatedDate, Paid_Date__c,'+ 
                            ' Status__c, Support_Start_Date__c, Support_End_Date__c,'+
                            ' Total__c, Case__r.CaseNumber FROM Invoice__c WHERE Status__c != \'Cancelled\' AND Provider__c = \''+ provider.Id + '\''; //Added Cancelled check TFR-183
            
            String extraFilters = ''; //FOR COUNT QUERY - CAN REMOVE LATER

            //Addition filters
            //TFR-184
            if (filterstatus.size() == 1) {
                if (filterstatus[0] == 'In Progress') {
                    extraFilters = ' AND Status__c != \'Paid\' AND Status__c != \'Credit Paid\'';
                    query += ' AND Status__c != \'Paid\' AND Status__c != \'Credit Paid\'';
                } else if (filterstatus[0] == 'Paid') {
                    extraFilters = ' AND (Status__c = \'Paid\' OR Status__c = \'Credit Paid\')';
                    query += ' AND (Status__c = \'Paid\' OR Status__c = \'Credit Paid\')';
                } else {
                    extraFilters = ' AND Status__c = \''+ filterstatus[0] + '\'';
                    query += ' AND Status__c = \''+ filterstatus[0] + '\'';
                }                
            } else if (filterstatus.size() > 1) {
                extraFilters = ' AND Status__c IN :'+filterstatus;
                query += ' AND Status__c IN :'+filterstatus;
            }  

            if (!String.isBlank(searchString)) {
                extraFilters += ' AND ((Client__r.Name LIKE \'%'+searchString + '%\') OR (Reference_Number__c LIKE \'%'+searchString + '%\'))';
                query += ' AND ((Client__r.Name LIKE \'%'+searchString + '%\') OR (Reference_Number__c LIKE \'%'+searchString + '%\'))';
            }

            extraFilters += !String.isBlank(filterStartDate) ? ' AND Support_Start_Date__c  >= '+filterStartDate : '';
            query += !String.isBlank(filterStartDate) ? ' AND Support_Start_Date__c  >= '+filterStartDate : '';

            extraFilters += !String.isBlank(filterEndDate) ? ' AND Support_End_Date__c <= '+filterEndDate : '';
            query += !String.isBlank(filterEndDate) ? ' AND Support_End_Date__c <= '+filterEndDate : '';

            if (!String.isBlank(sortingField) && isSortAsc != null) {
                String sortBy = isSortAsc ? 'ASC' : 'DESC';                                         
                query += ' ORDER BY ' + sortingField + ' ' + sortBy + ' NULLS LAST';
            } else if (isSortAsc == null) {
                query += ' ORDER BY CreatedDate DESC NULLS LAST';
            }           
            
            query += ' LIMIT '+pageSize+' OFFSET '+offset;
                //Calculate totalRecords //TFR-183 - Added status check
                String quertString = 'SELECT COUNT() FROM Invoice__c WHERE Status__c != \'Cancelled\' AND Provider__c = \''+ provider.Id + '\''; 
                quertString += extraFilters.length() > 0 ? extraFilters : '';
                Integer totalRecords = Database.countQuery(quertString);
                Integer recordEnd = pageSize * pageNumber;
                
                InvoiceDTWrapper objDT =  new InvoiceDTWrapper();  
                objDT.pageSize = pageSize;
                objDT.pageNumber = pageNumber;
                objDT.recordStart = offset + 1;
                objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
                objDT.totalRecords = totalRecords;
                objDT.invoices = Database.query(query);
                jsonDT = JSON.serialize(objDT);
                return jsonDT;
        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String createInvoiceAndLineItems(String providerPortalData){
        try {
            ProviderPortalData portalData = (ProviderPortalData) JSON.deserialize(providerPortalData, ProviderPortalData.CLASS);
            
            Invoice__c invoiceToInsert = portalData.getInvoiceRecord();
            insert invoiceToInsert;
            List<Invoice_Line_Item__c> lineItemsToInsert = portalData.getLineItemRecords(invoiceToInsert);
            insert lineItemsToInsert;
            AsyncApexJob job = InvoiceRuleHelper.executeInvoiceProcessing(invoiceToInsert.Id);
            return invoiceToInsert.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void attachFileAsPDF(String invoiceId){
        try {
            if(!Test.isRunningTest()) {
                HTTP h = new HTTP();
                HTTPRequest request = new HTTPRequest();
                request.setEndpoint(Site.getBaseUrl()+'/apex/ProviderPortalGenerateInvoice?invoiceId='+invoiceId);
                request.setHeader('contentType', 'application/pdf');
                request.setHeader('Authorization', 'Bearer '+UserInfo.getSessionId());            
                request.setMethod('GET');
                HTTPResponse resp = h.send(request); 
                ContentVersion cv = new ContentVersion();
                if(resp.getStatusCode()==200){                
                    cv.Title = 'Invoice';
                    cv.PathOnClient = 'Invoice.Pdf';
                    cv.VersionData = resp.getBodyAsBlob();
                    cv.IsMajorVersion = true;
                    insert cv;
                }

                List<ContentVersion> cvList = [SELECT ContentDocumentId FROM ContentVersion WHERE id = :cv.Id AND IsLatest = true];

                ContentDocumentLink cDocLink = new ContentDocumentLink(ContentDocumentId = cvList[0].ContentDocumentId,
                                                            LinkedEntityId = invoiceId,
                                                            Visibility ='AllUsers',
                                                            ShareType ='V');
                insert cDocLink;
            }
                        
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    
    
    
    public class InvoiceDTWrapper {
        public Integer pageSize {get;set;}
        public Integer pageNumber {get;set;}
        public Integer totalRecords {get;set;}
        public Integer recordStart {get;set;}
        public Integer recordEnd {get;set;}
        public Account providerAccount {get;set;}
        public List<Invoice__c> invoices {get;set;}
    }

    public class ProviderPortalData{
        public String abn {get;set;}
        public String invoiceDate {get;set;}
        public String invoiceNo {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String street {get;set;}
        public String suburb {get;set;}
        public String state {get;set;}
        public String postcode {get;set;}
        public String latitude {get;set;}
        public String longitude {get;set;}
        public String ndisNumber {get;set;}
        public Decimal totalPrice {get;set;}
        public String dob {get;set;}
        public String companyName {get;set;}
        public String dobConvert {get;set;}
        public String casenumber {get;set;}
        public String clientId {get;set;}
        public String providerId {get;set;}
        public String supportStartDate {get;set;}
        public String supportEndDate {get;set;}
        public List<SupportItem> supportItem;

        public Invoice__c getInvoiceRecord(){
            Invoice__c invoiceRec = new Invoice__c();
            invoiceRec.Reference_Number__c = this.invoiceNo;
            invoiceRec.Document_Type__c = 'Invoice';
            invoiceRec.Invoice_Origin__c = 'Provider Portal';
            invoiceRec.Client_Street__c = this.street;
            invoiceRec.Client_City__c = this.suburb;
            invoiceRec.Client_StateCode__c = this.state;
            invoiceRec.Client_PostalCode__c = this.postcode;
            invoiceRec.Client_Location__latitude__s = this.latitude != null ? Decimal.valueOf(this.latitude) : null;
            invoiceRec.Client_Location__longitude__s = this.longitude != null ? Decimal.valueOf(this.longitude) : null;
            invoiceRec.Client__c = this.clientId != null ? this.clientId : null;
            invoiceRec.Client_Birthdate__c = this.dobConvert != null ? Date.ValueOf(this.dobConvert) : null;
            invoiceRec.Total__c = this.totalPrice;
            invoiceRec.Client_NDIS_Number__c = this.ndisNumber;
            invoiceRec.Client_Name__c = this.firstName + ' ' + this.lastName;
            invoiceRec.Provider__c = this.providerId != null ? this.providerId : null;
            invoiceRec.Provider_ABN__c = this.abn != null ? this.abn.replaceAll(' ', '') : '';
            invoiceRec.Status__c = 'New';
            invoiceRec.Case__c = getCaseRecord(this.casenumber);
            invoiceRec.Support_Start_Date__c = this.supportStartDate != null ? Date.ValueOf(this.supportStartDate) : null; 
            invoiceRec.Support_End_Date__c = this.supportEndDate != null ? Date.ValueOf(this.supportEndDate) : null;
            
            return invoiceRec;
        }

        public List<Invoice_Line_Item__c> getLineItemRecords(Invoice__c invoice){
            
            List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
            for(SupportItem sItem : supportItem){

                    //Sprint-12/TTP-235 Start
                    Invoice_Line_Item__c lineItemRecord = new Invoice_Line_Item__c();
                    if(invoice.Id != null) {
                        lineItemRecord.Invoice__c = invoice.Id;
                    }
                    
                    if(sItem.supportId != null) { 
                        lineItemRecord.Support_Item__c = sItem.supportId;
                    }

                    if(sItem.quantity != null) { 
                        lineItemRecord.Quantity__c = sItem.quantity;
                    }
                    
                    if(sItem.unitPrice != null) { 
                        lineItemRecord.RateExGST__c = Decimal.valueOf(sItem.unitPrice);
                    }
                    
                    if(sItem.description != null) { 
                        lineItemRecord.Description__c = sItem.description;
                    }
                    
                    if(sItem.unitPrice != null && sItem.quantity != null) { 
                        lineItemRecord.Total__c = Decimal.valueOf(sItem.unitPrice) * sItem.quantity;                       
                    }
                    
                    if(sItem.dateFromConverted != null) { 
                        lineItemRecord.Service_Date_From__c = sItem.dateFromConverted != null ? Date.ValueOf(sItem.dateFromConverted) : null;
                    }
                    
                    if(sItem.dateToConverted != null) { 
                        lineItemRecord.Service_Date_To__c = sItem.dateToConverted != null ? Date.ValueOf(sItem.dateToConverted) : null;
                    }

                    if(lineItemRecord.Service_Date_From__c != null && lineItemRecord.Service_Date_To__c != null) {
                        invoiceLineItems.add(lineItemRecord);
                    }
                    
                    //Sprint-12/TTP-235 End
            }
            return invoiceLineItems;
        }

        public String getCaseRecord(String caseNumber){
            if (caseNumber != null) {
                List<Case> caseRec = [SELECT Id FROM Case WHERE CaseNumber =: caseNumber];    
                if(!caseRec.isEmpty()){
                    return caseRec[0].Id;
                } else{
                    return null;
                }       
            } else {
                return null;
            }
        }
    }

    public class SupportItem{
        public String supportCode {get;set;}
        public String supportNumber {get;set;}
        public String description {get;set;}
        public Decimal quantity {get;set;}
        public String unitPrice {get;set;}
        public Boolean disableProductLookup {get;set;}
        public Boolean productLookupPopulated {get;set;}
        //public Integer _id {get;set;}
        public String dateFrom {get;set;}
        public String dateFromConverted {get;set;}
        public String dateTo {get;set;}
        public String dateToConverted {get;set;}
        public String supportId {get;set;}
        public Boolean isExpanded {get;set;}
        public Boolean inAccordian {get;set;}
    }
}