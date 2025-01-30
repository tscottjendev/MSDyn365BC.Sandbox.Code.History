// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;
// using System.Azure.DI;
using System.Text;

/// <summary>
/// E-Document OCR Converter
/// Converts a binary unstructured blob to a structured type such as JSON using OCR.
/// </summary>
codeunit 6173 "E-Document OCR Converter" implements IBlobConverter
{
    Access = Internal;
    // TODO: Awaiting uptake in SystemModule. Then uncomment code.

    procedure ConvertToStructuredType(EDocument: Record "E-Document"; Tempblob: Codeunit "Temp Blob"; var Content: Text) NewType: Enum "E-Doc. Data Storage Blob Type"
    var
        Base64Convert: Codeunit "Base64 Convert";
        // AzureDI: Codeunit "Azure DI";
        Instream: InStream;
        Progress: Dialog;
        Data: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        Data := Base64Convert.ToBase64(InStream);
        if GuiAllowed then
            Progress.Open('Processing document with OCR...');
        // Content := AzureDI.AnalyzeInvoice(Data);

        if GuiAllowed then begin
            Progress.Close();
            Message('Document processed with OCR.');
        end;
        NewType := Enum::"E-Doc. Data Storage Blob Type"::JSON;
    end;

}