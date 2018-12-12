
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

{$IFDEF VER130}
  {$IFDEF BCB}			// C++Buider 5.0
  {$ObjExportAll on}
  {$ENDIF}

  {$DEFINE D4+}
  {$DEFINE D5+}
{$ENDIF}

{$IFDEF VER140}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$IFDEF BCB}			// C++Buider 6.0
  {$ObjExportAll on}
  {$ENDIF}
  {$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}

{$IFDEF VER150}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}

  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}

// Probably Delphi 2005 defines
{$IFDEF VER170}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}
  {$DEFINE D9+}

  {$INLINE OFF}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}


{$IFDEF VER180}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}
  {$DEFINE D9+}
  {$DEFINE D10+}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
{$ENDIF}

{$IFDEF VER200}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
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

{$IFDEF VER210}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
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

{$IFDEF VER220}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}
  {$DEFINE D9+} //2006
  {$DEFINE D10+} //2007
  {$DEFINE D11+}//2009
  {$DEFINE D12+}//2010
  {$DEFINE D13+}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
  {$WARNINGS  OFF}
{$ENDIF}

{$IFDEF VER230}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}
  {$DEFINE D9+} //2006
  {$DEFINE D10+} //2007
  {$DEFINE D11+}//2009
  {$DEFINE D12+}//2010
  {$DEFINE D13+}
  {$DEFINE D_XE2}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
  {$WARNINGS  OFF}
{$ENDIF}

{$IFDEF VER240}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}
  {$DEFINE D9+} //2006
  {$DEFINE D10+} //2007
  {$DEFINE D11+}//2009
  {$DEFINE D12+}//2010
  {$DEFINE D13+}
  {$DEFINE D_XE2}
  {$DEFINE D_XE3}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
  {$WARNINGS  OFF}
{$ENDIF}

{$IFDEF VER250}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}
  {$DEFINE D9+} //2006
  {$DEFINE D10+} //2007
  {$DEFINE D11+}//2009
  {$DEFINE D12+}//2010
  {$DEFINE D13+}
  {$DEFINE D_XE2}
  {$DEFINE D_XE3}
  {$DEFINE D_XE4}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
  {$WARNINGS  OFF}
{$ENDIF}

{$IFDEF VER300}
  {$DEFINE D23}
{$ENDIF}

{$IFDEF VER310}
  {$DEFINE D24}
{$ENDIF}

{$IFDEF VER320}
  {$DEFINE D25}
{$ENDIF}

{$IFDEF VER330}
  {$DEFINE D26}
{$ENDIF}

{$IFDEF D26}
  {$DEFINE D25}
{$ENDIF}

{$IFDEF D25}
  {$DEFINE D24}
{$ENDIF}

{$IFDEF D24}
  {$DEFINE D23}
{$ENDIF}

{$IFDEF D23}
  {$DEFINE D4+}
  {$DEFINE D5+}
  {$DEFINE D6+}
  {$DEFINE D7+}
  {$DEFINE D9+} //2006
  {$DEFINE D10+} //2007
  {$DEFINE D11+}//2009
  {$DEFINE D12+}//2010
  {$DEFINE D13+}
  {$DEFINE D_XE2}
  {$DEFINE D_XE3}
  {$DEFINE D_XE4}
  {$WARN UNSAFE_TYPE OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_CAST OFF}
  {$WARN SYMBOL_PLATFORM OFF}
  {$WARNINGS  OFF}
{$ENDIF}

{$I ..\FIBPlus.inc}
{$UNDEF UNICODE}

