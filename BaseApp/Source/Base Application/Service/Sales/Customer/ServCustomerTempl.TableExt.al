// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Customer;

using Microsoft.Sales.Customer;
using Microsoft.Service.Setup;

tableextension 6451 "Serv. Customer Templ." extends "Customer Templ."
{
    fields
    {
        field(5900; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            DataClassification = CustomerContent;
            TableRelation = "Service Zone";
        }
    }
}
