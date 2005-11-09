{
    Copyright (c) 1998-2002 by Florian Klaempfl

    Some basic types and constants for the code generation

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
{# This unit exports some types which are used across the code generator }
unit cgbase;

{$i fpcdefs.inc}

interface

    uses
      globtype,
      symconst;

    type
       { Location types where value can be stored }
       TCGLoc=(
         LOC_INVALID,      { added for tracking problems}
         LOC_VOID,         { no value is available }
         LOC_CONSTANT,     { constant value }
         LOC_JUMP,         { boolean results only, jump to false or true label }
         LOC_FLAGS,        { boolean results only, flags are set }
         LOC_CREFERENCE,   { in memory constant value reference (cannot change) }
         LOC_REFERENCE,    { in memory value }
         LOC_REGISTER,     { in a processor register }
         LOC_CREGISTER,    { Constant register which shouldn't be modified }
         LOC_FPUREGISTER,  { FPU stack }
         LOC_CFPUREGISTER, { if it is a FPU register variable on the fpu stack }
         LOC_MMXREGISTER,  { MMX register }
         { MMX register variable }
         LOC_CMMXREGISTER,
         { multimedia register }
         LOC_MMREGISTER,
         { Constant multimedia reg which shouldn't be modified }
         LOC_CMMREGISTER
       );

       { since we have only 16 offsets, we need to be able to specify the high
         and low 16 bits of the address of a symbol                            }
       trefaddr = (addr_no,addr_full,addr_hi,addr_lo,addr_pic);

       {# Generic opcodes, which must be supported by all processors
       }
       topcg =
       (
          OP_NONE,
          OP_ADD,       { simple addition          }
          OP_AND,       { simple logical and       }
          OP_DIV,       { simple unsigned division }
          OP_IDIV,      { simple signed division   }
          OP_IMUL,      { simple signed multiply   }
          OP_MUL,       { simple unsigned multiply }
          OP_NEG,       { simple negate            }
          OP_NOT,       { simple logical not       }
          OP_OR,        { simple logical or        }
          OP_SAR,       { arithmetic shift-right   }
          OP_SHL,       { logical shift left       }
          OP_SHR,       { logical shift right      }
          OP_SUB,       { simple subtraction       }
          OP_XOR        { simple exclusive or      }
        );

       {# Generic flag values - used for jump locations }
       TOpCmp =
       (
          OC_NONE,
          OC_EQ,           { equality comparison              }
          OC_GT,           { greater than (signed)            }
          OC_LT,           { less than (signed)               }
          OC_GTE,          { greater or equal than (signed)   }
          OC_LTE,          { less or equal than (signed)      }
          OC_NE,           { not equal                        }
          OC_BE,           { less or equal than (unsigned)    }
          OC_B,            { less than (unsigned)             }
          OC_AE,           { greater or equal than (unsigned) }
          OC_A             { greater than (unsigned)          }
        );

       { OS_NO is also used memory references with large data that can
         not be loaded in a register directly }
       TCgSize = (OS_NO,
                 { integer registers }
                  OS_8,OS_16,OS_32,OS_64,OS_128,OS_S8,OS_S16,OS_S32,OS_S64,OS_S128,
                 { single,double,extended,comp,float128 }
                  OS_F32,OS_F64,OS_F80,OS_C64,OS_F128,
                 { multi-media sizes: split in byte, word, dword, ... }
                 { entities, then the signed counterparts             }
                  OS_M8,OS_M16,OS_M32,OS_M64,OS_M128,
                  OS_MS8,OS_MS16,OS_MS32,OS_MS64,OS_MS128);

      { Register types }
      TRegisterType = (
        R_INVALIDREGISTER, { = 0 }
        R_INTREGISTER,     { = 1 }
        R_FPUREGISTER,     { = 2 }
        { used by Intel only }
        R_MMXREGISTER,     { = 3 }
        R_MMREGISTER,      { = 4 }
        R_SPECIALREGISTER, { = 5 }
        R_ADDRESSREGISTER  { = 6 }
      );

      { Sub registers }
      TSubRegister = (
        R_SUBNONE, { = 0; no sub register possible }
        R_SUBL,    { = 1; 8 bits, Like AL }
        R_SUBH,    { = 2; 8 bits, Like AH }
        R_SUBW,    { = 3; 16 bits, Like AX }
        R_SUBD,    { = 4; 32 bits, Like EAX }
        R_SUBQ,    { = 5; 64 bits, Like RAX }
        { For Sparc floats that use F0:F1 to store doubles }
        R_SUBFS,   { = 6; Float that allocates 1 FPU register }
        R_SUBFD,   { = 7; Float that allocates 2 FPU registers }
        R_SUBFQ    { = 8; Float that allocates 4 FPU registers }
      );

      TSuperRegister = type word;

      {
        The new register coding:

        SuperRegister   (bits 0..15)
        Subregister     (bits 16..23)
        Register type   (bits 24..31)

        TRegister is defined as an enum to make it incompatible
        with TSuperRegister to avoid mixing them
      }
      TRegister = (
        TRegisterLowEnum := Low(longint),
        TRegisterHighEnum := High(longint)
      );
      TRegisterRec=packed record
{$ifdef FPC_BIG_ENDIAN}
         regtype : Tregistertype;
         subreg  : Tsubregister;
         supreg  : Tsuperregister;
{$else FPC_BIG_ENDIAN}
         supreg  : Tsuperregister;
         subreg  : Tsubregister;
         regtype : Tregistertype;
{$endif FPC_BIG_ENDIAN}
      end;

      { A type to store register locations for 64 Bit values. }
{$ifdef cpu64bit}
      tregister64 = tregister;
{$else cpu64bit}
      tregister64 = record
         reglo,reghi : tregister;
      end;
{$endif cpu64bit}

      Tregistermmxset = record
        reg0,reg1,reg2,reg3:Tregister
      end;

      { Set type definition for registers }
      tcpuregisterset = set of byte;
      tsuperregisterset = array[byte] of set of byte;

      pmmshuffle = ^tmmshuffle;

      { this record describes shuffle operations for mm operations; if a pointer a shuffle record
        passed to an mm operation is nil, it means that the whole location is moved }
      tmmshuffle = record
        { describes how many shuffles are actually described, if len=0 then
          moving the scalar with index 0 to the scalar with index 0 is meant }
        len : byte;
        { lower nibble of each entry of this array describes index of the source data index while
          the upper nibble describes the destination index }
        shuffles : array[1..1] of byte;
      end;

      Tsuperregisterarray=array[0..$ffff] of Tsuperregister;
      Psuperregisterarray=^Tsuperregisterarray;

      Tsuperregisterworklist=object
        buflength,
        buflengthinc,
        length:word;
        buf:Psuperregisterarray;
        constructor init;
        constructor copyfrom(const x:Tsuperregisterworklist);
        destructor  done;
        procedure clear;
        procedure add(s:tsuperregister);
        function get:tsuperregister;
        procedure deleteidx(i:word);
        function delete(s:tsuperregister):boolean;
      end;
      psuperregisterworklist=^tsuperregisterworklist;

    const
       { alias for easier understanding }
       R_SSEREGISTER = R_MMREGISTER;

       { Invalid register number }
       RS_INVALID    = high(tsuperregister);

       { Maximum number of cpu registers per register type,
         this must fit in tcpuregisterset }
       maxcpuregister = 32;

       tcgsize2size : Array[tcgsize] of integer =
         { integer values }
        (0,1,2,4,8,16,1,2,4,8,16,
         { floating point values }
         4,8,10,8,16,
         { multimedia values }
         1,2,4,8,16,1,2,4,8,16);

       tfloat2tcgsize: array[tfloattype] of tcgsize =
         (OS_F32,OS_F64,OS_F80,OS_C64,OS_C64,OS_F128);

       tcgsize2tfloat: array[OS_F32..OS_C64] of tfloattype =
         (s32real,s64real,s80real,s64comp);

       { Table to convert tcgsize variables to the correspondending
         unsigned types }
       tcgsize2unsigned : array[tcgsize] of tcgsize = (OS_NO,
          OS_8,OS_16,OS_32,OS_64,OS_128,OS_8,OS_16,OS_32,OS_64,OS_128,
          OS_F32,OS_F64,OS_F80,OS_C64,OS_F128,
          OS_M8,OS_M16,OS_M32,OS_M64,OS_M128,OS_M8,OS_M16,OS_M32,
          OS_M64,OS_M128);

       tcgloc2str : array[TCGLoc] of string[11] = (
            'LOC_INVALID',
            'LOC_VOID',
            'LOC_CONST',
            'LOC_JUMP',
            'LOC_FLAGS',
            'LOC_CREF',
            'LOC_REF',
            'LOC_REG',
            'LOC_CREG',
            'LOC_FPUREG',
            'LOC_CFPUREG',
            'LOC_MMXREG',
            'LOC_CMMXREG',
            'LOC_MMREG',
            'LOC_CMMREG');

    var
       mms_movescalar : pmmshuffle;

    procedure supregset_reset(var regs:tsuperregisterset;setall:boolean;
                              maxreg:Tsuperregister);{$ifdef USEINLINE}inline;{$endif}
    procedure supregset_include(var regs:tsuperregisterset;s:tsuperregister);{$ifdef USEINLINE}inline;{$endif}
    procedure supregset_exclude(var regs:tsuperregisterset;s:tsuperregister);{$ifdef USEINLINE}inline;{$endif}
    function supregset_in(const regs:tsuperregisterset;s:tsuperregister):boolean;{$ifdef USEINLINE}inline;{$endif}

    function newreg(rt:tregistertype;sr:tsuperregister;sb:tsubregister):tregister;{$ifdef USEINLINE}inline;{$endif}
    function getsubreg(r:tregister):tsubregister;{$ifdef USEINLINE}inline;{$endif}
    function getsupreg(r:tregister):tsuperregister;{$ifdef USEINLINE}inline;{$endif}
    function getregtype(r:tregister):tregistertype;{$ifdef USEINLINE}inline;{$endif}
    procedure setsubreg(var r:tregister;sr:tsubregister);{$ifdef USEINLINE}inline;{$endif}
    procedure setsupreg(var r:tregister;sr:tsuperregister);{$ifdef USEINLINE}inline;{$endif}
    function generic_regname(r:tregister):string;

    {# From a constant numeric value, return the abstract code generator
       size.
    }
    function int_cgsize(const a: aint): tcgsize;{$ifdef USEINLINE}inline;{$endif}

    { return the inverse condition of opcmp }
    function inverse_opcmp(opcmp: topcmp): topcmp;{$ifdef USEINLINE}inline;{$endif}

    { return whether op is commutative }
    function commutativeop(op: topcg): boolean;{$ifdef USEINLINE}inline;{$endif}

    { returns true, if shuffle describes a real shuffle operation and not only a move }
    function realshuffle(shuffle : pmmshuffle) : boolean;

    { returns true, if the shuffle describes only a move of the scalar at index 0 }
    function shufflescalar(shuffle : pmmshuffle) : boolean;

    { removes shuffling from shuffle, this means that the destenation index of each shuffle is copied to
      the source }
    procedure removeshuffles(var shuffle : tmmshuffle);

implementation

    uses
      verbose;

{******************************************************************************
                             tsuperregisterworklist
******************************************************************************}

    constructor tsuperregisterworklist.init;

    begin
      length:=0;
      buflength:=0;
      buflengthinc:=16;
      buf:=nil;
    end;

    constructor Tsuperregisterworklist.copyfrom(const x:Tsuperregisterworklist);

    begin
      self:=x;
      if x.buf<>nil then
        begin
          getmem(buf,buflength*sizeof(Tsuperregister));
          move(x.buf^,buf^,length*sizeof(Tsuperregister));
        end;
    end;

    destructor tsuperregisterworklist.done;

    begin
      if assigned(buf) then
        freemem(buf);
    end;


    procedure tsuperregisterworklist.add(s:tsuperregister);

    begin
      inc(length);
      { Need to increase buffer length? }
      if length>=buflength then
        begin
          inc(buflength,buflengthinc);
          buflengthinc:=buflengthinc*2;
          if buflengthinc>256 then
             buflengthinc:=256;
          reallocmem(buf,buflength*sizeof(Tsuperregister));
        end;
      buf^[length-1]:=s;
    end;


    procedure tsuperregisterworklist.clear;

    begin
      length:=0;
    end;


    procedure tsuperregisterworklist.deleteidx(i:word);

    begin
      if length=0 then
        internalerror(200310144);
      buf^[i]:=buf^[length-1];
      dec(length);
    end;


    function tsuperregisterworklist.get:tsuperregister;

    begin
      if length=0 then
        internalerror(200310142);
      get:=buf^[0];
      buf^[0]:=buf^[length-1];
      dec(length);
    end;


    function tsuperregisterworklist.delete(s:tsuperregister):boolean;

    var
      i:longint;

    begin
      delete:=false;
      { indexword in 1.0.x and 1.9.4 is broken }
      i:=indexword(buf^,length,s);
      if i<>-1 then
        begin
          deleteidx(i);
          delete := true;
        end;
    end;


    procedure supregset_reset(var regs:tsuperregisterset;setall:boolean;
                              maxreg:Tsuperregister);{$ifdef USEINLINE}inline;{$endif}

    begin
      fillchar(regs,(maxreg+7) shr 3,-byte(setall));
    end;


    procedure supregset_include(var regs:tsuperregisterset;s:tsuperregister);{$ifdef USEINLINE}inline;{$endif}
      begin
        include(regs[s shr 8],(s and $ff));
      end;


    procedure supregset_exclude(var regs:tsuperregisterset;s:tsuperregister);{$ifdef USEINLINE}inline;{$endif}
      begin
        exclude(regs[s shr 8],(s and $ff));
      end;


    function supregset_in(const regs:tsuperregisterset;s:tsuperregister):boolean;{$ifdef USEINLINE}inline;{$endif}
      begin
        result:=(s and $ff) in regs[s shr 8];
      end;


    function newreg(rt:tregistertype;sr:tsuperregister;sb:tsubregister):tregister;{$ifdef USEINLINE}inline;{$endif}
      begin
        tregisterrec(result).regtype:=rt;
        tregisterrec(result).supreg:=sr;
        tregisterrec(result).subreg:=sb;
      end;


    function getsubreg(r:tregister):tsubregister;{$ifdef USEINLINE}inline;{$endif}
      begin
        result:=tregisterrec(r).subreg;
      end;


    function getsupreg(r:tregister):tsuperregister;{$ifdef USEINLINE}inline;{$endif}
      begin
        result:=tregisterrec(r).supreg;
      end;


    function getregtype(r:tregister):tregistertype;{$ifdef USEINLINE}inline;{$endif}
      begin
        result:=tregisterrec(r).regtype;
      end;


    procedure setsubreg(var r:tregister;sr:tsubregister);{$ifdef USEINLINE}inline;{$endif}
      begin
        tregisterrec(r).subreg:=sr;
      end;


    procedure setsupreg(var r:tregister;sr:tsuperregister);{$ifdef USEINLINE}inline;{$endif}
      begin
        tregisterrec(r).supreg:=sr;
      end;


    function generic_regname(r:tregister):string;
      var
        nr : string[12];
      begin
        str(getsupreg(r),nr);
        case getregtype(r) of
          R_INTREGISTER:
            result:='ireg'+nr;
          R_FPUREGISTER:
            result:='freg'+nr;
          R_MMREGISTER:
            result:='mreg'+nr;
          R_MMXREGISTER:
            result:='xreg'+nr;
          else
            begin
              result:='INVALID';
              exit;
            end;
        end;
        case getsubreg(r) of
          R_SUBNONE:
            ;
          R_SUBL:
            result:=result+'l';
          R_SUBH:
            result:=result+'h';
          R_SUBW:
            result:=result+'w';
          R_SUBD:
            result:=result+'d';
          R_SUBQ:
            result:=result+'q';
          R_SUBFS:
            result:=result+'fs';
          R_SUBFD:
            result:=result+'fd';
          else
            internalerror(200308252);
        end;
      end;


    function int_cgsize(const a: aint): tcgsize;{$ifdef USEINLINE}inline;{$endif}
      const
        size2cgsize : array[0..8] of tcgsize = (
          OS_NO,OS_8,OS_16,OS_32,OS_32,OS_64,OS_64,OS_64,OS_64
        );
      begin
        if a>8 then
          result:=OS_NO
        else
          result:=size2cgsize[a];
      end;


    function inverse_opcmp(opcmp: topcmp): topcmp;{$ifdef USEINLINE}inline;{$endif}
      const
        list: array[TOpCmp] of TOpCmp =
          (OC_NONE,OC_NE,OC_LTE,OC_GTE,OC_LT,OC_GT,OC_EQ,OC_A,OC_AE,
           OC_B,OC_BE);
      begin
        inverse_opcmp := list[opcmp];
      end;


    function commutativeop(op: topcg): boolean;{$ifdef USEINLINE}inline;{$endif}
      const
        list: array[topcg] of boolean =
          (true,true,true,false,false,true,true,false,false,
           true,false,false,false,false,true);
      begin
        commutativeop := list[op];
      end;


    function realshuffle(shuffle : pmmshuffle) : boolean;
      var
        i : longint;
      begin
        realshuffle:=true;
        if (shuffle=nil) or (shuffle^.len=0) then
          realshuffle:=false
        else
          begin
            for i:=1 to shuffle^.len do
              begin
                if (shuffle^.shuffles[i] and $f)<>((shuffle^.shuffles[i] and $f0) shr 8) then
                  exit;
              end;
            realshuffle:=false;
          end;
      end;


    function shufflescalar(shuffle : pmmshuffle) : boolean;
      begin
        result:=shuffle^.len=0;
      end;


    procedure removeshuffles(var shuffle : tmmshuffle);
      var
        i : longint;
      begin
        if shuffle.len=0 then
          exit;
        for i:=1 to shuffle.len do
          shuffle.shuffles[i]:=(shuffle.shuffles[i] and $f0) or ((shuffle.shuffles[i] and $f0) shr 8);
      end;


initialization
  new(mms_movescalar);
  mms_movescalar^.len:=0;
finalization
  dispose(mms_movescalar);
end.
