{ %fail }
{ %norun }

{$ifdef fpc}
{$mode delphi}
{$endif}

type
  tc = class
    class procedure classmethod;
    procedure method;
    a : longint;
  end;

  ttc = class of tc;

class procedure tc.classmethod;
begin
end;

procedure tc.method;
begin
end;

var
  c: ttc;
begin
  c := tc;
  with c do
    a := 5;
end.
