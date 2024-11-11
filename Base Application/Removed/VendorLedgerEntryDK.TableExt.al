#if not CLEANSCHEMA15
tableextension 13700 "Vendor Ledger Entry DK" extends "Vendor Ledger Entry"
{
    fields
    {
#if not CLEANSCHEMA15
        field(13650; "Giro Acc. No."; Code[8])
        {
            Caption = 'Giro Acc. No.';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: GiroAccNo';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
#endif
    }
}
#endif