codeunit 17022187 "PYA Interest Recogn Sched Calc"
{
    var
        Conf001: Label 'Recalculate Interest revenue schedule for contract %1?';
        LeasingSetup: Record "S4LA Leasing Setup";
        ContractMgt: Codeunit "S4LA Contract Mgt";
        ClosingOutstanding: Decimal;
        FirstDate: Date;
        LastDate: Date;
        Rate_Annual: Decimal;
        Rate_PerDay: Decimal;
        StartFromPeriodNo: Integer;
        EndWithPeriodNo: Integer;
        TmpBalance: Decimal;
        TmpBalancetWTax: Decimal;
        LastInvoicedInst: Record "S4LA Schedule Line";
        PrevInterestAmt: Decimal; //TG220720
        UsePrevAmount: Boolean;
        IsFromAndToDateSame: Boolean;
        DetailLineSameDate: Record "S4LA Int. Recogn. Sched. Det.";
        FlagDeleteDetailedLine: Boolean;
        InterestFullyApplied: Boolean;
        StartNewLoop: Boolean;
        SchedLineToAllocate: Record "S4LA Schedule Line";
        Contr: record "S4LA Contract";
        Schedule: Record "S4LA Schedule";
        FirstSchedLine: Record "S4LA Schedule Line";
        LastSchedLine: Record "S4LA Schedule Line";
        IntRevSched: Record "S4LA Interest Recogn. Sched.";
        S4LACommonFunctions: Codeunit "S4LA Common Functions";

    /*[EventSubscriber(ObjectType::Codeunit, Codeunit::"pya Interest Recogn Sched Calc", 'OnBefore_RecalculateInterestRevenueSchedule', '', false, false)]
    local procedure RecalculateInterestRevenueSchedule(var Schedule: Record "S4LA Schedule"; var IsHandled: Boolean)
    var
        IntRevSched: Record "S4LA Interest Recogn. Sched.";
        DetailedLine: Record "S4LA Int. Recogn. Sched. Det.";
        IntRevSched2: Record "S4LA Interest Recogn. Sched.";
        FirstSchedLine: Record "s4la Schedule Line";
        LastSchedLine: Record "s4la Schedule Line";
        SchedLine: Record "s4la Schedule Line";
        TmpDate: Date;
        i: Integer;
        Rate_StartDate: Date;
        TmpToDate: Date;
        IntCalcIntBase: Decimal;
        PrevSchedLine: Record "s4la Schedule Line";
    begin
        // temporary code to correct any with recalculate error

        IsHandled := true;
        if Schedule.Recalculate then begin
            if Schedule."Version status" = Schedule."Version status"::Valid then begin
                Schedule.Recalculate := false;
                Schedule.Modify();
            end;
            exit;
        end else
            exit;
        */
    /*Contr.Get(Sched."Contract No.");
    FinProd.Get(Sched."Financial Product");
    GLSetup.Get();
*/
    //TG
    //        if (Contr."Migration Flag" <> '') or (FinProd."Interest Recognition Method" <> FinProd."Interest Recognition Method"::"End of Month")
    //or (Contr."PYA Contract Status" <> 2)
    //        then begin
    //            IsHandled := true;
    //exit
    //        end;

    // -------------------- Clear Revenue Schedule
    procedure "Clear Revenue Schedule"(IsHandled: Boolean);
    var
        TmpDate: Date;
        TmpToDate: Date;
        Rate_StartDate: date;
        I: Integer;
        IntCalcIntBase: Decimal;
        IntRevSched2: Record "S4LA Interest Recogn. Sched.";
        DetailedLine: Record "S4LA Int. Recogn. Sched. Det.";
        SchedLine: Record "S4LA Schedule Line";
        PrevSchedLine: RECORD "S4LA Schedule Line";

    begin
        IntRevSched.SetRange("Contract No.", Schedule."Contract No.");
        IntRevSched.SetRange("Schedule No.", Schedule."Schedule No.");
        IntRevSched.SetRange("Version No.", Schedule."Version No.");
        IntRevSched.SetRange("Posted to GL", false); //TG        
        //IF IntRevSched.FINDFIRST THEN
        //IF CONFIRM(STRSUBSTNO(Conf001,Sched."Contract No.")) THEN
        IntRevSched.DeleteAll(true);
        //ELSE
        //EXIT;

        Schedule.GetTheFirstInstallment(FirstSchedLine);
        Schedule.GetTheLastInstallment(LastSchedLine);

        if FirstSchedLine.IsEmpty then
            exit;

        TmpBalance := 0;
        TmpBalancetWTax := 0;
        StartFromPeriodNo := 1;

        // Determine first data to start the schedule from
        FirstDate := FirstSchedLine.Date;
        if FirstDate > Schedule."Starting Date" then
            FirstDate := Schedule."Starting Date";

        // IntRevSched.RESET;
        // IntRevSched.SETRANGE("Contract No.",Sched."Contract No.");
        // IntRevSched.SETRANGE("Schedule No.",Sched."Schedule No.");
        // IntRevSched.SETRANGE("Version No.",Sched."Version No.");
        IntRevSched.SetRange("Posted to GL", true);
        if IntRevSched.FindLast then begin
            StartFromPeriodNo += IntRevSched."Period No.";
            FirstDate := IntRevSched."Period End Date" + 1;
            TmpBalance := IntRevSched."Closing Balance";
        end;
        FirstDate := AccPeriodStart(FirstDate);

        LastDate := LastSchedLine.Date;
        if LastDate < Schedule."Ending Date" then
            LastDate := Schedule."Ending Date";

        StartFromPeriodNo := 1;
        if IntRevSched.FindLast then
            StartFromPeriodNo += IntRevSched."Period No.";

        EndWithPeriodNo := StartFromPeriodNo + AccPeriodsBetweenDates(FirstDate, LastDate);

        TmpDate := FirstDate;

        Rate_StartDate := TmpDate;
        if FirstSchedLine.Date > Rate_StartDate then
            Rate_StartDate := FirstSchedLine.Date;

        //------------------------------------- loop months
        for i := StartFromPeriodNo to EndWithPeriodNo do begin
            IntRevSched.Init;
            IntRevSched."Contract No." := Schedule."Contract No.";
            IntRevSched."Schedule No." := Schedule."Schedule No.";
            IntRevSched."Version No." := Schedule."Version No.";
            IntRevSched."Period No." := i;
            IntRevSched.Insert;

            IntRevSched."Period Start Date" := TmpDate;
            IntRevSched."Period End Date" := AccPeriodEnd(TmpDate);

            IntRevSched."Opening Balance" := TmpBalance;

            if (Schedule."Starting Date" >= IntRevSched."Period Start Date") and (Schedule."Starting Date" <= IntRevSched."Period End Date") then
                IntRevSched."Net Investment" := Schedule.TotalFinancedAmount;

            if i = StartFromPeriodNo then begin
                IntRevSched2.Reset;
                IntRevSched2.SetRange("Contract No.", Schedule."Contract No.");
                IntRevSched2.SetRange("Schedule No.", Schedule."Schedule No.");
                IntRevSched2.SetRange("Version No.", Schedule."Version No.");
                IntRevSched2.CalcSums("Net Investment", "Net Investment Modification"); // historical net investment, being amortized
                IntRevSched."Net Investment Modification" := Schedule.TotalFinancedAmount - (IntRevSched."Net Investment" + IntRevSched2."Net Investment" + IntRevSched2."Net Investment Modification");
                if IntRevSched."Net Investment Modification" <> 0 then
                    IntRevSched."Effective Date of Modification" := IntRevSched."Period Start Date";
                // >> SK200731
                if Schedule.GetLastInvoicedInstallment(LastInvoicedInst) then
                    if LastInvoicedInst.Date > IntRevSched."Period Start Date" then
                        IntRevSched."Effective Date of Modification" := LastInvoicedInst.Date;
                // <<
            end;

            IntRevSched."Installment Amount" := SumOfPaymentsInPeriod(Schedule, IntRevSched."Period Start Date", IntRevSched."Period End Date");

            if i = StartFromPeriodNo then begin //calculate once
                if StartFromPeriodNo = 1 then
                    Rate_Annual := ContractMgt.fnXIRRSched(Schedule)
                else
                    Rate_Annual := ContractMgt.fnXIRRSchedLines(Schedule, Rate_StartDate, TmpBalance + IntRevSched."Net Investment Modification", WorkDate, TmpBalancetWTax);
                Rate_PerDay := Power(1 + Rate_Annual, 1 / 365) - 1;
            end;

            IntRevSched.Modify;

            // Schedule lines is used to take installment dates and installment amounts only
            SchedLine.SetCurrentKey("Contract No.", "Schedule No.", "Version No.", "Line No.");
            SchedLine.SetRange("Contract No.", IntRevSched."Contract No.");
            SchedLine.SetRange("Schedule No.", IntRevSched."Schedule No.");
            SchedLine.SetRange("Version No.", IntRevSched."Version No.");
            SchedLine.SetRange(SchedLine."Entry Type", SchedLine."Entry Type"::Installment);
            SchedLine.SetFilter(Date, '%1..%2', IntRevSched."Period Start Date", IntRevSched."Period End Date");

            // add accounting period start
            AddToDetailedLine(IntRevSched, DetailedLine, IntRevSched."Period Start Date", 0);

            // add schedule start
            if IntRevSched."Net Investment" <> 0 then
                AddToDetailedLine(IntRevSched, DetailedLine, Schedule."Starting Date", 0);

            // add modification
            if IntRevSched."Net Investment Modification" <> 0 then
                AddToDetailedLine(IntRevSched, DetailedLine, IntRevSched."Effective Date of Modification", 0);

            // add scheduled installments
            if SchedLine.FindFirst then
                repeat
                    AddToDetailedLine(IntRevSched, DetailedLine, SchedLine.Date, -SchedLine."Total Installment")
                until SchedLine.Next = 0;

            // backwards loop to calc days
            TmpToDate := IntRevSched."Period End Date";

            DetailedLine.Reset;
            DetailedLine.SetCurrentKey("Contract No.", "Schedule No.", "Version No.", "Period No.", "From Date");
            DetailedLine.SetRange("Contract No.", IntRevSched."Contract No.");
            DetailedLine.SetRange("Schedule No.", IntRevSched."Schedule No.");
            DetailedLine.SetRange("Version No.", IntRevSched."Version No.");
            DetailedLine.SetRange("Period No.", IntRevSched."Period No.");
            DetailedLine.Ascending(false);
            if DetailedLine.FindFirst then
                repeat
                    DetailedLine."To Date" := TmpToDate;
                    TmpToDate := DetailedLine."From Date" - 1;
                    DetailedLine."No of Days" := DetailedLine."To Date" - DetailedLine."From Date" + 1;
                    if DetailedLine."To Date" = DetailLineSameDate."To Date" then begin
                        FlagDeleteDetailedLine := true;
                        DetailedLine."Installment Amount" += DetailLineSameDate."Installment Amount";
                    end;
                    DetailedLine.Modify;
                    // TG220729 - case that the previous line will have same ending date as current line
                    if DetailedLine."From Date" = DetailedLine."To Date" then begin
                        IsFromAndToDateSame := true;
                        DetailLineSameDate := DetailedLine;
                    end;
                //---//
                until DetailedLine.Next = 0;

            Clear(IsFromAndToDateSame);
            if FlagDeleteDetailedLine then
                if DetailedLine.Get(DetailLineSameDate."Contract No.", DetailLineSameDate."Schedule No.", DetailLineSameDate."Version No.", DetailLineSameDate."Period No.", DetailLineSameDate."From Date") then begin
                    DetailedLine.Delete(false);
                    Clear(FlagDeleteDetailedLine);
                end;
            Clear(DetailLineSameDate);

            // forward loop to calc amounts
            IntCalcIntBase := IntRevSched."Opening Balance";
            Clear(StartNewLoop);
            DetailedLine.Reset;
            DetailedLine.SetCurrentKey("Contract No.", "Schedule No.", "Version No.", "Period No.", "From Date");
            DetailedLine.SetRange("Contract No.", IntRevSched."Contract No.");
            DetailedLine.SetRange("Schedule No.", IntRevSched."Schedule No.");
            DetailedLine.SetRange("Version No.", IntRevSched."Version No.");
            DetailedLine.SetRange("Period No.", IntRevSched."Period No.");
            DetailedLine.Ascending(true);
            if DetailedLine.FindFirst then begin
                StartNewLoop := true;
                repeat
                    DetailedLine."Interest Base" := IntCalcIntBase;
                    if DetailedLine."From Date" = Schedule."Starting Date" then
                        DetailedLine."Interest Base" += IntRevSched."Net Investment";
                    DetailedLine."Interest Base" -= DetailedLine."Installment Amount";
                    if DetailedLine."From Date" = IntRevSched."Effective Date of Modification" then
                        DetailedLine."Interest Base" += IntRevSched."Net Investment Modification";

                    DetailedLine."Interest Rate (IRR)" := Rate_Annual;
                    DetailedLine."Effective Daily Rate" := Rate_PerDay;

                    //TG220720
                    SchedLine.Reset();
                    SchedLine.SetRange("Contract No.", Schedule."Contract No.");
                    SchedLine.SetRange("Schedule No.", Schedule."Schedule No.");
                    SchedLine.SetRange("Version No.", Schedule."Version No.");
                    SchedLine.SetFilter(Date, '>%1', DetailedLine."To Date");
                    if not SchedLine.FindFirst() then begin
                        SchedLine.SetRange(Date);
                        SchedLine.FindLast();
                    end;
                    if StartNewLoop then begin
                        if (SchedLine."Contract No." = SchedLineToAllocate."Contract No.") and
                            (SchedLine."Schedule No." = SchedLineToAllocate."Schedule No.") and
                            (SchedLine."Version No." = SchedLineToAllocate."Version No.") and
                            (SchedLine."Line No." = SchedLineToAllocate."Line No.")
                        then
                            StartNewLoop := false; // this in
                    end;
                    SchedLineToAllocate := SchedLine;
                    // is a principal only pmt, from CQ old contracts only, use next sched line
                    if (SchedLine."Interest Amount" = 0) and (SchedLine."Principal Amount" <> 0) and (SchedLine.Period > 1) and (CopyStr(SchedLine."Migration Flag", 1, 2) = 'CQ') then begin
                        PrevSchedLine := SchedLine;
                        if SchedLine.Next() <> 0 then begin
                            if SchedLine.Date > PrevSchedLine.Date then begin
                                SchedLine.Next(-1);
                            end;
                        end else begin
                            SchedLine := PrevSchedLine;
                        end;
                    end;
                    //DetailedLine."Interest Amount" := DetailedLine."Interest Base" * (Power(1 + DetailedLine."Effective Daily Rate", DetailedLine."No of Days") - 1);
                    if DetailedLine."Interest Base" <> 0 then
                        if ((DetailedLine."To Date" <> (SchedLine.Date - 1)) or InterestFullyApplied) or
                            (StartNewLoop and (DetailedLine."To Date" = CalcDate('<CM>', DetailedLine."To Date")) and (DetailedLine."From Date" = CalcDate('<-CM>', DetailedLine."To Date")))
                        then begin
                            if (SchedLine.Date - DetailedLine."From Date") <> 0 then
                                DetailedLine."Interest Amount" := S4LACommonFunctions.RoundAmount(-SchedLine."Interest Amount" * DetailedLine."No of Days" / (SchedLine.Date - DetailedLine."From Date"), Contr.CCY)
                        end else
                            DetailedLine."Interest Amount" := -SchedLine."Interest Amount" - PrevInterestAmt;
                    PrevInterestAmt := DetailedLine."Interest Amount";
                    if (PrevInterestAmt = -SchedLine."Interest Amount") and (PrevInterestAmt <> 0) and (SchedLine."Principal Amount" <> 0) then
                        InterestFullyApplied := true
                    else
                        InterestFullyApplied := false;
                    //---//
                    IntCalcIntBase := DetailedLine."Interest Base" + DetailedLine."Interest Amount";
                    DetailedLine.Modify;
                    StartNewLoop := false;
                until DetailedLine.Next = 0;
            end;

            // Total interest for the period
            DetailedLine.Reset;
            DetailedLine.SetRange("Contract No.", IntRevSched."Contract No.");
            DetailedLine.SetRange("Schedule No.", IntRevSched."Schedule No.");
            DetailedLine.SetRange("Version No.", IntRevSched."Version No.");
            DetailedLine.SetRange("Period No.", IntRevSched."Period No.");
            DetailedLine.CalcSums("Interest Amount");
            IntRevSched."Interest for Period" := S4LACommonFunctions.RoundAmount(DetailedLine."Interest Amount", Contr.CCY);

            IntRevSched."Closing Balance" := IntRevSched."Opening Balance"
                                           + IntRevSched."Net Investment"
                                           + IntRevSched."Net Investment Modification"
                                           + IntRevSched."Interest for Period"
                                           - IntRevSched."Installment Amount";

            if (i = EndWithPeriodNo) and (IntRevSched."Closing Balance" <> 0) then begin
                IntRevSched."Roundings Modification" := -IntRevSched."Closing Balance";
                if (Schedule."Residual Value" <> 0) and (Schedule."Residual Value Type" = Schedule."Residual Value Type"::"Stays Unpaid") then
                    IntRevSched."Roundings Modification" += Schedule."Residual Value";
                //IntRevSched."Interest for Period" += IntRevSched."Roundings Modification";
                IntRevSched."Closing Balance" := IntRevSched."Opening Balance"
                                             + IntRevSched."Net Investment"
                                             + IntRevSched."Net Investment Modification"
                                             + IntRevSched."Interest for Period"
                                             - IntRevSched."Installment Amount";
            end;

            IntRevSched.Modify;

            TmpDate := AccPeriodNext(TmpDate);
            TmpBalance := IntRevSched."Closing Balance";

        end;
        IsHandled := true;
    end;

    local procedure AddToDetailedLine(IntRevSched: Record "S4LA Interest Recogn. Sched."; var IntRevSchedDet: Record "S4LA Int. Recogn. Sched. Det."; AddDate: Date; AddInstallment: Decimal)
    begin
        if not IntRevSchedDet.Get(IntRevSched."Contract No.", IntRevSched."Schedule No.", IntRevSched."Version No.", IntRevSched."Period No.", AddDate) then begin
            IntRevSchedDet.Init;
            IntRevSchedDet."Contract No." := IntRevSched."Contract No.";
            IntRevSchedDet."Schedule No." := IntRevSched."Schedule No.";
            IntRevSchedDet."Version No." := IntRevSched."Version No.";
            IntRevSchedDet."Period No." := IntRevSched."Period No.";
            IntRevSchedDet."From Date" := AddDate;
            IntRevSchedDet."Installment Amount" := AddInstallment;
            IntRevSchedDet.Insert(true);
        end else begin
            IntRevSchedDet."Installment Amount" += AddInstallment;
            IntRevSchedDet.Modify;
        end;

    end;


    procedure AccPeriodStart(Date: Date): Date
    begin
        exit(CalcDate('<-CM>', Date));
    end;


    procedure AccPeriodEnd(Date: Date): Date
    begin
        exit(CalcDate('<+CM>', Date));
    end;


    procedure AccPeriodNext(Date: Date): Date
    begin
        exit(CalcDate('<+1M>', Date));
    end;


    procedure AccPeriodsBetweenDates(FromDate: Date; ToDate: Date) NoOfPeriods: Integer
    var
        Soft4Common: Codeunit "S4LA Common Functions";
        DaysCount: Decimal;
    begin
        if FromDate = 0D then
            exit(0);
        if ToDate = 0D then
            exit(0);
        if FromDate >= ToDate then
            exit(0);

        FromDate := CalcDate('<-CM>', FromDate);
        ToDate := CalcDate('<-CM>', ToDate);
        NoOfPeriods := Round(Soft4Common.Days360(FromDate, ToDate) / 360 * 12, 1, '>');

        exit(NoOfPeriods);
    end;


    procedure SumOfPaymentsInPeriod(var Sched: Record "S4LA Schedule"; FromDate: Date; ToDate: Date): Decimal
    var
        SchedLines: Record "S4LA Schedule Line";
        SumPayments: Decimal;
    begin

        if Contr."Contract No." = '' then
            exit(0);

        SumPayments := 0;

        SchedLines.Reset;
        SchedLines.SetRange("Contract No.", Sched."Contract No.");
        SchedLines.SetRange("Schedule No.", Sched."Schedule No.");
        SchedLines.SetRange("Version No.", Sched."Version No.");
        SchedLines.SetFilter(Date, '%1..%2', FromDate, ToDate);
        SchedLines.CalcSums("Total Installment");
        exit(-SchedLines."Total Installment");
    end;


    procedure MakeACopy(FromSched: Record "S4LA Schedule"; ToSched: Record "S4LA Schedule")
    var
        IntRevSched1: Record "S4LA Interest Recogn. Sched.";
        IntRevSched2: Record "S4LA Interest Recogn. Sched.";
    begin
        ToSched.TestField("Contract No.", FromSched."Contract No.");
        ToSched.TestField("Schedule No.", FromSched."Schedule No.");

        IntRevSched1.SetRange("Contract No.", FromSched."Contract No.");
        IntRevSched1.SetRange("Schedule No.", FromSched."Schedule No.");
        IntRevSched1.SetRange("Version No.", FromSched."Version No.");
        if IntRevSched1.FindSet then
            repeat
                IntRevSched2.TransferFields(IntRevSched1);
                IntRevSched2."Version No." := ToSched."Version No.";
                IntRevSched2.Insert;
            until IntRevSched1.Next = 0;
    end;

    /*procedure RecalculateOLRevenueSchedule(pSched: Record Schedule)
    var
        IntRevSched: Record "Interest Recognition Schedule";
        DetailedLine: Record "Int. Recognition Sched. Det.";
        IntRevSched2: Record "Interest Recognition Schedule";
        Sched: Record Schedule;
        FirstSchedLine: Record "Schedule Line";
        LastSchedLine: Record "Schedule Line";
        SchedLine: Record "Schedule Line";
        TmpDate: Date;
        i: Integer;
        Rate_StartDate: Date;
        TmpToDate: Date;
        DepreciationCalculation: Codeunit "Depreciation Calculation";
        TmpDays: Integer;
        AccumRevenue: Decimal;
    begin
        Sched.Get(pSched."Contract No.", pSched."Schedule No.", pSched."Version No.");
        Contr.Get(Sched."Contract No.");
        FinProd.Get(Sched."Financial Product");
        GLSetup.Get();

        // -------------------- Clear Revenue Schedule
        IntRevSched.SetRange("Contract No.", Sched."Contract No.");
        IntRevSched.SetRange("Schedule No.", Sched."Schedule No.");
        IntRevSched.SetRange("Version No.", Sched."Version No.");
        IntRevSched.SetRange("Posted to GL", false);
        //IF IntRevSched.FINDFIRST THEN
        //IF CONFIRM(STRSUBSTNO(Conf001,Sched."Contract No.")) THEN
        IntRevSched.DeleteAll(true);
        //ELSE
        //EXIT;

        Sched.GetTheFirstInstallment(FirstSchedLine);
        Sched.GetTheLastInstallment(LastSchedLine);
        Sched.CalcFields(PMT);

        if FirstSchedLine.IsEmpty then
            exit;

        TmpBalance := 0;
        StartFromPeriodNo := 1;

        // Determine first data to start the schedule from
        FirstDate := FirstSchedLine.Date;
        if FirstDate > Sched."Starting Date" then
            FirstDate := Sched."Starting Date";

        if Sched."Installments Due" = Sched."Installments Due"::"In Arrears" then
            FirstDate += 1;

        // IntRevSched.RESET;
        // IntRevSched.SETRANGE("Contract No.",Sched."Contract No.");
        // IntRevSched.SETRANGE("Schedule No.",Sched."Schedule No.");
        // IntRevSched.SETRANGE("Version No.",Sched."Version No.");
        IntRevSched.SetRange("Posted to GL", true);
        if IntRevSched.FindLast then begin
            StartFromPeriodNo += IntRevSched."Period No.";
            FirstDate := IntRevSched."Period End Date" + 1;
            TmpBalance := IntRevSched."Closing Balance";
        end;
        FirstDate := AccPeriodStart(FirstDate);

        LastDate := LastSchedLine.Date;
        if LastDate < Sched."Ending Date" then
            LastDate := Sched."Ending Date";

        StartFromPeriodNo := 1;
        if IntRevSched.FindLast then
            StartFromPeriodNo += IntRevSched."Period No.";

        // EndWithPeriodNo := StartFromPeriodNo + AccPeriodsBetweenDates(FirstSchedLine.Date,LastSchedLine.Date);
        // EndWithPeriodNo := StartFromPeriodNo + AccPeriodsBetweenDates(FirstDate,LastSchedLine.Date);
        EndWithPeriodNo := StartFromPeriodNo + AccPeriodsBetweenDates(FirstDate, LastDate);

        TmpDate := FirstDate;

        Rate_StartDate := TmpDate;
        if FirstSchedLine.Date > Rate_StartDate then
            Rate_StartDate := FirstSchedLine.Date;

        //------------------------------------- loop months
        for i := StartFromPeriodNo to EndWithPeriodNo do begin
            IntRevSched.Init;
            IntRevSched."Contract No." := Sched."Contract No.";
            IntRevSched."Schedule No." := Sched."Schedule No.";
            IntRevSched."Version No." := Sched."Version No.";
            IntRevSched."Period No." := i;
            IntRevSched.Insert;

            IntRevSched."Period Start Date" := TmpDate;
            IntRevSched."Period End Date" := AccPeriodEnd(TmpDate);

            IntRevSched."Opening Balance" := TmpBalance;

            if (Sched."Starting Date" >= IntRevSched."Period Start Date") and (Sched."Starting Date" <= IntRevSched."Period End Date") then
                IntRevSched."Net Investment" := Sched.TotalFinancedAmount;

            if i = StartFromPeriodNo then begin
                IntRevSched2.Reset;
                IntRevSched2.SetRange("Contract No.", Sched."Contract No.");
                IntRevSched2.SetRange("Schedule No.", Sched."Schedule No.");
                IntRevSched2.SetRange("Version No.", Sched."Version No.");
                IntRevSched2.CalcSums("Net Investment", "Net Investment Modification"); // historical net investment, being amortized
                                                                                        // IntRevSched."Net Investment Modification" := Sched.TotalFinancedAmount - (IntRevSched."Net Investment" + IntRevSched2."Net Investment" + IntRevSched2."Net Investment Modification");
                                                                                        // IF IntRevSched."Net Investment Modification" <> 0 THEN
                                                                                        //   IntRevSched."Effective Date of Modification" := IntRevSched."Period Start Date";
            end;

            IntRevSched."Installment Amount" := SumOfPaymentsInPeriod(Sched, IntRevSched."Period Start Date", IntRevSched."Period End Date");

            IntRevSched.Modify;

            // Schedule lines is used to take installment dates and installment amounts only
            SchedLine.SetCurrentKey("Contract No.", "Schedule No.", "Version No.", "Line No");
            SchedLine.SetRange("Contract No.", IntRevSched."Contract No.");
            SchedLine.SetRange("Schedule No.", IntRevSched."Schedule No.");
            SchedLine.SetRange("Version No.", IntRevSched."Version No.");
            SchedLine.SetRange(SchedLine."Entry Type", SchedLine."Entry Type"::Installment);
            SchedLine.SetFilter(Date, '%1..%2', IntRevSched."Period Start Date", IntRevSched."Period End Date");

            // add accounting period start
            AddToDetailedLine(IntRevSched, DetailedLine, IntRevSched."Period Start Date", 0);

            // add schedule start
            if IntRevSched."Net Investment" <> 0 then
                AddToDetailedLine(IntRevSched, DetailedLine, Sched."Starting Date", 0);

            // add modification
            // IF IntRevSched."Net Investment Modification" <> 0 THEN
            //   AddToDetailedLine(IntRevSched,DetailedLine,IntRevSched."Effective Date of Modification",0);

            // add scheduled installments
            //  IF SchedLine.FINDFIRST THEN
            //    REPEAT
            //      AddToDetailedLine(IntRevSched,DetailedLine,SchedLine.Date,-SchedLine."Total Installment")
            //    UNTIL SchedLine.NEXT = 0;

            // add schedule end date
            if i = EndWithPeriodNo then
                if Sched."Ending Date" <> 0D then
                    AddToDetailedLine(IntRevSched, DetailedLine, Sched."Ending Date" + 1, 0);

            // backwards loop to calc days
            TmpToDate := IntRevSched."Period End Date";

            DetailedLine.Reset;
            DetailedLine.SetCurrentKey("Contract No.", "Schedule No.", "Version No.", "Period No.", "From Date");
            DetailedLine.SetRange("Contract No.", IntRevSched."Contract No.");
            DetailedLine.SetRange("Schedule No.", IntRevSched."Schedule No.");
            DetailedLine.SetRange("Version No.", IntRevSched."Version No.");
            DetailedLine.SetRange("Period No.", IntRevSched."Period No.");
            DetailedLine.Ascending(false);
            if DetailedLine.FindFirst then
                repeat
                    DetailedLine."To Date" := TmpToDate;
                    TmpToDate := DetailedLine."From Date" - 1;
                    DetailedLine."No of Days" := DetailedLine."To Date" - DetailedLine."From Date" + 1;
                    DetailedLine."No of Days" := DepreciationCalculation.DeprDays(DetailedLine."From Date", DetailedLine."To Date", false);    //!!
                    DetailedLine.Modify;
                until DetailedLine.Next = 0;

            // forward loop to calc amounts
            DetailedLine.Ascending(true);
            if DetailedLine.FindFirst then
                repeat
                    DetailedLine."Opening Balance" := TmpBalance;
                    if DetailedLine."From Date" = Sched."Starting Date" then
                        DetailedLine."Opening Balance" += -Sched.PMT;   // not financed amount because revenue must be the same as total PMT
                    TmpDays := DepreciationCalculation.DeprDays(DetailedLine."From Date", Sched."Ending Date", false);
                    if TmpDays > 0 then
                        DetailedLine."Revenue Amount (OL)" := DetailedLine."Opening Balance" * DetailedLine."No of Days" / DepreciationCalculation.DeprDays(DetailedLine."From Date", Sched."Ending Date", false);
                    DetailedLine."Closing Balance" := DetailedLine."Opening Balance" - DetailedLine."Revenue Amount (OL)";
                    DetailedLine.Modify;

                    TmpBalance := DetailedLine."Closing Balance";
                until DetailedLine.Next = 0;

            // Revenue for the period
            DetailedLine.Reset;
            DetailedLine.SetRange("Contract No.", IntRevSched."Contract No.");
            DetailedLine.SetRange("Schedule No.", IntRevSched."Schedule No.");
            DetailedLine.SetRange("Version No.", IntRevSched."Version No.");
            DetailedLine.SetRange("Period No.", IntRevSched."Period No.");
            DetailedLine.CalcSums("Revenue Amount (OL)");
            IntRevSched."Revenue for Period (OL)" := S4LCommonFunctions.RoundAmount(DetailedLine."Revenue Amount (OL)", Contr.CCY);
            AccumRevenue += IntRevSched."Revenue for Period (OL)";

            IntRevSched."Closing Balance" := TmpBalance;

            if (i = EndWithPeriodNo) and (AccumRevenue <> -Sched.PMT) then begin
                IntRevSched."Revenue for Period (OL)" += -(AccumRevenue + Sched.PMT);
                IntRevSched."Roundings Modification" := AccumRevenue + Sched.PMT;
            end;

            IntRevSched.Modify;

            TmpDate := AccPeriodNext(TmpDate);
            TmpBalance := IntRevSched."Closing Balance";

        end;
    end;
    */
}