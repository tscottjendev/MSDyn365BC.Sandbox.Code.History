#if not CLEANSCHEMA15
tableextension 13671 "Finance Charge Memo Line DK" extends "Finance Charge Memo Line"
{
    fields
    {
#if not CLEANSCHEMA15
        field(13600; "Account Code"; Text[30])
        {
            Caption = 'Account Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
#endif
    }
}
#endif