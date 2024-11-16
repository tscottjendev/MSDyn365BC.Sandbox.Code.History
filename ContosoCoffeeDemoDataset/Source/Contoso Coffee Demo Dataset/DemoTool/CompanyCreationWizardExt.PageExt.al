pageextension 5240 "Company Creation Wizard Ext" extends "Company Creation Wizard"
{
    layout
    {
        addafter("Available Modules")
        {
            part("Contoso Modules Part"; "Contoso Modules Part")
            {
                ApplicationArea = All;
                Caption = 'Available Modules';
            }
        }
    }


    actions
    {
        modify(ActionFinish)
        {
            trigger OnAfterAction()
            var
                TempContosoDemoDataModule: Record "Contoso Demo Data Module" temporary;
                CompanyCreationContoso: Codeunit "Company Creation Contoso";
                NewCopmanyData: Enum "Company Demo Data Type";
                StartTime, EndTime : DateTime;
                NCDuration: Duration;
            begin
                StartTime := CurrentDateTime();
                NewCopmanyData := GetNewCompanyData();

                if not (NewCopmanyData in [NewCopmanyData::"Production - Setup Data Only", NewCopmanyData::"Evaluation - Contoso Sample Data"]) then
                    exit;

                CurrPage."Contoso Modules Part".Page.GetContosoRecord(TempContosoDemoDataModule);
                CompanyCreationContoso.CreateContosoDemodataInCompany(TempContosoDemoDataModule, GetNewCompanyName(), NewCopmanyData);
                EndTime := CurrentDateTime();
                NCDuration := StartTime - EndTime;
                Message('Contoso Time: %1', NCDuration);
            end;
        }
        addbefore(ActionBack)
        {
            action("Select All")
            {
                ApplicationArea = All;
                Caption = 'Select All';
                Image = AllLines;
                InFooterBar = true;
                Visible = DemoDataStepVisible;
                trigger OnAction()
                var
                    TempContosoDemoDataModule: Record "Contoso Demo Data Module" temporary;
                begin
                    CurrPage."Contoso Modules Part".Page.GetContosoRecord(TempContosoDemoDataModule);
                    TempContosoDemoDataModule.ModifyAll(Install, true);
                    CurrPage."Contoso Modules Part".Page.SetContosoRecord(TempContosoDemoDataModule);
                end;
            }
        }
        modify(ActionNext)
        {
            trigger OnAfterAction()
            var
                Step: Option Start,Creation,"Demo Data","Add Users",Finish;
            begin
                if GetStep() = Step::"Demo Data" then
                    DemoDataStepVisible := true
                else
                    DemoDataStepVisible := false;
            end;
        }
        modify(ActionBack)
        {
            trigger OnAfterAction()
            var
                Step: Option Start,Creation,"Demo Data","Add Users",Finish;
            begin
                if GetStep() = Step::"Demo Data" then
                    DemoDataStepVisible := true
                else
                    DemoDataStepVisible := false;
            end;
        }
    }
    var
        DemoDataStepVisible: Boolean;
}