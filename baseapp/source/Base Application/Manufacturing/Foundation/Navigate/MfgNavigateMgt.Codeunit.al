// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;

codeunit 99000994 "Mfg. Navigate Mgt."
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        CapacityLedgEntry: Record "Capacity Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ProductionOrderHeader: Record "Production Order";

        ProductionOrderTxt: Label 'Production Order';

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindPostedDocuments', '', false, false)]
    local procedure OnAfterFindPostedDocuments(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindProdOrderHeader(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindProdOrderHeader(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ProductionOrderHeader.ReadPermission() then begin
            SetProdOrderFilters(DocNoFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Production Order", ProductionOrderTxt, ProductionOrderHeader.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindLedgerEntries', '', false, false)]
    local procedure OnAfterFindLedgerEntries(var DocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindCapacityEntries(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindCapacityEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if CapacityLedgEntry.ReadPermission() then begin
            SetCapacityLedgerEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Capacity Ledger Entry", CapacityLedgEntry.TableCaption(), CapacityLedgEntry.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            Database::"Production Order":
                PAGE.Run(0, ProductionOrderHeader);
            Database::"Capacity Ledger Entry":
                PAGE.Run(0, CapacityLedgEntry);
        end;
    end;

    local procedure SetProdOrderFilters(DocNoFilter: Text)
    begin
        ProductionOrderHeader.Reset();
        ProductionOrderHeader.SetRange(
            Status,
            ProductionOrderHeader.Status::Released,
            ProductionOrderHeader.Status::Finished);
        ProductionOrderHeader.SetFilter("No.", DocNoFilter);
    end;

    local procedure SetCapacityLedgerEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        CapacityLedgEntry.Reset();
        CapacityLedgEntry.SetCurrentKey("Document No.", "Posting Date");
        CapacityLedgEntry.SetFilter("Document No.", DocNoFilter);
        CapacityLedgEntry.SetFilter("Posting Date", PostingDateFilter);
    end;
}