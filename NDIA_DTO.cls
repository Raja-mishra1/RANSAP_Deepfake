/**
 * @description      This class contains the possible classes that can be recieved by the NDIS server 
 * 					 Helps in parsing Request & Response
 * @company          Cloudwerx
 * @date             26/07/2021
**/

public class NDIA_DTO {

	//TTP-609 Start
	public class PlanQuery {
        public String participant;
        public String participant_surname;
        public String date_of_birth;

		public PlanQuery(Account account) {
			this.participant= account.NDIS__c;
			this.participant_surname= account.LastName;
			this.date_of_birth = String.valueOf(account.PersonBirthdate);
		}
    }

    public class PlanResponse {
        public Boolean success;
        public PlanResponseResult [] result;
        public String [] errors;
    }

	/**
     * @description     Method deserializes the data received from to Plan API
     * @author          Sonali Takke
     * @param           json : Serialized Response string
	 * @return			PlanResponse wrapper
    **/

	public static PlanResponse parseplanResponse(String json) {
		return (PlanResponse) System.JSON.deserialize(json, PlanResponse.class);
	}

    public class PlanResponseResult{
        public String participant_plan_id;
        public String plan_start_date;
        public String plan_end_date;
        public String participant;
    }
	//TTP-609 End

	//TTP-610 Start
	public class BudgetQuery {
		public String participant_surname;
		public String date_of_birth;

		public BudgetQuery(String participant_surname, String date_of_birth){
			this.participant_surname = participant_surname;
			this.date_of_birth = date_of_birth;
		}
	}

    public class BudgetResponse {
        public Boolean success;
	    public BudgetResultResponse result;
		public List<ErrorResponse> errors;
    }

	public class BudgetResultResponse {
		public String participant_plan_id;
		public List<PlanManagedResponse> plan_management;
	}

    public class PlanManagedResponse {
		public String plan_management;
		public String plan_management_text;
		public List<SupportTypeLevelDetailResponse> supp_typ_lvl_dtls;
	}

	public class SupportTypeLevelDetailResponse {
		public String support_type;
		public String support_type_text;
		public Double approved_amount;
		public Double allocated_amount;
		public Double spent_amount;
		public Double remaining_amount;
		public List<SupportCategoryLevelDetailResponse> supp_cat_lvl_dtls;	
	}

	public class SupportCategoryLevelDetailResponse{
		public PlanManagedResponse myparent;
		public String support_category;
		public String support_category_text;
		public Double approved_amount;
		public Double allocated_amount;
		public Double spent_amount;
		public Double remaining_amount;
		public String plan_management;
		public String plan_management_text;
		public List<SupportItemLevelDetailResponse> supp_itm_lvl_dtls;
	}

	public class SupportItemLevelDetailResponse {
		public String item_type;
		public String item;
		public Double approved_amount;
		public Double allocated_amount;
		public Double spent_amount;
		public Double remaining_amount;
		public Boolean quoteable_item;
		public Boolean quote_approved;
		public Boolean in_kind;
    }

	/**
     * @description     Method deserializes the data received from PaymentRequestCreation API
     * @author          Sonali Takke
     * @param           json : Serialized Response string
	 * @return			BudgetResponse wrapper
    **/ 

	public static BudgetResponse parse(String json) {
		return (BudgetResponse) System.JSON.deserialize(json, BudgetResponse.class);
	}

	 //Result wrappers
	 public class PlanResult {
        public String errors;
        public String planId;
        public String prodaPlanId;
        public String clientId;
        public Boolean isCreated; 
        public Boolean isSuccess;
    }

    public class PlanSupportResult {
        public String errors;
        public String planSupportId;
		public String planId;
        public String externalId;
        public Boolean isCreated;
        public Boolean isSuccess;
    }

    public class PlanSupportItemResult {
        public String errors;
        public String planSupportItemId;
		public String planId;
        public String externalId;
        public Boolean isCreated;
        public Boolean isSuccess;
    }

	public class ResponseError {
		public boolean success;
		public List<String> errors;
		public String moreInformation;
		public String message;			// TTP-1600
	}

	//Change in Error response format for Budget API only 
	public class ErrorDetails {
		public String code;
		public String detail;
	}
	
