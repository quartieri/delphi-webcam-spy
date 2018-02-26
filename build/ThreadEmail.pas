unit ThreadEmail;

interface

uses
  Classes, Windows, SysUtils, inifiles, dialogs,IdComponent, IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdMessageClient, IdSMTPBase, IdSMTP,
  IdBaseComponent, IdMessage, StdCtrls, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdAntiFreezeBase, IdAntiFreeze;

type
  TThreadEnviaEmail = class(TThread)
  private
  emailDoDestinatario: string;
  nomeDaImagem : string;

  protected
  procedure Execute; override;
  procedure sendSMTPMessage(filename: string);


  public
  constructor create(emailDestinatario,nomeImagem:string);
  destructor destroy; override;

  end;

implementation




{constructor}
constructor TThreadEnviaEmail.create(emailDestinatario,nomeImagem:string);
begin
inherited create(true); // cria sem iniciar a thread

Priority            := tpHighest;
nomeDaImagem        := nomeImagem;
emailDoDestinatario := emailDestinatario;
end;

{destructor}
destructor TThreadEnviaEmail.Destroy;
begin
inherited destroy;
end;


{main thread entry point}
procedure TThreadEnviaEmail.Execute;
begin

if true then  //FileExists(nomeDaImagem)
   begin
   sendSMTPMessage(nomeDaImagem);
   end;

end;

procedure TThreadEnviaEmail.sendSMTPMessage(filename: string);
var
smtp: TidSMTP;
msg : TIdMessage;
IdSSLIOHandlerSocketOpenSSL1 : TIdSSLIOHandlerSocketOpenSSL;
toAddress, body, attachments: TStringList;
begin
try
   // Criação dos objetos
   smtp := TidSMTP.create(nil);

   IdSSLIOHandlerSocketOpenSSL1 := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
   IdSSLIOHandlerSocketOpenSSL1.SSLOptions.Method := sslvSSLv2;
   IdSSLIOHandlerSocketOpenSSL1.SSLOptions.Mode := sslmClient;

   msg := TIdMessage.Create(nil);
   //

   // Configurações
   with SMTP do
      begin
      AuthType  := satDefault;
      Host      := 'smtp.gmail.com';
      IOHandler := IdSSLIOHandlerSocketOpenSSL1;
      Password  := 'y4a5h9m9__3';
      Port      := 587;
      Username  := 'webcamvigia@gmail.com';
      UseTLS    := utUseRequireTLS;
      end;

   with MSG do
      begin
      Body.Add('Senhor(a) usuário(a),'#13+
               'O WebCam Vigia detectou movimento na sua área vigiada em '+formatdatetime('dd/mm/yyyy - hh:mm:ss',now)+'.'+#13+
               'Foto em anexo.'+#13+#13+
               'Continuarei em alerta - WebCam Vigia.'+#13#13#13+
               'Sugestão: Faça uma doação ($) ao desenvolvedor deste programa: leoquartieri@gmail.com'+#13+
               '');

      From.Address := 'webcamvigia@gmail.com'; //opcional
      From.Name := 'WebCam Vigia';
      Recipients.Add;
      Recipients.Items[0].Address := LowerCase(trim(emailDoDestinatario));
      Recipients.Items[0].Name := 'Senhor(a) usuário(a)'; //opcional
      Subject := 'WebCam Vigia Alerta!!! - '+formatdatetime('dd/mm/yyyy hh:mm:ss',now); //opcional
      end;
   //


   // Realiza envio
   if (not(smtp.Connected)) then
      SMTP.Connect();

   SMTP.Send(MSG);
   SMTP.Disconnect;
   //

   except
   on e:exception do
      begin
      //
      end;
   end;
end;


end.
