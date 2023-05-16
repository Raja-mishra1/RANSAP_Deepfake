/**
* Class Name: NDIA_DataSyncService
* Description: NDIA Data Sync Service Class to keep all the SOQL Queries.
* Created By: Cloudwerx
* Created Date: 02/08/2021
*/

public class NDIA_DataSyncService {

    public static final Integer PLAN_BATCH_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('Plan_API').Batch_Size__c);
    public static final Integer PLAN_BATCH_SCOPE_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('Plan_API').Batch_Scope_Size__c);
   
    public static final Integer BUDGET_BATCH_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('Budget_API').Batch_Size__c);
    public static final Integer BUDGET_BATCH_SCOPE_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('Budget_API').Batch_Scope_Size__c);
    
    public static final Integer SERVICE_BOOKING_BATCH_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('ServiceBooking_API').Batch_Size__c);
    public static final Integer SERVICE_BOOKING_BATCH_SCOPE_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('ServiceBooking_API').Batch_Scope_Size__c);
    
    public static final Integer SERVICE_BOOKING_LINE_ITEM_BATCH_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('ServiceBookingLineItem_API').Batch_Size__c);
    public static final Integer SERVICE_BOOKING_LINE_ITEM_BATCH_SCOPE_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('ServiceBookingLineItem_API').Batch_Scope_Size__c);

    public static final Integer PR_CREATION_SCOPE_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('PaymentRequestCreation_API').Batch_Scope_Size__c);
    public static final Integer PR_CREATION_BATCH_SIZE = Integer.valueOf(NDIS_API_Configuration__mdt.getInstance('PaymentRequestCreation_API').Batch_Size__c);

    //==================PLAN SYNC QUERIES 
    /**
     * @description Method to create Query for One time NDIA Plan Sync
     * @ticket      TTP-609
     * @return      List of Accounts
     */
    public static String getOneTimePlanSyncQuery () {
        
        return 'SELECT Id, Last_Plan_Sync__c, LastName, NDIS__c, PersonBirthdate, Sync_Error_Plan__c, PlanManager__c'+
            + ' FROM Account' +
            + ' WHERE PersonBirthdate != NULL AND LastName != NULL AND'+
            + ' NDIS__c != NULL AND Last_Plan_Sync__c = NULL AND Status__c = \'Active\'' + 
            + ' LIMIT ' +PLAN_BATCH_SIZE;
    }

    /**
     * @description Method to get account records for NDIA On-demand Plan Sync 
     * @ticket      TTP-727
     * @return      List of Accounts
     */
    public static List<Account> getOnDemandPlanSyncQuery (List<String> accountIds) {
        return [ 
            SELECT Id, Last_Plan_Sync__c, LastName, NDIS__c, PersonBirthdate, Sync_Error_Plan__c, PlanManager__c
            FROM Account
            WHERE PersonBirthdate != NULL AND LastName != NULL AND NDIS__c != NULL AND Id IN :accountIds
        ];
    }

    /**
     * @description Method to create a Query for NDIA Daily Plan Sync
     * @ticket      TTP-728
     * @return      List of Accounts
     */
    public static String getScheduledPlanSyncQuery () {
        
        DateTime today = System.now();
        return 'SELECT Id, Last_Plan_Sync__c, LastName, NDIS__c, PersonBirthdate, Sync_Error_Plan__c, PlanManager__c'+
            + ' FROM Account' +
            + ' WHERE PersonBirthdate != NULL AND LastName != NULL AND'
            + ' NDIS__c != NULL AND Status__c = \'Active\' AND Last_Plan_Sync__c != today '+ 
            + ' ORDER BY Last_Plan_Sync__c ASC LIMIT ' + PLAN_BATCH_SIZE;
    }


    //==================BUDGET SYNC QUERIES

    /**
     * @description Method to create Query for One time NDIA Budget Sync
     * @ticket      TTP-609
     * @return      List of Plans     
     */
    public static String getOneTimeBudgetSyncQuery () {
        
        return 'SELECT Id, Client_Name__c, PRODA_Plan_Id__c, Client_Name__r.LastName,' +
            + ' Client_Name__r.PersonBirthdate, Client_Name__r.NDIS__c, LastBudgetSync__c,' +
            + ' Sync_Error_Budget__c, PlanAccessLevel__c ,Plan_Start_Date__c,Plan_End_Date__c,' 
            + ' Client_Name__r.Status__c, PlanManager__c'+
            + ' FROM Plan__c' +
            + ' WHERE PRODA_Plan_Id__c != NULL AND Client_Name__r.NDIS__c != NULL' +
            + ' AND Client_Name__r.Status__c = \'Active\' AND (LastBudgetSync__c = NULL OR PlanAccessLevel__c = NULL)' + 
            + ' AND Active__c = TRUE AND PersonBirthdate__c != NULL AND LastName__c != NULL' + //TTP-2123
            + ' ORDER BY Client_Name__c,CreatedDate LIMIT '+BUDGET_BATCH_SIZE;
    }

   /**
     * @description Method to create Query for Ondemand NDIA Plan Sync
     * @ticket      TTP-868
     * @return      List of Plans
     */
    public static List<Plan__c> getOnDemandBudgetSyncQuery (List<Id> planIds) {
        return [
            SELECT Id, Client_Name__c, PRODA_Plan_Id__c, Client_Name__r.LastName, Sync_Error_Budget__c, PlanManager__c,
                    Client_Name__r.PersonBirthdate, Client_Name__r.NDIS__c, LastBudgetSync__c, PlanAccessLevel__c ,Plan_Start_Date__c,Plan_End_Date__c 
            FROM Plan__c 
            WHERE PRODA_Plan_Id__c != NULL AND Client_Name__r.NDIS__c != NULL AND Active__c = TRUE
            AND PersonBirthdate__c != NULL AND LastName__c != NULL AND Id IN : planIds
        ]; //TTP-2123
    }

    /**
     * @description Method to create Query for Schedulable NDIA budget sync 
     * @ticket      TTP-869
     * @return      List of Payment Request
     */
    public static String getPaymentRequests () {
        return 'SELECT Id, LastModifiedDate, CreatedDate,' +        
        + ' Plan__r.Client_Name__c, Plan__r.PRODA_Plan_Id__c,' +
        + ' Plan__r.Client_Name__r.NDIS__c, Plan__r.LastBudgetSync__c, Plan__r.Client_Name__r.Status__c, PlanManager__c' +
        + ' FROM Payment_Request__c' +
        + ' WHERE Plan__r.Client_Name__c != NULL AND Plan__r.PRODA_Plan_Id__c != NULL AND Plan__r.Client_Name__r.NDIS__c != NULL' +
        + ' AND (Plan__r.Client_Name__r.Status__c = \'Active\' OR Plan__r.Client_Name__r.Status__c = \'Inactive\')' +
        + ' AND Plan__r.Is_Active__c = true AND Plan__r.LastBudgetSync__c != NULL' + 
        + ' ORDER BY LastModifiedDate DESC Limit 50000'; //ACEM-2 Added limit in query
    }

    /**
     * @description Method to create Query for Schedulable NDIA budget sync 
     * @ticket      TTP-869
     * @return      List of Payment Request with related payments
     */
    public static String getScheduledBudgetSyncQuery (Set<Id> filteredPlanSet) {
        
        return 'SELECT Id, Client_Name__c, PRODA_Plan_Id__c, Client_Name__r.LastName,' +
            + ' Client_Name__r.PersonBirthdate, Client_Name__r.NDIS__c, LastBudgetSync__c,' +
            + ' Sync_Error_Budget__c, PlanAccessLevel__c ,Plan_Start_Date__c,Plan_End_Date__c, PlanManager__c,' +
            + ' (SELECT Id, CreatedDate, Plan__c  FROM Payments__r)' +
            + ' FROM Plan__c' +
            + ' WHERE PRODA_Plan_Id__c != NULL AND Client_Name__r.NDIS__c != NULL' +
            + ' AND Active__c = TRUE AND PersonBirthdate__c != NULL AND LastName__c != NULL' + //TTP-2123
            + ' AND (Client_Name__r.Status__c = \'Active\' OR Client_Name__r.Status__c = \'Inactive\')' +
            + ' AND ((LastBudgetSync__c != NULL AND Id IN :filteredPlanSet) OR LastBudgetSync__c = NULL)' + 
            + ' ORDER BY LastBudgetSync__c NULLS FIRST, LastModifiedDate DESC LIMIT '+BUDGET_BATCH_SIZE;
    }


    //==================SERVICE BOOKING QUERIES 

   /**
    * Description   Method to create Query for One time Service Booking Sync
    * @ticket       TTP-779
    * @return       List of Accounts with related plans
    */
    public static String getOneTimeSBSyncQuery () {
        String query = '';
        query = 'SELECT Id, LastName, NDIS__c, Last_Plan_Sync__c, Last_Service_Booking_Sync__c,'+
                'Sync_Error_Service_Booking__c, PlanManager__c ,' +
                '(SELECT Id, Proda_Plan_Id__c , PlanManager__c FROM Plans__r ORDER BY CreatedDate DESC) ' + 
                'FROM Account WHERE PlanManager__c != NULL';
        
        if (String.isNotBlank(Label.OneTimeSBQuery)) {
            query +=  ' AND ' + Label.OneTimeSBQuery;
            if (Label.OneTimeSBQuery.contains('LIMIT') && SERVICE_BOOKING_BATCH_SIZE != null) {
                query += ' ' + String.valueOf(SERVICE_BOOKING_BATCH_SIZE);
            }
        }
        return query;
    }

    /**
    * Description   Method to create Query accounts for ON demand Service booking Sync
    * @ticket       TTP-777
    * @return       List of Accounts with related plans
    */
    public static List<Account> getOnDemandSBSyncQuery(List<String> accountIds){
        return [
            SELECT Id, LastName, NDIS__c, Last_Plan_Sync__c, Last_Service_Booking_Sync__c, 
                    Sync_Error_Service_Booking__c, PlanManager__c,
                (SELECT Id, Proda_Plan_Id__c, PlanManager__c FROM Plans__r
                 ORDER BY CreatedDate DESC) 
            FROM Account 
            WHERE NDIS__c != NULL AND PlanManager__c != NULL AND Id IN :accountIds
        ];
    }

    /**
    * Description : Method to create Query accounts for ON demand Service booking Sync
    * @ticket:    TTP-980
    */
    public static List<ServiceBooking__c> getOnDemandSBLineItemSyncQuery(List<Id> serviceBookingIds){
        return [
            SELECT Id, Name,LastServiceBookingLineItemsSync__c, PlanManager__c,
                Plan__c, Plan__r.PlanManager__c, Account__c, 
                Account__r.NDIS__c,ExternalId__c, Account__r.PlanManager__c
            FROM ServiceBooking__c
            WHERE   Account__c != NULL 
            AND Account__r.NDIS__c != NULL
            AND PlanManager__c != NULL
            AND Id IN :serviceBookingIds
        ];
    }
    
    //==================SERVICE BOOKING LINE ITEM QUERIES 
    /**
     * @description  [TTP-975] Method to create Query for One time Service Booking Line Item 
     * @author       Swapnil Bhapkar  
     * @param        -    
     * @return       List of Servicebookings 
    **/
    public static String getOneTimeSBLineItemSyncQuery () {
        String query = '';
        query = 'SELECT Id, Name, LastServiceBookingLineItemsSync__c, Plan__c, PlanManager__c,'+
            + ' Plan__r.PlanManager__c, Account__c, Account__r.NDIS__c,'+
            + ' Account__r.PlanManager__c, ExternalId__c'+
            + ' FROM ServiceBooking__c WHERE PlanManager__c != NULL';
            
        if (String.isNotBlank(Label.OneTimeSBLineItemQuery)) {
            query += ' AND ' + Label.OneTimeSBLineItemQuery;
            if (Label.OneTimeSBLineItemQuery.contains('LIMIT') && SERVICE_BOOKING_LINE_ITEM_BATCH_SIZE != null) {
                query += ' ' + String.valueOf(SERVICE_BOOKING_LINE_ITEM_BATCH_SIZE);
            }
        }
        return query;
    }

    

    //==================PAYMENT REQUEST QUERIES 
    /**
     * @description      [TTP-1404] [TTP-1405] Method to create Query for Payment Requests
     * @author           Sonali Takke
     * @param            invoiceId : Invoice Id from the orchestrator
     * @return           String : Payment Request Query String
    **/

    public static String getPendingPaymentRequests (String invoiceId) {

        String query = 'SELECT Id,Status__c,Reference_Number__c,PRODA_Service_Booking_Id__c,PRODA_Support_Item_Number__c,PRODA_Exemption_Reason__c,'+
            +'  PRODA_Support_Category_Code__c,Invoice__c,Client_NDIS__c,Amount__c,Quantity__c,PRODA_Tax_Code__c,ABN_Not_Available__c,'+
            +'  PRODA_Claim_Type__c,Service_Date_From__c,Service_Date_To__c,Unit_Of_Measure__c,PRODA_Claim_Number__c, Provider_ABN__c,'+
            +'  PRODA_Claim_Reason__c,Client__r.NDIS__c, PlanManager__c '
            +' FROM Payment_Request__c'+
            +' WHERE Status__c = \'Pending\'';
        if (String.isNotBlank(invoiceId)) query += ' AND Invoice__c = \''+invoiceId+'\'';
        return query;
    }
    //==================OTHER QUERIES 
   
    /*
     * @description Method to return Async Apex Jobs which are currently being processed of a 
     *              certain class. 
     * @ticket      TTP-609, TTP-975,TTP-869, TTP-728,TTP-779
     * @return      List of AsyncApexJob
     */
    public static List<AsyncApexJob> getApexJobs(String className) {
        return [
            SELECT Id, Status, ApexClassID 
            FROM AsyncApexJob 
            WHERE ApexClass.Name = :className AND Status = 'Processing'
        ];
    }

  /**
    * @description  Method to get SupportCategory__c records
    * @ticket       TTP-609, TTP-975  
    * @return       List of Support Categories
    */
    public static List<SupportCategory__c> getSupportCategories() { 
        return [
            SELECT Id, SupportCategoryCode__c ,Name , SupportCategoryName__c 
            FROM SupportCategory__c 
            WHERE SupportCategoryCode__c != null
        ];
    }

  /**
    * @description  Method to get SupportItems by supportItemNumbers
    * @ticket       TTP-609, TTP-975  
    * @return       List of Support Items
    */
    public static List<SupportItem__c> getSupportItemsBySupportItemNumber (Set<String> supportItemNumberSet) {
        return [
            SELECT EndDate__c,StartDate__c,SupportItemNumber__c ,SupportItemName__c 
            FROM SupportItem__c 
            WHERE SupportItemNumber__c IN :supportItemNumberSet
        ];
    }

    /**
    * @description  Method to get plans by matching Clients
    * @ticket       TTP-609 
    * @return       List of Plans
    */
    public static List<Plan__c> getPlansbyClient(Set <String> accountIdSet) {
        return [
            SELECT Id, NDIS__c, Client_Name__c, PRODA_Plan_Id__c, Plan_Start_Date__c, PlanManager__c
            FROM Plan__c 
            WHERE Client_Name__c IN :accountIdSet AND 
                (PRODA_Plan_Id__c != null OR Plan_Start_Date__c != NULL)
        ];
    }

        /**
    * Description : Method to get plans by matching Proda Plan Id
    * @ticket :TTP-1105
    */
    public static List<Plan__c> getPlansbyProdaId(Set <String> planIdSet) {
        return [
            SELECT Id,Name,Proda_Plan_Id__c, PlanManager__c, Client_Name__c from Plan__c WHERE Proda_Plan_Id__c IN:planIdSet
        ];
    }

    /**
    * Description : Method to get Payment Request by Invoice Line Item
    * @ticket :TTP-1414
    * @Params : invoiceLineItemIds - Set of Invoice Line Item IDs
    */

    public static List<Payment_Request__c> getPRForCancelledLineItem (List<String> invoiceLineItemIds) {
        return [ 
            SELECT Id,Name,PRODA_Claim_Number__c,Invoice_Line_Item__c,Invoice_Line_Item__r.Invoice__c,Invoice_Line_Item__r.Invoice__r.Client__c,
            Invoice_Line_Item__r.Invoice__r.Client__r.NDIS__c, PlanManager__c 
            FROM Payment_Request__c 
            WHERE PRODA_Claim_Number__c !=null AND PRODA_Claim_Status__c IN ('4','41') AND Status__c != 'Cancelled' AND Invoice_Line_Item__r.Invoice__r.Client__r.NDIS__c != null
                AND Invoice_Line_Item__c IN : invoiceLineItemIds limit 100
        ];
    }

    /**
    * @description  Method to get plans for Salesforce_Claiming_Experience__c as true
    * @author       Aman
    * @ticket       TTP-2200 
    * @return       List of Plans
    */
    public static String getOneTimeSlicedBudgetSyncQuery () { 
        return 'SELECT Id, Client_Name__c, PRODA_Plan_Id__c, Client_Name__r.LastName,' 
            + ' Client_Name__r.PersonBirthdate, Client_Name__r.NDIS__c, LastBudgetSync__c,' 
            + ' Sync_Error_Budget__c, PlanAccessLevel__c ,Plan_Start_Date__c,Plan_End_Date__c,' 
            + ' Client_Name__r.Status__c, PlanManager__c'
            + ' FROM Plan__c'
            + ' WHERE PRODA_Plan_Id__c != NULL AND Active__c = TRUE' 
            + ' AND PersonBirthdate__c != NULL AND LastName__c != NULL AND NDIS__c != NULL'
            + ' AND Client_Name__r.Salesforce_Claiming_Experience__c = TRUE'
            + ' AND Client_Name__r.Status__c = \'Active\' AND (LastBudgetSync__c = NULL OR PlanAccessLevel__c = NULL)' 
            + ' ORDER BY Client_Name__c, CreatedDate LIMIT ' + BUDGET_BATCH_SIZE;
    }
}