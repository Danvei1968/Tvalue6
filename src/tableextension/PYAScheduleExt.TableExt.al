tableextension 17022206 "PYA Schedule Ext." extends "S4LA Schedule"
{
    fields
    {
        field(17022090; "NA Customer Residual"; Decimal)
        {
            Caption = 'Customer Residual';
        }
        field(17022091; "NA Refundable Security Deposit"; Decimal)
        {
            Caption = 'Refundable Security Deposit';

            trigger OnValidate()
            begin
                TotalUpfrontFees;//DV170413
            end;
        }
        field(17022092; "NA Date out"; Date)
        {
            Caption = 'Date out';
            Description = 'DV170421';
        }
        field(17022093; "NA Km In"; Decimal)
        {
            Caption = 'Miles In';
            DecimalPlaces = 0 : 0;
            Description = 'DV170421';
        }
        field(17022094; "NA Km Out"; Decimal)
        {
            Caption = 'Miles Out';
            DecimalPlaces = 0 : 0;
            Description = 'DV170421';
        }
        field(17022095; "NA Fuel"; Decimal)
        {
            Caption = 'Fuel';
            Description = 'DV170421';
        }
        field(17022096; "NA Date In"; Date)
        {
            Caption = 'Date In';
            Description = 'DV170421';
        }
        field(17022098; "NA Monthly depreciation %"; Decimal)
        {
            Caption = 'Monthly depreciation %';
            DecimalPlaces = 2 : 7;
        }
        field(17022099; "NA Extended Termination Date"; Date)
        {
            Caption = 'Extended Termination Date';
            Description = 'JM171012';

            trigger OnValidate()
            var
                Ltext001: Label 'Ext Term date must be later than Ext start date %1';
                Contr: Record "s4la Contract";
            begin
                IF "NA Extended Termination Date" < "NA Start Extension Date" THEN
                    ERROR(Ltext001, "NA Start Extension Date");
                /*DV190320*/
                Contr.GET("Contract No.");
                Contr."NA Extended Date" := "NA Extended Termination Date";
                Contr.MODIFY;
                /*---*/

            end;
        }
        field(17022100; "NA Equity"; Decimal)
        {
            Caption = 'Equity';
            Description = 'DV171219';

            trigger OnValidate()
            begin
                UpdateCapitalAmount;//DV171219
            end;
        }
        field(17022101; "NA Shortfall"; Decimal)
        {
            Caption = 'Shortfall';
            Description = 'DV171219';

            trigger OnValidate()
            begin
                UpdateCapitalAmount;//DV171219
            end;
        }
        field(17022102; "NA Incl. First P. to First Inv"; Boolean)
        {
            Caption = 'Include First Payment to First Invoice';
            InitValue = false;

            trigger OnValidate()
            var
                CompInfo: Record "Company Information";
            begin
                IF xRec."NA Incl. First P. to First Inv" <> "NA Incl. First P. to First Inv" AND (NOT "NA Incl. First P. to First Inv") THEN
                    "NA First Monthly Pmt. in Advn" := 0;

                /*DV171013*/
                CompInfo.GET;
                IF "NA Incl. First P. to First Inv" THEN BEGIN
                    IF CompInfo."Country/Region Code" <> 'US' THEN BEGIN
                        "NA First Monthly Pmt. in Advn" := GetNextPaymentAmount;
                    END ELSE BEGIN
                        //"First Monthly Payment in Advn" := ??
                    END
                    /*---*/
                END ELSE
                    "NA First Monthly Pmt. in Advn" := 0;

            end;
        }
        field(17022103; "NA First Monthly Pmt. in Advn"; Decimal)
        {
            Caption = 'First Monthly Payment in Advn';
            DataClassification = ToBeClassified;
        }
        field(17022104; "NA Profit Value"; Decimal)
        {
            Caption = 'Profit Value';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                "NA Customer Residual" := "NA Profit Value" + "Residual Value";//DV190125
            end;
        }
        field(17022105; "NA Start Extension Date"; Date)
        {
            Caption = 'Start Extension Date';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                Ltext001: Label 'Ext Start date has to be after contract end date %1';
                SchedLn: Record "S4LA Schedule Line";
            begin
                /*DV190304*/
                SchedLn.RESET;
                SchedLn.SETRANGE("Contract No.", "Contract No.");
                SchedLn.SETRANGE("Schedule No.", "Schedule No.");
                SchedLn.SETRANGE("Version No.", "Version No.");
                SchedLn.SETRANGE(Invoiced, FALSE);
                IF NOT SchedLn.FINDFIRST THEN
                    SchedLn.Date := "Ending Date";
                /*---*/
                IF "NA Start Extension Date" < SchedLn.Date THEN
                    ERROR(Ltext001, SchedLn.Date);

            end;
        }
        field(17022106; "NA Downpayment Tax Group"; Code[20])
        {
            Caption = 'Downpayment VAT Group';
            DataClassification = ToBeClassified;
            TableRelation = "VAT Product Posting Group";
        }
        field(17022107; "NA Migration Flag"; Boolean)
        {
            Caption = 'Migration Flag';
            DataClassification = ToBeClassified;
            Description = 'JM170817';
        }
        field(17022108; "NA Asset Book Value on Act."; Decimal)
        {
            Caption = 'Asset Book Value On Activation';
            Description = 'JM170817';
        }
        field(17022109; "NA Equity Tax Group"; Code[20])
        {
            Caption = 'Equity VAT Group';
            DataClassification = ToBeClassified;
            TableRelation = "VAT Product Posting Group";
        }
        field(17022110; "NA Schedule Extension Date"; Date)
        {
            Caption = 'Schedule Extension Date';
            DataClassification = ToBeClassified;
        }

        //BA220120
        modify("Capital Amount")
        {
            trigger OnAfterValidate()
            begin
                CalcMonthlyDeprPct;
            end;
        }

        modify("Term (months)")
        {
            trigger OnAfterValidate()
            begin
                CalcMonthlyDeprPct;
            end;
        }
        field(17022180; "PYA Interest Rate Modified"; Boolean)
        {
            Caption = 'Interest Rate Modified';

        }

        field(17022181; "PYA Blended Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
            Description = 'TG190710';
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
            Caption = 'Blended Cost';
        }

        field(17022182; "PYA Interest Rate Markup"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 5 : 5;
            Description = 'TG190730';
            MaxValue = 100;
            MinValue = -100;
            Caption = 'Interest Rate Markup';

            trigger OnValidate()
            begin
                RecalcTotalInterest;//DV181116
            end;
        }
        //BA220408 
        field(17022183; "PYA Manual Installment Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Description = 'BA220408';
            Caption = 'Manual Installment Amount';

            trigger OnValidate()
            var
                recContract: Record "S4LA Contract";
                recSchedule: Record "S4LA Schedule";
                FinProd: Record "S4LA Financial Product";
                ContractServices: Record "S4LA Contract Service";

                //ContractMgt: Codeunit "NA Contract Mgt";
                TempInterest: Decimal;
                SLine: Record "S4LA Schedule Line";
                ContractService: Record "S4LA Contract Service";
                Services: Record "S4LA Service";
                InstallmentFrequency: Record "S4LA Frequency";
                InstallmentDay: Integer;
                Tax1: Decimal;
                Tax2: Decimal;
                cdLeasingContMgt: Codeunit "S4LA Contract Mgt";

            begin
                if "PYA Manual Installment Amount" <> 0 then
                    Recalculate := true;

                if (rec."PYA Manual Installment Amount" = 0) and (xRec."PYA Manual Installment Amount" <> 0) then
                    Recalculate := true;

                IF xRec."PYA Manual Installment Amount" <> "PYA Manual Installment Amount" THEN BEGIN
                    IF "PYA Manual Installment Amount" <> 0 THEN BEGIN
                        FinProd.GET("Financial Product");
                        /*DV170531*/
                        recContract.GET("Contract No.");
                        recSchedule := Rec;
                        InstallmentFrequency.GET(recSchedule.Frequency);
                        Tax1 := 0;
                        Tax2 := 0;
                        "Manual Inertia Amount" := 0;
                        SLine.RESET;
                        SLine.SETRANGE("Contract No.", "Contract No.");
                        SLine.SETRANGE("Schedule No.", "Schedule No.");
                        SLine.SETRANGE("Version No.", "Version No.");
                        SLine.SETFILTER("Entry Type", '%1|%2', SLine."Entry Type"::Installment, SLine."Entry Type"::Inertia);
                        IF NOT SLine.FINDLAST THEN
                            SLine.Date := WORKDATE;
                        //TG210420
                        if InstallmentFrequency."Frequency Base Unit" = InstallmentFrequency."Frequency Base Unit"::Week then
                            InstallmentDay := Date2DWY(SLine.Date, 1)
                        else
                            //---//
                            InstallmentDay := DATE2DMY(SLine.Date, 1);
                        SLine.Date := CalcNextPaymentDate(SLine.Date, InstallmentDay, InstallmentFrequency);
                        // ContractMgt.TaxCalculate(recSchedule, FinProd."NA Principal Tax Gr.(Instal.)", ABS("Manual Installment Amount"), SLine.Date);
                        "Manual Inertia Amount" := "Manual Installment Amount";
                        // Tax1 := ROUND(ContractMgt.fnTaxAmount1, 0.01);
                        // Tax2 := ROUND(ContractMgt.fnTaxAmount2, 0.01);
                        ContractServices.RESET;
                        ContractServices.SETRANGE("Contract No.", SLine."Contract No.");
                        ContractServices.SETRANGE("Schedule No.", SLine."Schedule No.");
                        ContractServices.SETRANGE("Version No.", SLine."Version No.");
                        ContractServices.SETRANGE("Payment Due", ContractServices."Payment Due"::"Included in Installment");
                        IF ContractServices.FINDSET THEN
                            REPEAT
                                Services.GET(ContractServices.Code);
                                "Manual Inertia Amount" += ContractServices."Service Cost (Monthly)";

                                IF NOT recSchedule."Amounts Including VAT" THEN BEGIN
                                    //   ContractMgt.TaxCalculate(recSchedule, Services."NA Tax Group", ContractServices."Service Cost (Monthly)", SLine.Date);
                                    //   Tax1 += ContractMgt.fnTaxAmount1;
                                    //    Tax2 += ContractMgt.fnTaxAmount2;
                                END;
                            UNTIL ContractServices.NEXT = 0;

                        "Manual Inertia Amount" += ROUND(Tax1, 0.01) + ROUND(Tax2, 0.01);
                        /*---*/
                    end;
                end;
                //----TG190111 // The schedule is not recalculated when validating this field from a codeunit.
                if not "NA Migration Flag" then
                    if Recalculate then begin
                        cdLeasingContMgt.RecalcScheduleLines(Rec);
                    end;
                //---//
            end;
        }
        field(17022184; "PYA Contract Status"; Enum "PYA Contract Status")
        {
            Description = '0=Locked,1=Quote,2=Application,3=Contract,4=Closed,5=Withdrawn';
            caption = 'Contract Status';
            TableRelation = "S4LA Status".Code WHERE("Target Table ID" = CONST(17021230));
        }
        field(17022185; "PYA Annuity/Linear"; Enum "PYA ScheduleAnnuityLinear")
        {
            Description = '0=Locked,1=Quote,2=Application,3=Contract,4=Closed,5=Withdrawn';
            caption = 'Annuity/Linear';
        }

        //--//
        modify("Financial Product")
        {
            trigger OnAfterValidate()
            var
                FinProduct: Record "S4LA Financial Product";
            begin
                //EN210325 >> must not override with standard program on quote conversion
                if xRec."Financial Product" = "Financial Product" then
                    exit;
                //EN210325 <<

                if not FinProduct.Get("Financial Product") then
                    FinProduct.Init;
                /*PYA*/
                //VALIDATE("Program Code", FinProduct."NA Default Program"); //JM170627
                IF "NA Equity Tax Group" = '' THEN//DV190411
                    Validate("NA Equity Tax Group", FinProduct."Principal VAT Gr.(Instalment)");//DV190410
                                                                                                /*TG191121*/
                IF "NA Downpayment Tax Group" = '' THEN
                    Validate("NA Downpayment Tax Group", FinProduct."Principal VAT Gr.(Instalment)");
                /*---*/
            end;
        }
        modify("Starting Date")
        {
            trigger OnAfterValidate()
            begin
                //BA210622
                if ("Starting Date" <> 0D) AND ("Activation Date" <> 0D) then
                    Rec.CalcProRataAmt; // SK170420 ??? - REMOVED BY SOFT4
            end;
        }
        modify("Program Code")
        {
            trigger OnAfterValidate()
            begin
                IF "Program Code" = '' THEN begin
                    "Interest %" := 0; //PYA - ?? NOT IN S4L58
                    "Interest Rate" := 0; //PYA
                end;
            end;
        }

        modify("Residual Value")
        {
            trigger OnAfterValidate()
            begin
                "NA Customer Residual" := "NA Profit Value" + "Residual Value";//DV181206
                CalcMonthlyDeprPct; //BA220120
            end;
        }
        modify("Manual Installment Amount")
        {
            trigger OnAfterValidate()
            var
                recContract: Record "S4LA Contract";
                recSchedule: Record "S4LA Schedule";
                FinProd: Record "S4LA Financial Product";
                ContractServices: Record "S4LA Contract Service";
                TempInterest: Decimal;
                SLine: Record "S4LA Schedule Line";
                ContractService: Record "S4LA Contract Service";
                Services: Record "S4LA Service";
                InstallmentFrequency: Record "S4LA Frequency";
                InstallmentDay: Integer;
                Tax1: Decimal;
                cdLeasingContMgt: Codeunit "S4LA Contract Mgt";
                PrincipalVAT: Decimal;
            begin
                IF xRec."Manual Installment Amount" <> "Manual Installment Amount" THEN BEGIN
                    IF "Manual Installment Amount" <> 0 THEN BEGIN
                        FinProd.GET("Financial Product");
                        /*DV170531*/
                        recContract.GET("Contract No.");
                        recSchedule := Rec;
                        InstallmentFrequency.GET(recSchedule.Frequency);
                        GLSetup.Get;
                        if not Currency.Get(recSchedule."Currency Code") then
                            Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
                        Tax1 := 0;
                        "Manual Inertia Amount" := 0;
                        SLine.RESET;
                        SLine.SETRANGE("Contract No.", "Contract No.");
                        SLine.SETRANGE("Schedule No.", "Schedule No.");
                        SLine.SETRANGE("Version No.", "Version No.");
                        SLine.SETFILTER("Entry Type", '%1|%2', SLine."Entry Type"::Installment, SLine."Entry Type"::Inertia);
                        IF NOT SLine.FINDLAST THEN
                            SLine.Date := WORKDATE;
                        //TG210420
                        if InstallmentFrequency."Frequency Base Unit" = InstallmentFrequency."Frequency Base Unit"::Week then
                            InstallmentDay := Date2DWY(SLine.Date, 1)
                        else
                            //---//
                            InstallmentDay := DATE2DMY(SLine.Date, 1);
                        SLine.Date := CalcNextPaymentDate(SLine.Date, InstallmentDay, InstallmentFrequency);
                        PrincipalVAT := ContractMgt.GetVATfactor(recContract."Customer VAT Bus. Group", FinProd."Principal VAT Gr.(Instalment)");
                        "Manual Inertia Amount" := "Manual Installment Amount";
                        Tax1 := Round(Abs("Manual Installment Amount") * PrincipalVAT, Currency."Amount Rounding Precision");
                        ContractServices.RESET;
                        ContractServices.SETRANGE("Contract No.", SLine."Contract No.");
                        ContractServices.SETRANGE("Schedule No.", SLine."Schedule No.");
                        ContractServices.SETRANGE("Version No.", SLine."Version No.");
                        ContractServices.SETRANGE("Payment Due", ContractServices."Payment Due"::"Included in Installment");
                        if ContractServices.FindSet() then
                            repeat
                                Services.GET(ContractServices.Code);
                                "Manual Inertia Amount" += ContractServices."Service Cost (Monthly)";

                                if not recSchedule."Amounts Including VAT" then begin
                                    Services.TestField("VAT Group");
                                    Tax1 += (ContractServices."Service Cost (Monthly)" * ContractMgt.GetVATfactor(recContract."Customer VAT Bus. Group", Services."VAT Group"));
                                end;
                            until ContractServices.NEXT = 0;

                        "Manual Inertia Amount" += Round(Tax1, Currency."Amount Rounding Precision");
                        /*---*/
                    end;
                end;
                //----TG190111 // The schedule is not recalculated when validating this field from a codeunit.
                if not "NA Migration Flag" then
                    if Recalculate then begin
                        cdLeasingContMgt.RecalcScheduleLines(Rec);
                    end;
                //---//                  
            end;
        }

        modify("Activation Date")
        {
            trigger OnAfterValidate()
            begin
                //BA210622
                if ("Starting Date" <> 0D) AND ("Activation Date" <> 0D) then
                    Rec.CalcProRataAmt(); // SK170420 //pya - REMOVED BY S4L
            end;

        }
        modify("Total Asset Price")
        {
            trigger OnBeforeValidate()
            begin
                //SM180328 - Start
                IF ("Total Asset Price" + "Total Bolt-Ons") <> 0 THEN
                    "Residual Value %" := "Residual Value" / ("Total Asset Price" + "Total Bolt-Ons") * 100;
                //---
            end;
        }

        modify("Interest %")
        {
            trigger OnAfterValidate()
            var
                Contr: record "s4la Contract";
            begin
                // {TG191219}
                IF Contr.GET("Contract No.") THEN BEGIN
                    Contr.fnSystemIntRate(IntRate, IntRateMarkup, FundedRate, 0, QuickQuoteWksht);
                    IF "Interest %" <> IntRate THEN
                        "PYA Interest Rate Modified" := TRUE;
                END;

            end;
        }

        modify("Customer No.")
        {
            trigger OnAfterValidate()
            begin
                //    {TG190730}
                IF xRec."Customer No." <> "Customer No." THEN
                    IF "Customer No." <> '' THEN BEGIN
                        Cont.GET("Customer No.");
                        UpdateInterestRate;
                    end;

            end;
        }
    }

    procedure CalcNextPaymentDate(PreviousDate: Date; PaymentDay: Integer; InstallmentFrequency: Record "s4la Frequency") NextPaymentDate: Date
    begin
        CASE InstallmentFrequency."Frequency Base Unit" OF
            InstallmentFrequency."Frequency Base Unit"::Week:
                NextPaymentDate := CALCDATE(STRSUBSTNO('<+%1W>', InstallmentFrequency."Frequency Term in Base Units"), PreviousDate);
            InstallmentFrequency."Frequency Base Unit"::Month:
                NextPaymentDate := CALCDATE(STRSUBSTNO('<+%1M>', InstallmentFrequency."Frequency Term in Base Units"), PreviousDate);
        END;
        NextPaymentDate := AdjustDateToPaymentDay(NextPaymentDate, PaymentDay, InstallmentFrequency);
    end;

    procedure AdjustDateToPaymentDay(BaseDate: Date; PaymentDay: Integer; InstallmentFrequency: Record "s4la Frequency") PaymentDate: Date
    begin
        // Set to preferred payment day
        PaymentDate := BaseDate;
        IF BaseDate = 0D THEN
            EXIT(BaseDate);

        IF PaymentDay = 0 THEN
            EXIT(BaseDate);

        CASE InstallmentFrequency."Frequency Base Unit" OF
            InstallmentFrequency."Frequency Base Unit"::Week:
                PaymentDate := DWY2DATE(PaymentDay, DATE2DWY(BaseDate, 2), DATE2DWY(BaseDate, 3));

            ELSE BEGIN
                IF DATE2DMY(CALCDATE('<CM>', BaseDate), 1) < PaymentDay THEN  //last month date lower than payment date
                    PaymentDay := DATE2DMY(CALCDATE('<CM>', BaseDate), 1);
                PaymentDate := DMY2DATE(PaymentDay, DATE2DMY(BaseDate, 2), DATE2DMY(BaseDate, 3));
            END;
        END;
    end;

    procedure GetNextContrSvcLineNo(): Integer
    var
        ContrSvc2: Record "S4LA Contract Service";
    begin
        ContrSvc2.RESET;
        ContrSvc2.SETRANGE("Contract No.", "Contract No.");
        ContrSvc2.SETRANGE("Schedule No.", "Schedule No.");
        ContrSvc2.SETRANGE("Version No.", "Version No.");
        IF ContrSvc2.FINDLAST THEN
            EXIT(ContrSvc2."Line No." + 10000);
        EXIT(10000);
    end;

    trigger OnAfterDelete()
    var
        FA: Record "Fixed Asset";
    begin
        Asset.reset;
        Asset.SetRange("Contract No.", "Contract No.");
        if Asset.FindFirst then
            repeat
                IF FA.GET(asset."Asset No.") THEN BEGIN
                    CLEAR(FA."PYA Contract No");//DV230210
                    FA.MODIFY;
                end;
            until Asset.next = 0;
    end;

    procedure PYATriggerStatusChange(NewStatusTrigger: Enum "PYA Contract Status"; EffectiveDate: Date)
    var
        SchedStatus: Record "S4LA Status";
        NewStatusCode: Code[20];

    begin
        IF NewStatusTrigger = Status THEN
            EXIT;  //no change.

        SchedStatus.RESET;
        SchedStatus.SETRANGE("Target Table ID", DATABASE::"S4LA Schedule");
        SchedStatus.SETRANGE("Trigger Option No.", NewStatusTrigger);
        IF NOT SchedStatus.FINDFIRST
          THEN
            EXIT;  //no status for trigger. Leave existing Schedule status

        NewStatusCode := SchedStatus.Code;
    end;

    procedure CalcProRataAmtNA()
    var
        finProd: record "S4LA Financial Product";
        ProRataDaysDiff: Integer;
    begin
        "Pro-Rata Amount" := 0;
        FinProd.Get("Financial Product");
        if FinProd."Pro-rata Allowed" then begin
            if "Activation Date" < "Starting Date" then begin
                ProRataDaysDiff := "Starting Date" - "Activation Date" - 1;
                if FinProd."Min Pro-rata Days" <= ProRataDaysDiff then
                    "Pro-Rata Amount" := Round(GetNextPaymentAmount / 30 * ProRataDaysDiff, 0.01);
            end;
        end;
        //OnCalcProRataAmt_BeforeExit(Rec); //S4L.NA
    end;

    //BA220120 -  Calculate Monthly depreciation percent
    local procedure CalcMonthlyDeprPct()
    var
        Currency: record Currency;
        GLSetup: record "General Ledger Setup";
        LeasingSetup: record "s4la Leasing Setup";
    begin
        GLSetup.Get;
        LeasingSetup.Get;
        if not Currency.Get("Currency Code") then
            Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";

        if ("Term (months)" <> 0) and ("Net Capital Amount" <> 0) then
            "NA Monthly depreciation %" := Round((Round(("Net Capital Amount" - "Residual Value") / "Term (months)", Currency."Amount Rounding Precision") / "Net Capital Amount") * 100, 0.01);
    end;

    var
        Cont: Record Contact;
        fundedRate: Decimal;
        IntRate: Decimal;
        QuickQuoteWksht: record "Quick Quote Worksheet";
        IntRateMarkUp: Decimal;
        ContractMgt: Codeunit "s4la Contract Mgt";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        Asset: Record "S4LA Asset";
}