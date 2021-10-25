@IsTest
private with sharing class LSC_FetchOwnerBuilderLicenceDetail_Test {

    
    @IsTest private static void testApexContinuation() {
        String mockResponseBody =  '{"licenceDetails": {"licenceID": "1-3JGWGTB","licenceNumber": "460391P","status": "Current","startDate": "2020/04/09","expiryDate": null,"licenceType": "Owner Builder Permit","licensee": "Sam Al Maraee"}}';
        Test.startTest();
        Continuation con = (Continuation) LSC_FetchOwnerBuilderLicenceDetail.startOwnerBuilderContinuation ('460391P');
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_FetchOwnerBuilderLicenceDetail.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchOwnerBuilderLicenceDetail.continuationState);

 
        LSC_FetchOwnerBuilderLicenceDetail.OwnerBuilderWrapper result = (LSC_FetchOwnerBuilderLicenceDetail.OwnerBuilderWrapper) LSC_FetchOwnerBuilderLicenceDetail.continuationCallback(label, LSC_FetchOwnerBuilderLicenceDetail.continuationState);
        Test.stopTest();
    }

    @IsTest private static void testContinuationExceptionCaptured() {
        Test.startTest();
        Continuation con = (Continuation) LSC_FetchOwnerBuilderLicenceDetail.startOwnerBuilderContinuation('460391P');
     
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(2000);
        Test.setContinuationResponse(LSC_FetchOwnerBuilderLicenceDetail.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchOwnerBuilderLicenceDetail.continuationState);
 
        Boolean exceptionThrown = false;
        try {
            Object result = LSC_FetchOwnerBuilderLicenceDetail.continuationCallback(label, LSC_FetchOwnerBuilderLicenceDetail.continuationState);
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();
         
        System.assert(exceptionThrown, 'Failed to catch continuation exception');         
    }

    @IsTest private static void testHttpRequestExceptionCaptured() {

        String mockResponseBody = '{"timestamp": "2021-02-10T23:22:04.831Z",  "statusCode": "500",  "error": "Internal server error",  "message": "licenceID has incorrect value"}';
        Test.startTest();
        Continuation con = (Continuation)LSC_FetchOwnerBuilderLicenceDetail.startOwnerBuilderContinuation('460391P');
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_FetchOwnerBuilderLicenceDetail.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchOwnerBuilderLicenceDetail.continuationState); 
        
        try {
            Object obj = LSC_FetchOwnerBuilderLicenceDetail.continuationCallback(label, LSC_FetchOwnerBuilderLicenceDetail.continuationState);
        } catch(AuraHandledException e) {
            Boolean exceptionThrown = false;
            exceptionThrown = true;
        }
        Test.stopTest();

    }
    
}