// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;

table 6101 "E-Document Purchase Line"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "E-Document Line Id"; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "E-Document Entry No."; Integer)
        {
            TableRelation = "E-Document"."Entry No";
            DataClassification = SystemMetadata;
        }
        field(3; "Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(4; "Product Code"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(5; "Description"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(6; "Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(7; "Unit of Measure"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(8; "Unit Price"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(9; "Amount"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(10; "Tax"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(11; "Tax Rate"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(12; "Currency Code"; Code[10])
        {
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