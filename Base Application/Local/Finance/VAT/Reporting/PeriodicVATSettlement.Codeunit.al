// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Utilities;

codeunit 12195 "Periodic VAT Settlement"
{
    Access = Internal;

    procedure CheckIfSplitIsNeeded(Period: Code[10]): Boolean
    var
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
    begin
        PeriodicVATSettlementEntry.SetRange("VAT Period", Period);
        PeriodicVATSettlementEntry.SetRange("Activity Code", '');
        exit(not PeriodicVATSettlementEntry.IsEmpty());

    end;

    procedure CreateSeparateEntries(Period: Code[10])
    var
        ActivityCode: Record "Activity Code";
        PeriodicVATSettlementEntry: Record "Periodic VAT Settlement Entry";
    begin
        if ActivityCode.Findset() then
            repeat
                PeriodicVATSettlementEntry.Init();
                PeriodicVATSettlementEntry."VAT Period" := Period;
                PeriodicVATSettlementEntry."Activity Code" := ActivityCode.Code;
                if PeriodicVATSettlementEntry.Insert() then;
            until ActivityCode.Next() = 0;
    end;
}
