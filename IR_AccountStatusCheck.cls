/**
 * @description  This rule checks if a client is Not in Archived or On Hold state on the invoice
 * @company      Cloudwerx
 * @date         19/07/2021
 * @testClass    InvoiceRuleTest - unitTest_ClientStatusCheck
**/

public without sharing class IR_AccountStatusCheck implements InvoiceRuleGenerator{
    
    /**
    * @description     This method checks if a client is Not in Archived or On Hold state on the invoice
    * @author          Swapnil Bhapkar
    * @param           invoice : Invoice Record on which the Rules run
    *                  result  : Instance of InvoiceRuleResult which holds the outcome of the rule
    * @return          result is the return type that holds status & mutated data
    */

    public InvoiceRuleResult executeRule(Invoice__c invoice,InvoiceRuleResult result) {
        String ruleStatus, ruleResult;
        String clientStatus = invoice.Client__r?.Status__c;
         
        //Rule failure
        if (String.isNotBlank(clientStatus) && (InvoiceRuleConstant.ACCOUNT_STATUS_ARCHIVED_ONHOLD).contains(clientStatus) ) {
            //TTP-2443 Assign Invoice to Queue    
            List <String> statuses = InvoiceRuleConstant.ACCOUNT_STATUS_ARCHIVED_ONHOLD.split(',');
            if((statuses[0].trim()).containsIgnoreCase(clientStatus)){ //Archived
				//[NAPS-95 Added Ternary Operator to check brand flag]
				invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
                InvoiceRuleConstant.NDSP_SOLUTIONS_QUEUE : InvoiceRuleConstant.SOLUTIONS_QUEUE;
            }
            else if((statuses[1].trim()).containsIgnoreCase(clientStatus)){ //On Hold
				//[NAPS-95 Added Ternary Operator to check brand flag]
				invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
                InvoiceRuleConstant.NDSP_OPERATIONS_SUPPORT : InvoiceRuleConstant.OPERATIONS_SUPPORT;
            } else {
				//[NAPS-95 Added Ternary Operator to check brand flag]
				invoice.OwnerId = invoice.PlanManager__c == 'NDSP' ? 
                InvoiceRuleConstant.NDSP_RELATIONSHIP_QUEUE : InvoiceRuleConstant.RELATIONSHIP_QUEUE;
            }
            ruleStatus = InvoiceRuleConstant.STATUS_FAIL;     
            ruleResult = InvoiceRuleConstant.ACCOUNT_STATUS_CHECK_FAIL;      
        
        } else {
            //Rule success        
            ruleStatus = InvoiceRuleConstant.STATUS_PASS;
            ruleResult = InvoiceRuleConstant.ACCOUNT_STATUS_CHECK_PASS;
        }
        
        return result.processRuleResult(result, ruleResult, invoice, null, ruleStatus, null);
    }
}