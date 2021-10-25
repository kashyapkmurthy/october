public inherited sharing class LSC_ProcessAccountAfterUpdate {
    public LSC_ProcessAccountAfterUpdate() {

    }

    public static void processAccountAfterUpdate (Map<Id, SObject> newItems){
        Map<Id, Account> accountMap;
        accountMap = (Map<Id, Account>) newItems;
        List<Id> accountIdList = new List<Id>();
        accountIdList.addAll(accountMap.keySet());
        LSC_PublishSAPPartnerDetails.publishSAPPartnerDetails(accountIdList);
    }

}