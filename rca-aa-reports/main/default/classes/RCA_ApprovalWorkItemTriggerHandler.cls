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
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }
        processApprovalWorkItems(newRecords, null);
    }
    
    /**
     * @description Handles after update trigger context
     * @param newRecords List of updated ApprovalWorkItem records
     * @param oldMap Map of old ApprovalWorkItem records by Id
     */
    public static void handleAfterUpdate(List<ApprovalWorkItem> newRecords, Map<Id, ApprovalWorkItem> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }
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
        if (oldRecord == null) {
            return true;
        }
        return newRecord.RelatedRecordId != oldRecord.RelatedRecordId ||
               newRecord.Status != oldRecord.Status ||
               newRecord.AssignedToId != oldRecord.AssignedToId ||
               newRecord.ApprovalChainName != oldRecord.ApprovalChainName;
    }
    
    /**
     * @description Filters ApprovalWorkItems to get only Quote-related items
     * @param records List of ApprovalWorkItem records
     * @param oldMap Map of old records (null for insert)
     * @return Wrapper containing filtered records and their IDs
     */
    @TestVisible
    private static ApprovalWorkItemWrapper filterQuoteRelatedItems(List<ApprovalWorkItem> records, Map<Id, ApprovalWorkItem> oldMap) {
        ApprovalWorkItemWrapper wrapper = new ApprovalWorkItemWrapper();
        wrapper.quoteWorkItems = new List<ApprovalWorkItem>();
        wrapper.approvalWorkItemIds = new Set<Id>();
        
        for (ApprovalWorkItem awi : records) {
            // Check if RelatedRecord is a Quote
            if (awi.RelatedRecordObjectName == 'Quote' && awi.RelatedRecordId != null) {
                // For updates, process if key fields changed
                if (oldMap == null || hasRelevantChanges(awi, oldMap.get(awi.Id))) {
                    wrapper.quoteWorkItems.add(awi);
                    wrapper.approvalWorkItemIds.add(awi.Id);
                }
            }
        }
        
        return wrapper;
    }
    
    /**
     * @description Queries existing junction records to avoid duplicates
     * @param approvalWorkItemIds Set of ApprovalWorkItem IDs
     * @return Map of existing junctions by ApprovalWorkItem ID string
     */
    @TestVisible
    private static Map<String, RCA_ApprovalWorkItemQuote__c> queryExistingJunctions(Set<Id> approvalWorkItemIds) {
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
        
        return existingJunctions;
    }
    
    /**
     * @description Prepares junction records for DML operations
     * @param quoteWorkItems List of Quote-related ApprovalWorkItems
     * @param existingJunctions Map of existing junctions
     * @return Wrapper containing lists of junctions to insert and update
     */
    @TestVisible
    private static JunctionRecordsWrapper prepareJunctionRecords(List<ApprovalWorkItem> quoteWorkItems, 
                                                                  Map<String, RCA_ApprovalWorkItemQuote__c> existingJunctions) {
        JunctionRecordsWrapper wrapper = new JunctionRecordsWrapper();
        wrapper.junctionsToInsert = new List<RCA_ApprovalWorkItemQuote__c>();
        wrapper.junctionsToUpdate = new List<RCA_ApprovalWorkItemQuote__c>();
        
        for (ApprovalWorkItem awi : quoteWorkItems) {
            String workItemIdString = String.valueOf(awi.Id);
            if (existingJunctions.containsKey(workItemIdString)) {
                // Update existing junction with latest values
                RCA_ApprovalWorkItemQuote__c existingJunction = existingJunctions.get(workItemIdString);
                existingJunction.RCA_Quote__c = awi.RelatedRecordId;
                existingJunction.RCA_Status__c = awi.Status;
                existingJunction.RCA_AssignedToId__c = awi.AssignedToId;
                existingJunction.RCA_Label__c = awi.ApprovalChainName;
                wrapper.junctionsToUpdate.add(existingJunction);
            } else {
                // Create new junction record with all field values
                RCA_ApprovalWorkItemQuote__c newJunction = new RCA_ApprovalWorkItemQuote__c(
                    RCA_ApprovalWorkItemId__c = workItemIdString,
                    RCA_Quote__c = awi.RelatedRecordId,
                    RCA_Status__c = awi.Status,
                    RCA_AssignedToId__c = awi.AssignedToId,
                    RCA_Label__c = awi.ApprovalChainName
                );
                wrapper.junctionsToInsert.add(newJunction);
            }
        }
        
        return wrapper;
    }
    
    /**
     * @description Performs DML operations on junction records
     * @param junctionsToInsert List of junction records to insert
     * @param junctionsToUpdate List of junction records to update
     */
    @TestVisible
    private static void performDML(List<RCA_ApprovalWorkItemQuote__c> junctionsToInsert, 
                                    List<RCA_ApprovalWorkItemQuote__c> junctionsToUpdate) {
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
    
    /**
     * @description Main processing method to create junction records for Quote-related ApprovalWorkItems
     * @param records List of ApprovalWorkItem records to process
     * @param oldMap Map of old records (null for insert context)
     */
    @TestVisible
    private static void processApprovalWorkItems(List<ApprovalWorkItem> records, Map<Id, ApprovalWorkItem> oldMap) {
        // Filter for Quote-related ApprovalWorkItems
        ApprovalWorkItemWrapper filtered = filterQuoteRelatedItems(records, oldMap);
        
        // Exit early if no Quote-related work items
        if (filtered.quoteWorkItems.isEmpty()) {
            return;
        }
        
        // Query existing junction records to avoid duplicates
        Map<String, RCA_ApprovalWorkItemQuote__c> existingJunctions = queryExistingJunctions(filtered.approvalWorkItemIds);
        
        // Prepare junction records for DML
        JunctionRecordsWrapper junctionRecords = prepareJunctionRecords(filtered.quoteWorkItems, existingJunctions);
        
        // Perform DML operations with error handling
        performDML(junctionRecords.junctionsToInsert, junctionRecords.junctionsToUpdate);
    }
    
    /**
     * @description Wrapper class for filtered ApprovalWorkItems
     */
    @TestVisible
    private class ApprovalWorkItemWrapper {
        public List<ApprovalWorkItem> quoteWorkItems;
        public Set<Id> approvalWorkItemIds;
    }
    
    /**
     * @description Wrapper class for junction records
     */
    @TestVisible
    private class JunctionRecordsWrapper {
        public List<RCA_ApprovalWorkItemQuote__c> junctionsToInsert;
        public List<RCA_ApprovalWorkItemQuote__c> junctionsToUpdate;
    }
}

