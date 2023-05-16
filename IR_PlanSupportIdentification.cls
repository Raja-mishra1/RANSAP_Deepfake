/**
 * @description  [TTP-46] Apex Class to implement Invoice Rule which identifies the Plan Supports
 * @company      Cloudwerx
 * @date         14/07/2021
 * @testClass    InvoiceRuleTest - unitTest_PlanSupportIdentification
**/

public without sharing class IR_PlanSupportIdentification implements InvoiceRuleGenerator {

    /**
     * @description      This Invoice Rule identifies the Plan Supports
     * @author           Mehul Shah
     * @param            invoice : Invoice Record on which the Rules run
     *                   result  : Instance of InvoiceRuleResult which holds the outcome of the rule
     * @return           InvoiceRuleResult is the return type that holds status & mutated data
    **/
    public InvoiceRuleResult executeRule(Invoice__c invoice, InvoiceRuleResult result) { 
        Set<Id> planIdSet = new Set<Id>();
        Set<String> supportCategoryNameSet = new Set<String>();
        List<PlanSupport__c> planSupportObjList = new List<PlanSupport__c>();
        Map<Id,String> lineItemVsRuleResult = new Map<Id,String>();
        String ruleStatus;
        boolean hasFailure = false;
        Map<Id, List<PlanSupport__c>> planSupportMap = new Map<Id, List<PlanSupport__c>>();

        // [AHOD -275]
        ServiceBookingRequest__c serviceBookingRequestObj;
        Map<Decimal, Decimal> mapOfCatgNumberWithAmount = new Map<Decimal, Decimal>();

        // Create lists of Plan Ids & Support Category Names
        for (Invoice_Line_Item__c lineItem : invoice.Invoice_Line_Items__r) {
            planIdSet.add(lineItem.Plan__c);
            supportCategoryNameSet.add(lineItem.Support_Item__r.SupportCategory__r.SupportCategoryCode__c);
        }

        // Fetch all Plan Supports
        List<PlanSupport__c> planSupportsList = InvoiceRuleService.getPlanSupportList(planIdSet, supportCategoryNameSet);

        // [AHOD - 275] query for any open SBR
        List<ServiceBookingRequest__c> openSBRList = InvoiceRuleService.getOpenSBR(invoice);        
        // Create Map of Plans and Plan Supports
        for (PlanSupport__c p : planSupportsList) {
            if (!planSupportMap.containsKey(p.Plan__c)) {
                planSupportMap.put(p.Plan__c, new List<PlanSupport__c> {p});
            } else {
                planSupportMap.get(p.Plan__c).add(p);
            }
        }

        // OPSNBOTS-28 query to get Plan Support Preference records for core categories
        Set<Id> SetOfPSPPlans= new Set<Id>();
        List<PlanSupportPreference__c> PSPList = InvoiceRuleService.getReservedBudgetPSPCountForCoreCategory(planIdSet);
        result.lockedBudgetList = PSPList;

        for (PlanSupportPreference__c psp : PSPList) {
            SetOfPSPPlans.add(psp.Plan__c);
        }

        for (Invoice_Line_Item__c invoiceLineItem : invoice.Invoice_Line_Items__r) { 
            Integer count = 0;
            Id planSupportId = null;
            PlanSupport__c planSupportObject = null; //Sprint-12/TTP-1649
            if (planSupportMap.containsKey(invoiceLineItem.Plan__c)) {

                // Fetch corresponding plan support list
                List<PlanSupport__c> planSupportList = planSupportMap.get(invoiceLineItem.Plan__c); 

                for (PlanSupport__c planSupportObj : planSupportList) {
                    // Check if the Support Category Code is equal to the Support Category Name on the Invoice Line Item
                    if (planSupportObj.SupportCategoryCode__c == invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryCode__c) {
                        count = count + 1;  // If matched, increment count of Plan Supports
                        planSupportId = planSupportObj.Id;
                        planSupportObject = planSupportObj; //Sprint-12/TTP-1649
                    }
                }
            }        
            if (count == 1) {     // Success
                invoiceLineItem.Plan_Support__c = planSupportId;  
                invoiceLineItem.Plan_Support__r = planSupportObject; //Sprint-12/TTP-1649
                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.PLAN_SUPPORT_IDENTIFIED);
            } else if (count > 1) {  // Failure
                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.PLAN_SUPPORTS_NOT_IDENTIFIED);
                hasFailure = true;
				//[NAPS-95 Added Ternary Operator to check brand flag]
                invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
            	InvoiceRuleConstant.NDSP_RELATIONSHIP_QUEUE : InvoiceRuleConstant.RELATIONSHIP_QUEUE;
            } else if (invoiceLineItem.Substitution_Plan_Support_Preferences__c != null) {  // Success, Claim As is present on line item
                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.CLAIM_AS_FOUND);
                //[NAPS-95 Added Ternary Operator to check brand flag]
                invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
            	InvoiceRuleConstant.NDSP_RELATIONSHIP_QUEUE : InvoiceRuleConstant.RELATIONSHIP_QUEUE;
            } else if (invoiceLineItem.Support_Item__r.SupportCategory__r.SupportTypeCode__c == 'ZCOR' 
                && invoiceLineItem.Plan__r.Active__c 
                && !SetOfPSPPlans.contains(invoiceLineItem.Plan__c)) { // OPSNBOTS-28 added PSP check
                
                if (invoice.Service_Booking_Request__c != NULL) {
                    // SBR is populated on invoice
                    hasFailure = true;
                    invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    String msg = InvoiceRuleConstant.EXISTING_COREALLOCATION
                                    .replace('[ReqType]', invoice.Service_Booking_Request__r?.RequestType__c)
                                    .replace('[Status]', invoice?.Service_Booking_Request__r?.Status__c)
                                    .replace('[ClientName]', invoice?.client__r?.Name);
                    msg = invoiceLineItem?.Plan__r != null 
                            ? msg.replace('[ProdaId]', invoiceLineItem?.Plan__r?.PRODA_Plan_Id__c) 
                            : msg.replace('[ProdaId]', '');
            
                    lineItemVsRuleResult.put(invoiceLineItem.id, msg);
					//[NAPS-95 Added Check for brand flag]
                    if (invoice.PlanManager__c == 'MPM') {
                        invoice.OwnerId = 'Not Started'.equalsIgnoreCase(invoice?.Service_Booking_Request__r?.Status__c) || 'In Progress'.equalsIgnoreCase(invoice?.Service_Booking_Request__r?.Status__c) ?
                        InvoiceRuleConstant.BUDGET_UPDATES : InvoiceRuleConstant.RELATIONSHIP_QUEUE;
                    }
                    else if (invoice.PlanManager__c == 'NDSP') {
                        invoice.OwnerId = 'Not Started'.equalsIgnoreCase(invoice?.Service_Booking_Request__r?.Status__c) || 'In Progress'.equalsIgnoreCase(invoice?.Service_Booking_Request__r?.Status__c) ?
                        InvoiceRuleConstant.NDSP_BUDGET_UPDATES_QUEUE : InvoiceRuleConstant.NDSP_RELATIONSHIP_QUEUE;
                    }
                } else if (invoice.Service_Booking_Request__r != NULL ) {
                    // Newly SBR created is populated on invoice
                    if (mapOfCatgNumberWithAmount.containsKey(invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryNumber__c)) {
                        // rollup the category amount
                        Decimal amount = mapOfCatgNumberWithAmount.get(invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryNumber__c);
                        amount += invoiceLineItem.Total__c;
                        mapOfCatgNumberWithAmount.put(invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryNumber__c, amount);
                    } else {
                        // add the New Support Category Number in existing JSON InvoiceSupportCategory__c

                        mapOfCatgNumberWithAmount.put(invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryNumber__c, invoiceLineItem.Total__c);
                        
                        List<Object> invoiceSupportCategoriesList = invoice.Service_Booking_Request__r?.InvoiceSupportCategory__c != '' ?
                                                                (List<Object>) JSON.deserializeUntyped(invoice.Service_Booking_Request__r.InvoiceSupportCategory__c)
                                                                : new List<Object>();

                        InvoiceRuleHelper.InvoiceSupportCategoryWrapper invoiceSCWrapperObj = new InvoiceRuleHelper.InvoiceSupportCategoryWrapper();
                        invoiceSCWrapperObj.SupportCategoryCode = invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryCode__c;
                        invoiceSCWrapperObj.SupportCategoryNumber = invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryNumber__c;
                        invoiceSCWrapperObj.SupportCategoryAmount = invoiceLineItem.Total__c;
                        invoiceSupportCategoriesList.add(invoiceSCWrapperObj); 
                        invoice.Service_Booking_Request__r.InvoiceSupportCategory__c = JSON.serialize(invoiceSupportCategoriesList); // add new category to json
                    }
                    
                    hasFailure = true;
                    invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    String msg = InvoiceRuleConstant.NEW_COREALLOCATION.replace('[ClientName]', invoice?.client__r?.Name);
                    msg = invoiceLineItem?.Plan__r != null 
                            ? msg.replace('[ProdaId]', invoiceLineItem?.Plan__r?.PRODA_Plan_Id__c) 
                            : msg.replace('[ProdaId]', '');                  
                    lineItemVsRuleResult.put(invoiceLineItem.id, msg);
                    //[NAPS-95 Added Ternary Operator to check brand flag]
                    invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
            		InvoiceRuleConstant.NDSP_BUDGET_UPDATES_QUEUE : InvoiceRuleConstant.BUDGET_UPDATES;
                } else if (!openSBRList.isEmpty()) {
                    // assign existing SBR
                    invoice.Service_Booking_Request__c = openSBRList[0].Id;
                    invoice.Service_Booking_Request__r = openSBRList[0];
                    hasFailure = true;
                    invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    String msg = InvoiceRuleConstant.EXISTING_COREALLOCATION
                                    .replace('[ReqType]', invoice.Service_Booking_Request__r?.RequestType__c)
                                    .replace('[Status]', invoice?.Service_Booking_Request__r?.Status__c)
                                    .replace('[ClientName]', invoice?.client__r?.Name);
                    msg = invoiceLineItem?.Plan__r != null  
                            ? msg.replace('[ProdaId]', invoiceLineItem?.Plan__r?.PRODA_Plan_Id__c) 
                            : msg.replace('[ProdaId]', '');
                    lineItemVsRuleResult.put(invoiceLineItem.id, msg);
                    //[NAPS-95 Added Ternary Operator to check brand flag]
                    invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
            		InvoiceRuleConstant.NDSP_BUDGET_UPDATES_QUEUE : InvoiceRuleConstant.BUDGET_UPDATES;
                } else {
                    // create new SBR
                    serviceBookingRequestObj = InvoiceRuleHelper.createSBRMapping(invoice, invoiceLineItem, System.Label.Create_CORE_Allocations);
                    // populate map of category number with amount
                    mapOfCatgNumberWithAmount.put(invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryNumber__c, invoiceLineItem.Total__c);
                    invoice.Service_Booking_Request__r = serviceBookingRequestObj;
                    hasFailure = true;
                    invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    String msg = InvoiceRuleConstant.NEW_COREALLOCATION.replace('[ClientName]', invoice?.client__r?.Name);
                    msg = invoiceLineItem?.Plan__r != null 
                            ? msg.replace('[ProdaId]', invoiceLineItem?.Plan__r?.PRODA_Plan_Id__c) 
                            : msg.replace('[ProdaId]', '');                    
                    lineItemVsRuleResult.put(invoiceLineItem.id, msg);
                    //[NAPS-95 Added Ternary Operator to check brand flag]
                    invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
            		InvoiceRuleConstant.NDSP_BUDGET_UPDATES_QUEUE : InvoiceRuleConstant.BUDGET_UPDATES;
                }
            } else {
                // failure
                hasFailure = true;
                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.PLAN_SUPPORT_NOT_FOUND);
                //[NAPS-95 Added Ternary Operator to check brand flag]
                invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
            	InvoiceRuleConstant.NDSP_RELATIONSHIP_QUEUE : InvoiceRuleConstant.RELATIONSHIP_QUEUE;
            }
              
        }


        // Set the json field in service booking request
        if (serviceBookingRequestObj != NULL) {
           
            List<Object> invoiceSupportCategories = (List<Object>) JSON.deserializeUntyped(serviceBookingRequestObj.InvoiceSupportCategory__c);
            for (Object obj : invoiceSupportCategories) {
                Map<String,Object> dataMap = new Map<String,Object>();
                dataMap = (Map<String,Object>)obj;
                if (mapOfCatgNumberWithAmount.containsKey(Decimal.valueOf(String.valueOf(dataMap.get('SupportCategoryNumber'))))) {
                    Object dataObj = dataMap.get('SupportCategoryNumber');
                    dataObj = mapOfCatgNumberWithAmount.get(Decimal.valueOf(String.valueOf(dataMap.get('SupportCategoryNumber')))).setScale(2,System.RoundingMode.HALF_UP);
                    dataMap.put('SupportCategoryAmount', dataObj);
                    obj = dataMap;
                   
                }
            }
            serviceBookingRequestObj.InvoiceSupportCategory__c = JSON.serialize(invoiceSupportCategories);

            // populate result variable for service booking
            result.serviceBookingReqt =  serviceBookingRequestObj;                                                    
        }
        

        // Set the ServiceBookingRequest for insert/update

        //Set rule result to fail if any of the invoice line item fails
        ruleStatus = hasFailure == true ? InvoiceRuleConstant.STATUS_FAIL : InvoiceRuleConstant.STATUS_PASS;
        
        return result.processRuleResult(result, null, invoice, null, ruleStatus, lineItemVsRuleResult);
    }
}