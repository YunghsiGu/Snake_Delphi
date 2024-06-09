unit Client;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IdBaseComponent, IdComponent, IdTCPServer,
  IdUDPClient, IdUDPBase, IdUDPServer, IdSocketHandle, JPEG;

const
  SnakeMaxLength = 100; // �D���̤j����
  FoodCount = 30;       // �����ƶq
  GameWidth = 570;      // �C���e��
  GameHeight = 370;     // �C������

type
  TDirection = (DirUp, DirDown, DirLeft, DirRight); // �w�q��V

  TPoint = record // �w�q�y��
    X, Y: Integer;
  end;

  TSnake = record // �w�q�D
    Length: Integer;
    Radius: Integer;
    Body: array[1..SnakeMaxLength] of TPoint;
    Direction: TDirection;
  end;

  // ���쪺�覡
  TCollisionWay = (None, HeadToHead, HeadToBody);

  TForm1 = class(TForm)
    Timer1: TTimer;
    UDPS: TIdUDPServer;
    UDPC: TIdUDPClient;
    ScoreLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UDPSUDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
    procedure FormDestroy(Sender: TObject);
  private
    SnakeSelf: TSnake;    // �ۤv���D
    SnakeOther: TSnake;   // ��誺�D
    LabelWait: TLabel;    // ���ݤ�r
    ImgGame: TImage;      // �D���e��
    ImgFront: TImage;     // ����
    BtnStart: TButton;    // �}�l
    Canvas1: TCanvas;
    Foods: array[1..FoodCount] of TPoint;
    Colors: array[1..7] of TColor;  // �������C��
    ScoreSelf: Integer;   // �ۤv������
    ScoreOther: Integer;  // ��誺����
    SerialNum: String;    // �s��
    procedure InitializeGame; // �C����l��
    procedure InitializeSnake(Serial: String);  // �D����l��
    procedure DrawEdge;       // �e�C�����
    procedure StartCountdown; // �˼ƭp��
    procedure ClearScreen;    // �M���e��
    procedure DrawGame;       // �e�C���e��
    procedure DrawSnake(const Snake: TSnake); // �e�D
    procedure UpdateSnakePosition;  // ��s�D���ʫ᪺��m
    procedure UpdateSnakeHead(var Snake: TSnake); // ��s�D�Y��V
    procedure WrapAround(var Snake: TSnake; Width, Height: Integer);  // �D�Y
    procedure LabelWaitBuild; // ���ݹ��
    procedure ImgGameBuild;
    procedure ImgFrontBuild;  // �����Ϥ�
    procedure BtnStartBuild;  // �}�l���s
    procedure BtnStartClick(Sender: TObject);
    procedure BtnLeaveClick(Sender: TObject);
    procedure EatFood(var Snake: TSnake); // �Y�쭹��
    function IsCollision(const Snake: TSnake; const Food: TPoint): Boolean;
    function IsOtherDead: Boolean;  // ��豾�F
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  form1.Caption := 'Snake Server';
  // Initialize colors
  Colors[1] := $6666ff;
  Colors[2] := $FF7979;
  Colors[3] := $DC35FF;
  Colors[4] := $94FF28;
  Colors[5] := $44FFFF;
  Colors[6] := $FFFF4D;
  Colors[7] := $B266FF;
  ImgFrontBuild;
  BtnStartBuild;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // �ھګ��U����V���s�D�����ʤ�V
  case Key of
    VK_Up: begin
      UDPC.Send(SerialNum + 'U'); // �V���A���ǰe 'U' �N���W
    end;
    VK_Down: begin
      UDPC.Send(SerialNum + 'D'); // �V���A���ǰe 'D' �N���U
    end;
    VK_Left: begin
      UDPC.Send(SerialNum + 'L'); // �V���A���ǰe 'L' �N����
    end;
    VK_Right: begin
      UDPC.Send(SerialNum + 'R'); // �V���A���ǰe 'R' �N���k
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  // �D�C��loop
  DrawGame;             // �e�C���e��

  // ����D�I��
  if IsOtherDead then begin
    UDPC.Send(SerialNum + 'Win');
  end;

  UpdateSnakePosition;  // ��s�D����m
