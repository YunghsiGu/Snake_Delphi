unit Client;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IdBaseComponent, IdComponent, IdTCPServer,
  IdUDPClient, IdUDPBase, IdUDPServer, IdSocketHandle, JPEG;

const
  SnakeMaxLength = 110; // �D���̤j����
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
    Score: Integer;
    Color: TColor;
  end;

  // ���쪺�覡
  TCollisionWay = (None, HeadToHead, HeadToBody);

  TForm1 = class(TForm)
    Timer1: TTimer;
    UDPS: TIdUDPServer;
    UDPC: TIdUDPClient;
    ColorDialog1: TColorDialog;
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure UDPSUDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
    procedure FormDestroy(Sender: TObject);
  private
    SnakeSelf: TSnake;    // �ۤv���D
    SnakeOther: TSnake;   // ��誺�D
    LabelWait: TLabel;
    LabelSnake: TLabel;   // �C���W��
    ScoreLabel: TLabel;
    ImgGame: TImage;      // �D���e��
    ImgLogo: TImage;
    PanelFront: TPanel;   // ��������
    PanelLeft: TPanel;    // �����������
    PanelSkin: TPanel;    // �ֽ��C��
    BtnStart: TButton;    // �}�l
    BtnSkin: TButton;     // �󴫥ֽ�
    Canvas1: TCanvas;
    Foods: array[1..FoodCount] of TPoint;
    Colors: array[1..7] of TColor;  // �������C��
    SerialNum: String;    // �s��
    procedure InitializeGame; // �C����l��
    procedure InitializeSnake(Serial: String);  // �D����l��
    procedure DrawEdge;       // �e�C�����
    procedure StartCountdown; // �˼ƭp��
    procedure ClearScreen;    // �M���e��
    procedure DrawGame;       // �e�C���e��
    procedure DrawSnake(const Snake: TSnake); // �e�D
    procedure UpdateSnakePosition;  // ��s�D���ʫ᪺��m
    procedure UpdateScoreLabel;     // ��s����
    procedure UpdateSnakeHead(var Snake: TSnake); // ��s�D�Y��V
    procedure WrapAround(var Snake: TSnake; Width, Height: Integer);  // �D�Y
    procedure LabelWaitBuild;   // ���ݹ��
    procedure LabelSnakeBuild;
    procedure LabelScoreBuild;  // ����
    procedure ImgGameBuild;
    procedure ImgLogoBuild;
    procedure PanelFrontBuild;  // ��������
    procedure PanelLeftBuild;   // �����������
    procedure PanelSkinBuild;   // �D���C��
    procedure FrontPageBuild;   // �إ߭���
    procedure GamePageBuild;    // �إ߹C������
    procedure BtnStartBuild;    // �}�l���s
    procedure BtnSkinBuild;     // �󴫥ֽ�
    procedure BtnSkinClick(Sender: TObject);
    procedure BtnStartClick(Sender: TObject);
    procedure GetBigger(var Snake: TSnake);   // �D�ܤj��
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
  SnakeSelf.Color := clWhite;
  // Initialize colors
  Colors[1] := $6666ff;
  Colors[2] := $FF7979;
  Colors[3] := $DC35FF;
  Colors[4] := $94FF28;
  Colors[5] := $44FFFF;
  Colors[6] := $FFFF4D;
  Colors[7] := $B266FF;
  FrontPageBuild;
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

    if str[1] = SerialNum then
      GetBigger(SnakeSelf)
    else
      GetBigger(SnakeOther);
    UpdateScoreLabel;
    if SnakeSelf.Score >= 100 then
      UDPC.Send(SerialNum + 'Win');
  end else if action = 'Start' then begin
    // ���C��
    UDPC.Send(SerialNum + 'Color' +
              Format('%.8d', [SnakeSelf.Color]));
    InitializeGame; // ��l�ƹC��
  end else if action = 'Invite' then begin
    if Application.MessageBox('You are invited to play game! ', 'Invitation',
    MB_OKCANCEL) = IDOK then
    begin
      GamePageBuild;
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
    FrontPageBuild;
    if Str[1] = SerialNum then begin
      ShowMessage('You win! Final Score: ' + IntToStr(SnakeSelf.Score));
    end else begin
      ShowMessage('You loss! Final Score: ' + IntToStr(SnakeSelf.Score));
    end;
  end else if action = 'Tie' then begin
    Timer1.Enabled := False;
    FrontPageBuild;
    ShowMessage('It''s a tie! Final Score: ' + IntToStr(SnakeSelf.Score));
  end else if action = 'Leave' then begin
    Timer1.Enabled := False;
    if str[1] <> SerialNum then begin
      Application.MessageBox('You win!', 'Opposite Leave');
      FrontPageBuild;
    end;
  end else if copy(action, 1, 5) = 'Color' then begin
    if str[1] <> SerialNum then
      SnakeOther.Color := StrToInt(copy(action, 6, 8));
  end else begin
    // �����쭹���ƾ�
    Adata.Position := 0;
    Adata.Read(Foods[1], FoodCount * SizeOf(TPoint));
    StartCountDown;               // �}�l�˼ƭp��
    form1.Timer1.Enabled := True; // �ҥ� Timer ����
    if BtnStart <> nil then begin
      BtnStart.Free;
      BtnStart := nil;
    end;
    if PanelFront <> nil then begin
      PanelFront.Free;
      PanelFront := nil;
    end;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if ImgGame <> nil then
    UDPC.Send(SerialNum + 'Leave');
  if LabelWait <> nil then begin
    LabelWait.Free; // �������
    LabelWait := nil;
  end;
  if ImgGame <> nil then begin
    ImgGame.Free;   // ����Ϥ�
    ImgGame := nil;
  end;
  if PanelLeft <> nil then begin
    PanelLeft.Free;
    PanelLeft := nil;
  end;
  if PanelSkin <> nil then begin
    PanelSkin.Free;
    PanelSkin := nil;
  end;
  if BtnStart <> nil then begin
    BtnStart.Free;
    BtnStart := nil;
  end;
  if BtnSkin <> nil then begin
    BtnSkin.Free;
    BtnSkin := nil;
  end;
  if ScoreLabel <> nil then begin
    ScoreLabel.Free;
    ScoreLabel := nil;
  end;
  if PanelFront <> nil then begin
    PanelFront.Free;
    PanelFront := nil;
  end;
