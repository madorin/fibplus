unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, FIBDataSet, pFIBDataSet,FIBQuery, ComCtrls;

type
  TForm2 = class(TForm)
    Label1: TLabel;
    dtGenData: TpFIBDataSet;
    lbProgress: TLabel;
    btnStop: TButton;
    ProgressBar1: TProgressBar;
    procedure dtGenDataAfterFetchRecord(FromQuery: TFIBQuery;
      RecordNumber: Integer; var StopFetching: Boolean);
    procedure btnStopClick(Sender: TObject);
    procedure dtGenDataBeforeOpen(DataSet: TDataSet);
  private
    { Private declarations }
  public
    Stop:Boolean;
    RecNumber:integer;
  end;

var
  Form2: TForm2;

implementation

uses Unit1;

{$R *.dfm}

procedure TForm2.dtGenDataAfterFetchRecord(FromQuery: TFIBQuery;
  RecordNumber: Integer; var StopFetching: Boolean);
begin

   Inc(RecNumber);
   lbProgress.Caption:='Generated '+IntToStr(RecNumber)+ ' record from '+
    dtGenData.Params[0].AsString;
   ProgressBar1.StepIt;
   Application.ProcessMessages;
end;

procedure TForm2.btnStopClick(Sender: TObject);
begin
 Stop:=True
end;

procedure TForm2.dtGenDataBeforeOpen(DataSet: TDataSet);
begin
 RecNumber:=0;
 ProgressBar1.Max:=dtGenData.Params[0].asInteger;
end;

end.
