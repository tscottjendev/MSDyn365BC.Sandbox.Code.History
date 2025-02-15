namespace Microsoft.SubscriptionBilling;

codeunit 8117 "Create Sub. Bill. Cust. Contr."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateCustomerContracts();
    end;

    local procedure CreateCustomerContracts()
    var
        CommonCustomer: Codeunit "Create Common Customer/Vendor";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
        CreateSubBillContrTypes: Codeunit "Create Sub. Bill. Contr. Types";
        CreateSubBillServObj: Codeunit "Create Sub. Bill. Serv. Obj.";
    begin
        ContosoSubscriptionBilling.InsertCustomerContract(CUC100001(), NewspaperLbl, CommonCustomer.DomesticCustomer1(), CreateSubBillContrTypes.MiscellaneousCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CUC100001(), CreateSubBillServObj.SOB100001());

        ContosoSubscriptionBilling.InsertCustomerContract(CUC100002(), SupportLbl, CommonCustomer.DomesticCustomer2(), CreateSubBillContrTypes.SupportCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CUC100002(), CreateSubBillServObj.SOB100002());

        ContosoSubscriptionBilling.InsertCustomerContract(CUC100003(), HardwareMaintenanceLbl, CommonCustomer.DomesticCustomer3(), CreateSubBillContrTypes.MaintenanceCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CUC100003(), CreateSubBillServObj.SOB100003());

        ContosoSubscriptionBilling.InsertCustomerContract(CUC100004(), UsageDataLbl, CommonCustomer.DomesticCustomer1(), CreateSubBillContrTypes.UsageDataCode());
        ContosoSubscriptionBilling.InsertCustomerContractLine(CUC100004(), CreateSubBillServObj.SOB100004());
    end;

    var
        NewspaperLbl: Label 'Newspaper', MaxLength = 100;
        SupportLbl: Label 'Support', MaxLength = 100;
        HardwareMaintenanceLbl: Label 'Hardware Maintenance', MaxLength = 100;
        UsageDataLbl: Label 'Usage data', MaxLength = 100;

    procedure CUC100001(): Code[20]
    begin
        exit('CUC100001');
    end;

    procedure CUC100002(): Code[20]
    begin
        exit('CUC100002');
    end;

    procedure CUC100003(): Code[20]
    begin
        exit('CUC100003');
    end;

    procedure CUC100004(): Code[20]
    begin
        exit('CUC100004');
    end;
}