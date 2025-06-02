trigger MilestoneTrigger on Milestone__c (after insert, after update, after delete, after undelete) {
    
    Boolean afterInsert = Trigger.isInsert && Trigger.isAfter;
    Boolean afterUpdate = Trigger.isUpdate && Trigger.isAfter;
    Boolean afterDelete = Trigger.isDelete && Trigger.isAfter;
    Boolean afterUndelete = Trigger.isUndelete && Trigger.isAfter;
    
    if(afterInsert){
        MilestoneTriggerHandler.updateProjectStatus(Trigger.new,null);
    }
    
    if(afterUpdate){
        MilestoneTriggerHandler.updateProjectStatus(Trigger.new, Trigger.oldMap);
    }
    
    if(afterDelete){
        MilestoneTriggerHandler.updateProjectStatus(Trigger.old,null);
    }
    
    if(afterUndelete){
        MilestoneTriggerHandler.updateProjectStatus(Trigger.new,null);
    }
    
}