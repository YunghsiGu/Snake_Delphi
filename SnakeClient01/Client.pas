unit Client;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IdBaseComponent, IdComponent, IdTCPServer,
  IdUDPClient, IdUDPBase, IdUDPServer, IdSocketHandle;

const
  SnakeMaxLength = 100;
  FoodCount = 30;
  Width = 574;
  Height = 371;

type
  TDirection = (DirUp, DirDown, DirLeft, DirRight);

  TPoint = record
    X, Y: Integer;
  end;

  TSnake = record
    Length: Integer;
    Radius: Integer;
    Body: array[1..SnakeMaxLength] of TPoint;
    Direction: TDirection;
  end;

  TForm1 = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    UDPS: TIdUDPServer;
    UDPC: TIdUDPClient;
    Button1: TButton;
    ScoreLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UDPSUDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    SnakeSelf: TSnake;
    SnakeOther: TSnake;
    Label2: TLabel;
    Canvas1: TCanvas;
    Foods: array[1..FoodCount] of TPoint;
    Colors: array[1..7] of TColor;
    ScoreSelf: Integer;
    ScoreOther: Integer;
    procedure InitializeGame;
    procedure StartCountdown;
    procedure ClearScreen;
    procedure DrawGame;
    procedure DrawSnake(const Snake: TSnake);
    procedure UpdateSnakePosition;
    procedure UpdateSnakeHead(var Snake: TSnake);
    procedure WrapAround(var Snake: TSnake; Width, Height: Integer);
    procedure Label2Build;
    procedure EatFood(var Snake: TSnake);
    function CheckGameOver: Boolean;
    function IsCollision(const Snake: TSnake; const Food: TPoint): Boolean;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  SerialNum: String;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  form1.Caption := 'Snake Server' + SerialNum;
  SerialNum := '1';
  // Initialize colors
  Colors[1] := $6666ff;
  Colors[2] := $FF7979;
  Colors[3] := $DC35FF;
  Colors[4] := $94FF28;
  Colors[5] := $44FFFF;
  Colors[6] := $FFFF4D;
  Colors[7] := $B266FF;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // �ھګ��U����V���s�D�����ʤ�V
  case Key of
    VK_Up: begin
      UDPC.Send(SerialNum + 'U');
    end;
    VK_Down: begin
      UDPC.Send(SerialNum + 'D');
    end;
    VK_Left: begin
      UDPC.Send(SerialNum + 'L');
    end;
    VK_Right: begin
      UDPC.Send(SerialNum + 'R');
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  // Main game loop
  DrawGame;
  UpdateSnakePosition;
  {if CheckGameOver then
  begin
    Timer1.Enabled := False;
    ShowMessage('Game Over! Final Score: ' + IntToStr(Score));
  end;}
end;

procedure TForm1.UDPSUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  str: string;
  length: integer;
  action: string;
  idx: integer;
  position: integer;
