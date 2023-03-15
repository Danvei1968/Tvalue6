tableextension 17022110 "PYA Purch. Inv. Header" extends "Purch. Inv. Header"
{
    fields
    {
        field(52004; "PYA Contract No"; Code[20])
        {
            Caption = 'Contract No.';
            DataClassification = ToBeClassified;
            Description = 'YSL32, relation to leasing module';
        }
    }
}