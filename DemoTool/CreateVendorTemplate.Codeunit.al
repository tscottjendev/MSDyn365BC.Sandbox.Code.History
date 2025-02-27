codeunit 101999 "Create Vendor Template"
{

    trigger OnRun()
    begin
    end;

    var
        xBlankDescrTxt: Label 'Blank Vendor Card', Comment = 'Translate.';
        xCashDescriptionTxt: Label 'Cash-Payment Vendor (Cash, VAT)', Comment = 'Translate.';
        DemoDataSetup: Record "Demo Data Setup";
        Vendor: Record Vendor;
        xPrivateDescriptionTxt: Label 'Private Vendor (Giro, No VAT)', Comment = 'Translate.';
        xBusinessDescriptionTxt: Label 'Business-to-Business Vendor (Bank, VAT)', Comment = 'Translate.';
        xEuDescriptionTxt: Label 'EU Vendor (EUR, Bank)', Comment = 'Translate.';
        xEURTxt: Label 'EUR', Comment = 'It''s EUR currency code.';
        xManualTxt: Label 'Manual';
        xCODTxt: Label 'COD';
        X14DAYSTxt: Label '14 DAYS';
        X1M8DTxt: Label '1M(8D)';
        xGIROTxt: Label 'GIRO', Comment = 'To be translated.';
        xBANKTxt: Label 'BANK', Comment = 'To be translated.';
        xCASHCAPTxt: Label 'CASH', Comment = 'Translated.';
        CreateTemplateHelper: Codeunit "Create Template Helper";
        xVENDDOMTxt: Label 'VENDDOM';
        xVENDFORTxt: Label 'VENDFOR';
        xVENDHIGHTxt: Label 'VENDHIGH';
        xForeignTxt: Label 'Foreign';

    procedure InsertMiniAppData()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        DemoDataSetup.Get();
        // Blank Template
        InsertTemplate(ConfigTemplateHeader, xBlankDescrTxt, '', '', '', '', false);
        // Cash-Payment vendor template // NO
        InsertTemplate(ConfigTemplateHeader,
          xCashDescriptionTxt, DemoDataSetup."Country/Region Code", xVENDDOMTxt, xVENDHIGHTxt, DemoDataSetup.DomesticCode(), true);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, xCODTxt, xCASHCAPTxt);

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Vendor, ConfigTemplateHeader.Code, '', 0, 0);
        // Private vendor template
        InsertTemplate(ConfigTemplateHeader,
          xPrivateDescriptionTxt, DemoDataSetup."Country/Region Code", xVENDDOMTxt, xVENDHIGHTxt, DemoDataSetup.DomesticCode(), true);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X14DAYSTxt, xGIROTxt);
        // Business-to-Business vendor template
        InsertTemplate(ConfigTemplateHeader,
          xBusinessDescriptionTxt, DemoDataSetup."Country/Region Code", xVENDDOMTxt, xVENDHIGHTxt, DemoDataSetup.DomesticCode(), false);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X1M8DTxt, xBANKTxt);
        // EU vendor template
        InsertTemplate(ConfigTemplateHeader, xEuDescriptionTxt, '', xVENDFORTxt, xVENDHIGHTxt, xForeignTxt, false);
        if DemoDataSetup."Currency Code" <> 'EUR' then
            InsertForeignTradeInfo(ConfigTemplateHeader, xEURTxt);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X14DAYSTxt, xBANKTxt);
    end;

    local procedure InsertTemplate(var ConfigTemplateHeader: Record "Config. Template Header"; Description: Text[50]; CountryCode: Text[50]; GenBusGroup: Code[20]; VATBusGroup: Code[20]; VendorGroup: Code[20]; PriceWithVAT: Boolean)
    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Vendor), Description, DATABASE::Vendor);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Country/Region Code"), CountryCode);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Gen. Bus. Posting Group"), GenBusGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("VAT Bus. Posting Group"), VATBusGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Prices Including VAT"), Format(PriceWithVAT));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Vendor Posting Group"), VendorGroup);
    end;

    local procedure InsertForeignTradeInfo(var ConfigTemplateHeader: Record "Config. Template Header"; CurrencyCode: Code[10])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Currency Code"), Format(CurrencyCode));
    end;

    local procedure InsertPaymentsInfo(var ConfigTemplateHeader: Record "Config. Template Header"; ApplMethod: Text[20]; PaymentTerms: Code[20]; PaymentMethod: Code[20])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Application Method"), ApplMethod);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Payment Terms Code"), PaymentTerms);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Vendor.FieldNo("Payment Method Code"), PaymentMethod);
    end;
}

