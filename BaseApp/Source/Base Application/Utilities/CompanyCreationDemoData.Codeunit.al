codeunit 9192 "Company Creation Demo Data"
{

    procedure CheckDemoDataAppsAvailability()
    var
        MissingDemoAppsErr: ErrorInfo;
    begin
        // Check if Contoso required apps are installed
        // Prompt the user to install them
        if not CheckAndPromptUserToInstallContosoRequiredApps() then begin
            MissingDemoAppsErr.Message := DemoDataAppsNotAvailableErr;

            MissingDemoAppsErr.PageNo := Page::"Extension Management";
            MissingDemoAppsErr.AddNavigationAction(GoToExtensionManagementMsg);
            Error(MissingDemoAppsErr);
        end

        // Check if extra apps are installed
        // Notify the user about them
        // NotifyAboutAdditionalDemoDataApps();
    end;

    procedure CheckAndPromptUserToInstallContosoRequiredApps(): Boolean
    var
        DemoDataApps: List of [Guid];
    begin
        GetRequireDemoDataApps(DemoDataApps);

        if AreAppsInstalled(DemoDataApps) then
            exit(true);

        if Confirm(ContosoNotInstalledMsg, true) then begin
            InstallApps(DemoDataApps);
            // Check again if demo data apps are installed
            exit(AreAppsInstalled(DemoDataApps));
        end;
    end;

    local procedure InstallApps(DemoDataApps: List of [Guid])
    var
        DemoDataApp: Guid;
    begin
        foreach demoDataApp in DemoDataApps do
            TryInstallApp(DemoDataApp);
    end;

    [TryFunction]
    local procedure TryInstallApp(App: Guid)
    var
        ExtensionManagement: Codeunit "Extension Management";
    begin
        if not ExtensionManagement.InstallExtension(App, GlobalLanguage, false) then
            if IsSaas() then
                ExtensionManagement.InstallMarketplaceExtension(App);
    end;

    local procedure AreAppsInstalled(DemoDataApps: List of [Guid]): Boolean
    var
        DemoDataApp: Guid;
    begin
        foreach DemoDataApp in DemoDataApps do
            if not ExtentionManagement.IsInstalledByAppId(DemoDataApp) then
                exit(false);

        exit(true);
    end;

    local procedure GetRequireDemoDataApps(var DemoDataApps: List of [Guid])
    var
        CountryApp: Guid;
    begin
        DemoDataApps.Add('5a0b41e9-7a42-4123-d521-2265186cfb31');

        CountryApp := GetCountryContosoAppId();
        if not IsNullGuid(CountryApp) then
            DemoDataApps.Add(CountryApp);
    end;

    local procedure IsSaas(): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaS() then
            exit(false);
    end;

    procedure NotifyAboutAdditionalDemoDataApps(): Boolean
    var
        DemoDataNotification: Notification;
        DemoDataApps, MissingDemoDataApps : List of [Guid];
        DemoDataApp: Guid;
    begin
        AddDemoDataAdditionalApps(DemoDataApps);
        OnBeforeNotifyAboutAdditionalDemoDataApps(DemoDataApps);

        foreach DemoDataApp in DemoDataApps do
            if not ExtentionManagement.IsInstalledByAppId(DemoDataApp) then
                MissingDemoDataApps.Add(DemoDataApp);

        if MissingDemoDataApps.Count > 0 then begin
            DemoDataNotification.Id(GetAdditionalDemoDataNotificationId());
            DemoDataNotification.SetData('NotificationId', GetAdditionalDemoDataNotificationId());
            DemoDataNotification.Message(AdditionDemoDataAvailableMsg);
            DemoDataNotification.AddAction(InstallAllMsg, Codeunit::"Company Creation Demo Data", 'InstallAll');
            DemoDataNotification.AddAction(GoToExtensionManagementMsg, Codeunit::"Company Creation Demo Data", 'OpenExtensionManagement');
            DemoDataNotification.Send();
        end
    end;

    procedure OpenExtensionManagement(HostNotification: Notification)
    begin
        Page.Run(Page::"Extension Management");
    end;

    procedure InstallAll(HostNotification: Notification)
    var
        DemoDataApps: List of [Guid];
        DemoDataApp: Guid;
    begin
        AddDemoDataAdditionalApps(DemoDataApps);
        OnBeforeNotifyAboutAdditionalDemoDataApps(DemoDataApps);

        foreach DemoDataApp in DemoDataApps do
            if ExtentionManagement.IsInstalledByAppId(DemoDataApp) then
                TryInstallApp(DemoDataApp);
    end;

    local procedure GetAdditionalDemoDataNotificationId(): Guid
    var
    begin
        exit('3478eb81-8caf-2245-41b7-65eaa90b7821');
    end;

    local procedure AddDemoDataAdditionalApps(var DemoDataAppList: List of [Guid])
    begin
        // Sustainability Demo Data
        DemoDataAppList.Add('a0673989-48a4-48a0-9517-499c9f4037d3');
        // E-Documents Demo Data
        DemoDataAppList.Add('de0dddf3-9917-430d-8d20-6e7679a08500');
    end;

    local procedure GetCountryContosoAppId(): Guid
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ApplicationFamily: Text;
    begin
        ApplicationFamily := EnvironmentInformation.GetApplicationFamily();

        case ApplicationFamily of
            'AT':
                exit('4b0b41f9-7a13-4231-d521-1465186cfb32');
            'AU':
                exit('4b0b41f9-7a13-4231-d521-2465186cfb32');
            'BE':
                exit('5b0b41a1-7b42-4123-a521-2265186cfb33');
            'CA':
                exit('5b0b41a1-7b42-3113-a521-2265186cfb33');
            'CH':
                exit('4b1c41f9-7a13-4231-d521-2465194cfb32');
            'CZ':
                exit('acbbfbc7-75c1-436f-8b22-926d741b2616');
            'DE':
                exit('4b1c41f9-7a13-4122-d521-2465194cfb32');
            'DK':
                exit('5b0b41a1-7b42-1134-a521-2265186cfb33');
            'ES':
                exit('5b0a41a1-7b42-4123-a521-2265186cfb31');
            'FI':
                exit('5b0a31a1-6b42-4123-a521-2265186cfb31');
            'FR':
                exit('5b0a41a1-7b42-4123-a631-2265186cfb31');
            'GB':
                exit('5b0b41a1-7b42-4153-b521-2265186cfb33');
            'IS':
                exit('5b1c41a1-6b42-4123-a521-2265186cfb31');
            'IT':
                exit('5b0a41a1-7b42-4123-a622-2265186cfb35');
            'MX':
                exit('5b0a41b5-7b42-4123-a521-2265186cfb31');
            'NL':
                exit('5b0a41a1-6c42-4123-a521-2265186cfb35');
            'NO':
                exit('5b0a41a1-7b42-1719-a521-2265186cfb31');
            'NZ':
                exit('5b0e32a1-7b42-4123-a521-2265186cfb31');
            'SE':
                exit('5b0a41a1-7b42-4123-a521-2265356bab31');
            'US':
                exit('3a3f33b1-7b42-4123-a521-2265186cfb31');
        end;

        exit('00000000-0000-0000-0000-000000000000');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNotifyAboutAdditionalDemoDataApps(var DemoDataAppList: List of [Guid])
    begin
    end;

    var
        ExtentionManagement: Codeunit "Extension Management";
        ContosoNotInstalledMsg: Label 'Contoso Demo Data app(s) are not installed, do you want to install them?';
        AdditionDemoDataAvailableMsg: Label 'Additional demo data apps are available';
        GoToExtensionManagementMsg: Label 'Go to Extension Management';
        InstallAllMsg: Label 'Install All';
        DemoDataAppsNotAvailableErr: Label 'Could not install Contoso demo data apps, you will have to go to Extension Management and install them manually';
}