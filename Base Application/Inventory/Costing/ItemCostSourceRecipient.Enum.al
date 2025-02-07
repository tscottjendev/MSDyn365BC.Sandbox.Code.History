namespace Microsoft.Inventory.Costing;

enum 5802 "Item Cost Source/Recipient"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Source)
    {
        Caption = 'Source';
    }
    value(2; Recipient)
    {
        Caption = 'Recipient';
    }
}