/**
 * @description  [T2P-145] Class Contains helper method for the post processing of payload
 * @company      Cloudwerx
 * @date         14/06/2021
**/

public class DocumentAPIHelper {

    /**
     * @description        [TTP-7] Fetch MEAL_PREP Queue ID
     * @author             Mehul Shah
     * @return			   MEAL_PREP_QUEUE Group record
    **/

    public static final Group MEAL_PREP_QUEUE {
        get {
            if (MEAL_PREP_QUEUE == null) {
                MEAL_PREP_QUEUE = [
                   SELECT Id, DeveloperName
                   FROM Group
                   WHERE DeveloperName = 'OCR_Meal_Preparation'
                ];
            }
           return MEAL_PREP_QUEUE;
        }
        private set;
    }

    /**
     * @description        [TTP-278][TTP-1879]Check document Type from JSON and take further actions
     * @author             Sonali Takke
     * @param              documentData : Response wrapper
     *                     masterCase : Master Case record
     * @return			   Case record Id
    **/
    public static String process(DocumentDTO documentData, Case masterCase) {
        String recordId;
        String brandValue;
        if (!documentData.duplicateDocuments.IsEmpty()) {
            documentData.documentType = 'duplicateinvoice';
        }

        if(masterCase.PlanManager__c == NULL || String.isBlank(masterCase.PlanManager__c)){
            brandValue = masterCase.Client__r.PlanManager__c ;
        }
        else{
            brandValue = masterCase.PlanManager__c;
        }

        Account client = getClient(documentData, brandValue); //Search  Client
        Account provider = getProvider(documentData); //Search  Provider

        switch on documentData.documentType.toLowerCase() {
            when 'duplicateinvoice' {
                Case caseRecord = initializeAsCase(documentData, masterCase, 'DocumentDuplicate', true, client, provider);
                insert caseRecord;
                recordId = caseRecord.Id;
            }

            when 'invoice'{
                recordId = executeInvoiceFlow(documentData, masterCase, 'DocumentInvoice', client, provider);
            }
            //non-invoice
            when else {
                Case caseRecord = initializeAsCase(documentData, masterCase, 'DocumentNonInvoice',false, null, null);
                insert caseRecord;
                recordId = caseRecord.Id;
            }
        }
       return recordId;
    }

    /**
     * @description        [TTP-278]Creates Case record & Link Client/Provider for Invoice/Duplicate documents
     *                     reates Invoice & Line Items record for Invoice documents
     * @author             Sonali Takke
     * @param              documentData : Response wrapper
     *                     documentType : Type of document
     *                     client : Client account record
     *                     provider : Provider account record
     * @return			   Invoice record Id
    **/
    public static String executeInvoiceFlow(DocumentDTO documentData, Case masterCase, String documentType, Account client, Account provider) {
        Invoice__c invoice = initializeAsInvoice(documentData,masterCase,client,provider);
        insert invoice;

        if(invoice.Id != null) {
            List<Invoice_Line_Item__c> listOfItems =  initializeAsInvoiceItem(invoice.Id, documentData.invoiceDetails.lineItems);
            Database.SaveResult[] invoiceLineItemResult = Database.insert(listOfItems, false);   // Insert Line Items

            List<Invoice_Line_Item__c> failedInvoiceItemList = new List<Invoice_Line_Item__c>();

            for (Integer index = 0, size = invoiceLineItemResult.size(); index < size; index++) {
                if (!invoiceLineItemResult[index].isSuccess()) {
                    for (Database.Error error: invoiceLineItemResult[index]?.getErrors()) {
                        if (
                            error.getMessage().containsIgnoreCase('SupportItem__c') &&
                            error.getMessage().containsIgnoreCase(listOfItems[index].Support_Item__r.ExternalId__c)
                        ) {
                            listOfItems[index].Support_Item__r = null;
                            failedInvoiceItemList.add(listOfItems[index]);
                            break;
                        }
                    }
                }
            }
            if (!failedInvoiceItemList.isEmpty()) {
                database.insert (failedInvoiceItemList,false);    // insert failed line items
            }
            if (!DocumentDTO.isMealPrep) {
                //ACEM-105 updated the execution logic to Platform event.
                //AsyncApexJob job = InvoiceRuleHelper.executeInvoiceProcessing(invoice.Id);
                TTPUtil.publishInvoiceTriggerEvent(new List<Invoice_Engine_Trigger__e>{
                    TTPUtil.getInvoiceTriggerEvent(invoice.Id,listOfItems.size())
                });
            } else {
                //[TTP-95] Assign the Invoice record to "Meal Preparation" queue.
                invoice.ownerId = MEAL_PREP_QUEUE?.Id;
                update invoice;
            }
        }
       return invoice.Id; //String.valueOf(invoice.Id)
    }

