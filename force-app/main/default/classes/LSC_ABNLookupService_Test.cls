@IsTest
private class LSC_ABNLookupService_Test {
    public LSC_ABNLookupService_Test() {

    }

    @IsTest private static void testApexContinuation() {
        //String mockResponseBody = '{"data":{"australianBusinessNumber":"35123321148","australianBusinessNumberStatus":"Active","australianCompanyName":"123321148","acncRegistrationStatus":"Registered","businessName":["Melanoma and Skin Cancer Research Institute","Melanoma Foundation Australia"],"charityTypeName":"Health Promotion Charity","effectiveFrom":"2007-01-05","entityName":"MELANOMA INSTITUTE AUSTRALIA","entityTypeCode":"PUB","entityTypeName":"Australian Public Company"}}';
        
        String mockResponseBody = '{"business": {"australianBusinessNumber":"35123321148","australianBusinessNumberStatus":"Active","australianCompanyName":"123321148","acncRegistrationStatus":"Registered","businessName":["Melanoma and Skin Cancer Research Institute","Melanoma Foundation Australia"],"charityTypeName":"Health Promotion Charity","effectiveFrom":"2007-01-05","entityName":"MELANOMA INSTITUTE AUSTRALIA","entityTypeCode":"PUB","entityTypeName":"Australian Public Company"}}';
        Test.startTest();
        Continuation con = (Continuation) LSC_ABNLookupService.startABNContinuation('35123321148');
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_ABNLookupService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_ABNLookupService.continuationState);

 
        LSC_ABNLookupService.Data result = (LSC_ABNLookupService.Data) LSC_ABNLookupService.continuationCallback(label, LSC_ABNLookupService.continuationState);
        Test.stopTest();
         
        System.assertEquals('MELANOMA INSTITUTE AUSTRALIA', result.business.entityName, 'Continuation failed: response body not valid');
        System.assertEquals('Australian Public Company', result.business.entityTypeName, 'Continuation failed: response body not valid');
        System.assertEquals('35123321148', result.business.australianBusinessNumber, 'Continuation failed: response body not valid');
        System.assertEquals('123321148', result.business.australianCompanyName, 'Continuation failed: response body not valid');
        System.assertEquals('2007-01-05', result.business.effectiveFrom, 'Continuation failed: response body not valid');
        System.assertEquals('PUB', result.business.entityTypeCode, 'Continuation failed: response body not valid');
        System.assertEquals('Health Promotion Charity', result.business.charityTypeName, 'Continuation failed: response body not valid');
        System.assertEquals('Registered', result.business.acncRegistrationStatus, 'Continuation failed: response body not valid');   
        System.assertEquals('Active', result.business.australianBusinessNumberStatus, 'Continuation failed: response body not valid');  
            
    }

    @IsTest private static void testContinuationExceptionCaptured() {
        Test.startTest();
        Continuation con = (Continuation) LSC_ABNLookupService.startABNContinuation('35123321148');
     
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(2000);
        Test.setContinuationResponse(LSC_ABNLookupService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_ABNLookupService.continuationState);
 
        Boolean exceptionThrown = false;
        try {
            Object result = LSC_ABNLookupService.continuationCallback(label, LSC_ABNLookupService.continuationState);
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
         
        System.assert(exceptionThrown, 'Failed to catch continuation exception');         
    }

    @IsTest private static void testHttpRequestExceptionCaptured() {

        String mockResponseBody = '{"correlationId": null,  "timestamp": "2021-02-10T23:22:04.831Z",  "statusCode": "WEBSERVICES",  "error": "Search text is not a valid ABN or ACN",  "message": "Search text is not a valid ABN or ACN"}';
        Test.startTest();
        Continuation con = (Continuation) LSC_ABNLookupService.startABNContinuation('35123321148');
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(400);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_ABNLookupService.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_ABNLookupService.continuationState);

 
        
        try {
            Object obj = LSC_ABNLookupService.continuationCallback(label, LSC_ABNLookupService.continuationState);
        } catch(AuraHandledException e) {
            Boolean exceptionThrown = false;
            exceptionThrown = true;
        }
        Test.stopTest();
        
    }


    
}