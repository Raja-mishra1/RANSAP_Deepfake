/**
 * @description	 Handler class for InvoiceTrigger
 * @company		 Cloudwerx
 * @date	     21/12/2021
 * @testClass	 InvoiceTriggerHandlerTest
**/

public class InvoiceTriggerHandler {

    public static Boolean didTriggerRun = false;

    public static void handleBeforeUpdate(Map<Id, Invoice__c> oldInvoicesMap, List<Invoice__c> newInvoices){
        List<Invoice__c> invoicesToUpdtPodSkil = new List<Invoice__c>();        //TTP-2676

        Map<Id,Invoice__c> mapOwnerIdName=new Map<Id,Invoice__c>([SELECT Id, OwnerId,Owner.Name
            FROM Invoice__c where Id IN:newInvoices]);

        for (Invoice__c newInvoice : newInvoices) {
            Invoice__c oldInvoice = oldInvoicesMap.get(newInvoice.Id);
            // TTP-2676
            if (newInvoice.Client__c != null && !newInvoice.Client__c.equals(oldInvoice.Client__c)) {
                invoicesToUpdtPodSkil.add(newInvoice);
            }

            //TTP-1414
            if (newInvoice.Invoice_Line_Item_Statuses__c != null
                && oldInvoice.Invoice_Line_Item_Statuses__c != null
                && !newInvoice.Invoice_Line_Item_Statuses__c.equalsIgnoreCase(oldInvoice.Invoice_Line_Item_Statuses__c)
                && !System.Label.Paid.equalsIgnoreCase(newInvoice.Status__c)
                && !System.Label.AwaitingPayment.equalsIgnoreCase(newInvoice.Status__c)
            ) {
                updateInvoiceStatus(newInvoice);
            }

            // TP-3306
            if ((!newInvoice.Status__c.equals(oldInvoice.Status__c)
                || newInvoice.MarkAsPaid__c != oldInvoice.MarkAsPaid__c)
                && (System.Label.IR_ReadyStatus.equalsIgnoreCase(newInvoice.Status__c)
                || System.Label.NDIA_Approved.equalsIgnoreCase(newInvoice.Status__c))
            ) {
                populateFinalisedAt(newInvoice);
            }

            //TTP-4106
            if (String.valueOf(newInvoice.OwnerId).startsWith('00G')) {
                updateQueueName(newInvoice, mapOwnerIdName);
            }
        }
        //TTP-2676
        updatePodSkillRequirement(invoicesToUpdtPodSkil);
    }

    public static void handleBeforeInsert(List<Invoice__c> newInvoices){
        List<Invoice__c> invoicesToUpdtPodSkil = new List<Invoice__c>();        //TTP-2676
        Map<Id,Invoice__c> mapOwnerIdName=new Map<Id,Invoice__c>([SELECT Id, OwnerId,Owner.Name
            FROM Invoice__c where Id IN:newInvoices]);

        for (Invoice__c newInvoice : newInvoices) {
            invoicesToUpdtPodSkil.add(newInvoice);
            //TTP-4106
            if (String.valueOf(newInvoice.OwnerId).startsWith('00G')) {
                updateQueueName(newInvoice, mapOwnerIdName);
            }
        }
        updatePodSkillRequirement(invoicesToUpdtPodSkil);     //TTP-2676
    }

