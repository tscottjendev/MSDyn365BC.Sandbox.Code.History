// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Document;

tableextension 99000761 "Mfg. Location" extends Location
{
    fields
    {
        field(7316; "Prod. Consump. Whse. Handling"; Enum "Prod. Consump. Whse. Handling")
        {
            Caption = 'Prod. Consump. Whse. Handling';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if Rec."Prod. Consump. Whse. Handling" <> xRec."Prod. Consump. Whse. Handling" then
                    CheckInventoryActivityExists(Rec.Code, Database::"Prod. Order Component", Rec.FieldCaption("Prod. Consump. Whse. Handling"));
            end;
        }
        field(7318; "Prod. Output Whse. Handling"; Enum "Prod. Output Whse. Handling")
        {
            Caption = 'Prod. Output Whse. Handling';
            DataClassification = SystemMetadata;
        }
    }
}
