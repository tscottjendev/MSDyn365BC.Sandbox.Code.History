namespace Microsoft.SubscriptionBilling;

using Microsoft.Foundation.AuditCodes;

codeunit 8101 "Create Sub. Billing Setup"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "Service Contract Setup" = rim,
        tabledata "Source Code Setup" = rim;

    trigger OnRun()
    begin
        CreateSetupTable();
        UpdateSourceCodeSetup();
    end;

    local procedure CreateSetupTable()
    var
        ServiceContractSetup: Record "Service Contract Setup";
        CreateSubBillingNoSeries: Codeunit "Create Sub. Billing No. Series";
    begin
        ServiceContractSetup.Get();

        ServiceContractSetup."Customer Contract Nos." := CreateSubBillingNoSeries.CustomerContractNoSeries();
        ServiceContractSetup."Vendor Contract Nos." := CreateSubBillingNoSeries.VendorContractNoSeries();
        ServiceContractSetup."Service Object Nos." := CreateSubBillingNoSeries.ServiceObjectNoSeries();

        ServiceContractSetup."Serv. Start Date for Inv. Pick" := ServiceContractSetup."Serv. Start Date for Inv. Pick"::"Shipment Date";
        Evaluate(ServiceContractSetup."Overdue Date Formula", '<1D>');
        ServiceContractSetup.ContractTextsCreateDefaults();
        ServiceContractSetup."Origin Name collective Invoice" := ServiceContractSetup."Origin Name collective Invoice"::"Sell-to Customer";
        ServiceContractSetup."Default Period Calculation" := ServiceContractSetup."Default Period Calculation"::"Align to End of Month";

        ServiceContractSetup.Modify(false);
    end;

    local procedure UpdateSourceCodeSetup()
    var
        SourceCodeSetup: Record "Source Code Setup";
        ContosoAuditCode: Codeunit "Contoso Audit Code";
    begin
        ContosoAuditCode.InsertSourceCode(SubBillDefRelTok, SubBillDefRelDescriptionLbl);

        SourceCodeSetup.Get();
        SourceCodeSetup."Contract Deferrals Release" := SubBillDefRelTok;
        SourceCodeSetup.Modify(false);
    end;

    var
        SubBillDefRelTok: Label 'CONTDEFREL', MaxLength = 10;
        SubBillDefRelDescriptionLbl: Label 'Contract Deferrals Release';
}