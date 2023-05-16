/**
 * @description  Handler class for AccountTrigger
 * @company      Cloudwerx
 * @date         23/12/2019
 * @testClass    AccountTriggerHandlerTest
**/

public class AccountTriggerHandler {
	public static String description = null;
    public static Boolean isFirstTime = true;
    public static String randomNum = '';
    public static final String PROVIDER_HIERARCHY_LIMIT_ERROR_MESSAGE = 'You can\'t add a parent to a provider that is already parent';
    public static final String PROVIDER_HIERARCHY_ABN_ERROR_MESSAGE = 'The ABN can\'t be changed if the child account(s) have a different ABN';
    public static final String MPM = 'MPM';
    public static final String NDSP = 'NDSP';
    public static final String NDSP_EXCEPTION = 'NDSP Exception';
    public static final String MPM_EXCEPTION = 'Exception';
    public static final Map<ID,Schema.RecordTypeInfo> rt_Map = Account.sObjectType.getDescribe().getRecordTypeInfosById(); //Getting Account recordTypes

    /**
     * @description  This method is used to copy name fields for Account
     * @author		 
     * @param        accounts : list of accounts
     * @return       NA
    **/
    //workaround for https://myplanmanager.atlassian.net/browse/SI-172
    public static void copyNameFieldForAccounts(List<Account> accounts) {
        for (Account account : accounts) {
            if (account.RecordTypeId == RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID) {
                String firstName = String.isBlank(account.FirstName) ? '' : account.FirstName + ' ';
                String middleName = String.isBlank(account.MiddleName) ? '' : account.MiddleName + ' ';
                String lastName = String.isBlank(account.LastName) ? '' : account.LastName;

                account.RO_Name__c = firstName + middleName + lastName;
            } else {
                account.RO_Name__c = account.Name;
            }
        }
    }

    /**
     * @description  This method is used to check ABN and provider hierarchy depth
     * @author		 
     * @param        updatedProviderAccounts : list of updated accounts
     *               oldAccountMap : old map of accounts
     * @return       NA
    **/
    public static void checkABNAndProviderHierarchyDepth(List<Account> updatedProviderAccounts, Map<Id, Account> oldAccountMap) {
        //ACEM-2 added query limit
        List<Account> childAccounts = [SELECT Id, ABN__c, ParentId FROM Account WHERE ParentId IN :updatedProviderAccounts Limit 50000];

        Map<Id, List<Account>> childAccountsByParentId = new Map<Id, List<Account>>();

        for (Account childAccount : childAccounts) {
            if (!childAccountsByParentId.containsKey(childAccount.ParentId)) {
                childAccountsByParentId.put(childAccount.ParentId, new List<Account>());
            }
            childAccountsByParentId.get(childAccount.ParentId).add(childAccount);
        }

        for (Account updatedProviderAccount : updatedProviderAccounts) {
            Account oldProviderAccount = oldAccountMap.get(updatedProviderAccount.Id);

            //don't bother to validate if the provider isn't a parent
            if (childAccountsByParentId.containsKey(updatedProviderAccount.Id)) {
                if (updatedProviderAccount.ParentId != null &&
                    oldProviderAccount.ParentId != updatedProviderAccount.ParentId) {

                    updatedProviderAccount.addError(PROVIDER_HIERARCHY_LIMIT_ERROR_MESSAGE);
                }

                if (oldProviderAccount.ABN__c != updatedProviderAccount.ABN__c) {
                    for (Account childAccount : childAccountsByParentId.get(updatedProviderAccount.Id)) {
                        if (childAccount.ABN__c != updatedProviderAccount.ABN__c) {
                            updatedProviderAccount.addError(PROVIDER_HIERARCHY_ABN_ERROR_MESSAGE);
                            break;
                        }
                    }
                }
            }
        }
    }

