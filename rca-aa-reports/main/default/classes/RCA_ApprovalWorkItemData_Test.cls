/**
 * @description Test class for RCA_ApprovalWorkItemData
 * @author Revenue Cloud Accelerators
 * @date 2025
 */
@isTest
private class RCA_ApprovalWorkItemData_Test {
    
    @isTest
    static void testDefaultConstructor() {
        Test.startTest();
        RCA_ApprovalWorkItemData data = new RCA_ApprovalWorkItemData();
        Test.stopTest();
        
        System.assertNotEquals(null, data, 'Data object should be created');
        System.assertEquals(null, data.workItemId);
        System.assertEquals(null, data.relatedRecordId);
        System.assertEquals(null, data.relatedRecordObjectName);
        System.assertEquals(null, data.status);
        System.assertEquals(null, data.assignedToId);
        System.assertEquals(null, data.approvalChainName);
    }
    
    @isTest
    static void testParameterizedConstructor() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert testOpp;
        
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Status = 'Draft'
        );
        insert testQuote;
        
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        
        // Use a real Id from the org to avoid invalid Id errors
        Id workItemId = testQuote.Id;
        
        Test.startTest();
        RCA_ApprovalWorkItemData data = new RCA_ApprovalWorkItemData(
            workItemId,
            testQuote.Id,
            'Quote',
            'Assigned',
            testUser.Id,
            'Test Approval Chain'
        );
        Test.stopTest();
        
        System.assertNotEquals(null, data);
        System.assertEquals(String.valueOf(workItemId), String.valueOf(data.workItemId));
        System.assertEquals(testQuote.Id, data.relatedRecordId);
        System.assertEquals('Quote', data.relatedRecordObjectName);
        System.assertEquals('Assigned', data.status);
        System.assertEquals(testUser.Id, data.assignedToId);
        System.assertEquals('Test Approval Chain', data.approvalChainName);
    }
    
    @isTest
    static void testSettersAndGetters() {
        // Setup test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert testOpp;
        
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OpportunityId = testOpp.Id,
            Status = 'Draft'
        );
        insert testQuote;
        
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        // Use a real Id to avoid invalid Id errors
        Id workItemId = testQuote.Id;
        
        RCA_ApprovalWorkItemData data = new RCA_ApprovalWorkItemData();
        
        Test.startTest();
        data.workItemId = workItemId;
        data.relatedRecordId = testQuote.Id;
        data.relatedRecordObjectName = 'Quote';
        data.status = 'Approved';
        data.assignedToId = testUser.Id;
        data.approvalChainName = 'Updated Chain';
        Test.stopTest();
        
        System.assertEquals(String.valueOf(workItemId), String.valueOf(data.workItemId));
        System.assertEquals(testQuote.Id, data.relatedRecordId);
        System.assertEquals('Quote', data.relatedRecordObjectName);
        System.assertEquals('Approved', data.status);
        System.assertEquals(testUser.Id, data.assignedToId);
        System.assertEquals('Updated Chain', data.approvalChainName);
    }
    
    @isTest
    static void testNullValues() {
        Test.startTest();
        RCA_ApprovalWorkItemData data = new RCA_ApprovalWorkItemData(
            null,
            null,
            null,
            null,
            null,
            null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, data);
        System.assertEquals(null, data.workItemId);
        System.assertEquals(null, data.relatedRecordId);
        System.assertEquals(null, data.relatedRecordObjectName);
        System.assertEquals(null, data.status);
        System.assertEquals(null, data.assignedToId);
        System.assertEquals(null, data.approvalChainName);
    }
}

