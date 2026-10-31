unit ToCodeEditorIntfs;

interface

uses
  Classes;

type
  IFIBStringsToCodeEditor = interface
    ['{D0769087-C78F-49D3-807F-39F2B1720191}']
    function ICreatePropInCode(Component: TComponent; const PropName: string; PropValue: TStrings; aModified: Boolean): Boolean;
  end;

var
  StringsToCodeEditor: IFIBStringsToCodeEditor;

implementation

end.
