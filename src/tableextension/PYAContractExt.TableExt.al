tableextension 17022184 "PYA Contract Ext." extends "S4LA Contract"
{
    fields
    {
        field(17022109; "NA DD Start Date"; Date)
        {
            Caption = 'DD Start Date';
            Description = 'JM170725';
            DataClassification = ToBeClassified;

            //BA220715 - Refresh DD schedule Line
            trigger OnValidate()
            var
                Schedule: Record "S4LA Schedule";
                DDScheduleMgt: Codeunit "S4LA DD Schedule Mgt";
                Contr: record "S4LA contract";
            begin
                if "NA DD Start Date" <> 0D then begin
                    Contr.get("Contract No.");
                    contr."NA DD Start Date" := "NA DD Start Date";
                    Contr.modify;

                    contr.GetValidSchedule(Schedule);

                    DDScheduleMgt.RefreshDDScheduleForSchedule(Schedule);
                end;
            end;
            //--//
        }
        field(17022110; "NA Original Customer Code"; Code[20])
        {
            Caption = 'Original Customer Code';
            Description = 'JM171012';
            TableRelation = Customer;
            DataClassification = ToBeClassified;
        }
        field(17022111; "NA Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            Description = 'DV180124';
            DataClassification = ToBeClassified;
        }
        field(17022114; "NA Extended Date"; Date)
        {
            Caption = 'Extended Date';
            DataClassification = ToBeClassified;
            Description = 'JM181214';
        }
        field(17022180; "PYA GPS Coordinates"; Text[30])
        {
            DataClassification = ToBeClassified;
            Description = 'TG200505';
            Caption = 'GPS Coordinates';

            trigger OnValidate()
            begin
                CheckGPSCoordinates("PYA GPS Coordinates");
            end;
        }

        //BA220221
        field(17022181; "PYA DD Account Type"; Enum "PYA DD Account Type")
        {
            DataClassification = ToBeClassified;
            Description = 'BA220221';
            Caption = 'Account Type';
        }
        //--//

        //BA220406
        field(17022182; "NA Termination Posted Date"; Date)
        {
            Caption = 'Termination Posted Date';
        }
        field(17022183; "PYA Net Capital Amount"; Decimal)
        {
            Caption = 'Net Capital Amount';
        }
        field(17022184; "PYA Tax Area Code"; CODE[20])
        {
            Caption = 'Net Capital Amount';
            TableRelation = "Tax Area";
        }
        field(17022185; "PYA Asset Status Code"; Code[20])
        {
            Description = '';
            caption = 'Asset Status Code';
            TableRelation = "S4LA Status".Code WHERE("Target Table ID" = CONST(5600));
        }
        field(17022186; "PYA Contract Status"; Integer)
        {
            Description = '0=Locked,1=Quote,2=Application,3=Contract,4=Closed,5=Withdrawn';
            caption = 'Contract Status';
            //TableRelation = "S4LA Status".Code WHERE("Target Table ID" = CONST(17021230));
        }
        field(17022187; "PYA Asset Status"; Integer)
        {
            caption = 'Asset Status';
        }
        field(17022188; "PYA Interest Recogn Sched Calc"; Boolean)
        {
            caption = 'Asset Status';
        }
        //--//

        //BA220329
        modify("Customer No.")
        {
            trigger OnAfterValidate()
            begin
                InsertUpdateContrInsurPolicy(Rec); //TG190420
                UpdateDDBankInfo(Rec); //TG190421
            end;
        }
        //--//
    }
    procedure OpenAddressDetailsPageNA()
    var
        ContactAltAddress: Record "Contact Alt. Address";
        State: Record "Country/Region";
        LeasingSetup: Record "s4la Leasing Setup";
        RecREf: RecordRef;
    begin
        // >> SK170925
        LeasingSetup.get;
        RecRef.GetTable(State);
        LeasingSetup.CheckGranActive(RecRef);
        // <<

        //>>PA140924 Func Created to open address page from assist edit
        Commit;
        // >> SK160725
        //PAGE.RUNMODAL(PAGE::"N#Address Details - Contract",Rec);
        ContactAltAddress.Reset;
        ContactAltAddress.SetRange("Contact No.", "Customer No.");
        ContactAltAddress.SetRange("PYA Contract No", "Contract No.");
        //ContactAltAddress.SetRange("Applicant Line No.", 1);
        //ContactAltAddress.SetRange("S4L Address Type", ContactAltAddress."S4L Address Type"::"Primary Address");   // SK161222
        if ContactAltAddress.FindFirst then
            PAGE.RunModal(PAGE::"S4LA Address Details", ContactAltAddress);
        InsertIntoAddressNA;
        // <<
    end;

    procedure InsertIntoAddressNA()
    var
        OriginalStr: Text[250];
        CopiedStr: Text[250];
        i: Integer;
        Addr1: Text[50];
        Addr2: Text[50];
        OriginalStr1: Text[250];
        ContactLocal: Record Contact;
        LeasingContract: Record "s4la Contract";
        ContactAltAddress: Record "Contact Alt. Address";
        Street: Record "s4la Street Type";
        Len2: Integer;
        LengthAddr1: Integer;
        LengthAddr2: Integer;
        AddMgmt: Codeunit "s4la Address Mgt";
        FormattedAddr: array[2] of Text;
    begin
        // >> SK160722
        /*AddMgmt.fnFormatAddr(FormattedAddr,
            "Property Name",
            "Sub Unit Number",
            "Sub Unit Type",
            "Street Number",
            "Street Name",
            "Street Type Code",
            "P.O. Box");
        */

        //ContactAltAddress.Reset;
        //ContactAltAddress.SetRange("Contract No.", "Contract No.");
        //ContactAltAddress.SetRange("Contact No.", "Customer No.");
        //ContactAltAddress.SetRange("Applicant Line No.", 1);
        //ContactAltAddress.SetRange("S4L Address Type", ContactAltAddress."S4L Address Type"::"Primary Address");
        //if ContactAltAddress.FindFirst then
        //AddMgmt.fnFormatAddr(FormattedAddr,
        //ContactAltAddress."S4L Property Name",
        //ContactAltAddress."S4L Sub Unit Number",
        //ContactAltAddress."S4L Sub Unit Type",
        //ContactAltAddress."S4L Street Number",
        //ContactAltAddress."S4L Street Name",
        //ContactAltAddress."S4L Street Type Code",
        //ContactAltAddress."S4L P.O. Box");
        // <<
        GET("Contract No."); //TG190211 - need this or will get error when updating contract rec
        Address := CopyStr(FormattedAddr[1], 1, MaxStrLen(Address));
        "Address 2" := CopyStr(FormattedAddr[2], 1, MaxStrLen("Address 2"));
        Modify();

    end;

    procedure fnStatusToDate(ToDate: Date): Enum "S4LA Contract Status"
    var
        Quote: Record "S4LA Contract";
        SchedStatusHistory: Record "S4LA Status History";
        Sched: Record "S4LA Schedule";
        Sched2: Record "S4LA Schedule";
    begin
        /*KS061205 grazina sutarties busena praeities datai*/
        /*
        0-Quote,
        1-Application,
        2-Contract,
        3-"Closed Contract",
        4-"Withdrawn Application"
        19-None, means, there were no contract at that date
        */

        IF ToDate = 0D THEN
            ToDate := TODAY;

        IF ToDate >= TODAY THEN
            EXIT(Status);

        CASE Status OF  //by actual status...

            Status::Quote:
                BEGIN
                    IF "Contract Date" <= ToDate
                      THEN
                        EXIT(Status)
                    ELSE
                        EXIT(Status);
                END;

            Status::Application:
                BEGIN
                    IF Quote.GET("Quote No.") THEN BEGIN
                        IF (Quote."Contract Created Date" = 0D) OR
                           (Quote."Contract Created Date" > ToDate)
                        THEN BEGIN //not yet project
                            IF Quote."Contract Date" < ToDate
                              THEN
                                EXIT(Status::Quote)
                            ELSE
                                EXIT(Status);
                        END;
                    END;
                END;

            Status::Contract:
                BEGIN
                    IF "Contract Date" > ToDate THEN BEGIN
                        // not yet contract. possibly project
                        IF Quote.GET("Quote No.") THEN BEGIN
                            IF (Quote."Contract Created Date" = 0D) OR
                               (Quote."Contract Created Date" > ToDate)
                            THEN BEGIN //not yet project
                                IF Quote."Contract Date" > ToDate
                                  THEN
                                    //EXIT(19) // no quote at the date
                                    exit
                                ELSE
                                    EXIT(Status::Quote);
                            END ELSE BEGIN
                                EXIT(Status::Application);
                            END;
                        END ELSE BEGIN
                            //migrated contracts do not have relation to quote
                            //EXIT(19);
                            exit;
                        END;
                    END;
                    EXIT(Status);
                END;

            Status::"Closed Contract":
                BEGIN
                    //bu hand-over date
                    Sched2.RESET;
                    Sched2.SETRANGE("Contract No.", "Contract No.");
                    IF Sched2.FINDFIRST THEN
                        REPEAT
                            IF Sched2."Termination Date" > ToDate THEN EXIT(Status::Contract);
                        UNTIL Sched2.NEXT = 0;

                    /*1. find last change to Expired. unill then it was "contract"*/
                    //SL33 SV150121 StatusHistory Changed to Status (Gate) History
                    SchedStatusHistory.RESET;

                    //SL33 SchedStatusHistory.SETCURRENTKEY("Contract No.","Physical Date Time"); //butinai toks raktas
                    SchedStatusHistory.SETRANGE("Target Table ID", DATABASE::"S4LA Schedule");  //Schedule of Payment
                                                                                                //SL33 SchedStatusHistory.SETRANGE("Contract No.","Contract No.");
                    SchedStatusHistory.SETRANGE("Key Field 1 Value", "Contract No.");
                    //SL33 SchedStatusHistory.SETFILTER("Status Trigger",'%1..',SchedStatusHistory."Status Trigger"::"8");
                    SchedStatusHistory.SETFILTER("Trigger Option No.", '%1..', 8);  // 8=Terminated-Stock
                    IF SchedStatusHistory.FINDLAST THEN BEGIN
                        IF SchedStatusHistory."Effective Date" > ToDate THEN BEGIN
                            //-------------contract
                            //EXIT("Sutarties BˇŚsena"::"Sutartis");
                            //patikrinam ar dabar pasibaigusi tada dar buvo projektu
                            IF "Contract Date" > ToDate THEN BEGIN
                                // tuo metu dar nebuvo sutartis. Tai gal buvo projektas
                                IF Quote.GET("Quote No.") THEN BEGIN
                                    IF (Quote."Contract Created Date" = 0D) OR
                                       (Quote."Contract Created Date" > ToDate)
                                    THEN BEGIN //not yet project
                                        IF Quote."Contract Date" > ToDate
                                          THEN
                                            //EXIT(19) // no quote
                                            exit
                                        ELSE
                                            EXIT(Status::Quote);
                                    END ELSE BEGIN
                                        EXIT(Status::Application);
                                    END;
                                END ELSE BEGIN
                                    //migrated contracts do not have relation to quote
                                    //EXIT(19);
                                    exit;
                                END;
                            END;
                            EXIT(Status::Contract);
                            /*------------*/
                        END;
                    END;
                    /*2. by delivery date*/
                    Sched.RESET;
                    Sched.SETCURRENTKEY("Contract No.", "Termination Date");
                    Sched.SETRANGE("Contract No.", "Contract No.");
                    Sched.SETRANGE("Version status", Sched."Version status"::Valid);
                    Sched.SETRANGE("Termination Date", 0D);
                    IF NOT Sched.FINDFIRST THEN BEGIN //jei viskas atiduota
                        Sched.SETRANGE("Termination Date");
                        IF Sched.FINDLAST THEN
                            IF Sched."Termination Date" > ToDate THEN BEGIN //jei paskutinis atidavimas vˇōliau uˇś atask datˇÉ
                                                                            //------------contract
                                IF "Contract Date" > ToDate THEN BEGIN
                                    IF Quote.GET("Quote No.") THEN BEGIN
                                        IF (Quote."Contract Created Date" = 0D) OR
                                           (Quote."Contract Created Date" > ToDate)
                                        THEN BEGIN
                                            IF Quote."Contract Date" > ToDate
                                              THEN
                                                //EXIT(19)
                                                exit
                                            ELSE
                                                EXIT(Status::Quote);
                                        END ELSE BEGIN
                                            EXIT(Status::Application);
                                        END;
                                    END ELSE BEGIN
                                        //
                                        //EXIT(19);
                                        exit;
                                    END;
                                END;
                                EXIT(Status::Contract);
                                /*------------*/
                            END;
                    END;
                    EXIT(Status);
                END;

            Status::"Withdrawn Application":
                EXIT(Status);
        END;
    end;

    procedure CopyQuoteFromQuoteSchedule(recQuoteSchedule: Record "S4LA Schedule")
    var
        LocalText000: Label 'You must create at least one schedule of payment.';
        CurrencyFrom: Code[10];
        CurrencyTo: Code[10];
        recCurrExRate: Record "Currency Exchange Rate";
        recQuote: Record "S4LA Contract";
        recContract: Record "S4LA Contract";
        recNewSchedule: Record "S4LA Schedule";
        varNoCode: Code[30];
        recLeasingType: Record "S4LA Financial Product";
        Guarantee: Record "S4LA Guarantee";
        Guarantee2: Record "S4LA Guarantee";
        NextLineNo: Integer;
        LineNo: Integer;
        LeasingSetup: Record "S4LA Leasing Setup";
        AssetOption: Record "S4LA Asset Option";
        AppNo: Code[20];
        //Disbursment: Record "Disbursement Schedule";
        MessageQuote: Record "S4LA Contract";
        MessageContr: Record "S4LA Contract";
        LastNo: Integer;
        SOP: Record "S4LA Schedule";
        "-- SK160229": Integer;
        ApprovalConditions: Record "S4LA Contr. Approval Condition";
        InterestComponentQuote: Record "S4LA Interest Recogn. Sched.";
        InterestComponentAppl: Record "S4LA Interest Recogn. Sched.";
    begin
        /*TG181217*/ // Copy of the MakeContractFromQuoteSchedule function
        GLSetup.GET;
        recQuote.GET(recQuoteSchedule."Contract No.");
        recQuoteSchedule.GET(recQuoteSchedule."Contract No.", recQuoteSchedule."Schedule No.", recQuoteSchedule."Version No.");/*EN121009*/

        LeasingSetup.GET;
        //LeasingSetup.TESTFIELD("Default Pre-Contract FA Class");
        // SK160617 IF recQuote."S#Asset No." <> '' THEN
        // SK160617  recQuote.TESTFIELD("Customer No."); //Will be needed when assigning asset to schedule

        recQuoteSchedule.TESTFIELD(Recalculate, FALSE);

        //KS160217 no user confirm required
        //IF GUIALLOWED THEN
        //  IF NOT CONFIRM(Text204,FALSE) THEN
        //    EXIT;

        recContract := recQuote;
        recContract."Contract No." := '';
        recContract.VALIDATE(Status, recContract.Status::Quote);
        //recContract."Quote No." := recQuote."Contract No.";
        SalesSetup.GET;
        // SK160617 recContract."S#Fin. Charge Terms" := SalesSetup."S#Default fin. charge cond.";
        FinProd.GET(recQuoteSchedule."Financial Product");
        LeasingSetup.TESTFIELD("Quote Nos.");
        //FinProd.TESTFIELD("Leasing Contract Nos.");
        // SK160617 NoSeriesMgt.InitSeries(FinProd."Leasing Contract Nos.",xRec."No. Series",0D,recContract."Contract No.",recContract."No. Series");

        //JM181211++
        //CLEAR(ManContPage);
        //IF ManContPage.RUNMODAL = ACTION::OK THEN
        //  recContract."Contract No." := ManContPage.GetCont;
        IF recContract."Contract No." = '' THEN
            //JM181211--
            NoSeriesMgt.InitSeries(LeasingSetup."Quote Nos.", '', 0D, recContract."Contract No.", LeasingSetup."Quote Nos."); // SK160617

        recContract.INSERT(TRUE);

        IF recQuote."Sales Officer Code" <> '' THEN
            recContract.VALIDATE("Sales Officer Code", recQuote."Sales Officer Code");

        //ReassignDocuments(recQuote."Contract No.", recContract."Contract No.");

        //recQuote."Created Contract No." := recContract."Contract No.";
        //recQuote."Quote Status" := recQuote."Quote Status"::"Converted to Application";
        //recQuote."Contract Created Date":=TODAY;
        //recQuote.MODIFY(FALSE);

        //recQuoteSchedule.MODIFY(FALSE);

        //recQuote.VALIDATE("Status Code", LeasingSetup."Status - Quote Converted");
        //recQuote.MODIFY;

        // SK160617 recContract."S#From Quote No." := recQuote."Contract No.";
        //recContract."Quote No." := recQuote."Contract No."; // SK160617
        recContract.MODIFY(FALSE);

        //Info from Schedule to Contract
        recContract.CCY := recQuoteSchedule."Currency Code";
        recContract."Financial Product" := recQuoteSchedule."Financial Product";
        // SK160617 recContract."N#Quote Object Value" := recQuoteSchedule."Capital Amount";
        recContract.MODIFY;

        recContract.CopyScheduleForQuoteFromQ(recQuoteSchedule);
        recNewSchedule.SETRANGE("Contract No.", recContract."Contract No.");
        recNewSchedule.FINDFIRST;

        //--- Update Status Code From Schedule
        recContract."Status Code" := recNewSchedule."Status Code";
        recContract.MODIFY;

        //---------
        CopyAssets(recQuote."Contract No.", recContract."Contract No.", FALSE);

        CopyApplicants(recQuote."Contract No.", recContract."Contract No.", FALSE);

        CopyIDDocument(recQuote."Contract No.", recContract."Contract No.", FALSE);  // SK160711
        CopyPhoneNumbers(recQuote."Contract No.", recContract."Contract No.", FALSE);  // SK160727
        CopyEmails(recQuote."Contract No.", recContract."Contract No.", FALSE);  // SK160727

        CopyServicesAndInsurance(recQuote."Contract No.", recContract."Contract No.", recQuoteSchedule."Schedule No.",
                            recNewSchedule."Schedule No.", recQuoteSchedule."Version No.", recNewSchedule."Version No.", FALSE);

        //ReassignMessages(recQuote."Contract No.",recContract."Contract No.",FALSE);

        CopyGuaranties(recQuoteSchedule."Contract No.", recQuoteSchedule."Schedule No.", recContract."Contract No.", '', FALSE);

        CopyAdditionalEquipment(recQuote."Contract No.", recContract."Contract No."
                                    /* , '', recNewSchedule."Schedule No."
                                    , 0, recNewSchedule."Version No." */
                                    , FALSE);

        //--- transfer Options
        AssetOption.RESET;
        AssetOption.SETRANGE("Contract No.", recQuoteSchedule."Contract No.");
        AssetOption.CopyOptionsFromQuoteToContract(AssetOption, recQuoteSchedule."Contract No.", recContract."Contract No.");
        /*---*/

        //KS160308, KS160531
        //--- transfer Interest Components (aka "Commercial Risk Loadings")
        InterestComponentAppl.SETRANGE("Contract No.", recContract."Contract No.");
        InterestComponentAppl.DELETEALL;
        InterestComponentQuote.RESET;
        InterestComponentQuote.SETRANGE("Contract No.", recQuoteSchedule."Contract No.");
        IF InterestComponentQuote.FINDSET THEN
            REPEAT
                InterestComponentAppl := InterestComponentQuote;
                InterestComponentAppl."Contract No." := recContract."Contract No.";
                InterestComponentAppl.INSERT;
            UNTIL InterestComponentQuote.NEXT = 0;
        //---

        // commit and then recalculate
        COMMIT;
        recNewSchedule.SETRANGE("Contract No.", recContract."Contract No.");
        recNewSchedule.FINDFIRST;
        cdLeasingContMgt.RecalcScheduleLines(recNewSchedule);

        //--- generate Disbursment schedule
        //Disbursment.CreateOrUpdateDisbursmentSchedule(recContract."Contract No.");

        //--- generate default approval conditions
        //ApprovalConditions.GenerateDefaultApprovalConditions(recContract); // SK160229

        //KS160212
        COMMIT;
        recContract.GET(recNewSchedule."Contract No."); // refresh curr rec
        IF GUIALLOWED THEN
            PAGE.RUN(PAGE::"S4LA Quote Card", recContract);
        MESSAGE(Text50000, recContract."Contract No.");

        //KS160212 code moved to Page action
        //IF GUIALLOWED THEN
        //  PAGE.RUNMODAL(PAGE::"Application Card",recContract);

    end;

    procedure CopyAssets(FromContractNo: Code[20]; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        ContractSecurity: Record "S4LA Asset";
        ContractSecurityNew: Record "S4LA Asset";
    begin
        /*TG181217*/
        ContractSecurity.RESET;
        ContractSecurity.SETRANGE("Contract No.", FromContractNo);
        IF ContractSecurity.FINDSET THEN
            REPEAT
                ContractSecurityNew.INIT;
                ContractSecurityNew := ContractSecurity;
                ContractSecurityNew."Line No." := ContractSecurity."Line No.";
                ContractSecurityNew."Contract No." := ToContractNo;
                //TG210214
                ContractSecurityNew."Asset No." := '';
                ContractSecurityNew.VIN := '';
                ContractSecurityNew."PO No." := '';
                ContractSecurityNew."PO Line No." := 0;
                ContractSecurityNew."Supplier No." := '';
                ContractSecurityNew."Licence Plate No." := '';
                ContractSecurityNew."Serial No." := '';
                ContractSecurityNew."Engine No." := '';
                ContractSecurityNew."Acquisition Source" := ContractSecurityNew."Acquisition Source"::Stock;
                //---//
                IF NOT ContractSecurityNew.INSERT(FALSE) THEN
                    ContractSecurityNew.MODIFY;
            UNTIL ContractSecurity.NEXT = 0;

        IF DeleteOld THEN
            ContractSecurity.DELETEALL;

    end;

    procedure CopyApplicants(FromContractNo: Code[20]; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        ContractContact: Record "S4LA Applicant";
        ContractContactNew: Record "S4LA Applicant";
    begin
        /*TG181217*/
        ContractContact.SETRANGE("Contract No.", FromContractNo);
        IF ContractContact.FINDSET THEN
            REPEAT
                ContractContactNew.INIT;
                ContractContactNew := ContractContact;
                ContractContactNew."Contract No." := ToContractNo;
                IF NOT ContractContactNew.INSERT(FALSE) THEN
                    ContractContactNew.MODIFY;
                CopyIncome(ContractContact."Contract No.", ContractContact."Line No.", ToContractNo, FALSE);
                CopyExpenditure(ContractContact."Contract No.", ContractContact."Line No.", ToContractNo, FALSE);
                CopyEmployment(ContractContact."Contract No.", ContractContact."Line No.", ToContractNo, FALSE);
                CopyAltAddresses(ContractContact."Contact No.", ContractContact."Contract No.", ContractContact."Line No.", ToContractNo, FALSE);
            UNTIL ContractContact.NEXT = 0;
        IF DeleteOld THEN
            ContractContact.DELETEALL;

    end;

    procedure CopyIncome(FromContractNo: Code[20]; FromContractContactLineNo: Integer; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        ContactIncome: Record "S4LA Applicant Income";
        ContactIncomeNew: Record "S4LA Applicant Income";
    begin
        /*TG181217*/
        //>>NK140910
        ContactIncome.SETRANGE(ContactIncome."Contract No.", FromContractNo);
        ContactIncome.SETRANGE(ContactIncome."Applicant Line No.", FromContractContactLineNo);
        IF ContactIncome.FINDSET THEN
            REPEAT
                ContactIncomeNew.INIT;
                ContactIncomeNew := ContactIncome;
                ContactIncomeNew."Contract No." := ToContractNo;
                ContactIncomeNew.INSERT(TRUE);
            UNTIL ContactIncome.NEXT = 0;
        IF DeleteOld THEN
            ContactIncome.DELETEALL(TRUE);

    end;

    procedure CopyExpenditure(FromContractNo: Code[20]; FromContractContactLineNo: Integer; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        ContactExpenditure: Record "S4LA Applicant Expenditure";
        ContactExpenditureNew: Record "S4LA Applicant Expenditure";
    begin
        /*TG181217*/
        //>>NK140910
        ContactExpenditure.SETRANGE(ContactExpenditure."Contract No.", FromContractNo);
        ContactExpenditure.SETRANGE(ContactExpenditure."Applicant Line No.", FromContractContactLineNo);
        IF ContactExpenditure.FINDSET THEN
            REPEAT
                ContactExpenditureNew.INIT;
                ContactExpenditureNew := ContactExpenditure;
                ContactExpenditureNew."Contract No." := ToContractNo;
                ContactExpenditureNew.INSERT(TRUE);
            UNTIL ContactExpenditure.NEXT = 0;
        IF DeleteOld THEN
            ContactExpenditure.DELETEALL(TRUE);

    end;

    procedure CopyEmployment(FromContractNo: Code[20]; FromContractContactLineNo: Integer; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        ContactEmployment: Record "S4LA Applicant Employment";
        ContactEmploymentNew: Record "S4LA Applicant Employment";
    begin
        /*TG181217*/
        //>>NK140910
        ContactEmployment.SETRANGE(ContactEmployment."Contract No.", FromContractNo);
        ContactEmployment.SETRANGE(ContactEmployment."Applicant Line No.", FromContractContactLineNo);
        IF ContactEmployment.FINDSET THEN
            REPEAT
                ContactEmploymentNew.INIT;
                ContactEmploymentNew := ContactEmployment;
                ContactEmploymentNew."Contract No." := ToContractNo;
                ContactEmploymentNew.INSERT(TRUE);
            UNTIL ContactEmployment.NEXT = 0;
        IF DeleteOld THEN
            ContactEmployment.DELETEALL(TRUE);

    end;

    procedure CopyAltAddresses(FromContactNo: Code[20]; FromContractNo: Code[20]; FromContractContactLineNo: Integer; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        ContactAltAddresses: Record "Contact Alt. Address";
        ContactAltAddressesNew: Record "Contact Alt. Address";
    begin
        /*TG181217*/
        //>>NK140910
        ContactAltAddresses.SETRANGE(ContactAltAddresses."Contact No.", FromContactNo);
        ContactAltAddresses.SETRANGE(ContactAltAddresses."PYA Contract No", FromContractNo);
        //ContactAltAddresses.SETRANGE(ContactAltAddresses."Applicant Line No.", FromContractContactLineNo);
        IF ContactAltAddresses.FINDSET THEN
            REPEAT
                ContactAltAddressesNew.INIT;
                ContactAltAddressesNew := ContactAltAddresses;
                //ContactAltAddressesNew."Contract No." := ToContractNo;
                ContactAltAddressesNew.INSERT(TRUE);
            UNTIL ContactAltAddresses.NEXT = 0;
        IF DeleteOld THEN
            ContactAltAddresses.DELETEALL(TRUE);

    end;

    procedure CopyIDDocument(FromContractNo: Code[20]; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        IDDocument: Record "S4LA ID Document";
        IDDocumentNew: Record "S4LA ID Document";
    begin
        /*TG181217*/
        IDDocument.SETRANGE("Contract No.", FromContractNo);
        IF IDDocument.FINDFIRST THEN
            REPEAT
                IDDocumentNew.INIT;
                IDDocumentNew := IDDocument;
                IDDocumentNew."Contract No." := ToContractNo;
                IDDocumentNew.INSERT;

            UNTIL IDDocument.NEXT = 0;

        IF DeleteOld THEN
            IDDocument.DELETEALL;

    end;

    procedure CopyPhoneNumbers(FromContractNo: Code[20]; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        PhoneNumber: Record "S4LA Phone Number";
        PhoneNumberNew: Record "S4LA Phone Number";
    begin
        /*TG181217*/
        PhoneNumber.SETRANGE("Contract No.", FromContractNo);
        IF PhoneNumber.FINDFIRST THEN
            REPEAT
                PhoneNumberNew.INIT;
                PhoneNumberNew := PhoneNumber;
                PhoneNumberNew."Contract No." := ToContractNo;
                PhoneNumberNew.INSERT;
            UNTIL PhoneNumber.NEXT = 0;

        IF DeleteOld THEN
            PhoneNumber.DELETEALL;

    end;

    procedure CopyEmails(FromContractNo: Code[20]; ToContractNo: Code[20]; DeleteOld: Boolean)
    var
        Email: Record "S4LA Email";
        EmailNew: Record "S4LA Email";
    begin
        /*TG181217*/
        Email.SETRANGE("Contract No.", FromContractNo);
        IF Email.FINDFIRST THEN
            REPEAT
                EmailNew.INIT;
                EmailNew := Email;
                EmailNew."Contract No." := ToContractNo;
                EmailNew.INSERT;
            UNTIL Email.NEXT = 0;

        IF DeleteOld THEN
            Email.DELETEALL;

    end;

    procedure CopyServicesAndInsurance(OldNo: Code[20]; NewNo: Code[20]; OldScheduleNo: Code[20]; NewScheduleNo: Code[20]; OldVersion: Integer; NewVersion: Integer; DeleteOld: Boolean)
    var
        ContractInsurance: Record "S4LA Contract Insurance";
        ContractInsuranceNew: Record "S4LA Contract Insurance";
        ContractFacilities: Record "S4LA Contract Service";
        ContractFacilitiesNew: Record "S4LA Contract Service";
    begin
        /*TG181217*/
        ContractInsurance.SETRANGE("Contract No.", OldNo);
        ContractInsurance.SETRANGE("Schedule No.", OldScheduleNo);
        ContractInsurance.SETRANGE("Version No.", OldVersion);
        IF ContractInsurance.FIND('-') THEN
            REPEAT
                ContractInsuranceNew := ContractInsurance;
                ContractInsuranceNew."Contract No." := NewNo;
                ContractInsuranceNew."Schedule No." := NewScheduleNo;
                ContractInsuranceNew."Version No." := NewVersion;
                ContractInsuranceNew.INSERT;
                IF ContractInsuranceNew."Annual Payment (LCY)" <> 0 THEN BEGIN
                    ContractInsuranceNew.VALIDATE("Annual Payment (LCY)", 0);
                    ContractInsuranceNew.VALIDATE("Annual Payment (LCY)", ContractInsurance."Annual Payment (LCY)");
                    ContractInsuranceNew.MODIFY;
                END;
            UNTIL ContractInsurance.NEXT = 0;
        IF DeleteOld THEN
            ContractInsurance.DELETEALL;

        ContractFacilities.SETRANGE("Contract No.", OldNo);
        ContractFacilities.SETRANGE("Schedule No.", OldScheduleNo);
        ContractFacilities.SETRANGE("Version No.", OldVersion);
        IF ContractFacilities.FIND('-') THEN
            REPEAT
                ContractFacilitiesNew := ContractFacilities;
                ContractFacilitiesNew."Contract No." := NewNo;
                ContractFacilitiesNew."Schedule No." := NewScheduleNo;
                ContractFacilitiesNew."Version No." := NewVersion;
                ContractFacilitiesNew.INSERT;
            UNTIL ContractFacilities.NEXT = 0;
        IF DeleteOld THEN
            ContractFacilities.DELETEALL;

    end;

    procedure CopyGuaranties(FromContractNo: Code[20]; FromScheduleNo: Code[20]; ToContractNo: Code[20]; ToScheduleNo: Code[20]; DeleteOld: Boolean)
    var
        ContractGuaranty: Record "S4LA Guarantee";
        ContractGuarantyNew: Record "S4LA Guarantee";
    begin
        /*TG181217*/
        ContractGuaranty.RESET;
        ContractGuaranty.SETRANGE("PYA Contract No.", FromContractNo);
        //ContractGuaranty.SETRANGE("Schedule No.", FromScheduleNo);
        IF ContractGuaranty.FIND('-') THEN
            REPEAT
                ContractGuarantyNew := ContractGuaranty;
                ContractGuarantyNew."PYA Contract No." := ToContractNo;
                //ContractGuarantyNew."Schedule No." := ToScheduleNo;
                ContractGuarantyNew.INSERT;
            UNTIL ContractGuaranty.NEXT = 0;
        IF DeleteOld THEN
            ContractGuaranty.DELETEALL;

    end;

    procedure CopyAdditionalEquipment(FromContractNo: Code[20]; ToContractNo: Code[20]; /*FromScheduleNo: Code[20]; ToScheduleNo: Code[20]; FromVersion: Integer; ToVersion: Integer;*/ DeleteOld: Boolean)
    var
        ContractGuaranty: Record "S4LA Guarantee";
        ContractGuarantyNew: Record "S4LA Guarantee";
        AddEquipment: Record "S4LA Contr. Asset Add. Equip.";
        AddEquipmentNew: Record "S4LA Contr. Asset Add. Equip.";
        Contract_Local: Record "S4LA Contract";
    begin
        /*TG181217*/
        IF Contract_Local.GET(FromContractNo) THEN BEGIN
            IF (Contract_Local.Status IN [Contract_Local.Status::Quote, Contract_Local.Status::Application]) THEN BEGIN

                AddEquipment.RESET;
                AddEquipment.SETRANGE("Contract No.", FromContractNo);
                IF AddEquipment.FINDSET THEN
                    REPEAT
                        AddEquipmentNew := AddEquipment;
                        AddEquipmentNew."Contract No." := ToContractNo;
                        //MG200901 AddEquipmentNew."Schedule No." := ToScheduleNo;
                        //MG200901 AddEquipmentNew."Version No." := ToVersion;
                        AddEquipmentNew.INSERT;
                    UNTIL AddEquipment.NEXT = 0;
                IF DeleteOld THEN
                    AddEquipment.DELETEALL;
            END;
        END;
    end;

    procedure CopyScheduleForQuoteFromQ(recQuoteSchedule: Record "S4LA Schedule")
    var
        StatusHistory: Record "S4LA Status History";
        StatusHistoryNew: Record "S4LA Status History";
        recQuote: Record "S4LA Contract";
        recGLSetup: Record "General Ledger Setup";
    begin
        /*TG181217*/
        CLEAR(recSchedule);
        recSchedule.SETRANGE("Contract No.", "Contract No.");
        IF NOT recSchedule.FIND('-') THEN BEGIN
            //Create new schedule
            recSchedule := recQuoteSchedule;
            recSchedule.VALIDATE("Contract No.", "Contract No.");
            recSchedule."Schedule No." := "Contract No.";
            recSchedule."Version status" := recSchedule."Version status"::New;
            recSchedule."Version No." := 1;
            recSchedule."Total Accessories" := recQuoteSchedule."Total Accessories";
            recSchedule.INSERT(TRUE);

            /*EN120827*/
            IF recSchedule."Capital Amount" <> 0 THEN BEGIN
                // SK170613 recSchedule."Downpayment %" := recSchedule."Downpayment Amount" / recSchedule."Capital Amount" * 100;
                recSchedule."Residual Value %" := recSchedule."Residual Value" / recSchedule."Capital Amount" * 100;
                //    recSchedule."S#Deposit %" := recSchedule."S#Deposit Amount" / recSchedule."Capital Amount" * 100;
            END;
            /*---*/
            recSchedule.VALIDATE("Capital Amount", recQuoteSchedule."Capital Amount"); /*KS081215 IFAG*/

            recSchedule."Commission Schema" := recQuoteSchedule."Commission Schema";
            recSchedule."Commission Amount (LCY)" := recQuoteSchedule."Commission Amount (LCY)";
            recSchedule."Pay Commission To" := recQuoteSchedule."Pay Commission To";


            //---Reassign Quote Status History (quotation timestamp is important)
            StatusHistory.RESET;
            StatusHistory.SETRANGE("Key Field 1 Value", recQuoteSchedule."Contract No.");
            StatusHistory.SETRANGE("Key Field 2 Value", recQuoteSchedule."Schedule No.");
            StatusHistory.SETRANGE("Key Field 3 Value", FORMAT(recQuoteSchedule."Version No."));
            IF StatusHistory.FINDFIRST THEN
                REPEAT
                    StatusHistoryNew.INIT;
                    StatusHistoryNew := StatusHistory;
                    StatusHistoryNew."Entry No." := 0;
                    StatusHistoryNew."Key Field 1 Value" := recSchedule."Contract No.";
                    StatusHistoryNew."Key Field 2 Value" := recSchedule."Schedule No.";
                    StatusHistoryNew."Key Field 3 Value" := FORMAT(recSchedule."Version No.");
                    StatusHistoryNew.INSERT(TRUE);
                UNTIL StatusHistory.NEXT = 0;
            //---

            recSchedule.PYATriggerStatusChange(recSchedule."PYA Contract Status"::Application, WORKDATE);
            recSchedule.MODIFY(TRUE);
            // >> SK160617
            //Assign Asset if needed
            /*IF recQuote.GET(recQuoteSchedule."Contract No.") THEN
              IF recQuote."S#Asset No." <> '' THEN BEGIN
                //Assign Asset to schedule
                recSchedule."S#Asset No." := recQuote."S#Asset No.";
                recSchedule.AssignAssetToSchedule();
                recSchedule.MODIFY;
              END;
            //---
            */ // <<
        END;

        IF recSchedule.FIND('-') THEN BEGIN
            recSchedule.DELETE;
            CLEAR(recSchedule);
            recSchedule.INIT;
            //Create new schedule
            recSchedule := recQuoteSchedule;
            recSchedule.VALIDATE("Contract No.", "Contract No.");
            recSchedule."Schedule No." := "Contract No.";
            recSchedule."Version status" := recSchedule."Version status"::New;
            recSchedule."Version No." := 1;
            recSchedule."Total Accessories" := recQuoteSchedule."Total Accessories";
            recSchedule.INSERT;

            /*EN120827*/
            IF recSchedule."Capital Amount" <> 0 THEN BEGIN
                // SK170613 recSchedule."Downpayment %" := recSchedule."Downpayment Amount" / recSchedule."Capital Amount" * 100;
                recSchedule."Residual Value %" := recSchedule."Residual Value" / recSchedule."Capital Amount" * 100;
                //    recSchedule."S#Deposit %" := recSchedule."S#Deposit Amount" / recSchedule."Capital Amount" * 100;
            END;
            /*---*/
            recSchedule.VALIDATE("Capital Amount", recQuoteSchedule."Capital Amount"); /*KS081215 IFAG*/

            recSchedule."Commission Schema" := recQuoteSchedule."Commission Schema";
            recSchedule."Commission Amount (LCY)" := recQuoteSchedule."Commission Amount (LCY)";
            recSchedule."Pay Commission To" := recQuoteSchedule."Pay Commission To";


            // //---Reassign Quote Status History (quotation timestamp is important)
            // StatusHistory.RESET;
            // StatusHistory.SETRANGE("Key Field 1 Value",recQuoteSchedule."Contract No.");
            // StatusHistory.SETRANGE("Key Field 2 Value",recQuoteSchedule."Schedule No.");
            // StatusHistory.SETRANGE("Key Field 3 Value",FORMAT(recQuoteSchedule."Version No."));
            // IF StatusHistory.FINDFIRST THEN REPEAT
            //   StatusHistoryNew.INIT;
            //   StatusHistoryNew := StatusHistory;
            //   StatusHistoryNew."Entry No." := 0;
            //   StatusHistoryNew."Key Field 1 Value" := recSchedule."Contract No.";
            //   StatusHistoryNew."Key Field 2 Value" := recSchedule."Schedule No.";
            //   StatusHistoryNew."Key Field 3 Value" := FORMAT(recSchedule."Version No.");
            //   StatusHistoryNew.INSERT(TRUE);
            // UNTIL StatusHistory.NEXT = 0;
            // //---

            //recSchedule.TriggerStatusChange(recSchedule.Status::Application,WORKDATE);
            recSchedule.MODIFY(TRUE);
            // >> SK160617
            //Assign Asset if needed
            /*IF recQuote.GET(recQuoteSchedule."Contract No.") THEN
              IF recQuote."S#Asset No." <> '' THEN BEGIN
                //Assign Asset to schedule
                recSchedule."S#Asset No." := recQuote."S#Asset No.";
                recSchedule.AssignAssetToSchedule();
                recSchedule.MODIFY;
              END;
            //---
            */ // <<
        END;

    end;

    procedure CopyApplFromApplSchedule(var recQuoteSchedule: Record "S4LA Schedule")
    var
        LocalText000: Label 'You must create at least one schedule of payment.';
        CurrencyFrom: Code[10];
        CurrencyTo: Code[10];
        recCurrExRate: Record "Currency Exchange Rate";
        recQuote: Record "S4LA Contract";
        recContract: Record "S4LA Contract";
        recNewSchedule: Record "S4LA Schedule";
        varNoCode: Code[30];
        recLeasingType: Record "S4LA Financial Product";
        Guarantee: Record "S4LA Guarantee";
        Guarantee2: Record "S4LA Guarantee";
        NextLineNo: Integer;
        LineNo: Integer;
        LeasingSetup: Record "S4LA Leasing Setup";
        AssetOption: Record "S4LA Asset Option";
        AppNo: Code[20];
        //Disbursment: Record "Disbursement Schedule";
        MessageQuote: Record "S4LA Message";
        MessageContr: Record "S4LA Message";
        LastNo: Integer;
        SOP: Record "S4LA Schedule";
        "-- SK160229": Integer;
        ApprovalConditions: Record "S4LA Contr. Approval Condition";
        InterestComponentQuote: Record "S4LA Interest Recogn. Sched.";
        InterestComponentAppl: Record "S4LA Interest Recogn. Sched.";
    begin
        /*TG190715*/ // almost an exact copy of MakeContractFromQuoteSchedule
        GLSetup.GET;
        recQuote.GET(recQuoteSchedule."Contract No.");
        recQuoteSchedule.GET(recQuoteSchedule."Contract No.", recQuoteSchedule."Schedule No.", recQuoteSchedule."Version No.");/*EN121009*/

        LeasingSetup.GET;
        LeasingSetup.TESTFIELD("Default Pre-Contract FA Class");
        // SK160617 IF recQuote."S#Asset No." <> '' THEN
        // SK160617  recQuote.TESTFIELD("Customer No."); //Will be needed when assigning asset to schedule


        recQuoteSchedule.TESTFIELD(Recalculate, FALSE);

        //KS160217 no user confirm required
        //IF GUIALLOWED THEN
        //  IF NOT CONFIRM(Text204,FALSE) THEN
        //    EXIT;

        recContract := recQuote;
        recContract."Contract No." := '';
        recContract.VALIDATE(Status, recContract.Status::Application);
        //recContract."Quote No." := recQuote."Contract No.";
        SalesSetup.GET;
        // SK160617 recContract."S#Fin. Charge Terms" := SalesSetup."S#Default fin. charge cond.";
        FinProd.GET(recQuoteSchedule."Financial Product");
        FinProd.TESTFIELD("Leasing Contract Nos.");
        // SK160617 NoSeriesMgt.InitSeries(FinProd."Leasing Contract Nos.",xRec."No. Series",0D,recContract."Contract No.",recContract."No. Series");
        NoSeriesMgt.InitSeries(FinProd."Leasing Contract Nos.", '', 0D, recContract."Contract No.", FinProd."Leasing Contract Nos."); // SK160617


        recContract.INSERT(TRUE);

        //IF recQuote."Sales Officer Code" <> '' THEN
        //  recContract.VALIDATE("Sales Officer Code",recQuote."Sales Officer Code");

        //ReassignDocuments(recQuote."Contract No.", recContract."Contract No.");

        //recQuote."Created Contract No." := recContract."Contract No.";
        //recQuote."Quote Status" := recQuote."Quote Status"::"Converted to Application";
        //recQuote."Contract Created Date":=TODAY;
        //recQuote.MODIFY(FALSE);

        //recQuoteSchedule.MODIFY(FALSE);

        //recQuote.VALIDATE("Status Code", LeasingSetup."Status - Quote Converted");
        //recQuote.MODIFY;

        // SK160617 recContract."S#From Quote No." := recQuote."Contract No.";
        //recContract."Quote No." := recQuote."Contract No."; // SK160617
        //recContract.MODIFY(FALSE);

        //Info from Schedule to Contract
        recContract.CCY := recQuoteSchedule."Currency Code";
        recContract."Financial Product" := recQuoteSchedule."Financial Product";
        // SK160617 recContract."N#Quote Object Value" := recQuoteSchedule."Capital Amount";
        recContract.MODIFY;

        recContract.CopyScheduleForQuoteFromQ(recQuoteSchedule);
        recNewSchedule.SETRANGE("Contract No.", recContract."Contract No.");
        recNewSchedule.FINDFIRST;

        //--- Update Status Code From Schedule
        recContract."Status Code" := recNewSchedule."Status Code";
        recContract.MODIFY;

        //---------
        CopyAssets(recQuote."Contract No.", recContract."Contract No.", FALSE);

        CopyApplicants(recQuote."Contract No.", recContract."Contract No.", false);

        ReassignIDDocument(recQuote."Contract No.", recContract."Contract No.", FALSE);  // SK160711
        ReassignPhoneNumbers(recQuote."Contract No.", recContract."Contract No.", FALSE);  // SK160727
        ReassignEmails(recQuote."Contract No.", recContract."Contract No.", FALSE);  // SK160727

        ReassignServicesAndInsurance(recQuote."Contract No.", recContract."Contract No.", recQuoteSchedule."Schedule No.",
                            recNewSchedule."Schedule No.", recQuoteSchedule."Version No.", recNewSchedule."Version No.", FALSE);

        //ReassignMessages(recQuote."Contract No.",recContract."Contract No.",FALSE);

        ReassignGuaranties(recQuoteSchedule."Contract No.", recQuoteSchedule."Schedule No.", recContract."Contract No.", '', recQuoteSchedule."Version No.", recNewSchedule."Version No.", FALSE);

        ReassignAdditionalEquipment(recQuote."Contract No.", recContract."Contract No."
                                    /*, '',  recNewSchedule."Schedule No."
                                    , 0, recNewSchedule."Version No." */
                                    , FALSE);


        //--- transfer Options
        AssetOption.RESET;
        AssetOption.SETRANGE("Contract No.", recQuoteSchedule."Contract No.");
        AssetOption.CopyOptionsFromQuoteToContract(AssetOption, recQuoteSchedule."Contract No.", recContract."Contract No.");
        /*---*/

        //KS160308, KS160531
        //--- transfer Interest Components (aka "Commercial Risk Loadings")
        InterestComponentAppl.SETRANGE("Contract No.", recContract."Contract No.");
        InterestComponentAppl.DELETEALL;
        InterestComponentQuote.RESET;
        InterestComponentQuote.SETRANGE("Contract No.", recQuoteSchedule."Contract No.");
        IF InterestComponentQuote.FINDSET THEN
            REPEAT
                InterestComponentAppl := InterestComponentQuote;
                InterestComponentAppl."Contract No." := recContract."Contract No.";
                InterestComponentAppl.INSERT;
            UNTIL InterestComponentQuote.NEXT = 0;
        //---

        // commit and then recalculate
        COMMIT;
        recNewSchedule.SETRANGE("Contract No.", recContract."Contract No.");
        recNewSchedule.FINDFIRST;
        cdLeasingContMgt.RecalcScheduleLines(recNewSchedule);

        //--- generate Disbursment schedule
        //Disbursment.CreateOrUpdateDisbursmentSchedule(recContract."Contract No.");

        //--- generate default approval conditions
        ApprovalConditions.GenerateDefaultApprovalConditions(recContract); // SK160229

        MESSAGE(Text205, recContract."Contract No.");
        COMMIT;

        recQuoteSchedule := recNewSchedule;

        //KS160212 code moved to Page action
        //IF GUIALLOWED THEN
        //  PAGE.RUNMODAL(PAGE::"Application Card",recContract);

    end;

    procedure UpdateAssetDim(AssetNo: Code[20])
    var
        DimValue: record "Dimension Value";
        OldDimSetID: Integer;
        DimsetEntry: record "Dimension Set Entry";
        DimMgt: Codeunit DimensionManagement;
        AssetDimCode_ID: Integer;
    begin
        /*TG190413*/
        GLSetup.GET;

        if GLSetup."NA Asset Dimension Code" = '' then
            exit;

        //BA210712 - Asset code dimension to work for both global & shortcut dimensions.
        AssetDimCode_ID := 0;
        DimValue.Reset;
        DimValue.SetRange("Dimension Code", GLSetup."NA Asset Dimension Code");
        DimValue.SetFilter("Global Dimension No.", '>%1', 0);
        if Dimvalue.FindFirst() then
            AssetDimCode_ID := DimValue."Global Dimension No."
        else
            exit;

        ValidateShortcutDimCode(AssetDimCode_ID, AssetNo);
        //--//

    end;

    procedure InsertUpdateContrInsurPolicy(recContract: Record "S4LA Contract")
    var
        ContractInsurPolicy: Record "S4LA Asset Ins. Policy";
        InsurerContact: Record "Contact";
    begin
        //BA211026 - Code Updated 
        IF NOT Contact.GET("Customer No.") then
            EXIT;
        if Rec.Status = Rec.Status::Application then begin

            ContractInsurPolicy.Reset;
            ContractInsurPolicy.SetRange("Contract No.", Rec."Contract No.");
            if not ContractInsurPolicy.FindFirst then begin
                ContractInsurPolicy.Init();
                ContractInsurPolicy."Contract No." := Rec."Contract No.";
                ContractInsurPolicy."asset Line No." := 10000;
                ContractInsurPolicy.Insert;

                if Contact."NA Policy No." <> '' then begin
                    ContractInsurPolicy."Policy No." := Contact."NA Policy No.";
                    ContractInsurPolicy."Insurer No." := Contact."NA Insurer Number";
                    IF InsurerContact.GET(Contact."NA Insurer Number") THEN
                        ContractInsurPolicy."Insurer Name" := InsurerContact.Name;
                    ContractInsurPolicy."Expiry Date" := Contact."NA Expiry Date";
                    ContractInsurPolicy."NA Agent" := Contact."NA Agent";
                    ContractInsurPolicy."NA Agent Phone" := Contact."NA Agent Phone";
                    ContractInsurPolicy."NA Broker" := Contact."NA Broker";
                    ContractInsurPolicy.Modify;
                end;
            end;

        end;

    end;

    procedure UpdateDDBankInfo(var RecContract: Record "S4LA Contract")
    var
        ContactBankAcct: Record "S4LA Contact Bank Account";
    begin
        /*TG190420*/
        Contact.GET("Customer No.");
        ContactBankAcct.RESET;
        ContactBankAcct.SETRANGE("Contact No.", Contact."No.");
        IF NOT ContactBankAcct.FINDFIRST THEN
            EXIT;
        RecContract."DD Bank Account No." := ContactBankAcct."Bank Account No.";
        RecContract."DD Bank Branch No." := ContactBankAcct."Bank Branch No.";
        RecContract."DD Bank Name" := ContactBankAcct.Name;
        //BA220221 
        RecContract."PYA DD Account Type" := ContactBankAcct."NA DD Account Type";
        //--//

    end;

    procedure CanGetNewestSched(var Sched: Record "S4LA Schedule"): Boolean
    begin
        /*TG210211*/
        // Returns schedule record if it can
        // Use when there is only one schedule per contract (Claireview case)
        //    Pre-contract can have only one schelule.
        //    Contract can have several versions of schedule - this function returns NEWEST version (New or Valid), normally, this is needed for printing
        Sched.Reset;
        Sched.SetRange("Contract No.", "Contract No.");
        Sched.SetRange("Version status", Sched."Version status"::New);
        if not Sched.FindLast then begin
            Sched.SetRange("Version status", Sched."Version status"::Valid);
            if not Sched.FindLast then
                exit(false);
        end;
        exit(true);
    end;

    trigger OnAfterInsert()
    var
        LeasingSetup: record "S4LA Leasing Setup";
        CustTemp: record "Customer Templ."; //BA210627  "Customer Template";
        ContactPerson: Record "S4LA Contact Person";
        Sched: Record "S4LA Schedule";
        IsSchedInserted: Boolean;
        OrigContact: Record Contact;
    begin
        LeasingSetup.get;
        IF Status = Status::Quote THEN BEGIN
            /*DV171221*/
            IF LeasingSetup."Cust.Template - Customer" <> '' THEN BEGIN
                CustTemp.GET(LeasingSetup."Cust.Template - Customer");
            END;
            /*---*/

            /*TG200925*/

            IF LeasingSetup."NA Default Originator" <> '' THEN begin
                OrigContact.get(LeasingSetup."NA Default Originator");
                if OrigContact."PYA Is Originator" then
                    VALIDATE("Originator No.", LeasingSetup."NA Default Originator");
                if OrigContact."PYA Is VENDOR" then
                    validate("Supplier No.", LeasingSetup."NA Default Originator");
            end;
            IF LeasingSetup."NA Default Orig. Sales Rep." <> '' THEN
                VALIDATE("Orig. Salesperson No.", LeasingSetup."NA Default Orig. Sales Rep.");

            Modify();
        end;

        //BA210521 added for application
        IF (Status = Status::Application) and ("Quote No." = '') THEN BEGIN
            IF LeasingSetup."NA Default Originator" <> '' THEN begin
                OrigContact.get(LeasingSetup."NA Default Originator");
                if OrigContact."PYA Is Originator" then
                    VALIDATE("Originator No.", LeasingSetup."NA Default Originator");
                if OrigContact."PYA Is VENDOR" then
                    validate("Supplier No.", LeasingSetup."NA Default Originator");
            end;
            IF LeasingSetup."NA Default Orig. Sales Rep." <> '' THEN
                VALIDATE("Orig. Salesperson No.", LeasingSetup."NA Default Orig. Sales Rep.");

            Modify();
        end;

        IF not ((Status = Status::Application) AND ("Quote No." = '')) THEN BEGIN
            //TG210211 - the OnValidate trigger has a GetNewestSchedule call - causing error when creating application
            // because the schedule record hasn't been inserted yet when this code executed
            if CanGetNewestSched(Sched) then
                IsSchedInserted := true;
            //----//

            IF LeasingSetup."NA Default Originator" <> '' THEN begin
                if IsSchedInserted then //TG210211
                    OrigContact.get(LeasingSetup."NA Default Originator");
                if OrigContact."PYA Is Originator" then
                    VALIDATE("Originator No.", LeasingSetup."NA Default Originator")
                //TG210211
                else begin
                    OrigContact.get(LeasingSetup."NA Default Originator");
                    if OrigContact."PYA Is Originator" then
                        "Originator No." := LeasingSetup."NA Default Originator";
                end;
                //---
            end;
            /*TG200925*/
            IF LeasingSetup."NA Default Orig. Sales Rep." <> '' THEN  //BA210527 - Changed the sequence due to table relation with contact
                VALIDATE("Orig. Salesperson No.", LeasingSetup."NA Default Orig. Sales Rep.");
            Modify();//
        end;
    end;

    //BA210519
    trigger OnBeforeInsert()
    var
        leasingSetup: record "S4LA Leasing Setup";
    begin
        leasingSetup.get;
        if (Status = Status::Application) and ("Quote No." = '') then
            "Financial Product" := leasingSetup."Default Financial Product";
    end;

    [Scope('OnPrem')]
    procedure ProcessWebMap()
    var
        TextURL: Label 'https://www.google.com/maps/search/?api=1&query=%1';
    begin
        /*TG200505*/
        TestField("PYA GPS Coordinates");
        HyperLink(StrSubstNo(TextURL, "PYA GPS Coordinates"));

    end;

    [Scope('OnPrem')]
    procedure CheckGPSCoordinates(GPSCoordinates: Text)
    var
        TextLine: Text;
        CommaCount: Integer;
        Text50000: Label 'The GPS coordinates are not formatted correctly.';
        DashCount: Integer;
        SpaceCount: Integer;
        Lattitude: Decimal;
        Longitude: Decimal;
    begin
        "PYA GPS Coordinates" := DelChr("PYA GPS Coordinates", '=', ' '); // clear out any spaces
        GPSCoordinates := "PYA GPS Coordinates";
        /*TG170608*/
        //Check that only one comma in the string
        CommaCount := StrLen(DelChr(GPSCoordinates, '=', DelChr(GPSCoordinates, '=', ',')));
        if CommaCount > 1 then
            Error(Text50000);
        //Check that there are only one or two dashes in the GPS coordinates
        DashCount := StrLen(DelChr(GPSCoordinates, '=', DelChr(GPSCoordinates, '=', '-')));
        if DashCount > 2 then
            Error(Text50000);
        //Check that the string does not contain any spaces
        SpaceCount := StrLen(DelChr(GPSCoordinates, '=', DelChr(GPSCoordinates, '=', ' ')));
        if SpaceCount > 0 then
            Error(Text50000);
        //Check that string only contains certain characters
        if IllegalCharFound(GPSCoordinates) then
            Error(Text50000);
        //Check value to left of comma
        if Evaluate(Lattitude, CopyStr(GPSCoordinates, 1, (CommaPosition(GPSCoordinates) - 1))) then begin
            if not ((Lattitude >= -90) and (Lattitude <= 90)) then
                Error(Text50000);
        end else
            Error(Text50000);
        //Check value to right of comma
        if Evaluate(Longitude, CopyStr(GPSCoordinates, (CommaPosition(GPSCoordinates) + 1), StrLen(GPSCoordinates))) then begin
            if not ((Longitude >= -180) and (Longitude <= 180)) then
                Error(Text50000);
        end else
            Error(Text50000);
        /*---*/

    end;

    local procedure IllegalCharFound(SourceString: Text): Boolean
    var
        CharPos: Integer;
        IFoundIt: Boolean;
        StringLength: Integer;
        TestDecimal: Decimal;
    begin
        /*TG170608*/
        StringLength := StrLen(SourceString);
        CharPos := 0;
        IFoundIt := false;
        repeat
            CharPos += 1;
            if DelChr(CopyStr(SourceString, CharPos, 1), '=', '0123456789.-,') <> '' then
                IFoundIt := true;
        until (IFoundIt or (CharPos = StringLength));
        if IFoundIt then
            exit(true);
        if (CharPos = StringLength) then
            exit(false); // no non-numeric value found
        /*---*/

    end;

    [Scope('OnPrem')]
    procedure CommaPosition(SourceString: Text): Integer
    var
        CharPOS: Integer;
        IFoundIt: Boolean;
    begin
        /*TG170608*/
        if SourceString <> '' then begin
            CharPOS := 0;
            IFoundIt := false;
            repeat
                CharPOS += 1;
                if CopyStr(SourceString, CharPOS, 1) = ',' then
                    IFoundIt := true;
            until (IFoundIt or (CharPOS = StrLen(SourceString)));
            if IFoundIt then
                exit(CharPOS) else
                exit(0);
        end;
        /*---*/

    end;

    [Scope('OnPrem')]
    procedure fnSystemIntRate(var IntRate: Decimal; var IntRateMarkup: Decimal; var FundedRate: Decimal; QuickQuoteNo: Integer; QuickQuoteWksht: Record "Quick Quote Worksheet")
    var
        ProgramRates: Record "S4LA Program Rate";
        LeasingSetup: Record "S4LA Leasing Setup";
        LeasingSetup2: Record "Leasing Setup 2";
        FunderRec: Record "S4LA Funder";
        VariableInterestRates: Record "S4LA Variable Interest Rate";
        Contact: record Contact;
        VarIntValueDate: Date;


    begin
        /*TG191219*/
        if "Contract No." = '' then
            exit;

        GetNewestSchedule(Schedule);
        if Schedule."Interest % Manual" then
            exit;
        if QuickQuoteNo = 0 then
            Schedule.GetRates(ProgramRates)
        else
            QuickQuoteWksht.GetRates(ProgramRates, QuickQuoteNo);

        if ("Customer No." <> '') and Contact.Get("Customer No.") then begin
            if Contact."PYA Use Funded Rate" then begin
                // markup
                if Contact."PYA Use Blended Rate Markup" then begin
                    LeasingSetup2.Get;
                    IntRateMarkup := LeasingSetup2."Blended Rate Markup %";

                end else
                    IntRateMarkup := 0;
                // interest rate
                if Funder <> '' then
                    FunderRec.Get(Funder)
                else
                    FunderRec.Get(Contact."PYA Default Funder");
                if FunderRec.Code <> '' then
                    FundedRate := VariableInterestRates.GetRateForDate(FunderRec.Code, Today, VarIntValueDate);
                if FundedRate <> 0 then
                    IntRate := FundedRate + IntRateMarkup
                else
                    IntRate := ProgramRates."Base Rate" + IntRateMarkup;
            end else begin
                IntRateMarkup := Contact."PYA Interest Rate Markup";
                IntRate := ProgramRates."Base Rate" + IntRateMarkup;
            end;
        end else begin
            IntRate := ProgramRates."Base Rate";
            IntRateMarkup := 0;
        end;

        if IntRate < ProgramRates."Min Rate" then
            IntRate := ProgramRates."Min Rate";

        if (IntRate > ProgramRates."Max Rate") and (ProgramRates."Max Rate" <> 0) then
            IntRate := ProgramRates."Max Rate";

    end;

    procedure UpdateIntRates()
    var
        LSchedule: Record "S4LA Schedule";
        IntRate: Decimal;
        IntRateMarkup: Decimal;
        FundedRate: Decimal;
        QuickQuoteWksht: Record "Quick Quote Worksheet";
        cdLeasingContMgt: Codeunit "S4LA Contract Mgt";

    begin
        //{TG190930} // update interest rates & recalculate schedule when opening card page
        IF NOT (Status IN [Status::Quote, Status::Application]) THEN
            EXIT;

        LSchedule.RESET;
        LSchedule.SETRANGE("Contract No.", "Contract No.");
        LSchedule.SETRANGE("Version status", LSchedule."Version status"::New);
        IF NOT LSchedule.FINDLAST THEN BEGIN
            LSchedule.SETRANGE("Version status", LSchedule."Version status"::Valid);
            IF NOT LSchedule.FINDLAST THEN
                EXIT;
        END;

        IF LSchedule."PYA Interest Rate Modified" THEN
            EXIT;

        fnSystemIntRate(IntRate, IntRateMarkup, FundedRate, 0, QuickQuoteWksht);
        IF (Schedule."Interest %" = IntRate) AND (Schedule."PYA Interest Rate Markup" = IntRateMarkup) THEN
            EXIT;

        LSchedule.UpdateInterestRate;
        LSchedule.Recalculate := TRUE;
        LSchedule.MODIFY;
        cdLeasingContMgt.RecalcScheduleLines(LSchedule);

    end;

    var
        Schedule: Record "S4LA Schedule";
        Text522: Label 'Can''t have the same quote number twice';
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        FinProd: Record "S4LA Financial Product";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        Text50000: Label 'Created Quote No. %1';
        recSchedule: Record "S4LA Schedule";
        cdLeasingContMgt: Codeunit "S4LA Contract Mgt";
        Text205: Label 'Created Application No. %1';
        Contact: record Contact;
}