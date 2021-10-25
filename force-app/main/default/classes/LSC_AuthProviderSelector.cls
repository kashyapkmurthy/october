/**
 * @description       : Selector class to query auth provider
 * @author            : Emily Jiang
 * @group             : 
 * @last modified on  : 07/09/2021
 * @last modified by  : Emily Jiang
**/
public with sharing class LSC_AuthProviderSelector {
  public static List<AuthProvider> getAuthProviderByDeveloperName(String developerName) {
    return [
      SELECT Id, DeveloperName
      FROM AuthProvider
      WHERE DeveloperName = :developerName
    ];
  }
}