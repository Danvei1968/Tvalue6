tableextension 17022180 "PYA Asset Ext." extends "S4LA Asset"
{
    fields
    {
        field(17022090; "NA FA Class Code"; Code[10])
        {
            Caption = 'FA Class Code';
            TableRelation = "FA Class";
        }
        field(17022091; "NA Trim"; Text[30])
        {
            Caption = 'Trim';
            trigger OnValidate()
            var
                FA: Record "Fixed Asset";
            begin
                /*DV171203*/
                IF "Asset No." <> '' THEN BEGIN
                    FA.GET("Asset No.");
                    FA."PYA Trim" := "NA Trim";
                    FA.MODIFY;
                END;
                BuildDescription;
                /*---*/

            end;
        }
        field(17022092; "NA Purchase Cost"; Decimal)
        {
            Caption = 'Purchase Cost';
        }
        field(17022094; "NA Color Of Vehicle"; Text[30])
        {
            Caption = 'Color Of Vehicle';

            trigger OnValidate()
            var
                FA: Record "Fixed Asset";
            begin
                /*DV171203*/
                //IF "Asset No." <> '' THEN BEGIN
                //  FA.GET("Asset No.");
                //FA."NA Color Of Vehicle" := "NA Color Of Vehicle";
                //FA.MODIFY;
                //END;
                /*---*/
            end;
        }

        field(17022181; "PYA MSRP Sticker Price"; Decimal)
        {
            Caption = 'MSRP Sticker Price';
            DataClassification = ToBeClassified;
        }
        field(17022182; "PYA Fleet Discount Amount"; Decimal)
        {
            Caption = 'Fleet Discount Amount';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                if "PYA Invoice Price" <> 0 then
                    Validate("Purchase Price", "PYA Invoice Price" - "PYA Fleet Discount Amount");
            end;
        }
        field(17022183; "PYA Invoice Price"; Decimal)
        {
            Caption = 'Invoice Price';
            DataClassification = ToBeClassified;

            trigger OnValidate()
            begin
                Validate("Purchase Price", "PYA Invoice Price" - "PYA Fleet Discount Amount");
            end;
        }
        //BA220301
        field(17022184; "PYA Capacity"; Decimal)
        {
            Caption = 'Capacity';
            DataClassification = ToBeClassified;
            DecimalPlaces = 0 : 5;
            BlankZero = true;

            trigger OnValidate()
            var
                FA: record "Fixed Asset";
            begin
                IF "Asset No." <> '' THEN BEGIN
                    FA.GET("Asset No.");
                    //FA."PYA Capacity" := "PYA Capacity";
                    FA.MODIFY;
                END;
            end;
        }
        field(17022185; "PYA Vin"; code[20])
        {
            Caption = 'Vin';
            DataClassification = ToBeClassified;

        }
        field(17022186; "PYA Interior Color"; Text[30])
        {
            Caption = 'Interior Color';
        }
        field(17022187; "PYA Contract Status"; Integer)
        {
            caption = 'Contract Status';
            TableRelation = "S4LA Status".Code WHERE("Target Table ID" = CONST(17021230));
        }
        field(17022188; "PYA Asset Status"; Integer)
        {
            caption = 'Asset Status';
        }
        field(17022189; "PYA Tax Group"; Code[20])
        {
            Caption = 'Ref. Security Deposit Tax Group';
            Description = 'JM170628';
            TableRelation = "VAT Product Posting Group";
        }
        field(17022190; "PYA Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            DataClassification = CustomerContent;
            Description = 'SK170207';
            TableRelation = "Tax Area";

            /*            trigger OnValidate()
                        var
                            Cust: Record Customer;
                            Vend: Record Vendor;
                        begin
                            //KS170209 NA
                            if Cust.Get("PYA Customer No") then begin
                                Cust."Tax Area Code" := "PYA Tax Area Code";
                                Cust.Modify();
                            end;
                            if Vend.Get("No") then begin
                                Vend."Tax Area Code" := "PYA Tax Area Code";
                                Vend.Modify();
                            end;
                            //---
                        end;        
            */
        }
        field(17022191; "PYA Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
            DataClassification = CustomerContent;
            Description = 'SK170207';
            InitValue = true;
        }

        /*            trigger OnValidate()
                    var
                        Cust: Record Customer;
                        Vend: Record Vendor;
                    begin
                        //KS170209 NA
                        if Cust.Get("No.") then begin
                            Cust."Tax Liable" := "PYA Tax Liable";
                            Cust.Modify();
                        end;
                        if Vend.Get("No.") then begin
                            Vend."Tax Liable" := "PYA Tax Liable";
                            Vend.Modify();
                        end;
                    end;
        */
        modify("Asset Brand")
        {
            trigger OnBeforeValidate()
            begin
                BuildDescription; //TG200828
            end;
        }
        modify(Model)
        {
            trigger OnAfterValidate()
            begin
                IF Model <> xRec.Model THEN BEGIN
                    IF Model <> '' THEN BEGIN
                        BuildDescription; //TG200828
                    END;
                END;
            end;
        }
        modify("Model Year")
        {
            trigger OnAfterValidate()
            begin

                IF "Model Year" <> xRec."Model Year" THEN
                    IF "Model Year" <> 0 THEN;
                BuildDescription();
            end;
        }
        modify("Asset New / Used")
        {
            trigger OnAfterValidate()
            VAR
                SOP: Record "s4la Schedule";
                Asset2: Record "s4la Asset";
                Contract: Record "s4la Contract";
            BEGIN

                Contract.GET("Contract No.");
                // only change the New/Used in contract if first asset line
                Asset2.SETRANGE("Contract No.", Contract."Contract No.");
                IF (NOT Asset2.FINDFIRST) OR (Asset2."Line No." = "Line No.") THEN BEGIN
                    IF Contract."New / Used Asset" <> "Asset New / Used" THEN BEGIN
                        Contract."New / Used Asset" := "Asset New / Used";
                        Contract.MODIFY;
                    END;
                END;
            END;
        }
        modify("Asset No.")
        {
            trigger OnAfterValidate()
            var
                FA: Record "Fixed Asset";
                Contract: record "s4la Contract";
                ScheduleOfPayment: Record "s4la Schedule";
                LAsset: Record "S4LA Asset";
                AssetMgt: Codeunit "S4LA Asset Mgt";
                //AssetStatus: Record "S4LA Status";
                Lcont: Record Contact;
            begin

                IF "Asset No." <> xRec."Asset No." THEN BEGIN
                    IF "Asset No." = '' THEN BEGIN
                        BreakFAtoAssetRelation(xRec."Asset No.");  //---- break asset-FA relation
                        "Asset Description" := ''; //PB150219 Issue No 134

                        VIN := '';
                        //        Manufacturer := '';
                        //        Model :='';
                        "Model Year" := 0;
                        //        clear("Purchase Price");
                        "NA Color Of Vehicle" := '';//DV171203
                        "NA Trim" := '';//DV171205


                        "Asset Brand" := '';
                        Model := '';
                        CLEAR("Model Year");
                        CLEAR("Asset New / Used");

                    END ELSE BEGIN
                        //AssignAsset;                            //----- create asset-FA relation

                        FA.GET("Asset No.");
                        //"Asset Type" := FA."S4L Asset Type";
                        //"Asset Group" := FA."S4L Asset Group";
                        //"Asset Category" := FA."S4L Asset Category";
                        //"Asset Brand" := FA."na Asset Brand";
                        //Model := FA."S4La Asset Model";
                        //"Model Year" := FA."na Model Year";
                        //BA210920 
                        //"Asset Description" := FA.Description;
                        Rec.BuildDescription();
                        //IF FA."S4L Asset Description" <> '' THEN
                        //  "Asset Description" := FA."S4L Asset Description";

                        "NA FA Class Code" := FA."FA Class Code";//DV170815                       
                                                                 //"NA Trim" := FA."NA Trim";//DV171205
                                                                 //"Asset New / Used" := FA."S4L Asset New / Used";//DV200922

                        Contract.GET("Contract No.");
                        Contract.UpdateAssetDim("Asset No.");
                        Contract.MODIFY;
                        /*---*/

                        //FA."S4L Contract No." := Contract."Contract No.";
                        //FA."S4L Fin. Product Code" := Contract."Financial Product";
                        //FA."S4L Contract Status" := Contract.Status;
                        //IF Lcont.GET(Contract."Customer No.") THEN BEGIN
                        //  FA."S4L Customer No." := Lcont."No.";
                        //  FA."S4L Customer Name" := Lcont.Name;
                    END;
                    //BA210920 
                    //IF FA."S4L Asset Description" = '' THEN begin
                    //  FA."S4L Asset Description" := Rec."Asset Description";
                    //  FA.Description := REC."Asset Description";
                    //end;
                    //---//                        
                    //FA.MODIFY;

                    //END;

                    //DV170727
                    ScheduleOfPayment.RESET;
                    ScheduleOfPayment.SETRANGE("Contract No.", "Contract No.");
                    IF ScheduleOfPayment.FINDLAST THEN;
                    LAsset.SETRANGE("Contract No.", "Contract No.");
                    IF NOT LAsset.FINDFIRST THEN
                        CLEAR(LAsset);
                    IF LAsset."Line No." = "Line No." THEN BEGIN
                        LAsset."Asset No." := "Asset No.";
                        // when filling in Asset No. from OnLookup trigger, the asset number doesn't fill in properly
                        /*TG200504*/ // this block of code causing an error when selecting an asset from lookup
                                     //  IF (xRec."Asset No." <> "Asset No.") AND ("Asset No." <> '') THEN BEGIN
                                     //    LAsset := Rec;
                                     //    LAsset.MODIFY; //TG200117 - the asset number not filled in, for whatever reason when the Quote Card updates it doesn't get the Rec from this page
                                     //  END;
                                     /*---*/
                    END;

                    // IF (ScheduleOfPayment."Contract No." <> '') AND (LAsset."Asset No." <> '') THEN BEGIN
                    //   ScheduleOfPayment."S#Asset No." := LAsset."Asset No.";

                    //   ScheduleOfPayment.MODIFY;
                    //END;

                    //END;


                    /*DV190514*/
                    IF xRec."Asset No." <> '' THEN BEGIN
                        FA.RESET;
                        FA.GET(xRec."Asset No.");
                        //AssetMgt.RemoveScheduleInfoFromAsset(FA,'', ScheduleOfPayment);                   
                        //AssetStatus.SETRANGE("Target Table ID", DATABASE::"Fixed Asset");
                        //TODO PYAS-137 AssetStatus.SETRANGE("Trigger Option No.", FA."Asset Status Trigger"::Stock);
                        //AssetStatus.SETRANGE("Trigger Option No.", 2); // temporary change until this is resolved
                        //IF AssetStatus.FINDFIRST THEN BEGIN
                        //    FA."PYA Asset Status Code" := AssetStatus.Code;
                        //    FA."PYA Asset Status Trigger" := AssetStatus."Trigger Option No.";
                        //END;
                        //LAsset.MODIFY;
                        //FA.MODIFY; //TG200610
                        //END;
                        /*---*/
                        UpdateMaintenanceCostonContract; //>>PB150211 Issue No 87
                    end;
                END;
            END;
        }
        modify("Purchase Price")
        {
            trigger OnAfterValidate()
            begin

                IF "Residual Value" = 0 THEN
                    "Residual Value" := ROUND("Purchase Price" * "Residual %" / 100, 0.01)
                ELSE
                    IF "Purchase Price" <> 0 THEN
                        "Residual %" := "Residual Value" / "Purchase Price" * 100
                    ELSE
                        "Residual %" := 0;

                //>>EN170123
                SetExclVATField(FIELDNO("Purchase Price")); //Calc. amount excluding VAT
                SetExclVATField(FIELDNO("Residual Value")); //Calc. amount excluding VAT
                                                            //<<EN170123
                UpdateValues(FALSE);
            end;
        }
        modify("Starting Mileage (km)")
        {
            Caption = 'Starting Mileage';
        }
        modify("Mileage Limit (km/year)")
        {
            //BA211123 - Enable dynamic caption based on language
            //  Caption = 'Mileage Limit (miles/year)';
            CaptionClass = '7,3';
            //--//
        }
        modify("Price Per km Over Limit")
        {
            Caption = 'Price per mile over limit';
        }
        modify("Closing Mileage (km)")
        {
            Caption = 'Ending Mileage';
        }

        modify("Acquisition Source")
        {
            trigger OnAfterValidate()
            var
                Contr: Record "S4LA Contract";
                FinProd: Record "S4LA Financial Product";
                Suppl: Record Contact;
            begin
                if not Contr.Get("Contract No.") then
                    Contr.Init;
                if not FinProd.Get(Contr."Financial Product") then
                    FinProd.Init;

                case "Acquisition Source" of

                    "Acquisition Source"::Supplier:
                        begin
                            Validate("VAT Group", FinProd."Purchase VAT Group (default)"); //default, user can override
                        end;

                    "Acquisition Source"::"3rd Party":
                        begin
                            if "Acquisition Source" <> xRec."Acquisition Source" then begin
                                Validate("VAT Group", '');
                            end;
                        end;

                end;
            end;
        }
        modify("Supplier No.")
        {
            trigger OnAfterValidate()
            var
                Contr: Record "S4LA Contract";
                FinProd: Record "S4LA Financial Product";
                Suppl: Record Contact;
            begin
                if not Contr.Get("Contract No.") then
                    Contr.Init;
                if not FinProd.Get(Contr."Financial Product") then
                    FinProd.Init;

                if ("Supplier No." = Contr."Supplier No.") and
                   ("Supplier No." <> '')
                then begin
                    Validate("VAT Group", FinProd."Purchase VAT Group (default)");
                end;

                if ("Supplier No." <> Contr."Supplier No.") and
                   ("Supplier No." <> '')
                then begin
                    Validate("VAT Group", FinProd."Purchase VAT Group (default)");
                end;
            end;
        }
    }
    var
    trigger OnAfterDelete()
    var
        FA: Record "Fixed Asset";
    begin
        /*DV170622*/
        //IF "Asset No." <> '' THEN
        //IF FA.GET("Asset No.") THEN BEGIN
        //FA."S4L Schedule No." := '';
        //FA."S4L Contract No." := '';
        //FA."S4L Customer No." := '';
        //FA."S4L Fin. Product Code" := '';
        //FA."S4L Customer No." := '';
        //FA.MODIFY;
        //END;
        /*---*/
    end;

    var
        Lasset: Record "S4LA Asset";
}
