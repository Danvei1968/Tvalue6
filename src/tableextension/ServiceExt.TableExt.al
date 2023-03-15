tableextension 17022109 "S4LNA Service Ext" extends "S4LA Service"
{
    //   DV170612 - Add 180 field
    //   DV170927 - Make 180 field 50 char & add Treat As
    //   DV171207 - Add Type & remove 180 field
    //   DV180222 - Add type RDPRM
    //   JM180409 - Add types Protection, Assistance
    //   DV180430 - Add Type Dealer Prep
    //   TG191017 - remove Invoice-In Invoice Out from Treat As

    fields
    {
        field(17022090; "NA Payment Due"; Option)
        {
            Caption = 'Payment Due';
            Description = 'EN151113,FM1 - renamed from "Treat As", options renamed (same meaning)';
            OptionMembers = "With Upfront Fees","Included in Financed Amount","Included in Installment","Re-charge Actual Cost";
            DataClassification = CustomerContent;
        }

        field(17022091; "NA Tax Group"; Code[20])
        {
            TableRelation = "Tax Group";
            Caption = 'Tax Group';
            DataClassification = CustomerContent;
        }
        field(17022092; "NA Type"; Enum "NA Services Type")
        {
            Caption = 'Type';
            DataClassification = CustomerContent;
        }
        //BA210624
        modify("Admin Fee VAT Group")
        {
            Caption = 'Admin Fee Tax Group';
        }
        //PYAS-296
        field(17022095; "S4LNA Charge During"; Option)
        {
            Caption = 'Charge';
            OptionMembers = " ","During Initial Term","While Outstanding > 0";
            DataClassification = CustomerContent;
        }
        //PYAS-358
        field(17022096; "S4LNA Incl/Excl from Base Rent"; Option)
        {
            caption = 'Include/Exclude from Base Rent';
            OptionMembers = Include,Exclude;
        }
        //--//
    }
}
