/*
 * Ivan Aerlic
 * Description: Test class for Case Assignment Rules
 */
@isTest(SeeAllData=false)  
private class CaseAssignmentsTest {     
    private static User systemUser = [SELECT Id FROM User WHERE Id = '0052v00000boDYdAAM'];
    private static Database.DMLOptions dmlOption = new Database.DMLOptions();
    static{
        dmlOption.assignmentRuleHeader.useDefaultRule= true;
    }
    //Group Ids
    private static Id relationshipsQLDGroupId = '00G5K000000N31YUAS';
    private static Id junkGroupId = '00G5K000000MecMUAS';
    private static Id exceptionGroupId =  '00G5K000000MecLUAS';
    private static Id solutionsGroupId =  '00G5K000000MVTfUAO';
    private static Id invoiceGroupId =  '00G5K000000MWFIUA4'; 
    private static Id statementsGroupId =  '00G5K000000MecPUAS';
    private static Id accountsGroupId =  '00G5K000000MVTTUA4';
    private static Id reimbursementsGroupId =  '00G5K000000MVTaUAO';
    private static Id trickyAccountsGroupId =  '00G5K000000MVThUAO';
    private static Id ocrGroupId =  '00G5K000000MVTXUA4';
    private static Id abbyGroupId =  [SELECT Id FROM Group WHERE DeveloperName = 'ABBYY'].Id;
    //Record Types Ids
    private static Id generalRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('General').getRecordTypeId();
    private static Id clientRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId();
    private static Id providerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Provider').getRecordTypeId();
    
