tableextension 17022112 "PYA Sales Invoice Header" extends "Sales Invoice Header"
{
    fields
    {
        field(17022183; "PYA Contract No"; CODE[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract No.';
        }
    }
}
