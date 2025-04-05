// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Availability;

codeunit 973 "Asm. Create Pick"
{
    var
        CreatePickParameters: Record "Create Pick Parameters";
        FeatureTelemetry: Codeunit System.Telemetry."Feature Telemetry";
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Project Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Project Whse. Handling in used for warehouse pick.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnAfterCheckOutBound', '', false, false)]
    local procedure OnAfterCheckOutBound(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var OutBoundQty: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case SourceType of
            Database::"Assembly Line":
                begin
                    AssemblyLine.SetAutoCalcFields("Pick Qty. (Base)");
                    AssemblyLine.SetLoadFields("Pick Qty. (Base)", "Qty. Picked (Base)");
                    if AssemblyLine.Get(SourceSubType, SourceNo, SourceLineNo) then
                        OutBoundQty := AssemblyLine."Pick Qty. (Base)" + AssemblyLine."Qty. Picked (Base)"
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
            CreatePickParameters."Whse. Document"::Assembly:
                LineReservedQty :=
                    WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                        Database::"Assembly Line", CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, 0, true, TempWarehouseActivityLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnFindToBinCodeForCustomWhseSource', '', false, false)]
    local procedure OnFindToBinCodeForCustomWhseSource(WhseSource2: Option; CurrSourceType: Integer; CurrSourceSubType: Integer; CurrSourceNo: Code[20]; CurrSourceLineNo: Integer; CurrSourceSubLineNo: Integer; var ToBinCode: Code[20])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case WhseSource2 of
            CreatePickParameters."Whse. Document"::Assembly:
                begin
                    AssemblyLine.Get(CurrSourceSubType, CurrSourceNo, CurrSourceLineNo);
                    ToBinCode := AssemblyLine."Bin Code";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnRunFindBWPickBinLoopOnAfterCheckWhseHandling', '', false, false)]
    local procedure OnRunFindBWPickBinLoopOnAfterCheckWhseHandling(CurrSourceType: Integer; CurrLocation: Record Location; var ShouldExit: Boolean)
    begin
        if (CurrSourceType = Database::"Assembly Line") and (CurrLocation.Code <> '') then begin
            FeatureTelemetry.LogUsage('0000KT6', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
            if not (CurrLocation."Asm. Consump. Whse. Handling" in [CurrLocation."Asm. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", CurrLocation."Asm. Consump. Whse. Handling"::"Warehouse Pick (optional)"]) then
                ShouldExit := true;
        end;
    end;
}