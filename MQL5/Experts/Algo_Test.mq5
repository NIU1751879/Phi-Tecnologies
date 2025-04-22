#property strict

// Input Parameters
input int            FastMAPeriod = 10;        // Fast Moving Average Period
input int            SlowMAPeriod = 30;        // Slow Moving Average Period
input ENUM_MA_METHOD MAMethod     = MODE_SMA;  // Moving Average Method
input ENUM_APPLIED_PRICE PriceType = PRICE_CLOSE; // Applied Price
input double         LotSize      = 0.1;       // Trading Lot Size

// Global Variables
int fastMAHandle;
int slowMAHandle;
double fastMABuffer[];
double slowMABuffer[];
int lastSignal = 0; // 0-no position, 1-buy, -1-sell


int OnInit(){
   // Create MA indicator handles
   fastMAHandle = iMA(_Symbol, PERIOD_CURRENT, FastMAPeriod, 0, MAMethod, PriceType);
   slowMAHandle = iMA(_Symbol, PERIOD_CURRENT, SlowMAPeriod, 0, MAMethod, PriceType);
   
   // Check if handles are created successfully
   if(fastMAHandle == INVALID_HANDLE || slowMAHandle == INVALID_HANDLE)
   {
      Print("Error creating MA indicators!");
      return(INIT_FAILED);
   }
   
   // Set up buffers for MA values
   ArraySetAsSeries(fastMABuffer, true);
   ArraySetAsSeries(slowMABuffer, true);
   
   Print("MA Crossover Strategy initialized successfully");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   // Release indicator handles
   IndicatorRelease(fastMAHandle);
   IndicatorRelease(slowMAHandle);
   
   Print("MA Crossover Strategy removed");
}

void OnTick(){
   // Copy MA values to buffers
   if(CopyBuffer(fastMAHandle, 0, 0, 3, fastMABuffer) <= 0) return;
   if(CopyBuffer(slowMAHandle, 0, 0, 3, slowMABuffer) <= 0) return;

   // Check for crossover
   bool buyCrossover = (fastMABuffer[1] <= slowMABuffer[1] && fastMABuffer[0] > slowMABuffer[0]);
   bool sellCrossover = (fastMABuffer[1] >= slowMABuffer[1] && fastMABuffer[0] < slowMABuffer[0]);
   
   // Current open positions
   int positions = GetPositions();
   
   // Trading logic
   if(buyCrossover && positions <= 0)
   {
      // Close any existing sell positions
      if(positions < 0) ClosePositions();
      
      // Open buy position
      if(Trade(ORDER_TYPE_BUY))
         lastSignal = 1;
   }
   else if(sellCrossover && positions >= 0)
   {
      // Close any existing buy positions
      if(positions > 0) ClosePositions();
      
      // Open sell position
      if(Trade(ORDER_TYPE_SELL))
         lastSignal = -1;
   }
}

bool Trade(ENUM_ORDER_TYPE orderType){
   MqlTradeRequest request;
   MqlTradeResult result;
   
   ZeroMemory(request);
   ZeroMemory(result);
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = LotSize;
   request.type = orderType;
   request.price = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation = 10;
   request.magic = 123456;
   request.comment = "MA Crossover";
   
   bool success = OrderSend(request, result);
   
   if(!success)
   {
      Print("Error opening position: ", GetLastError());
      return false;
   }
   
   Print("Position opened successfully: Order #", result.order);
   return true;
}

void ClosePositions(){
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong posTicket = PositionGetTicket(i);
      if(posTicket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            MqlTradeRequest request;
            MqlTradeResult result;
            
            ZeroMemory(request);
            ZeroMemory(result);
            
            request.action = TRADE_ACTION_DEAL;
            request.position = posTicket;
            request.symbol = _Symbol;
            
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
               request.volume = PositionGetDouble(POSITION_VOLUME);
               request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
               request.type = ORDER_TYPE_SELL;
            }
            else
            {
               request.volume = PositionGetDouble(POSITION_VOLUME);
               request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
               request.type = ORDER_TYPE_BUY;
            }
            
            request.deviation = 10;
            
            bool success = OrderSend(request, result);
            if(!success)
               Print("Error closing position: ", GetLastError());
            else
               Print("Position closed successfully");
         }
      }
   }
}

int GetPositions(){
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong posTicket = PositionGetTicket(i);
      if(posTicket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
               count++;
            else
               count--;
         }
      }
   }
   
   return count;
}