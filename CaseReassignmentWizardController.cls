/**
 * @description       : 
 * @author            : Arman Alam
 * @group             : 
 * @last modified on  : 09-14-2022
 * @last modified by  : Arman Alam
**/
public class CaseReassignmentWizardController {
    @AuraEnabled
    public static ReassignmentMetadataContainer fetchReassignmentMetadataRecords(
        String planManagerValue 
    ) {
        try {
            ReassignmentMetadataContainer reassignmentmetadatacontainer = new ReassignmentMetadataContainer();
            List<Queue_Subtype_Mappings__mdt> queueuSubtypeList = new List<Queue_Subtype_Mappings__mdt>();

            /*planManager Conditions for Reassignment_Case_Configuration__mdt, 
            Queue_Subtype_Mappings__mdt, Queues__mdt */
            if (String.isNotBlank(planManagerValue) && planManagerValue.equalsIgnoreCase(NDSPConstants.MPM)) {
                reassignmentmetadatacontainer.queueMetadata = [SELECT Id, DeveloperName, MasterLabel
                                                              FROM Queues__mdt 
                                                              WHERE (NOT DeveloperName like 'NDSP%')];
                queueuSubtypeList = [SELECT Id, DeveloperName,  Queue_Label__c, Type__c, Sub_Type__c
                                    FROM Queue_Subtype_Mappings__mdt 
                                    WHERE (NOT DeveloperName like 'NDSP%')];
                reassignmentmetadatacontainer.reassignmentCaseMetdata = 
                                                    [SELECT Id, 
                                                    Field__r.QualifiedApiName,Field__r.MasterLabel, 
                                                    Is_Mandatory__c, Object__c, Owner_Type__c, 
                                                    SortOrder__c, Queue__c, DeveloperName, 
                                                    MasterLabel 
                                                    FROM Reassignment_Case_Configuration__mdt 
                                                    WHERE (NOT DeveloperName like 'NDSP%') 
                                                    ORDER BY SortOrder__c];
            } else if (String.isNotBlank(planManagerValue) && planManagerValue.equalsIgnoreCase(NDSPConstants.NDSP)) {
                reassignmentmetadatacontainer.queueMetadata = [SELECT Id, DeveloperName, MasterLabel
                                                              FROM Queues__mdt 
                                                              WHERE DeveloperName like 'NDSP%'];
                queueuSubtypeList = [SELECT Id, DeveloperName,  Queue_Label__c, Type__c, Sub_Type__c
                                    FROM Queue_Subtype_Mappings__mdt 
                                    WHERE DeveloperName like 'NDSP%'];
                reassignmentmetadatacontainer.reassignmentCaseMetdata = 
                                                    [SELECT Id, 
                                                    Field__r.QualifiedApiName,Field__r.MasterLabel, 
                                                    Is_Mandatory__c, Object__c, Owner_Type__c, 
                                                    SortOrder__c, Queue__c, DeveloperName, 
                                                    MasterLabel 
                                                    FROM Reassignment_Case_Configuration__mdt 
                                                    WHERE DeveloperName like 'NDSP%' 
                                                    ORDER BY SortOrder__c];
            } else {
                reassignmentmetadatacontainer.queueMetadata = [SELECT Id, DeveloperName, MasterLabel
                                                              FROM Queues__mdt];
                queueuSubtypeList = [SELECT Id, DeveloperName, Queue_Label__c, Type__c, Sub_Type__c
                                    FROM Queue_Subtype_Mappings__mdt];
                reassignmentmetadatacontainer.reassignmentCaseMetdata = 
                                                    [SELECT Id, 
                                                    Field__r.QualifiedApiName,Field__r.MasterLabel, 
                                                    Is_Mandatory__c, Object__c, Owner_Type__c, 
                                                    SortOrder__c, Queue__c, DeveloperName, 
                                                    MasterLabel 
                                                    FROM Reassignment_Case_Configuration__mdt 
                                                    ORDER BY SortOrder__c];
            }

            List<Group> listOfQueues = [SELECT DeveloperName, Name, Id 
                                        FROM Group 
                                        WHERE Type = 'Queue'];
            Map<String,Id> mapOfQueue = new Map<String,Id>();
            if(!listOfQueues.isEmpty()) {
                for(Group g : listOfQueues) {
                    mapOfQueue.put(g.DeveloperName, g.Id);
                }
            }
            reassignmentmetadatacontainer.queueList = new List<ReassignmentMetadataContainer.QueueWrapper>();
            for (Queues__mdt q : reassignmentmetadatacontainer.queueMetadata) {
                if(mapOfQueue.containsKey(q.DeveloperName)) {
                    Id queueId = mapOfQueue.get(q.DeveloperName);
                    reassignmentmetadatacontainer.queueList.add
                        (
                            new reassignmentmetadatacontainer.QueueWrapper(queueId,q.Id,q.DeveloperName,
                            q.MasterLabel)
                        );
                }
            }
            reassignmentmetadatacontainer.queueSubtypeList = new List<ReassignmentMetadataContainer.QueueSubTypeWrapper>();
            for (Queue_Subtype_Mappings__mdt qRec : queueuSubtypeList) {
                reassignmentmetadatacontainer.queueSubtypeList.add
                    (
                        new reassignmentmetadatacontainer.QueueSubTypeWrapper(qRec.Queue_Label__c,
                        qRec.Type__c, 
                        qRec.Sub_Type__c)
                    );
            }
            return reassignmentmetadatacontainer;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Case getCase(Id caseId) {
        Case caseObj = [SELECT Id, Status, Client__r.Name FROM Case WHERE ID =: caseId];
        return caseObj;
    }

    /**
    * @description  Method to get the records of User/Queue
    * @author       Rohit Tikoo
    * @param        userOrGroupObjName  : Name of the Object - User/Group
    *               objectName : Name of the object - Case / Invoice
    *               searchString : User/Queue Name searched in component
    *               planManagerValue : Attribute value (MPM/NDSP/Null)
    * @return       List<OwnerUpdateComponentCtrlHelper.RecordsData> : Wrapper List
    **/
    @AuraEnabled 
    public static List<OwnerUpdateComponentCtrlHelper.RecordsData> fetchRecords( 
        String userOrGroupObjName, 
        String objectName, 
        String searchString, 
        String planManagerValue 
    ) {
        List<OwnerUpdateComponentCtrlHelper.RecordsData> recordsDataList = 
            OwnerUpdateComponentCtrlHelper.fetchRecords
            (
                userOrGroupObjName, objectName, searchString, planManagerValue
            );
        return recordsDataList;
    }

    @AuraEnabled
    public static Map<Id,String> getRelatedRecords(List <String> relatedRecordIdList){
        try {
            Map<Id, String> relatedRecordIdNameMap = new Map<Id, String>(); 
            Set<String> objectNameSet = new Set<String>();
            String query = 'SELECT Id, Name ';

            //Set<String> accoundIdSet = new Set<String>();
            Set <Id> accoundIdSet = new Set <Id> (); 
            Set <Id> contactIdSet = new Set <Id> ();

            String accountQuery = '';
            String contactQuery = '';

            for (String strVar : relatedRecordIdList) {
                String objectName = SchemaGlobalDescribe.findObjectNameFromRecordIdPrefix(strVar);
                if (objectName == 'Account') {
                    accoundIdSet.add((Id)strVar);
                } else if (objectName == 'Contact') {
                    contactIdSet.add((Id)strVar);
                }
                if (objectName == 'Account' && accountQuery == '') {
                    accountQuery = query + ' FROM ' + objectName;
                } else if (objectName == 'Contact') {
                    contactQuery = query + ' FROM ' + objectName;
                }
            }
            if (accountQuery != '' ) {
                accountQuery = accountQuery+ ' WHERE id IN: accoundIdSet Limit 50000'; //ACEM-2 added query limit
                List<Account> accountNameList = Database.query(accountQuery);
                for (Account accRec : accountNameList) relatedRecordIdNameMap.put(accRec.Id,accRec.Name);
            }
            if (contactQuery != '') {
                contactQuery = contactQuery + ' WHERE id =: contactIdSet Limit 50000'; //ACEM-2 added query limit
                List<Contact> contactNameList = Database.query(contactQuery);
                for (Contact accRec : contactNameList) relatedRecordIdNameMap.put(accRec.Id,accRec.Name);
            }
            
            return relatedRecordIdNameMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*This method updates the Case records*/
    @AuraEnabled
    public static List<Case> setCaseRecords(List<Case> caseList){//, Id caseId, Integer limitCount
        List<Case> updatedCaseList = new List<Case>();
        //Sprint-8 [SFDC-977] Starts
        List<FeedItem> lstFeedItem = new List<FeedItem>();       
        List<Case> oldCaseList = [SELECT Id, CaseNumber, Case_Owner__c,Re_Assignment_Notes__c FROM Case WHERE Id IN :caseList];                                
            
        if (!caseList.isEmpty()) {
            Database.SaveResult[] srList = Database.update(caseList, false);   
            // Iterate through each returned result by the method
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    updatedCaseList = [SELECT Id, CaseNumber, Case_Owner__c,Re_Assignment_Notes__c FROM Case WHERE Id IN :caseList]; 
                    //create the feedItem //Sprint-8 [SFDC-977]
                    /* String message = UserInfo.getName()+' updated the with comments - '; 
                    ReconnectionsUtil.createChatterFeedOnCase(message, updatedCaseList); */
                    if (!oldCaseList.isEmpty() && !updatedCaseList.isEmpty() && oldCaseList[0].Re_Assignment_Notes__c != updatedCaseList[0].Re_Assignment_Notes__c) {
                        for (Case caseRec : updatedCaseList) {
                            FeedItem post = new FeedItem();
                            post.ParentId = caseRec.Id; 
                            post.Body = UserInfo.getName()+' updated the owner to '+caseRec.Case_Owner__c+' with the following re-assignment notes: \n'+caseRec.Re_Assignment_Notes__c;
                            lstFeedItem.add(post);
                        }
                        try{
                            insert lstFeedItem;
                        } catch(exception e){
                            system.debug('error for lstFeedItem===='+e);
                        }
                    }
                } else {
                    for (Database.Error objErr : sr.getErrors()) {
                        System.debug('The following error has occurred.');                            
                        System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                        throw new AuraHandledException(objErr.getMessage());
                    }
                }
            }            
        }


        return updatedCaseList;
    }

    /*Get picklist value*/
    @AuraEnabled(cacheable=true)
    public static Map <String,Map<String, List<ReconnectionsUtil.PicklistValuesWrapper>>> getFieldsPicklistValuesMap(String json)
    {
        return ReconnectionsUtil.getFieldsPicklistValuesMap(json); 
    }

    /**
    * @description  Called at initialize to get the current values of case
    * @author       Rohit Tikoo
    * @param        caseId  : Id of case Record
    * @return       CaseData : Wrapper obj
    **/
    @AuraEnabled
    public static CaseData retrieveCaseRecord(Id caseId){
        CaseData caseDataWrapper = new CaseData();
        caseDataWrapper.caseRecord = [SELECT Sub_Type__c, Id, Type, Status, PlanManager__c, 
                                     Client__c, Client__r.PlanManager__c, Provider__c, ContactId, 
                                     OwnerId, Re_Assignment_Notes__c, CaseNumber
                                     FROM Case 
                                     WHERE Id =: caseId];
        caseDataWrapper.planManagerValue = OwnerUpdateComponentCtrlHelper.getPlanManagerValue(
            new List<sObject> {caseDataWrapper.caseRecord},
            caseDataWrapper.caseRecord.Client__r.PlanManager__c
        );
        return caseDataWrapper;
    }

    /**
    * @description  Wrapper class to Case record data and Computed PlanManager Value
    * @author       Rohit Tikoo
    **/
    public class CaseData{
        @AuraEnabled 
        public String planManagerValue;

        @AuraEnabled 
        public Case caseRecord;
    }

}