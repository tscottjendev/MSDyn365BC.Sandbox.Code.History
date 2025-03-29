// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

enum 1700 "Deferral Calculation Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Straight-Line") { Caption = 'Straight-Line'; }
    value(1; "Equal per Period") { Caption = 'Equal per Period'; }
    value(2; "Days per Period") { Caption = 'Days per Period'; }
    value(3; "User-Defined") { Caption = 'User-Defined'; }
}
