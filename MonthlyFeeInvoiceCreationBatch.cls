/**
 * @description       : This batch will run every 3rd day of the month to generate fee invoices for MPM
 * @author            : Arman Alam
 * @last modified on  : 12-08-2022
 * @last modified by  : Arman Alam
 * @Test Class        : MonthlyFeeInvoiceCreationBatchTest
**/
global class MonthlyFeeInvoiceCreationBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable, Database.AllowsCallouts{

    private static DateTime previousMonthEndDate = Date.today().toStartOfMonth().addDays(-1);
    private static DateTime previousMonthStartDate = Date.today().toStartOfMonth().addDays(-1).toStartOfMonth();
    private static String previousMonth = previousMonthStartDate.format('MMMM');
    private static Integer previousYear = previousMonthStartDate.year();
    private static Map<Id,List<Plan__c>> plans = new Map<Id,List<Plan__c>>();
    private static Map<Id,Service_Agreement__c> serviceAgreementMap = new Map<Id,Service_Agreement__c>(); //TFR-217
    private static Map<Id,Integer> invoicesWithCount = new Map<Id,Integer>();
    private static String mpmProviderId = Fee_Invoice_Rule_Configuration__mdt.getInstance('FeeConfig1').MyPlanManagerRecordId__c;
    private static String ndspProviderId = Fee_Invoice_Rule_Configuration__mdt.getInstance('FeeConfig1').NDSPRecordId__c;
    Integer count = 0;

    /**
    * @description
    * @author Arman Alam | 10-14-2022
    * @param sc
    **/
    global void execute(SchedulableContext sc) {
        if (evaluateCriteria() || Test.isRunningTest()) {
            MonthlyFeeInvoiceCreationBatch b = new MonthlyFeeInvoiceCreationBatch();
            AsyncApexFramework.submitBatch(b,100,99);
            AsyncApexFramework.flush();
        }
    }

    /**
    * @description
    * @author Arman Alam | 11-08-2022
    * @return Boolean
    **/
    public static Boolean evaluateCriteria(){
        Integer nthDay = Label.MonthlyFeeInvoiceBatchSchedule.isNumeric() ?
            			 Integer.valueOf(Label.MonthlyFeeInvoiceBatchSchedule) : 0;
        if (nthDay != 0) {
            Integer workingDayCount = 0;
            for (Integer i = 1; i <= Date.today().day(); i++){
                Date toRunOnDate = Date.newInstance(System.Today().year(), System.Today().month(), i);
                if (toRunOnDate.toStartofWeek().daysBetween(toRunOnDate) > 0 && 
                    toRunOnDate.toStartofWeek().daysBetween(toRunOnDate) <= 5) {
                    workingDayCount++;
                }
            }
            if (workingDayCount == nthDay) {
                return true;
            }
            return false;
            /*Date toRunOnDate = Date.newInstance(System.Today().year(), System.Today().month(), nthDay);
            Integer weekOfDate = toRunOnDate.toStartofWeek().daysBetween(toRunOnDate);
            toRunOnDate = toRunOnDate.addDays(
                weekOfDate == 6 ? 2 : (weekOfDate == 0 ? 1 : 0)
            );
            return toRunOnDate.isSameDay(System.today());*/
        }
        return true;
    }

    /**
    * @description
    * @author Arman Alam | 10-10-2022
    * @param bc
    * @return Database.QueryLocator
    **/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> recordTypes = InvoiceRuleConstant.MONTHLY_FEE_ACCOUNT_RECORDTYPES;
        String query =  'SELECT Id, Name, PlanManager__c, CreatedDate FROM Account WHERE RecordTypeId IN :recordTypes ';
        query += Test.isRunningTest() ? '' : System.Label.MonthlyFeeInvoiceBatchQuery;
        System.debug(query);
        return Database.getQueryLocator(query);
    }

    /**
    * @description
    * @author Arman Alam | 10-10-2022
    * @param bc
    * @param accounts
    **/
    global void execute(Database.BatchableContext bc, List<Account> accounts){
        count += accounts.size();
        createMonthlyFeeInvoice(bc, accounts);
    }

    /**
    * @description
    * @author Arman Alam | 10-13-2022
    * @param bc
    * @param accounts
    **/
    public static void createMonthlyFeeInvoice(Database.BatchableContext bc, List<Account> accounts){
        try {
            Map<Id,Invoice__c> clientsInvoices = new Map<Id,Invoice__c>();
            getServiceAgreement(accounts);
            for (Account client: accounts) {
                //TFR-246
                if (serviceAgreementMap.containsKey(client.Id) && serviceAgreementMap.get(client.Id)
                    .Commencement_Date__c > previousMonthEndDate.date()) {
                    continue;
                }
                clientsInvoices.put(client.Id, 
                                    getInvoiceForClient(
                                                        client, 
                                                        client.PlanManager__c == NDSPConstants.MPM
                                                        ? mpmProviderId 
                                                        : client.PlanManager__c == NDSPConstants.NDSP
                                                        ? ndspProviderId : null
                                                        )
                                    );
            }
            Database.insert(clientsInvoices.values());
            //get all the plans and prepare map.
            getPlan(clientsInvoices.keySet());
            List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
            for (Id cl: clientsInvoices.keySet()) {
                if (!plans.containsKey(cl)) {
                    //If no plan record found then create a single Invoice Line Item.
                    lineItems.add(getSingleLineItem(clientsInvoices.get(cl),cl));
                    invoicesWithCount.put(clientsInvoices.get(cl).Id,1);
                } else {
                    lineItems.addAll(getLineItems(clientsInvoices.get(cl),cl));
                }
            }
            Database.insert(lineItems);

            initiateRuleEngine();
        } catch(Exception e) {
            LogService.insertLog(new List<EventLog__e>{ LogService.logSaveResult('MonthlyFeeInvoiceCreationBatch',
                        'Execute', e.getMessage(), (bc != null ? String.valueOf(bc.getJobId()) : '') , '', '')});
        }
    }

    /**
    * @description
    * @author Arman Alam | 10-13-2022
    * @param client
    * @param provider
    * @return Invoice__c
    **/
    public static Invoice__c getInvoiceForClient(Account client, String providerId){
        return new Invoice__c(
            Reference_Number__c = previousMonth.toUpperCase() + previousYear + 'MONTHLYFEE',
            Document_Type__c = 'Fee',
            Invoice_Origin__c = 'Auto-Generated',
            FeeType__c = 'Monthly',
            Client__c = client.Id,
            Provider__c = providerId,
            //TFR-217
            Support_Start_Date__c = (serviceAgreementMap.containsKey(client.Id) &&
                                    serviceAgreementMap.get(client.Id).Commencement_Date__c > previousMonthStartDate.date() ?
                                    serviceAgreementMap.get(client.Id).Commencement_Date__c : previousMonthStartDate.date()),
            Support_End_Date__c = previousMonthEndDate.date(),
            Status__c = 'New'
        );
    }

    /**
    * @description
    * @author Arman Alam | 10-11-2022
    * @param invoice
    * @param clientId
    * @return List<Invoice_Line_Item__c>
    **/
    @testVisible
    public static List<Invoice_Line_Item__c> getLineItems(Invoice__c invoice, Id clientId){
        //Identify service dates
        List<Date> serviceDates = new List<Date>();
        List<Invoice_Line_Item__c> invoiceLineList = new List<Invoice_Line_Item__c>();
        serviceDates.add(invoice.Support_Start_Date__c);
        if (plans.get(clientId).size() > 0) {
            if (plans.get(clientId)[0].Plan_Start_Date__c > invoice.Support_Start_Date__c) {
                serviceDates.add(plans.get(clientId)[0].Plan_Start_Date__c - 1);
            }
            for (Plan__c plan: plans.get(clientId)) {
                if (plan.Plan_Start_Date__c > invoice.Support_Start_Date__c &&
                    plan.Plan_Start_Date__c <= invoice.Support_End_Date__c) {
                    //system.debug('adding plan start date');
                    serviceDates.add(plan.Plan_Start_Date__c);
                }
                if (plan.Plan_End_Date__c >= invoice.Support_Start_Date__c &&
                    plan.Plan_End_Date__c < invoice.Support_End_Date__c) {
                    //system.debug('adding plan end date');
                    serviceDates.add(plan.Plan_End_Date__c);
                }
            }
        }
        serviceDates.add(invoice.Support_End_Date__c);
        //System.debug('serviceDates -->'+ serviceDates);
        for (Integer i = 0; i+1 < serviceDates.size(); i++) {
            //TFR-217 Added below service date logic considering commencement date
            Date serviceDateFrom;
            if (serviceAgreementMap.containsKey(clientId) &&
                serviceAgreementMap.get(clientId).Commencement_Date__c > serviceDates[i]) {
                if (serviceAgreementMap.get(clientId).Commencement_Date__c > serviceDates[i+1]) {
                    continue; //start date and end date both are less than commencement date.
                }
                serviceDateFrom = serviceAgreementMap.get(clientId).Commencement_Date__c;
            } else {
                serviceDateFrom = serviceDates[i];
            }
            invoiceLineList.add(new Invoice_Line_Item__c(
                Service_Date_From__c = serviceDateFrom,
                Service_Date_To__c = serviceDates[++i],
                Invoice__c = invoice.Id,
                Status__c = 'New'
            ));
        }
        System.debug('invoice line list '+invoiceLineList);
        invoicesWithCount.put(invoice.Id,invoiceLineList.size());
        return invoiceLineList;
    }

    /**
    * @description
    * @author Arman Alam | 10-11-2022
    * @param invoice
    * @param clientId
    * @return Invoice_Line_Item__c
    **/
    @testVisible
    private static Invoice_Line_Item__c getSingleLineItem(Invoice__c invoice, Id clientId){
        return new Invoice_Line_Item__c(
            //TFR-217
            Service_Date_From__c = (serviceAgreementMap.containsKey(clientId) &&
                                    serviceAgreementMap.get(clientId).Commencement_Date__c > invoice.Support_Start_Date__c ?
                                    serviceAgreementMap.get(clientId).Commencement_Date__c : invoice.Support_Start_Date__c),
            Service_Date_To__c = invoice.Support_End_Date__c,
            Invoice__c = invoice.Id,
            Status__c = 'New'
        );
    }

    /**
    * @description
    * @author Arman Alam | 10-13-2022
    **/
    public static void initiateRuleEngine(){
        List<Fee_Invoice_Event__e> eventsList = new List<Fee_Invoice_Event__e>();
        Map<String, Integer> eventsMap = new Map<String, Integer>();
        for (String inv: invoicesWithCount.keySet()) {
            if (eventsMap.keySet().size() == 2) {
                eventsList.add(TTPUtil.getFeeInvoiceTriggerEvent(JSON.serialize(eventsMap)));
                eventsMap = new Map<String, Integer>();
            }
            eventsMap.put(inv, invoicesWithCount.get(inv));
        }
        if (eventsMap.keySet().size() > 0) {
            eventsList.add(TTPUtil.getFeeInvoiceTriggerEvent(JSON.serialize(eventsMap)));
        }
        if (eventsList.size() > 0) {
            TTPUtil.publishInvoiceTriggerEvent(eventsList);
        }
    }


    /**
    * @description
    * @author Arman Alam | 10-13-2022
    * @param clients
    **/
    @testVisible
    private static void getPlan(Set<Id> clients){
        for (Plan__c pl: [SELECT Id, PRODA_Plan_Id__c, Plan_Start_Date__c, Plan_End_Date__c,
                        Client_Name__c FROM Plan__c WHERE ((Plan_Start_Date__c <=
                        :previousMonthStartDate.date() AND Plan_End_Date__c >=
                        :previousMonthEndDate.date()) OR (Plan_Start_Date__c <=
                        :previousMonthEndDate.date() AND Plan_End_Date__c >=
                        :previousMonthEndDate.date()) OR (Plan_Start_Date__c <=
                        :previousMonthStartDate.date() AND Plan_End_Date__c <=
                        :previousMonthEndDate.date() AND Plan_End_Date__c >=
                        :previousMonthStartDate.date()) OR (Plan_Start_Date__c >=
                        :previousMonthStartDate.date() AND Plan_End_Date__c <=
                        :previousMonthEndDate.date())) AND  Client_Name__c In :clients
                        ORDER BY Plan_Start_Date__c ASC]) {
            if (plans.containsKey(pl.Client_Name__c)) {
                plans.get(pl.Client_Name__c).add(pl);
            } else {
                plans.put(pl.Client_Name__c,new List<Plan__c>{pl});
            }
        }
    }

    /**
    * @description TFR-217
    * @author Arman Alam | 11-14-2022
    * @param clients
    **/
    private static void getServiceAgreement(List<Account> clients){
        for (Service_Agreement__c agreement: [SELECT Id, NDIS_Participant__c, Commencement_Date__c, Status__c
                                              FROM Service_Agreement__c WHERE NDIS_Participant__c IN :clients
                                              and Status__c = 'Current' AND Commencement_Date__c != null
                                              ORDER BY Commencement_date__c DESC]) {
                                                  serviceAgreementMap.put(agreement.NDIS_Participant__c, agreement);
                                              }
    }

    /**
    * @description
    * @author Arman Alam | 10-10-2022
    * @param bc
    **/
    global void finish(Database.BatchableContext bc) {
        //Attributes used for Email
        List <String> listOfUserEmail = new List <String>();
        List <String> ccAddress = new List <String>();
        //Get Batch Job information
        AsyncApexJob asyncJob = [SELECT Id, Status, ExtendedStatus, NumberOfErrors, JobItemsProcessed,
                                    TotalJobItems, CreatedDate, CompletedDate
                                    FROM AsyncApexJob WHERE Id =:bc.getJobId()];
        //Get user who scheduled the batch
        List <User> listOfUsers = [SELECT Id,Email,Name FROM User WHERE id = :UserInfo.getUserId() LIMIT 1];
        //Get list of users to send email
        for (User u: listOfUsers){
            listOfUserEmail.add(u.Email);
        }
        //Get MPM outlook email
        ccAddress.add(System.label.mpm_outlook_email);
        //Send Email to the user who Scheduled the batch and to mpm outlook mailbox
        Utils.sendBatchConfirmationEmailBody(asyncJob, listOfUserEmail, ccAddress, count,'Monthly Fee Invoice Creation Batch',
                                        'creates monthly fee invoices');
    }
}