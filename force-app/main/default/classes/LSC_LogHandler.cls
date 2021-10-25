/**
 * Feature:PS-136: Error Handling
 * Author: Kashyap Murthy - DCS
 */

public class LSC_LogHandler{
    
    //Save information log
    public static void logInformation(String className, String methodName, String description){
        LSC_Log__c log = new LSC_Log__c();
        log.LSC_Class__c = className;
        log.LSC_Method__c = methodName;
        log.LSC_Description__c = description;
        log.LSC_Type__c = 'Information';
        log.RecordTypeId = Schema.SObjectType.LSC_Log__c.getRecordTypeInfosByName().get('Info').getRecordTypeId();
        insert log;
    }
     
    //Save exception log    
    public static void logException(String className, String methodName, String description, Integer lineNumber,String stackTrace){
        LSC_Log__c log = new LSC_Log__c();
        log.LSC_Class__c = className;
        log.LSC_Method__c = methodName;
        log.LSC_Description__c = description;
        log.LSC_Type__c = 'Error';
        log.RecordTypeId = Schema.SObjectType.LSC_Log__c.getRecordTypeInfosByName().get('Error').getRecordTypeId();
        log.LSC_LineNumber__c = String.valueof(lineNumber);
        log.LSC_StackTrace__c = stackTrace;
        insert log;
    }
     
    //Save HTTP response log
    public static void logHTTPResponse(String className, String methodName, String description, HttpResponse response){
        LSC_Log__c log = new LSC_Log__c();
        log.LSC_Class__c = className;
        log.LSC_Method__c = methodName;
        log.LSC_Description__c = description;
        log.LSC_Type__c = 'Response';
        log.RecordTypeId = Schema.SObjectType.LSC_Log__c.getRecordTypeInfosByName().get('Info').getRecordTypeId();
        if(response != null){
            log.LSC_HTTPResponse__c = response.getBody();
            log.LSC_HTTPStatusCode__c = response.getStatusCode();         
        }
        insert log;
    }
    
    //Save HTTP Request log
    public static void logHTTPRequest(String className, String methodName, String description, HttpRequest request, String type){
        LSC_Log__c log = new LSC_Log__c();
        log.LSC_Class__c = className;
        log.LSC_Method__c = methodName;
        log.LSC_Description__c = description;
        log.LSC_Type__c = 'Request';
        log.RecordTypeId = Schema.SObjectType.LSC_Log__c.getRecordTypeInfosByName().get('Info').getRecordTypeId();
        if(request!= null){
            log.LSC_HTTPRequest__c = request.getBody();        
        }
        insert log;
    }
    //Save HTTP response log
    public static void logHTTPResponseError(String className, String methodName, String description, HttpResponse response){
        LSC_Log__c log = new LSC_Log__c();
        log.LSC_Class__c = className;
        log.LSC_Method__c = methodName;
        log.LSC_Description__c = description;
        log.LSC_Type__c = 'Response';
        log.RecordTypeId = Schema.SObjectType.LSC_Log__c.getRecordTypeInfosByName().get('Info').getRecordTypeId();
        if(response != null){
            log.LSC_HTTPResponse__c = response.getBody();
            log.LSC_HTTPStatusCode__c = response.getStatusCode();         
        }
        insert log;
    }
}