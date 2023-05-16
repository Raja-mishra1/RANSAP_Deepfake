/**
 * @description     A batch runs 6 AM everyday to create Case when Plan End Date ends a day before.
                    Custom settings 'Reconnect Auto Case Create Settings' drives the Case's static field value
 * @company         Cloudwerx
 * @date            19/05/2020
**/
 global class AutoCreateExpiredCaseBatchClass implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    
    private final static Reconnect_Auto_Case_Create_Settings__c reConnectAutoCase = Reconnect_Auto_Case_Create_Settings__c.getInstance();
    private Set <String> setOfFields;
    public Integer count;
    
    public AutoCreateExpiredCaseBatchClass() {
        setOfFields = new Set <String>();
        setOfFields = returnFields();
        
        count = 0;
    }
    global void execute(SchedulableContext sc) {
        AutoCreateExpiredCaseBatchClass b = new AutoCreateExpiredCaseBatchClass(); 
        AsyncApexFramework.submitBatch(b,200,99);
        AsyncApexFramework.flush();
    }
    
    /**
     * @description   Sprint 18 [SFDC-1268] Query is updated on account instead of plan 
     *                because we were not able associate latest expired plan on the case 
     *                even ordered by desc.
    **/
    global Database.QueryLocator start(Database.BatchableContext BC) {   
        String query = 'SELECT Id, (SELECT Id, Name, Client_Name__C, Client_Name__r.Name, Plan_Start_Date__C, Plan_End_Date__C, Active__C, PlanManager__c from Plans__r ORDER BY Plan_End_Date__C DESC), ';
        query += 'Pod__c, Pod__r.Pod_Skill_New__c, PlanManager__c, (SELECT Id, ContactId, Primary_Contact__c, AccountId FROM AccountContactRelations WHERE IsActive = true) '; //Sprint 18 [SFDC-1268] removed SOQL query from execute and added here.
        for (String field : setOfFields) {
            query += ' ,'+ field + ' '; // Name.
        } 
        query += 'FROM Account ';
        query += 'WHERE Status__c = \'ACTIVE\' AND (RecordType.Name = \'Client\' Or  RecordType.Name = \'Restricted Client\')'; //Pick all Active and Client Accounts.
        return Database.getQueryLocator(query);
    }
      
    global void execute(Database.BatchableContext BC, List <Account> listOfAccounts) {   
        Map <Id, Plan__c> mapOfClientIdVsLatestExpiredPlan = new Map <Id, Plan__c>();
        Map <Id, Account> mapOfClientRecords = new Map <Id, Account>(listOfAccounts);
        Set <Id> setOfClientIdWithExistingCase = new Set <Id>();
        List <Case> listOfCasesToInsert = new List <Case>();
        //Sprint-6 [BT-561] Start
        Map<Id, Id> clientContactMap = new Map<Id, Id>(); 
        List<Id> primaryContactList;
        List<AccountContactRelation> varACRList = new List<AccountContactRelation>();
        //Sprint-6 [BT-561] End
        //Sprint 18 [SFDC-1268]
        for (Account clientRecord : listOfAccounts) {
            if (!clientRecord.plans__r.isEmpty()) {
                if (!clientRecord.plans__r[0].Active__c) { // Exclude Clients with active plan.
                    mapOfClientIdVsLatestExpiredPlan.put(clientRecord.Id , clientRecord.plans__r[0]);
                    //Sprint-6 [BT-561] Start
                    if (clientRecord.AccountContactRelations.size() > 1) {
                        primaryContactList = new List<Id>();
                        varACRList = clientRecord.AccountContactRelations;
                        for (AccountContactRelation acrRecord : varACRList) {
                            if (acrRecord.Primary_Contact__c) {
                                primaryContactList.add(acrRecord.ContactId);                        
                            }
                        }
                        if (primaryContactList.size() == 1 ) { //logic to check there are only primary contacts on the client
                            clientContactMap.put(clientRecord.Id, primaryContactList[0]);
                        }
                    } else if (clientRecord.AccountContactRelations.size() == 1 && clientRecord.AccountContactRelations[0].Primary_Contact__c == true) {
                        clientContactMap.put(clientRecord.Id, clientRecord.AccountContactRelations[0].ContactId);
                    }
                    //Sprint-6 [BT-561] End
                }
            }
            
        }
         
        // Sprint-7 [BT-613] Start - Added Exit client conditions
        // List of open existing reconnection/client exiting cases
        List <Case> listOfExistingCases = [SELECT Id, Client__c, Client__r.Pod__r.Name FROM Case WHERE IsClosed = False AND Client__c IN : mapOfClientIdVsLatestExpiredPlan.keySet()
																AND (
                                                                (Type =:reConnectAutoCase.Type__c AND Sub_Type__c =:reConnectAutoCase.Sub_Type__c)  OR Subject LIKE '%Reconnection%'
                                                                OR Subject LIKE '%Reconnect%' OR
																Sub_Type__c =:reConnectAutoCase.Exit_Sub_Type__c OR
                                                                Subject LIKE '%Exit%') Limit 50000]; //ACEM-2 added query limit
        // Sprint-7 [BT-613] End                                                       
        for (Case nCase: listOfExistingCases) {
            setOfClientIdWithExistingCase.add(nCase.Client__c);
        }
        if (!mapOfClientIdVsLatestExpiredPlan.values().IsEmpty()) {
            for (Plan__c plan: mapOfClientIdVsLatestExpiredPlan.values()) { //Sprint 18 - [SFDC-1268]
                if (plan.Plan_End_Date__c <= Date.today().addDays(-2)) {  //Sprint 18 [SFDC-1268] : Create case for only plans whose end date is passed for more than 2 days.
                    if (!setOfClientIdWithExistingCase.contains(plan.Client_Name__c)) {  // BT-710 removed assignment to plan reconnection queue
                        Case newCase = new Case(RecordTypeId = reConnectAutoCase.Case_Record_Type_Id__c, Priority = reConnectAutoCase.Priority__c, Status = reConnectAutoCase.Status__c,
                                                OwnerId = plan.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ? reConnectAutoCase.Relationship_QLD_Queue__c : reConnectAutoCase.NDSP_Owner_Id__c, Type = reConnectAutoCase.Type__c, Sub_Type__c = reConnectAutoCase.Sub_Type__c,
                                                Subject = reConnectAutoCase.Subject__c, Description = reConnectAutoCase.Description__c, Client__c = plan.Client_Name__c ,Expired_Plan__c = plan.Id,
                                                Is_Auto_Created__c = True, Origin = 'Auto Generated');
                        listOfCasesToInsert.add(newCase);
                    }
                }   
            }  
        }
            
        if (!listOfCasesToInsert.isEmpty()) {
            for (Case nCase: listOfCasesToInsert) {
                if (clientContactMap.get(nCase.Client__c) != null) { //Sprint-6 [BT-561]
                    nCase.ContactId = clientContactMap.get(nCase.Client__c);
                }
                if (mapOfClientRecords.containsKey(nCase.Client__c)) {
                    nCase = buildString(nCase, mapOfClientRecords.get(nCase.Client__c), setOfFields); //Sprint 18 [SFDC-1268] updated for account.
                }
            }
            
            Database.SaveResult[] srList = Database.insert(listOfCasesToInsert, false);
            for (Database.SaveResult sr : srList){
                if (sr.isSuccess()) {
                    count++;
                } else {            
                    for(Database.Error err : sr.getErrors()) {                   
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
        }
    }
    
    
    global void finish(Database.BatchableContext BC) {
        
        AsyncApexJob asyncJob = [Select Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
                            from AsyncApexJob where Id =:BC.getJobId()];                          
        sendConfirmationEmail(asyncJob);                        
    }
    
    public void sendConfirmationEmail(AsyncApexJob asyncJob) {
        List <User> listOfUsers = [SELECT Id, Email, Name FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true];       
        List <String> listOfAdminEmails = new List <String>();

        for (User u: listOfUsers) {
            listOfAdminEmails.add(u.Email);
        }
        
        String createdDate = asyncJob.CreatedDate.format('dd-MM-yyyy HH:mm:ss','Australia/Adelaide');
        String completedDate = asyncJob.CompletedDate.format('dd-MM-yyyy HH:mm:ss','Australia/Adelaide');

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(listOfAdminEmails);
        mail.setSubject('Daily Reconnection Case Batch - ' + asyncJob.Status);
        String plainText = '<html><body> The batch process that automatically creates client reconnection cases in Salesforce has been successfully processed on ';
        plainText += completedDate + '. Further details are provided below: <br/><br/>';
        plainText += '<b>Batch Start Time:</b> ' + createdDate + '<br/>';
        plainText += '<b>Batch End Time:</b> ' + completedDate + '<br/>';
        plainText += '<b>Number of Batches Processed:</b> ' + asyncJob.TotalJobItems+ '<br/>'; 
        plainText += '<b>Number of Reconnection Cases Created Successfully:</b> ' + count+ '<br/>';
        if (asyncJob.ExtendedStatus != null) {
            plainText += '<b>Failure Reason:</b>' + asyncJob.ExtendedStatus+ '<br/>';
        }
        plainText += ' </body></html>';
        mail.setHtmlBody(plainText);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public static Set <String> returnFields() {
        List <String> mergeStrings = new List <String>();
        Set <String> setOfFields = new Set <String>();
        
        mergeStrings.add(reConnectAutoCase.Subject__c);
        mergeStrings.add(reConnectAutoCase.Description__c);
        
        for (String mergeString : mergeStrings) {
            List <String> listOfFields = mergeString.split('\'');
            for (String field: listOfFields) {
                if (field.contains('.') && field.length() > 1 && !field.containsWhitespace()) {
                    field = field.remove('Client__c.');
                    setOfFields.add(field);
                }
            }
        }
        return setOfFields;
    }
    
    public static Case buildString(Case nCase, Account ClientRecord, Set <String> setOfFields) {
        nCase.Description = mergeFieldText(nCase.Description, ClientRecord, setOfFields);
        nCase.Subject = mergeFieldText(nCase.Subject, ClientRecord, setOfFields);
        return nCase;
    }
    //Sprint 18 [SFDC-1268] updated for account.
    public static String mergeFieldText(String fieldValue, Account ClientRecord, Set <String> setOfFields) { 
        String newString = '';
        List <String> sliptedValue = fieldValue.split('\'');
        for (String value: sliptedValue){
            value = value.remove('Client__c.');
            if (setOfFields.contains(value)) {
                List <String> listOfMergeFields = value.split('\\.');
                if (listOfMergeFields.size() == 2) { // this is for related objects field
                    if (ClientRecord.get(listOfMergeFields[0]) != null) {
                        newString += value.replace(value, (String) ClientRecord.getSObject(listOfMergeFields[0]).get(listOfMergeFields[1]));
                    }
                } else {
                    if (ClientRecord.get(listOfMergeFields[0]) != null) {
                       newString += value.replace(value,String.valueOf(ClientRecord.get(listOfMergeFields[0])));
                    }
                }
            } else {
                newString += value;
            }
        }
        return newString;
    }

}