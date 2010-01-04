unit WebPage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphtml, htmlelements, htmlwriter, HTTPDefs, fpweb, contnrs, dom;

type
  TRequestResponseEvent = procedure(Sender: TObject; ARequest: TRequest; AResponse: TResponse) of object;
  TRequestEvent = procedure(Sender: TObject; ARequest: TRequest) of object;
  THandleAjaxRequest = procedure(Sender: TObject; ARequest: TRequest; AResponse: TResponse; var handled: boolean) of object;

type
  IWebPageDesigner = interface(IUnknown)
    procedure Invalidate;
  end;

  { TStandardWebController }

  TStandardWebController = class(TWebController)
  private
    FScriptFileReferences: TStringList;
    FCurrentJavascriptStack: TJavaScriptStack;
    FScripts: TFPObjectList;
  protected
    function GetScriptFileReferences: TStringList; override;
    function GetScripts: TFPObjectList; override;
    function GetCurrentJavaScriptStack: TJavaScriptStack; override;
    procedure SetCurrentJavascriptStack(const AJavascriptStack: TJavaScriptStack);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function InitializeJavaScriptStack: TJavaScriptStack; override;
    function GetUrl(ParamNames, ParamValues, KeepParams: array of string; Action: string = ''): string; override;
    procedure FreeJavascriptStack; override;
    procedure BindJavascriptCallstackToElement(AnElement: THtmlCustomElement; AnEvent: string); override;
    procedure AddScriptFileReference(AScriptFile: String); override;
    function DefaultMessageBoxHandler(Sender: TObject; AText: String; Buttons: TWebButtons): string; override;
    function CreateNewScript: TStringList; override;
  end;

  { TWebPage }

  TWebPage = class(TDataModule, IHTMLContentProducerContainer)
  private
    FAfterAjaxRequest: TRequestResponseEvent;
    FBaseURL: string;
    FBeforeAjaxRequest: TRequestResponseEvent;
    FBeforeRequest: TRequestEvent;
    FBeforeShowPage: TRequestEvent;
    FDesigner: IWebPageDesigner;
    FOnAjaxRequest: THandleAjaxRequest;
    FRequest: TRequest;
    FWebController: TWebController;
    FWebModule: TFPWebModule;
    FContentProducers: TFPList; // list of THTMLContentProducer
    function GetContentProducer(Index: integer): THTMLContentProducer;
    function GetContentProducerList: TFPList;
    function GetContentProducers(Index: integer): THTMLContentProducer;
    function GetHasWebController: boolean;
    function GetWebController: TWebController;
  protected
    procedure DoBeforeAjaxRequest(ARequest: TRequest; AResponse: TResponse); virtual;
    procedure DoAfterAjaxRequest(ARequest: TRequest; AResponse: TResponse); virtual;
    procedure DoHandleAjaxRequest(ARequest: TRequest; AResponse: TResponse; var Handled: boolean); virtual;
    procedure DoBeforeRequest(ARequest: TRequest); virtual;
    procedure DoBeforeShowPage(ARequest: TRequest); virtual;
    property WebModule: TFPWebModule read FWebModule;
    procedure DoCleanupAfterRequest(const AContentProducer: THTMLContentProducer);
    procedure SetRequest(ARequest: TRequest); virtual;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    property ContentProducerList: TFPList read GetContentProducerList;
  public
    function ContentProducerCount: integer;

    function ProduceContent : string;
    procedure AddContentProducer(AContentProducer: THTMLContentProducer);
    procedure RemoveContentProducer(AContentProducer: THTMLContentProducer);
    function ExchangeContentProducers(Child1, Child2: THTMLContentProducer) : boolean;
    function MoveContentProducer(MoveElement, MoveBeforeElement: THTMLContentProducer) : boolean;
    procedure ForeachContentProducer(AForeachChildsProc: TForeachContentProducerProc; Recursive: boolean);

    procedure HandlePage(ARequest: TRequest; AResponse: TResponse; AWriter: THTMLwriter; AWebModule: TFPWebModule = nil); virtual;
    procedure DoBeforeGenerateXML; virtual;
    property Designer: IWebPageDesigner read FDesigner write FDesigner;
    property Request: TRequest read FRequest;
    property ContentProducers[Index: integer]: THTMLContentProducer read GetContentProducer;
    property HasWebController: boolean read GetHasWebController;
    property WebController: TWebController read GetWebController write FWebController;
  published
    property BeforeRequest: TRequestEvent read FBeforeRequest write FBeforeRequest;
    property BeforeShowPage: TRequestEvent read FBeforeShowPage write FBeforeShowPage;
    property BeforeAjaxRequest: TRequestResponseEvent read FBeforeAjaxRequest write FBeforeAjaxRequest;
    property AfterAjaxRequest: TRequestResponseEvent read FAfterAjaxRequest write FAfterAjaxRequest;
    property OnAjaxRequest: THandleAjaxRequest read FOnAjaxRequest write FOnAjaxRequest;
    property BaseURL: string read FBaseURL write FBaseURL;
  end;

