#if not CLEANSCHEMA25
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247

tableextension 10810 SourceCodeFR extends "Source Code"
{
    fields
    {
#pragma warning disable AS0125
        field(10810; Simulation; Boolean)
        {
            Caption = 'Simulation';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Discontinued feature';
            ObsoleteState = Removed;
            ObsoleteTag = '15.0';
            MovedFrom = 'f3552374-a1f2-4356-848e-196002525837';
        }
#pragma warning restore AS0125
    }
}
#endif