end;

procedure TForm1.UDPSUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  str: string;
  length: integer;
  action: string;
  idx: integer;
  position: integer;
  Direction: Integer;
begin
  length := Adata.Size;
  Setlength(str, length);
  Adata.Read(str[1], length); // Ū�����
  action := copy(str, 2, length - 1);

  if action = 'U' then begin
    // ��s�ۤv���D��V
    if str[1] = SerialNum then snakeSelf.Direction := DirUp
    // ��s��誺�D��V
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
    idx := strtoint(copy(str, 5, 2));       // ���o��������
    position := strtoint(copy(str, 7, 3));  // ���o����X�y��
    Foods[idx].X := position;
    position := strtoint(copy(str, 10, 3)); // ���o����Y�y��
    Foods[idx].Y := position;

    if str[1] = SerialNum then begin
      Inc(ScoreSelf);                             // �W�[�ۤv������
      SnakeSelf.Length := SnakeSelf.Length + 1;   // �D�ܪ�
      if ScoreSelf mod 3 = 2 then begin           // �C3���ܭD�@��
        SnakeSelf.Radius := SnakeSelf.Radius + 1;
      end;
      SnakeSelf.Length := SnakeSelf.Length + 1;   // �W�[�D������
    end else begin
      Inc(ScoreOther);                            // �W�[��誺����
      SnakeOther.Length := SnakeOther.Length + 1; // �D�ܪ�
      if ScoreOther mod 3 = 2 then begin          // �C3���ܭD�@��
        SnakeOther.Radius := SnakeOther.Radius + 1;
      end;
      SnakeOther.Length := SnakeOther.Length + 1; // �W�[�D������
    end;
  end else if action = 'Start' then begin
    BtnStart.Free;  // �R���}�l���s
    ImgFront.Free;
    InitializeGame; // ��l�ƹC��
  end else if action = 'Invite' then begin
    if Application.MessageBox('You are invited to play game! ', 'Invitation',
    MB_OKCANCEL) = IDOK then
    begin
      UDPC.Send('0Invite');   // �����ܽ�
    end;
  end else if action = 'Serial' then begin
    SerialNum := str[1];      // �]�w�C���s��
    form1.Caption := 'Snake Server' + SerialNum;
  end else if copy(action, 1, 9) = 'Direction' then begin
    Direction := StrToInt(copy(action, 10, 1));
    // ��s�ۤv���D��V
    if Str[1] = SerialNum then SnakeSelf.Direction := TDirection(Direction)
    // ��s��誺�D��V
    else SnakeOther.Direction := TDirection(Direction);
  end else if action = 'Win' then begin
    Timer1.Enabled := False;  // �C���פ�
    if Str[1] = SerialNum then begin
      ShowMessage('You win! Final Score: ' + IntToStr(ScoreSelf));
    end else begin
      ShowMessage('You loss! Final Score: ' + IntToStr(ScoreSelf));
    end;
    ImgGame.Free;
    ImgFrontBuild;
  end else if action = 'Tie' then begin
    Timer1.Enabled := False;
    ShowMessage('It''s a tie! Final Score: ' + IntToStr(ScoreSelf));
    ImgGame.Free;
    ImgFrontBuild;
  end else if action = 'Leave' then begin
    Timer1.Enabled := False;
    if str[1] <> SerialNum then
      Application.MessageBox('You win!', 'Opposite Leave');
    ImgGame.Free;
    ImgFrontBuild;
  end else begin
    // �����쭹���ƾ�
    Adata.Position := 0;
    Adata.Read(Foods[1], FoodCount * SizeOf(TPoint));
    StartCountDown;           // �}�l�˼ƭp��
    form1.Timer1.Enabled := True;    // �ҥ� Timer ����
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if LabelWait <> nil then begin
    LabelWait.Free;  // �������
    LabelWait := nil;
  end;
  if ImgGame <> nil then begin
    ImgGame.Free;  // �������
    ImgGame := nil;
  end;
  if ImgFront <> nil then begin
    ImgFront.Free;  // �������
    ImgFront := nil;
  end;
  if Timer1.Enabled = true then
    UDPC.Send(SerialNum + 'Leave');
