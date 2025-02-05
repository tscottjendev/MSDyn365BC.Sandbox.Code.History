// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;

/// <summary>
/// Implementation of the E-Document Purchase Data Flow.
/// Processes the E-Document data structures for a purchase document.
/// </summary>
codeunit 6106 "E-Doc. Process Purchase Data" implements IProcessStructuredData
{
    Access = Internal;

    procedure Process(var EDocument: Record "E-Document")
    begin
    end;

}
