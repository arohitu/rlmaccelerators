/**
 * @description Data transfer object for ApprovalWorkItem fields
 *              Used to simulate ApprovalWorkItem records in tests
 * @author Revenue Cloud Accelerators
 * @date 2025
 */
public class RCA_ApprovalWorkItemData {
    public Id workItemId { get; set; }
    public Id relatedRecordId { get; set; }
    public String relatedRecordObjectName { get; set; }
    public String status { get; set; }
    public String assignedToId { get; set; }
    public String approvalChainName { get; set; }
    
    public RCA_ApprovalWorkItemData() {
        // Default constructor
    }
    
    public RCA_ApprovalWorkItemData(Id workItemId, Id relatedRecordId, String relatedRecordObjectName,
                                   String status, String assignedToId, String approvalChainName) {
        this.workItemId = workItemId;
        this.relatedRecordId = relatedRecordId;
        this.relatedRecordObjectName = relatedRecordObjectName;
        this.status = status;
        this.assignedToId = assignedToId;
        this.approvalChainName = approvalChainName;
    }
}

