/**
 * @description       : Test class for LSC_BannerMessageController
 * @author            : Emily Jiang
 * @group             :
 * @last modified on  : 30/08/2021
 * @last modified by  : Emily Jiang
 **/
@isTest
private class LSC_BannerMessageControllerTest {
  @isTest
  static void getBannerMessageTest() {
    Banner_Message__mdt message;
    Test.startTest();
    message = LSC_BannerMessageController.getBannerMessage();
    Test.stopTest();
    System.assertNotEquals(message, null);
  }
}