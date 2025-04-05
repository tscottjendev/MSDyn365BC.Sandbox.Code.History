// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Availability;

codeunit 99000873 "Mfg. Create Pick"
{
    var
        CreatePickParameters: Record "Create Pick Parameters";
        FeatureTelemetry: Codeunit System.Telemetry."Feature Telemetry";
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Project Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Project Whse. Handling in used for warehouse pick.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnAfterCheckOutBound', '', false, false)]
    local procedure OnAfterCheckOutBound(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var OutBoundQty: Decimal; SourceSubLineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case SourceType of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.SetRange(Status, SourceSubType);
                    ProdOrderComponent.SetRange("Prod. Order No.", SourceNo);
                    ProdOrderComponent.SetRange("Prod. Order Line No.", SourceSubLineNo);
                    ProdOrderComponent.SetRange("Line No.", SourceLineNo);
                    ProdOrderComponent.SetAutoCalcFields("Pick Qty. (Base)");
                    ProdOrderComponent.SetLoadFields("Pick Qty. (Base)", "Qty. Picked (Base)");
                    if ProdOrderComponent.FindFirst() then
                        OutBoundQty := ProdOrderComponent."Pick Qty. (Base)" + ProdOrderComponent."Qty. Picked (Base)"
                    else
                        OutBoundQty := 0;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnCalcAvailableQtyOnGetLineReservedQty', '', false, false)]
    local procedure OnCalcAvailableQtyOnGetLineReservedQty(WhseSource2: Option; CurrSourceSubType: Integer; CurrSourceNo: Code[20]; CurrSourceLineNo: Integer; CurrSourceSubLineNo: Integer; var LineReservedQty: Decimal; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary);
    var
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
    begin
        case WhseSource2 of
            CreatePickParameters."Whse. Document"::Production:
                LineReservedQty :=
                  WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                    Database::"Prod. Order Component", CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, true, TempWarehouseActivityLine);
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnFindToBinCodeForCustomWhseSource', '', false, false)]
    local procedure OnFindToBinCodeForCustomWhseSource(WhseSource2: Option; CurrSourceType: Integer; CurrSourceSubType: Integer; CurrSourceNo: Code[20]; CurrSourceLineNo: Integer; CurrSourceSubLineNo: Integer; var ToBinCode: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WhseSource2 of
            CreatePickParameters."Whse. Document"::Assembly:
                begin
                    ProdOrderComponent.Get(CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo);
                    ToBinCode := ProdOrderComponent."Bin Code";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnRunFindBWPickBinLoopOnAfterCheckWhseHandling', '', false, false)]
    local procedure OnRunFindBWPickBinLoopOnAfterCheckWhseHandling(CurrSourceType: Integer; CurrLocation: Record Location; var ShouldExit: Boolean)
    begin
        if (CurrSourceType = Database::"Prod. Order Component") and (CurrLocation.Code <> '') then begin
            FeatureTelemetry.LogUsage('0000KT5', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
            if not (CurrLocation."Prod. Consump. Whse. Handling" in [CurrLocation."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", CurrLocation."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)"]) then
                exit;
        end;
    end;
}