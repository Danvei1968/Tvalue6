tableextension 17022192 "PYA Fixed Asset" extends "Fixed Asset"
{
    fields
    {
        field(17022090; "PYA Starting Mileage (km)"; Integer)
        {
            Caption = 'Starting Mileage';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            Var
                Ltxt01: Label 'Can''t be less than start';
            begin
                IF ("NA Ending Mileage (km)" <> 0) and ("NA Ending Mileage (km)" < "PYA Starting Mileage (km)") THEN
                    ERROR(Ltxt01);
            end;
        }
        //ML: ENU=Can't be less than start;FRC=Ne peut pas ùtre inférieur au début;ENC=Can't be less than start

        field(17022091; "NA Ending Mileage (km)"; Integer)
        {
            Caption = 'Ending Mileage';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            var
                Ltxt01: Label 'Can''t be less than start';
            //ML: ENU=Can't be less than start;FRC=Ne peut pas ùtre inférieur au début;ENC=Can't be less than start
            begin
                IF "NA Ending Mileage (km)" < "PYA Starting Mileage (km)" THEN
                    ERROR(Ltxt01);
            end;
        }
        field(17022092; "NA Return Date"; Date)
        {
            Caption = 'Return Date';
            DataClassification = ToBeClassified;
        }
        field(17022093; "NA Stock Date"; Date)
        {
            Caption = 'Stock Date';
            DataClassification = ToBeClassified;
        }
        field(17022094; "NA Plates End Date"; Date)
        {
            Caption = 'Plates End Date';
            DataClassification = ToBeClassified;
        }
        field(17022095; "NA Key Code"; Text[30])
        {
            Caption = 'Key Code';
            DataClassification = ToBeClassified;
        }
        field(17022096; "PYA Interior Color"; Text[30])
        {
            Caption = 'Interior Color';
            DataClassification = ToBeClassified;
        }
        field(17022097; "PYA Color Of Vehicle"; Text[30])
        {
            Caption = 'Color Of Vehicle';
            DataClassification = ToBeClassified;
        }
        field(17022180; "PYA License Plate State"; Code[30])
        {
            Caption = 'License Plate State';
            TableRelation = "Country/Region";
        }
        field(17022181; "PYA Registration Renewals"; Boolean)
        {
            Caption = 'Registration Renewals';
        }
        field(17022182; "PYA Temporary Plate"; Boolean)
        {
            Caption = 'Temporary Plate';
        }

        field(17022183; "PYA Plates Date Paid"; Date)
        {
            Caption = 'Plates Date Paid';
        }
        field(17022184; "PYA Plates Reg. Fee"; Decimal)
        {
            Caption = 'Registration Fee';
        }
        field(17022185; "PYA Plates Date Sent Tags"; Date)
        {
            Caption = 'Date Sent Tags';
        }
        field(17022186; "PYA Previous Plate No."; Code[20])
        {
            Caption = 'Previous Plate No.';
        }
        field(17022187; "PYA Previous Plate State"; Code[30])
        {
            Caption = 'Previous Plate State';
            TableRelation = "Country/Region";
        }
        //BA220301
        field(17022188; "PYA Capacity"; Decimal)
        {
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            BlankZero = true;
        }
        //BA220406
        field(17022189; "Stock No. (External)"; code[20])
        {
            caption = 'Stock No. (External)';
        }
        field(17022190; "PYA Model Year"; Integer)
        {
            caption = 'PYA Model Year';
            MinValue = 1900;
            MaxValue = 9999;
        }
        field(17022191; "PYA Asset Brand"; code[20])
        {
            caption = 'PYA Asset Brand';
            TableRelation = "S4LA Brand";
        }
        field(17022192; "PYA Asset Model"; Code[20])
        {
            caption = 'PYA Asset Model';
            TableRelation = "S4LA Asset Model";
        }
        field(17022193; "PYA Trim"; Code[20])
        {
            caption = 'Trim';
        }
        field(17022194; "PYA Contract No"; Code[20])
        {
            caption = 'Contract';
            TableRelation = "S4LA Contract"."Contract No.";
        }
        field(17022195; "PYA Asset Status Code"; Code[20])
        {
            caption = 'Asset Status Code';
            TableRelation = "S4LA Status".Code WHERE("Target Table ID" = CONST(5600));
        }
        field(17022196; "PYA Book Value"; Decimal)
        {
            caption = 'Book Value';
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = Sum("FA Ledger Entry".Amount WHERE("FA No." = FIELD("No."),
                                                              "FA Posting Date" = FIELD(UPPERLIMIT("FA Posting Date Filter"))));
            TableRelation = "S4LA Status".Code WHERE("Target Table ID" = CONST(5600));
        }

        field(17022197; "PYA Customer No"; Code[20])
        {
            caption = 'Contact';
            TableRelation = Contact."No.";
        }
        field(17022198; "PYA Licence Plate No."; Code[30])
        {
            Caption = 'License Plate';
            //TableRelation = "Country/Region";
        }
        field(1702219; "PYA Vin"; Code[20])
        {
            caption = 'Vin';
        }
        field(17022200; "PYA Acquisition Cost"; Decimal)
        {
            AutoFormatType = 1;
            FieldClass = FlowField;
            Editable = false;
            CalcFormula = sum("FA Ledger Entry".Amount where("FA No." = field("No."),
                                                             "FA Posting Category" = const(" "),
                                                             "FA Posting Type" = const("Acquisition Cost"),
                                                             "FA Posting Date" = field("FA Posting Date Filter")));
        }

        field(17022201; "PYA Balance at Date"; Decimal)
        {
            Caption = 'Balance to Date';
            AutoFormatType = 1;
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = Sum("G/L Entry".Amount WHERE("G/L Account No." = FIELD("No."),
                                                                "G/L Account No." = FIELD(FILTER(Totaling)),
                                                                //"PYA G/L Account No." = FIELD(FILTER(Totaling)),
                                                                "Business Unit Code" = FIELD("Business Unit Filter"),
                                                                "Global Dimension 1 Code" = FIELD("Global Dimension 1 Filter"),
                                                                "Global Dimension 2 Code" = FIELD("Global Dimension 2 Filter"),
                                                                "Posting Date" = FIELD(UPPERLIMIT("FA Posting Date Filter")),
                                                                //"PYA Posting Date" = FIELD(UPPERLIMIT("FA Posting Date Filter")),
                                                                //"PYA Contract No" = FIELD("PYA Contract Filter"),
                                                                "Document No." = FIELD("PYA Document No Filter")));
        }
        field(17022202; Totaling; Text[250])
        {
            Caption = 'Totaling';
            FieldClass = FlowFilter;
        }
        field(17022203; "Business Unit Filter"; text[100])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
        }
        field(17022204; "Global Dimension 1 Filter"; text[100])
        {
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(17022205; "Global Dimension 2 Filter"; text[100])
        {
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(17022206; "PYA Contract Filter"; text[100])
        {
            Caption = 'PYA Contract Filter';
            FieldClass = FlowFilter;
        }
        field(17022207; "PYA Document No Filter"; text[100])
        {
            Caption = 'PYA Document No Filter';
            FieldClass = FlowFilter;
        }
        field(17022208; "S4L Fin. Product Code"; CODE[20])
        {
            Caption = 'Fin. Product Code';
            TableRelation = "S4LA Financial Product";
        }

        //modify("Asset Status Trigger")
        //{
        //    OptionCaption = 'Internal Fixed Asset,Lease Asset,Stock,Sold';
        //}
        //modify("S4L Starting Mileage (km)")
        //{
        //    Caption = 'Starting Mileage';
        //}
        //modify("S4L Starting Mileage Date")
        //{
        //    Caption = 'Starting Mileage Date';
        //}

        modify(Description)
        {
            trigger OnAfterValidate()
            begin
                Description := COPYSTR(Description, 1, MAXSTRLEN(Description));
            end;
        }

        modify("PYA Asset Brand")
        {
            trigger OnAfterValidate()
            begin
                IF "PYA Asset Brand" <> xRec."PYA Asset Brand" THEN BEGIN
                    //"S4L Asset Description" := '';
                    REC."PYA Trim" := ''; //TG200828
                END;
                BuildDescription; //TG200828
            end;

        }
        modify("PYA Asset Model")
        {
            trigger OnAfterValidate()
            begin
                IF "PYA Asset Model" <> xRec."PYA Asset Model" THEN BEGIN
                    //"S4L Asset Description" := '';
                END;
                BuildDescription; //TG200828
            end;
        }

        modify("PYA Model Year")
        {
            trigger OnAfterValidate()
            begin
                BuildDescription; //TG200828
            end;
        }
    }
    trigger OnAfterInsert()
    begin
        //SM181010 - Start
        //Create Dimension for asset
        CreateAssetDimensionValue("No.");

    end;

    trigger OnAfterRename()
    begin

        //SM181010 - Start
        //Create Dimension for asset
        RenameAssetDimensionValue("No.", xRec."No.");
        //---
    end;

    [Scope('OnPrem')]
    local procedure CreateAssetDimensionValue(AssetNo: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        DimensionDefault: Record "Default Dimension";
    begin
        GLSetup.GET;
        GLSetup.TESTFIELD("NA Asset Dimension Code");

        IF NOT DimensionValue.GET(GLSetup."NA Asset Dimension Code", AssetNo) THEN BEGIN
            DimensionValue.INIT;
            DimensionValue."Dimension Code" := GLSetup."NA Asset Dimension Code";
            DimensionValue.Code := AssetNo;
            DimensionValue.INSERT(TRUE);
        END;

        DimensionDefault.INIT;
        DimensionDefault."Table ID" := Database::"Fixed Asset";
        DimensionDefault."No." := AssetNo;
        DimensionDefault."Dimension Code" := GLSetup."NA Asset Dimension Code";
        DimensionDefault."Dimension Value Code" := AssetNo;
        DimensionDefault.INSERT;
    end;

    procedure BuildDescription()
    var
        AssetModel: Record "s4la Asset Model";
        Txt: Text;
        AssetManuf: Record "s4la Asset Brand";
        AssetGrp: Record "s4la Asset Group";
        AssetCat: Record "s4la Asset Category";
    begin
        //S4L
        Txt := '';
        //BA220326
        if Rec."PYA Model Year" <> 0 then
            Txt := format(Rec."PYA Model Year");

        If Rec."pya Asset Brand" <> '' then
            Txt := Txt + ' ' + Rec."pya Asset Brand";

        if rec."PYA Asset Model" <> '' then
            Txt := Txt + ' ' + rec."PYA Asset Model";

        if rec."PYA Trim" <> '' then
            Txt := txt + ' ' + rec."PYA Trim";

        //-//
        Description := COPYSTR(Txt, 1, MAXSTRLEN(Description));
        //"S4L Asset Description" := COPYSTR(Txt, 1, MAXSTRLEN("S4L Asset Description"));
        //Description := "S4L Asset Description";
    end;

    procedure PYAUpdateDeprBook()
    var
        FAbook: Record "FA Depreciation Book";
        LeasingPostingSetup: Record "S4LA Leasing Posting Setup";
        FinProduct: Record "S4LA Financial Product";
        isHandled: Boolean; //S4L.NA
    begin
        //S4LAFixedAsset_OnUpdateDeprBook(Rec, isHandled); //S4L.NA
        if isHandled then //S4L.NA
            exit; //S4L.NA

        if not FinProduct.Get("S4L Fin. Product Code") then
            exit;
        if FinProduct."Create Fixed Assets" then
            FinProduct.TestField("FA Depreciation Book Code")
        else
            exit;
    end;

    local procedure RenameAssetDimensionValue(AssetNo: Code[20]; OldAssetNo: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        GLSetup: Record "General Ledger Setup";
        DimensionDefault: Record "Default Dimension";
    begin
        GLSetup.GET;
        GLSetup.TESTFIELD("NA Asset Dimension Code");

        DimensionDefault.RESET;
        DimensionDefault.SETRANGE("Table ID", 5600);
        DimensionDefault.SETRANGE("No.", OldAssetNo);
        DimensionDefault.SETRANGE("Dimension Code", GLSetup."NA Asset Dimension Code");
        IF DimensionDefault.FINDFIRST THEN
            DimensionDefault.DELETE;

        IF DimensionValue.GET(GLSetup."NA Asset Dimension Code", OldAssetNo) THEN BEGIN
            DimensionValue.DELETE;

        END;

        IF NOT DimensionValue.GET(GLSetup."NA Asset Dimension Code", AssetNo) THEN BEGIN
            DimensionValue.INIT;
            DimensionValue."Dimension Code" := GLSetup."NA Asset Dimension Code";
            DimensionValue.Code := AssetNo;
            DimensionValue.INSERT(TRUE);
        END;

        DimensionDefault.INIT;
        DimensionDefault."Table ID" := 5600;
        DimensionDefault."No." := AssetNo;
        DimensionDefault."Dimension Code" := GLSetup."NA Asset Dimension Code";
        DimensionDefault."Dimension Value Code" := AssetNo;
        DimensionDefault.INSERT;
    end;

    procedure Paddinglookup()
    var
        FaJnlTemp: Record "FA Journal Template";
        GLE: Record "G/L Entry";
        FAE: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";

    begin
        FASetup.Get;
        FaJnlTemp.FindFirst;
        FAE.Reset;
        FAE.SetRange(FAE."FA No.", "No.");
        //FAE.SETRANGE("Asset Padding",TRUE);
        if FAE.FindFirst then
            PAGE.run(5604, fae);
    end;
}
