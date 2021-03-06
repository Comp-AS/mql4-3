//+------------------------------------------------------------------+
//|                                                MarketProfile.mq4 |
//| 				                 Copyright © 2010-2018, EarnForex.com |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+

#property copyright "EarnForex.com"
#property link      "https://www.earnforex.com/metatrader-indicators/MarketProfile/"
#property version   "1.08"
#property strict
 
#property description "Displays the Market Profile indicator for intraday, daily, weekly, or monthly trading sessions."
#property description "Daily - should be attached to M5-M30 timeframes. M30 is recommended."
#property description "Weekly - should be attached to M30-H4 timeframes. H1 is recommended."
#property description "Weeks start on Sunday."
#property description "Monthly - should be attached to H1-D1 timeframes. H4 is recommended."
#property description "Intraday - should be attached to M1-M15 timeframes. M5 is recommended.\r\n"
#property description "Designed for major currency pairs, but should work also with exotic pairs, CFDs, or commodities."

#property indicator_chart_window
#property indicator_plots 0

enum color_scheme
{
   Blue_to_Red,
   Red_to_Green,
   Green_to_Blue,
   Yellow_to_Cyan,
   Magenta_to_Yellow,
   Cyan_to_Magenta,
   Single_Color
};

enum session_period
{
	Daily,
	Weekly,
	Monthly,
	Intraday
};

input session_period Session                 = Daily;
input datetime       StartFromDate           = __DATE__; // StartFromDate: lower priority.
input bool           StartFromCurrentSession = true;     // StartFromCurrentSession: higher priority.
input int            SessionsToCount         = 2;        // SessionsToCount: Number of sessions to count Market Profile.
input color_scheme   ColorScheme             = Blue_to_Red;
input color          SingleColor             = clrBlue;  // SingleColor: if ColorScheme is set to Single_Color.
input color          MedianColor             = clrWhite;
input color          ValueAreaColor          = clrWhite;
input bool           ShowValueAreaRays       = false;    // ShowValueAreaRays: draw previous value area high/low rays.
input bool           ShowMedianRays          = false;    // ShowMedianRays: draw previous median rays.
input int            TimeShiftMinutes        = 0;        // TimeShiftMinutes: shift session + to the left, - to the right.
input int            PointMultiplier         = 1;        // PointMultiplier: the higher it is, the fewer chart objects.
input int            ThrottleRedraw          = 0;        // ThrottleRedraw: delay (in secodns) for updating Market Profile.

input bool           EnableIntradaySession1      = true;
input string         IntradaySession1StartTime   = "00:00";
input string         IntradaySession1EndTime     = "06:00";
input color_scheme   IntradaySession1ColorScheme = Blue_to_Red;

input bool           EnableIntradaySession2      = true;
input string         IntradaySession2StartTime   = "06:00";
input string         IntradaySession2EndTime     = "12:00";
input color_scheme   IntradaySession2ColorScheme = Red_to_Green;

input bool           EnableIntradaySession3      = true;
input string         IntradaySession3StartTime   = "12:00";
input string         IntradaySession3EndTime     = "18:00";
input color_scheme   IntradaySession3ColorScheme = Green_to_Blue;

input bool           EnableIntradaySession4      = true;
input string         IntradaySession4StartTime   = "18:00";
input string         IntradaySession4EndTime     = "00:00";
input color_scheme   IntradaySession4ColorScheme = Yellow_to_Cyan;

int DigitsM; 					// Number of digits normalized based on TickMultiplier.
bool InitFailed;           // Used for soft INIT_FAILED. Hard INIT_FAILED resets input parameters.
datetime StartDate; 			// Will hold either StartFromDate or Time[0].
double onetick; 				// One normalized pip.
bool FirstRunDone = false; // If true - OnCalculate() was already executed once.
string Suffix = "";			// Will store object name suffix depending on timeframe.
color_scheme CurrentColorScheme; // Required due to intraday sessions.
int Max_number_of_bars_in_a_session = 1;
int Timer = 0; 			   // For throttling updates of market profiles in slow systems.

