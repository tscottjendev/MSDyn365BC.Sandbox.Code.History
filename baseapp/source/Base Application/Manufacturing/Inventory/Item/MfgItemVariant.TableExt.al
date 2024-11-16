// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

tableextension 99000753 "Mfg. Item Variant" extends "Item Variant"
{
    fields
    {
        field(8020; "Production Blocked"; Boolean)
        {
            Caption = 'Production Blocked';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies that the item variant cannot be entered on production documents, except requisition worksheet, planning worksheet and journals.';
        }
    }
}