    public static void handleAfterUpdate(Map<Id, Invoice__c> oldInvoicesMap, List<Invoice__c> newInvoices){
        // [TFR-233] : Get the Id of MPM Business Hours
        Id businessHoursId = [SELECT Id FROM BusinessHours WHERE Name = 'MPM Business Hours' LIMIT 1].Id;

        List<Invoice__c> nonCancelledInvoices = new List<Invoice__c>(); //TTP-3994
        Set<Id> invoiceIds = new Set<Id>(); // [TFR-167]

        // [TTP-472]
        if (!didTriggerRun) { // [ACEM-213]
        runEngineIfInvoiceApproved(oldInvoicesMap, newInvoices);
        }

        //Process invoice PSR's [Delete old and create new PSR records]
        updateInvoicePsr(oldInvoicesMap, newInvoices);                          //[TTP-2780]

        // TTP-2389/2598/2599/2601
        List<Id> invoicesToSendSMS = new List<Id>();                            //TTP-2389
        List<Invoice__c> invoicesToCancel = new List<Invoice__c>();             //Harshad: TTP-3596
        List<Invoice__c> invoiceLineItemsKeyToUpdate = new List<Invoice__c>();  //Harshad: TTP-3596
        Set<Id> setCaseId = new Set<Id>(); //OPSNBOTS-218

        for (Invoice__c updtInvoice : newInvoices) {
            Invoice__c oldInvoice = oldInvoicesMap.get(updtInvoice.Id);
            if (!updtInvoice.Status__c.equals(oldInvoice.Status__c)
                && System.Label.Invoice.equalsIgnoreCase(updtInvoice.Document_Type__c)
                && updtInvoice.Client__c != null && updtInvoice.Provider__c != null && updtInvoice.Total__c != null
                && updtInvoice.Support_Start_Date__c != null && updtInvoice.Reference_Number__c != null
                && (Test.isRunningTest() || BusinessHours.isWithin(businessHoursId, System.now())) // [TFR-233] Check if current datetime is in within biz hours 
                && !updtInvoice.InvoiceSubmittedSMSSent__c
                && ((System.Label.IR_ReadyStatus.equalsIgnoreCase(updtInvoice.Status__c)
                    && updtInvoice.Auto_Approve_Client_Invoices__c)
                    ||(System.Label.AwaitingClientApproval.equalsIgnoreCase(updtInvoice.Status__c)
                    && !updtInvoice.Auto_Approve_Client_Invoices__c))) {
                invoicesToSendSMS.add(updtInvoice.Id);
            }

            //Harshad: TTP-3596
            if (updtInvoice.Client_Approval_Status__c!=null
                && !updtInvoice.Client_Approval_Status__c.equals(oldInvoice.Client_Approval_Status__c)
                && updtInvoice.Client_Approval_Status__c.equalsIgnoreCase(System.Label.Rejected)
            ) {
                invoicesToCancel.add(updtInvoice);
            }

            //Harshad: TTP-3596
            if ((updtInvoice.Client__c!=null && !updtInvoice.Client__c.equals(oldInvoice.Client__c))
                || (updtInvoice.Provider__c!=null && !updtInvoice.Provider__c.equals(oldInvoice.Provider__c))
            ) {
                invoiceLineItemsKeyToUpdate.add(updtInvoice);
            }
            //Harshad : TTP-3994
            if (updtInvoice.Status__c != System.label.Cancelled 
                && updtInvoice.OwnerId!= oldInvoice.OwnerId) {
                nonCancelledInvoices.add(updtInvoice);
            }

            //OPSNBOTS-218
            if (updtInvoice.Case__c != oldInvoice.Case__c && updtInvoice.Case__c != null) {
                setCaseId.add(updtInvoice.Case__c);   
                setCaseId.add(oldInvoice.Case__c);            
        }

            // [TFR-167]
            if (updtInvoice.OverrideDuplicateRule__c && !oldInvoicesMap.get(updtInvoice.Id)?.OverrideDuplicateRule__c) {
                invoiceIds.add(updtInvoice.Id);
            }
        }
        //OPSNBOTS-218
        if(!setCaseId.isEmpty()) {
            updateRelatedInvoiceCountOnCase(setCaseId);
        }//End

        if (!invoicesToSendSMS.isEmpty()) {
            sendInvoiceToSMSQueuable(invoicesToSendSMS);
        }

        if (!invoicesToCancel.isEmpty()) {
            // [ACEM-10][ACEM-11]
            //notify providers and clients of Invoice rejection
            notifyRejectedInvoices(invoicesToCancel);

            //cancel related invoice line items - with reasons
            updateToCancelInvoiceLineItems(invoicesToCancel);
        }

        if (!invoiceLineItemsKeyToUpdate.isEmpty()) {
            updateDuplicateKeyInvoiceLineItems(invoiceLineItemsKeyToUpdate);
        }

        if (!nonCancelledInvoices.isEmpty()) {
            updateCurrentOwnersQueues(nonCancelledInvoices);    //Updated Method Name - ACEM-145
        }

        // [TFR-167]
        if (!invoiceIds.isEmpty()) {
            updateOverrideDuplicateRuleOnLineItems(invoiceIds);
        }
    }

