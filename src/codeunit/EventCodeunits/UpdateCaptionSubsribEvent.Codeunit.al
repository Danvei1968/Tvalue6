codeunit 17022120 "Update Caption Subsrib Event"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Caption Class", 'OnResolveCaptionClass', '', true, true)]

    local procedure OnResolveCaptionClass(CaptionArea: Text; CaptionExpr: Text; Language: Integer; var Caption: Text; var Resolved: Boolean)
    var

    begin

        if Language = 1033 then begin
            if (CaptionArea = '7') and (CaptionExpr = '1') then begin
                Caption := 'City';
                Resolved := true;
            end else
                if (CaptionArea = '7') and (CaptionExpr = '2') then begin
                    Caption := 'ZIP Code';
                    Resolved := true;
                end else
                    if (CaptionArea = '7') and (CaptionExpr = '3') then begin
                        Caption := 'Mileage Limit (miles/year)';
                        Resolved := true;
                    end
                    else
                        if (CaptionArea = '7') and (CaptionExpr = '4') then begin
                            Caption := 'Markup';
                            Resolved := true;
                        end

        end else
            if Language = 4105 then begin
                if (CaptionArea = '7') and (CaptionExpr = '1') then begin
                    Caption := 'City';
                    Resolved := true;
                end else
                    if (CaptionArea = '7') and (CaptionExpr = '2') then begin
                        Caption := 'Postal/ZIP Code';
                        Resolved := true;
                    end
                    else
                        if (CaptionArea = '7') and (CaptionExpr = '3') then begin
                            Caption := 'Mileage Limit (km/year)';
                            Resolved := true;
                        end
                        else
                            if (CaptionArea = '7') and (CaptionExpr = '4') then begin
                                Caption := 'PAD';
                                Resolved := true;
                            end

            end;

    end;

}