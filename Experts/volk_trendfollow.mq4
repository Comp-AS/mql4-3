//+------------------------------------------------------------------+
//|                                           volk_trendfollow.mq4   |
//|                                                             volk |
//|   EURCHF M15                                                     |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      ""
#property version   "1.02"
#property strict

#include <volk_utils.mqh>


input int TakeProfit       = 15; // The take profit level (0 disable)
input int StopLoss         = 10; // The default stop loss (0 disable)
input double Risk          = 0.5;//%on equity
input int MaxSpreadInPIP   = 5;//Disable orders on wide spread cross
input bool ShowAlerts      = false;//Alerts  
input double MinBalance    =1600.0;//Limit that stop sending more trading to preserve money
input string CommentString ="";
input OrderPreference Type=OPB;
input double AtrStopFactor=2.0;//Factor * ATR(if StopLoss=0)
input int AtrAvgCount=5;//Average candlestick on ATR 
input int MaxSlippage=5;
input bool DebugToFile=true;

#define MAGICNUM  2712794

//#include <MovingAverages.mqh>

static datetime oldTime; 

double PIPCoef;//moltiplicatore per ottenere un valore dai PIP, tiene conto dei decimali del broker

//parametri label di indicazione
int OffsetHorizontal = 5;
int OffsetVertical = 20;
color LabelColor = Black;