    /**
      * @description        [TTP-166],[TTP-176]Creates Case record for NonInvoice documents
      * @author             Sonali Takke
      * @param              documentData : Response wrapper
      *                     masterCase : Master Case record
      *                     caseConfigName : Case batch Configuration metdata name
      *                     IsInvoiceType : Boolean to check if document is of INvoice Type
      *                     client : Client account
      *                     provider : Provider account
	  * @return			    Case record
     **/

    public static Case initializeAsCase(
        DocumentDTO documentData, Case masterCase, String caseConfigName, boolean IsInvoiceType,
        Account client, Account provider
    ) {
        Case_Batch_Configuration__mdt caseConfig = Case_Batch_Configuration__mdt.getInstance(caseConfigName);
        Case newCase = new Case();
        newCase.RecordTypeId = caseConfig.Case_Record_Type_Id__c;
        newCase.Status = caseConfig.Status__c;
        newCase.Origin = masterCase.Origin;
        newCase.Priority = caseConfig.Priority__c;
        newCase.ParentId = documentData.masterCaseId;
        newCase.Sypht_File_Id__c = documentData.fileId;
        newCase.Document_Link__c =  documentData.documentLink;
        newCase.Sypht_Response_Link__c =  documentData.responseLink;
        newCase.Document_JSON__c =  JSON.serialize(documentData);
        newCase.Document_Type__c =  documentData.documentType;
        newCase.Bypass_Case_Reassignment_Rules__c = True;   // [TTP-162]
        newCase.Subject = masterCase.subject;

        if (IsInvoiceType) {
           newCase.Type = caseConfig.Type__c;
           newCase.Sub_Type__c = caseConfig.Sub_Type__c;
           newCase.OwnerId = masterCase.PlanManager__c == 'NDSP' ? InvoiceRuleService.getQueueInfo.get(caseConfig.NDSPOwnerName__c) : caseConfig.Owner_Id__c;
           newCase.Description = caseConfig.Description__c;
            if (client != null) {
               newCase.Client__c = client.Id;
            }
            if (provider != null) {
                newCase.Provider__c = provider.Id;
            }
            if ((documentData.documentType).equalsIgnoreCase('duplicateinvoice') && provider != null) {
                newCase.Subject = (
                    caseConfig.Subject__c).replace('[Provider]', provider.Name);
            }
        } else {
           executeCaseAssignment(newCase);  // method call to execute case assignment
           newCase.Description = caseConfig.Description__c +' '+documentData.documentType;
        }
       return newCase;
    }

