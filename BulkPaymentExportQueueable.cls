/**
 * @description       : Generate a CSV file containing the payment requests data and attach payment request record to the Bulk Payment Request record
 * @author            : Cloudwerx
 * @group             : 
 * @last modified on  : 02-10-2022
 * @last modified by  : Aman Agarwal
**/
public with sharing class BulkPaymentExportQueueable implements Queueable{

    private List<Id> paymentRequestIds;
    private BulkPaymentRequest__c bulkPaymentRequest;
    private String csvString;

    public BulkPaymentExportQueueable(List<Id> paymentRequestIds, BulkPaymentRequest__c bulkPaymentRequest, String csvString) {
        this.paymentRequestIds = paymentRequestIds;
        this.bulkPaymentRequest = bulkPaymentRequest;
        this.csvString = csvString;
    }

    public void execute(QueueableContext context) {
        Savepoint sp = Database.setSavepoint();
        try{    
            List<Payment_Request__c> dataToUpdate = new List<Payment_Request__c>();
            for(Id recId : this.paymentRequestIds){
                dataToUpdate.add(new Payment_Request__c(Id=recId, BulkPaymentRequest__c=this.bulkPaymentRequest.Id));
            }
            update dataToUpdate;
            
            Blob bodyBlob = Blob.valueOf(this.csvString);
            
            ContentVersion contentVersion_1 = new ContentVersion(
                Title = bulkPaymentRequest.Name, 
                PathOnClient = bulkPaymentRequest.Name,
                VersionData = bodyBlob, 
                origin = 'H',
                FirstPublishLocationId = this.bulkPaymentRequest.Id
            );
            insert contentVersion_1;

            String contentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: contentVersion_1.Id].ContentDocumentId;
            this.bulkPaymentRequest.ExportFileId__c = contentDocumentId;
            this.bulkPaymentRequest.ExportFileName__c = contentVersion_1.Title;
            this.bulkPaymentRequest.ExportCompletedAt__c = System.now();
            this.bulkPaymentRequest.Status__c = 'Export Completed';
            this.bulkPaymentRequest.PlanManager__c = (String.isBlank(this.bulkPaymentRequest.PlanManager__c)) ? getPlanManagerValue() : this.bulkPaymentRequest.PlanManager__c;
            update this.bulkPaymentRequest;

            System.debug(this.bulkPaymentRequest);

            Cache.OrgPartition orgPart = Cache.Org.getPartition('local.BulkRequestCache');
            orgPart.put('exportInProgress', false);

            //fire platform event to notify user for refresh
            RefreshEvent__e refreshEvent = new RefreshEvent__e(RecordId__c=this.bulkPaymentRequest.Id);
            Database.SaveResult result = EventBus.publish(refreshEvent);

        } catch(Exception exp) {
            Database.rollback(sp);
            System.debug('Exception while BulkPaymentExport : '+exp.getMessage() + ' Stack Trace : '+exp.getStackTraceString());
            this.bulkPaymentRequest.Export_Import_Error_Details__c = 'Error : ' + exp.getMessage() + ' Stack Trace : '+exp.getStackTraceString();
            this.bulkPaymentRequest.Status__c = 'Export Failed';
            update this.bulkPaymentRequest;

            Cache.OrgPartition orgPart = Cache.Org.getPartition('local.BulkRequestCache');
            orgPart.put('exportInProgress', false);
        }
    }

    public String getPlanManagerValue(){
        String planManagerValue = '';
        List<Payment_Request__c> paymentRequestList = [SELECT Id, PlanManager__c FROM Payment_Request__c WHERE Id =: paymentRequestIds AND PlanManager__c != null];
        for (Payment_Request__c paymentRequest : paymentRequestList) {
            planManagerValue = paymentRequest.PlanManager__c;
            break;
        }
        return planManagerValue;
    }
}