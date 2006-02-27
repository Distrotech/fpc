{
    Copyright (c) 1998-2006 by Peter Vreman

    Contains the binary coff reader and writer

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
unit ogcoff;

{$i fpcdefs.inc}

interface

    uses
       { common }
       cclasses,globtype,
       { target }
       systems,
       { assembler }
       cpuinfo,cpubase,aasmbase,assemble,link,
       { output }
       ogbase,ogmap;

    type
       TCoffObjSection = class(TObjSection)
       private
         orgmempos,
         coffrelocs,
         coffrelocpos : longint;
       public
         flags    : longword;
         constructor create(const Aname:string;Aalign:longint;Aoptions:TObjSectionOptions);override;
         procedure addsymsizereloc(ofs:longint;p:tasmsymbol;size:longint;relative:TObjRelocationType);
         procedure fixuprelocs;override;
       end;

       TDJCoffObjSection = class(TCoffObjSection)
         constructor create(const Aname:string;Aalign:longint;Aoptions:TObjSectionOptions);override;
       end;

       TPECoffObjSection = class(TCoffObjSection)
         constructor create(const Aname:string;Aalign:longint;Aoptions:TObjSectionOptions);override;
       end;

       TCoffObjData = class(TObjData)
       private
         win32      : boolean;
         procedure section_mempos(p:tnamedindexitem;arg:pointer);
       public
         constructor createcoff(const n:string;awin32:boolean;acObjSection:TObjSectionClass);
         destructor  destroy;override;
         procedure CreateDebugSections;override;
         function  sectionname(atype:TAsmSectiontype;const aname:string):string;override;
         procedure writereloc(data,len:aint;p:tasmsymbol;relative:TObjRelocationType);override;
         procedure writesymbol(p:tasmsymbol);override;
         procedure writestab(offset:aint;ps:tasmsymbol;nidx,nother:byte;ndesc:word;p:pchar);override;
         procedure beforealloc;override;
         procedure beforewrite;override;
         procedure afteralloc;override;
       end;

       TDJCoffObjData = class(TCoffObjData)
         constructor create(const n:string);override;
       end;

       TPECoffObjData = class(TCoffObjData)
         constructor create(const n:string);override;
       end;

       TCoffObjOutput = class(tObjOutput)
       private
         win32   : boolean;
         initsym : longint;
         FCoffStrs : tdynamicarray;
         procedure write_symbol(const name:string;value:longint;section:smallint;typ,aux:byte);
         procedure section_write_symbol(p:tnamedindexitem;arg:pointer);
         procedure section_write_relocs(p:tnamedindexitem;arg:pointer);
         procedure write_ObjSymbols(data:TObjData);
         procedure section_set_secsymidx(p:tnamedindexitem;arg:pointer);
         procedure section_set_datapos(p:tnamedindexitem;arg:pointer);
         procedure section_set_reloc_datapos(p:tnamedindexitem;arg:pointer);
         procedure section_write_header(p:tnamedindexitem;arg:pointer);
         procedure section_write_data(p:tnamedindexitem;arg:pointer);
       protected
         function writedata(data:TObjData):boolean;override;
       public
         constructor createcoff(smart:boolean;awin32:boolean);
       end;

       TDJCoffObjOutput = class(TCoffObjOutput)
         constructor create(smart:boolean);override;
       end;

       TPECoffObjOutput = class(TCoffObjOutput)
         constructor create(smart:boolean);override;
       end;

       TCoffExeSection = class(TExeSection)
       private
         win32   : boolean;
       public
         constructor createcoff(const n:string;awin32:boolean);
       end;

       TDJCoffExeSection = class(TCoffExeSection)
         constructor create(const n:string);override;
       end;

       TPECoffExeSection = class(TCoffExeSection)
         constructor create(const n:string);override;
       end;

       TCoffexeoutput = class(texeoutput)
       private
         FCoffsyms,
         FCoffStrs : tdynamicarray;
         win32     : boolean;
         nsects    : word;
         nsyms,
         sympos    : longint;
         procedure ExeSections_pass2_header(p:tnamedindexitem;arg:pointer);
         procedure write_symbol(const name:string;value:longint;section:smallint;typ,aux:byte);
         procedure globalsyms_write_symbol(p:tnamedindexitem;arg:pointer);
         procedure ExeSections_write_header(p:tnamedindexitem;arg:pointer);
         procedure ExeSections_write_data(p:tnamedindexitem;arg:pointer);
       protected
         procedure Pass2_Header;override;
         procedure Pass2_Symbols;override;
         function writedata:boolean;override;
       public
         constructor createcoff(awin32:boolean);
       end;

       TDJCoffexeoutput = class(TCoffexeoutput)
         constructor create;override;
       end;

       TPECoffexeoutput = class(TCoffexeoutput)
         constructor create;override;
       end;

       ttasmsymbolrec = record
         sym : tasmsymbol;
         orgsize : longint;
       end;
       ttasmsymbolarray = array[0..high(word)] of ttasmsymbolrec;

       TCoffObjInput = class(tObjInput)
       private
         Fidx2objsec  : array[0..255] of TObjSection;
         FCoffsyms,
         FCoffStrs : tdynamicarray;
         FSymTbl   : ^ttasmsymbolarray;
         win32     : boolean;
         procedure read_relocs(s:TCoffObjSection);
         procedure handle_ObjSymbols(data:TObjData);
         procedure ObjSections_read_data(p:tnamedindexitem;arg:pointer);
         procedure ObjSections_read_relocs(p:tnamedindexitem;arg:pointer);
       protected
         function  readObjData(data:TObjData):boolean;override;
       public
         constructor createcoff(awin32:boolean);
       end;

       TDJCoffObjInput = class(TCoffObjInput)
         constructor create;override;
       end;

       TPECoffObjInput = class(TCoffObjInput)
         constructor create;override;
       end;

       TDJCoffAssembler = class(tinternalassembler)
         constructor create(smart:boolean);override;
       end;

       TPECoffassembler = class(tinternalassembler)
         constructor create(smart:boolean);override;
       end;

       TDJCofflinker = class(tinternallinker)
         constructor create;override;
         procedure DefaultLinkScript;override;
       end;

       TPECofflinker = class(tinternallinker)
         constructor create;override;
         procedure DefaultLinkScript;override;
       end;


implementation

    uses
       strings,
       cutils,verbose,
       globals,fmodule,aasmtai;

    const
{$ifdef i386}
       COFF_MAGIC = $14c;
{$endif i386}
{$ifdef arm}
       COFF_MAGIC = $1c0;
{$endif arm}

       COFF_FLAG_NORELOCS = $0001;
       COFF_FLAG_EXE      = $0002;
       COFF_FLAG_NOLINES  = $0004;
       COFF_FLAG_NOLSYMS  = $0008;
       COFF_FLAG_AR16WR   = $0080; { 16bit little endian }
       COFF_FLAG_AR32WR   = $0100; { 32bit little endian }
       COFF_FLAG_AR32W    = $0200; { 32bit big endian }
       COFF_FLAG_DLL      = $2000;

       COFF_SYM_GLOBAL   = 2;
       COFF_SYM_LOCAL    = 3;
       COFF_SYM_LABEL    = 6;
       COFF_SYM_FUNCTION = 101;
       COFF_SYM_FILE     = 103;
       COFF_SYM_SECTION  = 104;

       COFF_STYP_REG    = $0000; { "regular": allocated, relocated, loaded }
       COFF_STYP_DSECT  = $0001; { "dummy":  relocated only }
       COFF_STYP_NOLOAD = $0002; { "noload": allocated, relocated, not loaded }
       COFF_STYP_GROUP  = $0004; { "grouped": formed of input sections }
       COFF_STYP_PAD    = $0008;
       COFF_STYP_COPY   = $0010;
       COFF_STYP_TEXT   = $0020;
       COFF_STYP_DATA   = $0040;
       COFF_STYP_BSS    = $0080;

       PE_SUBSYSTEM_WINDOWS_GUI    = 2;
       PE_SUBSYSTEM_WINDOWS_CUI	   = 3;
       PE_SUBSYSTEM_WINDOWS_CE_GUI = 9;

       PE_FILE_RELOCS_STRIPPED         = $0001;
       PE_FILE_EXECUTABLE_IMAGE        = $0002;
       PE_FILE_LINE_NUMS_STRIPPED      = $0004;
       PE_FILE_LOCAL_SYMS_STRIPPED     = $0008;
       PE_FILE_AGGRESSIVE_WS_TRIM      = $0010;
       PE_FILE_LARGE_ADDRESS_AWARE     = $0020;
       PE_FILE_16BIT_MACHINE           = $0040;
       PE_FILE_BYTES_REVERSED_LO       = $0080;
       PE_FILE_32BIT_MACHINE           = $0100;
       PE_FILE_DEBUG_STRIPPED          = $0200;
       PE_FILE_REMOVABLE_RUN_FROM_SWAP = $0400;
       PE_FILE_NET_RUN_FROM_SWAP       = $0800;
       PE_FILE_SYSTEM                  = $1000;
       PE_FILE_DLL                     = $2000;
       PE_FILE_UP_SYSTEM_ONLY          = $4000;
       PE_FILE_BYTES_REVERSED_HI       = $8000;

       PE_SCN_CNT_CODE               = $00000020; { Section contains code. }
       PE_SCN_CNT_INITIALIZED_DATA   = $00000040; { Section contains initialized data. }
       PE_SCN_CNT_UNINITIALIZED_DATA = $00000080; { Section contains uninitialized data. }
       PE_SCN_LNK_OTHER              = $00000100; { Reserved. }
       PE_SCN_LNK_INFO               = $00000200; { Section contains comments or some other type of information. }
       PE_SCN_LNK_REMOVE             = $00000800; { Section contents will not become part of image. }
       PE_SCN_LNK_COMDAT             = $00001000; { Section contents comdat. }
       PE_SCN_MEM_FARDATA            = $00008000;
       PE_SCN_MEM_PURGEABLE          = $00020000;
       PE_SCN_MEM_16BIT              = $00020000;
       PE_SCN_MEM_LOCKED             = $00040000;
       PE_SCN_MEM_PRELOAD            = $00080000;
       PE_SCN_ALIGN_MASK             = $00f00000;
       PE_SCN_ALIGN_1BYTES           = $00100000;
       PE_SCN_ALIGN_2BYTES           = $00200000;
       PE_SCN_ALIGN_4BYTES           = $00300000;
       PE_SCN_ALIGN_8BYTES           = $00400000;
       PE_SCN_ALIGN_16BYTES          = $00500000; { Default alignment if no others are specified. }
       PE_SCN_ALIGN_32BYTES          = $00600000;
       PE_SCN_ALIGN_64BYTES          = $00700000;
       PE_SCN_LNK_NRELOC_OVFL        = $01000000; { Section contains extended relocations. }
       PE_SCN_MEM_NOT_CACHED         = $04000000; { Section is not cachable.               }
       PE_SCN_MEM_NOT_PAGED          = $08000000; { Section is not pageable.               }
       PE_SCN_MEM_SHARED             = $10000000; { Section is shareable.                  }
       PE_SCN_MEM_DISCARDABLE        = $02000000;
       PE_SCN_MEM_EXECUTE            = $20000000;
       PE_SCN_MEM_READ               = $40000000;
       PE_SCN_MEM_WRITE              = $80000000;

       PE_DATADIR_ENTRIES = 16;
       PE_DATADIR_EDATA = 0;
       PE_DATADIR_IDATA = 1;
       PE_DATADIR_RSRC = 2;
       PE_DATADIR_PDATA = 3;
       PE_DATADIR_SECURITY = 4;
       PE_DATADIR_RELOC = 5;
       PE_DATADIR_DEBUG = 6;
       PE_DATADIR_DESCRIPTION = 7;
       PE_DATADIR_SPECIAL = 8;
       PE_DATADIR_TLS = 9;
       PE_DATADIR_LOADCFG = 10;
       PE_DATADIR_BOUNDIMPORT = 11;
       PE_DATADIR_IMPORTADDRESSTABLE = 12;
       PE_DATADIR_DELAYIMPORT = 13;

    type
       { Structures which are written directly to the output file }
       coffheader=packed record
         mach   : word;
         nsects : word;
         time   : longint;
         sympos : longint;
         syms   : longint;
         opthdr : word;
         flag   : word;
       end;
       coffdjoptheader=packed record
         magic  : word;
         vstamp : word;
         tsize  : longint;
         dsize  : longint;
         bsize  : longint;
         entry  : longint;
         text_start : longint;
         data_start : longint;
       end;
       coffpedatadir=packed record
         vaddr : longint;
         size  : longint;
       end;
       coffpeoptheader=packed record
         Magic : word;
         MajorLinkerVersion : byte;
         MinorLinkerVersion : byte;
         tsize : longint;
         dsize : longint;
         bsize : longint;
         entry : longint;
         text_start : longint;
         data_start : longint;
         ImageBase : longint;
         SectionAlignment : longint;
         FileAlignment : longint;
         MajorOperatingSystemVersion : word;
         MinorOperatingSystemVersion : word;
         MajorImageVersion : word;
         MinorImageVersion : word;
         MajorSubsystemVersion : word;
         MinorSubsystemVersion : word;
         Win32Version : longint;
         SizeOfImage : longint;
         SizeOfHeaders : longint;
         CheckSum : longint;
         Subsystem : word;
         DllCharacteristics : word;
         SizeOfStackReserve : longint;
         SizeOfStackCommit : longint;
         SizeOfHeapReserve : longint;
         SizeOfHeapCommit : longint;
         LoaderFlags : longint;
         NumberOfRvaAndSizes : longint;
         DataDirectory : array[0..PE_DATADIR_ENTRIES-1] of coffpedatadir;
       end;
       coffsechdr=packed record
         name     : array[0..7] of char;
         vsize    : longint;
         rvaofs   : longint;
         datasize : longint;
         datapos  : longint;
         relocpos : longint;
         lineno1  : longint;
         nrelocs  : word;
         lineno2  : word;
         flags    : longword;
       end;
       coffsectionrec=packed record
         len     : longint;
         nrelocs : word;
         empty   : array[0..11] of char;
       end;
       coffreloc=packed record
         address  : longint;
         sym      : longint;
         relative : word;
       end;
       coffsymbol=packed record
         name    : array[0..3] of char; { real is [0..7], which overlaps the strpos ! }
         strpos  : longint;
         value   : longint;
         section : smallint;
         empty   : smallint;
         typ     : byte;
         aux     : byte;
       end;

     const
       symbolresize = 200*sizeof(coffsymbol);
       strsresize   = 8192;

       coffsecnames : array[TAsmSectiontype] of string[16] = ('',
          '.text','.data','.data','.bss','.tls',
          '.text',
          '.stab','.stabstr',
          '.idata$2','.idata$4','.idata$5','.idata$6','.idata$7','.edata',
          '.eh_frame',
          '.debug_frame','.debug_info','.debug_line','.debug_abbrev',
          '.fpc',
                  ''
        );

const go32v2stub : array[0..2047] of byte=(
  $4D,$5A,$00,$00,$04,$00,$00,$00,$20,$00,$27,$00,$FF,$FF,$00,
  $00,$60,$07,$00,$00,$54,$00,$00,$00,$00,$00,$00,$00,$0D,$0A,
  $73,$74,$75,$62,$2E,$68,$20,$67,$65,$6E,$65,$72,$61,$74,$65,
  $64,$20,$66,$72,$6F,$6D,$20,$73,$74,$75,$62,$2E,$61,$73,$6D,
  $20,$62,$79,$20,$64,$6A,$61,$73,$6D,$2C,$20,$6F,$6E,$20,$54,
  $68,$75,$20,$44,$65,$63,$20,$20,$39,$20,$31,$30,$3A,$35,$39,
  $3A,$33,$31,$20,$31,$39,$39,$39,$0D,$0A,$54,$68,$65,$20,$53,
  $54,$55,$42,$2E,$45,$58,$45,$20,$73,$74,$75,$62,$20,$6C,$6F,
  $61,$64,$65,$72,$20,$69,$73,$20,$43,$6F,$70,$79,$72,$69,$67,
  $68,$74,$20,$28,$43,$29,$20,$31,$39,$39,$33,$2D,$31,$39,$39,
  $35,$20,$44,$4A,$20,$44,$65,$6C,$6F,$72,$69,$65,$2E,$20,$0D,
  $0A,$50,$65,$72,$6D,$69,$73,$73,$69,$6F,$6E,$20,$67,$72,$61,
  $6E,$74,$65,$64,$20,$74,$6F,$20,$75,$73,$65,$20,$66,$6F,$72,
  $20,$61,$6E,$79,$20,$70,$75,$72,$70,$6F,$73,$65,$20,$70,$72,
  $6F,$76,$69,$64,$65,$64,$20,$74,$68,$69,$73,$20,$63,$6F,$70,
  $79,$72,$69,$67,$68,$74,$20,$0D,$0A,$72,$65,$6D,$61,$69,$6E,
  $73,$20,$70,$72,$65,$73,$65,$6E,$74,$20,$61,$6E,$64,$20,$75,
  $6E,$6D,$6F,$64,$69,$66,$69,$65,$64,$2E,$20,$0D,$0A,$54,$68,
  $69,$73,$20,$6F,$6E,$6C,$79,$20,$61,$70,$70,$6C,$69,$65,$73,
  $20,$74,$6F,$20,$74,$68,$65,$20,$73,$74,$75,$62,$2C,$20,$61,
  $6E,$64,$20,$6E,$6F,$74,$20,$6E,$65,$63,$65,$73,$73,$61,$72,
  $69,$6C,$79,$20,$74,$68,$65,$20,$77,$68,$6F,$6C,$65,$20,$70,
  $72,$6F,$67,$72,$61,$6D,$2E,$0A,$0D,$0A,$24,$49,$64,$3A,$20,
  $73,$74,$75,$62,$2E,$61,$73,$6D,$20,$62,$75,$69,$6C,$74,$20,
  $31,$32,$2F,$30,$39,$2F,$39,$39,$20,$31,$30,$3A,$35,$39,$3A,
  $33,$31,$20,$62,$79,$20,$64,$6A,$61,$73,$6D,$20,$24,$0A,$0D,
  $0A,$40,$28,$23,$29,$20,$73,$74,$75,$62,$2E,$61,$73,$6D,$20,
  $62,$75,$69,$6C,$74,$20,$31,$32,$2F,$30,$39,$2F,$39,$39,$20,
  $31,$30,$3A,$35,$39,$3A,$33,$31,$20,$62,$79,$20,$64,$6A,$61,
  $73,$6D,$0A,$0D,$0A,$1A,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$67,$6F,$33,$32,$73,$74,$75,$62,$2C,$20,$76,$20,$32,
  $2E,$30,$32,$54,$00,$00,$00,$00,$00,$08,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$43,$57,$53,$44,$50,
  $4D,$49,$2E,$45,$58,$45,$00,$00,$00,$00,$00,$0E,$1F,$8C,$1E,
  $24,$00,$8C,$06,$60,$07,$FC,$B4,$30,$CD,$21,$3C,$03,$73,$08,
  $B0,$6D,$BA,$A7,$05,$E9,$D4,$03,$A2,$69,$08,$BE,$20,$00,$8B,
  $04,$09,$C0,$75,$02,$B4,$FE,$BB,$70,$08,$39,$C3,$73,$02,$89,
  $C3,$89,$1C,$FE,$C7,$B9,$04,$FF,$D3,$EB,$B4,$4A,$CD,$21,$73,
  $08,$D3,$E3,$FE,$CF,$89,$1C,$EB,$D8,$26,$8E,$06,$2C,$00,$31,
  $FF,$30,$C0,$A9,$F2,$AE,$26,$81,$3D,$50,$41,$75,$15,$AF,$26,
  $81,$3D,$54,$48,$75,$0D,$AF,$26,$80,$3D,$3D,$75,$06,$47,$89,
  $3E,$8C,$04,$4F,$AE,$75,$DF,$AF,$B4,$3E,$BB,$13,$00,$CD,$21,
  $B4,$3E,$BB,$12,$00,$CD,$21,$06,$57,$31,$C9,$74,$12,$B0,$6E,
  $BA,$7E,$05,$E9,$5E,$03,$09,$C9,$75,$F4,$41,$E8,$A1,$03,$72,
  $EE,$B8,$87,$16,$CD,$2F,$09,$C0,$75,$ED,$80,$E3,$01,$74,$E8,
  $89,$3E,$00,$06,$8C,$06,$02,$06,$89,$36,$04,$06,$5F,$07,$E8,
  $D3,$02,$89,$3E,$2A,$00,$89,$36,$62,$07,$80,$3E,$2C,$00,$00,
  $74,$23,$B9,$08,$00,$BF,$2C,$00,$8A,$05,$47,$08,$C0,$74,$05,
  $88,$07,$43,$E2,$F4,$66,$C7,$07,$2E,$45,$58,$45,$83,$C3,$04,
  $C6,$07,$00,$89,$1E,$62,$07,$B8,$00,$3D,$BA,$64,$07,$CD,$21,
  $0F,$82,$B3,$02,$A3,$06,$06,$89,$C3,$B9,$06,$00,$BA,$B5,$07,
  $B4,$3F,$CD,$21,$31,$D2,$31,$C9,$A1,$B5,$07,$3D,$4C,$01,$74,
  $1B,$3D,$4D,$5A,$0F,$85,$98,$02,$8B,$16,$B9,$07,$C1,$E2,$09,
  $8B,$1E,$B7,$07,$09,$DB,$74,$05,$80,$EE,$02,$01,$DA,$89,$16,
  $BB,$07,$89,$0E,$BD,$07,$B8,$00,$42,$8B,$1E,$06,$06,$CD,$21,
  $B9,$A8,$00,$BA,$BF,$07,$B4,$3F,$CD,$21,$3D,$A8,$00,$75,$06,
  $81,$3E,$BF,$07,$4C,$01,$0F,$85,$61,$02,$66,$A1,$E3,$07,$66,
  $A3,$10,$06,$66,$8B,$0E,$BB,$07,$66,$A1,$03,$08,$66,$01,$C8,
  $66,$A3,$08,$06,$66,$A1,$2B,$08,$66,$01,$C8,$66,$A3,$0C,$06,
  $66,$8B,$1E,$4B,$08,$66,$A1,$4F,$08,$66,$01,$C3,$66,$B8,$01,
  $00,$01,$00,$66,$39,$C3,$73,$03,$66,$89,$C3,$66,$81,$C3,$FF,
  $FF,$00,$00,$31,$DB,$66,$89,$1E,$1C,$00,$E8,$F5,$02,$8B,$1E,
  $04,$06,$09,$DB,$74,$0A,$B4,$48,$CD,$21,$0F,$82,$15,$02,$8E,
  $C0,$E8,$08,$03,$B8,$01,$00,$FF,$1E,$00,$06,$0F,$82,$0F,$02,
  $8C,$06,$26,$00,$8C,$0E,$28,$00,$8C,$D8,$A3,$22,$00,$8E,$C0,
  $31,$C0,$B9,$01,$00,$CD,$31,$72,$07,$A3,$14,$06,$31,$C0,$CD,
  $31,$0F,$82,$F3,$01,$A3,$16,$06,$66,$8B,$0E,$1C,$00,$B8,$01,
  $05,$8B,$1E,$1E,$00,$CD,$31,$0F,$82,$E5,$01,$89,$1E,$1A,$06,
  $89,$0E,$18,$06,$89,$36,$1A,$00,$89,$3E,$18,$00,$B8,$07,$00,
  $8B,$1E,$14,$06,$8B,$0E,$1A,$06,$8B,$16,$18,$06,$CD,$31,$B8,
  $09,$00,$8C,$C9,$83,$E1,$03,$C1,$E1,$05,$51,$81,$C9,$9B,$C0,
  $CD,$31,$B8,$08,$00,$8B,$0E,$1E,$00,$49,$BA,$FF,$FF,$CD,$31,
  $B8,$07,$00,$8B,$1E,$16,$06,$8B,$0E,$1A,$06,$8B,$16,$18,$06,
  $CD,$31,$B8,$09,$00,$59,$81,$C9,$93,$C0,$CD,$31,$B8,$08,$00,
  $8B,$0E,$1E,$00,$49,$BA,$FF,$FF,$CD,$31,$B8,$00,$01,$BB,$00,
  $0F,$CD,$31,$73,$10,$3D,$08,$00,$0F,$85,$73,$01,$B8,$00,$01,
  $CD,$31,$0F,$82,$6A,$01,$A3,$1C,$06,$89,$16,$1E,$06,$C1,$E3,
  $04,$89,$1E,$20,$06,$66,$8B,$36,$08,$06,$66,$8B,$3E,$FB,$07,
  $66,$8B,$0E,$FF,$07,$E8,$49,$00,$66,$8B,$36,$0C,$06,$66,$8B,
  $3E,$23,$08,$66,$8B,$0E,$27,$08,$E8,$37,$00,$8E,$06,$16,$06,
  $66,$8B,$3E,$4B,$08,$66,$8B,$0E,$4F,$08,$66,$31,$C0,$66,$C1,
  $E9,$02,$67,$F3,$66,$AB,$B4,$3E,$8B,$1E,$06,$06,$CD,$21,$B8,
  $01,$01,$8B,$16,$1E,$06,$CD,$31,$1E,$0F,$A1,$8E,$1E,$16,$06,
  $66,$64,$FF,$2E,$10,$06,$66,$89,$F0,$66,$25,$FF,$01,$00,$00,
  $66,$01,$C1,$29,$C6,$66,$29,$C7,$66,$89,$0E,$26,$06,$66,$89,
  $3E,$22,$06,$E8,$0F,$01,$89,$36,$3E,$06,$66,$C1,$EE,$10,$89,
  $36,$42,$06,$8B,$1E,$06,$06,$89,$1E,$3A,$06,$C7,$06,$46,$06,
  $00,$42,$E8,$03,$01,$A1,$1C,$06,$A3,$4E,$06,$C7,$06,$3E,$06,
  $00,$00,$C6,$06,$47,$06,$3F,$A1,$28,$06,$09,$C0,$75,$09,$A1,
  $26,$06,$3B,$06,$20,$06,$76,$03,$A1,$20,$06,$A3,$42,$06,$E8,
  $D9,$00,$66,$31,$C9,$8B,$0E,$46,$06,$66,$8B,$3E,$22,$06,$66,
  $01,$0E,$22,$06,$66,$29,$0E,$26,$06,$66,$31,$F6,$C1,$E9,$02,
  $1E,$06,$8E,$06,$16,$06,$8E,$1E,$1E,$06,$67,$F3,$66,$A5,$07,
  $1F,$66,$03,$0E,$26,$06,$75,$AF,$C3,$3C,$3A,$74,$06,$3C,$2F,
  $74,$02,$3C,$5C,$C3,$BE,$64,$07,$89,$F3,$26,$8A,$05,$47,$88,
  $04,$38,$E0,$74,$0E,$08,$C0,$74,$0A,$46,$E8,$DE,$FF,$75,$EC,
  $89,$F3,$74,$E8,$C3,$B0,$66,$BA,$48,$05,$EB,$0C,$B0,$67,$BA,
  $55,$05,$EB,$05,$B0,$68,$BA,$5F,$05,$52,$8B,$1E,$62,$07,$C6,
  $07,$24,$BB,$64,$07,$EB,$28,$E8,$F5,$00,$B0,$69,$BA,$99,$05,
  $EB,$1A,$B0,$6A,$BA,$B2,$05,$EB,$13,$B0,$6B,$BA,$C4,$05,$EB,
  $0C,$B0,$6C,$BA,$D6,$05,$EB,$05,$B0,$69,$BA,$99,$05,$52,$BB,
  $3B,$05,$E8,$15,$00,$5B,$E8,$11,$00,$BB,$67,$04,$E8,$0B,$00,
  $B4,$4C,$CD,$21,$43,$50,$B4,$02,$CD,$21,$58,$8A,$17,$80,$FA,
  $24,$75,$F2,$C3,$0D,$0A,$24,$50,$51,$57,$31,$C0,$BF,$2A,$06,
  $B9,$19,$00,$F3,$AB,$5F,$59,$58,$C3,$B8,$00,$03,$BB,$21,$00,
  $31,$C9,$66,$BF,$2A,$06,$00,$00,$CD,$31,$C3,$00,$00,$30,$E4,
  $E8,$4E,$FF,$89,$DE,$8B,$3E,$8C,$04,$EB,$17,$B4,$3B,$E8,$41,
  $FF,$81,$FE,$64,$07,$74,$12,$8A,$44,$FF,$E8,$2A,$FF,$74,$04,
  $C6,$04,$5C,$46,$E8,$03,$00,$72,$E4,$C3,$E8,$34,$00,$BB,$44,
  $00,$8A,$07,$88,$04,$43,$46,$08,$C0,$75,$F6,$06,$57,$1E,$07,
  $E8,$9B,$FF,$BB,$2A,$06,$8C,$5F,$04,$89,$5F,$02,$BA,$64,$07,
  $B8,$00,$4B,$CD,$21,$5F,$07,$72,$09,$B4,$4D,$CD,$21,$2D,$00,
  $03,$F7,$D8,$EB,$28,$80,$3E,$69,$08,$05,$72,$20,$B8,$00,$58,
  $CD,$21,$A2,$67,$08,$B8,$02,$58,$CD,$21,$A2,$68,$08,$B8,$01,
  $58,$BB,$80,$00,$CD,$21,$B8,$03,$58,$BB,$01,$00,$CD,$21,$C3,
  $9C,$80,$3E,$69,$08,$05,$72,$1A,$50,$53,$B8,$03,$58,$8A,$1E,
  $68,$08,$30,$FF,$CD,$21,$B8,$01,$58,$8A,$1E,$67,$08,$30,$FF,
  $CD,$21,$5B,$58,$9D,$C3,$4C,$6F,$61,$64,$20,$65,$72,$72,$6F,
  $72,$3A,$20,$24,$3A,$20,$63,$61,$6E,$27,$74,$20,$6F,$70,$65,
  $6E,$24,$3A,$20,$6E,$6F,$74,$20,$45,$58,$45,$24,$3A,$20,$6E,
  $6F,$74,$20,$43,$4F,$46,$46,$20,$28,$43,$68,$65,$63,$6B,$20,
  $66,$6F,$72,$20,$76,$69,$72,$75,$73,$65,$73,$29,$24,$6E,$6F,
  $20,$44,$50,$4D,$49,$20,$2D,$20,$47,$65,$74,$20,$63,$73,$64,
  $70,$6D,$69,$2A,$62,$2E,$7A,$69,$70,$24,$6E,$6F,$20,$44,$4F,
  $53,$20,$6D,$65,$6D,$6F,$72,$79,$24,$6E,$65,$65,$64,$20,$44,
  $4F,$53,$20,$33,$24,$63,$61,$6E,$27,$74,$20,$73,$77,$69,$74,
  $63,$68,$20,$6D,$6F,$64,$65,$24,$6E,$6F,$20,$44,$50,$4D,$49,
  $20,$73,$65,$6C,$65,$63,$74,$6F,$72,$73,$24,$6E,$6F,$20,$44,
  $50,$4D,$49,$20,$6D,$65,$6D,$6F,$72,$79,$24,$90,$90,$90,$90,
  $90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,$90,
  $90,$90,$90,$90,$90,$90,$90,$90);

const win32stub : array[0..131] of byte=(
  $4D,$5A,$90,$00,$03,$00,$00,$00,$04,$00,$00,$00,$FF,$FF,$00,$00,
  $B8,$00,$00,$00,$00,$00,$00,$00,$40,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
  $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$80,$00,$00,$00,
  $0E,$1F,$BA,$0E,$00,$B4,$09,$CD,$21,$B8,$01,$4C,$CD,$21,$54,$68,
  $69,$73,$20,$70,$72,$6F,$67,$72,$61,$6D,$20,$63,$61,$6E,$6E,$6F,
  $74,$20,$62,$65,$20,$72,$75,$6E,$20,$69,$6E,$20,$44,$4F,$53,$20,
  $6D,$6F,$64,$65,$2E,$0D,$0D,$0A,$24,$00,$00,$00,$00,$00,$00,$00,
  $50,$45,$00,$00);

{****************************************************************************
                                 Helpers
****************************************************************************}

    function djencodesechdrflags(aoptions:TObjSectionOptions):longword;
      begin
        if (oso_load in aoptions) then
          begin
            if oso_executable in aoptions then
              result:=COFF_STYP_TEXT
            else if not(oso_data in aoptions) then
              result:=COFF_STYP_BSS
            else
              result:=COFF_STYP_DATA;
          end
        else
          result:=COFF_STYP_REG;
      end;


    function djdecodesechdrflags(const aname:string;flags:longword):TObjSectionOptions;
      begin
        result:=[];
        if flags and COFF_STYP_TEXT<>0 then
          result:=[oso_data,oso_load,oso_executable]
        else if flags and COFF_STYP_BSS<>0 then
          result:=[oso_load]
        else if flags and COFF_STYP_DATA<>0 then
          result:=[oso_data,oso_load]
        else
          result:=[oso_data]
      end;


    function peencodesechdrflags(aoptions:TObjSectionOptions;aalign:shortint):longword;
      begin
        result:=0;
        if (oso_load in aoptions) then
          begin
            if oso_executable in aoptions then
              result:=result or PE_SCN_CNT_CODE or PE_SCN_MEM_EXECUTE
            else
              begin
                if (oso_data in aoptions) then
                  result:=result or PE_SCN_CNT_INITIALIZED_DATA
                else
                  result:=result or PE_SCN_CNT_UNINITIALIZED_DATA;
              end;
            if oso_write in aoptions then
              result:=result or PE_SCN_MEM_WRITE or PE_SCN_MEM_READ
            else
              result:=result or PE_SCN_MEM_READ;
          end
        else
          result:=result or PE_SCN_LNK_REMOVE;
        if oso_debug in aoptions then
          result:=result or PE_SCN_MEM_DISCARDABLE;
        case aalign of
           1 : result:=result or PE_SCN_ALIGN_1BYTES;
           2 : result:=result or PE_SCN_ALIGN_2BYTES;
           4 : result:=result or PE_SCN_ALIGN_4BYTES;
           8 : result:=result or PE_SCN_ALIGN_8BYTES;
          16 : result:=result or PE_SCN_ALIGN_16BYTES;
          32 : result:=result or PE_SCN_ALIGN_32BYTES;
          64 : result:=result or PE_SCN_ALIGN_64BYTES;
          else result:=result or PE_SCN_ALIGN_16BYTES;
        end;
      end;


    procedure pedecodesechdrflags(const aname:string;flags:longword;out aoptions:TObjSectionOptions;out aalign:shortint);
      var
        alignflag : longword;
      begin
        aoptions:=[];
        aalign:=sizeof(aint);
        if flags and PE_SCN_CNT_CODE<>0 then
          include(aoptions,oso_executable);
        if flags and PE_SCN_MEM_DISCARDABLE<>0 then
          include(aoptions,oso_debug);
        if flags and PE_SCN_CNT_UNINITIALIZED_DATA=0 then
          include(aoptions,oso_data);
        if flags and PE_SCN_LNK_REMOVE<>0 then
          include(aoptions,oso_noload)
        else
          include(aoptions,oso_load);
        { read/write }
        if flags and PE_SCN_MEM_WRITE<>0 then
          include(aoptions,oso_write)
        else
          include(aoptions,oso_readonly);
        { alignment }
        alignflag:=flags and PE_SCN_ALIGN_MASK;
        if alignflag=PE_SCN_ALIGN_64BYTES then
          aalign:=64
        else if alignflag=PE_SCN_ALIGN_32BYTES then
          aalign:=32
        else if alignflag=PE_SCN_ALIGN_16BYTES then
          aalign:=16
        else if alignflag=PE_SCN_ALIGN_8BYTES then
          aalign:=8
        else if alignflag=PE_SCN_ALIGN_4BYTES then
          aalign:=4
        else if alignflag=PE_SCN_ALIGN_2BYTES then
          aalign:=2
        else if alignflag=PE_SCN_ALIGN_1BYTES then
          aalign:=1;
      end;


{****************************************************************************
                               TCoffObjSection
****************************************************************************}

    constructor TCoffObjSection.create(const aname:string;aalign:longint;aoptions:TObjSectionOptions);
      begin
        inherited create(aname,aalign,aoptions);
      end;


    procedure TCoffObjSection.addsymsizereloc(ofs:longint;p:tasmsymbol;size:longint;relative:TObjRelocationType);
      begin
        relocations.concat(TObjRelocation.createsymbolsize(ofs,p,size,relative));
      end;


    procedure TCoffObjSection.fixuprelocs;
      var
        r : TObjRelocation;
        address,
        relocval : longint;
      begin
        r:=TObjRelocation(relocations.first);
        if assigned(r) and
           (not assigned(data)) then
          internalerror(200205183);
        while assigned(r) do
          begin
            if not(assigned(r.symbol) and assigned(r.symbol.objsection)) then
              internalerror(200205183);
            relocval:=r.symbol.address;
            data.Seek(r.dataoffset);
            data.Read(address,4);
            case r.typ of
              RELOC_RELATIVE  :
                begin
                  address:=address-mempos+relocval;
                  if TCoffObjData(objdata).win32 then
                    dec(address,r.dataoffset+4);
                end;
              RELOC_RVA :
                begin
                  { fixup address when the symbol was known in defined object }
                  if (r.symbol.objsection.objdata=objdata) then
                    dec(address,TCoffObjSection(r.symbol.objsection).orgmempos);
                  inc(address,relocval);
                end;
              RELOC_ABSOLUTE :
                begin
                  if oso_common in r.symbol.objsection.secoptions then
                    dec(address,r.orgsize)
                  else
                    begin
                      { fixup address when the symbol was known in defined object }
                      if (r.symbol.objsection.objdata=objdata) then
                        dec(address,TCoffObjSection(r.symbol.objsection).orgmempos);
                    end;
                  inc(address,relocval);
                  inc(address,r.symbol.objsection.objdata.imagebase);
                end;
            end;
            data.Seek(r.dataoffset);
            data.Write(address,4);
            { goto next reloc }
            r:=TObjRelocation(r.next);
          end;
      end;



{****************************************************************************
                               TDJCoffObjSection
****************************************************************************}

    constructor TDJCoffObjSection.create(const aname:string;aalign:longint;aoptions:TObjSectionOptions);
      begin
        inherited create(aname,aalign,aoptions);
      end;


{****************************************************************************
                               TPECoffObjSection
****************************************************************************}

    constructor TPECoffObjSection.create(const aname:string;aalign:longint;aoptions:TObjSectionOptions);
      begin
        inherited create(aname,aalign,aoptions);
      end;


{****************************************************************************
                                TCoffObjData
****************************************************************************}

    constructor TCoffObjData.createcoff(const n:string;awin32:boolean;acObjSection:TObjSectionClass);
      begin
        inherited create(n);
        CObjSection:=ACObjSection;
        win32:=awin32;
        { we need at least the following 3 ObjSections }
        createsection(sec_code,'');
        createsection(sec_data,'');
        createsection(sec_bss,'');
      end;


    destructor TCoffObjData.destroy;
      begin
        inherited destroy;
      end;


    function TCoffObjData.sectionname(atype:TAsmSectiontype;const aname:string):string;
      var
        secname : string;
      begin
        secname:=coffsecnames[atype];
        if use_smartlink_section and
           (aname<>'') then
          result:=secname+'$'+aname
        else
          result:=secname;
      end;


    procedure TCoffObjData.CreateDebugSections;
      begin
        stabssec:=createsection(sec_stab,'');
        stabstrsec:=createsection(sec_stabstr,'');
      end;


    procedure TCoffObjData.writesymbol(p:tasmsymbol);
      begin
        if CurrObjSec=nil then
          internalerror(200403071);
        { already written ? }
        if p.indexnr<>-1 then
         exit;
        { calculate symbol index }
        if (p.currbind<>AB_LOCAL) then
         begin
           { insert the symbol in the local index, the indexarray
             will take care of the numbering }
           ObjSymbols.insert(p);
         end
        else
         p.indexnr:=-2; { local }
      end;


    procedure TCoffObjData.writereloc(data,len:aint;p:tasmsymbol;relative:TObjRelocationType);
      var
        curraddr,
        symaddr : longint;
      begin
        if CurrObjSec=nil then
          internalerror(200403072);
        if assigned(p) then
         begin
           { current address }
           curraddr:=CurrObjSec.mempos+CurrObjSec.datasize;
           { external/common ObjSymbols don't have a fixed memory position yet }
           if (p.currbind=AB_COMMON) then
             begin
               { For go32v2 we need to use the size as address }
               if not win32 then
                 symaddr:=p.size
               else
                 symaddr:=0;
             end
           else
             begin
               symaddr:=p.memoffset;
               if assigned(p.objsection) then
                 inc(symaddr,p.objsection.mempos);
             end;
           { no symbol relocation need inside a section }
           if (p.objsection=CurrObjSec) and
              (p.currbind<>AB_COMMON) then
             begin
               case relative of
                 RELOC_ABSOLUTE :
                   begin
                     CurrObjSec.addsectionreloc(curraddr,CurrObjSec,RELOC_ABSOLUTE);
                     inc(data,symaddr);
                   end;
                 RELOC_RELATIVE :
                   begin
                     inc(data,symaddr-len-CurrObjSec.datasize);
                   end;
                 RELOC_RVA :
                   begin
                     CurrObjSec.addsectionreloc(curraddr,CurrObjSec,RELOC_RVA);
                     inc(data,symaddr);
                   end;
               end;
             end
           else
             begin
               writesymbol(p);
               if (p.objsection<>nil) and
                  (p.currbind<>AB_COMMON) and
                  (relative<>RELOC_RELATIVE) then
                 CurrObjSec.addsectionreloc(curraddr,p.objsection,relative)
               else
                 CurrObjSec.addsymreloc(curraddr,p,relative);
               if (not win32) or
                  ((relative<>RELOC_RELATIVE) and (p.objsection<>nil)) then
                 inc(data,symaddr);
               if relative=RELOC_RELATIVE then
                begin
                  if win32 then
                    dec(data,len-4)
                  else
                    dec(data,len+CurrObjSec.datasize);
                end;
            end;
         end;
        CurrObjSec.write(data,len);
      end;


    procedure TCoffObjData.writestab(offset:aint;ps:tasmsymbol;nidx,nother:byte;ndesc:word;p:pchar);
      var
        stab : TObjStabEntry;
        curraddr : longint;
      begin
        if not assigned(StabsSec) then
          internalerror(200602256);
        { Win32 does not need an offset if a symbol relocation is used }
        if win32 and
           assigned(ps) and
           (ps.currbind<>AB_LOCAL) then
          offset:=0;
        if assigned(p) and (p[0]<>#0) then
          begin
            stab.strpos:=StabStrSec.datasize;
            StabStrSec.write(p^,strlen(p)+1);
          end
        else
          stab.strpos:=0;
        stab.ntype:=nidx;
        stab.ndesc:=ndesc;
        stab.nother:=nother;
        stab.nvalue:=offset;
        StabsSec.write(stab,sizeof(stab));
        if assigned(ps) then
         begin
           writesymbol(ps);
           { current address }
           curraddr:=StabsSec.mempos+StabsSec.datasize;
           if DLLSource and RelocSection then
            { avoid relocation in the .stab section
              because it ends up in the .reloc section instead }
            StabsSec.addsymreloc(curraddr-4,ps,RELOC_RVA)
           else
            StabsSec.addsymreloc(curraddr-4,ps,RELOC_ABSOLUTE);
         end;
      end;


    procedure TCoffObjData.section_mempos(p:tnamedindexitem;arg:pointer);
      begin
        TCoffObjSection(p).memsize:=TCoffObjSection(p).datasize;
        { memory position is in arg }
        if not win32 then
         begin
           TCoffObjSection(p).mempos:=plongint(arg)^;
           inc(plongint(arg)^,TCoffObjSection(p).alignedmemsize);
         end;
      end;


    procedure TCoffObjData.beforealloc;
      begin
        { create stabs Sections if debugging }
        if assigned(StabsSec) then
          begin
            StabsSec.Alloc(sizeof(TObjStabEntry));
            StabStrSec.Alloc(length(SplitFileName(current_module.mainsource^))+2);
          end;
      end;


    procedure TCoffObjData.beforewrite;
      var
        s : string;
      begin
        { create stabs ObjSections if debugging }
        if assigned(StabsSec) then
         begin
           writestab(0,nil,0,0,0,nil);
           { write zero pchar and name together (PM) }
           s:=#0+SplitFileName(current_module.mainsource^)+#0;
           stabstrsec.write(s[1],length(s));
         end;
      end;


    procedure TCoffObjData.afteralloc;
      var
        mempos : longint;
      begin
        { if debug then also count header stab }
        if assigned(StabsSec) then
          begin
            StabsSec.Alloc(sizeof(TObjStabEntry));
            StabStrSec.Alloc(length(SplitFileName(current_module.mainsource^))+2);
          end;
        { calc mempos }
        mempos:=0;
        ObjSections.foreach(@section_mempos,@mempos);
      end;


{****************************************************************************
                                TDJCoffObjData
****************************************************************************}

    constructor TDJCoffObjData.create(const n:string);
      begin
        inherited createcoff(n,false,TDJCoffObjSection);
      end;


{****************************************************************************
                                TPECoffObjData
****************************************************************************}

    constructor TPECoffObjData.create(const n:string);
      begin
        inherited createcoff(n,true,TPECoffObjSection);
      end;


{****************************************************************************
                                TCoffObjOutput
****************************************************************************}

    constructor TCoffObjOutput.createcoff(smart:boolean;awin32:boolean);
      begin
        inherited create(smart);
        win32:=awin32;
      end;


    procedure TCoffObjOutput.write_symbol(const name:string;value:longint;section:smallint;typ,aux:byte);
      var
        sym : coffsymbol;
      begin
        FillChar(sym,sizeof(sym),0);
        { symbolname }
        if length(name)>8 then
          begin
            sym.strpos:=FCoffStrs.size+4;
            FCoffStrs.writestr(name);
            FCoffStrs.writestr(#0);
          end
        else
          move(name[1],sym.name,length(name));
        sym.value:=value;
        sym.section:=section;
        sym.typ:=typ;
        sym.aux:=aux;
        FWriter.write(sym,sizeof(sym));
      end;


    procedure TCoffObjOutput.section_write_symbol(p:tnamedindexitem;arg:pointer);
      var
        secrec : coffsectionrec;
      begin
        write_symbol(TObjSection(p).name,TObjSection(p).mempos,TObjSection(p).secsymidx,3,1);
        fillchar(secrec,sizeof(secrec),0);
        secrec.len:=TObjSection(p).aligneddatasize;
        secrec.nrelocs:=TObjSection(p).relocations.count;
        FWriter.write(secrec,sizeof(secrec));
      end;


    procedure TCoffObjOutput.section_write_relocs(p:tnamedindexitem;arg:pointer);
      var
        rel  : coffreloc;
        r    : TObjRelocation;
      begin
        r:=TObjRelocation(TObjSection(p).relocations.first);
        while assigned(r) do
         begin
           rel.address:=r.dataoffset;
           if assigned(r.symbol) then
            begin
              if (r.symbol.currbind=AB_LOCAL) then
               rel.sym:=2*r.symbol.objsection.secsymidx
              else
               begin
                 if r.symbol.indexnr=-1 then
                   internalerror(200602233);
                 { indexnr starts with 1, coff starts with 0 }
                 rel.sym:=r.symbol.indexnr+initsym-1;
               end;
            end
           else
            begin
              if r.objsection<>nil then
               rel.sym:=2*r.objsection.secsymidx
              else
               rel.sym:=0;
            end;
           case r.typ of
             RELOC_RELATIVE :
               rel.relative:=$14;
             RELOC_ABSOLUTE :
               rel.relative:=$6;
             RELOC_RVA :
               rel.relative:=$7;
           end;
           FWriter.write(rel,sizeof(rel));
           r:=TObjRelocation(r.next);
         end;
      end;


    procedure TCoffObjOutput.write_ObjSymbols(data:TObjData);
      var
        filename  : string[18];
        sectionval,
        globalval,
        value     : longint;
        p         : tasmsymbol;
      begin
        with TCoffObjData(data) do
         begin
           { The `.file' record, and the file name auxiliary record }
           write_symbol('.file', 0, -2, $67, 1);
           fillchar(filename,sizeof(filename),0);
           filename:=SplitFileName(current_module.mainsource^);
           FWriter.write(filename[1],sizeof(filename)-1);
           { The section records, with their auxiliaries, also store the
             symbol index }
           ObjSections.foreach(@section_write_symbol,nil);
           { The ObjSymbols used }
           p:=Tasmsymbol(ObjSymbols.First);
           while assigned(p) do
            begin
              if assigned(p.objsection) and
                 (p.currbind<>AB_COMMON) then
               sectionval:=p.objsection.secsymidx
              else
               sectionval:=0;
              if p.currbind=AB_LOCAL then
               globalval:=3
              else
               globalval:=2;
              { if local of global then set the section value to the address
                of the symbol }
              if p.currbind in [AB_LOCAL,AB_GLOBAL] then
               value:=p.address
              else
               value:=p.size;
              { symbolname }
              write_symbol(p.name,value,sectionval,globalval,0);
              p:=tasmsymbol(p.indexnext);
            end;
         end;
      end;


    procedure TCoffObjOutput.section_set_secsymidx(p:tnamedindexitem;arg:pointer);
      begin
        inc(plongint(arg)^);
        TObjSection(p).secsymidx:=plongint(arg)^;
      end;


    procedure TCoffObjOutput.section_set_datapos(p:tnamedindexitem;arg:pointer);
      begin
        TObjSection(p).datapos:=plongint(arg)^;
        if (oso_data in TObjSection(p).secoptions) then
          inc(plongint(arg)^,TObjSection(p).aligneddatasize);
      end;


    procedure TCoffObjOutput.section_set_reloc_datapos(p:tnamedindexitem;arg:pointer);
      begin
        TCoffObjSection(p).coffrelocpos:=plongint(arg)^;
        inc(plongint(arg)^,sizeof(coffreloc)*TObjSection(p).relocations.count);
      end;


    procedure TCoffObjOutput.section_write_header(p:tnamedindexitem;arg:pointer);
      var
        sechdr   : coffsechdr;
        s        : string;
        strpos   : longint;
      begin
        with TCoffObjSection(p) do
          begin
            fillchar(sechdr,sizeof(sechdr),0);
            s:=name;
            if length(s)>8 then
             begin
               strpos:=FCoffStrs.size+4;
               FCoffStrs.writestr(s);
               FCoffStrs.writestr(#0);
               s:='/'+ToStr(strpos);
             end;
            move(s[1],sechdr.name,length(s));
            if not win32 then
              begin
                sechdr.rvaofs:=mempos;
                sechdr.vsize:=mempos;
              end
            else
              begin
                if not(oso_data in secoptions) then
                  sechdr.vsize:=aligneddatasize;
              end;
            sechdr.datasize:=aligneddatasize;
            if (datasize>0) and
               (oso_data in secoptions) then
              sechdr.datapos:=datapos;
            sechdr.nrelocs:=relocations.count;
            sechdr.relocpos:=coffrelocpos;
            if win32 then
              sechdr.flags:=peencodesechdrflags(secoptions,secalign)
            else
              sechdr.flags:=djencodesechdrflags(secoptions);
            FWriter.write(sechdr,sizeof(sechdr));
          end;
      end;


    procedure TCoffObjOutput.section_write_data(p:tnamedindexitem;arg:pointer);
      begin
        if oso_data in TObjSection(p).secoptions then
          begin
            TObjSection(p).alignsection;
            FWriter.writearray(TObjSection(p).data);
          end;
      end;


    function TCoffObjOutput.writedata(data:TObjData):boolean;
      var
        orgdatapos,
        datapos,
        nsects,
        sympos,i : longint;
        hstab    : TObjStabEntry;
        gotreloc : boolean;
        header   : coffheader;
        empty    : array[0..15] of byte;
        hp       : pdynamicblock;
        s        : string;
      begin
        result:=false;
        FCoffStrs:=TDynamicArray.Create(strsresize);
        with TCoffObjData(data) do
         begin
         { calc amount of ObjSections we have }
           fillchar(empty,sizeof(empty),0);
           nsects:=0;
           ObjSections.foreach(@section_set_secsymidx,@nsects);
           initsym:=2+nsects*2;   { 2 for the file }
         { For the stab section we need an HdrSym which can now be
           calculated more easily }
           if assigned(StabsSec) then
            begin
              { header stab }
              s:=#0+SplitFileName(current_module.mainsource^)+#0;
              stabstrsec.write(s[1],length(s));
              hstab.strpos:=1;
              hstab.ntype:=0;
              hstab.nother:=0;
              hstab.ndesc:=(StabsSec.datasize div sizeof(TObjStabEntry))-1{+1 according to gas output PM};
              hstab.nvalue:=StabStrSec.datasize;
              StabsSec.data.seek(0);
              StabsSec.data.write(hstab,sizeof(hstab));
            end;
         { Calculate the filepositions }
           datapos:=sizeof(coffheader)+sizeof(coffsechdr)*nsects;
           { ObjSections first }
           ObjSections.foreach(@section_set_datapos,@datapos);
           { relocs }
           orgdatapos:=datapos;
           ObjSections.foreach(@section_set_reloc_datapos,@datapos);
           gotreloc:=(orgdatapos<>datapos);
           { ObjSymbols }
           sympos:=datapos;
         { COFF header }
           fillchar(header,sizeof(coffheader),0);
           header.mach:=COFF_MAGIC;
           header.nsects:=nsects;
           header.sympos:=sympos;
           header.syms:=ObjSymbols.count+initsym;
           if win32 then
             begin
               header.flag:=PE_FILE_BYTES_REVERSED_LO or PE_FILE_32BIT_MACHINE or
                            PE_FILE_LINE_NUMS_STRIPPED or PE_FILE_LOCAL_SYMS_STRIPPED;
               if not gotreloc then
                 header.flag:=header.flag or PE_FILE_RELOCS_STRIPPED;
             end
           else
             begin
               header.flag:=COFF_FLAG_AR32WR or COFF_FLAG_NOLINES or COFF_FLAG_NOLSYMS;
               if not gotreloc then
                 header.flag:=header.flag or COFF_FLAG_NORELOCS;
             end;
           FWriter.write(header,sizeof(header));
         { Section headers }
           ObjSections.foreach(@section_write_header,nil);
         { ObjSections }
           ObjSections.foreach(@section_write_data,nil);
           { Relocs }
           ObjSections.foreach(@section_write_relocs,nil);
           { ObjSymbols }
           write_ObjSymbols(data);
           { Strings }
           i:=FCoffStrs.size+4;
           FWriter.write(i,4);
           hp:=FCoffStrs.firstblock;
           while assigned(hp) do
            begin
              FWriter.write(hp^.data,hp^.used);
              hp:=hp^.next;
            end;
         end;
        FCoffStrs.Free;
      end;


    constructor TDJCoffObjOutput.create(smart:boolean);
      begin
        inherited createcoff(smart,false);
        cobjdata:=TDJCoffObjData;
      end;


    constructor TPECoffObjOutput.create(smart:boolean);
      begin
        inherited createcoff(smart,true);
        cobjdata:=TPECoffObjData;
      end;

{****************************************************************************
                              TCoffexesection
****************************************************************************}


    constructor TCoffExeSection.createcoff(const n:string;awin32:boolean);
      begin
        inherited create(n);
        win32:=awin32;
      end;


    constructor TDJCoffExeSection.create(const n:string);
      begin
        inherited createcoff(n,false);
      end;


    constructor TPECoffExeSection.create(const n:string);
      begin
        inherited createcoff(n,false);
      end;


{****************************************************************************
                              TCoffexeoutput
****************************************************************************}

    constructor TCoffexeoutput.createcoff(awin32:boolean);
      begin
        inherited create;
        win32:=awin32;
        if win32 then
          imagebase:=$400000;
      end;


    procedure TCoffexeoutput.write_symbol(const name:string;value:longint;section:smallint;typ,aux:byte);
      var
        sym : coffsymbol;
      begin
        FillChar(sym,sizeof(sym),0);
        if length(name)>8 then
          begin
             sym.strpos:=FCoffStrs.size+4;
             FCoffStrs.writestr(name);
             FCoffStrs.writestr(#0);
          end
        else
          move(name[1],sym.name,length(name));
        sym.value:=value;
        sym.section:=section;
        sym.typ:=typ;
        sym.aux:=aux;
        FWriter.write(sym,sizeof(sym));
      end;


    procedure TCoffexeoutput.globalsyms_write_symbol(p:tnamedindexitem;arg:pointer);
      var
        value,
        globalval : longint;
        exesec : TExeSection;
      begin
        with texesymbol(p).objsymbol do
          begin
            exesec:=TExeSection(objsection.exesection);
            if not assigned(exesec) then
              internalerror(200602255);
            if currbind=AB_LOCAL then
              globalval:=3
            else
              globalval:=2;
            { Relative address to the section in the executable }
            value:=address-exesec.mempos;
            write_symbol(name,value,exesec.secsymidx,globalval,0);
          end;
      end;


    procedure TCoffexeoutput.ExeSections_write_header(p:tnamedindexitem;arg:pointer);
      var
        sechdr    : coffsechdr;
      begin
        with tExeSection(p) do
          begin
            fillchar(sechdr,sizeof(sechdr),0);
            move(name[1],sechdr.name,length(name));
            sechdr.rvaofs:=mempos;
            sechdr.vsize:=mempos;
            if win32 then
              begin
                sechdr.rvaofs:=mempos;
                sechdr.vsize:=align(memsize,$100);
              end
            else
              begin
                sechdr.rvaofs:=mempos;
                sechdr.vsize:=mempos;
              end;
            if oso_data in SecOptions then
              begin
                sechdr.datasize:=datasize;
                sechdr.datapos:=datapos;
              end
            else
              sechdr.datasize:=memsize;
            sechdr.nrelocs:=0;
            sechdr.relocpos:=0;
            if win32 then
              sechdr.flags:=peencodesechdrflags(SecOptions,SecAlign)
            else
              sechdr.flags:=djencodesechdrflags(SecOptions);
            FWriter.write(sechdr,sizeof(sechdr));
          end;
      end;


    procedure TCoffexeoutput.ExeSections_pass2_header(p:tnamedindexitem;arg:pointer);
      begin
        with TExeSection(p) do
          begin
            inc(plongint(arg)^);
            secsymidx:=plongint(arg)^;
          end;
      end;


    procedure Tcoffexeoutput.ExeSections_write_Data(p:tnamedindexitem;arg:pointer);
      var
        objsec : TObjSection;
        i      : longint;
        hstab  : TObjStabEntry;
      begin
        with texesection(p) do
          begin
            if (oso_data in secoptions) then
              begin
                FWriter.Writezeros(Align(FWriter.Size,SectionDataAlign)-FWriter.Size);
                if DataPos<>FWriter.Size then
                  internalerror(200602251);

                { For the stab section we need an HdrSym }
                if name='.stab' then
                  begin
                    hstab.strpos:=1;
                    hstab.ntype:=0;
                    hstab.nother:=0;
                    hstab.ndesc:=(datasize div sizeof(TObjStabEntry))-1;
                    hstab.nvalue:=1;
                    FWriter.write(hstab,sizeof(hstab));
                  end;

                for i:=0 to ObjSectionList.Count-1 do
                  begin
                    objsec:=TObjSection(ObjSectionList[i]);
                    FWriter.writezeros(objsec.dataalignbytes);
                    FWriter.writearray(objsec.data);
                    FWriter.writezeros(objsec.aligneddatasize-objsec.datasize);
                  end;
              end;
          end;
      end;


    procedure tcoffexeoutput.Pass2_Header;
      var
        stubsize,
        optheadersize : longint;
      begin
        if win32 then
          begin
            stubsize:=sizeof(win32stub);
            optheadersize:=sizeof(coffpeoptheader);
          end
        else
          begin
            stubsize:=sizeof(go32v2stub);
            optheadersize:=sizeof(coffdjoptheader);
          end;
        { retrieve amount of ObjSections }
        nsects:=0;
        ExeSections.foreach(@ExeSections_pass2_header,@nsects);
        { calculate start positions after the headers }
        currdatapos:=stubsize+optheadersize+sizeof(coffsechdr)*nsects;
        currmempos:=stubsize+optheadersize+sizeof(coffsechdr)*nsects;
      end;


    procedure tcoffexeoutput.Pass2_Symbols;
      begin
        nsyms:=0;
        sympos:=0;
        if not(cs_link_strip in aktglobalswitches) then
         begin
           nsyms:=GlobalExeSymbols.count;
           sympos:=CurrDataPos;
           inc(CurrDataPos,sizeof(coffsymbol)*nsyms);
         end;
      end;


    function TCoffexeoutput.writedata:boolean;
      var
        i           : longint;
        header      : coffheader;
        djoptheader : coffdjoptheader;
        peoptheader : coffpeoptheader;
        idataexesec,
        textExeSec,
        dataExeSec,
        bssExeSec   : TExeSection;
      begin
        result:=false;
        FCoffSyms:=TDynamicArray.Create(symbolresize);
        FCoffStrs:=TDynamicArray.Create(strsresize);
        textExeSec:=FindExeSection('.text');
        dataExeSec:=FindExeSection('.data');
        bssExeSec:=FindExeSection('.bss');
        if not assigned(TextExeSec) or
           not assigned(DataExeSec) or
           not assigned(BSSExeSec) then
          internalerror(200602231);
        { Stub }
        if win32 then
          FWriter.write(win32stub,sizeof(win32stub))
        else
          FWriter.write(go32v2stub,sizeof(go32v2stub));
        { COFF header }
        fillchar(header,sizeof(header),0);
        header.mach:=COFF_MAGIC;
        header.nsects:=nsects;
        header.sympos:=sympos;
        header.syms:=nsyms;
        if win32 then
          header.opthdr:=sizeof(coffpeoptheader)
        else
          header.opthdr:=sizeof(coffdjoptheader);
        if win32 then
          begin
            header.flag:=PE_FILE_EXECUTABLE_IMAGE or PE_FILE_RELOCS_STRIPPED or
                         {PE_FILE_BYTES_REVERSED_LO or }PE_FILE_32BIT_MACHINE or
                         PE_FILE_LINE_NUMS_STRIPPED;
            if FindExeSection('.stab')=nil then
              header.flag:=header.flag or PE_FILE_DEBUG_STRIPPED;
            if (cs_link_strip in aktglobalswitches) then
              header.flag:=header.flag or PE_FILE_LOCAL_SYMS_STRIPPED;
          end
        else
          header.flag:=COFF_FLAG_AR32WR or COFF_FLAG_EXE or COFF_FLAG_NORELOCS or COFF_FLAG_NOLINES;
        FWriter.write(header,sizeof(header));
        { Optional COFF Header }
        if win32 then
          begin
            fillchar(peoptheader,sizeof(peoptheader),0);
            peoptheader.magic:=$10b;
            peoptheader.tsize:=TextExeSec.memsize;
            peoptheader.dsize:=DataExeSec.memsize;
            peoptheader.bsize:=BSSExeSec.memsize;
            peoptheader.text_start:=TextExeSec.mempos;
            peoptheader.data_start:=DataExeSec.mempos;
            peoptheader.entry:=EntrySym.Address;
            peoptheader.ImageBase:=ImageBase;
            peoptheader.SectionAlignment:=SectionMemAlign;
            peoptheader.FileAlignment:=SectionDataAlign;
            peoptheader.MajorOperatingSystemVersion:=4;
            peoptheader.MinorOperatingSystemVersion:=0;
            peoptheader.MajorImageVersion:=1;
            peoptheader.MinorImageVersion:=0;
            peoptheader.MajorSubsystemVersion:=4;
            peoptheader.MinorSubsystemVersion:=0;
            peoptheader.Win32Version:=0;
            peoptheader.SizeOfImage:=Align(CurrMemPos,SectionMemAlign);
            peoptheader.SizeOfHeaders:=textExeSec.DataPos;
// TODO                         0000b7b1
            peoptheader.CheckSum:=0;
{$warning TODO GUI/CUI Subsystem}
            peoptheader.Subsystem:=3;
            peoptheader.DllCharacteristics:=0;
            peoptheader.SizeOfStackReserve:=$40000;
            peoptheader.SizeOfStackCommit:=$1000;
            peoptheader.SizeOfHeapReserve:=$100000;
            peoptheader.SizeOfHeapCommit:=$1000;
            peoptheader.LoaderFlags:=0;
            peoptheader.NumberOfRvaAndSizes:=PE_DATADIR_ENTRIES;
            idataexesec:=FindExeSection('.idata');
            if assigned(idataexesec) then
              begin
                peoptheader.DataDirectory[PE_DATADIR_IDATA].vaddr:=idataexesec.mempos;
                peoptheader.DataDirectory[PE_DATADIR_IDATA].size:=idataexesec.memsize;
              end;
            FWriter.write(peoptheader,sizeof(peoptheader));
          end
        else
          begin
            fillchar(djoptheader,sizeof(djoptheader),0);
            djoptheader.magic:=$10b;
            djoptheader.tsize:=TextExeSec.memsize;
            djoptheader.dsize:=DataExeSec.memsize;
            djoptheader.bsize:=BSSExeSec.memsize;
            djoptheader.text_start:=TextExeSec.mempos;
            djoptheader.data_start:=DataExeSec.mempos;
            djoptheader.entry:=EntrySym.memoffset;
            FWriter.write(djoptheader,sizeof(djoptheader));
          end;
        { Section headers }
        ExeSections.foreach(@ExeSections_write_header,nil);
        { Section data }
        ExeSections.foreach(@ExeSections_write_data,nil);
        { Optional ObjSymbols }
        if not(cs_link_strip in aktglobalswitches) then
         begin
           if SymPos<>FWriter.Size then
             internalerror(200602252);
           { ObjSymbols }
           globalexesymbols.foreach(@globalsyms_write_symbol,nil);
           { Strings }
           i:=FCoffStrs.size+4;
           FWriter.write(i,4);
           FWriter.writearray(FCoffStrs);
         end;
        { Release }
        FCoffStrs.Free;
        FCoffSyms.Free;
        result:=true;
      end;


    constructor TDJCoffexeoutput.create;
      begin
        inherited createcoff(false);
        CExeSection:=TDJCoffExeSection;
        CObjData:=TPECoffObjData;
      end;


    constructor TPECoffexeoutput.create;
      begin
        inherited createcoff(true);
        CExeSection:=TPECoffExeSection;
        CObjData:=TPECoffObjData;
      end;


{****************************************************************************
                                TCoffObjInput
****************************************************************************}

    constructor TCoffObjInput.createcoff(awin32:boolean);
      begin
        inherited create;
        win32:=awin32;
      end;


    procedure TCoffObjInput.read_relocs(s:TCoffObjSection);
      var
        rel      : coffreloc;
        rel_type : TObjRelocationType;
        i        : longint;
        p        : tasmsymbol;
      begin
        for i:=1 to s.coffrelocs do
         begin
           FReader.read(rel,sizeof(rel));
           case rel.relative of
             $14 : rel_type:=RELOC_RELATIVE;
             $06 : rel_type:=RELOC_ABSOLUTE;
             $07 : rel_type:=RELOC_RVA;
           else
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           end;

           p:=FSymTbl^[rel.sym].sym;
           if assigned(p) then
            begin
              s.addsymsizereloc(rel.address-s.mempos,p,FSymTbl^[rel.sym].orgsize,rel_type);
            end
           else
            begin
              Comment(V_Error,'Error reading coff file');
              exit;
            end;
         end;
      end;


    procedure TCoffObjInput.handle_ObjSymbols(data:TObjData);
      var
        size,
        address   : aint;
        i,nsyms,
        symidx    : longint;
        sym       : coffsymbol;
        strname   : string;
        p         : tasmsymbol;
        bind      : Tasmsymbind;
        auxrec    : array[0..17] of byte;
        objsec    : TObjSection;
      begin
        with TCoffObjData(data) do
         begin
           nsyms:=FCoffSyms.Size div sizeof(CoffSymbol);
           { Allocate memory for symidx -> tasmsymbol table }
           GetMem(FSymTbl,nsyms*sizeof(ttasmsymbolrec));
           FillChar(FSymTbl^,nsyms*sizeof(ttasmsymbolrec),0);
           { Loop all ObjSymbols }
           FCoffSyms.Seek(0);
           symidx:=0;
           while (symidx<nsyms) do
            begin
              FCoffSyms.Read(sym,sizeof(sym));
              if plongint(@sym.name)^<>0 then
               begin
                 move(sym.name,strname[1],8);
                 strname[9]:=#0;
               end
              else
               begin
                 FCoffStrs.Seek(sym.strpos-4);
                 FCoffStrs.Read(strname[1],255);
                 strname[255]:=#0;
               end;
              strname[0]:=chr(strlen(@strname[1]));
              if strname='' then
               Internalerror(200205172);
              bind:=AB_EXTERNAL;
              size:=0;
              address:=0;
              case sym.typ of
                COFF_SYM_GLOBAL :
                  begin
                    if sym.section=0 then
                     begin
                       if sym.value=0 then
                        bind:=AB_EXTERNAL
                       else
                        begin
                          bind:=AB_COMMON;
                          size:=sym.value;
                        end;
                     end
                    else
                     begin
                       bind:=AB_GLOBAL;
                       objsec:=Fidx2objsec[sym.section];
                       if sym.value>=objsec.mempos then
                         address:=sym.value-objsec.mempos;
                     end;
                    p:=TAsmSymbol.Create(strname,bind,AT_FUNCTION);
                    p.SetAddress(0,objsec,address,size);
                    ObjSymbols.insert(p);
                  end;
                COFF_SYM_LABEL,
                COFF_SYM_LOCAL :
                  begin
                    { do not add constants (section=-1) }
                    if sym.section<>-1 then
                     begin
                       bind:=AB_LOCAL;
                       objsec:=Fidx2objsec[sym.section];
                       if sym.value>=objsec.mempos then
                         address:=sym.value-objsec.mempos;
                       p:=TAsmSymbol.Create(strname,bind,AT_FUNCTION);
                       p.SetAddress(0,objsec,address,size);
                       ObjSymbols.insert(p);
                     end;
                  end;
                COFF_SYM_SECTION,
                COFF_SYM_FUNCTION,
                COFF_SYM_FILE :
                  ;
                else
                  internalerror(200602232);
              end;
              FSymTbl^[symidx].sym:=p;
              FSymTbl^[symidx].orgsize:=size;
              { read aux records }
              for i:=1 to sym.aux do
               begin
                 FCoffSyms.Read(auxrec,sizeof(auxrec));
                 inc(symidx);
               end;
              inc(symidx);
            end;
         end;
      end;


    procedure TCoffObjInput.ObjSections_read_data(p:tnamedindexitem;arg:pointer);
      begin
        with TCoffObjSection(p) do
          begin
            if oso_data in secoptions then
              begin
                Reader.Seek(datapos);
                if not Reader.ReadArray(data,datasize) then
                  begin
                    Comment(V_Error,'Error reading coff file');
                    exit;
                  end;
              end;
          end;
      end;


    procedure TCoffObjInput.ObjSections_read_relocs(p:tnamedindexitem;arg:pointer);
      begin
        with TCoffObjSection(p) do
          begin
            if coffrelocs>0 then
             begin
               Reader.Seek(coffrelocpos);
               read_relocs(TCoffObjSection(p));
             end;
          end;
      end;


    function  TCoffObjInput.readObjData(data:TObjData):boolean;
      var
        secalign : shortint;
        strsize,
        i        : longint;
        objsec   : TCoffObjSection;
        secoptions : TObjSectionOptions;
        header   : coffheader;
        sechdr   : coffsechdr;
        secname  : string;
        secnamebuf : array[0..15] of char;
      begin
        result:=false;
        FCoffSyms:=TDynamicArray.Create(symbolresize);
        FCoffStrs:=TDynamicArray.Create(strsresize);
        with TCoffObjData(data) do
         begin
           FillChar(Fidx2objsec,sizeof(Fidx2objsec),0);
           { Read COFF header }
           if not reader.read(header,sizeof(coffheader)) then
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           if header.mach<>COFF_MAGIC then
             begin
               Comment(V_Error,'Not a coff file');
               exit;
             end;
           if header.nsects>255 then
             begin
               Comment(V_Error,'To many ObjSections');
               exit;
             end;
{$warning TODO Read strings first}
           { Section headers }
           for i:=1 to header.nsects do
             begin
               if not reader.read(sechdr,sizeof(sechdr)) then
                begin
                  Comment(V_Error,'Error reading coff file');
                  exit;
                end;
{$warning TODO Support long secnames}
               move(sechdr.name,secnamebuf,8);
               secnamebuf[8]:=#0;
               secname:=strpas(secnamebuf);
 {$warning TODO Alignment}
               if win32 then
                 pedecodesechdrflags(secname,sechdr.flags,secoptions,secalign)
               else
                 begin
                   djdecodesechdrflags(secname,sechdr.flags);
                   secalign:=sizeof(aint);
                 end;
               objsec:=TCoffObjSection(createsection(secname,secalign,secoptions));
               Fidx2objsec[i]:=objsec;
               if not win32 then
                 objsec.mempos:=sechdr.rvaofs;
               objsec.orgmempos:=sechdr.rvaofs;
               objsec.coffrelocs:=sechdr.nrelocs;
               objsec.coffrelocpos:=sechdr.relocpos;
               objsec.datapos:=sechdr.datapos;
               objsec.datasize:=sechdr.datasize;
               objsec.memsize:=sechdr.datasize;
             end;
           { ObjSymbols }
           Reader.Seek(header.sympos);
           if not Reader.ReadArray(FCoffSyms,header.syms*sizeof(CoffSymbol)) then
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           { Strings }
           if not Reader.Read(strsize,4) then
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           if strsize<4 then
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           if not Reader.ReadArray(FCoffStrs,Strsize-4) then
             begin
               Comment(V_Error,'Error reading coff file');
               exit;
             end;
           { Insert all ObjSymbols }
           handle_ObjSymbols(data);
           { Section Data }
           ObjSections.foreach(@objsections_read_data,nil);
           { Relocs }
           ObjSections.foreach(@objsections_read_relocs,nil);
         end;
        FCoffStrs.Free;
        FCoffSyms.Free;
        result:=true;
      end;


    constructor TDJCoffObjInput.create;
      begin
        inherited createcoff(false);
        cobjdata:=TDJCoffObjData;
      end;


    constructor TPECoffObjInput.create;
      begin
        inherited createcoff(true);
        cobjdata:=TPECoffObjData;
      end;


{****************************************************************************
                                 TDJCoffAssembler
****************************************************************************}

    constructor TDJCoffAssembler.Create(smart:boolean);
      begin
        inherited Create(smart);
        CObjOutput:=TDJCoffObjOutput;
      end;


{****************************************************************************
                               TPECoffAssembler
****************************************************************************}

    constructor TPECoffAssembler.Create(smart:boolean);
      begin
        inherited Create(smart);
        CObjOutput:=TPECoffObjOutput;
      end;


{****************************************************************************
                                  TCoffLinker
****************************************************************************}

    constructor TDJCoffLinker.Create;
      begin
        inherited Create;
        CExeoutput:=TDJCoffexeoutput;
        CObjInput:=TDJCoffObjInput;
      end;


    procedure TDJCoffLinker.DefaultLinkScript;
      begin
      end;


    constructor TPECoffLinker.Create;
      begin
        inherited Create;
        CExeoutput:=TPECoffexeoutput;
        CObjInput:=TPECoffObjInput;
      end;


    procedure TPECoffLinker.DefaultLinkScript;
      begin
        with LinkScript do
          begin
            Concat('READUNITOBJECTS');
            Concat('ENTRYNAME _mainCRTStartup');
            Concat('HEADER');
            Concat('EXESECTION .text');
            Concat('  OBJSECTION .text');
            Concat('  SYMBOL etext');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .data');
            Concat('  OBJSECTION .data');
            Concat('  SYMBOL edata');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .idata');
            Concat('  OBJSECTION .idata$2');
            Concat('  OBJSECTION .idata$3');
            Concat('  ZEROS 20');
            Concat('  OBJSECTION .idata$4');
            Concat('  OBJSECTION .idata$5');
            Concat('  OBJSECTION .idata$6');
            Concat('  OBJSECTION .idata$7');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .bss');
            Concat('  OBJSECTION .bss');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .stab');
            Concat('  OBJSECTION .stab');
            Concat('ENDEXESECTION');
            Concat('EXESECTION .stabstr');
            Concat('  OBJSECTION .stabstr');
            Concat('ENDEXESECTION');
            Concat('SYMBOLS');
          end;
      end;


{*****************************************************************************
                                  Initialize
*****************************************************************************}

    const
       as_i386_coff_info : tasminfo =
          (
            id     : as_i386_coff;
            idtxt  : 'COFF';
            asmbin : '';
            asmcmd : '';
            supported_target : system_i386_go32v2;
            flags : [af_outputbinary];
            labelprefix : '.L';
            comment : '';
          );

       as_i386_pecoff_info : tasminfo =
          (
            id     : as_i386_pecoff;
            idtxt  : 'PECOFF';
            asmbin : '';
            asmcmd : '';
            supported_target : system_i386_win32;
            flags : [af_outputbinary,af_smartlink_sections];
            labelprefix : '.L';
            comment : '';
          );

       as_i386_pecoffwdosx_info : tasminfo =
          (
            id     : as_i386_pecoffwdosx;
            idtxt  : 'PEWDOSX';
            asmbin : '';
            asmcmd : '';
            supported_target : system_i386_wdosx;
            flags : [af_outputbinary];
            labelprefix : '.L';
            comment : '';
          );

       as_i386_pecoffwince_info : tasminfo =
          (
            id     : as_i386_pecoffwince;
            idtxt  : 'PECOFFWINCE';
            asmbin : '';
            asmcmd : '';
            supported_target : system_i386_wince;
            flags : [af_outputbinary];
            labelprefix : '.L';
            comment : '';
          );


       as_arm_pecoffwince_info : tasminfo =
          (
            id     : as_arm_pecoffwince;
            idtxt  : 'PECOFFWINCE';
            asmbin : '';
            asmcmd : '';
            supported_target : system_arm_wince;
            flags : [af_outputbinary];
            labelprefix : '.L';
            comment : '';
          );

initialization
{$ifdef i386}
  RegisterAssembler(as_i386_coff_info,TDJCoffAssembler);
  RegisterAssembler(as_i386_pecoff_info,TPECoffAssembler);
  RegisterAssembler(as_i386_pecoffwdosx_info,TPECoffAssembler);
  RegisterAssembler(as_i386_pecoffwince_info,TPECoffAssembler);
{$endif i386}
{$ifdef arm}
  RegisterAssembler(as_arm_pecoffwince_info,TPECoffAssembler);
{$endif arm}
end.
