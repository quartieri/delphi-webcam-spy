{********************************************************************
TJLCVideo: componente para la visualización y captura de video.
Fecha de inicio: 03-Enero-1999
Fecha de finalizacion: 06-Enero-1999 (Version 1.0).

Realizado por Juan Luis Ceada Ramos
Diplomado en Informática de Sistemas por la Universidad de Huelva.
Futuro :) Ingeniero Superior en Informatica por la Universidad de Sevilla



                 --------------ooooOOOOOOOoooo----------------

      Esta unidad contiene un componte que se ditribuye como FreeWare, incluyendo
      el codigo fuente. Si usa el componente contenido en esta unidad para
      desarrollar una aplicación, deberá incluir una mención al programador de este
      componente (Juan Luis Ceada Ramos) en el cuadro de diálogo Acerca de, en la ayuda
      , manuales, o cualquier otro sitio visible. Además, cualquier cambio o mejora
      realizada, debe serme comunicada, mediante el envio de la unidad actualizada por
      e-mail.

      Limitación de garantia: no existen garantías de que el componente funcione en todas
      las circunstancias, úsalo por tu cuenta y riesgo. El autor no asumirá ninguna responsabilidad
      derivada del uso de este componente.

                 --------------ooooOOOOOOOoooo----------------

E-milio:
        i5939@fie.us.es
        jlceada@olemail.com

Web donde obtener nuevas versiones del componente
          www.clubdelphi.com


08-01-1999:  Version 1.1
             Se añaden ciertos eventos que pueden ser de utilidad.
             OnVideoStream, OnWaveStream, OnFrame, OnYield, OnError, OnStatus,
             OnControl. Se hacen visibles los eventos OnClick, OnDblClick, OnMouseDown,
             OnMouseMove, OnMouseUp,  OnResize
             Se añade la propiedad de solo lectura "Grabando"

02-04-1999:  Version 1.2
             Se corrigen ciertos bugs:
                - ahora las propiedades se inician correctamente. Antes, si se establecia
                  la propiedad HiloAparte a False (por ejemplo), al iniciar la
                  visualización, el valor de la propiedad se mantenia a TRUE. Ahora ya esta
                  solucionado, llamando a los procedimientos de asignación de
                  propiedades justo despues de enlazar la ventana con el drivers del dispositivo
                - la propiedad Grabando en determinadas situaciones siempre devuelve true. Ahora
                  devuelve siempre el valor correcto.
             Se añaden nuevas capacidades:
                - Se añade una nueva propiedad, OpcionesAudio, que permite cambiar el formato del audio
                  capturado (bits, frecuencia y canales de sonido)
             Otros:
                - Se unifica el código del componente. Ahora el mismo fuente sirve para D3 y D4.
                  Es de suponer que tambien funcionara en D2. Si alguien puede probarlo,
                  que me lo comunique.
                - Se eliminan algunas unidades de la clausula uses que no son necesarias.
12-04-1999: Version 1.3
            Se cambia el sitio desde donde se llama a las funciones InstalarCallBack y DesInstalarCallback.
            Ahora se llama a la primera al activar el modo preview, y a la segunda al desactivarlo. Esto debe
            hacerse así, ya que el componente cuando se crea aparece en modo preview, por lo que si manteniamos
            las llamadas a estas funciones en el procedimiento Conectar, es posible que se ejecute codigo en el
            tiempo que va desde la creación del componente hasta que se pasa a modo overlay.
            Bueno, y ademas, como estaba un pelin aburrio, he decidido cambiar el nombre del componente:
            a partir de ahora, se llama JLCVideo a secas. Tambien he cambiado el icono del componente. Ahora
            indica claramente que version esta instalada.

20-10-1999: Version 1.4
            Por fin, he tenido tiempo para mejorar el tema de la gestión de eventos. Ahora se hace todo
            en menos código, y más bonito.....En fin, uno que va mejorando, con la edad....
            En anteriores versiones, al estar basado su funcionamiento en el envio de mensajes, el
            componente no funcionaba (no generaba eventos) cuando estaba minimizado, puesto que Windows no
            "despacha" los eventos dirigidos a aplicaciones minimizadas (excepto determinados mensajes del sistema)
            Ahora el componente genera eventos aun cuando la aplicacion este mínimizada.

