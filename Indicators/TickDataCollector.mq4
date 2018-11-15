//+------------------------------------------------------------------+
//|                                             PriceQtIndicator.mq4 |
//|                                                             linx |
//|                             https://login.mql5.com/en/users/linx |
//+------------------------------------------------------------------+
#property copyright "linx"
#property link      "https://login.mql5.com/en/users/linx"

string symbol;
int handle;

#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   symbol = Symbol();
   
  // handle=FileOpen(symbol+"_tick.csv", FILE_CSV|FILE_WRITE,',');
  /* handle=FileOpen(symbol+"_tick.csv", FILE_CSV|FILE_WRITE,',');
   if (handle>0)
      FileWrite(handle, "datatime", "open", "high", "low", "close", "volume");
   else
      Alert("Failed to open data file. Please check if you have write priviledge!");
*/
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   if (handle>0)
      FileClose(handle);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   //int    counted_bars=IndicatorCounted();
//----
  /* if (handle>0) {
      FileWrite(handle,iTime(symbol,PERIOD_M1,0), iOpen(symbol,PERIOD_M1,0),
                       iHigh(symbol,PERIOD_M1,0), iLow(symbol,PERIOD_M1,0),
                       iClose(symbol,PERIOD_M1,0), iVolume(symbol,PERIOD_M1,0));
   }
   */
    Alert(iTime(symbol,PERIOD_M1,0)+ " ", iOpen(symbol,PERIOD_M1,0)+ " ",                  
                       iClose(symbol,PERIOD_M1,0)+ " ", iVolume(symbol,PERIOD_M1,0));
					   
	//181004 questo preso dal web ma non ancora testato:eventualmente gestire errori				   
  if(SymbolInfoTick(Symbol(), tick_struct))
      {
         Comment("\n[Darwinex Labs] Tick Data | Bid: " + DoubleToString(tick_struct.bid, 5) 
         + " | Ask: " + DoubleToString(tick_struct.ask, 5) 
         + " | Spread: " + StringFormat("%.05f", NormalizeDouble(MathAbs(tick_struct.bid - tick_struct.ask), 5))
         + "\n\n* Writing tick data to \\MQL4\\Files\\" + fileName
         + "\n(please remove the indicator from this chart to access CSV under \\MQL4\\Files.)"
         );
         FileWrite(csv_io_hnd, tick_struct.time_msc, tick_struct.bid,
                       tick_struct.ask, StringFormat("%.05f", NormalizeDouble(MathAbs(tick_struct.bid - tick_struct.ask), 5)));
                       
         // 11-04-2018: Close file handle so it's accessible to other processes.
         FileClose(csv_io_hnd);
      } 
      else
		Print("ERROR: SymbolInfoTick() failed to validate tick."); 					   
//----
   return(0);
  }
//+------------------------------------------------------------------+