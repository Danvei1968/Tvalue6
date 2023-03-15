table 17022091 "PYA Warning Log Sys"
{
    // version S4L.WL,SL56,SFLV-89

    // //KS150928 code restructure
    // //Object renumbered from 17021603 to 17021299
    // EN180504 - Truncate error text, if too long
    // JL191112 - Entry no. field property set to autoincrement
    // SFLV-89 MG200429 - Added fields Status, "Status Update Date"
    // SFLV-89 MG200902 - Added fields "Object Name", "Server Instance Name", "Background Session"
    //                   "Object ID" caption removed,
    //                   logic for background tasks
    // SOLV-16 EN201210 - field "Object Name" calculation formula updated to retireve names from AllObjWithCaption table instead of Object

    Caption = 'Activities Log';
    //DrillDownPageID = "Activities Log";
    //LookupPageID = "Activities Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(9; "Transaction GUID"; Guid)
        {
            Caption = 'Batch GUID';
        }
        field(20; "Warning Text"; Text[250])
        {
            Caption = 'Warning Text';
        }
        field(24; Severity; Option)
        {
            OptionMembers = ,Info,Warning,Critical;
        }
        field(30; DateTime; DateTime)
        {
            Caption = 'DateTime';
        }
        field(31; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(40; "Server Instance Name"; Text[250])
        {
            Caption = 'Server Instance Name';
            DataClassification = ToBeClassified;
            Description = 'TIS-226';
        }
        field(50; "Background Session"; Boolean)
        {
            DataClassification = ToBeClassified;
            Description = 'TIS-226';
        }
        field(101; "Object Type"; Option)
        {
            OptionMembers = " ","Table",Form,"Report",,"Codeunit","XMLPort",MenuSuite,"Page";
        }
        field(102; "Object ID"; Integer)
        {
            Description = 'TIS-226';
        }
        field(103; "Object Name"; Text[60])
        {
            //SOLF-16 EN201210 >>
            CalcFormula = Lookup(AllObjWithCaption."Object Name" WHERE("Object Type" = field("Object Type"),
                                                    "Object ID" = FIELD("Object ID")));
            //SOLF-16 EN201210 <<
            FieldClass = FlowField;
        }
        field(104; "Table ID"; Integer)
        {
        }
        field(105; "Record ID"; RecordID)
        {
        }
        field(108; "Record Position"; Text[250])
        {

            trigger OnLookup()
            var
                Contr: Record "S4LA Contract";
                Sched: Record "S4LA Schedule";
                SchedLine: Record "S4LA Schedule Line";
                SalesHeader: Record "Sales Header";
                SalesLine: Record "Sales Line";
            begin
                case "Table ID" of

                    DATABASE::"S4LA Contract":
                        begin
                            Contr.SetPosition("Record Position");
                            Contr.OpenCardPage();
                        end;

                    DATABASE::"S4LA Schedule":
                        begin
                            Sched.SetPosition("Record Position");
                            Contr.Get(Sched."Contract No.");
                            Contr.OpenCardPage();
                        end;

                    DATABASE::"S4LA Schedule Line":
                        begin
                            SchedLine.SetPosition("Record Position");
                            Contr.Get(SchedLine."Contract No.");
                            Contr.OpenCardPage();
                        end;

                    DATABASE::"Sales Header":
                        begin
                            SalesHeader.SetPosition("Record Position");
                            PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
                        end;

                    DATABASE::"Sales Line":
                        begin
                            SalesLine.SetPosition("Record Position");
                            SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                            PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
                        end;

                end;
            end;
        }
        field(120; "Contract No."; Code[20])
        {
            TableRelation = "S4LA Contract";
        }
        field(68000; Status; Option)
        {
            DataClassification = ToBeClassified;
            Description = 'SFLV-89';
            Editable = false;
            OptionCaption = 'Unread,Read';
            OptionMembers = Unread,Read;

            trigger OnValidate();
            begin
                "Status Update Date" := CurrentDateTime;
            end;
        }
        field(68010; "Status Update Date"; DateTime)
        {
            DataClassification = ToBeClassified;
            Description = 'SFLV-89';
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

    var
        WarningLogSys: Record "PYA Warning Log Sys";
        TransactionGUID: Guid;


    procedure Add(aObjectType: Option " ","Table",Form,"Report",,"Codeunit","XMLPort",MenuSuite,"Page"; aObjectID: Integer; aWarningText: Text; var aRecVariant: Variant; aSeverity: Option ,Info,Warning,Critical)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ActiveSession: Record "Active Session";
    begin
        //KS150928
        // Insert message into warning log.
        // NOTE: TransactionGUID is global, used to identify set of warnings. Use CLEAR(WarningLogSys) once, before first call to AddWarnings

        if IsNullGuid(TransactionGUID) then
            TransactionGUID := CreateGuid;

        WarningLogSys.Init;
        WarningLogSys."Entry No." := 0;
        //>>EN180504
        //WarningLogSys."Warning Text" := aWarningText;
        WarningLogSys."Warning Text" := CopyStr(aWarningText, 1, MaxStrLen(WarningLogSys."Warning Text"));
        //<<EN180504
        WarningLogSys.Severity := aSeverity;
        WarningLogSys."Transaction GUID" := TransactionGUID;
        WarningLogSys.DateTime := CurrentDateTime;
        WarningLogSys."User ID" := UserId;

        //SFLV-89>>
        if ActiveSession.Get(ServiceInstanceId, SessionId) then begin
            WarningLogSys."Server Instance Name" := ActiveSession."Server Instance Name";
            if ActiveSession."Client Type" = ActiveSession."Client Type"::Background then begin
                WarningLogSys."User ID" := CopyStr(WarningLogSys."User ID" + ' (BG)', 1, MaxStrLen(WarningLogSys."User ID"));
                WarningLogSys."Background Session" := true;
            end;
        end;
        //SFLV-89 <<

        WarningLogSys."Object Type" := aObjectType;
        WarningLogSys."Object ID" := aObjectID;
        //SFLV-89 >>
        if WarningLogSys.Severity = WarningLogSys.Severity::Info then begin
            WarningLogSys.Status := WarningLogSys.Status::Read;
            WarningLogSys."Status Update Date" := WarningLogSys.DateTime;
        end;
        //SFLV-89 <<
        if aRecVariant.IsRecord then begin
            RecRef.GetTable(aRecVariant);
            WarningLogSys."Table ID" := RecRef.Number;
            WarningLogSys."Record ID" := RecRef.RecordId;
            WarningLogSys."Record Position" := RecRef.GetPosition(true);
            //KS151202 solve for Contract No. Used to filter log entries on pages.
            case WarningLogSys."Table ID" of
                DATABASE::"S4LA Contract":
                    WarningLogSys."Contract No." := RecRef.Field(1).Value;
                DATABASE::"S4LA Schedule":
                    WarningLogSys."Contract No." := RecRef.Field(1).Value;
                DATABASE::"S4LA Schedule Line":
                    WarningLogSys."Contract No." := RecRef.Field(1).Value;
                DATABASE::"S4LA Early Payout":
                    WarningLogSys."Contract No." := RecRef.Field(10).Value;
                DATABASE::"S4LA Asset":
                    WarningLogSys."Contract No." := RecRef.Field(1).Value;
                DATABASE::"S4LA Applicant":
                    WarningLogSys."Contract No." := RecRef.Field(1).Value;
            end;
            //---
        end;
        WarningLogSys.Insert(true);
    end;


    procedure WarningCount(): Integer
    begin
        //Returns count of warnings received within transaction (typically, used in user message, like '5000 instalments invoices, 0 warning messages')
        WarningLogSys.Reset;
        WarningLogSys.SetCurrentKey("Transaction GUID");
        WarningLogSys.SetRange("Transaction GUID", TransactionGUID);
        WarningLogSys.SetRange(Severity, WarningLogSys.Severity::Warning, WarningLogSys.Severity::Critical);
        exit(WarningLogSys.Count);
    end;
}
