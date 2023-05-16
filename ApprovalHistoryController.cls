public with sharing class ApprovalHistoryController {

    public static final String APPROVE_ACTION = 'Approve';
    public static final String REJECT_ACTION = 'Reject';
    public static final String RECALL_ACTION = 'Removed';
    
    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> searchUsers(String searchTerm) {
        // Prepare query paramters
        searchTerm += '*';

        // Execute search query
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                User(Id, FirstName, LastName)
            LIMIT :ApprovalHistoryUtil.MAX_RESULTS 
        ];

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Accounts & convert them into LookupSearchResult
        String userIcon = 'standard:user';
        User[] users = (List<User>) searchResults[0];
        for (User currUser : users) {
            results.add(
                new LookupSearchResult(
                    currUser.Id,
                    'User',
                    userIcon,
                    currUser.FirstName + ' ' + currUser.LastName,
                    ''
                )
            );
        }

        // Optionnaly sort all results on title
        results.sort();

        return results;
    }

    @AuraEnabled
    public static String processStep(
        String recordId, 
        String objectAPIName, 
        String comments, 
        String nextApproverId, 
        String action
    ) {
        String query = 'SELECT PlanManager__c FROM ' +objectAPIName+ ' WHERE Id =\'' +recordId+'\'';
        List <SObject> listOfRecords = Database.query(query);
        String queueName = 
            NDSPConstants.NDSP.equalsIgnoreCase((String)listOfRecords[0]?.get('PlanManager__c')) ?
            'NDSP Relationships' : 'Relationships';
        List<Group> queue = [SELECT Id FROM Group WHERE Type = 'Queue' 
                                AND Name =: queueName
                            ];
        List<ProcessInstanceWorkitem> workItems = [
            SELECT Id, ProcessInstanceId 
            FROM ProcessInstanceWorkitem 
            WHERE ProcessInstance.TargetObjectId = :recordId AND 
                  (ActorId IN: queue OR 
                  ActorId =: ApprovalHistoryUtil.currentUserId) // [TTP-1564] Added this condition
        ];

        return ApprovalHistoryUtil.processStep(workItems,comments, nextApproverId,  action);
    }

    @AuraEnabled
    public static void reassignStep(String recordId, String newActorId ){
        List<ProcessInstanceWorkItem> workItemList = [SELECT ActorId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = : recordId];
        ApprovalHistoryUtil.reassignStep(workItemList, newActorId);
    }


    @AuraEnabled
    public static String submitForApproval(String recordId, String comments, String nextApproverId){
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(comments);
        if(!String.isBlank(nextApproverId)){
            req.setNextApproverIds(new Id[] {nextApproverId});
        }
        req.setObjectId(recordId);
        
        // Submit on behalf of a specific submitter
        req.setSubmitterId(ApprovalHistoryUtil.currentUserId); 
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req);
        
        return JSON.serialize(result);
        
    }


    @AuraEnabled (cacheable=true)
    public static ApprovalHistory getApprovalHistory(String recordId, String objectAPIName){  
        
        Set<Id> UserIds = new Set<Id>();
        Map<Id, User> mapOfUserObject ;                  
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                            StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                            ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                            OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                    FROM ProcessInstance where TargetObjectId =:recordId order by CreatedDate DESC];                                                                         
  
        for (ProcessInstance pr :  processInstances) {
            for (ProcessInstanceHistory step : pr.StepsAndWorkitems) {
                if (String.valueOf(step.OriginalActorId).startsWith('005')) {
                    UserIds.add(step.OriginalActorId);
                }
            }
        }
        if (UserIds?.size() > 0) {
            mapOfUserObject = new Map<Id, User>([SELECT Id, PlanManager__c FROM User WHERE Id IN :UserIds]);
        }

                                                
        String query = 'SELECT PlanManager__c FROM ' +objectAPIName+ ' WHERE Id =\'' +recordId+'\'';
        List <SObject> listOfRecords = Database.query(query);

        return ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, recordId, listOfRecords, mapOfUserObject);   

                                                                         
    }

    public class ApprovalHistoryStep{
        @AuraEnabled
        public Integer indexNo {get;set;}
        @AuraEnabled  
        public String stepName {get;set;}  
        @AuraEnabled  
        public String stepUrl {get;set;}
        @AuraEnabled  
        public DateTime createdDate {get;set;}   
        @AuraEnabled  
        public String stepStatus {get;set;}  
        @AuraEnabled  
        public String assignedTo {get;set;}   
        @AuraEnabled  
        public String assignedToUrl {get;set;}
        @AuraEnabled
        public String comments {get;set;}
        
        public ApprovalHistoryStep(
            String stepName,
            String stepId,
            Integer indexVal,
            DateTime createdDate, 
            String stepStatus,
            String assignedTo,
            String assignedToId,
            String comments )  
        { 
            this.indexNo = indexVal;
            this.stepName = stepName;
            this.stepUrl = '/' + stepId;
            this.createdDate = createdDate;
            this.assignedTo = assignedTo;  
            this.assignedToUrl = '/'+assignedToId;
            this.comments = comments;

            if(stepStatus == ApprovalHistoryUtil.STATUS_STARTED){
                this.stepStatus = ApprovalHistoryUtil.STATUS_SUBMITTED;
            }else if(stepStatus == ApprovalHistoryUtil.STATUS_REMOVED){
                this.stepStatus = ApprovalHistoryUtil.STATUS_RECALLED;
            }else{
                this.stepStatus = stepStatus;
            }
            
        } 
    }

    public class ApprovalHistory{
        @AuraEnabled
        public List<ApprovalHistoryStep> approvalSteps;
        @AuraEnabled
        public String approvalStepsSize;
        @AuraEnabled 
        public boolean isCurrentUserApprover; 
        @AuraEnabled 
        public boolean showRecall;  //Modify All Data" permission or "Modify All" on the object level
                                    // system admin and submitter(if it says so on the approval process)
                                        //SELECT Name FROM Profile WHERE PermissionsModifyAllData = true
                                    //query permission sets with modify all or modify all for object and see if curr user has them

        @AuraEnabled 
        public boolean showSubmitForApproval; 
        public ApprovalHistory(List<ApprovalHistoryStep> approvalSteps, boolean isCurrentUserApprover, boolean isSubmitForApproval, boolean showRecall){
            this.approvalSteps = approvalSteps;
            this.isCurrentUserApprover = isCurrentUserApprover; 
            //this.approvalStepsSize = moreThan6Steps ? '6+' : string.valueOf(approvalSteps.size());
            this.showSubmitForApproval = isSubmitForApproval;
            this.showRecall = showRecall;
        }
    }


}