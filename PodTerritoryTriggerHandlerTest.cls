/**
 * TestData Factory: PodTestDataFactory
 * Trigger: PodTerritoryTrigger
 * Description: Test class for  PodTerritoryTriggerHandler
 * Created By: Cloudwerx
 * Created Date: 02/06/2020
 */
@isTest
private class PodTerritoryTriggerHandlerTest {

   
    @testSetup static void setup() {
        Reconnection_Trigger_Configuration__c recon = new Reconnection_Trigger_Configuration__c();
        recon.Pod_Territory_Trigger_Activated__c = True;
        insert recon;
        //List<Skill> skillList = PodTestDataFactory.getSKill(); 
        //Pod__c pod = new Pod__c (Pod_Skill_Id__c = skillList[0].Id, Pod_Skill_New__c= skillList[0].MasterLabel, Name = 'Test Pod of PodTerritory1');
        Pod__c pod = new Pod__c (Name = 'Test Pod of PodTerritory MPM', PlanManager__c = 'MPM');
        insert pod;
        //Pod__c pod2 = new Pod__c (Pod_Skill_Id__c = skillList[1].Id, Pod_Skill_New__c= skillList[1].MasterLabel, Name = 'Test Pod of PodTerritory2');
        Pod__c pod2 = new Pod__c (Name = 'Test Pod of PodTerritory NDSP', PlanManager__c = 'NDSP');
        insert pod2;
        //insert Pod Territories with no overlapping codes
        Pod_Territory__c podT1 = new Pod_Territory__c(Pod__c = pod.Id, StartingPostCode__c= 1200, EndingPostCode__c = 1400, PlanManager__c = 'MPM');
        insert podT1;
        Pod_Territory__c podT2 = new Pod_Territory__c(Pod__c = pod.Id, StartingPostCode__c= 1401, EndingPostCode__c = 1500, PlanManager__c = 'MPM');
        insert podT2;
    }

    @isTest
    static void testBeforeInsertPodTerritory() {
        List<Pod_Territory__c> podTerrList = new List<Pod_Territory__c> ();
        Pod__c pod = [Select Id FROM Pod__c WHERE Name = 'Test Pod of PodTerritory MPM'];
        Pod__c pod1 = [Select Id FROM Pod__C WHERE Name = 'Test Pod of PodTerritory NDSP'];
        Pod_Territory__c newPodT = new Pod_Territory__c(Pod__c = pod.Id, StartingPostCode__c= 1100, EndingPostCode__c = 1201, PlanManager__c = 'MPM');
        Pod_Territory__c newPodT1 = new Pod_Territory__c(Pod__c = pod1.Id, StartingPostCode__c= 1402, EndingPostCode__c = 1501, PlanManager__c = 'NDSP');

        podTerrList.add(newPodT);
        podTerrList.add(newPodT1);


        Test.startTest();
        Exception ex;
        try {
            insert podTerrList;
        }catch(Exception e) {
            ex = e;
        }
        Test.stopTest();
        System.assertNotEquals(null, ex);
    
    }

    @isTest
    static void testOnBeforeUpdatePodTerritory() {
        Pod__c pod = [Select Id FROM Pod__c WHERE Name = 'Test Pod of PodTerritory MPM'];
        Pod_Territory__c objPod1 = new Pod_Territory__c(StartingPostCode__c = 1501, EndingPostCode__c = 1600, Pod__c = pod.Id, PlanManager__c = 'MPM' );
        Pod_Territory__c objPod2 = new Pod_Territory__c(StartingPostCode__c = 1601, EndingPostCode__c = 1700, Pod__c = pod.Id, PlanManager__c = 'MPM' );

        Test.startTest();
        Exception ex;

        Try {
            insert objPod1;
            insert objPod2;
            objPod2.StartingPostCode__c = 1502;
            objPod2.EndingPostCode__c = 1599;
            update objPod2;
        } catch(Exception e) {
            ex = e;
        }

        Test.stopTest();
        System.assertNotEquals(null, ex);
    }
}