//+------------------------------------------------------------------+
//|                                         IvolkPatternDetector.mqh |
//|                                                             volk |
//|                                                   www.volk.cloud |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      "www.volk.cloud"
#property strict

interface IVolkPatternDetector
{
   bool   IsValid(string symbol,int period, int bar);
   string PatternName();
   color  PatternColor();
   bool   IsBackground();
   int    BarCount();
};