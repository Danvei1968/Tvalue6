codeunit 17022109 "NA Schedule Calc NA"
{
    procedure PMTDotNET(Rate: Decimal; NPer: Integer; PV: Decimal; FV: Decimal; DueDateAtTheEnd: Boolean): Decimal
    var
        Financials: DotNet "Financial";
        VBDueDate: DotNet "DueDate";
    begin
        if DueDateAtTheEnd then
            exit(Financials.Pmt(Rate, NPer, PV, FV, VBDueDate.EndOfPeriod))
        else
            exit(Financials.Pmt(Rate, NPer, PV, FV, VBDueDate.BegOfPeriod));
    end;

    procedure PPmtDotNET(Rate: Decimal; Per: Integer; NPer: Integer; PV: Decimal; FV: Decimal; DueDateAtTheEnd: Boolean): Decimal
    var
        Financials: DotNet "Financial";
        VBDueDate: DotNet "DueDate";
    begin
        if DueDateAtTheEnd then
            exit(Financials.PPmt(Rate, Per, NPer, PV, FV, VBDueDate.EndOfPeriod))
        else
            exit(Financials.PPmt(Rate, Per, NPer, PV, FV, VBDueDate.BegOfPeriod));
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalculateIPMT(var Line: Record "S4LA Schedule Line"; var Schedule: Record "S4LA Schedule"; FixedInterestPrincipalValue: Decimal; InstallmentFrequency: record "S4LA Frequency"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalculatePPMT(var Line: Record "S4LA Schedule Line"; var Schedule: Record "S4LA Schedule"; FixedInterestPrincipalValue: Decimal; InstallmentFrequency: record "S4LA Frequency"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    Procedure onCheckBillServices(var Line: record "S4LA Schedule Line"; var Services: Record "S4LA Service"; var BillServExist: boolean);
    begin

    end;

    procedure CreateJnl(var Jnl: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20];
                                                                                   Descr: Text;
                                                                                   Amt: Decimal;
                                                                                   PostingType: Text[30];
                                                                                   TaxAreaCode: Code[20];
                                                                                   TaxGroup: Code[20];
                                                                                   TaxLiable: Boolean);


    begin
        Contr.GetNewestSchedule(Sched);
        // use globals: Contr, Sched, and setup tables
        IF Amt = 0 THEN BEGIN//DV170815
            Jnl.INIT;
            EXIT;
        END;

        Jnl.Init;
        Jnl."Account Type" := AccType;
        Jnl.Validate("Account No.", AccNo);
        Jnl.Validate("Posting Date", PostingDate);
        //JM170726++
        //Jnl."Document Type" := 0;
        Jnl."Document Type" := Jnl."Document Type"::Invoice;
        //JM170726--
        Jnl."Document No." := PostingDocNo;
        Jnl.Description := CopyStr(Descr, 1, MaxStrLen(Jnl.Description));
        // UpdateJnlCurrency(Jnl);              // CCY
        // CCY Jnl.VALIDATE(Amount,Amt);
        //EN190130 >>
        if Jnl."Account Type" in [Jnl."Account Type"::Customer, Jnl."Account Type"::Vendor] then
            Jnl.Validate("Payment Method Code", Contr."Payment Method Code");
        //EN190130 <<
        Jnl."Account No." := Contr."Customer No.";
        Jnl."PYA Contract No" := Sched."Contract No.";
        //Jnl."S4L Schedule No." := Sched."Schedule No.";
        //Jnl."S4L Schedule Line No." := 0;
        //Jnl."External Document No." := Contr."NA External Document No.";//DV170331

        Jnl."PYA Installment Part" := 0;
        Jnl."Source Code" := SourceCodeSetup."PYA Lease Activation";
        Jnl."System-Created Entry" := true;
        Jnl."Dimension Set ID" := Contr."Dimension Set ID";
        DimMgt.UpdateGlobalDimFromDimSetID(Jnl."Dimension Set ID", Jnl."Shortcut Dimension 1 Code", Jnl."Shortcut Dimension 2 Code");
        Jnl."VAT Calculation Type" := Jnl."VAT Calculation Type"::"Sales Tax";  //LO201028
        Jnl."Gen. Bus. Posting Group" := '';
        Jnl."Gen. Prod. Posting Group" := '';
        Jnl."VAT Calculation Type" := Jnl."VAT Calculation Type"::"Sales Tax"; // SK170209
        case PostingType of
            '':
                begin
                    Jnl."Gen. Posting Type" := Jnl."Gen. Posting Type"::" ";
                    Jnl."VAT Bus. Posting Group" := '';
                    Jnl."VAT Prod. Posting Group" := '';
                end;
            'Purchase':
                begin
                    //SM180503
                    //Jnl."Gen. Posting Type" := Jnl."Gen. Posting Type"::Purchase;
                    Jnl."Gen. Posting Type" := Jnl."Gen. Posting Type"::" ";
                    //--
                    // SK170207 Jnl."VAT Bus. Posting Group" := BusinessVAT;
                    // SK170207 Jnl.VALIDATE("VAT Prod. Posting Group", ProductVAT);
                    // >> SK170207
                    Jnl."Tax Area Code" := TaxAreaCode;
                    Jnl."Tax Group Code" := TaxGroup;
                    Jnl.VALIDATE("Tax Liable", TaxLiable);
                    // <<
                end;
            'Sale':
                begin
                    //LO201028 Jnl."Gen. Posting Type" := Jnl."Gen. Posting Type"::Sale;

                    Jnl."Gen. Posting Type" := Jnl."Gen. Posting Type"::Sale; //PYAS-148 Changed to 'Sale',Tax is not being broken out separately
                    // SK170207 Jnl."VAT Bus. Posting Group" := '';
                    // SK170207 Jnl.VALIDATE("VAT Prod. Posting Group", ProductVAT);
                    // >> SK170207
                    Jnl."Tax Area Code" := TaxAreaCode;
                    Jnl."Tax Group Code" := TaxGroup;
                    Jnl.VALIDATE("Tax Liable", TaxLiable);
                    // <<
                end;
        end;
        Jnl.Description := COPYSTR(Descr, 1, MAXSTRLEN(Jnl.Description));

        //SM180503 - Insert in TmpJnlLine for display if out of balance
        /* //Do not Delete used to display for debuging the Consistency error
        NextTmpLineNo := NextTmpLineNo + 10000;
        TmpGenJnlLine.INIT;
        TmpGenJnlLine := Jnl;
        TmpGenJnlLine."Line No." := NextTmpLineNo;
        TmpGenJnlLine.INSERT;
        */
    end;

    //BA210726changed to Global
    local procedure AddToBalanceMsg(Desc: Text; Amt: Decimal; AmtLCY: Decimal)
    begin
        //compose message for posting consistency check (zero balance)
        BalanceMsg += StrSubstNo(Text240, Desc, Amt);
        BalanceLCYMsg += StrSubstNo(Text240, Desc, AmtLCY);
        BalanceTotLCY += AmtLCY;
        BalanceTot += Amt;
    end;

    procedure PostJnl(var Jnl: Record "Gen. Journal Line")
    begin
        //>>EN180321 >>
        //IF Jnl.Amount = 0 THEN
        if (Jnl.Amount = 0) and (Jnl."Amount (LCY)" = 0) then
            IF (Jnl.Amount = 0) AND (Jnl."Amount (LCY)" = 0) AND (Jnl.Quantity = 0) THEN//DV180718
                                                                                        //<<EN180321
                exit;
        //>>EN180321
        //AddToBalanceMsg(Jnl.Description,Jnl.Amount);
        IF Jnl."Bal. Account No." = '' THEN //JM171017++
            AddToBalanceMsg(Jnl.Description, Jnl.Amount, Jnl."Amount (LCY)");
        //<<EN180321
        cdGenJnlPost.Run(Jnl);
    end;

    var
        Contr: record "S4LA Contract";
        Sched: Record "S4LA Schedule";
        SourceCodeSetup: record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        PostingDate: date;
        PostingDocNo: Code[20];
        BalanceMsg: Text;
        Text240: Label ' %1 = %2 \';
        BalanceLCYMsg: Text;
        BalanceTotLCY: Decimal;
        BalanceTot: Decimal;
        cdGenJnlPost: Codeunit "Gen. Jnl.-Post Line";
}