implementation

uses rtlconsts, typinfo, XMLWrite;

{ TWebPage }

function TWebPage.ProduceContent: string;
var i : integer;
begin
  result := '';
  for i := 0 to ContentProducerCount-1 do
    result := result + THTMLContentProducer(ContentProducers[i]).ProduceContent;
end;

procedure TWebPage.AddContentProducer(AContentProducer: THTMLContentProducer);
begin
  ContentProducerList.Add(AContentProducer);
end;

procedure TWebPage.RemoveContentProducer(AContentProducer: THTMLContentProducer);
begin
  ContentProducerList.Remove(AContentProducer);
end;

function TWebPage.ExchangeContentProducers(Child1, Child2: THTMLContentProducer): boolean;
var ChildIndex1, ChildIndex2: integer;
begin
  result := false;
  ChildIndex1:=GetContentProducerList.IndexOf(Child1);
  if (ChildIndex1=-1) then
    Exit;
  ChildIndex2:=GetContentProducerList.IndexOf(Child2);
  if (ChildIndex2=-1) then
    Exit;
  GetContentProducerList.Exchange(ChildIndex1,ChildIndex2);
  result := true;
end;

function TWebPage.MoveContentProducer(MoveElement, MoveBeforeElement: THTMLContentProducer): boolean;
var ChildIndex1, ChildIndex2: integer;
begin
  result := false;
  ChildIndex1:=GetContentProducerList.IndexOf(MoveElement);
  if (ChildIndex1=-1) then
    Exit;
  ChildIndex2:=GetContentProducerList.IndexOf(MoveBeforeElement);
  if (ChildIndex2=-1) then
    Exit;
  GetContentProducerList.Move(ChildIndex1,ChildIndex2);
  result := true;
end;

procedure TWebPage.ForeachContentProducer(AForeachChildsProc: TForeachContentProducerProc; Recursive: boolean);
var i : integer;
    tmpChild: THTMLContentProducer;
begin
  for i := 0 to ContentProducerCount -1 do
    begin
    tmpChild := ContentProducers[i];
    AForeachChildsProc(tmpChild);
    if recursive then
      tmpChild.ForeachContentProducer(AForeachChildsProc,Recursive);
    end;
end;

procedure TWebPage.HandlePage(ARequest: TRequest; AResponse: TResponse; AWriter: THTMLwriter; AWebModule: TFPWebModule=nil);
var s : string;
    Handled: boolean;
    CompName: string;
    AComponent: TComponent;
    AnAjaxResponse: TAjaxResponse;
begin
  SetRequest(ARequest);
  FWebModule := AWebModule;
  try
    try
      DoBeforeRequest(ARequest);
      s := Request.HTTPXRequestedWith;
      if sametext(s,'XmlHttpRequest') then
        begin
        AnAjaxResponse := TAjaxResponse.Create(GetWebController, AResponse);
        try
          DoBeforeAjaxRequest(ARequest, AResponse);
          if HasWebController then
            WebController.InitializeAjaxRequest;
          Handled := false;
          DoHandleAjaxRequest(ARequest, AResponse, Handled);
          if not Handled then
            begin
            CompName := Request.QueryFields.Values['AjaxID'];
            if CompName='' then CompName := Request.GetNextPathInfo;
            AComponent := FindComponent(CompName);
            if assigned(AComponent) and (AComponent is THTMLContentProducer) then
              THTMLContentProducer(AComponent).HandleAjaxRequest(ARequest, AnAjaxResponse);
            end;
          DoAfterAjaxRequest(ARequest, AResponse);
          AnAjaxResponse.BindToResponse;
        finally
          AnAjaxResponse.Free;
        end;
        end
      else
        begin
        if HasWebController then
          WebController.InitializeShowRequest;
        DoBeforeShowPage(ARequest);
        AResponse.Content := ProduceContent;
        end;
    finally
      ForeachContentProducer(@DoCleanupAfterRequest, True);
    end;
  finally
    SetRequest(nil);
    AWebModule := nil;
  end;
