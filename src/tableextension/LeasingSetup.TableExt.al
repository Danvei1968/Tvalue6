tableextension 17022104 "PYA Leasing Setup" extends "S4LA Leasing Setup"
{
    fields
    {
        field(17022090; "NA Default Originator"; Code[20])
        {
            Caption = 'Default Originator';
            TableRelation = Contact."No.";
            DataClassification = CustomerContent;
        }
        field(17022091; "NA Default Orig. Sales Rep."; Code[20])
        {
            Caption = 'Default Originator Sales Rep';
            TableRelation = "S4LA Contact Person".Code where("Contact No." = field("NA Default Originator"));
            DataClassification = CustomerContent;
        }
        field(17022092; "NA Default Insurance Deduct"; Decimal)
        {
            Caption = 'Default Insurance Deduct';
            DataClassification = CustomerContent;
        }
        field(17022093; "NA Dealer No"; Code[10])
        {
            Caption = 'Dealer No';
            Description = 'DV180119';
            DataClassification = CustomerContent;
        }
        field(17022094; "NA Default Charge Extra Km"; Decimal)
        {
            Caption = 'Default Charge Extra Miles';
            DataClassification = CustomerContent;
        }
        field(17022095; "NA Tire Service Code"; Code[20])
        {
            Caption = 'Tire Service Code';
            Description = 'JM171026';
            TableRelation = "S4LA Service";
            DataClassification = CustomerContent;
        }
        field(17022096; "NA RDPRM Service Code"; Code[20])
        {
            Caption = 'RDPRM Service Code';
            Description = 'JM171026';
            TableRelation = "S4LA Service";
            DataClassification = CustomerContent;
        }
        field(17022097; "NA Round Quick Quote Inst."; Boolean)
        {
            Caption = 'Round Quick Quote Installment';
            DataClassification = CustomerContent;
            Description = 'TG190109';
        }
        field(17022098; "NA Clear Manual Amount"; Boolean)
        {
            Caption = 'Clear Manual Amount';
            DataClassification = CustomerContent;
            Description = 'TG190109';
        }
        field(17022099; "NA Default Admin Fee Serv."; Code[20])
        {
            Caption = 'Default Admin Fee Service';
            DataClassification = CustomerContent;
            Description = 'TG190314';
            TableRelation = "S4LA Service";
        }
        field(17022100; "NA Mileage Limit (km/year)"; Decimal)
        {
            Caption = 'Mileage Limit (Miles/year)';
            DataClassification = CustomerContent;
        }
        field(17022101; "NA Price per km over limit"; Decimal)
        {
            Caption = 'Price per miles over limit';
            DataClassification = CustomerContent;
        }
        field(17022102; "NA Direct Debit Fee Tax Gr."; Code[20])
        {
            TableRelation = "Tax Group";
            Caption = 'Direct Debit Fee Tax Group';
            DataClassification = CustomerContent;
        }
        field(17022103; "NA Dishonor Fee Tax Group"; Code[20])
        {
            TableRelation = "Tax Group";
            Caption = 'Dishonor Fee Tax Group';
            DataClassification = CustomerContent;
        }
        field(17022104; "NA Payment Periods Rounding"; Option)
        {
            Caption = 'Payment Periods Rounding';
            DataClassification = CustomerContent;
            OptionMembers = "Round Up","Round Nearest","Round Down";
            OptionCaption = 'Round Up,Round Nearest,Round Down';
        }
        field(17022105; "NA Role Code for Driver"; Code[20])
        {
            TableRelation = "S4LA Applicant Role";
            Caption = 'Role Code for Drivers';
            DataClassification = CustomerContent;
        }
        field(17022106; "NA Inertia Billing Code"; Code[20])
        {
            TableRelation = "S4LA Service";
            DataClassification = CustomerContent;
        }
        field(17022107; "NA Role Code for Division"; Code[20])
        {
            TableRelation = "S4LA Applicant Role";
            Caption = 'Role Code for Division';
            DataClassification = CustomerContent;
        }
        field(17022108; "NA Role Code for Branch"; Code[20])
        {
            TableRelation = "S4LA Applicant Role";
            Caption = 'Role Code for Branch';
            DataClassification = CustomerContent;
        }
        field(17022109; "NA Master Lease Agr. Nos."; Code[20])
        {
            TableRelation = "No. Series";
            Caption = 'Master Lease Agreement Nos.';
            DataClassification = CustomerContent;
        }
        //--//
        //PYAS-154 -  Field for log file path
        field(17022110; "NA Inv. Run Log File Path"; Text[250])
        {
            Caption = 'Invoicing Run Log File Path';
            DataClassification = CustomerContent;
        }
        //--//
        // PYAS-307 Loan Changes
        field(17022111; "NA Default Loan Frequency"; Code[20])
        {
            Caption = 'Default Loan Frequency';
            TableRelation = "S4LA Frequency";
            DataClassification = CustomerContent;
        }
        field(17022112; "NA Loan Installments Due At"; Option)
        {
            Caption = 'Loan Installments Due At';
            Description = 'Installments in arrears or in advance';
            OptionCaption = 'End of period,Beginning of period';
            OptionMembers = "End of period","Beginning of period";
            DataClassification = CustomerContent;
        }
        field(17022184; "Status - Repossession"; Code[20])
        {
            TableRelation = "S4LA Status" WHERE("Target Table ID" = CONST(17021231));
        }
        field(17022185; "Status - Surrender"; Code[20])
        {
            TableRelation = "S4LA Status" WHERE("Target Table ID" = CONST(17021231));
        }
        field(17022186; "Status - Matured Paid in Full"; Code[20])
        {
            TableRelation = "S4LA Status" WHERE("Target Table ID" = CONST(17021231));
        }
        field(17022187; "Status - Write Off"; Code[20])
        {
            TableRelation = "S4LA Status" WHERE("Target Table ID" = CONST(17021231));
        }
        field(17022188; "Status - Payout Paid in Full"; Code[20])
        {
            TableRelation = "S4LA Status" WHERE("Target Table ID" = CONST(17021231));
        }
        //--//
        //NA Print Document
        field(17022113; "NA Use New Document Print"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Use New Document Print';
        }
        //--- NA Print Document
        //PYAS-356
        field(17022114; "NA Def. Acquisition Source"; Enum "S4LA Asset Acquisition Source")
        {
            DataClassification = CustomerContent;
            Caption = 'Default Acquisition Source';
        }
        //--//
        field(17022130; "NA FA Post.Gr. for PO Lease"; Code[10])
        {
            Caption = 'FA Posting Group for PO Lease';
            TableRelation = "FA Posting Group";
            DataClassification = CustomerContent;
        }
        field(17022131; "NA Default Sales Inv. Type"; Code[10])
        {
            Caption = 'Default Sales Invoice Type';
            TableRelation = "S4LA Invoice Type";
            DataClassification = CustomerContent;
        }
        field(17022132; "Use Additional Term. Status"; Boolean)
        {
            Caption = 'Use Additional Term. Status';
        }
        field(17022189; "FA - Customer Subclass Code"; code[20])
        {
            TableRelation = "FA Subclass";
        }
        field(17022190; "FA - Inventory Subclass Code"; code[20])
        {
            TableRelation = "FA Subclass";
        }
        field(17022192; "Show Lease Balance"; Boolean)
        {
            Caption = 'Show Lease Balance';
        }
    }
}
