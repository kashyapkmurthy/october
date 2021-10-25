/**
 * @description       :
 * @author            : Emily Jiang
 * @group             :
 * @last modified on  : 21/07/2021
 * @last modified by  : Emily Jiang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   21/07/2021   Emily Jiang   Initial Version
 **/
public inherited sharing class LSC_AccountContactRelationshipSelector {
  static final String ADMIN_ROLE = 'Admin';
  /**
   * Retrieve all the admin contact under the account, sort by created date
   * @author Emily Jiang | 21/07/2021
   * @param accountId
   * @return List<AccountContactRelation>
   **/
  public static List<AccountContactRelation> getAdminContactListByAccountId(
    Id accountId
  ) {
    return [
      SELECT Id, ContactId, AccountId, CreatedDate, Roles, IsActive
      FROM AccountContactRelation
      WHERE
        AccountId = :accountId
        AND Roles INCLUDES (:ADMIN_ROLE)
        AND IsActive = TRUE
      ORDER BY CreatedDate ASC
    ];
  }
}