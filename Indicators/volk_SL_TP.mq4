//+------------------------------------------------------------------+
//|                                                 SL&TP Values.mq4 |
//|                                          Copyright © 2017, MhFx7 |
//|                              https://www.mql5.com/en/users/mhfx7 |
//+------------------------------------------------------------------+
#property copyright  "Copyright © 2017, MhFx7 + volk"
#property link       "https://www.mql5.com/en/users/mhfx7"
#property version    "1.05"
#property strict
#property indicator_chart_window

#include <ChartObjects\ChartObjectPanel.mqh>
#include <ChartObjects\ChartObjectsArrows.mqh>
//+------------------------------------------------------------------+
//| Select Colors                                                    |
//+------------------------------------------------------------------+
enum ColorSelect
  {
   COLOR_RED_GREEN,//Red/Green
   COLOR_FOREGROUND,//Foreground
  };
//--
input ColorSelect Colors=COLOR_RED_GREEN;//Colors
input int Offset=25;//Offset
input double Risk=1;//% on equity
input bool showAlerts=false; 
//--
color COLOR_SL=clrNONE;
color COLOR_TP=clrNONE;
CChartObjectLabel lb1P;
CChartObjectLabel lb1M;
CChartObjectArrowLeftPrice arrPointerLots;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   EventSetMillisecondTimer(1000);
//-- Initialize Colors
   if(Colors!=COLOR_RED_GREEN)
     {
      COLOR_SL=ChartForeColor();
      COLOR_TP=ChartForeColor();
     }
   else
     {
      COLOR_SL=clrRed;
      COLOR_TP=clrLimeGreen;
     }
     
     lb1P.Create(0,"#lb1P1",0,11,35);
     lb1P.Description("????");
     lb1P.Color(clrGreen);
     lb1P.Corner(CORNER_LEFT_LOWER);
     lb1P.Z_Order(999);

     lb1M.Create(0,"#lb1M1",0,10,15);
     lb1M.Description("????");
     lb1M.Color(clrRed);
     lb1M.Corner(CORNER_LEFT_LOWER);
     
     arrPointerLots.Create(0,"#lotti1",0,Time[0],Ask);
     arrPointerLots.Description("?");
     arrPointerLots.Z_Order(100);
     arrPointerLots.Selectable(true);
     arrPointerLots.Selected(true);
     arrPointerLots.Tooltip("???");
     
     double Price = WindowPriceOnDropped();
     
     //if (showAlerts)
      Print(DoubleToString(Price,_Digits));
        
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   EventKillTimer();
//-- Delete Objects (Opened Orders)
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==_Symbol)
           {
            //--
            if(ObjectFind(0,"#"+IntegerToString(OrderTicket(),0,0)+" sl")==0)ObjectDelete(0,"#"+IntegerToString(OrderTicket(),0,0)+" sl");
            if(ObjectFind(0,"#"+IntegerToString(OrderTicket(),0,0)+" tp")==0)ObjectDelete(0,"#"+IntegerToString(OrderTicket(),0,0)+" tp");
            
            
            //--
            
          
           }
        }
     }
//--- 
           if(ObjectFind(lb1P.Name())==0) lb1P.Delete();
            lb1M.Delete();
            arrPointerLots.Delete();

  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---

   if (prev_calculated!=rates_total)
   {
      //sposta il puntatore lotti solo se selezionato
      if (arrPointerLots.Selected())
         arrPointerLots.Time(0,Time[0]);
   }
 
//--- return value of prev_calculated for next call
   return(rates_total);
  }
  
