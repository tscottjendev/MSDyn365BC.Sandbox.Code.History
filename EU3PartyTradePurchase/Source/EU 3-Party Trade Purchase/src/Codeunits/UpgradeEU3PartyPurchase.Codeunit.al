#if not CLEANSCHEMA26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.EU3PartyTrade;
#if not CLEAN26
using System.Environment;
using Microsoft.Purchases.Document;
using System.Upgrade;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Purchases.History;
#endif

codeunit 4888 "Upgrade EU3 Party Purchase"
{
    ObsoleteReason = 'EU 3rd party purchase app is moved to a new app.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    Access = Internal;
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    var
#if not CLEAN26
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagDefEU3PartyPurchase: Codeunit "Upg. Tag Def. EU3 Party Purch.";
        EnvironmentInformation: Codeunit "Environment Information";
        EU3PartyTradeFeatureMgt: Codeunit "EU3 Party Trade Feature Mgt.";
        Localization: Text;
#endif
    begin
#if not CLEAN26
        Localization := EnvironmentInformation.GetApplicationFamily();
        if (Localization <> 'SE') or EU3PartyTradeFeatureMgt.IsEnabled() then begin
            UpgradeTag.SetUpgradeTag(UpgTagDefEU3PartyPurchase.GetEU3PartyPurchaseUpgradeTag());
            exit;
        end;
        if UpgradeTag.HasUpgradeTag(UpgTagDefEU3PartyPurchase.GetEU3PartyPurchaseUpgradeTag()) then
            exit;
        UpgradeEU3PartyPurchase();
        UpdateVATSetup();
        UpgradeTag.SetUpgradeTag(UpgTagDefEU3PartyPurchase.GetEU3PartyPurchaseUpgradeTag());
#endif
    end;

#if not CLEAN26
    local procedure UpgradeEU3PartyPurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VATStatementLine: Record "VAT Statement Line";
    begin
        UpdateRecords(Database::"Purchase Header", 11200, PurchaseHeader.FieldNo("EU 3 Party Trade"));
        UpdateRecords(Database::"Purch. Inv. Header", 11200, PurchInvHeader.FieldNo("EU 3 Party Trade"));
        UpdateRecords(Database::"Purch. Cr. Memo Hdr.", 11200, PurchCrMemoHdr.FieldNo("EU 3 Party Trade"));
        UpdateRecords(Database::"VAT Statement Line", 11200, VATStatementLine.FieldNo("EU 3 Party Trade"));
    end;
#endif

#if not CLEAN26
    local procedure UpdateRecords(SourceTableId: Integer; SourceFieldId: Integer; TargetFieldId: Integer)
    var
        DataTransfer: DataTransfer;
        EU3PartyTradeFilter: Enum "EU3 Party Trade Filter";
    begin
        DataTransfer.SetTables(SourceTableId, SourceTableId);
        DataTransfer.AddSourceFilter(SourceFieldId, '=%1', true);
        DataTransfer.AddConstantValue(EU3PartyTradeFilter::EU3, TargetFieldId);
        DataTransfer.CopyFields();
        Clear(DataTransfer);

        DataTransfer.SetTables(SourceTableId, SourceTableId);
        DataTransfer.AddSourceFilter(SourceFieldId, '=%1', false);
        DataTransfer.AddConstantValue(EU3PartyTradeFilter::"non-EU3", TargetFieldId);
        DataTransfer.CopyFields();
        Clear(DataTransfer);
    end;
#endif

#if not CLEAN26
    local procedure UpdateVATSetup()
    var
        VATSetup: Record "VAT Setup";
    begin
        if not VATSetup.Get() then
            VATSetup.Insert();
        VATSetup."Enable EU 3-Party Purchase" := true;
        VATSetup.Modify(true);
    end;
#endif
}
#endif