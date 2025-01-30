// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using System.Utilities;

/// <summary>
/// E-Document No Blob Conversion
/// This codeunit is default implementation of the IBlobConverter interface.
/// </summary>
codeunit 6172 "E-Doc. No Blob Conversion" implements IBlobConverter
{
    Access = Internal;

    procedure ConvertToStructuredType(EDocument: Record "E-Document"; Tempblob: Codeunit "Temp Blob"; var Content: Text) NewType: Enum "E-Doc. Data Storage Blob Type"
    begin
        Content := '';
        NewType := Enum::"E-Doc. Data Storage Blob Type"::Unspecified;
    end;

}