table 17022182 "Quick Quote Worksheet"
{
    // TG190109 - FYI, for purpose of tax - Original Area Code should always be blank unless there is luxury tax.
    // TG190417 - Round monthly interest and principal pmt up to nearest dollar.
    // TG190507 - fix to calculation of rounded interest
    // DV190626 - Update ENU caption
    // NOTE: any new fields should be added to two functions in this table to clear worksheet: ClearQuotes2And3 & FillFromQuote1 & also to codeunit 50001 (if applicable)
    // TG190712 - bring in default program OnInsert
    // TG190731 - stepdown mod

    fields
    {
        field(1; "Contract No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Contract No.';
        }
        field(10; "Quick Quote Date"; Date)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quick Quote Date';
        }
        field(50000; "Quote1 Program Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "S4LA Program";
            Caption = 'Quote1 Program Code';

            trigger OnValidate()

            begin
                if not prog.Get("Quote1 Program Code") then
                    Error(STRSUBSTNO(Err50000, "Quote1 Program Code"));
            end;
        }
        field(50001; "Quote2 Program Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "S4LA Program";
            Caption = 'Quote2 Program Code';

            trigger OnValidate()

            begin
                if not prog.Get("Quote2 Program Code") then
                    Error(STRSUBSTNO(Err50000, "Quote2 Program Code"));
            end;
        }
        field(50002; "Quote3 Program Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "S4LA Program";
            Caption = 'Quote3 Program Code';

            trigger OnValidate()

            begin
                if not prog.Get("Quote3 Program Code") then
                    error(STRSUBSTNO(Err50000, "Quote3 Program Code"));
            end;
        }
        field(50010; "Quote1 Asset No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG200506';
            //TableRelation = "Fixed Asset" where("Asset Status Trigger" = const(Stock));
            TableRelation = "Fixed Asset"; //TODO: PYAS-137 filtering by asset status of stock
            Caption = 'Quote1 Asset No.';

            trigger OnValidate()
            begin
                OnValidateAssetNo("Quote1 Asset No.", 1);
            end;
        }
        field(50011; "Quote2 Asset No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG200506';
            TableRelation = "Fixed Asset"; //TODO PYAS-137 where("Asset Status Trigger" = const(Stock));
            Caption = 'Quote2 Asset No.';

            trigger OnValidate()
            begin
                OnValidateAssetNo("Quote2 Asset No.", 2);
            end;
        }
        field(50012; "Quote3 Asset No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG200506';
            TableRelation = "Fixed Asset"; //TODO PYAS-137 where("Asset Status Trigger" = const(Stock));
            Caption = 'Quote3 Asset No.';

            trigger OnValidate()
            begin
                OnValidateAssetNo("Quote3 Asset No.", 3);
            end;
        }
        field(50110; Type; Option)
        {
            DataClassification = ToBeClassified;
            Description = 'TG191125';
            OptionMembers = " ",Quote,Application;
            Caption = 'Type';
        }
        field(50111; "Quote1 Int. Rate Modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'TG191219 - Selig specific fields';
            Caption = 'Quote1 Int. Rate Modified';
        }
        field(50112; "Quote2 Int. Rate Modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'TG191219 - Selig specific fields';
            Caption = 'Quote2 Int. Rate Modified';
        }
        field(50113; "Quote3 Int. Rate Modified"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'TG191219 - Selig specific fields';
            Caption = 'Quote3 Int. Rate Modified';
        }
        field(60000; "Quote1 Manufacturer"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG181218 --------------- Quick Quote fields---------';
            //BA211008 - Changed from Asset Manufacturer
            TableRelation = "S4LA Asset Brand" where(Active = const(true));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
            Caption = 'Quote1 Manufacturer';
        }
        field(60001; "Quote1 Model"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Model';
        }
        field(60002; "Quote1 Model Year"; Integer)
        {
            DataClassification = ToBeClassified;
            MaxValue = 2100;
            MinValue = 0;
            Caption = 'Quote1 Model Year';
        }
        field(60003; "Quote1 Color of Vehicle"; Text[30])
        {
            Caption = 'Quote1 Color of Vehicle';
            DataClassification = ToBeClassified;
        }
        field(60004; "Quote1 Vehicle Notes"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Vehicle Notes';
        }
        field(60005; "Quote1 Interior Color"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Interior Color';
        }
        field(60010; "Quote1 Purchase Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote1 Purchase Price';

            trigger OnValidate()
            begin
                CalcTotalCost(1);
            end;
        }
        field(60015; "Quote1 Total Addons"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Accessories';

            trigger OnValidate()
            begin
                CalcTotalCost(1);
            end;
        }
        field(60019; "Quote1 Total Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote1 Total Cost';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(1);
                CalcMonthlyInterest(1);
                GetContext(1);
                CalcTotalCost(1);
            end;
        }
        field(60021; "Quote1 Downpayment"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote1 Downpayment';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(1);
                CalcMonthlyInterest(1);
            end;
        }
        field(60022; "Quote1 Trade-In Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote1 Trade-In Cost';

            trigger OnValidate()
            begin
                if "Quote1 Trade-In Cost" < 0 then
                    FieldError("Quote1 Trade-In Cost", Text50001);
                CalcMonthlyDepr2(1);
                CalcMonthlyInterest(1);
            end;
        }
        field(60023; "Quote1 Refin. Pay-out Figure"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Refin. Pay-out Figure';

            trigger OnValidate()
            begin
                if xRec."Quote1 Refin. Pay-out Figure" = "Quote1 Refin. Pay-out Figure" then
                    exit;
                CalcMonthlyDepr2(1);
                CalcMonthlyInterest(1);
            end;
        }
        field(60025; "Quote1 Tax Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Tax Amount';

            trigger OnValidate()
            begin
                "Quote1 Monthly Pmt. Incl. Tax" := "Quote1 Monthly Pmt. Excl. Tax" + "Quote1 Tax Amount";
            end;
        }

        field(60029; "Quote1 Tax Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote1 Tax Rate';
        }
        field(60031; "Quote1 Term (Months)"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Term (Months)';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(1);
                CalcMonthlyInterest(1);
                CalcCommission(1);
            end;
        }
        field(60032; "Quote1 Term"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Terms And Conditions";
            Caption = 'Quote1 Term';

            trigger OnValidate()
            begin
                UpdateNumberOfPaymentPeriods(1);
            end;
        }
        field(60033; "Quote1 Interest %"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
            MaxValue = 100;
            MinValue = 0;
            Caption = 'Quote1 Interest %';

            trigger OnValidate()
            begin
                /*TG190802*/
                if CurrFieldNo = 60033 then begin
                    CheckIntPct(1);
                    /*TG191219*/
                    if (xRec."Quote1 Interest %" <> "Quote1 Interest %") and not (("Quote1 Program Code" = '') and ("Quote1 Interest %" = 0)) then
                        "Quote1 Int. Rate Modified" := true;
                    /*---*/
                end;
                /*---*/

                CalcMonthlyDepr2(1);
                CalcMonthlyInterest(1);
            end;
        }
        field(60034; "Quote1 Monthly Depreciation %"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 3;
            MaxValue = 100;
            MinValue = 0;
            Caption = 'Quote1 Monthly Depreciation %';

            trigger OnValidate()
            begin
                if CurrFieldNo = 60034 then
                    CalcMonthlyDepr(1);
            end;
        }
        field(60035; "Quote1 Profit Figure"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Profit Figure';

            trigger OnValidate()
            begin
                "Quote1 Customer Residual" := "Quote1 Profit Figure" + "Quote1 Residual Value"; //JM190401
                CalcCommission(1);
            end;
        }
        field(60036; "Quote1 Residual Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Residual Value';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(1);
                CalcMonthlyInterest(1);
                "Quote1 Customer Residual" := "Quote1 Profit Figure" + "Quote1 Residual Value"; //JM190401
            end;
        }
        field(60040; "Quote1 Monthly Overhead"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote1 Monthly Overhead';

            trigger OnValidate()
            begin
                CalcMonthlyPmtExclTax(1);
                CalcCommission(1);
            end;
        }
        field(60041; "Quote1 Bonus"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote1 Bonus';
        }
        field(60042; "Quote1 Monthly Interest"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote1 Monthly Interest';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 60044 then
                    CalcMonthlyPmtExclTax(1);
            end;
        }
        field(60043; "Quote1 Monthly Depreciation"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote1 Monthly Depreciation';

            trigger OnValidate()
            begin
                if CurrFieldNo = 60034 then
                    CalcResidualValue(1);
                CalcMonthlyPmtExclTax(1);
                CalcMonthlyInterest(1);
            end;
        }
        field(60044; "Quote1 Monthly Pmt. Excl. Tax"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Monthly Pmt. Excl. Tax';

            trigger OnValidate()
            begin
                if (xRec."Quote1 Monthly Pmt. Excl. Tax" <> "Quote1 Monthly Pmt. Excl. Tax") and (CurrFieldNo = 60044) then begin
                    FillFixedValue(1);
                    CalcMonthlyDepr2(1);
                    CalcMonthlyInterest(1);
                end;

                CalcTax(1);
            end;
        }
        field(60045; "Quote1 Monthly Pmt. Incl. Tax"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote1 Monthly Pmt. Incl. Tax';
        }
        field(60046; "Quote1 Commission"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote1 Commission';
        }
        field(60047; "Quote1 Commission Schema"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "S4LA Commission Schema";
            Caption = 'Quote1 Commission Schema';

            trigger OnValidate()
            begin
                CalcCommission(1);
            end;
        }
        field(60049; "Quote1 Accepted"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Accepted';

            trigger OnValidate()
            begin
                if "Quote1 Accepted" and ("Quote2 Accepted" or "Quote3 Accepted") then begin
                    "Quote2 Accepted" := false;
                    "Quote3 Accepted" := false;
                end;
            end;
        }
        field(60050; "Quote2 Manufacturer"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG181218 --------------- Quick Quote fields---------';
            //BA211008 - Changed from Asset Manufacturer
            TableRelation = "S4LA Asset Brand" where(Active = const(true));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
            Caption = 'Quote2 Manufacturer';
        }
        field(60051; "Quote2 Model"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Model';
        }
        field(60052; "Quote2 Model Year"; Integer)
        {
            DataClassification = ToBeClassified;
            MaxValue = 2100;
            MinValue = 0;
            Caption = 'Quote2 Model Year';
        }
        field(60053; "Quote2 Color of Vehicle"; Text[30])
        {
            Caption = 'Quote2 Color of Vehicle';
            DataClassification = ToBeClassified;
        }
        field(60054; "Quote2 Vehicle Notes"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Vehicle Notes';
        }
        field(60055; "Quote2 Interior Color"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Interior Color';
        }
        field(60060; "Quote2 Purchase Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote2 Purchase Price';

            trigger OnValidate()
            begin
                CalcTotalCost(2);
            end;
        }
        field(60065; "Quote2 Total Addons"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Accessories';

            trigger OnValidate()
            begin
                CalcTotalCost(2);
            end;
        }
        field(60069; "Quote2 Total Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote2 Total Cost';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(2);
                CalcMonthlyInterest(2);
                GetContext(2);
                CalcTotalCost(2);
            end;
        }
        field(60071; "Quote2 Downpayment"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote2 Downpayment';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(2);
                CalcMonthlyInterest(2);
            end;
        }
        field(60072; "Quote2 Trade-In Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote2 Trade-In Cost';

            trigger OnValidate()
            begin
                if "Quote2 Trade-In Cost" < 0 then
                    FieldError("Quote2 Trade-In Cost", Text50001);

                CalcMonthlyDepr2(2);
                CalcMonthlyInterest(2);

            end;
        }
        field(60073; "Quote2 Refin. Pay-out Figure"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Refin. Pay-out Figure';

            trigger OnValidate()
            begin
                if xRec."Quote2 Refin. Pay-out Figure" = "Quote2 Refin. Pay-out Figure" then
                    exit;

                CalcMonthlyDepr2(2);
                CalcMonthlyInterest(2);

            end;
        }
        field(60075; "Quote2 Tax Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Tax Amount';

            trigger OnValidate()
            begin
                "Quote2 Monthly Pmt. Incl. Tax" := "Quote2 Monthly Pmt. Excl. Tax" + "Quote2 Tax Amount";
            end;
        }
        field(60076; "PYA Licence Plate No."; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Licence Plate No.';
        }
        field(60077; "PYA Gross Receivable"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Gross Receivable';
        }
        field(60078; "PYA Net Receivable"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Net Receivable';
        }
        field(60079; "Quote2 Tax Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote2 Tax Rate';
        }
        field(60080; "PYA Lease Payments"; Integer)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Lease Payments';
        }
        field(60081; "Quote2 Term (Months)"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Term (Months)';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(2);
                CalcMonthlyInterest(2);
                CalcCommission(2);
            end;
        }
        field(60082; "Quote2 Term"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Terms And Conditions";
            Caption = 'Quote2 Term';

            trigger OnValidate()
            begin
                UpdateNumberOfPaymentPeriods(2);
            end;
        }
        field(60083; "Quote2 Interest %"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
            MaxValue = 100;
            MinValue = 0;
            Caption = 'Quote2 Interest %';

            trigger OnValidate()
            begin

                /*TG190802*/
                if CurrFieldNo = 60083 then begin
                    CheckIntPct(2);
                    /*TG191219*/
                    if (xRec."Quote2 Interest %" <> "Quote2 Interest %") and not (("Quote2 Program Code" = '') and ("Quote2 Interest %" = 0)) then
                        "Quote2 Int. Rate Modified" := true;
                    /*---*/
                end;
                /*---*/
                CalcMonthlyDepr2(2);
                CalcMonthlyInterest(2);
            end;
        }
        field(60084; "Quote2 Monthly Depreciation %"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 3;
            MaxValue = 100;
            MinValue = 0;
            Caption = 'Quote2 Monthly Depreciation %';

            trigger OnValidate()
            begin
                if CurrFieldNo = 60084 then
                    CalcMonthlyDepr(2);
            end;
        }
        field(60085; "Quote2 Profit Figure"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Profit Figure';

            trigger OnValidate()
            begin
                "Quote2 Customer Residual" := "Quote2 Profit Figure" + "Quote2 Residual Value"; //JM190401
                CalcCommission(2);
            end;
        }
        field(60086; "Quote2 Residual Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Residual Value';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(2);
                CalcMonthlyInterest(2);
                "Quote2 Customer Residual" := "Quote2 Profit Figure" + "Quote2 Residual Value"; //JM190401
            end;
        }
        field(60090; "Quote2 Monthly Overhead"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote2 Monthly Overhead';

            trigger OnValidate()
            begin
                CalcMonthlyPmtExclTax(2);
                CalcCommission(2);
            end;
        }
        field(60091; "Quote2 Bonus"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote2 Bonus';
        }
        field(60092; "Quote2 Monthly Interest"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote2 Monthly Interest';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 60094 then
                    CalcMonthlyPmtExclTax(2);
            end;
        }
        field(60093; "Quote2 Monthly Depreciation"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote2 Monthly Depreciation';

            trigger OnValidate()
            begin
                if CurrFieldNo = 60084 then
                    CalcResidualValue(2);
                CalcMonthlyPmtExclTax(2);
                CalcMonthlyInterest(2);
            end;
        }
        field(60094; "Quote2 Monthly Pmt. Excl. Tax"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Monthly Pmt. Excl. Tax';

            trigger OnValidate()
            begin
                if (xRec."Quote2 Monthly Pmt. Excl. Tax" <> "Quote2 Monthly Pmt. Excl. Tax") and (CurrFieldNo = 60094) then begin
                    FillFixedValue(2);
                    CalcMonthlyDepr2(2);
                    CalcMonthlyInterest(2);
                end;

                CalcTax(2);
            end;
        }
        field(60095; "Quote2 Monthly Pmt. Incl. Tax"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote2 Monthly Pmt. Incl. Tax';
        }
        field(60096; "Quote2 Commission"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote2 Commission';
        }
        field(60097; "Quote2 Commission Schema"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "S4LA Commission Schema";
            Caption = 'Quote2 Commission Schema';

            trigger OnValidate()
            begin
                CalcCommission(2);
            end;
        }
        field(60099; "Quote2 Accepted"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Accepted';

            trigger OnValidate()
            begin
                if "Quote2 Accepted" and ("Quote1 Accepted" or "Quote3 Accepted") then begin
                    "Quote1 Accepted" := false;
                    "Quote3 Accepted" := false;
                end;
            end;
        }
        field(60100; "Quote3 Manufacturer"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG181218 --------------- Quick Quote fields---------';
            //BA211008 - Changed from Asset Manufacturer
            TableRelation = "S4LA Asset Brand" where(Active = const(true));
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
            Caption = 'Quote3 Manufacturer';
        }
        field(60101; "Quote3 Model"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Model';
        }
        field(60102; "Quote3 Model Year"; Integer)
        {
            DataClassification = ToBeClassified;
            MaxValue = 2100;
            MinValue = 0;
            Caption = 'Quote3 Model Year';
        }
        field(60103; "Quote3 Color of Vehicle"; Text[30])
        {
            Caption = 'Quote3 Color of Vehicle';
            DataClassification = ToBeClassified;
        }
        field(60104; "Quote3 Vehicle Notes"; Text[250])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Vehicle Notes';
        }
        field(60105; "Quote3 Interior Color"; Text[30])
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Interior Color';
        }
        field(60110; "Quote3 Purchase Price"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote3 Purchase Price';

            trigger OnValidate()
            begin
                CalcTotalCost(3);
            end;
        }
        field(60115; "Quote3 Total Addons"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Accessories';

            trigger OnValidate()
            begin
                CalcTotalCost(3);
            end;
        }
        field(60119; "Quote3 Total Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote3 Total Cost';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(3);
                CalcMonthlyInterest(3);
                GetContext(3);
                CalcTotalCost(3);
            end;
        }
        field(60121; "Quote3 Downpayment"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote3 Downpayment';

            trigger OnValidate()
            begin
                CalcMonthlyDepr(3);
                CalcMonthlyInterest(3);
            end;
        }
        field(60122; "Quote3 Trade-In Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote3 Trade-In Cost';

            trigger OnValidate()
            begin
                if "Quote3 Trade-In Cost" < 0 then
                    FieldError("Quote3 Trade-In Cost", Text50001);

                CalcMonthlyDepr2(3);
                CalcMonthlyInterest(3);
            end;
        }
        field(60123; "Quote3 Refin. Pay-out Figure"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Refin. Pay-out Figure';

            trigger OnValidate()
            begin
                if xRec."Quote3 Refin. Pay-out Figure" = "Quote3 Refin. Pay-out Figure" then
                    exit;

                CalcMonthlyDepr2(3);
                CalcMonthlyInterest(3);
            end;
        }
        field(60125; "Quote3 Tax Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Tax Amount';

            trigger OnValidate()
            begin
                "Quote3 Monthly Pmt. Incl. Tax" := "Quote3 Monthly Pmt. Excl. Tax" + "Quote3 Tax Amount";
            end;
        }

        field(60129; "Quote3 Tax Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote3 Tax Rate';
        }
        field(60131; "Quote3 Term (Months)"; Integer)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Term (Months)';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(3);
                CalcMonthlyInterest(3);
                CalcCommission(3);
            end;
        }
        field(60132; "Quote3 Term"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "Terms And Conditions";
            Caption = 'Quote3 Term';

            trigger OnValidate()
            begin
                UpdateNumberOfPaymentPeriods(3);
            end;
        }
        field(60133; "Quote3 Interest %"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 5;
            MaxValue = 100;
            MinValue = 0;
            Caption = 'Quote3 Interest %';

            trigger OnValidate()
            begin
                /*TG190802*/
                if CurrFieldNo = 60133 then begin
                    CheckIntPct(3);
                    /*TG191219*/
                    if (xRec."Quote3 Interest %" <> "Quote3 Interest %") and not (("Quote3 Program Code" = '') and ("Quote3 Interest %" = 0)) then
                        "Quote3 Int. Rate Modified" := true;
                    /*---*/
                end;
                /*---*/

                CalcMonthlyDepr2(3);
                CalcMonthlyInterest(3);
            end;
        }
        field(60134; "Quote3 Monthly Depreciation %"; Decimal)
        {
            DataClassification = ToBeClassified;
            DecimalPlaces = 2 : 3;
            MaxValue = 100;
            MinValue = 0;
            Caption = 'Quote3 Monthly Depreciation %';

            trigger OnValidate()
            begin
                if CurrFieldNo = 60134 then
                    CalcMonthlyDepr(3);
            end;
        }
        field(60135; "Quote3 Profit Figure"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Profit Figure';

            trigger OnValidate()
            begin
                "Quote3 Customer Residual" := "Quote3 Profit Figure" + "Quote3 Residual Value"; //JM190401
                CalcCommission(3);
            end;
        }
        field(60136; "Quote3 Residual Value"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Residual Value';

            trigger OnValidate()
            begin
                CalcMonthlyDepr2(3);
                CalcMonthlyInterest(3);
                "Quote3 Customer Residual" := "Quote3 Profit Figure" + "Quote3 Residual Value"; //JM190401
            end;
        }
        field(60140; "Quote3 Monthly Overhead"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote3 Monthly Overhead';

            trigger OnValidate()
            begin
                CalcMonthlyPmtExclTax(3);
                CalcCommission(3);
            end;
        }
        field(60141; "Quote3 Bonus"; Decimal)
        {
            DataClassification = ToBeClassified;
            MinValue = 0;
            Caption = 'Quote3 Bonus';
        }
        field(60142; "Quote3 Monthly Interest"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote3 Monthly Interest';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 60144 then
                    CalcMonthlyPmtExclTax(3);
            end;
        }
        field(60143; "Quote3 Monthly Depreciation"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote3 Monthly Depreciation';

            trigger OnValidate()
            begin
                if CurrFieldNo = 60134 then
                    CalcResidualValue(3);
                CalcMonthlyPmtExclTax(3);
                CalcMonthlyInterest(3);
            end;
        }
        field(60144; "Quote3 Monthly Pmt. Excl. Tax"; Decimal)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Monthly Pmt. Excl. Tax';

            trigger OnValidate()
            begin
                if (xRec."Quote3 Monthly Pmt. Excl. Tax" <> "Quote3 Monthly Pmt. Excl. Tax") and (CurrFieldNo = 60144) then begin
                    FillFixedValue(3);
                    CalcMonthlyDepr2(3);
                    CalcMonthlyInterest(3);
                end;

                CalcTax(3);
            end;
        }

        field(60145; "Quote3 Monthly Pmt. Incl. Tax"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote3 Monthly Pmt. Incl. Tax';
        }
        field(60146; "Quote3 Commission"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
            Caption = 'Quote3 Commission';
        }
        field(60147; "Quote3 Commission Schema"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "S4LA Commission Schema";
            Caption = 'Quote3 Commission Schema';

            trigger OnValidate()
            begin
                CalcCommission(3);
            end;
        }
        field(60149; "Quote3 Accepted"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Accepted';

            trigger OnValidate()
            begin
                if "Quote3 Accepted" and ("Quote1 Accepted" or "Quote2 Accepted") then begin
                    "Quote1 Accepted" := false;
                    "Quote2 Accepted" := false;
                end;
            end;
        }
        field(60150; QuickEntry1; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'QuickEntry1';

            trigger OnValidate()
            begin
                if QuickEntry1 then begin
                    QuickEntry2 := false;
                    QuickEntry3 := false;
                end;
            end;
        }
        field(60151; QuickEntry2; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'QuickEntry2';

            trigger OnValidate()
            begin
                if QuickEntry2 then begin
                    QuickEntry1 := false;
                    QuickEntry3 := false;
                end;
            end;
        }
        field(60152; QuickEntry3; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'QuickEntry3';

            trigger OnValidate()
            begin
                if QuickEntry3 then begin
                    QuickEntry2 := false;
                    QuickEntry1 := false;
                end;
            end;
        }
        field(60153; "Quick Quote Confirmed"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quick Quote Confirmed';

            trigger OnValidate()
            begin
                "Confirmed By" := UserId;
                "Date Confirmed" := CurrentDateTime;
            end;
        }
        field(60154; "Confirmed By"; Code[50])
        {
            DataClassification = ToBeClassified;
            Caption = 'Confirmed By';
        }
        field(60155; "Date Confirmed"; DateTime)
        {
            DataClassification = ToBeClassified;
            Caption = 'Date Confirmed';
        }
        field(60160; "Quote1 Print"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote1 Print';
        }
        field(60161; "Quote2 Print"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote2 Print';
        }
        field(60162; "Quote3 Print"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Quote3 Print';
        }
        field(60163; "Quote1 Customer Residual"; Decimal)
        {
            DataClassification = ToBeClassified;
            Description = 'JM190401';
            Caption = 'Quote1 Customer Residual';
        }
        field(60170; "Value To Fix"; Option)
        {
            DataClassification = ToBeClassified;
            OptionCaption = ' ,Asset Price,Downpayment,Residual Value,Trade-in Value';
            OptionMembers = " ","Asset Price",Downpayment,"Residual Value","Trade-in Value";
            Caption = 'Value To Fix';
        }
        field(61164; "Quote2 Customer Residual"; Decimal)
        {
            DataClassification = ToBeClassified;
            Description = 'JM190401';
            Caption = 'Quote2 Customer Residual';
        }
        field(61165; "Quote3 Customer Residual"; Decimal)
        {
            DataClassification = ToBeClassified;
            Description = 'JM190401';
            Caption = 'Quote3 Customer Residual';
        }
        field(61900; "UPDATE_BY"; Code[50])
        {
            Caption = 'UPDATE_BY';
            DataClassification = ToBeClassified;
            Description = '--------- TECHNICAL FIELDS ----------------';

            trigger OnLookup()
            var
                UserMgt: Codeunit "User Management";
            begin
            end;

            trigger OnValidate()
            var
                UserMgt: Codeunit "User Management";
            begin
            end;
        }
        field(61901; "UPDATE_DATE"; DateTime)
        {
            Caption = 'UPDATE_DATE';
            DataClassification = ToBeClassified;
        }
        field(61902; "INSERT_BY"; Code[50])
        {
            Caption = 'INSERT_BY';
            DataClassification = ToBeClassified;

            trigger OnLookup()
            var
                UserMgt: Codeunit "User Management";
            begin
            end;

            trigger OnValidate()
            var
                UserMgt: Codeunit "User Management";
            begin
            end;
        }
        field(61903; "INSERT_DATE"; DateTime)
        {
            Caption = 'INSERT_DATE';
            DataClassification = ToBeClassified;
        }

        //BA210624
        field(61904; "Quote1 Services"; Decimal)
        {
            Caption = 'Quote1 Services';
            trigger OnValidate()
            begin
                CalcTotalCost(1);
            end;

        }
        field(61905; "Quote2 Services"; Decimal)
        {
            Caption = 'Quote2 Services';
            trigger OnValidate()
            begin
                CalcTotalCost(2);
            end;

        }
        field(61906; "Quote3 Services"; Decimal)
        {
            Caption = 'Quote3 Services';
            trigger OnValidate()
            begin
                CalcTotalCost(2);
            end;

        }

        field(61907; "Quote1 Upfront Services"; Decimal)
        {
            Caption = 'Quote1 Upfront Services';

        }
        field(61908; "Quote2 Upfront Services"; Decimal)
        {
            Caption = 'Quote2 Upfront Services';

        }
        field(61909; "Quote3 Upfront Services"; Decimal)
        {
            Caption = 'Quote3 Upfront Services';

        }

        field(61910; "Quote1 Insurance Services"; Decimal)
        {
            Caption = 'Quote1 Insurance Services';

        }
        field(61911; "Quote2 Insurance Services"; Decimal)
        {
            Caption = 'Quote2 Insurance Services';

        }
        field(61912; "Quote3 Insurance Services"; Decimal)
        {
            Caption = 'Quote3 Insurance Services';

        }

        field(61913; "Quote1 Financed Insurance"; Decimal)
        {
            Caption = 'Quote1 Financed Insurance';
            trigger OnValidate()
            begin
                CalcTotalCost(1);
            end;

        }
        field(61914; "Quote2 Financed Insurance"; Decimal)
        {
            Caption = 'Quote2 Financed Insurance';
            trigger OnValidate()
            begin
                CalcTotalCost(2);
            end;
        }
        field(61915; "Quote3 Financed Insurance"; Decimal)
        {
            Caption = 'Quote3 Financed Insurance';
            trigger OnValidate()
            begin
                CalcTotalCost(3);
            end;

        }

        field(61916; "Quote1 Monthly Insurance"; Decimal)
        {
            Caption = 'Quote1 Monthly Insurance';

            trigger OnValidate()
            begin
                CalcMonthlyPmtExclTax(1);
                // CalcCommission(1);
            end;
        }
        field(61917; "Quote2 Monthly Insurance"; Decimal)
        {
            Caption = 'Quote2 Monthly Insurance';
            trigger OnValidate()
            begin
                CalcMonthlyPmtExclTax(2);
                //  CalcCommission(1);
            end;
        }
        field(61918; "Quote3 Monthly Insurance"; Decimal)
        {
            Caption = 'Quote3 Monthly Insurance';
            trigger OnValidate()
            begin
                CalcMonthlyPmtExclTax(3);
                // CalcCommission(1);
            end;
        }
        field(61919; "Quote1 Tax Area Code"; Code[20])
        {
            Caption = 'Quote1 Tax Area Code';
            trigger OnValidate()
            begin
                GetContext(1);
            end;
        }
        field(61920; "Quote2 Tax Area Code"; code[20])
        {
            Caption = 'Quote2 Tax Area Code';
            trigger OnValidate()
            begin
                GetContext(2);
            end;
        }
        field(61921; "Quote3 Tax Area Code"; code[20])
        {
            Caption = 'Quote3 Tax Area Code';
            trigger OnValidate()
            begin
                GetContext(3);
            end;
        }
        field(61922; "Quote1 Original Tax Area Code"; Code[20])
        {
            Caption = 'Quote1 Original Tax Area Code';
            trigger OnValidate()
            begin
                GetContext(1);
            end;
        }
        field(61923; "Quote2 Original Tax Area Code"; code[20])
        {
            Caption = 'Quote2 Original Tax Area Code';
            trigger OnValidate()
            begin
                GetContext(2);
            end;
        }
        field(61924; "Quote3 Original Tax Area Code"; code[20])
        {
            Caption = 'Quote3 Original Tax Area Code';
            trigger OnValidate()
            begin
                GetContext(3);
            end;
        }
    }

    keys
    {
        key(Key1; "Contract No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        ValidateContr;
        FillFromQuoteToAppl; //TG190916
        GetContext(0);
        "Quick Quote Date" := Contract."Contract Date";
        "Quote1 Accepted" := true; //TG190426
        /*TG190712*/
        if FinProd."Default Program Code" <> '' then
            Validate("Quote1 Program Code", FinProd."Default Program Code");
        /*---*/
        INSERT_BY := UserId;
        INSERT_DATE := CurrentDateTime;

    end;

    trigger OnModify()
    begin
        UPDATE_BY := UserId;
        UPDATE_DATE := CurrentDateTime;
    end;

    var

        prog: Record "S4LA PROGRAM";
        Text50000: Label 'Please mark one of the three quotes as accepted before confirming.';
        Err50000: label 'The Program code %1 is invalid';
        Err50001: label 'The Asset is %1 is invalid';
        Contract: Record "S4LA Contract";
        Schedule: Record "S4LA Schedule";
        FinProd: Record "S4LA Financial Product";
        LeasingSetup: Record "S4LA Leasing Setup";
        LeasingSetup2: Record "Leasing Setup 2";
        pselectValuetoFix: Page "Quick Quote Wksht Dialogue";
        Text50001: Label 'Cannot be less than zero';
        "--TG190731--": Integer;
        DeprAmt: Decimal;
        StepdownArray: array[999] of Decimal;
        StepdownAvgArray: array[999] of Decimal;
        ProgramRec: Record "S4LA Program";
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        QuickQuoteTaxAreaCode: Code[20];
        QuickQuoteOrigTaxAreaCode: code[20];

    local procedure GetContext(QuoteNo: Integer)

    begin
        LeasingSetup.GET;
        IF NOT Contract.GET("Contract No.") THEN;
        Schedule.reset;
        Schedule.SetRange("Contract No.", Contract."Contract No.");
        Schedule.SetRange("Schedule No.", Contract."Contract No.");
        if Schedule.FindFirst then;

        IF NOT FinProd.GET(Contract."Financial Product") THEN
            CLEAR(FinProd);

        CASE QuoteNo OF
            1:
                BEGIN
                    IF "Quote1 Tax Area Code" = '' THEN
                        "Quote1 Tax Area Code" := Contract."PYA Tax Area Code";

                    QuickQuoteTaxAreaCode := "Quote1 Tax Area Code";
                END;

            2:
                BEGIN
                    IF "Quote2 Tax Area Code" = '' THEN
                        "Quote2 Tax Area Code" := Contract."PYA Tax Area Code";

                    QuickQuoteTaxAreaCode := "Quote2 Tax Area Code";
                END;
            3:
                BEGIN
                    IF "Quote3 Tax Area Code" = '' THEN
                        "Quote3 Tax Area Code" := Contract."PYA Tax Area Code";

                    QuickQuoteTaxAreaCode := "Quote3 Tax Area Code";
                END;
        END;
    end;

    local procedure CalcTotalCost(QuoteNo: Integer)
    begin
        //BA210624  -- Added Services
        case QuoteNo of
            1:
                Validate("Quote1 Total Cost", "Quote1 Purchase Price" + "Quote1 Total Addons" + "Quote1 Services" + "Quote1 Financed Insurance");
            2:
                Validate("Quote2 Total Cost", "Quote2 Purchase Price" + "Quote2 Total Addons" + "Quote2 Services" + "Quote2 Financed Insurance");
            3:
                Validate("Quote3 Total Cost", "Quote3 Purchase Price" + "Quote3 Total Addons" + "Quote3 Services" + "Quote3 Financed Insurance");
        end;
    end;

    local procedure CalcResidualValue(QuoteNo: Integer)
    begin
        case QuoteNo of
            1:
                begin
                    if ("Quote1 Monthly Depreciation %" = 0) or ("Quote1 Term (Months)" = 0) or ("Quote1 Total Cost" = 0) then begin
                        Validate("Quote1 Residual Value", 0);
                        exit;
                    end;
                    Validate("Quote1 Residual Value", ("Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure")) - ("Quote1 Term (Months)" * "Quote1 Monthly Depreciation"));
                end;
            2:
                begin
                    if ("Quote2 Monthly Depreciation %" = 0) or ("Quote2 Term (Months)" = 0) or ("Quote2 Total Cost" = 0) then begin
                        Validate("Quote2 Residual Value", 0);
                        exit;
                    end;
                    Validate("Quote2 Residual Value", ("Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure")) - ("Quote2 Term (Months)" * "Quote2 Monthly Depreciation"));
                end;
            3:
                begin
                    if ("Quote3 Monthly Depreciation %" = 0) or ("Quote3 Term (Months)" = 0) or ("Quote3 Total Cost" = 0) then begin
                        Validate("Quote3 Residual Value", 0);
                        exit;
                    end;
                    Validate("Quote3 Residual Value", ("Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure")) - ("Quote3 Term (Months)" * "Quote3 Monthly Depreciation"));
                end;
        end;
    end;

    local procedure CalcMonthlyDepr(QuoteNo: Integer)
    begin
        // this function calculates monthly depreciation based on the monthly depreciation %
        LeasingSetup.Get;
        case QuoteNo of
            1:
                begin
                    if ("Quote1 Monthly Depreciation %" = 0) or (("Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure")) <= 0) then begin
                        Validate("Quote1 Monthly Depreciation", 0);
                        exit;
                    end;
                    Validate("Quote1 Monthly Depreciation",
                              Round(("Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure")) * "Quote1 Monthly Depreciation %" / 100, 0.01));
                    /*TG190731*/
                    if "Quote1 Program Code" <> '' then begin
                        ProgramRec.Get("Quote1 Program Code");
                        /*    if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin
                               LoadStepdownArray(1);
                               "Quote1 Monthly Depreciation" := Round(DeprAmt, 0.01);
                           end; */
                    end;
                    /*---*/
                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then begin
                        "Quote1 Monthly Depreciation" := Round("Quote1 Monthly Depreciation", 1, '>');
                        CalcMonthlyPmtExclTax(1);
                    end;
                    /*---*/
                end;
            2:
                begin
                    if ("Quote2 Monthly Depreciation %" = 0) or (("Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure")) <= 0) then begin
                        Validate("Quote2 Monthly Depreciation", 0);
                        exit;
                    end;
                    Validate("Quote2 Monthly Depreciation",
                              Round(("Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure")) * "Quote2 Monthly Depreciation %" / 100, 0.01));
                    /*TG190731*/
                    if "Quote2 Program Code" <> '' then begin
                        ProgramRec.Get("Quote2 Program Code");
                        /*  if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin
                             LoadStepdownArray(2);
                             "Quote2 Monthly Depreciation" := Round(DeprAmt, 0.01);
                         end; */
                    end;
                    /*---*/
                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then begin
                        "Quote2 Monthly Depreciation" := Round("Quote2 Monthly Depreciation", 1, '>');
                        CalcMonthlyPmtExclTax(2);
                    end;
                    /*---*/
                end;
            3:
                begin
                    if ("Quote3 Monthly Depreciation %" = 0) or (("Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure")) <= 0) then begin
                        Validate("Quote3 Monthly Depreciation", 0);
                        exit;
                    end;
                    Validate("Quote3 Monthly Depreciation",
                              Round(("Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure")) * "Quote3 Monthly Depreciation %" / 100, 0.01));
                    /*TG190731*/
                    if "Quote3 Program Code" <> '' then begin
                        ProgramRec.Get("Quote3 Program Code");
                        /*  if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin
                             LoadStepdownArray(3);
                             "Quote3 Monthly Depreciation" := Round(DeprAmt, 0.01);
                         end; */
                    end;
                    /*---*/
                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then begin
                        "Quote3 Monthly Depreciation" := Round("Quote3 Monthly Depreciation", 1, '>');
                        CalcMonthlyPmtExclTax(3);
                    end;
                    /*---*/
                end;
        end;
    end;

    local procedure CalcMonthlyDepr2(QuoteNo: Integer)
    begin
        LeasingSetup.Get;
        case QuoteNo of
            1:
                begin
                    /*TG190731*/
                    if "Quote1 Program Code" <> '' then begin
                        ProgramRec.Get("Quote1 Program Code");
                        // if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin
                        //     LoadStepdownArray(1);
                        //   "Quote1 Monthly Depreciation" := Round(DeprAmt, 0.01);
                        /*TG190417*/
                        //   if LeasingSetup."Round Quick Quote Installment" then
                        //      "Quote1 Monthly Depreciation" := Round("Quote1 Monthly Depreciation", 1, '>');
                        //  exit;
                        //end;
                    end;
                    /*---*/
                    if ("Quote1 Term (Months)" = 0) or (("Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure")) = 0) /* BA210625 or ("Quote1 Residual Value" = 0)*/ then begin
                        "Quote1 Monthly Depreciation" := 0;
                        "Quote1 Monthly Depreciation %" := 0;
                        exit;
                    end;
                    if CurrFieldNo <> 60034 then //TG190430
                        "Quote1 Monthly Depreciation %" := Round(((("Quote1 Total Cost" - "Quote1 Residual Value" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure")) /
                                                                  "Quote1 Term (Months)") * 100), 0.01) /
                                                                  ("Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure"));
                    "Quote1 Monthly Depreciation" := Round(("Quote1 Total Cost" - "Quote1 Residual Value" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure")) /
                                                              "Quote1 Term (Months)", 0.01);

                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then
                        "Quote1 Monthly Depreciation" := Round("Quote1 Monthly Depreciation", 1, '>');
                    /*---*/
                end;
            2:
                begin
                    /*TG190731*/
                    if "Quote2 Program Code" <> '' then begin
                        ProgramRec.Get("Quote2 Program Code");
                        // if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin
                        //     LoadStepdownArray(2);
                        //  "Quote2 Monthly Depreciation" := Round(DeprAmt, 0.01);
                        /*TG190417*/
                        //  if LeasingSetup."Round Quick Quote Installment" then
                        //       "Quote2 Monthly Depreciation" := Round("Quote2 Monthly Depreciation", 1, '>');
                        //    exit;
                        // end;
                    end;
                    /*---*/
                    if ("Quote2 Term (Months)" = 0) or (("Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure")) = 0) /*or ("Quote2 Residual Value" = 0)*/ then begin
                        "Quote2 Monthly Depreciation" := 0;
                        exit;
                    end;
                    if CurrFieldNo <> 60084 then //TG190430
                        "Quote2 Monthly Depreciation %" := Round(((("Quote2 Total Cost" - "Quote2 Residual Value" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure")) /
                                                                  "Quote2 Term (Months)") * 100), 0.01) /
                                                                  ("Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure"));
                    "Quote2 Monthly Depreciation" := Round(("Quote2 Total Cost" - "Quote2 Residual Value" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure")) /
                                                              "Quote2 Term (Months)", 0.01);
                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then
                        "Quote2 Monthly Depreciation" := Round("Quote2 Monthly Depreciation", 1, '>');
                    /*---*/
                end;
            3:
                begin
                    /*TG190731*/
                    if "Quote3 Program Code" <> '' then begin
                        ProgramRec.Get("Quote3 Program Code");
                        //  if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin
                        //     LoadStepdownArray(3);
                        //  "Quote3 Monthly Depreciation" := Round(DeprAmt, 0.01);
                        /*TG190417*/
                        // if LeasingSetup."Round Quick Quote Installment" then
                        //    "Quote3 Monthly Depreciation" := Round("Quote3 Monthly Depreciation", 1, '>');
                        //   exit;
                        //end;
                    end;
                    /*---*/
                    if ("Quote3 Term (Months)" = 0) or (("Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure")) = 0) /*or ("Quote3 Residual Value" = 0)*/ then begin
                        "Quote3 Monthly Depreciation" := 0;
                        exit;
                    end;
                    if CurrFieldNo <> 60134 then //TG190430
                        "Quote3 Monthly Depreciation %" := Round(((("Quote3 Total Cost" - "Quote3 Residual Value" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure")) /
                                                                  "Quote3 Term (Months)") * 100), 0.01) /
                                                                  ("Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure"));
                    "Quote3 Monthly Depreciation" := Round(("Quote3 Total Cost" - "Quote3 Residual Value" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure")) /
                                                              "Quote3 Term (Months)", 0.01);
                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then
                        "Quote3 Monthly Depreciation" := Round("Quote3 Monthly Depreciation", 1, '>');
                    /*---*/
                end;
        end;
    end;

    local procedure CalcMonthlyInterest(QuoteNo: Integer)
    var
        ScheduleCalcNA: Codeunit "NA Schedule Calc NA";
        "--TG190731--": Integer;
        InArrears: Boolean;
    begin
        LeasingSetup.Get;
        Contract.Get("Contract No.");
        FinProd.Get(Contract."Financial Product");

        if FinProd."Installments Due" = FinProd."Installments Due"::"In Arrears" then
            InArrears := true
        else
            InArrears := false;

        case QuoteNo of
            1:
                begin
                    if ("Quote1 Interest %" = 0) or ("Quote1 Term (Months)" = 0) or ("Quote1 Total Cost" = 0) or
                       ("Quote1 Total Cost" <= ("Quote1 Downpayment" + ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure")))
                    then begin
                        Validate("Quote1 Monthly Interest", 0);
                        exit;
                    end;
                    /*TG190731*/
                    if "Quote1 Program Code" <> '' then begin
                        ProgramRec.Get("Quote1 Program Code");
                        // if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin
                        //   LoadStepdownArray(1);
                        //   Validate("Quote1 Monthly Interest", Round(StepdownAvgArray[1], 0.01));
                        /*TG190417*/
                        //    if LeasingSetup."Round Quick Quote Installment" then begin
                        //     "Quote1 Monthly Interest" := Round("Quote1 Monthly Interest", 1, '>');
                        //    CalcMonthlyPmtExclTax(1);
                        // end;
                        //  exit;
                        // end;
                    end;

                    if InArrears then
                        Validate("Quote1 Monthly Interest", Round(-ScheduleCalcNA.PMTDotNET("Quote1 Interest %" / 12 / 100, "Quote1 Term (Months)",
                                                                  "Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure"),
                                                                                            -"Quote1 Residual Value", InArrears), 0.01) - "Quote1 Monthly Depreciation")
                    else
                        /*---*/
                Validate("Quote1 Monthly Interest",
                        Round(-ScheduleCalcNA.PPmtDotNET("Quote1 Interest %" / 12 / 100, 1, "Quote1 Term (Months)",
                                                          "Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure"),
                                                          //TG190513
                                                          //-"Quote1 Residual Value" + "Quote1 Profit Figure",FALSE),0.01) - "Quote1 Monthly Depreciation");
                                                          -"Quote1 Residual Value", false), 0.01) - "Quote1 Monthly Depreciation");
                    /*---*/
                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then begin
                        "Quote1 Monthly Interest" := Round("Quote1 Monthly Interest", 1, '>');
                        CalcMonthlyPmtExclTax(1);
                    end;
                    /*---*/
                end;
            2:
                begin
                    if ("Quote2 Interest %" = 0) or ("Quote2 Term (Months)" = 0) or ("Quote2 Total Cost" = 0) or
                       ("Quote2 Total Cost" <= ("Quote2 Downpayment" + ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure")))
                    then begin
                        Validate("Quote2 Monthly Interest", 0);
                        exit;
                    end;
                    /*TG190731*/
                    if "Quote2 Program Code" <> '' then begin
                        ProgramRec.Get("Quote2 Program Code");
                        /*    if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin 
                               LoadStepdownArray(2);
                               Validate("Quote2 Monthly Interest", Round(StepdownAvgArray[1], 0.01));

                               if LeasingSetup."Round Quick Quote Installment" then begin
                                   "Quote2 Monthly Interest" := Round("Quote2 Monthly Interest", 1, '>');
                                   CalcMonthlyPmtExclTax(2);
                               end;
                               exit;
                           end; */
                        /*TG190417*/
                    end;

                    if InArrears then
                        Validate("Quote2 Monthly Interest", Round(-ScheduleCalcNA.PMTDotNET("Quote2 Interest %" / 12 / 100, "Quote2 Term (Months)",
                                                                  "Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure"),
                                                                                            -"Quote2 Residual Value", InArrears), 0.01) - "Quote2 Monthly Depreciation")
                    else
                        /*---*/
                Validate("Quote2 Monthly Interest",
                          Round(-ScheduleCalcNA.PPmtDotNET("Quote2 Interest %" / 12 / 100, 1, "Quote2 Term (Months)",
                                "Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure"),
                                                          /*TG190513*/
                                                          //-"Quote2 Residual Value" + "Quote2 Profit Figure",FALSE),0.01) - "Quote2 Monthly Depreciation");
                                                          -"Quote2 Residual Value", false), 0.01) - "Quote2 Monthly Depreciation");
                    /*---*/
                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then begin
                        "Quote2 Monthly Interest" := Round("Quote2 Monthly Interest", 1, '>');
                        CalcMonthlyPmtExclTax(2);
                    end;
                    /*---*/
                end;
            3:
                begin
                    if ("Quote3 Interest %" = 0) or ("Quote3 Term (Months)" = 0) or ("Quote3 Total Cost" = 0) or
                       ("Quote3 Total Cost" <= ("Quote3 Downpayment" + ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure")))
                    then begin
                        Validate("Quote3 Monthly Interest", 0);
                        exit;
                    end;
                    /*TG190731*/
                    if "Quote3 Program Code" <> '' then begin
                        ProgramRec.Get("Quote3 Program Code");
                        /*   if ProgramRec."Schedule Type" = ProgramRec."Schedule Type"::Stepdown then begin
                              LoadStepdownArray(3);
                              Validate("Quote3 Monthly Interest", Round(StepdownAvgArray[1], 0.01));

                              if LeasingSetup."NA Round Quick Quote Inst." then begin
                                  "Quote3 Monthly Interest" := Round("Quote3 Monthly Interest", 1, '>');
                                  CalcMonthlyPmtExclTax(3);
                              end;
                              exit;
                          end; */ /*TG190417*/
                    end;

                    if InArrears then
                        Validate("Quote3 Monthly Interest", Round(-ScheduleCalcNA.PMTDotNET("Quote3 Interest %" / 12 / 100, "Quote3 Term (Months)",
                                                                  "Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure"),
                                                                                            -"Quote3 Residual Value", InArrears), 0.01) - "Quote3 Monthly Depreciation")
                    else
                        /*---*/
                Validate("Quote3 Monthly Interest",
                          Round(-ScheduleCalcNA.PPmtDotNET("Quote3 Interest %" / 12 / 100, 1, "Quote3 Term (Months)",
                                "Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure"),
                                                          /*TG190513*/
                                                          //-"Quote3 Residual Value" + "Quote3 Profit Figure",FALSE),0.01) - "Quote3 Monthly Depreciation");
                                                          -"Quote3 Residual Value", false), 0.01) - "Quote3 Monthly Depreciation");
                    /*---*/
                    /*TG190417*/
                    if LeasingSetup."NA Round Quick Quote Inst." then begin
                        "Quote3 Monthly Interest" := Round("Quote3 Monthly Interest", 1, '>');
                        CalcMonthlyPmtExclTax(3);
                    end;
                    /*---*/
                end;
        end;

    end;

    procedure OnValidateAssetNo(Assno: code[20]; xx: Integer): Boolean
    var
        Lfa: Record "fixed asset";
    begin
        if not Lfa.Get(Assno) then begin
            message(STRSUBSTNO(Err50001, xx));
            exit(false);
        end else
            exit(true);
    end;

    local procedure CalcMonthlyPmtExclTax(QuoteNo: Integer)
    begin
        ////GetContext(0);
        case QuoteNo of
            1:
                if CurrFieldNo <> 60044 then //TG200507 - fix endless loop
                    if LeasingSetup."NA Round Quick Quote Inst." then
                        Validate("Quote1 Monthly Pmt. Excl. Tax", Round("Quote1 Monthly Overhead" + "Quote1 Monthly Interest" + "Quote1 Monthly Depreciation" + "Quote1 Monthly Insurance", 1))
                    else
                        Validate("Quote1 Monthly Pmt. Excl. Tax", "Quote1 Monthly Overhead" + "Quote1 Monthly Interest" + "Quote1 Monthly Depreciation" + "Quote1 Monthly Insurance");
            2:
                if CurrFieldNo <> 60094 then //TG200507 - fix endless loop
                    if LeasingSetup."NA Round Quick Quote Inst." then
                        Validate("Quote2 Monthly Pmt. Excl. Tax", Round("Quote2 Monthly Overhead" + "Quote2 Monthly Interest" + "Quote2 Monthly Depreciation" + "Quote2 Monthly Insurance", 1))
                    else
                        Validate("Quote2 Monthly Pmt. Excl. Tax", "Quote2 Monthly Overhead" + "Quote2 Monthly Interest" + "Quote2 Monthly Depreciation" + "Quote2 Monthly Insurance");
            3:
                if CurrFieldNo <> 60144 then //TG200507 - fix endless loop
                    if LeasingSetup."NA Round Quick Quote Inst." then
                        Validate("Quote3 Monthly Pmt. Excl. Tax", Round("Quote3 Monthly Overhead" + "Quote3 Monthly Interest" + "Quote3 Monthly Depreciation" + "Quote3 Monthly Insurance", 1))
                    else
                        Validate("Quote3 Monthly Pmt. Excl. Tax", "Quote3 Monthly Overhead" + "Quote3 Monthly Interest" + "Quote3 Monthly Depreciation" + "Quote3 Monthly Insurance");
        end;
    end;

    local procedure CalcTax(QuoteNo: Integer)
    var
        ContractMgt: Codeunit "S4LA Contract Mgt";
        PrincipalVAT: Decimal;
    begin
        //GetContext(0);
        PrincipalVAT := ContractMgt.GetVATfactor(Contract."Customer VAT Bus. Group", FinProd."Principal VAT Gr.(Instalment)");
        case QuoteNo of
            1:
                begin
                    "Quote1 Tax Rate" := PrincipalVAT * 100;
                    if ("Quick Quote Date" = 0D) or ("Quote1 Monthly Pmt. Excl. Tax" = 0) then begin
                        Validate("Quote1 Tax Amount", 0);
                        exit;
                    end;
                    Validate("Quote1 Tax Amount", Round("Quote1 Monthly Pmt. Excl. Tax" * PrincipalVAT, Currency."Amount Rounding Precision"));
                end;
            2:
                begin
                    "Quote2 Tax Rate" := PrincipalVAT * 100;
                    if ("Quick Quote Date" = 0D) or ("Quote2 Monthly Pmt. Excl. Tax" = 0) then begin
                        Validate("Quote2 Tax Amount", 0);
                        exit;
                    end;
                    Validate("Quote2 Tax Amount", Round("Quote2 Monthly Pmt. Excl. Tax" * PrincipalVAT, Currency."Amount Rounding Precision"));
                end;
            3:
                begin
                    "Quote3 Tax Rate" := PrincipalVAT * 100;
                    if ("Quick Quote Date" = 0D) or ("Quote3 Monthly Pmt. Excl. Tax" = 0) then begin
                        Validate("Quote3 Tax Amount", 0);
                        exit;
                    end;
                    Validate("Quote3 Tax Amount", Round("Quote3 Monthly Pmt. Excl. Tax" * PrincipalVAT, Currency."Amount Rounding Precision"));
                end;
        end;

    end;

    local procedure CalcCommission(QuoteNo: Integer)
    var
        Schema: Record "S4LA Commission Schema";
    begin
        // Comm. % * ((monthly overhead amt  * term) + profit amount)
        case QuoteNo of
            1:
                begin
                    if "Quote1 Commission Schema" = '' then
                        exit;
                    Schema.Get("Quote1 Commission Schema");
                    Validate("Quote1 Commission", Schema.fnCommissionAmt("Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure"), "Quote1 Term (Months)", "Quote1 Interest %",
                             "Quote1 Profit Figure", "Quote1 Monthly Overhead"));
                end;
            2:
                begin
                    if "Quote2 Commission Schema" = '' then
                        exit;
                    Schema.Get("Quote2 Commission Schema");
                    Validate("Quote2 Commission", Schema.fnCommissionAmt("Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure"), "Quote2 Term (Months)", "Quote2 Interest %",
                             "Quote2 Profit Figure", "Quote2 Monthly Overhead"));
                end;
            3:
                begin
                    if "Quote3 Commission Schema" = '' then
                        exit;
                    Schema.Get("Quote3 Commission Schema");
                    Validate("Quote3 Commission", Schema.fnCommissionAmt("Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure"), "Quote3 Term (Months)", "Quote3 Interest %",
                             "Quote3 Profit Figure", "Quote3 Monthly Overhead"));
                end;
        end;
    end;

    local procedure UpdateNumberOfPaymentPeriods(QuoteNo: Integer)
    var
        TermRecord: Record "S4LA Term";
        Term: Code[20];
    begin
        case QuoteNo of
            1:
                if "Quote1 Term" <> '' then begin
                    TermRecord.Get("Quote1 Term");
                    if TermRecord."Allow Custom Term" then begin
                        Validate("Quote1 Term (Months)");
                        exit;
                    end;
                    if TermRecord."Number Of Months" <> 0 then
                        Validate("Quote1 Term (Months)", Round(TermRecord."Number Of Months", 1, '>'));
                end else
                    Validate("Quote1 Term (Months)", 0);
            2:
                if "Quote2 Term" <> '' then begin
                    TermRecord.Get("Quote2 Term");
                    if TermRecord."Allow Custom Term" then begin
                        Validate("Quote2 Term (Months)");
                        exit;
                    end;
                    if TermRecord."Number Of Months" <> 0 then
                        Validate("Quote2 Term (Months)", Round(TermRecord."Number Of Months", 1, '>'));
                end else
                    Validate("Quote2 Term (Months)", 0);
            3:
                if "Quote3 Term" <> '' then begin
                    TermRecord.Get("Quote3 Term");
                    if TermRecord."Allow Custom Term" then begin
                        Validate("Quote3 Term (Months)");
                        exit;
                    end;
                    if TermRecord."Number Of Months" <> 0 then
                        Validate("Quote3 Term (Months)", Round(TermRecord."Number Of Months", 1, '>'));
                end else
                    Validate("Quote3 Term (Months)", 0);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckForAcceptedQuote(): Boolean
    begin
        if not ("Quote1 Accepted" or "Quote2 Accepted" or "Quote3 Accepted") then
            Error(Text50000);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure FillFromQuote1()
    var
        quickQuoteService: Record "Quick Quote Service";
        NewquickQuoteService2: Record "Quick Quote Service";
        NewquickQuoteService3: Record "Quick Quote Service";

    begin
        "Quote2 Asset No." := "Quote1 Asset No.";
        "Quote2 Commission" := "Quote1 Commission";
        "Quote2 Commission Schema" := "Quote1 Commission Schema";
        "Quote2 Color of Vehicle" := "Quote1 Color of Vehicle";
        "Quote2 Commission" := "Quote1 Commission";
        "Quote2 Customer Residual" := "Quote1 Customer Residual";
        "Quote2 Downpayment" := "Quote1 Downpayment";
        "Quote2 Interest %" := "Quote1 Interest %";
        "Quote2 Int. Rate Modified" := "Quote1 Int. Rate Modified";
        "Quote2 Interior Color" := "Quote1 Interior Color";
        "Quote2 Manufacturer" := "Quote1 Manufacturer";
        "Quote2 Model" := "Quote1 Model";
        "Quote2 Model Year" := "Quote1 Model Year";
        "Quote2 Monthly Depreciation" := "Quote1 Monthly Depreciation";
        "Quote2 Monthly Depreciation %" := "Quote1 Monthly Depreciation %";
        "Quote2 Monthly Interest" := "Quote1 Monthly Interest";
        "Quote2 Monthly Overhead" := "Quote1 Monthly Overhead";
        "Quote2 Monthly Pmt. Excl. Tax" := "Quote1 Monthly Pmt. Excl. Tax";
        "Quote2 Monthly Pmt. Incl. Tax" := "Quote1 Monthly Pmt. Incl. Tax";
        "Quote2 Profit Figure" := "Quote1 Profit Figure";
        "Quote2 Program Code" := "Quote1 Program Code";
        "Quote2 Purchase Price" := "Quote1 Purchase Price";
        "Quote2 Refin. Pay-out Figure" := "Quote1 Refin. Pay-out Figure";
        "Quote2 Residual Value" := "Quote1 Residual Value";
        "Quote2 Tax Rate" := "Quote1 Tax Rate";
        "Quote2 Tax Amount" := "Quote1 Tax Amount";
        // "Quote2 Original Tax Area Code" := "Quote1 Original Tax Area Code";
        "Quote2 Term" := "Quote1 Term";
        "Quote2 Term (Months)" := "Quote1 Term (Months)";
        "Quote2 Total Addons" := "Quote1 Total Addons";
        "Quote2 Total Cost" := "Quote1 Total Cost";
        "Quote2 Trade-In Cost" := "Quote1 Trade-In Cost";
        "Quote2 Vehicle Notes" := "Quote1 Vehicle Notes";

        "Quote3 Asset No." := "Quote1 Asset No.";
        "Quote3 Commission" := "Quote1 Commission";
        "Quote3 Commission Schema" := "Quote1 Commission Schema";
        "Quote3 Color of Vehicle" := "Quote1 Color of Vehicle";
        "Quote3 Customer Residual" := "Quote1 Customer Residual";
        "Quote3 Downpayment" := "Quote1 Downpayment";
        "Quote3 Interest %" := "Quote1 Interest %";
        "Quote3 Int. Rate Modified" := "Quote1 Int. Rate Modified";
        "Quote3 Interior Color" := "Quote1 Interior Color";
        "Quote3 Manufacturer" := "Quote1 Manufacturer";
        "Quote3 Model" := "Quote1 Model";
        "Quote3 Model Year" := "Quote1 Model Year";
        "Quote3 Monthly Depreciation" := "Quote1 Monthly Depreciation";
        "Quote3 Monthly Depreciation %" := "Quote1 Monthly Depreciation %";
        "Quote3 Monthly Interest" := "Quote1 Monthly Interest";
        "Quote3 Monthly Overhead" := "Quote1 Monthly Overhead";
        "Quote3 Monthly Pmt. Excl. Tax" := "Quote1 Monthly Pmt. Excl. Tax";
        "Quote3 Monthly Pmt. Incl. Tax" := "Quote1 Monthly Pmt. Incl. Tax";
        "Quote3 Profit Figure" := "Quote1 Profit Figure";
        "Quote3 Program Code" := "Quote1 Program Code";
        "Quote3 Purchase Price" := "Quote1 Purchase Price";
        "Quote3 Refin. Pay-out Figure" := "Quote1 Refin. Pay-out Figure";
        "Quote3 Residual Value" := "Quote1 Residual Value";
        "Quote3 Tax Rate" := "Quote1 Tax Rate";
        "Quote3 Tax Amount" := "Quote1 Tax Amount";
        "Quote3 Term" := "Quote1 Term";
        "Quote3 Term (Months)" := "Quote1 Term (Months)";
        "Quote3 Total Addons" := "Quote1 Total Addons";
        "Quote3 Total Cost" := "Quote1 Total Cost";
        "Quote3 Trade-In Cost" := "Quote1 Trade-In Cost";
        "Quote3 Vehicle Notes" := "Quote1 Vehicle Notes";

        //for Services & Insurance drill down fields
        "Quote2 Upfront Services" := "Quote1 Upfront Services";
        "Quote2 Services" := "Quote1 Services";
        "Quote2 Monthly Overhead" := "Quote1 Monthly Overhead";
        "Quote2 Monthly Insurance" := "Quote1 Monthly Insurance";


        "Quote2 Financed Insurance" := "Quote1 Financed Insurance";
        "Quote2 Insurance Services" := "Quote1 Insurance Services";

        "Quote3 Upfront Services" := "Quote1 Upfront Services";
        "Quote3 Services" := "Quote1 Services";
        "Quote3 Monthly Overhead" := "Quote1 Monthly Overhead";

        "Quote3 Financed Insurance" := "Quote1 Financed Insurance";
        "Quote3 Insurance Services" := "Quote1 Insurance Services";
        "Quote3 Monthly Insurance" := "Quote1 Monthly Insurance";

        //Update quick quote service records

        quickQuoteService.setrange("Contract No.", Rec."Contract No.");
        quickQuoteService.SetFilter("Quick Quote No.", '%1|%2', 2, 3);
        quickQuoteService.DeleteAll();

        quickQuoteService.Reset();
        quickQuoteService.SetRange("Quick Quote No.", 1);
        quickQuoteService.SetRange("Contract No.", Rec."Contract No.");
        if quickQuoteService.FindFirst() then
            repeat

                NewquickQuoteService2.init;
                NewquickQuoteService2.TransferFields(quickQuoteService);
                NewquickQuoteService2."Quick Quote No." := 2;
                NewquickQuoteService2.insert;

                NewquickQuoteService3.init;
                NewquickQuoteService3.TransferFields(quickQuoteService);
                NewquickQuoteService3."Quick Quote No." := 3;
                NewquickQuoteService3.insert;

            until quickQuoteService.next = 0;


        onAfterFillFromQuote(rec);
    end;

    [Scope('OnPrem')]
    procedure SetQuickEntry(QuoteNo: Integer; var QuickQuoteWksht: Record "Quick Quote Worksheet")
    begin
        case QuoteNo of
            1:
                begin
                    QuickQuoteWksht.QuickEntry1 := true;
                    QuickQuoteWksht.QuickEntry2 := false;
                    QuickQuoteWksht.QuickEntry3 := false;
                end;
            2:
                begin
                    QuickQuoteWksht.QuickEntry1 := false;
                    QuickQuoteWksht.QuickEntry2 := true;
                    QuickQuoteWksht.QuickEntry3 := false;
                end;
            3:
                begin
                    QuickQuoteWksht.QuickEntry1 := false;
                    QuickQuoteWksht.QuickEntry2 := false;
                    QuickQuoteWksht.QuickEntry3 := true;
                end;
        end;
    end;

    //local procedure GetContext(QuoteNo: Integer)
    //var
    //        Schedule: Record "S4LA Schedule"
    //    begin
    //        LeasingSetup.Get;
    //        Clear(Schedule);
    //        Clear(Contract);
    //Clear(FinProd);
    //if Contract.Get("Contract No.") then begin
    //Contract.GetValidSchedule(Schedule);
    //FinProd.Get(Contract."Financial Product");
    //end;

    //GLSetup.Get;
    //if not Currency.Get(Schedule."Currency Code") then
    //Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";

    //case QuoteNo of
    //1:
    //OnGetContext(rec, 1);
    //2:
    //On//GetContext(rec, 2);
    //3:
    //On//GetContext(rec, 3);
    //end;
    //end;

    local procedure OnValidateProgramCode(QuoteNo: Integer)
    var
        ProgramRec: Record "S4LA Program";
        ProgramRates: Record "S4LA Program Rate";
        Schedule: Record "S4LA Schedule";
        ProgramCode: Code[20];
        TermCode: Code[20];
        InterestPct: Decimal;
        ResValuePct: Decimal;
        IntRateMarkup: Decimal;
        FundedRate: Decimal;

    begin
        case QuoteNo of
            1:
                ProgramCode := "Quote1 Program Code";
            2:
                ProgramCode := "Quote2 Program Code";
            3:
                ProgramCode := "Quote3 Program Code";
        end;

        if ProgramCode <> '' then begin
            if not ProgramRec.Get(ProgramCode) then
                exit;
            TermCode := ProgramRec.Term;
            Contract.Get("Contract No.");
            Contract.GetNewestSchedule(Schedule);
            GetRates(ProgramRates, QuoteNo);
            // InterestPct := ProgramRates."Standard Rate";
            /*TG191219*/
            Contract.fnSystemIntRate(InterestPct, IntRateMarkup, FundedRate, QuoteNo, Rec);
            /*---*/
            ResValuePct := ProgramRec."Residual Value %";
        end;

        case QuoteNo of
            1:
                begin
                    Validate("Quote1 Term", TermCode);
                    if ("Quote1 Program Code" = '') and (InterestPct = 0) then
                        "Quote1 Int. Rate Modified" := false;
                    Validate("Quote1 Interest %", InterestPct);
                end;
            2:
                begin
                    Validate("Quote2 Term", TermCode);
                    if ("Quote2 Program Code" = '') and (InterestPct = 0) then
                        "Quote2 Int. Rate Modified" := false;
                    Validate("Quote2 Interest %", InterestPct);
                end;
            3:
                begin
                    Validate("Quote3 Term", TermCode);
                    if ("Quote3 Program Code" = '') and (InterestPct = 0) then
                        "Quote3 Int. Rate Modified" := false;
                    Validate("Quote3 Interest %", InterestPct);
                end;
        end;
    end;

    procedure GetRates(var ProgramRates: Record "S4LA Program Rate"; QuoteNo: Integer)
    var
        Asset: Record "S4LA Asset";
        New: Boolean;
        Used: Boolean;
        ProgramCode: Code[20];
        TermMonths: Integer;
        NetCapAmt: Decimal;
    begin
        case QuoteNo of
            1:
                begin
                    ProgramCode := "Quote1 Program Code";
                    TermMonths := "Quote1 Term (Months)";
                    NetCapAmt := "Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure");
                end;
            2:
                begin
                    ProgramCode := "Quote2 Program Code";
                    TermMonths := "Quote2 Term (Months)";
                    NetCapAmt := "Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure");
                end;
            3:
                begin
                    ProgramCode := "Quote3 Program Code";
                    TermMonths := "Quote3 Term (Months)";
                    NetCapAmt := "Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure");
                end;
        end;

        if ProgramCode = '' then
            exit;

        //------------- Find best matching rates record
        ProgramRates.Reset;
        ProgramRates.SetCurrentKey("Program Code", "Standard Rate"); // sorting per Standard Rate is important - findfirst gives lowest rate from all applicable
        ProgramRates.SetRange("Program Code", ProgramCode);
        ProgramRates.SetFilter("Fin. Product", '%1|%2', '', Contract."Financial Product");
        ProgramRates.SetFilter("Asset Group", '%1|%2', '', Contract."Overall Asset Group");
        case Contract."New / Used Asset" of
            Contract."New / Used Asset"::New:
                ProgramRates.SetFilter("Asset New/Used", '%1|%2', ProgramRates."Asset New/Used"::" ", ProgramRates."Asset New/Used"::New);
            Contract."New / Used Asset"::Used:
                ProgramRates.SetFilter("Asset New/Used", '%1|%2', ProgramRates."Asset New/Used"::" ", ProgramRates."Asset New/Used"::Used);
            else
                ProgramRates.SetFilter("Asset New/Used", '%1', ProgramRates."Asset New/Used"::" ");
        end;

        ProgramRates.SetFilter("Min NAF", '%1|..%2', 0, NetCapAmt);
        ProgramRates.SetFilter("Max NAF", '%1|%2..', 0, NetCapAmt);
        ProgramRates.SetFilter("Min Term (mths)", '%1|..%2', 0, TermMonths);
        ProgramRates.SetFilter("Valid From", '%1|..%2', 0D, "Quick Quote Date");
        ProgramRates.SetFilter("Valid Until", '%1|%2..', 0D, Contract."Quote Valid Until");

        if not ProgramRates.FindFirst then
            ProgramRates.Init;
    end;

    [Scope('OnPrem')]
    procedure ValidateContr()
    begin
        /*TG190314*/
        Contract.Get("Contract No.");
        Contract.TestField(Name);
        //Contract.TESTFIELD("E-Mail");
        //Contract.TESTFIELD(Address);
        //Contract.TESTFIELD(City);
        //Contract.TESTFIELD(County);
        //Contract.TESTFIELD("Post Code");
        //Contract.TESTFIELD("Phone No.");

    end;

    [Scope('OnPrem')]
    procedure ClearRec()
    var
        QuickQuoteWkshtOld: Record "Quick Quote Worksheet";
        QuickQuoteWkshtNew: Record "Quick Quote Worksheet";
    begin
        QuickQuoteWkshtOld := Rec;
        QuickQuoteWkshtNew.Init;
        QuickQuoteWkshtNew."Contract No." := QuickQuoteWkshtOld."Contract No.";
        QuickQuoteWkshtNew."Quick Quote Date" := QuickQuoteWkshtOld."Quick Quote Date";
        Rec := QuickQuoteWkshtNew;
        Modify;
        Get(QuickQuoteWkshtOld."Contract No.");

    end;

    [Scope('OnPrem')]
    procedure ClearQuotes2And3(var QuickQuoteWksht: Record "Quick Quote Worksheet"; ClearColumn: array[3] of Boolean)
    var
        //QuickQuoteService: Record "Interface Error Log ";
        FilterString: Text;
        QuickQuoteService: Record "Quick Quote Service";
    begin
        /*TG190430*/
        if ClearColumn[1] then begin
            Clear("Quote1 Accepted");
            Clear("Quote1 Asset No.");
            Clear("Quote1 Bonus");
            Clear("Quote1 Color of Vehicle");
            Clear("Quote1 Customer Residual");
            Clear("Quote1 Commission");
            Clear("Quote1 Downpayment");
            Clear("Quote1 Interest %");
            Clear("Quote1 Interior Color");
            Clear("Quote1 Manufacturer");
            Clear("Quote1 Model");
            Clear("Quote1 Model Year");
            Clear("Quote1 Monthly Depreciation");
            Clear("Quote1 Monthly Depreciation %");
            Clear("Quote1 Monthly Interest");
            Clear("Quote1 Monthly Overhead");
            Clear("Quote1 Monthly Pmt. Excl. Tax");
            Clear("Quote1 Monthly Pmt. Incl. Tax");
            Clear("Quote1 Print");
            Clear("Quote1 Profit Figure");
            Clear("Quote1 Program Code");
            Clear("Quote1 Purchase Price");
            Clear("Quote1 Refin. Pay-out Figure");
            Clear("Quote1 Residual Value");
            Clear("Quote1 Tax Amount");
            Clear("Quote1 Tax Rate");
            Clear("Quote1 Term");
            Clear("Quote1 Term (Months)");
            Clear("Quote1 Total Addons");
            Clear("Quote1 Total Cost");
            Clear("Quote1 Trade-In Cost");
            Clear("Quote1 Vehicle Notes");
            Clear("Quote1 Int. Rate Modified");


            clear("Quote1 Upfront Services");
            clear("Quote1 Services");
            clear("Quote1 Monthly Overhead");
            clear("Quote1 Financed Insurance");
            clear("Quote1 Insurance Services");
            clear("Quote1 Monthly Insurance");


            onClearQuote(rec, 1);
        end;
        if ClearColumn[2] or not (ClearColumn[1] or ClearColumn[2] or ClearColumn[3]) then begin
            Clear("Quote2 Accepted");
            Clear("Quote2 Asset No.");
            Clear("Quote2 Bonus");
            Clear("Quote2 Color of Vehicle");
            Clear("Quote2 Commission");
            Clear("Quote2 Customer Residual");
            Clear("Quote2 Downpayment");
            Clear("Quote2 Interest %");
            Clear("Quote2 Interior Color");
            Clear("Quote2 Manufacturer");
            Clear("Quote2 Model");
            Clear("Quote2 Model Year");
            Clear("Quote2 Monthly Depreciation");
            Clear("Quote2 Monthly Depreciation %");
            Clear("Quote2 Monthly Interest");
            Clear("Quote2 Monthly Overhead");
            Clear("Quote2 Monthly Pmt. Excl. Tax");
            Clear("Quote2 Monthly Pmt. Incl. Tax");
            Clear("Quote2 Print");
            Clear("Quote2 Profit Figure");
            Clear("Quote2 Program Code");
            Clear("Quote2 Purchase Price");
            Clear("Quote2 Refin. Pay-out Figure");
            Clear("Quote2 Residual Value");
            Clear("Quote2 Tax Amount");
            Clear("Quote2 Tax Rate");
            Clear("Quote2 Term");
            Clear("Quote2 Term (Months)");
            Clear("Quote2 Total Addons");
            Clear("Quote2 Total Cost");
            Clear("Quote2 Trade-In Cost");
            Clear("Quote2 Vehicle Notes");
            Clear("Quote2 Int. Rate Modified");
            clear("Quote2 Upfront Services");
            clear("Quote2 Services");
            clear("Quote2 Monthly Overhead");
            clear("Quote2 Financed Insurance");
            clear("Quote2 Insurance Services");
            clear("Quote2 Monthly Insurance");
            onClearQuote(rec, 2);
        end;

        if ClearColumn[3] or not (ClearColumn[1] or ClearColumn[2] or ClearColumn[3]) then begin
            Clear("Quote3 Accepted");
            Clear("Quote3 Asset No.");
            Clear("Quote3 Bonus");
            Clear("Quote3 Color of Vehicle");
            Clear("Quote3 Customer Residual");
            Clear("Quote3 Commission");
            Clear("Quote3 Downpayment");
            Clear("Quote3 Interest %");
            Clear("Quote3 Interior Color");
            Clear("Quote3 Manufacturer");
            Clear("Quote3 Model");
            Clear("Quote3 Model Year");
            Clear("Quote3 Monthly Depreciation");
            Clear("Quote3 Monthly Depreciation %");
            Clear("Quote3 Monthly Interest");
            Clear("Quote3 Monthly Overhead");
            Clear("Quote3 Monthly Pmt. Excl. Tax");
            Clear("Quote3 Monthly Pmt. Incl. Tax");
            Clear("Quote3 Print");
            Clear("Quote3 Profit Figure");
            Clear("Quote3 Program Code");
            Clear("Quote3 Purchase Price");
            Clear("Quote3 Refin. Pay-out Figure");
            Clear("Quote3 Residual Value");
            Clear("Quote3 Tax Amount");
            Clear("Quote3 Tax Rate");
            Clear("Quote3 Term");
            Clear("Quote3 Term (Months)");
            Clear("Quote3 Total Addons");
            Clear("Quote3 Total Cost");
            Clear("Quote3 Trade-In Cost");
            Clear("Quote3 Vehicle Notes");
            Clear("Quote3 Int. Rate Modified");
            clear("Quote3 Upfront Services");
            clear("Quote3 Services");
            clear("Quote3 Monthly Overhead");
            clear("Quote3 Financed Insurance");
            clear("Quote3 Insurance Services");
            clear("Quote3 Monthly Insurance");
            onClearQuote(rec, 3);
        end;

        QuickQuoteService.SETRANGE("Contract No.", "Contract No.");
        case true of
            not (ClearColumn[1] or ClearColumn[2] or ClearColumn[3]): // no columns selected
                QuickQuoteService.SETRANGE("Quick Quote No.", 2, 3);
            ClearColumn[1] and ClearColumn[2] and ClearColumn[3]: // all columns selected
                QuickQuoteService.SETRANGE("Quick Quote No.");
            ClearColumn[1] and ClearColumn[2]: // 1 and 2 only
                QuickQuoteService.SETRANGE("Quick Quote No.", 1, 2);
            ClearColumn[1] and ClearColumn[3]: // 1 and 3 only
                QuickQuoteService.SETFILTER("Quick Quote No.", '%1|%2', 1, 3);
            ClearColumn[2] and ClearColumn[3]: // 2 and 3 only
                QuickQuoteService.SETRANGE("Quick Quote No.", 2, 3);
            ClearColumn[1]: // column 1 only
                QuickQuoteService.SETRANGE("Quick Quote No.", 1);
            ClearColumn[2]: // column 2 only
                QuickQuoteService.SETRANGE("Quick Quote No.", 2);
            ClearColumn[3]: // column 3 only
                QuickQuoteService.SETRANGE("Quick Quote No.", 3);
        end;
        QuickQuoteService.DELETEALL;

    end;

    local procedure FillFixedValue(QuoteNo: Integer)
    var
        ResidualValue: Decimal;
        NAFNew: Decimal;
        ValueToFix: Option " ","Asset Price",Downpayment,"Residual Value","Trade-in Value";
    begin
        /*TG190707*/ // Removed trade-in and refin. payout fields
        "Value To Fix" := "Value To Fix"::" ";
        Clear(pselectValuetoFix);

        pselectValuetoFix.LookupMode(true);
        if pselectValuetoFix.RunModal = ACTION::LookupOK then begin
            pselectValuetoFix.GetValuetoFix("Value To Fix");

            case QuoteNo of
                1:
                    case "Value To Fix" of
                        "Value To Fix"::" ":
                            exit;
                        "Value To Fix"::"Asset Price":
                            begin
                                NAFNew := CalcNAFFromPMT(1);
                                Validate("Quote1 Purchase Price", NAFNew - "Quote1 Total Addons" + ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure") + "Quote1 Downpayment");
                            end;
                        "Value To Fix"::Downpayment:
                            begin
                                NAFNew := CalcNAFFromPMT(1);
                                Validate("Quote1 Downpayment", "Quote1 Total Cost" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure") - NAFNew);
                            end;
                        "Value To Fix"::"Residual Value":
                            Validate("Quote1 Residual Value", CalcResidualFromPMT(1));
                        "Value To Fix"::"Trade-in Value":
                            begin
                                NAFNew := CalcNAFFromPMT(1);
                                Validate("Quote1 Trade-In Cost", "Quote1 Total Cost" - "Quote1 Downpayment" - NAFNew + ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure"));
                            end;
                    end;
                2:
                    case "Value To Fix" of
                        "Value To Fix"::" ":
                            exit;
                        "Value To Fix"::"Asset Price":
                            begin
                                NAFNew := CalcNAFFromPMT(2);
                                Validate("Quote2 Purchase Price", NAFNew - "Quote2 Total Addons" + ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure") + "Quote2 Downpayment");
                            end;
                        "Value To Fix"::Downpayment:
                            begin
                                NAFNew := CalcNAFFromPMT(2);
                                Validate("Quote2 Downpayment", "Quote2 Total Cost" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure") - NAFNew);
                            end;
                        "Value To Fix"::"Residual Value":
                            Validate("Quote2 Residual Value", CalcResidualFromPMT(2));
                        "Value To Fix"::"Trade-in Value":
                            begin
                                NAFNew := CalcNAFFromPMT(2);
                                Validate("Quote2 Trade-In Cost", "Quote2 Total Cost" - "Quote2 Downpayment" - NAFNew + ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure"));
                            end;
                    end;
                3:
                    case "Value To Fix" of
                        "Value To Fix"::" ":
                            exit;
                        "Value To Fix"::"Asset Price":
                            begin
                                NAFNew := CalcNAFFromPMT(3);
                                Validate("Quote3 Purchase Price", NAFNew - "Quote3 Total Addons" + ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure") + "Quote3 Downpayment");
                            end;
                        "Value To Fix"::Downpayment:
                            begin
                                NAFNew := CalcNAFFromPMT(3);
                                Validate("Quote3 Downpayment", "Quote3 Total Cost" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure") - NAFNew);
                            end;
                        "Value To Fix"::"Residual Value":
                            Validate("Quote3 Residual Value", CalcResidualFromPMT(3));
                        "Value To Fix"::"Trade-in Value":
                            begin
                                NAFNew := CalcNAFFromPMT(3);
                                Validate("Quote3 Trade-In Cost", "Quote3 Total Cost" - "Quote3 Downpayment" - NAFNew + ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure"));
                            end;
                    end;
            end;
        end;

    end;

    local procedure CalcNAFFromPMT(QuoteNo: Integer) NAF: Decimal
    var
        Pmt: Decimal;
        IntRate: Decimal;
        ResidualValue: Decimal;
        TermMonths: Integer;
        NoAdvPmts: Integer;
    begin
        // Calc net amount financed for Lacolle only (because their payment amount not corrected as in Ensign, SouthGate and Sommerville)
        //GetContext(QuoteNo); //TG190908
        case QuoteNo of
            1:
                begin
                    IntRate := "Quote1 Interest %";
                    TermMonths := "Quote1 Term (Months)";
                    Pmt := "Quote1 Monthly Pmt. Excl. Tax" - "Quote1 Monthly Overhead";
                    ResidualValue := "Quote1 Residual Value";
                end;
            2:
                begin
                    IntRate := "Quote2 Interest %";
                    TermMonths := "Quote2 Term (Months)";
                    Pmt := "Quote2 Monthly Pmt. Excl. Tax" - "Quote2 Monthly Overhead";
                    ResidualValue := "Quote2 Residual Value";
                end;
            3:
                begin
                    IntRate := "Quote3 Interest %";
                    TermMonths := "Quote3 Term (Months)";
                    Pmt := "Quote3 Monthly Pmt. Excl. Tax" - "Quote3 Monthly Overhead";
                    ResidualValue := "Quote3 Residual Value";
                end;
        end;
        if (IntRate = 0) or (TermMonths = 0) then
            exit(0);
        IntRate := IntRate / 100 / 12;
        /*TG190908*/
        if FinProd."Installments Due" = FinProd."Installments Due"::"In Arrears" then
            NoAdvPmts := 0
        else
            /*---*/
          NoAdvPmts := 1;
        NAF := Round(((Pmt * (((1 - (1 / Power(1 + IntRate, TermMonths - NoAdvPmts))) / IntRate) + NoAdvPmts)) - (-ResidualValue / Power(1 + IntRate, TermMonths))), 1);

        if CalcPMTFromNAF(QuoteNo, NAF) <> Pmt then
            NAF := Round(((Pmt * (((1 - (1 / Power(1 + IntRate, TermMonths - NoAdvPmts))) / IntRate) + NoAdvPmts)) - (-ResidualValue / Power(1 + IntRate, TermMonths))), 0.1);
        if CalcPMTFromNAF(QuoteNo, NAF) <> Pmt then
            NAF := Round(((Pmt * (((1 - (1 / Power(1 + IntRate, TermMonths - NoAdvPmts))) / IntRate) + NoAdvPmts)) - (-ResidualValue / Power(1 + IntRate, TermMonths))), 0.01);

    end;

    local procedure CalcResidualFromPMT(QuoteNo: Integer) ResidualValue: Decimal
    var
        Pmt: Decimal;
        PV: Decimal;
        IntRate: Decimal;
        TermMonths: Integer;
        NoAdvPmts: Integer;
    begin
        // Calc residual value as if using Sommerville or Ensign database. Not used in Lacolle.
        //GetContext(QuoteNo); //TG190908
        /*TG190707*/ // Removed trade-in and refin. payout fields
        case QuoteNo of
            1:
                begin
                    IntRate := "Quote1 Interest %";
                    TermMonths := "Quote1 Term (Months)";
                    Pmt := "Quote1 Monthly Pmt. Excl. Tax" - "Quote1 Monthly Overhead";
                    PV := "Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure");
                end;
            2:
                begin
                    IntRate := "Quote2 Interest %";
                    TermMonths := "Quote2 Term (Months)";
                    Pmt := "Quote2 Monthly Pmt. Excl. Tax" - "Quote2 Monthly Overhead";
                    PV := "Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure");
                end;
            3:
                begin
                    IntRate := "Quote3 Interest %";
                    TermMonths := "Quote3 Term (Months)";
                    Pmt := "Quote3 Monthly Pmt. Excl. Tax" - "Quote3 Monthly Overhead";
                    PV := "Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure");
                end;
        end;
        if (IntRate = 0) or (TermMonths = 0) then
            exit(0);
        IntRate := IntRate / 100 / 12;
        /*TG190908*/
        if FinProd."Installments Due" = FinProd."Installments Due"::"In Arrears" then
            NoAdvPmts := 0
        else
            /*---*/
          NoAdvPmts := 1;
        ResidualValue := Round(-(((Pmt * (((1 - (1 / Power(1 + IntRate, TermMonths - NoAdvPmts))) / IntRate) + NoAdvPmts)) - PV) * Power(1 + IntRate, TermMonths)), 1);

        if CalcPMTFromRV(QuoteNo, ResidualValue) <> Pmt then
            ResidualValue := Round(-(((Pmt * (((1 - (1 / Power(1 + IntRate, TermMonths - NoAdvPmts))) / IntRate) + NoAdvPmts)) - PV) * Power(1 + IntRate, TermMonths)), 0.1);
        if CalcPMTFromRV(QuoteNo, ResidualValue) <> Pmt then
            ResidualValue := Round(-(((Pmt * (((1 - (1 / Power(1 + IntRate, TermMonths - NoAdvPmts))) / IntRate) + NoAdvPmts)) - PV) * Power(1 + IntRate, TermMonths)), 0.01);

    end;

    local procedure CalcFactor(Pmt: Decimal; TermMonths: Integer; NoAdvPmts: Integer; IntRate: Decimal): Decimal
    begin
        exit(((1 - (1 / Power(1 + IntRate, TermMonths - NoAdvPmts))) / IntRate) + NoAdvPmts);
    end;

    local procedure CalcPMTFromRV(QuoteNo: Integer; ResidualValue: Decimal) PMTAmt: Decimal
    var
        AnualRate: Decimal;
        FV: Decimal;
        PV: Decimal;
        TermMonths: Integer;
        ScheduleCalcNA: Codeunit "NA Schedule Calc NA";
    begin
        case QuoteNo of
            1:
                begin
                    FV := ResidualValue;
                    //LoanValue := "Quote1 Total Cost" - "Quote1 Downpayment" - ResidualValue + "Quote1 Profit Figure" - ("Quote1 Trade-In Cost"-"Quote1 Refin. Pay-out Figure");
                    PV := "Quote1 Total Cost" - "Quote1 Downpayment" - ("Quote1 Trade-In Cost" - "Quote1 Refin. Pay-out Figure");
                    TermMonths := "Quote1 Term (Months)";
                    AnualRate := "Quote1 Interest %";
                end;
            2:
                begin
                    FV := ResidualValue;
                    //LoanValue := "Quote2 Total Cost" - "Quote2 Downpayment" - ResidualValue + "Quote2 Profit Figure" - ("Quote2 Trade-In Cost"-"Quote2 Refin. Pay-out Figure");
                    PV := "Quote2 Total Cost" - "Quote2 Downpayment" - ("Quote2 Trade-In Cost" - "Quote2 Refin. Pay-out Figure");
                    TermMonths := "Quote2 Term (Months)";
                    AnualRate := "Quote2 Interest %";
                end;
            3:
                begin
                    FV := ResidualValue;
                    //LoanValue := "Quote3 Total Cost" - "Quote3 Downpayment" - ResidualValue + "Quote3 Profit Figure" - ("Quote3 Trade-In Cost"-"Quote3 Refin. Pay-out Figure");
                    PV := "Quote3 Total Cost" - "Quote3 Downpayment" - ("Quote3 Trade-In Cost" - "Quote3 Refin. Pay-out Figure");
                    TermMonths := "Quote3 Term (Months)";
                    AnualRate := "Quote3 Interest %";
                end;
        end;

        PMTAmt := Round(-ScheduleCalcNA.PPmtDotNET(AnualRate / 12 / 100, 1, TermMonths, PV, -FV, false), 0.01);
        //PMTAmt := ROUND(PV * AnualRate/100/12,0.01) + ROUND(-ScheduleCalcNA.PPmtDotNET(AnualRate / 12 / 100,1,TermMonths,LoanValue,0,FALSE),0.01);
    end;

    local procedure CalcPMTFromNAF(QuoteNo: Integer; PV: Decimal) PMTAmt: Decimal
    var
        AnualRate: Decimal;
        FV: Decimal;
        TermMonths: Integer;
        ScheduleCalcNA: Codeunit "NA Schedule Calc NA";
    begin
        case QuoteNo of
            1:
                begin
                    FV := "Quote1 Residual Value";
                    TermMonths := "Quote1 Term (Months)";
                    AnualRate := "Quote1 Interest %";
                end;
            2:
                begin
                    FV := "Quote2 Residual Value";
                    TermMonths := "Quote2 Term (Months)";
                    AnualRate := "Quote2 Interest %";
                end;
            3:
                begin
                    FV := "Quote3 Residual Value";
                    TermMonths := "Quote3 Term (Months)";
                    AnualRate := "Quote3 Interest %";
                end;
        end;

        PMTAmt := Round(-ScheduleCalcNA.PPmtDotNET(AnualRate / 12 / 100, 1, TermMonths, PV, -FV, false), 0.01);
        //PMTAmt := ROUND(PV * AnualRate/100/12,0.01) + ROUND(-ScheduleCalcNA.PPmtDotNET(AnualRate / 12 / 100,1,TermMonths,LoanValue,0,FALSE),0.01);
    end;

    local procedure FillFromQuoteToAppl()
    var
        OldQuickQuote: Record "Quick Quote Worksheet";
    begin
        /*TG190916*/
        Contract.Get("Contract No.");
        case Contract.Status of
            Contract.Status::Quote:
                Type := Type::Quote;
            Contract.Status::Application:
                Type := Type::Application;
        end;

        if (Type = Type::Application) and (Contract."Quote No." <> '') and OldQuickQuote.Get(Contract."Quote No.") then
            case true of
                OldQuickQuote."Quote1 Accepted":
                    begin
                        "Quote1 Bonus" := OldQuickQuote."Quote1 Bonus";
                        "Quote1 Color of Vehicle" := OldQuickQuote."Quote1 Color of Vehicle";
                        "Quote1 Commission" := OldQuickQuote."Quote1 Commission";
                        "Quote1 Customer Residual" := OldQuickQuote."Quote1 Customer Residual";
                        "Quote1 Downpayment" := OldQuickQuote."Quote1 Downpayment";
                        "Quote1 Interest %" := OldQuickQuote."Quote1 Interest %";
                        "Quote1 Interior Color" := OldQuickQuote."Quote1 Interior Color";
                        "Quote1 Manufacturer" := OldQuickQuote."Quote1 Manufacturer";
                        "Quote1 Model" := OldQuickQuote."Quote1 Model";
                        "Quote1 Model Year" := OldQuickQuote."Quote1 Model Year";
                        "Quote1 Monthly Depreciation" := OldQuickQuote."Quote1 Monthly Depreciation";
                        "Quote1 Monthly Depreciation %" := OldQuickQuote."Quote1 Monthly Depreciation %";
                        "Quote1 Monthly Interest" := OldQuickQuote."Quote1 Monthly Interest";
                        "Quote1 Monthly Overhead" := OldQuickQuote."Quote1 Monthly Overhead";
                        "Quote1 Monthly Pmt. Excl. Tax" := OldQuickQuote."Quote1 Monthly Pmt. Excl. Tax";
                        "Quote1 Monthly Pmt. Incl. Tax" := OldQuickQuote."Quote1 Monthly Pmt. Incl. Tax";
                        "Quote1 Profit Figure" := OldQuickQuote."Quote1 Profit Figure";
                        "Quote1 Program Code" := OldQuickQuote."Quote1 Program Code";
                        "Quote1 Purchase Price" := OldQuickQuote."Quote1 Purchase Price";
                        "Quote1 Refin. Pay-out Figure" := OldQuickQuote."Quote1 Refin. Pay-out Figure";
                        "Quote1 Residual Value" := OldQuickQuote."Quote1 Residual Value";
                        "Quote1 Tax Rate" := OldQuickQuote."Quote1 Tax Rate";
                        "Quote1 Tax Amount" := OldQuickQuote."Quote1 Tax Amount";
                        "Quote1 Term" := OldQuickQuote."Quote1 Term";
                        "Quote1 Term (Months)" := OldQuickQuote."Quote1 Term (Months)";
                        "Quote1 Total Addons" := OldQuickQuote."Quote1 Total Addons";
                        "Quote1 Total Cost" := OldQuickQuote."Quote1 Total Cost";
                        "Quote1 Trade-In Cost" := OldQuickQuote."Quote1 Trade-In Cost";
                        "Quote1 Vehicle Notes" := OldQuickQuote."Quote1 Vehicle Notes";
                        OnFillQuoteFromApp(OldQuickQuote, rec);
                    end;
                OldQuickQuote."Quote2 Accepted":
                    begin
                        "Quote1 Bonus" := OldQuickQuote."Quote2 Bonus";
                        "Quote1 Color of Vehicle" := OldQuickQuote."Quote2 Color of Vehicle";
                        "Quote1 Commission" := OldQuickQuote."Quote2 Commission";
                        "Quote1 Customer Residual" := OldQuickQuote."Quote2 Customer Residual";
                        "Quote1 Downpayment" := OldQuickQuote."Quote2 Downpayment";
                        "Quote1 Interest %" := OldQuickQuote."Quote2 Interest %";
                        "Quote1 Interior Color" := OldQuickQuote."Quote2 Interior Color";
                        "Quote1 Manufacturer" := OldQuickQuote."Quote2 Manufacturer";
                        "Quote1 Model" := OldQuickQuote."Quote2 Model";
                        "Quote1 Model Year" := OldQuickQuote."Quote2 Model Year";
                        "Quote1 Monthly Depreciation" := OldQuickQuote."Quote2 Monthly Depreciation";
                        "Quote1 Monthly Depreciation %" := OldQuickQuote."Quote2 Monthly Depreciation %";
                        "Quote1 Monthly Interest" := OldQuickQuote."Quote2 Monthly Interest";
                        "Quote1 Monthly Overhead" := OldQuickQuote."Quote2 Monthly Overhead";
                        "Quote1 Monthly Pmt. Excl. Tax" := OldQuickQuote."Quote2 Monthly Pmt. Excl. Tax";
                        "Quote1 Monthly Pmt. Incl. Tax" := OldQuickQuote."Quote2 Monthly Pmt. Incl. Tax";
                        "Quote1 Profit Figure" := OldQuickQuote."Quote2 Profit Figure";
                        "Quote1 Program Code" := OldQuickQuote."Quote2 Program Code";
                        "Quote1 Purchase Price" := OldQuickQuote."Quote2 Purchase Price";
                        "Quote1 Refin. Pay-out Figure" := OldQuickQuote."Quote2 Refin. Pay-out Figure";
                        "Quote1 Residual Value" := OldQuickQuote."Quote2 Residual Value";
                        "Quote1 Tax Rate" := OldQuickQuote."Quote2 Tax Rate";
                        "Quote1 Tax Amount" := OldQuickQuote."Quote2 Tax Amount";
                        "Quote1 Term" := OldQuickQuote."Quote2 Term";
                        "Quote1 Term (Months)" := OldQuickQuote."Quote2 Term (Months)";
                        "Quote1 Total Addons" := OldQuickQuote."Quote2 Total Addons";
                        "Quote1 Total Cost" := OldQuickQuote."Quote2 Total Cost";
                        "Quote1 Trade-In Cost" := OldQuickQuote."Quote2 Trade-In Cost";
                        "Quote1 Vehicle Notes" := OldQuickQuote."Quote2 Vehicle Notes";
                        OnFillQuoteFromApp(OldQuickQuote, rec);
                    end;
                OldQuickQuote."Quote3 Accepted":
                    begin
                        "Quote1 Bonus" := OldQuickQuote."Quote3 Bonus";
                        "Quote1 Color of Vehicle" := OldQuickQuote."Quote3 Color of Vehicle";
                        "Quote1 Commission" := OldQuickQuote."Quote3 Commission";
                        "Quote1 Customer Residual" := OldQuickQuote."Quote3 Customer Residual";
                        "Quote1 Downpayment" := OldQuickQuote."Quote3 Downpayment";
                        "Quote1 Interest %" := OldQuickQuote."Quote3 Interest %";
                        "Quote1 Interior Color" := OldQuickQuote."Quote3 Interior Color";
                        "Quote1 Manufacturer" := OldQuickQuote."Quote3 Manufacturer";
                        "Quote1 Model" := OldQuickQuote."Quote3 Model";
                        "Quote1 Model Year" := OldQuickQuote."Quote3 Model Year";
                        "Quote1 Monthly Depreciation" := OldQuickQuote."Quote3 Monthly Depreciation";
                        "Quote1 Monthly Depreciation %" := OldQuickQuote."Quote3 Monthly Depreciation %";
                        "Quote1 Monthly Interest" := OldQuickQuote."Quote3 Monthly Interest";
                        "Quote1 Monthly Overhead" := OldQuickQuote."Quote3 Monthly Overhead";
                        "Quote1 Monthly Pmt. Excl. Tax" := OldQuickQuote."Quote3 Monthly Pmt. Excl. Tax";
                        "Quote1 Monthly Pmt. Incl. Tax" := OldQuickQuote."Quote3 Monthly Pmt. Incl. Tax";
                        "Quote1 Profit Figure" := OldQuickQuote."Quote3 Profit Figure";
                        "Quote1 Program Code" := OldQuickQuote."Quote3 Program Code";
                        "Quote1 Purchase Price" := OldQuickQuote."Quote3 Purchase Price";
                        "Quote1 Refin. Pay-out Figure" := OldQuickQuote."Quote3 Refin. Pay-out Figure";
                        "Quote1 Residual Value" := OldQuickQuote."Quote3 Residual Value";
                        "Quote1 Tax Rate" := OldQuickQuote."Quote3 Tax Rate";
                        "Quote1 Tax Amount" := OldQuickQuote."Quote3 Tax Amount";
                        "Quote1 Term" := OldQuickQuote."Quote3 Term";
                        "Quote1 Term (Months)" := OldQuickQuote."Quote3 Term (Months)";
                        "Quote1 Total Addons" := OldQuickQuote."Quote3 Total Addons";
                        "Quote1 Total Cost" := OldQuickQuote."Quote3 Total Cost";
                        "Quote1 Trade-In Cost" := OldQuickQuote."Quote3 Trade-In Cost";
                        "Quote1 Vehicle Notes" := OldQuickQuote."Quote3 Vehicle Notes";
                        OnFillQuoteFromApp(OldQuickQuote, rec);
                    end;
            end;

    end;

    local procedure LoadStepdownArray(QuoteNo: Integer)
    var
        i: Integer;
        Year: Integer;
        Residual: Decimal;
        TermMonths: Integer;
        InterestPct: Decimal;
    begin
        /*TG190729*/ // Copy of function in Codeunit Schedule Calc NA with some changes
        Clear(StepdownArray);
        Clear(StepdownAvgArray);
        Clear(DeprAmt);
        case QuoteNo of
            1:
                begin
                    TermMonths := "Quote1 Term (Months)";
                    Residual := "Quote1 Total Cost" - "Quote1 Downpayment" - "Quote1 Trade-In Cost";
                    DeprAmt := ("Quote1 Total Cost" - "Quote1 Downpayment" - "Quote1 Residual Value" - "Quote1 Trade-In Cost") / TermMonths;
                    InterestPct := "Quote1 Interest %";
                end;
            2:
                begin
                    TermMonths := "Quote2 Term (Months)";
                    Residual := "Quote2 Total Cost" - "Quote2 Downpayment" - "Quote2 Trade-In Cost";
                    DeprAmt := ("Quote2 Total Cost" - "Quote2 Downpayment" - "Quote2 Residual Value" - "Quote2 Trade-In Cost") / TermMonths;
                    InterestPct := "Quote2 Interest %";
                end;
            3:
                begin
                    TermMonths := "Quote3 Term (Months)";
                    Residual := "Quote3 Total Cost" - "Quote3 Downpayment" - "Quote3 Trade-In Cost";
                    DeprAmt := ("Quote3 Total Cost" - "Quote3 Downpayment" - "Quote3 Residual Value" - "Quote3 Trade-In Cost") / TermMonths;
                    InterestPct := "Quote3 Interest %";
                end;
        end;

        if TermMonths = 0 then
            exit;

        for i := 1 to TermMonths do begin
            StepdownArray[i] := Residual * InterestPct / 100 / 12;
            Residual += -DeprAmt;
        end;

        Clear(Year);
        for Year := 1 to (TermMonths / 12) do begin
            StepdownAvgArray[Year] := GetStepdownAvg(Year);
        end;

    end;

    local procedure GetStepdownAvg(Year: Integer) IntForYear: Decimal
    var
        i: Integer;
        InstalNo: Integer;
    begin
        /*TG190729*/ // Copy of function in Codeunit Schedule Calc NA with some changes
        InstalNo := Year * 12;
        for i := 1 to 12 do begin
            IntForYear += StepdownArray[InstalNo];
            InstalNo := InstalNo - 1;
        end;

        IntForYear := IntForYear / 12;

    end;

    local procedure OnValidateAssetNo(QuoteNo: Integer)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        /*TG200506*/
        case QuoteNo of
            1:
                if FixedAsset.Get("Quote1 Asset No.") then begin
                    "Quote1 Model Year" := FixedAsset."PYA Model YEAR";
                    "Quote1 Manufacturer" := FixedAsset."PYA Asset Brand";
                    "Quote1 Model" := FixedAsset."PYA Asset Model";
                    "Quote1 Color of Vehicle" := FixedAsset."PYA Color Of Vehicle";

                    "Quote1 Interior Color" := FixedAsset."PYA Interior Color";
                end;
            2:
                if FixedAsset.Get("Quote2 Asset No.") then begin
                    "Quote2 Model Year" := FixedAsset."PYA Model Year";
                    "Quote2 Manufacturer" := FixedAsset."PYA Asset Brand";
                    "Quote2 Model" := FixedAsset."PYA Asset Model";
                    "Quote2 Color of Vehicle" := FixedAsset."PYA Color Of Vehicle";
                    "Quote2 Interior Color" := FixedAsset."PYA Interior Color";
                end;
            3:
                if FixedAsset.Get("Quote3 Asset No.") then begin
                    "Quote3 Model Year" := FixedAsset."PYA Model Year";
                    ;
                    "Quote3 Manufacturer" := FixedAsset."PYA Asset Brand";
                    "Quote3 Model" := FixedAsset."PYA Asset Model";
                    "Quote3 Color of Vehicle" := FixedAsset."PYA Color Of Vehicle";
                    "Quote3 Interior Color" := FixedAsset."PYA Interior Color";
                end;
        end;

    end;

    local procedure GetRates(pcode: Code[20]; VAR ProgramRates: Record "S4LA Program Rate")
    begin
        IF pcode = '' THEN
            EXIT;
        //------------- Find best matching rates record
        ProgramRates.RESET;
        ProgramRates.SETCURRENTKEY("Program Code", "Standard Rate"); // sorting per Standard Rate is important - findfirst gives lowest rate from all applicable
        ProgramRates.SETRANGE("Program Code", pcode);
        ProgramRates.SETFILTER("Fin. Product", '%1|%2', '', Contract."Financial Product");
        ProgramRates.SETFILTER("Asset Group", '%1|%2', '', Contract."Overall Asset Group");
        ProgramRates.SETFILTER("Min NAF", '%1|..%2', 0, Contract."PYA Net Capital Amount");
        ProgramRates.SETFILTER("Max NAF", '%1|%2..', 0, Contract."PYA Net Capital Amount");
        ProgramRates.SETFILTER("Min Term (mths)", '%1|..%2', 0, schedule."term (months)");
        ProgramRates.SETFILTER("Valid From", '%1|..%2', 0D, Contract."Contract Date");
        ProgramRates.SETFILTER("Valid Until", '%1|%2..', 0D, Contract."Quote Valid Until");
        IF NOT ProgramRates.FINDFIRST THEN
            ProgramRates.INIT;
    end;

    //BA210510 for interest rate modified
    local procedure CheckIntPct(QuoteNo: Integer)
    var
        "--TG190730--": Integer;
        Funder: Record "S4LA Funder";
        VariableInterestRates: Record "S4LA Variable Interest Rate";
        FundedRate: Decimal;
        MinInterestPct: Decimal;
        ProgramRates: Record "S4LA Program Rate";
        ProgramRec: Record "S4LA Program";
        ProgramCode: Code[20];
        InterestPct: Decimal;
        Cont: Record Contact;
        Text50011: Label 'Interest percent must not be below minimum rate';
        Text50012: Label 'Interest percent must not be above maximum rate';
        VarIntValueDate: Date;
    begin
        /*TG190802*/
        case QuoteNo of
            1:
                begin
                    ProgramCode := "Quote1 Program Code";
                    InterestPct := "Quote1 Interest %";
                end;
            2:
                begin
                    ProgramCode := "Quote2 Program Code";
                    InterestPct := "Quote2 Interest %";
                end;
            3:
                begin
                    ProgramCode := "Quote3 Program Code";
                    InterestPct := "Quote3 Interest %";
                end;
        end;

        if ProgramCode <> '' then begin
            if not ProgramRec.Get(ProgramCode) then
                exit;
            GetRates(ProgramRates, QuoteNo);
        end;

        Clear(FundedRate);
        Contract.Get("Contract No.");
        if (Contract."Customer No." <> '') and (Cont.Get(Contract."Customer No.")) then begin
            // if Cont."PYA Use Funded Rate" and ((Contract.Funder <> '') or (Cont."PYA Default Funder" <> '')) then begin
            if Contract.Funder <> '' then
                Funder.Get(Contract.Funder)
            else
                //       Funder.Get(Cont."PYA Default Funder");
                FundedRate := VariableInterestRates.GetRateForDate(Funder.Code, WorkDate, VarIntValueDate);
            if FundedRate <> 0 then
                MinInterestPct := FundedRate
            else
                MinInterestPct := programRates."Min Rate"; //BA210604  ProgramRates."Base Rate";
        end else
            MinInterestPct := programRates."Min Rate"; //BA210604;
                                                       //end else
        MinInterestPct := programRates."Min Rate"; //BA210604;

        if InterestPct < MinInterestPct then
            Error(Text50011);

        if (InterestPct > ProgramRates."Max Rate") and (ProgramRates."Max Rate" <> 0) then
            Error(Text50012);

    end;

    procedure CreateQuickQuote() DocumentEntryNo: Integer
    var
        Contract: Record "S4LA Contract";
        Document: Record "S4LA Document";
        Document2: Record "S4LA Document";
        DocumentSetup: Record "S4LA Document Selection";
    begin
        if not Contract.Get(Rec."Contract No.") then
            exit;

        if Contract.Status <> Contract.Status::Quote then
            Contract.FIELDERROR(Status);

        DocumentSetup.SETRANGE("Financial Product", Contract."Financial Product");
        //!! setfilter for language code
        if DocumentSetup.FindFirst then
            //DocumentSetup.TESTFIELD("PYA Quick Quote Xls Temp (EN)")
            //else begin
            DocumentSetup.SETRANGE("Financial Product", '');
        DocumentSetup.SETRANGE("Language Code", '');
        DocumentSetup.FINDFIRST;
        //  DocumentSetup.TESTFIELD("PYA Quick Quote Xls Temp (EN)");
        //end;

        Document.RESET;
        Document.SETRANGE("Key Code 1", Contract."Contract No.");
        //Document.SETRANGE("Document Type Code", DocumentSetup."PYA Quick Quote Xls Type");
        //Document.SETRANGE("Template Code", DocumentSetup."PYA Quick Quote Xls Temp (EN)");
        Document.SetFilter("Attachment No.", '<>%1', 0);
        if Document.FINDFIRST then
            Document.CreateOpenDocument
        else begin
            Document.INIT;
            Document2.RESET;
            if Document2.FINDLAST then
                Document."Entry No." := Document2."Entry No." + 1
            else
                Document."Entry No." := 1;
            Document."Table ID" := DATABASE::"S4LA Contract";
            Document.VALIDATE("Key Code 1", Contract."Contract No.");
            Document.VALIDATE(Document."Document Type Code", DocumentSetup."PYA Quick Quote Xls Type");
            Document.VALIDATE("Template Code", DocumentSetup."PYA Quick Quote Xls Temp (EN)");
            Document.INSERT(true);
            COMMIT; //TG191003 - prevent locking of table when opening doc
            Document.CreateOpenDocument;
            //Document.MODIFY;
            Document.DELETE;//DV190308
        end;
        exit(Document."Entry No.");//
    end;

    // BA210324
    [IntegrationEvent(false, false)]
    local procedure OnValidateTotalCost(var QuickQuoteWkSht: Record "Quick Quote Worksheet"; fieldNum: Integer; var FinProd: Record "S4LA Financial Product")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure onAfterFillFromQuote(var QuickQuoteWkSht: Record "Quick Quote Worksheet")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnClearQuote(var QuickQuoteWkSht: Record "Quick Quote Worksheet"; fieldNum: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFillQuoteFromApp(var QuickQuoteWkSht: Record "Quick Quote Worksheet"; var RecQuickQuoteWkSht: Record "Quick Quote Worksheet")
    begin
    end;
}