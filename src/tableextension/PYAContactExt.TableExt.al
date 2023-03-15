tableextension 17022183 "PYA Contact Ext." extends Contact
{
    fields
    {
        field(17022090; "NA Policy No."; Code[50])
        {
            Caption = 'Policy No.';
            DataClassification = ToBeClassified;
            Description = 'JM170719';
        }
        field(17022091; "NA Insurer Number"; Code[20])
        {
            Caption = 'Insurer Number';
            DataClassification = ToBeClassified;
            Description = 'JM170719';
            TableRelation = Contact WHERE("S4L Is Insurer" = CONST(True));
        }
        field(17022092; "NA Show Insurer Name"; Boolean)
        {
            Caption = 'Show Insurer Name';
            DataClassification = ToBeClassified;
            Description = 'JM170719';
        }
        field(17022093; "NA Expiry Date"; Date)
        {
            Caption = 'Expiry Date';
            DataClassification = ToBeClassified;
            Description = 'JM170719';
        }
        field(17022094; "NA Agent"; Text[50])
        {
            Caption = 'Agent';
            DataClassification = ToBeClassified;
            Description = 'JM170719';
        }
        field(17022095; "NA Agent Phone"; Text[30])
        {
            Caption = 'Agent Phone';
            DataClassification = ToBeClassified;
            Description = 'JM170719';
        }
        field(17022096; "NA Broker"; Code[20])
        {
            Caption = 'Broker';
            DataClassification = ToBeClassified;
            Description = 'JM170719';
            TableRelation = Contact;
        }
        field(17022097; "PYA Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = CustomerContent;
            Description = 'SK170207';
            TableRelation = "Tax Area";

            trigger OnValidate()
            var
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                //KS170209 NA
                if Cust.Get("No.") then begin
                    Cust."Tax Area Code" := "PYA Tax Area Code";
                    Cust.Modify();
                end;
                if Vend.Get("No.") then begin
                    Vend."Tax Area Code" := "PYA Tax Area Code";
                    Vend.Modify();
                end;
                //---
            end;
        }
        field(17022098; "PYA Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = CustomerContent;
            Description = 'SK170207';
            InitValue = true;

            trigger OnValidate()
            var
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                //KS170209 NA
                if Cust.Get("No.") then begin
                    Cust."Tax Liable" := "PYA Tax Liable";
                    Cust.Modify();
                end;
                if Vend.Get("No.") then begin
                    Vend."Tax Liable" := "PYA Tax Liable";
                    Vend.Modify();
                end;
                //---
            end;
        }
        //BA210920
        Field(17022100; "NA Inertia Billing Amount"; Decimal)
        {
            Caption = 'Inertia Billing Amount';
        }
        field(17022180; "PYA Is Broker"; Boolean)
        {
            Caption = 'Is Broker';
            DataClassification = ToBeClassified;
        }
        field(17022181; "PYA Fleet Size"; Text[100])
        {
            Caption = 'Fleet Size';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
        }

        field(17022182; "PYA Fleet Potential"; Text[100])
        {
            Caption = 'Fleet Potential';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
        }
        field(17022183; "PYA AME (Aftermarket)"; Text[100])
        {
            Caption = 'AME (Aftermarket)';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
        }
        field(17022184; "PYA Acquisition Method"; Text[100])
        {
            Caption = 'Acquisition Method';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
        }
        field(17022185; "PYA Funding Method"; Text[100])
        {
            Caption = 'Funding Method';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
        }
        field(17022186; "PYA Maintenance Method"; Text[100])
        {
            Caption = 'Maintenance Method';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
        }
        field(17022187; "PYA Fuel Method"; Text[100])
        {
            Caption = 'Fuel Method';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
        }
        field(17022188; "PYA Disposal Method"; Text[100])
        {
            Caption = 'Disposal Method';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
        }
        field(17022189; "PYA Identified Prospect"; Date)
        {
            Caption = 'Identified Prospect';
            DataClassification = ToBeClassified;
            Description = 'JM191015 {TG191022} // changed to Date';

            trigger OnValidate()
            begin
                UpdateSalesStages('Identified Prospect');
            end;
        }
        field(17022190; "PYA Ident. Prosp. Completed"; Boolean)
        {
            Caption = 'Identified Prospect Completed';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
            Editable = false;
        }
        field(17022191; "PYA Qualified Prospect"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015 {TG191022} // changed to Date';
            Caption = 'Qualified Prospect';

            trigger OnValidate()
            begin
                UpdateSalesStages('Qualified Prospect');
            end;
        }
        field(17022192; "PYA Qual. Prospect Completed"; Boolean) //Qualified Prospect Completed
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015';
            Editable = false;
            Caption = 'Qualified Prospect Completed';
        }
        field(17022193; "PYA Discovery Meeting"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015 {TG191022} // changed to Date';
            Caption = 'Discovery Meeting';

            trigger OnValidate()
            begin
                UpdateSalesStages('Discovery Meeting');
            end;
        }
        field(17022194; "PYA Disc. Meeting Completed"; Boolean)
        {
            Caption = 'Discovery Meeting Completed';
            DataClassification = ToBeClassified;
            Description = 'JM191015';
            Editable = false;
        }
        field(17022195; "PYA Presentation Meeting"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015 {TG191022} // changed to Date';
            Caption = 'Presentation Meeting';

            trigger OnValidate()
            begin
                UpdateSalesStages('Presentation Meeting');
            end;
        }
        field(17022196; "PYA Present. Meeting Completed"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015';
            Editable = false;
            Caption = 'Presentation Meeting Completed';
        }
        field(17022197; "PYA Follow-Up Meeting"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015 {TG191022} // changed to Date';
            Caption = 'Follow-Up Meeting';

            trigger OnValidate()
            begin
                UpdateSalesStages('Follow-Up Meeting');
            end;
        }
        field(17022198; "PYA Follow-Up Meet. Completed"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015';
            Editable = false;
            Caption = 'Follow-Up Meeting Completed';
        }
        field(17022199; "PYA Close & Vehicles Ordered"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015 {TG191022} // changed to Date';
            Caption = 'Close & Vehicles Ordered';

            trigger OnValidate()
            begin
                UpdateSalesStages('Close & Vehicles Ordered');
            end;
        }
        field(17022200; "PYA Close & Veh. Ordered Comp."; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015';
            Editable = false;
            Caption = 'Close & Veh. Ordered Completed';
        }
        field(17022201; "PYA Internal Roll-out"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015 {TG191022} // changed to Date';
            Caption = 'Internal Roll-out';

            trigger OnValidate()
            begin
                UpdateSalesStages('Implementation Meeting');
            end;
        }
        field(17022202; "PYA Internal Roll-out Comp."; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'JM191015';
            Editable = false;
            Caption = 'Internal Roll-out Completed';
        }
        field(17022203; "PYA Last Sales Stage Compl."; Text[30])
        {
            Caption = 'Last Sales Stage';
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(17022204; "PYA Competitor/Curr. Prov. Co"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'KC191021';
            Caption = 'Competitor/Current Provider Company';
        }
        field(17022205; "PYA Competitor/Curr. Provider"; Option)
        {
            DataClassification = ToBeClassified;
            Description = 'KC191021';
            OptionCaption = ' ,Completed,In Progress,N/A';
            OptionMembers = " ",Completed,"In Progress","N/A";
            Caption = 'Competitor/Current Provider';
        }
        field(17022206; "PYA Competitor/Curr. Provider."; Text[100])
        {
            Caption = 'Competitor/Current Provider';
            DataClassification = ToBeClassified;
            Description = 'KC191021';
        }
        field(17022207; "PYA Next Step Due Date"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'TG191022';
            Caption = 'Next Step Due Date';
        }
        // BA210321 interest Mod
        field(17022208; "PYA Use Funded Rate"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'TG190730';
            Caption = 'Use Funded Rate';
        }
        field(17022209; "PYA Interest Rate Markup"; Decimal)
        {
            DataClassification = ToBeClassified;
            Description = 'TG190730';
            Caption = 'Interest Rate Markup';
        }

        field(17022210; "PYA Use Blended Rate Markup"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'TG190930';
            InitValue = true;
            Caption = 'Use Blended Rate Markup';
        }

        field(17022211; "PYA Default Funder"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG190730';
            TableRelation = "s4la Funder";
            Caption = 'Default Funder';
        }
        field(17022212; "PYA Next Step"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'TG191022';
            Caption = 'Next Step';
        }
        field(17022213; "PYA Implementation"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'TG191022';
            Caption = 'Implementation';
        }
        field(17022214; "PYA Customer Relations"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'TG191022';
            Caption = 'Customer Relations';
        }
        field(17022215; "PYA Fleet Plan./Veh. Orders"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'TG191022';
            Caption = 'Fleet Planning/Vehicle Orders';
        }
        field(17022216; "PYA Ancillary Sales"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'TG191022';
            Caption = 'Ancillary Sales';
        }
        field(17022217; "PYA Remarketing/Fleet Eval."; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'TG191022';
            Caption = 'Remarketing/Fleet Evaluation';
        }
        field(17022218; "PYA Customer Relations Outing"; Text[100])
        {
            DataClassification = ToBeClassified;
            Description = 'TG191022';
            Caption = 'Customer Relations Outing';
        }
        field(17022226; "PYA Fleet No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG190725';
            Caption = 'Fleet No.';
        }
        field(17022227; "PYA Expiry Date"; Date)
        {
            DataClassification = ToBeClassified;
            Description = 'JM170719';
            Caption = 'Expiry Date';
        }
        field(17022228; "S4L Is Insurer"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Insurer';
        }
        field(17022229; "PYA Is Customer"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Customer';
        }
        field(17022230; "PYA Is Vendor"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Vendor';
        }
        field(17022231; "PYA Is Originator"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Is Originator';
        }
        field(17022232; "PYA Contact Person"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Contact Person';
            TableRelation = Contact;
        }
        field(17022233; "PYA Recommended by"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Recommended by';
            TableRelation = Contact;
        }
    }

    local procedure UpdateSalesStages(lStage: Text)
    begin
        //JM191015
        case lStage of
            'Identified Prospect':
                begin
                    if "PYA Identified Prospect" = 0D then begin
                        "PYA Ident. Prosp. Completed" := false;
                        "PYA Qualified Prospect" := 0D;
                        "PYA Qual. Prospect Completed" := false;
                        "PYA Discovery Meeting" := 0D;
                        "PYA Disc. Meeting Completed" := false;
                        "PYA Presentation Meeting" := 0D;
                        "PYA Present. Meeting Completed" := false;
                        "PYA Follow-Up Meeting" := 0D;
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end else begin
                        "PYA Ident. Prosp. Completed" := true;
                        "PYA Qualified Prospect" := 0D;
                        "PYA Qual. Prospect Completed" := false;
                        "PYA Discovery Meeting" := 0D;
                        "PYA Disc. Meeting Completed" := false;
                        "PYA Presentation Meeting" := 0D;
                        "PYA Present. Meeting Completed" := false;
                        "PYA Follow-Up Meeting" := 0D;
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end;
                end;
            'Qualified Prospect':
                begin
                    if "PYA Qualified Prospect" = 0D then begin
                        "PYA Qual. Prospect Completed" := false;
                        "PYA Discovery Meeting" := 0D;
                        "PYA Disc. Meeting Completed" := false;
                        "PYA Presentation Meeting" := 0D;
                        "PYA Present. Meeting Completed" := false;
                        "PYA Follow-Up Meeting" := 0D;
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end else begin
                        "PYA Ident. Prosp. Completed" := true;
                        "PYA Qual. Prospect Completed" := true;
                        "PYA Discovery Meeting" := 0D;
                        "PYA Disc. Meeting Completed" := false;
                        "PYA Presentation Meeting" := 0D;
                        "PYA Present. Meeting Completed" := false;
                        "PYA Follow-Up Meeting" := 0D;
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end;
                end;
            'Discovery Meeting':
                begin
                    if "PYA Discovery Meeting" = 0D then begin
                        "PYA Disc. Meeting Completed" := false;
                        "PYA Presentation Meeting" := 0D;
                        "PYA Present. Meeting Completed" := false;
                        "PYA Follow-Up Meeting" := 0D;
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end else begin
                        "PYA Ident. Prosp. Completed" := true;
                        "PYA Qual. Prospect Completed" := true;
                        "PYA Disc. Meeting Completed" := true;
                        "PYA Presentation Meeting" := 0D;
                        "PYA Present. Meeting Completed" := false;
                        "PYA Follow-Up Meeting" := 0D;
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end;
                end;
            'Presentation Meeting':
                begin
                    if "PYA Presentation Meeting" = 0D then begin
                        "PYA Present. Meeting Completed" := false;
                        "PYA Follow-Up Meeting" := 0D;
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end else begin
                        "PYA Ident. Prosp. Completed" := true;
                        "PYA Qual. Prospect Completed" := true;
                        "PYA Disc. Meeting Completed" := true;
                        "PYA Present. Meeting Completed" := true;
                        "PYA Follow-Up Meeting" := 0D;
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end;
                end;
            'Follow-Up Meeting':
                begin
                    if "PYA Follow-Up Meeting" = 0D then begin
                        "PYA Follow-Up Meet. Completed" := false;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end else begin
                        "PYA Ident. Prosp. Completed" := true;
                        "PYA Qual. Prospect Completed" := true;
                        "PYA Disc. Meeting Completed" := true;
                        "PYA Present. Meeting Completed" := true;
                        "PYA Follow-Up Meet. Completed" := true;
                        "PYA Close & Vehicles Ordered" := 0D;
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end;
                end;
            'Close & Vehicles Ordered':
                begin
                    if "PYA Close & Vehicles Ordered" = 0D then begin
                        "PYA Close & Veh. Ordered Comp." := false;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end else begin
                        "PYA Ident. Prosp. Completed" := true;
                        "PYA Qual. Prospect Completed" := true;
                        "PYA Disc. Meeting Completed" := true;
                        "PYA Present. Meeting Completed" := true;
                        "PYA Follow-Up Meet. Completed" := true;
                        "PYA Close & Veh. Ordered Comp." := true;
                        "PYA Internal Roll-out" := 0D;
                        "PYA Internal Roll-out Comp." := false;
                    end;
                end;
            'Implementation Meeting':
                begin
                    if "PYA Internal Roll-out" = 0D then begin
                        "PYA Internal Roll-out Comp." := false;
                    end else begin
                        "PYA Ident. Prosp. Completed" := true;
                        "PYA Qual. Prospect Completed" := true;
                        "PYA Disc. Meeting Completed" := true;
                        "PYA Present. Meeting Completed" := true;
                        "PYA Follow-Up Meet. Completed" := true;
                        "PYA Close & Veh. Ordered Comp." := true;
                        "PYA Internal Roll-out Comp." := true;
                    end;
                end;
        end;
        UpdateLastSalesStage;
    end;

    local procedure UpdateLastSalesStage()
    begin
        if "PYA Internal Roll-out Comp." then
            "PYA Last Sales Stage Compl." := 'Implementation Meeting'
        else
            if "PYA Close & Veh. Ordered Comp." then
                "PYA Last Sales Stage Compl." := 'Close & Vehicles Ordered'
            else
                if "PYA Follow-Up Meet. Completed" then
                    "PYA Last Sales Stage Compl." := 'Follow-Up Meeting'
                else
                    if "PYA Present. Meeting Completed" then
                        "PYA Last Sales Stage Compl." := 'Presentation Meeting'
                    else
                        if "PYA Disc. Meeting Completed" then
                            "PYA Last Sales Stage Compl." := 'Discovery Meeting'
                        else
                            if "PYA Qual. Prospect Completed" then
                                "PYA Last Sales Stage Compl." := 'Qualified Prospect'
                            else
                                if "PYA Ident. Prosp. Completed" then
                                    "PYA Last Sales Stage Compl." := 'Identified Prospect'
                                else
                                    "PYA Last Sales Stage Compl." := '';
        /*IF "Implementation Meeting Comp." THEN
          "Last Sales Stage Completed" := "Implementation Meeting"
        ELSE
          IF "Close & Vehicles Ordered Comp." THEN
            "Last Sales Stage Completed" := "Close & Vehicles Ordered"
          ELSE
            IF "Follow-Up Meeting Completed" THEN
              "Last Sales Stage Completed" := "Follow-Up Meeting"
            ELSE
              IF "Presentation Meeting Completed" THEN
                "Last Sales Stage Completed" := "Presentation Meeting"
              ELSE
                IF "Discovery Meeting Completed" THEN
                  "Last Sales Stage Completed" := "Discovery Meeting"
                ELSE
                  IF "Qualified Prospect Completed" THEN
                    "Last Sales Stage Completed" := "Qualified Prospect"
                  ELSE
                    IF "Identified Prospect Completed" THEN
                      "Last Sales Stage Completed" := "Identified Prospect"
                    ELSE
                      "Last Sales Stage Completed" := 0D;
        */



    end;

    //[Scope('Internal')]
    procedure CreateVendorPYA(VendorTemplateCode: Code[20])
    var
        Vend: Record Vendor;
        ContComp: Record Contact;
        "---SL32": Integer;
        VendorTemplate: Record "Vendor Templ.";  //BA210414 Chnaged from "Vendor Template";
        "----KS081216": Integer;
        ContBank: Record "s4la Contact Bank Account";
        VendBank: Record "Vendor Bank Account";
        "---PG130107": Integer;
        L_Contact: Record Contact;
        OldContact: Record Contact;
        ContBank2: Record "s4la Contact Bank Account";
        LeaseSetup: Record "s4la Leasing Setup";
        SalesPersonRec: Record "Salesperson/Purchaser";
        OfficeMgt: Codeunit "Office Management";
        Text009: Label 'The %2 record of the %1 has been created.';
        ContBusRel: record "Contact Business Relation";
        RMSetup: Record "Marketing Setup";
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        HideValidationDialog: Boolean;
    begin
        if Vend.Get("No.") then  //KS160219 silent exist if vendor already exists (because CreateVendor called from multiple places)
            exit;

        if Type = Type::Person then
            CheckForExistingRelationships(ContBusRel."Link to Table"::Vendor);

        TestField("Company No.");
        RMSetup.Get;
        RMSetup.TestField("Bus. Rel. Code for Vendors");

        Clear(Vend);
        Vend.SetInsertFromContact(true);

        /*SL32*/
        Vend."No." := "No."; //always use same Contact no for vendor (and customer also). This is a must.
        Vend."Application Method" := Vend."Application Method"::"Apply to Oldest"; /*KS081209*/
        /*---*/

        Vend.Insert(true);

        /*KS081216 IFAG create bank accounts*/
        ContBank.Reset;
        ContBank.SetRange("Contact No.", "No.");
        if ContBank.FindFirst then
            repeat
                VendBank.Init;
                VendBank.TransferFields(ContBank);
                VendBank."Country/Region Code" := ContBank."Country Code";
                /*KS090204*/
                //VendBank.INSERT;
                if VendBank.Get(VendBank."Vendor No.", VendBank.Code)
                  then
                    VendBank.Modify
                else
                    VendBank.Insert;
            /*---*/
            until ContBank.Next = 0;
        /*---*/

        Vend.SetInsertFromContact(false);

        if Type = Type::Company then
            ContComp := Rec
        else
            ContComp.Get("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Vendor;
        ContBusRel."No." := Vend."No.";
        ContBusRel.Insert(true);

        UpdateCustVendBank.UpdateVendor(ContComp, ContBusRel);

        Vend.Get(ContBusRel."No.");
        Vend.Validate(Name, Name);   // PG120821 was company name

        /*SL32*/
        VendorTemplate.Get(VendorTemplateCode); // there must be a template, and user must choose one
        Vend.Validate("Vendor Posting Group", VendorTemplate."Vendor Posting Group");
        Vend.Validate("Gen. Bus. Posting Group", VendorTemplate."Gen. Bus. Posting Group");
        Vend.Validate("VAT Bus. Posting Group", VendorTemplate."VAT Bus. Posting Group");
        //todo VendorTemplate."Prepaid Vendor Post. Group"
        //todo VendorTemplate."Allocation Vend. Posting Group"

        //TG211008
        if VendorTemplate."Application Method" = VendorTemplate."Application Method"::"Apply to Oldest" then
            Vend."Application Method" := Vend."Application Method"::"Apply to Oldest";
        if VendorTemplate."Application Method" = VendorTemplate."Application Method"::Manual then
            Vend."Application Method" := Vend."Application Method"::Manual;
        //Vend."Application Method" := VendorTemplate."Application Method";   //>>NK141219
        //---//

        /*\\ PG121008 \\*/
        Vend."Primary Contact No." := "No."; /*DV140403*/
        Vend.Modify;

        if OfficeMgt.IsAvailable then
            Page.Run(26, Vend)
        else
            if not HideValidationDialog then//DV170413
                Message(Text009, Vend.TableCaption, Vend."No.");
    end;
}