#if not CLEANSCHEMA15
tableextension 13702 "Item Charge DK" extends "Item Charge"
{
    fields
    {
#if not CLEANSCHEMA15
        field(13600; "Charge Category"; Option)
        {
            Caption = 'Charge Category';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to OIOUBL extension, the same table, same field name prefixed with OIOUBL-.';
            ObsoleteState = Removed;
            OptionCaption = 'General Rebate,General Fine,Freight Charge,Duty,Tax';
            OptionMembers = "General Rebate","General Fine","Freight Charge",Duty,Tax;
            ObsoleteTag = '15.0';
        }
#endif
    }
}
#endif