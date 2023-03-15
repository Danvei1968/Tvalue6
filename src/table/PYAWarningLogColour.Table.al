table 17022090 "PYA Warning Log Colour"
{
    // SOLV-230 - image import
    fields
    {
        field(10; Severity; Option)
        {
            OptionMembers = InfoGreen,InfoBlue,Warning,Critical;
        }
        field(20; Colour; BLOB)
        {
            SubType = Bitmap;
        }
    }

    keys
    {
        key(Key1; Severity)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
    procedure ImportPicture()
    var
        ImgInStream: InStream;
        BlobOutStream: OutStream;
        ImgFilename: Text;
    begin
        if UploadIntoStream('Colour picture import', '', 'All Files (*.*)|*.*', ImgFileName, ImgInStream) then begin
            Clear(Colour);
            Colour.CreateOutStream(BlobOutStream);
            CopyStream(BlobOutStream, ImgInStream);
            IF NOT Modify() then
                Insert();
        end;
    end;
}
