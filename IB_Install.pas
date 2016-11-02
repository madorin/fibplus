{***************************************************************}
{ FIBPlus - component library for direct access to Firebird and }
{ InterBase databases                                           }
{                                                               }
{    FIBPlus is based in part on the product                    }
{    Free IB Components, written by Gregory H. Deatz for        }
{    Hoagland, Longo, Moran, Dunst & Doukas Company.            }
{    mailto:gdeatz@hlmdd.com                                    }
{                                                               }
{    Copyright (c) 1998-2013 Devrace Ltd.                       }
{    Written by Serge Buzadzhy (buzz@devrace.com)               }
{                                                               }
{ ------------------------------------------------------------- }
{    FIBPlus home page: http://www.fibplus.com/                 }
{    FIBPlus support  : http://www.devrace.com/support/         }
{ ------------------------------------------------------------- }
{                                                               }
{  Please see the file License.txt for full license information }
{***************************************************************}


unit IB_Install;

interface
{$I FIBPlus.inc}
uses
   TypInfo, SysUtils, Classes, IB_InstallHeader, IB_Intf;

type

  TIscError = MSG_NO;
  TIBInstallerError = (ieSuccess,
                       ieDelphiException,
                       ieNoOptionsSet,
                       ieNoDestinationDirectory,
                       ieNosourceDirectory,
                       ieNoUninstallFile,
                       ieOptionNeedsClient,
                       ieOptionNeedsServer,
                       ieInvalidOption,
                       ieInvalidOnErrorResult,
                       ieInvalidOnStatusResult);

  TMainOption = (moServer,
                 moClient,
                 moConServer,
                 moGuiTools,
                 moDocumentation,
                 moDevelopment);


  TExamplesOption = (exDB, exAPI);
  TCmdOption = (cmDBMgmt, cmDBQuery, cmUsrMgmt);
  TConnectivityOption = (cnODBC, cnOLEDB, cnJDBC);

  TMainOptions = set of TMainOption;
  TExamplesOptions = set of TExamplesOption;
  TCmdOptions = set of TCmdOption;
  TConnectivityOptions = set of TConnectivityOption;

  TErrorResult = (erAbort, erContinue, erRetry);
  TStatusResult = (srAbort, srContinue);
  TWarningResult = (wrAbort, wrContinue);

  TpFIBSetupOnStatus = function(Sender : TObject; StatusComment : string):
                              TStatusResult of object;
  TpFIBSetupOnWarning = function(Sender :TObject; WarningCode: TIscError;
                               WarningMessage : string): TWarningResult of object;
  TpFIBSetupOnError = function (Sender : TObject; IscCode : TIscError;
                               ErrorMessage, ErrorComment : string):
                               TErrorResult of object;

  EIBInstall = class(Exception)
  private
    FIscError : MSG_NO;
    FInstallerError : TIBInstallerError;
  public
    constructor Create(IscCode : MSG_NO; IscMessage : string); virtual;
    constructor Create1(ECode  : TIBInstallerError; EMessage : string);virtual;
    property InstallError : MSG_NO read FIscError;
    property InstallerError : TIBInstallerError read FInstallerError;
  end;

  EIBInstallError = class(EIBInstall);  

  EIBInstallerError  = class(EIBInstall);

  TInstallOptions = class(TPersistent)
   private
    FMainComponents : TMainOptions;
    FExamples: TExamplesOptions;
    FCmdLineTools: TCmdOptions;
    FConnectivityClients: TConnectivityOptions;
   published
    property MainComponents : TMainOptions read FMainComponents write FMainComponents;
    property CmdLineTools: TCmdOptions read FCmdLineTools write FCmdLineTools;
    property ConnectivityClients: TConnectivityOptions read FConnectivityClients
                                                       write FConnectivityClients;
    property Examples: TExamplesOptions read FExamples write FExamples;
  end;

  TpFIBSetup = class(TComponent)
  private
    FIBInstallLoaded: Boolean;
    FRebootToComplete: Boolean;
    FProgress: Integer;
    FMsgFilePath: string;
    FOnStatusChange: TpFIBSetupOnStatus;
    FStatusContext : Pointer;
    FOnError: TpFIBSetupOnError;
    FErrorContext : Pointer;
    FOnWarning: TpFIBSetupOnWarning;
    procedure SetMsgFilePath(const Value: string);
 protected
    function StatusInternal(Status: Integer; const ActionDescription: TEXT):Integer;
    function ErrorInternal(IscCode: MSG_NO; const ActionDescription: TEXT): Integer;
    procedure Call(IscCode: MSG_NO);
    procedure IBInstallError(IscCode: MSG_NO);
    function GetInstallMessage(IscCode : MSG_NO) : string;
  public
    constructor Create(AOwner : TComponent); override;
    property RebootToComplete : Boolean read FRebootToComplete;
    property Progress : Integer read FProgress;
    property StatusContext : Pointer read FStatusContext write FStatusContext;
    property ErrorContext : Pointer read FErrorContext write FErrorContext;
    property MsgFilePath: string read FMsgFilePath write SetMsgFilePath;
  published
    property OnWarning: TpFIBSetupOnWarning read FOnWarning write FOnWarning;
    property OnError: TpFIBSetupOnError read FOnError write FOnError;
    property OnStatusChange: TpFIBSetupOnStatus read FOnStatusChange write FOnStatusChange;
  end;

  TpFIBInstall = class(TpFIBSetup)
  private
    FUnInstallFile: string;
    FSourceDir: string;
    FDestinationDir: string;
    FSuggestedDestination: string;
    FInstallOptions: TInstallOptions;
    procedure GetOptionProperty(InfoType : Integer; Option : TExamplesOption;
                                Buffer : Pointer; BufferLen : Cardinal);
    procedure GetOptionProperty1(InfoType : Integer; Option : TMainOption;
                                Buffer : Pointer; BufferLen : Cardinal);
    procedure GetOptionProperty2(InfoType : Integer; Option : TConnectivityOption;
                                Buffer : Pointer; BufferLen : Cardinal);
    procedure GetOptionProperty3(InfoType : Integer; Option : TCmdOption;
                                Buffer : Pointer; BufferLen : Cardinal);
    procedure InternalSetOptions(pHandle : POPTIONS_HANDLE);
    procedure SetDestination(const Value: string);
    procedure SetSource(const Value: string);
    procedure SetInstallOptions(const Value: TInstallOptions);
    procedure SuggestDestination;
  public
    Constructor Create(AOwner: TComponent); override;
    Destructor Destroy; override;

    procedure InstallCheck;
    procedure InstallExecute;

    function  GetOptionDescription (Option : TExamplesOption): string;
    function  GetOptionDescription1 (Option : TMainOption) : string;
    function  GetOptionDescription2 (Option : TConnectivityOption) : string;
    function  GetOptionDescription3 (Option : TCmdOption) :string; 

    function  GetOptionName (Option : TExamplesOption): string; 
    function  GetOptionName1 (Option : TMainOption) :string;
    function  GetOptionName2 (Option : TConnectivityOption) : string;
    function  GetOptionName3 (Option : TCmdOption) : string;

    function  GetOptionSpaceRequired (Option : TExamplesOption): cardinal;
    function  GetOptionSpaceRequired1 (Option : TMainOption): cardinal;
    function  GetOptionSpaceRequired2 (Option : TConnectivityOption): cardinal;
    function  GetOptionSpaceRequired3 (Option : TCmdOption): cardinal;

    property  UnInstallFile: string read FUnInstallFile;
    property SuggestedDestination: string read FSuggestedDestination;

  published
    property SourceDirectory: string read FSourceDir write SetSource;
    property DestinationDirectory: string read FDestinationDir write SetDestination;
    property InstallOptions: TInstallOptions read FInstallOptions write SetInstallOptions;
  end;

  TpFIBUnInstall = class(TpFIBSetup)
  private
    FUnInstallFile: string;
   public
    procedure UnInstallCheck;
    procedure UnInstallExecute;
    property  UnInstallFile: string read FUnInstallFile write FUnInstallFile;
  end;

implementation
uses FIBConsts;

const
  IBInstallerMessages : array[TIBInstallerError] of string = (
    SSuccess,
    SDelphiException,
    SNoOptionsSet,
    SNoDestinationDirectory,
    SNosourceDirectory,
    SNoUninstallFile,
    SOptionNeedsClient,
    SOptionNeedsServer,
    SInvalidOption,
    SInvalidOnErrorResult,
    SInvalidOnStatusResult
    );
{$DEFINE FP_STDCALL}

procedure IBInstallerError(ECode: TIBInstallerError; const Args: array of const);
begin
  raise EIBInstallerError.Create1(ECode, Format(IBInstallerMessages[ECode], Args));
end;

function ErrorCallback(IscCode: MSG_NO; UserContext: Pointer; const ActionDescription:
                       TEXT): Integer;{$I pFIBMacroComp.inc}
begin
  Result := TpFIBSetup(UserContext).ErrorInternal(IscCode, ActionDescription);
end;

function StatusCallback(Status : Integer; UserContext: Pointer; const ActionDescription:
                       TEXT): Integer; {$I pFIBMacroComp.inc}
begin
  Result := TpFIBSetup(UserContext).StatusInternal(Status, ActionDescription);
end;

{ TpFIBSetup }

function TpFIBSetup.ErrorInternal(IscCode: MSG_NO; const ActionDescription: TEXT):
                                Integer;
var
  ErrorComment : string;
begin
  if(ActionDescription <> nil) and (ActionDescription[0] <> #0) then
  begin
    SetLength(ErrorComment, StrLen(ActionDescription));
    StrCopy(PChar(ErrorComment), ActionDescription);
  end
  else
    ErrorComment := '';

  if(Isccode = isc_install_fp_copy_delayed) or
    (Isccode = isc_install_fp_delete_delayed) then
  begin
    FRebootToComplete := True;
    Result := isc_install_fp_continue;
    exit;
  end;

  if Assigned(FOnError) then
    case FOnError(self, IscCode, GetInstallMessage(IscCode), ErrorComment) of
      erAbort:
        Result := isc_install_fp_abort;
      erContinue:
        Result := isc_install_fp_continue;
      erRetry:
        Result := isc_install_fp_retry;
      else
        Result := isc_install_fp_abort;
    end
  else
    Result := isc_install_fp_abort;
end;

function TpFIBSetup.StatusInternal(Status: Integer; const ActionDescription: TEXT):
 Integer;
var
  StatusComment : string;
begin
  FProgress := Status;
  if(ActionDescription <> nil) and (ActionDescription[0] <> #0) then
  begin
    SetLength(StatusComment, StrLen(ActionDescription));
    StrCopy(PChar(StatusComment), ActionDescription);
  end
  else
   StatusComment := '';

  if Assigned(FOnStatusChange) then
    case  FOnStatusChange(self, StatusComment) of
      srAbort:
       Result := isc_install_fp_abort;
      srContinue:
       Result := isc_install_fp_continue;
      else
       Result := isc_install_fp_continue;
    end
   else
     Result := isc_install_fp_continue;
end;

procedure TpFIBSetup.SetMsgFilePath(const Value: string);
begin
  if FMsgFilePath <> Value then
  begin
    Call(isc_install_load_external_text(PChar(Value)));
    FMsgFilePath := Value;
  end;
end;

procedure TpFIBSetup.Call(IscCode: MSG_NO);
begin
  Set8087CW(Default8087CW);
  if IscCode = isc_install_success then
    Exit;

  if IscCode < isc_install_success then
  begin
    if Assigned(FOnWarning) then
    begin
      if FOnWarning(self, IscCode, GetInstallMessage(IscCode)) = wrAbort then
        IBInstallError(IscCode);
      Exit;
    end
    else
      IBInstallError(IscCode);
  end;
  IBInstallError(IscCode);
end;

procedure TpFIBSetup.IBInstallError(IscCode: MSG_NO);
begin
  raise EIBInstallError.Create(IscCode, GetInstallMessage(IscCode));
end;

function TpFIBSetup.GetInstallMessage(IscCode : MSG_NO) : string;
var
  status     : MSG_NO;
  IscMessage : string;
begin
  SetLength(IscMessage, ISC_INSTALL_MAX_MESSAGE_LEN * 2);
  status := isc_install_get_message(0, IscCode, PChar(IscMessage),
                                    ISC_INSTALL_MAX_MESSAGE_LEN * 2);

  if status <> isc_install_success then
    isc_install_get_message(0, status, PChar(IscMessage),
                            ISC_INSTALL_MAX_MESSAGE_LEN * 2);

  SetLength(IscMessage, StrLen(PChar(IscMessage)));
  result := IscMessage;
end;

constructor TpFIBSetup.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FIBInstallLoaded := False;
  CheckIBInstallLoaded;
  FIBInstallLoaded := True;
  FRebootToComplete := False;
  FProgress := 0;
end;

{ TpFIBInstall }

constructor TpFIBInstall.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIBInstallLoaded := False;
  CheckIBInstallLoaded;
  FIBInstallLoaded := True;
  FInstallOptions := TInstallOptions.Create;
  SuggestDestination;
end;

destructor TpFIBInstall.Destroy;
begin
  if FIBInstallLoaded then
    FInstallOptions.Free;
  inherited;
end;

procedure TpFIBInstall.InstallCheck;
var
  Handle : OPTIONS_HANDLE;
  SrcDir, DestDir : PChar;
begin
  Handle := 0;
  InternalSetOptions(@Handle);

  if FSourceDir = '' then
    SrcDir := nil
  else
    SrcDir := PChar(FSourceDir);

  if FDestinationDir = '' then
    DestDir := nil
  else
    DestDir := PChar(FDestinationDir);

  try
    Call(isc_install_precheck(Handle, SrcDir, DestDir));
  finally
    isc_install_clear_options(@Handle);
  end;
end;

procedure TpFIBInstall.InstallExecute;
var
  Handle : OPTIONS_HANDLE;
begin
  Handle := 0;
  InternalSetOptions(@Handle);

  if Handle = 0 then
    IBInstallerError(ieNoOptionsSet, ['']);

  try
    SetLength(FUninstallFile, ISC_INSTALL_MAX_PATH);
    Call(isc_install_execute(Handle, PChar(FSourceDir), PChar(FDestinationDir),
                            StatusCallback, Pointer(self), ErrorCallback,
                            Pointer(self), PChar(FUninstallFile)));
    SetLength(FUninstallFile, StrLen(PChar(FUninstallFile)));
  finally
    isc_install_clear_options(@Handle);
  end;
end;

procedure TpFIBInstall.InternalSetOptions(pHandle: POPTIONS_HANDLE);
begin
  with FInstallOptions do
  begin
    if FMainComponents <> [] then
    begin
     if moClient in  FMainComponents then
       isc_install_set_option(pHandle, IB_CLIENT);
     if moDevelopment in FMainComponents then
       isc_install_set_option(pHandle, IB_DEV);
     if moServer in FMainComponents then
       isc_install_set_option(pHandle, IB_SERVER);
     if  moDocumentation in FMainComponents then
       isc_install_set_option(pHandle, IB_DOC);
     if moConServer in FMainComponents then
       isc_install_set_option(pHandle, IB_CONNECTIVITY_SERVER);
     if moGuiTools in FMainComponents then
       isc_install_set_option(pHandle, IB_GUI_TOOLS);
    end;

    if FExamples <> [] then
    begin
     if exDB in FExamples  then
       isc_install_set_option(pHandle, IB_EXAMPLE_DB);
     if exAPI in FExamples then
       isc_install_set_option(pHandle, IB_EXAMPLE_API);
    end;

    if FCmdLineTools  <> [] then
    begin
     if cmDBMgmt in FCmdLineTools then
        isc_install_set_option(pHandle, IB_CMD_TOOLS_DB_MGMT);
     if cmDBQuery in FCmdLineTools then
        isc_install_set_option(pHandle, IB_CMD_TOOLS_DB_QUERY);
     if cmUsrMgmt in FCmdLineTools then
        isc_install_set_option(pHandle, IB_CMD_TOOLS_USR_MGMT);
    end;

    if FConnectivityClients <> [] then
    begin
     if cnODBC in FConnectivityClients then
       isc_install_set_option(pHandle, IB_ODBC_CLIENT);
     if cnOLEDB in FConnectivityClients then
       isc_install_set_option(pHandle, IB_OLEDB_CLIENT);
     if  cnJDBC in FConnectivityClients then
        isc_install_set_option(pHandle, IB_JDBC_CLIENT);
    end;
  end;
end;

procedure TpFIBInstall.SetDestination(const Value: string);
var
  IscCode  : MSG_NO;
begin
  if Value <> '' then
  begin
    IscCode := isc_install_precheck(0, nil, PChar(Value));
    if(IscCode > isc_install_success) then
     IBInstallError(IscCode);
  end;
  FDestinationDir := Value;
end;

procedure TpFIBInstall.SetInstallOptions(const Value: TInstallOptions);
begin
  if FInstallOptions <> Value then
    FInstallOptions.Assign(Value);
end;

procedure TpFIBInstall.SetSource(const Value: string);
var
  IscCode  : MSG_NO;
begin
  if Value <> '' then
  begin
    IscCode := isc_install_precheck(0, PChar(Value), nil);
    if(IscCode > isc_install_success) then
      IBInstallError(IscCode);
    end;
  FSourceDir := Value;
end;

procedure TpFIBInstall.SuggestDestination;
begin
  SetLength(FSuggestedDestination, ISC_INSTALL_MAX_PATH);
  Call(isc_install_get_info(isc_install_info_destination, 0, PChar(FSuggestedDestination),
                           ISC_INSTALL_MAX_PATH));
  SetLength(FSuggestedDestination, StrLen(PChar(FSuggestedDestination)));
end;

function TpFIBInstall.GetOptionDescription(Option: TExamplesOption): string;
var
  OptionDesc : string;
begin
  SetLength(OptionDesc, ISC_INSTALL_MAX_MESSAGE_LEN);
  GetOptionProperty(isc_install_info_opdescription, Option, PChar(OptionDesc),
                   ISC_INSTALL_MAX_MESSAGE_LEN);
  SetLength(OptionDesc, StrLen(PChar(OptionDesc)));
  Result := OptionDesc;
end;

function TpFIBInstall.GetOptionDescription3(Option: TCmdOption): string;
var
  OptionDesc : string;
begin
  SetLength(OptionDesc, ISC_INSTALL_MAX_MESSAGE_LEN);
  GetOptionProperty3(isc_install_info_opdescription, Option, PChar(OptionDesc),
                   ISC_INSTALL_MAX_MESSAGE_LEN);
  SetLength(OptionDesc, StrLen(PChar(OptionDesc)));
  Result := OptionDesc;
end;

function TpFIBInstall.GetOptionDescription2(Option: TConnectivityOption): string;
var
  OptionDesc : string;
begin
  SetLength(OptionDesc, ISC_INSTALL_MAX_MESSAGE_LEN);
  GetOptionProperty2(isc_install_info_opdescription, Option, PChar(OptionDesc),
                   ISC_INSTALL_MAX_MESSAGE_LEN);
  SetLength(OptionDesc, StrLen(PChar(OptionDesc)));
  Result := OptionDesc;
end;

function TpFIBInstall.GetOptionDescription1(Option: TMainOption): string;
var
  OptionDesc : string;
begin
  SetLength(OptionDesc, ISC_INSTALL_MAX_MESSAGE_LEN);
  GetOptionProperty1(isc_install_info_opdescription, Option, PChar(OptionDesc),
                   ISC_INSTALL_MAX_MESSAGE_LEN);
  SetLength(OptionDesc, StrLen(PChar(OptionDesc)));
  Result := OptionDesc;
end;

function TpFIBInstall.GetOptionName(Option: TExamplesOption): string;
var
  OptionName : string;
begin
  SetLength(OptionName, ISC_INSTALL_MAX_MESSAGE_LEN);
  GetOptionProperty(isc_install_info_opname, Option, PChar(OptionName),
                   ISC_INSTALL_MAX_MESSAGE_LEN);
  SetLength(OptionName, StrLen(PChar(OptionName)));
  Result := OptionName;
end;

function TpFIBInstall.GetOptionName3(Option: TCmdOption): string;
var
  OptionName : string;
begin
  SetLength(OptionName, ISC_INSTALL_MAX_MESSAGE_LEN);
  GetOptionProperty3(isc_install_info_opname, Option, PChar(OptionName),
                   ISC_INSTALL_MAX_MESSAGE_LEN);
  SetLength(OptionName, StrLen(PChar(OptionName)));
  Result := OptionName;
end;

function TpFIBInstall.GetOptionName2(Option: TConnectivityOption): string;
var
  OptionName : string;
begin
  SetLength(OptionName, ISC_INSTALL_MAX_MESSAGE_LEN);
  GetOptionProperty2(isc_install_info_opname, Option, PChar(OptionName),
                  ISC_INSTALL_MAX_MESSAGE_LEN);
  SetLength(OptionName, StrLen(PChar(OptionName)));
  Result := OptionName;
end;

function TpFIBInstall.GetOptionName1(Option: TMainOption): string;
var
  OptionName : string;
begin
  SetLength(OptionName, ISC_INSTALL_MAX_MESSAGE_LEN);
  GetOptionProperty1(isc_install_info_opname, Option, PChar(OptionName),
                   ISC_INSTALL_MAX_MESSAGE_LEN);
  SetLength(OptionName, StrLen(PChar(OptionName)));
  Result := OptionName;
end;

function TpFIBInstall.GetOptionSpaceRequired(Option: TExamplesOption): cardinal;
var
  OptionSpace : cardinal;
begin
  GetOptionProperty(isc_install_info_opspace, Option, @OptionSpace,
                    Cardinal(SizeOf(OptionSpace)));
  Result := OptionSpace;
end;

function TpFIBInstall.GetOptionSpaceRequired1(Option: TMainOption): cardinal;
var
  OptionSpace : cardinal;
begin
  GetOptionProperty1(isc_install_info_opspace, Option, @OptionSpace,
                    Cardinal(SizeOf(OptionSpace)));
  Result := OptionSpace;
end;

function TpFIBInstall.GetOptionSpaceRequired2(Option: TConnectivityOption): cardinal;
var
  OptionSpace : cardinal;
begin
  GetOptionProperty2(isc_install_info_opspace, Option, @OptionSpace,
                    Cardinal(SizeOf(OptionSpace)));
  Result := OptionSpace;
end;

function TpFIBInstall.GetOptionSpaceRequired3(Option: TCmdOption): cardinal;
var
  OptionSpace : cardinal;
begin
  GetOptionProperty3(isc_install_info_opspace, Option, @OptionSpace,
                   Cardinal(SizeOf(OptionSpace)));
  Result := OptionSpace;
end;

procedure TpFIBInstall.GetOptionProperty1(InfoType: Integer; Option : TMainOption;
                                       Buffer: Pointer; BufferLen : Cardinal);
var
 IscOption : OPT;
begin
  case Option of
    moClient:
     IscOption := IB_CLIENT;
    moDevelopment:
     IscOption := IB_DEV;
    moServer:
     IscOption :=  IB_SERVER;
    moDocumentation:
     IscOption := IB_DOC;
    moGuiTools:
     IscOption := IB_GUI_TOOLS;
    else
     IscOption :=  IB_CONNECTIVITY_SERVER;
  end;
  Call(isc_install_get_info(InfoType, IscOption, Buffer, BufferLen));
end;

procedure TpFIBInstall.GetOptionProperty(InfoType: Integer; Option: TExamplesOption;
                                       Buffer: Pointer; BufferLen : Cardinal);
var
 IscOption : OPT;
begin
  case Option of
     exDB:
       IscOption := IB_EXAMPLE_DB;
     else
       IscOption := IB_EXAMPLE_API;
   end;
   Call(isc_install_get_info(InfoType, IscOption, Buffer, BufferLen));
end;

procedure TpFIBInstall.GetOptionProperty3(InfoType: Integer; Option: TCmdOption;
                                       Buffer: Pointer; BufferLen : Cardinal);
var
 IscOption : OPT;
begin
  case Option of
    cmDBMgmt:
      IscOption := IB_CMD_TOOLS_DB_MGMT;
        cmDBQuery:
      IscOption := IB_CMD_TOOLS_DB_QUERY;
        else
      IscOption := IB_CMD_TOOLS_USR_MGMT;
  end;
  Call(isc_install_get_info(InfoType, IscOption, Buffer, BufferLen));
end;

procedure TpFIBInstall.GetOptionProperty2(InfoType: Integer; Option: TConnectivityOption;
                                       Buffer: Pointer; BufferLen : Cardinal);
var
 IscOption : OPT;
begin
  case Option of
    cnODBC:
     IscOption :=  IB_ODBC_CLIENT;
    cnOLEDB:
     IscOption := IB_OLEDB_CLIENT;
    else
     IscOption := IB_JDBC_CLIENT;
  end;
  Call(isc_install_get_info(InfoType, IscOption, Buffer, BufferLen));
end;

{ TpFIBUnInstall }

procedure TpFIBUnInstall.UnInstallCheck;
begin
  if FUninstallFile = '' then
    IBInstallerError(ieNoUninstallFile, ['']);

  Call(isc_uninstall_precheck(PChar(FUninstallFile)));
end;

procedure TpFIBUnInstall.UnInstallExecute;
begin
  if FUninstallFile = '' then
    IBInstallerError(ieNoUninstallFile, ['']);

  Call(isc_uninstall_execute(PChar(FUninstallFile), StatusCallback, Pointer(self),
                             ErrorCallback, Pointer(self)));
end;

{ EIBInstall }

constructor EIBInstall.Create(IscCode: MSG_NO; IscMessage: string);
begin
   inherited Create(IscMessage);
   FIscError := IscCode;
   FInstallerError := ieSuccess;
end;

constructor EIBInstall.Create1(ECode: TIBInstallerError; EMessage: string);
begin
  inherited Create(EMessage);
  FInstallerError := ECode;
  FIscError := isc_install_success;
end;

end.
