/**
* @description  Generic Controller Class for OwnerUpdateComponent & CaseReassignmentWizardController 
* @author       Rohit Tikoo
* @company      CloudWerx
**/
public class OwnerUpdateComponentCtrlHelper {

    /**
    * @description  Method to get the records of User/Queue
    * @author       Rohit Tikoo
    * @param        userOrGroupObjName  : Name of the Object - User/Group
    *               objectName : Name of the object - Case / Invoice
    *               searchString : User/Queue Name searched in component
    *               planManagerValue : Attribute value (MPM/NDSP/Null)
    * @return       List<RecordsData> : Wrapper List
    **/
    public static List<RecordsData> fetchRecords( 
        String userOrGroupObjName, 
        String objectName, 
        String searchString, 
        String planManagerValue 
    ) {
        List<RecordsData> recordsDataList = new List<RecordsData>();
        try {
            String query = '';
            if(userOrGroupObjName == 'group'){
                query = 'Select QueueId, Queue.Name FROM QueueSobject WHERE '+
                        'SobjectType = '+ '\'' +objectName+ '\' AND '+
                        'Queue.Name LIKE ' + '\'%' + String.escapeSingleQuotes(searchString.trim())+ 
                        '%\'';                
            
                if (String.isNotBlank(planManagerValue) && planManagerValue == NDSPConstants.MPM) {
                    // Plan Manager Value = 'MPM'
                    String temp = NDSPConstants.NDSP;
                    query +=  ' AND (NOT Queue.DeveloperName LIKE ' + '\'' + temp + '%\'' + ')';
                
                } else if (String.isNotBlank(planManagerValue) && planManagerValue == NDSPConstants.NDSP) {
                    // Plan Manager Value = 'NDSP'
                    query +=  ' AND (Queue.DeveloperName LIKE '+'\'' +planManagerValue+ '%\'' + ')';
                    }
                }
                //[CS-231] Added filter to return only Active users
            else{
                query = 'SELECT Id, Name' +
                        ' FROM '+userOrGroupObjName+
                        ' WHERE Name LIKE ' + '\'' +String.escapeSingleQuotes(searchString.trim())+ 
                        '%\'' + ' AND IsActive = True ';
                
                if (String.isNotBlank(planManagerValue)) {
                    query +=  ' AND PlanManager__c = ' +'\'' +planManagerValue+'\'';
                }
            }
            query += ' LIMIT 50000';

            for(SObject s : Database.query(query)){
                if (userOrGroupObjName == 'group') {
                    recordsDataList.add
                        ( 
                            new RecordsData((String)s?.getSObject('Queue')?.get('Name'), 
                            (String)s.get('QueueId')) 
                        );
                } else {
                    recordsDataList.add
                        (
                            new RecordsData((String)s.get('Name'), 
                            (String)s.get('id'))
                        );
                }
            } 
        } catch(Exception e) {
            if (String.isNotBlank(e.getMessage() ) && e.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(e.getMessage().split('error:')[1].split(':')[0]+'.');
            } else {
                throw new AuraHandledException(e.getMessage());
            }
        }
        return recordsDataList;
    }

    /**
    * @description  Method to get the Plan Manager Value from record OR record's Parent object 
                    OR User record
    * @author       Rohit Tikoo
    * @param        listOfRecords :  records received from component
    *               getPlanManagerValue  :  PlanManager__c value on Parent Object
    * @return       String : Plan Manager Value, can be MPM/NDSP or null
    **/
    public static string getPlanManagerValue(
        List<SObject> listOfRecords, 
        String parentPlanManagerValue
    ) {
        try {
            String planManagerValue;
            if (listOfRecords?.size() == 1) {
                // only 1 record is present
                if (listOfRecords[0].get('PlanManager__c') != null) {
                    // plan manager value is present on record
                    planManagerValue = (String) listOfRecords[0].get('PlanManager__c');

                } else if (String.isNotBlank(parentPlanManagerValue)) {
                    // parent plan manager value is present
                    planManagerValue = parentPlanManagerValue;

                } else {
                    // parent plan manager value is not present, get plan manager value from User
                    User u = [SELECT PlanManager__c FROM User WHERE Id =: UserInfo.getUserId()];
                    planManagerValue = u.PlanManager__c;
                }

            } else if (listOfRecords?.size() > 1) {
                /* if more than 1 record is received, 
                    plan manager value should be same and
                    present on all records
                */
                planManagerValue = (String) listOfRecords[0].get('PlanManager__c');
            }
            return planManagerValue;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    * @description  Wrapper class to hold Queue/User's Label and Value
    * @author       Rohit Tikoo
    **/
    public class RecordsData{
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public RecordsData(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}