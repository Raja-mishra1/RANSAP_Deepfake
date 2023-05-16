/**
 * @description      Controller for PodAssignment Lightning Component
 * @company          Cloudwerx
 * @date             02/06/2020
**/

public class PodAssignmentController {
    
    /**
     * @description     Called at initialize to get the current status of Pod
     * @author          Animesh Chauhan
     * @param           podId : record id
     * @return          pod object is returned
    **/
    @AuraEnabled
    public static Pod__c retrievePodRecord(Id podId) {
        return [SELECT Id, PodAssignmentStatus__c, PodAssignmentScheduleTime__c FROM Pod__c WHERE Id =: podId];
    }
    
    /**
     * @description     To retrieve latest status on the Apex job running
     * @author          Animesh Chauhan
     * @param           podId : record id
     * @return          AsyncApexJob object is returned
    **/
    @AuraEnabled
    public static AsyncApexJob getBatchResults(Id podId) {
        Pod__c pod = [SELECT Id, Batch_Job_Id__c FROM Pod__c WHERE Id =: podId];
        return [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CompletedDate, ExtendedStatus
                                    FROM AsyncApexJob WHERE Id =: pod.Batch_Job_Id__c];
    }
    
    /**
     * @description     Called when Execute Assignment Rules is clicked to retrieve the account count that will be processed
     * @author          Animesh Chauhan
     * @param           podId : record id
     * @return          RecordInfoWrapper
    **/
    @AuraEnabled
    public static RecordInfoWrapper retriveRecordCountInformation(Id podId) {
        List <Account> listOfAccount = [SELECT Id FROM Account WHERE Pod__c =: podId];
        List <Account> listOfAccountsToBeProcessed = retrieveAccountListToBeProcessed(podId);
        return new RecordInfoWrapper(listOfAccount.size(), listOfAccountsToBeProcessed.size());
    }
    
    /**
     * @description     Called when Run button is clicked which exuecute the batch and update time fields
     * @author          Animesh Chauhan
     * @param           podId : record id
     * @return          Pod object is returned after executing the batch
    **/
    @AuraEnabled
    public static Pod__c executeBatch(Id podId) {
        Pod__c pod = new Pod__c(Id = podId, PodAssignmentStatus__c = 'Scheduled', PodAssignmentScheduleTime__c = System.now(), 
                        Batch_Job_Id__c = AsyncApexFramework.submitBatch(new PodAssignmentBatchClass(podId),100,99));
        AsyncApexFramework.flush();
        update pod;
        return pod;
    }
    
    /**
     * @description     Generic method to update the Pod record
     * @author          Animesh Chauhan
     * @param           pod : pod record
     * @return          Pod object is returned after update
    **/
    @AuraEnabled
    public static Pod__c updatePodRecord(Pod__c pod) {
        update pod;
        return pod;
    }
    
    /**
     * @description     This method is used to find count of records to be processed & 
                        is also used by batch apex to get records to process 
     * @author          Animesh Chauhan
     * @param           podId : pod id
     * @return          list of accounts 
    **/
    public static List <Account> retrieveAccountListToBeProcessed(Id podId) {
        
        List <Account> listOfAccountsToBeProcessed = new List <Account>();

        Pod__c Pod = [SELECT Name, Pod_Type__c, Pod_Skill_New__c FROM Pod__c WHERE id = :podId];

        if (Pod.Pod_Type__c == 'Regional' && Pod.Name != 'Exception') {
            List <Account> listOfAccounts = [SELECT Id, BillingState, BillingPostalCode FROM Account WHERE RecordType.DeveloperName = 'Client' 
                                                                        AND IsPersonAccount = True AND  Cultural_Needs__c = FALSE AND BillingPostalCode != null AND Pod__c != :podId Limit 50000]; //ACEM-2 Added query limit
        
            List <Pod_Territory__c> listOfPodTerritories = [SELECT Id, StartingPostCode__c, EndingPostCode__c FROM Pod_Territory__c WHERE Pod__c =: podId];
            
            Set <Integer> listOfPinCodes = new Set <Integer>();
            listOfPinCodes = getAllBillingPostCodes(listOfPodTerritories);
            
            for (Account acc: listOfAccounts) {
                if (acc.BillingPostalCode != null) {
                    if (listOfPinCodes.contains(Integer.ValueOf(acc.BillingPostalCode))) {
                        listOfAccountsToBeProcessed.add(acc);
                    }
                }
            }
        } else if (Pod.Pod_Type__c == 'Regional' && Pod.Name == 'Exception') {    
            List <Account> listOfAccounts = [SELECT Id, BillingState, BillingPostalCode FROM Account WHERE RecordType.DeveloperName = 'Client' 
                                                                        AND IsPersonAccount = True AND  Cultural_Needs__c = FALSE AND Pod__c = null Limit 50000]; //ACEM-2 Added query limit
        
            List <Pod_Territory__c> listOfPodTerritories = [SELECT Id, StartingPostCode__c, EndingPostCode__c FROM Pod_Territory__c Limit 50000]; //ACEM-2 Added query limit
            
            Set <Integer> listOfPinCodes = new Set <Integer>();
            listOfPinCodes = getAllBillingPostCodes(listOfPodTerritories);
            
            for (Account acc: listOfAccounts) {
                if (acc.BillingPostalCode != null) {
                    if (!listOfPinCodes.contains(Integer.ValueOf(acc.BillingPostalCode))) {
                        listOfAccountsToBeProcessed.add(acc);
                    }
                }
                else if (acc.BillingPostalCode == null) {
                    listOfAccountsToBeProcessed.add(acc);
                }
            }
        }
        
        return listOfAccountsToBeProcessed;
    }

    /**
     * @description     Method to get set of all postcodes
     * @author          Animesh Chauhan
     * @param           listOfPodTerritories : list of Pod Territories
     * @return          set of billingCodes 
    **/
    public static Set<Integer> getAllBillingPostCodes(List<Pod_Territory__c> listOfPodTerritories) {
        Set <Integer> listOfAllBillingCodes = new Set <Integer>();
        for (Pod_Territory__c pTerritory : listOfPodTerritories) {
            
            Decimal startingNumber = pTerritory.StartingPostCode__c;
            
            while (startingNumber <= pTerritory.EndingPostCode__c) {
                listOfAllBillingCodes.add(Integer.ValueOf(startingNumber));
                startingNumber ++;
            } 
        }
        return listOfAllBillingCodes;
    }
    
    /* Wrapper class used in displaying count of records in Lightning component */
    public class RecordInfoWrapper {
        
        @AuraEnabled
        public Integer previousAccountsProcessedNumber;
        @AuraEnabled
        public Integer nextAccountsProcessedNumber;
        
        private RecordInfoWrapper(Integer previousAccountsProcessedNumber, Integer nextAccountsProcessedNumber) {
            this.previousAccountsProcessedNumber = previousAccountsProcessedNumber;
            this.nextAccountsProcessedNumber = nextAccountsProcessedNumber;
        }
    }
}