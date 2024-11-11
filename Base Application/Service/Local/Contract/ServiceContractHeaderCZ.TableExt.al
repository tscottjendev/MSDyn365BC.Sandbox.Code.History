// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

tableextension 11800 "Service Contract Header CZ" extends "Service Contract Header"
{
    fields
    {
#if not CLEANSCHEMA18
        field(11792; "Original User ID"; Code[50])
        {
            Caption = 'Original User ID';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteState = Removed;
            ObsoleteReason = 'This field is not needed and it should not be used.';
            ObsoleteTag = '18.0';
        }
#endif
    }
}
