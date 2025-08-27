codeunit 101998 "Create Customer Template"
{

    trigger OnRun()
    begin
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Customer: Record Customer;
        CreateTemplateHelper: Codeunit "Create Template Helper";
        xBlankDescrTxt: Label 'Blank Customer Card', Comment = 'Translate.';
        xCashDescriptionTxt: Label 'Cash-Payment / Retail Customer (Cash)', Comment = 'Translate.';
        xPrivateDescriptionTxt: Label 'Private Customer (Giro)', Comment = 'Translate.';
        xBusinessDescriptionTxt: Label 'Business-to-Business Customer (Bank)', Comment = 'Translate.';
        xEuDescriptionTxt: Label 'EU Customer (EUR, Bank)', Comment = 'Translate.';
        xEURTxt: Label 'EUR', Comment = 'It''s EUR currency code.';
        xManualTxt: Label 'Manual';
        xCODTxt: Label 'COD';
        X14DAYSTxt: Label '14 DAYS';
        X1M8DTxt: Label '1M(8D)';
        xGIROTxt: Label 'GIRO', Comment = 'To be translated.';
        xBANKTxt: Label 'BANK', Comment = 'To be translated.';
        xCASHCAPTxt: Label 'CASH', Comment = 'Translated.';

    procedure InsertMiniAppData()
    var
        ConfigTemplateHeader: Record "Config. Template Header";
    begin
        DemoDataSetup.Get();
        // Blank Template
        InsertTemplateHeader(ConfigTemplateHeader, xBlankDescrTxt);
        // Cash-Payment/Retail Customer customer template
        InsertTemplateHeader(ConfigTemplateHeader, GetCustomerTemplateDescriptionCashCustomer());
        InsertAddressInfo(ConfigTemplateHeader, DemoDataSetup."Country/Region Code");
        InsertPostingInfo(ConfigTemplateHeader, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode());
        InsertPricingInfo(ConfigTemplateHeader, true, true, Customer."Contact Type"::Person);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, xCODTxt, xCASHCAPTxt, '', '', true);

        CreateTemplateHelper.CreateTemplateSelectionRule(
          DATABASE::Customer, ConfigTemplateHeader.Code, '', 0, 0);
        // Private customer template
        InsertTemplateHeader(ConfigTemplateHeader, xPrivateDescriptionTxt);
        InsertAddressInfo(ConfigTemplateHeader, DemoDataSetup."Country/Region Code");
        InsertPostingInfo(ConfigTemplateHeader, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode());
        InsertPricingInfo(ConfigTemplateHeader, true, true, Customer."Contact Type"::Person);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X14DAYSTxt, xGIROTxt, '', '', true);
        // Business customer template
        InsertTemplateHeader(ConfigTemplateHeader, xBusinessDescriptionTxt);
        InsertAddressInfo(ConfigTemplateHeader, DemoDataSetup."Country/Region Code");
        InsertPostingInfo(ConfigTemplateHeader, DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.DomesticCode());
        InsertPricingInfo(ConfigTemplateHeader, true, false, Customer."Contact Type"::Company);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X1M8DTxt, xBANKTxt, '', '', true);
        // EU customer template
        InsertTemplateHeader(ConfigTemplateHeader, xEuDescriptionTxt);
        InsertAddressInfo(ConfigTemplateHeader, '');
        InsertPostingInfo(ConfigTemplateHeader, DemoDataSetup.EUCode(), DemoDataSetup.EUCode(), DemoDataSetup.EUCode());
        InsertPricingInfo(ConfigTemplateHeader, true, false, Customer."Contact Type"::Company);
        InsertForeignTradeInfo(ConfigTemplateHeader, xEURTxt);
        InsertPaymentsInfo(ConfigTemplateHeader, xManualTxt, X14DAYSTxt, xBANKTxt, '', '', true);
    end;

    local procedure InsertTemplateHeader(var ConfigTemplateHeader: Record "Config. Template Header"; Description: Text[50])
    var
        ConfigTemplateManagement: Codeunit "Config. Template Management";
    begin
        CreateTemplateHelper.CreateTemplateHeader(
          ConfigTemplateHeader, ConfigTemplateManagement.GetNextAvailableCode(DATABASE::Customer), Description, DATABASE::Customer);
    end;

    local procedure InsertAddressInfo(var ConfigTemplateHeader: Record "Config. Template Header"; CountryCode: Text[50])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Country/Region Code"), CountryCode);
    end;

    local procedure InsertPostingInfo(var ConfigTemplateHeader: Record "Config. Template Header"; GenBusGroup: Code[20]; VATBusGroup: Code[20]; CustomerGroup: Code[20])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Gen. Bus. Posting Group"), GenBusGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("VAT Bus. Posting Group"), VATBusGroup);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Customer Posting Group"), CustomerGroup);
    end;

    local procedure InsertPricingInfo(var ConfigTemplateHeader: Record "Config. Template Header"; AlowLine: Boolean; PriceWithVAT: Boolean; CustomerContactType: Enum "Contact Type")
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Allow Line Disc."), Format(AlowLine));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Prices Including VAT"), Format(PriceWithVAT));
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Contact Type"), Format(CustomerContactType));
    end;

    local procedure InsertForeignTradeInfo(var ConfigTemplateHeader: Record "Config. Template Header"; CurrencyCode: Code[10])
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Currency Code"), Format(CurrencyCode));
    end;

    local procedure InsertPaymentsInfo(var ConfigTemplateHeader: Record "Config. Template Header"; ApplMethod: Text[20]; PaymentTerms: Code[20]; PaymentMethod: Code[20]; ReminderTerms: Code[20]; FinChargeTerms: Code[20]; PrintStatm: Boolean)
    begin
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Application Method"), ApplMethod);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Payment Terms Code"), PaymentTerms);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Payment Method Code"), PaymentMethod);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Reminder Terms Code"), ReminderTerms);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Fin. Charge Terms Code"), FinChargeTerms);
        CreateTemplateHelper.CreateTemplateLine(ConfigTemplateHeader, Customer.FieldNo("Print Statements"), Format(PrintStatm));
    end;

    procedure GetCustomerTemplateDescriptionCashCustomer(): Text[50]
    begin
        exit(CopyStr(xCashDescriptionTxt, 1, 50));
    end;
}

