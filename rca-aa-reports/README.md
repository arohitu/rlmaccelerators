# RCA Advanced Approval Reports Package

## Overview

This package provides enhanced reporting capabilities for Salesforce Revenue Cloud Advanced Approvals by creating a bridge between `ApprovalWorkItem` and `Quote` records.

## Problem Statement

Salesforce does not allow Quote fields (such as Quote Number, Quote Name, Status, Amount, etc.) to be included in ApprovalWorkItem reports due to the polymorphic nature of the `RelatedRecordId` field. This field is not a true lookup/master-detail relationship, making it non-reportable.

## Solution

This package introduces a custom junction object `RCA_ApprovalWorkItemQuote__c` that:
- Stores the **ApprovalWorkItem ID** as an External ID text field (workaround for platform limitation on direct lookups)
- Has a **Master-Detail relationship to Quote** for enhanced security and cascade deletion
- Automatically creates/updates records via the `RCA_ApprovalWorkItemTrigger` trigger

**Note:** Due to Salesforce platform limitations, `ApprovalWorkItem` cannot be used as a lookup target. Instead, we store the 18-character ID as an external ID for reference.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Approval Process Flow                        │
└─────────────────────────────────────────────────────────────────┘
                                ↓
                    ┌────────────────────────┐
                    │   ApprovalWorkItem     │ (Platform Object)
                    │  RelatedRecordId: Quote│
                    └───────────┬────────────┘
                                │
                    ┌───────────▼────────────┐
                    │  RCA_ApprovalWorkItem  │ (Trigger)
                    │        Trigger         │
                    └───────────┬────────────┘
                                │
                    ┌───────────▼────────────┐
                    │  RCA_ApprovalWorkItem  │ (Handler)
                    │   TriggerHandler.cls   │
                    └───────────┬────────────┘
                                │
                                │ Creates/Updates
                                ↓
        ┌───────────────────────────────────────────┐
        │   RCA_ApprovalWorkItemQuote__c            │ (Junction Object)
        │   ┌──────────────────────────────────┐    │
        │   │ RCA_ApprovalWorkItemId__c (Text) │    │
        │   │ RCA_Quote__c (Master-Detail) ────┼────┼──→  Quote
        │   │ RCA_Status__c                    │    │
        │   │ RCA_AssignedToId__c              │    │
        │   │ RCA_Label__c                     │    │
        │   └──────────────────────────────────┘    │
        └─────────────────┬─────────────────────────┘
                          │
                          │ Enables Reporting
                          ↓
        ┌──────────────────────────────────────────┐
        │  Custom Report Type:                     │
        │  "Quote with Approval Work Items"        │
        │                                          │
        │  Fields Available:                       │
        │  • All Quote fields (Name, Number, etc.) │
        │  • Junction fields (Status, Assignee)    │
        │  • Related Opportunity, Account fields   │
        └──────────────────────────────────────────┘
