program WebCamVigia;

uses
  Forms,
  mainthread in 'mainthread.pas',
  JLCVideo in '..\common\jlcvideo\JLCVideo.pas',
  AviCaptura in '..\common\jlcvideo\AviCaptura.pas',
  ufrmTelaPrincipal in 'ufrmTelaPrincipal.pas' {frmTelaPrincipal},
  MailerThread in 'MailerThread.pas',
  FTPThread in 'FTPThread.pas',
  ThreadEmail in 'ThreadEmail.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'WebCam Vigia';
  Application.CreateForm(TfrmTelaPrincipal, frmTelaPrincipal);
  Application.Run;
end.
