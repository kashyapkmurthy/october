/**
 * Service class for account contact relation
 * @author            : Emily Jiang
 * @group             :
 * @last modified on  : 21/07/2021
 * @last modified by  : Emily Jiang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   21/07/2021   Emily Jiang   Initial Version
 **/
public inherited sharing class LSC_AccountContactRelationshipService {
  /**
   * get first portal admin user email address
   * @author Emily Jiang | 21/07/2021
   * @param accountId
   * @return String
   **/
  public static String getPortalAdminEmailAddress(Id accountId) {
    String portalAdminEmailAddress = '';
    List<AccountContactRelation> adminACRList = LSC_AccountContactRelationshipSelector.getAdminContactListByAccountId(
      accountId
    );
    List<Id> adminContactIds = new List<Id>();
    for (AccountContactRelation acr : adminACRList) {
      adminContactIds.add(acr.ContactId);
    }
    List<User> portalAdminUserList = LSC_UserSelector.getPortalContact(
      adminContactIds
    );
    if (!portalAdminUserList.isEmpty()) {
      portalAdminEmailAddress = portalAdminUserList[0].Contact.Email;
    }
    return portalAdminEmailAddress;
  }
}