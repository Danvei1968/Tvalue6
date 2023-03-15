tableextension 17022100 "PYA G/L Entry" extends "G/L Entry"
{
    fields
    {
        field(17022090; "PYA Contract No"; Code[20])
        {
            Caption = 'Contract No';
            DataClassification = ToBeClassified;
        }
        field(17022091; Totaling; Text[250])
        {
            Caption = 'Totaling';

            trigger OnValidate()
            var
                GL: Record "G/L Account";
            begin
                IF GL.Get(REC."G/L Account No.") THEN;
                CalcFields("PYA Balance to Date");
            end;
        }
        field(17022092; "PYA Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(17022093; "PYA G/L Account No."; Date)
        {
            Caption = 'G/L Account No';
            FieldClass = FlowFilter;
        }
        field(17022094; "PYA Balance to Date"; Decimal)
        {
            Caption = 'Balance to Date';
            AutoFormatType = 1;
            Editable = false;
            FieldClass = FlowField;

            CalcFormula = Sum("G/L Entry".Amount WHERE
                                                                ("G/L Account No." = FIELD("G/L Account No."),
                                                                //"PYA G/L Account No." = FIELD("No."),
                                                                "G/L Account No." = FIELD(FILTER(Totaling)),
                                                                "PYA G/L Account No." = FIELD(FILTER(Totaling)),
                                                                "Business Unit Code" = FIELD("Business Unit Filter"),
                                                                "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                "Posting Date" = FIELD(UPPERLIMIT("PYA Date Filter")),
                                                                "Posting Date" = FIELD(UPPERLIMIT("PYA Date Filter")),
                                                                "PYA Contract No" = FIELD("PYA Contract Filter"),
                                                                "Document No." = FIELD("PYA Document No Filter")));
        }
        field(17022095; "Business Unit Filter"; text[100])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
        }
        field(17022096; "Global Dimension 1 Filter"; text[100])
        {
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(17022097; "Global Dimension 2 Filter"; text[100])
        {
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(17022098; "PYA Contract Filter"; text[100])
        {
            Caption = 'PYA Contract Filter';
            FieldClass = FlowFilter;
        }
        field(17022099; "PYA Document No Filter"; text[100])
        {
            Caption = 'PYA Document No Filter';
            FieldClass = FlowFilter;
        }
        field(17022100; "PYA Installment Part"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Installment Part';
        }
    }
}