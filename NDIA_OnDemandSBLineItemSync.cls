/**
* @description      [TTP-980] This class contains code to on-demand sync service booking line item data from NDIA 
* @company          Cloudwerx
* @date             09-09-2021
* @testClass        NDIA_SBLineItemDataSyncTest
**/

public without sharing class NDIA_OnDemandSBLineItemSync {

    /**
     * @description     Invocable method to perform on-demand sync of Service Bookings from NDIS to Salesforce
     * @author          Prithviraj Deshmukh
     * @param           accountIds : Account Id for which plan record needs to be synced. 
     * @return          String message to determine if Sync is success or failure.
    **/

    @InvocableMethod(label='Sync NDIS Service Booking Line Items' description='On-demand sync of client service booking items from NDIS to Salesforce.' category='ServiceBooking__c')
    public static List<String> syncServiceBookingsOnDemand(List<Id> serviceBookingIds) {
        List<ServiceBooking__c> serviceBookingList =  NDIA_DataSyncService.getOnDemandSBLineItemSyncQuery(serviceBookingIds);//new List<ServiceBooking__c>();
        
        List<String> serviceBookingProdaIdSet = new List<String>();
        for (ServiceBooking__c serviceBookingRec : serviceBookingList) {
            serviceBookingProdaIdSet.add(serviceBookingRec.ExternalId__c);
        }

        Map<String,NDIA_DTO.ServiceBookingLineItemResponse> mapOfServiceBookingsResponse = NDIA_SBLineItemDataSync.getSBLineItems(serviceBookingList,null);

        if (mapOfServiceBookingsResponse.isEmpty() || !mapOfServiceBookingsResponse.containsKey(serviceBookingProdaIdSet[0])) {
            ServiceBooking__c sbRecord = NDIA_SBLineItemDataSync.idVsServiceBookingMap.get(serviceBookingProdaIdSet[0]);
            return new List<String>{ Label.NdiaOnDemandSBLineSyncError + ' ' + sbRecord?.SyncErrorSBLineItem__c+'.'};
        } else {
            /*SECOND PARAMETER (FALSE) INDICATES THAT MAPOFSERVICEBOOKINGSRESPONSE 
            WAS REVEIVED FROM NDIA_SBLINEITEMDATASYNC.GETSBLINEITEMS CALLOUT. 
            IF THE MAPOFSERVICEBOOKINGSRESPONSE WAS RECEIVED FROM NDIA NOTIFICATION THEN WE
            NEED TO SET THIS PARAMETER AS TRUE.*/
            Map<String, ServiceBooking__c> ServiceBookingData = NDIA_SBLineItemDataSync.processSBLineItems(mapOfServiceBookingsResponse, false);
            ServiceBooking__c processedServiceBooking = ServiceBookingData.get(serviceBookingProdaIdSet[0]);
            if (String.isEmpty(processedServiceBooking.SyncErrorSBLineItem__c)) {//sync successful
                return new List<String>{ Label.NdiaOnDemandSBLineSyncSuccess };
            } else {
                return new List<String>{ Label.NdiaOnDemandSBLineSyncError + ' ' + processedServiceBooking.SyncErrorSBLineItem__c+'.'};
            }
        }
    }
}