//MG201117 SOLV-16 page 17021959 "Warning Log Sys"
page 17022096 "Activities Log" //MG201117 SOLV-16
{
    // version S4L.WL,SFLV-89

    // SFLV-89 MG200429 - Added fields Status, "Status Update Date"
    // SFLV-89 MG200902 - Added field "Object Name", "Server Instance Name", "Background Session"
    // SOLV-16 EN201210 - Promoted action "Mark Batch Read/Unread"

    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "PYA Warning Log Sys";
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = S4Leasing;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; "Entry No.")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field(Severity; Severity)
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field("Warning Text"; "Warning Text")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field("Record Position"; "Record Position")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field("Server Instance Name"; "Server Instance Name")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                    Visible = false;
                }
                field("Background Session"; "Background Session")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                    Visible = false;
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field(DateTime; DateTime)
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field("Object Type"; "Object Type")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field("Object ID"; "Object ID")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field("Object Name"; "Object Name")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                }
                field(Status; Status)
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                    Visible = false;
                }
                field("Status Update Date"; "Status Update Date")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                    Visible = false;
                }
                field("Transaction GUID"; "Transaction GUID")
                {
                    ApplicationArea = S4Leasing;
                    StyleExpr = StyleVar;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Mark Batch Read/Unread")
            {
                ApplicationArea = S4Leasing;
                Image = ShowSelected;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;

                trigger OnAction();
                var
                    WarningLog: Record "PYA Warning Log Sys";
                begin
                    CurrPage.SetSelectionFilter(WarningLog);
                    if WarningLog.FindFirst then
                        repeat
                            case WarningLog.Status of
                                WarningLog.Status::Read:
                                    MarkUnread(WarningLog);
                                WarningLog.Status::Unread:
                                    MarkRead(WarningLog);
                            end;
                            WarningLog.Modify;
                        until WarningLog.Next = 0;

                    UpdateStyle;

                    CurrPage.Update;
                end;
            }
        }
    }

    trigger OnAfterGetRecord();
    begin
        UpdateStyle;
    end;

    var
        StyleVar: Text;

    local procedure UpdateStyle();
    begin
        case Status of
            Status::Unread:
                StyleVar := 'Strong';
            Status::Read:
                StyleVar := '';
        end;
    end;

    local procedure MarkRead(var WarningLog: Record "PYA Warning Log Sys");
    begin
        WarningLog.Validate(Status, WarningLog.Status::Read);
    end;

    local procedure MarkUnread(var WarningLog: Record "PYA Warning Log Sys");
    begin
        WarningLog.Validate(Status, WarningLog.Status::Unread);
    end;
}
