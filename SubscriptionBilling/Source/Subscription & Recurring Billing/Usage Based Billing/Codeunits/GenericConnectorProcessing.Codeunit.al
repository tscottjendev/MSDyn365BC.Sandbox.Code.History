namespace Microsoft.SubscriptionBilling;

using System.IO;

codeunit 8033 "Generic Connector Processing" implements "Usage Data Processing"
{
    Access = Internal;

    var
        UsageDataGenericImportGlobal: Record "Usage Data Generic Import";
        ImportAndProcessUsageData: Codeunit "Import And Process Usage Data";
        CreateUsageDataBilling: Codeunit "Create Usage Data Billing";
        ProcessingSetupErr: Label 'You must specify either a reading/writing XMLport or a reading/writing codeunit.';
        UsageDataLinesProcessingErr: Label 'Errors were found while processing the Usage Data Lines.';
        NoDataFoundErr: Label 'No data found for processing step %1.', Comment = '%1 = Name of the processing step';
        UsageDataWithZeroQuantityCannotBeProcessedErr: Label 'Usage data with Quantity 0 cannot be processed.';
        NoServiceObjectErr: Label 'The %1 ''%2'' is not linked to an %3.', Comment = '%1 = Table name, %2 = Entry number, %3 = Table name';
        ServiceObjectProvisionEndDateErr: Label 'The %1 ''%2'' is deinstalled.', Comment = '%1 = Table name, %2 = Entry number';
        ReferenceNotFoundErr: Label 'For %1 ''%2'' no linked %3 was found.', Comment = '%1 = Field name, %2 = Entry description, %3 = Table name';
        NotValidServiceCommitmentErr: Label 'Service Commitment %2 found for Service Object %1 is not valid. Please check the Service Commitment and adjust the validity of the Service if necessary.', Comment = '%1 = Object number, %2 = Entry number';
        UsageDataGenericImportWithErrorExistErr: Label 'Usage Data Billing for Import %1 already exist. They must be deleted before new Billing can be created.', Comment = '%1 = Entry number';
        UsageDataGenericImportProcessingErr: Label 'Errors were found while processing the Usage Data Generic Import.';
        NoContractErr: Label 'The %1 %2 in %3 "%4" has not been assigned to a Contract yet.', Comment = '%1 = Service Commitment, %2 = Service Commitment Entry No., %3 = Service Object, %4 = Service Object No.';
        NoServiceCommitmentWithUsageBasedFlagInServiceObjectErr: Label '%1 "%2" has no valid %3 with property "%4": Yes', Comment = '%1 = Service Object, %2 = Service Object No., %3 = Service Commitment, %4 = Usage Based Billing';

    internal procedure ImportUsageData(var UsageDataImport: Record "Usage Data Import")
    var
        UsageDataBlob: Record "Usage Data Blob";
        UsageDataGenericImport: Record "Usage Data Generic Import";
    begin
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImport.DeleteAll(false);

        UsageDataBlob.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataBlob.SetRange("Import Status", UsageDataBlob."Import Status"::Ok);
        if UsageDataBlob.FindSet() then
            repeat
                ImportUsageDataBlobToUsageDataGenericImport(UsageDataBlob, UsageDataImport);
            until UsageDataBlob.Next() = 0
        else begin
            UsageDataImport.SetErrorReason(StrSubstNo(NoDataFoundErr, UsageDataImport."Processing Step"));
            UsageDataImport.Modify(false);
        end;
    end;

    local procedure ImportUsageDataBlobToUsageDataGenericImport(UsageDataBlob: Record "Usage Data Blob"; var UsageDataImport: Record "Usage Data Import")
    var
        DataExch: Record "Data Exch.";
        DataExchDef: Record "Data Exch. Def";
        GenericImportSettings: Record "Generic Import Settings";
    begin
        UsageDataImport.TestField("Supplier No.");
        GenericImportSettings.Get(UsageDataImport."Supplier No.");
        GenericImportSettings.TestField("Data Exchange Definition");
        DataExchDef.Get(GenericImportSettings."Data Exchange Definition");
        if (DataExchDef."Reading/Writing XMLport" <> 0) = (DataExchDef."Reading/Writing Codeunit" <> 0) then
            Error(ProcessingSetupErr);

        CreateDataExch(DataExch, UsageDataBlob, DataExchDef.Code);
        DataExch."Related Record" := UsageDataImport.RecordId;
        DataExch.Modify(false);
        DataExch.ImportToDataExch(DataExchDef);
        DataExchDef.ProcessDataExchange(DataExch);
        DataExch.Delete(true);

        OnAfterImportUsageDataBlobToUsageDataGenericImport(UsageDataBlob, UsageDataImport);
    end;

    local procedure CreateDataExch(var DataExch: Record "Data Exch."; UsageDataBlob: Record "Usage Data Blob"; DataExchDefCode: Code[20])
    var
        FileContentInStream: InStream;
    begin
        UsageDataBlob.CalcFields(Data);
        UsageDataBlob.Data.CreateInStream(FileContentInStream);
        DataExch.InsertRec(UsageDataBlob.Source, FileContentInStream, DataExchDefCode);
    end;

    internal procedure ProcessUsageData(var UsageDataImport: Record "Usage Data Import")
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
        ServiceCommitment: Record "Service Commitment";
        GenericImportSettings: Record "Generic Import Settings";
        UsageDataSupplierReference: Record "Usage Data Supplier Reference";
        ErrorCount: Integer;
    begin
        UsageDataGenericImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        if UsageDataGenericImport.FindSet() then
            repeat
                UsageDataGenericImport.Validate("Processing Status", Enum::"Processing Status"::None);
                ErrorIfUsageDataGenericImportQuantityIsZero(UsageDataGenericImport);
                GenericImportSettings.Get(UsageDataImport."Supplier No.");
                CreateUsageDataCustomers(GenericImportSettings, UsageDataGenericImport, UsageDataSupplierReference, UsageDataImport."Supplier No.");
                CreateUsageDataSubscriptions(GenericImportSettings, UsageDataGenericImport, UsageDataSupplierReference, UsageDataImport);

                if UsageDataGenericImport."Processing Status" <> Enum::"Processing Status"::Error then
                    CheckServiceCommitment(UsageDataGenericImport, UsageDataImport, ServiceCommitment);
                if UsageDataGenericImport."Processing Status" <> Enum::"Processing Status"::Error then
                    CheckAndAssignServiceObject(UsageDataGenericImport, ServiceCommitment);

                if UsageDataGenericImport."Processing Status" = "Processing Status"::Error then
                    ErrorCount += 1
                else
                    UsageDataGenericImport."Processing Status" := Enum::"Processing Status"::Ok;
                UpdateServiceObjectConnectionStatus(ImportAndProcessUsageData, UsageDataImport, UsageDataGenericImport);
                UsageDataGenericImport.Modify(false);
            until UsageDataGenericImport.Next() = 0
        else begin
            UsageDataImport.SetErrorReason(StrSubstNo(NoDataFoundErr, UsageDataImport."Processing Step"));
            UsageDataImport.Modify(false);
        end;

        if ErrorCount <> 0 then
            ImportAndProcessUsageData.SetError(UsageDataImport, UsageDataLinesProcessingErr);
    end;

    local procedure CreateUsageDataCustomers(GenericImportSettings: Record "Generic Import Settings"; UsageDataGenericImport: Record "Usage Data Generic Import";
                                            UsageDataSupplierReference: Record "Usage Data Supplier Reference"; SupplierNo: Code[20])
    begin
        if not GenericImportSettings."Create Customers" then
            exit;
        UsageDataGenericImport.TestField("Customer ID");
        ImportAndProcessUsageData.CreateUsageDataCustomer(UsageDataGenericImport."Customer ID", UsageDataSupplierReference, SupplierNo);
    end;

    local procedure CreateUsageDataSubscriptions(GenericImportSettings: Record "Generic Import Settings"; UsageDataGenericImport: Record "Usage Data Generic Import"; UsageDataSupplierReference: Record "Usage Data Supplier Reference"; var UsageDataImport: Record "Usage Data Import")
    begin
        if not GenericImportSettings."Create Subscriptions" then
            exit;
        ImportAndProcessUsageData.CreateUsageDataSubscription(UsageDataGenericImport."Subscription ID", UsageDataGenericImport."Customer ID",
                        UsageDataGenericImport."Product ID", UsageDataGenericImport."Product Name", UsageDataGenericImport."Unit",
                        UsageDataGenericImport.Quantity, UsageDataGenericImport."Subscription Start Date", UsageDataGenericImport."Subscription End Date",
                        UsageDataSupplierReference, UsageDataImport."Supplier No.");
    end;

    local procedure UpdateServiceObjectConnectionStatus(ImportAndProcessUsageDataParam: Codeunit "Import And Process Usage Data"; var UsageDataImport: Record "Usage Data Import"; var UsageDataGenericImport: Record "Usage Data Generic Import")
    begin
        UsageDataGenericImport."Service Object Availability" := UsageDataGenericImport."Service Object Availability"::"Not Available";

        if UsageDataGenericImport."Service Object No." <> '' then begin
            UsageDataGenericImport."Service Object Availability" := UsageDataGenericImport."Service Object Availability"::Connected;
            exit;
        end;
        if not ImportAndProcessUsageDataParam.AvailableServiceObjectExist(UsageDataImport, UsageDataGenericImport."Subscription ID") then
            exit;
        UsageDataGenericImport."Service Object Availability" := UsageDataGenericImport."Service Object Availability"::Available;
    end;

    internal procedure CheckAndAssignServiceObject(var UsageDataGenericImport: Record "Usage Data Generic Import"; ServiceCommitment: Record "Service Commitment")
    var
        ServiceObject: Record "Service Object";
    begin
        if ServiceCommitment."Service Object No." = '' then begin
            UsageDataGenericImport."Processing Status" := UsageDataGenericImport."Processing Status"::Error;
            UsageDataGenericImport.SetReason(StrSubstNo(NoServiceObjectErr, ServiceCommitment.TableCaption, ServiceCommitment."Entry No.", ServiceObject.TableCaption));
        end else begin
            ServiceObject.Get(ServiceCommitment."Service Object No.");
            if ServiceObject."Provision End Date" <> 0D then begin
                UsageDataGenericImport."Processing Status" := UsageDataGenericImport."Processing Status"::Error;
                UsageDataGenericImport.SetReason(StrSubstNo(ServiceObjectProvisionEndDateErr, ServiceObject.TableCaption, ServiceObject."No."));
            end else
                UsageDataGenericImport."Service Object No." := ServiceCommitment."Service Object No.";
        end;
    end;

    internal procedure ErrorIfUsageDataGenericImportQuantityIsZero(var UsageDataGenericImport: Record "Usage Data Generic Import")
    begin
        if UsageDataGenericImport.Quantity <> 0 then
            exit;
        UsageDataGenericImport."Processing Status" := UsageDataGenericImport."Processing Status"::Error;
        UsageDataGenericImport.SetReason(UsageDataWithZeroQuantityCannotBeProcessedErr);
    end;

    internal procedure CheckServiceCommitment(var UsageDataGenericImport: Record "Usage Data Generic Import"; var UsageDataImport: Record "Usage Data Import"; var ServiceCommitment: Record "Service Commitment")
    begin
        if ImportAndProcessUsageData.GetServiceCommitmentForSubscription(UsageDataImport."Supplier No.", UsageDataGenericImport."Subscription ID", ServiceCommitment) then
            CheckIfServiceCommitmentStartDateIsValid(UsageDataGenericImport, ServiceCommitment)
        else
            SetErrorIfServiceCommitmentDoesNotExist(UsageDataGenericImport, ServiceCommitment);
    end;

    local procedure SetErrorIfServiceCommitmentDoesNotExist(var UsageDataGenericImport: Record "Usage Data Generic Import"; ServiceCommitment: Record "Service Commitment")
    begin
        UsageDataGenericImport."Processing Status" := UsageDataGenericImport."Processing Status"::Error;
        UsageDataGenericImport.SetReason(StrSubstNo(ReferenceNotFoundErr, UsageDataGenericImport.FieldCaption(UsageDataGenericImport."Subscription ID"),
                                                    UsageDataGenericImport."Subscription ID", ServiceCommitment.TableCaption));
    end;

    local procedure CheckIfServiceCommitmentStartDateIsValid(var UsageDataGenericImport: Record "Usage Data Generic Import"; ServiceCommitment: Record "Service Commitment")
    begin
        if ServiceCommitment."Service Start Date" <= UsageDataGenericImport."Billing Period Start Date" then
            exit;
        UsageDataGenericImport."Processing Status" := UsageDataGenericImport."Processing Status"::Error;
        UsageDataGenericImport.SetReason(StrSubstNo(NotValidServiceCommitmentErr, ServiceCommitment."Service Object No.", ServiceCommitment."Entry No."));
    end;

    internal procedure FindAndProcessUsageDataImport(var UsageDataImport: Record "Usage Data Import")
    var
        TempServiceCommitment: Record "Service Commitment" temporary;
    begin
        UsageDataGenericImportGlobal.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        if CreateUsageDataBilling.GetRetryFailedUsageDataImport() then
            UsageDataGenericImportGlobal.SetFilter("Processing Status", '<>%1', "Processing Status"::Ok);

        if UsageDataGenericImportGlobal.FindSet() then
            repeat
                CreateUsageDataBilling.CollectServiceCommitments(TempServiceCommitment, UsageDataGenericImportGlobal."Service Object No.", UsageDataGenericImportGlobal."Subscription End Date");
                SetUsageDataGenericImportError('');
                if not CheckServiceCommitments(TempServiceCommitment) then
                    exit;
                CreateUsageDataBilling.CreateUsageDataBillingFromTempServiceCommitments(TempServiceCommitment, UsageDataImport."Supplier No.", UsageDataGenericImportGlobal."Usage Data Import Entry No.", UsageDataGenericImportGlobal."Service Object No.", UsageDataGenericImportGlobal."Billing Period Start Date",
                                UsageDataGenericImportGlobal."Billing Period End Date", UsageDataGenericImportGlobal.Cost, UsageDataGenericImportGlobal.Quantity,
                                UsageDataGenericImportGlobal."Cost Amount", UsageDataGenericImportGlobal.Price, UsageDataGenericImportGlobal.Amount, UsageDataGenericImportGlobal.GetCurrencyCode());
            until UsageDataGenericImportGlobal.Next() = 0
        else begin
            UsageDataImport.SetErrorReason(StrSubstNo(NoDataFoundErr, UsageDataImport."Processing Step"));
            UsageDataImport.Modify(false);
        end;
    end;

    internal procedure TestUsageDataImport(var UsageDataImport: Record "Usage Data Import")
    var
        UsageDataGenImport: Record "Usage Data Generic Import";
    begin
        UsageDataGenImport.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenImport.SetFilter("Processing Status", '<>%1', UsageDataGenImport."Processing Status"::Ok);
        if not UsageDataGenImport.IsEmpty() then begin
            UsageDataImport.SetErrorReason(StrSubstNo(UsageDataGenericImportWithErrorExistErr, UsageDataImport."Entry No."));
            UsageDataImport.Modify(false);
        end;
        UsageDataGenImport.SetRange("Processing Status");
        if UsageDataGenImport.IsEmpty() then begin
            UsageDataImport.SetErrorReason(StrSubstNo(NoDataFoundErr, UsageDataImport."Processing Step"));
            UsageDataImport.Modify(false);
        end;
    end;

    internal procedure SetUsageDataImportError(var UsageDataImport: Record "Usage Data Import")
    begin
        UsageDataGenericImportGlobal.Reset();
        UsageDataGenericImportGlobal.SetRange("Usage Data Import Entry No.", UsageDataImport."Entry No.");
        UsageDataGenericImportGlobal.SetRange("Processing Status", UsageDataGenericImportGlobal."Processing Status"::Error);
        if UsageDataGenericImportGlobal.IsEmpty() then begin
            UsageDataImport."Processing Status" := UsageDataImport."Processing Status"::Ok;
            UsageDataImport.SetReason('');
        end else
            UsageDataImport.SetErrorReason(UsageDataGenericImportProcessingErr);
        UsageDataImport.Modify(false);
    end;

    internal procedure CheckServiceCommitments(var TempServiceCommitment: Record "Service Commitment" temporary): Boolean
    var
        ServiceObject: Record "Service Object";
    begin
        TempServiceCommitment.Reset();
        TempServiceCommitment.SetRange("Contract No.", '');
        if TempServiceCommitment.FindFirst() then begin
            SetUsageDataGenericImportError(StrSubstNo(NoContractErr, TempServiceCommitment.TableCaption, TempServiceCommitment."Entry No.",
                                             ServiceObject.TableCaption, UsageDataGenericImportGlobal."Service Object No."));
            exit(false);
        end;

        TempServiceCommitment.Reset();
        if not TempServiceCommitment.FindSet() then begin
            SetUsageDataGenericImportError(StrSubstNo(NoServiceCommitmentWithUsageBasedFlagInServiceObjectErr, ServiceObject.TableCaption, UsageDataGenericImportGlobal."Service Object No.",
                                             TempServiceCommitment.TableCaption, TempServiceCommitment.FieldCaption("Usage Based Billing")));
            exit(false);
        end;

        exit(true);
    end;

    internal procedure SetUsageDataGenericImportError(Reason: Text)
    begin
        if Reason = '' then
            UsageDataGenericImportGlobal."Processing Status" := UsageDataGenericImportGlobal."Processing Status"::Ok
        else
            UsageDataGenericImportGlobal."Processing Status" := UsageDataGenericImportGlobal."Processing Status"::Error;
        UsageDataGenericImportGlobal.SetReason(Reason);
        UsageDataGenericImportGlobal.Modify(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Process Data Exch.", 'OnProcessColumnMappingOnBeforeDataExchFieldMappingFindSet', '', false, false)]
    local procedure SetNextEntryNoForUsageDataGenericImport(var RecordRef: RecordRef; LastKeyFieldId: Integer; CurrLineNo: Integer)
    var
        UsageDataGenericImport: Record "Usage Data Generic Import";
        ProcessDataExch: Codeunit "Process Data Exch.";
    begin
        if RecordRef.Number <> Database::"Usage Data Generic Import" then
            exit;
        ProcessDataExch.SetFieldValue(RecordRef, LastKeyFieldId, UsageDataGenericImport.GetNextEntryNo());
    end;

    [InternalEvent(false, false)]
    local procedure OnAfterImportUsageDataBlobToUsageDataGenericImport(UsageDataBlob: Record "Usage Data Blob"; var UsageDataImport: Record "Usage Data Import")
    begin
    end;
}