24-10-1999: ActiveX: se distribuye una versión del componente como ActiveX. En fase de pruebas.
            Si alguien lo prueba, que me comente los resultados.

Futuras modificaciones:

        Pretendo añadir nuevos metodos y propiedades, destinados a controlar dispositivos MCI.
        Es posible que desarrolle un nuevo componente, dedicado exclusivamente a esto. Agradeceria
        cualquier ayuda al respecto, ya que conseguir un dispositivo que soporte MCI (por ejemplo, un video)
        para las pruebas, se presenta como algo casi imposible.
*********************************************************************}

unit JLCVideo;

interface


uses
  Windows, Messages, SysUtils, Classes, Controls, ExtCtrls, Dialogs, MMSystem, AviCaptura;

{  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, MMSystem, AviCaptura;}


type

  {Tipos de datos usados en la creacion de los eventos}
  TOnFrameVideoEvent =procedure (Sender:TObject;HndPreview:Thandle; lpVHdr:PVideoHdr) of object;
  TOnWaveStreamEvent =procedure (Sender:TObject;HndPreview:Thandle; lpWHdr:PWaveHdr) of object;
  TOnStatusErrorEvent=procedure (Sender:TObject;HndPreview:THandle;id:Integer;lpsz:PChar) of object;
  TOnYieldEvent   =procedure (Sender:TObject;HndPreview:THandle) of object;
  TOnControlEvent =procedure (Sender:TObject;HndPreview:THandle; nState:Integer) of object;

  TJLCVideo = class;
  TCanal = (Estereo, Mono);
  THertz = (_8kHz, _11025kHz, _22050kHz, _44100kHz);
  TBits  = (_8Bits, _16Bits);

  TFormatoAudio = class (TPersistent)
   private
    FCanales:TCanal;
    FCalidad:THertz;
    FBits:   Tbits;
   protected
    procedure SetAudioCanales(valor:TCanal);
    procedure SetAudioCalidad(valor:THertz);
    procedure SetAudiobits(Valor:TBits);
    procedure ActualizaAudio;

   public
     constructor create;
   published
     {Formato del audio}
     property Canales: TCanal read FCanales write SetAudioCanales default Mono;
     property Calidad: THertz read FCalidad write SetAudioCalidad default _8Khz;
     property Bits   : TBits  read FBits    write SetAudioBits default _8Bits;

  end;


  TJLCVideo = class(TCustomPanel)
   private
    { Private declarations }
    FVideoDriverNombre      : string;
    FFicheroVideo           : string;
    FFicheroImagen          : string;
    FEstabaOverlay:Boolean;
    FActivo:boolean;
    FOverlay:Boolean;
    FFramesPreview:Integer;
    FFramesCaptura:Integer;
    FHiloAparte:Boolean;
    FCapturaConAudio:Boolean;
    FOpcionesAudio:TFormatoAudio;
    FEscalaPreview:Boolean;
    FTiempoActivado:Boolean;
    FSegundos:Integer;
    FDriverIniciado:Boolean;
    FDispositivo:Integer;
    FHandlePreview:THandle;
    {Eventos}
    FOnFrame:TOnFrameVideoEvent;
    FONVIDEOSTREAM:TOnFrameVideoEvent;
    FONWAVESTREAM:TOnWaveStreamEvent;

    FONERROR:TOnStatusErrorEvent;
    FONSTATUS:TOnStatusErrorEvent;

    FONCONTROL:TOnControlEvent;
    FONYIELD:TOnYieldEvent;

    {instala las funciones de callback, encargadas de enviar los mensajes que haran
    saltar los eventos}
    procedure InstalarCallBack;
    procedure DesInstalarCallBack;

    {procedimientos encargados de recibir los mensajes, y de activar, en caso de que
    haya sido definido, el manejador de eventos correspondiente. Hay uno por cada
    tipo de mensaje que hemos definido. Aqui es donde se usan los tipos definidos con
    anterioridad}

    function   AbrirDriver : Boolean;
    function   IniciarDriver( Index : Integer ): Boolean;
    procedure  CerrarDriver;
    procedure  MostrarVideo;
    procedure  ActivarOverlay;
    procedure  ActivarPreview;
    procedure  SetActivo(Valor:boolean);
    procedure  SetOverlay(Valor:boolean);
    procedure  SetEscalaPreview(Valor:Boolean);
    procedure  SetCapturaConAudio(Valor:Boolean);
    procedure  SetFramesCaptura(Valor:Integer);
    procedure  SetHiloAparte(Valor:Boolean);
    procedure  SetTiempoActivado(Valor:Boolean);
    procedure  SetSegundos(Valor:integer);
    function   GetGrabando:Boolean;
    procedure  Conectar;
    procedure  Desconectar;
    function   TieneDlgFuente  : Boolean;
    function   TieneDlgFormato  : Boolean;
    function   TieneDlgDisplay  : Boolean;

  protected
    { Protected declarations }


  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Paint;override;

    procedure GrabarVideoDisco;
    procedure GrabarVideoSinDisco;
    procedure StopVideo;
    procedure GrabarImagenPortaPapeles;
    procedure GrabarImagenDisco;

    procedure SeleccionarFuente;
    procedure SeleccionarFormato;
    procedure SeleccionarCompresion;
    procedure SeleccionarDisplay;

    {Propiedad publica, de solo lectura}
    property HandlePreview:THandle read FHandlePreview;
    property Grabando:Boolean read GetGrabando;

  published
    property Activo: boolean read FActivo write SetActivo default false;
    property FicheroVideo:String read FFicheroVideo write FFicheroVideo;
    property FicheroImagen:String read FFicheroImagen write FFicheroImagen;
    property Overlay:Boolean read FOverlay write SetOverlay default True;
    property FramesPreview:Integer read FFramesPreview write FFramesPreview default 15;
    property FramesCaptura:Integer read FFramesCaptura write SetFramesCaptura default 15;
    property CapturaConAudio:Boolean read FCapturaConAudio write SetCapturaConAudio default false;
    property HiloAparte:Boolean read FHiloAparte write SetHiloAparte default true;
    property EscalaPreview:Boolean read  FEscalaPreview write SetEscalaPreview default True;
    property TiempoActivado:Boolean read FTiempoActivado write SetTiempoActivado default False;
    property Segundos:Integer read FSegundos write SetSegundos default 0;
    property Dispositivo:integer read FDispositivo write FDispositivo default 0;
    property OpcionesAudio:TFormatoAudio read FOpcionesAudio write FOpcionesAudio;
    property Align;
    property Visible;
    property Enabled;

    {eventos}
    property OnFrame:TOnFrameVideoEvent read FOnFrame write FOnFrame;
    property OnVideoStream:TOnFrameVideoEvent read FOnVideoStream write FOnVideoStream;
    property OnWaveStream:TOnWaveStreamEvent read FOnWaveStream write FOnWaveStream;
    property OnError:TOnStatusErrorEvent read FOnError write FOnError;
    property OnStatus:TOnStatusErrorEvent read FOnStatus write FOnStatus;
    property OnControl:TOnControlEvent read FOnControl write FOnControl;
    property OnYield:TOnYieldEvent read FOnYield write FOnYield;

    {hacemos visibles algunos eventos comunes}
    property Onclick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;

