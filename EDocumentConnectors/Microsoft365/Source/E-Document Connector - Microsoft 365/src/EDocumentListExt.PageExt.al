namespace Microsoft.EServices.EDocumentConnector.Microsoft365;

using Microsoft.eServices.EDocument;

pageextension 6383 EDocumentListExt extends "E-Documents"
{
    actions
    {
        addlast(Processing)
        {
            action(ViewMailMessage)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View e-mail message';
                ToolTip = 'View the source e-mail message.';
                Image = Email;
                Visible = EmailActionsVisible;

                trigger OnAction()
                begin
                    if (Rec."Mail Message Id" <> '') then
                        HyperLink(StrSubstNo(WebLinkTxt, Rec."Mail Message Id"))
                end;
            }
        }
        addafter(Promoted_EDocumentServices)
        {
            actionref(Promoted_ViewMailMessage; ViewMailMessage) { }
        }
    }

    trigger OnOpenPage()
    var
        OutlookIntegrationImpl: Codeunit "Outlook Integration Impl.";
    begin
        OutlookIntegrationImpl.SetConditionalVisibilityFlag(EmailActionsVisible);
    end;

    var
        EmailActionsVisible: Boolean;
        WebLinkTxt: label 'https://outlook.office365.com/owa/?ItemID=%1&exvsurl=1&viewmodel=ReadMessageItem', Locked = true;
}