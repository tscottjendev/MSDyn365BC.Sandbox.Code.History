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
        field(13; "Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(16; "Product Code"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(14; "Description"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(15; "Quantity"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(20; "Unit of Measure"; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(21; "Unit Price"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(11; "Amount"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(17; "Tax"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(19; "Tax Rate"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(18; "Currency Code"; Code[10])
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