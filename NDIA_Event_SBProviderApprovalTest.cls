/**
 * @description      Apex Test Class for NDIA_Event_SBProviderApproval class
 * @company          Cloudwerx
 * @date             07/09/2021
 **/

@isTest public without sharing class NDIA_Event_SBProviderApprovalTest {
    public static List<Case> caseList= new List<Case>();
    public static List<NDIA_Notification__e> inkEvents = new List<NDIA_Notification__e>();

    @testSetup
    public static void makeData() {
        //Activate Trigger
        insert new Reconnection_Trigger_Configuration__c (NDIA_Notification_Trigger_Activated__c = True);
        List<ServiceBooking__c> sbList = TestClassDataUtil.createServiceBookingRecords(false, 2);
        sbList[0].ExternalId__c = '58358894';
        sbList[1].ExternalId__c = '58358895';
        insert sbList;
    }

    @isTest
    public static void unitTest_caseInsertSuccess() {
        /*CREATE CLIENT ACCOUNT*/
        Account clientAccount = TestClassDataUtil.createClientAccount();
        Profile p = [SELECT id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        System.runAs(new user(ID = UserInfo.getUserID(), ProfileId = p.id)) {
            Test.startTest();
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'SERVICBK_PROVID_APPR', JSON_Message__c = '{"serviceBookingId": "58358894","planId": "2988984","NDIS": "431231232","mpmAccountNumber": "210604-18493","planManager":"MPM","status": "APRO"}'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'SERVICBK_PROVID_APPR', JSON_Message__c = '{"serviceBookingId": "58358895","planId": "2988984","NDIS": "431231232","mpmAccountNumber": "210604-18494","planManager":"NDSP","status": "APRO"}'
                ));
                EventBus.publish(inkEvents);
        	Test.stopTest();
        }  
        System.assertEquals(inkEvents[0].Name__c, 'SERVICBK_PROVID_APPR', 'Name Matched');
        caseList = [SELECT Id FROM Case];
        //System.assertEquals(2, caseList.size(), '2 Case Records are created');
    }
    
    @isTest
    public static void unitTest_caseInserFailure() {
        Profile p = [SELECT id, Name FROM Profile WHERE Name = 'System Administrator' limit 1];
        System.runAs(new user(ID = UserInfo.getUserID(), ProfileId = p.id)) {
            Test.startTest();
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'SERVICBK_PROVID_APPR', JSON_Message__c = '{"serviceBookingId": "","planId": "2988984","NDIS": "431231232","mpmAccountNumber": "210604-18493","planManager":"MPM","status": "APRO"}'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'SERVICBK_PROVID_APPR', JSON_Message__c = '{"serviceBookingId": "58358896","planId": "2988984","NDIS": "431231232","mpmAccountNumber": "210604-18494","planManager":"MPM","status": "APRO"}'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'SERVICBK_PROVID_APPR', JSON_Message__c = '{"serviceBookingId": "","planId": "2988984""NDIS": "431231232","mpmAccountNumber": "210604-18494","planManager":"MPM","status": "APRO"}'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'SERVICBK_PROVID_APPR', JSON_Message__c = '{"serviceBookingId": "","planId": "2988984","NDIS": "431231232","mpmAccountNumber": "210604-18494","planManager":"MPM","status": "APRO"}'
                ));
                inkEvents.add(new NDIA_Notification__e(
                    Name__c = 'SERVICBK_PROVID_APPR', JSON_Message__c = '{"serviceBookingId": "","planId": "2988984","NDIS": "431231232","mpmAccountNumber": "210604-18494","planManager":"MPM","status": "APRO"}'
                ));
                EventBus.publish(inkEvents);
        	Test.stopTest();
        }  
        System.assertEquals(inkEvents[0].Name__c, 'SERVICBK_PROVID_APPR', 'Name Matched');
        caseList = [SELECT Id FROM Case];
        System.assertEquals(0, caseList.size(), '2 Case Records are created');
        List<Log__c> logrecordList = [SELECT Id, Description__c FROM Log__c];
        System.assertEquals(10, logrecordList.size(),'Log is generated'); 
    }
}