end;

procedure TWebPage.DoBeforeGenerateXML;
begin
  // Do Nothing
end;

procedure TWebPage.DoCleanupAfterRequest(const AContentProducer: THTMLContentProducer);
begin
  AContentProducer.CleanupInstance;
end;

procedure TWebPage.SetRequest(ARequest: TRequest);
begin
  FRequest := ARequest;
end;

procedure TWebPage.GetChildren(Proc: TGetChildProc; Root: TComponent);
var i : integer;
begin
  inherited GetChildren(Proc, Root);
  if (Root=Self) then
    for I:=0 to ContentProducerCount-1 do
      Proc(ContentProducers[i]);
end;

function TWebPage.ContentProducerCount: integer;
begin
  if assigned(FContentProducers) then
    result := FContentProducers.Count
  else
    result := 0;
end;

function TWebPage.GetContentProducers(Index: integer): THTMLContentProducer;
begin
  Result:=THTMLContentProducer(ContentProducerList[Index]);
end;

function TWebPage.GetHasWebController: boolean;
begin
  result := assigned(FWebController);
end;

function TWebPage.GetWebController: TWebController;
begin
  if not assigned(FWebController) then
    raise exception.create('No webcontroller available');
  result := FWebController;
end;

function TWebPage.GetContentProducerList: TFPList;
begin
  if not assigned(FContentProducers) then
    FContentProducers := tfplist.Create;
  Result := FContentProducers;
end;

function TWebPage.GetContentProducer(Index: integer): THTMLContentProducer;
begin
  Result := THTMLContentProducer(ContentProducerList[Index]);
end;

procedure TWebPage.DoBeforeAjaxRequest(ARequest: TRequest; AResponse: TResponse);
begin
  if assigned(BeforeAjaxRequest) then
    BeforeAjaxRequest(Self,ARequest,AResponse);
end;

procedure TWebPage.DoAfterAjaxRequest(ARequest: TRequest; AResponse: TResponse);
begin
  if assigned(AfterAjaxRequest) then
    AfterAjaxRequest(Self,ARequest,AResponse);
end;

procedure TWebPage.DoHandleAjaxRequest(ARequest: TRequest; AResponse: TResponse; var Handled: boolean);
begin
  if assigned(OnAjaxRequest) then
    OnAjaxRequest(Self,ARequest,AResponse, Handled);
end;

procedure TWebPage.DoBeforeRequest(ARequest: TRequest);
begin
  if assigned(BeforeRequest) then
    BeforeRequest(Self,ARequest);
end;

procedure TWebPage.DoBeforeShowPage(ARequest: TRequest);
begin
  if assigned(BeforeShowPage) then
    BeforeShowPage(Self,ARequest);
end;

{ TStandardWebController }

function TStandardWebController.GetScriptFileReferences: TStringList;
begin
  Result:=FScriptFileReferences;
end;

function TStandardWebController.GetScripts: TFPObjectList;
begin
  if not assigned(FScripts) then
    begin
    FScripts:=TFPObjectList.Create;
    FScripts.OwnsObjects:=true;
    end;
  Result:=FScripts;
end;

function TStandardWebController.GetCurrentJavaScriptStack: TJavaScriptStack;
begin
  Result:=FCurrentJavascriptStack;
end;

procedure TStandardWebController.SetCurrentJavascriptStack(const AJavascriptStack: TJavaScriptStack);
begin
  FCurrentJavascriptStack := AJavascriptStack;
end;

function TStandardWebController.CreateNewScript: TStringList;
begin
  Result:=TStringList.Create;
  GetScripts.Add(result);
end;

function TStandardWebController.DefaultMessageBoxHandler(Sender: TObject;
  AText: String; Buttons: TWebButtons): string;
var i : integer;
    HasCancel: boolean;
    HasOk: boolean;
    OnOk: string;
    OnCancel: string;
