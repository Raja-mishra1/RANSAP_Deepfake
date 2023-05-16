/**
 * @description  [TTP-91] [TTP-1721] Rule related to the budget check on invoice line item records
 * @company      Cloudwerx
 * @date         24/09/2021
 * @testClass    InvoiceRuleTest - unitTest_BudgetCheckPlanSupportItem, unitTest_BudgetCheckPlanSupport, unitTest_BudgetCheckInterchangeable, unitTest_BudgetCheckReservedBudget
**/
public without sharing class IR_BudgetCheck implements InvoiceRuleGenerator {

    /**
     * @description  [TTP-91]This rule checks if a budget is present on the invoice
     * @author       Mehul Shah
     * @param        invoice : Invoice Record on which the Rules run
     *               result  : Instance of InvoiceRuleResult which holds the outcome of the rule
     * @return       InvoiceRuleResult is the return type that holds status & mutated data
    **/
    public InvoiceRuleResult executeRule(Invoice__c invoice,InvoiceRuleResult result) {

        // Initializing attributes
        String ruleStatus;
        boolean hasFailure = false;
        Decimal fundsLeft;  //AHOD-812

        // Initializing Collections
        Map<Id,String> lineItemVsRuleResult = new Map<Id,String>();
        Set<String> providerSet = new Set<String>();
        Set<String> planSet = new Set<String>();
        Set<String> planSupportSet = new Set<String>();
        Set<String> supportItemNumberSet = new Set<String>();
        Set<String> substitutionPlanSupportSet = new Set<String>();
        Set<String> substitutionSupportItemNumberSet = new Set<String>();
        //ACEM-48 --start--
        Map<Id,Decimal> pspVsBudgetRemaining = new Map<Id,Decimal>();
        Decimal currentPSPFunds;
        //ACEM-48 --end--
        //AHOD-300
        ServiceBookingRequest__c serviceBookingRequestObj;
        Map<Decimal, Decimal> mapOfCatgNumberWithAmount = new Map<Decimal, Decimal>();          //map of category number with amount
        List<ServiceBookingRequest__c> openSBRList = InvoiceRuleService.getOpenSBR(invoice);    //query for any open SBR

        // OPSNBOTS-28 Plan Support Preference records for core categories
        Set<Id> SetOfPSPPlans= new Set<Id>();
        if (result.lockedBudgetList != NULL && !result.lockedBudgetList.isEmpty()) {
            for (PlanSupportPreference__c psp : result.lockedBudgetList) {
                SetOfPSPPlans.add(psp.Plan__c);
            }
        }

        // Loop to initialize collections for query filter conditions
        for (Invoice_Line_Item__c invoiceLineItem : invoice.Invoice_Line_Items__r) {
           providerSet.add(invoice.Provider__c); // Set of Provider
           planSet.add(invoiceLineItem.Plan__c); // Set of Plan
           planSupportSet.add(invoiceLineItem.Plan_Support__c); // Set of Plan Support
           supportItemNumberSet.add(invoiceLineItem.Support_Item__r.SupportItemNumber__c); // Set of Support Item
           substitutionPlanSupportSet.add(invoiceLineItem.Substitution_Plan_Support_Preferences__r?.SubstitutionPlanSupport__c); // Set of Substitution Plan Support
           substitutionSupportItemNumberSet.add(invoiceLineItem.Substitution_Plan_Support_Preferences__r?.SubstitutionSupportItemNumber__c); // Set of Substitution Support Item Number
        }

        // Method calls to get Plan Support Preference For Locked Budget RecordType
        List<PlanSupportPreference__c> pspList = InvoiceRuleService.getReservedBudgetPSPForBudgetCheck(providerSet,planSet,planSupportSet,supportItemNumberSet,invoice);
        //List<PlanSupportPreference__c> substitutionPspList = InvoiceRuleService.getSubstitutionPSPForBudgetCheck(providerSet,planSet,substitutionPlanSupportSet,substitutionSupportItemNumberSet,invoice); //[TTP-1721]
		List<PlanSupportPreference__c> substitutionPspList = InvoiceRuleService.getReservedBudgetPSPForBudgetCheck(providerSet,planSet,substitutionPlanSupportSet,substitutionSupportItemNumberSet,invoice); //[TTP-3998]

        // NAP5-346 - start
        // for pspList
        Map<Id, List<PlanSupportPreferenceLineItem__c>> mapOfLockedBudgetWithLines = new Map<Id, List<PlanSupportPreferenceLineItem__c>>();
        for (PlanSupportPreference__c psp : pspList) {
            for (PlanSupportPreferenceLineItem__c pspLine : psp.Client_Budget_Preferences__r) {
                if (mapOfLockedBudgetWithLines.containsKey(psp.Id)) {
                    mapOfLockedBudgetWithLines.get(psp.Id).add(pspLine);
                } else {
                    mapOfLockedBudgetWithLines.put(psp.Id, new List<PlanSupportPreferenceLineItem__c>{pspLine});
                }
            }
        }

        // NAP5-346 - start
        // for substitutionPspList
        Map<Id, List<PlanSupportPreferenceLineItem__c>> mapOfSubstitutionWithLines = new Map<Id, List<PlanSupportPreferenceLineItem__c>>();
        Map<Id, String> mapOfSupportItemsVsNumber = new Map<Id, String>(); 
        for (PlanSupportPreference__c psp : substitutionPspList) {
            for (PlanSupportPreferenceLineItem__c pspLine : psp.Client_Budget_Preferences__r) {
                mapOfSupportItemsVsNumber.put(pspLine.SupportItem__c,pspLine.SupportItem__r.SupportItemNumber__c);
                if (mapOfSubstitutionWithLines.containsKey(psp.Id)) {
                    mapOfSubstitutionWithLines.get(psp.Id).add(pspLine);
                } else {
                    mapOfSubstitutionWithLines.put(psp.Id, new List<PlanSupportPreferenceLineItem__c>{pspLine});
                }
            }
        }
        // NAP5-346 - end

        // Iterate over invoice line item
        for (Invoice_Line_Item__c invoiceLineItem : invoice.Invoice_Line_Items__r) {

            List<PlanSupportPreference__c> validPspRecords = new List<PlanSupportPreference__c>();

            if ( pspList != null &&!pspList.isEmpty()) {
                // Loop to iterate over Plan Support Preference records
                for (PlanSupportPreference__c pspRecord : pspList) {     // Check for Reserve Budget Record
                    if (pspRecord.StartDate__c <= invoiceLineItem.Service_Date_From__c 
                        && pspRecord.EndDate__c >= invoiceLineItem.Service_Date_From__c 
                        && pspRecord.StartDate__c <= invoiceLineItem.Service_Date_To__c 
                        && pspRecord.EndDate__c >= invoiceLineItem.Service_Date_To__c 
                        && (pspRecord.PlanSupport__r?.FundsApproved__c - (pspRecord.FundsRemaining__c + pspRecord.PlanSupport__r?.TotalFundsSpent__c) >= 0)
                    ) { // Check condition for dates
                        // NAP5-346 - start
                        if (mapOfLockedBudgetWithLines.containsKey(pspRecord.Id)) {
                            List<PlanSupportPreferenceLineItem__c> pspLinesList = mapOfLockedBudgetWithLines.get(pspRecord.Id);
                            for (PlanSupportPreferenceLineItem__c pspLines : pspLinesList) {
                                if (pspLines.SupportItem__c == invoiceLineItem.Support_Item__c) {
                                    validPspRecords.add(pspRecord);
                                }
                            }                            
                        }
                        // NAP5-346 - end
                    }
                }
            }

            if (validPspRecords != null && !validPspRecords.isEmpty()) {

                for (PlanSupportPreference__c pspRecord : validPspRecords) {
                    //ACEM-48 --start
                    currentPSPFunds = 	pspVsBudgetRemaining.containsKey(pspRecord.Id) ?
                                        pspVsBudgetRemaining.get(pspRecord.Id) :
                    					pspRecord.FundsRemaining__c;
                    //ACEM-48 --end
                    if (currentPSPFunds >= invoiceLineItem.Amount_Due__c) { // Check for budget
                        // Update Invoice_Line_Item__c.Reserved_Plan_Support_Preferences__c lookup with Locked Budget
                        invoiceLineItem.Reserved_Plan_Support_Preferences__c = pspRecord.Id;
                        invoiceLineItem.Reserved_Plan_Support_Preferences__r = pspRecord;

                        // TTP-4197
                          invoiceLineItem.Plan_Support__c = pspRecord.PlanSupport__r.id;
                          invoiceLineItem.Plan_Support__r = pspRecord.PlanSupport__r;
                        //invoiceLineItem.Plan_Support_Item__c = null;

                          //invoiceLineItem.Substitution_Plan_Support_Preferences__c = null; TTP-4197
                        // Update invoice line item status, rule result and status
                        invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                        lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.FUNDS_AVAILABLE_IN_RESERVED_BUDGET);
                        //ACEM-48 --start--
                        currentPSPFunds -= invoiceLineItem.Amount_Due__c;
                        pspVsBudgetRemaining.put(pspRecord.Id, currentPSPFunds);
                        //ACEM-48 --end--
                        break;
                    } else { // For Insufficient funds in locked budget
                        //Update invoice line item status, rule result and status
                        invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                        hasFailure = true;
                        lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.INSUFFICIENT_FUNDS_IN_RESERVED_BUDGET);
                    }
                }
            } else if (!String.IsBlank(invoiceLineItem.Plan_Support_Item__c)) {
                //ACEM-48 --start
                currentPSPFunds = 	pspVsBudgetRemaining.containsKey(invoiceLineItem.Plan_Support_Item__c)
                                    ? pspVsBudgetRemaining.get(invoiceLineItem.Plan_Support_Item__c) :
                					invoiceLineItem.Plan_Support_Item__r.TotalFundsRemaining__c;
                //ACEM-48 --end
				// For Plan Support Item - unitTest_BudgetCheckPlanSupportItem
                if (currentPSPFunds >= invoiceLineItem.Amount_Due__c) {
                    // Remove Invoice_Line_Item__c.Substitution lookup
                    invoiceLineItem.Substitution_Plan_Support_Preferences__c = null;

                    // Update invoice line item status, rule result and status
                    invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                    lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.FUNDS_AVAILABLE_IN_PLAN_SUPPORT_ITEM);
                    //ACEM-48 --start--
                    currentPSPFunds -= invoiceLineItem.Amount_Due__c;
                    pspVsBudgetRemaining.put(invoiceLineItem.Plan_Support_Item__c, currentPSPFunds);
                    //ACEM-48 --end--
                } else {
                    // Update invoice line item status, rule result and status
                    invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    hasFailure = true;
                    lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.INSUFFICIENT_FUNDS_IN_PLAN_SUPPORT_ITEM);
                }
            } else {  // For Plan Support - unitTest_BudgetCheckPlanSupport
                if (!String.IsBlank(invoiceLineItem.Plan_Support__c)){
                    //ACEM-48 --start , ACEM-106
                    currentPSPFunds = 	pspVsBudgetRemaining.containsKey(invoiceLineItem.Plan_Support__c)
                                        ? pspVsBudgetRemaining.get(invoiceLineItem.Plan_Support__c) :
                    					(invoiceLineItem.Plan_Support__r.TotalFundsRemaining__c -
                                        invoiceLineItem.Plan_Support__r.LockedFunds__c - invoiceLineItem.Plan_Support__r.UnlockedStatedFundsRemaining__c);
                    //ACEM-48, ACEM-106 --end
                }
                if ((!String.IsBlank(invoiceLineItem.Plan_Support__c) && currentPSPFunds >= invoiceLineItem.Amount_Due__c)) {
                    // Remove Invoice_Line_Item__c.Substitution
                    invoiceLineItem.Substitution_Plan_Support_Preferences__c = null;
                    // Update invoice line item status, rule result and status
                    invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                    lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.FUNDS_AVAILABLE_IN_PLAN_SUPPORT);
                    //ACEM-48 --start--
                    currentPSPFunds -= invoiceLineItem.Amount_Due__c;
                    pspVsBudgetRemaining.put(invoiceLineItem.Plan_Support__c, currentPSPFunds);
                    //ACEM-48 --end--
                } else if (invoiceLineItem.Interchangeable__c) {    // Check for Interchangeable
                    if (!String.IsBlank(invoiceLineItem.Substitution_Plan_Support_Preferences__c)
                        && substitutionPspList != null && !substitutionPspList.isEmpty() ) {

                        for (PlanSupportPreference__c pspRecord : substitutionPspList) {
                            if (pspRecord.StartDate__c <= invoiceLineItem.Service_Date_From__c 
                                && pspRecord.EndDate__c >= invoiceLineItem.Service_Date_From__c 
                                && pspRecord.StartDate__c <= invoiceLineItem.Service_Date_To__c 
                                && pspRecord.EndDate__c >= invoiceLineItem.Service_Date_To__c  
                                && (pspRecord.PlanSupport__r?.FundsApproved__c - (pspRecord.FundsRemaining__c + pspRecord.PlanSupport__r?.TotalFundsSpent__c) >= 0)
                            ) {
                                // NAP5-346 - start
                                // Check condition for dates
                                if (mapOfSubstitutionWithLines.containsKey(pspRecord.Id)) {
                                    List<PlanSupportPreferenceLineItem__c> pspLinesList = mapOfSubstitutionWithLines.get(pspRecord.Id);
                                    for (PlanSupportPreferenceLineItem__c pspLines : pspLinesList) {
                                        if (mapOfSupportItemsVsNumber.containsKey(pspLines.SupportItem__c)) {
                                            if (mapOfSupportItemsVsNumber.get(pspLines.SupportItem__c).equalsIgnoreCase(invoiceLineItem.Substitution_Plan_Support_Preferences__r?.SubstitutionSupportItemNumber__c)) {
                                                validPspRecords.add(pspRecord);
                                            }
                                        }
                                    }                            
                                }
                                // NAP5-346 - end
                            }
                        }
                    }
                    //ACEM-48, ACEM-106
                    if(invoiceLineItem.Substitution_Plan_Support_Preferences__c != null){
                        currentPSPFunds = 	pspVsBudgetRemaining.containsKey(invoiceLineItem.Substitution_Plan_Support_Preferences__c)
                                            ? pspVsBudgetRemaining.get(invoiceLineItem.Substitution_Plan_Support_Preferences__c) :
                        					(invoiceLineItem.Substitution_Plan_Support_Preferences__r?.SubstitutionPlanSupport__r?.TotalFundsRemaining__c -
                                 			invoiceLineItem.Substitution_Plan_Support_Preferences__r.SubstitutionPlanSupport__r.LockedFunds__c  -
                                            invoiceLineItem.Substitution_Plan_Support_Preferences__r.SubstitutionPlanSupport__r.UnlockedStatedFundsRemaining__c);
                    }
                    if (validPspRecords != null && !validPspRecords.isEmpty()) {
                        for (PlanSupportPreference__c pspRecord : validPspRecords) { // Check Locked Budget record for Substitution record
                            //ACEM-48 --start
                            currentPSPFunds = 	pspVsBudgetRemaining.containsKey(pspRecord.Id) ? pspVsBudgetRemaining.get(pspRecord.Id) :
                            					pspRecord.FundsRemaining__c;
                            //ACEM-48 --end
                            if (currentPSPFunds >= invoiceLineItem.Amount_Due__c) { // Check for budget
                                invoiceLineItem.Reserved_Plan_Support_Preferences__c = pspRecord.id;
                                invoiceLineItem.Reserved_Plan_Support_Preferences__r = pspRecord;

                                invoiceLineItem.Plan_Support__c = pspRecord.PlanSupport__c;
                                //Update invoice line item status, rule result and status
                                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                                lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.FUNDS_AVAILABLE_IN_SUBSTITUTION_INTERCHANGEABLE);
                                //ACEM-48 --start--
                                currentPSPFunds -= invoiceLineItem.Amount_Due__c;
                                pspVsBudgetRemaining.put(pspRecord.Id, currentPSPFunds);
                                //ACEM-48 --end--
                                break;
                            } else {
                                //Update invoice line item status, rule result and status
                                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                                hasFailure = true;
                                lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.INSUFFICIENT_FUNDS_IN_SUBSTITUTION_RESERVED_BUDGET);
                            }
                        }
                    } else if (invoiceLineItem.Substitution_Plan_Support_Preferences__c != null
                                && currentPSPFunds >= invoiceLineItem.Amount_Due__c
                        ) {   // Check Plan Support record for Substitution record

                            // Update Invoice_Line_Item__c.Reserved_Plan_Support_Preferences__c lookup with Plan Support lookup
                            invoiceLineItem.Plan_Support__c = invoiceLineItem.Substitution_Plan_Support_Preferences__r?.SubstitutionPlanSupport__c;
                            invoiceLineItem.Plan_Support__r = invoiceLineItem.Substitution_Plan_Support_Preferences__r?.SubstitutionPlanSupport__r; //AHOD-812

                            // Update invoice line item status, rule result and status
                            invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                            lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.FUNDS_AVAILABLE_IN_SUBSTITUTION_PLAN_SUPPORT);
                            //ACEM-48 --start--
                            currentPSPFunds -= invoiceLineItem.Amount_Due__c;
                            pspVsBudgetRemaining.put(invoiceLineItem.Substitution_Plan_Support_Preferences__c, currentPSPFunds);
                            //ACEM-48 --end--

                            /* CREDIT NOTE ASSOCIATION LOGIC - AHOD-812 */
                            if (result.creditNoteList != null && !result.creditNoteList.isEmpty()) {
                                for (CreditNote__c creditNote: result.creditNoteList) {
                                    creditNote.FundsSpent__c = creditNote.FundsSpent__c!= null ? creditNote.FundsSpent__c :0; //[TTP-1997]
                                    fundsLeft = creditNote.Total__c - creditNote.FundsSpent__c; //[TTP-1997]
                                    if ( invoiceLineItem.Invoice__r?.Provider__c == creditNote.Provider__c
                                        && invoiceLineItem.Plan__c == creditNote.Plan__c
                                        && fundsLeft > 0 &&
                                        ((invoiceLineItem.Plan_Support__c == creditNote.PlanSupport__c && invoiceLineItem.Plan_Support_Item__c == creditNote.PlanSupportItem__c)
                                         || ((invoiceLineItem.Plan_Support__r.SupportCategoryNumber__c == 01 || invoiceLineItem.Plan_Support__r.SupportCategoryNumber__c == 03 || invoiceLineItem.Plan_Support__r.SupportCategoryNumber__c == 04)
                                             && (creditNote.PlanSupport__r.SupportCategoryNumber__c == 01 || creditNote.PlanSupport__r.SupportCategoryNumber__c == 03 || creditNote.PlanSupport__r.SupportCategoryNumber__c == 04))
                                        ) //AHOD-102 (If condition changes)
                                       ) {
                                           invoiceLineItem.Credit_Note__c = creditNote.Id;
                                           invoiceLineItem.Credit_Amount__c = fundsLeft > invoiceLineItem.Total__c ? invoiceLineItem.Total__c : fundsLeft;
                                           creditNote.FundsSpent__c = creditNote.FundsSpent__c + invoiceLineItem.Credit_Amount__c;
                                           break;
                                       }
                                } //AHOD-812
                            }
                        } else {
                        //AHOD-300
                        if (invoiceLineItem.Support_Item__r.SupportCategory__r.SupportTypeCode__c == 'ZCOR'
                            && invoiceLineItem.Plan__r.Active__c
                            && !SetOfPSPPlans.contains(invoiceLineItem.Plan__c)) { // OPSNBOTS-28 added PSP check
                            // invoice has a related SBR
                            if (invoice.Service_Booking_Request__c != NULL) {
                                // SBR is populated on invoice
                                hasFailure = true;
                                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                                String msg = InvoiceRuleConstant.EXISTING_COREALLOCATION.replace('[ReqType]', invoice.Service_Booking_Request__r?.RequestType__c).replace('[Status]', invoice?.Service_Booking_Request__r?.Status__c).replace('[ClientName]', invoice?.client__r?.Name);
                                msg = invoiceLineItem?.Plan__r != null ? msg.replace('[ProdaId]', invoiceLineItem?.Plan__r?.PRODA_Plan_Id__c) : msg.replace('[ProdaId]', '');

                                lineItemVsRuleResult.put(invoiceLineItem.id, msg);
                                //[NAPS-95 Added Check for brand flag]
                                if (invoice.PlanManager__c == 'MPM') {
                                    invoice.OwnerId = 'Not Started'.equalsIgnoreCase(invoice?.Service_Booking_Request__r?.Status__c) || 'In Progress'.equalsIgnoreCase(invoice?.Service_Booking_Request__r?.Status__c) ? InvoiceRuleConstant.BUDGET_UPDATES : InvoiceRuleConstant.RELATIONSHIP_QUEUE;
                                }
                                else if (invoice.PlanManager__c == 'NDSP') {
                                    	invoice.OwnerId = 'Not Started'.equalsIgnoreCase(invoice?.Service_Booking_Request__r?.Status__c) || 'In Progress'.equalsIgnoreCase(invoice?.Service_Booking_Request__r?.Status__c) ? InvoiceRuleConstant.NDSP_BUDGET_UPDATES_QUEUE : InvoiceRuleConstant.NDSP_RELATIONSHIP_QUEUE;
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

                                    List<Object> invoiceSupportCategoriesList = invoice.Service_Booking_Request__r?.InvoiceSupportCategory__c != ''
                                                                                ? (List<Object>) JSON.deserializeUntyped(invoice.Service_Booking_Request__r.InvoiceSupportCategory__c): new List<Object>();

                                    InvoiceRuleHelper.InvoiceSupportCategoryWrapper invoiceSCWrapperObj = new InvoiceRuleHelper.InvoiceSupportCategoryWrapper();
                                    invoiceSCWrapperObj.SupportCategoryCode = invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryCode__c;
                                    invoiceSCWrapperObj.SupportCategoryNumber = invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryNumber__c;
                                    invoiceSCWrapperObj.SupportCategoryAmount = invoiceLineItem.Total__c;
                                    invoiceSupportCategoriesList.add(invoiceSCWrapperObj);
                                    // add new category to json
                                    invoice.Service_Booking_Request__r.InvoiceSupportCategory__c = JSON.serialize(invoiceSupportCategoriesList);
                                }

                                hasFailure = true;
                                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                                String msg = System.Label.IR_NewCoreAllocation.replace(System.Label.Create_CORE_Allocations,System.Label.Adjust_CORE_Allocations).replace('[ClientName]', invoice?.client__r?.Name);
                                msg = invoiceLineItem?.Plan__r != null ? msg.replace('[ProdaId]', invoiceLineItem?.Plan__r?.PRODA_Plan_Id__c) : msg.replace('[ProdaId]', '');
                                lineItemVsRuleResult.put(invoiceLineItem.id, msg);
                                //[NAPS-95 Added Ternary Operator to check brand flag]
                    			invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? InvoiceRuleConstant.NDSP_BUDGET_UPDATES_QUEUE : InvoiceRuleConstant.BUDGET_UPDATES;

                            } else if (!openSBRList.isEmpty()) {
                                // assign existing SBR
                                invoice.Service_Booking_Request__c = openSBRList[0].Id;
                                invoice.Service_Booking_Request__r = openSBRList[0];
                                hasFailure = true;
                                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                                String msg = InvoiceRuleConstant.EXISTING_COREALLOCATION.replace('[ReqType]', invoice.Service_Booking_Request__r?.RequestType__c).replace('[Status]', invoice?.Service_Booking_Request__r?.Status__c).replace('[ClientName]', invoice?.client__r?.Name);
                                msg = invoiceLineItem?.Plan__r != null ? msg.replace('[ProdaId]', invoiceLineItem?.Plan__r?.PRODA_Plan_Id__c) : msg.replace('[ProdaId]', '');

                                lineItemVsRuleResult.put(invoiceLineItem.id, msg);
                                //[NAPS-95 Added Ternary Operator to check brand flag]
                    			invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? InvoiceRuleConstant.NDSP_BUDGET_UPDATES_QUEUE : InvoiceRuleConstant.BUDGET_UPDATES;
                            } else {
                                // create new SBR
                                serviceBookingRequestObj = InvoiceRuleHelper.createSBRMapping(invoice, invoiceLineItem, System.Label.Adjust_CORE_Allocations);
                                // populate map of category number with amount
                                mapOfCatgNumberWithAmount.put(invoiceLineItem.Support_Item__r.SupportCategory__r.SupportCategoryNumber__c, invoiceLineItem.Total__c);
                                invoice.Service_Booking_Request__r = serviceBookingRequestObj;
                                hasFailure = true;
                                invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;

                                String msg = System.Label.IR_NewCoreAllocation.replace(System.Label.Create_CORE_Allocations,System.Label.Adjust_CORE_Allocations);
                                msg = msg.replace('[ClientName]', invoice?.client__r?.Name);
                                msg = invoiceLineItem?.Plan__r != null ? msg.replace('[ProdaId]', invoiceLineItem?.Plan__r?.PRODA_Plan_Id__c) : msg.replace('[ProdaId]', '');
                                lineItemVsRuleResult.put(invoiceLineItem.id, msg);
                                //[NAPS-95 Added Ternary Operator to check brand flag]
                    			invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? InvoiceRuleConstant.NDSP_BUDGET_UPDATES_QUEUE : InvoiceRuleConstant.BUDGET_UPDATES;
                            }
                            //AHOD-300
                        } else {
                            // Update invoice line item status, rule result and status
                            invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                            hasFailure = true;
                            lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.INSUFFICIENT_FUNDS_IN_PLAN_SUPPORT_AS_WELL_AS_SUBSTITUTION_INTERCHANGEABLE);
                        }
                    }
                } else if (!invoiceLineItem.Interchangeable__c){ // For Non-Interchangeable
                    // Update invoice line item status, rule result and status
                    invoiceLineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    hasFailure = true;
                    lineItemVsRuleResult.put(invoiceLineItem.id,InvoiceRuleConstant.INSUFFICIENT_FUNDS_IN_PLAN_SUPPORT_NON_INTERCHANGEABLE);
                }
            }
        }

        // Set the ServiceBookingRequest for insert/update
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
            // populate variable in result for SBR
            result.serviceBookingReqt =  serviceBookingRequestObj;
        }

        if (hasFailure && invoice.OwnerId != InvoiceRuleConstant.BUDGET_UPDATES) {
            //[NAPS-95 Added Ternary Operator to check brand flag]
			invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? InvoiceRuleConstant.NDSP_RELATIONSHIP_QUEUE : InvoiceRuleConstant.RELATIONSHIP_QUEUE;
        }

        // Set rule result to fail if any of the invoice line item fails
        ruleStatus = hasFailure ? InvoiceRuleConstant.STATUS_FAIL : InvoiceRuleConstant.STATUS_PASS; //Code Review Fix

        // Return invoice and invoice line item
        return result.processRuleResult(result, null, invoice, null, ruleStatus, lineItemVsRuleResult);
    }
}