// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

tableextension 11810 "Location CZ" extends Location
{
    fields
    {
        field(31070; "Area"; Code[10])
        {
            Caption = 'Area';
            DataClassification = CustomerContent;
            ObsoleteReason = 'The functionality will be removed and this field should not be used.';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
    }
}