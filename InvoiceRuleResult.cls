/**
 * @description  This is data service class to hold result data & fire relevant events[TTP-38]
 * @company      Cloudwerx
 * @date         19/07/2021
 * @testClass    InvoiceRuleTest
**/
public without sharing class InvoiceRuleResult {    
    public Invoice__c invoice{get;set;}
    public Boolean    isLineItem{get;set;}                    //IDENTIFIER FOR LINE ITEM EVENTS
    public Id         invoiceId {get;set;}                    //INVOICE ON WHICH ORCHESTRATOR RUNS
    public String     ruleResult{get;set;}                    //HOLDS RESULT FOR EACH INDIVIDUAL RULES
    public String     caseBatchConfig{get;set;}               //HOLDS RESULT FOR EACH INDIVIDUAL RULES
    public List<Case> caseList{get;set;}                      //LIST OF CASES TO INSERT IF RULE FAILS
    public String     middlewareCalloutAction{get;set;}       //TTP-143
    public Integer    executionNumber{get;set;}               //NUMBER OF TIMES ORCHESTRATOR RAN ON INVOICE
    public Datetime   executionDateTime{get;set;}             //TIME WHEN ORCHESTRATOR RUN STARTED
    public Map<Id,String> lineItemVsRuleResult{get;set;}      //HOLDS RULE RESULT FOR EACH LINE ITEM
    public Boolean isApprovalPending {get;set;}               //[TTP-472] for checking if Invoice status is Awaiting Client Approval
    public Integer    lineItemCount{get;set;}                  //holds number of line Items for Invoice
    public ServiceBookingRequest__c serviceBookingReqt{get;set;}  // [AHOD-275]
    public List<CreditNote__c> creditNoteList{get;set;}         //AHOD-812
    public List<PlanSupportPreference__c> lockedBudgetList{get;set;}  // OPSNBOTS-28
    
    //this runs before isSuccess
    public Integer currentRule {
        get; 
        set {    
            if (currentRule == null) {
                currentRule = 1;
            }
            currentRule = value;
            //fire only if Publish Event Checkbox is true
            if(InvoiceRuleConstant.DOCUMENT_TYPE_FEE.equalsIgnoreCase(invoice.Document_Type__c)) {
                if (InvoiceRuleService.feeRuleInformation.get(currentRule).Publish_Event__c) {
                    InvoiceRuleHelper.fireInvoiceProcessStatusEvent(invoice.Id,InvoiceRuleService.feeRuleInformation.get(currentRule).Rule_Name__c);
                }
            } 
            else {
                if (InvoiceRuleService.ruleInformation.get(currentRule).Publish_Event__c) {
                    InvoiceRuleHelper.fireInvoiceProcessStatusEvent(invoice.Id,InvoiceRuleService.ruleInformation.get(currentRule).Rule_Name__c);
                }
            }
            
        }
    }

    public String isSuccess{
        get; 
        set {
            isSuccess = value;
            if (!String.isBlank(value) && (value == InvoiceRuleConstant.STATUS_PASS || value == InvoiceRuleConstant.STATUS_FAIL)) {
                createInvoiceRuleResult();                              
            }  
        }
    }
    
    /**
     * @description  constructor that initializes execution time and invoice id
     * @author       
     * @param        invoiceRecordId : Invoice record id
     * @return       NA
    **/
    public InvoiceRuleResult(Id invoiceRecordId){
        executionNumber = 1;
        invoiceId = invoiceRecordId;
        isLineItem = false;
        executionDateTime = System.now();
        caseList = new List<Case>();
        isApprovalPending = false; // [TTP-472] by default this will be false
        lineItemCount = 0;
    }
    
    /**
     * @description  method to fire invoice rule event
     * @author       
     * @param        NA
     * @return       NA
    **/
    public void createInvoiceRuleResult(){ //sendInvoiceRuleEvent
        List <InvoiceProcessResults__c> invoiceProcessResultList = new List <InvoiceProcessResults__c >();
        if (isSuccess == InvoiceRuleConstant.STATUS_FAIL) { //TTP-2676
            invoice.Rule_Skill_Requirement__c = InvoiceRuleConstant.DOCUMENT_TYPE_FEE.equalsIgnoreCase(invoice.Document_Type__c) 
                                                ? InvoiceRuleService.feeRuleInformation.get(currentRule).Rule_Name__c
                                                : InvoiceRuleService.ruleInformation.get(currentRule).Rule_Name__c;
        } else {
            invoice.Rule_Skill_Requirement__c = '';
        }
        if (!isLineItem) {
            invoice.RuleResult__c = isSuccess == InvoiceRuleConstant.STATUS_FAIL ? ruleResult : '';     //AHOD-196
            InvoiceProcessResults__c invoiceProcessResult = new InvoiceProcessResults__c();
            invoiceProcessResult.RuleName__c = InvoiceRuleConstant.DOCUMENT_TYPE_FEE.equalsIgnoreCase(invoice.Document_Type__c) 
                                                ? InvoiceRuleService.feeRuleInformation.get(currentRule).Rule_Name__c
                                                : InvoiceRuleService.ruleInformation.get(currentRule).Rule_Name__c;
            invoiceProcessResult.Invoice__c = invoice.Id;
            invoiceProcessResult.RuleStatus__c = String.valueOf(isSuccess);
            invoiceProcessResult.ExecutionDateTime__c = executionDateTime;        
            invoiceProcessResult.RuleResult__c = ruleResult;
            invoiceProcessResult.ExecutionNumber__c = executionNumber;
            invoiceProcessResult.RuleNumber__c = currentRule;
            invoiceProcessResultList.add(invoiceProcessResult);
        } else {
            for (Invoice_Line_Item__c lineItem : invoice.Invoice_Line_Items__r) {
                lineItem.RuleResult__c = InvoiceRuleConstant.STATUS_FAILED.equals(lineItem.Status__c) ? lineItemVsRuleResult.get(lineItem.Id) : '';  //AHOD-196
                InvoiceProcessResults__c item = new InvoiceProcessResults__c();
                item.Invoice__c = invoice.Id;
                item.InvoiceLineItem__c = lineItem.id;
                item.RuleStatus__c = InvoiceRuleConstant.STATUS_FAILED.equals(lineItem.Status__c) ? InvoiceRuleConstant.STATUS_FAIL : InvoiceRuleConstant.STATUS_PASS;
                item.RuleName__c = InvoiceRuleConstant.DOCUMENT_TYPE_FEE.equalsIgnoreCase(invoice.Document_Type__c) 
                                    ? InvoiceRuleService.feeRuleInformation.get(currentRule).Rule_Name__c
                                    : InvoiceRuleService.ruleInformation.get(currentRule).Rule_Name__c;
                item.RuleResult__c = lineItemVsRuleResult.get(lineItem.Id);
                item.ExecutionNumber__c = executionNumber;
                item.ExecutionDateTime__c = executionDateTime;
                item.RuleNumber__c = currentRule;
                invoiceProcessResultList.add(item);
            }
        }
        try {
            insert invoiceProcessResultList;
        } catch (Exception e) {
            System.debug('EXCEPTION : ' + e.getMessage() + ' LINE NUMBER : ' + e.getLineNumber());    
        }
    }

    /**
     * @description  method to increment current rule count
     * @author       
     * @param        NA
     * @return       NA
    **/
    public void incrementCurrentRule () {
        if (currentRule == null) {
            currentRule = 1;
        } else {
            currentRule++;
        }        
    }

    /**
     * @description a placeholder, anyone creating invoice rule needs to implement this method
     * @author       
     * @param       result Gives instance of the result being used
                    ruleResult is the string message displayed on the UI component
                    invoiceRecord is the record on which rules are being processed
                    caseList is the list of cases when rule fails
                    ruleStatus is the status msg displayed on UI
     * @return      InvoiceRuleResult is the return type that holds status & mutated data
    **/
    public InvoiceRuleResult processRuleResult (InvoiceRuleResult result, String ruleResult,Invoice__c invoiceRecord, String caseConfigName, String ruleStatus, Map<Id,String> lineItemVsRuleResult) {       
        result.invoice = invoiceRecord;
        if (InvoiceRuleConstant.STATUS_FAIL.equals(ruleStatus)) {
            //TTP-3262 - Optimizing logic to set the owner in failed rules
            if(InvoiceRuleConstant.DOCUMENT_TYPE_FEE.equalsIgnoreCase(invoice.Document_Type__c)) {
                if (invoice.PlanManager__c == 'MPM' && String.isNotEmpty(InvoiceRuleService.feeRuleInformation.get(currentRule).QueueName__c)) {
                    result.invoice.OwnerId = InvoiceRuleService.getQueueInfo.get(InvoiceRuleService.feeRuleInformation.get(currentRule).QueueName__c);
                }
                else if (invoice.PlanManager__c == 'NDSP' && String.isNotEmpty(InvoiceRuleService.feeRuleInformation.get(currentRule).NDSPQueueName__c)) {
                    result.invoice.OwnerId = InvoiceRuleService.getQueueInfo.get(InvoiceRuleService.feeRuleInformation.get(currentRule).NDSPQueueName__c);
                }
                //call the fireInvoiceProcessStatusEvent method if Rule Fails
                if (System.isBatch()) { // ACEM-138
                    InvoiceRuleHelper.fireInvoiceProcessStatusEvent(invoice.Id,InvoiceRuleService.feeRuleInformation.get(currentRule).Rule_Name__c);
                }
            }
            else {
                //[NAPS-95 Added brand flag check for MPM]
                if (invoice.PlanManager__c == 'MPM' && String.isNotEmpty(InvoiceRuleService.ruleInformation.get(currentRule).QueueName__c)) {
                   result.invoice.OwnerId = InvoiceRuleService.getQueueInfo.get(InvoiceRuleService.ruleInformation.get(currentRule).QueueName__c);
                }
                //[NAPS-95 Added brand flag check for NDSP]
                else if (invoice.PlanManager__c == 'NDSP' && String.isNotEmpty(InvoiceRuleService.ruleInformation.get(currentRule).NDSPQueueName__c)){
                result.invoice.OwnerId = InvoiceRuleService.getQueueInfo.get(InvoiceRuleService.ruleInformation.get(currentRule).NDSPQueueName__c); 
                }
                //call the fireInvoiceProcessStatusEvent method if Rule Fails
                if (System.isBatch()) { // ACEM-138
                    InvoiceRuleHelper.fireInvoiceProcessStatusEvent(invoice.Id,InvoiceRuleService.ruleInformation.get(currentRule).Rule_Name__c);
                }
            }           
            result.caseBatchConfig = caseConfigName;
            if (String.isNotBlank(caseConfigName)) {
                result.caseList.add(InvoiceRuleHelper.createCaseForInvoiceRule(result.invoice,Case_Batch_Configuration__mdt.getInstance(caseConfigName)));
            }
        }
        if (lineItemVsRuleResult != null){
            result.lineItemVsRuleResult = lineItemVsRuleResult;
            result.isLineItem = true;
        } else {
            result.isLineItem = false;
            result.ruleResult = ruleResult;
        }
        result.isSuccess = ruleStatus;
        return result;
    }
}