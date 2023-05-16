/**
 * @description  [TTP-975] Batch class One-Time ServiceBookingLineItem data Sync between NDIA & SF
 * @company      Cloudwerx
 * @date         24/08/2021
 * @testClass    NDIA_SBLineItemDataSyncTest
**/

public without sharing class NDIA_SBLineItemDataSync {
    public static List<EventLog__e> responseLogs ;
    public static List<EventLog__e> dmlLogs;
    public static Map<String, ServiceBooking__c> idVsServiceBookingMap = new Map<String, ServiceBooking__c>();
    public static Map<String, String> picklistLabelVsApiName = NDIA_DataSyncHelper.getPicklistValues('ServiceBooking__c', 'Type__c');
    public static final string SB_LINE_ITEM_ENDPOINT = NDIS_API_Configuration__mdt.getInstance('ServiceBookingLineItem_API').Endpoint_URL__c;
    public static final Integer DEFAULT_SB_LINE_ITEM_TIMEOUT = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('ServiceBookingLineItem_API').Default_timeout__c);
    public static final string SB_LINE_ITEM_AUTH_CONFIG = NDIS_API_Configuration__mdt.getInstance('ServiceBookingLineItem_API').NDIS_Gateway_Configuration_Name__c;

    // NDSP SETTINGS
    public static final string NDSP_SB_LINE_ITEM_ENDPOINT = NDIS_API_Configuration__mdt.getInstance('NDSP_ServiceBookingLineItem_API').Endpoint_URL__c;
    public static final Integer NDSP_DEFAULT_SB_LINE_ITEM_TIMEOUT = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('NDSP_ServiceBookingLineItem_API').Default_timeout__c);
    public static final string NDSP_SB_LINE_ITEM_AUTH_CONFIG = NDIS_API_Configuration__mdt.getInstance('NDSP_ServiceBookingLineItem_API').NDIS_Gateway_Configuration_Name__c;

    /**
     * @description         Method performs NDIA Get callout for Service Booking Line Items object
     * @author              Swapnil Bhapkar
     * @param               serviceBookingList : List of Service Booking records
     *                      jobId : Batch job id
     * @return              Map of service Booking External Id and response is the return type                
    **/
    public static Map<String,NDIA_DTO.ServiceBookingLineItemResponse> getSBLineItems (List <ServiceBooking__c> serviceBookingList, Id jobId) {
        //Variable declaration
        Boolean rateLimitHit = false;
        responseLogs  = new List<EventLog__e>();
        Map<String,NDIA_DTO.ServiceBookingLineItemResponse> serviceBookingIdVsResponseMap = new Map <String, NDIA_DTO.ServiceBookingLineItemResponse>(); 
        Map<String, String> headers = new Map <String,String>();

        for (ServiceBooking__c serviceBooking : serviceBookingList) {
            headers = new Map <String,String> {
                'Authorization' => + new JWTGenerator(
                    serviceBooking?.PlanManager__c == 'MPM' 
                    ? SB_LINE_ITEM_AUTH_CONFIG
                    : NDSP_SB_LINE_ITEM_AUTH_CONFIG
                    ).assertion(),
                    'participant' => serviceBooking.Account__r.NDIS__c} ;
            
            if (NDIA_OnDemandServiceBookingSync.calloutMs < 110000) {
                
                Long s1 = System.currentTimeMillis();        
                APIService.HTTPWire result = APIService.performGet(
                    serviceBooking?.PlanManager__c == 'MPM' 
                        ? SB_LINE_ITEM_ENDPOINT
                        : NDSP_SB_LINE_ITEM_ENDPOINT,
                    serviceBooking?.PlanManager__c == 'MPM' 
                        ? DEFAULT_SB_LINE_ITEM_TIMEOUT
                        : NDSP_DEFAULT_SB_LINE_ITEM_TIMEOUT,
                    serviceBooking.ExternalId__c,
                    '',
                    headers           
                    );
                Long s2 = System.currentTimeMillis(); 
                
                NDIA_OnDemandServiceBookingSync.calloutMs += (s2-s1);
    
                HttpRequest request = result.request;
                HTTPResponse response = result.response;

                boolean isServerError =  (Integer.valueOf(response.getStatusCode()/100) == 4 ||
                                        Integer.valueOf(response.getStatusCode()/100) == 5)? true: false;
                String responseBody = response.getBody().trim();

                if (response.getStatusCode() == 200) {    // API Success
                    try {
                        NDIA_DTO.ServiceBookingLineItemResponse sbResponse = NDIA_DTO.parseServiceBookingLineItemResponse(response.getBody());
                        System.debug('response body' +response.getBody());
                        if(sbResponse.success) {
                            serviceBookingIdVsResponseMap.put(serviceBooking.ExternalId__c, sbResponse);
                        }                  
                    } catch (JSONException e) {//Catching any exception during parsing
                        NDIA_DTO.ServiceBookingResponse sbResponse = NDIA_DTO.parseServiceBookingLineItemEmptyResponse(response.getBody());

                        if (sbResponse.result.isEmpty()) {
                            ServiceBooking__c serviceBookingObj = new ServiceBooking__c(ExternalId__c = serviceBooking.ExternalId__c,
                                                                                        SyncErrorSBLineItem__c = e.getMessage(),
                                                                                        LastServiceBookingLineItemsSync__c = DateTime.now()
                            );
                            
                            idVsServiceBookingMap.put(serviceBookingObj.ExternalId__c, serviceBookingObj);
                            EventLog__e evt = LogService.logCallout(
                                'NDIA_SBLineItemDataSync', 'getSBLineItems', 'No Records Found ' + e.getMessage(), request, response, 'Error'
                            ); 
                            evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                            evt.EventName__c = NDIA_NotificationHelper.eventName;
                            evt.EventReplayId__c = NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBooking.ExternalId__c);

                            if (NDIA_NotificationHelper.uniqueIdVsEventResponseMap != null) {
                                evt.HttpResponse__c += '\nEvent JSON Response : \n' + NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBooking.ExternalId__c);    // NDIA Notification Event JSON Response
                            }

                            responseLogs.add(evt);
                        }
                    }
    
                } else if (response.getStatusCode() == 503) {   // API Failure for Service Unavailable
                    EventLog__e evt = LogService.logCallout(
                        'NDIA_SBLineItemDataSync', 'getSBLineItems', 'NDIA SB LINE ITEM API', request, response, 'Error'
                    );
                    evt.Description__c = 'Service Unavailable';
                    evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                    evt.EventName__c = NDIA_NotificationHelper.eventName;
                    evt.EventReplayId__c = NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBooking.ExternalId__c);
                    
                    if (NDIA_NotificationHelper.uniqueIdVsEventResponseMap != null) {
                        evt.HttpResponse__c += '\nEvent JSON Response : \n' + NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBooking.ExternalId__c);    // NDIA Notification Event JSON Response
                    }

                    responseLogs.add(evt);
                    break;
                } else if (response.getStatusCode() == 429) {
                    rateLimitHit = true;
                    EventLog__e evt = LogService.logCallout(
                        'NDIA_SBLineItemDataSync', 'getSBLineItems', 'NDIA SB LINE ITEM API', request, response, 'Error'); 
                    evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                    evt.EventName__c = NDIA_NotificationHelper.eventName;
                    evt.EventReplayId__c = NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBooking.ExternalId__c);
                    
                    if (NDIA_NotificationHelper.uniqueIdVsEventResponseMap != null) {
                        evt.HttpResponse__c += '\nEvent JSON Response : \n' + NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBooking.ExternalId__c);    // NDIA Notification Event JSON Response
                    }

                    responseLogs.add(evt);
                    break;
                } else if (isServerError && response.getStatusCode() != 400) {
                    EventLog__e evt = LogService.logCallout(
                        'NDIA_SBLineItemDataSync', 'getSBLineItems', 'NDIA SB LINE ITEM API', request, response, 'Error'); 
                    evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                    evt.EventName__c = NDIA_NotificationHelper.eventName;
                    evt.EventReplayId__c = NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBooking.ExternalId__c);
                    
                    if (NDIA_NotificationHelper.uniqueIdVsEventResponseMap != null) {
                        evt.HttpResponse__c += '\nEvent JSON Response : \n' + NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBooking.ExternalId__c);    // NDIA Notification Event JSON Response
                    }
                    responseLogs.add(evt);
                }  else {     // API Failure
                    NDIA_DTO.ResponseError body = (NDIA_DTO.ResponseError) JSON.deserialize(response.getBody(), NDIA_DTO.ResponseError.class);
                    EventLog__e evt = LogService.logCallout(
                        'NDIA_SBLineItemDataSync', 'getSBLineItems', 'NDIA SB LINE ITEM API', request, response, 'Error'); 
                    evt.HttpRequest__c += JSON.serialize(APIService.defaultHeaders);
                    evt.EventName__c = NDIA_NotificationHelper.eventName;
                    evt.EventReplayId__c = NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBooking.ExternalId__c);
                    
                    if (NDIA_NotificationHelper.uniqueIdVsEventResponseMap != null) {
                        evt.HttpResponse__c += '\nEvent JSON Response : \n' + NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBooking.ExternalId__c);    // NDIA Notification Event JSON Response
                    }

                    // Error String
                    String error = deserializeErrorResponse(response.getBody());

                    ServiceBooking__c serviceBookingObj = new ServiceBooking__c(ExternalId__c = serviceBooking.ExternalId__c,
                                                                                SyncErrorSBLineItem__c = (error.length() > 255) ? error.substring(0, 255) : error,
                                                                                LastServiceBookingLineItemsSync__c = response.getStatusCode() == 400 ? DateTime.now() : null);
                
                    idVsServiceBookingMap.put(serviceBookingObj.ExternalId__c, serviceBookingObj);
                    responseLogs.add(evt);
                }
            } else {
                return null;
            }           
        }
        if (!responseLogs.isEmpty()) {
            LogService.insertLog(responseLogs);    // insert logs for failed callouts
        }
        if (rateLimitHit && jobId != null) {    // abort batch job if rate limit is hit //added JobId check for TTP-980
            System.abortJob(jobId);
        }
        return serviceBookingIdVsResponseMap; 
    }

    /**
     * @description   This method processes the service bookings and Line Items
     * @author        Swapnil Bhapkar
     * @param         serviceBookingIdVsResponseMap : Map of service Booking External Id and Response from API
     * @return        Map of service Booking External Id with service Booking object is the return type
    **/
    public static Map<String, ServiceBooking__c> processSBLineItems (Map<String,NDIA_DTO.ServiceBookingLineItemResponse> serviceBookingIdVsResponseMap, Boolean calledFromNDIAEvent) {        
        dmlLogs = new List <EventLog__e>();
        Set<String> supportItemNumberSet = new Set<String>();
        Set<String> planIdSet = new Set<String>();
        List<ServiceBookingLineItem__c> ServiceBookingLineItemList = new List<ServiceBookingLineItem__c>();
        Map<String,String> sbLineItemIdVsServiceBookingIdMap = new Map<String,String>();
        Map<String,SupportCategory__c> nameVsSupportCategory = new Map<String,SupportCategory__c>();
        Map<String,Plan__c> planIdVsPlanMap = new Map<String,Plan__c>();
        //Map of Support Caregory Name VS its Id--Start
        Map<String, List<SupportItem__c>> supportItemNumberVsListOfSupportItems = new Map<String, List<SupportItem__c>>();//TTP-975

        for (SupportCategory__c supportCategory : NDIA_DataSyncService.getSupportCategories()) {
            nameVsSupportCategory.put(supportCategory.SupportCategoryCode__c , supportCategory);
        }
        //Map of Support Caregory Name VS its Id--End        
        if (serviceBookingIdVsResponseMap != null && !serviceBookingIdVsResponseMap.isEmpty()) {
            
            for (String serviceBookingId : serviceBookingIdVsResponseMap.keySet()) {
                NDIA_DTO.ServiceBookingLineItemResponse sbResponse = serviceBookingIdVsResponseMap.get(serviceBookingId);
                planIdSet.add(sbResponse.result.participant_plan_id);
                for (NDIA_DTO.ServiceBookingLineItemResponseResult result : sbResponse.result.items) {
                    supportItemNumberSet.add(result.product_category_item);
                }
            }

            if (!planIdSet.isEmpty()) {
                for (Plan__c planObj :NDIA_DataSyncService.getPlansbyProdaId(planIdSet)) {
                    /*IF THE PAYLOAD WAS RECEIVED FROM NDIA NOTIFICATION THEN THE KEY SHOULD INCLUDE
                    PLANMANAGER*/
                    if(calledFromNDIAEvent) {
                        planIdVsPlanMap.put(planObj.Proda_Plan_Id__c + planObj.PlanManager__c,planObj);
                    }
                    /*IF THE PAYLOAD WAS RECEIVED FROM CALLOUT THEN THE PAYLOAD WILL NOT CONTAIN
                    PLANMANAGER ATTRIBUTE AND HENCE WE SHOULD NOT INCLUDE PLANMANAGER IN THE KEY*/
                    else {
                        planIdVsPlanMap.put(planObj.Proda_Plan_Id__c,planObj);
                    }
                }
            }

            //TTP-975 Map existing support item--Start
            for (SupportItem__c supportItem : NDIA_DataSyncService.getSupportItemsBySupportItemNumber(supportItemNumberSet)) {
                String supportItemNumber = string.valueOf(supportItem.SupportItemNumber__c);
                if (supportItemNumberVsListOfSupportItems.containsKey(supportItemNumber)) {
                    supportItemNumberVsListOfSupportItems.get(supportItemNumber).add(supportItem);
                } else {
                    supportItemNumberVsListOfSupportItems.put(supportItemNumber, new List<SupportItem__c>{supportItem});
                }
            }

            //TTP-975 Map existing support item--End
            for (String serviceBookingId : serviceBookingIdVsResponseMap.keySet()) {
                NDIA_DTO.ServiceBookingLineItemResponse sbResponse = serviceBookingIdVsResponseMap.get(serviceBookingId);
                ServiceBooking__c serviceBookingObj = mapServiceBookingRecord(sbResponse,planIdVsPlanMap,calledFromNDIAEvent); //Mapping the Service Booking record with the response from API
                
                if (sbResponse.result.items.size() < 1) {
                    serviceBookingObj.SyncErrorSBLineItem__c = System.Label.NDIA_NoRecordsFound;
                    EventLog__e event = LogService.logSaveResult(
                        'NDIA_SBLineItemDataSync', 'processSBLineItems', serviceBookingObj.SyncErrorSBLineItem__c, '', 
                        NDIA_NotificationHelper.eventName, NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBookingObj.ExternalId__c));
                    event.HttpResponse__c = JSON.serialize(sbResponse);
                    
                    if (NDIA_NotificationHelper.uniqueIdVsEventResponseMap != null) {
                        event.HttpResponse__c += '\nEvent JSON Response : \n' + 
                        NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBookingObj.ExternalId__c);    // NDIA Notification Event JSON Response
                    }

                    dmlLogs.add(event);
                }

                idVsServiceBookingMap.put(serviceBookingObj.ExternalId__c,serviceBookingObj);

                for (NDIA_DTO.ServiceBookingLineItemResponseResult result : sbResponse.result.items) {
                    //Mapping the Service Booking Line Item record with the response from API
                    ServiceBookingLineItem__c serviceBookingLineItem = mapSBLineItemsRecord(result,supportItemNumberVsListOfSupportItems,serviceBookingObj,nameVsSupportCategory);
                    ServiceBookingLineItemList.add(serviceBookingLineItem);
                    sbLineItemIdVsServiceBookingIdMap.put(serviceBookingLineItem.ExternalId__c ,serviceBookingObj.ExternalId__c);
                }
            }
        }
        if (!idVsServiceBookingMap.isEmpty() && idVsServiceBookingMap != null) {
            
            // Upsert Service Bookings
            upsertServiceBookings(serviceBookingIdVsResponseMap); 

            //upsert service booking line items
            if ( !ServiceBookingLineItemList.isEmpty()) {
                // upsert the service booking Line Item records--Start
                Schema.SObjectField fieldNameLineItem = ServiceBookingLineItem__c.Fields.ExternalId__c;
                Database.UpsertResult[] upsertLineItemResults = Database.upsert(ServiceBookingLineItemList, fieldNameLineItem, false);
                for (Integer index = 0, size = upsertLineItemResults.size(); index < size; index++) {
                    if (!upsertLineItemResults[index].isSuccess()) {             // Create log record details in case of dml failure
                        NDIA_DTO.ServiceBookingLineItemResult resultLineItemRow = createErrorRecordForSBLineItemLogging(ServiceBookingLineItemList[index],upsertLineItemResults[index]);
                        resultLineItemRow.errors = '';
                        for (Database.Error error: upsertLineItemResults[index].getErrors()) {
                            resultLineItemRow.errors += error;
                        }
                        resultLineItemRow.serviceBookingId = sbLineItemIdVsServiceBookingIdMap.get(ServiceBookingLineItemList[index].ExternalId__c);
                        ServiceBooking__c serviceBookingObj = idVsServiceBookingMap.get(sbLineItemIdVsServiceBookingIdMap.get(ServiceBookingLineItemList[index].ExternalId__c));
                        serviceBookingObj.SyncErrorSBLineItem__c = (resultLineItemRow.errors.length() > 255) ? 
                                                                    resultLineItemRow.errors.substring(0, 255) : resultLineItemRow.errors;
                        idVsServiceBookingMap.put(serviceBookingObj.ExternalId__c, serviceBookingObj);
                        EventLog__e evt = LogService.logSaveResult (
                            'NDIA_SBLineItemDataSync', 'processSBLineItems', JSON.serialize(resultLineItemRow), '',
                            NDIA_NotificationHelper.eventName, NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBookingObj.ExternalId__c));

                        evt.HttpResponse__c = JSON.serialize(serviceBookingIdVsResponseMap.get(resultLineItemRow.serviceBookingId));
                        
                        if (NDIA_NotificationHelper.uniqueIdVsEventResponseMap != null) {
                            evt.HttpResponse__c += '\nEvent JSON Response : \n' + 
                            NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBookingObj.ExternalId__c);    // NDIA Notification Event JSON Response;
                        }
                        
                        dmlLogs.add(evt);
                        //Need to add incase of failure
                    } 
                }
                // upsert the service booking Line Item records--End

                //update the service booking records for error conditions
                upsertServiceBookings(serviceBookingIdVsResponseMap);
            }
        }
        //Insert Logs
        if (!dmlLogs.isEmpty()){
            LogService.insertLog(dmlLogs);
        }
        return idVsServiceBookingMap; //added return for TTP-980
    }

    /**
     * @description   This method performs upsert on Service Booking records
     * @author        Swapnil Bhapkar
     * @param         serviceBookingIdVsResponseMap : Map of Service Booking and Line item Response
     * @return        -
    **/
    public static void upsertServiceBookings(Map<String,NDIA_DTO.ServiceBookingLineItemResponse> serviceBookingIdVsResponseMap){
        Schema.SObjectField fieldName = ServiceBooking__c.Fields.ExternalId__c;
        Database.UpsertResult[] sbUpdateResults = Database.upsert(idVsServiceBookingMap.values(),fieldName, false);
        for (Integer index = 0, size = sbUpdateResults.size(); index < size; index++) {
            
            if (!sbUpdateResults[index].isSuccess()) {             // Create log record details in case of dml failure
                List<ServiceBooking__c> serviceBookingList = idVsServiceBookingMap.values();
                NDIA_DTO.ServiceBookingResult resultRow = createErrorRecordForServiceBookingLogging(serviceBookingList[index],sbUpdateResults[index]);
                resultRow.errors = '';
                for (Database.Error error: sbUpdateResults[index].getErrors()) {
                    resultRow.errors += error;
                }
                EventLog__e evt = LogService.logSaveResult('NDIA_SBLineItemDataSync', 'processSBLineItems', JSON.serialize(resultRow), '', 
                                    NDIA_NotificationHelper.eventName, NDIA_NotificationHelper.uniqueIdVsReplayIdMap.get(serviceBookingList[index].ExternalId__c));

                evt.HttpResponse__c = JSON.serialize(serviceBookingIdVsResponseMap.get(resultRow.serviceBookingId));
                
                if (NDIA_NotificationHelper.uniqueIdVsEventResponseMap != null) {
                    evt.HttpResponse__c += '\nEvent JSON Response : \n' + 
                    NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(resultRow.serviceBookingId);    // NDIA Notification Event JSON Response
                }

                dmlLogs.add(evt);
            } 
        } 
    }
    
    /**
     * @description   This method create Error object for Service Booking Record.
     * @author        Swapnil Bhapkar
     * @param         serviceBooking : Service Booking object
     *                upsertResultsObj : upsert result object
     * @return        wrapper of ServiceBookingResult is the return type
    **/
    public static NDIA_DTO.ServiceBookingResult createErrorRecordForServiceBookingLogging(ServiceBooking__c serviceBooking,Database.UpsertResult upsertResultsObj){
        NDIA_DTO.ServiceBookingResult serviceBookingResult = new NDIA_DTO.ServiceBookingResult();
        serviceBookingResult.serviceBookingId = serviceBooking.ExternalId__c;
        serviceBookingResult.clientId = serviceBooking.Account__c;
        serviceBookingResult.isCreated = upsertResultsObj.isCreated();
        serviceBookingResult.isSuccess = upsertResultsObj.isSuccess();
        serviceBookingResult.recordId = upsertResultsObj.getId();
        return serviceBookingResult;
    }
    
    /**
     * @description   This method create Error object for Service Booking Line Item Record.
     * @author        Swapnil Bhapkar
     * @param         serviceBookingLineItem : Service Booking Line Item object
     *                upsertResultsObj       : upsert result object
     * @return        wrapper of ServiceBookingLineItemResult is the return type
    **/
    public static NDIA_DTO.ServiceBookingLineItemResult createErrorRecordForSBLineItemLogging(ServiceBookingLineItem__c serviceBookingLineItem,Database.UpsertResult upsertResultsObj){
        NDIA_DTO.ServiceBookingLineItemResult sBLineItem = new NDIA_DTO.ServiceBookingLineItemResult();
        sBLineItem.externalId = serviceBookingLineItem.ExternalId__c;
        sBLineItem.isCreated = upsertResultsObj.isCreated();
        sBLineItem.isSuccess = upsertResultsObj.isSuccess();
        sBLineItem.recordId = upsertResultsObj.getId();
        return sBLineItem;
    }
    
    /**
     * @description   This method create ServiceBookingRecord
     * @author        Swapnil Bhapar
     * @param         sbResponse      : wrapper of ServiceBookingLineItemResponse, 
     *                planIdVsPlanMap : Map of Plan
     *                calledFromNDIAEvent : Indicates if payload was received from NDIA Notification
     * @return        service Booking object is the return type
    **/
    public static ServiceBooking__c mapServiceBookingRecord(NDIA_DTO.ServiceBookingLineItemResponse sbResponse,Map<String,Plan__c> planIdVsPlanMap,Boolean calledFromNDIAEvent){
        ServiceBooking__c serviceBookingObj = new ServiceBooking__c();
        Account accountObj = new Account(NDIS__c = sbResponse.result.participant);
        serviceBookingObj.ExternalId__c = sbResponse.result.service_booking_id;
        if(!String.IsBlank(sbResponse.result.booking_type)){
            serviceBookingObj.Type__c = sbResponse.result.booking_type;
        }
        /*IF THE PAYLOAD WAS RECEIVED FROM NDIA NOTIFICATION THEN WE WILL GET PLANMANAGER ATTRIBUTE*/
        if(calledFromNDIAEvent) {
            Plan__c objPlan = !planIdVsPlanMap.isempty() 
                        && planIdVsPlanMap.containsKey(
                            sbResponse.result.participant_plan_id + 
                            sbResponse.result.planManager) 
                            ? 
                            planIdVsPlanMap.get(sbResponse.result.participant_plan_id + 
                            sbResponse.result.planManager) 
                            : null;
            serviceBookingObj.Account__c = objPlan?.Client_Name__c;
            serviceBookingObj.Plan__c = objPlan?.Id ;
        }
        /*IF THE PAYLOAD WAS RECEIVED FROM CALLOUT THEN WE WILL NOT GET PLANMANAGER ATTRIBUTE*/
        else {
            serviceBookingObj.Account__r = accountObj;
            serviceBookingObj.Plan__c = !planIdVsPlanMap.isempty() 
                                    && planIdVsPlanMap.containsKey(sbResponse.result.participant_plan_id) ? 
                                    planIdVsPlanMap.get(sbResponse.result.participant_plan_id).Id : null;
        }
        
        
        if (String.IsNotBlank(sbResponse.result.start_date)) {
            serviceBookingObj.StartDate__c = Date.valueOf(sbResponse.result.start_date);
        }

        if (sbResponse.result.revised_end_date != '0000-00-00' 
            && String.isNotBlank(sbResponse.result.revised_end_date)) {
                serviceBookingObj.EndDate__c = Date.valueOf(sbResponse.result.revised_end_date);
        } else if (String.IsNotBlank(sbResponse.result.end_date)) {
            serviceBookingObj.EndDate__c = Date.valueOf(sbResponse.result.end_date);
        }

        if (String.IsNotBlank(sbResponse.result.submitted_date)) {
            serviceBookingObj.SubmittedDate__c = Date.valueOf(sbResponse.result.submitted_date);
        }

        if (sbResponse.result.inkind_program != null) {
            serviceBookingObj.Inkind__c = sbResponse.result.inkind_program;
        }
        
        serviceBookingObj.Status__c = sbResponse.result.status;
        serviceBookingObj.ProviderComments__c = sbResponse.result.provider_comments;
        serviceBookingObj.LastServiceBookingLineItemsSync__c = DateTime.now();
        serviceBookingObj.SyncErrorSBLineItem__c = '';
        serviceBookingObj.PRODA_Plan_Id__c = sbResponse.result.participant_plan_id;

        if (String.isNotBlank(sbResponse.result.start_date)) {
            serviceBookingObj.Name = picklistLabelVsApiName.get(serviceBookingObj.Type__c) + ' - ' + NDIA_DataSyncHelper.getStartDate(sbResponse.result.start_date.removeEnd(' 00:00:00')).format();
        }

        return serviceBookingObj;
    }
    
    /**
     * @description   This method create Service Booking Line Items Record
     * @author        Swapnil Bhapkar
     * @param         result : wrapper of ServiceBookingLineItemResponseResult, 
     *                supportItemNumberVsListOfSupportItems : Map of supportItemNumber with SupportItems, 
     *                serviceBookingObj : object of Service Booking
     *                nameVsSupportCategory : Map of Support Category
     * @return        service Booking Line Item Object is the return type
    **/
    public static ServiceBookingLineItem__c mapSBLineItemsRecord(
        NDIA_DTO.ServiceBookingLineItemResponseResult result, Map<String, List<SupportItem__c>> supportItemNumberVsListOfSupportItems,
        ServiceBooking__c serviceBookingObj, Map<String,SupportCategory__c> nameVsSupportCategory
    ) {
        ServiceBookingLineItem__c serviceBookingLineItem = new ServiceBookingLineItem__c();
        ServiceBooking__c serviceBookingObjtoLink = new ServiceBooking__c(ExternalId__c = serviceBookingObj.ExternalId__c);

        serviceBookingLineItem.SupportCategory__c = nameVsSupportCategory.containsKey(result.product_category) ? 
                                                        nameVsSupportCategory.get(result.product_category).Id : null;
        serviceBookingLineItem.SupportItemNumber__c = result.product_category_item;
        serviceBookingLineItem.SupportItemName__c = result.product_category_item_desc;

        // TTP-975  update external Id stamping
        serviceBookingLineItem.ExternalId__c =  String.isNotBlank(serviceBookingLineItem.SupportItemNumber__c) ? 
                                                    serviceBookingObj.ExternalId__c + ' - ' + result.product_category + ' - ' + serviceBookingLineItem.SupportItemNumber__c : 
                                                    serviceBookingObj.ExternalId__c + ' - ' + result.product_category;
        
        serviceBookingLineItem.Quantity__c = result.quantity;
        serviceBookingLineItem.AllocatedFunds__c = result.allocated_amount;
        serviceBookingLineItem.FundsRemaining__c = result.remaining_amount;
        serviceBookingLineItem.ServiceBooking__r = serviceBookingObjtoLink;
        return serviceBookingLineItem;
    }

    /**
     * @description      Deserialize error response 
     * @author           Sonali Takke
     * @param            responseBody : Response body
     * @return           error : String 
    **/
    public static String deserializeErrorResponse(String responseBody) {
        try {
            NDIA_DTO.ErrorResponse body = (NDIA_DTO.ErrorResponse) JSON.deserialize(responseBody, NDIA_DTO.ErrorResponse.class);
            String error = (body.errors != null && body.errors.size() > 0) ? body.errors[0].detail : '';
            return error;
        } catch(JSONException jes) {
            NDIA_DTO.ErrorResponseString body = (NDIA_DTO.ErrorResponseString) JSON.deserialize(responseBody, NDIA_DTO.ErrorResponseString.class);
            String error = (body.errors != null && body.errors.size() > 0) ? body.errors[0] : (body.moreInformation != null ? body.moreInformation : '');
            return error;
        }
    }
}