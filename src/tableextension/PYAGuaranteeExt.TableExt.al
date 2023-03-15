//BA210920 - Global Dim 1 & 2 fields added to the table.
tableextension 17022200 "PYA Guarantee Ext." extends "S4LA Guarantee"
{
    Caption = 'Guarantee';
    fields
    {
        field(17022180; "PYA Contract No."; Code[20])
        {
            Caption = 'Contract No';
            TableRelation = "S4LA CONTRACT";
        }
    }
}