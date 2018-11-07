/*
    Author:         Derrick Vuong
    Company:        Salesforce
    Description:    PartnerTierCurrentLevel.cmp
    Date:           2-Nov-2018
*/
({
    doInit : function(cmp, event, helper) {
        var action = cmp.get("c.getPartnerMembers");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var members = response.getReturnValue();
                if (members != null) {
                    cmp.set("v.availableProgramMembers", members);
                    if (members[0] != null) {
                        cmp.set("v.selectedProgramMember", members[0]);
                        if (members[0].level !== null) {
                            cmp.set("v.levelIcon", members[0].Level.DV_PAA__Icon_URL__c);
                        }
                    }
                    if (members.length > 1) {
                        cmp.set("v.numberOfPrograms", members.length);
                    }
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
    
    handleProgramPicker : function(cmp, event) {
        cmp.set("v.selectedProgramMember", event.getParam("selectedProgramMember"));
        cmp.set("v.levelIcon", event.getParam("levelIcon"));
    }
})