input int period = 60; // Número de segundos entre cada entry  
input string fileName = "data.csv";

datetime last_time; // mirar si esta abierto el mercado

// Timeframes que se utilizarán (https://www.mql5.com/en/docs/constants/chartconstants/enum_timeframes)
int timeframes[] = {PERIOD_M1, PERIOD_M5, PERIOD_M15, PERIOD_H1, PERIOD_H6, PERIOD_H12, PERIOD_D1, PERIOD_W1, PERIOD_MN1};


int OnInit() {
   EventSetTimer(period); // creamos timer
   
   return(INIT_SUCCEEDED);
}

// https://www.mql5.com/en/docs/event_handlers/ondeinit
void OnDeinit(const int reason){
   EventKillTimer();
}

// https://www.mql5.com/en/docs/event_handlers/ontimer
void OnTimer(){

   if(TimeCurrent() != last_time){
      IndicatorCSV();
      last_time = TimeCurrent();
   }
}

void IndicatorCSV(){

   int fileHandle;

   // Si no existe el CSV lo creamos
   if(!FileIsExist(fileName)){
 
      fileHandle = FileOpen(fileName, FILE_WRITE|FILE_CSV);
    
      if(fileHandle == INVALID_HANDLE){
         Print("Error al crear CSV: ", GetLastError());
         return;
      }
    
      // Redactar encabezados
      string indicators[] = {"ADX", "RSI", "StdDev"};
      string headers = "Time,Ticker,Bid,Ask,";
    
      for(int i = 0; i<ArraySize(timeframes); i++){
         for(int j = 0; j < ArraySize(indicators); j++){
            headers += indicators[j] + "_" + StringSubstr(EnumToString((ENUM_TIMEFRAMES)timeframes[i]),7) + ","; // Nos cercioramos de tener el timeframe en el buen formato
         }
      }
      headers = StringSubstr(headers,0,StringLen(headers)-1); // Quitar última ","
      
      FileWrite(fileHandle, headers);
    
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
 
 
   MqlTick last_tick;
 
   string newLine;
   
   // Conseguimos la hora, el bid y el ask del último tick
   if(SymbolInfoTick(Symbol(),last_tick)){
      newLine = TimeToString(last_tick.time) + "," + _Symbol + "," + DoubleToString(last_tick.bid) + "," + DoubleToString(last_tick.ask) + ",";
   }
   else{
      Print("ERROR: ", GetLastError());
   }
 
   for(int i = 0; i < ArraySize(timeframes); i++){
      
      // Creamos las listas de los indicadores
      double ADXArray[], RSIArray[], StdDevArray[];

      // Lo pasamos a series para que los nuevos elementos estén indexados en la pos 0
      ArraySetAsSeries(ADXArray, true);
      ArraySetAsSeries(RSIArray, true);
      ArraySetAsSeries(StdDevArray, true);
   
      // https://www.mql5.com/en/docs/indicators
      int ADXHandle = iADX(_Symbol, (ENUM_TIMEFRAMES)timeframes[i], 14);
      int RSIHandle = iRSI(_Symbol, (ENUM_TIMEFRAMES)timeframes[i], 14, PRICE_CLOSE);
      int StdDevHandle = iStdDev(_Symbol, (ENUM_TIMEFRAMES)timeframes[i], 20, 0, MODE_SMA, PRICE_CLOSE);
   
      // Copiamos los 3 valores de cada indicador
      CopyBuffer(ADXHandle, 0, 0, 3, ADXArray);
      CopyBuffer(RSIHandle, 0, 0, 3, RSIArray);
      CopyBuffer(StdDevHandle, 0, 0, 3, StdDevArray);
    
      // Normalizamos los valores
      double ADXValue = NormalizeDouble(ADXArray[0], 3);
      double RSIValue = NormalizeDouble(RSIArray[0], 3);
      double StdDevValue = NormalizeDouble(StdDevArray[0], 7); // El último parámetro define el num de decimales
   
      // Creamos una nueva entry para el CSV
      newLine += DoubleToString(ADXValue) + "," + DoubleToString(RSIValue) + "," + DoubleToString(StdDevValue) + ",";

      // Liberamos las handles de los indicadores para liberar memoria
      IndicatorRelease(ADXHandle);
      IndicatorRelease(RSIHandle);
      IndicatorRelease(StdDevHandle);
   }

   newLine = StringSubstr(newLine,0,StringLen(newLine)-1); // Quitar última ","
   
   FileWrite(fileHandle, newLine);
   FileClose(fileHandle);
 
}