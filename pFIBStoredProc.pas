{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2007 Devrace Ltd.                       }
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}


{Special thanks to Vadim Yegorov <zg@matrica.apollo.lv>}

unit pFIBStoredProc;

interface

{$I FIBPlus.inc}
uses
  Classes,pFIBQuery, FIBQuery,FIBDataBase;

type
  TpFIBStoredProc = class(TpFIBQuery)
  private
    FStoredProc: string;
    FDefaultValues:TStrings;
    FDefaultLoaded:boolean;
    procedure SetStoredProc(const Value: string);
    procedure LoadDefaults;
  protected
    procedure SetDatabase(Value: TFIBDatabase); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function   GetParamDefValue(ParamNo:integer):string; overload;
    function   GetParamDefValue(const ParamName:string):string; overload;

  published
    property StoredProcName: string read FStoredProc write SetStoredProc;
  end;

implementation

uses
   pFIBDatabase, StrUtil, SysUtils,pFIBDataInfo,pFIBCacheQueries;

const
 qParDefaults=
  'SELECT PP.RDB$PARAMETER_NAME AS PARAMETER_NAME, F.RDB$DEFAULT_SOURCE '+
  'FROM RDB$PROCEDURE_PARAMETERS PP JOIN RDB$FIELDS F ON F.RDB$FIELD_NAME = PP.RDB$FIELD_SOURCE '+
  'WHERE PP.RDB$PROCEDURE_NAME = :RN AND  PP.RDB$PARAMETER_TYPE = :RT '+
  'ORDER BY PP.RDB$PARAMETER_NUMBER';

procedure TpFIBStoredProc.SetStoredProc(const Value: string);
var ProcName:string;
begin
  if (Value <> FStoredProc) then
  begin
   FStoredProc := Value;
   if not (csReading in ComponentState) then
   begin
//     FBase.CheckDatabase;
     if Assigned(Database) then
     if  IsBlank(Value) then
      SQL.Clear
     else
     begin
      ProcName:=EasyFormatIdentifier(Database.SQLDialect, FStoredProc,
       Database.EasyFormatsStr
      );
      SQL.Text :=
       ListSPInfo.GetExecProcTxt(Database,
        ProcName
        ,csDesigning in ComponentState
       );
     end;
   end;
  end;
end;

constructor TpFIBStoredProc.Create(AOwner: TComponent);
begin
  inherited;
  FStoredProc := '';
  FDefaultValues:=TStringList.Create;
end;


destructor TpFIBStoredProc.Destroy;
begin
  FDefaultValues.Free;
  inherited;
end;

function TpFIBStoredProc.GetParamDefValue(const ParamName: string): string;
var
   ParamNo:Integer;
begin
//For Firebird only
 ParamNo:=ParamByName(ParamName).Index;
 Result:=GetParamDefValue(ParamNo)
end;

function TpFIBStoredProc.GetParamDefValue(ParamNo: integer): string;
begin
//For Firebird only
 if not FDefaultLoaded then
   LoadDefaults;
 if FDefaultValues.Count>ParamNo then
 {$IFNDEF D7+}
  begin
   Result:=FDefaultValues.Names[ParamNo];
   Result:=FDefaultValues.Values[Result];
  end 
 {$ELSE}
  Result:=FDefaultValues.ValueFromIndex[ParamNo]
 {$ENDIF}
 else
  Result:='';
end;


procedure TpFIBStoredProc.LoadDefaults;
var
 ProcName:string;
 Query: TFIBQuery;
 Trans:TFIBTransaction;
 FreeTrans,CloseTrans:boolean;
begin
//For Firebird only
 FDefaultValues.Clear;
 FDefaultLoaded:=False;
 if (Length(FStoredProc)=0)  or (Database=nil) then
  Exit;

 ProcName:=EasyFormatIdentifier(Database.SQLDialect, FStoredProc,
   Database.EasyFormatsStr
 );
//Init Transaction
 FreeTrans:=False;
 CloseTrans:=False;
 if (Transaction<>nil) and Transaction.Active then
  Trans:=Transaction
 else
  Trans:=Database.FirstActiveTransaction;
 if (Trans=nil) then
 begin
  Trans:=TFIBTransaction.Create(Self);
  Trans.DefaultDatabase:=Database;
  FreeTrans:=True
 end;
//end Init Transaction
 Query :=GetQueryForUse(Trans,qParDefaults);
 try

  Query.Params[0].AsString:=ProcName;
  Query.Params[1].AsInteger:=0;
  if not Trans.Active then
  begin
   CloseTrans:=True;
   Trans.StartTransaction;
  end;
  Query.ExecQuery;
  while not Query.Eof do
  begin
   FDefaultValues.Add(Trim(Query.Fields[0].asString)+Trim(Query.Fields[1].asString));
   Query.Next;
  end;
 finally
   FreeQueryForUse(Query);
   if CloseTrans then
    if Trans.Active then
     Trans.Commit;
   if FreeTrans then
   begin
    Trans.Free;
   end;
 end;
 FDefaultLoaded:=True
end;

procedure TpFIBStoredProc.SetDatabase(Value: TFIBDatabase);
var
  s:string;

begin
  inherited SetDatabase(Value);
  if Assigned(Value) and (Length(FastTrim(SQL.Text))=0)
   and (Length(FStoredProc)>0)
  then
  begin
    s:=FStoredProc;
    FStoredProc:='';
    StoredProcName:=s
  end;
end;

end.