    /**
      * @description        [T2P-277]Creates Invoice record from Invoice Payload
      * @author             Sonali Takke
      * @param              documentData : Response wrapper
      *                     client : Client account
      *                     provider : Plient account
	  * @return			    Invoice record
     **/
    public static Invoice__c initializeAsInvoice(DocumentDTO documentData, Case masterCase, Account client, Account provider) {
        Invoice__c invoice = new Invoice__c();
        //TTP-1741 - blank Check added
        if (documentData.invoiceDetails != null) {
           invoice.Reference_Number__c = String.isBlank(documentData.invoiceDetails.referenceNo) ? null : documentData.invoiceDetails.referenceNo;
           invoice.Support_Start_Date__c = documentData.invoiceDetails.supportStartDate;
           invoice.Support_End_Date__c = documentData.invoiceDetails.supportEndDate;
           invoice.Total__c = documentData.invoiceDetails.total != null ? documentData.invoiceDetails.total.setScale(2,System.RoundingMode.HALF_UP) : null;
           invoice.GST__c = documentData.invoiceDetails.gst != null ? documentData.invoiceDetails.gst.setScale(2,System.RoundingMode.HALF_UP) : null;
           invoice.Outstanding_Amount__c = documentData.invoiceDetails.outstandingAmount != null ? documentData.invoiceDetails.outstandingAmount.setScale(2,System.RoundingMode.HALF_UP) : null;
        }

        invoice.Sypht_File_Id__c = documentData.fileId;
        invoice.Document_Link__c =  documentData.documentLink;
        invoice.Sypht_Response_Link__c =  documentData.responseLink;
        invoice.Document_JSON__c =  JSON.serialize(documentData);
        invoice.Document_Type__c = documentData.documentType;
        invoice.Case__c =  documentData.masterCaseId;
        //TTP-1741 - blank Check added
        if (documentData.invoiceDetails.paymentDetails != null) {
            //[TTP-462]
            invoice.Account_Name__c =  String.isBlank(documentData.invoiceDetails.paymentDetails.accountName) ? null : documentData.invoiceDetails.paymentDetails.accountName;
            invoice.Account_Number__c =  String.isBlank(documentData.invoiceDetails.paymentDetails.accountNo) ? null : documentData.invoiceDetails.paymentDetails.accountNo;
            invoice.BSB__c =  String.isBlank(documentData.invoiceDetails.paymentDetails.bsb) ? null : documentData.invoiceDetails.paymentDetails.bsb;
            invoice.Biller_Code__c = String.isBlank(documentData.invoiceDetails.paymentDetails.billerCode) ? null : documentData.invoiceDetails.paymentDetails.billerCode?.remove('-');
            invoice.BPAY_Reference__c =  String.isBlank(documentData.invoiceDetails.paymentDetails.reference) ? null : documentData.invoiceDetails.paymentDetails.reference;
        }
        invoice.Client_Name__c = String.isBlank(documentData.participantName) ? null : documentData.participantName;
        invoice.Client_NDIS_Number__c = String.isBlank(documentData.participantNo) ? null : documentData.participantNo;
        invoice.Provider_ABN__c = String.isBlank(documentData.supplierABN) ? null : documentData.supplierABN;
        if (client != null){
            invoice.Client__c = client.Id;
        }
        if (provider != null){
            invoice.Provider__c = provider.Id;
        }
        invoice.Invoice_Origin__c = masterCase.Origin == 'Client Portal'? 'Client Portal' :
            (masterCase.Origin == 'Provider Portal'? 'Provider Portal':'Email');
        return invoice;
    }

    /**
      * @description        [T2P-277] Creates Invoice Line Items for line Items Payload
      * @author             Sonali Takke
      * @param              invoiceId : Response wrapper
      *                     invoiceItems : LineItems response wrapper
	  * @return			    List of Invoice Line Item records
     **/
    public static List <Invoice_Line_Item__c> initializeAsInvoiceItem ( Id invoiceId, List <DocumentDTO.LineItems> invoiceItems) {
        List <Invoice_Line_Item__c> listOfInvoiceItems = new List <Invoice_Line_Item__c>();
        if (invoiceItems != null && !invoiceItems.isEmpty()) {
            for (DocumentDTO.LineItems item : invoiceItems) {

                //[TTP-95]
                if ((!String.isBlank(item.supportItemNo)) &&
                    TTPUtil.containsIgnoreCase(
                        Document_Api_Settings__c.getOrgDefaults().Meal_Prep__c.split(','), item.supportItemNo
                )) {
                    DocumentDTO.isMealPrep = true;
                }
                Invoice_Line_Item__c invoiceItem = new Invoice_Line_Item__c();
                invoiceItem.Invoice__c = invoiceId;
                invoiceItem.Support_Item__r = item.supportItemNo != null ? new SupportItem__c(ExternalId__c = item.supportItemNo) : null;
                invoiceItem.Service_Date_From__c = item.serviceStartDate;
                invoiceItem.Service_Date_To__c = item.serviceEndDate;
                invoiceItem.Description__c = String.isBlank(item.description) ? null :
                                                item.description.length() > 255 ? item.description.substring(0,255) : item.description;
                invoiceItem.Quantity__c = item.quantity != null ? item.quantity.setScale(2,System.RoundingMode.HALF_UP) : null;
                invoiceItem.RateExGST__c = item.rate != null ? item.rate.setScale(2,System.RoundingMode.HALF_UP) : null;
                invoiceItem.UOM__c = item.unitOfMeasure != null ? item.unitOfMeasure : null;
                invoiceItem.GST__c = item.gst != null ?item.gst.setScale(2,System.RoundingMode.HALF_UP) : null;
                invoiceItem.Total__c = item.total != null ? item.total.setScale(2,System.RoundingMode.HALF_UP) : null;
                invoiceItem.Hours__c = item.hours;
                //OPSNBOTS-109
                invoiceItem.ServiceTime__c = String.isBlank(item.serviceTime) ? null : item.serviceTime.length() > 255 ? item.serviceTime.substring(0,255) : item.serviceTime;
                invoiceItem.ServiceWorker__c = String.isBlank(item.serviceWorker) ? null : item.serviceWorker.length() > 255 ? item.serviceWorker.substring(0,255) : item.serviceWorker;
                listOfInvoiceItems.add(invoiceItem);
            }
        }
        return listOfInvoiceItems;
    }

