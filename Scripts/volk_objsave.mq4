//+------------------------------------------------------------------+
//|                                                 volk_objsave.mq4 |
//|                                                             volk |
//|                                                   www.volk.cloud |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      "www.volk.cloud"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
input string             InpFileName="Trendline.csv";      // File name
input string             InpDirectoryName="Data";     // Folder name

void OnStart()
  {
//---
  int TotalObject;
  TotalObject = ObjectsTotal(0,0,-1);

  int file_handle=FileOpen(InpDirectoryName+"//"+InpFileName,FILE_READ|FILE_WRITE|FILE_CSV);
  if(file_handle!=INVALID_HANDLE)
  {
     
     
     for(int i=TotalObject;i>=0;i--) 
         {
            if(ObjectType(ObjectName(i))==OBJ_TREND)
            {
               
               double p1=ObjectGetDouble(0,ObjectName(i),OBJPROP_PRICE1,0);
               double p2=ObjectGetDouble(0,ObjectName(i),OBJPROP_PRICE2,0);
               datetime d1=ObjectGet(ObjectName(i),OBJPROP_TIME1);
               datetime d2=ObjectGet(ObjectName(i),OBJPROP_TIME2);
               Print("... --> " +ObjectName(i) +" " + DoubleToString(p1,4) + " " + TimeToString(d1) ) ; 
               FileWrite(file_handle,ObjectName(i) , DoubleToString(p1,4));
            }
         } 
      FileClose(file_handle);
   }
    
  }
//+------------------------------------------------------------------+
