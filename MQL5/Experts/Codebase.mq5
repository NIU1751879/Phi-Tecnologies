//+--------------------------------------------------
//| Expert configuration                                            
//+--------------------------------------------------

//-----------------------HACER ANALISI 30 minutos sheets estadisticas cada dia descargando los trades. NO SOBRECOMPRAR Y ELEGIR EN QUE MOMENTO DEL DIA ATACAR POCOS MINUTOS ENVIANDO ORDENES EN MILISEGUNDOS ES LO MEJOR. EN EURUSD por ejemplo idealmente operar entre 9-11 y de 21-23 ya que la desviacion estandar baja.  MENOS VOLUMEN Y DE CALIDAD PARA ESOS POCOS MINUTOS > MAYOR VOLUMEN CON ALGUNAS ORDENES NO CERRADAS

//1. Revisar que imprima el tiempo en newcomment haciendo que en el commenatrio antiguo no haya nada escrito + Revisar la funcion para guardar todo en un CSV. Lo del CSV creo que no se llama bien en la funcion closeopenposition y mas alla de eso dentro de la funcion csv creo que hay errores de sintaxi o algo que nos dejamos que haceq ue no funcione como toca. 

//2. Scrapeo de real volume per price level con webrequest o websockets y algun otro calculo para medir la fuerza en funcion de los lotes del real volume del market depth para hacer con eos ecuaciones de fluidos o de fuerza que complementen el RSI y permitan ajustar mejor la agresividad o la pasividad y los POCs en funcion dle volumen por price level. 

//3. Se podria analizar los datos del ADX de varios activos y ver que activos tienen tendencias mas largas o mas cortas ya que de eso nos podemos beneficiar y asi elegir mejores activos para nuestra estrategia basada en ADX filtrando por ejemplo para que se opere en intervalos donde analicemos que el ADX es mas bajo por ejmeplo en EURUSD de 11am a 13am y de 21-23 para evitar volatilidad excesiva pero buena liquidez y volatilidad media que haga que se cierren muchas ordene sporque fluctua mucho pero en rangos bajoy, StdDev, RSI, SMAs y RealVolume per price level para identificar POCs

//4. Ya se mejorará la estrategia detectando un grid trading market making para escenarios pasivos en vez de esto que tenemos ahora o bien otras cosa como que cuando se detecte grid market making en escenarios pasivos el limit price sea restandole o sumandole un mini porcentaje para capturar rebotes o algo parecido, evidentemente el porcentaje de desviacion depender'a en cada activo, puede ser por ejemplo restarle o sumarle al precio un 0.0003% y en activos mas volatiles un 0.0005%. Posible webrequest en caso de que Tickmill no lo ofrezca para escrapear los real-volumes de TradingView y representarlos en mi grafico o bien en modo pasivo entrar con grid trading y varianza segun el rango de precio

//5. El uso de Navier Stokes para hacer predicciones estocásticas mejor o con termino imaginario i para hacer una fórmula econometrica de situaciones cambiantes de momentum, presión, fuerzas y aceleración al estilo fórmula Newton.O bien el uso de trailing stops para que el SL dinamico se ajuste dinamicamente y no hayan ordenes con SL o TP fijo