uses
    Windows, Messages, SysUtils, Classes,
 {$IFDEF D_XE2}
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,  Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls,
  Vcl.StdCtrls,Vcl.Menus,Vcl.Clipbrd,
  {$ELSE}
  Graphics, Controls, Forms,  Dialogs, ComCtrls, ExtCtrls, StdCtrls,Menus,
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

    tokILCompDir    = 23; //Inline Compiler Directive - C-style: #
    tokMLCompDirBeg = 24; //Multyline Compiler Directive - Delphi-style: {$ }
    tokMLCompDirEnd = 25;
    tokChar         = 26;
    tokCharEnd      = 27;

    tokErroneous    = 28;
    tokErroneous2   = 29;

    tokReservedSiO  = 30;


    tokUser         = 255;

    clSkyBlue = TColor($F0CAA6);

 tokWords= [tokText,tokStringEnd,tokString, tokHexValue, tokInteger, tokFloat , tokChar,tokUser];
 var
  tokUserWords : set of byte;

 type
    TMPCustomSyntaxMemo = class;
    TMPSynMemoRange     = class;
    TMPSynMemoSection   = class;
    TMPSynMemoStrings   = class;
    TMPSyntaxParser     = class;
    TMPSyntaxAttributes = class;
    TMPBreakPointCollection = class;

    TMPSyntaxCompletionProposalForm=class;

    EMPSyntaxMemo       = class(Exception);

    // Токен
    TToken              = tokBlank..tokUser;
    PToken              = ^TToken;
    TTokenSet           = set of TToken;
    TCharSet            = set of AnsiChar;

    // Опции парсера
    TParseOption        = (poHasELComment, poHasMLComment, poHasILComment,
                           poHasHexPrefix, poFloatValid, poHasReference,
                           poHasDereference, poBLSeparated, poHasILCompDir,
                           poHasMLCompDir, poHasChar);
    TParseOptions       = set of TParseOption;

    // Пользовательское прерывание определения токена слова
    TUserTokenEvent     = procedure(
        Sender          : TObject;
        Word            : string;
        Pos, Line       : Integer;
        var Token       : TToken
    ) of object;
                                       
    // Тип - массив размеров символов текущего шрифта
    TCharWidths         = array [Boolean] of array [AnsiChar] of Byte;
    //TCharWidths         = array [Boolean] of array [Char] of Byte;

    // Атрибуты визуального выделения токена
    TTokenStyle         = record
                            tsForeground : TColor;          // цвет шрифта
                            tsBackground : TColor;          // цвет фона
                            tsStyle      : TFontStyles;     // стиль шрифта
                          end;

    // Класс, управляющий правилами выделения и визуальными атрибутами токенов
    TMPSyntaxAttributes = class
    private
        fRichMemo       : TMPCustomSyntaxMemo;
        fLitString      : Char;
        fLitChar        : Char;
        fLitILCompDir   : string;
        fLitMLCompDirB  : string;
        fLitMLCompDirE  : string;
        fLitILComment   : string;
        fLitMLCommentB  : string;
        fLitMLCommentE  : string;
        fLitELCommentB  : string;
        fLitELCommentE  : string;
        fLitHexPrefix   : string;
        fLitDecimalPoint: Char;
        fLitReference   : Char;
        fLitDereference : Char;
        fParseOptions   : TParseOptions;
        fTokenStyles    : array [TToken] of TTokenStyle;
        fOnUserToken    : TUserTokenEvent;
        function        GetColor(const Token: TToken; const Index: Integer): TColor;
        function        GetStyle(const Token: TToken): TFontStyles;
        procedure       SetColor(const Token: TToken; const Index: Integer; const Value: TColor);
        procedure       SetStyle(const Token: TToken; const Value: TFontStyles);
    public
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        procedure       Assign(Friend: TMPSyntaxAttributes);
        function        Equals(const T1, T2: TToken): Boolean;
        procedure       SaveToFile(const FileName: string);
        procedure       LoadFromFile(const FileName: string);
        procedure       CopyAttrs(const SrcToken: TToken; DstTokArray: array of TToken);
        property        LiteralString: Char read fLitString write fLitString;
        property        LiteralChar: Char read fLitChar write fLitChar;
        property        LiteralILComment: string read fLitILComment write fLitILComment;
        property        LiteralILCompilerDirective: string read fLitILCompDir write fLitILCompDir;
        property        LiteralMLCompDirBeg: string read fLitMLCompDirB write fLitMLCompDirB;
        property        LiteralMLCompDirEnd: string read fLitMLCompDirE write fLitMLCompDirE;
        property        LiteralMLCommentBeg: string read fLitMLCommentB write fLitMLCommentB;
        property        LiteralMLCommentEnd: string read fLitMLCommentE write fLitMLCommentE;
        property        LiteralELCommentBeg: string read fLitELCommentB write fLitELCommentB;
        property        LiteralELCommentEnd: string read fLitELCommentE write fLitELCommentE;
        property        LiteralHexPrefix: string read fLitHexPrefix write fLitHexPrefix;
        property        LiteralDecimalPoint: Char read fLitDecimalPoint write fLitDecimalPoint;
        property        LiteralReference: Char read fLitReference write fLitReference;
        property        LiteralDereference: Char read fLitDereference write fLitDereference;
        property        ParseOptions: TParseOptions read fParseOptions write fParseOptions;
        property        OnUserToken: TUserTokenEvent read fOnUserToken write fOnUserToken;
        property        FontColor[const Token: TToken]: TColor index 0 read GetColor write SetColor;
        property        BackColor[const Token: TToken]: TColor index 1 read GetColor write SetColor;
        property        FontStyle[const Token: TToken]: TFontStyles read GetStyle write SetStyle;
    end;


    // Слово - токен
    // Параметры слова
    TMPSyntaxTokenStyle = ( stsInSelection,     // слово внутри выделения
                            stsPressed          // слово под нажатым указателем мыши - reserved for future use
                          );
    TMPSyntaxTokenStyles= set of TMPSyntaxTokenStyle;
    TMPSyntaxToken      = class
    public
        stStart         : Word;                     // Начало слова, символов
        stLength        : Word;                     // Длина слова, символов
        stToken         : TToken;                   // Тип (токен) слова
        stStyle         : TMPSyntaxTokenStyles;     // Слово выделено
    end;

    // Синтаксический парсер строки /копию имеет КАЖДАЯ строка текста/
    TMPSyntaxParser     = class (TObjectList)
    private
        fSection        : TMPSynMemoSection;
        fVisibleIndex   : Integer;
        fNeedReparse    : Boolean;
        function        GetToken(const TokIndex: Integer): TMPSyntaxToken;
        procedure       SetToken(const TokIndex: Integer; const Value: TMPSyntaxToken);
    protected
        function        ParseLine(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken; virtual;
        function        ParseLineEx(const Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken; virtual;
    public
        constructor     Create(const AsCloneOf: TMPSyntaxParser = nil);
        procedure       Assign(const Friend: TMPSyntaxParser);
        procedure       Clear; override;
        procedure       AddToken(const Beg, Len: Integer; Token: TToken);
        procedure       GroupTokens;
        procedure       SplitTokens(const sx, ex: Integer);
        function        AsString: string;
        function        LastToken: TToken;
        function        FirstToken: TToken;
        function        Parse(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
        property        Tokens[const TokIndex: Integer]: TMPSyntaxToken read GetToken write SetToken; default;
        property        NeedReparse: Boolean read fNeedReparse write fNeedReparse;
        property        Section: TMPSynMemoSection read fSection write fSection;
        property        VisibleIndex: Integer read fVisibleIndex write fVisibleIndex;
    end;



    { Max Proof Syntax Memo Strings Class }
    // Класс инкапсулирует управление содержанием текста и его синтаксическим анализом
    // с помощью вспомогательного класса TMPSyntaxParser, по экземпляру которого имеет
    // КАЖДАЯ строка текста. Все изменения в тексте сводятся к трем элементарным override
    // процедурам-операторам: Put, Insert и Delete.
    TStringsStateItem   = (
                        ssTextChanged,      // Есть измененные строки
                        ssSectionsChanged,  // Есть измененные секции (New, Explode)
                        ssNeedReIndex,      // Есть измененные секции (Expand, Collapse)
                        ssNeedReparseAll,   // Требуется полный репарсинг строк
                        ssUndoProcess       // В данный момент производится откат
    );
    TStringsState       = set of TStringsStateItem;

    TMPSynMemoStrings    = class(TStringList)
    private
        fRichMemo       : TMPCustomSyntaxMemo;              // Хозяин
        fFileName       : string;                           // Имя файла
        fVirtualFileName: Boolean;                          // Имя файла сгенерировано (не настоящее)
        fState          : TStringsState;                    // Набор состояний
        fModified       : Boolean;                          // Текст изменен
        fDirectAccess   : Boolean;                          // Прямой доступ к тексту
        function        GetParser(const Row: Integer): TMPSyntaxParser;
        procedure       SetModified(const Value: Boolean);
        procedure       SetFileName(const Value: string);
    protected
        procedure       Changed; override;
        procedure       Put(Index: Integer; const s: string); override;
        procedure       SetUpdateState(Updating: Boolean); override;
        function        ParseLine(const Index: Integer; const TestNextLine: Boolean): Boolean; virtual;
        property        State: TStringsState read fState write fState;
    public
        constructor     Create(const Owner: TMPCustomSyntaxMemo);
        procedure       Clear; override;
        function        PositionToRC(Value: Integer): TPoint;
        function        RCToPosition(Col, Row: Integer): Integer;
        procedure       Parse(const EntireText : Boolean; const NeedRepaint: Boolean = False);
        procedure       Delete(Index: Integer); override;
//        procedure       InsertObject(Index: Integer; const s: string; AObject: TObject); override;
        procedure       Insert(Index: Integer; const s: string); override;
        function        Add(const s: string):Integer;  override;        
        procedure       LoadFromStream(Stream: TStream); override;
        procedure       SaveToStream(Stream: TStream); override;
        procedure       LoadFromFile(const NewFileName: string); override;
        procedure       SaveToFile(const NewFileName: string); override;
        procedure       New; virtual;
        function        IsValidLineIndex(const Row: Integer): Boolean;
        property        FileName: string read fFileName write SetFileName;
        property        Parser[const Row: Integer]: TMPSyntaxParser read GetParser;
        property        VirtualFileName: Boolean read fVirtualFileName;
        property        Modified: Boolean read fModified write SetModified;
        property        DirectAccess: Boolean read fDirectAccess write fDirectAccess;
       {$IFDEF D6+}
        property        UpdateCount;
       {$ENDIF}
    end;


    // Класс "Секция текта"
    // Имеет маркеры начала и конца (номера строк), причем в одной строке
    // может "располагаться" только один маркер, неважно какой секции
    TMPSynMemoSection    = class(TObjectList)
    private
        fParent         : TMPSynMemoSection;    // Секция - родитель
        fRowBeg         : Integer;              // Начало диапазона строк хранения
        fRowEnd         : Integer;              // Конец диапазона строк хранения
        fLevel          : Integer;              // Уровень вложенности секции
        fCollapsed      : Boolean;              // Признак того, что секция свернута
        function        GetSections(const Idx: Integer): TMPSynMemoSection;
        procedure       SetLevel(const Value: Integer);
    public
        constructor     Create;
        property        RowBeg: Integer read fRowBeg write fRowBeg;
        property        RowEnd: Integer read fRowEnd write fRowEnd;
        property        Sections[const Idx: Integer]: TMPSynMemoSection read GetSections; default;
        property        Level: Integer read fLevel write SetLevel;
        property        Parent: TMPSynMemoSection read fParent write fParent;
        property        Collapsed: Boolean read fCollapsed write fCollapsed;
    end;

    TMPSMSectionClone   = class(TMPSynMemoSection)
    private
        fRefCount       : Integer;
    protected
        procedure       AddRef;
        procedure       Release;
        procedure       Assign(original:TMPSMSectionClone);
    public
        property        RefCount: Integer read fRefCount;
    end;

    // Section Manager Class
    TSectionMark = (smNone, smExpanded, smCollapsed, smEnd);

    // Класс - менеджер секций.
    // Обеспечивает выполнение высокоуровневых операций с секциями (свернуть, развернуть, создать, разрушить и т.д.)
    // Не обеспечивает откат.
    TMPSynMemoSections   = class(TObject)
    private
        fRichMemo       : TMPCustomSyntaxMemo;          // Хозяин
        fRoot           : TMPSMSectionClone;            // Корневая секция
        fIndexes        : TList;                        // Индексация текста для быстрого доступа к экранным индексам
        fMaxLevel       : Integer;                      // Максимальный уровень вложенности секций
        fMaxExpandLevel : Integer;                      // Максимальный открытый уровень вложенности секций
        fErrorLine      : Integer;                      // Индекс строки текста с нарушением управления секциями
        fErrorString    : string;                       // Ошибка управления секциями
        procedure       ReIndex;
        procedure       MakeUnique;
        procedure       SetRoot(const Value: TMPSMSectionClone);
        function        GetSection(const Row: Integer): TMPSynMemoSection;
        procedure       SetSection(const Row: Integer; Value: TMPSynMemoSection);
    protected
        procedure       Scan; virtual;
        procedure       FillOutput(const Sl: TStringList); virtual;
        procedure       DeleteRow(const Row: Integer); virtual;
        procedure       InsertRow(const Row: Integer); virtual;
    public
        class function  DetectSectionMark(const s: string): TSectionMark;
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        destructor      Destroy; override;
        function        New(const Row1, Row2: Integer; const IsCollapsed: Boolean = False): TMPSynMemoSection;
        procedure       Explode(const Row: Integer; const Recursive: Boolean);
        procedure       Collapse(const Row: Integer; const Recursive, SafeSelf: Boolean);
        procedure       Expand(const Row: Integer; const Recursive, ParentRecursive: Boolean);
        function        SectionBorder(const Row: Integer): TSectionMark;
        function        AsText: string;
        function        Next(Sec: TMPSynMemoSection): TMPSynMemoSection;
        function        Prev(Sec: TMPSynMemoSection): TMPSynMemoSection;
        function        Visible(const Sec: TMPSynMemoSection): Boolean;
        property        Section[const Row: Integer]: TMPSynMemoSection read GetSection write SetSection;
        property        MaxLevel: Integer read fMaxLevel;
        property        ErrorLine: Integer read fErrorLine;
        property        ErrorString: string read fErrorString;
        property        EntireSection: TMPSMSectionClone read fRoot write SetRoot;
        property        Indexes: TList read fIndexes;
    end;


    //Типы операций для группировки UNDO
    TUndoKind=(ukNone,          //Не группируется ни с чем (даже сам с собой) - не для использования в нормальном режиме
               ukLetterTyped,   //Символ введен с клавиатуры
               ukLetterDeleted, //Символ удален с клавиатуры (Delete BackSpace)
               ukRangeInserted, //Вставлен кусок текста (Paste)
               ukRangeDeleted,  //Удален кусок текста (Delete или Cut)
               ukCursorMoved,   //Курсор убежал на другую позицию
               ukBlockCreated,  //Создан новый блок
               ukBlockExploded  //Блок удален
               );
    // Range Class
    TMPSynMemoUndoItem  = class
    public
        uiCaretPos      : TPoint;
        uiSelStart      : TPoint;
        uiSelEnd        : TPoint;
        uiSealing       : Boolean;
        uiText          : string;
        uiSections      : TMPSMSectionClone;
        uiKind          : TUndoKind;
        destructor      Destroy; override;
    end;

    // TMPSynMemoRange
    // Класс является прослойкой между железом исполнительных классов
    // T..Strings, T..Sections и командами пользователя. Основные задачи -
    // - преобразование действий над позицией каретки (PosY, PosX) к
    // действиям над объектами (Strings, Sections), а также обеспечение
    // возможности отмены действий пользователя (поддержка стека отката)

    TPosChangeProc = procedure(Pos:TPoint) of object;


    TMPSynMemoRange = class(TObject)
    private
        fRichMemo       : TMPCustomSyntaxMemo;  // Владелец
        fStart          : TPoint;               // Начало выделенной области
        fEnd            : TPoint;               // Конец выделенной области
        fPos            : TPoint;               // Текущие координаты курсора относительно текста [Row,Col]
        fSealing        : Boolean;              // Режим Collapsed (залипание, пустое выделение)
        fMaxUndoDepth   : Integer;              // Максимальный размер стека отката
        fUndoStack      : TObjectList;          // Стек отката
        fOnSetPosProc   : TPosChangeProc;
        function        GetLength: Integer;
        function        GetPosition: Integer;
        function        GetPosInText:Integer;
        function        GetText: string;
        function        GetMarkedText: string;
        procedure       CutFinalSpaces(const Row: Integer);
        procedure       SetLength(const Value: Integer);
        procedure       SetMaxUndoDepth(const Value: Integer);
        procedure       SetPosition(const Value: Integer);
        procedure       SetPos(const NewPos: TPoint);
        procedure       SetRange(const Index, Value: Integer);
        procedure       SetText(const Value: string);
        procedure       SetTextEx(const Value: string;ActionKind: TUndoKind);
        procedure       SetMarkedText(Value: string);
    protected

        function        AddUndo(const UndoText: string = ''): TMPSynMemoUndoItem;
        property        StartX : Integer read fStart.X write fStart.X;
        property        StartY : Integer read fStart.Y write fStart.Y;
        property        EndX   : Integer read fEnd.X   write fEnd.X;
        property        EndY   : Integer read fEnd.Y   write fEnd.Y;
    public
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        destructor      Destroy; override;
        procedure       Collapse;
        procedure       Enlarge(const Value: Integer; const EnlargeLine: Boolean = False; const VisiblesOnly: Boolean = False);
        procedure       Delete;
        { Операции над секциями }
        procedure       CreateSection;
        procedure       ExplodeSection(const Recursive: Boolean);
        procedure       ExpandSection(const Recursive: Boolean);
        procedure       CollapseSection(const Recursive: Boolean);
        procedure       GotoSection(const GoForward: Boolean);
        { Поддержка буфера обмена }
        procedure       CopyToClipboard;
        procedure       CutToClipBoard;
        procedure       PasteFromClipboard;
        { Стек отката }
        procedure       DoUndo;
        function        GetLastUndoItem:TMPSynMemoUndoItem;
        procedure       ClearUndo;
        procedure       SelectAll;
        procedure       SelectFromStart;
        procedure       SelectToEnd;
        function        IsEmpty: Boolean;
        function        CanUndo: Boolean;


        procedure       MakeIndent;
        procedure       MakeUnIndent;
        procedure       MakeComment(LitILComment:string);

        property        UndoStack: TObjectList read fUndoStack;
        property        PosX   : Integer index 0 read fPos.X write SetRange;
        property        PosY   : Integer index 1 read fPos.Y write SetRange;
        property        Pos: TPoint read fPos write SetPos;
        property        MaxUndoDepth: Integer read fMaxUndoDepth write SetMaxUndoDepth default 100;
        property        Position:     Integer read GetPosition write SetPosition;
        property        PosInText:    Integer read GetPosInText ;
        property        SelLength:    Integer read GetLength write SetLength;
        property        Text: string read GetText write SetText;
        property        MarkedText: string read GetMarkedText write SetMarkedText;
        property        LastUndoItem:TMPSynMemoUndoItem read GetLastUndoItem;

    end;

    TWordInfoEvent      = procedure (Sender: TMPCustomSyntaxMemo; const X, Y, WordIndex, Row: Integer; Showing: Boolean) of object;
    //TDrawWordEvent      = procedure (Sender: TMPCustomSyntaxMemo; ACanvas: TCanvas; Rect: TRect; Row, Index: Integer) of object;
    TRowIndexConvertionDirection = (cdNeedReal, cdNeedScreen);
    // Опции редактора
    TMPSynMemoOption = (smoShowFileNameInTabSheet,      // отображать имя файла на закладке
                        smoShowFileNameInFormCaption,   // отображать имя файла в форме
                        smoReadOnly,                    // запрет изменения текста (кроме секций)
                        smoOverwrite,                   // режим замены символов
                        smoSkipSectionsOnCopy,          // не копировать в буфер обмена информацию о секциях
                        smoSkipSectionsOnPaste,         // не восстанавливать секции при вставке текста из буфера обмена
                        smoAutoGutterWidth,             // ширина гуттера зависит от ОТКРЫТЫХ секций
                        smoWriteMarkersOnSave,          // при сохранении текста внедрять маркеры секций
                        smoVSNET_SectionsStyle,         // стиль маркеров секций как в Visual Studio NET
                        smoBreakPointsNeedPosibility,   // режим требующий установки BreakPoint'ов типа bpPosible
                        smoShowCursorPos,               // Показывает окно отображения позиции курсора
                        smoShowPageScroll,              // Показывае дополнительный скролл для прокрутки страниц
                        smoPanning,                     // Разрешает/запрещает панорамирование вообще
                        smoHorPanning,                  // Дополнительно разрешает/запрещает горизонтальное панорамирование
                        smoVerPanningReverse,           // Режим обратного вертикального панарамирования
                        smoHighlightLine,               // Включает закразивание комментариев и директив компилятора до конца строки.
                        smoSolidSpecialLine,            // Включает "залитый" режим для BreakPoint'ов и Линии отладки.
                        smoGroupUndo,                   // Включает группировку сходных Undo
                        smoTabulatedReturn,             // Включает автоматическую табуляцию при нажатии Enter
                        smoShowLineNumberToGutter       // Показ нумерации строк на гуттере

    );
    TMPSynMemoOptions   = set of TMPSynMemoOption;
    TLogEvent           = procedure (Sender: TObject; LogStr: string) of object;
    TChangedItem        = (ciText, ciSelection, ciSections, ciUndoStack, ciOptions);
    TChangedItems       = set of TChangedItem;
    TMPChangeEvent      = procedure (Sender: TObject; ChangedItems: TChangedItems) of object;


    // Управляющий закладками
    TBookmarkIndex      = 0..9;
    TMPBookmarkManager    = class
    private
        fRichMemo       : TMPCustomSyntaxMemo;
        fBookMarks      : array [TBookmarkIndex] of Integer;
        fImages         : TBitmap;
        function        GetBookMarks(const Index: TBookmarkIndex): Integer;
        procedure       SetBookMarks(const Index: TBookmarkIndex; const Row: Integer);
    public
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        destructor      Destroy; override;
        function        Find(const Row: Integer; var Index: TBookmarkIndex): Boolean;
        procedure       Clear;
        procedure       PaintAt(const ACanvas: TCanvas; const x, y: Integer; const Index: TBookmarkIndex);
        property        BookMarks[const Index: TBookmarkIndex]: Integer read GetBookMarks write SetBookMarks; default;
    end;

    //Классы для управления BreakPoint'ами
//    TBPKind = (bkPosible=0,bkEnabled=1,bkDisabled=2);
    TBPKind = (bkPosible,bkEnabled,bkDisabled);
    TBPMode = (bmFreeMode,bmNeedPosibility);
//    TBPMode = (bmFreeMode=0,bmNeedPosibility=1);
    TBPAction = (bpaSet,bpaDelete);
    TOnBeforeBreakPointChangedNotify=procedure (Sender: TObject; const Row:integer;const Action:TBPAction;var CanChange:boolean) of object;
    TBreakPoint = class(TObject)
    private
        Condition:string;
        PassCount:cardinal;
        Group:string;
        Comment:string;
        fKind:TBPKind;
        fCollection: TMPBreakPointCollection;
    private
        procedure       fSefKind(kind:TBPKind);
    public
        constructor     Create(Owner: TMPBreakPointCollection);
        destructor      Destroy; override;
        property        Kind: TBPKind read fKind write fSefKind;
        end;

    TMPBreakPointCollection = class(TObject)
    private
        fRichMemo       : TMPCustomSyntaxMemo;  // Владелец
        fBPList         : TStringList;
        fImages         : TBitmap;
        fImagesMask     : TBitmap;
        fMode           : TBPMode;
        fPopUpMenu      : TPopupMenu;
        fOnBeforeBreakPointChangedNotify:TOnBeforeBreakPointChangedNotify;
        fRowOfCurrentBP : integer;
        procedure       RefreshBP(Sender:TBreakPoint);
        property        Mode : TBPMode read fMode write fMode default bmFreeMode;
        procedure       PaintAt(const ACanvas: TCanvas; const x, y: Integer; const Kind:TBPKind);
        function        Find(const Row: Integer; var Kind:TBPKind): Boolean;
        procedure       Add(const Row: Integer;const Kind:TBPKind=bkEnabled;
                           Condition:string='';PassCount:cardinal=0;Group:string='';Comment:string='');
        function        Delete(const Row: Integer):boolean;
    protected
        function        fGetIsBreakPoint(const LineIndex:integer):boolean;
        procedure       fSetIsBreakPoint(const LineIndex:integer;bp:boolean);
        function        fGetIsPosible(const LineIndex:integer):boolean;
        procedure       fSetIsPosible(const LineIndex:integer;bp:boolean);
        function        fGetBreakPoint(const LineIndex:integer):TBreakPoint;
        procedure       fSetBreakPoint(const LineIndex:integer;BP:TBreakPoint);
    public
        constructor     Create(Owner: TMPCustomSyntaxMemo);
        destructor      Destroy; override;
        property        IsBreakPoint[const LineIndex: Integer]: Boolean read fGetIsBreakPoint write fSetIsBreakPoint;
        property        IsPosible[const LineIndex: Integer]: Boolean read fGetIsPosible write fSetIsPosible;
        property        BreakPoint[const LineIndex: Integer]: TBreakPoint read fGetBreakPoint;// write fSetBreakPoint;
        property        OnBeforeBreakPointChangedNotify:TOnBeforeBreakPointChangedNotify read fOnBeforeBreakPointChangedNotify write fOnBeforeBreakPointChangedNotify default nil;
        property        PopupMenu: TPopupMenu read fPopUpMenu write fPopUpMenu default nil;
        property        RowOfCurrentBP: integer read fRowOfCurrentBP write fRowOfCurrentBP;
    end;

    TMPProposalItems = array [0..1] of TStrings;
    TBeforeProposalCall=procedure(const ProposalName:string) of object;

    TMPCustomSyntaxMemo = class(TCustomControl)
    private
        fLines          : TMPSynMemoStrings;
        fRange          : TMPSynMemoRange;
        fSections       : TMPSynMemoSections;
        fOptions        : TMPSynMemoOptions;
        fBuffer         : TBitmap;
        fCharHeight     : Integer;
        fCharWidths     : TCharWidths;
        fParseAttributes: TMPSyntaxAttributes;
        fBookMarks      : TMPBookmarkManager;
        fBreakPoints    : TMPBreakPointCollection;
        fOnContextPopup : TContextPopupEvent;
        fOnBreakPointPopup : TContextPopupEvent;
        fPopupMenu      : TPopupMenu;
        fOffsets        : TPoint;
        fDown           : Boolean;
        fPanning        : Boolean;
        fHinting        : Boolean;
        fPanStartPoint  : TPoint;
        fInsertMode     : Boolean;
        fVScroll        : TScrollBar;
        fHScroll        : TScrollBar;
        fNavButton      : TPanel;
        fPageUpDown     : TScrollBar;
        fPosInfo        : TEdit;
        fSelColor       : TColor;
        fDefBackColor   : TColor;
        fDefForeColor   : TColor;
        fBPEnabledBackColor  : TColor;
        fBPEnabledForeColor  : TColor;
        fBPDisabledBackColor : TColor;
        fBPDisabledForeColor : TColor;
        fSelectedWordColor   : TColor;
        fDebugBackColor : TColor;
        fDebugForeColor : TColor;
        fSelWord        : TPoint;
        fCaretVisible   : Boolean;
        fScreenLines    : array of Boolean;
        fGutterWidth    : Integer;
        fSectionIndent  : Integer;
        fChangesSummator: TChangedItems;
        {$IFDEF SYNDEBUG}
        fLogDisabled    : Boolean;
        {$ENDIF}
        fOnChange       : TMPChangeEvent;
        fOnWordInfo     : TWordInfoEvent;
//        fOnDrawWord     : TDrawWordEvent;
        fOnLog          : TLogEvent;
        fStepDebugLine  : integer;
        fLettersCalculated : boolean;
        FCurParser      :TMPSyntaxParser;
        fInProposalCall :boolean;
        FProposalForm:TMPSyntaxCompletionProposalForm;
        FTimer:TTimer;
        FBeforeProposalCall: TBeforeProposalCall;
        function GetCurProposalName: string;
        procedure DoOnTimer(Sender:TObject);
        { Gets }
        function        GetUserTokenEvent: TUserTokenEvent;
        function        GetOnBeforeBreakPointChangedNotify:TOnBeforeBreakPointChangedNotify;
        function        GetBreakPointsPopupMenu:TPopupMenu;

        { Sets }
        procedure       OnChangePos(pos:TPoint);
        procedure       SetDefColor(const Index: Integer; const Value: TColor);
        procedure       SetGutterWidth(const Value: Integer);
        procedure       SetOffset(const Index, Value: Integer);
        procedure       SetOffsets(NewOffsets: TPoint);
        procedure       SetOptions(const Value: TMPSynMemoOptions);
        procedure       SetSectionIndent(const Value: Integer);
        procedure       SetSelColor(const Value: TColor);
        procedure       SetSelectedWord(const Value: TPoint);
        procedure       SetUserTokenEvent(const Value: TUserTokenEvent);
        procedure       SetOnBeforeBreakPointChangedNotify(OnBeforeBreakPointChangedNotify:TOnBeforeBreakPointChangedNotify);
        procedure       SetBreakPointsPopupMenu(pum:TPopupMenu);
        procedure       SetStepDebugLine(Row:integer);

        { Others }
        procedure       CreateDestroyPageUpDown;
        procedure       CreateDestroyCursorPos;
        procedure       Reset; virtual;
        procedure       CalcScreenParams;
        procedure       CalcFontParams;
        procedure       ScrollEnter(Sender: TObject);
        procedure       ScrollClick(Sender: TObject);
        procedure       UpdateScrollBars;
        procedure       PageUpDownOnClick(Sender: TObject);
        function        ClientLines: Integer;
        procedure       PaintGutter(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
        procedure       PaintSectionMarks(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
        procedure       PaintDots(const ACanvas: TCanvas);
        procedure       PaintTokens(const ACanvas: TCanvas; s: string; Sp: TMPSyntaxParser; Row, TextIndent, SelStart, SelEnd: Integer);
//        procedure       PaintLine(const ScreenRow, Row: Integer);
        procedure       PaintLineEx3(const ScreenRow, Row: Integer);
        function        RowIndexConvert(const Index: Integer; const Direction: TRowIndexConvertionDirection): Integer;
        function        FindVisibleRow(const Row, Delta: Integer; const EnsureInRange: Boolean): Integer;
        function        RangeRowToScreenRow(const Row: Integer): Integer;
        { Repaint manager }
        procedure       ReDraw;
        procedure       NeedRedraw(const Row: Integer);
        procedure       NeedReDrawLE(const Row: Integer);
        procedure       NeedRedrawAll;
        { Приведение координат }
        function        CharPosToPixOffset(const Col, Row: Integer): Integer; overload;
        function        CharPosToPixOffset(const Col: Integer; s: string; Sp: TMPSyntaxParser): Integer; overload;
        function        PixOffsetToCharPos(const Pix, Row: Integer; const WordIndex: PInteger = nil): Integer;
        procedure       WndOffsetToPixOffset(OfsPoint: TPoint; var CharPix, Row: Integer; const TextRow: Boolean);
        function        PixOffsetToWndOffsetEx(const CharPix, ScreenRow: Integer): TPoint;
        function        GetSectionButtonRect(const ScreenRow, ALevel: Integer): TRect;
        function        IsLineVisible(const Row: Integer; const PScreenRow: PInteger = nil): Boolean;
        function        GetWndRect(const ScreenRow, Index: Integer): TRect;
        {$IFDEF SYNDEBUG}
        procedure       Log(const LogString: string);
        procedure       LogFmt(const LogFormat: string; LogArgs: array of const);
        {$ENDIF}
    protected

        function        CanResize(var NewWidth, NewHeight: Integer): Boolean; override;
        procedure       CreateParams(var Params: TCreateParams); override;
        procedure       WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
        procedure       WMSize(var Message: TMessage); message WM_SIZE;
        procedure       WMKillFocus(var Msg: TWMKillFocus); message WM_KILLFOCUS;
        procedure       WMLButtonDblClk(var Message: TWMMouse); message WM_LBUTTONDBLCLK;
        procedure       WMSetFocus(var Msg: TWMSetFocus); message WM_SETFOCUS;
        procedure       WMMouseWheel(var Message: TMessage); message WM_MouseWheel;
        procedure       MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
        procedure       MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
        procedure       MouseMove(Shift: TShiftState; X, Y: Integer); override;
        procedure       KeyDown(var Key: Word; Shift: TShiftState); override;
        procedure       KeyPress(var Key: Char); override;
        procedure       KeyUp(var Key: Word; Shift: TShiftState); override;
        procedure       FontChange(Sender: TObject);
        procedure       Paint; override;
        procedure       HideCaret;
        procedure       ShowCaret;
        procedure       Change(const ChangedItems: TChangedItems); virtual;
        procedure       ProposalCall;
        procedure       CloseProposal;
                        // Координаты специальных элементов строки экрана
        property        EntireRowRect[const ScreenRow: Integer]: TRect      index 0 read GetWndRect;
        property        TextRowRect[const ScreenRow: Integer]: TRect        index 1 read GetWndRect;
        property        EntireGutterRect[const ScreenRow: Integer]: TRect   index 2 read GetWndRect;
        property        SymbolsGutterRect[const ScreenRow: Integer]: TRect  index 3 read GetWndRect;
    public
        constructor     Create(AOwner: TComponent); override;
        destructor      Destroy; override;

        procedure       ScreenPosToTextPos(const ScrX,ScrY:Integer;var DestX,DestY:Integer ); // для драг дропа
        function        TextPosToScreen(const X,Y:Integer):TPoint; // для драг дропа
        function        CharPosToWordIndex(const Col, Row: Integer): Integer;
        function        GetWordAtPos(const X, Y: Integer; var WordIndex, Row: Integer): Boolean;
        function        GetCurrentWord(PartOnly:boolean =False):string;
        procedure       ReplaceCurrentWord(DestStr:string);
        function        FindNextWord(var wx, wy: Integer): Boolean;
        function        FindPrevWord(var wx, wy: Integer): Boolean;
        function        WordByPos(const WordPos:TPoint):string;
        function        GetPosInText:Integer;

        procedure       ShowWord(const Row, WordIndex: Integer);
        procedure       MakeVisible(const Col, Row: Integer; const Length: Integer = 1);
        procedure       Navigate(const Col, Row: Integer);

        procedure       SetProposalItems(PI:TMPProposalItems);
        procedure       SaveProposals(const aName:string);
        procedure       ApplyProposal(const aName:string);
        procedure       AddToCurrentProposal(ts,ts1:TStrings);
        procedure       AddProposal(const aName:string);
        procedure       ClearProposal;

        { Properties }
        property        BookMarks: TMPBookmarkManager read fBookMarks;
        property        BreakPoints: TMPBreakPointCollection read fBreakPoints write fBreakPoints;
        property        DefBackColor: TColor index 0 read fDefBackColor write SetDefColor default clWindow;
        property        DefForeColor: TColor index 1 read fDefForeColor write SetDefColor default clBlack;

        property        BPEnabledBackColor:TColor index 2 read fBPEnabledBackColor write SetDefColor default clRed;
        property        BPEnabledForeColor:TColor index 3 read fBPEnabledForeColor write SetDefColor default clWhite;
        property        BPDisabledBackColor:TColor index 4 read fBPDisabledBackColor write SetDefColor default clMaroon;
        property        BPDisabledForeColor:TColor index 5 read fBPDisabledForeColor write SetDefColor default clWhite;
        property        DebugLineBackColor:TColor index 6 read fDebugBackColor write SetDefColor default clNavy;
        property        DebugLineForeColor:TColor index 7 read fDebugForeColor write SetDefColor default clWhite;
        property        SelectedWordColor:TColor index 8 read fSelectedWordColor write SetDefColor default $000080FF;

        property        GutterWidth: Integer read fGutterWidth write SetGutterWidth default 32;
        property        Lines: TMPSynMemoStrings read fLines;
        property        OffsetXPix: Integer index 0 read fOffsets.X write SetOffset;
        property        OffsetY: Integer index 1 read fOffsets.Y write SetOffset;
        property        Offsets: TPoint read fOffsets write SetOffsets;
        property        Range: TMPSynMemoRange read fRange;
        property        SectionIndent: Integer read fSectionIndent write SetSectionIndent default 16;
        property        Sections: TMPSynMemoSections read fSections;
        property        SelColor: TColor read fSelColor write SetSelColor default clSkyBlue;
        property        SelectedWord: TPoint read fSelWord write SetSelectedWord;
        property        SyntaxAttributes: TMPSyntaxAttributes read fParseAttributes;
        property        Options: TMPSynMemoOptions read fOptions write SetOptions default [smoAutoGutterWidth,smoShowCursorPos,smoShowPageScroll,smoPanning];
        property        OnChange: TMPChangeEvent read fOnChange write fOnChange;
//        property        OnDrawWord: TDrawWordEvent read fOnDrawWord write fOnDrawWord;
        property        OnWordInfo: TWordInfoEvent read fOnWordInfo write fOnWordInfo;
        property        OnParseWord: TUserTokenEvent read GetUserTokenEvent write SetUserTokenEvent;
        property        OnLog: TLogEvent read fOnLog write fOnLog;
        property        OnBeforeBreakPointChanged: TOnBeforeBreakPointChangedNotify read GetOnBeforeBreakPointChangedNotify write SetOnBeforeBreakPointChangedNotify;
        property        BreakPointsPopupMenu: TPopupMenu read GetBreakPointsPopupMenu write SetBreakPointsPopupMenu default nil;
        property        PopupMenu: TPopupMenu read fPopupMenu write fPopupMenu default nil;
        property        Color default clWindow;
        property        OnContextPopup: TContextPopupEvent read fOnContextPopup write fOnContextPopup default nil;
        property        OnBreakPointPopup: TContextPopupEvent read fOnBreakPointPopup write fOnBreakPointPopup default nil;
        property        StepDebugLine: integer read fStepDebugLine write SetStepDebugLine default -1;
        property        BeforeProposalCall: TBeforeProposalCall read FBeforeProposalCall write FBeforeProposalCall;
        property        CurProposalName   : string read GetCurProposalName;
        property        Hinting:boolean read fHinting;
    end;


    TMPSyntaxMemo       = class(TMPCustomSyntaxMemo)
    published
        property        Anchors;
        property        Align;
        property        Color;
        property        DefBackColor;
        property        DefForeColor;
        property        BPEnabledBackColor;
        property        BPEnabledForeColor;
        property        BPDisabledBackColor;
        property        BPDisabledForeColor;
        property        DebugLineBackColor;
        property        DebugLineForeColor;
        property        SelectedWordColor;

        property        GutterWidth default 32;
        property        Font;
        property        Options;
        property        SelColor default clHighlight;
        property        SectionIndent default 32;
        property        TabStop default True;
        property        OnKeyDown;
        property        OnKeyPress;
        property        OnKeyUp;
        property        OnMouseDown;
        property        OnMouseMove;
        property        OnMouseUp;
        property        OnClick;
        property        OnDblClick;
        property        OnDragDrop;
        property        OnChange;
//        property        OnDrawWord;
        property        OnWordInfo;
        property        OnParseWord;
        property        OnLog;
        property        OnEnter;
        property        OnExit;
        property        OnBeforeBreakPointChanged;
        property        BreakPointsPopupMenu;
        property        PopupMenu;
        property        OnContextPopup;
        property        OnBreakPointPopup;
        property        BeforeProposalCall;
    end;

    TUserTokenEventProc  = procedure(
        Sender          : TObject;
        StartPos,EndPos :Integer;
        const Line       : string;
        var Token       : TToken
    );

    TDefAddSyntaxAttributes=procedure(N:TMPSyntaxAttributes);


////////////



  TMPSyntaxCompletionProposalForm = class(TForm)
  private
    FItemList       : TStrings;
    FInsertList     : TStrings;

    FProposalNames  :  TStrings;
    FCurProposalName   : string;
    FItems          : array of string;
    FInserts        : array of string;

    FListProp:TListBox;
    FOwnerPos:TPoint;
    procedure ListBoxClick(Sender: TObject);
    procedure ListBoxKeyDown(Sender: TObject; var Key: Word;  Shift: TShiftState);
    procedure CompleteProposal;
    procedure Up;
    procedure Down;
    procedure ToHome;
    procedure ToEnd;
    procedure PAGEDOWN;
    procedure PAGEUP;
    procedure ListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);

  protected
    procedure Deactivate; override;
    procedure DoHide; override;
    procedure ChangeListText;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure  ShowEx(x,y:integer);
    procedure  SaveProposals(const aName:string);
    procedure  ApplyProposal(const aName:string);
    procedure  AddProposal(const aName:string);

    procedure  ChangeItems(NewItems:TMPProposalItems);
    property   ItemList       : TStrings read FItemList;
    property   InsertList     : TStrings read FInsertList;
    property   CurProposalName   : string read FCurProposalName;
  end;


var
   DefUserTokenEventProc:TUserTokenEventProc;
   DefAddSyntaxAttributes:TDefAddSyntaxAttributes;
   DefProposal:TMPProposalItems;

const
     SectionMarks      : array [TSectionMark] of string = ('', '{<+}', '{<-}', '{>>}');
     SECTION_HEADER_LENGTH = 4;
     OperatorChars= ['+','-','*','/','<','>','='];

     ProposalDelimiter:string ='#$';

implementation

{$R pFIBSyntaxMemo.res}
//{$R UnitSyntaxMemo.dcr}

uses Math {$IFDEF D6+},StrUtils, Variants{$ENDIF};

var CF_SYNTAX: THandle;

// Results of RangeRowToScreenRow()
const
    ROW_ABOVE_SCREEN    = -1;
    ROW_HIDEN           = -2;
    ROW_BELOW_SCREEN    = -3;




procedure Swap(var A, B: Integer);
var t: Integer;
begin
    t := A;
    A := B;
    B := t;
end;


// Class TParseAttributes Implementation

// К О Н С Т Р У К Т О Р
constructor TMPSyntaxAttributes.Create(Owner: TMPCustomSyntaxMemo);
var T: TToken;
begin

    inherited Create;
    fRichMemo := Owner;
    // Очистка таблицы стилей
    for T := Low(TToken) to High(TToken) do
        with fTokenStyles[T] do begin
            tsForeground    := clDefault;
            tsBackground    := clDefault;
            tsStyle         := [];
        end;
    // Стили по умолчанию
    fLitString        := '''';
    fLitChar          := '''';//Для C
    fLitILComment     := '//';
    fLitILCompDir     := '#';//Для C
    fLitMLCommentB    := '{';
    fLitMLCommentE    := '}';
    fLitELCommentB    := '(*';
    fLitELCommentE    := '*)';
    fLitMLCompDirB    := '{$';
    fLitMLCompDirB    := '}';
    fLitHexPrefix     := '$';
    fLitDecimalPoint  := '.';
    fLitReference     := '@';
    fLitDereference   := '^';
    fParseOptions     := [  poHasELComment, poHasMLComment, poHasILComment,
                            poHasHexPrefix, poFloatValid, poHasReference,
                            poHasDereference, poHasMLCompDir];

{    fTokenStyles[tokReservedWord].tsForeground := clBlack;
    fTokenStyles[tokReservedWord].tsStyle      := [fsBold];
 }
    fTokenStyles[tokString].tsForeground        := clBlue;
    fTokenStyles[tokString].tsStyle             := [fsItalic];
    fTokenStyles[tokStringEnd].tsForeground     := clBlue;
    fTokenStyles[tokStringEnd].tsStyle          := [fsItalic];

    fTokenStyles[tokChar].tsForeground          := clBlue;
    fTokenStyles[tokChar].tsStyle               := [fsItalic];
    fTokenStyles[tokCharEnd].tsForeground       := clBlue;
    fTokenStyles[tokCharEnd].tsStyle            := [fsItalic];

    fTokenStyles[tokHexValue].tsForeground      := clNavy;
    fTokenStyles[tokHexValue].tsStyle           := [fsBold];
    fTokenStyles[tokInteger].tsForeground       := clRed;
    fTokenStyles[tokFloat].tsForeground         := clRed;
    fTokenStyles[tokFloat].tsStyle              := [fsItalic];

    fTokenStyles[tokILCompDir].tsForeground     := clGreen;
    fTokenStyles[tokMLCompDirBeg].tsForeground  := clGreen;
    fTokenStyles[tokMLCompDirEnd].tsForeground  := clGreen;

    fTokenStyles[tokILComment].tsForeground     := clGray;
    fTokenStyles[tokILComment].tsStyle          := [fsItalic];

    fTokenStyles[tokMLCommentBeg].tsForeground  := clGray;
    fTokenStyles[tokMLCommentBeg].tsStyle       := [fsItalic];
    fTokenStyles[tokMLCommentEnd].tsForeground  := clGray;
    fTokenStyles[tokMLCommentEnd].tsStyle       := [fsItalic];

    fTokenStyles[tokELCommentBeg].tsForeground  := clGray;
    fTokenStyles[tokELCommentBeg].tsBackground  := clWindow;
    fTokenStyles[tokELCommentBeg].tsStyle       := [fsItalic];
    fTokenStyles[tokELCommentEnd].tsForeground  := clGray;
    fTokenStyles[tokELCommentEnd].tsBackground  := clWindow;
    fTokenStyles[tokELCommentEnd].tsStyle       := [fsItalic];

{    fTokenStyles[tokELCommentBeg].tsForeground  := clNavy;
    fTokenStyles[tokELCommentBeg].tsBackground  := clMoneyGreen;
    fTokenStyles[tokELCommentEnd].tsForeground  := clNavy;
    fTokenStyles[tokELCommentEnd].tsBackground  := clMoneyGreen;{}

    fTokenStyles[tokParenBeg].tsForeground      := clBlue;
    fTokenStyles[tokParenEnd].tsForeground      := clBlue;
    fTokenStyles[tokBrackedBeg].tsForeground    := clBlue;
    fTokenStyles[tokBracketEnd].tsForeground    := clBlue;

    fTokenStyles[tokILCompDir].tsForeground     := clGreen;
    if Assigned(DefAddSyntaxAttributes) then
     DefAddSyntaxAttributes(Self) 
end;


// Присваивает себе все состояние родственника
procedure TMPSyntaxAttributes.Assign(Friend: TMPSyntaxAttributes);
begin
    if (self = Friend) or (Friend = nil) then Exit;
    fRichMemo.Lines.BeginUpdate;
    fLitString       := Friend.fLitString;
    fLitChar         := Friend.fLitChar;
    fLitILComment    := Friend.fLitILComment;
    fLitILCompDir    := Friend.fLitILCompDir;
    fLitMLCompDirB   := Friend.fLitMLCompDirB;
    fLitMLCompDirE   := Friend.fLitMLCompDirE;
    fLitMLCommentB   := Friend.fLitMLCommentB;
    fLitMLCommentE   := Friend.fLitMLCommentE;
    fLitELCommentB   := Friend.fLitELCommentB;
    fLitELCommentE   := Friend.fLitELCommentE;
    fLitHexPrefix    := Friend.fLitHexPrefix;
    fLitDecimalPoint := Friend.fLitDecimalPoint;
    fLitReference    := Friend.fLitReference;
    fLitDereference  := Friend.fLitDereference;
    fParseOptions    := Friend.fParseOptions;
    Move(Friend.fTokenStyles, fTokenStyles, SizeOf(fTokenStyles));
    fRichMemo.Lines.State := fRichMemo.Lines.State + [ssNeedReparseAll];
    fRichMemo.Lines.EndUpdate;
end;


// Возвращает истину, если визуальные атрибуты токенов одинаковы
function TMPSyntaxAttributes.Equals(const T1, T2: TToken): Boolean;
begin
    Result := (fTokenStyles[T1].tsForeground = fTokenStyles[T2].tsForeground)
          and (fTokenStyles[T1].tsBackground = fTokenStyles[T2].tsBackground)
          and (fTokenStyles[T1].tsStyle = fTokenStyles[T2].tsStyle);
end;


// Возвращает атрибут цвета токена
function TMPSyntaxAttributes.GetColor(const Token: TToken; const Index: Integer): TColor;
begin
    if Index = 0
        then Result := fTokenStyles[Token].tsForeground
        else Result := fTokenStyles[Token].tsBackground;
end;


// Возвращает атрибут стиля шрифта токена
function TMPSyntaxAttributes.GetStyle(const Token: TToken): TFontStyles;
begin
    Result := fTokenStyles[Token].tsStyle;
end;


// Устанавливает атрибут цвета токена
procedure TMPSyntaxAttributes.SetColor(const Token: TToken; const Index: Integer; const Value: TColor);
begin
    if Index = 0
        then fTokenStyles[Token].tsForeground := Value
        else fTokenStyles[Token].tsBackground := Value;
end;


// Устанавливает атрибут стиля шрифта токена
procedure TMPSyntaxAttributes.SetStyle(const Token: TToken; const Value: TFontStyles);
begin
    fTokenStyles[Token].tsStyle := Value;
end;


// Копирует атрибуты токена SrcToken во все токены из списка DstTokArray
procedure TMPSyntaxAttributes.CopyAttrs(const SrcToken: TToken; DstTokArray: array of TToken);
var T: TToken;
begin
    for T := Low(DstTokArray) to High(DstTokArray) do
        fTokenStyles[DstTokArray[T]] := fTokenStyles[SrcToken];
end;


const
    bools: array[Boolean] of string = ('N', 'Y');
    CURRENT_SYN_VERSION = '1.0';
    SSynVersion         = 'SyntaxVersion';
    SLitString          = 'LitString';
    SLitChar            = 'LitChar';
    SLitILCompDir       = 'LitILCompDir';
    SLitMLCompDirB      = 'LitMLCompDirB';
    SLitMLCompDirE      = 'LitMLCompDirE';

    SLitILComment       = 'LitILComment';
    SLitMLCommentB      = 'LitMLCommentB';
    SLitMLCommentE      = 'LitMLCommentE';
    SLitELCommentB      = 'LitELCommentB';
    SLitELCommentE      = 'LitELCommentE';
    SLitHexPrefix       = 'LitHexPrefix';
    SLitDecimalPoint    = 'LitDecimalPoint';
    SLitReference       = 'LitReference';
    SLitDereference     = 'LitDereference';
    SForeground         = 'Fore';
    SBackground         = 'Back';
    SStyleBold          = 'Bold';
    SStyleUnderline     = 'ULin';
    SStyleItalic        = 'Ital';
    SPOHasELComment     = 'HasELComment';
    SPOHasMLComment     = 'HasMLComment';
    SPOHasILComment     = 'HasILComment';
    SPOHasILCompDir     = 'HasILCompDir';
    SPOHasMLCompDir     = 'HasMLCompDir';
    SPOHasHexPrefix     = 'HasHexPrefix';
    SPOHasChar          = 'HasChar';
    SPOValidFloat       = 'ValidFloat';
    SPOHasReference     = 'HasReference';
    SPOHasDereference   = 'HasDereference';
    SPOBLSeparated      = 'BLSeparated';


// Загружает настройки из файла
procedure TMPSyntaxAttributes.LoadFromFile(const FileName: string);
var T: TToken;
    {}
    function FirstChar(const s: string): Char;
    begin
        if s = '' then Result := #0 else Result := s[1];
    end;
    {}
begin
    with TStringList.Create do begin
        fRichMemo.Lines.BeginUpdate;
        try
            LoadFromFile(FileName);
            if Values[SSynVersion] <> CURRENT_SYN_VERSION then
                raise Exception.Create('Неподходящая версия синтаксиса');
            fLitString          := FirstChar( Values[SLitString] );
            fLitChar            := FirstChar( Values[SLitChar] );
            fLitILCompDir       := Values[SLitILCompDir];
            fLitMLCompDirB      := Values[SLitMLCompDirB];
            fLitMLCompDirE      := Values[SLitMLCompDirE];
            fLitILComment       := Values[SLitILComment];
            fLitMLCommentB      := Values[SLitMLCommentB];
            fLitMLCommentE      := Values[SLitMLCommentE];
            fLitELCommentB      := Values[SLitELCommentB];
            fLitELCommentE      := Values[SLitELCommentE];
            fLitHexPrefix       := Values[SLitHexPrefix];
            fLitDecimalPoint    := FirstChar( Values[SLitDecimalPoint] );
            fLitReference       := FirstChar( Values[SLitReference] );
            fLitDereference     := FirstChar( Values[SLitDereference] );

            fParseOptions := [];
            if Values[SPOHasChar]        = bools[True] then Include(fParseOptions, poHasChar);
            if Values[SPOHasELComment]   = bools[True] then Include(fParseOptions, poHasELComment);
            if Values[SPOHasMLComment]   = bools[True] then Include(fParseOptions, poHasMLComment);
            if Values[SPOHasILComment]   = bools[True] then Include(fParseOptions, poHasILComment);
            if Values[SPOHasILCompDir]   = bools[True] then Include(fParseOptions, poHasILCompDir);
            if Values[SPOHasMLCompDir]   = bools[True] then Include(fParseOptions, poHasMLCompDir);
            if Values[SPOHasHexPrefix]   = bools[True] then Include(fParseOptions, poHasHexPrefix);
            if Values[SPOValidFloat]     = bools[True] then Include(fParseOptions, poFloatValid);
            if Values[SPOHasReference]   = bools[True] then Include(fParseOptions, poHasReference);
            if Values[SPOHasDereference] = bools[True] then Include(fParseOptions, poHasDereference);
            if Values[SPOBLSeparated]    = bools[True] then Include(fParseOptions, poBLSeparated);

            for T := Low(TToken) to High(TToken) do
                with fTokenStyles[T] do begin
                    tsForeground := StrToIntDef(Values[SForeground + IntToStr(Ord(T))], clDefault);
                    tsBackground := StrToIntDef(Values[SBackground + IntToStr(Ord(T))], clDefault);
                    tsStyle := [];
                    if Values[SStyleBold + IntToStr(Ord(T))] = bools[True] then Include(tsStyle, fsBold);
                    if Values[SStyleUnderline + IntToStr(Ord(T))] = bools[True] then Include(tsStyle, fsUnderline);
                    if Values[SStyleItalic + IntToStr(Ord(T))] = bools[True] then Include(tsStyle, fsItalic);
                end;

            fRichMemo.Lines.State := fRichMemo.Lines.State + [ssNeedReparseAll];
        finally
            fRichMemo.Lines.EndUpdate;
            Free;
        end
    end;
end;


// Сохраняет настройки в файл
procedure TMPSyntaxAttributes.SaveToFile(const FileName: string);
var T: TToken;
begin
    with TStringList.Create do begin
        Values[SSynVersion]       := CURRENT_SYN_VERSION;

        Values[SLitString]        := fLitString;
        Values[SLitChar]          := fLitChar;
        Values[SLitILCompDir]     := fLitILCompDir;
        Values[SLitMLCompDirB]    := fLitMLCompDirB;
        Values[SLitMLCompDirE]    := fLitMLCompDirE;
        Values[SLitILComment]     := fLitILComment;
        Values[SLitMLCommentB]    := fLitMLCommentB;
        Values[SLitMLCommentE]    := fLitMLCommentE;
        Values[SLitELCommentB]    := fLitELCommentB;
        Values[SLitELCommentE]    := fLitELCommentE;
        Values[SLitHexPrefix]     := fLitHexPrefix;
        Values[SLitDecimalPoint]  := fLitDecimalPoint;
        Values[SLitReference]     := fLitReference;
        Values[SLitDereference]   := fLitDereference;

        Values[SPOHasChar]        := bools[poHasChar in fParseOptions];
        Values[SPOHasELComment]   := bools[poHasELComment in fParseOptions];
        Values[SPOHasMLComment]   := bools[poHasMLComment in fParseOptions];
        Values[SPOHasILComment]   := bools[poHasILComment in fParseOptions];
        Values[SPOHasILCompDir]   := bools[poHasILCompDir in fParseOptions];
        Values[SPOHasMLCompDir]   := bools[poHasMLCompDir in fParseOptions];
        Values[SPOHasHexPrefix]   := bools[poHasHexPrefix in fParseOptions];
        Values[SPOValidFloat]     := bools[poFloatValid in fParseOptions];
        Values[SPOHasReference]   := bools[poHasReference in fParseOptions];
        Values[SPOHasDereference] := bools[poHasDereference in fParseOptions];
        Values[SPOBLSeparated]    := bools[poBLSeparated in fParseOptions];

        for T := Low(TToken) to High(TToken) do
            with fTokenStyles[T] do begin
                if tsForeground <> clDefault then
                    Values[SForeground + IntToStr(Ord(T))] := IntToStr(tsForeground);
                if tsForeground <> clDefault then
                    Values[SBackground + IntToStr(Ord(T))] := IntToStr(tsBackground);
                if fsBold in fTokenStyles[T].tsStyle then
                    Values[SStyleBold + IntToStr(Ord(T))] := bools[True];
                if fsUnderline in fTokenStyles[T].tsStyle then
                    Values[SStyleUnderline + IntToStr(Ord(T))] := bools[True];
                if fsItalic in fTokenStyles[T].tsStyle then
                    Values[SStyleItalic + IntToStr(Ord(T))] := bools[True];
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

    TokenStrings: array [tokBlank..tokReservedSiO] of string = (
        'tokBlank',     'tokText',    'tokString',    'tokStringEnd',    'tokHexValue',    'tokInteger',
        'tokFloat',    'tokILComment',    'tokMLCommentBeg',    'tokMLCommentEnd',    'tokELCommentBeg',
        'tokELCommentEnd',    'tokEndLine',    'tokParenBeg',    'tokParenEnd',    'tokBrackedBeg',
        'tokBracketEnd',    'tokOperator',    'tokPoint',    'tokComma',    'tokReference',
        'tokDereference', 'tokReserved', 'tokILCompDir', 'tokMLCompDirBeg', 'tokMLCompDirEnd',
        'tokChar', 'tokCharEnd', 'tokErroneous', 'tokErroneous2', 'tokReservedSIO');

    TOKEN_USER = 'tokUser#';



// Создает клон существующего парсера
constructor TMPSyntaxParser.Create(const AsCloneOf: TMPSyntaxParser = nil);
begin
    inherited Create(True);
    if Assigned(AsCloneOf) then
        Assign(AsCloneOf);
end;


// Добавляет позицию начала (0-based), длину и токен слова
procedure TMPSyntaxParser.AddToken(const Beg, Len: Integer; Token: TToken);
var W: TMPSyntaxToken;
begin
    W := TMPSyntaxToken.Create;
    W.stStart := Word(Beg - 1);
    W.stLength := Word(Len);
    W.stToken := Token;
    W.stStyle := [];
    Add(W);
end;


// Возвращает заданный токен
function TMPSyntaxParser.GetToken(const TokIndex: Integer): TMPSyntaxToken;
begin
    Result := TMPSyntaxToken( inherited Items[TokIndex] );
end;


// Устанавливает заданный токен
procedure TMPSyntaxParser.SetToken(const TokIndex: Integer; const Value: TMPSyntaxToken);
begin
    Items[TokIndex] := Value;
end;


// Возвращает "портрет" кода строки (для отладки)
function TMPSyntaxParser.AsString: string;
var i: Integer;
    s: string;
    T: TMPSyntaxToken;
begin
    Result := '';
    for i := 0 to Count - 1 do begin
        T := Tokens[i];
        if T.stToken > tokReserved
            then s := TOKEN_USER + IntToHex(T.stToken, 2) + 'H'
            else s := TokenStrings[T.stToken];
        Result := Result + #13#10 + s + #9'Beg=' + IntToStr(T.stStart) + #9'Len=' + IntToStr(T.stLength);
    end;
end;


// Принимает данные
procedure TMPSyntaxParser.Assign(const Friend: TMPSyntaxParser);
var i: Integer;
    T, NewT: TMPSyntaxToken;
begin
    Clear;
    for i := 0 to Friend.Count - 1 do begin
        T := Friend.Tokens[i];
        NewT := TMPSyntaxToken.Create;
        NewT.stStart    := T.stStart;
        NewT.stLength   := T.stLength;
        NewT.stToken    := T.stToken;
        NewT.stStyle    := T.stStyle;
        ADd(NewT);
    end;
    fSection      := Friend.Section;
    fVisibleIndex := Friend.VisibleIndex;
    fNeedReparse  := Friend.NeedReparse;
end;


// Удаляет информацию о строке
procedure TMPSyntaxParser.Clear;
begin
    inherited Clear;
    fNeedReparse := False;
end;


// Группирует смежные токены (tokString-tokStringEnd и т.п.)
// Операция необратимая.
procedure TMPSyntaxParser.GroupTokens;
var wi: Integer;
    {}
    procedure GroupSame(var i: Integer; SameTokens: TTokenSet);
    var W, W1: TMPSyntaxToken;
    begin
        W := Tokens[i];
        Inc(i);
        while i < Count do begin
            W1 := Tokens[i];
            if not (W1.stToken in SameTokens) then Break;
            W.stLength := W1.stStart + W1.stLength - W.stStart;
            W.stToken := W1.stToken;
            Delete(i);
        end;
    end;
begin
    if Count < 2 then Exit;
    wi := 0;
    while wi < Count do begin
        case GetToken(wi).stToken of
        tokString:
            GroupSame(wi, [tokString, tokStringEnd]);
        tokChar:
            GroupSame(wi, [tokChar, tokCharEnd]);

        tokMLCommentBeg:
            GroupSame(wi, [tokMLCommentBeg, tokMLCommentEnd]);

        tokELCommentBeg:
            GroupSame(wi, [tokELCommentBeg, tokELCommentEnd]);

        tokILComment:
            GroupSame(wi, [tokILComment]);

        tokILCompDir:
            GroupSame(wi, [tokILCompDir]);

        tokMLCompDirBeg:
            GroupSame(wi, [tokMLCompDirBeg, tokMLCompDirEnd]);
        else
            Inc(wi);
        end;
    end;
end;


// Разбивает токены, исходя из заданного диапазона выделения
// Если sx < 0, то строка выделена с начала экрана (не первая строка области выделения)
// Если ex = MAXINT, то строка выделена до конца экрана (не последняя строка области выделения)
// Операция необратимая.

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
//  assert(AMin <= AMax);
  if Result < AMin then
    Result := AMin;
  if Result > AMax then
    Result := AMax;
end;

function PointsEqual(const P1, P2: TPoint): Boolean;
begin
  Result := (P1.X = P2.X) and (P1.Y = P2.Y);
end;

function Sign(const AValue: Integer): integer;
begin
  Result := 0;
  if AValue < 0 then
    Result := -1
  else if AValue > 0 then
    Result := 1;
end;



function StuffString(const AText: string; AStart, ALength: Cardinal;
  const ASubText: string): string;
begin
  Result := Copy(AText, 1, AStart - 1) +
            ASubText +
            Copy(AText, AStart + ALength, MaxInt);
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

function PosEx(const SubStr, S: string; Offset: Integer = 1): Integer;
asm
       test  eax, eax
       jz    @Nil
       test  edx, edx
       jz    @Nil
       dec   ecx
       jl    @Nil

       push  esi
       push  ebx

       mov   esi, [edx-4]  //Length(Str)
       mov   ebx, [eax-4]  //Length(Substr)
       sub   esi, ecx      //effective length of Str
       add   edx, ecx      //addr of the first char at starting position
       cmp   esi, ebx
       jl    @Past         //jump if EffectiveLength(Str)<Length(Substr)
       test  ebx, ebx
       jle   @Past         //jump if Length(Substr)<=0

       add   esp, -12
       add   ebx, -1       //Length(Substr)-1
       add   esi, edx      //addr of the terminator
       add   edx, ebx      //addr of the last char at starting position
       mov   [esp+8], esi  //save addr of the terminator
       add   eax, ebx      //addr of the last char of Substr
       sub   ecx, edx      //-@Str[Length(Substr)]
       neg   ebx           //-(Length(Substr)-1)
       mov   [esp+4], ecx  //save -@Str[Length(Substr)]
       mov   [esp], ebx    //save -(Length(Substr)-1)
       movzx ecx, byte ptr [eax] //the last char of Substr

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


function IfThenStr(AValue: Boolean; const ATrue: string; const AFalse: String): String;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;


procedure TMPSyntaxParser.SplitTokens(const sx, ex: Integer);
var wi: Integer;
    T: TMPSyntaxToken;
    {}
    function TestSel(const r: Integer): Boolean;
    var TT: TMPSyntaxToken;
    begin
        with T do begin
            Result := InRange(r, stStart + 1, stStart + stLength - 1);
            if Result then begin
                // Разбиваем цепочку на две
                TT := TMPSyntaxToken.Create;
                TT.stStart  := r;
                TT.stLength := stStart + stLength - r;
                TT.stToken  := stToken;
                stLength := r - stStart;
                Insert(wi + 1, TT);
            end
        end
    end;
begin
    wi := 0;
    while wi < Count do begin
        T := Tokens[wi];
        if not TestSel(sx)
            then TestSel(ex);
        if InRange(T.stStart, sx, ex - 1)
            then Include(T.stStyle, stsInSelection)
            else Exclude(T.stStyle, stsInSelection);
        Inc(wi);
    end;
end;


// Возвращает первый токен строки (если он есть - иначе tokText)
function TMPSyntaxParser.FirstToken: TToken;
begin
    if Count > 0
        then Result := Tokens[0].stToken
        else Result := tokText;
end;


// Возвращает последний токен строки (...)
function TMPSyntaxParser.LastToken: TToken;
begin
    if Count > 0
        then Result := Tokens[Count - 1].stToken
        else Result := tokText;
end;


// Основное - производит синтаксический разбор строки (парсер)
function TMPSyntaxParser.Parse(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
begin
    if poBLSeparated in PA.ParseOptions  then
     Result := ParseLine(Line, LineIndex, LastToken, PA)
    else
     Result := ParseLineEx(Line, LineIndex, LastToken, PA);
    fNeedReparse := False;
end;


// ParseLine() Синтаксический разбор строки со словами, разделенными пробелами
function TMPSyntaxParser.ParseLine(Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
var si: string;
    i, wordbeg: Integer;
    InWord, InLit, InLitChar: Boolean;
    {}
    function HasChars(const s: string; StartPos: Integer; Chars: TCharSet): Boolean;
    var i: Integer;
    begin
        Result := False;
        for i := StartPos to Length(s) do
            if not (s[i] in Chars) then
                Exit;
        Result := True;
    end;
    {}
begin
    Clear;
    InWord := False;
    InLit  := False;
    InLitChar:= False;
    WordBeg := 1;

    Result := tokText;
    if Length(Line) = 0 then Exit;
    if Line[Length(Line)] >= ' ' then
        Line := Line + ' ';

    for i := 1 to Length(Line) do

        if Line[i] > ' ' then begin
            // Найден символ
            if not InWord then
                WordBeg := i;
            InWord := True;
        end else begin

            // Blank symbol
            if InWord then begin
                si := Copy(Line, WordBeg, i - wordbeg);

                Result := LastToken;

                { Test for comments begin }
                if not (Result in [tokMLCommentBeg, tokELCommentBeg, tokMLCompDirBeg]) then begin
                    if  (poHasELComment in PA.ParseOptions)
                    and (Pos(PA.LiteralELCommentBeg, si) = 1) then
                        Result := tokELCommentBeg
                    else
                    if  (poHasMLComment in PA.ParseOptions)
                    and (Pos(PA.LiteralMLCommentBeg, si) = 1) then
                        Result := tokMLCommentBeg
                    else
                    if  (poHasILComment in PA.ParseOptions)
                    and (Pos(PA.LiteralILComment, si) = 1) then
                        Result := tokILComment
                    else
                    if  (poHasMLCompDir in PA.ParseOptions)
                    and (Pos(PA.LiteralMLCompDirBeg, si) = 1) then
                        Result := tokMLCompDirBeg
                    else
                    if  (poHasILCompDir in PA.ParseOptions)
                    and (Pos(PA.LiteralILCompilerDirective, si) = 1) then
                        Result := tokILCompDir;


                end;

                { Test for comments end }
                case Result of
                tokILComment: ;   // остается до конца строки
                tokILCompDir: ;

                tokMLCommentBeg:
                    with PA do
                        if RightStr(si, Length(LiteralMLCommentEnd)) = LiteralMLCommentEnd
                            then Result := tokMLCommentEnd;

                tokELCommentBeg:
                    with PA do
                        if RightStr(si, Length(PA.LiteralELCommentEnd)) = LiteralELCommentEnd
                            then Result := tokELCommentEnd;

                tokMLCompDirBeg:
                    with PA do
                        if RightStr(si, Length(LiteralMLCompDirEnd)) = LiteralMLCompDirEnd
                            then Result := tokMLCompDirEnd;

                else
                    // Возвращаемся к токену по умолчанию
                    Result := tokText;

                    { Test for string begin }
                    if si[1] = PA.LiteralString then
                        InLit := True;
                    { Test for string end }
                    if InLit then begin
                        Result := tokStringEnd;
                        if si[Length(si)] = PA.LiteralString then
                            InLit := False;
                    end else

                    { Test for AnsiChar begin }
                    if si[1] = PA.LiteralChar then
                        InLitChar := True;
                    { Test for AnsiChar end }
                    if InLitChar then begin
                        Result := tokCharEnd;
                        if si[Length(si)] = PA.LiteralChar then
                            InLitChar := False;
                    end else

                    { Numbers: separately Integer, Hex or Float values }
                    if (Length(si) > Length(PA.LiteralHexPrefix))
                    and (Pos(PA.LiteralHexPrefix, si) = 1)
                    and HasChars(si, Length(PA.LiteralHexPrefix) + 1, ['0'..'9','A'..'F','a'..'f']) then
                        Result := tokHexValue
                    else
                    if (Length(si) > 1) and (si[1] in ['-', '0'..'9']) then begin
                        if HasChars(si, 2, ['0'..'9']) then
                            Result := tokInteger
                        else
                        if HasChars(si, 2, ['0'..'9', PA.LiteralDecimalPoint]) then
                            Result := tokFloat
                    end;

                end;

                { User tokens }
                if Result = tokText then     // Подключаем внешнее прерывание
                    if Assigned(PA.OnUserToken) then
                        PA.OnUserToken(self, si, WordBeg, LineIndex, Result);

                // Add to processed words list
                AddToken(WordBeg, i - WordBeg, Result);
                LastToken := Result;
            end;
            InWord := False;
        end;

    // Внутристрочный комментарий всегда завершается в конце строки
    // Общая нормализация конечного токена строки
    // (важны только открытые многострочные комментарии)
    if not (Result in [tokMLCommentBeg, tokELCommentBeg, tokMLCompDirBeg]) then
        Result := tokText;
end;


// Синтаксический разбор строки "продвинутый"
function TMPSyntaxParser.ParseLineEx(const Line: string; LineIndex: Integer; LastToken: TToken; PA: TMPSyntaxAttributes): TToken;
const
    HexChars            : TCharSet = ['0'..'9','A'..'F','a'..'f'];
    IntChars            : TCharSet = ['0'..'9'];
    { Возвращает категорию символа в строке }
type TCharRange = (crBlank, crSymbol, crLetter, crLit);
    function CharRange(c: Char): TCharRange;
    begin
        if c = PA.LiteralString then
            Result := crLit
        else
            case c of
            #$00..#$20: Result := crBlank;
            #$21..#$2F,
            #$3A..#$40: Result := crSymbol;
            #$30..#$39,
            #$41..#$FF: Result := crLetter;
            else        Result := crSymbol;
            end;
    end;

    // Возвращает признак того, что сменился ранг символа
    function CharRangeChange(c1, c2: Char): Boolean;
    begin
        Result := CharRange(c1) <> CharRange(c2);
    end;

    // Проверка на начало комментария
    function TestCommentsBegin(const Pos: Integer; var Token: TToken): Boolean;
    begin
        Result := True;
        if  (poHasELComment in PA.ParseOptions)
        and (PosEx(PA.LiteralELCommentBeg, Line, Pos) = Pos) then
            Token := tokELCommentBeg
        else
        if  (poHasMLComment in PA.ParseOptions)
        and (PosEx(PA.LiteralMLCommentBeg, Line, Pos) = Pos) then
            Token := tokMLCommentBeg
        else
        if  (poHasILComment in PA.ParseOptions)
        and (PosEx(PA.LiteralILComment, Line, Pos) = Pos) then
            Token := tokILComment
        else
        if  (poHasILCompDir in PA.ParseOptions)
        and (PosEx(PA.LiteralILCompilerDirective, Line, Pos) = Pos) then
            Token := tokILCompDir
        else
        if  (poHasMLCompDir in PA.ParseOptions)
        and (PosEx(PA.LiteralMLCompDirBeg, Line, Pos) = Pos) then
            Token := tokMLCompDirBeg
        else
            Result := False;
    end;

    // Возвращает признак того, что токен является комментарием
    function InComment(const Token: TToken): Boolean;
    begin
        Result := Token in [tokELCommentBeg, tokMLCommentBeg, tokILComment, tokMLCompDirBeg, tokILCompDir];
    end;

    // Обрабатывает комментарии, начиная с заданного символа (Pos)
    // Возвращает позицию следующего за концом комментария символа (Pos)
    // Тип комментария получает через Token, туда же кладет последний
    // обработанный токен
    procedure ProcessComments(var Pos: Integer; var Token: TToken);
    var WordBeg: Integer;
        si: string;
        InWord: Boolean;
    begin
        si := '';
        InWord := True;
        WordBeg := Pos;
        while Pos <= Length(Line) do begin
            if Line[Pos] > ' ' then begin
                if not InWord then
                    WordBeg := Pos;
                InWord := True;
                si := si + Line[Pos];
                // Проверка на конец комментария
                case Token of
                tokMLCommentBeg:
                    if RightStr(si, Length(PA.LiteralMLCommentEnd)) = PA.LiteralMLCommentEnd then begin
                        Token := tokMLCommentEnd;
                        Inc(Pos);
                        AddToken(WordBeg, Pos - WordBeg, Token);
                        Exit;
                    end;
                tokELCommentBeg:
                    if RightStr(si, Length(PA.LiteralELCommentEnd)) = PA.LiteralELCommentEnd then begin
                        Token := tokELCommentEnd;
                        Inc(Pos);
                        AddToken(WordBeg, Pos - WordBeg, Token);
                        Exit;
                    end;
                tokMLCompDirBeg:
                    if RightStr(si, Length(PA.LiteralMLCompDirEnd)) = PA.LiteralMLCompDirEnd then begin
                        Token := tokMLCompDirEnd;
                        Inc(Pos);
                        AddToken(WordBeg, Pos - WordBeg, Token);
                        Exit;
                    end;
                end;

              if  (Pos=Length(Line)) then
              if InWord then begin
                  InWord := False;
                  AddToken(WordBeg, Pos - WordBeg+1, Token);
                  si := '';
              end;
            end
            else
            if InWord then begin
                InWord := False;
                AddToken(WordBeg, Pos - WordBeg, Token);
                si := '';
            end;
            Inc(Pos);
        end;
    end;

    // Обрабатывает строку, начиная с заданного символа, так что Line[Pos] = fLitString
    // Возвращает позицию следующего за концом строки символа
    procedure ProcessString(var Pos: Integer);
    var WordBeg: Integer;
        InWord: Boolean;
    begin
        InWord := True;
        WordBeg := Pos;
//        Inc(Pos);
        while Pos <= Length(Line) do begin
            Inc(Pos);
            if Line[Pos] > ' ' then begin
                if not InWord then
                    WordBeg := Pos;
                InWord := True;
                // Проверка на конец строки
                if Line[Pos] = PA.LiteralString then begin
                    Inc(Pos);
                    AddToken(WordBeg, Pos - WordBeg, tokStringEnd);
                    Exit;
                end;
                if (Pos = Length(Line)) and InWord then
                begin
                    InWord := False;
                    AddToken(WordBeg, Pos - WordBeg+1, tokString);
                end;

            end else
            if InWord then begin
                InWord := False;
                AddToken(WordBeg, Pos - WordBeg, tokString);
            end;
//            Inc(Pos);
        end;
    end;

    // Обрабатывает символ, начиная с заданного символа, так что Line[Pos] = fLitChar
    // Возвращает позицию следующего за концом строки символа
    procedure ProcessChar(var Pos: Integer);
    var WordBeg: Integer;
        InWord: Boolean;
    begin
        InWord := True;
        WordBeg := Pos;
        Inc(Pos);
        while Pos <= Length(Line) do begin
            if Line[Pos] > ' ' then begin
                if not InWord then
                    WordBeg := Pos;
                InWord := True;
                // Проверка на конец строки
                if Line[Pos] = PA.LiteralChar then begin
                    Inc(Pos);
                    AddToken(WordBeg, Pos - WordBeg, tokCharEnd);
                    Exit;
                end;
              if (Pos = Length(Line)) and InWord then begin
                  InWord := False;
                  AddToken(WordBeg, Pos - WordBeg+1, tokChar);
              end;

            end
            else
            if InWord then begin
                InWord := False;
                AddToken(WordBeg, Pos - WordBeg, tokChar);
            end;
            Inc(Pos);
        end;
    end;

    // Обрабатывает шестнадцатиричное число, начиная с заданного символа,
    // так что Line[Pos] = fLitHexPrefix
    // Возвращает позицию следующего за концом числа символа
    procedure ProcessHexValue(var Pos: Integer);
    var WordBeg: Integer;
    begin
        WordBeg := Pos;
        Pos:=Pos+Length(PA.LiteralHexPrefix);
        while (Pos <= Length(Line)) and (Line[Pos] in HexChars) do
              Inc(Pos);
        AddToken(WordBeg, Pos - WordBeg, tokHexValue);
    end;

    // Обрабатывает целое или дробное число, начиная с заданного символа,
    // так что Line[Pos] in IntChars
    // Возвращает позицию следующего за концом числа символа
    procedure ProcessNumber(var Pos: Integer);
    var Token: TToken;
        WordBeg: Integer;
        ValidChars: TCharSet;
    begin
        Token := tokInteger;
        ValidChars := IntChars + [PA.LiteralDecimalPoint];
        WordBeg := Pos;
        repeat
            Inc(Pos);
            if Line[Pos] = PA.LiteralDecimalPoint then
                if Token = tokInteger
                    then Token := tokFloat
                    else Break;
        until (Pos > Length(Line)) or not (Line[Pos] in ValidChars);
        AddToken(WordBeg, Pos - WordBeg, Token);
    end;

var //Word: string;
    Col, WordBeg: Integer;
    c: Char;


    procedure DoOnUserToken(StartPos: Integer;Token: TToken);
    begin
        PA.OnUserToken(self, Copy(Line,StartPos,Col-StartPos), StartPos, LineIndex, Token);
    end;

    function ProcessReservedWord(StartPos: Integer;Token: TToken):boolean;
    begin
     Result:=False;
//     if Assigned(FRese)
    end;

    function IsBlank(const Line:string;var StartPos:integer;EndPos:integer):boolean;
    var i:integer;
    begin
      Result:=True;
      for i:=StartPos to EndPos do
       if Line[i]>' ' then
       begin
        StartPos:=i;
        Result:=False;
        Exit
       end
    end;

    procedure ProcessWord(StartPos: Integer);
    var Token: TToken;
    begin
//        if  Col-StartPos = 0 then Exit;
        if IsBlank(Line,StartPos,Col-1) then
        begin
         WordBeg:=Col;
         Exit;
        end;
        Token := tokText;

        if Assigned(DefUserTokenEventProc) then
          DefUserTokenEventProc(self, StartPos,Col-1, Line, Token);
        // User event
        if Assigned(PA.OnUserToken) then
         DoOnUserToken(StartPos,Token);
//            PA.OnUserToken(self, Copy(Line,StartPos,Col-StartPos), StartPos, LineIndex, Token);


        AddToken(StartPos, Col-StartPos , Token);
        WordBeg:=Col;
    end;

{    function IsCharAlphaNumeric(c: Char): Boolean;
    begin
        Result := Windows.IsCharAlphaNumeric(c) or (c = '_');
    end;
 }
begin
    Clear;
    Result := LastToken;
    if (Length(Line) = 0) or (PA = nil) then Exit;
{    if Line[Length(Line)] >= ' ' then
        Line := Line + ' ';                                 }
 
    WordBeg := 1;

    Col := 1;
    while Col <= Length(Line) do begin

        // Next AnsiChar
        c := Line[Col];

        // Сразу обрабатываем открытые и потенциальные комментарии
        if InComment(Result) or TestCommentsBegin(Col, Result) then begin
//            ProcessWord(Word, WordBeg);
            ProcessWord(WordBeg);
            ProcessComments(Col, Result);
            WordBeg:=Col;
        end else

        // Strings supply
        if c = PA.LiteralString then begin
            ProcessWord(WordBeg);
            ProcessString(Col);
            WordBeg:=Col;
        end else

        // AnsiChar supply
        if (c = PA.LiteralChar)and(poHasChar in PA.ParseOptions) then begin
            ProcessWord( WordBeg);
            ProcessChar(Col);
            WordBeg:=Col;
        end else

        // Numbers supply: Hex
        if (poHasHexPrefix in PA.ParseOptions)
        and (PosEx(PA.LiteralHexPrefix, Line, Col) = Col) then begin
            ProcessWord( WordBeg);
            ProcessHexValue(Col);
            WordBeg:=Col;
        end else

        // Numbers supply: Integer and Float
        if (c in IntChars)
        and ((Col = 1) or not IsCharAlphaNumeric(Line[Col-1])) then begin
            ProcessWord( WordBeg);
            ProcessNumber(Col);
            WordBeg:=Col;
        end else

        begin
            Result := tokText;
            if c in OperatorChars then
              Result:=tokOperator
            else  
            case c of
            '.':    Result := tokPoint;
            ',':    Result := tokComma;
            ';':    Result := tokEndLine;
            '(':    Result := tokParenBeg;
            ')':    Result := tokParenEnd;
            '[':    Result := tokBrackedBeg;
            ']':    Result := tokBracketEnd;
            else
                if (poHasReference in PA.ParseOptions)
                and (c = PA.LiteralReference) then
                    Result := tokReference
                else
                if (poHasDereference in PA.ParseOptions)
                and (c = PA.LiteralDereference) then
                    Result := tokDereference;
            end;
            if Result <> tokText then begin
                ProcessWord( WordBeg);
                AddToken(Col, 1, Result);
                WordBeg:=Col+1;
            end else

            {.. Some other tokens here ..}

            begin
                if (c <= ' ')  then
                begin
                     ProcessWord( WordBeg);
                end
                else
                if (Col = Length(Line)) then
                begin
                     Inc(Col);
                     ProcessWord( WordBeg);
                end
{                else
//                if CharRangeChange(c, Word[Length(Word)]) then begin
                if (Col>1) and CharRangeChange(c, Line[Col-1]) then begin
                    ProcessWord( WordBeg);
//                    Word := c;
                    WordBeg := Col;
                end
{                else
                    Word := Word + c;}
            end;

            Inc(Col);
        end;
    end;
end;


// Class TMPSynMemoStrings methods implementation

var GlobalUntitledIndex: Integer = 1;
const UNTITLEDFN = 'Untitled';


// Create() Конструктор
constructor TMPSynMemoStrings.Create(const Owner: TMPCustomSyntaxMemo);
begin
    inherited Create;
    fRichMemo   := Owner;
    fState      := [];
    FileName    := UNTITLEDFN + IntToStr(GlobalUntitledIndex) + '.txt';
    Inc(GlobalUntitledIndex);

    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Strings.Create');
    {$ENDIF}
end;


// Clear() Очищает ссодержимое, удаляя ключевый объекты
procedure TMPSynMemoStrings.Clear;
var i: Integer;
    Da: Boolean;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.Clear {');
    {} {$ENDIF}
    BeginUpdate;
    // Сохраняем текущий режим и устанавливаем режим прямого доступа к тексту
    Da := fDirectAccess;
    fDirectAccess := True;
    // Очищаем все строки
    for i := Count - 1 downto 0 do
        Objects[i].Free;
    inherited Clear;
    fRichMemo.Sections.Scan;
    fRichMemo.Reset;
    // Восстанавливаем режим
    fDirectAccess := Da;
    fState := fState + [ssNeedReparseAll, ssNeedReIndex];
    SetModified(True);
    EndUpdate;
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('} Strings.Clear');
    {} {$ENDIF}
    fRichMemo.Change([ciText, ciSelection, ciSections, ciUndoStack]);
    fRichMemo.NeedRedrawAll;   
end;


// Преобразует отсчет от начала файла в значение строки и символа в ней
function TMPSynMemoStrings.PositionToRC(Value: Integer): TPoint;
var i: Integer;
begin
    for i := 0 to Count - 1 do
        if Value < Length(Get(i)) + 2 then begin
            Result := Point(Value, i);
            Exit;
        end else
            Dec(Value, Length(Get(i)) + 2);
    Result.Y := Count - 1;
    Result.X := Length(Get(Result.Y));
end;


// Преобразует значение символа в заданной строке в его отсчет от начала текста
function TMPSynMemoStrings.RCToPosition(Col, Row: Integer): Integer;
var i: Integer;
begin
    Result := 0;
    for i := 0 to Row - 1 do
        Inc(Result, Length(Get(i)) + 2);
    Inc(Result, Col);
end;


// Устанавливает содержимое заданной строки
procedure TMPSynMemoStrings.Put(Index: Integer; const s: string);
begin
    if fDirectAccess then
        inherited Put(Index, s)
    else begin
        BeginUpdate;
        // Изменяем строку
        inherited Put(Index, s);
        // Помечаем строку как изменившуюся
        Parser[Index].NeedReparse := True;
        Include(fState, ssTextChanged);
        // Её надо перерисовывать, если она видна, конечно,
        // но эта строка закомментирована, поскольку неявно это будет
        // сделано при репарсинге
        { fRichMemo.NeedRedraw(Index); }
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Strings.Put(%d, "%s")', [Index, s]);
        {} {$ENDIF}
        EndUpdate;
    end;
end;

function   TMPSynMemoStrings. Add(const s: string):Integer;
begin
  Result :=Count;
  Insert(Result,s)

end;

// Вставляет строку после заданной
procedure TMPSynMemoStrings.Insert(Index: Integer; const s: string);
begin
    if fDirectAccess then
    begin
//        inherited InsertItem(Index, s, TMPSyntaxParser.Create)
     inherited Insert(Index, s);
     Objects[Index]:=TMPSyntaxParser.Create
    end
    else begin
        BeginUpdate;
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Strings.Insert(%d, "%s") {', [Index, s]);
        {} {$ENDIF}
        // Вставляем строку
//        inherited InsertItem(Index, s, TMPSyntaxParser.Create);
         inherited Insert(Index, s);
         Objects[Index]:=TMPSyntaxParser.Create;


        // Помечаем строку как изменившуюся
        Parser[Index].NeedReparse := True;
        Include(fState, ssTextChanged);
        // Корректируем секции, если это не откат, конечно
        if not (ssUndoProcess in fState) then
            fRichMemo.Sections.InsertRow(Index);
        { TODO : Это не совсем так.. Перерисовывать нужно только строки ниже этой }
        // При добавлении строки ВСЕГДА перерисовываем ВЕСЬ текст
        fRichMemo.NeedRedrawLE(Index);
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('} Strings.Insert');
        {} {$ENDIF}
        EndUpdate;
    end;
end;


// Удаляет заданную строку
procedure TMPSynMemoStrings.Delete(Index: Integer);
begin
    if DirectAccess then
        inherited Delete(Index)
    else begin
        BeginUpdate;
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Strings.Delete(%d) {', [Index]);
        {} {$ENDIF}
        // Корректируем секции, если это не откат
        if not (ssUndoProcess in fState) then
            fRichMemo.Sections.DeleteRow(Index);
        // Освобождаем StringParser этой строки
        if Assigned(Objects[Index]) then
            Objects[Index].Free;
{           FreeParser(TMPSyntaxParser(Objects[Index]));}
        // Удаляем строку
        inherited Delete(Index);
        // Строка, севшая на её место, может зависить от удаленной
        if Index<Count then
         Parser[Index].NeedReparse := True;
        Include(fState, ssTextChanged);
        { TODO : Это не совсем так.. Перерисовывать нужно только строки ниже этой }
        // При удалении строки ВСЕГДА перерисовываем ВЕСЬ текст
        if Index<Count then
         fRichMemo.NeedReDrawLE(Index);
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('} Strings.Delete');
        {} {$ENDIF}
        EndUpdate;
    end;
end;


// Устанавливает флаг изменения - ЗАГЛУШКА
procedure TMPSynMemoStrings.Changed;
begin
end;


// SetUpdateState() Установка признака блокировки
procedure TMPSynMemoStrings.SetUpdateState(Updating: Boolean);
begin
    inherited;
    if Updating then begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('BeginUpdate {');
        {} {$ENDIF}

        fRichMemo.HideCaret;
        fState := fState - [ssTextChanged, ssSectionsChanged, ssNeedReIndex, ssNeedReparseAll];
        fRichMemo.Change([]);

    end else begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('} EndUpdate');
        {} {$ENDIF}

        // Если строки менялись, устанавливаем состояние изменения
        if fState * [ssTextChanged, ssSectionsChanged] <> [] then
            SetModified(True);

        // Если необходимо, заново настраивает индексы строк
        if ssNeedReIndex in fState then
            fRichMemo.Sections.ReIndex;

        // Просматриваем строки. Производим парсинг строк, которые
        // изменились, либо зависят от изменившихся, пропуская пустые;
        // Измененные строки перерисовываем
        if fState * [ssTextChanged, ssNeedReparseAll] <> [] then
            Parse(ssNeedReparseAll in fState, True);

        // Перерисовываем строки, которые еще не перерисовывались
        // И переставляем курсор
        fRichMemo.ReDraw;

        // Обновляем ScrollBars
        if not (csDesigning in fRichMemo.ComponentState) then
            fRichMemo.UpdateScrollBars;
    end;
end;


// Тупой перерасчет всех строк (EntireText is True) или только изменившихся
// Если (NeedRepaint is True) - производится перерисовка измененных строк
procedure TMPSynMemoStrings.Parse(const EntireText : Boolean; const NeedRepaint: Boolean = False);
var Row: Integer;
    NeedNext: Boolean;
    Sp: TMPSyntaxParser;
begin
    // Просматриваем строки. Производим парсинг строк, которые
    // изменились, либо зависят от изменившихся, пропуская пустые;
    NeedNext := False;
    Row := 0;
    while Row < Count do begin
        Sp := Parser[Row];
        if EntireText or Sp.NeedReparse then begin
            NeedNext := Self.ParseLine(Row, not EntireText);
            if NeedRepaint then
                fRichMemo.NeedRedraw(Row);
        end else
        if NeedNext and (Sp.Count <> 0) then begin
            NeedNext := Self.ParseLine(Row, True);
            if NeedRepaint then
                fRichMemo.NeedRedraw(Row);
        end;
        Inc(Row);
    end;
    fState := fState - [ssTextChanged, ssNeedReparseAll];
end;


// Parse() Расчет ключа строки
// !! Возвращает истину, если следующая строка требует пересчета ключа
// (в случае несовпадения признаков многострочного комментария в конце данной строки и начала следующей)
function TMPSynMemoStrings.ParseLine(const Index: Integer; const TestNextLine: Boolean): Boolean;
var i: integer;
    Key: TToken;
begin
    Result := False;
    // Перемычка - для случая удаления последней строки
    if Index >= Count then Exit;
    Key := tokText;

    // Просматриваем предыдущую непустую строку в надежде,
    // что текущая строка входит в мультистрочный комментарий
    for i := Index - 1 downto 0 do
        with Parser[i] do
            if Count > 0 then begin
                if LastToken in [tokMLCommentBeg, tokELCommentBeg, tokMLCompDirBeg] then
                    Key := LastToken;
                Break;
            end;

    // Парсинг строки
    {$IFDEF SYNDEBUG}
    fRichMemo.LogFmt('Strings.Parse %d', [Index]);
    {$ENDIF}
    Key := Parser[Index].Parse(Get(Index), Index, Key, fRichMemo.fParseAttributes);

    // Если необходимо (TestNextLine = True),
    // то просматриваем непустую строку ниже, для того,
    // чтобы понять - нужно ее определять заново, или нет.
    if TestNextLine then
        for i := Index + 1 to Count - 1 do
            with Parser[i] do
                if Count > 0 then begin
                    Result := ((Key   = tokMLCommentBeg) and (FirstToken <> Key))
                           or ((Key   = tokELCommentBeg) and (FirstToken <> Key))
                           or ((Key   = tokMLCompDirBeg) and (FirstToken <> Key))
                           or ((FirstToken = tokMLCommentBeg) and (Key <> FirstToken))
                           or ((FirstToken = tokELCommentBeg) and (Key <> FirstToken))
                           or ((FirstToken = tokMLCompDirBeg) and (Key <> FirstToken));
                    Break;
                end;

end;


// LoadFromStream() Загружает текст из потока
// После загрузки разбирается с секциями, удаляя маркеры и производит полный репарсинг
procedure TMPSynMemoStrings.LoadFromStream(Stream: TStream);
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.LoadFromStream {');
    {} {$ENDIF}

    BeginUpdate;
    { Разрешаем прямое изменение строк }
    fDirectAccess := True;
    try
        inherited LoadFromStream(Stream);
    finally
        fDirectAccess := False;
        // Заново сканируем секции
        fRichMemo.Sections.Scan;
        // Требуется перерисовка, переиндексация, репарсинг
        fRichMemo.NeedRedrawAll;
        fState := [ssNeedReIndex, ssNeedReparseAll];
        EndUpdate;
    end;

    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('} Strings.LoadFromStream - Ok');
    {} {$ENDIF}
    // Текст сурово обновился
    fRichMemo.Change([ciText, ciSelection, ciSections, ciUndoStack]);
end;


// SaveToStream() Сохраняет текст в поток.
// Предварительно, если необходимо, добавляет маркеры секций
procedure TMPSynMemoStrings.SaveToStream(Stream: TStream);
var Sl: TStringList;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.SaveToStream');
    {} {$ENDIF}

    // Создаем вспомогательный текст
    Sl := TStringList.Create;
    // Куда и копируем имеющийся
    Sl.Assign(self);
    // Если в настройках указано запись маркеров секций,
    // выполняем заданную коррекцию временного текста
    if smoWriteMarkersOnSave in fRichMemo.Options then
        fRichMemo.Sections.FillOutput(Sl);
    try
        // Пишем временный текст в поток
        Sl.SaveToStream(Stream);
    finally
        // Забываем его
        Sl.Free;
    end;
    // Текст записан - потому сбрасываем флаг изменения
    SetModified(False);
    // Обновить информацию о тексте
    fRichMemo.Change([ciText]);
end;


// Загружает текст из файла, устанавливая свойства имени файла
// и признака изменения содержимого.
procedure TMPSynMemoStrings.LoadFromFile(const NewFileName: string);
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.LoadFromFile(' + NewFileName + ') {');
    {} {$ENDIF}

    inherited;
    // Новое имя.. =)
    FileName := NewFileName;
    fVirtualFileName := False;
    // Сброс первоначального обновления
    SetModified(False);

    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('} Strings.LoadFromFile - Ok');
    {}{$ENDIF}
end;


// Сохраняет содержимое в файле с заданным именем
procedure TMPSynMemoStrings.SaveToFile(const NewFileName: string);
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.SaveToFile(' + NewFileName + ')');
    {} {$ENDIF}

    inherited;
    FileName := NewFileName;
    fVirtualFileName := False;
    SetModified(False);
end;


// New() Создает новый документ
procedure TMPSynMemoStrings.New;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.New');
    {} {$ENDIF}
    Clear;
    fRichMemo.Reset;
    FileName := UNTITLEDFN + IntToStr(GlobalUntitledIndex) + '.txt';
    fVirtualFileName := True;
    Inc(GlobalUntitledIndex);
    fState := [];
    fRichMemo.Change([ciText, ciSelection, ciSections, ciUndoStack]);

    //SiO: Создадим пустую строчку, а то пользователю печатать будет негде...
    Add('');
//    InsertItem(Count,'',nil);

end;


// IsValidLineIndex() Допустим ли заданный индекс строки
function TMPSynMemoStrings.IsValidLineIndex(const Row: Integer): Boolean;
begin
    Result := InRange(Row, 0, Count - 1);
end;


// GetParser() Гарантированно возвращает парсер указанной строки
function TMPSynMemoStrings.GetParser(const Row: Integer): TMPSyntaxParser;
begin
    Result := TMPSyntaxParser(Objects[Row]);
end;


// SetFileName() Устанавливает имя файла
procedure TMPSynMemoStrings.SetFileName(const Value: string);
var F: TCustomForm;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Strings.SetFileName(' + Value + ')');
    {} {$ENDIF}
    fFileName := Value;
    { Выводим имя файла в заголовок закладки }
    if (smoShowFileNameInTabSheet in fRichMemo.fOptions)
    and Assigned(fRichMemo.Parent)
    and (fRichMemo.Parent is TTabSheet) then
        TTabSheet(fRichMemo.Parent).Caption := ExtractFileName(fFileName);
    { Выводим имя файла в заголовок формы }
    if smoShowFileNameInFormCaption in fRichMemo.fOptions then begin
        F := GetParentForm(fRichMemo);
        if F <> nil then
            F.Caption := Application.Title + '-' + fFileName;
    end;
end;


// SetModified() Сбрасывает показатель изменения текста
procedure TMPSynMemoStrings.SetModified(const Value: Boolean);
begin
    if Value <> fModified then begin
        fModified := Value;
        {$IFDEF SYNDEBUG}
        fRichMemo.Log('Strings.SetModified ' + BoolToStr(Value));
        {$ENDIF}
        fRichMemo.Change([ciText]);
    end;
end;



{ TMPSMSectionClone }

// Увеличивает счетчик ссылок на 1
procedure TMPSMSectionClone.AddRef;
begin
    Inc(fRefCount);
end;


// Уменьшает счетчик ссылок на 1.
// Как только счетчик станет равным 0, объект уничтожается
procedure TMPSMSectionClone.Release;
begin
    Dec(fRefCount);
    if fRefCount <= 0 then Free;
end;

//SiO: Делаем копию
procedure TMPSMSectionClone.Assign(original:TMPSMSectionClone);
begin
  fParent:=original.fParent;
  fRowBeg:=original.fRowBeg;
  fRowEnd:=original.fRowEnd;
  fLevel:=original.fLevel;
  fCollapsed:=original.fCollapsed;
end;




// Class TMPSynMemoSection Implementation

// Create() Конструктор
constructor TMPSynMemoSection.Create;
begin
    inherited Create(True);
end;


// GetSections() Возвращает вложенную секцию по индексу
function TMPSynMemoSection.GetSections(const Idx: Integer): TMPSynMemoSection;
begin
    Assert(InRange(Idx, 0, Count - 1), 'Bad nested section index: ' + IntToStr(Idx));
    Result := TMPSynMemoSection(Items[Idx])
end;


// Устанавливает новый уровень вложенности секции
// Рекурсивно изменяет уровень внутренних секций
procedure TMPSynMemoSection.SetLevel(const Value: Integer);
var i: Integer;
begin
    fLevel := Value;
    for i := 0 to Count - 1 do
        Sections[i].SetLevel(fLevel + 1);
end;



// Class TMPSynMemoManager Implementation

// Create() Конструктор менеджера секций
constructor TMPSynMemoSections.Create(Owner: TMPCustomSyntaxMemo);
begin
    inherited Create;
    fRichMemo := Owner;
    fRoot     := TMPSMSectionClone.Create;
    fIndexes  := TList.Create;
    fRoot.AddRef;
    Scan;
end;


// Destroy() Деструктор менеджера секций
destructor TMPSynMemoSections.Destroy;
begin
    fIndexes.Free;
    fRoot.Free;
    inherited;
end;


// Возвращает тип заголовка секции
class function TMPSynMemoSections.DetectSectionMark(const s: string): TSectionMark;
begin
    if s = '' then Result := smNone else
    if PDWORD(s)^ = PDWORD(SectionMarks[smExpanded])^ then Result := smExpanded else
    if PDWORD(s)^ = PDWORD(SectionMarks[smCollapsed])^ then Result := smCollapsed else
    if PDWORD(s)^ = PDWORD(SectionMarks[smEnd])^ then Result := smEnd else
        Result := smNone;
end;


// Возвращает тип заголовка секции, которому принадлежит строка
function TMPSynMemoSections.SectionBorder(const Row: Integer): TSectionMark;
begin
    with Section[Row] do
        if Row = RowBeg then
            if Collapsed
                then Result := smCollapsed
                else Result := smExpanded
        else
            if Row = RowEnd
                then Result := smEnd
                else Result := smNone;
end;


// Возвращает следующую секцию после заданной без учета видимости и вложенности
function TMPSynMemoSections.Next(Sec: TMPSynMemoSection): TMPSynMemoSection;
    {}
    function _next(Sec: TMPSynMemoSection): TMPSynMemoSection;
    var n: Integer;
    begin
        if Sec = fRoot then
            Result := nil
        else begin
            n := Sec.Parent.IndexOf(Sec);
            if n < Sec.Parent.Count - 1
                then Result := Sec.Parent.Sections[n + 1]
                else Result := _next(Sec.Parent);
        end;
    end;
    {}
begin
    if Sec.Count > 0
        then Result := TMPSynMemoSection(Sec.First)
        else Result := _next(Sec);
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Sections.Next');
    {$ENDIF}
end;


// Возвращает предыдущую секцию перед заданной без учета видимости и вложенности
function TMPSynMemoSections.Prev(Sec: TMPSynMemoSection): TMPSynMemoSection;
    function _last(Sec: TMPSynMemoSection): TMPSynMemoSection;
    begin
        Result := Sec;
        if Result.Count > 0 then
            Result := _last(TMPSynMemoSection(Result.Last));
    end;
var n: Integer;
begin
    if Sec = fRoot then
        Result := nil
    else begin
        n := Sec.Parent.IndexOf(Sec);
        if n > 0 then
            Result := _last(Sec.Parent.Sections[n - 1])
        else
        if Sec.Parent = fRoot then
            Result := nil
        else
            Result := Sec.Parent;
    end;
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Sections.Prev');
    {$ENDIF}
end;


// Возвращает секцию, которой принадлежит строка
function TMPSynMemoSections.GetSection(const Row: Integer): TMPSynMemoSection;
begin
    Result := fRichMemo.Lines.Parser[Row].Section;
end;


// Устанавливает секцию, которой принадлежит строка
procedure TMPSynMemoSections.SetSection(const Row: Integer; Value: TMPSynMemoSection);
begin
    fRichMemo.Lines.Parser[Row].Section := Value;
end;


// Возвращает True, если хотябы заголовок секции виден
// !!! Работает только после переиндексации строк !!!
function TMPSynMemoSections.Visible(const Sec: TMPSynMemoSection): Boolean;
begin
    if ssNeedReIndex in fRichMemo.Lines.State then
        ReIndex;
    Result := fRichMemo.Lines.Parser[Sec.RowBeg].VisibleIndex >= 0;
end;


// Плющит заданную секцию
// Если Recursive = True, плющит все вложенные секции
procedure TMPSynMemoSections.Collapse(const Row: Integer; const Recursive, SafeSelf: Boolean);
var Sec: TMPSynMemoSection;
    { Для чистой рекурсии }
    procedure CollapseChildren(Father: TMPSynMemoSection);
    var i: Integer;
    begin
        if Recursive then
            for i := Father.Count - 1 downto 0 do
                CollapseChildren(Father[i]);
        if (Father.Level = 0) or ((Father = Sec) and SafeSelf) then Exit;
        Father.Collapsed := True;
    end;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.Collapse(%d)', [Row]);
    {} {$ENDIF}

    // Секции должны быть подготовлены
    with fRichMemo.Lines do begin
        if ssNeedReindex in State then ReIndex;
        BeginUpdate;
        Sec := Section[Row];
        CollapseChildren(Sec);
        State := State + [ssNeedReIndex];
        fRichMemo.NeedRedrawAll;
        EndUpdate;
    end;
    fRichMemo.Change([ciSections]);
end;


// Раскрывает заданную секцию
// Если Recursive = True, раскрывает все вложенные секции
// Если ParentRecursive = True, раскрывает всех родителей
procedure TMPSynMemoSections.Expand(const Row: Integer; const Recursive, ParentRecursive: Boolean);
    procedure ExpandChildren(Father: TMPSynMemoSection);
    var i: Integer;
    begin
        Father.Collapsed := False;
        if Recursive then
            for i := Father.Count - 1 downto 0 do
                ExpandChildren(Father[i]);
    end;
var Sec: TMPSynMemoSection;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.Expand(%d)', [Row]);
    {} {$ENDIF}

    // Секции должны быть подготовлены
    if ssNeedReindex in fRichMemo.Lines.State then
        ReIndex;
    with fRichMemo.fLines do begin
        BeginUpdate;
        Sec := Self.Section[Row];
        ExpandChildren(Sec);
        if ParentRecursive then
            while Sec.Level > 1 do begin
                Sec := Sec.Parent;
                Sec.Collapsed := False;
            end;
        State := State + [ssNeedReIndex];
        fRichMemo.NeedRedrawAll;
        EndUpdate;
    end;
    fRichMemo.Change([ciSections]);
end;


// Разбивает секцию.
// Если Recursive = True, разбить все вложенные секции
procedure TMPSynMemoSections.Explode(const Row: Integer; const Recursive: Boolean);
    { Recurse }
    procedure ExplodeChildren(Father: TMPSynMemoSection);
    var i, n: Integer;
        Child: TMPSynMemoSection;
    begin
        if Father.Level > 0 then begin
            n := Father.Parent.IndexOf(Father);
            for i := Father.Count-1 downto 0 do begin
                // Если внутри этой секции есть вложенные,
                // они тоже теперь принадлежат родителю
                Child := Father[i];
                Child.Level := Child.Level - 1;
                Child.Parent := Father.Parent;
                Father.Parent.Insert(n+1, Father.Extract(Child));
                if Recursive then
                    ExplodeChildren(Child);
            end;
            // Если строка ранее принадлежала родительской секции,
            // теперь она принадлежит родителю разрушенной секции
            for i := Father.RowBeg to Father.RowEnd do
                with fRichMemo.Lines.Parser[i] do
                    if Section = Father then
                        Section := Father.Parent;
            // Удаляем разрушенную секцию
            Father.Parent.Delete(n);
        end;
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.Explode(%d)', [Row]);
    {} {$ENDIF}

    // Секции должны быть подготовлены
    if ssNeedReindex in fRichMemo.Lines.State then
        ReIndex;
    { TODO : С этим разобраться - что-то здесь не так.. }
    MakeUnique;
    with fRichMemo.Lines do begin
        BeginUpdate;
        ExplodeChildren(Section[Row]);
        State := State + [ssSectionsChanged, ssNeedReIndex];
        fRichMemo.NeedRedrawAll;
        SetModified(True);
        EndUpdate;
    end;
    fRichMemo.Change([ciText, ciSelection, ciSections]);
end;


{ Создает новую секцию с охватом возможных существующих }
function TMPSynMemoSections.New(const Row1, Row2: Integer; const IsCollapsed: Boolean = False): TMPSynMemoSection;
var i: Integer;
    Father, iSec: TMPSynMemoSection;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.New(%d, %d)', [Row1, Row2]);
    {} {$ENDIF}

    // Секции должны быть подготовлены
    if ssNeedReindex in fRichMemo.Lines.State then
        ReIndex;
    { TODO : С этим разобраться - что-то здесь не так.. }
    MakeUnique;

    // Если одна строка принадлежит секции "A", а другая строка
    // принадлежит её родителю ("^A"), но при этом не является её границей,
    // то вначале разбиваем существующую секцию ("A"->(^A"),
    // а, затем, создаем её заново - либо с новым размером,
    // либо с новым местоположением
    if ((Section[Row2] = Section[Row1].Parent) and (SectionBorder(Row2) = smNone))
    or ((Section[Row1] = Section[Row2].Parent) and (SectionBorder(Row1) = smNone)) then
        Explode(Row1, False);

    // Если после всего этого исходные параметры остаются недопустимыми,
    // присваиваем результату nil и выходим из процедуры
    if (Section[Row1] <> Section[Row2])
    or (SectionBorder(Row1) <> smNone)
    or (SectionBorder(Row2) <> smNone) then begin
        Result := nil;
        Exit;
    end;

    // Пакетные изменения
    fRichMemo.Lines.BeginUpdate;

    // Будущий отец новой секции
    Father := Section[Row1];

    // Создаем новую секцию
    Result := TMPSynMemoSection.Create;
    Result.Parent    := Father;
    Result.RowBeg    := Row1;
    Result.RowEnd    := Row2;
    Result.Level     := Father.Level + 1;
    Result.Collapsed := IsCollapsed;

    // Соотносим секцию и новые строки
    for i := Row1 to Row2 do begin
        iSec := Section[i];
        // Если строка ранее принадлежала родительской секции,
        // теперь она принадлежит созданной дочерней секции
        // ( так часто бывает ;)
        if iSec = Father then
            Section[i] := Result
        else
        // Если внутри выделенного объема есть вложенные секции,
        // они тоже теперь принадлежат ребенку и имеют гораздо
        // меньшую значимость ;))
        if (i = iSec.RowBeg) and (iSec.Parent = Father) then begin
            iSec.Level := Result.Level + 1;
            iSec.Parent := Result;
            Result.Add(Father.Extract(iSec));
        end;
    end;

    // Вставляем новую секцию к детишкам старой
    i := Father.Count;
    while (i > 0) and (Father[i-1].RowBeg > Row1) do
        Dec(i);
    Father.Insert(i, Result);

    // Фиксируем изменения
    with fRichMemo.Lines do begin
        State := State + [ssSectionsChanged, ssNeedReIndex];
        fRichMemo.NeedRedrawAll;
        SetModified(True);
        EndUpdate;
    end;

    // Обновляемся
    fRichMemo.Change([ciText, ciSelection, ciSections]);
end;


// Удаляет строку - пересчитываются индексы секций
// !!! Только для вложений в пакетные изменения !!!
procedure TMPSynMemoSections.DeleteRow(const Row: Integer);
    { Recurse }
    procedure UpdateIndexes(Sec: TMPSynMemoSection);
    var i: Integer;
    begin
        if Sec.RowBeg > Row then Dec(Sec.fRowBeg);
        if Sec.RowEnd > Row then begin
            Dec(Sec.fRowEnd);
            { Рекурсивно пересчитываются индексы вложенных секций}
            for i := 0 to Sec.Count - 1 do
                UpdateIndexes( Sec.Sections[i] );
        end;
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.DeleteRow(%d)', [Row]);
    {} {$ENDIF}

    { TODO : С этим разобраться - что-то здесь не так.. }
    MakeUnique;

    // Если удаляемая строка является границей секции, секция разрушается.
    with fRichMemo do
        if Sections.SectionBorder(Row) <> smNone then
            Explode(Row, False);

    // .. а уже потом корректируются индексы
    UpdateIndexes(fRoot);
    with fRichMemo.Lines do
        State := State + [ssSectionsChanged, ssNeedReIndex];
end;


// Добавляется строка - пересчитываются индексы секций
// !!! Только для вложений в пакетные изменения !!!
procedure TMPSynMemoSections.InsertRow(const Row: Integer);
var ParentSec: TMPSynMemoSection;
    {}
    procedure UpdateIndexes(Sec: TMPSynMemoSection);
    var i: Integer;
    begin
        if Row <= Sec.RowBeg then
            Inc(Sec.fRowBeg);
        if Row <= Sec.RowEnd then begin
            Inc(Sec.fRowEnd);
            { Проверяем, не в эту ли секцию добавлена строка }
            if InRange(Row, Sec.RowBeg, Sec.RowEnd) and (Sec.Level > ParentSec.Level) then
                ParentSec := Sec;
            { Рекурсивно пересчитываются индексы вложенных секций}
            for i := 0 to Sec.Count - 1 do
                UpdateIndexes( Sec.Sections[i] );
        end;
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Sections.InsertRow(%d)', [Row]);
    {} {$ENDIF}

    { TODO : С этим разобраться - что-то здесь не так.. }
    MakeUnique;
    ParentSec := fRoot;
    UpdateIndexes(fRoot);
    Section[Row] := ParentSec;
    with fRichMemo.Lines do
        State := State + [ssSectionsChanged, ssNeedReIndex];
end;


// FillOutput() Заполняет выходной текст в зависимости от опций менеджера смекций
procedure TMPSynMemoSections.FillOutput(const Sl: TStringList);
const pm: array[Boolean] of string[4] = ('{<+}', '{<-}');
    {}
    procedure MarkSection(Sec: TMPSynMemoSection);
    var i: Integer;
    begin
        if Sec <> fRoot then begin
            Sl[Sec.RowBeg] := pm[Sec.Collapsed] + Sl[Sec.RowBeg];
            Sl[Sec.RowEnd] := '{>>}' + Sl[Sec.RowEnd];
        end;
        for i := 0 to Sec.Count - 1 do
            MarkSection(Sec.Sections[i]);
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Sections.FillOutput');
    {} {$ENDIF}
    MarkSection(fRoot);
end;


{ TODO : ВОТ С ЭТИ И БУДЕМ РАЗБИРАТЬСЯ - завтра с утра }
// Текущее дерево секций становится уникальным
procedure TMPSynMemoSections.MakeUnique;
    { Создает копию секции - recurse }
    function Clone(const Father, Sec: TMPSynMemoSection): TMPSynMemoSection;
    var i: Integer;
    begin
        Result := TMPSynMemoSection.Create;
        Result.fParent    := Father;
        Result.fRowBeg    := Sec.fRowBeg;
        Result.fRowEnd    := Sec.fRowEnd;
        Result.fLevel     := Sec.fLevel;
        Result.fCollapsed := Sec.fCollapsed;
        for i := 0 to Sec.Count - 1 do
            Result.Add( Clone(Result, Sec.Sections[i]) );
    end;
    {}
var NewRoot: TMPSMSectionClone;
    i: Integer;
begin
    if ssUndoProcess in fRichMemo.Lines.State then Exit;
    if fRoot.fRefCount > 1 then begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Sections.MakeUnique %d->%d', [fRoot.fRefCount, fRoot.fRefCount + 1]);
        {} {$ENDIF}

        { Создаем реальный /занимающий отдельную память/ клон дерева секций }
        NewRoot := TMPSMSectionClone.Create;
        NewRoot.fParent    := nil;
        NewRoot.fRowBeg    := fRoot.fRowBeg;
        NewRoot.fRowEnd    := fRoot.fRowEnd;
        NewRoot.fLevel     := 0;
        NewRoot.fCollapsed := False;
        for i := 0 to fRoot.Count - 1 do
            NewRoot.Add( Clone(NewRoot, fRoot.Sections[i]) );
        SetRoot(NewRoot);
    end else begin

        { Создаем виртуальный /индексация счетчиком ссылок/ клон дерева секций }
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.Log('Sections.MakeUnique VIRTUAL');
        {} {$ENDIF}
    end;
end;


// Возвращает данные секций как многострочный текст
function TMPSynMemoSections.AsText: string;
var sl: TStringList;
    procedure SecAsString(Sec: TMPSynMemoSection);
    var i: Integer;
    begin
        sl.Append(Format('%s%d..%d %s',
           [StringOfChar(' ', Sec.Level * 4),
            Sec.RowBeg,
            Sec.RowEnd,
            IfThenStr(Sec.Collapsed, 'Collapsed','')]));
        for i := 0 to Sec.Count - 1 do
            SecAsString(Sec.Sections[i]);
    end;
begin
    sl := TStringList.Create;
    sl.Append('Sections');
    SecAsString(fRoot);
    sl.Append('End of sections');
    Result := sl.Text;
    sl.Free;
end;


// Заново переиндексирует строки соответствия секций
procedure TMPSynMemoSections.ReIndex;
var Row: Integer;
    {}
    procedure ProcessSection(const Sec: TMPSynMemoSection; ParentOpen: Boolean);
    var ChildIndex: Integer;
    begin
        ChildIndex := 0;
        if Sec.Level > fMaxLevel then fMaxLevel := Sec.fLevel;
        if ParentOpen and (Sec.fLevel > fMaxExpandLevel)
            then fMaxExpandLevel := Sec.fLevel;
{ TODO -oBuzz : 
Когда накрываешь большой текст пастой маленького - АВ
Тупо забью. Потом разберусь. }
       if fRichMemo.Lines.Count<=Sec.fRowEnd then
        Sec.fRowEnd:=fRichMemo.Lines.Count-1;
        while Row <= Sec.fRowEnd do begin
            if (ChildIndex >= Sec.Count)
            or (Row < Sec.Sections[ChildIndex].RowBeg)
            or (Row > Sec.Sections[ChildIndex].RowEnd) then begin
                with fRichMemo.Lines.Parser[Row] do begin
                    Section := Sec;
                    if ParentOpen and (not Sec.Collapsed or (Row = Sec.RowBeg))
                        then fVisibleIndex := fIndexes.Add(Pointer(Row))
                        else fVisibleIndex := -1;
                end;
                Inc(Row);
            end else begin
                ProcessSection(Sec.Sections[ChildIndex], ParentOpen and not Sec.Collapsed);
                Inc(ChildIndex);
            end;
        end;
    end;
    {}
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Sections.ReIndex');
    {} {$ENDIF}
    Dec(fRoot.fRowEnd);
    fMaxLevel       := 0;
    fMaxExpandLevel := 0;
    Row             := 0;
    fIndexes.Clear;
    ProcessSection(fRoot, True);
    Inc(fRoot.fRowEnd);
    { Фиксируем обновление }
    fRichMemo.Lines.State := fRichMemo.Lines.State - [ssNeedReIndex];
    { Вызываем процедуру поддержки }
    fRichMemo.Change([ciSections]);
end;


// Задает новый корень секций (он может был сохранен в Undo)
procedure TMPSynMemoSections.SetRoot(const Value: TMPSMSectionClone);
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Sections.SetRoot');
    {$ENDIF}
    { Если дерево не меняется, просто переиндексируем строки }
    if fRoot <> Value then begin
        fRoot.Release;
        fRoot := Value;
        fRoot.AddRef;
    end;
    { Обновляем строки }
    ReIndex;
end;


// Прочитывает весь текст и создает набор секций
procedure TMPSynMemoSections.Scan;
var Row, i: Integer;
    ParentSec, Sec: TMPSynMemoSection;
    Stack: TObjectStack;
    Sm: TSectionMark;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Sections.SCAN');
    {$ENDIF}
    { Очищаем корень секций }
    with fRoot do begin
        Clear;
        fRowBeg     := -1;
        fRowEnd     := fRichMemo.fLines.Count;
        fLevel      := 0;
        fParent     := nil;
        fCollapsed  := False;
    end;

    { Создаем стек открытых секций }
    Stack := TObjectStack.Create;

    { Просматривает весь текст и создаем новое дерево секций }
    Row := 0;
    ParentSec := fRoot;
    repeat
        while Row < fRichMemo.Lines.Count do begin
            Sm := TMPSynMemoSections.DetectSectionMark(fRichMemo.Lines[Row]);
            case Sm of
            smExpanded,
            smCollapsed:
                begin
                    { Создаем новую секцию }
                    Sec := TMPSynMemoSection.Create;
                    with Sec do begin
                        fRowBeg     := Row;
                        fRowEnd     := -1;
                        fLevel      := ParentSec.fLevel + 1;
                        fParent     := ParentSec;
                        fCollapsed  := Sm = smCollapsed;
                    end;
                    { Вкладываем ее внутрь ParentSec }
                    ParentSec.Add(Sec);
                    { Кладем ее в стек }
                    Stack.Push(Sec);
                    { Делаем ее родительской }
                    ParentSec := Sec;
                    { Каждая строка из заданного диапазона будет принадлежать этой секции }
                    fRichMemo.Sections.Section[Row] := ParentSec;
                    { Убираем маркер начала секции }
                    fRichMemo.Lines[Row] := StuffString(fRichMemo.Lines[Row], 1, SECTION_HEADER_LENGTH, '');
                end;
            smEnd:
                begin
                    { Проверяем стек }
                    if Stack.Count = 0 then begin
                        // Ошибка: несогласованное закрытие секции (лишний {>>}):
                        // Восстановление - вставляем строку с открытием секции
                        fRichMemo.fLines.Insert(Row, SectionMarks[smExpanded]);
                        Continue;
                    end;
                    { Достаем последнюю открытую секцию из стека и закрываем ее }
                    Sec := TMPSynMemoSection(Stack.Pop);
                    Sec.fRowEnd := Row;
                    { Каждая строка из заданного диапазона будет принадлежать этой секции }
                    fRichMemo.Sections.Section[Row] := Sec;
                    { Родительской секцией становится ее родитель }
                    ParentSec := Sec.fParent;
                    { Убираем маркер конца секции }
                    fRichMemo.Lines[Row] := StuffString(fRichMemo.Lines[Row], 1, SECTION_HEADER_LENGTH, '');
                end;
            else
                { Каждая строка из заданного диапазона будет принадлежать текущей секции }
                fRichMemo.Sections.Section[Row] := ParentSec;
            end;
            Inc(Row);
        end;

        { Проверяем стек на наличие открытых секций }
        if Stack.Count > 0 then
            // Ошибка: не хватает закрывашек {>>}:
            // Восстановление - добавляем строки с закрывашками
            for i := 0 to Stack.Count - 1 do
                fRichMemo.Lines.Append(SectionMarks[smEnd]);
    until Stack.Count = 0;

    { Освобождаем стек }
    Stack.Free;
end;


{ TMPSynMemoUndoItem }

// Деструктор.
destructor TMPSynMemoUndoItem.Destroy;
begin
    // Вначале освобождает дерево секций
    uiSections.Release;
    inherited;
end;



// Class TMPSynMemoRange Implementation

// Create() Конструктор
constructor TMPSynMemoRange.Create(Owner: TMPCustomSyntaxMemo);
begin
    inherited Create;
    fRichMemo     := Owner;
    fSealing      := True;
    fMaxUndoDepth := 100;
    fUndoStack := TObjectList.Create(True);
    fUndoStack.Capacity := 100;
    fOnSetPosProc:=nil;
end;


// Destroy() Деструктор
destructor TMPSynMemoRange.Destroy;
begin
fUndoStack.Clear;
fUndoStack.Free;
inherited;
end;

// Сдвигает выделенные строки вправо
procedure TMPSynMemoRange.MakeIndent;
var i: Integer;
begin
fRichMemo.Lines.BeginUpdate;
for i := StartY to EndY do
    fRichMemo.Lines[i] := '    ' + fRichMemo.Lines[i];
fRichMemo.Lines.EndUpdate;
end;

// Сдвигает выделенные строки влево
procedure TMPSynMemoRange.MakeUnIndent;
var i: Integer;
begin
fRichMemo.Lines.BeginUpdate;
for i := StartY to EndY do
    if copy(fRichMemo.Lines[i],1,4)='    '
       then fRichMemo.Lines[i] := copy(fRichMemo.Lines[i],5,length(fRichMemo.Lines[i])-4);
fRichMemo.Lines.EndUpdate;
end;

//Комментируем выделенные строки
procedure TMPSynMemoRange.MakeComment(LitILComment:string);
var i: Integer;
begin
if copy(fRichMemo.Lines[StartY],1,length(LitILComment))<>LitILComment
   then begin
        fRichMemo.Lines.BeginUpdate;
        for i := StartY to EndY do
            if copy(fRichMemo.Lines[i],1,length(LitILComment))<>LitILComment then
            fRichMemo.Lines[i] := LitILComment + fRichMemo.Lines[i];
        fRichMemo.Lines.EndUpdate;
        end
   else begin
        fRichMemo.Lines.BeginUpdate;
        for i := StartY to EndY do
            if copy(fRichMemo.Lines[i],1,length(LitILComment))=LitILComment then
               fRichMemo.Lines[i] := copy(fRichMemo.Lines[i],length(LitILComment)+1,Length(fRichMemo.Lines[i])-length(LitILComment));
        fRichMemo.Lines.EndUpdate;
        end;
end;


// Collaps() Сворачивает выделение к началу
procedure TMPSynMemoRange.Collapse;
var yb, ye: Integer;
    e: Boolean;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Range.Collapse');
    {} {$ENDIF}

    // Сохраняем значения начальной и конечной строк выделения ..
    yb       := fStart.Y;
    ye       := fEnd.Y;
    // .. и признака пустоты выделения
    e        := IsEmpty();
    // Включаем залипание
    // При этом, границы выделения всегда будут соответствовать позиции ввода
    fSealing := True;
    fStart   := fPos;
    fEnd     := fPos;
    // Устраняем следы прошлого - перерисовываем те строки,
    // где раньше былы границы выделения
    if not e then
        with fRichMemo do begin
            Lines.BeginUpdate;
            repeat
                NeedRedraw(yb);
                Inc(yb);
            until yb > ye;
            Lines.EndUpdate;
        end;
    // Подтверждение изменения
    fRichMemo.Change([ciSelection]);
end;


// Enlarge() Увеличивает область выделения на Value символов (или строк - если EnlargeLine is True)
procedure TMPSynMemoRange.Enlarge(const Value: Integer; const EnlargeLine: Boolean = False; const VisiblesOnly: Boolean = False);
var n, PrevY: Integer;
begin
    fRichMemo.Lines.BeginUpdate;
    fSealing := False;
    if not EnlargeLine then begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Range.Enlarge(Cols=%d)', [Value]);
        {} {$ENDIF}
        // Прикидываем увеличиваем/уменьшаем выделение по горизонтали
        n := PosX + Value;
        // Ограничиваем выделение в пределах текущей строки (как в Delphi)
        if n < 0 then n := -PosX else
            if n > Length(fRichMemo.Lines[PosY]) then n := Length(fRichMemo.Lines[PosY]) - PosX else
                n := Value;
        // Если в результате ограничений, ничего не сдвинуть - просто выходим
        if n <> 0 then begin
            // Корректируем границы выделения
            if (PosX = StartX) and (PosY = StartY) then Inc(fStart.X, n) else Inc(fEnd.X, n);
            if (StartY = EndY) and (StartX > EndX) then Swap(fStart.X, fEnd.X);
            // Перемещаем курсор по горизонтали, при необходимости осуществляя прокрутку
            PosX := PosX + n;
            // Перерисовываем текущую строку
            fRichMemo.NeedRedraw(PosY);
        end
    end else begin
        {} {$IFDEF SYNDEBUG}
        {} fRichMemo.LogFmt('Range.Enlarge(Rows=%d)', [Value]);
        {} {$ENDIF}
        // Прикидываем увеличиваем/уменьшаем выделение по вертикали
        if VisiblesOnly
            then n := fRichMemo.FindVisibleRow(PosY, Value, True)
            else n := EnsureRange(PosY + Value, 0, fRichMemo.Lines.Count - 1);

        // Если в результате ограничений, ничего не сдвинуть - просто выходим
        if n <> PosY then begin
            // Запоминаем начальную строку
            PrevY := PosY;

            // Корректируем границы выделения
            if PointsEqual(fPos, fStart)
                then fStart.Y := n
                else fEnd.Y := n;
            if fStart.Y<0 then
              fStart.Y :=0;
            if StartY > EndY then begin
                Swap(fStart.Y, fEnd.Y);
                Swap(fStart.X, fEnd.X);
            end;

            // Перемещаем курсор по вертикали, при необходимости осуществляя прокрутку
            PosY := n;

            // Перерисовываем строки с начальной по конечную
            for n := Min(PrevY, PosY) to Max(PrevY, PosY) do
                fRichMemo.NeedRedraw(n);
        end;
    end;
    fRichMemo.Lines.EndUpdate;
    fRichMemo.Change([ciSelection]);
end;


// Удаляет символ, разрыв строки или содержимое области выделения
procedure TMPSynMemoRange.Delete;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.Log('Range.Delete');
    {} {$ENDIF}
   if not IsEmpty then
    begin
//        fRichMemo.Lines.State := fRichMemo.Lines.State + [ssNeedReparseAll];
        if (StartY<fRichMemo.OffsetY) and (EndY>fRichMemo.OffsetY) then
         fRichMemo.OffsetY:=fRichMemo.OffsetY-(EndY-StartY);
        
        SetTextEx('',ukLetterDeleted)
    end
    else
    if PosX < Length(fRichMemo.fLines[PosY]) then begin
        // выделения нет; курсор не в конце строки - удаление символа
        EndX := StartX + 1;
        SetTextEx('',ukLetterDeleted);
    end else
    if PosY < fRichMemo.fLines.Count - 1 then begin
        // курсор в конце строки - объединение двух строк
        EndX := 0;
        EndY := StartY + 1;
        SetTextEx('',ukLetterDeleted);
    end;
end;


// Сворачивает секцию, в строке которой находится позиция ввода
procedure TMPSynMemoRange.CollapseSection(const Recursive: Boolean);
begin
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} Log('Range.CollapseSection');
        {} {$ENDIF}
        // Если курсор внутри секции, выносим его к заголовку секции
        if Sections.SectionBorder(PosY) in [smNone, smEnd] then
            SetPos( Point(0, Sections.Section[PosY].RowBeg) );
        Sections.Collapse(PosY, Recursive, Recursive);
    end;
end;


// Раскрываем секцию, в заголовке которой находится позиция ввода
procedure TMPSynMemoRange.ExpandSection(const Recursive: Boolean);
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.ExpandSection');
    {$ENDIF}
    fRichMemo.Sections.Expand(PosY, Recursive, False);
end;


// Разбиваем секцию
procedure TMPSynMemoRange.ExplodeSection(const Recursive: Boolean);
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.ExplodeSection');
    {$ENDIF}
    Collapse;
    AddUndo;
    fRichMemo.Sections.Explode(PosY, Recursive);
end;


// CreateSection() Создает секцию со строки Row1 по строку Row2
// Если Row2 = -1 (по умолчанию), создается новая секция Row1..Row1+1
procedure TMPSynMemoRange.CreateSection;
begin
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} Log('Range.CreateSection');
        {} {$ENDIF}
        Lines.BeginUpdate;
        // Row1 = Row2
        // Выделение пустое или располагается на одной строке текста
        // Курсор может находиться в любом месте строки
        // СТРОКА НЕ МОЖЕТ БЫТЬ ГРАНИЦЕЙ СУЩЕСТВУЮЩЕЙ СЕКЦИИ
        // Предварительно вставляется пустая строка
        if (StartY = EndY)
        and (Sections.SectionBorder(StartY) = smNone) then begin
            Collapse;
            // Генерим откат в виде команды удаления строки..
            with AddUndo() do begin
                uiSelStart := Point(0, StartY + 1);
                uiSelEnd   := Point(0, StartY + 2);
                uiSealing  := False;
            end;
            // .. которую мы щас добавим
            Lines.Insert(StartY + 1, '');
            // Генерим секцию
            Sections.New(StartY, StartY + 1);
        end else
        // Row1 < Row2
        // Выделение не пустое, начальная и конечная строки принадлежат
        // одной или разным секциям и не являются границами этих секций
        if (StartY <> EndY)
        and (Sections.SectionBorder(StartY) = smNone)
        and (Sections.SectionBorder(EndY) = smNone) then begin
            with AddUndo() do begin
                uiSelStart := fPos;
                uiSelEnd   := fPos;
                uiSealing  := True;
            end;
            Sections.New(fStart.Y, fEnd.Y);
            Collapse;
        end;
        SetPos(Point(0, fStart.Y));
        Lines.EndUpdate;
    end;
end;


// Переход к следующей (Delta=+1) или предыдущей (Delta=-1) секции,
// если это возможно, конечно
procedure TMPSynMemoRange.GotoSection(const GoForward: Boolean);
var Sec: TMPSynMemoSection;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Range.GotoSection(%s)', [BoolToStr(GoForward)]);
    {} {$ENDIF}
    // Получаем текущую секцию (к которой относится строка с курсором)
    Sec := fRichMemo.Sections.Section[PosY];
    // Пытаемся найти предыдущую или следующую секцию
    repeat
        if GoForward
            then Sec := fRichMemo.Sections.Next(Sec)
            else Sec := fRichMemo.Sections.Prev(Sec);
    until (Sec = nil) or fRichMemo.Sections.Visible(Sec);
    // Если секция найдена, устанавливаем курсор в её заголовок
    if Sec <> nil then
        SetPos( Point(0, Sec.RowBeg) );
end;


// Копирует в буфер обмена текст и информацию о вложенных секциях
procedure TMPSynMemoRange.CopyToClipboard;
var Data: THandle;
    DataPtr: Pointer;
    s: string;
    sa:AnsiString;
begin
    if IsEmpty then Exit;
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.CopyToClipboard');
    {$ENDIF}
    // Просто копируем текст
    Clipboard.AsText := self.GetText;
    // Если не запрещено, и границы выделения находятся в разных строках,
    // сохраняем информацию о границах вложенных секций
    if not (smoSkipSectionsOnCopy in fRichMemo.Options)
    and (fStart.Y <> fEnd.Y) then begin
        s := GetMarkedText;
        sa:=s;

        // Открываем буфер обмена
        OpenClipboard(Application.Handle);
        try
            // Резервируем глобальную область
            Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, Length(s)*SizeOf(Char) + SizeOf(Char));
            try
                // Получаем указатель на неё
                DataPtr := GlobalLock(Data);
                try
                    {$IFDEF D11+}
                     if s=sa then
                      Move(PAnsiChar(sa)^, DataPtr^, Length(s)*SizeOf(AnsiChar) + SizeOf(AnsiChar))
                     else
                      Move(PChar(s)^, DataPtr^, Length(s)*SizeOf(Char) + SizeOf(Char));
                    {$ELSE}
                     Move(PChar(s)^, DataPtr^, Length(s)*SizeOf(Char) + SizeOf(Char));
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
            // Закрываем буфер обмена
            CloseClipboard;
        end;
    end;
end;


// Вставляет в текст строки и, если есть информация, секции текста
procedure TMPSynMemoRange.PasteFromClipboard;
var Data: THandle;
    oldDirAccess:boolean;
    p:Pointer;
    s:string;
    sa:AnsiString;
begin
    if smoReadOnly in fRichMemo.fOptions then Exit;
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.PasteFromClipboard');
    {$ENDIF}
    // Запоминаем позицию вставки для коррекции секций
    fRichMemo.Lines.BeginUpdate;
    oldDirAccess:=fRichMemo.Lines.fDirectAccess;
    fRichMemo.Lines.fDirectAccess:=True;
    try
      if not (smoSkipSectionsOnPaste in fRichMemo.Options) and Clipboard.HasFormat(CF_SYNTAX) then begin
          // Открываем буфер обмена
          OpenClipboard(Application.Handle);
          Data := GetClipboardData(CF_SYNTAX);
          try
              // На основе полученной информации о границах секций в переданном тексте,
              // создаем их на новом месте
              p:=  GlobalLock(Data);
              s:= PChar(p);
              sa:=PAnsiChar(p);
              {$IFDEF D11+}
               if sa=s then
                SetMarkedText(s)
               else
                SetMarkedText(sa)
                ;
              {$ELSE}
               SetMarkedText(s);
              {$ENDIF}
          finally
              GlobalUnlock(Data);
              CloseClipboard;
          end;
      end else
      // Если нет синтаксиса или он запрещен, вставляем просто текст
      if Clipboard.HasFormat(CF_TEXT) then
          SetTextEx(Clipboard.AsText,ukRangeInserted);
    finally
     fRichMemo.Lines.fDirectAccess:=oldDirAccess;
     fRichMemo.Sections.Scan;
        // Требуется перерисовка, переиндексация, репарсинг
     fRichMemo.NeedRedrawAll;
     fRichMemo.Lines.fState := [ssNeedReIndex, ssNeedReparseAll];
    end;
    fRichMemo.Lines.EndUpdate;
    fRichMemo.MakeVisible(PosX,PosY)    

end;


// CutToClipboard() Вырезает текст выделения и помещает в буфер обмена
procedure TMPSynMemoRange.CutToClipBoard;
begin
    if not IsEmpty and not (smoReadOnly in fRichMemo.fOptions) then begin
        {$IFDEF SYNDEBUG}
        fRichMemo.Log('Range.CutToClipboard');
        {$ENDIF}
        CopyToClipboard;
        self.SetTextEx('',ukRangeDeleted);
    end;
end;


// IsEmpty() Возвращает True, если область пустая (только позиция ввода)
function TMPSynMemoRange.IsEmpty: Boolean;
begin
    Result := (StartX = EndX) and (StartY = EndY);
end;


// Устаналивает точку ввода
procedure TMPSynMemoRange.SetPos(const NewPos: TPoint);
begin
    if PointsEqual(fPos, NewPos) then Exit;
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} LogFmt('Range Col = %d Row = %d', [NewPos.X, NewPos.Y]);
        {} {$ENDIF}

        //SiO: Пока еще ничего не изменилось - запишем точку UnDo
        if (not (ssUndoProcess in Lines.State))and(Assigned(LastUndoItem))
           then begin
                if not (LastUndoItem.uiKind=ukCursorMoved)
                   then with AddUndo do
                        begin
                        uiText:='';
                        uiCaretPos:=fPos;
                        uiSelStart:=fPos;
                        uiSelEnd:=fPos;
                        uiKind:=ukCursorMoved;
                        end;
                end;


        Lines.BeginUpdate;
        // По вертикали
        // Убираем лишние пробелы справа после окончания редактирования строки
        // (: Если строка еще существует :)
        if NewPos.Y <> fPos.Y then
             CutFinalSpaces(fPos.Y);
        // Устанавливаем строку
        fPos.Y := EnsureRange(NewPos.Y, 0, Lines.Count);
        // Если курсор после последней строки текста и эта последняя строка текста НЕ ПУСТАЯ,
        // создается новая строка - вообщем-то в этом и состоит весь механизм последовательного
        // набора текста ..:)
        if fPos.Y = Lines.Count then
            if (Lines.Count = 0)
            or ((Lines.Count > 0) and (Lines[Lines.Count-1] <> '')) then begin
//             Lines.InsertItem(Lines.Count,'',nil);
                Lines.Add('');
                SetPos(Point(0, Lines.Count-1));
            end;
        // По горизонтали
        fPos.X := Max(0, NewPos.X);
        // Если включено залипание, корректируем выделение по текущему положению курсора
        if fSealing then begin
            fStart := fPos;
            fEnd   := fPos;
        end;
        // Курсор должен быть виден на экране
        MakeVisible(fPos.X, fPos.Y);
        Lines.EndUpdate;
        Change([ciSelection]);

        if Assigned(fOnSetPosProc)
           then fOnSetPosProc(NewPos);
    end;
end;


// Устанавливает одно из значений выделения
procedure TMPSynMemoRange.SetRange(const Index, Value: Integer);
begin
    case Index of
    0:  SetPos( Point(Value, fPos.Y) );
    1:  SetPos( Point(fPos.X, Value) );
    end;
end;


// Удаляет финальные пробелы в строке
procedure TMPSynMemoRange.CutFinalSpaces(const Row: Integer);
var s: string;
    Da: Boolean;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Range.CutFinalSpaces(%d)', [Row]);
    {} {$ENDIF}
    with fRichMemo.Lines do
        if IsValidLineIndex(fPos.Y) then begin
            s := TrimRight(Strings[fPos.Y]);
            if Length(s) <> Length(Strings[fPos.Y]) then begin
                Da := fDirectAccess;
                fDirectAccess := True;
                Strings[fPos.Y] := s;
                fDirectAccess := Da;
            end;
        end;
end;


// GetText() Возвращает текст выделения
function TMPSynMemoRange.GetText: string;
var Row: Integer;
begin
    if IsEmpty then
        Result := ''
    else
    if fStart.Y = fEnd.Y then
        Result := Copy(fRichMemo.Lines[fStart.Y], fStart.X + 1, fEnd.X - fStart.X)
    else begin
        Result := Copy(fRichMemo.Lines[fStart.Y], fStart.X + 1, MAXINT);
        for Row := StartY + 1 to EndY - 1 do
            Result := Result + #13#10 + fRichMemo.Lines[Row];
        Result := Result + #13#10 +
         Copy(fRichMemo.Lines[fEnd.Y], 1, fEnd.X);
//        LeftStr(fRichMemo.Lines[fEnd.Y], fEnd.X);
    end;
end;


// Возвращает текст выделения с маркерами целых секций
function TMPSynMemoRange.GetMarkedText: string;
var Row, Row1, Row2: Integer;
begin
    with fRichMemo do begin
        // Секции будут действительны только для полных строк
        Row1 := fStart.Y;
        if fStart.X > 0 then Inc(Row1);
        Row2 := fEnd.Y;
        if fEnd.X < Length(Lines[fEnd.Y]) then Dec(Row2);
        // Если первая строка была не полной, её копируем без учета секций
        if Row1 > fStart.Y
//            then Result := Copy(Lines[fStart.Y], fStart.X, MAXINT) + #13#10
            then Result := Copy(Lines[fStart.Y], fStart.X+1, MAXINT) + #13#10
            else Result := '';
        // Каждую строку копируем с учетом секций
        for Row := Row1 to Row2 do
            with Sections.Section[Row] do
                if (Row = RowBeg) and (RowEnd <= Row2) then
                    if Collapsed
                        then Result := Result + SectionMarks[smCollapsed] + Lines[Row] + #13#10
                        else Result := Result + SectionMarks[smExpanded] + Lines[Row] + #13#10
                else
                if (Row = RowEnd) and (RowBeg >= Row1) then
                    Result := Result + SectionMarks[smEnd] + Lines[Row] + #13#10
                else
                    Result := Result + Lines[Row] + #13#10;
        // Если последняя строка была не полной, её копируем без учета секций
        if Row2 < fEnd.Y then
            Result := Result +
             Copy(Lines[fEnd.Y], 1, fEnd.X)
//            LeftStr(Lines[fEnd.Y], fEnd.X)
        else
            System.SetLength(Result, Length(Result) - 2);
    end;
end;


// DoUndo() Производит откат (если есть куда)
procedure TMPSynMemoRange.DoUndo;
var  ui:TMPSynMemoUndoItem;
begin
    if CanUndo then
    begin
        ui:=  TMPSynMemoUndoItem(fUndoStack.Last);
        with fRichMemo, ui do
        begin
            {} {$IFDEF SYNDEBUG}
            {} Log('Range.DoUndo');
            {} {$ENDIF}

            Lines.BeginUpdate;

            // Старые установки
            fStart :=   uiSelStart;
            fEnd :=     uiSelEnd;
            fSealing := uiSealing;

            // Восстанавливаем прежний текст
            Lines.State := Lines.State + [ssUndoProcess];
            Self.SetTextEx(uiText,ukNone);//Прямой вызов действительной процедуры (без прослойки)
            Lines.State := Lines.State - [ssUndoProcess];

            // Прежнее дерево секций
            Sections.EntireSection := uiSections;

            // Старая позиция курсора
            Lines.State := Lines.State + [ssUndoProcess];
            SetPos( uiCaretPos );
            Lines.State := Lines.State - [ssUndoProcess];

            // Удаляем использованный откат
            with fUndoStack do Delete(Count - 1);

            // Фиксируем изменения
            Change([ciUndoStack]);
            Lines.State := [ssNeedReIndex, ssNeedReparseAll];
            fRichMemo.NeedRedrawAll;
            Lines.EndUpdate;
        end;
   end
end;

// Получаем последний откат
function TMPSynMemoRange.GetLastUndoItem:TMPSynMemoUndoItem;
begin
result:=nil;
if fUndoStack.Count>0
   then result:=TMPSynMemoUndoItem(fUndoStack.Last);
end;



// Создает точку отката
function TMPSynMemoRange.AddUndo(const UndoText: string = ''): TMPSynMemoUndoItem;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.LogFmt('Range.AddUndo("%.20s")', [UndoText]);
    {$ENDIF}
    Result := TMPSynMemoUndoItem.Create;
    Result.uiCaretPos := fPos;
    Result.uiSelStart := fStart;
    Result.uiSelEnd   := fEnd;
    Result.uiSealing  := fSealing;
    Result.uiKind     := ukNone;
    Result.uiSections := fRichMemo.Sections.EntireSection;
    Result.uiText     := UndoText;

//SiO: А объекты кто за нас создавать будет?!!
//Три часа, блин, искал причину ошибки "Runtime error 204"!
//P.S. Потом еще столько же искал, почему откаты перестали работать.
//А всего-то нужно было _копию_ сделать.
//Как оно до этого работало - ума не приложу.

    Result.uiSections := TMPSMSectionClone.Create;
    Result.uiSections.Assign(fRichMemo.Sections.EntireSection);
    Result.uiSections.AddRef;

    { Записываем откат }
    if fUndoStack.Count >= fMaxUndoDepth then
        fUndoStack.Delete(0);
    fUndoStack.Add(Result);
    fRichMemo.Change([ciUndoStack]);
end;


// Чистит стек отката
procedure TMPSynMemoRange.ClearUndo;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.ClearUndo');
    {$ENDIF}
    fUndoStack.Clear;
    Assert(fRichMemo.Sections.EntireSection.RefCount = 1,
        'После ClearUndo должно быть fRichMemo.Sections.EntireSection.RefCount == 1');
    fRichMemo.Change([ciUndoStack]);
end;


{ TODO : Это очень похоже на Sections.Scan ! }
// Вставляет текст с маркерами секций
procedure TMPSynMemoRange.SetMarkedText(Value: string);
type TIntArray = array of Integer;

    { Производит разбор секций во вставляемом тексте и выделяет законченные }
    procedure _Scan(var s: string; var secs: TIntArray);
    const signs: array [Boolean] of Integer = (-1, +1);
    var Sl: TStringList;
        i: Integer;
        Stack: TStack;
        Sm: TSectionMark;
    begin
        Sl := TStringList.Create;
        Sl.Text := s;
        secs := nil;
        Stack := TStack.Create;
        for i := 0 to Sl.Count - 1 do begin
            Sm := TMPSynMemoSections.DetectSectionMark(Sl[i]);
            case Sm of
            smExpanded,
            smCollapsed:
                begin
                    Stack.Push(Pointer((i + 1) * signs[Sm = smExpanded]));
                    Sl[i] := Copy(Sl[i], SECTION_HEADER_LENGTH + 1, MAXINT);
                end;
            smEnd:
                begin
                    if Stack.AtLeast(1) then begin
                        System.SetLength(secs, Length(secs) + 2);
                        secs[High(secs)-1] := Integer(Stack.Pop);
                        secs[High(secs)]   := i;
                    end;
                    Sl[i] := Copy(Sl[i], SECTION_HEADER_LENGTH + 1, MAXINT);
                end;
            end;
        end;
        Stack.Free;
        s := Sl.Text;
        Sl.Free;
    end;
    {}

var i, Row1, Row2: Integer;
    SafeStart: TPoint;
    SecIndexes: TIntArray;
begin
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} LogFmt('Range.SetMarkedText("%.20s")', [Value]);
        {} {$ENDIF}

        Lines.BeginUpdate;

        // Запоминаем начальную позицию вставки
        SafeStart := fStart;

        // Если начало выделения, куда вставляем, было не выровнено по строке
        // запрещаем любой маркер секции в этой строке, чтобы не получилось что-то типа Line10: abc{<+}def
        if (SafeStart.X > 0)
        and (TMPSynMemoSections.DetectSectionMark(Value) <> smNone) then
            System.Delete(Value, 1, SECTION_HEADER_LENGTH);

        // Разбор и выделение секций
        _Scan(Value, SecIndexes);

        // Вставляем как текст и переиндексируемся
        SetTextEx(Value,ukRangeInserted);
        Sections.ReIndex;

        // Пробуем создать секции там, где они вставились
        for i := 0 to Length(SecIndexes) shr 1 - 1 do begin
            Row1 := SafeStart.Y + SecIndexes[i*2] * sign(SecIndexes[i*2]) - 1;
            Row2 := SafeStart.Y + SecIndexes[i*2 + 1];
            Sections.New(Row1, Row2, SecIndexes[i*2] < 0);
        end;

        // Освобождаем временный массив границ секций
        SecIndexes := nil;

        // Переиндексация строк
        Lines.EndUpdate;
    end;
end;

//SiO: Прослойка для совместимости
procedure TMPSynMemoRange.SetText(const Value: string);
var ActionKind:TUndoKind;
begin
ActionKind:=ukNone;
if length(Value)=0 then ActionKind:=ukRangeDeleted;
if length(Value)=1 then ActionKind:=ukLetterTyped;
if length(Value)>1 then ActionKind:=ukRangeInserted;
SetTextEx(Value,ActionKind);
end;


// SetText() Самое главное. Задает текст выделения.
procedure TMPSynMemoRange.SetTextEx(const Value: string;ActionKind: TUndoKind);
var Sl: TStringList;
    n, n1, n2: Integer;
    s:string;
    NewSelEnd: TPoint;
    p,p1:integer;

procedure SaveUndo(var Dest:string;fLines:TMPSynMemoStrings);
var
    n:integer;
begin
       p:=Length(Dest);
       if fEnd.Y<>fStart.Y then
       begin
         System.SetLength(Dest,255*(fEnd.Y-fStart.Y));
         for n := fStart.Y + 1 to fEnd.Y do
         begin
  //Buzz оптимизировано
             if Length(Dest)<p+Length(fLines[n])+2 then
              System.SetLength(Dest, Length(Dest)+255*(fEnd.Y-n));
              Move(#13#10,Dest[p+1],2*SizeOf(Char));
              Inc(p,2);
              if Length(fLines[n])>0 then
               Move(fLines[n][1],Dest[p+1],Length(fLines[n])*SizeOf(Char));
             Inc(p,Length(fLines[n]));

         end;
         System.SetLength(Dest, p);
      end;
      if  fEnd.X< Length(fLines[fEnd.Y]) then
       System.SetLength(Dest, p - Length(fLines[fEnd.Y]) + fEnd.X);
end;

 var  ui:TMPSynMemoUndoItem;
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Range.SetText("%.20s")', [Value]);
    {} {$ENDIF}

    // Корректируем позицию ввода
    with fRichMemo do
    begin
        if Lines.Count<PosY+1 then
        begin
         PosX:=PosX+1;
         PosX:=PosX-1;
        end;

        if IsEmpty and (PosX > Length(Lines[PosY])) then
            Lines[PosY] := Lines[PosY] + StringOfChar(' ', PosX - Length(Lines[PosY]));
    end;

    Sl := TStringList.Create;
    Sl.Text := Value + #13#10;
    with fRichMemo do begin
        { Создаем вспомогательные строки }
        n1 := EndY - StartY + 1;
        n2 := Sl.Count;

        // Готовим вспомогательные строки
        NewSelEnd.Y := fStart.Y + n2 - 1;
//        Sl[0] := LeftStr(fLines[fStart.Y], fStart.X) + Sl[0];
        Sl[0] := Copy(fLines[fStart.Y],1 ,fStart.X) + Sl[0];

        NewSelEnd.X := Length(Sl[n2-1]);
        Sl[n2-1] := Sl[n2-1] + RightStr(fLines[fEnd.Y], Length(fLines[fEnd.Y]) - fEnd.X);

        { Сохраняем параметры отката }
        if not (ssUndoProcess in Lines.State) then
           // Смотрим, нельзя ли сгруппировать с предыдущим
           if (not Assigned(LastUndoItem))or(ActionKind in [ukNone, ukBlockCreated, ukBlockExploded])or
              (Assigned(LastUndoItem) and ((LastUndoItem.uiKind=ukNone)or(LastUndoItem.uiKind<>ActionKind)))
              or(not (smoGroupUndo in Options))
              then //Если нельзя - создаем новый откат
              begin
                   ui:=AddUndo;
                   with ui do
                   begin
                     uiCaretPos:=fPos;
                     uiSelEnd := NewSelEnd;
                     { Сохраняем текст отката }

                     uiText := Copy(fLines[fStart.Y], fStart.X + 1, MAXINT);
                     SaveUndo(uiText,fLines);
                   
  {                   for n := fStart.Y + 1 to fEnd.Y do
                         uiText := uiText + #13#10 + fLines[n];
                     System.SetLength(uiText, Length(uiText) - Length(fLines[fEnd.Y]) + fEnd.X);
  }
                     uiKind:=ActionKind;
                   end
              end     
              else //Если можно - группируем.
                   //begin
                   with LastUndoItem do
                   begin
                   //Выясняем направление изменение
                   if ((NewSelEnd.X>=uiSelEnd.X)and(NewSelEnd.Y=uiSelEnd.Y))
                      or(NewSelEnd.Y>uiSelEnd.Y)
                      then
                      begin //Вперед
                       uiSelEnd := NewSelEnd;
                       uiText := uiText+Copy(fLines[fStart.Y], fStart.X + 1, MAXINT);

                       SaveUndo(uiText,fLines);
{                       for n := fStart.Y + 1 to fEnd.Y do
                           uiText := uiText + #13#10 + fLines[n];
                       System.SetLength(uiText, Length(uiText) - Length(fLines[fEnd.Y]) + fEnd.X);}

                      end
                      else
                      begin //Назад
                           s:=uiText;
                           uiSelEnd := NewSelEnd;
                           uiSelStart := fStart;
                           uiText := Copy(fLines[fStart.Y], fStart.X + 1, MAXINT);
                           SaveUndo(uiText,fLines);

{                           for n := fStart.Y + 1 to fEnd.Y do
                               uiText := uiText + #13#10 + fLines[n];
                           System.SetLength(uiText, Length(uiText) - Length(fLines[fEnd.Y]) + fEnd.X);}
                           uiText:=uiText+s;
                     end;
                   if system.Pos(#13#10,uiText)>0 then uiSealing:=False;
                   end;(**)

        { Меняем исходные строки }
        Lines.BeginUpdate;
//Buzz
        if Lines.Capacity<fStart.Y+n2-n1 then
          Lines.Capacity:=fStart.Y+n2-n1;
//         p:=fStart.Y+n2-n1;
         p:=Lines.Count-1;
         for n := n2 - n1 downto 1 do
            if fStart.X = 0
                then Lines.Add( '')
                else Lines.Add('');
         p1:=Lines.Count-1;
         for n := p+1-fStart.Y downto 1 do
         begin
          if p<0 then
           Break;
          TMPSyntaxParser(Lines.Objects[p]).fNeedReparse:=True;
          Lines.Exchange(p,p1);
          Dec(p);
          Dec(p1);
         end;
{        for n := n2 - n1 downto 1 do
            if fStart.X = 0
                then Lines.Insert(fStart.Y, '')
                else Lines.Insert(fStart.Y + n1, '');}

       if n1>n2 then
       begin
         p:=fStart.Y ;
//         p1:=Lines.Count-(n1 - n2);
         for n:=p+(n1 - n2) to Lines.Count-1 do
         begin
          Lines.Exchange(n,p);
          Inc(p);
         end;
         for n := n1 - n2 downto 1 do
           Lines.Delete(Lines.Count-1);
         NeedReDrawLE(fStart.Y);
// Последняя строка всегда пустая
       end;
{        for n := n1 - n2 downto 1 do
            Lines.Delete(fStart.Y);  }

        for n := 0 to n2 - 1 do
            Lines[fStart.Y + n] := Sl[n];

        // Устанавливаем новое положение курсора
        fEnd := NewSelEnd;
        fStart := fEnd;
        fSealing := True;

        //Чтобы движение символа не записывалось
        Lines.State := Lines.State + [ssUndoProcess];
        SetPos( fEnd );
        Lines.State := Lines.State - [ssUndoProcess];

        MakeVisible(fEnd.X, fEnd.Y);
        // Репарсинг и перерисовка
        Lines.EndUpdate;
    end;
    Sl.Free;
    fRichMemo.Invalidate       
end;


// GetLength() Подсчитывает длину строки выделения
function TMPSynMemoRange.GetLength: Integer;
var i: Integer;
begin
    Result := EndX - StartX;
    for i := StartY to EndY - 1 do
        Inc(Result, Length(fRichMemo.Lines[i]) + 2);
end;


// GetPosition() Вовращает позицию начала выделения (0-based)
function TMPSynMemoRange.GetPosition: Integer;
begin
    Result := fRichMemo.Lines.RCToPosition(StartX, StartY);
end;

function        TMPSynMemoRange.GetPosInText:Integer;
var
   PosCoord:TPoint;
   i,RowCount:integer;
begin
   Result:=0;
   PosCoord:=Pos;
   if PosCoord.Y+1<=fRichMemo .fLines.Count then
    RowCount:=PosCoord.Y
   else
    RowCount:=fRichMemo .fLines.Count -1;

   for i:=0 to RowCount do
    if i<RowCount then
     Inc(Result,Length(fRichMemo .fLines[i])+2)
    else
     if Length(fRichMemo .fLines[i])<PosCoord.X then
      Inc(Result,Length(fRichMemo .fLines[i])+2)
     else
      Inc(Result,PosCoord.X);
end;

// SetLength() Устанавливает длину выделения
procedure TMPSynMemoRange.SetLength(const Value: Integer);
var x0, dy, i, n: Integer;
begin
    with fRichMemo do begin
        {} {$IFDEF SYNDEBUG}
        {} LogFmt('Range.SetLength(%d)', [Value]);
        {} {$ENDIF}
        dy := 0;
        x0 := StartX;
        n := Value;
        for i := StartY to fLines.Count - 1 do begin
            Dec(n, Length(fLines[i]) + 2 - x0);
            x0 := 0;
            if n <= 0 then begin
                Enlarge(dy, True);
                Enlarge(Length(fLines[i]) + 2 + n - StartX);
                Exit;
            end else
                Inc(dy);
        end;
    end;
end;


// SetPosition() Устанавливает позицию курсора по его отсчету от начала текста
procedure TMPSynMemoRange.SetPosition(const Value: Integer);
begin
    {} {$IFDEF SYNDEBUG}
    {} fRichMemo.LogFmt('Range.SetPosition(%d)', [Value]);
    {} {$ENDIF}
    Collapse;
    SetPos( fRichMemo.Lines.PositionToRC(Value) );
end;


// CanUndo() Возвращает True, если есть возможность отката
function TMPSynMemoRange.CanUndo: Boolean;
begin
    Result := fUndoStack.Count > 0;
end;


// SetMaxUndoDepth() Устанавливает новую границу стека отката
procedure TMPSynMemoRange.SetMaxUndoDepth(const Value: Integer);
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.LogFmt('Range.SetMaxUndoDepth(%d)', [Value]);
    {$ENDIF}
    while fMaxUndoDepth > Value do begin
        fUndoStack.Delete(0);
        Dec(fMaxUndoDepth);
    end;
    fMaxUndoDepth := Value;
end;


// SelectAll() Выделяет весь текст
procedure TMPSynMemoRange.SelectAll;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.SelectAll');
    {$ENDIF}
    SetPosition(0);
    SetLength(Length(fRichMemo.Lines.Text));
end;


// SelectFromStart() Выделяет текст от начала до текущей позиции
procedure TMPSynMemoRange.SelectFromStart;
var L: Integer;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.SelectFromStart');
    {$ENDIF}
    L := fRichMemo.Lines.RCToPosition(fPos.X, fPos.Y);
    SetPosition(0);
    SetLength(L);
end;


// SelectToEnd() Выделяет текст от текущей позиции до конца документа
procedure TMPSynMemoRange.SelectToEnd;
var L: Integer;
begin
    {$IFDEF SYNDEBUG}
    fRichMemo.Log('Range.SelectToEnd');
    {$ENDIF}
    L := fRichMemo.Lines.RCToPosition(fPos.X, fPos.Y);
    SetPosition(L);
    SetLength(Length(fRichMemo.Lines.Text) - L);
end;

//Реализация

{TBreakPoint}

//Создаем экземпляр объекта БП
constructor TBreakPoint.Create(Owner: TMPBreakPointCollection);
begin
inherited Create;
fCollection:=Owner;
Condition:='';
Group:='';
PassCount:=0;
Comment:='';
fKind:=bkPosible;
end;

//Удаляем объект БП
destructor TBreakPoint.Destroy;
begin
inherited;
end;

procedure TBreakPoint.fSefKind(kind:TBPKind);
begin
fKind:=kind;
fCollection.RefreshBP(self);
end;

{TMPBreakPointCollection}

//Создаем коллекцию БП'ов
constructor TMPBreakPointCollection.Create(Owner: TMPCustomSyntaxMemo);
begin
inherited Create;
fRichMemo:=Owner;
fBPList:=TStringList.Create;
fImages := TBitmap.Create;
fImages.LoadFromResourceName(HInstance, 'BREAKPOINTS');
fImagesMask := TBitmap.Create;
fImagesMask.LoadFromResourceName(HInstance, 'BREAKPOINTSMASK');
fOnBeforeBreakPointChangedNotify:=nil;
fRowOfCurrentBP:=-1;
end;

//Удаляем
destructor TMPBreakPointCollection.Destroy;
var i:integer;
begin
fOnBeforeBreakPointChangedNotify:=nil;
fImagesMask.Free;
fImages.Free;
for i:=0 to fBPList.Count-1 do
    fBPList.Objects[i].Free;
fBPList.Free;
inherited;
end;

//Добавляет новый БП в коллекцию. Если на этой строке уже был БП - удаляет старый,
//создает новый
procedure TMPBreakPointCollection.Add(const Row: Integer;const Kind:TBPKind=bkEnabled;
                      Condition:string='';PassCount:cardinal=0;Group:string='';Comment:string='');
var BP:TBreakPoint;
begin
if (Row=-1) then exit;

Delete(Row);
BP:=TBreakPoint.Create(self);
BP.Condition:=Condition;
BP.PassCount:=PassCount;
BP.Group:=Group;
BP.Comment:=Comment;
BP.Kind:=Kind;

fBPList.AddObject(inttostr(Row),TObject(BP));
fBPList.Sort;
fRichMemo.NeedRedraw(Row);
fRowOfCurrentBP:=Row;
end;

//Удаляет БП из указанной строки. Если его там не было - игнорирует...
function TMPBreakPointCollection.Delete(const Row: Integer):boolean;
var i:integer;
begin
result:=false;
if Row=-1 then exit;
if fBPList.Find(IntToStr(Row),i) then
   begin
   (fBPList.Objects[i] as TBreakPoint).Free;
   fBPList.Delete(i);
   result:=true;
   end;
fRichMemo.NeedRedraw(Row);
end;

//Возвращает информацию о наличии или отсутствии БП на указанной строке.
//В режиме bmNeedPosibility bpPosible не считается БП
function TMPBreakPointCollection.fGetIsBreakPoint(const LineIndex:integer):boolean;
var Kind:TBPKind;
begin
result:=false;
case fMode of
     bmFreeMode:       begin
                       result:=Find(LineIndex,Kind);
                       end;
     bmNeedPosibility: begin
                       if Find(LineIndex,Kind)
                          then result:=(Kind=bkEnabled)or(Kind=bkDisabled);
                       end;
     end;
end;

//Устанавливает информацию о наличии или отсутствии БП на указанной строке.
//Всегда ставил БП типа bpEnabled или удаляет его.
//В режиме bmNeedPosibility ставит только там, где есть bpPosible, а при удалении
//возвращает bpPosible.
//Так же генерирует событие OnBeforeBreakPointChanged, в котором можно разрешить
//или запретить установу БП. В случает если нужно, чтобы поставленный БП был типа
//bpDisabled необходимо запретить установку и поставить его вручную. На откуп программисту редактора
procedure TMPBreakPointCollection.fSetIsBreakPoint(const LineIndex:integer;bp:boolean);
var Kind:TBPKind;
    Action:TBPAction;
    CanChange:boolean;
begin
if LineIndex=-1 then exit;
if bp
   then Action:=bpaSet
   else Action:=bpaDelete;
CanChange:=True;
if Assigned(fOnBeforeBreakPointChangedNotify)
   then fOnBeforeBreakPointChangedNotify(fRichMemo,LineIndex,Action,CanChange);
if not CanChange then exit;
case fMode of
     bmFreeMode:       begin
                       if bp
                          then Add(LineIndex,bkEnabled)
                          else Delete(LineIndex);
                       end;
     bmNeedPosibility: begin
                       if bp
                          then begin
                               if Find(LineIndex,Kind) then
                                  if Kind=bkPosible then
                                     Add(LineIndex,bkEnabled)
                               end
                          else begin
                               if Find(LineIndex,Kind) then
                                  if Kind<>bkPosible then
                                     Add(LineIndex,bkPosible)
                               end;
                       end
     end;

end;

function TMPBreakPointCollection.fGetIsPosible(const LineIndex:integer):boolean;
var Kind:TBPKind;
begin
result:=False;
if Find(LineIndex,Kind)
   then result:=(Kind=bkPosible);
end;

procedure TMPBreakPointCollection.fSetIsPosible(const LineIndex:integer;bp:boolean);
var Kind:TBPKind;
begin
if bp
   then begin
        if not IsBreakPoint[LineIndex]
           then Add(LineIndex,bkPosible);
        end
   else begin
        // Если БП нет, то и удалять нечего
        if not (Find(LineIndex,Kind)) then exit;
        // Если есть, проверим установленый БП, если его нет - удалим возможный
        if BreakPoint[LineIndex].Kind=bkPosible
           then Delete(LineIndex);
        end;
end;


//Реализация работы с массивом БП'ов
function TMPBreakPointCollection.fGetBreakPoint(const LineIndex:integer):TBreakPoint;
var i:integer;
begin
result:=nil;
if fBPList.Find(IntToStr(LineIndex),i)
   then result:=TBreakPoint(fBPList.Objects[i]);
end;

//Реализация работы с массивом БП'ов
procedure TMPBreakPointCollection.fSetBreakPoint(const LineIndex:integer;BP:TBreakPoint);
begin
Delete(LineIndex);
Add(LineIndex,BP.Kind,BP.Condition,BP.PassCount,BP.Group,BP.Comment);
fRowOfCurrentBP:=LineIndex;
end;

procedure TMPBreakPointCollection.RefreshBP(Sender:TBreakPoint);
var i,Row:integer;
begin
i:=fBPList.IndexOfObject(TObject(Sender));
if i>=0
   then begin
        Row:=StrToInt(fBPList.Strings[i]);
        fRowOfCurrentBP:=Row;
        fRichMemo.NeedRedraw(Row);
        end;
end;



//Прорисовка БП на гутере.
//Прорисовка в два этапа позволяет сделать "прозрачный" край иконок. (маскирование)
procedure TMPBreakPointCollection.PaintAt(const ACanvas: TCanvas; const x, y: Integer; const Kind:TBPKind);
const BOOKMARK_GLYPH_SIZE = 11;
begin
    BitBlt( ACanvas.Handle,
            x,
            y,
            BOOKMARK_GLYPH_SIZE,
            BOOKMARK_GLYPH_SIZE,
            fImagesMask.Canvas.Handle,
            byte(Kind) * BOOKMARK_GLYPH_SIZE,
            0,
            SRCAND);{}
    BitBlt( ACanvas.Handle,
            x,
            y,
            BOOKMARK_GLYPH_SIZE,
            BOOKMARK_GLYPH_SIZE,
            fImages.Canvas.Handle,
            byte(Kind) * BOOKMARK_GLYPH_SIZE,
            0,
            SRCPAINT);{}
end;

//Поиск брейкпоинта в указанной строке.
//Если найден - возвращает TRUE и тип брейкпоинта
//Если не найдет - тип игнорируется
function TMPBreakPointCollection.Find(const Row: Integer; var Kind:TBPKind): Boolean;
var i:integer;
begin
result:=false;
if fBPList.Find(IntToStr(Row),i) then
   begin
   Kind:=(fBPList.Objects[i] as TBreakPoint).Kind;
   result:=true;
   end;
end;



// Class TMPCustomSyntaxMemo methods implementation

// Create() Конструктор
constructor TMPCustomSyntaxMemo.Create(AOwner: TComponent);
var F: TFont;
begin
    inherited Create(AOwner);
    DoubleBuffered  := True;
    fLines          := TMPSynMemoStrings.Create(self);
    fRange          := TMPSynMemoRange.Create(self);
    fSections       := TMPSynMemoSections.Create(self);
    fParseAttributes:= TMPSyntaxAttributes.Create(self);
    fBookMarks      := TMPBookmarkManager.Create(self);
    fBreakPoints    := TMPBreakPointCollection.Create(self);
    FCurParser:=TMPSyntaxParser.Create;
    fBuffer         := TBitmap.Create;
    Width           := 249;
    Height          := 145;
//    Color           := clWindow;
    Color           := clWhite;
    Cursor          := crIBeam;
    fSelWord        := Point(-1, -1);
    fDefBackColor   := clWindow;
    fDefForeColor   := clBlack;

    fBPEnabledBackColor  := clRed;
    fBPEnabledForeColor  := clWhite;
    fBPDisabledBackColor := clMaroon;
    fBPDisabledForeColor := clWhite;
    fDebugBackColor      := clNavy;
    fDebugForeColor      := clWhite;
    fSelectedWordColor   := $000080FF;

    fSelColor       := clSkyBlue;
    fGutterWidth    := 32;
    fInsertMode     := True;
    fOptions        := [smoAutoGutterWidth,smoShowCursorPos,smoShowPageScroll,smoPanning,smoShowLineNumberToGutter];
    fStepDebugLine  := -1;

    fRange.fOnSetPosProc:=OnChangePos;

    fVScroll:= TScrollBar.Create(Self);
    with fVScroll do begin
        Parent      := Self;
        Kind        := sbVertical;
        Ctl3D       := True;
        OnChange    := ScrollClick;
        OnEnter     := ScrollEnter;
    end;

    fHScroll:= TScrollBar.Create(Self);
    with fHScroll do begin
        Parent      := Self;
        Kind        := sbHorizontal;
        Ctl3D       := True;
        Visible     := True;
        OnChange    := ScrollClick;
        OnEnter     := ScrollEnter;
    end;

    fNavButton:= TPanel.Create(self);
    with fNavButton do begin
        Parent      := Self;
        Width       := fVScroll.Width;
        Height      := fHScroll.Height;
        Caption     := '';//'…';
        Visible     := True;
        BevelInner  := bvNone;
        BevelOuter  := bvNone;
    end;

    fPosInfo:=nil;
    CreateDestroyCursorPos;
    fPageUpDown:=nil;
    CreateDestroyPageUpDown;

    // Параметры отображения синтаксиса по умолчанию
    F := TFont.Create;
    F.Name := 'Arial';
    F.Size := 9;
    F.Style := [];
    F.Color := clBlack;
    Font.Assign(F);
    F.Free;
    fLettersCalculated:=False;
    // настройки синтаксиса по умолчанию
    TabStop         := True;
    Font.OnChange   := FontChange;
    fSectionIndent  := 16;

    FProposalForm:=TMPSyntaxCompletionProposalForm.Create(Self);
    FTimer:=TTimer.Create(Self);
    FTimer.Interval:=100;
    FTimer.OnTimer:=DoOnTimer;

end;

//Созадние/удаление дополнительного элемента управления PageUpDown
//Создается или удаляется в зависимости от Options
//Вызывается при изменении Options
procedure TMPCustomSyntaxMemo.CreateDestroyPageUpDown;
begin
if (smoShowPageScroll in fOptions)
   then begin
        if not Assigned(fPageUpDown) then
           begin
           fPageUpDown:= TScrollBar.Create(self);
           with fPageUpDown do begin
                Parent      := Self;
                Kind        := sbVertical;
                Width       := fVScroll.Width;
                Height      := Width*2;
                Visible     := True;
                Max         := 1;
                Min         := -1;
                Position    := 0;
                Enabled     := fVScroll.Enabled;
                OnChange    := PageUpDownOnClick;
                OnEnter     := ScrollEnter;
                end;
           end;
        end
   else begin
        if fPageUpDown<>nil
           then begin
                fPageUpDown.Free;
                fPageUpDown:=nil;
                end;
        end;
end;

//Созадние/удаление дополнительного элемента управления CursorPos
//Создается или удаляется в зависимости от Options
//Вызывается при изменении Options
procedure TMPCustomSyntaxMemo.CreateDestroyCursorPos;
begin
if (smoShowCursorPos in fOptions)
   then begin
        if not Assigned(fPosInfo) then
           begin
           fPosInfo:= TEdit.Create(self);
           with fPosInfo do begin
                Parent      := Self;
                Visible     := True;
                ReadOnly    := True;
                Left        := 0;
                Width       := 64;
                Text        := '1: 1';
                end;
           end;
        end
   else begin
        if fPosInfo<>nil
           then begin
                fPosInfo.Free;
                fPosInfo:=nil;
                end;
        end;
end;



// Destroy() Деструктор
destructor TMPCustomSyntaxMemo.Destroy;
begin
//Вроде бы как не нужно удалять то, что имеет владельца, а эти видимые элементы имеют
{    if fPosInfo<>nil
       then begin
            fPosInfo.Free;
            end;
    if fPageUpDown<>nil
       then begin
            fPageUpDown.Free;
            end;
    fNavButton.Free;{}

    FCurParser.Free;
    setlength(fScreenLines,0);
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



//Установка события изменения БП
function TMPCustomSyntaxMemo.GetOnBeforeBreakPointChangedNotify;
begin
result:=fBreakPoints.OnBeforeBreakPointChangedNotify;
end;

function TMPCustomSyntaxMemo.GetPosInText: Integer;
begin
 Result:=Range.PosInText
end;

//Получение события изменения БП
procedure TMPCustomSyntaxMemo.SetOnBeforeBreakPointChangedNotify;
begin
if Assigned(fBreakPoints)
   then fBreakPoints.OnBeforeBreakPointChangedNotify:=OnBeforeBreakPointChangedNotify;
end;

//Установка выпадающего меню
function TMPCustomSyntaxMemo.GetBreakPointsPopupMenu:TPopupMenu;
begin
result:=fBreakPoints.PopupMenu;
end;

//Получение выпадающего меню
procedure TMPCustomSyntaxMemo.SetBreakPointsPopupMenu(pum:TPopupMenu);
begin
if Assigned(fBreakPoints)
   then fBreakPoints.PopupMenu:=pum;
end;

//Указывает строку, которая будет выделена, как шаг отладки
procedure TMPCustomSyntaxMemo.SetStepDebugLine(Row:integer);
var OldLine:integer;
begin
OldLine:=fStepDebugLine;
fStepDebugLine:=Row;
// На всякий случай проверим, есть ли такая строка вообще
if not Lines.IsValidLineIndex(row)
   then exit;

// Обновим строку, где линии отладки уже нет
if OldLine<>-1 then NeedRedraw(OldLine);

//Нарисуем новую линию
if fStepDebugLine<>-1
   then begin
        //Если строка не видима - сделаем видимой!
        if not (IsLineVisible(Row))
           then OffsetY := Row;
        //Перересуем
        NeedRedraw(fStepDebugLine);
        end;
end;



// SetSelColor() Устанавливает цвет выделения
procedure TMPCustomSyntaxMemo.SetSelColor(const Value: TColor);
begin
    if Value <> fSelColor then begin
        fSelColor := Value;
        if not fRange.IsEmpty() then Invalidate;
    end;
end;


// ClientLines() Возвращает количество строк текста, умещающихся в окне редактора
function TMPCustomSyntaxMemo.ClientLines: Integer;
begin
    with TextRowRect[-1] do
        { DONE -oMax Proof -c19.03.2006 : Ошибка. Должно быть видно только целое число строк текста }
        Result := (Bottom - Top {+ fCharHeight - 1}) div fCharHeight;
end;


// WMSIZE() Реакция на изменение размеров редактора
procedure TMPCustomSyntaxMemo.WMSIZE(var Message : TMessage);
begin
    Invalidate;
    if not fLettersCalculated
       then CalcFontParams;
    CalcScreenParams;
    if not (csDesigning in ComponentState) then UpdateScrollBars;
end;


// CanResize() Обрабатывает высоту таким образом,
// чтобы клиентская область была кратна высоте строки
function TMPCustomSyntaxMemo.CanResize(var NewWidth, NewHeight: Integer): Boolean;
begin
//    with TextRowRect[-1] do
//        Dec(NewHeight, (NewHeight - Self.Height + (Bottom - Top)) mod fCharHeight);
//    Inc(NewHeight);
    Result := Inherited CanResize(NewWidth, NewHeight);
end;


// Двойной щелчок мышью - выделение текущего слова
procedure TMPCustomSyntaxMemo.WMLButtonDblClk(var Message : TWMMouse);
var Row, WIndex: Integer;
    Sec: TMPSynMemoSection;
    T: TMPSyntaxToken;
begin
    inherited;
    // Если нажата клавиша Ctrl во время двойного щелчка,
    // выделяется соответствующая секция
    if (GetKeyState(VK_CONTROL) and $8000) <> 0 then begin
        WndOffsetToPixOffset(Point(Message.XPos, Message.YPos), WIndex, Row, True);
        if Lines.IsValidLineIndex(Row) then begin
            Sec := Sections.Section[Row];
            Sections.Expand(Row, False, True);
            Range.Collapse;
            { Так как корневая секция начинается с -1, корректируем возм. ошибку }
            Range.Pos := Point(0, EnsureRange(Sec.RowBeg, 0, Lines.Count - 1));
            Range.Enlarge(Sec.RowEnd - Sec.RowBeg + 1, True);
        end
    end else
    // Иначе, выделяем слово под курсором
    if GetWordAtPos(Message.XPos, Message.YPos, WIndex, Row) then
        if InRange(WIndex, 0, Lines.Parser[Row].Count - 1) then begin
            T := Lines.Parser[Row].Tokens[WIndex];
            Range.Collapse;
            Range.Pos := Point(T.stStart, Row);
            Range.Enlarge(T.stLength);
        end;
end;

procedure TMPCustomSyntaxMemo.ScreenPosToTextPos(const ScrX,ScrY:Integer;var DestX,DestY:Integer );
begin
    WndOffsetToPixOffset(Point(ScrX, ScrY), DestX,DestY, False);
    if fLines.IsValidLineIndex(DestY) then
    begin
     DestX:= PixOffsetToCharPos(DestX,DestY,nil);
    end
    else
     DestX:=DestX div fCharWidths[False][' ']
end;

function   TMPCustomSyntaxMemo.TextPosToScreen(const X,Y:Integer):TPoint; // для драг дропа
begin
 Result.X:=CharPosToPixOffset(X,Y);
 Result:=PixOffsetToWndOffsetEx(Result.X,Y-fOffsets.Y)
end;

// Перерасчет параметров шрифта
//SiO: Разделил на две
procedure TMPCustomSyntaxMemo.CalcFontParams;
var c: AnsiChar;
begin
fLettersCalculated:=True;
    with Canvas do begin
        Font.Assign(Self.Font);
        FCharHeight := -Font.Height + 3;
        Font.Style  := [];
        for c := Low(fCharWidths[False]) to High(fCharWidths[False]) do
            fCharWidths[False][c] := Byte( TextWidth(c) );
        Font.Style  := [fsBold];
        for c := Low(fCharWidths[True]) to High(fCharWidths[True]) do
            fCharWidths[True][c] := Byte( TextWidth(c) );
    end;

end;

procedure TMPCustomSyntaxMemo.CalcScreenParams;
begin
    with fVScroll do begin
        Ctl3D       := True;
        Visible     := True;
    end;
    fVScroll.Left:=Width-fVScroll.Width-4;
    fVScroll.Top:=0;


    if fPageUpDown<>nil
       then begin
            fVScroll.Height:=Height-fHScroll.Height-fPageUpDown.Height-4;
            fPageUpDown.Top:=fVScroll.Height;
            fPageUpDown.Left:=fVScroll.Left;
            end
       else begin
            fVScroll.Height:=Height-fHScroll.Height-4;
            end;


    with fHScroll do begin
        Ctl3D       := True;
        Visible     := True;
    end;

    if fPosInfo<>nil
       then begin
            fHScroll.Left:=fPosInfo.Width;
            fHScroll.Width:=Width-fVScroll.Width-fPosInfo.Width-4;
            fHScroll.Top:=Height-fHScroll.Height-4;
            fPosInfo.Left:=0;
            fPosInfo.Top:=fHScroll.Top-1;
            fPosInfo.Height:=fHScroll.Height+1;
            end
       else begin
            fHScroll.Left:=0;
            fHScroll.Width:=Width-fVScroll.Width-4;
            fHScroll.Top:=Height-fHScroll.Height-4;
            end;




    fNavButton.Left:=Width-fNavButton.Width-4;
    fNavButton.Top:=Height-fNavButton.Height-4;


    SetLength(fScreenLines, ClientLines);
    with EntireRowRect[0] do
         begin
         if (Bottom-Top)>0
            then fBuffer.Height := Bottom - Top;
         if (Right-Left)>0
            then fBuffer.Width  := Right - Left;
    end;
end;

//Обновление элемента индикации положения курсора
procedure TMPCustomSyntaxMemo.OnChangePos(Pos:TPoint);
begin
if pos.X<0 then pos.X:=0;
if fPosInfo<>nil
   then fPosInfo.Text:=inttostr(pos.Y+1)+': '+inttostr(pos.X+1);
end;


//Обработчик нажатия на PageUpDown элемент
procedure TMPCustomSyntaxMemo.PageUpDownOnClick(Sender: TObject);
begin
if fPageUpDown.Position<>0
   then begin
        OffsetY := FindVisibleRow(OffsetY, fPageUpDown.Position * (ClientLines-1), True);
        fPageUpDown.Position:=0;
        end;
end;

// Возвращает смещение от начала строки (в пикселах)
function TMPCustomSyntaxMemo.CharPosToPixOffset(const Col: Integer; s: string; Sp: TMPSyntaxParser): Integer;
var T: TMPSyntaxToken;
    i, j, WordIndex: Integer;
    Bold: Boolean;
begin
    Result := 0;
    WordIndex := 0;
    i := 0;
    while WordIndex < Sp.Count do begin
        T := Sp[WordIndex];
        j := Min(Col, T.stStart);
        Inc(Result, (j - i) * fCharWidths[False][' ']);
        i := j;
        if i = Col then Break;
        Bold := fsBold in fParseAttributes.FontStyle[T.stToken];
        j := Min(Col, T.stStart + T.stLength);
        if j >Length(s) then
         j:=Length(s);
        while i < j do begin
            if s[i+1]<=High(AnsiChar) then
             Inc(Result, fCharWidths[Bold][AnsiChar(s[i+1])])
            else
             Inc(Result, Canvas.TextWidth(s[i+1]));

//             fCharWidths[Bold][AnsiChar(s[i+1])])
            Inc(i);
        end;
        if i = Col then Break;
        Inc(WordIndex);
    end;
    if i < Col then
        Inc(Result, (Col - i) * fCharWidths[False][' ']);
end;


// Возвращает смещение от начала строки (в пикселах)
// для заданного символа (Col, 0-based) заданной строки (Row, base=0)
function TMPCustomSyntaxMemo.CharPosToPixOffset(const Col, Row: Integer): Integer;
begin
    if fLines.IsValidLineIndex(Row) then
        Result := CharPosToPixOffset(Col, fLines[Row], fLines.Parser[Row])
    else
        Result := 0;
end;


// PixOffsetToCharPos() Возвращает номер позиции (0-based) символа в строке Row
// по его смещению от начала строки в пикселах Pix
// Если WordIndex <> nil, то через него возвращается индекс слова в этой позиции:
// WordIndex^ > 0, если позиция внутри слова
// WordIndex^ < 0, если позиция перед данным словом (индекс слова отрицателен)
// WordIndex = MAXINT, если позиция после последнего слова в строке
function TMPCustomSyntaxMemo.PixOffsetToCharPos(const Pix, Row: Integer; const WordIndex: PInteger = nil): Integer;
var Sp: TMPSyntaxParser;
    s: string;
    Pos, WIndex: Integer;
    Bold: Boolean;
    T: TMPSyntaxToken;
begin
    Result := 0;
    if not InRange(Row, 0, fLines.Count - 1) then Exit;
    Sp := TMPSyntaxParser(fLines.Objects[Row]);
    s  := fLines[Row];
    WIndex := 0;
    Pos := 0;
    if Sp <> nil then
        while WIndex < sp.Count do begin
            T := Sp[WIndex];
            Bold := fsBold in fParseAttributes.FontStyle[T.stToken];
            while Result < T.stStart do begin
                Inc(Pos, fCharWidths[False][' ']);
                if Pos > Pix then begin
                    if Assigned(WordIndex) then WordIndex^ := -WIndex;
                    Exit;
                end;
                Inc(Result);
            end;
            while (Result < T.stStart + T.stLength) and (Result<Length(s)) do begin
                Inc(Pos, fCharWidths[Bold][AnsiChar(s[Result+1])]);
                if Pos > Pix then begin
                    if Assigned(WordIndex) then WordIndex^ := WIndex;
                    Exit;
                end;
                Inc(Result);
            end;
            Inc(WIndex);
        end;
    if Pos < Pix then
        Inc(Result, (Pix - Pos) div fCharWidths[False][' ']);
    if Assigned(WordIndex) then
        WordIndex^ := MAXINT;
end;


// WMGetDlgCode() Для того, чтобы компонент не терял фокус при нажатии управляющих клавиш
procedure TMPCustomSyntaxMemo.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
   Message.Result := DLGC_WANTARROWS    // что бы при нажатии стрелок фокус не терялся}
                  or DLGC_WANTALLKEYS   // что бы реакция на Enter оставалась}
                  or DLGC_WANTTAB
                  or DLGC_WANTCHARS
                  ;
end;


// KeyDown() Отработка нажатия специальных клавиш
procedure TMPCustomSyntaxMemo.KeyDown(var Key: Word; Shift: TShiftState);
var xn, yn,x: Integer;
    {$IFDEF SYNDEBUG}
    function ShiftAsString(Shift: TShiftState): string;
    begin
        Result := '[';
        if ssShift  in Shift then Result := Result + ',ssShift';
        if ssAlt    in Shift then Result := ',ssAlt';
        if ssCtrl   in Shift then Result := Result + ',ssCtrl';
        if ssLeft   in Shift then Result := Result + ',ssLeft';
        if ssRight  in Shift then Result := Result + ',ssRight';
        if ssMiddle in Shift then Result := Result + ',ssMiddle';
        if ssDouble in Shift then Result := Result + ',ssDouble';
        if Length(Result) > 1 then System.Delete(Result, 2, 1);
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
            if (Shift = [ssCtrl]) and not fHinting then begin
                Cursor := crHandPoint;
                Hint := '';
                SelectedWord := Point(-1, -1);
                ShowHint := True;
                fHinting := True;
            end;

        VK_RIGHT:
        begin

            if not (ssShift in Shift) then begin
                Collapse;
                if not (ssCtrl in Shift) then
                    PosX := PosX + 1
                else
                if FindNextWord(xn, yn) then
                    Pos := Point(xn, yn);
            end else
                if not (ssCtrl in Shift)
                    then Enlarge(1)
                    else begin
                        if FindNextWord(xn, yn) then begin
                            Enlarge(yn - PosY, True);
                            Enlarge(xn - PosX);
                        end;
                    end;

           if fInProposalCall then                    
           begin
                if Length(GetCurrentWord()) =0 then
                      CloseProposal
                else
                begin
                 FProposalForm.ChangeListText;
                 if FProposalForm.FListProp.Items.Count=0 then
                    CloseProposal;
                end
           end;


         end;

        VK_LEFT:
        begin
{           if fInProposalCall then
           begin
//             CloseProposal;
                FProposalForm.ChangeListText;
                 if FProposalForm.FListProp.Items.Count=0 then
                    CloseProposal;

           end;}
            if not (ssShift in Shift) then begin
                Collapse;
                if not (ssCtrl in Shift) then
                    PosX := PosX - 1
                else
                if FindPrevWord(xn, yn) then
                    Pos := Point(xn, yn);
            end else
                if not (ssCtrl in Shift)
                    then Enlarge(-1)
                    else begin
                        if FindPrevWord(xn, yn) then begin
                            Enlarge(yn - PosY, True);
                            Enlarge(xn - PosX);
                        end;
                    end;

           if fInProposalCall then                    
           begin
                if Length(GetCurrentWord()) =0 then
                      CloseProposal
                else
                begin
                 FProposalForm.ChangeListText;
                 if FProposalForm.FListProp.Items.Count=0 then
                    CloseProposal;
                end

           end;
                    
         end;
        VK_DOWN:
            if fInProposalCall then
             FProposalForm.Down
            else
            if not (ssShift in Shift) then
                if not (ssCtrl in Shift)
                    then begin
                        Collapse;
                        x:=CharPosToPixOffset(PosX,PosY);
                        PosY := FindVisibleRow(PosY, 1, True);
                        PosX:=PixOffsetToCharPos(x,PosY);
                    end else begin
                        OffsetY := FindVisibleRow(OffsetY, 1, True);
                        if StartY < OffsetY then begin
                            Collapse;
                            PosY := OffsetY;
                        end;
                    end
            else
                if not (ssCtrl in Shift)
                    then Enlarge(1, True, True)
                    else GotoSection(True);

        VK_UP:
            if fInProposalCall then
             FProposalForm.Up
            else
            if not (ssShift in Shift) then
                if not (ssCtrl in Shift)
                    then begin
                        Collapse;
                        x:=CharPosToPixOffset(PosX,PosY);
                        PosY := FindVisibleRow(PosY, -1, True);
                        PosX:=PixOffsetToCharPos(x,PosY);
                    end else begin
                        OffsetY := FindVisibleRow(OffsetY, -1, True);
                        if StartY >= OffsetY + ClientLines then begin
                            Collapse;
                            PosY := OffsetY + ClientLines - 1;
                        end;
                    end
            else
                if not (ssCtrl in Shift)
                    then Enlarge(-1, True, True)
                    else GotoSection(False);

        VK_HOME:
            if fInProposalCall then
             FProposalForm.ToHome
            else
            if not (ssShift in Shift) then begin
                Collapse;
                if ssCtrl in Shift then PosY := 0;
                if (PosX=0)and(Length(Trim(Lines.Strings[PosY]))>0)
                   then PosX := system.pos(Trim(Lines.Strings[PosY]),Lines.Strings[PosY])-1
                   else PosX := 0;
            end else begin
                if ssCtrl in Shift then Enlarge(-PosY, True);
                Enlarge(-PosX);
            end;

        VK_END:
            if fInProposalCall then
             FProposalForm.ToEnd
            else
            if not (ssShift in Shift) then begin
                Collapse;
                if ssCtrl in Shift then PosY := fLines.Count - 1;
                PosX := Length(fLines[PosY]);
            end else begin
                if ssCtrl in Shift then Enlarge(fLines.Count-1 - PosY, True);
                Enlarge(Length(fLines[PosY]) - PosX);
            end;

        VK_NEXT:
            if fInProposalCall then
             FProposalForm.PAGEDOWN
            else
            if not (ssShift in Shift) then begin
                Collapse;
                if not (ssCtrl in Shift)
                    then PosY := FindVisibleRow(PosY, ClientLines - 1, True)
                    else PosY := FindVisibleRow(OffsetY, ClientLines - 1, True)
            end else
                if not (ssCtrl in Shift)
                    then Enlarge(ClientLines() - 1, True)
                    else Enlarge(OffsetY + (ClientLines - 1) - PosY, True);

        VK_PRIOR:
            if fInProposalCall then
             FProposalForm.PAGEUP
            else
            if not (ssShift in Shift) then begin
                Collapse;
                if not (ssCtrl in Shift)
                    then PosY := FindVisibleRow(PosY, -(ClientLines - 1), True)
                    else PosY := OffsetY
            end else
                if not (ssCtrl in Shift)
                    then Enlarge( -(ClientLines - 1), True)
                    else Enlarge( -(OffsetY - PosY), True);
       VK_ESCAPE:
       begin
        CloseProposal
       end;


        VK_DELETE:
            if not (smoReadOnly in fOptions) then
                Range.Delete;

        VK_TAB:
            if not (smoReadOnly in fOptions) then
                Range.SetTextEx(StringOfChar(' ', 4 - PosX mod 4),ukLetterTyped);

        VK_BACK:
            if not (smoReadOnly in fOptions) then begin
                if (PosX = 0) and (FindVisibleRow(Range.PosY, -1, True) = Range.PosY - 1) then
                    with Range do
                         begin
                         StartX := Length(fLines[PosY - 1]);
                         StartY := PosY - 1;
                         end
                else
                if PosX > 0
                   then begin
                        if Length(Trim(copy(Lines.Strings[PosY],1,PosX)))=0
                           then StartX:=0
                           else
                           begin
                            if (StartX=EndX) and (StartY=EndY) then
                             StartX:=PosX-1;
                           end;
                        end;
                Range.Delete;
            end;

        VK_RETURN:
            if fInProposalCall then
             FProposalForm.CompleteProposal
            else
            if not (smoReadOnly in fOptions)
               then begin
                    {if not (smoTabulatedReturn in fOptions)
                       then Range.SetTextEx(#13#10,ukLetterTyped);
                       else{}
                       begin
                            //Следующая строка смотрится слегка сложновато, но
                            //по сути все просто - берем количество пробелов в
                            //текущей строке, и при добавлении новой строки
                            //вставляем их
                            x:=PosY;//Не удивляйтесь - не хочу вводить новую переменную
                            if x<Lines.Count then
                            begin
                              while Length(Trim(Lines.Strings[x]))=0 do
                                    begin
                                    if x=0 then break;
                                    dec(x);
                                    end;
                              Range.SetTextEx(#13#10+copy(Lines.Strings[x],1,system.pos(Trim(Lines.Strings[x]),Lines.Strings[x])-1),ukLetterTyped);
                              end
                            else
                              Range.SetTextEx(#13#10,ukLetterTyped);
                        end

                    end;

        VK_INSERT:
            if Shift=[]
               then begin
                    if not (smoReadOnly in fOptions) then
                       if smoOverwrite in fOptions
                          then SetOptions(fOptions + [smoOverwrite])
                          else SetOptions(fOptions - [smoOverwrite]);
                    end
               else begin
                    //SiO: Добавим возможность копирования и вставки
                    //по Ctrl+Ins / Shift+Ins - я без них не могу =)
                    if Shift=[ssCtrl] then fRange.CopyToClipboard;
                    if Shift=[ssShift] then fRange.PasteFromClipboard;
                    end;
        ORD(' '):
            if Shift=[ssCtrl] then
            begin
             fInProposalCall :=True;
            end;


        ORD('A'):
            if Shift=[ssCtrl] then
               fRange.SelectAll;

        ORD('C'):
            if ssCtrl in Shift then
                fRange.CopyToClipboard;

        ORD('X'):
            if Shift = [ssCtrl] then
                fRange.CutToClipBoard;

        ORD('V'):
            if (Shift = [ssCtrl]) and not (smoReadOnly in fOptions) then
                fRange.PasteFromClipboard;

        ORD('Z'):
            if ssCtrl in Shift then
               if CanUndo then DoUndo;

        ORD('I'):
            if Shift=[ssCtrl, ssShift] then
               fRange.MakeIndent;

        ORD('U'):
            if Shift=[ssCtrl, ssShift] then
               fRange.MakeUnIndent;


        191://	ORD('/'):
            if (Shift = [ssCtrl])and(poHasILComment in fParseAttributes.ParseOptions) then
               fRange.MakeComment(fParseAttributes.fLitILComment);{}

        VK_ADD:
            if ssCtrl in Shift then
                fRange.ExpandSection(ssShift in Shift);

        VK_SUBTRACT:
            if ssCtrl in Shift then
                fRange.CollapseSection(ssShift in Shift);

        VK_F5:
            fRange.CreateSection;

        VK_F6:
            fRange.ExplodeSection(ssCtrl in Shift);
        Ord('0')..Ord('9'):
        begin
            if ssCtrl in Shift then
            begin
                if ssShift in Shift
                    then BookMarks[Key - Ord('0')] := fRange.PosY
                    else Navigate(0, BookMarks[Key - Ord('0')]);
            end
{            else
            if Lines.Count=0 then
            begin
              PosX := PosX + 1;
              PosX := PosX - 1
            end;
 }
        end;
        VK_NUMPAD0..VK_NUMPAD9:
            if ssCtrl in Shift then
                if ssShift in Shift
                    then BookMarks[Key - VK_NUMPAD0] := fRange.PosY
                    else Navigate(0, BookMarks[Key - VK_NUMPAD0]);

        {$IFDEF SYNDEBUG}
        VK_MULTIPLY:
            if ssCtrl in Shift then
                Log('---------------');
        {$ENDIF}

        end;  (**)
end;


// Вставка символа в текущую позицию
procedure TMPCustomSyntaxMemo.KeyPress(var Key: Char);
begin
    inherited;
    if (not (smoReadOnly in fOptions)) then
    case Key of
        #32..High(Char) :
        if fInProposalCall and (Key=#32) and not FProposalForm.Visible then
         ProposalCall
        else
        begin
         if (self.Lines.Count=0) then
         begin
          Range.PosX:= Range.PosX + 1;
          Range.PosX:= Range.PosX - 1;
         end;
         Range.Text := Key;
        if fInProposalCall then
          FProposalForm.ChangeListText;

        end
//        Range. SetTextEx(Key,ukLetterTyped);
    end;{}
end;


// Отпускание кнопки
procedure TMPCustomSyntaxMemo.KeyUp(var Key: Word; Shift: TShiftState);
begin
    Cursor := crIBeam;
    ShowHint := False;
    SelectedWord := Point(-1, -1);
    if Assigned(fOnWordInfo) then
        fOnWordInfo(self, 0, 0, -1, -1, False);
    fHinting := False;    
    if Key = VK_BACK then
       if fInProposalCall then
          FProposalForm.ChangeListText;

    inherited;
end;


// Paint() Перерисовка всего компонента
procedure TMPCustomSyntaxMemo.Paint;
begin
//    inherited;
    if Parent = nil then Exit;
    {} {$IFDEF SYNDEBUG}
    {} Log('Memo.Paint');
    {} {$ENDIF}
    NeedRedrawAll;
end;


// CreateParams() Задание параметров компонента
procedure TMPCustomSyntaxMemo.CreateParams(var Params: TCreateParams);
begin
    inherited;
    with Params do begin
        ExStyle := ExStyle or WS_EX_CLIENTEDGE; // 3d рамка окна
        Style   := Style and not WS_TABSTOP;
    end;
end;


// WMMouseWheel() Отработка колеса мыши
procedure TMPCustomSyntaxMemo.WMMouseWheel(var Message: TMessage);
begin
    inherited;
    if GetKeyState(VK_CONTROL) and $8000 <> 0 then
        if Short(Message.WParamHi) > 0
            then OffsetXPix := Max(OffsetXPix - 4, 0)
            else OffsetXPix := OffsetXPix + 4
    else
        if Short(Message.WParamHi) > 0
            then OffsetY := FindVisibleRow(OffsetY, -3, True)
            else OffsetY := FindVisibleRow(OffsetY, +3, True);
end;


// WMKillFocus() Отработка потери фокуса
procedure TMPCustomSyntaxMemo.WMKillFocus(var Msg: TWMKillFocus);
begin
    inherited;
    if (Msg.FocusedWnd <> fHScroll.Handle)
    and (Msg.FocusedWnd <> fVScroll.Handle) then begin
        HideCaret;
        Windows.DestroyCaret;
    end;
end;


// WMSetFocus() Отработка получения фокуса
procedure TMPCustomSyntaxMemo.WMSetFocus(var Msg: TWMSetFocus);
begin
    inherited;
    if (Msg.FocusedWnd <> fHScroll.Handle)
    and (Msg.FocusedWnd <> fVScroll.Handle) then begin
        Windows.CreateCaret(Handle, 0, 1, FCharHeight);
        ShowCaret;
    end;
end;


// ScrollEnter() Вхождение в скроллинг
procedure TMPCustomSyntaxMemo.ScrollEnter(Sender: TObject);
begin
    SetFocus;
end;


// MouseDown() Нажатие кнопки мыши
procedure TMPCustomSyntaxMemo.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var Col, Row, SRow: Integer;
    R: TRect;
begin
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('MouseDown at (%d, %d)', [X, Y]);
    {} {$ENDIF}
    if not Focused then SetFocus;
    { Левая кнопка мыши }
    if (Button = mbLeft) and (Shift = [ssLeft]) then
        if PtInRect(EntireGutterRect[-1], Point(X, Y)) then begin
            if x>11
               then begin
                    { Нажата кнопка в гуттере - отработка скрытия / раскрытия секции }
                    WndOffsetToPixOffset(Point(X, Y), Col, SRow, False);
                    Row := FindVisibleRow(OffsetY, SRow, False);
                    if Row<>-1
                       then with fSections.Section[Row] do
                                 if (Level > 0) and (Row = RowBeg)
                                    then begin
                                         R := GetSectionButtonRect(SRow, Level);
                                         if PtInRect(R, Point(X, Y))
                                            then begin
                                                 if Collapsed
                                                    then fSections.Expand(Row, False, False)
                                                    else fSections.Collapse(Row, False, False);
                                                 end;
                                         end;
                    end
               else begin
                    WndOffsetToPixOffset(Point(X, Y), Col, SRow, False);
                    Row := FindVisibleRow(OffsetY, SRow, False);
                    if fBreakPoints.IsBreakPoint[Row]
                       then fBreakPoints.IsBreakPoint[Row]:=False
                       else fBreakPoints.IsBreakPoint[Row]:=True;
                    end;
        end else begin
            fDown := True;
            { сжимаем выделение }
            Range.Collapse;
            WndOffsetToPixOffset(Point(X, Y), Col, Row, True);
            if fLines.IsValidLineIndex(Row) then begin
                Col := PixOffsetToCharPos(Col, Row);
                Range.Pos := Point(Col, Row);
                CloseProposal
            end;
        end
    else
    { Средняя кнопка мыши - панорамирование (!!!) }
    {SiO: Переделано}
    if (Button = mbMiddle) and (Shift = [ssMiddle])and(smoPanning in fOptions) then begin
        fPanning := True;
        Cursor := crSizeAll;
        fPanStartPoint:=Point(x,y);
        GetWindowRect(self.Handle,R);
        R.Bottom:=R.Bottom-fHScroll.Height-4;
        R.Right:=R.Right-fVScroll.Width-4;
        R.Left:=R.Left+GutterWidth+2;
        R.Top:=R.Top+2;
        ClipCursor(@R);
    end;
    inherited;
end;



 // MouseMove() Движение мыши - отработка изменения выделения
procedure TMPCustomSyntaxMemo.MouseMove(Shift: TShiftState; X, Y: Integer);
var Col, Row: Integer;
    oX,oY:integer;
    R:TRect;
    P:TPoint;
begin
    // Управление выделением
    if fDown and (Shift = [ssLeft]) then begin
        // происходят изменения только если сменилась позиция
        { DONE -oMax Proof -c19.03.2006 :
            WndOffsetToPixOffset может вернуть Row <= 0 для
            специальных районов (выше текста, ниже текста, скрытый текст)
            и т. д. Эта ситуация никак не обрабатывалась. }
        WndOffsetToPixOffset(Point(X, Y), Col, Row, False);
        // получаем номер строки
        Row := FindVisibleRow(OffsetY, Row, True);
        // получаем номер столбца в строке
        Col := PixOffsetToCharPos(Col, Row);
        if (Col <> Range.PosX) or (Row <> Range.PosY) then begin
            Range.Enlarge(Row - Range.PosY, True);
            Range.Enlarge(Col - Range.PosX);
        end;
    end else
    if fHinting then begin
        if (ssCtrl in Shift)
           then begin
                WndOffsetToPixOffset(Point(X, Y), Col, Row, True);
                if Row<>-1
                   then begin
                        PixOffsetToCharPos(Col, Row, @Col);
                        if InRange(Col, 0, fLines.Parser[Row].Count - 1)
                           then begin
                                SelectedWord := Point(Col, Row);
                                if Assigned(fOnWordInfo)
                                   then fOnWordInfo(self, X, Y, Col, Row, True)
                                   else with fLines.Parser[Row].Tokens[Col] do
                                             Hint := Format('Word: "%s"'#13#10'Start: %d'#13#10'Length: %d'#13#10'As token #%d', [Copy(fLines[Row], stStart + 1, stLength), stStart, stLength, stToken]);
                                end
                        end;
                end
           else begin
                Cursor := crIBeam;
                ShowHint := False;
                SelectedWord := Point(-1, -1);
                fHinting := False;
                end;
    end else
    if fPanning then begin
        oX:=fPanStartPoint.X;
        oY:=fPanStartPoint.Y;
        fPanStartPoint:=Point(x,y);

        oY:=(oY-fPanStartPoint.Y);
        oX:=(oX-fPanStartPoint.X);
        if (smoHorPanning in fOptions)
           then OffsetXPix := Max(OffsetXPix + oX, 0);
        if (smoVerPanningReverse in fOptions)
           then oY:=-oY;
        OffsetY := FindVisibleRow(OffsetY, oY, True);

        //Перебрысывание курсора
        GetWindowRect(self.Handle,R);
        R.Bottom:=R.Bottom-fHScroll.Height-5;
        R.Top:=R.Top+2;
        GetCursorPos(P);
        if P.Y=R.Top
           then begin
                P.Y:=R.Bottom-1;
                fPanStartPoint.Y:=fPanStartPoint.Y+(R.Bottom-R.Top-1);
                SetCursorPos(P.X,P.Y);
                end;
        if P.Y=R.Bottom
           then begin
                P.Y:=R.Top+1;
                fPanStartPoint.Y:=fPanStartPoint.Y-(R.Bottom-R.Top-1);
                SetCursorPos(P.X,P.Y);
                end;
         CloseProposal;

    end else
    if Shift = [] then begin
        if PtInRect(EntireGutterRect[-1], Point(X, Y))
            then Cursor := crDefault
            else Cursor := crIBeam;
    end;
    inherited;
end;



 // MouseUp() Отпускание кнопки мыши
procedure TMPCustomSyntaxMemo.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var p:TPoint;
    Handled:boolean;
    R:TRect;
    W,Row:integer;
begin
inherited;
fDown := False;
if fPanning
   then begin
        fPanning := False;
        Cursor := crIBeam;
        ClipCursor(nil);
        exit;
        end;

if (Button=mbLeft)and(Shift=[ssRight])and(smoPanning in fOptions)
   then begin
        fPanning := True;
        Cursor := crSizeAll;
        fPanStartPoint:=Point(x,y);
        GetWindowRect(self.Handle,R);
        R.Bottom:=R.Bottom-fHScroll.Height-4;
        R.Right:=R.Right-fVScroll.Width-4;
        R.Left:=R.Left+GutterWidth+2;
        R.Top:=R.Top+2;
        ClipCursor(@R);
        end;

if Button=mbRight
   then begin
        if PtInRect(EntireGutterRect[-1], Point(X, Y))
           then begin //Щелчок на гутере
                if x<11
                   then begin //Щелчок на BreakPoint'е
                        GetWordAtPos(X,Y,W,Row);
                        fBreakPoints.RowOfCurrentBP:=Row;
                        GetCursorPos(P);
                        if Assigned(fBreakPoints.fPopUpMenu)
                           then begin
                                Handled:=False;
                                if Assigned(fOnBreakPointPopup)
                                   then fOnBreakPointPopup(self,Point(X,Y),Handled);
                                if not Handled
                                   then fBreakPoints.fPopUpMenu.Popup(P.X, P.Y);
                                end;
                        end;
                end
           else begin //Щелчок на тексте
                GetCursorPos(P);
                if Assigned(fPopUpMenu)
                   then begin
                        Handled:=False;
                        if Assigned(fOnContextPopup)
                           then fOnContextPopup(self,Point(X,Y),Handled);
                        if not Handled
                           then fPopUpMenu.Popup(P.X, P.Y);
                        end;
                end;
        end;
end;


// FindNextWord() Ищет следующее слово.
// Если слово найдено (не конец текста), его начало возвращается
// через ссылки wx, wy
function TMPCustomSyntaxMemo.FindNextWord(var wx, wy: Integer): Boolean;
var Sp: TMPSyntaxParser;
    wn:integer;
begin
    Result := True;
    wx := CharPosToWordIndex(Range.PosX, Range.PosY);
    wy := Range.PosY;
    Sp := fLines.Parser[wy];
    { Курсор между словами в середине строки }
    if wx < 0 then begin
        wy := Range.PosY;
        wx := Sp[-wx].stStart;
    end else
    { Курсор после последнего слова в строке }
    if wx = MAXINT then begin
        wy := FindVisibleRow(wy, 1, False);
        Result := wy >= 0;
        if Result then begin
            Sp := fLines.Parser[wy];
            if Sp.Count > 0
                then wx := Sp[0].stStart
                else wx := 0;
        end
    end else
    { Курсор на последнем слове в строке }
    if wx = Sp.Count - 1 then
        with Sp[wx] do
            wx := stStart + stLength
    { Курсор на любом другом слове в строке }
    else
    begin
     wn:=wx;
     repeat
        Inc(wn);
        if wn = Sp.Count then
        begin
          with Sp[wn-1] do
           wx := stStart + stLength;
          Exit;
        end;
        wx := Sp[wn].stStart;

     until Sp[wn].stToken in tokWords +tokUserWords;
    end
end;


// FindPrevWord() Ищет предыдующее слово.
// Если слово найдено (не начало текста), его начало возвращается
// через ссылки wx, wy
function TMPCustomSyntaxMemo.FindPrevWord(var wx, wy: Integer): Boolean;
var Sp: TMPSyntaxParser;
    function FindLastWordOfPrevRow: Boolean;
    begin
        wy := FindVisibleRow(wy, -1, False);
        Result := wy >= 0;
        if Result then begin
            Sp := fLines.Parser[wy];
            if Sp.Count > 0
                then
                    with Sp[Sp.Count - 1] do
                        wx := stStart + stLength
                else wx := 0;
        end;
    end;
var
    wn:integer;    
begin
    Result := True;
    wx := CharPosToWordIndex(Range.PosX, Range.PosY);
    wy := Range.PosY;
    Sp := fLines.Parser[wy];
    { Курсор между словами в середине строки }
    if wx < 0 then
        { Перед первым словом - слева ничего нет }
        if wx = -1
            then Result := FindLastWordOfPrevRow
            else wx := Sp[-wx - 1].stStart
    else
    { После последнего слова в строке }
    if wx = MAXINT then
        if Sp.Count = 0
            then Result := FindLastWordOfPrevRow
            else wx := Sp[Sp.Count-1].stStart
    else
    { Внутри произвольного слова в строке }
    if Sp[wx].stStart = Range.PosX then
        { В начале слова }
        if wx = 0
            then Result := FindLastWordOfPrevRow
            else
            begin
             wn:=wx;
             repeat
                Dec(wn);
                if wn <0 then
                begin
                  wx:=-1;
                  Result := FindLastWordOfPrevRow;
                  Exit;
                end;
                wx := Sp[wn].stStart;

             until Sp[wn].stToken in tokWords+tokUserWords;

//             wx := Sp[wx - 1].stStart
            end
    else
        { В середине слова }
        wx := Sp[wx].stStart;
end;

function TMPCustomSyntaxMemo.WordByPos(const WordPos:TPoint):string;
var
    Parser:TMPSyntaxParser;
    i:Integer;
begin
 Result:='';
 if (WordPos.Y>=0) and (WordPos.Y<fLines.Count) then
 begin
   Parser:=Lines.Parser[WordPos.Y];
   for i:=Parser.Count-1 downto 0 do
    if Parser[i].stStart<=WordPos.X then
    begin
     Result:=Copy(Lines[WordPos.Y],Parser[i].stStart+1,Parser[i].stLength)   ;
     Break
    end

 end;
end;

// PaintLine() Перерисовывает строку
(*procedure TMPCustomSyntaxMemo.PaintLine(const ScreenRow, Row: Integer);
var CharPos, WIndex, SelIndeXFrom, SelIndeXTo, i: Integer;
    T: TMPSyntaxToken;
    s: string;
    PaintOffset, SecPnt: TPoint;
    ClipRgn: HRGN;
    RowRect, WordRect, R: TRect;
    Sp: TMPSyntaxParser;
    Sec: TMPSynMemoSection;
begin
    // Если компонент не видет - чего ж перерисовывать его?
    if not Visible then Exit;

    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.PaintLine %d as %d', [ScreenRow, Row]);
    {} {$ENDIF}

    // Параметры строки
    RowRect := TextRowRect[ScreenRow];

    // Отрисовываем GUTTER
    with Canvas do begin
        // Закраска области Gutter-a
        if smoVSNET_SectionsStyle in fOptions
            then R := SymbolsGutterRect[ScreenRow]
            else R := EntireGutterRect[ScreenRow];
        Brush.Style := bsSolid;
        Brush.Color := clBtnFace;
        Dec(R.Right, 4);
        FillRect( R );
        // Bevel Edge справа Gutter-a
        Pen.Color := clBtnHighlight;
        MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
        Pen.Color := clBtnShadow;
        MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
        Pen.Color := self.Color;
        MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
        MoveTo(R.Right, R.Top); LineTo(R.Right, R.Bottom); Inc(R.Right);
        // Чистим строку
        Canvas.Brush.Color := Self.Color;
        FillRect(Rect(R.Right, RowRect.Top, RowRect.Right, RowRect.Bottom));

        // Если номер строки недопустимый (напр. строки снизу текста)
        // То просто все стираем и выходим
        if Row < 0 then Exit;

        // Обработка действительной строки текста
        Sp := fLines.Parser[Row];                           // парсер строки
        Sec := Sp.Section;                                  // секция строки
        s := fLines[Row];                                   // строка
        R := GetSectionButtonRect(ScreenRow, Sec.Level);    // кадватик
        SecPnt := CenterPoint(R);                           // центральная точка кадватика

        // Начало секции - прорисовываем кадватик
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
                // Линия справа от кадватика
                MoveTo(Right, SecPnt.Y);
                LineTo(RowRect.Left - 2, SecPnt.Y);
                if not Sec.Collapsed then begin
                    // Линия внизу кадватика
                    MoveTo(SecPnt.X, Bottom);
                    LineTo(SecPnt.X, RowRect.Bottom);
                end;
            end;
            // Отрисовываем троеточие в конце строки
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

        // Конец секции - рисуем гориз. палочку
        if (Sec.RowEnd = Row) and (Sec.Level > 0) then begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, RowRect.Top);
            LineTo(SecPnt.X, SecPnt.Y);
            LineTo(RowRect.Left - 2, SecPnt.Y);
        end else

        // Просто строка, принадлежащая не-корневой секции
        if Sec.Level > 0 then begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, RowRect.Top);
            LineTo(SecPnt.X, RowRect.Bottom);
        end;

        // Отрисовка вертикальных линий родительских секций
        // только НЕ ДЛЯ режима эмуляции MS VS NET
        if not (smoVSNET_SectionsStyle in fOptions) then
            for i := Sec.Level - 1 downto 1 do begin
                Dec(SecPnt.X, fSectionIndent);
                MoveTo(SecPnt.X, RowRect.Top);
                LineTo(SecPnt.X, RowRect.Bottom);
            end;

        // Рассчитываем и устанавливаем Clip Region для канвы текста
        with RowRect do
            if Sec.Collapsed
                then ClipRgn := CreateRectRgn(Left, Top, Right - 33, Bottom)
                else ClipRgn := CreateRectRgn(Left, Top, Right, Bottom);
        SelectClipRgn(Canvas.Handle, ClipRgn);

        // Смещение для начала строки (X<=0 !!!)
        PaintOffset := PixOffsetToWndOffsetEx(0, ScreenRow);

        // Отображение выделения
        if not Range.IsEmpty() and InRange(Row, Range.StartY, Range.EndY) then begin
            // Если строка = первой строке выделения, то определяемся с левой границей,
            // иначе, принимаем её за начало видимой области текста (OffsetX)
            if Row = Range.StartY
                then SelIndeXFrom := PaintOffset.X + CharPosToPixOffset(Range.StartX, Row)
                else SelIndeXFrom := RowRect.Left;
            // Аналогично определяемся с правой границей выделения
            if Row = Range.EndY
                then SelIndeXTo   := PaintOffset.X + CharPosToPixOffset(Range.EndX, Row)
                else SelIndeXTo   := RowRect.Right;
            // Рисуем выделение
            Canvas.Brush.Style := bsSolid;
            Canvas.Brush.Color := fSelColor;
            Canvas.FillRect( Rect(SelIndeXFrom, RowRect.Top, SelIndeXTo, RowRect.Bottom) );
        end;

        // Рисуем, по очереди, все слова
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

        // Отменяем Clip Region для канвы строки
        SelectClipRgn(Canvas.Handle, 0);
        DeleteObject(ClipRgn);
    end;
end;    *)


// Пересчитывает параметры прорисовки, если изменился шрифт
procedure TMPCustomSyntaxMemo.FontChange(Sender: TObject);
begin
    fLines.BeginUpdate;
    CalcFontParams;
    NeedRedrawAll;
    fLines.EndUpdate;
end;


// Устанавливает/снимает выделение для конкретного слова в строке (красная рамка)
procedure TMPCustomSyntaxMemo.SetSelectedWord(const Value: TPoint);
begin
    fLines.BeginUpdate;
    // Снимаем старое выделение
    if fLines.IsValidLineIndex( fSelWord.Y ) then
        NeedRedraw(fSelWord.Y);
    // Сбрасываем выделение
    fSelWord := Point(-1, -1);
    // Устанавливаем новое выделение
    if fLines.IsValidLineIndex( Value.Y ) then begin
        // Устанавливаем смещение так, чтобы выделяемое слово было целиком на экране
        ShowWord(Value.Y, Value.X);
        // Если создается выделение - так посему и быть
        fSelWord := Value;
        NeedRedraw(fSelWord.Y);
    end;
    fLines.EndUpdate;
end;


// Показывает слово на экране (устанавливая соответствующее смещение экрана)
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


// Возвращает информацию о слове в позиции X, Y относительно окна
// LineIndex - номер строки
// WBeg      - номер первого символа слова в строке
// WLen      - длина слова
function TMPCustomSyntaxMemo.GetWordAtPos(const X, Y: Integer; var WordIndex, Row: Integer): Boolean;
var n, Row1: Integer;
begin
    WndOffsetToPixOffset(Point(X, Y), n, Row1, True);
    Result := fLines.IsValidLineIndex(Row1);
    if Result then begin
        Row := Row1;
        PixOffsetToCharPos(n, Row1, @WordIndex);
    end;
end;


// Устанавливает видимой строку Row, столбец Col,
// при необходимости открывая соответствующие секции
procedure TMPCustomSyntaxMemo.Navigate(const Col, Row: Integer);
begin
    if not fLines.IsValidLineIndex(Row) then Exit;
    {$IFDEF SYNDEBUG}
    LogFmt('Memo.NavigateTo Col=%d; Row=%d', [Col, Row]);
    {$ENDIF}
    fLines.BeginUpdate;
    fSections.Expand(Row, False, True);
    SetOffsets(Point(0, FindVisibleRow(Row, -2, True)));
    fRange.Pos := Point(Col, Row);
    fLines.EndUpdate;
end;


// Устанавливает видимой позицию символа PosX в строке PosY
procedure TMPCustomSyntaxMemo.MakeVisible(const Col, Row: Integer; const Length: Integer = 1);
var RowPix, CharPix, CharPixLen: Integer;
    NewOffsets: TPoint;
    R: TRect;
begin
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.MakeVisible(Col=%d; Row=%d; Length=%d)', [Col, Row, Length]);
    {} {$ENDIF}

    // Вертикаль
    RowPix := RangeRowToScreenRow(Row);
    if RowPix = ROW_HIDEN then Exit else
    if RowPix = ROW_ABOVE_SCREEN then NewOffsets.Y := Row else
    if RowPix = ROW_BELOW_SCREEN then
        NewOffsets.Y := FindVisibleRow(Row, -(ClientLines - 1), True)
    else
        NewOffsets.Y := OffsetY;

    // Горизонталь
    R := TextRowRect[0];
    CharPixLen := Length * 10;
    CharPix := CharPosToPixOffset(Col, Row);
    if CharPix < OffsetXPix then NewOffsets.X := CharPix else
    if CharPix + CharPixLen - OffsetXPix > R.Right - R.Left then
        NewOffsets.X := CharPix + CharPixLen - R.Right + R.Left
    else
        NewOffsets.X := OffsetXPix;

    // Все вместе
    if (NewOffsets.X <> OffsetXPix) or (NewOffsets.Y <> OffsetY) then
        SetOffsets(NewOffsets);
end;


// Возвращает индекс слова в строке по индексу символа
// Если попадаем в пробелы - возвращает отрицательное значение индекса ближайшего слова справа
// Если вне строки - возвращает MAXINT
function TMPCustomSyntaxMemo.CharPosToWordIndex(const Col, Row: Integer): Integer;
var Sp: TMPSyntaxParser;
    i, WBeg: Integer;
begin
    Result := MAXINT;
    if not InRange(Row, 0, fLines.Count - 1) then Exit;
    Sp := TMPSyntaxParser(fLines.Objects[Row]);
    if Sp <> nil then
        for i := 0 to Sp.Count - 1 do begin
            WBeg := Sp[i].stStart;
            if Col < WBeg then begin
                Result := -i;
                Exit;
            end else
            if Col < WBeg + Sp[i].stLength then begin
                Result := i;
                Exit;
            end;
        end;
end;


// Возвращает прерывание по определению пользовательского слова
function TMPCustomSyntaxMemo.GetUserTokenEvent: TUserTokenEvent;
begin
    if Assigned(fParseAttributes)
        then Result := fParseAttributes.OnUserToken
        else Result := nil;
end;


// Устанавливает прерывание по определению пользовательского слова
procedure TMPCustomSyntaxMemo.SetUserTokenEvent(const Value: TUserTokenEvent);
begin
    if Assigned(fParseAttributes) then
        fParseAttributes.OnUserToken := Value;
end;


// Устанавливает ширину GUTTER-а
procedure TMPCustomSyntaxMemo.SetGutterWidth(const Value: Integer);
begin
    if fGutterWidth <> Value then begin
        fGutterWidth := Value;
        Repaint;
    end;
end;


// Возвращает истину, если строка показывается на экране
function TMPCustomSyntaxMemo.IsLineVisible(const Row: Integer; const PScreenRow: PInteger = nil): Boolean;
var sr: Integer;
begin
    sr := RangeRowToScreenRow(Row);
    Result := InRange(sr, 0, ClientLines - 1);
    if Result and Assigned(PScreenRow) then
        PScreenRow^ := sr;
end;


// Устанавливает новое смещение для уровня секции
procedure TMPCustomSyntaxMemo.SetSectionIndent(const Value: Integer);
begin
    fSectionIndent := Value;
    NeedRedrawAll;
end;


// Возвращает прямоугольник экранных координат заданной области
// Глобальная функция. Должна быть переписана при изменении способа вычисления
// координат специальных зон экрана.
// На входе - ЭКРАННЫЙ индекс строки (относительно верхней строки экрана).
// Если ScreenRow = -1, возвращается соответствующая область ОКНА.
// НЕ ПРОИЗВОДИТ ПРОВЕРКУ ВИДИМОСТИ СТРОКИ и ТОГО, ЧТО СТРОКА НАХОДИТСЯ В ПРЕДЕЛАХ ЭКРАНА
function TMPCustomSyntaxMemo.GetWndRect(const ScreenRow, Index: Integer): TRect;
begin
    if smoVSNET_SectionsStyle in fOptions then
        case Index of

        { EntireRowRect }
        0:  begin
                if ScreenRow = -1 then begin
                    { Для всех строк сразу }
                    Result := ClientRect;
                    Dec(Result.Bottom, fHScroll.Height);
                end else
                    { Для заданной строки }
                    Result := Bounds(   0,
                                        ScreenRow * fCharHeight,
                                        ClientWidth,
                                        Min(fCharHeight, ClientHeight - fHScroll.Height - ScreenRow * fCharHeight)  );
//                                      fCharHeight );
                Dec(Result.Right, fVScroll.Width);
                Dec(Result.Right);
            end;

        { TextRowRect }
        1:  begin
                Result := EntireRowRect[ScreenRow];
                Result.Left := EntireGutterRect[ScreenRow].Right;
            end;

        { EntireGutterRect }
        2:  begin
                Result := SymbolsGutterRect[ScreenRow];
                Inc(Result.Right, fSectionIndent + 2);
            end;

        { SymbolsGutterRect }
        3:  begin
                Result := EntireRowRect[ScreenRow];
                Result.Right := Result.Left + fGutterWidth;
            end;
        end

    else
        case Index of

        { EntireRowRect }
        0:  begin
                if ScreenRow = -1 then begin
                    { Для всех строк сразу }
                    Result := ClientRect;
                    Dec(Result.Bottom, fHScroll.Height);
                end else
                    { Для заданной строки }
                    Result := Bounds(
                        0,
                        ScreenRow * fCharHeight,
                        ClientWidth,
                        Min(fCharHeight, ClientHeight - fHScroll.Height - ScreenRow * fCharHeight)  );
                Dec(Result.Right, fVScroll.Width);
                Dec(Result.Right);
            end;

        { TextRowRect }
        1:  begin
                Result := EntireRowRect[ScreenRow];
                Result.Left := EntireGutterRect[ScreenRow].Right;
            end;

        { EntireGutterRect }
        2:  begin
                Result := EntireRowRect[ScreenRow];
                if smoAutoGutterWidth in fOptions
                    then Result.Right := Result.Left + fGutterWidth + fSections.fMaxExpandLevel*fSectionIndent + 2
                    else Result.Right := Result.Left + fGutterWidth + fSections.fMaxLevel*fSectionIndent + 2;
            end;

        { SymbolsGutterRect }
        3:  begin
                Result := EntireRowRect[ScreenRow];
                Result.Right := Result.Left + fGutterWidth;
            end;
        end;
end;


// Преобразует позицию X, Y клиентской области
// в смещение от начала строки и номер строки текста
procedure TMPCustomSyntaxMemo.WndOffsetToPixOffset(OfsPoint: TPoint; var CharPix, Row: Integer; const TextRow: Boolean);
var R: TRect;
begin
    R := TextRowRect[ 0 ];
    CharPix := OfsPoint.X - R.Left + OffsetXPix;
    // Получаем индекс строки на экране ..
    Row := (OfsPoint.Y - R.Top) div fCharHeight;
    // .. и, если надо, переводим его в реальный индекс строки в тексте
    if TextRow then
        Row := FindVisibleRow(OffsetY, Row, False);
end;


// Преобразует смещение в пикселах внутри строки к координатам
// внутри клиентской области окна
function TMPCustomSyntaxMemo.PixOffsetToWndOffsetEx(const CharPix, ScreenRow: Integer): TPoint;
var Rect:TRect;
begin
    Rect:=TextRowRect[ ScreenRow ];
    with Rect do begin
        Inc(Left, CharPix - OffsetXPix);
        Result := TopLeft;
    end;
end;


// Возвращает область прорисовки кадватика заголовка секции через R: TRect
// Если кадватика нет, возвращается False
function TMPCustomSyntaxMemo.GetSectionButtonRect(const ScreenRow, ALevel: Integer): TRect;
begin
    // Область Guttera для данной строки
    Result := SymbolsGutterRect[ScreenRow];
    if smoVSNET_SectionsStyle in fOptions
        // Все квадратики на одной линии
        then Result.Left := Result.Right + 2
        // Область кадватика по горизонтали внутри своего SectionIndent
        else Result.Left   := Result.Right + (ALevel - 1)*fSectionIndent;
    Result.Right  := Result.Left + 9;
    Result.Top    := (Result.Top + Result.Bottom) shr 1 - 4;
    Result.Bottom := Result.Top + 9;
end;


// Прячет курсор
procedure TMPCustomSyntaxMemo.HideCaret;
begin
    if fCaretVisible and Assigned(Parent) then begin
        Windows.HideCaret(Handle);
        fCaretVisible := False;
    end;
end;


type
{$IFNDEF D6+}
    THackStrings=class(TPersistent)
    private
     UpdateCount: Integer;
    end;
{$ELSE}
 {$IFNDEF D9+}
    THackStrings=class(TPersistent)
    private
     FDefined: TStringsDefined;
     FDelimiter: Char;
     FQuoteChar: Char;
     UpdateCount: Integer;
    end;

 {$ELSE}
    THackStrings=class(TStrings);
 {$ENDIF}    
{$ENDIF}


// Показывает курсор
procedure TMPCustomSyntaxMemo.ShowCaret;
var n, ScreenRow: Integer;
    Cp: TPoint;
begin
    if (Lines.Count=0) then
    begin
        n := CharPosToPixOffset(Range.PosX, Range.PosY);
        Cp := PixOffsetToWndOffsetEx(n, ScreenRow);
        cp.Y:=0;
        { DONE : Thanks Defm. }
        with TextRowRect[ScreenRow] do  // new
            if InRange(Cp.X, Left, Right - 1) then begin  // new
                Windows.SetCaretPos(Cp.X, Cp.Y);
                Windows.ShowCaret(Handle);
                fCaretVisible := True;
            end;  // new

{      Windows.SetCaretPos(1, 1);
      Windows.ShowCaret(Handle);
      fCaretVisible := True;}
    end
    else
    if  (THackStrings(Lines).UpdateCount = 0) and
    { TODO : Д5 }
      ( Lines.IsValidLineIndex(Range.PosY)
     and IsLineVisible(Range.PosY, @ScreenRow)) then
    begin
        n := CharPosToPixOffset(Range.PosX, Range.PosY);
        Cp := PixOffsetToWndOffsetEx(n, ScreenRow);
        { DONE : Thanks Defm. }
        with TextRowRect[ScreenRow] do  // new
            if InRange(Cp.X, Left, Right - 1) then begin  // new
                Windows.SetCaretPos(Cp.X, Cp.Y);
                Windows.ShowCaret(Handle);
                fCaretVisible := True;
            end;  // new
    end;
end;



// RangeRowToScreenRow() Переводит реальный индекс строки в экранный с учетом секционности.
// Если экранных координат не существует (выше верхней границы текста), возвращается -1
// Если строка не видна (в свернутой секции), возвращается -2;
// Если строка ниже нижней границы текста, возвращается -3
// Возвращается индекс строки относительно верхней строки экрана.
function TMPCustomSyntaxMemo.RangeRowToScreenRow(const Row: Integer): Integer;
begin
    // Реальный индекс строки должен быть больше или равен индексу смещения OffsetY,
    // иначе она точно не видна на экране + строка НЕ должна быть латентной [loLatent]
    if Row < OffsetY then
        Result := ROW_ABOVE_SCREEN
    else
    if fLines.Parser[Row].VisibleIndex < 0 then
        Result := ROW_HIDEN
    else begin
        Result := RowIndexConvert(Row, cdNeedScreen) - RowIndexConvert(OffsetY, cdNeedScreen);
        if Result >= ClientLines then
            Result := ROW_BELOW_SCREEN;
    end;
end;


// FindVisibleRow() Ищет видимую строку на удалении Delta видимых строк от заданной.
// Delta может быть >=0 или <0.
// Если EnsureInRange = True, результат будет ВСЕГДА в пределах текста,
// иначе при выходе за пределы текста, функция вернет -1
function TMPCustomSyntaxMemo.FindVisibleRow(const Row, Delta: Integer; const EnsureInRange: Boolean): Integer;
var n: Integer;
begin
    // Видимый индекс искомой строки
    n := RowIndexConvert(Row, cdNeedScreen) + Delta;
    if EnsureInRange then
        n := EnsureRange(n, 0, fSections.Indexes.Count - 1);
    Result := RowIndexConvert(n, cdNeedReal);
end;


// RowIndexConvert() Конвертирует видимый индекс строки в реальный и наоборот
function TMPCustomSyntaxMemo.RowIndexConvert(const Index: Integer; const Direction: TRowIndexConvertionDirection): Integer;
begin
    Result := -1;
    case Direction of
    cdNeedReal:     if InRange(Index, 0, fSections.Indexes.Count - 1)
                        then Result := Integer(fSections.Indexes[Index]);

    cdNeedScreen:   if fLines.IsValidLineIndex(Index)
                        then Result := fLines.Parser[Index].VisibleIndex;
    end;
end;


// Обновляет ScrollBar-ы компонента в зависимости от содержания текста
// и текущей позиции курсора
procedure TMPCustomSyntaxMemo.UpdateScrollBars;
var i, MaxLine: Integer;
begin
    {} {$IFDEF SYNDEBUG}
    {} Log('Memo.UpdateScrollBars');
    {} {$ENDIF}
    // Выход если нет хозяина или режим пакетных изменений
    if (Parent = nil) or (THackStrings(Lines).UpdateCount > 0) then Exit;
{ TODO : Д5a }
    // Временно блокируем вертикальный скролл, пока его обновляем
    fVScroll.OnChange := nil;
    with fVScroll do begin
        Max := Math.Max(fSections.Indexes.Count - ClientLines, 0);
        Enabled := Max > 0;
        if fLines.Count = 0
            then Position := 0
            else Position := RowIndexConvert(OffsetY, cdNeedScreen);
        SmallChange := 1;
        LargeChange := ClientLines - 2;
    end;

    if fPageUpDown<>nil
       then fPageUpDown.Enabled := (fSections.Indexes.Count > ClientLines);

    // Временно блокируем горизонтальный скролл, пока его обновляем
    fHScroll.OnChange := nil;
    with fHScroll do begin
        MaxLine := 0;
        for i := 0 to fLines.Count-1 do
            if Length(fLines[i]) > MaxLine then MaxLine := Length(fLines[i]);
        // SLAB - 10 взято с потолка
        with TextRowRect[-1] do
            Max := Math.Max(MaxLine * 10 - (Right - Left), 0);
        Enabled := Max > 0;
        Position := OffsetXPix;
        SmallChange := 1;
        LargeChange := 32;
    end;

    // Все восстанавливаем
    fVScroll.OnChange := ScrollClick;
    fHScroll.OnChange := ScrollClick;
end;


// Щелчок на скроллинге
procedure TMPCustomSyntaxMemo.ScrollClick(Sender: TObject);
begin
    if Sender = fVScroll
        then OffsetY := RowIndexConvert(fVScroll.Position, cdNeedReal)
        else OffsetXPix := fHScroll.Position;
end;



 // SetOffset() Устанавливает оба смещения текста сразу
// (для уменьшения количества перерисовок)
procedure TMPCustomSyntaxMemo.SetOffsets(NewOffsets: TPoint);
begin
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.SetOffsets Pix=%d; Row=%d', [NewOffsets.X, NewOffsets.Y]);
    {} {$ENDIF}
    { Проверка на допустимость новых смещений }
    // OffsetXPix
    if NewOffsets.X <> fOffsets.X then
        NewOffsets.X := EnsureRange(NewOffsets.X, 0, fHScroll.Max);
    // OffsetY
    if NewOffsets.Y <> fOffsets.Y then begin
        NewOffsets.Y := EnsureRange(RowIndexConvert(NewOffsets.Y, cdNeedScreen), 0, fVScroll.Max);
        NewOffsets.Y := RowIndexConvert(NewOffsets.Y, cdNeedReal);
    end;
    { Проверка изменившихся значений и перерисовка, если она ДЕЙСТВИТЕЛЬНО требуется }
    if (NewOffsets.X <> fOffsets.X) or (NewOffsets.Y <> fOffsets.Y) then begin
        fOffsets := NewOffsets;
        NeedRedrawAll;
        UpdateScrollBars;
    end;
end;


// SetOffset() Устанавливает смещение текста относительно окна компонента
// в отдельности по вертикали или горизонтали.
procedure TMPCustomSyntaxMemo.SetOffset(const Index, Value: Integer);
begin
    case Index of
    0:  SetOffsets(Point(Value, fOffsets.Y));
    1:  SetOffsets(Point(fOffsets.X, Value));
    end;
end;


// Reset() Сбрасывает параметры
procedure TMPCustomSyntaxMemo.Reset;
begin
    {$IFDEF SYNDEBUG}
    Log('Reset');
    {$ENDIF}
    { Self }
    fOffsets        := Point(0, 0);
    fDown           := False;
    fPanning        := False;
//    fOptions        := fOptions - [smoOverwrite, smoReadOnly];
    fBookMarks.Clear;
    { Range }
    fRange.fPos     := fOffsets;
    fRange.fStart   := fOffsets;
    fRange.fEnd     := fOffsets;
    fRange.fSealing := True;
    fRange.fUndoStack.Clear;
end;


// SetOption() Устанавливает опцию
procedure TMPCustomSyntaxMemo.SetOptions(const Value: TMPSynMemoOptions);
var oi: TMPSynMemoOption;
    os: TMPSynMemoOptions;
    new: Boolean;
begin
    if fOptions <> Value then begin
        // Реально меняем опцию
        os := fOptions;
        fOptions := Value;
        // Отрабатываем изменение каждой опции
        for oi := Low(TMPSynMemoOption) to High(TMPSynMemoOption) do
            if [oi]*os <> [oi]*Value then begin
                new := oi in Value;
                case oi of
                { Опции отображения имени файла }
                smoShowFileNameInTabSheet,
                smoShowFileNameInFormCaption:
                    if new then fLines.FileName := fLines.FileName;
                { Опция изменения ширины гуттера }
                smoAutoGutterWidth,
                smoHighlightLine,
                smoSolidSpecialLine,
                smoVSNET_SectionsStyle:
                    NeedRedrawAll;
                smoShowCursorPos: begin
                                  CreateDestroyCursorPos;
                                  CalcScreenParams;
                                  end;
                smoShowPageScroll: begin
                                   CreateDestroyPageUpDown;
                                   CalcScreenParams;
                                   end;
                end;
            end;
        if (smoBreakPointsNeedPosibility in Value)
           then fBreakPoints.Mode:=bmNeedPosibility
           else fBreakPoints.Mode:=bmFreeMode;

        // Подтверждаем изменение
        Change([ciOptions]);
    end;
end;


// Вызывает пользовательское прерывание на изменение
procedure TMPCustomSyntaxMemo.Change(const ChangedItems: TChangedItems);
begin
    // Если параметр пустой [], производится сброс изменений
    if ChangedItems = [] then
        fChangesSummator := []
    else
    begin
        // Суммируем изменения
        fChangesSummator := fChangesSummator + ChangedItems;
        // Если нет блокировки изменений, вызываем пользовательское прерывание
        // со всеми накопленными изменениями

        if THackStrings(fLines).UpdateCount = 0 then
        begin
            if Assigned(fOnChange) then
                fOnChange(self, fChangesSummator);
            // Сбрасываем изменения, чтобы они не повторялись
            fChangesSummator := [];
        end;
    end;
{   if FProposalForm.Visible then
   begin
      //  FProposalForm.BringToFront;
      FProposalForm.Hide;
      FProposalForm.Show
   end       }
end;


{$IFDEF SYNDEBUG}
// Лог компонента для отладки
procedure TMPCustomSyntaxMemo.Log(const LogString: string);
begin
    if LogString = '' then
        fLogDisabled := True
    else
    if fLogDisabled then
        fLogDisabled := False
    else
    if Assigned(fOnLog) then
        fOnLog(self, StringOfChar(' ', Lines.UpdateCount*2) + LogString);
end;

procedure TMPCustomSyntaxMemo.LogFmt(const LogFormat: string; LogArgs: array of const);
begin
    Log(Format(LogFormat, LogArgs));
end;
{$ENDIF}


// Помечаем строку как необходимую к перерисовке
procedure TMPCustomSyntaxMemo.NeedRedraw(const Row: Integer);
var Index: Integer;
begin
    if Parent = nil then Exit;
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.NeedRedraw %d', [Row]);
    {} {$ENDIF}
    // Только помечаем строки к перерисовке
    if IsLineVisible(Row, @Index) then
        fScreenLines[Index] := True;
    // Пробуем перерисовать
    ReDraw;
end;


// Помечаем к перерисовки все строки, ниже и равной заданной
procedure TMPCustomSyntaxMemo.NeedReDrawLE(const Row: Integer);
var Index: Integer;
begin
    if Parent = nil then Exit;
    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.NeedRedrawLE %d', [Row]);
    {} {$ENDIF}
    // Только помечаем строки к перерисовке
    if IsLineVisible(Row, @Index) then
        while Index <= High(fScreenLines) do begin
            fScreenLines[Index] := True;
            Inc(Index);
        end;
    // Пробуем перерисовать
    ReDraw;
end;


// Помечаем к перерисовки все строки
procedure TMPCustomSyntaxMemo.NeedRedrawAll;
var i: Integer;
begin
    {} {$IFDEF SYNDEBUG}
    {} Log('Memo.NeedRedrawAll');
    {} {$ENDIF}
    for i := Low(fScreenLines) to High(fScreenLines) do
        fScreenLines[i] := True;
    // Пробуем перерисовать
    ReDraw;
end;


// Перерисовка экрана - перерисовываем только помеченные к перерисовке строки
procedure TMPCustomSyntaxMemo.ReDraw;
var i: Integer;
begin
    if (Parent = nil) {or (THackStrings(Lines).UpdateCount > 0)} then Exit;
    {} {$IFDEF SYNDEBUG}
    {} Log('Memo.Redraw');
    {} {$ENDIF}
    HideCaret;
    for i := Low(fScreenLines) to High(fScreenLines) do
        if fScreenLines[i] then begin
            PaintLineEx3(i, FindVisibleRow(OffsetY, i, False));
            fScreenLines[i] := False;
        end;
    ShowCaret;
end;


// Устанавливает новый цвет текста/фона по умолчанию
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
var Sp: TMPSyntaxParser;
    TextIndent, SelStart, SelEnd: Integer;
    ClipRgn: HRGN;
    R: TRect;

begin
    // Если компонент не виден - чего ж перерисовывать его?
    if not Visible then Exit;

    {} {$IFDEF SYNDEBUG}
    {} LogFmt('Memo.PaintLineEx3 %d as %d', [ScreenRow, Row]);
    {} {$ENDIF}

    // Отрисовка гуттера
    PaintGutter(fBuffer.Canvas, Row, ScreenRow);

    // Если номер строки недопустимый (строки после текста),
    // просто все стираем и выходим
    if Lines.IsValidLineIndex(Row) then begin
        // Маркеры секций
        PaintSectionMarks( fBuffer.Canvas, Row, ScreenRow );
        // Смещение для начала строки (X <= default_offset !!!)
        TextIndent := PixOffsetToWndOffsetEx(0, ScreenRow).X;
        // Создаем временный вспомогательный парсер как клон имеющегося строчного

//         Sp := TMPSyntaxParser.Create( Lines.Parser[Row] );
         Sp := FCurParser;
         Sp.Assign(Lines.Parser[Row]);
          // Группируем смежные токены (У КОПИИ!!)
         Sp.GroupTokens;

        // Корректируем его на основе информации о выделении
        if not fRange.IsEmpty()
        and InRange(Row, fRange.StartY, fRange.EndY) then begin
            SelStart := IfThen(Row = fRange.StartY, fRange.StartX, -1);
            SelEnd   := IfThen(Row = fRange.EndY, fRange.EndX, MAXINT);
            Sp.SplitTokens(SelStart, SelEnd);
        end else begin
            SelStart := 0;
            SelEnd := 0;
        end;
        // Рассчитываем и устанавливаем Clip Region для канвы текста
        // отсекаем гуттер, иначе он перекроется текстом при OffsetXPix > 0
        with TextRowRect[ScreenRow] do
            ClipRgn := CreateRectRgn(Left, 0, Right, Bottom - Top);
        SelectClipRgn(fBuffer.Canvas.Handle, ClipRgn);
        // Рисуем строку
        PaintTokens(fBuffer.Canvas, Lines[Row], Sp, Row, TextIndent, SelStart, SelEnd );
        // Если строка является первой строкой свернутой секции,
        // прорисовываем знак свертывания (троеточие справа текста)
        if fSections.Section[Row].Collapsed then
            PaintDots(fBuffer.Canvas);

        // Если строка содержит БП - обозначим красной рамкой
        if (fBreakPoints.IsBreakPoint[Row])and(fBreakPoints.BreakPoint[Row].Kind<>bkPosible)
           then begin

                R.Left  := TextIndent + CharPosToPixOffset(0, Row);
                R.Right := Width;//TextIndent + CharPosToPixOffset(Length(Lines[Row]), Row);
                R.Top := 0;
                R.Bottom := fCharHeight;
                if fBreakPoints.BreakPoint[Row].Kind=bkEnabled
                   then fBuffer.Canvas.Brush.Color := fBPEnabledBackColor
                   else fBuffer.Canvas.Brush.Color := fBPDisabledBackColor;
                fBuffer.Canvas.FrameRect( R );
                end;

        // Если строка является строкой пошагового дебага - обозначим это
        if Row=fStepDebugLine
           then begin
                R.Left  := TextIndent + CharPosToPixOffset(0, Row);
                R.Right := Width;//TextIndent + CharPosToPixOffset(Length(Lines[Row]), Row);
                R.Top := 0;
                R.Bottom := fCharHeight;
                fBuffer.Canvas.Brush.Color := fDebugBackColor;
                fBuffer.Canvas.FrameRect( R );
                end;

        // Если строка содержит выделенное слово - обозначаем его
        if fSelWord.Y = Row then
           if fLines.Parser[Row].Count> fSelWord.X then

            with fLines.Parser[Row].Tokens[fSelWord.X] do begin
                R.Left  := TextIndent + CharPosToPixOffset(stStart, Row)-1;
                R.Right := TextIndent + CharPosToPixOffset(stStart + stLength, Row)+1;
                R.Top := 0;
                R.Bottom := fCharHeight;
                fBuffer.Canvas.Brush.Color := fSelectedWordColor;///!!!"Красная" рамка!
                fBuffer.Canvas.FrameRect( R );

                R.Left  := TextIndent + CharPosToPixOffset(stStart, Row);
                R.Right := TextIndent + CharPosToPixOffset(stStart + stLength, Row);
                R.Top := 1;
                R.Bottom := fCharHeight - 1;
                fBuffer.Canvas.FrameRect( R );
            end;


        // Отменяем Clip Region для канвы строки
        SelectClipRgn(fBuffer.Canvas.Handle, 0);
        DeleteObject(ClipRgn);
        // Уничтожаем вспомогательный список токенов
//       FreeParser(Sp)
//        Sp.Free;
    end;
    // Отрисовываем буфер
    with EntireRowRect[ScreenRow] do
        BitBlt(Canvas.Handle, 0, Top, Right - Left, Bottom - Top, fBuffer.Canvas.Handle, 0, 0, SRCCOPY)
end;


// Прорисовка гуттера и очистка строки
procedure TMPCustomSyntaxMemo.PaintGutter(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
var RR, GR, R: TRect;
    i: TBookmarkIndex;
    Kind: TBPKind;
    StrNumRow:string;
begin
    RR := TextRowRect[ScreenRow];
    Dec(RR.Bottom, RR.Top);
    RR.Top := 0;

    GR := EntireGutterRect[ScreenRow];
    Dec(GR.Bottom, GR.Top);
    GR.Top := 0;

    // Левый гуттер
    with ACanvas do begin
        R := GR;
        Brush.Style := bsSolid;
        Brush.Color := clBtnFace;
        if not (smoVSNET_SectionsStyle in fOptions)
            then Dec(R.Right, 4)
            else Dec(R.Right, fSectionIndent + 4);
        FillRect( R );
        Pen.Color := clBtnHighlight;
        MoveTo(R.Right, R.Top);
        LineTo(R.Right, R.Bottom);
        Inc(R.Right);
        Pen.Color := clBtnShadow;
        MoveTo(R.Right, R.Top);
        LineTo(R.Right, R.Bottom);
        Inc(R.Right);
        Brush.Color := self.Color;
        R.Left := R.Right;
        R.Right := GR.Right;
        FillRect( R );
        FillRect( RR );
        if not Lines.IsValidLineIndex(Row) then Exit;
        // Закладка
        if fBookMarks.Find(Row, i) then
            fBookMarks.PaintAt(ACanvas, GR.Left + 9, GR.Top + 2, i);
        // BreakPoints
        if fBreakPoints.Find(Row, Kind) then
            fBreakPoints.PaintAt(ACanvas, GR.Left + 2, GR.Top + 2, Kind);
        StrNumRow:=IntToStr(Row+1);
        Font.Color:=clBlack;
        if smoShowLineNumberToGutter in Options then
         TextOut(GR.Right - fCharWidths[False]['1']*(Length(StrNumRow)+1) ,GR.Top + 2,StrNumRow)
    end;
end;


// Отрисовка маркеров секций
procedure TMPCustomSyntaxMemo.PaintSectionMarks(const ACanvas: TCanvas; const Row, ScreenRow: Integer);
var SecPnt: TPoint;
    Sec: TMPSynMemoSection;
    MR, RR, GR: TRect;
    i: Integer;
begin
    RR := TextRowRect[ScreenRow];
    Dec(RR.Bottom, RR.Top);
    RR.Top := 0;

    GR := EntireGutterRect[ScreenRow];
    Dec(GR.Bottom, GR.Top);
    GR.Top := 0;

    Sec      := fSections.Section[Row];
    MR       := GetSectionButtonRect(ScreenRow, Sec.Level);
    Dec(MR.Top, EntireRowRect[ScreenRow].Top);
    Dec(MR.Bottom, EntireRowRect[ScreenRow].Top);
    SecPnt   := CenterPoint(MR);

    with ACanvas do begin
        if Sec.RowBeg = Row then begin
            // Начало секции - прорисовываем кадватик
            if Sec.Collapsed then begin
                Brush.Color := clWhite;
                Pen.Color   := clBlack;
                Rectangle( MR );
            end else begin
                Brush.Color := clBlack;
                FrameRect( MR );
            end;
            Pen.Color := clBlack;
            with MR do begin
                MoveTo(Left + 2, SecPnt.Y);
                LineTo(Right - 2, SecPnt.Y);
                if Sec.Collapsed then begin
                    MoveTo(SecPnt.X, Top + 2);
                    LineTo(SecPnt.X, Bottom - 2);
                end;
                Pen.Color := clDkGray;
                // Линия справа от кадватика
                MoveTo(Right, SecPnt.Y);
                LineTo(GR.Right - 2, SecPnt.Y);
                if not Sec.Collapsed then begin
                    // Линия внизу кадватика
                    MoveTo(SecPnt.X, Bottom);
                    LineTo(SecPnt.X, GR.Bottom);
                end;
            end;
        end else

        // Конец секции - рисуем гориз. палочку
        if Sec.RowEnd = Row then begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, GR.Top);
            LineTo(SecPnt.X, SecPnt.Y);
            LineTo(GR.Right - 2, SecPnt.Y);
        end else

        // Просто строка, принадлежащая не-корневой секции
        if Sec.Level > 0 then begin
            Pen.Color := clDkGray;
            MoveTo(SecPnt.X, GR.Top);
            LineTo(SecPnt.X, GR.Bottom);
        end;

        // Отрисовка вертикальных линий родительских секций
        // только НЕ ДЛЯ режима эмуляции MS VS NET
        if not (smoVSNET_SectionsStyle in fOptions) then
            for i := Sec.Level - 1 downto 1 do begin
                Dec(SecPnt.X, fSectionIndent);
                MoveTo(SecPnt.X, GR.Top);
                LineTo(SecPnt.X, GR.Bottom);
            end;
    end;
end;


// Прорисовывает многоточие справа текста
procedure TMPCustomSyntaxMemo.PaintDots(const ACanvas: TCanvas);
var R: TRect;
begin
    with ACanvas do begin
        R := ClipRect;
        R.Left := R.Right - 33;
        Brush.Style := bsSolid;
        Brush.Color := self.Color;
        FillRect( R );
        with ClipRect do
            R := Rect(Right - 32, Top + 1, Right - 10, Bottom - 1);
        Brush.Color := clBlue;
        FrameRect( R );
        R := Bounds(R.Left + 5, R.Top + 8, 2, 2);
        FillRect( R );
        OffsetRect(R, 5, 0);
        FillRect( R );
        OffsetRect(R, 5, 0);
        FillRect( R );
    end;
end;


// Отрисовывает строку с синтаксисом на заданную канву
procedure TMPCustomSyntaxMemo.PaintTokens(const ACanvas: TCanvas; s: string; Sp: TMPSyntaxParser; Row, TextIndent, SelStart, SelEnd: Integer);
var wi, CharPos,i: Integer;
    col,ErrCol: TColor;
    R: TRect;
begin
    with ACanvas do begin
        R := ClipRect;
        // Прорисовка фона
        Brush.Style := bsSolid;
        for wi := 0 to Sp.Count - 1 do
            with Sp[wi] do begin

                 col := fParseAttributes.BackColor[stToken];
                 if (smoSolidSpecialLine in fOptions)and(fBreakPoints.IsBreakPoint[Row])and(fBreakPoints.BreakPoint[Row].Kind<>bkPosible)
                    then begin
                         if fBreakPoints.BreakPoint[Row].Kind=bkEnabled
                            then col:=fBPEnabledBackColor
                            else col:=fBPDisabledBackColor;
                         end;
                 if (smoSolidSpecialLine in fOptions)and(StepDebugLine=Row)
                    then col:=fDebugBackColor;


                 if (col <> clDefault) and not (stsInSelection in stStyle)
                    then begin
                         if {((smoHighlightLine in fOptions)and(stToken in [tokILCompDir]))or}
                            ((smoSolidSpecialLine in fOptions)and((fBreakPoints.IsBreakPoint[Row])or(StepDebugLine=Row)))
                            then R.Left := 0
                            else R.Left := TextIndent + CharPosToPixOffset(stStart, s, Sp);
                         if ((smoHighlightLine in fOptions)and(stToken in [tokILComment, tokILCompDir, tokMLCommentBeg, tokELCommentBeg, tokMLCompDirBeg]))or
                            ((smoSolidSpecialLine in fOptions)and((fBreakPoints.IsBreakPoint[Row])or(StepDebugLine=Row)))
                            then R.Right := Width//TextIndent + CharPosToPixOffset(stStart + stLength, s, Sp);
                            else R.Right := TextIndent + CharPosToPixOffset(stStart + stLength, s, Sp);
                         Brush.Color := col;
                         FillRect( R );
                         end;
            end;
        // Прорисовка фона выделения
        if SelStart <> SelEnd then begin
            R.Left := TextIndent;
            if SelStart > 0 then
                Inc(R.Left, CharPosToPixOffset(fRange.StartX, s, Sp));
            if SelEnd < MAXINT
                then R.Right := TextIndent + CharPosToPixOffset(fRange.EndX, s, Sp)
                else R.Right := ClipRect.Right;
            Brush.Color := fSelColor;
            FillRect( R );
        end;
        // Прорисовка всех слов по очереди
        Brush.Style := bsClear;
        Font.Assign(Self.Font);
        PenPos := Point(TextIndent, 0);
        CharPos := 0;
        for wi := 0 to Sp.Count - 1 do
            with Sp[wi] do begin
                with fParseAttributes.fTokenStyles[stToken] do begin
                    Font.Style := tsStyle;
                    if stsInSelection in stStyle then
                        Font.Color := clBlack
                    else
                    if tsForeground = clDefault then
                        Font.Color := fDefForeColor
                    else
                        Font.Color := tsForeground;
                    if (smoSolidSpecialLine in fOptions)
                       then begin
                            if (fBreakPoints.IsBreakPoint[Row])and(fBreakPoints.BreakPoint[Row].Kind<>bkPosible)
                               then begin
                                    if fBreakPoints.BreakPoint[Row].Kind=bkEnabled
                                       then Font.Color := fBPEnabledForeColor
                                       else Font.Color := fBPDisabledForeColor;
                                    end;
                            if StepDebugLine=Row
                               then Font.Color := fDebugForeColor;
                            end;
                end;
                R.TopLeft := PenPos;
                Inc(R.Left, (stStart - CharPos) * fCharWidths[False][' ']);
(*                // Подключение прерывания юзера
                if (stToken = tokCustomDraw) and Assigned(fOnDrawWord) then
                    R.BottomRight := Point(TextIndent + CharPosToPixOffset(stStart+stLength, s, Sp), fCharHeight);
                    fOnDrawWord(self, ACanvas, R, Row, wi);
                end;    *)
                TextOut(R.Left, R.Top, Copy(s, stStart + 1, stLength));

                //Если ошибка - подчеркнем
                if (stToken=tokErroneous)or(stToken=tokErroneous2)
                   then begin
                        ErrCol:=clRed;
                        if stToken=tokErroneous2
                           then ErrCol:=clGreen;
                        R.Left := TextIndent + CharPosToPixOffset(stStart, s, Sp);
                        R.Right := TextIndent + CharPosToPixOffset(stStart + stLength, s, Sp);
                        for i:=R.Left to R.Right do
                            case (i mod 4) of
                                 0,2: Pixels[i,R.Bottom-2]:=ErrCol;
                                 1: Pixels[i,R.Bottom-3]:=ErrCol;
                                 3: Pixels[i,R.Bottom-1]:=ErrCol;
                                 end;
                        end;
                CharPos := stStart + stLength;
            end;
    end;
end;

{Proposal support}

function TMPCustomSyntaxMemo.GetCurrentWord(PartOnly: boolean): string;
var
   i,XPos,YPos:integer;
   CurParser:TMPSyntaxParser;
begin
 Result:='';
 if Range.PosY<Lines.Count then
 begin
   XPos:=Range.PosX;
   YPos:=Range.PosY;
   CurParser:=Lines.Parser[YPos];
   for i:=CurParser.Count-1  downto 0 do
    if (XPos> CurParser[i].stStart)
     and  (XPos<= CurParser[i].stStart+CurParser[i].stLength)
    then
    begin
     if PartOnly then
      Result:=Copy(Lines[YPos],CurParser[i].stStart+1,XPos-CurParser[i].stStart )
     else
      Result:=Copy(Lines[YPos],CurParser[i].stStart+1,CurParser[i].stLength);
     Break
    end;

{   if not PartOnly then
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
   end}
 end;
end;

procedure TMPCustomSyntaxMemo.ReplaceCurrentWord(DestStr: string);
var
   i,XPos:integer;
   CurParser:TMPSyntaxParser;
   s:string;
   Success:boolean;
   NewPos:integer;
begin

// For Proposal
 NewPos:=Pos('|',DestStr);
 if NewPos>0 then
 begin
   Delete(DestStr,NewPos,1);
   NewPos:=Length(DestStr)-NewPos+1;

 end;

 if Range.PosY<Lines.Count then
 begin
   Success:=False;
   XPos:=Range.PosX;

   CurParser:=Lines.Parser[Range.PosY];
   if CurParser.Count=0 then
   begin
     Range.SetTextEx(DestStr,ukRangeInserted);
     Success:=True
   end
   else
   for i:=0  to CurParser.Count-1 do
    if (XPos>= CurParser[i].stStart) and
       (XPos<= CurParser[i].stStart+CurParser[i].stLength) then
   begin
     Success:=True;
     xPos:=CurParser[i].stStart;
     s:=Lines[Range.PosY];

     if not (CurParser[i].stToken in
        [ tokEndLine, tokParenBeg,    tokParenEnd     ,    tokBrackedBeg   ,    tokBracketEnd   ,    tokOperator ,tokComma,tokPoint   ]

     ) then
     begin
     //      Range.EndX  :=CurParser[i].stStart+CurParser[i].stLength
      Range.StartX:=CurParser[i].stStart;
      Range.EndX  :=Range.StartX+CurParser[i].stLength
     end
     else
     begin
//      Range.StartX:=Range.StartX+1;
      Range.EndX  :=Range.StartX;
     end;
     if CurParser[i].stToken = tokText then
     begin
      Range.SetTextEx('',ukRangeDeleted);
      Range.SetTextEx(DestStr,ukRangeInserted);
     end
     else
     begin
//      Range.PosX:=Range.PosX+1;
      Range.SetTextEx(DestStr,ukRangeInserted);
     end; 
     Break
    end
 end
 else
 if Range.PosY=0 then
 begin
   Success:=True;
   Range.SetTextEx(DestStr,ukRangeInserted);
 end;
 if not Success  then
 begin
     Range.SetTextEx(DestStr,ukRangeInserted);
 end;

 if NewPos>0 then
 begin
//   Range.PosX:=Range.PosX-NewPos
   Range.Enlarge(-NewPos);
   Range.EndX:=Range.StartX

 end;
end;

procedure TMPCustomSyntaxMemo.SetProposalItems(PI: TMPProposalItems);
begin
  FProposalForm.ChangeItems(PI);
end;

procedure       TMPCustomSyntaxMemo.ClearProposal;
var
   c:TMPProposalItems;
begin
  c[0]:=nil;
  c[1]:=nil;
  FProposalForm.ChangeItems(c)
end;

procedure       TMPCustomSyntaxMemo.AddToCurrentProposal(ts,ts1:TStrings);
begin
 FProposalForm.FItemList.AddStrings(ts);
 FProposalForm.FInsertList.AddStrings(ts1);
end;

procedure   TMPCustomSyntaxMemo.SaveProposals(const aName:string);
begin
   FProposalForm.SaveProposals(aName);
end;

procedure   TMPCustomSyntaxMemo.ApplyProposal(const aName:string);
begin
   FProposalForm.ApplyProposal(aName)
end;

procedure       TMPCustomSyntaxMemo.AddProposal(const aName:string);
begin
 FProposalForm.AddProposal(aName);
end;

function TMPCustomSyntaxMemo.GetCurProposalName: string;
begin
 Result:=FProposalForm.FCurProposalName
end;


{ TBookmarkManager }

// Конструктор
constructor TMPBookmarkManager.Create(Owner: TMPCustomSyntaxMemo);
begin
    inherited Create;
    fRichMemo := Owner;
    fImages := TBitmap.Create;
    fImages.LoadFromResourceName(HInstance, 'BOOKMARKS');
    Clear;
end;


// Деструктор
destructor TMPBookmarkManager.Destroy;
begin
    fImages.Free;
    inherited;
end;


// Сбрасывает информацию о закладках
procedure TMPBookmarkManager.Clear;
var i: TBookmarkIndex;
begin
    for i := Low(TBookmarkIndex) to High(TBookmarkIndex) do
        fBookMarks[i] := -1;
end;


// Возвращает
function TMPBookmarkManager.Find(const Row: Integer; var Index: TBookmarkIndex): Boolean;
var i: TBookmarkIndex;
begin
    for i := Low(TBookmarkIndex) to High(TBookmarkIndex) do
        if fBookMarks[i] = Row then begin
            Result := True;
            Index := i;
            Exit;
        end;
    Result := False;
end;


// Возвращает заклвдку
function TMPBookmarkManager.GetBookMarks(const Index: TBookmarkIndex): Integer;
begin
    Result := fBookMarks[Index];
end;


// Устанавливает закладку
procedure TMPBookmarkManager.SetBookMarks(const Index: TBookmarkIndex; const Row: Integer);
    {}
    procedure SetBookMarkInt;
    var i: TBookmarkIndex;
        n: Integer;
    begin
        // На этой строке могла быть другая закладка..
        if Find(Row, i) then begin
            fBookMarks[i] := -1;
            // ..или та же - в этом случае её просто удаляем
            if i = Index then
                Exit;
        end;
        // Эта закладка могла принадлежать другой странице
        if fBookMarks[Index] >= 0 then begin
            n := fBookMarks[Index];
            fBookMarks[Index] := -1;
            fRichMemo.NeedRedraw(n);
        end;
        // Новая закладка
        fBookMarks[Index] := Row;
    end;
begin
    fRichMemo.fLines.BeginUpdate;
    SetBookMarkInt;
    fRichMemo.NeedRedraw(Row);
    fRichMemo.fLines.EndUpdate;
end;


// Рисует пончик на гуттере
procedure TMPBookmarkManager.PaintAt(const ACanvas: TCanvas; const x, y: Integer; const Index: TBookmarkIndex);
const BOOKMARK_GLYPH_SIZE = 11;
begin
    BitBlt( ACanvas.Handle,
            x,
            y,
            BOOKMARK_GLYPH_SIZE,
            BOOKMARK_GLYPH_SIZE,
            fImages.Canvas.Handle,
            Index * BOOKMARK_GLYPH_SIZE,
            0,
            SRCCOPY );
end;



procedure  TMPCustomSyntaxMemo.CloseProposal;
begin
 fInProposalCall:=false;
 FTimer.Enabled:=False;
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
 if FProposalForm.FListProp.Items.Count=0 then
  CloseProposal;

 p:=TextPosToScreen(Range.PosX,Range.PosY );
 p:=ClientToScreen(p);
 Inc(p.y, fCharHeight);

 FTimer.Enabled:=True;
 FProposalForm.ShowEx(p.x,p.Y);


 fInProposalCall:=True
end;

{ TMPSyntaxCompletionProposalForm }

procedure TMPSyntaxCompletionProposalForm.ChangeItems(
  NewItems: TMPProposalItems);
begin
 FItemList.Clear;
 FInsertList.Clear;
 if NewItems[0]<>nil then
  FItemList.Assign(NewItems[0]);
 if NewItems[1]<>nil then
  FInsertList.Assign(NewItems[1]);
end;

const
  CharsAfterClause =[' ',#13,#9,#10,#0,';','(','/','-','"','^'];
  CharsBeforeClause=[' ',#10,')',#9,#13,'"'];
  endLexem=['+',')','(','*','/','|',',','=','>','<','-','!','^','~',',',';','.'];


procedure TMPSyntaxCompletionProposalForm.ChangeListText;
var
  i:integer;
  s:string;
begin
 with FListProp.Items do
 begin
  Clear;
  s:=  TMPCustomSyntaxMemo(Owner).GetCurrentWord(True);
  if (Length(s) >0) then
    if s[Length(s)] in (CharsAfterClause +endLexem+CharsBeforeClause-['"']) then
     s:='';
  for i:=0 to Pred(FInsertList.Count) do
   if i<FItemList.Count then
   if Copy(UpperCase(FInsertList[i]),1,Length(s))=UpperCase(s) then
     AddObject(FItemList[i],TObject(i));
  if Count=0  then
   TMPCustomSyntaxMemo(Owner).CloseProposal
  else
   FListProp.ItemIndex:=0
 end;
end;

//@@additional strings@
procedure TMPSyntaxCompletionProposalForm.CompleteProposal;
var
    i:integer;
    s,s1:string;
    p:integer;
begin
 s:='';
 with FListProp do
 begin
   for i:=0 to Pred(Items.Count) do
     if Selected[i] then
       s:=s+FInsertList[Integer(Items.Objects[i])]+',';
   if Length(s)>0 then
    SetLength(s,Length(s)-1);
 end;

 p:=Pos('@@',s);
 if p>0 then
 begin
   s1:=Copy(s,p+2,MaxInt);
   SetLength(s,p-1);
   SetLength(s1,Length(s1)-1);
   s:=s+s1
 end;
 TMPCustomSyntaxMemo(Owner).ReplaceCurrentWord(s);
 TMPCustomSyntaxMemo(Owner).CloseProposal
end;

constructor TMPSyntaxCompletionProposalForm.Create(AOwner: TComponent);
begin
  CreateNew(AOwner);
  FItemList := TStringList.Create;
  FInsertList := TStringList.Create;
  FProposalNames:= TStringList.Create;
  BorderStyle := bsNone;
  FormStyle:=fsStayOnTop;
  FListProp:=TListBox.Create(Self);
  FListProp.Parent:=Self;
  FListProp.Visible:=True;
  FListProp.Align:=alClient;
  FListProp.OnDblClick:=ListBoxClick;
  FListProp.OnKeyDown:=ListBoxKeyDown;

  FListProp.Style:=lbOwnerDrawFixed;

  FListProp.OnDrawItem:=ListDrawItem;
  FListProp.DoubleBuffered:=True;
//  FListProp.MultiSelect:=True;

  Left:=33;
  Top:=20;
  Width:=300;
  Height:=100;
end;

procedure TMPSyntaxCompletionProposalForm.Deactivate;
begin
  inherited;
//  Visible:=False
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
if FListProp.ItemIndex<FListProp.Items.Count then
  FListProp.ItemIndex := FListProp.ItemIndex+1;
end;

procedure TMPSyntaxCompletionProposalForm.ListBoxClick(Sender: TObject);
begin
 CompleteProposal
end;

procedure TMPSyntaxCompletionProposalForm.ListBoxKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
 case  Key of
  VK_RETURN:  CompleteProposal;
  VK_ESCAPE:
   begin
    Hide;
    TMPCustomSyntaxMemo(Owner).SetFocus
   end
 end;
end;

procedure TMPSyntaxCompletionProposalForm.PAGEDOWN;
var t:Integer;
begin
  SendMessage(FListProp.Handle,WM_VSCROLL, SB_PAGEDOWN,0);
  t := LoWord(FListProp.Perform(LB_ITEMFROMPOINT, 0, MakeLParam(0, FListProp.ClientHeight)));
  if t>=0 then
   FListProp.ItemIndex:=t
end;

procedure TMPSyntaxCompletionProposalForm.ListDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
var
	Offset: Integer;      { text offset width }
  s:string;
  s1:string;
  p:integer;
begin

	with (Control as TListBox).Canvas do  { draw on control canvas, not on the form }
	begin
   FillRect(Rect);       { clear the rectangle }
   Offset := 2;          { provide default offset }
   s:=(Control as TListBox).Items[Index];
   p:=Pos(ProposalDelimiter,s);
   s1:=Copy(s,1,p-2);
   if Length(S)<p+2 then Exit;
    case S[p+2] of
     'B': Font.Color:= clBlue;
     'D': Font.Color:= clGRAY;
     'F': Font.Color:= clFuchsia;
     'G': Font.Color:= clGreen;
     'M': Font.Color:= clMaroon;
     'N': Font.Color:= clNavy;
     'O': Font.Color:= clOlive;
     'R': Font.Color:= clRed;
     'T': Font.Color:= clTeal;
    end;
   if   odSelected in State then
   begin
     Font.Color:= clWhite;
//     Font.Style:=[fsBold];
   end;


   TextOut(Rect.Left + Offset, Rect.Top, s1);  { display the text }

   if   odSelected in State then
   begin
     Font.Color:= clWhite;
     Font.Style:=[fsBold] ;
   end
   else
   begin
    Font.Color:= clBlack;
    Font.Style:=[fsBold] ;
   end;

   s:=Copy(s,p+3,MaxInt);

   TextOut(Rect.Left + Offset+TextWidth(s1)+1, Rect.Top, s);  { display the text }

//   in
//	TextOut(Rect.Left + Offset, Rect.Top, (Control as TListBox).Items[Index])  { display the text }
	end;
end;

procedure TMPSyntaxCompletionProposalForm.PAGEUP;
var t:integer;
begin
  SendMessage(FListProp.Handle,WM_VSCROLL, SB_PAGEUP,0);

  t := FListProp.Perform(LB_GETTOPINDEX, 0, 0);
  if t>=0 then
   FListProp.ItemIndex:=t;
end;

procedure TMPSyntaxCompletionProposalForm.ShowEx(x, y: integer);
begin
 ChangeListText;
 if FListProp.Items.Count= 0 then
  Exit;
 FListProp.ItemIndex:=0; 
 Left:=x;
 Top:=y;
 FOwnerPos.X:=TMPCustomSyntaxMemo(Owner).ClientOrigin.X;
 FOwnerPos.Y:=TMPCustomSyntaxMemo(Owner).ClientOrigin.Y; 
 Show;
 TMPCustomSyntaxMemo(Owner).SetFocus
end;

procedure TMPCustomSyntaxMemo.DoOnTimer(Sender: TObject);
begin
 if (not Focused and not FProposalForm.FListProp.Focused and FProposalForm.Visible)
 or
  (FProposalForm.FOwnerPos.X<>ClientOrigin.X)  or
  (FProposalForm.FOwnerPos.Y<>ClientOrigin.Y)
 then
 begin
  FTimer.Enabled:=False;
  FProposalForm.Hide
 end;

end;


procedure TMPSyntaxCompletionProposalForm.ToEnd;
begin
if FListProp.Items.Count>0 then
  FListProp.ItemIndex:=FListProp.Items.Count-1
end;

procedure TMPSyntaxCompletionProposalForm.ToHome;
begin
if FListProp.Items.Count>0 then
  FListProp.ItemIndex:=0
end;

procedure TMPSyntaxCompletionProposalForm.Up;
begin
if FListProp.ItemIndex>0 then
  FListProp.ItemIndex := FListProp.ItemIndex-1;

end;



procedure TMPSyntaxCompletionProposalForm.ApplyProposal(
  const aName: string);
var
   i:integer;
begin
   i:=FProposalNames.IndexOf(aName);
   if i>-1 then
   begin
     FItemList.Text:=FItems[i];
     FInsertList.Text:=FInserts[i];
     FCurProposalName:=aName
   end;
end;

procedure TMPSyntaxCompletionProposalForm.SaveProposals(
  const aName: string);
var
   i:integer;
begin
   i:=FProposalNames.IndexOf(aName);
   if i<0 then
    i:=FProposalNames.Add(aName);

   if Length(FItems)<=i then
   begin
    SetLength(FItems,i+1);
    SetLength(FInserts,i+1);
   end;
   FItems[i]:=FItemList.Text;
   FInserts[i]:=FInsertList.Text;
   FCurProposalName:=aName
end;


procedure TMPSyntaxCompletionProposalForm.AddProposal(const aName: string);
var
   i:integer;
   ts:TStrings;
begin

   i:=FProposalNames.IndexOf(aName);
   if i>-1 then
   begin
     ts:=TStringList.Create;
     try
       ts.Text:=FItems[i];
       FItemList.AddStrings(ts);
       ts.Text:=FInserts[i];
       FInsertList.AddStrings(ts);
       FCurProposalName:=FCurProposalName+'+'+aName
     finally
      ts.Free
     end
   end;
end;

procedure TMPSyntaxCompletionProposalForm.DoHide;
begin
  inherited;
  if Owner is TMPSyntaxMemo then
    TMPSyntaxMemo(Owner).fInProposalCall:=False
end;

initialization
   CF_SYNTAX := RegisterClipboardFormat('MP_SYN_MEMO');
   DefUserTokenEventProc:=nil;
   DefProposal[0]:=TStringList.Create;
   DefProposal[1]:=TStringList.Create;
finalization
   DefProposal[0].Free;
   DefProposal[1].Free
end.


