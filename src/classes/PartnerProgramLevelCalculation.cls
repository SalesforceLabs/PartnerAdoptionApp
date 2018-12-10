public without sharing class PartnerProgramLevelCalculation {
	@InvocableMethod(label='Update Partner Program Level' description='Evaluate the points and activities of channel program members and update their program level information correspondingly')
    public static void UpdatePartnerProgramLevel(List<Id> MemberId) {
        checkProgramLevel(MemberId); // Calls future method to finish the DML of Partner Activity creation before querying activities
    }
    
    @future
    static void checkProgramLevel(List<Id> MemberId) {
        List<ChannelProgramMember> members = getAllMembers(MemberId);
        List<ChannelProgramMember> membersToBeUpdated = new List<ChannelProgramMember>();
        
        for(ChannelProgramMember member : members) {
            List<ChannelProgramLevel> programLevels = getAllProgramLevels(member.ProgramId);
            Map<Id, Integer> pointsInEachType = getPointTypeMap(member.PartnerId, member.ProgramId);
            ChannelProgramLevel newLevel = getNewLevel(member, pointsInEachType, programLevels);
            system.debug(newLevel);
            if (newLevel != null && newLevel.Id != member.LevelId) {
                if (newLevel.Minimum_Points__c > member.Level.Minimum_Points__c || member.LevelId == null) {
                    // leveling up
                    member.Pending_Level__c = null;
                    member.LevelId = newLevel.Id;
                } else {
                    // level down
                    member.Pending_Level__c = newLevel.Id;
                }
                membersToBeUpdated.add(member);
            } else {
                if (member.Pending_Level__c != null) {
                    member.Pending_Level__c = null;
                    membersToBeUpdated.add(member);
                }
            }
        }
        update membersToBeUpdated;
    }
    
    public static List<ChannelProgramMember> getAllMembers(List<Id> MemberId) {
        List<ChannelProgramMember> results = new List<ChannelProgramMember>();
        
        List<string> fields = new List<string> { 
            'Id',
            'LevelId',
            'Total_Partner_Points__c',
            'ProgramId',
            'PartnerId', 
            'Pending_Level__c'};
                
        boolean isAccessible = FLSCheck.checkFLS(ChannelProgramMember.sObjectType.getDescribe(), fields, 'Read');
        if (isAccessible) {
            results = [SELECT Id,
                       LevelId,
                       Total_Partner_Points__c,
                       Level.Next_Level__c,
                       Level.Minimum_Points__c,
                       ProgramId,
                       PartnerId,
                       Pending_Level__c
                       FROM ChannelProgramMember
                       WHERE Id IN :MemberId];
        }
        return results;
    }
    
    public static List<ChannelProgramLevel> getAllProgramLevels(Id ProgramId) {
        List<ChannelProgramLevel> results = new List<ChannelProgramLevel>();
        
        List<string> fields = new List<string> { 
            'Minimum_Points__c'};
                
        boolean isAccessible = FLSCheck.checkFLS(ChannelProgramLevel.sObjectType.getDescribe(), fields, 'Read');
        if (isAccessible) {
        results = [SELECT Id,
                Minimum_Points__c,
                (
                    SELECT
                    Partner_Activity_Type__c,
                    Minimum_Point_Requirement__c
                    FROM
                    Partner_Level_Requirements__r
                )
                FROM ChannelProgramLevel
                WHERE ProgramId = :ProgramId
                ORDER BY Minimum_Points__c DESC];
        }
        
        return results;
    }
    
    public static Map<Id, Integer> getPointTypeMap(Id AccountId, Id ProgramId) {
        List<Partner_Activity__c> activities = getActivities(AccountId, ProgramId);
        
        Map<Id, Integer> pointsInEachType = new Map<Id, Integer>();
        
        for (Partner_Activity__c activity : activities) {
            if (!pointsInEachType.containsKey(activity.Partner_Activity_Type__c)) {
                pointsInEachType.put(activity.Partner_Activity_Type__c, 0);
            }
            Integer newValue = pointsInEachType.get(activity.Partner_Activity_Type__c);
            pointsInEachType.put(activity.Partner_Activity_Type__c, newValue + Integer.valueof(activity.Points_Awarded__c));
        }
        return pointsInEachType;
    }
    
    public static List<Partner_Activity__c> getActivities(Id AccountId, Id ProgramId) {
        List<Partner_Activity__c> results = new List<Partner_Activity__c>();
        
        List<string> fields = new List<string> { 
            'Id',
            'Activity_Date__c',
            'Points_Awarded__c',
            'Partner_Activity_Type__c'};
                
        boolean isAccessible = FLSCheck.checkFLS(Partner_Activity__c.sObjectType.getDescribe(), fields, 'Read');
        if (isAccessible) {
        results = [SELECT Id,
                Activity_Date__c,
                Points_Awarded__c,
                Partner_Activity_Type__c,
                Partner_Activity_Type__r.Name,
                Partner_Activity_Type__r.Category_Icon_URL__c
                FROM Partner_Activity__c
                WHERE Partner_Account__c = :AccountId
                AND Channel_Program__c = :ProgramId
                ORDER BY Activity_Date__c DESC, CreatedDate DESC];
        }
        return results;
    }
    
    public static ChannelProgramLevel getNewLevel(ChannelProgramMember member, Map<Id, Integer> pointsInEachType, List<ChannelProgramLevel> programLevels) {
        boolean nextLevelOrBelow = false; // Used to ensure that the partner cannot skip levels if they fulfil the above requirements before current requirement
        integer levels = 0;
        
        for (ChannelProgramLevel level : programLevels) {
            levels++;
            
            if ((member.Level.Next_Level__c == level.Id && nextLevelOrBelow == false) || member.Level.Next_Level__c == null)  {
                nextLevelOrBelow = true;
            }
            
            if(nextLevelOrBelow == true) {
                if (member.Total_Partner_Points__c < level.Minimum_Points__c) {
                    continue;
                }
                
                boolean requirementsFulfilled = true;
                // check if fulfill each requirement, including for lower levels which allows for downgrading when points decrease
                for (Partner_Level_Requirement__c requirement : level.Partner_Level_Requirements__r) {
                    
                    system.debug('Current Points: ' + pointsInEachType.get(requirement.Partner_Activity_Type__c));
                    system.debug('Points Requirement: ' + requirement.Minimum_Point_Requirement__c);
                    system.debug(programLevels.size());
                    system.debug(levels);
                    
                    if (!pointsInEachType.containsKey(requirement.Partner_Activity_Type__c) ||
                        pointsInEachType.get(requirement.Partner_Activity_Type__c) < requirement.Minimum_Point_Requirement__c ) {
                            requirementsFulfilled = false;
                            break;
                        }
                }
                if (requirementsFulfilled || (member.LevelId != level.Id && programLevels.size() == levels)) {
                    return level;
                }
            }
        }
        return null;
    }
}