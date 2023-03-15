tableextension 17022092 "PYA Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(52004; "PYA Contract No"; Code[20])
        {
            Caption = 'Contract No.';
            DataClassification = ToBeClassified;
            TableRelation = "S4LA Contract"."Contract No.";
        }
        field(17022090; "NA Purchase for"; Option)
        {
            Caption = 'Purchase for';
            DataClassification = ToBeClassified;
            Description = 'SM130528';
            OptionMembers = " ",Stock,Lease,Other;

            trigger OnValidate()
            var
                ltext000: Label 'You cannot change the value of the Purchase For fields when the asset no. is specified.';
            begin
                IF "NA Asset No." <> '' THEN ERROR(ltext000);
            end;
        }
        field(17022091; "NA Asset No."; Code[20])
        {
            Caption = 'Asset No.';
            DataClassification = ToBeClassified;
            Description = 'EN121108';
            TableRelation = "Fixed Asset";

            trigger OnLookup()
            var
                AssetListPage: Page "S4LA Fixed Assets";
                FixedAsset: Record "Fixed Asset";
                LeasingSetup: Record "S4LA Leasing Setup";
            begin
                LeasingSetup.GET;
                AssetListPage.LOOKUPMODE := TRUE;
                AssetListPage.SETTABLEVIEW(FixedAsset);
                IF AssetListPage.RUNMODAL = ACTION::LookupOK THEN BEGIN
                    AssetListPage.GETRECORD(FixedAsset);
                    VALIDATE("NA Asset No.", FixedAsset."No.");
                END;
            end;

            trigger OnValidate()
            var
                FixedAsset: Record "Fixed Asset";
            begin
                IF "NA Asset No." <> '' THEN BEGIN
                    FixedAsset.GET("NA Asset No.");
                    "Posting Description" := COPYSTR(FixedAsset.Description, 1, MAXSTRLEN("Posting Description"));
                    "NA Model Year" := FixedAsset."PYA Model Year";
                    "NA FA Class Code" := FixedAsset."FA Class Code";
                    "NA Trim" := FixedAsset."PYA Trim";//DV190215
                                                       //"Color Of Vehicle" := FixedAsset."Color Of Vehicle";
                                                       //"Color Of Interior" := FixedAsset."S#Color Of Interior";
                                                       //"Starting Mileage (km)" := FixedAsset."Starting Mileage (km)";
                                                       //"Car Make Code" := FixedAsset."Car Make Code";
                                                       //"Car Model" := FixedAsset."Car Model";
                                                       //"New / Used Asset" := FixedAsset."New / Used Asset";
                                                       //"Identification No." := FixedAsset."Identification No.";
                END;
            end;
        }
        field(17022092; "NA Model Year"; Integer)
        {
            Caption = 'Model Year';
            DataClassification = ToBeClassified;
            Description = 'EN121108';

            trigger OnValidate()
            var
                recAsset: Record "Fixed Asset";
            begin
                IF ("NA Model Year" <> xRec."NA Model Year") THEN BEGIN
                    BuildPostingDescription(); /*EN121219*/
                    IF recAsset.GET("NA Asset No.") THEN BEGIN
                        recAsset.VALIDATE("PYA Model Year", "NA Model Year");
                        recAsset.MODIFY;
                    END;
                END;

            end;
        }
        field(17022093; "NA S#Car Make Code"; Code[20])
        {
            Caption = 'Car Make Code';
            DataClassification = ToBeClassified;
            Description = 'EN120710';
            TableRelation = "S4LA Asset Brand";
            trigger OnValidate()
            BEGIN
                /*TG200903*/
                IF "NA S#Car Make Code" <> xRec."NA S#Car Make Code" THEN BEGIN
                    BuildPostingDescription;
                END;
                /*---*/
            END;
        }
        field(17022094; "NA S#Car Model"; Text[50])
        {
            Caption = 'Car Model';
            DataClassification = ToBeClassified;
            Description = 'EN120710';
            trigger OnValidate()
            BEGIN
                /*TG200903*/
                IF "NA S#Car Model" <> xRec."NA S#Car Model" THEN BEGIN
                    BuildPostingDescription;
                END;
                /*---*/
            END;
        }
        field(17022095; "NA Asset New / Used"; Option)
        {
            Caption = 'New / Used Asset';
            DataClassification = ToBeClassified;
            Description = 'EN121108';
            OptionMembers = " ",New,Used;

            trigger OnValidate()
            var
                recAsset: Record "Fixed Asset";
            begin
                //IF ("NA Asset New / Used" <> xRec."NA Asset New / Used") THEN BEGIN
                //    IF recAsset.GET("NA Asset No.") THEN BEGIN
                //        recAsset.VALIDATE("S4L Asset New / Used", "NA Asset New / Used");
                //        recAsset.MODIFY;
                //    END;
            END;

        }
        field(17022096; "NA Starting Mileage (km)"; Integer)
        {
            Caption = 'Starting Mileage';
            DataClassification = ToBeClassified;
        }
        field(17022097; "NA Color Of Vehicle"; Text[30])
        {
            Caption = 'Color Of Vehicle';
            DataClassification = ToBeClassified;
        }
        field(17022098; "NA S#Color Of Interior"; Text[30])
        {
            Caption = 'Color Of Interior';
            DataClassification = ToBeClassified;
            Description = 'EN120710';
        }
        field(17022099; "NA VIN"; Code[30])
        {
            Caption = 'VIN';
            DataClassification = ToBeClassified;
            Description = 'Identification No. renamed to VIN';
        }
        field(17022100; "NA FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            DataClassification = ToBeClassified;
            TableRelation = "FA Class";

            trigger OnValidate()
            var
                FASubclass: Record "FA Subclass";
                recContract: Record "S4LA Contract";
            begin
            end;
        }
        field(17022101; "NA Trim"; Text[30])
        {
            Caption = 'Trim';
            DataClassification = ToBeClassified;
            trigger OnValidate()
            BEGIN
                /*TG200903*/
                IF "NA Trim" <> xRec."NA Trim" THEN BEGIN
                    BuildPostingDescription;
                END;
                /*---*/
            END;
        }
        field(17022102; "NA Sales Invoice No."; Code[20])
        {
            Caption = 'Sales Invoice No.';
            DataClassification = ToBeClassified;
            Description = 'TG190516 - for rebilling receivables';
            TableRelation = "Sales Header"."No.";
        }

    }

    procedure BuildPostingDescription()
    VAR
        Txt: Text;
        AssetModel: Record "S4LA Asset Model";
        AssetManuf: Record "S4LA Asset Brand";
        AssetGrp: Record "S4LA Asset Group";
    BEGIN
        /*TG200903*/
        //"Posting Description" := COPYSTR(FORMAT("Model Year",0) + ' '+"S#Car Make Code" + ' ' + "S#Car Model"+ ' ' + Trim, 1,
        //                       MAXSTRLEN("Posting Description"));

        //S4L
        Txt := '';

        //IF AssetModel.GET("S#Car Model") THEN BEGIN
        IF AssetModel.GET("NA S#Car Model") THEN //DV200918
            Txt := AssetModel."Model Description";
        //END ELSE BEGIN
        // if model not in list (manual entry) then compose asset description
        IF AssetManuf.GET("NA S#Car Make Code") THEN
            IF AssetManuf.Description <> '' THEN
                Txt += AssetManuf.Description + ' ';
        //IF AssetGrp.GET("Asset Group") THEN
        //  IF AssetGrp."Asset Group Descr." <> '' THEN
        //    Txt +=  AssetGrp."Asset Group Descr." + ' ';
        IF "NA S#Car Model" <> '' THEN
            Txt += "NA S#Car Model" + ' ';
        IF "NA Model Year" <> 0 THEN
            IF Txt <> '' THEN
                Txt := FORMAT("NA Model Year") + ' ' + Txt
            ELSE
                Txt := FORMAT("NA Model Year");
        //END;

        /*DV170316*/
        //Txt := FORMAT("Model Year",0) + ' '+Manufacturer + ' ' + Model;
        /*TG200828*/
        IF "NA Trim" <> '' THEN
            Txt += "NA Trim";
        /*---*/

        //--- used asset
        //IF ("Asset New / Used"<>"Asset New / Used"::" ") AND
        //    ("Asset New / Used"<>"Asset New / Used"::New)
        //THEN Txt += ' (' + FORMAT("Asset New / Used") + ')';

        Txt := DELCHR(Txt, '<>');
        "Posting Description" := COPYSTR(Txt, 1, MAXSTRLEN("Posting Description"));
    end;

    //BA211005
    procedure CreatePOLine()
    var
        PurchLine: record "Purchase Line";
        LineNo: Integer;
    begin
        LineNo := 10000;
        PurchLine.Init;
        PurchLine.Validate("Document Type", Rec."Document Type");
        PurchLine.Validate("Document No.", Rec."No.");
        PurchLine."Line No." := LineNo;
        PurchLine.Validate(Type, PurchLine.Type::"Fixed Asset");
        PurchLine.Validate("No.", Rec."NA Asset No.");
        PurchLine.Description := CopyStr(Rec."Posting Description", 1, MaxStrLen(PurchLine.Description));
        PurchLine.Validate(Quantity, 1);
        PurchLine.Insert(true);
    end;
}
