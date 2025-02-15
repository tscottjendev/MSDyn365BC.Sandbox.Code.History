namespace Microsoft.SubscriptionBilling;

codeunit 8118 "Create Sub. Bill. Vend. Contr."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateVendorContracts();
    end;

    local procedure CreateVendorContracts()
    var
        CommonVendor: Codeunit "Create Common Customer/Vendor";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
        CreateSubBillContrTypes: Codeunit "Create Sub. Bill. Contr. Types";
        CreateSubBillServObj: Codeunit "Create Sub. Bill. Serv. Obj.";
    begin
        ContosoSubscriptionBilling.InsertVendorContract(VEC100001(), HardwareMaintenanceLbl, CommonVendor.DomesticVendor2(), CreateSubBillContrTypes.MaintenanceCode());
        ContosoSubscriptionBilling.InsertVendorContractLine(VEC100001(), CreateSubBillServObj.SOB100003());

        ContosoSubscriptionBilling.InsertVendorContract(VEC100002(), UsageDataLbl, CommonVendor.DomesticVendor3(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertVendorContractLine(VEC100002(), CreateSubBillServObj.SOB100004());
    end;

    var
        HardwareMaintenanceLbl: Label 'Hardware Maintenance', MaxLength = 100;
        UsageDataLbl: Label 'Usage data', MaxLength = 100;

    procedure VEC100001(): Code[20]
    begin
        exit('VEC100001');
    end;

    procedure VEC100002(): Code[20]
    begin
        exit('VEC100002');
    end;
}