// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;

table 6100 "E-Document Purchase Header"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "E-Document Entry No."; Integer)
        {
            TableRelation = "E-Document"."Entry No";
            DataClassification = SystemMetadata;
            ValidateTableRelation = true;
        }
        field(10; "Customer Company Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(11; "Customer Company Id"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(12; "Purchase Order No."; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(13; "Sales Invoice No."; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(14; "Invoice Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(15; "Due Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(2431; "Document Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(16; "Vendor Name"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(17; "Vendor Address"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(18; "Vendor Address Recipient"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(19; "Customer Address"; Text[200])
        {
            DataClassification = CustomerContent;
        }
        field(20; "Customer Address Recipient"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(21; "Billing Address"; Text[200])
        {
            DataClassification = CustomerContent;
        }
        field(22; "Billing Address Recipient"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(23; "Shipping Address"; Text[200])
        {
            DataClassification = CustomerContent;
        }
        field(24; "Shipping Address Recipient"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(25; "Sub Total"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(26; "Total Discount"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(27; "Total Tax"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(28; "Total"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(29; "Amount Due"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(30; "Previous Unpaid Balance"; Decimal)
        {
            DataClassification = CustomerContent;
        }
        field(41; "Currency Code"; Code[10])
        {
            DataClassification = CustomerContent;
        }
        field(31; "Remittance Address"; Text[200])
        {
            DataClassification = CustomerContent;
        }
        field(32; "Remittance Address Recipient"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(33; "Service Address"; Text[200])
        {
            DataClassification = CustomerContent;
        }
        field(34; "Service Address Recipient"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(35; "Service Start Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(36; "Service End Date"; Date)
        {
            DataClassification = CustomerContent;
        }
        field(37; "Vendor Tax Id"; Text[20])
        {
            DataClassification = CustomerContent;
        }
        field(38; "Customer Tax Id"; Text[100])
        {
            DataClassification = CustomerContent;
        }
        field(39; "Payment Terms"; Text[150])
        {
            DataClassification = CustomerContent;
        }
        field(47; "Customer GLN"; Text[13])
        {
            DataClassification = CustomerContent;
            Caption = 'Global Location Number';
        }
        field(48; "Vendor GLN"; Text[13])
        {
            DataClassification = CustomerContent;
            Caption = 'Global Location Number';
        }
    }
    keys
    {
        key(PK; "E-Document Entry No.")
        {
            Clustered = true;
        }
    }
}