input string TradeSymbol = "EURUSD";                      // Símbolo a operar
input double StdDevMultiplier = 6;                        // Multiplier StdDev.                                               Se recomiendan valores entre 30-500k (puede ser decimal pese a que solo se mostará un SL dinamico entero)
input int FastSMA = 300;                                  // SMA rapida                                                      (Nos interesa aprox 3 velas, 9 velas, 27 velas y 81 velas del periodo seleccionado (seguramente 5m), 300 en la SMA corta equivaldrá a la media de los ultimos 300 precios registrados debe ser la que mas peso tenga junto a la media ya que la lenta es solo de sentimiento macro)
input int MediumSMA = 900;                                // SMA media 
input int SlowSMA = 2700;                                 // SMA lenta.
input  int SuperslowSMA = 8100;                           // SMA superlenta
input double TickVolatilityThresholdLow = 0.00001;        //Threshold Volatilidad baja 
input double TickVolatilityThresholdHigh = 0.00002;       //Threshold Volatilidad alta
input double MaxAllowedSpread = 0.00002;                  // Valor máximo de spread 
input int MinTickVolume = 300;                            // Valor minimo de tick
input int MaxTickVolume = 500;                            // Valor maximo de tick                        
input int PendingOrderTimeoutSeconds = 120;               // Tiempo límite ordenes pendientes (120/180/240...)
input double MinProfitPips = 0.00001;                     // Ganancia mínima requerida para TP en modo pasivo
input double AggressiveProfitMultiplier = 3;              // Multiplicador para TP en modo agresivo.                          Segun la proporcion de posiciones que hayan cerrado con mayor TP se puede ampliar
input double VolatilityTickHighLotMultiplier = 0.5;       // VolatilityTickHighLotMultiplier.
input double VolatilityTickLowLotMultiplier = 1.5;        // VolatilityTickLowLotMultiplier.                                  Se amplia cuando es baja la volatilidad ya que no suele haber slippage  seguramente veamos en los CSV que se cierran en mayor porcentaje las ordenes menos volatiles dentro de una volatilidad promedio baja y otros momentos con una volatilidad promedio alta


double longPositionWeight, shortPositionWeight = 0;
double VolatilityTick = 0;
double SMA3 = 0.0, SMA9 = 0.0, SMA27 = 0.0, SMA81 = 0.0;
double alphaFast, alphaMedium, alphaSlow, alphaSuperslow;
double lastPrice = 0;
double dynamicSL = 0;
string comment;
double StdDevArray [];
double RSIArray [];
double ADXArray [];
double StdDevValue = 0;
double RSIValue = 0;
double ADXValue = 0;

int CandlesRSIandStdDevandADX = 14;                       // Cantidad de velas de referencia para calculos de RSI y ADX y StdDev. 14 esta bien porque es la base que usan todos, menor a 14 genera ruido y mas que 14 pierdes situaciones que el resto ve
int BufferPeriodStdDevandRSIandADX = 300;                 // Mayor lo de 300 para simbolos muy estables y menor a 200 por ejemplo para simbolos muy volatiles o 500 para estables
int RSIbuythreshold = 30;                                 // Se puede bajar a 20 (sobrevendido por lo que se deberia comprar)
int RSIsellthreshold = 70;                                // Se puede subir a 80 (sobrecomprado por lo que se deberia vender)
int ADXtrendthreshold = 30;                               // No se debe bajar a menos de 25 y no se debe subir a mas de 40 para que sobrefiltre y la tendencia ya se este acabando, indica la fuerza de tendencias 
double MaximumAccountBalanceTotalPositionWeight = 0.3;    // 30% del balance de la cuenta, si la estrategia es solida se puede subir al 90% o si tenemos un leverage alto mejor bajarlo al 30 0 10%
double sizeLot = 0.003*ACCOUNT_BALANCE;                   // Lote de base arriesgando un 0.3% de la cuenta, un 15% apalancado x30
double DailyProfitThreshold = 0.0009;                     // Umbral diario (0.09%, 0.09*30 = 2.7% diario sobre el capital nuestro sin apalancamiento. )
int StartHourIntFormat = 7;                               // Hora de inicio de conteo del bot en formato int
datetime StartMonitoringHour = 7 * 3600;                  // 7:00 AM
datetime EndMonitoringHour = 23 * 3600;                   // 11:00 PM    
datetime startTime;                                       // Hora de inicio del día
double dailyInitialBalance;                               // Balance al comienzo del día
bool dailyThresholdReached = false;                       // Indicador de si el umbral diario se alcanzó, por defecto false
bool balanceInitialized = false;                          // Indica si el balance ya fue inicializado      
                                  
int millisecondsSetBetweenPendingOrders = 500;            // Tras ver que todo funcione correctamente ya lo bajaremos a menos segundos como 500 (0.5seg) o 2000 para hacerlo mas HFT aun
int millisecondsDelay = 6;                                // Cada 6 milisegundos el bot es analizado en vez de en cada tick
int BasePendingOrdersPerInterval = 3;                     // Ordenes pendientes enviadas por intervalo 


