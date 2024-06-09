unit Client;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IdBaseComponent, IdComponent, IdTCPServer,
  IdUDPClient, IdUDPBase, IdUDPServer, IdSocketHandle, JPEG;

const
  SnakeMaxLength = 100; // 蛇的最大長度
  FoodCount = 30;       // 食物數量
  GameWidth = 570;      // 遊戲寬度
  GameHeight = 370;     // 遊戲高度

type
  TDirection = (DirUp, DirDown, DirLeft, DirRight); // 定義方向

  TPoint = record // 定義座標
    X, Y: Integer;
  end;

  TSnake = record // 定義蛇
    Length: Integer;
    Radius: Integer;
    Body: array[1..SnakeMaxLength] of TPoint;
    Direction: TDirection;
  end;

  // 撞到的方式
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
    SnakeSelf: TSnake;    // 自己的蛇
    SnakeOther: TSnake;   // 對方的蛇
    LabelWait: TLabel;    // 等待文字
    ImgGame: TImage;      // 蛇的畫面
    ImgFront: TImage;     // 首頁
    BtnStart: TButton;    // 開始
    Canvas1: TCanvas;
    Foods: array[1..FoodCount] of TPoint;
    Colors: array[1..7] of TColor;  // 食物的顏色
    ScoreSelf: Integer;   // 自己的分數
    ScoreOther: Integer;  // 對方的分數
    SerialNum: String;    // 編號
    procedure InitializeGame; // 遊戲初始化
    procedure InitializeSnake(Serial: String);  // 蛇的初始化
    procedure DrawEdge;       // 畫遊戲邊框
    procedure StartCountdown; // 倒數計時
    procedure ClearScreen;    // 清除畫面
    procedure DrawGame;       // 畫遊戲畫面
    procedure DrawSnake(const Snake: TSnake); // 畫蛇
    procedure UpdateSnakePosition;  // 更新蛇移動後的位置
    procedure UpdateSnakeHead(var Snake: TSnake); // 更新蛇頭方向
    procedure WrapAround(var Snake: TSnake; Width, Height: Integer);  // 蛇頭
    procedure LabelWaitBuild; // 等待對手
    procedure ImgGameBuild;
    procedure ImgFrontBuild;  // 首頁圖片
    procedure BtnStartBuild;  // 開始按鈕
    procedure BtnStartClick(Sender: TObject);
    procedure BtnLeaveClick(Sender: TObject);
    procedure EatFood(var Snake: TSnake); // 吃到食物
    function IsCollision(const Snake: TSnake; const Food: TPoint): Boolean;
    function IsOtherDead: Boolean;  // 對方掛了
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
  // 根據按下的方向鍵更新蛇的移動方向
  case Key of
    VK_Up: begin
      UDPC.Send(SerialNum + 'U'); // 向伺服器傳送 'U' 代表上
    end;
    VK_Down: begin
      UDPC.Send(SerialNum + 'D'); // 向伺服器傳送 'D' 代表下
    end;
    VK_Left: begin
      UDPC.Send(SerialNum + 'L'); // 向伺服器傳送 'L' 代表左
    end;
    VK_Right: begin
      UDPC.Send(SerialNum + 'R'); // 向伺服器傳送 'R' 代表右
    end;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  // 主遊戲loop
  DrawGame;             // 畫遊戲畫面

  // 雙方蛇碰撞
  if IsOtherDead then begin
    UDPC.Send(SerialNum + 'Win');
  end;

  UpdateSnakePosition;  // 更新蛇的位置
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
  Adata.Read(str[1], length); // 讀取資料
  action := copy(str, 2, length - 1);

  if action = 'U' then begin
    // 更新自己的蛇方向
    if str[1] = SerialNum then snakeSelf.Direction := DirUp
    // 更新對方的蛇方向
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
    idx := strtoint(copy(str, 5, 2));       // 取得食物索引
    position := strtoint(copy(str, 7, 3));  // 取得食物X座標
    Foods[idx].X := position;
    position := strtoint(copy(str, 10, 3)); // 取得食物Y座標
    Foods[idx].Y := position;

    if str[1] = SerialNum then begin
      Inc(ScoreSelf);                             // 增加自己的分數
      SnakeSelf.Length := SnakeSelf.Length + 1;   // 蛇變長
      if ScoreSelf mod 3 = 2 then begin           // 每3分變胖一次
        SnakeSelf.Radius := SnakeSelf.Radius + 1;
      end;
      SnakeSelf.Length := SnakeSelf.Length + 1;   // 增加蛇的長度
    end else begin
      Inc(ScoreOther);                            // 增加對方的分數
      SnakeOther.Length := SnakeOther.Length + 1; // 蛇變長
      if ScoreOther mod 3 = 2 then begin          // 每3分變胖一次
        SnakeOther.Radius := SnakeOther.Radius + 1;
      end;
      SnakeOther.Length := SnakeOther.Length + 1; // 增加蛇的長度
    end;
  end else if action = 'Start' then begin
    BtnStart.Free;  // 刪除開始按鈕
    ImgFront.Free;
    InitializeGame; // 初始化遊戲
  end else if action = 'Invite' then begin
    if Application.MessageBox('You are invited to play game! ', 'Invitation',
    MB_OKCANCEL) = IDOK then
    begin
      UDPC.Send('0Invite');   // 接受邀請
    end;
  end else if action = 'Serial' then begin
    SerialNum := str[1];      // 設定遊戲編號
    form1.Caption := 'Snake Server' + SerialNum;
  end else if copy(action, 1, 9) = 'Direction' then begin
    Direction := StrToInt(copy(action, 10, 1));
    // 更新自己的蛇方向
    if Str[1] = SerialNum then SnakeSelf.Direction := TDirection(Direction)
    // 更新對方的蛇方向
    else SnakeOther.Direction := TDirection(Direction);
  end else if action = 'Win' then begin
    Timer1.Enabled := False;  // 遊戲終止
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
    // 接收到食物數據
    Adata.Position := 0;
    Adata.Read(Foods[1], FoodCount * SizeOf(TPoint));
    StartCountDown;           // 開始倒數計時
    form1.Timer1.Enabled := True;    // 啟用 Timer 控件
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  if LabelWait <> nil then begin
    LabelWait.Free;  // 釋放標籤
    LabelWait := nil;
  end;
  if ImgGame <> nil then begin
    ImgGame.Free;  // 釋放標籤
    ImgGame := nil;
  end;
  if ImgFront <> nil then begin
    ImgFront.Free;  // 釋放標籤
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
  
  ScoreSelf := 0;   // 初始化分數
  ScoreOther := 0;

  // 創建分數顯示標籤
  ScoreLabel := TLabel.Create(form1);
  ScoreLabel.Parent := form1;
  ScoreLabel.Left := 10;
  ScoreLabel.Top := 10;
  ScoreLabel.Caption := 'Score: 0';

  // 初始化遊戲畫面
  Canvas1 := ImgGame.Picture.Bitmap.Canvas;
  ImgGame.Picture.Bitmap.Width := GameWidth;
  ImgGame.Picture.Bitmap.Height := GameHeight;
  DrawEdge;

  Randomize; // 隨機化種子

  // 初始化蛇
  InitializeSnake(SerialNum);

  // 設置 Timer 物件
  form1.Timer1.Interval := 100;   // 設置時間間隔為 100 毫秒
  form1.Timer1.OnTimer := form1.Timer1Timer;    // 關聯 Timer 事件處理程序
