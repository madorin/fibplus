unit ToCodeEditorIntfs;

interface
 uses Classes;
type
    IStringsToCodeEditor=interface
    ['{D0769087-C78F-49D3-807F-39F2B1720191}']
     function ICreatePropInCode(Component:TComponent;const PropName:string;PropValue:TStrings;
      aModified:boolean
     ):boolean;
    end;

var
   StringsToCodeEditor:IStringsToCodeEditor;

implementation

end.