// Modo de trading
enum TradingMode { AGGRESSIVE, PASSIVE };
TradingMode currentMode;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |p
//+------------------------------------------------------------------+
int OnInit()
 {
   
   EventSetMillisecondTimer(millisecondsDelay);

// Calculamos los multiplicadores de suavizado para las SMAs. Ajustar a 2 o 3 o 4 en vez de 1 si se quiere que sean EMAs mas fuertes en los ultimos valores en vez de SMAs
   alphaFast =      1.0  /  (FastSMA * 1);
   alphaMedium =    1.0  /  (MediumSMA * 1);
   alphaSlow =      1.0  /  (SlowSMA * 1);
   alphaSuperslow = 1.0  /  (SuperslowSMA * 1);

   currentMode = PASSIVE; // Iniciar en modo pasivo
   
   //Definición del calculo de StdDev, RSI y ADX. Se usa Typical para enfatizar algo mas en el close que es (HIGH+LOW+CLOSE)/3
   int StdDevDefinition = iStdDev(TradeSymbol, _Period, CandlesRSIandStdDevandADX, 0, MODE_SMA, PRICE_TYPICAL);
   ArraySetAsSeries(StdDevArray, true);
   CopyBuffer(StdDevDefinition, 0, 0, BufferPeriodStdDevandRSIandADX, StdDevArray);
   
   int RSIDefinition = iRSI(TradeSymbol, _Period, CandlesRSIandStdDevandADX, PRICE_TYPICAL);
   ArraySetAsSeries(RSIArray, true);
   CopyBuffer(RSIDefinition, 0, 0, BufferPeriodStdDevandRSIandADX, RSIArray);
   
   int ADXDefinition = iADX(TradeSymbol, _Period, CandlesRSIandStdDevandADX);
   ArraySetAsSeries(ADXArray, true);
   CopyBuffer(ADXDefinition, 0, 0, BufferPeriodStdDevandRSIandADX, ADXArray);  

       
   // Configurar tiempo inicial y balance del día
   startTime = GetStartOfDay();
   
   // Solo inicializar si no se ha hecho o es un nuevo día
   if (!balanceInitialized || IsNewDay())
   {
     startTime = GetStartOfDay();
     balanceInitialized = true;
     dailyThresholdReached = false; // Reiniciar el umbral solo si es un nuevo día
     Print("Balance inicial registrado: ", AccountInfoDouble(ACCOUNT_BALANCE), " a las", StartHourIntFormat, ":00 AM.");
    }

    return INIT_SUCCEEDED;
}

     
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer()
   {  
   
      // Monitorear el umbral diario
      CheckDailyProfitThreshold();

      // Si se alcanzó el umbral diario sobre el balance de la cuenta detener operaciones ese dia
      if (dailyThresholdReached)
      {
       Print("El bot está desactivado. No se realizarán operaciones.");
       return; 
      }
      
      // Si el simbolo no pertenece al grafico return y print para cambiarlo
      if(TradeSymbol != _Symbol)
       {
        Print("El símbolo ", TradeSymbol, " no pertenece al simbolo del grafico");
        return;
       }  
      
      // Se le asigna el current price al bid, si se hace grid trading o en modo pasivo se pretende jugar con el 
      // spread esto se deberia cambiar ya que coge el Bid como current price            
      double currentPrice = NormalizeDouble(SymbolInfoDouble(TradeSymbol, SYMBOL_BID), _Digits); 
      
      
   // Si es el primer tick, inicializamos las SMAs con el precio actual
      if(lastPrice == 0)
        {
         lastPrice = currentPrice;
         SMA3 = currentPrice;
         SMA9 = currentPrice;
         SMA27 = currentPrice;
         SMA81 = currentPrice;
         return;
        }
   
   
   // Calcular la volatilidad del tick actual
      double tickChange = MathAbs(currentPrice - lastPrice);
      
      VolatilityTick = tickChange;
      lastPrice = currentPrice;
   
   
   // Actualizamos las EMAs manualmente basadas en ticks
      SMA3  =  alphaFast      * (currentPrice - SMA3)  + SMA3;
      SMA9  =  alphaMedium    * (currentPrice - SMA9)  + SMA9;
      SMA27 =  alphaSlow      * (currentPrice - SMA27) + SMA27;
      SMA81 =  alphaSuperslow * (currentPrice - SMA81) + SMA81;
         
   
   // Determinar los pesos de long/short según el orden de las EMAs
      if(SMA3 > SMA9 && SMA9 > SMA27 && SMA27 > SMA81) 
      {
          longPositionWeight = 0.90;
          shortPositionWeight = 0.10;
      }
      else if(SMA3 > SMA9 && SMA9 > SMA81 && SMA81 > SMA27)
      {
          longPositionWeight = 0.80;
          shortPositionWeight = 0.20;
      }
      else if(SMA3 > SMA27 && SMA27 > SMA9 && SMA9 > SMA81)
      {
          longPositionWeight = 0.70;
          shortPositionWeight = 0.30;
      }
      else if(SMA3 > SMA27 && SMA27 > SMA81 && SMA81 > SMA9) // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA3 > SMA81 && SMA81 > SMA9 && SMA9 > SMA27)  // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA3 > SMA81 && SMA81 > SMA27 && SMA27 > SMA9) // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA9 > SMA3 && SMA3 > SMA27 && SMA27 > SMA81)
      {
          longPositionWeight = 0.80;
          shortPositionWeight = 0.20;
      }
      else if(SMA9 > SMA3 && SMA3 > SMA81 && SMA81 > SMA27)
      {
          longPositionWeight = 0.70;
          shortPositionWeight = 0.30;
      }
      else if(SMA9 > SMA27 && SMA27 > SMA3 && SMA3 > SMA81)  // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA9 > SMA27 && SMA27 > SMA81 && SMA81 > SMA3) // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA9 > SMA81 && SMA81 > SMA3 && SMA3 > SMA27)  // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA9 > SMA81 && SMA81 > SMA27 && SMA27 > SMA3)
      {
          longPositionWeight = 0.30;
          shortPositionWeight = 0.70;
      }
      else if(SMA27 > SMA3 && SMA3 > SMA9 && SMA9 > SMA81)
      {
          longPositionWeight = 0.70;
          shortPositionWeight = 0.30;
      }
      else if(SMA27 > SMA3 && SMA3 > SMA81 && SMA81 > SMA9) // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA27 > SMA9 && SMA9 > SMA3 && SMA3 > SMA81)  // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA27 > SMA9 && SMA9 > SMA81 && SMA81 > SMA3) // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA27 > SMA81 && SMA81 > SMA3 && SMA3 > SMA9)
      {
          longPositionWeight = 0.30;
          shortPositionWeight = 0.70;
      }
      else if(SMA27 > SMA81 && SMA81 > SMA9 && SMA9 > SMA3)
      {
          longPositionWeight = 0.20;
          shortPositionWeight = 0.80;
      }
      else if(SMA81 > SMA3 && SMA3 > SMA9 && SMA9 > SMA27)  // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA81 > SMA3 && SMA3 > SMA27 && SMA27 > SMA9) // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;
          shortPositionWeight = 0.50;
      }
      else if(SMA81 > SMA9 && SMA9 > SMA3 && SMA3 > SMA27)  // Tan poca fuerza que apenas es tendencia
      {
          longPositionWeight = 0.50;   
          shortPositionWeight = 0.50;  
      }
      else if(SMA81 > SMA9 && SMA9 > SMA27 && SMA27 > SMA3)
      {
          longPositionWeight = 0.30;
          shortPositionWeight = 0.70;
      }
      else if(SMA81 > SMA27 && SMA27 > SMA3 && SMA3 > SMA9)
      {
          longPositionWeight = 0.20;
          shortPositionWeight = 0.80;
      }
      else if(SMA81 > SMA27 && SMA27 > SMA9 && SMA9 > SMA3)
      {
          longPositionWeight = 0.10;
          shortPositionWeight = 0.90;
      }
      
                              
   
   
   // Determinar si el modo es agresivo o pasivo
      currentMode = (longPositionWeight != shortPositionWeight) ? AGGRESSIVE : PASSIVE;
      

   // Determinar el SL dinamico en base a la desviación estandar (mas ajustes que con ATR) del activo de forma simple y dando mas incapié en el closing price, shift de 3 velas y viendo el rango de las ultimas 11 velas   
      StdDevValue = NormalizeDouble(StdDevArray[0], _Digits);
      dynamicSL = NormalizeDouble((StdDevValue * StdDevMultiplier), 0); // ajustar esto para los decimales del SL
      
   // Establecer el valor del ADX y el RSI actual     
      RSIValue = NormalizeDouble(RSIArray[0], 0);
      ADXValue = NormalizeDouble(ADXArray[0], 0);
   
   // Mostrar los pesos, las EMAs y el modo en la esquina superior izquierda del gráfico
      Comment(
         "Fast SMA: ", DoubleToString(SMA3, _Digits), "\n",
         "Medium SMA: ", DoubleToString(SMA9, _Digits), "\n",
         "Slow SMA: ", DoubleToString(SMA27, _Digits), "\n",
         "SuperSlow SMA: ", DoubleToString(SMA81, _Digits), "\n",
         "Peso Long: ", DoubleToString(longPositionWeight, 2), "\n",
         "Peso Short: ", DoubleToString(shortPositionWeight, 2), "\n",
         "Volatilidad Tick: ", DoubleToString(VolatilityTick, _Digits), "\n",
         "Valor ADX: ", DoubleToString(ADXValue, 0), "\n", 
         "Valor RSI: ", DoubleToString(RSIValue, 0), "\n", 
         "Valor StdDev: ", DoubleToString(StdDevValue, _Digits), "\n",
         "SL dinámico: ", DoubleToString(dynamicSL, 0), "\n",      
         "Modo: ", (currentMode == AGGRESSIVE ? "Agresivo" : "Pasivo"), "\n"    
             );
             
   
   // Determinar el multiplicador de lote basado en la volatilidad del tick
      double positionMultiplier;
      if(VolatilityTick < TickVolatilityThresholdLow)
        {
         positionMultiplier = VolatilityTickLowLotMultiplier;
        }
      else
         if(VolatilityTick > TickVolatilityThresholdHigh)
           {
            positionMultiplier = VolatilityTickHighLotMultiplier;
           }
         else
           {
            positionMultiplier = 1; // Si no hay volatilidad alta ni baja lote normal
           }
   
   
      double lotSize = NormalizeDouble(sizeLot * positionMultiplier, 2); //Redondeado a 2 dcimales formato ...n.nn
      
   
   // Verificar el spread antes de abrir una operación
      double spread = NormalizeDouble(SymbolInfoDouble(TradeSymbol, SYMBOL_ASK) - SymbolInfoDouble(TradeSymbol, SYMBOL_BID), _Digits);
      if(spread > MaxAllowedSpread)
       {
         Print("El Spread es más alto que el permitido, no se realizará operación");
         return;
       }
       
       
   
      long volumeTicks = iTickVolume(TradeSymbol, PERIOD_CURRENT, 1);
      if (volumeTicks < MinTickVolume || volumeTicks > MaxTickVolume) 
       {
         Print("El voluemn de ticks de la ultima vela es inferior o superior al umbral minimo o maximo establecido, revisar ultima vela, no se realizará operación");
         return;
       }
       
       
       // Calcular el balance de la cuenta y el valor de las posiciones actuales
      double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double totalPositionValue = GetTotalPositionValue(); 
   
      // Verificar si el valor total de las posiciones supera el 30% del balance
      double maxAllowedValue = accountBalance * MaximumAccountBalanceTotalPositionWeight;
      if (totalPositionValue > maxAllowedValue)
      {
         Print("El valor total de las posiciones supera el 30% del balance de la cuenta. No se realizarán más operaciones hasta que no se cierren algunas."); //Se debe ajustar el % de este comentario en funcion dle int de la variable global
         return;
      }
      
        
      // Enviar órdenes según las órdenes dinámicas para este símbolo
      for(int i = 0; i <= BasePendingOrdersPerInterval; i++) 
      {   
             if(longPositionWeight > shortPositionWeight && RSIValue >= RSIbuythreshold && ADXValue >= ADXtrendthreshold) //Que el RSI sea superior a 30
               {
                PlaceLimitOrder(true, lotSize);            // Orden de compra pendiente
               }
            else
                if(shortPositionWeight > longPositionWeight && RSIValue <= RSIsellthreshold && ADXValue >= ADXtrendthreshold) //Que el RSI sea inferior a 70
                  {
                   PlaceLimitOrder(false, lotSize);        // Orden de venta pendiente
                  }
                else
                    if(shortPositionWeight == longPositionWeight && iClose(TradeSymbol, PERIOD_CURRENT, 1) > iOpen(TradeSymbol, PERIOD_CURRENT, 1) && RSIValue > RSIbuythreshold && RSIValue < RSIsellthreshold) 
                      {
                       PlaceLimitOrder(false, lotSize);    // Orden de venta pendiente
                      }
                    else
                        if(shortPositionWeight == longPositionWeight && iClose(TradeSymbol, PERIOD_CURRENT, 1) < iOpen(TradeSymbol, PERIOD_CURRENT, 1) && RSIValue > RSIbuythreshold && RSIValue < RSIsellthreshold) // la ultima configuracion de smas indicó venta por tendencia hacia arriba)
                          {
                           PlaceLimitOrder(true, lotSize); // Orden de compra pendiente
                          }
                          else
                            {
                            Print("No se cumplieron las tres condiciones de congruencia de tendencia, rsi y adx ", GetLastError());
                            return;
                            }
                
          }
      
      
      // Pequeño retraso entre órdenes
      EventSetMillisecondTimer(millisecondsSetBetweenPendingOrders);  // los milisegundos selecionados, 300 son 0.3s, 30000 seran 30s
      
      // Monitorear la ganancia diaria
      CheckDailyProfitThreshold();
      
      
      // Administrar posiciones abiertas
      ManageOpenPositions();
     
 } 
   
     
