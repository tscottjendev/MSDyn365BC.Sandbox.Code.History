// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 773 "Fin. Report Excel Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Financial Report Excel Templates';
    PageType = List;
    SourceTable = "Fin. Report Excel Template";
    DataCaptionExpression = GetCaption();
    InsertAllowed = false;
    AboutTitle = 'About financial report Excel templates';
    AboutText = 'On this page, you can create and import Excel workbooks as a template for an Excel version of the financial report. This allows you to format and visualize the financial report data directly in Excel and have it reused in the future.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Financial Report Name"; Rec."Financial Report Name")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(New)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New';
                ToolTip = 'Create a new template.';
                AboutTitle = 'About creating new templates.';
                AboutText = 'Use this action to create a new template. Newly created templates comes with the default Excel workbook as a starting point.';
                Image = NewDocument;
                Scope = Repeater;

                trigger OnAction()
                var
                    FinReportExcelTemplate: Record "Fin. Report Excel Template";
                    ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
                    NewFinReportExcelTempl: Page "New Fin. Report Excel Templ.";
                    OutStream: OutStream;
                begin
                    NewFinReportExcelTempl.SetSource(TempFinancialReport.Name, '');
                    if NewFinReportExcelTempl.RunModal() = Action::Ok then begin
                        NewFinReportExcelTempl.GetRecord(FinReportExcelTemplate);
                        ExportAccSchedToExcel.SetOptions(this.AccScheduleLine, this.TempFinancialReport."Financial Report Column Group", this.TempFinancialReport.UseAmountsInAddCurrency, this.TempFinancialReport.Name);
                        ExportAccSchedToExcel.SetSaveToStream(true);
                        ExportAccSchedToExcel.RunModal();
                        FinReportExcelTemplate.Template.CreateOutStream(OutStream);
                        ExportAccSchedToExcel.GetSavedStream(OutStream);
                        FinReportExcelTemplate.Insert();
                    end;
                end;

            }
            action(Copy)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Copy';
                ToolTip = 'Make a copy of the selected template.';
                Image = CopyDocument;
                Scope = Repeater;
                Enabled = Rec.Code <> '';

                trigger OnAction()
                var
                    FinReportExcelTemplate: Record "Fin. Report Excel Template";
                    NewFinReportExcelTempl: Page "New Fin. Report Excel Templ.";
                    InStream: InStream;
                    OutStream: OutStream;
                begin
                    NewFinReportExcelTempl.SetSource(TempFinancialReport.Name, Rec.Code);
                    if NewFinReportExcelTempl.RunModal() = Action::Ok then begin
                        NewFinReportExcelTempl.GetRecord(FinReportExcelTemplate);
                        Rec.CalcFields(Template);
                        Rec.Template.CreateInStream(InStream);
                        FinReportExcelTemplate.Template.CreateOutStream(OutStream);
                        CopyStream(OutStream, InStream);
                        FinReportExcelTemplate.Insert();
                    end;
                end;
            }
        }
        area(Processing)
        {
            action(Export)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export';
                ToolTip = 'Export the selected template.';
                AboutTitle = 'About exporting templates';
                AboutText = 'Use this action to export the selected template, which will create an Excel workbook on your device with data from the financial report. You can then create a new sheet and apply your own formatting and visualization with the data.';
                Image = Export;
                Scope = Repeater;
                Enabled = Rec.Code <> '';

                trigger OnAction()
                var
                    ExportAccSchedToExcel: Report "Export Acc. Sched. to Excel";
                begin
                    ExportAccSchedToExcel.SetOptions(this.AccScheduleLine, this.TempFinancialReport."Financial Report Column Group", this.TempFinancialReport.UseAmountsInAddCurrency, this.TempFinancialReport.Name);
                    ExportAccSchedToExcel.SetUseExistingTemplate(Rec);
                    ExportAccSchedToExcel.Run();
                end;
            }
            fileuploadaction(Import)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import';
                ToolTip = 'Import and replace the template file for the selected template.';
                AboutTitle = 'About importing templates';
                AboutText = 'Use this action to import the customized Excel workbook. You can then specify this template code on the financial report, and it will be used in future exports of the report.';
                Image = Import;
                Scope = Repeater;
                Enabled = Rec.Code <> '';
                AllowMultipleFiles = false;
                AllowedFileExtensions = '.xlsx';

                trigger OnAction(Files: List of [FileUpload])
                var
                    InStream: InStream;
                    OutStream: OutStream;
                begin
                    Files.Get(1).CreateInStream(InStream);
                    Rec.Template.CreateOutStream(OutStream);
                    CopyStream(OutStream, InStream);
                    Rec.Modify();
                end;
            }
        }

        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(New_Promoted; New) { }
                actionref(Copy_Promoted; Copy) { }
                actionref(Export_Promoted; Export) { }
                actionref(Import_Promoted; Import) { }
            }
        }
    }

    var
        TempFinancialReport: Record "Financial Report";
        AccScheduleLine: Record "Acc. Schedule Line";

    internal procedure SetSource(var TempFinancialReport: Record "Financial Report"; var AccScheduleLine: Record "Acc. Schedule Line")
    begin
        this.TempFinancialReport.Copy(TempFinancialReport);
        this.AccScheduleLine.Copy(AccScheduleLine);

        Rec.FilterGroup(2);
        Rec.SetRange("Financial Report Name", TempFinancialReport.Name);
        Rec.FilterGroup(0);
    end;

    internal procedure GetCaption(): Text
    begin
        exit(TempFinancialReport.Name);
    end;
}