#if not CLEANSCHEMA15
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

tableextension 11309 "Service Line BE" extends "Service Line"
{
    fields
    {
        field(11302; "Pmt. Discount Amount (Old)"; Decimal)
        {
            Caption = 'Pmt. Discount Amount (Old)';
            DataClassification = SystemMetadata;
            Editable = false;
            ObsoleteReason = 'Merged to W1';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
    }
}
#endif