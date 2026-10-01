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

{ Special thanks to Vadim Yegorov <zg@matrica.apollo.lv> }

unit pFIBStoredProc;

interface

{$I FIBPlus.inc}

uses
  pFIBQuery, FIBDatabase;

type
  TpFIBStoredProc = class(TpFIBQuery)
  private
    FStoredProcName: string;
    // SQL is built from metadata, deferred until the database is connected
    FSQLDeferred: Boolean;
    procedure SetStoredProcName(const Value: string);
    function FormattedName: string;
    procedure BuildSQL;
    procedure DeferMissingSQL;
  protected
    procedure BuildDeferredSQL; override;
    procedure SetDatabase(Value: TFIBDatabase); override;
  public
    procedure Loaded; override;
    function IsProc: Boolean; override;
    // Parameter defaults exist since Firebird 2.0
    function GetParamDefValue(ParamNo: Integer): string; overload;
    function GetParamDefValue(const ParamName: string): string; overload;
  published
    property StoredProcName: string read FStoredProcName write SetStoredProcName;
  end;

implementation

uses
  Classes, SysUtils, StrUtil, pFIBDataInfo;

procedure TpFIBStoredProc.SetStoredProcName(const Value: string);
begin
  if Value = FStoredProcName then
    Exit;
  FStoredProcName := Value;
  // While reading, SQL comes from the stream
  if not(csReading in ComponentState) then
    BuildSQL;
end;

function TpFIBStoredProc.FormattedName: string;
begin
  Result := EasyFormatIdentifier(Database.SQLDialect, FStoredProcName, Database.EasyFormatsStr);
end;

procedure TpFIBStoredProc.BuildSQL;
var
  SQLText: string;
  Deferred: Boolean;
begin
  SQLText := '';
  Deferred := not IsBlank(FStoredProcName);
  try
    if Deferred and Assigned(Database) and Database.Connected then
    begin
      // In the IDE the procedure may have been altered, re-read its metadata
      SQLText := ListSPInfo.GetExecProcTxt(Database, FormattedName, csDesigning in ComponentState);
      Deferred := False;
    end;
  finally
    // Also on failure, so the SQL of the previous procedure can't be run.
    // Not deferred meanwhile: SQL change notifications read Params.
    FSQLDeferred := False;
    SQL.Text := SQLText;
    FSQLDeferred := Deferred;
  end;
end;

// Name set before the database, or component stored without SQL
procedure TpFIBStoredProc.DeferMissingSQL;
begin
  if not FSQLDeferred and not IsBlank(FStoredProcName) and IsBlank(SQL.Text) then
    FSQLDeferred := True;
end;

procedure TpFIBStoredProc.BuildDeferredSQL;
begin
  if FSQLDeferred and Assigned(Database) and Database.Connected and not(csDestroying in ComponentState) then
    BuildSQL;
end;

// Deferred SQL is a procedure call too, ExecProc must not skip it
function TpFIBStoredProc.IsProc: Boolean;
begin
  BuildDeferredSQL;
  Result := FSQLDeferred or inherited IsProc;
end;

procedure TpFIBStoredProc.SetDatabase(Value: TFIBDatabase);
begin
  inherited SetDatabase(Value);
  if not(csLoading in ComponentState) then
  begin
    DeferMissingSQL;
    BuildDeferredSQL;
  end;
end;

procedure TpFIBStoredProc.Loaded;
begin
  inherited Loaded;
  DeferMissingSQL;
end;

function TpFIBStoredProc.GetParamDefValue(const ParamName: string): string;
begin
  Result := GetParamDefValue(ParamByName(ParamName).Index);
end;

function TpFIBStoredProc.GetParamDefValue(ParamNo: Integer): string;
begin
  if IsBlank(FStoredProcName) or (Database = nil) then
    Result := ''
  else
    Result := ListSPInfo.GetParamDefValue(Database, FormattedName, ParamNo);
end;

end.
