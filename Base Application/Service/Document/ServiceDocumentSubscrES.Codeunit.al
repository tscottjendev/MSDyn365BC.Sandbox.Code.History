// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;

codeunit 10763 "Service Document Subscr. ES"
{
    var
        SIIManagement: Codeunit "SII Management";

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnValidateBillToCustomerNoOnAfterSetFilters', '', true, true)]
    local procedure OnValidateBillToCustomerNoOnAfterSetFilters(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header")
    begin
        if xServiceHeader."Bill-to Customer No." <> ServiceHeader."Bill-to Customer No." then
            ServiceHeader."Corrected Invoice No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateBillToCustomerNo', '', true, true)]
    local procedure OnAfterValidateBillToCustomerNo(var ServiceHeader: Record "Service Header"; var xServiceHeader: Record "Service Header"; var Customer: Record Customer)
    begin
        ServiceHeader.Validate(
            "ID Type",
            SIIManagement.GetSalesIDType(ServiceHeader."Bill-to Customer No.", ServiceHeader."Correction Type", ServiceHeader."Corrected Invoice No."));
        SIIManagement.UpdateSIIInfoInServiceDoc(ServiceHeader);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterValidateAppliesToDocNo', '', true, true)]
    local procedure OnAfterValidateAppliesToDocNo(var ServiceHeader: Record "Service Header"; xServiceHeader: Record "Service Header"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        ServiceHeader."Applies-to Bill No." := CustLedgEntry."Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnValidateAppliestoDocNoOnAfterSetFilters', '', true, true)]
    local procedure OnValidateAppliestoDocNoOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry"; var ServiceHeader: Record "Service Header")
    begin
        if (ServiceHeader."Applies-to Doc. No." <> '') and (ServiceHeader."Applies-to Bill No." <> '') then begin
            CustLedgerEntry.SetRange("Bill No.", ServiceHeader."Applies-to Bill No.");
            if CustLedgerEntry.FindFirst() then;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyAppliestoFieldsFromCustLedgerEntry', '', true, true)]
    local procedure OnAfterCopyAppliestoFieldsFromCustLedgerEntry(var ServiceHeader: Record "Service Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        ServiceHeader."Applies-to Bill No." := CustLedgerEntry."Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyBillToCustomerFields', '', true, true)]
    local procedure OnAfterCopyBillToCustomerFields(var ServiceHeader: Record "Service Header"; Customer: Record Customer; SkipBillToContact: Boolean)
    begin
        ServiceHeader."Cust. Bank Acc. Code" := Customer."Preferred Bank Account Code";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyToGenJnlLine', '', true, true)]
    local procedure OnAfterCopyToGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
        GenJournalLine."Payment Terms Code" := ServiceHeader."Payment Terms Code";
        GenJournalLine."Payment Method Code" := ServiceHeader."Payment Method Code";
        GenJournalLine."Correction Type" := ServiceHeader."Correction Type";
        GenJournalLine."Corrected Invoice No." := ServiceHeader."Corrected Invoice No.";
        GenJournalLine."Sales Invoice Type" := ServiceHeader."Invoice Type";
        GenJournalLine."Sales Cr. Memo Type" := ServiceHeader."Cr. Memo Type";
        GenJournalLine."Sales Special Scheme Code" := ServiceHeader."Special Scheme Code";
        GenJournalLine."Succeeded Company Name" := ServiceHeader."Succeeded Company Name";
        GenJournalLine."Succeeded VAT Registration No." := ServiceHeader."Succeeded VAT Registration No.";
        GenJournalLine."Issued By Third Party" := ServiceHeader."Issued By Third Party";

        ServiceHeader.SetSIIFirstSummaryDocNo(ServiceHeader.GetSIIFirstSummaryDocNo());
        ServiceHeader.SetSIILastSummaryDocNo(ServiceHeader.GetSIILastSummaryDocNo());

        GenJournalLine."Do Not Send To SII" := ServiceHeader."Do Not Send To SII";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterCopyToGenJnlLineApplyTo', '', true, true)]
    local procedure OnAfterCopyToGenJnlLineApplyTo(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
        GenJournalLine."Applies-to Bill No." := ServiceHeader."Applies-to Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnAfterInitRecord', '', true, true)]
    local procedure OnAfterInitRecord(var ServiceHeader: Record "Service Header")
    begin
        SIIManagement.UpdateSIIInfoInServiceDoc(ServiceHeader);
    end;
}