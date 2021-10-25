@isTest
public class LSC_CaseListControllerTest {

    @isTest
    public static void getCases() {
        //UserRole userRole_1 = [SELECT Id FROM UserRole LIMIT 1];

        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User'].Id;
        User u = LSC_TestDataFactory.createUser(profileId, 'aaa');
        u.ContactId = contacts[0].Id;
        //u.UserRoleId = userRole_1.Id;
        insert u;
        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exemption').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], null, caseRT);
        cases[0].Status = 'Closed Approved';
        insert cases;
        ContentVersion cv = LSC_TestDataFactory.createContent();
        insert cv;
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = cases[0].Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'I';
        cdl.Visibility = 'AllUsers'; 
        insert cdl;
        System.runAs(u) {
            Test.startTest();
            List<LSC_CaseListController.Wrapper> casesResult = LSC_CaseListController.getCases('closed', 'status', 'ASC');
            System.assert(casesResult.size() > 0);
            LSC_CaseRecordController.CaseWrapper cw = LSC_CaseRecordController.getCase(casesResult[0].id);
            System.assert(cw.subject == 'Test case');
            List<String> contents = LSC_CaseRecordDetailsController.getAttachments(cw.id);
            System.assert(contents.size() > 0);
            List<String> docIds = new List<String>();
            docIds.add(documents[0].Id);
            String s = LSC_CaseCommentsController.deleteDocuments(docIds);
            System.assert(s == 'FAILED'); //Insufficient access
            LSC_CaseCommentsController.createComment(cw.id, 'abc', null);
            List<LSC_CaseCommentsController.Wrapper> comments = LSC_CaseCommentsController.getComments(cw.id);
            System.assert(comments.size() == 1);
            LSC_CaseCommentsController.ResultWrapper rw = LSC_CaseCommentsController.createComment(cw.id, 'abc', docIds);
            System.assert(rw.error == 'Internal error');
            Test.stopTest();
        }
    }

    @isTest
    public static void getCasesWithOutKey() {
        //UserRole userRole_1 = [SELECT Id FROM UserRole LIMIT 1];

        List<Account> accounts = LSC_TestDataFactory.createAccounts(1);
        insert accounts;
        List<Contact> contacts = LSC_TestDataFactory.createContact(1, accounts[0]);
        contacts[0].LSC_SelectedAccountId__c = accounts.get(0).Id;
        insert contacts;
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User'].Id;
        User u = LSC_TestDataFactory.createUser(profileId, 'aaa');
        u.ContactId = contacts[0].Id;
        insert u;
        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Exemption').getRecordTypeId();
        List<Case> cases = LSC_TestDataFactory.createCase(1, accounts[0], contacts[0], null, caseRT);
        cases[0].Status = 'Closed Approved';
        insert cases;
        ContentVersion cv = LSC_TestDataFactory.createContent();
        insert cv;
        List<ContentDocument> documents = [
            SELECT Id, Title, LatestPublishedVersionId 
            FROM ContentDocument
        ];
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = cases[0].Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'I';
        cdl.Visibility = 'AllUsers'; 
        insert cdl;
        System.runAs(u) {
            Test.startTest();
            List<LSC_CaseListController.Wrapper> casesResult = LSC_CaseListController.getCases(null, 'status', 'ASC');
            System.assert(casesResult.size() > 0);
            LSC_CaseRecordController.CaseWrapper cw = LSC_CaseRecordController.getCase(casesResult[0].id);
            System.assert(cw.subject == 'Test case');
            List<String> contents = LSC_CaseRecordDetailsController.getAttachments(cw.id);
            System.assert(contents.size() > 0);
            List<String> docIds = new List<String>();
            docIds.add(documents[0].Id);
            String s = LSC_CaseCommentsController.deleteDocuments(docIds);
            System.assert(s == 'FAILED'); //Insufficient access
            LSC_CaseCommentsController.createComment(cw.id, 'abc', null);
            List<LSC_CaseCommentsController.Wrapper> comments = LSC_CaseCommentsController.getComments(cw.id);
            System.assert(comments.size() == 1);
            LSC_CaseCommentsController.ResultWrapper rw = LSC_CaseCommentsController.createComment(cw.id, 'abc', docIds);
            System.assert(rw.error == 'Internal error');
            Test.stopTest();
        }
    }
}