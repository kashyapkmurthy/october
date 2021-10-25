@IsTest
private class LSC_AuthProviderSelector_Test {
  @IsTest
  static void testAuthProvider() {
    String providerName = 'myservicensw';
      List<AuthProvider> providerList;
      Test.startTest();
      providerList = LSC_AuthProviderSelector.getAuthProviderByDeveloperName(providerName);
      Test.stopTest();
      System.assertEquals(providerList.size(), 1);
  }
}