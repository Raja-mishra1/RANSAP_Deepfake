/**
* @description      [TTP-777][TTP-1876] This class contains code to on-demand sync service booking data from NDIA 
* @company          Cloudwerx
* @date             03-12-2021
* @testClass        NDIA_ServiceBookingDataSyncTest
**/

public without sharing class NDIA_OnDemandServiceBookingSync {
    
    public static Long calloutMs = 0;
    public static List<PLan__c> planList = new List<PLan__c>();

    /**
     * @description     Invocable method to perform on-demand sync of Service Bookings from NDIS to Salesforce
     * @author          Mehul Shah
     * @param           planIds : Plan Id for which service booking record needs to be synced. 
     * @return          String message to determine if Sync is success or failure.
    **/

    @InvocableMethod(label='Sync NDIS Service Bookings' description='On-demand sync of client service bookings from NDIS to Salesforce.' category='Account')
    public static List<String> syncServiceBookingsOnDemand(List<ID> planIds) {
        List<String> accountIds = new List<String>();
        Set<String> prodaPlanIds = new Set<String>();

        planList = [SELECT Id, Client_Name__c, PlanManager__c, Proda_Plan_Id__c, LastServiceBookingSync__c, Sync_Error_Service_Booking__c FROM Plan__c WHERE Id IN : planIds];

        for (Plan__c plan : planList) {
            accountIds.add(plan.Client_Name__c);
            prodaPlanIds.add(plan.Proda_Plan_Id__c);
        }
        
        List<Account> accountToSync = NDIA_DataSyncService.getOnDemandSBSyncQuery(accountIds);  

        List<ServiceBooking__c> serviceBookingList = [SELECT Id, Name, 
                                                            LastServiceBookingLineItemsSync__c, 
                                                            Plan__c, Account__c, 
                                                            Account__r.NDIS__c, ExternalId__c,
                                                            PlanManager__c
                                                      FROM ServiceBooking__c 
                                                      WHERE Account__c != NULL 
                                                      AND Account__r.NDIS__c != NULL AND Account__c IN : accountToSync Limit 50000]; //ACEM-2 added query limit

        if (accountToSync.isEmpty()){
            return new List<String>{ Label.NdiaOnDemandServiceBookingSyncInvalid };
        } 

        NDIA_ServiceBookingDataSync.isOnDemandSync = true;
        Map<String,NDIA_DTO.ServiceBookingResponse> mapOfServiceBookingResponse = NDIA_ServiceBookingDataSync.getServiceBookings(accountToSync, null);  // fetch service bookings via callout
        NDIA_ServiceBookingDataSync.idVsAccountPlansMap.put(accountIds[0], new List<Plan__c>{planList[0]});

        for (NDIA_DTO.ServiceBookingResponse response : mapOfServiceBookingResponse.values()) {
            Integer i=0;
            while (i<response.result.size()) {
                if (!prodaPlanIds.contains(response.result[i].participant_plan_id)) {       // prcoess only service bookings related to the selected plan
                    response.result.remove(i);                                              // if corresponding plan is not found, remove the service booking response 
                } else {
                    i++;
                }
            }
        }

        if (calloutMs > 110000) {   // if callout time limit is greater than 110 seconds
            return processServiceBookingResponse(mapOfServiceBookingResponse, accountIds);  
        } else {    // if callout time limit is less than 110 seconds, fetch the SB Line Items as well & process the same
            List<ServiceBooking__c> sbObjList = new List<ServiceBooking__c>();
            Set<String> serviceBookingExternalIds = new Set<String>();
    
            for (ServiceBooking__c sb : serviceBookingList) {
                serviceBookingExternalIds.add(sb.ExternalId__c);
            }
    
            for (NDIA_DTO.ServiceBookingResponse response : mapOfServiceBookingResponse.values()) {
                for (Integer i=0, size=response.result.size(); i<size; i++) {
                    if (!serviceBookingExternalIds.contains(response.result[i].service_booking_id) && prodaPlanIds.contains(response.result[i].participant_plan_id)) {   // add newly created service bookings in PRODA in local list 
                        System.debug('MISSING SB : ' + response.result[i].service_booking_id);
                        Account accountObj = new Account(NDIS__c = response.result[i].participant);
                        ServiceBooking__c serviceBookingObj = new ServiceBooking__c(ExternalId__c = response.result[i].service_booking_id,
                                                                                    PlanManager__c = planList[0].PlanManager__c);
                        serviceBookingObj.Account__r = accountObj;
                        sbObjList.add(serviceBookingObj);
                    } 
                }
            }
    
            serviceBookingList.addAll(sbObjList);
    
            Map<String,NDIA_DTO.ServiceBookingLineItemResponse> mapOfSBLineItemResponse = NDIA_SBLineItemDataSync.getSBLineItems(serviceBookingList,null);  // fetch service bookings & its line items via callout
            if (mapOfSBLineItemResponse == null) {  // if callout time execeeded for Line items API callout, only process the service bookings
                System.debug('CALLOUT LIMIT EXECEEDED!!!');
                return processServiceBookingResponse(mapOfServiceBookingResponse, accountIds);
            } else {    // process the service bookings & its line items
                List<String> responseStringList = processServiceBookingResponse(mapOfServiceBookingResponse, accountIds);
                
                for (String s : responseStringList) {
                    if (s.contains(Label.NdiaOnDemandServiceBookingSyncError)) {
                        return responseStringList;
                    }
                }
                
                /*SECOND PARAMETER (FALSE) INDICATES THAT MAPOFSBLINEITEMRESPONSE 
                WAS REVEIVED FROM NDIA_SBLINEITEMDATASYNC.GETSBLINEITEMS CALLOUT. 
                IF THE MAPOFSBLINEITEMRESPONSE WAS RECEIVED FROM NDIA NOTIFICATION THEN WE
                NEED TO SET THIS PARAMETER AS TRUE.*/
                Map<String, ServiceBooking__c> ServiceBookingData = NDIA_SBLineItemDataSync.processSBLineItems(mapOfSBLineItemResponse, false);
                for (String sbId : ServiceBookingData.keySet()) {
                    ServiceBooking__c sbObj = ServiceBookingData.get(sbId);
                    if (sbObj.SyncErrorSBLineItem__c.contains(Label.NdiaOnDemandSBLineSyncError)) {
                        return new List<String>{ Label.NdiaOnDemandSBLineSyncError + ' ' + sbObj.SyncErrorSBLineItem__c+'.'};
                    } 
                }
                
                return new List<String>{ Label.NdiaOnDemandServiceBookingSyncSuccess };
            }
        }
    }

    /**
     * @description     Method to perform Service Bookings sync from NDIS to Salesforce
     * @author          Mehul Shah
     * @param           accountIds : Account Ids for which plan record needs to be synced.
     *                  mapOfServiceBookingResponse : Map of Account Id vs Service Booking API Response
     * @return          String message to determine if Sync is success or failure.
    **/

    public static List<String> processServiceBookingResponse (Map<String,NDIA_DTO.ServiceBookingResponse> mapOfServiceBookingResponse, List<String> accountIds) {

        Map<Id, Account> accountData = NDIA_ServiceBookingDataSync.processServiceBookings(mapOfServiceBookingResponse);
        List<Plan__c> planList = NDIA_ServiceBookingDataSync.idVsAccountPlansMap.get(accountIds[0]);
        if (String.isEmpty(planList[0].Sync_Error_Service_Booking__c)) {   // Service Booking Sync Successful
            return new List<String>{ Label.NdiaOnDemandServiceBookingSyncSuccess };
        } else {
            return new List<String>{ Label.NdiaOnDemandServiceBookingSyncError + ' ' + planList[0].Sync_Error_Service_Booking__c + '.'};
        }
    }
}