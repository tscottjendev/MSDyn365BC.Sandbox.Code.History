// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import;

using Microsoft.Purchases.Document;
using Microsoft.Utilities;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Item;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Projects.Resources.Resource;

table 6105 "E-Document Line Mapping"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    fields
    {
        field(1; "E-Document Line Id"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "Purchase Line Type"; Enum "Purchase Line Type")
        {
            Caption = 'Purchase Line Type';
            DataClassification = CustomerContent;
        }
        field(3; "Purchase Type No."; Code[20])
        {
            Caption = 'Purchase Type No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Purchase Line Type" = const(" ")) "Standard Text"
            else
            if ("Purchase Line Type" = const("G/L Account")) "G/L Account"
            else
            if ("Purchase Line Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Purchase Line Type" = const("Charge (Item)")) "Item Charge"
            else
            if ("Purchase Line Type" = const(Item)) Item
            else
            if ("Purchase Line Type" = const("Allocation Account")) "Allocation Account"
            else
            if ("Purchase Line Type" = const(Resource)) Resource;
        }
        field(4; "Unit of Measure"; Code[20])
        {
            Caption = 'Unit of Measure';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "E-Document Line Id")
        {
            Clustered = true;
        }
    }
}