    /**
    * @author : Harshad Dani
    * @description : This method is used to handle After Insert Invoices
    * @param newInvoices
    */
    public static void handleAfterInsert (List<Invoice__c> newInvoices){
        List<Invoice__c> nonCancelledInvoices = new List<Invoice__c>();
        List<Invoice__c> manualInvoices = new List<Invoice__c>();   //OPSNBOTS-100
        Set<Id> setCaseId = new Set<Id>();
        Set<Id> invoiceIds = new Set<Id>(); // [TFR-167]

        for (Invoice__c invoiceRec : newInvoices) {
            if (invoiceRec.Status__c != System.label.Cancelled) {
                nonCancelledInvoices.add(invoiceRec);
            }
            //OPSNBOTS-218
            if(invoiceRec.Case__c != null) {
                setCaseId.add(invoiceRec.Case__c);
            }//End

            //OPSNBOTS-100, ACEM-219
            //System.Label.InvoiceOriginTypeForConDocLinkCreation = Manual 
            if (invoiceRec.Invoice_Origin__c != null && System.Label.InvoiceOriginTypeForConDocLinkCreation.contains(invoiceRec.Invoice_Origin__c)) {
                manualInvoices.add(invoiceRec);
            }

            // [TFR-167]
            if (invoiceRec.OverrideDuplicateRule__c) {   
                invoiceIds.add(invoiceRec.Id);
        }
        }

        // [TFR-167]
        if (!invoiceIds.isEmpty()) {
            updateOverrideDuplicateRuleOnLineItems(invoiceIds);
        }

        //OPSNBOTS-218
        if(!setCaseId.isEmpty()) {
            updateRelatedInvoiceCountOnCase(setCaseId);
        }//End
        if (!nonCancelledInvoices.isEmpty()) {
            updateCurrentOwnersQueues(nonCancelledInvoices);    //Updated Method Name - ACEM-145
        }

        //OPSNBOTS-100
        if (!manualInvoices.isEmpty()) {
            createConDocLinkForManualInvoices(manualInvoices);
        }
        
    }

    /**
     * @description	 [TTP-472] [ACEM-213] Method to execute invoice processing when invoice is approved
     * @author		 Mehul Shah
     * @param	     oldInvoicesMap : Old Map of Invoice
     *               newInvoices : New list of Invoice
     * @return	     -
     **/
    public static void runEngineIfInvoiceApproved(Map<Id, Invoice__c> oldInvoicesMap, List<Invoice__c> newInvoices) {
        Set<Id> invoiceIds = new Set<Id>();
        List<Invoice__c> invoicesList = new List<Invoice__c>();
        
        for (Invoice__c inv : newInvoices) {
            if ((System.Label.Approved).equals(inv.Client_Approval_Status__c)
                && !((System.Label.Approved).equals(oldInvoicesMap.get(inv.Id).Client_Approval_Status__c))) {
            didTriggerRun = true;
                    invoiceIds.add(inv.Id);
            }
        }

        if (!invoiceIds.isEmpty()) {
            invoicesList = [SELECT Id, (SELECT Id FROM Invoice_Line_Items__r)
                                             FROM Invoice__c
                                             WHERE Id IN : invoiceIds
                                             LIMIT 20000
                                            ];            
        }
            
        if (invoicesList != null && !invoicesList.isEmpty()) {
            TTPUtil.publishInvoiceEngine(invoicesList); // invoke the invoice engine by firing platform events
        }
    }

