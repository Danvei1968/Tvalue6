tableextension 17022111 "PYA Sales Header" extends "Sales Header"
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
