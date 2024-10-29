#if not CLEANSCHEMA15
namespace System.Device;

tableextension 15000290 "Printer Selection Extension" extends "Printer Selection"
{
    fields
    {
        field(10600; "First Page - Paper Source"; Option)
        {
            Caption = 'First Page - Paper Source';
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            OptionCaption = ' ,Upper or Only One Feed,Lower Feed,Middle Feed,Manual Feed,Envelope Feed,Envelope Manual Feed,Automatic Feed,Tractor Feed,Small-format Feed,Large-format Feed,Large-capacity Feed,,,Cassette Feed,Automatically Select,Printer Specific Feed 1,Printer Specific Feed 2,Printer Specific Feed 3,Printer Specific Feed 4,Printer Specific Feed 5,Printer Specific Feed 6,Printer Specific Feed 7,Printer Specific Feed 8';
            OptionMembers = " ","Upper or Only One Feed","Lower Feed","Middle Feed","Manual Feed","Envelope Feed","Envelope Manual Feed","Automatic Feed","Tractor Feed","Small-format Feed","Large-format Feed","Large-capacity Feed",,,"Cassette Feed","Automatically Select","Printer Specific Feed 1","Printer Specific Feed 2","Printer Specific Feed 3","Printer Specific Feed 4","Printer Specific Feed 5","Printer Specific Feed 6","Printer Specific Feed 7","Printer Specific Feed 8";
            ObsoleteTag = '15.0';
            DataClassification = CustomerContent;
        }
        field(10601; "First Page - Tray Number"; Integer)
        {
            BlankZero = true;
            Caption = 'First Page - Tray Number';
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
            DataClassification = CustomerContent;
        }
        field(10602; "Other Pages - Paper Source"; Option)
        {
            Caption = 'Other Pages - Paper Source';
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            OptionCaption = ' ,Upper or Only One Feed,Lower Feed,Middle Feed,Manual Feed,Envelope Feed,Envelope Manual Feed,Automatic Feed,Tractor Feed,Small-format Feed,Large-format Feed,Large-capacity Feed,,,Cassette Feed,Automatically Select,Printer Specific Feed 1,Printer Specific Feed 2,Printer Specific Feed 3,Printer Specific Feed 4,Printer Specific Feed 5,Printer Specific Feed 6,Printer Specific Feed 7,Printer Specific Feed 8';
            OptionMembers = " ","Upper or Only One Feed","Lower Feed","Middle Feed","Manual Feed","Envelope Feed","Envelope Manual Feed","Automatic Feed","Tractor Feed","Small-format Feed","Large-format Feed","Large-capacity Feed",,,"Cassette Feed","Automatically Select","Printer Specific Feed 1","Printer Specific Feed 2","Printer Specific Feed 3","Printer Specific Feed 4","Printer Specific Feed 5","Printer Specific Feed 6","Printer Specific Feed 7","Printer Specific Feed 8";
            ObsoleteTag = '15.0';
            DataClassification = CustomerContent;
        }
        field(10603; "Other Pages - Tray Number"; Integer)
        {
            BlankZero = true;
            Caption = 'Other Pages - Tray Number';
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
            DataClassification = CustomerContent;
        }
        field(10604; "Giro Page - Paper Source"; Option)
        {
            Caption = 'Giro Page - Paper Source';
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            OptionCaption = ' ,Upper or Only One Feed,Lower Feed,Middle Feed,Manual Feed,Envelope Feed,Envelope Manual Feed,Automatic Feed,Tractor Feed,Small-format Feed,Large-format Feed,Large-capacity Feed,,,Cassette Feed,Automatically Select,Printer Specific Feed 1,Printer Specific Feed 2,Printer Specific Feed 3,Printer Specific Feed 4,Printer Specific Feed 5,Printer Specific Feed 6,Printer Specific Feed 7,Printer Specific Feed 8';
            OptionMembers = " ","Upper or Only One Feed","Lower Feed","Middle Feed","Manual Feed","Envelope Feed","Envelope Manual Feed","Automatic Feed","Tractor Feed","Small-format Feed","Large-format Feed","Large-capacity Feed",,,"Cassette Feed","Automatically Select","Printer Specific Feed 1","Printer Specific Feed 2","Printer Specific Feed 3","Printer Specific Feed 4","Printer Specific Feed 5","Printer Specific Feed 6","Printer Specific Feed 7","Printer Specific Feed 8";
            ObsoleteTag = '15.0';
            DataClassification = CustomerContent;
        }
        field(10605; "Giro Page - Tray Number"; Integer)
        {
            BlankZero = true;
            Caption = 'Giro Page - Tray Number';
            ObsoleteReason = 'Not needed after refactoring';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
            DataClassification = CustomerContent;
        }
    }
}
#endif
