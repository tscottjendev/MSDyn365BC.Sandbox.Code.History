namespace Microsoft.SubscriptionBilling;

page 8096 "Usage Data Billing Metadata"
{
    ApplicationArea = All;
    Caption = 'Usage Data Billing Metadata';
    PageType = List;
    SourceTable = "Usage Data Billing Metadata";
    UsageCategory = Administration;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Service Object No."; Rec."Service Object No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the number of the related service object.';
                }
                field("Service Commitment Entry No."; Rec."Service Commitment Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the number of the related service commitment line.';
                }
                field("Supplier Charge Start Date"; Rec."Supplier Charge Start Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the start date of the usage provided by the supplier';
                }
                field("Supplier Charge End Date"; Rec."Supplier Charge End Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the end date of the usage provided by the supplier.';
                }
                field("Original Invoiced to Date"; Rec."Original Invoiced to Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates the date up to which the service commitment was originally invoiced.';
                }
                field(Invoiced; Rec.Invoiced)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the related usage data billing is invoiced.';
                }
                field(Rebilling; Rec.Rebilling)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the related usage data billing comes out of a rebilling scenario.';
                }
            }
        }
    }
}
