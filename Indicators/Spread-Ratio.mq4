//+---------------------------------------------------------------------------+
//|Spread_Ratio_Universoforex mq4                                             | 
//|Calcola lo spread ratio tra due asset                                      | 
//|http://www.universoforex.it                                                |
//+---------------------------------------------------------------------------+
#property copyright "Copyright © 2018, Universoforex" 
#property link "http://www.universoforex.it"
#property description "Spread Ratio Curve"

#include <stdlib.mqh>

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 DarkOrange
#property indicator_width1 2
//--- indicator parameters
string sSymbol1 = "this";               //symbol 1 è l grafico principale attualmente attivo
extern string sSymbol2 = "EURUSD";      //symbol 2 è quello che vogliamo confrontare
extern string sAddSubtractDivide = "d"; //a=add, s=subtract, d=divide
extern bool bInvertSymbol2 = false;     
extern bool bWriteLogFile = false;      

string sLineOut = "x";
int iFileHandle = 0;
int iError = 0;
bool bRtn = false;
bool bFirst=True;
int prevPeriod=0;
int initBars=0;
int prevBars=0;
int iRtn=0;
double dSprdVal[];
double dClose1=0;
double dClose2=0;
double dClose2Prev=0;
datetime dtSaveLastTime=0;

int init()
{
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,1);
   SetIndexBuffer(0,dSprdVal);
   SetIndexLabel(0,"sprd");
   return(0);
}

int deinit()
{
   return(0);
}

int start()
{
   //Initialize
   if(Period() != prevPeriod) {
      prevPeriod = Period();
      bFirst = True;
   }
   if(IndicatorCounted() == 0) bFirst = True;

   if(bFirst == True) {
      sSymbol1 = Symbol();
      string sTitleHeader = "(SpreadRatio, " + sSymbol1;
      if(sAddSubtractDivide == "a" ) sTitleHeader = sTitleHeader + "+";
      if(sAddSubtractDivide == "s" ) sTitleHeader = sTitleHeader + "-";
      if(sAddSubtractDivide == "d" ) sTitleHeader = sTitleHeader + "/";
      sTitleHeader = sTitleHeader + sSymbol2;
      if(bInvertSymbol2 == true) sTitleHeader = sTitleHeader + " inverted";
      sTitleHeader = sTitleHeader + ")";
      IndicatorShortName(sTitleHeader);
      initBars = Bars;
      prevBars = Bars;
//backfill chart with historical bars
      int kklmt = Bars-20;   
      for(int kk=kklmt; kk>=0; kk--) {
         iRtn = fctCalcSpread(kk);
      }
      bFirst = False;
   }
   //Initialize End
   //
   //All bars (full and tick)
   if(Bars <= initBars) return;           
   if(Bars == prevBars) {              
      
   }
   else {                              
         
      iRtn = fctCalcSpread(1);
   }
   prevBars = Bars;
   return(0);
} 
////////////////////
int fctCalcSpread(int i)
{
   dClose1 = Close[i];
   int iBarThis = iBarShift(sSymbol2,0,Time[i],true);
   if(iBarThis == -1)             
      { dClose2 = dClose2Prev; }  
   else
   {
      dClose2 = iClose(sSymbol2,0,iBarThis);
      if( !( (dClose2 > 0) && (dClose2 < 2147483000.0) ) )   
         { dClose2 = dClose2Prev; }  
   }     
   if(dClose2 > 0)
   {
      if(bInvertSymbol2 == true) dClose2 = (1.0 / dClose2);
      if(sAddSubtractDivide == "a") dSprdVal[i] = dClose1 + dClose2;
      if(sAddSubtractDivide == "s") dSprdVal[i] = dClose1 - dClose2;
      if(sAddSubtractDivide == "d") dSprdVal[i] = dClose1 / dClose2;
      if(dtSaveLastTime != Time[i]) 
      {
         sLineOut = TimeToStr(Time[i], TIME_DATE|TIME_SECONDS) + ", " ;
         sLineOut = sLineOut + DoubleToStr(dClose1,5) + ", " + DoubleToStr(dClose2,5) + ", " + DoubleToStr(dSprdVal[i],5);
         fctLogAction(sLineOut);
      }
      dtSaveLastTime = Time[i];
   }
   if(dClose2 > 0) 
      {  dClose2Prev = dClose2; }
   return(0);
}  
////////////////////
void fctLogAction(string psLineOut)
{
   static bool bFirstTime = true;
   if(bWriteLogFile == false) return;
   string sFileName = StringConcatenate("SpreadRatioLog\\", sSymbol1, "_", sSymbol2, "_", Period(), ".csv");
   if( bFirstTime == true)
   {
      bFirstTime = false;
      FileDelete(sFileName);
   }
   iFileHandle = FileOpen(sFileName, FILE_READ|FILE_WRITE|FILE_CSV, ";");
   bRtn = FileSeek(iFileHandle, 0, SEEK_END);
   if(bRtn == false)
   {
      iError=GetLastError();
      Print("Error of file open/seek, ", iError , ErrorDescription(iError));
      return;
   }
   FileWrite(iFileHandle, psLineOut);   
   FileClose(iFileHandle);
   return;
}
//+------------------------------------------------------------------+
