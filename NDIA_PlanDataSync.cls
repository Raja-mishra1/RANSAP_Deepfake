/**
 * @description  [TTP-609] Batch class One-Time Migration of plan data Sync between NDIA & SF
 * @company      Cloudwerx
 * @date         13/08/2021
 * @testClass    NDIA_PlanDataSyncTest
**/

public without sharing class NDIA_PlanDataSync {

    public static List<EventLog__e> responseLogs ;
    public static List<EventLog__e> dmlLogs;
    public static Map<Id, Account> idVsAccountMap = new Map<Id, Account>();

    public static final string PLAN_ENDPOINT = NDIS_API_Configuration__mdt.getInstance('Plan_API').Endpoint_URL__c;
    public static final Integer DEFAULT_PLAN_TIMEOUT = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('Plan_API').Default_timeout__c);
    public static final string PLAN_AUTH_CONFIG = NDIS_API_Configuration__mdt.getInstance('Plan_API').NDIS_Gateway_Configuration_Name__c;
    public static final string NDSP_PLAN_ENDPOINT = NDIS_API_Configuration__mdt.getInstance('NDSP_Plan_API').Endpoint_URL__c;
    public static final Integer NDSP_DEFAULT_PLAN_TIMEOUT = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('NDSP_Plan_API').Default_timeout__c);
    public static final string NDSP_PLAN_AUTH_CONFIG = NDIS_API_Configuration__mdt.getInstance('NDSP_Plan_API').NDIS_Gateway_Configuration_Name__c;



    /**
    * @description         Method performs NDIA Get callout for Plan object
    * @param accountList   List of Account records
    * @return              accountIdVsResponseMap holds accountId as a key & plan response as avalue
    **/
    public static Map<String,NDIA_DTO.PlanResponse> getPlans (List <Account> accountList, Id jobId) {
        //Variable declaration
        responseLogs = new List<EventLog__e>();
        Map<String, NDIA_DTO.PlanResponse> accountIdVsResponseMap = new Map<String, NDIA_DTO.PlanResponse>(); 
        List<NDIA_DTO.PlanResult> planResultList = new List<NDIA_DTO.PlanResult>();
        Boolean rateLimitHit = false;

        for (Account account : accountList) {
            NDIA_DTO.PlanQuery planQuery = new NDIA_DTO.PlanQuery(account);
            String header = NDIA_DataSyncHelper.createHeader(planQuery, null);

            //Callout
            APIService.HTTPWire result = APIService.performGet (
                NDSPConstants.NDSP.equalsIgnoreCase(account.PlanManager__c) ? NDSP_PLAN_ENDPOINT : PLAN_ENDPOINT, 
                NDSPConstants.NDSP.equalsIgnoreCase(account.PlanManager__c) ? NDSP_DEFAULT_PLAN_TIMEOUT : DEFAULT_PLAN_TIMEOUT, '',header,
                new Map <String,String> {'Authorization' => + new JWTGenerator(NDSPConstants.NDSP.equalsIgnoreCase(account.PlanManager__c) ? NDSP_PLAN_AUTH_CONFIG : PLAN_AUTH_CONFIG).assertion() }
            );
            HttpResponse response = result.response;
            //Process response
            if (response.getStatusCode() == 200) { //SUCCESS
                NDIA_DTO.PlanResponse convResponse = NDIA_DTO.PlanResponse.parseplanResponse(response.getBody());
                if (convResponse.success) {
                    account.Sync_Error_Plan__c = '';
                    accountIdVsResponseMap.put(account.Id, convResponse); 
                }
            } else { //ERROR
                //create Log
                EventLog__e evt = LogService.logCallout (
                    'NDIA_PlanDataSync','getPlans','NDIS PLAN API',result.request,response,'Error'
                ); 
                evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);

                //Check if Error code is in 400 - 599 Error code range 
                boolean isServerError =  (Integer.valueOf(response.getStatusCode()/100) == 4 ||
                                        Integer.valueOf(response.getStatusCode()/100) == 5)? true: false;
                String responseBody = response.getBody().trim();
                //RATE API Limit check
                if (response.getStatusCode() == 429) {
                    rateLimitHit = true;
                    responseLogs.add(evt);
                    account.Last_Plan_Sync__c = null;
                    break;
                } else if(isServerError && response.getStatusCode() != 400){
                    account.Sync_Error_Plan__c = (responseBody.length() > 255 ? responseBody.substring(0,255) : responseBody);
                    responseLogs.add(evt);
                } else {
                    responseLogs.add(evt); 
                    //Update Sync fields on Account
                    NDIA_DTO.ResponseError body = (NDIA_DTO.ResponseError) JSON.deserialize(response.getBody(), NDIA_DTO.ResponseError.class);
                    String error = (body.errors != null && body.errors.size() > 0) 
                                    ? body.errors[0] 
                                    : (String.isNotBlank(body.message) ? body.message : '') ;
                    account.Sync_Error_Plan__c = (error.length() > 255 ? error.substring(0,255) : error);

                    if (error.contains(Label.NDIA_NoRecordsFound)) {
                        account.Last_Plan_Sync__c = DateTime.now();
                    }
                }                
                idVsAccountMap.put (account.Id, account);
            }                
        }
      
        //Insert logs for failure scenarios
        if (!responseLogs.isEmpty()) {
            LogService.insertLog(responseLogs);
        }
        if (rateLimitHit && jobId != null) System.abortJob(jobId);
        return accountIdVsResponseMap;
    }

    /**
    * @description     Method performs NDIA Get callout for Plan object
    * @param           accountIdVsResponseMap holds accountId as a key[string] & response [NDIA_DTO.PlanResponsevalue]
    * @return          accountIdVsResponseMap holds accountId as a key & plan response as a value
    */ 
    public static Map<Id, Account> processPlans (Map<String,NDIA_DTO.PlanResponse> accountIdVsResponseMap) {
        dmlLogs = new List <EventLog__e>();
        List <Plan__c> planUpsertList = new List <Plan__c> ();  
        List <Plan__c> planUpdateList = new List <Plan__c> ();  
        Map<String,Plan__c> prodaPlanIdVsPlanMap = new Map<String,Plan__c>();
        Map <String,Plan__c> uniqueKeyVsPlanMap = new Map <String,Plan__c> ();
        Set<String> prodaPlanIdList = new Set<String>(); //TTP-1608

        if (accountIdVsResponseMap != null && !accountIdVsResponseMap.isEmpty()) {

            //Query existing Plan Records to match using PRODA_Plan_Id__c or start date
             for (Plan__c plan : NDIA_DataSyncService.getPlansbyClient(accountIdVsResponseMap.keyset())) {
                if (plan.PRODA_Plan_Id__c != null) {
                    prodaPlanIdVsPlanMap.put(plan.PRODA_Plan_Id__c, plan);
                } else {  //beacause Plan_Start_Date__c is unique for client
                    String key = plan.Client_Name__c+string.valueOf(plan.Plan_Start_Date__c);
                    uniqueKeyVsPlanMap.put(key, plan);
                }
            }

            //Process Response
            for (String accountId :accountIdVsResponseMap.keyset()) {
                NDIA_DTO.PlanResponse response = accountIdVsResponseMap.get(accountId);
                List<Plan__c> planTempList = new List<Plan__c>();
                
                for (NDIA_DTO.PlanResponseResult result :response.result) {                    
                    if (!result.plan_start_date.equalsIgnoreCase(result.plan_end_date)) {
                        String dateKey = accountId+result.plan_start_date;
                        if (prodaPlanIdVsPlanMap.containsKey(result.participant_plan_id)) {
                            Plan__c planObj = createPlan(prodaPlanIdVsPlanMap.get(result.participant_plan_id), result);
                            planTempList.add(planObj); 
                        } else if (uniqueKeyVsPlanMap.containsKey(dateKey)) {
                            Plan__c planObj = createPlan(uniqueKeyVsPlanMap.get(dateKey), result);
                            planTempList.add(planObj);
                        }
                    } 
                }
                
                if (planTempList.isEmpty()) {
                    idVsAccountMap.put(accountId, new Account(Id=accountId, Last_Plan_Sync__c = datetime.now(), Sync_Error_Plan__c = ''));
                } else {
                    planUpdateList.addAll(planTempList);
                }                
            }
        }
        
        Map<String,EventLog__e> clientVsResultMap = new Map<String,EventLog__e>();
       
        //Update Plan Records
        if (planUpdateList != null && !planUpdateList.isEmpty()) {
            Database.SaveResult[] planUpdateResults = Database.update(planUpdateList, false);
            for (Integer index = 0, size = planUpdateResults.size(); index < size; index++) {
                Account accountToUpdate = new Account( Id = planUpdateList[index]?.Client_Name__c,  Last_Plan_Sync__c = datetime.now(), Sync_Error_Plan__c = '');
                
                if (!(planUpdateResults[index]?.isSuccess())) {
                    NDIA_DTO.PlanResult resultRow = new NDIA_DTO.PlanResult();
                    resultRow.planId = planUpdateResults[index]?.getId();
                    resultRow.prodaPlanId = planUpdateList[index]?.PRODA_Plan_Id__c;
                    resultRow.clientId = planUpdateList[index]?.Client_Name__c;
                    resultRow.isSuccess = planUpdateResults[index]?.isSuccess();
                    resultRow.errors = '';

                    for (Database.Error error: planUpdateResults[index]?.getErrors()) {
                        resultRow.errors += ' '+ error;
                    }

                    //Create Event Log
                    EventLog__e eve = LogService.logSaveResult ('NDIA_PlanDataSync','processPlans','','', '', '');

                    //Group the logs based on Client Id
                    if (clientVsResultMap.containsKey(resultRow.clientId)) {
                        EventLog__e evt =  clientVsResultMap.get(resultRow.clientId);
                        evt.Description__c += '\n '+json.serialize(resultRow);
                    } else {
                        eve.Description__c = json.serialize(resultRow);
                        clientVsResultMap.put(resultRow.clientId, eve);
                    }
                    
                    accountToUpdate.Sync_Error_Plan__c = JSON.serialize(resultRow).length() > 255 ? JSON.serialize(resultRow).substring(0, 255) : JSON.serialize(resultRow);
                }

                idVsAccountMap.put(planUpdateList[index]?.Client_Name__c, accountToUpdate);
            }
        }
        
        if (!clientVsResultMap.isEmpty()) {
            LogService.insertLog(clientVsResultMap.values());   //Insert Logs
        }

        if (!idVsAccountMap.isEmpty()) {
            Database.SaveResult[] accountUpdateResults = Database.update(idVsAccountMap.values(),false); 
        }

        return idVsAccountMap;
    }

    /**
    * @description              Method to create Plan Record from request object
    * @param                    result is input type of PlanResponseResult
    * @return                   Plan__c plan object record
    */
    public static Plan__c createPlan(Plan__c planRecord, NDIA_DTO.PlanResponseResult result) {
        planRecord.PRODA_Plan_Id__c = result.participant_plan_id;
        planRecord.Plan_End_Date__c = Date.valueOf(result.plan_end_date);
        planRecord.Plan_Start_Date__c = Date.valueOf(result.plan_start_date);
        planRecord.Name = result.plan_start_date + ' - ' + result.plan_end_date;
        return planRecord;
    }
}