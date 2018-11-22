/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
({
    getAvailableProgramMembers : function(cmp) {
        var action = cmp.get("c.getPartnerMembers");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var members = response.getReturnValue();
                if (members !== null) {
                    cmp.set("v.availableProgramMembers", members);
                    if (members[0] != null) {
                        cmp.set("v.selectedProgramMember", members[0]);
                    }
                    if (members.length > 1) {
                        cmp.set("v.numberOfPrograms", members.length);
                    }
                } else {
                    this.initialisePreviewChart(cmp);
                }
            }
            else if (state === "INCOMPLETE") {
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    },
    retrievePartnerMemberActivityMap : function (cmp) {
        var member = cmp.get("v.selectedProgramMember");
        var action = cmp.get("c.getMemberPointsByType");
        action.setParams({ 'memberId' : member.Id});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var activityTypeMap = response.getReturnValue();
                if (activityTypeMap !== null) {
                    cmp.set("v.activityTypeMap", activityTypeMap);
                    this.assignStatusToRequirements(cmp);
                }
            }
            else if (state === "INCOMPLETE") {
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    },
    initialiseProgressChart : function (cmp, member) {
        var progressMsg = "";
        var colour =  cmp.get("v.chartColour");// '#0097E1';
        
        if (member.Level.DV_PAA__Next_Level__c != null) {
            var percentage = 0;
            var requirements = cmp.get("v.requirements");
            var nextLevelMinimumPoints = member.Level.DV_PAA__Next_Level__r.DV_PAA__Minimum_Points__c; //member.Points_to_Next_Level__c + member.Total_Partner_Points__c;
            var maximumStandardPoints = member.Level.DV_PAA__Next_Level__r.DV_PAA__Minimum_Points__c; // Calculates points requirement to next level
            var remainingPointsRequirement = 0; // Calculates how many points are missing from requirements to next level
            
            /* A delay is required for the JSON to load the extra keys '.Fulfilled' and '.CurrentPoints'
             * Using anything less than 1500ms appears to still have a chance of it being undefined
             * If there are user errors with the progress chart, increase the delay
             */
            setTimeout(function() {
                requirements.forEach(function(requirement) {
                    maximumStandardPoints -= requirement.DV_PAA__Minimum_Point_Requirement__c;
                    if (requirement.CurrentPoints > requirement.DV_PAA__Minimum_Point_Requirement__c) {
                        remainingPointsRequirement += requirement.DV_PAA__Minimum_Point_Requirement__c;
                    }
                    else {
                        remainingPointsRequirement += requirement.CurrentPoints;
                    }
                });
                
                if((member.DV_PAA__Total_Partner_Points__c - remainingPointsRequirement) >= maximumStandardPoints) {
                    remainingPointsRequirement += maximumStandardPoints; // Calculate how many points earned
                }
                else { // If total points less than max standard pts just display the points 
                    remainingPointsRequirement = member.DV_PAA__Total_Partner_Points__c;
                }
                
                percentage = remainingPointsRequirement / nextLevelMinimumPoints; // Get the percantage to show before actual remaining pts is calc'd
                remainingPointsRequirement = nextLevelMinimumPoints - remainingPointsRequirement; // Remaining points = points earned - required points
                
                progressMsg = '<p class="slds-text-heading--large chart-number" title="' + remainingPointsRequirement + '">' + remainingPointsRequirement + '</p>' +
                    '<p class="slds-text-heading--label" title="To ' + member.Level.DV_PAA__Next_Level__r.Name + '">to ' + member.Level.DV_PAA__Next_Level__r.Name + '</p>';
                
                $('#circle').circleProgress({
                    value: percentage,
                    size: 150,
                    thickness: 10,
                    fill: { color: colour },
                    startAngle: Math.PI * 1.5
                }).on('circle-animation-progress', function(event, progress) {
                    
                    $(this).find('strong').html(progressMsg);
                    
                });
            }, 1500);
        }
        else {
            progressMsg = '<p class="slds-text-heading--large chart-number">' + member.DV_PAA__Total_Partner_Points__c + '</p>' +
                '<p class="slds-text-heading--label">' + member.Level.Name + '</p>';
            percentage = 1;
            
            $('#circle').circleProgress({
                value: percentage,
                size: 150,
                thickness: 10,
                fill: { color: colour },
                startAngle: Math.PI * 1.5
            }).on('circle-animation-progress', function(event, progress) {
                
                $(this).find('strong').html(progressMsg);
                
            });
        }
    },
    retrieveLevelRequirements : function (cmp, levelId, callback) {
        var action = cmp.get("c.getLevelRequirements");
        action.setParams({ 
            'levelId' : levelId
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var requirements = response.getReturnValue();
                //console.log(requirements);
                
                cmp.set("v.requirements", requirements);
                
                
                this.retrievePartnerMemberActivityMap(cmp);
                callback();
            }
            else if (state === "INCOMPLETE") {
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    },
    assignStatusToRequirements : function(cmp) {
        var requirements = cmp.get("v.requirements");
        var map = cmp.get("v.activityTypeMap");
        requirements.forEach(function(requirement) {
            var points = map[requirement.DV_PAA__Partner_Activity_Type__c];
            if (points == null) {
                points = 0;
            }
            requirement.CurrentPoints = points;
            requirement.Fulfilled = false;
            if (points >= requirement.DV_PAA__Minimum_Point_Requirement__c) {
                requirement.Fulfilled = true;
            }
        });
        cmp.set("v.requirements", requirements);
    },
    initialisePreviewChart : function (cmp) {
        //initialise chart for preview
        var colour =  cmp.get("v.chartColour");// '#0097E1';

        $('#circle').circleProgress({
            value: 0.8,
            size: 150,
            thickness: 10,
            fill: { color: colour },
            startAngle: Math.PI * 1.5
        }).on('circle-animation-progress', function(event, progress) {
            $(this).find('strong').html('<p class="slds-text-heading--large chart-number">' + 20 + '</p>' +
                '<p class="slds-text-heading--label">to Level</p>');
        });
    },
})