```

### Data Flow Example

1. **Approval Submission:** User submits a Quote for approval
2. **Platform Creates Record:** Salesforce creates an `ApprovalWorkItem` with `RelatedRecordId` pointing to the Quote
3. **Trigger Fires:** `RCA_ApprovalWorkItemTrigger` executes in `after insert` context
4. **Handler Processes:** Handler validates `RelatedRecordObjectName = 'Quote'` and extracts key fields
5. **Junction Record Created:** A new `RCA_ApprovalWorkItemQuote__c` record is inserted with:
   - `RCA_ApprovalWorkItemId__c` = ApprovalWorkItem.Id (as text)
   - `RCA_Quote__c` = ApprovalWorkItem.RelatedRecordId (Master-Detail)
   - `RCA_Status__c` = ApprovalWorkItem.Status
   - `RCA_AssignedToId__c` = ApprovalWorkItem.AssignedToId (as text)
   - `RCA_Label__c` = ApprovalWorkItem.ApprovalChainName
6. **Reporting Enabled:** Users can now create reports joining Quote and approval data

## Components

### Custom Objects

Note: Key fields from ApprovalWorkItem are copied to the junction object for enhanced reporting without needing to query through the lookup relationship.

#### RCA_ApprovalWorkItemQuote__c
Junction object with the following fields:
- **Name** - Auto-number field (AWIQ-{00000})
- **RCA_ApprovalWorkItemId__c** - Required external ID text field (18 chars) storing ApprovalWorkItem ID
- **RCA_Quote__c** - Master-Detail relationship to Quote (controls sharing and cascade delete)
- **RCA_Status__c** - Picklist (Assigned, Approved, Canceled, Errored, Recalled, Rejected, Withdrawn)
- **RCA_AssignedToId__c** - Text field (18 chars) storing User/Group ID of assigned approver
- **RCA_Label__c** - Text field (255 chars) storing Approval Chain Name

### Triggers

#### RCA_ApprovalWorkItemTrigger
- Fires on `after insert` and `after update` of ApprovalWorkItem
- Only processes ApprovalWorkItems where `RelatedRecordObjectName = 'Quote'`
- Automatically creates/updates junction records when:
  - A new ApprovalWorkItem is created with a Quote as the RelatedRecordId
  - An existing ApprovalWorkItem's Status, AssignedToId, or ApprovalChainName changes
- Uses upsert logic based on the external ID to prevent duplicates

### Custom Report Types

#### RCA_QuotewithApprovalWorkItems
Custom report type that enables reporting on:
- Primary object: RCA_ApprovalWorkItemQuote__c
- Related object: Quote (via Master-Detail relationship)
- Label: "Quote with Approval Work Items"
- Category: Other Reports
- Provides access to Quote fields (Name, Number, Status, Grand Total, Opportunity, Owner, etc.)
- Provides access to junction object fields (Status, Assigned To ID, Approval Chain Name)

**Usage:** Navigate to Reports → New Report → select "Quote with Approval Work Items" report type.

### Report Folder

#### RCA_ApprovalReports
A dedicated report folder is created for organizing approval-related reports. Share this folder with users who need access to approval reports.

**Note:** Sample reports are not included in the package. Use the custom report type to build reports tailored to your business requirements.

### Permission Set

#### RCA_ApprovalReportViewer
A permission set providing read-only access for reporting purposes:
- **Object Access:**
  - Read access to RCA_ApprovalWorkItemQuote__c
  - Read access to ApprovalWorkItem
  - Read access to Quote, Opportunity, and Account (required for Master-Detail chain)
- **Field Access:**
  - Read access to RCA_Status__c
  - Read access to RCA_AssignedToId__c  
  - Read access to RCA_Label__c
  - Required fields (RCA_ApprovalWorkItemId__c, RCA_Quote__c) are accessible by default

**Usage:** Assign this permission set to users who need to create and view approval reports but don't need edit access.

### Apex Classes

#### RCA_ApprovalWorkItemTriggerHandler
Handler class containing the business logic:
- Filters for Quote-related ApprovalWorkItems
- Copies field values from ApprovalWorkItem to junction object
- Prevents duplicate junction records
- Updates junction records when approval status changes
- Handles bulk operations efficiently
- Includes error handling and logging

#### RCA_ApprovalWorkItemTriggerHandler_Test
Comprehensive test class providing coverage for:
- Insert scenarios
- Update scenarios
- Bulk operations
- Non-Quote record filtering
- Error handling

## Reporting Benefits

After installing this package, users can:

1. **Create custom reports** - Use the custom report type "Quote with Approval Work Items"
2. **Access Quote fields** - Include Quote Number, Name, Status, Amount, Account, Opportunity, etc.
3. **Access Approval fields** - Status, Assigned To, and Approval Chain Name stored directly on junction object
4. **Cross-object reporting** - Join to Account, Opportunity, Product, and other objects through the Quote relationship
5. **Build comprehensive dashboards** - Create approval metrics with full Quote context
6. **No lookup traversal required** - Key fields copied to junction object for better report performance
7. **Historical tracking** - Junction records persist even after approval completion for historical reporting

### Real-World Use Cases

- **Sales Operations:** Track average approval times per region or product line
- **Management:** Monitor pending approvals by executive and proactively address bottlenecks
- **Finance:** Audit trail for approved discounts and special pricing
- **Revenue Analytics:** Correlate approval patterns with win rates and deal velocity
- **Capacity Planning:** Identify approvers with heavy workloads for resource allocation

## Sample Report Examples

### Example 1: Pending Approvals by Quote
**Report Type:** RCA_ApprovalWorkItemQuote__c
**Fields:**
- ApprovalWorkItem: Name, Status, Assigned To, Created Date
- Quote: Quote Number, Name, Status, Grand Total, Account

**Filters:**
- ApprovalWorkItem Status equals "Assigned"

### Example 2: Approval History with Quote Details
**Report Type:** RCA_ApprovalWorkItemQuote__c
**Fields:**
- ApprovalWorkItem: Name, Status, Reviewed By, Reviewed Date, Comments
- Quote: Quote Number, Name, Opportunity Name, Account Name
- Group by: Reviewed By

### Example 3: Approval Turnaround Time
**Report Type:** RCA_ApprovalWorkItemQuote__c
**Fields:**
- ApprovalWorkItem: Created Date, Reviewed Date
- Quote: Quote Number, Account Name
- Formula: Reviewed Date - Created Date (hours)

## Installation

### Prerequisites
- Salesforce Revenue Cloud with Advanced Approvals enabled
- System Administrator or equivalent access

### Option 1: Package Installation (Recommended)

Install the managed package using the installation URL:

**Latest Version:** 1.0.0-1  
**Installation URLs:**
- **Production:** https://login.salesforce.com/packaging/installPackage.apexp?p0=04td2000000AeKLAA0
- **Sandbox:** https://test.salesforce.com/packaging/installPackage.apexp?p0=04td2000000AeKLAA0

**Installation Steps:**
1. Click the appropriate installation URL for your org type (Production or Sandbox)
2. Log in to your target org
3. Select "Install for All Users" (recommended) or choose specific profiles
4. Click "Install"
5. Approve security access for the package components
6. Wait for installation to complete (2-5 minutes)

### Option 2: Source Deployment (Development)

For developers working with the source code:

```bash
# Deploy the entire package
sf project deploy start -d rca-aa-reports -o <your-org-alias>
```

### Post-Installation Steps

1. **Assign Permission Set:**
   - Navigate to Setup → Users → Permission Sets
   - Open "Approval Report Viewer" (RCA_ApprovalReportViewer)
   - Click "Manage Assignments" and assign to users who need reporting access

2. **Verify Installation:**
   - Navigate to Setup → Objects and Fields → Object Manager
   - Find "Approval Work Item Quote" (RCA_ApprovalWorkItemQuote__c)
   - Verify fields: RCA_ApprovalWorkItemId__c, RCA_Quote__c, RCA_Status__c, etc.
   - Navigate to Setup → Reports → Report Types
   - Verify "Quote with Approval Work Items" report type exists

3. **Test the Automation:**
   - Create a Quote that meets approval criteria
   - Submit the Quote for approval (via your approval process)
   - Query junction records to verify creation:
     ```sql
     SELECT Id, Name, RCA_ApprovalWorkItemId__c, RCA_Quote__c, 
            RCA_Status__c, RCA_AssignedToId__c, RCA_Label__c
     FROM RCA_ApprovalWorkItemQuote__c 
     WHERE RCA_Quote__c = '<Your-Quote-Id>'
     ORDER BY CreatedDate DESC
     ```

4. **Create Your First Report:**
   - Navigate to Reports → New Report
   - Search for "Quote with Approval Work Items"
   - Add desired fields from both Quote and Approval Work Item Quote objects
   - Save the report in the "RCA Approval Reports" folder

## Testing

The package includes comprehensive test coverage:
- Test class: `RCA_ApprovalWorkItemTriggerHandler_Test`
- Coverage: Bulk operations, error handling, filtering logic

**Note:** Full integration testing requires actual approval submission processes, as ApprovalWorkItem records cannot be directly created via Apex. The test class includes documentation for integration testing procedures.

## Technical Notes

### ApprovalWorkItem Limitations
- **ApprovalWorkItem** is a platform-managed object
- Cannot be directly inserted, updated, or deleted via Apex
- Cannot be used as a lookup target (platform restriction)
- Records are created automatically by the platform during approval processes
- The trigger activates when the platform creates/updates these records

### Platform Workaround: External ID Pattern
Due to the inability to create a lookup to ApprovalWorkItem:
- We store the ApprovalWorkItem ID as text in `RCA_ApprovalWorkItemId__c`
- This field is marked as External ID and Unique
- Enables upsert operations to prevent duplicates
- Provides reference for custom reports and queries

### Master-Detail Benefits
The Master-Detail relationship to Quote provides:
- **Cascade Delete:** Junction records are automatically deleted when Quote is deleted
- **Security Inheritance:** Junction records inherit sharing settings from parent Quote
- **Roll-up Summary Potential:** Can create roll-up summary fields on Quote if needed
- **Report Performance:** More efficient report queries through the direct relationship

### Bulk Processing
- The handler is optimized for bulk operations
- Processes up to 200 records per transaction efficiently
- Uses SOQL queries and DML operations within governor limits

### Error Handling
- DML errors are logged and re-thrown for visibility
- Duplicate prevention logic avoids creating redundant junction records
- Update logic handles changes to the RelatedRecordId field

## Troubleshooting

### Junction Records Not Created

**Symptom:** ApprovalWorkItems exist but junction records are missing.

**Possible Causes:**
1. The trigger is not active
2. The RelatedRecordId is not a Quote
3. DML errors during record creation

**Solutions:**
- Verify trigger is active: Setup → Apex Triggers → RCA_ApprovalWorkItemTrigger
- Check Debug Logs for DML errors
- Query ApprovalWorkItems: `SELECT Id, RelatedRecordObjectName FROM ApprovalWorkItem WHERE RelatedRecordId = '<Quote-Id>'`
- Ensure the Quote record exists and user has access

### Reports Showing No Data

**Symptom:** Custom report type exists but reports return no records.

**Possible Causes:**
1. No junction records have been created yet
2. Incorrect report filters
3. User lacks permission to view records

**Solutions:**
- Verify junction records exist: `SELECT COUNT() FROM RCA_ApprovalWorkItemQuote__c`
- Check sharing settings and permission set assignments
- Ensure ApprovalWorkItems have been created for Quotes (submit a Quote for approval)
- Review report filters - remove all filters initially to see if data appears

### Permission Errors

**Symptom:** Users cannot create reports or see junction records.

**Solutions:**
- Assign the "Approval Report Viewer" permission set
- Grant user access to the RCA_ApprovalReports folder
- Ensure user has "Create and Customize Reports" permission
- For custom report creation, ensure access to the report type

## Frequently Asked Questions (FAQ)

**Q: Why not use a direct lookup to ApprovalWorkItem?**  
A: Salesforce platform restrictions prevent ApprovalWorkItem from being used as a lookup target. We use an External ID text field as a workaround.

**Q: What happens to junction records when a Quote is deleted?**  
A: Junction records are automatically cascade-deleted due to the Master-Detail relationship.

**Q: Can I add more fields to the junction object?**  
A: Yes, but this requires extending the Apex handler to populate those fields. Consider whether you truly need to copy the field vs. reporting directly from the related objects.

**Q: Why are some fields stored as text (IDs) instead of lookups?**  
A: Platform limitations prevent lookups to ApprovalWorkItem and User/Group polymorphic relationships. Text fields provide a reference while maintaining package compatibility.

**Q: How do I report on approver names instead of IDs?**  
A: Use a formula field on the junction object that performs a TEXT() conversion of the RCA_AssignedToId__c field, or create a custom Apex class to populate a text field with the assignee name.

**Q: Will this work with approval processes on objects other than Quote?**  
A: No, this package is specifically designed for Quote approvals. The trigger filters for `RelatedRecordObjectName = 'Quote'`. You would need to create separate junction objects for other object types.

**Q: Does this impact approval process performance?**  
A: Minimal impact. The trigger executes asynchronously after the approval platform processes complete. Bulk operations are optimized for governor limits.

**Q: Can I modify the trigger logic?**  
A: For managed package installations, you cannot directly modify the code. For source deployments, yes - but ensure you maintain test coverage and bulk-safe patterns.

## Support and Contributions

For issues, questions, or contributions, please refer to the main project repository.

## License

This package is licensed under the MIT License.  
See the main project [LICENSE](../LICENSE) file for full details.

## Version History

### v1.0.0-1 (Winter '26) - Initial Release
**Release Date:** November 18, 2025  
**Package ID:** 0Hod20000000Td7CAE  
**Subscriber Package Version ID:** 04td2000000AeKLAA0

**What's Included:**
- Custom junction object: RCA_ApprovalWorkItemQuote__c with 5 custom fields
- Apex trigger: RCA_ApprovalWorkItemTrigger (after insert, after update)
- Apex handler: RCA_ApprovalWorkItemTriggerHandler with comprehensive business logic
- Test class: RCA_ApprovalWorkItemTriggerHandler_Test (full coverage)
- Custom report type: RCA_QuotewithApprovalWorkItems
- Report folder: RCA_ApprovalReports
- Permission set: RCA_ApprovalReportViewer

**Key Features:**
- Master-Detail relationship to Quote for enhanced security
- External ID pattern for ApprovalWorkItem reference
- Automatic junction record creation and updates
- Bulk-safe processing (200+ records per transaction)
- Comprehensive error handling and logging
- Ready-to-use permission set for report viewers

**Known Limitations:**
- Sample reports not included (build custom reports using the report type)
- Requires manual testing with actual approval submission processes
- RCA_AssignedToId__c stores ID as text (not a lookup)

