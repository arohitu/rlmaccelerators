/**
 * @description Trigger on ApprovalWorkItem object to manage junction records with Quote
 * @author Revenue Cloud Accelerators
 * @date 2025
 */
trigger RCA_ApprovalWorkItemTrigger on ApprovalWorkItem (after insert, after update) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            RCA_ApprovalWorkItemTriggerHandler.handleAfterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            RCA_ApprovalWorkItemTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}

