/**
 * @description       : 
 * @author            : Aman Agarwal
 * @group             : 
 * @last modified on  : 04-05-2022
 * @last modified by  : Aman Agarwal
**/
public with sharing class CaseTriggerHandler {

    private static Boolean SENT_TO_CLAIMS_AUTOMATION = false;

    public static final Group ACCOUNTS_QUEUE {
        get {
            if (ACCOUNTS_QUEUE == null) {
                ACCOUNTS_QUEUE = [SELECT Id FROM Group WHERE Name = 'Accounts'];
            }

            return ACCOUNTS_QUEUE;
        }
        private set;
    }
    
    public static final Group OCR_CLAIM_QUEUE {
        get {
            if (OCR_CLAIM_QUEUE == null) {
                OCR_CLAIM_QUEUE = [SELECT Id FROM Group WHERE Name = 'OCR Claim'];
            }

            return OCR_CLAIM_QUEUE;
        }
        private set;
    }

    /*
    @author:        Prithviraj Deshmukh
    @company:       Cloudwerx
    @description:   Use this method to query Relationships queue ID in parent org and use in code.
    */
    public static final Group RELATIONSHIP_QUEUE {
        get {
            if (RELATIONSHIP_QUEUE == null) {
                RELATIONSHIP_QUEUE = [SELECT Id FROM Group WHERE Name = 'Relationships'];
            }

            return RELATIONSHIP_QUEUE;
        }
        private set;
    }

    /*
    @author:        Rohit Tikoo
    @company:       Cloudwerx
    @description:   Use this method to query NDSP Relationships queue ID in parent org and use in code.
    */
    public static final Group NDSP_RELATIONSHIP_QUEUE {
        get {
            if (NDSP_RELATIONSHIP_QUEUE == null) {
                NDSP_RELATIONSHIP_QUEUE = [SELECT Id FROM Group WHERE DeveloperName = 'NDSP_Relationships'];
            }

            return NDSP_RELATIONSHIP_QUEUE;
        }
        private set;
    }
    
    public static void sendOCRClaimsToClaimsAutomationService(List<Case> cases) {
        //putting this hacky flag back in- we're literally getting two trigger calls in the same transaction for the object
        //i suspect this is because of the UFHT package
        if (SENT_TO_CLAIMS_AUTOMATION) {
            return;
        }

        SENT_TO_CLAIMS_AUTOMATION = true;

        List<Id> ocrCases = new List<Id>();

        for (Case c : cases) {
            ocrCases.add(c.Id);
        }

        if (!ocrCases.isEmpty() && !Test.isRunningTest()) {
            ClaimsAutomationService.sendOCRCases(ocrCases);
        }
    }
    
    @future 
    public static void updateCaseonSurvey(Map<Id, Id> caseSurveyMapping) {
        List<Survey_Response__c> detractorSurveys = [SELECT Id, Detractor_Case__c FROM Survey_Response__c WHERE Id IN :caseSurveyMapping.keySet()];
        for (Survey_Response__c survey : detractorSurveys) {
            if (caseSurveyMapping.containsKey(survey.Id)) {
                survey.Detractor_Case__c =  caseSurveyMapping.get(survey.Id);
            }
        }
        if (detractorSurveys.size() > 0) {
            update detractorSurveys;
        }
    }

    /*
    @author     :   Prithviraj Deshmukh
    @company    :   Cloudwerx
    @ticket     :   [BT-241][BT-105]
    @description:   Method to update PodSkillRequirement on cases if client is changed/removed
    */
    public static void udpatePodSkillRequirement(List<Case> cases) {
        List<String> relatedAccList = new List<String>();
        Map<String,String> clientSkillMap = new Map<String,String>();
        for (Case c : cases) {
            if (!String.isBlank(c.Client__c)) {
                relatedAccList.add(c.Client__c);
            }
        }
        if (!relatedAccList.isEmpty()) {
            List<Account> caseAccounts = [SELECT Id, Pod__c, Pod__r.Pod_Skill_New__c
                                            FROM Account WHERE Id IN :relatedAccList];
            for (Account acc:caseAccounts) {
                if (acc.Pod__c != null && !String.isBlank(acc.Pod__r.Pod_Skill_New__c)) {
                    clientSkillMap.put(acc.Id,acc.Pod__r.Pod_Skill_New__c);
                }
            }
        }
        for (Case c : cases) {
            if (clientSkillMap.containsKey(c.Client__c)) {
                c.PodSkillRequirement__c = clientSkillMap.get(c.Client__c);
            } else {
                c.PodSkillRequirement__c = '';
            }
        }
    } 
    
    /*
    @author     :   Sonali Bhat
    @company    :   Cloudwerx
    @ticket     :   [SFDC-613]
    @description:   Method to rollup count of open reconnection cases on Account on insert.
    */
    public static void updateCountOfCasesOnAfterInsert(List<Case> newCases) {
        Set<Id> setOfAccountIds = new Set<Id>();
        Map<Id,Integer> mapOfAccountWithCase = new Map<Id,Integer>();
        for(Case caseObj : newCases) {
            if(caseObj.Client__c != null && caseObj.Status != 'Closed') {
                setOfAccountIds.add(caseObj.Client__c);
            }
        }
        List<Account> listOfAccountstoUpdate = new List<Account>();
        if(!setOfAccountIds.isEmpty()) {
           mapOfAccountWithCase = getCountOfCases(setOfAccountIds);
            for(Id accObj : setOfAccountIds) {
              if(mapOfAccountWithCase.containsKey(accObj)) {
                   Account acc = new Account();
                   acc.Id = accObj;
                   acc.Count_of_Open_Reconnection_Cases__c = mapOfAccountWithCase.get(accObj);
                  listOfAccountstoUpdate.add(acc);
                }
            } 
        }
        if(!listOfAccountstoUpdate.isEmpty()) {
           try {
               update listOfAccountstoUpdate;
            } catch(DmlException ex) {
               System.debug('Cannot update count of open reconnection cases on Account on insert of Case'+ex);
            } 
        }                             
    }

    // method to rollup count of open reconnection cases on Account on update
    public static void updateCountOfCasesOnAfterUpdate(Map<Id,Case> oldCasesMap, List<Case> newCaseList) {
        Set<Id> setOfAccountIds = new Set<Id>();
        Map<Id,Integer> mapOfAccountWithCase = new Map<Id,Integer>();
        for(Case caseObj : newCaseList) {
            if((caseObj.Client__c !=  oldCasesMap.get(caseObj.Id).Client__c) 
                    || (caseObj.Status != oldCasesMap.get(caseObj.Id).Status) 
                    || (caseObj.Subject != oldCasesMap.get(caseObj.Id).Subject)
                    || (caseObj.Sub_Type__c != oldCasesMap.get(caseObj.Id).Sub_Type__c)) {
                setOfAccountIds.add(caseObj.Client__c);
                setOfAccountIds.add(oldCasesMap.get(caseObj.Id).Client__c);
                
            }
        }
        setOfAccountIds.remove(null);
        List<Account> listOfAccountstoUpdate = new List<Account>();
        if(!setOfAccountIds.isEmpty()) {
            mapOfAccountWithCase = getCountOfCases(setOfAccountIds);
            for(Id accObj : setOfAccountIds) {
                if(mapOfAccountWithCase.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Count_of_Open_Reconnection_Cases__c = mapOfAccountWithCase.get(accObj);
                    listOfAccountstoUpdate.add(acc);
                }
                else if(!mapOfAccountWithCase.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Count_of_Open_Reconnection_Cases__c =0;
                    listOfAccountstoUpdate.add(acc);
                }
            } 
        }
        if(!listOfAccountstoUpdate.isEmpty()) {
            try {
                update listOfAccountstoUpdate;
            } catch(DmlException ex) {
                System.debug('Cannot update count of open reconnection cases on Account on update of Case'+ex);
            } 
        }                             
    }

     // method to rollup count of open reconnection cases on Account on delete
    public static void updateCountOfCasesOnAfterDelete(List<Case> oldCaseList) {
        Set<Id> setOfAccountIds = new Set<Id>();
        Map<Id,Integer> mapOfAccountWithCase = new Map<Id,Integer>();
        for(Case caseObj : oldCaseList) {
            if(caseObj.Client__c != null && caseObj.Status != 'Closed') {
                setOfAccountIds.add(caseObj.Client__c);
            }
        }
        List<Account> listOfAccountstoUpdate = new List<Account>();
        if(!setOfAccountIds.isEmpty()) {
            mapOfAccountWithCase = getCountOfCases(setOfAccountIds);
            for(Id accObj : setOfAccountIds) {
                if(mapOfAccountWithCase.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Count_of_Open_Reconnection_Cases__c = mapOfAccountWithCase.get(accObj);
                    listOfAccountstoUpdate.add(acc);
                }
                else if(!mapOfAccountWithCase.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Count_of_Open_Reconnection_Cases__c =0;
                    listOfAccountstoUpdate.add(acc);
                }
            } 
        }
        if(!listOfAccountstoUpdate.isEmpty()) {
            try {
                update listOfAccountstoUpdate;
            } catch(DmlException ex) {
                System.debug('Cannot update count of open reconnection cases on Account on delete of Case'+ex);
            } 
        }                             
    }

    // method to do the aggregate query on Case Object
    public static Map<Id,Integer> getCountOfCases(Set<Id> setOfAccountIds) {
        Map<Id, Integer> mapOfAccWithCountOfCases = new Map<Id,Integer>();
        List<AggregateResult> AggregateResultList = [Select Client__c, Count(Id) CountOfCases
                                                     FROM Case 
                                                     WHERE Client__c IN :setOfAccountIds
                                                     AND Status != 'Closed' AND
                                                     (Subject LIKE '%Reconnection%' OR Subject LIKE '%Reconnect%'
                                                     OR (Type = 'Client Setup/Admin' AND Sub_Type__c = 'Client Reconnection'))
                                                     GROUP BY Client__c];
           
        if(AggregateResultList != null && AggregateResultList.size()>0) {
            for(AggregateResult ar : AggregateResultList) {
                mapOfAccWithCountOfCases.put((Id)ar.get('Client__c'),(Integer)ar.get('CountOfCases'));
            }
        }

        return mapOfAccWithCountOfCases;
    }
    // Sprint-7 [BT-613] End     
    
    /*
    @author     :   Prithviraj Deshmukh
    @company    :   Cloudwerx
    @ticket     :   [SFDC-980]
    @description:   updatePSRRecord updates the PSR record for a case which is 
                    assigned to Relationship queue.
                    Method is intended to delete existin PSR records for the case 
                    and create new PSR records using SkillsBasedRouting.routeUsingSkills.
    */
    public static void updatePSRRecord(List<Case> casesToUpdatePSR) {
        Set<Id> setOfCaseIds = new Set<Id>();
        
        for(Case caseObj : casesToUpdatePSR) {
            setOfCaseIds.add(caseObj.Id);
        }

        if(!setOfCaseIds.isEmpty()) {
                ReconnectionsUtil.deletePSR(setOfCaseIds);
                if(!Test.isRunningTest()) {
                    SkillsBasedRouting.routeUsingSkills(casesToUpdatePSR); 
                }
        }
    }
    
    /**
    * @author: Yash Bhalerao
	* @company: Cloudwerx
    * @description : This method updates the CDL for all the ContentNotes related to the updated Case
    * @param   :    List of Old and Updated Cases for which all related ContentNote ContentDocumentLinks 
    * 				need to be updated
    * @return  :   ``
    * @ticket  :  [CS-104]
    **/
    public static void updateCDLForUpdatedCase(List<Case> listOfOldCases, List<Case> listOfUpdatedCases) {
        Set<Id> linkedEntityIds = new Set<Id>();
        Set<Id> setOfCDId = new Set<Id>();
        List<ContentDocumentLink> listOfCDLWithoutCase = new List<ContentDocumentLink>();
        List<ContentDocumentLink> listOfCDLToDelete = new List<ContentDocumentLink>();
        List<ContentDocumentLink> listOfCDLToInsert = new List<ContentDocumentLink>();
        Map<Id,Case> mapOfIdAndCase = new Map<Id,Case>();
        Map<Id,Case> mapofCDANDCase = new Map<Id,Case>();

        mapOfIdAndCase.putAll(listOfUpdatedCases);
        
        for(Case oldCase : listOfOldCases) {
            linkedEntityIds.add(oldCase.Id);
            linkedEntityIds.add(oldCase.Client__c);
            linkedEntityIds.add(oldCase.Provider__c); 
        }
        
        List<ContentDocumentLink> listOfCDL = [SELECT Id, ContentDocumentId, LinkedEntityId
                                               FROM ContentDocumentLink
                                               WHERE ContentDocument.FileType = 'SNOTE'
                                               AND LinkedEntityId IN : linkedEntityIds];
        
        for(ContentDocumentLink cdlRecord : listOfCDL) {
            if(mapOfIdAndCase.containsKey(cdlRecord.LinkedEntityId)) {
                Case caseRecord = mapOfIdAndCase.get(cdlRecord.LinkedEntityId);
                mapofCDANDCase.put(cdlRecord.ContentDocumentId, caseRecord);
                
                setOfCDId.add(cdlRecord.ContentDocumentId);
            }
            else {
                listOfCDLWithoutCase.add(cdlRecord);
            }
        }
        
        for(ContentDocumentLink cdl : listOfCDLWithoutCase) {
            if(setOfCDId.contains(cdl.ContentDocumentId)) {
                listOfCDLToDelete.add(cdl);
            }
        }
        
        //Call method from 'without sharing' class to delete list of CDL
        ReconnectionsUtil.deleteCDL(listOfCDLToDelete);
        
        for(Id cdId : mapofCDANDCase.keyset()) {
            Case caseRecord = mapofCDANDCase.get(cdId);
            
            if(caseRecord.Client__c != null) {
                ContentDocumentLink clientLink = ReconnectionsUtil.createCDL(cdId, caseRecord.Client__c);
                listOfCDLToInsert.add(clientLink);
            }
                    
            if(caseRecord.Provider__c != null) {
                ContentDocumentLink providerLink = ReconnectionsUtil.createCDL(cdId, caseRecord.Provider__c);
                listOfCDLToInsert.add(providerLink);
            }
        }

        try {
            insert listOfCDLToInsert;
        } 
        catch (Exception e) {
            System.debug('Cannot insert : ' + e.getMessage());
        }
    }
    
    /**
    * @author: Yash Bhalerao
	* @company: Cloudwerx
    * @description : This method inserts CDLs on Case Client and Provider when the Case is Closed
    * 					if not already present
    * @param   :    List of Closed Cases
    * @return  :   ``
    * @ticket  :  [CS-104]
    **/
    public static void insertCDLForClosedCases(Set<Case> setOfClosedCases) {
        Set<Id> setOfClosedCaseId = new Set<Id>();
        Set<Integer> setOfCDLIndexToRemove = new Set<Integer>();
        Set<Id> setOflinkedEntityIds = new Set<Id>();
        List<ContentDocumentLink> listOfNewCDL = new List<ContentDocumentLink>();
        List <ContentDocumentLink> listOfCDLToInsert = new List <ContentDocumentLink>();
        Map<Id,Case> mapOfIdAndCase = new Map<Id,Case>();
        Map<Id,Case> mapOfIdAndClosedCase = new Map<Id,Case>();
        Map<Id,Map<Id,Id>> existingCDLMap = new Map<Id,Map<Id,Id>>();
        
        
        for(Case caseRecord : setOfClosedCases) {
            setOfClosedCaseId.add(caseRecord.Id);
            setOflinkedEntityIds.add(caseRecord.Id);
            setOflinkedEntityIds.add(caseRecord.Client__c);
            setOflinkedEntityIds.add(caseRecord.Provider__c);
            mapOfIdAndClosedCase.put(caseRecord.Id, caseRecord);
        }
        
        List<ContentDocumentLink> listOfCDL = [SELECT Id, LinkedEntityId, ContentDocumentId
                                               FROM ContentDocumentLink
                                               WHERE LinkedEntityId IN : setOfClosedCaseId
                                               AND ContentDocument.FileType = 'SNOTE'];
        
        if(listOfCDL.size() > 0) {
            for(ContentDocumentLink cdlRecord : listOfCDL) {
                if(mapOfIdAndClosedCase.containsKey(cdlRecord.LinkedEntityId)) {
                    Case caseRecord = mapOfIdAndClosedCase.get(cdlRecord.LinkedEntityId);
                    mapofIdAndCase.put(cdlRecord.ContentDocumentId, caseRecord);
                }
            }
        }
        
        for(Id documentId : mapofIdAndCase.keyset()) {
            Case caseRecord = mapofIdAndCase.get(documentId);
            
            if(caseRecord.Client__c != null) {
                ContentDocumentLink clientLink = ReconnectionsUtil.createCDL(documentId, caseRecord.Client__c);
                listOfNewCDL.add(clientLink);
            }
                    
            if(caseRecord.Provider__c != null) {
                ContentDocumentLink providerLink = ReconnectionsUtil.createCDL(documentId, caseRecord.Provider__c);
                listOfNewCDL.add(providerLink);
            }
        }
        
        List<ContentDocumentLink> listOfExistingCDL = [SELECT Id, ContentDocumentId, 
                                                       LinkedEntityId, ContentDocument.FileType
                                                       FROM ContentDocumentLink
                                                       WHERE ContentDocument.FileType = 'SNOTE'
                                                       AND LinkedEntityId IN : setOflinkedEntityIds];

        for(ContentDocumentLink existingCDL : listOfExistingCDL) {
            Map<Id,Id> existingCDAndLinked = new Map<Id,Id>();
            existingCDAndLinked.put(existingCDL.ContentDocumentId, existingCDL.LinkedEntityId);
            
            existingCDLMap.put(existingCDL.Id, existingCDAndLinked);
        }
        
        for(ContentDocumentLink newCDL : listOfNewCDL) {
            Map<Id,Id> newCDAndLinked = new Map<Id,Id>();
            newCDAndLinked.put(newCDL.ContentDocumentId, newCDL.LinkedEntityId);
            
            if(existingCDLMap.values().contains(newCDAndLinked)) {
                setOfCDLIndexToRemove.add(listOfNewCDL.indexOf(newCDL));
            }
        }

        for(Integer i = 0; i < listOfNewCDL.size(); i++) {
            if(!setOfCDLIndexToRemove.contains(i)) {
                listOfCDLToInsert.add(listOfNewCDL[i]);
            }
        }   

        if(listOfCDLToInsert.size() > 0) {
            try {
            	insert listOfCDLToInsert;
            } 
            catch (Exception e) {
                System.debug('Cannot insert : ' + e.getMessage());
            }
        }
    }
}