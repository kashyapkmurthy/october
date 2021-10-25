public without sharing class LSC_PermissionCheckUtility {
    final static String SITE_PROFILE_NAME = 'BCI Profile';
    public static Boolean isGuestUser(Id userId) {
        Boolean isGuestUser = false;
        User u = [SELECT Id, Name, Profile.Name FROM User WHERE Id =: userId Limit 1];
        if (u.Profile.Name == SITE_PROFILE_NAME) {
            isGuestUser = true;
        }
        return isGuestUser;
    }

    public static Boolean isIncompletedRegistrationUser(Id userId) {
        Boolean incompletedRegUser = false;
        List<User> users = [SELECT Id, Name, ContactId, Contact.LSC_InCompleteRegistration__c FROM User WHERE Id =: userId];
        if (!users.isEmpty() && users[0].ContactId != null && users[0].Contact.LSC_InCompleteRegistration__c) {
            incompletedRegUser = true;
        }
        return incompletedRegUser;
    }
}