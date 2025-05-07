// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Reports;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Location;

codeunit 99000776 "Mfg. InventoryAdjmtEntryOrder"
{
    var
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text009: Label 'This %1 Order has not been adjusted.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnAfterRoundAmounts', '', false, false)]
    local procedure OnAfterRoundAmounts(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; RndPrecLCY: Decimal; RndPrecACY: Decimal; ShareOfTotalCost: Decimal; RndResLCY: Decimal; RndResACY: Decimal)
    begin
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
            InventoryAdjmtEntryOrder."Direct Cost Non-Inventory" :=
                InventoryAdjmtEntryOrder.RoundCost(InventoryAdjmtEntryOrder."Direct Cost Non-Inventory", ShareOfTotalCost, RndResLCY, RndPrecLCY);
            InventoryAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost" :=
                InventoryAdjmtEntryOrder.RoundCost(InventoryAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost", ShareOfTotalCost, RndResLCY, RndPrecLCY);
            InventoryAdjmtEntryOrder."Direct Cost Non-Inv. (ACY)" :=
                InventoryAdjmtEntryOrder.RoundCost(InventoryAdjmtEntryOrder."Direct Cost Non-Inv. (ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
            InventoryAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)" :=
                InventoryAdjmtEntryOrder.RoundCost(InventoryAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)", ShareOfTotalCost, RndResACY, RndPrecACY);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnGetSingleLevelCostsOnAfterCopyCostsLCY', '', false, false)]
    local procedure OnGetInsgleLevelCostsOnAfterCopyCostsLCY(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; Item: Record Item)
    begin
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
            InventoryAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost" := Item."Single-Lvl Mat. Non-Invt. Cost";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnGetSingleLevelCostsOnAfterCopyCostsACY', '', false, false)]
    local procedure OnGetInsgleLevelCostsOnAfterCopyCostsACY(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; Item: Record Item; CurrExchRate: Decimal)
    begin
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
            InventoryAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)" := InventoryAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost" * CurrExchRate;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnUpdatedFromSKUOnAfterCopyCostFromSKU', '', false, false)]
    local procedure OnUpdatedFromSKUOnAfterCopyCostFromSKU(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
            InventoryAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost" := StockkeepingUnit."Single-Lvl Mat. Non-Invt. Cost";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnAfterCalcUnitCost', '', false, false)]
    local procedure OnAfterCalcUnitCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)")
    begin
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then
            InventoryAdjmtEntryOrder."Unit Cost" += InventoryAdjmtEntryOrder."Direct Cost Non-Inventory";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnAfterCalcDiff', '', false, false)]
    local procedure OnAfterCalcDiff(var InvtAdjmtEntryOrderRec: Record "Inventory Adjmt. Entry (Order)"; var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; OnlyCostShares: Boolean)
    begin
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
            if not OnlyCostShares then begin
                InvtAdjmtEntryOrderRec."Direct Cost Non-Inventory" := InvtAdjmtEntryOrder."Direct Cost Non-Inventory" - InvtAdjmtEntryOrderRec."Direct Cost Non-Inventory";
                InvtAdjmtEntryOrderRec."Direct Cost Non-Inv. (ACY)" := InvtAdjmtEntryOrder."Direct Cost Non-Inv. (ACY)" - InvtAdjmtEntryOrderRec."Direct Cost (ACY)";
            end;
            InvtAdjmtEntryOrderRec."Single-Lvl Mat. Non-Invt. Cost" := InvtAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost" - InvtAdjmtEntryOrderRec."Single-Lvl Mat. Non-Invt. Cost";
            InvtAdjmtEntryOrderRec."Single-Lvl Mat.NonInvCost(ACY)" := InvtAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)" - InvtAdjmtEntryOrderRec."Single-Lvl Mat.NonInvCost(ACY)";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnAddDirectCostNonInv', '', false, false)]
    local procedure OnAddDirectCostNonInv(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
            InventoryAdjmtEntryOrder."Direct Cost Non-Inventory" += CostAmtLCY;
            InventoryAdjmtEntryOrder."Direct Cost Non-Inv. (ACY)" += CostAmtACY;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnAddDirectCostNonInv', '', false, false)]
    local procedure OnAddSingleLvlNonInvMaterialCost(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; CostAmtLCY: Decimal; CostAmtACY: Decimal)
    begin
        if MfgCostCalcMgt.CanIncNonInvCostIntoProductionItem() then begin
            InventoryAdjmtEntryOrder."Single-Lvl Mat. Non-Invt. Cost" += CostAmtLCY;
            InventoryAdjmtEntryOrder."Single-Lvl Mat.NonInvCost(ACY)" += CostAmtACY;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Adjmt. Entry (Order)", 'OnFindProdOrderLine', '', false, false)]
    local procedure OnFindProdOrderLine(var InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; var Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit"; var Found: Boolean)
    var

        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetLoadFields("Prod. Order No.", "Line No.", "Location Code", "Item No.", "Variant Code");
        ProdOrderLine.SetRange("Prod. Order No.", InventoryAdjmtEntryOrder."Order No.");
        ProdOrderLine.SetRange("Line No.", InventoryAdjmtEntryOrder."Order Line No.");
        if not ProdOrderLine.FindFirst() then
            Found := false;

        if not StockkeepingUnit.Get(ProdOrderLine."Location Code", Item."No.", ProdOrderLine."Variant Code") then
            Found := false;

        Found := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Close Inventory Period - Test", 'OnStoreOrderInErrorBuffer', '', false, false)]
    local procedure OnStoreOrderInErrorBuffer(InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; sender: Report "Close Inventory Period - Test")
    var
        ProductionOrder: Record "Production Order";
        RecRef: RecordRef;
        Bookmark: Text[250];
    begin
        case InventoryAdjmtEntryOrder."Order Type" of
            InventoryAdjmtEntryOrder."Order Type"::Production:
                begin
                    ProductionOrder.Get(ProductionOrder.Status::Finished, InventoryAdjmtEntryOrder."Order No.");
                    RecRef.GetTable(ProductionOrder);
                    Bookmark := Format(RecRef.RecordId, 0, 10);
                    sender.StoreItemInErrorBuffer(
                        InventoryAdjmtEntryOrder."Item No.", DATABASE::"Inventory Adjmt. Entry (Order)",
                        StrSubstNo(Text009, InventoryAdjmtEntryOrder."Order Type"), Bookmark, InventoryAdjmtEntryOrder."Order No.",
                        PAGE::"Finished Production Order");
                end;
        end;
    end;
}