    /**
     * @description  This method is create EntitySubscription for existing cases for Accounts where owner is changed
     * @author		 
     * @param        accounts : list of accounts
     *               oldAccountsMap : map of old accounts
     * @return       NA
    **/
    public static void followCasesForOneToOneAccount(List<Account> accounts, Map<Id, Account> oldAccountsMap) {
        List<Id> oneToOneAccountsWithChangedOwners = new List<Id>();

        for (Account account : accounts) {
            if (oldAccountsMap.get(account.Id).OwnerId != account.OwnerId) {
                if (account.One_to_One_Account__c) {
                    oneToOneAccountsWithChangedOwners.add(account.Id);
                }
            }
        }

        //hard LIMIT on soql query to prevent hitting limits
        List<Case> casesToFollow = [SELECT Id, Client__r.OwnerId FROM Case WHERE Client__c IN :oneToOneAccountsWithChangedOwners LIMIT 1000];
        List<EntitySubscription> entitySubscriptionsToCreate = new List<EntitySubscription>();

        for (Case caseToFollow : casesToFollow) {
            entitySubscriptionsToCreate.add(new EntitySubscription(ParentId = caseToFollow.Id, SubscriberId = caseToFollow.Client__r.OwnerId));
        }

        //entity subscriptions have a uniqueness constraint
        Database.insert(entitySubscriptionsToCreate, false);
    }

    /**
     * @description  This method is used to copy provider business email to provider Remittance email
     * @author		 
     * @param        newProviderAccounts : list of provider accounts
     * @return       NA
    **/
    public static void copyProviderBusinessEmailToRemittance(List<Account> newProviderAccounts) {
        for (Account newProviderAccount : newProviderAccounts) {
            if (String.isNotBlank(newProviderAccount.Business_Email__c) && String.isBlank(newProviderAccount.Provider_Remittance_Email_Address__c)) {
                newProviderAccount.Provider_Remittance_Email_Address__c = newProviderAccount.Business_Email__c;
            }
        }
    }

    /**
     * @description  This method is handle clients before insert
     * @author		 
     * @param        accList : list of accounts
     * @return       NA
    **/
    // Method to handle before insert of Client
    public static void handleBeforeInsertOfClient(List<Account> accList) {
        List<Account> accountMPMList = new List<Account> ();
        List<Account> accountNDSPList = new List<Account> ();
        List<Account> exceptionAccountMPMList = new List<Account>();
        List<Account> exceptionAccountNDSPList = new List<Account>();
        for(Account acc : accList) {
            if(acc.RecordTypeId == RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID || acc.RecordTypeId == RecordTypeUtil.RESTRICTED_CLIENT_ACCOUNT_RECORD_TYPE_ID) {
                if(!acc.Cultural_Needs__c && String.isNotBlank(acc.BillingPostalCode)) {
                    if(MPM.equalsIgnoreCase(acc.PlanManager__c)) {
                        accountMPMList.add(acc);
                    }
                    else if(NDSP.equalsIgnoreCase(acc.PlanManager__c)) {
                        accountNDSPList.add(acc);
                    }
                }
                else if(!acc.Cultural_Needs__c && String.isBlank(acc.BillingPostalCode)) {
                    if(MPM.equalsIgnoreCase(acc.PlanManager__c)) {
                        exceptionAccountMPMList.add(acc);
                    }
                    else if(NDSP.equalsIgnoreCase(acc.PlanManager__c)) {
                        exceptionAccountNDSPList.add(acc);
                    }
                }
            }
        }

        //Update Non Cultural Pod on MPM Client
        if(accountMPMList?.size() > 0) {
            compareBillingPostCodes(accountMPMList, MPM);
        }
         //Update Non Cultural Pod on NDSP Client
        if(accountNDSPList?.size() > 0) {
            compareBillingPostCodes(accountNDSPList, NDSP);
        }
        // Update Exception Pod on MPM Clients where BillingPostalCode is Blank
        if(exceptionAccountMPMList?.size() > 0) {
            assignExceptionPod(exceptionAccountMPMList, MPM);
        }
        if(exceptionAccountNDSPList?.size() > 0) {
            assignExceptionPod(exceptionAccountNDSPList, NDSP);
        }
        
    }

