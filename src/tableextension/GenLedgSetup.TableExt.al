tableextension 17022099 "S4LNA Gen. Ledg. Setup" extends "General Ledger Setup"
{
    fields
    {
        field(17022090; "NA Asset Dimension Code"; Code[20])
        {
            Caption = 'Asset Dimension Code';
            DataClassification = CustomerContent;
            Description = 'SM181010';
            TableRelation = Dimension;
        }
        /*BA210712 - Field Removed - Should work without specifying the global dimension no.
        field(17022091; "S4LNA Dim ID - Asset"; Integer)
        {
            Caption = 'Asset Dimension Code';
            DataClassification = ToBeClassified;
            Description = 'SM181010';
        }
        */
        field(17022092; "S4LNA Leas.Amt.Round.Precision"; Decimal)
        {
            Caption = 'Leas. Amt. Rounding Precision';
            DataClassification = CustomerContent;
            InitValue = 0.01;
            DecimalPlaces = 0 : 5;
        }
    }
}
