/**
 * @description      DTO Class for handling and parsing the NDIA Notifications Data
 * @company          Cloudwerx
 * @date             30/08/2021
**/

public without sharing class NDIA_NotificationDTO {
    
    public class PlanDateUpdate {
        public String planId;
        public String startDate;
        public String endDate;
        public String NDIS;
        public String mpmAccountNumber;
        public String lastName;
        public String birthDate;
        public String event_replay_id;
        public String planManager; //Added by Nishant Singh for NAP5-117
    }
    
    /**
     * @description     Method deserializes the data received from to Plan API
     * @author          Rohit Tikoo
     * @param           json : Serialized Response string
	 * @return			PlanDateUpdate wrapper
    **/

    public static PlanDateUpdate parsePlanInfo(String json) {
        return (PlanDateUpdate) System.JSON.deserialize(json, PlanDateUpdate.class);
    }

    public class ServiceBookingUpsert {
        public String serviceBookingId;
        public String planId;
		public String NDIS;
        public String mpmAccountNumber;
		public String status;
        public String startDate;
        public String endDate;
        public String event_replay_id;
        public String planManager;  //NAP5-117
    }

    /**
     * @description     Method deserializes the data received from to ServiceBooking API
     * @author          Sonali Takke
     * @param           json : Serialized Response string
	 * @return			ServiceBookingUpsert wrapper
    **/

    public static ServiceBookingUpsert parseServiceBookingInfo(String json) {
        return (ServiceBookingUpsert) System.JSON.deserialize(json, ServiceBookingUpsert.class);
    }
}