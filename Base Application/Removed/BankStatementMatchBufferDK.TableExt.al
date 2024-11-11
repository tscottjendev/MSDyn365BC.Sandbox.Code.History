#if not CLEANSCHEMA15
tableextension 13665 "Bank Statement Match Buffer DK" extends "Bank Statement Matching Buffer"
{
    fields
    {
#if not CLEANSCHEMA15
        field(13600; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: DescriptionBankStatment';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
        }
#endif
#if not CLEANSCHEMA15
        field(13601; "Match Status"; Option)
        {
            Caption = 'Match Status';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Moved to Payment and Reconciliation Formats (DK) extension to field name: MatchStatus';
            ObsoleteState = Removed;
            OptionCaption = ' ,NoMatch,Duplicate,IsPaid,Partial,Extra,Fully';
            OptionMembers = " ",NoMatch,Duplicate,IsPaid,Partial,Extra,Fully;
            ObsoleteTag = '15.0';
        }
#endif
    }
}
#endif