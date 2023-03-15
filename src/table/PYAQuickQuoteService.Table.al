table 17022181 "Quick Quote Service"
{
    // TG190426 - This table is an exact copy of Contract Services table, except that the Schedule No, Version No. fields removed. Currently this table will only be used for Services included in financed amount.

    DrillDownPageID = "S4LA Contract Services";
    LookupPageID = "S4LA Contract Services";

    fields
    {
        field(1; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
            TableRelation = "S4LA Contract"."Contract No.";
        }
        field(2; "Quick Quote No."; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quick Quote No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
            TableRelation = if ("Service Type" = const(Services)) "S4LA Service".Code WHERE("Currency Code" = FIELD("Currency Code"),
                                                "NA Payment Due" = FIELD("Payment Due"))
            else
            if ("Service Type" = const(Insurance)) "S4LA Insurance" where("Currency Code" = FIELD("Currency Code"))
            else
            if ("Service Type" = const(Accessory)) "S4LA Additional Equipment".Code;

            trigger OnValidate()
            var
                Service: Record "S4LA Service";
                QuickQuoteService: Record "Quick Quote Service";
                InsuranceProduct: Record "S4LA Insurance";
            begin
                if "Service Type" = "Service Type"::Services then begin
                    if Service.Get(Code) then begin
                        Description := Service.Description;
                        "Posting Description" := Service."Posting Description";
                        Validate("Acquisition Source", Service."Acquisition Source");
                    end;
                    Validate("Payment Due", Service."NA Payment Due");
                    Type := Service."NA Type";

                    QuickQuoteService.SetRange("Contract No.", "Contract No.");
                    QuickQuoteService.SetRange("Quick Quote No.", "Quick Quote No.");
                    QuickQuoteService.SetRange(Code, Code);
                    QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Services);
                    if QuickQuoteService.FindFirst then
                        Error(Text50000);

                end else
                    if "Service Type" = "Service Type"::Insurance then begin
                        IF InsuranceProduct.GET(Code) THEN BEGIN

                            Description := InsuranceProduct.Description;
                        END;
                        "Insurance Type" := InsuranceProduct."Insurance Type";

                        QuickQuoteService.SetRange("Contract No.", "Contract No.");
                        QuickQuoteService.SetRange("Quick Quote No.", "Quick Quote No.");
                        QuickQuoteService.SetRange(Code, Code);
                        QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Insurance);
                        if QuickQuoteService.FindFirst then
                            Error(Text50001);

                    end
            end;
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(9; "Currency Code"; Code[20])
        {
            Caption = 'Currency Code';
            Description = 'CCY,removed lookup to "Currency Code"';
            Editable = false;
            TableRelation = "S4LA Financing Currency";
        }
        field(25; "Payment Due"; Option)
        {
            Description = 'EN151113';
            OptionMembers = "With Upfront Fees","Included in Financed Amount","Included in Installment","Re-charge Actual Cost";
            Caption = 'Payment Due';

            trigger OnValidate()
            var
                Schedule: Record "S4LA Schedule";
            begin
            end;
        }
        field(37; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';

            trigger OnValidate()
            begin
                if xRec."Total Amount" <> "Total Amount" then begin
                    if "Currency Code" <> '' then
                        "Total Amount (LCY)" := Round(recCurrExRate.ExchangeAmtFCYToLCY(WorkDate, "Currency Code",
                                                       "Total Amount", recCurrExRate.ExchangeRate(WorkDate, "Currency Code")))
                    else
                        "Total Amount (LCY)" := "Total Amount";
                end;
            end;
        }
        field(38; "Total Amount (LCY)"; Decimal)
        {
            Caption = 'Total Amount (LCY)';

            trigger OnValidate()
            begin
                if "Total Amount (LCY)" <> xRec."Total Amount (LCY)" then begin
                    if "Currency Code" <> '' then
                        "Total Amount" := Round(recCurrExRate.ExchangeAmtLCYToFCY(WorkDate, "Currency Code",
                                                       "Total Amount (LCY)", recCurrExRate.ExchangeRate(WorkDate, "Currency Code")))
                    else
                        "Total Amount" := "Total Amount (LCY)";
                end;
            end;
        }
        field(39; "No. Of Months"; Integer)
        {
            Description = 'EN151116';
            Caption = 'No. of Months';
        }
        field(48; "Acquisition Source"; Option)
        {
            OptionMembers = Supplier,Originator,Lessor,"Servicer (3rd party)";
            Caption = 'Acquisition Source';

            trigger OnValidate()
            var
                Contr: Record "S4LA Contract";
                Services: Record "S4LA Service";
            begin
                if not Contr.Get("Contract No.") then
                    Contr.Init;

                if not Services.Get(Code) then
                    Services.Init;

                case "Acquisition Source" of
                    "Acquisition Source"::Supplier:
                        "Servicer No." := Contr."Supplier No.";
                    "Acquisition Source"::Originator:
                        "Servicer No." := Contr."Originator No.";
                    "Acquisition Source"::Lessor:
                        "Servicer No." := '';
                    "Acquisition Source"::"Servicer (3rd party)":
                        "Servicer No." := Services."Servicer No.";
                end;
            end;
        }
        field(50; "Servicer No."; Code[20])
        {
            TableRelation = Contact;
            Caption = 'Servicer No.';

            trigger OnValidate()
            var
                Contr: Record "S4LA Contract";
                Services: Record "S4LA Service";
            begin
                if not Contr.Get("Contract No.") then
                    Contr.Init;

                if not Services.Get(Code) then
                    Services.Init;

                case true of

                    "Servicer No." = '':
                        Validate("Acquisition Source"); //set default servicer, per current acq.source

                    "Servicer No." = Contr."Supplier No.":
                        "Acquisition Source" := "Acquisition Source"::Supplier;

                    "Servicer No." = Contr."Originator No.":
                        "Acquisition Source" := "Acquisition Source"::Originator;

                    else
                        "Servicer No." := Services."Servicer No.";

                end;
            end;
        }
        field(51; "Servicer Name"; Text[100])
        {
            CalcFormula = Lookup(Contact.Name WHERE("No." = FIELD("Servicer No.")));
            Description = 'lookup';
            Editable = false;
            FieldClass = FlowField;
            Caption = 'Servicer Name';
        }
        field(60; "Posting Description"; Text[80])
        {
            Caption = 'Posting Description';
        }

        //BA210624
        field(61; "Equipment Type"; Option)
        {
            OptionCaption = ' ,Accessories,Bolt-On';
            OptionMembers = " ",Accessories,"Bolt-On";
            Caption = 'Equipment Type';
        }

        field(62; Accessory; Boolean)
        {
            Caption = 'Accessory';

        }
        field(63; "Service Type"; Option)
        {
            OptionMembers = " ","Services","Insurance","Accessory";
            OptionCaption = ' ,Services,Insurance,Accessory';
            Caption = 'Service Type';
        }
        field(50002; Type; Enum "NA Services Type")
        {
            Caption = 'Type';
        }

        field(50003; "Insurance Type"; Enum "S4LA Insurance Type")
        {
            Caption = 'Type';
        }
    }

    keys
    {
        key(Key1; "Contract No.", "Quick Quote No.", "Line No.", "Payment Due", "Service Type")
        {
            Clustered = true;
            SumIndexFields = "Total Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        QuickQuoteService: Record "Quick Quote Service";
    begin
        if "Line No." = 0 then begin
            QuickQuoteService.SetRange("Contract No.", "Contract No.");
            QuickQuoteService.SetRange("Quick Quote No.", "Quick Quote No.");
            if QuickQuoteService.FindLast then
                "Line No." := QuickQuoteService."Line No." + 10000
            else
                "Line No." := 10000;
        end;

        // if (Code = '') and not Accessory then  //BA210624
        //  Error(Text001);

        //BA210624
        if "Service Type" = "Service Type"::Accessory then begin
            Accessory := true;
            "Equipment Type" := "Equipment Type"::Accessories;
        end;
    end;

    var
        recService: Record "S4LA Service";
        recCurrExRate: Record "Currency Exchange Rate";
        recContract: Record "S4LA Contract";
        codLeasingMgt: Codeunit "S4LA Contract Mgt";
        Text001: Label 'Please enter a code & verify the Values';
        InUpdate: Boolean;
        Text50000: Label 'Please do not enter same service twice';

        Text50001: Label 'Please do not enter same service twice';

    [Scope('onPrem')]
    procedure UpdateQuickQuoteAccessory(QuoteNo: Integer; var QuickQuoteWksht: Record "Quick Quote Worksheet")
    var
        QuickQuoteService: Record "Quick Quote Service";
    begin

        QuickQuoteService.RESET;
        QuickQuoteService.SETRANGE("Contract No.", QuickQuoteWksht."Contract No.");
        QuickQuoteService.SETRANGE("Quick Quote No.", QuoteNo);
        QuickQuoteService.SetRange(Accessory, true);
        QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Accessory);
        QuickQuoteService.CALCSUMS("Total Amount");
        CASE QuoteNo OF
            1:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote1 Total Addons", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            2:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote2 Total Addons", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            3:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote3 Total Addons", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
        END;
    end;

    //BA210624 - for contract services
    [Scope('onPrem')]
    procedure UpdateQuickQuoteServices(QuoteNo: Integer; var QuickQuoteWksht: Record "Quick Quote Worksheet")
    var
        QuickQuoteService: Record "Quick Quote Service";
    begin
        QuickQuoteService.RESET;
        QuickQuoteService.SETRANGE("Contract No.", QuickQuoteWksht."Contract No.");
        QuickQuoteService.SETRANGE("Quick Quote No.", QuoteNo);
        QuickQuoteService.SetRange(Accessory, false);
        QuickQuoteService.SetRange("Payment Due", QuickQuoteService."Payment Due"::"Included in Financed Amount");
        QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Services);
        QuickQuoteService.CALCSUMS("Total Amount");
        CASE QuoteNo OF
            1:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote1 Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            2:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote2 Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            3:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote3 Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
        END;
    end;

    //BA210624 - for monthly fees
    [Scope('onPrem')]
    procedure UpdateQuickQuoteMonthlyFees(QuoteNo: Integer; var QuickQuoteWksht: Record "Quick Quote Worksheet")
    var
        QuickQuoteService: Record "Quick Quote Service";
    begin

        QuickQuoteService.RESET;
        QuickQuoteService.SETRANGE("Contract No.", QuickQuoteWksht."Contract No.");
        QuickQuoteService.SETRANGE("Quick Quote No.", QuoteNo);
        QuickQuoteService.SetRange(Accessory, false);
        QuickQuoteService.SetRange("Payment Due", QuickQuoteService."Payment Due"::"Included in Installment");
        QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Services);
        QuickQuoteService.CALCSUMS("Total Amount");
        CASE QuoteNo OF
            1:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote1 Monthly Overhead", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            2:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote2 Monthly Overhead", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            3:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote2 Monthly Overhead", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
        END;


    end;

    //BA210624 - for upfront services
    [Scope('onPrem')]
    procedure UpdateQuickQuoteUpfrontServ(QuoteNo: Integer; var QuickQuoteWksht: Record "Quick Quote Worksheet")
    var
        QuickQuoteService: Record "Quick Quote Service";
    begin
        QuickQuoteService.RESET;
        QuickQuoteService.SETRANGE("Contract No.", QuickQuoteWksht."Contract No.");
        QuickQuoteService.SETRANGE("Quick Quote No.", QuoteNo);
        QuickQuoteService.SetRange(Accessory, false);
        QuickQuoteService.SetRange("Payment Due", QuickQuoteService."Payment Due"::"With Upfront Fees");
        QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Services);
        QuickQuoteService.CALCSUMS("Total Amount");
        CASE QuoteNo OF
            1:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote1 Upfront Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            2:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote2 Upfront Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            3:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote3 Upfront Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
        END;
    end;


    //BA210714 - for upfront  insurance
    [Scope('onPrem')]
    procedure UpdateQuickQuoteMonthlyInsurance(QuoteNo: Integer; var QuickQuoteWksht: Record "Quick Quote Worksheet")
    var
        QuickQuoteService: Record "Quick Quote Service";
    begin
        QuickQuoteService.RESET;
        QuickQuoteService.SETRANGE("Contract No.", QuickQuoteWksht."Contract No.");
        QuickQuoteService.SETRANGE("Quick Quote No.", QuoteNo);
        QuickQuoteService.SetRange(Accessory, false);
        QuickQuoteService.SetRange("Payment Due", QuickQuoteService."Payment Due"::"With Upfront Fees");
        QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Insurance);
        QuickQuoteService.CALCSUMS("Total Amount");
        CASE QuoteNo OF
            1:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote1 Insurance Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            2:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote2 Insurance Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            3:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote3 Insurance Services", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
        END;
    end;

    //BA210714 - for Financed  insurance
    [Scope('onPrem')]
    procedure UpdateQuickQuoteMonthlyFinInsurance(QuoteNo: Integer; var QuickQuoteWksht: Record "Quick Quote Worksheet")
    var
        QuickQuoteService: Record "Quick Quote Service";
    begin
        QuickQuoteService.RESET;
        QuickQuoteService.SETRANGE("Contract No.", QuickQuoteWksht."Contract No.");
        QuickQuoteService.SETRANGE("Quick Quote No.", QuoteNo);
        QuickQuoteService.SetRange(Accessory, false);
        QuickQuoteService.SetRange("Payment Due", QuickQuoteService."Payment Due"::"Included in Financed Amount");
        QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Insurance);
        QuickQuoteService.CALCSUMS("Total Amount");
        CASE QuoteNo OF
            1:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote1 Financed Insurance", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            2:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote2 Financed Insurance", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            3:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote3 Financed Insurance", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
        END;
    end;


    //BA220113 - for Monthly insurance
    [Scope('onPrem')]
    procedure UpdateQuickQuoteMonthlyInsurServices(QuoteNo: Integer; var QuickQuoteWksht: Record "Quick Quote Worksheet")
    var
        QuickQuoteService: Record "Quick Quote Service";
    begin
        QuickQuoteService.RESET;
        QuickQuoteService.SETRANGE("Contract No.", QuickQuoteWksht."Contract No.");
        QuickQuoteService.SETRANGE("Quick Quote No.", QuoteNo);
        QuickQuoteService.SetRange(Accessory, false);
        QuickQuoteService.SetRange("Payment Due", QuickQuoteService."Payment Due"::"Included in Installment");
        QuickQuoteService.SetRange("Service Type", QuickQuoteService."Service Type"::Insurance);
        QuickQuoteService.CALCSUMS("Total Amount");
        CASE QuoteNo OF
            1:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote1 Monthly Insurance", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            2:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote2 Monthly Insurance", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
            3:
                BEGIN
                    QuickQuoteWksht.VALIDATE("Quote3 Monthly Insurance", QuickQuoteService."Total Amount");
                    QuickQuoteWksht.Modify();
                END;
        END;
    end;
}