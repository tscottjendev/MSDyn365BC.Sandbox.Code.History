codeunit 101092 "Create Cust. Posting Group"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          DemoDataSetup.DomesticCode(), XDomesticCustomersTxt,
          '992310', '996410', '', '', '7690001', '7050004', '7691001', '998610', '6690002', '6691001', '6691001');
        InsertData(
          DemoDataSetup.ForeignCode(), XForeignCustomersTxt,
          '992320', '996430', '', '', '7690001', '7050004', '7691001', '998610', '6690002', '6691001', '6691001');
        InsertData(
          DemoDataSetup.EUCode(), XCustomersInEUTxt,
          '992310', '996420', '', '', '7690001', '7050004', '7691001', '998610', '6690002', '6691001', '6691001');

        InsertData2(DemoDataSetup.DomesticCode(), '4310001', '4311001', '4312001', '4315001', '7691001', '4300003', '4300004', '4300005');
        InsertData2(DemoDataSetup.ForeignCode(), '', '', '', '', '', '', '', '');
        InsertData2(DemoDataSetup.EUCode(), '4310001', '4311001', '4312001', '4315001', '7691001', '4300003', '4300004', '4300005');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XDomesticCustomersTxt: Label 'Domestic customers';
        XCustomersInEUTxt: Label 'Customers in EU';
        XForeignCustomersTxt: Label 'Foreign customers (not EU)';

    procedure GetRoundingAccount(): code[20]
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        exit(MakeAdjustments.Convert('6690002'));
    end;

    procedure InsertData("Code": Code[20]; PostingGroupDescription: Text[50]; "Receivables Account": Code[20]; "Service Charge Acc.": Code[20]; "Pmt. Disc. Debit Acc.": Code[20]; "Pmt. Disc. Credit Acc.": Code[20]; "Invoice Rounding Account": Code[20]; "Additional Fee Acc.": Code[20]; "Interest Acc.": Code[20]; "Credit Appl. Rounding Account": Code[20]; "Debit Appl. Rounding Account": Code[20]; "Payment Tolerance Debit Acc.": Code[20]; "Payment Tolerance Credit Acc.": Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        CustomerPostingGroup.Init();
        CustomerPostingGroup.Validate(Code, Code);
        CustomerPostingGroup.Validate(Description, PostingGroupDescription);
        CustomerPostingGroup.Validate("Receivables Account", MakeAdjustments.Convert("Receivables Account"));
        CustomerPostingGroup.Validate("Service Charge Acc.", MakeAdjustments.Convert("Service Charge Acc."));
        CustomerPostingGroup.Validate("Payment Disc. Debit Acc.", MakeAdjustments.Convert("Pmt. Disc. Debit Acc."));
        CustomerPostingGroup.Validate("Payment Disc. Credit Acc.", MakeAdjustments.Convert("Pmt. Disc. Credit Acc."));
        CustomerPostingGroup.Validate("Additional Fee Account", MakeAdjustments.Convert("Additional Fee Acc."));
        CustomerPostingGroup.Validate("Interest Account", MakeAdjustments.Convert("Interest Acc."));
        CustomerPostingGroup.Validate("Invoice Rounding Account", MakeAdjustments.Convert("Invoice Rounding Account"));
        CustomerPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Credit Appl. Rounding Account"));
        CustomerPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", MakeAdjustments.Convert("Debit Appl. Rounding Account"));
        CustomerPostingGroup.Validate("Debit Rounding Account", GetRoundingAccount());
        CustomerPostingGroup.Validate("Credit Rounding Account", GetRoundingAccount());
        CustomerPostingGroup.Validate("Payment Tolerance Debit Acc.", MakeAdjustments.Convert("Payment Tolerance Debit Acc."));
        CustomerPostingGroup.Validate("Payment Tolerance Credit Acc.", MakeAdjustments.Convert("Payment Tolerance Credit Acc."));
        CustomerPostingGroup.Insert();
    end;

    procedure InsertData2("Code": Code[10]; "Bills Account": Code[20]; "Discted. Bills Acc.": Code[20]; "Bills on Collection Acc.": Code[20]; "Bills Dishonored Acc.": Code[20]; "Finance Income Acc.": Code[20]; "Factoring for Collection Acc.": Code[20]; "Factoring for Discount Acc.": Code[20]; "Rejected Factoring Acc.": Code[20])
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        CustomerPostingGroup.Get(Code);
        CustomerPostingGroup.Validate("Bills Account", MakeAdjustments.Convert("Bills Account"));
        CustomerPostingGroup.Validate("Discted. Bills Acc.", MakeAdjustments.Convert("Discted. Bills Acc."));
        CustomerPostingGroup.Validate("Bills on Collection Acc.", MakeAdjustments.Convert("Bills on Collection Acc."));
        CustomerPostingGroup.Validate("Rejected Bills Acc.", MakeAdjustments.Convert("Bills Dishonored Acc."));
        CustomerPostingGroup.Validate("Finance Income Acc.", MakeAdjustments.Convert("Finance Income Acc."));
        CustomerPostingGroup.Validate("Factoring for Collection Acc.", MakeAdjustments.Convert("Factoring for Collection Acc."));
        CustomerPostingGroup.Validate("Factoring for Discount Acc.", MakeAdjustments.Convert("Factoring for Discount Acc."));
        CustomerPostingGroup.Validate("Rejected Factoring Acc.", MakeAdjustments.Convert("Rejected Factoring Acc."));
        CustomerPostingGroup.Modify();
    end;
}

