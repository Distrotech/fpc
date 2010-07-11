{
    Copyright (c) 1998-2002 by Florian Klaempfl

    Commandline compiler for Free Pascal

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
program ppsem;

{
  possible compiler switches:
  -----------------------------------------------------------------
  CMEM                use cmem unit for better memory debugging
  I386                generate a compiler for the Intel i386+
  x86_64              generate a compiler for the AMD x86-64 architecture
  M68K                generate a compiler for the M68000
  SPARC               generate a compiler for SPARC
  POWERPC             generate a compiler for the PowerPC
  POWERPC64           generate a compiler for the PowerPC64 architecture
  VIS                 generate a compile for the VIS
  DEBUG               version with debug code is generated
  EXTDEBUG            some extra debug code is executed
  SUPPORT_MMX         only i386: releases the compiler switch
                      MMX which allows the compiler to generate
                      MMX instructions
  EXTERN_MSG          Don't compile the msgfiles in the compiler, always
                      use external messagefiles, default for TP
  FPC_ARMEL           create an arm eabi compiler
  FPC_ARMEB           create an arm big endian compiler
  FPC_OARM            create an arm oabi compiler, only needed when the host
                      compiler is ARMEL or ARMEB
  -----------------------------------------------------------------
  cpuflags            The target processor has status flags (on by default)
  cpufpemu            The target compiler will also support emitting software
                       floating point operations
  cpu64bitaddr        Generate code for a 64-bit address space
  cpu64bitalu         The target cpu has 64-bit registers and a 64 bit alu
                      (required for cpu64bitaddr; optional with 32 bit addr space)
  -----------------------------------------------------------------
}

{$i fpcdefs.inc}

{ Require at least 2.0.2 }
{$ifdef VER2_0}
  {$if FPC_PATCH<2}
    {$fatal At least FPC 2.0.2 is required to compile the compiler}
  {$endif}
{$endif VER2_0}

{ exactly one target CPU must be defined }
{$ifdef I386}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif I386}
{$ifdef x86_64}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif x86_64}
{$ifdef M68K}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif M68K}
{$ifdef vis}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif}
{$ifdef iA64}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif iA64}
{$ifdef POWERPC}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif POWERPC}
{$ifdef POWERPC64}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif POWERPC64}
{$ifdef ALPHA}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif ALPHA}
{$ifdef SPARC}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif SPARC}
{$ifdef ARM}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif ARM}
{$ifdef MIPS}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif MIPS}
{$ifdef AVR}
  {$ifdef CPUDEFINED}
    {$fatal ONLY one of the switches for the CPU type must be defined}
  {$endif CPUDEFINED}
  {$define CPUDEFINED}
{$endif AVR}
{$ifndef CPUDEFINED}
  {$fatal A CPU type switch must be defined}
{$endif CPUDEFINED}
{$ifdef support_mmx}
  {$ifndef i386}
    {$fatal I386 switch must be on for MMX support}
  {$endif i386}
{$endif support_mmx}

{$ifdef win32}
  { 256 MB stack }
  { under windows the stack can't grow }
  {$MAXSTACKSIZE 256000000}
{$else win32}
  {$ifdef win64}
    { 512 MB stack }
    { under windows the stack can't grow }
    {$MAXSTACKSIZE 512000000}
  {$else win64}
    { 1 MB stack }
    {$MINSTACKSIZE 1000000}
  {$endif win64}
{$endif win32}

uses
{$ifdef cmem}
  cmem,
{$endif cmem}
{$ifdef profile}
  profile,
{$endif profile}
{$ifndef NOCATCH}
  {$if defined(Unix) or defined(Go32v2) or defined(Watcom)}
    catch,
  {$endif}
{$endif NOCATCH}
  globals,compiler;

var
  oldexit : pointer;
procedure myexit;
begin
  exitproc:=oldexit;
{$ifdef nocatch}
  exit;
{$endif nocatch}
{ Show Runtime error if there was an error }
  if (erroraddr<>nil) then
   begin
     case exitcode of
      100:
        begin
           erroraddr:=nil;
           writeln('Error while reading file');
        end;
      101:
        begin
           erroraddr:=nil;
           writeln('Error while writing file');
        end;
      202:
        begin
           erroraddr:=nil;
           writeln('Error: Stack Overflow');
        end;
      203:
        begin
           erroraddr:=nil;
           writeln('Error: Out of memory');
        end;
     end;
     { we cannot use current_filepos.file because all memory might have been
       freed already !
       But we can use global parser_current_file var }
     Writeln('Compilation aborted ',parser_current_file,':',current_filepos.line);
   end;
end;

begin
  oldexit:=exitproc;
  exitproc:=@myexit;
{$ifdef extheaptrc}
  keepreleased:=true;
{$endif extheaptrc}
{ Call the compiler with empty command, so it will take the parameters }
  Halt(compiler.Compile(''));
end.
