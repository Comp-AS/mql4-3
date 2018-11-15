
#property copyright "Coders Guru"
#property link      "http://www.xpworx.com"
#property show_inputs

extern int  DistancePips = 10;


int start()
{
   double mPoint = GetPoint();
   DrawHorizontalLine("horz1",Close[0],Blue);
   DrawHorizontalLine("horz2",Close[0]+DistancePips*mPoint,Red);
   DrawHorizontalLine("horz3",Close[0]-DistancePips*mPoint,Red);
   return(0);
}

double GetPoint(string symbol = "")
{
   if(symbol=="" || symbol == Symbol())
   {
      if(Point==0.00001) return(0.0001);
      else if(Point==0.001) return(0.01);
      else return(Point);
   }
   else
   {
      RefreshRates();
      double tPoint = MarketInfo(symbol,MODE_POINT);
      if(tPoint==0.00001) return(0.0001);
      else if(tPoint==0.001) return(0.01);
      else return(tPoint);
   }
}

void DrawHorizontalLine(string name , double price , color clr, int width = 2, int style = STYLE_SOLID)
{
   if(ObjectFind(name)==-1)
   {
      ObjectCreate(name,OBJ_HLINE,0,0,price);
      ObjectSet(name,OBJPROP_COLOR,clr);
      ObjectSet(name,OBJPROP_STYLE,style);
      ObjectSet(name,OBJPROP_WIDTH,width);
      WindowRedraw();
   }
   else
   {
      ObjectSet(name,OBJPROP_TIME1,0);
      ObjectSet(name,OBJPROP_PRICE1,price);
      ObjectSet(name,OBJPROP_COLOR,clr);
      ObjectSet(name,OBJPROP_STYLE,style);
      ObjectSet(name,OBJPROP_WIDTH,width);
      WindowRedraw();
   }
}