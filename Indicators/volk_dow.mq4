//+------------------------------------------------------------------+
//|                                                 volk_candles.mq4 |
//|                                                             volk |
//|                                                   www.volk.cloud |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      "www.volk.cloud"
#property version   "1.00"
#property strict
#property description "Evidenzia alcune candele temporalmente (esempio domeniche) "
#property indicator_chart_window


  
//double Derivata01Buffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- 1 additional buffer used for counting.
   ClearObjs();
  
//---
  // SetIndexDrawBegin(0,Inp01Period+InpBandsShift);
  
   //--- initialization done
   return(INIT_SUCCEEDED);
  }
  
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
  return ClearObjs();
  }
  
  
  
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
   int i,pos;
   int numPos,numNeg;
   int numOldPos=0,numOldNeg=0;
   bool isMod;
//---
  // if(rates_total<=Inp01Period || Inp01Period<=0)
  //    return(0);
   if(rates_total==prev_calculated)
      return(rates_total);
   
   ArraySetAsSeries(close,false);
   

//--- starting calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle:attenzione all'ordine della sequenza
   bool ok =false;

   for(i=pos; i<rates_total && !IsStopped(); i++)
     {
       if (TimeDayOfWeek(Time[rates_total-i-1])==0)
       {
         DrawSimbolSunday(Time[rates_total-i-1],high[rates_total-i-1],  Green,STYLE_DOT,0,i);
       } 
     }
//---- OnCalculate done. Return new prev_calculated.
     return(rates_total);
  }



  
  void DrawSimbolSunday(datetime x1,double y1,
                  color lineColor,double style,int direction,int idx)
  {
   int indicatorWindow=0;//WindowFind(indicatorName);
   if(indicatorWindow<0) return;
   bool created;

   string labelArrow="volkDow#"+DoubleToStr(x1,0)+"-"+DoubleToStr(y1,0);// IntegerToString(idx);  
  
   if(direction==1)//BUY
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1,0,0);
      ObjectSet(labelArrow,OBJPROP_COLOR,lineColor);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,253);
   }
   else if(direction==0)//SELL
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1+0.002);
      ObjectSet(labelArrow,OBJPROP_COLOR,lineColor);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,253);
   }
  
 
  }
  
  
  
  int ClearObjs()
  {
   for(int i=ObjectsTotal()-1; i>=0; i--)
     {
      string label=ObjectName(i);
      if((StringSubstr(label,0,3)=="no#")||(StringSubstr(label,0,8)=="volkDow#") )     
       ObjectDelete(label);
     }
   return(0);
  }
  
  
