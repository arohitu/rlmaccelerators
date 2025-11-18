/**
 * @description Handler class for RCA_ApprovalWorkItemTrigger
 *              Creates junction records between ApprovalWorkItem and Quote for enhanced reporting
 * @author Revenue Cloud Accelerators
 * @date 2025
 */
public with sharing class RCA_ApprovalWorkItemTriggerHandler {
    
    /**
     * @description Handles after insert trigger context
     * @param newRecords List of newly inserted ApprovalWorkItem records
     */
    public static void handleAfterInsert(List<ApprovalWorkItem> newRecords) {
        processApprovalWorkItems(newRecords, null);
    }
    
    /**
     * @description Handles after update trigger context
     * @param newRecords List of updated ApprovalWorkItem records
     * @param oldMap Map of old ApprovalWorkItem records by Id
     */
    public static void handleAfterUpdate(List<ApprovalWorkItem> newRecords, Map<Id, ApprovalWorkItem> oldMap) {
        processApprovalWorkItems(newRecords, oldMap);
    }
    
    /**
     * @description Checks if relevant fields have changed
     * @param newRecord New version of the record
     * @param oldRecord Old version of the record
     * @return Boolean indicating if relevant changes occurred
     */
    @TestVisible
    private static Boolean hasRelevantChanges(ApprovalWorkItem newRecord, ApprovalWorkItem oldRecord) {
        return newRecord.RelatedRecordId != oldRecord.RelatedRecordId ||
               newRecord.Status != oldRecord.Status ||
               newRecord.AssignedToId != oldRecord.AssignedToId ||
               newRecord.ApprovalChainName != oldRecord.ApprovalChainName;
    }
    
    /**
     * @description Main processing method to create junction records for Quote-related ApprovalWorkItems
     * @param records List of ApprovalWorkItem records to process
     * @param oldMap Map of old records (null for insert context)
     */
    @TestVisible
    private static void processApprovalWorkItems(List<ApprovalWorkItem> records, Map<Id, ApprovalWorkItem> oldMap) {
        // Filter for Quote-related ApprovalWorkItems
        List<ApprovalWorkItem> quoteWorkItems = new List<ApprovalWorkItem>();
        Set<Id> approvalWorkItemIds = new Set<Id>();
        
        for (ApprovalWorkItem awi : records) {
            // Check if RelatedRecord is a Quote
            if (awi.RelatedRecordObjectName == 'Quote' && awi.RelatedRecordId != null) {
                // For updates, process if key fields changed
                if (oldMap == null || hasRelevantChanges(awi, oldMap.get(awi.Id))) {
                    quoteWorkItems.add(awi);
                    approvalWorkItemIds.add(awi.Id);
                }
            }
        }
        
        // Exit early if no Quote-related work items
        if (quoteWorkItems.isEmpty()) {
            return;
        }
        
        // Query existing junction records to avoid duplicates
        Set<String> workItemIdStrings = new Set<String>();
        for (Id workItemId : approvalWorkItemIds) {
            workItemIdStrings.add(String.valueOf(workItemId));
        }
        
        Map<String, RCA_ApprovalWorkItemQuote__c> existingJunctions = new Map<String, RCA_ApprovalWorkItemQuote__c>();
        for (RCA_ApprovalWorkItemQuote__c junction : [
            SELECT Id, RCA_ApprovalWorkItemId__c, RCA_Quote__c
            FROM RCA_ApprovalWorkItemQuote__c
            WHERE RCA_ApprovalWorkItemId__c IN :workItemIdStrings
        ]) {
            existingJunctions.put(junction.RCA_ApprovalWorkItemId__c, junction);
        }
        
        // Prepare junction records for DML
        List<RCA_ApprovalWorkItemQuote__c> junctionsToInsert = new List<RCA_ApprovalWorkItemQuote__c>();
        List<RCA_ApprovalWorkItemQuote__c> junctionsToUpdate = new List<RCA_ApprovalWorkItemQuote__c>();
        
        for (ApprovalWorkItem awi : quoteWorkItems) {
            String workItemIdString = String.valueOf(awi.Id);
            if (existingJunctions.containsKey(workItemIdString)) {
                // Update existing junction with latest values
                RCA_ApprovalWorkItemQuote__c existingJunction = existingJunctions.get(workItemIdString);
                existingJunction.RCA_Quote__c = awi.RelatedRecordId;
                existingJunction.RCA_Status__c = awi.Status;
                existingJunction.RCA_AssignedToId__c = awi.AssignedToId;
                existingJunction.RCA_Label__c = awi.ApprovalChainName;
                junctionsToUpdate.add(existingJunction);
            } else {
                // Create new junction record with all field values
                RCA_ApprovalWorkItemQuote__c newJunction = new RCA_ApprovalWorkItemQuote__c(
                    RCA_ApprovalWorkItemId__c = workItemIdString,
                    RCA_Quote__c = awi.RelatedRecordId,
                    RCA_Status__c = awi.Status,
                    RCA_AssignedToId__c = awi.AssignedToId,
                    RCA_Label__c = awi.ApprovalChainName
                );
                junctionsToInsert.add(newJunction);
            }
        }
        
        // Perform DML operations with error handling
        try {
            if (!junctionsToInsert.isEmpty()) {
                insert junctionsToInsert;
            }
            if (!junctionsToUpdate.isEmpty()) {
                update junctionsToUpdate;
            }
        } catch (DmlException e) {
            // Log the error - in production, you might want to use a logging framework
            System.debug(LoggingLevel.ERROR, 'Error creating/updating junction records: ' + e.getMessage());
            // Re-throw to ensure visibility of the error
            throw e;
        }
    }
}

