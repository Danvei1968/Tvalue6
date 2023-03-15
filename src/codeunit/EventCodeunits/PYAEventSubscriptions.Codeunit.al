codeunit 17022090 "S4LNA Event Subscriptions"
{
    //   DV170404 add ext doc no & Update the sales inv
    //   DV170711 - Add Rental Fields
    //   SK170712 - Populate schedule field
    //   DV170718 - set "Insurance Deductible" from setup & Add Rates
    //   DV170807 - Add Customer & Driver age
    //   DV170906 - Fix Contract lookup
    //   DV170919 - Carry forward the tax info to the sales Hdr/lines
    //   DV170920 - Add Available for rental on asset & Contact Person
    //   DV170921 - Default insurance & Discount %
    //   JM171025 - Fix Tax Area Code issue
    //   DV190626 - Update ENU captions
    //   TG200511 - when looking up contracts, only lookup status of Contract or application (not quotes and closed contracts_
    //   TG200511 - correct the TableRelation for Asset No. to not validate the "Available for Rental" field
    //   EN210325 - Schedule_OnValidateInterestPct_BeforeRecalc update, Schedule_OnUpdateCapitalAmount_BeforeUpdateInterest update

    SingleInstance = true;

    var
        FirstCustEntry: Record "Cust. Ledger Entry";
        OnBeforeApplyCustLedgEntry_Cust: Record Customer;

    //Contact
    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnCreateCustomerFromTemplateOnBeforeCustomerInsert', '', false, false)]
    local procedure Contact_OnBeforeCustomerInsert(var Cust: Record Customer; CustomerTemplate: Code[20]; var Contact: Record Contact)
    begin
        //KS170209 NA
        Cust."Tax Area Code" := Contact."PYA Tax Area Code";
        Cust."Tax Liable" := Contact."PYA Tax Liable";
        //---
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnCreateCustomerOnBeforeUpdateQuotes', '', false, false)]
    local procedure Contact_OnCreateCustomerOnBeforeUpdateQuotes(var Customer: Record Customer; Contact: Record Contact)
    begin
        //TG210119
        Customer."Tax Area Code" := Contact."PYA Tax Area Code";
        Customer."Tax Liable" := Contact."PYA Tax Liable";
        Customer.Modify();
        //---
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeVendorInsert', '', false, false)]
    local procedure Contact_OnBeforeVendorInsert(var Vend: Record Vendor; var Contact: Record Contact)
    begin
        //KS170209 NA
        Vend."Tax Area Code" := Contact."PYA Tax Area Code";
        Vend."Tax Liable" := Contact."PYA Tax Liable";
        //---
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeIsUpdateNeeded', '', false, false)]
    local procedure Contact_OnBeforeIsUpdateNeeded(Contact: Record Contact; xContact: Record Contact; var UpdateNeeded: Boolean)
    begin
        if
            (Contact."PYA Tax Area Code" <> xContact."PYA Tax Area Code") or //DV181105
            (Contact."PYA Tax Liable" <> xContact."PYA Tax Liable") //DV181105
        then
            UpdateNeeded := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeCreateCustomerFromTemplate', '', false, false)]
    local procedure Contact_OnBeforeCreateCustomer(var Contact: Record Contact; var CustNo: Code[20]; var IsHandled: Boolean; CustomerTemplate: Code[20]; HideValidationDialog: Boolean)
    var
        Cust: Record Customer;
        ContBusRel: Record "Contact Business Relation";
        CustTemplate: Record "Customer Templ.";
        OfficeMgt: Codeunit "Office Management";
        RMSetup: Record "Marketing Setup";
        ContComp: Record Contact;
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        LeaseSetup: Record "S4LA Leasing Setup";
        CampaignMgt: Codeunit "Campaign Target Group Mgt";
        CustBank: Record "Customer Bank Account";
        DefaultDim: Record "Default Dimension";
        DefaultDim2: Record "Default Dimension";
        ContBank: Record "S4LA Contact Bank Account";
        cont2: Record Contact;
        RelatedRecordIsCreatedMsg: Label 'The %1 Record has been created.', Comment = 'The Customer Record has been created.';
    begin
        IsHandled := true;
        if Cust.Get(Contact."No.") then
            exit;

        Contact.CheckForExistingRelationships(ContBusRel."Link to Table"::Customer);
        Contact.CheckIfPrivacyBlockedGeneric();
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Customers");

        if CustomerTemplate <> '' then
            if CustTemplate.Get(CustomerTemplate) then;

        Clear(Cust);
        Cust.SetInsertFromContact(true);
        Cust."Contact Type" := Contact.Type;
        Cust."No." := Contact."No.";
        Cust."Application Method" := Cust."Application Method"::Manual;
        Cust."Tax Area Code" := Contact."PYA Tax Area Code";
        Cust."Tax Liable" := Contact."PYA Tax Liable";
        Cust.Insert(true);
        Cust.SetInsertFromContact(false);
        if Contact.Type = Contact.Type::Company then
            ContComp := Contact
        else
            ContComp.Get(Contact."Company No.");
        CustNo := Cust."No.";

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Customer;
        ContBusRel."No." := Cust."No.";
        ContBusRel.Insert(true);

        UpdateCustVendBank.UpdateCustomer(ContComp, ContBusRel);

        Cust.Get(ContBusRel."No.");
        if Contact.Type = Contact.Type::Company then
            Cust.Validate(Name, Contact.Name);

        Cust.Modify();

        if CustomerTemplate = '' then begin
            LeaseSetup.Get();
            if Contact."PYA Is Customer" then
                CustomerTemplate := LeaseSetup."Cust.Template - Customer";
            if Contact."PYA Is Originator" then
                CustomerTemplate := LeaseSetup."Cust.Template - Originator";
            if Contact."PYA Is Vendor" then
                CustomerTemplate := LeaseSetup."Cust.Template - Supplier";
        end;

        CustTemplate.Get(CustomerTemplate);

        if CustTemplate.Code <> '' then begin
            if Contact."Territory Code" = '' then
                Cust."Territory Code" := CustTemplate."Territory Code"
            else
                Cust."Territory Code" := Contact."Territory Code";
            if Contact."Currency Code" = '' then
                Cust."Currency Code" := CustTemplate."Currency Code"
            else
                Cust."Currency Code" := Contact."Currency Code";
            if Contact."Country/Region Code" = '' then
                Cust."Country/Region Code" := CustTemplate."Country/Region Code"
            else
                Cust."Country/Region Code" := Contact."Country/Region Code";

            if Cust."Gen. Bus. Posting Group" = '' then
                Cust."Gen. Bus. Posting Group" := CustTemplate."Gen. Bus. Posting Group";
            if Cust."Customer Posting Group" = '' then
                Cust."Customer Posting Group" := CustTemplate."Customer Posting Group";
            if Cust."VAT Bus. Posting Group" = '' then
                Cust."VAT Bus. Posting Group" := CustTemplate."VAT Bus. Posting Group";
            if Cust."Customer Price Group" = '' then
                Cust."Customer Price Group" := CustTemplate."Customer Price Group";
            if Cust."Customer Disc. Group" = '' then
                Cust."Customer Disc. Group" := CustTemplate."Customer Disc. Group";
            if Cust."Allow Line Disc." = false then
                Cust."Allow Line Disc." := CustTemplate."Allow Line Disc.";
            if Cust."Invoice Disc. Code" = '' then
                Cust."Invoice Disc. Code" := CustTemplate."Invoice Disc. Code";
            if Cust."Payment Terms Code" = '' then
                Cust."Payment Terms Code" := CustTemplate."Payment Terms Code";
            if Cust."Payment Method Code" = '' then
                Cust."Payment Method Code" := CustTemplate."Payment Method Code";
            if Cust."Shipment Method Code" = '' then
                Cust."Shipment Method Code" := CustTemplate."Shipment Method Code";
            if Cust."Tax Area Code" = '' then begin
                //Cust."Tax Area Code" := CustTemplate."PYA Tax Area Code";
                //Cust."Tax Liable" := CustTemplate."PYA Tax Liable";
                //PYAS-242
                if cont2.Get(Contact."No.") then begin
                    cont2."PYA Tax Area Code" := Cust."Tax Area Code";
                    cont2."PYA Tax Liable" := Cust."Tax Liable";
                    cont2.Modify();
                end;
                //-//
            end;
            if Cust."Credit Limit (LCY)" = 0 then
                Cust."Credit Limit (LCY)" := CustTemplate."Credit Limit (LCY)";

            Cust.UpdateReferencedIds();
            Cust.Modify();

            DefaultDim.SetRange("Table ID", Database::"Customer Templ.");
            DefaultDim.SetRange("No.", CustTemplate.Code);
            if DefaultDim.Find('-') then
                repeat
                    Clear(DefaultDim2);
                    DefaultDim2.Init();
                    DefaultDim2.Validate("Table ID", Database::Customer);
                    DefaultDim2."No." := Cust."No.";
                    DefaultDim2.Validate("Dimension Code", DefaultDim."Dimension Code");
                    DefaultDim2.Validate("Dimension Value Code", DefaultDim."Dimension Value Code");
                    DefaultDim2."Value Posting" := DefaultDim."Value Posting";
                    DefaultDim2.Insert(true);
                until DefaultDim.Next() = 0;
        end;

        ContBank.Reset();
        ContBank.SetRange("Contact No.", Contact."No.");
        if ContBank.FindFirst() then
            repeat
                CustBank.Init();
                CustBank.TransferFields(ContBank);
                CustBank."Country/Region Code" := ContBank."Country Code";

                if CustBank.Get(CustBank."Customer No.", CustBank.Code)
                  then
                    CustBank.Modify()
                else
                    CustBank.Insert();
            until ContBank.Next() = 0;

        Cust."Primary Contact No." := Contact."No.";
        Cust.County := Contact.County;
        Cust.Modify();

        CampaignMgt.ConverttoCustomer(Contact, Cust);
        if OfficeMgt.IsAvailable() then
            Page.Run(Page::"Customer Card", Cust)
        else
            if not HideValidationDialog then
                Message(RelatedRecordIsCreatedMsg, Cust.TableCaption);
    end;

    //Contact Alt. Address
    [EventSubscriber(ObjectType::Table, Database::"Contact Alt. Address", 'OnAfterModifyEvent', '', false, false)]
    local procedure ContactAltAddress_OnAfterModifyEvent(var Rec: Record "Contact Alt. Address"; var xRec: Record "Contact Alt. Address"; RunTrigger: Boolean)
    var
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        Contact: Record Contact;

    begin
        if not RunTrigger then//TG210208
            exit;
        //JM180228++
        if Rec."Contact No." <> '' then begin//DV180216
            Contact.Get(Rec."Contact No.");
            UpdateCustVendBank.Run(Contact);
        end;
        //JM180222--
    end;

    //Contract
    [EventSubscriber(ObjectType::Table, Database::"S4LA Contract", 'ValidateSupplierSalespersonNo', '', false, false)]
    procedure Contract_ValidateSupplierSalespersonNo(var Rec: Record "S4LA Contract"; newVale: Code[20]; var isHandled: Boolean)
    begin
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Contract", 'OnBeforeFindCreateUpdateCustomerFindMatch', '', false, false)]
    local procedure Contract_OnBeforeFindCreateUpdateCustomerFindMatch(var Rec: Record "S4LA Contract"; var PrimeAppl: Record "S4LA Applicant"; ContactNo: Code[20]; var IsHandled: Boolean)
    var
        ApplMgt: Codeunit "S4LA Applicant Mgt";
        ContactRec: Record Contact;
    begin
        if not ApplMgt.FindMatch(PrimeAppl, ContactNo) then // returns ContactNo, if matching contact found
            ContactNo := ApplMgt.CreateContactFromApplicant(PrimeAppl);
        //BA210604 - Fix issue of customer No. not being populated after creating customer

        if ContactNo <> '' then begin
            //PYAS-297
            ContactRec.Get(ContactNo);
            ContactRec."PYA Is Customer" := true;
            ContactRec.Modify();
            //--//
            Rec.Validate("Customer No.", ContactNo);
        end;

        Rec.Modify();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Contract", 'OnAfterGuarantorSetFilters', '', false, false)]
    local procedure Contract_OnAfterGuarantorSetFilters(Rec: Record "S4LA Contract"; var Guarantor: Record "S4LA Applicant")
    var
    begin
        Guarantor.SetRange("Individual/Business"); //DV181116
    end;


    ///   local procedure Contract_OnBeforeInsertSupplierContact(var Rec: Record "S4LA Contract"; var Con[EventSubscriber(ObjectType::Table, Database::"S4LA Contract", 'OnBeforeInsertSupplierContact', '', false, false)]tact: Record Contact)
    //    begin
    //        Contact."Phone No." := Rec."Supplier Phone No."; //PYA
    //        Contact."S4LA Contact Person" := Rec."Supplier Salesperson Name"; //PYA
    //    end;

    //    [EventSubscriber(ObjectType::Table, Database::"S4LA Contract", 'OnMakeContractFromQuoteSchedule_BeforeCommit', '', false, false)]
    //    local procedure Contract_OnMakeContractFromQuoteSchedule_BeforeCommit(var rec: Record "S4LA Contract"; var recContract: Record "S4LA Contract")
    //    begin
    //        rec.S4LNAInsertUpdateContrInsurPolicy(recContract); //TG190420
    //    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Contract", 'OnfnAssetDesriptions_BeforeExit', '', false, false)]
    local procedure Contract_OnfnAssetDesriptions_BeforeExit(var Rec: Record "S4LA Contract"; var Asset: Record "S4LA Asset"; var Txt: Text)
    begin
        Txt := '';
        /*TG190110*/ // Only have description of first asset line
        if Asset.FindFirst() then
            if Asset."Asset Description" <> '0' then
                Txt := CopyStr(Asset."Asset Description", 1, MaxStrLen(Txt));
        /*---*/
    end;

    //Schedule
    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnValidateProgramCode_BeforeResidualPct', '', false, false)]
    local procedure Schedule_OnValidateProgramCode_BeforeResidualPct(var Rec: Record "S4LA Schedule"; Prgrm: Record "S4LA Program"; var isHandled: Boolean)
    begin
        if ((Rec."Residual Value %" = 0) and (Rec."Residual Value" = 0)) and (Prgrm."Residual Value %" <> 0) then //DV180411
            Rec.Validate("Residual Value %", Prgrm."Residual Value %");
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnValidateProgramCode_BeforeStatusCheck', '', false, false)]
    local procedure OnValidateProgramCode_BeforeStatusCheck(var Rec: Record "S4LA Schedule"; var isHandled: Boolean)
    var
        Contr: Record "S4LA Contract";
    begin
        isHandled := false;
        if not Contr.Get(Rec."Contract No.") then //KS150309
            Contr.Init();
        if Contr."Migration Flag" <> '' then//DV171220
            isHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnLookupProgramCode_BeforeStatusCodeCheck', '', false, false)]
    local procedure Schedule_OnLookupProgramCode_BeforeStatusCodeCheck(var Rec: Record "S4LA Schedule"; var isHandled: Boolean)
    begin
        isHandled := true; /*DV180405*/
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnValidateDownpaymentPct_BeforeCalcDownpaymentAmount', '', false, false)]
    local procedure Schedule_OnValidateDownpaymentPct_BeforeCalcDownpaymentAmount(var Rec: Record "S4LA Schedule"; var isHandled: Boolean)
    begin
        isHandled := true; // >> SK170613
        Rec."Downpayment %" := 0; //EN201022 Downpayment % is not used in NA. Set it to zero
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnValidateDownpaymentAmount_BeforeCalcDownpaymentPct', '', false, false)]
    local procedure OnValidateDownpaymentAmount_BeforeCalcDownpaymentPct(var Rec: Record "S4LA Schedule"; var isHandled: Boolean)
    begin
        isHandled := true; // >> SK170613
    end;

    /*    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnValidateInterestPct_BeforeRecalc', '', false, false)]
        local procedure Schedule_OnValidateInterestPct_BeforeRecalc(var Rec: Record "S4LA Schedule"; var xRec: Record "S4LA Schedule"; var isHandled: Boolean)
        var
            LeasingSetup: Record "S4LA Leasing Setup";
            ScheduleInDatabase: Record "S4LA Schedule"; //EN210325
        begin
             // requested behavior that changing parameters (term, downpayment, etc.) overrides manual installment amount
            if LeasingSetup.Get() then
                if LeasingSetup."S4LNA Clear Manual Amount" and (Rec."Manual Installment Amount" <> 0) then
                    Rec.Validate("Manual Installment Amount", 0);

            Rec.CheckInterestRate();
            //EN210325 >> must call to populate interest components
            if ScheduleInDatabase.Get(Rec."Contract No.", Rec."Schedule No.", Rec."Version No.") then //skip on Quote conversion
                ; // UpdateInterestRate(); //BA210415
                  //EN210325 <<
            Rec.Recalculate := true;
            isHandled := true;
        end; 

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnInitOnInsert_BeforeExit', '', false, false)]
        local procedure Schedule_OnInitOnInsert_BeforeExit(var Rec: Record "S4LA Schedule"; var ScheduleContract: Record "S4LA Contract")
        var
            finprod: Record "S4LA Financial Product";
        begin
            if ScheduleContract.Status <> ScheduleContract.Status::Quote then
                // was creating new application with status of quote
                if ScheduleContract."Quote No." = '' then
                    if ScheduleContract.Status in [ScheduleContract.Status::Application, ScheduleContract.Status::Contract] then
                        Rec.Status := ScheduleContract.Status;
            // EN201022 Can't update Interest Components if Schedule is not inserted physically
            IF ("Interest %" = 0) OR ("Interest Rate" = 0) THEN//DV171219
                UpdateInterestRate;//DV171219
     /*
            //DV180201
            // if "S#Mileage Limit (km/year)" = 0 then //TG210215
            //     "S#Mileage Limit (km/year)" := LeasingSetup2."S4LNA Mileage Limit (km/year)";
            // if "S#Price per km over limit" = 0 then //TG210215
            //     "S#Price per km over limit" := LeasingSetup2."S4LNA Price per km over limit";


            if finprod.Get(ScheduleContract."Financial Product") then
                Rec."S4LNA Serv. and Insurance Only" := finprod."S4LNA Services/Insurance Only";
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnRecalculateAmounts_BeforeCalcDownpayment', '', false, false)]
        local procedure Schedule_OnRecalculateAmounts_BeforeCalcDownpayment(var Rec: Record "S4LA Schedule"; var isHandled: Boolean)
        begin
            isHandled := true; 
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnGetNextPaymentAmountLCY_AfterSetFilters', '', false, false)]
        local procedure Schedule_OnGetNextPaymentAmountLCY_AfterSetFilters(var Rec: Record "S4LA Schedule"; var ScheduleLine: Record "S4LA Schedule Line")
        begin
            ScheduleLine.SetFilter("Entry Type", '%1|%2', ScheduleLine."Entry Type"::Installment, ScheduleLine."Entry Type"::Inertia);//DV190304
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnGetNextPaymentAmountExclVAT_AfterSetFilters', '', false, false)]
        local procedure Schedule_OnGetNextPaymentAmountExclVAT_AfterSetFilters(var Rec: Record "S4LA Schedule"; var ScheduleLine: Record "S4LA Schedule Line")
        begin
            ScheduleLine.SetFilter("Entry Type", '%1|%2', ScheduleLine."Entry Type"::Installment, ScheduleLine."Entry Type"::Inertia);//DV190304
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnGetNextPaymentAmount_AfterSetFilters', '', false, false)]
        local procedure Schedule_OnGetNextPaymentAmount_AfterSetFilters(var Rec: Record "S4LA Schedule"; var ScheduleLine: Record "S4LA Schedule Line")
        begin
            ScheduleLine.SetFilter("Entry Type", '%1|%2', ScheduleLine."Entry Type"::Installment, ScheduleLine."Entry Type"::Inertia);//DV190304
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnfnStatusCodeToDate_AfterSetFilters', '', false, false)]
        local procedure Schedule_OnfnStatusCodeToDate_AfterSetFilters(var Rec: Record "S4LA Schedule"; ToDate: Date; var StatusHistory: Record "S4LA Status History")
        begin
            StatusHistory.SetCurrentKey("Effective Date");//DV180416
            StatusHistory.SetRange("Effective Date", 0D, ToDate);
            //DV190430
            StatusHistory.SetRange("Key Field 3 Value");
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnTotalUpfrontFees_BeforeExit', '', false, false)]
        local procedure Schedule_OnTotalUpfrontFees_BeforeExit(var Rec: Record "S4LA Schedule"; var Amt: Decimal)
        var
            SchedLine: Record "S4LA Schedule Line";
            FirstInv: Decimal;
        begin
            FirstInv := 0;
            //PYAS-251
            if Rec."S4LNA Incl.First P.To FirstInv" then begin
                Rec.GetTheFirstInstallment(SchedLine);
                FirstInv := SchedLine.fnInstallment();
            end;

            Amt += Rec."S4LNA Refund. Security Deposit"//DV170313
               + Rec."Pro-Rata Amount" //JM170628
               + Rec.S4LNATotalUpfrontTax //JM170628() //JM170628
               + Rec."Downpayment Amount"//DV170801
               + FirstInv; //PYAS-251
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnTotalCapitalAmount_BeforeExit', '', false, false)]
        local procedure Schedule_OnTotalCapitalAmount_BeforeExit(var Rec: Record "S4LA Schedule"; var Amt: Decimal)
        begin
            Amt += Rec."S4LNA PAD"//DV170518
         - Rec."S4LNA Equity" //DV171219
         + Rec."S4LNA Shortfall";//DV171219
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnTotalCapitalAmountExVAT_BeforeExit', '', false, false)]
        local procedure Schedule_OnTotalCapitalAmountExVAT_BeforeExit(var Rec: Record "S4LA Schedule"; var Amt: Decimal)
        begin
            Amt += Rec."S4LNA PAD"//DV170518
     - Rec."S4LNA Equity" //DV171219
     + Rec."S4LNA Shortfall";//DV171219
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnAssetAmountFinanced_BeforeExit', '', false, false)]
        local procedure Schedule_OnAssetAmountFinanced_BeforeExit(var Rec: Record "S4LA Schedule"; var Amt: Decimal)
        begin
            Amt += Rec."S4LNA PAD"//DV170518
    - Rec."S4LNA Equity" //DV171219
    + Rec."S4LNA Shortfall";//DV171219
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnUpdateCapitalAmount_BeforeUpdateInterest', '', false, false)]
        local procedure Schedule_OnUpdateCapitalAmount_BeforeUpdateInterest(var Rec: Record "S4LA Schedule"; var xRec: Record "S4LA Schedule"; CurrFieldNo: Integer; var isHandled: Boolean)
        var
            Contr: Record "S4LA Contract";
            LeasingSetup: Record "S4LA Leasing Setup";
            ScheduleInDatabase: Record "S4LA Schedule"; //EN210325
        begin
            if not Contr.Get(Rec."Contract No.") then  //EN151028 "get" is needed for quote creation
                exit;
             // requested behavior that changing parameters (term, downpayment, etc.) overrides manual installment amount
            if LeasingSetup.Get() then
                if LeasingSetup."S4LNA Clear Manual Amount" and (Rec."Manual Installment Amount" <> 0) then
                    Rec.Validate("Manual Installment Amount", 0);

            if ScheduleInDatabase.Get(Rec."Contract No.", Rec."Schedule No.", Rec."Version No.") then //EN210325do not modify if not inserted yet (e.g on quote conversion)
                Rec.Modify(); //KS160309

            Rec.UpdateVariableInterest(); //EN170407
            if (CurrFieldNo = Rec.FieldNo("Interest %")) then //DV180305
                Rec.UpdateInterestRate(); //KS160308

            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnGetNextInstallment_AfterSetFilters', '', false, false)]
        local procedure Schedule_OnGetNextInstallment_AfterSetFilters(var Rec: Record "S4LA Schedule"; var ScheduleLine: Record "S4LA Schedule Line")
        begin
            ScheduleLine.SetFilter("Entry Type", '%1|%2', ScheduleLine."Entry Type"::Installment, ScheduleLine."Entry Type"::Inertia);//DV190219
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnCalcProRataAmt_BeforeExit', '', false, false)]
        local procedure Schedule_OnCalcProRataAmt_BeforeExit(var Rec: Record "S4LA Schedule")
        var
            FinProd: Record "S4LA Financial Product";
            ProRataDaysDiff: Integer;
            Days: Integer;
        begin
            //BA210622
            Days := 0;
            case
                Rec.Frequency of
                'MONTHLY':
                    Days := 30;
                'WEEKLY':
                    Days := 7;
                'BI-WEEKLY':
                    Days := 14;
            end;

            Rec."Pro-Rata Amount" := 0;
            FinProd.Get(Rec."Financial Product");
            if FinProd."Pro-rata Allowed" then
                //IF "Activation Date" < "Starting Date" THEN BEGIN
                if (Rec."Activation Date" <> 0D) and (Rec."Activation Date" < Rec."Starting Date") then begin //DV170719
                                                                                                              //ProRataDaysDiff := "Starting Date" - "Activation Date" - 1;
                    ProRataDaysDiff := Rec."Starting Date" - Rec."Activation Date";//DV171130
                                                                                   //Days := 30;//DV190207
                    if FinProd."Min Pro-rata Days" <= ProRataDaysDiff then
                        Rec."Pro-Rata Amount" := Round(Round(Rec.GetNextPaymentAmountExclVAT() / Days, 0.01) * ProRataDaysDiff, 0.01);//DV171201
                                                                                                                                      //"Pro-Rata Amount" := ROUND(GetNextPaymentAmount / 30 * ProRataDaysDiff,0.01);
                end;
        end;

        [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnBeforeUpdateNumberOfPaymentPeriods', '', false, false)]
        local procedure Sched_OnBeforeUpdNoOfPmtPeriods(var Rec: Record "S4LA Schedule"; var isHandled: Boolean)
        var
            LeasingSetup: Record "S4LA Leasing Setup";
            TermRecord: Record "S4LA Term";
        begin
            //TG210325//
            LeasingSetup.Get();
            if Rec.Term <> '' then begin
                TermRecord.Get(Rec.Term);
                if TermRecord."Allow Custom Term" then begin
                    Rec.Validate("Number Of Payment Periods");
                    isHandled := true;
                    exit;
                end;
                if Rec."Installments Per Year" <> 0 then begin
                    if TermRecord."Number Of Months" <> 0 then
                        case LeasingSetup."S4LNA Payment Periods Rounding" of
                            LeasingSetup."S4LNA Payment Periods Rounding"::"Round Up":
                                Rec.Validate("Number Of Payment Periods", Round(TermRecord."Number Of Months" / 12 * Rec."Installments Per Year", 1, '>'));
                            LeasingSetup."S4LNA Payment Periods Rounding"::"Round Nearest":
                                Rec.Validate("Number Of Payment Periods", Round(TermRecord."Number Of Months" / 12 * Rec."Installments Per Year", 1));
                            LeasingSetup."S4LNA Payment Periods Rounding"::"Round Down":
                                Rec.Validate("Number Of Payment Periods", Round(TermRecord."Number Of Months" / 12 * Rec."Installments Per Year", 1, '<'));
                        end
                    else
                        Rec.Validate("Number Of Payment Periods", TermRecord."Number Of Weeks" / 52 * Rec."Installments Per Year");
                end else
                    Rec.Validate("Number Of Payment Periods", 0);
            end else
                Rec.Validate("Number Of Payment Periods", 0);
            isHandled := true;
        end;

        //Fixed Asset
        [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'S4LAFixedAsset_OnUpdateDeprBook', '', false, false)]
        local procedure FixedAsset_OnUpdateDeprBook(var FixedAsset: Record "Fixed Asset"; var isHandled: Boolean)
        var
            FAbook: Record "FA Depreciation Book";
            LeasingPostingSetup: Record "S4LA Leasing Posting Setup";
            LeaseSetup: Record "S4LA Leasing Setup";
            Contr: Record "S4LA Contract";
            FASetup: Record "FA Setup";
            user: Record User;
        begin
            isHandled := true;
            /*
            //KS031015,KS060908,KS141215
            // >> SK200214
            // FASetup.GET;
            // FASetup.TESTFIELD("Default Depr. Book");
            IF NOT FinProduct.GET("S4LA Fin. Product Code") THEN
                FinProduct.INIT;
            FinProduct.TESTFIELD("FA Depreciation Book Code");

            // SK200214 IF NOT FAbook.GET("No.",FASetup."Default Depr. Book") THEN BEGIN
            LeaseSetup.GET;//DV170926
            IF NOT FAbook.GET("No.", FinProduct."FA Depreciation Book Code") THEN BEGIN  // SK200214
                FAbook.INIT;
                FAbook."FA No." := "No.";
                // SK200214 FAbook."Depreciation Book Code":=FASetup."Default Depr. Book";
                FAbook."Depreciation Book Code" := FinProduct."FA Depreciation Book Code";  // SK200214
                FAbook.Description := COPYSTR(Description, 1, MAXSTRLEN(Description));  //KS141215
                FAbook.VALIDATE("FA Posting Group", LeaseSetup."S4LNA FA Post.Gr. for PO Lease");//DV170926, 1111
                FAbook.INSERT;
            END;

            //PYAS-179 - skip insert for Limited users
            user.Reset();
            user.SetRange("User Name", UserId);
            user.SetRange("License Type", user."License Type"::"Full User");
            if user.FindFirst() then begin
                //BA210622 -- PYA Code
                FASetup.Get();
                FASetup.TestField("Default Depr. Book");
                LeaseSetup.Get();//DV170926
                if not FAbook.Get(FixedAsset."No.", FASetup."Default Depr. Book") then begin
                    FAbook.Init();
                    FAbook."FA No." := FixedAsset."No.";
                    FAbook."Depreciation Book Code" := FASetup."Default Depr. Book";
                    FAbook.Description := CopyStr(FixedAsset.Description, 1, MaxStrLen(FixedAsset.Description));  //KS141215
                    FAbook.Validate("FA Posting Group", LeaseSetup."S4LNA FA Post.Gr. for PO Lease");//DV170926, 1111
                    FAbook.Insert();
                end;

                FAbook.CalcFields("Acquisition Cost");
                if FAbook."Acquisition Cost" = 0 then begin //Do not change if has balance

                    //KS190614
                    if not Contr.Get(FixedAsset."PYA Contract No") then//DV171111
                        Clear(Contr);
                    LeasingPostingSetup.SetSilentMode(true);
                    LeasingPostingSetup.GetSetupRec(LeasingPostingSetup, FixedAsset."PYA Contract No");
                    if Contr.Status = Contr.Status::Contract then //DV171111
                        FAbook."FA Posting Group" := LeasingPostingSetup."Op. Lease Inv. (Post. Gr.)" //should be blank for non OL fin products.
                    else
                        FAbook.Validate("FA Posting Group", LeaseSetup."S4LNA FA Post.Gr. for PO Lease");//DV171111

                    FAbook.Modify();
                end;
            end; //--//
        end;

        [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'S4LAFixedAsset_OnUpdateDeprTerm', '', false, false)]
        local procedure FixedAsset_OnUpdateDeprTerm(var FixedAsset: Record "Fixed Asset"; var isHandled: Boolean)
        var
            FAbook: Record "FA Depreciation Book";
            FinProduct: Record "S4LA Financial Product";
            Contr: Record "S4LA Contract";
            Sched: Record "S4LA Schedule";
            FASetup: Record "FA Setup";
        begin

            //KS060911
            //This function updates asset lifetime depr fields, to be in paralell with Contract.
            FASetup.Get();
            if FASetup."Default Depr. Book" = '' then
                exit;

            if not FAbook.Get(FixedAsset."No.", FASetup."Default Depr. Book") then
                exit;

            //-- in case asset removed from contrat (e.g. asset variation) - then stop depreciation
            if FixedAsset."PYA Contract No" = '' then begin
                FAbook."No. of Depreciation Months" := 0;  //can not validate, because there is no starting date
                FAbook."No. of Depreciation Years" := 0;
                FAbook."Straight-Line %" := 0;
                FAbook.Validate("Depreciation Starting Date", 0D);
                FAbook.Modify();
                exit;
            end;

            //--- Cleanup depr. fields if asset under retail Contract other than OL
            //!! IF FinProduct.GET("Fin. Product Code") THEN BEGIN
            //>>EN150224
            //!! Contr.GET("Contract No.");
            //>>EN181205
            if not Contr.Get(FixedAsset."PYA Contract No") then
                exit;
            //Contr.GET("Contract No.");   // SK180607
            //<<EN181205
            Contr.GetNewestSchedule(Sched);
            //<<EN150224
            //>>NK150113 EN150224 - code transfered to a correct place
            //--- Usage Based depr. OL-RMAX
            //>>EN150224 FinProduct.GET("Fin. Product Code");
            if FinProduct."Fin. Product Type" <> FinProduct."Fin. Product Type"::"Operating Lease"
              then begin
                FAbook."No. of Depreciation Months" := 0;  //can not validate, because there is no starting date
                FAbook."No. of Depreciation Years" := 0;
                FAbook."Straight-Line %" := 0;
                FAbook.Validate("Depreciation Starting Date", 0D);
                FAbook.Modify();
                exit;
            end;
            //!! END; //>>EN150224

            //-- don't change depr parameters if depr already started
            //FAentries.RESET;
            //FAentries.SETCURRENTKEY("FA No.","FA Posting Type");
            //FAentries.SETRANGE("FA No.","No.");
            //FAentries.SETRANGE("FA Posting Type",FAentries."FA Posting Type"::Depreciation);
            //IF FAentries.FINDFIRST THEN
            //  EXIT;

            //!! Contr.GET("Contract No.");
            Contr.GetNewestSchedule(Sched);

            //KS141215
            FAbook.Validate("Depreciation Method", FAbook."Depreciation Method"::"Straight-Line");
            if Sched."Activation Date" <> 0D then begin
                FAbook.Validate("Depreciation Starting Date", Sched."Activation Date");
                FAbook.Validate("Depreciation Ending Date", Sched."Ending Date");
            end else begin
                FAbook.Validate("Depreciation Starting Date", Sched."Starting Date");
                FAbook.Validate("Depreciation Ending Date", Sched."Ending Date");
            end;

            FAbook.Modify();
        end;

        [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'S4LAFixedAsset_OnShowBookValueAfterDisposal', '', false, false)]
        local procedure FixedAsset_OnShowBookValueAfterDisposal(var FixedAsset: Record "Fixed Asset"; var isHandled: Boolean)
        var
            TempFALedgEntry: Record "FA Ledger Entry" temporary;
            FALedgEntry: Record "FA Ledger Entry";
        begin
            isHandled := true;

            FixedAsset.CalcFields("S4LA Disposal Date (Asset)");
            if (FixedAsset."S4LA Disposal Date (Asset)" > 0D) then begin
                Clear(TempFALedgEntry);
                TempFALedgEntry.DeleteAll();
                TempFALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                FALedgEntry.SetRange("FA No.", FixedAsset."No.");
                if FALedgEntry.FindSet() then
                    repeat
                        if ((FALedgEntry."FA Posting Category" = FALedgEntry."FA Posting Category"::Disposal) and
                           (FALedgEntry."FA Posting Type" <> FALedgEntry."FA Posting Type"::"Book Value on Disposal") and
                           (FALedgEntry."FA Posting Type" <> FALedgEntry."FA Posting Type"::"Salvage Value")) or
                           (FALedgEntry."Part of Book Value")
                        then begin
                            TempFALedgEntry := FALedgEntry;
                            TempFALedgEntry.Insert();
                        end;
                    until FALedgEntry.Next() = 0;
                TempFALedgEntry.SetRange("FA No.", TempFALedgEntry."FA No.");
                Page.Run(0, TempFALedgEntry);
            end else begin
                FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
                FALedgEntry.SetRange("FA No.", FixedAsset."No.");
                FALedgEntry.SetRange("Part of Book Value", true);
                Page.Run(0, FALedgEntry);
            end;
        end;

        [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'S4LAFixedAsset_OnCalcBookValue', '', false, false)]
        local procedure FixedAsset_OnCalcBookValue(var FixedAsset: Record "Fixed Asset"; var isHandled: Boolean)
        begin
            isHandled := true;
            FixedAsset.CalcFields("S4LA Disposal Date (Asset)");
            if FixedAsset."S4LA Disposal Date (Asset)" > 0D then
                FixedAsset."S4LA Book Value" := 0
            else
                FixedAsset.CalcFields("S4LA Book Value");
        end;

        [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'S4LAFixedAsset_OnShowAcquisitionCostAfterDisposal', '', false, false)]
        local procedure FixedAsset_OnShowAcquisitionCostAfterDisposal(var FixedAsset: Record "Fixed Asset"; var isHandled: Boolean)
        var
            TempFALedgEntry: Record "FA Ledger Entry" temporary;
            FALedgEntry: Record "FA Ledger Entry";
        begin
            isHandled := true;
            FixedAsset.CalcFields("S4LA Disposal Date (Asset)");
            if (FixedAsset."S4LA Disposal Date (Asset)" > 0D) then begin
                Clear(TempFALedgEntry);
                TempFALedgEntry.DeleteAll();
                TempFALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                FALedgEntry.SetRange("FA No.", FixedAsset."No.");
                if FALedgEntry.FindSet() then
                    repeat
                        if (FALedgEntry."FA Posting Type" = FALedgEntry."FA Posting Type"::"Acquisition Cost") then begin
                            TempFALedgEntry := FALedgEntry;
                            TempFALedgEntry.Insert();
                        end;
                    until FALedgEntry.Next() = 0;
                TempFALedgEntry.SetRange("FA No.", TempFALedgEntry."FA No.");
                Page.Run(0, TempFALedgEntry);
            end else begin
                FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
                FALedgEntry.SetRange("FA No.", FixedAsset."No.");
                FALedgEntry.SetRange("Part of Book Value", true);
                FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Acquisition Cost");
                Page.Run(0, FALedgEntry);
            end;
        end;

        /* SOLV-1422 --- not used enywhere
        [EventSubscriber(ObjectType::Table, Database::"Fixed Asset", 'FixedAsset_OnCalcAcquisitionCost', '', false, false)]
        local procedure FixedAsset_OnCalcAcquisitionCost(var FixedAsset: Record "Fixed Asset"; var isHandled: Boolean)
        begin
            isHandled := true;
            with FixedAsset do begin
                CALCFIELDS("S4LA Disposal Date (Asset)");
                IF "S4LA Disposal Date (Asset)" > 0D THEN
                    "S4LA Acquisition Cost" := 0
                ELSE
                    CALCFIELDS("S4LA Acquisition Cost");
            end;
        end;
        */

    //Schedule Line
    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule Line", 'OnfnInstallment_BeforeExit', '', false, false)]
    local procedure OnfnInstallment_BeforeExit(var Rec: Record "S4LA Schedule Line"; var Amt: Decimal)
    var
        cdCommon: Codeunit "S4LA Common Functions";
    begin
        Amt := cdCommon.RoundAmount(Amt, Rec."Currency Code");//DV180226
    end;

    //Asset
    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnAssetNo_BeforeLookup', '', false, false)]
    local procedure Asset_OnAssetNo_BeforeLookup(var Rec: Record "S4LA Asset"; var isHandled: Boolean)

    var
        LeasingContract: Record "S4LA Contract";
        FA: Record "Fixed Asset";
        LeasingSetup: Record "S4LA Leasing Setup";
    begin
        if Rec."Asset No." <> '' then begin
            if FA.Get(Rec."Asset No.") then
                Page.Run(Page::"S4LA Leasing Fixed Asset Card", FA)
        end else
  //JM170719++
  begin
            LeasingSetup.Get();
            if Rec."Acquisition Source" = Rec."Acquisition Source"::Stock then
                FA.SetRange("PYA Asset Status Code", LeasingSetup."FA Status Filter - Stock")
            else
                FA.SetRange("PYA Asset Status Code");
            //JM170419--
            if Page.RunModal(Page::"S4LA Fixed Assets", FA) = Action::LookupOK then
                if LeasingContract.Status in [LeasingContract.Status::Quote, LeasingContract.Status::Application] then begin
                    Rec.Validate("Asset No.", FA."No.");
                    FA.Get(FA."No."); // PYAS-246: to resolve error due to FA being modified between initial and JIT load
                    //Rec."Asset Type" := FA."PYA Asset Type";
                    //Rec."Asset Group" := FA."PYA Asset Group";
                    //Rec."Asset Category" := FA."PYA Asset Category";
                    Rec."Asset Brand" := FA."PYA Asset Brand";
                    Rec.Model := FA."PYA Asset Model";
                    Rec."Model Year" := FA."PYA Model Year";
                    Rec."Asset Description" := FA.Description;
                    Rec.UpdateAssetsDescriptionOnContract(false);
                end;
        end; //JM170719
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnOLAssetReturnedDate_BeforeValidate', '', false, false)]
    local procedure Asset_OnOLAssetReturnedDate_BeforeValidate(var Rec: Record "S4LA Asset"; var isHandled: Boolean)

    var
        FixedAsset: Record "Fixed Asset";
        FABook: Record "FA Depreciation Book";
        Contr: Record "S4LA Contract";
        Sched: Record "S4LA Schedule";
        LeasingSetup: Record "S4LA Leasing Setup";
        LeasePostingSetup: Record "S4LA Leasing Posting Setup";
        AssetStatus: Record "S4LA Status";
    begin

        //>>PA150314
        //IF (("OL Asset Returned Date" <> 0D) AND ("OL Asset Returned Date" < WORKDATE))THEN
        Contr.Get(Rec."Contract No.");//DV180216
        Contr.GetValidSchedule(Sched);//DV180216
        if ((Rec."OL Asset Returned Date" <> 0D) and (Rec."OL Asset Returned Date" < Sched."Starting Date")) then//DV180216
            Rec.FieldError("OL Asset Returned Date");
        //<<PA150314
        LeasingSetup.Get();//DV170825
                           //>>PB150129 If Asset Returned then should not depriciate
        if Rec."OL Asset Returned Date" <> 0D then begin
            LeasePostingSetup.S4LNAGetTermSetupRec(LeasePostingSetup, Rec."Contract No.");//DV170825
            Rec.Validate("OL Asset Returned", true);
            FixedAsset.Get(Rec."Asset No.");
            //>>PA150529
            FABook.SetRange("FA No.", Rec."Asset No.");
            if FABook.FindFirst() then begin
                //>>PA150617 sys Aid 18445
                /*DV180405*/
                /*FA2.SETRANGE("No.","Asset No.");
                FA2.FINDFIRST;
                CalcDepriciation.SETTABLEVIEW(FA2);
                LSetup.GET;
                CalcDepriciation.InitializeRequest(LSetup."Default Depriciation Book Code","OL Asset Returned Date",FALSE,0,WORKDATE,"Contract No.",Text220,TRUE);
                CalcDepriciation.USEREQUESTPAGE(FALSE);
                CalcDepriciation.RUNMODAL;
                GenJnl.SETRANGE("Contract No.","Contract No.");
                GenJnl.SETRANGE(GenJnl."FA Posting Type",GenJnl."FA Posting Type"::Depreciation);
                IF GenJnl.FINDFIRST THEN
                   MESSAGE(Text250);
                //CalcDepriciation.InitializeRequest(DeprBookCodeFrom,DeprUntilDateFrom,UseForceNoOfDaysFrom,DaysInPeriodFrom,PostingDateFrom,DocumentNoFrom,PostingDescriptionFrom,BalAccountFrom)
                */
                FABook.Validate("Depreciation Ending Date", 0D);
                //<<PA150617 sys Aid 18445
                FABook.Modify();
                //FixedAsset.VALIDATE(Inactive,TRUE);
            end;
            /*DV170825*/
            AssetStatus.Reset();
            AssetStatus.SetRange("Target Table ID", Database::"Fixed Asset");
            //AssetStatus.SetRange("Trigger Option No.", FixedAsset."S4LA Asset Status Trigger"::"S4LNA Stock".AsInteger());
            AssetStatus.FindFirst();
            FixedAsset.Get(Rec."Asset No.");//DV180124
            FixedAsset."PYA Asset Status Code" := AssetStatus.Code;
            //FixedAsset."PYA Asset Status Trigger" := Enum::"S4LA Asset Status Trigger".FromInteger(AssetStatus."Trigger Option No.");
            /*BA211104 - OnValidate trigger is causing an error during returning an asset
               FixedAsset.VALIDATE("FA Posting Group", LeasePostingSetup."Op. Lease Inv. (Post. Gr.)");
              */
            //BA211104 -to avoid error when using Validate
            //BA211105 - field changed to Op. Lease Inventory (BS) – Tm
            //FixedAsset."FA Posting Group" := LeasePostingSetup."S4LNA Op. Lease Invent.(BS)–Tm";

            FixedAsset."NA Return Date" := Rec."OL Asset Returned Date";//DV180124
                                                                        /*---*/
            FixedAsset.Modify();
            //<<PA150529
        end else begin
            LeasePostingSetup.GetSetupRec(LeasePostingSetup, Rec."Contract No.");//DV170825
            Rec."OL Asset Returned" := false;
            FixedAsset.Get(Rec."Asset No.");
            //>>PA150530 -
            Contr.Get(Rec."Contract No.");
            Contr.GetValidSchedule(Sched);
            FABook.SetRange("FA No.", Rec."Asset No.");
            if FABook.FindFirst() then begin
                FABook.Validate("Depreciation Ending Date", Sched."Ending Date");
                FABook."FA Posting Group" := LeasePostingSetup."Op. Lease Inv. (Post. Gr.)";
                FABook.Modify();
                //FixedAsset.VALIDATE(Inactive,TRUE);
            end;
            //<<PA150530

            /*BA211104 - OnValidate trigger is causing an error during returning an asset
              FixedAsset.VALIDATE("FA Posting Group", LeasePostingSetup."Op. Lease Inv. (Post. Gr.)");//DV170825
           */
            //BA211104 -to avoid error when using Validate
            FixedAsset."FA Posting Group" := LeasePostingSetup."Op. Lease Inv. (Post. Gr.)";

            FixedAsset.Validate("PYA Asset Status Code", LeasingSetup."FA Status - On Active Contract");
            FixedAsset.Validate(Inactive, false);
            FixedAsset.Modify();
        end;
        //<<PB150129
        Rec.UpdateMaintenanceCostonContract();//>>PB150211
        isHandled := true;
    end;

    /*    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnInitOnInsert_BeforeExit', '', false, false)]
        local procedure Asset_OnInitOnInsert_BeforeExit(var Rec: Record "S4LA Asset"; var Contr: Record "S4LA Contract"; OldRec: Record "S4LA Asset")
        var
            FinProd: Record "S4LA Financial Product";
            LeasingSetup: Record "S4LA Leasing Setup";
        begin
            LeasingSetup.Get;
            if not FinProd.Get(Contr."Financial Product") then
                FinProd.Init();

            //"Acquisition Source" := "Acquisition Source"::Supplier; //by default. User may override.
            //"Supplier No." := Contr."Supplier No.";
            Rec."Acquisition Source" := LeasingSetup."S4LNA Def. Acquisition Source";//PYAS-356   "Acquisition Source"::Stock;

            Rec."Supplier No." := OldRec."Supplier No.";
            Rec."Supplier Name" := OldRec."Supplier Name";
            Rec."PYA Tax Group" := FinProd."PYA Tax Group"; //default, user can override
        end;
    */
    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnSplitAssetLine_BeforeInsert', '', false, false)]
    local procedure Asset_OnSplitAssetLine_BeforeInsert(var Rec: Record "S4LA Asset"; var Asset: Record "S4LA Asset")
    begin
        if Rec."PYA Tax Group" <> '' then
            Asset.Validate("PYA Tax Group", Rec."PYA Tax Group");
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnBuildDescription_BeforeExit', '', false, false)]
    local procedure Asset_OnBuildDescription_BeforeExit(var Rec: Record "S4LA Asset"; var Txt: Text)
    var
        AssetModel: Record "S4LA Asset Model";
        AssetManuf: Record "S4LA Asset Brand";
        AssetGrp: Record "S4LA Asset Group";
    begin
        Txt := '';

        if AssetModel.Get(Rec.Model) then
            //IF AssetModel.GET(Manufacturer, Model) THEN // BEGIN
            Txt := AssetModel."Model Description" + ' ';
        //end else begin
        // if model not in list (manual entry) then compose asset description
        if AssetManuf.Get(Rec."Asset Brand") then begin
            if AssetManuf.Description <> '' then
                Txt += AssetManuf.Description + ' ';
            //TG210121 - still need manufacturer in description when not GET
        end else
            Txt += Rec."Asset Brand" + ' ';
        //---
        if AssetGrp.Get(Rec."Asset Group") then
            if AssetGrp."Asset Group Descr." <> '' then
                Txt += AssetGrp."Asset Group Descr." + ' ';
        if Rec.Model <> '' then
            Txt += Rec.Model + ' ';
        /*TG200828*/
        //IF "Model Year"<>0 THEN
        //  Txt += FORMAT("Model Year") + ' ';
        if Rec."Model Year" <> 0 then
            if Txt <> '' then
                Txt := Format(Rec."Model Year") + ' ' + Txt
            else
                Txt := Format(Rec."Model Year");
        /*---*/
        //end;

        //--- used asset
        //if ("Asset New / Used" <> "Asset New / Used"::" ") and
        //    ("Asset New / Used" <> "Asset New / Used"::New)
        //then
        //    Txt += ' (' + Format("Asset New / Used") + ')';
        /*DV170316*/
        //Txt := FORMAT("Model Year",0) + ' '+Manufacturer + ' ' + Model;
        /*TG200828*/
        if Rec."NA Trim" <> '' then
            Txt := Txt + Rec."NA Trim";
        /*---*/

        Txt := DelChr(Txt, '<>');
        Rec.Validate("Asset Description", CopyStr(Txt, 1, MaxStrLen(Rec."Asset Description"))); //PYAS-126
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnBeforeContractModify_UpdateAssetsDescriptionOnContract', '', false, false)]
    local procedure Asset_OnBeforeContractModify_UpdateAssetsDescriptionOnContract(Asset: Record "S4LA Asset"; var Contract: Record "S4LA Contract")
    var
        FirstAsset: Record "S4LA Asset";
    begin
        FirstAsset.Reset();
        FirstAsset.SetRange("Contract No.", Contract."Contract No.");
        if FirstAsset.FindFirst() then begin
            if Asset."Line No." = FirstAsset."Line No." then
                Contract."Assets Description" := Asset."Asset Description"
            else
                Contract."Assets Description" := FirstAsset."Asset Description";
        end else
            Contract."Assets Description" := Asset."Asset Description";
    end;

    //Applicant
    [EventSubscriber(ObjectType::Table, Database::"S4LA Applicant", 'OnDelete_BeforeCheck', '', false, false)]
    local procedure Applicant_OnDelete_BeforeCheck(var Rec: Record "S4LA Applicant"; var isHandled: Boolean)
    var
        Contr: Record "S4LA Contract";
        Text002: Label 'You cannot delete Primary Applicant record.';
    begin
        if Contr.Get(Rec."Contract No.") then //DV171116
            if ((Contr.Status = Contr.Status::Quote) and (Contr."Quote Status" = Contr."Quote Status"::New)) or (Contr.Status = Contr.Status::Application) then begin
            end else
                if Rec."Role Type" = Rec."Role Type"::"Primary Applicant" then
                    Error(Text002);
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Applicant", 'OnIndividualBusiness_BeforeCheck', '', false, false)]
    local procedure Applicant_OnIndividualBusiness_BeforeCheck(var Rec: Record "S4LA Applicant"; var isHandled: Boolean)
    var
        ApplRole: Record "S4LA Applicant Role";
        Contr: Record "S4LA Contract";
        FinProduct: Record "S4LA Financial Product";
    begin
        //>>PA150314
        ApplRole.Reset();
        ApplRole.SetRange(ApplRole."Role Type", ApplRole."Role Type"::"Primary Applicant");
        if ApplRole.FindFirst() then
            repeat//DV171117 do for all roles
                if (Rec."Role in Contract" = ApplRole.Code) then//>>We check for Individual business in case of primary applicant
                    if Contr.Get(Rec."Contract No.") then
                        if Contr."Financial Product" <> '' then begin
                            FinProduct.Get(Contr."Financial Product");
                            if FinProduct."Applies for Individual/Busines" <> FinProduct."Applies for Individual/Busines"::All then
                                if FinProduct."Applies for Individual/Busines" = FinProduct."Applies for Individual/Busines"::Individual then
                                    Rec.TestField("Individual/Business", Rec."Individual/Business"::Individual)
                                else
                                    if FinProduct."Applies for Individual/Busines" = FinProduct."Applies for Individual/Busines"::Business then
                                        Rec.TestField("Individual/Business", Rec."Individual/Business"::Business);
                        end;
            //>>PA150314
            until ApplRole.Next() = 0;
    end;

    //Document
    [EventSubscriber(ObjectType::Table, Database::"S4LA Document", 'OnCreateOpenDocument_BeforeCreate', '', false, false)]
    local procedure Document_OnCreateOpenDocument_BeforeCreate(var Rec: Record "S4LA Document"; var isHandled: Boolean)
    var
        Create: Boolean;
        Attachment: Record Attachment;
    begin
        Create := false;
        if Rec."Attachment No." = 0 then begin
            Create := true;
            Rec.CreateDocument();
        end;

        if Attachment.Get(Rec."Attachment No.") then;//DV181107
                                                     //IF (Create = TRUE) AND (Attachment."File Extension" = 'XLSX') THEN //DV181025
        if ((Create = true) and (Attachment."File Extension" = 'XLSX')) or (Attachment."File Extension" = '') then //DV190308
            exit;
        Rec.OpenDocument();
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Document", 'OnCreateDocument_Check', '', false, false)]
    local procedure Document_OnCreateDocument_Check(var Rec: Record "S4LA Document")
    var
        DocumentSetup: Record "S4LA Document Selection";
        Contr: Record "S4LA Contract";
    begin
        //TG211007 - this is only needed for Contract table
        if Rec."Table ID" = Database::"S4LA Contract" then begin
            //IF "Table ID" = DATABASE::Contract THEN
            if Contr.Get(Rec."Key Code 1") then;
            //JM180201++
            DocumentSetup.Reset();
            DocumentSetup.SetRange("Financial Product", Contr."Financial Product");
            if not DocumentSetup.FindSet() then
            //DocumentSetup.TESTFIELD("Quote Template")
            //ELSE BEGIN
            begin
                DocumentSetup.SetRange("Financial Product", '');
                DocumentSetup.SetRange("Language Code", '');
                DocumentSetup.FindFirst();
                DocumentSetup.TestField("Quote Template");
            end;
            /*DV181114*/
            /*DV190308*/
            /*LeasingSetup2.GET;
                  IF ("Template Code" = DocumentSetup."Quick Quote Template") THEN BEGIN//DV181116
                      CLEAR(MoreQuotePage);
                      Contr."Print Quote No2" := '';
                      Contr."Print Quote No3" := '';
                      Contr.MODIFY;
                      COMMIT;
                      Contr.SETRECFILTER;
                      MoreQuotePage.SETTABLEVIEW(Contr);
                      MoreQuotePage.EDITABLE(TRUE);
                      MoreQuotePage.LOOKUPMODE := TRUE;
                      IF MoreQuotePage.RUNMODAL = ACTION::LookupOK THEN
                          MoreQuotePage.GETRECORD(Contr)
                      ELSE BEGIN
                          Contr."Print Quote No2" := '';
                          Contr."Print Quote No3" := '';
                      END;
                  END;*/
            /*---*/
            /*DV181113*/
            /*IF "Template Code" = DocumentSetup."Quote Template" THEN
            BEGIN
              ContractServices.RESET;
              ContractServices.SETRANGE("Contract No.", Contr."Contract No.");
              ContractServices.SETRANGE(Type, ContractServices.Type::Admin);
              IF NOT ContractServices.FINDSET THEN
                ERROR(PYAText001);
            END;*/
            //JM180201--
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Document", 'OnCreateDocument_ReportLayout', '', false, false)]
    local procedure Document_OnCreateDocument_ReportLayout(var Rec: Record "S4LA Document"; var DocTemplate: Record "S4LA Document Template"; var CustomReportLayout: Record "Custom Report Layout"; var ReportLayoutSelection: Record "Report Layout Selection"; var isHandled: Boolean)
    begin

        if (DocTemplate."Output Doc Format" = DocTemplate."Output Doc Format"::"Save as EXCEL") and (DocTemplate."Custom Report Layout Code" <> '') then begin//DV181025
            DocTemplate.TestField("Custom Report Layout Code");
            CustomReportLayout.Get(DocTemplate."Custom Report Layout Code");
            ReportLayoutSelection.SetTempLayoutSelected(CustomReportLayout.Code);
        end;
        if CustomReportLayout.Get(DocTemplate."Custom Report Layout Code") then //DV181204
            ReportLayoutSelection.SetTempLayoutSelected(CustomReportLayout.Code);

        isHandled := true;
    end;
    /* --- SOLV-1422 replaced with event OnBeforePrintLeasingDocuments
    [EventSubscriber(ObjectType::Table, Database::"S4LA Document", 'OnCreateDocument_Print', '', false, false)]
    local procedure Document_OnCreateDocument_Print(var Rec: Record "S4LA Document"; DocTemplate: Record "S4LA Document Template"; CustomReportLayout: Record "Custom Report Layout"; ServerFileName: Text; var isHandled: Boolean);
    var
        QuoteApplicationContract: Record "S4LA Contract";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        WorkOrdHdr: Record "S4LA Work Order Header";
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
                                DocTemplate."Output Doc Format"::"Save as PDF":
                                    REPORT.SaveAsPdf(CustomReportLayout."Report ID", ServerFileName, QuoteApplicationContract);
                                DocTemplate."Output Doc Format"::"Save as WORD":
                                    REPORT.SaveAsWord(CustomReportLayout."Report ID", ServerFileName, QuoteApplicationContract);
                                // DV180831
                                DocTemplate."Output Doc Format"::"Save As EXCEL":
                                    IF CustomReportLayout."Report ID" <> 0 THEN
                                        REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, QuoteApplicationContract)
                                    ELSE BEGIN
                                        Rec.WritetoExcel;//DV181024
                                    END;
                                // SOLV-1422 --- enum values "PDF Form (editable)", "PDF Form (read-only)" have been removed because dotnet is not suported in cloud
                                DocTemplate."Output Doc Format"::"PDF Form (editable)":
                                    Rec.FillPDFform(ServerFileName, QuoteApplicationContract, false); //KS160203
                                DocTemplate."Output Doc Format"::"PDF Form (read-only)":
                                    Rec.FillPDFform(ServerFileName, QuoteApplicationContract, true); //KS160203
                            end;
                            isHandled := true;
                        end; //case TRUE
                    end;
                end;//Contract table
            // >> SK151002
            DATABASE::"Sales Header":
                BEGIN
                    SalesHeader.SETRANGE("Document Type", Rec."Key Int 1");
                    SalesHeader.SETRANGE("No.", Rec."Key Code 1");
                    SalesHeader.FINDFIRST;
                    CASE DocTemplate."Output Doc Format" OF
                        DocTemplate."Output Doc Format"::"Save as PDF":
                            REPORT.SAVEASPDF(CustomReportLayout."Report ID", ServerFileName, SalesHeader);
                        DocTemplate."Output Doc Format"::"Save as WORD":
                            REPORT.SAVEASWORD(CustomReportLayout."Report ID", ServerFileName, SalesHeader);
                        // DV180905
                        DocTemplate."Output Doc Format"::"Save As EXCEL":
                            BEGIN
                                IF CustomReportLayout."Report ID" <> 0 THEN
                                    REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, SalesHeader)
                                ELSE BEGIN
                                    Rec.WritetoExcel;//DV181024
                                END;
                            END;
                    //DocTemplate."Output Doc Format"::"Save As EXCEL": REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, SalesHeader);
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
                        // DV180905
                        DocTemplate."Output Doc Format"::"Save As EXCEL":
                            BEGIN
                                IF CustomReportLayout."Report ID" <> 0 THEN
                                    REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, PurchaseHeader)
                                ELSE BEGIN
                                    Rec.WritetoExcel;//DV181024
                                END;
                            END;
                    //DocTemplate."Output Doc Format"::"Save As EXCEL": REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, PurchaseHeader);
                    END;
                    isHandled := true;
                END;
            //DV170712
            DATABASE::"S4LA Work Order Header":
                BEGIN
                    WorkOrdHdr.SETRANGE("No.", Rec."Key Code 1");
                    WorkOrdHdr.FINDFIRST;
                    CASE DocTemplate."Output Doc Format" OF
                        DocTemplate."Output Doc Format"::"Save as PDF":
                            REPORT.SAVEASPDF(CustomReportLayout."Report ID", ServerFileName, WorkOrdHdr);
                        DocTemplate."Output Doc Format"::"Save as WORD":
                            REPORT.SAVEASWORD(CustomReportLayout."Report ID", ServerFileName, WorkOrdHdr);
                        // DV180905
                        DocTemplate."Output Doc Format"::"Save As EXCEL":
                            BEGIN
                                IF CustomReportLayout."Report ID" <> 0 THEN
                                    REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, WorkOrdHdr)
                                ELSE BEGIN
                                    Rec.WritetoExcel;//DV181024
                                END;
                            END;
                    //DocTemplate."Output Doc Format"::"Save As EXCEL": REPORT.SAVEASEXCEL(CustomReportLayout."Report ID", ServerFileName, WorkOrdHdr);
                    END;
                    isHandled := true;
                END;
        end; //case per table
    end;
    */
    /*
        //[EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Leasing Document Mgt.", 'OnBeforePrintLeasingDocuments', '', false, false)]
        //local procedure OnBeforePrintLeasingDocuments(var Sender: Record "S4LA Document"; DocTemplate: Record "S4LA Document Template"; CustomReportLayout: Record "Custom Report Layout"; var TempBlob: Codeunit "Temp Blob"; var isHandled: Boolean);
        var
            WorkOrdHdr: Record "S4LA Work Order Header";
            RecRef: RecordRef;
            OStream: OutStream;
            EarlyPayout: Record "S4LA Early Payout";
        begin
            case Sender."Table ID" of
                Database::"S4LA Work Order Header":
                    begin
                        WorkOrdHdr.SetRange("No.", Sender."Key Code 1");
                        RecRef.GetTable(WorkOrdHdr);
                        TempBlob.CreateOutStream(OStream);
                        Report.SaveAs(CustomReportLayout."Report ID", '', DocTemplate.GetReportFormat(), OStream, RecRef);
                        isHandled := true;
                    end;
                //PYAS-369
                DATABASE::"S4LA Early Payout":
                    BEGIN
                        EarlyPayout.SETRANGE("No.", Rec."Key Code 1");
                        EarlyPayout.FINDFIRST;
                        RecRef.GetTable(WorkOrdHdr);
                        TempBlob.CreateOutStream(OStream);
                        Report.SaveAs(CustomReportLayout."Report ID", '', DocTemplate.GetReportFormat(), OStream, RecRef);
                        isHandled := true;
                    END;
            //--//
            end;
        end;
        */

    [EventSubscriber(ObjectType::Table, Database::"S4LA Document", 'OnCreateDocument_Attachment', '', false, false)]
    local procedure Document_OnCreateDocument_Attachment(var Rec: Record "S4LA Document"; var DocTemplate: Record "S4LA Document Template"; var TempBlob: Codeunit "Temp Blob"; var isHandled: Boolean)
    begin
        if DocTemplate."Output Doc Format" = DocTemplate."Output Doc Format"::"Save as EXCEL" then
            isHandled := true; //DV181025
    end;

    //Work Order Header
    [EventSubscriber(ObjectType::Table, Database::"S4LA Work Order Header", 'OnWorkOrderHeader_ContractNoLookup', '', false, false)]
    local procedure WorkOrderHeader_OnWorkOrderHeader_ContractNoLookup(var Rec: Record "S4LA Work Order Header"; var isHandled: Boolean)
    var
        Contract: Record "S4LA Contract";
        ContractListPage: Page "S4LA General Contract List";
    begin
        Contract.Reset();
        Contract.SetFilter("Customer No.", Rec."Customer No.");
        Contract.SetFilter(Status, '%1|%2', Contract.Status::Application, Contract.Status::Contract); //TG200511
        ContractListPage.LookupMode := true;
        ContractListPage.SetTableView(Contract);

        if Rec."Contract No." <> '' then begin
            Contract.SetFilter("Contract No.", Rec."Contract No.");
            if Contract.FindFirst() then
                ContractListPage.SetRecord(Contract);
            Contract.SetRange("Contract No.");
        end;
        if ContractListPage.RunModal() = Action::LookupOK then begin
            ContractListPage.GetRecord(Contract);
            //VALIDATE("Contract No.", "Contract No.");
            Rec.Validate("Contract No.", Contract."Contract No.");//DV170906
            isHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Work Order Header", 'OnInvoiceWorkOrder_BeforeInsertSalesHeader', '', false, false)]
    local procedure WorkOrderHeader_OnInvoiceWorkOrder_BeforeInsertSalesHeader(var Rec: Record "S4LA Work Order Header"; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."External Document No." := Rec."S4LNA External Document No.";//DV170404
        SalesHeader.Validate("Tax Area Code", Rec."Tax Area Code");
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Work Order Header", 'OnInvoiceWorkOrder_BeforeInsertSalesLine', '', false, false)]
    local procedure WorkOrderHeader_OnInvoiceWorkOrder_BeforeInsertSalesLine(var Rec: Record "S4LA Work Order Header"; var WorkOrderLine: Record "S4LA Work Order Line"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Tax Area Code", WorkOrderLine."Tax Area Code");//DV170919
        SalesLine.Validate("Tax Group Code", WorkOrderLine."Tax Group Code");//DV170919
        SalesLine."Tax Liable" := WorkOrderLine."Tax Liable";//DV170919
    end;

    //Gen. Jnl.-Post Line

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitCustLedgEntry', '', false, false)]
    local procedure GenJnlPostLine_OnAfterInitCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    var
        LContr: Record "S4LA Contract";
    begin
        /*DV191205*/
        if not LContr.Get(GenJournalLine."PYA Contract No") then
            Clear(LContr);
        //CustLedgerEntry."S4LNA WHS Funder" := LContr.Funder;
        //CustLedgerEntry."S4LNA WHS Funding Ref.No." := LContr."S4LNA WHS Funding Ref.No.";
        /*---*/
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostFixedAssetOnAfterSaveGenJnlLineValues', '', false, false)]
    local procedure GenJnlPostLine_OnPostFixedAssetOnAfterSaveGenJnlLineValues(var GenJournalLine: Record "Gen. Journal Line")
    begin
        UpdateInfoWhenPostingToAsset(GenJournalLine);//DV170725
        UpdateFAPostingGroupToAsset(GenJournalLine);//DV170726
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInitGLEntry', '', false, false)]
    local procedure GenJnlPostLine_OnAfterInitGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GLEntry."External Document No." := GenJournalLine."External Document No.";//DV170403
                                                                                  // PYAS-307 Loan Changes
        GLEntry."PYA Installment Part" := GenJournalLine."PYA Installment Part";
        //GLEntry."S4LA Loan Line No." := GenJournalLine."S4LA Loan Line No.";
        //GLEntry."S4LA Loan No." := GenJournalLine."S4LA Loan No.";

        //BA221017
        if GenJournalLine."S4LA Loan No." <> '' then
            UpdateLoanSchedule(GenJournalLine);
        //--//
    end;

    local procedure UpdateLoanSchedule(JnLine: Record "Gen. Journal Line")
    var
        LoanScheduleLine: Record "S4LA Loan Schedule Line";
    begin
        //S4L.BOR
        if (JnLine."S4LA Loan No." = '') and (JnLine."S4LA Loan Line No." = 0) then
            exit;

        LoanScheduleLine.Reset();
        LoanScheduleLine.SetRange("Loan No.", JnLine."S4LA Loan No.");
        LoanScheduleLine.SetRange("Line No.", JnLine."S4LA Loan Line No.");
        if LoanScheduleLine.FindFirst() then begin
            LoanScheduleLine.Posted := true;
            LoanScheduleLine.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseGLEntryOnAfterInsertGLEntry', '', false, false)]
    local procedure ReverseGLEntryOnAfterInsertGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")

    var
        LoanScheduleLine: Record "S4LA Loan Schedule Line";
    begin
        // PYAS-307 Loan Changes
        if (GLEntry."S4LA Loan No." = '') and (GLEntry."S4LA Loan Line No." = 0) then
            exit;
        LoanScheduleLine.Reset();
        LoanScheduleLine.SetRange("Loan No.", GLEntry."S4LA Loan No.");
        LoanScheduleLine.SetRange("Line No.", GLEntry."S4LA Loan Line No.");
        if LoanScheduleLine.FindFirst() then begin
            LoanScheduleLine.Posted := false;
            LoanScheduleLine.Modify();
        end;
    end;

    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'S4LNA_OnBeforeApplyCustLedgEntry', '', false, false)]
    //local procedure GenJnlPostLine_OnBeforeApplyCustLedgEntry_NA(var GenJnlLine: Record "Gen. Journal Line"; var Cust: Record Customer)
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnBeforeApplyCustLedgEntry', '', false, false)]
    local procedure GenJnlPostLine_OnBeforeApplyCustLedgEntry(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var DtldCVLedgEntryBuf: Record "Detailed CV Ledg. Entry Buffer"; var GenJnlLine: Record "Gen. Journal Line"; Cust: Record Customer; var IsAmountToApplyCheckHandled: Boolean)
    var
        GlbGenJournalBatch: Record "Gen. Journal Batch";
    begin
        //JM170723++
        if GlbGenJournalBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
            if GlbGenJournalBatch."S4LNA Apply to Oldest" then begin
                //tmpCust."Application Method" := Cust."Application Method";
                //S4LA use isolated storage for globals
                IsolatedStorage.Set(Cust.TableName + Cust.FieldName("Application Method") + Format(SessionId()), Format(Cust."Application Method"), DataScope::CompanyAndUser);
                Cust."Application Method" := Cust."Application Method"::"Apply to Oldest";
            end;
        //JM170723--
        OnBeforeApplyCustLedgEntry_Cust := Cust;
    end;

    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'S4LNA_OnAfterApplyCustLedgEntry', '', false, false)]
    //local procedure GenJnlPostLine_OnAfterApplyCustLedgEntry_NA(var GenJnlLine: Record "Gen. Journal Line"; var Cust: Record Customer)
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterApplyCustLedgEntry', '', false, false)]
    local procedure OnAfterApplyCustLedgEntry(var GenJnlLine: Record "Gen. Journal Line"; var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCustLedgEntry: Record "Cust. Ledger Entry")
    var
        GlbGenJournalBatch: Record "Gen. Journal Batch";
        ApplicationMethod: Text;
    begin
        //JM170723++
        if GlbGenJournalBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name") then
            if GlbGenJournalBatch."S4LNA Apply to Oldest" then begin
                //S4LA use isolated storage for globals
                IsolatedStorage.Get(OnBeforeApplyCustLedgEntry_Cust.TableName + OnBeforeApplyCustLedgEntry_Cust.FieldName("Application Method") + Format(SessionId()), DataScope::CompanyAndUser, ApplicationMethod);
                IsolatedStorage.Delete(OnBeforeApplyCustLedgEntry_Cust.TableName + OnBeforeApplyCustLedgEntry_Cust.FieldName("Application Method") + Format(SessionId()), DataScope::CompanyAndUser);
                Evaluate(OnBeforeApplyCustLedgEntry_Cust."Application Method", ApplicationMethod);
            end;
        //JM170723--
    end;

    //BA221206 -
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPostCustOnBeforeTempDtldCVLedgEntryBufCopyFromGenJnlLine', '', false, false)]
    local procedure PostCustOnBeforeTempDtldCVLedgEntryBufCopyFromGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Cust: Record Customer; GLReg: Record "G/L Register")
    var
        GlbGenJournalBatch: Record "Gen. Journal Batch";
    begin
        if GlbGenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            if GlbGenJournalBatch."S4LNA Apply to Oldest" then
                Cust."Application Method" := Cust."Application Method"::"Apply to Oldest";
    end;
    //--//

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempCustLedgEntryOnAfterSetFilters', '', false, false)]
    local procedure GenJnlPostLine_OnPrepareTempCustLedgEntryOnAfterSetFilters(var OldCustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    var
        GlbGenJournalBatch: Record "Gen. Journal Batch";
        date1: Date;
        date2: Date;
        FactoringSetup: Record "S4LA Factoring Setup";
    begin
        if not FactoringSetup.Get() then
            FactoringSetup.Init();

        if not GlbGenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            GlbGenJournalBatch.Init();
        if GlbGenJournalBatch."S4LNA Apply to Oldest" then //JM170723++
         begin //JM190410++
            OldCustLedgerEntry.SetRange("PYA Contract No", GenJournalLine."PYA Contract No"); //KS150610
                                                                                              //<<KG
                                                                                              //            if FactoringSetup."Cust. L. Applic. By Fact. Agr." then //S4L.FACT EN190520
                                                                                              //                OldCustLedgerEntry.SetRange("S4LA Factoring Agreement No.", GenJournalLine."S4LA Factoring Agreement No."); //S4L.FACT
                                                                                              //JM190410++
            OldCustLedgerEntry.SetRange(Amount, -GenJournalLine.Amount);
            date1 := (CalcDate('CM-1M+1D', GenJournalLine."Posting Date"));
            date2 := (CalcDate('CM', GenJournalLine."Posting Date"));
            OldCustLedgerEntry.SetFilter("Posting Date", '%1..%2', date1, date2);
            //JM190410++
        end else begin
            OldCustLedgerEntry.SetRange("PYA Contract No");
            //OldCustLedgerEntry.SetRange("S4LA Factoring Agreement No.");
            OldCustLedgerEntry.SetRange(Amount);
            OldCustLedgerEntry.SetRange("Posting Date");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempCustLedgEntryOnAfterSetFiltersByAppliesToId', '', false, false)]
    //local procedure GenJnlPostLine_S4LOnPrepareTempCustLedgEntryOnAfterSetFilters(var OldCustLedgEntry: Record "Cust. Ledger Entry"; var TempOldCustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    local procedure GenJnlPostLine_OnPrepareTempCustLedgEntryOnAfterSetFiltersByAppliesToId(var OldCustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer"; Customer: Record Customer)

    var
        GlbGenJournalBatch: Record "Gen. Journal Batch";
        FactoringSetup: Record "S4LA Factoring Setup";
        date1: Date;
        date2: Date;

    begin
        if not GlbGenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            GlbGenJournalBatch.Init();
        if not FactoringSetup.Get() then
            FactoringSetup.Init();

        if GlbGenJournalBatch."S4LNA Apply to Oldest" then //JM170723++
        begin //JM190410
            OldCustLedgerEntry.SetRange("PYA Contract No", GenJournalLine."PYA Contract No"); //KS150610
            if FactoringSetup."Cust. L. Applic. By Fact. Agr." then //S4L.FACT EN190520
                OldCustLedgerEntry.SetRange("S4LA Factoring Agreement No.", GenJournalLine."S4LA Factoring Agreement No."); //S4L.FACT
                                                                                                                            //JM190410++
            OldCustLedgerEntry.SetRange(Amount, -GenJournalLine.Amount);
            date1 := (CalcDate('CM-1M+1D', GenJournalLine."Posting Date"));
            date2 := (CalcDate('CM', GenJournalLine."Posting Date"));
            OldCustLedgerEntry.SetFilter("Posting Date", '%1..%2', date1, date2);

            //JM190410--
        end else begin
            OldCustLedgerEntry.SetRange("PYA Contract No");
            //OldCustLedgerEntry.SetRange("S4LA Factoring Agreement No.");
            OldCustLedgerEntry.SetRange(Amount);
            OldCustLedgerEntry.SetRange("Posting Date");
        end;
    end;

    local procedure UpdateInfoWhenPostingToAsset(recJnlLine: Record "Gen. Journal Line")
    var
        recSchedule: Record "S4LA Schedule";
        NewStatus: Record "S4LA Status";
        Contract: Record "S4LA Contract";
        recSourceCodeSetup: Record "Source Code Setup";

        LeasingSetup: Record "S4LA Leasing Setup";
        FASetup: Record "FA Setup";
        recFA: Record "Fixed Asset";
        recProduct: Record "S4LA Financial Product";
        RecVariant: Variant;
        GateChangeMgt: Codeunit "S4LA Status Mgt";
        AssetDeprBook: Record "FA Depreciation Book";
        AssetStatus: Record "S4LA Status";
    begin
        //Update Asset status if no Contract
        //DV170725
        if recJnlLine."PYA Contract No" <> '' then
            exit;
        //Update schedule and Asset status
        //----- force shedule status (user selected before posting)
        if recJnlLine."S4LA To Schedule Status" <> '' then begin
            recSchedule.Reset();
            recSchedule.SetRange("Contract No.", recJnlLine."PYA Contract No");
            //recSchedule.SetRange("Schedule No.", recJnlLine."S4LA Schedule No.");
            recSchedule.SetFilter("Version status", '<>%1', recSchedule."Version status"::Old);
            if recSchedule.FindSet() then
                repeat
                    if recSchedule."Status Code" <> recJnlLine."S4LA To Schedule Status" then begin
                        NewStatus.Get(recJnlLine."S4LA To Schedule Status");
                        recSchedule.StatusChange(NewStatus, recJnlLine."Posting Date");
                        Contract.Get(recSchedule."Contract No.");
                        Contract."Status Code" := recSchedule."Status Code";
                        Contract.Modify();
                    end;
                until recSchedule.Next() = 0;
            exit;
        end;

        recSourceCodeSetup.Get();
        LeasingSetup.Get();
        FASetup.Get();
        //--== Lease Activation ==--
        if (recJnlLine."Source Code" = recSourceCodeSetup."S4LA Lease Activation") and (recJnlLine."Source Code" <> '') then begin
            recSchedule.Reset();
            recSchedule.SetRange("Contract No.", recJnlLine."PYA Contract No");
            //recSchedule.SetRange("Schedule No.", recJnlLine."S4LA Schedule No.");
            recSchedule.SetFilter("Version status", '<>%1', recSchedule."Version status"::Old);
            if recSchedule.FindSet() then
                repeat
                    //recFA.GET(recSchedule."S#Asset No.");
                    recFA.Get(recJnlLine."Account No."); //TG200925
                    if not recProduct.Get(recSchedule."Financial Product") then
                        recProduct.Init();

                    if recSchedule.Status <> recSchedule.Status::Contract then begin
                        RecVariant := recSchedule;
                        GateChangeMgt.TriggerStatusChange(RecVariant, RecVariant, recSchedule.Status::Contract.AsInteger(), recJnlLine."Posting Date", recSchedule.FieldNo("Status Code"));
                        recSchedule.Get(recSchedule."Contract No.", recSchedule."Schedule No.", recSchedule."Version No.");
                        Contract.Get(recSchedule."Contract No.");
                        Contract."Status Code" := recSchedule."Status Code";
                        Contract.Modify();
                        if LeasingSetup."FA Status - On Active Contract" <> '' then
                            recFA.Validate("S4LA Asset Status Code", LeasingSetup."FA Status - On Active Contract");
                        recFA."S4LA Schedule Status Code" := recSchedule."Status Code";
                        //recFA."S4LA Schedule Status Trigger" := recSchedule.Status.AsInteger();
                        recFA.Modify();
                    end;

                    //---------------------- UPDATE FIXED ASSET CARD DEPRECIATION FIELDS
                    if recProduct."Accounting Group" = recProduct."Accounting Group"::"Gross Receivable" then begin
                        AssetDeprBook.Get(recFA."No.", FASetup."Default Depr. Book");
                        AssetDeprBook.Validate("Depreciation Starting Date", recSchedule."Starting Date");
                        AssetDeprBook.Validate("No. of Depreciation Months", recSchedule."Term (months)");
                        AssetDeprBook.Modify();
                    end;
                until recSchedule.Next() = 0;
        end;
        if recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::Disposal then
            if (recJnlLine."Source Code" = recSourceCodeSetup.Sales) and (recJnlLine."Source Code" <> '') then begin
                //--== Asset sold ==--
                recFA.Get(recJnlLine."Account No.");
                if LeasingSetup."FA Status - Sold" <> '' then
                    recFA.Validate("PYA Asset Status Code", LeasingSetup."FA Status - Sold");
                //recFA."PYA Status Code" := recSchedule."Status Code";
                //recFA."S4LA Schedule Status Trigger" := recSchedule.Status.AsInteger();
                recFA.Modify();
            end;
        //EN190809 >>
        /*
        IF (recJnlLine."Source Code" = recSourceCodeSetup.Termination) AND (recJnlLine."Source Code" <> '') THEN BEGIN
                    //--== Asset goes to Stock ==---
                    recSchedule.RESET;
                    recSchedule.SETRANGE("Contract No.", recJnlLine."Contract No.");
                    recSchedule.SETRANGE("Schedule No.", recJnlLine."Schedule No.");
                    recSchedule.SETFILTER("Version status", '<>%1', recSchedule."Version status"::Old);
                    IF recSchedule.FINDSET THEN
                        REPEAT
                            IF recSchedule.Status <> recSchedule.Status::"9" THEN BEGIN
                                //--== Asset status becomes STOCK ==--
                                RecVariant := recSchedule;
                                GateChangeMgt.TriggerStatusChange(RecVariant, RecVariant, recSchedule.Status::"9", recJnlLine."Posting Date", recSchedule.FIELDNO("Status Code"));
                                recSchedule.GET(recSchedule."Contract No.", recSchedule."Schedule No.", recSchedule."Version No.");
                                Contract.GET(recSchedule."Contract No.");
                                Contract."Status Code" := recSchedule."Status Code";
                                Contract.MODIFY;
                            END;
                        UNTIL recSchedule.NEXT = 0;
                END;
        */
        //EN190809 <<

        if recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::"Acquisition Cost" then begin
            recFA.Get(recJnlLine."Account No.");
            if recFA."S4LA Asset Status Trigger" = recFA."S4LA Asset Status Trigger"::"Internal Fixed Asset" then
                if (recJnlLine."Source Code" = recSourceCodeSetup.Purchases) and (recJnlLine."Source Code" <> '') then
                    recFA.S4LNAUpdateDeprStartingDate(recJnlLine."Posting Date");

            if (recJnlLine."Source Code" = recSourceCodeSetup.Purchases) and (recJnlLine."Source Code" <> '') then begin
                recFA."S4LA Planned Purch.Price exVAT" += recJnlLine."Amount (LCY)";
                recFA.Modify();
            end;

            if not recProduct.Get(recFA."S4LA Fin. Product Code") then
                recProduct.Init();

            recSchedule.Reset();
            recSchedule.SetRange("Contract No.", recJnlLine."PYA Contract No");
            recSchedule.SetRange("Schedule No.", recJnlLine."S4LA Schedule No.");
            recSchedule.SetFilter("Version status", '<>%1', recSchedule."Version status"::Old);
            if recSchedule.FindSet() then
                //Schedule update
                repeat
                    if (recJnlLine."Source Code" = recSourceCodeSetup."S4LA Lease Activation") and
                       (recJnlLine."Source Code" <> '') then
                        if recSchedule."Activation Date" = 0D then
                            recSchedule."Activation Date" := recJnlLine."Posting Date";

                    if (recJnlLine."Source Code" = recSourceCodeSetup.Purchases) and
                       (recJnlLine."Source Code" <> '') then;

                    // IF recSchedule."S#Purchase Date" = 0D THEN
                    //     recSchedule."S#Purchase Date" := recJnlLine."Posting Date";
                    //EN190809 >>
                    /*
                    IF recSchedule.Status < recSchedule.Status::"5" THEN BEGIN
                            RecVariant := recSchedule;
                            GateChangeMgt.TriggerStatusChange(RecVariant, RecVariant, recSchedule.Status::"5", recJnlLine."Posting Date", recSchedule.FIELDNO("Status Code"));
                            recSchedule.GET(recSchedule."Contract No.", recSchedule."Schedule No.", recSchedule."Version No.");
                        END;
                    */
                    //EN190809 <<

                    if (recJnlLine."Source Code" = recSourceCodeSetup."S4LA Asset Repossession") and
                       (recJnlLine."Source Code" <> '') then begin
                        recSchedule."Termination Status" := recSchedule."Termination Status"::"W/O Loss recovery";
                        recSchedule."Termination Date" := recJnlLine."Posting Date";
                        recSchedule.Modify();
                    end;

                    recSchedule.Modify();
                    Contract.Get(recSchedule."Contract No.");
                    Contract."Status Code" := recSchedule."Status Code";
                    Contract.Modify();
                until recSchedule.Next() = 0
            else begin
                //--== Asset is not related to Lease ==--
                //EN190809 >>
                if LeasingSetup."FA Status - Internal" <> '' then
                    recFA.Validate("S4LA Asset Status Code", LeasingSetup."FA Status - Internal");
                //EN190809 <<
                recFA."S4LA Schedule Status Code" := '';
                //recFA."S4LA Schedule Status Trigger" := recFA."S4LA Schedule Status Trigger"::" ";
                recFA.Modify();
            end;
        end;

        /*PYA*/
        //IF (recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::"Acquisition Cost") OR
        //   (recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::Disposal)
        if recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::"Acquisition Cost" //TG200923
          then begin
            AssetStatus.Reset();
            AssetStatus.SetRange("Target Table ID", Database::"Fixed Asset");
            AssetStatus.SetRange("Trigger Option No.", recFA."S4LA Asset Status Trigger"::"S4LNA Stock".AsInteger());//DV170724
                                                                                                                     /*DV180406*/
            if recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::Disposal then
                AssetStatus.SetRange("Trigger Option No.", recFA."S4LA Asset Status Trigger"::"S4LNA Sold".AsInteger());

            AssetStatus.FindFirst();
            recFA.Get(recJnlLine."Account No.");
            if not Contract.Get(recFA."PYA Contract No") then
                Clear(Contract);
            ////TG210604
            if (Contract."Status Code" <> LeasingSetup."Status - Active") and (recFA."S4LA Asset Status Code" <> LeasingSetup."FA Status - On Application") then
                if (recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::"Acquisition Cost") then begin
                    recFA."S4LA Asset Status Code" := AssetStatus.Code;
                    //recFA."S4LA Asset Status Trigger" := Enum::"S4LA Asset Status Trigger".FromInteger(AssetStatus."Trigger Option No.");
                end;
            if (recJnlLine."FA Posting Type" = recJnlLine."FA Posting Type"::Disposal) then begin
                LeasingSetup.TestField("FA Status - Sold");
                if recFA."S4LA Asset Status Code" <> LeasingSetup."FA Status - Sold" then
                    //recFA.Validate("S4LA Asset Status Code", LeasingSetup."FA Status - Sold");
            end;
                /*DV180824*/
                if (recJnlLine."Source Code" = recSourceCodeSetup.Purchases) and (recJnlLine."Source Code" <> '') then
                    if (recFA."S4LNA Stock Date" = 0D) or (recJnlLine."Source Code" = recSourceCodeSetup."S4LA Termination To Stock") then
                        recFA."S4LNA Stock Date" := recJnlLine."Posting Date";

                recSchedule.Reset();
                recSchedule.SetRange("Contract No.", recJnlLine."PYA Contract No");
                recSchedule.SetRange("Schedule No.", recJnlLine."S4LA Schedule No.");
                recSchedule.SetFilter("Version status", '<>%1', recSchedule."Version status"::Old);
                if recSchedule.FindFirst() then
                    if (recSchedule."Status Code" = LeasingSetup."Status - Lost") or
                       (recSchedule."Status Code" = LeasingSetup."Status - Flat Cancelled") or
                       (recSchedule."Status Code" = LeasingSetup."Status - Settled in full") or
                       (recSchedule."Status Code" = LeasingSetup."Status - Paid in Full")
                    then
                        //          recFA.GET(recJnlLine."Account No.");
                        recFA."NA Stock Date" := recJnlLine."Posting Date";
                /*DV200608*/  //TG200923 - I think this code isn't needed. It is causing a problem when disposing of asset (status not going to sold)
                              // AssetStatus.RESET;
                              // AssetStatus.SETRANGE("Target Table ID", DATABASE::"Fixed Asset");
                              // AssetStatus.SETRANGE("Trigger Option No.", recFA."Asset Status Trigger"::Stock);
                              // AssetStatus.FINDFIRST;
                              // recFA."S4LA Asset Status Code" := AssetStatus.Code;
                              // recFA."Asset Status Trigger" := AssetStatus."Trigger Option No.";
                              /*---*/
                              /*---*/
                              /*DV190322*/
                if Contract."Status Code" = LeasingSetup."Status - Active" then begin
                    AssetStatus.Reset();
                    AssetStatus.Get(LeasingSetup."FA Status - On Active Contract");
                    recFA."S4LA Asset Status Code" := AssetStatus.Code;
                    recFA."S4LA Asset Status Trigger" := Enum::"S4LA Asset Status Trigger".FromInteger(AssetStatus."Trigger Option No.");
                end;
                /*---*/
                recFA.Modify();
            end;
            /*---*/
        end;

        local procedure UpdateFAPostingGroupToAsset(recJnlLine: Record "Gen. Journal Line")
    var
        recFA: Record "Fixed Asset";
        recFAPostGr: Record "FA Posting Group";
        recFADeprBook: Record "FA Depreciation Book";
    begin
        //Set FA posting group from the last posted entry
        if recJnlLine."Account Type" <> recJnlLine."Account Type"::"Fixed Asset" then
            exit;

        if not recFA.Get(recJnlLine."Account No.") then
            exit;

        if not recFAPostGr.Get(recJnlLine."Posting Group") then
            exit;

        recFA."FA Posting Group" := recJnlLine."Posting Group";
        recFA.Modify();

        recFADeprBook.SetRange("FA No.", recJnlLine."Account No.");
        recFADeprBook.ModifyAll("FA Posting Group", recJnlLine."Posting Group");
    end;

    //Purch.-Post
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostPurchaseDoc', '', false, false)]
    local procedure PurchPost_OnBeforePostPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; CommitIsSupressed: Boolean; var HideProgressWindow: Boolean)
    var
        SalesInvFromPurchInv: Codeunit "S4LNA Sales Inv From Purch Inv";
        AssetNo: Code[20];
        Asset: Record "S4LA Asset";
        Contract: Record "S4LA Contract";
        Text001: Label 'The Fixed Asset (%1) does not match the Contract Number (%2) in the Purchase Order you are about to post. Please verify the Fixed Asset Number and Contract Number in the Purchase Order line are correct.\If this is a PO for a traded in vehicle, you may ignore this message. \Are you sure you want to proceed with this action?';
        Text002: Label 'Process aborted';
        PurchLine: Record "Purchase Line";
    begin
        /*TG190515*/
        if PurchaseHeader."S4LA Re-post to Receivable" then
            SalesInvFromPurchInv.CreateSalesInvoice(PurchaseHeader);
        /*---*/
        //PYAS-177
        AssetNo := '';
        if PurchaseHeader."PYA Contract No" <> '' then begin
            if PurchaseHeader."S4LA Re-post to Receivable" then
                exit;
            Contract.Get(PurchaseHeader."PYA Contract No");
            PurchLine.Reset();
            PurchLine.SetRange("Document No.", PurchaseHeader."No.");
            PurchLine.SetRange(Type, PurchLine.Type::"Fixed Asset");
            if not PurchLine.FindFirst() then
                exit;

            Asset.Reset();
            Asset.SetCurrentKey("Line No.", "Asset No.");
            Asset.SetRange("Contract No.", Contract."Contract No.");
            Asset.SetFilter("Asset No.", '<>%1', '');
            if Asset.FindFirst() then
                if (Asset."Asset No." <> PurchaseHeader."NA Asset No.") and (PurchaseHeader."NA Asset No." <> '') then begin
                    AssetNo := PurchaseHeader."NA Asset No.";
                    if not Confirm(StrSubstNo(Text001, AssetNo, PurchaseHeader."PYA Contract No"), false) then
                        Error(Text002);
                end else
                    if (Asset."Asset No." <> PurchLine."No.") and (PurchLine."No." <> '') then begin
                        AssetNo := PurchLine."No.";
                        if not Confirm(StrSubstNo(Text001, AssetNo, PurchaseHeader."PYA Contract No"), false) then
                            Error(Text002);
                    end;
        end;
        //--//
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforeUpdatePurchLineBeforePost', '', false, false)]
    local procedure PurchPost_OnBeforeUpdatePurchLineBeforePost(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; WhseShip: Boolean; WhseReceive: Boolean; RoundingLineInserted: Boolean; CommitIsSupressed: Boolean)
    begin
        //>>NK150106
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
            if PurchaseLine.Type <> PurchaseLine.Type::" " then
                if PurchaseLine."S4LA Re-post to Receivable" then
                    PurchaseLine.TestField(PurchaseLine."PYA Contract No");
        //<<NK150106
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Purch.-Post Events", 'S4L_OnBeforePostVendorEntry_AfterSetDetailedVendorEntries', '', false, false)]
    local procedure PurchPost_S4L_OnBeforePostVendorEntry_AfterSetDetailedVendorEntries(var MakeDetailedVendorEntries: Boolean)
    begin
        MakeDetailedVendorEntries := false; //JM170627
    end;
    /*
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostInvPostBuffer', '', false, false)]
        local procedure PurchPost_OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer"; var PurchHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; CommitIsSupressed: Boolean)
        var
            recDocumentLine: Record "Purchase Line";
            LFA: Record "Fixed Asset";
        begin
            //if recDocumentLine.Get(PurchHeader."Document Type", PurchHeader."No.", InvoicePostBuffer."Invoice Line No.") then begin
            if recDocumentLine.Get(PurchHeader."Document Type", PurchHeader."No.", InvoicePostBuffer.S4LAGetInvoiceLineNo()) then
                //DV170817
                if recDocumentLine.Type = recDocumentLine.Type::"Fixed Asset" then
                    if LFA.Get(recDocumentLine."No.") then
                        GenJnlLine."Posting Group" := LFA."FA Posting Group";

        end;
    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Purch.-Post Events", 'S4L_OnAfterPostInvPostBuffer_BeforeStart', '', false, false)]
    local procedure S4L_OnAfterPostInvPostBuffer_BeforeStart(var InvoicePostBuffer: Record "Invoice Post. Buffer"; var GenJnlLine: Record "Gen. Journal Line"; var isHandled: Boolean)
    begin
        isHandled := true;
    end;
*/
    //Cust. Entry-SetAppl.ID
    //[EventSubscriber(ObjectType::Codeunit, Codeunit::"Cust. Entry-SetAppl.ID", 'S4LNA_OnSetAppId_BeforeInsertTempCustLedgEntry', '', false, false)]

    //local procedure S4LNA_OnSetAppId_BeforeInsertTempCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; CustEntryApplID: Code[50])
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cust. Entry-SetAppl.ID", 'OnBeforeUpdateCustLedgerEntry', '', false, false)]
    //local procedure S4LNA_OnBeforeUpdateCustLedgerEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]);
    local procedure S4LNA_OnBeforeUpdateCustLedgerEntry(var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; ApplyingCustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50]; var IsHandled: Boolean; var CustEntryApplID: Code[50]); //PYAS-276
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        SaveCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        // Make Applies-to ID
        SaveCustLedgEntry := TempCustLedgerEntry;
        TempCustLedgerEntry.FindFirst();
        if FirstCustEntry."Entry No." <> TempCustLedgerEntry."Entry No." then begin
            FirstCustEntry.Get(TempCustLedgerEntry."Entry No.");
            if FirstCustEntry."Applies-to ID" <> '' then
                CustEntryApplID := ''
            else begin
                CustEntryApplID := AppliesToID;
                if CustEntryApplID = '' then begin
                    CustEntryApplID := UserId;
                    if CustEntryApplID = '' then
                        CustEntryApplID := '***';
                end;
            end;
        end;
        TempCustLedgerEntry := SaveCustLedgEntry;

        CustLedgEntry.Get(TempCustLedgerEntry."Entry No.");

        //PYAJM170704 END ELSE BEGIN
        //---
        CustLedgEntry.TestField(Open, true);
        CustLedgEntry."Applies-to ID" := CustEntryApplID;

        if CustLedgEntry."Applies-to ID" = '' then begin
            CustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
            CustLedgEntry."Accepted Payment Tolerance" := 0;
        end;
        // Set Amount to Apply
        if ((CustLedgEntry."Amount to Apply" <> 0) and (CustEntryApplID = '')) or
           (CustEntryApplID = '')
        then
            CustLedgEntry."Amount to Apply" := 0
        else
            if CustLedgEntry."Amount to Apply" = 0 then begin
                CustLedgEntry.CalcFields("Remaining Amount");
                CustLedgEntry."Amount to Apply" := CustLedgEntry."Remaining Amount"
            end;

        if CustLedgEntry."Entry No." = ApplyingCustLedgerEntry."Entry No." then
            CustLedgEntry."Applying Entry" := ApplyingCustLedgerEntry."Applying Entry";
        CustLedgEntry.Modify();
        //PYAJM170704 END; //KS150611

        //clear CustEntryApplID
        TempCustLedgerEntry := SaveCustLedgEntry;
        TempCustLedgerEntry.FindLast();
        if TempCustLedgerEntry."Entry No." = SaveCustLedgEntry."Entry No." then begin
            Clear(FirstCustEntry);
            Clear(CustEntryApplID);
        end;
        SaveCustLedgEntry := TempCustLedgerEntry;

        IsHandled := true; //PYAS-276
    end;

    //CustVendBank-Update
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustVendBank-Update", 'OnAfterUpdateCustomer', '', false, false)]
    local procedure CustVendBankUpdate_OnAfterUpdateCustomer(var Customer: Record Customer; Contact: Record Contact)
    begin
        //KS170209 NA
        Customer."Tax Area Code" := Contact."PYA Tax Area Code";
        Customer."Tax Liable" := Contact."PYA Tax Liable";
        //---
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustVendBank-Update", 'OnAfterUpdateVendor', '', false, false)]
    local procedure CustVendBankUpdate_OnAfterUpdateVendor(var Vendor: Record Vendor; Contact: Record Contact)
    begin
        //KS170209 NA
        Vendor."Tax Area Code" := Contact."PYA Tax Area Code";
        Vendor."Tax Liable" := Contact."PYA Tax Liable";
        //---
    end;

    //CustCont-Update
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustCont-Update", 'OnAfterTransferFieldsFromCustToCont', '', false, false)]
    local procedure OnAfterTransferFieldsFromCustToCont(var Contact: Record Contact; Customer: Record Customer)
    begin
        /*DV181105*/
        Contact."PYA Tax Area Code" := Customer."Tax Area Code";
        Contact."PYA Tax Liable" := Customer."Tax Liable";
        /*---*/
    end;

    //FA Check Consistency
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Check Consistency", 'S4LNA_OnCheckForError_Amount', '', false, false)]
    // local procedure S4LNA_OnCheckForError_Amount(var FALedgEntry2: Record "FA Ledger Entry"; NewAmount: decimal; var isHandled: Boolean)
    // begin
    //     //JM170719++
    //     WITH FALedgEntry2 DO BEGIN
    //         CASE "FA Posting Type" OF
    //             "FA Posting Type"::"Acquisition Cost":
    //                 isHandled := true;
    //             "FA Posting Type"::Depreciation:
    //                 isHandled := true;
    //         end;
    //     end;
    //     //JM170719--
    // end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Check Consistency", 'S4LNA_OnCheckForError_Values', '', false, false)]
    // local procedure S4LNA_OnCheckForError_Values(var FALedgEntry2: Record "FA Ledger Entry"; var DeprBook: Record "Depreciation Book"; var BookValue: Decimal; var SalvageValue: decimal; var isHandled: Boolean)
    // begin
    //     isHandled := true; //JM170719
    // end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Check Consistency", 'OnBeforeCheckForError', '', false, false)]
    local procedure S4LNA_OnBeforeCheckForError(FALedgEntry2: Record "FA Ledger Entry"; var FAJnlLine: Record "FA Journal Line"; FAPostingTypeSetup: Record "FA Posting Type Setup"; NewAmount: Decimal; BookValue: Decimal; SalvageValue: Decimal; DeprBasis: Decimal; var IsHandled: Boolean)
    begin
        //JM170719++
        case FALedgEntry2."FA Posting Type" of
            FALedgEntry2."FA Posting Type"::"Acquisition Cost":
                begin
                    IsHandled := true;
                    exit;
                end;
            FALedgEntry2."FA Posting Type"::Depreciation:
                begin
                    IsHandled := true;
                    exit;
                end;
        end;
        //JM170719--
        case FALedgEntry2."FA Posting Type" of
            FALedgEntry2."FA Posting Type"::"Acquisition Cost":
                if NewAmount < 0 then
                    CreatePostingTypeError(FAJnlLine, FALedgEntry2, NewAmount);
            FALedgEntry2."FA Posting Type"::Depreciation,
  FALedgEntry2."FA Posting Type"::"Salvage Value":
                if NewAmount > 0 then
                    CreatePostingTypeError(FAJnlLine, FALedgEntry2, NewAmount);
            FALedgEntry2."FA Posting Type"::"Write-Down",
            FALedgEntry2."FA Posting Type"::Appreciation,
            FALedgEntry2."FA Posting Type"::"Custom 1",
            FALedgEntry2."FA Posting Type"::"Custom 2":
                begin
                    if NewAmount > 0 then
                        if FAPostingTypeSetup.Sign = FAPostingTypeSetup.Sign::Credit then
                            CreatePostingTypeError(FAJnlLine, FALedgEntry2, NewAmount);
                    if NewAmount < 0 then
                        if FAPostingTypeSetup.Sign = FAPostingTypeSetup.Sign::Debit then
                            CreatePostingTypeError(FAJnlLine, FALedgEntry2, NewAmount);
                end;
        end;

        IsHandled := true; //JM170719
    end;

    local procedure CreatePostingTypeError(FAJnlLine: Record "FA Journal Line"; FALedgEntry2: Record "FA Ledger Entry"; NewAmount: Decimal)
    var
        AccumText: Text[30];
        Text003: Label 'Accumulated';
        Text004: Label '%2%3 must not be positive on %4 for %1.';
        Text005: Label '%2%3 must not be negative on %4 for %1.';
    begin
        FAJnlLine."FA Posting Type" := "FA Journal Line FA Posting Type".FromInteger(FALedgEntry2.ConvertPostingType());
        if FAJnlLine."FA Posting Type" = FAJnlLine."FA Posting Type"::Depreciation then
            AccumText := StrSubstNo('%1 %2', Text003, '');
        if NewAmount > 0 then
            Error(Text004, FAName(FALedgEntry2), AccumText, FAJnlLine."FA Posting Type", FALedgEntry2."FA Posting Date");
        if NewAmount < 0 then
            Error(Text005, FAName(FALedgEntry2), AccumText, FAJnlLine."FA Posting Type", FALedgEntry2."FA Posting Date");
    end;

    local procedure FAName(FALedgEntry: Record "FA Ledger Entry"): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
        FA: Record "Fixed Asset";
    begin
        FA.Get(FALedgEntry."FA No.");
        exit(DepreciationCalc.FAName(FA, FALedgEntry."Depreciation Book Code"));
    end;

    //VendCont-Update
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendCont-Update", 'OnAfterTransferFieldsFromVendToCont', '', false, false)]
    local procedure OnAfterTransferFieldsFromVendToCont(var Contact: Record Contact; Vendor: Record Vendor)
    begin
        Contact."PYA Tax Area Code" := Vendor."Tax Area Code"; //TG190912 - not working with transferfields because field number not same
    end;

    //Depreciation Calculation
    //TODO NA >>
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"Depreciation Calculation", 'S4LNA_OnGetFirstDeprDate_BeforeExit', '', false, false)]
    // local procedure S4LNA_OnGetFirstDeprDate_BeforeExit(FANo: Code[20]; DeprBookCode: Code[10]; var FALedgEntry: Record "FA Ledger Entry"; var LocalDate: Date)
    // var
    //     FAdep: Record "FA Depreciation Book";
    // begin
    //     /*DV190404*/
    //     IF FAdep.GET(FANo, DeprBookCode) THEN;
    //     /*---*/
    //     /*DV190404*/
    //     IF (DATE2DMY(LocalDate, 2) = DATE2DMY(FAdep."Depreciation Starting Date", 2)) AND
    //        (DATE2DMY(LocalDate, 3) = DATE2DMY(FAdep."Depreciation Starting Date", 3)) THEN
    //         LocalDate := FAdep."Depreciation Starting Date";
    //     /*---*/
    // end;
    //TODO NA <<

    //Contract Balances Run
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Run Calc. Contract Bal.", 'S4LNA_OnRun_FillGenRepBuf', '', false, false)]
    local procedure S4LNA_OnRun_FillGenRepBuf(var Rec: Record "Job Queue Entry"; var GenReportBuffer: Record "S4LA Gen.Report Buffer"; var isHandled: Boolean)
    begin
        isHandled := true; /*TG200828*/ // we don't need to fill Gen.Report buffer when running Contract balances
    end;

    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Run Calc. Contract Bal.", 'S4LNA_OnfnCalcContract_BeforeExit', '', false, false)]
    // local procedure S4LNA_OnfnCalcContract_BeforeExit(BreakOnError_Para: Boolean; IncludeAllStatuses_Para: Boolean)
    // var
    //     cdCalcContrBal: Codeunit "S4LNA Contract Balances Calc";
    // begin
    //     cdCalcContrBal.CalcCustAging(); //DV180124
    // end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Run Calc. Contract Bal.", 'S4LNA_OnFillGenRepBuf_InitGenRepBuf_FromContract', '', false, false)]
    local procedure S4LNA_OnFillGenRepBuf_InitGenRepBuf_FromContract(var GenRepBuf: Record "S4LA Gen.Report Buffer"; var Contr: Record "S4LA Contract")
    begin
        GenRepBuf.Funder := Contr.Funder;
        GenRepBuf.Funded := Contr.Funded;
        GenRepBuf."Date Funded" := Contr."Date Funded";
        GenRepBuf."Funding Batch No." := Contr."Funding Batch No.";
        GenRepBuf."Book Value (Funding)" := Contr."Book Value (Funding)";
        GenRepBuf."Sales Price (Funding)" := Contr."Sales Price (Funding)";
        GenRepBuf."Funder Ref. No." := Contr."Funder Ref. No.";
    end;

    //Status Mgt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Status Mgt", 'S4LNA_OnScheduleGateChange_EffectiveDate', '', false, false)]
    local procedure S4LNA_OnScheduleGateChange_EffectiveDate(var Schedule: Record "S4LA Schedule"; NewStatus: Record "S4LA Status"; var EffectiveDate: Date)
    var
        GLSetup: Record "General Ledger Setup";
        LeaseSetup: Record "S4LA Leasing Setup";
    begin
        /*DV190502*/
        GLSetup.Get();
        LeaseSetup.Get();
        if Schedule."S4LNA Migration Flag" and (NewStatus.Code = LeaseSetup."Status - Active") and (EffectiveDate = 0D) then
            EffectiveDate := GLSetup."S4LA Data Migration Date";
        /*---*/
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Status Mgt", 'S4LNA_OnInsertStatusChangeHistory_EffectiveDate', '', false, false)]
    local procedure S4LNA_OnInsertStatusChangeHistory_EffectiveDate(RecRef: RecordRef; NewStatus: Record "S4LA Status"; var EffectiveDate: Date)
    var
        recStatus: Record "S4LA Status";
    begin
        /*DV180417*/
        //IF EffectiveDate = 0D THEN
        //  EffectiveDate := WORKDATE;
        if recStatus.Get(NewStatus.Code) then
            case recStatus."S4LNA Update Date Type" of
                recStatus."S4LNA Update Date Type"::" ":
                    Clear(EffectiveDate);
                recStatus."S4LNA Update Date Type"::"Posting Date":
                    if EffectiveDate = 0D then
                        EffectiveDate := WorkDate();
            end;
        /*---*/
    end;

    //DD Mgt.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Suggest DD Mgt.", 'OnCode_CheckExceptions', '', false, false)]
    local procedure OnCode_CheckExceptions(var Contr: Record "S4LA Contract"; var DDSched: Record "S4LA DD Schedule"; var doExit: Boolean; var isHandled: Boolean)
    var
        FinProduct: Record "S4LA Financial Product";
        ContrBal: Record "S4LA Contract Balance";
        LeasingSetup: Record "S4LA Leasing Setup";
    begin
        isHandled := true;
        FinProduct.Get(Contr."Financial Product");
        LeasingSetup.Get();

        if DDSched.Status <> DDSched.Status::" " then
            doExit := true;

        //--- If Contract is not active (e.g. Closed) - don't collect
        if (Contr."Contract No." <> '') and (Contr.Status <> Contr.Status::Contract) then
            doExit := true;

        if (Contr."Contract No." <> '') and (Contr."Status Code" <> LeasingSetup."Status - Active") then
            doExit := true;

        if doExit then
            exit;

        //--- If there is not receivable (e.g.Contract paid in full, even if not Closed yet) - Don't collect
        Codeunit.Run(Codeunit::"S4LA Calc. Contract Balance", Contr); //Recalculate balances
        if (DDSched.Type = DDSched.Type::"Scheduled Instalment") and (Contr."Contract No." <> '') and (Contr."Status Code" = LeasingSetup."Status - Active") then begin
            ContrBal.Get(Contr."Contract No.");
            if ContrBal."Paid in Full" then
                doExit := true;

            //DV180502
            //  if (ContrBal.NetReceivable + ContrBal.CurrentReceivable) <= 0 then
            //      if FinProduct."Accounting Group" <> FinProduct."Accounting Group"::"Lease Inventory" then//EN200414
            //          exit;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Suggest DD Mgt.", 'OnCode_AmountToCollect', '', false, false)]
    local procedure OnCode_AmountToCollect(var Contr: Record "S4LA Contract"; var DDSched: Record "S4LA DD Schedule"; var AmtToCollect: Decimal; var isHandled: Boolean)
    var
        FinProduct: Record "S4LA Financial Product";
        RemainingAmount: Decimal;
        CLE: Record "Cust. Ledger Entry";
    begin
        FinProduct.Get(Contr."Financial Product");

        AmtToCollect := DDSched.Amount;
        if DDSched.Type = DDSched.Type::"Scheduled Instalment" then //EN190522
            if DDSched."Contract No." <> '' then begin
                //DV180502ContrBal.Get(Contr."Contract No.");
                //>>EN180809
                //IF (ContrBal.NetReceivable + ContrBal.CurrentReceivable) < AmtToCollect THEN
                //DV180502if (ContrBal.NetReceivable + ContrBal.CurrentReceivable + ContrBal.UnearnedInterest) < AmtToCollect then
                //DV180502    if FinProduct."Accounting Group" <> FinProduct."Accounting Group"::"Lease Inventory" then//EN200414
                //AmtToCollect := ContrBal.NetReceivable + ContrBal.CurrentReceivable; //Decrease amount if Oustanding Amount is less
                //DV180502        AmtToCollect := ContrBal.NetReceivable + ContrBal.CurrentReceivable + +ContrBal.UnearnedInterest; //Decrease amount if Oustanding Amount is less
                //<<EN180809
            end
            else begin
                RemainingAmount := 0;
                if CLE.FindSet() then
                    repeat
                        CLE.CalcFields("Remaining Amount");
                        RemainingAmount += CLE."Remaining Amount";
                    until CLE.Next() = 0;
                if RemainingAmount < AmtToCollect then
                    AmtToCollect := RemainingAmount;
            end;
        //>>EN160322
        // CCY IF LeasingSetup."Direct Debit Fee" <> 0 THEN
        //    AmtToCollect += LeasingSetup."Direct Debit Fee";
        if FinProduct."Direct Debit Fee" <> 0 then            // CCY
            AmtToCollect += FinProduct."Direct Debit Fee";    // CCY
                                                              //<<EN160322
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Suggest DD Mgt.", 'OnCode_AfterJnlInit', '', false, false)]
    local procedure OnCode_AfterJnlInit(var Contr: Record "S4LA Contract"; var Jnl: Record "Gen. Journal Line")
    begin
        //SM180228 - Start
        Jnl."S4LNA Bank Name" := Contr."DD Bank Name";
        //---
    end;

    //Asset Mgt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Asset Mgt", 'OnCreateAssetFromPO_AfterFAInit', '', false, false)]
    local procedure OnCreateAssetFromPO_AfterFAInit(var PurchaseHeader: Record "Purchase Header"; var FA: Record "Fixed Asset"; var Status: Record "S4LA Status")
    var
        Ltest001: Label 'Vin already exists for Asset %1';
        FA2: Record "Fixed Asset";
        Text001: Label 'Create New Asset ?';
    begin
        //PYAS-256
        if GuiAllowed then
            if not Confirm(Text001 +
                         '\' + FA.FieldCaption(Description) + ': ' + PurchaseHeader."Posting Description"
                       , true) then
                exit;
        //--//

        /*DV170619*/
        FA2.SetRange("PYA VIN", PurchaseHeader."NA VIN");
        /*TG190909*/
        if (FA2.FindFirst()) and (PurchaseHeader."NA VIN" <> '') then
            //IF FA.FINDFIRST THEN
            /*---*/
            Error(Ltest001, FA."No.");
        //ELSE //TG190909
        //    CLEAR(FA); //TG190909
        /*---*/

        Status.Reset();
        Status.SetRange("Target Table ID", Database::"Fixed Asset");
        /*TG200227*/
        case PurchaseHeader."S4LNA Purchase for" of
            PurchaseHeader."S4LNA Purchase for"::Stock:
                Status.SetRange("Trigger Option No.", FA."S4LA Asset Status Trigger"::"S4LNA Stock".AsInteger());
            PurchaseHeader."S4LNA Purchase for"::Lease:
                Status.SetRange("Trigger Option No.", FA."S4LA Asset Status Trigger"::"Lease Asset".AsInteger());
            else
                Status.SetRange("Trigger Option No.", FA."S4LA Asset Status Trigger"::"Internal Fixed Asset".AsInteger());
        end;
        /*---*/
        if not Status.FindFirst() then
            Clear(Status)
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Asset Mgt", 'OnCreateAssetFromPO_BeforeFAInsert', '', false, false)]
    local procedure OnCreateAssetFromPO_BeforeFAInsert(var PurchaseHeader: Record "Purchase Header"; var FA: Record "Fixed Asset")
    var
        LeasingSetup: Record "S4LA Leasing Setup";
        AssetModel: Record "S4LA Asset Model";
        fxAsset: Record "Fixed Asset";
        Contract: Record "S4LA Contract";
    begin

        LeasingSetup.Get();
        FA."FA Class Code" := PurchaseHeader."NA FA Class Code";//DV170719
        if FA."FA Class Code" = '' then//DV170719
            FA."FA Class Code" := LeasingSetup."Default Pre-Contract FA Class";
        //FA."FA Subclass Code":= LeasingSetup."Default Pre-Contract FA Class";

        FA."PYA Model Year" := PurchaseHeader."NA Model Year";
        FA."PYA Asset Model" := PurchaseHeader."NA S#Car Model";
        FA."PYA Asset Brand" := PurchaseHeader."NA S#Car Make Code";
        //FA."PYA Asset New / Used" := PurchaseHeader."S4LNA Asset New / Used";
        FA."PYA VIN" := PurchaseHeader."NA VIN";
        FA."PYA Color Of Vehicle" := PurchaseHeader."NA Color Of Vehicle";
        FA."PYA Starting Mileage (km)" := PurchaseHeader."NA Starting Mileage (km)";
        FA."pyA Interior Color" := PurchaseHeader."NA S#Color Of Interior";

        //{BA210324}
        // FA."No of Cylinders" := PurchaseHeader."No of CylinderS";
        FA."PYA Trim" := PurchaseHeader."NA Trim";
        if (PurchaseHeader."NA S#Car Model" <> '') and AssetModel.Get(PurchaseHeader."NA S#Car Model") then begin
            //FA."NA Asset Type" := AssetModel."Asset Type";
            //FA."S4L Asset Group" := AssetModel."Asset Group";
            //FA."S4LA Asset Category" := AssetModel."Asset Category";
        end;
        //---//

        //BA210622
        if Contract.Get(PurchaseHeader."PYA Contract No") then
            FA."S4L Fin. Product Code" := Contract."Financial Product";

        // BA210714
        onBeforeCreateFANo(FA);

        if fxAsset.Get(FA."No.") then //BA210622 -- the publisher event in Soft4-Leasing is placed before the FA.Insert hence gives error
            PurchaseHeader.Validate("NA Asset No.", FA."No.") //DV170619
        else
            PurchaseHeader."S4LNA Asset No." := FA."No."; //BA210622
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Asset Mgt", 'OnUpdateFAfromAsset_BeforeFAModify', '', false, false)]
    local procedure OnUpdateFAfromAsset_BeforeFAModify(var FA: Record "Fixed Asset"; xFA: Record "Fixed Asset"; var Asset: Record "S4LA Asset")
    var
        Contr: Record "S4LA Contract";
        ContRec: Record Contact;
        Sched: Record "S4LA Schedule";
    begin
        Contr.Get(Asset."Contract No.");
        Contr.GetNewestSchedule(Sched);

        if Asset."Asset Description" <> '' then begin//DV170619
            FA.Description := CopyStr(Asset."Asset Description", 1, MaxStrLen(FA.Description));
            //FA."S4LA Asset Description" := CopyStr(Asset."Asset Description", 1, MaxStrLen(FA."S4LA Asset Description"));
        end;

        FA."PYA Asset Brand" := xFA."PYA Asset Brand";
        if (Asset."Asset Brand" <> '') and (FA."PYA Asset Brand" = '') then//DV190710
            FA."PYA Asset Brand" := Asset."Asset Brand";
        //FA."S4LA Asset Group" := xFA."S4LA Asset Group";
        //if (Asset."Asset Group" <> '') and (FA."S4LA Asset Group" = '') then//DV190710
        //  FA."S4LA Asset Group" := Asset."Asset Group";
        //FA."S4LA Asset Category" := xFA."S4LA Asset Category";
        //if (Asset."Asset Category" <> '') and (FA."S4LA Asset Category" = '') then//DV190710
        //FA."S4LA Asset Category" := Asset."Asset Category";
        FA."PYA Asset Model" := xFA."PYA Asset Model";
        if (Asset.Model <> '') and (FA."PYA Asset Model" = '') then//DV190710
            FA."PYA Asset Model" := Asset.Model;
        FA."PYA Model Year" := xFA."PYA Model Year";
        if (Asset."Model Year" <> 0) and (FA."PYA Model Year" = 0) then//DV190710
            FA."PYA Model Year" := Asset."Model Year";
        FA."PYA VIN" := xFA."PYA VIN";
        if (Asset.VIN <> '') and (FA."PYA VIN" = '') then//DV190710
            FA."PYA VIN" := Asset.VIN;
        //FA."S4LA Engine Number" := xFA."S4LA Engine Number";
        //if (Asset."Engine No." <> '') and (FA."S4LA Engine Number" = '') then//DV190710
        //  FA."S4LA Engine Number" := Asset."Engine No.";
        //FA."S4LA Asset Serial No." := xFA."S4LA Asset Serial No.";
        //if (Asset."Serial No." <> '') and (FA."S4LA Asset Serial No." = '') then//DV190710
        //  FA."S4LA Asset Serial No." := Asset."Serial No.";
        //FA."S4LA Licence Plate No." := xFA."S4LA Licence Plate No.";
        //if (Asset."Licence Plate No." <> '') and (FA."S4LA Licence Plate No." = '') then//DV190710
        //FA."S4LA Licence Plate No." := Asset."Licence Plate No.";  //AY150805
        //FA."S4LA Total Resource (usage)" := xFA."S4LA Total Resource (usage)";
        //if (Asset."Total Resource (usage)" <> 0) and (FA."S4LA Total Resource (usage)" = 0) then//DV190710
        //  FA."S4LA Total Resource (usage)" := Asset."Total Resource (usage)";      //>>NK150113
        //FA."S4LNA Asset Location" := xFA."S4LNA Asset Location";
        //if (Asset."Asset Location" <> '') and (FA."S4LNA Asset Location" = '') then
        //  FA."S4LNA Asset Location" := Asset."Asset Location";
        //FA."FA Class Code" := xFA."FA Class Code";
        //if (Asset."S4LNA FA Class Code" <> '') and (FA."FA Class Code" = '') then//DV190710
        //  FA."FA Class Code" := Asset."S4LNA FA Class Code";
        FA."Vendor No." := xFA."Vendor No.";
        if (Asset."Supplier No." <> '') and (FA."Vendor No." = '') then
            FA."Vendor No." := Asset."Supplier No.";

        /*TG190413*/
        Contr.S4LNAUpdateAssetDim(Asset."Asset No.");
        Contr.Modify();
        /*---*/
        /*DV190514*/
        FA."S4LA Contract Status" := Contr.Status;
        FA."S4LA Schedule Status Code" := Sched."Status Code";
        /*---*/
        if ContRec.Get(Contr."Customer No.") then//DV190424
            FA."S4LA Customer Name" := ContRec.Name;
    end;

    //Applicant Mgt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnUpdContactNoInApplicationTables_Begin', '', false, false)]
    local procedure OnUpdContactNoInApplicationTables_Begin(var Applicant: Record "S4LA Applicant"; var Contract: Record "S4LA Contract")
    begin
        if Applicant."Role Type" = Applicant."Role Type"::"Primary Applicant" then begin
            //SM180409 - Start
            Commit();
            Contract.Find('=');
            //---
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnUpdContrFromContact_BeforeModify', '', false, false)]
    local procedure OnUpdContrFromContact_BeforeModify(var Contract: Record "S4LA Contract"; var Contact: Record Contact)
    begin
        //KS170209 NA
        Contract."PYA Tax Area Code" := Contact."PYA Tax Area Code";
        Contract."PYA Tax Liable" := Contact."PYA Tax Liable";
        //BA210618
        Contract."S4LNA County 2" := Contact."S4LNA County 2";

        //---
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnUpdApplicantFromContact_BeforeModify', '', false, false)]
    local procedure OnUpdApplicantFromContact_BeforeModify(var Applicant: Record "S4LA Applicant"; var Contact: Record Contact)
    begin
        //KS170209 NA
        Applicant."S4LNA Tax Area Code" := Contact."PYA Tax Area Code";
        Applicant."S4LNA Tax Liable" := Contact."PYA Tax Liable";
        //---
        //TG210120 field missing
        Applicant."S4LNA City" := Contact.City;
        //---
        //BA210618
        Applicant."S4LNA County 2" := Contact."S4LNA County 2";

        ///
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnUpdContactFromApplicant_BeforeModify', '', false, false)]
    local procedure OnUpdContactFromApplicant_BeforeModify(var Contact: Record Contact; var Applicant: Record "S4LA Applicant")
    begin
        //KS170209 NA
        Contact."PYA Tax Area Code" := Applicant."S4LNA Tax Area Code";
        Contact."PYA Tax Liable" := Applicant."S4LNA Tax Liable";
        //---
        //BA210618
        Contact."S4LNA County 2" := Applicant."S4LNA County 2";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnUpdPrimeApplFromContr_BeforeModify', '', false, false)]
    local procedure OnUpdPrimeApplFromContr_BeforeModify(var Applicant: Record "S4LA Applicant"; var Contract: Record "S4LA Contract")
    begin
        //KS170209 NA
        Applicant."S4LNA Tax Area Code" := Contract."S4LNA Tax Area Code";
        Applicant."S4LNA Tax Liable" := Contract."S4LNA Tax Liable";
        //---
        //TG210120 - missing field
        Applicant."S4LNA City" := Contract.City;
        //---
        //BA200618
        Applicant."S4LNA County 2" := Contract."S4LNA County 2";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnUpdContrFromPrimeAppl_BeforeModify', '', false, false)]
    local procedure OnUpdContrFromPrimeAppl_BeforeModify(var Contract: Record "S4LA Contract"; var Applicant: Record "S4LA Applicant")
    begin
        //KS170209 NA
        Contract."S4LNA Tax Area Code" := Applicant."S4LNA Tax Area Code";
        Contract."S4LNA Tax Liable" := Applicant."S4LNA Tax Liable";
        //---
        //BA210618
        Contract."S4LNA County 2" := Applicant."S4LNA County 2";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnFindCreateUpdateAddressFromApplicant_AfterContAltAddressModify', '', false, false)]
    local procedure OnFindCreateUpdateAddressFromApplicant_AfterContAltAddressModify(var Applicant: Record "S4LA Applicant"; var ContactAltAddress: Record "Contact Alt. Address"; UpdateContract: Boolean)
    var
        I: Integer;
        I2: Integer;
        Num: Integer;
    begin

        /*DV171114*/
        if ContactAltAddress.Address <> '' then begin
            I := StrPos(ContactAltAddress.Address, '-');//DV181102
            I2 := StrPos(ContactAltAddress.Address, ' ');
            if (I2 <> 0) and ((I2 < I) or (I = 0)) then //DV181109
                I := I2;
            if I <> 0 then
                if Evaluate(Num, CopyStr(ContactAltAddress.Address, 1, 1)) then begin//if 1st char is a number then split
                    ContactAltAddress."S4LA Street Number" := CopyStr(ContactAltAddress.Address, 1, I);
                    ContactAltAddress."S4LA Street Name" := CopyStr(ContactAltAddress.Address, I + 1);
                end;
        end;
        /*---8/
        ContactAltAddress.MODIFY();

        /*DV171123*/
        ContactAltAddress."S4LA Applicant Line No." := 0;
        ContactAltAddress.Code := '1';
        ContactAltAddress."PYA Contract No" := '';
        //BA210618
        ContactAltAddress."S4LNA County 2" := Applicant."S4LNA County 2";

        //SM180509 - Start
        //IF NOT ContactAltAddress.INSERT(TRUE) THEN
        //  ContactAltAddress.MODIFY(TRUE);
        /*---*/
        /*TG191017*/
        if not ContactAltAddress.Insert(UpdateContract) then
            ContactAltAddress.Modify(UpdateContract);
        /*---*/
    end;

    //Check Submission Rules
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnCheck_ContractField', '', false, false)]
    local procedure OnCheck_ContractField(Contract: Record "S4LA Contract"; FldNo: Integer; var isHandled: Boolean)
    begin
        //IF Contr."Originator Type" = Contr."Originator Type":: " " THEN
        //  WarningLog.Add(STRSUBSTNO(Text001, Contr.FIELDCAPTION(Contr."Originator Type"), Contr."Contract No."), 3);
        isHandled := false;
        if FldNo = Contract.FieldNo("Originator Type") then
            isHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnCheck_ApplicantField', '', false, false)]
    local procedure OnCheck_ApplicantField(Applicant: Record "S4LA Applicant"; FldNo: Integer; var isHandled: Boolean)
    begin
        //IF (Applicant.ABN = '') THEN
        //   WarningLog.Add(STRSUBSTNO(Text530,Applicant.FIELDCAPTION(ABN),Applicant.Name),3);
        isHandled := false;
        if FldNo = Applicant.FieldNo("Registration No.") then
            isHandled := true;
    end;

    //Check Compliance Validations
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Compliance Rules", 'OnCheck_Disbursement', '', false, false)]
    local procedure OnCheck_Disbursement(var Contract: Record "S4LA Contract"; var isHandled: Boolean)
    begin
        isHandled := true;           /*PYA*/
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Compliance Rules", 'OnCheck_BeforeExit', '', false, false)]
    local procedure OnCheck_BeforeExit(var Contract: Record "S4LA Contract")
    var
        LeasingSetup: Record "S4LA Leasing Setup";
        WarningLog: Record "S4LA Validation Message";
        Text518: Label '%1 is not defined for Contract no. %2.';
        Text514: Label 'Missing %1 for Asset %2.';
        Asset: Record "S4LA Asset";
        FinancialProduct: Record "S4LA Financial Product";
        FA: Record "Fixed Asset";
    begin
        LeasingSetup.Get();
        FinancialProduct.Get(Contract."Financial Product");

        if (Contract."Payment Method Code" = LeasingSetup."Payment Method Code for DD") then
            //JM170725++
            if Contract."S4LNA DD Start Date" = 0D then
                WarningLog.Add(StrSubstNo(Text518, Contract.FieldCaption("S4LNA DD Start Date"), Contract."Contract No."), 2);
        //JM170725--

        Asset.SetRange(Asset."Contract No.", Contract."Contract No.");
        if Asset.FindSet() then
            repeat

                if FinancialProduct."Fin. Product Type" <> FinancialProduct."Fin. Product Type"::Loan then     // SK180409

                    /*DV170726*/
                    if not FA.Get(Asset."Asset No.") then
                        Clear(FA)
                    else
                        if (FA."FA Posting Group" = '') then
                            WarningLog.Add(StrSubstNo(Text514, FA.FieldCaption("FA Posting Group"), Asset."Asset Description"), 3);
            /*---*/
            // SK180409
            until Asset.Next() = 0;
    end;

    //Address Mgt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Address Mgt", 'OnfnFormatAddr_Begin', '', false, false)]
    local procedure OnfnFormatAddr_Begin(var Addr: array[2] of Text; PropertyName: Text[100]; SuiteNumber: Code[10]; UnitNumber: Code[10]; StreetNumber: Code[10]; StreetName: Text[50]; StreetTypeCode: Code[10]; POBox: Text[30]; var isHandled: Boolean)
    var
        POBoxTxt: Text;
        SubUnittype: Record "S4LA Sub Unit Type";
        UnitTxt: Text;
        SuiteTxt: Text;
    begin

        Clear(Addr);

        //StreetName := CommonFn.NormalCase(StreetName); //KS151023

        //---------- PO, Suite, Unit NUMBERS - if starts with digit then add auto prefix
        POBoxTxt := POBox;
        if (POBoxTxt[1] >= '0') and (POBoxTxt[1] <= '9') then
            POBoxTxt := 'PO Box ' + POBoxTxt;

        if SubUnittype.Get(UnitNumber) then
            UnitTxt := SubUnittype.Description
        else
            UnitTxt := UnitNumber;
        if (UnitTxt[1] >= '0') and (UnitTxt[1] <= '9') then
            UnitTxt := 'Unit ' + UnitTxt;

        SuiteTxt := SuiteNumber;

        //IF ((StreetNumber <>'') AND (SuiteTxt <> ''))THEN
        //   SuiteTxt += ' -';

        //-----------Line 1. Property OR Suite+Unit OR P.O.box (logically, would be just one of those three. Or none.)
        if PropertyName <> '' then Addr[1] += ' ' + PropertyName + ' ';
        if UnitTxt <> '' then Addr[1] += UnitTxt + ' ';
        //if SuiteTxt <> '' then Addr[1] += SuiteTxt + ' ';
        if POBoxTxt <> '' then Addr[1] += POBoxTxt + ' ';
        Addr[1] := DelChr(Addr[1], '<>');

        //-----------Line 2. Street address
        if StreetNumber <> '' then Addr[2] += StreetNumber + ' ';
        if StreetName <> '' then Addr[2] += StreetName + ' ';

        /*DV190225*/
        if SuiteTxt <> '' then
            Addr[2] := SuiteTxt + '-' + Addr[2];
        /*---*/
        /*
        if StreetTypeCode <> '' then
            if StreetType.Get(StreetTypeCode) then
                if StreetType.Description <> '' then
                    Addr[2] += StreetType.Description + ' ';
        */
        Addr[2] := DelChr(Addr[2], '<>');

        CompressArray(Addr);
        isHandled := true;
    end;

    //Invoicing on Termination
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Invoicing on Termination", 'OnCode_Begin', '', false, false)]
    local procedure OnCode_Begin(var Contract: Record "S4LA Contract"; var Sched: Record "S4LA Schedule"; var VATOnPrincipal: Decimal; var VATOnInterest: Decimal)
    var
        cdLeasingContMgt: Codeunit "S4LA Contract Mgt";
    begin
        cdLeasingContMgt.GetVatPercentsSchedule2(Sched, VATOnPrincipal, VATOnInterest);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Invoicing on Termination", 'OnInvoiceETF_BeforePostRevenue', '', false, false)]
    local procedure OnInvoiceETF_BeforePostRevenue(var Contract: Record "S4LA Contract"; var Schedule: Record "S4LA Schedule"; var Jnl: Record "Gen. Journal Line")
    begin
        Jnl."VAT Calculation Type" := Jnl."VAT Calculation Type"::"Sales Tax";//DV170616
    end;

    //WF Mgt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA WF Mgt", 'OnUpdateWorkflowOnNextStep_BeforeAction', '', false, false)]
    local procedure OnUpdateWorkflowOnNextStep_BeforeAction(var WF: Record "S4LA WF Task"; ToStepCode: Code[20])
    var
        Outbox: Record "S4LA Document";
        DocOutboxMgt: Codeunit "S4LA Doc. Outbox Mgt";
        DocumentSetup: Record "S4LA Document Selection";
        UserSetup: Record "User Setup";
        Approver: Record "User Setup";
        Sub: Record "User Setup";
        Contract: Record "S4LA Contract";
        TemplateStepNext: Record "S4LA WF Template Step";
    begin
        TemplateStepNext.Get(WF."WF Template", ToStepCode);
        /*DV180112,15*/
        Contract.Get(WF."Contract No.");
        if (Contract.Status = Contract.Status::Quote) and
           (StrPos(UpperCase(TemplateStepNext."Task Description"), UpperCase('Credit Decision')) > 0) then begin
            DocumentSetup.Reset();
            DocumentSetup.SetRange("Financial Product", Contract."Financial Product");
            DocumentSetup.FindFirst();
            Outbox.Reset();
            Outbox.SetRange("Key Code 1", WF."Contract No.");
            Outbox.SetRange("Template Code", DocumentSetup."Approval Letter Template");
            if not Outbox.FindFirst() then
                Contract.CreateDocApprovalLetter(false);

            Outbox.SetRange("Key Code 1", WF."Contract No.");
            Outbox.SetRange("Template Code", DocumentSetup."Approval Letter Template");
            if Outbox.FindFirst() then begin
                Outbox."E-mail" := '';//DV180220
                UserSetup.Get(UserId);
                if UserSetup."Approver ID" <> '' then
                    if not Approver.Get(UserSetup."Approver ID") then
                        Clear(Approver);
                if UserSetup.Substitute <> '' then
                    if not Sub.Get(UserSetup.Substitute) then
                        Clear(Sub);
                Outbox.Prepared := false;
                Outbox."Doc Send-to" := Outbox."Doc Send-to"::"S4LNA Approver";
                if Approver."E-Mail" <> '' then
                    Outbox."E-mail" := Approver."E-Mail";
                if (Sub."E-Mail" <> '') and (Sub."E-Mail" <> Approver."E-Mail") then
                    Outbox."E-mail" += ';' + Sub."E-Mail";
                Outbox.Modify();
                DocOutboxMgt.SendEmails(Outbox, Enum::"S4LA D.Outb. SendEmails Caller"::"S4LNA WorkflowOnNextStep");
            end;
        end;
        /*---*/
    end;

    //S4LA Common Functions
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Common Functions", 'OnFormatBSB_Begin', '', false, false)]
    local procedure OnFormatBSB_Begin(InBSB: Text; var OutBSB: Text; var isHandled: Boolean)
    begin
        OutBSB := InBSB; //KS170210 NA disable check and format - exit with input string
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Common Functions", 'OnCheckBSB_Begin', '', false, false)]
    local procedure OnCheckBSB_Begin(BSB: Text; var isOK: Boolean; var isHandled: Boolean)
    begin
        isOK := true; //KS170210 NA disable check
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Common Functions", 'OnBeforeIsValidRegNo', '', false, false)]
    local procedure S4LCommonFunctions_OnBeforeIsValidRegNo_TestRegNoNA(RegNo: Code[20]; var isOK: boolean; var IsHandled: boolean)
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        CompInfo: Record "Company Information";
    begin
        IsHandled := true;
        if not VATRegistrationNoFormat.Test(RegNo, CompInfo."Country/Region Code", '', Database::Contact) then;
        isOK := true;
    end;

    //Bank Statement Mgt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Bank Statement Mgt", 'OnSearchActiveContractFromText_FillStrArr', '', false, false)]
    local procedure OnSearchActiveContractFromTextAUS_FillStrArr(var GenJournalLine: Record "Gen. Journal Line"; var StrArr: array[10] of Text; var isHandled: Boolean)
    var
        CompanyInformation: Record "Company Information";
        TempStr: Text;
        i: Integer;
    begin
        TempStr := GenJournalLine."S4LA Payment details";

        CompanyInformation.Get();

        if CompanyInformation."Country/Region Code" = 'AU' then begin
        end else begin
            for i := 1 to 10 do
                if TempStr <> '' then begin
                    TempStr := DelChr(TempStr, '<>');
                    //JM170723++
                    TempStr := DelChr(TempStr, '=', '(');
                    TempStr := DelChr(TempStr, '=', ')');
                    //JM170723--
                    if StrPos(TempStr, ';') > StrPos(TempStr, ' ') then begin
                        if StrPos(TempStr, ' ') = 0 then begin
                            StrArr[i] := CopyStr(TempStr, 1, StrPos(TempStr, ';'));
                            TempStr := CopyStr(TempStr, StrPos(TempStr, ';') + 1);
                        end else begin
                            StrArr[i] := CopyStr(TempStr, 1, StrPos(TempStr, ' '));
                            TempStr := CopyStr(TempStr, StrPos(TempStr, ' ') + 1);
                        end;
                    end else
                        if StrPos(TempStr, ';') < StrPos(TempStr, ' ') then begin
                            if StrPos(TempStr, ';') = 0 then begin
                                StrArr[i] := CopyStr(TempStr, 1, StrPos(TempStr, ' '));
                                TempStr := CopyStr(TempStr, StrPos(TempStr, ' ') + 1);
                            end else begin
                                StrArr[i] := CopyStr(TempStr, 1, StrPos(TempStr, ';'));
                                TempStr := CopyStr(TempStr, StrPos(TempStr, ';') + 1);
                            end;
                        end else begin
                            StrArr[i] := TempStr;
                            TempStr := '';
                        end;
                end;
            isHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Bank Statement Mgt", 'OnSearchActiveContractFromText_MatchGenJnlLine', '', false, false)]
    local procedure OnSearchActiveContractFromTextAUS_MatchGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var Contract: Record "S4LA Contract"; var Schedule: Record "S4LA Schedule"; var doExit: Boolean; var isHandled: Boolean)
    var
        ScheduleLine: Record "S4LA Schedule Line";
        decInstAmount: Decimal;
    begin
        ScheduleLine.Reset();
        ScheduleLine.SetRange("Contract No.", Schedule."Contract No.");
        ScheduleLine.SetRange("Schedule No.", Schedule."Schedule No.");
        ScheduleLine.SetRange("Version No.", Schedule."Version No.");
        if ScheduleLine.FindSet() then begin
            ScheduleLine.SetRange(Invoiced, true);
            if ScheduleLine.FindLast() then;
            //JM170723 rem IF GenJournalLine."Amount (LCY)" = ScheduleLine."Installment Incl. VAT" THEN
            decInstAmount := ScheduleLine.fnInstallmentInclVAT();
            if GenJournalLine."Amount (LCY)" = -decInstAmount then //JM170723
                GenJournalLine."S4LA Auto Matched By" := 'STRONG. By Contract No.,Amount'
            else begin
                ScheduleLine.SetRange(Invoiced);
                GenJournalLine."S4LA Auto Matched By" := 'WEAK. By Contract No.';
            end;
            GenJournalLine.Validate(GenJournalLine."S4LA Contact No.", Contract."Customer No.");
            GenJournalLine.Validate(GenJournalLine."Account No.", Contract."Customer No.");
            GenJournalLine.Validate(GenJournalLine."PYA Contract No", Contract."Contract No.");
            GenJournalLine.Validate(GenJournalLine."S4LA Schedule No.", Schedule."Schedule No.");
            //JM180322++
            GenJournalLine."S4LA Bank Branch No." := Contract."DD Bank Branch No.";
            GenJournalLine."S4LA Bank Account No." := Contract."DD Bank Account No.";
            GenJournalLine."S4LNA Bank Name" := Contract."DD Bank Name";
            //JM180322--
            GenJournalLine.Modify();
            doExit := true;
            exit;
        end;
    end;

    //Funder Payable Mgt
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Funder Payable Mgt", 'OnPostFunderPayables_BeforePostJnl', '', false, false)]
    local procedure OnPostFunderPayables_BeforePostJnl(var FunderRec: Record "S4LA Funder"; var BatchLine: Record "S4LA Funder Payable Line"; var Contr: Record "S4LA Contract"; var Vend: Record Vendor)
    begin
        //JM180219++
        if FunderRec."S4LNA Funder Type" = FunderRec."S4LNA Funder Type"::"Self-funding" then begin
            Contr."S4LNA Self Funder" := FunderRec.Code;
            Contr.Funder := '';
            Contr.Modify();
        end;
        if FunderRec."S4LNA Funder Type" = FunderRec."S4LNA Funder Type"::"Warehouse Funding" then begin
            Contr."S4LNA Self Funder" := '';
            Contr.Funder := FunderRec.Code;
            Contr.Modify();
        end;
        //JM180219--
    end;

    //Purchase Invoice
    //TODO NA >>
    // [EventSubscriber(ObjectType::Page, Page::"Purchase Invoice", 'OnPurchInvoice_AfterPostedPageRun', '', false, false)]
    // local procedure OnPurchInvoice_AfterPostedPageRun(var PurchInvHeader: Record "Purch. Inv. Header")
    // var
    //     SalesHeader: Record "Sales Header";
    //     SalesInvoice: Page "Sales Invoice";
    // begin
    //     /*TG190516*/
    //     IF PurchInvHeader."S4LA Re-post to Receivable" AND (SalesHeader.GET(SalesHeader."Document Type"::Invoice, PurchInvHeader."S4LNA Sales Invoice No.")) THEN BEGIN
    //         //SalesInvoice.SETTABLEVIEW(SalesHeader);
    //         SalesInvoice.SETRECORD(SalesHeader);
    //         SalesInvoice.EDITABLE := TRUE;
    //         SalesInvoice.RUN;
    //         //PAGE.RUN(Page::"Sales Invoice",SalesHeader);
    //     END;
    //     /*---*/
    // end;
    //TODO NA <<

    //FA Jnl.-Post Line
    // [EventSubscriber(ObjectType::codeunit, Codeunit::"FA Jnl.-Post Line", 'S4LNA_OnAfterPostDisposalEntry', '', false, false)]
    // local procedure S4LNA_OnAfterPostDisposalEntry(var FALedgEntry: Record "FA Ledger Entry")
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FA Jnl.-Post Line", 'OnBeforePostDisposalEntry', '', false, false)]
    local procedure OnBeforePostDisposalEntry(var FALedgEntry: Record "FA Ledger Entry"; DeprBook: Record "Depreciation Book"; FANo: Code[20]; ErrorEntryNo: Integer; var IsHandled: Boolean; var FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry")
    var
        LAssetStatus: Record "S4LA Status";
        LrecFA: Record "Fixed Asset";
        LeasingSetup: Record "S4LA Leasing Setup";
    begin
        /*TG200921*/
        LeasingSetup.Get();
        if LeasingSetup."FA Status - Sold" <> '' then
            LAssetStatus.Get(LeasingSetup."FA Status - Sold")
        else begin
            /*---*/
            LAssetStatus.Reset();
            LAssetStatus.SetRange("Target Table ID", Database::"Fixed Asset");
            LAssetStatus.SetRange("Trigger Option No.", LrecFA."S4LA Asset Status Trigger"::"S4LNA Sold".AsInteger());
            LAssetStatus.FindFirst();
        end; //TG200921
        LrecFA.Get(FALedgEntry."FA No.");
        LrecFA."S4LA Asset Status Code" := LAssetStatus.Code;
        LrecFA."S4LA Asset Status Trigger" := Enum::"S4LA Asset Status Trigger".FromInteger(LAssetStatus."Trigger Option No.");
        LrecFA.Modify();
    end;

    //Global Search Web
    [EventSubscriber(ObjectType::Page, Page::"S4LA Global Search", 'OnInit_BeforeExit', '', false, false)]
    local procedure OnInit_BeforeExit(var VINField: Boolean; var LicensePlateField: Boolean)
    begin
        VINField := true;
        LicensePlateField := true; //DV190131
    end;

    /*   [EventSubscriber(ObjectType::Page, Page::"S4LA Global Search", 'GlobalSearchWeb_OnFindPush', '', false, false)]
       local procedure GlobalSearchWeb_OnFindPush(var Sender: Page "S4LA Global Search"; var GlobalSearchBuffer: Record "S4LA Global Search Buffer"; var isHandled: Boolean; var SearchTxt: Text[1024])
       begin
           isHandled := true;
           Sender.FindPushNA(SearchTxt);
       end;
       */
    /* PYAS-168
 [EventSubscriber(ObjectType::Page, Page::"S4LA Global Search", 'GlobalSearchWeb_OnFindPush', '', false, false)]
 local procedure GlobalSearchWeb_OnFindPush(var Sender: Page "S4LA Global Search";

 var
     GlobalSearchBuffer: Record "S4LA Global Search Buffer";

 var
     isHandled: Boolean;

 var
     SearchTxt: Text[1024];

 var
     NameField: Boolean;

 var
     EmailAddressField: Boolean;
     SearchParam: array[20] of Boolean)
 begin
     // isHandled := true; PYAS-168
     //Sender.FindPushNA(SearchTxt, NameField, EmailAddressField, SearchParam); PYAS-168
 end;

 [EventSubscriber(ObjectType::Page, Page::"S4LA Global Search", 'GlobalSearchWeb_OnFindRecords', '', false, false)]
 local procedure GlobalSearchWeb_OnFindRecords(var Sender: Page "S4LA Global Search";

 var
     GlobalSearchBuffer: Record "S4LA Global Search Buffer";

 var
     isHandled: Boolean)
 begin
     // isHandled := true; PYAS-168
     // Sender.FindRecordsNA(); PYAS-168
 end;
*/
    //Calculate Depreciation
    //TODO NA
    /*
    [EventSubscriber(ObjectType::Report, Report::"Calculate Depreciation", 'OnPostReport_BeforeMessage', '', false, false)]
    local procedure CalculateDepreciation_OnPostReport_BeforeMessage(var IsHandled: boolean)
    var
        storageKey: text;
        storageValue: text;
    begin
        IsHandled := false;
        storageKey := 'CalculateDepreciation_ContractNo';
        if not IsolatedStorage.Contains(storageKey, DataScope::CompanyAndUser) then
            exit;
        if IsolatedStorage.Get(storageKey, DataScope::CompanyAndUser, storageValue) then begin
            IsHandled := storageValue <> '';  //DV171003 don't want message if from return
            IsolatedStorage.Delete(storageKey, DataScope::CompanyAndUser);
        end;
    end;
    */

    [EventSubscriber(ObjectType::Report, Report::"Calculate Depreciation", 'OnBeforeGenJnlLineInsert', '', false, false)]
    local procedure CalculateDepreciation_OnBeforeGenJnlLineInsert(var TempGenJournalLine: Record "Gen. Journal Line" temporary; var GenJournalLine: Record "Gen. Journal Line")
    var
        FA: Record "Fixed Asset";
        Contr: Record "S4LA Contract";
        Sched: Record "S4LA Schedule";
        DimMgt: Codeunit DimensionManagement;
    begin
        if not FA.Get(TempGenJournalLine."Account No.") then
            FA.Init();
        //KS150109
        if FA."PYA Contract No" <> '' then begin
            Contr.Get(FA."PYA Contract No");
            Contr.GetNewestSchedule(Sched);
            GenJournalLine."S4LA Customer No." := Contr."Customer No.";
            GenJournalLine."PYA Contract No" := Contr."Contract No.";
            GenJournalLine."S4LA Schedule No." := Sched."Schedule No.";
            GenJournalLine."Dimension Set ID" := Contr."Dimension Set ID";
            DimMgt.UpdateGlobalDimFromDimSetID(GenJournalLine."Dimension Set ID", GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");
            //TODO NA IsolatedStorage.Set('CalculateDepreciation_ContractNo', Contr."Contract No.", DataScope::CompanyAndUser);
        end;
        //---
    end;

    //Invoicing Run
    [EventSubscriber(ObjectType::Report, Report::"S4LA Invoicing Run", 'InvoicingRun_OnPreReport', '', false, false)]
    local procedure InvoicingRun_OnPreReport(var ContractFilters: Record "S4LA Contract"; Contr: Code[20]; DueDateUntil: Date; PostingDate: Date; BreakOnError: Boolean; PenaltyInterestPostingForCompletelyInvoicedContracts: Boolean; DoPosting: Boolean; var isHandled: Boolean)
    var
        r: Report "S4LNA Invoicing Run";
    begin
        r.SetParametersNA(ContractFilters, Contr, DueDateUntil, PostingDate, BreakOnError, PenaltyInterestPostingForCompletelyInvoicedContracts, DoPosting);
        r.UseRequestPage := false;
        r.RunModal();
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Invoicing Mgt", 'OnCalcPenaltyInterest_BeforeCalcPenaltyInterestInclVAT', '', false, false)]
    local procedure CalcPenaltyInclTax_OnCalcPenaltyInterest_BeforeCalcPenaltyInterestInclVAT(ContractNo: Code[20]; CalcToDate: Date; FinancialProduct: Record "S4LA Financial Product"; CurrencyRec: Record Currency; PenaltyInterestExclVAT: Decimal; var PenaltyInterestInclVAT: Decimal; var isHandled: Boolean)
    begin
        PenaltyInterestInclVAT := PenaltyInterestExclVAT; //Implement Tax calculation procedure for penalty interest here, if required
        isHandled := true;
    end;

    //TG210910 - sales invoice type needs to be populated for installments
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Invoicing Mgt", 'RunGenJnlPostingForCreatedJnLine_BeforePost', '', false, false)]
    local procedure FillFields_OnPostGenJnl_BeforePost(var Jnl: Record "Gen. Journal Line"; var Contract: Record "S4LA Contract"; var Schedule: Record "S4LA Schedule";
                                                       var ScheduleLine: Record "S4LA Schedule Line"; var isHandled: Boolean)
    var
        FinProd: Record "S4LA Financial Product";
    begin
        FinProd.Get(Contract."Financial Product");
        Jnl."S4LA Sales invoice type" := FinProd."Invoice Type For Instalments";

        //PYAS-170
        if Contract."S4LNA Payment Terms Code" <> '' then
            Jnl.Validate("Payment Terms Code", Contract."S4LNA Payment Terms Code")
        else
            Jnl."Due Date" := ScheduleLine.Date;
        //--//
    end;

    //PYAS-170
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Invoicing Mgt", 'OnCreateSalesHeader_No', '', false, false)]
    local procedure CreateSalesHeader_No(var SalesHeader: Record "Sales Header"; var Contract: Record "S4LA Contract"; var Schedule: Record "S4LA Schedule"; var ScheduleLine: Record "S4LA Schedule Line"; var isHandled: Boolean)
    begin
        if Contract."S4LNA Payment Terms Code" <> '' then
            SalesHeader.Validate("Payment Terms Code", Contract."S4LNA Payment Terms Code")
        else
            SalesHeader."Due Date" := ScheduleLine.Date;
    end;
    //--/

    //Contract Activate
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Contract - Activate", 'ContractActivate_OnRun', '', false, false)]
    local procedure ContractActivate_OnRun(var Contr: Record "S4LA Contract"; var isHandled: Boolean)
    var
        NAContractActivate: Codeunit "NA Contract Activate";
        sched: Record "S4LA Schedule";
    begin
        // -- PYAS-149
        Contr.GetNewestSchedule(sched);
        sched.TestField("Activation Date");
        NAContractActivate.SetParameters(sched."Activation Date");
        //--//
        NAContractActivate.Run(Contr);
        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Contract Mgt", 'OnCalcPaymentsBeforeCalc', '', false, false)]
    local procedure CalcPayments_OnRun(Schedule: Record "S4LA Schedule"; intPeriod: Integer; VarInterestChangeRecalculation: Boolean; var isHandled: Boolean)
    var
        NASchedCalc: Codeunit "NA Schedule Calc NA";
        FinProd: Record "S4LA Financial Product";
    begin
        if not isHandled then begin
            if not FinProd.Get(Schedule."Financial Product") then
                exit;
            if FinProd."S4LNA Schedule Calc. Codeunit" = FinProd."S4LNA Schedule Calc. Codeunit"::"Schedule Calc" then
                exit;
            //PYAS-209
            NASchedCalc.SetVarInterestChangeRecalculation(VarInterestChangeRecalculation);
            //--//
            NASchedCalc.CalcPayments(Schedule, intPeriod);
            isHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Contract Mgt", 'OnAfterRecalcScheduleLines', '', false, false)]
    local procedure ContractMgt_OnAfterRecalcScheduleLines(var Schedule: Record "S4LA Schedule")
    begin
        //--// TG210318 - put in NA if shouldn't be in W1.
        if Schedule."Ending Date" = 0D then
            Schedule."Ending Date" := CalcDate('<CM>', Schedule."Starting Date");
        //--//
        Schedule.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Contract", 'OnMakeContractFromQuoteSchedule_BeforeCommit', '', false, false)]
    local procedure ValidateOriginator(rec: Record "S4LA Contract"; RecContract: Record "S4LA Contract")
    begin
        RecContract.Validate("Originator No.");
        RecContract.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"S4LA Schedule", 'OnBeforeUpdateIntRate', '', false, false)]
    local procedure BeforeUpdateIntRate(var skipRun: Boolean)
    begin
        skipRun := true;
    end;

    //BA210511
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer; var NewReportId: Integer)
    begin
        if ReportId = Report::"S4LA Invoicing Run" then
            NewReportId := Report::"S4LNA Invoicing Run";
    end;

    //BA210519
    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnInitOnInsert_BeforeExit', '', false, false)]

    local procedure BeforeInsertAsset(var Rec: Record "S4LA Asset"; var Contr: Record "S4LA Contract"; OldRec: Record "S4LA Asset")
    var
        LeasingSetup: Record "S4LA Leasing Setup";

    begin
        LeasingSetup.Get();

        Rec."Mileage Limit (km/year)" := LeasingSetup."S4LNA Mileage Limit (km/year)";
        Rec."Price Per km Over Limit" := LeasingSetup."S4LNA Price per km over limit";
    end;

    //BA210602 - avoid creating dimension when either dim 1 or dim 2 has a value
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeCreateDim', '', false, false)]
    local procedure BeforeCreateDim(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    var
    begin
        if (SalesHeader."Shortcut Dimension 1 Code" <> '') or (SalesHeader."Shortcut Dimension 2 Code" <> '') then
            IsHandled := true;
    end;

    //BA210603 -- Change VAT label to TAX
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VAT CaptionClass Mgmt", 'OnBeforeVATCaptionClassTranslate', '', true, true)]

    local procedure UpdateVATCaptionClassTranslate(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var IsHandled: Boolean)

    var
        VATCaptionType: Text;
        VATCaptionRef: Text;
        CommaPosition: Integer;
        ExclVATTxt: Label 'Excl. Tax';
        InclVATTxt: Label 'Incl. Tax';
    begin

        CommaPosition := StrPos(CaptionExpr, ',');
        if CommaPosition > 0 then begin
            VATCaptionType := CopyStr(CaptionExpr, 1, CommaPosition - 1);
            VATCaptionRef := CopyStr(CaptionExpr, CommaPosition + 1);
            case VATCaptionType of
                '0':
                    Caption := StrSubstNo('%1 %2', VATCaptionRef, ExclVATTxt);
                '1':
                    Caption := StrSubstNo('%1 %2', VATCaptionRef, InclVATTxt);
                else
                    Caption := '';
            end;
        end;

        IsHandled := true;
    end;

    //BA210618
    /*    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnTransferDataFromAltAddressToContact_BeforeModify', '', true, true)]
        local procedure TransferDataFromAltAddressToContact(var ContactAltAddress: Record "Contact Alt. Address"; var Contact: Record Contact)

        begin
            Contact."S4LNA County 2" := ContactAltAddress."S4LNA County 2";
        end;

        //BA210618
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnTransferDataFromAltAddressToApplicant_BeforeModify', '', true, true)]
        local procedure TransferDataFromAltAddressToApplicant_beforemodify(var ContactAltAddress: Record "Contact Alt. Address"; var Applicant: Record "S4LA Applicant")

        begin
            Applicant."S4LNA County 2" := ContactAltAddress."S4LNA County 2";
        end;

        //BA210618
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnUpdateAddressFromApplicantToContract_BeforeModify', '', true, true)]
        local procedure UpdateAddressFromApplicantToContract_BeforeModify(var Contract: Record "S4LA Contract"; var Applicant: Record "S4LA Applicant")

        begin
            Contract."S4LNA County 2" := Applicant."S4LNA County 2";
        end;

        //BA210618
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Applicant Mgt", 'OnCompareApplicantToContact_BeforeEnd', '', true, true)]
        local procedure OnComparefield(Applicant: Record "S4LA Applicant"; Contact: Record Contact; var FieldDoesNotMatch: Boolean)
        begin
            FieldDoesNotMatch := false;
            if CompareField(Applicant.County, Contact.County) then
                FieldDoesNotMatch := true;
        end;

        local procedure CompareField(NewValue: Variant; ExistingValue: Variant): Boolean
        var
            Val1: Code[250];
            Val2: Code[250];
        begin
            Val1 := UpperCase(CopyStr(DelChr(Format(NewValue)), 1, 100));
            Val2 := UpperCase(CopyStr(DelChr(Format(ExistingValue)), 1, 100));
            if (Val2 <> '') and
               (Val2 <> Val1)
            then
                exit(true)   // conflict
            else
                exit(false); // no conflict
        end;

        //BA210623  -- take care of createVendor
        [EventSubscriber(ObjectType::Table, Database::Contact, 'OnBeforeCreateVendor', '', true, true)]
        procedure CreateVendorPYA(var Contact: Record Contact; var VendorNo: Code[20]; var IsHandled: Boolean)
        var
            Vend: Record Vendor;
            ContComp: Record Contact;
            ContBank: Record "S4LA Contact Bank Account";
            VendBank: Record "Vendor Bank Account";
            ContBusRel: Record "Contact Business Relation";
            RMSetup: Record "Marketing Setup";
            UpdateCustVendBank: Codeunit "CustVendBank-Update";
            VendTemplate: Record "Vendor Templ.";
            VendorTemplateCode: Code[20];
        begin

            IsHandled := true;

            VendTemplate.Reset();
            if VendTemplate.Count = 1 then begin
                VendTemplate.FindFirst();
                VendorTemplateCode := VendTemplate.Code;
            end else
                VendorTemplateCode := Contact.S4LAChooseVendorTemplate();

            if Vend.Get(Contact."No.") then  //KS160219 silent exist if vendor already exists (because CreateVendor called from multiple places)
                exit;

            if Contact.Type = Contact.Type::Person then
                Contact.CheckForExistingRelationships(ContBusRel."Link to Table"::Vendor);

            Contact.TestField("Company No.");
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Vendors");

            Clear(Vend);
            Vend.SetInsertFromContact(true);


            //BA210707 Changed to contact.no
            Vend."No." := Contact."No.";  //always use same Contact no for vendor (and customer also). This is a must.
            Vend."Application Method" := Vend."Application Method"::"Apply to Oldest";
            //KS170209 NA
            Vend."Tax Area Code" := Contact."PYA Tax Area Code";
            Vend."Tax Liable" := Contact."PYA Tax Liable";
            //---
            Vend.Insert(true);

            //KS081216 IFAG create bank accounts
            ContBank.Reset();
            ContBank.SetRange("Contact No.", Contact."No.");
            if ContBank.FindFirst() then
                repeat
                    VendBank.Init();
                    VendBank.TransferFields(ContBank);
                    VendBank."Country/Region Code" := ContBank."Country Code";

                    //VendBank.INSERT;
                    if VendBank.Get(VendBank."Vendor No.", VendBank.Code)
                      then
                        VendBank.Modify()
                    else
                        VendBank.Insert();

                until ContBank.Next() = 0;

            Vend.SetInsertFromContact(false);

            if Contact.Type = Contact.Type::Company then
                ContComp := Contact
            else
                ContComp.Get(Contact."Company No.");

            ContBusRel."Contact No." := ContComp."No.";
            ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
            ContBusRel."Link to Table" := ContBusRel."Link to Table"::Vendor;
            ContBusRel."No." := Vend."No.";
            ContBusRel.Insert(true);

            UpdateCustVendBank.UpdateVendor(ContComp, ContBusRel);

            Vend.Get(ContBusRel."No.");
            Vend.Validate(Name, Contact.Name);   // PG120821 was company name

            VendTemplate.Get(VendorTemplateCode); // there must be a template, and user must choose one
            Vend.Validate("Vendor Posting Group", VendTemplate."Vendor Posting Group");
            Vend.Validate("Gen. Bus. Posting Group", VendTemplate."Gen. Bus. Posting Group");
            Vend.Validate("VAT Bus. Posting Group", VendTemplate."VAT Bus. Posting Group");

            Vend."Application Method" := VendTemplate."Application Method";   //>>NK141219


            Vend."Primary Contact No." := Contact."No."; /*DV140403*/
    //Vend.Modify(); //KS081208/

    //end;

    //remove from compliance check
    /*    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeTitleCheck', '', true, true)]
        procedure BeforeTitleCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeGenderCheck', '', true, true)]
        procedure BeforeGenderCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeMaritalStatusCheck', '', true, true)]
        procedure BeforeMaritalStatusCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeCountryRegionCheck', '', true, true)]
        procedure BeforeCountryRegionCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeResidentialStatusCheck', '', true, true)]
        procedure BeforeResidentialStatusCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeOriginatorCountryCheck', '', true, true)]
        procedure BeforeOriginatorCountryCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeOriginatorStateCheck', '', true, true)]
        procedure OnBeforeOriginatorStateCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeApplicantTitleCheck', '', true, true)]
        procedure BeforeApplicantTitleCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeAssetGroupCheck', '', true, true)]
        procedure BeforeAssetGroupCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Compliance Rules", 'OnBeforeAssetCategoryCheck', '', true, true)]
        procedure BeforeAssetCategoryCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Compliance Rules", 'OnBeforeRetailOriginatorStatusCheck', '', true, true)]
        procedure BeforeOrigStatusCheck_Compliance(Contact: Record Contact; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeRetailOriginatorStatusCheck', '', true, true)]
        procedure BeforeOrigStatusCheck_Submission(Contact: Record Contact; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeOriginatorSalesPersonCheck', '', true, true)]
        procedure BeforeOriginatorSalesPersonCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        //--//
        //PYAS-150 - remove from compliance check
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeRegistrationNoCheck', '', true, true)]
        procedure BeforeRegistrationNoCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;
        //no of employees   OnBeforeNoOfEmployeesCheck(Contract, isHandled);
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeNoOfEmployeesCheck', '', true, true)]
        procedure BeforeNoOfEmployeesCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;
        //

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeLegalFormCheck', '', true, true)]
        procedure BeforeLegalFormCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        // (Contract, isHandled);
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeNationalityCheck', '', true, true)]
        procedure BeforeNationalityCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeApplicantCountyCheck', '', true, true)]
        procedure BeforeApplicantCountyCheck(Contract: Record "S4LA Contract"; Applicant: Record "S4LA Applicant"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeEMailCheck', '', true, true)]
        procedure BeforeEMailCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforePhoneNoCheck', '', true, true)]
        procedure BeforePhoneNoCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeApplicantBirthDateCheck', '', true, true)]
        procedure BeforeApplicantBirthDateCheck(Contract: Record "S4LA Contract"; Applicant: Record "S4LA Applicant"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeApplicantApplicantAgeYearsCheck', '', true, true)]
        procedure BeforeApplicantApplicantAgeYearsCheck(Contract: Record "S4LA Contract"; Applicant: Record "S4LA Applicant"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeApplicantApplicantNationalityCheck', '', true, true)]
        procedure BeforeApplicantApplicantNationalityCheck(Contract: Record "S4LA Contract"; Applicant: Record "S4LA Applicant"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Submission Rules", 'OnBeforeContactPersonCheck', '', true, true)]
        procedure BeforeContactPersonCheck(Contract: Record "S4LA Contract"; var isHandled: Boolean)
        begin
            isHandled := true;
        end;

        //--//

        //FOR keyCredit
        [IntegrationEvent(false, false)]
        local procedure onBeforeCreateFANo(var FA: Record "Fixed Asset")
        begin
        end;

        //SOLV-707 >>
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Gen. Jnl.-Post Line", 'OnBegin_IsDishonourFeeApplicable', '', false, false)]
        procedure IsDishonourFeeApplicable(GenJournalLine: Record "Gen. Journal Line"; var ApplyDishonourFee: Boolean; var IsHandled: Boolean)
        begin
            ApplyDishonourFee := GenJournalLine."S4LNA Charge Dishonour Fee";
            IsHandled := true;
        end;

        [IntegrationEvent(false, false)]
        local procedure SetPYADocFiller(var DocRec: Record "S4LA Document"; pServerFileName: Text; pReadOnly: Boolean; var IsHandled: Boolean)
        begin
        end;

        //BA211006  -- Insert custom fields when recreating sales line.
        [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnBeforeSalesLineInsert', '', true, true)]
        procedure InsertS4Lines(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
        var
        begin
            SalesLine."PYA Contract No" := TempSalesLine."PYA Contract No";
            SalesLine."S4LA Amortiz. From Date" := TempSalesLine."S4LA Amortiz. From Date";
            // SalesLine."S4LA Amortiz. Item ID" := TempSalesLine."S4LA Amortiz. Item ID";
            SalesLine."S4LA Amortiz. Method" := TempSalesLine."S4LA Amortiz. Method";
            SalesLine."S4LA Amortiz. per Schedule No." := TempSalesLine."S4LA Amortiz. per Schedule No.";
            SalesLine."S4LA Amortiz. To Date" := TempSalesLine."S4LA Amortiz. To Date";
            SalesLine."S4LA Asset ID" := TempSalesLine."S4LA Asset ID";
            SalesLine."S4LA FA Posting Type" := TempSalesLine."S4LA FA Posting Type";
            SalesLine."S4LNA Fee Type" := TempSalesLine."S4LNA Fee Type";
            SalesLine."S4LNA Current Odometer" := TempSalesLine."S4LNA Current Odometer";
            SalesLine."S4LA Factoring Agreement No." := TempSalesLine."S4LA Factoring Agreement No.";
            SalesLine."S4LA Factoring Entry Type" := TempSalesLine."S4LA Factoring Entry Type";
            SalesLine."S4LA Factoring Invoice ID" := TempSalesLine."S4LA Factoring Invoice ID";
            SalesLine."S4LA Installment Part" := TempSalesLine."S4LA Installment Part";
            // SalesLine."S4LA Instalm. Part for Printing" := TempSalesLine."S4LA Instalm. Part for Printing";
            SalesLine."S4LA Schedule Line No." := TempSalesLine."S4LA Schedule Line No.";
            SalesLine."S4LA Schedule No." := TempSalesLine."S4LA Schedule No.";
            SalesLine."S4LA Service Code" := TempSalesLine."S4LA Service Code";
            SalesLine."S4LA Work Order No." := TempSalesLine."S4LA Work Order No.";
        end;

        //- Publisher events need to be added to SL61 Soft4Leasing Extension
        //BA211108 - use schduline line outstanding amount as refinance amt

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Refinance Mgt.", 'OnBeforeSetRefinanceAmount_CreateRefinance', '', true, true)]
        procedure GetAmtToRefinance(var FromContr: Record "S4LA Contract"; var AmountToRefinance: Decimal; var DateOfRefinance: Date; var IsHandled: Boolean);
        var
            SchedLine: Record "S4LA Schedule Line";
            OutStandingAmt: Decimal;
            FromSched: Record "S4LA Schedule";
        begin

            FromContr.GetValidSchedule(FromSched);

            OutStandingAmt := 0;

            SchedLine.Reset();
            SchedLine.SetCurrentKey(Date, Invoiced);
            SchedLine.SetRange("Contract No.", FromSched."Contract No.");
            SchedLine.SetRange("Version No.", FromSched."Version No.");
            SchedLine.SetFilter(Period, '>=1');
            SchedLine.SetRange(Invoiced, true);
            if SchedLine.FindLast() then
                OutStandingAmt := SchedLine."Outstanding Amount" + SchedLine."Principal Amount";

            if OutStandingAmt <> 0 then begin
                AmountToRefinance := OutStandingAmt;
                IsHandled := true;
            end;
        end;

        //BA211109 - use schedule line outstanding amount as the outstanding principal for early payout card
        //SOLV-828 >>
        [EventSubscriber(ObjectType::Table, Database::"S4LA Early Payout", 'OnAfterOutstandingPrincipleCalculation', '', true, true)]
        procedure GetOutstandingAmt(var EarlyPayOut: Record "S4LA Early Payout"; CBal: Record "S4LA Contract Balance"; Schedule: Record "S4LA Schedule")
        var
            SchedLine: Record "S4LA Schedule Line";
            StartPeriod: Date;
            SchedLine2: Record "S4LA Schedule Line";
        begin

            //  StartPeriod := DMY2Date(01, Date2DMY(EarlyPayOut."Pay-out Figure as of Date", 2), Date2DMY(EarlyPayOut."Pay-out Figure as of Date", 3));
            StartPeriod := 0D;
            SchedLine2.Reset();
            SchedLine2.SetCurrentKey(Date, Invoiced);
            SchedLine2.SetRange("Contract No.", Schedule."Contract No.");
            SchedLine2.SetRange("Version No.", Schedule."Version No.");
            SchedLine2.SetFilter(Date, '..%1', EarlyPayOut."Pay-out Figure as of Date");
            SchedLine2.SetFilter(Period, '>=1');
            if SchedLine2.FindLast() then
                StartPeriod := SchedLine2.Date;

            SchedLine.Reset();
            SchedLine.SetCurrentKey(Date, Invoiced);
            SchedLine.SetRange("Contract No.", Schedule."Contract No.");
            SchedLine.SetRange("Version No.", Schedule."Version No.");
            SchedLine.SetFilter(Date, '%1..%2', StartPeriod, CalcDate('CM', EarlyPayOut."Pay-out Figure as of Date"));
            SchedLine.SetFilter(Period, '>=1');
            if SchedLine.FindFirst() then
                EarlyPayOut."Outstanding Principal" := SchedLine."Outstanding Amount" + SchedLine."Principal Amount";
        end;

        //PYAS-95 >>
        [EventSubscriber(ObjectType::Table, Database::"S4LA Early Payout", 'OnBeforePayoutFigureAsOfDateCheck_OnValidatePayoutFigureAsOfDate', '', true, true)]
        procedure OnBeforePayoutFigureAsOfDateCheck_OnValidatePayoutFigureAsOfDate(EarlyPayout: Record "S4LA Early Payout"; var IsHandled: Boolean)
        var
        begin
            IsHandled := true;
        end;
        //PYAS-95 <<

        //PYAS-91
        [EventSubscriber(ObjectType::Table, Database::Contact, 'S4LAOnBeforeContAltAddressModify_InsertIntoAddress', '', true, true)]
        local procedure Contact_OnBeforeContAltAddressModify(Contact: Record Contact; var ContactAltAddress: Record "Contact Alt. Address")
        var
            i: Integer;
        begin
            if Contact.Address <> '' then begin
                Contact.Address := DelChr(Contact.Address, '<>', ' ');
                i := StrPos(Contact.Address, ' ');
                if i >= 1 then
                    i -= 1;
                if i <> 0 then begin
                    if i <= 10 then
                        ContactAltAddress."S4LA Street Number" := CopyStr(Contact.Address, 1, i)
                    else
                        ContactAltAddress."S4LA Street Number" := CopyStr(Contact.Address, 1, 10);
                    ContactAltAddress."S4LA Street Name" := CopyStr(Contact.Address, i + 2, 50);
                    ContactAltAddress.Modify(false);
                end;
            end;
        end;

        //BA220119 - Fix document printing & report printing bug.

        [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document Report Mgt.", 'OnAfterGetCustomLayoutCode', '', false, false)]
        local procedure AfterGetCustomLayout(ReportID: Integer; var CustomLayoutCode: Code[20])
        var
            CustomReportLayout: Record "Custom Report Layout";
        begin
            CustomReportLayout.Reset();
            CustomReportLayout.SetRange("Report ID", ReportID);
            CustomReportLayout.SetRange(Code, CustomLayoutCode);
            if not CustomReportLayout.FindFirst() then begin
                CustomLayoutCode := '';
                exit;
            end else
                CustomLayoutCode := CustomReportLayout.Code;

                    CustomReportLayout.reset;
                    CustomReportLayout.SetCurrentKey("Report ID");
                    CustomReportLayout.SetRange("Report ID", ReportID);
                    if not CustomReportLayout.findfirst then
                        CustomLayoutCode := ''
                    else
                        CustomLayoutCode := CustomReportLayout.code;

        end;
    */
    /* SOLV-1422
    //PYAS-156 - Fill DD Entry No for Bank Recon Line
    [EventSubscriber(ObjectType::Report, Report::"Bank Rec. Process Lines", 'OnAfterWriteLine', '', true, true)]
    local procedure AfterWriteLine(BankRecHdr2: Record "Bank Rec. Header"; var BankRecLine2: Record "Bank Rec. Line")
    var
        BankAccLedger: Record "Bank Account Ledger Entry";
    begin
        if BankAccLedger.get(BankRecLine2."Bank Ledger Entry No.") then begin
            BankRecLine2."S4LNA Direct Debit Entry No." := BankAccLedger."S4LA Direct Debit Entry No.";
            BankRecLine2.Modify();
        end;
    end;
    //--//
    */

    //PYAS-157 - Skip for limited user
    [EventSubscriber(ObjectType::Table, Database::"S4LA Early Payout", 'OnBeforeCalculatePayout', '', true, true)]
    local procedure BeforeCalculatePayout(var EarlyPayOut: Record "S4LA Early Payout"; CBal: Record "S4LA Contract Balance"; DoModify: Boolean; var IsHandled: Boolean)
    var
        user: Record User;
    begin
        user.Reset();
        user.SetRange("User Name", UserId);
        if user.FindFirst() then
            if user."License Type" = user."License Type"::"Limited User" then
                IsHandled := true;
    end;
    //--//

    //PYAS-184 Update Asset/Fixed Asset BuildDescription
    [EventSubscriber(ObjectType::Table, Database::"S4LA Asset", 'OnBuildDescription_BeforeExit', '', false, false)]
    local procedure BuildDescriptioni(var Rec: Record "S4LA Asset"; var Txt: Text)
    begin
        //Model Year + Asset Brand + Model + Trim
        Txt := '';
        if Rec."Model Year" <> 0 then
            Txt := Format(Rec."Model Year");

        if Rec."Asset Brand" <> '' then
            Txt := Txt + ' ' + Rec."Asset Brand";

        if Rec.Model <> '' then
            Txt := Txt + ' ' + Rec.Model;

        if Rec."S4LNA Trim" <> '' then
            Txt := Txt + ' ' + Rec."S4LNA Trim";
    end;

    //--//
    //PYAS-228
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Contract Mgt", 'OnBeforeCheckAndDeleteScheduleLines_RecalcScheduleLines', '', false, false)]
    local procedure CheckAndDeleteScheduleLines_RecalcScheduleLines(var Schedule: Record "S4LA Schedule"; var SkipCalculation: Boolean; var isHandled: Boolean)
    var
        ScheduleLine: Record "S4LA Schedule Line";
        FinProd: Record "S4LA Financial Product";
        contr: Record "S4LA Contract";
    begin
        if contr.Get(Schedule."Contract No.") then;
        if FinProd.Get(contr."Financial Product") then;//PYAS-235
        if ((Schedule."Starting Date" = 0D) or
              (Schedule."Installments Per Year" = 0) or
              (Schedule."Number Of Payment Periods" = 0) or
              ((Schedule."Capital Amount" = 0) and ((not FinProd."S4LNA Services/Insurance Only") and (not Schedule."S4LNA Serv. and Insurance Only")))

              )

              and
             (Schedule."Version status" = Schedule."Version status"::New) then begin
            ScheduleLine.SetRange("Contract No.", Schedule."Contract No.");
            ScheduleLine.SetRange("Schedule No.", Schedule."Schedule No.");
            ScheduleLine.SetRange("Version No.", Schedule."Version No.");
            ScheduleLine.SetRange(Invoiced, true);
            ScheduleLine.SetFilter("Entry Type", '<>%1', ScheduleLine."Entry Type"::" ");
            if ScheduleLine.IsEmpty then begin
                ScheduleLine.SetRange(Invoiced);
                ScheduleLine.SetRange("Entry Type");
                ScheduleLine.DeleteAll(true);
                SkipCalculation := true;
            end;
            ScheduleLine.Reset();
        end;

        isHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Contract Mgt", 'OnBeforeCapitalAmountCheck_RecalcScheduleLines', '', false, false)]
    local procedure BeforeCapitalAmountCheck_RecalcScheduleLines(var Schedule: Record "S4LA Schedule"; var isHandled: Boolean)
    var
        FinProd: Record "S4LA Financial Product";
        contr: Record "S4LA Contract";
    begin
        if contr.Get(Schedule."Contract No.") then;
        FinProd.Get(contr."Financial Product");

        if (FinProd."S4LNA Services/Insurance Only") or Schedule."S4LNA Serv. and Insurance Only" then
            isHandled := true;
    end;
    //--//

    //
    //PYAS-269
    [EventSubscriber(ObjectType::Table, Database::"S4LA Leasing Posting Setup", 'OnBeforeGetSetupRec', '', false, false)]
    local procedure BeforeGetSetupRec(var recSetupLine: Record "S4LA Leasing Posting Setup"; var ContractNo: Code[20]; var IsHandled: Boolean);
    var
        Contract: Record "S4LA Contract";
        GlobalSilentMode: Boolean;
        Contact: Record Contact;
        AssetRec: Record "S4LA Asset";
        FA: Record "Fixed Asset";
    begin

        GlobalSilentMode := recSetupLine.isGlobalSilentMode();

        if GlobalSilentMode then begin
            if not Contract.Get(ContractNo) then Clear(Contract);
            if not Contact.Get(Contract."Customer No.") then Clear(Contact);
        end else begin
            Contract.Get(ContractNo);
            Contact.Get(Contract."Customer No.");
        end;

        Clear(FA);
        AssetRec.Reset();
        AssetRec.SetRange("Contract No.", Contract."Contract No.");
        AssetRec.SetFilter("Asset No.", '<>%1', ''); //PYAS-269 changes to the previous commit
        if AssetRec.FindFirst() then
            if not FA.Get(AssetRec."Asset No.") then
                Clear(FA);

        recSetupLine.SetFilter("Fin. Product", '%1|%2', Contract."Financial Product", '');
        recSetupLine.SetFilter("FA Class Code", '%1|%2', FA."FA Class Code", '');
        case Contract."Individual/Business" of
            Contract."Individual/Business"::Business:
                recSetupLine.SetRange("Individual/Busines", recSetupLine."Individual/Busines"::Business);
            Contract."Individual/Business"::Individual:
                recSetupLine.SetRange("Individual/Busines", recSetupLine."Individual/Busines"::Individual);
        end;

        if recSetupLine.IsEmpty then
            recSetupLine.SetRange("Individual/Busines", recSetupLine."Individual/Busines"::All);

        //Additional Filter Per Legal Form
        recSetupLine.SetRange("Legal Form", ''); //Set empty filter
        if Contract."Legal Form" <> '' then begin
            recSetupLine.SetRange("Legal Form", Contract."Legal Form");
            if recSetupLine.IsEmpty then
                recSetupLine.SetRange("Legal Form", ''); //Set empty filter again
        end;

        //recSetupLine.SetFilter("Customer category", '%1|%2', Contact."S4LA Contact Category", '');
        //recSetupLine.SetRange(recSetupLine."Lease Status", recSetupLine."Lease Status"::"Active Lease"); //KS141128 this function is for Active Contract. Create new fn for other statuses, when/if needed
        if GlobalSilentMode then begin
            if not recSetupLine.FindLast() then Clear(recSetupLine);
        end else
            recSetupLine.FindLast();

        IsHandled := true;
    end;

    //--//
    //PYAS-306 - Changes for monthly inertia amount on Contract services
    [EventSubscriber(ObjectType::Table, Database::"S4LA Contract Service", 'OnAfterCalculateTotals', '', false, false)]
    local procedure OnAfterCalcServ(var Rec: Record "S4LA Contract Service")
    var
        GLSetup: Record "General Ledger Setup";
        RoundingPrecision: Decimal;
        Currency: Record Currency;
    begin
        //should only run when calling from Invoicing Run
        GLSetup.Get();
        if Currency.Get(Rec."Currency Code") then
            RoundingPrecision := Currency."Amount Rounding Precision"
        else
            RoundingPrecision := GLSetup."S4LA Leas. Amt. Rounding Prec.";

        if (Rec."Total Amount" = 0) and (Rec."Service Cost (Annual)" = 0) and (Rec."Service Cost (Monthly)" > 0) then begin

            Rec."Service Cost (Annual)" := Round(Rec."Service Cost (Monthly)" * 12, RoundingPrecision);

            if Rec."Service Cost (Annual)" <> 0 then
                Rec."Total Amount" := Round(Rec."Service Cost (Annual)" * Rec."No. Of Months" / 12, RoundingPrecision);
        end;
    end;

    /*    [EventSubscriber(ObjectType::Report, Report::"S4LA Create PO from Applicat.", 'OnBeforePurchaseHeaderModify', '', false, false)]
        local procedure CreatePOFromApplication_OnBeforePurchaseHeaderModify(var PurchaseHeader: Record "Purchase Header"; Asset: Record "S4LA Asset"; Contract: Record "S4LA Contract"; Schedule: Record "S4LA Schedule")
        begin
            //BA210531 -- add asset details from application
            PurchaseHeader."S4LNA Model Year" := Asset."Model Year";
            PurchaseHeader."S4LNA S#Car Make Code" := Asset."Asset Brand";
            PurchaseHeader."S4LNA S#Car Model" := Asset.Model;
            PurchaseHeader."S4LNA Asset New / Used" := Asset."Asset New / Used";
            PurchaseHeader."S4LNA VIN" := Asset.VIN;
            PurchaseHeader."S4LNA Trim" := Asset."S4LNA Trim";
            PurchaseHeader."S4LNA Color Of Vehicle" := Asset."S4LNA Color Of Vehicle";
            PurchaseHeader."S4LNA S#Color Of Interior" := Asset."S4LNA Color Of Interior";
            PurchaseHeader."S4LNA FA Class Code" := Asset."S4LNA FA Class Code";
            PurchaseHeader."S4LNA Starting Mileage (km)" := Asset."Starting Mileage (km)";
            PurchaseHeader."S4LNA Purchase for" := PurchaseHeader."S4LNA Purchase for"::Lease;
            //end here
        end;

        [EventSubscriber(ObjectType::Report, Report::"S4LA Create PO from Applicat.", 'OnBeforePurchaseLineInsert', '', false, false)]
        local procedure CreatePOFromApplication_OnBeforePurchaseLineInsert(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; var Asset: Record "S4LA Asset"; Contract: Record "S4LA Contract"; Schedule: Record "S4LA Schedule")
        var
            GLSetup: Record "General Ledger Setup";
            FinancialProduct: Record "S4LA Financial Product";
            DimValue: Record "Dimension Value";
            AssetDimCode_ID: Integer;
            ContractActivate: Codeunit "S4LA Contract - Activate";
            cdContractActivate: Codeunit "S4LA Contract - Activate";
        begin
            //----- create FixedAsset
            if Asset."Asset No." = '' then begin
                cdContractActivate.CreateFixedAsset(Asset);  //Creates new OR maps with existing FA. [Asset].[Asset No.] points to [FA].[No.]
                GLSetup.Get();
                //BA211207 - Removed "S4LNA Dim ID - Asset".Asset code dimension to work for both global & shortcut dimensions.
                AssetDimCode_ID := 0;

                DimValue.Reset();
                DimValue.SetRange("Dimension Code", GLSetup."S4LNA Asset Dimension Code");
                DimValue.SetFilter("Global Dimension No.", '>%1', 0);
                if DimValue.FindFirst() then
                    AssetDimCode_ID := DimValue."Global Dimension No.";

                if AssetDimCode_ID <> 0 then
                    PurchaseHeader.ValidateShortcutDimCode(AssetDimCode_ID, Asset."Asset No.");
                PurchaseHeader.Modify();
            end;
            FinancialProduct.Get(Contract."Financial Product");
            if FinancialProduct."Create Fixed Assets" then begin
                //---//TG210318
                //UseFixedAsset := true;
                if Asset."Asset No." = '' then begin
                    ContractActivate.CreateFixedAsset(Asset);
                    Asset.Get(Asset."Contract No.", Asset."Line No.");
                end;
                PurchaseLine.Validate(Type, PurchaseLine.Type::"Fixed Asset");
                PurchaseLine.Validate("No.", Asset."Asset No.");
                PurchaseLine.Validate("VAT Prod. Posting Group", '');
                PurchaseLine.Validate(Quantity, 1);

                if Asset."S4LNA Purchase Cost" <> 0 then
                    PurchaseLine.Validate(PurchaseLine."Direct Unit Cost", Asset."S4LNA Purchase Cost")
                else //---//
                    PurchaseLine.Validate(PurchaseLine."Direct Unit Cost", Asset."Purchase Price");
                PurchaseLine.Validate("Tax Group Code", Asset."S4LNA Tax Group");
            end;
        end;

            [EventSubscriber(ObjectType::Report, Report::"S4LA Create PO from Applicat.", 'OnAfterPurchaseLineInsert', '', false, false)]
            local procedure CreatePOFromApplication_OnAfterPurchaseLineInsert(var PurchaseLine: Record "Purchase Line"; var PurchaseHeader: Record "Purchase Header"; Asset: Record "S4LA Asset"; Contract: Record "S4LA Contract"; Schedule: Record "S4LA Schedule"; var LineNo: Integer)
            begin

                if PurchaseHeader."S4LNA Asset No." = '' then begin
                    PurchaseHeader."S4LNA Asset No." := Asset."Asset No.";
                    PurchaseHeader.Modify();
                end;

            end;
            //PYAS-330 - Fix issue with closing outstanding
            [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Schedule Calc. - TValue", 'OnAfterSchedLineCreatedBeforeModify_CalcSchedule', '', false, false)]
           local procedure AfterSchedLineCreatedBeforeModify_CalcSchedule(var Schedule: Record "S4LA Schedule"; var Line: Record "S4LA Schedule Line")
            begin
                if Line."Closing Outstanding" < 0 then
                    Line."Closing Outstanding" := 0;

                if Line."Closing Outstanding Incl. VAT" < 0 then
                    Line."Closing Outstanding Incl. VAT" := 0;
            end;
            //--//
        */
}
