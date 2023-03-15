tableextension 17022091 "PYA Contact Bank Account" extends "S4LA Contact Bank Account"
{
    fields
    {
        field(17022090; "NA DD Account Type"; Enum "PYA DD Account Type")
        {
            DataClassification = ToBeClassified;
            Description = 'BA220221';
            Caption = 'Account Type';
        }
    }
}