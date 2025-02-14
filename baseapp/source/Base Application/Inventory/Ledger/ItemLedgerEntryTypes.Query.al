namespace Microsoft.Inventory.Ledger;

query 203 "Item Ledger Entry Types"
{
    QueryType = Normal;
    Caption = 'Item Ledger Entry Types';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Item_Ledger_Entry; "Item Ledger Entry")
        {
            filter(Item_No_; "Item No.") { }
            column(Entry_Type; "Entry Type") { }
            column(Count)
            {
                Method = Count;
            }
        }
    }
}