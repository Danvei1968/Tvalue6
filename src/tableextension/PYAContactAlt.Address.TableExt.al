tableextension 17022221 "PYA Contact Alt. Address" extends "Contact Alt. Address"
{
    fields
    {
        field(17022090; "PYA Skip Birth Date Check"; Boolean)
        {
            Caption = 'Skip Birth Date Check';
            DataClassification = ToBeClassified;
        }
        field(17022091; "PYA Contract No"; code[20])
        {
            Caption = 'Contract No.';
            DataClassification = ToBeClassified;
        }
    }
}