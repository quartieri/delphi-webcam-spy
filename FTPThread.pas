{thread that runs in the background & FTPs any new JPG files it finds}
unit FTPthread;

interface

uses
  Classes, Windows, SysUtils, inifiles, idFTP,dialogs;

type
  TFTPUploader = class(TThread)
  private
   remoteDirectory, saveDirectory, uploadFileName: string;
   imageCount: integer;
   checkfileinterval: integer;
  protected
 //   NMFTP1: TNMFTP;
    procedure Execute; override;
    function LPad(s: String; nLength: integer): string ;
    procedure log(msg: string);
  public
    constructor create(IniFile: TIniFile; _imageCount: integer; _ftpPassword, _saveDirectory: string);
    destructor Destroy; override;
  end;

implementation




{constructor}
constructor TFTPUploader.create(IniFile: TIniFile; _imageCount: integer; _ftpPassword,_saveDirectory: string);
var
   host,user,password : string;
   port : integer;
   passive: boolean;
begin
   inherited create(true); // create but don't start running yet

   password:= _ftpPassword;
   imageCount := _imageCount+1;
   saveDirectory := _saveDirectory;
   with IniFile do
   begin
      checkfileinterval := ReadInteger('main', 'ftp.checkfileinterval', 500);
      host := ReadString('main', 'ftp.host', 'localhost');
      port := ReadInteger('main', 'ftp.port', 21);
      user := ReadString('main', 'ftp.user', 'anonymous');
      // password := ReadString('main', 'ftp.password', 'password@anonymous.com');
      passive := ReadBool('main', 'ftp.passive', false);
      remoteDirectory := ReadString('main', 'ftp.remoteDirectory', '/');
      uploadFileName := ReadString('main', 'ftp.uploadFileName', '');
   end;

//   NMFTP1 := TNMFTP.create(nil);
//   NMFTP1.Host := host;
//   NMFTP1.Port := port;
//   NMFTP1.UserID := user;
//   NMFTP1.Password := password;
//   NMFTP1.Passive := passive;
//   NMFTP1.TimeOut := 60000;
end;

{destructor}
destructor TFTPUploader.Destroy;
begin
   inherited destroy;
end;


{main thread entry point}
procedure TFTPUploader.Execute;
var
   filename: string;
begin
   filename := 'image_' + lpad(inttostr(imageCount), 6) + '.jpg';

   // this thread looks for the next image file number, and uploads it when found
   repeat

//	   while FileExists(saveDirectory + filename) do
//      begin
//         try
//            if not NMFTP1.Connected then
//            begin
//               NMFTP1.Connect;
//               NMFTP1.ChangeDir(remoteDirectory);
//               NMFTP1.Mode(MODE_IMAGE); // presume this means binary
//            end;

            // use actual filename (with sequence)
            // or fixed filename?
//            if length(uploadFileName) > 0 then
//               NMFTP1.Upload(saveDirectory + filename, uploadFileName)
//            else
//               NMFTP1.Upload(saveDirectory + filename, filename);
//
//            inc(imageCount);
//            filename := 'image_' + lpad(inttostr(imageCount), 6) + '.jpg';
//         except
//            on e:exception do
//            begin
//               log(e.Message);
//            end;
  //       end;
  //    end;

    //  if NMFTP1.Connected then NMFTP1.Disconnect;
      sleep(checkfileinterval);

   until terminated;

end;


{left-pads a string}
function TFTPUploader.LPad(s: String; nLength: integer): string ;
begin
     while length(s) < nLength do
           s := '0' + s ;
     result := s ;
end ;

procedure TFTPUploader.log(msg: string);
const
   logFileName = 'ftperrors.log';
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