//+------------------------------------------------------------------+
//| Función para calcular el valor total de posiciones abiertas      |
//+------------------------------------------------------------------+
double GetTotalPositionValue()
{
   double totalValue = 0.0;

   // Iterar por todas las posiciones abiertas
   for (int posIndex = 0; posIndex <= PositionsTotal(); posIndex++)
   {
      ulong ticket = PositionGetTicket(posIndex);                       // Obtener el ticket de la posición actual
      if (ticket != 0)                                                  // Asegurarse de que el ticket sea válido
      {
         double volume = PositionGetDouble(POSITION_VOLUME);            // Obtener el volumen
         double price = PositionGetDouble(POSITION_PRICE_CURRENT);      // Obtener el precio de apertura
         totalValue += volume * price;                                  // Calcular y sumar al total
      }
   }

   return totalValue;
}


//+------------------------------------------------------------------+
//| Función para colocar órdenes limit                               |
//+------------------------------------------------------------------+    
void PlaceLimitOrder(bool isBuy, double lotSize)
  {
  
   double limitPrice, tp, sl;
   double scaleFactor = MathPow(10, -_Digits);
   datetime expirationTime = TimeCurrent() + datetime(PendingOrderTimeoutSeconds); //Minimo 2 minutos permite MT5 o 120 segundos
   comment = //"longW.: " + DoubleToString(longPositionWeight, 2) +
                    //", shortW.: " + DoubleToString(shortPositionWeight, 2) +
                    //", StdDevValue: " + DoubleToString(StdDevValue, _Digits) +
                    //", RSIValue: " + DoubleToString(RSIValue, 0) +
                    //", ADXValue: " + 
                    DoubleToString(ADXValue, 0);
   
   if(isBuy)
     {
      limitPrice = SymbolInfoDouble(TradeSymbol, SYMBOL_BID); //se podria cambiar esto por el ask y el otro de debajo por el bid y asi se asumiria que el precio deberia corregir 
      tp = limitPrice + (currentMode == AGGRESSIVE ? MinProfitPips * AggressiveProfitMultiplier : MinProfitPips);
      sl = limitPrice - dynamicSL * scaleFactor;
     }
   else
     {
      limitPrice = SymbolInfoDouble(TradeSymbol, SYMBOL_ASK);
      tp = limitPrice - (currentMode == AGGRESSIVE ? MinProfitPips * AggressiveProfitMultiplier : MinProfitPips);
      sl = limitPrice + dynamicSL * scaleFactor;
     }
   
   MqlTradeRequest request;
   MqlTradeResult result;
   ZeroMemory(request);
   ZeroMemory(result);


   //Se debe ajustar el tema de la expiracion de ordenes pendientes tal vez. 
   //Revisar eta web para hacer buenos requests y entender el formato https://www.mql5.com/en/docs/constants/tradingconstants/orderproperties
   request.action = TRADE_ACTION_PENDING;
   request.symbol = TradeSymbol;
   request.volume = lotSize;
   request.price = limitPrice;
   request.expiration = expirationTime;
   request.type_time = ORDER_TIME_SPECIFIED; 
   request.sl = sl;
   request.tp = tp;
   request.deviation = 1;
   request.magic = ORDER_TICKET;
   request.type = isBuy ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;
   request.type_filling = ORDER_FILLING_IOC;
   request.comment = comment; //Esto imprime como comentario para luego filtrar en el csv las propiedades del mercado que ha condicionado cada orden, nos permitir'a identificar que escenarios hacen que se nos cierren mas ordenes  
 
   if(!OrderSend(request, result))
     {
      Print("Error al colocar la limit order:", GetLastError());
     }
  }