// For intraday sessions' start and end times.
int IDStartHours[4];
int IDStartMinutes[4];
int IDStartTime[4]; // Stores IDStartHours x 60 + IDStartMinutes for comparison purposes.
int IDEndHours[4];
int IDEndMinutes[4];
int IDEndTime[4]; // Stores IDEndHours x 60 + IDEndMinutes for comparison purposes.
color_scheme IDColorScheme[4];
bool IntradayCheckPassed = false;
int IntradaySessionCount = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
	InitFailed = false;
	
	if (Session == Daily)
	{
		Suffix = "_D";
		if ((Period() < PERIOD_M5) || (Period() > PERIOD_M30))
		{
			Alert("Timeframe should be between M5 and M30 for a Daily session.");
			InitFailed = true; // Soft INIT_FAILED.
		}
	}
	else if (Session == Weekly)
	{
		Suffix = "_W";
		if ((Period() < PERIOD_M30) || (Period() > PERIOD_H4))
		{
			Alert("Timeframe should be between M30 and H4 for a Weekly session.");
			InitFailed = true; // Soft INIT_FAILED.
		}
	}
	else if (Session == Monthly)
	{
		Suffix = "_M";
		if ((Period() < PERIOD_H1) || (Period() > PERIOD_D1))
		{
			Alert("Timeframe should be between H1 and D1 for a Monthly session.");
			InitFailed = true; // Soft INIT_FAILED.
		}
	}
	else if (Session == Intraday)
	{
		if (Period() > PERIOD_M15)
		{
			Alert("Timeframe should not be higher than M15 for an Intraday sessions.");
			InitFailed = true; // Soft INIT_FAILED.
		}

		IntradaySessionCount = 0;
		if (!CheckIntradaySession(EnableIntradaySession1, IntradaySession1StartTime, IntradaySession1EndTime, IntradaySession1ColorScheme)) return(INIT_PARAMETERS_INCORRECT);
		if (!CheckIntradaySession(EnableIntradaySession2, IntradaySession2StartTime, IntradaySession2EndTime, IntradaySession2ColorScheme)) return(INIT_PARAMETERS_INCORRECT);
		if (!CheckIntradaySession(EnableIntradaySession3, IntradaySession3StartTime, IntradaySession3EndTime, IntradaySession3ColorScheme)) return(INIT_PARAMETERS_INCORRECT);
		if (!CheckIntradaySession(EnableIntradaySession4, IntradaySession4StartTime, IntradaySession4EndTime, IntradaySession4ColorScheme)) return(INIT_PARAMETERS_INCORRECT);
		
		if (IntradaySessionCount == 0)
		{
			Alert("Enable at least one intraday session if you want to use Intraday mode.");
			InitFailed = true; // Soft INIT_FAILED.
		}
	}
	
   IndicatorShortName("MarketProfile " + EnumToString(Session));

	// Based on number of digits in TickMultiplier. -1 because if TickMultiplier < 10, it does not modify the number of digits.
	DigitsM = _Digits - (StringLen(IntegerToString(PointMultiplier)) - 1);
	
	onetick = NormalizeDouble(_Point * PointMultiplier, DigitsM);
	Print(onetick);
	
	CurrentColorScheme = ColorScheme;
	
	// To clean up potential leftovers when applying a chart template.
	ObjectCleanup();
	
	return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectCleanup();
}

//+------------------------------------------------------------------+
//| Custom Market Profile main iteration function                    |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time_timeseries[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[]
)
{
	if (InitFailed)
	{
	   Print("Initialization failed. Please see the alert message for details.");
	   return(0);
	}
	
	if (StartFromCurrentSession) StartDate = Time[0];
	else StartDate = StartFromDate;
	
	// If we calculate profiles for the past sessions, no need to run it again.
	if ((FirstRunDone) && (StartDate != Time[0])) return(0);

   // Delay the update of Market Profile if ThrottleRedraw is given.
   if ((ThrottleRedraw > 0) && (Timer > 0))
   {
      if ((int)TimeLocal() - Timer < ThrottleRedraw) return(rates_total);
   }

   // Recalculate everything if there were missing bars or something like that.
   if (rates_total - prev_calculated > 1)
   {
      FirstRunDone = false;
      ObjectCleanup();
   }

	// Get start and end bar numbers of the given session.
	int sessionend = FindSessionEndByDate(StartDate);
	int sessionstart = FindSessionStart(sessionend);

	int SessionToStart = 0;
	// If all sessions have already been counted, jump to the current one.
	if (FirstRunDone) SessionToStart = SessionsToCount - 1;
	else
	{
		// Move back to the oldest session to count to start from it.
		for (int i = 1; i < SessionsToCount; i++)
		{
			sessionend = sessionstart + 1;
			sessionstart = FindSessionStart(sessionend);
		}
	}

	// We begin from the oldest session coming to the current session or to StartFromDate.
	for (int i = SessionToStart; i < SessionsToCount; i++)
	{
      if (Session == Intraday)
      {
         if (!ProcessIntradaySession(sessionstart, sessionend, i)) return(0);
      }
      else
      {
         if (Session == Daily) Max_number_of_bars_in_a_session = PeriodSeconds(PERIOD_D1) / PeriodSeconds();
         else if (Session == Weekly) Max_number_of_bars_in_a_session = 604800 / PeriodSeconds();
         else if (Session == Monthly) Max_number_of_bars_in_a_session = 2678400 / PeriodSeconds();
         if (!ProcessSession(sessionstart, sessionend, i)) return(0);
      }

		// Go to the newer session only if there is one or more left.
		if (SessionsToCount - i > 1)
		{
			sessionstart = sessionend - 1;
			sessionend = FindSessionEndByDate(Time[sessionstart]);
		}
	}

	FirstRunDone = true;

   Timer = (int)TimeLocal();

	return(rates_total);
}

