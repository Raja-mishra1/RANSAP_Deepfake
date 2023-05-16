/**
 * @description  Test Class for NDIA_SBLineItemDataSync class
 * @company      Cloudwerx
 * @date         30/08/2021
**/

@isTest
public class NDIA_SBLineItemDataSyncTest {
    @TestSetup
    static void createData() {
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

        ServiceBooking__c sb = new ServiceBooking__c();
        sb.Account__c = clientAccount.Id;
        sb.ExternalId__c = '123456';
        sb.PlanManager__c = 'MPM';
        insert sb;
    }
    
    @isTest   
    public static void unitTest_SBLineItemsSuccess() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":123456,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest();        
    }
    
    @isTest   
    public static void unitTest_SBLineItemsFailure() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(400,'{"httpCode":"400","httpMessage":"Bad Request","moreInformation":"Path parameter service_booking_id is mandatory and has to be more than 7 digits"}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest();        
    }
    
    @isTest   
    public static void unitTest_ServiceBookingFailure() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{"participant":"","participant_name":"Seth Davis","booking_type":"Z77777PLM","service_booking_id":123456,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APooooPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest();        
    }

    @isTest   
    public static void unitTest_SBLineItemFailure() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"Z77777PLM","service_booking_id":123456,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APooooPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"1_0023_436_1","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest();        
    }
    
    @isTest
    public static void unitTest_RateLimitHit() {
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];

        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(429,'{"success": false,"result": [],"erros" : []}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest();  
        List<Log__c> logrecord = [SELECT Id,Description__c FROM Log__c];
        System.assertEquals(1, logrecord.size(),'Log is generated'); 
    }
    
    @isTest
    public static void unitTest_NoLineItems() {
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];

        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":123456,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest();       
    }

    //TTP-980 - Ondemand SB Line Item Sync - Success Test 
    @isTest   
    public static void unitTest_OnDemandSBLineItemSyncSuccessTest() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":123456,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OnDemandSBLineItemSync.syncServiceBookingsOnDemand(new List<Id>{sb.Id});
        test.stopTest();        
    }
    
    //TTP-980 - Ondemand SB Line Item Sync - Success Test 
    @isTest   
    public static void unitTest_OnDemandRateLimitHit() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(429,'{"success": false,"result": [],"erros" : []}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OnDemandSBLineItemSync.syncServiceBookingsOnDemand(new List<Id>{sb.Id});
        test.stopTest();  
        List<Log__c> logrecord = [SELECT Id,Description__c FROM Log__c];
        System.assertEquals(1, logrecord.size(),'Log is generated');    
    }
    @isTest
    public static void unitTest_OnDemandNoLineItems() {
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];

        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":123456,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OnDemandSBLineItemSync.syncServiceBookingsOnDemand(new List<Id>{sb.Id});
        test.stopTest();          
    }
    @isTest   
    public static void unitTest_ExceptionInProcessing() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":{}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest();    
        List<Log__c> logrecord = [SELECT Id,Class__c FROM Log__c];
        System.assertEquals('NDIA_SBLineItemDataSyncBatch', logrecord[0].Class__c, 'Log is generated'); 
    }
    @isTest   
    public static void unitTest_ExceptionInParsing() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200,'{"success":true,"result":[]}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest(); 
        List<Log__c> logrecord = [SELECT Id,Description__c FROM Log__c];
        System.assertEquals(1, logrecord.size(), 'Log is generated');    
    }
    @isTest   
    public static void unitTest_ServiceUnavailableException() {   
        ServiceBooking__c sb = [SELECT id FROM ServiceBooking__c LIMIT 1];
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(503,'<!DOCTYPE html><html><head>ontent="width=device-width, initial-scale=1"><meta charset="utf-8">');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeSBLineItemSyncJob instance = new NDIA_OneTimeSBLineItemSyncJob();
            instance.execute(null);
        test.stopTest(); 
        List<Log__c> logrecord = [SELECT Id,Description__c FROM Log__c];
        System.assertEquals('Service Unavailable', logrecord[0].Description__c, 'Log is generated');     
    }

}