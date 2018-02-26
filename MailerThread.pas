{thread that runs in the background & emails any new JPG files it finds}
unit MailerThread;

interface

uses
  Classes, Windows, SysUtils, inifiles, idsmtp,dialogs;

type
  TMailer = class(TThread)
  private
   imageCount: integer;
   emailuserid,emailto,emailfrom,emailsubject,emailbody,emailhost : string;
   emailport : integer;
   checkfileinterval: integer;
   saveDirectory: string;
  protected
    procedure Execute; override;
    procedure sendSMTPMessage(filename: string);
    function LPad(s: String; nLength: integer): string ;
    procedure log(msg: string);
  public
    constructor create(IniFile: TIniFile; _imageCount: integer; _saveDirectory: string);
    destructor destroy; override;
  end;

implementation




{constructor}
constructor TMailer.create(IniFile: TIniFile; _imageCount: integer; _saveDirectory: string);
begin
   inherited create(true); // create but don't start running yet

   imageCount := _imageCount+1;
   saveDirectory := _saveDirectory;
   with IniFile do
   begin
      checkfileinterval := ReadInteger('main', 'email.checkfileinterval', 500);
      emailuserid := ReadString('main', 'email.userid', '');
      emailto := ReadString('main', 'email.to', 'you@mycompany.com');
      emailfrom := ReadString('main', 'email.from', 'me@mycompany.com');
      emailsubject := ReadString('main', 'email.subject', 'Webcam image');
      emailbody := ReadString('main', 'email.body', 'Webcam image was detected');
      emailhost := ReadString('main', 'email.host', 'localhost');
      emailport := ReadInteger('main', 'email.port', 25);
   end;
end;

{destructor}
destructor TMailer.Destroy;
begin
   inherited destroy;
end;


{main thread entry point}
procedure TMailer.Execute;
var
   filename: string;
begin
   // this thread looks for the next image file number, and mails it when found
   repeat
      filename := 'image_' + lpad(inttostr(imageCount), 6) + '.jpg';
      if FileExists(saveDirectory + filename) then
      begin
         sendSMTPMessage(filename);
         inc(imageCount);
      end
      else
      begin
         sleep(checkfileinterval);
      end;
   until terminated;

end;

procedure TMailer.sendSMTPMessage(filename: string);
var
   smtp: TidSMTP;
   toAddress, body, attachments: TStringList;
begin
   // connect to the SMTP server, send a file and disconnect
   // it would probably be more efficient to only make a single connection and send a whole bunch
   // of files at once, but I'm not sure if some smtp servers will allow this, so I'm keeping it simple
//   try
//
//     // smtp := TNMSMTP.create(nil);
//      toAddress := TStringList.create;
//      body := TStringList.create;
//      attachments := TStringList.create;
//      try
//         with smtp do
//         begin
//            userid := emailuserid;
//            host := emailhost;
//            port := emailport;
//            timeout := 60000;
//            with PostMessage do
//            begin
//               body.add(emailbody);
//               subject := emailsubject + ' - ' + filename;
//               toAddress.add(emailto);
//               fromName := emailfrom;
//               fromAddress := emailfrom;
//               replyto := emailfrom;
//               attachments.add(saveDirectory + filename);
//            end;
//            connect;
//            sendMail;
//            disconnect;
//         end;
//      finally
//         attachments.free;
//         toAddress.free;
//         body.free;
//         smtp.free;
//      end;
//
//   except
//      on e:exception do
//      begin
//         log(e.Message);
//      end;
//   end;
end;

{left-pads a string}
function TMailer.LPad(s: String; nLength: integer): string ;
begin
   while length(s) < nLength do
      s := '0' + s ;
   result := s ;
end ;


procedure TMailer.log(msg: string);
const
   logFileName = 'smtperrors.log';
var
   logfile: text;
begin
   try
      assignfile(logfile, logfilename);
      if fileexists(logfilename) then
         append(logfile)
      else
         rewrite(logfile);

      writeln(logfile, DateTimeToStr(Now) + ' ' + msg);
      closefile(logfile);
   except
      on E:Exception do
      begin
         // now what?
      end;
   end;
end;

end.
