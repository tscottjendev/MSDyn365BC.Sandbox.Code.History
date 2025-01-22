codeunit 137084 "SCM Production Orders V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        IsInitialized := false;
    end;

    var
        LocationGreen: Record Location;
        LocationRed: Record Location;
        LocationYellow: Record Location;
        LocationWhite: Record Location;
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';

    [Test]
    procedure VerifyDifferentLocationMustNotBeAllowedInProdOrderLineWhenWhsePutAwayOnLocation()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 559653] Verify Different Location must not be allowed in Production Order Line When "Prod. Output Whse. Handling" is "Warehouse Put-away" on Location.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationGreen.Validate("Prod. Output Whse. Handling", LocationGreen."Prod. Output Whse. Handling"::"No Warehouse Handling");
        LocationGreen.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationWhite.Validate("Prod. Output Whse. Handling", LocationWhite."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationWhite.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"No Warehouse Handling");
        LocationRed.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationYellow.Validate("Prod. Output Whse. Handling", LocationYellow."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationYellow.Modify();

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, Item2);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationWhite.Code, '');

        // [WHEN] Insert Production Order Line with different Location "Warehouse Put-away".
        asserterror InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationGreen.Code);

        // [THEN] Verify different Location must not be allowed in Production Order Line When Location "Warehouse Put-away" is selected on first Line.
        Assert.ExpectedTestFieldError(ProductionOrderLine.FieldCaption("Location Code"), LocationWhite.Code);

        // [WHEN] Insert Production Order Line with Same Location.
        InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationWhite.Code);

        // [THEN] Verify Same Location must be allowed in Production Order Line When Location "Warehouse Put-away" is selected on first Line.
        Assert.AreEqual(
            LocationWhite.Code,
            ProductionOrderLine."Location Code",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrderLine.FieldCaption("Location Code"), LocationWhite.Code, ProductionOrderLine.TableCaption()));

        // [WHEN] Insert Production Order Line with different Location "No Warehouse Handling".
        asserterror InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationGreen.Code);

        // [THEN] Verify Different Location "No Warehouse Handling" must not be allowed in Production Order Line When Location "Warehouse Put-away" is selected on first Line.
        Assert.ExpectedTestFieldError(ProductionOrderLine.FieldCaption("Location Code"), LocationWhite.Code);
    end;

    [Test]
    procedure VerifyWhsePutAwayLocationCannotBeSelectedOnProdOrderLine()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 559653] Verify "Warehouse Put-away" Location must not be allowed in another Production Order Line When "No Warehouse Handling" Location is selected on first line.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationGreen.Validate("Prod. Output Whse. Handling", LocationGreen."Prod. Output Whse. Handling"::"No Warehouse Handling");
        LocationGreen.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationWhite.Validate("Prod. Output Whse. Handling", LocationWhite."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationWhite.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"No Warehouse Handling");
        LocationRed.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationYellow.Validate("Prod. Output Whse. Handling", LocationYellow."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationYellow.Modify();

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, Item2);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationRed.Code, '');

        // [WHEN] Insert Production Order Line with different Location "Warehouse Put-away".
        asserterror InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationWhite.Code);

        // [THEN] Verify different Location "Warehouse Put-away" must not be allowed in Production Order Line When Location "No Warehouse Handling" is selected on first Line.
        Assert.ExpectedTestFieldError(ProductionOrderLine.FieldCaption("Location Code"), LocationRed.Code);

        // [WHEN] Insert Production Order Line with Same Location.
        InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationRed.Code);

        // [THEN] Verify Same Location must be allowed in Production Order Line When Location "No Warehouse Handling" is selected on first Line.
        Assert.AreEqual(
            LocationRed.Code,
            ProductionOrderLine."Location Code",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrderLine.FieldCaption("Location Code"), LocationRed.Code, ProductionOrderLine.TableCaption()));

        // [WHEN] Insert Production Order Line with different Location "No Warehouse Handling".
        InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationGreen.Code);

        // [THEN] Verify different Location "No Warehouse Handling" must be allowed in Production Order Line When Location "No Warehouse Handling" is selected on first Line.
        Assert.AreEqual(
            LocationGreen.Code,
            ProductionOrderLine."Location Code",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrderLine.FieldCaption("Location Code"), LocationGreen.Code, ProductionOrderLine.TableCaption()));
    end;

    [Test]
    procedure VerifyDocumentPutAwayStatusMustBeCompletelyPutAwayInReleasedProductionOrderForSourceTypeFamilyAndFlushingMethodForward()
    var
        Bin: Record Bin;
        Family: Record Family;
        Item: array[3] of Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        FamilyLine: array[3] of Record "Family Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
    begin
        // [SCENARIO 559026] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order When "Source Type" is Family and "Flushing Method" is "Forward".
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Validate("Use Put-away Worksheet", false);
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Forward);

        // [GIVEN] Create three items.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create Family with three items.
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item[2]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[3], Family."No.", Item[3]."No.", 1);

        // [GIVEN] Update "Routing No." in Family. 
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        // [GIVEN] Create and Refresh Production Order with "Source Type" Family.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(ProductionOrder, ProductionOrder.Status::Released, Family."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [GIVEN] Warehouse Put Away Request must be created When "Prod. Output Whse. Handling" is "Warehouse Put-away" on Location.
        WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request should be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNoText,ChangeStatusOnProdOrderOk')]
    procedure VerifyWarehousePutAwayMustBeCreatedForSourceTypeFamilyAndFlushingMethodBackwardWhenStatusIsChanged()
    var
        Bin: Record Bin;
        Family: Record Family;
        Item: array[3] of Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        FamilyLine: array[3] of Record "Family Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 559653] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order When "Source Type" is Family and "Flushing Method" is "Backward".
        // Warehouse Put Away must be created when Changing the status from Released to Finished Production Order.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Backward);

        // [GIVEN] Create three items.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create Family with three items.
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item[2]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[3], Family."No.", Item[3]."No.", 1);

        // [GIVEN] Update "Routing No." in Family. 
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        // [WHEN] Create and Refresh Production Order with "Source Type" Family.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(ProductionOrder, ProductionOrder.Status::Released, Family."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [THEN] Verify Warehouse Put Away Request must not be created with Flushing Method Backward.
        asserterror WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [GIVEN] Open Released Production Order.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Invoke "Change Status" action.
        ReleasedProductionOrder."Change &Status".Invoke();

        // [WHEN] Register Warehouse Activity.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNoText,ChangeStatusOnProdOrderOk')]
    procedure VerifyWarehousePutAwayMustBeCreatedForFlushingMethodBackwardUsingPutAwayWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 559987] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order using "Put Away Worksheet" and "Flushing Method" is "Backward".
        // Warehouse Put Away must be created using "Put Away Worksheet" when Changing the status from Released to Finished Production Order.
        Initialize();

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Validate("Use Put-away Worksheet", true);
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Backward);

        // [GIVEN] Create an tem.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Update "Routing No." in item. 
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [WHEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [THEN] Verify Warehouse Put Away Request must not be created with Flushing Method Backward.
        asserterror WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [GIVEN] Open Released Production Order.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Invoke "Change Status" action.
        ReleasedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, LocationRed.Code, Item."No.", Item."No.", ProductionOrder.Quantity, "Whse. Activity Sorting Method"::None, false);

        // [WHEN] Register Warehouse Activity.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNoText,ChangeStatusOnProdOrderOk')]
    procedure VerifyWarehousePutAwayMustBeCreatedForFamilyAndFlushingMethodForwardWhenStatusIsChangedFromFirmPlannedToReleased()
    var
        Bin: Record Bin;
        Family: Record Family;
        Item: array[3] of Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        FamilyLine: array[3] of Record "Family Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        FirmPlannedProductionOrder: TestPage "Firm Planned Prod. Order";
    begin
        // [SCENARIO 559984] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order When "Source Type" is Family and "Flushing Method" is "Forward".
        // Warehouse Put Away must be created when Changing the status from Firm Planned to Released Production Order.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Validate("Use Put-away Worksheet", false);
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Forward);

        // [GIVEN] Create three items.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItem(Item[3]);

        // [GIVEN] Create Family with three items.
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item[2]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[3], Family."No.", Item[3]."No.", 1);

        // [GIVEN] Update "Routing No." in Family. 
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        // [WHEN] Create and Refresh Production Order with "Source Type" Family.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(ProductionOrder, ProductionOrder.Status::"Firm Planned", Family."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [THEN] Verify Warehouse Put Away Request must not be created with Flushing Method Forward.
        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);

        // [GIVEN] Open Firm Planned Production Order.
        FirmPlannedProductionOrder.OpenEdit();
        FirmPlannedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Invoke "Change Status" action.
        FirmPlannedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Production Order.
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, Family."No.");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Production Orders V");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Production Orders V");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        CreateLocationSetup();

        LibrarySetupStorage.SaveManufacturingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Production Orders V");
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);

        CreateAndUpdateLocation(LocationGreen, false, false, false, false);  // Location Green.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);

        CreateAndUpdateLocation(LocationRed, false, false, false, true);  // Location Red.
        LibraryWarehouse.CreateNumberOfBins(LocationRed.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        CreateAndUpdateLocation(LocationYellow, true, true, false, true);  // Location Yellow.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationYellow.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, false, RequireShipment);
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(Item2);

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateAndCertifiedProductionBOM(ProductionBOMHeader, Item2);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateAndCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshProductionOrderWithSourceTypeFamily(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[20]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Family, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure InsertProdOrderLineWithLocation(var ProductionOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; LineNo: Integer; LocationCode: Code[20])
    begin
        ProductionOrderLine.Init();
        ProductionOrderLine.Status := ProductionOrder.Status;
        ProductionOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProductionOrderLine."Line No." := LineNo;
        ProductionOrderLine.Insert();

        ProductionOrderLine.Validate("Item No.", ProductionOrder."Source No.");
        ProductionOrderLine.Validate("Location Code", LocationCode);
        ProductionOrderLine.Modify();
    end;

    local procedure CreateRoutingWithFlushingMethodRouting(var RoutingHeader: Record "Routing Header"; FlushingMethodRouting: Enum "Flushing Method Routing")
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithWorkCenterFlushingMethod(RoutingLine, RoutingHeader, FlushingMethodRouting);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingLineWithWorkCenterFlushingMethod(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; FlushingMethod: Enum "Flushing Method Routing"): Code[10]
    var
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);

        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        exit(RoutingLine."Operation No.")
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo, SourceDocument, ActionType);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument, ActionType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure CreatePutAwayFromPutAwayWorksheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; QuantityToHandle: Decimal; SortActivity: Enum "Whse. Activity Sorting Method"; BreakBulkFilter: Boolean)
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::"Put-away");
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePutAwayRequest.SetRange("Completely Put Away", false);
        WhsePutAwayRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetInboundSourceDocuments(WhsePutAwayRequest, WhseWorksheetName, LocationCode);
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetFilter("Item No.", ItemNo + '|' + ItemNo2);
        WhseWorksheetLine.FindFirst();

        if QuantityToHandle <> 0 then begin
            WhseWorksheetLine.Validate("Qty. to Handle", QuantityToHandle);
            WhseWorksheetLine.Modify(true);
        end;

        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, SortActivity, false, false, BreakBulkFilter);
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source Type", SourceType);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerNoText(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure ChangeStatusOnProdOrderOk(var ChangeStatusOnProductionOrder: TestPage "Change Status on Prod. Order")
    begin
        ChangeStatusOnProductionOrder.Yes().Invoke();
    end;
}