//+------------------------------------------------------------------+
//| Finds the session's starting bar number for any given bar number.|
//| n - bar number for which to find starting bar. 					   |
//+------------------------------------------------------------------+
int FindSessionStart(const int n)
{
	if (Session == Daily) return(FindDayStart(n));
	else if (Session == Weekly) return(FindWeekStart(n));
	else if (Session == Monthly) return(FindMonthStart(n));
	else if (Session == Intraday) return(FindDayStart(n));
	
	return(-1);
}

//+------------------------------------------------------------------+
//| Finds the day's starting bar number for any given bar number.    |
//| n - bar number for which to find starting bar. 					   |
//+------------------------------------------------------------------+
int FindDayStart(const int n)
{
	int x = n;
	
	while ((x < Bars) && (TimeDayOfYear(Time[n] + TimeShiftMinutes * 60) == TimeDayOfYear(Time[x] + TimeShiftMinutes * 60)))
		x++;

	return(x - 1);
}

//+------------------------------------------------------------------+
//| Finds the week's starting bar number for any given bar number.   |
//| n - bar number for which to find starting bar. 					   |
//+------------------------------------------------------------------+
int FindWeekStart(const int n)
{
	int x = n;
	int day_of_week = TimeDayOfWeek(Time[n] + TimeShiftMinutes * 60);
	while ((x < Bars) && (SameWeek(Time[n] + TimeShiftMinutes * 60, Time[x] + TimeShiftMinutes * 60)))
		x++;

	return(x - 1);
}

//+------------------------------------------------------------------+
//| Finds the month's starting bar number for any given bar number.  |
//| n - bar number for which to find starting bar. 					   |
//+------------------------------------------------------------------+
int FindMonthStart(const int n)
{
	int x = n;
	
	while ((x < Bars) && (TimeMonth(Time[n] + TimeShiftMinutes * 60) == TimeMonth(Time[x] + TimeShiftMinutes * 60)))
		x++;

	return(x - 1);
}

//+------------------------------------------------------------------+
//| Finds the session's end bar by the session's date.					|
//+------------------------------------------------------------------+
int FindSessionEndByDate(const datetime date)
{
	if (Session == Daily) return(FindDayEndByDate(date));
	else if (Session == Weekly) return(FindWeekEndByDate(date));
	else if (Session == Monthly) return(FindMonthEndByDate(date));
	else if (Session == Intraday) return(FindDayEndByDate(date));
	
	return(-1);
}

//+------------------------------------------------------------------+
//| Finds the day's end bar by the day's date.								|
//+------------------------------------------------------------------+
int FindDayEndByDate(const datetime date)
{
	int x = 0;

	while ((x < Bars) && (TimeDayOfYear(date + TimeShiftMinutes * 60) < TimeDayOfYear(Time[x] + TimeShiftMinutes * 60)))
		x++;

	return(x);
}

//+------------------------------------------------------------------+
//| Finds the week's end bar by the week's date.							|
//+------------------------------------------------------------------+
int FindWeekEndByDate(const datetime date)
{
	int x = 0;

	while ((x < Bars) && (SameWeek(date + TimeShiftMinutes * 60, Time[x] + TimeShiftMinutes * 60) != true))
		x++;

	return(x);
}

//+------------------------------------------------------------------+
//| Finds the month's end bar by the month's date.							|
//+------------------------------------------------------------------+
int FindMonthEndByDate(const datetime date)
{
	int x = 0;

	while ((x < Bars) && (SameMonth(date + TimeShiftMinutes * 60, Time[x] + TimeShiftMinutes * 60) != true))
		x++;

	return(x);
}

//+------------------------------------------------------------------+
//| Check if two dates are in the same week.									|
//+------------------------------------------------------------------+
int SameWeek(const datetime date1, const datetime date2)
{
	int seconds_from_start = TimeDayOfWeek(date1) * 24 * 3600 + TimeHour(date1) * 3600 + TimeMinute(date1) * 60 + TimeSeconds(date1);
	
	if (date1 == date2) return(true);
	else if (date2 < date1)
	{
		if (date1 - date2 <= seconds_from_start) return(true);
	}
	// 604800 - seconds in one week.
	else if (date2 - date1 < 604800 - seconds_from_start) return(true);

	return(false);
}

//+------------------------------------------------------------------+
//| Check if two dates are in the same month.								|
//+------------------------------------------------------------------+
int SameMonth(const datetime date1, const datetime date2)
{
	if ((TimeMonth(date1) == TimeMonth(date2)) && (TimeYear(date1) == TimeYear(date2))) return(true);
	return(false);
}

