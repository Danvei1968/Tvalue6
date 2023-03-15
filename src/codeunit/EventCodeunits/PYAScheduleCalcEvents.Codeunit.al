codeunit 17022181 "PYA Schedule Calc Events"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Schedule Calc", 'OnBeforeCalculateIPMT', '', false, false)]
    procedure CalculateIPMT(var ScheduleLine: Record "S4LA Schedule Line"; var Schedule: Record "S4LA Schedule"; FixedInterestPrincipalValue: Decimal
    ; InstallmentFrequency: record "S4LA Frequency"; var IsHandled: Boolean)
    var
        ScheduleCalc: Codeunit "S4LA Schedule Calc";
        MoneyFactor: Decimal;
    begin
        case true of
            (Schedule."PYA Annuity/Linear" In [Schedule."PYA Annuity/Linear"::"Straight Line", Schedule."PYA Annuity/Linear"::"Straight Line (w\Residual)"]):
                begin
                    ScheduleLine.IPMT := ScheduleCalc.InterestForPeriod(-FixedInterestPrincipalValue, Schedule."Interest Rate", InstallmentFrequency);
                    IsHandled := true;
                    exit;
                end;
            //TG190729 stepdown
            (Schedule."Annuity/Linear" = Schedule."PYA Annuity/Linear"::Stepdown):
                begin
                    LoadStepdownArray(Schedule);
                    ScheduleLine.IPMT := -StepdownAvgArray[Round(ScheduleLine.Period / Schedule."Installments Per Year", 1, '>')];
                    IsHandled := true;
                    exit;
                end;
            (Schedule."PYA Annuity/Linear" = Schedule."PYA Annuity/Linear"::MoneyFactor):
                begin
                    MoneyFactor := Round(Schedule."Interest %" / 2400, 0.00001);
                    ScheduleLine.IPMT := -(Schedule."Net Capital Amount" + Schedule."Residual Value") * MoneyFactor;
                    IsHandled := true;
                    exit;
                end;
        end;
        IsHandled := false;
    end;

    /*[EventSubscriber(ObjectType::Codeunit, Codeunit::"NA Schedule Calc NA", 'OnCheckIfNotStraightStepDown', '', false, false)]
    procedure CheckIfnotStraightStepDown(var Schedule: Record Schedule; var IsHandled: Boolean)
    begin
        IF NOT (Schedule."Annuity/Linear PYA" IN [Schedule."Annuity/Linear PYA"::"Straight Line (w\Residual)", Schedule."Annuity/Linear PYA"::Stepdown]) THEN
            IsHandled := false
        else
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NA Schedule Calc NA", 'OnCheckIfNotStepDown', '', false, false)]
    procedure CheckIfNotStepDown(var Schedule: Record Schedule; var NotStepDown: Boolean)
    begin
        IF Schedule."Annuity/Linear PYA" <> Schedule."Annuity/Linear PYA"::Stepdown THEN
            NotStepDown := true
        else
            NotStepDown := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NA Schedule Calc NA", 'OnBeforeCalculatePPMT', '', false, false)]
    procedure OnBeforeCalculatePPMT_CalcPPMTPYA(var Line: Record "Schedule Line"; var Schedule: Record Schedule; FixedInterestPrincipalValue: Decimal
    ; InstallmentFrequency: record Frequency; var IsHandled: Boolean)
    begin
        if Schedule."Annuity/Linear PYA" = Schedule."Annuity/Linear PYA"::Stepdown then begin
            Line."Principal Amount" := -(Schedule."Net Capital Amount" - Schedule."Residual Value") / Schedule."Term (months)";
            IsHandled := true;
        end;
    end;
    */

    procedure LoadStepdownArray(Schedule: Record "S4LA Schedule")
    var
        DeprAmt: decimal;
        Residual: Decimal;
        i: Integer;
        Year: Integer;

    begin
        //  {TG190729}
        IF (Schedule."Number Of Payment Periods" = 0) OR (Schedule."Installments Per Year" = 0) THEN
            EXIT;

        Residual := Schedule."Net Capital Amount";
        DeprAmt := (Schedule."Net Capital Amount" - Schedule."Residual Value") / Schedule."Number Of Payment Periods";
        FOR i := 1 TO Schedule."Number Of Payment Periods" DO BEGIN
            StepdownArray[i] := Residual * Schedule."Interest %" / 100 / Schedule."Installments Per Year";
            Residual += -DeprAmt;
        END;

        CLEAR(Year);
        FOR Year := 1 TO ROUND(Schedule."Number Of Payment Periods" / Schedule."Installments Per Year", 1) DO BEGIN
            StepdownAvgArray[Year] := GetStepdownAvg(Schedule, Year);
        END;
    end;


    procedure GetStepdownAvg(schedule: record "S4LA Schedule"; year: Integer) IntForYear: Decimal
    var
        InstalNo: integer;
        i: integer;
    begin
        //  {TG190729}
        InstalNo := Year * Schedule."Installments Per Year";
        FOR i := 1 TO Schedule."Installments Per Year" DO BEGIN
            IntForYear += StepdownArray[InstalNo];
            InstalNo := InstalNo - 1;
        END;

        IntForYear := IntForYear / Schedule."Installments Per Year";

    end;

    var
        StepdownAvgArray: array[999] of Decimal;
        StepdownArray: array[999] of Decimal;
}