//+------------------------------------------------------------------+ 
//Mostra le label di ATR
//+------------------------------------------------------------------+
void ShowATR()
{

   string text1P,text1N;
   double atr;

   
   atr=iATR(_Symbol,0,14,0);
   
   RefreshRates();
   

   text1P="Lng (-2) " +DoubleToString((-2*atr+Bid),_Digits) + " (+4) "+DoubleToString((4*atr+Bid),_Digits);
   text1P=text1P+" [" + GetLotSize(Ask,-2*atr+Bid,OP_BUY)+ "]" +" [** " + GetLotSize(1.179,1.178,OP_BUY)+ " **]";
   
   text1N="Srt (+2) " +DoubleToString((2*atr+Ask),_Digits) + " (-4) "+DoubleToString((-4*atr+Ask),_Digits);
   text1N=text1N+" [" + GetLotSize(Bid,2*atr+Ask,OP_SELL)+ "]";
   
   lb1P.Description(text1P);
   lb1M.Description(text1N);
 
}

void ShowLots()
{
   string textLots1;
   double sl;
   arrPointerLots.GetDouble(OBJPROP_PRICE,0,sl);
   
   RefreshRates();
   if(Bid <sl) 
   {
      textLots1=" [" + GetLotSize(Ask,sl,OP_SELL)+ "]";
      arrPointerLots.Color(clrRed);
   }
   else
   {
      textLots1=" [" + GetLotSize(Bid,sl,OP_BUY)+ "]";
      arrPointerLots.Color(clrGreen);
   }  
   arrPointerLots.Tooltip(textLots1);

}

double GetLotSize(double price,double priceSL,int orderType)
{

   double local_availablemoney;
	double local_lotsize;
	int local_lotdigit;
	string local_appendix;  // local string variable used for possible currency pair appendix
	int local_length;  // local integer variable to store length of the currency pair string
   //double multiplicator;      // Multiplicator for lot size based on Account Currency
   double tick_val;
   double local_max_expos;
   double stoplevel=MarketInfo(_Symbol,MODE_STOPLEVEL)*Point;
   //Alert(_Symbol,stoplevel);
//   if(stoplevel<=0) 
//      stoplevel=1000;
      
   switch (orderType)
   {
      case OP_BUY:
         if (price <stoplevel+priceSL)
            return(-1);
      break;
      case OP_SELL:
        if (price >-stoplevel+priceSL)
            return(-1);     
      break;
   
   }
   
	//if(lotstep == 1) 
	//	local_lotdigit = 0;
	//if(lotstep == 0.1)	
	//	local_lotdigit = 1;
   //if(lotstep == 0.01) 
	local_lotdigit = 2;

   local_length = StringLen(Symbol());
	local_appendix = "";
	//multiplicator=0;
	tick_val=0;
	
	if (local_length != 6)
		local_appendix = StringSubstr(Symbol(),6,local_length - 6);
  /* if (AccountCurrency() == "EUR") 
		multiplicator = 1.0 / MarketInfo("EURUSD" + local_appendix, MODE_BID);
   if (AccountCurrency() == "GBP") 
		multiplicator = 1.0 / MarketInfo("GBPUSD" + local_appendix, MODE_BID);
   if (AccountCurrency() == "CHF") 
		multiplicator = MarketInfo("USDCHF" + local_appendix, MODE_BID);
   if (AccountCurrency() == "JPY") 
		multiplicator = MarketInfo("USDJPY" + local_appendix, MODE_BID);
   if (multiplicator == 0)
   	multiplicator = 1.0; // If account currency is neither of EUR,GBP,CHF or JPY we assumes that it is USD
*/
  if (AccountCurrency() != "EUR")
  {
   if (showAlerts)
      Alert("Conto solo in €");
   return(0);
  } 
  tick_val=MarketInfo(_Symbol,MODE_TICKVALUE)/_Point;
  //multiplicator = 1.0 / MarketInfo("EURUSD" + local_appendix, MODE_BID);
   if (((price-priceSL)*tick_val)==0)
   {
     if (showAlerts)
      Alert("Price ",price," SL ",priceSL," Tick ",tick_val);
     return(0);

   }
	// Get available money as Equity
	local_availablemoney = AccountBalance();
	local_max_expos=local_availablemoney*Risk/100;
	local_lotsize =local_max_expos/((price-priceSL)*tick_val);// MathMin(MathFloor(Risk / 102 * local_availablemoney / (StopLoss + AddPriceGap) / lotstep) * lotstep, MaxLots);
   local_lotsize = MathAbs(local_lotsize ); 
   
   if (local_lotsize < MarketInfo(Symbol(), MODE_MINLOT)/2)
		 local_lotsize = 0;
   else if (local_lotsize < MarketInfo(Symbol(), MODE_MINLOT))
		   local_lotsize = MarketInfo(Symbol(), MODE_MINLOT);//lascia un margine di tolleranza
	local_lotsize = NormalizeDouble(local_lotsize, local_lotdigit);


		
	return (local_lotsize);
}


