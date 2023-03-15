table 17022092 "PYA Warning Log UI"
{
    // JL191211 - Warning Log UI and Warning Log primary key property "AutoIncrement" set to yes.

    Caption = 'Warning Log';
    DrillDownPageID = "Warning Log UI";
    LookupPageID = "Warning Log UI";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
        }
        field(9; "Transaction GUID"; Guid)
        {
        }
        field(20; "Warning Text"; Text[250])
        {
            Width = 80;
        }
        field(24; Severity; Option)
        {
            OptionMembers = " ",Info,Warning,Critical;
        }
        field(25; "Severity Colour"; BLOB)
        {
            SubType = Bitmap;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Transaction GUID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        //JL191211>>

        //KS150928
        /*IF "Entry No."=0 THEN
          IF WarningLog.FINDLAST
            THEN "Entry No." := WarningLog."Entry No." + 1
            ELSE "Entry No." := 1;*/

        //<<JL191211

    end;

    var
        WarningLog: Record "PYA Warning Log UI";
        TransactionGUID: Guid;


    procedure Add(AddWarningText: Text; AddSeverity: Option InfoGreen,InfoBlue,Warning,Critical)
    begin
        //KS150928
        // Insert message into warning log.
        // NOTE: TransactionGUID is global, used to identify set of warnings. Use CLEAR(WarningLog) once, before first call to AddWarnings

        if IsNullGuid(TransactionGUID) then
            TransactionGUID := CreateGuid;

        WarningLog.Init;
        WarningLog."Entry No." := 0;
        WarningLog."Warning Text" := AddWarningText;
        WarningLog.Severity := AddSeverity;
        WarningLog."Transaction GUID" := TransactionGUID;
        WarningLog.Insert(true);
    end;


    procedure HandleWarnings()
    begin
        // Sample code how to handle warnings at the end of "Check...Rules" codeunit
        if HasWarnings then
            if GuiAllowed
              then
                ShowWarnings
            else
                MoveToSystemLog;

        if HasCriticalWarnings
          then
            Error('')
        else
            ClearWarningLog;
    end;


    procedure HasWarnings(): Boolean
    begin
        //Returns if have any warnings (typically, ShowWarnings will follow)
        WarningLog.Reset;
        WarningLog.SetCurrentKey("Transaction GUID");
        WarningLog.SetRange("Transaction GUID", TransactionGUID);
        exit(not WarningLog.IsEmpty);
    end;


    procedure ShowWarnings()
    begin
        //opens page to show list of warnings to user
        WarningLog.Reset;
        WarningLog.SetCurrentKey("Transaction GUID");
        WarningLog.SetRange("Transaction GUID", TransactionGUID);
        PAGE.RunModal(PAGE::"Warning Log UI", WarningLog);
    end;


    procedure HasCriticalWarnings(): Boolean
    begin
        //Returns if have critical warnings (typically, ERROR will follow)
        WarningLog.Reset;
        WarningLog.SetCurrentKey("Transaction GUID");
        WarningLog.SetRange("Transaction GUID", TransactionGUID);
        WarningLog.SetRange(Severity, WarningLog.Severity::Critical);
        exit(not WarningLog.IsEmpty);
    end;


    procedure MoveToSystemLog()
    var
        SystemLog: Record "PYA Warning Log Sys";
    begin
        //moves user interface warnings to "Warning Log - System", in case when GUIALLOWED=false
        WarningLog.Reset;
        WarningLog.SetCurrentKey("Transaction GUID");
        WarningLog.SetRange("Transaction GUID", TransactionGUID);
        SystemLog.LockTable; //JL191211
        if WarningLog.FindSet then
            repeat
                SystemLog.Init;
                SystemLog."Entry No." := 0; //JL191211
                SystemLog.DateTime := CurrentDateTime;
                SystemLog."Warning Text" := WarningLog."Warning Text";
                SystemLog."Transaction GUID" := WarningLog."Transaction GUID";
                SystemLog."User ID" := UserId;
                SystemLog.Severity := WarningLog.Severity;
                SystemLog.Insert(true);
            until WarningLog.Next = 0;
        Commit; //JL191211
    end;


    procedure ClearWarningLog()
    begin
        //Clears the log of current transaction
        WarningLog.Reset;
        WarningLog.SetCurrentKey("Transaction GUID");
        WarningLog.SetRange("Transaction GUID", TransactionGUID);
        WarningLog.DeleteAll;
    end;

    //S4L.LP >>
    procedure GetTransactionGUID(): Guid
    begin
        exit(TransactionGUID);
    end;
    //S4L.LP <<


    procedure SetTransactionGUID(pTransactionGUID: Guid)
    begin
        TransactionGUID := pTransactionGUID;
    end;
}
