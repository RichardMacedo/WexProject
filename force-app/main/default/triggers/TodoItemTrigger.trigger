trigger TodoItemTrigger on TodoItem__c (after insert, after update, after delete, after undelete) {
    
    Boolean afterInsert = Trigger.isInsert && Trigger.isAfter;
    Boolean afterUpdate = Trigger.isUpdate && Trigger.isAfter;
    Boolean afterDelete = Trigger.isDelete && Trigger.isAfter;
    Boolean afterUndelete = Trigger.isUndelete && Trigger.isAfter;
    
    if(afterInsert){
        TodoItemTriggerHandler.updateMilestoneStatus(Trigger.new,null);
    }
    
    if(afterUpdate){
        TodoItemTriggerHandler.updateMilestoneStatus(Trigger.new, Trigger.oldMap);
    }
    
    if(afterDelete){
        TodoItemTriggerHandler.updateMilestoneStatus(Trigger.old,null);
    }
    
    if(afterUndelete){
        TodoItemTriggerHandler.updateMilestoneStatus(Trigger.new,null);
    }

}