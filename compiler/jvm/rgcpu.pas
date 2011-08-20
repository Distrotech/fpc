{
    Copyright (c) 2010 by Jonas Maebe

    This unit implements the JVM specific class for the register
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
unit rgcpu;

{$i fpcdefs.inc}

  interface

    uses
      aasmbase,aasmcpu,aasmtai,aasmdata,
      cgbase,cgutils,
      cpubase,
      rgobj;

    type
      tspilltemps = array[tregistertype] of ^Tspill_temp_list;

      { trgcpu }

      trgcpu=class(trgobj)
       protected
        class function  do_spill_replace_all(list:TAsmList;instr:taicpu;const spilltemps: tspilltemps):boolean;
        class procedure remove_dummy_load_stores(list: TAsmList; headertai: tai);
       public
        { performs the register allocation for *all* register types }
        class procedure do_all_register_allocation(list: TAsmList; headertai: tai);
      end;


implementation

    uses
      verbose,cutils,
      globtype,globals,
      cgobj,
      tgobj;

    { trgcpu }

    class function trgcpu.do_spill_replace_all(list:TAsmList;instr:taicpu;const spilltemps: tspilltemps):boolean;
      var
        l: longint;
        reg: tregister;
      begin
        { jvm instructions never have more than one memory (virtual register)
          operand, so there is no danger of superregister conflicts }
        for l:=0 to instr.ops-1 do
          if instr.oper[l]^.typ=top_reg then
            begin
              reg:=instr.oper[l]^.reg;
              instr.loadref(l,spilltemps[getregtype(reg)]^[getsupreg(reg)]);
            end;
      end;


    class procedure trgcpu.remove_dummy_load_stores(list: TAsmList; headertai: tai);

      function issimpleregstore(p: tai; reg: tregister; doubleprecisionok: boolean): boolean;
        const
          simplestoressp = [a_astore,a_fstore,a_istore];
          simplestoresdp = [a_dstore,a_lstore];
        begin
          result:=
            assigned(p) and
            (p.typ=ait_instruction) and
            ((taicpu(p).opcode in simplestoressp) or
             (doubleprecisionok and
              (taicpu(p).opcode in simplestoresdp))) and
            ((reg=NR_NO) or
             (taicpu(p).oper[0]^.typ=top_reg) and
             (taicpu(p).oper[0]^.reg=reg));
        end;

      function issimpleregload(p: tai; reg: tregister; doubleprecisionok: boolean): boolean;
        const
          simpleloadssp = [a_aload,a_fload,a_iload];
          simpleloadsdp = [a_dload,a_lload];
        begin
          result:=
            assigned(p) and
            (p.typ=ait_instruction) and
            ((taicpu(p).opcode in simpleloadssp) or
             (doubleprecisionok and
              (taicpu(p).opcode in simpleloadsdp))) and
            ((reg=NR_NO) or
             (taicpu(p).oper[0]^.typ=top_reg) and
             (taicpu(p).oper[0]^.reg=reg));
        end;


      function try_remove_alloc_store_dealloc_load(var p: tai; reg: tregister): boolean;
        var
          q: tai;
        begin
          result:=false;
          { check for:
              alloc regx
              store regx
              dealloc regx
              load regx
            and remove. We don't have to check that the load/store
            types match, because they have to for this to be
            valid JVM code }
          if issimpleregstore(tai(p.next),reg,true) and
             assigned(p.next.next) and
             (tai(p.next.next).typ=ait_regalloc) and
             (tai_regalloc(p.next.next).ratype=ra_dealloc) and
             (tai_regalloc(p.next.next).reg=reg) and
             issimpleregload(tai(p.next.next.next),reg,true) then
            begin
              { remove the whole sequence: the allocation }
              q:=Tai(p.next);
              list.remove(p);
              p.free;
              p:=q;
              { the store }
              q:=Tai(p.next);
              list.remove(p);
              p.free;
              p:=q;
              { the dealloc }
              q:=Tai(p.next);
              list.remove(p);
              p.free;
              p:=q;
              { the load }
              q:=Tai(p.next);
              list.remove(p);
              p.free;
              p:=q;
              result:=true;
            end;
        end;


      var
        p: tai;
        reg: tregister;
        removedsomething: boolean;
      begin
        repeat
          removedsomething:=false;
          p:=headertai;
          while assigned(p) do
            begin
              case p.typ of
                ait_regalloc:
                  begin
                    if (tai_regalloc(p).ratype=ra_alloc) then
                      begin
                        reg:=tai_regalloc(p).reg;
                        if try_remove_alloc_store_dealloc_load(p,reg) then
                          begin
                            removedsomething:=true;
                            continue;
                          end;
                        { todo in peephole optimizer:
                            alloc regx // not double precision
                            store regx // not double precision
                            load  regy or memy
                            dealloc regx
                            load regx
                          -> change into
                            load regy or memy
                            swap       // can only handle single precision

                          and then
                            swap
                            <commutative op>
                           -> remove swap
                        }
                      end;
                  end;
              end;
              p:=tai(p.next);
            end;
        until not removedsomething;
      end;


    class procedure trgcpu.do_all_register_allocation(list: TAsmList; headertai: tai);
      var
        spill_temps : tspilltemps;
        templist : TAsmList;
        intrg,
        fprg     : trgcpu;
        p,q      : tai;
        size     : longint;
      begin
        { Since there are no actual registers, we simply spill everything. We
          use tt_regallocator temps, which are not used by the temp allocator
          during code generation, so that we cannot accidentally overwrite
          any temporary values }

        { get references to all register allocators }
        intrg:=trgcpu(cg.rg[R_INTREGISTER]);
        fprg:=trgcpu(cg.rg[R_FPUREGISTER]);
        { determine the live ranges of all registers }
        intrg.insert_regalloc_info_all(list);
        fprg.insert_regalloc_info_all(list);
        { Don't do the actual allocation when -sr is passed }
        if (cs_no_regalloc in current_settings.globalswitches) then
          exit;
        { remove some simple useless store/load sequences }
        remove_dummy_load_stores(list,headertai);
        { allocate room to store the virtual register -> temp mapping }
        spill_temps[R_INTREGISTER]:=allocmem(sizeof(treference)*intrg.maxreg);
        spill_temps[R_FPUREGISTER]:=allocmem(sizeof(treference)*fprg.maxreg);
        { List to insert temp allocations into }
        templist:=TAsmList.create;
        { allocate/replace all registers }
        p:=headertai;
        while assigned(p) do
          begin
            case p.typ of
              ait_regalloc:
                with Tai_regalloc(p) do
                  begin
                    case getregtype(reg) of
                      R_INTREGISTER:
                        if getsubreg(reg)=R_SUBD then
                          size:=4
                        else
                          size:=8;
                      R_ADDRESSREGISTER:
                        size:=4;
                      R_FPUREGISTER:
                        if getsubreg(reg)=R_SUBFS then
                          size:=4
                        else
                          size:=8;
                      else
                        internalerror(2010122912);
                    end;
                    case ratype of
                      ra_alloc :
                        tg.gettemp(templist,
                                   size,1,
                                   tt_regallocator,spill_temps[getregtype(reg)]^[getsupreg(reg)]);
                      ra_dealloc :
                        begin
                          tg.ungettemp(templist,spill_temps[getregtype(reg)]^[getsupreg(reg)]);
                          { don't invalidate the temp reference, may still be used one instruction
                            later }
                        end;
                    end;
                    { insert the tempallocation/free at the right place }
                    list.insertlistbefore(p,templist);
                    { remove the register allocation info for the register
                      (p.previous is valid because we just inserted the temp
                       allocation/free before p) }
                    q:=Tai(p.previous);
                    list.remove(p);
                    p.free;
                    p:=q;
                  end;
              ait_instruction:
                do_spill_replace_all(list,taicpu(p),spill_temps);
            end;
            p:=Tai(p.next);
          end;
        freemem(spill_temps[R_INTREGISTER]);
        freemem(spill_temps[R_FPUREGISTER]);
      end;

end.
