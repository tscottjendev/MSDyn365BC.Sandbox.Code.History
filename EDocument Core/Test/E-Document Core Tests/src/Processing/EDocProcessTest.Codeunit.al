codeunit 139883 "E-Doc Process Test"
{
    Subtype = Test;

    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryEDoc: Codeunit "Library - E-Document";
        EDocImplState: Codeunit "E-Doc. Impl. State";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;


    [Test]
    procedure ProcessStructureReceivedData()
    var
        EDocument: Record "E-Document";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocumentLog: Codeunit "E-Document Log";
        IBlobType: Interface IBlobType;
        InStream: InStream;
        Text: Text;
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. Data Storage Blob Type"::"PDF Mock", 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Unprocessed);

        EDocument."Unstructured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Unprocessed);
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";

        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::Unprocessed, EDocument.GetEDocumentImportProcessingStatus(), 'The status should be updated to the one after the step executed.');
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::Readable, EDocument.GetEDocumentImportProcessingStatus(), 'The status should be updated to the one after the step executed.');

        EDocDataStorage.FindLast();
        EDocDataStorage.CalcFields("Data Storage");
        EDocDataStorage."Data Storage".CreateInStream(InStream);
        InStream.Read(Text);
        Assert.AreEqual('Mocked content', Text, 'The data should be read from the mock converter.');
        Assert.AreEqual(Enum::"E-Doc. Data Storage Blob Type"::JSON, EDocDataStorage."Data Type", 'The data type should be updated to JSON.');
        IBlobType := EDocDataStorage."Data Type";
        Assert.IsTrue(IBlobType.IsStructured(), 'New entry should always be structured');
    end;


    [Test]
    procedure ProcessingDoesSequenceOfSteps()
    var
        EDocument: Record "E-Document";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocumentLog: Codeunit "E-Document Log";
        ImportEDocumentProcess: Codeunit "Import E-Document Process";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. Data Storage Blob Type"::"PDF Mock", 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Unprocessed);

        EDocument."Unstructured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Unprocessed);
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        Assert.AreEqual(ImportEDocumentProcess.GetStatusForStep(EDocImportParameters."Step to Run", false), EDocument.GetEDocumentImportProcessingStatus(), 'The status should be updated to the one after the step executed.');
    end;

    [Test]
    procedure ProcessingUndoesSteps()
    var
        EDocument: Record "E-Document";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        EDocLogRecord: Record "E-Document Log";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
        EDocumentLog: Codeunit "E-Document Log";
        ImportEDocumentProcess: Codeunit "Import E-Document Process";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        EDocumentLog.SetBlob('Test', Enum::"E-Doc. Data Storage Blob Type"::"PDF Mock", 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Imported, Enum::"Import E-Doc. Proc. Status"::Unprocessed);

        EDocument."Unstructured Data Entry No." := EDocLogRecord."E-Doc. Data Storage Entry No.";
        EDocument.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::Processed);
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        Assert.AreEqual(ImportEDocumentProcess.GetStatusForStep(EDocImportParameters."Step to Run", false), EDocument.GetEDocumentImportProcessingStatus(), 'The status should be updated to the one after the step executed.');
    end;

    [Test]
    procedure FinishDraftCanBeUndone()
    var
        EDocument: Record "E-Document";
        EDocImportParameters: Record "E-Doc. Import Parameters";
        PurchaseHeader: Record "Purchase Header";
        EDocImport: Codeunit "E-Doc. Import";
        EDocumentProcessing: Codeunit "E-Document Processing";
    begin
        Initialize(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocument."Document Type" := "E-Document Type"::"Purchase Invoice";
        EDocument.Modify();
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService.Modify();

        EDocumentProcessing.ModifyEDocumentProcessingStatus(EDocument, "Import E-Doc. Proc. Status"::"Draft Ready");
        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        EDocImportParameters."Finish Purchase Draft Impl." := "E-Doc. Create Purchase Invoice"::"Mock Create Purchase Invoice";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        PurchaseHeader.SetRange("E-Document Link", EDocument.SystemId);
        PurchaseHeader.FindFirst();

        EDocImportParameters."Step to Run" := "Import E-Document Steps"::"Structure received data";
        EDocImport.ProcessIncomingEDocument(EDocument, EDocImportParameters);

        Assert.RecordIsEmpty(PurchaseHeader);
    end;

    local procedure Initialize(Integration: Enum "Service Integration")
    var
        TransformationRule: Record "Transformation Rule";
        EDocument: Record "E-Document";
        EDocDataStorage: Record "E-Doc. Data Storage";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();
        Clear(EDocImplState);

        if IsInitialized then
            exit;

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocumentService.DeleteAll();
        EDocDataStorage.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Integration);
        EDocumentService."Sent Actions Integration" := Enum::"Sent Document Actions"::Mock;
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService."E-Document Structured Format" := "E-Document Structured Format"::"PDF Mock";
        EDocumentService.Modify();

        TransformationRule.DeleteAll();
        TransformationRule.CreateDefaultTransformations();

        IsInitialized := true;
    end;
}
