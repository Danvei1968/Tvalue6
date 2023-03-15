tableextension 17022121 "PYA Leasing Posting Setup Ext." extends "S4LA Leasing Posting Setup"
{
    fields
    {
        field(17022090; "NA Ref Security Deposit"; Code[20])
        {
            Caption = 'Ref. Security Deposit';
            Description = 'JM170628';
            TableRelation = "G/L Account";
        }
        field(17022091; "NA Ref Sec. Deposit Tax Grp"; Code[20])
        {
            Caption = 'Ref. Security Deposit Tax Group';
            Description = 'JM170628';
            TableRelation = "VAT Product Posting Group";
        }
        field(17022103; "Op. Lease Inventory (BS) - Tm"; code[20])
        {
            Caption = 'Op. Lease Inventory (BS) - Termination';
            TableRelation = "FA Posting Group";
        }
        //BA220427
        field(17022104; "HP Asset Clearing Account"; code[20])
        {
            Caption = 'HP Asset Clearing PG';
            TableRelation = "FA Posting Group";
        }
        //--//
        //BA220609
        field(17022105; "Gain/Loss on Early Settlement"; code[20])
        {
            Caption = 'Gain/Loss on Early Settlement';
            TableRelation = "G/L Account";
        }
        field(17022106; "Receivables Type"; Enum "S4LA Leasing Receivables Type")
        {
            Caption = 'Receivables Type';
        }
        //--//
    }

    //BA220406 
    procedure S4LNAGetTermSetupRec(var recSetupLine: Record "S4LA Leasing Posting Setup"; ContractNo: Code[20])
    var
        Asset: Record "S4LA Asset";
        FA: Record "Fixed Asset";
        Contract: Record "S4LA Contract";
        Contact: Record Contact;
    begin
        /*DV170818*/
        IF isGlobalSilentMode() THEN BEGIN
            IF NOT Contract.GET(ContractNo) THEN CLEAR(Contract);
            IF NOT Contact.GET(Contract."Customer No.") THEN CLEAR(Contact);
        END ELSE BEGIN
            Contract.GET(ContractNo);
            Contact.GET(Contract."Customer No.");
        END;

        CLEAR(FA);
        Asset.RESET;
        Asset.SETRANGE("Contract No.", Contract."Contract No.");
        IF Asset.FINDFIRST THEN
            IF FA.GET(Asset."Asset No.") THEN;

        recSetupLine.SETFILTER("Fin. Product", '%1|%2', Contract."Financial Product", '');

        // recSetupLine.SETFILTER("FA Class Code", '%1|%2', FA."FA Class Code", '');
        // recSetupLine.SETFILTER("Customer category", '%1|%2', Contact."S4L Contact Category", '');
        // recSetupLine.SETRANGE(recSetupLine."Lease Status", recSetupLine."Lease Status"::Termination);
        case Contract."Individual/Business" of
            Contract."Individual/Business"::Business:
                recSetupLine.SetRange("Individual/Busines", recSetupLine."Individual/Busines"::Business);
            Contract."Individual/Business"::Individual:
                recSetupLine.SetRange("Individual/Busines", recSetupLine."Individual/Busines"::Individual);
        end;
        if recSetupLine.IsEmpty then
            recSetupLine.SetRange("Individual/Busines", recSetupLine."Individual/Busines"::All);

        IF isGlobalSilentMode() THEN BEGIN
            IF NOT recSetupLine.FINDLAST THEN CLEAR(recSetupLine);
        END ELSE
            recSetupLine.FINDLAST;
        /*---*/
    end;
    //--//
}