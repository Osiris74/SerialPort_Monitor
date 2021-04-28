program Project2;

uses
  Forms,
  Serial_Port in 'C:\For_Alex\Project_MISIS\Project_Prog\Delphie\Serial Port Monitor\Serial_Port.pas' {Form1},
  MyComm in 'C:\For_Alex\Project_MISIS\Project_Prog\Delphie\Serial Port Monitor\MyComm.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, fmMain);
  Application.Run;
end.