    /**
     * @description  This method is handle clients before update
     * @author		 
     * @param        accList : list of accounts
     *               accMap : Map of accounts
     * @return       NA
    **/
    // Method to handle before update of Client
    public static void handleBeforeUpdateOfClient(List<Account> accList, Map<Id, Account> accMap) {
        List<Account> accountMPMList = new List<Account>();
        List<Account> accountNDSPList = new List<Account>();
        List<Account> culturalAccountList = new List<Account>();
        for(Account acc : accList) {
            if(acc.RecordTypeId == RecordTypeUtil.CLIENT_ACCOUNT_RECORD_TYPE_ID || acc.RecordTypeId == RecordTypeUtil.RESTRICTED_CLIENT_ACCOUNT_RECORD_TYPE_ID) {
               String billingCode = accMap.get(acc.Id).BillingPostalCode;
                if((acc.Cultural_Needs__c != accMap.get(acc.Id).Cultural_Needs__c && !acc.Cultural_Needs__c) || (!acc.Cultural_Needs__c && acc.BillingPostalCode != billingCode && String.isNotBlank(acc.BillingPostalCode) && accMap.get(acc.Id).Pod__r.Name == 'Exception') || (!acc.Cultural_Needs__c && acc.BillingPostalCode != billingCode && accMap.get(acc.Id).Pod__r.Name != 'Exception'))  {
                    if(MPM.equalsIgnoreCase(acc.PlanManager__c)) {
                        accountMPMList.add(acc);
                    }
                    else if(NDSP.equalsIgnoreCase(acc.PlanManager__c)) {
                        accountNDSPList.add(acc);
                    }
                }
            }
        }

        //Assign Non Cultural Pod
        if(accountMPMList?.size() > 0) {
            compareBillingPostCodes(accountMPMList, MPM);
        }

        if(accountNDSPList?.size() > 0) {
            compareBillingPostCodes(accountNDSPList, NDSP);
        }
    }

    /**
     * @description  This method is used to compare billing postcodes for accounts
     * @author		 
     * @param        accountList : list of accounts
     * @return       NA
    **/
    public static void compareBillingPostCodes(List<Account> accountList, String planManager) {
        List<Pod_Territory__c> podTList = new List<Pod_Territory__c>();
        Set <Integer> listOfPostalCodes = new Set <Integer>();

        if(accountList != null && !accountList.isEmpty()) {
            //ACEM-2 added query limit
            podTList = [Select Id, Name, StartingPostCode__c, EndingPostCode__c, Pod__c, Pod__r.Name FROM Pod_Territory__c WHERE PlanManager__c =:planManager Limit 50000]; //Pod__r.Name added for OPSNBOTS-104
        }

        // Add all PostalCode values of PodTerritory in a set
        if(podTList != null && !podTList.isEmpty()) {
            for(Pod_Territory__c podT : podTList) {
                Decimal startingPostalCode = podT.StartingPostCode__c;

                while (startingPostalCode <= podT.EndingPostCode__c) {
                    listOfPostalCodes.add(Integer.ValueOf(startingPostalCode));
                    startingPostalCode ++;
                }  
            }
        }
        String exceptionName = (NDSP.equalsIgnoreCase(planManager)) ? NDSP_EXCEPTION : MPM_EXCEPTION;
        //ACEM-2 added query limit
        Pod__c exceptionPod = [Select Id, Pod_Type__c, Name FROM Pod__c WHERE Pod_Type__c = 'Regional' AND Name =: exceptionName Limit 1];
        
        // compare BillingPostal Code of Client with Pod Territory Postal Codes
        if(podTList != null && !podTList.IsEmpty() && accountList != null && !accountList.isEmpty()) {
            for(Account account : accountList) {
                if(account.BillingPostalCode != NULL && listOfPostalCodes.contains(Integer.ValueOf(account.BillingPostalCode))) {
                    assignPod(account,podTList);
                }
                else {
                    account.Pod__c = exceptionPod.Id;
                    //Below code added for OPSNBOTS-104
                    checkForSalesforceClaimingExp(account, exceptionPod.Name);
                    //End here
                }
            }
        }
    }

    /**
     * @description  Method to set Salesforce_Claiming_Experience__c to true based on Pod
     * @author		 Akshansh
     * @param        account : account record
     *               podName : Pod name string
     * @return       NA
    **/
    private static void checkForSalesforceClaimingExp(Account acc, String podName) {
        if(General_T2P_Settings__c.getOrgDefaults()?.ACE_Pod_Names__c != null
            && General_T2P_Settings__c.getOrgDefaults().ACE_Pod_Names__c.containsIgnoreCase(podName) //If condition added for OPSNBOTS-104
        ) {
            acc.Salesforce_Claiming_Experience__c = true;
        }
    }

    /**
     * @description  Method to Assign Pod to  Non Cultural Client
     * @author		 
     * @param        account : account record
     *               podTList : List of Pod_Territory__c
     * @return       NA
    **/
    public static void assignPod(Account account, List<Pod_Territory__c> podTList) {
        for(Pod_Territory__c podT : podTList) {
            if(Integer.ValueOf(account.BillingPostalCode) >= Integer.ValueOf(podT.StartingPostCode__c) && Integer.ValueOf(account.BillingPostalCode) <= Integer.ValueOf(podT.EndingPostCode__c)) {
                account.Pod__c = podT.Pod__c;
                //Below code added for OPSNBOTS-104
                checkForSalesforceClaimingExp(account, podT.Pod__r.Name);
                //End here
                break;
            }
        }
    }

