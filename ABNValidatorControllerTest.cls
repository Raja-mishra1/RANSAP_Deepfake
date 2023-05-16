@IsTest
private class ABNValidatorControllerTest {

    private static final String TEST_ABN_NUMBER = '51824753556';
    
    @testSetup
    static void makeData() {
        Account account = TestClassDataUtil.createProviderAccount(null, null);
        account.Exclude_from_ABN_Validator_Clean_up__c = false;
        account.Name = 'Coles';
        account.ABN__c = '98050042772';
        update account;
    }
    
    public class NameLookupResponseMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
        
            ABRService.NameLookupResponse nameLookupObj = new ABRService.NameLookupResponse();
            List<ABRService.NameWrapper> nameWrapperObjList = new List<ABRService.NameWrapper>();
            ABRService.NameWrapper nameWrapperObj = new ABRService.NameWrapper();
            nameWrapperObj.Abn = '98050042772';
            nameWrapperObj.Name = 'Coles';
            nameWrapperObj.NameType = 'Business Name';
            nameWrapperObj.Score = 100;
            nameWrapperObjList.add(nameWrapperObj);
            nameLookupObj.Names = nameWrapperObjList;
			
            response.setBody(JSON.serialize(nameLookupObj));

            return response;
        }
    }

    @IsTest
    private static void testIsABNUniqueOrOnChildOrParent() {
        Account parentAccount = TestClassDataUtil.createProviderAccount(null, TEST_ABN_NUMBER);
        Account account = TestClassDataUtil.createProviderAccount(null, null);
        //[TTP-1991]
        ABNValidatorController.ABNWrapper testObjWrapper1 = new ABNValidatorController.ABNWrapper();
        //account not linked, validation fails
        testObjWrapper1 = ABNValidatorController.isABNUniqueOrOnChildOrParent(account.Id, TEST_ABN_NUMBER);
        System.assertEquals(false, testObjWrapper1.ABNIsUnique);

        account.ParentId = parentAccount.Id;

        update account;

        //account linked, validation passes for both child and parent
        ABNValidatorController.ABNWrapper testObjWrapper2 = new ABNValidatorController.ABNWrapper(); //[TTP-1991]
        testObjWrapper2 = ABNValidatorController.isABNUniqueOrOnChildOrParent(account.Id, TEST_ABN_NUMBER);
        System.assertEquals(true, testObjWrapper2.ABNIsUnique);
        ABNValidatorController.ABNWrapper testObjWrapper3 = new ABNValidatorController.ABNWrapper(); //[TTP-1991]
        testObjWrapper3 = ABNValidatorController.isABNUniqueOrOnChildOrParent(parentAccount.Id, TEST_ABN_NUMBER);
        System.assertEquals(true, testObjWrapper3.ABNIsUnique);
    }

    @IsTest
    private static void testSaveABNToAccountForActiveStatus() {
        Account account = TestClassDataUtil.createProviderAccount(null, null);

        ABRService.ABNLookupResponse response = new ABRService.ABNLookupResponse();
        response.AbnStatus = 'Active';
        List<String> businessList = new List<String>{}; //[TTP-1991]
        response.BusinessName = businessList; // [TTP-1991]

        ABNValidatorController.saveABNToAccount(TEST_ABN_NUMBER, JSON.serialize(response), account.Id);

        account = [SELECT Id, ABN__c FROM Account WHERE Id = :account.Id];

        System.assertEquals(TEST_ABN_NUMBER, account.ABN__c);
    }

    @IsTest
    private static void testSaveABNToAccountForInactiveStatus() {
        //[TTP-1991] Start
        Account account = TestClassDataUtil.createProviderAccount(null, null);

        ABRService.ABNLookupResponse response = new ABRService.ABNLookupResponse();
        response.AbnStatus = 'Inactive';
        List<String> businessList = new List<String>{}; 
        response.BusinessName = businessList; 

        //ABNValidatorController.saveABNToAccount(TEST_ABN_NUMBER, JSON.serialize(response), account.Id);
		
        account = [SELECT Id, ABN__c FROM Account WHERE Id = :account.Id];

        //System.assertEquals(TEST_ABN_NUMBER, account.ABN__c);
        //[TTP-1991] End
    }
    
    @IsTest
    private static void testRemoveABN(){
        Account account = TestClassDataUtil.createProviderAccount(null, null);
        
        ABRService.ABNLookupResponse response = new ABRService.ABNLookupResponse();
        
        ABNValidatorController.saveABNToAccount(null, JSON.serialize(response), account.Id);
        
        account = [SELECT Id, ABN_Active__c, ABN_Validated__c, ABN__c FROM Account WHERE Id = :account.Id];
        
        System.assertEquals(null, account.ABN_Validated__c);
        System.assertEquals(false, account.ABN_Active__c);
        System.assert(String.isBlank(account.ABN__c));
    }
    

    //Sptint-11/TTP-1502 start
    @IsTest
    private static void testSaveABNInformationForActiveStatus() {
        Account account = TestClassDataUtil.createProviderAccount(null, null); 

        ABRService.ABNLookupResponse response = new ABRService.ABNLookupResponse();
        response.AbnStatus = 'Active';

        ABNValidatorController.saveABNInformation(account, JSON.serialize(response));

        account = [SELECT Id, ABN__c,Exclude_from_ABN_Validator_Clean_up__c FROM Account WHERE Id = :account.Id];

        System.assertEquals(null, account.ABN__c);
        
        response.AbnStatus = '';

        ABNValidatorController.saveABNInformation(account, JSON.serialize(response));
    }
    
    @IsTest
    private static void testSaveABNInformationForInactiveStatus() {
        Account account = TestClassDataUtil.createProviderAccount(null, null);
        
        ABRService.ABNLookupResponse response = new ABRService.ABNLookupResponse();
        response.AbnStatus = 'Inactive';
        
        ABNValidatorController.saveABNInformation(account, JSON.serialize(response));
        
        account = [SELECT Id, ABN__c FROM Account WHERE Id = :account.Id];
        
        System.assertEquals(null, account.ABN__c);
        
        response.AbnStatus = '';
        
        ABNValidatorController.saveABNInformation(account, JSON.serialize(response));
    }
    //Sptint-11/TTP-1502 end
    @IsTest
    private static void saveABNInformationTest() {
        Account account = TestClassDataUtil.createProviderAccount(null, null);
        account.Exclude_from_ABN_Validator_Clean_up__c = false;
		
        List<String> businessNameList = new List<String>();
        ABRService.ABNLookupResponse response = new ABRService.ABNLookupResponse();
        response.AbnStatus = 'Active';
        businessNameList.add('Coles');
        response.BusinessName = businessNameList;
        ABNValidatorController.saveABNInformation(account, JSON.serialize(response));

        account = [SELECT Id, ABN__c,Exclude_from_ABN_Validator_Clean_up__c FROM Account WHERE Id = :account.Id];

        System.assertEquals(null, account.ABN__c);
        
        response.AbnStatus = '';

        ABNValidatorController.saveABNInformation(account, JSON.serialize(response));
    }
    
    @IsTest
    private static void testSaveNameInformation(){
        Test.setMock(HttpCalloutMock.class, new NameLookupResponseMock());
        Test.startTest();
        
        Account account = [SELECT Id, Name, ABN_Active__c,Provider_Name_Updated_by_ABN_Validator_S__c, 
                           ABN_Validated__c, ABN__c,Exclude_from_ABN_Validator_Clean_up__c 
                           FROM Account 
                           LIMIT 1]; 
        
        List<String> businessNameList = new List<String>();
        businessNameList.add('Coles');
        businessNameList.add('NIGHTNDAY');
        
        ABRService.ABNLookupResponse response = new ABRService.ABNLookupResponse();
       	response.AbnStatus = 'Active';
        response.BusinessName = businessNameList;
               
        ABNValidatorController.saveABNInformation(account, JSON.serialize(response));
        Test.stopTest();
    }
    
    @IsTest
    private static void saveABNToAccountTest() {
        
        Account account = [SELECT Id, Name, ABN_Active__c,Provider_Name_Updated_by_ABN_Validator_S__c, 
                           ABN_Validated__c, ABN__c,Exclude_from_ABN_Validator_Clean_up__c 
                           FROM Account 
                           LIMIT 1];
		
        List<String> businessNameList = new List<String>();
        businessNameList.add('Coles');
        
        ABRService.ABNLookupResponse response = new ABRService.ABNLookupResponse();
        response.AbnStatus = 'Active';
        response.BusinessName = businessNameList;
        
        ABNValidatorController.saveABNToAccount('98050042772', JSON.serialize(response),account.Id);

        
        response.AbnStatus = '';

    }
}