//+------------------------------------------------------------------+
//| Función para administrar posiciones abiertas                     |
//+------------------------------------------------------------------+
void ManageOpenPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
         ulong ticket = PositionGetInteger(POSITION_TICKET);      

         // Verificar si la posición está en ganancia mínima o alcanzó SL
         double tp = PositionGetDouble(POSITION_TP);
         double sl = PositionGetDouble(POSITION_SL);
         
         double profit = PositionGetDouble(POSITION_PROFIT);
         if(profit >= MinProfitPips || sl >= dynamicSL) 
           {
            // Cerrar posición
            CloseOpenPosition(ticket);         
           }        
     }
  }


//+------------------------------------------------------------------+
//| Función para cerrar posición abierta                             |
//+------------------------------------------------------------------+
void CloseOpenPosition(ulong ticket)
{
    datetime openTime = datetime (PositionGetInteger(POSITION_TIME));  // Tiempo de apertura de la posición
    datetime closeTime = TimeCurrent();                                // Tiempo actual al cerrar la posición
    int timeSpent = int(closeTime - openTime);                         // Tiempo que estuvo abierta la posición en segundos o milisegundos

    string oldComment = comment;                                       // Comentario existente de la posición
    string newComment = StringFormat(oldComment, timeSpent);           // Añadir tiempo al comentario
    double volume = PositionGetDouble(POSITION_VOLUME);
    double profit = PositionGetDouble(POSITION_PROFIT);

    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    SendDataToCSV(ticket, profit, volume, newComment);
    
    // Configurar la solicitud de cierre
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = TradeSymbol;
    request.volume = volume;
    request.comment = newComment; // Agregar el comentario con el tiempo de exposición

    if (!OrderSend(request, result)) 
     {
      Print("Error al cerrar la posición: Ticket ", ticket, " Error: ", GetLastError());
     }
     
    if (newComment==oldComment)
     {
     Alert("El nuevo comentario no contiene lo del tiempo");
     }       
      
}


