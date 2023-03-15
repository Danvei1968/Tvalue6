codeunit 17022095 "NA Contract Closing"
{
    // NR141107 : Created one codeunit   for closing contract and discharging all related assets;
    // PB141127 : CCI Rebate Calc
    // PA150217 : issue 115
    // KS151105 code restructure
    // PB150419 add Loss recovery Status
    // PA150528 - Sys aid issue - 17615

    TableNo = "s4la Contract";

    trigger OnRun()
    var
        Text50000: Label 'Can''t close Contract No. %1 . Only %2% Asset returned.';
    begin
        Contr := Rec;
        Code;
        Rec := Contr;
    end;

    var
        LeasingSetup: Record "S4LA Leasing Setup";
        Contr: Record "S4LA Contract";
        CBal: Record "S4LA Contract Balance";
        Text50000: Label 'Operating lease asets must be returned. Can not close contract No. %1';
        LeasingPostingSetup: Record "S4LA Leasing Posting Setup";
        LeasingPostingSetupTerm: Record "S4LA Leasing Posting Setup";
        LeasingPostingSetupAct: Record "S4LA Leasing Posting Setup";
        PostingDate: Date;
        PostingDocNo: Code[20];
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Sched: Record "S4LA Schedule";
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        cdGenJnlPost: Codeunit "Gen. Jnl.-Post Line";
        BalanceMsg: Text;
        BalanceTot: Decimal;
        Text241: Label 'Termination posting is out of balance by %1 \';
        ".DV201802": Integer;
        FaDep: Record "FA Depreciation Book";
        FaJnl: Record "FA Journal Line";
        FALE: Record "FA Ledger Entry";
        FAJnlPostBatch: Codeunit "FA Jnl.-Post Batch";
        W: Dialog;
        PostingLines2Msg: Label 'Posting              #2######';
        FATmpl: Record "FA Journal Template";
        FaTBatch: Record "FA Journal Batch";
        FAJnlPostLine: Codeunit "FA Jnl.-Post Line";
        ".DV190130": Integer;
        SchedLn: Record "S4LA Schedule Line";
        Text001: Label 'Last month invoiced is %1';
        ProRataDaysDiff: Integer;
        ProRataAmount: Decimal;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        Text019: Label 'Pro-rata billing, contr. %1';
        AmountToPost: Decimal;
        Text020: Label 'Security Deposit %1';
        "---JM180414---": Integer;
        schedLine: Record "S4LA Schedule Line";
        dt1: Date;
        dt2: Date;
        Amt: Decimal;
        InsAmt: Decimal;
        ContractInsurance: Record "S4LA Contract Insurance";
        InsuranceProduct: Record "S4LA Insurance";
        GLAccount: Record "G/L Account";
        SkipDateDialogPage: Boolean;

        BusSalesVATgr: Code[20];
        ProdSalesVATgr: code[20];
        AmtInclSalesVAT: Decimal;
        AmtExVAT: Decimal;
        RoundingPrecision: decimal;
        Currency: record Currency;
        GLSetup: record "General Ledger Setup";
        UnEarnedInc: Decimal;
        GainLossAmount: Decimal;

        DiffRounding: Decimal;

    local procedure "Code"()
    var
        CLE: Record "Cust. Ledger Entry";
        FA: Record "Fixed Asset";
        Partial: Decimal;
        remaining: Decimal;
        AllAssetsReturned: Boolean;
        FinProd: Record "S4LA Financial Product";
        CompInfo: Record "Company Information";
        "-- SK171030": Integer;
        ToStatus: Code[20];
        StatusMgt: Codeunit "S4LA Status Mgt";
        LAsset: Record "S4LA Asset";
        Jnl: Record "Gen. Journal Line";
        LText01: Label '%1Termination %2, Leasing Inventory';
        PostDtPage: Page "PYA Posting Date";
        BookVal: Decimal;
        AssetStatus: Record "S4LA Status";
        LeaseReceivableAcc: code[20];
        EarlyPayout: record "S4LA Early Payout";
        EarlyTermFeeLbl: label 'Payout penaly fee %1';
        ShowAssetPosting: Boolean;
        AssetPostingType: Option " ",Repossession,"Early Pay Out",Surrender,"Matured -Paid in Full","Early Pay Out – Paid in Full","Write off";

        AssetPostErr: label 'Please specify the asset return type.';
    //NAContractMgt: Codeunit "NA Contract Mgt";
    begin
        //--- Check for zero balances, give error
        LeasingSetup.GET;
        LeasingSetup.TESTFIELD("Status - Paid in Full");
        LeasingSetup.TESTFIELD("Status - Settled in full");
        LeasingSetup.TESTFIELD("Status - Loss Recovery");

        FinProd.GET(Contr."Financial Product");
        SourceCodeSetup.GET;//DV180214

        //BA220609
        if (FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::"Hire Purchase") or
         (FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::"Financial Lease") then
            ShowAssetPosting := true;
        //--//


        CBal.GET(Contr."Contract No.");

        //--- Check if OpLease assets returned, give error
        IF Contr.IsOperatingLease THEN BEGIN //BA220428
            Contr.AssetReturnPercents(Partial, remaining, AllAssetsReturned);
            IF (NOT AllAssetsReturned) THEN
                ERROR(Text50000, Contr."Contract No.");
        END;
        /*DV180124*/
        LAsset.RESET;
        LAsset.SETRANGE("Contract No.", Contr."Contract No.");
        IF LAsset.FINDFIRST THEN
            if FA.GET(LAsset."Asset No.") then; //BA220501

        //BA221212 -Skip dialog page for refinanced contract
        if Contr."Refinanced by Contr. No." <> '' then begin
            SkipDateDialogPage := true;
            ShowAssetPosting := false;
        end;
        //--//

        //PYAS-176
        if not SkipDateDialogPage then begin
            commit;
            CLEAR(PostDtPage);
            PostDtPage.LOOKUPMODE := TRUE;
            PostDtPage.SetDt(FA."NA Return Date");
            PostDtPage.SetAssetPType(ShowAssetPosting); //BA220609
            IF PostDtPage.RUNMODAL = ACTION::LookupOK THEN begin //BA220609
                PostingDate := PostDtPage.GetDt;
                AssetPostingType := PostDtPage.GetAssetPType();
            END ELSE
                EXIT;
        end;

        if ShowAssetPosting then
            if AssetPostingType = AssetPostingType::" " then
                error(AssetPostErr);

        /*---*/
        W.OPEN(PostingLines2Msg + '\\' +
          '#1#################################');//DV180301
                                                 /*DV180226*/

        CLE.RESET;
        CLE.SETCURRENTKEY("Customer No.", "PYA Contract No", "Posting Date");
        CLE.SETRANGE("Customer No.", Contr."Customer No.");
        CLE.SETRANGE("PYA Contract No", Contr."Contract No.");
        CLE.SETRANGE("Posting Date", CALCDATE('<-7D>', PostingDate), PostingDate);//DV180124
        //CLE.SETRANGE("Posting Date",CALCDATE('<-7D>',WORKDATE),WORKDATE);
        CLE.SETRANGE("Document Type", CLE."Document Type"::Payment);
        CLE.SETRANGE(Positive, FALSE);
        CLE.SETRANGE(Reversed, FALSE);
        IF CLE.ISEMPTY
          // >> SK171030
          // THEN Contr.VALIDATE("Status Code",LeasingSetup."Status - Settled in full")
          // ELSE Contr.VALIDATE("Status Code",LeasingSetup."Status - Paid in Full");
          THEN
            ToStatus := LeasingSetup."Status - Settled in full"
        ELSE
            ToStatus := LeasingSetup."Status - Paid in Full";

        //BA220715
        if AssetPostingType = AssetPostingType::Repossession then
            ToStatus := LeasingSetup."Status - Repossession"
        else
            if (AssetPostingType = AssetPostingType::"Early Pay Out") or
             (AssetPostingType = AssetPostingType::"Early Pay Out – Paid in Full") then
                ToStatus := LeasingSetup."Status - Payout Paid in Full"
            else
                if AssetPostingType = AssetPostingType::"Matured -Paid in Full" then
                    ToStatus := LeasingSetup."Status - Matured Paid in Full"
                else
                    if AssetPostingType = AssetPostingType::Surrender then
                        ToStatus := LeasingSetup."Status - Surrender"
                    else
                        if AssetPostingType = AssetPostingType::"Write off" then
                            ToStatus := LeasingSetup."Status - Write Off";

        //BA221212
        if Contr."Refinanced by Contr. No." <> '' then
            ToStatus := LeasingSetup."Status - Closed Refinanced";
        //--//

        if AssetPostingType in [AssetPostingType::Repossession, AssetPostingType::Surrender, AssetPostingType::"Write off"] then begin
            if LAsset."Asset No." <> '' then begin
                LAsset.VALIDATE("OL Asset Returned Date", PostingDate);
                LAsset.Modify();

                FA.GET(LAsset."Asset No.");
                FA."FA Subclass Code" := LeasingSetup."FA - Inventory Subclass Code";
                FA.modify;


            end;
        end;

        if AssetPostingType in [AssetPostingType::"Matured -Paid in Full", AssetPostingType::"Early Pay Out", AssetPostingType::" ",
        AssetPostingType::"Early Pay Out – Paid in Full"] then begin
            if FA.GET(LAsset."Asset No.") then begin
                FA."FA Subclass Code" := LeasingSetup."FA - Customer Subclass Code";
                FA.VALIDATE("PYA Asset Status Code", LeasingSetup."FA Status - Sold");
                FA.Modify();
            end;
        end;

        if (ToStatus = LeasingSetup."Status - Settled in full") or (ToStatus = LeasingSetup."Status - Paid in Full") then begin
            if FA.GET(LAsset."Asset No.") then begin
                FA."FA Subclass Code" := LeasingSetup."FA - Customer Subclass Code";
                FA.VALIDATE("PYA Asset Status Code", LeasingSetup."FA Status - Sold");
                FA.Modify();
            end;
        end;
        //--//

        IF StatusMgt.StatusFlowCheck(ToStatus, Contr."Status Code") THEN BEGIN
            Contr."Status Code" := ToStatus;
            Contr.MODIFY(TRUE);
            Contr.VALIDATE("PYA Asset Status Code", ToStatus);
        END;

        //BA221212 - Don't post any entry for refinanced 
        if Contr."Refinanced by Contr. No." <> '' then
            exit;
        //--//
        // <<
        W.UPDATE(1, STRSUBSTNO('%1 %2', Contr."Contract No.", 'Close Contract'));//DV180301

        /*DV170818*/
        LeasingPostingSetup.GetSetupRec(LeasingPostingSetup, Contr."Contract No.");
        LeasingPostingSetupTerm.S4LNAGetTermSetupRec(LeasingPostingSetupTerm, Contr."Contract No.");
        SourceCodeSetup.GET;
        Contr.GetNewestSchedule(Sched);
        IF Contr."Contract No." <> '' THEN
            PostingDocNo := Contr."Contract No." + '99';
        //IF PostingDocNo = '' THEN
        //    PostingDocNo := NoSeriesMgt.GetNextNo(LeasingSetup."Termination No. Series", PostingDate, TRUE);

        IF PostingDate = 0D THEN
            PostingDate := WORKDATE;

        //JM180814++

        IF FinProd.GET(Contr."Financial Product") THEN
            // IF FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::"Financial Lease" THEN BEGIN
            if (FinProd."Accounting Group" <> FinProd."Accounting Group"::"Lease Inventory") and
                 (FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::Loan) then begin
                LAsset.RESET;
                LAsset.SETRANGE("Contract No.", Contr."Contract No.");
                IF LAsset.FINDFIRST THEN BEGIN
                    //New Posting
                    schedLine.RESET;
                    schedLine.SETRANGE("Contract No.", Contr."Contract No.");
                    schedLine.SETRANGE("Schedule No.", Sched."Schedule No.");
                    schedLine.SETRANGE("Version No.", Sched."Version No.");
                    schedLine.SETFILTER("Entry Type", '%1', schedLine."Entry Type"::Installment);
                    IF schedLine.FINDFIRST THEN BEGIN

                        IF schedLine.Date < CALCDATE('+1Y', PostingDate) THEN//DV180821
                        BEGIN
                            /*  //Extended Warranty BA220406 - commented
                              InsAmt := 0;
                              ContractInsurance.RESET;
                              ContractInsurance.SETRANGE("Contract No.", Contr."Contract No.");
                              ContractInsurance.SETRANGE("Schedule No.", Sched."Schedule No.");
                              ContractInsurance.SETRANGE("Version No.", Sched."Version No.");
                              IF ContractInsurance.FINDFIRST THEN
                                  REPEAT
                                      InsuranceProduct.GET(ContractInsurance."Insurance Product Code");
                                      InsAmt += GetGLBalance(Contr."Contract No.", InsuranceProduct."Revenue G/L Acc.");
                                  UNTIL ContractInsurance.NEXT = 0;
                              Amt := InsAmt;
                              CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", InsuranceProduct."Revenue G/L Acc.",
                              STRSUBSTNO(LText01, GLAccount.Name, Contr."Contract No."),
                              -Amt, '', '', '', FALSE);
                              Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                              PostJnl(Jnl);

                            CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                            STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                            Amt, '', '', '', FALSE);
                            Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                            Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";
                            PostJnl(Jnl);
                           */
                            //BA220609
                            if AssetPostingType IN [AssetPostingType::Repossession, AssetPostingType::Surrender, AssetPostingType::"Write off"] then begin  //BA220609
                                case FinProd."Accounting Group" of
                                    FinProd."Accounting Group"::"Gross Receivable":
                                        begin
                                            LeasingPostingSetup.testfield("Gross Receivable (BS)");
                                            LeasingPostingSetup.TestField("Op. Lease Inventory (BS) - Tm"); //BA221011
                                            LeaseReceivableAcc := LeasingPostingSetup."Gross Receivable (BS)";

                                            Amt := GetGLBalance(Contr."Contract No.", LeaseReceivableAcc);

                                            if FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::"Hire Purchase" then begin
                                                CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                                STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                Amt, '', '', '', FALSE);
                                                Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                                                Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inventory (BS) - Tm"; //BA221011
                                                //LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                                PostJnl(Jnl);
                                            end else
                                                if FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::"Hire Purchase" then begin
                                                    //BA220428
                                                    LeasingPostingSetup.TestField("HP Asset Clearing Account");

                                                    CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                                       STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                              Amt, '', '', '', FALSE);
                                                    Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                                                    Jnl."Posting Group" := LeasingPostingSetup."HP Asset Clearing Account";
                                                    PostJnl(Jnl);
                                                    //--//
                                                end;

                                            CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                              STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                               -Amt, '', '', '', FALSE);
                                            Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                            PostJnl(Jnl);


                                        end;
                                    FinProd."Accounting Group"::"Net Receivable":
                                        begin
                                            LeasingPostingSetup.testfield("Net Receivable (BS)");
                                            LeaseReceivableAcc := LeasingPostingSetup."Net Receivable (BS)";

                                            Amt := GetGLBalance(Contr."Contract No.", LeaseReceivableAcc);

                                            if FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::"Hire Purchase" then begin
                                                CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                                STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                Amt, '', '', '', FALSE);
                                                Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                                                Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inventory (BS) - Tm";// BA221011
                                                                                                                           // LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                                PostJnl(Jnl);
                                            end
                                            else
                                                if FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::"Hire Purchase" then begin
                                                    //BA220428
                                                    LeasingPostingSetup.TestField("HP Asset Clearing Account");
                                                    CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                                       STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                              Amt, '', '', '', FALSE);
                                                    Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                                                    Jnl."Posting Group" := LeasingPostingSetup."HP Asset Clearing Account";
                                                    PostJnl(Jnl);
                                                    //--//
                                                end;
                                            CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                            STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                             -Amt, '', '', '', FALSE);
                                            Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                            PostJnl(Jnl);
                                        end;
                                end;

                                //Asset part
                                //Unearned interest part
                                //Amt := GetGLBalance(Contr."Contract No.", LeasingPostingSetup."Accrued Interest (PL)");
                                Amt := GetGLBalance(Contr."Contract No.", LeasingPostingSetup."Unearned Interest (BS)");//DV180821
                                CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."Unearned Interest (BS)",
                                STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                -Amt, '', '', '', FALSE);
                                Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                PostJnl(Jnl);

                                //CreateJnl(Jnl,Jnl."Account Type"::"G/L Account",LeasingPostingSetup."Accrued Interest (PL)",
                                if FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::"Hire Purchase" then begin
                                    CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",//DV180821
                                    STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                    Amt, '', '', '', FALSE);
                                    Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                                    Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inventory (BS) - Tm"; //BA221011
                                    //LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                    PostJnl(Jnl);
                                end
                                else
                                    if FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::"Hire Purchase" then begin
                                        //BA220428
                                        LeasingPostingSetup.TestField("HP Asset Clearing Account");
                                        CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                                     STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                            Amt, '', '', '', FALSE);
                                        Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                                        Jnl."Posting Group" := LeasingPostingSetup."HP Asset Clearing Account";
                                        PostJnl(Jnl);
                                        //--//
                                    end;
                                //BA221110-  Updating posting group after posting
                                if AssetPostingType in [AssetPostingType::Repossession, AssetPostingType::Surrender, AssetPostingType::"Write off"] then begin
                                    if LAsset."Asset No." <> '' then begin
                                        FA.GET(LAsset."Asset No.");
                                        //BA221110-Updating posting group
                                        LeasingPostingSetup.GetSetupRec(LeasingPostingSetup, Contr."Contract No.");
                                        LeasingPostingSetup.TestField("Op. Lease Inventory (BS) - Tm");
                                        FA."FA Posting Group" := LeasingPostingSetup."Op. Lease Inventory (BS) - Tm";
                                        FA.modify;

                                        FaDep.RESET;
                                        FaDep.SETRANGE("FA No.", FA."No.");
                                        IF FaDep.FINDFIRST THEN BEGIN
                                            FaDep."FA Posting Group" := LeasingPostingSetup."Op. Lease Inventory (BS) - Tm";// "Op. Lease Inventory (BS) – Tm";
                                            FaDep.MODIFY;
                                        END;
                                    end;
                                end;
                                //--//
                            end //Assetposting type Pay out
                            else
                                if AssetPostingType in [AssetPostingType::"Matured -Paid in Full", AssetPostingType::"Early Pay Out", AssetPostingType::"Early Pay Out – Paid in Full", AssetPostingType::" "] then begin
                                    case FinProd."Accounting Group" of
                                        FinProd."Accounting Group"::"Gross Receivable":
                                            begin
                                                LeasingPostingSetup.testfield("Gross Receivable (BS)");
                                                LeasingPostingSetup.testfield("Unearned Interest (BS)");

                                                LeaseReceivableAcc := LeasingPostingSetup."Gross Receivable (BS)";

                                                Amt := GetGLBalance(Contr."Contract No.", LeaseReceivableAcc);
                                                UnEarnedInc := GetGLBalance(Contr."Contract No.", LeasingPostingSetup."Unearned Interest (BS)");//DV180821

                                                //post customer receivable
                                                //BA220727
                                                if not FinProd."Post Gain/Loss" then begin
                                                    CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                                       STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                              Amt - ABS(UnEarnedInc), '', '', '', FALSE);

                                                    Jnl."Posting Group" := FinProd."Posting Group for Active Contr";
                                                    PostJnl(Jnl);
                                                end else begin

                                                    if Currency.Get(Contr.CCY) then
                                                        RoundingPrecision := Currency."Amount Rounding Precision"
                                                    else
                                                        RoundingPrecision := GLSetup."Amount Rounding Precision";


                                                    CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                                               STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                                                   -cbal.CurrentReceivable, '', '', '', FALSE);

                                                    Jnl."Posting Group" := FinProd."Posting Group for Active Contr";
                                                    PostJnl(Jnl);

                                                    //post gain loss
                                                    GainLossAmount := 0;
                                                    if ABS((-Amt) + (-UnEarnedInc) + (-CBal.CurrentReceivable)) = ABS(CBal."Pay-Out Total To Pay") then
                                                        GainLossAmount := CBal."Pay-Out Total To Pay"
                                                    else
                                                        GainLossAmount := CBal."Pay-Out Total To Pay" - Round(CBal."Accrued Total Interest", RoundingPrecision);

                                                    GainLossAmount := round(GainLossAmount, RoundingPrecision);

                                                    LeasingPostingSetup.TestField("Gain/Loss on Early Settlement");
                                                    CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."Gain/Loss on Early Settlement",
                                                   STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                    GainLossAmount, '', '', '', FALSE);//(-Amt) + (-UnEarnedInc) + (-CBal.CurrentReceivable)
                                                    Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                                    PostJnl(Jnl);

                                                end;
                                                //--//


                                                CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."Unearned Interest (BS)",
                                                STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                -UnEarnedInc, '', '', '', FALSE);
                                                //Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                                PostJnl(Jnl);


                                                CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                                  STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                   -Amt, '', '', '', FALSE);
                                                //Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                                PostJnl(Jnl);


                                                //--//
                                            end;
                                        FinProd."Accounting Group"::"Net Receivable":
                                            begin
                                                LeasingPostingSetup.testfield("Net Receivable (BS)");
                                                LeaseReceivableAcc := LeasingPostingSetup."Net Receivable (BS)";

                                                Amt := GetGLBalance(Contr."Contract No.", LeaseReceivableAcc);

                                                CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                              STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                              Amt, '', '', '', FALSE);

                                                Jnl."Posting Group" := FinProd."Posting Group for Active Contr";//DV171025
                                                PostJnl(Jnl);


                                                CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                                STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                 -Amt, '', '', '', FALSE);
                                                Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                                PostJnl(Jnl);


                                            end;


                                    end;
                                    //BA221110 
                                    if AssetPostingType = AssetPostingType::"Early Pay Out – Paid in Full" then begin
                                        EarlyPayout.reset;
                                        EarlyPayout.SetRange("Contract No.", Contr."Contract No.");
                                        EarlyPayout.setrange("Schedule No.", Sched."Schedule No.");
                                        EarlyPayout.SetRange("Version No.", Sched."Version No.");
                                        if EarlyPayout.FindFirst() then begin
                                            if EarlyPayout."Early Termination Fee Payable" <> 0 then begin

                                                LeasingPostingSetup.TestField("Installment Fee Income (PL)");
                                                CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                                                                          STRSUBSTNO(EarlyTermFeeLbl, Contr."Contract No."),
                                                                                          EarlyPayout."Early Termination Fee Payable", '', '', '', FALSE);

                                                Jnl."Posting Group" := FinProd."Posting Group for Active Contr";
                                                PostJnl(Jnl);


                                                CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."Installment Fee Income (PL)",
                                                STRSUBSTNO(EarlyTermFeeLbl, Contr."Contract No."),
                                                 -EarlyPayout."Early Termination Fee Payable", '', '', '', FALSE);

                                                PostJnl(Jnl);
                                            end;
                                        end;
                                    end;
                                    //--//
                                end; //end Asset
                                     //more than a year past to contract
                        END;
                    END;
                END;
            END ELSE BEGIN
                //Keep actual code for non capital leases
                LAsset.RESET;
                LAsset.SETRANGE("Contract No.", Contr."Contract No.");
                LAsset.SetFilter("Asset No.", '<>%1', ''); //BA220501
                IF LAsset.FINDFIRST THEN
                    REPEAT
                        LeasingPostingSetupTerm.TestField("Op. Lease Inventory (BS) - Tm");
                        FA.GET(LAsset."Asset No.");
                        FA.CALCFIELDS("PYA Book Value");
                        BookVal := FA."PYA Book Value";//DV180405
                                                       /*  W.UPDATE(1, STRSUBSTNO('%1 %2', LAsset."Asset No.", 'Acquisition Cost'));//DV180301

                                                         CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                                                   STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                                                   -FA."S4L Acquisition Cost", '', '', '', FALSE);
                                                         Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                                                         Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";//DV171025
                                                         PostJnl(Jnl);
                                                         */

                        FA.GET(LAsset."Asset No.");
                        //BA211105 - Changed to "Op. Lease Inventory (BS) – Tm" from "Op. Lease Inv. (Post. Gr.)"
                        FA."FA Posting Group" := LeasingPostingSetupTerm."Op. Lease Inventory (BS) - Tm";//  "Op. Lease Inventory (BS) – Tm";//DV180405
                                                                                                         //--//                                                                          //      FA."Contract Term Date" := PostingDate;//DV170823
                        FA.MODIFY;
                        FaDep.RESET;
                        FaDep.SETRANGE("FA No.", FA."No.");
                        IF FaDep.FINDFIRST THEN BEGIN
                            //BA211105 - Changed to "Op. Lease Inventory (BS) – Tm" from "Op. Lease Inv. (Post. Gr.)"
                            FaDep."FA Posting Group" := LeasingPostingSetupTerm."Op. Lease Inventory (BS) - Tm";// "Op. Lease Inventory (BS) – Tm";
                                                                                                                //--//
                            FaDep.MODIFY;
                        END;
                        /*DV180212*/
                        IF FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::"Operating Lease" THEN BEGIN
                            FaDep.RESET;
                            FaDep.SETRANGE("FA No.", FA."No.");
                            IF FaDep.FINDFIRST THEN
                                FaDep.CALCFIELDS("Salvage Value", Depreciation, "Acquisition Cost");
                        END;


                        //--//
                        W.UPDATE(1, STRSUBSTNO('%1 %2', LAsset."Asset No.", 'Book Value'));//DV180301

                        CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                  STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                  BookVal, '', '', '', FALSE);
                        Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                        //BA211105 - Changed to "Op. Lease Inventory (BS) – Tm" from "Op. Lease Inv. (Post. Gr.)"
                        Jnl."Posting Group" := LeasingPostingSetupTerm."Op. Lease Inventory (BS) - Tm";// "Op. Lease Inventory (BS) – Tm";//DV171025
                                                                                                       //--//
                        PostJnl(Jnl);

                        //BA220526 - To prevent bookvalue from going into a negative figure
                        W.UPDATE(1, STRSUBSTNO('%1 %2', LAsset."Asset No.", 'Acquisition Cost'));

                        CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                  STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                  -BookVal, '', '', '', FALSE);
                        Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                        Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";
                        PostJnl(Jnl);
                        //--//

                        W.UPDATE(1, STRSUBSTNO('%1 %2', LAsset."Asset No.", 'Depreciation'));//DV180301

                        CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                                 STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                                -FaDep.Depreciation, '', '', '', FALSE);
                        Jnl."FA Posting Type" := Jnl."FA Posting Type"::Depreciation;
                        Jnl."Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";
                        PostJnl(Jnl);

                        //BA220527 - Post Salvage value first
                        if FaDep."Salvage Value" <> 0 then begin
                            FATmpl.SETRANGE(Recurring, FALSE);
                            FATmpl.FINDFIRST;
                            FaTBatch.SETRANGE("Journal Template Name", FATmpl.Name);
                            FaTBatch.FINDFIRST;
                            CLEAR(FaJnl);
                            /*DV180405*/
                            FaJnl.SETRANGE("Journal Template Name", FATmpl.Name);
                            FaJnl.SETRANGE("Journal Batch Name", FaTBatch.Name);
                            IF FaJnl.FINDLAST THEN
                                LAsset."Line No." := FaJnl."Line No." + 10000;
                            /*---*/
                            FaJnl.VALIDATE("Journal Template Name", FATmpl.Name);
                            FaJnl.VALIDATE("Journal Batch Name", FaTBatch.Name);
                            FaJnl."Line No." := LAsset."Line No.";//DV180405
                            FaJnl."Document No." := PostingDocNo;//DV180405
                            FaJnl.VALIDATE("FA No.", LAsset."Asset No.");
                            FaJnl.VALIDATE("FA Posting Date", PostingDate);
                            FaJnl.VALIDATE("Posting Date", PostingDate);//DV180621
                            FaJnl.VALIDATE("FA Posting Type", FaJnl."FA Posting Type"::"Salvage Value");
                            FaJnl.VALIDATE(Amount, -FaDep."Salvage Value");
                            //FaJnl.VALIDATE("Salvage Value",FaJnl.Amount);
                            FaJnl.SETRECFILTER;
                            FaJnl.INSERT;

                            CLEAR(FAJnlPostLine);
                            FAJnlPostLine.FAJnlPostLine(FaJnl, FALSE);
                            FaJnl.DELETE;//DV180621
                        end;

                    // Add FAGNL posting + value for salvage value T5621
                    /*---*/
                    UNTIL LAsset.NEXT = 0;
            END;
        /*DV190212*/
        //Security Deposit
        if Sched."NA Refundable Security Deposit" <> 0 then begin

            GLSetup.get;
            if Currency.Get(Contr.CCY)
            then
                RoundingPrecision := Currency."Amount Rounding Precision"
            else
                RoundingPrecision := GLSetup."Amount Rounding Precision";

            LeasingPostingSetup.TestField("NA Ref Security Deposit");
            // IsFinancedInclVAT := sched."Amounts Including VAT";

            if sched."Amounts Including VAT" then begin
                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                ProdSalesVATgr := LeasingPostingSetup."NA Ref Sec. Deposit Tax Grp";
                AmtInclSalesVAT := Sched."NA Refundable Security Deposit";
                AmtExVAT := Round(Sched."NA Refundable Security Deposit" / GetVATfactor(BusSalesVATgr, ProdSalesVATgr), RoundingPrecision);
            end else begin
                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                ProdSalesVATgr := LeasingPostingSetup."NA Ref Sec. Deposit Tax Grp";
                AmtInclSalesVAT := round(Sched."NA Refundable Security Deposit" * GetVATfactor(BusSalesVATgr, ProdSalesVATgr), RoundingPrecision);
                AmtExVAT := Sched."NA Refundable Security Deposit";
            end;

            CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                                        STRSUBSTNO(Text020, Sched."Contract No."), -AmtInclSalesVAT, '', '', '', false);
            PostJnl(Jnl);
            CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."NA Ref Security Deposit",
                  STRSUBSTNO(Text020, Sched."Contract No."), AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, false);
            PostJnl(Jnl);
        end;
        /* baba
        //BA210322
        // NAContractMgt.OnBeforeTaxCalculate(Sched, schedLine, LeasingPostingSetup."NA Ref Sec. Deposit Tax Grp", true, Contr);

        AmountToPost := ROUND(SalesTaxCalculate.CalculateTax(Contr."NA Tax Area Code", LeasingPostingSetup."NA Ref Sec. Deposit Tax Grp", Contr."NA Tax Liable", PostingDate, Sched."NA Refundable Security Deposit", 1, 1), 0.01);
        AmountToPost += ROUND(Sched."NA Refundable Security Deposit", 0.01);
        CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."NA Ref Security Deposit",
                  STRSUBSTNO(Text020, Sched."Contract No."),
                  AmountToPost,
                  'Sale', Contr."NA Tax Area Code", LeasingPostingSetup."NA Ref Sec. Deposit Tax Grp", Contr."NA Tax Liable");
        */
        // PostJnl(Jnl);
        /* baba
            CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                      STRSUBSTNO(Text020, Sched."Contract No."),
                      -AmountToPost,
                      '', Contr."NA Tax Area Code", LeasingPostingSetup."NA Ref Sec. Deposit Tax Grp", Contr."NA Tax Liable");//DV190401
           */
        //PostJnl(Jnl);
        /*---*/
        /*DV20190201*/

        IF BalanceTot <> 0 THEN
            ERROR(Text241 + BalanceMsg, BalanceTot);

        //Contr.GET(Contr."Contract No.");//>>PA150528 Sys aid issue - 17615
        Contr.Status := Contr.Status::"Closed Contract";
        Contr."NA Termination Posted Date" := Sched."Termination Posted Date"; //JM190327
        W.CLOSE;//DV180301
        Contr.MODIFY;

    end;


    procedure GetVATfactor(BusinessVATGroup: Code[20]; ProductVATGroup: Code[20]) VATfactor: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATPostingSetup.get(BusinessVATGroup, ProductVATGroup)
            then
            VATfactor := 1 + VATPostingSetup."VAT %" / 100
        else
            VATfactor := 1;

        exit(VATfactor);
    end;

    procedure CreateJnl(var Jnl: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20];
                                                                          Descr: Text;
                                                                          Amt: Decimal;
                                                                          PostingType: Text[30];
                                                                          TaxAreaCode: Code[20];
                                                                          TaxGroup: Code[20];
                                                                          TaxLiable: Boolean)
    begin
        // use globals: Contr, Sched, and setup tables
        IF Amt = 0 THEN BEGIN//DV170815
            Jnl.INIT;
            exit;
        END;
        Jnl.INIT;
        Jnl."Account Type" := AccType;
        Jnl.VALIDATE("Account No.", AccNo);
        Jnl.VALIDATE("Posting Date", PostingDate);
        //JM170726++
        //Jnl."Document Type" := 0;
        Jnl."Document Type" := Jnl."Document Type"::Invoice;
        //JM170726--
        Jnl."Document No." := PostingDocNo;
        Jnl.Description := COPYSTR(Descr, 1, MAXSTRLEN(Jnl.Description));
        // UpdateJnlCurrency(Jnl);              // CCY
        // CCY Jnl.VALIDATE(Amount,Amt);

        Jnl."ACCOUNT No." := Contr."Customer No.";
        Jnl."PYA Contract No" := Sched."Contract No.";
        //Jnl."S4L Schedule No." := Sched."Schedule No.";
        //Jnl."S4L Schedule Line No." := 0;
        //Jnl."External Document No." := Contr."NA External Document No.";//DV170331
        //UpdateJnlCurrency(Jnl);              // CCY
        //Jnl.VALIDATE("S4L Amount (CCY)", Amt);    // CCY

        Jnl."PYA Installment Part" := 0;
        Jnl."Source Code" := SourceCodeSetup."PYA Lease Termination";
        //Jnl."S4L Allow the same doc. No." := TRUE;
        Jnl."System-Created Entry" := TRUE;

        Jnl."Dimension Set ID" := Contr."Dimension Set ID";
        DimMgt.UpdateGlobalDimFromDimSetID(Jnl."Dimension Set ID", Jnl."Shortcut Dimension 1 Code", Jnl."Shortcut Dimension 2 Code");

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
                    Jnl."Gen. Posting Type" := Jnl."Gen. Posting Type"::Purchase;
                    Jnl."VAT Bus. Posting Group" := TaxAreaCode;
                    Jnl.Validate("VAT Prod. Posting Group", TaxGroup);
                end;
            'Sale':
                begin
                    Jnl."Gen. Posting Type" := Jnl."Gen. Posting Type"::Sale;
                    Jnl."VAT Bus. Posting Group" := TaxAreaCode; //KS210104
                    Jnl.Validate("VAT Prod. Posting Group", TaxGroup);
                end;
        end;

    end;

    procedure PostJnl(var Jnl: Record "Gen. Journal Line")
    begin
        IF Jnl.Amount = 0 THEN
            EXIT;
        AddToBalanceMsg(Jnl.Description, Jnl.Amount);
        cdGenJnlPost.RUN(Jnl);
    end;

    procedure AddToBalanceMsg(Desc: Text; Amt: Decimal)
    var
        LText240: Label ' %1 = %2 \';
    begin
        //compose message for posting consistency check (zero balance)
        BalanceMsg += STRSUBSTNO(LText240, Desc, Amt);
        BalanceTot += Amt;
    end;

    procedure UnReturn()
    var
        LAsset: Record "S4LA Asset";
        Jnl: Record "Gen. Journal Line";
        FA: Record "Fixed Asset";
        LText01: Label '%1 Unreturned, Back on contract %2';
    begin
        LeasingPostingSetup.GetSetupRec(LeasingPostingSetup, Contr."Contract No.");
        LeasingPostingSetupTerm.S4LNAGetTermSetupRec(LeasingPostingSetupTerm, Contr."Contract No.");
        SourceCodeSetup.GET;
        Contr.GetNewestSchedule(Sched);
        IF Contr."Contract No." <> '' THEN
            PostingDocNo := Contr."Contract No." + '99';
        //IF PostingDocNo = '' THEN
        //    PostingDocNo := NoSeriesMgt.GetNextNo(LeasingSetup."Termination No. Series", PostingDate, TRUE);

        IF PostingDate = 0D THEN
            PostingDate := WORKDATE;

        LAsset.RESET;
        LAsset.SETRANGE("Contract No.", Contr."Contract No.");
        IF LAsset.FINDFIRST THEN
            REPEAT
                FA.GET(LAsset."Asset No.");
                FA.CALCFIELDS("PYA Book Value");

                CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                          STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                          FA."PYA Book Value", '', '', '', FALSE);
                Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                Jnl."Posting Group" := FA."FA Posting Group";
                PostJnl(Jnl);

                CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", LAsset."Asset No.",
                          STRSUBSTNO(LText01, LAsset."Asset Description", Contr."Contract No."),
                          -FA."PYA Book Value", '', '', '', FALSE);
                Jnl."FA Posting Type" := Jnl."FA Posting Type"::"Acquisition Cost";
                //BA211105 - Changed to "Op. Lease Inventory (BS) – Tm" from "Op. Lease Inv. (Post. Gr.)"
                Jnl."Posting Group" := LeasingPostingSetupTerm."Op. Lease Inventory (BS) - Tm";// "Op. Lease Inventory (BS) – Tm";
                                                                                               //--//
                PostJnl(Jnl);
                FA.GET(LAsset."Asset No.");
                FA."FA Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)";
                //  FA."Contract Term Date" := PostingDate;//DV170823
                FA.MODIFY;
                FaDep.RESET;
                FaDep.SETRANGE("FA No.", FA."No.");
                IF FaDep.FINDFIRST THEN BEGIN
                    //BA211105 - Changed to "Op. Lease Inventory (BS) – Tm" from "Op. Lease Inv. (Post. Gr.)"
                    FaDep."FA Posting Group" := LeasingPostingSetupTerm."Op. Lease Inventory (BS) - Tm";// "Op. Lease Inventory (BS) – Tm";                                                                                                //--//
                    FaDep.MODIFY;
                END;
            UNTIL LAsset.NEXT = 0;

        IF BalanceTot <> 0 THEN
            ERROR(Text241 + BalanceMsg, BalanceTot);

        Contr.Status := Contr.Status::"Closed Contract";
        Contr.MODIFY;
    end;

    procedure GetGLBalance(ContractNo: Code[20]; GlAccNo: Code[20]): Decimal
    begin
        //JM180414
        GLAccount.GET(GlAccNo);
        //GLAccount.SETFILTER("S4LA Contract Filter", ContractNo);
        GLAccount.CALCFIELDS(Balance);
        EXIT(GLAccount.Balance);
    end;


    /*    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NA Contract Closing", 'S4LNA_OnCode', '', false, false)]
        local procedure S4LNA_OnCode(var Contract: Record "S4LA Contract"; var isHandled: Boolean)
        var
            ContractClosing: Codeunit "NA Contract Closing";
        begin
            ContractClosing.Run(Contract);
            isHandled := true;
        end;
    */
    //PYAS-176
    procedure SkipDatePage(Pdate: Date; SkipDate: Boolean)
    begin
        PostingDate := pdate;
        SkipDateDialogPage := SkipDate;
    end;
    //--//
}