    /**
     * @description	 [TTP-2780] Method to process PSR's of an invoice record on Pod_Skill_Requirement__c || Rule_Skill_Requirement__c field value changes
     * @author		 Aman Agarwal
     * @param	     oldInvoicesMap : Old Map of Invoice
     *               newInvoices : New list of Invoice
     * @return	     -
     **/
    public static void updateInvoicePsr(Map<Id, Invoice__c> oldInvoicesMap, List<Invoice__c> newInvoices) {
        Map<Id, Invoice__c> invoiceToUpdatePsr = new Map<Id, Invoice__c>();
        for (Invoice__c newInvoice : newInvoices) {
            Invoice__c oldInvoice = oldInvoicesMap.get(newInvoice.Id);

            if (newInvoice.Pod_Skill_Requirement__c != oldInvoice.Pod_Skill_Requirement__c
            || newInvoice.Rule_Skill_Requirement__c != oldInvoice.Rule_Skill_Requirement__c) {
                invoiceToUpdatePsr.put(newInvoice.Id, newInvoice);
            }
        }
        if(!invoiceToUpdatePsr.isEmpty()) {
            Integer existingPsrCount = ReconnectionsUtil.deletePSR(invoiceToUpdatePsr.keySet());
            if(!Test.isRunningTest() && existingPsrCount > 0) {
                SkillsBasedRouting.routeUsingSkills(invoiceToUpdatePsr.values());
            }
        }
    }

    /**
     * @description	 //AHOD-162 Orignally done in flow for TTP-2676 - Aman - Record_Triggered_Invoice_After_Save_Update_Pod_Skill_Requirement
     * @param	     newInvoices : New list of Invoice
     * @return	     -
     **/
    public static void updatePodSkillRequirement(List<Invoice__c> newInvoices) {
        List<String> relatedClientList = new List<String>(); // related clients
        Map<String,String> clientPodNameMap = new Map<String,String>(); //client pod name map
        for (Invoice__c invoiceRec : newInvoices) {
            if (!String.isBlank(invoiceRec.Client__c)) {
                relatedClientList.add(invoiceRec.Client__c);
            }
        }

        if (!relatedClientList.isEmpty()) {
            List<Account> invoiceClientAccList = [SELECT Id, Pod__c, Pod_Name__c FROM Account WHERE Id IN :relatedClientList];
            for (Account acc : invoiceClientAccList) {
                if (!String.isBlank(acc.Pod_Name__c)) {
                    clientPodNameMap.put(acc.Id,acc.Pod_Name__c);
                }
            }
        }

        if (!clientPodNameMap.isEmpty()) {
            for (Invoice__c invoiceRec : newInvoices) {
                if (clientPodNameMap.containsKey(invoiceRec.Client__c)) {
                    invoiceRec.Pod_Skill_Requirement__c = clientPodNameMap.get(invoiceRec.Client__c);
                } else {
                    invoiceRec.Pod_Skill_Requirement__c = '';
                }
            }
        }
    }

    /**
     * @description	 [TTP-4106] Method to udpate Queue name field on invoice in before create/uptate
     *               Invoice_Before_Update
     * @param	     newInvoiceRec : New/Updated Invoice
    **/
    public static void updateQueueName(Invoice__c newInvoiceRec, Map<Id,Invoice__c> mapOwnerIdName) {
        newInvoiceRec.QueueName__c = mapOwnerIdName.get(newInvoiceRec.Id).Owner.Name;
    }

