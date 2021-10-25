/**
 * Selector class for user object       :
 * @author            : Emily Jiang
 * @group             :
 * @last modified on  : 21/07/2021
 * @last modified by  : Emily Jiang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   21/07/2021   Emily Jiang   Initial Version
 **/
public inherited sharing class LSC_UserSelector {
  static final List<String> PORTAL_USER_TYPES = new List<String>{
    'CSPLitePortal',
    'PowerCustomerSuccess'
  };

  /**
   * Check if user is portal user
   * @author Emily Jiang | 21/07/2021
   * @param contactIds
   * @return List<User>
   **/
  public static List<User> getPortalContact(List<Id> contactIds) {
    return [
      SELECT Id, Name, Contact.CreatedDate, Contact.Email
      FROM User
      WHERE
        ContactId IN :contactIds
        AND UserType IN :PORTAL_USER_TYPES
        AND IsActive = TRUE
      ORDER BY CreatedDate ASC
    ];
  }
}