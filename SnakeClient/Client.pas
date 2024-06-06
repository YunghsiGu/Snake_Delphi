unit Client;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdUDPServer, IdUDPBase, IdUDPClient,
  IdSocketHandle;

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
    Score: Integer;
    isInvited: Boolean;
    gameStarted: Boolean;
    procedure InitializeGame;
    procedure StartCountdown;
    procedure ClearScreen;
    procedure DrawGame;
    procedure DrawSnake(const Snake: TSnake);
    procedure UpdateSnakePosition;
    procedure UpdateSnakeHead(var Snake: TSnake);
    procedure WrapAround(var Snake: TSnake; Width, Height: Integer);
    procedure Label2Build;
    procedure PlaceFood;
    function IsCollisionWithFood(var Snake: TSnake): Boolean;
    function IsCollision(const Snake: TSnake; const Food: TPoint): Boolean;
    function IsCollisionWithSnake(const SnakeSelf, SnakeOther: TSnake): Boolean;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  form1.Caption := 'Snake Client';
  // Initialize colors
  Colors[1] := $6666ff;
  Colors[2] := $FF7979;
  Colors[3] := $DC35FF;
  Colors[4] := $94FF28;
  Colors[5] := $44FFFF;
  Colors[6] := $FFFF4D;
  Colors[7] := $B266FF;
end;
// 處理鍵盤按下事件
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // 根據按下的方向鍵更新蛇的移動方向
  case Key of
    VK_Up: begin
      SnakeSelf.Direction := DirUp;
      UDPC.Send('U');
    end;
    VK_Down: begin
      SnakeSelf.Direction := DirDown;
      UDPC.Send('D');
    end;
    VK_Left: begin
      SnakeSelf.Direction := DirLeft;
      UDPC.Send('L');
    end;
    VK_Right: begin
      SnakeSelf.Direction := DirRight;
      UDPC.Send('R');
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  if gameStarted then
  begin
    // Main game loop
    DrawGame;
    UpdateSnakePosition;

    // 雙方蛇碰撞
    if IsCollisionWithSnake(SnakeSelf, SnakeOther) then begin
      Timer1.Enabled := False;
      if SnakeSelf.Length > SnakeOther.Length then
        ShowMessage('你贏了! 最終得分: ' + IntToStr(Score))
      else if SnakeSelf.Length < SnakeOther.Length then
        ShowMessage('你輸了! 最終得分: ' + IntToStr(Score))
      else
        ShowMessage('平手! 最終得分: ' + IntToStr(Score));
    end;
  end;
end;


procedure TForm1.UDPSUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
  str: string;
  length: integer;
begin
  length := Adata.Size;
  Setlength(str, length);
  Adata.Read(str[1], length);
  if str = 'U' then begin
    snakeOther.Direction := DirUp;
  end else if str = 'D' then begin
    snakeOther.Direction := DirDown;
  end else if str = 'L' then begin
    snakeOther.Direction := DirLeft;
  end else if str = 'R' then begin
    snakeOther.Direction := DirRight;
  end else if str = 'Start' then begin
    StartCountDown;
    InitializeGame;
  end else if str = 'Invite' then begin
    isInvited := true;
    if Application.MessageBox('You are invited to play game! ', 'Invitation',
    MB_OKCANCEL) = IDOK then begin
      button1.Visible := false;
      UDPC.Send('Start');
      StartCountDown;
      InitializeGame;
    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if isInvited then
  begin
    button1.Visible := false;
    UDPC.Send('Start');
    StartCountdown;
    InitializeGame;
  end else begin
    Button1.Visible := False;
    UDPC.Send('Invite');
    Label2Build;
    Label2.Font.Size := 12;
    Label2.Caption := 'Waiting for the other player...';
  end;
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
  Score := 0;   // 初始化分數
  isInvited := false;
  gameStarted := false; // 初始化為 false

  // 創建分數顯示標籤
  ScoreLabel := TLabel.Create(form1);
  ScoreLabel.Parent := form1;
  ScoreLabel.Left := 10;
  ScoreLabel.Top := 10;
  ScoreLabel.Caption := 'Score: 0';

  // 初始化遊戲畫面
  Canvas1 := Image1.Picture.Bitmap.Canvas;
  Image1.Picture.Bitmap.Width := form1.image1.Width;
  Image1.Picture.Bitmap.Height := form1.image1.Height;

  Randomize; // 隨機化種子

  // 初始化蛇
  SnakeSelf.Length := 3;
  SnakeSelf.Radius := 5;
  SnakeSelf.Body[1].X := 130;
  SnakeSelf.Body[1].Y := 150;
  SnakeSelf.Direction := TDirection(Random(4));

  SnakeOther.Length := 3;
  SnakeOther.Radius := 5;
  SnakeOther.Body[1].X := 460;
  SnakeOther.Body[1].Y := 260;

  PlaceFood;  // 放置初始食物

  // 設置 Timer 控件
  form1.Timer1.Interval := 100;   // 設置時間間隔為 100 毫秒
  form1.Timer1.OnTimer := form1.Timer1Timer;    // 關聯 Timer 事件處理程序
  form1.Timer1.Enabled := True;    // 啟用 Timer 控件
  gameStarted := true; // 遊戲開始
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
    Application.ProcessMessages;  // 刷新界面
    Sleep(1000);
  end;
  label2.Visible := false;
