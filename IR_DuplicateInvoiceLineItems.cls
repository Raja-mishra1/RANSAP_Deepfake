/**
 * @description  [TTP-41] Invoice Process Rule (Duplicate Invoice Line Items), Invoice Rule Class to identify if an invoice line item is Duplicate or Not
 * @company      Cloudwerx
 * @date         20/09/2021
 * @testClass    InvoiceRuleTest - unitTest_DuplicateInvoiceLineItems
**/
public without sharing class IR_DuplicateInvoiceLineItems implements InvoiceRuleGenerator{
    
    /**
     * @description  Execute Rule method to identify if an invoice line item is Duplicate
     * @author       Sonali Bhat
     * @param        invoice : Invoice Record on which the Rules run
     *               result  : Instance of InvoiceRuleResult which holds the outcome of the rule
     * @return       InvoiceRuleResult is the return type that holds status & mutated data
    **/
    public InvoiceRuleResult executeRule(Invoice__c invoice, InvoiceRuleResult result) {

        Map<Id,String> lineItemVsRuleResult = new Map<Id,String>();
        String ruleStatus;
        Boolean hasFailure = false;

        Set<String> setOfDuplicateCheckValues = new Set<String>(); // contains duplicatecheck field values present in the current line items data
        Set<Id> setOfCurrentDuplicateLineItems = new Set<Id>(); // contains duplicate line items
        Set<Id> setOfLineItemIds = new Set<Id>();   // contains set of current line item ids
        Map<String, Id> lineItemVsDuplicateCheck = new Map<String, Id>(); // map of duplicatecheck field value with line item id
        Set<String> setOfExistingDuplicateCheckValues = new Set<String>(); // set of duplicatecheck field values present in the org


        for (Invoice_Line_Item__c lineItem : invoice.Invoice_Line_Items__r) {
            setOfDuplicateCheckValues.add(lineItem.DuplicateCheck__c);
            setOfLineItemIds.add(lineItem.Id);

            // populate map to get duplicate values
            if (!lineItemVsDuplicateCheck.containsKey(lineItem.DuplicateCheck__c)) {
                // Ist time entry of duplicatecheck
                lineItemVsDuplicateCheck.put(lineItem.DuplicateCheck__c, lineItem.Id);
            } else {
                Id lineItemId = lineItemVsDuplicateCheck.get(lineItem.DuplicateCheck__c);
                // duplicate value found , put ids in a set
                setOfCurrentDuplicateLineItems.add(lineItemId); // as it is a set, it will have only one occurence of this line item
                setOfCurrentDuplicateLineItems.add(lineItem.Id); // add duplicate record Id in a set
            }
        }

        // query all line items where duplicatecheck field value is present in the org
        for (Invoice_Line_Item__c lineItem  :  
            [SELECT Id, 
                    Status__c, 
                    DuplicateCheck__c,PlanManager__c
            FROM Invoice_Line_Item__c WHERE DuplicateCheck__c IN : setOfDuplicateCheckValues
            AND Id NOT IN : setOfLineItemIds AND Status__c != 'Cancelled' AND PlanManager__c =: invoice.PlanManager__c LIMIT 50000] //ACEM-2 Added query limit
        ) {
            setOfExistingDuplicateCheckValues.add(lineItem.DuplicateCheck__c); // add value in a set
        }
        
        // iterate over line items to perform the duplicate check                                                              
        for (Invoice_Line_Item__c lineItem : invoice.Invoice_Line_Items__r) {
            Boolean duplicateFound = false;

            // if duplicate value is present in current line item set or in the org data
            if (setOfCurrentDuplicateLineItems.contains(lineItem.Id) 
                || setOfExistingDuplicateCheckValues.contains(lineItem.DuplicateCheck__c)
            ) {
                //set duplicate flag to true
                duplicateFound = true;
            }
            // Set the status on line item
            if (lineItem.Support_Item__r.ExcludeFromDuplicateLineItemCheck__c) { //This if condition added for OPSNBOTS-99
                String errorMsg = InvoiceRuleConstant.EXCLUDE_FROM_DUPLICATE_LINE_ITEM_CHECK;
                errorMsg = errorMsg.replace('{}', '{'+lineItem.Support_Item__r.SupportItemNumber__c+'}');
                lineItemVsRuleResult.put(lineItem.Id,errorMsg);
                lineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
            }
            else if (lineItem.OverrideDuplicateRule__c) {
                lineItemVsRuleResult.put(lineItem.Id,InvoiceRuleConstant.DUPLICATE_LINE_ITEMS_CHECK_OVERRIDDEN);
                lineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
            } else if (duplicateFound) {  // if true, fail the rule as duplicates are found
                lineItemVsRuleResult.put(lineItem.id,InvoiceRuleConstant.DUPLICATE_LINE_ITEMS_FOUND);
                lineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                hasFailure = true;
            } else {    // pass the rule as no duplicated found
                lineItemVsRuleResult.put(lineItem.Id,InvoiceRuleConstant.DUPLICATE_LINE_ITEMS_NOT_FOUND);
                lineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
            }
        }

        // If any invoice line item is duplicate, status of invoice should be FAIL
        ruleStatus = hasFailure ? InvoiceRuleConstant.STATUS_FAIL : InvoiceRuleConstant.STATUS_PASS;

        return result.processRuleResult(result, null, invoice, null, ruleStatus, lineItemVsRuleResult);
    }
}