    /**
      * @description        [TTP-278][TTP-1879] Method to search Participant in SF records - Optimized
      * @author             Sonali Takke
      * @param              documentData : Response wrapper
	  * @return			    Client account record
     **/
    public static Account getClient(DocumentDTO documentData, String strBrand) {
        List<Account> accountList = new List<Account>();
        if (!String.IsBlank(documentData.participantMPMAccountNo)) {
            accountList = [
                SELECT Id, MPMAccountNumber__c
                FROM Account
                WHERE MPMAccountNumber__c =: documentData.participantMPMAccountNo AND PlanManager__c =: strBrand LIMIT 1
            ];
        } else if (!String.IsBlank(documentData.participantNo)) {
            accountList =  [
                SELECT Id, NDIS__c
                FROM Account
                WHERE NDIS__c =: documentData.participantNo AND PlanManager__c =: strBrand LIMIT 1
            ];
        }
        return accountList.size() > 0 ? accountList[0] : null;
    }

    /**
      * @description        [TTP-278][TTP-1879] Method to search Provider in SF records - Optimized
      * @author             Sonali Takke
      * @param              documentData : Response wrapper
	  * @return			    Provider account record
      * @Modified           OPSNBOTS-157 - Harshad - 22-09-22
     **/
    public static Account getProvider(DocumentDTO documentData) {
        List<Account> accountList = new List<Account>();
        if (!String.IsBlank(documentData.supplierMPMAccountNo)) {
            accountList = [
                SELECT Id, Name, MPMAccountNumber__c
                FROM Account
                WHERE MPMAccountNumber__c =: documentData.supplierMPMAccountNo AND Status__c NOT IN ('Inactive')  LIMIT 1
            ];
        } else if (!String.IsBlank(documentData.supplierABN)) {
            accountList =  [
                SELECT Id, Name, ABN__c, ParentId
                FROM Account
                WHERE ParentId = NULL AND ABN__c =: documentData.supplierABN AND Status__c NOT IN ('Inactive') LIMIT 1
            ];
        }
        return accountList.size() > 0 ? accountList[0] : null;
    }

    /**
      * @description        [TTP-162] Method to assign Type, Sub-Type and Owner Id on non-invoice document
      * @author             Sonali Takke
      * @param              caseObj : Case record
	  * @return			    Case record
     **/
    public static Case executeCaseAssignment(Case caseObj) {
        // Map of all records of Case_Batch_Configuration Metadata
        Map<String, Case_Batch_Configuration__mdt> caseMetadataMap = Case_Batch_Configuration__mdt.getAll();
        if (caseMetadataMap.containsKey(caseObj.Document_Type__c.toLowerCase())) {
            caseObj.Type = caseMetadataMap.get(caseObj.Document_Type__c.toLowerCase()).Type__c;
            caseObj.Sub_Type__c = caseMetadataMap.get(caseObj.Document_Type__c.toLowerCase()).Sub_Type__c;
            caseObj.OwnerId = caseMetadataMap.get(caseObj.Document_Type__c.toLowerCase()).Owner_Id__c;
        }
        return caseObj;
    }
}