procedure Register;

implementation

const ACTIVAR=1;
      DESACTIVAR=0;
      CIERTO=1;
      FALSO=0;
      MAXVIDDRIVERS = 10;
      TEXTO_GRABAR = 'Grabando video';

var     FVentanaPreview         : THandle;
        FGrabando:Boolean;
        FAreaVideo: TWinControl;
{Funciones de CALLBACK. Estas funciones son llamadas periodicamente cuando se esta
visualizando o capturando video. Cada vez que sean llamadas, enviaran un mensaje al
propio componente, que será recogido por el manejador de mensajes correspondiente, el
cual a su vez llamara (si procede) al manejador de eventos definido por el usuario. Dicho
manejador de eventos recibira una serie de parametros, que se extraen del mensaje que la
funcion de callback envia. El handle que reciben las funciones de callback
es el de la ventana de Preview}

function STATUSCALLBACKProc(HndPreview:HWND; nID:Integer; lpsz:Pchar):LongInt; stdcall;
Var JLCVideo:TJLCVideo;
begin
     case Nid of
          IDS_CAP_BEGIN: FGrabando:=True;
          IDS_CAP_END  : FGrabando:=False;
     end;
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TJLCVideo(FAreaVideo);
     if not (csDesigning in JLCVideo.ComponentState) then
        if (Assigned(JLCVideo.FOnStatus)) then JLCVideo.FOnStatus(TObject(JLCVideo),HndPreview,nid, lpsz);
