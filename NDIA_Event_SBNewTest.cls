/**
 * @description     [TTP-1036] Apex Test Class for NDIA_Event_SBNew class
 * @author          Cloudwerx 
 * @date            09/27/2021
**/

@isTest
public without sharing class NDIA_Event_SBNewTest {

    @testSetup
    public static void makeData() {
        insert new Reconnection_Trigger_Configuration__c(NDIA_Notification_Trigger_Activated__c = True);    // Insert Reconnection Trigger for NDIA Notification Trigger
        Account clientAccount = TestClassDataUtil.createClientAccount();
        clientAccount.NDIS__c = '431406066';
        update clientAccount;
    }

    @isTest
    public static void unitTest_SBNewNotification () {
        List<NDIA_Notification__e> notificationEvents = new List<NDIA_Notification__e>();
        notificationEvents.add(new NDIA_Notification__e(Name__c = 'SB_NEW', JSON_Message__c = '{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":55879102,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-08","inkind_program":true,"status":"APPR","virtual_status":"Inactive","participant_plan_id":55879102,"planManager":"MPM","provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}'));
        notificationEvents.add(new NDIA_Notification__e(Name__c = 'SB_NEW', JSON_Message__c = '{"participant":431406066"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":55879102,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-08","inkind_program":true,"status":"APPR","virtual_status":"Inactive","participant_plan_id":55879102,"planManager":"MPM","provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}'));
        notificationEvents.add(new NDIA_Notification__e(Name__c = 'SB_NEW', JSON_Message__c = '{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":null,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-08","inkind_program":true,"status":"APPR","virtual_status":"Inactive","participant_plan_id":55879102,"planManager":"NDSP","provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}'));
        notificationEvents.add(new NDIA_Notification__e(Name__c = 'SB_NEW', JSON_Message__c = '{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":55879102,"start_date":"20-06-05","end_date":"2021-06-07","revised_end_date":"2021-06-08","inkind_program":true,"status":"APPR","virtual_status":"Inactive","participant_plan_id":55879102,"planManager":"MPM","provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}'));
        notificationEvents.add(new NDIA_Notification__e(Name__c = 'SB_NEW', JSON_Message__c = '{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":55879102,"start_date":"2020-06-05","end_date":"21-06-07","revised_end_date":"2021-06-08","inkind_program":true,"status":"APPR","virtual_status":"Inactive","participant_plan_id":55879102,"planManager":"MPM","provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}'));
        notificationEvents.add(new NDIA_Notification__e(Name__c = 'SB_NEW', JSON_Message__c = '{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":55879102,"start_date":"2020-06-05","end_date":"2021-06-07","revised_end_date":"21-06-08","inkind_program":true,"status":"APPR","virtual_status":"Inactive","participant_plan_id":55879102,"planManager":"NDSP","provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}'));
        notificationEvents.add(new NDIA_Notification__e(Name__c = 'SB_NEW', JSON_Message__c = '{"participant":431406066,"participant_name":"Seth Davis","booking_type":"ZPLM","service_booking_id":55879102,"start_date":"","end_date":"2021-06-07","revised_end_date":"21-06-08","inkind_program":true,"status":"APPR","virtual_status":"Inactive","participant_plan_id":55879102,"planManager":"MPM","provider_comments":"","items":[{"product_category":"CB_HEALTH_WELLBEING","product_category_item":"1_0023_436_1","product_category_item_desc":"","quantity":1,"allocated_amount":39744.76,"remaining_amount":28857.96},{"product_category":"DAILY_ACTIVITIES","product_category_item":"","product_category_item_desc":"1_0023_436_2","quantity":1,"allocated_amount":818.72,"remaining_amount":818.72}]}'));

        Test.startTest();
            EventBus.publish(notificationEvents);
        Test.stopTest();

        System.assertEquals(1, [SELECT ExternalId__c FROM ServiceBooking__c WHERE ExternalId__c = '55879102'].size());
    }
}