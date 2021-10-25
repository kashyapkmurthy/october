/**
 * 
 * 
 * 
 */
public inherited sharing class LSC_FetchOwnerBuilderLicenceDetail {
    public LSC_FetchOwnerBuilderLicenceDetail() {

    }

    @TestVisible
    public static String continuationState;

    @AuraEnabled(continuation=true cacheable=true)
    public static Object startOwnerBuilderContinuation(String licenceNumber) {

        //addressText = '12 Raff';
        String encodedString = EncodingUtil.urlEncode(licenceNumber, 'UTF-8');
        //Done the changes for Spring 21 changes.
        LSC_URL_Setting__mdt ownerBuilderDetailMdt = LSC_URL_Setting__mdt.getInstance(LSC_GlobalConstants.LSC_CUSTOM_METADATA_NAME_OWNER_BUILDER);
        String baseUrl = ownerBuilderDetailMdt.LSC_URL_Mapping__c;
        
        String endPointUrl = baseUrl+encodedString;
        System.debug('endPointUrl owner builder'+endPointUrl);
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
        System.debug('response OwnerBuilderWrapper--->'+response.getBody());
        String responseString = response.getBody();
        Integer statusCode = response.getStatusCode();
        if (statusCode == 200) {
            OwnerBuilderWrapper ownerBuilderDetail = (OwnerBuilderWrapper) System.JSON.deserialize(responseString, OwnerBuilderWrapper.class);
            System.debug('response ownerBuilderDetail--->'+ownerBuilderDetail);
            return ownerBuilderDetail;
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

    public class OwnerBuilderWrapper {
        @AuraEnabled public LicenceDetails licenceDetails;
    }
    
    public class LicenceDetails {
        @AuraEnabled public String licenceID;
        @AuraEnabled public String licenceNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String startDate;
        @AuraEnabled public String expiryDate;
        @AuraEnabled public String licenceType;
        @AuraEnabled public String licensee;
    }

    public class Error{
        @AuraEnabled public String correlationId;
	    @AuraEnabled public String timestamp;
	    @AuraEnabled public String statusCode;
	    @AuraEnabled public String error;
	    @AuraEnabled public String message;
    }
}