/**
 * @description  [TTP-1502]Test class for ABN_WeeklyABNValidatorBatch
 * @company      Cloudwerx
 * @date         19/10/2021
**/
@isTest
public class ABN_WeeklyABNValidatorBatchTest {
    
    public class ABNLookupResponseMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            
            List<String> businessNameList = new List<String>();
        	businessNameList.add('Coles');

            ABRService.ABNLookupResponse abnLookupResponse = new ABRService.ABNLookupResponse();
            abnLookupResponse.AbnStatus = 'Active';
            abnLookupResponse.BusinessName = businessNameList;

            response.setBody(JSON.serialize(abnLookupResponse));

            return response;
        }
    }
    
    @IsTest
    private static void unitTest_ABNValidatorBatch() { 
        Account testProviderAccount = TestClassDataUtil.createProviderAccount(false, null, '29009415703');
        insert testProviderAccount;

        Account testProviderAccount1 = TestClassDataUtil.createProviderAccount(false, null, '');
        insert testProviderAccount1;
        Test.setMock(HttpCalloutMock.class, new ABNLookupResponseMock());
        Test.startTest();

        AsyncApexFramework.submitBatch(new ABN_WeeklyABNValidatorBatch(),1,99);
        AsyncApexFramework.flush();    

        
        ABN_WeeklyABNValidatorBatch testsche = new ABN_WeeklyABNValidatorBatch();
		String sch = '0 0 23 * * ?';
        system.schedule('Test status Check', sch, testsche );
        Test.stopTest();

    }
    
}