end;

function ERRORCALLBACKProc(HndPreview:HWND; nID:Integer; lpsz:Pchar):LongInt; stdcall;
Var JLCVideo:TJLCVideo;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TJLCVideo(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnError)) then JLCVideo.FOnError(TObject(JLCVideo),HndPreview,nid, lpsz);
end;

function WAVECALLBACKProc(HndPreview:HWND; lpWHdr:PWavehdr):LongInt; stdcall;
Var JLCVideo:TJLCVideo;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TJLCVideo(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnWaveStream)) then JLCVideo.FOnWaveStream(TObject(JLCVideo),HndPreview,lpWHdr);
end;


function CONTROLCALLBACKProc(HndPreview:HWND; nState:Integer):LongInt; stdcall;
Var JLCVideo:TJLCVideo;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TJLCVideo(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnControl)) then JLCVideo.FOnControl(TObject(JLCVideo),hndPReview, nState);
    Result:=CIERTO;

end;

{funciones de callback}
function YieldCallBackProc(HndPreview:HWND):LongInt; stdcall;
Var JLCVideo:TJLCVideo;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TJLCVideo(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnYield)) then JLCVideo.FOnYield(TObject(JLCVideo),HndPreview);
end;

function VideoCallBackProc(HndPreview:HWND;lp:PVideoHdr):LongInt;stdcall;
Var JLCVideo:TJLCVideo;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TJLCVideo(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnVideoStream)) then JLCVideo.FOnVideoStream(TObject(JLCVideo),HndPreview,lp);
end;

function FrameCallBackProc(HndPreview:HWND;lp:PVideoHdr):LongInt;stdcall;
Var JLCVideo:TJLCVideo;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TJLCVideo(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnFrame)) then JLCVideo.FOnFrame(TObject(JLCVideo),HndPreview,lp);
end;


{implementacion del componente}

constructor TJLCVideo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  parent:=AOwner as TWinCOntrol;
  width:=260;
  height:=180;
  FAreaVideo:=Self;
  FVentanaPreview         := 0;
  FVideoDriverNombre      := 'No hay driver';
  FFicheroVideo           := 'Video.avi';
  FFicheroImagen          := 'Imagen.bmp';
  FActivo:=False;
  FFramesPreview:=15;
  FFramesCaptura:=15;
  FHiloAparte:=True;
  FOverlay:=True;
  FEscalaPreview:=True;
  FCapturaConAudio:=False;
  FEstabaOverlay:=False;
  FTiempoActivado:=False;
  FSegundos:=0;
  FGrabando:=False;
  //Formato del audio
  FOpcionesAudio:=TFormatoAudio.Create;
end;

destructor TJLCVideo.Destroy;
begin
  if FActivo then Desconectar;
  inherited Destroy;
end;

procedure TJLCVideo.Paint;
begin
  inherited Paint;
  SetWindowPos(FVentanaPreview,HWND_TOP,0,0,width,height,SWP_SHOWWINDOW);
end;

function TJLCVideo.GetGrabando:boolean;
begin
     Result:=FGrabando;
end;

procedure TJLCVideo.SetSegundos(Valor:Integer);
Var CapParms         : TCAPTUREPARMS;
begin
   capCaptureGetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
   capParms.wTimeLimit:=Valor;
   capCaptureSetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
end;


procedure TJLCVideo.SetActivo(Valor:boolean);
begin
     FActivo:=Valor;
     if Valor then    //Activar el video
        Conectar
     else
        Desconectar
end;

procedure TJLCVideo.SetTiempoActivado(Valor:Boolean);
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     FTiempoActivado:=Valor;
     if FVentanaPreview=0 then exit;
     retc := capCaptureGetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
     if retc <> 0 then
     begin
  	CapParms.fLimitEnabled    := Valor;
        retc := capCaptureSetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
        if retc = 0 then exit;
     end;
end;

procedure TJLCVideo.SetEscalaPreview(Valor:Boolean);
begin
     FEscalaPreview:=Valor;
     if FVentanaPreview=0 then exit;
     if FEscalaPreview then
           capPreviewScale(FVentanaPreview, ACTIVAR)
     else
           capPreviewScale(FVentanaPreview, DESACTIVAR)