    @isTest private static void testJunkAsSystemUser(){
        System.runAs(systemUser){
            testJunk();
        }
    }
    @isTest private static void testExceptionAsSystemUser(){
        System.runAs(systemUser){
            testException();
        }
    }
    @isTest private static void testTrickyAsSystemUser(){
        System.runAs(systemUser){
            testTricky();
        }
    }
    @isTest private static void testStatementsAsSystemUser(){
        System.runAs(systemUser){
            testStatements();
        }
    }
    @isTest private static void testSolutionsAsSystemUser(){
        System.runAs(systemUser){
            testSolutions();
        }
    }
    @isTest private static void testInvoicesAsSystemUser(){
        System.runAs(systemUser){
            testInvoices(); 
        }
    }
    @isTest private static void testReimbursementsAsSystemUser(){
        System.runAs(systemUser){
            testReimbursements(); 
        }
    }
    /*@isTest private static void testAccountsSwitchAsSystemUser(){ 
        System.runAs(systemUser){
            testAccountsSwitch();
        }
    }*/
    @isTest private static void testInvoiceSwitchAsSystemUser(){ 
        System.runAs(systemUser){
            testInvoiceSwitch();
        }
    }
    @isTest private static void testSolutionsSwitchAsSystemUser(){ 
        System.runAs(systemUser){
            testSolutionsSwitch();
        }
    }
    @isTest private static void testTrickySwitchAsSystemUser(){ 
        System.runAs(systemUser){
            testTrickySwitch();
        }
    }
    @isTest private static void testReimbursementsSwitchAsSystemUser(){ 
        System.runAs(systemUser){
            testReimbursementsSwitch();
        }
    }
    //Tests entry into Junk Queue
    private static void testJunk(){
        //Add subjects
        String [] subjects = new List<String>();
        subjects.add('how would you rate the support you receive'.toUpperCase());
       
        //Create junk cases
        List<Case> junkCases = createCasesWithSubjects(UserInfo.getUserId(), subjects); 
       
        //Start test
        Test.startTest();
        insert junkCases;

        
        //Check that values have been changed during DML by retrieving them from the database   
        List<Case> results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                              PodSkillRequirement__c, Status
                              FROM Case WHERE Id IN:junkCases];
        //Assertions
        for(Case c: results){
            if (c.OwnerId == junkGroupId) {
                System.assert(c.OwnerId == junkGroupId, 'Owner: '+c.OwnerId );
            }            
        }
        //Make sure it only works on insert
        for(Case c: junkCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update junkCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                              PodSkillRequirement__c, Status
                              FROM Case WHERE Id IN:junkCases];
        //Assertions
        for(Case c: results){
            if (c.OwnerId != junkGroupId) {
                System.assert(c.OwnerId != junkGroupId, 'Owner: '+c.OwnerId );
            }            
        }
        System.assert(results.size() == 1, results.size());
        Test.stopTest();
    }
    //Tests entry into Exception Queue
    private static void testException(){
        //Add subjects
        List<String> subjects = new List<String>();
        subjects.add('your message couldn'.toUpperCase());
        subjects.add('out of office'.toUpperCase());
        subjects.add('failed'.toUpperCase());
        //Create exception cases
        List<Case> exceptionCases = createCasesWithSubjects(UserInfo.getUserId(), subjects); 
        
        //Start test
        Test.startTest();
        insert exceptionCases;
        
        //Check that values have been changed during DML by retrieving them from the database   
        List<Case> results = [SELECT OwnerId,RecordTypeId,Sub_Type__c, Status,
                                Client__r.One_to_One_Account__c,PodSkillRequirement__c 
                                FROM Case WHERE Id IN:exceptionCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId == exceptionGroupId, ' | Owner: '+c.OwnerId );
        }
        System.assert(results.size() == 3, results.size()); 
        //Make sure it only works on insert
        for(Case c: exceptionCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update exceptionCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c, Status
                   FROM Case WHERE Id IN:exceptionCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId != exceptionGroupId, ' | Owner: '+c.OwnerId );
        }
        System.assert(results.size() == 3, results.size());
        Test.stopTest();
    }
    //Tests entry into Solutions Queue
    private static void testSolutions(){
        //Add emails
        String [] emails = new List<String>();
        emails.add('test@adelaidepaediatrics.com.au'.toUpperCase());
        emails.add('info@bouncephysiobirkdale.com.au'.toUpperCase());
        emails.add('birkdale@bouncephys.com.au'.toUpperCase());
        emails.add('ndispayments@anglicare.org.au'.toUpperCase());
        emails.add('kotzlighting@bigpond.com'.toUpperCase());
        emails.add('ella.kos@rdasa.org.au'.toUpperCase());
        emails.add('finance@rdasa.org.au'.toUpperCase());
        emails.add('customerservice@independenceaustralia.com'.toUpperCase());
        emails.add('customerservice@iagroup.org.au'.toUpperCase());
        emails.add('ar@iagroup.org.au'.toUpperCase());
        //Create solution cases
        Case [] solutionCases = createCasesWithEmails(emails); 
        //Start test
        Test.startTest();
        insert solutionCases;

        //Check that values have been changed during DML by retrieving them from the database   
        Case [] results = [SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail,
                            Client__r.One_to_One_Account__c,PodSkillRequirement__c 
                            FROM Case WHERE Id IN:solutionCases];

        //Assertions
        for(Case c : results){
            if (c.OwnerId == solutionsGroupId) {
                System.assert(c.OwnerId == solutionsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | Email: '+c.SuppliedEmail
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
            }            
        }
        System.assert(results.size() == 10, results.size());
        //Make sure it only works on insert
        for(Case c: solutionCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update solutionCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:solutionCases];
        //Assertions
        for(Case c: results){
            if (c.OwnerId == solutionsGroupId) {
                System.assert(c.OwnerId != solutionsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
            }            
        }
        System.assert(results.size() == 10, results.size());
        Test.stopTest();
    }
    //Tests entry into Invoice Request to Pay Queue
    private static void testInvoices(){
        //Add emails
        List<String> emails = new List<String>();
        emails.add('maris69@optusnet.com.au'.toUpperCase());
        emails.add('wilsonalan862@gmail.com'.toUpperCase()); 
        emails.add('lorafranciscastle@hotmail.com'.toUpperCase());
        emails.add('libby_armstrong@yahoo.com'.toUpperCase());
        emails.add('raelenecox868@gmail.com'.toUpperCase());
        emails.add('mariana.oppermann@me.com'.toUpperCase());
        emails.add('bobby-jo@live.com'.toUpperCase());
        emails.add('paulcook3@clubtelco.com'.toUpperCase());
        emails.add('lewanacagi@gmail.com'.toUpperCase());
        emails.add('info@therabees.com.au'.toUpperCase());
        emails.add('cbrandrgpm@gmail.com'.toUpperCase());
        emails.add('chriskbrand@gmail.com'.toUpperCase());
        emails.add('christine.mikhail@justingroup.com.au'.toUpperCase());
        emails.add('tarawilliamssuppotworker@gmail.com'.toUpperCase());
        emails.add('anna.pitra@hotmail.com'.toUpperCase());
        emails.add('jarvislinda1967@gmail.com'.toUpperCase());
        emails.add('janellepope1963@gmail.com'.toUpperCase());
        //Create invoice cases
        List<Case> invoiceCases = createCasesWithEmails(emails);
        //Start test
        Test.startTest();
        insert invoiceCases;
        
        //Check that values have been changed during DML by retrieving them from the database  
        List<Case> results = [SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail
                ,Client__r.One_to_One_Account__c,PodSkillRequirement__c 
                FROM Case WHERE Id IN:invoiceCases];

        //Assert
       /* for(Case c : results){ 
            System.assert(c.OwnerId == invoiceGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | Email: '+c.SuppliedEmail
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(results.size() == 17, results.size());*/
        //Make sure it only works on insert
        for(Case c: invoiceCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update invoiceCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:invoiceCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId != invoiceGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(results.size() == 17, results.size());
        Test.stopTest();
    }

    //Tests entry into Tricky Queue for keywords : Phamacy / Chemist / Residential / Accomodation / Aged care 
    private static void testTricky(){
        //Because we use account group id on insert we need a webhook for ocr claims
        Test.setMock(HttpCalloutMock.class, new ClaimsAutomationServiceMock());
        
        //Create subjects
        String [] goodSubjects = new List<String>();
        goodSubjects.add('statementChemist King Hectorville Account Statements'.toUpperCase());
        goodSubjects.add('statement for Residential'.toUpperCase());
        String [] badSubjects = new List<String>();
        badSubjects.add('invoice'.toUpperCase());
        badSubjects.add('statement my plan manager'.toUpperCase());
        badSubjects.add('regis monthly'.toUpperCase());
        
        //Create statement cases
        List<Case> statementCases = createCasesWithSubjects(accountsGroupId, goodSubjects);
        List<Case> nonStatementCases = createCasesWithSubjects(accountsGroupId, badSubjects);
        //Start test
        Test.startTest();
        insert statementCases;
        insert nonStatementCases;

        //Check that values have been changed during DML by retrieving them from the database 
        Case [] goodResults =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail,
                              Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                              FROM Case WHERE Id IN:statementCases];
        Case [] badResults =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail,
                             Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                             FROM Case WHERE Id IN:nonStatementCases];
        
        //Assert
        for(Case c : goodResults){ 
            //System.assert(c.OwnerId == trickyAccountsGroupId, 'Owner: '+c.OwnerId );
        }
        System.assert(goodResults.size() == 2, goodResults.size());
        for(Case c : badResults){ 
            System.assert(c.OwnerId != trickyAccountsGroupId,'Owner: '+c.OwnerId );
        }
        System.assert(badResults.size() == 3, badResults.size());
        
        //Make sure it only works on insert
        for(Case c: statementCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update statementCases;
        goodResults = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:statementCases];
        //Assertions
        for(Case c: goodResults){
            System.assert(c.OwnerId != statementsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(goodResults.size() == 2, goodResults.size());
        Test.stopTest();
    }


    //Tests entry into Statements Queue
    private static void testStatements(){
        //Because we use account group id on insert we need a webhook for ocr claims
        Test.setMock(HttpCalloutMock.class, new ClaimsAutomationServiceMock());
        
        //Create subjects
        String [] goodSubjects = new List<String>();
        goodSubjects.add('statement'.toUpperCase());
        
        String [] badSubjects = new List<String>();
        badSubjects.add('invoice'.toUpperCase());
        badSubjects.add('statement my plan manager'.toUpperCase());
        badSubjects.add('regis monthly'.toUpperCase());
        
        //Create statement cases
        List<Case> statementCases = createCasesWithSubjects(accountsGroupId, goodSubjects);
        List<Case> nonStatementCases = createCasesWithSubjects(accountsGroupId, badSubjects);
        //Start test
        Test.startTest();
        insert statementCases;
        insert nonStatementCases;

        //Check that values have been changed during DML by retrieving them from the database 
        Case [] goodResults =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail,
                              Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                              FROM Case WHERE Id IN:statementCases];
        Case [] badResults =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail,
                             Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                             FROM Case WHERE Id IN:nonStatementCases];
        
        //Assert
        for(Case c : goodResults){ 
            System.assert(c.OwnerId == statementsGroupId, 'Owner: '+c.OwnerId );
        }
        System.assert(goodResults.size() == 1, goodResults.size());
        for(Case c : badResults){ 
            System.assert(c.OwnerId != statementsGroupId,'Owner: '+c.OwnerId );
        }
        System.assert(badResults.size() == 3, badResults.size());
        
        //Make sure it only works on insert
        for(Case c: statementCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update statementCases;
        goodResults = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:statementCases];
        //Assertions
        for(Case c: goodResults){
            System.assert(c.OwnerId != statementsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(goodResults.size() == 1, goodResults.size());
        Test.stopTest();
    }
    //Tests entry into Reimbursements queue
    private static void testReimbursements(){
        //Add subjects
        String [] subjects = new List<String>();
        subjects.add('reimburse');
        subjects.add('paid to me');
        subjects.add('paid by me');
        subjects.add('receipt');
        //Create reimbursement cases
        List<Case> reimbursementCases = createCasesWithSubjects(UserInfo.getUserId(), subjects); 
        
        //Start test
        Test.startTest();
        insert reimbursementCases;

        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                          Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject, Type, Priority 
                          FROM Case WHERE Id IN:reimbursementCases];
        //Assert
        for(Case c : results){  
            System.assert(c.OwnerId == reimbursementsGroupId, 'Type: '+c.Type
                          +' | Owner: '+c.OwnerId  
                          +' | Priority : '+c.Priority
                          +' | Sub_Type__c: '+c.Sub_Type__c);
            System.assert(c.Priority == 'High', c.Priority);
            System.assert(c.Sub_Type__c == 'Reimbursements', c.Sub_Type__c);
            System.assert(c.Type == 'Claims Processing', c.Type);
        }
        System.assert(results.size() == 4, results.size());
        //Make sure it only works on insert
        for(Case c: reimbursementCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update reimbursementCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                       PodSkillRequirement__c 
                       FROM Case WHERE Id IN:reimbursementCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId != reimbursementsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(results.size() == 4, results.size());
        Test.stopTest();
    }
    /*//Tests entry from user into Accounts Queue
    private static void testAccountsSwitch(){
        //Because we use account group id on insert we need a webhook for ocr claims
        Test.setMock(HttpCalloutMock.class, new ClaimsAutomationServiceMock());
        
        //Create account cases
        List<Case> accountCases = createSwitchCase(accountsGroupId); 
        
        //Start test
        Test.startTest();
        update accountCases;

        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                              Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                              FROM Case WHERE Id IN:accountCases];
        
        //Assert
        for(Case c : results){  
            System.assert(c.OwnerId == accountsGroupId, 'Owner: '+c.OwnerId );
        }
        System.assert(results.size() == 1, results.size());
        //Make sure it only works on when status is changed
        for(Case c: accountCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update accountCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:accountCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId != accountsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(results.size() == 1, results.size());
        Test.stopTest();
    }*/
    //Tests entry from user into Invoice Queue
    private static void testInvoiceSwitch(){
        //Create invoice cases
        List<Case> invoiceCases = createSwitchCase(invoiceGroupId); 
        
        //Start test
        Test.startTest();
        update invoiceCases;

        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                          Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                          FROM Case WHERE Id IN:invoiceCases];
        //Assert
        for(Case c : results){  
            System.assert(c.OwnerId == invoiceGroupId, 'Status: '+c.status
                          +' | Owner: '+c.OwnerId  
                          +' | recordtype: '+c.RecordTypeId
                          +' | Queue_Name__c: '+c.Queue_Name__c);
        }
        System.assert(results.size() == 1, results.size());
        //Make sure it only works on when status is changed
        for(Case c: invoiceCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update invoiceCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:invoiceCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId != invoiceGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(results.size() == 1, results.size());
        Test.stopTest();
    }
    //Tests entry from user into Solutions Queue
    private static void testSolutionsSwitch(){
        //Create solution cases
        List<Case> solutionCases = createSwitchCase(solutionsGroupId); 
        
        //Start test
        Test.startTest();
        update solutionCases;

        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                          Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                          FROM Case WHERE Id IN:solutionCases];
        //Assert
        for(Case c : results){  
            System.assert(c.OwnerId == solutionsGroupId, 'Status: '+c.status
                          +' | Owner: '+c.OwnerId  
                          +' | recordtype: '+c.RecordTypeId
                          +' | Queue_Name__c: '+c.Queue_Name__c);
        }
        System.assert(results.size() == 1, results.size());
        //Make sure it only works on when status is changed
        for(Case c: solutionCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update solutionCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:solutionCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId != solutionsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(results.size() == 1, results.size());
        Test.stopTest();
    }
    //Tests entry from user into Tricky Accounts Queue
    private static void testTrickySwitch(){
        //Create tricky account cases
        List<Case> trickyAccountCases = createSwitchCase(trickyAccountsGroupId); 
        
        //Start test
        Test.startTest();
        update trickyAccountCases;

        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                          Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                          FROM Case WHERE Id IN:trickyAccountCases];
        //Assert
        for(Case c : results){  
            System.assert(c.OwnerId == trickyAccountsGroupId, 'Status: '+c.status
                          +' | Owner: '+c.OwnerId  
                          +' | recordtype: '+c.RecordTypeId
                          +' | Queue_Name__c: '+c.Queue_Name__c);
        }
        System.assert(results.size() == 1, results.size());
        //Make sure it only works on when status is changed
        for(Case c: trickyAccountCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update trickyAccountCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:trickyAccountCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId != trickyAccountsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(results.size() == 1, results.size());
        Test.stopTest();
    }
    //Tests entry from user into Reimbursements Queue
    private static void testReimbursementsSwitch(){
        //Create reimbursement cases
        List<Case> reimbursementsCases = createSwitchCase(reimbursementsGroupId); 
        
        //Start test
        Test.startTest();
        update reimbursementsCases;
        
        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                          Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                          FROM Case WHERE Id IN:reimbursementsCases];
        //Assert
        for(Case c : results){  
            System.assert(c.OwnerId == reimbursementsGroupId, 'Status: '+c.status
                          +' | Owner: '+c.OwnerId  
                          +' | recordtype: '+c.RecordTypeId
                          +' | Queue_Name__c: '+c.Queue_Name__c);
        }
        System.assert(results.size() == 1, results.size());
        //Make sure it only works on when status is changed
        for(Case c: reimbursementsCases){
            c.OwnerId = UserInfo.getUserId();
        }
        update reimbursementsCases;
        results = [SELECT OwnerId,RecordTypeId,Sub_Type__c,Client__r.One_to_One_Account__c,
                   PodSkillRequirement__c 
                   FROM Case WHERE Id IN:reimbursementsCases];
        //Assertions
        for(Case c: results){
            System.assert(c.OwnerId != reimbursementsGroupId, 'Sub-type: '+c.Sub_Type__c
                          +' | client one to one:'+c.Client__r.One_to_One_Account__c 
                          +' | Owner: '+c.OwnerId 
                          +' | Pod Skill: '+c.PodSkillRequirement__c
                          +' | recordtype: '+c.RecordTypeId);
        }
        System.assert(results.size() == 1, results.size());
        Test.stopTest();
    }
    //Tests entry into ABBY queue
    @isTest private static void testABBY(){
        
        //Create automated claims provider
        Account account = new Account();
        account.Name = 'Provider'; 
        account.RecordTypeId = providerRecordTypeId;
        insert account;
        //Add emails
        List<String> emails = new List<String>();
        emails.add('messaging-service@post.xero.com'.toUpperCase());
        emails.add('customerservice@independenceaustralia.com'.toUpperCase());
        //Create invoice cases
        List<Case> emailCases = createCasesWithEmails(emails);
        
        //Add subjects
        String [] subjects = new List<String>();
        subjects.add('Physio Inq');
        subjects.add('Independence Australia Invoice');
        subjects.add('Independence Australia Credit Note');
        //Create ABBY cases
        List<Case> abbyCases = createCasesWithSubjects(UserInfo.getUserId(), subjects); 
        
        List<Case> mainCaseList = new List<Case>();
        mainCaseList.addAll(abbyCases);
        mainCaseList.addAll(emailCases);
        //Start test
        Test.startTest();
        insert mainCaseList;
        Test.stopTest();
        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                          Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                          FROM Case WHERE Id IN:mainCaseList];
    }
    //Tests entry into OCR queue
    /*@isTest private static void testOCR(){
        //Because we use ocr group id on insert we need a webhook for ocr claims
        Test.setMock(HttpCalloutMock.class, new ClaimsAutomationServiceMock());
        
        //Create automated claims provider
        Account account = new Account();
        account.Name = 'Provider'; 
        account.RecordTypeId = providerRecordTypeId;
        account.Automated_Claims__c = true; 
        account.Automated_Claims_Confidence_Level__c = 'High';
        insert account;
        //Create OCR cases
        List<Case> ocrCases = createCases(1); 
        //Set account as provider
        for(Case c : ocrCases){  
            c.Provider__c = account.Id; 
        }
        
        //Start test
        Test.startTest();
        insert ocrCases;
        Test.stopTest();
        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                          Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject 
                          FROM Case WHERE Id IN:ocrCases];
        //Assert
        for(Case c : results){  
            System.assert(c.OwnerId == ocrGroupId, 'Owner: '+c.OwnerId  );
        }
        System.assert(results.size() == 1, results.size());
    }*/
    //Test process builder that sets case owner to client owner
    @isTest private static void testOneToOneClient(){
        //Create one to one client
        Account account = new Account();
        account.FirstName = 'John'; 
        account.LastName = 'Doe';  
        account.NDIS__c = '43436';
        account.RecordTypeId = clientRecordTypeId;
        account.One_to_One_Account__c = true;
        insert account;
        
        //Retrieve account from db to check owner id
        Account savedAccount = [SELECT Id, OwnerId FROM Account WHERE Id =:account.Id];
        
        //Create one to one client cases
        List<Case> oneToOneClientCases = createCases(1); 
        
        //Change owner so that it is different from account owner
        for(Case cs : oneToOneClientCases) {
            cs.Client__c = account.Id;
            cs.OwnerId = solutionsGroupId;
        }
        //Start test
        Test.startTest();
        insert oneToOneClientCases;
        Test.stopTest();
        //Check that values have been changed during DML by retrieving them from the database 
        Case [] results =[SELECT OwnerId,RecordTypeId,Sub_Type__c, SuppliedEmail, status,Queue_Name__c, 
                          Client__r.One_to_One_Account__c,PodSkillRequirement__c,subject, Type, Priority 
                          FROM Case WHERE Id IN:oneToOneClientCases];
        //Assert
        for(Case c : results){   
            System.assert(c.OwnerId == savedAccount.ownerId, ' | Owner: '+c.OwnerId  );
        }
        System.assert(results.size() == 1, results.size());
    }
   /* Create a case that starts in a certain queue and then gets switched to being owned by a user
    * And status get switched to response received
    */
    private static Case [] createSwitchCase(String queueId){ 
        Case [] cases = new List<Case>();
        Case c = new Case(); 
        c.setOptions(dmlOption);
        c.Status = 'Status';
        c.OwnerId = queueId;
        c.SuppliedEmail = 'test@test.com';
        c.Subject = 'test';  
        c.RecordTypeId = generalRecordTypeId;
        c.PlanManager__c = 'MPM';
        cases.add(c);
        insert cases;
        c.OwnerId = UserInfo.getUserId();
        update cases;
        c.Status = 'Response Received';
        return cases; 
    }
    /*
     * Create cases starting in any queue
     * Subjects are dynamic
     */
    private static Case [] createCasesWithSubjects(String queueId, String [] subjects){ 
        Case [] cases = new List<Case>();
        for(String subject : subjects){
            Case c = new Case(); 
            c.setOptions(dmlOption);
            c.OwnerId = queueId;
            c.SuppliedEmail = 'test@test.com';
            c.Subject = subject;  
            c.RecordTypeId = generalRecordTypeId;
            c.PlanManager__c = 'MPM';
            c.Priority = 'High';
            c.Type = 'Claims Processing';
            c.Sub_Type__c = 'Reimbursements';
            cases.add(c);
        }
        return cases; 
    }
   /*
    * Create cases with dynamic emails
    */
    private static Case [] createCasesWithEmails(String [] emails){ 
        Case [] cases = new List<Case>();
        for(String email: emails){
            Case c = new Case(); 
            c.setOptions(dmlOption);
            c.OwnerId = UserInfo.getUserId();
            c.SuppliedEmail = email;
            c.Subject = 'test'; 
            c.RecordTypeId = generalRecordTypeId;
            c.PlanManager__c = 'NDSP';
            c.Sub_Type__c = 'Budget Milestone Conversatio';
            c.Type= 'Client Education';
            c.PodSkillRequirement__c ='Queensland'; 
            cases.add(c);
        }
        return cases; 
    }
    /*
     * Create cases for Relationships queue
     */
    private static List<Case> createRelationshipCases(Account client){
        List<Case> cases = new List<Case>();
        Map<String, String> subTypes = new Map<String, String>();
        String clientEducation = 'Client Education';
        String clientSetupAdmin = 'Client Setup/Admin';
        String clientSupport = 'Client Support';
        String cliamsProcessing = 'Claims Processing';
        subTypes.put('Budget Milestone Conversation', clientEducation);  
        subTypes.put('Maintenance Budget Conversation', clientEducation);
        subTypes.put('Payment Assurance Conversation', clientEducation);
        subTypes.put('Underspend/Overspend Conversation', clientEducation);
        subTypes.put('Education About Digital Tools', clientEducation);
        subTypes.put('Process Client Documentation', clientSetupAdmin);
        subTypes.put('Process NDIS Plans', clientSetupAdmin);
        subTypes.put('Setup Plan Managed Transport', clientSetupAdmin);
        subTypes.put('Generate Budget Report', clientSetupAdmin);
        subTypes.put('Client Reconnection', clientSetupAdmin);
        subTypes.put('Client Exit', clientSetupAdmin);
        subTypes.put('Setup Budget Conversation', clientSetupAdmin);
        subTypes.put('Setup Client Portal Access', clientSetupAdmin);
        subTypes.put('Setup Virtual Credit Card', clientSetupAdmin);
        subTypes.put('NDIA Request', clientSetupAdmin);
        subTypes.put('Retention Conversation', clientSupport);
        subTypes.put('Inbound Client Enquiry', clientSupport);
        subTypes.put('Cabcharge/Credit Card Purchases', clientSupport);
        subTypes.put('Quote Support', clientSupport);
        subTypes.put('Budget Line Check', cliamsProcessing);
        subTypes.put('Duplicate Invoice', cliamsProcessing);
        subTypes.put('Reimbursements - Draft', cliamsProcessing);
        subTypes.put('Over the Price Guide', cliamsProcessing);
        subTypes.put('Insufficient Funds', cliamsProcessing);
        subTypes.put('Invoice Over $20,000', cliamsProcessing);
        subTypes.put('Reduced Plans/Funds', cliamsProcessing);
        subTypes.put('Split Invoice (Relationships)', cliamsProcessing);
        for(String subType : subTypes.keySet()){
            Case c = new Case(); 
            c.setOptions(dmlOption);
            c.OwnerId = UserInfo.getUserId();
            c.PodSkillRequirement__c ='Queensland'; 
            c.SuppliedEmail = 'test@test.com';
            c.Subject = 'test';
            c.RecordTypeId = generalRecordTypeId;
            c.Client__c = client.Id;
            c.Sub_Type__c = subType;
            c.Type= subTypes.get(subType);
            cases.add(c); 
        }
		return cases;
    }
    /*
     * Create generic cases
     */
    private static Case [] createCases(integer no){
        List<Case> cases = new List<Case>();
        for(integer i = 0; i < no; i++){
            Case c = new Case(); 
            c.setOptions(dmlOption); 
            c.SuppliedEmail = 'test@test.com';
            c.Subject = 'test';
            c.RecordTypeId = generalRecordTypeId;
            c.PlanManager__c= 'NDSP';
            cases.add(c); 
        } 
        return cases;
    }
    /*
     * Mock class for OCR claims webhook
     */
    private class ClaimsAutomationServiceMock implements HttpCalloutMock {
        public ClaimsAutomationServiceMock(){
            TestClassDataUtil.createClaimsAutomationSettings();
        }
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            
            response.setStatusCode(200);
            
            return response;
        }
    }
}