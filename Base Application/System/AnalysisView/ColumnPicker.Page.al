namespace System.Tooling;

using System.Reflection;

page 9640 "Column Picker"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Page Table Field";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            field(SourcePage; SourcePageName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show available fields from';
                ToolTip = 'Specifies source page name.';
                Visible = AreTherePagesAvailable;
                InstructionalText = 'Select a page';
                LookupPageId = "List and Card page picker";
                TableRelation = "Page Metadata" where(SourceTable = field("Table No"),
                                                        PageType = filter('0|1'));

                trigger OnAfterLookup(Selected: RecordRef)
                var
                    PageMetadata: Record "Page Metadata";
                begin
                    PageMetadata := Selected;
                    SourcePageName := PageMetadata.Name;

                    Rec.SetFilter(FieldKind, '%1', Rec.FieldKind::PageFieldBoundToTable);
                    Rec.SetFilter("Page ID", '%1', PageMetadata.ID);
                    Rec.SetCurrentKey(Name);
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

    trigger OnOpenPage()
    begin
        Rec.FindFirst();

        // Fill in the information about the selected table to join
        RelatedTableRecRef.Open(Rec."Table No");
        CurrPage.Caption := StrSubstNo(InsertColumnMsg, RelatedTableRecRef.Name());

        // Filter the pages and fields shown in the repeater control
        FilterRelatedPagesAndFields();
    end;

    trigger OnAfterGetRecord()
    begin
        if RelatedTableRecRef.FindFirst() then
            Example := GetExampleValue(Rec."Table Field Id");
    end;

    local procedure FilterRelatedPagesAndFields()
    var
        PageMetadata: Record "Page Metadata";
    begin
        // If there are no list or card pages for the selected table, show table fields instead.
        PageMetadata.SetFilter(SourceTable, '%1', Rec."Table No");
        PageMetadata.SetFilter(PageType, '%1|%2', PageMetadata.PageType::List, PageMetadata.PageType::Card);

        AreTherePagesAvailable := not PageMetadata.IsEmpty();
        if AreTherePagesAvailable then begin
            Rec.SetFilter(FieldKind, '%1', Rec.FieldKind::TableField);
            Rec.SetFilter("Page ID", '%1', Rec."Page ID");
        end;

        // Filter the fields in the repeater control to show only supported field types and skip system fields.
        Rec.SetFilter(Type, '<>%1 & <>%2 & <>%3 & <>%4 & <>%5', Rec.Type::BLOB, Rec.Type::Media, Rec.Type::MediaSet, Rec.Type::NotSupported_Binary, Rec.Type::TableFilter);
        Rec.SetFilter("Table Field Id", '<2000000000');
        Rec.FindSet();
    end;

    local procedure GetExampleValue(FieldId: Integer): Text
    var
        PageTableFieldFieldRef: FieldRef;
    begin
        if RelatedTableRecRef.FieldExist(FieldId) then begin
            PageTableFieldFieldRef := RelatedTableRecRef.Field(FieldId);
            exit(Format(PageTableFieldFieldRef.Value()));
        end;
    end;

    var
        RelatedTableRecRef: RecordRef;
        UsingTableAsSourceMsg: Label 'There are no list or card pages for the selected table, showing table fields instead.';
        InsertColumnMsg: Label 'Insert column(s) from %1', Comment = '%1 = The table name to insert columns from.';
        SourcePageName: Text;
        Example: Text;
        AreTherePagesAvailable: Boolean;
}