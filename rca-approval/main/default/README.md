# **Kickstart Approval Process Framework**

**Version:** 1.0.2

[**Installation in Production**](https://login.salesforce.com/packaging/installPackage.apexp?p0=04td200000050fJAAQ)

[**Installation in Sandbox**](https://test.salesforce.com/packaging/installPackage.apexp?p0=04td200000050fJAAQ)

## **1\. Overview**

This package provides a reusable and configurable framework for submitting Salesforce Quote records for approval. It replaces the standard "Submit for Approval" button with a custom Lightning Web Component (LWC) modal, allowing for a more guided user experience directly from the record page.

The core of the process is driven by a powerful Orchestration Flow, making the backend approval logic easy to visualize and customize without additional code.

## **2\. Key Features**

- **LWC-Powered UI:** A modern, modal-based interface for submitting approvals and capturing user comments.
- **Flow-Driven Backend:** The entire approval process logic is handled by a flexible Orchestration Flow, allowing for easy customization of approval steps, status updates, and decision logic.
- **Secure & Context-Aware:** The process is initiated via a secure Apex Controller that respects user permissions.
- **Ready to Customize:** Built with extensibility in mind, allowing you to easily modify the approval criteria, assignee queue, and actions upon approval or rejection.

## **3\. Components Included**

| **Component Type** | **Component Name** | **Description** |
| --- | --- | --- |
| **Lightning Web Comp.** | rca_invokeQuoteApproval | The user-facing modal for capturing comments and submitting the Quote for approval. |
| **Apex Controller** | RCA_QuoteApprovalLWCController | Secure server-side controller that acts as a bridge between the LWC and the approval Flow. |
| **Apex Test Class** | RCA_QuoteApprovalLWCController_Test | Provides >75% code coverage and validates the controller logic against various scenarios. |
| **Flow (Orchestration)** | Quote Approval Process | The main Flow that orchestrates the entire approval process from submission to final decision. |
| **Flow (Subflow)** | Quote - Approval - Update Quote Status | A utility subflow called by the main orchestration to update the Status field on the Quote record. |
| **Flow (Subflow)** | Quote - Get Quote Record | A utility subflow to fetch the Quote record details. |
| **Quick Action** | Quote - Submit for Approval | Quick action button that invokes the flow via an apex to submit for approval. |

## **4\. How It Works (Default Process)**

1. A user clicks the custom "Submit for Approval" Quick Action on a Quote record.
2. The rca_invokeQuoteApproval LWC launches in a modal window, displaying a text area for approval comments.
3. The user enters comments and clicks "Submit".
4. The LWC calls the submitQuoteForApproval method in the RCA_QuoteApprovalLWCController.
5. The Apex controller invokes the **Quote Approval Process** Flow, passing the Quote ID and comments.
6. The Flow immediately updates the Quote's status to **'In Review'**.
7. The Flow then submits the Quote into the standard approval engine, assigning it to the **RCA_QuoteApprovers** queue.
8. The process then waits for an approver to Approve or Reject the record.

## **Post-Installation Steps & Configuration Guide**

To ensure the package functions correctly after installation, please follow these streamlined steps.

### **Step 1: Add users to the Approval Queue**

The approval flow is configured to assign requests to a specific queue. This queue must be created manually.

1. Navigate to **Setup > Users > Queues**.
2. Click **RCA Quote Approvers**.
3. Add the appropriate users as Queue Members.
4. Save the queue.

### **Step 2: Configure User Permissions**

Users who need to submit quotes for approval require access to the package components.

1. Navigate to **Setup > Users > Permission Sets**.
2. Create a new Permission Set (e.g., label it Quote Approval Submitter).
3. In the new Permission Set, grant the following access:
    - **Apex Class Access:** Add RCA_QuoteApprovalLWCController.
    - **Lightning Web Component Access:** Add rca_invokeQuoteApproval.
    - **System Permissions:** Ensure users have the "Run Flows" permission (this is typically enabled on standard profiles).
4. Assign this new Permission Set to all users who will be submitting quotes for approval.

### **Step 3: Review and Activate Flows**

1. Navigate to **Setup > Process Automation > Flows**.
2. You will see the three new flows from the package: Quote Approval Process, Quote - Approval - Update Quote Status, and Quote - Get Quote Record.
3. Open each one, review its logic to ensure it meets your business needs, and click **Activate**. All three flows must be active for the process to work.

### **Step 4: Place the Quick Action**

This final step makes the process visible to your users on the Quote record page.

1. **Add the Submit for Approval Action to the Page Layout:**
    - Navigate to **Setup > Object Manager > Quote > Page Layouts**.
    - Select the page layout you wish to modify.
    - In the palette at the top, select **Mobile & Lightning Actions**.
    - Find your new "Submit for Approval" action and drag it into the "Salesforce Mobile and Lightning Experience Actions" section at the top of the layout.
    - Save the page layout.

### **Step 5: Add Approval components**

1. Edit the quote record page **Setup > Object Manager > Quote > Lightning Receord Page**.
2. Edit the lightning page used in your org.
3. Create a new tab `Approvals` in the quote page.
3. Add the below components to the Approvals tab.
   - Flow Orchestration Work Guide
   - Approval Trace

### **Step 6: Test the Process**

1. Log in as a user with the Permission Set you configured.
2. Navigate to a test Quote record.
3. Click the "Submit for Approval" button.
4. Enter a comment and click "Submit".
5. Verify that the Quote's status changes to "In Review" and that the record is submitted for approval 
   (you can check this under the "Approval" tab on the quote page).

Your Kickstart Approval Process is now fully configured and ready to use!