//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//----
   double sl_dist=0,sl_val=0,tp_dist=0,tp_val=0,tick_val=0;
   string sl_name="", tp_name="", sl_pn="";
   ENUM_ANCHOR_POINT anchor=0;
   
   ShowATR();
   ShowLots();
//--
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==_Symbol)
           {
            //--- 
            tick_val=MarketInfo(_Symbol,MODE_TICKVALUE);//GetTickValue
            //--
            if(ChartGetInteger(0,CHART_SHIFT,0))anchor=ANCHOR_LEFT;else anchor=ANCHOR_RIGHT;//SetAnchor
            //-- Sell Orders
            if(OrderType()==OP_SELL || OrderType()==OP_SELLLIMIT || OrderType()==OP_SELLSTOP)
              {
               //-- StopLoss
               sl_name="#"+IntegerToString(OrderTicket(),0,0)+" sl";//SetName
               if(OrderStopLoss()>0)//StopLoss is active
                 {
                  if(OrderStopLoss()<=OrderOpenPrice())sl_pn="   +";else sl_pn="   -";//SetPos/Negative
                  sl_dist=(OrderStopLoss()-OrderOpenPrice())/_Point;//CalcDistance
                  sl_val=(sl_dist*tick_val)*OrderLots();//CalcValue
                  TextCreate(0,sl_name,0,Time[0],OrderStopLoss()+Offset*_Point,sl_pn+DoubleToString(MathAbs(sl_val),2)+_AccountCurrency()+" / "+DoubleToString(MathAbs(sl_dist),0)+"p","Tahoma",8,COLOR_SL,0,anchor,false,false,true,0);//ObjectCreate
                  //-- ObjectSet SL
                  if(ObjectFind(0,sl_name)==0)//Object is present
                    {
                     if((ObjectGetDouble(0,sl_name,OBJPROP_PRICE,0)-(OrderStopLoss()+Offset*_Point))!=0 || ObjectGetInteger(0,sl_name,OBJPROP_TIME,0)!=Time[0])//Price or Time has changed
                       {
                        ObjectSetDouble(0,sl_name,OBJPROP_PRICE,OrderStopLoss()+Offset*_Point);//SetPrice
                        ObjectSetString(0,sl_name,OBJPROP_TEXT,0,sl_pn+DoubleToString(MathAbs(sl_val),2)+_AccountCurrency()+" / "+DoubleToString(MathAbs(sl_dist),0)+"p");//SetText
                        ObjectSetInteger(0,sl_name,OBJPROP_TIME,Time[0]);//SetTime
                       }
                    }
                  //--
                 }
               //--
               else if(ObjectFind(0,sl_name)==0)ObjectDelete(0,sl_name);//Canceled
               //-- TakeProfit
               tp_name="#"+IntegerToString(OrderTicket(),0,0)+" tp";//SetName
               if(OrderTakeProfit()>0)//TakeProfit is active
                 {
                  tp_dist=(OrderOpenPrice()-OrderTakeProfit())/_Point;//CalcDistance
                  tp_val=(tp_dist*tick_val)*OrderLots();//CalcValue
                  TextCreate(0,tp_name,0,Time[0],OrderTakeProfit()-Offset*_Point,"   +"+DoubleToString(tp_val,2)+_AccountCurrency()+" / "+DoubleToString(tp_dist,0)+"p","Tahoma",8,COLOR_TP,0,anchor,false,false,true,0);//ObjectCreate
                  //-- ObjectSet TP
                  if(ObjectFind(0,tp_name)==0)//Object is present
                    {
                     if((ObjectGetDouble(0,tp_name,OBJPROP_PRICE,0)-(OrderTakeProfit()-Offset*_Point))!=0 || ObjectGetInteger(0,tp_name,OBJPROP_TIME,0)!=Time[0])//Price or Time has changed
                       {
                        ObjectSetDouble(0,tp_name,OBJPROP_PRICE,OrderTakeProfit()-Offset*_Point);//SetPrice
                        ObjectSetString(0,tp_name,OBJPROP_TEXT,0,"   +"+DoubleToString(tp_val,2)+_AccountCurrency()+" / "+DoubleToString(tp_dist,0)+"p");//SetText
                        ObjectSetInteger(0,tp_name,OBJPROP_TIME,Time[0]);//SetTime
                       }
                    }
                 }
               //--
               else if(ObjectFind(0,tp_name)==0)ObjectDelete(0,tp_name);//Canceled
               //--
              }
            //--- Buy Orders
            if(OrderType()==OP_BUY || OrderType()==OP_BUYLIMIT || OrderType()==OP_BUYSTOP)
              {
               //-- StopLoss
               sl_name="#"+IntegerToString(OrderTicket(),0,0)+" sl";//SetName
               if(OrderStopLoss()>0)//StopLoss is active
                 {
                  if(OrderStopLoss()>=OrderOpenPrice())sl_pn="   +";else sl_pn="   -";//SetPos/Negative
                  sl_dist=(OrderOpenPrice()-OrderStopLoss())/_Point;//CalcDistance
                  sl_val=(sl_dist*tick_val)*OrderLots();//CalcValue
                  TextCreate(0,sl_name,0,Time[0],OrderStopLoss()-Offset*_Point,sl_pn+DoubleToString(MathAbs(sl_val),2)+_AccountCurrency()+" / "+DoubleToString(MathAbs(sl_dist),0)+"p","Tahoma",8,COLOR_SL,0,anchor,false,false,true,0);//ObjectCreate
                  //-- ObjectSet SL
                  if(ObjectFind(0,sl_name)==0)//Object is present
                    {
                     if((ObjectGetDouble(0,sl_name,OBJPROP_PRICE,0)-(OrderStopLoss()-Offset*_Point))!=0 || ObjectGetInteger(0,sl_name,OBJPROP_TIME,0)!=Time[0])//Price or Time has changed
                       {
                        ObjectSetDouble(0,sl_name,OBJPROP_PRICE,OrderStopLoss()-Offset*_Point);//SetPrice
                        ObjectSetString(0,sl_name,OBJPROP_TEXT,0,sl_pn+DoubleToString(MathAbs(sl_val),2)+_AccountCurrency()+" / "+DoubleToString(MathAbs(sl_dist),0)+"p");//SetText
                        ObjectSetInteger(0,sl_name,OBJPROP_TIME,Time[0]);//SetTime
                       }
                    }
                  //--
                 }
               //--
               else if(ObjectFind(0,sl_name)==0)ObjectDelete(0,sl_name);//Canceled
               //-- TakeProfit
               tp_name="#"+IntegerToString(OrderTicket(),0,0)+" tp";//SetName
               if(OrderTakeProfit()>0)//TakeProfit is active
                 {
                  tp_dist=(OrderTakeProfit()-OrderOpenPrice())/_Point;//CalcDistance
                  tp_val=(tp_dist*tick_val)*OrderLots();//CalcValue
                  TextCreate(0,tp_name,0,Time[0],OrderTakeProfit()+Offset*_Point,"   +"+DoubleToString(tp_val,2)+_AccountCurrency()+" / "+DoubleToString(tp_dist,0)+"p","Tahoma",8,COLOR_TP,0,anchor,false,false,true,0);//ObjectCreate
                  //-- ObjectSet TP
                  if(ObjectFind(0,tp_name)==0)//Object is present
                    {
                     if((ObjectGetDouble(0,tp_name,OBJPROP_PRICE,0)-(OrderTakeProfit()+Offset*_Point))!=0 || ObjectGetInteger(0,tp_name,OBJPROP_TIME,0)!=Time[0])//Price or Time has changed
                       {
                        ObjectSetDouble(0,tp_name,OBJPROP_PRICE,OrderTakeProfit()+Offset*_Point);//SetPrice
                        ObjectSetString(0,tp_name,OBJPROP_TEXT,0,"   +"+DoubleToString(tp_val,2)+_AccountCurrency()+" / "+DoubleToString(tp_dist,0)+"p");//SetText
                        ObjectSetInteger(0,tp_name,OBJPROP_TIME,Time[0]);//SetTime
                       }
                    }
                 }
               //--
               else if(ObjectFind(0,tp_name)==0)ObjectDelete(0,tp_name);//Canceled
               //--
              }
            //---
           }
        }
     }
