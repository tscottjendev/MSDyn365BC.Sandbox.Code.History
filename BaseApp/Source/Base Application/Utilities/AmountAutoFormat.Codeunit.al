// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Text;

codeunit 347 "Amount Auto Format"
{
    Permissions = tabledata "General Ledger Setup" = r;
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        GLSetupRead: Boolean;
        CurrencyCodeFormatPrefixTxt: Label '<C,%1>', Locked = true;
        FormatTxt: Label '<Precision,%1><Standard Format,0>', Locked = true;
        CurrFormatTxt: Label '%3%2<Precision,%1><Standard Format,0>', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnResolveAutoFormat', '', false, false)]
    local procedure ResolveAutoFormatTranslateCase1(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    begin
        // Amount
        if not Resolved and GetGLSetup() then
            if AutoFormatType = AutoFormatType::AmountFormat then begin
                Result := GetAmountPrecisionFormat(AutoFormatExpr);
                Resolved := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnResolveAutoFormat', '', false, false)]
    local procedure ResolveAutoFormatTranslateCase2(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    begin
        // Unit Amount
        if not Resolved and GetGLSetup() then
            if AutoFormatType = AutoFormatType::UnitAmountFormat then begin
                Result := GetUnitAmountPrecisionFormat(AutoFormatExpr);
                Resolved := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnResolveAutoFormat', '', false, false)]
    local procedure ResolveAutoFormatTranslateCase10(AutoFormatType: Enum "Auto Format"; AutoFormatExpr: Text[80]; var Result: Text[80]; var Resolved: Boolean)
    begin
        // Custom or AutoFormatExpr = '1[,<curr>[,<PrefixedText>]]' or '2[,<curr>[,<PrefixedText>]]'
        if not Resolved and GetGLSetup() then
            if AutoFormatType = AutoFormatType::CurrencySymbolFormat then begin
                Result := GetCustomFormat(AutoFormatExpr);
                Resolved := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Auto Format", 'OnReadRounding', '', false, false)]
    local procedure ReadRounding(var AmountRoundingPrecision: Decimal)
    begin
        GetGLSetup();
        AmountRoundingPrecision := GLSetup."Amount Rounding Precision";
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterDeleteEvent', '', false, false)]
    local procedure ResetGLSetupReadOnGLSetupDelete()
    begin
        GLSetupRead := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterInsertEvent', '', false, false)]
    local procedure ResetGLSetupReadOnGLSetupInsert()
    begin
        GLSetupRead := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure ResetGLSetupReadOnGLSetupModify()
    begin
        GLSetupRead := false;
    end;

    local procedure GetGLSetup(): Boolean
    begin
        if not GLSetupRead then
            GLSetupRead := GLSetup.Get();
        exit(GLSetupRead);
    end;

    local procedure GetAmountPrecisionFormat(AutoFormatExpr: Text[80]): Text[80]
    var
        Result: Text[80];
    begin
        if AutoFormatExpr = '' then begin
            Result := StrSubstNo(FormatTxt, GLSetup."Amount Decimal Places");
            PrefixCurrencyCodeFormatString(Result, GLSetup."LCY Code", '');
            exit(Result)
        end;
        if GetCurrencyAndAmount(AutoFormatExpr) then begin
            Result := StrSubstNo(FormatTxt, Currency."Amount Decimal Places");
            PrefixCurrencyCodeFormatString(Result, Currency."ISO Code", '');
            exit(Result)
        end;
        Result := StrSubstNo(FormatTxt, GLSetup."Amount Decimal Places");
        PrefixCurrencyCodeFormatString(Result, GLSetup."LCY Code", '');
        exit(Result)
    end;

    local procedure GetUnitAmountPrecisionFormat(AutoFormatExpr: Text[80]): Text[80]
    var
        Result: Text[80];
    begin
        if AutoFormatExpr = '' then begin
            Result := StrSubstNo(FormatTxt, GLSetup."Unit-Amount Decimal Places");
            PrefixCurrencyCodeFormatString(Result, GLSetup."LCY Code", '');
            exit(Result)
        end;
        if GetCurrencyAndUnitAmount(AutoFormatExpr) then begin
            Result := StrSubstNo(FormatTxt, Currency."Unit-Amount Decimal Places");
            PrefixCurrencyCodeFormatString(Result, Currency."ISO Code", '');
            exit(Result)
        end;
        Result := StrSubstNo(FormatTxt, GLSetup."Unit-Amount Decimal Places");
        PrefixCurrencyCodeFormatString(Result, GLSetup."LCY Code", '');
        exit(Result)
    end;

    local procedure PrefixCurrencyCodeFormatString(var AutoFormatExpression: Text[80]; CurrencyCode: Code[10]; AutoFormatPrefixedText: Text[80])
    begin
        AutoFormatExpression := CopyStr(StrSubstNo(CurrencyCodeFormatPrefixTxt, CurrencyCode) + AutoFormatPrefixedText + AutoFormatExpression, 1, 80);
    end;

    local procedure GetCustomFormat(AutoFormatExpr: Text[80]): Text[80]
    var
        FormatSubtype: Text;
        AutoFormatCurrencyCode: Text[80];
        AutoFormatPrefixedText: Text[80];
    begin
        FormatSubtype := SelectStr(1, AutoFormatExpr);
        if FormatSubtype in ['1', '2'] then begin
            GetCurrencyCodeAndPrefixedText(AutoFormatExpr, AutoFormatCurrencyCode, AutoFormatPrefixedText);
            case FormatSubtype of
                '1':
                    exit(GetCustomAmountFormat(AutoFormatCurrencyCode, AutoFormatPrefixedText));
                '2':
                    exit(GetCustomUnitAmountFormat(AutoFormatCurrencyCode, AutoFormatPrefixedText));
            end;
        end else
            exit(AutoFormatExpr);
    end;

    local procedure GetCustomAmountFormat(AutoFormatCurrencyCode: Text[80]; AutoFormatPrefixedText: Text[80]): Text[80]
    var
        Result: Text[80];
    begin
        if AutoFormatCurrencyCode = '' then begin
            Result := StrSubstNo(CurrFormatTxt, GLSetup."Amount Decimal Places", GLSetup.GetCurrencySymbol(), AutoFormatPrefixedText);
            PrefixCurrencyCodeFormatString(Result, GLSetup."LCY Code", '');
            exit(Result);
        end;
        if GetCurrencyAndAmount(AutoFormatCurrencyCode) then begin
            Result := StrSubstNo(CurrFormatTxt, Currency."Amount Decimal Places", Currency.GetCurrencySymbol(), AutoFormatPrefixedText);
            PrefixCurrencyCodeFormatString(Result, Currency."ISO Code", '');
            exit(Result);
        end;
        Result := StrSubstNo(CurrFormatTxt, GLSetup."Amount Decimal Places", GLSetup.GetCurrencySymbol(), AutoFormatPrefixedText);
        PrefixCurrencyCodeFormatString(Result, GLSetup."LCY Code", '');
        exit(Result);
    end;

    local procedure GetCustomUnitAmountFormat(AutoFormatCurrencyCode: Text[80]; AutoFormatPrefixedText: Text[80]): Text[80]
    var
        Result: Text[80];
    begin
        if AutoFormatCurrencyCode = '' then begin
            Result := StrSubstNo(CurrFormatTxt, GLSetup."Unit-Amount Decimal Places", GLSetup.GetCurrencySymbol(), AutoFormatPrefixedText);
            PrefixCurrencyCodeFormatString(Result, GLSetup."LCY Code", '');
            exit(Result);
        end;
        if GetCurrencyAndUnitAmount(AutoFormatCurrencyCode) then begin
            Result := StrSubstNo(CurrFormatTxt, Currency."Unit-Amount Decimal Places", Currency.GetCurrencySymbol(), AutoFormatPrefixedText);
            PrefixCurrencyCodeFormatString(Result, Currency."ISO Code", '');
            exit(Result);
        end;
        Result := StrSubstNo(CurrFormatTxt, GLSetup."Unit-Amount Decimal Places", GLSetup.GetCurrencySymbol(), AutoFormatPrefixedText);
        PrefixCurrencyCodeFormatString(Result, GLSetup."LCY Code", '');
        exit(Result);
    end;

    local procedure GetCurrency(CurrencyCode: Code[10]): Boolean
    begin
        if CurrencyCode = Currency.Code then
            exit(true);
        if CurrencyCode = '' then begin
            CLEAR(Currency);
            Currency.InitRoundingPrecision();
            exit(true);
        end;
        exit(Currency.GET(CurrencyCode));
    end;

    local procedure GetCurrencyAndAmount(AutoFormatValue: Text[80]): Boolean
    begin
        if GetCurrency(CopyStr(AutoFormatValue, 1, 10)) and
           (Currency."Amount Decimal Places" <> '')
        then
            exit(true);
        exit(false);
    end;

    local procedure GetCurrencyAndUnitAmount(AutoFormatValue: Text[80]): Boolean
    begin
        if GetCurrency(CopyStr(AutoFormatValue, 1, 10)) and
           (Currency."Unit-Amount Decimal Places" <> '')
        then
            exit(true);
        exit(false);
    end;

    local procedure GetCurrencyCodeAndPrefixedText(AutoFormatExpr: Text[80]; var AutoFormatCurrencyCode: Text[80]; var AutoFormatPrefixedText: Text[80])
    var
        NumCommasInAutoFormatExpr: Integer;
    begin
        NumCommasInAutoFormatExpr := StrLen(AutoFormatExpr) - StrLen(DelChr(AutoFormatExpr, '=', ','));
        if NumCommasInAutoFormatExpr >= 1 then
            AutoFormatCurrencyCode := CopyStr(SelectStr(2, AutoFormatExpr), 1, 80);
        if NumCommasInAutoFormatExpr >= 2 then
            AutoFormatPrefixedText := CopyStr(SelectStr(3, AutoFormatExpr), 1, 80);
        if AutoFormatPrefixedText <> '' then
            AutoFormatPrefixedText := CopyStr(AutoFormatPrefixedText + ' ', 1, 80);
    end;
}
