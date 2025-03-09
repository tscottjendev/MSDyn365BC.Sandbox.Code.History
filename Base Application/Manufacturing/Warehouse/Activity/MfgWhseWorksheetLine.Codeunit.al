namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Manufacturing.Document;

codeunit 99000767 "Mfg. Whse. Worksheet Line"
{
    [EventSubscriber(ObjectType::Table, Database::"Whse. Worksheet Line", 'OnUpdateQtyHandledForProdOrderOutput', '', false, false)]
    local procedure OnUpdateQtyHandledForProdOrderOutput(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(WhseWorksheetLine."Source Subtype", WhseWorksheetLine."Source No.", WhseWorksheetLine."Source Line No.");
        ProdOrderLine.CalcFields("Put-away Qty. (Base)");

        if ProdOrderLine."Finished Quantity" = WhseWorksheetLine."Qty. Handled" then
            WhseWorksheetLine.Validate("Qty. Outstanding", 0)
        else
            WhseWorksheetLine.Validate("Qty. Outstanding", ProdOrderLine."Finished Qty. (Base)" - (ProdOrderLine."Qty. Put Away (Base)" + ProdOrderLine."Put-away Qty. (Base)"));
    end;
}