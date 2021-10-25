// MyServiceNSWRegHandler class implements the Auth.RegistrationHandler interface 
// are specified as the Registration Handler in authorization provider definitions, 
// and enable single sign-on into Salesforce portals and organizations from 
// third-party services such as MyServiceNSW
global class MyServiceNSWRegHandler implements Auth.RegistrationHandler{
    class RegHandlerException extends Exception {}
    // Returns a User object using the specified portal ID and user information
    // from the third party, such as the username and email address. The User 
    // object corresponds to the third party’s user information and may be a 
    // new user that hasn’t been inserted in the database or may represent an 
    // existing user record in the database.
    global User createUser(Id portalId, Auth.UserData data){
        if (LSC_Utility.isSandbox() && !Test.isRunningTest() && !LSC_Utility.isEmailAddressInWhiteList(data.email)) {
            throw new RegHandlerException(System.Label.Email_Address_Not_Allowed_In_Sandbox);   
        }
    
       // Check for existing user record
       String username = LSC_Utility.constructUsername(data.email);
       User[] users = [ SELECT id FROM user WHERE username =: username ];
       if (users.size() > 0) {
           return users[0];
       }
       
       // Check for existing incompleted registration user record
       String incompletedRegUsername = username + LSC_Utility.SNSW_INCOMPLETED_SUFFIX;
       User[] incompletedRegUsers = [ SELECT id FROM user WHERE username =: incompletedRegUsername ];
       if (incompletedRegUsers.size() > 0) {
           return incompletedRegUsers[0];
       }

       // Create a customer community login user with profile, but no permission set.
       // Get an actual account
       Account a =[SELECT Id FROM account WHERE name = 'MyServiceNSW Registration'];
       
       // Create a contact
       Contact c = new Contact();
       c.accountId = a.Id;
       c.email = data.email;
       c.lastName = data.lastName;
       c.LSC_InCompleteRegistration__c = TRUE;
       insert(c);
       
       // Create a customer community login user
        User u = new User();
        Profile p =[SELECT Id FROM profile WHERE name = 'LSC Customer Community Login User'];
        u.username = incompletedRegUsername;
        u.email = data.email;
        u.lastName = data.lastName;
        String alias = data.firstName;
        //Alias must be 8 characters or less
        if (alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.alias = alias;
        u.languagelocalekey = 'en_US';
        u.localesidkey = 'en_US';
        u.emailEncodingKey = 'UTF-8';
        u.timeZoneSidKey = 'Australia/Sydney';
        u.profileId = p.Id;
        u.contactId = c.Id;
        u.LSC_Registration_Type__c = 'SNSW';
        return u;
    }
    
    // Updates the specified user’s information. This method is called 
    // if the user has logged in before with the authorization provider 
    // and then logs in again.
    global void updateUser(Id userId, Id portalId, Auth.UserData data){

    }
}