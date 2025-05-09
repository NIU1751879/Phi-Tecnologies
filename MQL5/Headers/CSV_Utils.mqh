// #include <CSV_Utils.mqh> para usarlo

// Función CSV universal
int AddRowToCSV(string &data[], string filename = "data.csv"){
   
   ResetLastError();
   
   string filePath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\Files\\"; // Por alguna razón no 100% exacto
   int fileHandle = FileOpen(filename, FILE_CSV|FILE_READ|FILE_WRITE|FILE_COMMON, ';');
   
   if(fileHandle == INVALID_HANDLE){
         Print("Error opening file: ", GetLastError());
         return 1;
   }
   
   FileSeek(fileHandle, 0, SEEK_END);
   
   string dataLine = "";
   for (int i = 0; i < ArraySize(data); i++)
   {
      if (i > 0) dataLine += ";";
      dataLine += data[i];
   }
   
   FileWrite(fileHandle, dataLine);
   FileClose(fileHandle);
   Print("File updated at: ", filePath);
   return 0;
}

// Función XtoString universal
/*
string ToString(const int        value)   { return IntegerToString(value); }
string ToString(const char       value)   { return CharToString(value); }
string ToString(const short      value)   { return ShortToString(value); }
string ToString(const color      value)   { return ColorToString(value); }
string ToString(const double     value)   { return DoubleToString(value, 5); }
string ToString(const datetime   value)   { return TimeToString(value, TIME_SECONDS); }
string ToString(const bool       value)   { return value ? "true" : "false"; }
*/