bool oneAlarmOnBalanceReach=false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   if (!IsDemo())
   {
      Alert("**** NOT IN DEMO ****");
   }
   double realDigits;
   if(Digits < 2) {
      realDigits = 0;
   } else if (Digits < 4) {
      realDigits = 2;
   } else {
      realDigits = 4;
   }

   PIPCoef = 1/ MathPow(10, realDigits);
                                                     
 
   //IL FONT VIENE SOVRASCRITTO, QUI NON HA TANTA IMPORTANZA
   ObjectCreate("lineopl", OBJ_LABEL, 0, 0, 0);
   ObjectSet("lineopl", OBJPROP_CORNER, 1);
   ObjectSet("lineopl", OBJPROP_YDISTANCE, OffsetVertical + 30);
   ObjectSet("lineopl", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("lineopl", "Open P/L: -", 8, "Tahoma", LabelColor);


   ObjectCreate("linerisk", OBJ_LABEL, 0, 0, 0);
   ObjectSet("linerisk", OBJPROP_CORNER, 1);
   ObjectSet("linerisk", OBJPROP_YDISTANCE, OffsetVertical + 10);
   ObjectSet("linerisk", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("linerisk", "Risk ???", 8, "Tahoma", LabelColor);


   ObjectCreate("linetime", OBJ_LABEL, 0, 0, 0);
   ObjectSet("linetime", OBJPROP_CORNER, 1);
   ObjectSet("linetime", OBJPROP_YDISTANCE, OffsetVertical + 20);
   ObjectSet("linetime", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("linetime", "Time ???", 6, "Tahoma", LabelColor);

   ObjectCreate("linestats", OBJ_LABEL, 0, 0, 0);
   ObjectSet("linestats", OBJPROP_CORNER, 1);
   ObjectSet("linestats", OBJPROP_YDISTANCE, OffsetVertical + 40);
   ObjectSet("linestats", OBJPROP_XDISTANCE, OffsetHorizontal);
   ObjectSetText("linestats", "Stats ???", 8, "Tahoma", LabelColor);


   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
  // EventKillTimer();
     ObjectDelete("lineopl"); 
     ObjectDelete("linerisk"); 
     ObjectDelete("linetime"); 
     ObjectDelete("stats"); 
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
bool changed=false;
   if(oldTime != Time[0] )
   {
  //    CheckMarket();
      changed=true;
      oldTime = Time[0];
   }
   CheckMarket();
    
   textFillOpens(changed);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

int CheckMarket()
{
  int ticket,ticketFst   ;
  double  ShortSL, ShortTP, LongSL, LongTP;
  bool ordinePresente;
  int orderType;
  
  double minstoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL);
 
  

  ticketFst=GetFirstOrder();
 
  ordinePresente=(ticketFst != -1);
   
  // Only open one trade at a time..
  if(!ordinePresente){
      if ( AccountBalance()<MinBalance)
      {
         Print("Balance reach: ", MinBalance);
         if (ShowAlerts && !oneAlarmOnBalanceReach)
            {
               Alert("Balance reach: ", MinBalance);
               oneAlarmOnBalanceReach=true;
            }
     
         return (0);
      }
  
      RefreshRates();
      

      double Spread = Ask - Bid;
      if(Spread>MaxSpreadInPIP*PIPCoef) //non effettua operazioni per spread troppo alti
         return(0);
         
      
      // Print("Minimum Stop Level=",minstoplevel," points");

       
       orderType=placeOrder();
       // Buy - Long position
       if(orderType == OP_BUY){
         LongSL=0;
         LongTP=0;
           if(TakeProfit > 0)
           {
               LongTP = NormalizeDouble(Ask+TakeProfit*PIPCoef,Digits);
           }
           if(StopLoss > 0)
           {
               LongSL = NormalizeDouble(Bid-StopLoss*PIPCoef,Digits);
           }
           else
           {
               double atr;
               atr=iATR(_Symbol, PERIOD_D1,AtrAvgCount,0);
               LongSL = NormalizeDouble(Bid-AtrStopFactor*atr,Digits);
           }
           ticket = OrderSend(Symbol(), OP_BUY, LotsOptimized(OP_BUY,LongSL),Ask,MaxSlippage, LongSL, LongTP, "VOLK trendfollow " +CommentString,MAGICNUM,0,Blue);
           if(ticket > 0){
             if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
               Print("BUY Order Opened: ", OrderOpenPrice(), " SL:", LongSL, " TP: ", LongTP);
             }
             else
             {
               Print("Error Opening BUY  Order: ", GetLastError());
               if (ShowAlerts)
                  Alert("Error Opening BUY  Order");
               return(1);
             }
           }
       // Sell - Short position
       if(orderType == OP_SELL){
           ShortSL=0;
           ShortTP=0;
           if(TakeProfit > 0)
           {
               ShortTP = NormalizeDouble(Bid-TakeProfit*PIPCoef,Digits);
           }
           if(StopLoss > 0)
           {
               ShortSL = NormalizeDouble(Ask+StopLoss*PIPCoef,Digits);
           }
          else
           {
               double atr;
               atr=iATR(_Symbol, PERIOD_D1,AtrAvgCount,0);
               ShortSL = NormalizeDouble(Ask+AtrStopFactor*atr,Digits);
           }

            ticket = OrderSend(Symbol(), OP_SELL, LotsOptimized(OP_SELL,ShortSL),Bid,MaxSlippage, ShortSL, ShortTP, "VOLK trendfollow " +CommentString,MAGICNUM,0,Red);
            if(ticket > 0){
              if(OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES))
                Print("SELL Order Opened: ", OrderOpenPrice(), " SL:", ShortSL, " TP: ", ShortTP);
              }
              else
              {
                Print("Error Opening SELL Order: ", GetLastError());
                if (ShowAlerts)
                  Alert("Error Opening SELL  Order");
                
                return(1);
              }
            }
 
 
  }
  else
  {//ordine presente
   
       if(OrderSelect(ticketFst,SELECT_BY_TICKET,MODE_TRADES)==true ) {

            double pl = 0;

   //         if(OrderType() == OP_BUY) {
   //            pl = (OrderClosePrice() - OrderOpenPrice());
   //         } else {
   //            pl = (OrderOpenPrice() - OrderClosePrice());
   //         }
            pl=OrderProfit();
            
            if (pl<0)
            {
              int Inp01Period=16; 
             
              //double m1 = NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,1),Digits);
              //double m2 = NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,5),Digits);
              //double m3 = NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,9),Digits);
         
                if(OrderType() == OP_SELL) {
                  if(MonotoneAverage(9,OP_BUY))
                    ClosePositionAtMarket();
               } else {
                  if(MonotoneAverage(9,OP_SELL))
                    ClosePositionAtMarket();
               }
          
            
            }

      }

  }
 
  return(0);
}

void ClosePositionAtMarket() {
   RefreshRates();
   double priceCP;
   bool rettmp;

   if(OrderType() == OP_BUY) {
      priceCP = Bid;
   } else {
      priceCP = Ask;
   }
   Print("*** Close ", OrderTicket());
   rettmp = OrderClose(OrderTicket(), OrderLots(), priceCP, MaxSlippage);
}


//cerca il primo ordine aperto, filtrando per SYMBOL, MAGIC 
//e ordinando per data inserimento
//
int GetFirstOrder()
{
  int cnt;
  int ticket=-1;
  datetime opened=D'01.01.2100';// salva la data di apertura per considerare il più vecchio
 
  for(cnt = 0; cnt < OrdersTotal(); cnt++)
  {
     OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
     if(OrderMagicNumber() ==MAGICNUM && OrderSymbol() == Symbol())
     {
         if (OrderOpenTime() < opened )
         {
            ticket=OrderTicket();  
            opened=OrderOpenTime();
         }
     }
  } 
  return(ticket);
}

//determina il numero di lotti da utilizzare in base al money management
//type: BUY, SELL ..
//stoploss: valore dello stop loss (NON i pip di differenza)
//
double LotsOptimized(int type,double stoploss)
  {
   //double lot = 0.01;
   double lot=0;

   if(type==OP_BUY)
   {  
     
      lot=volk_GetLotSize(Bid,stoploss,type,Risk);
   }
   else if(type==OP_SELL)
   {
      
      lot=volk_GetLotSize(Ask,stoploss,type,Risk);
   }

   Print("Lot: ", lot, " Stop ", stoploss);
   return(lot);
  }
 
//determina se piazzare un ordine e come deve essere:BUY, SELL...
//  
int placeOrder()
{
  int Inp01Period=16; 
  //double m1 = NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,1),Digits);
  //double m2 = NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,5),Digits);
  //double m3 = NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,9),Digits);
  
 
  
  if(MonotoneAverage(9,OP_BUY))
  {
 //     Print("BUY m1: ", m1, " m2:", m2, " m3: ", m3);
      if((Type==OPB)||(Type==OPBS))
      {
         return(OP_BUY);
      }
      else
         return(-2);
  }
  
  if(MonotoneAverage(9,OP_SELL))
  {
//      Print("SELL m1: ", m1, " m2:", m2, " m3: ", m3);
     
      if((Type==OPS)||(Type==OPBS))
      {
        return(OP_SELL);
      }
      else
         return(-2);
  }
  return (-1);
}

bool MonotoneAverage(int prevCount,int direction)
{
  int Inp01Period=16; 
  int i;
  //double m1 = NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,1),Digits);
  //double m2 = NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,5),Digits);
  
  if (DebugToFile)
  {
  /*    int handle = FileOpen(StringConcatenate(TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL4\\files\\","volk_trend.csv"),FILE_WRITE|FILE_CSV);
      FileWrite(handle,TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS));
      for (i=0 ; i< prevCount ;i++)
      {
         FileWrite(handle,i,NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,i),Digits));
      }
      FileClose(handle);*/
  }
  
  
  for (i=0 ; i< prevCount -1;i++)
  {
      if (direction== OP_BUY)
      {
         if (NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,i),Digits)<
            NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,i+1),Digits))
         {
            return(false);
         }
       }
       else
       {
       
        if (NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,i),Digits)>
            NormalizeDouble(iMA(NULL,0,Inp01Period,0,MODE_SMA,PRICE_CLOSE,i+1),Digits))
         {
            return(false);
         }
       
       }
  
  } 
  return (true);
   
}



