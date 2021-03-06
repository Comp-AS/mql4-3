//+------------------------------------------------------------------+
//|                                                 volk_candles.mq4 |
//|                                                             volk |
//|                                                   www.volk.cloud |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      "www.volk.cloud"
#property version   "1.00"
#property strict
#property indicator_chart_window

#property indicator_buffers 6
#property indicator_color1 Red
#property indicator_color2 Blue
#property indicator_color3 Green

#include <volk_basePatternDetector.mqh>;

#include <ChartObjects\ChartObjectPanel.mqh>
#include <ChartObjects\ChartObjectsArrows.mqh>

CChartObjectArrowLeftPrice arrPointerSL;
CChartObjectArrowLeftPrice arrPointerTP;
CChartObjectArrowLeftPrice arrPointerEN;
CChartObjectLabel lbInfo;
  
input int    InpBandsShift=0;        // Bands Shift
input double PercSL=1.0;
input double PercTP=1.0;
input bool logToFile=false;
//input double InpBandsDeviations=2.0; // Bands Deviations

//input int Inp01Period=70;
//--- buffers
double Ext01Buffer[];

//double Derivata01Buffer[];
int DECIMALS=4;
int PIPFACTOR=10000;
int handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//--- 1 additional buffer used for counting.
   IndicatorBuffers(6);
   IndicatorDigits(Digits);
//--- set delle 3 bande
  // SetIndexStyle(0,DRAW_LINE);
  // SetIndexBuffer(0,Ext01Buffer);
  // SetIndexShift(0,InpBandsShift);
  // SetIndexLabel(0,"GEM");
   handle=-1;
   if (logToFile)   
      handle=FileOpen(_Symbol + "_" + _Period  + "_volk_candles.csv", FILE_CSV|FILE_WRITE|FILE_SHARE_READ,'\t');
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
  if (handle>0)
      FileClose(handle);
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
//--- counting from 0 to rates_total
   ArraySetAsSeries(Ext01Buffer,false);
   
   ArraySetAsSeries(close,false);
   
//--- initial zero
   if(prev_calculated<1)
   {
  /*      for(i=0; i<Inp01Period; i++)
        {
         ExtMoving01Buffer[i]=EMPTY_VALUE;       
        }
       for(i=0; i<Inp02Period; i++)
        {
         ExtMoving02Buffer[i]=EMPTY_VALUE;       
        }
      for(i=0; i<Inp03Period; i++)
        {
         ExtMoving03Buffer[i]=EMPTY_VALUE;       
        }
        */
     }
//--- starting calculation
   if(prev_calculated>1)
      pos=prev_calculated-1;
   else
      pos=0;