//+------------------------------------------------------------------+
//| Función para enviar datos a un archivo CSV                       |
//+------------------------------------------------------------------+

//Ajustar bien esto para que haga lo dle CSV como toque

void SendDataToCSV(ulong ticket, double profit, double volume, string newcomment){

    string fileName = "trading_log.csv";
    int fileHandle;

    // Directorio donde se guardará el archivo
    string filePath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\Files\\";
 
    // Mirar si ya existe el CSV en el directorio 
    if(!FileIsExist(fileName)){
    
       // FileOpen() puede tanto crear como acceder al archivo
       fileHandle = FileOpen(fileName, FILE_WRITE|FILE_CSV);
       
       if(fileHandle == INVALID_HANDLE){
          Print("Error al crear CSV: ", GetLastError());
          return;
       }
       
       Print("Creando archivo CSV en: ", filePath);
       
       // Redactar encabezados
       FileWrite(fileHandle, "Ticket", "Profit", "Volume", "Comment");
       
    }
    else {
       fileHandle = FileOpen(fileName, FILE_READ|FILE_WRITE|FILE_CSV);
       
       if(fileHandle == INVALID_HANDLE){
          Print("Error al abrir CSV: ", GetLastError());
          return;
       }
       
       // Mover la posición del puntero del CSV al final
       FileSeek(fileHandle, 0, SEEK_END);   
    }
    
    // Escribir los datos de la posición cerrada en el archivo
    FileWrite(fileHandle, ticket, profit, volume, newcomment);
    Print("Datos escritos en CSV: Ticket=", ticket, " Profit=", profit, " Volume=", volume, " Comment=", newcomment);
    
    // Cerrar el archivo
    FileClose(fileHandle);
    Print("Datos guardados en CSV: ", filePath);
    
 }


