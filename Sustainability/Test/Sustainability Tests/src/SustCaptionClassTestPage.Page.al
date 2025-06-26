page 148180 "Sust. Caption Class Test Page"
{
    PageType = Card;

    layout
    {
        area(Content)
        {
            field(NetChangeCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,1,1';
            }
            field(NetChangeCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,1,2';
            }
            field(NetChangeN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,1,3';
            }
            field(BalanceAtDateCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,2,1';
            }
            field(BalanceAtDateCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,2,2';
            }
            field(BalanceAtDateN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,2,3';
            }
            field(BalanceCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,3,1';
            }
            field(BalanceCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,3,2';
            }
            field(BalanceN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,3,3';
            }
            field(CO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,4,1';
            }
            field(CH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,4,2';
            }
            field(N2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,4,3';
            }
            field(EmissionFactorCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,5,1';
            }
            field(EmissionFactorCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,5,2';
            }
            field(EmissionFactorN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,5,3';
            }
            field(EmissionCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,6,1';
            }
            field(EmissionCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,6,2';
            }
            field(EmissionN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,6,3';
            }
            field(BaselineCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,7,1';
            }
            field(BaselineCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,7,2';
            }
            field(BaselineN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,7,3';
            }
            field(CurrentValueCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,8,1';
            }
            field(CurrentValueCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,8,2';
            }
            field(CurrentValueN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,8,3';
            }
            field(TargetValueCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,9,1';
            }
            field(TargetValueCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,9,2';
            }
            field(TargetValueN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,9,3';
            }
            field(DefaultEmissionCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,10,1';
            }
            field(DefaultEmissionCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,10,2';
            }
            field(DefaultEmissionN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,10,3';
            }
            field(PostedEmissionCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,11,1';
            }
            field(PostedEmissionCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,11,2';
            }
            field(PostedEmissionN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,11,3';
            }
            field(TotalEmissionUnitOfMeasureCO2; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,12,1';
            }
            field(TotalEmissionUnitOfMeasureCH4; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,12,2';
            }
            field(TotalEmissionUnitOfMeasureN2O; TextValue)
            {
                ApplicationArea = All;
                CaptionClass = '102,12,3';
            }
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