codeunit 17022114 "NA CheckQuoteValidations"
{
    trigger OnRun()
    begin
    end;

    var
        Text501: Label 'Quote no %1 has been expired as it was valid until %2';
        Text502: Label 'Program %1 is not yet active (can be used from %2)';
        Text503: Label 'Program %1 is expired (was valid until %2)';
        Text504: Label '%1 is missing';
        Text505: Label 'Applicant %1 age is below 18';
        Text506: Label '%1 can not be future date';
        Text513: Label 'Asset is missing on Quote';
        Text516: Label '%1 is not valid for Quote';
        Text518: Label 'Quote data validated.';
        Text519: Label 'Asset Logo Relation does not exist for Asset type %1¨ and Logo %2¨';
        Text522: Label '%1 is missing for Applicant %2.';
        WarningLog: Record "PYA Warning Log UI";
        Text600: Label 'Loan value is missing on Quote %1';

    local procedure "-- Event Handler"()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"S4LA Check Quote Validations", 'OnBeforecheck', '', false, false)]

    local procedure OnBeforecheck(Contr: Record "S4LA Contract"; var ishandled: Boolean)

    var
        Applicant: Record "S4LA Applicant";
        ContactIncome: Record "S4LA Applicant Income";
        ContactExpenditure: Record "S4LA Applicant Expenditure";
        ContactEmployment: Record "S4LA Applicant Employment";
        EmpolymentMonthsTotal: Integer;
        EmpolymentYearsTotal: Integer;
        ContactAltAddress: Record "Contact Alt. Address";
        AddressMonthsTotal: Integer;
        AddressYearsTotal: Integer;
        Asset: Record "S4LA Asset";
        Contact: Record Contact;
        ContactPerson: Record "S4LA Contact Person";
        ProgramRec: Record "S4LA Program";
        Sched: Record "S4LA Schedule";
        Programbuffer: Record "S4LA Program Selection Buffer";
        AssetGroup: Record "S4LA asset Group";
        ErrorText: Text;
        LeasingSetup: Record "S4LA Leasing Setup";
        RecRef: RecordRef;
        AssetCategory: Record "S4LA Asset Category";
        AssetModel: Record "S4LA Asset Model";
        FinProd: Record "S4LA Financial Product";
        Env: DotNet Environment;
    begin
        ishandled := true;

        LeasingSetup.Get;
        FinProd.Get(Contr."Financial Product");
        //--------------------------------------------- Check Quote fields
        //if (Contr."Quote Valid Until" < WorkDate) then
        //  WarningLog.Add(StrSubstNo(Text501, Contr."Contract No.", Contr."Quote Valid Until"), 3);

        if Contr."Financial Product" = '' then
            WarningLog.Add(StrSubstNo(Text504, Contr.FieldCaption("Financial Product")), 3);

        //if FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::Loan then
        //  if Contr."New / Used Asset" = 0 then
        //    WarningLog.Add(StrSubstNo(Text504, Contr.FieldCaption("New / Used Asset")), 3);

        //if Contr."Originator No." = '' then
        //WarningLog.Add(StrSubstNo(Text504, Contr.FieldCaption("Originator No.")), 3);

        //if Contr."Orig. Salesperson No." = '' then
        //  WarningLog.Add(StrSubstNo(Text504, Contr.FieldCaption("Orig. Salesperson No.")), 3);

        if Contr.Name = '' then
            WarningLog.Add(StrSubstNo(Text504, Contr.FieldCaption(Name)), 3);

        If Contr."E-Mail" = '' then
            WarningLog.Add(StrSubstNo(Text504, Contr.FieldCaption("E-Mail")), 2); //2 = not critical

        if Contr."Phone No." = '' then
            WarningLog.Add(StrSubstNo(Text504, Contr.FieldCaption("Phone No.")), 2); //2 = not critical


        //--------------------------------------------- Check Schedule fields
        Contr.GetNewestSchedule(Sched);

        if Sched.Term = '' then
            WarningLog.Add(StrSubstNo(Text504, Sched.FieldCaption(Term)), 3);

        if Sched.Frequency = '' then
            WarningLog.Add(StrSubstNo(Text504, Sched.FieldCaption(Frequency)), 3);

        if (Sched."Interest %" = 0) and (Sched."Annuity/Linear" = Sched."Annuity/Linear"::Annuity) then
            WarningLog.Add(StrSubstNo(Text504, Sched.FieldCaption(Sched."Interest %")), 3);


        //--------------------------------------------- Check Program
        if Sched."Program Code" = '' then begin
            WarningLog.Add(StrSubstNo(Text504, Sched.FieldCaption("Program Code")), 3);

        end else begin

            ProgramRec.Get(Sched."Program Code");
            ProgramRec.MakeProgramSelectionList(Contr."Originator Type", Contr."Contract Date", Contr."Quote Valid Until", '', Contr."Financial Product"
                                               , Contr."Contract No.", true, Sched."Program Code");
            Programbuffer.Reset;
            Programbuffer.SetRange("Contract No.", Contr."Contract No.");
            Programbuffer.SetRange("Program Code", Sched."Program Code");
            if Programbuffer.IsEmpty then
                WarningLog.Add(StrSubstNo(Text516, Sched.FieldCaption("Program Code"), Contr."Contract No."), 3);

            if (ProgramRec."Valid From" > Contr."Contract Date") then
                WarningLog.Add(StrSubstNo(Text502, ProgramRec.Code, ProgramRec."Valid From"), 3);

            if (ProgramRec."Valid Until" < Contr."Quote Valid Until") and (ProgramRec."Valid Until" <> 0D) then
                WarningLog.Add(StrSubstNo(Text503, ProgramRec.Code, ProgramRec."Valid Until"), 3);

        end;
        //--------------------------------------------- Check Applicant fields (Individual)
        Applicant.Reset;
        Applicant.SetRange("Contract No.", Contr."Contract No.");
        Applicant.SetRange("Individual/Business", Applicant."Individual/Business"::Individual);
        if Applicant.FindSet then
            repeat

                if Applicant."First Name" = '' then
                    WarningLog.Add(StrSubstNo(Text504, Applicant.FieldCaption(Applicant."First Name")), 3);

            until Applicant.Next = 0;

        //--------------------------------------------- Check Applicant fields (Business)
        Applicant.Reset;
        Applicant.SetRange("Contract No.", Contr."Contract No.");
        Applicant.SetRange("Individual/Business", Applicant."Individual/Business"::Business);
        if Applicant.FindSet then
            repeat
                if Applicant.Name = '' then
                    WarningLog.Add(StrSubstNo(Text504, Applicant.FieldCaption(Applicant.Name)), 3);
            until Applicant.Next = 0;


        //--------------------------------------------- Must have an asset record
        Asset.Reset;
        Asset.SetRange(Asset."Contract No.", Contr."Contract No.");
        if Asset.IsEmpty then begin
            if FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::Loan then
                WarningLog.Add(StrSubstNo(Text513, Applicant."Contract No."), 3)
            else
                WarningLog.Add(StrSubstNo(Text600, Applicant."Contract No."), 3);
        end;
        // <<

        //--------------------------------------------- Check Asset fields
        Asset.Reset;
        Asset.SetRange(Asset."Contract No.", Contr."Contract No.");
        if Asset.FindSet then
            repeat
                //PYAS-151 - Should only check manufacturer for assets
                if FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::Loan then begin
                    if Asset."Asset Brand" = '' then
                        WarningLog.Add(StrSubstNo(Text504, Asset.FieldCaption(Asset."Asset Brand")), 3);

                    //if FinProd."Fin. Product Type" <> FinProd."Fin. Product Type"::Loan then begin
                    //  if Asset."Asset Group" = '' then begin
                    //    RecRef.GetTable(AssetGroup);
                    //  if LeasingSetup.IsGranActive(RecRef) then
                    //    WarningLog.Add(StrSubstNo(Text504, Asset.FieldCaption(Asset."Asset Group")), 3);
                    //end;

                    //if Asset."Asset Category" = '' then begin
                    //  RecRef.GetTable(AssetCategory);
                    //if LeasingSetup.IsGranActive(RecRef) then
                    //  WarningLog.Add(StrSubstNo(Text504, Asset.FieldCaption(Asset."Asset Category")), 3);
                    //end;

                    ///if Asset."Asset New / Used" = Asset."Asset New / Used"::" " then
                    // WarningLog.Add(StrSubstNo(Text504, Asset.FieldCaption("Asset New / Used")), 3);
                end;
            until Asset.Next = 0;

        Commit;
        if WarningLog.HasWarnings then
            if GuiAllowed
                then
                WarningLog.ShowWarnings
            else
                WarningLog.MoveToSystemLog;
        if WarningLog.HasCriticalWarnings then
            Error('');
        WarningLog.ClearWarningLog;
    end;

}