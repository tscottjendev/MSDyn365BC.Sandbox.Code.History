#if not CLEANSCHEMA15
tableextension 13682 "Reminder Line DK" extends "Reminder Line"
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