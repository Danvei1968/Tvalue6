codeunit 17022092 "NA Sales Inv. From Purch. Inv."
{
    // TG190515 - to be called if checkbox "Re-post to Receivable" is filled into Purchase Invoice


    trigger OnRun()
    begin
    end;

    var
        TypeNotSupportedErr: Label 'Type %1 is not supported.', Comment = 'Line or Document type';
        Contract: Record "S4LA Contract";
        LeasingSetup: Record "S4LA Leasing Setup";

    procedure CreateSalesInvoice(var PurchHeader: Record "Purchase Header")
    var
        Cust: Record "Customer";
        SalesHeader: Record "Sales Header";
        PurchLine: Record "Purchase Line";
    begin
        Cust.GET(PurchHeader."Sell-to Customer No.");
        Contract.GET(PurchHeader."PYA Contract No");
        LeasingSetup.GET;
        CreateSalesHeader(SalesHeader, PurchHeader, Cust);
        CopyPurchLinesToSalesLines(SalesHeader, PurchHeader);
        PurchHeader."NA Sales Invoice No." := SalesHeader."No.";
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; PurchHeader: Record "Purchase Header"; Cust: Record "Customer")
    begin
        SalesHeader.INIT;
        SalesHeader.VALIDATE("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.InitRecord;
        SalesHeader.VALIDATE("Sell-to Customer No.", Cust."No.");
        SalesHeader.VALIDATE("PYA Contract No", Contract."Contract No.");
        IF PurchHeader."Shortcut Dimension 1 Code" <> '' THEN
            SalesHeader.VALIDATE("Shortcut Dimension 1 Code", PurchHeader."Shortcut Dimension 1 Code");
        IF PurchHeader."Shortcut Dimension 2 Code" <> '' THEN
            SalesHeader.VALIDATE("Shortcut Dimension 2 Code", PurchHeader."Shortcut Dimension 2 Code");
        //SalesHeader.VALIDATE("S4L Sales Invoice Type", LeasingSetup."Default Sales Invoice Type");
        SalesHeader.VALIDATE("External Document No.", PurchHeader."Vendor Invoice No.");
        //SalesHeader.VALIDATE("Current Odometer",PurchHeader."Current Odometer");
        SalesHeader.INSERT(TRUE);
    end;

    local procedure CopyPurchLinesToSalesLines(SalesHeader: Record "Sales Header"; PurchHeader: Record "Purchase Header")
    var
        SalesLine: Record "Sales Line";
        SalesLineNo: Integer;
        PurchLine: Record "Purchase Line";
    begin
        SalesLineNo := 0;

        PurchLine.SETRANGE("Document Type", PurchHeader."Document Type");
        PurchLine.SETRANGE("Document No.", PurchHeader."No.");
        //PurchLine.SETRANGE("S4L Re-post to Receivable", TRUE);

        IF PurchLine.FINDSET THEN
            REPEAT
                CLEAR(SalesLine);
                SalesLine.INIT;
                SalesLine."Document No." := SalesHeader."No.";
                SalesLine."Document Type" := SalesHeader."Document Type";

                SalesLineNo += 10000;
                SalesLine."Line No." := SalesLineNo;

                CASE PurchLine.Type OF
                    PurchLine.Type::" ":
                        SalesLine.Type := SalesLine.Type::" ";
                    PurchLine.Type::"G/L Account":
                        SalesLine.Type := SalesLine.Type::"G/L Account";
                    ELSE
                        ERROR(TypeNotSupportedErr, FORMAT(PurchLine.Type));
                END;

                SalesLine.VALIDATE("No.", PurchLine."No.");
                SalesLine.Description := PurchLine.Description;

                IF SalesLine."No." <> '' THEN BEGIN
                    SalesLine.VALIDATE("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
                    SalesLine.VALIDATE("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
                    //SalesLine.VALIDATE("S4L Contract No.", SalesHeader."S4L Contract No.");
                    SalesLine.VALIDATE(Quantity, PurchLine.Quantity);
                    SalesLine.VALIDATE("Unit of Measure Code", PurchLine."Unit of Measure Code");
                    SalesLine.VALIDATE("Unit Price", PurchLine."Direct Unit Cost");
                    SalesLine."Dimension Set ID" := PurchLine."Dimension Set ID";
                    //SalesLine."Vendor No." := PurchHeader."Buy-from Vendor No.";
                    //SalesLine."Current Odometer" := PurchLine."Current Odometer";
                END;

                SalesLine.INSERT(TRUE);
            UNTIL PurchLine.NEXT = 0;
    end;
}