//--- main cycle:attenzione all'ordine della sequenza
   bool ok =false;
   CVolkBasePatternDetector* patt =new   CVolkBasePatternDetector();
   for(i=pos; i<rates_total && !IsStopped(); i++)
     {
      
       //  ExtMoving01Buffer[i]=NormalizeDouble(SimpleMA(i,Inp01Period,close),Digits);
       
       
       // DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],  Blue,STYLE_DOT,2,i);
       ok =false;
       if (TimeDayOfWeek(Time[rates_total-i-1])==0)
       {
       //  DrawSimbolSunday(Time[rates_total-i-1],high[rates_total-i-1],  Green,STYLE_DOT,0,i);
       }
        //condizioni ricerca pattern gemelli
       if ((patt.GetCandleBodySize(rates_total-i) !=0)&&(patt.GetCandleBodySize(rates_total-i-1) !=0))// perchè si avrebbe divisione per zero
       {
          double ratio=patt.GetCandleBodySize(rates_total-i-1)/patt.GetCandleBodySize(rates_total-i);
          double c=iClose(_Symbol, _Period, rates_total-i);
          double o=iOpen(_Symbol, _Period, rates_total-i-1);
          double bs=patt.GetCandleBodySize(rates_total-i-1);
          double uw=patt.UpperWick(rates_total-i-1)/bs;
          double lw=patt.LowerWick(rates_total-i-1)/bs;
          double uw1=patt.UpperWick(rates_total-i)/patt.GetCandleBodySize(rates_total-i);
          double lw1=patt.LowerWick(rates_total-i)/patt.GetCandleBodySize(rates_total-i);
         
          if(
               (bs*PIPFACTOR>30)&& //alemno 30 pip
               ((ratio >0.5) && (ratio <2)) && // non deve differire dalla precedente di 1/2
               (MathAbs(iClose(_Symbol, _Period, rates_total-i)-  iOpen(_Symbol, _Period, rates_total-i-1))*PIPFACTOR <=2)&&//apertura vicina alla chiusura della precedente
               ((patt.IsUp(rates_total-i-1)&& !patt.IsUp(rates_total-i))||(!patt.IsUp(rates_total-i-1)&& patt.IsUp(rates_total-i)))&&//segni discordi
               (uw < 0.95 && lw < 0.95 && uw1 < 0.95 && lw1 < 0.95)//code non troppo lunghe
             )
          {
           // Print(patt.GetCandleBodySize(i));
            ok=true;
          }
          
       }
       if (ok)
       {
         if (patt.IsUp(rates_total-i-1))
         {
            if(iHigh(_Symbol, _Period, rates_total-i-2)>iHigh(_Symbol, _Period, rates_total-i-1))
            {
               DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],  Red,STYLE_DOT,1,i);
               DrawLimits(rates_total-i-1,STYLE_DOT,1);
            }
            else
               DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],  Blue,STYLE_DOT,1,i);//non c'è sforamento del prezzo 
         }
         else
         {  if(iLow(_Symbol, _Period, rates_total-i-2)<iLow(_Symbol, _Period, rates_total-i-1))
            {
               DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],  Red,STYLE_DOT,0,i);
               DrawLimits(rates_total-i-1,STYLE_DOT,0);
            }
            else
               DrawSimbol(Time[rates_total-i-1],low[rates_total-i-1],  Blue,STYLE_DOT,0,i);//non c'è sforamento del prezzo 
         }
       }
      
      
     }
