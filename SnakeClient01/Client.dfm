object Form1: TForm1
  Left = 194
  Top = 162
  Width = 590
  Height = 410
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 574
    Height = 371
    Align = alClient
  end
  object ScoreLabel: TLabel
    Left = 8
    Top = 8
    Width = 37
    Height = 13
    Caption = 'Score:0'
  end
  object Button1: TButton
    Left = 256
    Top = 160
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Timer1: TTimer
    Enabled = False
    OnTimer = Timer1Timer
    Left = 88
    Top = 72
  end
  object UDPS: TIdUDPServer
    Active = True
    Bindings = <>
    DefaultPort = 5000
    OnUDPRead = UDPSUDPRead
    Left = 192
    Top = 72
  end
  object UDPC: TIdUDPClient
    Active = True
    Host = '127.0.0.1'
    Port = 3000
    Left = 136
    Top = 72
  end
end
