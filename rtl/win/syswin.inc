{
    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2008 by Florian Klaempfl and Pavel Ozerski
    member of the Free Pascal development team.

    FPC Pascal system unit part shared by win32/win64.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{
  Error code definitions for the Win32 API functions


  Values are 32 bit values layed out as follows:
   3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1
   1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
  +---+-+-+-----------------------+-------------------------------+
  |Sev|C|R|     Facility          |               Code            |
  +---+-+-+-----------------------+-------------------------------+

  where
      Sev - is the severity code
          00 - Success
          01 - Informational
          10 - Warning
          11 - Error

      C - is the Customer code flag
      R - is a reserved bit
      Facility - is the facility code
      Code - is the facility's status code
}

const
  SEVERITY_SUCCESS                        = $00000000;
  SEVERITY_INFORMATIONAL                  = $40000000;
  SEVERITY_WARNING                        = $80000000;
  SEVERITY_ERROR                          = $C0000000;

const
  STATUS_SEGMENT_NOTIFICATION             = $40000005;
  DBG_TERMINATE_THREAD                    = $40010003;
  DBG_TERMINATE_PROCESS                   = $40010004;
  DBG_CONTROL_C                           = $40010005;
  DBG_CONTROL_BREAK                       = $40010008;

  STATUS_GUARD_PAGE_VIOLATION             = $80000001;
  STATUS_DATATYPE_MISALIGNMENT            = $80000002;
  STATUS_BREAKPOINT                       = $80000003;
  STATUS_SINGLE_STEP                      = $80000004;
  DBG_EXCEPTION_NOT_HANDLED               = $80010001;

  STATUS_ACCESS_VIOLATION                 = $C0000005;
  STATUS_IN_PAGE_ERROR                    = $C0000006;
  STATUS_INVALID_HANDLE                   = $C0000008;
  STATUS_NO_MEMORY                        = $C0000017;
  STATUS_ILLEGAL_INSTRUCTION              = $C000001D;
  STATUS_NONCONTINUABLE_EXCEPTION         = $C0000025;
  STATUS_INVALID_DISPOSITION              = $C0000026;
  STATUS_ARRAY_BOUNDS_EXCEEDED            = $C000008C;
  STATUS_FLOAT_DENORMAL_OPERAND           = $C000008D;
  STATUS_FLOAT_DIVIDE_BY_ZERO             = $C000008E;
  STATUS_FLOAT_INEXACT_RESULT             = $C000008F;
  STATUS_FLOAT_INVALID_OPERATION          = $C0000090;
  STATUS_FLOAT_OVERFLOW                   = $C0000091;
  STATUS_FLOAT_STACK_CHECK                = $C0000092;
  STATUS_FLOAT_UNDERFLOW                  = $C0000093;
  STATUS_INTEGER_DIVIDE_BY_ZERO           = $C0000094;
  STATUS_INTEGER_OVERFLOW                 = $C0000095;
  STATUS_PRIVILEGED_INSTRUCTION           = $C0000096;
  STATUS_STACK_OVERFLOW                   = $C00000FD;
  STATUS_CONTROL_C_EXIT                   = $C000013A;
  STATUS_FLOAT_MULTIPLE_FAULTS            = $C00002B4;
  STATUS_FLOAT_MULTIPLE_TRAPS             = $C00002B5;
  STATUS_REG_NAT_CONSUMPTION              = $C00002C9;

  EXCEPTION_EXECUTE_HANDLER               = 1;
  EXCEPTION_CONTINUE_EXECUTION            = -1;
  EXCEPTION_CONTINUE_SEARCH               = 0;

  CONTEXT_X86                             = $00010000;
  CONTEXT_CONTROL                         = CONTEXT_X86 or $00000001;
  CONTEXT_INTEGER                         = CONTEXT_X86 or $00000002;
  CONTEXT_SEGMENTS                        = CONTEXT_X86 or $00000004;
  CONTEXT_FLOATING_POINT                  = CONTEXT_X86 or $00000008;
  CONTEXT_DEBUG_REGISTERS                 = CONTEXT_X86 or $00000010;
  CONTEXT_EXTENDED_REGISTERS              = CONTEXT_X86 or $00000020;

  CONTEXT_FULL                            = CONTEXT_CONTROL or CONTEXT_INTEGER or CONTEXT_SEGMENTS;

  MAXIMUM_SUPPORTED_EXTENSION             = 512;

  {*****************************************************************************
                                Parameter Handling
  *****************************************************************************}

  procedure setup_arguments;
  var
    arglen,
    count   : longint;
    argstart,
    pc,arg  : pchar;
    quote   : Boolean;
    argvlen : longint;
    buf: array[0..259] of char;  // need MAX_PATH bytes, not 256!

    procedure allocarg(idx,len:longint);
      var
        oldargvlen : longint;
      begin
        if idx>=argvlen then
         begin
           oldargvlen:=argvlen;
           argvlen:=(idx+8) and (not 7);
           sysreallocmem(argv,argvlen*sizeof(pointer));
           fillchar(argv[oldargvlen],(argvlen-oldargvlen)*sizeof(pointer),0);
         end;
        { use realloc to reuse already existing memory }
        { always allocate, even if length is zero, since }
        { the arg. is still present!                     }
        sysreallocmem(argv[idx],len+1);
      end;

  begin
    { create commandline, it starts with the executed filename which is argv[0] }
    { Win32 passes the command NOT via the args, but via getmodulefilename}
    count:=0;
    argv:=nil;
    argvlen:=0;
    ArgLen := GetModuleFileName(0, @buf[0], sizeof(buf));
    buf[ArgLen] := #0; // be safe
    allocarg(0,arglen);
    move(buf,argv[0]^,arglen+1);
    { Setup cmdline variable }
    cmdline:=GetCommandLine;
    { process arguments }
    pc:=cmdline;
  {$IfDef SYSTEM_DEBUG_STARTUP}
    Writeln(stderr,'Win32 GetCommandLine is #',pc,'#');
  {$EndIf }
    while pc^<>#0 do
     begin
       { skip leading spaces }
       while pc^ in [#1..#32] do
        inc(pc);
       if pc^=#0 then
        break;
       { calc argument length }
       quote:=False;
       argstart:=pc;
       arglen:=0;
       while (pc^<>#0) do
        begin
          case pc^ of
            #1..#32 :
              begin
                if quote then
                 inc(arglen)
                else
                 break;
              end;
            '"' :
              if pc[1]<>'"' then
                quote := not quote
                else
                inc(pc);
            else
              inc(arglen);
          end;
          inc(pc);
        end;
       { copy argument }
       { Don't copy the first one, it is already there.}
       If Count<>0 then
        begin
          allocarg(count,arglen);
          quote:=False;
          pc:=argstart;
          arg:=argv[count];
          while (pc^<>#0) do
           begin
             case pc^ of
               #1..#32 :
                 begin
                   if quote then
                    begin
                      arg^:=pc^;
                      inc(arg);
                    end
                   else
                    break;
                 end;
               '"' :
                 if pc[1]<>'"' then
                   quote := not quote
                    else
                  inc(pc);
               else
                 begin
                   arg^:=pc^;
                   inc(arg);
                 end;
             end;
             inc(pc);
           end;
          arg^:=#0;
        end;
   {$IfDef SYSTEM_DEBUG_STARTUP}
       Writeln(stderr,'dos arg ',count,' #',arglen,'#',argv[count],'#');
   {$EndIf SYSTEM_DEBUG_STARTUP}
       inc(count);
     end;
    { get argc }
    argc:=count;
    { free unused memory, leaving a nil entry at the end }
    sysreallocmem(argv,(count+1)*sizeof(pointer));
    argv[count] := nil;
  end;


  function paramcount : longint;
  begin
    paramcount := argc - 1;
  end;

  function paramstr(l : longint) : string;
  begin
    if (l>=0) and (l<argc) then
      paramstr:=strpas(argv[l])
    else
      paramstr:='';
  end;


  procedure randomize;
  begin
    randseed:=GetTickCount;
  end;




Var
  DLLInitState : Longint = -1;
  DLLBuf : Jmp_buf;

function Dll_entry{$ifdef FPC_HAS_INDIRECT_MAIN_INFORMATION}(const info : TEntryInformation){$endif FPC_HAS_INDIRECT_MAIN_INFORMATION} : longbool; [public,alias:'_FPC_DLL_Entry'];
  begin
{$ifdef FPC_HAS_INDIRECT_MAIN_INFORMATION}
     EntryInformation:=info;
{$endif FPC_HAS_INDIRECT_MAIN_INFORMATION}
     IsLibrary:=true;
     DllInitState:=DLLreason;
     Dll_entry:=false;  { return value is ignored, except when DLLreason=DLL_PROCESS_ATTACH }
     case DLLreason of
       DLL_PROCESS_ATTACH :
         begin
           MainThreadIdWin32 := Win32GetCurrentThreadId;

           If SetJmp(DLLBuf) = 0 then
             begin
{$ifdef FPC_HAS_INDIRECT_MAIN_INFORMATION}
               EntryInformation.PascalMain();
{$else FPC_HAS_INDIRECT_MAIN_INFORMATION}
               PascalMain;
{$endif FPC_HAS_INDIRECT_MAIN_INFORMATION}
               Dll_entry:=true;
             end
           else
             Dll_entry:=(ExitCode=0);
         end;
       DLL_THREAD_ATTACH :
         begin
           { SysInitMultithreading must not be called here,
             see comments in exec_tls_callback below }
           { Allocate Threadvars  }
           SysAllocateThreadVars;

           { NS : no idea what is correct to pass here - pass dummy value for now }
           { passing a dummy is ok, the correct value is read from the coff header of SysInstance (FK) }
           InitThread($1000000); { Assume everything is idempotent there, as the thread could have been created with BeginThread... }

           if assigned(Dll_Thread_Attach_Hook) then
             Dll_Thread_Attach_Hook(DllParam);
        end;
       DLL_THREAD_DETACH :
         begin
           if assigned(Dll_Thread_Detach_Hook) then
             Dll_Thread_Detach_Hook(DllParam);
           { Release Threadvars }
           if TlsGetValue(TLSKey)<>nil then
             DoneThread; { Assume everything is idempotent there }
         end;
       DLL_PROCESS_DETACH :
         begin
           if MainThreadIDWin32=0 then // already been here.
             exit;
           If SetJmp(DLLBuf) = 0 then
             begin
               if assigned(Dll_Process_Detach_Hook) then
                 Dll_Process_Detach_Hook(DllParam);
               InternalExit;
             end;

           SysReleaseThreadVars;
           { Free TLS resources used by ThreadVars }
           SysFiniMultiThreading;
           MainThreadIDWin32:=0;
         end;
     end;
     DllInitState:=-1;
  end;


{****************************************************************************
                    Error Message writing using messageboxes
****************************************************************************}

function MessageBox(w1:longint;l1,l2:pointer;w2:longint):longint;
   stdcall;external 'user32' name 'MessageBoxA';

const
  ErrorBufferLength = 1024;
var
  ErrorBuf : array[0..ErrorBufferLength] of char;
  ErrorLen : SizeInt;

Function ErrorWrite(Var F: TextRec): Integer;
{
  An error message should always end with #13#10#13#10
}
var
  i : SizeInt;
Begin
  while F.BufPos>0 do
    begin
      begin
        if F.BufPos+ErrorLen>ErrorBufferLength then
          i:=ErrorBufferLength-ErrorLen
        else
          i:=F.BufPos;
        Move(F.BufPtr^,ErrorBuf[ErrorLen],i);
        inc(ErrorLen,i);
        ErrorBuf[ErrorLen]:=#0;
      end;
      if ErrorLen=ErrorBufferLength then
        begin
          MessageBox(0,@ErrorBuf,pchar('Error'),0);
          ErrorLen:=0;
        end;
      Dec(F.BufPos,i);
    end;
  ErrorWrite:=0;
End;


Function ErrorClose(Var F: TextRec): Integer;
begin
  if ErrorLen>0 then
   begin
     MessageBox(0,@ErrorBuf,pchar('Error'),0);
     ErrorLen:=0;
   end;
  ErrorLen:=0;
  ErrorClose:=0;
end;


Function ErrorOpen(Var F: TextRec): Integer;
Begin
  TextRec(F).InOutFunc:=@ErrorWrite;
  TextRec(F).FlushFunc:=@ErrorWrite;
  TextRec(F).CloseFunc:=@ErrorClose;
  ErrorLen:=0;
  ErrorOpen:=0;
End;


procedure AssignError(Var T: Text);
begin
  Assign(T,'');
  TextRec(T).OpenFunc:=@ErrorOpen;
  Rewrite(T);
end;


procedure SysInitStdIO;
begin
  { Setup stdin, stdout and stderr, for GUI apps redirect stderr,stdout to be
    displayed in a messagebox }
  StdInputHandle:=longint(GetStdHandle(cardinal(STD_INPUT_HANDLE)));
  StdOutputHandle:=longint(GetStdHandle(cardinal(STD_OUTPUT_HANDLE)));
  StdErrorHandle:=longint(GetStdHandle(cardinal(STD_ERROR_HANDLE)));
  if not IsConsole then
   begin
     AssignError(stderr);
     AssignError(StdOut);
     Assign(Output,'');
     Assign(Input,'');
     Assign(ErrOutput,'');
   end
  else
   begin
     OpenStdIO(Input,fmInput,StdInputHandle);
     OpenStdIO(Output,fmOutput,StdOutputHandle);
     OpenStdIO(ErrOutput,fmOutput,StdErrorHandle);
     OpenStdIO(StdOut,fmOutput,StdOutputHandle);
     OpenStdIO(StdErr,fmOutput,StdErrorHandle);
   end;
end;

{ ProcessID cached to avoid repeated calls to GetCurrentProcess. }

var
  ProcessID: SizeUInt;

function GetProcessID: SizeUInt;
  begin
    GetProcessID := ProcessID;
  end;


{******************************************************************************
                              Unicode
 ******************************************************************************}
const
  { MultiByteToWideChar  }
  MB_PRECOMPOSED = 1;
  WC_NO_BEST_FIT_CHARS = $400;

function MultiByteToWideChar(CodePage:UINT; dwFlags:DWORD; lpMultiByteStr:PChar; cchMultiByte:longint; lpWideCharStr:PWideChar;cchWideChar:longint):longint;
    stdcall; external 'kernel32' name 'MultiByteToWideChar';
function WideCharToMultiByte(CodePage:UINT; dwFlags:DWORD; lpWideCharStr:PWideChar; cchWideChar:longint; lpMultiByteStr:PChar;cchMultiByte:longint; lpDefaultChar:PChar; lpUsedDefaultChar:pointer):longint;
    stdcall; external 'kernel32' name 'WideCharToMultiByte';
function CharUpperBuff(lpsz:LPWSTR; cchLength:DWORD):DWORD;
    stdcall; external 'user32' name 'CharUpperBuffW';
function CharLowerBuff(lpsz:LPWSTR; cchLength:DWORD):DWORD;
    stdcall; external 'user32' name 'CharLowerBuffW';

procedure Win32Unicode2AnsiMove(source:punicodechar;var dest:RawByteString;cp : TSystemCodePage;len:SizeInt);
  var
    destlen: SizeInt;
  begin
    // retrieve length including trailing #0
    // not anymore, because this must also be usable for single characters
    destlen:=WideCharToMultiByte(cp, 0, source, len, nil, 0, nil, nil);
    // this will null-terminate
    setlength(dest, destlen);
    if destlen>0 then
      begin
        WideCharToMultiByte(cp, 0, source, len, @dest[1], destlen, nil, nil);
        PAnsiRec(pointer(dest)-AnsiFirstOff)^.CodePage:=cp;
      end;
  end;

procedure Win32Ansi2UnicodeMove(source:pchar;cp : TSystemCodePage;var dest:UnicodeString;len:SizeInt);
  var
    destlen: SizeInt;
    dwflags: DWORD;
  begin
    // retrieve length including trailing #0
    // not anymore, because this must also be usable for single characters
    if cp=CP_UTF8 then
      dwFlags:=0
    else
      dwFlags:=MB_PRECOMPOSED;
    destlen:=MultiByteToWideChar(cp, dwFlags, source, len, nil, 0);
    // this will null-terminate
    setlength(dest, destlen);
    if destlen>0 then
      begin
        MultiByteToWideChar(cp, dwFlags, source, len, @dest[1], destlen);
        PUnicodeRec(pointer(dest)-UnicodeFirstOff)^.CodePage:=CP_UTF16;
      end;
  end;


function Win32UnicodeUpper(const s : UnicodeString) : UnicodeString;
  begin
    result:=s;
    UniqueString(result);
    if length(result)>0 then
      CharUpperBuff(LPWSTR(result),length(result));
  end;


function Win32UnicodeLower(const s : UnicodeString) : UnicodeString;
  begin
    result:=s;
    UniqueString(result);
    if length(result)>0 then
      CharLowerBuff(LPWSTR(result),length(result));
  end;

{******************************************************************************
                              Widestring
 ******************************************************************************}

procedure Win32Ansi2WideMove(source:pchar;cp : TSystemCodePage;var dest:widestring;len:SizeInt);
  var
    destlen: SizeInt;
    dwFlags: DWORD;
  begin
    // retrieve length including trailing #0
    // not anymore, because this must also be usable for single characters
    if cp=CP_UTF8 then
      dwFlags:=0
    else
      dwFlags:=MB_PRECOMPOSED;
    destlen:=MultiByteToWideChar(cp, dwFlags, source, len, nil, 0);
    // this will null-terminate
    setlength(dest, destlen);
    if destlen>0 then
      MultiByteToWideChar(cp, dwFlags, source, len, @dest[1], destlen);
  end;


function Win32WideUpper(const s : WideString) : WideString;
  begin
    result:=s;
    if length(result)>0 then
      CharUpperBuff(LPWSTR(result),length(result));
  end;


function Win32WideLower(const s : WideString) : WideString;
  begin
    result:=s;
    if length(result)>0 then
      CharLowerBuff(LPWSTR(result),length(result));
  end;

type
  PWStrInitEntry = ^TWStrInitEntry;
  TWStrInitEntry = record
    addr: PPointer;
    data: Pointer;
  end;

  PWStrInitTablesTable = ^TWStrInitTablesTable;
  TWStrInitTablesTable = packed record
    count  : longint;
    tables : packed array [1..32767] of PWStrInitEntry;
  end;

{$if not(defined(VER2_2) or defined(VER2_4))}
var
  WStrInitTablesTable: TWStrInitTablesTable; external name 'FPC_WIDEINITTABLES';
{$endif}

function GetACP:UINT; stdcall; external 'kernel32' name 'GetACP';
function GetConsoleCP:UINT; stdcall; external 'kernel32' name 'GetConsoleCP';

function Win32GetStandardCodePage(const stdcp: TStandardCodePageEnum): TSystemCodePage;
  begin
    case stdcp of
      scpAnsi,
      scpFileSystemSingleByte: Result := GetACP;
      scpConsoleInput: Result := GetConsoleCP;
      scpConsoleOutput: Result := GetConsoleOutputCP;
    end;
  end;

{ there is a similiar procedure in sysutils which inits the fields which
  are only relevant for the sysutils units }
procedure InitWin32Widestrings;
  var
    i: longint;
    ptable: PWStrInitEntry;
  begin
{$if not(defined(VER2_2) or defined(VER2_4))}
    { assign initial values to global Widestring typed consts }
    for i:=1 to WStrInitTablesTable.count do
      begin
        ptable:=WStrInitTablesTable.tables[i];
        while Assigned(ptable^.addr) do
          begin
            fpc_widestr_assign(ptable^.addr^, ptable^.data);
            Inc(ptable);
          end;
      end;
{$endif}

    { Note: since WideChar=UnicodeChar and PWideChar=PUnicodeChar,
      Wide2AnsiMoveProc is identical to Unicode2AnsiStrMoveProc. }

    { Widestring }
    widestringmanager.Wide2AnsiMoveProc:=@Win32Unicode2AnsiMove;
    widestringmanager.Ansi2WideMoveProc:=@Win32Ansi2WideMove;
    widestringmanager.UpperWideStringProc:=@Win32WideUpper;
    widestringmanager.LowerWideStringProc:=@Win32WideLower;
    { Unicode }
    widestringmanager.Unicode2AnsiMoveProc:=@Win32Unicode2AnsiMove;
    widestringmanager.Ansi2UnicodeMoveProc:=@Win32Ansi2UnicodeMove;
    widestringmanager.UpperUnicodeStringProc:=@Win32UnicodeUpper;
    widestringmanager.LowerUnicodeStringProc:=@Win32UnicodeLower;
    { Codepage }
    widestringmanager.GetStandardCodePageProc:=@Win32GetStandardCodePage;

    DefaultSystemCodePage:=GetACP;
    DefaultUnicodeCodePage:=CP_UTF16;
    DefaultFileSystemCodePage:=DefaultSystemCodePage;
    DefaultRTLFileSystemCodePage:=DefaultFileSystemCodePage;
  end;

