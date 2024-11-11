// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

tableextension 11300 "Service Header BE" extends "Service Header"
{
    fields
    {
#if not CLEANSCHEMA23
        field(11300; "Journal Template Name"; Code[10])
        {
            Caption = 'Template Name (obsolete)';
            DataClassification = SystemMetadata;
            ObsoleteReason = 'Replaced by W1 field Journal Templ. Name';
            ObsoleteState = Removed;
            ObsoleteTag = '23.0';
        }
#endif
        field(11310; "Enterprise No."; Text[50])
        {
            Caption = 'Enterprise No.';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
    }
}
