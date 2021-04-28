unit Serial_Port;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ComObj, ExtCtrls, Buttons;

const
  cmRxByte = wm_User+$55;
  WM_COPYDATA = wm_User+$3000;

type
  TForm1 = class(TForm)
    TxEdit: TEdit;
    StatusBar1: TStatusBar;
    SpeedBox: TComboBox;
    PortBox: TComboBox;
    Label1: TLabel;
    Button1: TButton;
    CheckBox1: TCheckBox;
    Label2: TLabel;
    DataGroup: TRadioGroup;
    StopGroup: TRadioGroup;
    ParityBox: TComboBox;
    Label3: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    RxMem: TMemo;
    SpeedButton3: TSpeedButton;
    procedure RecivBytes(var Msg : TMessage); message cmRxByte;
    procedure PortBoxEnter(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmMain: TForm1;
  autoscroll:Bool;
  isStopped: Bool;

implementation
uses MyComm;
{$R *.dfm}


//===================================RecivBytes===================================



 procedure TForm1.WMCopyData(var Msg: TWMCopyData);
 var
   sText: array[0..49] of Char;
   i:integer;
   tmp:String;
 begin                                   
   // generate text from parameter
  // anzuzeigenden Text aus den Parametern generieren
  StrLCopy(sText, Msg.CopyDataStruct.lpData, Msg.CopyDataStruct.cbData);
   // write received text
   for i:=0 to 49 do begin
    tmp:=tmp+sText[i];
   end;
  RxMem.Lines.Add(tmp);
 end;

      procedure TForm1.RecivBytes(var Msg: TMessage);   //Messages from second thread
       var
        s:PChar;
          begin
              case Msg.WParam of

                 //Message with pipette pressure
                 1: begin
                      s:=PChar(Pointer(Msg.LParam)^);
                      RxMem.Lines.Add(string(s));
                      if autoscroll = false then
                        SendMessage(RxMem.Handle, WM_VSCROLL, SB_LINEDOWN, 0)
                      else RxMem.SelStart:=RxMem.Lines.Count +1;
                      Application.ProcessMessages;
                    end;

                 //Connecting protocol
                 2: begin
                       Application.ProcessMessages;
                    end;
              end;
          end;

//===================================RecivBytes===================================

//********************************************************************************

//==================================FillCommList==================================
   //Процедура поиска свободных COM-портов
  function FillCommList( List : Tstrings ): integer;
      var
        ComName: string;
        i: integer;
        pPath : pchar;
        Size : Cardinal;
      begin
        List.Clear();               //Очистка предыдущих значений
        pPath := Stralloc( 256 );   //Задание размера буфера
          try                       //Пробуем найти порты
            for i := 1 to 99 do
              begin
                pPath[0] := #0;
                ComName := 'COM' + inttostr( i );
                QueryDosDevice( pchar( ComName), pPath, Size );  //Спец функция
                                                                 //поиска подключенных
                                                                 //устройств
                if CompareText( pPath, '' ) <> 0 then            //Добавление в список
                List.AddObject( ComName, pointer( i ) );
            end;
          finally
            strdispose( pPath );                                 //Процедура освобождения строки
          end;
        result := List.Count;
      end;

//==================================FillCommList==================================

//********************************************************************************

//=================================PortBoxEnter===================================

    //Заполнение СОМ-портоа после нажатия на BOX
    procedure TForm1.PortBoxEnter(Sender: TObject);
      begin
        FillCommList(PortBox.Items);
      end;
//=================================PortBoxEnter===================================

//********************************************************************************

//==================================FormCreate====================================

    procedure TForm1.FormCreate(Sender: TObject);
      begin
          DataGroup.ItemIndex:=3;
          StopGroup.ItemIndex:=1;
          ParityBox.ItemIndex:=0;
          SpeedBox.ItemIndex:=0;
      end;
//==================================FormCreate====================================

//********************************************************************************

//=================================ButtonsClick===================================

    procedure TForm1.Button1Click(Sender: TObject);
      begin
          RxMem.Lines.Clear;
      end;

  procedure TForm1.CheckBox1Click(Sender: TObject);
      begin
          if CheckBox1.Checked = true then autoscroll:= false
          else autoscroll:= true;
      end;

    procedure TForm1.SpeedButton1Click(Sender: TObject);
    var
      stopbits:integer;
      begin
            if StartService = true then ShowMessage('Com-Port Started Succesfully');
            isStopped:=false;
      end;

    procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
      begin
          if isStopped=false then
          StopService;
      end;

    procedure TForm1.SpeedButton2Click(Sender: TObject);
      begin
          WriteStrToPort(TxEdit.Text);
      end;

procedure TForm1.SpeedButton3Click(Sender: TObject);
begin
     StopService;
     ShowMessage('Com-Port Stopped Succesfully');
     isStopped:=true;
end;

end.
