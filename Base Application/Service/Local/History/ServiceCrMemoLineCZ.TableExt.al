#if not CLEANSCHEMA23
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

tableextension 11804 "Service Cr.Memo Line CZ" extends "Service Cr.Memo Line"
{
    fields
    {
#if not CLEANSCHEMA23
        field(11764; "VAT Difference (LCY)"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'VAT Difference (LCY)';
            DataClassification = CustomerContent;
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
            ObsoleteReason = 'Functionality will be removed and this field should not be used.';
        }
#endif
    }
}
#endif