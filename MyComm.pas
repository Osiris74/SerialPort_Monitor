unit MyComm;

interface

uses Windows, SysUtils, Classes, ActiveX,ComObj,Variants,Serial_Port;


type

  // TComThread - child from the class TThread
  TCommThread = class(TThread)
  private
    { Private declarations }
  //procedure, of reading COM-Port
    Procedure QueryPort;
  protected
  //Method of starting thread
     Procedure Execute; override;
  end;

 function StartService:Bool;
 Procedure StopService;
 function WriteStrToPort(Str:String):boolean;
 function CloseComm : boolean;
 function HexToStr(buf:array of byte):string;

Var
CommThread:TCommThread; //Thread, where we will work with COM-port
hPort:Integer;          //port descriptor
isRecieved:boolean;
time_int:double;
dot_Pos:integer;
ComPort,pressureCounter,LogCounter:Integer;
LogBuff:array [0..200,0..1] of string;
FData:Variant;
LogFlag,Terminated:boolean;
implementation

//******************************************************************************

//=================================StartComThread===============================

  Procedure StartComThread;
  //initialization of our thread
    Begin {StartComThread}
      //trying to initialize thread
      CommThread:=TCommThread.Create(False);
      CommThread.Priority:=tpLower;
      //checking the result
      If CommThread = Nil Then
        Begin {Nil}
        //Erorr, exit the application
          SysErrorMessage(GetLastError);
          Exit;
        End; {Nil}
    End; {StartComThread}


//=================================StartComThread===============================


//******************************************************************************


//================================Execute=======================================

  //Starting the procedure interviewing the port
  Procedure TCommThread.Execute;
    Begin {Execute}
      Repeat
        QueryPort;
        // Will work until Terminated
        Until Terminated;
    End;  {Execute}


//================================Execute=======================================


//******************************************************************************


