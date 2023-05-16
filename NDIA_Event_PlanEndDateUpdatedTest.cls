/**
 * @description      [TTP-230] Apex Test Class for NDIA_NotificationPlanUpdateHandler class
 * @company          Cloudwerx
 * @date             30/08/2021
**/

@isTest
public class NDIA_Event_PlanEndDateUpdatedTest {
    
    public static final string reqbody = '{"success":true,"result":{"participant_plan_id":"2988984","plan_management":[{"plan_management":"ZCOR_PLAN","plan_management_text":"Core Plan Managed","supp_typ_lvl_dtls":[{"support_type":"ZCOR","support_type_text":"Core","approved_amount":113184.88,"allocated_amount":100,"spent_amount":0,"remaining_amount":113084.88,"supp_cat_lvl_dtls":[{"support_category":"CONSUMABLES","support_category_text":"Consumables","approved_amount":0,"allocated_amount":100,"spent_amount":0,"remaining_amount":-100,"supp_itm_lvl_dtls":[]},{"support_category":"DAILY_ACTIVITIES","support_category_text":"Assistance with Daily Life","approved_amount":50000,"allocated_amount":0,"spent_amount":0,"remaining_amount":50000,"supp_itm_lvl_dtls":[{"item_type":"ZSTA","item":" 1_0023_436_1","approved_amount":0,"allocated_amount":0,"spent_amount":0,"remaining_amount":0,"quoteable_item":true,"quote_approved":false,"in_kind":false}]},{"support_category":"SOCIAL_COMMUNITY_CIVIC","support_category_text":"Assistance with Social and Community Participation","approved_amount":63184.88,"allocated_amount":0,"spent_amount":0,"remaining_amount":63184.88,"supp_itm_lvl_dtls":[{"item_type":"ZSTA","item":"1_0023_436_2","approved_amount":13184.88,"allocated_amount":0,"spent_amount":0,"remaining_amount":13184.88,"quoteable_item":false,"quote_approved":false,"in_kind":false}]},{"support_category":"TRANSPORT","support_category_text":"Transport","approved_amount":0,"allocated_amount":0,"spent_amount":0,"remaining_amount":0,"supp_itm_lvl_dtls":[]}]}]},{"plan_management":"ZCAT_PLAN","plan_management_text":"Capacity Plan Managed","supp_typ_lvl_dtls":[{"support_type":"ZCAT","support_type_text":"Capital","approved_amount":102184.13,"allocated_amount":104.45,"spent_amount":0,"remaining_amount":102079.68,"supp_cat_lvl_dtls":[{"support_category":"ASSISTIVE_TECHNOLOGY","support_category_text":"Assistive Technology","approved_amount":102107.55,"allocated_amount":104.45,"spent_amount":0,"remaining_amount":102003.1,"supp_itm_lvl_dtls":[]},{"support_category":"HOME_MODIFICATIONS","support_category_text":"Home Modifications","approved_amount":76.58,"allocated_amount":0,"spent_amount":0,"remaining_amount":76.58,"supp_itm_lvl_dtls":[]}]}]},{"plan_management":"ZCAP_PLAN","plan_management_text":"Capital Plan Managed","supp_typ_lvl_dtls":[{"support_type":"ZCAP","support_type_text":"Capacity Building","approved_amount":29186.39,"allocated_amount":0,"spent_amount":0,"remaining_amount":29186.39,"supp_cat_lvl_dtls":[{"support_category":"CB_CHOICE_CONTROL","support_category_text":"Improved Life Choices","approved_amount":498.77,"allocated_amount":0,"spent_amount":0,"remaining_amount":498.77,"supp_itm_lvl_dtls":[]},{"support_category":"CB_DAILY_ACTIVITY","support_category_text":"Improved Daily Living","approved_amount":823.32,"allocated_amount":0,"spent_amount":0,"remaining_amount":823.32,"supp_itm_lvl_dtls":[{"item_type":"ZSTA","item":"15_037_0117_1_3","approved_amount":544.32,"allocated_amount":0,"spent_amount":0,"remaining_amount":544.32,"quoteable_item":false,"quote_approved":false,"in_kind":false}]},{"support_category":"CB_HEALTH_WELLBEING","support_category_text":"Improved Health and Wellbeing","approved_amount":5000,"allocated_amount":0,"spent_amount":0,"remaining_amount":5000,"supp_itm_lvl_dtls":[]},{"support_category":"CB_HOME_LIVING","support_category_text":"Improved Living Arrangements","approved_amount":5000,"allocated_amount":0,"spent_amount":0,"remaining_amount":5000,"supp_itm_lvl_dtls":[]},{"support_category":"CB_LIFELONG_LEARNING","support_category_text":"Improved Learning","approved_amount":5000,"allocated_amount":0,"spent_amount":0,"remaining_amount":5000,"supp_itm_lvl_dtls":[]},{"support_category":"SUPPORT_COORDINATION","support_category_text":"Support Coordination","approved_amount":12864.3,"allocated_amount":0,"spent_amount":0,"remaining_amount":12864.3,"supp_itm_lvl_dtls":[]}]}]}]}}';
    public static List<Plan__c> planList = new List<Plan__c>();
    
