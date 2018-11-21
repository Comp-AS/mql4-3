//+------------------------------------------------------------------+
//|                                     volk_basePatternDetector.mqh |
//|                                                             volk |
//|                                                   www.volk.cloud |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      "www.volk.cloud"
#property strict

#include <IVolkPatternDetector.mqh>;
class CVolkBasePatternDetector : public IVolkPatternDetector
{
protected:   
   int    _period;
   string _symbol;
   
  
   
   
   //+------------------------------------------------------------------+
   int SpaceLeft(int bar)
   {
     double lowerWick = LowerWick(bar);
     double upperWick = UpperWick(bar);
     int cnt=0;
     for (int i=1; i < 20;++i)
     {
        if (upperWick > lowerWick)
        {
          if (iHigh(_symbol, _period, bar+i) < iHigh(_symbol, _period, bar)) cnt++;
          else break;
        }
        else
        {
          if (iLow(_symbol, _period, bar+i) > iLow(_symbol, _period, bar)) cnt++;
          else break;
        }
     }
     
     return cnt;
   }
   
   //+------------------------------------------------------------------+
   bool IsLargeCandle(int bar)
   {
      double body = GetCandleBodySize(bar);
      
      double cnt     = 0;
      double barSize = 0;
      for (int i=1; i < 100;++i)
      {
         barSize += GetCandleBodySize(bar+i);
         cnt++;
      }
      double avgBarSize = barSize / cnt;
      return (body >= avgBarSize);
   }
   
public: 
 //+------------------------------------------------------------------+
   bool IsUp(int bar)
   {
     return iClose(_symbol, _period, bar) >= iOpen(_symbol, _period, bar);
   }
   
   //+------------------------------------------------------------------+
   double UpperWick(int bar)
   {
      double upperBody = MathMax(iClose(_symbol, _period, bar), iOpen(_symbol, _period, bar));
      return iHigh(_symbol, _period, bar) - upperBody;
   }
   
   //+------------------------------------------------------------------+
   double LowerWick(int bar)
   {
      double lowerBody = MathMin(iClose(_symbol, _period, bar), iOpen(_symbol, _period, bar));
      return lowerBody - iLow(_symbol, _period, bar);
   }
   
   //+------------------------------------------------------------------+
   double GetCandleRangeSize(int bar)
   {
      return MathAbs(iHigh(_symbol, _period, bar) - iLow(_symbol, _period, bar));
   }
   
   //+------------------------------------------------------------------+
   double GetCandleBodySize(int bar)
   {
   //Print(iClose(_symbol, _period, bar) - iOpen(_symbol, _period, bar));
      return MathAbs(iClose(_symbol, _period, bar) - iOpen(_symbol, _period, bar));
   }
   //+------------------------------------------------------------------+
   CVolkBasePatternDetector()
   {
      _symbol = _Symbol;
      _period = _Period;
   }
   
   //+------------------------------------------------------------------+
   virtual bool IsValid(string symbol, int period, int bar)
   {
      _symbol = symbol;
      _period = period;
      return false;
   }
   
   //+------------------------------------------------------------------+
   virtual string PatternName()
   {
      return "";
   }
   
   //+------------------------------------------------------------------+
   virtual color PatternColor()
   {
      return Yellow;
   }
   
   //+------------------------------------------------------------------+
   virtual bool IsBackground()
   {
      return false;
   }
   
   //+------------------------------------------------------------------+
   virtual int BarCount()
   {
      return 1;
   }
};