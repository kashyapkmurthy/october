@IsTest
private class LSC_SNSWCallouts_Test {
  @IsTest
  static void logoutSNSWUserTest() {
    MockHttpResponseGenerator response = new MockHttpResponseGenerator();
    LSC_SNSWCallouts.ResultWrapper result;
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, MockHttpResponseGenerator.jsonDelete200Ok());
    result = LSC_SNSWCallouts.logoutSNSWUser();
    Test.stopTest();
    System.assertEquals(result.success, true);
  }

  @IsTest
  static void logoutSNSWUserTestException() {
    MockHttpResponseGenerator response = new MockHttpResponseGenerator();
    LSC_SNSWCallouts.ResultWrapper result;
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, MockHttpResponseGenerator.jsonDelete400Exception());
    result = LSC_SNSWCallouts.logoutSNSWUser();
    Test.stopTest();
    System.assertEquals(result.success, false);
  }
}