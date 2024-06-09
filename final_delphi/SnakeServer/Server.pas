unit Server;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdUDPServer, IdUDPBase, IdUDPClient,
  IdSocketHandle;

const
  SnakeMaxLength = 100; // �D���̤j����
  SnakeNum = 2;         // �D���ƶq
  FoodCount = 30;       // �������ƶq
  GameWidth = 570;      // �C���e��
  GameHeight = 370;     // �C������

type
  // �y�Щw�q
  TPoint = record
    X, Y: Integer;
  end;

  TForm1 = class(TForm)
    UDPS: TIdUDPServer;   // UDP���A��1
    UDPC: TIdUDPClient;   // UDP�Ȥ��1
    UDPS2: TIdUDPServer;  // UDP���A��2
    UDPC2: TIdUDPClient;  // UDP�Ȥ��2
    procedure FormCreate(Sender: TObject);  // �{���Ұ�
    procedure UDPSUDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
    procedure UDPS2UDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
  private
    Foods: array[1..FoodCount] of TPoint; // ������array
    Invite: Array[1..2] of Boolean;       // �ܽЪ��A
    procedure PlaceFood;                  // ��m��������k
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  form1.Caption := 'Snake Server';  // �]�w���D
  Randomize; // �H���ƺؤl
end;

// UDP���A��1Ū��
procedure TForm1.UDPSUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  str: string;
  length: integer;
  action: string;
  i: integer;
  isStarting: boolean;
  Direction: String;
begin
  isStarting := true;

  length := Adata.Size;               // ����ƾڪ���
  Setlength(str, length);             // �]�m�r�����
  Adata.Read(str[1], length);         // Ū���ƾڨ�r��
  action := copy(str, 2, length - 1); // ����ʧ@
  if action = 'Invite' then begin     // �p�G�O�ܽ�
    for i := 1 to SnakeNum do begin
      if invite[i] = false then begin
        invite[i] := true;            // �аO���w�ܽ�
        UDPC.Send(IntToStr(i) + 'Serial');  // �o�e�s��
        if i <> SnakeNum then begin
          isStarting := false;
          UDPC2.Send(str);            // �o�e�ܽе��t�@�ӫȤ��
          break;
        end;
      end;
    end;
    if isStarting then begin                // �p�G�C���Y�N�}�l
      Direction := IntToStr(Random(4));     // �H����V
      UDPC.Send('1Direction' + Direction);  // �o�e��V���Ȥ��1
      UDPC2.Send('1Direction' + Direction); // �o�e��V���Ȥ��2

      Direction := IntToStr(Random(4));     // �H����V
      UDPC.Send('2Direction' + Direction);  // �o�e��V���Ȥ��1
      UDPC2.Send('2Direction' + Direction); // �o�e��V���Ȥ��2
      
      UDPC.Send('0Start');  // �o�e�}�l���O���Ȥ��1
      UDPC2.Send('0Start'); // �o�e�}�l���O���Ȥ��2
      for i := 1 to SnakeNum do begin
        Invite[i] := false; // ���m�ܽЪ��A
      end;
      Sleep(1500);
      PlaceFood;  // ��m����
    end;
  end else if copy(action, 1, 3) = 'Eat' then begin // �Y
    i := strtoint(copy(str, 5, 2));                 // �������������
    Foods[i].X := Random(GameWidth - 20) + 10;      // �H���ͦ�������X�y��
    Foods[i].Y := Random(GameHeight - 20) + 10;     // �H���ͦ�������Y�y��
    UDPC.Send(str + Format('%.3d', [Foods[i].X]) +  // �o�e�s������m���Ȥ��1
                    Format('%.3d', [Foods[i].Y]));
    UDPC2.Send(str + Format('%.3d', [Foods[i].X]) + // �o�e�s������m���Ȥ��2
                     Format('%.3d', [Foods[i].Y]));
  end else begin
    UDPC.Send(str);   // ��o�ƾڵ��Ȥ��1
    UDPC2.Send(str);  // ��o�ƾڵ��Ȥ��2
  end;
end;

// UDP���A��2Ū��
procedure TForm1.UDPS2UDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  str: string;
  length: integer;
  action: string;
  i: integer;
  isStarting: boolean;
  Direction: String;
begin
  isStarting := true;

  length := Adata.Size;
  Setlength(str, length);
  Adata.Read(str[1], length);
  action := copy(str, 2, length - 1);
  if action = 'Invite' then begin
    for i := 1 to SnakeNum do begin
      if invite[i] = false then begin
        invite[i] := true;
        UDPC2.Send(IntToStr(i) + 'Serial');
        if i <> SnakeNum then begin
          isStarting := false;
          UDPC.Send(str);
          break;
        end;
      end;
    end;
    if isStarting then begin
      Direction := IntToStr(Random(4));
      UDPC.Send('1Direction' + Direction);
      UDPC2.Send('1Direction' + Direction);

      Direction := IntToStr(Random(4));
      UDPC.Send('2Direction' + Direction);
      UDPC2.Send('2Direction' + Direction);

      UDPC.Send('0Start');
      UDPC2.Send('0Start');
      for i := 1 to SnakeNum do begin
        Invite[i] := false;
      end;
      Sleep(1500);
      PlaceFood;
    end;
  end else if copy(action, 1, 3) = 'Eat' then begin
    i := strtoint(copy(str, 5, 2));
    Foods[i].X := Random(GameWidth - 20) + 10;
    Foods[i].Y := Random(GameHeight - 20) + 10;
    UDPC.Send(str + Format('%.3d', [Foods[i].X]) +
                    Format('%.3d', [Foods[i].Y]));
    UDPC2.Send(str + Format('%.3d', [Foods[i].X]) +
                     Format('%.3d', [Foods[i].Y]));
  end else if action = 'Tie' then begin
    // ����h���򳣤���
  end else begin
    UDPC.Send(str);
    UDPC2.Send(str);
  end;
end;

// �H����m����
procedure TForm1.PlaceFood;
var
  i: Integer;
begin
  for i := 1 to FoodCount do begin
    Foods[i].X := Random(GameWidth - 20) + 10;  // �H���ͦ�������X�y��
    Foods[i].Y := Random(GameHeight - 20) + 10; // �H���ͦ�������Y�y��
  end;
  UDPC.SendBuffer(Foods, FoodCount * SizeOf(TPoint));   // �o�e�����ƾڵ��Ȥ��1
  UDPC2.SendBuffer(Foods, FoodCount * SizeOf(TPoint));  // �o�e�����ƾڵ��Ȥ��2
end;

end.
