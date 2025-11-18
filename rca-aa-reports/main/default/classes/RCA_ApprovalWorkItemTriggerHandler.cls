/**
 * @description Handler class for RCA_ApprovalWorkItemTrigger
 *              Creates junction records between ApprovalWorkItem and Quote for enhanced reporting
 *              Refactored for maximum testability (75%+ coverage requirement for packaging)
 * @author Revenue Cloud Accelerators
 * @date 2025
 */
public with sharing class RCA_ApprovalWorkItemTriggerHandler {
    
    /**
     * @description Handles after insert trigger context
     * Thin wrapper - converts to DTO and delegates to testable method
     */
    public static void handleAfterInsert(List<ApprovalWorkItem> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) return;
        List<RCA_ApprovalWorkItemData> dtoList = convertToDTO(newRecords);
        processWorkItems(dtoList, false);
    }
    
    /**
     * @description Handles after update trigger context
     * Thin wrapper - converts to DTO and delegates to testable method
     */
    public static void handleAfterUpdate(List<ApprovalWorkItem> newRecords, Map<Id, ApprovalWorkItem> oldMap) {
        if (newRecords == null || newRecords.isEmpty()) return;
        List<RCA_ApprovalWorkItemData> dtoList = convertToDTO(newRecords, oldMap);
        processWorkItems(dtoList, true);
    }
    
    /**
     * @description Converts ApprovalWorkItem records to DTOs
     * Thin conversion method
     */
    @TestVisible
    private static List<RCA_ApprovalWorkItemData> convertToDTO(List<ApprovalWorkItem> records) {
        return convertToDTO(records, null);
    }
    
    /**
     * @description Converts ApprovalWorkItem records to DTOs with change detection
     * Thin conversion method
     */
    @TestVisible
    private static List<RCA_ApprovalWorkItemData> convertToDTO(List<ApprovalWorkItem> records, Map<Id, ApprovalWorkItem> oldMap) {
        List<RCA_ApprovalWorkItemData> dtoList = new List<RCA_ApprovalWorkItemData>();
        for (ApprovalWorkItem awi : records) {
            // Only process Quote-related items
            if (awi.RelatedRecordObjectName != 'Quote' || awi.RelatedRecordId == null) continue;
            
            // For updates, only process if relevant fields changed
            if (oldMap != null && !hasRelevantChanges(awi, oldMap.get(awi.Id))) continue;
            
            RCA_ApprovalWorkItemData dto = new RCA_ApprovalWorkItemData();
            dto.workItemId = awi.Id;
            dto.relatedRecordId = awi.RelatedRecordId;
            dto.relatedRecordObjectName = awi.RelatedRecordObjectName;
            dto.status = awi.Status;
            dto.assignedToId = awi.AssignedToId;
            dto.approvalChainName = awi.ApprovalChainName;
            dtoList.add(dto);
        }
        return dtoList;
    }
    
    /**
     * @description Checks if relevant fields changed
     */
    @TestVisible
    private static Boolean hasRelevantChanges(ApprovalWorkItem newRecord, ApprovalWorkItem oldRecord) {
        if (oldRecord == null) return true;
        return newRecord.RelatedRecordId != oldRecord.RelatedRecordId ||
               newRecord.Status != oldRecord.Status ||
               newRecord.AssignedToId != oldRecord.AssignedToId ||
               newRecord.ApprovalChainName != oldRecord.ApprovalChainName;
    }
    
    /**
     * @description Main processing method - works entirely with DTOs (fully testable!)
     * This is where ALL the business logic lives
     */
    @TestVisible
    private static void processWorkItems(List<RCA_ApprovalWorkItemData> workItemDataList, Boolean isUpdate) {
        if (workItemDataList == null || workItemDataList.isEmpty()) return;
        
        // Filter for Quote-related items with valid data
        List<RCA_ApprovalWorkItemData> validItems = filterValidQuoteItems(workItemDataList);
        if (validItems.isEmpty()) return;
        
        // Get work item IDs for querying existing junctions
        Set<String> workItemIds = extractWorkItemIds(validItems);
        
        // Query existing junction records
        Map<String, RCA_ApprovalWorkItemQuote__c> existingJunctions = queryExistingJunctions(workItemIds);
        
        // Prepare records for DML
        List<RCA_ApprovalWorkItemQuote__c> toInsert = new List<RCA_ApprovalWorkItemQuote__c>();
        List<RCA_ApprovalWorkItemQuote__c> toUpdate = new List<RCA_ApprovalWorkItemQuote__c>();
        
        prepareJunctionRecords(validItems, existingJunctions, toInsert, toUpdate);
        
        // Perform DML
        performDML(toInsert, toUpdate);
    }
    
    /**
     * @description Filters for valid Quote-related items
     */
    @TestVisible
    private static List<RCA_ApprovalWorkItemData> filterValidQuoteItems(List<RCA_ApprovalWorkItemData> items) {
        List<RCA_ApprovalWorkItemData> validItems = new List<RCA_ApprovalWorkItemData>();
        for (RCA_ApprovalWorkItemData item : items) {
            if (item.relatedRecordObjectName == 'Quote' && item.relatedRecordId != null) {
                validItems.add(item);
            }
        }
        return validItems;
    }
    
    /**
     * @description Extracts work item IDs as strings
     */
    @TestVisible
    private static Set<String> extractWorkItemIds(List<RCA_ApprovalWorkItemData> items) {
        Set<String> workItemIds = new Set<String>();
        for (RCA_ApprovalWorkItemData item : items) {
            workItemIds.add(String.valueOf(item.workItemId));
        }
        return workItemIds;
    }
    
    /**
     * @description Queries existing junction records
     */
    @TestVisible
    private static Map<String, RCA_ApprovalWorkItemQuote__c> queryExistingJunctions(Set<String> workItemIds) {
        Map<String, RCA_ApprovalWorkItemQuote__c> existingJunctions = new Map<String, RCA_ApprovalWorkItemQuote__c>();
        if (workItemIds.isEmpty()) return existingJunctions;
        
        for (RCA_ApprovalWorkItemQuote__c junction : [
            SELECT Id, RCA_ApprovalWorkItemId__c, RCA_Quote__c, 
                   RCA_Status__c, RCA_AssignedToId__c, RCA_Label__c
            FROM RCA_ApprovalWorkItemQuote__c
            WHERE RCA_ApprovalWorkItemId__c IN :workItemIds
        ]) {
            existingJunctions.put(junction.RCA_ApprovalWorkItemId__c, junction);
        }
        return existingJunctions;
    }
    
    /**
     * @description Prepares junction records for insert/update
     */
    @TestVisible
    private static void prepareJunctionRecords(
        List<RCA_ApprovalWorkItemData> items,
        Map<String, RCA_ApprovalWorkItemQuote__c> existingJunctions,
        List<RCA_ApprovalWorkItemQuote__c> toInsert,
        List<RCA_ApprovalWorkItemQuote__c> toUpdate
    ) {
        for (RCA_ApprovalWorkItemData item : items) {
            String workItemIdString = String.valueOf(item.workItemId);
            
            if (existingJunctions.containsKey(workItemIdString)) {
                // Update existing - but skip Quote field (Master-Detail can't be updated)
                RCA_ApprovalWorkItemQuote__c existing = existingJunctions.get(workItemIdString);
                updateJunctionFields(existing, item);
                toUpdate.add(existing);
            } else {
                // Create new
                RCA_ApprovalWorkItemQuote__c newJunction = createJunctionRecord(item);
                toInsert.add(newJunction);
            }
        }
    }
    
    /**
     * @description Updates junction fields (excluding Master-Detail Quote field)
     */
    @TestVisible
    private static void updateJunctionFields(RCA_ApprovalWorkItemQuote__c junction, RCA_ApprovalWorkItemData item) {
        // Don't update RCA_Quote__c - Master-Detail field can't be changed
        junction.RCA_Status__c = item.status;
        junction.RCA_AssignedToId__c = item.assignedToId;
        junction.RCA_Label__c = item.approvalChainName;
    }
    
    /**
     * @description Creates a new junction record
     */
    @TestVisible
    private static RCA_ApprovalWorkItemQuote__c createJunctionRecord(RCA_ApprovalWorkItemData item) {
        return new RCA_ApprovalWorkItemQuote__c(
            RCA_ApprovalWorkItemId__c = String.valueOf(item.workItemId),
            RCA_Quote__c = item.relatedRecordId,
            RCA_Status__c = item.status,
            RCA_AssignedToId__c = item.assignedToId,
            RCA_Label__c = item.approvalChainName
        );
    }
    
    /**
     * @description Performs DML operations with error handling
     */
    @TestVisible
    private static void performDML(
        List<RCA_ApprovalWorkItemQuote__c> toInsert,
        List<RCA_ApprovalWorkItemQuote__c> toUpdate
    ) {
        try {
            if (!toInsert.isEmpty()) {
                insert toInsert;
            }
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Error in junction DML: ' + e.getMessage());
            throw e;
        }
    }
}
