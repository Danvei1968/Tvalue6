codeunit 17022096 "NA DD Schedule Mgt"
{
    var
        DDScheduleMgt: Codeunit "S4LA DD Schedule Mgt";
        Text000: Label 'No Dishonored Recored found.';
        Text001: Label 'No Of Promise To Pay DD Sched Line must not be 0.';
        Text002: Label 'No Of Promise To Pay DD Sched Line must be less or equal to 5.';
        Text003: Label 'Total amount must be equal to %1.';
        Text004: Label 'Process completed.';
        Text005: Label 'Do yu want to confirm Promise to Pay entries?';
        Text006: Label 'No Of Promise To Pay DD Sched Line must be less or equal to 4.';
        LeasingSetup: Record "S4LA Leasing Setup";
        StatusChangeError: Label 'Status %1 can''t be changed to %2';
        "--TG190408--": Integer;
        LoopCount: Integer;
        "--TG200430--": Integer;
        AddlDDLinesToCheck: Boolean;
        LastDDInstallNo: Integer;
        PrevDDSchedCancelled: Boolean;

        LastDDSchedPeriod: integer; // BA220111 - Only used for weekly & bi-weekly contracts.

    trigger OnRun()
    begin
    end;


    local procedure "--TG190405--"()
    begin
    end;

    local procedure GetLastDDSchedDate(Contract: Record "S4LA Contract"; Schedule: Record "S4LA Schedule") LastDate: Date
    var
        DDSchedule: Record "S4LA DD Schedule";
        SchedLine: Record "S4LA Schedule Line";
    begin
        /*TG190405*/
        DDSchedule.Reset;
        DDSchedule.SetCurrentKey("Contract No.", "Instalment No."); //TG190506
        DDSchedule.SetRange("Contract No.", Schedule."Contract No.");
        DDSchedule.SetRange("Schedule No.", Schedule."Schedule No.");
        //DDSchedule.SETRANGE(Type,DDSchedule.Type::"Scheduled Instalment");
        DDSchedule.SetFilter(Status, '<>%1', DDSchedule.Status::" "); // already processed
        if DDSchedule.FindLast then begin
            LastDate := DDSchedule.Date;
            LastDDSchedPeriod := DDSchedule."Instalment No.";  //BA220111- 
            LastDDInstallNo := DDSchedule."Instalment No."; //TG210111
            if DDSchedule.Status = DDSchedule.Status::Cancelled then
                PrevDDSchedCancelled := true;
        end;

    end;

    local procedure InertiaBillingNeedsRefresh(Contract: Record "S4LA Contract"; Schedule: Record "S4LA Schedule"): Boolean
    var
        SchedLine: Record "S4LA Schedule Line";
        DDSchedule: Record "S4LA DD Schedule";
    begin
        /*TG190405*/
        SchedLine.SetRange("Contract No.", Schedule."Contract No.");
        SchedLine.SetRange("Schedule No.", Schedule."Schedule No.");
        SchedLine.SetRange("Version No.", Schedule."Version No.");
        SchedLine.SetRange("Entry Type", SchedLine."Entry Type"::Inertia);
        if SchedLine.FindLast then begin
            DDSchedule.Reset;
            DDSchedule.SetRange("Contract No.", SchedLine."Contract No.");
            DDSchedule.SetRange("Schedule No.", SchedLine."Schedule No.");
            DDSchedule.SetRange("Schedule Line No.", SchedLine."Line No.");
            if DDSchedule.IsEmpty then
                exit(true);
        end;
        exit(false);

    end;

    local procedure FindPrevDDSchedule(var PrevDDSchedule: Record "S4LA DD Schedule"; DDSchedule: Record "S4LA DD Schedule"): Boolean
    begin
        /*TG190405*/
        PrevDDSchedule.Reset;
        PrevDDSchedule.SetRange("Contract No.", DDSchedule."Contract No.");
        PrevDDSchedule.SetRange("Schedule No.", DDSchedule."Schedule No.");
        PrevDDSchedule.SetRange("Instalment No.", (DDSchedule."Instalment No." - 1));
        exit(PrevDDSchedule.FindLast);

    end;


    local procedure "--TG190506--"()
    begin
    end;

    local procedure CurrDDSchedIsProcessed(SchedLine: Record "S4LA Schedule Line"): Boolean
    var
        CurrDDSchedLine: Record "S4LA DD Schedule";
    begin
        /*TG1900506*/ // filtering DD Schedule to see if the DD belonging to current schedule line is processed or not
        CurrDDSchedLine.Reset;
        CurrDDSchedLine.SetCurrentKey("Contract No.", "Schedule No.");
        CurrDDSchedLine.SetRange("Contract No.", SchedLine."Contract No.");
        CurrDDSchedLine.SetRange("Schedule No.", SchedLine."Schedule No.");
        CurrDDSchedLine.SetRange("Schedule Line No.", SchedLine."Line No.");
        CurrDDSchedLine.SetRange(Type, CurrDDSchedLine.Type::"Scheduled Instalment");
        CurrDDSchedLine.SetFilter(Status, '<>%1', CurrDDSchedLine.Status::" ");
        if CurrDDSchedLine.IsEmpty then
            exit(false);
        exit(true);

    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA DD Schedule Mgt", 'OnRefreshDDScheduleForSchedule_Begin', '', false, false)]
    local procedure OnRefreshDDScheduleForSchedule_Begin(var Contract: Record "S4LA Contract"; var Schedule: Record "S4LA Schedule"; var isHandled: Boolean)
    var
        DDSchedule: Record "S4LA DD Schedule";
        LeasingSetup: Record "S4LA Leasing Setup";
        RecRef: RecordRef;
        PaymentMethod: Record "Payment Method";
        ScheduleLine: Record "S4LA Schedule Line";
        DDScheduleProcessed: Record "S4LA DD Schedule";
        EntryNo: Integer;
        ScheduleNo: Integer;
        VersionNo: Integer;
        Inserted: Boolean;
        TextDD001: Label 'Collection (DD) schedule lines generated successfully.';
        SLCommonFunctions: Codeunit "PYA Common Functions";
        ddStartDate: Date;
        "-=SM1800301=-": Integer;
        IsFirstSchdLine: Boolean;
        I: Integer;
        LastSchedDate: Date;
        Freq: Record "S4LA Frequency";
        "--TG190405--": Integer;
        LastDDSchedDate: Date;
        PrevDDSchedule: Record "S4LA DD Schedule";
        NextSchedLine: Record "S4LA Schedule Line";
        TmpDDStartDate: Date;
        TmpNextDDDate: Date;
        PrevDDDate: date;
        "--TG210503--": Integer;
        SkipFirstLineInclFirstInv: Boolean;
    begin
        RecRef.GetTable(DDSchedule);
        if not LeasingSetup.IsGranActive(RecRef) then
            exit;
        isHandled := true;

        Contract.Get(Schedule."Contract No.");
        Freq.get(Schedule.Frequency);
        /*TG190405*/
        Clear(LoopCount);
        Clear(LastDDSchedDate);
        Clear(AddlDDLinesToCheck); //TG200430
        Clear(PrevDDSchedCancelled); //TG211122
        LastDDSchedDate := GetLastDDSchedDate(Contract, Schedule);
        /*---*/
        DDSchedule.SetRange("Contract No.", Schedule."Contract No.");
        DDSchedule.SetRange("Schedule No.", Schedule."Schedule No.");
        DDSchedule.SetRange(Type, DDSchedule.Type::"Scheduled Instalment");
        DDSchedule.SetRange(Status, DDSchedule.Status::" ");
        if DDSchedule.FindSet then
            repeat

                if not ScheduleLine.Get(DDSchedule."Contract No.", DDSchedule."Schedule No.", Schedule."Version No.", DDSchedule."Schedule Line No.") then
                    DDSchedule.Delete
                else
                    /*TG190405*/
                    //IF NOT ScheduleLine.Invoiced THEN //Do not delete if related to invoiced because can be pending for processing
                    //  DDSchedule.DELETE;
                    if (Contract."NA DD Start Date" <= LastDDSchedDate) and not InertiaBillingNeedsRefresh(Contract, Schedule) then
                        //IF ((Contract."DD Start Date" <= LastDDSchedDate) AND NOT (Contract."DD Start Date" = 0D)) AND NOT InertiaBillingNeedsRefresh(Contract,Schedule) THEN
                        /*TG200403*/ // don't exit if the DD Schedule Payment month is different from the schedule date month or if the DD amount is different from Schedule Amt.
                                     //IF AmountOrDateOutOfSync(ScheduleLine,DDSchedule) THEN BEGIN
                        if AmountOrDateOutOfSync(ScheduleLine, DDSchedule) or PrevDDSchedCancelled then begin // 1st entry was cancelled, need to increment up the date from starting date
                            Schedule.GetNextInstallment(NextSchedLine); //TG200403 - date should be based off of next installment when contract has been rescheduled or deferred.
                            if Contract."NA DD Start Date" <> 0D then begin
                                //--TG210430--//
                                if Date2DMY(Contract."NA DD Start Date", 1) > Date2DMY(CalcDate('<CM>', ScheduleLine.Date), 1) then begin
                                    TmpDDStartDate := CalcDate('<CM>', ScheduleLine.Date);
                                    if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Month then
                                        TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+1M>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+1M>', ScheduleLine.Date), 3))
                                    else
                                        if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Week then begin  //BA220111
                                            IF Freq."Frequency Term in Base Units" = 1 then
                                                TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+1W>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+1W>', ScheduleLine.Date), 3))
                                            else
                                                if freq."Frequency Term in Base Units" = 2 then
                                                    TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+2W>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+2W>', ScheduleLine.Date), 3));
                                            //--//
                                        end;
                                end else begin
                                    Clear(TmpDDStartDate);
                                    //---//
                                    Contract."NA DD Start Date" := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(ScheduleLine.Date, 2), Date2DMY(ScheduleLine.Date, 3));  // no modify
                                end;
                            end else
                                Contract."NA DD Start Date" := ScheduleLine.Date;
                        end else
                            if not AddlDDLinesToCheck then; //TG200430
                                                            /*---*/
                                                            // exit; BA220112 - Commented
                                                            /*TG200430*/
                if AddlDDLinesToCheck and (Contract."NA DD Start Date" = 0D) then begin
                    if DDSchedule.Date <> 0D then
                        Contract."NA DD Start Date" := DDSchedule.Date
                    else
                        Contract."NA DD Start Date" := ScheduleLine.Date;
                end else
                    /*---*/
                    if DDSchedule.Delete then;
            /*---*/
            until DDSchedule.Next = 0;

        if not PaymentMethod.Get(Contract."Payment Method Code") then
            exit;
        if not PaymentMethod."Direct Debit" then
            exit;

        if not Freq.Get(Schedule.Frequency) then//DV180511
            exit;
        ScheduleLine.Reset;
        ScheduleLine.SetRange("Contract No.", Schedule."Contract No.");
        ScheduleLine.SetRange("Schedule No.", Schedule."Schedule No.");
        ScheduleLine.SetRange("Version No.", Schedule."Version No.");
        ScheduleLine.SetFilter("Entry Type", '<>%1', ScheduleLine."Entry Type"::" ");
        if LastDDInstallNo <> 0 then
            ScheduleLine.SetFilter(Period, '>%1', LastDDInstallNo); //TG210111
        /*TG210512*/
        if (Contract."NA DD Start Date" <> 0D) and (Schedule."Installments Per Year" = 12) then begin
            ScheduleLine.SetFilter(Date, '>=%1', CalcDate('<-CM>', Contract."NA DD Start Date"));
        end;
        /*---*/
        //SM180301 - ScheduleLine.SETFILTER("Outstanding Amount",'<>%1',0);
        //SM180301 - ScheduleLine.SETRANGE(Invoiced,FALSE);
        /*DV180322*/
        //CLEAR(LastSchedDate);
        //IF ScheduleLine.FINDLAST THEN
        //  LastSchedDate := ScheduleLine.Date;
        /*---*/
        if ScheduleLine.FindSet then
        //JM170726++
        begin
            if not (Schedule."NA Incl. First P. to First Inv" and ScheduleLine.Invoiced and (ScheduleLine.Period = 1)) then begin //TG210503
                if Contract."NA DD Start Date" <> 0D then begin
                    /*TG210111*/ // situation of refreshing DD Schedule when DD Start Date is far in past
                    if ddStartDate <= LastDDSchedDate then begin
                        //--TG210430--//
                        if Date2DMY(Contract."NA DD Start Date", 1) > Date2DMY(CalcDate('<CM>', ScheduleLine.Date), 1) then begin
                            TmpDDStartDate := CalcDate('<CM>', ScheduleLine.Date);
                            if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Month then
                                TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+1M>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+1M>', ScheduleLine.Date), 3))
                            else
                                if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Week then begin  //BA220111
                                    IF Freq."Frequency Term in Base Units" = 1 then
                                        TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+1W>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+1W>', ScheduleLine.Date), 3))
                                    else
                                        if freq."Frequency Term in Base Units" = 2 then
                                            TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+2W>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+2W>', ScheduleLine.Date), 3));
                                    //--//
                                end;
                        end else begin
                            Clear(TmpDDStartDate);
                            //---//
                            if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Month then
                                ddStartDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(ScheduleLine.Date, 2), Date2DMY(ScheduleLine.Date, 3))
                            else begin
                                if (ScheduleLine.period - 1) = LastDDSchedPeriod then begin
                                    ddStartDate := ScheduleLine.Date;
                                end;
                            end;
                        end;
                    end else
                        /*---*/
                ddStartDate := Contract."NA DD Start Date"
                    /*TG190506*/ // caused an error if Contr DD start date is empty
                                 //ELSE
                end else begin
                    ddStartDate := ScheduleLine.Date;
                    Contract."NA DD Start Date" := ScheduleLine.Date;
                end;
                /*---*/
                //JM170726--
                //SM180301 - Start
                IsFirstSchdLine := true;
                //---
            end else //TG210503
                SkipFirstLineInclFirstInv := true; //TG210503

            //BA220117
            if Schedule."Version No." > 1 then
                Contract."NA DD Start Date" := ddStartDate;
            //---//
            repeat
                /*TG210503*/ // execute normal first line code on 2nd line if first line invoiced in advance
                if SkipFirstLineInclFirstInv and (ScheduleLine.Period = 2) then begin
                    if Contract."na DD Start Date" <> 0D then begin
                        /*TG210111*/ // situation of refreshing DD Schedule when DD Start Date is far in past
                        if ddStartDate <= LastDDSchedDate then begin
                            //--TG210430--//
                            if Date2DMY(Contract."NA DD Start Date", 1) > Date2DMY(CalcDate('<CM>', ScheduleLine.Date), 1) then begin
                                TmpDDStartDate := CalcDate('<CM>', ScheduleLine.Date);
                                if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Month then
                                    TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+1M>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+1M>', ScheduleLine.Date), 3))
                                else
                                    if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Week then begin  //BA220111
                                        IF Freq."Frequency Term in Base Units" = 1 then
                                            TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+1W>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+1W>', ScheduleLine.Date), 3))
                                        else
                                            if freq."Frequency Term in Base Units" = 2 then
                                                TmpNextDDDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(CalcDate('<+2W>', ScheduleLine.Date), 2), Date2DMY(CalcDate('<+2W>', ScheduleLine.Date), 3));
                                        //--//
                                    end;
                            end else begin
                                Clear(TmpDDStartDate);
                                //---//
                                ddStartDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(ScheduleLine.Date, 2), Date2DMY(ScheduleLine.Date, 3));
                            end;
                        end else
                            /*---*/
                  ddStartDate := Contract."NA DD Start Date"
                        /*TG190506*/ // caused an error if Contr DD start date is empty
                                     //ELSE
                    end else begin
                        ddStartDate := ScheduleLine.Date;
                        Contract."NA DD Start Date" := ScheduleLine.Date;
                    end;
                    /*---*/
                    //JM170726--
                    //SM180301 - Start
                    IsFirstSchdLine := true;
                    SkipFirstLineInclFirstInv := false;
                    //---
                end;
                if not (Schedule."NA Incl. First P. to First Inv" and ScheduleLine.Invoiced and (ScheduleLine.Period = 1)) then begin
                    /*---*/ // TG210503
                    DDScheduleProcessed.Reset;
                    DDScheduleProcessed.SetRange("Contract No.", ScheduleLine."Contract No.");
                    DDScheduleProcessed.SetRange("Schedule No.", ScheduleLine."Schedule No.");
                    DDScheduleProcessed.SetRange("Schedule Line No.", ScheduleLine."Line No.");
                    if IsFirstSchdLine then begin
                        /*TG190506*/
                        if not CurrDDSchedIsProcessed(ScheduleLine) and
                              ((Date2DMY(ScheduleLine.Date, 2) >= Date2DMY(Contract."NA DD Start Date", 2)) or (Date2DMY(ScheduleLine.Date, 3) > Date2DMY(Contract."NA DD Start Date", 3)))
                        then
                            LoopCount += 1;
                        /*---*/
                        IsFirstSchdLine := false;
                    end else begin
                        //--TG210430--// - scenario that the dd start date is greater than number of days in month
                        if TmpDDStartDate <> 0D then begin
                            DDSchedule.Date := TmpDDStartDate;
                            Clear(TmpDDStartDate);
                        end else
                            //---//
                            //--TG210430--// - scenario that the dd start date is greater than number of days in month
                            if TmpDDStartDate <> 0D then begin
                                DDSchedule.Date := TmpDDStartDate;
                                Clear(TmpDDStartDate);
                            end else
                                //---//
                                DDSchedule.Date := ddStartDate;
                        I := GlobalLanguage;//DV180302
                        GlobalLanguage := 1033;//DV180302
                                               /*TG190405*/
                                               //IF Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Week THEN//DV180511
                                               //  ddStartDate := CALCDATE('+1W', ddStartDate)
                                               //ELSE
                                               //  ddStartDate := CALCDATE('+1M', ddStartDate);
                                               /*TG190506*/
                        if (Date2DMY(ScheduleLine.Date, 2) >= Date2DMY(Contract."NA DD Start Date", 2)) or (Date2DMY(ScheduleLine.Date, 3) > Date2DMY(Contract."NA DD Start Date", 3)) then
                            if IsDDStatusBlank(ScheduleLine) and (Contract."NA DD Start Date" > LastDDSchedDate) then begin
                                /*---*/
                                if LoopCount <> 1 then begin
                                    if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Week then begin
                                        //BA220111 -Take care of bi weekly contracts

                                        if Freq."Frequency Term in Base Units" = 1 then
                                            ddStartDate := CalcDate('<+1W>', ddStartDate) //DV201118
                                        else
                                            if Freq."Frequency Term in Base Units" = 2 then
                                                ddStartDate := CalcDate('<+2W>', ddStartDate) //DV201118
                                                                                              //--//
                                    end else
                                        //--TG210430--//
                                        if (TmpNextDDDate <> 0D) and (ddStartDate = 0D) then begin
                                            ddStartDate := TmpNextDDDate;
                                            Clear(TmpNextDDDate);
                                        end else begin  //BA220514
                                            //---//
                                            if (Date2DMY(ScheduleLine.Date, 2) = Date2DMY(PrevDDDate, 2)) and (PrevDDDate <> 0D) then
                                                ddStartDate := ddStartDate
                                            else begin
                                                ddStartDate := CalcDate('<+1M>', ddStartDate);//DV201118

                                                //BA220513
                                                if Contract."NA DD Start Date" <> 0D then
                                                    if (Date2DMY(Contract."NA DD Start Date", 1) <> Date2DMY(ddStartDate, 1)) and
                                                      (Date2DMY(Contract."NA DD Start Date", 1) <= Date2DMY(CalcDate('<CM>', ddStartDate), 1)) then
                                                        ddStartDate := DMY2Date(Date2DMY(Contract."NA DD Start Date", 1), Date2DMY(ddStartDate, 2), Date2DMY(ddStartDate, 3));
                                                //--//

                                            end;
                                        end; //BA220514
                                end;
                            end;
                        /*TG190506*/
                        //IF (Contract."DD Start Date" <= LastDDSchedDate) THEN BEGIN
                        if (Contract."NA DD Start Date" <= LastDDSchedDate) and ((Date2DMY(ScheduleLine.Date, 2) >= Date2DMY(Contract."NA DD Start Date", 2)) or
                          (Date2DMY(ScheduleLine.Date, 3) > Date2DMY(Contract."NA DD Start Date", 3))) then begin
                            /*---*/
                            if Freq."Frequency Base Unit" = Freq."Frequency Base Unit"::Week then begin
                                //BA220111 - Take care of Bi-Weekly
                                if FindPrevDDSchedule(PrevDDSchedule, DDSchedule) then begin
                                    if Freq."Frequency Term in Base Units" = 1 then
                                        DDSchedule.Date := CalcDate('<+1W>', PrevDDSchedule.Date)  //DV201118
                                    else
                                        if Freq."Frequency Term in Base Units" = 2 then
                                            DDSchedule.Date := CalcDate('<+2W>', PrevDDSchedule.Date);
                                end;
                                //--//
                            end else
                                //--TG210430--//
                                if (TmpNextDDDate <> 0D) and (ddStartDate = 0D) then begin
                                    ddStartDate := TmpNextDDDate;
                                    Clear(TmpNextDDDate);
                                end else
                                    //---//
                                    ddStartDate := CalcDate('<+1M>', ddStartDate);//DV201118
                        end;
                        /*---*/
                        GlobalLanguage := I;//DV180302
                    end;



                    /*TG190506*/
                    if (DDScheduleProcessed.IsEmpty) and ((Date2DMY(ScheduleLine.Date, 2) >= Date2DMY(Contract."NA DD Start Date", 2)) or
                      (Date2DMY(ScheduleLine.Date, 3) > Date2DMY(Contract."NA DD Start Date", 3))) then begin
                        //IF DDScheduleProcessed.ISEMPTY THEN BEGIN
                        /*---*/
                        DDSchedule.Init;
                        DDSchedule."Payment Order No." := DDScheduleMgt.GetNewPaymentOrderNo;
                        DDSchedule.Insert(true);
                        //JM170726++
                        //DDSchedule.Date:= ScheduleLine.Date;
                        /*TG210111*/ // situation that the DD Schedule needs to be refreshed but the DD Start Date is still set well in the past
                                     /*---*/
                                     //--TG210430--// - scenario that the dd start date is greater than number of days in month
                        if TmpDDStartDate <> 0D then begin
                            DDSchedule.Date := TmpDDStartDate;
                            Clear(TmpDDStartDate);
                        end else
                            //---//
                            DDSchedule.Date := ddStartDate;

                        //SM180301 - ddStartDate := CALCDATE('+1M', ddStartDate);
                        //JM170726--
                        DDSchedule.Amount := ScheduleLine.fnInstallmentInclVAT;
                        DDSchedule."Currency Code" := Schedule."Currency Code";
                        DDSchedule."Amount (LCY)" := ScheduleLine.fnInstallmentInclVATLCY(); //just for estimated amount. Will collect using DDSchedule date rate
                        DDSchedule.Type := DDSchedule.Type::"Scheduled Instalment";
                        /*DV180322*/
                        //        IF DDSchedule.Date = LastSchedDate THEN
                        DDSchedule.Status := DDSchedule.Status::" ";
                        //        ELSE
                        //        DDSchedule.Status := DDSchedule.Status::Posted;
                        /*---*/
                        DDSchedule."Customer No." := Schedule."Customer No.";
                        DDSchedule."Contract No." := ScheduleLine."Contract No.";
                        DDSchedule."Schedule No." := ScheduleLine."Schedule No.";
                        DDSchedule."Schedule Line No." := ScheduleLine."Line No.";
                        DDSchedule."Instalment No." := ScheduleLine.Period;
                        DDSchedule."Payment Method" := PaymentMethod.Code;
                        /*TG190405*/ // This should apply to Inertia billing when DD Start Date in past
                                     //TG211116::IF ((Contract."DD Start Date" <= LastDDSchedDate) AND NOT (Contract."DD Start Date" = 0D) AND (ScheduleLine."Entry Type" = ScheduleLine."Entry Type"::Inertia)) THEN BEGIN
                        if (((Contract."NA DD Start Date" <= LastDDSchedDate) and not (Contract."NA DD Start Date" = 0D) and (ScheduleLine."Entry Type" = ScheduleLine."Entry Type"::Inertia)))
                        or (DDSchedule.Date = LastDDSchedDate)
                        then begin
                            //---//
                            if FindPrevDDSchedule(PrevDDSchedule, DDSchedule) then begin
                                case Freq."Frequency Base Unit" of
                                    Freq."Frequency Base Unit"::Week:
                                        begin
                                            //BA220111 - Take care of Bi-Weekly
                                            if Freq."Frequency Term in Base Units" = 1 then
                                                DDSchedule.Date := CalcDate('<+1W>', PrevDDSchedule.Date)  //DV201118
                                            else
                                                if Freq."Frequency Term in Base Units" = 2 then
                                                    DDSchedule.Date := CalcDate('<+2W>', PrevDDSchedule.Date)
                                            //--//
                                        end;
                                    Freq."Frequency Base Unit"::Month:
                                        DDSchedule.Date := CalcDate('<+1M>', PrevDDSchedule.Date);//DV201118
                                end;
                                LastDDSchedDate := DDSchedule.Date;
                            end;
                        end; //TG190405 - end

                        PrevDDDate := DDSchedule.Date; //BA220514
                        DDSchedule.Modify;
                    end;
                end;
            until ScheduleLine.Next = 0;
        end; //JM170726
    end;

    local procedure AmountOrDateOutOfSync(pSchedLine: Record "S4LA Schedule Line"; pDDSchedule: Record "S4LA DD Schedule"): Boolean
    var
        AddlDDSchedule: Record "S4LA DD Schedule";
    begin
        /*TG200430*/
        if ((-pSchedLine."Installment Incl. VAT" + pSchedLine."Services Incl. VAT") <> pDDSchedule.Amount) or ((Date2DMY(pDDSchedule.Date, 2) <> Date2DMY(pSchedLine.Date, 2))) then
            exit(true);

        AddlDDSchedule.SetRange("Contract No.", pDDSchedule."Contract No.");
        AddlDDSchedule.SetFilter("Instalment No.", '>%1', pDDSchedule."Instalment No.");
        if AddlDDSchedule.IsEmpty then
            AddlDDLinesToCheck := false
        else
            AddlDDLinesToCheck := true;

    end;

    local procedure IsDDStatusBlank(ScheduleLine: Record "S4LA Schedule Line"): Boolean
    var
        DDScheduleCurr: Record "S4LA DD Schedule";
    begin
        DDScheduleCurr.Reset;
        DDScheduleCurr.SetRange("Contract No.", ScheduleLine."Contract No.");
        DDScheduleCurr.SetRange("Schedule No.", ScheduleLine."Schedule No.");
        DDScheduleCurr.SetRange("Schedule Line No.", ScheduleLine."Line No.");
        DDScheduleCurr.SetRange(Status, DDScheduleCurr.Status::" ");
        if not DDScheduleCurr.IsEmpty then begin
            LoopCount += 1;
            exit(true);
        end;
        DDScheduleCurr.SetRange(Status);
        if DDScheduleCurr.IsEmpty then begin
            LoopCount += 1;
            exit(true);
        end;
        exit(false);
    end;
}