begin
  length := Adata.Size;
  Setlength(str, length);
  Adata.Read(str[1], length);
  action := copy(str, 2, length - 1);

  if action = 'U' then begin
    if str[1] = SerialNum then snakeSelf.Direction := DirUp
    else snakeOther.Direction := DirUp;
  end else if action = 'D' then begin
    if str[1] = SerialNum then snakeSelf.Direction := DirDown
    else snakeOther.Direction := DirDown;
  end else if action = 'L' then begin
    if str[1] = SerialNum then snakeself.Direction := DirLeft
    else snakeOther.Direction := DirLeft;
  end else if action = 'R' then begin
    if str[1] = SerialNum then snakeSelf.Direction := DirRight
    else snakeOther.Direction := DirRight;
  end else if copy(action, 1, 3) = 'Eat' then begin
    idx := strtoint(copy(str, 5, 2));
    position := strtoint(copy(str, 7, 3));
    Foods[idx].X := position;
    position := strtoint(copy(str, 10, 3));
    Foods[idx].Y := position;

    if str[1] = SerialNum then begin
      Inc(ScoreSelf);                               // �W�[����
      SnakeSelf.Length := SnakeSelf.Length + 1;   // �D�ܪ�
      if ScoreSelf mod 3 = 2 then begin               // �D�ܭD
        SnakeSelf.Radius := SnakeSelf.Radius + 1;
      end;
      SnakeSelf.Length := SnakeSelf.Length + 1;   // �W�[�D������
    end else begin
      Inc(ScoreOther);                                 // �W�[����
      SnakeOther.Length := SnakeOther.Length + 1; // �D�ܪ�
      if ScoreOther mod 3 = 2 then begin               // �D�ܭD
        SnakeOther.Radius := SnakeOther.Radius + 1;
      end;
      SnakeOther.Length := SnakeOther.Length + 1; // �W�[�D������
    end;
  end else if action = 'Start' then begin
    button1.Visible := false;
    StartCountDown;
    InitializeGame;
  end else if (action = 'Invite') and (str[1] <> SerialNum) then begin
    if Application.MessageBox('You are invited to play game! ', 'Invitation',
    MB_OKCANCEL) = IDOK then
    begin
      UDPC.Send(SerialNum + 'Invite');
    end;
  end else begin
    // �����쭹���ƾ�
    Adata.Position := 0;
    Adata.Read(Foods[1], FoodCount * SizeOf(TPoint));
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  UDPC.Send(SerialNum + 'Invite');
  Label2Build;
  Label2.Font.Size := 12;
  Label2.Caption := 'Waiting for the other player...';
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if label2 <> nil then begin
    label2.Free;
    label2 := nil;
  end;
end;

procedure TForm1.InitializeGame;
begin
  ScoreSelf := 0;   // ��l�Ƥ���
  ScoreOther := 0;

  // �Ыؤ�����ܼ���
  ScoreLabel := TLabel.Create(form1);
  ScoreLabel.Parent := form1;
  ScoreLabel.Left := 10;
  ScoreLabel.Top := 10;
  ScoreLabel.Caption := 'Score: 0';

  // ��l�ƹC���e��
  Canvas1 := Image1.Picture.Bitmap.Canvas;
  Image1.Picture.Bitmap.Width := form1.image1.Width;
  Image1.Picture.Bitmap.Height := form1.image1.Height;

  Randomize; // �H���ƺؤl

  // ��l�ƳD
  SnakeSelf.Length := 3;
  SnakeSelf.Radius := 5;
  SnakeSelf.Body[1].X := 460;
  SnakeSelf.Body[1].Y := 260;
  SnakeSelf.Direction := TDirection(Random(4));  // �H���]�m�D����l���ʤ�V

  SnakeOther.Length := 3;
  SnakeOther.Radius := 5;
  SnakeOther.Body[1].X := 130;
  SnakeOther.Body[1].Y := 150;

  // �]�m Timer ����
  form1.Timer1.Interval := 100;   // �]�m�ɶ����j�� 100 �@��
  form1.Timer1.OnTimer := form1.Timer1Timer;    // ���p Timer �ƥ�B�z�{��
  form1.Timer1.Enabled := True;    // �ҥ� Timer ����
end;

procedure TForm1.StartCountdown;
var
  i: integer;
begin
  Label2Build;
  Label2.Font.Size := 30;
  label2.Caption := '3';
  for i := 3 downto 1 do begin
    label2.Caption := IntToStr(i);
    Application.ProcessMessages;  // ��s�ɭ�
    Sleep(1000);
  end;
  label2.Visible := false;
end;

// �M���C���e��
procedure TForm1.ClearScreen;
var tc: TRect;
begin
  tc.Top := 0;
  tc.Left := 0;
  tc.Bottom := Height;
  tc.Right := Width;
  form1.image1.Picture.Bitmap.Canvas.Brush.Color := $FFFFFF;
  form1.image1.Picture.Bitmap.Canvas.FillRect(tc);
end;

// ø�s�C���e��
procedure TForm1.DrawGame;
var
  i: Integer;
  idx: integer;
