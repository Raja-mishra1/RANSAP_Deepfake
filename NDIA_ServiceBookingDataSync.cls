/**
 * @description  [TTP-779] Processes & syncs Service Booking data from NDIA to SF
 * @company      Cloudwerx
 * @date         24/08/2021                              
**/

public without sharing class NDIA_ServiceBookingDataSync {
   
    public static Boolean isOnDemandSync = false;
    public static List<EventLog__e> responseLogs;
    public static List<EventLog__e> dmlLogs;
    public static Map<Id, Account> idVsAccountMap = new Map<Id, Account>();
    public static Map<Id, List<Plan__c>> idVsAccountPlansMap = new Map<Id, List<Plan__c>>();
    public static Map<String, String> picklistLabelVsApiName = NDIA_DataSyncHelper.getPicklistValues('ServiceBooking__c', 'Type__c');
    public static final string SERVICE_BOOKING_ENDPOINT = NDIS_API_Configuration__mdt.getInstance('ServiceBooking_API').Endpoint_URL__c;
    public static final string NDSP_SERVICE_BOOKING_ENDPOINT = NDIS_API_Configuration__mdt.getInstance('NDSP_Service_Booking_API').Endpoint_URL__c;
    
    public static final Integer NDSP_DEFAULT_SERVICE_BOOKING_TIMEOUT = Integer.valueOf(
        NDIS_API_Configuration__mdt.getInstance('NDSP_Service_Booking_API').Default_timeout__c
    );
    public static final Integer DEFAULT_SERVICE_BOOKING_TIMEOUT = Integer.valueOf(
        NDIS_API_Configuration__mdt.getInstance('ServiceBooking_API').Default_timeout__c
    );

    /**
     * @description  [TTP-779] This method fetches the service bookings for a client by performing a callout.
     * @author       Mehul Shah
     * @param        accountsList : List of Account records
     *               jobId  : Batch Job ID
     * @return       Map of account and related Service Booking response
    **/
    public static Map<String,NDIA_DTO.ServiceBookingResponse> getServiceBookings (List<Account> accountsList, Id jobId) {
        Boolean rateLimitHit = false;
        responseLogs  = new List<EventLog__e>();
        Map<String,NDIA_DTO.ServiceBookingResponse> accountIdVsResponseMap = new Map <String, NDIA_DTO.ServiceBookingResponse>(); 
        Map<String, String> headers = new Map <String,String>();

        for (Account account : accountsList) {
            headers = new Map <String,String> {
                'Authorization' => + new JWTGenerator(
                    account?.PlanManager__c == 'MPM' 
                    ? NDIS_API_Configuration__mdt.getInstance
                        ('ServiceBooking_API').NDIS_Gateway_Configuration_Name__c
                    : NDIS_API_Configuration__mdt.getInstance
                        ('NDSP_Service_Booking_API').NDIS_Gateway_Configuration_Name__c
                ).assertion(),
                'participant' => account.NDIS__c
            };
            Long s1 = System.currentTimeMillis();
            APIService.HTTPWire result = APIService.performGet(
                account?.PlanManager__c == 'MPM' 
                    ? SERVICE_BOOKING_ENDPOINT
                    : NDSP_SERVICE_BOOKING_ENDPOINT, 
                account?.PlanManager__c == 'MPM'
                    ? DEFAULT_SERVICE_BOOKING_TIMEOUT
                    : NDSP_DEFAULT_SERVICE_BOOKING_TIMEOUT,
                    '','', headers
            );
            Long s2 = System.currentTimeMillis();
            NDIA_OnDemandServiceBookingSync.calloutMs += (s2-s1);
                    
            HttpRequest request = result.request;
            HTTPResponse response = result.response;
            idVsAccountPlansMap.put(account.Id, account.Plans__r);
                                                 
            if (response.getStatusCode() == 200) {    // API Success
                NDIA_DTO.ServiceBookingResponse sbResponse = NDIA_DTO.parseServiceBookingResponse(response.getBody());
                if(sbResponse.success) {
                    accountIdVsResponseMap.put(account.Id, sbResponse);
                    account.Last_Service_Booking_Sync__c = Datetime.now();
                    account.Sync_Error_Service_Booking__c = '';
                    idVsAccountMap.put(account.Id, account);
                }
            } else {
                EventLog__e evt = LogService.logCallout(
                        'NDIA_ServiceBookingDataSync', 'getServiceBookings', 'NDIA SERVICE BOOKING API', request, response, 'Error'
                    );

                //Check if Error code is in 400 - 599 Error code range 
                boolean isServerError =  (Integer.valueOf(response.getStatusCode()/100) == 4 ||
                                        Integer.valueOf(response.getStatusCode()/100) == 5)? true: false;
                String responseBody = response.getBody().trim();

                if (response.getStatusCode() == 503) {   // API Failure for Service Unavailable                    
                    evt.Description__c = 'Service Unavailable';
                    evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                    responseLogs.add(evt);   
                    account.Sync_Error_Service_Booking__c = Label.NdiaApiServiceUnavailable; 
                    idVsAccountMap.put(account.Id, account);
                    break;
                } else if (response.getStatusCode() == 429) {   // API Failure for API Rate Limit Hit
                    rateLimitHit = true;
                    account.Last_Service_Booking_Sync__c = null;
                    account.Sync_Error_Service_Booking__c = Label.NdiaApiRateLimitHit;                
                    idVsAccountMap.put(account.Id, account);
                    evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                    responseLogs.add(evt);
                    break;
                } else if (isServerError && response.getStatusCode() != 400) {
                    evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                    responseLogs.add(evt);
                    account.Sync_Error_Service_Booking__c = (responseBody.length() > 255 ? responseBody.substring(0,255) : responseBody); 
                    idVsAccountMap.put(account.Id, account);
                } else {     // API Failure for other status code
                    NDIA_DTO.ResponseError body = (NDIA_DTO.ResponseError) JSON.deserialize(response.getBody(), NDIA_DTO.ResponseError.class);
                    String error = (body.errors != null && !body.errors.isEmpty()) ? body.errors[0] : (body.moreInformation != null ? body.moreInformation : '');
                    account.Sync_Error_Service_Booking__c = (error.length() > 255) ? error.substring(0, 255) : error;
                    account.Last_Service_Booking_Sync__c = response.getStatusCode() == 400 ? DateTime.now() : null;
                    idVsAccountMap.put(account.Id, account);
                    evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                    responseLogs.add(evt);
                }
            }
            
        }

        if (rateLimitHit && jobId != null) {    // abort batch job if rate limit is hit
            System.abortJob(jobId);
        }
        return accountIdVsResponseMap;
    }


    /**
     * @description  This method processes the service bookings.
     * @author       Mehul Shah     
     * @param        accountIdVsResponseMap : List of Account records    
     * @return       Map of Account records     
    **/
    public static Map<Id, Account> processServiceBookings (Map<String,NDIA_DTO.ServiceBookingResponse> accountIdVsResponseMap) {
        dmlLogs = new List <EventLog__e>();
        EventLog__e evt = new EventLog__e();
        Map<Id, Id> accountIdVsServiceBookingId = new Map<Id, Id>();
        List<ServiceBooking__c> serviceBookingList = new List <ServiceBooking__c>();
        List<Plan__c> allPlansList = new List <Plan__c>();
        
        if (accountIdVsResponseMap != null && !accountIdVsResponseMap.isEmpty()) {
            for (Id accountId : accountIdVsResponseMap.keySet()) {
                NDIA_DTO.ServiceBookingResponse sbResponse = accountIdVsResponseMap.get(accountId);
                if(sbResponse.result.isEmpty() || sbResponse.result == null) {    
                //if no service bookings returned from response for a client, then populate the timestamp and error msg on Account and add log record.
                    idVsAccountMap.put(
                        accountId, new Account(
                                Id = accountId, Last_Service_Booking_Sync__c = DateTime.now(), 
                                Sync_Error_Service_Booking__c = System.Label.NDIA_NoRecordsFound
                        )
                    );
                    String logMsg = 'Message : ' + System.Label.NDIA_NoRecordsFound;
                    logMsg += '\n' + 'Client ID : ' + accountId;
                    EventLog__e event = LogService.logSaveResult('NDIA_ServiceBookingDataSync', 'processServiceBookings', logMsg, '', '', '');
                    event.HTTPResponse__c = JSON.serialize(sbResponse.result);
                    dmlLogs.add(event);
                } else {
                    for (NDIA_DTO.ServiceBookingResponseResult result : sbResponse.result) {
                        ServiceBooking__c serviceBookingObj = new ServiceBooking__c();
                        serviceBookingObj.Name = picklistLabelVsApiName.get(result.booking_type) + 
                            ' - ' + NDIA_DataSyncHelper.getStartDate(result.start_date.removeEnd(' 00:00:00')).format();
                        serviceBookingObj.ExternalId__c = result.service_booking_id;
                        if(!String.IsBlank(result.booking_type)){
                            serviceBookingObj.Type__c = result.booking_type;
                        }
                        serviceBookingObj.Account__c = accountId;
                        serviceBookingObj.StartDate__c = Date.valueOf(result.start_date);
                        serviceBookingObj.EndDate__c = Date.valueOf(result.end_date);
                        serviceBookingObj.Status__c = result.status;
                        serviceBookingObj.ProviderComments__c = result.provider_comments;
                        serviceBookingObj.SubmittedDate__c = Date.valueOf(result.submitted_date);
                        serviceBookingObj.NDIACreatedBy__c = result.created_by;
                        serviceBookingObj.PRODA_Plan_Id__c = result.participant_plan_id;
                        
                        for (Plan__c plan : idVsAccountPlansMap.get(accountId)) {
                            plan.LastServiceBookingSync__c = DateTime.now();
                            if (result.participant_plan_id.equals(plan.Proda_Plan_Id__c)) {
                                serviceBookingObj.Plan__c = plan.Id;
                                break;
                            }
                        }
                        serviceBookingList.add(serviceBookingObj);                 
                    }
                } 
            }

            if (!serviceBookingList.isEmpty() && serviceBookingList != null) {
                Schema.SObjectField fieldName = ServiceBooking__c.Fields.ExternalId__c;
                Database.UpsertResult[] upsertResults = Database.upsert(serviceBookingList, fieldName, false);

                // upsert the service booking records
                for (Integer index = 0, size = upsertResults.size(); index < size; index++) {
                    if (!upsertResults[index].isSuccess()) {             // Create log record details in case of dml failure
                        NDIA_DTO.ServiceBookingResult resultRow = new NDIA_DTO.ServiceBookingResult();
                        resultRow.errors = '';
                        resultRow.recordId = serviceBookingList[index]?.Id;
                        resultRow.serviceBookingId = serviceBookingList[index]?.ExternalId__c;
                        resultRow.clientId = serviceBookingList[index]?.Account__c;
                        resultRow.isCreated = upsertResults[index]?.isCreated();
                        resultRow.isSuccess = upsertResults[index]?.isSuccess();
                        
                        for (Database.Error error: upsertResults[index]?.getErrors()) {
                            resultRow.errors += error;
                        }

                        evt = LogService.logSaveResult('NDIA_ServiceBookingDataSync', 'processServiceBookings', JSON.serialize(resultRow), '', '', '');
                        evt.HTTPResponse__c = JSON.serialize(accountIdVsResponseMap.get(serviceBookingList[index].Account__c));
                        dmlLogs.add(evt);
                        idVsAccountMap.put(
                            serviceBookingList[index].Account__c, 
                            new Account(
                                Id = serviceBookingList[index].Account__c, Last_Service_Booking_Sync__c = DateTime.now(), 
                                Sync_Error_Service_Booking__c = (JSON.serialize(resultRow).length() > 255) ? 
                                                                JSON.serialize(resultRow).substring(0, 255) : 
                                                                JSON.serialize(resultRow)
                            )
                        );
                    }
                }
            }
        }

        if (!responseLogs.isEmpty()) {
            LogService.insertLog(responseLogs);    // insert logs for failed callouts
        }

        //Insert Logs
        if (!dmlLogs.isEmpty()) {
            LogService.insertLog(dmlLogs);
        } 

        for (Account acc : idVsAccountMap.values()) {
            for (Plan__c plan : idVsAccountPlansMap.get(acc.Id)) {
                plan.LastServiceBookingSync__c = acc.Last_Service_Booking_Sync__c;
                plan.Sync_Error_Service_Booking__c = acc.Sync_Error_Service_Booking__c;
                if (isOnDemandSync) {
                    break;
                } 
            }
        }

        // Update Accounts
        if (!idVsAccountMap.isEmpty() && !isOnDemandSync) {
            Database.SaveResult[] accountUpdateResults = Database.update(idVsAccountMap.values(), false);
        }

        if (!idVsAccountPlansMap.isEmpty()) {
            for (List<Plan__c> planList : idVsAccountPlansMap.values()) {
                for (Plan__c plan : planList) {
                    allPlansList.add(plan);
                }
            }
        }

        if (!allPlansList.isEmpty()) {
            Database.SaveResult[] planUpdateResults = Database.update(allPlansList, false);
        }
        return idVsAccountMap;
    }
}