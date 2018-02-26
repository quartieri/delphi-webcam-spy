unit ufrmTelaPrincipal;

interface

uses
  math, comobj, shellapi, Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, clipbrd,ExtCtrls, AviCaptura, MMSystem,
  IdTCPConnection, IdTCPClient, IdHTTP,
  Spin, JLCVideo, inifiles, mainthread, ComCtrls, jpeg,mailerthread, ftpthread,
  Menus, JvBackgrounds, JvExControls, JvGradient, JvComponentBase, JvBalloonHint,
  JvTrayIcon,ThreadEmail;

const
   WM_NOTIFYICON  = WM_USER+333;

type
  TfrmTelaPrincipal = class(TForm)
    Panel1: TPanel;
    JLCVideo1: TJLCVideo;
    pnlMainImage: TPanel;
    imgPrevious: TImage;
    imgCurrent: TImage;
    pnlControls: TPanel;
    lblInformation: TLabel;
    Label1: TLabel;
    ProgressBar1: TProgressBar;
    Label2: TLabel;
    TrackBar1: TTrackBar;
    lblActualMovement: TLabel;
    lblMovementTrigger: TLabel;
    pnlDetectionZone: TPanel;
    pnlZoneImage: TPanel;
    imgZone: TImage;
    MainMenu1: TMainMenu;
    Opes1: TMenuItem;
    Selecionarcamera1: TMenuItem;
    Ajuda1: TMenuItem;
    Sobreoprograma1: TMenuItem;
    Sobreoautor1: TMenuItem;
    ConfiguraesdeEmail1: TMenuItem;
    ConfiguraodeEmail1: TMenuItem;
    JvGradient1: TJvGradient;
    JvBalloonHint1: TJvBalloonHint;
    JvTrayIcon1: TJvTrayIcon;
    chkbxEnviarEmail: TCheckBox;
    SpeedButton1: TSpeedButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure FormShow(Sender: TObject);
    procedure drawZoneBox;
    procedure ControlMouseDown(Sender: TObject;
                             Button: TMouseButton;
                             Shift: TShiftState;
                             X, Y: Integer);
    procedure ControlMouseMove(Sender: TObject;
                             Shift: TShiftState;
                             X, Y: Integer);
    procedure ControlMouseUp(Sender: TObject;
                           Button: TMouseButton; 
                           Shift: TShiftState; 
                           X, Y: Integer);
    procedure FormActivate(Sender: TObject);
    procedure Selecionarcamera1Click(Sender: TObject);
    procedure reacrtica1Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);

  private
    { Private declarations }
    inReposition,alwaysOnTop,capturingBaseImage,wantThreadPaused,threadIsPaused,waitingForBaseImage,useWindowsLock: boolean;
    frameDiffsForTriggerCount, actualFramesThatWereDifferent: integer;
    oldPos: TPoint;
    MailerThread: TMailer;
    FTPThread: TFTPUploader;
    gotBothImages, wasIconic: boolean;
    lockOnMovement, cancelLockIfNoMovement, saveJpegOnMovement, minimizeToTray, shutdownOnMovement: boolean;
    source, launchOnMovement, workingDirectory, playSoundOnMovement,saveDirectory: string;
    mainThread: TMainThread;
    normalFrameinterval, moveTrigger, pixelTolerance, lockTime, gracePeriod, cancelPeriod, imageCount: integer;
    gracePeriodStart: DWORD;
    function calculateDifference: integer;
    procedure getImageFromWebcam;
    procedure getImageFromHttpServer;
    function getFrame: integer;
    procedure updateLockCountdown;
    procedure doLockStuff(movementDetected, gracePeriodPassed: boolean);
    procedure doSaveJpegStuff;
    procedure doPlaySoundStuff;
    function LPad(s: String; nLength: integer): string ;
    procedure flashTaskBar;
    function loadBaseImageFromDisk: boolean;
  public
    { Public declarations }
    TrayIcon: TNotifyIconData;
    HMainIcon: HICON;
    procedure ClickTrayIcon(var msg: TMessage); message WM_NOTIFYICON;
    procedure MinimizeClick(Sender:TObject);
    function doMainIteration: boolean;
  end;

  TSoundPlayer = class(TThread)
  private
    playSoundOnMovement: string;
  protected
    procedure Execute; override;
  public
    constructor create(_playSoundOnMovement: string);
    destructor destroy; override;
  end;



