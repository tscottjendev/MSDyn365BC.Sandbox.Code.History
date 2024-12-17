// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Routing;
using System.Utilities;

page 99000810 "Routing Version"
{
    Caption = 'Routing Version';
    DataCaptionExpression = Rec.Caption();
    PageType = ListPlus;
    SourceTable = "Routing Version";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Version Code"; Rec."Version Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the version code of the routing.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a description for the routing version.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies in which order operations in the routing are performed.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the status of this routing version.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting date for this routing version.';
                }
            }
            part(RoutingLine; "Routing Version Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Routing No." = field("Routing No."),
                              "Version Code" = field("Version Code");
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyRouting)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy &Routing';
                    Image = CopyRouteHeader;
                    ToolTip = 'Copy an existing routing to quickly create a similar BOM.';

                    trigger OnAction()
                    begin
                        if not Confirm(Text000, false) then
                            exit;

                        RtngHeader.Get(Rec."Routing No.");
                        CopyRouting.CopyRouting(Rec."Routing No.", '', RtngHeader, Rec."Version Code");
                    end;
                }
                action("Copy Routing &Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Copy Routing &Version';
                    Ellipsis = true;
                    Image = CopyRouteVersion;
                    ToolTip = 'Copy an existing routing version to quickly create a similar routing.';

                    trigger OnAction()
                    begin
                        CopyRouting.SelectCopyFromVersionList(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(CopyRouting_Promoted; CopyRouting)
                {
                }
                actionref("Copy Routing &Version_Promoted"; "Copy Routing &Version")
                {
                }
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (Rec.Status in [Rec.Status::Certified, Rec.Status::Closed]) then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(CertifyQst, CurrPage.Caption), false) then
                exit(false);

        exit(true);
    end;

    var
        RtngHeader: Record "Routing Header";
        CopyRouting: Codeunit "Routing Line-Copy Lines";
        ConfirmManagement: Codeunit "Confirm Management";
#pragma warning disable AA0074
        Text000: Label 'Copy from routing header?';
#pragma warning restore AA0074
        CertifyQst: Label 'The %1 has not been certified. Are you sure you want to exit?', Comment = '%1 = page caption (Production BOM)';
}

