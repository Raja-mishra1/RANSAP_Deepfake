/**
 * @description       : This class is used by exportViewer LWC to get the payment data and export the records
 * @company           : Cloudwerx
 * @date              : 02-11-2022
 * @testClass         : ExportViewerControllerTest
**/
public with sharing class ExportViewerController {

    public static List <NDIA_Bulk_Payment_Request_Setting__mdt> bulkPaymentObj = [SELECT Id, Export_to_NDIA_Record_Size__c FROM NDIA_Bulk_Payment_Request_Setting__mdt LIMIT 1];
    public static Integer queryLimit = integer.valueOf(bulkPaymentObj[0].Export_to_NDIA_Record_Size__c);

    /**
     * @description      Method to get the payment records on load, search and filter
     * @author           Sonali Bhat    
     * @return           export wrapper        
    **/
    @AuraEnabled
    public static String fetchRecords(
        String objectName, String fields, String nonVisibleFields, String statusFilterValues, 
        List<String> globalSearchFields, String soqlfilter, String searchKey, String serviceDateFrom, String serviceDateTo,
        String createdDateFrom, String createdDateTo , String statusSelectedValues, String invoiceTypeSelectedValues, String orderByField
    ) {
        try {
            // filtered status list
            Boolean pendingFound = false;
            List<String> filterStatusList = new List<String>(); // list for filtered status values
            if (!String.isEmpty(statusSelectedValues)) {
                if (statusSelectedValues.contains(',')) {
                    filterStatusList = statusSelectedValues.split(',');
                    for (integer i =0;i<=filterStatusList.size()-1;i++) {
                        String value = filterStatusList[i];
                        value = value.remove('\'');
                        if (value == 'Pending') {
                            pendingFound = true;
                            filterStatusList.remove(i); // remove pending from list as pending status has additional conditions to be added
                            break;
                        }
                    } 
                } else if (statusSelectedValues.contains('Pending')) {
                    pendingFound = true;
                } else {
                    filterStatusList.add(statusSelectedValues);
                }
            }

            //invoiceTypeFilterList
            List<String> invoiceTypeList = new List<String>();
            if (!String.isEmpty(invoiceTypeSelectedValues)) {
                if (invoiceTypeSelectedValues.contains(',')) {
                    invoiceTypeList = invoiceTypeSelectedValues.split(',');
                } else {
                    invoiceTypeList.add(invoiceTypeSelectedValues);
                }
            }

            // default status list
            List<String> defaultStatusList = new List<String>();
            if (!string.isEmpty(statusFilterValues)) {
                if (statusFilterValues.contains(',')) {
                    defaultStatusList = statusFilterValues.split(',');
                    for (integer i = 0; i<=defaultStatusList.size()-1; i++) {
                        String value = defaultStatusList[i];
                        value = value.remove('\'');
                        if (value == 'Pending') {
                            defaultStatusList.remove(i); // remove pending from list as pending status has additional conditions to be added
                            break;
                        }
                    } 
                }
            }
            
            String allFields = fields ;

            if (!String.isEmpty(nonVisibleFields)) {
                allFields += ',' +nonVisibleFields;
            }

            String soqlQuery = 'SELECT Id, ' + allFields + ' FROM ' + objectName + ' WHERE Invoice__r.Status__c NOT IN (\'Cancelled\',\'Failed\') AND Invoice_Line_Item__r.Status__c NOT IN (\'Cancelled\', \'Failed\' ) AND ';

            if (filterStatusList.size() > 0) {  
                // if filtered status has values other than pending
                soqlQuery += '( Status__c IN '+filterStatusList+ ' ';
                if ( pendingFound && !String.isEmpty(soqlfilter)) {
                    // if pending value is also selected for status filter
                    soqlQuery+= ' OR ' + ' ( ' +soqlfilter + '  ) ';
                }
                soqlQuery += ') ';
            } else if (pendingFound && !String.isEmpty(soqlfilter)) { 
                // Only Pending value is selected for status filter 
                soqlQuery+= ' ( ' + soqlfilter + ' ) ';
            } else if (defaultStatusList.size() > 0 ) {
                // no status filter present, add default filter for status
                soqlQuery += ' ( Status__c IN' +defaultStatusList+ ' ';
                soqlQuery += ' OR ' + ' ( ' +soqlfilter + '  ) ';
                soqlQuery += ') ';
            }

            //invoiceType filter
            if (invoiceTypeList.size() > 0) { 
                soqlQuery += ' AND (';
                for(String invoiceType : invoiceTypeList) {
                    if (invoiceType.contains('Fee')) {
                        String feeType = invoiceType.substringAfter('- ');
                        soqlQuery += '( Invoice__r.Document_Type__c = \'FEE\' AND Invoice__r.FeeType__c = \'' + feeType + ' ) OR ';
                    } else {
                        soqlQuery += 'Invoice__r.Document_Type__c = ' + invoiceType + ' OR ';
                    }
                }
                soqlQuery = soqlQuery.removeEnd('OR ');
                soqlQuery+= ') ' ;
            }
             
            // Global Search
            if (!String.isEmpty(searchKey) && !globalSearchFields.isEmpty()) {
                soqlQuery += ' AND (';
                String tempInput ='\'%' + searchKey  + '%\'';
                for (String s : globalSearchFields) {
                    soqlQuery += '(' +s+ ' LIKE ' +tempInput +') OR ';
                }
                soqlQuery = soqlQuery.removeEnd('OR ');
                soqlQuery+= ') ' ;
            } 
            
            if (!String.isEmpty(serviceDateFrom)) {
                soqlQuery += ' AND (';
                soqlQuery += ' Service_Date_From__c >= '+serviceDateFrom;
                soqlQuery+= ') ' ;
            }

            if (!String.isEmpty(serviceDateTo)) {
                soqlQuery += ' AND (';
                soqlQuery += ' Service_Date_To__c <= '+serviceDateTo;
                soqlQuery+= ') ' ;
            }

            if (!String.isEmpty(createdDateFrom)) {
                soqlQuery += ' AND (';
                soqlQuery += ' CreatedDateOfPaymentReq__c >= '+createdDateFrom;
                soqlQuery+= ') ' ;
            }

            if (!String.isEmpty(createdDateTo)) {
                soqlQuery += ' AND (';
                soqlQuery += ' CreatedDateOfPaymentReq__c <= '+createdDateTo;
                soqlQuery+= ') ' ;
            }

            if(!String.isEmpty(orderByField)) {
                soqlQuery += ' ORDER BY ' +orderByField;
            }

            soqlQuery += ' LIMIT ' +queryLimit;
            System.debug('soqlQuery => '+soqlQuery);

            List <SObject> listOfRecords = Database.query(soqlQuery);

            ExportWrapper wrap = new ExportWrapper();

            Cache.OrgPartition orgPart = Cache.Org.getPartition('local.BulkRequestCache');
            wrap.isExportInProcessing = (Boolean)orgPart.get('exportInProgress');
            if(wrap.isExportInProcessing == null){
                wrap.isExportInProcessing = false;
            }

            wrap.listOfRecords = Database.query(soqlQuery);
            wrap.bulkPaymentMdt = [SELECT Id, MasterLabel, RegistrationNumber__c, NDSPRegistrationNumber__c FROM NDIA_Bulk_Payment_Request_Setting__mdt LIMIT 1]; //NAP5-152 added the NDSPRegistrationNumber__c field in the query
            wrap.bulkPaymentCsvMapping = [SELECT Id, MasterLabel, Field_Api_Name__c, Order__c FROM NDIA_Bulk_Payment_Csv_Mapping__mdt ORDER BY Order__c];

            return JSON.serialize(wrap);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ExportWrapper {
        @AuraEnabled public Boolean isExportInProcessing;
        @AuraEnabled public List<SObject> listOfRecords;
        @AuraEnabled public NDIA_Bulk_Payment_Request_Setting__mdt bulkPaymentMdt;
        @AuraEnabled public List<NDIA_Bulk_Payment_Csv_Mapping__mdt> bulkPaymentCsvMapping;
    }

    /**
     * @description      Method called on export button to process the selected payment records
     * @author           Aman Agarwal    
     * @return           bulk payment record id       
    **/
    @AuraEnabled
    public static string createBulkPaymentRequest(String bulkJson){
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.BulkRequestCache');
        Boolean exportInProgress = (Boolean)orgPart.get('exportInProgress');
        if(exportInProgress != null && exportInProgress){
            throw new AuraHandledException('An export is already in progress. Please wait for some time.');
        }
        
        try {
            orgPart.put('exportInProgress', true);
            BulkPaymentWrapper bulkWrapper = (BulkPaymentWrapper) JSON.deserialize(bulkJson, BulkPaymentWrapper.CLASS);
            List<String> bulkRecordIds = new List<String>();
            BulkPaymentRequest__c bulkPaymentRecord = createBulkPayment();
            BulkPaymentExportQueueable bulkPay = new BulkPaymentExportQueueable(bulkWrapper.paymentReqIds, bulkPaymentRecord, bulkWrapper.csvBlob);
            AsyncApexFramework.submitQueueable(bulkPay,99);
            AsyncApexFramework.flush();
            orgPart.put('exportInProgress', true);
            return bulkPaymentRecord.Id;
        } catch (Exception e) {
            orgPart.put('exportInProgress', false);
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description      Method creates bulk payment request record
     * @author           Aman Agarwal    
     * @return           BulkPaymentRequest__c : bulk payment request object  
    **/
    public static BulkPaymentRequest__c createBulkPayment () {

        String todayDate = Datetime.now().format('dd-MM-yyyy');
        String todayDateLikeString = todayDate + '%';
        ExportViewerWrapper wrap = new ExportViewerWrapper();
        List<BulkPaymentRequest__c> lastBulkPaymentRecord = wrap.getBulkPaymentRequest(todayDateLikeString);
        String newFileName;
        if (lastBulkPaymentRecord.isEmpty()) {
            newFileName = todayDate + '_' + 'AA.CSV';
        } else {
            newFileName = todayDate + '_' + getNextTwoDigitString(lastBulkPaymentRecord[0].Name.substringBetween('_','.')) + '.CSV';
        }

        BulkPaymentRequest__c newBulkPayment = new BulkPaymentRequest__c();
        newBulkPayment.Name = newFileName;
        newBulkPayment.ExportStartedAt__c = System.now();
        newBulkPayment.Status__c = 'Export Pending';
        insert newBulkPayment;
        
        return newBulkPayment;
    }

    /**
     * @description      Method to format the file name
     * @author           Aman Agarwal    
     * @return           string - next two strings needed for file name    
    **/
    public static String getNextTwoDigitString(String oldLetterCombo) {
        String key = 'ABCDEFGHIJKLMNOPQRSTUVWXYZAabcdefghijklmnopqrstuvwxyza';
        String firstLetter = oldLetterCombo.substring(0,1);
        String secondLetter = oldLetterCombo.substring(1,2);
        Integer secondLetterIndex = key.indexOfChar(oldLetterCombo.charAt(1));

        String newSecondLetter = secondLetterIndex == -1? null: key.substring(secondLetterIndex+1, secondLetterIndex+2);
        if(secondLetter == 'Z' || secondLetter == 'z'){
            Integer firstLetterIndex = key.indexOfChar(oldLetterCombo.charAt(0));
            firstLetter = firstLetterIndex == -1? null: key.substring(firstLetterIndex+1, firstLetterIndex+2);
        }
        return firstLetter+newSecondLetter;
    }

    public class BulkPaymentWrapper {
        @AuraEnabled public String csvBlob {get;set;}
        @AuraEnabled public List<Id> paymentReqIds {get;set;}
    }

    public without sharing class ExportViewerWrapper {
        public List<BulkPaymentRequest__c> getBulkPaymentRequest(String todayDateLikeString) {
            List<BulkPaymentRequest__c> lastBulkPaymentRecord = [SELECT Id, Name FROM BulkPaymentRequest__c WHERE Name LIKE :todayDateLikeString ORDER BY createdDate DESC LIMIT 1];
            return lastBulkPaymentRecord;
        }
    }
}