//+------------------------------------------------------------------+
//| Función principal para monitorear la ganancia diaria             |
//+------------------------------------------------------------------+
void CheckDailyProfitThreshold()
{
    // Verificar si estamos dentro del rango de tiempo permitido
    datetime currentTime = TimeCurrent();
    
    // Verificar si estamos dentro del horario permitido y fuera de este no se opera
    if (currentTime < startTime + StartMonitoringHour || currentTime > startTime + EndMonitoringHour)
        return;

    // Calcular ganancia diaria actual y compararla con la del balance a las 7 AM
    dailyInitialBalance = GetDailyInitialBalance(); 
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double profitPercentage = (currentBalance - dailyInitialBalance) / dailyInitialBalance;
    double profitAbsolute = currentBalance - dailyInitialBalance;

    // Verificar si se alcanzó el umbral
    if (profitPercentage >= DailyProfitThreshold)
    {
        if (!dailyThresholdReached) // Solo mostrar mensaje la primera vez
        {
            dailyThresholdReached = true;
            Print("Umbral diario alcanzado: Ganancia del ", DoubleToString(profitPercentage * 100, 2), "%.");
            Alert("Bot detenido: umbral diario alcanzado y ganancia de: ", DoubleToString (profitAbsolute, 2), "\n");
        }

        // Detener operaciones sin apagar el bot
        return;
    }
}


