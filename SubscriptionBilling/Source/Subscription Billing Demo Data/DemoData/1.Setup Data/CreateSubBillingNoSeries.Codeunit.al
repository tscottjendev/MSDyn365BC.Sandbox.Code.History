namespace Microsoft.SubscriptionBilling;

using Microsoft.Foundation.NoSeries;

codeunit 8103 "Create Sub. Billing No. Series"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoNoSeries: Codeunit "Contoso No Series";
    begin
        ContosoNoSeries.InsertNoSeries(CustomerContractNoSeries(), CustomerContractNoSeriesDescriptionTok, CustomerContractStartingNoLbl, CustomerContractEndingNoLbl, '', CustomerContractLastUsedNoLbl, 1, Enum::"No. Series Implementation"::Normal, true);
        ContosoNoSeries.InsertNoSeries(VendorContractNoSeries(), VendorContractNoSeriesDescriptionTok, VendorContractStartingNoLbl, VendorContractEndingNoLbl, '', VendorContractLastUsedNoLbl, 1, Enum::"No. Series Implementation"::Normal, true);
        ContosoNoSeries.InsertNoSeries(ServiceObjectNoSeries(), ServiceObjectNoSeriesDescriptionTok, ServiceObjectStartingNoLbl, ServiceObjectEndingNoLbl, '', ServiceObjectLastUsedNoLbl, 1, Enum::"No. Series Implementation"::Normal, true);
    end;

    procedure CustomerContractNoSeries(): Code[20]
    begin
        exit(CustomerContractNoSeriesTok);
    end;

    procedure VendorContractNoSeries(): Code[20]
    begin
        exit(VendorContractNoSeriesTok);
    end;

    procedure ServiceObjectNoSeries(): Code[20]
    begin
        exit(ServiceObjectNoSeriesTok);
    end;

    var
        CustomerContractNoSeriesTok: Label 'CUSTCONTR', MaxLength = 20;
        CustomerContractNoSeriesDescriptionTok: Label 'Customer Subscription Contracts', MaxLength = 100;
        CustomerContractStartingNoLbl: Label 'CUC100001', MaxLength = 20;
        CustomerContractEndingNoLbl: Label 'CUC999999', MaxLength = 20;
        CustomerContractLastUsedNoLbl: Label 'CUC100004', MaxLength = 20;
        VendorContractNoSeriesTok: Label 'VENDCONTR', MaxLength = 20;
        VendorContractNoSeriesDescriptionTok: Label 'Vendor Subscription Contracts', MaxLength = 100;
        VendorContractStartingNoLbl: Label 'VEC100001', MaxLength = 20;
        VendorContractLastUsedNoLbl: Label 'VEC100002', MaxLength = 20;
        VendorContractEndingNoLbl: Label 'VEC999999', MaxLength = 20;
        ServiceObjectNoSeriesTok: Label 'SERVOBJECT', MaxLength = 20;
        ServiceObjectNoSeriesDescriptionTok: Label 'Subscriptions', MaxLength = 100;
        ServiceObjectStartingNoLbl: Label 'SOB100001', MaxLength = 20;
        ServiceObjectLastUsedNoLbl: Label 'SOB100004', MaxLength = 20;
        ServiceObjectEndingNoLbl: Label 'SOB999999', MaxLength = 20;
}