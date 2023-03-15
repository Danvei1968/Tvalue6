tableextension 17022195 "PYA Financial Product" extends "S4LA Financial Product"
{
    fields
    {
        field(17022090; "Schedule Calc. Codeunit"; Enum "PYA Soft4 Edition")
        {
            Description = '0=Schedule Calc,1=NA Schedule Calc,2=Tvalue6';
            Caption = 'Schedule Calc. Codeunit';
            DataClassification = ToBeClassified;
        }
        //BA220727
        field(17022091; "Post Gain/Loss"; Boolean)
        {
            Caption = 'Post Gain/Loss At Termination';
        }
    }
}