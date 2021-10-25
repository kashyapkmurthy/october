public class LSC_FetchAddressService {

    @TestVisible
    public static String continuationState;

    @AuraEnabled(continuation=true cacheable=true)
    public static Object startContinuation(String addressText, String addressType, String addressState) {
        String endPointUrl;
        String encodedString = EncodingUtil.urlEncode(addressText, 'UTF-8');
        String encodedAddressType = EncodingUtil.urlEncode(addressType, 'UTF-8');
        String encodedAddressState = EncodingUtil.urlEncode(addressState, 'UTF-8');
        //Done the changes for Spring 21 changes.
        //LSC_URL_Setting__mdt addressListMdt = LSC_URL_Setting__mdt.getInstance('Address List');
        //String baseUrl = addressListMdt.LSC_URL_Mapping__c;

        endPointUrl = 'callout:Mulesoft'+'/api/v1/addresses?address='+encodedString+'&addressType='+encodedAddressType+'&stateTerritory='+encodedAddressState;
        // Create the callout Request
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint(endPointUrl);
 
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
        System.debug('response'+response.getBody());
        String responseString = response.getBody();
        Integer statusCode = response.getStatusCode();
        if (statusCode == 200) {
            //LSC_LogHandler.logHTTPResponse('FetchAddressService', 'continuationCallback', response.getBody(), response, 'Response');            
            AddressListWrapper addressList = (AddressListWrapper) System.JSON.deserialize(responseString, AddressListWrapper.class);
            return addressList;
        } else if(statusCode >= 2000) {
            // Handle continutation-specific error codes
            // See <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Continuation.htm">https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Continuation.htm</a>
            throw new AuraHandledException('Continuation Error: ' + statusCode + ' - ' + response.getBody());
        } else {
            // Handle standard HTTP request errors
            Error error = (Error) System.JSON.deserialize(responseString, Error.class);
            throw new AuraHandledException('HTTP Request Error: ' + error.statusCode + ' - ' + error.message);
        }
    }


    public class AddressListWrapper{
        @AuraEnabled public List<Addresses> addresses;
    }

    public class Addresses {
		@AuraEnabled public String address;
		@AuraEnabled public String id;
		@AuraEnabled public Integer rank;
	}


    public class Error{
        @AuraEnabled public Object correlationId;
	    @AuraEnabled public String timestamp;
	    @AuraEnabled public String statusCode;
	    @AuraEnabled public String error;
	    @AuraEnabled public String message;
    }
    

}