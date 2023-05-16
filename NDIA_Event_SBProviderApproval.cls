/**
 * @description      [TTP-1034] Apex Trigger Handler for processing NDIS_SERVICBK_PROVID_APPR 
 *                   NDIA_Notification__e Platform Event Object
 * @company          Cloudwerx
 * @date             06/19/2021
 * @testClass        NDIA_Event_SBProviderApproval_Test
**/

public without sharing class NDIA_Event_SBProviderApproval implements NDIA_NotificationHandler {

    public static final Case_Batch_Configuration__mdt CASE_MAPPING = Case_Batch_Configuration__mdt.getInstance('NDIS_SERVICBK_PROVID_APPR');
    public Map <String, NDIA_NotificationDTO.ServiceBookingUpsert> serviceBookingWrapperMap = new Map <String, NDIA_NotificationDTO.ServiceBookingUpsert>();
    public static List<EventLog__e> dmlLogs = new List<EventLog__e>();

    /**
     * @description     Method parses the Data received from the platform Event & calls method for further processing
     * @author          Sonali Takke
     * @param           notificationJsonMessageList : List of messages published to platform Event Json 
    **/ 
    public void run(List <String> notificationJsonMessageList) {
        List<EventLog__e> errorLogs = new List <EventLog__e>();
        NDIA_NotificationHelper.eventName = 'SERVICBK_PROVID_APPR'; // static variable used to pass the event name

        for (String message : notificationJsonMessageList) {
            try {
                NDIA_NotificationDTO.ServiceBookingUpsert result = NDIA_NotificationDTO.parseServiceBookingInfo(message);
                if (result.serviceBookingId != null && result.serviceBookingId != '') {  // check for service booking id
                    serviceBookingWrapperMap.put(result.serviceBookingId, result);
                    // static map of ServiceBooking Id with Notification Event Replay Id 
                    NDIA_NotificationHelper.uniqueIdVsReplayIdMap.put(result.serviceBookingId, result.event_replay_id);
                    // static map of ServiceBooking Id with Event Response
                    NDIA_NotificationHelper.uniqueIdVsEventResponseMap.put(result.serviceBookingId,message);
                } else {
                    // service booking id is not present
                    EventLog__e event = LogService.logSaveResult(
                        'NDIA_Event_SBProviderApproval', 'run', 'Service booking id is blank in the event json response' , '', 
                        NDIA_NotificationHelper.eventName, result.event_replay_id);
                        event.HTTPResponse__c = message;
                    errorLogs.add(event);
                }
            } catch (Exception e) {
                // parsing error
                EventLog__e event = LogService.logSaveResult(
                    'NDIA_Event_SBProviderApproval', 'run', 'Parsing Error - '+e.getMessage() , '', 
                    NDIA_NotificationHelper.eventName, '');
                    event.HTTPResponse__c = message;
                errorLogs.add(event);
            }
        }

        if (!errorLogs.isEmpty()) {
            LogService.insertLog(errorLogs);
        }

        processResponse();
    }
 
    /**
     * @description     Creates case with necessary details for every Service booking Upsert 
     * @author          Sonali Takke
    **/  
    public void processResponse() {
        Set<String> serviceBookingExternalIdSet = new Set<String>();
        List<Case> caseList = new List<Case>();
        List<String> serviceBookingList = new List<String>();
        Map<String,String> mapSBExternalIdVsAccountId = new Map<String,String>();

        for (ServiceBooking__c eachServiceBooking : [
                SELECT Id, Name, LastServiceBookingLineItemsSync__c, Plan__c, Account__c, Account__r.NDIS__c, ExternalId__c 
                FROM ServiceBooking__c 
                WHERE ExternalId__c IN :serviceBookingWrapperMap.keySet() Limit 50000 //ACEM-2 added query limit
            ]
        ) {
            mapSBExternalIdVsAccountId.put(eachServiceBooking.ExternalId__c, 
                                            eachServiceBooking.Account__c);
        }

        for (String serviceBookingId : serviceBookingWrapperMap.keySet()) {
            if (mapSBExternalIdVsAccountId.containsKey(serviceBookingId)) {
                // Create Case Record from Wrapper
                caseList.add(createCase(serviceBookingWrapperMap.get(serviceBookingId),
                                        mapSBExternalIdVsAccountId.get(serviceBookingId)));
                serviceBookingList.add(serviceBookingId);
            } else {
                // service booking id not found
                String errorMsg =  'Service Booking : ' + serviceBookingId + ' does not exist';
                EventLog__e evt = LogService.logSaveResult (
                        'NDIA_Event_SBProviderApproval', 'processResponse', errorMsg, '', 
                        NDIA_NotificationHelper.eventName, NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBookingId)
                );
                evt.HTTPResponse__c = NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBookingId);
                dmlLogs.add(evt);
            } 
        }

        if (!caseList.isEmpty()) {
            Database.SaveResult[] caseInsertResult = Database.Insert(caseList, false); 
            if (caseInsertResult != null && !caseInsertResult.isEmpty()) { 
                for (Integer index = 0, size = caseInsertResult.size(); index < size; index++) {
                    if(!(caseInsertResult[index]?.isSuccess())) {  //Create Error Log for failures
                        String errorDetails = string.valueOf(caseList[index])+' '+ 'Errors:';
                        for(Database.Error error: caseInsertResult[index]?.getErrors()) {
                            errorDetails += error;
                        }
                        String eventReplayId = caseList[index].Description.contains(serviceBookingList[index]) ? NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBookingList[index]) : '';
                        EventLog__e evt = LogService.logSaveResult (
                            'NDIA_Event_SBProviderApproval', 'processResponse', errorDetails, '', NDIA_NotificationHelper.eventName, eventReplayId
                        );
                        evt.HTTPResponse__c = NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBookingList[index]);
                        dmlLogs.add(evt);
                    }
                }
            }
        } 
        if (!dmlLogs.isEmpty()) LogService.insertLog(dmlLogs);  //Insert Logs
    }

    /**
     * @description     Method to create Case 
     * @author          Sonali Takke
     * @param           serviceBookingWrapper : Service booking Wrapper
     * @return          Case object record
    **/ 

    public static Case createCase(NDIA_NotificationDTO.ServiceBookingUpsert serviceBookingWrapper,
                                    String strAccountId                                
    ) {
        Case caseRecord = new Case();
        caseRecord.RecordTypeId = CASE_MAPPING?.Case_Record_Type_Id__c;
        caseRecord.Client__c = strAccountId; 
        caseRecord.Status = CASE_MAPPING?.Status__c; 
        caseRecord.Type = CASE_MAPPING?.Type__c;        
        caseRecord.Sub_Type__c = CASE_MAPPING?.Sub_Type__c;
        caseRecord.OwnerId = serviceBookingWrapper.planmanager.equalsIgnoreCase(NDSPConstants.NDSP) 
                                ? InvoiceRuleService.getQueueInfo.get(CASE_MAPPING?.NDSPOwnerName__c) 
                                : CASE_MAPPING?.Owner_Id__c;   
        caseRecord.Origin = CASE_MAPPING?.Case_Origin__c;      
        caseRecord.Priority = CASE_MAPPING?.Priority__c; 
        caseRecord.Subject = CASE_MAPPING?.Subject__c;
        caseRecord.Description =  CASE_MAPPING?.Description__c?.replace(
            'Insert Service Booking ID', serviceBookingWrapper.serviceBookingId
        );
        return caseRecord;
    }
}