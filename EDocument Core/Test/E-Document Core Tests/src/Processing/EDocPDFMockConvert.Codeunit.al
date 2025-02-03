codeunit 139782 "E-Doc PDF Mock Convert" implements IBlobType, IBlobToStructuredDataConverter
{

    procedure IsStructured(): Boolean
    begin
        exit(false);
    end;

    procedure Convert(FromTempblob: Codeunit "Temp Blob"; FromType: Enum "E-Doc. Data Storage Blob Type"; var ConvertedType: Enum "E-Doc. Data Storage Blob Type"): Text
    begin
        ConvertedType := Enum::"E-Doc. Data Storage Blob Type"::JSON;
        exit('Mocked content');
    end;

    procedure HasConverter(): Boolean
    begin
        exit(true);
    end;

    procedure GetStructuredDataConverter(): Interface IBlobToStructuredDataConverter
    begin
        exit(this);
    end;
}