end;

procedure TForm1.InitializeGame;
begin
  if ImgGame = nil then ImgGameBuild;
  if LabelWait <> nil then
    LabelWait.Color := clWhite;
  SnakeSelf.Score := 0;   // ��l�Ƥ���
  SnakeOther.Score := 0;

  // ������ܼ���
  ScoreLabel.Color := clWhite;

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
  if LabelWait = nil then
    LabelWaitBuild;
  LabelWait.Font.Size := 30;
  LabelWait.Caption := '3';
  for i := 3 downto 1 do begin
    LabelWait.Caption := IntToStr(i);
    Application.ProcessMessages;  // ��s�ɭ�
    Sleep(1000);                  // ����1��
  end;
  LabelWait.Free;
  LabelWait := nil;
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

  // �e�D
  Canvas1.Brush.Color := SnakeSelf.Color;   // �]�m�D�����C��
  DrawSnake(SnakeSelf);
  Canvas1.Brush.Color := SnakeOther.Color;
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

procedure TForm1.UpdateScoreLabel;
begin
  if SnakeSelf.Score >= SnakeOther.Score then begin
    ScoreLabel.Caption := 'Score: ' + #13#10 +
                          '1st You: ' + IntToStr(SnakeSelf.Score) + #13#10 +
                          '2nd Player: ' + IntToStr(SnakeOther.Score);
  end else begin
    ScoreLabel.Caption := 'Score: ' + #13#10 +
                          '1st Player: ' + IntToStr(SnakeOther.Score) + #13#10 +
                          '2nd You: ' + IntToStr(SnakeSelf.Score);
  end;
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
    LabelWait.Font.Color := clBlack;
  end;
end;

procedure TForm1.LabelScoreBuild;
begin
  if ScoreLabel = nil then begin
    ScoreLabel := TLabel.Create(form1);
    ScoreLabel.Parent := form1;
    ScoreLabel.Left := 10;
    ScoreLabel.Top := 10;
    ScoreLabel.Font.Size := 12;
    ScoreLabel.Font.Name := 'Consolas';
  end;
end;

procedure TForm1.LabelSnakeBuild;
begin
  if LabelSnake = nil then begin
    LabelSnake := TLabel.Create(form1);
    LabelSnake.Parent := PanelFront;
    LabelSnake.Left := 31;
    LabelSnake.Top := 16;
    LabelSnake.Width := 177;
    LabelSnake.Height := 85;
    LabelSnake.Color := clGreen;
    LabelSnake.Font.Color := clWhite;
    LabelSnake.Font.Size := 48;
    LabelSnake.Font.Name := 'MV Boli';
    LabelSnake.Font.Style := [fsBold];
    LabelSnake.Caption := 'Snake';
    LabelSnake.AutoSize := false;
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

procedure TForm1.ImgLogoBuild;
begin
  if ImgLogo = nil then begin
    ImgLogo := TImage.Create(Form1);
    ImgLogo.Parent := PanelFront;
    ImgLogo.Width := 177;
    ImgLogo.Height := 153;
    ImgLogo.Left := 31;
    ImgLogo.Top := 112;
    ImgLogo.Picture.LoadFromFile('Logo.jpg');
    ImgLogo.Stretch := True;
  end;
end;

procedure TForm1.PanelFrontBuild;
begin
  if PanelFront = nil then begin
    PanelFront := TPanel.Create(Form1);
    PanelFront.Parent := Form1;
    PanelFront.Align := alClient;
    PanelFront.Color := $b1efa4;
  end;
