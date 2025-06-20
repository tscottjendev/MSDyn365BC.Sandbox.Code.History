page 148180 "Sust. Caption Class Test Page"
{
    PageType = Card;

    layout
    {
        area(Content)
        {
            field(EnergyConsumption; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,13,4';
            }
            field(PostedEnergyConsumption; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,14,4';
            }
        }
    }

    var
        TextValue: Text[30];
}