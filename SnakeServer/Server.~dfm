object Form1: TForm1
  Left = 63
  Top = 142
  Width = 187
  Height = 154
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object UDPS: TIdUDPServer
    Active = True
    Bindings = <>
    DefaultPort = 3000
    OnUDPRead = UDPSUDPRead
    Left = 56
    Top = 8
  end
  object UDPC: TIdUDPClient
    Active = True
    Host = '127.0.0.1'
    Port = 5000
    Left = 24
    Top = 8
  end
  object UDPC2: TIdUDPClient
    Active = True
    Host = '127.0.0.1'
    Port = 5001
    Left = 24
    Top = 48
  end
  object UDPS2: TIdUDPServer
    Active = True
    Bindings = <>
    DefaultPort = 3001
    OnUDPRead = UDPS2UDPRead
    Left = 56
    Top = 48
  end
end
