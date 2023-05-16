/**
 * @description  Class to maintain the static constants used across invoice orchestrator
 * @company      Cloudwerx
 * @date         15/07/2021
**/
public without sharing class InvoiceRuleConstant {

    /****************************RULE RESULT CONSTANT******************************************** */
    public static String DAYS_OF_SERVICE_MAXIMUM_CHECK_PASS = System.Label.IR_DaysofServiceMaximumCheckPass; //PA-20
    public static String DAYS_OF_SERVICE_MAXIMUM_CHECK_FAIL = System.Label.IR_DaysofServiceMaximumCheckFail; //PA-20
    public static String DAYS_OF_SERVICE_MAXIMUM_CHECK_NOT_APPLICABLE = System.Label.IR_DaysofServiceMaximumCheckNotApplicable; //PA-20
    public static String DATE_OF_SERVICE_CHECK_FAIL = System.Label.IR_DateofServiceCheckFail; //PA-15
    public static String DATE_OF_SERVICE_CHECK_PASS = System.Label.IR_DateofServiceCheckPass; //PA-15
    public static String DATE_OF_SERVICE_CHECK_NOT_APPLICABLE = System.Label.IR_DateofServiceCheckNotApplicable; //PA-15
    public static String PROVIDER_IN_PROSPECT_STATUS = System.Label.IR_ProviderProspectStatus;
    public static String PROVIDER_NOT_FOUND = System.Label.IR_ProviderNotFound;
    public static String PROVIDER_IDENTIFIED = System.Label.IR_ProviderIdentified;
    public static String ACCOUNT_PROSPECT_RT_NAME = System.Label.AccountRT_Prospect;
    public static String SINGLE_PLAN_IDENTIFIED = System.Label.IR_SinglePlanIdentified;
    public static String NO_PLAN_IDENTIFIED = System.Label.IR_NoPlanIdentified;
    public static String MULTIPLE_PLAN_IDENTIFIED = System.Label.IR_MultiplePlanIdentified;
    public static String BANK_DETAILS_PRESENT = System.Label.IR_BankDetailsPresent;
    public static String BANK_DETAILS_NOT_PRESENT = System.Label.IR_BankDetailsNotPresent;
    public static String PAYMENT_METHOD_DETAILS_PRESENT = System.Label.IR_PaymentMethodDetailsPresent;
    public static String PAYMENT_METHOD_DETAILS_NOT_PRESENT = System.Label.IR_PaymentMethodDetailsNotPresent;
    public static String CLIENT_NOT_FOUND = System.Label.IR_ClientNotFound;
    public static String CLIENT_IDENTIFIED = System.Label.IR_ClientIdentified;
    public static String ACCOUNT_STATUS_ARCHIVED_ONHOLD = System.Label.IR_Account_Archived_Onhold;
    public static String SUPPORT_ITEM_FOUND = System.Label.IR_SupportItemFound;
    public static String SUPPORT_ITEM_NOT_FOUND = System.Label.IR_SupportItemNotFound;
    public static String RELATIONSHIPS_CLIENT_ACTIVE_PROVIDER  = System.Label.IR_RelationshipsClientActiveProvider;
    public static String RELATIONSHIPS_CLIENT_BLOCKED_PROVIDER = System.Label.IR_RelationshipsClientBlockedProvider;
    public static String PLAN_SUPPORTS_NOT_IDENTIFIED = System.Label.IR_PlanSupportMismatch;
    public static String PLAN_SUPPORT_IDENTIFIED = System.Label.IR_PlanSupportIdentified;
    public static String PLAN_SUPPORT_CLAIMAS_NOT_CONFIGURED = System.Label.IR_NoPlanSupportAndClaimAsIdentified;
    public static String PLAN_SUPPORT_NOT_FOUND = System.Label.IR_NoPlanSupportIdentified;
    public static String ACCOUNT_STATUS_CHECK_PASS = System.Label.IR_Account_Status_Check_Pass;
    public static String ACCOUNT_STATUS_CHECK_FAIL = System.Label.IR_Account_Status_Check_Fail;
    public static String PLAN_STATUS_CHECK_FAIL = System.Label.IR_Plan_Status_Check_Fail;
    public static String PLAN_STATUS_CHECK_PASS = System.Label.IR_Plan_Status_Check_Pass;
    public static String PLAN_SUPPORT_LINE_ITEM_IDENTIFIED = System.Label.IR_PlanSupportLineItemIdentified;
    public static String PLAN_SUPPORT_LINE_ITEM_NOT_IDENTIFIED= System.Label.IR_PlanSupportLineItemNotIdentified;
    public static String PLAN_SUPPORT_LINE_ITEM_NOT_CONFIGURED = System.Label.IR_PlanSupportLineItemNotConfigured;
    public static String QUALITY_RISK_CLIENT_PROVIDER_NOT_BLOCKED = System.Label.IR_QualityRiskActiveProvider;
    public static String QUALITY_RISK_CLIENT_PROVIDER_BLOCKED = System.Label.IR_QualityRiskBlockedProvider;
    public static String IS_INTERCHANGEABLE_ITEM = System.Label.Is_Interchangeable_Item;
    public static String IS_NOT_INTERCHANGEABLE_ITEM = System.Label.Is_Not_Interchangeable_Item;
    public static String SUBSTITUTION_LINE_IDENTIFIED = System.Label.IR_Substitution_Line_Identified;
    public static String SUBSTITUTION_LINE_NOT_IDENTIFIED = System.Label.IR_Substitution_Line_Not_Identified;
    public static String SUBSTITUTION_LINE_NOT_CONFIGURED = System.Label.IR_Substitution_line_not_configured;
    public static String FUNDS_AVAILABLE_IN_RESERVED_BUDGET = System.Label.IR_FundsAvailableInReservedBudget;
    public static String INSUFFICIENT_FUNDS_IN_RESERVED_BUDGET = System.Label.IR_InsufficientFundsInReservedBudget;
    public static String MEAL_PREP_BUDGET_NOT_FOUND = System.Label.IR_MealPrepLockedBudgetNotFound;
    public static String MEAL_PREP_BUDGET_NOT_NEEDED = System.Label.IR_MealPrepLockedBudgetNotNeeded;
    public static String FUNDS_AVAILABLE_IN_PLAN_SUPPORT_ITEM = System.Label.IR_FundsAvailableInPlanSupportItem;
    public static String INSUFFICIENT_FUNDS_IN_PLAN_SUPPORT_ITEM = System.Label.IR_InsufficientFundsInPlanSupportItem;
    public static String FUNDS_AVAILABLE_IN_PLAN_SUPPORT = System.Label.IR_FundsAvailableInPlanSupport;
    public static String FUNDS_AVAILABLE_IN_SUBSTITUTION_INTERCHANGEABLE = System.Label.IR_FundsAvailableInSubstitutionInterchangeable;
    public static String INSUFFICIENT_FUNDS_IN_PLAN_SUPPORT_AS_WELL_AS_SUBSTITUTION_INTERCHANGEABLE = System.Label.IR_InsufficientFundsInPlanSupportAsWellAsSubstitutionInterchangeable;
    public static String INSUFFICIENT_FUNDS_IN_PLAN_SUPPORT_NON_INTERCHANGEABLE = System.Label.IR_InsufficientFundsInPlanSupportNonInterchangeable;
    public static String RB_PRICE_CHECK_PASS = System.Label.IR_RBPriceCheckPass;
    public static String RB_PRICE_CHECK_FAIL = System.Label.IR_RBPriceCheckFail;
    public static String SI_PRICE_CHECK_PASS = System.Label.IR_SIPriceCheckPass;
    public static String SI_PRICE_CHECK_FAIL = System.Label.IR_SIPriceCheckFail;
    public static String NOTIONAL_PRICE_PASS = System.Label.IR_NotionalPricePass;
    public static String PRICE_CHECK_NA = System.Label.IR_PriceCheckNA;
    public static String OUTSTANDING_AMOUNT_CHECK_PASS = System.Label.IR_OutstandingAmountCheckPass;
    public static String OUTSTANDING_AMOUNT_CHECK_FAIL = System.Label.IR_OutstandingAmountCheckFail;
    public static String TOTAL_AMOUNT_CHECK_FAIL = System.Label.IR_TotalAmountCheckFail;//TTP-2003
    public static String TOTAL_AMOUNT_CHECK_PASS = System.Label.IR_TotalAmountCheckPass;//TTP-2003
    public static String DUPLICATE_LINE_ITEMS_FOUND = System.Label.IR_DuplicateLineItemsFound;
    public static String DUPLICATE_LINE_ITEMS_NOT_FOUND = System.Label.IR_DuplicateLineItemsNotFound;
    public static String DUPLICATE_LINE_ITEMS_CHECK_OVERRIDDEN = System.Label.IR_DuplicateLineItemsCheckOverridden;
    public static String INVOICE_PAYMENT_METHOD_CHECK_PASS = System.Label.IR_InvoicePaymentMethodCheckPass;
    public static String INVOICE_PAYMENT_METHOD_CHECK_FAIL = System.Label.IR_InvoicePaymentMethodCheckFail;
    public static String INVOICE_PAYMENT_METHOD_CHECK_NOT_NEEDED = System.Label.IR_InvoicePaymentMethodCheckNotNeded;
    public static String Substitution_Service_Booking_Identified  = System.Label.IR_SubstitutionServiceBookingIdentified;
    public static String Multiple_Substitution_Service_Bookings_Found  = System.Label.IR_MultipleSubstitutionServiceBookingsFound;
    public static String Substitution_Service_Booking_Not_Found  = System.Label.IR_SubstitutionServiceBookingNotFound;
    public static String Service_Booking_Identified  = System.Label.IR_ServiceBookingIdentified;
    public static String Multiple_Service_Bookings_Found  = System.Label.IR_MultipleServiceBookingsFound;
    public static String Service_Booking_Not_Found  = System.Label.IR_ServiceBookingNotFound;
    public static String LOR_NOT_APPLICABLE = System.Label.IR_LORNotApplicable;
    public static String LOR_NOT_CONFIRMED = System.Label.IR_LORNotConfirmed;
    public static String LOR_CONFIRMED = System.Label.IR_LORConfirmed;
    public static String LOR_LEVEL_MSG = System.Label.IR_LORLevelMsg;
    public static String CREDIT_NOTE_FOUND = System.Label.IR_CreditNoteIdentified;
    public static String CREDIT_NOTE_NOT_FOUND = System.Label.IR_CreditNoteNotFound;
    public static String FUNDS_AVAILABLE_IN_SUBSTITUTION_PLAN_SUPPORT = System.Label.IR_FundsAvailableInSubstitutionPlanSupport;
    public static String INSUFFICIENT_FUNDS_IN_SUBSTITUTION_RESERVED_BUDGET = System.Label.IR_InsufficientFundsInSubstitutionReservedBudget;
    public static String CLIENT_APPROVAL_AVAILABLE = System.Label.IR_ClientApprovalAvailable;
    public static String CLIENT_APPROVAL_NOT_AVAILABLE = System.Label.IR_ClientApprovalNotAvailable;
    public static String CLIENT_APPROVAL_NOT_NEEDED = System.Label.IR_ClientApprovalNotNeeded;
    public static String PAYMENT_REQUEST_CREATION_FAILURE = System.Label.IR_PaymentRequestCreationFailure;
    public static String PAYMENT_REQUEST_CREATION_SUCCESS = System.Label.IR_PaymentRequestCreationSuccess;
    public static String PAYMENT_REQUEST_CREATION_NA = System.Label.IR_PaymentRequestCreationNotApplicable;
    public static String GSTCheckSuccessMsg = System.Label.IR_GSTCheckSuccessMsg; //AHOD-646
    public static String GSTCheckFailMsg = System.Label.IR_GSTCheckFailMsg;//AHOD-646
    public static String EXCLUDE_FROM_DUPLICATE_LINE_ITEM_CHECK = System.Label.IR_DuplicateInvoiceLineItems_ExcludeFromDuplicateLineItemCheck;//OPSNBOTS-99
    //TTP-2594
    public static String ONE_MATCHING_SUPPORTITEM_PRICE = System.Label.IR_OneMatchingSupportItemPrice;
    public static String NO_MATCHING_SUPPORTITEM_PRICE = System.Label.IR_NoMatchingSupportItemPrice;
    public static String INVOICE_OVER_20K = System.Label.IR_InvoiceOver20K;
    public static String INVOICE_UNDER_20K = System.Label.IR_InvoiceUnder20K;
    public static String INVOICE_OVER_20K_WITH_CONSENT = System.Label.IR_InvoiceOver20KWithConsent;
    public static String SERVICE_DATES_INVALID = System.Label.IR_ServiceDatesInvalid;
    public static String SERVICE_DATES_VALID = System.Label.IR_ServiceDatesValid;
    public static String SERVICE_DATES_IN_FUTURE = System.Label.IR_ServiceDatesInFuture;

    // TTP-3721
    public static String MANDATORY_CHECK_SUCCESS = System.Label.IR_MandatoryCheckOk;
    public static String LINE_ITEM_QTY_NOT_FOUND = System.Label.IR_QtyNotFound;
    public static String LINE_ITEMS_NOT_FOUND = System.Label.IR_LineItemsNotFound;

    //TTP-4039
    public static String DUPLICATE_INVOICELINEITEMS_PARTITION_SIZE  = System.Label.IR_DuplicateInvoiceLineItems_PartitionSize;
    public static String DUPLICATE_INVOICELINEITEMS_PARTITION_INDEX = System.Label.IR_DuplicateInvoiceLineItems_PartitionIndex;

    //TTP-4156
    public static String UNITPRICE_NOT_FOUND = System.label.IR_UnitPriceNotFound;
    public static String LINETOTAL_INVALID = System.label.IR_LineTotalInvalid;
    public static String LINETOTAL_VALID = System.label.IR_LineTotalValid;

    //AHOD-275
    public static String NEW_COREALLOCATION = System.Label.IR_NewCoreAllocation;
    public static String EXISTING_COREALLOCATION = System.Label.IR_ExistingCoreAllocation;
    public static String CLAIM_AS_FOUND = System.Label.IR_ClaimAsFound;

    //AHOD-4 (AHOD-543)
    public static String NOTIONAL_ROUNDING_APPLIED = System.Label.IR_NotionalRoundingApplied;
    public static String LINETOTALCHECK_FEED_MESSAGE = System.Label.IR_LineTotalCheck_FeedMessage;
    public static String PRICECHECK_FEED_MESSAGE = System.Label.IR_PriceCheck_FeedMessage;

    // [ACEM-153]
    public static String REFERENCE_NUMBER_NOT_FOUND = System.Label.IR_InvoiceReferenceNumberNotFound;
    // [TFR-210]
    public static String TOTAL_AMOUNT_CHECK_NOTIONAL_ROUNDING_ADJUSTMENT_PASS = System.Label.IR_TotalAmountCheckNotionalRoundingAdjustmentPass;
    public static String TOTAL_AMOUNT_CHECK_FEED_MESSAGE = System.Label.IR_TotalAmountCheckFeedMessage;

    //NAP5-351
    public static String NOTIONAL_ROUNDING_REVERTED = System.Label.IR_NotionalRoundingReverted;
    /*************************************************************************************************************/


    /**************** STATUS CONSTANTS ***************************************************************************/
    public static String STATUS_PASS    = System.Label.IR_PassStatus;
    public static String STATUS_FAIL    = System.Label.IR_FailStatus;
    public static String STATUS_READY   = System.Label.IR_ReadyStatus;
    public static String STATUS_FAILED  = System.Label.IR_FailedStatus;
    /*************************************************************************************************************/


    /**************** CONSTANTS *********************************************************************************/
    public static String IR_START = System.Label.IR_START;
    public static String IR_FINISH = System.Label.IR_FINISH;
    public static String IR_EFT = 'EFT';
    public static String IR_BPAY = 'BPAY';
    public static String ACCOUNT_LOCKED = 'Account Locked';
    public static String ORIGINAL_CASE = 'Original Case';
    public static String MASTER_CASE = 'Master Case';
    public static String SUPPORT_TYPE_CODE_ZCOR = 'ZCOR';
    public static String DOCUMENT_TYPE_FEE = 'fee';
    public static String INVOICE_FEETYPE_MONTHLY = 'Monthly';
    public static String INVOICE_FEETYPE_SETUP = 'Setup';
    public static String SUPPORTITEM_UNIT_MONTHLY = 'MON';
    //TFR-2 
    public static List<String> MONTHLY_FEE_ACCOUNT_RECORDTYPES = new List<String>{'0125K0000004IDWQA2','0125K0000004ISTQA2'};
    public static String MPM_PROVIDER_ACCOUNT_NAME = 'My Plan Manager';

    /************************************************************************************************************/

    /**************** QUEUES ************************************************************************************/

    public static String SOLUTIONS_QUEUE   = System.Label.IR_Queue_Solutions;
    public static String ACCOUNTS_QUEUE   = System.Label.IR_Queue_Accounts;
    public static String RELATIONSHIP_QUEUE   = System.Label.IR_Queue_Relationship;
    public static String FINANCE_QUEUE  = System.Label.IR_Queue_Finance;
    public static String OPERATIONS_SUPPORT  = System.Label.IR_Queue_OperationsSupport;
    public static String BUDGET_UPDATES = System.Label.IR_Queue_BudgetUpdates; // [AHOD -275]
    public static String INVOICE_LINE_ITEM_CANCELLED_STATUS =  'Cancelled,Credit Paid';
	
	//[NAPS-95 Added Queues and Custom labels]
	public static String NDSP_SOLUTIONS_QUEUE   = System.Label.IR_Queue_NDSP_Solutions;
    public static String NDSP_ACCOUNTS_QUEUE   = System.Label.IR_QUEUE_NDSP_ACCOUNTS_INVOICES;
    public static String NDSP_RELATIONSHIP_QUEUE   = System.Label.IR_Queue_NDSP_Relationships;
    public static String NDSP_BUDGET_UPDATES_QUEUE  = System.Label.IR_QUEUE_NDSP_BUDGET_UPDATES;
    public static String NDSP_OPERATIONS_SUPPORT  = System.Label.IR_Queue_NDSP_Operation_Support;
    public static String NDSP_FINANCE  = System.Label.NDSP_Finance_Queue_Id;
    /************************************************************************************************************/
    //Payment Assurance labels
    public static String CAPITAL_BUDGET_CHECK_KEYWORD_FOUND = System.Label.IR_CapitalBudgetCheckKeywordFound;
    //[PA-48]
    public static String SUPPORT_ITEM_EXCEPTION_CODE_CHECK_PASS = System.Label.IR_SupportItemExceptionCodeCheckPass;
    public static String SUPPORT_ITEM_EXCEPTION_CODE_CHECK_FAIL = System.Label.IR_SupportItemExceptionCodeCheckFail;
    
}