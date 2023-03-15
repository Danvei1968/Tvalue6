page 17022094 "Warning Log UI"
{
    Caption = 'Warning Log';
    Editable = false;
    PageType = List;
    ShowFilter = false;
    SourceTable = "PYA Warning Log UI";

    layout
    {
        area(content)
        {
            repeater(Control1000000000)
            {
                ShowCaption = false;
                field("Severity Colour"; "Severity Colour")
                {
                    ApplicationArea = S4Leasing;
                }
                field("Warning Text"; "Warning Text")
                {
                    ApplicationArea = S4Leasing;

                    trigger OnAssistEdit()
                    begin
                        Message("Warning Text");
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        //KS150928
        SeverityColor.Get(Severity);
        SeverityColor.CalcFields(Colour);
        "Severity Colour" := SeverityColor.Colour;
        //---
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    var
        SeverityColor: Record "PYA Warning Log Colour";
}
