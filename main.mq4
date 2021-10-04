//main.mq4
//パイプでpyと接続→pyからの命令で実行を可能とするが、基本的には自動で行う

//+------------------------------------------------------------------+
//| 定義付け
//+------------------------------------------------------------------+
#property strict

input int LimitPositions = 3;
input double Lots = 0.01;
input int slippage = 1;

double Stoploss_Buy = 0;
double Stoploss_Sell = 0;
double Range_High = 111.222;
double Range_Low = 110.850;
double WidthRange = NormalizeDouble(Range_High - Range_Low,2);
int NowVolume = 0;
int NowPerRange = 0;
int LastTickPerRange = 0;
int NowTickPerRange = 0;

int HavePositions = 0;
int ea_ticket_res;
int Res;
int Select;
int pipe = INVALID_HANDLE;
int counter = 0;


const string pipeName = "TestPipe";     // パイプ名。外部プログラムで作成した名前に合わせる。

//+------------------------------------------------------------------+
// 関数
//+------------------------------------------------------------------+

int OnInit()
{
   // 名前付きパイプを開く（接続する）。
   pipe = FileOpen("\\\\.\\pipe\\" + pipeName, FILE_READ | FILE_WRITE | FILE_BIN | FILE_ANSI);

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   // パイプを閉じる。
   FileClose(pipe);
}

// ファイルから 1 行読み取る
inline string ReadLine(int file)
{
   string s;
   while (1)
   {
      string c = FileReadString(file, 1);
      s += c;
      if (c == "\n") break;
   } 
   
   return s;
}
/* 
//レンジ変更
double ChangeRange()
{
   Range_High ;
   Range_Low ;
   WidthRange = Range_High - Range_Low;

   return 0;
}

//現在価格のレンジ評価
double NowRangeAssess()
{
   if((iClose(Symbol(), PERIOD_M5, Close[0])-Range_High)>0) //上限を超えている場合
   {
      NowPerRange = NormalizeDouble((iClose(Symbol(), PERIOD_M5, Close[0])-Range_High) + WidthRange ,2)/WidthRange*0.01);
   }else{
      NowPerRange = NormalizeDouble((iClose(Symbol(), PERIOD_M5, Close[0])-Range_Low),2)/WidthRange*0.01);
   } 

   return 0;
} */

//決済ティック評価 
double ExitRangeAssess()
{
   double Tick_move1 = iClose(Symbol(), PERIOD_M5, 1);
   double Tick_move2 = iClose(Symbol(), PERIOD_M5, 2);

   NowTickPerRange = (Tick_move1 - Range_Low)/ (WidthRange*0.01);
   LastTickPerRange = (Tick_move2 - Range_Low)/ (WidthRange*0.01);
   Stoploss_Buy = NormalizeDouble(Range_Low - (WidthRange/5*0.1),3);
   Stoploss_Sell = NormalizeDouble(Range_High + (WidthRange/5*0.1),3);

   return 0;
}

//取引停止処理
double TradeingStop()
{
   if(NowTickPerRange<100 && NowTickPerRange>0)
   {
      NowVolume = 1;
   }else{
      NowVolume = 0;
   }

   return 0;
}

//自動注文
double PlzOrder()
{
   //オーダーから時間が経っている,ポジションが上限を超えていない,VOLUMEがOK
   if(counter == 0 && HavePositions <= LimitPositions && NowVolume == 1)
   {
      //買い注文
      if(NowTickPerRange > 20 && LastTickPerRange <= 20 )
      {
         ea_ticket_res = OrderSend(Symbol(), OP_BUY, Lots, Ask, slippage, Stoploss_Buy, 0, "buy", 100, 0, clrRed);
         // エラー処理
         if(ea_ticket_res == -1)
         {
            ea_ticket_res = OrderSend(Symbol(), OP_BUY, Lots, Ask, slippage, Stoploss_Buy, 0, "buy", 100, 0, clrRed);
            Print("BUY");
            counter=900;
         }else{
            Print("BUY");
            counter=900;
         }
         Alert(counter,"ok");
      }

      //売り注文
      if(NowTickPerRange <= 80 && LastTickPerRange >= 80 )
      {
         ea_ticket_res = OrderSend(Symbol(), OP_SELL, Lots, Bid, slippage, Stoploss_Sell, 0, "sell", 200, 0, clrBlue);
         // エラー処理
         if(ea_ticket_res == -1)
         {
            ea_ticket_res = OrderSend(Symbol(), OP_SELL, Lots, Bid, slippage, Stoploss_Sell, 0, "sell", 200, 0, clrBlue);
            Print("SELL");
            counter=900;
         }else{
            Print("SELL");
            counter=900;
         }
      }
   }

   return 0;
}

//自動決済
double Settlement()
{
   //買い決済
   if(NowTickPerRange > 80 && LastTickPerRange <= 80 )
   {
      for(int i = OrdersTotal()-1; i>=0; i--)
      {
         Select = OrderSelect(i,SELECT_BY_POS);
         if(Select == 0)
         {
            Select = OrderSelect(i,SELECT_BY_POS);
            Print("GET");
         }else{
            Print("GET");
         }
         if(OrderMagicNumber() == 100)
         {
            Res = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1, clrRed);
            if(Res == 0)
            {
               Res = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1, clrRed);
            }else{
               Print("BUY_BYEBYE");
            }
         }
      }
   }

   //売り決済
   if(NowTickPerRange < 20 && LastTickPerRange >= 20 )
   {
      for(int i = OrdersTotal()-1; i>=0; i--)
      {
         Select = OrderSelect(i,SELECT_BY_POS);
         if(Select == 0)
         {
            Select = OrderSelect(i,SELECT_BY_POS);
            Print("GET");
         }else{
            Print("GET");
         }
         if(OrderMagicNumber() == 200)
         {
            Res = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1, clrBlue);
            if(Res == 0)
            {
               Res = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1, clrBlue);
            }else{
               Print("SELL_BYEBYE");
            }
         }  
      }
   }

   //ロストカット
   if(LastTickPerRange > 110 ||  LastTickPerRange < -10) //上限又は下限を超えている場合
   {
      for(int i = OrdersTotal()-1; i>=0; i--)
      {
         Select = OrderSelect(i,SELECT_BY_POS);
         if(Select == 0)
         {
            Select = OrderSelect(i,SELECT_BY_POS);
            Print("GET");
         }else{
            Print("GET");
         }
         Res = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1, clrBlue);
         if(Res == 0)
         {
            Res = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 1, clrBlue);
            Print("ALL Settlement");
         }else{
            Print("ALL Settlement");
         }
      }
   }

   return 0;
}
//+------------------------------------------------------------------+
// メイン 処理
//+------------------------------------------------------------------+
void OnTick()
{

/*    
   // Bid 価格を文字列に変換
   string s = DoubleToString(Bid);

   // 文字列をパイプに書き込む
   FileWriteString(pipe,s+ "\r\n");
   
   // パイプから 1 行読み取って，ターミナルに表示
   Print(ReadLine(pipe));
    */
   //double NAssess_1 = NowRangeAssess();

   double EAssess_2 = ExitRangeAssess();
   double RangeCheck = TradeingStop();
   double PlzOrder_1 = PlzOrder();
   double Settlement_1 = Settlement();

   if(counter >= 1){ counter -= 1; }
   Sleep( 1000 );

}