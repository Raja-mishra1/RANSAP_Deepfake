/**
 * @description  [TTP-471] Invoice Rule to check if Letter Of Recommendation is confirmed or not
 * @company      Cloudwerx
 * @date         10/05/2021
 * @testClass    InvoiceRuleTest - unitTest_LetterOfRecommendationCheck
**/

public without sharing class IR_LetterOfRecommendationCheck implements InvoiceRuleGenerator {
    
    /**
    * @description  Method to check if Letter Of Recommendation is confirmed or not
    * @author       Mehul Shah
    * @param        invoice : Invoice Record on which the Rules run
    *               result  : Instance of InvoiceRuleResult which holds the outcome of the rule
    * @return       result is the return type that holds status & mutated data
    */

    public InvoiceRuleResult executeRule(Invoice__c invoice,InvoiceRuleResult result) {
        
        String ruleStatus;
        Boolean hasFailure = false;
        Boolean failedLIRelationshipQueue = false;

        Map<Id,String> lineItemVsRuleResult = new Map<Id,String>();        
        Set<String> setOfSupportItemNumbers = new Set<String>();
        Map<String,LORDirectory__c> supportItemNumbervsLORMap = new Map<String,LORDirectory__c>();

        String lorLevelMsg = InvoiceRuleConstant.LOR_LEVEL_MSG;

        for (Invoice_Line_Item__c lineItem : invoice.Invoice_Line_Items__r) {
            setOfSupportItemNumbers.add(lineItem?.Support_Item__r?.SupportItemNumber__c);
        }

        // fetch LOR Directory records
        List<LORDirectory__c> listOfLORDirectory = InvoiceRuleService.getLORDirectory(setOfSupportItemNumbers);

        for (LORDirectory__c lor : listOfLORDirectory) {
            supportItemNumbervsLORMap.put(lor.SupportItemNumber__c, lor);
        }

        for (Invoice_Line_Item__c lineItem : invoice.Invoice_Line_Items__r) {
            
            if (listOfLORDirectory.isEmpty() || listOfLORDirectory == null) { // LOR is not applicable
                lineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                lineItemVsRuleResult.put(lineItem.id, InvoiceRuleConstant.LOR_NOT_APPLICABLE);
            }
            
            if (supportItemNumbervsLORMap.containsKey(lineItem?.Support_Item__r?.SupportItemNumber__c) && 
                supportItemNumbervsLORMap.get(lineItem?.Support_Item__r?.SupportItemNumber__c)?.StartDate__c <= lineItem.Service_Date_From__c &&
                supportItemNumbervsLORMap.get(lineItem?.Support_Item__r?.SupportItemNumber__c)?.EndDate__c >= lineItem.Service_Date_From__c &&
                supportItemNumbervsLORMap.get(lineItem?.Support_Item__r?.SupportItemNumber__c)?.StartDate__c <= lineItem.Service_Date_To__c &&
                supportItemNumbervsLORMap.get(lineItem?.Support_Item__r?.SupportItemNumber__c)?.EndDate__c >= lineItem.Service_Date_To__c &&
                lineItem.Plan_Support_Item__c == null
            ) {
                lineItem.LORDirectory__c = supportItemNumbervsLORMap.get(lineItem?.Support_Item__r?.SupportItemNumber__c)?.Id; 
                                     
                if (lineItem.LORReceived__c) {  // check if LOR is received - if yes, LOR is confirmed
                    lineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                    lineItemVsRuleResult.put(lineItem.id, InvoiceRuleConstant.LOR_CONFIRMED);
                } else if (('Level 2').equals(supportItemNumbervsLORMap.get(lineItem?.Support_Item__r?.SupportItemNumber__c).AssessmentLevel__c) &&
                           lineItem.Total__c <= General_T2P_Settings__c.getOrgDefaults()?.LORLevel2Limit__c &&
                           General_T2P_Settings__c.getOrgDefaults()?.LORLevel2Limit__c > 0
                ) { // LOR Level 2 is within the configured limit
                    lineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    String lorMsg = replaceMergeFields(lorLevelMsg, lineItem, supportItemNumbervsLORMap.get(lineItem?.Support_Item__r?.SupportItemNumber__c));
                    lineItemVsRuleResult.put(lineItem.id, lorMsg);
                    hasFailure = true;  // mark failure as true if any invoice line item fails 
                } else {    // LOR is not confirmed
                    lineItem.Status__c = InvoiceRuleConstant.STATUS_FAILED;
                    String lorMsg = replaceMergeFields(lorLevelMsg, lineItem, supportItemNumbervsLORMap.get(lineItem?.Support_Item__r?.SupportItemNumber__c));
                    lineItemVsRuleResult.put(lineItem.id, lorMsg);
                    hasFailure = true;  // mark failure as true if any invoice line item fails

                    // marking this as true because if multiple line items fail, invoice should be assigned to relationship team
                    failedLIRelationshipQueue = true;
                }
            } else {
                lineItem.Status__c = InvoiceRuleConstant.STATUS_READY;
                lineItemVsRuleResult.put(lineItem.id, InvoiceRuleConstant.LOR_NOT_APPLICABLE);
            }
        }

        // if any invoice line item is failed, the rule should fail
        ruleStatus = hasFailure ? InvoiceRuleConstant.STATUS_FAIL : InvoiceRuleConstant.STATUS_PASS;

        // if multiple line items fail, invoice should be assigned to relationship team
        if (hasFailure && failedLIRelationshipQueue) {
            //[NAPS-95 Added Ternary Operator to check brand flag]
            invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
            InvoiceRuleConstant.NDSP_RELATIONSHIP_QUEUE : InvoiceRuleConstant.RELATIONSHIP_QUEUE;
        } else if (hasFailure && !failedLIRelationshipQueue) {
			//[NAPS-95 Added Ternary Operator to check brand flag]
			invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
            InvoiceRuleConstant.NDSP_ACCOUNTS_QUEUE : InvoiceRuleConstant.ACCOUNTS_QUEUE;
        }

        return result.processRuleResult(result, null, invoice, null, ruleStatus, lineItemVsRuleResult);
    }

    public static String replaceMergeFields(String msg, Invoice_Line_Item__c lineItem, LORDirectory__c lor) {
        msg = msg.replace('[Level]', lor.AssessmentLevel__c);
        msg = msg.replace('[Support Item No]', lineItem?.Support_Item__r?.SupportItemNumber__c);
        msg = msg.replace('[Line Item Total]', String.valueOf(lineItem.Total__c));

        return msg;
    }
}