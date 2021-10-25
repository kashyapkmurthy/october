@isTest
private class LSC_PermissionCheckUtility_Test {
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
        }
    }

    
    @isTest 
static void testIsGuestUser() {
        User u = [
            SELECT Id, FirstName, LastName
            FROM User
            WHERE FirstName = 'Greg' AND LastName = 'Chapel' AND Email = 'greg.chapel@gmail.com'
            LIMIT 1
        ];
        System.runAs(u) {
            Boolean isGuestUser = false;
            Test.startTest();
                isGuestUser = LSC_PermissionCheckUtility.isGuestUser(UserInfo.getUserId());
            Test.stopTest();
            System.assertEquals(isGuestUser, false);
        }
    }
}