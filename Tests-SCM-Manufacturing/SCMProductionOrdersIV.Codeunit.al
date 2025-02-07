// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Purchases.History;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Reports;

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
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ShowLevelAs: Option "First BOM Level","BOM Leaves";
        ShowCostShareAs: Option "Single-level","Rolled-up";
        IsInitialized: Boolean;
        ItemNoLbl: Label 'ItemNo';
        TotalCostLbl: Label 'TotalCost';
        CapOvhdCostLbl: Label 'CapOvhdCost';
        MfgOvhdCostLbl: Label 'MfgOvhdCost';
        MaterialCostLbl: Label 'MaterialCost';
        CapacityCostLbl: Label 'CapacityCost';
        SubcontrdCostLbl: Label 'SubcontrdCost';
        NonInventoryMaterialCostLbl: Label 'NonInventoryMaterialCost';
        MissingAccountTxt: Label '%1 is missing in %2.', Comment = '%1 = Field caption, %2 = Table Caption';
        FieldMustBeEditableErr: Label '%1 must be editable in %2', Comment = ' %1 = Field Name , %2 = Page Name';
        FieldMustNotBeEditableErr: Label '%1 must not be editable in %2', Comment = ' %1 = Field Name , %2 = Page Name';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        EntryMustBeEqualErr: Label '%1 must be equal to %2 for Entry No. %3 in the %4.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Entry No., %4 = Table Caption';
        CannotFinishProductionLineErr: Label 'You cannot finish line %1 on %2 %3. It has consumption or capacity posted with no output.', Comment = '%1 = Production Order Line No. , %2 = Table Caption , %3 = Production Order No.';
        MaterialCostMustBeEqualErr: Label 'Material Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        CapacityCostMustBeEqualErr: Label 'Capacity Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        SubcontractedCostMustBeEqualErr: Label 'Subcontracted Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        MfgOverheadCostMustBeEqualErr: Label 'Mfg. Overhead Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        CapacityOverheadCostMustBeEqualErr: Label 'Capacity Overhead Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        NonInvMaterialCostMustBeEqualErr: Label 'Non Inventory Material Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';
        TotalCostMustBeEqualErr: Label 'Total Cost must be equal to %1 in item %2', Comment = ' %1 = Expected Value , %2 = Item No.';

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

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyMaterialCostNonInventoryValueMustBeShownInBOMCostSharesForProductionItem()
    var
        OutputItem: Record Item;
        NonInvItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        BOMCostShares: TestPage "BOM Cost Shares";
        Quantity: Decimal;
        NonInvUnitCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(OutputItem, NonInvItem, ProductionBOMHeader);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem, Quantity, NonInvUnitCost);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page.
        BOMCostShares.OpenView();
        BOMCostShares.ItemFilter.SetValue(OutputItem."No.");

        // [THEN] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page.
        BOMCostShares."Rolled-up Mat. Non-Invt. Cost".AssertEquals(NonInvUnitCost);
        BOMCostShares."Total Cost".AssertEquals(NonInvUnitCost);

        // [THEN] Verify Material Costs fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, NonInvUnitCost, 0, 0, NonInvUnitCost, NonInvUnitCost, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyMaterialCostNonInventoryValueMustBeShownInBOMCostSharesForProductionItemWithTwoComponents()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        BOMCostShares: TestPage "BOM Cost Shares";
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
    begin
        // [SCENARIO 457878] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory and production item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item with Production BOM.
        CreateProductionItemWithNonInvItemAndProductionBOM(SemiOutputItem, NonInvItem1, ProductionBOMHeader);

        // [GIVEN] Save Quantity and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(20, 20);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(30, 30);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Semi-Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(OutputItem, NonInvItem2, SemiOutputItem);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page.
        BOMCostShares.OpenView();
        BOMCostShares.ItemFilter.SetValue(OutputItem."No.");

        // [THEN] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory and production item exist in Production BOM.
        BOMCostShares."Rolled-up Mat. Non-Invt. Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2);
        BOMCostShares."Total Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2);

        // [THEN] Verify Material Costs fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, NonInvUnitCost1 + NonInvUnitCost2, NonInvUnitCost1, 0, NonInvUnitCost2, NonInvUnitCost1 + NonInvUnitCost2, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifyMaterialCostNonInventoryValueMustBeShownInBOMCostSharesForProductionItemWithThreeComponents()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        CompItem: array[2] of Record Item;
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        BOMCostShares: TestPage "BOM Cost Shares";
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedSLMatCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory, component and production item exist in Production BOM.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Save Quantity, Component and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(50, 50);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(20, 20);
        CompUnitCost1 := LibraryRandom.RandIntInRange(30, 30);
        CompUnitCost2 := LibraryRandom.RandIntInRange(40, 40);
        ExpectedStandardCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2;
        ExpectedSLMatCost := NonInvUnitCost1 + CompUnitCost1 + CompUnitCost2;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page.
        BOMCostShares.OpenView();
        BOMCostShares.ItemFilter.SetValue(OutputItem."No.");

        // [THEN] Verify "Material Cost - Non Inventory" must be shown in "BOM Cost Shares" page for production item When Non-Inventory, component and production item exist in Production BOM.
        BOMCostShares."Rolled-up Mat. Non-Invt. Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2);
        BOMCostShares."Total Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2);

        // [THEN] Verify Material Costs fields in Semi-Output item.
        SemiOutputItem.Get(SemiOutputItem."No.");
        VerifyCostFieldsInItem(SemiOutputItem, NonInvUnitCost1 + CompUnitCost1, CompUnitCost1, CompUnitCost1, NonInvUnitCost1, NonInvUnitCost1, 0, 0);

        // [THEN] Verify Material Costs fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(OutputItem, ExpectedStandardCost, ExpectedSLMatCost, CompUnitCost1 + CompUnitCost2, NonInvUnitCost2, NonInvUnitCost1 + NonInvUnitCost2, 0, 0);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifySingleAndRolledCostFieldsWithIndirectPercentageForProductionItem()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        CompItem: array[2] of Record Item;
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        BOMCostShares: TestPage "BOM Cost Shares";
        ExpectedOvhdCost: Decimal;
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        IndirectCostPer: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedSLMatCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Single-Level" and "Rolled-up" fields with "Indirect Cost %" for production item.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Save Quantity, Component, Indirect% and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(50, 50);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(20, 20);
        CompUnitCost1 := LibraryRandom.RandIntInRange(30, 30);
        CompUnitCost2 := LibraryRandom.RandIntInRange(40, 40);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2) * IndirectCostPer / 100;
        ExpectedStandardCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + ExpectedOvhdCost;
        ExpectedSLMatCost := NonInvUnitCost1 + CompUnitCost1 + CompUnitCost2;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);

        // [GIVEN] Update "Costing Method" Standard and "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Set Value of Item Filter in BOM Cost Shares Page.
        BOMCostShares.OpenView();
        BOMCostShares.ItemFilter.SetValue(OutputItem."No.");

        // [THEN] Verify "Total Cost" must be shown in "BOM Cost Shares" page for production item.
        BOMCostShares."Total Cost".AssertEquals(NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + ExpectedOvhdCost);

        // [THEN] Verify Costs fields in Semi-Output item.
        SemiOutputItem.Get(SemiOutputItem."No.");
        VerifyCostFieldsInItem(SemiOutputItem, NonInvUnitCost1 + CompUnitCost1, CompUnitCost1, CompUnitCost1, NonInvUnitCost1, NonInvUnitCost1, 0, 0);

        // [THEN] Verify Costs fields in Output item.
        OutputItem.Get(OutputItem."No.");
        VerifyCostFieldsInItem(
            OutputItem,
            ExpectedStandardCost,
            ExpectedSLMatCost,
            CompUnitCost1 + CompUnitCost2,
            NonInvUnitCost2,
            NonInvUnitCost1 + NonInvUnitCost2,
            ExpectedOvhdCost,
            ExpectedOvhdCost);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure VerifySingleLevelAndRolledUpCostFieldsWithIndirectPercentageForStockKeepingUnit()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        Location: Record Location;
        CompItem: array[2] of Record Item;
        SemiStockkeepingUnit: Record "Stockkeeping Unit";
        OutputStockkeepingUnit: Record "Stockkeeping Unit";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ExpectedOvhdCost: Decimal;
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        IndirectCostPer: Decimal;
        ExpectedStandardCost: Decimal;
        ExpectedSLMatCost: Decimal;
    begin
        // [SCENARIO 457878] Verify "Single-Level" and "Rolled-up" fields with "Indirect Cost %" for "StockKeeping Unit".
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Update "Costing Method" Standard in Semi-Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Save Quantity, Component, Indirect% and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(50, 50);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(20, 20);
        CompUnitCost1 := LibraryRandom.RandIntInRange(30, 30);
        CompUnitCost2 := LibraryRandom.RandIntInRange(40, 40);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2) * IndirectCostPer / 100;
        ExpectedStandardCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + ExpectedOvhdCost;
        ExpectedSLMatCost := NonInvUnitCost1 + CompUnitCost1 + CompUnitCost2;

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Semi-Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(SemiOutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Semi-Stockkeeping Unit.
        SemiStockkeepingUnit.SetRange("Item No.", SemiOutputItem."No.");
        SemiStockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        SemiStockkeepingUnit.Validate("Location Code", Location.Code);
        SemiStockkeepingUnit.Validate("Routing No.", '');
        SemiStockkeepingUnit.Validate("Production BOM No.", SemiOutputItem."Production BOM No.");
        SemiStockkeepingUnit.Modify(true);

        // [GIVEN] Update "Production BOM No." in Semi-Production item.
        SemiOutputItem.Validate("Production BOM No.", '');
        SemiOutputItem.Modify();

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [WHEN] Calculate Standard Cost for Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(SemiStockkeepingUnit."Item No.", SemiStockkeepingUnit."Location Code", SemiStockkeepingUnit."Variant Code");

        // [THEN] Verify Costs fields in Semi StockKeeping Unit and Output item.
        SemiStockkeepingUnit.Get(SemiStockkeepingUnit."Location Code", SemiStockkeepingUnit."Item No.", SemiStockkeepingUnit."Variant Code");
        VerifyCostFieldsInItem(SemiOutputItem, 0, 0, 0, 0, 0, 0, 0);
        VerifyCostFieldsInSKU(SemiStockkeepingUnit, NonInvUnitCost1 + CompUnitCost1, CompUnitCost1, CompUnitCost1, NonInvUnitCost1, NonInvUnitCost1, 0, 0);

        // [GIVEN] Update "Production BOM No." in Semi-Production item.
        SemiOutputItem.Validate("Production BOM No.", SemiStockkeepingUnit."Production BOM No.");
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);

        // [GIVEN] Update "Costing Method" Standard and "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Create Production Stockkeeping Unit.
        LibraryInventory.CreateStockKeepingUnit(OutputItem, Enum::"SKU Creation Method"::"Location & Variant", false, false);

        // [GIVEN] Find Production Stockkeeping Unit.
        OutputStockkeepingUnit.SetRange("Item No.", OutputItem."No.");
        OutputStockkeepingUnit.FindFirst();

        // [GIVEN] Validate Location Code, Routing No. and Production BOM No. in Stockkeeping Unit.
        OutputStockkeepingUnit.Validate("Location Code", Location.Code);
        OutputStockkeepingUnit.Validate("Routing No.", '');
        OutputStockkeepingUnit.Validate("Production BOM No.", OutputItem."Production BOM No.");
        OutputStockkeepingUnit.Modify(true);

        // [GIVEN] Update "Production BOM No." in Production item.
        OutputItem.Validate("Production BOM No.", '');
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Calculate Standard Cost for Production Stockkeeping Unit.
        CalculateStandardCost.CalcItemSKU(OutputStockkeepingUnit."Item No.", OutputStockkeepingUnit."Location Code", OutputStockkeepingUnit."Variant Code");

        // [THEN] Verify Costs fields in Output StockKeeping Unit and item.
        OutputStockkeepingUnit.Get(OutputStockkeepingUnit."Location Code", OutputStockkeepingUnit."Item No.", OutputStockkeepingUnit."Variant Code");
        VerifyCostFieldsInItem(OutputItem, 0, 0, 0, 0, 0, 0, 0);
        VerifyCostFieldsInSKU(
            OutputStockkeepingUnit,
            ExpectedStandardCost,
            ExpectedSLMatCost,
            CompUnitCost1 + CompUnitCost2,
            NonInvUnitCost2,
            NonInvUnitCost1 + NonInvUnitCost2,
            ExpectedOvhdCost,
            ExpectedOvhdCost);
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,BOMCostSharesDistributionReportHandler')]
    procedure VerifyCostAmountInBOMCostSharesDistributionReportForProductionItem()
    var
        OutputItem: Record Item;
        SemiOutputItem: Record Item;
        NonInvItem1: Record Item;
        NonInvItem2: Record Item;
        CompItem: array[2] of Record Item;
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ExpectedOvhdCost: Decimal;
        Quantity: Decimal;
        NonInvUnitCost1: Decimal;
        NonInvUnitCost2: Decimal;
        CompUnitCost1: Decimal;
        CompUnitCost2: Decimal;
        IndirectCostPer: Decimal;
        ExpectedSLMatCost: Decimal;
        ExpectedTotalCost: Decimal;
    begin
        // [SCENARIO 457878] Verify Cost Amount fields in "BOM Cost Share Distribution" report for production item.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Update "Journal Templ. Name Mandatory" in General Ledger Setup.
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        // [GIVEN] Create component items.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Create Semi Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(SemiOutputItem, NonInvItem1, CompItem[1]);

        // [GIVEN] Save Quantity, Component, Indirect% and Non-Inventory Unit Cost.
        Quantity := LibraryRandom.RandIntInRange(10, 10);
        NonInvUnitCost1 := LibraryRandom.RandIntInRange(50, 50);
        NonInvUnitCost2 := LibraryRandom.RandIntInRange(20, 20);
        CompUnitCost1 := LibraryRandom.RandIntInRange(30, 30);
        CompUnitCost2 := LibraryRandom.RandIntInRange(40, 40);
        IndirectCostPer := LibraryRandom.RandIntInRange(10, 10);
        ExpectedOvhdCost := (NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2) * IndirectCostPer / 100;
        ExpectedSLMatCost := CompUnitCost1 + CompUnitCost2 + NonInvUnitCost1;
        ExpectedTotalCost := NonInvUnitCost1 + NonInvUnitCost2 + CompUnitCost1 + CompUnitCost2 + ExpectedOvhdCost;

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem1, Quantity, NonInvUnitCost1);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[1], Quantity, CompUnitCost1);

        // [GIVEN] Update "Costing Method" Standard in Production item.
        SemiOutputItem.Validate("Costing Method", SemiOutputItem."Costing Method"::Standard);
        SemiOutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Semi-Production Item.
        CalculateStdCost.CalcItem(SemiOutputItem."No.", false);

        // [GIVEN] Create Production Item, Non-Inventory Item and Production BOM contains Non-Inventory item, Semi-Production and component item.
        CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(OutputItem, NonInvItem2, SemiOutputItem, CompItem[2]);

        // [GIVEN] Create and Post Purchase Document for Non-Inventory and component item with Unit Cost.
        CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem2, Quantity, NonInvUnitCost2);
        CreateAndPostPurchaseDocumentWithNonInvItem(CompItem[2], Quantity, CompUnitCost2);

        // [GIVEN] Update "Costing Method" Standard and "Indirect Cost %" in Production item.
        OutputItem.Validate("Costing Method", OutputItem."Costing Method"::Standard);
        OutputItem.Validate("Indirect Cost %", IndirectCostPer);
        OutputItem.Modify();

        // [GIVEN] Calculate Material Cost of Production Item.
        CalculateStdCost.CalcItem(OutputItem."No.", false);

        // [WHEN] Run "BOM Cost Share Distribution" with ShowLevelAs "First BOM Level" and ShowCostShareAs "Single-level".
        RunBOMCostSharesReport(OutputItem, ShowLevelAs::"First BOM Level", true, ShowCostShareAs::"Single-level");

        // [THEN] Verify Cost Amount in "BOM Cost Share Distribution" report.
        VerifyBOMCostSharesReport(OutputItem."No.", ExpectedSLMatCost, 0, ExpectedOvhdCost, 0, 0, NonInvUnitCost2, ExpectedTotalCost);

        // [WHEN] Run "BOM Cost Share Distribution" with ShowLevelAs "BOM Leaves" and ShowCostShareAs "Single-level".
        RunBOMCostSharesReport(OutputItem, ShowLevelAs::"BOM Leaves", true, ShowCostShareAs::"Single-level");

        // [THEN] Verify Cost Amount in "BOM Cost Share Distribution" report.
        VerifyBOMCostSharesReport(OutputItem."No.", ExpectedSLMatCost, 0, ExpectedOvhdCost, 0, 0, NonInvUnitCost2, ExpectedTotalCost);

        // [WHEN] Run "BOM Cost Share Distribution" with ShowLevelAs "First BOM Level" and ShowCostShareAs "Rolled-up".
        RunBOMCostSharesReport(OutputItem, ShowLevelAs::"First BOM Level", true, ShowCostShareAs::"Rolled-up");

        // [THEN] Verify Cost Amount in "BOM Cost Share Distribution" report.
        VerifyBOMCostSharesReport(OutputItem."No.", CompUnitCost1 + CompUnitCost2, 0, ExpectedOvhdCost, 0, 0, NonInvUnitCost1 + NonInvUnitCost2, ExpectedTotalCost);

        // [WHEN] Run "BOM Cost Share Distribution" with ShowLevelAs "BOM Leaves" and ShowCostShareAs "Rolled-up".
        RunBOMCostSharesReport(OutputItem, ShowLevelAs::"BOM Leaves", true, ShowCostShareAs::"Rolled-up");

        // [THEN] Verify Cost Amount in "BOM Cost Share Distribution" report.
        VerifyBOMCostSharesReport(OutputItem."No.", CompUnitCost1 + CompUnitCost2, 0, ExpectedOvhdCost, 0, 0, NonInvUnitCost1 + NonInvUnitCost2, ExpectedTotalCost);
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

    local procedure CreateProductionItemWithNonInvItemAndProductionBOM(var ProdItem: Record Item; var NonInvItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CreateProductionItemWithNonInvItemAndProductionBOMWithTwoComponent(var ProdItem: Record Item; var NonInvItem: Record Item; SemiProdItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, NonInvItem."No.", SemiProdItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CreateProductionItemWithNonInvItemAndProductionBOMWithThreeComponent(var ProdItem: Record Item; var NonInvItem: Record Item; Item1: Record Item; Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, NonInvItem."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item1."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();
    end;

    local procedure CreateAndPostPurchaseDocumentWithNonInvItem(NonInvItem: Record Item; Quantity: Decimal; UnitCost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
            PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
            LibraryPurchase.CreateVendorNo(), NonInvItem."No.", Quantity, '', WorkDate());

        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Modify();

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure VerifyCostFieldsInItem(Item: Record Item; StandardCost: Decimal; SLMatCost: Decimal; RUMatCost: Decimal; SLNonInvMatCost: Decimal; RUNonInvMatCost: Decimal; SLMfgOvhdCost: Decimal; RUMfgOvhdCost: Decimal)
    begin
        Assert.AreEqual(
            StandardCost,
            Item."Standard Cost",
            StrSubstNo(EntryMustBeEqualErr, Item.FieldCaption("Standard Cost"), StandardCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLNonInvMatCost,
            Item."Single-Lvl Mat. Non-Invt. Cost",
            StrSubstNo(EntryMustBeEqualErr, Item.FieldCaption("Single-Lvl Mat. Non-Invt. Cost"), SLNonInvMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUNonInvMatCost,
            Item."Rolled-up Mat. Non-Invt. Cost",
            StrSubstNo(EntryMustBeEqualErr, Item.FieldCaption("Rolled-up Mat. Non-Invt. Cost"), RUNonInvMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLMatCost,
            Item."Single-Level Material Cost",
            StrSubstNo(EntryMustBeEqualErr, Item.FieldCaption("Single-Level Material Cost"), SLMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUMatCost,
            Item."Rolled-up Material Cost",
            StrSubstNo(EntryMustBeEqualErr, Item.FieldCaption("Rolled-up Material Cost"), RUMatCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            SLMfgOvhdCost,
            Item."Single-Level Mfg. Ovhd Cost",
            StrSubstNo(EntryMustBeEqualErr, Item.FieldCaption("Single-Level Mfg. Ovhd Cost"), SLMfgOvhdCost, Item."No.", Item.TableCaption()));
        Assert.AreEqual(
            RUMfgOvhdCost,
            Item."Rolled-up Mfg. Ovhd Cost",
            StrSubstNo(EntryMustBeEqualErr, Item.FieldCaption("Rolled-up Mfg. Ovhd Cost"), RUMfgOvhdCost, Item."No.", Item.TableCaption()));
    end;

    local procedure VerifyCostFieldsInSKU(SKU: Record "Stockkeeping Unit"; StandardCost: Decimal; SLMatCost: Decimal; RUMatCost: Decimal; SLNonInvMatCost: Decimal; RUNonInvMatCost: Decimal; SLMfgOvhdCost: Decimal; RUMfgOvhdCost: Decimal)
    begin
        Assert.AreEqual(
            StandardCost,
            SKU."Standard Cost",
            StrSubstNo(EntryMustBeEqualErr, SKU.FieldCaption("Standard Cost"), StandardCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            SLNonInvMatCost,
            SKU."Single-Lvl Mat. Non-Invt. Cost",
            StrSubstNo(EntryMustBeEqualErr, SKU.FieldCaption("Single-Lvl Mat. Non-Invt. Cost"), SLNonInvMatCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            RUNonInvMatCost,
            SKU."Rolled-up Mat. Non-Invt. Cost",
            StrSubstNo(EntryMustBeEqualErr, SKU.FieldCaption("Rolled-up Mat. Non-Invt. Cost"), RUNonInvMatCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            SLMatCost,
            SKU."Single-Level Material Cost",
            StrSubstNo(EntryMustBeEqualErr, SKU.FieldCaption("Single-Level Material Cost"), SLMatCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            RUMatCost,
            SKU."Rolled-up Material Cost",
            StrSubstNo(EntryMustBeEqualErr, SKU.FieldCaption("Rolled-up Material Cost"), RUMatCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            SLMfgOvhdCost,
            SKU."Single-Level Mfg. Ovhd Cost",
            StrSubstNo(EntryMustBeEqualErr, SKU.FieldCaption("Single-Level Mfg. Ovhd Cost"), SLMfgOvhdCost, SKU."Item No.", SKU.TableCaption()));
        Assert.AreEqual(
            RUMfgOvhdCost,
            SKU."Rolled-up Mfg. Ovhd Cost",
            StrSubstNo(EntryMustBeEqualErr, SKU.FieldCaption("Rolled-up Mfg. Ovhd Cost"), RUMfgOvhdCost, SKU."Item No.", SKU.TableCaption()));
    end;

    local procedure RunBOMCostSharesReport(Item: Record Item; ShowLevel: Option; ShowDetails: Boolean; ShowCostShare: Option)
    var
        Item1: Record Item;
    begin
        Item1.SetRange("No.", Item."No.");
        Commit();

        LibraryVariableStorage.Enqueue(ShowCostShare);
        LibraryVariableStorage.Enqueue(ShowLevel);
        LibraryVariableStorage.Enqueue(ShowDetails);
        Report.Run(Report::"BOM Cost Share Distribution", true, false, Item1);
    end;

    local procedure VerifyBOMCostSharesReport(ItemNo: Code[20]; ExpMaterialCost: Decimal; ExpCapacityCost: Decimal; ExpMfgOvhdCost: Decimal; ExpCapOvhdCost: Decimal; ExpSubcontractedCost: Decimal; ExpNonInvMaterialCost: Decimal; ExpTotalCost: Decimal)
    var
        CostAmount: Decimal;
        RoundingFactor: Decimal;
    begin
        RoundingFactor := 100 * LibraryERM.GetUnitAmountRoundingPrecision();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(ItemNoLbl, ItemNo);

        CostAmount := LibraryReportDataset.Sum(MaterialCostLbl);
        Assert.AreNearlyEqual(ExpMaterialCost, CostAmount, RoundingFactor, StrSubstNo(MaterialCostMustBeEqualErr, ExpMaterialCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(CapacityCostLbl);
        Assert.AreNearlyEqual(ExpCapacityCost, CostAmount, RoundingFactor, StrSubstNo(CapacityCostMustBeEqualErr, ExpCapacityCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(MfgOvhdCostLbl);
        Assert.AreNearlyEqual(ExpMfgOvhdCost, CostAmount, RoundingFactor, StrSubstNo(MfgOverheadCostMustBeEqualErr, ExpMfgOvhdCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(CapOvhdCostLbl);
        Assert.AreNearlyEqual(ExpCapOvhdCost, CostAmount, RoundingFactor, StrSubstNo(CapacityOverheadCostMustBeEqualErr, ExpCapOvhdCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(SubcontrdCostLbl);
        Assert.AreNearlyEqual(ExpSubcontractedCost, CostAmount, RoundingFactor, StrSubstNo(SubcontractedCostMustBeEqualErr, ExpSubcontractedCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(NonInventoryMaterialCostLbl);
        Assert.AreNearlyEqual(ExpNonInvMaterialCost, CostAmount, RoundingFactor, StrSubstNo(NonInvMaterialCostMustBeEqualErr, ExpNonInvMaterialCost, ItemNo));

        CostAmount := LibraryReportDataset.Sum(TotalCostLbl);
        Assert.AreNearlyEqual(ExpTotalCost, CostAmount, RoundingFactor, StrSubstNo(TotalCostMustBeEqualErr, ExpTotalCost, ItemNo));
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

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesDistributionReportHandler(var BOMCostShareDistribution: TestRequestPage "BOM Cost Share Distribution")
    var
        ShowCostShareAsLcl: Variant;
        ShowLevelAsLcl: Variant;
        ShowDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowCostShareAsLcl);
        LibraryVariableStorage.Dequeue(ShowLevelAsLcl);
        LibraryVariableStorage.Dequeue(ShowDetails);

        BOMCostShareDistribution.ShowCostShareAs.SetValue(ShowCostShareAsLcl);
        BOMCostShareDistribution.ShowLevelAs.SetValue(ShowLevelAsLcl);
        BOMCostShareDistribution.ShowDetails.SetValue(ShowDetails);
        BOMCostShareDistribution.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
