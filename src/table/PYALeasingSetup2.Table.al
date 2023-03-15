table 17022180 "Leasing Setup 2"
{
    // JM180404 - New fields for leasing documents
    // JM180418 - New fields for leasing documents
    // DV181112,16 - Add Quick Quote Template
    // DV190619 - Add Luxury Tax
    // DV190626 - update ENU captions
    // DV190628 - Remove Luxury tax


    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Mileage Limit (km/year)"; Decimal)
        {
            Caption = 'Mileage Limit (Miles/year)';
        }
        field(20; "Price per km over limit"; Decimal)
        {
            Caption = 'Price per miles over limit';
        }
        field(50020; "Help Phone No."; Text[30])
        {
            DataClassification = ToBeClassified;
            Description = 'JM180404';
            Caption = 'Help Phone No.';
        }
        field(50021; "Valid for nb Days"; Integer)
        {
            DataClassification = ToBeClassified;
            Description = 'JM180404';
            Caption = 'Valid for Number of Days';
        }
        field(50022; "Leasing Email Address"; Text[30])
        {
            DataClassification = ToBeClassified;
            Description = 'JM180404';
            Caption = 'Leasing Email Address';
        }
        field(50023; "Residual Fee"; Decimal)
        {
            Caption = 'Residual Fee';
            DataClassification = ToBeClassified;
            Description = 'JM180404';
        }
        field(50024; "Short Comp Desc Local"; Text[40])
        {
            DataClassification = ToBeClassified;
            Description = 'DV171206';
            Caption = 'Short Company Description (Local)';
        }
        field(50025; "Capital BV Filter"; Code[250])
        {
            Caption = 'Capital BV Filter';
            DataClassification = ToBeClassified;
            Description = 'JM170901';
            TableRelation = "G/L Account";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(50026; "Operating BV Filter"; Code[250])
        {
            Caption = 'Operating BV Filter';
            DataClassification = ToBeClassified;
            Description = 'JM170901';
            TableRelation = "G/L Account";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(50027; "Late Payment Interest Rate"; Decimal)
        {
            DataClassification = ToBeClassified;
            Description = 'JM180418';
            Caption = 'Late Payment Interest Rate';
        }
        field(50033; "Blended Rate Markup %"; Decimal)
        {
            DataClassification = ToBeClassified;
            Description = 'TG190930';
            Caption = 'Blended Rate Markup %';
        }
        field(50034; "Complete Maint. Service Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG191108';
        }
        field(50035; "Fleet Mgt Service Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "s4la Service".Code;
            Caption = 'Fleet Mgt. Service Code';
        }
        field(50048; "Fuel Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            Description = 'TG190605';
            TableRelation = "Dimension Value".Code WHERE("Dimension Code" = CONST('SERVICE_CODE'));
            Caption = 'Fuel Code';
        }
        field(50059; "PYA License & Titles Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "s4la Service".Code;
            Caption = 'License & Titles Code';
        }
        field(50061; "GPS Code"; Code[20])
        {
            DataClassification = ToBeClassified;
            TableRelation = "s4la Service".Code;
            Caption = 'GPS Code';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}