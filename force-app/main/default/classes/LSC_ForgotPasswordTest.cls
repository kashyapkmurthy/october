@isTest
public class LSC_ForgotPasswordTest {

    static testMethod void forgotPasswordTest() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'LSC Customer Community Login User'].Id;
        User u = LSC_TestDataFactory.createUser(profileId, 'aaa');
        Test.startTest();
            LSC_ForgotPassword.forgotPassword('testuser@test.aaa');
            LSC_ForgotPassword.forgotPassword(null);
        Test.stopTest();        
    }
}