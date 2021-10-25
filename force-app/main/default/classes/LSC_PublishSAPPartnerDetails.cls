public class LSC_PublishSAPPartnerDetails {
    public LSC_PublishSAPPartnerDetails() {

    }    

    @future
    public static void publishSAPPartnerDetails (List<Id> accountIdList){

        String query ='';
        String sobjectApiName = 'Account';
        String strFields = LSC_QueryUtils.getFieldNameForAnObject('Account');
        String additionalRelationalFields = ', Account.RecordType.Name';
        
       
        query = 'select ' + strFields + additionalRelationalFields+ ' from ' + SobjectApiName + ' where Id IN:accountIdList';
       
        List <Account> accList = Database.query(query);

        System.debug('Account value--->'+accList);

        for (Account acc : accList){
            System.debug('Account Name--->'+acc.Name);    
        }

        List<LSC_NewRegistration__e> events = new List<LSC_NewRegistration__e>();
        for(Account acc : accList) {
            LSC_NewRegistration__e peReg = new LSC_NewRegistration__e();
            peReg.LSC_AccountId__c = acc.Id;
            peReg.LSC_AccountName__c = acc.name;

            peReg.LSC_Abn__c = acc.LSC_ABN__c;
            peReg.LSC_AbnEffectiveFrom__c = acc.LSC_ABNEffectiveFrom__c;
            peReg.LSC_ABNEffectiveTo__c = acc.LSC_ABNEffectiveTo__c;
            peReg.LSC_ACN__c = acc.LSC_ACN__c;
            peReg.LSC_AccountType__c = acc.RecordType.Name;
            peReg.LSC_AccountSubType__c = acc.Type;
            peReg.LSC_FirstName__c = acc.LSC_IndividualFirstName__c;
            peReg.LSC_LastName__c = acc.LSC_IndividualLastName__c;
            //peReg.LSC_BusinessName__c = acc.LSC_BusinessName__c;
            peReg.LSC_EntityTypeName__c = acc.LSC_EntityTypeName__c;
            peReg.LSC_CharityTypeName__c = acc.LSC_CharityTypeName__c;
            peReg.LSC_Schemes__c = acc.LSC_Schemes__c;
            peReg.LSC_Email__c = acc.LSC_Email__c;
            peReg.LSC_Phone__c = acc.Phone;
            peReg.LSC_Mobile__c = acc.LSC_Mobile__c;
            peReg.LSC_ShippingStreet__c = acc.ShippingStreet;
            peReg.LSC_ShippingCity__c = acc.ShippingCity;
            peReg.LSC_ShippingState__c = acc.ShippingState;
            peReg.LSC_ShippingPostCode__c = acc.ShippingPostalCode;
            peReg.LSC_ShippingCountry__c = acc.ShippingCountry;
            peReg.LSC_BillingStreet__c = acc.BillingStreet;
            peReg.LSC_BillingCity__c = acc.BillingCity;
            peReg.LSC_BillingState__c = acc.BillingState;
            peReg.LSC_BillingPostCode__c = acc.BillingPostalCode;

            peReg.LSC_BillingCountry__c = acc.BillingCountry;
            peReg.LSC_Status__c = acc.LSC_AccountStatus__c;


            events.add(peReg);            
        }

        if(events.size() > 0) {
            EventBus.publish(events);
        }

    }
}