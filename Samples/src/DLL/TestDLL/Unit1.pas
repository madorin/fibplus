unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, DB, FIBDataSet, pFIBDataSet, FIBDatabase, pFIBDatabase,
  ExtCtrls, StdCtrls, Grids, DBGrids, ibase;

type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    db: TpFIBDatabase;
    tr: TpFIBTransaction;
    dt: TpFIBDataSet;
    ds: TDataSource;
    Label2: TLabel;
    DBGrid1: TDBGrid;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

  procedure ShowFormFromDLL(AppHandle: THandle; DBHandle: TISC_DB_HANDLE); StdCall;

exports
  ShowFormFromDLL;
{$I FIBExamples.inc}

implementation

procedure ShowFormFromDLL(AppHandle: THandle; DBHandle: TISC_DB_HANDLE);
begin
  try
    Application.Handle := AppHandle;
    Form1 := TForm1.Create(Application);
   {$IFDEF FBCLIENT.DLL}
    Form1.db.LibraryName:='fbclient.dll';
   {$ENDIF}

    Form1.db.Handle := DBHandle;
    Form1.dt.Open;
    Form1.ShowModal;
  finally
    Form1.dt.Close;
    Application.Handle := 0;
    Form1.Free;
  end;
end;


{$R *.dfm}

end.
