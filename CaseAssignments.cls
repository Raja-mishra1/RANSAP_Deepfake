/*
 * Ivan Aerlic
 * Description: A class that assigns cases
 * it operates in conjunction with Case Assignment mtd
 * 
 * Version 2 :  
 * Updated By : Clouderx
 * Updated On : 8th July 2021
 */
public class CaseAssignments { 
    public static void caseAssignments(Case [] newCases, Map<Id, Case> oldCases){
        Case_Assignment__mdt [] assignments = [SELECT Id, Active__c, Description__c, Description_Not__c,NDSPSetOwnerid__c, 
                                                Email__c,Email_Not__c,Is_New__c,Owner_Id__c, Queue_Name__c,DeveloperName,
                                                Response_Received__c,Record_Type_Id__c,Set_Owner_Id__c,Owner_is_User__c, SenderEmail__c,
                                                Subject__c, Subject_Not__c, Entry_Criteria__c, PlanManager__c  FROM Case_Assignment__mdt
                                                WHERE Active__c = TRUE ORDER BY Entry_Criteria__c ASC]; 
        System.debug('CaseAssignmentValue-->'+assignments);
        for(Case newCase : newCases){ 
            Boolean oldCaseIsNull = oldCases == null;
            Case oldCase = oldCaseIsNull ? null : oldCases.get(newCase.Id);
            Boolean statusIsChanged = oldCaseIsNull ? false : newCase.Status != oldCase.Status;
            for(Case_Assignment__mdt assignment : assignments){ 
                if(!assignment.PlanManager__c.containsIgnoreCase(newCase.PlanManager__c)){
                    continue;
                }
                Set<Boolean> andLogic = new Set<Boolean>();            
                Set<Boolean> orLogic = new Set<Boolean>();
                Set<Boolean> andNotLogic = new Set<Boolean>();
                if(assignment.Is_New__c){
                    andLogic.add(newCase.Id == null);
                }
                if(assignment.Response_Received__c){
                    andLogic.add(statusIsChanged); 
                }             
                if(!isEmpty(assignment.Queue_Name__c)){
                    List<String> queueNameLst = assignment.Queue_Name__c.split(',');
                    Boolean isQueueVal = false;
                    for (String queueName : queueNameLst) {
                        if (newCase.Queue_Name__c == queueName) {
                            isQueueVal = true;
                            break;
                        }
                    }
                    andLogic.add(isQueueVal);
                }  
                if(!isEmpty(assignment.Record_Type_Id__c)){
                    andLogic.add(newCase.RecordTypeId == assignment.Record_Type_Id__c); 
                }              
                if(!isEmpty(assignment.Owner_Id__c)){
                    andLogic.add(String.valueOf(newCase.OwnerId) == assignment.Owner_Id__c); 
                }
                if(assignment.Owner_is_User__c){ 
                    andLogic.add(newCase.ownerId == null ? false :String.valueOf(newCase.ownerId).startsWith('005')); 
                }                 
                if(!isEmpty(assignment.Subject__c)){
                    orLogic.add(fieldContainsTextAreaValues(newCase.Subject, assignment.Subject__c));
                }
                if (!isEmpty(assignment.Description__c)) {
                    orLogic.add(fieldContainsTextAreaValues(newCase.Description, assignment.Description__c));
                }                
                if(!isEmpty(assignment.Email__c)){
                    orLogic.add(fieldContainsTextAreaValues(newCase.SuppliedEmail, assignment.Email__c));
                }              
                if(!isEmpty(assignment.SenderEmail__c)){//WES-31 //TTP-2933
                    orLogic.add(fieldContainsTextAreaValues(newCase.Sender__c, assignment.SenderEmail__c));
                }
                if(!isEmpty(assignment.Subject_Not__c)){
                    andNotLogic.add(fieldContainsTextAreaValues(newCase.Subject, assignment.Subject_Not__c));
                }               
                if (!isEmpty(assignment.Description_Not__c)) {
                    andNotLogic.add(fieldContainsTextAreaValues(newCase.Description, assignment.Description_Not__c));
                }               
                if(!isEmpty(assignment.Email_Not__c)){
                    andNotLogic.add(fieldContainsTextAreaValues(newCase.SuppliedEmail, assignment.Email_Not__c));
                }
                //If logic is invalid continue with next assignment rule
                if(andLogic.contains(false) 
                   || (!orLogic.isEmpty() && !orLogic.contains(true)) 
                   || andNotLogic.contains(true)){  
                    continue;  
                }
                //Assign case and break
                //SFDC-749 Added Bypass case assignment field
                newCase.Bypass_Case_Reassignment_Rules__c = True;
                newCase.ownerId = newCase.PlanManager__c == 'NDSP' ? assignment.NDSPSetOwnerid__c : assignment.Set_Owner_Id__c;
                break;
            }
        }
    }
    private static Boolean fieldContainsTextAreaValues(String caseField, String textArea){
        if(isEmpty(caseField)){
            return false;
        }
        String [] split = textArea.split('\n'); 
        for(String part : split){
            if(caseField.toLowerCase().contains(part.toLowerCase().trim())){
                return true;
            } 
        } 
        return false;
    }
    private static Boolean isEmpty(String str){
        return str == null || str == '';
    }
}