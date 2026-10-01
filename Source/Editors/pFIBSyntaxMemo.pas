{*****************************************************************************}
{                                                                             }
{    TMPSyntaxMemo                                                            }
{                                                                             }
{    http://www.delphikingdom.com/asp/viewitem.asp?catalogid=1148             }
{    Coded by MaxProof                                                        }
{    Updated by SiONYX (sionyx@yandex.ru)                                     }
{                                                                             }
{*****************************************************************************}

unit pFIBSyntaxMemo;

interface

{$I ..\FIBPlus.inc}
{$IFDEF VER140}
{$IFDEF BCB}			// C++Buider 6.0
{$OBJEXPORTALL on}
{$ENDIF}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}
{$IFDEF VER150}
{$DEFINE D7+}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}
// Probably Delphi 2005 defines
{$IFDEF VER170}
{$DEFINE D7+}
{$DEFINE D9+}
{$INLINE OFF}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}
{$IFDEF VER180}
{$DEFINE D7+}
{$DEFINE D9+}
{$DEFINE D10+}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}
{$IFDEF VER200}
{$DEFINE D7+}
{$DEFINE D9+}
{$DEFINE D10+}
{$DEFINE D11+}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$WARNINGS  OFF}
{$ENDIF}
{$IFDEF VER210} // Delphi 2010
{$DEFINE D7+}
{$DEFINE D9+}
{$DEFINE D10+}
{$DEFINE D11+}
{$DEFINE D12+}
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$WARNINGS  OFF}
{$ENDIF}
{$IF CompilerVersion >= 22} // Delphi XE
{$WARN UNSAFE_TYPE OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_CAST OFF}
{$WARN SYMBOL_PLATFORM OFF}
{$WARNINGS OFF}
{$DEFINE D7+}
{$DEFINE D9+}
{$DEFINE D10+}
{$DEFINE D11+}
{$DEFINE D12+}
{$DEFINE D13+}
{$IF CompilerVersion >= 23} // Delphi XE2
{$DEFINE D_XE2}
{$ENDIF}
{$ENDIF}
{$UNDEF UNICODE}

