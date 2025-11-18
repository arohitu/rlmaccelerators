/**
 * @description Interface for ApprovalWorkItem service to enable mocking and testing
 * @author Revenue Cloud Accelerators
 * @date 2025
 */
public interface RCA_IApprovalWorkItemService {
    /**
     * @description Get ApprovalWorkItem data wrapper
     */
    RCA_ApprovalWorkItemData getApprovalWorkItemData(Id workItemId);
}

