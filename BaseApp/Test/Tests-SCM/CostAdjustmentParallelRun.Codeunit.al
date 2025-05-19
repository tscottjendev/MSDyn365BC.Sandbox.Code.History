codeunit 137103 "Cost Adjustment Parallel Run"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Adjustment] [SCM] [Concurrent Posting]
        Initialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Initialized: Boolean;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if Initialized then
            exit;

        LibrarySetupStorage.SaveInventorySetup();

        Initialized := true;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ItemJournalPost_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        ItemJournalline: Record "Item Journal Line";
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(2), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(3), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(4), 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create item journal lines for the second and fourth item.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalline, ItemNos.Get(2), '', '', -10);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalline, ItemNos.Get(4), '', '', -10);

        // [WHEN] Post the item journal order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryInventory.PostItemJournalLine(ItemJournalline."Journal Template Name", ItemJournalline."Journal Batch Name");

        // [THEN] Automatic Cost Adjustment has been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ItemJournalPost_DifferentLowLevelCodes()
    var
        Item: Record Item;
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 3 items with low-level codes 1, 2, 3.
        // [GIVEN] Post an inventory adjustment for each item.
        CreateItem(Item, Item."Costing Method"::FIFO, 1);
        ItemNos.Add(Item."No.");
        CreateItem(Item, Item."Costing Method"::FIFO, 2);
        ItemNos.Add(Item."No.");
        CreateItem(Item, Item."Costing Method"::FIFO, 3);
        ItemNos.Add(Item."No.");

        PostItemJournalLine(ItemNos.Get(1), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(2), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(3), 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Post item journal line for the second item (with low-level code 2).
        BindSubscription(this);
        PostItemJournalLine(ItemNos.Get(2), -10, 0.0, WorkDate());

        // [THEN] Automatic Cost Adjustment has been run for the second item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SalesPost_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(2), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(3), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(4), 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create a sales order with 2 lines for the first and third item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNos.Get(1), 10);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNos.Get(3), 10);

        // [WHEN] Post the sales order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; LowLevelCode: Integer)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", 10);
        Item.Validate("Last Direct Cost", 10);
        Item.Validate("Low-Level Code", LowLevelCode);
        Item.Modify(true);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date)
    begin
        PostItemJournalLine(ItemNo, '', Quantity, UnitAmount, PostingDate, 0);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date; AppliesToEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine."Applies-to Entry" := AppliesToEntryNo;
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetAutomaticCostAdjustment(IsAutomatic: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if IsAutomatic then
            InventorySetup.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Always)
        else
            InventorySetup.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Never);
        InventorySetup.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Key Management", OnAfterIsConcurrentInventoryPostingEnabled, '', false, false)]
    local procedure EnableConcurrentInventoryPosting(var ConcurrentInventoryPosting: Boolean)
    begin
        ConcurrentInventoryPosting := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}