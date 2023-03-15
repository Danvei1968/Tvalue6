//   DV170612 - Add Agent
//   JM170726 - Add Broker Name, collision deductible, 3rd party deductible, comprehensive deductible , all perils deductible
//   JM170815 - Fix error when entering insurer no.
//   DV171004 - When entering contract update customer info
//   DV200129 - Add Contract Status
//   DV200918 - Update status on insert/modify

tableextension 17022108 "PYA Contract Ins. Policy" extends "S4LA Asset Ins. Policy"
{
    LookupPageID = 17021685;  //BA220807
    DrillDownPageID = 17021685; //BA220807
    fields
    {
        modify("Contract No.")
        {
            trigger OnAfterValidate()
            begin
                IF Contr.GET("Contract No.") THEN;
                IF NOT Cont.GET(Contr."Customer No.") THEN
                    CLEAR(Cont);
                "NA Customer No" := Cont."No.";
                "NA Customer Name" := Cont.Name;
            end;
        }
        modify("Insurer No.")
        {
            trigger OnAfterValidate()
            var
                LContact: Record Contact;
            BEGIN
                //JM170815++
                //rem original Vendor.GET("Insurer No.");
                IF Vendor.GET("Insurer No.") THEN
                    "Insurer Name" := Vendor.Name;
                //BA220808
                IF ("Insurer Name" = '') then begin
                    if LContact.GET("Insurer No.") THEN
                        "Insurer Name" := LContact.Name

                end;
                //--//// ELSE
                // "Insurer Name" := '';
                //JM170815
            end;
        }
        field(17022090; "NA Agent"; Text[50])
        {
            Caption = 'Agent';
        }
        field(17022091; "NA Broker"; Code[20])
        {
            Caption = 'Broker';
            TableRelation = Contact;
        }
        field(17022092; "NA Agent Phone"; Text[30])
        {
            caption = 'Agent Phone';
            ExtendedDatatype = PhoneNo;
        }
        field(17022093; "NA Broker Name"; Text[100])
        {
            Caption = 'Broker Name';
            CalcFormula = Lookup(Contact.Name WHERE("No." = FIELD("NA Broker")));
            Description = 'JM170726';
            FieldClass = FlowField;
        }
        field(17022094; "NA Collision Deductible"; Decimal)
        {
            Caption = 'Collision Deductible';
            Description = 'JM170726';
        }
        field(17022095; "NA 3rd Party Deductible"; Decimal)
        {
            Caption = '3rd Party Deductible';
            Description = 'JM170726';
        }
        field(17022096; "NA Comprehensive Deductible"; Decimal)
        {
            Caption = 'Comprehensive Deductible';
            Description = 'JM170726';
        }
        field(17022097; "NA All Perils Deductible"; Decimal)
        {
            Caption = 'All Perils Deductible';
            Description = 'JM170726';
        }
        field(17022098; "NA Customer No"; Code[20])
        {
            Caption = 'Customer No';
        }
        field(17022099; "NA Customer Name"; Text[100])
        {
            Caption = 'Customer Name';
        }
        field(17022100; "NA Contract Status"; Code[20])
        {
            Caption = 'Status Code';
            //BA210503 Changed to flow field
            FieldClass = FlowField;
            CalcFormula = lookup("S4LA Contract"."Status Code" WHERE("Contract No." = FIELD("Contract No.")));
        }

    }

    var
        Contr: Record "S4LA Contract";
        Cont: Record Contact;
        Vendor: Record Vendor;

    trigger OnAfterInsert()
    begin
        /*DV171004*/
        Contr.GET("Contract No.");
        IF NOT Cont.GET(Contr."Customer No.") THEN//DV171124
            CLEAR(Cont);
        "NA Customer No" := Cont."No.";
        "NA Customer Name" := Cont.Name;

        /*---*/
    end;




}