end;

procedure TForm1.InitializeGame;
begin
  ImgGameBuild;
  if LabelWait <> nil then
    LabelWait.Color := clWhite;
  
  ScoreSelf := 0;   // ��l�Ƥ���
  ScoreOther := 0;

  // �Ыؤ�����ܼ���
  ScoreLabel := TLabel.Create(form1);
  ScoreLabel.Parent := form1;
  ScoreLabel.Left := 10;
  ScoreLabel.Top := 10;
  ScoreLabel.Caption := 'Score: 0';

  // ��l�ƹC���e��
  Canvas1 := ImgGame.Picture.Bitmap.Canvas;
  ImgGame.Picture.Bitmap.Width := GameWidth;
  ImgGame.Picture.Bitmap.Height := GameHeight;
  DrawEdge;

  Randomize; // �H���ƺؤl

  // ��l�ƳD
  InitializeSnake(SerialNum);

  // �]�m Timer ����
  form1.Timer1.Interval := 100;   // �]�m�ɶ����j�� 100 �@��
  form1.Timer1.OnTimer := form1.Timer1Timer;    // ���p Timer �ƥ�B�z�{��
end;

// ��l�ƳD���ݩ�
procedure TForm1.InitializeSnake(Serial: String);
begin
  SnakeSelf.Length := 3;  // �D��l����
  SnakeSelf.Radius := 5;  // �D��l�b�|
  SnakeOther.Length := 3;
  SnakeOther.Radius := 5;

  if SerialNum = '1' then begin
    SnakeSelf.Body[1].X := 460;
    SnakeSelf.Body[1].Y := 260;

    SnakeOther.Body[1].X := 130;
    SnakeOther.Body[1].Y := 150;
  end else begin
    SnakeSelf.Body[1].X := 130;
    SnakeSelf.Body[1].Y := 150;

    SnakeOther.Body[1].X := 460;
    SnakeOther.Body[1].Y := 260;
  end;
end;

// �e���
procedure TForm1.DrawEdge;
begin
  ImgGame.Picture.Bitmap.Canvas.Pen.Color := clBlack;
  ImgGame.Picture.Bitmap.Canvas.Pen.Width := 1;
  Canvas1.Rectangle(0, 0, GameWidth, GameHeight);
end;

procedure TForm1.StartCountdown;
var
  i: integer;
begin
  LabelWaitBuild;
  LabelWait.Font.Size := 30;
  LabelWait.Caption := '3';
  for i := 3 downto 1 do begin
    LabelWait.Caption := IntToStr(i);
    Application.ProcessMessages;  // ��s�ɭ�
    Sleep(1000);                  // ����1��
  end;
  LabelWait.Visible := false;
end;

// �M���C���e��
procedure TForm1.ClearScreen;
var tc: TRect;
begin
  tc.Top := 0;
  tc.Left := 0;
  tc.Bottom := GameHeight;
  tc.Right := GameWidth;
  form1.ImgGame.Picture.Bitmap.Canvas.Brush.Color := $FFFFFF;
  form1.ImgGame.Picture.Bitmap.Canvas.FillRect(tc);
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
  DrawEdge;

  Canvas1.Brush.Color := clGreen;   // �]�m�D�����C��

  // �e�D
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
  WrapAround(SnakeSelf, GameWidth, GameHeight);
  EatFood(SnakeSelf);

   // �N�D���骺��m�V�e���ʤ@��
  for i := SnakeOther.Length downto 2 do
    SnakeOther.Body[i] := SnakeOther.Body[i - 1];

  UpdateSnakeHead(SnakeOther);
  WrapAround(SnakeOther, GameWidth, GameHeight);
end;

// ��s�D�Y��m
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
    Snake.Body[1].X := GameWidth;
  if (Snake.Body[1].X > GameWidth) then
    Snake.Body[1].X := 1;
  if (Snake.Body[1].Y < 1) then
    Snake.Body[1].Y := GameHeight;
  if (Snake.Body[1].Y > GameHeight) then
    Snake.Body[1].Y := 1;
