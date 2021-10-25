public class LSC_FetchCPPPaymentReferenceDetail {

    @TestVisible
    public static String continuationState;

    @AuraEnabled(continuation=true cacheable=true)
    public static Object startCPPPaymentReferenceContinuation(String transactionData) {

        //addressText = '12 Raff';
        //String encodedString = EncodingUtil.urlEncode(licenceNumber, 'UTF-8');
        //Done the changes for Spring 21 changes.
        LSC_URL_Setting__mdt cppPaymentRefDetailMdt = LSC_URL_Setting__mdt.getInstance(LSC_GlobalConstants.LSC_CUSTOM_METADATA_NAME_CPP_PAYMENT_REFERENCE);
        String baseUrl = cppPaymentRefDetailMdt.LSC_URL_Mapping__c;
                                                 
        String body = transactionData;
        String endPointUrl = baseUrl;//+encodedString
        System.debug('endPointUrl owner builder'+endPointUrl);
        System.debug('body'+body);
        // Create the callout Request
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setEndpoint(endPointUrl);
        req.setBody(body);
 
        // Create the continuation with a 40s timeout
        Continuation con = new Continuation(20);
        con.ContinuationMethod = 'continuationCallback';
        // Store the HttRequest and make it accessible for a testing-context
        continuationState = con.addHttpRequest(req);
        con.state = continuationState;
 
        return con;
    }

    @AuraEnabled(cacheable=true)
    public static Object continuationCallback(List<String> labels, Object state) {
        // Get the response
        System.debug('(String) state'+(String) state);
        HttpResponse response = Continuation.getResponse(labels[0]);
        System.debug('response OwnerBuilderWrapper--->'+response.getBody());
        String responseString = response.getBody();
        Integer statusCode = response.getStatusCode();
        if (statusCode == 200) {
            PaymentReferenceWrapper paymentReferenceDetail = (PaymentReferenceWrapper) System.JSON.deserialize(responseString, PaymentReferenceWrapper.class);
            System.debug('response ownerBuilderDetail--->'+paymentReferenceDetail);
            return paymentReferenceDetail;
            //return response.getBody();
        } else if(statusCode >= 2000) {
            // Handle continutation-specific error codes
            // See <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Continuation.htm">https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Continuation.htm</a>
            throw new AuraHandledException('Continuation Error: ' + statusCode + ' - ' + response.getBody());
        } else {
            Error error = (Error) System.JSON.deserialize(responseString, Error.class);
            throw new AuraHandledException(error.message);
        }
    }

    public class PaymentReferenceWrapper {
        @AuraEnabled public List<PaymentResponse> payments;
    }

    public class PaymentReferenceRequestWrapper {
        @AuraEnabled public List<PaymentRequest> payments;
    }

	public class PaymentRequest {
		@AuraEnabled public String paymentDescription;
		@AuraEnabled public Decimal amount;
		@AuraEnabled public String applicationNumber;
		@AuraEnabled public String transactionId;
		@AuraEnabled public String paymentCaller;
		@AuraEnabled public String paymentScheme;
	}


	public class PaymentResponse {
        @AuraEnabled public String paymentReference;
        @AuraEnabled public Boolean duplicateFlag;
	}
    public class Error{
        @AuraEnabled public String correlationId;
	    @AuraEnabled public String timestamp;
	    @AuraEnabled public String statusCode;
	    @AuraEnabled public String error;
	    @AuraEnabled public String message;
    }
}