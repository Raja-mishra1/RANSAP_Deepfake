/**
 * @description  [T2P-145] Apex Rest Service for SF Document API
 * @company      Cloudwerx
 * @date         14/06/2021
**/

@RestResource(urlmapping='/sf-document/*')
global inherited sharing class DocumentRestService {
    public static Boolean IsDMLException = false;

    /**
     * @description @HttpPost exposes the method to POST request when this API is called.It is a sync 
     *              webservice which get the payload out & searlize to check if there is any serialization 
     *              issues. If no error is found 200 is returned else error code is returned.
    **/
    @HttpPost
    global static void handleHttpPost() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        Savepoint sp = Database.setSavepoint();
        try {
            DocumentDTO parsedDocumentData = DocumentDTO.parse(request.requestBody.toString());
            String missingValues = validateRequiredFields(parsedDocumentData); // [TTP-1879]
            if(missingValues!= '') {
                throw new MissingDataException(missingValues);
            }
            String invalidValue = validateParsedData(parsedDocumentData);
            if(invalidValue!= '') {
                throw new InvalidResponseDataException(invalidValue);
            }
            Case masterCase = masterCaseValidation(parsedDocumentData.masterCaseId);
            RestResponse res = DocumentPostProcessing.execute(parsedDocumentData,masterCase,request);
            response.statusCode = res.statusCode;
            response.responseBody =  res.responseBody;
        } catch(MissingDataException ex) {
            response.statusCode = 400;
            response.responseBody =  Blob.valueOf('[{ "errorCode": "VALIDATION_EXCEPTION", "error": "Bad Request: missing data found for required fields", "message": "' + ex.getMessage()  + '" }]'); 
        } catch(InvalidResponseDataException ex) {
            response.statusCode = 400;
            response.responseBody =  Blob.valueOf('[{ "errorCode": "VALIDATION_EXCEPTION", "error": "Bad Request: invalid data found", "message": "' + ex.getMessage()  + '" }]'); 
        } catch (JSONException jex) {
            // to catch parsing error 
            response.statusCode = 400;
            response.responseBody =  Blob.valueOf('[{ "errorCode": "JSON_EXCEPTION", "error": "Bad Request: Invalid request or content" , "message": "' + jex.getMessage()  + '" }]');      
        } catch (QueryException qex) {
            // to catch query exception error 
            response.statusCode = 400;
            response.responseBody =  Blob.valueOf('[{ "errorCode": "QUERY_EXCEPTION", "error" : "Master case was not found", "message": "' + qex.getMessage()  + '" }]');
        } catch (DMLException e) {
            System.debug('Error executing the job: ' + e.getMessage() + ':Line Number '+e.getLineNumber());
            IsDMLException = true; //[TTP-1879]
            response.statusCode = 500;
            response.responseBody =  Blob.valueOf('[{ "errorCode": "UnexpectedException", "message": "' + e.getMessage()+ '" }]');
            Database.rollback(sp);            
        } finally {
            EventLog__e evt = LogService.logRestRequestAndResponse ( 
                'DocumentRestService','handleHttpPost','This is document api', request,response
            );
            LogService.insertLog(new List<EventLog__e>{ evt });
            if (IsDMLException) { //[TTP-1879]
                // Return Generic Exception Messsage
                response.responseBody = Blob.valueOf('[{ "errorCode": "UnexpectedException", "message": "' + System.Label.DocumentPostProcessingExceptionMessage  + '" }]');
            }
        }
    }

    public class MissingDataException extends Exception {}
    public class InvalidResponseDataException extends Exception {}

    /**
     * @description         Get master case record based on masterCaseId 
     * @author              Sonali Takke
     * @param               masterCase : Master case record
     * @return			    Case record
    **/
    public static Case masterCaseValidation(String masterCaseId) {
        // 1. Verify if master case Id exist in backend
        Case masterCase = [SELECT Id, Subject, Origin, PlanManager__c, Client__r.PlanManager__c 
                          FROM Case WHERE Id =: masterCaseId];
        return masterCase;
    }

    /**
     * @description         Validate response data 
     * @author              Sonali Bhat
     * @param               parsedDocumentData : Parsed document API response
     * @return			    Error message 
    **/
    public static string validateParsedData(DocumentDTO parsedDocumentData) {
        String errorMsg = '';
        String dateRegex = '^((19|20)[0-9]{2})-(0?[1-9]|1[012])-(0?[1-9]|[12][0-9]|3[01])$';   // date Regex

        // document type check
        if (parsedDocumentData.documentType!= null 
            && parsedDocumentData.documentType!= '' 
            && (!System.Label.NonInvoiceDocumentTypes.contains(parsedDocumentData.documentType.toLowerCase()))
            && (!System.Label.Invoice.contains(parsedDocumentData.documentType.toLowerCase()))) {
                errorMsg = DocumentAPIConstant.DOCUMENT_TYPE_ERROR + ', ';
        }

        // participant no check
        if ((parsedDocumentData.participantNo != '' && parsedDocumentData.participantNo != null) 
            &&  ((!parsedDocumentData.participantNo.startsWith('43')) 
            ||  (!parsedDocumentData.participantNo.isNumeric()) 
            ||  parsedDocumentData.participantNo.length() !=9)) {
                    errorMsg += DocumentAPIConstant.PARTICIPANT_NO_ERROR +', ';
        }

        // supplier no check
        if ((parsedDocumentData.supplierABN != null && parsedDocumentData.supplierABN != '') 
            && ((!parsedDocumentData.supplierABN.isNumeric()
            || parsedDocumentData.supplierABN.length() !=11))) {
                    errorMsg += DocumentAPIConstant.SUPPLIER_NO_ERROR +', ';
        }

        // Invoice Details - reference no check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.referenceNo != ''
            && parsedDocumentData.invoiceDetails.referenceNo != null) {
                if (parsedDocumentData.invoiceDetails.referenceNo.length() >50) {
                    errorMsg += DocumentAPIConstant.INV_REF_ERROR+', ';
                }
        }

        // Invoice Details - support start date check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.supportStartDate != null) {           
                pattern myPattern = pattern.compile(dateRegex); 
                matcher myMatcher = myPattern.matcher(string.valueOf(parsedDocumentData.invoiceDetails.supportStartDate));
                Boolean result = myMatcher.matches();
                if (!result) {
                    errorMsg += DocumentAPIConstant.INV_SUPPORT_STARTDATE_ERROR+', ';
                }
        }

        // Invoice Details - support end date check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.supportEndDate != null) {              
                pattern myPattern = pattern.compile(dateRegex); 
                matcher myMatcher = myPattern.matcher(string.valueOf(parsedDocumentData.invoiceDetails.supportEndDate));
                Boolean result = myMatcher.matches();
                if (!result) {
                    errorMsg += DocumentAPIConstant.INV_SUPPORT_ENDDATE_ERROR+', ';
                }
        }

        // Invoice Details - total check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.total != null
            && parsedDocumentData.invoiceDetails.total <=0) {
                errorMsg += DocumentAPIConstant.INV_TOTAL_ERROR +', ';
        }

        // Invoice Details - gst check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.gst != null
            && parsedDocumentData.invoiceDetails.gst <0) {
                errorMsg += DocumentAPIConstant.INV_GST_ERROR +', ';
        }

        // Invoice Details - outstanding amount check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.outstandingAmount != null
            && parsedDocumentData.invoiceDetails.outstandingAmount <0) {
                errorMsg += DocumentAPIConstant.INV_OUTSTANDING_AMOUNT_ERROR +', ';
        }

        // Payment Details - account no check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.paymentDetails != null
            && parsedDocumentData.invoiceDetails.paymentDetails.accountNo != null
            && parsedDocumentData.invoiceDetails.paymentDetails.accountNo != ''
            ) {
                String accRegex = '^(?! )[0-9 ]*(?<! )$';
                pattern myPattern = pattern.compile(accRegex); 
                matcher myMatcher = myPattern.matcher(parsedDocumentData.invoiceDetails.paymentDetails.accountNo);
                Boolean result = myMatcher.matches();
                if (!result)
                errorMsg += DocumentAPIConstant.PAY_ACC_NO_ERROR + ', ';
        }

        // Payment Details - bsb no check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.paymentDetails != null
            && parsedDocumentData.invoiceDetails.paymentDetails.bsb != null
            && parsedDocumentData.invoiceDetails.paymentDetails.bsb != ''
            ) {
                String bsbRegex = '^[0-9]{3}-[0-9]{3}$';
                pattern myPattern = pattern.compile(bsbRegex); 
                matcher myMatcher = myPattern.matcher(parsedDocumentData.invoiceDetails.paymentDetails.bsb);
                Boolean result = myMatcher.matches();
                if (!result)
                errorMsg += DocumentAPIConstant.PAY_BSB_ERROR + ', ';
        }

        // Payment Details - biler code check
        if (parsedDocumentData.invoiceDetails != null && parsedDocumentData.invoiceDetails.paymentDetails != null) {
            String billerCode = parsedDocumentData.invoiceDetails.paymentDetails.billerCode;
            if ((billerCode != '' && billerCode != null) && ((!billerCode.isNumeric()) || (billerCode.length() != 6))) {
                errorMsg += DocumentAPIConstant.PAY_BILLER_CODE_ERROR + ', ';
            }
        }

        // Payment Details - reference check
        if (parsedDocumentData.invoiceDetails != null 
            && parsedDocumentData.invoiceDetails.paymentDetails != null
            && parsedDocumentData.invoiceDetails.paymentDetails.reference != null
            && parsedDocumentData.invoiceDetails.paymentDetails.reference != ''
            && (!parsedDocumentData.invoiceDetails.paymentDetails.reference.isNumeric() 
                || parsedDocumentData.invoiceDetails.paymentDetails.reference.length() < 2
                || parsedDocumentData.invoiceDetails.paymentDetails.reference.length() > 20)) {
                errorMsg += DocumentAPIConstant.PAY_REF_ERROR + ', ';
        }

        // Line Item Check
        if (parsedDocumentData.invoiceDetails != null && parsedDocumentData.invoiceDetails.LineItems != null) {
            for (integer i = 0; i< parsedDocumentData.invoiceDetails.LineItems.size(); i++) {
                integer j =i+1;

                // support item no check
                if (parsedDocumentData.invoiceDetails.LineItems[i].supportItemNo != null 
                    && parsedDocumentData.invoiceDetails.LineItems[i].supportItemNo != '') {
                        String supportItemRegex = '^[a-zA-Z0-9_]*$';
                        pattern myPattern = pattern.compile(supportItemRegex); 
                        matcher myMatcher = myPattern.matcher(parsedDocumentData.invoiceDetails.LineItems[i].supportItemNo);
                        Boolean result = myMatcher.matches();
                        if (!result || parsedDocumentData.invoiceDetails.LineItems[i].supportItemNo.length() >60) {
                            errorMsg += DocumentAPIConstant.INVLINE_SUPPORTITEM_ERROR.replace('[LINE HOLDER]','['+j+']') + ', ';
                        }
                }

                // service start date check
                if (parsedDocumentData.invoiceDetails.LineItems[i].serviceStartDate != null) {
                        pattern myPattern = pattern.compile(dateRegex); 
                        matcher myMatcher = myPattern.matcher(string.valueOf(parsedDocumentData.invoiceDetails.LineItems[i].serviceStartDate));
                        Boolean result = myMatcher.matches();
                        if (!result) {
                            errorMsg += DocumentAPIConstant.INVLINE_SERVICE_STARTDATE_ERROR.replace('[LINE HOLDER]','['+j+']')+ ', ';
                        }
                }

                // service end date check
                if (parsedDocumentData.invoiceDetails.LineItems[i].serviceEndDate != null) {
                    pattern myPattern = pattern.compile(dateRegex); 
                    matcher myMatcher = myPattern.matcher(string.valueOf(parsedDocumentData.invoiceDetails.LineItems[i].serviceEndDate));
                    Boolean result = myMatcher.matches();
                    if (!result) {
                        errorMsg += DocumentAPIConstant.INVLINE_SERVICE_ENDDATE_ERROR.replace('[LINE HOLDER]','['+j+']')+ ', ';
                    }
                }

                // quantity check
                if (parsedDocumentData.invoiceDetails.LineItems[i].quantity!= null 
                    && parsedDocumentData.invoiceDetails.LineItems[i].quantity < 0) {
                        errorMsg += DocumentAPIConstant.INVLINE_QTY_ERROR+'['+j+']' + ', ';
                }

                // unit of measure check
                if (parsedDocumentData.invoiceDetails.LineItems[i].unitOfMeasure != null 
                    && parsedDocumentData.invoiceDetails.LineItems[i].unitOfMeasure != ''
                    && !System.Label.DOCAPI_UOM.contains(parsedDocumentData.invoiceDetails.LineItems[i].unitOfMeasure.toLowerCase())) {
                        errorMsg += DocumentAPIConstant.INVLINE_UOM_ERROR+'['+j+']'+ ', ';
                }

                // rate check
                if (parsedDocumentData.invoiceDetails.LineItems[i].rate!= null
                    && parsedDocumentData.invoiceDetails.LineItems[i].rate < 0) {
                        errorMsg += DocumentAPIConstant.INVLINE_RATE_ERROR+'['+j+']' + ', ';
                }

                // gst check
                if (parsedDocumentData.invoiceDetails.LineItems[i].gst != null
                   && parsedDocumentData.invoiceDetails.LineItems[i].gst < 0) {
                        errorMsg += DocumentAPIConstant.INVLINE_GST_ERROR+'['+j+']' + ', ';
                }

                // total check
                if (parsedDocumentData.invoiceDetails.LineItems[i].total!= null
                    && parsedDocumentData.invoiceDetails.LineItems[i].total <= 0) {
                        errorMsg += DocumentAPIConstant.INVLINE_TOTAL_ERROR+'['+j+']' + ', ';
                }

                // hours check [AHOD-4], [AHOD-555]
                if (parsedDocumentData.invoiceDetails.LineItems[i].hours!= null) {
                    Boolean result = TTPUtil.validateHoursOnLineItem(parsedDocumentData.invoiceDetails.LineItems[i].hours);
                    if (!result)
                        errorMsg += DocumentAPIConstant.INVLINE_HOURS_ERROR.replace('[LINE HOLDER]','['+j+']')+ ', ';
                    else {
                        String hours, minutes;
                        Decimal computedQuantity;
                        hours = parsedDocumentData.invoiceDetails.LineItems[i].hours.substringBefore(':') != '' 
                            ? parsedDocumentData.invoiceDetails.LineItems[i].hours.substringBefore(':')
                            : '0' ;
                        minutes = parsedDocumentData.invoiceDetails.LineItems[i].hours.substringAfter(':');
                        computedQuantity = (Decimal.valueOf(Integer.valueOf(hours)*60 + Integer.valueOf(minutes))/Decimal.valueOf(60));
                        if(computedQuantity == 0 
                            && (parsedDocumentData.invoiceDetails.LineItems[i].quantity == 0
                                || parsedDocumentData.invoiceDetails.LineItems[i].quantity == null)) {
                            errorMsg += DocumentAPIConstant.INVLINE_QTY_HOURS_ERROR.replace('[LINE HOLDER]','['+j+']')+ ', ';
                        }
                    }                       
                }

                if (parsedDocumentData.invoiceDetails.LineItems[i].hours == null
                    && parsedDocumentData.invoiceDetails.LineItems[i].quantity == 0
                    ) {
                        errorMsg += DocumentAPIConstant.INVLINE_QTY_HOURS_ERROR.replace('[LINE HOLDER]','['+j+']')+ ', ';
                }
            }
        }
        if (errorMsg != '') {
            errorMsg = errorMsg.trim();
            errorMsg = errorMsg.removeEnd(','); 
        }
        return errorMsg;
    }
    
    /**
     * @description         Validation of non nullable fields to be checked against the payload
     * @author              Sonali Bhat
     * @param               parsedDocumentData : Parsed document API response
     * @return			    missingFieldValues misssing field names 
    **/
    public static string validateRequiredFields( DocumentDTO parsedDocumentData) {
        /* Values to be compared - 
            ['masterCaseId','fileId','fileName','documentLink','responseLink','documentType','lineItems.description',
            'invoiceDetails.supportStartDate','invoiceDetails.supportEndDate','invoiceDetails.total','lineItems.serviceStartDate',
            'lineItems.serviceEndDate','lineItems.quantity','lineItems.total'] 
        */
        String missingFieldValues = '';
        if (parsedDocumentData.masterCaseId == null || parsedDocumentData.masterCaseId == '' ) {
            missingFieldValues = 'masterCaseId' + ', ';
        }
        if (parsedDocumentData.fileId == null || parsedDocumentData.fileId == '' ) {
            missingFieldValues += 'fileId' + ', ' ;
        }
        if (parsedDocumentData.fileName == null || parsedDocumentData.fileName == '' ) {
            missingFieldValues += 'fileName' + ', ';
        }
        if (parsedDocumentData.documentLink == null || parsedDocumentData.documentLink == '' ) {
            missingFieldValues += 'documentLink' + ', ';
        }
        if (parsedDocumentData.responseLink == null || parsedDocumentData.responseLink == '' ) {
            missingFieldValues += 'responseLink' + ', ';
        }
        if (parsedDocumentData.documentType == null || parsedDocumentData.documentType == '' ) {
            missingFieldValues += 'documentType' + ', ';
        }

        // Invoice Field Validations
        if (parsedDocumentData.invoiceDetails != null) {
            if (parsedDocumentData.invoiceDetails.supportStartDate == null) {
                missingFieldValues += 'invoiceDetails.supportStartDate' + ', ';
            }
            if (parsedDocumentData.invoiceDetails.supportEndDate == null) {
                missingFieldValues += 'invoiceDetails.supportEndDate' + ', ' ;
            } 
            if (parsedDocumentData.invoiceDetails.total == null) {
                missingFieldValues += 'invoiceDetails.total' + ', ';
            }

            // Invoice Line Item field Validations
            if (parsedDocumentData.invoiceDetails.LineItems != null) {
                for (integer i = 0; i< parsedDocumentData.invoiceDetails.LineItems.size(); i++) {
                    integer j = i+1;
                    if (parsedDocumentData.invoiceDetails.LineItems[i].serviceStartDate == null) {
                        missingFieldValues += 'LineItem'+'['+j+']' +'-> '+ 'serviceStartDate' + ', ';
                    }
                    if (parsedDocumentData.invoiceDetails.LineItems[i].serviceEndDate == null) {
                        missingFieldValues += 'LineItem'+'['+j+']' +'-> '+ 'serviceEndDate' + ', ';
                    }
                    if (parsedDocumentData.invoiceDetails.LineItems[i].total == null) {
                        missingFieldValues += 'LineItem'+'['+j+']' +'-> '+ 'total' + ', ';
                    }
                    //[AHOD-4], [AHOD-555]
                    if (parsedDocumentData.invoiceDetails.LineItems[i].quantity == null 
                        && parsedDocumentData.invoiceDetails.LineItems[i].hours == null) {
                        missingFieldValues += 'LineItem'+'['+j+']' +'-> '+ 'quantity or hours' + ', ';
                    }
                }
            }
        }
        if (missingFieldValues != '') {
            missingFieldValues = missingFieldValues.trim();
            missingFieldValues = missingFieldValues.removeEnd(','); 
        }
        return missingFieldValues;
    }
}