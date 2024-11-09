namespace Microsoft.Inventory.Item;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000795 "Mfg. Item Integration"
{
    var
        ChangeConfirmationQst: Label 'If you change %1 it may affect existing production orders.\Do you want to change %1?', Comment = '%1 - field caption';
        CannotDeleteDocumentErr: Label 'You cannot delete item variant %1 because there is at least one %2 that includes this Variant Code.', Comment = '%1 - item variant, %2 - document number';
        CannotDeleteProdOrderErr: Label 'You cannot delete item variant %1 because there are one or more outstanding production orders that include this item.', Comment = '%1 - variant code';
        CannotModifyUnitOfMeasureErr: Label 'You cannot modify %1 %2 for item %3 because non-zero %5 with %2 exists in %4.', Comment = '%1 Table name (Item Unit of measure), %2 Value of Measure (KG, PCS...), %3 Item ID, %4 Entry Table Name, %5 Field Caption';

    // Item

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterHasBOM', '', false, false)]
    local procedure OnAfterHasBOM(var Item: Record Item; var Result: Boolean);
    begin
        if Item."Production BOM No." <> '' then
            Result := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckUpdateFieldsForNonInventoriableItem', '', false, false)]
    local procedure OnAfterCheckUpdateFieldsForNonInventoriableItem(var Item: Record Item)
    begin
        Item.Validate("Production BOM No.", '');
        Item.Validate("Routing No.", '');
        Item.Validate("Overhead Rate", 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnValidateGenProdPostingGroupOnConfirmChange', '', false, false)]
    local procedure OnBeforeValidateGenProdPostingGroup(var Item: Record Item; xItemGenProdPostingGroupCode: Code[20]; var ShouldExit: Boolean)
    var
        ConfirmMgt: Codeunit System.Utilities."Confirm Management";
        Question: Text;
    begin
        if ProdOrderExist(Item) then begin
            Question := StrSubstNo(ChangeConfirmationQst, Item.FieldCaption("Gen. Prod. Posting Group"));
            if not ConfirmMgt.GetResponseOrDefault(Question, true) then begin
                Item."Gen. Prod. Posting Group" := xItemGenProdPostingGroupCode;
                ShouldExit := true;
            end;
        end;
    end;

    local procedure ProdOrderExist(var Item: Record Item): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetFilter(Status, '..%1', ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", Item."No.");
        if not ProdOrderLine.IsEmpty() then
            exit(true);

        exit(false);
    end;

    // Inventory Posting Setup

    [EventSubscriber(ObjectType::Table, Database::"Inventory Posting Setup", 'OnAfterSuggestSetupAccount', '', false, false)]
    local procedure OnAfterSuggestSetupAccount(var InventoryPostingSetup: Record "Inventory Posting Setup"; RecRef: RecordRef)
    begin
        if InventoryPostingSetup."WIP Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("WIP Account"));
        if InventoryPostingSetup."Material Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Material Variance Account"));
        if InventoryPostingSetup."Capacity Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Capacity Variance Account"));
        if InventoryPostingSetup."Mfg. Overhead Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Mfg. Overhead Variance Account"));
        if InventoryPostingSetup."Cap. Overhead Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Cap. Overhead Variance Account"));
        if InventoryPostingSetup."Subcontracted Variance Account" = '' then
            InventoryPostingSetup.SuggestAccount(RecRef, InventoryPostingSetup.FieldNo("Subcontracted Variance Account"));
    end;

    // Item Variant

    [EventSubscriber(ObjectType::Table, Database::"Item Variant", 'OnDeleteOnAfterCheck', '', false, false)]
    local procedure ItemVariantOnDeleteOnAfterCheck(var ItemVariant: Record "Item Variant")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetCurrentKey(Type, "No.");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemVariant."Item No.");
        ProductionBOMLine.SetRange("Variant Code", ItemVariant.Code);
        if not ProductionBOMLine.IsEmpty() then
            Error(CannotDeleteDocumentErr, ItemVariant.Code, ProductionBOMLine.TableCaption());

        ProdOrderComponent.SetCurrentKey(Status, "Item No.");
        ProdOrderComponent.SetRange("Item No.", ItemVariant."Item No.");
        ProdOrderComponent.SetRange("Variant Code", ItemVariant.Code);
        if not ProdOrderComponent.IsEmpty() then
            Error(CannotDeleteDocumentErr, ItemVariant.Code, ProdOrderComponent.TableCaption());

        ProdOrderLine.SetCurrentKey(Status, "Item No.");
        ProdOrderLine.SetRange("Item No.", ItemVariant."Item No.");
        ProdOrderLine.SetRange("Variant Code", ItemVariant.Code);
        if not ProdOrderLine.IsEmpty() then
            Error(CannotDeleteProdOrderErr, ItemVariant."Item No.");
    end;

    // Item Unit of Measure

    [EventSubscriber(ObjectType::Table, Database::"Item Unit of Measure", 'OnAfterCheckNoOutstandingQty', '', false, false)]
    local procedure ItemUnitOfMeasureOnAfterCheckNoOutstandingQty(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        CheckNoRemQtyProdOrderLine(ItemUnitOfMeasure, xItemUnitOfMeasure);
        CheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure, xItemUnitOfMeasure);
    end;

    local procedure CheckNoRemQtyProdOrderLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoRemQtyProdOrderLine(ItemUnitOfMeasure, xItemUnitOfMeasure, ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.SetRange("Item No.", ItemUnitOfMeasure."Item No.");
        ProdOrderLine.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProdOrderLine.SetFilter("Remaining Quantity", '<>%1', 0);
        ProdOrderLine.SetFilter(Status, '<>%1', ProdOrderLine.Status::Finished);
        if not ProdOrderLine.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, ItemUnitOfMeasure.TableCaption(), xItemUnitOfMeasure.Code, ItemUnitOfMeasure."Item No.",
              ProdOrderLine.TableCaption(), ProdOrderLine.FieldCaption("Remaining Quantity"));
    end;

    local procedure CheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure, xItemUnitOfMeasure, ProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComponent.SetRange("Item No.", ItemUnitOfMeasure."Item No.");
        ProdOrderComponent.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProdOrderComponent.SetFilter("Remaining Quantity", '<>%1', 0);
        ProdOrderComponent.SetFilter(Status, '<>%1', ProdOrderComponent.Status::Finished);
        if not ProdOrderComponent.IsEmpty() then
            Error(
              CannotModifyUnitOfMeasureErr, ItemUnitOfMeasure.TableCaption(), xItemUnitOfMeasure.Code, ItemUnitOfMeasure."Item No.",
              ProdOrderComponent.TableCaption(), ProdOrderComponent.FieldCaption("Remaining Quantity"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoRemQtyProdOrderLine(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNoRemQtyProdOrderComponent(ItemUnitOfMeasure: Record "Item Unit of Measure"; xItemUnitOfMeasure: Record "Item Unit of Measure"; var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    // Location

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnAfterValidateEvent', 'Use As In-Transit', false, false)]
    local procedure LocationOnAfterValidateEventUseAsInTransit(var Rec: Record Location)
    begin
        if Rec."Use As In-Transit" then begin
            Rec.TestField("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"No Warehouse Handling");
            Rec.TestField("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"No Warehouse Handling");
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnAfterValidateEvent', 'Directed Put-away and Pick', false, false)]
    local procedure LocationOnAfterValidateEventDirectedPutawayandPick(var Rec: Record Location)
    begin
        if Rec."Directed Put-away and Pick" then begin
            Rec."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
            Rec."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterOnDelete(var Rec: Record Location)
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.SetRange("Location Code", Rec.Code);
        if WorkCenter.FindSet(true) then
            repeat
                WorkCenter.Validate("Location Code", '');
                WorkCenter.Modify(true);
            until WorkCenter.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::Location, 'OnGetLocationSetupOnAfterInitLocation', '', false, false)]
    local procedure OnGetLocationSetupOnAfterInitLocation(var Location: Record Location; var Location2: Record Location)
    begin
        case true of
            not Location2."Require Pick" and not Location2."Require Shipment",
            not Location2."Require Pick" and Location2."Require Shipment":
                Location2."Prod. Consump. Whse. Handling" := Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
            Location2."Require Pick" and not Location2."Require Shipment":
                Location2."Prod. Consump. Whse. Handling" := Enum::"Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
            Location2."Require Pick" and Location2."Require Shipment":
                Location2."Prod. Consump. Whse. Handling" := Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        end;

        case true of
            not Location2."Require Put-away" and not Location2."Require Receive",
            not Location2."Require Put-away" and Location2."Require Receive",
            Location2."Require Put-away" and Location2."Require Receive":
                Location2."Prod. Output Whse. Handling" := Enum::"Prod. Output Whse. Handling"::"No Warehouse Handling";
            Location2."Require Put-away" and not Location2."Require Receive":
                Location2."Prod. Output Whse. Handling" := Enum::"Prod. Output Whse. Handling"::"Inventory Put-away";
        end;
    end;

    // Stockkeeping Unit

    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", 'OnAfterValidateEvent', 'Variant Code', false, false)]
    local procedure LocationOnAfterValidateEventVariantCode(var Rec: Record "Stockkeeping Unit")
    begin
        Rec.CalcFields("Qty. on Prod. Order", "Qty. on Component Lines");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", 'OnAfterValidateEvent', 'Location Code', false, false)]
    local procedure LocationOnAfterValidateEventLocationCode(var Rec: Record "Stockkeeping Unit")
    begin
        Rec.CalcFields("Qty. on Prod. Order", "Qty. on Component Lines");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Stockkeeping Unit", 'OnAfterCopyFromItem', '', false, false)]
    local procedure OnAfterCopyFromItem(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item)
    begin
        StockkeepingUnit."Flushing Method" := Item."Flushing Method";
    end;
}
