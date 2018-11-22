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
                    if(members[0] != null) {
                        cmp.set("v.selectedProgramMember", members[0]);
                    }
                    if (members.length > 1) {
                        cmp.set("v.numberOfPrograms", members.length);
                    }
                } else {
                    //this.initialisePreviewChart(cmp);
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
    
    getFeaturedActivityTypes : function (cmp) {
        var member = cmp.get("v.selectedProgramMember");
        var action = cmp.get("c.getFeaturedActivityTypes");
        action.setParams({ 'levelId' : member.LevelId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var activityTypes = response.getReturnValue();
                if (activityTypes != null && activityTypes.length > 0) {
                    cmp.set("v.activityTypes", activityTypes);
                }
                else {
                    cmp.set("v.activityTypes", null);
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
    }
})