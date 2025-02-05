// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;

/// <summary>
/// Describe the data processing used to assign Business Central values to the E-Document data structures
/// </summary>
interface IProcessStructuredData
{

    /// <summary>
    /// Get the supported processing type for the machine readable format.
    /// </summary>
    procedure Process(var EDocument: Record "E-Document");

}