//================================QueryPort=====================================


  //interviewing the port
  Procedure TCommThread.QueryPort;
    Var
      Ovr : TOverlapped;
      Events : array[0..1] of THandle;
      MyBuff:Array[0..3] Of  Byte;              //Buffer for readed inf
      ByteReaded:Dword;                          //Number of readed bytes
      tmp:String;
      pTemp:pChar;
      aCopyData:TCopyDataStruct;
      hTargetWnd:HWND;

    Begin {QueryPort}
      //Read Buffer from Com-port
      FillChar(Ovr,SizeOf(TOverlapped),0);
      Ovr.hEvent:=CreateEvent(nil,TRUE,FALSE,#0);
      Events[0] := Ovr.hEvent;

        If Not ReadFile(hPort,MyBuff,SizeOf(MyBuff),ByteReaded,@Ovr) Then
          Begin {Error with readed files}
            //Error, close all and exit
            SysErrorMessage(GetLastError);
            Exit;
            CloseHandle(Ovr.hEvent);
          End;{Error with readed files}
      //Data recieved
      If ByteReaded>0 Then
        Begin {ByteReaded>0}
        //Making string from recieved buffer        //Получаем строку байтов
              tmp:=HexToStr(MyBuff);                //Отправляем на преобразование
       with aCopyData do
        begin
          dwData :=0;
          cbData :=StrLen(PChar(tmp))+1;
          lpData := PChar(tmp);
        end;
          pTemp:=PChar(HexToStr(MyBuff));
          SendMessage(fmMain.Handle,WM_COPYDATA,longint(Handle),Longint(@aCopyData));

      End; {ByteReaded>0}
End; {QueryPort}

function HexToStr(buf:array of byte):string;      //Функция преобразования в строковый формат
var
i,tmp,tmp1,tmp2, R:integer;
sum:byte;

  begin
    Result:='';
    sum:=0;
    for i:=0 to Length(buf)-2 do begin
      sum:=sum+buf[i];                           //Расчет контрольной суммы
      Result:=Result+'$'+(IntToHex((buf[i]),1));//IntToStr(представит в десятичном виде)
    end;                                        //IntToHex в шестнадцатеричном (IntToHex((buf[i]),1))
                                                //Собираем строку по отдельности из трех байтов

      R:=0;
      R:=R or (buf[2] shl 0);                   //Сдвигаем LSB на 0
      R:=R or (buf[1] shl 8);                   //Сдвигаем средний байт на середину
      R:=R or (buf[0] shl 16);                  //Сдвигаем MSB в конец

      Result:=Result+'  STRING_DEC:  '+'$'+IntToStr(R); //Готовим финальную строку для отправки
    if sum<>buf[3] then Result:='ERROR!  SUM IS INCORRECT';

  end;



//================================QueryPort=====================================


//******************************************************************************


//==================================InitPort====================================


  //Initialization of port
  function InitPort:Bool;
    Var
      DCB: TDCB;         //Structure for settings of COM-Port
      CT: TCommTimeouts; //Structure for timeouts of COM-Port
      stopbits,bytesize:Integer;
    Begin {InitPort}
        hPort := CreateFile(PChar('\\.\' +fmMain.PortBox.Text),
                            GENERIC_READ or GENERIC_WRITE,
                            FILE_SHARE_READ or FILE_SHARE_WRITE,
                            nil, OPEN_EXISTING,
                            FILE_ATTRIBUTE_NORMAL, 0);
        If (hPort < 0)                          //Couldn't create file(initialize port)
          Or Not SetupComm(hPort, 256, 256)     //Couldn't set up buffers
          Or Not GetCommState(hPort, DCB) Then //Couldn't get settings of COM-port
            Begin {Error}
              SysErrorMessage(GetLastError);
              Result:=False;
              Exit;
            End;  {Error}

        //Parameters of port
        DCB.BaudRate := StrToInt(fmMain.SpeedBox.Text); //velocity
        case fmMain.StopGroup.ItemIndex of
          0: stopbits:=0;
          1: stopbits:=2;
        end;
        DCB.StopBits :=stopbits;          //stop bits (0 - 1, 1 - 1,5, 2 - 2)
        DCB.Parity := 0;                  //parity bits
        case fmMain.StopGroup.ItemIndex of
          0:  bytesize:=5;
          1:  bytesize:=8;
          2:  bytesize:=6;
          3:  bytesize:=8;
        end;
        DCB.ByteSize := bytesize;         //bits with information

        If Not SetCommState(hPort, DCB) Then //Couldn't set up settings of COM-port
          Begin {Error}
            SysErrorMessage(GetLastError);
            Result:=False;
            fmMain.RxMem.Lines.Add('Error');
            Exit;
          End; {Error}

        //Setting up timeouts
        If Not GetCommTimeouts(hPort, CT) Then //Couldn't get timeouts
          Begin  {Error}
            SysErrorMessage(GetLastError);
            Result:=False;
            Exit;
            fmMain.RxMem.Lines.Add('Timeouts');
          End; {Error}
        //Timeouts
        CT.ReadTotalTimeoutConstant := 50;
        CT.ReadIntervalTimeout := 50;
        CT.ReadTotalTimeoutMultiplier := 1;
        CT.WriteTotalTimeoutMultiplier := 10;
        CT.WriteTotalTimeoutConstant := 10;

        If Not SetCommTimeouts(hPort, CT) Then //Couldn't set up timeouts
          Begin {Error}
            SysErrorMessage(GetLastError);
            Result:=False;
            Exit;
            fmMain.RxMem.Lines.Add('Set Timeouts');
          End; {Error}
          Result:=True;
    End;{InitPort}


//==================================InitPort====================================


//******************************************************************************


//================================WriteStrToPort================================


  //Write string to port
  function WriteStrToPort(Str:String): boolean;
    Var
      ByteWritten:DWord;
      MyBuff:Array[0..255] Of Char;
      charCtrl:String;
    Begin {WriteStrToPort}

      FillChar(MyBuff,SizeOf(MyBuff),0);    //Preparing buffer
      StrPCopy(MyBuff,Str);               //Copying final string,and writing it

      If Not WriteFile(hPort,MyBuff,Length(Str),ByteWritten,nil) Then
        Begin {Error}
          SysErrorMessage(GetLastError);
          Result:=false;
          Exit;
        End; {Error}
      Result:=true;
    End; {WriteStrToPort}


//================================WriteStrToPort================================


//******************************************************************************


//=====================================StopService==============================

  //Stop COM-port
  Procedure StopService;
    Begin {StopService}
      CloseComm();                        //Close COM-port
      sleep(100);
    End; {StopService}


//==================================StopService==================================


//******************************************************************************


//==================================CloseComm====================================

  //Close COM-Port
  function CloseComm : boolean;
    begin
     SetCommMask(hPort,0);
     sleep(10);
     //Close handle
     CloseHandle(hPort);
     sleep(100);
     DeleteObject(hPort);
     CommThread.Free;                    //Thread free
     Result := True;
  end;


//=====================================CloseComm=================================


//******************************************************************************


//====================================StartService==============================


  //Start COM-port service
  function StartService:Bool;
    Begin {StartService}
                if InitPort = true then
                  begin
                    StartComThread;            //Starting COM thread
                    Result:=True;
                  end;
    End;  {StartService}

//====================================StartService==============================


//******************************************************************************
end.

