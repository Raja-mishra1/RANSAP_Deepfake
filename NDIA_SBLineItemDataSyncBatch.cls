/**
 * @description  [TTP-975] Batch class for One-Time Migration Sync of Service Bookings Line Item between NDIA & SF
 * @company      Cloudwerx
 * @date         24/08/2021
 * @testClass    NDIA_SBLineItemDataSyncTest   
 **/

public without sharing class NDIA_SBLineItemDataSyncBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    public String query;

    public NDIA_SBLineItemDataSyncBatch (String query) {
        this.query = query;
    }

    public Iterable<sObject> start (Database.BatchableContext context) {
        List<ServiceBooking__c> serviceBookingList = Database.query(query);
        return serviceBookingList;
    }
    public void execute(Database.BatchableContext context, List<ServiceBooking__c> serviceBookingList) {
        try {
            Map<String,NDIA_DTO.ServiceBookingLineItemResponse> mapOfServiceBookingsResponse = NDIA_SBLineItemDataSync.getSBLineItems(
                                                                                                serviceBookingList, context.getJobId());                                                                                               
            /*SECOND PARAMETER (FALSE) INDICATES THAT MAPOFSERVICEBOOKINGSRESPONSE 
            WAS REVEIVED FROM NDIA_SBLINEITEMDATASYNC.GETSBLINEITEMS CALLOUT. 
            IF THE MAPOFSERVICEBOOKINGSRESPONSE WAS RECEIVED FROM NDIA NOTIFICATION THEN WE
            NEED TO SET THIS PARAMETER AS TRUE.*/                                                                                    
            NDIA_SBLineItemDataSync.processSBLineItems(mapOfServiceBookingsResponse, false); 
        } catch (Exception e) {
            System.debug('Exception occured ' +e.getMessage());
            // insert log record
            EventLog__e evt =  LogService.logSaveResult(
                'NDIA_SBLineItemDataSyncBatch', 'Execute',e.getMessage(), String.valueOf(context.getJobId()), '', ''); 
            LogService.insertLog(new List<EventLog__e>{ evt });
        }
    }

    public void finish(Database.BatchableContext context) {

    }
}