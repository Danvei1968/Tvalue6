codeunit 17022180 "PYA Codeunit Events"
{ }
/*
    [IntegrationEvent(false, false)]
    local procedure SetPYADocFiller(var DocRec: record "S4LA Document"; pServerFileName: Text; pReadOnly: Boolean; var IsHandled: Boolean)
    begin
    end;  
        [EventSubscriber(ObjectType::Codeunit, Codeunit::LogInManagement, 'OnBeforeCompanyOpen', '', false, false)]
        local procedure CheckNbrOfUsers()
        var
            locUser: Record "User Setup";
            UserSetup: record "User Setup";
            locActiveSession: Record "Active Session";
            LicenseErrorMsg: Label 'Your program license does not permit more users to work simultaneously. Wait until another user has stopped using the program. Contact your system manager if you want to allow more simultaneous users on your system';
            TerminateUserTxt: label 'User ID %1 is already logged into the system. Would you like to terminate that session and continue logging in?\Terminating the session could result in lost data for the session currently logged in. Continue?';

        begin
            //TG191203
            //BA Feb 21. Moved the field to User Setup because table extension cannot be created for User table.
            if UserSetup.GET(UserId) then begin
                IF NOT UserSetup.Multilogin THEN BEGIN
                    locActiveSession.RESET;
                    locActiveSession.SETRANGE("User ID", USERID);
                    locActiveSession.SETFILTER("Client Type", '<>%1&<>%2&<>%3&<>%4', locActiveSession."Client Type"::"Web Service", locActiveSession."Client Type"::"Management Client",
                    locActiveSession."Client Type"::NAS, locActiveSession."Client Type"::"Client Service");
                    //TG200903
                    IF locActiveSession.FINDSET THEN
                        if GuiAllowed then // BA210416 - added to be able publish without callback error.
                            IF CONFIRM(TerminateUserTxt, FALSE, UserSetup."User ID") THEN BEGIN
                                REPEAT
                                    STOPSESSION(locActiveSession."Session ID");
                                UNTIL locActiveSession.NEXT = 0;
                            END ELSE
                                //{---}
                                ERROR(LicenseErrorMsg);
                END;
            end;

        end;
    
    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnCheckInterestModified', '', false, false)]
    procedure CheckInterestModified(var Schedule: Record "S4LA Schedule")

    begin
        //  {TG191219}
        //        IF Schedule"." PYA Interest Rate Modified " THEN
        //EXIT; // do not update if user-defined interest rate
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnCalcSystemIntRate', '', false, false)]
    procedure CalcSystemInterest(var Schedule: Record "S4LA Schedule"; var ProgramRates: record "S4LA Program Rate"; var ScheduleOld: record "S4LA Schedule")
    var
        Contr: record "s4la Contract";
        QuickQuoteWksht: record "Quick Quote Worksheet";
        FundedRate: Decimal;
        UserSetup: Record "User Setup";
        NewRate: Decimal;
        LText001: label 'Must be Application Admin to change interest rate lower than %1';
    begin

        //{TG191219}
        //IF ("Interest %" = 0) OR (xRec."Program Code"<>"Program Code") OR (xRec."Term (months)" <>"Term (months)") THEN//DV171219
        //  "Interest %" := ProgramRates."Standard Rate";
        IF (schedule."Contract No." <> '') AND Contr.GET(schedule."Contract No.") THEN
            Contr.fnSystemIntRate(Schedule."Interest %", Schedule."PYA Interest Rate Markup", FundedRate, 0, QuickQuoteWksht);
        //{---}

        //Schedule."PYA Blended Cost" := ProgramRates."PYA Blended Rate"; //TG190730
        NewRate := Schedule."Interest %";//DV171205

        //{DV171220}
        UserSetup.GET(USERID);
        //{TG190730}
        //IF (xRec."Interest %"<>"Interest %") AND ("Interest %" < ProgramRates."Standard Rate") AND (UserSetup."Application Admin" = FALSE ) THEN
        //  ERROR(LText001,ProgramRates."Standard Rate");
        //{---}{DV171220}
        IF FundedRate <> 0 THEN BEGIN
            IF (ScheduleOld."Interest %" <> Schedule."Interest %") AND (Schedule."Interest %" < FundedRate) AND NOT UserSetup."Approval Administrator" THEN
                ERROR(LText001, FundedRate);
        END ELSE BEGIN
            IF (ScheduleOld."Interest %" <> Schedule."Interest %") AND (Schedule."Interest %" < ProgramRates."Base Rate") AND NOT UserSetup."Approval Administrator" THEN
                ERROR(LText001, ProgramRates."Base Rate");
        END;
        //{---}
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NA Schedule Calc NA", 'onCheckBillServices', '', false, false)]
    procedure checkBillServices(var Line: record "S4LA Schedule Line"; var ServiceS: Record "S4LA Service"; var BillServExist: boolean);

    var
        i: Integer;
        MonthsBilledArray: array[11] of integer;
        SubStrCount: Integer;
    begin
        //{TG201119}
        IF (Services."PYA Starting Period" <> 0) AND (Line.Period < Services."PYA Starting Period") THEN
            BillServExist := false; // EXIT(FALSE);

        IF Services."PYA Months Charged" <> '' THEN BEGIN
            SubStrCount := fnSubStrCount(Services."PYA Months Charged");
            FOR i := 1 TO SubStrCount DO BEGIN
                EVALUATE(MonthsBilledArray[i], SELECTSTR(i, Services."PYA Months Charged"));
                IF DATE2DMY(Line.Date, 2) = MonthsBilledArray[i] THEN
                    BillServExist := true; // EXIT(TRUE);
            END;
            BillServExist := false; // EXIT(FALSE);
        END;

        //EXIT(TRUE);
        BillServExist := true;

    end;

    procedure fnSubStrCount(Str: Text) Number: Integer
    var
        FinalSubstr: boolean;
        SubStr: text;
        SubStrPos: Integer;

    begin
        //{TG201119}
        Number := 0;

        WHILE (NOT FinalSubstr) DO BEGIN
            Number += 1;
            SubStr := SELECTSTR(Number, Str);

            IF Number = 1 THEN
                SubStr := SubStr + ','
            ELSE
                SubStr := ',' + SubStr + ',';

            SubStrPos := STRPOS(Str, SubStr);

            IF SubStrPos = 0 THEN
                FinalSubstr := TRUE;
        END;

    end;

    /**
    bug has been fixed in SL61
    //BA211008 - Commented temporarily 
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Leasing Document Mgt.", 'OnBeforeSaveHTMLReport', '', false, false)]
    //--//
    procedure BeforeSaveHTMLReport(var DocNo: code[20]; var DocVar: Record document)
    var
    begin
        docvar.reset;
        docvar.SetRange("Key Code 1", DocNo);
        docvar.FindFirst();
    end;
    
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"Doc. PDF Form Filler", 'OnBeforeRun', '', false, false)]
        procedure DocPDFFormFiller_OnBeforeRun(pServerFileName: Text; pContr: Record "S4LA Contract"; pReadOnly: Boolean; var IsHandled: Boolean)
        var
            PYADocPDFFormFiller: Codeunit "PYA Doc. PDF Form Filler";
        begin
            IsHandled := true;
            PYADocPDFFormFiller.SetParameters(pServerFileName, pContr, pReadOnly);
            PYADocPDFFormFiller.Run();
        end;


    [EventSubscriber(ObjectType::Table, DATABASE::"S4LA Document", 'OnCreateDocument_Print', '', false, false)]
    local procedure Document_OnCreateDocument_Print(var Rec: Record "S4LA Document"; DocTemplate: Record "S4LA Document Template"; CustomReportLayout: Record "Custom Report Layout"; ServerFileName: Text; var isHandled: Boolean);
    var
        QuoteApplicationContract: Record "S4LA Contract";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WorkOrdHdr: Record "s4la Work Order Header";
        isHandled_PYADoc: Boolean;
        DocApplicationReport: report "PYA Doc. Data - Application";
        SelectGuarantor: page "Select Guarantor";
        GuarantorCode: code[20];
    begin
        case Rec."Table ID" of
            DATABASE::"S4LA Contract":
                begin
                    case true of

                        (Rec."Payment Entry No." <> 0):
                            ;
                        (rec."Dishonour Entry No." <> 0):
                            ;
                        else begin //KS160406
                            QuoteApplicationContract.SetRange("Contract No.", Rec."Key Code 1"); //KS151001
                            QuoteApplicationContract.FindFirst;
                            case DocTemplate."Output Doc Format" of
                                //DocTemplate."Output Doc Format"::"Save as PDF":
                                //    begin
                                //BA220307
                                //        if DocTemplate."PYA Print Per Guarantor" then begin
                                //            commit;
                                //            CLEAR(SelectGuarantor); //page
                                //            SelectGuarantor.LOOKUPMODE := TRUE;
                                //            SelectGuarantor.setContractNo(QuoteApplicationContract."Contract No.");
                                //            if SelectGuarantor.RUNMODAL = ACTION::LookupOK then
                                //                GuarantorCode := SelectGuarantor.GetGuarantor();

                                //            Clear(DocApplicationReport);
                                //            DocApplicationReport.SetPrintPerGuarantor(GuarantorCode);
                                //            DocApplicationReport.SetTableView(QuoteApplicationContract);
                                //            DocApplicationReport.SaveAsWord(ServerFileName);

                                //        end else
                                //--//
                                //            REPORT.SaveAsPdf(CustomReportLayout."Report ID", ServerFileName, QuoteApplicationContract);
                                //    end;
                                //DocTemplate."Output Doc Format"::"Save as WORD":
                                //    begin
                                //BA220221 
                                //        if DocTemplate."PYA Print Per Guarantor" then begin
                                //            commit;
                                //            CLEAR(SelectGuarantor); //page
                                //            SelectGuarantor.LOOKUPMODE := TRUE;
                                //            SelectGuarantor.setContractNo(QuoteApplicationContract."Contract No.");
                                //            if SelectGuarantor.RUNMODAL = ACTION::LookupOK then
                                //                GuarantorCode := SelectGuarantor.GetGuarantor();

                                //            Clear(DocApplicationReport);
                                //            DocApplicationReport.SetPrintPerGuarantor(GuarantorCode);
                                //            DocApplicationReport.SetTableView(QuoteApplicationContract);
                                //            DocApplicationReport.SaveAsWord(ServerFileName);

                                //        end else
                                //--//
                                //            REPORT.SaveAsWord(CustomReportLayout."Report ID", ServerFileName, QuoteApplicationContract);
                                //    end;
                              
                                DocTemplate."Output Doc Format"::"Save As EXCEL":
                                    IF CustomReportLayout."Report ID" <> 0 THEN
                                        REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, QuoteApplicationContract)
                            //ELSE BEGIN
                            //    Rec.WritetoExcel;//DV181024
                            //END;
                            //DocTemplate."Output Doc Format"::"PDF Form (editable)":
                            //  begin
                            //BA210927
                            //    SetPYADocFiller(Rec, ServerFileName, false, isHandled_PYADoc);
                            //    if not isHandled_PYADoc then
                            //        Rec.FillPDFform(ServerFileName, QuoteApplicationContract, false); //KS160203
                            //end;

                            //DocTemplate."Output Doc Format"::"PDF Form (read-only)":
                            //    begin
                            //BA210927
                            //        SetPYADocFiller(Rec, ServerFileName, true, isHandled_PYADoc);
                            //        if not isHandled_PYADoc then
                            //            Rec.FillPDFform(ServerFileName, QuoteApplicationContract, true); //KS160203
                            //    end;
                            end;
                            isHandled := true;
                        end; //case TRUE
                    end;
                end;//contract table

            // >> SK151002
            DATABASE::"Sales Header":
                BEGIN
                    SalesHeader.SETRANGE("Document Type", Rec."Key Int 1");
                    SalesHeader.SETRANGE("No.", Rec."Key Code 1");
                    SalesHeader.FINDFIRST;
                    CASE DocTemplate."Output Doc Format" OF
                        //DocTemplate."Output Doc Format"::"Save as PDF":
                        //    REPORT.SAVEASPDF(CustomReportLayout."Report ID", ServerFileName, SalesHeader);
                        DocTemplate."Output Doc Format"::"Save as WORD":
                            REPORT.SAVEASWORD(CustomReportLayout."Report ID", ServerFileName, SalesHeader);
                      
                        DocTemplate."Output Doc Format"::"Save As EXCEL":
                            BEGIN
                                IF CustomReportLayout."Report ID" <> 0 THEN
                                    REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, SalesHeader)
                                //   ELSE BEGIN
                                //        Rec.WritetoExcel;//DV181024
                            END;
                    //END;
                    //DocTemplate."Output Doc Format"::"Save As EXCEL": REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, SalesHeader);
                   
                    //DocTemplate."Output Doc Format"::"PDF Form (editable)":
                    //    SetPYADocFiller(Rec, ServerFileName, false, isHandled_PYADoc);
                    //DocTemplate."Output Doc Format"::"PDF Form (read-only)":
                    //    SetPYADocFiller(Rec, ServerFileName, true, isHandled_PYADoc);
                    END;
                    isHandled := true;
                END;

            DATABASE::"Purchase Header":
                BEGIN
                    PurchaseHeader.SETRANGE("Document Type", Rec."Key Int 1");
                    PurchaseHeader.SETRANGE("No.", Rec."Key Code 1");
                    PurchaseHeader.FINDFIRST;
                    CASE DocTemplate."Output Doc Format" OF
                        DocTemplate."Output Doc Format"::"Save as PDF":
                            REPORT.SAVEASPDF(CustomReportLayout."Report ID", ServerFileName, PurchaseHeader);
                        DocTemplate."Output Doc Format"::"Save as WORD":
                            REPORT.SAVEASWORD(CustomReportLayout."Report ID", ServerFileName, PurchaseHeader);
                       
                        DocTemplate."Output Doc Format"::"Save As EXCEL":
                            BEGIN
                                IF CustomReportLayout."Report ID" <> 0 THEN
                                    REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, PurchaseHeader)
                                //ELSE BEGIN
                                //    Rec.WritetoExcel;//DV181024
                                //END;
                            END;
                    //DocTemplate."Output Doc Format"::"Save As EXCEL": REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, PurchaseHeader);
                  

                    //BA210927
                    //DocTemplate."Output Doc Format"::"PDF Form (editable)":
                    //    SetPYADocFiller(Rec, ServerFileName, false, isHandled_PYADoc);
                    //DocTemplate."Output Doc Format"::"PDF Form (read-only)":
                    //    SetPYADocFiller(Rec, ServerFileName, true, isHandled_PYADoc);

                    END;
                    isHandled := true;
                END;
            //DV170712
            DATABASE::"S4LA Work Order Header":
                BEGIN
                    WorkOrdHdr.SETRANGE("No.", Rec."Key Code 1");
                    WorkOrdHdr.FINDFIRST;
                    CASE DocTemplate."Output Doc Format" OF
                        //DocTemplate."Output Doc Format"::"Save as PDF":
                        //    REPORT.SAVEASPDF(CustomReportLayout."Report ID", ServerFileName, WorkOrdHdr);
                        DocTemplate."Output Doc Format"::"Save as WORD":
                            REPORT.SAVEASWORD(CustomReportLayout."Report ID", ServerFileName, WorkOrdHdr);
                       
                        DocTemplate."Output Doc Format"::"Save As EXCEL":
                            BEGIN
                                IF CustomReportLayout."Report ID" <> 0 THEN
                                    REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, WorkOrdHdr)
                                //    ELSE BEGIN
                                //        Rec.WritetoExcel;//DV181024
                                //    END;
                            END;
                    //DocTemplate."Output Doc Format"::"Save As EXCEL": REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, WorkOrdHdr);

                    //BA210927
                    //DocTemplate."Output Doc Format"::"PDF Form (editable)":
                    //    SetPYADocFiller(Rec, ServerFileName, false, isHandled_PYADoc);
                    //DocTemplate."Output Doc Format"::"PDF Form (read-only)":
                    //    SetPYADocFiller(Rec, ServerFileName, true, isHandled_PYADoc);
                    END;
                    isHandled := true;
                END;
            //BA210927
            DATABASE::"Cust. Ledger Entry":
                begin
                    //    case DocTemplate."Output Doc Format" of
                    //        DocTemplate."Output Doc Format"::"PDF Form (editable)":
                    //            SetPYADocFiller(Rec, ServerFileName, false, isHandled_PYADoc);
                    //        DocTemplate."Output Doc Format"::"PDF Form (read-only)":
                    //            SetPYADocFiller(Rec, ServerFileName, true, isHandled_PYADoc);
                    //    end;
                end;
        end; //case per table
    end;

    //BA211123
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer; var NewReportId: Integer)
    begin
        if ReportId = Report::"PYA Gen.Report - Update" then
            NewReportId := Report::"PYA Gen.Report - Update";
    end;


    //BA220221
    [EventSubscriber(ObjectType::Codeunit, codeunit::"NA DD Schedule Mgt", 'OnCode_AfterJnlInit', '', false, false)]
    local procedure AfterJnlInit(var Contr: Record "S4LA Contract"; var Jnl: Record "Gen. Journal Line")
    begin
        jnl."PYA DD Account Type" := contr."PYA DD Account Type";
    end;
    //--//

    //Contract Activate
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NA Contract Activate", 'ContractActivate_OnRun', '', false, false)]
    local procedure ContractActivate_OnRun(var Contr: Record "S4LA Contract"; var isHandled: Boolean)
    var
        //NAContractActivate: Codeunit "NA Contract Activate";
        sched: Record "S4LA Schedule";
        HasActPostingsTxt: Label 'This contract already has activation postings. Not possible to activate a second time.\Admin should update Contract Status back to "Active Contract" after any changes to avoid duplicate postings.';
    begin
        // -- PYAS-149
        Contr.GetNewestSchedule(Sched);
        sched.TestField("Activation Date");
        //BA220615
        IF HasActivationEntries(Contr."Contract No.") THEN
            ERROR(HasActPostingsTxt);
        //--//
    end;
    //BA220615
    local procedure HasActivationEntries(pContrNo: Code[20]): Boolean
    var
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry: Record "G/L Entry";
    begin
        SourceCodeSetup.GET;

        GLEntry.RESET;
        GLEntry.SETCURRENTKEY("PYA Contract No", "G/L Account No.", "Posting Date");
        GLEntry.SETRANGE("PYA Contract No", pContrNo);
        GLEntry.SETFILTER("Source Code", '%1|%2', SourceCodeSetup."PYA Contract - Activate", SourceCodeSetup."PYA Pro-Rata Billing");
        GLEntry.SetRange(Reversed, false); //BA220921 - Show allow after the intial entries must have been reversed.
        IF GLEntry.ISEMPTY THEN
            EXIT(FALSE);

        EXIT(TRUE);

    end;
    //--//

    //BA220221
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Compliance Rules", 'OnBeforePaymentDDBankBranchNoCheck', '', false, false)]
    local procedure BeforePaymentDDBankBranchNoCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
    var
        WarningLog: Record "PYA Warning Log UI";
        Text518: Label '%1 is not defined for Contract no. %2.';
    begin
        if (Contract."PYA DD Account Type" = Contract."PYA DD Account Type"::" ") then
            WarningLog.Add(StrSubstNo(Text518, Contract.FieldCaption("PYA DD Account Type")), 3);
    end;
    //--//
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Compliance Rules", 'OnCheck_BeforeExit', '', false, false)]
    local procedure OnCheck_BeforeExit(var Contract: Record "S4LA Contract")
    var
        LeasingSetup: Record "S4LA Leasing Setup";
        WarningLog: Record "PYA Warning Log UI";
        Text518: Label '%1 is not defined for Contract no. %2.';
        Text514: Label 'Missing %1 for Asset %2.';
        Asset: Record "S4LA Asset";
        FinancialProduct: Record "S4LA Financial Product";
        FA: Record "Fixed Asset";
    begin
        LeasingSetup.get;
        FinancialProduct.GET(Contract."Financial Product");

        IF (Contract."Payment Method Code" = LeasingSetup."Payment Method Code for DD") THEN BEGIN
            //JM170725++
            IF Contract."NA DD Start Date" = 0D THEN
                WarningLog.Add(STRSUBSTNO(Text518, Contract.FIELDCAPTION("NA DD Start Date"), Contract."Contract No."), 2);
            //JM170725--
        END;

        Asset.SETRANGE(Asset."Contract No.", Contract."Contract No.");
        IF Asset.FINDSET THEN
            REPEAT

                IF FinancialProduct."Fin. Product Type" <> FinancialProduct."Fin. Product Type"::Loan THEN BEGIN    // SK180409
                    
                    IF NOT FA.GET(Asset."Asset No.") THEN
                        CLEAR(FA)
                    ELSE
                        IF (FA."FA Posting Group" = '') THEN
                            WarningLog.Add(STRSUBSTNO(Text514, FA.FIELDCAPTION("FA Posting Group"), Asset."Asset Description"), 3);                   
                END;
            // SK180409
            UNTIL Asset.NEXT = 0;
    end;
    //WF Mgt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"s4la WF Mgt", 'OnUpdateWorkflowOnNextStep_BeforeAction', '', false, false)]
    local procedure OnUpdateWorkflowOnNextStep_BeforeAction(var WF: Record "s4la WF Task"; ToStepCode: Code[20])
    var
        Outbox: Record "s4la Document";
        DocOutboxMgt: Codeunit "s4la Doc. Outbox Mgt";
        DocumentSetup: Record "S4LA Document Selection";
        UserSetup: Record "User Setup";
        Approver: Record "User Setup";
        Sub: Record "User Setup";
        Contract: Record "S4LA Contract";
        TemplateStepNext: Record "s4la WF Template Step";
    begin
        TemplateStepNext.Get(WF."WF Template", ToStepCode);

        Contract.GET(WF."Contract No.");
        IF (Contract.Status = Contract.Status::Quote) AND
           (STRPOS(UPPERCASE(TemplateStepNext."Task Description"), UPPERCASE('Credit Decision')) > 0) THEN BEGIN
            DocumentSetup.RESET;
            DocumentSetup.SETRANGE("Financial Product", Contract."Financial Product");
            DocumentSetup.FINDFIRST;
            Outbox.RESET;
            Outbox.SETRANGE("Key Code 1", WF."Contract No.");
            Outbox.SETRANGE("Template Code", DocumentSetup."Approval Letter Template");
            IF NOT Outbox.FINDFIRST THEN BEGIN
                Contract.CreateDocApprovalLetter(FALSE);
            END;

            Outbox.SETRANGE("Key Code 1", WF."Contract No.");
            Outbox.SETRANGE("Template Code", DocumentSetup."Approval Letter Template");
            IF Outbox.FINDFIRST THEN BEGIN
                Outbox."E-mail" := '';//DV180220
                UserSetup.GET(USERID);
                IF UserSetup."Approver ID" <> '' THEN
                    IF NOT Approver.GET(UserSetup."Approver ID") THEN
                        CLEAR(Approver);
                IF UserSetup.Substitute <> '' THEN
                    IF NOT Sub.GET(UserSetup.Substitute) THEN
                        CLEAR(Sub);
                Outbox.Prepared := FALSE;
                Outbox."Doc Send-to" := Outbox."Doc Send-to"::Approver;
                IF Approver."E-Mail" <> '' THEN
                    Outbox."E-mail" := Approver."E-Mail";
                IF (Sub."E-Mail" <> '') AND (Sub."E-Mail" <> Approver."E-Mail") THEN
                    Outbox."E-mail" += ';' + Sub."E-Mail";
                Outbox.MODIFY;
                DocOutboxMgt.SendEmails(Outbox, Enum::"S4LA D.Outb. SendEmails Caller"::"Doc. Subpage");
            END;
        END;
    end;

    //BA220316 - Fix document printing & report printing bug. 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Report Mgt.", 'OnAfterGetCustomLayoutCode', '', false, false)]
    local procedure AfterGetCustomLayout(ReportID: Integer; var CustomLayoutCode: Code[20])
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        CustomReportLayout.reset;
        CustomReportLayout.setrange("Report ID", ReportID);
        CustomReportLayout.setrange(Code, CustomLayoutCode);
        if not CustomReportLayout.FindFirst() then begin
            CustomLayoutCode := '';
            Exit;
        end else begin
            CustomLayoutCode := CustomReportLayout.code;
        end;
    end;

    //BA220323 Finance lease change for VAT postings
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NA Contract Activate", 'OnBeforeAssetPosting_DoJournalPostings', '', false, false)]
    local procedure BeforeAssetPosting_DoJournalPostings(var Sender: codeunit "NA Contract Activate"; var Contr: Record "S4LA Contract"; var Sched: Record "S4LA Schedule"; PostingDate: date; PostingDocNo: code[20]; var BalanceTot: Decimal; var BalanceTotLCY: Decimal; var BalanceMsg: text; var BalanceLCYMsg: text; var IsHandled: Boolean);
    var
        LeasingReceivablesType: Enum "S4LA Leasing Receivables Type";
        Asset: record "s4la Asset";
        IsFinancedInclVAT: Boolean;
        AmtNominal: Decimal;
        ResidualValue: Decimal;
        ResidualExVAT: Decimal;
        IsDedicatedAccountForRV: Boolean;
        IsPurchOnActivation: Boolean;
        GLSetup: Record "General Ledger Setup";
        LeasingSetup: record "s4la Leasing Setup";
        LeasingPostingSetup: Record "s4la Leasing Posting Setup";
        FinProd: record "s4la Financial Product";
        IsLoanProduct: Boolean;
        IsLeaseInventory: Boolean;
        Descr: Text;
        BusPurchVATgr: Code[20];
        BusSalesVATgr: Code[20];
        ProdPurchVATgr: Code[20];
        ProdSalesVATgr: Code[20];
        AmtInclPurchVAT: Decimal;
        AmtInclSalesVAT: Decimal;
        AmtExVAT: Decimal;
        PrincipalVATRate: Decimal; //SOLV-441
        InterestVATRate: Decimal; //SOLV-441
        InstallmentVATRate: Decimal; //SOLV-441
        jnl: Record "Gen. Journal Line";
        IsAssetFromStock: Boolean;
        ResidualInclVAT: Decimal;
        Text001: Label 'Activation (%1) %2', Comment = 'LTH="Aktyvavimas (%1) %2"';
        RoundingPrecision: Decimal;
        TotalPurchVATonFinancedItems: Decimal;
        UpfrontVATBase: Decimal;
        LeaseReceivableAcc: Code[20];
        RVLeaseReceivableAcc: code[20];
        Currency: Record Currency;
        FixedAsset: record "Fixed Asset";
        FAPostingGroup: record "FA Posting Group";
        GainLoss: Decimal;
        AssetValue: Decimal;

    begin
        GLSetup.Get;
        LeasingSetup.get();
        FinProd.get(Contr."Financial Product");
        LeasingPostingSetup.GetSetupRec(LeasingPostingSetup, Contr."Contract No.");

        IsPurchOnActivation := FinProd."Asset Acquisition Method" = FinProd."Asset Acquisition Method"::"At Lease Activation";
        IsLeaseInventory := (FinProd."Accounting Group" = FinProd."Accounting Group"::"Lease Inventory"); //for short
        IsLoanProduct := (FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::Loan);
        //SOLV-614 >>
        //IsFinancedInclVAT := FinProd."Amounts Including VAT"; //for short
        IsFinancedInclVAT := Sched."Amounts Including VAT";
        //SOLV-614 <<


        if not (not isPurchOnActivation and not isLeaseInventory) then begin
            IsHandled := false;
            exit;
        end;

        if Currency.Get(Contr.CCY)
            then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GLSetup."Amount Rounding Precision";

        case FinProd."Accounting Group" of
            FinProd."Accounting Group"::"Gross Receivable":
                begin
                    LeasingPostingSetup.testfield("Gross Receivable (BS)");
                    if IsDedicatedAccountForRV then
                        LeasingPostingSetup.TestField("Receivable - RV Portion (BS)");
                    LeaseReceivableAcc := LeasingPostingSetup."Gross Receivable (BS)";
                    RVLeaseReceivableAcc := LeasingPostingSetup."Receivable - RV Portion (BS)";
                end;
            FinProd."Accounting Group"::"Net Receivable":
                begin
                    LeasingPostingSetup.testfield("Net Receivable (BS)");
                    LeaseReceivableAcc := LeasingPostingSetup."Net Receivable (BS)";
                    if IsDedicatedAccountForRV then
                        LeasingPostingSetup.TestField("Receivable - RV Portion (BS)");
                    RVLeaseReceivableAcc := LeasingPostingSetup."Receivable - RV Portion (BS)";
                end;
            FinProd."Accounting Group"::"Lease Inventory":
                LeaseReceivableAcc := '';
        end;

        IsDedicatedAccountForRV := (FinProd."Use Dedicated RV G/L Account") AND NOT IsLeaseInventory;

        Asset.reset;
        Asset.SetRange("Contract No.", Contr."Contract No.");
        Asset.SetFilter("Asset No.", '<>%1', '');
        if Asset.FindSet() then
            repeat
                //SOLV-448 >>
                if not IsFinancedInclVAT then begin
                    AmtNominal := Asset."Purchase Price (Excl. VAT)";
                    ResidualExVAT := Asset."Residual Value (Excl. VAT)";
                    ResidualValue := Asset."Residual Value";
                end
                else begin
                    ResidualExVAT := Asset."Residual Value (Excl. VAT)";
                    //SOLV-448 <<
                    AmtNominal := Asset."Purchase Price";
                    ResidualValue := Asset."Residual Value";
                end;

                                if IsDedicatedAccountForRV then //RV to be posted in separate account, So is removed from nominal amount
                                                                //SOLV-448 >>
                                    if not IsFinancedInclVAT then
                                        AmtNominal -= ResidualExVAT
                                    else
                                        //SOLV-448 <<
                                        AmtNominal -= ResidualValue;

                if AmtNominal <> 0 then begin

                    IsAssetFromStock := Asset."Acquisition Source" = Asset."Acquisition Source"::Stock;
                    Descr := StrSubstNo(Text001, Asset."Asset Description", Contr."Contract No.");

                    //--------- Calc Amount to post (ASSETS)
                    if IsFinancedInclVAT then begin
                        BusPurchVATgr := '';
                        ProdPurchVATgr := '';
                        // BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                        BusSalesVATgr := Contr."Customer VAT Bus. Group";
                        ProdSalesVATgr := Asset."VAT Group";
                        AmtInclPurchVAT := AmtNominal;
                        ResidualExVAT := Round(ResidualValue / GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                        ResidualInclVAT := ResidualValue;
                    end else begin
                        BusPurchVATgr := GetVendVATGroup(Asset."Supplier No.");
                        ProdPurchVATgr := Asset."VAT Group";
                        BusSalesVATgr := '';
                        ProdSalesVATgr := '';
                        AmtInclPurchVAT := Round(AmtNominal * GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                        TotalPurchVATonFinancedItems += AmtInclPurchVAT - AmtNominal;
                        ResidualExVAT := ResidualValue;
                        ResidualInclVAT := Round(ResidualValue * GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                    end;

                    //------ ASSET cases
                    case true of

                        //--- Case 1.2 FL --- (LeaseReceivable, via PO)
                        not isPurchOnActivation and not isLeaseInventory and not IsDedicatedAccountForRV:
                            begin

                                LeasingPostingSetup.testfield("Supplier Clearing Acc. (Cr)");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc, Descr, AmtNominal, '', jnl."Tax Area Code", jnl."Tax Group Code", jnl."Tax Liable");
                                //Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc, '',
                                //      Descr, AmtNominal, 0, '', '', '', jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."Supplier Clearing Acc. (Cr)", CopyStr(Asset."Asset Description", 1, MaxStrLen((Jnl.Description))), -AmtNominal, '', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                            end;

                        //BA221020- For Asset Posting
                        //--- Case 1.3 FL --- (Asset from Stock)
                        IsAssetFromStock and not isLeaseInventory AND NOT IsDedicatedAccountForRV:
                            begin
                                if FinProd."Fin. Product Type" = FinProd."Fin. Product Type"::"Hire Purchase" then begin
                                    FixedAsset.get(Asset."Asset No.");
                                    FAPostingGroup.get(FixedAsset."FA Posting Group");
                                    FAPostingGroup.TestField("Gains Acc. on Disposal");
                                    FAPostingGroup.TestField("Losses Acc. on Disposal");

                                    //FixedAsset.CalcFields("S4L Book Value");

                                    GainLoss := round(AmtNominal - FixedAsset."pya Book Value", RoundingPrecision);

                                    LeasingPostingSetup.testfield("Stock Clearing Acc. (Cr)");
                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                            Descr, AmtNominal, '', '', '', jnl."Tax Liable");
                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                            Descr, AmtNominal, '', '', '', false);
                                    //post asset entries        
                                    case true of
                                        (GainLoss > 0):
                                            begin
                                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", Asset."Asset No.",
                                                                                       Descr, -AmtNominal, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", FAPostingGroup."Gains Acc. on Disposal",
                                                                                          Descr, -GainLoss, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                            end;

                                        (GainLoss < 0):
                                            begin
                                                //gainloss is (-)
                                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", Asset."Asset No.",
                                                                                          Descr, -AmtNominal, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", FAPostingGroup."Losses Acc. on Disposal",
                                                                                          Descr, -GainLoss, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                            end;

                                        (GainLoss = 0):
                                            begin
                                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", Asset."Asset No.",
                                                                             Descr, -AmtNominal, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                            end;
                                    end;
                                end else begin

                                    LeasingPostingSetup.testfield("Stock Clearing Acc. (Cr)");
                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                            Descr, AmtNominal, '', '', '', jnl."Tax Liable");
                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."Stock Clearing Acc. (Cr)",
                                            Descr, -AmtNominal, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                end;
                            end;

                        //--- Case 1.3.2 FL --- (Asset from Stock) - dedicated account for RV
                        IsAssetFromStock and not isLeaseInventory AND IsDedicatedAccountForRV:
                            begin
                                LeasingPostingSetup.testfield("Stock Clearing Acc. (Cr)");
                                LeasingPostingSetup.TestField("Receivable - RV Portion (BS)");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                        Descr, AmtNominal, '', '', '', jnl."Tax Liable");

                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", RVLeaseReceivableAcc,
                                        Descr, ResidualValue, '', '', '', jnl."Tax Liable");

                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."Stock Clearing Acc. (Cr)",
                                        Descr, -(AmtNominal + ResidualValue), 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");

                            end;
                        //--//

                        //--- Case 1.2.1 FL --- (LeaseReceivable, via PO) - dedicated account for RV
                        not isPurchOnActivation and not isLeaseInventory and IsDedicatedAccountForRV:
                            begin
                                LeasingPostingSetup.testfield("Supplier Clearing Acc. (Cr)");
                                LeasingPostingSetup.TestField("Receivable - RV Portion (BS)");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                        Descr, AmtNominal, '', '', '', jnl."Tax Liable");

                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", RVLeaseReceivableAcc,
                                        Descr, ResidualValue, '', '', '', jnl."Tax Liable");


                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."Supplier Clearing Acc. (Cr)",
                                        CopyStr(Asset."Asset Description", 1, MaxStrLen((Jnl.Description))), -AmtNominal, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                            end;
                        else
                            Error('Case of Asset Net Investment posting not implemented. Contract No. %1', Contr."Contract No.");
                    end;
                end;

            until Asset.Next() = 0;

        IsHandled := true;
    end;

    //-//
    procedure GetVendVATGroup(SupplierNo: Code[20]): Code[20]
    var
        Vend: Record Vendor;
    begin
        if Vend.get(SupplierNo)
            then
            exit(Vend."VAT Bus. Posting Group")
        else
            exit('');
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


    [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'FixedAsset_OnUpdateDeprBook', '', false, false)]
    local procedure FA_OnUpdateDeprBook(var FixedAsset: Record "Fixed Asset"; var isHandled: Boolean);
    var
        FAbook: Record "FA Depreciation Book";
        LeasingPostingSetup: Record "S4LA Leasing Posting Setup";
        FinProduct: Record "S4LA Financial Product";
        contr: Record "S4LA Contract";
        FASetup: Record "FA Setup";
    begin
        IF NOT Contr.GET(Contr."Contract No.") THEN
            CLEAR(Contr);
        FASetup.GET;
        FASetup.TESTFIELD("Default Depr. Book");
        with FixedAsset do begin
            IF NOT FinProduct.GET(contr."Financial Product") THEN
                FinProduct.INIT;
            FinProduct.TESTFIELD("FA Depreciation Book Code");
            FinProduct.TestField("FA Posting Group for PO Lease");

            // SK200214 IF NOT FAbook.GET("No.",FASetup."Default Depr. Book") THEN BEGIN
            IF NOT FAbook.GET("No.", FASetup."Default Depr. Book") THEN BEGIN // SK200214
                FAbook.INIT;
                FAbook."FA No." := "No.";
                FAbook."Depreciation Book Code" := FASetup."Default Depr. Book";
                FAbook.Description := COPYSTR(Description, 1, MAXSTRLEN(Description));  //KS141215
                FAbook.VALIDATE("FA Posting Group", FinProduct."FA Posting Group for PO Lease");//DV170926, 1111
                FAbook.INSERT;
            END;

            FAbook.CALCFIELDS("Acquisition Cost");
            IF FAbook."Acquisition Cost" = 0 THEN BEGIN //Do not change if has balance

                IF "PYA Contract No" = '' THEN BEGIN
                    //--- use wholesale post group
                END ELSE BEGIN
                    //--- OpLease posting group
                    //KS141215
                    IF NOT Contr.GET(Contr."Contract No.") THEN//DV171111
                        CLEAR(Contr);
                    IF FAbook."FA Posting Group" = '' THEN BEGIN
                        LeasingPostingSetup.SetSilentMode(TRUE);
                        LeasingPostingSetup.GetSetupRec(LeasingPostingSetup, "PYA Contract No");
                        IF Contr.Status = Contr.Status::Contract THEN //DV171111
                            FAbook.VALIDATE("FA Posting Group", LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)") //should be blank for non OL fin products.
                        ELSE
                            FAbook.VALIDATE("FA Posting Group", FinProduct."FA Posting Group for PO Lease");
                    END;
                    FAbook.MODIFY;
                END;


            end;
        END;
        isHandled := true;
    end;


    //BA220326
    [EventSubscriber(ObjectType::Table, Database::"s4la Asset", 'OnBuildDescription_BeforeExit', '', false, false)]
    local procedure BuildDescriptioni(var Rec: Record "s4la Asset"; var Txt: Text)

    begin
        //Model Year + Asset Brand + Model + Trim
        txt := '';
        if Rec."Model Year" <> 0 then
            Txt := format(Rec."Model Year");

        If Rec."Asset Brand" <> '' then
            Txt := Txt + ' ' + Rec."Asset Brand";

        if rec.Model <> '' then
            Txt := Txt + ' ' + rec.Model;

        if rec."NA Trim" <> '' then
            Txt := txt + ' ' + rec."NA Trim";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"s4la Invoicing Mgt", 'OnInitCodeunit_CreatedInvoiceNo', '', false, false)]
    local procedure InvoicingMgt_OnInitCodeunit_CreatedInvoiceNo(var Contract: Record "S4LA Contract"; var FinProduct: Record "S4LA Financial Product"; var ScheduleLine: Record "S4LA Schedule Line"; PostingDate: date; var CreatedInvoiceNo: Code[20]; var isHandled: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
        cdNoSeriesMng: Codeunit NoSeriesManagement;
    begin
        if not FinProduct."Create Sales Document" then begin
            SalesSetup.Get();
            CreatedInvoiceNo := cdNoSeriesMng.GetNextNo(SalesSetup."Posted Invoice Nos.", PostingDate, true);
            isHandled := true;
        end;
    end;

    //BA220327
    [EventSubscriber(ObjectType::Codeunit, Report::"S4LA Contract Balances Run", 'S4LNA_OnRun_FillGenRepBuf', '', false, false)]
    local procedure RunFillGenReport(var Rec: Record "Job queue entry"; var GenReportBuffer: Record "S4LA Gen.Report Buffer"; var isHandled: Boolean)
    begin
        isHandled := true;
        //run based on job queue BA220412
        // commit;
        //  Report.Run(Report::"PYA Gen.Report - Update", false, false); //"PYA Gen.Report - Update"
    end;

    //BA220329--
    [EventSubscriber(ObjectType::Table, Database::"s4la Contract", 'OnMakeContractFromQuoteSchedule_BeforeCommit', '', false, false)]
    local procedure Contract_OnMakeContractFromQuoteSchedule_BeforeCommit(var rec: Record "S4LA Contract"; var recContract: Record "S4LA Contract")
    begin
        Rec.InsertUpdateContrInsurPolicy(recContract);
    end;
    //--//

    //BA220330 --
    [EventSubscriber(ObjectType::Table, Database::"S4LA Document", 'OnCreateDocument_ReportLayout', '', false, false)]
    local procedure Document_OnCreateDocument_ReportLayout(var Rec: Record "S4LA Document"; var DocTemplate: Record "S4LA Document Template"; var CustomReportLayout: Record "Custom Report Layout"; var ReportLayoutSelection: Record "Report Layout Selection"; VAR isHandled: Boolean)
    begin

        IF (DocTemplate."Output Doc Format" = DocTemplate."Output Doc Format"::"Save As EXCEL") AND (DocTemplate."Custom Report Layout Code" <> '') THEN BEGIN//DV181025
            DocTemplate.TESTFIELD("Custom Report Layout Code");
            CustomReportLayout.GET(DocTemplate."Custom Report Layout Code");
            ReportLayoutSelection.SetTempLayoutSelected(CustomReportLayout.Code);
        END;
        IF CustomReportLayout.GET(DocTemplate."Custom Report Layout Code") THEN //DV181204
            ReportLayoutSelection.SetTempLayoutSelected(CustomReportLayout.Code);

        isHandled := true;
    end;
    //--//

    [EventSubscriber(ObjectType::Table, Database::"s4la document", 'OnCreateDocument_Attachment', '', false, false)]

    local procedure Document_OnCreateDocument_Attachment(var rec: Record "S4LA Document"; var DocTemplate: Record "S4LA Document template"; var ServerFileName: Text; var isHandled: Boolean)
    begin
        if DocTemplate."Output Doc Format" = DocTemplate."Output Doc Format"::"Save As EXCEL" then
            isHandled := true; //DV181025
    end;

    //BA220404
    [EventSubscriber(ObjectType::Codeunit, codeunit::"NA Contract Activate", 'OnAfter_DoJournalPostings', '', false, false)]
    local procedure After_DoJournalPostings(Sender: codeunit "NA Contract Activate"; var Contr: Record "S4LA Contract"; var Sched: Record "S4LA Schedule"; PostingDate: date; PostingDocNo: code[20]; var BalanceTot: Decimal; var BalanceTotLCY: Decimal; var BalanceMsg: text; var BalanceLCYMsg: text);
    var
        Jnl: record "Gen. Journal Line";
        Descr: Text[50];
        IsFinancedInclVAT: Boolean;
        LeasingPostingSetup: record "s4la Leasing Posting Setup";
        ProdSalesVATgr: code[20];
        BusSalesVATgr: Code[20];
        AmtInclSalesVAT: Decimal;
        AmtExVAT: Decimal;
        Currency: Record currency;
        RoundingPrecision: Decimal;
        GLSetup: record "General Ledger Setup";
        LeasingReceivablesType: Enum "S4LA Leasing Receivables Type";
        Text020: Label 'Security Deposit %1';
    begin
        if Sched."NA Refundable Security Deposit" <> 0 then begin

            GLSetup.get;
            if Currency.Get(Contr.CCY)
            then
                RoundingPrecision := Currency."Amount Rounding Precision"
            else
                RoundingPrecision := GLSetup."Amount Rounding Precision";

            LeasingPostingSetup.GetSetupRec(LeasingPostingSetup, Contr."Contract No.");
            LeasingPostingSetup.TestField("NA Ref Security Deposit");
            IsFinancedInclVAT := sched."Amounts Including VAT";

            if IsFinancedInclVAT then begin
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
            Descr := STRSUBSTNO(Text020, Sched."Contract No.");

            Sender.CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                                         Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");

            Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeasingPostingSetup."NA Ref Security Deposit",
                    Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
        end
    End;
    //--//

    //BA220405 -  Update Create PO header
    [EventSubscriber(ObjectType::Report, Report::"S4LA Create PO from Applicat.", 'OnBeforePurchaseHeaderModify', '', false, false)]
    local procedure BeforePurchaseHeaderModify(var PurchaseHeader: Record "Purchase Header"; Asset: Record "S4LA Asset"; Contract: Record "S4LA Contract"; Schedule: Record "S4LA Schedule");
    var
    begin
        //BA210531 -- add asset details from application
        PurchaseHeader."NA Model Year" := Asset."Model Year";
        PurchaseHeader."NA S#Car Make Code" := Asset."Asset Brand";
        PurchaseHeader."NA S#Car Model" := Asset.Model;
        PurchaseHeader."NA Asset New / Used" := Asset."Asset New / Used";
        PurchaseHeader."NA VIN" := Asset.VIN;
        PurchaseHeader."NA Trim" := Asset."NA Trim";
        //end here
    end;


    //BA220405 - Change to Fixed Asset according to the Fin Product
    [EventSubscriber(ObjectType::Report, Report::"S4LA Create PO from Applicat.", 'OnBeforePurchaseLineInsert', '', false, false)]
    local procedure BeforePurchaseLineInsert(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Asset: Record "S4LA Asset"; Contract: Record "S4LA Contract"; Schedule: Record "S4LA Schedule");
    var
        FinancialProduct: record "S4LA Financial Product";
        ContractActivate: Codeunit "NA Contract Activate";
        Purchheader: record "Purchase Header";
    begin

        FinancialProduct.Get(Contract."Financial Product");
        if FinancialProduct."PO Account Type" = FinancialProduct."PO Account Type"::"Fixed Asset" then begin

            if Asset."Asset No." = '' then begin
                ContractActivate.CreateFixedAsset(Asset);
                Asset.Get(Asset."Contract No.", Asset."Line No.");
            end;

            PurchaseLine.Validate(Type, PurchaseLine.Type::"Fixed Asset");
            PurchaseLine.Validate("No.", Asset."Asset No.");
            PurchaseLine.Validate("VAT Prod. Posting Group", Asset."VAT Group");
            PurchaseLine.Description := CopyStr(Asset."Asset Description", 1, MaxStrLen(PurchaseLine.Description));
            PurchaseLine.Validate(Quantity, 1);
            PurchaseLine.Validate("Direct Unit Cost", Asset."Purchase Price (Excl. VAT)");

            //Update asset no 
            if Purchheader.get(PurchaseHeader."Document Type", PurchaseHeader."No.") then
                IF PurchHeader."NA Asset No." = '' THEN BEGIN
                    PurchHeader."NA Asset No." := Asset."Asset No.";
                    PurchHeader.MODIFY;
                END;
        end;
    end;

    //BA220330 - Maintenance Service posting
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Contract - Activate", 'OnBeforeContrServicesPosting_DoJournalPostings', '', false, false)]
    local procedure BeforeContrService_DoJournalPostings(var sender: codeunit "NA Contract Activate"; var Contr: Record "S4LA Contract"; var Sched: Record "S4LA Schedule"; PostingDate: date; PostingDocNo: code[20]; var BalanceTot: Decimal; var BalanceTotLCY: Decimal; var BalanceMsg: text; var BalanceLCYMsg: text; var IsHandled: Boolean);
    var
        ContrServices: record "S4LA Contract Service";
        AmtNominal: Decimal;
        Services: record "S4LA service";
        Descr: text[100];
        DescriptionList: List of [Text]; //SOLV-582
        Text001: Label 'Activation (%1) %2', Comment = 'LTH="Aktyvavimas (%1) %2"';
        IsServiceFinanced: Boolean;
        IsServicePurchOnActivation: Boolean;
        InitialInvoiceDescr: Text; //SOLV-441
        InvoicingType: Record "S4LA Invoice Type"; //SOLV-582
        IsLeaseInventory: Boolean;
        FinProduct: Record "S4LA Financial Product";
        Asset: Record "S4LA Asset";
        LeasingPostingSetup: Record "S4LA Leasing Posting Setup";
        InitialInvoiceReceivablesType: Enum "S4LA Leasing Receivables Type";
        SalesLineType: Enum "Sales Line Type"; //SOLV-441
        LeasingReceivablesType: Enum "S4LA Leasing Receivables Type"; //SOLV-313
        BusPurchVATgr: Code[20];
        BusSalesVATgr: Code[20];
        ProdPurchVATgr: Code[20];
        ProdSalesVATgr: Code[20];
        AmtInclPurchVAT: Decimal;
        AmtInclSalesVAT: Decimal;
        AmtExVAT: Decimal;
        PrincipalVATRate: Decimal; //SOLV-441
        InterestVATRate: Decimal; //SOLV-441
        InstallmentVATRate: Decimal; //SOLV-441
        IsFinancedInclVAT: Boolean;
        Currency: record Currency;
        RoundingPrecision: Decimal;
        GLSetup: record "General Ledger Setup";
        TotalPurchVATonFinancedItems: Decimal;
        Jnl: record "Gen. Journal Line";
        IsDedicatedAccountForRV: Boolean;
        RVLeaseReceivableAcc: code[20];
        LeaseReceivableAcc: code[20];
    begin
        GLSetup.get;
        FinProduct.get(contr."Financial Product");
        IsLeaseInventory := (FinProduct."Accounting Group" = FinProduct."Accounting Group"::"Lease Inventory"); //for short
        IsDedicatedAccountForRV := (FinProduct."Use Dedicated RV G/L Account") AND NOT IsLeaseInventory;
        LeasingPostingSetup.GetSetupRec(LeasingPostingSetup, Contr."Contract No.");

        case FinProduct."Accounting Group" of
            FinProduct."Accounting Group"::"Gross Receivable":
                begin
                    LeasingPostingSetup.testfield("Gross Receivable (BS)");
                    if IsDedicatedAccountForRV then
                        LeasingPostingSetup.TestField("Receivable - RV Portion (BS)");
                    LeaseReceivableAcc := LeasingPostingSetup."Gross Receivable (BS)";
                    RVLeaseReceivableAcc := LeasingPostingSetup."Receivable - RV Portion (BS)";
                end;
            FinProduct."Accounting Group"::"Net Receivable":
                begin
                    LeasingPostingSetup.testfield("Net Receivable (BS)");
                    LeaseReceivableAcc := LeasingPostingSetup."Net Receivable (BS)";
                    if IsDedicatedAccountForRV then
                        LeasingPostingSetup.TestField("Receivable - RV Portion (BS)");
                    RVLeaseReceivableAcc := LeasingPostingSetup."Receivable - RV Portion (BS)";
                end;
            FinProduct."Accounting Group"::"Lease Inventory":
                LeaseReceivableAcc := '';
        end;
        IsFinancedInclVAT := Sched."Amounts Including VAT";

        if Currency.Get(Contr.CCY)
          then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GLSetup."Amount Rounding Precision";

        ContrServices.reset;
        ContrServices.SetRange("Contract No.", Contr."Contract No.");
        if ContrServices.FindSet() then
            repeat
                //-----
                AmtNominal := ContrServices."Total Amount";
                if AmtNominal <> 0 then begin

                    Services.get(ContrServices.Code);
                    Descr := StrSubstNo(Text001, Services."Posting Description", Contr."Contract No.");
                    //SOLV-441 >>
                    Services.TestField("Posting Description");


                    //SOLV-441 <<
                    IsServiceFinanced := (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Financed Amount");
                    IsServicePurchOnActivation := Services."Service Purchase Posting" = Services."Service Purchase Posting"::"On Activation";

                    //--- find related asset. Only needed in OL, if service financed. Services not linked to any asset will apply to the first asset.
                    if IsServiceFinanced and IsLeaseInventory then begin
                        Asset.reset;
                        Asset.SetRange("Contract No.", Contr."Contract No.");
                        Asset.SetRange("Line No.", ContrServices."Asset Line No.");
                        if not Asset.FindFirst() then begin
                            Asset.SetRange("Line No.");
                            if not Asset.FindFirst() then
                                Asset.init;
                        end;
                    end;

                    case true of
                        //--- Financing Incl VAT (product) and Service is Financed
                        IsFinancedInclVAT and IsServiceFinanced:
                            begin
                                BusPurchVATgr := '';
                                ProdPurchVATgr := '';
                                // BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                                ProdSalesVATgr := Services."VAT Group";
                                AmtInclPurchVAT := AmtNominal;
                                AmtInclSalesVAT := AmtNominal;
                                AmtExVAT := Round(AmtNominal / GetVATfactor(BusSalesVATgr, ProdSalesVATgr), RoundingPrecision);
                            end;
                        //--- Financing Ex VAT (product) and Service is Financed
                        not IsFinancedInclVAT and IsServiceFinanced:
                            begin
                                BusPurchVATgr := GetVendVATGroup(ContrServices."Servicer No.");
                                ProdPurchVATgr := Services."VAT Group";
                                //LO210122 BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                                //LO210122 ProdSalesVATgr := Services."VAT Group";
                                // BusSalesVATgr := '';
                                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                                ProdSalesVATgr := '';
                                AmtInclPurchVAT := Round(AmtNominal * GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                                AmtInclSalesVAT := Round(AmtNominal * GetVATfactor(BusSalesVATgr, ProdSalesVATgr), RoundingPrecision);
                                AmtExVAT := AmtNominal;
                                TotalPurchVATonFinancedItems += AmtInclPurchVAT - AmtNominal;
                            end;
                        //--- Financing Incl VAT (product) and Service is NOT Financed
                        IsFinancedInclVAT and not IsServiceFinanced:
                            begin
                                BusPurchVATgr := GetVendVATGroup(ContrServices."Servicer No.");
                                ProdPurchVATgr := Services."VAT Group";
                                // BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                                ProdSalesVATgr := Services."VAT Group";
                                AmtInclPurchVAT := AmtNominal;
                                AmtInclSalesVAT := AmtNominal;
                                AmtExVAT := Round(AmtNominal / GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                            end;
                        //--- Financing Ex VAT (product), and Service is NOT Financed
                        not IsFinancedInclVAT and not IsServiceFinanced:
                            begin
                                BusPurchVATgr := GetVendVATGroup(ContrServices."Servicer No.");
                                ProdPurchVATgr := Services."VAT Group";
                                // BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                                ProdSalesVATgr := Services."VAT Group";
                                AmtInclPurchVAT := Round(AmtNominal * GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                                AmtInclSalesVAT := Round(AmtNominal * GetVATfactor(BusSalesVATgr, ProdSalesVATgr), RoundingPrecision);
                                AmtExVAT := AmtNominal;
                            end;
                    end;
                    //------ SERVICE cases
                    case true of
                        //--- Case "Re-charge Actual Cost"
                        ContrServices."Payment Due" = ContrServices."Payment Due"::"Re-charge Actual Cost":
                            begin
                                //no postings on Activation
                            end;

                        //--- Case 3.0.1 Acquisition Source Lessor Service financed, Post to Receivable, Bal. with Service Income
                        not IsLeaseInventory and (ContrServices."Acquisition Source" = ContrServices."Acquisition Source"::Lessor) and
                        (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Financed Amount"):
                            begin
                                Services.TestField("Service Income Acc. (Cr)"); //SOLV-769
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                        Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");

                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Income Acc. (Cr)",
                                        Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");

                            end;

                        //--- Case 3.0.2 Acquisition Source Lessor Service financed, Post to FA, Bal. with Service Income
                        IsLeaseInventory and (ContrServices."Acquisition Source" = ContrServices."Acquisition Source"::Lessor) and
                         (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Financed Amount"):
                            begin
                                FinProduct.TestField("FA Depreciation Book Code"); //SOLV-430
                                LeasingPostingSetup.TestField("Op. Lease Inv. (Post. Gr.)"); //SOLV-430
                                Services.TestField("Service Income Acc. (Cr)"); //SOLV-769
                                Asset.TestField("Asset No."); //SOLV-769
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", Asset."Asset No.",
                                        Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");

                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Income Acc. (Cr)",
                                        Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");

                            end;

                        //--- Case 3.0.3 Acquisition Source Lessor, Service upfront, Posto to Customer, Bal. with Service Income
                        (ContrServices."Acquisition Source" = ContrServices."Acquisition Source"::Lessor) and
                        (ContrServices."Payment Due" = ContrServices."Payment Due"::"With Upfront Fees"):
                            begin
                                Services.TestField("Service Income Acc. (Cr)"); //SOLV-769
                                                                                //SOLV-275 >>
                                IF isPartOfInitialInvoice(InitialInvoiceReceivablesType::"Services Upfront", Contr) then
                                    Sender.CreateContrInitialInvoicesPosting(InitialInvoiceReceivablesType::"Services Upfront", Contr."Customer No.", 0,
                                                                      SalesLineType::"G/L Account", Services."Service Income Acc. (Cr)", '', InitialInvoiceDescr, AmtInclSalesVAT, BusSalesVATgr, ProdSalesVATgr)
                                else begin
                                    //SOLV-275 <<
                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                            Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");

                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Income Acc. (Cr)",
                                            Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                end; //SOLV-275
                            end;

                        //--- Case 3.0.4 Acquisition Source Lessor, Service Included in Installment, no postings on Activation
                        (ContrServices."Acquisition Source" = ContrServices."Acquisition Source"::Lessor) and
                        (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Installment"):
                            begin
                                //no postings on Activation
                            end;

                        //--- Case 3.0.5 Acquisition Source Lessor, Re-charge Actual Cost, no postings on Activation
                        (ContrServices."Acquisition Source" = ContrServices."Acquisition Source"::Lessor) and
                        (ContrServices."Payment Due" = ContrServices."Payment Due"::"Re-charge Actual Cost"):
                            begin
                                //no postings on Activation
                            end;

                        //--- Case 3.1 Service upfront, Bal. with Supplier
                        IsServicePurchOnActivation and (ContrServices."Payment Due" = ContrServices."Payment Due"::"With Upfront Fees"):
                            begin
                                Services.TestField("Service Income Acc. (Cr)");
                                Services.TestField("Service Expense Acc. (Dr)");
                                //SOLV-275 >>
                                IF isPartOfInitialInvoice(InitialInvoiceReceivablesType::"Services Upfront", Contr) then
                                    Sender.CreateContrInitialInvoicesPosting(InitialInvoiceReceivablesType::"Services Upfront", Contr."Customer No.", 0,
                                                                      SalesLineType::"G/L Account", Services."Service Income Acc. (Cr)", Services."Revenue Amort. Profile Code", InitialInvoiceDescr, AmtInclSalesVAT, BusSalesVATgr, ProdSalesVATgr)
                                else begin
                                    //SOLV-275 <<

                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                            Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");
                                    //SOLV-275
                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Income Acc. (Cr)",
                                                Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                end; //SOLV-275
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Expense Acc. (Dr)",
                                        Descr, AmtInclPurchVAT, 'Purchase', BusPurchVATgr, ProdPurchVATgr, jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::Vendor, ContrServices."Servicer No.",
                                        Descr, -AmtInclPurchVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 3.2 FL, Service financed, Bal. with Supplier
                        IsServicePurchOnActivation and not IsLeaseInventory and (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Financed Amount"):
                            begin
                                ContrServices.TestField("Servicer No."); //SOLV-769
                                sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                        Descr, AmtInclPurchVAT, 'Purchase', BusPurchVATgr, ProdPurchVATgr, jnl."Tax Liable");
                                sender.CreateJnl(Jnl, Jnl."Account Type"::Vendor, ContrServices."Servicer No.",
                                        Descr, -AmtInclPurchVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 3.2 OL, Service financed, Bal. with Supplier
                        IsServicePurchOnActivation and IsLeaseInventory and (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Financed Amount"):
                            begin
                                FinProduct.TestField("FA Depreciation Book Code"); //SOLV-430
                                LeasingPostingSetup.TestField("Op. Lease Inv. (Post. Gr.)"); //SOLV-430
                                Asset.TestField("Asset No."); //SOLV-769
                                ContrServices.TestField("Servicer No."); //SOLV-769
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", Asset."Asset No.",
                                        Descr, AmtInclPurchVAT, 'Purchase', BusPurchVATgr, ProdPurchVATgr, jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::Vendor, ContrServices."Servicer No.",
                                        Descr, -AmtInclPurchVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 3.3 Service in Installment, Bal. with Supplier
                        IsServicePurchOnActivation and (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Installment"):
                            begin
                                Services.TestField("Service Expense Acc. (Dr)");
                                ContrServices.TestField("Servicer No."); //SOLV-769
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Expense Acc. (Dr)",
                                        Descr, AmtInclPurchVAT, 'Purchase', BusPurchVATgr, ProdPurchVATgr, jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::Vendor, ContrServices."Servicer No.",
                                        Descr, -AmtInclPurchVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 3.4 Service upfront, Bal. with PO
                        not IsServicePurchOnActivation and (ContrServices."Payment Due" = ContrServices."Payment Due"::"With Upfront Fees"):
                            begin
                                Services.TestField("Service Income Acc. (Cr)");
                                Services.TestField("Service Expense Acc. (Dr)");
                                //LeasingPostingSetup.TestField("Supplier Clearing Acc. (Cr)");
                                Services.TestField("PYA Serv. Clearing Acc. (Cr)");
                                //SOLV-275 >>
                                IF isPartOfInitialInvoice(InitialInvoiceReceivablesType::"Services Upfront", Contr) then
                                    sender.CreateContrInitialInvoicesPosting(InitialInvoiceReceivablesType::"Services Upfront", Contr."Customer No.", 0,
                                                                      SalesLineType::"G/L Account", Services."Service Income Acc. (Cr)", '', InitialInvoiceDescr, AmtInclSalesVAT, BusSalesVATgr, ProdSalesVATgr)
                                else begin
                                    //SOLV-275 <<
                                    sender.CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                            Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");

                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Income Acc. (Cr)",
                                            Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                end; //SOLV-275
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Expense Acc. (Dr)",
                                        Descr, AmtExVAT, '', '', '', jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."PYA Serv. Clearing Acc. (Cr)",
                                        Descr, -AmtExVAT, '', '', '', jnl."Tax Liable");
                            end;

                        //--- Case 3.5 FL, Service financed, Bal. with PO
                        not IsServicePurchOnActivation and not IsLeaseInventory and (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Financed Amount"):
                            begin
                                //LeasingPostingSetup.TestField("Supplier Clearing Acc. (Cr)");
                                Services.TestField("PYA Serv. Clearing Acc. (Cr)");

                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                        Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."PYA Serv. Clearing Acc. (Cr)",
                                        Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                            end;

                        //--- Case 3.5 OL, Service financed, Bal. with PO
                        not IsServicePurchOnActivation and IsLeaseInventory and (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Financed Amount"):
                            begin

                                FinProduct.TestField("FA Depreciation Book Code"); //SOLV-430
                                Services.TestField("PYA Serv. Clearing Acc. (Cr)");
                                //LeasingPostingSetup.TestField("Op. Lease Inv. (Post. Gr.)"); //SOLV-430

                                Asset.TestField("Asset No."); //SOLV-769
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", Asset."Asset No.",
                                        Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."PYA Serv. Clearing Acc. (Cr)",
                                        Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                            end;
                        //--- Case 3.6 Service in Installment, Bal. with PO
                        not IsServicePurchOnActivation and (ContrServices."Payment Due" = ContrServices."Payment Due"::"Included in Installment"):
                            begin
                                Services.TestField("Service Expense Acc. (Dr)");
                                Services.TestField("PYA Serv. Clearing Acc. (Cr)");
                                // LeasingPostingSetup.TestField("Supplier Clearing Acc. (Cr)");

                                sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."Service Expense Acc. (Dr)",
                                        Descr, AmtExVAT, '', '', '', jnl."Tax Liable");
                                sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Services."PYA Serv. Clearing Acc. (Cr)",
                                        Descr, -AmtExVAT, '', '', '', jnl."Tax Liable");
                            end;
                        else
                            error('Case of "Services" not implemented. Contract No. %1', Contr."Contract No.");
                    end;
                end;
            until ContrServices.Next() = 0;

        IsHandled := true;
    end;

    local procedure isPartOfInitialInvoice(ReceivablesType: Enum "S4LA Leasing Receivables Type"; Contract: Record "S4LA Contract"): Boolean
    var
        InitInvPostSetup: Record "S4LA Leasing Posting Setup";
    begin
        Clear(InitInvPostSetup);
        InitInvPostSetup.SetRange("Receivables Type", ReceivablesType);
        InitInvPostSetup.SETRANGE("Fin. Product", Contract."Financial Product");
        IF InitInvPostSetup.IsEmpty then begin
            InitInvPostSetup.SETRANGE("Fin. Product", '');
            IF InitInvPostSetup.IsEmpty then
                exit(false);
        end;
        exit(true);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"NA Contract Activate", 'OnBeforeContrInsurancePosting_DoJournalPostings', '', false, false)]
    local procedure BeforeContrInsurancePosting_DoJournalPostings(var sender: codeunit "NA Contract Activate"; var Contr: Record "S4LA Contract"; var Sched: Record "S4LA Schedule"; PostingDate: date; PostingDocNo: code[20]; var BalanceTot: Decimal; var BalanceTotLCY: Decimal; var BalanceMsg: text; var BalanceLCYMsg: text; var IsHandled: Boolean);
    var
        ContrInsurance: record "S4LA Contract Insurance";
        Insurance: Record "S4LA Insurance";
        AmtNominal: Decimal;
        Services: record "S4LA service";
        Descr: text[100];
        DescriptionList: List of [Text]; //SOLV-582
        Text001: Label 'Activation (%1) %2', Comment = 'LTH="Aktyvavimas (%1) %2"';
        IsServiceFinanced: Boolean;
        IsServicePurchOnActivation: Boolean;
        InitialInvoiceDescr: Text; //SOLV-441                                          
        IsLeaseInventory: Boolean;
        FinProduct: Record "S4LA Financial Product";
        Asset: Record "S4LA Asset";
        InitialInvoiceReceivablesType: Enum "S4LA Leasing Receivables Type";
        SalesLineType: Enum "Sales Line Type"; //SOLV-441
        LeasingReceivablesType: Enum "S4LA Leasing Receivables Type"; //SOLV-313
        BusPurchVATgr: Code[20];
        BusSalesVATgr: Code[20];
        ProdPurchVATgr: Code[20];
        ProdSalesVATgr: Code[20];
        AmtInclPurchVAT: Decimal;
        AmtInclSalesVAT: Decimal;
        AmtExVAT: Decimal;
        PrincipalVATRate: Decimal; //SOLV-441
        InterestVATRate: Decimal; //SOLV-441
        InstallmentVATRate: Decimal; //SOLV-441
        IsFinancedInclVAT: Boolean;
        Currency: record Currency;
        RoundingPrecision: Decimal;
        GLSetup: record "General Ledger Setup";
        TotalPurchVATonFinancedItems: Decimal;
        Jnl: record "Gen. Journal Line";
        IsDedicatedAccountForRV: Boolean;
        RVLeaseReceivableAcc: code[20];
        LeaseReceivableAcc: code[20];
        IsInsurancePurchOnActivation: Boolean;
        IsInsuranceFinanced: Boolean;

    begin
        FinProduct.get(contr."Financial Product");
        IsLeaseInventory := (FinProduct."Accounting Group" = FinProduct."Accounting Group"::"Lease Inventory"); //for short
        IsDedicatedAccountForRV := (FinProduct."Use Dedicated RV G/L Account") AND NOT IsLeaseInventory;
        IsFinancedInclVAT := Sched."Amounts Including VAT";

        ContrInsurance.reset;
        ContrInsurance.SetRange("Contract No.", Contr."Contract No.");
        if ContrInsurance.FindSet() then
            repeat
                AmtNominal := ContrInsurance."Total Amount";
                if AmtNominal <> 0 then begin

                    Insurance.get(ContrInsurance."Insurance Product Code");
                    Descr := StrSubstNo(Text001, Insurance."Description", Contr."Contract No.");
                    //SOLV-441 >>
                    Insurance.TestField(Description);
                    //SOLV-441 <<


                    IsInsuranceFinanced := (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"Included in Financed Amount");
                    IsInsurancePurchOnActivation := Insurance."Insurance Purchase Posting" = Insurance."Insurance Purchase Posting"::"On Activation";


                    GLSetup.get;
                    if Currency.Get(Contr.CCY) then
                        RoundingPrecision := Currency."Amount Rounding Precision"
                    else
                        RoundingPrecision := GLSetup."Amount Rounding Precision";

                    //--- find related asset. Only needed in OL, if insurance financed. Insurance not linked to any asset will apply to the first asset.
                    if IsInsuranceFinanced and IsLeaseInventory then begin
                        Asset.reset;
                        Asset.SetRange("Contract No.", Contr."Contract No.");
                        //Asset.SetRange("Line No.", ContrInsurance."Asset Line No.");  //TODO
                        if not Asset.FindFirst() then begin
                            Asset.SetRange("Line No.");
                            if not Asset.FindFirst() then
                                Asset.init;
                        end;
                    end;

                    case true of
                        //--- Financing Incl VAT (product) and Insurance is Financed
                        IsFinancedInclVAT and IsInsuranceFinanced:
                            begin
                                BusPurchVATgr := '';
                                ProdPurchVATgr := '';
                                // BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                                ProdSalesVATgr := Insurance."VAT Group";
                                AmtInclPurchVAT := AmtNominal;
                                AmtInclSalesVAT := AmtNominal;
                                AmtExVAT := Round(AmtNominal / GetVATfactor(BusSalesVATgr, ProdSalesVATgr), RoundingPrecision);
                            end;
                        //--- Financing Ex VAT (product) and Insurance is Financed
                        not IsFinancedInclVAT and IsInsuranceFinanced:
                            begin
                                BusPurchVATgr := GetVendVATGroup(ContrInsurance."Insurer No.");
                                ProdPurchVATgr := Services."VAT Group";
                                // BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                                ProdSalesVATgr := Services."VAT Group";
                                AmtInclPurchVAT := Round(AmtNominal * GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                                AmtInclSalesVAT := Round(AmtNominal * GetVATfactor(BusSalesVATgr, ProdSalesVATgr), RoundingPrecision);
                                AmtExVAT := AmtNominal;
                                TotalPurchVATonFinancedItems += AmtInclPurchVAT - AmtNominal;
                            end;
                        //--- Financing Incl VAT (product) and Insurance is NOT Financed
                        IsFinancedInclVAT and not IsInsuranceFinanced:
                            begin
                                BusPurchVATgr := GetVendVATGroup(ContrInsurance."Insurer No.");
                                ProdPurchVATgr := Services."VAT Group";
                                // BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                                ProdSalesVATgr := Services."VAT Group";
                                AmtInclPurchVAT := AmtNominal;
                                AmtInclSalesVAT := AmtNominal;
                                AmtExVAT := Round(AmtNominal / GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                            end;
                        //--- Financing Ex VAT (product), and Insurance is NOT Financed
                        not IsFinancedInclVAT and not IsInsuranceFinanced:
                            begin
                                BusPurchVATgr := GetVendVATGroup(ContrInsurance."Insurer No.");
                                ProdPurchVATgr := Services."VAT Group";
                                // BusSalesVATgr := LeasingSetup."Lessor Business VAT Group";
                                BusSalesVATgr := Contr."Customer VAT Bus. Group";
                                ProdSalesVATgr := Services."VAT Group";
                                AmtInclPurchVAT := Round(AmtNominal * GetVATfactor(BusPurchVATgr, ProdPurchVATgr), RoundingPrecision);
                                AmtInclSalesVAT := Round(AmtNominal * GetVATfactor(BusSalesVATgr, ProdSalesVATgr), RoundingPrecision);
                                AmtExVAT := AmtNominal;
                            end;
                    end;
                    //------ Insurance cases
                    case true of
                        //--- Case "Re-charge Actual Cost"
                        (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"Re-charge Actual Cost"):
                            begin
                                //no postings on Activation
                            end;
                        //--- Case 4.1 Insurance upfront, Bal. with Supplier
                        IsInsurancePurchOnActivation and (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"With Upfront Fees"):
                            begin
                                Insurance.testfield("Revenue G/L Acc.");
                                //SOLV-275 >>
                                IF isPartOfInitialInvoice(InitialInvoiceReceivablesType::"Insurances Upfront", Contr) then
                                    Sender.CreateContrInitialInvoicesPosting(InitialInvoiceReceivablesType::"Insurances Upfront", Contr."Customer No.", 0,
                                                                      SalesLineType::"G/L Account", Insurance."Revenue G/L Acc.", Insurance."Revenue Amort. Profile", InitialInvoiceDescr, AmtInclSalesVAT, BusSalesVATgr, ProdSalesVATgr)
                                else begin
                                    //SOLV-275 <<
                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                            Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");

                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."Revenue G/L Acc.",
                                            Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                end; //SOLV-275
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."Cost G/L Acc.",
                                        Descr, AmtInclPurchVAT, 'Purchase', BusPurchVATgr, ProdPurchVATgr, jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::Vendor, ContrInsurance."Insurer No.",
                                        Descr, -AmtInclPurchVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 4.2 FL, Insurance financed, Bal. with Supplier
                        IsInsurancePurchOnActivation and not IsLeaseInventory and (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"Included in Financed Amount"):
                            begin
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                        Descr, AmtInclPurchVAT, 'Purchase', BusPurchVATgr, ProdPurchVATgr, jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::Vendor, ContrInsurance."Insurer No.",
                                        Descr, -AmtInclPurchVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 4.2 OL, Insurance financed, Bal. with Supplier
                        IsInsurancePurchOnActivation and IsLeaseInventory and (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"Included in Financed Amount"):
                            begin
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", Asset."Asset No.",
                                        Descr, AmtInclPurchVAT, 'Purchase', BusPurchVATgr, ProdPurchVATgr, jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::Vendor, ContrInsurance."Insurer No.",
                                        Descr, -AmtInclPurchVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 4.3 Insurance in Installment, Bal. with Supplier
                        IsInsurancePurchOnActivation and (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"Included in Installment"):
                            begin
                                Insurance.testfield("Cost G/L Acc.");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."Cost G/L Acc.",
                                        Descr, AmtInclPurchVAT, 'Purchase', BusPurchVATgr, ProdPurchVATgr, jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::Vendor, ContrInsurance."Insurer No.",
                                        Descr, -AmtInclPurchVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 4.4 Insurance upfront, Bal. with PO
                        not IsInsurancePurchOnActivation and (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"With Upfront Fees"):
                            begin
                                Insurance.testfield("Revenue G/L Acc.");
                                Insurance.testfield("Cost G/L Acc.");
                                //LeasingPostingSetup.testfield("Supplier Clearing Acc. (Cr)");
                                Insurance.TestField("PYA Ins. Prod Clr. Acc. (Cr)");

                                //SOLV-275 >>
                                IF isPartOfInitialInvoice(InitialInvoiceReceivablesType::"Insurances Upfront", Contr) then
                                    Sender.CreateContrInitialInvoicesPosting(InitialInvoiceReceivablesType::"Insurances Upfront", Contr."Customer No.", 0,
                                                                      SalesLineType::"G/L Account", Insurance."Revenue G/L Acc.", Insurance."Revenue Amort. Profile", InitialInvoiceDescr, AmtInclSalesVAT, BusSalesVATgr, ProdSalesVATgr)
                                else begin
                                    //SOLV-275 <<
                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::Customer, Contr."Customer No.",
                                            Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");

                                    Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."Revenue G/L Acc.",
                                            Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                                end; //SOLV-275
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."Cost G/L Acc.",
                                        Descr, AmtExVAT, '', '', '', jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."PYA Ins. Prod Clr. Acc. (Cr)",
                                        Descr, -AmtExVAT, '', '', '', jnl."Tax Liable");
                            end;
                        //--- Case 4.5 FL, Insurance financed, Bal. with PO
                        not IsInsurancePurchOnActivation and not IsLeaseInventory and (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"Included in Financed Amount"):
                            begin
                                Insurance.TestField("PYA Ins. Prod Clr. Acc. (Cr)");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", LeaseReceivableAcc,
                                        Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."PYA Ins. Prod Clr. Acc. (Cr)",
                                        Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                            end;
                        //--- Case 4.5 OL, Insurance financed, Bal. with PO
                        not IsInsurancePurchOnActivation and IsLeaseInventory and (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"Included in Financed Amount"):
                            begin
                                Insurance.TestField("PYA Ins. Prod Clr. Acc. (Cr)");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"Fixed Asset", Asset."Asset No.",
                                        Descr, AmtInclSalesVAT, '', '', '', jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."PYA Ins. Prod Clr. Acc. (Cr)",
                                        Descr, -AmtInclSalesVAT, 'Sale', BusSalesVATgr, ProdSalesVATgr, jnl."Tax Liable");
                            end;
                        //--- Case 4.6 Insurance in Installment, Bal. with PO
                        not IsInsurancePurchOnActivation and (ContrInsurance."Treat As" = ContrInsurance."Treat As"::"Included in Installment"):
                            begin
                                Insurance.testfield("Cost G/L Acc.");
                                Insurance.TestField("PYA Ins. Prod Clr. Acc. (Cr)");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."Cost G/L Acc.",
                                        Descr, AmtExVAT, '', '', '', jnl."Tax Liable");
                                Sender.CreateJnl(Jnl, Jnl."Account Type"::"G/L Account", Insurance."PYA Ins. Prod Clr. Acc. (Cr)",
                                        Descr, -AmtExVAT, '', '', '', jnl."Tax Liable");
                            end;
                        else
                            error('Case of "Insurance" not implemented. Contract No. %1', Contr."Contract No.");
                    end;
                end;

            until ContrInsurance.Next() = 0;
        IsHandled := true;
    end;
    //BA220406 - Asset return
    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnOLAssetReturnedDate_BeforeValidate', '', false, false)]
    local procedure Asset_OnOLAssetReturnedDate_BeforeValidate(var Rec: Record "S4LA Asset"; var isHandled: Boolean)

    var
        FixedAsset: Record "Fixed Asset";
        FABook: Record "FA Depreciation Book";
        Contr: Record "S4LA Contract";
        Sched: Record "S4LA Schedule";
        CalcDepriciation: Report "Calculate Depreciation";
        LSetup: Record "S4LA Leasing Setup";
        FA2: Record "Fixed Asset";
        GenJnl: Record "Gen. Journal Line";
        LeasingSetup: Record "S4LA Leasing Setup";
        LeasePostingSetup: Record "S4LA Leasing Posting Setup";
        AssetStatus: record "S4LA Status";
        FinProduct: Record "S4LA Financial Product";
    begin
        with Rec do begin

            //>>PA150314
            //IF (("OL Asset Returned Date" <> 0D) AND ("OL Asset Returned Date" < WORKDATE))THEN
            Contr.GET("Contract No.");//DV180216
            FinProduct.get(contr."Financial Product");
            Contr.GetValidSchedule(Sched);//DV180216
            IF (("OL Asset Returned Date" <> 0D) AND ("OL Asset Returned Date" < Sched."Starting Date")) THEN//DV180216
                FIELDERROR("OL Asset Returned Date");
            //<<PA150314
            LeasingSetup.GET;//DV170825
                             //>>PB150129 If Asset Returned then should not depriciate
            IF "OL Asset Returned Date" <> 0D THEN BEGIN
                LeasePostingSetup.GetTermSetupRec(LeasePostingSetup, "Contract No.");//DV170825
                VALIDATE("OL Asset Returned", TRUE);
                FixedAsset.GET("Asset No.");
                //>>PA150529
                if FinProduct."Fin. Product Type" = FinProduct."Fin. Product Type"::"Operating Lease" then begin //BA220407
                    FABook.SETRANGE("FA No.", "Asset No.");
                    IF FABook.FINDFIRST THEN BEGIN

                        FABook.VALIDATE("Depreciation Ending Date", 0D);
                        //<<PA150617 sys Aid 18445
                        FABook.MODIFY;
                        //FixedAsset.VALIDATE(Inactive,TRUE);
                    END;
                end;

                AssetStatus.RESET;
                AssetStatus.SETRANGE("Target Table ID", DATABASE::"Fixed Asset");
                AssetStatus.SetRange(code, LeasingSetup."FA Status Filter - Stock"); //BA220406
                // AssetStatus.SETRANGE("Trigger Option No.", FixedAsset."Asset Status Trigger"::"Lease Asset");  // BA220405 no stock option
                AssetStatus.FINDFIRST;
                FixedAsset.GET("Asset No.");//DV180124
                FixedAsset."PYA Asset Status Code" := AssetStatus.Code;
                //FixedAsset."Asset Status Trigger" := AssetStatus."Trigger Option No.";
                //BA211104 -to avoid error when using Validate
                //BA211105 - field changed to Op. Lease Inventory (BS) – Tm
                if FinProduct."Fin. Product Type" = FinProduct."Fin. Product Type"::"Operating Lease" then //BA220407
                    FixedAsset."FA Posting Group" := LeasePostingSetup."Op. Lease Inventory (BS) - Tm";
                // "Op. Lease Inventory (BS) – Tm";

                FixedAsset."NA Return Date" := "OL Asset Returned Date";//DV180124

                FixedAsset.MODIFY;
                //<<PA150529
            END ELSE BEGIN
                LeasePostingSetup.GetSetupRec(LeasePostingSetup, "Contract No.");//DV170825
                "OL Asset Returned" := FALSE;
                FixedAsset.GET("Asset No.");
                //>>PA150530 -
                Contr.GET("Contract No.");
                Contr.GetValidSchedule(Sched);
                if FinProduct."Fin. Product Type" = FinProduct."Fin. Product Type"::"Operating Lease" then begin //BA220407
                    FABook.SETRANGE("FA No.", "Asset No.");
                    IF FABook.FINDFIRST THEN BEGIN
                        FABook.VALIDATE("Depreciation Ending Date", Sched."Ending Date");
                        FABook."FA Posting Group" := LeasePostingSetup."Op. Lease Inv. (Post. Gr.)";
                        FABook.MODIFY;
                        //FixedAsset.VALIDATE(Inactive,TRUE);
                    END;
                    //<<PA150530
                    //BA211104 -to avoid error when using Validate
                    FixedAsset."FA Posting Group" := LeasePostingSetup."Op. Lease Inv. (Post. Gr.)";
                end;
                FixedAsset.VALIDATE("PYA Asset Status Code", LeasingSetup."FA Status - On Active Contract");
                FixedAsset.VALIDATE(Inactive, FALSE);
                FixedAsset.MODIFY;
            END;
            //<<PB150129
            UpdateMaintenanceCostonContract;//>>PB150211
        end;
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Contract Insurance", 'OnAfterValidateEvent', 'Insurance Product Code', false, false)]
    local procedure ContractInsurance_OnAfterValidateCode(var Rec: Record "S4LA Contract Insurance"; var xRec: Record "S4LA Contract Insurance"; CurrFieldNo: Integer)
    var
        InsurProd: Record "S4LA Insurance";
    begin
        if Rec."Insurance Product Code" <> '' then begin
            InsurProd.Get(Rec."Insurance Product Code");
            Rec."Treat As" := InsurProd."Treat As";
        end;
    end;

    //BA220418 - manual installment amounts
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Schedule Calc", 'OnAfterLineInterestAmountRoundingCalcPayments', '', false, false)]
    local procedure beforecalculatetotalAmt(var ScheduleLine: Record "S4LA Schedule Line"; Schedule: Record "S4LA Schedule")
    var
        Currency: record Currency;
        GLSetup: record "General Ledger Setup";
    begin
        if Schedule."PYA Manual Installment Amount" <> 0 then begin
            GLSetup.Get;
            if not Currency.Get(Schedule."Currency Code") then
                Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";

            ScheduleLine."Total Installment" := -Schedule."PYA Manual Installment Amount";
            if Round(((Schedule."Number Of Payment Periods" * Schedule."PYA Manual Installment Amount" - Schedule."Net Capital Amount" + Schedule."Residual Value") / Schedule."Number Of Payment Periods"), 0.01) = 0 then begin
                ScheduleLine."Interest Amount" := 0;
                ScheduleLine.IPMT := 0;
                ScheduleLine."Principal Amount" := ScheduleLine."Total Installment";
            end else begin
                if not ScheduleLine."Interest Not Recalc." then begin
                    if (Schedule."Annuity/Linear" = Schedule."Annuity/Linear"::Annuity) and (Schedule."Installments Due" = Schedule."Installments Due"::"In Advance") and (ScheduleLine.Period = 1) then
                        ScheduleLine."Principal Amount" := Round(ScheduleLine."Total Installment" - ScheduleLine."Interest Amount", Currency."Amount Rounding Precision")
                    else begin
                        ScheduleLine."Interest Amount" := Round(ScheduleLine."Total Installment" - ScheduleLine."Principal Amount", Currency."Amount Rounding Precision");
                        ScheduleLine.IPMT := ScheduleLine."Interest Amount";
                    end;
                end;
            end;
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Schedule Calc", 'OnAfterLineInterestAmountInclVATRoundingCalcPayments', '', false, false)]
    local procedure BeforecalculatetotalAmtVAT(var ScheduleLine: Record "S4LA Schedule Line"; Schedule: Record "S4LA Schedule")
    var
        Currency: record Currency;
        GLSetup: record "General Ledger Setup";
    begin
        if Schedule."PYA Manual Installment Amount" <> 0 then begin
            GLSetup.Get;
            if not Currency.Get(Schedule."Currency Code") then
                Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";

            ScheduleLine."Total Installment" := -Schedule."PYA Manual Installment Amount";
            if Round(((Schedule."Number Of Payment Periods" * Schedule."PYA Manual Installment Amount" - Schedule."Net Capital Amount" + Schedule."Residual Value") / Schedule."Number Of Payment Periods"), 0.01) = 0 then begin
                ScheduleLine."Interest Incl. VAT" := 0;
                ScheduleLine.IPMT := 0;
                ScheduleLine."Interest Incl. VAT" := ScheduleLine."Total Installment";
            end else begin
                if not ScheduleLine."Interest Not Recalc." then begin
                    if (Schedule."Annuity/Linear" = Schedule."Annuity/Linear"::Annuity) and (Schedule."Installments Due" = Schedule."Installments Due"::"In Advance") and (ScheduleLine.Period = 1) then
                        ScheduleLine."Principal Incl. VAT" := Round(ScheduleLine."Total Installment" - ScheduleLine."Principal Incl. VAT", Currency."Amount Rounding Precision")
                    else begin
                        ScheduleLine."Interest Incl. VAT" := Round(ScheduleLine."Total Installment" - ScheduleLine."Principal Incl. VAT", Currency."Amount Rounding Precision");
                        ScheduleLine.IPMT := ScheduleLine."Interest Incl. VAT";
                    end;
                end;
            end;
        end;
    end;
    //--//

    //BA220803 -- Add event to T Value Schedule Calc

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Schedule Calc. - TValue", 'OnAfterInterestAmountCalculatedOnSchedLine_CalcSchedule', '', false, false)]
    local procedure AfterInterestCalc(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line")
    var
        Currency: record Currency;
        GLSetup: record "General Ledger Setup";
    begin
        if Schedule."PYA Manual Installment Amount" <> 0 then begin
            GLSetup.Get;
            if not Currency.Get(Schedule."Currency Code") then
                Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";

            Line."Total Installment" := -Schedule."PYA Manual Installment Amount";
            if Round(((Schedule."Number Of Payment Periods" * Schedule."PYA Manual Installment Amount" - Schedule."Net Capital Amount" + Schedule."Residual Value") / Schedule."Number Of Payment Periods"), 0.01) = 0 then begin
                Line."Interest Incl. VAT" := 0;
                Line.IPMT := 0;
                Line."Interest Incl. VAT" := Line."Total Installment";
            end else begin
                if not Line."Interest Not Recalc." then begin
                    if (Schedule."Annuity/Linear" = Schedule."Annuity/Linear"::Annuity) and (Schedule."Installments Due" = Schedule."Installments Due"::"In Advance") and (Line.Period = 1) then
                        Line."Principal Incl. VAT" := Round(Line."Total Installment" - Line."Principal Incl. VAT", Currency."Amount Rounding Precision")
                    else begin
                        Line."Interest Incl. VAT" := Round(Line."Total Installment" - Line."Principal Incl. VAT", Currency."Amount Rounding Precision");
                        Line.IPMT := Line."Interest Incl. VAT";
                    end;
                end;
            end;
        end;
    end;
    //-//

    //BA220607
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeApplicantBirthDateCheck', '', false, false)]
    local procedure BeforeApplicantBirthDateCheck(Contract: Record "s4la Contract"; Applicant: Record "s4la Applicant"; var isHandled: Boolean)
    var
        ApplicantRole: record "s4la Applicant Role";
    begin
        isHandled := false;
        if ApplicantRole.get(Applicant."Role in Contract") then begin
            if ApplicantRole."PYA Skip Birth Date Check" then
                isHandled := true;
        end;
    end;
    //--//

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostFixedAssetOnAfterSaveGenJnlLineValues', '', false, false)]
    local procedure GenJnlPostLine_OnPostFixedAssetOnAfterSaveGenJnlLineValues(var GenJournalLine: Record "Gen. Journal Line")
    begin
        UpdateInfoWhenPostingToAsset(GenJournalLine);//DV170725
        UpdateFAPostingGroupToAsset(GenJournalLine);//DV170726
    end;

    //BA221028 - update when selling asset
    local procedure UpdateInfoWhenPostingToAsset(recJnlLine: Record "Gen. Journal Line")
    var
        recSchedule: Record "S4LA Schedule";
        NewStatus: Record "s4la Status";
        Contract: Record "S4LA Contract";
        recSourceCodeSetup: Record "Source Code Setup";

        LeasingSetup: Record "s4la Leasing Setup";
        FASetup: Record "FA Setup";
        recFA: Record "Fixed Asset";
        recProduct: Record "s4la Financial Product";
        RecVariant: Variant;
        GateChangeMgt: Codeunit "s4la Status Mgt";
        AssetDeprBook: Record "FA Depreciation Book";
        AssetStatus: Record "s4la Status";
    begin
        //Update Asset status if no contract
        recSourceCodeSetup.get;
        LeasingSetup.get;

        IF recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::Disposal THEN BEGIN
            IF (recJnlLine."Source Code" = recSourceCodeSetup.Sales) AND (recJnlLine."Source Code" <> '') THEN BEGIN
                //--== Asset sold ==--
                recFA.GET(recJnlLine."Account No.");
                IF LeasingSetup."FA Status - Sold" <> '' THEN
                    recFA.VALIDATE("PYA Asset Status Code", LeasingSetup."FA Status - Sold");
                //recFA."PYA Schedule Status Code" := recSchedule."Status Code";
                //recFA."S4L Schedule Status Trigger" := recSchedule.Status;
                if LeasingSetup."FA - Customer Subclass Code" <> '' then
                    recFA."FA Subclass Code" := LeasingSetup."FA - Customer Subclass Code";
                recFA.MODIFY;
            END;
        END;
    end;

    Local Procedure UpdateFAPostingGroupToAsset(recJnlLine: Record "Gen. Journal Line")
    var
        recFA: record "Fixed Asset";
        recFAPostGr: Record "FA Posting Group";
        recFADeprBook: Record "FA Depreciation Book";
    begin
        //Set FA posting group from the last posted entry
        IF recJnlLine."Account Type" <> recJnlLine."Account Type"::"Fixed Asset" THEN
            EXIT;

        IF NOT recFA.GET(recJnlLine."Account No.") THEN
            EXIT;

        IF NOT recFAPostGr.GET(recJnlLine."Posting Group") THEN
            EXIT;

        recFA."FA Posting Group" := recJnlLine."Posting Group";
        recFA.MODIFY;

        recFADeprBook.SETRANGE("FA No.", recJnlLine."Account No.");
        recFADeprBook.MODIFYALL("FA Posting Group", recJnlLine."Posting Group");
    end;   
    */
