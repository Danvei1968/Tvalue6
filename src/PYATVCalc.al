page 17022090 "PYA TV Calc"

{
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = Integer;
    SourceTableView = SORTING(Number)
                      WHERE(Number = CONST(0));
    ApplicationArea = S4Leasing;

    trigger OnOpenPage()
    var
        customerId: text[50];
        Months: integer;
        loanAmount: decimal;
        interest: decimal;
        result: Text[100];
        StartDt: DotNet tvdate;
        EndDt: DotNet tvdate;
        I: Integer;
        tv: DotNet TVAmortizationLine;
    begin
        customerId := '8517000753848570671';
        Months := 30;
        loanAmount := 100000;
        interest := 0.050;
    end;
}
    layout
    {
        
        area(content)
        {

        }      
    }
        {
            field(months; months)
            {
                ApplicationArea = S4Leasing;
                Caption = 'Months';
            }
            field(loanAmount; loanAmount)
            {
                ApplicationArea = S4Leasing;
                Caption = 'loan Amount';
            }
            field(interest; interest)
            {
                ApplicationArea = S4Leasing;
                Caption = 'interest';
            }
            field(StartDt; StartDt)
            {
                ApplicationArea = S4Leasing;
                Caption = 'Start Date';
            }
            field(EndDt; EndDt)
            {
                ApplicationArea = S4Leasing;
                Caption = 'End Date';
            }
    [Scope('OnPrem')]
    procedure GetValuetoFix(var pValuetoFix: Option " ","Asset Price",Downpayment,"Residual Value","Trade-in Value")
    begin
        

result = tv.LoanPaymentAmSchedule(
				customerId,
				StartDt,
				loanAmount,
				EndDt,
				months,
				interest,
				out listAmSchedule);                
for (i=0; i<listAmSchedule.Count )

      i+=1;  
    vmTValueAmSchedule = new Models.VmTValueAmSchedule();
				vmTValueAmSchedule.Event		= listAmSchedule[i].Event;
				vmTValueAmSchedule.Date			= listAmSchedule[i].EventDate;
				vmTValueAmSchedule.Payment		= listAmSchedule[i].Payment;
				vmTValueAmSchedule.Interest		= listAmSchedule[i].Interest;
				vmTValueAmSchedule.Principal	= listAmSchedule[i].Principal;
				vmTValueAmSchedule.Balance		= listAmSchedule[i].Balance;
				vmTValue.AmSchedule.Add(vmTValueAmSchedule);
			

			vmTValue.AmScheduleVisible = "visible";
			return View(vmTValue);
    end;
        }
    