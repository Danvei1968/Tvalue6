page 17022090 "PYA Posting Date"
{
    // DV171017 - Ask for posting Date

    DataCaptionExpression = '';
    DelayedInsert = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    ShowFilter = false;
    SourceTable = Integer;
    SourceTableView = SORTING(Number)
                      WHERE(Number = CONST(0));

    layout
    {
        area(content)
        {
            field(PostingDate; PostingDate)
            {
                ApplicationArea = S4Leasing;
                Caption = 'Posting Date';
            }
            //BA220609
            group(AssetType)
            {
                Visible = ShowRepos;
                ShowCaption = false;

                group(ShowAll)
                {
                    ShowCaption = false;
                    Visible = ShowAllTermStat;

                    field(AssetPostingType; AssetPostingType)
                    {
                        ApplicationArea = S4Leasing;
                        Caption = 'Asset Posting Type';
                    }
                }

                group(HideStat) ///To only show limited options for STEWART
                {
                    ShowCaption = false;
                    Visible = not ShowAllTermStat;

                    field(HideAssetPostingType; AssetPostingType)
                    {
                        ApplicationArea = S4Leasing;
                        Caption = 'Asset Posting Type';
                        OptionCaption = ' ,Repossession,"Pay Out"';
                    }
                }
            }
            //--//
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        IF PostingDate = 0D THEN
            PostingDate := WORKDATE;

        LeasingSetup.get;

        if LeasingSetup."Use Additional Term. Status" then
            ShowAllTermStat := true
        else
            ShowAllTermStat := false;
    end;

    var
        PostingDate: Date;
        ShowRepos: Boolean;
        LeasingSetup: record "S4LA Leasing Setup";

        ShowAllTermStat: Boolean;

        AssetPostingType: Option " ",Repossession,"Pay Out",Surrender,"Matured -Paid in Full","Early Pay Out – Paid in Full","Write off";

    procedure SetDt(PDate: Date): Date
    begin
        PostingDate := PDate;
    end;

    procedure GetDt(): Date
    begin
        EXIT(PostingDate);
    end;

    procedure SetAssetPType(Repos: boolean)
    begin
        ShowRepos := repos;
    end;

    procedure GetAssetPType(): Option
    begin
        exit(AssetPostingType);
    end;

}

