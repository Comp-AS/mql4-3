//+------------------------------------------------------------------+
//|                                                  volk_orders.mq4 |
//|                                                             volk |
//|                                                   www.volk.cloud |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      "www.volk.cloud"
#property version   "1.00"
#property strict
#property description "EA di posizionamento ordini(per back test)"

//--- input parameters
input int         MagicNumber=99;
input double      LotSize=1;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  // if(IsTesting())
     {
      string name;
      string heading[4]={"Buy","Sell","Stop","TP"};
      int xc=5;
      int yc=30;
      for(int i=0;i<2;i++)
        {
         name=heading[i];
         ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
         ObjectSetText(name,name,10,"Arial",clrBlue);
         ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xc);
         ObjectSetInteger(0,name,OBJPROP_YDISTANCE,yc);
         yc+=20;
        }
      for(int i=2;i<4;i++)
        {
         name=heading[i];
         ObjectCreate(0,name,OBJ_LABEL,0,0,0);
         ObjectSetText(name,name,10,"Arial",clrBlue);
         ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xc);
         ObjectSetInteger(0,name,OBJPROP_YDISTANCE,yc);
         ObjectSetInteger(0,name,OBJPROP_SELECTED,false);
         yc+=20;
        }
      name="EditSL";
      ObjectCreate(0,name,OBJ_EDIT,0,0,0);
      ObjectSetText(name,DoubleToStr(0,Digits),10,"Arial",clrRed);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xc+50);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,70);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,60);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
      name="EditTP";
      ObjectCreate(0,name,OBJ_EDIT,0,0,0);
      ObjectSetText(name,DoubleToStr(0,Digits),10,"Arial",clrRed);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,xc+50);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,90);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,60);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
 //  if(IsTesting())
     {
      string name="Buy";
      if(ObjectGetInteger(0,name,OBJPROP_STATE)==true)
        {
         ObjectSetInteger(0,name,OBJPROP_STATE,false);
         double sl=StrToDouble(ObjectGetString(0,"EditSL",OBJPROP_TEXT));
         double tp=StrToDouble(ObjectGetString(0,"EditTP",OBJPROP_TEXT));
         int ticket=OrderSend(Symbol(),OP_BUY,LotSize,Ask,50,sl,tp,NULL,MagicNumber,0,clrNONE);
         if(ticket > 0)
           {
             
           }
           else
           {
               Print("Error Opening OPEN Order: ", GetLastError());
          
           } 
        }
      name="Sell";
      if(ObjectGetInteger(0,name,OBJPROP_STATE)==true)
        {
         ObjectSetInteger(0,name,OBJPROP_STATE,false);
         double sl=StrToDouble(ObjectGetString(0,"EditSL",OBJPROP_TEXT));
         double tp=StrToDouble(ObjectGetString(0,"EditTP",OBJPROP_TEXT));
         int ticket=OrderSend(Symbol(),OP_SELL,LotSize,Ask,50,sl,tp,NULL,MagicNumber,0,clrNONE);
        }
     }
//---
  }

