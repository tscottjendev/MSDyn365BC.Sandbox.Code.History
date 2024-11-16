page 5699 "Validate Demo Data"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Config. Package Table";
    Editable = false;
    SourceTableView = sorting("Table ID");
    DataCaptionFields = "Package Code";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(PackageCode; Rec."Package Code")
                {
                    ToolTip = 'Specifies Package Code';
                }
            }
            repeater(DemoData)
            {
                Caption = 'List of Tables to validate';

                field("Table ID"; Rec."Table ID")
                {
                    ToolTip = 'Specifies Table ID';
                }
                field(TableName; Rec."Table Name")
                {
                    ToolTip = 'Specifies Table Name';
                }
                field("No. of Fields Included"; Rec."No. of Fields Included")
                {
                    DrillDown = true;
                    DrillDownPageID = "Config. Package Fields";
                    ToolTip = 'Specifies No. of Fields Included';
                }
                field(NoOfDatabaseRecords; Rec.GetNoOfDatabaseRecordsText())
                {
                    Caption = 'No. of Database Records';
                    DrillDown = true;
                    ToolTip = 'Specifies how many database records have been created in connection with the migration.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowDatabaseRecords();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ValidateSelected)
            {
                Caption = 'Validate Selected';
                ToolTip = 'Validate Selected Table';
                Image = Action;

                trigger OnAction()
                var
                    ConfigPackageTable: Record "Config. Package Table";
                begin
                    CurrPage.GetRecord(ConfigPackageTable);
                    ValidateTable(CompanyName(), CompanyName().Replace('Evaluation', 'Contoso'), ConfigPackageTable."Table ID");
                    Message('Validation completed - No differences found');
                end;
            }
            action(ValidateFromSelected)
            {
                Caption = 'Validate From Selected';
                ToolTip = 'Validate all the tables that have a bigger table ID than the selected table';
                Image = AllLines;

                trigger OnAction()
                var
                    ConfigPackageTable: Record "Config. Package Table";
                    SelectedTableID: Integer;
                begin
                    CurrPage.GetRecord(ConfigPackageTable);
                    SelectedTableID := ConfigPackageTable."Table ID";

                    ConfigPackageTable.Reset();
                    ConfigPackageTable.SetRange("Package Code", Rec."Package Code");
                    ConfigPackageTable.SetFilter("Table ID", '>=%1', SelectedTableID);
                    if ConfigPackageTable.FindSet() then
                        repeat
                            ValidateTable(CompanyName(), CompanyName().Replace('Evaluation', 'Contoso'), ConfigPackageTable."Table ID");
                        until ConfigPackageTable.Next() = 0;

                    Message('Validation completed - No differences found');
                end;
            }
            action(ValidateAll)
            {
                Caption = 'Validate All';
                ToolTip = 'Validate all tables';
                Image = AllLines;

                trigger OnAction()
                var
                    ConfigPackageTable: Record "Config. Package Table";
                begin
                    DeleteOrModifyExpectedData();

                    ConfigPackageTable.SetRange("Package Code", Rec."Package Code");

                    if ConfigPackageTable.FindSet() then
                        repeat
                            ValidateTable(CompanyName(), CompanyName().Replace('Evaluation', 'Contoso'), ConfigPackageTable."Table ID");
                        until ConfigPackageTable.Next() = 0;

                    Message('Great! All tables have been validated - No differences found');
                end;
            }
            action(ExportSelected)
            {
                Caption = 'Export Selected';
                ToolTip = 'Export Selected Table';
                Image = Export;
                trigger OnAction()
                var
                    ConfigPackageTable: Record "Config. Package Table";
                begin
                    CurrPage.GetRecord(ConfigPackageTable);
                    ExportCSV(ConfigPackageTable."Table ID");
                end;
            }
            action(DeleteOrModifyExpected)
            {
                Caption = 'Delete Or Modify Expected';
                ToolTip = 'Delete or modify data that we expect, so it is faster to validate';
                Image = Delete;

                trigger OnAction()
                begin
                    DeleteOrModifyExpectedData();
                end;
            }
        }
        area(Promoted)
        {
            actionref(Promoted_validate; ValidateSelected) { }
            actionref(Promoted_validataall; ValidateAll) { }
        }
    }

    trigger OnInit()
    var
        ConfigPackageTable: Record "Config. Package Table";
    begin
        ConfigPackageTable.SetRange("Package Code", GetEvaluationPackageCode());
    end;

    local procedure DeleteOrModifyExpectedData()
    var
        Vendor: Record Vendor;
        SourceCode: Record "Source Code";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        DefaultDimension: Record "Default Dimension";
        ItemAttributeValue: Record "Item Attribute Value";
        PurchaseHeader: Record "Purchase Header";
        AccScheduleName: Record "Acc. Schedule Name";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if SourceCode.Get('START') then
            SourceCode.Delete(true);

        if Vendor.Get('10000') then begin
            Vendor."Home Page" := '';
            Vendor.Modify(true);
        end;

        if NoSeries.Get('JOB') then
            NoSeries.Delete(true);

        DefaultDimension.SetRange("Table ID", Database::Job);
        DefaultDimension.DeleteAll();

        if NoSeriesLine.Get('CASHFLOW', 10000) then begin
            NoSeriesLine.Validate("Ending No.", 'CF200000');
            NoSeriesLine.Modify(true);
        end;

        if NoSeriesLine.Get('PREC', 10000) then begin
            NoSeriesLine.Validate("Starting No.", 'PREC000');
            NoSeriesLine.Modify(true);
        end;

        ItemAttributeValue.SetRange("Attribute ID", 1);
        ItemAttributeValue.SetRange(Value, '');
        ItemAttributeValue.DeleteAll();

        if PurchaseHeader.Get(Enum::"Purchase Document Type"::Order, '106005') then
            PurchaseHeader.Delete(true);

        GeneralLedgerSetup.Get();

        if AccScheduleName.Get(GeneralLedgerSetup."Fin. Rep. for Balance Sheet") then
            AccScheduleName.Delete(true);

        if AccScheduleName.Get(GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt") then
            AccScheduleName.Delete(true);

        if AccScheduleName.Get(GeneralLedgerSetup."Fin. Rep. for Income Stmt.") then
            AccScheduleName.Delete(true);

        if AccScheduleName.Get(GeneralLedgerSetup."Fin. Rep. for Retained Earn.") then
            AccScheduleName.Delete(true);
    end;

    local procedure GetEvaluationPackageCode(): Code[20]
    var
        ConfigPackage: Record "Config. Package";
    begin
        ConfigPackage.SetRange("Package Name", 'Microsoft Dynamics 365 Business Central');
        if ConfigPackage.FindFirst() then
            exit(ConfigPackage.Code)
        else
            Error('Evaluation package code not found');
    end;

    local procedure ExportCSV(TableID: Integer)
    var
        FileMgt: Codeunit "File Management";
        TempBlobEvaluation, TempBlobContoso : Codeunit "Temp Blob";
        EvaluationTable, ContosoTable : RecordRef;
        EvaluationCompanyName, ContosoCompanyName : Text;
    begin
        EvaluationCompanyName := CompanyName();
        ContosoCompanyName := EvaluationCompanyName.Replace('Evaluation', 'Contoso');

        EvaluationTable.Open(TableID, false, EvaluationCompanyName);
        TempBlobEvaluation := GetTempBlob(EvaluationTable, TableID);

        FileMgt.BLOBExport(TempBlobEvaluation, EvaluationTable.Caption() + EvaluationCompanyName + '.csv', true);

        ContosoTable.Open(TableID, false, ContosoCompanyName);
        TempBlobContoso := GetTempBlob(ContosoTable, TableID);

        FileMgt.BLOBExport(TempBlobContoso, ContosoTable.Caption() + ContosoCompanyName + '.csv', true);
    end;

    procedure GetTempBlob(SelectedTable: RecordRef; TableID: Integer): Codeunit "Temp Blob"
    var
        TempCSVBuffer: Record "CSV Buffer" temporary;
        ConfigPackageField: Record "Config. Package Field";
        TempBlob: Codeunit "Temp Blob";
        CurrentField: FieldRef;
        LineNo, ColumnNo : Integer;
    begin
        LineNo := 0;
        if SelectedTable.FindSet() then
            repeat
                ColumnNo := 0;

                ConfigPackageField.SetRange("Package Code", Rec."Package Code");
                ConfigPackageField.SetRange("Table ID", TableID);
                ConfigPackageField.SetRange("Include Field", true);

                if ConfigPackageField.FindSet() then
                    repeat
                        CurrentField := SelectedTable.Field(ConfigPackageField."Field ID");

                        TempCSVBuffer.InsertEntry(LineNo, ColumnNo, CurrentField.Value);
                        ColumnNo += 1;
                    until ConfigPackageField.Next() = 0;
                LineNo += 1;
            until SelectedTable.Next() = 0;

        TempCSVBuffer.SaveDataToBlob(TempBlob, ',');
        exit(TempBlob);
    end;

    local procedure ValidateTable(EvaluationCompanyName: Text; ContosoCompanyName: Text; TableID: Integer)
    var
        EvaluationTable, ContosoTable : RecordRef;
        Position: Text;
    begin
        if IsSkippedTable(TableID) then
            exit;

        if IsExistingContosoModule(TableID) then
            exit;

        EvaluationTable.Open(TableID, false, EvaluationCompanyName);
        ContosoTable.Open(TableID, false, ContosoCompanyName);

        if EvaluationTable.FindSet() then
            repeat
                Position := EvaluationTable.GetPosition();
                ContosoTable.SetPosition(Position);
                ContosoTable.Find('=');

                ValidateField(EvaluationTable, ContosoTable, TableID);
            until EvaluationTable.Next() = 0;
    end;

    local procedure ValidateField(EvaluationRecord: RecordRef; ContosoRecord: RecordRef; TableID: Integer)
    var
        ConfigPackageField: Record "Config. Package Field";
        EvaluationField, ContosoField : FieldRef;
    begin
        ConfigPackageField.SetRange("Package Code", Rec."Package Code");
        ConfigPackageField.SetRange("Table ID", TableID);
        ConfigPackageField.SetRange("Include Field", true);

        if ConfigPackageField.FindSet() then
            repeat
                EvaluationField := EvaluationRecord.Field(ConfigPackageField."Field ID");
                ContosoField := ContosoRecord.Field(ConfigPackageField."Field ID");

                if not IsSkippedFieldInTable(TableID, ConfigPackageField."Field ID") then
                    if ComparableType(EvaluationField.Type()) then
                        if CompareValue(EvaluationField, ContosoField, EvaluationField.Type()) then
                            Error('Field `%1` in Table `%2` does not match. \\ Identification: %3. \\ Expected: %4 -- Actual: %5',
                                ConfigPackageField."Field Name", EvaluationRecord.Caption(), EvaluationRecord.GetPosition(), EvaluationField.Value, ContosoField.Value);

            until ConfigPackageField.Next() = 0;
    end;

    local procedure CompareValue(EvaluationField: FieldRef; ContosoField: FieldRef; Type: FieldType): Boolean
    var
        EvalText, ContosoText : Text;
    begin
        if Type = FieldType::Text then begin
            EvalText := EvaluationField.Value;
            ContosoText := ContosoField.Value;

            if (EvaluationField.Record().Number() = 85) and (EvaluationField.Name() = 'Description') then
                exit(EvalText.Trim().ToLower() <> ContosoText.Trim().ToLower());

            if (EvaluationField.Record().Number() = 5720) and (EvaluationField.Name() = 'Name') then
                exit(EvalText.Trim() <> ContosoText.Trim());

            exit(EvalText.Trim() <> ContosoText.Trim());
        end;

        exit(EvaluationField.Value <> ContosoField.Value);
    end;

    local procedure IsSkippedTable(TableID: Integer): Boolean
    var
        SkippedTables: List of [Integer];
    begin
        SkippedTables.Add(50);
        SkippedTables.Add(142);
        SkippedTables.Add(388);
        SkippedTables.Add(502);
        SkippedTables.Add(503);
        SkippedTables.Add(504);
        SkippedTables.Add(1251);
        SkippedTables.Add(2119);
        SkippedTables.Add(2121);
        SkippedTables.Add(5050);
        SkippedTables.Add(5054);
        SkippedTables.Add(5404);
        SkippedTables.Add(5065);
        SkippedTables.Add(5067);
        SkippedTables.Add(5077);
        SkippedTables.Add(5720);
        SkippedTables.Add(6750);
        SkippedTables.Add(6751);
        SkippedTables.Add(6755);
        SkippedTables.Add(6757);
        SkippedTables.Add(7501);
        SkippedTables.Add(7505);
        SkippedTables.Add(8618);
        SkippedTables.Add(8619);
        SkippedTables.Add(8620);
        SkippedTables.Add(8622);
        SkippedTables.Add(8626);
        SkippedTables.Add(8627);
        SkippedTables.Add(8630);
        SkippedTables.Add(8631);
        SkippedTables.Add(9701);
        SkippedTables.Add(10010);
        SkippedTables.Add(28003);

        exit(SkippedTables.Contains(TableID));
    end;

    local procedure IsExistingContosoModule(TableID: Integer): Boolean
    var
        ExistingModuleTables: List of [Integer];
    begin
        ExistingModuleTables.Add(167);
        ExistingModuleTables.Add(208);
        ExistingModuleTables.Add(209);
        ExistingModuleTables.Add(210);
        ExistingModuleTables.Add(237);
        ExistingModuleTables.Add(313);
        ExistingModuleTables.Add(315);
        ExistingModuleTables.Add(1001);
        ExistingModuleTables.Add(1002);
        ExistingModuleTables.Add(1003);
        ExistingModuleTables.Add(1384);
        ExistingModuleTables.Add(5079);
        ExistingModuleTables.Add(5200);
        ExistingModuleTables.Add(5221);
        ExistingModuleTables.Add(5605);
        ExistingModuleTables.Add(5606);
        ExistingModuleTables.Add(5609);
        ExistingModuleTables.Add(5611);
        ExistingModuleTables.Add(5633);
        ExistingModuleTables.Add(5634);
        ExistingModuleTables.Add(7700);
        ExistingModuleTables.Add(7701);
        ExistingModuleTables.Add(7702);
        ExistingModuleTables.Add(7703);
        ExistingModuleTables.Add(7704);
        ExistingModuleTables.Add(7710);

        exit(ExistingModuleTables.Contains(TableID));
    end;

    local procedure IsSkippedFieldInTable(TableID: Integer; FieldID: Integer): Boolean
    begin
        if (TableID = 15) and ((FieldID = 2) or (FieldID = 3)) then
            exit(true);

        if (TableID = 37) and (FieldID = 11) then
            exit(true);

        if (TableID = 39) and (FieldID = 11) then
            exit(true);

        if (TableID = 85) and (FieldID = 19) then
            exit(true);

        if (TableID = 292) and ((FieldID = 20) or (FieldID = 21)) then
            exit(true);

        if (TableID = 293) and ((FieldID = 20) or (FieldID = 21)) then
            exit(true);

        if (TableID = 133) and (FieldID = 4) then
            exit(true);

        if (TableID = 156) and (FieldID = 59) then
            exit(true);

        if (TableID = 274) and (FieldID = 480) then
            exit(true);

        if (TableID = 289) and (FieldID = 8) then
            exit(true);

        if (TableID = 309) and ((FieldID = 12) or (FieldID = 8) or (FieldID = 13)) then
            exit(true);

        if (TableID = 334) and (FieldID = 30) then
            exit(true);

        if (TableID = 5722) and (FieldID = 10) then
            exit(true);

        if (TableID = 5092) and ((FieldID = 5) or (FieldID = 6)) then
            exit(true);

        if (TableID = 5093) and ((FieldID = 5) or (FieldID = 6)) then
            exit(true);

        if (TableID = 5402) and (FieldID = 3) then
            exit(true);

        exit(false);
    end;

    local procedure ComparableType(Type: FieldType): Boolean
    begin
        case
           Type of
            FieldType::Date:
                exit(false);
            FieldType::Time:
                exit(false);
            FieldType::DateTime:
                exit(false);
            FieldType::Media:
                exit(false);
            FieldType::MediaSet:
                exit(false);
            else
                exit(true);
        end;
    end;
}
