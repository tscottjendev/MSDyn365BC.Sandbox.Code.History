codeunit 148209 "Sust. Caption Class Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySustainability: Codeunit "Library - Sustainability";
        EnergyConsumptionUnitOfMeasureLbl: Label 'Energy Consumption (%1)', Comment = '%1 = Energy Unit of Measure Code';
        PostedEnergyConsumptionUnitOfMeasureLbl: Label 'Posted Energy Consumption (%1)', Comment = '%1 = Energy Unit of Measure Code';
        CaptionValueMustBeEqualErr: Label '%1 caption must be equal to %2 in the Page %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Page Caption';

    [Test]
    procedure VerifyCaptionWhenUnitOfMeasureIsNotBlank()
    var
        SustainabilitySetup: Record "Sustainability Setup";
        CaptionClassTestPage: TestPage "Sust. Caption Class Test Page";
    begin
        // [SCENARIO 554943] Verify caption When "Energy Unit of Measure" is not blank in Sustainability Setup. 
        LibrarySustainability.CleanUpBeforeTesting();

        // [GIVEN] Update "Energy Unit Of Measure" in Sustainability Setup.
        UpdateEnergyUnitOfMeasureInSustainabilitySetup();

        // [GIVEN] Get Sustainability Setup.
        SustainabilitySetup.Get();

        // [WHEN] Get Caption Class Test Page.
        CaptionClassTestPage.OpenEdit();

        // [VERIFY] Verify caption When "Energy Unit of Measure" is not blank in Sustainability Setup. 
        Assert.AreEqual(
            StrSubstNo(EnergyConsumptionUnitOfMeasureLbl, SustainabilitySetup."Energy Unit of Measure Code"),
            CaptionClassTestPage.EnergyConsumption.Caption(),
            StrSubstNo(CaptionValueMustBeEqualErr, CaptionClassTestPage.EnergyConsumption.Caption(), StrSubstNo(EnergyConsumptionUnitOfMeasureLbl, SustainabilitySetup."Energy Unit of Measure Code"), CaptionClassTestPage.Caption));

        Assert.AreEqual(
           StrSubstNo(PostedEnergyConsumptionUnitOfMeasureLbl, SustainabilitySetup."Energy Unit of Measure Code"),
           CaptionClassTestPage.PostedEnergyConsumption.Caption(),
           StrSubstNo(CaptionValueMustBeEqualErr, CaptionClassTestPage.PostedEnergyConsumption.Caption(), StrSubstNo(PostedEnergyConsumptionUnitOfMeasureLbl, SustainabilitySetup."Energy Unit of Measure Code"), CaptionClassTestPage.Caption));
    end;

    local procedure UpdateEnergyUnitOfMeasureInSustainabilitySetup()
    var
        UnitOfMeasure: Record "Unit of Measure";
        SustainabilitySetup: Record "Sustainability Setup";
    begin
        LibraryInventory.FindUnitOfMeasure(UnitOfMeasure);

        SustainabilitySetup.Get();
        SustainabilitySetup.Validate("Energy Unit of Measure Code", UnitOfMeasure.Code);
        SustainabilitySetup.Modify();
    end;
}