//This is the code added by Kashyap Murthy
public with sharing class LSC_ABNLookupService {

    @TestVisible
    public static String continuationState;

    public Data data;
	
	//Call from LWC Component.
    @AuraEnabled(continuation=true cacheable=true)
	
    public static Object startABNContinuation(String abn) {
        String encodedString = EncodingUtil.urlEncode(abn, 'UTF-8');
        String endPointUrl = 'callout:MulesoftABN'+'/api/v1/abn/'+encodedString;
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
        HttpResponse response = Continuation.getResponse(labels[0]);
        String responseString = response.getBody();
        Integer statusCode = response.getStatusCode();
        
        // === For dev environment testing ===
        // StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'abnLookupResponseForDevSandbox' LIMIT 1];
        // String responseString = sr.Body.toString();
        // Integer statusCode = 200;

        if (statusCode == 200) {
            Data lookup = (Data) System.JSON.deserialize(responseString, Data.class);
            return lookup;//response.getBody();
        } else if(statusCode >= 2000) {
            // Handle continutation-specific error codes
            // See <a href="https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Continuation.htm">https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_System_Continuation.htm</a>
            //LSC_LogHandler.logHTTPResponseError('LSC_ABNLookupService', 'continuationCallback', 'Continuation Error', response);
            throw new AuraHandledException('Continuation Error: ' + statusCode + ' - ' + response.getBody());
        } else {
            // Handle standard HTTP request errors
            Error error = (Error) System.JSON.deserialize(responseString, Error.class);
            //LSC_LogHandler.logHTTPResponseError('LSC_ABNLookupService', 'continuationCallback', 'HTTP Error', response);
            throw new AuraHandledException('HTTP Request Error: ' + error.statusCode + ' - ' + error.message);
        }
    }

    public class Data {
        @AuraEnabled public Business business;
    }
     public class Business {
            @AuraEnabled public String australianBusinessNumber;
            @AuraEnabled public String australianBusinessNumberStatus;
            @AuraEnabled public String australianCompanyName;
            @AuraEnabled public String effectiveFrom;
            @AuraEnabled public String effectiveTo;
            @AuraEnabled public List<String> businessName;
            @AuraEnabled public String entityName;
            @AuraEnabled public String entityTypeCode;
            @AuraEnabled public String entityTypeName;
            @AuraEnabled public String charityTypeName;
            @AuraEnabled public String acncRegistrationStatus;
        }

    public class Error{
        @AuraEnabled public String correlationId;
	    @AuraEnabled public String timestamp;
	    @AuraEnabled public String statusCode;
	    @AuraEnabled public String error;
	    @AuraEnabled public String message;
    }
}