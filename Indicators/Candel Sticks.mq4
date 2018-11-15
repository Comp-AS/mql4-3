#property indicator_chart_window 
#property indicator_buffers 2 
#property indicator_color1 Red 
#property indicator_color2 Blue 
int limit;
//---- buffers 
double ExtMapBuffer1[]; 
double ExtMapBuffer2[]; 
string PatternText[200000];
//+------------------------------------------------------------------+ 
//| CuStom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int init() 
  { 
//---- indicators 
   SetIndexStyle(0,DRAW_ARROW,EMPTY , 1, Red);
   SetIndexArrow(0,234); 
   SetIndexBuffer(0,ExtMapBuffer1); 
   
   SetIndexStyle(1,DRAW_ARROW,EMPTY , 1, Blue);
   SetIndexArrow(1,233); 
   SetIndexBuffer(1,ExtMapBuffer2); 
//---- 
   return(0); 
  } 
//+------------------------------------------------------------------+ 
//| CuStor indicator deinitialization function                       | 
//+------------------------------------------------------------------+ 
int deinit() 
  { 
//---- 
   // ObjectsDeleteAll(0,PatternText,0,OBJ_TEXT);
//---- 
   return(0); 
  } 
//+------------------------------------------------------------------+ 
//| CuStom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int start() 
  { 
  
   int N;
   int N1;
   int N2;
   int N3;
   int N4;
   string text;
   

  
  
 int counted_bars=IndicatorCounted();
     limit=Bars-counted_bars;
    
     
     
 for(N = 1; N < limit; N++) { 
    PatternText[N] = CharToStr(N);
   
      N1 = N + 1;
      N2 = N + 2;
      N3 = N + 3;
      N4 = N + 4; 
      
   
//----  
    //---- check for possible errors
   if(counted_bars<0) {
	  Alert("NO Bars..");
	  return(-1);
   }
   
// Check for a Bearish Engulfing pattern
  if (High[N4]<High[N3] && Low[N4]<Low[N3] && High[N3]<High[N2] && Low[N3]<Low[N2] && High[N2]<High[N1] && Low[N2]>Low[N1] && Open[N2]<Close[N2] && Open[N1]>Close[N1] && (Open[N1]-Close[N1])>(High[N1]-Low[N1])/3 && (Close[N2]-Open[N2])>(High[N2]-Low[N2])/3) {  
      ExtMapBuffer1[N1]=High[N1]; 
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], High[N1] + (Point * 12));
      ObjectSetText(PatternText[N1], "Bearish Engulfing", 9, "Times New Roman", Red);

   }   

// Check for a Dark Cloud Cover pattern  
  if (High[N4]<High[N3] && Low[N4]<Low[N3] && High[N3]<High[N2] && Low[N3]<Low[N2] && High[N2]<High[N1] && Low[N2]<Low[N1] && Open[N2]<Close[N2] && Open[N1]>Close[N1] && (Open[N1]-Close[N1])>(High[N1]-Low[N1])/3 && (Close[N2]-Open[N2])>(High[N2]-Low[N2])/3) {
      ExtMapBuffer1[N1]=High[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], High[N1] + (Point * 12));
      ObjectSetText(PatternText[N1], "Dark Cloud Cover", 9, "Times New Roman", Red);

   } 

// check for Hanging Man   
  if (High[N3]<High[N2] && Low[N3]<Low[N2] && High[N2]<High[N1] && Low[N2]<Low[N1] && Open[N1]>Close[N1] && (High[N1]-Open[N1])<=(High[N1]-Low[N1])/6 && (Open[N1]-Close[N1])<=(High[N1]-Low[N1])/3) {
      ExtMapBuffer1[N1]=High[N1];  
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], High[N1] + (Point * 12));
      ObjectSetText(PatternText[N1], "Hanging Man", 9, "Times New Roman", Red);
   }
   
  if (High[N3]<High[N2] && Low[N3]<Low[N2] && High[N2]<High[N1] && Low[N2]<Low[N1] && Open[N1]<Close[N1] && (High[N1]-Close[N1])<=(High[N1]-Low[N1])/6 && (Close[N1]-Open[N1])<=(High[N1]-Low[N1])/3) {     
      ExtMapBuffer1[N1]=High[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], High[N1] + (Point * 12));
      ObjectSetText(PatternText[N1], "Hanging Man", 9, "Times New Roman", Red);

   }
   
// Check for Inverted Hammer Up
  if (High[N3]<High[N2] && Low[N3]<Low[N2] && High[N2]<High[N1] && Low[N2]<Low[N1] && Close[N1]<Open[N1] && (Close[N1]-Low[N1])<= (High[N1]-Low[N1])/6 && (Open[N1]-Close[N1])<=(High[N1]-Low[N1])/3) {
      ExtMapBuffer1[N1]=High[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], High[N1] + (Point * 12));
      ObjectSetText(PatternText[N1], "Inverted Hammer Up", 9, "Times New Roman", Red);     
   } 
   
