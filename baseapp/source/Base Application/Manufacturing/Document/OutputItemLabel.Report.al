namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using System.Text;

report 99000769 "Output Item Label"
{
    UsageCategory = Tasks;
    ApplicationArea = Manufacturing;
    WordMergeDataItem = ItemLedgerEntry;
    DefaultRenderingLayout = Word;
    Caption = 'Output Item Label';

    dataset
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableView = where("Entry Type" = const("Item Ledger Entry Type"::"Output"));
            RequestFilterFields = "Order No.", "Item No.";

            column(ItemNo; "Item No.")
            {
            }
            column(Description; ItemDescription)
            {
            }
            column(BaseUnitofMeasure; ItemBaseUnitOfMeasure)
            {
            }
            column(BarCode; BarCode)
            {
            }
            column(QRCode; QRCode)
            {
            }

            trigger OnAfterGetRecord()
            var
                Item: Record Item;
                BarcodeString: Text;
                BarcodeFontProvider: Interface "Barcode Font Provider";
                BarcodeFontProvider2D: Interface "Barcode Font Provider 2D";
            begin
                BarcodeFontProvider := Enum::"Barcode Font Provider"::IDAutomation1D;
                BarcodeFontProvider2D := Enum::"Barcode Font Provider 2D"::IDAutomation2D;

                if UseSerialNo and ("Serial No." <> '') then
                    BarcodeString := "Serial No.";

                if UseLotNo and ("Lot No." <> '') then
                    BarcodeString := "Lot No.";

                if UsePackageNo and ("Package No." <> '') then
                    BarcodeString := "Package No.";

                if StrLen(BarcodeString) > 0 then begin
                    BarcodeFontProvider.ValidateInput(BarcodeString, BarcodeSymbology);
                    BarCode := BarcodeFontProvider.EncodeFont(BarcodeString, BarcodeSymbology);
                    QRCode := BarcodeFontProvider2D.EncodeFont(BarcodeString, BarcodeSymbology2D);

                    if Item.Get("Item No.") then begin
                        ItemDescription := Item.Description;
                        ItemBaseUnitOfMeasure := Item."Base Unit of Measure";
                    end
                end else
                    CurrReport.Skip();
            end;

        }
    }

    requestpage
    {
        SaveValues = true;
        AboutTitle = 'Print labels for posted output items';

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Use Serial No"; UseSerialNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Serial No.';
                        ToolTip = 'Specifies whether to print the Serial No. of the item on the label, if it exists.';

                        trigger OnValidate()
                        begin
                            UseLotNo := false;
                            UsePackageNo := false;
                        end;
                    }
                    field("Use Lot No"; UseLotNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Lot No.';
                        ToolTip = 'Specifies whether to print the Lot No. of the item on the label, if it exists.';

                        trigger OnValidate()
                        begin
                            UseSerialNo := false;
                            UsePackageNo := false;
                        end;
                    }
                    field("Use Package No"; UsePackageNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Package No.';
                        ToolTip = 'Specifies whether to print the Package No. of the item on the label, if it exists.';

                        trigger OnValidate()
                        begin
                            UseLotNo := false;
                            UseSerialNo := false;
                        end;
                    }
                }
            }
        }
    }

    rendering
    {
        layout(Word)
        {
            Type = Word;
            LayoutFile = './Manufacturing/Document/OutputItemLabel.docx';
        }
    }

    var
        BarcodeSymbology: Enum "Barcode Symbology";
        BarcodeSymbology2D: Enum "Barcode Symbology 2D";
        ItemBaseUnitOfMeasure: Code[10];
        BarCode, QRCode, ItemDescription : Text;
        UseSerialNo, UseLotNo, UsePackageNo : Boolean;
        ErrorLbl: Label 'One of the three options must be on.';

    trigger OnInitReport()
    begin
        UseSerialNo := true;
        BarcodeSymbology := Enum::"Barcode Symbology"::Code39;
        BarcodeSymbology2D := Enum::"Barcode Symbology 2D"::"QR-Code";
    end;

    trigger OnPreReport()
    begin
        if not (UseSerialNo or UseLotNo or UsePackageNo) then
            Error(ErrorLbl);
    end;

}