//-- Delete Objects (Closed Orders)
   for(int x=0; x<ObjectsTotal(); x++)
     {
      string obj_name=ObjectName(x);
      if(StringSubstr(obj_name,StringLen(obj_name)-2,2)=="sl" || StringSubstr(obj_name,StringLen(obj_name)-2,2)=="tp")
        {
         for(int i=0; i<OrdersHistoryTotal(); i++)
           {
            if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
              {
               if(OrderSymbol()==_Symbol)
                 {
                  //-- Closed Order found
                  if(ObjectFind(0,"#"+IntegerToString(OrderTicket(),0,0)+" sl")==0)ObjectDelete(0,"#"+IntegerToString(OrderTicket(),0,0)+" sl");
                  if(ObjectFind(0,"#"+IntegerToString(OrderTicket(),0,0)+" tp")==0)ObjectDelete(0,"#"+IntegerToString(OrderTicket(),0,0)+" tp");
                  //--
                 }
              }
           }
         //--
        }
     }
//----
  }
//+------------------------------------------------------------------+
//| ChartForeColor                                                   |
//+------------------------------------------------------------------+
color ChartForeColor()
  {
   long result=clrNONE;
   ChartGetInteger(0,CHART_COLOR_FOREGROUND,0,result);
   return((color)result);
  }
