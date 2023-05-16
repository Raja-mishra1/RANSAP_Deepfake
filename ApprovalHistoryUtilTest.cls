@isTest
private class ApprovalHistoryUtilTest {
    @testSetup static void methodName() {
        Account newAccount = new Account(Name = 'Test Account', PlanManager__c = 'MPM');
        insert newAccount;
        Invoice__c inv = TestClassDataUtil.createInvoice();
        inv.PlanManager__c = 'MPM';
        inv.Status__c = 'Awaiting Client Approval';
        update inv;
    }
    @isTest static void isCurrentUserIdTest_SystemAdmin(){
        List<User> users = [select Id, FirstName, LastName FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        System.runAs(users.get(0)){
            boolean isAdmin = ApprovalHistoryUtil.isCurrentUserSystemAdmin(accounts.get(0).Id);
            System.assertEquals(true, isAdmin, 'The user was supposed to be found admin');
        }
       
    }

    @isTest static void isCurrentUserIdTest_NOT_SystemAdmin(){
        List<User> users = [select Id, FirstName, LastName FROM User WHERE Profile.Name != 'System Administrator' AND IsActive = true LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        System.runAs(users.get(0)){
            boolean isAdmin = ApprovalHistoryUtil.isCurrentUserSystemAdmin(accounts.get(0).Id);
            System.assertEquals(false, isAdmin, 'The user was not supposed to be found admin');
        }
       
    }

    @isTest static void processStepTest_EmptyWorkItems(){
        List<User> users = [select Id, FirstName, LastName FROM User WHERE Profile.Name != 'System Administrator' AND IsActive = true LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>();
        String retVal = ApprovalHistoryUtil.processStep( workItems, 'comments',users.get(0).Id, accounts.get(0).Id);

    }
    
    @isTest static void processStepTest_NotEmptyWorkItems(){
        List<User> users = [select Id, FirstName, LastName FROM User WHERE Profile.Name != 'System Administrator' AND IsActive = true LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>();
        workItems.add(new ProcessInstanceWorkitem(Id = '04i3h000001L5fGAAS'));
        try{
            String retVal = ApprovalHistoryUtil.processStep( workItems, 'comments',users.get(0).Id, accounts.get(0).Id);
        }catch(Exception e){

        }
    }

    @isTest static void reassignStepTest(){
        List<User> users = [SELECT Id, FirstName, LastName FROM User WHERE IsActive = true LIMIT 1];
        List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkitem>();
        workItems.add(new ProcessInstanceWorkitem(Id = '04i3h000001L5fGAAS'));
        try{
            ApprovalHistoryUtil.reassignStep(workItems, users.get(0).Id);
        }catch(Exception e){
        }
    }

    @isTest static void populateApprovalHistoryTest(){
        Invoice__c inv = new Invoice__c ();
        inv.PlanManager__c = 'MPM';
        inv.Status__c = 'Awaiting Client Approval';
        insert inv;
        List<Invoice__c> invoices = [SELECT Id, PlanManager__c FROM Invoice__c WHERE Id =:inv.Id];
        Set<Id> userIds = new Set<Id>();
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		app.setObjectId(invoices[0].id);
		Approval.ProcessResult result = Approval.process(app);

        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                            StepStatus,Comments,TargetObjectId,ActorId, Actor.Id, CreatedById,IsDeleted,IsPending  
                                                            ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                            OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                    FROM ProcessInstance where TargetObjectId =:invoices[0].Id order by CreatedDate DESC];

        for (ProcessInstance pr :  processInstances) {
            for (ProcessInstanceHistory step : pr.StepsAndWorkitems) {
                if (String.valueOf(step.OriginalActorId).startsWith('005')) {
                    UserIds.add(step.OriginalActorId);
                }
            }
        }
        Map<Id, User> UserMap = new Map<Id, User>(
            [SELECT Id, PlanManager__c FROM User WHERE Id IN :UserIds]);
        ApprovalHistoryController.ApprovalHistory retVal = ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, invoices[0].Id, invoices, UserMap);

    }

    @isTest static void populateApprovalHistoryRecord(){
        List<User> users = [SELECT Id, FirstName, LastName FROM User WHERE IsActive = true LIMIT 1];
        List<ApprovalHistoryController.ApprovalHistoryStep> approvalSteps = new List<ApprovalHistoryController.ApprovalHistoryStep>();
        approvalSteps.add(new ApprovalHistoryController.ApprovalHistoryStep( 'stepName','stepId', 1, DateTime.now(),'stepStatus', 'assignedTo', 'assignedToId', 'Comments'));
        ApprovalHistoryController.ApprovalHistory approvalHistoryToReturn = new ApprovalHistoryController.ApprovalHistory( approvalSteps,  false, true, true);
        ProcessInstanceHistory step = new ProcessInstanceHistory();
        ApprovalHistoryUtil.populateApprovalHistoryRecord(approvalHistoryToReturn, step,  true, users.get(0).Id, true);
        System.assertEquals(true, approvalHistoryToReturn.showRecall, 'The recall attribute is supposed to be true');
        System.assertEquals(true, approvalHistoryToReturn.isCurrentUserApprover, 'The isCurrentUserApprover attribute is supposed to be true');
        System.assertEquals(false, approvalHistoryToReturn.showSubmitForApproval, 'The showSubmitForApproval attribute is supposed to be false');
        
    }


}