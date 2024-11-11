#if not CLEANSCHEMA15
tableextension 13689 "Sales Line Archive DK" extends "Sales Line Archive"
{
    fields
    {
#if not CLEANSCHEMA15
        field(13602; "Account Code"; Text[30])
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