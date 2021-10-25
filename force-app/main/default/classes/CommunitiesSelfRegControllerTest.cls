/**
 * An apex page controller that supports self registration of users in communities that allow self registration
 */
@IsTest public with sharing class CommunitiesSelfRegControllerTest {
    @TestSetup
    static void makeData() {
        Id accBusinessRecordTypeId = Account.sObjectType.getDescribe()
        .getRecordTypeInfosByDeveloperName()
        .get('LSC_Business')
        .getRecordTypeId();
        //Business Account
        Account businessAccount = new Account(
            name = 'MyServiceNSW Registration',
            Type = 'Commercial',
            recordTypeId = accBusinessRecordTypeId
        );
        insert businessAccount;
    }
    
    @IsTest(SeeAllData=false) 
    public static void testCommunitiesSelfRegController() {
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        controller.firstName = 'Bob';
        controller.lastName = 'Jones';
        controller.email = 'bob@jones.com';
        controller.password = '8yhMsHDN&ituQgO$WO';
        controller.confirmPassword = '8yhMsHDN&ituQgO$WO';
        controller.communityNickname = 'bob-jones-testing';
    
        PageReference pageRef = controller.registerUser();
    }

    @IsTest(SeeAllData=false) 
    public static void testInvalidPassword() {
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        controller.firstName = 'Bob';
        controller.lastName = 'Jones';
        controller.email = 'bob@jones.com';
        controller.password = '8yhMsHDN&ituQgO$WO';
        controller.confirmPassword = 'not the same';
        controller.communityNickname = 'bob-jones-testing';
        PageReference pageRef = controller.registerUser();
        System.assert(pageRef == null, 'The returned page reference should be null');
    }

    @IsTest(SeeAllData=false) 
    public static void testNullPassword() {
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        controller.firstName = 'Bob';
        controller.lastName = 'Jones';
        controller.email = 'bob@jones.com';
        controller.communityNickname = 'bob-jones-testing';
    
        PageReference pageRef = controller.registerUser();
        System.assert(pageRef == null, 'The returned page reference should be null');
    }
}