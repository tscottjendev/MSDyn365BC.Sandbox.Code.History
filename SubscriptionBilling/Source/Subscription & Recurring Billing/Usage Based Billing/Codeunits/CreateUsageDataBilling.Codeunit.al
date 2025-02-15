namespace Microsoft.SubscriptionBilling;

using System.Utilities;

codeunit 8023 "Create Usage Data Billing"
{
    Access = Internal;
    TableNo = "Usage Data Import";

    var
        UsageDataProcessing: Interface "Usage Data Processing";

    trigger OnRun()
    begin
        UsageDataImport.Copy(Rec);
        Code();
        Rec := UsageDataImport;
    end;

    local procedure Code()
    begin
        UsageDataImport.SetFilter("Processing Status", '<>%1', Enum::"Processing Status"::Closed);
        if UsageDataImport.FindSet() then
            repeat
                CheckRetryFailedUsageLines();
                if not RetryFailedUsageDataImport then
                    TestUsageDataImport();
                if not (UsageDataImport."Processing Status" = "Processing Status"::Error) then
                    FindAndProcessUsageDataImport();
                if not (UsageDataImport."Processing Status" = "Processing Status"::Error) then
                    SetUsageDataImportError();
            until UsageDataImport.Next() = 0;
    end;

    local procedure CheckRetryFailedUsageLines()
    var
        UsageDataBilling: Record "Usage Data Billing";
    begin
        UsageDataBilling.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        if not UsageDataBilling.IsEmpty() then
            if GuiAllowed then
                if ConfirmManagement.GetResponse(StrSubstNo(RetryFailedUsageDataImportTxt, UsageDataImport."Entry No."), false) then
                    RetryFailedUsageDataImport := true;
    end;

    local procedure FindAndProcessUsageDataImport()
    begin
        UsageDataProcessing.FindAndProcessUsageDataImport(UsageDataImport);
    end;

    internal procedure CollectServiceCommitments(var TempServiceCommitment: Record "Service Commitment" temporary; ServiceObjectNo: Code[20]; SubscriptionEndDate: Date)
    begin
        FillTempServiceCommitment(TempServiceCommitment, ServiceObjectNo, SubscriptionEndDate);
    end;

    internal procedure CreateUsageDataBillingFromTempServiceCommitments(var TempServiceCommitment: Record "Service Commitment"; SupplierNo: Code[20]; UsageDataImportEntryNo: Integer; ServiceObjectNo: Code[20]; BillingPeriodStartDate: Date;
                        BillingPeriodEndDate: Date; UnitCost: Decimal; NewQuantity: Decimal; CostAmount: Decimal; UnitPrice: Decimal; NewAmount: Decimal; CurrencyCode: Code[10])
    begin
        repeat
            CreateUsageDataBillingFromTempServiceCommitment(TempServiceCommitment, SupplierNo, UsageDataImportEntryNo, ServiceObjectNo, BillingPeriodStartDate, BillingPeriodEndDate, UnitCost, NewQuantity, CostAmount, UnitPrice, NewAmount, CurrencyCode);
        until TempServiceCommitment.Next() = 0;
        OnAfterCreateUsageDataBillingFromTempServiceCommitments(TempServiceCommitment);
    end;

    local procedure CreateUsageDataBillingFromTempServiceCommitment(var TempServiceCommitment: Record "Service Commitment"; SupplierNo: Code[20]; UsageDataImportEntryNo: Integer; ServiceObjectNo: Code[20]; BillingPeriodStartDate: Date;
                        BillingPeriodEndDate: Date; UnitCost: Decimal; NewQuantity: Decimal; CostAmount: Decimal; UnitPrice: Decimal; NewAmount: Decimal; CurrencyCode: Code[10])
    var
        UsageDataBilling: Record "Usage Data Billing";
        UsageDataSupplier: Record "Usage Data Supplier";
    begin
        UsageDataSupplier.Get(SupplierNo);

        UsageDataBilling.InitFrom(UsageDataImportEntryNo, ServiceObjectNo, BillingPeriodStartDate, BillingPeriodEndDate, UnitCost, NewQuantity, CostAmount, UnitPrice, NewAmount, CurrencyCode);
        UsageDataBilling."Supplier No." := SupplierNo;
        UsageDataBilling."Service Object No." := TempServiceCommitment."Service Object No.";
        UsageDataBilling.Partner := TempServiceCommitment.Partner;
        UsageDataBilling."Contract No." := TempServiceCommitment."Contract No.";
        UsageDataBilling."Contract Line No." := TempServiceCommitment."Contract Line No.";
        UsageDataBilling."Service Object No." := TempServiceCommitment."Service Object No.";
        UsageDataBilling."Service Commitment Entry No." := TempServiceCommitment."Entry No.";
        UsageDataBilling."Service Commitment Description" := TempServiceCommitment.Description;
        UsageDataBilling."Usage Base Pricing" := TempServiceCommitment."Usage Based Pricing";
        UsageDataBilling."Pricing Unit Cost Surcharge %" := TempServiceCommitment."Pricing Unit Cost Surcharge %";
        if UsageDataBilling.IsPartnerVendor() or not UsageDataSupplier."Unit Price from Import" then begin
            UsageDataBilling."Unit Price" := 0;
            UsageDataBilling.Amount := 0;
        end;
        UsageDataBilling.UpdateRebilling();
        UsageDataBilling."Entry No." := 0;
        UsageDataBilling.Insert(true);
        UsageDataBilling.InsertMetadata();

        OnAfterCreateUsageDataBillingFromTempServiceCommitment(TempServiceCommitment, UsageDataBilling);
    end;

    local procedure FillTempServiceCommitment(var TempServiceCommitment: Record "Service Commitment" temporary; ServiceObjectNo: Code[20]; SubscriptionEndDate: Date)
    var
        ServiceCommitment: Record "Service Commitment";
    begin
        TempServiceCommitment.Reset();
        TempServiceCommitment.DeleteAll(false);
        ServiceCommitment.SetRange("Service Object No.", ServiceObjectNo);
        ServiceCommitment.SetFilter("Service End Date", '>=%1|%2', SubscriptionEndDate, 0D);
        ServiceCommitment.SetRange("Usage Based Billing", true);
        if ServiceCommitment.FindSet() then
            repeat
                if not TempServiceCommitment.Get(ServiceCommitment."Entry No.") then begin
                    TempServiceCommitment := ServiceCommitment;
                    TempServiceCommitment.Insert(false);
                end;
            until ServiceCommitment.Next() = 0;
    end;

    local procedure TestUsageDataImport()
    var
        UsageDataSupplier: Record "Usage Data Supplier";
    begin
        UsageDataSupplier.Get(UsageDataImport."Supplier No.");
        UsageDataProcessing := UsageDataSupplier.Type;
        UsageDataProcessing.TestUsageDataImport(UsageDataImport);
    end;

    local procedure SetUsageDataImportError()
    begin
        UsageDataProcessing.SetUsageDataImportError(UsageDataImport);
    end;

    internal procedure GetRetryFailedUsageDataImport(): Boolean
    begin
        exit(RetryFailedUsageDataImport);
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterCreateUsageDataBillingFromTempServiceCommitment(var TempServiceCommitment: Record "Service Commitment"; var UsageDataBilling: Record "Usage Data Billing")
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterCreateUsageDataBillingFromTempServiceCommitments(var TempServiceCommitment: Record "Service Commitment")
    begin
    end;

    var
        UsageDataImport: Record "Usage Data Import";
        ConfirmManagement: Codeunit "Confirm Management";
        RetryFailedUsageDataImportTxt: Label 'Usage Data Billing for Import %1 already exist. Do you want to try to create new entries for the failed Usage Data Generic Import only?';
        RetryFailedUsageDataImport: Boolean;
}