// Check for Shooting Star Up
  if (High[N3]<High[N2] && Low[N3]<Low[N2] && High[N2]<High[N1] && Low[N2]<Low[N1] && Close[N1]>Open[N1] && (Open[N1]-Low[N1])<= (High[N1]-Low[N1])/6 && (Close[N1]-Open[N1])<=(High[N1]-Low[N1])/3) {
      ExtMapBuffer1[N1]=High[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], High[N1] + (Point * 12));
      ObjectSetText(PatternText[N1], "Shooting Star Up", 9, "Times New Roman", Red);     
   }
   
//*********************************************************************************************************************************************************************************************************************************************************************************************************//            

// Check for a Bullish Engulfing pattern
  if (High[N4]>High[N3] && Low[N4]>Low[N3] && High[N3]>High[N2] && Low[N3]>Low[N2] && High[N2]<High[N1] && Low[N2]>Low[N1] && Open[N2]<Close[N2] && Open[N1]>Close[N1] && (Open[N1]-Close[N1])>(High[N1]-Low[N1])/3 && (Close[N2]-Open[N2])>(High[N2]-Low[N2])/3) {
      ExtMapBuffer2[N1]=Low[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], Low[N1] - Point);
      ObjectSetText(PatternText[N1], "Bullish Engulfing", 9, "Times New Roman", Blue);     
   }
   
// Check for a Pricing Pattern
  if (High[N4]>High[N3] && Low[N4]>Low[N3] && High[N3]>High[N2] && Low[N3]>Low[N2] && High[N2]>High[N1] && Low[N2]>Low[N1] && Open[N2]<Close[N2] && Open[N1]>Close[N1] && (Open[N1]-Close[N1])>(High[N1]-Low[N1])/3 && (Close[N2]-Open[N2])>(High[N2]-Low[N2])/3) {      
      ExtMapBuffer2[N1]=Low[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], Low[N1] - Point);
      ObjectSetText(PatternText[N1], "Pricing Pattern", 9, "Times New Roman", Blue);     
  
   }
   
// Check for Hammer
  if (High[N3]>High[N2] && Low[N3]>Low[N2] && High[N2]>High[N1] && Low[N2]>Low[N1] && Open[N1]>Close[N1] && (High[N1]-Open[N1])<= (High[N1]-Low[N1])/6 && (Open[N1]-Close[N1])<=(High[N1]-Low[N1])/3) {      
      ExtMapBuffer2[N1]=Low[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], Low[N1] - Point);
      ObjectSetText(PatternText[N1], "Hammer", 9, "Times New Roman", Blue);     

   }
   
  if (High[N3]>High[N2] && Low[N3]>Low[N2] && High[N2]>High[N1] && Low[N2]>Low[N1] && Open[N1]<Close[N1] && (High[N1]-Close[N1])<=(High[N1]-Low[N1])/6 && (Close[N1]-Open[N1])<=(High[N1]-Low[N1])/3) {      
      ExtMapBuffer2[N1]=Low[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], Low[N1] - Point);
      ObjectSetText(PatternText[N1], "Hammer", 9, "Times New Roman", Blue);        
   }
   
// Check for Shooting Star Down
  if (High[N3]>High[N2] && Low[N3]>Low[N2] && High[N2]>High[N1] && Low[N2]>Low[N1] && Close[N1]>Open[N1] && (Open[N1]-Low[N1])<= (High[N1]-Low[N1])/6 && (Close[N1]-Open[N1])<=(High[N1]-Low[N1])/3) {
      ExtMapBuffer2[N1]=Low[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], Low[N1] - Point);
      ObjectSetText(PatternText[N1], "Shooting Star Down", 9, "Times New Roman", Blue);        
   
   }
   
// Check for Inverted Hammer Down
   if (High[N3]>High[N2] && Low[N3]>Low[N2] && High[N2]>High[N1] && Low[N2]>Low[N1] && Open[N1]>Close[N1] && (Close[N1]-Low[N1])<= (High[N1]-Low[N1])/6 && (Open[N1]-Close[N1])<=(High[N1]-Low[N1])/3) {
       ExtMapBuffer2[N1]=Low[N1];
      ObjectCreate(PatternText[N1], OBJ_TEXT, 0, Time[N1], Low[N1] - Point);
      ObjectSetText(PatternText[N1], "Inverted Hammer Down", 9, "Times New Roman", Blue);   
   }
   
//----      
   } // End of for loop
   return(0); 
  }
 
//+------------------------------------------------------------------+ 

