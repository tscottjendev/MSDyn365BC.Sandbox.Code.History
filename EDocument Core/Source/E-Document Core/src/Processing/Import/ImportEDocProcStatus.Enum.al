// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Processing.Import;

enum 6100 "Import E-Doc. Proc. Status"
{
    Extensible = false;

    value(0; "Unprocessed")
    {
    }
    value(1; "Readable")
    {
    }
    value(2; "Ready for draft")
    {
    }
    value(3; "Draft Ready")
    {
    }
    value(4; "Processed")
    {
    }
}