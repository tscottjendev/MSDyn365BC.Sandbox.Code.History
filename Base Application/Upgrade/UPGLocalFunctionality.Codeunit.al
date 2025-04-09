#pragma warning disable AA0247
codeunit 104100 "Upg Local Functionality"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpdateVendorRegistrationNo();
    end;


#if not CLEAN25
    [Obsolete('Replaced by ReportSelections table setup', '25.0')]
    procedure SetReportSelectionForGLVATReconciliation()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportSelections: Record "Report Selections";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        ReportID: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag()) then
            exit;

        DACHReportSelections.SETRANGE(Usage, DACHReportSelections.Usage::"Sales VAT Acc. Proof");
        if DACHReportSelections.FindFirst() then
            ReportID := DACHReportSelections."Report ID"
        else
            ReportID := 11;

        ReportSelections.Init();
        ReportSelections.Usage := ReportSelections.Usage::"Sales VAT Acc. Proof";
        ReportSelections.Sequence := '1';
        ReportSelections."Report ID" := DACHReportSelections."Report ID";
        if not ReportSelections.Insert() then
            ReportSelections.Modify();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag());
    end;
#endif

    procedure UpdateVendorRegistrationNo()
    var
        Vendor: Record Vendor;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        VendorDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag()) then
            exit;

        VendorDataTransfer.SetTables(Database::Vendor, Database::Vendor);
        VendorDataTransfer.AddFieldValue(Vendor.FieldNo("Registration No."), Vendor.FieldNo("Registration Number"));
        VendorDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag());
    end;
}
