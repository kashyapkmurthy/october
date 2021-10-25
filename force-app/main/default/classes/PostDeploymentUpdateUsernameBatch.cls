/**
 * @description       : Batch job to update username
 * @author            : Emily Jiang
 * @group             :
 * @last modified on  : 15/10/2021
 * @last modified by  : Emily Jiang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   15/10/2021   Emily Jiang   Initial Version
 **/
global with sharing class PostDeploymentUpdateUsernameBatch implements Database.Batchable<sObject> {
  global string query = 'SELECT Id, Name, Email, profile.name, isActive, username, account.name FROM User';
  global Database.QueryLocator start(Database.BatchableContext BC) {
    String profileName = 'LSC Customer Community Login User';
    String myServiceNSWName = 'MyServiceNSW Registration';
    query =
      query +
      ' Where profile.name =: profileName AND account.name !=: myServiceNSWName';
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<User> users) {
    System.debug(users.size());
    List<User> usersToUpdate = new List<User>();
    for (User u : users) {
      String username = LSC_Utility.constructUsername(u.email);
      if (u.username != username) {
        u.username = username;
        usersToUpdate.add(u);
      }
    }
    Database.update(usersToUpdate, false);
  }

  global void finish(Database.BatchableContext BC) {
  }
}