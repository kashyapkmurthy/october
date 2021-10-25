public with sharing class LSC_ForgotPassword {

    @AuraEnabled
    public static Boolean forgotPassword(String username) {
        // the front end passing email to backend and need to add suffix before checking
        if(username != null) {
            username = username.toLowerCase();
            username = LSC_Utility.constructUsername(username);
            if(Site.isValidUsername(username)) {
                return Site.forgotPassword(username, 'LSC_ForgotPassword');
            }      
            else {
                return false;
            }       
        }
        else {
            return false;
        }
    }
}