const
   confFile = 'WebCamVigia.ini';
   baseImageFileName = 'baseimage.bmp';
   COMPARE_PREVIOUS_FRAME = 0;
   COMPARE_BASE_IMAGE = 1;

var
  frmTelaPrincipal: TfrmTelaPrincipal;
  playingSound, initialized: boolean;
  compareMode: integer;
  nomeDaImagem : string;
  mail : TThreadEnviaEmail;

implementation


{$R *.dfm}

procedure TfrmTelaPrincipal.FormActivate(Sender: TObject);
begin
if initialized then exit;

with TIniFile.Create(ExtractFilePath(Application.ExeName) + '\' + confFile) do
   begin
   try
      self.Top    := ReadInteger('main','self.Top', 100);
      self.Left   := ReadInteger('main','self.Left', 100);
   //   self.Height := ReadInteger('main','self.Height',500);
    //  self.Width  := ReadInteger('main','self.Width',700);

      if ReadString('main','useZone','false') = 'true' then
         begin
         pnlDetectionZone.visible := false;
         pnlDetectionZone.Top     := ReadInteger('main','pnlDetectionZone.Top', 87);
         pnlDetectionZone.Left    := ReadInteger('main','pnlDetectionZone.Left', 82);
         pnlDetectionZone.Height  := ReadInteger('main','pnlDetectionZone.Height',130);//130
         pnlDetectionZone.Width   := ReadInteger('main','pnlDetectionZone.Width',167); //167
         end;

      finally
      free;
      end;
   end;

initialized := true;
Application.ProcessMessages;
end;

procedure TfrmTelaPrincipal.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
Resize := (NewWidth > pnlControls.width) and (NewHeight >= 400);
end;

procedure TfrmTelaPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
   if mainThread <> nil then
   begin
      mainThread.terminate;
      {while mainThread.isThreadRunning do
      begin
         sleep(1000);
         application.processmessages;
      end;}
   end;
   if MailerThread <> nil then MailerThread.terminate;
   if FTPthread <> nil then FTPthread.terminate;

   if FileExists(baseImageFileName) then
   begin
      if MessageDlg('Leave base image file on disk so it can be used next time?', mtConfirmation, [mbYes, mbNo], 0) = mrNo then
         DeleteFile(baseImageFileName);
   end;

   with TIniFile.Create(ExtractFilePath(Application.ExeName) + '\' + confFile) do
   begin
      WriteInteger('main', 'moveTrigger', Trackbar1.position);
      WriteInteger('main', 'compareMode', 0);//rgCompareAgainst.ItemIndex
      if pnlDetectionZone.visible then
      begin
         WriteString('main','useZone','true');
         WriteInteger('main','pnlDetectionZone.Top',pnlDetectionZone.Top);
         WriteInteger('main','pnlDetectionZone.Left',pnlDetectionZone.Left);
         WriteInteger('main','pnlDetectionZone.Height',pnlDetectionZone.Height);
         WriteInteger('main','pnlDetectionZone.Width',pnlDetectionZone.Width);
      end
      else
         WriteString('main','useZone','false');

      WriteInteger('main','self.Top', self.Top);
      WriteInteger('main','self.Left', self.Left);
    //  WriteInteger('main','self.Height', self.Height);
    //  WriteInteger('main','self.Width', self.Width);

      free;
   end;
end;

procedure TfrmTelaPrincipal.FormCreate(Sender: TObject);
var
i,val: integer;
SRec: TSearchRec;
sendviaemail, sendviaftp: boolean;
IniFile: TIniFile ;
ftpPassword: string;
begin
initialized         := false;
capturingBaseImage  := false;
waitingForBaseImage := false;
wantThreadPaused    := false;
threadIsPaused      := false;
actualFramesThatWereDifferent := 0;
// Permite que a zona de seleção seja redimencionavel em runtime
with pnlDetectionZone do
   begin
   OnMouseDown := ControlMouseDown;
   OnMouseMove := ControlMouseMove;
   OnMouseUp   := ControlMouseUp;
   Left        := (pnlMainImage.width div 2) - (pnlDetectionZone.Width div 2);
   top         := (pnlMainImage.height div 2) - (pnlDetectionZone.height div 2);
   end;
//
playingSound                           := false;
imgCurrent.picture.bitmap.PixelFormat  := pf24bit;
imgPrevious.picture.bitmap.PixelFormat := pf24bit;
imgZone.picture.bitmap.PixelFormat     := pf24bit;
gotBothImages                          := false;
lockTime                               := -1;
pnlZoneImage.parent                    := pnlDetectionZone;
// get highest image count of files in directory
imageCount := 0;
i          := FindFirst(ExtractFilePath(Application.ExeName) + '\image_*.jpg', faAnyFile, SRec);
try
   while i = 0 do
    	begin
      val := strtoint(copy(SRec.Name, 7, 6));
      if val > imagecount then imagecount := val;
      	i := FindNext(SRec);

      Application.ProcessMessages;   
     	end;

   finally
	FindClose(SRec);
   end ;

IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + '\' + confFile);

try
   with IniFile do
      begin
      source      := ReadString('main', 'source', 'webcam');
      compareMode := ReadInteger('main','compareMode',COMPARE_PREVIOUS_FRAME);
      
      if compareMode = COMPARE_BASE_IMAGE then
         begin
         if not loadBaseImageFromDisk then
            compareMode := COMPARE_PREVIOUS_FRAME;
         end;

    //  rgCompareAgainst.ItemIndex := compareMode;
      normalFrameinterval        := ReadInteger('main', 'normalFrameinterval', 1000);
      moveTrigger                := ReadInteger('main', 'moveTrigger', 20);
      pixelTolerance             := ReadInteger('main', 'pixelTolerance', 20);
      gracePeriod                := ReadInteger('main', 'gracePeriod', 3) * 1000;
      cancelPeriod               := ReadInteger('main', 'cancelPeriod', 5);
      lockOnMovement             := ReadString('main', 'lockOnMovement', 'false') = 'true';
      cancelLockIfNoMovement     := ReadString('main', 'cancelLockIfNoMovement', 'false') = 'true';
      saveJpegOnMovement         := ReadString('main', 'saveJpegOnMovement', 'false') = 'true';
      saveDirectory              := ReadString('main', 'saveDirectory', '');

      if (length(saveDirectory) > 0) and (saveDirectory[length(saveDirectory)] <> '\') then
         begin
         saveDirectory := saveDirectory + '\';
         end;

      launchOnMovement    := ReadString('main', 'launchOnMovement', '');
      workingDirectory    := ReadString('main', 'workingDirectory', '');
      playSoundOnMovement := ReadString('main', 'playSoundOnMovement', '');
      sendviaemail        := ReadString('main', 'sendViaEmail', 'false') = 'true';
      sendviaftp          := ReadString('main', 'sendViaFtp', 'false') = 'true';
      minimizeToTray      := ReadString('main', 'minimizeToTray', 'false') = 'true';
      alwaysOnTop         := ReadString('main', 'alwaysOnTop', 'false') = 'true';
      shutdownOnMovement  := ReadString('main', 'shutdownOnMovement', 'false') = 'true';
      frameDiffsForTriggerCount := ReadInteger('main', 'frameDiffsForTriggerCount', 1);
      useWindowsLock            := ReadString('main', 'useWindowsLock', 'true') = 'true';
      trackbar1.Position  := moveTrigger;

      // if we need to email the images, start the background thread
      if sendviaemail then
         begin
         MailerThread := TMailer.create(IniFile, imagecount, saveDirectory);
         MailerThread.FreeOnTerminate := True ;
         MailerThread.resume;
         end;

      end;
   finally
   IniFile.Free;
   end;

// set up "minimize to tray" stuff
if minimizeToTray then
   begin
   HMainIcon:=LoadIcon(MainInstance, 'MAINICON');
   Shell_NotifyIcon(NIM_DELETE, @TrayIcon);
   with trayIcon do
      begin
      cbSize              := sizeof(TNotifyIconData);
      Wnd                 := handle;
      uID                 := 123;
      uFlags              := NIF_MESSAGE or NIF_ICON or NIF_TIP;
      uCallbackMessage    := WM_NOTIFYICON;
      hIcon               := HMainIcon;
      szTip               := 'Move Action';
      end;

   Application.OnMinimize:= MinimizeClick;
   Application.ProcessMessages;
   end;

//  sbCameraSource.visible := (source = 'webcam');
if source = 'webcam' then
   JLCVideo1.Activo := true;

mainThread := TMainThread.create(self, JLCVideo1);
mainThread.FreeOnTerminate := true;
mainThread.resume;
end;


procedure TfrmTelaPrincipal.FormDestroy(Sender: TObject);
begin
   if minimizeToTray then
      Shell_NotifyIcon(NIM_Delete, @TrayIcon);
end;

procedure TfrmTelaPrincipal.FormResize(Sender: TObject);
var
   imageSize, imageLeft, imageTop: integer;
begin
   inReposition := true;
   try
      // centre the controls panel
      pnlControls.Left := (self.width div 2) - (pnlControls.Width div 2);

      // resize & centre the images
      // TImage has some properties to do this automatically
      // but they result in a lot of screen flickering
      imageSize := min(pnlMainImage.Width, pnlMainImage.Height)-4;
      imgCurrent.Width := imageSize;
      imgCurrent.Height := imageSize;
      imgPrevious.Width := imageSize;
      imgPrevious.Height := imageSize;

      imageTop := (pnlMainImage.Height div 2) - (imageSize div 2);
      imgCurrent.Top := imageTop;
      imgPrevious.Top := imageTop;

      imageLeft := (pnlMainImage.Width div 2) - (imageSize div 2);
      imgCurrent.left := imageLeft;
      imgPrevious.left := imageLeft;

      drawZoneBox;
      Application.ProcessMessages;

   finally
      inReposition := false;
   end;
end;

procedure TfrmTelaPrincipal.FormShow(Sender: TObject);
begin
if alwaysOnTop then
   begin
   SetWindowPos(frmTelaPrincipal.Handle,HWND_TOPMOST,0, 0, 0, 0,SWP_NOMOVE or SWP_NOSIZE or SWP_SHOWWINDOW);
   end;

FormResize(self);
Application.ProcessMessages;
end;

{captures a frame and returns the difference between this and the
frame to compare with.
return value:
0=no difference, i.e. every single pixel is identical
100=total difference, i.e. every single pixel is different
-1 = could not capture frame for some reason}
function TfrmTelaPrincipal.getFrame: integer;
begin
Application.ProcessMessages;
getImageFromWebcam;

if imgCurrent.picture.bitmap.PixelFormat <> pf24bit then
   begin
      mainThread.terminate;
      sleep(3000);
     // lblInformation.caption := 'Bitmap format not 24 bit!';
      lblInformation.visible := true;
      application.processmessages;
      result := -1;
      exit;
   end;

   if gotBothImages then
   begin
      // get difference between frames
      result := calculateDifference;
      progressbar1.Position := result;
      lblActualMovement.Caption := inttostr(result);
      end
   else
   begin
      // first iteration
      result := 0;
      gracePeriodStart := GetTickCount;
   end;

    // copy image to previous image
   if (compareMode = COMPARE_PREVIOUS_FRAME) or (capturingBaseImage) then
   begin
    
      imgPrevious.Picture := imgCurrent.Picture;
      gotBothImages := true;


   end;

   // are we waiting for the user to click the button capture a base image?
   if waitingForBaseImage then
   begin
     // lblInformation.caption := 'Please click button to capture base image...';
      lblInformation.visible := true;
      application.processmessages;
      result := -1;
      exit;
   end;
Application.ProcessMessages;   
end;


procedure TfrmTelaPrincipal.getImageFromWebcam;
begin
JLCvideo1.GrabarImagenDisco;

if fileexists(JLCVideo1.FicheroImagen) then
   begin
   
   imgCurrent.picture.LoadFromFile(JLCVideo1.FicheroImagen);

   if pnlDetectionZone.Visible then
      begin
      imgZone.Picture.bitmap.FreeImage;
      imgZone.Picture.bitmap.Assign(imgCurrent.picture.bitmap);
      imgZone.repaint;
      end;

   deleteFile(pchar(JLCVideo1.FicheroImagen));
   end;
Application.ProcessMessages;   
end;


procedure TfrmTelaPrincipal.getImageFromHttpServer;
begin
//
end;


function TfrmTelaPrincipal.doMainIteration: boolean;
var
differenceBetweenFrames: integer;
framesDifferent, triggerMovementDetection, gracePeriodPassed: boolean;
begin
   while wantThreadPaused do
   begin
      threadIsPaused := true;
      sleep(500);
      application.processmessages;
   end;
   threadIsPaused := false;

   result := false;
   if (inReposition) or (not initialized) then exit;
   try
      // get next frame & see if any differences
      differenceBetweenFrames := getFrame;
      if differenceBetweenFrames = -1 then exit;
      if differenceBetweenFrames >= moveTrigger then
      begin
         framesDifferent := true;
         inc(actualFramesThatWereDifferent);
         triggerMovementDetection := (actualFramesThatWereDifferent >= frameDiffsForTriggerCount);
      end
      else
      begin
         framesDifferent := false;
         actualFramesThatWereDifferent := 0; // reset
         triggerMovementDetection := false;
         if lockOnMovement then
         begin
         //   if (cancelLockIfNoMovement) and (lockTime <> -1) then btnCancelLockClick(self); // cancels lock countdown
           // if (not useWindowsLock) then unlockSystem; // ensures system is unlocked if using custom lock
         end;
      end;

      // determine whether this is the "grace period" (i.e. time allowed on startup and after a lock has occurred)
      gracePeriodPassed := (GetTickCount - gracePeriodStart > gracePeriod);

      // update display
      if framesDifferent then
      begin
         if triggerMovementDetection then
         begin
            if gracePeriodPassed then
            begin
               if (lockOnMovement) or (saveJpegOnMovement) or (length(launchOnMovement) > 0) or (length(playSoundOnMovement) > 0) or (shutdownOnMovement) then
                  lblInformation.Caption := ''//'Movement'
               else
                  begin
                  lblInformation.Caption := '>>> Movimento detectado <<<';
                  doSaveJpegStuff;
                  mail := TThreadEnviaEmail.create('leoquartieri@gmail.com',nomeDaImagem);
                  mail.Resume;

                  end;
            end
            else
               lblInformation.Caption := '';//'Movement (grace period)';
         end
         else if actualFramesThatWereDifferent > 0 then
           // lblInformation.Caption := 'Movement (only ' + IntTostr(actualFramesThatWereDifferent) + ' ' + fixPlurals('frame',actualFramesThatWereDifferent) + ' different)';
      end;

      lblInformation.Visible := framesDifferent;

      // now do all the actions
      if lockOnMovement then doLockStuff(triggerMovementDetection, gracePeriodPassed);

      if (triggerMovementDetection) and (gracePeriodPassed) then
      begin
      //
      saveJpegOnMovement := false;


         if saveJpegOnMovement then
            begin
            doSaveJpegStuff;
            saveJpegOnMovement := false;
            end;


      end;

      result := framesDifferent;
   except
      on E:Exception do
      begin
       //  lblInformation.caption := 'Error: ' + E.Message;
         lblInformation.Visible := true;
      end;
   end;

   application.processmessages;
end;


procedure TfrmTelaPrincipal.doLockStuff(movementDetected, gracePeriodPassed: boolean);
begin

end;

procedure TfrmTelaPrincipal.doSaveJpegStuff;
var
JpegImg: TJpegImage;
tmpFilename, actualFilename: string;
f: file;
begin
inc(imageCount);

JpegImg := TJpegImage.Create;
try
   JpegImg.Assign(imgCurrent.picture.bitmap) ;
   tmpFilename := saveDirectory + 'Foto_'+ lpad(inttostr(imageCount), 6) + '.jpg_';
   actualFilename := copy(tmpFilename, 1, length(tmpFilename)-1);
   lblInformation.caption := 'Salvando ' + actualFilename;
   lblInformation.Visible := true;
   JpegImg.SaveToFile(tmpFilename);

   nomeDaImagem := ExtractFilePath(Application.ExeName)+'/'+ actualFilename;

   finally
   JpegImg.Free;
   end;

// Se a imagem já existir, deleta antes...
if fileExists(actualFilename) then
   deletefile(actualFilename);

AssignFile(f, tmpFilename);
rename(f, actualFilename);
end;

procedure TfrmTelaPrincipal.Selecionarcamera1Click(Sender: TObject);
begin
JLCVideo1.SeleccionarFuente;
end;

procedure TfrmTelaPrincipal.SpeedButton1Click(Sender: TObject);
begin
mail := TThreadEnviaEmail.create('leoquartieri@gmail.com',nomeDaImagem);
mail.Resume;
end;

procedure TfrmTelaPrincipal.TrackBar1Change(Sender: TObject);
begin
moveTrigger := Trackbar1.Position;
lblMovementTrigger.caption := inttostr(moveTrigger);
end;

function TfrmTelaPrincipal.calculateDifference: integer;
const
   showZone = false; // debugging, shows the zone being monitored in red
   badZoneMsg = 'Invalid detection zone, please reposition';
type
  TRGBArray = ARRAY[0..32767] OF TRGBTriple; // pf24bit
  pRGBArray = ^TRGBArray;
var
   x,y,changedPixels: integer;
   currentLine, prevLine: pRGBArray;
   currentPixel, prevPixel: TRGBTriple;
   startY, endY, startX, endX, pixelsCompared: integer;
begin
Application.ProcessMessages;

if pnlDetectionZone.visible then
   begin
   y := ((pnlDetectionZone.Top * 100) div imgCurrent.Height);
   startY := (imgCurrent.picture.Height * y) div 100;

   if startY < 0 then Raise Exception.Create(badZoneMsg);

   y := (((pnlDetectionZone.Top + pnlDetectionZone.Height) * 100) div imgCurrent.Height);
   endY := ((imgCurrent.picture.Height * y) div 100)-1;

   if endY > imgCurrent.picture.Height - 1 then Raise Exception.Create(badZoneMsg);

   x := (((pnlDetectionZone.Left - imgCurrent.left) * 100) div imgCurrent.Width);
   startX := (imgCurrent.picture.width * x) div 100;

   if startX < 0 then Raise Exception.Create(badZoneMsg);

   x := (((pnlDetectionZone.Left + pnlDetectionZone.Width - imgCurrent.left) * 100) div imgCurrent.Width);
   endX := ((imgCurrent.picture.width * x) div 100)-1;
   if endX > imgCurrent.picture.Width - 1 then Raise Exception.Create(badZoneMsg);


   pixelsCompared := (endX-startX+1) * (endY-startY+1)
   end
else
   begin
   startY := 0;
   endY := imgCurrent.picture.Height - 1;
   startX := 0;
   endX := imgCurrent.picture.Width - 1;
   pixelsCompared := (imgCurrent.picture.Height * imgCurrent.picture.Width)
   end;


changedPixels := 0;

for y := startY to endY do
   begin
   currentLine := imgCurrent.picture.bitmap.Scanline[y];
   prevLine := imgPrevious.picture.bitmap.Scanline[y];
   Application.ProcessMessages;
      for x := startX to endX do
      begin
         currentPixel := currentLine^[x];
         prevPixel := prevLine^[x];
         Application.ProcessMessages;
         if (abs(currentPixel.rgbtRed - prevPixel.rgbtRed) > pixelTolerance) and
         (abs(currentPixel.rgbtGreen - prevPixel.rgbtGreen) > pixelTolerance) and
         ((abs(currentPixel.rgbtBlue - prevPixel.rgbtBlue) > pixelTolerance)) then
            inc(changedPixels);

         if (showZone) and ((y = startY) or (y = endY) or (x = startX) or (x = endX)) then
         begin
            currentLine^[x].rgbtRed := 255;
            currentLine^[x].rgbtGreen := 0;
            currentLine^[x].rgbtBlue := 0;
         end;
         
      end;
   end;
   result := (changedPixels * 100) div pixelsCompared;
   if showZone then imgCurrent.Repaint;
Application.ProcessMessages;
end;

{left-pads a string}
function TfrmTelaPrincipal.LPad(s: String; nLength: integer): string ;
begin
   while length(s) < nLength do
      s := '0' + s ;
   result := s ;
end ;


procedure TfrmTelaPrincipal.updateLockCountdown;
begin
Application.processmessages;
end;


procedure TfrmTelaPrincipal.MinimizeClick(Sender:TObject);
begin
   Shell_NotifyIcon(NIM_Add, @TrayIcon);
   hide;
   {hide the taskbar button}
   if IsWindowVisible(Application.Handle)
   then ShowWindow(Application.Handle, SW_HIDE);
end;


function TfrmTelaPrincipal.loadBaseImageFromDisk: boolean;
begin
   result := false;
   try
      if FileExists(baseImageFileName) then
      begin
         imgPrevious.Picture.LoadFromFile(baseImageFileName);
         if (imgPrevious.picture.bitmap.height = 0) or (imgPrevious.picture.bitmap.width = 0) then
         begin
            deleteFile(baseImageFileName);
           // ShowMessageTimedClose('Previous base image is corrupted!',caption,10);
            exit;
         end;
         gotBothImages := true;
         result := true;
      end;
   except
      // do nothing
   end;

end;

procedure TfrmTelaPrincipal.reacrtica1Click(Sender: TObject);
begin
pnlDetectionZone.visible := true;

if pnlDetectionZone.Visible then
   begin
   drawZoneBox;
   end;

JvBalloonHint1.DefaultIcon := ikInformation;
JvBalloonHint1.ActivateHint(pnlDetectionZone,'O retangulo amarelo definirá a área a ser vigiada.'+#13+' Pressione SHIFT para alterar o tamanho da área','Atenção',5000);
Application.ProcessMessages;
end;

procedure TfrmTelaPrincipal.ClickTrayIcon(var msg: TMessage);
begin

end;

procedure TfrmTelaPrincipal.flashTaskBar;
var
   FWinfo: TFlashWInfo;
begin
   if minimizeToTray then exit;

   FWinfo.cbSize := 20;
   FWinfo.hwnd := Application.Handle; // Handle of Window to flash
   FWinfo.dwflags := FLASHW_ALL;
   FWinfo.ucount := 1; // number of times to flash
   FWinfo.dwtimeout := 0; // speed in ms, 0 default blink cursor rate
   FlashWindowEx(FWinfo); // make it flash!
end;

procedure TfrmTelaPrincipal.ControlMouseDown(
Sender: TObject;
Button: TMouseButton;
Shift: TShiftState;
X, Y: Integer);
begin
if Sender is TWinControl then
   begin
   inReposition    :=True;
   imgZone.Visible := false;
   Application.ProcessMessages;
   SetCapture(TWinControl(Sender).Handle);
   GetCursorPos(oldPos);
   Application.ProcessMessages;
   end;
   
end; (*ControlMouseDown*)

procedure TfrmTelaPrincipal.ControlMouseMove(
  Sender: TObject;
  Shift: TShiftState;
  X, Y: Integer);
const
minWidth = 20;
minHeight = 20;
var
newPos: TPoint;
frmPoint : TPoint;
begin
Application.ProcessMessages;
if inReposition then
   begin
   with TWinControl(Sender) do
      begin

      GetCursorPos(newPos);


      if ssShift in Shift then
         begin //resize

         Screen.Cursor := crSizeNWSE;
         frmPoint := ScreenToClient(Mouse.CursorPos);
         if frmPoint.X > minWidth then
            Width := frmPoint.X;
         if frmPoint.Y > minHeight then
            Height := frmPoint.Y;

         end
      else //move
         begin

         Screen.Cursor := crSize;
         Left := Left - oldPos.X + newPos.X;
         Top := Top - oldPos.Y + newPos.Y;
         oldPos := newPos;

         end;
      end;
   end;
Application.ProcessMessages;
end; (*ControlMouseMove*)

procedure TfrmTelaPrincipal.ControlMouseUp(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
Application.ProcessMessages;
if inReposition then
   begin
   imgZone.Visible := true;
   Screen.Cursor := crDefault;
   ReleaseCapture;
   inReposition := False;
   drawZoneBox;
   end;
   
end; (*ControlMouseUp*)


procedure TfrmTelaPrincipal.drawZoneBox;
const
margin = 5;
begin

if not pnlDetectionZone.visible then exit;

// check zone panel is not larger than the main image
if pnlDetectionZone.Height > imgCurrent.Height then pnlDetectionZone.Height := imgCurrent.Height;
if pnlDetectionZone.Width > imgCurrent.Width then pnlDetectionZone.Width := imgCurrent.Width;


// ensure zone image cannot be dragged/positioned outsize main image
if pnlDetectionZone.Top < imgCurrent.top then
   pnlDetectionZone.Top := imgCurrent.top;

if pnlDetectionZone.Left < imgCurrent.left then
   pnlDetectionZone.Left := imgCurrent.left;

if pnlDetectionZone.Top + pnlDetectionZone.Height > imgCurrent.Height then
   pnlDetectionZone.Top := imgCurrent.Height - pnlDetectionZone.Height;

if pnlDetectionZone.Left + pnlDetectionZone.Width > (imgCurrent.left + imgCurrent.Width) then
   pnlDetectionZone.Left := (imgCurrent.left + imgCurrent.Width) - pnlDetectionZone.Width;

// ensure zone image is rendered inside the zone panel correctly
pnlZoneImage.height := pnlDetectionZone.height-(margin*2);
pnlZoneImage.width  := pnlDetectionZone.width-(margin*2);
pnlZoneImage.Top    := margin;
pnlZoneImage.Left   := margin;

imgZone.Width   := imgCurrent.Width;
imgZone.Height  := imgCurrent.height;
imgZone.Left    := imgCurrent.left - pnlDetectionZone.left-margin;
imgZone.Top     := imgCurrent.Top - pnlDetectionZone.top-margin;

Application.ProcessMessages;
end;


procedure TfrmTelaPrincipal.doPlaySoundStuff;
var
   soundPlayer: TSoundPlayer;
begin
   if playingSound then exit;
   playingSound := true;
   soundPlayer:= TSoundPlayer.create(playSoundOnMovement);
   soundPlayer.FreeOnTerminate := True ;
   soundPlayer.resume;
end;


constructor TSoundPlayer.create(_playSoundOnMovement: string);
begin
   inherited create(true); // create but don't start running yet
   playSoundOnMovement := _playSoundOnMovement;
end;


destructor TSoundPlayer.Destroy;
begin
   inherited destroy;
end;


procedure TSoundPlayer.Execute;
begin
   // play the sound and reset the flag
   // note - to play the sound asynchronously (call returns immediately) use this:
   // sndPlaySound(PChar(playSoundOnMovement), SND_NODEFAULT Or SND_ASYNC)
   sndPlaySound(PChar(playSoundOnMovement), SND_NODEFAULT);
   playingSound := false;
end;

end.
