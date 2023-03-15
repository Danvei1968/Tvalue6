tableextension 17022194 "PYA Gen. Journal Line Ext." extends "Gen. Journal Line"
{
    fields
    {
        field(17022090; "NA Bank Name"; Text[50])
        {
            Caption = 'Bank Name';
            DataClassification = ToBeClassified;

            trigger OnLookup()
            var
                BankList: Record "Bank Account";
            begin
                IF PAGE.RUNMODAL(PAGE::"Bank Account Link", BankList) = ACTION::LookupOK THEN
                    VALIDATE("NA Bank Name", BankList.Name);
            end;
        }
        //SOLV-707 >>
        field(17022091; "NA Charge Dishonour Fee"; Boolean)
        {
            Caption = 'Charge Dishonour Fee';
        }
        field(17022092; "S4L Dishonoured CLE No."; Integer)
        {
            Caption = 'S4L Dishonoured CLE No.';
        }
        field(17022180; "PYA Cust. Name (per Contract)"; Text[100])
        {
            FieldClass = FlowField;
            CalcFormula = Lookup(Contact.Name WHERE("No." = FIELD("Account No.")));

            Caption = 'Customer Name (Per Contract)';
        }
        field(17022181; "PYA Receipt No"; Code[10])
        {
            Caption = 'Receipt No.';
            DataClassification = ToBeClassified;
        }
        field(17022182; "PYA Report Printed"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Report Printed';
        }
        //BA220221
        field(17022183; "PYA DD Account Type"; Enum "PYA DD Account Type")
        {
            DataClassification = ToBeClassified;
            Description = 'BA220221';
            Caption = 'Account Type';
        }
        field(17022184; "PYA Export File Name"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Export File Name';
        }
        //--//

        //BA220622
        field(17022185; "PYA License Plate No."; code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Registration No.';

            trigger OnValidate()
            var
                FixedAsset: record "Fixed Asset";
                LPlateLbl: label 'License plate does not exist';
            begin
                if "PYA License Plate No." <> '' then begin
                    FixedAsset.Reset;
                    FixedAsset.SetFilter("PYA Licence Plate No.", "PYA License Plate No.");
                    if FixedAsset.FindFirst() then
                        Validate("PYA Contract NO", FixedAsset."PYA Contract No")
                    else
                        error(LPlateLbl);
                end else begin
                    "PYA Contract No" := '';
                    "Account No." := '';
                end;
            end;
        }
        field(17022187; "PYA Contract No"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract';
        }
        field(17022188; "PYA Installment Part"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Installment Part';
        }

        modify("S4L Dishonoured CLE No.")
        {
            trigger OnAfterValidate()
            begin
                if "S4L Dishonoured CLE No." <> 0 then
                    "NA Charge Dishonour Fee" := true
                else
                    "NA Charge Dishonour Fee" := false;
            end;
        }
        modify("Account No.")
        {
            trigger OnAfterValidate()
            begin
                FillBankDetailsToJnl();
            end;
        }
    }

    //--//

    //BA221118 
    trigger OnBeforeDelete()
    var
        Text001: Label 'You can''t delete a line that has been printed';
    begin
        if "PYA Receipt No" <> '' then
            error(Text001);
    end;
    //--///

    procedure FillBankDetailsToJnl()
    var
        ContBankAcc: record "S4LA Contact Bank Account";
        Contr: record "S4LA contract";
    begin
        "Account No." := '';
        //"S4L Bank Branch No." := '';
        "PYA DD Account Type" := "PYA DD Account Type"::" ";
        "NA Bank Name" := ContBankAcc.Name;
        IF (("Account Type" = "Account Type"::Customer) or ("Account Type" = "Account Type"::Vendor)) AND ("Account No." <> '') THEN BEGIN
            ContBankAcc.RESET;
            ContBankAcc.SETRANGE("Contact No.", "Account No.");
            IF ContBankAcc.FINDFIRST THEN BEGIN
                "Account Type" := "Account Type"::"Bank Account";
                "Account No." := ContBankAcc."Bank Account No.";
                "PYA DD Account Type" := ContBankAcc."NA DD Account Type";
                "NA Bank Name" := ContBankAcc.Name;
            END;
        END;

        IF "PYA Contract No" <> '' THEN BEGIN
            Contr.GET("PYA Contract No");
            "Account Type" := "Account Type"::"Bank Account";
            "PYA DD Account Type" := contr."PYA DD Account Type";
            "Account No." := Contr."DD Bank Account No.";
        END;
    end;
}