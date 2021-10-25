public abstract class LSC_TestDataFactory {
    

    //Account creation
    public static List<Account> createAccounts( Integer numberOfAccounts) {
        List<Account> accounts = new List<Account>();
        Integer abn = 1012345678;
        Integer acn = 101234567;

        for ( Integer i = 0 ; i < numberOfAccounts ; i++ ) {
            abn = abn + i;
            acn = acn + i;
            Account account = new Account(  LSC_IndividualFirstName__c = 'firstname' + i, 
                                            LSC_IndividualLastName__c = 'lastname'+i,
                                            LSC_Email__c = 'donotemail'+i+'@email.com',
                                            LSC_ABNEffectiveFrom__c = Date.today(),
                                            LSC_ABNEffectiveTo__c = Date.today().addYears(5),
                                            Type = 'Individual', 
                                            Name = 'firstname' + i + 'lastname'+i,
                                            LSC_BusinessName__c = 'BusinessName'+ i, 
                                            LSC_EntityTypeName__c = 'EntityTypeName'+ i,
                                            LSC_CharityTypeName__c = 'CharityTypeName'+ i,
                                            LSC_Schemes__c = 'BCI',
                                            Phone = '0412345678',
                                            LSC_Mobile__c = '0412345678',
                                            ShippingStreet = '2 Rawson Street',
                                            ShippingCity = 'Sydney',
                                            ShippingState = 'NSW',
                                            ShippingPostalCode = '2000',
                                            ShippingCountry = 'AU',
                                            BillingStreet = '2 Rawson Street',
                                            BillingCity = 'Sydney',
                                            BillingState = 'NSW',
                                            BillingPostalCode = '2000',
                                            BillingCountry = 'AU',                                            
                                            LSC_AccountStatus__c = 'Active',
                                            LSC_ABN__c = '1'+ String.valueof(abn),
                                            LSC_ACN__c =  String.valueof(acn)
                                        );
            accounts.add( account);
        }

        return accounts;

    }

    public static List<Contact> createContact( Integer numberOfContacts, Account account) {
        List<Contact> contacts = new List<Contact>();

        for ( Integer i = 0 ; i < numberOfContacts ; i++ ) {
            Contact contact = new Contact(  firstname = 'firstname' + i, 
                                            lastname = 'lastname'+i,
                                            Email = 'donotemail'+i+'@email.com',
                                            Phone = '0412345678',
                                            HomePhone = '0412345678',
                                            AccountId = account.Id
                                        );
            contacts.add( contact);
        }
        return contacts;
    }

    
    public static List<LSC_Levy__c> createLevy( Integer numberOfLevies, Account account, Contact contact) {
        List<LSC_Levy__c> levies = new List<LSC_Levy__c>();

        for ( Integer i = 0 ; i < numberOfLevies ; i++ ) {
            LSC_Levy__c levy = new LSC_Levy__c(  
                                            LSC_AccountId__c = account.Id,
                                            LSC_ApplicantId__c = contact.Id,
                                            LSC_ApplicationNumber__c = 'Application-DA-' + i, 
                                            LSC_ApplicationStatus__c = 'Paid',
                                            LSC_ApplicationType__c = 'Development Application',
                                            LSC_AuthorisedRepresentativeId__c =  contact.Id,
                                            LSC_ConstructionStartDate__c = System.Today(),
                                            LSC_ConstructionEndDate__c = date.newinstance(System.Now().addYears(1).year(), System.Now().addYears(1).month(), System.Now().addYears(1).day()),
                                            LSC_CostOfWorks__c = 123456789,
                                            LSC_LevyPayable__c = 0.035 * 123456789,
                                            RecordtypeId = Schema.SObjectType.LSC_Levy__c.getRecordTypeInfosByName().get(LSC_GlobalConstants.LSC_LEVY_RECORDTYPE_BCI).getRecordTypeId()
                                        );
            levies.add( levy);
        }

        return levies;
    }


    public static List<LSC_Transaction__c> createTransaction( Integer numberOfTransactions, LSC_Levy__c levy, Id RecordTypeId) {
        List<LSC_Transaction__c> transactions = new List<LSC_Transaction__c>();

        for ( Integer i = 0 ; i < numberOfTransactions ; i++ ) {
            LSC_Transaction__c tran = new LSC_Transaction__c(  
                                            LSC_Amount__c = 123456789,
                                            LSC_DueDate__c = System.Today(),
                                            LSC_GST__c = 123456, 
                                            LSC_LevyId__c = levy.Id,
                                            /*LSC_PaidAmount__c = 123456789,*/
                                            LSC_PaymentDate__c = System.Today(),
                                            LSC_PaymentMethod__c = 'Card',
                                            LSC_PaymentReference__c = 'PR000001',                                            
                                            LSC_ReceiptDate__c =System.Today(),
                                            LSC_Status__c = 'Paid',
                                            LSC_Stage__c = 'In Progress',                                            
                                            RecordTypeId = RecordTypeId
                                        );
            transactions.add( tran);
        }

        return transactions;
    }

    public static List<LSC_TransactionLineItem__c> createTransactionLineItems(
        Integer numberOfTransactions,
        Account acc,
        LSC_Transaction__c tran,
        Id recordTypeId,
        Double amount,
        String status
      ) {
        List<LSC_TransactionLineItem__c> transactionLineItems = new List<LSC_TransactionLineItem__c>();
    
        for (Integer i = 0; i < numberOfTransactions; i++) {
          LSC_TransactionLineItem__c tliRec = new LSC_TransactionLineItem__c(
            LSC_TransactionId__c = tran.Id,
            LSC_AccountId__c = acc.Id,
            recordTypeId = recordTypeId,
            LSC_Amount__c = amount,
            LSC_Status__c = status,
            LSC_ReceiptDate__c = System.Date.today(),
            LSC_PaymentMethod__c = 'Agency',
            LSC_PaymentDate__c = System.Date.today()
          );
          transactionLineItems.add(tliRec);
        }
    
        return transactionLineItems;
    }

    public static List<Case> createCase(Integer numberOfTransactions, Account a, Contact c, LSC_Levy__c l, Id RecordTypeId) {
        List<Case> cases = new List<Case>();

        for(Integer i = 0; i < numberOfTransactions; i++) {
            Case cc = new Case(  
                Subject = 'Test case',
                Description = 'ABC',
                AccountId = a.Id,
                ContactId = c.Id,
                Status = 'New',                                           
                RecordTypeId = RecordTypeId
            );
            if(l != null) {
                cc.LSC_LevyId__c = l.Id;
            }
            cases.add(cc);
        }
        return cases;
    }

    public static User createUser(Id profileId, String key) {
        User u = new User(  
            FirstName = 'Test',  
            LastName = key,  
            email = 'testuser@test.' + key,  
            Username = 'testuser@test.' + key,  
            CommunityNickname = 'test' + key,
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = 'testu',
            TimeZoneSidKey = 'Australia/Sydney',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profileId
        );      
        return u;      
    }

    public static ContentVersion createContent() {
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Koala',
            PathOnClient = 'Koala.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        return contentVersion;        
    }



    public static String createMigrationId() {
        String hashString = String.valueOf(Datetime.now().formatGMT('yyyy-MM-dd HH:mm:ss.SSS'));
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(hashString));
        String hexDigest = EncodingUtil.convertToHex(hash);
        return hexDigest;
    }
    public static List<LSC_LegacyLevy__c> createLegacyLevys(
        Integer numberOfLegacyLevies,
        Account acc,
        Boolean isInsert
    ) {
        List<LSC_LegacyLevy__c> legacyLevies = new List<LSC_LegacyLevy__c>();

        for (Integer i = 0; i < numberOfLegacyLevies; i++) {
            LSC_LegacyLevy__c legacyLevy = new LSC_LegacyLevy__c();
            legacyLevy.LSC_NewLevyAccount__c = acc.Id;
            legacyLevy.LSC_ApplicationNumber__c = 'Application-DA-' + i;
            legacyLevy.LSC_ApplicationType__c = 'Development Application';
            legacyLevy.LSC_ConstructionStartDate__c = System.Today().addYears(-2);
            legacyLevy.LSC_ConstructionEndDate__c = System.Today().addYears(-1);
            legacyLevy.LSC_CostOfWorks__c = 200000;
            legacyLevy.LSC_LevyPayable__c = 0.035 * 200000;
            legacyLevy.LSC_CorrectedTotalPaidAmount__c = legacyLevy.LSC_LevyPayable__c - 50;
            legacyLevy.LSC_CorrectedWriteOffAmount__c = 50;
            legacyLevy.LSC_CorrectedRefundAmount__c = 100;
            legacyLevy.LSC_DataMigrationId__c = createMigrationId();
            legacyLevies.add(legacyLevy);
        }

        if (isInsert) {
            insert legacyLevies;
        }
        return legacyLevies;
    }

    public static LSC_LegacyTransaction__c createLegacyTransactions(
        LSC_LegacyLevy__c legacyLevy,
        String type,
        Boolean isInsert
    ) {
        LSC_LegacyTransaction__c legacyTransaction = new LSC_LegacyTransaction__c();
        if (type == 'Payment') {
            legacyTransaction.LSC_Amount__c = legacyLevy.LSC_LevyPayable__c + 100;
        } else if (type == 'Refund') {
            legacyTransaction.LSC_Amount__c = 100;
        } else if (type == 'WriteOff') {
            legacyTransaction.LSC_Amount__c = 50;
        }
        legacyTransaction.LSC_PaidAmount__c = legacyLevy.LSC_LevyPayable__c - 50;
        legacyTransaction.LSC_Type__c = type;
        legacyTransaction.LSC_LegacyLevyId__c = legacyLevy.Id;
        legacyTransaction.LSC_DataMigrationId__c = createMigrationId();

        if (isInsert) {
            insert legacyTransaction;
        }
        return legacyTransaction;
    }
}