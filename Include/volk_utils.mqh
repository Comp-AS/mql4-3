//+------------------------------------------------------------------+
//|                                                   volk_utils.mqh |
//|                                                             volk |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "volk"
#property link      ""
#property strict
#property version   "1.02"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

enum OrderPreference
{
   OPB=1,//Buy
   OPS=2,//Sell
   OPBS=3 //Buy + Sell
};
enum OrderPreference2
{
   OP2B=1,//Buy
   OP2S=2//Sell

};
double volk_GetLotSize(double price,double priceSL,int orderType,double risk)
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
   
	//if(lotstep == 1) 
	//	local_lotdigit = 0;
	//if(lotstep == 0.1)	
	//	local_lotdigit = 1;
   //if(lotstep == 0.01) 
	local_lotdigit = 2;

   local_length = StringLen(Symbol());
	local_appendix = "";
	//multiplicator=0;
	tick_val=0;
	
	if (local_length != 6)
		local_appendix = StringSubstr(Symbol(),6,local_length - 6);
  /* if (AccountCurrency() == "EUR") 
		multiplicator = 1.0 / MarketInfo("EURUSD" + local_appendix, MODE_BID);
   if (AccountCurrency() == "GBP") 
		multiplicator = 1.0 / MarketInfo("GBPUSD" + local_appendix, MODE_BID);
   if (AccountCurrency() == "CHF") 
		multiplicator = MarketInfo("USDCHF" + local_appendix, MODE_BID);
   if (AccountCurrency() == "JPY") 
		multiplicator = MarketInfo("USDJPY" + local_appendix, MODE_BID);
   if (multiplicator == 0)
   	multiplicator = 1.0; // If account currency is neither of EUR,GBP,CHF or JPY we assumes that it is USD
*/
  if (AccountCurrency() != "EUR")
  {
  // if (showAlerts)
  //    Alert("Conto solo in €");
   return(0);
  } 
  tick_val=MarketInfo(_Symbol,MODE_TICKVALUE);
  tick_val=tick_val/_Point;
  
  //multiplicator = 1.0 / MarketInfo("EURUSD" + local_appendix, MODE_BID);
   if (((price-priceSL)*tick_val)==0)
   {
    // if (showAlerts)
    //  Alert("Price ",price," SL ",priceSL," Tick ",tick_val);
     return(0);

   }
	// Get available money as Equity
	local_availablemoney = AccountBalance();
	local_max_expos=local_availablemoney*risk/100;
	local_lotsize =local_max_expos/((price-priceSL)*tick_val);// MathMin(MathFloor(Risk / 102 * local_availablemoney / (StopLoss + AddPriceGap) / lotstep) * lotstep, MaxLots);
   local_lotsize = MathAbs(local_lotsize ); 
   
 //  if (local_lotsize < MarketInfo(Symbol(), MODE_MINLOT)/2)
 // 		 local_lotsize = 0;
 //  else if (local_lotsize < MarketInfo(Symbol(), MODE_MINLOT))
 //		   local_lotsize = MarketInfo(Symbol(), MODE_MINLOT);//lascia un margine di tolleranza
   if (local_lotsize < MarketInfo(Symbol(), MODE_MINLOT))//180403 non lascia più la tolleranza
  		 local_lotsize = 0;
	local_lotsize = NormalizeDouble(local_lotsize, local_lotdigit);


		
	return (local_lotsize);
}