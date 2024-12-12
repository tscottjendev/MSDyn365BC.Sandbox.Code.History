codeunit 99000750 ProdOrderChangeStatusBulk
{
    TableNo = "Production Order";

    trigger OnRun()
    var
        ProdOrderStatusMgt: Codeunit "Prod. Order Status Management";
    begin
        ProdOrderStatusMgt.ChangeProdOrderStatus(Rec, NewProductionOrderStatus, NewPostingDate, NewUpdateUnitCost);
    end;

    internal procedure SetParameters(Status: Enum "Production Order Status"; PostingDate: Date; UpdateUnitCost: Boolean)
    begin
        NewProductionOrderStatus := Status;
        NewPostingDate := PostingDate;
        NewUpdateUnitCost := UpdateUnitCost;
    end;

    var
        NewProductionOrderStatus: Enum "Production Order Status";
        NewPostingDate: Date;
        NewUpdateUnitCost: Boolean;
}