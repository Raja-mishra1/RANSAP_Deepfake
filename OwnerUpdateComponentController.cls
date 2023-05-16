/**
 * @description  Controller Class for OwnerUpdateComponent 
 * @author       Sonali Bhat
 * @company      CloudWerx
**/
public class OwnerUpdateComponentController {

   /**
    * @description  Method to retrieve all the fields which are required for the received record Ids
    * @author       Sonali Bhat
    * @param        recordList  :  list of records received from component
    *               parentField :  Name of the Parent field present on the records
    *               sObjectName :  Name of the Object for which record Ids are received
    * @return       List<SObject> : List of records 
   **/
    @AuraEnabled
    public static objectData retrieveSObjectRecords(
        List<SObject> recordList, String parentField, String sObjectName
    ) {
        List<String> recordIdList = new List<String>();
        for (SObject obj : recordList) {
            String val = '\''+obj.Id+'\'';
            recordIdList.add(val);
        }
        // add the parent object field - PlanManagerField
        String parentPlanManager = parentField.replace('__c' , '__r') +'.'+'PlanManager__c';
       
        String query = 'SELECT Name, PlanManager__c, ' +parentField+ +', ' + parentPlanManager;
        query += ' FROM ' +sObjectName;
        query += ' WHERE Id IN  ' +recordIdList;

        List<SObject> sObjectRecordList  = Database.query(query);

        String parentObject = parentField.replace('__c' , '__r');

        // get the Plan Manager value on parent object
        String parentPlanManagerValue = 
            (String)sObjectRecordList[0]?.getSObject(parentObject)?.get('PlanManager__c');

        // call to helper method
        String planManagerValue = OwnerUpdateComponentCtrlHelper.getPlanManagerValue(
            sObjectRecordList, parentPlanManagerValue);

        objectData objectDataWrapper = new objectData();
        // populate wrapper properties
        objectDataWrapper.planManagerValue = planManagerValue;
        objectDataWrapper.sObjectRecordList = sObjectRecordList;

        return objectDataWrapper;
    }

    /**
     * @description  Method to get the records of User/Queue
     * @author       Sonali Bhat
     * @param        userOrGroupObjName  : Name of the Object - User/Group
     *               objectName : Name of the object - Case / Invoice
     *               searchString : User/Queue Name searched in component
     *               planManagerValue : Attribute value (MPM/NDSP/Null)
     * @return       List<OwnerUpdateComponentCtrlHelper.RecordsData> : Wrapper List
    **/
    @AuraEnabled 
    public static List<OwnerUpdateComponentCtrlHelper.RecordsData> fetchRecords( 
        String userOrGroupObjName, 
        String objectName, 
        String searchString, 
        String planManagerValue 
    ) {
        List<OwnerUpdateComponentCtrlHelper.RecordsData> recordsDataList = 
            OwnerUpdateComponentCtrlHelper.fetchRecords
            (
                userOrGroupObjName, objectName, searchString, planManagerValue
            );
        return recordsDataList;
    }

    /**
     * @description  Method to update the Owner on records received from component
     * @author       Sonali Bhat
     * @param        recordList :  list of records received from the component 
     * @return       void
    **/
    @AuraEnabled
    public static void updateOwner(List<SObject> recordList) {
        if (!recordList.isEmpty()) {
            // update records
            Database.SaveResult[] srList = Database.update(recordList, false); 

            // Iterate through each returned result by the method
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    for (Database.Error objErr : sr.getErrors()) {
                        System.debug('The following error has occurred.');                            
                        System.debug(objErr.getStatusCode() + ': ' + objErr.getMessage());
                        throw new AuraHandledException(objErr.getMessage());
                    }
                }
            }            
        }
    }

    /**
     * @description  Wrapper Class to get record list of object and Plan Manager Value
     * @author       Sonali Bhat
    **/
    public class objectData {
        @AuraEnabled public String planManagerValue;
        @AuraEnabled public List<sObject> sObjectRecordList;
    }
}