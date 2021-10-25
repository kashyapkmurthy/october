public inherited sharing class LSC_GlobalConstants {
    
     //CUSTOM METADATA NAME FOR URL
     public static String LSC_ACCOUNT_STATUS_ACTIVE = 'Active';

    //ACCOUNT SOBJECT RECORD TYPE NAMES
    public static String LSC_ACCOUNT_RECORDTYPENAME_INDIVIDUAL  = 'Individual';
    public static String LSC_ACCOUNT_RECORDTYPENAME_BUSINESS    = 'Business';

    //CUSTOM METADATA NAME FOR URL
    public static String LSC_CUSTOM_METADATA_NAME_ADDRESS_DETAIL = 'Address_Detail';
    public static String LSC_CUSTOM_METADATA_NAME_ADDRESS_LIST = 'Address_List';
    public static String LSC_CUSTOM_METADATA_NAME_ABN = 'ABN';
    public static String LSC_CUSTOM_METADATA_NAME_OWNER_BUILDER = 'Owner_Builder';
    public static String LSC_CUSTOM_METADATA_NAME_CPP_PAYMENT_REFERENCE = 'CPP_PAYMENT_REFERENCE';    	
    public static String LSC_CUSTOM_METADATA_NAME_CPP_PAYMENT_REDIRECT_URL = 'CPP_Redirect_URL';	
    public static String LSC_CUSTOM_METADATA_NAME_CPP_CALLING_SYSTEM_URL = 'Calling_System_URL';

    //TRANSACTION SOBJECT RECORD TYPE NAMES
    public static String LSC_TRANSACTION_RECORDTYPENAME_INSTALMENT = 'Instalment';
    public static String LSC_TRANSACTION_RECORDTYPENAME_INTEREST   = 'Interest';
    public static String LSC_TRANSACTION_RECORDTYPENAME_REFUND     = 'Refund';
    public static String LSC_TRANSACTION_RECORDTYPENAME_TOPUP      = 'Top Up';
    public static String LSC_TRANSACTION_RECORDTYPENAME_LEVY       = 'Levy';

    //CASE SOBJECT RECORD TYPE NAMES
    public static String LSC_CASE_RECORDTYPENAME_REFUND            = 'Refund';
    public static String LSC_CASE_RECORDTYPENAME_EXEMPTION         = 'Exemption';
    public static String LSC_CASE_RECORDTYPENAME_INSTALMENT        = 'Instalment';
    public static String LSC_CASE_RECORDTYPENAME_INQUIRY           = 'Inquiry';

    //TRANSACTION LINE ITEM SOBJECT RECORD TYPE NAMES
    public static String LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_COMMISSION = 'Commission';
    public static String LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_PAYMENT    = 'Payment';
    public static String LSC_TRANSACTION_LINE_ITEM_RECORDTYPENAME_WRITE_OFF  = 'Write Off';    


    public static String LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PROCESSING = 'Processing';
    public static String LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_CANCELLED  = 'Cancelled';
    public static String LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_FAILED     = 'Failed';      
    public static String LSC_TRANSACTION_LINE_ITEM_PAYMENT_METHOD_STATUS_PAID       = 'Paid';   


    //TRANSACTION SOBJECT STATUS TYPE
    public static String LSC_TRANSACTION_STATUS_PENDING   = 'Pending';
    public static String LSC_TRANSACTION_STATUS_PAID      = 'Paid';
    public static String LSC_TRANSACTION_STATUS_NEW       = 'New';
    public static String LSC_TRANSACTION_STATUS_CANCELLED = 'Cancelled';
    public static String LSC_TRANSACTION_STATUS_FAILED    = 'Failed';
    //TRANSACTION SOBJECT PAYMENTMETHOD
    public static String LSC_TRANSACTION_PAYMENTMETHOD_AGENCY   = 'Agency';


     //TRANSACTION SOBJECT LSC_TRANSACTION_TYPE
    public static String LSC_TRANSACTION_TYPE_CREATE  = 'CREATE';
    public static String LSC_TRANSACTION_TYPE_UPDATE  = 'UPDATE';

    //TRANSACTION SOBJECT LSC_TRANSACTION_TYPE
    public static String LSC_LEVY_RECORDTYPE_BCI  = 'BCI';
    public static String LSC_LEVY_RECORDTYPE_CCI  = 'CCI';

    //Levy SOBJECT LSC_TRANSACTION_TYPE
    public static String LSC_LEVY_APPLICATION_STATUS  = 'Ready to be paid'; 

    //CASE SOBJECT STATUS
    public static String LSC_CASE_STATUS_CLOSED_APPROVED  = 'Closed Approved';
    public static String LSC_CASE_STATUS_CLOSED_REJECTED  = 'Closed Rejected';

    public static String LSC_CASE_REFUND_PAYMENT_METHOD  = 'EFT';
    public static String LSC_CASE_REFUND_CARD_PAYMENT_METHOD  = 'Card';
    public static String LSC_CASE_REFUND_PAYPAL_PAYMENT_METHOD  = 'PayPal';

    public static String LSC_CASE_STAGE_INSTALMENT_TYPE = 'Staged instalments';

    public static Decimal LSC_COUNCIL_COMMISSION_FEE = 19.8;
    
    

}