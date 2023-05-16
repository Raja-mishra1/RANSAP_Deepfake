/**
 * @description      Test Class for NDIA_SBEndDateHandler class
 * @company          Cloudwerx
 * @date             09/09/2021
 **/

@isTest
public class NDIA_Event_SBEndDateUpdatedTest {
    @TestSetup
    static void makeData() {
        Reconnection_Trigger_Configuration__c recon = new Reconnection_Trigger_Configuration__c();
        recon.NDIA_Notification_Trigger_Activated__c = true;
        insert recon;
        /*CREATE ACCOUNT*/
        Account clientAccount = TestClassDataUtil.createClientAccount();
        clientAccount.NDIS__c = '431406066';
        clientAccount.Last_Service_Booking_Sync__c = system.today();
        update clientAccount;
        
        /*CREATE PLANS*/
        Plan__c plan1 = TestClassDataUtil.createPlan(clientAccount.Id);
        plan1.Plan_Start_Date__c = System.today().addMonths(1);
        plan1.Plan_End_Date__c = System.today().addMonths(2);
        plan1.PRODA_Plan_Id__c = '2551851';
        update plan1;
        
        /*CREATE SUPPORT CATEGORY*/
        SupportCategory__c supportCategory =  TestClassDataUtil.createSupportCategory(); 
        
        /*CREATE SUPPORT ITEMS*/
        List<SupportItem__c> supportItemList = TestClassDataUtil.createSupportItemRecords(true, 2, supportCategory.Id);
    }
    
    @isTest   
    public static void unitTest_processResponseSuccess() {   
        Account existingclientAccount =[SELECT id FROM Account LIMIT 1];
        ServiceBooking__c sb = new ServiceBooking__c();
        sb.Account__c = existingclientAccount.Id;
        sb.ExternalId__c = '123456';
        insert sb;
        ServiceBooking__c sb2 = new ServiceBooking__c();
        sb2.Account__c = existingclientAccount.Id;
        sb2.ExternalId__c = '1234567';
        sb2.PlanManager__c = 'MPM';
        insert sb2;
        
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":123456,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        List<NDIA_Notification__e> inkEvents = new List<NDIA_Notification__e>();
        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                               JSON_Message__c='{"serviceBookingId":"123456","startDate":"2021-06-21","endDate":"2023-12-17","planId":"2551851","NDIS":"431406066","mpmAccountNumber":"210604-18493"},"planManager": "MPM"'));                   
        
        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                                JSON_Message__c='{"serviceBookingId":"1234567","startDate":"2021-06-21","endDate":"2023-12-17","planId":"2551851","NDIS":"431406066","mpmAccountNumber":"210604-18493","planManager": "MPM"}'));
        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                                JSON_Message__c='{"serviceBookingId":"1234568","startDate":"2021-06-21","endDate":"2023-12-17","planId":"2551851","NDIS":"431406066","mpmAccountNumber":"210604-18493","planManager": "MPM"}'));                                        

        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                                JSON_Message__c='{"serviceBookingId":"1234568","startDate":"1-06-21","endDate":"2023-12-17","planId":"2551851","NDIS":"431406066","mpmAccountNumber":"210604-18493"},"planManager": "MPM"'));

        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                                JSON_Message__c='{"serviceBookingId":"1234568","startDate":"2021-06-21","endDate":"23-12-17","planId":"2551851","NDIS":"431406066","mpmAccountNumber":"210604-18493","planManager": "MPM"}'));
                                                
        test.startTest();
        List<Database.SaveResult> results = EventBus.publish(inkEvents);
        Test.getEventBus().deliver();
        ServiceBooking__c serviceBookingObj = [SELECT Id,Type__c,Account__c,Account__r.NDIS__c from ServiceBooking__c LIMIT 1];
        System.assertEquals('431406066', serviceBookingObj.Account__r.NDIS__c, 'Service Booking upserted');
        test.stopTest();        
    }
    
    @isTest   
    public static void  unitTest_processResponseFailure() {   
        Account existingclientAccount =[SELECT id FROM Account LIMIT 1];
        ServiceBooking__c sb = new ServiceBooking__c();
        sb.Account__c = existingclientAccount.Id;
        sb.ExternalId__c = '123456';
        insert sb;

        ServiceBooking__c sb2 = new ServiceBooking__c();
        sb2.Account__c = existingclientAccount.Id;
        sb2.ExternalId__c = '123459';
        insert sb2;

        
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":123456,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        List<NDIA_Notification__e> inkEvents = new List<NDIA_Notification__e>();
        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                               JSON_Message__c='{"serviceBookingId":"123qwqwqw456","startDate":"2021-06-21","endDate":"2023-12-17","planId":"25518ddsd51","NDIS":"431406066","mpmAccountNumber":"210604-18493"}'));
        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                               JSON_Message__c='{"serviceBookingId":"123456","startDate":"2021-06-21","endDate":"2023-12-17","planId":"2551851""NDIS":"431406066","mpmAccountNumber":"210604-18493"}'));
        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                               JSON_Message__c='{"serviceBookingId":"123459","startDate":"2021-06-21","endDate":"2023-12-17","planId":"2551851","NDIS":"431406066","mpmAccountNumber":"210604-18493"}'));
        inkEvents.add(new NDIA_Notification__e(Name__c='SB_END_DATE_UPDATED', 
                                               JSON_Message__c='{"serviceBookingId":"","startDate":"2021-06-21","endDate":"2023-12-17","planId":"2551851","NDIS":"431406066","mpmAccountNumber":"210604-18493"}'));
        test.startTest();
        List<Database.SaveResult> results = EventBus.publish(inkEvents);
        Test.getEventBus().deliver();
        List<Log__c> logrecordList = [SELECT Id, EventName__c, EventReplayId__c, Description__c FROM Log__c];
        System.assertEquals(8, logrecordList.size(),'Log is generated'); 
        test.stopTest();        
    }
    
}