/**
 * @description  Controller class for InvoiceOwnerUpdate VF Page 
 * @author       Sonali Bhat
 * @company      CloudWerx
**/
public class InvoiceOwnerUpdateController {

    PageReference listViewPage;
    Invoice__c[] records {get;set;}
    public String invoiceIds {get;set;}
    public String urlValue {get;set;}
   
    
    public InvoiceOwnerUpdateController(ApexPages.StandardSetController inv) {
        records = (Invoice__c[])inv.getSelected();
        invoiceIds = JSON.serialize(records);
        listViewPage = inv.cancel();
        urlValue = String.valueOf(listViewPage);
        urlValue = urlValue.remove('System.PageReference[').remove(']');   
    }

    public PageReference redirectToAura() {
        String returnUrl = 
            '/lightning/cmp/c__OwnerUpdateModal?c__listViewAttribute='+invoiceIds+
            '&c__listViewUrl='+urlValue;
        PageReference pgReturnPage = new PageReference(returnUrl);
        pgReturnPage.setRedirect(true);
        return pgReturnPage;
        
    }
}