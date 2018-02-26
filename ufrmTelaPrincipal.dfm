object frmTelaPrincipal: TfrmTelaPrincipal
  Left = 0
  Top = 0
  Cursor = crArrow
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'WebCamVigia 1.0'
  ClientHeight = 493
  ClientWidth = 466
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clNavy
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object TImage
    Left = 498
    Top = 16
    Width = 105
    Height = 105
  end
  object JvGradient1: TJvGradient
    Left = 0
    Top = 0
    Width = 466
    Height = 493
    Style = grVertical
    StartColor = 16744448
    ExplicitLeft = 540
    ExplicitTop = 248
    ExplicitWidth = 100
    ExplicitHeight = 41
  end
  object Panel1: TPanel
    Left = 8
    Top = 361
    Width = 449
    Height = 123
    BevelKind = bkSoft
    BevelOuter = bvNone
    Color = clWindow
    ParentBackground = False
    TabOrder = 0
    object JLCVideo1: TJLCVideo
      Left = 284
      Top = 112
      Width = 26
      Height = 22
      FicheroVideo = 'Video.avi'
      FicheroImagen = 'Imagen.bmp'
      Visible = False
    end
    object pnlControls: TPanel
      Left = 0
      Top = 0
      Width = 445
      Height = 119
      Align = alClient
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 1
      object lblInformation: TLabel
        Left = 4
        Top = 75
        Width = 12
        Height = 13
        Caption = '---'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsItalic]
        ParentFont = False
        Visible = False
      end
      object Label1: TLabel
        Left = 4
        Top = 2
        Width = 100
        Height = 13
        Hint = 'This shows the actual movement detected between frames (0-100)'
        Caption = 'N'#237'vel de movimento: '
        ParentShowHint = False
        ShowHint = True
      end
      object Label2: TLabel
        Left = 4
        Top = 22
        Width = 83
        Height = 13
        Hint = 
          'Drag the slider to indicate the amount of movement that will tri' +
          'gger actions'
        Caption = 'N'#237'vel para alerta:'
        ParentShowHint = False
        ShowHint = True
      end
      object lblActualMovement: TLabel
        Left = 406
        Top = 3
        Width = 7
        Height = 13
        Hint = 'This shows the actual movement detected between frames (0-100)'
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object lblMovementTrigger: TLabel
        Left = 406
        Top = 25
        Width = 7
        Height = 13
        Hint = 
          'Drag the slider to indicate the amount of movement that will tri' +
          'gger actions'
        Caption = '0'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        ParentShowHint = False
        ShowHint = True
      end
      object TImage
        Left = 152
        Top = -160
        Width = 105
        Height = 105
      end
      object SpeedButton1: TSpeedButton
        Left = 4
        Top = 92
        Width = 437
        Height = 22
        Cursor = crHandPoint
        Caption = '>>>  Ativar Vigia!  <<<'
        Flat = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = SpeedButton1Click
      end
      object ProgressBar1: TProgressBar
        Left = 105
        Top = 2
        Width = 283
        Height = 17
        ParentShowHint = False
        ShowHint = False
        TabOrder = 0
      end
      object TrackBar1: TTrackBar
        Left = 99
        Top = 19
        Width = 297
        Height = 33
        Max = 100
        ParentShowHint = False
        ShowHint = False
        TabOrder = 1
        TickStyle = tsNone
        OnChange = TrackBar1Change
      end
      object chkbxEnviarEmail: TCheckBox
        Left = 4
        Top = 52
        Width = 237
        Height = 21
        Caption = 'Enviar E-mail de Alerta '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
    end
  end
  object pnlMainImage: TPanel
    Left = 8
    Top = 8
    Width = 449
    Height = 345
    BevelKind = bkSoft
    BevelOuter = bvNone
    TabOrder = 1
    object imgPrevious: TImage
      Left = 99
      Top = 6
      Width = 89
      Height = 64
      Stretch = True
      Visible = False
    end
    object imgCurrent: TImage
      Left = 9
      Top = 10
      Width = 84
      Height = 63
      Stretch = True
    end
    object pnlDetectionZone: TPanel
      Left = 9
      Top = 19
      Width = 116
      Height = 110
      BevelOuter = bvNone
      Color = clYellow
      ParentBackground = False
      TabOrder = 0
      Visible = False
      object pnlZoneImage: TPanel
        Left = 3
        Top = 3
        Width = 110
        Height = 102
        Color = clBlue
        TabOrder = 0
        object imgZone: TImage
          Left = 1
          Top = 1
          Width = 236
          Height = 144
          Align = alCustom
          ParentShowHint = False
          ShowHint = False
          Stretch = True
        end
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 356
    object Opes1: TMenuItem
      Caption = 'Op'#231#245'es'
      object Selecionarcamera1: TMenuItem
        Caption = 'Selecionar webcam'
        OnClick = Selecionarcamera1Click
      end
    end
    object ConfiguraesdeEmail1: TMenuItem
      Caption = 'Configura'#231#245'es'
      object ConfiguraodeEmail1: TMenuItem
        Caption = 'Configura'#231#227'o de E-mail'
      end
    end
    object Ajuda1: TMenuItem
      Caption = 'Ajuda'
      object Sobreoprograma1: TMenuItem
        Caption = 'Sobre o programa'
      end
      object Sobreoautor1: TMenuItem
        Caption = 'Sobre o autor'
      end
    end
  end
  object JvBalloonHint1: TJvBalloonHint
    DefaultBalloonPosition = bpRightUp
    DefaultImageIndex = 0
    Options = [boUseDefaultIcon, boShowCloseBtn, boCustomAnimation]
    ApplicationHintOptions = [ahShowHeaderInHint, ahShowIconInHint, ahPlaySound]
    Left = 292
    Top = 20
  end
  object JvTrayIcon1: TJvTrayIcon
    Active = True
    Animated = True
    IconIndex = 0
    Visibility = [tvVisibleTaskBar, tvVisibleTaskList, tvAutoHide, tvRestoreClick]
    Left = 408
    Top = 56
  end
end