begin
  HasCancel:=false;
  HasOk:=false;
  OnOk:='';
  OnCancel:='';
  for i := low(Buttons) to High(Buttons) do
    begin
    if Buttons[i].ButtonType=btOk then
      begin
      HasOk := True;
      OnOk := Buttons[i].OnClick;
      end;
    if Buttons[i].ButtonType=btCancel then
      begin
      HasCancel := True;
      OnCancel := Buttons[i].OnClick;
      end;
    end;

  if HasCancel then
    result := 'if (confirm('''+AText+''')==true) {'+OnOk+'} else {'+OnCancel+'}'
  else
    result := 'alert('''+AText+''');'+OnOk;
end;

constructor TStandardWebController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FScriptFileReferences := TStringList.Create;
  FScriptFileReferences.Sorted:=true;
  FScriptFileReferences.Duplicates:=dupIgnore;
end;

destructor TStandardWebController.Destroy;
begin
  FScriptFileReferences.Free;
  FScripts.Free;
  inherited Destroy;
end;

function TStandardWebController.InitializeJavaScriptStack: TJavaScriptStack;
begin
  if assigned(FCurrentJavascriptStack) then
    raise exception.Create('There is still an old JavascriptStack available');
  FCurrentJavascriptStack := TJavaScriptStack.Create(self);
  Result:=FCurrentJavascriptStack;
end;

function TStandardWebController.GetUrl(ParamNames, ParamValues,
  KeepParams: array of string; Action: string): string;

var qs,p : String;
    i,j  : integer;
    found: boolean;
    FancyTitle: boolean;
    CGIScriptName: string;
    ActionVar: string;
    ARequest: TRequest;

begin
  FancyTitle:=false;
  qs := '';
  result := Action;
  ARequest := GetRequest;
  if assigned(owner) and (owner is TWebPage) and assigned(TWebPage(Owner).WebModule) then
    begin
    ActionVar := TWebPage(Owner).WebModule.ActionVar;
    if action = '' then
      result := TWebPage(Owner).WebModule.Actions.CurrentAction.Name;
    end
  else
    ActionVar := '';
  if ActionVar='' then FancyTitle:=true;
  if Assigned(ARequest) then
    begin
    if  (high(KeepParams)>=0) and (KeepParams[0]='*') then
      begin
      for i := 0 to ARequest.QueryFields.Count-1 do
        begin
        p := ARequest.QueryFields.Names[i];
        found := False;
        for j := 0 to high(ParamNames) do if sametext(ParamNames[j],p) then
          begin
          found := True;
          break;
          end;
        if not FancyTitle and SameText(ActionVar,p) then
          found := true;
        if not found then
          qs := qs + p + '=' + ARequest.QueryFields.ValueFromIndex[i] + '&';
        end;
      end
    else for i := 0 to high(KeepParams) do
      begin
      p := ARequest.QueryFields.Values[KeepParams[i]];
      if p <> '' then
        qs := qs + KeepParams[i] + '=' + p + '&';
      end;
    end;
  for i := 0 to high(ParamNames) do
    qs := qs + ParamNames[i] + '=' + ParamValues[i] + '&';

  if ScriptName='' then CGIScriptName:='.'
  else CGIScriptName:=ScriptName;
  if FancyTitle then // use ? or /
    result := CGIScriptName + '/' + Result
  else
    result := CGIScriptName + '?'+ActionVar+'=' + Result;

  p := copy(qs,1,length(qs)-1);
  if p <> '' then
    begin
    if FancyTitle then
      result := result + '?' + p
    else
      result := result + '&' + p;
    end
end;

procedure TStandardWebController.FreeJavascriptStack;
begin
  FreeAndNil(FCurrentJavascriptStack);
end;

procedure TStandardWebController.BindJavascriptCallstackToElement(AnElement: THtmlCustomElement; AnEvent: string);
begin
  case AnEvent of
    'onclick' : (AnElement as THTMLAttrsElement).onclick:=CurrentJavaScriptStack.GetScript;
    'onchange' : if AnElement is THTML_input then (AnElement as THTML_input).onchange:=CurrentJavaScriptStack.GetScript;
  end; {case}
end;

procedure TStandardWebController.AddScriptFileReference(AScriptFile: String);
begin
  FScriptFileReferences.Add(AScriptFile);
end;

end.

