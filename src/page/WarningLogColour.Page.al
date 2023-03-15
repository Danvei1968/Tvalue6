page 17022095 "Warning Log Colour"
{
    // EN180725 - Page type is changed from Card to List
    // SOLV-230 - image import
    ApplicationArea = S4Leasing;

    PageType = List;
    SourceTable = "PYA Warning Log Colour";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Severity; Severity)
                {
                    ApplicationArea = S4Leasing;
                }
                field(Colour; Colour)
                {
                    ApplicationArea = S4Leasing;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportImage)
            {
                Caption = 'Import Colour Image';
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                Image = ImportDatabase;
                ApplicationArea = S4Leasing;

                trigger OnAction()
                begin
                    rec.ImportPicture();
                    CurrPage.Update();
                end;
            }
        }
    }
}