//---- OnCalculate done. Return new prev_calculated.
     return(rates_total);
  }




   void DrawSimbol(datetime x1,double y1,
                  color lineColor,double style,int direction,int idx)
  {
   int indicatorWindow=0;//WindowFind(indicatorName);
   if(indicatorWindow<0) return;
   bool created;

   string labelArrow="volkSign#"+DoubleToStr(x1,0)+"-"+DoubleToStr(y1,0);// IntegerToString(idx);  
  
   if(direction==1)//BUY
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1,0,0);
      ObjectSet(labelArrow,OBJPROP_COLOR,lineColor);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,SYMBOL_ARROWUP);
   }
   else if(direction==0)//SELL
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1);
      ObjectSet(labelArrow,OBJPROP_COLOR,lineColor);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,SYMBOL_ARROWDOWN);
   }
  
 
  }
  
  
  void DrawSimbolSunday(datetime x1,double y1,
                  color lineColor,double style,int direction,int idx)
  {
   int indicatorWindow=0;//WindowFind(indicatorName);
   if(indicatorWindow<0) return;
   bool created;

   string labelArrow="volkSign#"+DoubleToStr(x1,0)+"-"+DoubleToStr(y1,0);// IntegerToString(idx);  
  
   if(direction==1)//BUY
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1,0,0);
      ObjectSet(labelArrow,OBJPROP_COLOR,lineColor);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,SYMBOL_STOPSIGN);
   }
   else if(direction==0)//SELL
   {
      created=ObjectCreate(labelArrow,OBJ_ARROW,indicatorWindow,x1,y1);
      ObjectSet(labelArrow,OBJPROP_COLOR,lineColor);
      ObjectSet(labelArrow,OBJPROP_ARROWCODE,SYMBOL_STOPSIGN);
   }
  
 
  }
  
  
  
  int ClearObjs()
  {
   for(int i=ObjectsTotal()-1; i>=0; i--)
     {
      string label=ObjectName(i);
      if((StringSubstr(label,0,3)=="lb#")||(StringSubstr(label,0,7)=="volkSL#")||(StringSubstr(label,0,7)=="volkTP#")||(StringSubstr(label,0,7)=="volkEN#")||(StringSubstr(label,0,9)=="volkSign#") )     
       ObjectDelete(label);
     }
   return(0);
  }
  
  void DrawLimits(int idx,double style,int direction)
  {
   if (idx<1)
   {return;}
   int indicatorWindow=0;//WindowFind(indicatorName);
   if(indicatorWindow<0) return;
   bool created;
   double Entry;

   //string labelArrow="volkSign#"+DoubleToStr(x1,0)+"-"+DoubleToStr(y1,0);// IntegerToString(idx);  

   //CChartObjectArrowLeftPrice arrPointerLotsSL;
   lbInfo.Create(0,"lb#"+ idx,0,Time[idx],iLow(_Symbol, _Period,idx)-0.001);
   //lbInfo.Description(TimeToStr( Time[idx-1], TIME_DATE ));
   lbInfo.Description(StringConcatenate(TimeDay(Time[idx-1]),"/",TimeMonth(Time[idx-1]),"/",TimeYear(Time[idx-1])));
   lbInfo.Color(clrGreen);
   lbInfo.Corner(CORNER_LEFT_LOWER);
   lbInfo.Z_Order(999);
  
   if (handle>0)
   { 
    FileWrite(handle,StringConcatenate(TimeDay(Time[idx]),"/",TimeMonth(Time[idx]),"/",TimeYear(Time[idx])),iLow(_Symbol, _Period,idx),iHigh(_Symbol, _Period,idx));

   }
   if(direction==1)//BUY
   {
      Entry=iHigh(_Symbol, _Period,idx);
   //SL
      arrPointerSL.Create(0,"volkSL#" + idx,0,Time[idx],Entry-(Entry-iLow(_Symbol, _Period,idx))*PercSL);
      arrPointerSL.Description("?");
      arrPointerSL.Z_Order(100);
      arrPointerSL.Selectable(true);
      arrPointerSL.Selected(false);
      arrPointerSL.Tooltip("???");
      arrPointerSL.Color(clrRed);
   //TP
      //arrPointerTP.Create(0,"volkTP#" + idx,0,Time[idx],2*iHigh(_Symbol, _Period,idx)-iLow(_Symbol, _Period,idx));
      arrPointerTP.Create(0,"volkTP#" + idx,0,Time[idx],Entry+(Entry-iLow(_Symbol, _Period,idx))*PercTP);
      arrPointerTP.Description("?");
      arrPointerTP.Z_Order(100);
      arrPointerTP.Selectable(true);
      arrPointerTP.Selected(false);
      arrPointerTP.Tooltip("???");
      arrPointerTP.Color(clrGreen);
   //OPEN
      arrPointerEN.Create(0,"volkEN#" + idx,0,Time[idx],Entry);
      arrPointerEN.Description("?");
      arrPointerEN.Z_Order(100);
      arrPointerEN.Selectable(true);
      arrPointerEN.Selected(false);
      arrPointerEN.Tooltip("???");
      arrPointerEN.Color(clrBlack);   
   }
   else if(direction==0)//SELL
   {
      Entry=iLow(_Symbol, _Period,idx);
    //SL  
      arrPointerSL.Create(0,"volkSL#" + idx,0,Time[idx],Entry + (iHigh(_Symbol, _Period,idx)-Entry)*PercSL);
      arrPointerSL.Description("?");
      arrPointerSL.Z_Order(100);
      arrPointerSL.Selectable(true);
      arrPointerSL.Selected(false);
      arrPointerSL.Tooltip("???");
      arrPointerSL.Color(clrRed);
     // arrPointerLotsSL.Time(0 ,Time[idx]);
     // arrPointerLotsSL.Price(0,
    
    //TP 
      arrPointerTP.Create(0,"volkTP#" + idx,0,Time[idx],Entry-(iHigh(_Symbol, _Period,idx)-Entry)*PercTP);
      arrPointerTP.Description("?");
      arrPointerTP.Z_Order(100);
      arrPointerTP.Selectable(true);
      arrPointerTP.Selected(false);
      arrPointerTP.Tooltip("???");
      arrPointerTP.Color(clrGreen);
      
    //OPEN
      arrPointerEN.Create(0,"volkEN#" + idx,0,Time[idx],Entry);
      arrPointerEN.Description("?");
      arrPointerEN.Z_Order(100);
      arrPointerEN.Selectable(true);
      arrPointerEN.Selected(false);
      arrPointerEN.Tooltip("???");
      arrPointerEN.Color(clrBlack);   
   }
  
 
  }
  
  
