public without sharing class PartnerActivityPointCalculation {
    @InvocableMethod(label='Assign Partner Activity Points' description='Evaluate the member and level then update their points accordingly')
    public static void AssignPartnerActivityPoints(List<Id> ActivityId) {
        List<Partner_Activity__c> activities = getActivity(ActivityId);
        if(activities != null || activities.size() > 0) {
            for(Partner_Activity__c activity : activities) {
                ChannelProgramMember member = getMember(activity.Partner_Account__c, activity.Channel_Program__c);
                
                if (member != null &&
                    Schema.sObjectType.Partner_Activity__c.fields.New_Activity__c.isUpdateable() &&
                    Schema.sObjectType.Partner_Activity__c.fields.Points_Awarded__c.isUpdateable()) {
                        // If the points awarded in an activity is not specified, search for another available point value
                        if (activity.Points_Awarded__c == null || activity.Points_Awarded__c == 0) {
                            
                            List<Program_Level_Activity_Point_Association__c> programPointAssociation = getAllProgramPointAssociations(activity.Partner_Activity_Type__c, member.LevelId); 
                            
                            // Determine whether there's a point association between the activity type and the member channel program level
                            if (programPointAssociation.size() > 0) { // If there's an association specified, use that point value
                                for(Program_Level_Activity_Point_Association__c ppa : programPointAssociation) {
                                    activity.Points_Awarded__c = ppa.Points__c;
                                }
                            }
                            else { // If there's no association specified, use the generic activity type point value
                                activity.Points_Awarded__c = activity.Partner_Activity_Type__r.Points__c;
                            }
                        }
                        // If there's a point value specified in the activity directly, use that
                        member.Total_Partner_Points__c += activity.Points_Awarded__c;
                        activity.New_Activity__c = false;
                        
                        update member;
                        update activity;
                    }
                else {
                    system.debug('User doesn\'t have access to update fields or doesn\'t belong to a Channel Program');
                }
            }
        }
        else {
            system.debug('No activities found');
        }
    }
    
    public static List<Partner_Activity__c> getActivity(List<Id> ActivityIds) {
        List<Partner_Activity__c> results = null;
        List<string> fields = new List<string> { 
            'Id',
            'Partner_Account__c',
            'New_Activity__c',
            'Partner_Activity_Type__c',
            'Channel_Program__c', 
            'Points_Awarded__c'};
        
        boolean isAccessible = FLSCheck.checkFLS(Partner_Activity__c.sObjectType.getDescribe(), fields, 'Read');
        system.debug(isAccessible);
        if (isAccessible) {
            results = [SELECT Id,
                       Partner_Account__c,
                       New_Activity__c,
                       Partner_Activity_Type__c,
                       Partner_Activity_Type__r.Points__c,
                       Channel_Program__c,
                       Points_Awarded__c
                       FROM Partner_Activity__c
                       WHERE Id IN :ActivityIds];
        }
        return results;
    }
    
    public static ChannelProgramMember getMember(Id AccountId, Id ChannelProgramId) {
        
        List<ChannelProgramMember> results = null;
        List<string> fields = new List<string> { 
            'Id',
            'LevelId',
            'Total_Partner_Points__c'};
        
        boolean isAccessible = FLSCheck.checkFLS(ChannelProgramMember.sObjectType.getDescribe(), fields, 'Read');
        if (isAccessible) {
            results = [SELECT Id,
                       LevelId,
                       Total_Partner_Points__c
                       FROM ChannelProgramMember
                       WHERE Partner.Id = :AccountId
                       AND Program.Id = :ChannelProgramId
                       LIMIT 1];
        }
        if (results.size() > 0) {
            return results[0];
        }
        else {
            return null;
        }
    }
    
    public static List<Program_Level_Activity_Point_Association__c> getAllProgramPointAssociations(Id ActivityTypeId, Id ProgramLevelId) {
        List<Program_Level_Activity_Point_Association__c> results = null;
        List<string> fields = new List<string> { 
            'Id',
            'Points__c', 
            'Channel_Program_Level__c'};
        
        boolean isAccessible = FLSCheck.checkFLS(Program_Level_Activity_Point_Association__c.sObjectType.getDescribe(), fields, 'Read');
        if (isAccessible) {
        results = [SELECT Id,
                Points__c,
                Channel_Program_Level__c
                FROM Program_Level_Activity_Point_Association__c
                WHERE Partner_Activity_Type__c = :ActivityTypeId
                AND Channel_Program_Level__c = :ProgramLevelId
               	LIMIT 1];
        }
        return results;
    }
}