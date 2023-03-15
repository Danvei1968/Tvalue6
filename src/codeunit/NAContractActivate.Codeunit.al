codeunit 17022112 "NA Contract Activate"
{
    procedure CreateFixedAsset(var Asset: Record "S4LA Asset")
    var
        AssetCategory: Record "S4LA Asset Category";
        FA: Record "Fixed Asset";
        Contract2: Record "S4LA Contract";
        Sched: Record "S4LA Schedule";
        LeasAssetMgmt: Codeunit "S4LA Asset Mgt";
        "-- EN171124": Integer;
        //ApplicationAssetInsPolicy: Record "Application Asset Ins. Policy"; BA220617 - Object removed
        AssetInsurancePolicy: Record "S4LA Asset Ins. Policy";
    begin
        //Creates FA, or maps to existing FA.
        /*DV170321*/
        // IF Asset."Asset No." <> '' THEN //EN171208
        //  Asset."Asset No." := Asset.ChoosePrimaryID();
        IF Asset."Asset No." = '' THEN BEGIN
            FA.INSERT(TRUE);
            Asset."Asset No." := FA."No.";
        END;
        /*---*/


        //EN200221 >>
        //IF Asset."Asset No." <> '' THEN //EN171208
        if Asset."Asset No." = '' then //EN171208
                                       //EN200221 <<
            Asset."Asset No." := Asset.ChoosePrimaryID();

        //KS160329
        if Asset."Asset No." = '' then begin
            FASetup.Get;
            FASetup.TestField("Fixed Asset Nos.");
            Asset."Asset No." := NoSeriesMgt.GetNextNo(FASetup."Fixed Asset Nos.", WorkDate, true);
        end;
        //---

        if FA.Get(Asset."Asset No.") then begin
            //===== check existing FA

            //----- if not already on active contract
            if FA."PYA Contract No" <> '' then
                if Contract2.Get(FA."PYA Contract No") then
                    if Contract2.Status = Contract2.Status::Contract then
                        //BA210607 -- only throw error if refin no <> asset.contract no
                        IF Contr."Refinance of Contr. No." <> FA."PYA Contract No" then
                            Error(Text201, FA."No.", FA."PYA Contract No");

            //LeasAssetMgmt.UpdateFAfromAsset(Asset, FA); //----- Update existing FA, relate FA to Contract

        end else begin
            //>>AY150726
            FA.Reset;
            //FA.SetRange("S4L Primary Asset Id", Asset."Asset No.");
            fa.SetRange("No.", Asset."Asset No.");
            if FA.FindFirst then begin

                //----- if not already on active contract
                if FA."PYA Contract No" <> '' then
                    //PYA:: if FA."S4L Contract No." <> Asset."Contract No." then //KS180326 Asset Variation (allow multiple asset recs on the same contract)
                        if Contract2.Get(FA."PYA Contract No") then
                        if Contract2.Status = Contract2.Status::Contract then
                            //BA210607 -- only throw error if refin no <> asset.contract no
                            IF Contr."Refinance of Contr. No." <> FA."PYA Contract No" then
                                Error(Text201, FA."No.", FA."PYA Contract No");

                //LeasAssetMgmt.UpdateFAfromAsset(Asset, FA); //----- Update existing FA, relate FA to Contract
            end else
                //<<AY150726
                IF Asset."Asset No." = '' THEN//DV170321
                    LeasAssetMgmt.CreateFAfromAsset(Asset, false);   //Create new FA

        end;
        /*DV170817*/
        //BA210602 - ADD TRIM
        FA."PYA Trim" := Asset."NA Trim";

        FA.BuildDescription;
        FA.MODIFY;
        Asset."Asset Description" := FA.Description;
        /*---*/

        //>>EN171124
        //Transfer Asset Insurance policies
        /* BA220617 - Object removed
        ApplicationAssetInsPolicy.SetRange("Contract No.", Asset."Contract No.");
        ApplicationAssetInsPolicy.SetRange("Asset Line No.", Asset."Line No.");
        if ApplicationAssetInsPolicy.FindSet then
            repeat
                AssetInsurancePolicy.Init;
                AssetInsurancePolicy.TransferFields(ApplicationAssetInsPolicy);
                AssetInsurancePolicy."Asset No." := Asset."Asset No.";
                AssetInsurancePolicy."Policy No." := ApplicationAssetInsPolicy."Policy No.";
                AssetInsurancePolicy.Insert;
            until ApplicationAssetInsPolicy.Next = 0;
            */
        //<<EN171124

        /*PYA*/
        Asset."Acquisition Source" := Asset."Acquisition Source"::Stock;//DV170815
        Asset."Supplier No." := '';//DV170815
        Asset."Supplier Name" := '';//DV170815
                                    /*---*/

        Asset.Modify;
    end;

    local procedure AddToBalanceMsg(Desc: Text; Amt: Decimal; AmtLCY: Decimal)
    begin
        //compose message for posting consistency check (zero balance)
        BalanceMsg += StrSubstNo(Text240, Desc, Amt);
        BalanceLCYMsg += StrSubstNo(Text240, Desc, AmtLCY);
        BalanceTotLCY += AmtLCY;
        BalanceTot += Amt;
    end;

    procedure CreateJnl(var Jnl: Record "Gen. Journal Line"; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20];
                                                                               Descr: Text;
                                                                               Amt: Decimal;
                                                                               PostingType: Text[30];
                                                                               TaxAreaCode: Code[20];
                                                                               TaxGroup: Code[20];
                                                                               TaxLiable: Boolean);
    var
        sched: Record "S4LA schedule";
        SourceCodeSetup: RECORD "Source Code Setup";
        PostingDate: Date;
        PostingDocNo: Code[20];
        DimMgt: Codeunit DimensionManagement;
    begin
        SourceCodeSetup.GET;
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

        //EN190130 >>
        if Jnl."Account Type" in [Jnl."Account Type"::Customer, Jnl."Account Type"::Vendor] then
            Jnl.Validate("Payment Method Code", Contr."Payment Method Code");
        //EN190130 <<
        Jnl."ACCOUNT No." := Contr."Customer No.";
        Jnl."PYA Contract No" := Sched."Contract No.";
        //Jnl."Schedule No." := Sched."Schedule No.";
        //Jnl."PYA Schedule Line No." := 0;
        //Jnl."External Document No." := Contr."S4LA External Document No.";//DV170331

        //UpdateJnlCurrency(Jnl);              // CCY
        //Jnl.Validate("S4L Amount (CCY)", Amt);    // CCY

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
        Contr: Record "S4LA Contract";
        FASetup: Record "FA Setup";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text201: Label 'Asset %1 is being used in Active Contract No. %2.';
        cdGenJnlPost: Codeunit "Gen. Jnl.-Post";
        BalanceMsg: Text;
        Text240: Label ' %1 = %2 \';
        BalanceLCYMsg: Text;
        BalanceTotLCY: Decimal;
        BalanceTot: Decimal;
}