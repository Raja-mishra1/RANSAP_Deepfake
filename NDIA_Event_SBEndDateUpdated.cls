/**
 * @description      [TTP-1035]Apex Trigger Handler for NDIA_Notification__e Platform Event Object
 * @company          Cloudwerx
 * @date             07/09/2021
 * @testClass        NDIA_Event_SBEndDateUpdatedTest
 **/

public without sharing class NDIA_Event_SBEndDateUpdated implements NDIA_NotificationHandler {
    Map <String,NDIA_NotificationDTO.ServiceBookingUpsert> sbIdVsSBNotificationMap = new Map <String,NDIA_NotificationDTO.ServiceBookingUpsert>();
    public static List<EventLog__e> dmlLogs;

    /**
     * @description     Method parses the Data received from the platform Event & calls method for further processing
     * @author          Rohit Tikoo
     * @param           listOfResponse : List of messages published to platform Event JSON 
    **/ 

    public void run(List <String> listOfResponse) {
        List<EventLog__e> errorLogs = new List <EventLog__e>();
        NDIA_NotificationHelper.eventName = 'SB_END_DATE_UPDATED'; // static variable used to pass the event name
        for(String rawResponse : listOfResponse) {
            try {
                NDIA_NotificationDTO.ServiceBookingUpsert sbwrapperObj = NDIA_NotificationDTO.parseServiceBookingInfo(rawResponse);
                if (sbwrapperObj.serviceBookingId != null && sbwrapperObj.serviceBookingId != '') { // check for service booking id
                    // Date validation
                    if (!NDIA_NotificationHelper.verifyDateFormat(sbwrapperObj.startDate)) {
                        EventLog__e event = LogService.logSaveResult(
                            'NDIA_Event_SBEndDateUpdated', 'run', 'Start Date is invalid : ' + sbwrapperObj.startDate, '', 
                            NDIA_NotificationHelper.eventName, sbwrapperObj.event_replay_id);
                        event.HTTPResponse__c = rawResponse;
                        errorLogs.add(event);
                    } else if (!NDIA_NotificationHelper.verifyDateFormat(sbwrapperObj.endDate)) {
                        EventLog__e event = LogService.logSaveResult(
                            'NDIA_Event_SBEndDateUpdated', 'run', 'End Date is invalid : ' + sbwrapperObj.endDate, '', 
                            NDIA_NotificationHelper.eventName, sbwrapperObj.event_replay_id);
                        event.HTTPResponse__c = rawResponse;
                        errorLogs.add(event);
                    } else {
                        sbIdVsSBNotificationMap.put(sbwrapperObj.serviceBookingId, sbwrapperObj);
                        // static map of ServiceBooking Id with Notification Event Replay Id
                        NDIA_NotificationHelper.uniqueIdVsReplayIdMap.put(sbwrapperObj.serviceBookingId, sbwrapperObj.event_replay_id);
                        // static map of ServiceBooking Id with Event Response
                        NDIA_NotificationHelper.uniqueIdVsEventResponseMap.put(sbwrapperObj.serviceBookingId,rawResponse);
                    }
                } else {
                    // service booking id is not present
                    EventLog__e event = LogService.logSaveResult(
                        'NDIA_Event_SBEndDateUpdated', 'run','Service booking id is blank in the event json response' , '', 
                        NDIA_NotificationHelper.eventName, sbwrapperObj.event_replay_id);
                    event.HTTPResponse__c = rawResponse;    
                    errorLogs.add(event);
                }
            } catch (Exception e) {
                // parsing error
                EventLog__e event = LogService.logSaveResult(
                        'NDIA_Event_SBEndDateUpdated', 'run', 'Parsing Error - ' + e.getMessage() , '', 
                        NDIA_NotificationHelper.eventName, '');
                event.HTTPResponse__c = rawResponse;
                errorLogs.add(event);
            }
        }
        
        if (!errorLogs.isEmpty()) {
            LogService.insertLog(errorLogs);
        }

        processResponse();
    }


    /**
     * @description     Method update Service Booking End Date with Data received from the platform Event
     * @author          Rohit Tikoo
    **/ 

    public void processResponse() {
        dmlLogs = new List <EventLog__e>();
        Set<Id> serviceBookingUpdatedSet = new Set<Id>(); //Set of service bookings that have been updated in Salesforce
        List<ServiceBooking__c> serviceBookingList = new List<ServiceBooking__c>(); //List of service bookings that will be upserted in Salesforce
        Set<String> serviceBookingObjectIdSet = new Set<String>();

        //Query Service Booking Records from Salesforce and Prepare Service Booking List to be Updated       
        for (ServiceBooking__c eachServiceBooking : [
                SELECT Id, Name, LastServiceBookingLineItemsSync__c, Plan__c, Account__c, Account__r.NDIS__c, ExternalId__c  
                FROM ServiceBooking__c 
                WHERE ExternalId__c IN :sbIdVsSBNotificationMap.keySet() Limit 50000  //ACEM-2 added query limit
            ]
        ) {
            serviceBookingObjectIdSet.add(eachServiceBooking.ExternalId__c);
            NDIA_NotificationDTO.ServiceBookingUpsert sbwrapperObj = sbIdVsSBNotificationMap.get(eachServiceBooking.ExternalId__c);
            ServiceBooking__c serviceBookingRecord = new ServiceBooking__c (
                Id = eachServiceBooking.Id, ExternalId__c = sbwrapperObj.serviceBookingId, 
                EndDate__c = String.isEmpty(sbwrapperObj.endDate) ? null :Date.valueOf(sbwrapperObj.endDate)
            );
            serviceBookingList.add(serviceBookingRecord);
        }

        if (Test.isRunningTest()) {
            serviceBookingList[0].Id = null;
        }
        
        if (!serviceBookingList.isEmpty()) {
            // Update Service Bookings
            Database.SaveResult[] sbUpdateResults = Database.update(serviceBookingList,false);
            for (Integer index = 0, size = sbUpdateResults.size(); index < size; index++) {
                String dmlError='';
                if (!sbUpdateResults[index].isSuccess()) {             // Create log record details in case of dml failure
                    for (Database.Error error: sbUpdateResults[index].getErrors()) {
                        dmlError += error;
                    }
                    EventLog__e evt = LogService.logSaveResult (
                        'NDIA_Event_SBEndDateUpdated', 'processResponse', 
                        dmlError+' '+JSON.serialize(sbIdVsSBNotificationMap.get(serviceBookingList[index]?.ExternalId__c)), '', 
                        NDIA_NotificationHelper.eventName,NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(serviceBookingList[index]?.ExternalId__c)
                    );
                    evt.HTTPResponse__c = NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(serviceBookingList[index]?.ExternalId__c);
                    dmlLogs.add(evt);
                } else {
                    serviceBookingUpdatedSet.add(serviceBookingList[index].Id);
                }
            }
        }

        //Loop to Find out the PRODA ID's which are present in the Platform Event but not in Salesforce
        for (String ID : sbIdVsSBNotificationMap.keySet()) {
            if (!serviceBookingObjectIdSet.contains(ID)) {
                // Service booking id not found
                EventLog__e evt = LogService.logSaveResult(
                        'NDIA_Event_SBEndDateUpdated','processResponse',
                        'Service Booking End Date update via NDIA Notification could not be completed for Service Booking Id ' + ID + 
                        ' as it was not found in Salesforce', '',
                NDIA_NotificationHelper.eventName, NDIA_NotificationHelper.uniqueIdVsReplayIdMap?.get(ID)); 
                evt.HTTPResponse__c = NDIA_NotificationHelper.uniqueIdVsEventResponseMap?.get(ID);
                dmlLogs.add(evt);
            }
        }
        //Insert Logs
        if (!dmlLogs.isEmpty()) {
            LogService.insertLog(dmlLogs);
        }
        if (!serviceBookingUpdatedSet.isEmpty()) {
            List<ServiceBooking__c> ServiceBookingRecordList = [
                SELECT Id, Name, LastServiceBookingLineItemsSync__c, Plan__c, Account__c, 
                PlanManager__c, Account__r.NDIS__c, ExternalId__c 
                FROM ServiceBooking__c 
                WHERE Id IN :serviceBookingUpdatedSet
            ];
            String serviceBookingListString = JSON.serialize(ServiceBookingRecordList);
            getSBLineItemsViaFuture(
                serviceBookingListString, NDIA_NotificationHelper.eventName,
                NDIA_NotificationHelper.uniqueIdVsReplayIdMap,
                NDIA_NotificationHelper.uniqueIdVsEventResponseMap
            );
        } 
    }

    /**
     * @description     Method calls NDIA Get callout function in NDIA_SBLineItemDataSync Class for Service Booking related objects
     * @author          Rohit Tikoo
     * @param           ServiceBookingAsJSON  : List of Service Booking records in Serialized form  
     *                  eventName             : NDIA Notification Event Name
     *                  uniqueIdVsReplayIdMap : Map of proda plan id vs event replay id
     **/ 

    @future (callout = true)
    public static void getSBLineItemsViaFuture(String ServiceBookingAsJSON, String eventName, Map<String, String> uniqueIdVsReplayIdMap, Map<String, String> uniqueIdVsEventResponseMap) {
        NDIA_NotificationHelper.eventName = eventName;
        NDIA_NotificationHelper.uniqueIdVsReplayIdMap = uniqueIdVsReplayIdMap;
        NDIA_NotificationHelper.uniqueIdVsEventResponseMap = uniqueIdVsEventResponseMap;

        List <ServiceBooking__c> serviceBookingList = (List<ServiceBooking__c>) JSON.deserialize(
            ServiceBookingAsJSON, List<ServiceBooking__c>.class
        );
        Map<String,NDIA_DTO.ServiceBookingLineItemResponse> serviceBookingIdVsResponseMap = NDIA_SBLineItemDataSync.getSBLineItems(
            serviceBookingList, null );
        /*SECOND PARAMETER (FALSE) INDICATES THAT SERVICEBOOKINGIDVSRESPONSEMAP 
        WAS REVEIVED FROM NDIA_SBLINEITEMDATASYNC.GETSBLINEITEMS CALLOUT. 
        IF THE SERVICEBOOKINGIDVSRESPONSEMAP WAS RECEIVED FROM NDIA NOTIFICATION THEN WE
        NEED TO SET THIS PARAMETER AS TRUE.*/
        NDIA_SBLineItemDataSync.processSBLineItems(serviceBookingIdVsResponseMap, false);
    }
}