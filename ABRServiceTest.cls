@IsTest
public class ABRServiceTest {

    public class ABNLookupResponseMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);

            ABRService.ABNLookupResponse abnLookupResponse = new ABRService.ABNLookupResponse();
            abnLookupResponse.AbnStatus = 'Active';

            response.setBody(JSON.serialize(abnLookupResponse));

            return response;
        }
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
    private static void testABNLookup() {
        Test.setMock(HttpCalloutMock.class, new ABNLookupResponseMock());
        Test.startTest();

        ABRService.ABNLookup('12345678');

        Test.stopTest();
    }

    @IsTest
    private static void testNameLookup() {
        Test.setMock(HttpCalloutMock.class, new NameLookupResponseMock());
        Test.startTest();

        ABRService.NameLookup('Coles');

        Test.stopTest();
    }
}