end;

procedure TJLCVideo.SetCapturaConAudio(Valor:Boolean);
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     FCapturaConAudio:=Valor;
     if FVentanaPreview=0 then exit;
     retc := capCaptureGetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
     if retc <> 0 then
     begin
  	CapParms.fCaptureAudio    := Valor;
        retc := capCaptureSetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
        if retc = 0 then exit;
     end;
end;

procedure TJLCVideo.SetFramesCaptura(Valor:Integer);
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     FFramesCaptura:=Valor;
     if FVentanaPreview=0 then exit;
     retc := capCaptureGetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
     if retc <> 0 then
     begin
  	CapParms.dwRequestMicroSecPerFrame    := (1000000 div Valor);
        retc := capCaptureSetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
        if retc = 0 then exit;
     end;
end;


procedure TJLCVideo.SetHiloAparte(Valor:Boolean);
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     FHiloAparte:=Valor;
     if FVentanaPreview=0 then exit;
     retc := capCaptureGetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
     if retc <> 0 then
     begin
        CapParms.fYield           := Valor;
        retc := capCaptureSetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
        if retc = 0 then exit;
     end;
end;


procedure  TJLCVideo.SetOverlay(Valor:boolean);
begin
     FOverlay:=Valor;
     MostrarVideo;
end;

procedure TJLCVideo.Conectar;
begin
  if AbrirDriver then
  begin
    SetEscalaPreview(FEscalaPreview);
    SetFramesCaptura(FFramesCaptura);
    SetCapturaConAudio(FCapturaConAudio);
    SetEscalaPreview(FEscalaPreview);
    SetFramesCaptura(FFramesCaptura);
    SetHiloAparte(FHiloAparte);
    SetTiempoActivado(FTiempoActivado);
    SetSegundos(FSegundos);
    FOpcionesAudio.ActualizaAudio;
    MostrarVideo;
  end
  else
     raise Exception.Create('No se ha podido conectar el video');
end;

procedure TJLCVideo.InstalarCallBack;
begin
     capSetCallBackOnYield(FVentanaPreview,Longint(@YieldCallBackProc));
     capSetCallbackOnVideoStream(FVentanaPreview,Longint(@VideoCallBackProc));
     capSetCallbackOnFrame (FVentanaPreview,Longint(@FrameCallBackProc));
     capSetCallbackOnError (FVentanaPreview,Longint(@ErrorCallBackProc));
     capSetCallbackOnStatus(FVentanaPreview,Longint(@StatusCallBackProc));
     capSetCallbackOnWaveStream (FVentanaPreview,Longint(@WaveCallBackProc));
     capSetCallbackOnCapControl (FVentanaPreview,Longint(@ControlCallBackProc));
end;

procedure TJLCVideo.DesInstalarCallBack;
begin
     capSetCallbackOnFrame (FVentanaPreview,0);
     capSetCallBackOnYield(FVentanaPreview,0);
     capSetCallbackOnVideoStream(FVentanaPreview,0);
     capSetCallbackOnError (FVentanaPreview,0);
     capSetCallbackOnStatus(FVentanaPreview,0);
     capSetCallbackOnWaveStream (FVentanaPreview,0);
     capSetCallbackOnCapControl (FVentanaPreview,0);
end;



procedure TJLCVideo.ActivarOverlay;
begin
	if FVentanaPreview = 0 then exit;
        capOverlay(FVentanaPreview, ACTIVAR);
        //desactivamos las callback, por si estabamos en modo preview y estaban activadas
        DesInstalarCallback;
end;

procedure TJLCVideo.ActivarPreview;
begin
   	if FVentanaPreview = 0 then exit;
        //Como ya estamos en modo preview, instalamos las callback
        InstalarCallBack;
        capPreviewRate(FVentanaPreview, 1000 div FFramesPreview);
	capPreview(FVentanaPreview, ACTIVAR);
end;



procedure TJLCVideo.MostrarVideo;
begin
     If FOverlay then
        ActivarOverlay
     else
        ActivarPreview;
end;


procedure TJLCVideo.Desconectar;
begin
     if (not FOverlay) then DesinstalarCallBack; //por si cerramos estando en modo preview
     CerrarDriver;
     FActivo:=False;
end;


