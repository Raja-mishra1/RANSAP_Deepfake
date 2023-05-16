/**
 * @description     [TTP-1036] Apex Trigger Handler for processing SB_NEW NDIA_Notification__e Platform Event Object
 * @company         Cloudwerx 
 * @date            09-27-2021
 * @testClass       NDIA_Event_SBNewTest
**/

public without sharing class NDIA_Event_SBNew implements NDIA_NotificationHandler {

    public static List <NDIA_DTO.ServiceBookingResponseResult> serviceBookingLineItemWrapper = new List <NDIA_DTO.ServiceBookingResponseResult>();
    public static Map <String,NDIA_DTO.ServiceBookingLineItemResponse> serviceBookingIdVsResponseMap = new Map <String,NDIA_DTO.ServiceBookingLineItemResponse>();
    
    /**
     * @description      Method to collect all the ServiceBooking responses published in the SB_NEW event
     * @author           Aman Agarwal
     * @param            listOfResponse : list of response came from the SB_NEW event published by MPM Middleware
     * @return           void           
    **/

    public void run (List <String> listOfResponse) {
        List<EventLog__e> errorLogs = new List <EventLog__e>();
        NDIA_NotificationHelper.eventName = 'SB_NEW'; // static variable used to pass the event name

        for (String rawResponse : listOfResponse) {
            try {
                NDIA_DTO.ServiceBookingResponseResult result = NDIA_DTO.parseServiceBookingResponseResult(rawResponse);
                if (result.service_booking_id != null && result.service_booking_id != '') { // check for service booking id
                    // Date Validation
                    if (!NDIA_NotificationHelper.verifyDateFormat(result.start_date)) {
                        EventLog__e event = LogService.logSaveResult(
                            'NDIA_Event_SBNew', 'run', 'Start Date is invalid : ' + result.start_date, '', 
                            NDIA_NotificationHelper.eventName, result.event_replay_id);
                        event.HTTPResponse__c = rawResponse;
                        errorLogs.add(event);
                    } else if (!NDIA_NotificationHelper.verifyDateFormat(result.end_date)) {
                        EventLog__e event = LogService.logSaveResult(
                            'NDIA_Event_SBNew', 'run', 'End Date is invalid : ' + result.end_date, '', 
                            NDIA_NotificationHelper.eventName, result.event_replay_id);
                        event.HTTPResponse__c = rawResponse;
                        errorLogs.add(event);
                    } else if (!NDIA_NotificationHelper.verifyDateFormat(result.revised_end_date)) {
                        EventLog__e event = LogService.logSaveResult(
                            'NDIA_Event_SBNew', 'run', 'Revised End Date is invalid : ' + result.revised_end_date, '', 
                            NDIA_NotificationHelper.eventName, result.event_replay_id);
                        event.HTTPResponse__c = rawResponse;
                        errorLogs.add(event);
                    } else {
                        serviceBookingLineItemWrapper.add(result);
                        // static map of ServiceBooking Id with Notification Event Replay Id 
                        NDIA_NotificationHelper.uniqueIdVsReplayIdMap.put(result.service_booking_id, result.event_replay_id);
                        // static map of ServiceBooking Id with with Notification Event Replay Id
                        NDIA_NotificationHelper.uniqueIdVsEventResponseMap.put(result.service_booking_id, rawResponse);
                    }
                } else {
                    // service booking id is not present
                    EventLog__e event = LogService.logSaveResult(
                        'NDIA_Event_SBNew', 'run', 'Service booking id is blank in the event json response', '', 
                        NDIA_NotificationHelper.eventName, result.event_replay_id);
                    event.HTTPResponse__c = rawResponse;
                    errorLogs.add(event);
                }
            } catch (Exception e) {
                // parsing error
                EventLog__e event = LogService.logSaveResult('NDIA_Event_SBNew', 'run', 'Parsing Error - ' + e.getMessage(), '', NDIA_NotificationHelper.eventName, '');
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
     * @description      Method calls NDIA_SBLineItemDataSync.processSBLineItems() method which 
     *                   upserts Service Bookings along with its Line Items received from the platform event
     * @author           Aman Agarwal
     * @param            None 
     * @return           void
    **/

    public void processResponse () {
        // Set<String> prodaPlanIds = new Set<String>();
        for (NDIA_DTO.ServiceBookingResponseResult sbWrapper : serviceBookingLineItemWrapper) {
            NDIA_DTO.ServiceBookingLineItemResponse wrapperObj = new NDIA_DTO.ServiceBookingLineItemResponse();
            wrapperObj.success = true;
            wrapperObj.result = sbWrapper;
            // prodaPlanIds.add(sbWrapper.participant_plan_id);
            serviceBookingIdVsResponseMap.put(sbWrapper.service_booking_id, wrapperObj);
        }   
        
        if (!serviceBookingIdVsResponseMap.isEmpty()) {
            /*SECOND PARAMETER (TRUE) INDICATES IF SERVICEBOOKINGIDVSRESPONSEMAP 
            WAS REVEIVED FROM NOTIFICATION EVENT. IF THE SERVICEBOOKINGIDVSRESPONSEMAP
            IS RECEIVED FROM NDIA_SBLINEITEMDATASYNC.GETSBLINEITEMS CALLOUT THEN WE
            NEED TO SET THIS PARAMETER AS FALSE.*/
            NDIA_SBLineItemDataSync.processSBLineItems(serviceBookingIdVsResponseMap, true);
        }

        /* NOTE : commenting the code as the current API limit for NDIA Budget sync is 100 calls per hour, 
                  can be uncommented later if limit is increased */      
        //NDIA_DataSyncHelper.refreshBudget(prodaPlanIds); // call method to sync budget
    }
}