end;

// 初始化蛇的屬性
procedure TForm1.InitializeSnake(Serial: String);
begin
  SnakeSelf.Length := 3;  // 蛇初始長度
  SnakeSelf.Radius := 5;  // 蛇初始半徑
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

// 畫邊框
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
    Application.ProcessMessages;  // 刷新界面
    Sleep(1000);                  // 等待1秒
  end;
  LabelWait.Visible := false;
end;

// 清除遊戲畫面
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

// 繪製遊戲畫面
procedure TForm1.DrawGame;
var
  i: Integer;
  idx: integer;
begin
  // 更新分數顯示
  if Assigned(ScoreLabel) then
    //ScoreLabel.Caption := 'Score: ' + IntToStr(Score);
    
  ClearScreen;
  DrawEdge;

  Canvas1.Brush.Color := clGreen;   // 設置蛇身體顏色

  // 畫蛇
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
  WrapAround(SnakeSelf, GameWidth, GameHeight);
  EatFood(SnakeSelf);

   // 將蛇身體的位置向前移動一格
  for i := SnakeOther.Length downto 2 do
    SnakeOther.Body[i] := SnakeOther.Body[i - 1];

  UpdateSnakeHead(SnakeOther);
  WrapAround(SnakeOther, GameWidth, GameHeight);
end;

// 更新蛇頭位置
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
  UDPC.Send('0Invite'); // 發送邀請
  LabelWaitBuild;          // 建立等待文字
  LabelWait.Font.Size := 12;
  LabelWait.Caption := 'Waiting for the other player...';  // 設定標籤內容
end;

procedure TForm1.BtnLeaveClick(Sender: TObject);
begin
  // 遊戲正在進行
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

// 檢查蛇頭是否與食物碰撞
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
