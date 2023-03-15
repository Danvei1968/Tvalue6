Codeunit 17022091 "PYA Common Functions"
{
    //BA210627
    procedure RefreshQuickQuoteServices(var QuickQuoteWkSht: record "Quick Quote Worksheet")

    var
        confrmTxt: Label 'Are you sure you want to refresh the quick quote services?';
        servicePackage: record "S4LA Service Package";
        ServicePackageLines: Record "S4LA Service Package Line";
        QuickQuoteService: RECORD "Quick Quote Service";
        Contr: record "S4LA contract";
        //QuickQuoteService: record "Quick Quote Service";
        ContractServices: record "S4LA Contract Service";
        LineNo: Integer;
        Services: record "S4LA service";

    begin

        if not confirm(confrmTxt, false) then
            exit;

        contr.get(QuickQuoteWkSht."Contract No.");

        //check mandatory fields
        contr.TestField("Financial Product");
        QuickQuoteWkSht.TestField("Quote1 Program Code");
        QuickQuoteWkSht.TestField("Quote1 Manufacturer");
        QuickQuoteWkSht.TestField("Quote1 Model");


        ServicePackage.Reset;
        ServicePackage.SetFilter("Valid From", '1%|..%2', 0D, Contr."Contract Date");
        ServicePackage.SetFilter("Valid Until", '%1|%2..', 0D, Contr."Contract Date");

        //----First priority -  Filter by Model-Category-Group-Type hierarchy
        ServicePackage.SetRange("Asset Model", quickQuoteWksht."Quote1 Model");
        if ServicePackage.IsEmpty then begin
            ServicePackage.SetRange("Asset Model", '');
            ServicePackage.SetRange("Asset Brand", quickQuoteWksht."Quote1 Manufacturer");
            if ServicePackage.IsEmpty then begin
                ServicePackage.SetRange("Asset Brand", '');

            end;
        end;
        //end;

        //----Second priority - Filter by Program - FinProduct - Consumer/Commercial (no hierarchy)
        //BA211008 - Changed "Customer Category" field to "Individual/Business" and also the options
        ServicePackage.SetFilter("Financial Product", '%1|%2', '', Contr."Financial Product");
        ServicePackage.SetFilter("Program Code", '%1|%2', '', QuickQuoteWkSht."Quote1 Program Code");
        case Contr."Individual/Business" of
            Contr."Individual/Business"::Individual:
                ServicePackage.SetFilter("Individual/Business", '%1|%2', ServicePackage."Individual/Business"::Any, ServicePackage."Individual/Business"::Individual);
            Contr."Individual/Business"::Business:
                ServicePackage.SetFilter("Individual/Business", '%1|%2', ServicePackage."Individual/Business"::Any, ServicePackage."Individual/Business"::Business);
            else
                ServicePackage.SetRange("Individual/Business");
        end;
        //--//
        if ServicePackage.FindLast then begin

            //-------------- Cleanup existing services, preserve manual overrides
            QuickQuoteService.Reset;
            QuickQuoteService.SetRange("Contract No.", QuickQuoteWkSht."Contract No.");
            QuickQuoteService.SetRange(Accessory, false);
            QuickQuoteService.SetRange("Quick Quote No.", 1);
            QuickQuoteService.setrange("Service Type", QuickQuoteService."Service Type"::Services);
            QuickQuoteService.DeleteAll;


            //-------------- Insert Services from the Package
            ServicePackageLines.Reset;
            ServicePackageLines.SetRange("Service Package No.", ServicePackage."Service Package No.");
            ServicePackageLines.SetFilter("Payment Due", '%1|%2|%3', ServicePackageLines."Payment Due"::"Included in Installment",
            ServicePackageLines."Payment Due"::"Included in Financed Amount", ServicePackageLines."Payment Due"::"With Upfront Fees");
            if ServicePackageLines.FindSet then
                repeat

                    QuickQuoteService.Reset;
                    QuickQuoteService.SetRange("Contract No.", QuickQuoteWkSht."Contract No.");
                    QuickQuoteService.SetRange(Code, ServicePackageLines."Service Code");
                    QuickQuoteService.SetRange(Accessory, false);
                    QuickQuoteService.SetRange("Quick Quote No.", 1);
                    QuickQuoteService.setrange("Service Type", QuickQuoteService."Service Type"::Services);
                    if QuickQuoteService.IsEmpty then begin

                        quickQuoteService.init;
                        quickQuoteService."Contract No." := QuickQuoteWkSht."Contract No.";
                        quickQuoteService."Quick Quote No." := 1;
                        quickQuoteService.Accessory := false;
                        QuickQuoteService."Payment Due" := ServicePackageLines."Payment Due";
                        QuickQuoteService.Code := ServicePackageLines."Service Code";
                        QuickQuoteService."Service Type" := QuickQuoteService."Service Type"::Services;
                        QuickQuoteService.insert(True);

                        //Update service price from Service price table
                        updateServicePrice(QuickQuoteService, QuickQuoteWkSht);

                        //Validate Quick Quote worksheet fields
                        case
                            QuickQuoteService."Payment Due"
                            of
                            QuickQuoteService."Payment Due"::"Included in Financed Amount":
                                QuickQuoteService.UpdateQuickQuoteServices(1, QuickQuoteWkSht);

                            QuickQuoteService."Payment Due"::"Included in Installment":
                                QuickQuoteService.UpdateQuickQuoteMonthlyFees(1, QuickQuoteWkSht);

                            QuickQuoteService."Payment Due"::"With Upfront Fees":
                                QuickQuoteService.UpdateQuickQuoteUpfrontServ(1, QuickQuoteWkSht);

                        end;
                    end;
                until ServicePackageLines.Next = 0;
        end; //if service package found
    end;

    procedure UpdateServicePrice(Var QuickQuoteServ: Record "Quick Quote Service"; var quickQuoteWksht: record "Quick Quote Worksheet")
    var
        ServicePrice: record "S4LA Service Price";
        contr: Record "S4LA Contract";

    begin
        contr.get(QuickQuoteServ."Contract No.");

        ServicePrice.Reset;
        ServicePrice.SetCurrentKey("Service Code", "Asset Age (end of Contract)", "Mileage Limit (per Contract)"); // sorting important
        ServicePrice.SetRange("Service Code", QuickQuoteServ.Code);
        ServicePrice.SetFilter("Price Valid From", '%1|..%2', 0D, Contr."Contract Date");
        ServicePrice.SetFilter("Price Valid Until", '%1|%2..', 0D, Contr."Contract Date");

        //----First priority -  Filter by Model-Category-Group-Type hierarchy
        ServicePrice.SetRange("Asset Model", quickQuoteWksht."Quote1 Model");
        if ServicePrice.IsEmpty then begin
            ServicePrice.SetRange("Asset Model", '');
            ServicePrice.SetRange("Asset Brand", quickQuoteWksht."Quote1 Manufacturer");
            if ServicePrice.IsEmpty then begin
                ServicePrice.SetRange("Asset Brand", '');

            end;
        end;

        //----Second priority - Filter by Program - FinProduct - Consumer/Commercial (no hierarchy)
        ServicePrice.SetFilter("Financial Product", '%1|%2', '', contr."Financial Product");
        ServicePrice.SetFilter("Program Code", '%1|%2', '', quickQuoteWksht."Quote1 Program Code");
        case Contr."Individual/Business" of
            Contr."Individual/Business"::Individual:
                ServicePrice.SetFilter("Customer Category", '%1|%2', ServicePrice."Customer Category"::Any, ServicePrice."Customer Category"::Consumer);
            Contr."Individual/Business"::Business:
                ServicePrice.SetFilter("Customer Category", '%1|%2', ServicePrice."Customer Category"::Any, ServicePrice."Customer Category"::Commercial);
            else
                ServicePrice.SetRange("Customer Category", ServicePrice."Customer Category"::Any);
        end;


        if not ServicePrice.FindLast then
            exit;

        //Should be just one of the two - either Annual price or flat price per lease. If both prices in setup - then "per Lease" shall prevail

        if ServicePrice."Service Cost (Annual)" <> 0 then
            QuickQuoteServ."Total Amount" := ServicePrice."Service Cost (Annual)" / 12;

        if ServicePrice."Service Cost (per Contract)" <> 0 then
            QuickQuoteServ."Total Amount" := ServicePrice."Service Cost (per Contract)";

        QuickQuoteServ.Modify;
    end;

    procedure FullMonths(FromDate: Date; ToDate: Date) NoOfMonths: Integer;
    var
        D0: Integer;
        M0: Integer;
        Y0: Integer;
        D1: Integer;
        M1: Integer;
        Y1: Integer;
    //NoOfMonths: Integer;
    begin
        NoOfMonths := 0;
        IF FromDate = 0D THEN
            EXIT(0);

        IF ToDate = 0D THEN
            EXIT(0);

        IF ToDate <= FromDate THEN
            EXIT(0);

        D0 := DATE2DMY(FromDate, 1);
        M0 := DATE2DMY(FromDate, 2);
        Y0 := DATE2DMY(FromDate, 3);

        D1 := DATE2DMY(ToDate, 1);
        M1 := DATE2DMY(ToDate, 2);
        Y1 := DATE2DMY(ToDate, 3);

        IF D1 < D0 THEN
            NoOfMonths := -1;
        NoOfMonths += M1 - M0;
        NoOfMonths += (Y1 - Y0) * 12;

        EXIT(NoOfMonths);
    end;
}