//aggiorna il testo delle etichette di diagnostica
//alsobig: se true aggiorna anche le label che richiedono calcoli dispoendiosi
//
void textFillOpens(bool alsobig ) {
   int lvr=AccountLeverage();
   
   //PROFITTO ATTUALE E MAGIC(PER EVITARE DUPLICATI)
   ObjectSetText("lineopl", "Open P/L: "+DoubleToStr(GetOpenPLInMoney(), 2) , 8, "Tahoma", LabelColor);
   //% DEL RISCHIO, PER VERIFICARE COERENZA MONEYMANAGEMENT
   ObjectSetText("linerisk", "Risk: "+DoubleToStr(Risk, 1) + "% update " +TimeToStr(Time[0]) + "(Lvrg " + IntegerToString(lvr) +")" , 8, "Tahoma", LabelColor);
   //TEMPO PER LA CHIUSUSRA DELL'ATTUALE CANDELA
   string TimeLeft=TimeToStr(Time[0]+Period()*60-TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
   ObjectSetText("linetime", "Time: "+ TimeLeft + " Magic: "+IntegerToString(MAGICNUM), 6, "Tahoma", LabelColor);
   //STATISTICHE DI STRATEGIA
   
   if (alsobig)
   {
      string statistiche="P/L: "+DoubleToStr(GetTotalClosedPLInMoney(1000),2) +
                         "  P#: "+IntegerToString(GetTotalProfits(1000)) +
                         "  L#: "+IntegerToString(GetTotalLosses(1000))  ;
      ObjectSetText("linestats", "Stats: "+ statistiche , 8, "Tahoma", LabelColor);
   }
}

//OTTIENE dagli ordini aperti il profitto,filtrando per SYMBOL e MAGIC
//..
double GetOpenPLInMoney() {
   double pl = 0;

   for (int cc = OrdersTotal() - 1; cc >= 0; cc--) {
      if (!OrderSelect(cc, SELECT_BY_POS) ) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderMagicNumber() != MAGICNUM) continue;

      pl += OrderProfit();
   }

   return(pl);
}

