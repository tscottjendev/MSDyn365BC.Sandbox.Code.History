// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.eServices.EDocument.Processing.Import;

/// <summary>
/// E-Document Data Storage Blob Type
/// This enum specifies the type of the binary data stored in the E-Document Data Storage table.
/// </summary>
enum 6109 "E-Doc. Data Storage Blob Type" implements IBlobConverter
{
    Access = Public;
    Extensible = true;
    DefaultImplementation = IBlobConverter = "E-Doc. No Blob Conversion";

    value(0; "Unspecified")
    {
        Caption = 'Unspecified';
    }
    value(1; "PDF")
    {
        Caption = 'PDF';
        Implementation = IBlobConverter = "E-Document OCR Converter";
    }
    value(2; "XML")
    {
        Caption = 'XML';
    }
    value(3; "JSON")
    {
        Caption = 'JSON';
    }
}