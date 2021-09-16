
    global class exercice4 implements Database.Batchable<sObject> {
        private static final String ELEMENTS_MANQUANTS = RS_GloablsC.Status_ELEMENTS_MANQUANTS;
        private static final String IMMO_NEUF = RS_GloablsC.ComplianceProcess_IMMO_NEUF;
        private static list<SBQQ__Subscription__c> subs = new list<SBQQ__Subscription__c>();
        private static set<String> setParentId = new set<String>();

        private static final String PUB = RS_GloablsC.ComplianceProcess_PUB;
        private static final set<String> setComplianceProcess = new set<String>{IMMO_NEUF, PUB};
        
        
        global Database.QueryLocator start(Database.BatchableContext cnxs) { 
            String  subscription = 'SELECT Id, CompanyAddressCity__c, OrderNumber__c, CompanyAddressCountry__c, CompanyPhone__c, ContactGender__c, ContactLastName__c,';
            subscription += 'ContactFirstName__c, Companyindustry__c, CompanyName__c, PrintVolume__c, BroadcastSoftware__c, PromoterDescription__c, SBQQ__RequiredById__c,';
            subscription += 'FlowType__c, BroadcastPartner__c, PostalCode__c, Souscription_Conforme__c, ComplianceProcess__c, Status__c, AccessStoreState__c,';
            subscription += 'ProductWorkflow__c, AccessUserId__c, KilometerRadius__c, AccessStoreId__c, CompanyAddressStreet__c, CompanyAddressZipcode__c, LeadPhone__c,';
            subscription += 'ContractEmail__c, CompanySegment__c, CompanySiret__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS';
            subscription += 'AND Souscription_Conforme__c = false';
            return Database.getQueryLocator(subscription);
        }
        
        global void execute(Database.BatchableContext cnx, List<SBQQ__Subscription__c> scope) {
            try {
             // List<SBQQ__Subscription__c> subs = new List<SBQQ__Subscription__c>();
                for(SBQQ__Subscription__c sub : scope) {
                    if (setComplianceProcess.contains(sub.ComplianceProcess__c)) {
                        if (setConformiteImmoNeufEtPub(sub) != null) {
                            if (sub.SBQQ__RequiredById__c != null) {
                               setParentId.add(sub.SBQQ__RequiredById__c);
                           }
                        }
                    }
                }
            } catch(Exception e) {
                Logs.error('SubscriptionComplianceCheck','Batch Compliance Check', e);
            }
        }
        
        global void finish(Database.BatchableContext cnx) {
            if(!subs.isEmpty()) update subs;
           
    
        }
        
    
        private SBQQ__Subscription__c setConformiteImmoNeufEtPub(SBQQ__Subscription__c subscription) {
            Boolean estConforme = 'Non';
            subscription.MissingInformations__c = '';
            switch on subscription.ComplianceProcess__c {
                when IMMO_NEUF {
                    if(subscription.PromoterDescription__c != null && subscription.FlowType__c != null && subscription.ProductWorkflow__c != null
                      && subscription.ContractEmail__c != null && subscription.CompanySiret__c != null && subscription.CompanyName__c != null
                      && subscription.CompanyAddressStreet__c != null && subscription.CompanyAddressZipcode__c != null && subscription.CompanyAddressCity__c != null
                      && subscription.CompanyPhone__c != null && subscription.ContactGender__c != null && subscription.ContactFirstName__c != null 
                      && subscription.ContactLastName__c != null && subscription.LeadPhone__c != null) {
                        estConforme = 'Oui';
                        subscription.Souscription_Conforme__c = true;
                        
                    } else {
                        subscription.MissingInformations__c += subscription.PromoterDescription__c == null ? ' => PromoterDescription__c / ' : '';
                        subscription.MissingInformations__c += subscription.FlowType__c == null ? ' => FlowType__c / ' : '';
                        subscription.MissingInformations__c += subscription.ProductWorkflow__c == null ? '=> ProductWorkflow__c / ' : '';
                        subscription.MissingInformations__c += subscription.ContractEmail__c == null ? '=> ContractEmail__c / ' : '';
                        subscription.MissingInformations__c += subscription.CompanySiret__c == null ? '=> CompanySiret__c / ' : '';
                        subscription.MissingInformations__c += subscription.CompanyName__c == null ? '=> CompanyName__c / ' : '';
                        subscription.MissingInformations__c += subscription.CompanyAddressStreet__c == null ? '=> CompanyAddressStreet__c / ' : '';
                        subscription.MissingInformations__c += subscription.CompanyAddressZipcode__c == null ? '=> CompanyAddressZipcode__c / ' : '';
                        subscription.MissingInformations__c += subscription.CompanyAddressCity__c == null ? '=> CompanyAddressCity__c / ' : '';
                        subscription.MissingInformations__c += subscription.CompanyPhone__c == null ? '=> CompanyPhone__c / ' : '';
                        subscription.MissingInformations__c += subscription.ContactGender__c == null ? '=> ContactGender__c / ' : '';
                        subscription.MissingInformations__c += subscription.ContactFirstName__c == null ? '=> ContactFirstName__c / ' : '';
                        subscription.MissingInformations__c += subscription.ContactLastName__c == null ? '=> ContactLastName__c / ' : '';
                        subscription.MissingInformations__c += subscription.LeadPhone__c == null ? '=> LeadPhone__c / ' : '';
                    }
                    subs.add(subscription);
                }
                when PUB {
                    if(subscription.EffectiveEndDate__c != null && subscription.EffectiveEndDate__c > Date.today()) {
                        subscription.Souscription_Conforme__c = true;
                        estConforme = 'Oui';
                    } else {
                        subscription.MissingInformations__c = 'EffectiveEndDate__c';
                    }
                    subs.add(subscription);
                }
    
                if(estConforme == 'Oui'){
                    return subscription;
                }
                else {
                    return null;
                }
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





