{ %target=darwin }
{ %cpu=powerpc,powerpc64,i386,x86_64,arm }
{ %norun }

{$mode objfpc}
{$modeswitch objectivec1}

uses
  ctypes;

var
  a: NSObjectProtocol;
  b: NSObject;
begin
  a:=b;
end.
