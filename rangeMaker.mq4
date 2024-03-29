//+------------------------------------------------------------------+
//|                                                   rangeMaker.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
input double Lots = 0.01;
input int slippage = 10;
int ea_ticket_res = 0;// チケットNo
int res;

double orderPrice;
double closePrice;
double limit_rate;
double stop_rate;

double count = 0;
double wincount = 0;
double countPrifit = 0;

bool buyReady = false;
bool sellReady = false;
bool buyFlag = false;
bool sellFlag = false;

int OnInit()
  {
   //勝率オブジェクト作成
    ObjectCreate("obj_judgeMonitor",OBJ_LABEL,0,0,0);//勝率計算のオブジェクト作成
    ObjectSet("obj_judgeMonitor",OBJPROP_CORNER,CORNER_LEFT_UPPER);//左上に表示
    ObjectSet("obj_judgeMonitor",OBJPROP_XDISTANCE,10);//X軸サイズ10
    ObjectSet("obj_judgeMonitor",OBJPROP_YDISTANCE,20);//Y軸サイズ20
    ObjectSetText("obj_judgeMonitor", "判定："+"0"+" 勝ち："+"0"+" 勝率："+"0%", 11, "メイリオ", clrWhite);//勝率の表示
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   
   //注文判定用
   double ema5 = iMA(NULL, 0, 5, 0, 1, 0, 1);
   double ema25 = iMA(NULL, 0, 25, 0, 1, 0, 1);
   double ema50 = iMA(NULL, 0, 50, 0, 1, 0, 1);
   double ema200 = iMA(NULL, 0, 200, 0, 1, 0, 1);
   
   double ema5Judge = iMA(NULL, 0, 5, 0, 1, 0, 2);
   double ema25Judge = iMA(NULL, 0, 25, 0, 1, 0, 2);
   
   //売却判定用
   double ema50Judge = iMA(NULL, 0, 50, 0, 1, 0, 2);
   
   //買うエントリーの準備を行う
   if (ema5<ema25 && ema25<ema50 && ema50<ema200) {
      buyReady = true;
   }
   
   //売るエントリーの準備を行う
   if (ema5>ema25 && ema25>ema50 && ema50>ema200) {
      sellReady = true;
   }
   
   if (ea_ticket_res == 0) {
      //買い成行
      if (buyReady) {
         if (ema5Judge<ema25Judge && ema5>ema25 && (High[1]-Low[1])<0.2){
            
            limit_rate = 0;
            for (int i=1; i<=12; i++){
               if (limit_rate<iLow(Symbol(), 0, i)){
                  limit_rate = iLow(Symbol(), 0, i);
               }
            }
         
         stop_rate  = Ask - ( Ask-limit_rate>1?0.05:Ask-limit_rate);
         limit_rate = Ask + ( Ask-limit_rate>1?0.05:Ask-limit_rate);
         
            ea_ticket_res = OrderSend(Symbol(), OP_BUY, 0.01, Ask, slippage, stop_rate, limit_rate, "buy", 100, 0, clrRed);
            orderPrice = Ask;
            printf("buy BUY");
            buyReady = false;
            buyFlag = true;
            count++;
         }
      }
      
      //売り成行
      if (sellReady) {
         if (ema5Judge>ema25Judge && ema5<ema25 && (High[1]-Low[1])<0.2){
         
            limit_rate = 0;
            for (i=1; i<=12; i++){
               if (limit_rate<iHigh(Symbol(), 0, i)){
                  limit_rate = iHigh(Symbol(), 0, i);
               }
            }
      
         stop_rate  = Bid + ( MathAbs(limit_rate - Bid)>1?0.05:MathAbs(limit_rate - Bid));
         limit_rate = Bid - ( MathAbs(limit_rate - Bid)>1?0.05:MathAbs(limit_rate - Bid));
            ea_ticket_res = OrderSend(Symbol(), OP_SELL, 0.01, Bid, slippage, stop_rate, limit_rate, "buy", 100, 0, clrRed);
            orderPrice = Bid;
            printf("sell BUY");
            sellReady = false;
            sellFlag = true;
            count++;
         }
      }
   }
 
   //買い決済注文
   if (buyFlag) {
      if (ema25Judge<ema50Judge && ema25>ema50 && (High[1]-Low[1])<0.2) {
         res = OrderClose(ea_ticket_res, 0.01, Bid, 1, clrRed);
         closePrice=Bid;
         printf("buyOrder SELL");
         buyFlag = false; 
         
         if (orderPrice<closePrice) {
            printf((string)ea_ticket_res+" O:"+(string)orderPrice+" C:"+(string)closePrice);
            countPrifit += closePrice-orderPrice;
            wincount++;
         }
         
         ea_ticket_res = 0;
         ObjectSetText("obj_judgeMonitor", "判定："+(string)count+" 勝ち："+(string)wincount+" 勝率："+(string)(NormalizeDouble(wincount/count*100,0))+"%"+"  利益"+(string)(countPrifit*100), 11, "メイリオ", clrWhite);//勝率の表示
         printf((wincount/count*100));
      } 
   }
   
   //売り決済注文
   if (sellFlag) {
      if (ema25Judge>ema50Judge && ema25<ema50) {
         res = OrderClose(ea_ticket_res, 0.01, Ask, 1, clrRed);
         closePrice=Ask;
         printf("sellOrder SELL");
         sellFlag = false;
         ea_ticket_res = 0;
         
         if (orderPrice>closePrice) {
            printf((string)ea_ticket_res+" O:"+(string)orderPrice+" C:"+(string)closePrice);
            countPrifit += orderPrice-closePrice;
            wincount++;
         }
         ObjectSetText("obj_judgeMonitor", "判定："+(string)count+" 勝ち："+(string)wincount+" 勝率："+(string)(NormalizeDouble(wincount/count*100,0))+"%"+"  利益"+(string)(countPrifit*100), 11, "メイリオ", clrWhite);//勝率の表示
         printf((wincount/count*100));
      }
   }
  }
