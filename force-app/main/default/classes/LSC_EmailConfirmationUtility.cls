public without sharing class LSC_EmailConfirmationUtility {
    public LSC_EmailConfirmationUtility() {

    }

    public static String generateEmailId() {
        Integer getLength = 30;
        String charString = 'nopqrstuvwABCDPQRSTUVWXYZ0123456789abcdefghijkEFGHIJKLMNOlmxyz';
        String randomString = '';
        while(randomString.length() < getLength) {
            Integer changeInt = Math.mod(Math.abs(Crypto.getRandomInteger()), charString.length());
            randomString += charString.substring(changeInt , changeInt +1);
        }
        return randomString; 
    }

    public static Messaging.SingleEmailMessage prepareEmail(String cId) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTargetObjectId(cId); 
        message.setSenderDisplayName('Long Service Corporation'); 
        message.setUseSignature(false); 
        message.setBccSender(false); 
        message.setSaveAsActivity(false); 
        List<EmailTemplate> emailTemplate = [SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName = 'LSC_EmailVerification'];
        if(emailTemplate == null || emailTemplate.size() == 0) {
            return null;
        }
        message.setTemplateID(emailTemplate[0].Id); 
        message.setWhatId(cId); 
        return message;       
    }
}