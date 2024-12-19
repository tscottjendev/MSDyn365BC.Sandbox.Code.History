// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

table 764 "Fin. Report Excel Template"
{
    Caption = 'Financial Report Excel Template';
    DataClassification = CustomerContent;
    LookupPageId = "Fin. Report Excel Templates";

    fields
    {
        field(1; "Financial Report Name"; Code[10])
        {
            Caption = 'Financial Report Name';
            ToolTip = 'Specifies the name of the financial report.';
            DataClassification = CustomerContent;
            TableRelation = "Financial Report";
            NotBlank = true;
        }
        field(2; Code; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code of the template.';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description.';
            DataClassification = CustomerContent;
        }
        field(4; Template; Blob)
        {
            Caption = 'Template';
            ToolTip = 'Specifies the Excel template file.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Financial Report Name", Code)
        {
            Clustered = true;
        }
    }
}