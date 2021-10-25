public with sharing class LSC_Utility {
  public static final String PROD_USERNAME_SUFFIX = '.lsc';
  public static final String SNSW_INCOMPLETED_SUFFIX = '.incompleted';
  public static final String EN_DASH = '–';
  public static final String EM_DASH = '—';
  public static final String HYPEN = '-';
  private static Organization org;
  public static AuraHandledException createAuraException(String message) {
    AuraHandledException auraException = new AuraHandledException(message);
    auraException.setMessage(message);
    return auraException;
  }

  public static Boolean isSandbox() {
    if (org == null) {
      org = [SELECT Id, isSandbox FROM Organization LIMIT 1];
    }
    return (org.IsSandbox == true || Test.isRunningTest());
  }

  public static String constructUsername(String email) {
    String userName = email + PROD_USERNAME_SUFFIX;
    if (isSandbox()) {
      String sandboxName = System.Label.Sandbox_Name;
      userName += '.' + sandboxName;
    }
    return userName;
  }

  public static String replaceDashWithHypen(String inputString) {
    inputString = inputString.replace(EN_DASH, HYPEN);
    inputString = inputString.replace(EM_DASH, HYPEN);
    return inputString;
  }

  public static Boolean checkIfLoginPortalViaServiceCloud() {
    Boolean isLoginPortalViaServiceCloud = false;
    if (!Test.isRunningTest()) {
      Map<String, String> currentSession = Auth.SessionManagement.getCurrentSession();
      isLoginPortalViaServiceCloud =
        currentSession.get('LoginType') == 'Unknown' &&
        currentSession.get('SourceIp') == '::' &&
        currentSession.get('UserType') == 'Standard';
    }
    return isLoginPortalViaServiceCloud;
  }
  
  public static Boolean isEmailAddressInWhiteList(String email) {
    Boolean isAllowed = false;
    List<Registration_Email_Whitelist__mdt> emailDomainList = [
      SELECT Id, Email_Domain__c
      FROM Registration_Email_Whitelist__mdt
    ];
    for (Registration_Email_Whitelist__mdt emailDomain : emailDomainList) {
      if (email.endsWithIgnoreCase(emailDomain.Email_Domain__c)) {
        isAllowed = true;
      }
    }
    return isAllowed;
  }

  public static String generateRandomString(Integer len) {
    final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    String randStr = '';
    while (randStr.length() < len) {
      Integer idx = Math.mod(
        Math.abs(Crypto.getRandomInteger()),
        chars.length()
      );
      randStr += chars.substring(idx, idx + 1);
    }
    return randStr;
  }
}