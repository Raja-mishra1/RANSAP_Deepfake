/**
 * @description	 [SFDC-1118] This batch runs 6 AM everyday to create Case for Client's whose Plan date has bee updated.
 *               Custom metadata 'Case Batch Configuration' drives the Case's static field value
 * @company		 Cloudwerx
 * @date	     04/05/2021
 * @testClass	 PlanExtensionCaseBatchClassTest
**/
global class PlanExtensionCaseBatchClass implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    
    private static final Case_Batch_Configuration__mdt CASE_BATCH_CONFIG =  Case_Batch_Configuration__mdt.getInstance('PlanExtensionCase');
    private Set <String> setOfFields;
    public Integer count;

    /*
    @ticket     :   [SFDC-1118]
    @description:   Constructor method to get the merge fields that need to be queried from Plan. 
    */
    public PlanExtensionCaseBatchClass(){
        setOfFields = returnFields();
        count = 0;
    }
    
    global void execute(SchedulableContext sc) {
        PlanExtensionCaseBatchClass b = new PlanExtensionCaseBatchClass(); 
        AsyncApexFramework.submitBatch(b,100,99);
        AsyncApexFramework.flush();
    }
    
    //A Plan is picked if Client Status = Active AND Plan Date is Extended
    global Iterable <SObject> start(Database.BatchableContext BC)
    {
        return processStart();
    }
      
    global void execute(Database.BatchableContext BC, List <Plan__c> listOfPlans) 
    {        
        Set <Id> setOfPlanIdWithExistingCase = new Set <Id>();
        Map <Id,Plan__c> mapOfPlans = new Map <Id,Plan__c>();
        Set<Id> setOfPlanIds = new Set<Id>();
        List <Case> listOfCasesToInsert = new List <Case>();

        for (Plan__c plan: listOfPlans) {
            mapOfPlans.put(plan.Client_Name__c,plan);
            setOfPlanIds.add(plan.Id);
        }

        //find primary contact of client - start - snippet from [561]
        Map<Id, Contact> clientContactMap = new Map<Id, Contact>();
        List<AccountContactRelation> varACRList = new List<AccountContactRelation>();
        
        List<AccountContactRelation> acrList = [SELECT Id, 
                                                        CreatedDate, 
                                                        ContactId, 
                                                        Contact.Name,  
                                                        Contact.FirstName, 
                                                        Contact.MiddleName, 
                                                        Contact.LastName, 
                                                        Contact.Email, 
                                                        Primary_Contact__c, 
                                                        AccountId 
                                                    FROM AccountContactRelation 
                                                    WHERE IsActive = true 
                                                    AND Primary_Contact__c = true 
                                                    AND AccountId IN :mapOfPlans.keySet() 
                                                    ORDER BY CreatedDate ASC];
       
        // If ACR List is not Empty
        if (!acrList.IsEmpty()) {
            for (AccountContactRelation acrRecord : acrList) {
                if (acrRecord.Primary_Contact__c ) {
                    //if multiple primary contacts on Client - we don't assign any
                    if (clientContactMap.containskey(acrRecord.AccountId)) {
                        clientContactMap.remove(acrRecord.AccountId);
                    } else {
                        Contact contactRec = new Contact(Id = acrRecord.Contact.Id, FirstName = acrRecord.Contact.FirstName, MiddleName = acrRecord.Contact.MiddleName,
                                                        LastName = acrRecord.Contact.Name,Email = acrRecord.Contact.Email);
                        clientContactMap.put(acrRecord.AccountId,contactRec);
                    }
                }
            }
        }                                             
        
        // List of existing plan extension cases related to plans on client
        List <Case> listOfExistingCases = [SELECT Id, 
                                                    Client__c,
                                                    Client__r.Pod__r.Name,
                                                    Expired_Plan__c
                                            FROM Case 
                                            WHERE Expired_Plan__c IN: setOfPlanIds 
                                            AND Client__c IN : mapOfPlans.keySet()
                                            AND 
                                            (
                                                (Type =:CASE_BATCH_CONFIG.Type__c AND Sub_Type__c =:CASE_BATCH_CONFIG.Sub_Type__c)
                                                    OR  
                                                (Subject LIKE '%Plan Extension%'
                                                    OR Subject LIKE '%Extension%')
                                            )];
        
        for (Case nCase: listOfExistingCases) {
            setOfPlanIdWithExistingCase.add(nCase.Expired_Plan__c);
        }
        
        // Create Plan Extension Cases
        if (!listOfPlans.IsEmpty()) {
            for (Plan__c plan: listOfPlans) {
                if(!setOfPlanIdWithExistingCase.contains(plan.Id)) {  
                    Case newCase = new Case(RecordTypeId = CASE_BATCH_CONFIG.Case_Record_Type_Id__c, Priority = CASE_BATCH_CONFIG.Priority__c, Status = CASE_BATCH_CONFIG.Status__c, 
                                            OwnerId = plan.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ? CASE_BATCH_CONFIG.Owner_Id__c : InvoiceRuleService.getQueueInfo.get(CASE_BATCH_CONFIG.NDSPOwnerName__c), Type = CASE_BATCH_CONFIG.Type__c, Sub_Type__c = CASE_BATCH_CONFIG.Sub_Type__c,
                                            Subject =  CASE_BATCH_CONFIG.Subject__c, Description = CASE_BATCH_CONFIG.Description__c, Client__c = plan.Client_Name__c ,
                                            Expired_Plan__c = plan.Id, Is_Auto_Created__c = True, Origin = CASE_BATCH_CONFIG.Case_Origin__c);
                    listOfCasesToInsert.add(newCase);
                }
            }
            
            // Set primary contact on cases
            for (Case nCase: listOfCasesToInsert) {
                if (clientContactMap.containsKey(nCase.Client__c)) {
                    nCase.ContactId = clientContactMap.get(nCase.Client__c).Id;  // set primary contact id
                    nCase.SuppliedName =  clientContactMap.get(nCase.Client__c).LastName; // set Web Name
                    nCase.SuppliedEmail =  clientContactMap.get(nCase.Client__c).Email; // set Web Email
                }
                nCase = buildString(nCase,mapOfPlans.get(nCase.Client__c), setOfFields);
            }
            
            Database.SaveResult[] srList = Database.insert(listOfCasesToInsert, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()){
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
    
    global void finish(Database.BatchableContext BC){                                 
         //Attributes used for Email
         List <String> listOfUserEmail = new List <String>();
         List <String> ccAddress = new List <String>();
         
         AsyncApexJob asyncJob = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, 
                                  JobItemsProcessed, TotalJobItems, CreatedDate, 
                                  CompletedDate
                                  FROM AsyncApexJob 
                                  WHERE Id =: BC.getJobId()
                                 ];
         
         //Get user who scheduled the batch
         List <User> listOfUsers = [SELECT Id,Email,Name from User WHERE id = :UserInfo.getUserId() LIMIT 1];
         
         //Get list of users to send email
         for(User u: listOfUsers){
             listOfUserEmail.add(u.Email);
         }
         
         //Get MPM outlook email 
         ccAddress.add(System.label.mpm_outlook_email);
         ccAddress.add(System.label.SF_PO_s_email_address);
        
         
         //Send Email to the user who Scheduled the batch and to mpm outlook mailbox
         Utils.sendBatchConfirmationEmail(asyncJob,listOfUserEmail,ccAddress,count,'Generates Plan Extension Case for Extended Plans');                       
    }

    /**Method picks plan whose Actual Plan End Date is less than Plan End Date*/
    global List <Plan__c> processStart(){
        List <Plan__c> listOfExtendedPlans = new List <Plan__c>();
        List <Plan__c> listOfAllPlans = new List <Plan__c>();

        listOfAllPlans =  [SELECT  Active__c, Actual_Plan_End_Date__c, Client_Name__c, Client_Name__r.Name,
                                            Client_Name__r.Status__c, Client_Name__r.RecordTypeId, Id, Plan_End_Date__c,
                                            Client_Name__r.PlanManager__c, PlanManager__c
                                    FROM    Plan__c 
                                    WHERE   Active__c = True
                                    AND     Client_Name__r.Status__c = 'Active'
                                    AND     (Client_Name__r.RecordTypeId =:RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID OR Client_Name__r.RecordTypeId =:RecordTypeUtil.RESTRICTED_CLIENT_ACCOUNT_RECORD_TYPE_ID)
                                    ORDER BY LastModifiedDate DESC Limit 50000]; //ACEM-2 Added query limit
        
        for (Plan__c planRecord: listOfAllPlans) {
            if (planRecord.Actual_Plan_End_Date__c < planRecord.Plan_End_Date__c) {
                listOfExtendedPlans.add(planRecord);
            }
        }
        return listOfExtendedPlans;
    }

    public static Set <String> returnFields(){
        List <String> mergeStrings = new List <String>();
        Set <String> setOfFields = new Set <String>();
        mergeStrings.add(CASE_BATCH_CONFIG.Subject__c);
        mergeStrings.add(CASE_BATCH_CONFIG.Description__c);
        
        for(String mergeString : mergeStrings){
            List <String> listOfFields = mergeString.split('\'');
            
            for(String field: listOfFields){
                if(field.contains('.') && field.length() > 1 && !field.containsWhitespace()){
                    field = field.remove('Plan__c.');//field = field.replace('Plan__c.','Plan__r.');
                    setOfFields.add(field);
                }
            }
        }
        return setOfFields;
    }
    
    public static Case buildString(Case nCase, Plan__c plan, Set <String> setOfFields){
        nCase.Description = mergeFieldText(nCase.Description, plan, setOfFields);
        nCase.Subject = mergeFieldText(nCase.Subject, plan, setOfFields);
        return nCase;
    }
    
    public static String mergeFieldText(String fieldValue,Plan__c plan, Set <String> setOfFields){ 
        String newString = '';
        List <String> sliptedValue = fieldValue.split('\'');
        for(String value: sliptedValue){                   
            value= value.remove('Plan__c.');//value = value.replace('Plan__c.','Plan__r.');
            if(setOfFields.contains(value)){
                //value= value.remove('Plan__r.');
                List <String> listOfMergeFields = value.split('\\.');
                if(listOfMergeFields.size() == 2){
                    newString += value.replace(value, (String) plan.getSObject(listOfMergeFields[0]).get(listOfMergeFields[1]));
                } else {
                    newString += value.replace(value,(String) plan.get(listOfMergeFields[0]));
                }
            }
            else{
                newString += value;
            }
        }
        return newString;
    }

}