unit mainthread;

interface

uses
  shellapi, Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, clipbrd,ExtCtrls, AviCaptura, MMSystem,
  Spin, JLCVideo, inifiles;

type
  TMainThread = class(TThread)
  private
   isRunning: boolean;
   frmOwner: TForm;
  protected
    procedure Execute; override;
  public
    constructor create(_frmOwner: TForm; _JLCVideo1: TJLCVideo);
    destructor Destroy; override;
    function isThreadRunning: boolean;
  end;


implementation

uses
   ufrmTelaPrincipal;


{constructor}
constructor TMainThread.create(_frmOwner: TForm; _JLCVideo1: TJLCVideo);
begin
   inherited create(true); // create but don't start running yet
   frmOwner := _frmOwner;
   isRunning := true;
end;

{destructor}
destructor TMainThread.Destroy;
begin
   inherited destroy;
end;


{main thread entry point}
procedure TMainThread.Execute;
var
   mainForm: TfrmTelaPrincipal;
   normalFrameinterval, fastFrameinterval, fastFrameintervalPeriod, intervalToUse: integer;
   movementDetected: boolean;
   fastFrameIntervalExpires: DWORD;
begin
   fastFrameIntervalExpires := 0;
   mainForm := (frmOwner as TfrmTelaPrincipal);

   with TIniFile.Create(ExtractFilePath(Application.ExeName) + '\' + confFile) do
   begin
      normalFrameinterval := ReadInteger('main', 'normalFrameinterval', 1000);
      fastFrameinterval := ReadInteger('main', 'fastFrameinterval', 100);
      fastFrameintervalPeriod := ReadInteger('main', 'fastFrameintervalPeriod', 10) * 1000;
      free;
   end;

   repeat
      movementDetected := mainForm.doMainIteration;

      // if we detect movement, speed up the frame rate for a while
      if movementDetected then
      begin
         intervalToUse := fastFrameinterval;
         fastFrameIntervalExpires := GetTickCount + fastFrameintervalPeriod;
      end
      else if GetTickCount > fastFrameIntervalExpires then
      begin
         intervalToUse := normalFrameinterval;
      end;

      sleep(intervalToUse);

   until terminated;
   isRunning := false;
end;

function TMainThread.isThreadRunning: boolean;
begin
   result := isRunning;
end;

end.