    @testSetup
    public static void makeData() {

        insert new Reconnection_Trigger_Configuration__c(NDIA_Notification_Trigger_Activated__c = True);

        /*CREATE CLIENT ACCOUNT*/
        Account clientAccount = TestClassDataUtil.createClientAccount();

        /*CREATE PLAN AND ASSOCIATE IT TO CLIENT ACCOUNT*/
        planList = TestClassDataUtil.createPlanRecords(false, 2,clientAccount.Id);
        planList[0].PRODA_Plan_Id__c = '2988984';
        planList[1].Plan_Start_Date__c = date.parse('6/01/2021');
        planList[1].Plan_End_Date__c = planList[1].Plan_Start_Date__c.addYears(3);
        planList[1].PRODA_Plan_Id__c = '2988989';
        planList[1].PlanManager__c = 'MPM'; //Added By Nishant Singh For NAP5-117
        insert planList;
    }

    @isTest
    public static void unitTest_NDIA_Event_PlanEndDateUpdated() {  
        Profile p = [Select id, Name from Profile where Name = 'System Administrator' limit 1];
        System.runAs(new user(ID = UserInfo.getUserID(), ProfileId = p.id)){
            Test.startTest();
            planList = [Select id, Name, Client_Name__c, PRODA_Plan_Id__c, Plan_Start_Date__c, Plan_End_Date__c from Plan__c];
        	GenericMockCallouts fakeSuccessResponse = new GenericMockCallouts(200, reqbody);
            Test.setMock(HttpCalloutMock.class, fakeSuccessResponse);
                List<NDIA_Notification__e> inkEvents = new List<NDIA_Notification__e>();
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "2988984", "startDate": "2021-01-08", "endDate": "2024-06-18", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1985-11-01","planManager": "MPM" }'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "2988989", "startDate": "2021-01-08", "endDate": "2024-06-18", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1985-11-01","planManager": "MPM" }'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "2988985", "startDate": "2021-01-08", "endDate": "2024-06-19", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1985-11-01","planManager": "MPM" }'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "2988985" "startDate": "2021-01-08", "endDate": "2024-06-19", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1985-11-01","planManager": "MPM" }'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "", "startDate": "2021-01-08", "endDate": "2024-06-19", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1985-11-01","planManager": "MPM" }'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "2988985", "startDate": "2021-01-08", "endDate": "2024-06-19", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1985-11-01","planManager": "MPM" }'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "2988985", "startDate": "21-01-08", "endDate": "2024-06-19", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1985-11-01","planManager": "MPM" }'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "2988985", "startDate": "2021-01-08", "endDate": "24-06-19", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1985-11-01","planManager": "MPM" }'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'PLAN_END_DT_UPDATED', JSON_Message__c = '{ "planId": "2988985", "startDate": "2021-01-08", "endDate": "2024-06-19", "NDIS": "430243559", "mpmAccountNumber": "210831-53840", "lastName": "Walter", "birthDate": "1785-11-01", "planManager": "MPM"}'
                ));
                
                EventBus.publish(inkEvents);
        	Test.stopTest();
            System.assertEquals(inkEvents[0].Name__c, 'PLAN_END_DT_UPDATED', 'Name Matched');
        }       
    }
}