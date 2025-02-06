// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Processing.Import;

enum 6114 "Import E-Document Steps"
{
    Access = Internal;
    Extensible = false;

    // Unprocessed
    value(0; "Structure received data")
    {
    }
    // Readable
    value(1; "Read into IR")
    {
    }
    // Ready for draft
    value(2; "Prepare draft")
    {
    }
    // Draft ready
    value(3; "Finish draft")
    {
    }
    // Processed
}