end;

procedure TForm1.PanelLeftBuild;
begin
  if PanelLeft = nil then begin
    PanelLeft := TPanel.Create(Form1);
    PanelLeft.Parent := Form1;
    PanelLeft.Align := alLeft;
    PanelLeft.Width := 153;
    PanelLeft.Color := $00408000;
  end;
end;

procedure TForm1.PanelSkinBuild;
begin
  if PanelSkin = nil then begin
    PanelSkin := TPanel.Create(Form1);
    PanelSkin.Parent := Form1;
    PanelSkin.Top := 16;
    PanelSkin.Left := 8;
    PanelSkin.Width := 137;
    PanelSkin.Height := 37;
    PanelSkin.Color := SnakeSelf.Color;
  end;
end;

procedure TForm1.FrontPageBuild;
begin
  if ImgGame <> nil then begin
    ImgGame.Free;
    ImgGame := nil;
  end;
  if ScoreLabel <> nil then begin
    ScoreLabel.Free;
    ScoreLabel := nil;
  end;
  if PanelFront = nil then PanelFrontBuild;
  if PanelLeft = nil then PanelLeftBuild;
  if PanelSkin = nil then PanelSkinBuild;
  if BtnStart = nil then BtnStartBuild;
  if BtnSkin = nil then BtnSkinBuild;
  if LabelSnake = nil then LabelSnakeBuild;
  if ImgLogo = nil then ImgLogoBuild;
end;

procedure TForm1.GamePageBuild;
begin
  BtnStart.Visible := false;
  if LabelSnake <> nil then begin
    LabelSnake.Free;
    LabelSnake := nil;
  end;
  if ImgLogo <> nil then begin
    ImgLogo.Free;
    ImgLogo := nil;
  end;
  PanelFront.Visible := false;
  if PanelLeft <> nil then begin
    PanelLeft.Free;
    PanelLeft := nil;
  end;
  if PanelSkin <> nil then begin
    PanelSkin.Free;
    PanelSkin := nil;
  end;
  if BtnSkin <> nil then begin
    BtnSkin.Free;
    BtnSkin := nil;
  end;
  if ImgGame = nil then ImgGameBuild;
  if ScoreLabel = nil then LabelScoreBuild;
  if LabelWait = nil then LabelWaitBuild;
end;

procedure TForm1.BtnStartBuild;
begin
  if BtnStart = nil then begin
    BtnStart := TButton.Create(Form1);
    BtnStart.Parent := PanelFront;
    BtnStart.Width := 177;
    BtnStart.Height := 73;
    BtnStart.Font.Size := 24;
    BtnStart.Left := 31;
    BtnStart.Top := 272;
    BtnStart.Caption := 'Start';
    BtnStart.Font.Name := 'MS Serif';
    BtnStart.Font.Style := [fsBold];
    BtnStart.OnClick := BtnStartClick;
    BtnStart.Visible := True;
  end;
end;

procedure TForm1.BtnSkinBuild;
begin
  if BtnSkin = nil then begin
    BtnSkin := TButton.Create(Form1);
    BtnSkin.Parent := Form1;
    BtnSkin.Top := 64;
    BtnSkin.Left := 8;
    BtnSkin.Width := 137;
    BtnSkin.Height := 37;
    BtnSkin.Font.Size := 17;
    BtnSkin.Font.Name := 'MV Boli';
    BtnSkin.Font.Style := [fsBold];
    BtnSkin.Caption := 'Skin';
    BtnSkin.OnClick := BtnSkinClick;
  end;
end;

procedure TForm1.BtnSkinClick(Sender: TObject);
begin
  if ColorDialog1.Execute then begin
    PanelSkin.Color := ColorDialog1.Color;
    SnakeSelf.Color := ColorDialog1.Color;
  end;
end;

procedure TForm1.BtnStartClick(Sender: TObject);
begin
  GamePageBuild;
  UDPC.Send('0Invite'); // �o�e�ܽ�
  LabelWait.Font.Size := 12;
  LabelWait.Caption := 'Waiting for the other player...';  // �]�w���Ҥ��e
end;

procedure TForm1.GetBigger(var Snake: TSnake);
begin
  Inc(Snake.Score);                   // �W�[����
  Inc(Snake.Length);                  // �D�ܪ�
  if Snake.Score mod 3 = 2 then begin // �C3���ܭD�@��
    Inc(Snake.Radius);
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
begin
  Result := false;
  if (SnakeSelf.Body[1].X = SnakeOther.Body[1].X) and
     (SnakeSelf.Body[1].Y = SnakeOther.Body[1].Y) then
  begin
    if SnakeSelf.Score > SnakeOther.Score then
      Result := True
    else if SnakeSelf.Score = SnakeOther.Score then
      UDPC.Send('0Tie');
  end else begin
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