function  TJLCVideo.AbrirDriver : Boolean;
var
  achDeviceName    : array [0..80] of Char;
  achDeviceVersion : array [0..100] of Char;
begin
   Result:=False;
  // Crear la ventana de captura y visualización
  FVentanaPreview := capCreateCaptureWindow( PChar('JLCVideo'),
                    WS_CHILD or WS_VISIBLE, 0, 0,
                    FAreaVideo.Width, FAreaVideo.Height,
                    FAreaVideo.Handle, 0);
{   FVentanaPreview := capCreateCaptureWindow( PChar('JLCVideo'),
                    WS_CHILD or WS_VISIBLE, 0, 0,
                    Width, Height,
                    Handle, 0);   }
  //Si tenemos éxito en la creación....
  if FVentanaPreview <> 0 then
  begin
      FHandlePreview:=FVentanaPreview;
      //Abrir el driver de video del dispositivo Fdispositivo (normalmente 0)
      FDriverIniciado := IniciarDriver( FDispositivo );
      //Si hemos conseguido conectar, obtenemos nombre y versión del driver
      if FDriverIniciado then
      begin
         //obtener el nombre y la version del driver que hemos instalado
         if capGetDriverDescription( FDispositivo, achDeviceName, 80, achDeviceVersion, 100 ) then
    	           FVideoDriverNombre := string(achDeviceName);
         Result:=TRUE;
      end
      else  //no hemos conseguido conectar, cerramos el driver
      begin
        Result := FALSE;
        CerrarDriver;
        FVentanaPreview := 0;
      end;
  end;
end;