    /**
     * @description  Method to Assign Exception Pod to Clients
     * @author		 
     * @param        exceptionAccountList : list of Account
     * @return       NA
    **/
    public static void assignExceptionPod(List<Account> exceptionAccountList, String PlanManager) {
        String exceptionName = (NDSP.equalsIgnoreCase(planManager)) ? NDSP_EXCEPTION : MPM_EXCEPTION;
        //ACEM-2 added query limit
        Pod__c Pod = [Select Id, Pod_Type__c, Name FROM Pod__c WHERE Pod_Type__c = 'Regional' AND Name =: exceptionName Limit 1];
        if(Pod!= null) {
            for(Account acc : exceptionAccountList) {
                acc.Pod__c = Pod.Id;
                //Below code added for OPSNBOTS-104
                checkForSalesforceClaimingExp(acc, Pod.Name);
                //End here
            }
        }
    }

    /**
     * @description  method to update pods on related cases
     * @author		 
     * @param        clientSkillChangeMap : Map of Account
     * @return       NA
    **/
    public static void updateCasePodSkill(Map<Id, Account> clientSkillChangeMap) {   
        Map<String,String> clientSkillMap = new Map<String,String>();         
        List<Case> casesToUpdate = new List<Case>();

        Database.DMLOptions options = new Database.DMLOptions();
        options.assignmentRuleHeader.useDefaultRule = true; //this would run the assignment rule when cases are updated
        //ACEM-2 added query limit
        List <Account> accountList = [SELECT Id,Pod__c,Pod__r.Pod_Skill_New__c FROM Account WHERE Id IN :clientSkillChangeMap.keySet()Limit 50000];

        for(Account acc : accountList){  
            if (acc.Pod__c != null) {
                clientSkillMap.put(acc.Id,acc.Pod__r.Pod_Skill_New__c);
            } else if (acc.Pod__c == null) {
                clientSkillMap.put(acc.Id,'');
            }
        } 
        //ACEM-2 added query limit
        List<Case> listOfCases = [SELECT Id, Client__c,Status,OwnerId FROM Case WHERE Client__c IN :clientSkillChangeMap.keySet() Limit 50000];

        for(Case caseRecord : listOfCases) {
            if (clientSkillMap.containsKey(caseRecord.Client__c) && !'Closed'.equalsIgnoreCase(caseRecord.Status)) {
                if (clientSkillMap.get(caseRecord.Client__c) != '') {
                    caseRecord.PodSkillRequirement__c = clientSkillMap.get(caseRecord.Client__c);
                } else {
                    caseRecord.PodSkillRequirement__c = '';
                } 
                casesToUpdate.add(caseRecord);
                if(string.valueOf(caseRecord.OwnerId).startsWith('00G')) {
                    caseRecord.setOptions(options);
                }
            }
        }        
        update(casesToUpdate);

        //Update Pod_Skill_Requirement__c on Invoice record //TTP-2780
        //ACEM-2 added query limit
        List<Invoice__c> listOfInvoices = [SELECT Id, Client__c FROM Invoice__c WHERE Status__c = 'Failed' AND Client__c IN :clientSkillChangeMap.keySet() Limit 50000];

        for(Invoice__c invoiceRecord : listOfInvoices) {
            if (clientSkillMap.get(invoiceRecord.Client__c) != '') {
                invoiceRecord.Pod_Skill_Requirement__c = clientSkillMap.get(invoiceRecord.Client__c);
            } else {
                invoiceRecord.Pod_Skill_Requirement__c = '';
            } 
        }        
        update(listOfInvoices);
    }

    /**
     * @description  [T2P-263] To generate random number format
     * @author		 
     * @param        createdDate : created Date
     * @return       String : random no
    **/
    public static String randomNumber(DateTime createdDate) {
        
        randomNum = String.valueOf(Math.round((Math.random() * (90000) + 9500 + createdDate.day())));

        if(String.valueOf(randomNum).length() != 5) {
            randomNumber(createdDate);
        }

        return randomNum;
    }

