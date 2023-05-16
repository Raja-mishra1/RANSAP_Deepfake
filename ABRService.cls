public without sharing class ABRService {

    private static final String CALLBACK_NAME = 'removeme';

    //TTP-1502 start
    public static final String ABN_ENDPOINT = ABN_API_Configuration__mdt.getInstance('ABN_API').Endpoint_URL__c;
    public static final Integer NAME_SEARCH_SCORE = Integer.valueof(ABN_API_Configuration__mdt.getInstance('ABN_API').Name_Search_Score__c); 
    public static final string GUID = ABN_API_Configuration__mdt.getInstance('ABN_API').GUID__c;
    public static final Integer ABN_BATCH_SCOPE_SIZE = Integer.valueOf(ABN_API_Configuration__mdt.getInstance('ABN_API').Batch_Scope_Size__c);
    public static final String NAME_SEARCH_ENDPOINT_URL = ABN_API_Configuration__mdt.getInstance('ABN_API').Name_Search_Endpoint_URL__c;    //Added By Nishant Singh NAP5-319
    //TTP-1502 End

    public class ABNLookupResponse {
        @AuraEnabled public String Abn;
        @AuraEnabled public String AbnStatus;
        @AuraEnabled public String Acn;
        @AuraEnabled public Date AddressDate;
        @AuraEnabled public String AddressPostcode;
        @AuraEnabled public String AddressState;
        @AuraEnabled public List<String> BusinessName;
        @AuraEnabled public String EntityName;
        @AuraEnabled public String EntityTypeCode;
        @AuraEnabled public String EntityTypeName;
        @AuraEnabled public Date Gst;
        @AuraEnabled public String Message;
    }

    public class NameLookupResponse{
        public String Message;	//
        public NameWrapper[] Names;
    }

    public class NameWrapper {
        public String Abn;
        public String Name;	
        public String NameType;
        public Integer Score;		
    }

    @AuraEnabled
    public static ABNLookupResponse ABNLookup(String ABN) {
        Http http = new Http();

        HttpRequest httpRequest = new HttpRequest();
		
        httpRequest.setEndpoint(ABN_ENDPOINT + ABN + GUID + CALLBACK_NAME);
        httpRequest.setMethod('GET');
		
        HttpResponse httpResponse = http.send(httpRequest);
        String requestBody = httpResponse.getBody();
        requestBody = requestBody.removeStart(CALLBACK_NAME + '(').removeEnd(')');

        return (ABNLookupResponse) JSON.deserialize(requestBody, ABNLookupResponse.class);
    }

    @AuraEnabled
    public static NameLookupResponse NameLookup(String Name) {
        Http http = new Http();

        HttpRequest httpRequest = new HttpRequest();
		
        String accountName = EncodingUtil.urlEncode(Name, 'UTF-8');

        httpRequest.setEndpoint(NAME_SEARCH_ENDPOINT_URL + accountName + GUID + CALLBACK_NAME);
        httpRequest.setMethod('GET');

        HttpResponse httpResponse = http.send(httpRequest);
        String requestBody = httpResponse.getBody();
        requestBody = requestBody.removeStart(CALLBACK_NAME + '(').removeEnd(')');
        
        return (NameLookupResponse) JSON.deserialize(requestBody, NameLookupResponse.class);
    }
}