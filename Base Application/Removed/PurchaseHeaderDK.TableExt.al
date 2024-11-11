#if not CLEANSCHEMA15
tableextension 13679 "Purchase Header DK" extends "Purchase Header"
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