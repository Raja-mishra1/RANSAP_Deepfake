/**
 * @description  [TTP-1502]This batch is used to validate and update ABN fields on Account
 * @company      Cloudwerx
 * @date         19/10/2021
 * @testclass    ABN_WeeklyABNValidatorBatchTest
**/
global class ABN_WeeklyABNValidatorBatch  implements Database.Batchable<sObject>, Schedulable, Database.stateful, Database.AllowsCallouts {
    
    //Initializing metadata
    public static final Integer SCOPE_SIZE = ABRService.ABN_BATCH_SCOPE_SIZE;

    //Initializing attributes
    Integer count=0;
    
    //Constructor
    global void execute (SchedulableContext sc) {

        //Submit a batch to Async Framework
        //AsyncApexFramework.submitBatch(new ABN_WeeklyABNValidatorBatch(), SCOPE_SIZE, 99);
        //AsyncApexFramework.flush(); 

        //Normal Run
        ABN_WeeklyABNValidatorBatch b = new ABN_WeeklyABNValidatorBatch(); 
        AsyncApexFramework.submitBatch(b,SCOPE_SIZE,99);
        AsyncApexFramework.flush();    
    }

    global Database.QueryLocator start (Database.BatchableContext BC) {

        //Fetching Record type Id
        String providerRecordTypeId = RecordTypeUtil.PROVIDER_ACCOUNT_RECORD_TYPE_ID;
        String prospectRecordTypeId = RecordTypeUtil.PROSPECT_ACCOUNT_RECORD_TYPE_ID;
        //Creating query
        String 	query =  'SELECT Id, Name, Exclude_from_ABN_Validator_Clean_up__c, Provider_Name_Updated_by_ABN_Validator_S__c, ABN__c, Status__c, Invoice_Instructions__c FROM Account ';        
                query += 'WHERE ABN__c != null '; 
        		query += 'AND (RecordTypeId = :providerRecordTypeId ';  //Add this condition RecordType provider and prospect
        		query += 'OR RecordTypeId = :prospectRecordTypeId) ';

        return Database.getQueryLocator(query);
    }

    global void execute (Database.BatchableContext BC, List<Account> recordsList) {
        //Initializing attributes
        String description = null;
        //Initializing collections
        List<Account> accountsToUpdate = new List<Account>();

        try {        

            //Iterate over account records
            for (Account account : recordsList) {

                //ABN Callout
                    String abnLookupResponseString = JSON.serialize(ABRService.ABNLookup(account.ABN__c));
                    //Creating Account list that consist ABN information to update
                    accountsToUpdate.add(ABNValidatorController.saveABNInformation(account,abnLookupResponseString));

                
            }
           	
            //Update account
            Database.SaveResult[] srList = Database.update(accountsToUpdate, false); //updating account
            for (Integer i = 0; i < accountsToUpdate.size(); i++) {
                Database.SaveResult sr = srList[i]; //Get updated result
                Account recId = accountsToUpdate[i]; //Get record Id
                if (sr.isSuccess()) { //If success increase count
                    count++;
                } else {  
                    for (Database.Error err : sr.getErrors()) { //If error append error message in description field for each error record
                        description =   description == null 
                                    ? String.valueOf(err.getStatusCode() + ': ' + err.getMessage() + '\n' +'For record :'+recId.Id)+'\n' 
                                    : description + String.valueOf(err.getStatusCode() + ': ' + err.getMessage() + '\n' +'For record :'+recId.Id)+'\n';   
                    }   
                } 
            }
            
            //Platform Event published to insert batch error log
            if (description != null) {
                EventLog__e evt =  LogService.logSaveResult('ABN_WeeklyABNValidatorBatch','Execute',description,String.valueOf(BC.getJobId()), '',''); 
                LogService.insertLog(new List<EventLog__e>{evt});
            } 


        } catch (Exception e) {
           LogService.insertLog(new List<EventLog__e>{ LogService.logSaveResult('ABN_WeeklyABNValidatorBatch','Execute',e.getMessage(),String.valueOf(BC.getJobId()), '', '')});
        }
    }

    global void finish(Database.BatchableContext BC) {
        //Attributes used for Email
        List <String> listOfUserEmail = new List <String>();
        List <String> ccAddress = new List <String>();
        
        //Get Batch Job information
        AsyncApexJob asyncJob = [Select Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
                                 from AsyncApexJob where Id =:BC.getJobId()];   
        
        //Get user who scheduled the batch
        List <User> listOfUsers = [SELECT Id,Email,Name from User WHERE id = :UserInfo.getUserId() LIMIT 1];
        
        //Get list of users to send email
        for (User u: listOfUsers){
            listOfUserEmail.add(u.Email);
        }
        
        //Get MPM outlook email 
        ccAddress.add(System.label.mpm_outlook_email);
        
        //Send Email to the user who Scheduled the batch and to mpm outlook mailbox
        Utils.sendBatchConfirmationEmail(asyncJob,listOfUserEmail,ccAddress,count,'ABN Weekly Validator for Accounts'); 
    }
}