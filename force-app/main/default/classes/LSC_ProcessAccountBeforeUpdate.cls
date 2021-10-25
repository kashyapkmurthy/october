public class LSC_ProcessAccountBeforeUpdate {

    
    public static void processAccountBeforeUpdate (Map<Id, SObject> newItems, Map<Id, SObject> oldItems){

        Map<String, LSC_AccountAttribute__mdt> accountAttributeMdt = LSC_AccountAttribute__mdt.getAll();
        for(Id key : newItems.keySet())
        {
            Account oldAccount = (Account)oldItems.get(key);
            Account newAccount = (Account)newItems.get(key);
            
            if (oldAccount.LSC_SyncedWithSAP__c == true && 
                newAccount.LSC_SyncedWithSAP__c == true){
                for (String str : accountAttributeMdt.keyset()) 
                { 
                    try 
                    { 
                        String accountFieldName = accountAttributeMdt.get(str).LSC_AccountFieldName__c;
                        if(newAccount.get(accountFieldName) != oldAccount.get(accountFieldName))
                        { 
                            newAccount.LSC_SyncedWithSAP__c = false;
                            break;
                        } 
                    } 
                    catch (Exception e) 
                    { 
                        System.Debug('Error: ' + e); 
                    } 
                }
            }
        }
    }
}