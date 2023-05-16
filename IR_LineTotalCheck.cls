/**
 * @description  [TTP-4156] Invoice Process Rule (Line Total Check),
 *               Invoice Rule Class to identify if an invoice line item has total amount correctly set
 * @company      Cloudwerx
 * @date         15/06/2022
 * @testClass    InvoiceRuleTest - unitTest_LineTotalCheck
**/
public without sharing class IR_LineTotalCheck implements InvoiceRuleGenerator {

    /**
     * @description  Execute Rule method to check unit price value
     * @author       Sonali Bhat
     * @param        invoice : Invoice Record on which the Rules run
     *               result  : Instance of InvoiceRuleResult which holds the outcome of the rule
     * @return       InvoiceRuleResult is the return type that holds status & mutated data
    **/
    public InvoiceRuleResult executeRule(Invoice__c invoice, InvoiceRuleResult result) {
        String ruleStatus;
        Boolean hasFailure = false; //Flag to check if rule fails;
        String lineTotalFailureMsg;
        String lineTotalSuccessMsg;
        String lineItemfeedBody;
        String invoicefeedBody;
        Decimal notionalRoundingAdjustment = General_T2P_Settings__c.getOrgDefaults()?.NotionalRoundingAdjustment__c;
		Decimal totalDifference = 0; // [TFR-258]
        Decimal previousInvoiceTotal = invoice.Total__c; // [TFR-258]
        
        List<FeedItem> feedItemList = new List<FeedItem>();
        Map<Id,String> lineItemVsRuleResult = new Map<Id,String>();

        //[NAP5-351] Creating Maps to store original Values of total and Rounding fields
        Map<Id,Decimal> originalLineItemIdvsTotal = new Map<Id,Decimal>();
        Map<Id,String> originalLineItemIdvsRounding = new Map<Id,String>();

        // iterate over line items
        for (Invoice_Line_Item__c lineItem : invoice.Invoice_Line_Items__r) {
            originalLineItemIdvsTotal.put(lineItem.Id, lineItem?.Total__c);
            originalLineItemIdvsRounding.put(lineItem.Id, lineItem?.NotionalRoundingAdjustmentJSON__c);
            string gstMsg = (lineItem.GST__c > 0 && lineItem.GST__c != NULL)? 'Unit price (inc GST)': 'Unit price (ex GST)'; //AHOD-678
            if (lineItem.Total__c != (lineItem.Rate__c * lineItem.Quantity__c).setScale(2,System.RoundingMode.HALF_UP)) {
                // Line Total not equal to rate*qty
                
                Decimal difference = lineItem.Total__c - (lineItem.Rate__c * lineItem.Quantity__c).setScale(2,System.RoundingMode.HALF_UP);
                Decimal previousLineItemTotal;

                if(!'reimbursement'.equalsIgnoreCase(invoice.Document_Type__c)
                    && !'reimbursement'.equalsIgnoreCase(invoice.Original_Invoice_Document_Type__c)
                    && Math.abs(difference) <= notionalRoundingAdjustment) {

                        previousLineItemTotal = lineItem.Total__c;
                        totalDifference += difference;	// [TFR-258]
                        lineItem.Total__c = difference > 0 ? lineItem.Total__c - Math.abs(difference) : lineItem.Total__c + Math.abs(difference); //Set Invoice Line Total
                        lineItemVsRuleResult.put(lineItem.Id,InvoiceRuleConstant.NOTIONAL_ROUNDING_APPLIED);
                        lineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                        
						//Below code added for OPSNBOTS-108
                        lineItemfeedBody = InvoiceRuleConstant.LINETOTALCHECK_FEED_MESSAGE
                                            .replace('[originalTotal]',String.ValueOf(previousLineItemTotal))
                                            .replace('[adjustedTotal]',String.ValueOf(lineItem?.Total__c))
                                            .replace('[adjustmentAmount]',String.ValueOf(Math.abs(difference)));
                        //Below code added for OPSNBOTS-108
                        lineItem.NotionalRoundingAdjustmentJSON__c = lineItemfeedBody;
                        feedItemList.add(TTPUtil.createFeedItem(lineItem.Id, lineItemfeedBody));
                } else {
                    lineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    lineTotalFailureMsg = InvoiceRuleConstant.LINETOTAL_INVALID;
                    lineTotalFailureMsg = lineTotalFailureMsg.replace
                                            ('[Rate*Qty]',String.valueOf((lineItem.Rate__c * lineItem.Quantity__c).setScale(2,System.RoundingMode.HALF_UP)))
                                            .replace('[Total]',String.valueOf(lineItem.Total__c));
                    lineTotalFailureMsg = lineTotalFailureMsg.replace('[gstMsg]',gstMsg);//AHOD-678
                    lineItemVsRuleResult.put(lineItem.Id,lineTotalFailureMsg);
                    hasFailure = true; // rule failed to execute atleast for one invoice line item.
                }

            } else {
                lineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                lineTotalSuccessMsg = InvoiceRuleConstant.LINETOTAL_VALID;
                lineTotalSuccessMsg = lineTotalSuccessMsg.replace
                                            ('[Rate*Qty]',String.valueOf((lineItem.Rate__c * lineItem.Quantity__c).setScale(2,System.RoundingMode.HALF_UP)))
                                            .replace('[Total]',String.valueOf(lineItem.Total__c));//AHOD-678
                lineTotalSuccessMsg = lineTotalSuccessMsg.replace('[gstMsg]',gstMsg);
                lineItemVsRuleResult.put(lineItem.Id,lineTotalSuccessMsg);
            }
        }        
        
        //Revert the Notional Rounding Adjustment if any other line item fails [NAP5-351]
        if(hasFailure && feedItemList?.size() > 0) {
            for(Invoice_Line_Item__c lineItem : invoice.Invoice_Line_Items__r) {
                if(originalLineItemIdvsTotal.containsKey(lineItem.Id)) {
                    lineItem.Total__c = originalLineItemIdvsTotal.get(lineItem.Id);
                }
                if(originalLineItemIdvsRounding.containsKey(lineItem.Id)) {
                    lineItem.NotionalRoundingAdjustmentJSON__c 
                    = originalLineItemIdvsRounding.get(lineItem.Id);
                }
                if(lineItemVsRuleResult.containsKey(lineItem.Id) && 
                    InvoiceRuleConstant.NOTIONAL_ROUNDING_APPLIED.equalsIgnoreCase(lineItemVsRuleResult.get(lineItem.Id))) {
                    lineItemVsRuleResult.put(lineItem.Id,InvoiceRuleConstant.NOTIONAL_ROUNDING_REVERTED);
                }
            }
        } 
        //Post Chatter Feed [TFR-258] - If Notional rounding applied, then only update Invoice fields & feed item.
        else if(!hasFailure && feedItemList?.size() > 0) {
            invoice.Total__c -= totalDifference;
            invoice.Invoice_Line_Item_Totals__c -= totalDifference;
            invoicefeedBody = InvoiceRuleConstant.LINETOTALCHECK_FEED_MESSAGE
                                                .replace('[originalTotal]',String.ValueOf(previousInvoiceTotal))
                                                .replace('[adjustedTotal]',String.ValueOf(invoice?.Total__c))
                                                .replace('[adjustmentAmount]',String.ValueOf(Math.abs(totalDifference)));
            
            invoice.NotionalRoundingAdjustmentJSON__c = invoicefeedBody;
            
            feedItemList.add(TTPUtil.createFeedItem(invoice.Id, invoicefeedBody));
            insert feedItemList;
        }

        ruleStatus = hasFailure ? InvoiceRuleConstant.STATUS_FAIL : InvoiceRuleConstant.STATUS_PASS;

        return result.processRuleResult(result, null, invoice, null, ruleStatus, lineItemVsRuleResult);

    }
}