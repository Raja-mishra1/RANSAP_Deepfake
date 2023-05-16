public class EmailMessageTriggerHandler {
    private static final String REPLY_TO_HEADER = 'REPLY-TO';
    private static final String RETURN_PATH = 'RETURN-PATH';
    private static final String ACCOUNT_EMAIL_ID = System.label.EmailId_Account; 
    private static final String ENQUIRY_EMAIL_ID = System.label.EmailId_Enquiry; 

    public static void addUniqueStringToInboundEmail(List<EmailMessage> newIncomingEmails) {
        for (EmailMessage emailMessage : newIncomingEmails) {
            if (emailMessage.Incoming) {
                emailMessage.TextBody = '[' + DateTime.now() + '_' + DateTime.now().format('SSS') + '_' + Crypto.getRandomLong() + ']\n\n' + emailMessage.TextBody;
            }
        }        
    }

    public static void updateWebEmailToValidEmail(List<EmailMessage> triggerNewList) {
        List<Case> caseToUpdateList = new List<Case>();
        Map<String, EmailMessage> emailMessageByParentIdMap = new Map<String, EmailMessage>();
        for (EmailMessage e : [
            SELECT Id, Headers, ParentId, Parent.SuppliedEmail,
                   Parent.Auto_Response_Flag__c , Parent.Status, Parent.Origin
            FROM EmailMessage
            WHERE Id IN :triggerNewList
                AND Incoming = true

        ]) {
            if (String.isNotBlank(e.ParentId) && e.Parent.Auto_Response_Flag__c == false && e.Parent.Status == 'New' && e.Parent.Origin == 'Email') {
                emailMessageByParentIdMap.put(e.ParentId, e);
            }
        }
        System.debug('***InboundEmailMessageTriggerHandler after Insert: emailMessageList > ' + emailMessageByParentIdMap);
        if (!emailMessageByParentIdMap.isEmpty()) {
            for (EmailMessage ie : emailMessageByParentIdMap.values()) {
                    Map<String, String> headersMap = getEmailMessageHeadersMap(ie, REPLY_TO_HEADER);
                    if ((headersMap.containsKey(REPLY_TO_HEADER) && String.isNotBlank(headersMap.get(REPLY_TO_HEADER))) && ie.Parent.SuppliedEmail != getMailFromReplyToHeaderValue(headersMap.get(REPLY_TO_HEADER))) {
                        caseToUpdateList.add(
                            new Case(
                                Id = ie.ParentId,
                                SuppliedEmail = getMailFromReplyToHeaderValue(headersMap.get(REPLY_TO_HEADER)),
                                Auto_Response_Flag__c = true,
                                Sender__c = ie.Parent.SuppliedEmail
                            )
                        );
                    } else {
                        caseToUpdateList.add(
                            new Case(
                                Id = ie.ParentId,
                                Auto_Response_Flag__c = true
                            )
                        );
                    }
                }
        }
        update caseToUpdateList;

    }
    private static String getMailFromReplyToHeaderValue(String replyToHeaderValue) {
        if (replyToHeaderValue.contains('<')) {
            replyToHeaderValue = replyToHeaderValue.substringBetween('<', '>');
            //START://OPSNBOTS-180
            replyToHeaderValue = validateReplyToEmail(replyToHeaderValue);
            //END: //OPSNBOTS-180
        }
        replyToHeaderValue = validateReplyToEmail(replyToHeaderValue);
        return replyToHeaderValue;
        
        
    }
     /**
     * @description      Method to validate Email id before updating on Case OPSNBOTS-180
     * @author           Harshad Dani   
     * @return           Email Id       
    **/
    private static String validateReplyToEmail(String replyToHeaderValue){
        if(replyToHeaderValue.length()<=80) { 
            String emailRegex='^[a-z0-9!#$%&’*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#$%&’*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$'; 
            Pattern EmailPattern = Pattern.compile(emailRegex);
            Matcher EmailMatcher = EmailPattern.matcher(replyToHeaderValue);
            if(EmailMatcher.matches()){
                return replyToHeaderValue.trim();
            }else{
                return null;
            }
        }else{
            return null;
        }
    }

    public static Map<String, String> getEmailMessageHeadersMap(EmailMessage emsg, String emailHeaderProperty) {
        Map<String, String> mapHeaders = new Map<String, String>();
        if (eMsg != null && String.isNotBlank(emsg.Headers)) {
            List<String> lstHeaders = emsg.Headers.escapeCsv().split('\n');
            List<String> lstHeadersAndVal = new List<String>();
            for (String h : lstHeaders) {
                lstHeadersAndVal = h.split(':', 2);
                if (lstHeadersAndVal.size() == 2 && String.isNotBlank(lstHeadersAndVal[1])) {
                    if(lstHeadersAndVal[0].contains('\"')){
                        lstHeadersAndVal[0]=lstHeadersAndVal[0].replaceAll('\"','');
                    }
                    mapHeaders.put(lstHeadersAndVal[0].toUpperCase(), lstHeadersAndVal[1].trim());
                }
            }

        }
        return mapHeaders;
    }
    /**
     * @description      Method to validate Duplicate Email id on multiple mail boxes OPSNBOTS-180
     * @author           Harshad Dani   
     * @return           void       
    **/
    public static void validateDuplicateEmailReceiptviaMultipleMailboxes(List<EmailMessage> newIncomingEmails) {
        for (EmailMessage emailMessage : newIncomingEmails) {
            Map<String, String> headersMap = getEmailMessageHeadersMap(emailMessage, REPLY_TO_HEADER);         
            if (emailMessage.Incoming) {              
               if(headersMap.containsKey(RETURN_PATH) 
                && ((headersMap.get(RETURN_PATH).trim().equals(ACCOUNT_EMAIL_ID)  
                        && ( (emailMessage.ToAddress!=null && emailMessage.ToAddress.contains(ENQUIRY_EMAIL_ID))  
                            || (emailMessage.CcAddress!=null && emailMessage.CcAddress.contains(ENQUIRY_EMAIL_ID))  
                            || (emailMessage.BccAddress!=null && emailMessage.BccAddress.contains(ENQUIRY_EMAIL_ID)) 
                            ) 
                        && emailMessage.HasAttachment==false)
                    ||
                    (headersMap.get(RETURN_PATH).trim().equals(ENQUIRY_EMAIL_ID)  
                        && ( (emailMessage.ToAddress!=null && emailMessage.ToAddress.contains(ACCOUNT_EMAIL_ID))  
                            || (emailMessage.CcAddress!=null && emailMessage.CcAddress.contains(ACCOUNT_EMAIL_ID))  
                            || (emailMessage.BccAddress!=null && emailMessage.BccAddress.contains(ACCOUNT_EMAIL_ID)) 
                            ) 
                        && emailMessage.HasAttachment==true)
                    )

                ){
                    emailMessage.addError('Email received at both '+ACCOUNT_EMAIL_ID+' and '+ ENQUIRY_EMAIL_ID);
               }

            }
        }
    }
}