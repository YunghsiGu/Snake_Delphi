unit Server;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdUDPServer, IdUDPBase, IdUDPClient,
  IdSocketHandle;

const
  SnakeMaxLength = 100; // 蛇的最大長度
  SnakeNum = 2;         // 蛇的數量
  FoodCount = 30;       // 食物的數量
  GameWidth = 570;      // 遊戲寬度
  GameHeight = 370;     // 遊戲高度

type
  // 座標定義
  TPoint = record
    X, Y: Integer;
  end;

  TForm1 = class(TForm)
    UDPS: TIdUDPServer;   // UDP伺服器1
    UDPC: TIdUDPClient;   // UDP客戶端1
    UDPS2: TIdUDPServer;  // UDP伺服器2
    UDPC2: TIdUDPClient;  // UDP客戶端2
    procedure FormCreate(Sender: TObject);  // 程式啟動
    procedure UDPSUDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
    procedure UDPS2UDPRead(Sender: TObject; AData: TStream;
      ABinding: TIdSocketHandle);
  private
    Foods: array[1..FoodCount] of TPoint; // 食物的array
    Invite: Array[1..2] of Boolean;       // 邀請狀態
    procedure PlaceFood;                  // 放置食物的方法
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  form1.Caption := 'Snake Server';  // 設定標題
  Randomize; // 隨機化種子
end;

// UDP伺服器1讀取
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

  length := Adata.Size;               // 獲取數據長度
  Setlength(str, length);             // 設置字串長度
  Adata.Read(str[1], length);         // 讀取數據到字串
  action := copy(str, 2, length - 1); // 獲取動作
  if action = 'Invite' then begin     // 如果是邀請
    for i := 1 to SnakeNum do begin
      if invite[i] = false then begin
        invite[i] := true;            // 標記為已邀請
        UDPC.Send(IntToStr(i) + 'Serial');  // 發送編號
        if i <> SnakeNum then begin
          isStarting := false;
          UDPC2.Send(str);            // 發送邀請給另一個客戶端
          break;
        end;
      end;
    end;
    if isStarting then begin                // 如果遊戲即將開始
      Direction := IntToStr(Random(4));     // 隨機方向
      UDPC.Send('1Direction' + Direction);  // 發送方向給客戶端1
      UDPC2.Send('1Direction' + Direction); // 發送方向給客戶端2

      Direction := IntToStr(Random(4));     // 隨機方向
      UDPC.Send('2Direction' + Direction);  // 發送方向給客戶端1
      UDPC2.Send('2Direction' + Direction); // 發送方向給客戶端2
      
      UDPC.Send('0Start');  // 發送開始指令給客戶端1
      UDPC2.Send('0Start'); // 發送開始指令給客戶端2
      for i := 1 to SnakeNum do begin
        Invite[i] := false; // 重置邀請狀態
      end;
      Sleep(1500);
      PlaceFood;  // 放置食物
    end;
  end else if copy(action, 1, 3) = 'Eat' then begin // 吃
    i := strtoint(copy(str, 5, 2));                 // 獲取食物的索引
    Foods[i].X := Random(GameWidth - 20) + 10;      // 隨機生成食物的X座標
    Foods[i].Y := Random(GameHeight - 20) + 10;     // 隨機生成食物的Y座標
    UDPC.Send(str + Format('%.3d', [Foods[i].X]) +  // 發送新食物位置給客戶端1
                    Format('%.3d', [Foods[i].Y]));
    UDPC2.Send(str + Format('%.3d', [Foods[i].X]) + // 發送新食物位置給客戶端2
                     Format('%.3d', [Foods[i].Y]));
  end else begin
    UDPC.Send(str);   // 轉發數據給客戶端1
    UDPC2.Send(str);  // 轉發數據給客戶端2
  end;
end;

// UDP伺服器2讀取
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
    // 平手則什麼都不做
  end else begin
    UDPC.Send(str);
    UDPC2.Send(str);
  end;
end;

// 隨機放置食物
procedure TForm1.PlaceFood;
var
  i: Integer;
begin
  for i := 1 to FoodCount do begin
    Foods[i].X := Random(GameWidth - 20) + 10;  // 隨機生成食物的X座標
    Foods[i].Y := Random(GameHeight - 20) + 10; // 隨機生成食物的Y座標
  end;
  UDPC.SendBuffer(Foods, FoodCount * SizeOf(TPoint));   // 發送食物數據給客戶端1
  UDPC2.SendBuffer(Foods, FoodCount * SizeOf(TPoint));  // 發送食物數據給客戶端2
end;

end.
