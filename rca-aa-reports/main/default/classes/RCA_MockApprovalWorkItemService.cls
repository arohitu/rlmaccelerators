/**
 * @description Mock implementation of ApprovalWorkItem service for testing
 * @author Revenue Cloud Accelerators
 * @date 2025
 */
@isTest
public class RCA_MockApprovalWorkItemService implements RCA_IApprovalWorkItemService {
    
    private Map<Id, RCA_ApprovalWorkItemData> mockData;
    
    public RCA_MockApprovalWorkItemService() {
        this.mockData = new Map<Id, RCA_ApprovalWorkItemData>();
    }
    
    /**
     * @description Add mock data for testing
     */
    public void addMockData(RCA_ApprovalWorkItemData data) {
        mockData.put(data.workItemId, data);
    }
    
    /**
     * @description Get mock approval work item data
     */
    public RCA_ApprovalWorkItemData getApprovalWorkItemData(Id workItemId) {
        return mockData.get(workItemId);
    }
    
    /**
     * @description Create a mock ApprovalWorkItem data for testing
     */
    public static RCA_ApprovalWorkItemData createMockData(
        String workItemIdSuffix, 
        Id quoteId, 
        String status,
        String assignedToId,
        String approvalChainName
    ) {
        // Generate a fake but valid-looking 18-char ID for ApprovalWorkItem
        String fakeWorkItemId = '04gd20000000' + workItemIdSuffix.leftPad(6, '0');
        
        return new RCA_ApprovalWorkItemData(
            (Id)fakeWorkItemId,
            quoteId,
            'Quote',
            status,
            assignedToId,
            approvalChainName
        );
    }
}

