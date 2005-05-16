{
    $Id: system.pp,v 1.9 2005/05/12 20:29:04 michael Exp $

    This file is part of the Free Pascal run time library.
    Copyright (c) 1999-2000 by Florian Klaempfl
    member of the Free Pascal development team

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

{$define PALMOS}
{$ASMMODE DIRECT}
unit {$ifdef VER1_0}syspalm{$else}system{$endif};

{$I os.inc}

  Interface

{Platform specific information}
const
 LineEnding = #10;
 LFNSupport = false;
 DirectorySeparator = '/';
 DriveSeparator = ':';
 PathSeparator = ';';
 FileNameCaseSensitive = false;
 CtrlZMarksEOF: boolean = false; (* #26 not considered as end of file *)
 maxExitCode = 255; {$ERROR TODO: CONFIRM THIS}
 MaxPathLen = 256;

    Type
       { type and constant declartions doesn't hurt }
       LongInt  = $80000000..$7fffffff;
       Integer  = -32768..32767;
       ShortInt = -128..127;
       Byte     = 0..255;
       Word     = 0..65535;

       { !!!!
       DWord    = Cardinal;
       LongWord = Cardinal;
       }

       { The Cardinal data type isn't currently implemented for the m68k }
       DWord    = LongInt;
       LongWord = LongInt;

       { Zero - terminated strings }
       PChar    = ^Char;
       PPChar   = ^PChar;

       { procedure type }
       TProcedure = Procedure;

    const
       { max. values for longint and int }
       MaxLongint = High(LongInt);
       MaxInt = High(Integer);

       { Must be determined at startup for both }
       Test68000 : byte = 0;
       Test68881 : byte = 0;

    { Palm specific data types }
    type
       Ptr    = ^Char;

    var
       ExitCode : DWord;
       { this variables are passed to PilotMain by the PalmOS }
       cmd : Word;
       cmdPBP : Ptr;
       launchFlags : Word;

  implementation

    { mimic the C start code }
    function PilotMain(_cmd : Word;_cmdPBP : Ptr;_launchFlags : Word) : DWord;cdecl;public;

      begin
         cmd:=_cmd;
         cmdPBP:=_cmdPBP;
         launchFlags:=_launchFlags;
         asm
            bsr PASCALMAIN
         end;
         PilotMain:=ExitCode;
      end;

{*****************************************************************************
                         System Dependent Exit code
*****************************************************************************}
Procedure system_exit;
begin
end;

function GetProcessID: SizeUInt;
begin
 GetProcessID := 1;
end;

begin
   ExitCode:=0;
end.

{
  $Log: system.pp,v $
  Revision 1.9  2005/05/12 20:29:04  michael
  + Added maxpathlen constant (maximum length of filename path)

  Revision 1.8  2005/04/03 21:10:59  hajny
    * EOF_CTRLZ conditional define replaced with CtrlZMarksEOF, #26 handling made more consistent (fix for bug 2453)

  Revision 1.7  2005/02/14 17:13:31  peter
    * truncate log

}