//ritorna il numero di trade che hanno portato un profitto
//..
int GetTotalProfits(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;
   int profits = 0;

   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {

         if(OrderMagicNumber() == MAGICNUM) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;

            if(OrderType() == OP_BUY) {
               pl = (OrderClosePrice() - OrderOpenPrice());
            } else {
               pl = (OrderOpenPrice() - OrderClosePrice());
            }

            if(pl > 0) {
               profits++;
            }

            if(count >= numberOfLastOrders) break;
         }
      }
   }

   return(profits);
}

//ritorna il numero di trade che hanno portato una perdita
//..
int GetTotalLosses(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;
   int losses = 0;

   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {

         if(OrderMagicNumber() == MAGICNUM) {
            // return the P/L of last order
            // or return the P/L of last order with given Magic Number
            count++;

            if(OrderType() == OP_BUY) {
               pl = (OrderClosePrice() - OrderOpenPrice());
            } else {
               pl = (OrderOpenPrice() - OrderClosePrice());
            }

            if(pl < 0) {
               losses++;
            }

            if(count >= numberOfLastOrders) break;
         }
      }
   }

   return(losses);
}

//ritorna il profitto totale
//..
double GetTotalClosedPLInMoney(int numberOfLastOrders) {
   double pl = 0;
   int count = 0;

   for(int i=OrdersHistoryTotal(); i>=0; i--) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==true && OrderSymbol() == Symbol()) {
         if(OrderMagicNumber() == MAGICNUM) {
            // return the P/L of last order or the P/L of last order with given Magic Number

            count++;
            pl = pl + OrderProfit();

            if(count >= numberOfLastOrders) break;
         }
      }
   }

   return(pl);
}
