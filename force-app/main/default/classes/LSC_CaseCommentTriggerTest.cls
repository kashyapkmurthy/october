@isTest
private class LSC_CaseCommentTriggerTest {
    @TestSetup
    static void makeData() {
        Id sysAdminprofileId = [SELECT Id FROM Profile WHERE Profile.Name = 'System Administrator']
        .Id;
        Id userRleId = [SELECT Id FROM UserRole WHERE DeveloperName = 'LSC_Director'].Id;
        Id transInstalmentRecTypeId = LSC_Transaction__c.sObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('LSC_Instalment')
            .getRecordTypeId();
        Id transInterestRecTypeId = LSC_Transaction__c.sObjectType.getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('LSC_Interest')
            .getRecordTypeId();
        User sysAdmn = new User(
            email = 'admincorp@gmail.com',
            profileid = sysAdminprofileId,
            UserName = 'greg.chapel@gmail.com' + '.test',
            Alias = 'GCL',
            FirstName = 'Greg',
            LastName = 'Chapel',
            userRoleId = userRleId,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'Australia/Sydney',
            LocaleSidKey = 'en_AU',
            LanguageLocaleKey = 'en_US'
        );
        insert sysAdmn;
        System.runAs(sysAdmn) {
            Id profileId = [
                SELECT Id
                FROM Profile
                WHERE Profile.Name = 'LSC Customer Community Login User'
            ]
            .Id;
            Id accIndividualRecordTypeId = Account.sObjectType.getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('LSC_Individual')
                .getRecordTypeId();
            Id accBusinessRecordTypeId = Account.sObjectType.getDescribe()
                .getRecordTypeInfosByDeveloperName()
                .get('LSC_Business')
                .getRecordTypeId();
            //Business Account
            Account businessAccount = new Account(
                name = 'BusinessAccount',
                Type = 'Commercial',
                recordTypeId = accBusinessRecordTypeId
            );
            insert businessAccount;
            Contact businessContact = new contact(
                LastName = 'Businessuser',
                AccountId = businessAccount.Id,
                email = 'greg.chapel@gmail.com'
            );
            insert businessContact;
            AccountContactRelation acr = [
                SELECT Id, LSC_IsLevyPayer__c
                FROM AccountContactRelation
                WHERE ContactId = :businessContact.Id
            ];
            acr.LSC_IsLevyPayer__c = true;
            update acr;
            User u1 = new User(
                email = 'greg.chapel@gmail.com',
                profileid = profileId,
                UserName = 'greg.chapel@gmail.com' + '.test7654',
                Alias = 'GCL',
                ContactId = businessContact.Id,
                FirstName = 'Greg',
                LastName = 'Chapel',
                EmailEncodingKey = 'UTF-8',
                TimeZoneSidKey = 'Australia/Sydney',
                LocaleSidKey = 'en_AU',
                LanguageLocaleKey = 'en_US'
            );
            insert u1;

            List<LSC_Levy__c> levyList = LSC_TestDataFactory.createLevy(
                1,
                businessAccount,
                businessContact
            );
            insert levyList;

            Id instalmentCaseRT = Schema.SObjectType.Case.getRecordTypeInfosByName()
                .get('Instalment')
                .getRecordTypeId();
            List<Case> cases = LSC_TestDataFactory.createCase(
                1,
                businessAccount,
                businessContact,
                levyList[0],
                instalmentCaseRT
            );
            insert cases;
        }
    }

    @IsTest
    static void CaseCommentTriggerTest() {
        Case theCase = [SELECT Id FROM Case LIMIT 1];
        CaseComment newCaseComment = new CaseComment();
        newCaseComment.CommentBody = 'test comment';
        newCaseComment.ParentId = theCase.Id;

        Test.startTest();
        insert newCaseComment;
        Test.stopTest();

        CaseComment result = [SELECT Id, IsPublished FROM CaseComment LIMIT 1]; 
        System.assertEquals(result.IsPublished, true);
    }

    @IsTest
    static void testUnusedMethod() {
        Case theCase = [SELECT Id FROM Case LIMIT 1];
        CaseComment newCaseComment = new CaseComment();
        newCaseComment.CommentBody = 'test comment';
        newCaseComment.ParentId = theCase.Id;
        insert newCaseComment;

        Map<Id, SObject> items = new Map<Id, SObject>();
        items.put(newCaseComment.Id, newCaseComment);
        Test.startTest();
        LSC_CaseCommentTriggerHandler handler = new LSC_CaseCommentTriggerHandler();
        handler.BeforeUpdate(items, items);
        handler.AfterUpdate(items, items);
        handler.BeforeDelete(items);
        handler.AfterInsert(items);
        handler.AfterDelete(items);
        handler.AfterUndelete(items);

        LSC_ProcessCaseCommentBeforeInsert controler = new LSC_ProcessCaseCommentBeforeInsert();
        Test.stopTest();
    }
}