end;

procedure TForm1.LabelWaitBuild;
begin
  if LabelWait = nil then begin
    LabelWait := TLabel.Create(form1);
    LabelWait.Parent := form1;
    LabelWait.Left := (GameWidth div 2) - 100;
    LabelWait.Top := (GameHeight div 2) - 25;
    LabelWait.Alignment := taCenter;
    LabelWait.Width := 200;
    LabelWait.Height := 50;
    LabelWait.AutoSize := false;
  end;
end;

procedure TForm1.ImgGameBuild;
begin
  if ImgGame = nil then begin
    ImgGame := TImage.Create(Form1);
    ImgGame.Parent := Form1;
    ImgGame.Width := GameWidth;
    ImgGame.Height := GameHeight;
  end;
end;

procedure TForm1.ImgFrontBuild;
var
  Path: String;
begin
  if ImgFront = nil then begin
    ImgFront := TImage.Create(Form1);
    ImgFront.Parent := Form1;
    ImgFront.Align := alClient;
    ImgFront.Stretch := True;
    Path := 'background.jpg';
    ImgFront.Picture.LoadFromFile(Path);
  end;
  if BtnStart = nil then
    BtnStartBuild;
end;

procedure TForm1.BtnStartBuild;
begin
  if BtnStart = nil then begin
    BtnStart := TButton.Create(Form1);
    BtnStart.Parent := Form1;
    BtnStart.Width := 75;
    BtnStart.Height := 25;
    BtnStart.Font.Size := 12;
    BtnStart.Left := (Form1.ClientWidth - BtnStart.Width) div 2;
    BtnStart.Top := (Form1.ClientHeight * 2) div 3;
    BtnStart.Caption := 'Start';
    BtnStart.OnClick := BtnStartClick;
  end;
end;

procedure TForm1.BtnStartClick(Sender: TObject);
begin
  ImgGameBuild;
  UDPC.Send('0Invite'); // �o�e�ܽ�
  LabelWaitBuild;          // �إߵ��ݤ�r
  LabelWait.Font.Size := 12;
  LabelWait.Caption := 'Waiting for the other player...';  // �]�w���Ҥ��e
end;

procedure TForm1.BtnLeaveClick(Sender: TObject);
begin
  // �C�����b�i��
  if Timer1.Enabled = true then begin
    UDPC.Send(SerialNum + 'Leave');
  end else begin
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

// �ˬd�D�Y�O�_�P�����I��
function TForm1.IsCollision(const Snake: TSnake;
  const Food: TPoint): Boolean;
var
  Distance: Double;
begin
  Distance := Sqrt(Sqr(Snake.Body[1].X - Food.X) +
                   Sqr(Snake.Body[1].Y - Food.Y));
  Result := Distance < (Snake.Radius + 4);
end;

function TForm1.IsOtherDead: Boolean;
var
  i: Integer;
  Radius: Integer;
begin
  Result := false;
  if (SnakeSelf.Body[1].X = SnakeOther.Body[1].X) and
     (SnakeSelf.Body[1].Y = SnakeOther.Body[1].Y) then
  begin
    if ScoreSelf > ScoreOther then
      Result := True
    else if ScoreSelf = ScoreOther then
      UDPC.Send('0Tie');
  end else begin
    Radius := SnakeOther.Radius + 1;
    for i := 1 to SnakeSelf.Length do begin
      if (SnakeSelf.Body[i].X >= SnakeOther.Body[1].X - SnakeOther.Radius) and
         (SnakeSelf.Body[i].X <= SnakeOther.Body[1].X + SnakeOther.Radius) and
         (SnakeSelf.Body[i].Y >= SnakeOther.Body[1].Y - SnakeOther.Radius) and
         (SnakeSelf.Body[i].Y <= SnakeOther.Body[1].Y + SnakeOther.Radius) then
      begin
        Result := True;
        break;
      end;
    end;
  end;
end;

end.