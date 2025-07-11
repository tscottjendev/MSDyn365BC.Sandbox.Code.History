// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Posted deferral header records that track completed deferral schedules after posting.
/// Maintains a permanent record of deferral parameters for posted transactions.
/// </summary>
table 1704 "Posted Deferral Header"
{
    Caption = 'Posted Deferral Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of source document (Purchase, Sales, or G/L) that initiated this posted deferral.
        /// </summary>
        field(1; "Deferral Doc. Type"; Enum "Deferral Document Type")
        {
            Caption = 'Deferral Doc. Type';
        }
        /// <summary>
        /// General Journal document number associated with the posting of this deferral.
        /// </summary>
        field(2; "Gen. Jnl. Document No."; Code[20])
        {
            Caption = 'Gen. Jnl. Document No.';
        }
        /// <summary>
        /// G/L Account number that was used for the initial deferral posting.
        /// </summary>
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = "G/L Account" where(Blocked = const(false));
        }
        /// <summary>
        /// Document type ID from the posted source document.
        /// </summary>
        field(4; "Document Type"; Integer)
        {
            Caption = 'Document Type';
        }
        /// <summary>
        /// Document number from the posted source document.
        /// </summary>
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Line number within the posted source document.
        /// </summary>
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Deferral template code that was used for this posted schedule.
        /// </summary>
        field(7; "Deferral Code"; Code[10])
        {
            Caption = 'Deferral Code';
            NotBlank = true;
            TableRelation = "Deferral Template"."Deferral Code";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Amount that was deferred in the posted document currency.
        /// </summary>
        field(8; "Amount to Defer"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount to Defer';
        }
        /// <summary>
        /// Amount that was deferred in local currency (LCY) at the time of posting.
        /// </summary>
        field(9; "Amount to Defer (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount to Defer (LCY)';
        }
        /// <summary>
        /// Calculation method that was used for the posted deferral schedule.
        /// </summary>
        field(10; "Calc. Method"; Enum "Deferral Calculation Method")
        {
            Caption = 'Calc. Method';
        }
        /// <summary>
        /// Start date that was used for the posted deferral schedule.
        /// </summary>
        field(11; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        /// <summary>
        /// Number of periods that were defined for the posted deferral schedule.
        /// </summary>
        field(12; "No. of Periods"; Integer)
        {
            BlankZero = true;
            Caption = 'No. of Periods';
            NotBlank = true;
        }
        /// <summary>
        /// Description of the posted deferral schedule.
        /// </summary>
        field(13; "Schedule Description"; Text[100])
        {
            Caption = 'Schedule Description';
        }
        /// <summary>
        /// Currency code of the posted source document.
        /// </summary>
        field(15; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        /// <summary>
        /// G/L Account used for the temporary deferral balance in the posted transaction.
        /// </summary>
        field(16; "Deferral Account"; Code[20])
        {
            Caption = 'Deferral Account';
            NotBlank = true;
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false));
        }
        /// <summary>
        /// Customer or Vendor number associated with the posted deferral transaction.
        /// </summary>
        field(17; CustVendorNo; Code[20])
        {
            Caption = 'CustVendorNo';
        }
        /// <summary>
        /// Date when the deferral schedule was initially posted.
        /// </summary>
        field(18; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Unique entry number for this posted deferral header record.
        /// </summary>
        field(19; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
    }

    keys
    {
        key(Key1; "Deferral Doc. Type", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Deferral Doc. Type", "Account No.", "Posting Date", "Gen. Jnl. Document No.", "Document Type", "Document No.", "Line No.")
        {
        }
        key(Key3; "Deferral Doc. Type", CustVendorNo, "Posting Date", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        DeleteLines("Deferral Doc. Type", "Gen. Jnl. Document No.", "Account No.", "Document Type", "Document No.", "Line No.");
    end;

    /// <summary>
    /// Deletes a posted deferral header and all associated lines.
    /// </summary>
    /// <param name="DeferralDocType">Type of document containing the deferral</param>
    /// <param name="GenJnlDocNo">General journal document number</param>
    /// <param name="AccountNo">Account number from the posting</param>
    /// <param name="DocumentType">Document type ID</param>
    /// <param name="DocumentNo">Document number</param>
    /// <param name="LineNo">Line number within the document</param>
    procedure DeleteHeader(DeferralDocType: Integer; GenJnlDocNo: Code[20]; AccountNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    begin
        if LineNo <> 0 then
            if Get(DeferralDocType, GenJnlDocNo, AccountNo, DocumentType, DocumentNo, LineNo) then begin
                Delete();
                DeleteLines(Enum::"Deferral Document Type".FromInteger(DeferralDocType), GenJnlDocNo, AccountNo, DocumentType, DocumentNo, LineNo);
            end;
    end;

    local procedure DeleteLines(DeferralDocType: Enum "Deferral Document Type"; GenJnlDocNo: Code[20]; AccountNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer)
    var
        PostedDeferralLine: Record "Posted Deferral Line";
    begin
        PostedDeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        PostedDeferralLine.SetRange("Gen. Jnl. Document No.", GenJnlDocNo);
        PostedDeferralLine.SetRange("Account No.", AccountNo);
        PostedDeferralLine.SetRange("Document Type", DocumentType);
        PostedDeferralLine.SetRange("Document No.", DocumentNo);
        PostedDeferralLine.SetRange("Line No.", LineNo);
        OnDeleteLinesOnAfterSetFilters(PostedDeferralLine);
        PostedDeferralLine.DeleteAll();
    end;

    /// <summary>
    /// Deletes all posted deferral headers and lines for a specific document.
    /// Used for cleanup when documents are deleted or corrected.
    /// </summary>
    /// <param name="DeferralDocType">Type of document containing deferrals</param>
    /// <param name="GenJnlDocNo">General journal document number</param>
    /// <param name="AccountNo">Account number filter (optional)</param>
    /// <param name="DocumentType">Document type ID</param>
    /// <param name="DocumentNo">Document number</param>
    procedure DeleteForDoc(DeferralDocType: Integer; GenJnlDocNo: Code[20]; AccountNo: Code[20]; DocumentType: Integer; DocumentNo: Code[20])
    begin
        SetRange("Deferral Doc. Type", DeferralDocType);
        SetRange("Gen. Jnl. Document No.", GenJnlDocNo);
        if AccountNo <> '' then
            SetRange("Account No.", AccountNo);
        if DocumentNo <> '' then begin
            SetRange("Document Type", DocumentType);
            SetRange("Document No.", DocumentNo);
        end;
        DeleteAll(true);
    end;

    /// <summary>
    /// Initializes a posted deferral header from a deferral header record during posting.
    /// Transfers data and sets up posting-specific fields.
    /// </summary>
    /// <param name="DeferralHeader">Source deferral header</param>
    /// <param name="GenJnlDocNo">General journal document number</param>
    /// <param name="AccountNo">Account number from the posting</param>
    /// <param name="NewDocumentType">Document type for the posted record</param>
    /// <param name="NewDocumentNo">Document number for the posted record</param>
    /// <param name="NewLineNo">Line number for the posted record</param>
    /// <param name="DeferralAccount">Deferral account used in posting</param>
    /// <param name="CustVendNo">Customer or vendor number</param>
    /// <param name="PostingDate">Posting date</param>
    procedure InitFromDeferralHeader(DeferralHeader: Record "Deferral Header"; GenJnlDocNo: Code[20]; AccountNo: Code[20]; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; DeferralAccount: Code[20]; CustVendNo: Code[20]; PostingDate: Date)
    begin
        Init();
        TransferFields(DeferralHeader);
        "Gen. Jnl. Document No." := GenJnlDocNo;
        "Account No." := AccountNo;
        "Document Type" := NewDocumentType;
        "Document No." := NewDocumentNo;
        "Line No." := NewLineNo;
        "Deferral Account" := DeferralAccount;
        CustVendorNo := CustVendNo;
        "Posting Date" := PostingDate;
        OnBeforePostedDeferralHeaderInsert(Rec, DeferralHeader);
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedDeferralHeaderInsert(var PostedDeferralHeader: Record "Posted Deferral Header"; DeferralHeader: Record "Deferral Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLinesOnAfterSetFilters(var PostedDeferralLine: Record "Posted Deferral Line")
    begin
    end;
}

