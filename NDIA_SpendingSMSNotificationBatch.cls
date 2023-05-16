/**
 * @description  [TTP-2396] This class will send Spending SMS to Clients using Twilio API
 * @company      Cloudwerx
 * @date         22/02/2022
 * @testClass    NDIA_SpendingSMSNotificationBatchTest
**/

global with sharing class NDIA_SpendingSMSNotificationBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.stateful {
    Integer count = 0;

    /**
     * @description      Start Method to query PlanSupport__c  records
     * @author           Sonali Takke
     * @param            context : Batch context
     * @return           Database.QueryLocator : PlanSupport__c Records
    **/
    global Database.QueryLocator start (Database.BatchableContext BC) {
            
		return Database.getQueryLocator(NDIA_SpendingSMSNotificationBatchHelper.getPlanSupportQuery());
    }

    /**
     * @description      Execute method to send SMS & update PlanSupport__c object
     * @author           Sonali Takke
     * @param            context : Batch context
     * @return           planSupportList : List Of PlanSupport__c Records
    **/
    global void execute (Database.BatchableContext BC, List<PlanSupport__c> planSupportList) { 
        try {
            Map<Id,PlanSupport__c> planSupportupdateMap = new Map<Id,PlanSupport__c>();
            Map<Id,List<Contact>> accountIdVscontactListMap = new Map<Id,List<Contact>>();
            List<planSupportWrapper> wrapperList = new List<planSupportWrapper>();
            List<EventLog__e> responseLogs  = new List<EventLog__e>();
            List<Task> taskList = new List<Task>();
            Set<Id> clientIds = new Set<Id>();
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
    
            //Retrive Twilio_API_Configuration__mdt data from custom metadata record
            Twilio_API_Configuration__mdt twilioConfigMPM;
            Twilio_API_Configuration__mdt twilioConfigNDSP;
            for(Twilio_API_Configuration__mdt twilioConfig : [SELECT Id, DeveloperName, Send_SMS__c,
                                                             SMS_Body__c, SMS_Subject__c, 
                                                             Endpoint_URL__c, Account_SID__c, 
                                                             Authorization_Token__c, From_Number__c 
                                                             FROM Twilio_API_Configuration__mdt 
                                                             WHERE DeveloperName =: 'TwilioConfig_4' 
                                                             OR DeveloperName =: 'NDSP_TwilioConfig_4'
                                                             ]){
               if(twilioConfig.DeveloperName == 'TwilioConfig_4'){
                 twilioConfigMPM = twilioConfig;
               }
               else if(twilioConfig.DeveloperName == 'NDSP_TwilioConfig_4'){
                 twilioConfigNDSP = twilioConfig;
               }                                                   

             }
    
            //Iterate over planSupportList to group records based on SpentPercentage__c
            for (PlanSupport__c planSupportRecord : planSupportList) {
                planSupportWrapper wrap = NDIA_SpendingSMSNotificationBatchHelper.createPlanSupportWrapper(planSupportRecord);
                if(String.isNotEmpty(wrap.SpendingSMS)) {
                    wrapperList.add(wrap);
                    clientIds.add( wrap.AccountId);
                }
            }
            
            //Identify the primary contact’s mobile who has not opted from SMS notifications
            if(!clientIds.isEmpty()) {
                accountIdVscontactListMap = NDIA_SpendingSMSNotificationBatchHelper.getFilteredClients(clientIds);
            }
    
            //Iterate over wrapper to get data for Callout
            for (planSupportWrapper wrap : wrapperList) {
                HttpResponse response;
                APIService.HTTPWire result;
                Twilio_API_Configuration__mdt twilioConfig = 
                wrap.planSupport.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ? twilioConfigMPM : twilioConfigNDSP;
                Id taskOwnerId = wrap.planSupport.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ? MPM_IT_USER_ID : NDSP_IT_USER_ID;
                if ((twilioConfig.Send_SMS__c || Test.isRunningTest()) && 
                    accountIdVscontactListMap.containsKey(wrap.AccountId)) {  
                    //Iterate over assciated contacts to send SMS
                    for(Contact contactRecord : accountIdVscontactListMap.get(wrap.AccountId)) {
                        //Replace merge field and generate smsBody
                        String smsBody = NDIA_SpendingSMSNotificationBatchHelper.replaceMergeFields(
                            twilioConfig.SMS_Body__c, contactRecord, wrap.planSupport
                        );

                        //Callout to twilio api
                        result = NDIA_SpendingSMSNotificationBatchHelper.performCallOut(twilioConfig, contactRecord.MobilePhone, smsBody); 
                        response = result.response;

                        //Process response
                        if(response?.getStatusCode() == 201) {
                            //Add a task record 
                            String subject  = twilioConfig.SMS_Subject__c;
                            subject = subject.replace('<CONTACT_MOBILE>', contactRecord.MobilePhone);
                            subject = subject.replace('<DATE>', Date.today().format());
                            taskList.add( TTPUtil.createTask( 
                                subject, 'Completed', smsBody, taskOwnerId, wrap.planSupport.Id, contactRecord.ReportsToId
                            ));
                        } 
                    }
                }
            
                    //UPDATE the Budget record SpendingSMSxx__c checkboxes = TRUE
                if (!twilioConfig.Send_SMS__c || response?.getStatusCode() == 201) { //SUCCESS
                    if(wrap.SpendingSMS == 'SpendingSMS51') {
                        wrap.planSupport.SpendingSMS51__c = true;
                    }
                    if(wrap.SpendingSMS == 'SpendingSMS80') {
                        wrap.planSupport.SpendingSMS80__c = true;
                    }
                    if(wrap.SpendingSMS == 'SpendingSMS85') {
                        wrap.planSupport.SpendingSMS85__c = true;
                    }
                    if(wrap.SpendingSMS == 'SpendingSMS90') {
                        wrap.planSupport.SpendingSMS90__c = true;
                    }
                    if(wrap.SpendingSMS == 'SpendingSMS95') {
                        wrap.planSupport.SpendingSMS95__c = true;
                    }
                    planSupportupdateMap.put(wrap.planSupport.Id,wrap.planSupport);
                } else {             
                    if(response != null) {        
                        //In case of API failure with a status other than 201, create a log via the Logging framework
                        String responseBody = response.getBody().trim();
                        EventLog__e evt = LogService.logCallout(
                            'NDIA_SpendingSMSNotificationBatch','execute','NDIS SMS NOTIFICATION',result?.request,response,'Error'
                        );
                        evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                        responseLogs.add(evt);
                    }
                }
                count++; //increment counter for email purpose
            }
            
    
            Database.SaveResult[] planSupportUpdateResult = Database.update(planSupportupdateMap.values(),false);
    
            //In case of DML failure, create a log via the Logging framework
            if (planSupportUpdateResult != null && !planSupportUpdateResult.isEmpty()) {
                for (Integer index = 0, size = planSupportUpdateResult.size(); index < size; index++) {
                    if (!(planSupportUpdateResult[index]?.isSuccess())) {
                        for (Database.Error error: planSupportUpdateResult[index]?.getErrors()) {
                            EventLog__e evt = LogService.logSaveResult(
                                'NDIA_SpendingSMSNotificationBatch','execute', json.serialize(error),BC.getJobId(),'',''
                            );
                            responseLogs.add(evt);
                        }
                    }
                }
            }
    
            if(!taskList.isEmpty()) {
                insert taskList;
            }
            if (!responseLogs.isEmpty()) {
                LogService.insertLog(responseLogs); 
            }

        } catch(Exception e) {
            EventLog__e event = LogService.logSaveResult(
                'NDIA_SpendingSMSNotificationBatch', 
                'execute', 
                'Error: '+ e, '', '', '');
                LogService.insertLog(new List<EventLog__e>{event});
        }
       
        
    }

    
    /**
     * @description  Batch finish method to perform post processing logic
     * @author       Sonali Takke
     * @param        BC : batchable instance
    **/
    global void finish (Database.BatchableContext BC) {
        NDIA_SpendingSMSNotificationBatchHelper.sendEmail(BC,count);
    }

    /**
     * @description  Wrapper class for account, associated plansupport & SpendingSMS category 
    **/
    public class planSupportWrapper {
        public String SpendingSMS;
        public Id AccountId;
        public PlanSupport__c planSupport;
    }
}