/**
 * @description  [TTP-2396] This class will send Spending SMS to Clients using Twilio API
 * @company      Cloudwerx
 * @date         22/02/2022
 * @testClass    NDIA_SpendingSMSNotificationBatchTest
**/

public with sharing class NDIA_SpendingSMSNotificationBatchHelper {

    /**
     * @description      Method to query PlanSupport__c  records
     * @author           Sonali Takke
     * @return           String soql query to fetch PlanSupport__c records
    **/
    public static String getPlanSupportQuery() {
        return (
              'SELECT Id, Plan__r.Client_Name__c, Client__c, SpentPercentage__c, Name,' 
            + ' TotalFundsRemaining__c, Plan__r.Plan_End_Date__c, SpendingSMS51__c, SpendingSMS80__c,'
            + ' SpendingSMS85__c, SpendingSMS90__c, SpendingSMS95__c, Planmanager__c '
            + 'FROM PlanSupport__c '
            + 'WHERE (Plan__r.Client_Name__r.Salesforce_Claiming_Experience__c = true) AND ' // [OPSNBOTS-47] Added SCE filter
            + '(SupportCategoryNumber__c NOT IN (1, 3, 4, 14)) AND ('+     // [AHOD-319] Added SupportCategoryNumber filter
            + ' (SpentPercentage__c >= 51 AND SpentPercentage__c < 80 AND SpendingSMS51__c = false) OR '
            + ' (SpentPercentage__c >= 80 AND SpentPercentage__c < 85 AND SpendingSMS80__c = false) OR '
            + ' (SpentPercentage__c >= 85 AND SpentPercentage__c < 90 AND SpendingSMS85__c = false) OR '
            + ' (SpentPercentage__c >= 90 AND SpentPercentage__c < 95 AND SpendingSMS90__c = false) OR '
            + ' (SpentPercentage__c >= 95 AND SpendingSMS95__c = false) '
            + ')'
        );
    }
    
    /**
     * @description      Identify Contacts who are primary and opted in for SMS Notification
     * @author           Sonali Takke
     * @param            clientIds : List of account Id
     * @return           Map<Id,String> : Map of Account and associated Phone number
    **/
    public static  Map<Id,List<Contact>> getFilteredClients(Set<Id> clientIds) {
        Map<Id,List<Contact>> accountIdVscontactListMap = new Map<Id,List<Contact>>();
        for (AccountContactRelation acr : [
            SELECT Id, Contact.FirstName, Contact.LastName, Contact.MobilePhone, AccountId, 
                    Primary_Contact__c, Account.PersonContactId
            FROM AccountContactRelation 
            WHERE SMS_Notification__c = TRUE AND AccountId IN :clientIds AND 
                  Contact.MobilePhone != null AND Primary_Contact__c = TRUE
        ]) {
            Contact primaryContact = new Contact(
                Id = acr.Contact.Id,
                FirstName = acr.Contact.FirstName, 
                LastName = acr.Contact.LastName,
                MobilePhone = acr.Contact.MobilePhone,
                ReportsToId  = acr.Account.PersonContactId //Since no DML on this contact added as Placeholder to store personAccountId
            );
            if(accountIdVscontactListMap.containsKey(acr.AccountId)) {
                List<Contact> contactList = accountIdVscontactListMap.get(acr.AccountId);
                contactList.add(primaryContact); 
                accountIdVscontactListMap.put(acr.AccountId, contactList);
            } else {
                accountIdVscontactListMap.put(acr.AccountId, new List<Contact>{primaryContact});
            }
        }
        return accountIdVscontactListMap;
    }

    /**
     * @description      Method to replace merge fields in SMS Body
     * @author           Sonali Takke
     * @param            smsBody        : SMS Body from Metadata
     *                   inv            : Invoice Record
     *                   contactName    : Primary Contact Name
     * @return           SMS Body 
    **/
    public static String replaceMergeFields(String smsBody, Contact contactRecord, PlanSupport__c support) {
        smsBody = smsBody.replace('<CLIENTNAME>',contactRecord.FirstName+' '+contactRecord.LastName);
        smsBody = smsBody.replace('<PERCENTAGE>',string.valueOf(support.SpentPercentage__c));
        smsBody = smsBody.replace('<BUDGETNAME>',support.Name);
        smsBody = smsBody.replace('<REMAININGAMOUNT>',string.valueOf(support.TotalFundsRemaining__c));
        smsBody = smsBody.replace('<PLANENDDATE>',string.valueOf(support.Plan__r?.Plan_End_Date__c));
        return smsBody;
    }

     /**
     * @description      Method performs callout using Twilio API to send the SMS to primary contacts
     * @author           Sonali Takke
     * @param            twilioConfig : Metadata
     *                   mobilePhone : Mobile Number of Primary Contact
     *                   smsBody : SMS Body
     * @return           wrapper object which contains the result of the API request
    **/
    public static APIService.HTTPWire performCallOut(Twilio_API_Configuration__mdt twilioConfig, String mobilePhone, String smsBody) {
        String endPointURL = twilioConfig.Endpoint_URL__c + '/' + twilioConfig.Account_SID__c + '/Messages.json';
        Blob headerValue = Blob.valueOf(twilioConfig.Account_SID__c+ ':' + twilioConfig.Authorization_Token__c);
        // body fomation in urlEncoded form
        String body = 'To='+EncodingUtil.urlEncode(mobilePhone,'UTF-8')+'&From='+twilioConfig.From_Number__c + '&Body='+EncodingUtil.urlEncode(smsBody,'UTF-8');

        // TWILIO CALLOUT
        APIService.HTTPWire result = APIService.performPost (
            endPointURL, 2000, '', '', body, 
            new Map <String,String>{
                'Content-Type' => 'application/x-www-form-urlencoded', 
                'Authorization' => 'BASIC ' + EncodingUtil.base64Encode(headerValue)
            }
        );
        return result;
    }

    /**
     * @description      Method creates & return a wrapper object
     * @author           Sonali Takke
     * @param            planSupportRecord : Plan Support record
     * @return           NDIA_SpendingSMSNotificationBatch.planSupportWrapper wrapper object
    **/

    public static NDIA_SpendingSMSNotificationBatch.planSupportWrapper createPlanSupportWrapper(PlanSupport__c planSupportRecord ) {
        NDIA_SpendingSMSNotificationBatch.planSupportWrapper wrap = new NDIA_SpendingSMSNotificationBatch.planSupportWrapper();
        wrap.planSupport = planSupportRecord;
        wrap.AccountId = planSupportRecord.Plan__r?.Client_Name__c;
        wrap.SpendingSMS = 
            (planSupportRecord.SpentPercentage__c >= 51 && planSupportRecord.SpentPercentage__c < 80 && 
                planSupportRecord.SpendingSMS51__c == false) ? 'SpendingSMS51' :
            (planSupportRecord.SpentPercentage__c >= 80 && planSupportRecord.SpentPercentage__c < 85 && 
                planSupportRecord.SpendingSMS80__c == false) ? 'SpendingSMS80':
            (planSupportRecord.SpentPercentage__c >= 85 && planSupportRecord.SpentPercentage__c < 90 && 
                planSupportRecord.SpendingSMS85__c == false) ? 'SpendingSMS85' :
            (planSupportRecord.SpentPercentage__c >= 90 && planSupportRecord.SpentPercentage__c < 95 && 
                planSupportRecord.SpendingSMS90__c == false)? 'SpendingSMS90' :
            (planSupportRecord.SpentPercentage__c >= 95 && 
                planSupportRecord.SpendingSMS95__c == false) ? 'SpendingSMS95' : '';
        return wrap;
    }
    
    /**
     * @description      Send email after batch is completed
     * @author           Sonali Takke
     * @param            BC : List of account Id
     *                   count : Number of Records Processed by batch
    **/
    public static void sendEmail(Database.BatchableContext BC, Integer count) {
         //Attributes used for Email
         List <String> listOfUserEmail = new List <String>();
         List <String> ccAddress = new List <String>();
         
         //Get Batch Job information
         AsyncApexJob asyncJob = [Select Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
                                  from AsyncApexJob where Id =:BC.getJobId()];   
         
         //Get user who schedule                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               d the batch
         List <User> listOfUsers = [SELECT Id,Email,Name from User WHERE id = :UserInfo.getUserId() LIMIT 1];
         
         //Get list of users to send email
         for (User u: listOfUsers){
             listOfUserEmail.add(u.Email);
         }
         
         //Get MPM outlook email 
         ccAddress.add(System.label.mpm_outlook_email);
         
         //Send Email to the user who Scheduled the batch and to mpm outlook mailbox
        Utils.sendBatchConfirmationEmail(asyncJob, listOfUserEmail, ccAddress, count, 'Spending SMS Notification Batch'); 
    }

    /**
     * @description      [AHOD-394] Method to query Plan__c  records
     * @author           Mehul Shah
     * @return           String soql query to fetch Plan__c records
    **/
    public static String getPlanQuery() {
        return (
              'SELECT Id, Client_Name__c, CoreSpentPercentage__c, Name, TotalFundsRemaining__c, Plan_End_Date__c, ' 
            + 'CoreSpendingSMS51__c, CoreSpendingSMS80__c, CoreSpendingSMS85__c, CoreSpendingSMS90__c, CoreSpendingSMS95__c, Planmanager__c '
            + 'FROM Plan__c '
            + 'WHERE (Client_Name__r.Salesforce_Claiming_Experience__c = true) AND (' +   // [OPSNBOTS-47] Added SCE filter
            + '(CoreSpentPercentage__c >= 51 AND CoreSpentPercentage__c < 80 AND CoreSpendingSMS51__c = false) OR '
            + '(CoreSpentPercentage__c >= 80 AND CoreSpentPercentage__c < 85 AND CoreSpendingSMS80__c = false) OR '
            + '(CoreSpentPercentage__c >= 85 AND CoreSpentPercentage__c < 90 AND CoreSpendingSMS85__c = false) OR '
            + '(CoreSpentPercentage__c >= 90 AND CoreSpentPercentage__c < 95 AND CoreSpendingSMS90__c = false) OR '
            + '(CoreSpentPercentage__c >= 95 AND CoreSpendingSMS95__c = false)'
            + ')'
        );
    }

    /**
     * @description      [AHOD-394] Method creates & return a wrapper object
     * @author           Mehul Shah
     * @param            planRecord : Plan record
     * @return           NDIA_CoreSpendingSMSNotificationBatch.PlanWrapper wrapper object
    **/

    public static NDIA_CoreSpendingSMSNotificationBatch.PlanWrapper createPlanWrapper(Plan__c planRecord) {
        NDIA_CoreSpendingSMSNotificationBatch.PlanWrapper wrap = new NDIA_CoreSpendingSMSNotificationBatch.PlanWrapper();
        wrap.plan = planRecord;
        wrap.AccountId = planRecord.Client_Name__c;
        wrap.SpendingSMS = 
            (planRecord.CoreSpentPercentage__c >= 51 && planRecord.CoreSpentPercentage__c < 80 && 
                planRecord.CoreSpendingSMS51__c == false) ? 'SpendingSMS51' :
            (planRecord.CoreSpentPercentage__c >= 80 && planRecord.CoreSpentPercentage__c < 85 && 
                planRecord.CoreSpendingSMS80__c == false) ? 'SpendingSMS80':
            (planRecord.CoreSpentPercentage__c >= 85 && planRecord.CoreSpentPercentage__c < 90 && 
                planRecord.CoreSpendingSMS85__c == false) ? 'SpendingSMS85' :
            (planRecord.CoreSpentPercentage__c >= 90 && planRecord.CoreSpentPercentage__c < 95 && 
                planRecord.CoreSpendingSMS90__c == false) ? 'SpendingSMS90' :
            (planRecord.CoreSpentPercentage__c >= 95 && 
                planRecord.CoreSpendingSMS95__c == false) ? 'SpendingSMS95' : '';
        return wrap;
    }

    /**
     * @description      [AHOD-394] Method to replace merge fields in SMS Body
     * @author           Mehul Shah
     * @param            smsBody        : SMS Body from Metadata
     *                   contactName    : Primary Contact Name
     *                   plan           : Plan record
     * @return           String - SMS Body 
    **/
    public static String replaceMergeFields(String smsBody, Contact contactRecord, Plan__c plan) {
        smsBody = smsBody.replace('<CLIENTNAME>', contactRecord.FirstName + ' ' + contactRecord.LastName);
        smsBody = smsBody.replace('<PERCENTAGE>', string.valueOf(plan.CoreSpentPercentage__c));
        smsBody = smsBody.replace('<BUDGETNAME>', System.Label.Core_Budget_Name);
        smsBody = smsBody.replace('<REMAININGAMOUNT>', string.valueOf(plan.TotalFundsRemaining__c));
        smsBody = smsBody.replace('<PLANENDDATE>', string.valueOf(plan.Plan_End_Date__c));
        return smsBody;
    }
}