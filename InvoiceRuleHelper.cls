/**
 * @description  [TTP-38] This is helper class for abstraction
 * @company      Cloudwerx
 * @date         19/07/2021
**/

public without sharing class InvoiceRuleHelper {
    /**
     * @description  [TTP-38] This method returns invoice record depending on status  
     * @author       Prithviraj Deshmukh
     * @param        invoiceRec        : Invoice Record 
     *               status            : Invoice Status
     *               isApprovalPending : Variable to check if invoice is pending approval
     * @return       Invoice Record
    **/


    public static Invoice__c updateInvoiceStatus (Invoice__c invoiceRec, String status, Boolean isApprovalPending, InvoiceRuleResult result) {
        List<Invoice_Line_Item__c> invoiceItemList = new List<Invoice_Line_Item__c>();
        Integer CreditPaidILCount = 0;        
        for (Invoice_Line_Item__c invoiceLineItemRec : invoiceRec.Invoice_Line_Items__r) {
            if (invoiceLineItemRec.Status__c == System.Label.Credit_Paid) {
                CreditPaidILCount++;
            } else {
                invoiceLineItemRec.Status__c = status;
            }
           
            if (status.equalsIgnoreCase('In Progress')) { //Set initial values for Invoice Line Item
                invoiceLineItemRec.Plan__c = null;
                invoiceLineItemRec.Plan_Support__c = null;
                invoiceLineItemRec.Plan_Support_Item__c = null;
                invoiceLineItemRec.Substitution_Plan_Support_Preferences__c = null;
                invoiceLineItemRec.Reserved_Plan_Support_Preferences__c = null;
                invoiceLineItemRec.Service_Booking__c = null;
                invoiceLineItemRec.Support_Item_Price__c = null; //TTP-1689
                invoiceLineItemRec.Interchangeable__c = false;
                invoiceLineItemRec.Credit_Amount__c = 0;
                invoiceLineItemRec.Credit_Note__c = null;
                invoiceLineItemRec.RuleResult__c = null;    //AHOD-196

                //AHOD-812
                invoiceLineItemRec.Plan__r = null;
                invoiceLineItemRec.Plan_Support__r = null;
                invoiceLineItemRec.Plan_Support_Item__r = null;
                invoiceLineItemRec.Substitution_Plan_Support_Preferences__r = null;
                invoiceLineItemRec.Reserved_Plan_Support_Preferences__r = null;
                invoiceLineItemRec.Service_Booking__r = null;
                invoiceLineItemRec.Support_Item_Price__r = null; //TTP-1689
                invoiceLineItemRec.Credit_Note__r = null;
            }           
            invoiceItemList.add(invoiceLineItemRec);
            
        }
        result.lineItemCount = invoiceItemList.size();
       
        if(CreditPaidILCount != 0 &&  result.lineItemCount == CreditPaidILCount) { 
            //if all lineItem are credit Paid then mark invoice as credit paid
            status = System.Label.Credit_Paid;
        }

        // [TTP-472] : Start
         if (isApprovalPending) {
            invoiceRec.Status__c = 'Awaiting Client Approval';
        } else {
            invoiceRec.Status__c = status;
            //TTP-3387
            invoiceRec.OwnerId = InvoiceRuleConstant.STATUS_READY.equalsIgnoreCase(status) 
                                    ? invoiceRec.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM)
                                    ? InvoiceRuleConstant.FINANCE_QUEUE : InvoiceRuleConstant.NDSP_FINANCE
                                    : invoiceRec.OwnerId;
        }
        // [TTP-472] : End

        if (status.equalsIgnoreCase('In Progress')) {
            invoiceRec.RuleResult__c = null;        //AHOD-196
        }
        
        Database.update(invoiceRec);
        Database.update(invoiceItemList);
        return invoiceRec;
    }

    /**
     * @description  [TTP-38] This method publishes platform event Invoice_Process_Status__e
     * @author       Prithviraj Deshmukh
     * @param        recordId : Invoice Record Id
     *               ruleName : Rule Name
    **/

    public static void fireInvoiceProcessStatusEvent(Id recordId, String ruleName) {
        Invoice_Process_Status__e event = new Invoice_Process_Status__e(RecordId__c=recordId,Rule_Name__c = ruleName);
        EventBus.publish(event);
    }

    /**
     * @description  [TTP-38] This method to initialize batch - populate execution number,updateInvoiceStatus,fireInvoiceProcessStatusEvent
     * @author       Prithviraj Deshmukh
     * @param        invoice : Invoice__c record 
     *               result  : Instance of InvoiceRuleResult
     * @return       InvoiceRuleResult is the return type that holds status & mutated data
    **/

    public static InvoiceRuleResult initializeStart(Invoice__c invoice, InvoiceRuleResult result) {

        //DML ON INVOICE & INVOICE LINE ITEM 
        // [TTP-472] - Added isApprovalPending parameter
        result.invoice = InvoiceRuleHelper.updateInvoiceStatus(invoice,'In Progress', result.isApprovalPending, result);           

        //FIRE START EVENT TO UPDATE STATUS
        if (System.isBatch()) { // ACEM-138
            InvoiceRuleHelper.fireInvoiceProcessStatusEvent(invoice.Id,InvoiceRuleConstant.IR_START);
        } 

        List<InvoiceProcessResults__c> invoiceResultList = [
            SELECT Id,ExecutionNumber__c 
            FROM InvoiceProcessResults__c 
            WHERE Invoice__c =: invoice.Id 
            ORDER BY ExecutionNumber__c DESC
        ];
        if (!invoiceResultList.isEmpty()) {
            //INCEREMENT EXECUTION NO FROM THE LAST ONE 
            result.executionNumber = Integer.valueOf(invoiceResultList[0].ExecutionNumber__c) + 1;  
        }
        invoice.OwnerId = InvoiceRuleConstant.ACCOUNTS_QUEUE;
        return result;
    }

    /**
     * @description  [TTP-38] Returns apex job based on JobId 
     * @author       Prithviraj Deshmukh
     * @param        invoiceId : Id of current Invoice record 
     * @return       AsyncApexJob instance of Apex Job
    **/

    @AuraEnabled
    public static AsyncApexJob executeInvoiceProcessing(Id invoiceId) {
        try {
            InvoiceRuleOrchestrator batchVar = new InvoiceRuleOrchestrator(invoiceId);
            ID jobId = AsyncApexFramework.submitBatch(batchVar,5,99);
            AsyncApexFramework.flush(); 

            Invoice__c invoiceRecord = new Invoice__c(
                Id = invoiceId, Invoice_Process_Job_Id__c = jobId
            );
            Update invoiceRecord;
            AsyncApexJob job = InvoiceProcessingStatusController.getBatchJob(jobId, false);
            return job;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description  [T2P-97] [TTP-607] Common Method to create Case via Invoice Rule Orchestrator
     * @author       Prithviraj Deshmukh
     * @param        invoice            : Invoice__c record  
     *               caseBatchConfig    : Custom metadata record
     * @return       Case record
    **/
    public static Case createCaseForInvoiceRule(Invoice__c invoice, Case_Batch_Configuration__mdt caseBatchConfig) {
        Case caseObj = new Case();
        /*caseObj.RecordTypeId = caseBatchConfig.Case_Record_Type_Id__c;
        caseObj.Client__c = invoice.Client__c != null ? invoice.Client__c : null; 
       	caseObj.Provider__c = invoice.Provider__c != null ? invoice.Provider__c  : null; 
        caseObj.Invoice__c = invoice.Id;   
        caseObj.Status = caseBatchConfig.Status__c;       
        caseObj.Type = caseBatchConfig.Type__c;        
        caseObj.Sub_Type__c = caseBatchConfig.Sub_Type__c;      
        caseObj.OwnerId = caseBatchConfig.Owner_Id__c;       
        caseObj.Origin = caseBatchConfig.Case_Origin__c;      
        caseObj.Priority = caseBatchConfig.Priority__c; 
        caseObj.ParentId = invoice.Case__c;
        
        //Process Invoice By Legacy
        if ('DocumentInvoice'.equals(caseBatchConfig.Label)) {
            if (!String.isEmpty(caseBatchConfig.Subject__c)) {
                caseObj.Subject = invoice.Provider__c != null ? 
                    (caseBatchConfig.Subject__c).replace('[Provider]',invoice.Provider__r.Name):
                    (caseBatchConfig.Subject__c).replace('- [Provider]','');
            }
            //TTP-143 - To handle duplicate case creation failure
            Case existingCase = InvoiceRuleService.getExistingCase(invoice,invoice.Sypht_File_Id__c);
            if (existingCase != null) {
                return existingCase;
            }                
            caseObj.Description = caseBatchConfig.Description__c;    
            caseObj.Sypht_File_Id__c = invoice.Sypht_File_Id__c;
            caseObj.Document_Link__c = invoice.Document_Link__c;
            caseObj.Sypht_Response_Link__c = invoice.Sypht_Response_Link__c;
            caseObj.Document_JSON__c = invoice.Document_JSON__c;
            caseObj.Document_Type__c = invoice.Document_Type__c;  
        } else {                
            //Rule Failure case creation
            caseObj.Subject = invoice.Case__r.Subject;
            caseObj.Description = invoice.Case__r.Description;
            caseObj.Bypass_Case_Reassignment_Rules__c = true;
        }*/
        return caseObj;        
    }


    /**
     * @description  [TTP-1563] Invocable method for re-running the invoice rule engine. 
     * @author       Mehul Shah
     * @param        invoiceIds : List of invoice record ids.
    **/

    // [TTP-472] - Start
    @InvocableMethod(label='Re-run Invoice Rule Engine' description='Re-run Invoice Rule Engine')
    public static void reRunInvoiceEngine (List<Id> invoiceIds) {
        executeInvoiceProcessing(invoiceIds[0]);
    }
    // [TTP-472] - End

    /**
     * @description  [TTP-3490] 
     * @author       Sonali Takke
     * @param        invoiceRec        : Invoice Record 
     *               status            : Invoice Status
    **/
    public static void setInvoiceStatus (Invoice__c invoiceRec, String status) {
        List<Invoice_Line_Item__c> invoiceLineItemList = new List<Invoice_Line_Item__c>();
        for (Invoice_Line_Item__c invoiceLineItemRec : invoiceRec.Invoice_Line_Items__r) {
            Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c(
                Id = invoiceLineItemRec.Id,
                Status__c = status
            );
            invoiceLineItemList.add(lineItem);
        }
        Invoice__c inv = new Invoice__c ( 
            Id = invoiceRec.Id,
            Status__c = status
        );
        Database.update(inv);
        Database.update(invoiceLineItemList);
    }

    /**
    * @description    [TTP-3071] Calculate pro rated total for line item
    * @author         Sonali Bhat
    * @param          lineItem - invoice line item record
                      invoice - invoice record
    * @return         proRateTotal - decimal value           
    */
    public static Decimal getProRatedTotal (Invoice_Line_Item__c lineItem, Invoice__c invoice ) {
        Decimal proRateTotal;
        Decimal pgRate = getPGRate(lineItem, invoice);
        // Get the number of days in a month from Invoice Date
        Decimal daysInInvoiceMonth = date.daysInMonth(invoice.Support_Start_Date__c.year(), invoice.Support_Start_Date__c.month());
        // Number of days between Invoice Line Item Dates
        Decimal daysBetweenLineItemDates = lineItem.Service_Date_From__c.daysBetween(lineItem.Service_Date_To__c) +1;
        Decimal diffOfDays = daysInInvoiceMonth != null && daysInInvoiceMonth != 0 ? 
                                (daysBetweenLineItemDates/daysInInvoiceMonth) : 0;
        proRateTotal= (diffOfDays * pgRate).setScale(2,System.RoundingMode.HALF_UP);
        return ((proRateTotal != null && proRateTotal > 0) ? proRateTotal : 0);
    }

    /**
    * @description    [TTP-3071] Calculate pg rate for line item
    * @author         Sonali Bhat
    * @param          lineItem - invoice line item record
                      invoice - invoice record
    * @return         pgRate - decimal value           
    */
    public static Decimal getPGRate(Invoice_Line_Item__c lineItem, Invoice__c invoice) {
        Decimal pgRate;
        if (invoice.Client__r.ModifiedMonashModelScore__c == 7) {
            pgRate = lineItem.Support_Item_Price__r.VeryRemotePrice__c;
        } else if(invoice.Client__r.ModifiedMonashModelScore__c == 6){
            pgRate = lineItem.Support_Item_Price__r.RemotePrice__c;
        }else if (invoice.Client__r.BillingStateCode == 'ACT') {
            pgRate = lineItem.Support_Item_Price__r.ACTPrice__c;
        } else if(invoice.Client__r.BillingStateCode == 'NSW') {
            pgRate = lineItem.Support_Item_Price__r.NSWPrice__c;
        } else if(invoice.Client__r.BillingStateCode == 'VIC') {
            pgRate = lineItem.Support_Item_Price__r.VICPrice__c;
        } else if(invoice.Client__r.BillingStateCode == 'QLD') {
            pgRate = lineItem.Support_Item_Price__r.QLDPrice__c;
        } else if(invoice.Client__r.BillingStateCode == 'WA') {
            pgRate = lineItem.Support_Item_Price__r.WAPrice__c;
        } else if(invoice.Client__r.BillingStateCode == 'NT') {
            pgRate = lineItem.Support_Item_Price__r.NTPrice__c;
        } else if(invoice.Client__r.BillingStateCode == 'SA') {
            pgRate = lineItem.Support_Item_Price__r.SAPrice__c;
        } else if(invoice.Client__r.BillingStateCode == 'TAS') {
            pgRate = lineItem.Support_Item_Price__r.TASPrice__c;
        }
        return ((pgRate != null && pgRate > 0) ? pgRate.setScale(2,System.RoundingMode.HALF_UP) : 0);
    }

    /**
    * @description    [PA-15] Get State Name from the State Code
    * @author         Palak Singla
    * @param          stateCode - Australian State Code
    * @return         stateName - Australian State Full Name          
    **/
    public static string getStateFullName (String stateCode){
        String stateName = '';
        if(String.isNotBlank(stateCode)){
            stateCode = stateCode.toUppercase();
            switch on stateCode {
                when 'ACT' {
                    stateName = 'Australian Capital Territory';
                }
                when 'NSW' {
                    stateName = 'New South Wales';
                }
                when 'NT' {
                    stateName = 'Northern Territory';
                }
                when 'QLD' {
                    stateName = 'Queensland';
                }
                when 'SA' {
                    stateName = 'South Australia';
                }
                when 'TAS' {
                    stateName = 'Tasmania';
                }
                when 'VIC' {
                    stateName = 'Victoria';
                }
                when 'WA' {
                    stateName = 'Western Australia';
                }
                when else {
                    stateName = '';
                }
            }
        }
        
        return stateName;
    }

     /**
    * @description    [PA-15] Get Day of Week from specified DateTime field
    * @author         Palak Singla
    * @param          dateTimeToProcess - DateTime value
    * @return         dayOfWeekResulted - Day of the Week      
    **/
    public static string getDayOfWeek(DateTime dateTimeToProcess){
        String dayOfWeekResulted = '';
        if(dateTimeToProcess != null){
            String dayOfWeek = dateTimeToProcess.format('E');
            switch on dayOfWeek {
                when 'Sun' {
                    dayOfWeekResulted = 'Sunday';
                }
                when 'Sat' {
                    dayOfWeekResulted = 'Saturday';
                }
                when 'Mon','Tue','Wed','Thu','Fri' {
                    dayOfWeekResulted = 'Weekday';
                }
            }
        }
        return dayOfWeekResulted;
    }

    /**
    * @description    [AHOD -275] Create Mapping of Service Booking Request
    * @author         Sonali Bhat
    * @param          invoice   - invoice record
                      lineItem   - invoice line item record
                      requestType
    * @return         ServiceBookingRequest__c         
    */
    public static ServiceBookingRequest__c createSBRMapping(Invoice__c invoice, Invoice_Line_Item__c lineItem, String requestType) {
        ServiceBookingRequest__c sbrObj = new ServiceBookingRequest__c();
        sbrObj.Account__c = invoice.Client__c;
        sbrObj.Case__c =   invoice.Case__c;
        sbrObj.CaseSubType__c = invoice.Case__r.Sub_Type__c;
        sbrObj.ClientDateOfBirth__c = invoice.Client__r.PersonBirthdate;
        sbrObj.ClientFirstName__c = invoice.Client__r.FirstName;
        sbrObj.ClientLastName__c = invoice.Client__r.LastName;
        sbrObj.ClientNDISNumber__c = invoice.Client__r.NDIS__c;
        sbrObj.Priority__c = 'High';
        sbrObj.RequestedBy__c = System.Label.SBRRequestedBy;
        sbrObj.RequestType__c = requestType;
        sbrObj.Status__c = System.Label.SBRNotStartedStatus;
       
        // populate BudgetAllocation__c
        if (invoice.Client__r.PersonBirthdate!= null) {
            Integer days = invoice.Client__r.PersonBirthdate.daysBetween(Date.Today());
            Integer age = Date.isLeapYear(Date.Today().Year()) ? Integer.valueOf(days/366) : Integer.valueOf(days/365);
            sbrObj.BudgetAllocation__c = TTPUtil.getCoreValues(age);
        }
      
        // populate InvoiceSupportCategory__c
        List<InvoiceSupportCategoryWrapper> invoiceSCWrapperList = new List<InvoiceSupportCategoryWrapper>();
        InvoiceSupportCategoryWrapper invoiceSCWrapperObj = new InvoiceSupportCategoryWrapper();
        invoiceSCWrapperObj.SupportCategoryCode = lineItem.Support_Item__r?.SupportCategory__r?.SupportCategoryCode__c;
        invoiceSCWrapperObj.SupportCategoryNumber = lineItem.Support_Item__r?.SupportCategory__r?.SupportCategoryNumber__c;
        invoiceSCWrapperObj.SupportCategoryAmount = lineItem.Total__c;
        invoiceSCWrapperList.add(invoiceSCWrapperObj);
        sbrObj.InvoiceSupportCategory__c = JSON.serialize(invoiceSCWrapperList);
        return  sbrObj;

    }


    /**
    [AHOD - 275] wrapper class
    */
    public class InvoiceSupportCategoryWrapper {
        public String  SupportCategoryCode;
        public Decimal  SupportCategoryNumber;
        public Decimal SupportCategoryAmount;
    }

}