    /**
     * @description	 //AHOD-162 Orignally done for TP-1414,1413 - Invoice_Before_Update
     * @param	     invoicesToUpdtStatus : List of Invoices for which Invoice_Line_Item_Statuses__c chngd
     *               and status is Paid or Awaiting Payment
     **/
    public static void updateInvoiceStatus(Invoice__c updtInvoiceRec) {
        if (updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.Credit_Paid)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.IR_ReadyStatus)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.NDIA_Approved)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.Rejected)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.New)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.InProgress)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.IR_FailedStatus)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.NDIA_Partially_Approved)
        ) {
            //credit paid
            updtInvoiceRec.Status__c = System.Label.Credit_Paid;
        } else if (updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.Rejected)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.IR_ReadyStatus)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.NDIA_Approved)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.NDIA_Partially_Approved)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.Credit_Paid)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.New)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.InProgress)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.IR_FailedStatus)
        ) {
            //NDIA Rejected
            updtInvoiceRec.Status__c = System.Label.NDIA_Rejected;
            updtInvoiceRec.OwnerId = updtInvoiceRec.Document_Type__c == InvoiceRuleConstant.DOCUMENT_TYPE_FEE ?
            updtInvoiceRec.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ? System.Label.IR_Queue_Finance : 
            System.Label.NDSP_Finance_Queue_Id : updtInvoiceRec.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ?
            System.Label.IR_Queue_Solutions : System.Label.IR_QUEUE_NDSP_SOLUTIONS;
            
        } else if ((updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.NDIA_Approved) 
            || updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.Credit_Paid))
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.IR_ReadyStatus)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.NDIA_Partially_Approved)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.Rejected)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.New)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.InProgress)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.IR_FailedStatus)
        ) {
            //NDIA Approved
            updtInvoiceRec.Status__c = System.Label.NDIA_Approved;  //Update_Status_to_NDIA_Approved
        } else if ((updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.NDIA_Approved)
            || updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.NDIA_Partially_Approved)
            || updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.Credit_Paid))
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.IR_ReadyStatus)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.New)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.InProgress)
            && !updtInvoiceRec.Invoice_Line_Item_Statuses__c.contains(System.Label.IR_FailedStatus)
        ) {
            //NDIA Partially Approved
            updtInvoiceRec.Status__c = System.Label.NDIA_Partially_Approved;  //Update_Status_to_NDIA_Partially_Approved
            updtInvoiceRec.OwnerId = updtInvoiceRec.Document_Type__c == InvoiceRuleConstant.DOCUMENT_TYPE_FEE ?
            updtInvoiceRec.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ? System.Label.IR_Queue_Finance : 
            System.Label.NDSP_Finance_Queue_Id : updtInvoiceRec.PlanManager__c.equalsIgnoreCase(NDSPConstants.MPM) ?
            System.Label.IR_Queue_Solutions : System.Label.IR_QUEUE_NDSP_SOLUTIONS;
            
        } else if (updtInvoiceRec.Invoice_Line_Item_Statuses__c == System.Label.Cancelled) { //ACEM-120
            //Cancelled
            updtInvoiceRec.Status__c = System.Label.Cancelled;  //Update_Status_to_Cancelled
        }
    }

    /**
     * @description	 //AHOD-162 Orignally done for TP-3306 - Sonali B Record_Triggered_Invoice_Update_Before_Save_Populate_Finalised_At
     * @param	     newInvoices : New list of Invoice
    **/
    public static void populateFinalisedAt(Invoice__c newInvoiceRec) {
        if (System.Label.IR_ReadyStatus.equalsIgnoreCase(newInvoiceRec.Status__c)
            && newInvoiceRec.FinalisedAt__c == null
        ) {
            //is status ready
            newInvoiceRec.FinalisedAt__c = System.now();
        } else if (System.Label.NDIA_Approved.equalsIgnoreCase(newInvoiceRec.Status__c)
                    && (newInvoiceRec.PaidByCreditCard__c || newInvoiceRec.MarkAsPaid__c)) {
            //is status approved
            newInvoiceRec.Status__c = System.Label.Paid;
            if (newInvoiceRec.Paid_Date__c == null) {
                newInvoiceRec.Paid_Date__c = System.now();
            }
        }
    }

    /**
     * @description	 //AHOD-162 Orignally done for TTP-2389/2598/2599/2601
     * @param	     invoicesToSendSMS : New list of Invoice
     **/
    public static void sendInvoiceToSMSQueuable(List<Id> invoicesToSendSMS) {
        List<Invoice__c> invoiceObjectList = [SELECT Id,
                                                    Name,
                                                    Total__c,
                                                    Provider_Name__c,
                                                    Client__c,
                                                    Client__r.Name,
                                                    Client__r.NDIS__c,
                                                    Client__r.PersonContactId,
                                                    Support_Start_Date__c,
                                                    Support_End_Date__c,
                                                    Reference_Number__c,
                                                    PlanManager__c
                                            FROM  Invoice__c
                                            WHERE Id IN :invoicesToSendSMS];
        InvoiceSMSNotificationQueuable  b = new InvoiceSMSNotificationQueuable(invoiceObjectList);
        AsyncApexFramework.submitQueueable(b,99);
        AsyncApexFramework.flush();
    }

    /**
    * @author : Harshad Dani
    * @description : This method is used to update Invoice line items- TTP-3596, ACEM-145
    * @param newInvoices
    */
    public static void updateToCancelInvoiceLineItems(List<Invoice__c> newInvoices) {
        List<Invoice_Line_Item__c> invoiceListItems = new List<Invoice_Line_Item__c>();
        for (Invoice_Line_Item__c invoiceLI : [SELECT id,Cancelled_Reason__c,Status__c
                                                FROM Invoice_Line_Item__c WHERE Invoice__c IN:newInvoices 
                                                AND Status__c !=: System.Label.Cancelled]
        ) {
                invoiceLI.Cancelled_Reason__c= System.Label.DeclinedByClient;
                invoiceLI.Status__c= System.Label.Cancelled;
                invoiceListItems.add(invoiceLI);
        }

        if (!invoiceListItems.isEmpty()) {
            update invoiceListItems;
        }

        //Cancelling Rejected Invoices
        cancelRejectedInvoices(newInvoices);    //ACEM-145
    }
    
    /**
    * @ author : Prithviraj Deshmukh
    * @ description : [ACEM-10][ACEM-11]This method is used to send email updates via queueable batch
    * @ param : rejectedInvoices - list of invoices which were rejected by the client
    */
    public static void notifyRejectedInvoices (List<Invoice__c> rejectedInvoiceIds){
        List<Invoice__c> rejectedInvoiceList = [SELECT Id,
                                                    Name,
                                                    Case__r.SuppliedEmail,
                                                    Case__r.OwnerId,
                                                    Client__c,
                                                    Client__r.Name,
                                                    Client__r.PersonContactId,
                                                    ClientNameFormula__c,
                                                    PlanManager__c,
                                                    Provider__c,
                                                    Provider_Name__c,
                                                    Reference_Number__c
                                            FROM  Invoice__c
                                            WHERE Id IN :rejectedInvoiceIds];

        InvoiceCancelNotificationQueuable  b = new InvoiceCancelNotificationQueuable(rejectedInvoiceList);
        AsyncApexFramework.submitQueueable(b,99);
        AsyncApexFramework.flush();
    }

    /**
    * @author : Harshad Dani
    * @description : This method is used to update Invoice statuses- TTP-3596, ACEM-145
    * @param newInvoices
    */
    public static void cancelRejectedInvoices (List<Invoice__c> newInvoices){

        List<Invoice__c> invoicesToBeCancelled = newInvoices.deepClone(true,true,true);
        for(Invoice__c invoiceRec : invoicesToBeCancelled) {
            invoiceRec.Cancelled_Reason__c = System.Label.DeclinedByClient;
            invoiceRec.Status__c= System.Label.Cancelled;
        }

        if(!invoicesToBeCancelled.isEmpty()) {
            update invoicesToBeCancelled;
        }

    }

    /**
    * @author : Harshad Dani
    * @description : This method is used to update Invoice line items DuplicateKey- TTP-3596
    * @param newInvoices
    */
    public static void updateDuplicateKeyInvoiceLineItems(List<Invoice__c> newInvoices) {
        List<Invoice_Line_Item__c> invoiceListItems = new List<Invoice_Line_Item__c>();
        for (Invoice_Line_Item__c invoiceLI : [SELECT id,Cancelled_Reason__c,Status__c,
                                                Invoice__r.Client__r.MPMAccountNumber__c,
                                                Invoice__r.Provider__r.MPMAccountNumber__c,
                                                Support_Item__r.SupportItemNumber__c,
                                                Service_Date_From__c,
                                                Service_Date_To__c,Quantity__c,
                                                Total__c,DuplicateCheck__c
                                                FROM Invoice_Line_Item__c
                                                WHERE Invoice__c IN:newInvoices ]
        ) {
                String  dupKey  =  invoiceLI.Invoice__r.Client__r.MPMAccountNumber__c+'_';
                        dupkey  += invoiceLI.Invoice__r.Provider__r.MPMAccountNumber__c+'_';
                        dupkey  += invoiceLI.Support_Item__r.SupportItemNumber__c+'_';
                        dupkey  += invoiceLI.Service_Date_From__c+'_';
                        dupkey  += invoiceLI.Service_Date_To__c+'_';
                        dupkey  += invoiceLI.Quantity__c+'_';
                        dupkey  += invoiceLI.Total__c;


                invoiceLI.DuplicateCheck__c = dupKey;
                invoiceListItems.add(invoiceLI);
        }

        if (!invoiceListItems.isEmpty()) {
            update invoiceListItems;
        }
    }
    /**
    * @author : Harshad Dani
    * @description : This method is used to update Current Owner's queues- TTP-3994 on After Save
                    , Updated Method name - ACEM-145
    * @param newInvoices
    */
    public static void updateCurrentOwnersQueues (List<Invoice__c> newInvoices) {
        Set<Id> ownerIds = new Set<Id> ();
        Map<Id, String> ownerIdOnQueues = new Map<Id, String>();
        for (Invoice__c invoiceObj : newInvoices) {
            if (invoiceObj.OwnerId.getSobjectType() == Schema.User.SObjectType) {
                ownerIds.add(invoiceObj.OwnerId);
            }
        }
        for (GroupMember gMember : [SELECT Id, Group.Name, UserOrGroupId, Group.Type
                                    FROM GroupMember
                                    WHERE UserOrGroupId IN:ownerIds
                                    AND Group.Type = 'Queue']
                                    ) {
            if (!ownerIdOnQueues.containsKey(gMember.UserOrGroupId)) {
                String queueName = gMember.Group.Name;
                ownerIdOnQueues.put(gMember.UserOrGroupId , queueName);
            } else {
                String queueName = ownerIdOnQueues.get(gMember.UserOrGroupId) + ',' + gMember.Group.Name;
                ownerIdOnQueues.put(gMember.UserOrGroupId , queueName);
            }

        }
        List<Invoice__c> invoiceItems = new List<Invoice__c>();
        for (Invoice__c invoiceObj : [SELECT Id,OwnerId,Current_Owner_s_Queues__c
                                        FROM Invoice__c WHERE Id IN:newInvoices ]) {
                invoiceObj.Current_Owner_s_Queues__c = ownerIdOnQueues.get(invoiceObj.OwnerId);
                invoiceItems.add(invoiceObj);
        }
        if (!invoiceItems.isEmpty()) {
           update invoiceItems;
        }
    }

    /**
    * @author : Rohit Tikoo
    * @description :  This method will create ContentDocumentLinks for files from Parent Case
                       & also create public links for those files - OPSNBOTS-100
    * @param newInvoices
    */
    public static void createConDocLinkForManualInvoices (List<Invoice__c> newInvoices) {

        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> invoiceIdSet = new Set<Id>();
        Set<Id> contentDocumentIdSet = new Set<Id>();
        Map<Id,List<ContentDocumentLink>> caseIdvsContentDocLinkMap = new Map<Id,List<ContentDocumentLink>>();
        for(Invoice__c invRec : newInvoices) {
            if (invRec.Case__c != null) {
                caseIdSet.add(invRec.Case__c);
            }           
            invoiceIdSet.add(invRec.Id);
        }

        if (!caseIdSet.isEmpty() && caseIdSet!= null) {
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId, ContentDocument.LatestPublishedVersionId, 
                                            ContentDocument.LatestPublishedVersion.Title FROM ContentDocumentLink 
                                            where LinkedEntityId IN: caseIdSet AND ContentDocument.FileType != 'sNote']) {
                if(caseIdvsContentDocLinkMap != null && caseIdvsContentDocLinkMap.containsKey(cdl.LinkedEntityId)) {
                    caseIdvsContentDocLinkMap.get(cdl.LinkedEntityId).add(cdl);
                } else {
                    caseIdvsContentDocLinkMap.put(cdl.LinkedEntityId, new List<ContentDocumentLink>{cdl});
                }
                contentDocumentIdSet.add(cdl.ContentDocumentId);
            }
        }

        if (caseIdvsContentDocLinkMap != null && !caseIdvsContentDocLinkMap.isEmpty()) {
            List<ContentDocumentLink> conDocList = new List<ContentDocumentLink>();

            for(Invoice__c invRec : newInvoices) {
                if (caseIdvsContentDocLinkMap.containsKey(invRec?.Case__c)) {
                    for (ContentDocumentLink conDocLink : caseIdvsContentDocLinkMap.get(invRec.Case__c)) {
                        //CREATE CONTENTDOCUMENTLINK INSTANCE
                        ContentDocumentLink cdl = new ContentDocumentLink();
                        cdl.LinkedEntityId = invRec.Id;
                        cdl.ContentDocumentId = conDocLink.ContentDocumentId;
                        cdl.Visibility ='AllUsers';
                        cdl.ShareType ='V';
                        conDocList.add(cdl);                        
                    }
                }
            }

            //INSERT CONTENTDOCUMENTLINK LIST
            if (!conDocList.isEmpty() && conDocList != null) {
                insert conDocList;
            }        
        }        
    }

    /**
    * @author : Akshansh Jain
    * @description : This method is used to handle After Delete operations
    * @param oldInvoices
    */
    public static void handleAfterDelete (List<Invoice__c> oldInvoices){
        Set<Id> setCaseId = new Set<Id>();
        for(Invoice__c obj : oldInvoices) {
            if(obj.Case__c != null) {
                setCaseId.add(obj.Case__c);
            }
        }
        if(!setCaseId.isEmpty()) {
            updateRelatedInvoiceCountOnCase(setCaseId);//OPSNBOTS-218
        }
    }

    /**
    * @author : Akshansh Jain
    * @description : This method is used to handle After UnDelete operations
    * @param newInvoices
    */
    public static void handleAfterUndelete (List<Invoice__c> newInvoices){
        Set<Id> setCaseId = new Set<Id>();
        for(Invoice__c obj : newInvoices) {
            if(obj.Case__c != null) {
                setCaseId.add(obj.Case__c);
            }
        }
        if(!setCaseId.isEmpty()) {
            updateRelatedInvoiceCountOnCase(setCaseId);//OPSNBOTS-218
        }
    }

    /**
    * @author : Akshansh Jain
    * @description : This method is used to perform rollup summary of related Invoices on Cases
    * @param setCaseId
    */
    private static Void updateRelatedInvoiceCountOnCase(Set<Id> setCaseId) {
        if(General_T2P_Settings__c.getOrgDefaults()?.ActivateInvoiceCountOnCase__c == true) {
            List<AggregateResult> vLstAggr = [SELECT count(Id) noOfInvoices, Case__c FROM Invoice__c
                                        WHERE Case__c IN :setCaseId GROUP BY Case__c];
            list<Case> lstcases = new list<Case>();
            for(AggregateResult vAggr : vLstAggr) {
                string caseId = (string) vAggr.get('Case__c');
                Integer invoiceCount = (Integer) vAggr.get('noOfInvoices');
                lstcases.add(new Case(Id = caseId, Related_Invoices__c = invoiceCount));
            }
            if(!lstcases.isEmpty()) {
                update lstcases;    
            }
        }
    }

    /**
    * @author      : Mehul Shah
    * @description : [TFR-167] To update OverrideDuplicateRule__c on line items if OverrideDuplicateRule__c on invoice is true
    * @param       : invoiceIds : list of invoice ids
    */
    public static void updateOverrideDuplicateRuleOnLineItems(Set<Id> invoiceIds) {
        List<Invoice_Line_Item__c> lineItemsList = [SELECT Id, OverrideDuplicateRule__c FROM Invoice_Line_Item__c WHERE Invoice__c IN : invoiceIds];
        
        for (Invoice_Line_Item__c lineItem : lineItemsList) {
            lineItem.OverrideDuplicateRule__c = true;
        }

        if (!lineItemsList.isEmpty()) {
            update lineItemsList;
        }
    }
}