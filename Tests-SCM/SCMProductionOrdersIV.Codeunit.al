codeunit 137083 "SCM Production Orders IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        MissingAccountTxt: Label '%1 is missing in %2.', Comment = '%1 = Field caption, %2 = Table Caption';
        FieldMustBeEditableErr: Label '%1 must be editable in %2', Comment = ' %1 = Field Name , %2 = Page Name';
        FieldMustNotBeEditableErr: Label '%1 must not be editable in %2', Comment = ' %1 = Field Name , %2 = Page Name';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        EntryMustBeEqualErr: Label '%1 must be equal to %2 for Entry No. %3 in the %4.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Entry No., %4 = Table Caption';
        CannotFinishProductionLineErr: Label 'You cannot finish line %1 on %2 %3. It has consumption or capacity posted with no output.', Comment = '%1 = Production Order Line No. , %2 = Table Caption , %3 = Production Order No.';

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyUndoProductionOrderWithConsumptionWithoutAutomaticCostPosting()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order with no output, and the cost impact should also be posted to the inventory adjustment account.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [THEN] Verify "Cost Posted to G/L" must be zero in Value Entry for Capacity and consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [WHEN] Run "Post Inventory Cost to G/L".
        LibraryCosting.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "G/L Entries" for both value entries and cost impact should also be posted to the inventory adjustment account.
        VerifyGLEntriesForConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntry(ProductionOrder, RunTime * RoutingUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VerifyUndoProductionOrderWithConsumptionWithAutomaticCostPosting()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order with no output, and the cost impact should also be posted to the inventory adjustment account with Automatic Cost Posting.
        Initialize();

        // [GIVEN] Update "Finish Order without Output"in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "G/L Entries" for both value entries and cost impact should also be posted to the inventory adjustment account.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status::Finished, ProductionOrder."No.");
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        VerifyGLEntriesForConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntry(ProductionOrder, RunTime * RoutingUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyUndoProductionOrderWithConsumptionAndPostInventoryCostToGLIsExecutedForFinishedProdOrder()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order with no output.
        // The cost impact should also be posted to the inventory adjustment account When "Post Inventory Cost to G/L" is executed for Finished Production Order.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "Cost Posted to G/L" must be zero in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            0,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), 0, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [WHEN] Run "Post Inventory Cost to G/L".
        LibraryCosting.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption. "G/L Entries" for both value entries and cost impact should also be posted to the inventory adjustment account.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        VerifyGLEntriesForConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntry(ProductionOrder, RunTime * RoutingUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VerifyProductionOrderPostedWithConsumptionAndOutputWhenFinishOrderWithoutOutputIsEnabled()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order with output.
        // If "Finish Order without Output" is enabled on Change Status page then the cost impact should not be posted to the inventory adjustment account with Automatic Cost Posting.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", Quantity, RunTime, RoutingUnitCost);

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "G/L Entries" for both value entries and cost impact should not be posted to the inventory adjustment account.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status::Finished, ProductionOrder."No.");
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        VerifyGLEntriesForConsumptionEntryWithOutput(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntryWithOutput(ProductionOrder, RunTime * RoutingUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyAdjustmentEntryShouldAlsoBeCreatedForItemCharge()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseHeader: Record "Purchase Header";
        ChargeItemPurchaseHeader: Record "Purchase Header";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
        ItemChargeUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order can be moved to the Finished Production Order without output.
        // If "Finish Order without Output" is enabled while changing the status then the cost impact should also be posted to the inventory adjustment account for Item Charge.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        ItemChargeUnitCost := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Purchase Document with Unit Cost.
        CreateAndPostPurchaseOrderWithDirectUnitCost(PurchaseHeader, CompItem."No.", Quantity, CompUnitCost);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [WHEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [THEN] Verify "Cost Posted to G/L" must be updated in Value Entry for Capacity and Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        Assert.AreEqual(
            -Quantity * CompUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), -Quantity * CompUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        Assert.AreEqual(
            RunTime * RoutingUnitCost,
            ValueEntry."Cost Posted to G/L",
            StrSubstNo(EntryMustBeEqualErr, ValueEntry.FieldCaption("Cost Posted to G/L"), RunTime * RoutingUnitCost, ValueEntry."Entry No.", ValueEntry.TableCaption()));

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify "G/L Entries" for both value entries and cost impact should also be posted to the inventory adjustment account.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status::Finished, ProductionOrder."No.");
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        VerifyGLEntriesForConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * CompUnitCost);
        VerifyGLEntriesForCapacityEntry(ProductionOrder, RunTime * RoutingUnitCost);

        // [GIVEN] Create And Post Item Charge Purchase Order.
        CreateAndPostChargeItemPO(ChargeItemPurchaseHeader, PurchaseHeader."No.", CompItem."No.", WorkDate(), Quantity, ItemChargeUnitCost);

        // [GIVEN] Adust Cost-Item Entries.
        LibraryCosting.AdjustCostItemEntries(CompItem."No.", '');

        // [WHEN] Run "Post Inventory Cost to G/L".
        LibraryCosting.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify cost impact should also be posted to the inventory adjustment account for Item Charge.
        VerifyGLEntriesForAdjustmentConsumptionEntry(ProductionOrder, ProdItem, CompItem, Quantity * ItemChargeUnitCost);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VerifyInventoryAdjustAccountIsMissingWhenStatusIsChanged()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        GeneralPostingSetup: Record "General Posting Setup";
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the user should not be able to change the status When "Inventory Adjmt. Account" is missing in General Posting Setup.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Find Value Entry for "Item Ledger Entry Type" Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");

        // [GIVEN] Update "Inventory Adjmt. Account" in General Posting Setup.
        GeneralPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Inventory Adjmt. Account", '');
        GeneralPostingSetup.Modify();

        // [GIVEN] Set Finish Order Without Output.
        ProdOrderStatusMgt.SetFinishOrderWithoutOutput(true);

        // [WHEN] Change Prod Order Status from Released to Finished.
        asserterror ProdOrderStatusMgt.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), true);

        // [THEN] Verify that the user should not be able to change the status When "Inventory Adjmt. Account" is missing in General Posting Setup.
        GeneralPostingSetup.SetRange("Gen. Bus. Posting Group", ValueEntry."Gen. Bus. Posting Group");
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        GeneralPostingSetup.FindFirst();
        Assert.ExpectedError(
            StrSubstNo(MissingAccountTxt, GeneralPostingSetup.FieldCaption("Inventory Adjmt. Account"), GeneralPostingSetup.TableCaption() + ' ' + GeneralPostingSetup.GetFilters()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,VerifyFinishOrderWithoutOutputNotEditableInChangeStatusOnProdOrder')]
    procedure VerifyFinishOrderWithoutOutputMustNotBeEditableInChangeStatusOnProdOrderPage()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the "Finish Order without Output" must not be editable in "Change Status on Prod. Order" page When "Finish Order Without Output" is false in Manufacturing Setup.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(false);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Find Value Entry for "Item Ledger Entry Type" Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");

        // [WHEN] Invoke "Change Status" action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [THEN] Verify that the "Finish Order without Output" must not be editable in "Change Status on Prod. Order" page through Handler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,VerifyFinishOrderWithoutOutputEditableInChangeStatusOnProdOrder')]
    procedure VerifyFinishOrderWithoutOutputMustBeEditableInChangeStatusOnProdOrderPage()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the "Finish Order without Output" must be editable in "Change Status on Prod. Order" page When "Finish Order without Output" is true in Manufacturing Setup.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(true);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Find Value Entry for "Item Ledger Entry Type" Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");

        // [WHEN] Invoke "Change Status" action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [THEN] Verify that the "Finish Order Without Output" must be editable in "Change Status on Prod. Order" page through Handler.
    end;

    [Test]
    [HandlerFunctions('ChangeStatusOnProdOrderOk,ConfirmHandlerTrue')]
    procedure VerifyReleasedProdOrderCannotBeFinishedWithoutOutputWhenScrapPostingIsNotEnabled()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ValueEntry: Record "Value Entry";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ProdOrderComponent: Record "Prod. Order Component";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
        RunTime: Decimal;
        RoutingUnitCost: Decimal;
        CompUnitCost: Decimal;
    begin
        // [SCENARIO 327365] Verify that the Released Production Order cannot be Finished without output When "Finish Order without Output" is false in Manufacturing Setup.
        Initialize();

        // [GIVEN] Update "Finish Order without Output" in Manufacturing Setup.
        LibraryManufacturing.UpdateFinishOrderWithoutOutputInManufacturingSetup(false);

        // [GIVEN] Update "Automatic Cost Posting" in Inventory Setup.
        LibraryInventory.SetAutomaticCostPosting(true);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(ProdItem, CompItem, LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Save Quantity and Component Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        CompUnitCost := CompItem."Unit Cost";

        // [GIVEN] Create and Post Item Journal Line for Component item with Unit Cost.
        CreateItemJournalLineWithUnitCost(ItemJournalBatch, ItemJournalLine, CompItem."No.", Quantity, '', '', CompUnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Routing.
        CreateRoutingAndUpdateItem(ProdItem, WorkCenter);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", Quantity, '', '');

        // [GIVEN] Generate Random Run Time and Unit Cost.
        RunTime := LibraryRandom.RandInt(100);
        RoutingUnitCost := LibraryRandom.RandInt(100);

        // [GIVEN] Find Production Order Component.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Create and Post Consumption Journal.
        CreateAndPostConsumptionJournal(ProductionOrder, ProdOrderComponent, Quantity);

        // [GIVEN] Create and Post Output Journal with no output quantity.
        CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrder."No.", 0, RunTime, RoutingUnitCost);

        // [GIVEN] Find Value Entry for "Item Ledger Entry Type" Consumption.
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");

        // [GIVEN] Find Prod order Line.
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [WHEN] Invoke "Change Status" action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        asserterror ReleasedProductionOrder."Change &Status".Invoke();

        // [THEN] Verify that the Released Production Order cannot be Finished without output.
        Assert.ExpectedError(StrSubstNo(CannotFinishProductionLineErr, ProdOrderLine."Line No.", ProductionOrder.TableCaption(), ProdOrderLine."Prod. Order No."));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Production Orders IV");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Production Orders IV");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveManufacturingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Production Orders IV");
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithUnitCost(Item2);

        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        CreateItemWithUnitCost(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure ItemJournalSetup(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateItemWithUnitCost(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure CreateRoutingAndUpdateItem(var Item: Record Item; var WorkCenter: Record "Work Center"): Code[10]
    begin
        exit(CreateRoutingAndUpdateItemSubcontracted(Item, WorkCenter, false));
    end;

    local procedure CreateRoutingAndUpdateItemSubcontracted(var Item: Record Item; var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean): Code[10]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        CreateWorkCenter(WorkCenter, IsSubcontracted);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLink.FindFirst();
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        exit(RoutingLink.Code);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; IsSubcontracted: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGenPostingSetupWithDefVAT(GeneralPostingSetup);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        if IsSubcontracted then
            WorkCenter.Validate("Subcontractor No.", LibraryPurchase.CreateVendorNo());

        WorkCenter.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        WorkCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        OperationNo := LibraryManufacturing.FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity, LocationCode, BinCode);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrder: Record "Production Order"; ProdOrderComponent: Record "Prod. Order Component"; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Consumption, ProdOrderComponent."Item No.", Quantity);

        ItemJournalLine.Validate("Order No.", ProductionOrder."No.");
        ItemJournalLine.Validate("Prod. Order Comp. Line No.", ProdOrderComponent."Line No.");
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostOutputJournalWithRunTimeAndUnitCost(ProductionOrderNo: Code[20]; OutputQuantity: Decimal; RunTime: Decimal; UnitCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
    begin
        OutputJournalSetup(OutputItemJournalTemplate, OutputItemJournalBatch);
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExplodeRouting(
        var ItemJournalLine: Record "Item Journal Line";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryInventory.OutputJnlExplRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure CreateItemJournalLineWithUnitCost(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; UnitCost: Decimal)
    begin
        ItemJournalSetup(ItemJournalBatch);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure OutputJournalSetup(var OutputItemJournalTemplate: Record "Item Journal Template"; var OutputItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure FilterValueEntryWithItemLedgerEntryType(var ValueEntry: Record "Value Entry"; ProdOrderNo: Code[20]; ItemLedgerEntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Document No.", ProdOrderNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ItemLedgerEntryType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
    end;

    local procedure GetRelatedGLEntriesFromValueEntry(var TempGLEntry: Record "G/L Entry" temporary; ValueEntry: Record "Value Entry")
    var
        GLEntry: Record "G/L Entry";
        GLItemLedgRelation: Record "G/L - Item Ledger Relation";
    begin
        GLItemLedgRelation.SetCurrentKey("Value Entry No.");
        GLItemLedgRelation.SetRange("Value Entry No.", ValueEntry."Entry No.");
        if GLItemLedgRelation.FindSet() then
            repeat
                GLEntry.Get(GLItemLedgRelation."G/L Entry No.");
                TempGLEntry.Init();
                TempGLEntry := GLEntry;
                TempGLEntry.Insert();
            until GLItemLedgRelation.Next() = 0;
    end;

    local procedure VerifyGLEntriesWithAccountNoAndExpectedAmount(var TempGLEntry: Record "G/L Entry" temporary; AccountNo: Code[20]; ExpectedAmount: Decimal)
    begin
        TempGLEntry.Reset();
        TempGLEntry.SetLoadFields("G/L Account No.", Amount);
        TempGLEntry.SetRange("G/L Account No.", AccountNo);
        TempGLEntry.FindFirst();
        TempGLEntry.CalcSums(Amount);

        Assert.AreEqual(
            AccountNo,
            TempGLEntry."G/L Account No.",
            StrSubstNo(ValueMustBeEqualErr, TempGLEntry.FieldCaption("G/L Account No."), AccountNo, TempGLEntry.TableCaption()));
        Assert.AreEqual(
            ExpectedAmount,
            TempGLEntry.Amount,
            StrSubstNo(EntryMustBeEqualErr, TempGLEntry.FieldCaption(Amount), ExpectedAmount, TempGLEntry."Entry No.", TempGLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntriesForConsumptionEntry(ProductionOrder: Record "Production Order"; ProdItem: Record Item; CompItem: Record Item; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ProductionOrder."Location Code", ProdItem."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Inventory Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", 0);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Inventory Adjmt. Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForCapacityEntry(ProductionOrder: Record "Production Order"; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);
        Assert.RecordCount(TempGLEntry, 4);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ValueEntry."Location Code", ValueEntry."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Direct Cost Applied Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", 0);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Inventory Adjmt. Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForConsumptionEntryWithOutput(ProductionOrder: Record "Production Order"; ProdItem: Record Item; CompItem: Record Item; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ProductionOrder."Location Code", ProdItem."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Inventory Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForCapacityEntryWithOutput(ProductionOrder: Record "Production Order"; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::" ", '');
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);
        Assert.RecordCount(TempGLEntry, 2);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ValueEntry."Location Code", ValueEntry."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Direct Cost Applied Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", ExpectedValue);
    end;

    local procedure VerifyGLEntriesForAdjustmentConsumptionEntry(ProductionOrder: Record "Production Order"; ProdItem: Record Item; CompItem: Record Item; ExpectedValue: Decimal)
    var
        TempGLEntry: Record "G/L Entry" temporary;
        GenPostingSetup: Record "General Posting Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange(Adjustment, true);
        FilterValueEntryWithItemLedgerEntryType(ValueEntry, ProductionOrder."No.", "Item Ledger Entry Type"::Consumption, CompItem."No.");
        GetRelatedGLEntriesFromValueEntry(TempGLEntry, ValueEntry);

        GenPostingSetup.Get(ValueEntry."Gen. Bus. Posting Group", ValueEntry."Gen. Prod. Posting Group");
        InventoryPostingSetup.Get(ProductionOrder."Location Code", ProdItem."Inventory Posting Group");
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."Inventory Account", -ExpectedValue);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, InventoryPostingSetup."WIP Account", 0);
        VerifyGLEntriesWithAccountNoAndExpectedAmount(TempGLEntry, GenPostingSetup."Inventory Adjmt. Account", ExpectedValue);
    end;

    local procedure CreateAndPostPurchaseOrderWithDirectUnitCost(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; UnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify(true);

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostChargeItemPO(var PurchaseHeader: Record "Purchase Header"; PurchaseOrderNo: Code[20]; ItemNo: Code[20]; DocumentDate: Date; Quantity: Decimal; ItemChargeUnitCost: Decimal) PostedPurchInvoiceNo: Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentDate);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", ItemChargeUnitCost);
        PurchaseLine.Modify(true);

        CreateItemChargeAssignment(PurchaseLine, PurchaseOrderNo, ItemNo);
        PostedPurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentDate: Date)
    begin
        Clear(PurchaseHeader);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), Database::"Purchase Header"));
        PurchaseHeader.Validate("Document Date", DocumentDate);
        PurchaseHeader.Validate("Posting Date", DocumentDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateItemChargeAssignment(var PurchaseLine: Record "Purchase Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindPurchaseReceiptLine(PurchRcptLine, PurchaseOrderNo, ItemNo);
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.",
          PurchRcptLine."Line No.", PurchRcptLine."No.");
    end;

    local procedure FindPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; PurchaseOrderNo: Code[20]; ItemNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", PurchaseOrderNo);
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure VerifyFinishOrderWithoutOutputNotEditableInChangeStatusOnProdOrder(var ChangeStatusOnProductionOrder: TestPage "Change Status on Prod. Order")
    begin
        Assert.AreEqual(
            false,
            ChangeStatusOnProductionOrder."Finish Order Without Output".Editable(),
            StrSubstNo(FieldMustNotBeEditableErr, ChangeStatusOnProductionOrder."Finish Order Without Output".Caption(), ChangeStatusOnProductionOrder.Caption()));
    end;

    [ModalPageHandler]
    procedure VerifyFinishOrderWithoutOutputEditableInChangeStatusOnProdOrder(var ChangeStatusOnProductionOrder: TestPage "Change Status on Prod. Order")
    begin
        Assert.AreEqual(
            true,
            ChangeStatusOnProductionOrder."Finish Order Without Output".Editable(),
            StrSubstNo(FieldMustBeEditableErr, ChangeStatusOnProductionOrder."Finish Order Without Output".Caption(), ChangeStatusOnProductionOrder.Caption()));
    end;

    [ModalPageHandler]
    procedure ChangeStatusOnProdOrderOk(var ChangeStatusOnProductionOrder: TestPage "Change Status on Prod. Order")
    begin
        ChangeStatusOnProductionOrder.Yes().Invoke();
    end;
}
