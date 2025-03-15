namespace Microsoft.SubscriptionBilling;

codeunit 8108 "Create Sub. Bill. GL Account"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        AddGLAccountsForLocalization();
    end;

    local procedure AddGLAccountsForLocalization()
    begin
        OnAfterAddGLAccountsForLocalization();
    end;

    var
        CustomerContractsRevenueLbl: Label 'Customer Subscription Contracts Revenue', MaxLength = 100;
        CustomerContractsDeferralsLbl: Label 'Customer Subscription Contract Deferrals', MaxLength = 100;
        VendorContractsCostLbl: Label 'Vendor Subscription Contracts Cost', MaxLength = 100;
        VendorContractsDeferralsLbl: Label 'Vendor Subscription Contract Deferrals', MaxLength = 100;

    procedure CustomerContractsRevenue(): Code[20]
    begin
        exit;
    end;

    procedure CustomerContractsRevenueName(): Text[100]
    begin
        exit(CustomerContractsRevenueLbl);
    end;

    procedure CustomerContractsDeferrals(): Code[20]
    begin
        exit;
    end;

    procedure CustomerContractsDeferralsName(): Text[100]
    begin
        exit(CustomerContractsDeferralsLbl);
    end;

    procedure VendorContractsCost(): Code[20]
    begin
        exit;
    end;

    procedure VendorContractsCostName(): Text[100]
    begin
        exit(VendorContractsCostLbl);
    end;

    procedure VendorContractsDeferrals(): Code[20]
    begin
        exit;
    end;

    procedure VendorContractsDeferralsName(): Text[100]
    begin
        exit(VendorContractsDeferralsLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddGLAccountsForLocalization()
    begin
    end;
}