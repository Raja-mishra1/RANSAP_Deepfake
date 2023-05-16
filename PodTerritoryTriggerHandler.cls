/** Name: PodTerritoryTriggerHandler
 * Trigger : PodTerritoryTrigger
 * Description : It displays error if the Starting Post Code and Ending Post Code 
 * of Pod Territory overlaps with the existing Pod Territory child records of Pod
 * Created By : Cloudwerx
 * Created Date : 1/6/2020
*/

public class PodTerritoryTriggerHandler {

    public static final String PLAN_MANAGER_MPM = 'MPM';
    public static final String PLAN_MANAGER_NDSP = 'NDSP';

    public static void onBeforeTriggerOfPodTerritory(List<Pod_Territory__c> newPodTerritoryList) {
        List<Pod_Territory__c> podTerritoriesMPM = new List<Pod_Territory__c>();
        List<Pod_Territory__c> podTerritoriesNDSP = new List<Pod_Territory__c>();
        Set<Id> updatedNDSPIds = new Set<Id>();
        Set<Id> updatedMPMIds = new Set<Id>();
        for(Pod_Territory__c objPodT : newPodTerritoryList) {
            if(objPodT.Id != null) {
                if(PLAN_MANAGER_MPM.equalsIgnoreCase(objPodT.PlanManager__c)) {
                    updatedMPMIds.add(objPodT.Id);
                }
                else if(PLAN_MANAGER_NDSP.equalsIgnoreCase(objPodT.PlanManager__c)) {
                    updatedNDSPIds.add(objPodT.Id);
                }
            }
            if(PLAN_MANAGER_MPM.equalsIgnoreCase(objPodT.PlanManager__c)) {
                podTerritoriesMPM.add(objPodT);
            }
            else if(PLAN_MANAGER_NDSP.equalsIgnoreCase(objPodT.PlanManager__c)) {
                podTerritoriesNDSP.add(objPodT);
            }
        }

        if(podTerritoriesMPM?.size() > 0) {
            performDuplicateCheck(podTerritoriesMPM, updatedMPMIds, PLAN_MANAGER_MPM);
        }

        if(podTerritoriesNDSP?.size() > 0) {
            performDuplicateCheck(podTerritoriesNDSP, updatedNDSPIds, PLAN_MANAGER_NDSP);
        }
    }

       /**
     * @description  This method is to handle duplicate pod territory
     * @author		Ujjawal Kumar 
     * @param       podTerritories : list of Pod Terrotory
     * @param       podTerritoryIds : Set of updated pod territory Ids
     * @param       planManager : Plan Manager name
     * @return      NA
    **/
    public static void performDuplicateCheck(List<Pod_Territory__c> podTerritories, Set<Id> podTerritoryIds, String PlanManager) {
        Set<Double> SetOfPostCodes = new Set<Double>();
        List<Pod_Territory__c> existingPodTerritoryList = new List<Pod_Territory__c> ();
        existingPodTerritoryList = [Select Id ,Name, StartingPostCode__c, EndingPostCode__c, Pod__c, Pod__r.Name FROM Pod_Territory__c WHERE ID NOT IN: podTerritoryIds AND PlanManager__c =: PlanManager Limit 50000]; //ACEM-2 Added query limit
         // add all PostCode values in set
        if(existingPodTerritoryList?.size() > 0) {
            for(Pod_Territory__c objPodT : existingPodTerritoryList) {
                Double i =  objPodT.StartingPostCode__c;
                do {
                    SetOfPostCodes.add(i);
                    i++;
                } while (i <= objPodT.EndingPostCode__c);
            }
        }

         //check if PostCode is present in postCode Set
        if(existingPodTerritoryList?.size() > 0) {
            for(Pod_Territory__c objPodT : podTerritories ) {
                if(SetOfPostCodes.contains(objPodT.StartingPostCode__c)) {
                    double startPostCode = objPodT.StartingPostCode__c;
                    checkStartPostCode(objPodT,startPostCode,existingPodTerritoryList);  
                }
                else if(SetOfPostCodes.contains(objPodT.EndingPostCode__c)) {
                    double endPostCode = objPodT.EndingPostCode__c;
                    checkStartPostCode(objPodT, endPostCode, existingPodTerritoryList);
                }         
            }
        }
    }

    // method to display error
    public static void checkStartPostCode(Pod_Territory__c objPodT, double startPostCode, List<Pod_Territory__c> podTList ) {
        for(Pod_Territory__c podT : podTList) {
            if(startPostCode >= podT.StartingPostCode__c && startPostCode <= podT.EndingPostCode__c) {
                objPodT.addError('Error: the specified post code range overlaps with pod territory  ' +podT.Name+   '  with range  '  +podT.StartingPostCode__c+ ' - ' +podT.EndingPostCode__c+  ' assigned to pod  '  +podT.Pod__r.Name);
            }
        }
    }
}