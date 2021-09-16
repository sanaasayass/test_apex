trigger ContractEndDateAdapterTrigger on SBQQ__Subscription__c (after insert, after update) {
    
    if(trigger.isInsert && trigger.isAfter) SubContracts.updateContratEndDate(trigger.new);
    if(trigger.isUpdate && trigger.is) SubContracts.updateContratEndDate(trigger.new);
}