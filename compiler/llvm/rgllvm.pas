{
    Copyright (c) 2013 by Jonas Maebe, member of the Free Pascal development
    team

    This unit implements the LLVM-specific class for the register
    allocator

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

 ****************************************************************************}
unit rgllvm;

{$i fpcdefs.inc}

  interface

    uses
      aasmcpu,aasmtai,aasmdata,
      symtype,
      cgbase,cgutils,
      cpubase,llvmbase,
      rgobj;

    type
      { trgllvm }
      trgllvm=class(trgobj)
        constructor create(Aregtype: Tregistertype; Adefaultsub: Tsubregister; const Ausable: array of tsuperregister; Afirst_imaginary: Tsuperregister; Apreserved_by_proc: Tcpuregisterset); reintroduce;
        procedure do_register_allocation(list: TAsmList; headertai: tai); override;
        procedure do_spill_read(list: TAsmList; pos: tai; const spilltemp: treference; tempreg: tregister; orgsupreg: tsuperregister); override;
        procedure do_spill_written(list: TAsmList; pos: tai; const spilltemp: treference; tempreg: tregister; orgsupreg: tsuperregister); override;
       protected
        procedure determine_spill_registers(list: TasmList; headertai: tai); override;
        procedure get_spill_temp(list:TAsmlist;spill_temps: Pspill_temp_list; supreg: tsuperregister);override;
       strict protected
       type
         tregwrites = (rw_none, rw_one, rw_multiple);
         pwrittenregs = ^twrittenregs;
         twrittenregs = bitpacked array[tsuperregister] of tregwrites;
       var
        spillcounter: longint;
        writtenregs: pwrittenregs;
      end;


implementation

    uses
      verbose,cutils,
      globtype,globals,
      symdef,
      aasmllvm,
      tgobj;

    { trgllvm }

     constructor trgllvm.create(Aregtype: Tregistertype; Adefaultsub: Tsubregister; const Ausable: array of tsuperregister; Afirst_imaginary: Tsuperregister; Apreserved_by_proc: Tcpuregisterset);
       begin
         inherited;
         { tell the generic register allocator to generate SSA spilling code }
         ssa_safe:=true;
       end;

     procedure trgllvm.do_register_allocation(list: TAsmList; headertai: tai);
      begin
        { these are SSA by design, they're only assigned by alloca
          instructions }
        if regtype=R_TEMPREGISTER then
          exit;
        inherited;
      end;


    procedure trgllvm.do_spill_read(list: TAsmList; pos: tai; const spilltemp: treference; tempreg: tregister; orgsupreg: tsuperregister);
      var
        ins: taillvm;
        def: tdef;
      begin
        def:=tdef(reginfo[orgsupreg].def);
        if not assigned(def) then
          internalerror(2013110803);
        ins:=taillvm.op_reg_size_ref(la_load,tempreg,getpointerdef(def),spilltemp);
        list.insertafter(ins,pos);
        {$ifdef DEBUG_SPILLING}
        list.Insertbefore(tai_comment.Create(strpnew('Spilling: Spill Read')),ins);
        {$endif}
      end;


    procedure trgllvm.do_spill_written(list: TAsmList; pos: tai; const spilltemp: treference; tempreg: tregister; orgsupreg: tsuperregister);
      var
        ins: taillvm;
        def: tdef;
      begin
        def:=tdef(reginfo[orgsupreg].def);
        if not assigned(def) then
          internalerror(2013110802);
        ins:=taillvm.op_size_reg_size_ref(la_store,def,tempreg,getpointerdef(def),spilltemp);
        list.insertafter(ins,pos);
        {$ifdef DEBUG_SPILLING}
        list.Insertbefore(tai_comment.Create(strpnew('Spilling: Spill Write')),ins);
        {$endif}
      end;


     procedure trgllvm.determine_spill_registers(list: TasmList; headertai: tai);
       var
         hp: tai;
         reg: tregister;
         sr: tsuperregister;
         i: longint;
       begin
         spillednodes.clear;
         { there should be only one round of spilling per register type, we
           shouldn't generate multiple writes so a single register here }
         if spillcounter<>0 then
           exit;
         { registers must be in SSA form -> determine all registers that are
           written to more than once }
         hp:=headertai;
         { 2 bits per superregister, rounded up to a byte }
         writtenregs:=allocmem((maxreg*2+7) shr 3);
         while assigned(hp) do
           begin
             case hp.typ of
               ait_llvmins:
                 begin
                   for i:=0 to taillvm(hp).ops-1 do
                     if (taillvm(hp).oper[i]^.typ=top_reg) and
                        (getregtype(taillvm(hp).oper[i]^.reg)=regtype)  and
                        (taillvm(hp).spilling_get_operation_type(i)=operand_write) then
                       begin
                         reg:=taillvm(hp).oper[i]^.reg;
                         sr:=getsupreg(reg);
                         if writtenregs^[sr]<rw_multiple then
                           writtenregs^[sr]:=succ(writtenregs^[sr]);
                       end;
                 end;
             end;
             hp:=tai(hp.next);
           end;
         { add all registers with multiple writes to the spilled nodes }
         for sr:=0 to maxreg-1 do
           if writtenregs^[sr]=rw_multiple then
             spillednodes.add(sr);
         freemem(writtenregs);
       end;


    procedure trgllvm.get_spill_temp(list: TAsmlist; spill_temps: Pspill_temp_list; supreg: tsuperregister);
      var
        supstart: tai;
        i: longint;
        def: tdef;
      begin
        supstart:=live_start[supreg];
        if supstart.typ<>ait_llvmins then
          internalerror(2013110701);
        { determine type of register so we can allocate a temp of the right
          type }
        def:=nil;
        for i:=0 to taillvm(supstart).ops-1 do
          begin
            if (taillvm(supstart).oper[i]^.typ=top_reg) and
               (getsupreg(taillvm(supstart).oper[i]^.reg)=supreg) then
              begin
                def:=taillvm(supstart).spilling_get_reg_type(i);
                break
              end;
          end;
        if not assigned(def) then
          internalerror(2013110702);
        tg.gethltemp(list,def,def.size,tt_noreuse,spill_temps^[supreg]);
        { record for use in spill instructions }
        reginfo[supreg].def:=def;
      end;

end.