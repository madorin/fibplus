unit RegSynEditAlt;

interface
    uses Windows,Classes,pFIBSyntaxMemo,RegFIBPlusEditors;

    type
         TFIBSQLSyntaxEditor=class(TMPSyntaxMemo,IFIBSQLTextEditor)
         private
           function GetReadOnly:boolean;
           procedure SetReadOnly(Value:boolean);
           function  GetLines:TStrings;
           procedure SetLines(Value: TStrings);
           function GetSelStart: Integer;
           procedure SetSelStart(Value: Integer);
           function GetSelLength: Integer;
           procedure SetSelLength(Value: Integer);
           procedure SelectAll;
           function GetModified: Boolean;
           procedure SetModified(Value: Boolean);
           function  GetCaretX:integer;
           function  GetCaretY:integer;
           procedure iSetCaretPos(X,Y:integer);
           procedure  ISetProposalItems(ts1,ts2:TStrings);
           function        GetBeforePropCall:TiBeforeProposalCall;
           procedure       SetBeforePropCall(Event:TiBeforeProposalCall);

         end;



implementation
uses IBSQLSyn;
{ TFIBSQLSyntaxEditor }

function TFIBSQLSyntaxEditor.GetCaretX: integer;
begin
 Result:=Range.PosX
end;

function TFIBSQLSyntaxEditor.GetCaretY: integer;
begin
 Result:=Range.PosY
end;

function TFIBSQLSyntaxEditor.GetLines: TStrings;
begin
  Result:=Lines
end;

function TFIBSQLSyntaxEditor.GetModified: Boolean;
begin
 Result:=Lines.Modified
end;

function TFIBSQLSyntaxEditor.GetReadOnly: boolean;
begin
  Result:=smoReadOnly in Options
end;

function TFIBSQLSyntaxEditor.GetSelLength: Integer;
begin
 Result:=Range.SelLength
end;

function TFIBSQLSyntaxEditor.GetSelStart: Integer;
begin
 Result:=Range.Position
end;

procedure TFIBSQLSyntaxEditor.SelectAll;
begin
 Range.SelectAll
end;

procedure TFIBSQLSyntaxEditor.iSetCaretPos(X,Y:integer);
begin
 Range.Pos:=Point(X,Y)
end;

procedure TFIBSQLSyntaxEditor.SetLines(Value: TStrings);
begin
 Lines.Text:=Value.Text
end;

procedure TFIBSQLSyntaxEditor.SetModified(Value: Boolean);
begin
 Lines.Modified:=Value
end;

procedure TFIBSQLSyntaxEditor.SetReadOnly(Value: boolean);
begin
 if Value then
  Options:=Options+[smoReadOnly]
 else
  Options:=Options-[smoReadOnly]
end;

procedure TFIBSQLSyntaxEditor.SetSelLength(Value: Integer);
begin
 Range.SelLength:=Value
end;

procedure TFIBSQLSyntaxEditor.SetSelStart(Value: Integer);
begin
 Range.Position:=Value
end;

procedure TFIBSQLSyntaxEditor.ISetProposalItems(ts1, ts2: TStrings);
var
 PI:TMPProposalItems;
begin
  PI[0]:=ts1;
  PI[1]:=ts2;
  SetProposalItems(PI)
end;

function TFIBSQLSyntaxEditor.GetBeforePropCall: TiBeforeProposalCall;
begin
 Result:= BeforeProposalCall
end;

procedure TFIBSQLSyntaxEditor.SetBeforePropCall(
  Event: TiBeforeProposalCall);
begin
 BeforeProposalCall:=Event
end;

initialization
 RegisterFIBSQLTextEditor(TFIBSQLSyntaxEditor);
 RegisterSyntax
end.
