tableextension 17022120 "PYA Commission Schema" extends "S4LA Commission Schema"
{
    procedure fnCommissionAmt(NetCapital: Decimal; PeriodMonths: Integer; InterestRate: Decimal; ProfitFigure: Decimal; MonthlyOverhead: Decimal) Amt: Decimal
    var
        SchemaSetup: Record "S4LA Commission Setup";
    begin
        /*TG190307*/ // commison percentage * ((monthly overhead amt * term) + profit amount)
        Amt := 0;

        IF (NetCapital = 0) OR
           (PeriodMonths = 0) OR
           ((ProfitFigure + MonthlyOverhead) = 0)
        THEN
            EXIT(0);

        SchemaSetup.RESET;
        SchemaSetup.SETCURRENTKEY("Commission Schema Code", "Net Capital (LCY)", "Contract Period (months)", "Interest Rate");
        SchemaSetup.SETRANGE("Commission Schema Code", Code);
        SchemaSetup.SETFILTER("Net Capital (LCY)", '<=%1', NetCapital);
        SchemaSetup.SETFILTER("Contract Period (months)", '<=%1', PeriodMonths);
        SchemaSetup.SETFILTER("Interest Rate", '<=%1', InterestRate);
        IF SchemaSetup.FINDLAST THEN BEGIN
            Amt := ((MonthlyOverhead * PeriodMonths) + ProfitFigure) * SchemaSetup."Commission %" / 100;
            Amt := ROUND(Amt, 0.01);
        END ELSE BEGIN
            Amt := SchemaSetup."Commission Amount (LCY)";
        END;
        EXIT(Amt);

    end;

}