//+------------------------------------------------------------------+
//| Función para verificar si es un nuevo día                        |
//+------------------------------------------------------------------+
bool IsNewDay()
{
    MqlDateTime currentDateTime, startDateTime;
    TimeToStruct(TimeCurrent(), currentDateTime); // Obtener la fecha y hora actuales
    TimeToStruct(startTime, startDateTime);       // Obtener la fecha y hora del inicio del día

    // Comparar año, mes y día
    if (currentDateTime.year != startDateTime.year || currentDateTime.mon != startDateTime.mon || currentDateTime.day != startDateTime.day)
    {
        return true; // Es un nuevo día
    }

    return false; // No es un nuevo día
}


//+------------------------------------------------------------------+
//| Función para obtener el balance inicial a las 7:00 AM            |
//+------------------------------------------------------------------+
double GetDailyInitialBalance()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dateTime;
    TimeToStruct(currentTime, dateTime);

    // Si el tiempo actual es antes de las 7:00 AM, usar el balance actual
    if (currentTime < startTime + StartMonitoringHour)
        return AccountInfoDouble(ACCOUNT_BALANCE);

    // Si es después de las 7:00 AM, usar el balance al inicio del día
    return AccountInfoDouble(ACCOUNT_BALANCE);
}


//+------------------------------------------------------------------+
//| Función para obtener el inicio del día a las 7:00 AM             |
//+------------------------------------------------------------------+
datetime GetStartOfDay()
{
    datetime currentDate = TimeCurrent();
    MqlDateTime dateTime;
    TimeToStruct(currentDate, dateTime);

    // Configurar hora del inicio del día en la que el bot empezará a analizar (como 7:00 AM)
    dateTime.hour = StartHourIntFormat;
    dateTime.min = 0;
    dateTime.sec = 0;

    return StructToTime(dateTime);
}

//Final del codigo
// SE DEBEN HACER MEJORAS Y MUCHO MAS CUANTITATIVO MULTIASSET Y DINAMICO TENIENDO EN CUENTA MAS DE 300 COMPONENTES ENTRE INDICADORES Y TIMEFRAMES