/**
 * @description     [ACEM-10][ACEM-11] Queuable Class Invoked via Invoice trigger to send   email Notification To Provider on Invoice
 * @company         Cloudwerx
 * @date            30/08/2022
 * @testClass       InvoiceCancelNotificationQueuableTest
 **/
public with sharing class InvoiceCancelNotificationQueuable implements Queueable {
  private List<Invoice__c> rejectedInvoiceList;
  private OrgWideEmailAddress noreplyEmailAddress;
  private OrgWideEmailAddress mpmNoreplyEmailAddress;
  private OrgWideEmailAddress ndspNoreplyEmailAddress;

  public InvoiceCancelNotificationQueuable(List<Invoice__c> rejectedInvoiceList) {
    this.rejectedInvoiceList = rejectedInvoiceList;
    this.mpmNoreplyEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :Label.Client_exit_wizard_email];
    this.ndspNoreplyEmailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :Label.NDSP_No_Reply_Email];
  }

  /**
   * @ description      [ACEM-10][ACEM-11]Method to process the invoices received from *                   trigger and send SMS Notification to providers
   * @ author           Prithviraj Deshmukh
   * @ param            context  : QueueableContext
   **/
  public void execute(QueueableContext context) {
    
      Map<Id, Id> invoiceProviderMap = new Map<Id, Id>(); //ACEM-10
      Map<Id, Id> providerPrimaryContactMap = new Map<Id, Id>(); //ACEM-10
      Map<Id, Id> invoiceClientMap = new Map<Id, Id>(); //ACEM-11
      Map<Id, List<String>> clientEmailMap = new Map<Id, List<String>>(); //ACEM-11
      List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
      List<Task> taskList = new List<Task>();

      //Getting org limits for single email
      Map<String, System.OrgLimit> limitsMap = OrgLimits.getMap();
      System.OrgLimit singleEmailLimit = limitsMap.get('SingleEmail');
      //checking pending org limits for single emails
      Integer pendingEmailLimit = singleEmailLimit.getLimit() - singleEmailLimit.getValue();

      //Query Email Templates
      EmailTemplate providerRejectionEmailTemplate = [
        SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body
        FROM EmailTemplate
        WHERE name = 'Email to Provider - Invoice rejected by Client'
        LIMIT 1
      ];
      EmailTemplate clientRejectionEmailTemplate = [
        SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body
        FROM EmailTemplate
        WHERE name = 'Email to Client - Invoice rejected by Client'
        LIMIT 1
      ];

      EmailTemplate NdspProviderRejectionEmailTemplate = [
        SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body
        FROM EmailTemplate
        WHERE name = 'NDSP Email to Provider - Invoice rejected by Client'
        LIMIT 1
      ];
      EmailTemplate NdspClientRejectionEmailTemplate = [
        SELECT Id, Subject, Description, HtmlValue, DeveloperName, Body
        FROM EmailTemplate
        WHERE name = 'NDSP Email to Client - Invoice rejected by Client'
        LIMIT 1
      ];

      //Query MPM IT User Id for tasks
      //for sandboxes
      Id taskOwnerId = [SELECT Id, Email FROM User WHERE Name = 'MPM IT' LIMIT 1].Id;
      //for production
      // Id taskOwnerId =  [SELECT Id,Email from User WHERE Email = :System.Label.MPM_IT_USER_EMAIL_ID LIMIT 1].Id;

      //ACEM-11 Create email collection to notify clients of rejection of provider invoice
      for (Invoice__c inv : this.rejectedInvoiceList) {
        if (inv.Client__c != null) {
          invoiceClientMap.put(inv.Id, inv.Client__c); // add client Ids
        }
        if (inv.Provider__c != null) {
          invoiceProviderMap.put(inv.Id, inv.Provider__c);
        }
      }

      //Query on ACR for Primary Contacts on Client/Provider
      for (AccountContactRelation accConRel : [
        SELECT AccountId, Contact.Email, Contact.Name
        FROM AccountContactRelation
        WHERE
          (AccountId IN :invoiceProviderMap.values()
          OR AccountId IN :invoiceClientMap.values())
          AND Contact.Email != NULL
          AND Primary_Contact__c = TRUE
      ]) {
        List<String> contactEmailList = new List<String>();
        if (invoiceClientMap.values().contains(accConRel.AccountId)) {
          // Getting client primary contact emails for Toaddress in rejection emails
          if (!clientEmailMap.containsKey(accConRel.AccountId)) {
            contactEmailList.add(accConRel.Contact.Email);
            clientEmailMap.put(accConRel.AccountId, contactEmailList);
          } else {
            contactEmailList = clientEmailMap.get(accConRel.AccountId);
            contactEmailList.add(accConRel.Contact.Email);
            clientEmailMap.put(accConRel.AccountId, contactEmailList);
          }
        }
        if (invoiceProviderMap.values().contains(accConRel.AccountId)) {
          //Getting provider primary contact to create task - for the whoid
          providerPrimaryContactMap.put(accConRel.AccountId, accConRel.ContactId);
          //might be tricky in case of multiple primary contacts
        }
      }

      //Iterate on rejected invoice to - create task/send emails
      for (Invoice__c rejectedInvoice : this.rejectedInvoiceList) {
        String subject = '';
        String htmlBody = '';
        List<String> providerEmailIds = new List<String>();
        Id providerPrimaryContactId = providerPrimaryContactMap.get(rejectedInvoice.Provider__c);

        if (pendingEmailLimit < 0 || Test.IsRunningTest()) {
          String description =
            'SFDC {Limit Name} encountered ' +
            'Usage Value:  ' +
            singleEmailLimit.getValue() +
            'Maximum Limit: ' +
            singleEmailLimit.getLimit();

          //ACEM-10 - Create Task on Provider
          taskList.add(
            createTask(
              'Email not sent - single email limit exceeded.',
              description,
              taskOwnerId,
              rejectedInvoice.Id,
              providerPrimaryContactId
            )
          );

          //ACEM-11 - Create Task on Client
          taskList.add(
            createTask(
              'Email not sent - single email limit exceeded.',
              description,
              taskOwnerId,
              rejectedInvoice.Id,
              rejectedInvoice.Client__r?.PersonContactId
            )
          );
        }

        //ACEM-10
        //Notification to Provider for rejected invoice
        if (String.isBlank(rejectedInvoice.Case__r.SuppliedEmail) && providerPrimaryContactId == null) {
          //IN CASE EMAIL IS Not PRESENT

          //ADD TASK FOR EMPTY EMAIL
          taskList.add(
            createTask(
              'Email not sent - email address not available.',
              'Provider email address not available.',
              taskOwnerId,
              rejectedInvoice.Id,
              providerPrimaryContactId
            )
          );
        } else {
          //SEND EMAIL SCENARIO
          providerEmailIds.add(rejectedInvoice.Case__r.SuppliedEmail);
          //replace merge field in subject
          if(rejectedInvoice.PlanManager__c == 'NDSP') {
            subject = replaceMergeFields(NdspProviderRejectionEmailTemplate.Subject, rejectedInvoice);
            htmlBody = replaceMergeFields(NdspProviderRejectionEmailTemplate.HtmlValue, rejectedInvoice);
            this.noreplyEmailAddress = this.ndspNoreplyEmailAddress;
          }
          else {
            subject = replaceMergeFields(providerRejectionEmailTemplate.Subject, rejectedInvoice);
            htmlBody = replaceMergeFields(providerRejectionEmailTemplate.HtmlValue, rejectedInvoice);
            this.noreplyEmailAddress = this.mpmNoreplyEmailAddress;
          }

          mails.add(
            createEmail(
              subject,
              htmlBody,
              noreplyEmailAddress,
              providerEmailIds
            )
          );
          pendingEmailLimit--;
          //ADD TASK OF SENT EMAIL
          taskList.add(
            createTask(
              subject,
              providerRejectionEmailTemplate.Description,
              taskOwnerId,
              rejectedInvoice.Id,
              providerPrimaryContactId
            )
          );
        }

        //ACEM-11
        //Notification to Client for rejected invoice
        if (clientEmailMap.isEmpty() || rejectedInvoice.Client__c == null) {
          //IN CASE EMAIL IS Not PRESENT

          //ADD TASK FOR EMPTY EMAIL
          taskList.add(
            createTask(
              'Email not sent - email address not available.',
              'Provider email address not available.',
              taskOwnerId,
              rejectedInvoice.Id,
              rejectedInvoice.Client__r?.PersonContactId
            )
          );
        } else {
          //SEND EMAIL SCENARIO
          if(rejectedInvoice.PlanManager__c == 'NDSP') {
            subject = replaceMergeFields(NdspClientRejectionEmailTemplate.Subject, rejectedInvoice);
            htmlBody = replaceMergeFields(NdspClientRejectionEmailTemplate.HtmlValue, rejectedInvoice);
            this.noreplyEmailAddress = this.ndspNoreplyEmailAddress;
          }
          else {
            subject = replaceMergeFields(clientRejectionEmailTemplate.Subject, rejectedInvoice);
            htmlBody = replaceMergeFields(clientRejectionEmailTemplate.HtmlValue, rejectedInvoice);
            this.noreplyEmailAddress = this.mpmNoreplyEmailAddress;
          }          

          // providerEmailIds.add(rejectedInvoice.Case__r.SuppliedEmail);
          //create client email list
          mails.add(
            createEmail(
              subject,
              htmlBody,
              noreplyEmailAddress,
              clientEmailMap.get(rejectedInvoice.Client__c)
            )
          );
          pendingEmailLimit--;

          //ADD TASK OF SENT EMAIL
          taskList.add(
            createTask(
              subject,
              clientRejectionEmailTemplate.Description,
              taskOwnerId,
              rejectedInvoice.Id,
              rejectedInvoice.Client__r?.PersonContactId
            )
          );
        }
      }
    try {
      Database.DMLOptions options = new Database.DMLOptions();
      options.OptAllOrNone = true;

      if (!taskList.isEmpty()) {
        //options.EmailHeader.triggerUserEmail = true;
        List<Database.SaveResult> results = Database.insert(taskList, options);
      }

      //Sned emails
      if (!mails.isEmpty() && pendingEmailLimit > 0) {
        Messaging.sendEmail(mails);
      }
    } catch (Exception e) {
      EventLog__e event = LogService.logSaveResult('InvoiceCancelNotificationQueuable',
        'execute', 'Error: ' + e, '', '', '' );
      LogService.insertLog(new List<EventLog__e>{ event });
    }
  }

  /**
   * @ description      [ACEM-10][ACEM-11]Method to create the email we need to send
   * @ author           Prithviraj
   * @ return           Task Record
   * @ param            rejectedInvoiceRecord - invoice record which is rejected
   *                    emailTemplate - id of email template to be used
   *                    noreplyEmailAddress - no reply email address
   *                    toEmailAddress - list of email addresses to send email
   **/
  public static Messaging.SingleEmailMessage createEmail(
    String subject,
    String htmlBody,
    OrgWideEmailAddress noreplyEmailAddress,
    List<String> toEmailAddress
  ) {
    Messaging.SingleEmailMessage rejectionEmail = new Messaging.SingleEmailMessage();

    if (Test.IsRunningTest()) {
      noreplyEmailAddress = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
      String plainText = '<html><body> Test  </body></html>';
      rejectionEmail.setSubject(plainText);
      rejectionEmail.setHtmlBody(plainText);
    } else {
      rejectionEmail.setSubject(subject);
      rejectionEmail.setHtmlBody(htmlBody);
    }

    rejectionEmail.setOrgWideEmailAddressId(noreplyEmailAddress.Id);
    rejectionEmail.setToAddresses(toEmailAddress);
    rejectionEmail.setBccSender(false);
    rejectionEmail.setSaveAsActivity(false);
    rejectionEmail.saveAsActivity = false;
    return rejectionEmail;
  }

  /**
   * @ description    [ACEM-10][ACEM-11]Method to create tasks
   * @ author         Prithviraj
   * @ return         Task Record
   * @ param          subject - Subject of Task
   *                  description - Description of Task
   *                  taskOwnerId - usually MPM IT owner
   *                  whatId - object id
   *                  whoId - id of object on which task is to be created
   **/
  public static Task createTask(String subject, String description, Id taskOwnerId, Id whatId, Id whoId) {
    Task taskObj = TTPUtil.createTask(subject, 'Completed', description, taskOwnerId, whatId, whoId);
    taskObj.Priority = 'Normal';
    taskObj.ActivityDate = Date.today();
    return taskObj;
  }

  /**
   * @ description     [ACEM-10][ACEM-11]Method to replace merge fields in text body
   * @ author          Prithviraj
   * @ param           textBody            : SMS Body from Metadata
   *                   rejectedInvoice    : Invoice which was rejected by client
   * @ return          String - text Body
   **/
  public static String replaceMergeFields(String textBody, Invoice__c rejectedInvoice) {
    textBody = textBody.replace('Invoice__c.Reference_Number__c', rejectedInvoice.Reference_Number__c);

    if (textBody.contains('Invoice__c.Provider_Name__c')) {
      textBody = textBody.replace('Invoice__c.Provider_Name__c', rejectedInvoice.Provider_Name__c);
    }
    if (textBody.contains('Invoice__c.ClientNameFormula__c')) {
      textBody = textBody.replace('Invoice__c.ClientNameFormula__c', rejectedInvoice.ClientNameFormula__c);
    }
    return textBody;
  }
}