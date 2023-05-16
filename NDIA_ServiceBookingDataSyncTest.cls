/**
* Class Name: NDIA_ServiceBookingDataSyncTest
* Description: Test Class for NDIA_ServiceBookingDataSync class
* Created By: Cloudwerx
* Created Date: 30/08/2021
*/

@isTest
public with sharing class NDIA_ServiceBookingDataSyncTest {

    @TestSetup
    static void makeData(){
        /*CREATE ACCOUNT */
        Account clientAccount = TestClassDataUtil.createClientAccount();
        clientAccount.FirstName = 'Seth';
        clientAccount.LastName = 'Davis';
        clientAccount.NDIS__c = '431406066';
        clientAccount.Last_Plan_Sync__c = System.today();
        clientAccount.PlanManager__c = 'MPM';
        update clientAccount;

        /*CREATE PLANS*/
        Plan__c plan1 = TestClassDataUtil.createPlan(clientAccount.Id);
        plan1.Proda_Plan_Id__c = '2551851';
        update plan1;

        Plan__c plan2 = TestClassDataUtil.createPlan(clientAccount.Id);
        plan2.Proda_Plan_Id__c = '3150993';
        update plan2;
    }

    @isTest
    public static void testSbSyncOnDemandSuccess(){
        Account acc = [SELECT Id, (SELECT Id, Proda_Plan_Id__c FROM Plans__r) FROM Account];

        GenericMultipleMockCallouts fakeSuccessResponse = new GenericMultipleMockCallouts(200);
        fakeSuccessResponse.addResponses('sb','{"success":true,"result":[{"service_booking_id":55879102,"booking_type":"ZSAG","participant":431406066,"participant_name":"Seth Davis","start_date":"2020-06-05","end_date":"2021-06-07","submitted_date":"2020-06-19","created_by":"Provider","status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":""}]}');
        fakeSuccessResponse.addResponses('sbLineItem', '{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":55879102,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OnDemandServiceBookingSync.syncServiceBookingsOnDemand(new List<ID>{acc.Plans__r[0].Id});
        test.stopTest();
        System.assertEquals(1, [SELECT count(Id) FROM ServiceBooking__c WHERE Account__c =: acc.Id][0].get('expr0'));
    }

    @isTest
    public static void testSbSyncOnDemandException(){
        Account acc = [SELECT Id, (SELECT Id, Proda_Plan_Id__c FROM Plans__r) FROM Account];

        GenericMultipleMockCallouts fakeSuccessResponse = new GenericMultipleMockCallouts(200);
        fakeSuccessResponse.addResponses('sb','{"success":true,"result":{"service_booking_id":55879102,"booking_type":"ZSAG","participant":431406066,"participant_name":"Seth Davis","start_date":"2020-06-05","end_date":"2021-06-07","submitted_date":"2020-06-19","created_by":"Provider","status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":""}}');
        fakeSuccessResponse.addResponses('sbLineItem', '{"success":true,"result":{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":55879102,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-07","inkind_program":false,"status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
        NDIA_OneTimeServiceBookingsSyncJob instance = new NDIA_OneTimeServiceBookingsSyncJob();
        instance.execute(null);
        test.stopTest();
        System.assertEquals(0, [SELECT count(Id) FROM ServiceBooking__c WHERE Account__c =: acc.Id][0].get('expr0'));
    }


    @isTest
    public static void testSbSyncOnDemandNoRecords(){
        Account acc = [SELECT Id, (SELECT Id, Proda_Plan_Id__c FROM Plans__r) FROM Account];

        GenericMultipleMockCallouts fakeSuccessResponse = new GenericMultipleMockCallouts(200);
        fakeSuccessResponse.addResponses('sb','{"success":true,"result":[]}');
        fakeSuccessResponse.addResponses('sbLineItem','{"success":true,"result":[]}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OnDemandServiceBookingSync.syncServiceBookingsOnDemand(new List<ID>{acc.Plans__r[0].Id});
        test.stopTest();
        System.assertEquals(0, [SELECT count(Id) FROM ServiceBooking__c WHERE Account__c =: acc.Id][0].get('expr0'));
    }

    @isTest
    public static void testSbSyncOnDemandFailed(){
        Account acc = [SELECT Id, (SELECT Id, Proda_Plan_Id__c FROM Plans__r) FROM Account];

        GenericMultipleMockCallouts fakeSuccessResponse = new GenericMultipleMockCallouts(500);
        fakeSuccessResponse.addResponses('sb','{"success":true,"result":[]}');
        fakeSuccessResponse.addResponses('sbLineItem','{"success":true,"result":[]}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OnDemandServiceBookingSync.syncServiceBookingsOnDemand(new List<ID>{acc.Plans__r[0].Id});
        test.stopTest();
        System.assertEquals(0, [SELECT count(Id) FROM ServiceBooking__c WHERE Account__c =: acc.Id][0].get('expr0'));
    }

    @isTest
    public static void unitTest_upsertServiceBookings () {
        Account acc = [SELECT Id, (SELECT Id, Proda_Plan_Id__c FROM Plans__r) FROM Account];

        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200, '{"success":true,"result":[{"service_booking_id":55879102,"booking_type":"ZSAG","participant":431406066,"participant_name":"Seth Davis","start_date":"2020-06-05","end_date":"2021-06-07","submitted_date":"2020-06-19","created_by":"Provider","status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":""},{"service_booking_id":55879144,"booking_type":"ZPLM","participant":431406066,"participant_name":"Seth Davis","start_date":"2020-06-05","end_date":"2021-06-07","submitted_date":"2020-06-19","created_by":"Provider","status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":""},{"service_booking_id":58095175,"booking_type":"ZPLM","participant":431406066,"participant_name":"Seth Davis","start_date":"2021-06-08","end_date":"2022-06-08","submitted_date":"2021-06-10","created_by":"Provider","status":"APPR","virtual_status":"Active","participant_plan_id":3150993,"provider_comments":""},{"service_booking_id":58095138,"booking_type":"ZSAG","participant":431406066,"participant_name":"Seth Davis","start_date":"2021-06-08","end_date":"2022-06-08","submitted_date":"2021-06-10","created_by":"Provider","status":"APPR","virtual_status":"Active","participant_plan_id":3150993,"provider_comments":""}]}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeServiceBookingsSyncJob instance = new NDIA_OneTimeServiceBookingsSyncJob();
            instance.execute(null);
        test.stopTest();

        System.assertEquals(4, [SELECT count(Id) FROM ServiceBooking__c WHERE Account__c =: acc.Id][0].get('expr0'));
    }

    @isTest
    public static void unitTest_noRecordsFoundTest () {
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200, '{"success":true,"result":[]}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeServiceBookingsSyncJob instance = new NDIA_OneTimeServiceBookingsSyncJob();
            instance.execute(null);
        test.stopTest();

        Account acc = [SELECT Id, Sync_Error_Service_Booking__c FROM Account];
        System.assert(acc.Sync_Error_Service_Booking__c == System.Label.NDIA_NoRecordsFound);
    }

    @isTest
    public static void unitTest_RateLimitHit() {
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(429,'{"success": false,"result": [],"erros" : []}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeServiceBookingsSyncJob instance = new NDIA_OneTimeServiceBookingsSyncJob();
            instance.execute(null);
        test.stopTest();  
        List<Log__c> logrecord = [SELECT Id,Description__c FROM Log__c];
        System.assertEquals(1, logrecord.size(),'Log is generated'); 
    }

    @isTest
    public static void unitTest_ServiceUnavailableError() {
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(503,'{"success": false,"result": [],"erros" : []}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeServiceBookingsSyncJob instance = new NDIA_OneTimeServiceBookingsSyncJob();
            instance.execute(null);
        test.stopTest();  
        List<Log__c> logrecord = [SELECT Id,Description__c FROM Log__c];
        System.assertEquals(1, logrecord.size(),'Log is generated'); 
    }

    @isTest
    public static void unitTest_DmlError () {
        GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200, '{"success":true,"result":[{"service_booking_id":55879102,"booking_type":"ZSAG","participant":"Test Account","participant_name":"Seth Davis","start_date":"2021-06-07","end_date":"2021-06-07","submitted_date":"2020-06-19","created_by":"Providerfsadfsadfadfsdfghfghdgqweqweqweqweqweqweqweqweasasdfyasgcuyqgrvuiyqergvioyeqrgvkiuhgfvoiygroiuqhgrfoiuygherdfoiuhgrfiluabgsdoufiyg3pifnberiuhgldsuvhgqsodiuheqori7hreiufhbslduvhasidughperughurhbsuhfpusdhfpuorhgporhfhpdufhgvpurnvourhvpoqerhrihgpoquerhg","status":"APPR","virtual_status":"Inactive","participant_plan_id":2551851,"provider_comments":""}]}');
        Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
        test.startTest();
            NDIA_OneTimeServiceBookingsSyncJob instance = new NDIA_OneTimeServiceBookingsSyncJob();
            instance.execute(null);
        test.stopTest();

        List<Log__c> logrecord = [SELECT Id,Description__c FROM Log__c];
        System.assertEquals(1, logrecord.size(),'Log is generated');
    }
}