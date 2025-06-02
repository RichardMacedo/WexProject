public class MilestoneTriggerHandler {
    
    public static void updateProjectStatus(List<Milestone__c> listMilestones, Map<Id,Milestone__c> oldMap){
        List<Milestone__c> listMilestonesToCheck = new List<Milestone__c>();
        List<Project__c> listProjectsToUpdate = new List<Project__c>();
        Set<String> setIdsProjects = new Set<String>();
        Set<String> setIdsMilestonesDisconsider = new Set<String>();
        Boolean hasCompleted = false;
        Boolean hasStarted = false;
        Boolean hasNotInitiated = false;
        Project__c projectToUpdate = new Project__c();
        
        for(Milestone__c milestone : listMilestones){
            //Check the milestone only if the status was changed, or the milestone is new, or the milestone was deleted or the milestone was undeleted
            if(oldMap == null || milestone.Status__c != oldMap.get(milestone.id).Status__c){
                listMilestonesToCheck.add(milestone);
                setIdsProjects.add(milestone.Project__c);
                if(Trigger.isDelete) setIdsMilestonesDisconsider.add(milestone.id);
            }
        }
        
        if(listMilestonesToCheck.size() > 0){
            for(Project__c project : [SELECT Id, Status__c, (SELECT Id, Status__c FROM Milestones__r WHERE Id NOT IN :setIdsMilestonesDisconsider) FROM Project__c WHERE Id IN :setIdsProjects WITH SECURITY_ENFORCED]){
                hasCompleted = false;
                hasStarted = false;
                hasNotInitiated = false;
                projectToUpdate = new Project__c(id = project.id);
                
                for(Milestone__c milestone : project.Milestones__r){
                    if(milestone.Status__c == 'Complete') hasCompleted = true;
                    else if(milestone.Status__c == 'In Progress') hasStarted = true;
                    else hasNotInitiated = true;
                }
                
                if(hasCompleted && !hasStarted && !hasNotInitiated) projectToUpdate.Status__c = 'Complete';
                else if(hasStarted || hasCompleted) projectToUpdate.Status__c = 'In Progress';
                else projectToUpdate.Status__c = 'Not Started	';
                
                //There is no need to update the Project if the Status is still correct
                if(project.Status__c != projectToUpdate.Status__c) listProjectsToUpdate.add(projectToUpdate);
            }
            
            if(listProjectsToUpdate.size() > 0) UPDATE as USER listProjectsToUpdate;
        }
    }
    
}