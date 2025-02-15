namespace Microsoft.SubscriptionBilling;

codeunit 8113 "Create Sub. Bill. Supplier"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CommonVendor: Codeunit "Create Common Customer/Vendor";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
    begin
        ContosoSubscriptionBilling.InsertUsageDataSupplier(Generic(), GenericLbl, Enum::"Usage Data Supplier Type"::Generic, false, Enum::"Vendor Invoice Per"::Import, CommonVendor.DomesticVendor3());
    end;

    var
        GenericTok: Label 'GENERIC', MaxLength = 20;
        GenericLbl: Label 'Generic', MaxLength = 80;

    procedure Generic(): Code[20]
    begin
        exit(GenericTok);
    end;
}