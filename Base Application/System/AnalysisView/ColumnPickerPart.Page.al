// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
namespace System.Tooling;

using System.Reflection;

page 9644 "Column Picker Part"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Page Table Field";
    Caption = 'Choose a source page';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    ShowFilter = true;

    layout
    {
        area(Content)
        {
            group(ChoosePage)
            {
                ShowCaption = false;
                field(SourcePage; SourcePageName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show available fields from';
                    ToolTip = 'Specifies source page name.';
                    Editable = true;
                    Visible = AreTherePagesAvailable;
                    InstructionalText = 'Select a page, or leave blank for all fields';
                    LookupPageId = "List and Card page picker";
                    TableRelation = "Page Metadata" where(SourceTable = field("Table No"));

                    trigger OnAfterLookup(Selected: RecordRef)
                    var
                        PageMetadata: Record "Page Metadata";
                    begin
                        Selected.SetTable(PageMetadata);

                        ColumnPickerHelper.FilterAfterLookup(PageMetadata.Id, Rec);

                        SourcePageName := PageMetadata.Name;
                        CurrPage.Update();
                    end;
                }

                field(Warning; UsingTableAsSourceMsg)
                {
                    Visible = not AreTherePagesAvailable;
                    ShowCaption = false;
                    ApplicationArea = All;
                    Editable = false;
                    Style = Strong;
                }

                repeater(GroupName)
                {
                    Editable = false;

                    field(Name; Rec.Name)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the table field id.';
                    }
                    field("Field ID"; Rec."Table Field Id")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the field name.';
                    }
                    field(Example; Example)
                    {
                        ApplicationArea = All;
                        Caption = 'Example';
                        Style = Subordinate;
                        ToolTip = 'Specifies an example value for the table field.';
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the description for the field.';
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ColumnPickerHelper.Initialize(Rec);
        CurrPage.Caption := StrSubstNo(InsertColumnMsg, ColumnPickerHelper.GetRelatedTableName());
        AreTherePagesAvailable := ColumnPickerHelper.GetAreTherePagesAvailable();
    end;

    trigger OnAfterGetRecord()
    begin
        Example := ColumnPickerHelper.GetExampleValue(Rec."Table Field Id");
    end;

    var
        ColumnPickerHelper: Codeunit "Column Picker Helper";
        UsingTableAsSourceMsg: Label 'There are no list or card pages for the selected table, showing table fields instead.';
        InsertColumnMsg: Label 'Insert column(s) from %1', Comment = '%1 = The table name to insert columns from.';
        SourcePageName: Text;
        Example: Text;
        AreTherePagesAvailable: Boolean;
}