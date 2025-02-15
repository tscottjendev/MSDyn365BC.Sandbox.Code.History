table 8021 "Usage Data Billing Metadata"
{
    Access = Internal;
    Caption = 'Usage Data Billing Metadata';
    DataClassification = CustomerContent;
    DrillDownPageId = "Usage Data Billing Metadata";
    LookupPageId = "Usage Data Billing Metadata";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Usage Data Billing Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = "Usage Data Billing";
        }
        field(3; "Service Object No."; Code[20])
        {
            Caption = 'Service Object No.';
            TableRelation = "Service Object";
        }
        field(4; "Service Commitment Entry No."; Integer)
        {
            Caption = 'Service Commitment Line No.';
            TableRelation = "Service Commitment";
        }
        field(5; "Supplier Charge Start Date"; Date)
        {
            Caption = 'Supplier Charge Start Date';
        }
        field(6; "Supplier Charge End Date"; Date)
        {
            Caption = 'Supplier Charge End Date';
        }
        field(7; "Original Invoiced to Date"; Date)
        {
            Caption = 'Original Invoiced to Date';
        }
        field(8; Invoiced; Boolean)
        {
            Caption = 'Invoiced';
        }
        field(9; Rebilling; Boolean)
        {
            Caption = 'Rebilling';
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    internal procedure FilterOnUsageDataBilling(UsageDataBilling: Record "Usage Data Billing")
    begin
        Rec.SetRange("Service Object No.", UsageDataBilling."Service Object No.");
        Rec.SetRange("Service Commitment Entry No.", UsageDataBilling."Service Commitment Entry No.");
        Rec.SetRange("Supplier Charge Start Date", UsageDataBilling."Charge Start Date");
        Rec.SetRange("Supplier Charge End Date", UsageDataBilling."Charge End Date");
    end;

    internal procedure InsertFromUsageDataBilling(UsageDataBilling: Record "Usage Data Billing")
    var
        ServiceCommitment: Record "Service Commitment";
    begin
        "Entry No." := 0;
        "Usage Data Billing Entry No." := UsageDataBilling."Entry No.";
        "Service Object No." := UsageDataBilling."Service Object No.";
        "Service Commitment Entry No." := UsageDataBilling."Service Commitment Entry No.";
        "Supplier Charge Start Date" := UsageDataBilling."Charge Start Date";
        "Supplier Charge End Date" := UsageDataBilling."Charge End Date";
        Rebilling := UsageDataBilling.Rebilling;

        if ("Service Object No." <> '') and ("Service Commitment Entry No." <> 0) then begin
            ServiceCommitment.Get("Service Commitment Entry No.");
            "Original Invoiced to Date" := CalcDate('<-1D>', ServiceCommitment."Next Billing Date");
            if UsageDataBilling.Rebilling then begin
                ServiceCommitment."Next Billing Date" := UsageDataBilling."Charge Start Date";
                ServiceCommitment.Modify(true);
            end;
        end;
        Insert(true);
    end;

    internal procedure DeleteFor(UsageDataBillingEntryNo: Integer)
    var
        UsageDataBillingMetadata: Record "Usage Data Billing Metadata";
    begin
        UsageDataBillingMetadata.SetRange("Usage Data Billing Entry No.", UsageDataBillingEntryNo);
        UsageDataBillingMetadata.DeleteAll();
    end;
}
