namespace Microsoft.Service.History;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Receivables;

codeunit 10762 "Service History Subscr. ES"
{

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Header", 'OnLookupAppliestoDocNoOnAfterSetFilters', '', true, true)]
    local procedure CreditMemoOnLookupAppliestoDocNoOnAfterSetFilters(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Bill No.", ServiceCrMemoHeader."Applies-to Bill No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', true, true)]
    local procedure CreditMemoOnCalcVATAmountLinesOnBeforeInsertLine(ServiceCrMemoHeader: Record "Service Cr.Memo Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        if ServiceCrMemoHeader."Prices Including VAT" then
            TempVATAmountLine."Prices Including VAT" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnAfterCopyToVATAmountLine', '', true, true)]
    local procedure CreditMemoOnAfterCopyToVATAmountLine(ServiceCrMemoLine: Record "Service Cr.Memo Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."EC %" := ServiceCrMemoLine."EC %";
        VATAmountLine."EC Difference" := ServiceCrMemoLine."EC Difference";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Cr.Memo Line", 'OnAfterGetVATPct', '', true, true)]
    local procedure CreditMemoOnAfterGetVATPct(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; var VATPct: Decimal)
    begin
        VATPct += ServiceCrMemoLine."EC %";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Header", 'OnLookupAppliestoDocNoOnAfterSetFilters', '', true, true)]
    local procedure InvoiceOnLookupAppliestoDocNoOnAfterSetFilters(ServiceInvoiceHeader: Record "Service Invoice Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange("Bill No.", CustLedgerEntry."Applies-to Bill No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnCalcVATAmountLinesOnBeforeInsertLine', '', true, true)]
    local procedure InvoiceOnCalcVATAmountLinesOnBeforeInsertLine(ServInvHeader: Record "Service Invoice Header"; var TempVATAmountLine: Record "VAT Amount Line" temporary)
    begin
        if ServInvHeader."Prices Including VAT" then
            TempVATAmountLine."Prices Including VAT" := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnAfterCopyToVATAmountLine', '', true, true)]
    local procedure InvoiceOnAfterCopyToVATAmountLine(ServiceInvoiceLine: Record "Service Invoice Line"; var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine."EC %" := ServiceInvoiceLine."EC %";
        VATAmountLine."EC Difference" := ServiceInvoiceLine."EC Difference";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Invoice Line", 'OnAfterGetVATPct', '', true, true)]
    local procedure InvoiceOnAfterGetVATPct(var ServiceInvoiceLine: Record "Service Invoice Line"; var VATPct: Decimal)
    begin
        VATPct += ServiceInvoiceLine."EC %";
    end;



}