	public class ErrorResponse {
		public boolean success;
		public List<ErrorDetails> errors;
		public String moreInformation;
		public String message;			
	}

	public class ErrorResponseString {
		public boolean success;
		public List<String> errors;
		public String moreInformation;
		public String message;			
	}
	//END

	//TTP-610 End

	// TTP-779, TTP-975 - Start	
	public class ServiceBookingResponse {
		public Boolean success;
        public ServiceBookingResponseResult [] result;
        public String [] errors;
	}

	public class ServiceBookingResponseResult {
		public String service_booking_id;
		public String booking_type;
		public String participant;
		public String participant_name;
		public String start_date;
		public String end_date;
		public String submitted_date;
		public String created_by;
		public String status;
		public String virtual_status;
		public String participant_plan_id;
		public String provider_comments;
		public Boolean inkind_program;
		public String revised_end_date;
		public List<ServiceBookingLineItemResponseResult> items;
		public String event_replay_id;
		public String planManager; // NAP5-117
	}

	public class ServiceBookingLineItemResponseResult {
		public String product_category;
		public String product_category_item;
		public String product_category_item_desc;
		public Integer quantity;
		public Double allocated_amount;
		public Double remaining_amount;
		public String externalId; 
	}

	public class ServiceBookingResult {
		public String errors;
        public String serviceBookingId;
        public String prodaPlanId;
        public String clientId;
		public String recordId;
        public Boolean isCreated; 
        public Boolean isSuccess;
	}

	public class ServiceBookingLineItemResult {
		public String errors;
        public String externalId;
        public String serviceBookingId;
        public Boolean isCreated; 
        public Boolean isSuccess;
		public String recordId;

	}

	/**
     * @description     Method deserializes the data received from to ServiceBooking API
     * @author          Mehul Shah
     * @param           json : Serialized Response string
	 * @return			ServiceBookingResponse wrapper
    **/

	public static ServiceBookingResponse parseServiceBookingResponse(String json) {
		return (ServiceBookingResponse) System.JSON.deserialize(json, ServiceBookingResponse.class);
	}

	/**
     * @description     Method deserializes the inner data recived from to ServiceBooking API
     * @author          Mehul Shah
     * @param           json : Serialized Response string
	 * @return			ServiceBookingResponseResult wrapper
    **/
	public static ServiceBookingResponseResult parseServiceBookingResponseResult(String json) {
		return (ServiceBookingResponseResult) System.JSON.deserialize(json, ServiceBookingResponseResult.class);
	}

	/**
     * @description     Method deserializes the data related to ServiceBookingLineItem response
     * @author          Swapnil Bhapkar
     * @param           json : Serialized Response string
	 * @return			ServiceBookingLineItemResponse wrapper
    **/
	public static ServiceBookingLineItemResponse parseServiceBookingLineItemResponse(String json) {
		return (ServiceBookingLineItemResponse) System.JSON.deserialize(json, ServiceBookingLineItemResponse.class);
	}

	public static ServiceBookingResponse parseServiceBookingLineItemEmptyResponse(String json) {
		return (ServiceBookingResponse) System.JSON.deserialize(json, ServiceBookingResponse.class);
	}

	public class ServiceBookingLineItemResponse {
		public Boolean success;
        public ServiceBookingResponseResult result;
        public String [] errors;
	}

	// TTP-779, TTP-975 - End

	// RPA changes
	public class ServiceBookings {
		public ServiceBookingLineItemResponse [] serviceBookings;
	}

	/**
     * @description     Method deserializes the data received from PaymentRequestCreation API
     * @author          Mehul Shah
     * @param           json : Serialized Response string
	 * @return			ServiceBookings wrapper
    **/
	public static ServiceBookings parseServiceBookings(String json) {
		return (ServiceBookings) System.JSON.deserialize(json, ServiceBookings.class);
	}

	//TTP-1404,TTP-1405
	public class PaymentRequest {

		public String ref_doc_no;	
		public Integer participant;
		public Integer service_agreement;
		public Long abn_provider;
		public boolean abn_not_available;
		public String exemption_reason;
		public String product_category;	
		public String product_category_item;
		public String start_date;	
		public String end_date;	
		public Double quantity;	
		public String unit_of_measure;
		public Double claimed_amount;
		public String tax_code;
		public String claim_type;	
		public String claim_reason;			

