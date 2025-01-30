// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using System.Utilities;
using Microsoft.eServices.EDocument;

/// <summary>
/// Interfaces defines how to convert a blob to a structured type.
/// </summary>
interface IBlobConverter
{
    procedure ConvertToStructuredType(EDocument: Record "E-Document"; Tempblob: Codeunit "Temp Blob"; var Content: Text) NewType: Enum "E-Doc. Data Storage Blob Type"

}