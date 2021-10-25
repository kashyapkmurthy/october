@isTest
private class LSC_LogHandler_Test {
    
    static testMethod void createlogInformationTest() {
        
        String className   = 'LSC_LogHandler_Test';
        String methodName  = 'logInformation';
        String description = 'Exception while saving';
        String type        = 'Information';

        Test.startTest();
            LSC_LogHandler.logInformation(className, methodName, description);
        Test.stopTest();
        LSC_Log__c log = [select id, LSC_Class__c from LSC_Log__c limit 1];
        System.assertEquals('LSC_LogHandler_Test', log.LSC_Class__c);
    }   

    
    static testMethod void createExeptionTest() {
        
        String className   = 'LSC_LogHandler_Test';
        String methodName  = 'logException';
        String description = 'Error while saving';
        String stackTrace  = 'Error StackTrace';
        Integer lineNumber  = 22;

        Test.startTest();
            LSC_LogHandler.logException(className, methodName, description, lineNumber, stackTrace);
        Test.stopTest();

        LSC_Log__c log = [select id, RecordType.Name, LSC_Class__c, LSC_LineNumber__c, LSC_Type__c from LSC_Log__c limit 1];
        System.assertEquals('Error', log.RecordType.Name,'Exception Logged Successfully');
    }

    static testMethod void createResponseTest() {
        
        String className   = 'LSC_LogHandler_Test';
        String methodName  = 'logHTTPResponse';
        String description = 'Response from Server';
        String type        = 'Response';

        HttpResponse response = new HttpResponse();
        response.setBody('{"startDate":null,"stage":null,"presetInstal":"8750.00","payNo":"1","id":"0","estimatedCost":null,"dueDate":"08-05-2021"}');
        response.setStatusCode(200);

        Test.startTest();
            LSC_LogHandler.logHTTPResponse(className, methodName, description, response);
        Test.stopTest();

        LSC_Log__c log = [select id, LSC_Class__c, LSC_LineNumber__c, LSC_Type__c, LSC_HTTPStatusCode__c, LSC_HTTPResponse__c from LSC_Log__c limit 1];
        System.assertEquals('{"startDate":null,"stage":null,"presetInstal":"8750.00","payNo":"1","id":"0","estimatedCost":null,"dueDate":"08-05-2021"}', log.LSC_HTTPResponse__c, 'HTTP Response Logged Successfully');
    }

    //

    static testMethod void createRequestTest() {
        
        String className   = 'LSC_LogHandler_Test';
        String methodName  = 'logHTTPRequest';
        String description = 'Request from Server';
        String type        = 'Request';

        HttpRequest request = new HttpRequest();
        request.setBody('{"id":"123454678"}');

        Test.startTest();
            LSC_LogHandler.logHTTPRequest(className, methodName, description, request, type);
        Test.stopTest();

        LSC_Log__c log = [select id, LSC_Class__c, LSC_LineNumber__c, LSC_Type__c, LSC_HTTPStatusCode__c, LSC_HTTPRequest__c from LSC_Log__c limit 1];
        System.assertEquals('{"id":"123454678"}', log.LSC_HTTPRequest__c,'HTTP Request Logged Successfully');
    }
    static testMethod void createResponseErrorTest() {
        
        String className   = 'LSC_LogHandler_Test';
        String methodName  = 'logHTTPResponse';
        String description = 'Response from Server';
        String type        = 'Response';

        HttpResponse response = new HttpResponse();
        response.setBody('{"startDate":null,"stage":null,"presetInstal":"8750.00","payNo":"1","id":"0","estimatedCost":null,"dueDate":"08-05-2021"}');
        response.setStatusCode(200);

        Test.startTest();
            LSC_LogHandler.logHTTPResponseError(className, methodName, description, response);
        Test.stopTest();

        LSC_Log__c log = [select id, LSC_Class__c, LSC_LineNumber__c, LSC_Type__c, LSC_HTTPStatusCode__c, LSC_HTTPResponse__c from LSC_Log__c limit 1];
        System.assertEquals('{"startDate":null,"stage":null,"presetInstal":"8750.00","payNo":"1","id":"0","estimatedCost":null,"dueDate":"08-05-2021"}', log.LSC_HTTPResponse__c, 'HTTP Response Error Logged Successfully');
    }

}