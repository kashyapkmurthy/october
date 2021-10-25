@IsTest
private class LSC_Utility_Test {
  @isTest
  static void testCreateAuraException() {
    String errorMessage = 'Test error message';
    Test.startTest();
    try {
      throw LSC_Utility.createAuraException(errorMessage);
    } catch (AuraHandledException ex) {
      System.assertEquals(ex.getMessage(), errorMessage);
    }
    Test.stopTest();
  }

  @isTest
  static void testIsSandbox() {
    Boolean isSandbox = false;
    Test.startTest();
    isSandbox = LSC_Utility.isSandbox();
    Test.stopTest();
    System.assertEquals(isSandbox, true);
  }

  @isTest
  static void testConstructUsername() {
    String email = 'testing@testing.com';
    String username;
    Test.startTest();
    username = LSC_Utility.constructUsername(email);
    Test.stopTest();
    System.assertNotEquals(username, email);
  }

  @isTest
  static void testReplaceDashWithHypen() {
    String stringToRepace =
      'abc' +
      LSC_Utility.EM_DASH +
      LSC_Utility.EN_DASH +
      'edf';
    String newString;
    Test.startTest();
    newString = LSC_Utility.replaceDashWithHypen(stringToRepace);
    Test.stopTest();
    System.assertEquals(newString.indexOf(LSC_Utility.EM_DASH), -1);
    System.assertEquals(newString.indexOf(LSC_Utility.EN_DASH), -1);
  }

  @isTest
  static void testCheckIfLoginPortalViaServiceCloud() {
    Boolean isLoginPortalViaServiceCloud;
    Test.startTest();
    isLoginPortalViaServiceCloud = LSC_Utility.checkIfLoginPortalViaServiceCloud();
    Test.stopTest();
    System.assertEquals(isLoginPortalViaServiceCloud, false);
  }

  @isTest
  static void testIsEmailAddressInWhiteList() {
    String randomStr = LSC_Utility.generateRandomString(5);
    String email = 'test@' + randomStr + '.com';

    Boolean isInAllowList = false;
    Test.startTest();
    isInAllowList = LSC_Utility.isEmailAddressInWhiteList(email);
    Test.stopTest();
    System.assertEquals(isInAllowList, false);
  }
}