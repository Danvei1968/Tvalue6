tableextension 17022189 "PYA Doc. Selection Ext." extends "S4LA Document Selection"
{
    fields
    {
        field(17022180; "PYA Quick Quote Xls Type"; Code[20])
        {
            Caption = 'Quick Quote Excel Doc. Type';
            TableRelation = "S4LA Document Selection"."Contract Doc.Type";
            DataClassification = ToBeClassified;
        }
        field(17022181; "PYA Quick Quote Xls Temp (EN)"; Code[20])
        {
            Caption = 'Quick Quote Excel Template (EN)';
            TableRelation = "S4LA Document Selection"."Contract Template" where("Contract Doc.Type" = field("PYA Quick Quote Xls Type"));
            DataClassification = ToBeClassified;
        }
    }

}