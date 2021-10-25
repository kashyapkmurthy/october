@IsTest
private with sharing class LSC_FetchAddressService_Test {

    @IsTest private static void testApexContinuation() {
        String mockResponseBody =  '{"addresses": [ { "address": "18 PENTLAND AV, ROSELANDS NSW 2196", "id": "GANSW705839785", "rank": 0},  { "address": "18 PENTLAND CR, DUDLEY PARK WA 6210", "id": "GAWA_162413764", "rank": 1  } ] }';
        Test.startTest();
        Continuation con = (Continuation) LSC_FetchAddressService.startContinuation ('18 PENTLAND', 'All', '');
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_FetchAddressService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchAddressService.continuationState);

 
        LSC_FetchAddressService.AddressListWrapper result = (LSC_FetchAddressService.AddressListWrapper) LSC_FetchAddressService.continuationCallback(label, LSC_FetchAddressService.continuationState);
        Test.stopTest();

        //System.assertEquals(2, result.size(), '2 returned reults');        
            
    }

    @IsTest private static void testContinuationExceptionCaptured() {
        Test.startTest();
        Continuation con = (Continuation) LSC_FetchAddressService.startContinuation('18 PENTLAND', 'All', '');
     
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(2000);
        Test.setContinuationResponse(LSC_FetchAddressService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchAddressService.continuationState);
 
        Boolean exceptionThrown = false;
        try {
            Object result = LSC_FetchAddressService.continuationCallback(label, LSC_FetchAddressService.continuationState);
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
         
        System.assert(exceptionThrown, 'Failed to catch continuation exception');         
    }

    @IsTest private static void testHttpRequestExceptionCaptured() {

        String mockResponseBody = '{"correlationId": null,  "timestamp": "2021-02-10T23:22:04.831Z",  "statusCode": "WEBSERVICES",  "error": "Search text is not a valid ABN or ACN",  "message": "Search text is not a valid ABN or ACN"}';
        Test.startTest();
        Continuation con = (Continuation)LSC_FetchAddressService.startContinuation('18 PENTLAND', 'All', '');
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_FetchAddressService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchAddressService.continuationState); 
        
        try {
            Object obj = LSC_FetchAddressService.continuationCallback(label, LSC_FetchAddressService.continuationState);
        } catch(AuraHandledException e) {
            Boolean exceptionThrown = false;
            exceptionThrown = true;
        }
        Test.stopTest();

    }


}