//+------------------------------------------------------------------+
//| AccountCurrency                                                  |
//+------------------------------------------------------------------+
string _AccountCurrency()
  {
   string txt="";
   if(AccountCurrency()=="EUR")txt="€";
   if(AccountCurrency()=="USD")txt="$";
   if(AccountCurrency()=="GBP")txt="£";
   if(AccountCurrency()=="CHF")txt="Fr.";
   return(txt);
  }
//+------------------------------------------------------------------+ 
//| Creating Text object                                             | 
//+------------------------------------------------------------------+ 
bool TextCreate(const long              chart_ID=0,               // chart's ID 
                const string            name="Text",              // object name 
                const int               sub_window=0,             // subwindow index 
                datetime                time=0,                   // anchor point time 
                double                  price=0,                  // anchor point price 
                const string            text="Text",              // the text itself 
                const string            font="Arial",             // font 
                const int               font_size=10,             // font size 
                const color             clr=clrRed,               // color 
                const double            angle=0.0,                // text slope 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type 
                const bool              back=false,               // in the background 
                const bool              selection=false,          // highlight to move 
                const bool              hidden=true,              // hidden in the object list 
                const long              z_order=0)                // priority for mouse click 
  {
   if(ObjectFind(chart_ID,name)!=0)
     {
      ResetLastError();
      if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
        {
         Print(__FUNCTION__,
               ": failed to create \"Text\" object! Error code = ",GetLastError());
         return(false);
        }
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
      ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
     }
   return(true);
  }
//+------------------------------------------------------------------+ 
//| End of the code                                                  | 
//+------------------------------------------------------------------+ 
