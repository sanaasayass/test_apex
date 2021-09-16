global class SubscriptionComplianceCheck implements Database.Batchable<sObject> {
 //Pour rendre  le code beaucoup plus dynamique et flexible – j’ai crée une class 'RS_GloablsC' qui contients tout les constants (pour eviter le codage en dur dans le batch apex en question )
    private static final String ELEMENTS_MANQUANTS = RS_GloablsC.Status_ELEMENTS_MANQUANTS;
    private static final String IMMO_NEUF = RS_GloablsC.ComplianceProcess_IMMO_NEUF;
    private static list<SBQQ__Subscription__c> subs = new list<SBQQ__Subscription__c>();
    private static set<String> setParentId = new set<String>();
    
    //Pour éviter d'atteindre les limites du gouverneur :j’ai renplacer la methode qui était en début du batch par la méthode start 
    global Database.QueryLocator start(Database.BatchableContext cnx) { 
        String  subscription = 'SELECT Id, CompanyAddressCity__c, OrderNumber__c, CompanyAddressCountry__c, CompanyPhone__c, ContactGender__c, ContactLastName__c,';
        subscription += 'ContactFirstName__c, Companyindustry__c, CompanyName__c, PrintVolume__c, BroadcastSoftware__c, PromoterDescription__c, SBQQ__RequiredById__c,';
        subscription += 'FlowType__c, BroadcastPartner__c, PostalCode__c, Souscription_Conforme__c, ComplianceProcess__c, Status__c, AccessStoreState__c,';
        subscription += 'ProductWorkflow__c, AccessUserId__c, KilometerRadius__c, AccessStoreId__c, CompanyAddressStreet__c, CompanyAddressZipcode__c, LeadPhone__c,';
        subscription += 'ContractEmail__c, CompanySegment__c, CompanySiret__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS';
        subscription += 'AND Souscription_Conforme__c = false';
        return Database.getQueryLocator(subscription);
    }
    //j’ai remarque que dans la   méthode excute y’vait un boucle for qui contient une sous  méthode (et cette methode contient  une opération MLD : chose qui n’est pas parmis les best practices de salesforce 
    global void execute(Database.BatchableContext cnx, List<SBQQ__Subscription__c> scope) {
        try {
         // List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();
            for(SBQQ__Subscription__c sub : scope) {
               if (sub.ComplianceProcess__c == IMMO_NEUF) {
                    SBQQ__Subscription__c subImmo = setConformiteImmoNeuf(sub);
                    if (subImmo != null) {
                        if (sub.SBQQ__RequiredById__c != null) {
                          // setParentConforme(sub.SBQQ__RequiredById__c);
                           setParentId.add(sub.SBQQ__RequiredById__c);
                       }
                    }
                }
            }
        } catch(Exception e) {
            Logs.error('SubscriptionComplianceCheck','Batch Compliance Check', e);
        }
    }
    //cette méthode est appelée à la fin, elle est chargée d'effectuer des opérations de post-traitement et pour se faire j’ai effectuer les opérations dml pour les list de souscriptions et de la souscription parent 
    global void finish(Database.BatchableContext cnx) {
        if(!subs.isEmpty()) update subs;
    	setParentConforme(setParentId);

    }
    
// la méthode est appelé dans une boucle for : alors j'ai retirer le 'update sub'
    private SBQQ__Subscription__c setConformiteImmoNeuf(SBQQ__Subscription__c sub) {
        if(sub.PromoterDescription__c != null && sub.FlowType__c != null && sub.ProductWorkflow__c != null
          && sub.ContractEmail__c != null && sub.CompanySiret__c != null && sub.CompanyName__c != null
          && sub.CompanyAddressStreet__c != null && sub.CompanyAddressZipcode__c != null && sub.CompanyAddressCity__c != null
          && sub.CompanyPhone__c != null && sub.ContactGender__c != null && sub.ContactFirstName__c != null 
          && sub.ContactLastName__c != null && sub.LeadPhone__c != null) {
            sub.Souscription_Conforme__c = true;
            subs.add(sub);
          //  update sub;
            return sub;
        }else{
             return null;
             }
    }
    
    private void setParentConforme(set<String> parentIds) {
        list<SBQQ__Subscription__c> subsToUpdate = new list<SBQQ__Subscription__c>();
        list<SBQQ__Subscription__c> ParentSubs = [SELECT Id, Souscription_Conforme__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS 
                                           AND Souscription_Conforme__c = false AND Id IN :parentIds];

        if (ParentSubs.size() > 0) {
            for(SBQQ__Subscription__c parentSub : ParentSubs){
                parentSub.Souscription_Conforme__c = true;
                subsToUpdate.add(parentSub);
            }
         //ParentSub[0].Souscription_Conforme__c = true;
        // UPDATE parentSub[0];
        }
        if(!subsToUpdate.isEmpty()) update subsToUpdate;
	    

    }

    
}