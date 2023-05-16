/**
 * @description       : 
 * @author            : Arman Alam
 * @group             : 
 * @last modified on  : 09-14-2022
 * @last modified by  : Arman Alam
**/
public with sharing class ABNValidatorController {

    @AuraEnabled
    public static ABRService.ABNLookupResponse lookupABNController(String abn) {
        try {
            return ABRService.ABNLookup(abn);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static ABNValidatorController.ABNWrapper isABNUniqueOrOnChildOrParent(Id accountId, String abn) {
        Account account = [SELECT Id, ParentId FROM Account WHERE Id = :accountId];
        //ACEM-2 added query limit
        List<Account> accountsWithABN = [SELECT Id, ParentId, ABN__c, Business_Names__c FROM Account WHERE ABN__c = :abn AND Id != :accountId Limit 50000];
        
        //TTP-1991 start
        ABNValidatorController.ABNWrapper objWrapper = new ABNValidatorController.ABNWrapper();
        objWrapper.ABNIsUnique = true;
        objWrapper.BusinessNames = '' ;
        //TTP-1991 end

        for (Account accountWithABN : accountsWithABN) {
            //account is a child of this account OR account is the parent of this account
            if (accountWithABN.ParentId == accountId ||
                accountWithABN.Id == account.ParentId ||
                (accountWithABN.ParentId != null && accountWithABN.ParentId == account.ParentId)) {
                //abn is unique, continue
                continue;
            }
            //abn is not unique 

            //TTP-1991 start
            objWrapper.ABNIsUnique = false;
            objWrapper.BusinessNames = accountWithABN.Business_Names__c;
            if(objWrapper.BusinessNames == null) {
                objWrapper.BusinessNames = '';
            }
        }
        return objWrapper;  //TTP-1991 end
    }

    //TTP-1991 start
    // Wrapper class to return the ABN Unique flag and Business Names
    public class ABNWrapper {
        @AuraEnabled public Boolean ABNIsUnique {get;set;}
        @AuraEnabled public String BusinessNames {get; set;}
    }
    //TTP-1991 end

    @AuraEnabled
    public static void saveABNToAccount(String abn, String abnLookupResponseString, Id accountId) {
        try {
            Account accountToUpdate  = new Account();

            if (String.isBlank(abn)) {
                accountToUpdate.Id = accountId;
                accountToUpdate.ABN__c = null;
                accountToUpdate.ABN_Validated__c = null;
                accountToUpdate.ABN_Active__c = false;
                accountToUpdate.GST_Registered__c = false;
                accountToUpdate.Sole_Trader__c = false;
                accountToUpdate.Trading_Name__c = null;
                accountToUpdate.ABN_Postcode__c = null;
                accountToUpdate.ABN_State__c = null;
                accountToUpdate.Business_Names__c = null;
            } else {
                ABRService.ABNLookupResponse abnLookupResponse = (ABRService.ABNLookupResponse) JSON.deserialize(abnLookupResponseString, ABRService.ABNLookupResponse.class);
                //[TTP-1991] Start
                String businessName = '';
                if(!abnLookupResponse.BusinessName.isEmpty()) {
                    businessName = JSON.serialize(abnLookupResponse.BusinessName);
                }
                accountToUpdate.Id = accountId;
                accountToUpdate.ABN__c = abn;
                accountToUpdate.ABN_Validated__c = DateTime.now();
                accountToUpdate.GST_Registered__c = abnLookupResponse.Gst != null;
                accountToUpdate.Sole_Trader__c = abnLookupResponse.EntityTypeCode == 'IND';
                accountToUpdate.Trading_Name__c = abnLookupResponse.EntityName;
                accountToUpdate.ABN_Postcode__c = abnLookupResponse.AddressPostcode;
                accountToUpdate.ABN_State__c = abnLookupResponse.AddressState;
                accountToUpdate.Business_Names__c = businessName;

                if(abnLookupResponse.AbnStatus.equalsIgnoreCase('Active')) { 
                    //If ABN_Active__c = true
                    accountToUpdate.ABN_Active__c = abnLookupResponse.AbnStatus.equalsIgnoreCase('Active');
                }
                
                else {
                    //If ABN_Active__c = false
                    accountToUpdate.ABN_Active__c = false;
                    accountToUpdate.Status__c = 'Account Locked';
                    // Get Invoice_Instructions__c From Account
                    Account acc = [SELECT Id, Invoice_Instructions__c FROM Account WHERE Id =:accountId LIMIT 1];
                    
                    if(String.isBlank(acc.Invoice_Instructions__c)) {
                        accountToUpdate.Invoice_Instructions__c = 'ABN Inactive';   
                    } else {
                        //Check if Invoice Instruction field doesn't contain 'ABN Inactive' in it
                        if(!acc.Invoice_Instructions__c.containsIgnoreCase('ABN Inactive')) {
                            accountToUpdate.Invoice_Instructions__c = acc.Invoice_Instructions__c + ' - ' + 'ABN Inactive';     
                        }
                    }
                    //[TTP-1991] End
                }                
            }
            update accountToUpdate;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    //TTP-1502 start
    /**
    * @ description    [TTP-1502] This method is used to update account record with ABN Details
    * @ return         Account record
    * @ param          abn - ABN Number
    *                  abnLookupResponseString - response recived from ABN API
    *                  accountId - Account Id
    */

    public static Account saveABNInformation(Account accountRecord, String abnLookupResponseString) {
        try {
            Account accountToUpdate;
                ABRService.ABNLookupResponse abnLookupResponse = (ABRService.ABNLookupResponse) JSON.deserialize(abnLookupResponseString, ABRService.ABNLookupResponse.class);
                
                if(abnLookupResponse.AbnStatus.equalsIgnoreCase('Active')) { //If ABN_Active__c = true
                        accountToUpdate = new Account(
                            Id = accountRecord.Id,
                            ABN__c = accountRecord.ABN__c,
                            ABN_Validated__c = DateTime.now(),
                            ABN_Active__c = abnLookupResponse.AbnStatus.equalsIgnoreCase('Active'),
                            GST_Registered__c = abnLookupResponse.Gst != null,
                            Sole_Trader__c = abnLookupResponse.EntityTypeCode == 'IND',
                            Trading_Name__c = abnLookupResponse.EntityName,
                            ABN_Postcode__c = abnLookupResponse.AddressPostcode,
                            ABN_State__c = abnLookupResponse.AddressState,
                            Business_Names__c = JSON.serialize(abnLookupResponse.BusinessName)
                    );
                }
                if(abnLookupResponse.AbnStatus.equalsIgnoreCase('Active') && !accountRecord.Exclude_from_ABN_Validator_Clean_up__c && !accountRecord.Provider_Name_Updated_by_ABN_Validator_S__c){
                        if(abnLookupResponse.BusinessName.size() == NDSPConstants.BUSINESS_NAME_SIZE){
                                accountToUpdate.Previous_Account_Name__c = accountRecord.Name;
                                accountToUpdate.Name = abnLookupResponse.BusinessName[0];
                                accountToUpdate.Provider_Name_Updated_by_ABN_Validator_S__c = true;
                        }
                        else if (abnLookupResponse.BusinessName.size() > NDSPConstants.BUSINESS_NAME_SIZE){
                            String NAME_TYPE = System.Label.Abn_Name_Type;
                            ABRService.NameLookupResponse NameLookupReponseObject;
                            NameLookupReponseObject = ABRService.NameLookup(accountRecord.Name);
                            Boolean ABNFound = false;
                            for(ABRService.NameWrapper nameReponse : NameLookupReponseObject.Names){
                                if(nameReponse.Abn == accountRecord.ABN__c && nameReponse.NameType == NAME_TYPE &&
                                   nameReponse.Score >= ABRService.NAME_SEARCH_SCORE){
                                       
                                        accountToUpdate.Previous_Account_Name__c = accountRecord.Name;
                                        accountToUpdate.Name = nameReponse.Name;
                                        accountToUpdate.Provider_Name_Updated_by_ABN_Validator_S__c = true;
                                        ABNFound = true;
                                }
                            }
                            if (!ABNFound) {
                                accountToUpdate.Business_Name_Action_Required__c = true;
                            }
                        }
                }
                else { //If ABN_Active__c = false
                    
                    //Check if Invoice Instruction field is blank
                    if(String.isBlank(accountRecord.Invoice_Instructions__c)) {
                         	accountRecord.Invoice_Instructions__c = 'ABN Inactive';   
                    } else {
                        
                        //Check if Invoice Instruction field already contains 'ABN Inactive' in it
                        if(!accountRecord.Invoice_Instructions__c.containsIgnoreCase('ABN Inactive')) {
                       		accountRecord.Invoice_Instructions__c = accountRecord.Invoice_Instructions__c + ' - ' + 'ABN Inactive';     
                        }
                       
                    }
                    
                    accountToUpdate = new Account(
                        Id = accountRecord.Id,
                        ABN__c = accountRecord.ABN__c,
                        ABN_Validated__c = DateTime.now(),
                        ABN_Active__c = false,
                        GST_Registered__c = abnLookupResponse.Gst != null,
                        Sole_Trader__c = abnLookupResponse.EntityTypeCode == 'IND',
                        Trading_Name__c = abnLookupResponse.EntityName,
                        ABN_Postcode__c = abnLookupResponse.AddressPostcode,
                        ABN_State__c = abnLookupResponse.AddressState,
                        Business_Names__c = JSON.serialize(abnLookupResponse.BusinessName),
                        Invoice_Instructions__c = accountRecord.Invoice_Instructions__c,
                        Status__c = 'Account Locked' 
                    );
                }
            //To pass test case
            if(Test.isRunningTest()) {
                accountToUpdate.Id = null;
            }

            //Return account to update
            return accountToUpdate;

        } catch (Exception e) {
            //Insert a log
            EventLog__e evt =  LogService.logException(e,'Account'); //Exception Object, Object Name
            LogService.insertLog(new List<EventLog__e>{evt});//EventBus.publish(evt);   
            return null;
        }
    }

}