begin
  // ��s�������
  if Assigned(ScoreLabel) then
    //ScoreLabel.Caption := 'Score: ' + IntToStr(Score);
    
  ClearScreen;

  Canvas1.Brush.Color := clGreen;   // �]�m�D�����C��

  DrawSnake(SnakeSelf);
  DrawSnake(SnakeOther);

  for i := 1 to FoodCount do begin
    idx := (i Mod 7) + 1;
    Canvas1.Brush.Color := colors[idx];   // �]�m�����C��
    Canvas1.Pen.Color := colors[idx];
    Canvas1.Ellipse(Foods[i].X - 3, Foods[i].Y - 3,
                    Foods[i].X + 3, Foods[i].Y + 3);   // ø�s����
  end;
  Canvas1.Pen.Color := clBlack;
  Canvas1.Brush.Color := clGreen;
end;

procedure TForm1.DrawSnake(const Snake: TSnake);
var
  i: Integer;
begin
  for i := 1 to Snake.Length do
    Canvas1.Rectangle(Snake.Body[i].X - Snake.Radius,
                      Snake.Body[i].Y - Snake.Radius,
                      Snake.Body[i].X + Snake.Radius,
                      Snake.Body[i].Y + Snake.Radius);
end;

// ��s�D����m
procedure TForm1.UpdateSnakePosition;
var i: Integer;
begin
   // �N�D���骺��m�V�e���ʤ@��
  for i := SnakeSelf.Length downto 2 do
    SnakeSelf.Body[i] := SnakeSelf.Body[i - 1];

  UpdateSnakeHead(SnakeSelf);
  WrapAround(SnakeSelf, image1.Width, image1.Height);
  EatFood(SnakeSelf);

   // �N�D���骺��m�V�e���ʤ@��
  for i := SnakeOther.Length downto 2 do
    SnakeOther.Body[i] := SnakeOther.Body[i - 1];

  UpdateSnakeHead(SnakeOther);
  WrapAround(SnakeOther, image1.Width, image1.Height);
end;

procedure TForm1.UpdateSnakeHead(var Snake: TSnake);
begin
  case Snake.Direction of
    DirUp: Dec(Snake.Body[1].Y, 10);
    DirDown: Inc(Snake.Body[1].Y, 10);
    DirLeft: Dec(Snake.Body[1].X, 10);
    DirRight: Inc(Snake.Body[1].X, 10);
  end;
end;

procedure TForm1.WrapAround(var Snake: TSnake; Width, Height: Integer);
begin
  if (Snake.Body[1].X < 1) then
    Snake.Body[1].X := Width;
  if (Snake.Body[1].X > Width) then
    Snake.Body[1].X := 1;
  if (Snake.Body[1].Y < 1) then
    Snake.Body[1].Y := Height;
  if (Snake.Body[1].Y > Height) then
    Snake.Body[1].Y := 1;
end;

procedure TForm1.Label2Build;
begin
  if Label2 = nil then begin
    Label2 := TLabel.Create(form1);
    Label2.Parent := form1;
    Label2.Left := (image1.Width div 2) - 100;
    Label2.Top := (image1.Height div 2) - 25;
    Label2.Alignment := taCenter;
    Label2.Width := 200;
    Label2.Height := 50;
    Label2.AutoSize := false;
  end;
end;

procedure TForm1.EatFood(var Snake: TSnake);
var
  i: integer;
begin
  for i := 1 to FoodCount do begin
    if IsCollision(Snake, Foods[i]) then begin
      UDPC.Send(SerialNum + 'Eat' + Format('%.2d', [i]));
      break;
    end;
  end;
end;

// �ˬd�C���O�_����
function TForm1.CheckGameOver: Boolean;
var i: Integer;
begin
  Result := False;
  for i := 2 to SnakeSelf.Length do
  begin
    if (SnakeSelf.Body[1].X = SnakeSelf.Body[i].X) and
       (SnakeSelf.Body[1].Y = SnakeSelf.Body[i].Y) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function TForm1.IsCollision(const Snake: TSnake;
  const Food: TPoint): Boolean;
var
  Distance: Double;
begin
  Distance := Sqrt(Sqr(Snake.Body[1].X - Food.X) +
                   Sqr(Snake.Body[1].Y - Food.Y));
  Result := Distance < (Snake.Radius + 3);
end;

end.