public class LSC_QueryUtils {

    /**
     * Get all fields for a particular Sobject
     */    
    public static String getFieldNameForAnObject (String sobjectApiName){

        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(sobjectApiName).getDescribe().fields.getMap();
       
        String strFields = '';
        
        for(String fieldName : fieldMap.keyset() )
        {
            if(strFields == null || strFields == '')
            {
                strFields = fieldName;
            }else{
                strFields = strFields + ' , ' + fieldName;
            }
        }

        return strFields;

    }

    /**
     * Method to Bank and Branch Name based on BSB
     */
    @AuraEnabled(cacheable=true)
    public static String getbankAndBranch (String bsbCode){
        String bankAndBranch = null;
        String inputString = 'X'+bsbCode;
        LSC_BSBDirectory__mdt bsbDirectory = LSC_BSBDirectory__mdt.getInstance(inputString);
        System.debug('bsbDirectory111--->'+bsbDirectory);
        if (bsbDirectory != null) {
            System.debug('bsbDirectory2222--->'+bsbDirectory);
            bankAndBranch = bsbDirectory.LSC_Bank__c + ' - '+bsbDirectory.LSC_Branch__c;
            return bankAndBranch;
        }
        return bankAndBranch;
    } 
    
    /**
     * Method to determine if the current user is Mulesoft Admin.
     */
    public static Boolean isMuleSoftUserProfile (){
        Map<String, Editable_Profile__mdt> editableProfileMdt = Editable_Profile__mdt.getAll();
        List<String> editableProfile = new List<String>();
        for (String key : editableProfileMdt.keySet()){
            editableProfile.add(editableProfileMdt.get(key).MasterLabel);
        }
        Boolean isMuleSoftUserProfile = false;
        Id profileId=userinfo.getProfileId();
        String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
        if (editableProfile.contains(profileName)){
            isMuleSoftUserProfile = true;    
        }
        return isMuleSoftUserProfile;
    }

    
}