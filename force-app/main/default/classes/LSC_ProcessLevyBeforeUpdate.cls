public class LSC_ProcessLevyBeforeUpdate{

    public static void processLevyBeforeUpdate (Map<Id, SObject> newItems, Map<Id, SObject> oldItems){

        Boolean isSalesforceUSer = !LSC_QueryUtils.isMuleSoftUserProfile();

        //Defect 375 - remove levy mdt to allow all levy fields to be updated by internal users
        //Map<String, Levy_Attributes__mdt> levyAttributeMdt = Levy_Attributes__mdt.getAll();
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.LSC_Levy__c.fields.getMap();
        //List<String> fieldList = new List<String>();
        //for (String str : levyAttributeMdt.keyset()) {
        //    fieldList.add(levyAttributeMdt.get(str).Levy_Field_Name__c);
        //}

        for(Id key : newItems.keySet()){       
            LSC_Levy__c oldLevy = (LSC_Levy__c)oldItems.get(key);
            LSC_Levy__c newLevy = (LSC_Levy__c)newItems.get(key);
            
            // Panaya-466 replace dash with hypern
            if (!String.isBlank(newLevy.LSC_ApplicationNumber__c)) {
                newLevy.LSC_ApplicationNumber__c = LSC_Utility.replaceDashWithHypen(newLevy.LSC_ApplicationNumber__c);
            }
            
            if(newLevy.LSC_CostOfWorks__c != null  && (oldLevy.LSC_CostOfWorks__c != newLevy.LSC_CostOfWorks__c) && UserInfo.getUserType() == 'Standard'){
                if(newLevy.LSC_CostOfWorks__c >= 25000){
                    newLevy.LSC_LevyPayable__c = Math.floor(newLevy.LSC_CostOfWorks__c * 0.0035);
                }else{
                    newLevy.LSC_LevyPayable__c = 0;
                }
            }
            
            //Defect 374 - Handle empty amount in LSC_LevyPayable__c
            if (newLevy.LSC_LevyPayable__c == null) {
                newLevy.LSC_LevyPayable__c = 0;
            }

            Decimal totalLevyPayable =  newLevy.LSC_LevyPayable__c - newLevy.LSC_ExemptionAmount__c + newLevy.LSC_TotalInterestAmount__c ;

            if (((newLevy.LSC_ApplicationStatus__c != 'Cancelled')  && ((newLevy.LSC_TotalPaidCredit__c >= totalLevyPayable - 50) ))){ 
                newLevy.LSC_ApplicationStatus__c = 'Paid';  
            }

            if (((oldLevy.LSC_ApplicationStatus__c == 'Paid' || newLevy.LSC_ApplicationStatus__c == 'Paid')  && (newLevy.LSC_TotalPaidCredit__c < totalLevyPayable))){
                newLevy.LSC_ApplicationStatus__c = 'Ready to be paid';  
            }

            if ((oldLevy.LSC_ApplicationStatus__c == 'Awaiting Exemption Decision') && (newLevy.LSC_ApplicationStatus__c != 'Awaiting Exemption Decision' && newLevy.LSC_ApplicationStatus__c != 'Ready to be paid' && newLevy.LSC_ApplicationStatus__c != 'Cancelled')){
                newLevy.addError('Awaiting Exemption Decision can only be changed to Ready to be paid or Cancelled');    
            }

            if ((oldLevy.LSC_ApplicationStatus__c == 'Awaiting Instalments Decision') && (newLevy.LSC_ApplicationStatus__c != 'Awaiting Instalments Decision' && newLevy.LSC_ApplicationStatus__c != 'Ready to be paid' && newLevy.LSC_ApplicationStatus__c != 'Cancelled')){
                newLevy.addError('Awaiting Instalments Decision can only be changed to Ready to be paid or Cancelled');    
            }

            if ((oldLevy.LSC_ApplicationStatus__c == 'Ready to be paid') && (newLevy.LSC_ApplicationStatus__c != 'Ready to be paid' && newLevy.LSC_ApplicationStatus__c != 'Paid' && newLevy.LSC_ApplicationStatus__c != 'Cancelled')){
                newLevy.addError('Ready to be paid can only be changed to Paid or Cancelled');    
            }

            if ((oldLevy.LSC_ApplicationStatus__c == 'Ready to be paid') && ((newLevy.LSC_ApplicationStatus__c != 'Ready to be paid' && newLevy.LSC_ApplicationStatus__c == 'Paid') && (newLevy.LSC_TotalPaidCredit__c < totalLevyPayable - 50))){
                newLevy.addError('Levy can be marked as Paid only if it was fully paid');    
            }

            if (oldLevy.LSC_ApplicationStatus__c == 'Paid' && isSalesforceUSer){
                /* Defect 375 - remove levy mdt to allow all levy fields to be updated by internal users
                if (getRecordTypeNameById('LSC_Levy__c', newLevy.RecordTypeId) == 'BCI'){                   
                    Schema.sObjectField[] sObj = getChangedFields(newLevy.id, fieldMap.values());
                    for (Schema.sObjectField s : sObj){
                        String str = String.valueOf(s);
                        System.debug('str--->'+str);
                        if (!fieldList.contains(str)){
                            newLevy.addError(new MyException('You can only update the Status of Levy Record to Ready to be paid based on the conditions'));    
                        }
                    }
                }
                */
                
                if (newLevy.LSC_ApplicationStatus__c == 'Awaiting Instalments Decision' || 
                    newLevy.LSC_ApplicationStatus__c == 'Awaiting Exemption Decision'   ||
                    newLevy.LSC_ApplicationStatus__c == 'Cancelled'){
                        newLevy.addError('Record with Paid status can’t be edited');
                }
            }

            if ((oldLevy.LSC_ApplicationStatus__c == 'Cancelled') && isSalesforceUSer){
                newLevy.addError('Record with Cancelled status can’t be edited');  
            }

        }
    } 

    public class MyException extends Exception {}    
    
}