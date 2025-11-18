/**
 * @description Comprehensive test class for RCA_ApprovalWorkItemTriggerHandler
 *              Achieves 75%+ coverage by testing all business logic methods
 * @author Revenue Cloud Accelerators
 * @date 2025
 */
@isTest
private class RCA_ApprovalWorkItemTriggerHandler_Test {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        
        List<Quote> testQuotes = new List<Quote>();
        for (Integer i = 1; i <= 10; i++) {
            testQuotes.add(new Quote(
                Name = 'Test Quote ' + i,
                OpportunityId = testOpp.Id,
                Status = 'Draft'
            ));
        }
        insert testQuotes;
    }
    
    // ========== CORE BUSINESS LOGIC TESTS (Main Coverage) ==========
    
    @isTest
    static void testProcessWorkItems_Insert() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<RCA_ApprovalWorkItemData> dataList = new List<RCA_ApprovalWorkItemData>();
        dataList.add(createMockData('001', testQuote.Id, 'Assigned', testUser.Id, 'Test Chain'));
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(dataList, false);
        Test.stopTest();
        
        List<RCA_ApprovalWorkItemQuote__c> junctions = [SELECT Id, RCA_Status__c FROM RCA_ApprovalWorkItemQuote__c];
        System.assertEquals(1, junctions.size());
        System.assertEquals('Assigned', junctions[0].RCA_Status__c);
    }
    
    @isTest
    static void testProcessWorkItems_Update() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create initial junction
        List<RCA_ApprovalWorkItemData> initialData = new List<RCA_ApprovalWorkItemData>();
        initialData.add(createMockData('001', testQuote.Id, 'Assigned', testUser.Id, 'Initial'));
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(initialData, false);
        
        // Update with new status
        List<RCA_ApprovalWorkItemData> updateData = new List<RCA_ApprovalWorkItemData>();
        updateData.add(createMockData('001', testQuote.Id, 'Approved', testUser.Id, 'Updated'));
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(updateData, true);
        Test.stopTest();
        
        RCA_ApprovalWorkItemQuote__c junction = [SELECT RCA_Status__c, RCA_Label__c FROM RCA_ApprovalWorkItemQuote__c LIMIT 1];
        System.assertEquals('Approved', junction.RCA_Status__c);
        System.assertEquals('Updated', junction.RCA_Label__c);
    }
    
    @isTest
    static void testProcessWorkItems_Bulk() {
        List<Quote> quotes = [SELECT Id FROM Quote LIMIT 10];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<RCA_ApprovalWorkItemData> dataList = new List<RCA_ApprovalWorkItemData>();
        for (Integer i = 0; i < quotes.size(); i++) {
            dataList.add(createMockData(String.valueOf(i).leftPad(3, '0'), quotes[i].Id, 'Assigned', testUser.Id, 'Bulk ' + i));
        }
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(dataList, false);
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM RCA_ApprovalWorkItemQuote__c];
        System.assertEquals(10, count);
    }
    
    @isTest
    static void testProcessWorkItems_NullEmpty() {
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(null, false);
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(new List<RCA_ApprovalWorkItemData>(), false);
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM RCA_ApprovalWorkItemQuote__c];
        System.assertEquals(0, count);
    }
    
    // ========== FILTER METHOD TESTS ==========
    
    @isTest
    static void testFilterValidQuoteItems_ValidItems() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<RCA_ApprovalWorkItemData> input = new List<RCA_ApprovalWorkItemData>();
        input.add(createMockData('001', testQuote.Id, 'Assigned', testUser.Id, 'Valid'));
        input.add(createMockData('002', testQuote.Id, 'Approved', testUser.Id, 'Valid2'));
        
        Test.startTest();
        List<RCA_ApprovalWorkItemData> result = RCA_ApprovalWorkItemTriggerHandler.filterValidQuoteItems(input);
        Test.stopTest();
        
        System.assertEquals(2, result.size());
    }
    
    @isTest
    static void testFilterValidQuoteItems_FilterOutNonQuote() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<RCA_ApprovalWorkItemData> input = new List<RCA_ApprovalWorkItemData>();
        
        // Valid Quote item
        input.add(createMockData('001', testQuote.Id, 'Assigned', testUser.Id, 'Valid'));
        
        // Invalid - not Quote
        RCA_ApprovalWorkItemData invalidType = createMockData('002', testQuote.Id, 'Assigned', testUser.Id, 'Invalid');
        invalidType.relatedRecordObjectName = 'Opportunity';
        input.add(invalidType);
        
        // Invalid - null relatedRecordId
        RCA_ApprovalWorkItemData invalidNull = createMockData('003', testQuote.Id, 'Assigned', testUser.Id, 'Invalid2');
        invalidNull.relatedRecordId = null;
        input.add(invalidNull);
        
        Test.startTest();
        List<RCA_ApprovalWorkItemData> result = RCA_ApprovalWorkItemTriggerHandler.filterValidQuoteItems(input);
        Test.stopTest();
        
        System.assertEquals(1, result.size());
    }
    
    // ========== EXTRACT IDS TEST ==========
    
    @isTest
    static void testExtractWorkItemIds() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<RCA_ApprovalWorkItemData> input = new List<RCA_ApprovalWorkItemData>();
        input.add(createMockData('001', testQuote.Id, 'Assigned', testUser.Id, 'Test1'));
        input.add(createMockData('002', testQuote.Id, 'Assigned', testUser.Id, 'Test2'));
        input.add(createMockData('003', testQuote.Id, 'Assigned', testUser.Id, 'Test3'));
        
        Test.startTest();
        Set<String> result = RCA_ApprovalWorkItemTriggerHandler.extractWorkItemIds(input);
        Test.stopTest();
        
        System.assertEquals(3, result.size());
    }
    
    // ========== QUERY EXISTING JUNCTIONS TEST ==========
    
    @isTest
    static void testQueryExistingJunctions_Found() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create test junction
        RCA_ApprovalWorkItemData data = createMockData('999', testQuote.Id, 'Assigned', testUser.Id, 'Test');
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(new List<RCA_ApprovalWorkItemData>{data}, false);
        
        Set<String> searchIds = new Set<String>{String.valueOf(data.workItemId)};
        
        Test.startTest();
        Map<String, RCA_ApprovalWorkItemQuote__c> result = RCA_ApprovalWorkItemTriggerHandler.queryExistingJunctions(searchIds);
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assert(result.containsKey(String.valueOf(data.workItemId)));
    }
    
    @isTest
    static void testQueryExistingJunctions_NotFound() {
        Set<String> searchIds = new Set<String>{'04gd200000099999'};
        
        Test.startTest();
        Map<String, RCA_ApprovalWorkItemQuote__c> result = RCA_ApprovalWorkItemTriggerHandler.queryExistingJunctions(searchIds);
        Test.stopTest();
        
        System.assertEquals(0, result.size());
    }
    
    @isTest
    static void testQueryExistingJunctions_EmptyInput() {
        Test.startTest();
        Map<String, RCA_ApprovalWorkItemQuote__c> result = RCA_ApprovalWorkItemTriggerHandler.queryExistingJunctions(new Set<String>());
        Test.stopTest();
        
        System.assertEquals(0, result.size());
    }
    
    // ========== PREPARE JUNCTION RECORDS TESTS ==========
    
    @isTest
    static void testPrepareJunctionRecords_Insert() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<RCA_ApprovalWorkItemData> items = new List<RCA_ApprovalWorkItemData>();
        items.add(createMockData('001', testQuote.Id, 'Assigned', testUser.Id, 'New'));
        
        Map<String, RCA_ApprovalWorkItemQuote__c> existingJunctions = new Map<String, RCA_ApprovalWorkItemQuote__c>();
        List<RCA_ApprovalWorkItemQuote__c> toInsert = new List<RCA_ApprovalWorkItemQuote__c>();
        List<RCA_ApprovalWorkItemQuote__c> toUpdate = new List<RCA_ApprovalWorkItemQuote__c>();
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.prepareJunctionRecords(items, existingJunctions, toInsert, toUpdate);
        Test.stopTest();
        
        System.assertEquals(1, toInsert.size());
        System.assertEquals(0, toUpdate.size());
        System.assertEquals(testQuote.Id, toInsert[0].RCA_Quote__c);
    }
    
    @isTest
    static void testPrepareJunctionRecords_Update() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create existing junction
        RCA_ApprovalWorkItemData data = createMockData('001', testQuote.Id, 'Assigned', testUser.Id, 'Initial');
        List<RCA_ApprovalWorkItemData> initialList = new List<RCA_ApprovalWorkItemData>{data};
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(initialList, false);
        
        // Get the existing junction
        RCA_ApprovalWorkItemQuote__c existing = [SELECT Id, RCA_ApprovalWorkItemId__c, RCA_Quote__c FROM RCA_ApprovalWorkItemQuote__c LIMIT 1];
        
        // Prepare update
        RCA_ApprovalWorkItemData updateData = createMockData('001', testQuote.Id, 'Approved', testUser.Id, 'Updated');
        List<RCA_ApprovalWorkItemData> items = new List<RCA_ApprovalWorkItemData>{updateData};
        
        Map<String, RCA_ApprovalWorkItemQuote__c> existingJunctions = new Map<String, RCA_ApprovalWorkItemQuote__c>();
        existingJunctions.put(existing.RCA_ApprovalWorkItemId__c, existing);
        
        List<RCA_ApprovalWorkItemQuote__c> toInsert = new List<RCA_ApprovalWorkItemQuote__c>();
        List<RCA_ApprovalWorkItemQuote__c> toUpdate = new List<RCA_ApprovalWorkItemQuote__c>();
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.prepareJunctionRecords(items, existingJunctions, toInsert, toUpdate);
        Test.stopTest();
        
        System.assertEquals(0, toInsert.size());
        System.assertEquals(1, toUpdate.size());
        System.assertEquals('Approved', toUpdate[0].RCA_Status__c);
    }
    
    // ========== UPDATE JUNCTION FIELDS TEST ==========
    
    @isTest
    static void testUpdateJunctionFields() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        RCA_ApprovalWorkItemQuote__c junction = new RCA_ApprovalWorkItemQuote__c(
            RCA_ApprovalWorkItemId__c = '04gd200000001111',
            RCA_Quote__c = testQuote.Id,
            RCA_Status__c = 'Assigned',
            RCA_Label__c = 'Old'
        );
        insert junction;
        
        RCA_ApprovalWorkItemData updateData = createMockData('001', testQuote.Id, 'Approved', testUser.Id, 'New');
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.updateJunctionFields(junction, updateData);
        Test.stopTest();
        
        System.assertEquals('Approved', junction.RCA_Status__c);
        System.assertEquals('New', junction.RCA_Label__c);
        System.assertEquals(testUser.Id, junction.RCA_AssignedToId__c);
        // Quote field should remain unchanged (Master-Detail)
        System.assertEquals(testQuote.Id, junction.RCA_Quote__c);
    }
    
    // ========== CREATE JUNCTION RECORD TEST ==========
    
    @isTest
    static void testCreateJunctionRecord() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        RCA_ApprovalWorkItemData data = createMockData('001', testQuote.Id, 'Assigned', testUser.Id, 'Test Chain');
        
        Test.startTest();
        RCA_ApprovalWorkItemQuote__c junction = RCA_ApprovalWorkItemTriggerHandler.createJunctionRecord(data);
        Test.stopTest();
        
        System.assertNotEquals(null, junction);
        System.assertEquals(testQuote.Id, junction.RCA_Quote__c);
        System.assertEquals('Assigned', junction.RCA_Status__c);
        System.assertEquals(testUser.Id, junction.RCA_AssignedToId__c);
        System.assertEquals('Test Chain', junction.RCA_Label__c);
    }
    
    // ========== PERFORM DML TESTS ==========
    
    @isTest
    static void testPerformDML_Insert() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        List<RCA_ApprovalWorkItemQuote__c> toInsert = new List<RCA_ApprovalWorkItemQuote__c>();
        toInsert.add(new RCA_ApprovalWorkItemQuote__c(
            RCA_ApprovalWorkItemId__c = '04gd200000002222',
            RCA_Quote__c = testQuote.Id,
            RCA_Status__c = 'Assigned'
        ));
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.performDML(toInsert, new List<RCA_ApprovalWorkItemQuote__c>());
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM RCA_ApprovalWorkItemQuote__c];
        System.assertEquals(1, count);
    }
    
    @isTest
    static void testPerformDML_Update() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        
        RCA_ApprovalWorkItemQuote__c junction = new RCA_ApprovalWorkItemQuote__c(
            RCA_ApprovalWorkItemId__c = '04gd200000003333',
            RCA_Quote__c = testQuote.Id,
            RCA_Status__c = 'Assigned'
        );
        insert junction;
        
        junction.RCA_Status__c = 'Approved';
        List<RCA_ApprovalWorkItemQuote__c> toUpdate = new List<RCA_ApprovalWorkItemQuote__c>{junction};
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.performDML(new List<RCA_ApprovalWorkItemQuote__c>(), toUpdate);
        Test.stopTest();
        
        RCA_ApprovalWorkItemQuote__c updated = [SELECT RCA_Status__c FROM RCA_ApprovalWorkItemQuote__c WHERE Id = :junction.Id];
        System.assertEquals('Approved', updated.RCA_Status__c);
    }
    
    @isTest
    static void testPerformDML_Error() {
        // Try to insert without required Quote field
        List<RCA_ApprovalWorkItemQuote__c> toInsert = new List<RCA_ApprovalWorkItemQuote__c>();
        toInsert.add(new RCA_ApprovalWorkItemQuote__c(
            RCA_ApprovalWorkItemId__c = '04gd200000004444',
            RCA_Status__c = 'Assigned'
            // Missing required RCA_Quote__c
        ));
        
        Boolean exceptionCaught = false;
        Test.startTest();
        try {
            RCA_ApprovalWorkItemTriggerHandler.performDML(toInsert, new List<RCA_ApprovalWorkItemQuote__c>());
        } catch (DmlException e) {
            exceptionCaught = true;
        }
        Test.stopTest();
        
        System.assert(exceptionCaught);
    }
    
    @isTest
    static void testPerformDML_EmptyLists() {
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.performDML(
            new List<RCA_ApprovalWorkItemQuote__c>(),
            new List<RCA_ApprovalWorkItemQuote__c>()
        );
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM RCA_ApprovalWorkItemQuote__c];
        System.assertEquals(0, count);
    }
    
    // ========== RELEVANT CHANGES TEST ==========
    
    @isTest
    static void testHasRelevantChanges_True() {
        // Test with null oldRecord
        Test.startTest();
        Boolean result1 = RCA_ApprovalWorkItemTriggerHandler.hasRelevantChanges(null, null);
        Test.stopTest();
        
        System.assertEquals(true, result1);
    }
    
    @isTest
    static void testHasRelevantChanges_WithRecords() {
        // Create mock ApprovalWorkItem records (no DML)
        Id fakeId = createFakeApprovalWorkItemId(1);
        ApprovalWorkItem oldRecord = new ApprovalWorkItem(
            Id = fakeId,
            RelatedRecordId = fakeId,
            RelatedRecordObjectName = 'Quote',
            Status = 'Assigned',
            AssignedToId = fakeId,
            ApprovalChainName = 'Initial'
        );
        ApprovalWorkItem newRecord = new ApprovalWorkItem(
            Id = fakeId,
            RelatedRecordId = fakeId,
            RelatedRecordObjectName = 'Quote',
            Status = 'Approved', // changed
            AssignedToId = fakeId,
            ApprovalChainName = 'Initial'
        );
        
        Test.startTest();
        Boolean result = RCA_ApprovalWorkItemTriggerHandler.hasRelevantChanges(newRecord, oldRecord);
        Test.stopTest();
        
        System.assertEquals(true, result, 'Status change should be detected as relevant');
    }
    
    // ========== CONVERT TO DTO TESTS ==========
    
    @isTest
    static void testConvertToDTO_InsertScenario() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Mixed list: valid Quote, non-Quote, and null RelatedRecordId
        List<ApprovalWorkItem> records = new List<ApprovalWorkItem>();
        
        // Valid Quote-related record
        records.add(new ApprovalWorkItem(
            Id = createFakeApprovalWorkItemId(2),
            RelatedRecordId = testQuote.Id,
            RelatedRecordObjectName = 'Quote',
            Status = 'Assigned',
            AssignedToId = testUser.Id,
            ApprovalChainName = 'Quote Chain'
        ));
        
        // Non-Quote record
        records.add(new ApprovalWorkItem(
            Id = createFakeApprovalWorkItemId(3),
            RelatedRecordId = testQuote.Id,
            RelatedRecordObjectName = 'Opportunity',
            Status = 'Assigned',
            AssignedToId = testUser.Id,
            ApprovalChainName = 'Opp Chain'
        ));
        
        // Quote with null RelatedRecordId
        records.add(new ApprovalWorkItem(
            Id = createFakeApprovalWorkItemId(4),
            RelatedRecordId = null,
            RelatedRecordObjectName = 'Quote',
            Status = 'Assigned',
            AssignedToId = testUser.Id,
            ApprovalChainName = 'Null Quote'
        ));
        
        Test.startTest();
        List<RCA_ApprovalWorkItemData> dtos = RCA_ApprovalWorkItemTriggerHandler.convertToDTO(records);
        Test.stopTest();
        
        System.assertEquals(1, dtos.size(), 'Only valid Quote-related items should be converted');
        System.assertEquals(testQuote.Id, dtos[0].relatedRecordId);
    }
    
    @isTest
    static void testConvertToDTO_UpdateScenario_WithOldMap() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Id awiId = createFakeApprovalWorkItemId(5);
        
        ApprovalWorkItem oldRecord = new ApprovalWorkItem(
            Id = awiId,
            RelatedRecordId = testQuote.Id,
            RelatedRecordObjectName = 'Quote',
            Status = 'Assigned',
            AssignedToId = testUser.Id,
            ApprovalChainName = 'Initial'
        );
        ApprovalWorkItem newRecord = new ApprovalWorkItem(
            Id = awiId,
            RelatedRecordId = testQuote.Id,
            RelatedRecordObjectName = 'Quote',
            Status = 'Approved', // changed
            AssignedToId = testUser.Id,
            ApprovalChainName = 'Initial'
        );
        
        List<ApprovalWorkItem> records = new List<ApprovalWorkItem>{ newRecord };
        Map<Id, ApprovalWorkItem> oldMap = new Map<Id, ApprovalWorkItem>{ awiId => oldRecord };
        
        Test.startTest();
        List<RCA_ApprovalWorkItemData> dtos = RCA_ApprovalWorkItemTriggerHandler.convertToDTO(records, oldMap);
        Test.stopTest();
        
        System.assertEquals(1, dtos.size(), 'Changed record should be converted');
        System.assertEquals('Approved', dtos[0].status);
    }
    
    // ========== WRAPPER METHOD TESTS (handleAfterInsert/Update) ==========
    
    @isTest
    static void testHandleAfterInsert_QuoteItem() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Id awiId = createFakeApprovalWorkItemId(6);
        
        ApprovalWorkItem awi = new ApprovalWorkItem(
            Id = awiId,
            RelatedRecordId = testQuote.Id,
            RelatedRecordObjectName = 'Quote',
            Status = 'Assigned',
            AssignedToId = testUser.Id,
            ApprovalChainName = 'Wrapper Insert'
        );
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.handleAfterInsert(new List<ApprovalWorkItem>{awi});
        Test.stopTest();
        
        RCA_ApprovalWorkItemQuote__c junction = [
            SELECT RCA_ApprovalWorkItemId__c, RCA_Status__c, RCA_Label__c
            FROM RCA_ApprovalWorkItemQuote__c
            WHERE RCA_ApprovalWorkItemId__c = :String.valueOf(awiId)
            LIMIT 1
        ];
        System.assertEquals('Assigned', junction.RCA_Status__c);
        System.assertEquals('Wrapper Insert', junction.RCA_Label__c);
    }
    
    @isTest
    static void testHandleAfterUpdate_QuoteItem() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        Id awiId = createFakeApprovalWorkItemId(7);
        
        // Simulate existing work item via insert wrapper
        ApprovalWorkItem initialAwi = new ApprovalWorkItem(
            Id = awiId,
            RelatedRecordId = testQuote.Id,
            RelatedRecordObjectName = 'Quote',
            Status = 'Assigned',
            AssignedToId = testUser.Id,
            ApprovalChainName = 'Initial Wrapper'
        );
        RCA_ApprovalWorkItemTriggerHandler.handleAfterInsert(new List<ApprovalWorkItem>{initialAwi});
        
        // Now simulate update with changed status
        ApprovalWorkItem updatedAwi = new ApprovalWorkItem(
            Id = awiId,
            RelatedRecordId = testQuote.Id,
            RelatedRecordObjectName = 'Quote',
            Status = 'Approved',
            AssignedToId = testUser.Id,
            ApprovalChainName = 'Updated Wrapper'
        );
        Map<Id, ApprovalWorkItem> oldMap = new Map<Id, ApprovalWorkItem>{ awiId => initialAwi };
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.handleAfterUpdate(new List<ApprovalWorkItem>{updatedAwi}, oldMap);
        Test.stopTest();
        
        RCA_ApprovalWorkItemQuote__c junction = [
            SELECT RCA_ApprovalWorkItemId__c, RCA_Status__c, RCA_Label__c
            FROM RCA_ApprovalWorkItemQuote__c
            WHERE RCA_ApprovalWorkItemId__c = :String.valueOf(awiId)
            LIMIT 1
        ];
        System.assertEquals('Approved', junction.RCA_Status__c);
        System.assertEquals('Updated Wrapper', junction.RCA_Label__c);
    }
    
    // ========== INTEGRATION TESTS ==========
    
    @isTest
    static void testFullFlow_CreateAndUpdate() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create
        List<RCA_ApprovalWorkItemData> createData = new List<RCA_ApprovalWorkItemData>();
        createData.add(createMockData('100', testQuote.Id, 'Assigned', testUser.Id, 'Initial'));
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(createData, false);
        
        RCA_ApprovalWorkItemQuote__c created = [SELECT Id, RCA_Status__c FROM RCA_ApprovalWorkItemQuote__c LIMIT 1];
        System.assertEquals('Assigned', created.RCA_Status__c);
        
        // Update
        List<RCA_ApprovalWorkItemData> updateData = new List<RCA_ApprovalWorkItemData>();
        updateData.add(createMockData('100', testQuote.Id, 'Approved', testUser.Id, 'Final'));
        
        Test.startTest();
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(updateData, true);
        Test.stopTest();
        
        RCA_ApprovalWorkItemQuote__c updated = [SELECT RCA_Status__c, RCA_Label__c FROM RCA_ApprovalWorkItemQuote__c WHERE Id = :created.Id];
        System.assertEquals('Approved', updated.RCA_Status__c);
        System.assertEquals('Final', updated.RCA_Label__c);
    }
    
    @isTest
    static void testMasterDetailCascadeDelete() {
        Quote testQuote = [SELECT Id FROM Quote LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        List<RCA_ApprovalWorkItemData> data = new List<RCA_ApprovalWorkItemData>();
        data.add(createMockData('200', testQuote.Id, 'Assigned', testUser.Id, 'Test'));
        RCA_ApprovalWorkItemTriggerHandler.processWorkItems(data, false);
        
        Integer countBefore = [SELECT COUNT() FROM RCA_ApprovalWorkItemQuote__c];
        System.assertEquals(1, countBefore);
        
        Test.startTest();
        delete testQuote;
        Test.stopTest();
        
        Integer countAfter = [SELECT COUNT() FROM RCA_ApprovalWorkItemQuote__c];
        System.assertEquals(0, countAfter, 'Master-Detail should cascade delete');
    }
    
    // ========== HELPER METHODS ==========
    
    /**
     * @description Creates a fake ApprovalWorkItem Id using the real key prefix (9jR)
     *              This avoids DML while still producing Ids valid for the ApprovalWorkItem sObject type.
     */
    private static Id createFakeApprovalWorkItemId(Integer seed) {
        // 3-char prefix + 15-char numeric suffix = 18-char Id
        String suffix = String.valueOf(seed).leftPad(15, '0');
        return (Id)('9jR' + suffix);
    }
    
    private static RCA_ApprovalWorkItemData createMockData(
        String suffix,
        Id quoteId,
        String status,
        String assignedToId,
        String chainName
    ) {
        String fakeId = '9jR' + String.valueOf(suffix).leftPad(15, '0');
        RCA_ApprovalWorkItemData data = new RCA_ApprovalWorkItemData();
        data.workItemId = (Id)fakeId;
        data.relatedRecordId = quoteId;
        data.relatedRecordObjectName = 'Quote';
        data.status = status;
        data.assignedToId = assignedToId;
        data.approvalChainName = chainName;
        return data;
    }
}
