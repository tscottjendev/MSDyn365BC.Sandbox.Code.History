// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;

tableextension 99000757 "Mfg. Item Templ." extends "Item Templ."
{
    fields
    {
        field(5417; "Flushing Method"; Enum "Flushing Method")
        {
            AccessByPermission = TableData "Production Order" = R;
            Caption = 'Flushing Method';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Flushing Method"));
            end;
        }
        field(99000750; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Routing No."));
            end;
        }
        field(99000751; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            DataClassification = CustomerContent;
            TableRelation = "Production BOM Header";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Production BOM No."));
            end;
        }
        field(99000773; "Order Tracking Policy"; Enum "Order Tracking Policy")
        {
            Caption = 'Order Tracking Policy';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Order Tracking Policy"));
            end;
        }
        field(99000875; Critical; Boolean)
        {
            Caption = 'Critical';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Critical));
            end;
        }
        field(99008500; "Common Item No."; Code[20])
        {
            Caption = 'Common Item No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Common Item No."));
            end;
        }
    }
}