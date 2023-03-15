page 17022189 "Quick Quote Wksht Dialogue"
{
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            field(ValueToFix; ValueToFix)
            {
                ApplicationArea = S4Leasing;
                Caption = 'Value To Fix';
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.LookupMode(true);
    end;

    var
        ValueToFix: Option " ","Asset Price",Downpayment,"Residual Value";

    [Scope('OnPrem')]
    procedure GetValuetoFix(var pValuetoFix: Option " ","Asset Price",Downpayment,"Residual Value","Trade-in Value")
    begin
        pValuetoFix := ValueToFix;
    end;
}

