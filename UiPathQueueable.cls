/**
 * @description     [AHOD-465] Queuable class for adding SBR records to the UiPath queue by doing a callout
 * @company         Cloudwerx
 * @date            27/07/2022
 * @testClass       UiPathQueueableTest
**/
public with sharing class UiPathQueueable implements Queueable, Database.AllowsCallouts {

    private String accessToken;
    private List<Id> listOfIdsToAddIntoUipathQueue;

    
    /* @description Constructor method
    *  @param       listOfIdsToAddIntoUipathQueue list of ids of records to be inserted into UiPath queue.
    *  @param       accessToken Access token for UiPath orchestrator API.
    */
    public UiPathQueueable(List<Id> listOfIdsToAddIntoUipathQueue, String accessToken) {
        this.accessToken = accessToken;
        this.listOfIdsToAddIntoUipathQueue = listOfIdsToAddIntoUipathQueue;
    }

    /**
    * @description This methods sends request to uipath that adds serviceBookingRequest__c record to 
    *              UiPaths queue mentioned in metadata record.
    **/
    public void execute(QueueableContext context) {
        List<ServiceBookingRequest__c> listOfServiceBookingRequestsToAddIntoQueue = [SELECT Id,
                                                                                            RequestType__c,
                                                                                            RequestedBy__c,
                                                                                            Priority__c,
                                                                                            CaseSubType__c,
                                                                                            DoesActivePlanExist__c,
                                                                                            PriceGuideAmount14_034__c,
                                                                                            PriceGuideAmount14_033__c,
                                                                                            PriceGuideAmount14_032__c,
                                                                                            ClientLastName__c,
                                                                                            ClientDateOfBirth__c,
                                                                                            ClientNDISNumber__c,
																							planmanager__c,
                                                                                            UserProvidedTransportBudget__c,
                                                                                            UserProvidedStatedSupports__c,
                                                                                            SalesforceClaimingExperience__c ,// [TTP-2040],
                                                                                            BudgetAllocation__c, // [AHOD-270]
                                                                                            InvoiceSupportCategory__c //AHOD-411
                                                                                    FROM  ServiceBookingRequest__c
                                                                                    WHERE Id IN : this.listOfIdsToAddIntoUipathQueue
                                                                                    WITH SECURITY_ENFORCED
                                                                                    LIMIT 1000];
        for (ServiceBookingRequest__c objServiceBookingReq : listOfServiceBookingRequestsToAddIntoQueue) {
            if (this.accessToken != NULL) {
                if(Limits.getCallouts() <= Limits.getLimitCallouts()) {
                    HttpRequest req = new HttpRequest();
                    if (objServiceBookingReq.planmanager__c == 'MPM'){
                        req.setEndpoint('https://cloud.uipath.com/' + ServiceBookingRequestTriggerHandler.mdtRec.UIPathOrgName__c +'/'+ ServiceBookingRequestTriggerHandler.mdtRec.UIPathTenantName__c +'/odata/Queues/UiPathODataSvc.AddQueueItem ');
                    } else if (objServiceBookingReq.planmanager__c == 'NDSP'){
                        req.setEndpoint('https://cloud.uipath.com/' + ServiceBookingRequestTriggerHandler.mdtRec.UIPathOrgName__c +'/'+ ServiceBookingRequestTriggerHandler.mdtRec.NDSP_UiPath_TenantName__c +'/odata/Queues/UiPathODataSvc.AddQueueItem ');
                    }
                    req.setMethod('POST');
                    req.setTimeout(120000);
                    req.setHeader('Content-Type', 'application/json');
                    req.setHeader('Accept', 'application/json');//[SFDC-1271]
                    if (objServiceBookingReq.planmanager__c == 'MPM'){
                        req.setHeader('X-UIPATH-TenantName', ServiceBookingRequestTriggerHandler.mdtRec.UIPathTenantName__c);
                    } else if (objServiceBookingReq.planmanager__c == 'NDSP'){
                        req.setHeader('X-UIPATH-TenantName', ServiceBookingRequestTriggerHandler.mdtRec.NDSP_UiPath_TenantName__c);
                    }
                    req.setHeader('Authorization', 'Bearer ' + this.accessToken);
					//[NAP5-226]
                    if (objServiceBookingReq.planmanager__c == 'MPM') {
                    req.setHeader('X-UIPATH-OrganizationUnitId', ServiceBookingRequestTriggerHandler.mdtRec.UIPathOrganizationUnitId__c);
                    }
					//[NAP5-226]
					else if (objServiceBookingReq.planmanager__c == 'NDSP') {
                    req.setHeader('X-UIPATH-OrganizationUnitId', ServiceBookingRequestTriggerHandler.mdtRec.NDSP_UIPath_OrganizationUnitID__c);
                    }             

                    Map<String,Object> body = new Map<String,Object>();
                    Map<String,Object> itemData = new Map<String,Object>();
                    Map<String,Object> specificContent = new Map<String,Object>();
                    specificContent.put('Id', objServiceBookingReq.Id);
                    specificContent.put('RequestType__c', objServiceBookingReq.RequestType__c);
                    specificContent.put('RequestedBy__c', objServiceBookingReq.RequestedBy__c);     // [SFDC-1247] Changes by Mehul
                    specificContent.put('DoesActivePlanExist__c', objServiceBookingReq.DoesActivePlanExist__c);
                    specificContent.put('planmanager__c', objServiceBookingReq.planmanager__c);
                    specificContent.put('PriceGuideAmount14_034__c', objServiceBookingReq.PriceGuideAmount14_034__c);
                    specificContent.put('PriceGuideAmount14_033__c', objServiceBookingReq.PriceGuideAmount14_033__c);
                    specificContent.put('PriceGuideAmount14_032__c', objServiceBookingReq.PriceGuideAmount14_032__c);
                    specificContent.put('ClientLastName__c', objServiceBookingReq.ClientLastName__c);
                    specificContent.put('ClientDateOfBirth__c', objServiceBookingReq.ClientDateOfBirth__c);
                    specificContent.put('ClientNDISNumber__c', objServiceBookingReq.ClientNDISNumber__c);
                    specificContent.put('CaseSubType__c', objServiceBookingReq.CaseSubType__c); //Sprint 18 [SFDC-1303]
                    specificContent.put('UserProvidedTransportBudget__c', objServiceBookingReq.UserProvidedTransportBudget__c);
                    specificContent.put('UserProvidedStatedSupports__c', objServiceBookingReq.UserProvidedStatedSupports__c);
                    specificContent.put('SalesforceClaimingExperience__c', objServiceBookingReq.SalesforceClaimingExperience__c); // [TTP-2040]
                    specificContent.put('BudgetAllocation__c', objServiceBookingReq.BudgetAllocation__c); //[AHOD - 270]
                    
                    //START: AHOD-411
                    if (objServiceBookingReq.RequestType__c == 'Create CORE Allocations' ||
                        objServiceBookingReq.RequestType__c == 'Adjust CORE Allocations'
                       ) {
                        specificContent.put('BudgetAllocation__c', objServiceBookingReq.BudgetAllocation__c);
                        specificContent.put('InvoiceSupportCategory__c', objServiceBookingReq.InvoiceSupportCategory__c);
							//[NAP5-226]
                           if (objServiceBookingReq.planmanager__c == 'MPM') {
                               itemData.put('Name', ServiceBookingRequestTriggerHandler.mdtRec.UIPath_Core_Correction_QueueName__c);
                           }
						    //[NAP5-226]
                           else if (objServiceBookingReq.planmanager__c == 'NDSP') {
                               itemData.put('Name', ServiceBookingRequestTriggerHandler.mdtRec.NDSP_UIPath_Core_Correction_QueueName__c);
                           }
                           //[NAP5-226]
                       } else if (objServiceBookingReq.planmanager__c == 'NDSP') {
                           itemData.put('Name', ServiceBookingRequestTriggerHandler.mdtRec.NDSP_UIPath_QueueName__c);
                       }
                    else {
                        itemData.put('Name', ServiceBookingRequestTriggerHandler.mdtRec.UIPathQueueName__c);
                    }
                    //END: AHOD-411
                    itemData.put('Priority', objServiceBookingReq.Priority__c);
                    itemData.put('SpecificContent', specificContent);
                    body.put('itemData',  itemData);
                    req.setBody(JSON.serialize(body));
                    Http http = new Http();
                    HttpResponse res;
                    try {
                        res = http.send(req);
                        UiPathAddQueueResWrapper resWrapperObject = UiPathAddQueueResWrapper.parse(res.getBody());
                        if (res.getStatusCode()/100 == 2) {
                            objServiceBookingReq.Status__c = 'In Progress';
                            objServiceBookingReq.UiPathQueueRecordId__c = resWrapperObject.Id;
                        } else if (res.getStatusCode() == 400) {
                            objServiceBookingReq = ServiceBookingRequestTrigrHndlrException.setAddRecordToUiPathQueueError(objServiceBookingReq, 'Exception', 'UIPath', resWrapperObject.message + '\n Status Code :' + res.getStatusCode() + '\n UiPath Response :' + res.getBody());
                        } else {
                            objServiceBookingReq = ServiceBookingRequestTrigrHndlrException.setAddRecordToUiPathQueueError(objServiceBookingReq, 'Exception', 'UIPath', resWrapperObject.error.message + '\n Status Code :' + res.getStatusCode() + '\n UiPath Response :' + res.getBody());
                        }
                    } catch (Exception e) {
                        objServiceBookingReq = ServiceBookingRequestTrigrHndlrException.setAddRecordToUiPathQueueError(objServiceBookingReq, 'Exception', 'UIPath', e.getMessage() + '\n Status Code :' + res.getStatusCode() + '\n UiPath Response :' + res.getBody());
                    }
                } else {
                    objServiceBookingReq = ServiceBookingRequestTrigrHndlrException.setAddRecordToUiPathQueueError(objServiceBookingReq, 'Exception', 'Salesforce', 'Call-out Limit Exceeded.\n Cannot send Record to UiPath');
                    break;
                }
            } else {
                objServiceBookingReq = ServiceBookingRequestTrigrHndlrException.setAddRecordToUiPathQueueError(objServiceBookingReq, 'Exception', 'Salesforce', 'Access Token Not Found.\n Cannot send Record to UiPath');
            }
        }

        try {
            //Database.update(listOfServiceBookingRequestsToAddIntoQueue, false);
            update listOfServiceBookingRequestsToAddIntoQueue;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }
}