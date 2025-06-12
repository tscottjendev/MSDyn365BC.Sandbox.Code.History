// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

codeunit 12261 "Service History Subscr. IT"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Inv. Header - Edit", 'OnOnRunOnBeforeTestFieldNo', '', true, true)]
    local procedure OnRunOnBeforeTestFieldNo(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceInvoiceHeaderRec: Record "Service Invoice Header")
    begin
        ServiceInvoiceHeader."Fattura Document Type" := ServiceInvoiceHeaderRec."Fattura Document Type";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Posted Service Inv. - Update", 'OnAfterRecordChanged', '', true, true)]
    local procedure OnAfterRecordChanged(var ServiceInvoiceHeader: Record "Service Invoice Header"; xServiceInvoiceHeader: Record "Service Invoice Header"; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or (ServiceInvoiceHeader."Fattura Document Type" <> xServiceInvoiceHeader."Fattura Document Type");
    end;
}