function TJLCVideo.IniciarDriver( Index : Integer ): Boolean;
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     Result := FALSE;
     // Nos conectamos al driver de captura de video
     if capDriverConnect(FVentanaPreview, Index) <> 0 then
     begin
        retc := capCaptureGetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
	if retc <> 0 then
        begin
	  	CapParms.fMCIControl      := FALSE;
	  	CapParms.vKeyAbort        := VK_ESCAPE;
	  	CapParms.fAbortLeftMouse  := FALSE;
	  	CapParms.fAbortRightMouse := FALSE;
                retc := capCaptureSetSetup(FVentanaPreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
                if retc = 0 then exit;
        end;
	Result := TRUE;
     end
     else
       Raise Exception.Create('>>>  Nenhuma webcam foi encontrada.  <<<     '+#13);
end;

procedure TJLCVideo.CerrarDriver;
begin
     if FVentanaPreview <> 0 then
     begin
	  capSetCallbackOnStatus(FVentanaPreview, LongInt(0));
	  capDriverDisconnect( FVentanaPreview );
          DestroyWindow( FVentanaPreview ) ;
	  FVentanaPreview := 0;
     end;
end;

procedure TJLCVideo.GrabarImagenDisco;
var
	achSingleFileName  : array [0..255] of Char;
begin
	if FVentanaPreview = 0 then exit;
	capGrabFrameNOStop(FVentanaPreview);
 	StrPCopy(achSingleFileName, FFicheroImagen);
	capFileSaveDIB(FVentanaPreview, LongInt(@achSingleFileName));
end;

procedure TJLCVideo.GrabarImagenPortaPapeles;
begin
	if FVentanaPreview = 0 then exit;
	capGrabFrameNOStop(FVentanaPreview);
        capEditCopy(FVentanaPreview);
end;


procedure TJLCVideo.GrabarVideoDisco;
var
	achFileName  : array [0..255] of Char;
        retc:Integer;
begin
     if FVentanaPreview = 0 then exit;
     ActivarPreview;
     StrPCopy(achFileName, FFicheroVideo);
     retc := capFileSetCaptureFile(FVentanaPreview, LongInt(@achFileName));
     if retc = FALSO then
          showmessage(FVideoDriverNombre+': Error en capFileSetCaptureFile');
     capCaptureSequence( FVentanaPreview );
end;

procedure TJLCVideo.GrabarVideoSinDisco;
begin
     if FVentanaPreview = 0 then exit;
     ActivarPreview;
     capCaptureSequenceNoFile( FVentanaPreview );
end;


procedure TJLCVideo.StopVideo;
begin
     if FVentanaPreview = 0 then exit;
     //If not GetGrabando then Exit;
     capCaptureStop(FVentanaPreview);
end;

procedure TJLCVideo.SeleccionarFormato;
begin
	if FVentanaPreview = 0 then exit;
        if TieneDlgFormato then
	   capDlgVideoFormat(FVentanaPreview)
        else
            raise Exception.Create('El dispositivo no permite seleccionar el formato');
end;

procedure  TJLCVideo.SeleccionarDisplay;
begin
	if FVentanaPreview = 0 then exit;
        if TieneDlgDisplay then
	   capDlgVideoDisplay(FVentanaPreview)
        else
            raise Exception.Create('El dispositivo no permite seleccionar el display');

end;


procedure TJLCVideo.SeleccionarFuente;
begin
	if FVentanaPreview = 0 then exit;
        if TieneDlgFuente then
            capDlgVideoSource(FVentanaPreview)
        else
            raise Exception.Create('El dispositivo no permite seleccionar la fuente');
end;

procedure TJLCVideo.SeleccionarCompresion;
begin
	if FVentanaPreview = 0 then exit;
        capDlgVideoCompression(FVentanaPreview);
end;


function  TJLCVideo.TieneDlgFormato  : Boolean;
var
  CDrvCaps : TCapDriverCaps;
begin
   Result := TRUE;
   if FVentanaPreview = 0 then exit;
   capDriverGetCaps(FVentanaPreview, LongInt(@CDrvCaps), sizeof(TCapDriverCaps));
   Result := CDrvCaps.fHasDlgVideoFormat;
end;

function  TJLCVideo.TieneDlgDisplay : Boolean;
var
  CDrvCaps : TCapDriverCaps;
begin
	Result := TRUE;
	if FVentanaPreview = 0 then exit;
        capDriverGetCaps(FVentanaPreview, LongInt(@CDrvCaps), sizeof(TCapDriverCaps));
        Result := CDrvCaps.fHasDlgVideoDisplay;
end;

function  TJLCVideo.TieneDlgFuente  : Boolean;
var
  CDrvCaps : TCapDriverCaps;
begin
  Result := TRUE;
  if FVentanaPreview = 0 then exit;
  capDriverGetCaps(FVentanaPreview, LongInt(@CDrvCaps), sizeof(TCapDriverCaps));
  Result := CDrvCaps.fHasDlgVideoSource;
end;

//Seleccionar el formato de audio
constructor TformatoAudio.create;
begin
     inherited create;
     FCanales:=Mono;
     FCalidad:=_8khz;
     FBits:=_8Bits;

end;
procedure TFormatoAudio.SetAudioCanales;
begin
     FCanales:=Valor;
     ActualizaAudio;
end;

procedure TFormatoAudio.SetAudioCalidad;
begin
     FCalidad:=Valor;
     ActualizaAudio;
end;


procedure TFormatoAudio.SetAudiobits;
begin
     FBits:=Valor;
     ActualizaAudio;
end;

procedure TFormatoAudio.ActualizaAudio;
Var WAVEFORMATEX:TWAVEFORMATEX;
begin
    if FVentanaPreview=0 then exit;
     //Capturamos los datos del audio, para grabar a 8Khz
     capGetAudioFormat(FVentanaPreview,LongInt(@WAVEFORMATEX), SizeOf(TWAVEFORMATEX));
     //modificamos la calidad del audio
     case FCalidad of
          _8khz    :WAVEFORMATEX.nSamplesPerSec:=8000;
          _11025khz:WAVEFORMATEX.nSamplesPerSec:=11025;
          _22050khz:WAVEFORMATEX.nSamplesPerSec:=22050;
          _44100khz:WAVEFORMATEX.nSamplesPerSec:=44100;
     end;
     WAVEFORMATEX.nAvgBytesPerSec:= WAVEFORMATEX.nSamplesPerSec;
     if FCanales=Mono then
          WAVEFORMATEX.nChannels:=1
     else
          WAVEFORMATEX.nChannels:=2;
     if FBits=_8Bits then
        WAVEFORMATEX.wBitsPerSample:=8
     else
        WAVEFORMATEX.wBitsPerSample:=16;
     //Actualizamos los datos del audio
     capSetAudioFormat(FVentanaPreview,LongInt(@WAVEFORMATEX), SizeOf(TWAVEFORMATEX));
end;

procedure Register;
begin
  RegisterComponents('JLCSoft', [TJLCVideo]);
end;



end.
