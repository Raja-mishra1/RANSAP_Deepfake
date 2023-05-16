public with sharing class LeadTriggerHandler {
    public static void copyLeadCustomFieldsToAccountStandardFields(List<Lead> convertedLeads) {
        Map<Id, Lead> convertedLeadsByAccountIds = new Map<Id, Lead>();

        for (Lead convertedLead : convertedLeads) {
            convertedLeadsByAccountIds.put(convertedLead.ConvertedAccountId, convertedLead);
        }

        List<Account> convertedAccounts = [SELECT Id FROM Account WHERE Id IN :convertedLeadsByAccountIds.keySet()];

        for (Account convertedAccount : convertedAccounts) {
            Lead convertedLead = convertedLeadsByAccountIds.get(convertedAccount.Id);
            convertedAccount.PersonBirthdate = convertedLead.Date_of_Birth__c;
            convertedAccount.PersonEmail = null;
        }

        update (convertedAccounts);
    }

    public static void createContactsForConvertedLead(List<Lead> convertedLeads, Map<Id, Lead> leadMap) {
        List<Contact> contactsToCreate = new List<Contact>();
        List<AccountContactRelation> accountContactRelationsToCreate = new List<AccountContactRelation>();
        
        Map<Id, Contact> contactsToCreateByLeadId = new Map<Id, Contact>();
        
        for (Lead convertedLead : convertedLeads) {
            if(!convertedLead.No_Contact_Details__c){   //removed the not from here
                Contact contactToCreate = new Contact();
                contactToCreate.Phone = convertedLead.Contact_Alternate_Phone_Number__c;
                contactToCreate.MobilePhone = convertedLead.Contact_Phone_Number__c;
                contactToCreate.Email = convertedLead.Email;
                contactToCreate.FirstName = convertedLead.Contact_First_Name__c;
                contactToCreate.MiddleName = convertedLead.Contact_Middle_Name__c;
                contactToCreate.LastName = convertedLead.Contact_Last_Name__c;
                contactToCreate.Communication_Preferences__c = convertedLead.Communication_Preferences__c;
                contactToCreate.PlanManager__c = convertedLead.PlanManager__c;
                
                contactsToCreateByLeadId.put(convertedLead.Id, contactToCreate);
            }
        }
        List<Database.SaveResult> insertResults = Database.insert(contactsToCreateByLeadId.values(), false);
        
        for (Integer i = 0; i < insertResults.size(); i++) {
            Database.SaveResult insertResult = insertResults[i];
            
            if (!insertResult.success) {
                for (Database.Error error : insertResult.getErrors()) {
                    if (error instanceof Database.DuplicateError) {
                        Database.DuplicateError duplicateError =  (Database.DuplicateError) error;
                        Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();
                        
                        Datacloud.MatchResult matchResult = duplicateResult.getMatchResults()[0];
                        Datacloud.MatchRecord matchRecord = matchResult.getMatchRecords()[0];
                        
                        contactsToCreateByLeadId.values()[i].Id = matchRecord.getRecord().Id;
                    }
                }
            }
        }
        
        for (Lead convertedLead : convertedLeads) {
            if(!convertedLead.No_Contact_Details__c){ //removed the not from here
                Contact createdContact = contactsToCreateByLeadId.get(convertedLead.Id);
                AccountContactRelation accountContactRelationToCreate = new AccountContactRelation();
                accountContactRelationToCreate.Relationship__c = convertedLead.Contact_Relationship__c;
                accountContactRelationToCreate.Relationship_Others__c = convertedLead.Contact_Relationship_Others__c;
                accountContactRelationToCreate.Primary_Contact__c = convertedLead.Is_Primary_Contact__c;
                accountContactRelationToCreate.AccountId = convertedLead.ConvertedAccountId;
                accountContactRelationToCreate.ContactId = createdContact.Id;
                //Sprint-6 [BT-577] start
                //only set the three fields in case the decision maker is self - since only one contact would be created then
                if (convertedLead.Primary_Decision_Maker__c == 'Self') {
                	accountContactRelationToCreate.Primary_Contact__c = true;
                    accountContactRelationToCreate.Client_Portal_Access_Level__c = 'Full access';
                    accountContactRelationToCreate.SMS_Notification__c = true;
	            }
                
                //Sprint-6 [BT-577] end
                accountContactRelationsToCreate.add(accountContactRelationToCreate);
            }
        }
        insert accountContactRelationsToCreate;
    }

    //Method to relate all 3 documents of Lead with Account on Lead Convsersion
    public static void updateDocumentsWithAccountOnLeadConversion(List<Lead> convertedLeads) {
        Map<Id,Lead> mapOfLead = new Map<Id,Lead>();
        for(Lead convertedLead : convertedLeads) {
            mapOfLead.put(convertedLead.Id,convertedLead);
        }

        List <Consent_Document__c> listOfConsentDocument = [SELECT Id, Lead__c, NDIS_Participant__c FROM Consent_Document__c WHERE Lead__c IN: mapOfLead.keySet()];
        List <Guardianship_Document__c> listOfGuardianshipDocument = [SELECT Id, Lead__c, NDIS_Participant__c FROM Guardianship_Document__c WHERE Lead__c IN: mapOfLead.keySet()];
        List <Service_Agreement__c> listOfServiceAgreement = [SELECT Id, Lead__c, NDIS_Participant__c FROM Service_Agreement__c WHERE Lead__c IN: mapOfLead.keySet()];
    
        populateLookupOfAccount(listOfConsentDocument,mapOfLead);
        populateLookupOfAccount(listOfGuardianshipDocument,mapOfLead);
        populateLookupOfAccount(listOfServiceAgreement,mapOfLead);
    }

    // Populate Lookup of Account on all 3 documents on Lead Conversion
    public static void populateLookupOfAccount(List <sObject> listOfsObject, Map<Id,Lead> mapOfLead){
        List <Consent_Document__c> updateConsentDocumentList = new List<Consent_Document__c>();
        List <Guardianship_Document__c> updateGuardianshipDocumentList = new List<Guardianship_Document__c>();
        List <Service_Agreement__c> updateServiceAgreementList = new List<Service_Agreement__c>();

        if(!listOfsObject.IsEmpty()){
            for(sObject sobj : listOfsObject){
                switch on sobj {
                    when Consent_Document__c  consentDoc{
                        Id convertedAccId = mapOfLead.get(consentDoc.Lead__c).ConvertedAccountId;
                        consentDoc.NDIS_Participant__c = convertedAccId;
                        updateConsentDocumentList.add(consentDoc);
                    }
                    when Guardianship_Document__c guardDoc {
                        Id convertedAccId = mapOfLead.get(guardDoc.Lead__c).ConvertedAccountId;
                        guardDoc.NDIS_Participant__c = convertedAccId;
                        updateGuardianshipDocumentList.add(guardDoc);
                    }
                    when Service_Agreement__c serviceDoc {
                        Id convertedAccId = mapOfLead.get(serviceDoc.Lead__c).ConvertedAccountId;
                        serviceDoc.NDIS_Participant__c = convertedAccId;
                        updateServiceAgreementList.add(serviceDoc);
                    }
                }
            }
        } 

        if(!updateConsentDocumentList.isEmpty()) {
            try {
                update updateConsentDocumentList;
            } catch(DmlException ex) {
                System.debug('Cannot Update Consent Doc'+ex);
            }    
        }
        if(!updateGuardianshipDocumentList.isEmpty()) {
            try {
                update updateGuardianshipDocumentList;
            } catch(DmlException dx) {
                System.debug('Cannot Update Consent Doc'+dx);
            }
            
        }
        if(!updateServiceAgreementList.isEmpty()) {
            try {
                update updateServiceAgreementList;
            } catch(DmlException sa) {
                System.debug('Cannot Update Consent Doc'+sa);
            }
        }
    }

    // Method to calculate Number Of Leads on Provider Account
    public static void onAfterInsertOfLead(List<Lead> newLeadList) {
        Set<Id> setOfAccountIds = new Set<Id>();
        Map<Id,Integer> mapOfProviderAccountWithLead = new Map<Id,Integer>();
        for(Lead leadObj : newLeadList) {
            if(leadObj.Provider__c != null && leadObj.Status != null && leadObj.Status != 'Lost' && leadObj.Status != 'Lost - Duplicate' && leadObj.Status != 'Converted') {
                setOfAccountIds.add(leadObj.Provider__c);
            }
        }
        List<Account> listOfAccountstoUpdate = new List<Account>();
        if(!setOfAccountIds.isEmpty()) {
            mapOfProviderAccountWithLead = getCountOfLeads(setOfAccountIds);
            for(Id accObj : setOfAccountIds) {
                if(mapOfProviderAccountWithLead.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Number_of_Leads__c = mapOfProviderAccountWithLead.get(accObj);
                    listOfAccountstoUpdate.add(acc);
                }
            } 
        }
        if(!listOfAccountstoUpdate.isEmpty()) {
            try {
                update listOfAccountstoUpdate;
            } catch(DmlException ex) {
                System.debug('Cannot update count of Leads on Provider Account on insert of Lead'+ex);
            } 
        }                             
    }

    // method on delete to calculate the number of Leads on Provider Account
    public static void onAfterDeleteOfLead(List<Lead> oldLeadList) {
        Set<Id> setOfAccountIds = new Set<Id>();
        Map<Id,Integer> mapOfProviderAccountWithLead = new Map<Id,Integer>();
        for(Lead leadObj : oldLeadList) {
            if(leadObj.Provider__c != null && leadObj.Status != null && leadObj.Status != 'Lost' && leadObj.Status != 'Lost - Duplicate' && leadObj.Status != 'Converted') {
                setOfAccountIds.add(leadObj.Provider__c);
            }
        }
        List<Account> listOfAccountstoUpdate = new List<Account>();
        if(!setOfAccountIds.isEmpty()) {
            mapOfProviderAccountWithLead = getCountOfLeads(setOfAccountIds);
            for(Id accObj : setOfAccountIds) {
                if(mapOfProviderAccountWithLead.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Number_of_Leads__c = mapOfProviderAccountWithLead.get(accObj);
                    listOfAccountstoUpdate.add(acc);
                }
                else if(!mapOfProviderAccountWithLead.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Number_of_Leads__c =0;
                    listOfAccountstoUpdate.add(acc);
                }
            } 
        }
        if(!listOfAccountstoUpdate.isEmpty()) {
            try {
                update listOfAccountstoUpdate;
            } catch(DmlException ex) {
                System.debug('Cannot update count of Leads on Provider Account on delete of Lead'+ex);
            } 
        }                             
    }

    // method on update to calculate the number of leads on Provider Account
    public static void onAfterUpdateOfLead(Map<Id,Lead> oldLeadMap, List<Lead> newLeadList) {
        Set<Id> setOfAccountIds = new Set<Id>();
        Map<Id,Integer> mapOfProviderAccountWithLead = new Map<Id,Integer>();
        for(Lead leadObj : newLeadList) {
            if((leadObj.Provider__c !=  oldLeadMap.get(leadObj.Id).Provider__c) || (leadObj.Status != oldLeadMap.get(leadObj.Id).Status)) {
                System.debug('After Update Of Lead');
                System.debug('New Provider' +leadObj.Provider__c);
                System.debug('Old Provider' +oldLeadMap.get(leadObj.Id).Provider__c);
                setOfAccountIds.add(leadObj.Provider__c);
                setOfAccountIds.add(oldLeadMap.get(leadObj.Id).Provider__c);
                
            }
        }
        setOfAccountIds.remove(null);
        System.debug('Set of Account Ids'+setOfAccountIds);
        List<Account> listOfAccountstoUpdate = new List<Account>();
        if(!setOfAccountIds.isEmpty()) {
            mapOfProviderAccountWithLead = getCountOfLeads(setOfAccountIds);
            for(Id accObj : setOfAccountIds) {
                if(mapOfProviderAccountWithLead.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Number_of_Leads__c = mapOfProviderAccountWithLead.get(accObj);
                    listOfAccountstoUpdate.add(acc);
                }
                else if(!mapOfProviderAccountWithLead.containsKey(accObj)) {
                    Account acc = new Account();
                    acc.Id = accObj;
                    acc.Number_of_Leads__c =0;
                    listOfAccountstoUpdate.add(acc);
                }
            } 
        }
        if(!listOfAccountstoUpdate.isEmpty()) {
            try {
                update listOfAccountstoUpdate;
            } catch(DmlException ex) {
                System.debug('Cannot update count of Leads on Provider Account on update of Lead'+ex);
            } 
        }                             
    }

    // method to do the aggregate query on Lead Object
    public static Map<Id,Integer> getCountOfLeads(Set<Id> setOfAccountIds) {
        Map<Id, Integer> mapOfProviderAccWithCountOfLeads = new Map<Id,Integer>();
        List<AggregateResult> AggregateResultList = [Select Provider__c, Count(Id) CountOfLead
                                                     FROM Lead 
                                                     WHERE Provider__c IN :setOfAccountIds
                                                     AND Status!= null AND Status != 'Lost' AND Status!= 'Lost - Duplicate' AND Status!= 'Converted'
                                                     GROUP BY Provider__c];
        
        if(AggregateResultList != null && AggregateResultList.size()>0) {
            for(AggregateResult ar : AggregateResultList) {
                mapOfProviderAccWithCountOfLeads.put((Id)ar.get('Provider__c'),(Integer)ar.get('CountOfLead'));
            }
        }
        return mapOfProviderAccWithCountOfLeads;
    }
}