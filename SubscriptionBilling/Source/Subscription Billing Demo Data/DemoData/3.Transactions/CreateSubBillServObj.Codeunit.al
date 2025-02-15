namespace Microsoft.SubscriptionBilling;

codeunit 8116 "Create Sub. Bill. Serv. Obj."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateServiceObjects();
    end;

    local procedure CreateServiceObjects()
    var
        CommonCustomer: Codeunit "Create Common Customer/Vendor";
        ContosoSubscriptionBilling: Codeunit "Contoso Subscription Billing";
        ContosoUtilities: Codeunit "Contoso Utilities";
        CreateSubBillItem: Codeunit "Create Sub. Bill. Item";
        CreateSubBillPackages: Codeunit "Create Sub. Bill. Packages";
    begin
        ContosoSubscriptionBilling.InsertServiceObject(SOB100001(), CommonCustomer.DomesticCustomer1(), CreateSubBillItem.SB1100(), ContosoUtilities.AdjustDate(19020101D), 1);
        ContosoSubscriptionBilling.InsertServiceCommitments(SOB100001(), ContosoUtilities.AdjustDate(19020101D), CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SOB100002(), CommonCustomer.DomesticCustomer2(), CreateSubBillItem.SB1102(), ContosoUtilities.AdjustDate(19020101D), 5);
        ContosoSubscriptionBilling.InsertServiceCommitments(SOB100002(), ContosoUtilities.AdjustDate(19020101D), CreateSubBillPackages.MonthlySubscription());

        ContosoSubscriptionBilling.InsertServiceObject(SOB100003(), CommonCustomer.DomesticCustomer3(), CreateSubBillItem.SB1103(), ContosoUtilities.AdjustDate(19020101D), 1);
        ContosoSubscriptionBilling.InsertServiceCommitments(SOB100003(), ContosoUtilities.AdjustDate(19020101D), CreateSubBillPackages.MaintenanceSilver());
        ContosoSubscriptionBilling.InsertServiceCommitments(SOB100003(), ContosoUtilities.AdjustDate(19020101D), CreateSubBillPackages.Warranty());

        ContosoSubscriptionBilling.InsertServiceObject(SOB100004(), CommonCustomer.DomesticCustomer1(), CreateSubBillItem.SB1105(), ContosoUtilities.AdjustDate(19020101D), 3);
        ContosoSubscriptionBilling.InsertServiceCommitments(SOB100004(), ContosoUtilities.AdjustDate(19020101D), CreateSubBillPackages.UDUsage());
    end;


    procedure SOB100001(): Code[20]
    begin
        exit('SOB100001');
    end;

    procedure SOB100002(): Code[20]
    begin
        exit('SOB100002');
    end;

    procedure SOB100003(): Code[20]
    begin
        exit('SOB100003');
    end;

    procedure SOB100004(): Code[20]
    begin
        exit('SOB100004');
    end;
}