    /**
     * @description  [T2P-263] To generate account number for the new Accounts
     * @author		 
     * @param        clonedAccountList : cloned accounts list
     * @return       Map<Id,Account>
    **/
    public static Map<Id,Account> generateAccountNumber(List<Account> clonedAccountList) {

        Map<Id, Account> accIdMap = new Map<Id, Account>();
        
        List<Account> failedAccIdList = new List<Account>();

        for(Integer i=0; i<clonedAccountList.size(); i++) {
            DateTime createdDate = clonedAccountList[i].CreatedDate;
            String year = String.valueOf(createdDate.year()).substring(2);
            String month = String.valueOf(createdDate.month()).length() == 1 ? '0' + String.valueOf(createdDate.month()) : String.valueOf(createdDate.month());
            String day = String.valueOf(createdDate.day()).length() == 1 ? '0' + String.valueOf(createdDate.day()) : String.valueOf(createdDate.day());
            String dateFormat = year + month + day;
            String accNum = '';
            
            // random number format : YYMMDD-XXXXX
            accNum = dateFormat + '-' + randomNumber(createdDate);
            clonedAccountList[i].MPMAccountNumber__c = accNum;

            // create map with id and account obj and return map
            accIdMap.put(clonedAccountList[i].Id, clonedAccountList[i]);
        }

        return accIdMap;
    }

    /**
     * @description  [T2P-263] To update the Account with MPM Account Number
     * @author		 
     * @param        accountList : accounts list
     * @return       NA
    **/
    public static void updateAccountNumber(List<Account> accountList) { 
        
        List<Account> clonedAccountList = new List<Account>();
        
        if (MPMAccountNumberGeneratorBatch.isBatchRunning) {      
            clonedAccountList = accountList;
        } else {
            clonedAccountList = accountList.deepClone(true, true, true);
        }

        List<Account> finalAccountList = new List<Account>();

        for (Integer i=0; i<clonedAccountList.size(); i++) {
            if(clonedAccountList[i].MPMAccountNumber__c == null || clonedAccountList[i].MPMAccountNumberLength__c != 12) {
                finalAccountList.add(clonedAccountList[i]);
            }
        }

        if (finalAccountList.size() > 0) {
            Map<Id, Account> accMap = generateAccountNumber(finalAccountList);
            List<EventLog__e> logList = new List<EventLog__e>();
            try {
                Database.SaveResult[] resultList =  Database.update(accMap.values(), false);
                for (Integer i = 0; i < accMap.values().size(); i++) {
                    Database.SaveResult sr = resultList[i]; //Get updated result
                    Account recId = accMap.values()[i]; //Get record Id
                    if (sr.isSuccess() && accMap.containsKey(recId.Id)) { //If success increase count
                        //Success
                        accMap.remove(recId.Id);               // contains only Accounts which failed to insert
                        description = null;
                    } else {  
                        for(Database.Error err : sr.getErrors()) { //If error append error message in description field for each error record
                            if(description == null) {
                                description = String.valueOf(err.getStatusCode() + ': ' + err.getMessage() + '\n' +'For record :'+recId.Id)+'\n';    
                            } else {
                                description += String.valueOf(err.getStatusCode() + ': ' + err.getMessage() + '\n' + 'For record :'+recId.Id)+'\n';    
                            }
                        }   
                    } 
                }
                
                //Platform Event published to insert batch error log
                if (description != null) {
                    EventLog__e evt =  LogService.logSaveResult('AccountTriggerHandler','updateAccountNumber',description,null, '', ''); 
                    logList.add(evt);//EventBus.publish(evt);
                }

                // If any duplicate values error occurs, re-generate the MPM Account Number
                if (accMap.size() > 0) {            
                    updateAccountNumber(accMap.values());
                }
            } catch (Exception e) {
                //Platform Event published to insert exception log
                EventLog__e evt =  LogService.logException(e,'Account'); //Exception Object, Object Name
                logList.add(evt);//EventBus.publish(evt);
            } finally {
                LogService.insertLog(logList);               
            }
        }
    }

    /**
     * @description  [T2P-263] To check if the MPM Account Number is updated or not depending on the custom settings value
     * @author		 
     * @param        oldAccountMap : old map account
     *               newAccountList : new accounts list
     * @return       NA
    **/
    public static void validateAccount(Map<Id, Account> oldAccountMap, List<Account> newAccountList) {
        for(Account acc : newAccountList) {
            if(oldAccountMap.get(acc.Id).MPMAccountNumber__c != null 
                && oldAccountMap.get(acc.Id).MPMAccountNumber__c != acc.MPMAccountNumber__c 
                && EditFieldSettings__c.getInstance().IsMPMAccountNumberEditable__c == false) {
                    acc.MPMAccountNumber__c.addError('You cannot edit this field');  
            }
        }
    }
}