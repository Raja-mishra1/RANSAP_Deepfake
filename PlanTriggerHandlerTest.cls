/**
 * Class Name: PlanTriggerHandlerTest
 * Description: Test class for handler PlanTriggerHandler
 * Created By: Cloudwerx
 * Created Date: 18/05/2020
 */
@IsTest
private class PlanTriggerHandlerTest {

    private static final String TEST_ABN_NUMBER = '51824753556';
    
   @testSetup static void setup() {
        List <RecordType> accountListRecordType = [SELECT Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Client'];    
        insert new Reconnection_Trigger_Configuration__c(Plan_Trigger_Activated__c = True, MilestoneCreationMethodActivated__c = true); // create custom setting 
        List <Milestone_Configurations__mdt> listOfMilestoneData = [SELECT QualifiedApiName, MasterLabel, Sort_Order__c, Milestone_Type__c
                                                                     FROM Milestone_Configurations__mdt ORDER BY Sort_Order__c];
        // Create common test accounts
        Pod__c qldPod = new Pod__c(Name = 'Queensland', Pod_Type__c = 'Regional');
        insert qldPod;
        List<Account> testAccts = new List<Account>();
        for(Integer i=0;i<6;i++) {
            testAccts.add(new Account(FirstName = 'TestAcct'+i, LastName = 'LastName', Status__c = 'Active',
                                 NDIS__c = '43567846'+i, BillingPostalCode = '4000', Pod__c = qldPod.Id, RecordTypeId = accountListRecordType[0].Id));
        }
        insert testAccts;      
        
        Plan__c testPlan = new Plan__c(Name = 'TestPlan1', Client_Name__c = testAccts[0].Id, Plan_Start_Date__c = System.today(),
                                                Plan_End_Date__c = System.today().addDays(5), PlanManager__c = 'MPM');
        Plan__c testPlan1 = new Plan__c(Name = 'TestPlan1', Client_Name__c = testAccts[1].Id, Plan_Start_Date__c = System.today(),
                                        Plan_End_Date__c = System.today(), PlanManager__c = 'MPM');
        insert testPlan;
        insert testPlan1;
    }

    @isTest 
    static void testMethodInsertPlansOfSameClient() {
        List <Account> testAcctsList = [SELECT Id FROM Account LIMIT 10];
        List<Plan__c> listOfPlansInsert = new List<Plan__c>();
        Plan__c Plan1 = new Plan__c(Name = 'One Day Plan', Client_Name__c = testAcctsList[1].Id, Plan_Start_Date__c = System.today().addDays(5),
                                                Plan_End_Date__c = System.today().addDays(6),Invalid_1_Day_Plan__c = false, PlanManager__c = 'MPM');
        listOfPlansInsert.add(Plan1);
        Plan__c Plan2 = new Plan__c(Name = 'One Day Plan', Client_Name__c = testAcctsList[1].Id, Plan_Start_Date__c = System.today().addDays(5),
                                                Plan_End_Date__c = System.today().addDays(6),Invalid_1_Day_Plan__c = false, PlanManager__c = 'MPM');
        
        listOfPlansInsert.add(Plan2);
        Test.startTest();
        DmlException expectedException;
        try {
            insert listOfPlansInsert;
        }
        catch(DmlException ex){
            expectedException = ex;
        }
        
        Test.stopTest();
        System.assertNotEquals(null, expectedException,'An unexpected error message was returned');
    }
    
    @isTest 
    static void testMethodInsertPlansOfSameClientNDSP() {
        List <Account> testAcctsList = [SELECT Id FROM Account LIMIT 10];
        List<Plan__c> listOfPlansInsert = new List<Plan__c>();
        Plan__c Plan1 = new Plan__c(Name = 'One Day Plan', Client_Name__c = testAcctsList[1].Id, Plan_Start_Date__c = System.today().addDays(5),
                                                Plan_End_Date__c = System.today().addDays(6),Invalid_1_Day_Plan__c = false, PlanManager__c = 'NDSP');
        listOfPlansInsert.add(Plan1);
        Plan__c Plan2 = new Plan__c(Name = 'One Day Plan', Client_Name__c = testAcctsList[1].Id, Plan_Start_Date__c = System.today().addDays(5),
                                                Plan_End_Date__c = System.today().addDays(6),Invalid_1_Day_Plan__c = false, PlanManager__c = 'NDSP');
        
        listOfPlansInsert.add(Plan2);
        Test.startTest();
        DmlException expectedException;
        try {
            insert listOfPlansInsert;
        }
        catch(DmlException ex){
            expectedException = ex;
        }
        
        Test.stopTest();
        System.assertNotEquals(null, expectedException,'An unexpected error message was returned');
    }
    
    @isTest 
    static void testMethodInsertOneDayPlan() {
        List <Account> testAcctsList = [SELECT Id FROM Account LIMIT 10];
        Plan__c oneDayPlan = new Plan__c(Name = 'One Day Plan', Client_Name__c = testAcctsList[1].Id, Plan_Start_Date__c = System.today(),
                                                Plan_End_Date__c = System.today(),Invalid_1_Day_Plan__c = false, PlanManager__c = 'MPM');
        
        Test.startTest();
        DmlException expectedException;
        try {
            insert oneDayPlan;
        }
        catch(DmlException ex){
            expectedException = ex;
        }

        Test.stopTest();
        List<Plan__c> getPlans = [Select Id,Invalid_1_Day_Plan__c, Client_Name__c from Plan__c WHERE Client_Name__c =: testAcctsList[1].Id];
        System.assertEquals(true,getPlans[0].Invalid_1_Day_Plan__c);
        System.assertEquals(true,getPlans[1].Invalid_1_Day_Plan__c);
    }

    @isTest 
    static void testMethodExistingOneDayToNonOneDay() {
        List <Account> testAcctsList = [SELECT Id FROM Account LIMIT 10];
        List<Plan__c> planList = new List<Plan__c>();
        Plan__c oneDayPlan = new Plan__c(Name = 'One Day Plan', Client_Name__c = testAcctsList[1].Id, Plan_Start_Date__c = System.today(),
                                                Plan_End_Date__c = System.today(), Invalid_1_Day_Plan__c = true, PlanManager__c = 'MPM');
        Plan__c nonOneDayPlan = new Plan__c(Name = 'Three Day Plan', Client_Name__c = testAcctsList[1].Id, Plan_Start_Date__c = System.today().addDays(2),
                                                Plan_End_Date__c = System.today().addDays(5), Invalid_1_Day_Plan__c = true, PlanManager__c = 'MPM');
        Plan__c inActivePlan = new Plan__c(Name = 'Inactive Plan', Client_Name__c = testAcctsList[1].Id, Plan_Start_Date__c = System.today().addDays(-15),
                                                Plan_End_Date__c = System.today().addDays(-10), Invalid_1_Day_Plan__c = false, PlanManager__c = 'MPM');
        planList.add(oneDayPlan);
        planList.add(nonOneDayPlan);
        planList.add(inActivePlan);
        Test.startTest();
        DmlException expectedException;
        try {
            insert planList;
        }
        catch(DmlException ex){
            expectedException = ex;
        }

        List<Plan__c> planListToUpdate = new List<Plan__c>();
        inActivePlan.Plan_End_Date__c = System.today().addDays(-11);
        oneDayPlan.Plan_End_Date__c = System.today().addDays(1);
        planListToUpdate.add(inActivePlan);
        planListToUpdate.add(oneDayPlan);
        update planListToUpdate;

        Test.stopTest();
        List<Plan__c> getPlans = [Select Id,Invalid_1_Day_Plan__c, Client_Name__c from Plan__c WHERE Client_Name__c =: testAcctsList[1].Id];
        System.assertEquals(true,getPlans[0].Invalid_1_Day_Plan__c);
        System.assertEquals(false,getPlans[1].Invalid_1_Day_Plan__c);
    }

    @isTest 
    static void testMethodInsertNonOneDayPlan() {
        List <Account> testAcctsList = [SELECT Id FROM Account LIMIT 10];
        List <Plan__c> listOfPlans = new List<Plan__c>();

        Plan__c testPlan = new Plan__c(Name = 'Non 1 Day Plan', Client_Name__c = testAcctsList [1].Id, Plan_Start_Date__c = System.today(),
                                                Plan_End_Date__c = System.today().addDays(5),Invalid_1_Day_Plan__c = false, PlanManager__c = 'MPM');
                                               
        Test.startTest();
        DmlException expectedException;
        try {
            insert testPlan;
        }
        catch(DmlException ex){
            expectedException = ex;
        }
        Test.stopTest();
        
        List<Plan__c> getPlans = [Select Id,Invalid_1_Day_Plan__c, Client_Name__c from Plan__c WHERE Client_Name__c =: testAcctsList[1].Id];
        System.assertEquals(2,getPlans.size());
    }
    
    @isTest 
    static void testMethodUpdate() {
        List <Account> testAcctsList = [SELECT Id FROM Account LIMIT 10];
        List <Plan__c> listOfPlans = [SELECT Id, Client_Name__c FROM Plan__c WHERE Name = 'TestPlan1'];
        Plan__c testPlan = new Plan__c(Name = 'TestPlan2', Client_Name__c = testAcctsList [0].Id, Plan_Start_Date__c = System.today().addDays(6),
                                                Plan_End_Date__c = System.today().addDays(7), PlanManager__c = 'MPM');
                                                
        Plan__c testPlan3 = new Plan__c(Name = 'TestPlan3', Client_Name__c = testAcctsList [0].Id, Plan_Start_Date__c = System.today().addDays(22),
                                                Plan_End_Date__c = System.today().addDays(27), PlanManager__c = 'MPM');
                                                                                        
        Test.startTest();
        DmlException expectedException;
        
        try {
            insert testPlan3;                                        
            insert testPlan;
            testPlan3.Plan_Start_Date__c = System.today().addDays(5);
            update testPlan3;
        }
        catch(DmlException ex){
            expectedException = ex;
        }
        Test.stopTest();
   
        System.assertNotEquals(null, expectedException,'An unexpected error message was returned');

    }

    @isTest
    static void testAfterInsertAndBeforeDelete() {
        List <Account> testAcctsList = [SELECT Id FROM Account LIMIT 10];
        List<Plan__c> planList = new List<Plan__c>();
        Plan__c planRecord = new Plan__c(Name = 'Test Plan Record', Client_Name__c = testAcctsList[3].Id,Plan_Start_Date__c = System.today(),
                                          Plan_End_Date__c = System.today().addMonths(36));

        Plan__c planRecord2 = new Plan__c(Name = 'hello1', Client_Name__c = testAcctsList[4].Id,Plan_Start_Date__c = System.today(), Plan_End_Date__c = System.today().addMonths(6));
        
        Plan__c planRecord3 = new Plan__c (Name = 'hello2', Client_Name__c = testAcctsList[5].Id,Plan_Start_Date__c = System.today(), Plan_End_Date__c = System.today().addMonths(6));
        
        planList.add(planRecord);
        planList.add(planRecord2);
        planList.add(planRecord3);


        Test.startTest();
      
        try {
           insert planList;
        } catch(Exception ex) {
            System.debug('Plan Insert After Failed'+ex);
        }
        List<Plan__c> listOfUpdatedPlan = new List<Plan__c>();
        planList[0].Plan_End_Date__c = System.today().addMonths(6);
        planList[1].Plan_End_Date__c = System.today().addMonths(12);
        planList[2].Plan_Start_Date__c = System.today().addDays(12);
        listOfUpdatedPlan.addAll(planList);
        
        try {
            update listOfUpdatedPlan;
        } catch(Exception ex) {
            System.debug('Plan Update After Failed'+ex);
        }
        Plan__c planObj = listOfUpdatedPlan[0];
        delete planObj;
        List<Milestone__c> listOfMilestone = [SELECT Id, Plan__c FROM Milestone__c WHERE Plan__c =:planObj.Id];
        System.assertEquals(0,listOfMilestone.size());
        Test.stopTest();
    }

    @isTest
    static void testUpdatePlanSupportPreferences() {
       Account clientAccount = TestClassDataUtil.createClientAccount();
        // create plan
        List<Plan__c> planList = TestClassDataUtil.createPlanRecords(true, 1,clientAccount.Id);
        // create provider account
        Account providerAccount = TestClassDataUtil.createProviderAccount(true, null, TEST_ABN_NUMBER);
        // create support category
        List<SupportCategory__c> scList = TestClassDataUtil.createSupportCategoryRecords(true,1);
        // create plan support
        List<PlanSupport__c> planSupportsList = TestClassDataUtil.createPlanSupports(true, 1, planList[0].Id, scList[0].Id);
        // create support item
        List<SupportItem__c> supportItemList = TestClassDataUtil.createSupportItemRecords(true, 1, scList[0].Id);
        // create plan support preference
        List<PlanSupportPreference__c> pspList = TestClassDataUtil.createPlanSupportPreferenceRecords(false, 1, providerAccount.Id, planList[0].Id, planSupportsList[0].Id, scList[0].Id);
        pspList[0].EndDate__c = System.today().addMonths(1);
        pspList[0].SupportItemNumber__c = '1_0023_436_1';
        pspList[0].SubstitutionSupportItemNumber__c = '1_0023_436_1';
        insert pspList;
        // update the plan end date, extend the duration
        planList[0].Plan_End_Date__c = System.today().addMonths(2);
        update planList[0];
        List<PlanSupportPreference__c> getPspList = [Select Id,EndDate__c FROM  PlanSupportPreference__c];
        System.assertEquals (planList[0].Plan_End_Date__c, getPspList[0].EndDate__c);

        // update the plan end date, shorten the duration
        planList[0].Plan_End_Date__c = System.today().addMonths(-1);
        update planList[0];
        List<PlanSupportPreference__c> getPspList1 = [Select Id,EndDate__c FROM  PlanSupportPreference__c];
        System.assertEquals (planList[0].Plan_End_Date__c, getPspList1[0].EndDate__c);
    }
}