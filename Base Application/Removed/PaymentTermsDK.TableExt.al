#if not CLEANSCHEMA15
tableextension 13678 "Payment Terms DK" extends "Payment Terms"
{
    fields
    {
#if not CLEANSCHEMA15
        field(13600; "OIOUBL Code"; Option)
        {
            Caption = 'OIOUBL Code';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            OptionCaption = ' ,Contract,Specific';
            OptionMembers = " ",Contract,Specific;
            ObsoleteTag = '15.0';
        }
#endif
    }
}
#endif