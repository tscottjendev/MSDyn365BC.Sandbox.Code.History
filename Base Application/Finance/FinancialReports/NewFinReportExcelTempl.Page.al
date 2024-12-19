// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 787 "New Fin. Report Excel Templ."
{
    Caption = 'Add New Financial Report Excel Template';
    PageType = StandardDialog;
    Extensible = false;
    SourceTable = "Fin. Report Excel Template";
    SourceTableTemporary = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            field("Financial Report Name"; Rec."Financial Report Name")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
            }
            field(CodeToCopy; CodeToCopy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy From Code';
                ToolTip = 'Specifies the code of the existing template to copy from.';
                Visible = CodeToCopy <> '';
                Editable = false;
            }
            field(NewCode; NewCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Code';
                ToolTip = 'Specifies the code of the new template.';
                ShowMandatory = true;
            }
            field(Description; Rec.Description)
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::Ok then begin
            if NewCode = '' then
                Error(MissingNewCodeErr);
            Rec.Code := NewCode;
        end;
    end;

    var
        NewCode: Code[20];
        CodeToCopy: Code[20];
        CopyModePageCaptionLbl: Label 'Copy Financial Report Excel Template';
        MissingNewCodeErr: Label 'You must specify a code for the new template.';

    internal procedure SetSource(FinancialReportName: Code[10]; CodeToCopy: Code[20])
    begin
        Rec."Financial Report Name" := FinancialReportName;
        Rec.Insert();
        this.CodeToCopy := CodeToCopy;
        if CodeToCopy <> '' then
            CurrPage.Caption(CopyModePageCaptionLbl);
    end;
}