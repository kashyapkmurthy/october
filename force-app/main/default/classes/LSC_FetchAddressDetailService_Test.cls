@IsTest
private with sharing  class LSC_FetchAddressDetailService_Test {
    @IsTest private static void testApexContinuation() {
        String mockResponseBody =  '{ "fullAddress": "12 RAFFERTY STREET, QUAKERS HILL NSW 2765", "street": "12 RAFFERTY STREET",  "city": "QUAKERS HILL", "state": "NSW", "country": "AU", "postcode": "2765", "longitude": 150.89055061, "latitude": -33.72969347, "addressId": "GANSW705746943" }';
        Test.startTest();
        Continuation con = (Continuation) LSC_FetchAddressDetailService.startAddressContinuation ('GANSW705746943');
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_FetchAddressDetailService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchAddressDetailService.continuationState);

 
        LSC_FetchAddressDetailService.AddressDetailWrapper result = (LSC_FetchAddressDetailService.AddressDetailWrapper) LSC_FetchAddressDetailService.continuationCallback(label, LSC_FetchAddressDetailService.continuationState);
        Test.stopTest();

        //System.assertEquals(2, result.size(), '2 returned reults');        
            
    }

    @IsTest private static void testContinuationExceptionCaptured() {
        Test.startTest();
        Continuation con = (Continuation) LSC_FetchAddressDetailService.startAddressContinuation('GANSW705746943');
     
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(2000);
        Test.setContinuationResponse(LSC_FetchAddressDetailService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchAddressDetailService.continuationState);
 
        Boolean exceptionThrown = false;
        try {
            Object result = LSC_FetchAddressDetailService.continuationCallback(label, LSC_FetchAddressDetailService.continuationState);
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
         
        System.assert(exceptionThrown, 'Failed to catch continuation exception');         
    }

    @IsTest private static void testHttpRequestExceptionCaptured() {

        String mockResponseBody = '{"correlationId": null,  "timestamp": "2021-02-10T23:22:04.831Z",  "statusCode": "WEBSERVICES",  "error": "Search text is not a valid ABN or ACN",  "message": "Search text is not a valid ABN or ACN"}';
        Test.startTest();
        Continuation con = (Continuation)LSC_FetchAddressDetailService.startAddressContinuation('GANSW705746943');
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_FetchAddressDetailService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchAddressDetailService.continuationState); 
        
        try {
            Object obj = LSC_FetchAddressDetailService.continuationCallback(label, LSC_FetchAddressDetailService.continuationState);
        } catch(AuraHandledException e) {
            Boolean exceptionThrown = false;
            exceptionThrown = true;
        }
        Test.stopTest();

    }
}