end;

// 清除遊戲畫面
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

// 繪製遊戲畫面
procedure TForm1.DrawGame;
var
  i: Integer;
  idx: integer;
begin
  // 更新分數顯示
  if Assigned(ScoreLabel) then
    ScoreLabel.Caption := 'Score: ' + IntToStr(Score);
    
  ClearScreen;

  Canvas1.Brush.Color := clGreen;   // 設置蛇身體顏色

  DrawSnake(SnakeSelf);
  DrawSnake(SnakeOther);

  for i := 1 to FoodCount do begin
    idx := (i Mod 7) + 1;
    Canvas1.Brush.Color := colors[idx];   // 設置食物顏色
    Canvas1.Pen.Color := colors[idx];
    Canvas1.Ellipse(Foods[i].X - 3, Foods[i].Y - 3,
                    Foods[i].X + 3, Foods[i].Y + 3);   // 繪製食物
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
// 更新蛇的位置
procedure TForm1.UpdateSnakePosition;
var i: Integer;
begin
   // 將蛇身體的位置向前移動一格
  for i := SnakeSelf.Length downto 2 do
    SnakeSelf.Body[i] := SnakeSelf.Body[i - 1];

  UpdateSnakeHead(SnakeSelf);
  WrapAround(SnakeSelf, image1.Width, image1.Height);
  if isCollisionWithFood(SnakeSelf) then
    UDPC.Send('OtherEat');

   // 將蛇身體的位置向前移動一格
  for i := SnakeOther.Length downto 2 do
    SnakeOther.Body[i] := SnakeOther.Body[i - 1];

  UpdateSnakeHead(SnakeOther);
  WrapAround(SnakeOther, image1.Width, image1.Height);
  if isCollisionWithFood(SnakeOther) then
    UDPC.Send('SelfEat');
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

// 隨機放置食物
procedure TForm1.PlaceFood;
var
  i: Integer;
begin
  for i := 1 to FoodCount do
  begin
    Foods[i].X := Random(form1.image1.Width - 20) + 10;
    Foods[i].Y := Random(form1.image1.Height - 20) + 10;
  end;
  form1.UDPC.SendBuffer(Foods, FoodCount * SizeOf(TPoint));
end;

function TForm1.IsCollisionWithFood(var Snake: TSnake): Boolean;
var
  i: integer;
begin
  Result := false;
  for i := 1 to FoodCount do begin
    if IsCollision(Snake, Foods[i]) then begin
      Inc(Score);                       // 增加分數
      Snake.Length := Snake.Length + 1; // 蛇變長
      if Score mod 3 = 2 then begin     // 蛇變胖
        Snake.Radius := Snake.Radius + 1;
      end;
      // 放置新的食物
      Foods[i].X := Random(Width - 20) + 10;
      Foods[i].Y := Random(Height - 20) + 10;
      UDPC.SendBuffer(Foods, FoodCount * SizeOf(TPoint));
      Result := true;
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

function TForm1.IsCollisionWithSnake(const SnakeSelf,
  SnakeOther: TSnake): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to SnakeSelf.Length do
  begin
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

end.
