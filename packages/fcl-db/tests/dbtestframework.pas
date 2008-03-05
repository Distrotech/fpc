program dbtestframework;

{$IFDEF FPC}
  {$mode objfpc}{$H+}
{$ENDIF}

{ $DEFINE STOREDB}

{$APPTYPE CONSOLE}

uses
  SysUtils,
  fpcunit,  testreport, testregistry,
{$IFDEF STOREDB}
  DBResultsWriter,
{$ENDIF}
  toolsunit,
// Units wich contains the tests
  testbasics, testsqlfieldtypes, testdbbasics;
  
var
  FXMLResultsWriter: TXMLResultsWriter;
{$IFDEF STOREDB}
  FDBResultsWriter: TDBResultsWriter;
{$ENDIF}
  testResult: TTestResult;
begin
  testResult := TTestResult.Create;
  FXMLResultsWriter := TXMLResultsWriter.Create;
{$IFDEF STOREDB}
  FDBResultsWriter := TDBResultsWriter.Create;
{$ENDIF}
  try
    testResult.AddListener(FXMLResultsWriter);
{$IFDEF STOREDB}
    testResult.AddListener(FDBResultsWriter);
{$ENDIF}
    FDigestResultsWriter.Comment:=dbtype;
    FDigestResultsWriter.Category:='db';
    FDigestResultsWriter.RelSrcDir:='fcl-db';
    FXMLResultsWriter.WriteHeader;
{$IFDEF STOREDB}
    FDBResultsWriter.OpenConnection(dbconnectorname+';'+dbconnectorparams);
{$ENDIF}
    GetTestRegistry.Run(testResult);
    FXMLResultsWriter.WriteResult(testResult);
{$IFDEF STOREDB}
    FDBResultsWriter.CloseConnection;
{$ENDIF}
  finally
    testResult.Free;
    FXMLResultsWriter.Free;
{$IFDEF STOREDB}
    FDBResultsWriter.Free;
{$ENDIF}
  end;
end.