		public PaymentRequest(Payment_Request__c PaymentRequest) {
			this.ref_doc_no =  String.isNotEmpty(PaymentRequest.Reference_Number__c) ? 
				PaymentRequest.Reference_Number__c : '' ;
			this.participant = PaymentRequest.Client_NDIS__c != null ? Integer.valueOf(PaymentRequest.Client_NDIS__c ) : 0;
			this.service_agreement = (PaymentRequest.PRODA_Service_Booking_Id__c != null) 
									? Integer.valueOf(PaymentRequest.PRODA_Service_Booking_Id__c) : 0;
			this.abn_provider = (PaymentRequest.Provider_ABN__c != null) 
					?  long.valueOf(PaymentRequest.Provider_ABN__c)
					: 0;
			this.abn_not_available = PaymentRequest.ABN_Not_Available__c;
			this.exemption_reason = PaymentRequest.PRODA_Exemption_Reason__c != null 
					? PaymentRequest.PRODA_Exemption_Reason__c
				: '';
			this.product_category = PaymentRequest.PRODA_Support_Category_Code__c != null 
					?  PaymentRequest.PRODA_Support_Category_Code__c
					: '';
			this.product_category_item = String.isNotEmpty(PaymentRequest.PRODA_Support_Item_Number__c) 
					? PaymentRequest.PRODA_Support_Item_Number__c
					: '';
			this.unit_of_measure = String.isNotEmpty(PaymentRequest.Unit_Of_Measure__c) 
					? PaymentRequest.Unit_Of_Measure__c
					: '';
			this.tax_code = PaymentRequest.PRODA_Tax_Code__c != null ? PaymentRequest.PRODA_Tax_Code__c : '';
			this.claim_type = PaymentRequest.PRODA_Claim_Type__c != null ? PaymentRequest.PRODA_Claim_Type__c: '';
			this.claim_reason = PaymentRequest.PRODA_Claim_Reason__c != null ?PaymentRequest.PRODA_Claim_Reason__c: '';
			this.start_date = string.valueOf(PaymentRequest.Service_Date_From__c);
			this.end_date = string.valueOf(PaymentRequest.Service_Date_To__c);
			this.quantity = PaymentRequest.Quantity__c;
			this.claimed_amount = PaymentRequest.Amount__c;
		}
	}

	public class PaymentResponse {
		public String claim_number;
		public String participant;
		public Double claimed_amount;
		public String participant_name;
		public String ref_doc_no;	
		public String invoice_number;
		public String claim_status;	
		public String start_date;	
		public String end_date;	
		public String product_category;	
		public String product_category_item;
		public String product_description;
		public String claim_type;
		public String claim_reason;
		public Double amount;
		public String quantity;	
		public String tax_code;	
		public String plan_id;
		public String service_agreement;
		public String inkind_flag;
		public String submit_date;
		public String submit_by;
		public String reject_reason_code;
		public String paid_date;
		public String abn_provider;
		public String exemption_reason;
	}

	public class PaymentRequestCreationResponse {
		public Boolean success;
        public PaymentResponse result;
		public String [] errors;
	}

	/**
     * @description     Method deserializes the data received from PaymentRequestCreation API
     * @author          PrithviRaj Deshmukh
     * @param           json : Serialized Response string
	 * @return			PaymentRequestCreationResponse wrapper
    **/ 
	public static PaymentRequestCreationResponse parsePaymentRequestCreationResponse(String json) {
		return (PaymentRequestCreationResponse) System.JSON.deserialize(json, PaymentRequestCreationResponse.class);
	}
	
	public class PaymentRequestCancellationResponse {
		public Boolean success;
        public String [] errors;
	}

	/**
     * @description     Method deserializes the data received from PaymentRequestCancellation API
     * @author          Rohit Tikoo
     * @param           json : Serialized Response string
	 * @return			PaymentRequestCancellationResponse wrapper
    **/  
	public static PaymentRequestCancellationResponse parsePaymentRequestCancellationResponse(String json) {
		return (PaymentRequestCancellationResponse) System.JSON.deserialize(json, PaymentRequestCancellationResponse.class);
	}

}