//+------------------------------------------------------------------+
//| Puts a dot (rectangle) at a given position and color. 			   |
//| price and time are coordinates.								 			   |
//| range is for the second coordinate.						 			   |
//| bar is to determine the color of the dot.				 			   |
//+------------------------------------------------------------------+
void PutDot(const double price, const int start_bar, const int range, const int bar)
{
	double divisor, color_shift;
	string LastName = " " + TimeToString(Time[start_bar - range]) + " " + DoubleToString(price, _Digits);
	if (ObjectFind("MP" + Suffix + LastName) >= 0) return;

	// Protection from 'Array out of range' error.
	if (start_bar - (range + 1) < 0) return;

	ObjectCreate("MP" + Suffix + LastName, OBJ_RECTANGLE, 0, Time[start_bar - range], price, Time[start_bar - (range + 1)], price + onetick);
	
	// Color switching depending on the distance of the bar from the session's beginning.
	int colour, offset1, offset2;
	switch(CurrentColorScheme)
	{
		case Blue_to_Red:
			colour = 0x00FF0000; // clrBlue;
			offset1 = 0x00010000;
			offset2 = 0x00000001;
		break;
		case Red_to_Green:
			colour = 0x000000FF; // clrDarkRed;
			offset1 = 0x00000001;
			offset2 = 0x00000100;
		break;
		case Green_to_Blue:
			colour = 0x0000FF00; // clrDarkGreen;
			offset1 = 0x00000100;
			offset2 = 0x00010000;
		break;
		case Yellow_to_Cyan:
			colour = 0x0000FFFF; // clrYellow;
			offset1 = 0x00000001;
			offset2 = 0x00010000;
		break;
		case Magenta_to_Yellow:
			colour = 0x00FF00FF; // clrMagenta;
			offset1 = 0x00010000;
			offset2 = 0x00000100;
		break;
		case Cyan_to_Magenta:
			colour = 0x00FFFF00; // clrCyan;
			offset1 = 0x00000100;
			offset2 = 0x00000001;
		break;
		case Single_Color:
			colour = SingleColor;
			offset1 = 0;
			offset2 = 0;
		break;
		default:
			colour = SingleColor;
			offset1 = 0;
			offset2 = 0;
		break;
	}

	// No need to do these calculations if plain color is used.
	if (CurrentColorScheme != Single_Color)
	{
   	divisor = 1.0 / 0xFF * (double)Max_number_of_bars_in_a_session;
   
   	// bar is negative.
   	color_shift = MathFloor((double)bar / divisor);
   
      // Prevents color overflow.
      if ((int)color_shift < -0xFF) color_shift = -0xFF;
   
   	colour += (int)color_shift * offset1;
   	colour -= (int)color_shift * offset2;
   }

	ObjectSet("MP" + Suffix + LastName, OBJPROP_COLOR, colour);
	// Fills rectangle.
	ObjectSet("MP" + Suffix + LastName, OBJPROP_BACK, true);
	ObjectSet("MP" + Suffix + LastName, OBJPROP_SELECTABLE, false);
	ObjectSet("MP" + Suffix + LastName, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Deletes all chart objects created by the indicator.              |
//+------------------------------------------------------------------+
void ObjectCleanup()
{
	// Delete all rectangles with set prefix.
	ObjectsDeleteAll(0, "MP" + Suffix, EMPTY, OBJ_RECTANGLE);
	ObjectsDeleteAll(0, "Median" + Suffix, EMPTY, OBJ_RECTANGLE);
	ObjectsDeleteAll(0, "Value Area" + Suffix, EMPTY, OBJ_RECTANGLE);
	if (ShowValueAreaRays)
	{
	   // Delete all trendlines with set prefix.
	   ObjectsDeleteAll(0, "Value Area HighRay" + Suffix, EMPTY, OBJ_TREND);
	   ObjectsDeleteAll(0, "Value Area LowRay" + Suffix, EMPTY, OBJ_TREND);
	}
	if (ShowMedianRays)
	{
	   // Delete all trendlines with set prefix.
	   ObjectsDeleteAll(0, "Median HighRay" + Suffix, EMPTY, OBJ_TREND);
	   ObjectsDeleteAll(0, "Median LowRay" + Suffix, EMPTY, OBJ_TREND);
	}
}

//+------------------------------------------------------------------+
//| Extract hours and minutes from a time string.                    |
//| Returns false in case of an error.                               |
//+------------------------------------------------------------------+
bool GetHoursAndMinutes(string time_string, int& hours, int& minutes, int& time)
{
	if (StringLen(time_string) == 4) time_string = "0" + time_string;
	
	if ( 
		// Wrong length.
		(StringLen(time_string) != 5) ||
		// Wrong separator.
		(time_string[2] != ':') ||
		// Wrong first number (only 24 hours in a day).
		((time_string[0] < '0') || (time_string[0] > '2')) ||
		// 00 to 09 and 10 to 19.
		(((time_string[0] == '0') || (time_string[0] == '1')) && ((time_string[1] < '0') || (time_string[1] > '9'))) ||
		// 20 to 23.
		((time_string[0] == '2') && ((time_string[1] < '0') || (time_string[1] > '3'))) ||
		// 0M to 5M.
		((time_string[3] < '0') || (time_string[3] > '5')) ||
		// M0 to M9.
		((time_string[4] < '0') || (time_string[4] > '9'))
		)
   {
      Print("Wrong time string: ", time_string, ". Please use HH:MM format.");
      return(false);
   }

   string result[];
   int number_of_substrings = StringSplit(time_string, ':', result);
   hours = (int)StringToInteger(result[0]);
   minutes = (int)StringToInteger(result[1]);
   time = hours * 60 + minutes;
   
   return(true);
}

//+------------------------------------------------------------------+
//| Extract hours and minutes from a time string.                    |
//| Returns false in case of an error.                               |
//+------------------------------------------------------------------+
bool CheckIntradaySession(const bool enable, const string start_time, const string end_time, const color_scheme cs)
{
	if (enable)
	{
		if (!GetHoursAndMinutes(start_time, IDStartHours[IntradaySessionCount], IDStartMinutes[IntradaySessionCount], IDStartTime[IntradaySessionCount]))
		{
		   Alert("Wrong time string format: ", start_time, ".");
		   return(false);
		}
		if (!GetHoursAndMinutes(end_time, IDEndHours[IntradaySessionCount], IDEndMinutes[IntradaySessionCount], IDEndTime[IntradaySessionCount]))
		{
		   Alert("Wrong time string format: ", end_time, ".");
		   return(false);
		}
		// Special case of the intraday session ending at "00:00".
		if (IDEndTime[IntradaySessionCount] == 0)
		{
		   // Turn it into "24:00".
		   IDEndHours[IntradaySessionCount] = 24;
		   IDEndMinutes[IntradaySessionCount] = 0;
		   IDEndTime[IntradaySessionCount] = 24 * 60;
		}
		
		IDColorScheme[IntradaySessionCount] = cs;
		IntradaySessionCount++;
	}
	return(true);
}

//+------------------------------------------------------------------+
//| Main procedure to draw the Market Profile based on a session     |
//| start bar and session end bar.                                   |
//| Returns true on success, false - on failure.                     |
//+------------------------------------------------------------------+
bool ProcessSession(const int sessionstart, const int sessionend, const int i)
{
   if (sessionstart + 16 >= Bars) return(false); // Data not yet ready.

	double SessionMax = DBL_MIN, SessionMin = DBL_MAX;

	// Find the session's high and low. 
	for (int bar = sessionstart; bar >= sessionend; bar--)
	{
		if (High[bar] > SessionMax) SessionMax = High[bar];
		if (Low[bar] < SessionMin) SessionMin = Low[bar];
	}
	SessionMax = NormalizeDouble(SessionMax, DigitsM);
	SessionMin = NormalizeDouble(SessionMin, DigitsM);
			
	int TPOperPrice[];
	// Possible price levels if multiplied to integer.
	int max = (int)MathRound(SessionMax / onetick + 2); // + 2 because further we will be possibly checking array at SessionMax + 1.
	ArrayResize(TPOperPrice, max);
	ArrayInitialize(TPOperPrice, 0);

	int MaxRange = 0; // Maximum distance from session start to the drawn dot.
	double PriceOfMaxRange = 0; // Level of the maximum range, required to draw Median.
	double DistanceToCenter = DBL_MAX; // Closest distance to center for the Median.
	
	int TotalTPO = 0; // Total amount of dots (TPO's).
	
	// Going through all possible quotes from session's High to session's Low.
	for (double price = SessionMax; price >= SessionMin; price -= onetick)
	{
		int range = 0; // Distance from first bar to the current bar.

		// Going through all bars of the session to see if the price was encountered here.
		for (int bar = sessionstart; bar >= sessionend; bar--)
		{
			// Price is encountered in the given bar
			if ((price >= Low[bar]) && (price <= High[bar]))
			{
				// Update maximum distance from session's start to the found bar (needed for Median).
				// Using the center-most Median if there are more than one.
				if ((MaxRange < range) || ((MaxRange == range) && (MathAbs(price - (SessionMin + (SessionMax - SessionMin) / 2)) < DistanceToCenter)))
				{
					MaxRange = range;
					PriceOfMaxRange = price;
					DistanceToCenter = MathAbs(price - (SessionMin + (SessionMax - SessionMin) / 2));
				}
				// Draws rectangle.
				PutDot(price, sessionstart, range, bar - sessionstart);
				// Remember the number of encountered bars for this price.
				int index = (int)MathRound(price / onetick);
				TPOperPrice[index]++;
				range++;
				TotalTPO++;
			}
		}
	}

	double TotalTPOdouble = TotalTPO;
	// Calculate amount of TPO's in the Value Area.
	int ValueControlTPO = (int)MathRound(TotalTPOdouble * 0.7);
	// Start with the TPO's of the Median.
	int index = (int)(PriceOfMaxRange / onetick);
	int TPOcount = TPOperPrice[index];

	// Go through the price levels above and below median adding the biggest to TPO count until the 70% of TPOs are inside the Value Area.
	int up_offset = 1;
	int down_offset = 1;
	while (TPOcount < ValueControlTPO)
	{
		double abovePrice = PriceOfMaxRange + up_offset * onetick;
		double belowPrice = PriceOfMaxRange - down_offset * onetick;
		// If belowPrice is out of the session's range then we should add only abovePrice's TPO's, and vice versa.
		index = (int)MathRound(abovePrice / onetick);
		int index2 = (int)MathRound(belowPrice / onetick);
		if (((TPOperPrice[index] >= TPOperPrice[index2]) || (belowPrice < SessionMin)) && (abovePrice <= SessionMax))
		{
			TPOcount += TPOperPrice[index];
			up_offset++;
		}
		else
		{
			TPOcount += TPOperPrice[index2];
			down_offset++;
		}
	}
	string LastName = " " + TimeToStr(Time[sessionstart], TIME_DATE);
	// Delete old Median.
	if (ObjectFind("Median" + Suffix + LastName) >= 0) ObjectDelete("Median" + Suffix + LastName);
	// Draw a new one.
	index = MathMax(sessionstart - MaxRange - 5, 0);
	ObjectCreate("Median" + Suffix + LastName, OBJ_RECTANGLE, 0, Time[sessionstart + 16], PriceOfMaxRange, Time[index], PriceOfMaxRange + _Point);
	ObjectSet("Median" + Suffix + LastName, OBJPROP_COLOR, MedianColor);
	ObjectSet("Median" + Suffix + LastName, OBJPROP_STYLE, STYLE_SOLID);
	ObjectSet("Median" + Suffix + LastName, OBJPROP_BACK, false);
	ObjectSet("Median" + Suffix + LastName, OBJPROP_SELECTABLE, false);
	ObjectSet("Median" + Suffix + LastName, OBJPROP_HIDDEN, true);
	
   // If the median rays have to be created and it is the last session before the most recent one:
   if ((ShowMedianRays) && (SessionsToCount - i == 2))
   {
   	// Delete old Median Rays.
   	if (ObjectFind(0, "Median HighRay" + Suffix) >= 0) ObjectDelete(0, "Median HighRay" + Suffix);
   	if (ObjectFind(0, "Median LowRay" + Suffix) >= 0) ObjectDelete(0, "Median LowRay" + Suffix);
   	// Draw a new Median High Ray.
   	ObjectCreate(0, "Median HighRay" + Suffix, OBJ_TREND, 0, Time[sessionstart], PriceOfMaxRange + _Point, Time[sessionstart - (MaxRange + 1)], PriceOfMaxRange + _Point);
   	ObjectSetInteger(0, "Median HighRay" + Suffix, OBJPROP_COLOR, MedianColor);
   	ObjectSetInteger(0, "Median HighRay" + Suffix, OBJPROP_STYLE, STYLE_DASH);
   	ObjectSetInteger(0, "Median HighRay" + Suffix, OBJPROP_BACK, false);
   	ObjectSetInteger(0, "Median HighRay" + Suffix, OBJPROP_SELECTABLE, false);
   	ObjectSetInteger(0, "Median HighRay" + Suffix, OBJPROP_RAY_RIGHT, true);
   	ObjectSetInteger(0, "Median HighRay" + Suffix, OBJPROP_HIDDEN, true);
   	// Draw a new Median Low Ray.
   	ObjectCreate(0, "Median LowRay" + Suffix, OBJ_TREND, 0, Time[sessionstart], PriceOfMaxRange, Time[sessionstart - (MaxRange + 1)], PriceOfMaxRange);
   	ObjectSetInteger(0, "Median LowRay" + Suffix, OBJPROP_COLOR, MedianColor);
   	ObjectSetInteger(0, "Median LowRay" + Suffix, OBJPROP_STYLE, STYLE_DASH);
   	ObjectSetInteger(0, "Median LowRay" + Suffix, OBJPROP_BACK, false);
   	ObjectSetInteger(0, "Median LowRay" + Suffix, OBJPROP_SELECTABLE, false);
   	ObjectSetInteger(0, "Median LowRay" + Suffix, OBJPROP_RAY_RIGHT, true);
   	ObjectSetInteger(0, "Median LowRay" + Suffix, OBJPROP_HIDDEN, true);
   }

	// Protection from 'Array out of range' error.
	if (sessionstart - (MaxRange + 1) < 0) return(true);
	
	// Delete old Value Area.
	if (ObjectFind("Value Area" + Suffix + LastName) >= 0) ObjectDelete("Value Area" + Suffix + LastName);
	// Draw a new one.
	ObjectCreate("Value Area" + Suffix + LastName, OBJ_RECTANGLE, 0, Time[sessionstart], PriceOfMaxRange + up_offset * onetick, Time[sessionstart - (MaxRange + 1)], PriceOfMaxRange - down_offset * onetick);
	ObjectSet("Value Area" + Suffix + LastName, OBJPROP_COLOR, ValueAreaColor);
	ObjectSet("Value Area" + Suffix + LastName, OBJPROP_STYLE, STYLE_SOLID);
	ObjectSet("Value Area" + Suffix + LastName, OBJPROP_BACK, false);
	ObjectSet("Value Area" + Suffix + LastName, OBJPROP_SELECTABLE, false);
	ObjectSet("Value Area" + Suffix + LastName, OBJPROP_HIDDEN, true);

   // If value area rays have to be created and it is the last session before the most recent one:
   if ((ShowValueAreaRays) && (SessionsToCount - i == 2))
   {
   	// Delete old Value Area Rays.
   	if (ObjectFind(0, "Value Area HighRay" + Suffix) >= 0) ObjectDelete(0, "Value Area HighRay" + Suffix);
   	if (ObjectFind(0, "Value Area LowRay" + Suffix) >= 0) ObjectDelete(0, "Value Area LowRay" + Suffix);
   	// Draw a new Value Area High Ray.
   	ObjectCreate(0, "Value Area HighRay" + Suffix, OBJ_TREND, 0, Time[sessionstart], PriceOfMaxRange + up_offset * onetick, Time[sessionstart - (MaxRange + 1)], PriceOfMaxRange + up_offset * onetick);
   	ObjectSetInteger(0, "Value Area HighRay" + Suffix, OBJPROP_COLOR, ValueAreaColor);
   	ObjectSetInteger(0, "Value Area HighRay" + Suffix, OBJPROP_STYLE, STYLE_DOT);
   	ObjectSetInteger(0, "Value Area HighRay" + Suffix, OBJPROP_BACK, false);
   	ObjectSetInteger(0, "Value Area HighRay" + Suffix, OBJPROP_SELECTABLE, false);
   	ObjectSetInteger(0, "Value Area HighRay" + Suffix, OBJPROP_RAY_RIGHT, true);
   	ObjectSetInteger(0, "Value Area HighRay" + Suffix, OBJPROP_HIDDEN, true);
   	// Draw a new Value Area Low Ray.
   	ObjectCreate(0, "Value Area LowRay" + Suffix, OBJ_TREND, 0, Time[sessionstart], PriceOfMaxRange - down_offset * onetick, Time[sessionstart - (MaxRange + 1)], PriceOfMaxRange - down_offset * onetick);
   	ObjectSetInteger(0, "Value Area LowRay" + Suffix, OBJPROP_COLOR, ValueAreaColor);
   	ObjectSetInteger(0, "Value Area LowRay" + Suffix, OBJPROP_STYLE, STYLE_DOT);
   	ObjectSetInteger(0, "Value Area LowRay" + Suffix, OBJPROP_BACK, false);
   	ObjectSetInteger(0, "Value Area LowRay" + Suffix, OBJPROP_SELECTABLE, false);
   	ObjectSetInteger(0, "Value Area LowRay" + Suffix, OBJPROP_RAY_RIGHT, true);
   	ObjectSetInteger(0, "Value Area LowRay" + Suffix, OBJPROP_HIDDEN, true);
   }
   
   return(true);
}

//+------------------------------------------------------------------+
//| A cycle through intraday sessions with necessary checks.         |
//| Returns true on success, false - on failure.                     |
//+------------------------------------------------------------------+
bool ProcessIntradaySession(int sessionstart, int sessionend, int i)
{
   int remember_sessionstart = sessionstart;
   int remember_sessionend = sessionend;
   
   // Start a cycle through intraday sessions if needed.
   // For each intraday session, find its own sessionstart and sessionend.
   for (int intraday_i = 0; intraday_i < IntradaySessionCount; intraday_i++)
   {
      Suffix = "_ID" + IntegerToString(intraday_i);
      CurrentColorScheme = IDColorScheme[intraday_i];
      // Get minutes.
      Max_number_of_bars_in_a_session = IDEndTime[intraday_i] - IDStartTime[intraday_i];
      // If end is less than beginning:
      if (Max_number_of_bars_in_a_session < 0) Max_number_of_bars_in_a_session = 24 * 60 + Max_number_of_bars_in_a_session;
      Max_number_of_bars_in_a_session = Max_number_of_bars_in_a_session / (PeriodSeconds() / 60);
      
      // If it is the updating stage, we need to recalculate only those intraday sessions that include the current bar.
      int hour, minute, time;
      if (FirstRunDone)
      {
         //sessionstart = day_start;
         hour = TimeHour(Time[0]);
         minute = TimeMinute(Time[0]);
         time = hour * 60 + minute;
      
         // For example, 13:00-18:00.
         if (IDStartTime[intraday_i] < IDEndTime[intraday_i])
         {
            if ((time < IDEndTime[intraday_i]) && (time >= IDStartTime[intraday_i]))
            {
               sessionstart = 0;
               int sessiontime = TimeHour(Time[sessionstart]) * 60 + TimeMinute(Time[sessionstart]);
               while((sessiontime > IDStartTime[intraday_i]) 
               // Prevents problems when the day has partial data (e.g. Sunday).
               && (TimeDayOfYear(Time[sessionstart]) == TimeDayOfYear(Time[0])))
               {
                  sessionstart++;
                  sessiontime = TimeHour(Time[sessionstart]) * 60 + TimeMinute(Time[sessionstart]);
               }
            }
            else continue;
         }
         // For example, 22:00-6:00.
         else if (IDStartTime[intraday_i] > IDEndTime[intraday_i])
         {
            if ((time < IDEndTime[intraday_i]) || (time >= IDStartTime[intraday_i]))
            {
               sessionstart = 0;
               int sessiontime = TimeHour(Time[sessionstart]) * 60 + TimeMinute(Time[sessionstart]);
               // Within 24 hours of the current time - but can be today or yesterday.
               while(((sessiontime > IDStartTime[intraday_i]) && (Time[0] - Time[sessionstart] <= 3600 * 24)) 
               // Same day only.
               || ((sessiontime < IDEndTime[intraday_i]) && (TimeDayOfYear(Time[sessionstart]) == TimeDayOfYear(Time[0]))))
               {
                  sessionstart++;
                  sessiontime = TimeHour(Time[sessionstart]) * 60 + TimeMinute(Time[sessionstart]);
               }
            }
            else continue;
         }
         // If start time equals end time, we can skip the session.
         else continue;
         
         // Because apparently, we are still inside the session.
         sessionend = 0;
         if (sessionend == sessionstart) continue; // No need to process such an intraday session.

         if (!ProcessSession(sessionstart, sessionend, i)) return(false);
      }
      // If it is the first run.
      else
      {
         sessionend = remember_sessionend;
         
         // Process the sessions that start today.
         // For example, 13:00-18:00.
         if (IDStartTime[intraday_i] < IDEndTime[intraday_i])
         {
            // Intraday session starts after the today's actual session ended (for Friday/Saturday cases).
            if (TimeHour(Time[remember_sessionend]) * 60 + TimeMinute(Time[remember_sessionend]) < IDStartTime[intraday_i]) continue;
            // Intraday session ends before the today's actual session starts (for Sunday cases).
            if (TimeHour(Time[remember_sessionstart]) * 60 + TimeMinute(Time[remember_sessionstart]) >= IDEndTime[intraday_i]) continue;
            
            while((sessionend < Bars) && (TimeHour(Time[sessionend]) * 60 + TimeMinute(Time[sessionend]) > IDEndTime[intraday_i]))
            {
               sessionend++;
            }
            if (sessionend == Bars) sessionend--;

            sessionstart = sessionend;
            while((sessionstart < Bars) && (TimeHour(Time[sessionstart]) * 60 + TimeMinute(Time[sessionstart]) >= IDStartTime[intraday_i])
            // Same day - for cases when the day does not contain intraday session start time.
            && (TimeDayOfYear(Time[sessionstart]) == TimeDayOfYear(Time[sessionend])))
            {
               sessionstart++;
            }
            sessionstart--;
         }
         // For example, 22:00-6:00.
         else if (IDStartTime[intraday_i] > IDEndTime[intraday_i])
         {
            // Today's intraday session starts after the end of the actual session (for Friday/Saturday cases).
            if (TimeHour(Time[remember_sessionend]) * 60 + TimeMinute(Time[remember_sessionend]) < IDStartTime[intraday_i]) continue;

            sessionstart = remember_sessionend; // Start from the end.
            while(((sessionstart < Bars) && (TimeHour(Time[sessionstart]) * 60 + TimeMinute(Time[sessionstart]) >= IDStartTime[intraday_i]))
            // Same day - for cases when the day does not contain intraday session start time.
            && (TimeDayOfYear(Time[sessionstart]) == TimeDayOfYear(Time[remember_sessionend])))
            {
               sessionstart++;
            }
            sessionstart--;

            int sessionlength = (24 * 60 - IDStartTime[intraday_i] + IDEndTime[intraday_i]) * 60; // In seconds.
            while((sessionend >= 0) && (Time[sessionend] - Time[sessionstart] < sessionlength))
            {
               sessionend--;
            }
            sessionend++;
         }
         // If start time equals end time, we can skip the session.
         else continue;
         
         if (sessionend == sessionstart) continue; // No need to process such an intraday session.

         if (!ProcessSession(sessionstart, sessionend, i)) return(false);
      }
   }
   Suffix = "_ID";
   
   return(true);
}
//+------------------------------------------------------------------+