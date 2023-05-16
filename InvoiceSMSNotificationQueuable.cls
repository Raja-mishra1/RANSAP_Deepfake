/**
 * @description     [TTP-2389/2598/2599/2601] Queuable Class Invoked via Flow to Send SMS Notification To Primary Contacts of Clients on Invoice
 * @company         Cloudwerx
 * @date            22/02/2022
 * @testClass       InvoiceSMSNotificationQueuableTest
**/

public without sharing class InvoiceSMSNotificationQueuable implements Queueable, Database.AllowsCallouts {

    private List<Invoice__c> invoiceList;
    private static Boolean isSMSSent = false;  // [TFR-233] : To track if SMS is sent out

    public InvoiceSMSNotificationQueuable(List<Invoice__c> invoiceList) {
        this.invoiceList = invoiceList;
    }

    /**
     * @description      Method to process the invoices received from the flow and send SMS Notification to Primary Contacts
     * @author           Sonali Bhat
     * @param            context  : QueueableContext
    **/
    public void execute(QueueableContext context) {
        try {
            Set<Id> clientIdSet = new Set<Id>();
            Map<Id, List<Contact>> accountIdVsContactMap = new Map<Id, List<Contact>>();
            List<EventLog__e> errorLogs  = new List<EventLog__e>();
            List<Task> taskList = new List<Task>();
            
            // Get Task Owner Id
            Id MPM_IT_USER_ID;
            Id NDSP_IT_USER_ID;
           
            for( User objUser : [SELECT Id, Email FROM User 
                                WHERE Email = :System.Label.MPM_IT_USER_EMAIL_ID
                                OR Email = :System.Label.NDSP_IT_USER_EMAIL_ID ] ){
               if( ObjUser.Email == System.Label.MPM_IT_USER_EMAIL_ID ){
                MPM_IT_USER_ID = objUser.Id ;
               }
               else if( ObjUser.Email == System.Label.NDSP_IT_USER_EMAIL_ID ){
                NDSP_IT_USER_ID = objUser.Id ;
               }                         
            }
            
            // Get Metadata
            Twilio_API_Configuration__mdt twilioConfigMPM;
            Twilio_API_Configuration__mdt twilioConfigNDSP;
            for(Twilio_API_Configuration__mdt twilioConfig : [SELECT Id, DeveloperName, Send_SMS__c,
                                                             SMS_Body__c, SMS_Subject__c, 
                                                             Endpoint_URL__c, Account_SID__c, 
                                                             Authorization_Token__c, From_Number__c 
                                                             FROM Twilio_API_Configuration__mdt 
                                                             WHERE DeveloperName =: 'TwilioConfig_3' 
                                                             OR DeveloperName =: 'NDSP_TwilioConfig_3'
                                                             ]){
               if(twilioConfig.DeveloperName == 'TwilioConfig_3'){
                 twilioConfigMPM = twilioConfig;
               }
               else if(twilioConfig.DeveloperName == 'NDSP_TwilioConfig_3'){
                 twilioConfigNDSP = twilioConfig;
               }                                                   

             }

            for (Invoice__c inv : this.invoiceList) {
                if (inv.Client__c != NULL) {
                    clientIdSet.add(inv.Client__c); // add client Ids
                }
            }
            
            /* Loop over the AccountContactRelation which are marked as primary and 
                opted in for SMS Notification*/
            for (AccountContactRelation accConRel : [
                SELECT Account.Name, AccountId, ContactId, Contact.MobilePhone, Contact.Name
                FROM AccountContactRelation 
                WHERE SMS_Notification__c = TRUE 
                    AND AccountId IN :clientIdSet 
                    AND Contact.MobilePhone != NULL
                    AND Primary_Contact__c = TRUE
            ]) {
                // prepare contact record, mapped LastName with Name as Name field is not writeable and we are not performing any dml on it
                Contact contact = new Contact(
                    Id = accConRel.ContactId, 
                    LastName = accConRel.Contact.Name, 
                    MobilePhone = accConRel.Contact.MobilePhone
                );

                if (accountIdVsContactMap.containsKey(accConRel.AccountId)) {
                    accountIdVsContactMap.get(accConRel.AccountId).add(contact);
                } else {
                    accountIdVsContactMap.put(accConRel.AccountId, new List <Contact>{contact});
                }
            }

            if (!accountIdVsContactMap.isEmpty()) {
                for (Invoice__c inv : this.invoiceList) {
                    if (accountIdVsContactMap.containsKey(inv.Client__c)) {
                        List<Contact> contactList = accountIdVsContactMap.get(inv.Client__c);
                        sendNotification(inv,contactList,
                                        inv.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ?
                                        twilioConfigMPM : twilioConfigNDSP,errorLogs, taskList, 
                                        inv.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ? 
                                        MPM_IT_USER_ID : NDSP_IT_USER_ID); 
                    }
                }

                // [TFR-233] Update invoices only if SMS is sent out & list is not empty
                if (isSMSSent && !this.invoiceList.isEmpty()) {
                    update invoiceList;
                }

                if (!errorLogs.isEmpty()) {
                    LogService.insertLog(errorLogs);  // insert logs
                }
                if (!taskList.isEmpty()) {  // insert tasks
                    insert taskList;
                }
            }
        } catch(Exception e) {
            EventLog__e event = LogService.logSaveResult(
                'InvoiceSMSNotificationQueuable', 
                'execute', 
                'Error: '+ e, '', '', '');
                LogService.insertLog(new List<EventLog__e>{event});
        }
    }

    /**
     * @description      Method to call the callout method and create a task on successful callout and log for a failure
     * @author           Sonali Bhat
     * @param            inv                : Invoice record
     *                   contactList        : Contact list
     *                   twilioConfig       : Metadata
     *                   errorLogs          : Empty List of Log
     *                   taskList           : Empty List of task
     *                   ownerId            : Id of MPM IT User
    **/
    public static void sendNotification(
        Invoice__c inv, List<Contact> contactList, 
        Twilio_API_Configuration__mdt twilioConfig, 
        List<EventLog__e> errorLogs, List<Task> taskList, Id ownerId
    ) {
        for (Contact contact : contactList) {

            if (twilioConfig.Send_SMS__c || Test.isRunningTest()) { // [TFR-233] - Added to check if Twilio setting is on to send SMS
            String smsBody = replaceMergeFields(twilioConfig.SMS_Body__c, inv, contact.LastName); // replace merge fields in sms body
            APIService.HTTPWire result = performCallOut(twilioConfig, contact.MobilePhone, smsBody); // callout to twilio api

            HttpResponse response = result.response;

            if (response?.getStatusCode() == 201) {
                // callout is successful
                String subject = twilioConfig.SMS_Subject__c;
                subject = subject.replace('<CONTACT_MOBILE>',contact.MobilePhone);
                subject = subject.replace('<DATE>', Date.today().format());
                // create task
                Task taskObj = TTPUtil.createTask(subject,'Completed',smsBody,ownerId,inv.Id,inv.Client__r?.PersonContactId);
                taskList.add(taskObj);

                inv.InvoiceSubmittedSMSSent__c = true;  // [TFR-233] mark the SMS field as true
                isSMSSent = true;   // [TFR-233] Mark as true as SMS is sent successfully
            } else { 
                // callout failed, create a log
                EventLog__e event = LogService.logCallout(
                    'InvoiceSMSNotificationQueuable', 'sendNotification', 'SMS Send Failed for Invoice :  '+ inv.Name+ ' while sending SMS to Contact Number: '+contact.MobilePhone, result?.request,result?.response,'Error');
                errorLogs.add(event);
                }
            }
        }
    }

    /**
     * @description      Method to replace merge fields in SMS Body
     * @author           Sonali Bhat
     * @param            smsBody        : SMS Body from Metadata
     *                   inv            : Invoice Record
     *                   contactName    : Primary Contact Name
     * @return           SMS Body 
    **/
    public static String replaceMergeFields(String smsBody, Invoice__c inv, String contactName) {
        smsBody = smsBody.replace('<Receiver_Name>', contactName);
        smsBody = smsBody.replace('<Provider_Name__c>',inv.Provider_Name__c);
        smsBody = smsBody.replace('<Reference_Number__c>',inv.Reference_Number__c);
        smsBody = smsBody.replace('<Total__c>', '$'+String.valueOf(inv.Total__c));
        smsBody = smsBody.replace('<Support_Start_Date__c>', String.valueOf(inv.Support_Start_Date__c.format()));
        smsBody = smsBody.replace('<Support_End_Date__c>', String.valueOf(inv.Support_End_Date__c.format()));
        smsBody = smsBody.replace('<Client__r.Name>',inv.Client__r.Name);
        String MaskedNDIS = inv.Client__r.NDIS__c.left(2) + 'XXXX' + inv.Client__r.NDIS__c.right(3) ;
        smsBody = smsBody.replace('<Client__r.NDIS__c>',MaskedNDIS);
        return smsBody;
    }
     
    /**
     * @description      Method performs callout using Twilio API to send the SMS to primary contacts
     * @author           Sonali Bhat
     * @param            twilioConfig : Metadata
     *                   mobilePhone : Mobile Number of Primary Contact
     *                   smsBody : SMS Body
     * @return           wrapper object which contains the result of the API request
    **/
    public static APIService.HTTPWire performCallOut(Twilio_API_Configuration__mdt twilioConfig, String mobilePhone, String smsBody) {
        String endPointURL = twilioConfig.Endpoint_URL__c+'/'+twilioConfig.Account_SID__c+'/Messages.json';
        Blob headerValue = Blob.valueOf(twilioConfig.Account_SID__c+ ':' + twilioConfig.Authorization_Token__c);
        APIService.HTTPWire result;
        
        // body fomation in urlEncoded form
        String body = 'To='+EncodingUtil.urlEncode(mobilePhone,'UTF-8')+'&From='+twilioConfig.From_Number__c + '&Body='+EncodingUtil.urlEncode(smsBody,'UTF-8');

        // TWILIO CALLOUT
        result = APIService.performPost (
            endPointURL, 2000, '', '', body, 
            new Map <String,String>{
                'Content-Type' => 'application/x-www-form-urlencoded', 
                'Authorization' => 'BASIC ' + EncodingUtil.base64Encode(headerValue)
            }
        );
        return result;
    }
}