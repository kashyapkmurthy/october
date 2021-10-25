@IsTest
private with sharing class LSC_FetchCPPPaymentReferenceDetailTest {
    
    @IsTest private static void testApexContinuation() {
        String transactionData = '';
        String mockResponseBody =  '{"payments": [ { "paymentReference": "GPP-DIG-SvINuVX2SwyemM2UNcYb4A", "duplicateFlag": false  } ]}';
        Test.startTest();
        Continuation con = (Continuation) LSC_FetchCPPPaymentReferenceDetail.startCPPPaymentReferenceContinuation (transactionData);
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_FetchCPPPaymentReferenceDetail.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchCPPPaymentReferenceDetail.continuationState);

 
        LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceWrapper result = (LSC_FetchCPPPaymentReferenceDetail.PaymentReferenceWrapper) LSC_FetchCPPPaymentReferenceDetail.continuationCallback(label, LSC_FetchCPPPaymentReferenceDetail.continuationState);
        Test.stopTest();
    }

    @IsTest private static void testContinuationExceptionCaptured() {
        Test.startTest();
        String transactionData = '';
        Continuation con = (Continuation) LSC_FetchCPPPaymentReferenceDetail.startCPPPaymentReferenceContinuation (transactionData);
     
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(2000);
        Test.setContinuationResponse(LSC_FetchCPPPaymentReferenceDetail.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchCPPPaymentReferenceDetail.continuationState);
 
        Boolean exceptionThrown = false;
        try {
            Object result = LSC_FetchCPPPaymentReferenceDetail.continuationCallback(label, LSC_FetchCPPPaymentReferenceDetail.continuationState);
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();
         
        System.assert(exceptionThrown, 'Failed to catch continuation exception');         
    }
    
    @IsTest private static void testErrorResponse() {
        String transactionData = '';
        String mockResponseBody =  '{ "correlationId": null, "timestamp": null, "statusCode": 500, "message": null, "error": "HTTP POST on resource  failed: internal server error (500)." }';
        Test.startTest();
        Continuation con = (Continuation) LSC_FetchCPPPaymentReferenceDetail.startCPPPaymentReferenceContinuation (transactionData);
 
        // Verify that the continuation has the correct number of requests
        Map<String, HttpRequest> requests = con.getRequests();
        System.assertEquals(1, requests.size(), 'The number of requests associated to the Continuation is not correct');
 
        // Create a mock response
        HttpResponse response = new HttpResponse();
        response.setStatusCode(500);
        response.setBody(mockResponseBody);
 
        // Assign the mock response to the variable created for testing - for keeping the reference to the correct Continuation
        Test.setContinuationResponse(LSC_FetchCPPPaymentReferenceDetail.continuationState, response);

        List<String> label = new List<String>();
        label.add(LSC_FetchCPPPaymentReferenceDetail.continuationState);

 		Boolean exceptionThrown = false;
        try {
            Object result = LSC_FetchCPPPaymentReferenceDetail.continuationCallback(label, LSC_FetchCPPPaymentReferenceDetail.continuationState);
        } catch(AuraHandledException e) {
            exceptionThrown = true;
        }

        Test.stopTest();
         
        System.assert(exceptionThrown, 'Failed to catch continuation exception');   
    }
   }