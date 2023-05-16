public without sharing class RecordTypeUtil {

    public static final String CLIENT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
    public static final String RESTRICTED_CLIENT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Restricted Client').getRecordTypeId();
    public static final String PROVIDER_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Provider').getRecordTypeId();
    public static final String COMPANY_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
    public static final String PROSPECT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
    public static final String REIMBURSEMENT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Reimbursement').getRecordTypeId();
    
    public static final String GENERAL_CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId();
    public static final String COMPLAINT_L2_CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaints Level 2').getRecordTypeId();
    public static final String COMPLAINT_L3_CASE_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Complaints Level 3').getRecordTypeId();
    public static final String REPORTABLE_INCIDENT_RECORD_TYPE_ID = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Reportable Incident').getRecordTypeId();

    public static final String NPS_SURVEY_RECORD_TYPE_ID = Schema.SObjectType.Survey_Response__c.getRecordTypeInfosByName().get('NPS').getRecordTypeId();
	public static final String CSAT_SURVEY_RECORD_TYPE_ID = Schema.SObjectType.Survey_Response__c.getRecordTypeInfosByName().get('CSAT').getRecordTypeId();

    public static final String PSP_SUBSTITUTION_RECORD_TYPE_ID = Schema.SObjectType.PlanSupportPreference__c.getRecordTypeInfosByName().get('Claim As').getRecordTypeId();
    public static final String PSP_RESERVED_BUDGET_RECORD_TYPE_ID = Schema.SObjectType.PlanSupportPreference__c.getRecordTypeInfosByName().get('Locked Budget').getRecordTypeId();

}