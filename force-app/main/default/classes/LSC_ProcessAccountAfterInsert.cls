public class LSC_ProcessAccountAfterInsert {

    public static void processAccountAfterInsert (Map<Id, SObject> newItems){
        Map<Id, Account> accountMap;
        accountMap = (Map<Id, Account>) newItems;
        List<Id> accountIdList = new List<Id>();
        accountIdList.addAll(accountMap.keySet());
        LSC_PublishSAPPartnerDetails.publishSAPPartnerDetails(accountIdList);
    }
}