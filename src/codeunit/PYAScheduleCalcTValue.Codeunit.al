codeunit 17022159 "PYA Schedule Calc. - TValue"
{
    // For proof-of-calc refer to "Design Patterns/TValue v3.xlsx"

    trigger OnRun()
    begin
    end;

    var
        LeasingSetup: Record "S4LA Leasing Setup";
        LeasingContrMngt: Codeunit "S4LA Contract Mgt";
        S4LCommon: Codeunit "S4LA Common Functions";
        ScheduleVersionStatusError: Label 'You are trying to recalculate installment schedule with "%1" = %2. You have to create schedule version with "%3" = %4 first if you want to recalculate it.\ "%5" = %6, "%7" = %8, "%9" = %10"';
        VarInterestChangeRecalculation: Boolean;
        ratePerPeriod: Decimal;
        ErrEffectiveDate: Label '%1 %2 must be in the period %3 %4.';

    procedure SetVarInterestChangeRecalculation(ParamValue: Boolean)
    begin
        VarInterestChangeRecalculation := ParamValue;
    end;

    procedure CalcSchedule(var Schedule: Record "S4LA Schedule"; PeriodNo: Integer)
    var
        IsHandled: Boolean;
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        FinProd: Record "S4LA Financial Product";
        Contr: Record "S4LA Contract";
        ContractMgt: Codeunit "S4LA Contract Mgt";
        InstallmentFrequency: Record "S4LA Frequency";
        CalculationGUID: Guid;
        RoundingPrecision: Decimal;
        Diff: Decimal;
        MaxRoundingDiffPossible: Decimal;
        i: Integer;
        ResidualValueType: Option "No Residual",Balloon,"Separate Payment","Stays Unpaid";

        StartingLine: Record "S4LA Schedule Line"; //the last invoiced line (may be line zero for new sched)
        LineOfReschedParams: Record "S4LA Schedule Line"; //the next non-invoiced installment line, to pass rescheduling params from reshed functions

        Line: Record "S4LA Schedule Line";
        PrevLine: Record "S4LA Schedule Line";
        SavedInstTEMP: Record "S4LA Schedule Line" temporary;

        InterestVAT: Decimal;
        PrincipalVAT: Decimal;
        ResidualVAT: Decimal;
        ResidualValue: Decimal;
        InstallmentDay: Integer;

        AccumulatedAssetVariationAmount: Decimal;

        ImpactOfPrincipalChange: Decimal;
        ImpactOfInterestChange: Decimal;
        ImpactOfAssetVariation: Decimal;
        OpeningCapitalInclReshedImpacts: Decimal;

        IsAdvance: Integer;
        IsArrears: Integer;

        NoOfInterestPeriodsFromStart: Decimal;
        PVofKnownInst: Decimal;
        PVofUnknownInst: Decimal;
        PVofUnguaranteedRV: Decimal;
        ToBePVofUnknownInst: Decimal;
        RegularPMTamt: Decimal;
        UnguaranteedRVamt: Decimal;
        EndingDateFormula: Text[20];
        IRRrate: Decimal;
        InterestBase: Decimal;
        IsInsert: Boolean;
        IsTheFirstLineToCalc: Boolean;

        SavedInstTEMPFound: Boolean;
        StopCalculation: Boolean;
        //SOLV-1438 >>>
        AddProrataPeriod: Integer;
        ProrataDays: Integer;
        DaysInFullPeriod: Integer;
        ProRataFromDate: date;
        ProRataToDate: date;
        FirstLine: Record "S4LA Schedule Line";
        AfterFirstLine: Record "S4LA Schedule Line";
        LastLine: Record "S4LA Schedule Line";
        BeforeLastLine: Record "S4LA Schedule Line";
        ProRataProportionFirstPeriod: Decimal;
        ProRataProportionLastPeriod: Decimal;
        //SOLV-1438 <<<
        InterestBeforeStarting: Decimal;
    begin
        OnBeforeCalcSchedule(Schedule);

        //-------------------------------- Schedule status must be "New", unless variable interest recalc run
        if Schedule."Version status" <> Schedule."Version status"::New then
            if not VarInterestChangeRecalculation then
                Error(ScheduleVersionStatusError,
                    Schedule.FieldCaption("Version status"), Format(Schedule."Version status", 0), Schedule.FieldCaption("Version status"), Format(Schedule."Version status"::New, 0), Schedule.FieldCaption("Contract No."), Schedule."Contract No.",
                    Schedule.FieldCaption("Schedule No."), Schedule."Schedule No.", Schedule.FieldCaption("Version No."), Schedule."Version No.");

        //-------------------------------- Get setup
        LeasingSetup.Get();
        GLSetup.Get;
        if Currency.Get(Schedule."Currency Code")
        then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GLSetup."Amount Rounding Precision";

        if not InstallmentFrequency.Get(Schedule.Frequency) then
            exit;

        Contr.Get(Schedule."Contract No.");
        FinProd.Get(Schedule."Financial Product");

        CalculationGUID := CreateGuid();

        //---------------------------------------------- This codeunit only can run in the following context:
        FinProd.TestField("Soft4 Edition", FinProd."Soft4 Edition"::"UK (TValue compatible)");

        //---------------------------------------------- Get VAT rates
        // SOLV-1218 >>
        if FinProd."Interest Recognition Method" = FinProd."Interest Recognition Method"::"End of Month" then
            LeasingContrMngt.GetVatPercentInstalment(Schedule, PrincipalVAT)
        else
            // SOLV-1218 <<
            LeasingContrMngt.GetVatPercentsSchedule2(Schedule, PrincipalVAT, InterestVAT);
        ResidualVAT := PrincipalVAT;

        //SOLV-1438 >>>
        if FinProd."Prorated Schedule" then
            Schedule.testfield("Number of Extra Adv. Payments", 0);
        //SOLV-1438 <<<

        //---------------------------------------------- Advance/arrears multipliers, used in formulas
        if (Schedule."Installments Due" = Schedule."Installments Due"::"In Advance") or
           (Schedule."Number of Extra Adv. Payments" <> 0)
        then begin
            IsAdvance := 1;
            IsArrears := 0;
        end else begin
            IsAdvance := 0;
            IsArrears := 1;
        end;

        //---------------------------------------------- Find Residual Value
        if Schedule."Amounts Including VAT" then
            ResidualValue := Round(Schedule."Residual Value" / (1 + ResidualVAT), RoundingPrecision)
        else
            ResidualValue := Schedule."Residual Value";

        //---------------------------------------------- Set Residual Value type
        if Schedule."Residual Value" = 0 then
            ResidualValueType := ResidualValueType::"No Residual"
        else begin
            if Schedule."Residual Value Type" = Schedule."Residual Value Type"::Balloon then
                ResidualValueType := ResidualValueType::Balloon;
            if Schedule."Residual Value Type" = Schedule."Residual Value Type"::"Separate Payment" then
                ResidualValueType := ResidualValueType::"Separate Payment";
            if Schedule."Residual Value Type" = Schedule."Residual Value Type"::"Stays Unpaid" then
                ResidualValueType := ResidualValueType::"Stays Unpaid";
        end;

        //---------------------------------------------- Set Unguranteed Residual Value
        if ResidualValueType = ResidualValueType::"Stays Unpaid" then
            UnguaranteedRVamt := ResidualValue
        else
            UnguaranteedRVamt := 0;

        //--------------------------------- Save first non-invoiced line, which has resheduling parameters populated from Reched functions (e.g. "Principal Change" and may have more as extention)
        LineOfReschedParams.Reset();
        LineOfReschedParams.SetRange("Contract No.", Schedule."Contract No.");
        LineOfReschedParams.SetRange("Schedule No.", Schedule."Schedule No.");
        LineOfReschedParams.SetRange("Version No.", Schedule."Version No.");
        LineOfReschedParams.SetRange(Invoiced, false);
        LineOfReschedParams.SetRange("Entry Type", Line."Entry Type"::Installment);
        if not LineOfReschedParams.FindFirst() then
            Clear(LineOfReschedParams);

        //--------------------------------- Save fixed installments
        SavedInstTEMP.Reset();
        SavedInstTEMP.DeleteAll();
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetRange(Invoiced, false);
        Line.SetRange("Entry Type", Line."Entry Type"::Installment); //can not save any RV or Balloon lines. Those must match with Schedule rec
        Line.SetRange("Installment Not Recalculated", true);
        if Line.FindSet() then
            repeat
                SavedInstTEMP := Line;
                SavedInstTEMP.Insert();
            until Line.Next() = 0;
        Line.SetRange("Installment Not Recalculated", false);
        Line.SetRange("Date Not Recalc.", true);
        if Line.FindSet() then
            repeat
                SavedInstTEMP := Line;
                SavedInstTEMP.Insert();
            until Line.Next() = 0;

        //--------------------------------- Get Installment Day
        if Schedule."Starting Date" = 0D then
            Schedule.FieldError("Starting Date");
        InstallmentDay := Date2DMY(Schedule."Starting Date", 1);

        //SOLV-1438 >>> ----------------- prorated Schedule

        //--- get regular installment day (not relative to Starting Date)
        if FinProd."Prorated Schedule" then
            InstallmentDay := GetRegularInstallmentDay(Schedule, Schedule."Starting Date");

        //--- get ending date (in prorated schedule, lease runs for number of periods from Starting date. Ending date is relative to Starting date, NOT to the last installment date)
        if FinProd."Prorated Schedule" then begin
            EndingDateFormula := '<' + Format(Schedule."Term (months)") + 'M-1D>';
            Schedule."Ending Date" := CalcDate(EndingDateFormula, Schedule."Starting Date");
        end;

        //--- get additional payment period (Protared sched will have one more period, e.g. 12 month lease  will have 13 installments, where first and last installment are part-month)
        AddProrataPeriod := 0;
        if FinProd."Prorated Schedule" then begin
            //--detect if will have or had pro-rata at start (then, will have additional period at the end as well
            ProRataFromDate := Schedule."Starting Date";
            ProrataToDate := CalcSecondPaymentDate(Schedule."Starting Date", InstallmentDay, InstallmentFrequency);
            if (ProRataFromDate <> 0D) and (ProrataToDate <> 0D) and (ProRataFromDate < ProrataToDate) and (Schedule."Installments Per Year" <> 0) then begin
                ProrataDays := S4LCommon.Days360(ProRataFromDate + 1, ProrataToDate + 1);
                DaysInFullPeriod := 360 / Schedule."Installments Per Year";
                if ProrataDays < DaysInFullPeriod then
                    AddProrataPeriod := 1;
            end;
            //-- in some case will not have aaditional period at the end
            if (Schedule."Installments Due" = Schedule."Installments Due"::"In Arrears") then
                if date2DMY(Schedule."Ending Date", 1) = InstallmentDay then
                    AddProrataPeriod := 0;
        end;
        //SOLV-1438 <<<

        if InstallmentFrequency."Frequency Base Unit" = InstallmentFrequency."Frequency Base Unit"::Week then
            InstallmentDay := 0;
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetRange(Period, 1, PeriodNo + 1);   //SK201106 to capture new payment date on reschedule
        Line.SetRange("Date Not Recalc.", true);
        if Line.FindLast() then
            InstallmentDay := Date2DMY(Line.Date, 1);

        OnAfterSetInstallmentDay_CalcSchedule(Schedule, InstallmentDay, PeriodNo);

        //---------------------------------  Get Starting line, which is the "0" line for new shedule, or the last invoiced line
        StartingLine.Reset();
        StartingLine.SetRange("Contract No.", Schedule."Contract No.");
        StartingLine.SetRange("Schedule No.", Schedule."Schedule No.");
        StartingLine.SetRange("Version No.", Schedule."Version No.");
        StartingLine.SetRange(Invoiced, true);
        if not StartingLine.FindLast() then begin
            StartingLine.SetRange(Invoiced);
            if not StartingLine.FindFirst() then begin
                StartingLine.Init();
                StartingLine.Insert(); //should never hit this, the "0" line will always exist
            end;
        end;

        //--------------------------------- Set starting outstanding from beginning
        if StartingLine.Period = 0 then
            if Contr.Status in [Contr.Status::Application, Contr.Status::Quote, Contr.Status::"Withdrawn Application"] then begin     //SK201019 fiannced amount can be changed because of asset variation
                StartingLine."Outstanding Amount" := Schedule.TotalFinancedAmountExVAT();
                StartingLine."Outstanding Incl. VAT" := Round(StartingLine."Outstanding Amount" * (1 + PrincipalVAT), RoundingPrecision);
                StartingLine."Closing Outstanding" := StartingLine."Outstanding Amount";
                StartingLine."Closing Outstanding Incl. VAT" := StartingLine."Outstanding Incl. VAT";
                StartingLine.Modify();
            end;
        //--------------------------------- Set starting outstanding for contracts calculated with "Worlwide" option and changed to "TValue". As worldwide did not calulate closing outstanding
        if StartingLine.Period = 0 then begin
            StartingLine."Outstanding Amount" := Schedule.TotalFinancedAmountExVAT();
            StartingLine."Outstanding Incl. VAT" := Round(StartingLine."Outstanding Amount" * (1 + PrincipalVAT), RoundingPrecision);
            StartingLine.Modify();
        end;
        if StartingLine."Closing Outstanding" = 0 then begin
            StartingLine."Closing Outstanding" := StartingLine."Outstanding Amount" + StartingLine."Principal Amount"; //principal is negative
            StartingLine."Closing Outstanding Incl. VAT" := StartingLine."Outstanding Incl. VAT" + StartingLine."Principal Incl. VAT";
            StartingLine.Modify();
        end;

        //--------------------------------- Find Asset Variation Amount
        if Contr."Asset Variation Started" and (Schedule."Version status" = Schedule."Version status"::New) then begin
            Line.Reset();
            Line.SetRange("Contract No.", Schedule."Contract No.");
            Line.SetRange("Schedule No.", Schedule."Schedule No.");
            Line.SetRange("Version No.", Schedule."Version No.");
            Line.SetFilter("Entry Type", '<>%1', Line."Entry Type"::" ");
            Line.SetRange(Invoiced, true);
            AccumulatedAssetVariationAmount := 0;
            if Line.FindSet() then
                repeat
                    AccumulatedAssetVariationAmount += Line."Asset Value Variation";
                until Line.Next() = 0;
            LineOfReschedParams."Asset Value Variation" := (Schedule."Total Asset Price Var. Amount" - AccumulatedAssetVariationAmount);

            CalcVariationProportion(Contr, Schedule, StartingLine, LineOfReschedParams);
            LineOfReschedParams."Effective Date of Asset Var" := WorkDate();
            if Schedule."Installments Due" = Schedule."Installments Due"::"In Advance" then
                LineOfReschedParams."Effective Date of Asset Var" := StartingLine.Date;
            if (LineOfReschedParams."Effective Date of Asset Var" < StartingLine.Date) or (LineOfReschedParams."Effective Date of Asset Var" > LineOfReschedParams.Date) then
                Error(ErrEffectiveDate, LineOfReschedParams.FieldCaption("Effective Date of Asset Var"), LineOfReschedParams."Effective Date of Asset Var", StartingLine.Date, LineOfReschedParams.Date);
        end;

        //=============================================================  Loop 1 - insert Lines with Due Dates
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetRange(Period, PeriodNo);
        Line.FindFirst();
        Line.SetRange(Period);
        PrevLine := StartingLine;
        for i := StartingLine.Period + 1 to Schedule."Number Of Payment Periods" + AddProrataPeriod do begin //SOLV-1438 AddProrataPeriod

            if Line.Next() = 0 then begin
                Line.Init();
                Line."Contract No." := Schedule."Contract No.";
                Line."Schedule No." := Schedule."Schedule No.";
                Line."Version No." := Schedule."Version No.";
                Line.Period := i;
                //Line."Line No." := 10000 + Line.Period * 1000;
                Line."Line No." := PrevLine."Line No." + 1000;
                IsInsert := true
            end;
            Line."Fin. Product Code" := Schedule."Financial Product"; //SOLV-644
            Line.Period := i;
            Line."Entry Type" := Line."Entry Type"::Installment;
            Line."Calculation GUID" := CalculationGUID;

            //--------------------------------- Set installment date
            if i = 1 then begin
                if not Line."Date Not Recalc." then
                    if Schedule."Installments Due" = Schedule."Installments Due"::"In Advance" then
                        Line.Date := Schedule."Starting Date"
                    else
                        if Schedule."Number of Extra Adv. Payments" <> 0 then
                            Line.Date := Schedule."Starting Date"
                        else
                            Line.Date := CalcNextPaymentDate(Schedule."Starting Date", InstallmentDay, InstallmentFrequency);
            end else begin
                if not Line."Date Not Recalc." then
                    Line.Date := CalcNextPaymentDate(PrevLine.Date, InstallmentDay, InstallmentFrequency)
                else
                    InstallmentDay := Date2DMY(Line.Date, 1);
                if InstallmentFrequency."Frequency Base Unit" = InstallmentFrequency."Frequency Base Unit"::Week then
                    InstallmentDay := 0;
            end;

            //SOLV-1438 >>>
            //--------- Prorated schedule cases (NOTE: in Prorated schedule user can not override first and second installment dates)
            if FinProd."Prorated Schedule" then begin
                case true of

                    //---- First installment, InAdvance
                    (Line.Period = 1) and (Schedule."Installments Due" = Schedule."Installments Due"::"In Advance"):
                        begin
                            Line.Date := Schedule."Starting Date";
                            Line."Date Not Recalc." := false;
                        end;

                    //---- First installment, InArrears
                    (Line.Period = 1) and (Schedule."Installments Due" = Schedule."Installments Due"::"In Arrears"):
                        begin
                            Line.Date := CalcSecondPaymentDate(Schedule."Starting Date", InstallmentDay, InstallmentFrequency); //i.e. one period after Starting Date, adjusted to Installment Day
                            Line."Date Not Recalc." := false;
                        end;

                    //---- Second installment, all cases
                    (Line.Period = 2):
                        begin
                            Line.Date := CalcSecondPaymentDate(PrevLine.Date, InstallmentDay, InstallmentFrequency);
                            Line."Date Not Recalc." := false;
                        end;

                    //---- Last installment, InArrears
                    (Line.Period = Schedule."Number Of Payment Periods" + AddProrataPeriod) and (Schedule."Installments Due" = Schedule."Installments Due"::"In Arrears"):
                        begin
                            Line.Date := Schedule."Ending Date";
                            Line."Date Not Recalc." := false;
                        end;

                    //---- All other installments
                    else begin
                        if Line."Date Not Recalc." then
                            //respect manual input, do not change Line.Date, only pick new Installment day.
                            InstallmentDay := Date2DMY(Line.Date, 1)
                        else
                            Line.Date := CalcNextPaymentDate(PrevLine.Date, InstallmentDay, InstallmentFrequency);
                    end;
                end;
            end;
            //SOLV-1438 <<<

            OnAfterSetInstallmentDate_CalcSchedule(Schedule, Line, PrevLine, i);

            //--------------------------------- Set Installment Multiplier (in field "Total Installment")
            // "Total Installment" here indicates "number of regular installments in this line", usually 1
            // ... but can be 2 or 0, in case of multiple installments charged upfront (UK style)
            Line."Installment Not Recalculated" := false; //indication of "Unknown" instalment. Will be calculated.
            Line."Total Installment" := -1; //used in PV of "Unknown" instalments

            //--- Add number of multiple advance payments (but do not override saved fixed installment)
            if (i = 1) then
                Line."Total Installment" -= Schedule."Number of Extra Adv. Payments";

            //--- terminal pause
            if (Schedule."Number of Extra Adv. Payments" <> 0) and
                (Schedule."Profile Type" = Schedule."Profile Type"::"Terminal Pause") and
                (i > Schedule."Number Of Payment Periods" - Schedule."Number of Extra Adv. Payments")
            then
                Line."Total Installment" := 0;
            Line."Installment Not Recalculated" := false;

            //--------------------------------- Set "Known" installments
            SavedInstTEMP.Reset();
            SavedInstTEMP.SetRange(Period, Line.Period);
            if SavedInstTEMP.FindFirst() then begin
                SavedInstTEMPFound := true;
                if SavedInstTEMP."Installment Not Recalculated" then begin
                    // Schedule Calc will use rate "interest rate" * (1+ Schedule."Stamp Tax % (Interest)"), so forced "Total Installment" must be incl stamp on interest.
                    Line."Total Installment" := SavedInstTEMP."Total Installment"; //+ SavedInstTEMP."Stamp Tax Amount (Interest)";
                    Line."Installment Not Recalculated" := true; //indication of "known" installment
                end;
                if SavedInstTEMP."Date Not Recalc." then
                    if SavedInstTEMP.Date >= PrevLine.Date then begin //can not freeze the date, if backdated before prev instalment. Must respect date order
                        Line.Date := SavedInstTEMP.Date;
                        Line."Date Not Recalc." := true;
                    end;
            end;

            OnBeforeLineInsertOrModify_CalcSchedule(Schedule, Line, PeriodNo, i, PrevLine, SavedInstTEMP, SavedInstTEMPFound);

            if IsInsert then
                Line.Insert()
            else
                Line.Modify();
            IsInsert := false;

            PrevLine := Line;
        end;
        //---end Loop 1 - insert Lines and Due Dates

        //--- delete lines not used in this calculation (e.g. lines after ending date)
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetRange(Invoiced, false);
        Line.SetFilter("Calculation GUID", '<>%1', CalculationGUID);
        Line.DeleteAll();

        //============================================================= Prepare Residual Value

        //---------------------------------------------- Calculate Schedule Ending Date
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.FindLast(); //will aways exist
        Schedule."Ending Date" := Line."Date";
        //>> (this code copied from ContractMgt codeunit)
        //Schedule."Ending Date" := Schedule."Last Payment Date";
        if Schedule."Installments Due" = Schedule."Installments Due"::"In Advance" then begin
            if Schedule."Installments Per Year" > 12 then
                EndingDateFormula := '<' + Format(52 / Schedule."Installments Per Year") + 'W-1D>'
            else
                EndingDateFormula := '<' + Format(12 / Schedule."Installments Per Year") + 'M-1D>';
            if Schedule."Ending Date" <> 0D then
                Schedule."Ending Date" := CalcDate(EndingDateFormula, Schedule."Ending Date");
        end;
        //<<

        //SOLV-1438 >>>
        // in prorated schedule, lease runs for number of periods from Starting date. Ending date is relative to Starting date, NOT to the last installment date
        if FinProd."Prorated Schedule" then begin
            EndingDateFormula := '<' + Format(Schedule."Term (months)") + 'M-1D>';
            Schedule."Ending Date" := CalcDate(EndingDateFormula, Schedule."Starting Date");
        end;
        //SOLV-1438 <<<

        Schedule.Modify();
        OnAfterCalcEndingDate_CalcSchedule(Schedule);

        //----------------------------------------------- Insert Residual Value as Separate Payment
        if ResidualValueType = ResidualValueType::"Separate Payment" then begin
            Line.Init();
            Line."Contract No." := Schedule."Contract No.";
            Line."Schedule No." := Schedule."Schedule No.";
            Line."Version No." := Schedule."Version No.";
            Line.Period := Schedule."Number Of Payment Periods" + IsAdvance; //if advance, RV due on next period after the last regular payment
                                                                             // in arrears, last instalment and RV will be in the same period
                                                                             // in advance, RV will be one period after the last instalment
            Line."Line No." := 10000 + Line.Period * 1000 + 1; //when in arrears, last instalment and RV will be in the same period
            Line.Date := Schedule."Ending Date";
            Line."Fin. Product Code" := Schedule."Financial Product"; //SOLV-664
            Line."Entry Type" := Line."Entry Type"::"Residual Value";
            Line."Interest Rate" := Schedule."Interest Rate" * (1 + Schedule."Stamp Tax % (Interest)" / 100);
            Line."Calculation GUID" := CalculationGUID;
            Line."Installment Not Recalculated" := true; //Freeze for this caclulation only. Amount must match with Schedule Rec
            Line."Date Not Recalc." := true;
            Line."Total Installment" := -ResidualValue;
            Line."Installment Incl. VAT" := -Round(ResidualValue * (1 + ResidualVAT), RoundingPrecision);
            Line.Insert();
        end;

        //----------------------------------------------- Residual as Balloon payment (update on the last installment)
        if ResidualValueType = ResidualValueType::Balloon then begin
            Line.Reset();
            Line.SetRange("Contract No.", Schedule."Contract No.");
            Line.SetRange("Schedule No.", Schedule."Schedule No.");
            Line.SetRange("Version No.", Schedule."Version No.");
            Line.FindLast(); //will aways exist
            Line."Entry Type" := Line."Entry Type"::Balloon;
            Line."Installment Not Recalculated" := true; //Freeze for this caclulation only. Amount must match with Schedule Rec
            Line."Date Not Recalc." := true;
            Line."Total Installment" := -ResidualValue;
            Line."Installment Incl. VAT" := -Round(ResidualValue * (1 + ResidualVAT), RoundingPrecision);
            Line.Modify();
        end;

        OnBeforeCalculateRegularInstallment_CalcSchedule(Schedule, PeriodNo);


        //==================================== Prorated schedule, calc prorata PROPORTIONS first/last installment  //SOLV-1438 >>>
        ProRataProportionFirstPeriod := 1;
        ProRataProportionLastPeriod := 1;
        if FinProd."Prorated Schedule" then begin
            //--- having key Dates :
            // [a] StartingLine.date    - the last invoiced line. In New schedule this is line #zero, date will equal to Schedule."Starting Date".
            // [b] FirstLine.date       - first line newly calculated
            // [c] AfterFirstLine.date  - the next after [b]
            // [d] BeforeLastLine.date  - line before [e]
            // [e] LastLine.date        - the last installment (not including residual as separate payment)
            // [f] Schedule."Ending Date" - lease end date, relative to Schedule."Starting Date" i.e. Starting date + 24 months MINUS ONE DAY. NOT relative to installment dates.

            //InArrears, Prorata days at the begining = from [a] to [b]
            //InAdvance, Prorata days at the begining = from [b] to [c]
            //InArrears, Prorata days at the end = from [d] to [e]
            //InAdvance, Prorata days at the end = from [e] to [f]+1

            //--- get records
            //StartingLine already have

            FirstLine.Reset();
            FirstLine.SetRange("Contract No.", Schedule."Contract No.");
            FirstLine.SetRange("Schedule No.", Schedule."Schedule No.");
            FirstLine.SetRange("Version No.", Schedule."Version No.");
            FirstLine.SetRange("Entry Type", FirstLine."Entry Type"::Installment);
            FirstLine.SetRange(invoiced, false);
            if not FirstLine.FindFirst() then
                clear(FirstLine);

            AfterFirstLine := FirstLine;
            if AfterFirstLine.next = 0 then
                clear(AfterFirstLine);

            LastLine.Reset();
            LastLine.SetRange("Contract No.", Schedule."Contract No.");
            LastLine.SetRange("Schedule No.", Schedule."Schedule No.");
            LastLine.SetRange("Version No.", Schedule."Version No.");
            LastLine.SetRange("Entry Type", LastLine."Entry Type"::Installment);
            LastLine.SetRange(invoiced, false);
            if not LastLine.FindLast() then
                clear(FirstLine);

            BeforeLastLine := LastLine;
            if BeforeLastLine.next(-1) = 0 then
                clear(BeforeLastLine);

            //--- calc prorata at the begining
            if Schedule."Installments Due" = Schedule."Installments Due"::"In Arrears" then begin
                ProRataFromDate := StartingLine.date;
                ProrataToDate := FirstLine.date;
            end else begin
                ProRataFromDate := FirstLine.date;
                ProrataToDate := AfterFirstLine.date;
            end;
            if (ProRataFromDate <> 0D) and (ProrataToDate <> 0D) and (ProRataFromDate < ProrataToDate) and (Schedule."Installments Per Year" <> 0) then begin
                //always 30/360 method, regardless of how interest calculates.
                ProrataDays := S4LCommon.Days360(ProRataFromDate + 1, ProrataToDate + 1);
                DaysInFullPeriod := 360 / Schedule."Installments Per Year";
                ProRataProportionFirstPeriod := ProrataDays / DaysInFullPeriod;
            end;

            //--- calc prorata at the end - In Arrears
            if (Schedule."Installments Due" = Schedule."Installments Due"::"In Arrears") and
               (LastLine.Period = Schedule."Number Of Payment Periods" + 1) // has added prorata period at the end
            then begin
                ProRataFromDate := BeforeLastLine.date;
                ProrataToDate := LastLine.date;
                if (ProRataFromDate <> 0D) and (ProrataToDate <> 0D) and (ProRataFromDate < ProrataToDate) and (Schedule."Installments Per Year" <> 0) then begin
                    //always 30/360 method, regardless of how interest calculates.
                    ProrataDays := S4LCommon.Days360(ProRataFromDate + 1, ProrataToDate + 1);
                    DaysInFullPeriod := 360 / Schedule."Installments Per Year";
                    ProRataProportionLastPeriod := ProrataDays / DaysInFullPeriod; // variable also used in discounting residual value, below
                end;
            end;

            //--- calc prorata at the end - In Advance
            if Schedule."Installments Due" = Schedule."Installments Due"::"In Advance" then begin
                ProRataFromDate := LastLine.date;
                ProrataToDate := Schedule."Ending Date" + 1;
                if (ProRataFromDate <> 0D) and (ProrataToDate <> 0D) and (ProRataFromDate < ProrataToDate) and (Schedule."Installments Per Year" <> 0) then begin
                    //always 30/360 method, regardless of how interest calculates.
                    ProrataDays := S4LCommon.Days360(ProRataFromDate + 1, ProrataToDate + 1);
                    DaysInFullPeriod := 360 / Schedule."Installments Per Year";
                    ProRataProportionLastPeriod := ProrataDays / DaysInFullPeriod; // variable also used in discounting residual value, below
                end;
            end;

            //---- Apply proportion to first/last installments
            if ProRataProportionFirstPeriod <> 1 then begin
                Line.Reset();
                Line.SetRange("Contract No.", Schedule."Contract No.");
                Line.SetRange("Schedule No.", Schedule."Schedule No.");
                Line.SetRange("Version No.", Schedule."Version No.");
                Line.SetRange(Invoiced, false);
                Line.SetRange(Period, 1);
                if Line.FindFirst() then begin
                    Line."Total Installment" := Line."Total Installment" * ProRataProportionFirstPeriod;
                    Line.Modify();
                end;
            end;
            if ProRataProportionLastPeriod <> 1 then begin
                Line.Reset();
                Line.SetRange("Contract No.", Schedule."Contract No.");
                Line.SetRange("Schedule No.", Schedule."Schedule No.");
                Line.SetRange("Version No.", Schedule."Version No.");
                Line.SetRange(Invoiced, false);
                Line.SetRange(Period, Schedule."Number Of Payment Periods" + AddProrataPeriod);
                if Line.FindLast() then begin
                    Line."Total Installment" := Line."Total Installment" * ProRataProportionLastPeriod;
                    Line.Modify();
                end;
            end;

        end;
        //SOLV-1438 <<<

        //==================================== Calculate regular instalment amount

        //--------- Step1: Calc PV of "known" installments (incl. guaranteed residual or balloon)

        ratePerPeriod := (Schedule."Interest Rate" / Schedule."Installments Per Year" / 100) * (1 + Schedule."Stamp Tax % (Interest)" / 100);
        OnAfterSetRatePerPeriod_CalcSchedule(Schedule, ratePerPeriod, PeriodNo);

        PVofKnownInst := 0;
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetRange(Invoiced, false);
        Line.SetRange("Installment Not Recalculated", true);
        if Line.FindSet() then
            repeat
                //  ratePerPeriod := (Schedule."Interest Rate" / Schedule."Installments Per Year" / 100) * (1 + Schedule."Stamp Tax % (Interest)" / 100);
                if (IsAdvance = 1) and (StartingLine.Period = 0) then
                    NoOfInterestPeriodsFromStart := Line.Period - StartingLine.Period - IsAdvance // starts with 0, but only if advance calc from beginning...
                else
                    NoOfInterestPeriodsFromStart := Line.Period - StartingLine.Period;  //...calculation from mid-schedule is same for advance and arrears
                PVofKnownInst += -Line."Total Installment" / Power((1 + ratePerPeriod), NoOfInterestPeriodsFromStart);
            until Line.Next() = 0;

        //--------- Step2: Calc PV of "unknown" installments (has PMT=1)
        PVofUnknownInst := 0;
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetRange(Invoiced, false);
        Line.SetRange("Installment Not Recalculated", false);
        if Line.FindSet() then
            repeat
                //  ratePerPeriod := (Schedule."Interest Rate" / Schedule."Installments Per Year" / 100) * (1 + Schedule."Stamp Tax % (Interest)" / 100);
                if (IsAdvance = 1) and (StartingLine.Period = 0) then
                    NoOfInterestPeriodsFromStart := Line.Period - StartingLine.Period - IsAdvance // starts with 0, but only if advance calc from beginning...
                else
                    NoOfInterestPeriodsFromStart := Line.Period - StartingLine.Period;  //...calculation from mid-schedule is same for advance and arrears

                PVofUnknownInst += -Line."Total Installment" / Power((1 + ratePerPeriod), NoOfInterestPeriodsFromStart);
            until Line.Next() = 0;

        //--------- Step3: Solve for "unknown" installment amt
        //--- Step3a: calc PV of Unguaranteed Residual
        PVofUnguaranteedRV := 0;
        // ratePerPeriod := (Schedule."Interest Rate" / Schedule."Installments Per Year" / 100) * (1 + Schedule."Stamp Tax % (Interest)" / 100);
        //SOLV-884 >>>
        //if (IsAdvance = 1) and (StartingLine.Period = 0) then
        //    NoOfInterestPeriodsFromStart := Line.Period - StartingLine.Period - IsAdvance // starts with 0, but only if advance calc from beginning...
        //else
        //    NoOfInterestPeriodsFromStart := Line.Period - StartingLine.Period;  //...calculation from mid-schedule is same for advance and arrears
        NoOfInterestPeriodsFromStart := Line.Period - StartingLine.Period;  //SOLV-884, RV always in arrears
                                                                            //SOLV-884<<<
        if (IsAdvance = 1) and (StartingLine.Period = 0) and (Schedule."Residual Value Type" = Schedule."Residual Value Type"::"Stays Unpaid") then
            NoOfInterestPeriodsFromStart := NoOfInterestPeriodsFromStart - 1;

        PVofUnguaranteedRV := UnguaranteedRVamt / Power((1 + ratePerPeriod), NoOfInterestPeriodsFromStart);

        //--- Step3b: Calculate impact of mid-period resheduling
        //nominal values, as if changes effective from start of current period (as it is in "Worlwide" Soft4 edition)
        ImpactOfPrincipalChange := LineOfReschedParams."Principal Change"; //Principal change is effective at the start of current period, so impact is at nominal value
        ImpactOfInterestChange := 0; //Interest rate change is effective at the beginning of current period (new rate applies for all next installments)
        ImpactOfAssetVariation := LineOfReschedParams."Asset Value Variation"; //Principal change is effective at the start of current period
                                                                               //Posiblity to calculate impacts AS IF EFFECTIVE FROM MID-PERIOD (only applicable if InArrears)
                                                                               //Limitation: can have just one interest change, principal change, asset variation in mid-period (between two installments). Multiple variations shall combine into single effective date.
        IsHandled := false;
        OnBeforeCalcReschedImpactVariables_CalcSchedule(IsHandled, Schedule, StartingLine, LineOfReschedParams, ImpactOfPrincipalChange, ImpactOfInterestChange, ImpactOfAssetVariation);
        if not IsHandled then
            CalcReschedImpactVariables(Schedule, StartingLine, LineOfReschedParams, ImpactOfPrincipalChange, ImpactOfInterestChange, ImpactOfAssetVariation);


        if StartingLine.Period = 0 then
            InterestBeforeStarting := GetInterestBeforeStarting(Schedule);

        //--- Step3c: Opening capital, plus all resheduling impacts AS IF EFFECTIVE FROM PERIOD START. The same variable to be used in IRR calc
        OpeningCapitalInclReshedImpacts := StartingLine."Closing Outstanding"
                                          + ImpactOfPrincipalChange
                                          + ImpactOfInterestChange
                                          + ImpactOfAssetVariation
                                          + InterestBeforeStarting;

        //--- Step3d: PV of "unknown" installments shall cover opening capital less amout already covered by PV of known installments and PV of unguaranteed residual
        ToBePVofUnknownInst := OpeningCapitalInclReshedImpacts
                             - PVofKnownInst
                             - PVofUnguaranteedRV;

        //--- Step3e: PVofUnknownInst was calculated assuming PMT = 1, now having ToBePVofUnknownInst, divide to solve for PMT amount
        RegularPMTamt := 0;
        if PVofUnknownInst <> 0 then
            RegularPMTamt := ToBePVofUnknownInst / PVofUnknownInst;
        OnAfterCalcRegularInstallmentBeforeRounding_CalcSchedule(Schedule, StartingLine, RegularPMTamt);
        RegularPMTamt := Round(RegularPMTamt, RoundingPrecision);
        OnAfterCalcRegularInstallment_CalcSchedule(Schedule, StartingLine, RegularPMTamt);
        Schedule."Regular Installment" := RegularPMTamt;
        Schedule.Modify();

        //--------- Step4: Build the schedule
        //=============================================================  Loop2 - Set Instalment amounts
        Line.Reset();
        Line.SetRange("Contract No.", StartingLine."Contract No.");
        Line.SetRange("Schedule No.", StartingLine."Schedule No.");
        Line.SetRange("Version No.", StartingLine."Version No.");
        Line.SetRange(Invoiced, false);
        Line.SetRange("Installment Not Recalculated", false);
        if Line.FindSet() then
            repeat
                Line."Total Installment" :=
                            Line."Total Installment"  //multiplier from Loop 1. Normally "1", but can be 2 or 0 (as negative)
                            *
                            RegularPMTamt;            // calculated regular installment
                Line."Total Installment" := Round(Line."Total Installment", RoundingPrecision);
                Line.Modify();
            until Line.Next() = 0;
        //--- End Loop2 - Set Instalment amounts

        IsHandled := false;
        StopCalculation := false;
        OnBeforeCalcIRRRate_CalcSchedule(Schedule, IRRrate, OpeningCapitalInclReshedImpacts, StopCalculation, IsHandled);
        if StopCalculation then
            exit;
        if not IsHandled then
            //calc IRR and use it Loop2 for interest calc
            //IRRrate := ContractMgt.fnIRRSched_TValue(Schedule, OpeningCapitalInclReshedImpacts, ProRataProportionFirstPeriod, ProRataProportionLastPeriod);
            IRRrate := ContractMgt.fnIRRSched_TValue(Schedule, OpeningCapitalInclReshedImpacts);


        //=============================================================  Loop 3 - Calc Interest, Principal, Outstanding, Services
        //--== Get current existing line. It will always exist ==--
        Line.Reset();
        Line.SetRange("Contract No.", StartingLine."Contract No.");
        Line.SetRange("Schedule No.", StartingLine."Schedule No.");
        Line.SetRange("Version No.", StartingLine."Version No.");
        Line.SetRange(Invoiced, false);
        PrevLine := StartingLine;
        IsTheFirstLineToCalc := true;
        if Line.FindSet() then
            repeat

                OnBeforeCalcSchedLine_CalcSchedule(Schedule, Line);

                Line."Interest Rate" := IRRrate;

                //-----------------------------------------------------  Set Outstanding
                Line."Outstanding Amount" := PrevLine."Closing Outstanding";
                Line."Outstanding Incl. VAT" := PrevLine."Closing Outstanding Incl. VAT";

                //----------------------------------------------------- Pass rescheduling params
                if IsTheFirstLineToCalc then begin //first line this calculation, just once

                    //--- Set Principal Change
                    if LineOfReschedParams."Principal Change" <> 0 then
                        Line."Principal Change" := LineOfReschedParams."Principal Change";

                    //--- Set Asset Variation
                    //SOLV-664 >>
                    if LineOfReschedParams."Asset Value Variation" <> 0 then begin
                        Line.Validate("Asset Value Variation", LineOfReschedParams."Asset Value Variation");
                        Line.Validate("Effective Date of Asset Var", LineOfReschedParams."Effective Date of Asset Var");
                        Line.Validate("Asset Variation Factor", LineOfReschedParams."Asset Variation Factor");
                    end;
                    //SOLV-664 <<
                end;

                //-----------------------------------------------------  Set Interest
                ratePerPeriod := (IRRrate / Schedule."Installments Per Year" / 100);

                InterestBase := Line."Outstanding Amount"
                              + Line."Principal Change"
                              + Line."Asset Value Variation";

                if (Line.Period = 1) and (IsArrears = 1) then
                    InterestBase += InterestBeforeStarting;

                //--- if Advance, the first instalment has no interest
                if (IsAdvance = 1) and (Line.Period = 1) then
                    InterestBase := 0;

                //---- if arrears, then residual value is due on the same day with the last installment (but separate line) - has no interest
                if (Line."Entry Type" = Line."Entry Type"::"Residual Value") and (IsArrears = 1) then
                    InterestBase := 0;

                Line."Interest Amount" := -InterestBase * ratePerPeriod;

                if Line.Period = 1 then
                    Line."Interest Amount" -= InterestBeforeStarting;

                if IsTheFirstLineToCalc then begin //first line this calculation, just once
                                                   //Posiblity to calculate interest when change in interest rate and/or change in Principal IF EFFECTIVE FROM MID-PERIOD (only applicable if InArrears)
                                                   //Limitation: can have just one interest change, principal change, asset variation in mid-period (between two installments). Multiple variations shall combine into single effective date.
                    IsHandled := false;
                    OnBeforeCalcReschedInterest_CalcSchedule(IsHandled, Line, InterestBase, Schedule, StartingLine, LineOfReschedParams, ImpactOfPrincipalChange, ImpactOfInterestChange, ImpactOfAssetVariation);
                    if not IsHandled then
                        CalcReschedInterest(Line, InterestBase, Schedule, StartingLine, LineOfReschedParams, ImpactOfPrincipalChange, ImpactOfInterestChange, ImpactOfAssetVariation);
                end;

                Line."Interest Amount" := Round(Line."Interest Amount", RoundingPrecision);

                //-----------------------------------------------------  Set Principal (will get already rounded)
                //(if Stamp tax on ineterest applies - at this point TotalInstalment and Interest are inclusive of Stamp tax. But principal is already clean)
                Line."Principal Amount" := Line."Total Installment" - Line."Interest Amount"; //(all these amounts are negative)
                OnAfterPrincipalAmountCalculatedOnSchedLine_CalcSchedule(Schedule, Line);

                //-----------------------------------------------------  Set Installment Fee

                if Line."Entry Type" in [Line."Entry Type"::Installment, Line."Entry Type"::Inertia] then begin
                    if Schedule."Amounts Including VAT" then begin
                        Line."Installment Fees" := -Schedule."Installment Fee";
                        Line."Installment Fees Incl. VAT" := -Schedule."Installment Fee";
                    end else begin
                        Line."Installment Fees" := -Schedule."Installment Fee";
                        Line."Installment Fees Incl. VAT" := Round(-Schedule."Installment Fee" * (1 + PrincipalVAT), RoundingPrecision);
                    end;
                    Line."Stamp Tax Amount (Intsl. Fee)" := Round(Line."Installment Fees" * (1 + Schedule."Stamp Tax % (Fees)" / 100), RoundingPrecision) - Line."Installment Fees";
                end else begin
                    Line."Installment Fees" := 0;
                    Line."Installment Fees Incl. VAT" := 0;
                    Line."Stamp Tax Amount (Intsl. Fee)" := 0;
                end;

                if Line."Skip Installment Fee" then begin
                    Line."Installment Fees" := 0;
                    Line."Installment Fees Incl. VAT" := 0;
                    Line."Stamp Tax Amount (Intsl. Fee)" := 0;
                end;

                //----------------------------------------------------- Split Stamp Tax to separte column
                // Interest amount is incl. stamp tax.
                Line."Interest Incl. Stamp Tax." := Line."Interest Amount";
                Line."Stamp Tax Amount (Interest)" := Round(Line."Interest Incl. Stamp Tax." - (Line."Interest Incl. Stamp Tax." / (1 + Schedule."Stamp Tax % (Interest)" / 100)), RoundingPrecision);
                Line."Interest Amount" := Line."Interest Incl. Stamp Tax." - Line."Stamp Tax Amount (Interest)";
                //at this point have clean interest (ex stamp tax)
                OnAfterInterestAmountCalculatedOnSchedLine_CalcSchedule(Schedule, Line);
                //Line."Total Installment" := Line."Principal Amount" + Line."Interest Amount";

                //-----------------------------------------------------  Calc Closing Outstanding
                Line."Closing Outstanding" := Line."Outstanding Amount"
                                            + Line."Principal Amount" //principal is negative
                                            + Line."Principal Change"
                                            + Line."Asset Value Variation";

                //-----------------------------------------------------  Calc Amounts incl. VAT
                Line."Principal Incl. VAT" := Round(Line."Principal Amount" * (1 + PrincipalVAT), RoundingPrecision);
                Line."Installment Incl. VAT" := Round(Line."Total Installment" * (1 + PrincipalVAT), RoundingPrecision);
                Line."Outstanding Incl. VAT" := Round(Line."Outstanding Amount" * (1 + PrincipalVAT), RoundingPrecision);
                Line."Closing Outstanding Incl. VAT" := Round(Line."Closing Outstanding" * (1 + PrincipalVAT), RoundingPrecision);
                Line."Interest Incl. VAT" := Line."Installment Incl. VAT" - Line."Principal Incl. VAT" - Line."Stamp Tax Amount (Interest)";

                //----------------------------------------------------- cleanup "freeze" flag from RV and Balloon
                if Line."Entry Type" in [Line."Entry Type"::"Residual Value", Line."Entry Type"::Balloon] then begin
                    Line."Installment Not Recalculated" := false;
                    Line."Date Not Recalc." := false;
                end;

                OnAfterSchedLineCreatedBeforeModify_CalcSchedule(Schedule, Line);

                Line.Modify();
                PrevLine := Line;
                IsTheFirstLineToCalc := false;
            until Line.Next() = 0;
        //-- End Loop 3 - Calc Interest, Principal, Outstanding, Services

        //---- Create Schedule Line Details for Insurance and Services Amount
        IsHandled := false;
        OnBeforeCreateScheduleLineDetailsForInsurance_CalcSchedule(Schedule, StartingLine, IsHandled);
        if not IsHandled then
            CreateScheduleLineDetailsInsurance(Schedule, StartingLine);

        IsHandled := false;
        OnBeforeCreateScheduleLineDetailsForServices_CalcSchedule(Schedule, StartingLine, IsHandled);
        if not IsHandled then
            CreateScheduleLineDetailsForServices(Schedule, StartingLine);

        //====================================================  Handle rounding residual with the last instalment
        MaxRoundingDiffPossible := (RoundingPrecision * Schedule."Number Of Payment Periods") / 2;
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetRange(Invoiced, false);
        if Line.FindLast() then begin
            Diff := Line."Closing Outstanding" - UnguaranteedRVamt;
            if Abs(Diff) <= MaxRoundingDiffPossible then begin
                Line."Principal Amount" += -Diff;
                //if Line."Interest Amount" <> 0 then //KS210421 can not do that. must add to diff to interest and principal.
                Line."Interest Amount" -= -Diff;
                Line."Closing Outstanding" := UnguaranteedRVamt;
                Line.Modify();
            end;

            Diff := Line."Closing Outstanding Incl. VAT" - Round(UnguaranteedRVamt * (1 + ResidualVAT), RoundingPrecision);
            if Abs(Diff) <= MaxRoundingDiffPossible then begin
                Line."Principal Incl. VAT" += -Diff;
                //if Line."Interest Incl. VAT" <> 0 then
                Line."Interest Incl. VAT" -= -Diff;
                Line."Closing Outstanding Incl. VAT" := Round(UnguaranteedRVamt * (1 + ResidualVAT), RoundingPrecision);
                Line.Modify();
            end;
        end;

        OnAfter_CalcSchedule(Schedule);
    end;

    procedure SolveForHPVATwithInstallment(var Schedule: Record "S4LA Schedule"; PeriodNo: Integer) //SOLV-1438 HP VAT
    var
        Contr: Record "S4LA Contract";
        FinProd: Record "S4LA Financial Product";
        RoundingPrecision: Decimal;
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        HPVATSchedLine: Record "S4LA Schedule Line";
        SchedLine: Record "S4LA Schedule Line";
        VATPostSetup: Record "VAT Posting Setup";

        HPprincipalVATRate: Decimal;
        HPprincipalVATAmt: Decimal;
        HPInterestVATRate: Decimal;
        HPInterestVATAmt: Decimal;

        TotalInterest: Decimal;
        GuessSpecialInstallment: Decimal;
        PrevRegularInstalment: Decimal;
        MaxIteration: Integer;
        Iteration: Integer;

    begin
        // this function will make one installment special (Sched."HP VAT Period No.") - equal to Regular installment + VAT on principal + VAT on total interest (if applicable)
        // the schedule is already calculated regular way,
        // this function would solve for special installment and put VAT in period "HP VAT Period No."
        // iterative calculation, because of circular  - interest depends on regular installment, and regular instalment depends on special instalment, and  special instalment includes VAT on interest

        if not Contr.get(Schedule."Contract No.") then
            exit;
        if not FinProd.get(Contr."Financial Product") then
            exit;
        if FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::"Hire Purchase" then
            exit;
        //if FinProd."HP VAT Due With Installment" = false then
        //  exit;

        //if Schedule."HP VAT Period No." = 0 then
        //  Schedule."HP VAT Period No." := 1;

        //if PeriodNo >= Schedule."HP VAT Period No." then
        //  exit;

        //--- get "special installment line", where Purchase VAT and VAT on interest to be added
        HPVATSchedLine.Reset();
        HPVATSchedLine.SetRange("Contract No.", Schedule."Contract No.");
        HPVATSchedLine.SetRange("Schedule No.", Schedule."Schedule No.");
        HPVATSchedLine.SetRange("Version No.", Schedule."Version No.");
        //HPVATSchedLine.Setrange(Period, Schedule."HP VAT Period No.");
        if not HPVATSchedLine.findfirst then
            exit;

        //--- flush previous calculation of Special installment (and any other "freezed" instalments)
        SchedLine.Reset();
        SchedLine.SetRange("Contract No.", Schedule."Contract No.");
        SchedLine.SetRange("Schedule No.", Schedule."Schedule No.");
        SchedLine.SetRange("Version No.", Schedule."Version No.");
        SchedLine.SetRange(Invoiced, false);
        SchedLine.SetRange("Installment Not Recalculated", true);
        if not SchedLine.IsEmpty then begin
            SchedLine.modifyall("Installment Not Recalculated", false);
            CalcSchedule(Schedule, PeriodNo);
        end;

        //--- get VAT rates
        VATPostSetup.Reset;
        VATPostSetup.SetRange("VAT Bus. Posting Group", Contr."Customer VAT Bus. Group");
        //VATPostSetup.SetRange("VAT Prod. Posting Group", FinProd."HP Interest VAT Gr.");
        if VATPostSetup.FindFirst then
            HPInterestVATRate := VATPostSetup."VAT %" / 100;
        //VATPostSetup.SetRange("VAT Prod. Posting Group", FinProd."HP Principal VAT Gr.");
        if VATPostSetup.FindFirst then
            HPprincipalVATRate := VATPostSetup."VAT %" / 100;

        //--- Get purchase VAT amount
        FinProd.testfield("Amounts Including VAT", true);
        HPprincipalVATAmt := Schedule.TotalFinancedAmount() * (1 - 1 / (1 + HPprincipalVATRate));  //financed including VAT

        //--- Get rounding precision
        GLSetup.Get;
        if Currency.Get(Schedule."Currency Code")
        then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GLSetup."Amount Rounding Precision";

        //---- Iterate
        MaxIteration := 10;
        Iteration := 0;
        repeat
            //--- calculate "Guess" for special installment
            Schedule.calcfields(IPMT);
            TotalInterest := -Schedule.IPMT; //returns as negative
            HPInterestVATAmt := TotalInterest * HPInterestVATRate;
            GuessSpecialInstallment := Schedule."Regular Installment" + HPprincipalVATAmt + HPInterestVATAmt;
            GuessSpecialInstallment := round(GuessSpecialInstallment, RoundingPrecision);
            //--- apply the guess installment to specific line
            HPVATSchedLine.get(HPVATSchedLine."Contract No.", HPVATSchedLine."Schedule No.", HPVATSchedLine."Version No.", HPVATSchedLine."Line No.");
            HPVATSchedLine.fnUpdateInstallmentInclVAT(GuessSpecialInstallment, 0, false); //update "Incl VAT"=GuessSpecialInstallment, "Ex VAT"=regularInstalment (the difference is full VAT amount to be paid in ths installment)
            HPVATSchedLine.modify;
            PrevRegularInstalment := Schedule."Regular Installment";
            Iteration += 1;
            //--- re-calculate schedule with special installment in place (next guess depends new regular installment AND new total interest)
            CalcSchedule(Schedule, PeriodNo);
        until (abs(PrevRegularInstalment - Schedule."Regular Installment") <= RoundingPrecision) //until no more impact to regular installment
            OR
            (Iteration > MaxIteration);

    end;

    local procedure CalcReschedImpactVariables(Schedule: Record "S4LA Schedule";
                                                StartingLine: Record "S4LA Schedule Line";
                                                LineOfReschedParams: Record "S4LA Schedule Line";
                                                var ImpactOfPrincipalChange: Decimal;
                                                var ImpactOfInterestChange: Decimal;
                                                var ImpactOfAssetVariation: Decimal);
    //Adjust impact variables by number of days from period start to effective date of resheduling
    var
        LastInvoicedDueDate: Date;
        EffectiveDateOfResched: Date;
        NextNonInvoicedDueDate: Date;
        DaysInPeriod: Integer;
        DaysBeforeResched: Integer;
        DaysAfterResched: Integer;
        NewRatePerPeriod: Decimal;
        OldRatePerPeriod: Decimal;
        OpeningBalance: Decimal;

    begin
        //--- split-period reched only applies to "In arrears". If advance - current period already invoiced and any changes apply from start of next period - no split period.
        if Schedule."Installments Due" <> Schedule."Installments Due"::"In Arrears"
        then
            exit;

        //---Get current period start/end dates, calc days in period, silent exits if no clear period
        LastInvoicedDueDate := StartingLine.Date;
        NextNonInvoicedDueDate := LineOfReschedParams.Date;

        if (LastInvoicedDueDate = 0D) or
           (NextNonInvoicedDueDate = 0D)
        then
            exit;

        DaysInPeriod := S4LCommon.Days360(LastInvoicedDueDate, NextNonInvoicedDueDate);
        if DaysInPeriod <= 0 then
            exit;

        if (StartingLine.Period = 0) and (StartingLine."Interest Rate" = 0) then begin
            StartingLine."Interest Rate" := LineOfReschedParams."Interest Rate"; //SV210630 Variable interest update fix
            StartingLine.Modify();
        end;

        NewRatePerPeriod := (LineOfReschedParams."Interest Rate" / Schedule."Installments Per Year" / 100) * (1 + Schedule."Stamp Tax % (Interest)" / 100);
        OldRatePerPeriod := (StartingLine."Interest Rate" / Schedule."Installments Per Year" / 100) * (1 + Schedule."Stamp Tax % (Interest)" / 100);

        //-- impact of Principal change
        EffectiveDateOfResched := LineOfReschedParams."Effective Date of Principal Ch";
        if EffectiveDateOfResched <> 0D then
            if (LastInvoicedDueDate <= EffectiveDateOfResched) and
                (EffectiveDateOfResched <= NextNonInvoicedDueDate)
            then begin
                DaysAfterResched := S4LCommon.Days360(EffectiveDateOfResched, NextNonInvoicedDueDate); //KS210803 was +1
                DaysBeforeResched := DaysInPeriod - DaysAfterResched;
                ImpactOfPrincipalChange := ImpactOfPrincipalChange
                                          - ImpactOfPrincipalChange * NewRatePerPeriod / DaysInPeriod * DaysBeforeResched
                                          / (1 + NewRatePerPeriod);
            end;

        //-- impact of Interest change
        EffectiveDateOfResched := LineOfReschedParams."Effective Date of Interest Ch";
        if EffectiveDateOfResched <> 0D then
            if (LastInvoicedDueDate <= EffectiveDateOfResched) and
                (EffectiveDateOfResched <= NextNonInvoicedDueDate)
            then begin
                DaysAfterResched := S4LCommon.Days360(EffectiveDateOfResched, NextNonInvoicedDueDate); //KS210803 was +1
                DaysBeforeResched := DaysInPeriod - DaysAfterResched;
                OpeningBalance := StartingLine."Closing Outstanding";
                ImpactOfInterestChange := OpeningBalance * (OldRatePerPeriod - NewRatePerPeriod) / DaysInPeriod * DaysBeforeResched
                                            / (1 + NewRatePerPeriod);
            end;

        //-- impact of Asset Value Variation
        EffectiveDateOfResched := LineOfReschedParams."Effective Date of Asset Var";
        if EffectiveDateOfResched <> 0D then
            if (LastInvoicedDueDate <= EffectiveDateOfResched) and
                (EffectiveDateOfResched <= NextNonInvoicedDueDate)
            then begin
                DaysAfterResched := S4LCommon.Days360(EffectiveDateOfResched, NextNonInvoicedDueDate); //KS211221 was +1
                DaysBeforeResched := DaysInPeriod - DaysAfterResched;
                ImpactOfAssetVariation := ImpactOfAssetVariation
                                          - ImpactOfAssetVariation * NewRatePerPeriod / DaysInPeriod * DaysBeforeResched
                                          / (1 + NewRatePerPeriod);
            end;
    end;

    local procedure CalcReschedInterest(var Line: Record "S4LA Schedule Line";
                                        InterestBase: Decimal;
                                        Schedule: Record "S4LA Schedule";
                                        StartingLine: Record "S4LA Schedule Line";
                                        LineOfReschedParams: Record "S4LA Schedule Line";
                                        ImpactOfPrincipalChange: Decimal;
                                        ImpactOfInterestChange: Decimal;
                                        ImpactOfAssetVariation: Decimal);
    //Adjust Line."Interest Amount" by number of days from period start to effective date of resheduling
    var
        LastInvoicedDueDate: Date;
        EffectiveDateOfResched: Date;
        NextNonInvoicedDueDate: Date;
        DaysInPeriod: Integer;

        DaysOldRate: Integer;
        DaysNewRate: Integer;

        DaysOldPrincipal: Integer;
        DaysNewPrincipal: Integer;

        OldRatePerPeriod: Decimal;
        NewRatePerPeriod: Decimal;

        OldOutstanding: Decimal;
        NewOutstanding: Decimal;

        ErrTwoEffectiveDates: Label 'Can not have %1 and %2 on different dates. Please combine into one resheduling.';

    begin
        //--- split-period resched only applies to "In arrears". If advance - current period already invoiced and any changes apply from start of next period - no split period.
        if Schedule."Installments Due" <> Schedule."Installments Due"::"In Arrears" then
            exit;

        //--- exit if no effective dates
        if (Line."Effective Date of Principal Ch" = 0D) and
            (Line."Effective Date of Interest Ch" = 0D) and
            (Line."Effective Date of Asset Var" = 0D) then
            exit;

        //-- Can not have both "Principal change" and "Asset Value Variation" mid period on diff dates
        if (LineOfReschedParams."Effective Date of Principal Ch" <> 0D) and (LineOfReschedParams."Effective Date of Asset Var" <> 0D) then
            if LineOfReschedParams."Effective Date of Principal Ch" <> LineOfReschedParams."Effective Date of Asset Var" then
                Error(ErrTwoEffectiveDates, LineOfReschedParams.FieldCaption("Effective Date of Principal Ch"), LineOfReschedParams.FieldCaption("Effective Date of Asset Var"));

        //---Get current period start/end dates, calc days in period, silent exits if no clear period
        LastInvoicedDueDate := StartingLine.Date;
        NextNonInvoicedDueDate := LineOfReschedParams.Date;

        if (LastInvoicedDueDate = 0D) or (NextNonInvoicedDueDate = 0D) then
            exit;

        DaysInPeriod := S4LCommon.Days360(LastInvoicedDueDate, NextNonInvoicedDueDate);
        if DaysInPeriod <= 0 then
            exit;

        if (StartingLine.Period = 0) and (StartingLine."Interest Rate" = 0) then begin
            StartingLine."Interest Rate" := LineOfReschedParams."Interest Rate"; //SV210630 Variable interest update fix
            StartingLine.Modify();
        end;

        NewRatePerPeriod := (LineOfReschedParams."Interest Rate" / Schedule."Installments Per Year" / 100) * (1 + Schedule."Stamp Tax % (Interest)" / 100);
        OldRatePerPeriod := (StartingLine."Interest Rate" / Schedule."Installments Per Year" / 100) * (1 + Schedule."Stamp Tax % (Interest)" / 100);

        OldOutstanding := InterestBase - Line."Principal Change" - Line."Asset Value Variation";
        NewOutstanding := InterestBase;

        //-- Days to Principal change OR Days to Asset Value Variation (can not have both)
        DaysNewPrincipal := 0;
        if LineOfReschedParams."Effective Date of Principal Ch" <> 0D then
            EffectiveDateOfResched := LineOfReschedParams."Effective Date of Principal Ch";
        if LineOfReschedParams."Effective Date of Asset Var" <> 0D then
            EffectiveDateOfResched := LineOfReschedParams."Effective Date of Asset Var";

        if EffectiveDateOfResched <> 0D then
            if (LastInvoicedDueDate <= EffectiveDateOfResched) and (EffectiveDateOfResched <= NextNonInvoicedDueDate) then
                DaysNewPrincipal := S4LCommon.Days360(EffectiveDateOfResched, NextNonInvoicedDueDate); //KS210803 was +1
        DaysOldPrincipal := DaysInPeriod - DaysNewPrincipal;

        //-- Days to Interest change
        EffectiveDateOfResched := LineOfReschedParams."Effective Date of Interest Ch";
        if EffectiveDateOfResched <> 0D then
            if (LastInvoicedDueDate <= EffectiveDateOfResched) and (EffectiveDateOfResched <= NextNonInvoicedDueDate) then
                DaysNewRate := S4LCommon.Days360(EffectiveDateOfResched, NextNonInvoicedDueDate); //KS210803 was +1
        DaysOldRate := DaysInPeriod - DaysNewRate;

        //-- Calc interest split period (two splits - one because of principal/AssetValue change, the other because of Interest change, e.g. variable interest)
        Line."Interest Amount" :=
                (OldOutstanding / DaysInPeriod * DaysOldPrincipal
                + NewOutstanding / DaysInPeriod * DaysNewPrincipal)
                *
                (OldRatePerPeriod / DaysInPeriod * DaysOldRate
                + NewRatePerPeriod / DaysInPeriod * DaysNewRate);
        Line."Interest Amount" := -Line."Interest Amount"; //as negative in table

    end;

    local procedure CalcVariationProportion(Contract_P: Record "S4LA Contract"; Schedule_P: Record "S4LA Schedule"; StartingLine_P: Record "S4LA Schedule Line"; VAR LineOfReschedParams_P: Record "S4LA Schedule Line")
    var
        ScheduleValid_L: Record "S4LA Schedule";
    begin
        // last closing balance, in proportion to Asset Price variation
        if Contract_P."Asset Variation Started" and (Schedule_P."Version status" = Schedule_P."Version status"::New) then begin
            Contract_P.GetValidSchedule(ScheduleValid_L);
            LineOfReschedParams_P."Asset Variation Factor" := StartingLine_P."Closing Outstanding" / (ScheduleValid_L."Total Asset Price" + ScheduleValid_L."Total Asset Price Var. Amount");
            LineOfReschedParams_P."Asset Value Variation" := StartingLine_P."Closing Outstanding" * ((Schedule_P."Total Asset Price" + Schedule_P."Total Asset Price Var. Amount") /
                                                                                                     (ScheduleValid_L."Total Asset Price" + ScheduleValid_L."Total Asset Price Var. Amount") - 1);
        end;
    end;

    local procedure CreateScheduleLineDetailsInsurance(var Schedule: Record "S4LA Schedule"; var StartingLine: Record "S4LA Schedule Line")
    var
        GlSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        ContrInsurance: Record "S4LA Contract Insurance";
        Line: Record "S4LA Schedule Line";
        RoundingPrecision: Decimal;

        //-- Insurance
        InsuranceProdBuff: Dictionary of [Code[40], Decimal];
        //Insurance Code, Monthly Amount
        RemainingInsurancePeriods: Integer;

        Globals: Codeunit "S4LA Globals";
        GlobalContractInsurance: Record "S4LA Contract Insurance";
        FinProd: Record "S4LA Financial Product";
    begin
        //--- Set Rounding Precision
        GlSetup.Get;
        if Currency.Get(Schedule."Currency Code") then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GlSetup."Amount Rounding Precision";

        if not FinProd.get(Schedule."Financial Product") then
            FinProd.init;

        //---Insurance Calculations

        //1. Calc Remaining Insurance Periods
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetFilter("Entry Type", '%1|%2', Line."Entry Type"::Installment, Line."Entry Type"::Balloon);
        Line.SetRange(Invoiced, false);
        Line.SetRange("Skip Insurance", false);
        RemainingInsurancePeriods := Line.Count;

        //SOLV-1438 >>> prorated schedule. Detect if one more installment added (e.g. 13 payments in 12-month lease).
        if FinProd."Prorated Schedule" then begin
            Line.Reset();
            Line.SetRange("Contract No.", Schedule."Contract No.");
            Line.SetRange("Schedule No.", Schedule."Schedule No.");
            Line.SetRange("Version No.", Schedule."Version No.");
            Line.SetRange("Entry Type", Line."Entry Type"::Installment);
            Line.SetRange("Skip Insurance", false);
            if Line.FindLast() then
                if (Line.Period = Schedule."Number Of Payment Periods" + 1) then  //Advance, and one more installment added (e.g. 13 payments over 12 month lease)
                    RemainingInsurancePeriods -= 1;
        end;
        //SOLV-1438 <<<

        //2. Loop per Contract Insurances, calc Insurance Portion in Installment and add to Insurance Prod buffer
        ContrInsurance.Reset();
        ContrInsurance.SetRange("Contract No.", Schedule."Contract No.");
        ContrInsurance.SetRange("Schedule No.", Schedule."Schedule No.");
        ContrInsurance.SetRange("Version No.", Schedule."Version No.");
        ContrInsurance.SetRange("Treat As", ContrInsurance."Treat As"::"Included in Installment");
        if Globals.IsContractInsuranceSet() then begin
            Globals.GetContractInsurance(GlobalContractInsurance);
            ContrInsurance.SetFilter("Line No.", '<>%1', GlobalContractInsurance."Line No.");
        end;
        if ContrInsurance.FindSet() then
            repeat
                CalcInsuranceAddBuffer(ContrInsurance, Schedule, Line, StartingLine, InsuranceProdBuff, RoundingPrecision, RemainingInsurancePeriods);
            until ContrInsurance.Next() = 0;

        if Globals.IsContractInsuranceSet() then
            if not Globals.GetContractInsuranceDeleted() then begin
                Globals.GetContractInsurance(GlobalContractInsurance);
                CalcInsuranceAddBuffer(GlobalContractInsurance, Schedule, Line, StartingLine, InsuranceProdBuff, RoundingPrecision, RemainingInsurancePeriods);
            end;

        Line.Reset();
        Line.SetRange("Contract No.", StartingLine."Contract No.");
        Line.SetRange("Schedule No.", StartingLine."Schedule No.");
        Line.SetRange("Version No.", StartingLine."Version No.");
        Line.SetRange(Invoiced, false);
        if Line.FindSet() then
            repeat
                CalcInsurance(Line, Schedule, InsuranceProdBuff);
                Line.Modify();
            until Line.Next() = 0;
    end;

    local procedure CreateScheduleLineDetailsForServices(var Schedule: Record "S4LA Schedule"; var StartingLine: Record "S4LA Schedule Line")
    var
        GlSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        ContrServices: Record "S4LA Contract Service";
        SchedLineDetails: Record "S4LA Schedule Line Details";
        Line: Record "S4LA Schedule Line";
        RoundingPrecision: Decimal;

        //-- Services
        ServicesProdBuff: Dictionary of [Code[20], Decimal];
        //Services Code, Monthly Amount
        RemainingServicesPeriods: Integer;
        RemainingTotalServicesAmount: Decimal;
        ServicesAmountInInstallment: Decimal;
        FinProd: Record "S4LA Financial Product";
    begin
        //--- Set Rounding Precision
        GlSetup.Get;
        if Currency.Get(Schedule."Currency Code") then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GlSetup."Amount Rounding Precision";

        if not FinProd.get(Schedule."Financial Product") then
            FinProd.init;

        //---Services Calculations

        //1. Calc Remaining Service Periods
        Line.Reset();
        Line.SetRange("Contract No.", Schedule."Contract No.");
        Line.SetRange("Schedule No.", Schedule."Schedule No.");
        Line.SetRange("Version No.", Schedule."Version No.");
        Line.SetFilter("Entry Type", '%1|%2', Line."Entry Type"::Installment, Line."Entry Type"::Balloon);
        Line.SetRange(Invoiced, false);
        Line.SetRange("Skip Services", false);
        RemainingServicesPeriods := Line.Count;

        //SOLV-1438 >>> prorated schedule. Detect if one more installment added (e.g. 13 payments in 12-month lease).
        if FinProd."Prorated Schedule" then begin
            Line.Reset();
            Line.SetRange("Contract No.", Schedule."Contract No.");
            Line.SetRange("Schedule No.", Schedule."Schedule No.");
            Line.SetRange("Version No.", Schedule."Version No.");
            Line.SetRange("Entry Type", Line."Entry Type"::Installment);
            Line.SetRange("Skip Services", false);
            if Line.FindLast() then
                if (Line.Period = Schedule."Number Of Payment Periods" + 1) then  //Advance, and one more installment added (e.g. 13 payments over 12 month lease)
                    RemainingServicesPeriods -= 1;
        end;
        //SOLV-1438 <<<

        //2. Loop per Contract Services, calc Services Portion in Installment and add to Service buffer
        ContrServices.Reset();
        ContrServices.SetRange("Contract No.", Schedule."Contract No.");
        ContrServices.SetRange("Schedule No.", Schedule."Schedule No.");
        ContrServices.SetRange("Version No.", Schedule."Version No.");
        ContrServices.SetRange("Payment Due", ContrServices."Payment Due"::"Included in Installment");
        ContrServices.SetRange(Included, true); //SOLV-1536
        if ContrServices.FindSet() then
            repeat
                SchedLineDetails.Reset();
                SchedLineDetails.SetCurrentKey("Source Code", "Entry Type", "Amount In Installment");
                SchedLineDetails.SetRange("Contract No.", Schedule."Contract No.");
                SchedLineDetails.SetRange("Schedule No.", Schedule."Schedule No.");
                SchedLineDetails.SetRange("Version No.", Schedule."Version No.");
                SchedLineDetails.SetFilter("Schedule Line No.", '..%1', StartingLine."Line No.");
                SchedLineDetails.SetRange("Entry Type", SchedLineDetails."Entry Type"::Service);
                SchedLineDetails.SetRange("Source Code", ContrServices.Code);
                SchedLineDetails.SetFilter("Amount In Installment", '<>%1', 0);

                if Schedule."Amounts Including VAT" then begin //must match with logic in CalcServices
                    //Set total service amount already invoiced
                    SchedLineDetails.CalcSums("Amount In Inst. Incl. VAT");
                    //Calc Remaining Total Service Amount
                    RemainingTotalServicesAmount := ContrServices."Total Amount" - SchedLineDetails."Amount In Inst. Incl. VAT";
                end
                else begin
                    //Set total service amount already invoiced
                    SchedLineDetails.CalcSums("Amount In Installment");
                    //Calc Remaining Total Service Amount
                    RemainingTotalServicesAmount := ContrServices."Total Amount" - SchedLineDetails."Amount In Installment";
                end;

                //Calc Service Portion In installment based on Remaining Total Service Amount and Remaining Service Periods
                if RemainingServicesPeriods <> 0 then
                    ServicesAmountInInstallment := Round(RemainingTotalServicesAmount / RemainingServicesPeriods, RoundingPrecision)
                ELSE
                    ServicesAmountInInstallment := RemainingTotalServicesAmount;

                //Add to Buff
                //ServicesProdBuff.Add(ContrServices.Code, ServicesAmountInInstallment);
                if not ServicesProdBuff.ContainsKey(ContrServices.Code) then
                    ServicesProdBuff.Add(ContrServices.Code, ServicesAmountInInstallment);
            until ContrServices.Next() = 0;

        OnBeforeLoopPerScheduleLines_CreateScheduleLineDetailsForServices(Schedule, ServicesProdBuff);

        Line.Reset();
        Line.SetRange("Contract No.", StartingLine."Contract No.");
        Line.SetRange("Schedule No.", StartingLine."Schedule No.");
        Line.SetRange("Version No.", StartingLine."Version No.");
        Line.SetRange(Invoiced, false);
        if Line.FindSet() then
            repeat
                CalcServices(Line, Schedule, ServicesProdBuff);
                Line.Modify();
            until Line.Next() = 0;
    end;

    local procedure SetRemainingInsurancePeriods(Schedule: Record "S4LA Schedule"; StartingLine: Record "S4LA Schedule Line"; InsuranceProdCode: Code[20]; var RemainingInsurancePeriods: Integer)
    var
        InsuranceProd: Record "S4LA Insurance";
        FinProd: Record "S4LA Financial Product";
    begin
        InsuranceProd.Get(InsuranceProdCode);

        if InsuranceProd."Insurance Type" <> InsuranceProd."Insurance Type"::"Loan Protection" then
            exit;

        FinProd.Get(Schedule."Financial Product");

        // Remove RV as Baloon period
        if (Schedule."Residual Value Type" = Schedule."Residual Value Type"::Balloon) and (Schedule."Residual Value" > 0) then
            RemainingInsurancePeriods -= 1;

        // Remove first period if loan insurance starts from second periods
        if StartingLine.Period = 0 then
            if FinProd."Loan Protection Insurance Due" in [FinProd."Loan Protection Insurance Due"::"From Second Installment Incl. RV",
                                                           FinProd."Loan Protection Insurance Due"::"From Second Installment Ex. RV"] then
                RemainingInsurancePeriods -= 1;

        // Add period if Insurance Installment included in RV
        if Schedule."Residual Value" > 0 then
            if FinProd."Loan Protection Insurance Due" in [FinProd."Loan Protection Insurance Due"::"From First Installment Incl. RV",
                                                           FinProd."Loan Protection Insurance Due"::"From Second Installment Incl. RV"] then
                if Schedule."Residual Value Type" in [Schedule."Residual Value Type"::"Separate Payment", Schedule."Residual Value Type"::Balloon] then
                    RemainingInsurancePeriods += 1;
    end;

    Procedure GetRegularInstallmentDay(Sched: record "S4LA Schedule"; BaseDate: Date): integer; //SOLV-1438
    var
        BaseDay: Integer;
        InstallmentDays: Record "S4LA Preferred Installm. Day";
        FinProdInstallmentDays: Record "S4LA Fin.Prod Installment Days";
    begin

        //--- Returns regular installment date from setup. Relative to BaseDate parameter, returns next nearest installment day.

        if BaseDate <> 0D then
            BaseDay := Date2DMY(BaseDate, 1)
        else
            BaseDay := 1;

        //----------------------------------------- 1. from "Fin product Installment Days" setup per Fin product
        FinProdInstallmentDays.reset;
        FinProdInstallmentDays.SetRange("Fin. Product", Sched."Financial Product");
        if not FinProdInstallmentDays.IsEmpty then begin
            FinProdInstallmentDays.SetFilter(Day, '>=%1', BaseDay);
            if FinProdInstallmentDays.FindFirst() then begin
                exit(FinProdInstallmentDays.Day);
            end else begin
                FinProdInstallmentDays.SetRange(Day);
                FinProdInstallmentDays.FindFirst();
                exit(FinProdInstallmentDays.Day);
            end;
        end;

        //----------------------------------------- 2. from "Installment Days" (all products)
        InstallmentDays.reset;
        if not InstallmentDays.IsEmpty then begin
            InstallmentDays.SetFilter(Day, '>=%1', BaseDay);
            if InstallmentDays.FindFirst() then begin
                exit(InstallmentDays.Day);
            end else begin
                InstallmentDays.SetRange(Day);
                InstallmentDays.FindFirst();
                exit(InstallmentDays.Day);
            end;
        end;

    end;

    procedure CalcNextPaymentDate(PreviousDate: Date; PaymentDay: Integer; InstallmentFrequency: Record "S4LA Frequency") NextPaymentDate: Date
    begin
        case InstallmentFrequency."Frequency Base Unit" of
            InstallmentFrequency."Frequency Base Unit"::Week:
                NextPaymentDate := CalcDate(StrSubstNo('<+%1W>', InstallmentFrequency."Frequency Term in Base Units"), PreviousDate);
            InstallmentFrequency."Frequency Base Unit"::Month:
                NextPaymentDate := CalcDate(StrSubstNo('<+%1M>', InstallmentFrequency."Frequency Term in Base Units"), PreviousDate);
        end;
        //IF NOT AdjMonthDate THEN//>>PA150701 Issue 44
        NextPaymentDate := AdjustDateToPaymentDay(NextPaymentDate, PaymentDay, InstallmentFrequency);
    end;

    local procedure CalcSecondPaymentDate(PreviousDate: Date; PaymentDay: Integer; InstallmentFrequency: Record "S4LA Frequency") SecondPaymentDate: Date //SOLV-1438
    // This function only applied to "Prorated Schedule"
    begin
        SecondPaymentDate := AdjustDateToPaymentDay(PreviousDate, PaymentDay, InstallmentFrequency); //Second payment mey be number of days after the first payment, do not add full period
        if SecondPaymentDate <= PreviousDate then begin // add period
            case InstallmentFrequency."Frequency Base Unit" of
                InstallmentFrequency."Frequency Base Unit"::Week:
                    SecondPaymentDate := CalcDate(StrSubstNo('<+%1W>', InstallmentFrequency."Frequency Term in Base Units"), PreviousDate);
                InstallmentFrequency."Frequency Base Unit"::Month:
                    SecondPaymentDate := CalcDate(StrSubstNo('<+%1M>', InstallmentFrequency."Frequency Term in Base Units"), PreviousDate);
            end;
            SecondPaymentDate := AdjustDateToPaymentDay(SecondPaymentDate, PaymentDay, InstallmentFrequency);
        end;
    end;

    procedure AdjustDateToPaymentDay(BaseDate: Date; PaymentDay: Integer; InstallmentFrequency: Record "S4LA Frequency") PaymentDate: Date
    begin
        // Set to preferred payment day
        PaymentDate := BaseDate;
        if BaseDate = 0D then
            exit(BaseDate);

        if PaymentDay = 0 then
            exit(BaseDate);

        case InstallmentFrequency."Frequency Base Unit" of
            InstallmentFrequency."Frequency Base Unit"::Week:
                PaymentDate := DWY2Date(PaymentDay, Date2DWY(BaseDate, 2), Date2DWY(BaseDate, 3));

            else begin
                if Date2DMY(CalcDate('<CM>', BaseDate), 1) < PaymentDay then  //last month date lower than payment date
                    PaymentDay := Date2DMY(CalcDate('<CM>', BaseDate), 1);
                PaymentDate := DMY2Date(PaymentDay, Date2DMY(BaseDate, 2), Date2DMY(BaseDate, 3));
            end;
        end;
    end;

    local procedure CalcInsurance(var Line: Record "S4LA Schedule Line"; var Schedule: Record "S4LA Schedule"; InsuranceProdBuff: Dictionary of [Code[40], Decimal])
    var
        FinancialProduct: Record "S4LA Financial Product";
        GlSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        RoundingPrecision: Decimal;
        ContractInsurance: Record "S4LA Contract Insurance";
        ScheduleLineDetails: Record "S4LA Schedule Line Details";
        Contr: Record "S4LA Contract";
        Globals: Codeunit "S4LA Globals";
        GlobalContractInsurance: Record "S4LA Contract Insurance";
    begin
        if not FinancialProduct.Get(Schedule."Financial Product") then
            FinancialProduct.Init();

        if not Contr.Get(Schedule."Contract No.") then
            Contr.Init();

        GlSetup.Get;
        if Currency.Get(Schedule."Currency Code") then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GlSetup."Amount Rounding Precision";

        ScheduleLineDetails.Reset();
        ScheduleLineDetails.SetRange("Contract No.", Line."Contract No.");
        ScheduleLineDetails.SetRange("Schedule No.", Line."Schedule No.");
        ScheduleLineDetails.SetRange("Version No.", Line."Version No.");
        ScheduleLineDetails.SetRange("Schedule Line No.", Line."Line No.");
        ScheduleLineDetails.SetRange("Entry Type", ScheduleLineDetails."Entry Type"::Insurance);
        ScheduleLineDetails.DeleteAll();

        Line.Insurance := 0;
        Line."Insurance Incl. VAT" := 0;

        ContractInsurance.Reset();
        ContractInsurance.SetRange("Contract No.", Line."Contract No.");
        ContractInsurance.SetRange("Schedule No.", Line."Schedule No.");
        ContractInsurance.SetRange("Version No.", Line."Version No.");
        ContractInsurance.SetRange("Treat As", ContractInsurance."Treat As"::"Included in Installment");
        if Globals.IsContractInsuranceSet() then begin
            Globals.GetContractInsurance(GlobalContractInsurance);
            ContractInsurance.SetFilter("Line No.", '<>%1', GlobalContractInsurance."Line No.");
        end;
        if ContractInsurance.FindSet() then
            repeat
                AddDetailLinesCalcAmounts(ContractInsurance, FinancialProduct, Contr, Schedule, Line, RoundingPrecision, InsuranceProdBuff);
            until ContractInsurance.Next() = 0;

        if Globals.IsContractInsuranceSet() then
            if not Globals.GetContractInsuranceDeleted() then begin
                Globals.GetContractInsurance(GlobalContractInsurance);
                AddDetailLinesCalcAmounts(GlobalContractInsurance, FinancialProduct, Contr, Schedule, Line, RoundingPrecision, InsuranceProdBuff);
            end;
    end;

    local procedure CalcServices(var Line: Record "S4LA Schedule Line"; var Schedule: Record "S4LA Schedule"; ServiceProdBuff: Dictionary of [Code[20], Decimal])
    var
        FinancialProduct: Record "S4LA Financial Product";
        LeasingContrMngt: Codeunit "S4LA Contract Mgt";
        GlSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        RoundingPrecision: Decimal;
        ContractServices: Record "S4LA Contract Service";
        AmountIncVAT: Decimal;
        ScheduleLineDetails: Record "S4LA Schedule Line Details";
        ServicesVAT: Decimal;
        Service: Record "S4LA Service";
        Asset: Record "S4LA Asset";
        ServiceAmtInInstallment: Decimal;
        AdminFeeInInstallment: Decimal;
        AdminFeeInclVAT: Decimal;
        AdmFeeVAT: Decimal;
        Contr: Record "S4LA Contract";
        IsProrated: Boolean;
    begin
        if not FinancialProduct.Get(Line."Fin. Product Code") then
            FinancialProduct.Init();

        GlSetup.Get;
        if Currency.Get(Schedule."Currency Code") then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GlSetup."Amount Rounding Precision";

        if not Contr.Get(Schedule."Contract No.") then
            Contr.Init();

        ScheduleLineDetails.Reset();
        ScheduleLineDetails.SetRange("Contract No.", Line."Contract No.");
        ScheduleLineDetails.SetRange("Schedule No.", Line."Schedule No.");
        ScheduleLineDetails.SetRange("Version No.", Line."Version No.");
        ScheduleLineDetails.SetRange("Schedule Line No.", Line."Line No.");
        ScheduleLineDetails.SetRange("Entry Type", ScheduleLineDetails."Entry Type"::Service);
        ScheduleLineDetails.DeleteAll();

        Line.Services := 0;
        Line."Services Incl. VAT" := 0;
        Line."Admin Fees" := 0; //FM1
        Line."Admin Fees Incl. VAT" := 0; //FM1

        if Line."Entry Type" = Line."Entry Type"::"Residual Value" then
            exit;

        ContractServices.Reset();
        ContractServices.SetRange("Contract No.", Line."Contract No.");
        ContractServices.SetRange("Schedule No.", Line."Schedule No.");
        ContractServices.SetRange("Version No.", Line."Version No.");
        ContractServices.SetRange("Payment Due", ContractServices."Payment Due"::"Included in Installment");
        ContractServices.SetRange(Included, true); //SOLV-1536
        if ContractServices.FindSet() then
            repeat
                ServiceAmtInInstallment := 0;

                ServiceAmtInInstallment := ServiceProdBuff.Get(ContractServices.Code);

                AdminFeeInInstallment := ContractServices."Admin Fee (Annual)" / Schedule."Installments Per Year";
                AdminFeeInInstallment += ContractServices."Admin Fee (per Lease)" / Schedule."Number Of Payment Periods";

                if not Service.Get(ContractServices.Code) then
                    Service.Init();
                LeasingContrMngt.GetVatPercentFromService2(Contr, Service, ServicesVAT, AdmFeeVAT);

                if Schedule."Amounts Including VAT" then begin
                    AmountIncVAT := ServiceAmtInInstallment;
                    AdminFeeInclVAT := AdminFeeInInstallment;
                end else begin
                    AmountIncVAT := ServiceAmtInInstallment * (1 + ServicesVAT);
                    AdminFeeInclVAT := AdminFeeInInstallment * (1 + AdmFeeVAT);
                end;
                //FM1<<<

                if Line."Skip Services" then begin
                    AmountIncVAT := 0;
                    AdminFeeInclVAT := 0;
                end;

                //SOLV-1438 >>> prorated schedule. Prorate insurance amount in proportion to prorated installment
                if FinancialProduct."Prorated Schedule" then begin

                    //--- detect if line has prorata
                    IsProrated := ((Line.Period = 1) OR   // first installment...
                                       (Line.Period = Schedule."Number Of Payment Periods" + 1) // ...or added period at the end (e.g. 13 payments over 12 month lease)
                                    ) and
                                    (Line."Entry Type" = Line."Entry Type"::Installment) and
                                    (Line.Invoiced = false) and
                                    (Line."Installment Not Recalculated" = false) and
                                    (-Line."Total Installment" < Schedule."Regular Installment");
                    if IsProrated then
                        if Schedule."Regular Installment" <> 0 then begin
                            AmountIncVAT := AmountIncVAT / Schedule."Regular Installment" * (-Line."Total Installment"); //prorate the insurance in proportion to prorated installment
                            AdminFeeInclVAT := AdminFeeInclVAT / Schedule."Regular Installment" * (-Line."Total Installment");
                        end;
                end;
                //SOLV-1438 <<<


                //new entry for schedule line service
                ScheduleLineDetails.Reset();
                ScheduleLineDetails.Init();
                ScheduleLineDetails."Contract No." := Line."Contract No.";
                ScheduleLineDetails."Schedule No." := Line."Schedule No.";
                ScheduleLineDetails."Version No." := Line."Version No.";
                ScheduleLineDetails."Schedule Line No." := Line."Line No.";
                ScheduleLineDetails."Line No." := 0;
                ScheduleLineDetails."Entry Type" := ScheduleLineDetails."Entry Type"::Service;
                //FM1>>
                ScheduleLineDetails."Asset Line No." := ContractServices."Asset Line No.";
                if Asset.Get(ContractServices."Contract No.", ContractServices."Asset Line No.") then
                    ScheduleLineDetails."Asset ID" := ContractServices."Asset ID";
                //FM1<<
                ScheduleLineDetails."Source Code" := ContractServices.Code;
                ScheduleLineDetails."Source Line No." := ContractServices."Line No.";
                //>>EN170207
                ScheduleLineDetails."Amount In Inst. Incl. VAT" := Round(AmountIncVAT, RoundingPrecision);
                //<<EN170207
                ScheduleLineDetails."Amount In Installment" := Round(AmountIncVAT / (1 + ServicesVAT), RoundingPrecision);
                //FM1>>>
                ScheduleLineDetails."Admin Fee In Installment" := Round(AdminFeeInclVAT / (1 + ServicesVAT), RoundingPrecision);
                ScheduleLineDetails."Admin Fee in Inst. Incl. VAT" := Round(AdminFeeInclVAT, RoundingPrecision);
                ScheduleLineDetails."Amount to Bill" := ScheduleLineDetails."Amount In Installment" + ScheduleLineDetails."Admin Fee In Installment"; //initially, equal to instalment. Actual cost may be added as incured
                ScheduleLineDetails."Amount to Bill Incl. VAT" := ScheduleLineDetails."Amount In Inst. Incl. VAT" + ScheduleLineDetails."Admin Fee in Inst. Incl. VAT";
                ScheduleLineDetails."Billing Description" := ContractServices."Posting Description"; //SOLV-413
                                                                                                     //FM1<<<

                OnBeforeInsertScheduleLineDetails_CalcServices2(Schedule, Line, ContractServices, ScheduleLineDetails);
                ScheduleLineDetails.Insert(true);

                Line."Services Incl. VAT" += ScheduleLineDetails."Amount In Inst. Incl. VAT";
                Line.Services += ScheduleLineDetails."Amount In Installment";

                //FM1>>>
                Line."Admin Fees" += ScheduleLineDetails."Admin Fee In Installment";
                Line."Admin Fees Incl. VAT" += ScheduleLineDetails."Admin Fee in Inst. Incl. VAT";
            //FM1<<<
            until ContractServices.Next() = 0;
    end;

    local procedure CalcInsuranceAddBuffer(ContrInsurance: Record "S4LA Contract Insurance"; var Schedule: Record "S4LA Schedule";
                                           var SchedLine: Record "S4LA Schedule Line"; var StartingLine: Record "S4LA Schedule Line";
                                           var InsuranceProdBuff: Dictionary of [Code[40], Decimal]; RoundingPrecision: Decimal; RemainingInsurancePeriods: Integer)
    var
        SchedLineDetails: Record "S4LA Schedule Line Details";
        RemainingTotalInsuranceAmount: Decimal;
        InsuranceAmountInInstallment: Decimal;
        InsuranceBufKey: Code[40]; //SOLV-1086
    begin
        //Set Remaining Insurance Periods - there is an exceptions for Loan Protection Insurance
        SetRemainingInsurancePeriods(Schedule, StartingLine, ContrInsurance."Insurance Product Code", RemainingInsurancePeriods);

        //Calc how many periods is invoiced already, and update Remaining Insurance Periods
        SchedLineDetails.Reset();
        SchedLineDetails.SetCurrentKey("Source Code", "Entry Type", "Amount In Installment");
        SchedLineDetails.SetRange("Contract No.", Schedule."Contract No.");
        SchedLineDetails.SetRange("Schedule No.", Schedule."Schedule No.");
        SchedLineDetails.SetRange("Version No.", Schedule."Version No.");
        SchedLineDetails.SetFilter("Schedule Line No.", '..%1', StartingLine."Line No.");
        SchedLineDetails.SetRange("Source Code", ContrInsurance."Insurance Product Code");
        SchedLineDetails.SetRange("Source Line No.", ContrInsurance."Line No."); //SOLV-1086
        SchedLineDetails.SetRange("Entry Type", SchedLineDetails."Entry Type"::Insurance);
        SchedLineDetails.SetFilter("Amount In Installment", '<>%1', 0);
        //   RemainingInsurancePeriods -= SchedLineDetails.Count();

        if Schedule."Amounts Including VAT" then begin
            //Set total insurance amount already invoiced
            SchedLineDetails.CalcSums("Amount In Inst. Incl. VAT");
            //Calc Remaining Total Insurance Amount
            RemainingTotalInsuranceAmount := ContrInsurance."Total Amount" - SchedLineDetails."Amount In Inst. Incl. VAT";
        end
        else begin
            //Set total insurance amount already invoiced
            SchedLineDetails.CalcSums("Amount In Installment");
            //Calc Remaining Total Insurance Amount
            RemainingTotalInsuranceAmount := ContrInsurance."Total Amount" - SchedLineDetails."Amount In Installment";
        end;

        //Calc Insurance Portion In installment based on Remaining Total Insurance Amount and Remaining Insurance Periods
        InsuranceAmountInInstallment := Round(RemainingTotalInsuranceAmount / RemainingInsurancePeriods, RoundingPrecision);

        //Add to Buff
        //SOLV-1086 >>
        InsuranceBufKey := ContrInsurance."Insurance Product Code" + Format(ContrInsurance."Line No.");
        if InsuranceProdBuff.ContainsKey(InsuranceBufKey) then begin
            InsuranceAmountInInstallment += InsuranceProdBuff.Get(InsuranceBufKey);
            InsuranceProdBuff.Set(InsuranceBufKey, InsuranceAmountInInstallment);
        end else
            InsuranceProdBuff.Add(InsuranceBufKey, InsuranceAmountInInstallment);
        //SOLV-1086 <<
    end;

    local procedure AddDetailLinesCalcAmounts(ContrInsurance: Record "S4LA Contract Insurance"; FinProd: Record "S4LA Financial Product";
                                              Contr: Record "S4LA Contract"; var Schedule: Record "S4LA Schedule";
                                              var SchedLine: Record "S4LA Schedule Line"; RoundingPrecision: Decimal;
                                              InsuranceProdBuff: Dictionary of [Code[40], Decimal])
    var
        AmountIncVAT: Decimal;
        ScheduleLineDetails: Record "S4LA Schedule Line Details";
        InsuranceVAT: Decimal;
        InsuranceProduct: Record "S4LA Insurance";
        InsuranceAllowed: Boolean;
        InstallAmount: Decimal;
        InsuranceBufKey: Code[40]; //SOLV-1086
        IsProrated: Boolean;
    begin
        if not InsuranceProduct.Get(ContrInsurance."Insurance Product Code") then
            InsuranceProduct.Init();
        InsuranceBufKey := ContrInsurance."Insurance Product Code" + Format(ContrInsurance."Line No."); //SOLV-1086

        //not allowed on RV as separate payment, with exception for Loan Protection Insurance
        InsuranceAllowed := true;

        if InsuranceProduct."Insurance Type" = InsuranceProduct."Insurance Type"::"Loan Protection" then
            case FinProd."Loan Protection Insurance Due" of
                FinProd."Loan Protection Insurance Due"::"From First Installment Ex. RV":
                    if not (SchedLine."Entry Type" in [SchedLine."Entry Type"::Installment, SchedLine."Entry Type"::Inertia]) then
                        InsuranceAllowed := false;
                FinProd."Loan Protection Insurance Due"::"From First Installment Incl. RV":
                    ;  //Do nothing
                FinProd."Loan Protection Insurance Due"::"From Second Installment Ex. RV":
                    begin
                        if not (SchedLine."Entry Type" in [SchedLine."Entry Type"::Installment, SchedLine."Entry Type"::Inertia]) then
                            InsuranceAllowed := false;

                        if SchedLine.Period = 1 then
                            InsuranceAllowed := false;
                    end;
                FinProd."Loan Protection Insurance Due"::"From Second Installment Incl. RV":
                    //Do nothing
                    if SchedLine.Period = 1 then
                        InsuranceAllowed := false;
            end
        else
            if SchedLine."Entry Type" = SchedLine."Entry Type"::"Residual Value" then
                exit;

        if SchedLine."Skip Insurance" then
            InsuranceAllowed := false;

        LeasingContrMngt.GetVatPercentFromInsurance2(Contr, InsuranceProduct, InsuranceVAT);

        if InsuranceAllowed then
            InstallAmount := InsuranceProdBuff.Get(InsuranceBufKey)
        else
            InstallAmount := 0;

        if not Schedule."Amounts Including VAT" then
            AmountIncVAT := InstallAmount * (1 + InsuranceVAT)
        else
            AmountIncVAT := InstallAmount;

        //SOLV-1438 >>> prorated schedule. Prorate insurance amount in proportion to prorated installment
        if FinProd."Prorated Schedule" then begin

            //--- detect if line has prorata
            IsProrated := ((SchedLine.Period = 1) OR   // first installment...
                              (SchedLine.Period = Schedule."Number Of Payment Periods" + 1) // ...or added period at the end (e.g. 13 payments over 12 month lease)
                            ) and
                            (SchedLine."Entry Type" = SchedLine."Entry Type"::Installment) and
                            (SchedLine.Invoiced = false) and
                            (SchedLine."Installment Not Recalculated" = false) and
                            (-SchedLine."Total Installment" < Schedule."Regular Installment");

            if IsProrated then
                if Schedule."Regular Installment" <> 0 then
                    AmountIncVAT := AmountIncVAT / Schedule."Regular Installment" * (-SchedLine."Total Installment"); //prorate the insurance in proportion to prorated installment
        end;
        //SOLV-1438 <<<


        //new entry for schedule line insurance
        ScheduleLineDetails.Reset();
        ScheduleLineDetails.Init();
        ScheduleLineDetails."Contract No." := SchedLine."Contract No.";
        ScheduleLineDetails."Schedule No." := SchedLine."Schedule No.";
        ScheduleLineDetails."Version No." := SchedLine."Version No.";
        ScheduleLineDetails."Schedule Line No." := SchedLine."Line No.";
        ScheduleLineDetails."Line No." := 0;
        ScheduleLineDetails."Entry Type" := ScheduleLineDetails."Entry Type"::Insurance;
        ScheduleLineDetails."Source Code" := ContrInsurance."Insurance Product Code";
        ScheduleLineDetails."Source Line No." := ContrInsurance."Line No.";
        ScheduleLineDetails."Amount In Inst. Incl. VAT" := Round(AmountIncVAT, RoundingPrecision);
        ScheduleLineDetails."Amount In Installment" := Round(AmountIncVAT / (1 + InsuranceVAT), RoundingPrecision);
        ScheduleLineDetails."Amount to Bill" := ScheduleLineDetails."Amount In Installment";
        ScheduleLineDetails."Amount to Bill Incl. VAT" := ScheduleLineDetails."Amount In Inst. Incl. VAT";
        ScheduleLineDetails."Billing Description" := ContrInsurance."Posting Description";
        OnBeforeInsertScheduleLineDetails_CalcInsurance2(Schedule, SchedLine, ContrInsurance, ScheduleLineDetails);

        ScheduleLineDetails.Insert(true);

        SchedLine."Insurance Incl. VAT" += ScheduleLineDetails."Amount In Inst. Incl. VAT";
        SchedLine.Insurance += ScheduleLineDetails."Amount In Installment";
    end;

    local procedure GetInterestBeforeStarting(var Schedule: Record "S4LA Schedule"): Decimal
    var
        Contract: Record "S4LA Contract";
        Frequency: Record "S4LA Frequency";
        CommonFunctions: Codeunit "S4LA Common Functions";
        ContractMgt: Codeunit "S4LA Contract Mgt";
        LoanDate: Date;
        StartBal: Decimal;
        PeriodicRate: Decimal;
        DailyIntRate: Decimal;
        DiffInDays: Integer;
        DiffInPeriods: Integer;
    begin
        if not Contract.Get(Schedule."Contract No.") then
            Contract.Init();

        LoanDate := Contract."Date of Delivery Certificate";
        if LoanDate = 0D then
            LoanDate := Schedule."Activation Date";

        if (LoanDate = 0D) or (LoanDate >= Schedule."Starting Date") then
            exit(0);

        if not Frequency.Get(Schedule.Frequency) then
            Frequency."Installments Per Year" := 12; // monthly

        StartBal := Schedule.TotalFinancedAmountExVAT();
        PeriodicRate := Schedule."Interest Rate" / 100 / Frequency."Installments Per Year";
        DailyIntRate := Schedule."Interest Rate" / 100 / CommonFunctions.DaysInYear(Schedule."Financial Product", LoanDate);

        DiffInPeriods := GetDiffInPeriods(LoanDate, Schedule."Starting Date", Frequency);
        DiffInDays := GetDiffInDays(LoanDate, Schedule."Starting Date", Frequency, DiffInPeriods);

        StartBal += DailyIntRate * DiffInDays * StartBal; //add interest calculated till starting (payment) day
        StartBal := ContractMgt.CalcFV(PeriodicRate, DiffInPeriods, 0, -StartBal, Schedule."Installments Due".AsInteger()); // Calc FV to starting day

        exit(StartBal - Schedule.TotalFinancedAmountExVAT());
    end;

    local procedure IsLastDay(TempDate: Date): Boolean
    begin
        exit(TempDate = CalcDate('CM', TempDate));
    end;

    local procedure GetDiffInPeriods(FromDate: Date; ToDate: Date; Frequency: Record "S4LA Frequency") Periods: Integer
    begin
        case Frequency."Frequency Base Unit" of
            Frequency."Frequency Base Unit"::Month:
                begin
                    Periods := (Date2DMY(ToDate, 3) - Date2DMY(FromDate, 3)) * 12;
                    Periods += (Date2DMY(ToDate, 2) - Date2DMY(FromDate, 2));
                    Periods := (Periods / Frequency."Frequency Term in Base Units") div 1;
                    if not IsLastDay(ToDate) then
                        if CalcDate(StrSubstNo('-%1M', Periods * Frequency."Frequency Term in Base Units"), ToDate) < FromDate then
                            Periods -= 1;
                end;
            Frequency."Frequency Base Unit"::Week:
                Periods := ((ToDate - FromDate) / 7 / Frequency."Frequency Term in Base Units") div 1;
        end;
    end;

    local procedure GetDiffInDays(FromDate: Date; ToDate: Date; Frequency: Record "S4LA Frequency"; Periods: Integer): Integer
    var
        DateForm: Text;
    begin
        case Frequency."Frequency Base Unit" of
            Frequency."Frequency Base Unit"::Month:
                if IsLastDay(ToDate) then
                    DateForm := '+1D-%1M-1D'
                else
                    DateForm := '-%1M';
            Frequency."Frequency Base Unit"::Week:
                DateForm := '-%1W';
        end;
        exit(CalcDate(StrSubstNo(DateForm, Periods * Frequency."Frequency Term in Base Units"), ToDate) - FromDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetInstallmentDate_CalcSchedule(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line"; var PrevLine: Record "S4LA Schedule Line"; i: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetInstallmentDay_CalcSchedule(var Schedule: Record "S4LA Schedule"; var InstallmentDay: Integer; PeriodNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcEndingDate_CalcSchedule(var Schedule: Record "S4LA Schedule");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRegularInstallment_CalcSchedule(var Schedule: Record "S4LA Schedule"; var StartingLine: Record "S4LA Schedule Line"; var RegularPMTamt: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRegularInstallmentBeforeRounding_CalcSchedule(var Schedule: Record "S4LA Schedule"; var StartingLine: Record "S4LA Schedule Line"; var RegularPMTamt: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfter_CalcSchedule(var Schedule: Record "S4LA Schedule");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateRegularInstallment_CalcSchedule(var Schedule: Record "S4LA Schedule"; PeriodNo: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInterestAmountCalculatedOnSchedLine_CalcSchedule(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrincipalAmountCalculatedOnSchedLine_CalcSchedule(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSchedLineCreatedBeforeModify_CalcSchedule(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSchedule(var Sched: Record "S4LA Schedule")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcSchedLine_CalcSchedule(var Sched: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReschedImpactVariables_CalcSchedule(var IsHandled: Boolean;
                                                                Sched: Record "S4LA Schedule";
                                                                StartingLine: Record "S4LA Schedule Line"; //the last invoiced line
                                                                LineOfReschedParams: Record "S4LA Schedule Line"; //the first not invoices line (will carry reshed data)
                                                                var ImpactofPrincipalChange: Decimal;
                                                                var ImpactofInterestChange: Decimal;
                                                                var ImpactOfAssetVariation: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcReschedInterest_CalcSchedule(var IsHandled: Boolean;
                                                            var Line: Record "S4LA Schedule Line";
                                                            InterestBase: Decimal;
                                                            Sched: Record "S4LA Schedule";
                                                            StartingLine: Record "S4LA Schedule Line"; //the last invoiced line
                                                            LineOfReschedParams: Record "S4LA Schedule Line"; //the first not invoices line (will carry reshed data)
                                                            ImpactofPrincipalChange: Decimal;
                                                            ImpactofInterestChange: Decimal;
                                                            ImpactOfAssetVariation: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertScheduleLineDetails_CalcInsurance2(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line"; var ContractInsurance: Record "S4LA Contract Insurance"; var ScheduleLineDetails: Record "S4LA Schedule Line Details")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertScheduleLineDetails_CalcServices2(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line"; var ContractServices: Record "S4LA Contract Service"; var ScheduleLineDetails: Record "S4LA Schedule Line Details")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateScheduleLineDetailsForInsurance_CalcSchedule(var Schedule: Record "S4LA Schedule"; var StartingLine: Record "S4LA Schedule Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateScheduleLineDetailsForServices_CalcSchedule(var Schedule: Record "S4LA Schedule"; var StartingLine: Record "S4LA Schedule Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetRatePerPeriod_CalcSchedule(var Schedule: Record "S4LA Schedule"; var ratePerPeriod: Decimal; PeriodNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLoopPerScheduleLines_CreateScheduleLineDetailsForServices(var Schedule: Record "S4LA Schedule"; var ServicesProdBuff: Dictionary of [Code[20], Decimal])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLineInsertOrModify_CalcSchedule(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line"; PeriodNo: Integer; i: Integer; PrevLine: Record "S4LA Schedule Line"; SavedInstTEMP: Record "S4LA Schedule Line"; SavedInstTEMPFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcIRRRate_CalcSchedule(var Schedule: Record "S4LA Schedule"; var IRRrate: Decimal; OpeningCapitalInclReshedImpacts: Decimal; var StopCalculation: Boolean; var IsHandled: Boolean)
    begin
    end;
}