uses
  Windows, Messages, SysUtils, Classes,
{$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.Menus, Vcl.Clipbrd,
{$ELSE}
  Graphics, Controls, Forms, Dialogs, ComCtrls, ExtCtrls, StdCtrls, Menus,
  Clipbrd,
{$ENDIF}
  Contnrs;

const
  tokBlank        = 0;
  tokText         = 1;
  tokString       = 2;
  tokStringEnd    = 3;
  tokHexValue     = 4;
  tokInteger      = 5;
  tokFloat        = 6;
  tokILComment    = 7;
  tokMLCommentBeg = 8;
  tokMLCommentEnd = 9;
  tokELCommentBeg = 10;
  tokELCommentEnd = 11;
  tokEndLine      = 12;
  tokParenBeg     = 13;
  tokParenEnd     = 14;
  tokBrackedBeg   = 15;
  tokBracketEnd   = 16;
  tokOperator     = 17;
  tokPoint        = 18;
  tokComma        = 19;
  tokReference    = 20;
  tokDereference  = 21;
  tokReserved     = 22;

  tokILCompDir    = 23; // Inline Compiler Directive - C-style: #
  tokMLCompDirBeg = 24; // Multyline Compiler Directive - Delphi-style: {$ }
  tokMLCompDirEnd = 25;
  tokChar         = 26;
  tokCharEnd      = 27;

  tokErroneous  = 28;
  tokErroneous2 = 29;

  tokReservedSiO = 30;

  tokUser = 255;

  clSkyBlue = TColor($F0CAA6);

  tokWords = [tokText, tokStringEnd, tokString, tokHexValue, tokInteger,
    tokFloat, tokChar, tokUser];

var
  tokUserWords: set of Byte;

type
  TMPCustomSyntaxMemo = class;
  TMPSynMemoRange = class;
  TMPSynMemoSection = class;
  TMPSynMemoStrings = class;
  TMPSyntaxParser = class;
  TMPSyntaxAttributes = class;
  TMPBreakPointCollection = class;

  TMPSyntaxCompletionProposalForm = class;

  EMPSyntaxMemo = class(Exception);

  // Token
  TToken = tokBlank .. tokUser;
  PToken = ^TToken;
  TTokenSet = set of TToken;
  TCharSet = set of AnsiChar;

  // Parser options
  TParseOption = (
    poHasELComment,
    poHasMLComment,
    poHasILComment,
    poHasHexPrefix,
    poFloatValid,
    poHasReference,
    poHasDereference,
    poBLSeparated,
    poHasILCompDir,
    poHasMLCompDir,
    poHasChar
  );
  TParseOptions = set of TParseOption;

  // User hook for word token detection
  TUserTokenEvent = procedure(Sender: TObject; Word: string; Pos, Line: Integer; var Token: TToken) of object;

  // Type - array of character widths of the current font
  TCharWidths = array [Boolean] of array [AnsiChar] of Byte;
  // TCharWidths         = array [Boolean] of array [Char] of Byte;

  // Visual highlighting attributes of a token
  TTokenStyle = record
    tsForeground: TColor; // font color
    tsBackground: TColor; // background color
    tsStyle: TFontStyles; // font style
  end;

  // Class managing highlighting rules and visual attributes of tokens
  TMPSyntaxAttributes = class
  private
    fRichMemo: TMPCustomSyntaxMemo;
    fLitString: Char;
    fLitChar: Char;
    fLitILCompDir: string;
    fLitMLCompDirB: string;
    fLitMLCompDirE: string;
    fLitILComment: string;
    fLitMLCommentB: string;
    fLitMLCommentE: string;
    fLitELCommentB: string;
    fLitELCommentE: string;
    fLitHexPrefix: string;
    fLitDecimalPoint: Char;
    fLitReference: Char;
    fLitDereference: Char;
    fParseOptions: TParseOptions;
    fTokenStyles: array [TToken] of TTokenStyle;
    fOnUserToken: TUserTokenEvent;
    function GetColor(const Token: TToken; const Index: Integer): TColor;
    function GetStyle(const Token: TToken): TFontStyles;
    procedure SetColor(const Token: TToken; const Index: Integer; const Value: TColor);
    procedure SetStyle(const Token: TToken; const Value: TFontStyles);
  public
    constructor Create(Owner: TMPCustomSyntaxMemo);
    procedure Assign(Friend: TMPSyntaxAttributes);
    function Equals(const T1, T2: TToken): Boolean;
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
    procedure CopyAttrs(const SrcToken: TToken; DstTokArray: array of TToken);
    property LiteralString: Char read fLitString write fLitString;
    property LiteralChar: Char read fLitChar write fLitChar;
    property LiteralILComment: string read fLitILComment write fLitILComment;
    property LiteralILCompilerDirective: string read fLitILCompDir write fLitILCompDir;
    property LiteralMLCompDirBeg: string read fLitMLCompDirB write fLitMLCompDirB;
    property LiteralMLCompDirEnd: string read fLitMLCompDirE write fLitMLCompDirE;
    property LiteralMLCommentBeg: string read fLitMLCommentB write fLitMLCommentB;
    property LiteralMLCommentEnd: string read fLitMLCommentE write fLitMLCommentE;
    property LiteralELCommentBeg: string read fLitELCommentB write fLitELCommentB;
    property LiteralELCommentEnd: string read fLitELCommentE write fLitELCommentE;
    property LiteralHexPrefix: string read fLitHexPrefix write fLitHexPrefix;
    property LiteralDecimalPoint: Char read fLitDecimalPoint write fLitDecimalPoint;
    property LiteralReference: Char read fLitReference write fLitReference;
    property LiteralDereference: Char read fLitDereference write fLitDereference;
    property ParseOptions: TParseOptions read fParseOptions write fParseOptions;
    property OnUserToken: TUserTokenEvent read fOnUserToken write fOnUserToken;
    property FontColor[const Token: TToken]: TColor index 0 read GetColor write SetColor;
    property BackColor[const Token: TToken]: TColor index 1 read GetColor write SetColor;
    property FontStyle[const Token: TToken]: TFontStyles read GetStyle write SetStyle;
  end;

  // Word - token
  // Word parameters
  TMPSyntaxTokenStyle = (stsInSelection, // word inside the selection
    stsPressed // word under the pressed mouse pointer - reserved for future use
  );
  TMPSyntaxTokenStyles = set of TMPSyntaxTokenStyle;

  TMPSyntaxToken = class
  public
    stStart: Word; // Word start, in chars
    stLength: Word; // Word length, in chars
    stToken: TToken; // Word type (token)
    stStyle: TMPSyntaxTokenStyles; // Word is selected
  end;

  // Line syntax parser /EVERY text line has its own copy/
  TMPSyntaxParser = class(TObjectList)
  private
    fSection: TMPSynMemoSection;
    fVisibleIndex: Integer;
    fNeedReparse: Boolean;
    function GetToken(const TokIndex: Integer): TMPSyntaxToken;
    procedure SetToken(const TokIndex: Integer; const Value: TMPSyntaxToken);
  protected
    function ParseLine(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken; virtual;
    function ParseLineEx(const Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken; virtual;
  public
    constructor Create(const AsCloneOf: TMPSyntaxParser = nil);
    procedure Assign(const Friend: TMPSyntaxParser);
    procedure Clear; override;
    procedure AddToken(const Beg, Len: Integer; Token: TToken);
    procedure GroupTokens;
    procedure SplitTokens(const sx, ex: Integer);
    function AsString: string;
    function LastToken: TToken;
    function FirstToken: TToken;
    function Parse(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
    property Tokens[const TokIndex: Integer]: TMPSyntaxToken read GetToken write SetToken; default;
    property NeedReparse: Boolean read fNeedReparse write fNeedReparse;
    property Section: TMPSynMemoSection read fSection write fSection;
    property VisibleIndex: Integer read fVisibleIndex write fVisibleIndex;
  end;

  { Max Proof Syntax Memo Strings Class }
  // Class encapsulating text content management and its syntax analysis
  // via the helper class TMPSyntaxParser, an instance of which is owned by
  // EVERY text line. All text changes come down to three elementary override
  // operator procedures: Put, Insert and Delete.
  TStringsStateItem = (ssTextChanged, // There are changed lines
    ssSectionsChanged, // There are changed sections (New, Explode)
    ssNeedReIndex, // There are changed sections (Expand, Collapse)
    ssNeedReparseAll, // Full reparsing of lines is required
    ssUndoProcess // Undo is currently in progress
  );
  TStringsState = set of TStringsStateItem;

  TMPSynMemoStrings = class(TStringList)
  private
    fRichMemo: TMPCustomSyntaxMemo; // Owner
    fFileName: string; // File name
    fVirtualFileName: Boolean; // File name is generated (not real)
    fState: TStringsState; // Set of states
    fModified: Boolean; // Text is modified
    fDirectAccess: Boolean; // Direct access to the text
    function GetParser(const Row: Integer): TMPSyntaxParser;
    procedure SetModified(const Value: Boolean);
    procedure SetFileName(const Value: string);
  protected
    procedure Changed; override;
    procedure Put(Index: Integer; const s: string); override;
    procedure SetUpdateState(Updating: Boolean); override;
    function ParseLine(const Index: Integer; const TestNextLine: Boolean): Boolean; virtual;
    property State: TStringsState read fState write fState;
  public
    constructor Create(const Owner: TMPCustomSyntaxMemo);
    procedure Clear; override;
    function PositionToRC(Value: Integer): TPoint;
    function RCToPosition(Col, Row: Integer): Integer;
    procedure Parse(const EntireText: Boolean; const NeedRepaint: Boolean = False);
    procedure Delete(Index: Integer); override;
    // procedure       InsertObject(Index: Integer; const s: string; AObject: TObject); override;
    procedure Insert(Index: Integer; const s: string); override;
    function Add(const s: string): Integer; override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;
    procedure LoadFromFile(const NewFileName: string); override;
    procedure SaveToFile(const NewFileName: string); override;
    procedure New; virtual;
    function IsValidLineIndex(const Row: Integer): Boolean;
    property FileName: string read fFileName write SetFileName;
    property Parser[const Row: Integer]: TMPSyntaxParser read GetParser;
    property VirtualFileName: Boolean read fVirtualFileName;
    property Modified: Boolean read fModified write SetModified;
    property DirectAccess: Boolean read fDirectAccess write fDirectAccess;
    property UpdateCount;
  end;

  // "Text section" class
  // Has begin and end markers (line numbers); a single line
  // may "hold" only one marker, no matter of which section
  TMPSynMemoSection = class(TObjectList)
  private
    fParent: TMPSynMemoSection; // Parent section
    fRowBeg: Integer; // Start of the stored line range
    fRowEnd: Integer; // End of the stored line range
    fLevel: Integer; // Section nesting level
    fCollapsed: Boolean; // Section is collapsed
    function GetSections(const Idx: Integer): TMPSynMemoSection;
    procedure SetLevel(const Value: Integer);
  public
    constructor Create;
    property RowBeg: Integer read fRowBeg write fRowBeg;
    property RowEnd: Integer read fRowEnd write fRowEnd;
    property Sections[const Idx: Integer]: TMPSynMemoSection read GetSections; default;
    property Level: Integer read fLevel write SetLevel;
    property Parent: TMPSynMemoSection read fParent write fParent;
    property Collapsed: Boolean read fCollapsed write fCollapsed;
  end;

  TMPSMSectionClone = class(TMPSynMemoSection)
  private
    fRefCount: Integer;
  protected
    procedure AddRef;
    procedure Release;
    procedure Assign(original: TMPSMSectionClone);
  public
    property RefCount: Integer read fRefCount;
  end;

  // Section Manager Class
  TSectionMark = (smNone, smExpanded, smCollapsed, smEnd);

  // Section manager class.
  // Performs high-level section operations (collapse, expand, create, explode, etc.)
  // Does not provide undo.
  TMPSynMemoSections = class(TObject)
  private
    fRichMemo: TMPCustomSyntaxMemo; // Owner
    fRoot: TMPSMSectionClone; // Root section
    fIndexes: TList; // Text indexing for fast access to screen indexes
    fMaxLevel: Integer; // Maximum section nesting level
    fMaxExpandLevel: Integer; // Maximum expanded section nesting level
    fErrorLine: Integer; // Index of the text line violating section management
    fErrorString: string; // Section management error
    procedure ReIndex;
    procedure MakeUnique;
    procedure SetRoot(const Value: TMPSMSectionClone);
    function GetSection(const Row: Integer): TMPSynMemoSection;
    procedure SetSection(const Row: Integer; Value: TMPSynMemoSection);
  protected
    procedure Scan; virtual;
    procedure FillOutput(const Sl: TStringList); virtual;
    procedure DeleteRow(const Row: Integer); virtual;
    procedure InsertRow(const Row: Integer); virtual;
  public
    class function DetectSectionMark(const s: string): TSectionMark;
    constructor Create(Owner: TMPCustomSyntaxMemo);
    destructor Destroy; override;
    function New(const Row1, Row2: Integer; const IsCollapsed: Boolean = False): TMPSynMemoSection;
    procedure Explode(const Row: Integer; const Recursive: Boolean);
    procedure Collapse(const Row: Integer; const Recursive, SafeSelf: Boolean);
    procedure Expand(const Row: Integer; const Recursive, ParentRecursive: Boolean);
    function SectionBorder(const Row: Integer): TSectionMark;
    function AsText: string;
    function Next(Sec: TMPSynMemoSection): TMPSynMemoSection;
    function Prev(Sec: TMPSynMemoSection): TMPSynMemoSection;
    function Visible(const Sec: TMPSynMemoSection): Boolean;
    property Section[const Row: Integer]: TMPSynMemoSection read GetSection write SetSection;
    property MaxLevel: Integer read fMaxLevel;
    property ErrorLine: Integer read fErrorLine;
    property ErrorString: string read fErrorString;
    property EntireSection: TMPSMSectionClone read fRoot write SetRoot;
    property Indexes: TList read fIndexes;
  end;

  // Operation kinds for UNDO grouping
  TUndoKind = (ukNone,
  // Not grouped with anything (not even itself) - not for normal use
    ukLetterTyped, // Char typed from the keyboard
    ukLetterDeleted, // Char deleted from the keyboard (Delete BackSpace)
    ukRangeInserted, // Text fragment inserted (Paste)
    ukRangeDeleted, // Text fragment deleted (Delete or Cut)
    ukCursorMoved, // Cursor moved to another position
    ukBlockCreated, // New block created
    ukBlockExploded // Block removed
  );

  // Range Class
  TMPSynMemoUndoItem = class
  public
    uiCaretPos: TPoint;
    uiSelStart: TPoint;
    uiSelEnd: TPoint;
    uiSealing: Boolean;
    uiText: string;
    uiSections: TMPSMSectionClone;
    uiKind: TUndoKind;
    destructor Destroy; override;
  end;

  // TMPSynMemoRange
  // This class is a layer between the low-level worker classes
  // T..Strings, T..Sections and user commands. Main tasks -
  // - translating actions on the caret position (PosY, PosX) into
  // actions on objects (Strings, Sections), and providing
  // the ability to undo user actions (undo stack support)

  TPosChangeProc = procedure(Pos: TPoint) of object;

  TMPSynMemoRange = class(TObject)
  private
    fRichMemo: TMPCustomSyntaxMemo; // Owner
    fStart: TPoint; // Start of the selected area
    fEnd: TPoint; // End of the selected area
    fPos: TPoint; // Current cursor coordinates relative to the text [Row,Col]
    fSealing: Boolean; // Collapsed mode (sticking, empty selection)
    fMaxUndoDepth: Integer; // Maximum undo stack size
    fUndoStack: TObjectList; // Undo stack
    fOnSetPosProc: TPosChangeProc;
    function GetLength: Integer;
    function GetPosition: Integer;
    function GetPosInText: Integer;
    function GetText: string;
    function GetMarkedText: string;
    procedure CutFinalSpaces(const Row: Integer);
    procedure SetLength(const Value: Integer);
    procedure SetMaxUndoDepth(const Value: Integer);
    procedure SetPosition(const Value: Integer);
    procedure SetPos(const NewPos: TPoint);
    procedure SetRange(const Index, Value: Integer);
    procedure SetText(const Value: string);
    procedure SetTextEx(const Value: string; ActionKind: TUndoKind);
    procedure SetMarkedText(Value: string);
  protected
    function AddUndo(const UndoText: string = ''): TMPSynMemoUndoItem;
    property StartX: Integer read fStart.X write fStart.X;
    property StartY: Integer read fStart.Y write fStart.Y;
    property EndX: Integer read fEnd.X write fEnd.X;
    property EndY: Integer read fEnd.Y write fEnd.Y;
  public
    constructor Create(Owner: TMPCustomSyntaxMemo);
    destructor Destroy; override;
    procedure Collapse;
    procedure Enlarge(const Value: Integer; const EnlargeLine: Boolean = False; const VisiblesOnly: Boolean = False);
    procedure Delete;
    { Section operations }
    procedure CreateSection;
    procedure ExplodeSection(const Recursive: Boolean);
    procedure ExpandSection(const Recursive: Boolean);
    procedure CollapseSection(const Recursive: Boolean);
    procedure GotoSection(const GoForward: Boolean);
    { Clipboard support }
    procedure CopyToClipboard;
    procedure CutToClipBoard;
    procedure PasteFromClipboard;
    { Undo stack }
    procedure DoUndo;
    function GetLastUndoItem: TMPSynMemoUndoItem;
    procedure ClearUndo;
    procedure SelectAll;
    procedure SelectFromStart;
    procedure SelectToEnd;
    function IsEmpty: Boolean;
    function CanUndo: Boolean;
    procedure MakeIndent;
    procedure MakeUnIndent;
    procedure MakeComment(LitILComment: string);
    property UndoStack: TObjectList read fUndoStack;
    property PosX: Integer index 0 read fPos.X write SetRange;
    property PosY: Integer index 1 read fPos.Y write SetRange;
    property Pos: TPoint read fPos write SetPos;
    property MaxUndoDepth: Integer read fMaxUndoDepth write SetMaxUndoDepth default 100;
    property Position: Integer read GetPosition write SetPosition;
    property PosInText: Integer read GetPosInText;
    property SelLength: Integer read GetLength write SetLength;
    property Text: string read GetText write SetText;
    property MarkedText: string read GetMarkedText write SetMarkedText;
    property LastUndoItem: TMPSynMemoUndoItem read GetLastUndoItem;
  end;

  TWordInfoEvent = procedure(Sender: TMPCustomSyntaxMemo; const X, Y, WordIndex, Row: Integer; Showing: Boolean) of object;
  // TDrawWordEvent      = procedure (Sender: TMPCustomSyntaxMemo; ACanvas: TCanvas; Rect: TRect; Row, Index: Integer) of object;
  TRowIndexConvertionDirection = (cdNeedReal, cdNeedScreen);
  // Editor options
  TMPSynMemoOption = (smoShowFileNameInTabSheet, // show file name on the tab
    smoShowFileNameInFormCaption, // show file name in the form
    smoReadOnly, // forbid text changes (except sections)
    smoOverwrite, // overwrite mode
    smoSkipSectionsOnCopy, // do not copy section info to the clipboard
    smoSkipSectionsOnPaste,
  // do not restore sections when pasting text from the clipboard
    smoAutoGutterWidth, // gutter width depends on EXPANDED sections
    smoWriteMarkersOnSave, // embed section markers when saving text
    smoVSNET_SectionsStyle, // section marker style as in Visual Studio NET
    smoBreakPointsNeedPosibility,
  // mode requiring BreakPoints of type bpPosible
    smoShowCursorPos, // Shows the cursor position window
    smoShowPageScroll, // Shows an extra scroll for paging
    smoPanning, // Enables/disables panning in general
    smoHorPanning, // Additionally enables/disables horizontal panning
    smoVerPanningReverse, // Reverse vertical panning mode
    smoHighlightLine,
  // Enables painting comments and compiler directives to the end of line.
    smoSolidSpecialLine,
  // Enables "filled" mode for BreakPoints and the debug line.
    smoGroupUndo, // Enables grouping of similar Undo steps
    smoTabulatedReturn, // Enables auto indentation on Enter
    smoShowLineNumberToGutter // Show line numbers in the gutter

  );
  TMPSynMemoOptions = set of TMPSynMemoOption;
  TLogEvent = procedure(Sender: TObject; LogStr: string) of object;
  TChangedItem = (ciText, ciSelection, ciSections, ciUndoStack, ciOptions);
  TChangedItems = set of TChangedItem;
  TMPChangeEvent = procedure(Sender: TObject; ChangedItems: TChangedItems) of object;

  // Bookmark manager
  TBookmarkIndex = 0 .. 9;

  TMPBookmarkManager = class
  private
    fRichMemo: TMPCustomSyntaxMemo;
    fBookMarks: array [TBookmarkIndex] of Integer;
    fImages: TBitmap;
    function GetBookMarks(const Index: TBookmarkIndex): Integer;
    procedure SetBookMarks(const Index: TBookmarkIndex; const Row: Integer);
  public
    constructor Create(Owner: TMPCustomSyntaxMemo);
    destructor Destroy; override;
    function Find(const Row: Integer; var Index: TBookmarkIndex): Boolean;
    procedure Clear;
    procedure PaintAt(const ACanvas: TCanvas; const X, Y: Integer; const Index: TBookmarkIndex);
    property BookMarks[const Index: TBookmarkIndex]: Integer read GetBookMarks write SetBookMarks; default;
  end;

  // Classes for managing BreakPoints
  // TBPKind = (bkPosible=0,bkEnabled=1,bkDisabled=2);
  TBPKind = (bkPosible, bkEnabled, bkDisabled);
  TBPMode = (bmFreeMode, bmNeedPosibility);
  // TBPMode = (bmFreeMode=0,bmNeedPosibility=1);
  TBPAction = (bpaSet, bpaDelete);
  TOnBeforeBreakPointChangedNotify = procedure(Sender: TObject;
    const Row: Integer; const Action: TBPAction; var CanChange: Boolean)
  of object;

  TBreakPoint = class(TObject)
  private
    Condition: string;
    PassCount: Cardinal;
    Group: string;
    Comment: string;
    fKind: TBPKind;
    fCollection: TMPBreakPointCollection;
  private
    procedure fSefKind(kind: TBPKind);
  public
    constructor Create(Owner: TMPBreakPointCollection);
    destructor Destroy; override;
    property kind: TBPKind read fKind write fSefKind;
  end;

  TMPBreakPointCollection = class(TObject)
  private
    fRichMemo: TMPCustomSyntaxMemo; // Owner
    fBPList: TStringList;
    fImages: TBitmap;
    fImagesMask: TBitmap;
    fMode: TBPMode;
    fPopUpMenu: TPopupMenu;
    fOnBeforeBreakPointChangedNotify: TOnBeforeBreakPointChangedNotify;
    fRowOfCurrentBP: Integer;
    procedure RefreshBP(Sender: TBreakPoint);
    property Mode: TBPMode read fMode write fMode default bmFreeMode;
    procedure PaintAt(const ACanvas: TCanvas; const X, Y: Integer; const kind: TBPKind);
    function Find(const Row: Integer; var kind: TBPKind): Boolean;
    procedure Add(const Row: Integer; const kind: TBPKind = bkEnabled;
      Condition: string = ''; PassCount: Cardinal = 0; Group: string = '';
      Comment: string = '');
    function Delete(const Row: Integer): Boolean;
  protected
    function fGetIsBreakPoint(const LineIndex: Integer): Boolean;
    procedure fSetIsBreakPoint(const LineIndex: Integer; bp: Boolean);
    function fGetIsPosible(const LineIndex: Integer): Boolean;
    procedure fSetIsPosible(const LineIndex: Integer; bp: Boolean);
    function fGetBreakPoint(const LineIndex: Integer): TBreakPoint;
    procedure fSetBreakPoint(const LineIndex: Integer; bp: TBreakPoint);
  public
    constructor Create(Owner: TMPCustomSyntaxMemo);
    destructor Destroy; override;
    property IsBreakPoint[const LineIndex: Integer]: Boolean read fGetIsBreakPoint write fSetIsBreakPoint;
    property IsPosible[const LineIndex: Integer]: Boolean read fGetIsPosible write fSetIsPosible;
    property BreakPoint[const LineIndex: Integer]: TBreakPoint read fGetBreakPoint; // write fSetBreakPoint;
    property OnBeforeBreakPointChangedNotify: TOnBeforeBreakPointChangedNotify
    read fOnBeforeBreakPointChangedNotify
    write fOnBeforeBreakPointChangedNotify default nil;
    property PopupMenu: TPopupMenu read fPopUpMenu write fPopUpMenu default nil;
    property RowOfCurrentBP: Integer read fRowOfCurrentBP write fRowOfCurrentBP;
  end;

  TMPProposalItems = array [0 .. 1] of TStrings;
  TBeforeProposalCall = procedure(const ProposalName: string) of object;

  TMPCustomSyntaxMemo = class(TCustomControl)
  private
    fLines: TMPSynMemoStrings;
    fRange: TMPSynMemoRange;
    fSections: TMPSynMemoSections;
    fOptions: TMPSynMemoOptions;
    fBuffer: TBitmap;
    fCharHeight: Integer;
    fCharWidths: TCharWidths;
    fParseAttributes: TMPSyntaxAttributes;
    fBookMarks: TMPBookmarkManager;
    fBreakPoints: TMPBreakPointCollection;
    fOnContextPopup: TContextPopupEvent;
    fOnBreakPointPopup: TContextPopupEvent;
    fPopUpMenu: TPopupMenu;
    fOffsets: TPoint;
    fDown: Boolean;
    fPanning: Boolean;
    fHinting: Boolean;
    fPanStartPoint: TPoint;
    fInsertMode: Boolean;
    fVScroll: TScrollBar;
    fHScroll: TScrollBar;
    fNavButton: TPanel;
    fPageUpDown: TScrollBar;
    fPosInfo: TEdit;
    fSelColor: TColor;
    fDefBackColor: TColor;
    fDefForeColor: TColor;
    fBPEnabledBackColor: TColor;
    fBPEnabledForeColor: TColor;
    fBPDisabledBackColor: TColor;
    fBPDisabledForeColor: TColor;
    fSelectedWordColor: TColor;
    fDebugBackColor: TColor;
    fDebugForeColor: TColor;
    fSelWord: TPoint;
    fCaretVisible: Boolean;
    fScreenLines: array of Boolean;
    fGutterWidth: Integer;
    fSectionIndent: Integer;
    fChangesSummator: TChangedItems;
{$IFDEF SYNDEBUG}
    fLogDisabled: Boolean;
{$ENDIF}
    fOnChange: TMPChangeEvent;
    fOnWordInfo: TWordInfoEvent;
    // fOnDrawWord     : TDrawWordEvent;
    fOnLog: TLogEvent;
    fStepDebugLine: Integer;
    fLettersCalculated: Boolean;
    FCurParser: TMPSyntaxParser;
    fInProposalCall: Boolean;
    FProposalForm: TMPSyntaxCompletionProposalForm;
    FTimer: TTimer;
    FBeforeProposalCall: TBeforeProposalCall;
    function GetCurProposalName: string;
    procedure DoOnTimer(Sender: TObject);
    { Gets }
    function GetUserTokenEvent: TUserTokenEvent;
    function GetOnBeforeBreakPointChangedNotify: TOnBeforeBreakPointChangedNotify;
    function GetBreakPointsPopupMenu: TPopupMenu;
    { Sets }
    procedure OnChangePos(Pos: TPoint);
    procedure SetDefColor(const Index: Integer; const Value: TColor);
    procedure SetGutterWidth(const Value: Integer);
    procedure SetOffset(const Index, Value: Integer);
    procedure SetOffsets(NewOffsets: TPoint);
    procedure SetOptions(const Value: TMPSynMemoOptions);
    procedure SetSectionIndent(const Value: Integer);
    procedure SetSelColor(const Value: TColor);
    procedure SetSelectedWord(const Value: TPoint);
    procedure SetUserTokenEvent(const Value: TUserTokenEvent);
    procedure SetOnBeforeBreakPointChangedNotify(OnBeforeBreakPointChangedNotify: TOnBeforeBreakPointChangedNotify);
    procedure SetBreakPointsPopupMenu(pum: TPopupMenu);
    procedure SetStepDebugLine(Row: Integer);
    { Others }
    procedure CreateDestroyPageUpDown;
    procedure CreateDestroyCursorPos;
    procedure Reset; virtual;
    procedure CalcScreenParams;
    procedure CalcFontParams;
    procedure ScrollEnter(Sender: TObject);
    procedure ScrollClick(Sender: TObject);
    procedure UpdateScrollBars;
    procedure PageUpDownOnClick(Sender: TObject);
    function ClientLines: Integer;
    procedure PaintGutter(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
    procedure PaintSectionMarks(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
    procedure PaintDots(const ACanvas: TCanvas);
    procedure PaintTokens(const ACanvas: TCanvas; s: string; Sp: TMPSyntaxParser; Row, TextIndent, SelStart, SelEnd: Integer);
    // procedure       PaintLine(const ScreenRow, Row: Integer);
    procedure PaintLineEx3(const ScreenRow, Row: Integer);
    function RowIndexConvert(const Index: Integer; const Direction: TRowIndexConvertionDirection): Integer;
    function FindVisibleRow(const Row, Delta: Integer; const EnsureInRange: Boolean): Integer;
    function RangeRowToScreenRow(const Row: Integer): Integer;
    { Repaint manager }
    procedure ReDraw;
    procedure NeedRedraw(const Row: Integer);
    procedure NeedReDrawLE(const Row: Integer);
    procedure NeedRedrawAll;
    { Coordinate conversion }
    function CharPosToPixOffset(const Col, Row: Integer): Integer; overload;
    function CharPosToPixOffset(const Col: Integer; s: string; Sp: TMPSyntaxParser): Integer; overload;
    function PixOffsetToCharPos(const Pix, Row: Integer; const WordIndex: PInteger = nil): Integer;
    procedure WndOffsetToPixOffset(OfsPoint: TPoint; var CharPix, Row: Integer; const TextRow: Boolean);
    function PixOffsetToWndOffsetEx(const CharPix, ScreenRow: Integer): TPoint;
    function GetSectionButtonRect(const ScreenRow, ALevel: Integer): TRect;
    function IsLineVisible(const Row: Integer; const PScreenRow: PInteger = nil): Boolean;
    function GetWndRect(const ScreenRow, Index: Integer): TRect;
{$IFDEF SYNDEBUG}
    procedure Log(const LogString: string);
    procedure LogFmt(const LogFormat: string; LogArgs: array of const);
{$ENDIF}
  protected
    function CanResize(var NewWidth, NewHeight: Integer): Boolean; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMSize(var Message: TMessage); message WM_SIZE;
    procedure WMKillFocus(var Msg: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMLButtonDblClk(var Message: TWMMouse); message WM_LBUTTONDBLCLK;
    procedure WMSetFocus(var Msg: TWMSetFocus); message WM_SETFOCUS;
    procedure WMMouseWheel(var Message: TMessage); message WM_MouseWheel;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure FontChange(Sender: TObject);
    procedure Paint; override;
    procedure HideCaret;
    procedure ShowCaret;
    procedure Change(const ChangedItems: TChangedItems); virtual;
    procedure ProposalCall;
    procedure CloseProposal;
    // Coordinates of special screen line elements
    property EntireRowRect[const ScreenRow: Integer]: TRect index 0 read GetWndRect;
    property TextRowRect[const ScreenRow: Integer]: TRect index 1 read GetWndRect;
    property EntireGutterRect[const ScreenRow: Integer]: TRect index 2 read GetWndRect;
    property SymbolsGutterRect[const ScreenRow: Integer]: TRect index 3 read GetWndRect;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ScreenPosToTextPos(const ScrX, ScrY: Integer; var DestX, DestY: Integer); // for drag and drop
    function TextPosToScreen(const X, Y: Integer): TPoint; // for drag and drop
    function CharPosToWordIndex(const Col, Row: Integer): Integer;
    function GetWordAtPos(const X, Y: Integer; var WordIndex, Row: Integer): Boolean;
    function GetCurrentWord(PartOnly: Boolean = False): string;
    procedure ReplaceCurrentWord(DestStr: string);
    function FindNextWord(var wx, wy: Integer): Boolean;
    function FindPrevWord(var wx, wy: Integer): Boolean;
    function WordByPos(const WordPos: TPoint): string;
    function GetPosInText: Integer;
    procedure ShowWord(const Row, WordIndex: Integer);
    procedure MakeVisible(const Col, Row: Integer; const Length: Integer = 1);
    procedure Navigate(const Col, Row: Integer);
    procedure SetProposalItems(PI: TMPProposalItems);
    procedure SaveProposals(const aName: string);
    procedure ApplyProposal(const aName: string);
    procedure AddToCurrentProposal(ts, ts1: TStrings);
    procedure AddProposal(const aName: string);
    procedure ClearProposal;
    { Properties }
    property BookMarks: TMPBookmarkManager read fBookMarks;
    property BreakPoints: TMPBreakPointCollection read fBreakPoints write fBreakPoints;
    property DefBackColor: TColor index 0 read fDefBackColor write SetDefColor default clWindow;
    property DefForeColor: TColor index 1 read fDefForeColor write SetDefColor default clBlack;
    property BPEnabledBackColor: TColor index 2 read fBPEnabledBackColor write SetDefColor default clRed;
    property BPEnabledForeColor: TColor index 3 read fBPEnabledForeColor write SetDefColor default clWhite;
    property BPDisabledBackColor: TColor index 4 read fBPDisabledBackColor write SetDefColor default clMaroon;
    property BPDisabledForeColor: TColor index 5 read fBPDisabledForeColor write SetDefColor default clWhite;
    property DebugLineBackColor: TColor index 6 read fDebugBackColor write SetDefColor default clNavy;
    property DebugLineForeColor: TColor index 7 read fDebugForeColor write SetDefColor default clWhite;
    property SelectedWordColor: TColor index 8 read fSelectedWordColor write SetDefColor default $000080FF;

    property GutterWidth: Integer read fGutterWidth write SetGutterWidth default 32;
    property Lines: TMPSynMemoStrings read fLines;
    property OffsetXPix: Integer index 0 read fOffsets.X write SetOffset;
    property OffsetY: Integer index 1 read fOffsets.Y write SetOffset;
    property Offsets: TPoint read fOffsets write SetOffsets;
    property Range: TMPSynMemoRange read fRange;
    property SectionIndent: Integer read fSectionIndent write SetSectionIndent default 16;
    property Sections: TMPSynMemoSections read fSections;
    property SelColor: TColor read fSelColor write SetSelColor default clSkyBlue;
    property SelectedWord: TPoint read fSelWord write SetSelectedWord;
    property SyntaxAttributes: TMPSyntaxAttributes read fParseAttributes;
    property Options: TMPSynMemoOptions read fOptions write SetOptions
    default [smoAutoGutterWidth, smoShowCursorPos, smoShowPageScroll,
      smoPanning];
    property OnChange: TMPChangeEvent read fOnChange write fOnChange;
    // property        OnDrawWord: TDrawWordEvent read fOnDrawWord write fOnDrawWord;
    property OnWordInfo: TWordInfoEvent read fOnWordInfo write fOnWordInfo;
    property OnParseWord: TUserTokenEvent read GetUserTokenEvent write SetUserTokenEvent;
    property OnLog: TLogEvent read fOnLog write fOnLog;
    property OnBeforeBreakPointChanged: TOnBeforeBreakPointChangedNotify
    read GetOnBeforeBreakPointChangedNotify
    write SetOnBeforeBreakPointChangedNotify;
    property BreakPointsPopupMenu: TPopupMenu read GetBreakPointsPopupMenu write SetBreakPointsPopupMenu default nil;
    property PopupMenu: TPopupMenu read fPopUpMenu write fPopUpMenu default nil;
    property Color default clWindow;
    property OnContextPopup: TContextPopupEvent read fOnContextPopup write fOnContextPopup default nil;
    property OnBreakPointPopup: TContextPopupEvent read fOnBreakPointPopup write fOnBreakPointPopup default nil;
    property StepDebugLine: Integer read fStepDebugLine write SetStepDebugLine default - 1;
    property BeforeProposalCall: TBeforeProposalCall read FBeforeProposalCall write FBeforeProposalCall;
    property CurProposalName: string read GetCurProposalName;
    property Hinting: Boolean read fHinting;
  end;

  TMPSyntaxMemo = class(TMPCustomSyntaxMemo)
  published
    property Anchors;
    property Align;
    property Color;
    property DefBackColor;
    property DefForeColor;
    property BPEnabledBackColor;
    property BPEnabledForeColor;
    property BPDisabledBackColor;
    property BPDisabledForeColor;
    property DebugLineBackColor;
    property DebugLineForeColor;
    property SelectedWordColor;

    property GutterWidth default 32;
    property Font;
    property Options;
    property SelColor default clHighlight;
    property SectionIndent default 32;
    property TabStop default True;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnChange;
    // property        OnDrawWord;
    property OnWordInfo;
    property OnParseWord;
    property OnLog;
    property OnEnter;
    property OnExit;
    property OnBeforeBreakPointChanged;
    property BreakPointsPopupMenu;
    property PopupMenu;
    property OnContextPopup;
    property OnBreakPointPopup;
    property BeforeProposalCall;
  end;

  TUserTokenEventProc = procedure(Sender: TObject; StartPos, EndPos: Integer; const Line: string; var Token: TToken);

  TDefAddSyntaxAttributes = procedure(N: TMPSyntaxAttributes);

  /// /////////

  TMPSyntaxCompletionProposalForm = class(TForm)
  private
    FItemList: TStrings;
    FInsertList: TStrings;

    FProposalNames: TStrings;
    FCurProposalName: string;
    FItems: array of string;
    FInserts: array of string;

    FListProp: TListBox;
    FOwnerPos: TPoint;
    procedure ListBoxClick(Sender: TObject);
    procedure ListBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CompleteProposal;
    procedure Up;
    procedure Down;
    procedure ToHome;
    procedure ToEnd;
    procedure PAGEDOWN;
    procedure PAGEUP;
    procedure ListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);

  protected
    procedure Deactivate; override;
    procedure DoHide; override;
    procedure ChangeListText;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ShowEx(X, Y: Integer);
    procedure SaveProposals(const aName: string);
    procedure ApplyProposal(const aName: string);
    procedure AddProposal(const aName: string);

    procedure ChangeItems(NewItems: TMPProposalItems);
    property ItemList: TStrings read FItemList;
    property InsertList: TStrings read FInsertList;
    property CurProposalName: string read FCurProposalName;
  end;

var
  DefUserTokenEventProc: TUserTokenEventProc;
  DefAddSyntaxAttributes: TDefAddSyntaxAttributes;
  DefProposal: TMPProposalItems;

const
  SectionMarks: array [TSectionMark] of string = ('', '{<+}', '{<-}', '{>>}');
  SECTION_HEADER_LENGTH = 4;
  OperatorChars         = ['+', '-', '*', '/', '<', '>', '='];

  ProposalDelimiter: string = '#$';

implementation

{$R pFIBSyntaxMemo.res}

uses
  Math, StrUtils, Variants;

var
  CF_SYNTAX: THandle;

  // Results of RangeRowToScreenRow()
const
  ROW_ABOVE_SCREEN = -1;
  ROW_HIDEN        = -2;
  ROW_BELOW_SCREEN = -3;

procedure Swap(var A, B: Integer);
var
  t: Integer;
begin
  t := A;
  A := B;
  B := t;
end;

// Class TParseAttributes Implementation

// C O N S T R U C T O R
constructor TMPSyntaxAttributes.Create(Owner: TMPCustomSyntaxMemo);
var
  t: TToken;
begin

  inherited Create;
  fRichMemo := Owner;
  // Clear the style table
  for t := Low(TToken) to High(TToken) do
    with fTokenStyles[t] do
      begin
        tsForeground := clDefault;
        tsBackground := clDefault;
      end;
  // Default styles
  fLitString := '''';
  fLitChar := ''''; // For C
  fLitILComment := '//';
  fLitILCompDir := '#'; // For C
  fLitMLCommentB := '{';
  fLitMLCommentE := '}';
  fLitELCommentB := '(*';
  fLitELCommentE := '*)';
  fLitMLCompDirB := '{$';
  fLitMLCompDirB := '}';
  fLitHexPrefix := '$';
  fLitDecimalPoint := '.';
  fLitReference := '@';
  fLitDereference := '^';
  fParseOptions := [poHasELComment, poHasMLComment, poHasILComment,
    poHasHexPrefix, poFloatValid, poHasReference, poHasDereference, poHasMLCompDir];

  { fTokenStyles[tokReservedWord].tsForeground := clBlack;
    fTokenStyles[tokReservedWord].tsStyle      := [fsBold];
  }
  fTokenStyles[tokString].tsForeground := clBlue;
  fTokenStyles[tokString].tsStyle := [fsItalic];
  fTokenStyles[tokStringEnd].tsForeground := clBlue;
  fTokenStyles[tokStringEnd].tsStyle := [fsItalic];

  fTokenStyles[tokChar].tsForeground := clBlue;
  fTokenStyles[tokChar].tsStyle := [fsItalic];
  fTokenStyles[tokCharEnd].tsForeground := clBlue;
  fTokenStyles[tokCharEnd].tsStyle := [fsItalic];

  fTokenStyles[tokHexValue].tsForeground := clNavy;
  fTokenStyles[tokHexValue].tsStyle := [fsBold];
  fTokenStyles[tokInteger].tsForeground := clRed;
  fTokenStyles[tokFloat].tsForeground := clRed;
  fTokenStyles[tokFloat].tsStyle := [fsItalic];

  fTokenStyles[tokILCompDir].tsForeground := clGreen;
  fTokenStyles[tokMLCompDirBeg].tsForeground := clGreen;
  fTokenStyles[tokMLCompDirEnd].tsForeground := clGreen;

  fTokenStyles[tokILComment].tsForeground := clGray;
  fTokenStyles[tokILComment].tsStyle := [fsItalic];

  fTokenStyles[tokMLCommentBeg].tsForeground := clGray;
  fTokenStyles[tokMLCommentBeg].tsStyle := [fsItalic];
  fTokenStyles[tokMLCommentEnd].tsForeground := clGray;
  fTokenStyles[tokMLCommentEnd].tsStyle := [fsItalic];

  fTokenStyles[tokELCommentBeg].tsForeground := clGray;
  fTokenStyles[tokELCommentBeg].tsBackground := clWindow;
  fTokenStyles[tokELCommentBeg].tsStyle := [fsItalic];
  fTokenStyles[tokELCommentEnd].tsForeground := clGray;
  fTokenStyles[tokELCommentEnd].tsBackground := clWindow;
  fTokenStyles[tokELCommentEnd].tsStyle := [fsItalic];

  { fTokenStyles[tokELCommentBeg].tsForeground  := clNavy;
    fTokenStyles[tokELCommentBeg].tsBackground  := clMoneyGreen;
    fTokenStyles[tokELCommentEnd].tsForeground  := clNavy;
    fTokenStyles[tokELCommentEnd].tsBackground  := clMoneyGreen;{ }

  fTokenStyles[tokParenBeg].tsForeground := clBlue;
  fTokenStyles[tokParenEnd].tsForeground := clBlue;
  fTokenStyles[tokBrackedBeg].tsForeground := clBlue;
  fTokenStyles[tokBracketEnd].tsForeground := clBlue;

  fTokenStyles[tokILCompDir].tsForeground := clGreen;
  if Assigned(DefAddSyntaxAttributes) then
    DefAddSyntaxAttributes(Self)
end;

// Copies the whole state of a sibling
procedure TMPSyntaxAttributes.Assign(Friend: TMPSyntaxAttributes);
begin
  if (Self = Friend) or (Friend = nil) then
    Exit;
  fRichMemo.Lines.BeginUpdate;
  fLitString := Friend.fLitString;
  fLitChar := Friend.fLitChar;
  fLitILComment := Friend.fLitILComment;
  fLitILCompDir := Friend.fLitILCompDir;
  fLitMLCompDirB := Friend.fLitMLCompDirB;
  fLitMLCompDirE := Friend.fLitMLCompDirE;
  fLitMLCommentB := Friend.fLitMLCommentB;
  fLitMLCommentE := Friend.fLitMLCommentE;
  fLitELCommentB := Friend.fLitELCommentB;
  fLitELCommentE := Friend.fLitELCommentE;
  fLitHexPrefix := Friend.fLitHexPrefix;
  fLitDecimalPoint := Friend.fLitDecimalPoint;
  fLitReference := Friend.fLitReference;
  fLitDereference := Friend.fLitDereference;
  fParseOptions := Friend.fParseOptions;
  Move(Friend.fTokenStyles, fTokenStyles, SizeOf(fTokenStyles));
  fRichMemo.Lines.State := fRichMemo.Lines.State + [ssNeedReparseAll];
  fRichMemo.Lines.EndUpdate;
end;

// Returns True if the visual attributes of the tokens are equal
function TMPSyntaxAttributes.Equals(const T1, T2: TToken): Boolean;
begin
  Result := (fTokenStyles[T1].tsForeground = fTokenStyles[T2].tsForeground) and
    (fTokenStyles[T1].tsBackground = fTokenStyles[T2].tsBackground) and
    (fTokenStyles[T1].tsStyle = fTokenStyles[T2].tsStyle);
end;

// Returns the token color attribute
function TMPSyntaxAttributes.GetColor(const Token: TToken; const Index: Integer): TColor;
begin
  if Index = 0 then
    Result := fTokenStyles[Token].tsForeground
  else
    Result := fTokenStyles[Token].tsBackground;
end;

// Returns the token font style attribute
function TMPSyntaxAttributes.GetStyle(const Token: TToken): TFontStyles;
begin
  Result := fTokenStyles[Token].tsStyle;
end;

// Sets the token color attribute
procedure TMPSyntaxAttributes.SetColor(const Token: TToken; const Index: Integer; const Value: TColor);
begin
  if Index = 0 then
    fTokenStyles[Token].tsForeground := Value
  else
    fTokenStyles[Token].tsBackground := Value;
end;

// Sets the token font style attribute
procedure TMPSyntaxAttributes.SetStyle(const Token: TToken; const Value: TFontStyles);
begin
  fTokenStyles[Token].tsStyle := Value;
end;

// Copies the attributes of token SrcToken to all tokens in DstTokArray
procedure TMPSyntaxAttributes.CopyAttrs(const SrcToken: TToken; DstTokArray: array of TToken);
var
  t: TToken;
begin
  for t := Low(DstTokArray) to High(DstTokArray) do
    fTokenStyles[DstTokArray[t]] := fTokenStyles[SrcToken];
end;

const
  bools: array [Boolean] of string = ('N', 'Y');
  CURRENT_SYN_VERSION = '1.0';
  SSynVersion         = 'SyntaxVersion';
  SLitString          = 'LitString';
  SLitChar            = 'LitChar';
  SLitILCompDir       = 'LitILCompDir';
  SLitMLCompDirB      = 'LitMLCompDirB';
  SLitMLCompDirE      = 'LitMLCompDirE';

  SLitILComment     = 'LitILComment';
  SLitMLCommentB    = 'LitMLCommentB';
  SLitMLCommentE    = 'LitMLCommentE';
  SLitELCommentB    = 'LitELCommentB';
  SLitELCommentE    = 'LitELCommentE';
  SLitHexPrefix     = 'LitHexPrefix';
  SLitDecimalPoint  = 'LitDecimalPoint';
  SLitReference     = 'LitReference';
  SLitDereference   = 'LitDereference';
  SForeground       = 'Fore';
  SBackground       = 'Back';
  SStyleBold        = 'Bold';
  SStyleUnderline   = 'ULin';
  SStyleItalic      = 'Ital';
  SPOHasELComment   = 'HasELComment';
  SPOHasMLComment   = 'HasMLComment';
  SPOHasILComment   = 'HasILComment';
  SPOHasILCompDir   = 'HasILCompDir';
  SPOHasMLCompDir   = 'HasMLCompDir';
  SPOHasHexPrefix   = 'HasHexPrefix';
  SPOHasChar        = 'HasChar';
  SPOValidFloat     = 'ValidFloat';
  SPOHasReference   = 'HasReference';
  SPOHasDereference = 'HasDereference';
  SPOBLSeparated    = 'BLSeparated';

  // Loads settings from a file
procedure TMPSyntaxAttributes.LoadFromFile(const FileName: string);
var
  t: TToken;
  { }
  function FirstChar(const s: string): Char;
  begin
    if s = '' then
      Result := #0
    else
      Result := s[1];
  end;

{ }
begin
  with TStringList.Create do
    begin
      fRichMemo.Lines.BeginUpdate;
      try
        LoadFromFile(FileName);
        if Values[SSynVersion] <> CURRENT_SYN_VERSION then
          raise Exception.Create('Unsuitable syntax version');
        fLitString := FirstChar(Values[SLitString]);
        fLitChar := FirstChar(Values[SLitChar]);
        fLitILCompDir := Values[SLitILCompDir];
        fLitMLCompDirB := Values[SLitMLCompDirB];
        fLitMLCompDirE := Values[SLitMLCompDirE];
        fLitILComment := Values[SLitILComment];
        fLitMLCommentB := Values[SLitMLCommentB];
        fLitMLCommentE := Values[SLitMLCommentE];
        fLitELCommentB := Values[SLitELCommentB];
        fLitELCommentE := Values[SLitELCommentE];
        fLitHexPrefix := Values[SLitHexPrefix];
        fLitDecimalPoint := FirstChar(Values[SLitDecimalPoint]);
        fLitReference := FirstChar(Values[SLitReference]);
        fLitDereference := FirstChar(Values[SLitDereference]);

        fParseOptions := [];
        if Values[SPOHasChar] = bools[True] then
          Include(fParseOptions, poHasChar);
        if Values[SPOHasELComment] = bools[True] then
          Include(fParseOptions, poHasELComment);
        if Values[SPOHasMLComment] = bools[True] then
          Include(fParseOptions, poHasMLComment);
        if Values[SPOHasILComment] = bools[True] then
          Include(fParseOptions, poHasILComment);
        if Values[SPOHasILCompDir] = bools[True] then
          Include(fParseOptions, poHasILCompDir);
        if Values[SPOHasMLCompDir] = bools[True] then
          Include(fParseOptions, poHasMLCompDir);
        if Values[SPOHasHexPrefix] = bools[True] then
          Include(fParseOptions, poHasHexPrefix);
        if Values[SPOValidFloat] = bools[True] then
          Include(fParseOptions, poFloatValid);
        if Values[SPOHasReference] = bools[True] then
          Include(fParseOptions, poHasReference);
        if Values[SPOHasDereference] = bools[True] then
          Include(fParseOptions, poHasDereference);
        if Values[SPOBLSeparated] = bools[True] then
          Include(fParseOptions, poBLSeparated);

        for t := Low(TToken) to High(TToken) do
          with fTokenStyles[t] do
            begin
              tsForeground := StrToIntDef(Values[SForeground + IntToStr(Ord(t))], clDefault);
              tsBackground := StrToIntDef(Values[SBackground + IntToStr(Ord(t))], clDefault);
              tsStyle := [];
              if Values[SStyleBold + IntToStr(Ord(t))] = bools[True] then
                Include(tsStyle, fsBold);
              if Values[SStyleUnderline + IntToStr(Ord(t))] = bools[True] then
                Include(tsStyle, fsUnderline);
              if Values[SStyleItalic + IntToStr(Ord(t))] = bools[True] then
                Include(tsStyle, fsItalic);
            end;

        fRichMemo.Lines.State := fRichMemo.Lines.State + [ssNeedReparseAll];
      finally
        fRichMemo.Lines.EndUpdate;
        Free;
      end
    end;
end;

// Saves settings to a file
procedure TMPSyntaxAttributes.SaveToFile(const FileName: string);
var
  t: TToken;
begin
  with TStringList.Create do
    begin
      Values[SSynVersion] := CURRENT_SYN_VERSION;

      Values[SLitString] := fLitString;
      Values[SLitChar] := fLitChar;
      Values[SLitILCompDir] := fLitILCompDir;
      Values[SLitMLCompDirB] := fLitMLCompDirB;
      Values[SLitMLCompDirE] := fLitMLCompDirE;
      Values[SLitILComment] := fLitILComment;
      Values[SLitMLCommentB] := fLitMLCommentB;
      Values[SLitMLCommentE] := fLitMLCommentE;
      Values[SLitELCommentB] := fLitELCommentB;
      Values[SLitELCommentE] := fLitELCommentE;
      Values[SLitHexPrefix] := fLitHexPrefix;
      Values[SLitDecimalPoint] := fLitDecimalPoint;
      Values[SLitReference] := fLitReference;
      Values[SLitDereference] := fLitDereference;

      Values[SPOHasChar] := bools[poHasChar in fParseOptions];
      Values[SPOHasELComment] := bools[poHasELComment in fParseOptions];
      Values[SPOHasMLComment] := bools[poHasMLComment in fParseOptions];
      Values[SPOHasILComment] := bools[poHasILComment in fParseOptions];
      Values[SPOHasILCompDir] := bools[poHasILCompDir in fParseOptions];
      Values[SPOHasMLCompDir] := bools[poHasMLCompDir in fParseOptions];
      Values[SPOHasHexPrefix] := bools[poHasHexPrefix in fParseOptions];
      Values[SPOValidFloat] := bools[poFloatValid in fParseOptions];
      Values[SPOHasReference] := bools[poHasReference in fParseOptions];
      Values[SPOHasDereference] := bools[poHasDereference in fParseOptions];
      Values[SPOBLSeparated] := bools[poBLSeparated in fParseOptions];

      for t := Low(TToken) to High(TToken) do
        with fTokenStyles[t] do
          begin
            if tsForeground <> clDefault then
              Values[SForeground + IntToStr(Ord(t))] := IntToStr(tsForeground);
            if tsForeground <> clDefault then
              Values[SBackground + IntToStr(Ord(t))] := IntToStr(tsBackground);
            if fsBold in fTokenStyles[t].tsStyle then
              Values[SStyleBold + IntToStr(Ord(t))] := bools[True];
            if fsUnderline in fTokenStyles[t].tsStyle then
              Values[SStyleUnderline + IntToStr(Ord(t))] := bools[True];
            if fsItalic in fTokenStyles[t].tsStyle then
              Values[SStyleItalic + IntToStr(Ord(t))] := bools[True];
          end;

      try
        SaveToFile(FileName);
      finally
        Free;
      end;
    end;
end;

// CLASS TMPSyntaxParser Implementation

const

  TokenStrings: array [tokBlank .. tokReservedSiO] of string = ('tokBlank',
    'tokText', 'tokString', 'tokStringEnd', 'tokHexValue', 'tokInteger',
    'tokFloat', 'tokILComment', 'tokMLCommentBeg', 'tokMLCommentEnd',
    'tokELCommentBeg', 'tokELCommentEnd', 'tokEndLine', 'tokParenBeg',
    'tokParenEnd', 'tokBrackedBeg', 'tokBracketEnd', 'tokOperator', 'tokPoint',
    'tokComma', 'tokReference', 'tokDereference', 'tokReserved', 'tokILCompDir',
    'tokMLCompDirBeg', 'tokMLCompDirEnd', 'tokChar', 'tokCharEnd',
    'tokErroneous', 'tokErroneous2', 'tokReservedSIO');

  TOKEN_USER = 'tokUser#';

  // Creates a clone of an existing parser
constructor TMPSyntaxParser.Create(const AsCloneOf: TMPSyntaxParser = nil);
begin
  inherited Create(True);
  if Assigned(AsCloneOf) then
    Assign(AsCloneOf);
end;

// Adds the start position (0-based), length and token of a word
procedure TMPSyntaxParser.AddToken(const Beg, Len: Integer; Token: TToken);
var
  W: TMPSyntaxToken;
begin
  W := TMPSyntaxToken.Create;
  W.stStart := Word(Beg - 1);
  W.stLength := Word(Len);
  W.stToken := Token;
  W.stStyle := [];
  Add(W);
end;

// Returns the given token
function TMPSyntaxParser.GetToken(const TokIndex: Integer): TMPSyntaxToken;
begin
  Result := TMPSyntaxToken(inherited Items[TokIndex]);
end;

// Sets the given token
procedure TMPSyntaxParser.SetToken(const TokIndex: Integer; const Value: TMPSyntaxToken);
begin
  Items[TokIndex] := Value;
end;

// Returns a "portrait" of the line code (for debugging)
function TMPSyntaxParser.AsString: string;
var
  i: Integer;
  s: string;
  t: TMPSyntaxToken;
begin
  Result := '';
  for i := 0 to Count - 1 do
    begin
      t := Tokens[i];
      if t.stToken > tokReserved then
        s := TOKEN_USER + IntToHex(t.stToken, 2) + 'H'
      else
        s := TokenStrings[t.stToken];
      Result := Result + #13#10 + s + #9'Beg=' + IntToStr(t.stStart) + #9'Len=' + IntToStr(t.stLength);
    end;
end;

// Takes the data
procedure TMPSyntaxParser.Assign(const Friend: TMPSyntaxParser);
var
  i: Integer;
  t, NewT: TMPSyntaxToken;
begin
  Clear;
  for i := 0 to Friend.Count - 1 do
    begin
      t := Friend.Tokens[i];
      NewT := TMPSyntaxToken.Create;
      NewT.stStart := t.stStart;
      NewT.stLength := t.stLength;
      NewT.stToken := t.stToken;
      NewT.stStyle := t.stStyle;
      Add(NewT);
    end;
  fSection := Friend.Section;
  fVisibleIndex := Friend.VisibleIndex;
  fNeedReparse := Friend.NeedReparse;
end;

// Removes line info
procedure TMPSyntaxParser.Clear;
begin
  inherited Clear;
  fNeedReparse := False;
end;

// Groups adjacent tokens (tokString-tokStringEnd etc.)
// Irreversible operation.
procedure TMPSyntaxParser.GroupTokens;
var
  wi: Integer;
  { }
  procedure GroupSame(var i: Integer; SameTokens: TTokenSet);
  var
    W, W1: TMPSyntaxToken;
  begin
    W := Tokens[i];
    Inc(i);
    while i < Count do
      begin
        W1 := Tokens[i];
        if not(W1.stToken in SameTokens) then
          Break;
        W.stLength := W1.stStart + W1.stLength - W.stStart;
        W.stToken := W1.stToken;
        Delete(i);
      end;
  end;

begin
  if Count < 2 then
    Exit;
  wi := 0;
  while wi < Count do
    begin
      case GetToken(wi).stToken of
        tokString: GroupSame(wi, [tokString, tokStringEnd]);
        tokChar: GroupSame(wi, [tokChar, tokCharEnd]);

        tokMLCommentBeg: GroupSame(wi, [tokMLCommentBeg, tokMLCommentEnd]);

        tokELCommentBeg: GroupSame(wi, [tokELCommentBeg, tokELCommentEnd]);

        tokILComment: GroupSame(wi, [tokILComment]);

        tokILCompDir: GroupSame(wi, [tokILCompDir]);

        tokMLCompDirBeg: GroupSame(wi, [tokMLCompDirBeg, tokMLCompDirEnd]);
        else
          Inc(wi);
      end;
    end;
end;

// Splits tokens based on the given selection range
// If sx < 0, the line is selected from the screen start (not the first line of the selection)
// If ex = MAXINT, the line is selected to the screen end (not the last line of the selection)
// Irreversible operation.

function CenterPoint(const Rect: TRect): TPoint;
begin
  with Rect do
    begin
      Result.X := (Right - Left) div 2 + Left;
      Result.Y := (Bottom - Top) div 2 + Top;
    end;
end;

{$IFNDEF D9+}

function EnsureRange(const AValue, AMin, AMax: Integer): Integer;
begin
  Result := AValue;
  // assert(AMin <= AMax);
  if Result < AMin then
    Result := AMin;
  if Result > AMax then
    Result := AMax;
end;

function PointsEqual(const P1, P2: TPoint): Boolean;
begin
  Result := (P1.X = P2.X) and (P1.Y = P2.Y);
end;

function Sign(const AValue: Integer): Integer;
begin
  Result := 0;
  if AValue < 0 then
    Result := -1
  else if AValue > 0 then
    Result := 1;
end;

function StuffString(const AText: string; AStart, ALength: Cardinal; const ASubText: string): string;
begin
  Result := Copy(AText, 1, AStart - 1) + ASubText + Copy(AText, AStart + ALength, MaxInt);
end;

function InRange(const AValue, AMin, AMax: Int64): Boolean;
begin
  Result := (AValue >= AMin) and (AValue <= AMax);
end;

function RightStr(const AText: AnsiString; const ACount: Integer): AnsiString;
begin
  Result := Copy(WideString(AText), Length(WideString(AText)) + 1 - ACount, ACount);
end;

{$IFNDEF D10+}

function LeftStr(const AText: AnsiString; const ACount: Integer): AnsiString; overload;
begin
  Result := Copy(WideString(AText), 1, ACount);
end;
{$ENDIF}

function IfThen(AValue: Boolean; const ATrue: Integer; const AFalse: Integer): Integer;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

function PosEx(const SubStr, s: string; Offset: Integer = 1): Integer;
asm
  test  eax, eax
  jz    @Nil
  test  edx, edx
  jz    @Nil
  dec   ecx
  jl    @Nil

  push  esi
  push  ebx

  mov   esi, [edx-4]  // Length(Str)
  mov   ebx, [eax-4]  // Length(Substr)
  sub   esi, ecx      // effective length of Str
  add   edx, ecx      // addr of the first char at starting position
  cmp   esi, ebx
  jl    @Past         // jump if EffectiveLength(Str)<Length(Substr)
  test  ebx, ebx
  jle   @Past         // jump if Length(Substr)<=0

  add   esp, -12
  add   ebx, -1       // Length(Substr)-1
  add   esi, edx      // addr of the terminator
  add   edx, ebx      // addr of the last char at starting position
  mov   [esp+8], esi  // save addr of the terminator
  add   eax, ebx      // addr of the last char of Substr
  sub   ecx, edx      // -@Str[Length(Substr)]
  neg   ebx           // -(Length(Substr)-1)
  mov   [esp+4], ecx  // save -@Str[Length(Substr)]
  mov   [esp], ebx    // save -(Length(Substr)-1)
  movzx ecx, byte ptr [eax] // the last char of Substr

@Loop:
  cmp   cl, [edx]
  jz    @Test0
@AfterTest0:
  cmp   cl, [edx+1]
  jz    @TestT
@AfterTestT:
  add   edx, 4
  cmp   edx, [esp+8]
  jb   @Continue
@EndLoop:
  add   edx, -2
  cmp   edx, [esp+8]
  jb    @Loop
@Exit:
  add   esp, 12
@Past:
  pop   ebx
  pop   esi
@Nil:
  xor   eax, eax
  ret
@Continue:
  cmp   cl, [edx-2]
  jz    @Test2
  cmp   cl, [edx-1]
  jnz   @Loop
@Test1:
  add   edx,  1
@Test2:
  add   edx, -2
@Test0:
  add   edx, -1
@TestT:
  mov   esi, [esp]
  test  esi, esi
  jz    @Found
@String:
  movzx ebx, word ptr [esi+eax]
  cmp   bx, word ptr [esi+edx+1]
  jnz   @AfterTestT
  cmp   esi, -2
  jge   @Found
  movzx ebx, word ptr [esi+eax+2]
  cmp   bx, word ptr [esi+edx+3]
  jnz   @AfterTestT
  add   esi, 4
  jl    @String
@Found:
  mov   eax, [esp+4]
  add   edx, 2

  cmp   edx, [esp+8]
  ja    @Exit

  add   esp, 12
  add   eax, edx
  pop   ebx
  pop   esi
end;

{$ENDIF}

function IfThenStr(AValue: Boolean; const ATrue: string; const AFalse: string): string;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

procedure TMPSyntaxParser.SplitTokens(const sx, ex: Integer);
var
  wi: Integer;
  t: TMPSyntaxToken;
  { }
  function TestSel(const r: Integer): Boolean;
  var
    TT: TMPSyntaxToken;
  begin
    with t do
      begin
        Result := InRange(r, stStart + 1, stStart + stLength - 1);
        if Result then
          begin
            // Split the chain in two
            TT := TMPSyntaxToken.Create;
            TT.stStart := r;
            TT.stLength := stStart + stLength - r;
            TT.stToken := stToken;
            stLength := r - stStart;
            Insert(wi + 1, TT);
          end
      end
  end;

begin
  wi := 0;
  while wi < Count do
    begin
      t := Tokens[wi];
      if not TestSel(sx) then
        TestSel(ex);
      if InRange(t.stStart, sx, ex - 1) then
        Include(t.stStyle, stsInSelection)
      else
        Exclude(t.stStyle, stsInSelection);
      Inc(wi);
    end;
end;

// Returns the first token of the line (if any - otherwise tokText)
function TMPSyntaxParser.FirstToken: TToken;
begin
  if Count > 0 then
    Result := Tokens[0].stToken
  else
    Result := tokText;
end;

// Returns the last token of the line (...)
function TMPSyntaxParser.LastToken: TToken;
begin
  if Count > 0 then
    Result := Tokens[Count - 1].stToken
  else
    Result := tokText;
end;

// Main - performs syntax parsing of the line (parser)
function TMPSyntaxParser.Parse(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
begin
  if poBLSeparated in PA.ParseOptions then
    Result := ParseLine(Line, LineIndex, LastToken, PA)
  else
    Result := ParseLineEx(Line, LineIndex, LastToken, PA);
  fNeedReparse := False;
end;

// ParseLine() Syntax parsing of a line with space-separated words
function TMPSyntaxParser.ParseLine(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
var
  si: string;
  i, wordbeg: Integer;
  InWord, InLit, InLitChar: Boolean;
  { }
  function HasChars(const s: string; StartPos: Integer; Chars: TCharSet): Boolean;
  var
    i: Integer;
  begin
    Result := False;
    for i := StartPos to Length(s) do
      if not(s[i] in Chars) then
        Exit;
    Result := True;
  end;

{ }
begin
  Clear;
  InWord := False;
  InLit := False;
  InLitChar := False;
  wordbeg := 1;

  Result := tokText;
  if Length(Line) = 0 then
    Exit;
  if Line[Length(Line)] >= ' ' then
    Line := Line + ' ';

  for i := 1 to Length(Line) do

    if Line[i] > ' ' then
      begin
        // Symbol found
        if not InWord then
          wordbeg := i;
        InWord := True;
      end
    else
      begin

        // Blank symbol
        if InWord then
          begin
            si := Copy(Line, wordbeg, i - wordbeg);

            Result := LastToken;

            { Test for comments begin }
            if not(Result in [tokMLCommentBeg, tokELCommentBeg, tokMLCompDirBeg]) then
              begin
                if (poHasELComment in PA.ParseOptions) and (Pos(PA.LiteralELCommentBeg, si) = 1) then
                  Result := tokELCommentBeg
                else if (poHasMLComment in PA.ParseOptions) and (Pos(PA.LiteralMLCommentBeg, si) = 1) then
                  Result := tokMLCommentBeg
                else if (poHasILComment in PA.ParseOptions) and (Pos(PA.LiteralILComment, si) = 1) then
                  Result := tokILComment
                else if (poHasMLCompDir in PA.ParseOptions) and (Pos(PA.LiteralMLCompDirBeg, si) = 1) then
                  Result := tokMLCompDirBeg
                else if (poHasILCompDir in PA.ParseOptions) and (Pos(PA.LiteralILCompilerDirective, si) = 1) then
                  Result := tokILCompDir;

              end;

            { Test for comments end }
            case Result of
              tokILComment: ; // lasts to the end of line
              tokILCompDir: ;

              tokMLCommentBeg:
                with PA do
                  if RightStr(si, Length(LiteralMLCommentEnd)) = LiteralMLCommentEnd then
                    Result := tokMLCommentEnd;

              tokELCommentBeg:
                with PA do
                  if RightStr(si, Length(PA.LiteralELCommentEnd)) = LiteralELCommentEnd then
                    Result := tokELCommentEnd;

              tokMLCompDirBeg:
                with PA do
                  if RightStr(si, Length(LiteralMLCompDirEnd)) = LiteralMLCompDirEnd then
                    Result := tokMLCompDirEnd;

              else
                // Return to the default token
                Result := tokText;

                { Test for string begin }
                if si[1] = PA.LiteralString then
                  InLit := True;
                { Test for string end }
                if InLit then
                  begin
                    Result := tokStringEnd;
                    if si[Length(si)] = PA.LiteralString then
                      InLit := False;
                  end
                else

                  { Test for AnsiChar begin }
                  if si[1] = PA.LiteralChar then
                    InLitChar := True;
                { Test for AnsiChar end }
                if InLitChar then
                  begin
                    Result := tokCharEnd;
                    if si[Length(si)] = PA.LiteralChar then
                      InLitChar := False;
                  end
                else

                  { Numbers: separately Integer, Hex or Float values }
                  if (Length(si) > Length(PA.LiteralHexPrefix)) and (Pos(PA.LiteralHexPrefix, si) = 1) and
                    HasChars(si, Length(PA.LiteralHexPrefix) + 1, ['0' .. '9', 'A' .. 'F', 'a' .. 'f']) then
                    Result := tokHexValue
                  else if (Length(si) > 1) and (si[1] in ['-', '0' .. '9']) then
                    begin
                      if HasChars(si, 2, ['0' .. '9']) then
                        Result := tokInteger
                      else if HasChars(si, 2, ['0' .. '9', PA.LiteralDecimalPoint]) then
                        Result := tokFloat
                    end;

            end;

            { User tokens }
            if Result = tokText then // Call the external hook
              if Assigned(PA.OnUserToken) then
                PA.OnUserToken(Self, si, wordbeg, LineIndex, Result);

            // Add to processed words list
            AddToken(wordbeg, i - wordbeg, Result);
            LastToken := Result;
          end;
        InWord := False;
      end;

  // An inline comment always ends at the end of line
  // General normalization of the line's final token
  // (only open multiline comments matter)
  if not(Result in [tokMLCommentBeg, tokELCommentBeg, tokMLCompDirBeg]) then
    Result := tokText;
end;

// "Advanced" line syntax parsing
function TMPSyntaxParser.ParseLineEx(const Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
const
  HexChars: TCharSet = ['0' .. '9', 'A' .. 'F', 'a' .. 'f'];
  IntChars: TCharSet = ['0' .. '9'];
  { Returns the char category in the line }
type
  TCharRange = (crBlank, crSymbol, crLetter, crLit);
  function CharRange(c: Char): TCharRange;
  begin
    if c = PA.LiteralString then
      Result := crLit
    else
      case c of
        #$00 .. #$20: Result := crBlank;
        #$21 .. #$2F, #$3A .. #$40: Result := crSymbol;
        #$30 .. #$39, #$41 .. #$FF: Result := crLetter;
        else
          Result := crSymbol;
      end;
  end;

// Returns whether the char rank has changed
  function CharRangeChange(c1, c2: Char): Boolean;
  begin
    Result := CharRange(c1) <> CharRange(c2);
  end;

// Check for comment start
  function TestCommentsBegin(const Pos: Integer; var Token: TToken): Boolean;
  begin
    Result := True;
    if (poHasELComment in PA.ParseOptions) and (PosEx(PA.LiteralELCommentBeg, Line, Pos) = Pos) then
      Token := tokELCommentBeg
    else if (poHasMLComment in PA.ParseOptions) and (PosEx(PA.LiteralMLCommentBeg, Line, Pos) = Pos) then
      Token := tokMLCommentBeg
    else if (poHasILComment in PA.ParseOptions) and (PosEx(PA.LiteralILComment, Line, Pos) = Pos) then
      Token := tokILComment
    else if (poHasILCompDir in PA.ParseOptions) and (PosEx(PA.LiteralILCompilerDirective, Line, Pos) = Pos) then
      Token := tokILCompDir
    else if (poHasMLCompDir in PA.ParseOptions) and (PosEx(PA.LiteralMLCompDirBeg, Line, Pos) = Pos) then
      Token := tokMLCompDirBeg
    else
      Result := False;
  end;

// Returns whether the token is a comment
  function InComment(const Token: TToken): Boolean;
  begin
    Result := Token in [tokELCommentBeg, tokMLCommentBeg, tokILComment, tokMLCompDirBeg, tokILCompDir];
  end;

// Processes comments starting at the given char (Pos)
// Returns the position of the char following the comment end (Pos)
// Gets the comment type via Token, and stores the last
// processed token there too
  procedure ProcessComments(var Pos: Integer; var Token: TToken);
  var
    wordbeg: Integer;
    si: string;
    InWord: Boolean;
  begin
    si := '';
    InWord := True;
    wordbeg := Pos;
    while Pos <= Length(Line) do
      begin
        if Line[Pos] > ' ' then
          begin
            if not InWord then
              wordbeg := Pos;
            InWord := True;
            si := si + Line[Pos];
            // Check for comment end
            case Token of
              tokMLCommentBeg:
                if RightStr(si, Length(PA.LiteralMLCommentEnd)) = PA.LiteralMLCommentEnd then
                  begin
                    Token := tokMLCommentEnd;
                    Inc(Pos);
                    AddToken(wordbeg, Pos - wordbeg, Token);
                    Exit;
                  end;
              tokELCommentBeg:
                if RightStr(si, Length(PA.LiteralELCommentEnd)) = PA.LiteralELCommentEnd then
                  begin
                    Token := tokELCommentEnd;
                    Inc(Pos);
                    AddToken(wordbeg, Pos - wordbeg, Token);
                    Exit;
                  end;
              tokMLCompDirBeg:
                if RightStr(si, Length(PA.LiteralMLCompDirEnd)) = PA.LiteralMLCompDirEnd then
                  begin
                    Token := tokMLCompDirEnd;
                    Inc(Pos);
                    AddToken(wordbeg, Pos - wordbeg, Token);
                    Exit;
                  end;
            end;

            if (Pos = Length(Line)) then
              if InWord then
                begin
                  InWord := False;
                  AddToken(wordbeg, Pos - wordbeg + 1, Token);
                  si := '';
                end;
          end
        else if InWord then
          begin
            InWord := False;
            AddToken(wordbeg, Pos - wordbeg, Token);
            si := '';
          end;
        Inc(Pos);
      end;
  end;

// Processes a string starting at the given char, so that Line[Pos] = fLitString
// Returns the position of the char following the string end
  procedure ProcessString(var Pos: Integer);
  var
    wordbeg: Integer;
    InWord: Boolean;
  begin
    InWord := True;
    wordbeg := Pos;
    // Inc(Pos);
    while Pos <= Length(Line) do
      begin
        Inc(Pos);
        if Line[Pos] > ' ' then
          begin
            if not InWord then
              wordbeg := Pos;
            InWord := True;
            // Check for string end
            if Line[Pos] = PA.LiteralString then
              begin
                Inc(Pos);
                AddToken(wordbeg, Pos - wordbeg, tokStringEnd);
                Exit;
              end;
            if (Pos = Length(Line)) and InWord then
              begin
                InWord := False;
                AddToken(wordbeg, Pos - wordbeg + 1, tokString);
              end;

          end
        else if InWord then
          begin
            InWord := False;
            AddToken(wordbeg, Pos - wordbeg, tokString);
          end;
        // Inc(Pos);
      end;
  end;

// Processes a char literal starting at the given char, so that Line[Pos] = fLitChar
// Returns the position of the char following the string end
  procedure ProcessChar(var Pos: Integer);
  var
    wordbeg: Integer;
    InWord: Boolean;
  begin
    InWord := True;
    wordbeg := Pos;
    Inc(Pos);
    while Pos <= Length(Line) do
      begin
        if Line[Pos] > ' ' then
          begin
            if not InWord then
              wordbeg := Pos;
            InWord := True;
            // Check for string end
            if Line[Pos] = PA.LiteralChar then
              begin
                Inc(Pos);
                AddToken(wordbeg, Pos - wordbeg, tokCharEnd);
                Exit;
              end;
            if (Pos = Length(Line)) and InWord then
              begin
                InWord := False;
                AddToken(wordbeg, Pos - wordbeg + 1, tokChar);
              end;

          end
        else if InWord then
          begin
            InWord := False;
            AddToken(wordbeg, Pos - wordbeg, tokChar);
          end;
        Inc(Pos);
      end;
  end;

// Processes a hexadecimal number starting at the given char,
// so that Line[Pos] = fLitHexPrefix
// Returns the position of the char following the number end
  procedure ProcessHexValue(var Pos: Integer);
  var
    wordbeg: Integer;
  begin
    wordbeg := Pos;
    Pos := Pos + Length(PA.LiteralHexPrefix);
    while (Pos <= Length(Line)) and (Line[Pos] in HexChars) do
      Inc(Pos);
    AddToken(wordbeg, Pos - wordbeg, tokHexValue);
  end;

// Processes an integer or fractional number starting at the given char,
// so that Line[Pos] in IntChars
// Returns the position of the char following the number end
  procedure ProcessNumber(var Pos: Integer);
  var
    Token: TToken;
    wordbeg: Integer;
    ValidChars: TCharSet;
  begin
    Token := tokInteger;
    ValidChars := IntChars + [PA.LiteralDecimalPoint];
    wordbeg := Pos;
    repeat
      Inc(Pos);
      if Line[Pos] = PA.LiteralDecimalPoint then
        if Token = tokInteger then
          Token := tokFloat
        else
          Break;
    until (Pos > Length(Line)) or not(Line[Pos] in ValidChars);
    AddToken(wordbeg, Pos - wordbeg, Token);
  end;

var // Word: string;
  Col, wordbeg: Integer;
  c: Char;

  procedure DoOnUserToken(StartPos: Integer; Token: TToken);
  begin
    PA.OnUserToken(Self, Copy(Line, StartPos, Col - StartPos), StartPos, LineIndex, Token);
  end;

  function ProcessReservedWord(StartPos: Integer; Token: TToken): Boolean;
  begin
    Result := False;
    // if Assigned(FRese)
  end;

  function IsBlank(const Line: string; var StartPos: Integer; EndPos: Integer): Boolean;
  var
    i: Integer;
  begin
    Result := True;
    for i := StartPos to EndPos do
      if Line[i] > ' ' then
        begin
          StartPos := i;
          Result := False;
          Exit
        end
  end;

  procedure ProcessWord(StartPos: Integer);
  var
    Token: TToken;
  begin
    // if  Col-StartPos = 0 then Exit;
    if IsBlank(Line, StartPos, Col - 1) then
      begin
        wordbeg := Col;
        Exit;
      end;
    Token := tokText;

    if Assigned(DefUserTokenEventProc) then
      DefUserTokenEventProc(Self, StartPos, Col - 1, Line, Token);
    // User event
    if Assigned(PA.OnUserToken) then
      DoOnUserToken(StartPos, Token);
    // PA.OnUserToken(self, Copy(Line,StartPos,Col-StartPos), StartPos, LineIndex, Token);

    AddToken(StartPos, Col - StartPos, Token);
    wordbeg := Col;
  end;

{ function IsCharAlphaNumeric(c: Char): Boolean;
  begin
  Result := Windows.IsCharAlphaNumeric(c) or (c = '_');
  end;
}
begin
  Clear;
  Result := LastToken;
  if (Length(Line) = 0) or (PA = nil) then
    Exit;
  { if Line[Length(Line)] >= ' ' then
    Line := Line + ' '; }

  wordbeg := 1;

  Col := 1;
  while Col <= Length(Line) do
    begin

      // Next AnsiChar
      c := Line[Col];

      // Handle open and potential comments right away
      if InComment(Result) or TestCommentsBegin(Col, Result) then
        begin
          // ProcessWord(Word, WordBeg);
          ProcessWord(wordbeg);
          ProcessComments(Col, Result);
          wordbeg := Col;
        end
      else

        // Strings supply
        if c = PA.LiteralString then
          begin
            ProcessWord(wordbeg);
            ProcessString(Col);
            wordbeg := Col;
          end
        else

          // AnsiChar supply
          if (c = PA.LiteralChar) and (poHasChar in PA.ParseOptions) then
            begin
              ProcessWord(wordbeg);
              ProcessChar(Col);
              wordbeg := Col;
            end
          else

            // Numbers supply: Hex
            if (poHasHexPrefix in PA.ParseOptions) and (PosEx(PA.LiteralHexPrefix, Line, Col) = Col) then
              begin
                ProcessWord(wordbeg);
                ProcessHexValue(Col);
                wordbeg := Col;
              end
            else

              // Numbers supply: Integer and Float
              if (c in IntChars) and ((Col = 1) or not IsCharAlphaNumeric(Line[Col - 1])) then
                begin
                  ProcessWord(wordbeg);
                  ProcessNumber(Col);
                  wordbeg := Col;
                end
              else

                begin
                  Result := tokText;
                  if c in OperatorChars then
                    Result := tokOperator
                  else
                    case c of
                      '.': Result := tokPoint;
                      ',': Result := tokComma;
                      ';':
                        Result := tokEndLine;
                      '(': Result := tokParenBeg;
                      ')': Result := tokParenEnd;
                      '[': Result := tokBrackedBeg;
                      ']': Result := tokBracketEnd;
                      else
                        if (poHasReference in PA.ParseOptions) and (c = PA.LiteralReference) then
                          Result := tokReference
                        else if (poHasDereference in PA.ParseOptions) and (c = PA.LiteralDereference) then
                          Result := tokDereference;
                    end;
                  if Result <> tokText then
                    begin
                      ProcessWord(wordbeg);
                      AddToken(Col, 1, Result);
                      wordbeg := Col + 1;
                    end
                  else

                    { .. Some other tokens here .. }

                    begin
                      if (c <= ' ') then
                        begin
                          ProcessWord(wordbeg);
                        end
                      else if (Col = Length(Line)) then
                        begin
                          Inc(Col);
                          ProcessWord(wordbeg);
                        end
                        { else
                  //                if CharRangeChange(c, Word[Length(Word)]) then begin
                  if (Col>1) and CharRangeChange(c, Line[Col-1]) then begin
                  ProcessWord( WordBeg);
                  //                    Word := c;
                  WordBeg := Col;
                  end
                  {                else
                  Word := Word + c; }
                    end;

                  Inc(Col);
                end;
    end;
end;

// Class TMPSynMemoStrings methods implementation

var
  GlobalUntitledIndex: Integer = 1;

const
  UNTITLEDFN = 'Untitled';

  // Create() Constructor
constructor TMPSynMemoStrings.Create(const Owner: TMPCustomSyntaxMemo);
begin
  inherited Create;
  fRichMemo := Owner;
  FileName := UNTITLEDFN + IntToStr(GlobalUntitledIndex) + '.txt';
  Inc(GlobalUntitledIndex);

{$IFDEF SYNDEBUG}
  fRichMemo.Log('Strings.Create');
{$ENDIF}
end;

// Clear() Clears the content, removing key objects
procedure TMPSynMemoStrings.Clear;
var
  i: Integer;
  Da: Boolean;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Strings.Clear {');
  { } {$ENDIF}
  BeginUpdate;
  // Save the current mode and set direct text access mode
  Da := fDirectAccess;
  fDirectAccess := True;
  // Clear all lines
  for i := Count - 1 downto 0 do
    Objects[i].Free;
  inherited Clear;
  fRichMemo.Sections.Scan;
  fRichMemo.Reset;
  // Restore the mode
  fDirectAccess := Da;
  fState := fState + [ssNeedReparseAll, ssNeedReIndex];
  SetModified(True);
  EndUpdate;
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('} Strings.Clear');
  { } {$ENDIF}
  fRichMemo.Change([ciText, ciSelection, ciSections, ciUndoStack]);
  fRichMemo.NeedRedrawAll;
end;

// Converts an offset from the file start into a line and char in it
function TMPSynMemoStrings.PositionToRC(Value: Integer): TPoint;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if Value < Length(Get(i)) + 2 then
      begin
        Result := Point(Value, i);
        Exit;
      end
    else
      dec(Value, Length(Get(i)) + 2);
  Result.Y := Count - 1;
  Result.X := Length(Get(Result.Y));
end;

// Converts a char in the given line into its offset from the text start
function TMPSynMemoStrings.RCToPosition(Col, Row: Integer): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Row - 1 do
    Inc(Result, Length(Get(i)) + 2);
  Inc(Result, Col);
end;

// Sets the content of the given line
procedure TMPSynMemoStrings.Put(Index: Integer; const s: string);
begin
  if fDirectAccess then
    inherited Put(Index, s)
  else
    begin
      BeginUpdate;
      // Change the line
      inherited Put(Index, s);
      // Mark the line as changed
      Parser[Index].NeedReparse := True;
      Include(fState, ssTextChanged);
      // It must be repainted, if visible of course,
      // but this line is commented out, since this will be done
      // implicitly during reparsing
      { fRichMemo.NeedRedraw(Index); }
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.LogFmt('Strings.Put(%d, "%s")', [Index, s]);
      { } {$ENDIF}
      EndUpdate;
    end;
end;

function TMPSynMemoStrings.Add(const s: string): Integer;
begin
  Result := Count;
  Insert(Result, s)

end;

// Inserts a line after the given one
procedure TMPSynMemoStrings.Insert(Index: Integer; const s: string);
begin
  if fDirectAccess then
    begin
      // inherited InsertItem(Index, s, TMPSyntaxParser.Create)
      inherited Insert(Index, s);
      Objects[Index] := TMPSyntaxParser.Create
    end
  else
    begin
      BeginUpdate;
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.LogFmt('Strings.Insert(%d, "%s") {', [Index, s]);
      { } {$ENDIF}
      // Insert the line
      // inherited InsertItem(Index, s, TMPSyntaxParser.Create);
      inherited Insert(Index, s);
      Objects[Index] := TMPSyntaxParser.Create;

      // Mark the line as changed
      Parser[Index].NeedReparse := True;
      Include(fState, ssTextChanged);
      // Adjust sections, unless this is an undo of course
      if not(ssUndoProcess in fState) then
        fRichMemo.Sections.InsertRow(Index);
      { TODO : Not quite right.. Only lines below this one need repainting }
      // When adding a line ALWAYS repaint the WHOLE text
      fRichMemo.NeedReDrawLE(Index);
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.Log('} Strings.Insert');
      { } {$ENDIF}
      EndUpdate;
    end;
end;

// Deletes the given line
procedure TMPSynMemoStrings.Delete(Index: Integer);
begin
  if DirectAccess then
    inherited Delete(Index)
  else
    begin
      BeginUpdate;
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.LogFmt('Strings.Delete(%d) {', [Index]);
      { } {$ENDIF}
      // Adjust sections, unless this is an undo
      if not(ssUndoProcess in fState) then
        fRichMemo.Sections.DeleteRow(Index);
      // Free the StringParser of this line
      if Assigned(Objects[Index]) then
        Objects[Index].Free;
      { FreeParser(TMPSyntaxParser(Objects[Index])); }
      // Delete the line
      inherited Delete(Index);
      // The line taking its place may depend on the deleted one
      if Index < Count then
        Parser[Index].NeedReparse := True;
      Include(fState, ssTextChanged);
      { TODO : Not quite right.. Only lines below this one need repainting }
      // When deleting a line ALWAYS repaint the WHOLE text
      if Index < Count then
        fRichMemo.NeedReDrawLE(Index);
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.Log('} Strings.Delete');
      { } {$ENDIF}
      EndUpdate;
    end;
end;

// Sets the modified flag - STUB
procedure TMPSynMemoStrings.Changed;
begin
end;

// SetUpdateState() Sets the lock flag
procedure TMPSynMemoStrings.SetUpdateState(Updating: Boolean);
begin
  inherited;
  if Updating then
    begin
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.Log('BeginUpdate {');
      { } {$ENDIF}
      fRichMemo.HideCaret;
      fState := fState - [ssTextChanged, ssSectionsChanged, ssNeedReIndex, ssNeedReparseAll];
      fRichMemo.Change([]);

    end
  else
    begin
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.Log('} EndUpdate');
      { } {$ENDIF}
      // If lines were changed, set the modified state
      if fState * [ssTextChanged, ssSectionsChanged] <> [] then
        SetModified(True);

      // If needed, re-adjust line indexes
      if ssNeedReIndex in fState then
        fRichMemo.Sections.ReIndex;

      // Scan the lines. Parse lines that
      // changed or depend on changed ones, skipping empty ones;
      // Repaint changed lines
      if fState * [ssTextChanged, ssNeedReparseAll] <> [] then
        Parse(ssNeedReparseAll in fState, True);

      // Repaint lines not yet repainted
      // And reposition the cursor
      fRichMemo.ReDraw;

      // Update ScrollBars
      if not(csDesigning in fRichMemo.ComponentState) then
        fRichMemo.UpdateScrollBars;
    end;
end;

// Brute-force recalculation of all lines (EntireText is True) or only changed ones
// If (NeedRepaint is True) - changed lines are repainted
procedure TMPSynMemoStrings.Parse(const EntireText: Boolean; const NeedRepaint: Boolean = False);
var
  Row: Integer;
  NeedNext: Boolean;
  Sp: TMPSyntaxParser;
begin
  // Scan the lines. Parse lines that
  // changed or depend on changed ones, skipping empty ones;
  NeedNext := False;
  Row := 0;
  while Row < Count do
    begin
      Sp := Parser[Row];
      if EntireText or Sp.NeedReparse then
        begin
          NeedNext := Self.ParseLine(Row, not EntireText);
          if NeedRepaint then
            fRichMemo.NeedRedraw(Row);
        end
      else if NeedNext and (Sp.Count <> 0) then
        begin
          NeedNext := Self.ParseLine(Row, True);
          if NeedRepaint then
            fRichMemo.NeedRedraw(Row);
        end;
      Inc(Row);
    end;
  fState := fState - [ssTextChanged, ssNeedReparseAll];
end;

// Parse() Calculates the line key
// !! Returns True if the next line needs its key recalculated
// (when the multiline comment flags at the end of this line and the start of the next one differ)
function TMPSynMemoStrings.ParseLine(const Index: Integer; const TestNextLine: Boolean): Boolean;
var
  i: Integer;
  Key: TToken;
begin
  Result := False;
  // Guard - for the case of deleting the last line
  if Index >= Count then
    Exit;
  Key := tokText;

  // Look at the previous non-empty line hoping
  // that the current line is part of a multiline comment
  for i := Index - 1 downto 0 do
    with Parser[i] do
      if Count > 0 then
        begin
          if LastToken in [tokMLCommentBeg, tokELCommentBeg, tokMLCompDirBeg] then
            Key := LastToken;
          Break;
        end;

  // Line parsing
  {$IFDEF SYNDEBUG}
  fRichMemo.LogFmt('Strings.Parse %d', [Index]);
  {$ENDIF}
  Key := Parser[Index].Parse(Get(Index), Index, Key, fRichMemo.fParseAttributes);

  // If needed (TestNextLine = True),
  // look at the non-empty line below in order
  // to find out whether it must be re-parsed or not.
  if TestNextLine then
    for i := Index + 1 to Count - 1 do
      with Parser[i] do
        if Count > 0 then
          begin
            Result := ((Key = tokMLCommentBeg) and (FirstToken <> Key)) or
              ((Key = tokELCommentBeg) and (FirstToken <> Key)) or ((Key = tokMLCompDirBeg) and (FirstToken <> Key)) or
              ((FirstToken = tokMLCommentBeg) and (Key <> FirstToken)) or
              ((FirstToken = tokELCommentBeg) and (Key <> FirstToken)) or
              ((FirstToken = tokMLCompDirBeg) and (Key <> FirstToken));
            Break;
          end;

end;

// LoadFromStream() Loads text from a stream
// After loading, processes sections removing markers and performs full reparsing
procedure TMPSynMemoStrings.LoadFromStream(Stream: TStream);
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Strings.LoadFromStream {');
  { } {$ENDIF}
  BeginUpdate;
  { Allow direct line changes }
  fDirectAccess := True;
  try
    inherited LoadFromStream(Stream);
  finally
    fDirectAccess := False;
    // Rescan sections
    fRichMemo.Sections.Scan;
    // Repaint, reindexing and reparsing are required
    fRichMemo.NeedRedrawAll;
    fState := [ssNeedReIndex, ssNeedReparseAll];
    EndUpdate;
  end;

  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('} Strings.LoadFromStream - Ok');
  { } {$ENDIF}
  // Text was thoroughly updated
  fRichMemo.Change([ciText, ciSelection, ciSections, ciUndoStack]);
end;

// SaveToStream() Saves text to a stream.
// Beforehand, if needed, adds section markers
procedure TMPSynMemoStrings.SaveToStream(Stream: TStream);
var
  Sl: TStringList;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Strings.SaveToStream');
  { } {$ENDIF}
  // Create a helper text
  Sl := TStringList.Create;
  // And copy the existing one into it
  Sl.Assign(Self);
  // If the settings specify writing section markers,
  // apply the corresponding correction to the temporary text
  if smoWriteMarkersOnSave in fRichMemo.Options then
    fRichMemo.Sections.FillOutput(Sl);
  try
    // Write the temporary text to the stream
    Sl.SaveToStream(Stream);
  finally
    // Forget it
    Sl.Free;
  end;
  // Text is written - so reset the modified flag
  SetModified(False);
  // Update text info
  fRichMemo.Change([ciText]);
end;

// Loads text from a file, setting the file name
// and content modified flag properties.
procedure TMPSynMemoStrings.LoadFromFile(const NewFileName: string);
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Strings.LoadFromFile(' + NewFileName + ') {');
  { } {$ENDIF}
  inherited;
  // New name.. =)
  FileName := NewFileName;
  fVirtualFileName := False;
  // Reset initial update
  SetModified(False);

  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('} Strings.LoadFromFile - Ok');
  { } {$ENDIF}
end;

// Saves the content to a file with the given name
procedure TMPSynMemoStrings.SaveToFile(const NewFileName: string);
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Strings.SaveToFile(' + NewFileName + ')');
  { } {$ENDIF}
  inherited;
  FileName := NewFileName;
  fVirtualFileName := False;
  SetModified(False);
end;

// New() Creates a new document
procedure TMPSynMemoStrings.New;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Strings.New');
  { } {$ENDIF}
  Clear;
  fRichMemo.Reset;
  FileName := UNTITLEDFN + IntToStr(GlobalUntitledIndex) + '.txt';
  fVirtualFileName := True;
  Inc(GlobalUntitledIndex);
  fState := [];
  fRichMemo.Change([ciText, ciSelection, ciSections, ciUndoStack]);

  // SiO: Create an empty line, otherwise the user has nowhere to type...
  Add('');
  // InsertItem(Count,'',nil);

end;

// IsValidLineIndex() Whether the given line index is valid
function TMPSynMemoStrings.IsValidLineIndex(const Row: Integer): Boolean;
begin
  Result := InRange(Row, 0, Count - 1);
end;

// GetParser() Always returns the parser of the given line
function TMPSynMemoStrings.GetParser(const Row: Integer): TMPSyntaxParser;
begin
  Result := TMPSyntaxParser(Objects[Row]);
end;

// SetFileName() Sets the file name
procedure TMPSynMemoStrings.SetFileName(const Value: string);
var
  F: TCustomForm;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Strings.SetFileName(' + Value + ')');
  { } {$ENDIF}
  fFileName := Value;
  { Show file name in the tab caption }
  if (smoShowFileNameInTabSheet in fRichMemo.fOptions) and
    Assigned(fRichMemo.Parent) and (fRichMemo.Parent is TTabSheet) then
    TTabSheet(fRichMemo.Parent).Caption := ExtractFileName(fFileName);
  { Show file name in the form caption }
  if smoShowFileNameInFormCaption in fRichMemo.fOptions then
    begin
      F := GetParentForm(fRichMemo);
      if F <> nil then
        F.Caption := Application.Title + '-' + fFileName;
    end;
end;

// SetModified() Resets the text modified flag
procedure TMPSynMemoStrings.SetModified(const Value: Boolean);
begin
  if Value <> fModified then
    begin
      fModified := Value;
  {$IFDEF SYNDEBUG}
      fRichMemo.Log('Strings.SetModified ' + BoolToStr(Value));
  {$ENDIF}
      fRichMemo.Change([ciText]);
    end;
end;

{ TMPSMSectionClone }

// Increments the reference count by 1
procedure TMPSMSectionClone.AddRef;
begin
  Inc(fRefCount);
end;

// Decrements the reference count by 1.
// As soon as the count reaches 0, the object is destroyed
procedure TMPSMSectionClone.Release;
begin
  dec(fRefCount);
  if fRefCount <= 0 then
    Free;
end;

// SiO: Make a copy
procedure TMPSMSectionClone.Assign(original: TMPSMSectionClone);
begin
  fParent := original.fParent;
  fRowBeg := original.fRowBeg;
  fRowEnd := original.fRowEnd;
  fLevel := original.fLevel;
  fCollapsed := original.fCollapsed;
end;

// Class TMPSynMemoSection Implementation

// Create() Constructor
constructor TMPSynMemoSection.Create;
begin
  inherited Create(True);
end;

// GetSections() Returns a nested section by index
function TMPSynMemoSection.GetSections(const Idx: Integer): TMPSynMemoSection;
begin
  Assert(InRange(Idx, 0, Count - 1), 'Bad nested section index: ' + IntToStr(Idx));
  Result := TMPSynMemoSection(Items[Idx])
end;

// Sets the new section nesting level
// Recursively changes the level of inner sections
procedure TMPSynMemoSection.SetLevel(const Value: Integer);
var
  i: Integer;
begin
  fLevel := Value;
  for i := 0 to Count - 1 do
    Sections[i].SetLevel(fLevel + 1);
end;

// Class TMPSynMemoManager Implementation

// Create() Section manager constructor
constructor TMPSynMemoSections.Create(Owner: TMPCustomSyntaxMemo);
begin
  inherited Create;
  fRichMemo := Owner;
  fRoot := TMPSMSectionClone.Create;
  fIndexes := TList.Create;
  fRoot.AddRef;
  Scan;
end;

// Destroy() Section manager destructor
destructor TMPSynMemoSections.Destroy;
begin
  fIndexes.Free;
  fRoot.Free;
  inherited;
end;

// Returns the section header type
class function TMPSynMemoSections.DetectSectionMark(const s: string): TSectionMark;
begin
  if s = '' then
    Result := smNone
  else if PDWORD(s)^ = PDWORD(SectionMarks[smExpanded])^ then
    Result := smExpanded
  else if PDWORD(s)^ = PDWORD(SectionMarks[smCollapsed])^ then
    Result := smCollapsed
  else if PDWORD(s)^ = PDWORD(SectionMarks[smEnd])^ then
    Result := smEnd
  else
    Result := smNone;
end;

// Returns the header type of the section the line belongs to
function TMPSynMemoSections.SectionBorder(const Row: Integer): TSectionMark;
begin
  with Section[Row] do
    if Row = RowBeg then
      if Collapsed then
        Result := smCollapsed
      else
        Result := smExpanded
    else if Row = RowEnd then
      Result := smEnd
    else
      Result := smNone;
end;

// Returns the next section after the given one, ignoring visibility and nesting
function TMPSynMemoSections.Next(Sec: TMPSynMemoSection): TMPSynMemoSection;
{ }
  function _next(Sec: TMPSynMemoSection): TMPSynMemoSection;
  var
    N: Integer;
  begin
    if Sec = fRoot then
      Result := nil
    else
      begin
        N := Sec.Parent.IndexOf(Sec);
        if N < Sec.Parent.Count - 1 then
          Result := Sec.Parent.Sections[N + 1]
        else
          Result := _next(Sec.Parent);
      end;
  end;

{ }
begin
  if Sec.Count > 0 then
    Result := TMPSynMemoSection(Sec.First)
  else
    Result := _next(Sec);
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Sections.Next');
{$ENDIF}
end;

// Returns the previous section before the given one, ignoring visibility and nesting
function TMPSynMemoSections.Prev(Sec: TMPSynMemoSection): TMPSynMemoSection;
  function _last(Sec: TMPSynMemoSection): TMPSynMemoSection;
  begin
    Result := Sec;
    if Result.Count > 0 then
      Result := _last(TMPSynMemoSection(Result.Last));
  end;

var
  N: Integer;
begin
  if Sec = fRoot then
    Result := nil
  else
    begin
      N := Sec.Parent.IndexOf(Sec);
      if N > 0 then
        Result := _last(Sec.Parent.Sections[N - 1])
      else if Sec.Parent = fRoot then
        Result := nil
      else
        Result := Sec.Parent;
    end;
  {$IFDEF SYNDEBUG}
  fRichMemo.Log('Sections.Prev');
  {$ENDIF}
end;

// Returns the section the line belongs to
function TMPSynMemoSections.GetSection(const Row: Integer): TMPSynMemoSection;
begin
  Result := fRichMemo.Lines.Parser[Row].Section;
end;

// Sets the section the line belongs to
procedure TMPSynMemoSections.SetSection(const Row: Integer; Value: TMPSynMemoSection);
begin
  fRichMemo.Lines.Parser[Row].Section := Value;
end;

// Returns True if at least the section header is visible
// !!! Works only after line reindexing !!!
function TMPSynMemoSections.Visible(const Sec: TMPSynMemoSection): Boolean;
begin
  if ssNeedReIndex in fRichMemo.Lines.State then
    ReIndex;
  Result := fRichMemo.Lines.Parser[Sec.RowBeg].VisibleIndex >= 0;
end;

// Collapses the given section
// If Recursive = True, collapses all nested sections
procedure TMPSynMemoSections.Collapse(const Row: Integer; const Recursive, SafeSelf: Boolean);
var
  Sec: TMPSynMemoSection;
  { For pure recursion }
  procedure CollapseChildren(Father: TMPSynMemoSection);
  var
    i: Integer;
  begin
    if Recursive then
      for i := Father.Count - 1 downto 0 do
        CollapseChildren(Father[i]);
    if (Father.Level = 0) or ((Father = Sec) and SafeSelf) then
      Exit;
    Father.Collapsed := True;
  end;

begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Sections.Collapse(%d)', [Row]);
  { } {$ENDIF}
  // Sections must be prepared
  with fRichMemo.Lines do
    begin
      if ssNeedReIndex in State then
        ReIndex;
      BeginUpdate;
      Sec := Section[Row];
      CollapseChildren(Sec);
      State := State + [ssNeedReIndex];
      fRichMemo.NeedRedrawAll;
      EndUpdate;
    end;
  fRichMemo.Change([ciSections]);
end;

// Expands the given section
// If Recursive = True, expands all nested sections
// If ParentRecursive = True, expands all parents
procedure TMPSynMemoSections.Expand(const Row: Integer; const Recursive, ParentRecursive: Boolean);
  procedure ExpandChildren(Father: TMPSynMemoSection);
  var
    i: Integer;
  begin
    Father.Collapsed := False;
    if Recursive then
      for i := Father.Count - 1 downto 0 do
        ExpandChildren(Father[i]);
  end;

var
  Sec: TMPSynMemoSection;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Sections.Expand(%d)', [Row]);
  { } {$ENDIF}
  // Sections must be prepared
  if ssNeedReIndex in fRichMemo.Lines.State then
    ReIndex;
  with fRichMemo.fLines do
    begin
      BeginUpdate;
      Sec := Self.Section[Row];
      ExpandChildren(Sec);
      if ParentRecursive then
        while Sec.Level > 1 do
          begin
            Sec := Sec.Parent;
            Sec.Collapsed := False;
          end;
      State := State + [ssNeedReIndex];
      fRichMemo.NeedRedrawAll;
      EndUpdate;
    end;
  fRichMemo.Change([ciSections]);
end;

// Breaks up a section.
// If Recursive = True, break up all nested sections
procedure TMPSynMemoSections.Explode(const Row: Integer; const Recursive: Boolean);
{ Recurse }
  procedure ExplodeChildren(Father: TMPSynMemoSection);
  var
    i, N: Integer;
    Child: TMPSynMemoSection;
  begin
    if Father.Level > 0 then
      begin
        N := Father.Parent.IndexOf(Father);
        for i := Father.Count - 1 downto 0 do
          begin
            // If this section has nested sections,
            // they now belong to the parent too
            Child := Father[i];
            Child.Level := Child.Level - 1;
            Child.Parent := Father.Parent;
            Father.Parent.Insert(N + 1, Father.Extract(Child));
            if Recursive then
              ExplodeChildren(Child);
          end;
        // If the line belonged to the parent section before,
        // it now belongs to the parent of the destroyed section
        for i := Father.RowBeg to Father.RowEnd do
          with fRichMemo.Lines.Parser[i] do
            if Section = Father then
              Section := Father.Parent;
        // Delete the destroyed section
        Father.Parent.Delete(N);
      end;
  end;

{ }
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Sections.Explode(%d)', [Row]);
  { } {$ENDIF}
  // Sections must be prepared
  if ssNeedReIndex in fRichMemo.Lines.State then
    ReIndex;
  { TODO : Sort this out - something is wrong here.. }
  MakeUnique;
  with fRichMemo.Lines do
    begin
      BeginUpdate;
      ExplodeChildren(Section[Row]);
      State := State + [ssSectionsChanged, ssNeedReIndex];
      fRichMemo.NeedRedrawAll;
      SetModified(True);
      EndUpdate;
    end;
  fRichMemo.Change([ciText, ciSelection, ciSections]);
end;

{ Creates a new section enclosing any existing ones }
function TMPSynMemoSections.New(const Row1, Row2: Integer; const IsCollapsed: Boolean = False): TMPSynMemoSection;
var
  i: Integer;
  Father, iSec: TMPSynMemoSection;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Sections.New(%d, %d)', [Row1, Row2]);
  { } {$ENDIF}
  // Sections must be prepared
  if ssNeedReIndex in fRichMemo.Lines.State then
    ReIndex;
  { TODO : Sort this out - something is wrong here.. }
  MakeUnique;

  // If one line belongs to section "A" and the other line
  // belongs to its parent ("^A") but is not its boundary,
  // first break up the existing section ("A"->(^A"),
  // and then create it again - either with a new size
  // or with a new location
  if ((Section[Row2] = Section[Row1].Parent) and (SectionBorder(Row2) = smNone))
    or ((Section[Row1] = Section[Row2].Parent) and (SectionBorder(Row1) = smNone)) then
    Explode(Row1, False);

  // If after all this the input parameters are still invalid,
  // set the result to nil and exit the procedure
  if (Section[Row1] <> Section[Row2]) or (SectionBorder(Row1) <> smNone) or (SectionBorder(Row2) <> smNone) then
    begin
      Result := nil;
      Exit;
    end;

  // Batch changes
  fRichMemo.Lines.BeginUpdate;

  // Future parent of the new section
  Father := Section[Row1];

  // Create the new section
  Result := TMPSynMemoSection.Create;
  Result.Parent := Father;
  Result.RowBeg := Row1;
  Result.RowEnd := Row2;
  Result.Level := Father.Level + 1;
  Result.Collapsed := IsCollapsed;

  // Associate the section with the new lines
  for i := Row1 to Row2 do
    begin
      iSec := Section[i];
      // If the line belonged to the parent section before,
      // it now belongs to the created child section
      // ( happens a lot ;)
      if iSec = Father then
        Section[i] := Result
      else
        // If the selected range contains nested sections,
        // they now belong to the child too and have much
        // lower significance ;))
        if (i = iSec.RowBeg) and (iSec.Parent = Father) then
          begin
            iSec.Level := Result.Level + 1;
            iSec.Parent := Result;
            Result.Add(Father.Extract(iSec));
          end;
    end;

  // Insert the new section among the old one's children
  i := Father.Count;
  while (i > 0) and (Father[i - 1].RowBeg > Row1) do
    dec(i);
  Father.Insert(i, Result);

  // Commit the changes
  with fRichMemo.Lines do
    begin
      State := State + [ssSectionsChanged, ssNeedReIndex];
      fRichMemo.NeedRedrawAll;
      SetModified(True);
      EndUpdate;
    end;

  // Refresh
  fRichMemo.Change([ciText, ciSelection, ciSections]);
end;

// Deletes a line - section indexes are recalculated
// !!! Only for use inside batch changes !!!
procedure TMPSynMemoSections.DeleteRow(const Row: Integer);
{ Recurse }
  procedure UpdateIndexes(Sec: TMPSynMemoSection);
  var
    i: Integer;
  begin
    if Sec.RowBeg > Row then
      dec(Sec.fRowBeg);
    if Sec.RowEnd > Row then
      begin
        dec(Sec.fRowEnd);
        { Recursively recalculate indexes of nested sections }
        for i := 0 to Sec.Count - 1 do
          UpdateIndexes(Sec.Sections[i]);
      end;
  end;

{ }
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Sections.DeleteRow(%d)', [Row]);
  { } {$ENDIF}
  { TODO : Sort this out - something is wrong here.. }
  MakeUnique;

  // If the deleted line is a section boundary, the section is destroyed.
  with fRichMemo do
    if Sections.SectionBorder(Row) <> smNone then
      Explode(Row, False);

  // .. and only then the indexes are adjusted
  UpdateIndexes(fRoot);
  with fRichMemo.Lines do
    State := State + [ssSectionsChanged, ssNeedReIndex];
end;

// A line is added - section indexes are recalculated
// !!! Only for use inside batch changes !!!
procedure TMPSynMemoSections.InsertRow(const Row: Integer);
var
  ParentSec: TMPSynMemoSection;
  { }
  procedure UpdateIndexes(Sec: TMPSynMemoSection);
  var
    i: Integer;
  begin
    if Row <= Sec.RowBeg then
      Inc(Sec.fRowBeg);
    if Row <= Sec.RowEnd then
      begin
        Inc(Sec.fRowEnd);
        { Check whether the line was added to this section }
        if InRange(Row, Sec.RowBeg, Sec.RowEnd) and (Sec.Level > ParentSec.Level) then
          ParentSec := Sec;
        { Recursively recalculate indexes of nested sections }
        for i := 0 to Sec.Count - 1 do
          UpdateIndexes(Sec.Sections[i]);
      end;
  end;

{ }
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Sections.InsertRow(%d)', [Row]);
  { } {$ENDIF}
  { TODO : Sort this out - something is wrong here.. }
  MakeUnique;
  ParentSec := fRoot;
  UpdateIndexes(fRoot);
  Section[Row] := ParentSec;
  with fRichMemo.Lines do
    State := State + [ssSectionsChanged, ssNeedReIndex];
end;

// FillOutput() Fills the output text depending on the section manager options
procedure TMPSynMemoSections.FillOutput(const Sl: TStringList);
const
  pm: array [Boolean] of string[4] = ('{<+}', '{<-}');
  { }
  procedure MarkSection(Sec: TMPSynMemoSection);
  var
    i: Integer;
  begin
    if Sec <> fRoot then
      begin
        Sl[Sec.RowBeg] := pm[Sec.Collapsed] + Sl[Sec.RowBeg];
        Sl[Sec.RowEnd] := '{>>}' + Sl[Sec.RowEnd];
      end;
    for i := 0 to Sec.Count - 1 do
      MarkSection(Sec.Sections[i]);
  end;

{ }
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Sections.FillOutput');
  { } {$ENDIF}
  MarkSection(fRoot);
end;

{ TODO : THIS IS WHAT WE WILL SORT OUT - tomorrow morning }
// The current section tree becomes unique
procedure TMPSynMemoSections.MakeUnique;
{ Creates a copy of the section - recurse }
  function Clone(const Father, Sec: TMPSynMemoSection): TMPSynMemoSection;
  var
    i: Integer;
  begin
    Result := TMPSynMemoSection.Create;
    Result.fParent := Father;
    Result.fRowBeg := Sec.fRowBeg;
    Result.fRowEnd := Sec.fRowEnd;
    Result.fLevel := Sec.fLevel;
    Result.fCollapsed := Sec.fCollapsed;
    for i := 0 to Sec.Count - 1 do
      Result.Add(Clone(Result, Sec.Sections[i]));
  end;

{ }
var
  NewRoot: TMPSMSectionClone;
  i: Integer;
begin
  if ssUndoProcess in fRichMemo.Lines.State then
    Exit;
  if fRoot.fRefCount > 1 then
    begin
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.LogFmt('Sections.MakeUnique %d->%d', [fRoot.fRefCount, fRoot.fRefCount + 1]);
      { } {$ENDIF}
      { Create a real /with its own memory/ clone of the section tree }
      NewRoot := TMPSMSectionClone.Create;
      NewRoot.fParent := nil;
      NewRoot.fRowBeg := fRoot.fRowBeg;
      NewRoot.fRowEnd := fRoot.fRowEnd;
      NewRoot.fLevel := 0;
      NewRoot.fCollapsed := False;
      for i := 0 to fRoot.Count - 1 do
        NewRoot.Add(Clone(NewRoot, fRoot.Sections[i]));
      SetRoot(NewRoot);
    end
  else
    begin

      { Create a virtual /reference-counted/ clone of the section tree }
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.Log('Sections.MakeUnique VIRTUAL');
      { } {$ENDIF}
    end;
end;

// Returns section data as multiline text
function TMPSynMemoSections.AsText: string;
var
  Sl: TStringList;
  procedure SecAsString(Sec: TMPSynMemoSection);
  var
    i: Integer;
  begin
    Sl.Append(Format('%s%d..%d %s', [StringOfChar(' ', Sec.Level * 4),
      Sec.RowBeg, Sec.RowEnd, IfThenStr(Sec.Collapsed, 'Collapsed', '')]));
    for i := 0 to Sec.Count - 1 do
      SecAsString(Sec.Sections[i]);
  end;

begin
  Sl := TStringList.Create;
  Sl.Append('Sections');
  SecAsString(fRoot);
  Sl.Append('End of sections');
  Result := Sl.Text;
  Sl.Free;
end;

// Reindexes the section mapping of lines
procedure TMPSynMemoSections.ReIndex;
var
  Row: Integer;
  { }
  procedure ProcessSection(const Sec: TMPSynMemoSection; ParentOpen: Boolean);
  var
    ChildIndex: Integer;
  begin
    ChildIndex := 0;
    if Sec.Level > fMaxLevel then
      fMaxLevel := Sec.fLevel;
    if ParentOpen and (Sec.fLevel > fMaxExpandLevel) then
      fMaxExpandLevel := Sec.fLevel;
    { TODO -oBuzz :
      Pasting a small text over a large one gives an AV
      Just ignoring it for now. Will sort it out later. }
    if fRichMemo.Lines.Count <= Sec.fRowEnd then
      Sec.fRowEnd := fRichMemo.Lines.Count - 1;
    while Row <= Sec.fRowEnd do
      begin
        if (ChildIndex >= Sec.Count) or (Row < Sec.Sections[ChildIndex].RowBeg) or
          (Row > Sec.Sections[ChildIndex].RowEnd) then
          begin
            with fRichMemo.Lines.Parser[Row] do
              begin
                Section := Sec;
                if ParentOpen and (not Sec.Collapsed or (Row = Sec.RowBeg)) then
                  fVisibleIndex := fIndexes.Add(Pointer(Row))
                else
                  fVisibleIndex := -1;
              end;
            Inc(Row);
          end
        else
          begin
            ProcessSection(Sec.Sections[ChildIndex], ParentOpen and not Sec.Collapsed);
            Inc(ChildIndex);
          end;
      end;
  end;

{ }
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Sections.ReIndex');
  { } {$ENDIF}
  dec(fRoot.fRowEnd);
  fMaxLevel := 0;
  fMaxExpandLevel := 0;
  Row := 0;
  fIndexes.Clear;
  ProcessSection(fRoot, True);
  Inc(fRoot.fRowEnd);
  { Commit the update }
  fRichMemo.Lines.State := fRichMemo.Lines.State - [ssNeedReIndex];
  { Call the support procedure }
  fRichMemo.Change([ciSections]);
end;

// Sets a new section root (it may have been saved in Undo)
procedure TMPSynMemoSections.SetRoot(const Value: TMPSMSectionClone);
begin
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Sections.SetRoot');
{$ENDIF}
  { If the tree does not change, just reindex the lines }
  if fRoot <> Value then
    begin
      fRoot.Release;
      fRoot := Value;
      fRoot.AddRef;
    end;
  { Update the lines }
  ReIndex;
end;

// Reads the whole text and builds the set of sections
procedure TMPSynMemoSections.Scan;
var
  Row, i: Integer;
  ParentSec, Sec: TMPSynMemoSection;
  Stack: TObjectStack;
  Sm: TSectionMark;
begin
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Sections.SCAN');
{$ENDIF}
  { Clear the section root }
  with fRoot do
    begin
      Clear;
      fRowBeg := -1;
      fRowEnd := fRichMemo.fLines.Count;
      fLevel := 0;
      fParent := nil;
      fCollapsed := False;
    end;

  { Create the stack of open sections }
  Stack := TObjectStack.Create;

  { Scan the whole text and build a new section tree }
  Row := 0;
  ParentSec := fRoot;
  repeat
    while Row < fRichMemo.Lines.Count do
      begin
        Sm := TMPSynMemoSections.DetectSectionMark(fRichMemo.Lines[Row]);
        case Sm of
          smExpanded, smCollapsed:
            begin
              { Create a new section }
              Sec := TMPSynMemoSection.Create;
              with Sec do
                begin
                  fRowBeg := Row;
                  fRowEnd := -1;
                  fLevel := ParentSec.fLevel + 1;
                  fParent := ParentSec;
                  fCollapsed := Sm = smCollapsed;
                end;
              { Nest it inside ParentSec }
              ParentSec.Add(Sec);
              { Push it onto the stack }
              Stack.push(Sec);
              { Make it the parent }
              ParentSec := Sec;
              { Every line in the given range will belong to this section }
              fRichMemo.Sections.Section[Row] := ParentSec;
              { Remove the section start marker }
              fRichMemo.Lines[Row] := StuffString(fRichMemo.Lines[Row], 1, SECTION_HEADER_LENGTH, '');
            end;
          smEnd:
            begin
              { Check the stack }
              if Stack.Count = 0 then
                begin
                  // Error: unmatched section close (extra {>>}):
                  // Recovery - insert a line opening a section
                  fRichMemo.fLines.Insert(Row, SectionMarks[smExpanded]);
                  Continue;
                end;
              { Pop the last open section from the stack and close it }
              Sec := TMPSynMemoSection(Stack.pop);
              Sec.fRowEnd := Row;
              { Every line in the given range will belong to this section }
              fRichMemo.Sections.Section[Row] := Sec;
              { Its parent becomes the parent section }
              ParentSec := Sec.fParent;
              { Remove the section end marker }
              fRichMemo.Lines[Row] := StuffString(fRichMemo.Lines[Row], 1, SECTION_HEADER_LENGTH, '');
            end;
          else
            { Every line in the given range will belong to the current section }
            fRichMemo.Sections.Section[Row] := ParentSec;
        end;
        Inc(Row);
      end;

    { Check the stack for open sections }
    if Stack.Count > 0 then
      // Error: missing closing {>>} markers:
      // Recovery - add lines with closing markers
      for i := 0 to Stack.Count - 1 do
        fRichMemo.Lines.Append(SectionMarks[smEnd]);
  until Stack.Count = 0;

  { Free the stack }
  Stack.Free;
end;

{ TMPSynMemoUndoItem }

// Destructor.
destructor TMPSynMemoUndoItem.Destroy;
begin
  // First frees the section tree
  uiSections.Release;
  inherited;
end;

// Class TMPSynMemoRange Implementation

// Create() Constructor
constructor TMPSynMemoRange.Create(Owner: TMPCustomSyntaxMemo);
begin
  inherited Create;
  fRichMemo := Owner;
  fSealing := True;
  fMaxUndoDepth := 100;
  fUndoStack := TObjectList.Create(True);
  fUndoStack.Capacity := 100;
end;

// Destroy() Destructor
destructor TMPSynMemoRange.Destroy;
begin
  fUndoStack.Clear;
  fUndoStack.Free;
  inherited;
end;

// Shifts the selected lines right
procedure TMPSynMemoRange.MakeIndent;
var
  i: Integer;
begin
  fRichMemo.Lines.BeginUpdate;
  for i := StartY to EndY do
    fRichMemo.Lines[i] := '    ' + fRichMemo.Lines[i];
  fRichMemo.Lines.EndUpdate;
end;

// Shifts the selected lines left
procedure TMPSynMemoRange.MakeUnIndent;
var
  i: Integer;
begin
  fRichMemo.Lines.BeginUpdate;
  for i := StartY to EndY do
    if Copy(fRichMemo.Lines[i], 1, 4) = '    ' then
      fRichMemo.Lines[i] := Copy(fRichMemo.Lines[i], 5, Length(fRichMemo.Lines[i]) - 4);
  fRichMemo.Lines.EndUpdate;
end;

// Comment out the selected lines
procedure TMPSynMemoRange.MakeComment(LitILComment: string);
var
  i: Integer;
begin
  if Copy(fRichMemo.Lines[StartY], 1, Length(LitILComment)) <> LitILComment then
    begin
      fRichMemo.Lines.BeginUpdate;
      for i := StartY to EndY do
        if Copy(fRichMemo.Lines[i], 1, Length(LitILComment)) <> LitILComment then
          fRichMemo.Lines[i] := LitILComment + fRichMemo.Lines[i];
      fRichMemo.Lines.EndUpdate;
    end
  else
    begin
      fRichMemo.Lines.BeginUpdate;
      for i := StartY to EndY do
        if Copy(fRichMemo.Lines[i], 1, Length(LitILComment)) = LitILComment then
          fRichMemo.Lines[i] := Copy(fRichMemo.Lines[i], Length(LitILComment) + 1,
            Length(fRichMemo.Lines[i]) - Length(LitILComment));
      fRichMemo.Lines.EndUpdate;
    end;
end;

// Collaps() Collapses the selection to its start
procedure TMPSynMemoRange.Collapse;
var
  yb, ye: Integer;
  e: Boolean;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Range.Collapse');
  { } {$ENDIF}
  // Save the selection start and end lines ..
  yb := fStart.Y;
  ye := fEnd.Y;
  // .. and the empty-selection flag
  e := IsEmpty();
  // Enable sticky mode
  // The selection bounds will then always follow the input position
  fSealing := True;
  fStart := fPos;
  fEnd := fPos;
  // Clean up leftovers - repaint the lines
  // where the selection bounds used to be
  if not e then
    with fRichMemo do
      begin
        Lines.BeginUpdate;
        repeat
          NeedRedraw(yb);
          Inc(yb);
        until yb > ye;
        Lines.EndUpdate;
      end;
  // Confirm the change
  fRichMemo.Change([ciSelection]);
end;

// Enlarge() Grows the selection by Value characters (or lines - if EnlargeLine is True)
procedure TMPSynMemoRange.Enlarge(const Value: Integer; const EnlargeLine: Boolean = False; const VisiblesOnly: Boolean = False);
var
  N, PrevY: Integer;
begin
  fRichMemo.Lines.BeginUpdate;
  fSealing := False;
  if not EnlargeLine then
    begin
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.LogFmt('Range.Enlarge(Cols=%d)', [Value]);
      { } {$ENDIF}
      // Estimate growing/shrinking the selection horizontally
      N := PosX + Value;
      // Limit the selection to the current line (as in Delphi)
      if N < 0 then
        N := -PosX
      else if N > Length(fRichMemo.Lines[PosY]) then
        N := Length(fRichMemo.Lines[PosY]) - PosX
      else
        N := Value;
      // If the limits leave nothing to move - just exit
      if N <> 0 then
        begin
          // Adjust the selection bounds
          if (PosX = StartX) and (PosY = StartY) then
            Inc(fStart.X, N)
          else
            Inc(fEnd.X, N);
          if (StartY = EndY) and (StartX > EndX) then
            Swap(fStart.X, fEnd.X);
          // Move the cursor horizontally, scrolling if needed
          PosX := PosX + N;
          // Repaint the current line
          fRichMemo.NeedRedraw(PosY);
        end
    end
  else
    begin
      { } {$IFDEF SYNDEBUG}
      { } fRichMemo.LogFmt('Range.Enlarge(Rows=%d)', [Value]);
      { } {$ENDIF}
      // Estimate growing/shrinking the selection vertically
      if VisiblesOnly then
        N := fRichMemo.FindVisibleRow(PosY, Value, True)
      else
        N := EnsureRange(PosY + Value, 0, fRichMemo.Lines.Count - 1);

      // If the limits leave nothing to move - just exit
      if N <> PosY then
        begin
          // Remember the start line
          PrevY := PosY;

          // Adjust the selection bounds
          if PointsEqual(fPos, fStart) then
            fStart.Y := N
          else
            fEnd.Y := N;
          if fStart.Y < 0 then
            fStart.Y := 0;
          if StartY > EndY then
            begin
              Swap(fStart.Y, fEnd.Y);
              Swap(fStart.X, fEnd.X);
            end;

          // Move the cursor vertically, scrolling if needed
          PosY := N;

          // Repaint lines from start to end
          for N := Min(PrevY, PosY) to Max(PrevY, PosY) do
            fRichMemo.NeedRedraw(N);
        end;
    end;
  fRichMemo.Lines.EndUpdate;
  fRichMemo.Change([ciSelection]);
end;

// Deletes a character, a line break or the selection contents
procedure TMPSynMemoRange.Delete;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.Log('Range.Delete');
  { } {$ENDIF}
  if not IsEmpty then
    begin
      // fRichMemo.Lines.State := fRichMemo.Lines.State + [ssNeedReparseAll];
      if (StartY < fRichMemo.OffsetY) and (EndY > fRichMemo.OffsetY) then
        fRichMemo.OffsetY := fRichMemo.OffsetY - (EndY - StartY);

      SetTextEx('', ukLetterDeleted)
    end
  else if PosX < Length(fRichMemo.fLines[PosY]) then
    begin
      // no selection; cursor not at end of line - delete a character
      EndX := StartX + 1;
      SetTextEx('', ukLetterDeleted);
    end
  else if PosY < fRichMemo.fLines.Count - 1 then
    begin
      // cursor at end of line - join two lines
      EndX := 0;
      EndY := StartY + 1;
      SetTextEx('', ukLetterDeleted);
    end;
end;

// Collapses the section whose line holds the input position
procedure TMPSynMemoRange.CollapseSection(const Recursive: Boolean);
begin
  with fRichMemo do
    begin
      { } {$IFDEF SYNDEBUG}
      { } Log('Range.CollapseSection');
      { } {$ENDIF}
      // If the cursor is inside the section, move it to the section header
      if Sections.SectionBorder(PosY) in [smNone, smEnd] then
        SetPos(Point(0, Sections.Section[PosY].RowBeg));
      Sections.Collapse(PosY, Recursive, Recursive);
    end;
end;

// Expand the section whose header holds the input position
procedure TMPSynMemoRange.ExpandSection(const Recursive: Boolean);
begin
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Range.ExpandSection');
{$ENDIF}
  fRichMemo.Sections.Expand(PosY, Recursive, False);
end;

// Break up the section
procedure TMPSynMemoRange.ExplodeSection(const Recursive: Boolean);
begin
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Range.ExplodeSection');
{$ENDIF}
  Collapse;
  AddUndo;
  fRichMemo.Sections.Explode(PosY, Recursive);
end;

// CreateSection() Creates a section from line Row1 to line Row2
// If Row2 = -1 (default), a new section Row1..Row1+1 is created
procedure TMPSynMemoRange.CreateSection;
begin
  with fRichMemo do
    begin
      { } {$IFDEF SYNDEBUG}
      { } Log('Range.CreateSection');
      { } {$ENDIF}
      Lines.BeginUpdate;
      // Row1 = Row2
      // Selection is empty or lies on a single text line
      // The cursor can be anywhere in the line
      // THE LINE CANNOT BE A BOUNDARY OF AN EXISTING SECTION
      // An empty line is inserted first
      if (StartY = EndY) and (Sections.SectionBorder(StartY) = smNone) then
        begin
          Collapse;
          // Generate undo as a delete-line command..
          with AddUndo() do
            begin
              uiSelStart := Point(0, StartY + 1);
              uiSelEnd := Point(0, StartY + 2);
              uiSealing := False;
            end;
          // .. for the line we are about to add
          Lines.Insert(StartY + 1, '');
          // Generate the section
          Sections.New(StartY, StartY + 1);
        end
      else
        // Row1 < Row2
        // Selection is not empty; start and end lines belong to
        // the same or different sections and are not their boundaries
        if (StartY <> EndY) and (Sections.SectionBorder(StartY) = smNone) and
          (Sections.SectionBorder(EndY) = smNone) then
          begin
            with AddUndo() do
              begin
                uiSelStart := fPos;
                uiSelEnd := fPos;
                uiSealing := True;
              end;
            Sections.New(fStart.Y, fEnd.Y);
            Collapse;
          end;
      SetPos(Point(0, fStart.Y));
      Lines.EndUpdate;
    end;
end;

// Go to the next (Delta=+1) or previous (Delta=-1) section,
// if possible, of course
procedure TMPSynMemoRange.GotoSection(const GoForward: Boolean);
var
  Sec: TMPSynMemoSection;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Range.GotoSection(%s)', [BoolToStr(GoForward)]);
  { } {$ENDIF}
  // Get the current section (the one the cursor line belongs to)
  Sec := fRichMemo.Sections.Section[PosY];
  // Try to find the previous or next section
  repeat
    if GoForward then
      Sec := fRichMemo.Sections.Next(Sec)
    else
      Sec := fRichMemo.Sections.Prev(Sec);
  until (Sec = nil) or fRichMemo.Sections.Visible(Sec);
  // If a section is found, put the cursor on its header
  if Sec <> nil then
    SetPos(Point(0, Sec.RowBeg));
end;

// Copies text and nested section info to the clipboard
procedure TMPSynMemoRange.CopyToClipboard;
var
  Data: THandle;
  DataPtr: Pointer;
  s: string;
  sa: AnsiString;
begin
  if IsEmpty then
    Exit;
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Range.CopyToClipboard');
{$ENDIF}
  // Just copy the text
  Clipboard.AsText := Self.GetText;
  // Unless disabled, and if the selection bounds are on different lines,
  // save the nested section boundary info
  if not(smoSkipSectionsOnCopy in fRichMemo.Options) and (fStart.Y <> fEnd.Y) then
    begin
      s := GetMarkedText;
      sa := s;

      // Open the clipboard
      OpenClipboard(Application.Handle);
      try
        // Allocate a global memory block
        Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, Length(s) * SizeOf(Char) + SizeOf(Char));
        try
          // Get a pointer to it
          DataPtr := GlobalLock(Data);
          try
  {$IFDEF D11+}
            if s = sa then
              Move(PAnsiChar(sa)^, DataPtr^, Length(s) * SizeOf(AnsiChar) + SizeOf(AnsiChar))
            else
              Move(PChar(s)^, DataPtr^, Length(s) * SizeOf(Char) + SizeOf(Char));
  {$ELSE}
            Move(PChar(s)^, DataPtr^, Length(s) * SizeOf(Char) + SizeOf(Char));
  {$ENDIF}
            SetClipboardData(CF_SYNTAX, Data);
          finally
            GlobalUnlock(Data);
          end;
        except
          GlobalFree(Data);
          raise;
        end;
      finally
        // Close the clipboard
        CloseClipboard;
      end;
    end;
end;

// Inserts lines into the text and, if info is present, text sections
procedure TMPSynMemoRange.PasteFromClipboard;
var
  Data: THandle;
  oldDirAccess: Boolean;
  p: Pointer;
  s: string;
  sa: AnsiString;
begin
  if smoReadOnly in fRichMemo.fOptions then
    Exit;
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Range.PasteFromClipboard');
{$ENDIF}
  // Remember the insert position to adjust sections
  fRichMemo.Lines.BeginUpdate;
  oldDirAccess := fRichMemo.Lines.fDirectAccess;
  fRichMemo.Lines.fDirectAccess := True;
  try
    if not(smoSkipSectionsOnPaste in fRichMemo.Options) and Clipboard.HasFormat(CF_SYNTAX) then
      begin
        // Open the clipboard
        OpenClipboard(Application.Handle);
        Data := GetClipboardData(CF_SYNTAX);
        try
          // Using the received section boundary info of the passed text,
          // create them at the new location
          p := GlobalLock(Data);
          s := PChar(p);
          sa := PAnsiChar(p);
  {$IFDEF D11+}
          if sa = s then
            SetMarkedText(s)
          else
            SetMarkedText(sa);
  {$ELSE}
          SetMarkedText(s);
  {$ENDIF}
        finally
          GlobalUnlock(Data);
          CloseClipboard;
        end;
      end
    else
      // If there is no syntax or it is disabled, insert plain text
      if Clipboard.HasFormat(CF_TEXT) then
        SetTextEx(Clipboard.AsText, ukRangeInserted);
  finally
    fRichMemo.Lines.fDirectAccess := oldDirAccess;
    fRichMemo.Sections.Scan;
    // Repaint, reindex and reparse are needed
    fRichMemo.NeedRedrawAll;
    fRichMemo.Lines.fState := [ssNeedReIndex, ssNeedReparseAll];
  end;
  fRichMemo.Lines.EndUpdate;
  fRichMemo.MakeVisible(PosX, PosY)

end;

// CutToClipboard() Cuts the selected text and puts it on the clipboard
procedure TMPSynMemoRange.CutToClipBoard;
begin
  if not IsEmpty and not(smoReadOnly in fRichMemo.fOptions) then
    begin
  {$IFDEF SYNDEBUG}
      fRichMemo.Log('Range.CutToClipboard');
  {$ENDIF}
      CopyToClipboard;
      Self.SetTextEx('', ukRangeDeleted);
    end;
end;

// IsEmpty() Returns True if the range is empty (input position only)
function TMPSynMemoRange.IsEmpty: Boolean;
begin
  Result := (StartX = EndX) and (StartY = EndY);
end;

// Sets the input point
procedure TMPSynMemoRange.SetPos(const NewPos: TPoint);
begin
  if PointsEqual(fPos, NewPos) then
    Exit;
  with fRichMemo do
    begin
      { } {$IFDEF SYNDEBUG}
      { } LogFmt('Range Col = %d Row = %d', [NewPos.X, NewPos.Y]);
      { } {$ENDIF}
      // SiO: Nothing has changed yet - record an UnDo point
      if (not(ssUndoProcess in Lines.State)) and (Assigned(LastUndoItem)) then
        begin
          if not(LastUndoItem.uiKind = ukCursorMoved) then
            with AddUndo do
              begin
                uiText := '';
                uiCaretPos := fPos;
                uiSelStart := fPos;
                uiSelEnd := fPos;
                uiKind := ukCursorMoved;
              end;
        end;

      Lines.BeginUpdate;
      // Vertically
      // Remove extra trailing spaces after a line has been edited
      // (: If the line still exists :)
      if NewPos.Y <> fPos.Y then
        CutFinalSpaces(fPos.Y);
      // Set the line
      fPos.Y := EnsureRange(NewPos.Y, 0, Lines.Count);
      // If the cursor is past the last text line and that last line is NOT EMPTY,
      // a new line is created - that is basically the whole mechanism of sequential
      // typing ..:)
      if fPos.Y = Lines.Count then
        if (Lines.Count = 0) or ((Lines.Count > 0) and (Lines[Lines.Count - 1] <> '')) then
          begin
            // Lines.InsertItem(Lines.Count,'',nil);
            Lines.Add('');
            SetPos(Point(0, Lines.Count - 1));
          end;
      // Horizontally
      fPos.X := Max(0, NewPos.X);
      // If sticky mode is on, adjust the selection to the current cursor position
      if fSealing then
        begin
          fStart := fPos;
          fEnd := fPos;
        end;
      // The cursor must be visible on screen
      MakeVisible(fPos.X, fPos.Y);
      Lines.EndUpdate;
      Change([ciSelection]);

      if Assigned(fOnSetPosProc) then
        fOnSetPosProc(NewPos);
    end;
end;

// Sets one of the selection values
procedure TMPSynMemoRange.SetRange(const Index, Value: Integer);
begin
  case Index of
    0: SetPos(Point(Value, fPos.Y));
    1: SetPos(Point(fPos.X, Value));
  end;
end;

// Removes trailing spaces in a line
procedure TMPSynMemoRange.CutFinalSpaces(const Row: Integer);
var
  s: string;
  Da: Boolean;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Range.CutFinalSpaces(%d)', [Row]);
  { } {$ENDIF}
  with fRichMemo.Lines do
    if IsValidLineIndex(fPos.Y) then
      begin
        s := TrimRight(Strings[fPos.Y]);
        if Length(s) <> Length(Strings[fPos.Y]) then
          begin
            Da := fDirectAccess;
            fDirectAccess := True;
            Strings[fPos.Y] := s;
            fDirectAccess := Da;
          end;
      end;
end;

// GetText() Returns the selected text
function TMPSynMemoRange.GetText: string;
var
  Row: Integer;
begin
  if IsEmpty then
    Result := ''
  else if fStart.Y = fEnd.Y then
    Result := Copy(fRichMemo.Lines[fStart.Y], fStart.X + 1, fEnd.X - fStart.X)
  else
    begin
      Result := Copy(fRichMemo.Lines[fStart.Y], fStart.X + 1, MaxInt);
      for Row := StartY + 1 to EndY - 1 do
        Result := Result + #13#10 + fRichMemo.Lines[Row];
      Result := Result + #13#10 + Copy(fRichMemo.Lines[fEnd.Y], 1, fEnd.X);
      // LeftStr(fRichMemo.Lines[fEnd.Y], fEnd.X);
    end;
end;

// Returns the selected text with whole-section markers
function TMPSynMemoRange.GetMarkedText: string;
var
  Row, Row1, Row2: Integer;
begin
  with fRichMemo do
    begin
      // Sections are valid only for whole lines
      Row1 := fStart.Y;
      if fStart.X > 0 then
        Inc(Row1);
      Row2 := fEnd.Y;
      if fEnd.X < Length(Lines[fEnd.Y]) then
        dec(Row2);
      // If the first line was partial, copy it without sections
      if Row1 > fStart.Y
      // then Result := Copy(Lines[fStart.Y], fStart.X, MAXINT) + #13#10
      then
        Result := Copy(Lines[fStart.Y], fStart.X + 1, MaxInt) + #13#10
      else
        Result := '';
      // Copy each line with sections
      for Row := Row1 to Row2 do
        with Sections.Section[Row] do
          if (Row = RowBeg) and (RowEnd <= Row2) then
            if Collapsed then
              Result := Result + SectionMarks[smCollapsed] + Lines[Row] + #13#10
            else
              Result := Result + SectionMarks[smExpanded] + Lines[Row] + #13#10
          else if (Row = RowEnd) and (RowBeg >= Row1) then
            Result := Result + SectionMarks[smEnd] + Lines[Row] + #13#10
          else
            Result := Result + Lines[Row] + #13#10;
      // If the last line was partial, copy it without sections
      if Row2 < fEnd.Y then
        Result := Result + Copy(Lines[fEnd.Y], 1, fEnd.X)
      // LeftStr(Lines[fEnd.Y], fEnd.X)
      else
        System.SetLength(Result, Length(Result) - 2);
    end;
end;

// DoUndo() Performs an undo (if there is one)
procedure TMPSynMemoRange.DoUndo;
var
  ui: TMPSynMemoUndoItem;
begin
  if CanUndo then
    begin
      ui := TMPSynMemoUndoItem(fUndoStack.Last);
      with fRichMemo, ui do
        begin
          { } {$IFDEF SYNDEBUG}
          { } Log('Range.DoUndo');
          { } {$ENDIF}
          Lines.BeginUpdate;

          // Old settings
          fStart := uiSelStart;
          fEnd := uiSelEnd;
          fSealing := uiSealing;

          // Restore the previous text
          Lines.State := Lines.State + [ssUndoProcess];
          Self.SetTextEx(uiText, ukNone);
          // Direct call of the actual procedure (no wrapper)
          Lines.State := Lines.State - [ssUndoProcess];

          // Previous section tree
          Sections.EntireSection := uiSections;

          // Old cursor position
          Lines.State := Lines.State + [ssUndoProcess];
          SetPos(uiCaretPos);
          Lines.State := Lines.State - [ssUndoProcess];

          // Delete the used undo entry
          with fUndoStack do
            Delete(Count - 1);

          // Commit the changes
          Change([ciUndoStack]);
          Lines.State := [ssNeedReIndex, ssNeedReparseAll];
          fRichMemo.NeedRedrawAll;
          Lines.EndUpdate;
        end;
    end
end;

// Get the last undo entry
function TMPSynMemoRange.GetLastUndoItem: TMPSynMemoUndoItem;
begin
  Result := nil;
  if fUndoStack.Count > 0 then
    Result := TMPSynMemoUndoItem(fUndoStack.Last);
end;

// Creates an undo point
function TMPSynMemoRange.AddUndo(const UndoText: string = ''): TMPSynMemoUndoItem;
begin
{$IFDEF SYNDEBUG}
  fRichMemo.LogFmt('Range.AddUndo("%.20s")', [UndoText]);
{$ENDIF}
  Result := TMPSynMemoUndoItem.Create;
  Result.uiCaretPos := fPos;
  Result.uiSelStart := fStart;
  Result.uiSelEnd := fEnd;
  Result.uiSealing := fSealing;
  Result.uiKind := ukNone;
  Result.uiSections := fRichMemo.Sections.EntireSection;
  Result.uiText := UndoText;

  // SiO: And who is going to create the objects for us?!!
  // Spent three damn hours hunting the cause of "Runtime error 204"!
  // P.S. Then as long again figuring out why undo stopped working.
  // And all it took was making a _copy_.
  // How it worked before - no idea.

  Result.uiSections := TMPSMSectionClone.Create;
  Result.uiSections.Assign(fRichMemo.Sections.EntireSection);
  Result.uiSections.AddRef;

  { Record the undo entry }
  if fUndoStack.Count >= fMaxUndoDepth then
    fUndoStack.Delete(0);
  fUndoStack.Add(Result);
  fRichMemo.Change([ciUndoStack]);
end;

// Clears the undo stack
procedure TMPSynMemoRange.ClearUndo;
begin
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Range.ClearUndo');
{$ENDIF}
  fUndoStack.Clear;
  Assert(fRichMemo.Sections.EntireSection.RefCount = 1,
    'After ClearUndo fRichMemo.Sections.EntireSection.RefCount must be == 1');
  fRichMemo.Change([ciUndoStack]);
end;

{ TODO : This looks a lot like Sections.Scan ! }
// Inserts text with section markers
procedure TMPSynMemoRange.SetMarkedText(Value: string);
type
  TIntArray = array of Integer;

  { Parses sections in the inserted text and extracts complete ones }
  procedure _Scan(var s: string; var secs: TIntArray);
  const
    signs: array [Boolean] of Integer = (-1, +1);
  var
    Sl: TStringList;
    i: Integer;
    Stack: TStack;
    Sm: TSectionMark;
  begin
    Sl := TStringList.Create;
    Sl.Text := s;
    secs := nil;
    Stack := TStack.Create;
    for i := 0 to Sl.Count - 1 do
      begin
        Sm := TMPSynMemoSections.DetectSectionMark(Sl[i]);
        case Sm of
          smExpanded, smCollapsed:
            begin
              Stack.push(Pointer((i + 1) * signs[Sm = smExpanded]));
              Sl[i] := Copy(Sl[i], SECTION_HEADER_LENGTH + 1, MaxInt);
            end;
          smEnd:
            begin
              if Stack.AtLeast(1) then
                begin
                  System.SetLength(secs, Length(secs) + 2);
                  secs[High(secs) - 1] := Integer(Stack.pop);
                  secs[High(secs)] := i;
                end;
              Sl[i] := Copy(Sl[i], SECTION_HEADER_LENGTH + 1, MaxInt);
            end;
        end;
      end;
    Stack.Free;
    s := Sl.Text;
    Sl.Free;
  end;
{ }

var
  i, Row1, Row2: Integer;
  SafeStart: TPoint;
  SecIndexes: TIntArray;
begin
  with fRichMemo do
    begin
      { } {$IFDEF SYNDEBUG}
      { } LogFmt('Range.SetMarkedText("%.20s")', [Value]);
      { } {$ENDIF}
      Lines.BeginUpdate;

      // Remember the insert start position
      SafeStart := fStart;

      // If the selection start we insert at was not line-aligned,
      // forbid any section marker on this line, to avoid something like Line10: abc{<+}def
      if (SafeStart.X > 0) and (TMPSynMemoSections.DetectSectionMark(Value) <> smNone) then
        System.Delete(Value, 1, SECTION_HEADER_LENGTH);

      // Parse and extract sections
      _Scan(Value, SecIndexes);

      // Insert as text and reindex
      SetTextEx(Value, ukRangeInserted);
      Sections.ReIndex;

      // Try to create sections where they were inserted
      for i := 0 to Length(SecIndexes) shr 1 - 1 do
        begin
          Row1 := SafeStart.Y + SecIndexes[i * 2] * Sign(SecIndexes[i * 2]) - 1;
          Row2 := SafeStart.Y + SecIndexes[i * 2 + 1];
          Sections.New(Row1, Row2, SecIndexes[i * 2] < 0);
        end;

      // Free the temporary section boundary array
      SecIndexes := nil;

      // Reindex lines
      Lines.EndUpdate;
    end;
end;

// SiO: Compatibility wrapper
procedure TMPSynMemoRange.SetText(const Value: string);
var
  ActionKind: TUndoKind;
begin
  ActionKind := ukNone;
  if Length(Value) = 0 then
    ActionKind := ukRangeDeleted;
  if Length(Value) = 1 then
    ActionKind := ukLetterTyped;
  if Length(Value) > 1 then
    ActionKind := ukRangeInserted;
  SetTextEx(Value, ActionKind);
end;

// SetText() The most important one. Sets the selected text.
procedure TMPSynMemoRange.SetTextEx(const Value: string; ActionKind: TUndoKind);
var
  Sl: TStringList;
  N, n1, n2: Integer;
  s: string;
  NewSelEnd: TPoint;
  p, P1: Integer;

  procedure SaveUndo(var Dest: string; fLines: TMPSynMemoStrings);
  var
    N: Integer;
  begin
    p := Length(Dest);
    if fEnd.Y <> fStart.Y then
      begin
        System.SetLength(Dest, 255 * (fEnd.Y - fStart.Y));
        for N := fStart.Y + 1 to fEnd.Y do
          begin
            // Buzz optimized
            if Length(Dest) < p + Length(fLines[N]) + 2 then
              System.SetLength(Dest, Length(Dest) + 255 * (fEnd.Y - N));
            Move(#13#10, Dest[p + 1], 2 * SizeOf(Char));
            Inc(p, 2);
            if Length(fLines[N]) > 0 then
              Move(fLines[N][1], Dest[p + 1], Length(fLines[N]) * SizeOf(Char));
            Inc(p, Length(fLines[N]));

          end;
        System.SetLength(Dest, p);
      end;
    if fEnd.X < Length(fLines[fEnd.Y]) then
      System.SetLength(Dest, p - Length(fLines[fEnd.Y]) + fEnd.X);
  end;

var
  ui: TMPSynMemoUndoItem;
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Range.SetText("%.20s")', [Value]);
  { } {$ENDIF}
  // Adjust the input position
  with fRichMemo do
    begin
      if Lines.Count < PosY + 1 then
        begin
          PosX := PosX + 1;
          PosX := PosX - 1;
        end;

      if IsEmpty and (PosX > Length(Lines[PosY])) then
        Lines[PosY] := Lines[PosY] + StringOfChar(' ', PosX - Length(Lines[PosY]));
    end;

  Sl := TStringList.Create;
  Sl.Text := Value + #13#10;
  with fRichMemo do
    begin
      { Create helper lines }
      n1 := EndY - StartY + 1;
      n2 := Sl.Count;

      // Prepare helper lines
      NewSelEnd.Y := fStart.Y + n2 - 1;
      // Sl[0] := LeftStr(fLines[fStart.Y], fStart.X) + Sl[0];
      Sl[0] := Copy(fLines[fStart.Y], 1, fStart.X) + Sl[0];

      NewSelEnd.X := Length(Sl[n2 - 1]);
      Sl[n2 - 1] := Sl[n2 - 1] + RightStr(fLines[fEnd.Y], Length(fLines[fEnd.Y]) - fEnd.X);

      { Save undo parameters }
      if not(ssUndoProcess in Lines.State) then
        // Check whether it can be grouped with the previous one
        if (not Assigned(LastUndoItem)) or (ActionKind in [ukNone, ukBlockCreated, ukBlockExploded]) or
          (Assigned(LastUndoItem) and ((LastUndoItem.uiKind = ukNone) or
          (LastUndoItem.uiKind <> ActionKind))) or (not(smoGroupUndo in Options))
          then // If not - create a new undo entry
          begin
            ui := AddUndo;
            with ui do
              begin
                uiCaretPos := fPos;
                uiSelEnd := NewSelEnd;
                { Save the undo text }

                uiText := Copy(fLines[fStart.Y], fStart.X + 1, MaxInt);
                SaveUndo(uiText, fLines);

                { for n := fStart.Y + 1 to fEnd.Y do
            uiText := uiText + #13#10 + fLines[n];
            System.SetLength(uiText, Length(uiText) - Length(fLines[fEnd.Y]) + fEnd.X);
          }
                uiKind := ActionKind;
              end
          end
        else // If yes - group them.
          // begin
          with LastUndoItem do
            begin
              // Determine the direction of the change
              if ((NewSelEnd.X >= uiSelEnd.X) and (NewSelEnd.Y = uiSelEnd.Y)) or (NewSelEnd.Y > uiSelEnd.Y) then
                begin // Forward
                  uiSelEnd := NewSelEnd;
                  uiText := uiText + Copy(fLines[fStart.Y], fStart.X + 1, MaxInt);

                  SaveUndo(uiText, fLines);
                  { for n := fStart.Y + 1 to fEnd.Y do
              uiText := uiText + #13#10 + fLines[n];
              System.SetLength(uiText, Length(uiText) - Length(fLines[fEnd.Y]) + fEnd.X); }

                end
              else
                begin // Backward
                  s := uiText;
                  uiSelEnd := NewSelEnd;
                  uiSelStart := fStart;
                  uiText := Copy(fLines[fStart.Y], fStart.X + 1, MaxInt);
                  SaveUndo(uiText, fLines);

                  { for n := fStart.Y + 1 to fEnd.Y do
              uiText := uiText + #13#10 + fLines[n];
              System.SetLength(uiText, Length(uiText) - Length(fLines[fEnd.Y]) + fEnd.X); }
                  uiText := uiText + s;
                end;
              if System.Pos(#13#10, uiText) > 0 then
                uiSealing := False;
            end; (* *)

      { Change the source lines }
      Lines.BeginUpdate;
      // Buzz
      if Lines.Capacity < fStart.Y + n2 - n1 then
        Lines.Capacity := fStart.Y + n2 - n1;
      // p:=fStart.Y+n2-n1;
      p := Lines.Count - 1;
      for N := n2 - n1 downto 1 do
        if fStart.X = 0 then
          Lines.Add('')
        else
          Lines.Add('');
      P1 := Lines.Count - 1;
      for N := p + 1 - fStart.Y downto 1 do
        begin
          if p < 0 then
            Break;
          TMPSyntaxParser(Lines.Objects[p]).fNeedReparse := True;
          Lines.Exchange(p, P1);
          dec(p);
          dec(P1);
        end;
      { for n := n2 - n1 downto 1 do
      if fStart.X = 0
      then Lines.Insert(fStart.Y, '')
      else Lines.Insert(fStart.Y + n1, ''); }

      if n1 > n2 then
        begin
          p := fStart.Y;
          // p1:=Lines.Count-(n1 - n2);
          for N := p + (n1 - n2) to Lines.Count - 1 do
            begin
              Lines.Exchange(N, p);
              Inc(p);
            end;
          for N := n1 - n2 downto 1 do
            Lines.Delete(Lines.Count - 1);
          NeedReDrawLE(fStart.Y);
          // The last line is always empty
        end;
      { for n := n1 - n2 downto 1 do
      Lines.Delete(fStart.Y); }

      for N := 0 to n2 - 1 do
        Lines[fStart.Y + N] := Sl[N];

      // Set the new cursor position
      fEnd := NewSelEnd;
      fStart := fEnd;
      fSealing := True;

      // So that character movement is not recorded
      Lines.State := Lines.State + [ssUndoProcess];
      SetPos(fEnd);
      Lines.State := Lines.State - [ssUndoProcess];

      MakeVisible(fEnd.X, fEnd.Y);
      // Reparse and repaint
      Lines.EndUpdate;
    end;
  Sl.Free;
  fRichMemo.Invalidate
end;

// GetLength() Computes the length of the selected text
function TMPSynMemoRange.GetLength: Integer;
var
  i: Integer;
begin
  Result := EndX - StartX;
  for i := StartY to EndY - 1 do
    Inc(Result, Length(fRichMemo.Lines[i]) + 2);
end;

// GetPosition() Returns the selection start position (0-based)
function TMPSynMemoRange.GetPosition: Integer;
begin
  Result := fRichMemo.Lines.RCToPosition(StartX, StartY);
end;

function TMPSynMemoRange.GetPosInText: Integer;
var
  PosCoord: TPoint;
  i, RowCount: Integer;
begin
  Result := 0;
  PosCoord := Pos;
  if PosCoord.Y + 1 <= fRichMemo.fLines.Count then
    RowCount := PosCoord.Y
  else
    RowCount := fRichMemo.fLines.Count - 1;

  for i := 0 to RowCount do
    if i < RowCount then
      Inc(Result, Length(fRichMemo.fLines[i]) + 2)
    else if Length(fRichMemo.fLines[i]) < PosCoord.X then
      Inc(Result, Length(fRichMemo.fLines[i]) + 2)
    else
      Inc(Result, PosCoord.X);
end;

// SetLength() Sets the selection length
procedure TMPSynMemoRange.SetLength(const Value: Integer);
var
  x0, dy, i, N: Integer;
begin
  with fRichMemo do
    begin
      { } {$IFDEF SYNDEBUG}
      { } LogFmt('Range.SetLength(%d)', [Value]);
      { } {$ENDIF}
      dy := 0;
      x0 := StartX;
      N := Value;
      for i := StartY to fLines.Count - 1 do
        begin
          dec(N, Length(fLines[i]) + 2 - x0);
          x0 := 0;
          if N <= 0 then
            begin
              Enlarge(dy, True);
              Enlarge(Length(fLines[i]) + 2 + N - StartX);
              Exit;
            end
          else
            Inc(dy);
        end;
    end;
end;

// SetPosition() Sets the cursor position as an offset from the start of the text
procedure TMPSynMemoRange.SetPosition(const Value: Integer);
begin
  { } {$IFDEF SYNDEBUG}
  { } fRichMemo.LogFmt('Range.SetPosition(%d)', [Value]);
  { } {$ENDIF}
  Collapse;
  SetPos(fRichMemo.Lines.PositionToRC(Value));
end;

// CanUndo() Returns True if undo is possible
function TMPSynMemoRange.CanUndo: Boolean;
begin
  Result := fUndoStack.Count > 0;
end;

// SetMaxUndoDepth() Sets a new undo stack limit
procedure TMPSynMemoRange.SetMaxUndoDepth(const Value: Integer);
begin
{$IFDEF SYNDEBUG}
  fRichMemo.LogFmt('Range.SetMaxUndoDepth(%d)', [Value]);
{$ENDIF}
  while fMaxUndoDepth > Value do
    begin
      fUndoStack.Delete(0);
      dec(fMaxUndoDepth);
    end;
  fMaxUndoDepth := Value;
end;

// SelectAll() Selects all text
procedure TMPSynMemoRange.SelectAll;
begin
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Range.SelectAll');
{$ENDIF}
  SetPosition(0);
  SetLength(Length(fRichMemo.Lines.Text));
end;

// SelectFromStart() Selects text from the start to the current position
procedure TMPSynMemoRange.SelectFromStart;
var
  L: Integer;
begin
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Range.SelectFromStart');
{$ENDIF}
  L := fRichMemo.Lines.RCToPosition(fPos.X, fPos.Y);
  SetPosition(0);
  SetLength(L);
end;

// SelectToEnd() Selects text from the current position to the end of the document
procedure TMPSynMemoRange.SelectToEnd;
var
  L: Integer;
begin
{$IFDEF SYNDEBUG}
  fRichMemo.Log('Range.SelectToEnd');
{$ENDIF}
  L := fRichMemo.Lines.RCToPosition(fPos.X, fPos.Y);
  SetPosition(L);
  SetLength(Length(fRichMemo.Lines.Text) - L);
end;

// Implementation

{ TBreakPoint }

// Create a breakpoint object instance
constructor TBreakPoint.Create(Owner: TMPBreakPointCollection);
begin
  inherited Create;
  fCollection := Owner;
end;

// Delete the breakpoint object
destructor TBreakPoint.Destroy;
begin
  inherited;
end;

procedure TBreakPoint.fSefKind(kind: TBPKind);
begin
  fKind := kind;
  fCollection.RefreshBP(Self);
end;

{ TMPBreakPointCollection }

// Create the breakpoint collection
constructor TMPBreakPointCollection.Create(Owner: TMPCustomSyntaxMemo);
begin
  inherited Create;
  fRichMemo := Owner;
  fBPList := TStringList.Create;
  fImages := TBitmap.Create;
  fImages.LoadFromResourceName(HInstance, 'BREAKPOINTS');
  fImagesMask := TBitmap.Create;
  fImagesMask.LoadFromResourceName(HInstance, 'BREAKPOINTSMASK');
  fRowOfCurrentBP := -1;
end;

// Delete
destructor TMPBreakPointCollection.Destroy;
var
  i: Integer;
begin
  fOnBeforeBreakPointChangedNotify := nil;
  fImagesMask.Free;
  fImages.Free;
  for i := 0 to fBPList.Count - 1 do
    fBPList.Objects[i].Free;
  fBPList.Free;
  inherited;
end;

// Adds a new breakpoint to the collection. If this line already had one - deletes the old one,
// creates a new one
procedure TMPBreakPointCollection.Add(const Row: Integer;
  const kind: TBPKind = bkEnabled; Condition: string = '';
  PassCount: Cardinal = 0; Group: string = ''; Comment: string = '');
var
  bp: TBreakPoint;
begin
  if (Row = -1) then
    Exit;

  Delete(Row);
  bp := TBreakPoint.Create(Self);
  bp.Condition := Condition;
  bp.PassCount := PassCount;
  bp.Group := Group;
  bp.Comment := Comment;
  bp.kind := kind;

  fBPList.AddObject(IntToStr(Row), TObject(bp));
  fBPList.Sort;
  fRichMemo.NeedRedraw(Row);
  fRowOfCurrentBP := Row;
end;

// Deletes the breakpoint from the given line. If there was none - ignores it...
function TMPBreakPointCollection.Delete(const Row: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  if Row = -1 then
    Exit;
  if fBPList.Find(IntToStr(Row), i) then
    begin
      (fBPList.Objects[i] as TBreakPoint).Free;
      fBPList.Delete(i);
      Result := True;
    end;
  fRichMemo.NeedRedraw(Row);
end;

// Returns whether there is a breakpoint on the given line.
// In bmNeedPosibility mode bpPosible does not count as a breakpoint
function TMPBreakPointCollection.fGetIsBreakPoint(const LineIndex: Integer): Boolean;
var
  kind: TBPKind;
begin
  Result := False;
  case fMode of
    bmFreeMode:
      begin
        Result := Find(LineIndex, kind);
      end;
    bmNeedPosibility:
      begin
        if Find(LineIndex, kind) then
          Result := (kind = bkEnabled) or (kind = bkDisabled);
      end;
  end;
end;

// Sets whether there is a breakpoint on the given line.
// Always sets a bpEnabled breakpoint or deletes it.
// In bmNeedPosibility mode sets it only where bpPosible exists, and on deletion
// restores bpPosible.
// Also fires the OnBeforeBreakPointChanged event, where setting the breakpoint can be
// allowed or denied. If the set breakpoint must be of type
// bpDisabled, deny the setting and set it manually. Left to the editor's programmer
procedure TMPBreakPointCollection.fSetIsBreakPoint(const LineIndex: Integer; bp: Boolean);
var
  kind: TBPKind;
  Action: TBPAction;
  CanChange: Boolean;
begin
  if LineIndex = -1 then
    Exit;
  if bp then
    Action := bpaSet
  else
    Action := bpaDelete;
  CanChange := True;
  if Assigned(fOnBeforeBreakPointChangedNotify) then
    fOnBeforeBreakPointChangedNotify(fRichMemo, LineIndex, Action, CanChange);
  if not CanChange then
    Exit;
  case fMode of
    bmFreeMode:
      begin
        if bp then
          Add(LineIndex, bkEnabled)
        else
          Delete(LineIndex);
      end;
    bmNeedPosibility:
      begin
        if bp then
          begin
            if Find(LineIndex, kind) then
              if kind = bkPosible then
                Add(LineIndex, bkEnabled)
          end
        else
          begin
            if Find(LineIndex, kind) then
              if kind <> bkPosible then
                Add(LineIndex, bkPosible)
          end;
      end
  end;

end;

function TMPBreakPointCollection.fGetIsPosible(const LineIndex: Integer): Boolean;
var
  kind: TBPKind;
begin
  Result := False;
  if Find(LineIndex, kind) then
    Result := (kind = bkPosible);
end;

procedure TMPBreakPointCollection.fSetIsPosible(const LineIndex: Integer; bp: Boolean);
var
  kind: TBPKind;
begin
  if bp then
    begin
      if not IsBreakPoint[LineIndex] then
        Add(LineIndex, bkPosible);
    end
  else
    begin
      // If there is no breakpoint, there is nothing to delete
      if not(Find(LineIndex, kind)) then
        Exit;
      // If there is, check the set breakpoint; if there is none - delete the possible one
      if BreakPoint[LineIndex].kind = bkPosible then
        Delete(LineIndex);
    end;
end;

// Breakpoint array handling implementation
function TMPBreakPointCollection.fGetBreakPoint(const LineIndex: Integer): TBreakPoint;
var
  i: Integer;
begin
  Result := nil;
  if fBPList.Find(IntToStr(LineIndex), i) then
    Result := TBreakPoint(fBPList.Objects[i]);
end;

// Breakpoint array handling implementation
procedure TMPBreakPointCollection.fSetBreakPoint(const LineIndex: Integer; bp: TBreakPoint);
begin
  Delete(LineIndex);
  Add(LineIndex, bp.kind, bp.Condition, bp.PassCount, bp.Group, bp.Comment);
  fRowOfCurrentBP := LineIndex;
end;

procedure TMPBreakPointCollection.RefreshBP(Sender: TBreakPoint);
var
  i, Row: Integer;
begin
  i := fBPList.IndexOfObject(TObject(Sender));
  if i >= 0 then
    begin
      Row := StrToInt(fBPList.Strings[i]);
      fRowOfCurrentBP := Row;
      fRichMemo.NeedRedraw(Row);
    end;
end;

// Drawing breakpoints on the gutter.
// Two-pass drawing allows a "transparent" icon edge. (masking)
procedure TMPBreakPointCollection.PaintAt(const ACanvas: TCanvas; const X, Y: Integer; const kind: TBPKind);
const
  BOOKMARK_GLYPH_SIZE = 11;
begin
  BitBlt(ACanvas.Handle, X, Y, BOOKMARK_GLYPH_SIZE, BOOKMARK_GLYPH_SIZE,
    fImagesMask.Canvas.Handle, Byte(kind) * BOOKMARK_GLYPH_SIZE, 0, SRCAND); { }
  BitBlt(ACanvas.Handle, X, Y, BOOKMARK_GLYPH_SIZE, BOOKMARK_GLYPH_SIZE,
    fImages.Canvas.Handle, Byte(kind) * BOOKMARK_GLYPH_SIZE, 0, SRCPAINT); { }
end;

// Look up a breakpoint on the given line.
// If found - returns TRUE and the breakpoint type
// If not found - the type is ignored
function TMPBreakPointCollection.Find(const Row: Integer; var kind: TBPKind): Boolean;
var
  i: Integer;
begin
  Result := False;
  if fBPList.Find(IntToStr(Row), i) then
    begin
      kind := (fBPList.Objects[i] as TBreakPoint).kind;
      Result := True;
    end;
end;

// Class TMPCustomSyntaxMemo methods implementation

// Create() Constructor
constructor TMPCustomSyntaxMemo.Create(AOwner: TComponent);
var
  F: TFont;
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  fLines := TMPSynMemoStrings.Create(Self);
  fRange := TMPSynMemoRange.Create(Self);
  fSections := TMPSynMemoSections.Create(Self);
  fParseAttributes := TMPSyntaxAttributes.Create(Self);
  fBookMarks := TMPBookmarkManager.Create(Self);
  fBreakPoints := TMPBreakPointCollection.Create(Self);
  FCurParser := TMPSyntaxParser.Create;
  fBuffer := TBitmap.Create;
  Width := 249;
  Height := 145;
  // Color           := clWindow;
  Color := clWhite;
  Cursor := crIBeam;
  fSelWord := Point(-1, -1);
  fDefBackColor := clWindow;
  fDefForeColor := clBlack;

  fBPEnabledBackColor := clRed;
  fBPEnabledForeColor := clWhite;
  fBPDisabledBackColor := clMaroon;
  fBPDisabledForeColor := clWhite;
  fDebugBackColor := clNavy;
  fDebugForeColor := clWhite;
  fSelectedWordColor := $000080FF;

  fSelColor := clSkyBlue;
  fGutterWidth := 32;
  fInsertMode := True;
  fOptions := [smoAutoGutterWidth, smoShowCursorPos, smoShowPageScroll, smoPanning, smoShowLineNumberToGutter];
  fStepDebugLine := -1;

  fRange.fOnSetPosProc := OnChangePos;

  fVScroll := TScrollBar.Create(Self);
  with fVScroll do
    begin
      Parent := Self;
      kind := sbVertical;
      Ctl3D := True;
      OnChange := ScrollClick;
      OnEnter := ScrollEnter;
    end;

  fHScroll := TScrollBar.Create(Self);
  with fHScroll do
    begin
      Parent := Self;
      kind := sbHorizontal;
      Ctl3D := True;
      Visible := True;
      OnChange := ScrollClick;
      OnEnter := ScrollEnter;
    end;

  fNavButton := TPanel.Create(Self);
  with fNavButton do
    begin
      Parent := Self;
      Width := fVScroll.Width;
      Height := fHScroll.Height;
      Caption := ''; // '...';
      Visible := True;
      BevelInner := bvNone;
      BevelOuter := bvNone;
    end;

  CreateDestroyCursorPos;
  CreateDestroyPageUpDown;

  // Default syntax display settings
  F := TFont.Create;
  F.Name := 'Arial';
  F.Size := 9;
  F.Style := [];
  F.Color := clBlack;
  Font.Assign(F);
  F.Free;
  // default syntax settings
  TabStop := True;
  Font.OnChange := FontChange;
  fSectionIndent := 16;

  FProposalForm := TMPSyntaxCompletionProposalForm.Create(Self);
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 100;
  FTimer.OnTimer := DoOnTimer;

end;

// Creation/deletion of the extra PageUpDown control
// Created or deleted depending on Options
// Called when Options changes
procedure TMPCustomSyntaxMemo.CreateDestroyPageUpDown;
begin
  if (smoShowPageScroll in fOptions) then
    begin
      if not Assigned(fPageUpDown) then
        begin
          fPageUpDown := TScrollBar.Create(Self);
          with fPageUpDown do
            begin
              Parent := Self;
              kind := sbVertical;
              Width := fVScroll.Width;
              Height := Width * 2;
              Visible := True;
              Max := 1;
              Min := -1;
              Position := 0;
              Enabled := fVScroll.Enabled;
              OnChange := PageUpDownOnClick;
              OnEnter := ScrollEnter;
            end;
        end;
    end
  else
    begin
      if fPageUpDown <> nil then
        begin
          fPageUpDown.Free;
          fPageUpDown := nil;
        end;
    end;
end;

// Creation/deletion of the extra CursorPos control
// Created or deleted depending on Options
// Called when Options changes
procedure TMPCustomSyntaxMemo.CreateDestroyCursorPos;
begin
  if (smoShowCursorPos in fOptions) then
    begin
      if not Assigned(fPosInfo) then
        begin
          fPosInfo := TEdit.Create(Self);
          with fPosInfo do
            begin
              Parent := Self;
              Visible := True;
              ReadOnly := True;
              Left := 0;
              Width := 64;
              Text := '1: 1';
            end;
        end;
    end
  else
    begin
      if fPosInfo <> nil then
        begin
          fPosInfo.Free;
          fPosInfo := nil;
        end;
    end;
end;

// Destroy() Destructor
destructor TMPCustomSyntaxMemo.Destroy;
begin
  // Apparently there is no need to free what has an owner, and these visual controls have
  { if fPosInfo<>nil
    then begin
    fPosInfo.Free;
    end;
    if fPageUpDown<>nil
    then begin
    fPageUpDown.Free;
    end;
    fNavButton.Free;{ }

  FCurParser.Free;
  SetLength(fScreenLines, 0);
  fScreenLines := nil;
  fBreakPoints.Free;
  fBookMarks.Free;
  fBuffer.Free;
  fSections.Free;
  fParseAttributes.Free;
  fRange.Free;
  fLines.Free;

  inherited;
end;

// Set the breakpoint change event
function TMPCustomSyntaxMemo.GetOnBeforeBreakPointChangedNotify;
begin
  Result := fBreakPoints.OnBeforeBreakPointChangedNotify;
end;

function TMPCustomSyntaxMemo.GetPosInText: Integer;
begin
  Result := Range.PosInText
end;

// Get the breakpoint change event
procedure TMPCustomSyntaxMemo.SetOnBeforeBreakPointChangedNotify;
begin
  if Assigned(fBreakPoints) then
    fBreakPoints.OnBeforeBreakPointChangedNotify := OnBeforeBreakPointChangedNotify;
end;

// Set the popup menu
function TMPCustomSyntaxMemo.GetBreakPointsPopupMenu: TPopupMenu;
begin
  Result := fBreakPoints.PopupMenu;
end;

// Get the popup menu
procedure TMPCustomSyntaxMemo.SetBreakPointsPopupMenu(pum: TPopupMenu);
begin
  if Assigned(fBreakPoints) then
    fBreakPoints.PopupMenu := pum;
end;

// Specifies the line to be highlighted as the debug step
procedure TMPCustomSyntaxMemo.SetStepDebugLine(Row: Integer);
var
  OldLine: Integer;
begin
  OldLine := fStepDebugLine;
  fStepDebugLine := Row;
  // Just in case, check whether such a line exists at all
  if not Lines.IsValidLineIndex(Row) then
    Exit;

  // Update the line where the debug line no longer is
  if OldLine <> -1 then
    NeedRedraw(OldLine);

  // Draw the new line
  if fStepDebugLine <> -1 then
    begin
      // If the line is not visible - make it visible!
      if not(IsLineVisible(Row)) then
        OffsetY := Row;
      // Repaint
      NeedRedraw(fStepDebugLine);
    end;
end;

// SetSelColor() Sets the selection color
procedure TMPCustomSyntaxMemo.SetSelColor(const Value: TColor);
begin
  if Value <> fSelColor then
    begin
      fSelColor := Value;
      if not fRange.IsEmpty() then
        Invalidate;
    end;
end;

// ClientLines() Returns the number of text lines that fit in the editor window
function TMPCustomSyntaxMemo.ClientLines: Integer;
begin
  with TextRowRect[-1] do
    { DONE -oMax Proof -c19.03.2006 : Bug. Only a whole number of text lines must be visible }
    Result := (Bottom - Top { + fCharHeight - 1 } ) div fCharHeight;
end;

// WMSIZE() Handles editor resizing
procedure TMPCustomSyntaxMemo.WMSize(var Message: TMessage);
begin
  Invalidate;
  if not fLettersCalculated then
    CalcFontParams;
  CalcScreenParams;
  if not(csDesigning in ComponentState) then
    UpdateScrollBars;
end;

// CanResize() Adjusts the height so that
// the client area is a multiple of the line height
function TMPCustomSyntaxMemo.CanResize(var NewWidth, NewHeight: Integer): Boolean;
begin
  // with TextRowRect[-1] do
  // Dec(NewHeight, (NewHeight - Self.Height + (Bottom - Top)) mod fCharHeight);
  // Inc(NewHeight);
  Result := inherited CanResize(NewWidth, NewHeight);
end;

// Mouse double click - selects the current word
procedure TMPCustomSyntaxMemo.WMLButtonDblClk(var Message: TWMMouse);
var
  Row, WIndex: Integer;
  Sec: TMPSynMemoSection;
  t: TMPSyntaxToken;
begin
  inherited;
  // If Ctrl is held during the double click,
  // the corresponding section is selected
  if (GetKeyState(VK_CONTROL) and $8000) <> 0 then
    begin
      WndOffsetToPixOffset(Point(Message.XPos, Message.YPos), WIndex, Row, True);
      if Lines.IsValidLineIndex(Row) then
        begin
          Sec := Sections.Section[Row];
          Sections.Expand(Row, False, True);
          Range.Collapse;
          { Since the root section starts at -1, correct a possible error }
          Range.Pos := Point(0, EnsureRange(Sec.RowBeg, 0, Lines.Count - 1));
          Range.Enlarge(Sec.RowEnd - Sec.RowBeg + 1, True);
        end
    end
  else
    // Otherwise, select the word under the cursor
    if GetWordAtPos(Message.XPos, Message.YPos, WIndex, Row) then
      if InRange(WIndex, 0, Lines.Parser[Row].Count - 1) then
        begin
          t := Lines.Parser[Row].Tokens[WIndex];
          Range.Collapse;
          Range.Pos := Point(t.stStart, Row);
          Range.Enlarge(t.stLength);
        end;
end;

procedure TMPCustomSyntaxMemo.ScreenPosToTextPos(const ScrX, ScrY: Integer; var DestX, DestY: Integer);
begin
  WndOffsetToPixOffset(Point(ScrX, ScrY), DestX, DestY, False);
  if fLines.IsValidLineIndex(DestY) then
    begin
      DestX := PixOffsetToCharPos(DestX, DestY, nil);
    end
  else
    DestX := DestX div fCharWidths[False][' ']
end;

function TMPCustomSyntaxMemo.TextPosToScreen(const X, Y: Integer): TPoint;
// for drag and drop
begin
  Result.X := CharPosToPixOffset(X, Y);
  Result := PixOffsetToWndOffsetEx(Result.X, Y - fOffsets.Y)
end;

// Recalculate font parameters
// SiO: Split into two
procedure TMPCustomSyntaxMemo.CalcFontParams;
var
  c: AnsiChar;
begin
  fLettersCalculated := True;
  with Canvas do
    begin
      Font.Assign(Self.Font);
      fCharHeight := -Font.Height + 3;
      Font.Style := [];
      for c := Low(fCharWidths[False]) to High(fCharWidths[False]) do
        fCharWidths[False][c] := Byte(TextWidth(c));
      Font.Style := [fsBold];
      for c := Low(fCharWidths[True]) to High(fCharWidths[True]) do
        fCharWidths[True][c] := Byte(TextWidth(c));
    end;

end;

procedure TMPCustomSyntaxMemo.CalcScreenParams;
begin
  with fVScroll do
    begin
      Ctl3D := True;
      Visible := True;
    end;
  fVScroll.Left := Width - fVScroll.Width - 4;
  fVScroll.Top := 0;

  if fPageUpDown <> nil then
    begin
      fVScroll.Height := Height - fHScroll.Height - fPageUpDown.Height - 4;
      fPageUpDown.Top := fVScroll.Height;
      fPageUpDown.Left := fVScroll.Left;
    end
  else
    begin
      fVScroll.Height := Height - fHScroll.Height - 4;
    end;

  with fHScroll do
    begin
      Ctl3D := True;
      Visible := True;
    end;

  if fPosInfo <> nil then
    begin
      fHScroll.Left := fPosInfo.Width;
      fHScroll.Width := Width - fVScroll.Width - fPosInfo.Width - 4;
      fHScroll.Top := Height - fHScroll.Height - 4;
      fPosInfo.Left := 0;
      fPosInfo.Top := fHScroll.Top - 1;
      fPosInfo.Height := fHScroll.Height + 1;
    end
  else
    begin
      fHScroll.Left := 0;
      fHScroll.Width := Width - fVScroll.Width - 4;
      fHScroll.Top := Height - fHScroll.Height - 4;
    end;

  fNavButton.Left := Width - fNavButton.Width - 4;
  fNavButton.Top := Height - fNavButton.Height - 4;

  SetLength(fScreenLines, ClientLines);
  with EntireRowRect[0] do
    begin
      if (Bottom - Top) > 0 then
        fBuffer.Height := Bottom - Top;
      if (Right - Left) > 0 then
        fBuffer.Width := Right - Left;
    end;
end;

// Update the cursor position indicator
procedure TMPCustomSyntaxMemo.OnChangePos(Pos: TPoint);
begin
  if Pos.X < 0 then
    Pos.X := 0;
  if fPosInfo <> nil then
    fPosInfo.Text := IntToStr(Pos.Y + 1) + ': ' + IntToStr(Pos.X + 1);
end;

// Handler for clicking the PageUpDown element
procedure TMPCustomSyntaxMemo.PageUpDownOnClick(Sender: TObject);
begin
  if fPageUpDown.Position <> 0 then
    begin
      OffsetY := FindVisibleRow(OffsetY, fPageUpDown.Position * (ClientLines - 1), True);
      fPageUpDown.Position := 0;
    end;
end;

// Returns the offset from the line start (in pixels)
function TMPCustomSyntaxMemo.CharPosToPixOffset(const Col: Integer; s: string; Sp: TMPSyntaxParser): Integer;
var
  t: TMPSyntaxToken;
  i, j, WordIndex: Integer;
  Bold: Boolean;
begin
  Result := 0;
  WordIndex := 0;
  i := 0;
  while WordIndex < Sp.Count do
    begin
      t := Sp[WordIndex];
      j := Min(Col, t.stStart);
      Inc(Result, (j - i) * fCharWidths[False][' ']);
      i := j;
      if i = Col then
        Break;
      Bold := fsBold in fParseAttributes.FontStyle[t.stToken];
      j := Min(Col, t.stStart + t.stLength);
      if j > Length(s) then
        j := Length(s);
      while i < j do
        begin
          if s[i + 1] <= High(AnsiChar) then
            Inc(Result, fCharWidths[Bold][AnsiChar(s[i + 1])])
          else
            Inc(Result, Canvas.TextWidth(s[i + 1]));

          // fCharWidths[Bold][AnsiChar(s[i+1])])
          Inc(i);
        end;
      if i = Col then
        Break;
      Inc(WordIndex);
    end;
  if i < Col then
    Inc(Result, (Col - i) * fCharWidths[False][' ']);
end;

// Returns the offset from the line start (in pixels)
// for the given character (Col, 0-based) of the given line (Row, base=0)
function TMPCustomSyntaxMemo.CharPosToPixOffset(const Col, Row: Integer): Integer;
begin
  if fLines.IsValidLineIndex(Row) then
    Result := CharPosToPixOffset(Col, fLines[Row], fLines.Parser[Row])
  else
    Result := 0;
end;

// PixOffsetToCharPos() Returns the position (0-based) of the character in line Row
// by its offset from the line start in pixels Pix
// If WordIndex <> nil, it returns the index of the word at this position:
// WordIndex^ > 0, if the position is inside a word
// WordIndex^ < 0, if the position is before this word (word index is negative)
// WordIndex = MAXINT, if the position is after the last word in the line
function TMPCustomSyntaxMemo.PixOffsetToCharPos(const Pix, Row: Integer; const WordIndex: PInteger = nil): Integer;
var
  Sp: TMPSyntaxParser;
  s: string;
  Pos, WIndex: Integer;
  Bold: Boolean;
  t: TMPSyntaxToken;
begin
  Result := 0;
  if not InRange(Row, 0, fLines.Count - 1) then
    Exit;
  Sp := TMPSyntaxParser(fLines.Objects[Row]);
  s := fLines[Row];
  WIndex := 0;
  Pos := 0;
  if Sp <> nil then
    while WIndex < Sp.Count do
      begin
        t := Sp[WIndex];
        Bold := fsBold in fParseAttributes.FontStyle[t.stToken];
        while Result < t.stStart do
          begin
            Inc(Pos, fCharWidths[False][' ']);
            if Pos > Pix then
              begin
                if Assigned(WordIndex) then
                  WordIndex^ := -WIndex;
                Exit;
              end;
            Inc(Result);
          end;
        while (Result < t.stStart + t.stLength) and (Result < Length(s)) do
          begin
            Inc(Pos, fCharWidths[Bold][AnsiChar(s[Result + 1])]);
            if Pos > Pix then
              begin
                if Assigned(WordIndex) then
                  WordIndex^ := WIndex;
                Exit;
              end;
            Inc(Result);
          end;
        Inc(WIndex);
      end;
  if Pos < Pix then
    Inc(Result, (Pix - Pos) div fCharWidths[False][' ']);
  if Assigned(WordIndex) then
    WordIndex^ := MaxInt;
end;

// WMGetDlgCode() Keeps the component from losing focus when control keys are pressed
procedure TMPCustomSyntaxMemo.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS // so focus is not lost on arrow keys}
    or DLGC_WANTALLKEYS // so Enter is still handled}
    or DLGC_WANTTAB or DLGC_WANTCHARS;
end;

// KeyDown() Handles special key presses
procedure TMPCustomSyntaxMemo.KeyDown(var Key: Word; Shift: TShiftState);
var
  xn, yn, X: Integer;
{$IFDEF SYNDEBUG}
  function ShiftAsString(Shift: TShiftState): string;
  begin
    Result := '[';
    if ssShift in Shift then
      Result := Result + ',ssShift';
    if ssAlt in Shift then
      Result := ',ssAlt';
    if ssCtrl in Shift then
      Result := Result + ',ssCtrl';
    if ssLeft in Shift then
      Result := Result + ',ssLeft';
    if ssRight in Shift then
      Result := Result + ',ssRight';
    if ssMiddle in Shift then
      Result := Result + ',ssMiddle';
    if ssDouble in Shift then
      Result := Result + ',ssDouble';
    if Length(Result) > 1 then
      System.Delete(Result, 2, 1);
    Result := Result + ']';
  end;
{$ENDIF}

begin
  inherited;
{$IFDEF SYNDEBUG}
  Log('KeyDown ' + IntToHex(Key, 2) + ' Shift: ' + ShiftAsString(Shift));
{$ENDIF}
  with Range do
    case Key of
      VK_CONTROL:
        if (Shift = [ssCtrl]) and not fHinting then
          begin
            Cursor := crHandPoint;
            Hint := '';
            SelectedWord := Point(-1, -1);
            ShowHint := True;
            fHinting := True;
          end;

      VK_RIGHT:
        begin

          if not(ssShift in Shift) then
            begin
              Collapse;
              if not(ssCtrl in Shift) then
                PosX := PosX + 1
              else if FindNextWord(xn, yn) then
                Pos := Point(xn, yn);
            end
          else if not(ssCtrl in Shift) then
            Enlarge(1)
          else
            begin
              if FindNextWord(xn, yn) then
                begin
                  Enlarge(yn - PosY, True);
                  Enlarge(xn - PosX);
                end;
            end;

          if fInProposalCall then
            begin
              if Length(GetCurrentWord()) = 0 then
                CloseProposal
              else
                begin
                  FProposalForm.ChangeListText;
                  if FProposalForm.FListProp.Items.Count = 0 then
                    CloseProposal;
                end
            end;

        end;

      VK_LEFT:
        begin
          { if fInProposalCall then
            begin
            //             CloseProposal;
            FProposalForm.ChangeListText;
            if FProposalForm.FListProp.Items.Count=0 then
            CloseProposal;

            end; }
          if not(ssShift in Shift) then
            begin
              Collapse;
              if not(ssCtrl in Shift) then
                PosX := PosX - 1
              else if FindPrevWord(xn, yn) then
                Pos := Point(xn, yn);
            end
          else if not(ssCtrl in Shift) then
            Enlarge(-1)
          else
            begin
              if FindPrevWord(xn, yn) then
                begin
                  Enlarge(yn - PosY, True);
                  Enlarge(xn - PosX);
                end;
            end;

          if fInProposalCall then
            begin
              if Length(GetCurrentWord()) = 0 then
                CloseProposal
              else
                begin
                  FProposalForm.ChangeListText;
                  if FProposalForm.FListProp.Items.Count = 0 then
                    CloseProposal;
                end

            end;

        end;
      VK_DOWN:
        if fInProposalCall then
          FProposalForm.Down
        else if not(ssShift in Shift) then
          if not(ssCtrl in Shift) then
            begin
              Collapse;
              X := CharPosToPixOffset(PosX, PosY);
              PosY := FindVisibleRow(PosY, 1, True);
              PosX := PixOffsetToCharPos(X, PosY);
            end
          else
            begin
              OffsetY := FindVisibleRow(OffsetY, 1, True);
              if StartY < OffsetY then
                begin
                  Collapse;
                  PosY := OffsetY;
                end;
            end
        else if not(ssCtrl in Shift) then
          Enlarge(1, True, True)
        else
          GotoSection(True);

      VK_UP:
        if fInProposalCall then
          FProposalForm.Up
        else if not(ssShift in Shift) then
          if not(ssCtrl in Shift) then
            begin
              Collapse;
              X := CharPosToPixOffset(PosX, PosY);
              PosY := FindVisibleRow(PosY, -1, True);
              PosX := PixOffsetToCharPos(X, PosY);
            end
          else
            begin
              OffsetY := FindVisibleRow(OffsetY, -1, True);
              if StartY >= OffsetY + ClientLines then
                begin
                  Collapse;
                  PosY := OffsetY + ClientLines - 1;
                end;
            end
        else if not(ssCtrl in Shift) then
          Enlarge(-1, True, True)
        else
          GotoSection(False);

      VK_HOME:
        if fInProposalCall then
          FProposalForm.ToHome
        else if not(ssShift in Shift) then
          begin
            Collapse;
            if ssCtrl in Shift then
              PosY := 0;
            if (PosX = 0) and (Length(Trim(Lines.Strings[PosY])) > 0) then
              PosX := System.Pos(Trim(Lines.Strings[PosY]), Lines.Strings[PosY]) - 1
            else
              PosX := 0;
          end
        else
          begin
            if ssCtrl in Shift then
              Enlarge(-PosY, True);
            Enlarge(-PosX);
          end;

      VK_END:
        if fInProposalCall then
          FProposalForm.ToEnd
        else if not(ssShift in Shift) then
          begin
            Collapse;
            if ssCtrl in Shift then
              PosY := fLines.Count - 1;
            PosX := Length(fLines[PosY]);
          end
        else
          begin
            if ssCtrl in Shift then
              Enlarge(fLines.Count - 1 - PosY, True);
            Enlarge(Length(fLines[PosY]) - PosX);
          end;

      VK_NEXT:
        if fInProposalCall then
          FProposalForm.PAGEDOWN
        else if not(ssShift in Shift) then
          begin
            Collapse;
            if not(ssCtrl in Shift) then
              PosY := FindVisibleRow(PosY, ClientLines - 1, True)
            else
              PosY := FindVisibleRow(OffsetY, ClientLines - 1, True)
          end
        else if not(ssCtrl in Shift) then
          Enlarge(ClientLines() - 1, True)
        else
          Enlarge(OffsetY + (ClientLines - 1) - PosY, True);

      VK_PRIOR:
        if fInProposalCall then
          FProposalForm.PAGEUP
        else if not(ssShift in Shift) then
          begin
            Collapse;
            if not(ssCtrl in Shift) then
              PosY := FindVisibleRow(PosY, -(ClientLines - 1), True)
            else
              PosY := OffsetY
          end
        else if not(ssCtrl in Shift) then
          Enlarge(-(ClientLines - 1), True)
        else
          Enlarge(-(OffsetY - PosY), True);
      VK_ESCAPE:
        begin
          CloseProposal
        end;

      VK_DELETE:
        if not(smoReadOnly in fOptions) then
          Range.Delete;

      VK_TAB:
        if not(smoReadOnly in fOptions) then
          Range.SetTextEx(StringOfChar(' ', 4 - PosX mod 4), ukLetterTyped);

      VK_BACK:
        if not(smoReadOnly in fOptions) then
          begin
            if (PosX = 0) and (FindVisibleRow(Range.PosY, -1, True) = Range.PosY - 1) then
              with Range do
                begin
                  StartX := Length(fLines[PosY - 1]);
                  StartY := PosY - 1;
                end
            else if PosX > 0 then
              begin
                if Length(Trim(Copy(Lines.Strings[PosY], 1, PosX))) = 0 then
                  StartX := 0
                else
                  begin
                    if (StartX = EndX) and (StartY = EndY) then
                      StartX := PosX - 1;
                  end;
              end;
            Range.Delete;
          end;

      VK_RETURN:
        if fInProposalCall then
          FProposalForm.CompleteProposal
        else if not(smoReadOnly in fOptions) then
          begin
            { if not (smoTabulatedReturn in fOptions)
            then Range.SetTextEx(#13#10,ukLetterTyped);
            else{ }
            begin
              // The next line looks a bit complicated, but
              // it is simple really - take the number of spaces in
              // the current line and, when adding a new line,
              // insert them
              X := PosY; // Don't be surprised - don't want to add a new variable
              if X < Lines.Count then
                begin
                  while Length(Trim(Lines.Strings[X])) = 0 do
                    begin
                      if X = 0 then
                        Break;
                      dec(X);
                    end;
                  Range.SetTextEx(#13#10 + Copy(Lines.Strings[X], 1,
                    System.Pos(Trim(Lines.Strings[X]), Lines.Strings[X]) - 1), ukLetterTyped);
                end
              else
                Range.SetTextEx(#13#10, ukLetterTyped);
            end

          end;

      VK_INSERT:
        if Shift = [] then
          begin
            if not(smoReadOnly in fOptions) then
              if smoOverwrite in fOptions then
                SetOptions(fOptions + [smoOverwrite])
              else
                SetOptions(fOptions - [smoOverwrite]);
          end
        else
          begin
            // SiO: Add copy and paste
            // via Ctrl+Ins / Shift+Ins - I can't live without them =)
            if Shift = [ssCtrl] then
              fRange.CopyToClipboard;
            if Shift = [ssShift] then
              fRange.PasteFromClipboard;
          end;
      Ord(' '):
        if Shift = [ssCtrl] then
          begin
            fInProposalCall := True;
          end;

      Ord('A'):
        if Shift = [ssCtrl] then
          fRange.SelectAll;

      Ord('C'):
        if ssCtrl in Shift then
          fRange.CopyToClipboard;

      Ord('X'):
        if Shift = [ssCtrl] then
          fRange.CutToClipBoard;

      Ord('V'):
        if (Shift = [ssCtrl]) and not(smoReadOnly in fOptions) then
          fRange.PasteFromClipboard;

      Ord('Z'):
        if ssCtrl in Shift then
          if CanUndo then
            DoUndo;

      Ord('I'):
        if Shift = [ssCtrl, ssShift] then
          fRange.MakeIndent;

      Ord('U'):
        if Shift = [ssCtrl, ssShift] then
          fRange.MakeUnIndent;

      191: // ORD('/'):
        if (Shift = [ssCtrl]) and (poHasILComment in fParseAttributes.ParseOptions) then
          fRange.MakeComment(fParseAttributes.fLitILComment); { }

      VK_ADD:
        if ssCtrl in Shift then
          fRange.ExpandSection(ssShift in Shift);

      VK_SUBTRACT:
        if ssCtrl in Shift then
          fRange.CollapseSection(ssShift in Shift);

      VK_F5: fRange.CreateSection;

      VK_F6: fRange.ExplodeSection(ssCtrl in Shift);
      Ord('0') .. Ord('9'):
        begin
          if ssCtrl in Shift then
            begin
              if ssShift in Shift then
                BookMarks[Key - Ord('0')] := fRange.PosY
              else
                Navigate(0, BookMarks[Key - Ord('0')]);
            end
            { else
            if Lines.Count=0 then
            begin
            PosX := PosX + 1;
            PosX := PosX - 1
            end;
          }
        end;
      VK_NUMPAD0 .. VK_NUMPAD9:
        if ssCtrl in Shift then
          if ssShift in Shift then
            BookMarks[Key - VK_NUMPAD0] := fRange.PosY
          else
            Navigate(0, BookMarks[Key - VK_NUMPAD0]);

{$IFDEF SYNDEBUG}
      VK_MULTIPLY:
        if ssCtrl in Shift then
          Log('---------------');
{$ENDIF}
    end; (* *)
end;

// Insert a character at the current position
procedure TMPCustomSyntaxMemo.KeyPress(var Key: Char);
begin
  inherited;
  if (not(smoReadOnly in fOptions)) then
    case Key of
      #32 .. High(Char):
        if fInProposalCall and (Key = #32) and not FProposalForm.Visible then
          ProposalCall
        else
          begin
            if (Self.Lines.Count = 0) then
              begin
                Range.PosX := Range.PosX + 1;
                Range.PosX := Range.PosX - 1;
              end;
            Range.Text := Key;
            if fInProposalCall then
              FProposalForm.ChangeListText;

          end
          // Range. SetTextEx(Key,ukLetterTyped);
    end; { }
end;

// Key release
procedure TMPCustomSyntaxMemo.KeyUp(var Key: Word; Shift: TShiftState);
begin
  Cursor := crIBeam;
  ShowHint := False;
  SelectedWord := Point(-1, -1);
  if Assigned(fOnWordInfo) then
    fOnWordInfo(Self, 0, 0, -1, -1, False);
  fHinting := False;
  if Key = VK_BACK then
    if fInProposalCall then
      FProposalForm.ChangeListText;

  inherited;
end;

// Paint() Repaints the whole component
procedure TMPCustomSyntaxMemo.Paint;
begin
  // inherited;
  if Parent = nil then
    Exit;
  { } {$IFDEF SYNDEBUG}
  { } Log('Memo.Paint');
  { } {$ENDIF}
  NeedRedrawAll;
end;

// CreateParams() Sets the component parameters
procedure TMPCustomSyntaxMemo.CreateParams(var Params: TCreateParams);
begin
  inherited;
  with Params do
    begin
      ExStyle := ExStyle or WS_EX_CLIENTEDGE; // 3d window border
      Style := Style and not WS_TABSTOP;
    end;
end;

// WMMouseWheel() Handles the mouse wheel
procedure TMPCustomSyntaxMemo.WMMouseWheel(var Message: TMessage);
begin
  inherited;
  if GetKeyState(VK_CONTROL) and $8000 <> 0 then
    if Short(Message.WParamHi) > 0 then
      OffsetXPix := Max(OffsetXPix - 4, 0)
    else
      OffsetXPix := OffsetXPix + 4
  else if Short(Message.WParamHi) > 0 then
    OffsetY := FindVisibleRow(OffsetY, -3, True)
  else
    OffsetY := FindVisibleRow(OffsetY, +3, True);
end;

// WMKillFocus() Handles focus loss
procedure TMPCustomSyntaxMemo.WMKillFocus(var Msg: TWMKillFocus);
begin
  inherited;
  if (Msg.FocusedWnd <> fHScroll.Handle) and (Msg.FocusedWnd <> fVScroll.Handle) then
    begin
      HideCaret;
      Windows.DestroyCaret;
    end;
end;

// WMSetFocus() Handles focus gain
procedure TMPCustomSyntaxMemo.WMSetFocus(var Msg: TWMSetFocus);
begin
  inherited;
  if (Msg.FocusedWnd <> fHScroll.Handle) and (Msg.FocusedWnd <> fVScroll.Handle) then
    begin
      Windows.CreateCaret(Handle, 0, 1, fCharHeight);
      ShowCaret;
    end;
end;

// ScrollEnter() Enters scrolling
procedure TMPCustomSyntaxMemo.ScrollEnter(Sender: TObject);
begin
  SetFocus;
end;

// MouseDown() Mouse button press
procedure TMPCustomSyntaxMemo.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Col, Row, SRow: Integer;
  r: TRect;
begin
  { } {$IFDEF SYNDEBUG}
  { } LogFmt('MouseDown at (%d, %d)', [X, Y]);
  { } {$ENDIF}
  if not Focused then
    SetFocus;
  { Left mouse button }
  if (Button = mbLeft) and (Shift = [ssLeft]) then
    if PtInRect(EntireGutterRect[-1], Point(X, Y)) then
      begin
        if X > 11 then
          begin
            { Button pressed in the gutter - collapse / expand the section }
            WndOffsetToPixOffset(Point(X, Y), Col, SRow, False);
            Row := FindVisibleRow(OffsetY, SRow, False);
            if Row <> -1 then
              with fSections.Section[Row] do
                if (Level > 0) and (Row = RowBeg) then
                  begin
                    r := GetSectionButtonRect(SRow, Level);
                    if PtInRect(r, Point(X, Y)) then
                      begin
                        if Collapsed then
                          fSections.Expand(Row, False, False)
                        else
                          fSections.Collapse(Row, False, False);
                      end;
                  end;
          end
        else
          begin
            WndOffsetToPixOffset(Point(X, Y), Col, SRow, False);
            Row := FindVisibleRow(OffsetY, SRow, False);
            if fBreakPoints.IsBreakPoint[Row] then
              fBreakPoints.IsBreakPoint[Row] := False
            else
              fBreakPoints.IsBreakPoint[Row] := True;
          end;
      end
    else
      begin
        fDown := True;
        { shrink the selection }
        Range.Collapse;
        WndOffsetToPixOffset(Point(X, Y), Col, Row, True);
        if fLines.IsValidLineIndex(Row) then
          begin
            Col := PixOffsetToCharPos(Col, Row);
            Range.Pos := Point(Col, Row);
            CloseProposal
          end;
      end
  else
    { Middle mouse button - panning (!!!) }
    { SiO: Reworked }
    if (Button = mbMiddle) and (Shift = [ssMiddle]) and (smoPanning in fOptions) then
      begin
        fPanning := True;
        Cursor := crSizeAll;
        fPanStartPoint := Point(X, Y);
        GetWindowRect(Self.Handle, r);
        r.Bottom := r.Bottom - fHScroll.Height - 4;
        r.Right := r.Right - fVScroll.Width - 4;
        r.Left := r.Left + GutterWidth + 2;
        r.Top := r.Top + 2;
        ClipCursor(@r);
      end;
  inherited;
end;

// MouseMove() Mouse move - handles selection changes
procedure TMPCustomSyntaxMemo.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Col, Row: Integer;
  oX, oY: Integer;
  r: TRect;
  p: TPoint;
begin
  // Selection handling
  if fDown and (Shift = [ssLeft]) then
    begin
      // changes happen only if the position changed
      { DONE -oMax Proof -c19.03.2006 :
      WndOffsetToPixOffset may return Row <= 0 for
      special areas (above the text, below the text, hidden text)
      etc. This case was not handled at all. }
      WndOffsetToPixOffset(Point(X, Y), Col, Row, False);
      // get the line number
      Row := FindVisibleRow(OffsetY, Row, True);
      // get the column number in the line
      Col := PixOffsetToCharPos(Col, Row);
      if (Col <> Range.PosX) or (Row <> Range.PosY) then
        begin
          Range.Enlarge(Row - Range.PosY, True);
          Range.Enlarge(Col - Range.PosX);
        end;
    end
  else if fHinting then
    begin
      if (ssCtrl in Shift) then
        begin
          WndOffsetToPixOffset(Point(X, Y), Col, Row, True);
          if Row <> -1 then
            begin
              PixOffsetToCharPos(Col, Row, @Col);
              if InRange(Col, 0, fLines.Parser[Row].Count - 1) then
                begin
                  SelectedWord := Point(Col, Row);
                  if Assigned(fOnWordInfo) then
                    fOnWordInfo(Self, X, Y, Col, Row, True)
                  else
                    with fLines.Parser[Row].Tokens[Col] do
                      Hint := Format
                        ('Word: "%s"'#13#10'Start: %d'#13#10'Length: %d'#13#10'As token #%d',
                          [Copy(fLines[Row], stStart + 1, stLength), stStart, stLength, stToken]);
                end
            end;
        end
      else
        begin
          Cursor := crIBeam;
          ShowHint := False;
          SelectedWord := Point(-1, -1);
          fHinting := False;
        end;
    end
  else if fPanning then
    begin
      oX := fPanStartPoint.X;
      oY := fPanStartPoint.Y;
      fPanStartPoint := Point(X, Y);

      oY := (oY - fPanStartPoint.Y);
      oX := (oX - fPanStartPoint.X);
      if (smoHorPanning in fOptions) then
        OffsetXPix := Max(OffsetXPix + oX, 0);
      if (smoVerPanningReverse in fOptions) then
        oY := -oY;
      OffsetY := FindVisibleRow(OffsetY, oY, True);

      // Cursor jump
      GetWindowRect(Self.Handle, r);
      r.Bottom := r.Bottom - fHScroll.Height - 5;
      r.Top := r.Top + 2;
      GetCursorPos(p);
      if p.Y = r.Top then
        begin
          p.Y := r.Bottom - 1;
          fPanStartPoint.Y := fPanStartPoint.Y + (r.Bottom - r.Top - 1);
          SetCursorPos(p.X, p.Y);
        end;
      if p.Y = r.Bottom then
        begin
          p.Y := r.Top + 1;
          fPanStartPoint.Y := fPanStartPoint.Y - (r.Bottom - r.Top - 1);
          SetCursorPos(p.X, p.Y);
        end;
      CloseProposal;

    end
  else if Shift = [] then
    begin
      if PtInRect(EntireGutterRect[-1], Point(X, Y)) then
        Cursor := crDefault
      else
        Cursor := crIBeam;
    end;
  inherited;
end;

// MouseUp() Mouse button release
procedure TMPCustomSyntaxMemo.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
  Handled: Boolean;
  r: TRect;
  W, Row: Integer;
begin
  inherited;
  fDown := False;
  if fPanning then
    begin
      fPanning := False;
      Cursor := crIBeam;
      ClipCursor(nil);
      Exit;
    end;

  if (Button = mbLeft) and (Shift = [ssRight]) and (smoPanning in fOptions) then
    begin
      fPanning := True;
      Cursor := crSizeAll;
      fPanStartPoint := Point(X, Y);
      GetWindowRect(Self.Handle, r);
      r.Bottom := r.Bottom - fHScroll.Height - 4;
      r.Right := r.Right - fVScroll.Width - 4;
      r.Left := r.Left + GutterWidth + 2;
      r.Top := r.Top + 2;
      ClipCursor(@r);
    end;

  if Button = mbRight then
    begin
      if PtInRect(EntireGutterRect[-1], Point(X, Y)) then
        begin // Click on the gutter
          if X < 11 then
            begin // Click on a BreakPoint
              GetWordAtPos(X, Y, W, Row);
              fBreakPoints.RowOfCurrentBP := Row;
              GetCursorPos(p);
              if Assigned(fBreakPoints.fPopUpMenu) then
                begin
                  Handled := False;
                  if Assigned(fOnBreakPointPopup) then
                    fOnBreakPointPopup(Self, Point(X, Y), Handled);
                  if not Handled then
                    fBreakPoints.fPopUpMenu.Popup(p.X, p.Y);
                end;
            end;
        end
      else
        begin // Click on the text
          GetCursorPos(p);
          if Assigned(fPopUpMenu) then
            begin
              Handled := False;
              if Assigned(fOnContextPopup) then
                fOnContextPopup(Self, Point(X, Y), Handled);
              if not Handled then
                fPopUpMenu.Popup(p.X, p.Y);
            end;
        end;
    end;
end;

// FindNextWord() Finds the next word.
// If the word is found (not end of text), its start is returned
// via the wx, wy references
function TMPCustomSyntaxMemo.FindNextWord(var wx, wy: Integer): Boolean;
var
  Sp: TMPSyntaxParser;
  wn: Integer;
begin
  Result := True;
  wx := CharPosToWordIndex(Range.PosX, Range.PosY);
  wy := Range.PosY;
  Sp := fLines.Parser[wy];
  { Cursor between words in the middle of the line }
  if wx < 0 then
    begin
      wy := Range.PosY;
      wx := Sp[-wx].stStart;
    end
  else
    { Cursor after the last word in the line }
    if wx = MaxInt then
      begin
        wy := FindVisibleRow(wy, 1, False);
        Result := wy >= 0;
        if Result then
          begin
            Sp := fLines.Parser[wy];
            if Sp.Count > 0 then
              wx := Sp[0].stStart
            else
              wx := 0;
          end
      end
    else
      { Cursor on the last word in the line }
      if wx = Sp.Count - 1 then
        with Sp[wx] do
          wx := stStart + stLength
        { Cursor on any other word in the line }
      else
        begin
          wn := wx;
          repeat
            Inc(wn);
            if wn = Sp.Count then
              begin
                with Sp[wn - 1] do
                  wx := stStart + stLength;
                Exit;
              end;
            wx := Sp[wn].stStart;

          until Sp[wn].stToken in tokWords + tokUserWords;
        end
end;

// FindPrevWord() Finds the previous word.
// If the word is found (not start of text), its start is returned
// via the wx, wy references
function TMPCustomSyntaxMemo.FindPrevWord(var wx, wy: Integer): Boolean;
var
  Sp: TMPSyntaxParser;
  function FindLastWordOfPrevRow: Boolean;
  begin
    wy := FindVisibleRow(wy, -1, False);
    Result := wy >= 0;
    if Result then
      begin
        Sp := fLines.Parser[wy];
        if Sp.Count > 0 then
          with Sp[Sp.Count - 1] do
            wx := stStart + stLength
        else
          wx := 0;
      end;
  end;

var
  wn: Integer;
begin
  Result := True;
  wx := CharPosToWordIndex(Range.PosX, Range.PosY);
  wy := Range.PosY;
  Sp := fLines.Parser[wy];
  { Cursor between words in the middle of the line }
  if wx < 0 then
    { Before the first word - nothing on the left }
    if wx = -1 then
      Result := FindLastWordOfPrevRow
    else
      wx := Sp[-wx - 1].stStart
  else
    { After the last word in the line }
    if wx = MaxInt then
      if Sp.Count = 0 then
        Result := FindLastWordOfPrevRow
      else
        wx := Sp[Sp.Count - 1].stStart
    else
      { Inside an arbitrary word in the line }
      if Sp[wx].stStart = Range.PosX then
        { At the word start }
        if wx = 0 then
          Result := FindLastWordOfPrevRow
        else
          begin
            wn := wx;
            repeat
              dec(wn);
              if wn < 0 then
                begin
                  wx := -1;
                  Result := FindLastWordOfPrevRow;
                  Exit;
                end;
              wx := Sp[wn].stStart;

            until Sp[wn].stToken in tokWords + tokUserWords;

            // wx := Sp[wx - 1].stStart
          end
      else
        { In the middle of the word }
        wx := Sp[wx].stStart;
end;

function TMPCustomSyntaxMemo.WordByPos(const WordPos: TPoint): string;
var
  Parser: TMPSyntaxParser;
  i: Integer;
begin
  Result := '';
  if (WordPos.Y >= 0) and (WordPos.Y < fLines.Count) then
    begin
      Parser := Lines.Parser[WordPos.Y];
      for i := Parser.Count - 1 downto 0 do
        if Parser[i].stStart <= WordPos.X then
          begin
            Result := Copy(Lines[WordPos.Y], Parser[i].stStart + 1, Parser[i].stLength);
            Break
          end

    end;
end;

// PaintLine() Repaints a line
(* procedure TMPCustomSyntaxMemo.PaintLine(const ScreenRow, Row: Integer);
  var CharPos, WIndex, SelIndeXFrom, SelIndeXTo, i: Integer;
  T: TMPSyntaxToken;
  s: string;
  PaintOffset, SecPnt: TPoint;
  ClipRgn: HRGN;
  RowRect, WordRect, R: TRect;
  Sp: TMPSyntaxParser;
  Sec: TMPSynMemoSection;
  begin
  // If the component is not visible - why repaint it?
  if not Visible then Exit;

  {} {$IFDEF SYNDEBUG}
  {} LogFmt('Memo.PaintLine %d as %d', [ScreenRow, Row]);
  {} {$ENDIF}

  // Line parameters
  RowRect := TextRowRect[ScreenRow];

  // Draw the GUTTER
  with Canvas do begin
  // Fill the Gutter area
  if smoVSNET_SectionsStyle in fOptions
  then R := SymbolsGutterRect[ScreenRow]
  else R := EntireGutterRect[ScreenRow];
  Brush.Style := bsSolid;
  Brush.Color := clBtnFace;
  Dec(R.Right, 4);
  FillRect( R );
  // Bevel Edge on the right of the Gutter
  Pen.Color := clBtnHighlight;
  MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
  Pen.Color := clBtnShadow;
  MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
  Pen.Color := self.Color;
  MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
  MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
  // Clear the line
  Canvas.Brush.Color := Self.Color;
  FillRect(Rect(R.Right, RowRect.Top, RowRect.Right, RowRect.Bottom));

  // If the line number is invalid (e.g. lines below the text)
  // Just erase everything and exit
  if Row < 0 then Exit;

  // Handle a real text line
  Sp := fLines.Parser[Row];                           // line parser
  Sec := Sp.Section;                                  // line section
  s := fLines[Row];                                   // line
  R := GetSectionButtonRect(ScreenRow, Sec.Level);    // square box
  SecPnt := CenterPoint(R);                           // center point of the box

  // Section start - draw the box
  if (Sec.RowBeg = Row) and (Sec.Level > 0) then begin
  if Sec.Collapsed then begin
  Brush.Color := clWhite;
  Pen.Color   := clBlack;
  Rectangle(R);
  end else begin
  Brush.Color := clBlack;
  FrameRect(R);
  end;
  Pen.Color := clBlack;
  with R do begin
  MoveTo(Left + 2, SecPnt.Y);
  LineTo(Right - 2, SecPnt.Y);
  if Sec.Collapsed then begin
  MoveTo(SecPnt.X, Top + 2);
  LineTo(SecPnt.X, Bottom - 2);
  end;
  Pen.Color := clDkGray;
  // Line to the right of the box
  MoveTo(Right, SecPnt.Y);
  LineTo(RowRect.Left - 2, SecPnt.Y);
  if not Sec.Collapsed then begin
  // Line below the box
  MoveTo(SecPnt.X, Bottom);
  LineTo(SecPnt.X, RowRect.Bottom);
  end;
  end;
  // Draw the ellipsis at the end of the line
  if Sec.Collapsed then begin
  R := RowRect;
  Inc(R.Top, 1);
  Dec(R.Bottom, 1);
  R.Left := R.Right - 32;
  R.Right := R.Left + 22;
  Brush.Color := clBlue;
  FrameRect(R);
  R := Bounds(R.Left + 5, R.Top + 8, 2, 2);
  FillRect(R);
  OffsetRect(R, 5, 0);
  FillRect(R);
  OffsetRect(R, 5, 0);
  FillRect(R);
  end;
  end else

  // Section end - draw a horizontal tick
  if (Sec.RowEnd = Row) and (Sec.Level > 0) then begin
  Pen.Color := clDkGray;
  MoveTo(SecPnt.X, RowRect.Top);
  LineTo(SecPnt.X, SecPnt.Y);
  LineTo(RowRect.Left - 2, SecPnt.Y);
  end else

  // Plain line belonging to a non-root section
  if Sec.Level > 0 then begin
  Pen.Color := clDkGray;
  MoveTo(SecPnt.X, RowRect.Top);
  LineTo(SecPnt.X, RowRect.Bottom);
  end;

  // Draw the vertical lines of parent sections
  // only NOT FOR MS VS NET emulation mode
  if not (smoVSNET_SectionsStyle in fOptions) then
  for i := Sec.Level - 1 downto 1 do begin
  Dec(SecPnt.X, fSectionIndent);
  MoveTo(SecPnt.X, RowRect.Top);
  LineTo(SecPnt.X, RowRect.Bottom);
  end;

  // Calculate and set the Clip Region for the text canvas
  with RowRect do
  if Sec.Collapsed
  then ClipRgn := CreateRectRgn(Left, Top, Right - 33, Bottom)
  else ClipRgn := CreateRectRgn(Left, Top, Right, Bottom);
  SelectClipRgn(Canvas.Handle, ClipRgn);

  // Offset for the line start (X<=0 !!!)
  PaintOffset := PixOffsetToWndOffsetEx(0, ScreenRow);

  // Draw the selection
  if not Range.IsEmpty() and InRange(Row, Range.StartY, Range.EndY) then begin
  // If the line = first selection line, determine the left bound,
  // otherwise, take it as the start of the visible text area (OffsetX)
  if Row = Range.StartY
  then SelIndeXFrom := PaintOffset.X + CharPosToPixOffset(Range.StartX, Row)
  else SelIndeXFrom := RowRect.Left;
  // Likewise determine the right selection bound
  if Row = Range.EndY
  then SelIndeXTo   := PaintOffset.X + CharPosToPixOffset(Range.EndX, Row)
  else SelIndeXTo   := RowRect.Right;
  // Draw the selection
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := fSelColor;
  Canvas.FillRect( Rect(SelIndeXFrom, RowRect.Top, SelIndeXTo, RowRect.Bottom) );
  end;

  // Draw all words, one by one
  if Assigned(Sp) then
  with Canvas do begin
  Brush.Style := bsClear;
  Pen.Color := clRed;
  Font.Assign(Self.Font);
  PenPos := PaintOffset;
  CharPos := 0;
  for WIndex := 0 to Sp.Count - 1 do begin
  T := Sp[WIndex];
  with fParseAttributes.fTokenStyles[T.stToken] do begin
  Font.Color := tsForeground;
  Font.Style := tsStyle;
  end;
  WordRect.TopLeft := PenPos;
  Inc(WordRect.Left, (T.stStart - CharPos) * fCharWidths[False][' ']);
  TextOut(WordRect.Left, WordRect.Top, Copy(s, T.stStart + 1, T.stLength));
  WordRect.Right := PenPos.X;
  WordRect.Bottom := WordRect.Top + fCharHeight - 1;
  if (fSelWord.X = WIndex) and (fSelWord.Y = Row) then
  Rectangle( WordRect );
  CharPos := T.stStart + T.stLength;
  end;
  end;

  // Remove the Clip Region for the line canvas
  SelectClipRgn(Canvas.Handle, 0);
  DeleteObject(ClipRgn);
  end;
  end; *)

// Recalculates painting parameters if the font changed
procedure TMPCustomSyntaxMemo.FontChange(Sender: TObject);
begin
  fLines.BeginUpdate;
  CalcFontParams;
  NeedRedrawAll;
  fLines.EndUpdate;
end;

// Sets/clears the highlight for a specific word in the line (red frame)
procedure TMPCustomSyntaxMemo.SetSelectedWord(const Value: TPoint);
begin
  fLines.BeginUpdate;
  // Clear the old highlight
  if fLines.IsValidLineIndex(fSelWord.Y) then
    NeedRedraw(fSelWord.Y);
  // Reset the highlight
  fSelWord := Point(-1, -1);
  // Set the new highlight
  if fLines.IsValidLineIndex(Value.Y) then
    begin
      // Set the offset so the highlighted word is fully on screen
      ShowWord(Value.Y, Value.X);
      // If a highlight is being created - so be it
      fSelWord := Value;
      NeedRedraw(fSelWord.Y);
    end;
  fLines.EndUpdate;
end;

// Shows the word on screen (setting the appropriate screen offset)
procedure TMPCustomSyntaxMemo.ShowWord(const Row, WordIndex: Integer);
begin
{$IFDEF SYNDEBUG}
  LogFmt('Memo.ShowWord Row=%d; WordIndex=%d)', [Row, WordIndex]);
{$ENDIF}
  if fLines.IsValidLineIndex(Row) then
    with fLines.Parser[Row] do
      if InRange(WordIndex, 0, Count - 1) then
        with Tokens[WordIndex] do
          MakeVisible(stStart, Row, stLength);
end;

// Returns info about the word at position X, Y relative to the window
// LineIndex - line number
// WBeg      - index of the word's first character in the line
// WLen      - word length
function TMPCustomSyntaxMemo.GetWordAtPos(const X, Y: Integer; var WordIndex, Row: Integer): Boolean;
var
  N, Row1: Integer;
begin
  WndOffsetToPixOffset(Point(X, Y), N, Row1, True);
  Result := fLines.IsValidLineIndex(Row1);
  if Result then
    begin
      Row := Row1;
      PixOffsetToCharPos(N, Row1, @WordIndex);
    end;
end;

// Makes line Row, column Col visible,
// expanding the corresponding sections if needed
procedure TMPCustomSyntaxMemo.Navigate(const Col, Row: Integer);
begin
  if not fLines.IsValidLineIndex(Row) then
    Exit;
{$IFDEF SYNDEBUG}
  LogFmt('Memo.NavigateTo Col=%d; Row=%d', [Col, Row]);
{$ENDIF}
  fLines.BeginUpdate;
  fSections.Expand(Row, False, True);
  SetOffsets(Point(0, FindVisibleRow(Row, -2, True)));
  fRange.Pos := Point(Col, Row);
  fLines.EndUpdate;
end;

// Makes character position PosX in line PosY visible
procedure TMPCustomSyntaxMemo.MakeVisible(const Col, Row: Integer; const Length: Integer = 1);
var
  RowPix, CharPix, CharPixLen: Integer;
  NewOffsets: TPoint;
  r: TRect;
begin
  { } {$IFDEF SYNDEBUG}
  { } LogFmt('Memo.MakeVisible(Col=%d; Row=%d; Length=%d)', [Col, Row, Length]);
  { } {$ENDIF}
  // Vertical
  RowPix := RangeRowToScreenRow(Row);
  if RowPix = ROW_HIDEN then
    Exit
  else if RowPix = ROW_ABOVE_SCREEN then
    NewOffsets.Y := Row
  else if RowPix = ROW_BELOW_SCREEN then
    NewOffsets.Y := FindVisibleRow(Row, -(ClientLines - 1), True)
  else
    NewOffsets.Y := OffsetY;

  // Horizontal
  r := TextRowRect[0];
  CharPixLen := Length * 10;
  CharPix := CharPosToPixOffset(Col, Row);
  if CharPix < OffsetXPix then
    NewOffsets.X := CharPix
  else if CharPix + CharPixLen - OffsetXPix > r.Right - r.Left then
    NewOffsets.X := CharPix + CharPixLen - r.Right + r.Left
  else
    NewOffsets.X := OffsetXPix;

  // All together
  if (NewOffsets.X <> OffsetXPix) or (NewOffsets.Y <> OffsetY) then
    SetOffsets(NewOffsets);
end;

// Returns the word index in the line by character index
// If in spaces - returns the negative index of the nearest word to the right
// If outside the line - returns MAXINT
function TMPCustomSyntaxMemo.CharPosToWordIndex(const Col, Row: Integer): Integer;
var
  Sp: TMPSyntaxParser;
  i, WBeg: Integer;
begin
  Result := MaxInt;
  if not InRange(Row, 0, fLines.Count - 1) then
    Exit;
  Sp := TMPSyntaxParser(fLines.Objects[Row]);
  if Sp <> nil then
    for i := 0 to Sp.Count - 1 do
      begin
        WBeg := Sp[i].stStart;
        if Col < WBeg then
          begin
            Result := -i;
            Exit;
          end
        else if Col < WBeg + Sp[i].stLength then
          begin
            Result := i;
            Exit;
          end;
      end;
end;

// Returns the user word definition event
function TMPCustomSyntaxMemo.GetUserTokenEvent: TUserTokenEvent;
begin
  if Assigned(fParseAttributes) then
    Result := fParseAttributes.OnUserToken
  else
    Result := nil;
end;

// Sets the user word definition event
procedure TMPCustomSyntaxMemo.SetUserTokenEvent(const Value: TUserTokenEvent);
begin
  if Assigned(fParseAttributes) then
    fParseAttributes.OnUserToken := Value;
end;

// Sets the GUTTER width
procedure TMPCustomSyntaxMemo.SetGutterWidth(const Value: Integer);
begin
  if fGutterWidth <> Value then
    begin
      fGutterWidth := Value;
      Repaint;
    end;
end;

// Returns True if the line is shown on screen
function TMPCustomSyntaxMemo.IsLineVisible(const Row: Integer; const PScreenRow: PInteger = nil): Boolean;
var
  sr: Integer;
begin
  sr := RangeRowToScreenRow(Row);
  Result := InRange(sr, 0, ClientLines - 1);
  if Result and Assigned(PScreenRow) then
    PScreenRow^ := sr;
end;

// Sets a new offset for the section level
procedure TMPCustomSyntaxMemo.SetSectionIndent(const Value: Integer);
begin
  fSectionIndent := Value;
  NeedRedrawAll;
end;

// Returns the screen coordinate rectangle of the given area
// Global function. Must be rewritten if the way of computing
// coordinates of special screen zones changes.
// Input - SCREEN line index (relative to the top screen line).
// If ScreenRow = -1, the corresponding WINDOW area is returned.
// DOES NOT CHECK LINE VISIBILITY NOR THAT THE LINE IS WITHIN THE SCREEN
function TMPCustomSyntaxMemo.GetWndRect(const ScreenRow, Index: Integer): TRect;
begin
  if smoVSNET_SectionsStyle in fOptions then
    case Index of

      { EntireRowRect }
      0:
        begin
          if ScreenRow = -1 then
            begin
              { For all lines at once }
              Result := ClientRect;
              dec(Result.Bottom, fHScroll.Height);
            end
          else
            { For the given line }
            Result := Bounds(0, ScreenRow * fCharHeight, ClientWidth,
              Min(fCharHeight, ClientHeight - fHScroll.Height - ScreenRow * fCharHeight));
          // fCharHeight );
          dec(Result.Right, fVScroll.Width);
          dec(Result.Right);
        end;

      { TextRowRect }
      1:
        begin
          Result := EntireRowRect[ScreenRow];
          Result.Left := EntireGutterRect[ScreenRow].Right;
        end;

      { EntireGutterRect }
      2:
        begin
          Result := SymbolsGutterRect[ScreenRow];
          Inc(Result.Right, fSectionIndent + 2);
        end;

      { SymbolsGutterRect }
      3:
        begin
          Result := EntireRowRect[ScreenRow];
          Result.Right := Result.Left + fGutterWidth;
        end;
    end

  else
    case Index of

      { EntireRowRect }
      0:
        begin
          if ScreenRow = -1 then
            begin
              { For all lines at once }
              Result := ClientRect;
              dec(Result.Bottom, fHScroll.Height);
            end
          else
            { For the given line }
            Result := Bounds(0, ScreenRow * fCharHeight, ClientWidth,
              Min(fCharHeight, ClientHeight - fHScroll.Height - ScreenRow * fCharHeight));
          dec(Result.Right, fVScroll.Width);
          dec(Result.Right);
        end;

      { TextRowRect }
      1:
        begin
          Result := EntireRowRect[ScreenRow];
          Result.Left := EntireGutterRect[ScreenRow].Right;
        end;

      { EntireGutterRect }
      2:
        begin
          Result := EntireRowRect[ScreenRow];
          if smoAutoGutterWidth in fOptions then
            Result.Right := Result.Left + fGutterWidth + fSections.fMaxExpandLevel * fSectionIndent + 2
          else
            Result.Right := Result.Left + fGutterWidth + fSections.fMaxLevel * fSectionIndent + 2;
        end;

      { SymbolsGutterRect }
      3:
        begin
          Result := EntireRowRect[ScreenRow];
          Result.Right := Result.Left + fGutterWidth;
        end;
    end;
end;

// Converts position X, Y of the client area
// to the offset from the line start and the text line number
procedure TMPCustomSyntaxMemo.WndOffsetToPixOffset(OfsPoint: TPoint; var CharPix, Row: Integer; const TextRow: Boolean);
var
  r: TRect;
begin
  r := TextRowRect[0];
  CharPix := OfsPoint.X - r.Left + OffsetXPix;
  // Get the line index on screen ..
  Row := (OfsPoint.Y - r.Top) div fCharHeight;
  // .. and, if needed, convert it to the real line index in the text
  if TextRow then
    Row := FindVisibleRow(OffsetY, Row, False);
end;

// Converts a pixel offset within a line to coordinates
// within the window client area
function TMPCustomSyntaxMemo.PixOffsetToWndOffsetEx(const CharPix, ScreenRow: Integer): TPoint;
var
  Rect: TRect;
begin
  Rect := TextRowRect[ScreenRow];
  with Rect do
    begin
      Inc(Left, CharPix - OffsetXPix);
      Result := TopLeft;
    end;
end;

// Returns the paint area of the section header box via R: TRect
// If there is no box, returns False
function TMPCustomSyntaxMemo.GetSectionButtonRect(const ScreenRow, ALevel: Integer): TRect;
begin
  // Gutter area for this line
  Result := SymbolsGutterRect[ScreenRow];
  if smoVSNET_SectionsStyle in fOptions
  // All boxes on one line
  then
    Result.Left := Result.Right + 2
  // Horizontal box area within its SectionIndent
  else
    Result.Left := Result.Right + (ALevel - 1) * fSectionIndent;
  Result.Right := Result.Left + 9;
  Result.Top := (Result.Top + Result.Bottom) shr 1 - 4;
  Result.Bottom := Result.Top + 9;
end;

// Hides the cursor
procedure TMPCustomSyntaxMemo.HideCaret;
begin
  if fCaretVisible and Assigned(Parent) then
    begin
      Windows.HideCaret(Handle);
      fCaretVisible := False;
    end;
end;

type
{$IFNDEF D9+}
  THackStrings = class(TPersistent)
  private
    FDefined: TStringsDefined;
    FDelimiter: Char;
    FQuoteChar: Char;
    UpdateCount: Integer;
  end;

{$ELSE}

  THackStrings = class(TStrings);
{$ENDIF}

  // Shows the cursor
procedure TMPCustomSyntaxMemo.ShowCaret;
var
  N, ScreenRow: Integer;
  Cp: TPoint;
begin
  if (Lines.Count = 0) then
    begin
      N := CharPosToPixOffset(Range.PosX, Range.PosY);
      Cp := PixOffsetToWndOffsetEx(N, ScreenRow);
      Cp.Y := 0;
      { DONE : Thanks Defm. }
      with TextRowRect[ScreenRow] do // new
        if InRange(Cp.X, Left, Right - 1) then
          begin // new
            Windows.SetCaretPos(Cp.X, Cp.Y);
            Windows.ShowCaret(Handle);
            fCaretVisible := True;
          end; // new

      { Windows.SetCaretPos(1, 1);
      Windows.ShowCaret(Handle);
      fCaretVisible := True; }
    end
  else if (THackStrings(Lines).UpdateCount = 0) and { TODO : D5 }
  (Lines.IsValidLineIndex(Range.PosY) and IsLineVisible(Range.PosY, @ScreenRow)) then
      begin
        N := CharPosToPixOffset(Range.PosX, Range.PosY);
        Cp := PixOffsetToWndOffsetEx(N, ScreenRow);
        { DONE : Thanks Defm. }
        with TextRowRect[ScreenRow] do // new
          if InRange(Cp.X, Left, Right - 1) then
            begin // new
              Windows.SetCaretPos(Cp.X, Cp.Y);
              Windows.ShowCaret(Handle);
              fCaretVisible := True;
            end; // new
      end;
end;

// RangeRowToScreenRow() Converts a real line index to a screen one, honoring sections.
// If there are no screen coordinates (above the text top), returns -1
// If the line is not visible (in a collapsed section), returns -2;
// If the line is below the text bottom, returns -3
// Returns the line index relative to the top screen line.
function TMPCustomSyntaxMemo.RangeRowToScreenRow(const Row: Integer): Integer;
begin
  // The real line index must be greater than or equal to the OffsetY offset index,
  // otherwise it is surely not visible on screen + the line must NOT be latent [loLatent]
  if Row < OffsetY then
    Result := ROW_ABOVE_SCREEN
  else if fLines.Parser[Row].VisibleIndex < 0 then
    Result := ROW_HIDEN
  else
    begin
      Result := RowIndexConvert(Row, cdNeedScreen) - RowIndexConvert(OffsetY, cdNeedScreen);
      if Result >= ClientLines then
        Result := ROW_BELOW_SCREEN;
    end;
end;

// FindVisibleRow() Finds a visible line Delta visible lines away from the given one.
// Delta may be >=0 or <0.
// If EnsureInRange = True, the result is ALWAYS within the text,
// otherwise when going beyond the text, the function returns -1
function TMPCustomSyntaxMemo.FindVisibleRow(const Row, Delta: Integer; const EnsureInRange: Boolean): Integer;
var
  N: Integer;
begin
  // Visible index of the target line
  N := RowIndexConvert(Row, cdNeedScreen) + Delta;
  if EnsureInRange then
    N := EnsureRange(N, 0, fSections.Indexes.Count - 1);
  Result := RowIndexConvert(N, cdNeedReal);
end;

// RowIndexConvert() Converts a visible line index to a real one and vice versa
function TMPCustomSyntaxMemo.RowIndexConvert(const Index: Integer; const Direction: TRowIndexConvertionDirection): Integer;
begin
  Result := -1;
  case Direction of
    cdNeedReal:
      if InRange(Index, 0, fSections.Indexes.Count - 1) then
        Result := Integer(fSections.Indexes[Index]);

    cdNeedScreen:
      if fLines.IsValidLineIndex(Index) then
        Result := fLines.Parser[Index].VisibleIndex;
  end;
end;

// Updates the component ScrollBars based on the text content
// and the current cursor position
procedure TMPCustomSyntaxMemo.UpdateScrollBars;
var
  i, MaxLine: Integer;
begin
  { } {$IFDEF SYNDEBUG}
  { } Log('Memo.UpdateScrollBars');
  { } {$ENDIF}
  // Exit if there is no owner or in batch update mode
  if (Parent = nil) or (THackStrings(Lines).UpdateCount > 0) then
    Exit;
  { TODO : D5a }
  // Temporarily lock the vertical scroll while updating it
  fVScroll.OnChange := nil;
  with fVScroll do
    begin
      Max := Math.Max(fSections.Indexes.Count - ClientLines, 0);
      Enabled := Max > 0;
      if fLines.Count = 0 then
        Position := 0
      else
        Position := RowIndexConvert(OffsetY, cdNeedScreen);
      SmallChange := 1;
      LargeChange := ClientLines - 2;
    end;

  if fPageUpDown <> nil then
    fPageUpDown.Enabled := (fSections.Indexes.Count > ClientLines);

  // Temporarily lock the horizontal scroll while updating it
  fHScroll.OnChange := nil;
  with fHScroll do
    begin
      MaxLine := 0;
      for i := 0 to fLines.Count - 1 do
        if Length(fLines[i]) > MaxLine then
          MaxLine := Length(fLines[i]);
      // SLAB - 10 picked out of thin air
      with TextRowRect[-1] do
        Max := Math.Max(MaxLine * 10 - (Right - Left), 0);
      Enabled := Max > 0;
      Position := OffsetXPix;
      SmallChange := 1;
      LargeChange := 32;
    end;

  // Restore everything
  fVScroll.OnChange := ScrollClick;
  fHScroll.OnChange := ScrollClick;
end;

// Click on the scrollbar
procedure TMPCustomSyntaxMemo.ScrollClick(Sender: TObject);
begin
  if Sender = fVScroll then
    OffsetY := RowIndexConvert(fVScroll.Position, cdNeedReal)
  else
    OffsetXPix := fHScroll.Position;
end;

// SetOffset() Sets both text offsets at once
// (to reduce the number of repaints)
procedure TMPCustomSyntaxMemo.SetOffsets(NewOffsets: TPoint);
begin
  { } {$IFDEF SYNDEBUG}
  { } LogFmt('Memo.SetOffsets Pix=%d; Row=%d', [NewOffsets.X, NewOffsets.Y]);
  { } {$ENDIF}
  { Check that the new offsets are valid }
  // OffsetXPix
  if NewOffsets.X <> fOffsets.X then
    NewOffsets.X := EnsureRange(NewOffsets.X, 0, fHScroll.Max);
  // OffsetY
  if NewOffsets.Y <> fOffsets.Y then
    begin
      NewOffsets.Y := EnsureRange(RowIndexConvert(NewOffsets.Y, cdNeedScreen), 0, fVScroll.Max);
      NewOffsets.Y := RowIndexConvert(NewOffsets.Y, cdNeedReal);
    end;
  { Check changed values and repaint if it is REALLY needed }
  if (NewOffsets.X <> fOffsets.X) or (NewOffsets.Y <> fOffsets.Y) then
    begin
      fOffsets := NewOffsets;
      NeedRedrawAll;
      UpdateScrollBars;
    end;
end;

// SetOffset() Sets the text offset relative to the component window
// separately for vertical or horizontal.
procedure TMPCustomSyntaxMemo.SetOffset(const Index, Value: Integer);
begin
  case Index of
    0: SetOffsets(Point(Value, fOffsets.Y));
    1: SetOffsets(Point(fOffsets.X, Value));
  end;
end;

// Reset() Resets parameters
procedure TMPCustomSyntaxMemo.Reset;
begin
{$IFDEF SYNDEBUG}
  Log('Reset');
{$ENDIF}
  { Self }
  fOffsets := Point(0, 0);
  fDown := False;
  fPanning := False;
  // fOptions        := fOptions - [smoOverwrite, smoReadOnly];
  fBookMarks.Clear;
  { Range }
  fRange.fPos := fOffsets;
  fRange.fStart := fOffsets;
  fRange.fEnd := fOffsets;
  fRange.fSealing := True;
  fRange.fUndoStack.Clear;
end;

// SetOption() Sets an option
procedure TMPCustomSyntaxMemo.SetOptions(const Value: TMPSynMemoOptions);
var
  oi: TMPSynMemoOption;
  os: TMPSynMemoOptions;
  New: Boolean;
begin
  if fOptions <> Value then
    begin
      // Actually change the option
      os := fOptions;
      fOptions := Value;
      // Handle the change of each option
      for oi := Low(TMPSynMemoOption) to High(TMPSynMemoOption) do
        if [oi] * os <> [oi] * Value then
          begin
            New := oi in Value;
            case oi of
              { File name display options }
              smoShowFileNameInTabSheet, smoShowFileNameInFormCaption:
                if New then
                  fLines.FileName := fLines.FileName;
              { Gutter width change option }
              smoAutoGutterWidth, smoHighlightLine, smoSolidSpecialLine, smoVSNET_SectionsStyle: NeedRedrawAll;
              smoShowCursorPos:
                begin
                  CreateDestroyCursorPos;
                  CalcScreenParams;
                end;
              smoShowPageScroll:
                begin
                  CreateDestroyPageUpDown;
                  CalcScreenParams;
                end;
            end;
          end;
      if (smoBreakPointsNeedPosibility in Value) then
        fBreakPoints.Mode := bmNeedPosibility
      else
        fBreakPoints.Mode := bmFreeMode;

      // Confirm the change
      Change([ciOptions]);
    end;
end;

// Fires the user change event
procedure TMPCustomSyntaxMemo.Change(const ChangedItems: TChangedItems);
begin
  // If the parameter is empty [], changes are reset
  if ChangedItems = [] then
    fChangesSummator := []
  else
    begin
      // Accumulate changes
      fChangesSummator := fChangesSummator + ChangedItems;
      // If changes are not locked, fire the user event
      // with all accumulated changes

      if THackStrings(fLines).UpdateCount = 0 then
        begin
          if Assigned(fOnChange) then
            fOnChange(Self, fChangesSummator);
          // Reset changes so they do not repeat
          fChangesSummator := [];
        end;
    end;
  { if FProposalForm.Visible then
    begin
    //  FProposalForm.BringToFront;
    FProposalForm.Hide;
    FProposalForm.Show
    end }
end;

{$IFDEF SYNDEBUG}

// Component log for debugging
procedure TMPCustomSyntaxMemo.Log(const LogString: string);
begin
  if LogString = '' then
    fLogDisabled := True
  else if fLogDisabled then
    fLogDisabled := False
  else if Assigned(fOnLog) then
    fOnLog(Self, StringOfChar(' ', Lines.UpdateCount * 2) + LogString);
end;

procedure TMPCustomSyntaxMemo.LogFmt(const LogFormat: string; LogArgs: array of const);
begin
  Log(Format(LogFormat, LogArgs));
end;
{$ENDIF}

// Mark the line as needing repaint
procedure TMPCustomSyntaxMemo.NeedRedraw(const Row: Integer);
var
  Index: Integer;
begin
  if Parent = nil then
    Exit;
  { } {$IFDEF SYNDEBUG}
  { } LogFmt('Memo.NeedRedraw %d', [Row]);
  { } {$ENDIF}
  // Only mark lines for repaint
  if IsLineVisible(Row, @Index) then
    fScreenLines[Index] := True;
  // Try to repaint
  ReDraw;
end;

// Mark for repaint all lines at or below the given one
procedure TMPCustomSyntaxMemo.NeedReDrawLE(const Row: Integer);
var
  Index: Integer;
begin
  if Parent = nil then
    Exit;
  { } {$IFDEF SYNDEBUG}
  { } LogFmt('Memo.NeedRedrawLE %d', [Row]);
  { } {$ENDIF}
  // Only mark lines for repaint
  if IsLineVisible(Row, @Index) then
    while Index <= High(fScreenLines) do
      begin
        fScreenLines[Index] := True;
        Inc(Index);
      end;
  // Try to repaint
  ReDraw;
end;

// Mark all lines for repaint
procedure TMPCustomSyntaxMemo.NeedRedrawAll;
var
  i: Integer;
begin
  { } {$IFDEF SYNDEBUG}
  { } Log('Memo.NeedRedrawAll');
  { } {$ENDIF}
  for i := Low(fScreenLines) to High(fScreenLines) do
    fScreenLines[i] := True;
  // Try to repaint
  ReDraw;
end;

// Screen repaint - repaint only lines marked for repaint
procedure TMPCustomSyntaxMemo.ReDraw;
var
  i: Integer;
begin
  if (Parent = nil) { or (THackStrings(Lines).UpdateCount > 0) } then
    Exit;
  { } {$IFDEF SYNDEBUG}
  { } Log('Memo.Redraw');
  { } {$ENDIF}
  HideCaret;
  for i := Low(fScreenLines) to High(fScreenLines) do
    if fScreenLines[i] then
      begin
        PaintLineEx3(i, FindVisibleRow(OffsetY, i, False));
        fScreenLines[i] := False;
      end;
  ShowCaret;
end;

// Sets the new default text/background color
procedure TMPCustomSyntaxMemo.SetDefColor(const Index: Integer; const Value: TColor);
begin
  case Index of
    0: fDefBackColor := Value;
    1: fDefForeColor := Value;
    2: fBPEnabledBackColor := Value;
    3: fBPEnabledForeColor := Value;
    4: fBPDisabledBackColor := Value;
    5: fBPDisabledForeColor := Value;
    6: fDebugBackColor := Value;
    7: fDebugForeColor := Value;
    8: fSelectedWordColor := Value;
  end;
  Invalidate;
end;

procedure TMPCustomSyntaxMemo.PaintLineEx3(const ScreenRow, Row: Integer);
var
  Sp: TMPSyntaxParser;
  TextIndent, SelStart, SelEnd: Integer;
  ClipRgn: HRGN;
  r: TRect;

begin
  // If the component is not visible - why repaint it?
  if not Visible then
    Exit;

  { } {$IFDEF SYNDEBUG}
  { } LogFmt('Memo.PaintLineEx3 %d as %d', [ScreenRow, Row]);
  { } {$ENDIF}
  // Draw the gutter
  PaintGutter(fBuffer.Canvas, Row, ScreenRow);

  // If the line number is invalid (lines after the text),
  // just erase everything and exit
  if Lines.IsValidLineIndex(Row) then
    begin
      // Section markers
      PaintSectionMarks(fBuffer.Canvas, Row, ScreenRow);
      // Offset for the line start (X <= default_offset !!!)
      TextIndent := PixOffsetToWndOffsetEx(0, ScreenRow).X;
      // Create a temporary helper parser as a clone of the existing line parser

      // Sp := TMPSyntaxParser.Create( Lines.Parser[Row] );
      Sp := FCurParser;
      Sp.Assign(Lines.Parser[Row]);
      // Group adjacent tokens (ON THE COPY!!)
      Sp.GroupTokens;

      // Adjust it based on selection info
      if not fRange.IsEmpty() and InRange(Row, fRange.StartY, fRange.EndY) then
        begin
          SelStart := IfThen(Row = fRange.StartY, fRange.StartX, -1);
          SelEnd := IfThen(Row = fRange.EndY, fRange.EndX, MaxInt);
          Sp.SplitTokens(SelStart, SelEnd);
        end
      else
        begin
          SelStart := 0;
          SelEnd := 0;
        end;
      // Calculate and set the Clip Region for the text canvas
      // clip out the gutter, otherwise text overlaps it when OffsetXPix > 0
      with TextRowRect[ScreenRow] do
        ClipRgn := CreateRectRgn(Left, 0, Right, Bottom - Top);
      SelectClipRgn(fBuffer.Canvas.Handle, ClipRgn);
      // Draw the line
      PaintTokens(fBuffer.Canvas, Lines[Row], Sp, Row, TextIndent, SelStart, SelEnd);
      // If the line is the first line of a collapsed section,
      // draw the collapse mark (ellipsis right of the text)
      if fSections.Section[Row].Collapsed then
        PaintDots(fBuffer.Canvas);

      // If the line has a BP - mark it with a red frame
      if (fBreakPoints.IsBreakPoint[Row]) and (fBreakPoints.BreakPoint[Row].kind <> bkPosible) then
        begin

          r.Left := TextIndent + CharPosToPixOffset(0, Row);
          r.Right := Width;
          // TextIndent + CharPosToPixOffset(Length(Lines[Row]), Row);
          r.Top := 0;
          r.Bottom := fCharHeight;
          if fBreakPoints.BreakPoint[Row].kind = bkEnabled then
            fBuffer.Canvas.Brush.Color := fBPEnabledBackColor
          else
            fBuffer.Canvas.Brush.Color := fBPDisabledBackColor;
          fBuffer.Canvas.FrameRect(r);
        end;

      // If the line is the step-debug line - mark it
      if Row = fStepDebugLine then
        begin
          r.Left := TextIndent + CharPosToPixOffset(0, Row);
          r.Right := Width;
          // TextIndent + CharPosToPixOffset(Length(Lines[Row]), Row);
          r.Top := 0;
          r.Bottom := fCharHeight;
          fBuffer.Canvas.Brush.Color := fDebugBackColor;
          fBuffer.Canvas.FrameRect(r);
        end;

      // If the line contains the highlighted word - mark it
      if fSelWord.Y = Row then
        if fLines.Parser[Row].Count > fSelWord.X then

          with fLines.Parser[Row].Tokens[fSelWord.X] do
            begin
              r.Left := TextIndent + CharPosToPixOffset(stStart, Row) - 1;
              r.Right := TextIndent + CharPosToPixOffset
                (stStart + stLength, Row) + 1;
              r.Top := 0;
              r.Bottom := fCharHeight;
              fBuffer.Canvas.Brush.Color := fSelectedWordColor;
              /// !!!"Red" frame!
              fBuffer.Canvas.FrameRect(r);

              r.Left := TextIndent + CharPosToPixOffset(stStart, Row);
              r.Right := TextIndent + CharPosToPixOffset(stStart + stLength, Row);
              r.Top := 1;
              r.Bottom := fCharHeight - 1;
              fBuffer.Canvas.FrameRect(r);
            end;

      // Remove the Clip Region for the line canvas
      SelectClipRgn(fBuffer.Canvas.Handle, 0);
      DeleteObject(ClipRgn);
      // Destroy the helper token list
      // FreeParser(Sp)
      // Sp.Free;
    end;
  // Draw the buffer
  with EntireRowRect[ScreenRow] do
    BitBlt(Canvas.Handle, 0, Top, Right - Left, Bottom - Top, fBuffer.Canvas.Handle, 0, 0, SRCCOPY)
end;

// Draw the gutter and clear the line
procedure TMPCustomSyntaxMemo.PaintGutter(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
var
  RR, GR, r: TRect;
  i: TBookmarkIndex;
  kind: TBPKind;
  StrNumRow: string;
begin
  RR := TextRowRect[ScreenRow];
  dec(RR.Bottom, RR.Top);
  RR.Top := 0;

  GR := EntireGutterRect[ScreenRow];
  dec(GR.Bottom, GR.Top);
  GR.Top := 0;

  // Left gutter
  with ACanvas do
    begin
      r := GR;
      Brush.Style := bsSolid;
      Brush.Color := clBtnFace;
      if not(smoVSNET_SectionsStyle in fOptions) then
        dec(r.Right, 4)
      else
        dec(r.Right, fSectionIndent + 4);
      FillRect(r);
      Pen.Color := clBtnHighlight;
      MoveTo(r.Right, r.Top);
      LineTo(r.Right, r.Bottom);
      Inc(r.Right);
      Pen.Color := clBtnShadow;
      MoveTo(r.Right, r.Top);
      LineTo(r.Right, r.Bottom);
      Inc(r.Right);
      Brush.Color := Self.Color;
      r.Left := r.Right;
      r.Right := GR.Right;
      FillRect(r);
      FillRect(RR);
      if not Lines.IsValidLineIndex(Row) then
        Exit;
      // Bookmark
      if fBookMarks.Find(Row, i) then
        fBookMarks.PaintAt(ACanvas, GR.Left + 9, GR.Top + 2, i);
      // BreakPoints
      if fBreakPoints.Find(Row, kind) then
        fBreakPoints.PaintAt(ACanvas, GR.Left + 2, GR.Top + 2, kind);
      StrNumRow := IntToStr(Row + 1);
      Font.Color := clBlack;
      if smoShowLineNumberToGutter in Options then
        TextOut(GR.Right - fCharWidths[False]['1'] * (Length(StrNumRow) + 1), GR.Top + 2, StrNumRow)
    end;
end;

// Draw section markers
procedure TMPCustomSyntaxMemo.PaintSectionMarks(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
var
  SecPnt: TPoint;
  Sec: TMPSynMemoSection;
  MR, RR, GR: TRect;
  i: Integer;
begin
  RR := TextRowRect[ScreenRow];
  dec(RR.Bottom, RR.Top);
  RR.Top := 0;

  GR := EntireGutterRect[ScreenRow];
  dec(GR.Bottom, GR.Top);
  GR.Top := 0;

  Sec := fSections.Section[Row];
  MR := GetSectionButtonRect(ScreenRow, Sec.Level);
  dec(MR.Top, EntireRowRect[ScreenRow].Top);
  dec(MR.Bottom, EntireRowRect[ScreenRow].Top);
  SecPnt := CenterPoint(MR);

  with ACanvas do
    begin
      if Sec.RowBeg = Row then
        begin
          // Section start - draw the box
          if Sec.Collapsed then
            begin
              Brush.Color := clWhite;
              Pen.Color := clBlack;
              Rectangle(MR);
            end
          else
            begin
              Brush.Color := clBlack;
              FrameRect(MR);
            end;
          Pen.Color := clBlack;
          with MR do
            begin
              MoveTo(Left + 2, SecPnt.Y);
              LineTo(Right - 2, SecPnt.Y);
              if Sec.Collapsed then
                begin
                  MoveTo(SecPnt.X, Top + 2);
                  LineTo(SecPnt.X, Bottom - 2);
                end;
              Pen.Color := clDkGray;
              // Line to the right of the box
              MoveTo(Right, SecPnt.Y);
              LineTo(GR.Right - 2, SecPnt.Y);
              if not Sec.Collapsed then
                begin
                  // Line below the box
                  MoveTo(SecPnt.X, Bottom);
                  LineTo(SecPnt.X, GR.Bottom);
                end;
            end;
        end
      else

        // Section end - draw a horizontal tick
        if Sec.RowEnd = Row then
          begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, GR.Top);
            LineTo(SecPnt.X, SecPnt.Y);
            LineTo(GR.Right - 2, SecPnt.Y);
          end
        else

          // Plain line belonging to a non-root section
          if Sec.Level > 0 then
            begin
              Pen.Color := clDkGray;
              MoveTo(SecPnt.X, GR.Top);
              LineTo(SecPnt.X, GR.Bottom);
            end;

      // Draw the vertical lines of parent sections
      // only NOT FOR MS VS NET emulation mode
      if not(smoVSNET_SectionsStyle in fOptions) then
        for i := Sec.Level - 1 downto 1 do
          begin
            dec(SecPnt.X, fSectionIndent);
            MoveTo(SecPnt.X, GR.Top);
            LineTo(SecPnt.X, GR.Bottom);
          end;
    end;
end;

// Draws the ellipsis right of the text
procedure TMPCustomSyntaxMemo.PaintDots(const ACanvas: TCanvas);
var
  r: TRect;
begin
  with ACanvas do
    begin
      r := ClipRect;
      r.Left := r.Right - 33;
      Brush.Style := bsSolid;
      Brush.Color := Self.Color;
      FillRect(r);
      with ClipRect do
        r := Rect(Right - 32, Top + 1, Right - 10, Bottom - 1);
      Brush.Color := clBlue;
      FrameRect(r);
      r := Bounds(r.Left + 5, r.Top + 8, 2, 2);
      FillRect(r);
      OffsetRect(r, 5, 0);
      FillRect(r);
      OffsetRect(r, 5, 0);
      FillRect(r);
    end;
end;

// Draws a syntax-highlighted line on the given canvas
procedure TMPCustomSyntaxMemo.PaintTokens(const ACanvas: TCanvas; s: string;
  Sp: TMPSyntaxParser; Row, TextIndent, SelStart, SelEnd: Integer);
var
  wi, CharPos, i: Integer;
  Col, ErrCol: TColor;
  r: TRect;
begin
  with ACanvas do
    begin
      r := ClipRect;
      // Draw the background
      Brush.Style := bsSolid;
      for wi := 0 to Sp.Count - 1 do
        with Sp[wi] do
          begin

            Col := fParseAttributes.BackColor[stToken];
            if (smoSolidSpecialLine in fOptions) and (fBreakPoints.IsBreakPoint[Row]
              ) and (fBreakPoints.BreakPoint[Row].kind <> bkPosible) then
              begin
                if fBreakPoints.BreakPoint[Row].kind = bkEnabled then
                  Col := fBPEnabledBackColor
                else
                  Col := fBPDisabledBackColor;
              end;
            if (smoSolidSpecialLine in fOptions) and (StepDebugLine = Row) then
              Col := fDebugBackColor;

            if (Col <> clDefault) and not(stsInSelection in stStyle) then
              begin
                if { ((smoHighlightLine in fOptions)and(stToken in [tokILCompDir]))or }
                  ((smoSolidSpecialLine in fOptions) and
                    ((fBreakPoints.IsBreakPoint[Row]) or (StepDebugLine = Row))) then
                  r.Left := 0
                else
                  r.Left := TextIndent + CharPosToPixOffset(stStart, s, Sp);
                if ((smoHighlightLine in fOptions) and (stToken in [tokILComment, tokILCompDir, tokMLCommentBeg,
                  tokELCommentBeg, tokMLCompDirBeg])) or ((smoSolidSpecialLine in fOptions) and
                  ((fBreakPoints.IsBreakPoint[Row]) or (StepDebugLine = Row))) then
                  r.Right := Width
                // TextIndent + CharPosToPixOffset(stStart + stLength, s, Sp);
                else
                  r.Right := TextIndent + CharPosToPixOffset
                    (stStart + stLength, s, Sp);
                Brush.Color := Col;
                FillRect(r);
              end;
          end;
      // Draw the selection background
      if SelStart <> SelEnd then
        begin
          r.Left := TextIndent;
          if SelStart > 0 then
            Inc(r.Left, CharPosToPixOffset(fRange.StartX, s, Sp));
          if SelEnd < MaxInt then
            r.Right := TextIndent + CharPosToPixOffset(fRange.EndX, s, Sp)
          else
            r.Right := ClipRect.Right;
          Brush.Color := fSelColor;
          FillRect(r);
        end;
      // Draw all words one by one
      Brush.Style := bsClear;
      Font.Assign(Self.Font);
      PenPos := Point(TextIndent, 0);
      CharPos := 0;
      for wi := 0 to Sp.Count - 1 do
        with Sp[wi] do
          begin
            with fParseAttributes.fTokenStyles[stToken] do
              begin
                Font.Style := tsStyle;
                if stsInSelection in stStyle then
                  Font.Color := clBlack
                else if tsForeground = clDefault then
                  Font.Color := fDefForeColor
                else
                  Font.Color := tsForeground;
                if (smoSolidSpecialLine in fOptions) then
                  begin
                    if (fBreakPoints.IsBreakPoint[Row]) and (fBreakPoints.BreakPoint[Row].kind <> bkPosible) then
                      begin
                        if fBreakPoints.BreakPoint[Row].kind = bkEnabled then
                          Font.Color := fBPEnabledForeColor
                        else
                          Font.Color := fBPDisabledForeColor;
                      end;
                    if StepDebugLine = Row then
                      Font.Color := fDebugForeColor;
                  end;
              end;
            r.TopLeft := PenPos;
            Inc(r.Left, (stStart - CharPos) * fCharWidths[False][' ']);
            (* // Hook up the user event
          if (stToken = tokCustomDraw) and Assigned(fOnDrawWord) then
          R.BottomRight := Point(TextIndent + CharPosToPixOffset(stStart+stLength, s, Sp), fCharHeight);
          fOnDrawWord(self, ACanvas, R, Row, wi);
          end; *)
            TextOut(r.Left, r.Top, Copy(s, stStart + 1, stLength));

            // If there is an error - underline it
            if (stToken = tokErroneous) or (stToken = tokErroneous2) then
              begin
                ErrCol := clRed;
                if stToken = tokErroneous2 then
                  ErrCol := clGreen;
                r.Left := TextIndent + CharPosToPixOffset(stStart, s, Sp);
                r.Right := TextIndent + CharPosToPixOffset(stStart + stLength, s, Sp);
                for i := r.Left to r.Right do
                  case (i mod 4) of
                    0, 2: Pixels[i, r.Bottom - 2] := ErrCol;
                    1: Pixels[i, r.Bottom - 3] := ErrCol;
                    3: Pixels[i, r.Bottom - 1] := ErrCol;
                  end;
              end;
            CharPos := stStart + stLength;
          end;
    end;
end;

{ Proposal support }

function TMPCustomSyntaxMemo.GetCurrentWord(PartOnly: Boolean): string;
var
  i, XPos, YPos: Integer;
  CurParser: TMPSyntaxParser;
begin
  Result := '';
  if Range.PosY < Lines.Count then
    begin
      XPos := Range.PosX;
      YPos := Range.PosY;
      CurParser := Lines.Parser[YPos];
      for i := CurParser.Count - 1 downto 0 do
        if (XPos > CurParser[i].stStart) and (XPos <= CurParser[i].stStart + CurParser[i].stLength) then
          begin
            if PartOnly then
              Result := Copy(Lines[YPos], CurParser[i].stStart + 1, XPos - CurParser[i].stStart)
            else
              Result := Copy(Lines[YPos], CurParser[i].stStart + 1, CurParser[i].stLength);
            Break
          end;

      { if not PartOnly then
      while (Length(Result)=0) and (YPos>=0) do
      begin
      if Length(Lines[YPos])=0 then
      Dec(YPos)
      else
      begin
      CurParser:=Lines.Parser[YPos];
      if CurParser.Count>0 then
      Result:=Copy(Lines[YPos],CurParser[CurParser.Count-1].stStart+1,CurParser[CurParser.Count-1].stLength);
      end
      end }
    end;
end;

procedure TMPCustomSyntaxMemo.ReplaceCurrentWord(DestStr: string);
var
  i, XPos: Integer;
  CurParser: TMPSyntaxParser;
  s: string;
  Success: Boolean;
  NewPos: Integer;
begin

  // For Proposal
  NewPos := Pos('|', DestStr);
  if NewPos > 0 then
    begin
      Delete(DestStr, NewPos, 1);
      NewPos := Length(DestStr) - NewPos + 1;

    end;

  if Range.PosY < Lines.Count then
    begin
      Success := False;
      XPos := Range.PosX;

      CurParser := Lines.Parser[Range.PosY];
      if CurParser.Count = 0 then
        begin
          Range.SetTextEx(DestStr, ukRangeInserted);
          Success := True
        end
      else
        for i := 0 to CurParser.Count - 1 do
          if (XPos >= CurParser[i].stStart) and (XPos <= CurParser[i].stStart + CurParser[i].stLength) then
            begin
              Success := True;
              // ~ xPos:=CurParser[i].stStart;
              s := Lines[Range.PosY];

              if not(CurParser[i].stToken in [tokEndLine, tokParenBeg, tokParenEnd,
                tokBrackedBeg, tokBracketEnd, tokOperator, tokComma, tokPoint]

              ) then
                begin
                  // Range.EndX  :=CurParser[i].stStart+CurParser[i].stLength
                  Range.StartX := CurParser[i].stStart;
                  Range.EndX := Range.StartX + CurParser[i].stLength
                end
              else
                begin
                  // Range.StartX:=Range.StartX+1;
                  Range.EndX := Range.StartX;
                end;
              if CurParser[i].stToken = tokText then
                begin
                  Range.SetTextEx('', ukRangeDeleted);
                  Range.SetTextEx(DestStr, ukRangeInserted);
                end
              else
                begin
                  // Range.PosX:=Range.PosX+1;
                  Range.SetTextEx(DestStr, ukRangeInserted);
                end;
              Break
            end
    end
  else if Range.PosY = 0 then
    begin
      Success := True;
      Range.SetTextEx(DestStr, ukRangeInserted);
    end;
  if not Success then
    begin
      Range.SetTextEx(DestStr, ukRangeInserted);
    end;

  if NewPos > 0 then
    begin
      // Range.PosX:=Range.PosX-NewPos
      Range.Enlarge(-NewPos);
      Range.EndX := Range.StartX

    end;
end;

procedure TMPCustomSyntaxMemo.SetProposalItems(PI: TMPProposalItems);
begin
  FProposalForm.ChangeItems(PI);
end;

procedure TMPCustomSyntaxMemo.ClearProposal;
var
  c: TMPProposalItems;
begin
  c[0] := nil;
  c[1] := nil;
  FProposalForm.ChangeItems(c)
end;

procedure TMPCustomSyntaxMemo.AddToCurrentProposal(ts, ts1: TStrings);
begin
  FProposalForm.FItemList.AddStrings(ts);
  FProposalForm.FInsertList.AddStrings(ts1);
end;

procedure TMPCustomSyntaxMemo.SaveProposals(const aName: string);
begin
  FProposalForm.SaveProposals(aName);
end;

procedure TMPCustomSyntaxMemo.ApplyProposal(const aName: string);
begin
  FProposalForm.ApplyProposal(aName)
end;

procedure TMPCustomSyntaxMemo.AddProposal(const aName: string);
begin
  FProposalForm.AddProposal(aName);
end;

function TMPCustomSyntaxMemo.GetCurProposalName: string;
begin
  Result := FProposalForm.FCurProposalName
end;

{ TBookmarkManager }

// Constructor
constructor TMPBookmarkManager.Create(Owner: TMPCustomSyntaxMemo);
begin
  inherited Create;
  fRichMemo := Owner;
  fImages := TBitmap.Create;
  fImages.LoadFromResourceName(HInstance, 'BOOKMARKS');
  Clear;
end;

// Destructor
destructor TMPBookmarkManager.Destroy;
begin
  fImages.Free;
  inherited;
end;

// Resets bookmark info
procedure TMPBookmarkManager.Clear;
var
  i: TBookmarkIndex;
begin
  for i := Low(TBookmarkIndex) to High(TBookmarkIndex) do
    fBookMarks[i] := -1;
end;

// Returns
function TMPBookmarkManager.Find(const Row: Integer; var Index: TBookmarkIndex): Boolean;
var
  i: TBookmarkIndex;
begin
  for i := Low(TBookmarkIndex) to High(TBookmarkIndex) do
    if fBookMarks[i] = Row then
      begin
        Result := True;
        Index := i;
        Exit;
      end;
  Result := False;
end;

// Returns a bookmark
function TMPBookmarkManager.GetBookMarks(const Index: TBookmarkIndex): Integer;
begin
  Result := fBookMarks[Index];
end;

// Sets a bookmark
procedure TMPBookmarkManager.SetBookMarks(const Index: TBookmarkIndex; const Row: Integer);
{ }
  procedure SetBookMarkInt;
  var
    i: TBookmarkIndex;
    N: Integer;
  begin
    // This line could have had another bookmark..
    if Find(Row, i) then
      begin
        fBookMarks[i] := -1;
        // ..or the same one - in which case just remove it
        if i = Index then
          Exit;
      end;
    // This bookmark could belong to another page
    if fBookMarks[Index] >= 0 then
      begin
        N := fBookMarks[Index];
        fBookMarks[Index] := -1;
        fRichMemo.NeedRedraw(N);
      end;
    // New bookmark
    fBookMarks[Index] := Row;
  end;

begin
  fRichMemo.fLines.BeginUpdate;
  SetBookMarkInt;
  fRichMemo.NeedRedraw(Row);
  fRichMemo.fLines.EndUpdate;
end;

// Draws the donut on the gutter
procedure TMPBookmarkManager.PaintAt(const ACanvas: TCanvas; const X, Y: Integer; const Index: TBookmarkIndex);
const
  BOOKMARK_GLYPH_SIZE = 11;
begin
  BitBlt(ACanvas.Handle, X, Y, BOOKMARK_GLYPH_SIZE, BOOKMARK_GLYPH_SIZE,
    fImages.Canvas.Handle, Index * BOOKMARK_GLYPH_SIZE, 0, SRCCOPY);
end;

procedure TMPCustomSyntaxMemo.CloseProposal;
begin
  fInProposalCall := False;
  FTimer.Enabled := False;
  FProposalForm.Hide;
  SetFocus
end;

procedure TMPCustomSyntaxMemo.ProposalCall;
var
  p: TPoint;
begin
  if Assigned(FBeforeProposalCall) then
    FBeforeProposalCall(CurProposalName);

  FProposalForm.ChangeListText;
  if FProposalForm.FListProp.Items.Count = 0 then
    CloseProposal;

  p := TextPosToScreen(Range.PosX, Range.PosY);
  p := ClientToScreen(p);
  Inc(p.Y, fCharHeight);

  FTimer.Enabled := True;
  FProposalForm.ShowEx(p.X, p.Y);

  fInProposalCall := True
end;

{ TMPSyntaxCompletionProposalForm }

procedure TMPSyntaxCompletionProposalForm.ChangeItems (NewItems: TMPProposalItems);
begin
  FItemList.Clear;
  FInsertList.Clear;
  if NewItems[0] <> nil then
    FItemList.Assign(NewItems[0]);
  if NewItems[1] <> nil then
    FInsertList.Assign(NewItems[1]);
end;

const
  CharsAfterClause  = [' ', #13, #9, #10, #0, ';', '(', '/', '-', '"', '^'];
  CharsBeforeClause = [' ', #10, ')', #9, #13, '"'];
  endLexem = ['+', ')', '(', '*', '/', '|', ',', '=', '>', '<', '-', '!', '^',
    '~', ',', ';', '.'];

procedure TMPSyntaxCompletionProposalForm.ChangeListText;
var
  i: Integer;
  s: string;
begin
  with FListProp.Items do
    begin
      Clear;
      s := TMPCustomSyntaxMemo(Owner).GetCurrentWord(True);
      if (Length(s) > 0) then
        if s[Length(s)] in (CharsAfterClause + endLexem + CharsBeforeClause - ['"']) then
          s := '';
      for i := 0 to Pred(FInsertList.Count) do
        if i < FItemList.Count then
          if Copy(UpperCase(FInsertList[i]), 1, Length(s)) = UpperCase(s) then
            AddObject(FItemList[i], TObject(i));
      if Count = 0 then
        TMPCustomSyntaxMemo(Owner).CloseProposal
      else
        FListProp.ItemIndex := 0
    end;
end;

// @@additional strings@
procedure TMPSyntaxCompletionProposalForm.CompleteProposal;
var
  i: Integer;
  s, s1: string;
  p: Integer;
begin
  s := '';
  with FListProp do
    begin
      for i := 0 to Pred(Items.Count) do
        if Selected[i] then
          s := s + FInsertList[Integer(Items.Objects[i])] + ',';
      if Length(s) > 0 then
        SetLength(s, Length(s) - 1);
    end;

  p := Pos('@@', s);
  if p > 0 then
    begin
      s1 := Copy(s, p + 2, MaxInt);
      SetLength(s, p - 1);
      SetLength(s1, Length(s1) - 1);
      s := s + s1
    end;
  TMPCustomSyntaxMemo(Owner).ReplaceCurrentWord(s);
  TMPCustomSyntaxMemo(Owner).CloseProposal
end;

constructor TMPSyntaxCompletionProposalForm.Create(AOwner: TComponent);
begin
  CreateNew(AOwner);
  FItemList := TStringList.Create;
  FInsertList := TStringList.Create;
  FProposalNames := TStringList.Create;
  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;
  FListProp := TListBox.Create(Self);
  FListProp.Parent := Self;
  FListProp.Visible := True;
  FListProp.Align := alClient;
  FListProp.OnDblClick := ListBoxClick;
  FListProp.OnKeyDown := ListBoxKeyDown;

  FListProp.Style := lbOwnerDrawFixed;

  FListProp.OnDrawItem := ListDrawItem;
  FListProp.DoubleBuffered := True;
  // FListProp.MultiSelect:=True;

  Left := 33;
  Top := 20;
  Width := 300;
  Height := 100;
end;

procedure TMPSyntaxCompletionProposalForm.Deactivate;
begin
  inherited;
  // Visible:=False
end;

destructor TMPSyntaxCompletionProposalForm.Destroy;
begin
  FItemList.Free;
  FInsertList.Free;
  FProposalNames.Free;
  inherited Destroy;
end;

procedure TMPSyntaxCompletionProposalForm.Down;
begin
  if FListProp.ItemIndex < FListProp.Items.Count then
    FListProp.ItemIndex := FListProp.ItemIndex + 1;
end;

procedure TMPSyntaxCompletionProposalForm.ListBoxClick(Sender: TObject);
begin
  CompleteProposal
end;

procedure TMPSyntaxCompletionProposalForm.ListBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN: CompleteProposal;
    VK_ESCAPE:
      begin
        Hide;
        TMPCustomSyntaxMemo(Owner).SetFocus
      end
  end;
end;

procedure TMPSyntaxCompletionProposalForm.PAGEDOWN;
var
  t: Integer;
begin
  SendMessage(FListProp.Handle, WM_VSCROLL, SB_PAGEDOWN, 0);
  t := LoWord(FListProp.Perform(LB_ITEMFROMPOINT, 0, MakeLParam(0, FListProp.ClientHeight)));
  if t >= 0 then
    FListProp.ItemIndex := t
end;

procedure TMPSyntaxCompletionProposalForm.ListDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Offset: Integer; { text offset width }
  s: string;
  s1: string;
  p: Integer;
begin

  with (Control as TListBox).Canvas do { draw on control canvas, not on the form }
    begin
      FillRect(Rect); { clear the rectangle }
      Offset := 2; { provide default offset }
      s := (Control as TListBox).Items[Index];
      p := Pos(ProposalDelimiter, s);
      s1 := Copy(s, 1, p - 2);
      if Length(s) < p + 2 then
        Exit;
      case s[p + 2] of
        'B': Font.Color := clBlue;
        'D': Font.Color := clGray;
        'F': Font.Color := clFuchsia;
        'G': Font.Color := clGreen;
        'M': Font.Color := clMaroon;
        'N': Font.Color := clNavy;
        'O': Font.Color := clOlive;
        'R': Font.Color := clRed;
        'T': Font.Color := clTeal;
      end;
      if odSelected in State then
        begin
          Font.Color := clWhite;
          // Font.Style:=[fsBold];
        end;

      TextOut(Rect.Left + Offset, Rect.Top, s1); { display the text }

      if odSelected in State then
        begin
          Font.Color := clWhite;
          Font.Style := [fsBold];
        end
      else
        begin
          Font.Color := clBlack;
          Font.Style := [fsBold];
        end;

      s := Copy(s, p + 3, MaxInt);

      TextOut(Rect.Left + Offset + TextWidth(s1) + 1, Rect.Top, s);
      { display the text }

      // in
      // TextOut(Rect.Left + Offset, Rect.Top, (Control as TListBox).Items[Index])  { display the text }
    end;
end;

procedure TMPSyntaxCompletionProposalForm.PAGEUP;
var
  t: Integer;
begin
  SendMessage(FListProp.Handle, WM_VSCROLL, SB_PAGEUP, 0);

  t := FListProp.Perform(LB_GETTOPINDEX, 0, 0);
  if t >= 0 then
    FListProp.ItemIndex := t;
end;

procedure TMPSyntaxCompletionProposalForm.ShowEx(X, Y: Integer);
begin
  ChangeListText;
  if FListProp.Items.Count = 0 then
    Exit;
  FListProp.ItemIndex := 0;
  Left := X;
  Top := Y;
  FOwnerPos.X := TMPCustomSyntaxMemo(Owner).ClientOrigin.X;
  FOwnerPos.Y := TMPCustomSyntaxMemo(Owner).ClientOrigin.Y;
  Show;
  TMPCustomSyntaxMemo(Owner).SetFocus
end;

procedure TMPCustomSyntaxMemo.DoOnTimer(Sender: TObject);
begin
  if (not Focused and not FProposalForm.FListProp.Focused and
    FProposalForm.Visible) or (FProposalForm.FOwnerPos.X <> ClientOrigin.X) or
    (FProposalForm.FOwnerPos.Y <> ClientOrigin.Y) then
    begin
      FTimer.Enabled := False;
      FProposalForm.Hide
    end;

end;

procedure TMPSyntaxCompletionProposalForm.ToEnd;
begin
  if FListProp.Items.Count > 0 then
    FListProp.ItemIndex := FListProp.Items.Count - 1
end;

procedure TMPSyntaxCompletionProposalForm.ToHome;
begin
  if FListProp.Items.Count > 0 then
    FListProp.ItemIndex := 0
end;

procedure TMPSyntaxCompletionProposalForm.Up;
begin
  if FListProp.ItemIndex > 0 then
    FListProp.ItemIndex := FListProp.ItemIndex - 1;

end;

procedure TMPSyntaxCompletionProposalForm.ApplyProposal(const aName: string);
var
  i: Integer;
begin
  i := FProposalNames.IndexOf(aName);
  if i > -1 then
    begin
      FItemList.Text := FItems[i];
      FInsertList.Text := FInserts[i];
      FCurProposalName := aName
    end;
end;

procedure TMPSyntaxCompletionProposalForm.SaveProposals(const aName: string);
var
  i: Integer;
begin
  i := FProposalNames.IndexOf(aName);
  if i < 0 then
    i := FProposalNames.Add(aName);

  if Length(FItems) <= i then
    begin
      SetLength(FItems, i + 1);
      SetLength(FInserts, i + 1);
    end;
  FItems[i] := FItemList.Text;
  FInserts[i] := FInsertList.Text;
  FCurProposalName := aName
end;

procedure TMPSyntaxCompletionProposalForm.AddProposal(const aName: string);
var
  i: Integer;
  ts: TStrings;
begin

  i := FProposalNames.IndexOf(aName);
  if i > -1 then
    begin
      ts := TStringList.Create;
      try
        ts.Text := FItems[i];
        FItemList.AddStrings(ts);
        ts.Text := FInserts[i];
        FInsertList.AddStrings(ts);
        FCurProposalName := FCurProposalName + '+' + aName
      finally
        ts.Free
      end
    end;
end;

procedure TMPSyntaxCompletionProposalForm.DoHide;
begin
  inherited;
  if Owner is TMPSyntaxMemo then
    TMPSyntaxMemo(Owner).fInProposalCall := False
end;

initialization

CF_SYNTAX := RegisterClipboardFormat('MP_SYN_MEMO');
DefUserTokenEventProc := nil;
DefProposal[0] := TStringList.Create;
DefProposal[1] := TStringList.Create;

finalization

DefProposal[0].Free;
DefProposal[1].Free

end.
