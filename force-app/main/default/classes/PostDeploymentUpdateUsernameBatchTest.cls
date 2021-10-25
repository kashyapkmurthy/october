@isTest
private class PostDeploymentUpdateUsernameBatchTest {
  static final String COMM_USER_Email = 'communityUser1245@gmail.com';
  @testSetup
  static void setup() {
    Id sysAdminprofileId = [
      SELECT Id
      FROM Profile
      WHERE Profile.Name = 'System Administrator'
    ]
    .Id;
    Id userRleId = [
      SELECT Id
      FROM UserRole
      WHERE DeveloperName = 'LSC_Director'
    ]
    .Id;
    User sysAdmn = new User(
      email = 'john.doe@gmail.com',
      profileid = sysAdminprofileId,
      UserName = 'john.doe7549@gmail.com' + '.test',
      Alias = 'GCL',
      FirstName = 'John',
      LastName = 'Doe',
      userRoleId = userRleId,
      EmailEncodingKey = 'UTF-8',
      TimeZoneSidKey = 'Australia/Sydney',
      LocaleSidKey = 'en_AU',
      LanguageLocaleKey = 'en_US'
    );
    insert sysAdmn;
    System.runAs(sysAdmn) {
      Id accIndividualRecordTypeId = Account.sObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get('LSC_Individual')
        .getRecordTypeId();
      Id accBusinessRecordTypeId = Account.sObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get('LSC_Business')
        .getRecordTypeId();
      Account businessNfpAccount = new Account(
        name = 'BusinessNFPAccount',
        Type = 'Not-For-Profit',
        recordTypeId = accBusinessRecordTypeId,
        LSC_ABN__c = '43936428523'
      );
      insert businessNfpAccount;

      //Testing Perm Set assignment method - insert a community user
      Contact con = new contact(
        LastName = 'Businessuser',
        AccountId = businessNfpAccount.Id,
        email = 'greg4568.chapel@gmail.com'
      );
      insert con;

      Id profileId = [
        SELECT Id
        FROM Profile
        WHERE Name = 'LSC Customer Community Login User'
        LIMIT 1
      ]
      .Id;

      User commUser = new User(
        Email = COMM_USER_Email,
        UserName = COMM_USER_Email,
        FirstName = 'Peter',
        LastName = 'Pan',
        communityNickname = 'petPan',
        ProfileId = profileId,
        ContactId = con.Id,
        EmailEncodingKey = 'UTF-8',
        TimeZoneSidKey = 'Australia/Sydney',
        Alias = 'petPan',
        LocaleSidKey = 'en_AU',
        LanguageLocaleKey = 'en_US'
      );
      insert commUser;

      AccountContactRelation acr = [
        SELECT Id, AccountId, ContactId, Roles
        FROM AccountContactRelation
        WHERE AccountId = :businessNfpAccount.Id AND ContactId = :con.Id
        LIMIT 1
      ];
      acr.Roles = 'Admin';
      update acr;
    }
  }

  @isTest
  static void testBatch() {
    List<User> users = [
      SELECT Id, Name, Email, UserName
      FROM User
      WHERE UserName = :COMM_USER_Email
    ];
    System.assertEquals(users.size(), 1);
    test.startTest();
    PostDeploymentUpdateUsernameBatch batchJob = new PostDeploymentUpdateUsernameBatch();
    Database.executeBatch(batchJob);
    test.stopTest();
    List<User> usersAfterBatchUpdate = [
        SELECT Id, Name, Email, UserName
        FROM User
        WHERE UserName = :COMM_USER_Email
      ];
      System.assertEquals(usersAfterBatchUpdate.size(), 0);
  }
}