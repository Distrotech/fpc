{$ifndef ALLPACKAGES}
{$mode objfpc}{$H+}
program fpmake;

uses fpmkunit;

Var
  P : TPackage;
  T : TTarget;
begin
  With Installer do
    begin
{$endif ALLPACKAGES}
    P:=AddPackage('pxlib');
{$ifdef ALLPACKAGES}
    P.Directory:='pxlib';
{$endif ALLPACKAGES}
    P.OSes:=[Linux,beos,haiku,win32,freebsd,openbsd,netbsd];
    P.Version:='2.7.1';
    T:=P.Targets.AddUnit('src/pxlib.pp');
    T:=P.Targets.AddExampleunit('examples/ppxview.pp');
{$ifndef ALLPACKAGES}
    Run;
    end;
end.
{$endif ALLPACKAGES}
