//+------------------------------------------------------------------+
//|                                      s-Downloader (SingleTF).mq4 |
//|                                        Copyright © 2018, Amr Ali |
//|                             https://www.mql5.com/en/users/amrali |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Amr Ali"
#property link      "https://www.mql5.com/en/users/amrali"
#property version   "1.000"
#property description "The script downloads the historical quote data of the current chart symbol and timeframe."
#property description "This is convenient to conduct more backtesting on a single TF that you usually work with."
#property description " "
#property description "How to use:"
#property description "- Launch the script on the target symbol and timeframe to download its historical data."
#property description "- When terminal is restarted later, historical data are automatically flushed to disk."
#property strict
#property script_show_inputs

// The method of emulating "pressing Home button" is based on the idea implemented in
// the s-Downloader of Talex script (CodeBase link). https://www.mql5.com/en/code/9099

#include <WinUser32.mqh>

#define VK_HOME            0x24
#define VK_END             0x23

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
void start()
  {
   if(MQLInfoInteger(MQL_DLLS_ALLOWED)==false)
     {
      Alert("Error, DLL imports is not allowed in the program settings.");
      return;
     }

   DownloadHomeKey();
  }

//+------------------------------------------------------------------------------+
//| DownloadHomeKey()                                                            |
//| Purpose:                                                                     |
//|    Download historical data for the current chart symbol and TF by emulating |
//|    pressing the HOME button                                                  |
//+------------------------------------------------------------------------------+
void DownloadHomeKey()
  {
   long max_bars,init_bars,bars=0;
   datetime first_date,server_first_date;

//--- max bars in chart from terminal options
   max_bars=TerminalInfoInteger(TERMINAL_MAXBARS);

   init_bars=SeriesInfoInteger(NULL,0,SERIES_BARS_COUNT);
   first_date=(datetime)SeriesInfoInteger(NULL,0,SERIES_FIRSTDATE);
   server_first_date=(datetime)SeriesInfoInteger(NULL,0,SERIES_SERVER_FIRSTDATE);

//--- output found dates to terminal log
   Print("first date on chart=",first_date);
   Print("first date on server=",server_first_date);

//+------------------------------------------------------------------+
//| https://docs.mql4.com/constants/chartconstants/charts_samples    |
//+------------------------------------------------------------------+
   ChartSetInteger(0,CHART_SCALE,0); // zoom out to zero
   ChartSetInteger(0,CHART_AUTOSCROLL,false); // disable scrolling

   string status_msg=" (all server data synchronized successfully)";

   int handlechart=WindowHandle(_Symbol,_Period);
   while(!IsStopped())
     {
      //--- check if data are present
      //		bars = iBars(_Symbol, _Period);
      bars=SeriesInfoInteger(NULL,0,SERIES_BARS_COUNT);
      if(bars>0)
        {
         //--- ask for first date
         first_date=(datetime)SeriesInfoInteger(NULL,0,SERIES_FIRSTDATE);
         if(first_date>0 && first_date<=server_first_date) break;;
         //--- check for max bars
         if(bars>=max_bars)
           {
            status_msg=" (Hint: Options -> Chart -> increase 'Max bars in chart', and restart terminal)";
            break;
           }
        }

      //--- data are not present, force data download
      PostMessageW(handlechart,WM_KEYDOWN,VK_HOME,0); // press HOME
      Sleep(200);
     }

   PostMessageW(handlechart,WM_KEYDOWN,VK_END,0); // press END
   ChartSetInteger(0,CHART_AUTOSCROLL,true); // enable scrolling

   Alert(_Symbol,": first date on chart=",first_date,", downloaded ",bars-init_bars," bars",status_msg);
  }
//+------------------------------------------------------------------+
