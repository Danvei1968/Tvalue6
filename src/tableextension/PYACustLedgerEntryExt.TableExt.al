tableextension 17022187 "PYA Cust. Ledger Entry Ext." extends "Cust. Ledger Entry"
{
    fields
    {
        field(17022180; "PYA Consolidated Invoice No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG190828 - Consolidated Invoice';
            Caption = 'Consolidated Invoice No.';
        }

        field(17022181; "PYA Consolidated Billing Month"; Text[30])
        {
            DataClassification = ToBeClassified;
            Description = 'TG190828 - Consolidated Invoice';
            Caption = 'Consolidated Billing Month';
        }
        field(17022182; "PYA Consolidated Invoice Date"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'TG190828 - Consolidated Invoice';
            Caption = 'Consolidated Invoice Date';
        }
        field(17022183; "PYA Driver Contact No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG190828 - Consolidated Invoice';
            TableRelation = Contact;
            Caption = 'Driver Contact No.';
        }
        field(17022184; "PYA Contract No"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'Contract No.';
            TableRelation = "S4LA Contract";
            Caption = 'Contract No.';
        }
        field(17022185; "PYA Sales Invoice Type"; Code[10])
        {
            DataClassification = ToBeClassified;
            Description = 'Contract No.';
            TableRelation = "S4LA Invoice Type";
            Caption = 'Sales Invoice Type';
        }
    }
}