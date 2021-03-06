#property show_inputs
//#property show_confirm
#property description "drop sul prezzo dove fare pending"
#property version   "1.00"

double Lots    = 0.0;
bool showAlerts =true;
extern int Slippage   = 3;
extern int Stop_Loss  = 25;
extern int Take_Profit = 30;
extern string CommentString ="volk_pending";
#define MAGICNUM  2712793
input double Risk=1;//% on equity

//+------------------------------------------------------------------+
//| script                                     |
//+------------------------------------------------------------------+
int start()
  {
   double Price = WindowPriceOnDropped();
   bool   result;
   int    cmd,total,error,slippage;
   
//----
   int NrOfDigits = MarketInfo(Symbol(),MODE_DIGITS);   // Nr. of decimals used by Symbol
   int PipAdjust;                                       // Pips multiplier for value adjustment
      if(NrOfDigits == 5 || NrOfDigits == 3)            // If decimals = 5 or 3
         PipAdjust = 10;                                // Multiply pips by 10
         else
      if(NrOfDigits == 4 || NrOfDigits == 2)            // If digits = 4 or 3 (normal)
         PipAdjust = 1;            
//----   
   
   slippage = Slippage;// * PipAdjust; 
   
   double stop_loss = 0;//Price + Stop_Loss * Point * PipAdjust;
   double take_profit =0;// Price - Take_Profit * Point * PipAdjust; 
   datetime expire = TimeCurrent() + 60 * (1.5* 60);//1.5h 
   if(Bid > Price)
   {
      stop_loss = Price + Stop_Loss * Point * PipAdjust;
      take_profit = Price - Take_Profit * Point * PipAdjust;  
      Print(GetLots(Price,stop_loss,OP_SELLSTOP)," prezzo ",Price," slippage ",slippage," SL ",stop_loss," tp ",take_profit);    
      result = OrderSend(Symbol(),OP_SELLSTOP,GetLots(Price,stop_loss,OP_SELLSTOP),Price,slippage,stop_loss,take_profit,CommentString, MAGICNUM,expire,clrRed);
   }
   if(Bid < Price)
   {
      stop_loss = Price - Stop_Loss * Point * PipAdjust;
      take_profit = Price + Take_Profit * Point * PipAdjust;    
      result = OrderSend(Symbol(),OP_BUYSTOP,GetLots(Price,stop_loss,OP_BUYSTOP),Price,slippage,stop_loss,take_profit,CommentString,MAGICNUM,expire,clrGreen);
   }
   
  if(result > 0)
  {
    if(OrderSelect(result, SELECT_BY_TICKET, MODE_TRADES))
    {
      Print("*** Order Opened: ", OrderOpenPrice());
    }
    else
    {
      Print("*** Error Opening Order: ", GetLastError());
      return(1);
    }
  }
//----
   return(0);
  }
//+------------------------------------------------------------------+

double GetLots(double price,double priceSL,int orderType)
{

   double local_availablemoney;
	double local_lotsize;
	int local_lotdigit;
	string local_appendix;  // local string variable used for possible currency pair appendix
	int local_length;  // local integer variable to store length of the currency pair string
   //double multiplicator;      // Multiplicator for lot size based on Account Currency
   double tick_val;
   double local_max_expos;
   double stoplevel=MarketInfo(_Symbol,MODE_STOPLEVEL)*Point;
   //Alert(_Symbol,stoplevel);
//   if(stoplevel<=0) 
//      stoplevel=1000;
      
   switch (orderType)
   {
      case OP_BUY:
         if (price <stoplevel+priceSL)
            return(-1);
      break;
      case OP_SELL:
        if (price >-stoplevel+priceSL)
            return(-1);     
      break;
   
   }
  
	local_lotdigit = 2;

   local_length = StringLen(Symbol());
	local_appendix = "";
	//multiplicator=0;
	tick_val=0;
	
	if (local_length != 6)
		local_appendix = StringSubstr(Symbol(),6,local_length - 6);
 
  if (AccountCurrency() != "EUR")
  {
   if (showAlerts)
      Alert("Conto solo in €");
   return(0);
  } 
  tick_val=MarketInfo(_Symbol,MODE_TICKVALUE)/_Point;
  //multiplicator = 1.0 / MarketInfo("EURUSD" + local_appendix, MODE_BID);
   if (((price-priceSL)*tick_val)==0)
   {
     if (showAlerts)
      Alert("Price ",price," SL ",priceSL," Tick ",tick_val);
     return(0);

   }
	// Get available money as Equity
	local_availablemoney = AccountBalance();
	local_max_expos=local_availablemoney*Risk/100;
	local_lotsize =local_max_expos/((price-priceSL)*tick_val);// MathMin(MathFloor(Risk / 102 * local_availablemoney / (StopLoss + AddPriceGap) / lotstep) * lotstep, MaxLots);
   local_lotsize = MathAbs(local_lotsize ); 
   
   if (local_lotsize < MarketInfo(Symbol(), MODE_MINLOT)/2)
		 local_lotsize = 0;
   else if (local_lotsize < MarketInfo(Symbol(), MODE_MINLOT))
		   local_lotsize = MarketInfo(Symbol(), MODE_MINLOT);//lascia un margine di tolleranza
	local_lotsize = NormalizeDouble(local_lotsize, local_lotdigit);


		
	return (local_lotsize);
}