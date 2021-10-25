/**
 * @description       : Controller class to get banner message configuration
 * @author            : Emily Jiang
 * @group             : 
 * @last modified on  : 30/08/2021
 * @last modified by  : Emily Jiang
**/
public with sharing class LSC_BannerMessageController {
  @AuraEnabled(cacheable=true)
  public static Banner_Message__mdt getBannerMessage() {
    Banner_Message__mdt message;
    List<Banner_Message__mdt> bannerMessages = [
      SELECT
        Message_Title__c,
        Message_Body__c,
        Is_Active__c,
        Start_Time__c,
        End_Time__c,
        Is_Critical__c
      FROM Banner_Message__mdt
    ];
    if (!bannerMessages.isEmpty()) {
      message = bannerMessages[0];
    }
    return message;
  }
}