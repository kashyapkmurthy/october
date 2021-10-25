public class LSC_FetchAddressDetailService {

    @TestVisible
    public static String continuationState;

    @AuraEnabled(continuation=true cacheable=true)
    public static Object startAddressContinuation(String addressId) {

        //addressText = '12 Raff';
        String encodedString = EncodingUtil.urlEncode(addressId, 'UTF-8');
        //Done the changes for Spring 21 changes.
        //LSC_URL_Setting__mdt addressDetailMdt = LSC_URL_Setting__mdt.getInstance('Address Detail');
        //String baseUrl = addressDetailMdt.LSC_URL_Mapping__c;
        
        String endPointUrl = 'callout:Mulesoft'+'/api/v1/addresses/'+encodedString;
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
            AddressDetailWrapper addressDetail = (AddressDetailWrapper) System.JSON.deserialize(responseString, AddressDetailWrapper.class);
            return addressDetail;
            //return response.getBody();
        } else if(statusCode >= 2000) {
            // Handle continutation-specific error codes
            // See <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Continuation.htm">https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Continuation.htm</a>
            throw new AuraHandledException('Continuation Error: ' + statusCode + ' - ' + response.getBody());
        } else {
            Error error = (Error) System.JSON.deserialize(responseString, Error.class);
            throw new AuraHandledException('HTTP Request Error: ' + error.statusCode + ' - ' + error.message);
        }
    }

    public class AddressDetailWrapper {
        @AuraEnabled public AddressDetails addressDetails;
    }

	public class AddressDetails {
        @AuraEnabled public String fullAddress;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String country;
        @AuraEnabled public String postcode;
        @AuraEnabled public Double longitude;
        @AuraEnabled public Double latitude;
        @AuraEnabled public String addressId;
    }

    public class Error{
        @AuraEnabled public Object correlationId;
	    @AuraEnabled public String timestamp;
	    @AuraEnabled public String statusCode;
	    @AuraEnabled public String error;
	    @AuraEnabled public String message;
    }

}