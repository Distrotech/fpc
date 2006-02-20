{
    Copyright (c) 1998-2002 by Florian Klaempfl

    Helper routines for all code generators

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
unit ncgutil;

{$i fpcdefs.inc}

interface

    uses
      node,cpuinfo,
      globtype,
      cpubase,cgbase,parabase,cgutils,
      aasmbase,aasmtai,aasmcpu,
      symconst,symbase,symdef,symsym,symtype,symtable
{$ifndef cpu64bit}
      ,cg64f32
{$endif cpu64bit}
      ;

    type
      tloadregvars = (lr_dont_load_regvars, lr_load_regvars);

    procedure firstcomplex(p : tbinarynode);
    procedure maketojumpbool(list:TAAsmoutput; p : tnode; loadregvars: tloadregvars);
//    procedure remove_non_regvars_from_loc(const t: tlocation; var regs:Tsuperregisterset);

    procedure location_force_reg(list:TAAsmoutput;var l:tlocation;dst_size:TCGSize;maybeconst:boolean);
    procedure location_force_fpureg(list:TAAsmoutput;var l: tlocation;maybeconst:boolean);
    procedure location_force_mem(list:TAAsmoutput;var l:tlocation);
    procedure location_force_mmregscalar(list:TAAsmoutput;var l: tlocation;maybeconst:boolean);

    { Retrieve the location of the data pointed to in location l, when the location is
      a register it is expected to contain the address of the data }
    procedure location_get_data_ref(list:TAAsmoutput;const l:tlocation;var ref:treference;loadref:boolean);

    function  maybe_pushfpu(list:taasmoutput;needed : byte;var l:tlocation) : boolean;

    procedure alloc_proc_symbol(pd: tprocdef);
    procedure gen_proc_symbol(list:Taasmoutput);
    procedure gen_proc_symbol_end(list:Taasmoutput);
    procedure gen_proc_entry_code(list:Taasmoutput);
    procedure gen_proc_exit_code(list:Taasmoutput);
    procedure gen_stack_check_size_para(list:Taasmoutput);
    procedure gen_stack_check_call(list:Taasmoutput);
    procedure gen_save_used_regs(list:TAAsmoutput);
    procedure gen_restore_used_regs(list:TAAsmoutput);
    procedure gen_initialize_code(list:TAAsmoutput);
    procedure gen_finalize_code(list:TAAsmoutput);
    procedure gen_entry_code(list:TAAsmoutput);
    procedure gen_exit_code(list:TAAsmoutput);
    procedure gen_load_para_value(list:TAAsmoutput);
    procedure gen_load_return_value(list:TAAsmoutput);

    procedure gen_external_stub(list:taasmoutput;pd:tprocdef;const externalname:string);
    procedure gen_intf_wrappers(list:taasmoutput;st:tsymtable);
    procedure gen_load_vmt_register(list:taasmoutput;objdef:tobjectdef;selfloc:tlocation;var vmtreg:tregister);

   {#
      Allocate the buffers for exception management and setjmp environment.
      Return a pointer to these buffers, send them to the utility routine
      so they are registered, and then call setjmp.

      Then compare the result of setjmp with 0, and if not equal
      to zero, then jump to exceptlabel.

      Also store the result of setjmp to a temporary space by calling g_save_exception_reason

      It is to note that this routine may be called *after* the stackframe of a
      routine has been called, therefore on machines where the stack cannot
      be modified, all temps should be allocated on the heap instead of the
      stack.
    }

    const

      EXCEPT_BUF_SIZE = 3*sizeof(aint);
    type
      texceptiontemps=record
        jmpbuf,
        envbuf,
        reasonbuf  : treference;
      end;

    procedure get_exception_temps(list:taasmoutput;var t:texceptiontemps);
    procedure unget_exception_temps(list:taasmoutput;const t:texceptiontemps);
    procedure new_exception(list:TAAsmoutput;const t:texceptiontemps;exceptlabel:tasmlabel);
    procedure free_exception(list:TAAsmoutput;const t:texceptiontemps;a:aint;endexceptlabel:tasmlabel;onlyfree:boolean);

    procedure insertbssdata(sym : tglobalvarsym);

    procedure gen_alloc_symtable(list:TAAsmoutput;st:tsymtable);
    procedure gen_free_symtable(list:TAAsmoutput;st:tsymtable);
{$ifdef PASS2INLINE}
    procedure gen_alloc_inline_parast(list:TAAsmoutput;pd:tprocdef);
    procedure gen_alloc_inline_funcret(list:TAAsmoutput;pd:tprocdef);
{$endif PASS2INLINE}

    { rtti and init/final }
    procedure generate_rtti(p:Ttypesym);
    procedure generate_inittable(p:tsym);

    procedure location_free(list: taasmoutput; const location : TLocation);

implementation

  uses
    strings,
    cutils,cclasses,
    globals,systems,verbose,
    ppu,defutil,
    procinfo,paramgr,fmodule,
    regvars,dwarf,
{$ifdef GDB}
    gdb,
{$endif GDB}
    pass_1,pass_2,
    ncon,nld,nutils,
    tgobj,cgobj;


{*****************************************************************************
                                  Misc Helpers
*****************************************************************************}

    procedure location_free(list: taasmoutput; const location : TLocation);
      begin
        case location.loc of
          LOC_VOID:
            ;
          LOC_REGISTER,
          LOC_CREGISTER:
            begin
              if getsupreg(location.register)<first_int_imreg then
                cg.ungetcpuregister(list,location.register);
            end;
          LOC_FPUREGISTER,
          LOC_CFPUREGISTER:
            begin
              if getsupreg(location.register)<first_fpu_imreg then
                cg.ungetcpuregister(list,location.register);
            end;
          LOC_MMREGISTER,
          LOC_CMMREGISTER :
            begin
              if getsupreg(location.register)<first_mm_imreg then
                cg.ungetcpuregister(list,location.register);
            end;
          LOC_REFERENCE,
          LOC_CREFERENCE :
            begin
{$ifdef cputargethasfixedstack}
              location_freetemp(list,location);
{$endif cputargethasfixedstack}
            end;
          else
            internalerror(2004110211);
        end;
      end;



   { DO NOT RELY on the fact that the tnode is not yet swaped
     because of inlining code PM }
    procedure firstcomplex(p : tbinarynode);
      var
         hp : tnode;
      begin
         { always calculate boolean AND and OR from left to right }
         if (p.nodetype in [orn,andn]) and
            is_boolean(p.left.resulttype.def) then
           begin
             if nf_swaped in p.flags then
               internalerror(234234);
           end
         else
           if (
               (p.expectloc=LOC_FPUREGISTER) and
               (p.right.registersfpu > p.left.registersfpu)
              ) or
              (
               (
                (
                 ((p.left.registersfpu = 0) and (p.right.registersfpu = 0)) or
                 (p.expectloc<>LOC_FPUREGISTER)
                ) and
                (p.left.registersint<p.right.registersint)
               )
              ) then
            begin
              hp:=p.left;
              p.left:=p.right;
              p.right:=hp;
              if nf_swaped in p.flags then
                exclude(p.flags,nf_swaped)
              else
                include(p.flags,nf_swaped);
            end;
      end;


    procedure maketojumpbool(list:TAAsmoutput; p : tnode; loadregvars: tloadregvars);
    {
      produces jumps to true respectively false labels using boolean expressions

      depending on whether the loading of regvars is currently being
      synchronized manually (such as in an if-node) or automatically (most of
      the other cases where this procedure is called), loadregvars can be
      "lr_load_regvars" or "lr_dont_load_regvars"
    }
      var
        opsize : tcgsize;
        storepos : tfileposinfo;
      begin
         if nf_error in p.flags then
           exit;
         storepos:=aktfilepos;
         aktfilepos:=p.fileinfo;
         if is_boolean(p.resulttype.def) then
           begin
{$ifdef OLDREGVARS}
              if loadregvars = lr_load_regvars then
                load_all_regvars(list);
{$endif OLDREGVARS}
              if is_constboolnode(p) then
                begin
                   if tordconstnode(p).value<>0 then
                     cg.a_jmp_always(list,truelabel)
                   else
                     cg.a_jmp_always(list,falselabel)
                end
              else
                begin
                   opsize:=def_cgsize(p.resulttype.def);
                   case p.location.loc of
                     LOC_CREGISTER,LOC_REGISTER,LOC_CREFERENCE,LOC_REFERENCE :
                       begin
{$ifdef OLDREGVARS}
                         if (p.location.loc = LOC_CREGISTER) then
                           load_regvar_reg(list,p.location.register);
{$endif OLDREGVARS}
                         cg.a_cmp_const_loc_label(list,opsize,OC_NE,0,p.location,truelabel);
                         cg.a_jmp_always(list,falselabel);
                       end;
                     LOC_JUMP:
                       ;
{$ifdef cpuflags}
                     LOC_FLAGS :
                       begin
                         cg.a_jmp_flags(list,p.location.resflags,truelabel);
                         cg.a_jmp_always(list,falselabel);
                       end;
{$endif cpuflags}
                     else
                       begin
                         printnode(output,p);
                         internalerror(200308241);
                       end;
                   end;
                end;
           end
         else
           internalerror(200112305);
         aktfilepos:=storepos;
      end;


        (*
        This code needs fixing. It is not safe to use rgint; on the m68000 it
        would be rgaddr.

    procedure remove_non_regvars_from_loc(const t: tlocation; var regs:Tsuperregisterset);
      begin
        case t.loc of
          LOC_REGISTER:
            begin
              { can't be a regvar, since it would be LOC_CREGISTER then }
              exclude(regs,getsupreg(t.register));
              if t.register64.reghi<>NR_NO then
                exclude(regs,getsupreg(t.register64.reghi));
            end;
          LOC_CREFERENCE,LOC_REFERENCE:
            begin
              if not(cs_regvars in aktglobalswitches) or
                 (getsupreg(t.reference.base) in cg.rgint.usableregs) then
                exclude(regs,getsupreg(t.reference.base));
              if not(cs_regvars in aktglobalswitches) or
                 (getsupreg(t.reference.index) in cg.rgint.usableregs) then
                exclude(regs,getsupreg(t.reference.index));
            end;
        end;
      end;
        *)


{*****************************************************************************
                            EXCEPTION MANAGEMENT
*****************************************************************************}

    procedure get_exception_temps(list:taasmoutput;var t:texceptiontemps);
      var
        sym : ttypesym;
      begin
        if jmp_buf_size=-1 then
          begin
            searchsystype('JMP_BUF',sym);
            jmp_buf_size:=sym.restype.def.size;
          end;
        tg.GetTemp(list,EXCEPT_BUF_SIZE,tt_persistent,t.envbuf);
        tg.GetTemp(list,jmp_buf_size,tt_persistent,t.jmpbuf);
        tg.GetTemp(list,sizeof(aint),tt_persistent,t.reasonbuf);
      end;


    procedure unget_exception_temps(list:taasmoutput;const t:texceptiontemps);
      begin
        tg.Ungettemp(list,t.jmpbuf);
        tg.ungettemp(list,t.envbuf);
        tg.ungettemp(list,t.reasonbuf);
      end;


    procedure new_exception(list:TAAsmoutput;const t:texceptiontemps;exceptlabel:tasmlabel);
      var
        paraloc1,paraloc2,paraloc3 : tcgpara;
      begin
        paraloc1.init;
        paraloc2.init;
        paraloc3.init;
        paramanager.getintparaloc(pocall_default,1,paraloc1);
        paramanager.getintparaloc(pocall_default,2,paraloc2);
        paramanager.getintparaloc(pocall_default,3,paraloc3);
        paramanager.allocparaloc(list,paraloc3);
        cg.a_paramaddr_ref(list,t.envbuf,paraloc3);
        paramanager.allocparaloc(list,paraloc2);
        cg.a_paramaddr_ref(list,t.jmpbuf,paraloc2);
        { push type of exceptionframe }
        paramanager.allocparaloc(list,paraloc1);
        cg.a_param_const(list,OS_S32,1,paraloc1);
        paramanager.freeparaloc(list,paraloc3);
        paramanager.freeparaloc(list,paraloc2);
        paramanager.freeparaloc(list,paraloc1);
        cg.alloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));
        cg.a_call_name(list,'FPC_PUSHEXCEPTADDR');
        cg.dealloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));

        paramanager.getintparaloc(pocall_default,1,paraloc1);
        paramanager.allocparaloc(list,paraloc1);
        cg.a_param_reg(list,OS_ADDR,NR_FUNCTION_RESULT_REG,paraloc1);
        paramanager.freeparaloc(list,paraloc1);
        cg.alloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));
        cg.a_call_name(list,'FPC_SETJMP');
        cg.dealloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));

        cg.g_exception_reason_save(list, t.reasonbuf);
        cg.a_cmp_const_reg_label(list,OS_S32,OC_NE,0,cg.makeregsize(list,NR_FUNCTION_RESULT_REG,OS_S32),exceptlabel);
        paraloc1.done;
        paraloc2.done;
        paraloc3.done;
     end;


    procedure free_exception(list:TAAsmoutput;const t:texceptiontemps;a:aint;endexceptlabel:tasmlabel;onlyfree:boolean);
     begin
         cg.alloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));
         cg.a_call_name(list,'FPC_POPADDRSTACK');
         cg.dealloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));

         if not onlyfree then
          begin
            cg.g_exception_reason_load(list, t.reasonbuf);
            cg.a_cmp_const_reg_label(list,OS_INT,OC_EQ,a,NR_FUNCTION_RESULT_REG,endexceptlabel);
          end;
     end;


{*****************************************************************************
                                     TLocation
*****************************************************************************}

{$ifndef cpu64bit}
    { 32-bit version }
    procedure location_force_reg(list:TAAsmoutput;var l:tlocation;dst_size:TCGSize;maybeconst:boolean);
      var
        hregister,
        hregisterhi : tregister;
        hreg64 : tregister64;
        hl : tasmlabel;
        oldloc : tlocation;
        const_location: boolean;
     begin
        oldloc:=l;
        if dst_size=OS_NO then
          internalerror(200309144);
        { handle transformations to 64bit separate }
        if dst_size in [OS_64,OS_S64] then
         begin
           if not (l.size in [OS_64,OS_S64]) then
            begin
              { load a smaller size to OS_64 }
              if l.loc=LOC_REGISTER then
               begin
                 hregister:=cg.makeregsize(list,l.register64.reglo,OS_32);
                 cg.a_load_reg_reg(list,l.size,OS_32,l.register64.reglo,hregister);
               end
              else
               hregister:=cg.getintregister(list,OS_INT);
              { load value in low register }
              case l.loc of
                LOC_FLAGS :
                  cg.g_flags2reg(list,OS_INT,l.resflags,hregister);
                LOC_JUMP :
                  begin
                    cg.a_label(list,truelabel);
                    cg.a_load_const_reg(list,OS_INT,1,hregister);
                    objectlibrary.getlabel(hl);
                    cg.a_jmp_always(list,hl);
                    cg.a_label(list,falselabel);
                    cg.a_load_const_reg(list,OS_INT,0,hregister);
                    cg.a_label(list,hl);
                  end;
                else
                  cg.a_load_loc_reg(list,OS_INT,l,hregister);
              end;
              { reset hi part, take care of the signed bit of the current value }
              hregisterhi:=cg.getintregister(list,OS_INT);
              if (l.size in [OS_S8,OS_S16,OS_S32]) then
               begin
                 if l.loc=LOC_CONSTANT then
                  begin
                    if (longint(l.value)<0) then
                     cg.a_load_const_reg(list,OS_32,aint($ffffffff),hregisterhi)
                    else
                     cg.a_load_const_reg(list,OS_32,0,hregisterhi);
                  end
                 else
                  begin
                    cg.a_op_const_reg_reg(list,OP_SAR,OS_32,31,hregister,
                      hregisterhi);
                  end;
               end
              else
               cg.a_load_const_reg(list,OS_32,0,hregisterhi);
              location_reset(l,LOC_REGISTER,dst_size);
              l.register64.reglo:=hregister;
              l.register64.reghi:=hregisterhi;
            end
           else
            begin
              { 64bit to 64bit }
              if ((l.loc=LOC_CREGISTER) and maybeconst) then
               begin
                 hregister:=l.register64.reglo;
                 hregisterhi:=l.register64.reghi;
                 const_location := true;
               end
              else
               begin
                 hregister:=cg.getintregister(list,OS_INT);
                 hregisterhi:=cg.getintregister(list,OS_INT);
                 const_location := false;
               end;
              hreg64.reglo:=hregister;
              hreg64.reghi:=hregisterhi;
              { load value in new register }
              cg64.a_load64_loc_reg(list,l,hreg64);
              if not const_location then
                location_reset(l,LOC_REGISTER,dst_size)
              else
                location_reset(l,LOC_CREGISTER,dst_size);
              l.register64.reglo:=hregister;
              l.register64.reghi:=hregisterhi;
            end;
         end
        else
         begin
           {Do not bother to recycle the existing register. The register
            allocator eliminates unnecessary moves, so it's not needed
            and trying to recycle registers can cause problems because
            the registers changes size and may need aditional constraints.

            Not if it's about LOC_CREGISTER's (JM)
            }
           const_location :=
              (maybeconst) and
              (l.loc = LOC_CREGISTER) and
              (TCGSize2Size[l.size] = TCGSize2Size[dst_size]) and
              ((l.size = dst_size) or
               (TCGSize2Size[l.size] = TCGSize2Size[OS_INT]));
           if not const_location then
             hregister:=cg.getintregister(list,dst_size)
           else
             hregister := l.register;
           { load value in new register }
           case l.loc of
             LOC_FLAGS :
               cg.g_flags2reg(list,dst_size,l.resflags,hregister);
             LOC_JUMP :
               begin
                 cg.a_label(list,truelabel);
                 cg.a_load_const_reg(list,dst_size,1,hregister);
                 objectlibrary.getlabel(hl);
                 cg.a_jmp_always(list,hl);
                 cg.a_label(list,falselabel);
                 cg.a_load_const_reg(list,dst_size,0,hregister);
                 cg.a_label(list,hl);
               end;
             else
               begin
                 { load_loc_reg can only handle size >= l.size, when the
                   new size is smaller then we need to adjust the size
                   of the orignal and maybe recalculate l.register for i386 }
                 if (TCGSize2Size[dst_size]<TCGSize2Size[l.size]) then
                  begin
                    if (l.loc in [LOC_REGISTER,LOC_CREGISTER]) then
                      l.register:=cg.makeregsize(list,l.register,dst_size);
                    { for big endian systems, the reference's offset must }
                    { be increased in this case, since they have the      }
                    { MSB first in memory and e.g. byte(word_var) should  }
                    { return  the second byte in this case (JM)           }
                    if (target_info.endian = ENDIAN_BIG) and
                       (l.loc in [LOC_REFERENCE,LOC_CREFERENCE]) then
                      inc(l.reference.offset,TCGSize2Size[l.size]-TCGSize2Size[dst_size]);
{$ifdef x86}
                   l.size:=dst_size;
{$endif x86}
                  end;
                 cg.a_load_loc_reg(list,dst_size,l,hregister);
{$ifndef x86}
                 if (TCGSize2Size[dst_size]<TCGSize2Size[l.size]) then
                   l.size:=dst_size;
{$endif not x86}
               end;
           end;
           if not const_location then
             location_reset(l,LOC_REGISTER,dst_size)
           else
             location_reset(l,LOC_CREGISTER,dst_size);
           l.register:=hregister;
         end;
       { Release temp when it was a reference }
       if oldloc.loc=LOC_REFERENCE then
         location_freetemp(list,oldloc);
     end;

{$else cpu64bit}

    { 64-bit version }
    procedure location_force_reg(list:TAAsmoutput;var l:tlocation;dst_size:TCGSize;maybeconst:boolean);
      var
        hregister : tregister;
        hl : tasmlabel;
        oldloc : tlocation;
      begin
        oldloc:=l;
        hregister:=cg.getintregister(list,dst_size);
        { load value in new register }
        case l.loc of
          LOC_FLAGS :
            cg.g_flags2reg(list,dst_size,l.resflags,hregister);
          LOC_JUMP :
            begin
              cg.a_label(list,truelabel);
              cg.a_load_const_reg(list,dst_size,1,hregister);
              objectlibrary.getlabel(hl);
              cg.a_jmp_always(list,hl);
              cg.a_label(list,falselabel);
              cg.a_load_const_reg(list,dst_size,0,hregister);
              cg.a_label(list,hl);
            end;
          else
            begin
              { load_loc_reg can only handle size >= l.size, when the
                new size is smaller then we need to adjust the size
                of the orignal and maybe recalculate l.register for i386 }
              if (TCGSize2Size[dst_size]<TCGSize2Size[l.size]) then
               begin
                 if (l.loc in [LOC_REGISTER,LOC_CREGISTER]) then
                   l.register:=cg.makeregsize(list,l.register,dst_size);
                 { for big endian systems, the reference's offset must }
                 { be increased in this case, since they have the      }
                 { MSB first in memory and e.g. byte(word_var) should  }
                 { return  the second byte in this case (JM)           }
                 if (target_info.endian = ENDIAN_BIG) and
                    (l.loc in [LOC_REFERENCE,LOC_CREFERENCE]) then
                   inc(l.reference.offset,TCGSize2Size[l.size]-TCGSize2Size[dst_size]);
{$ifdef x86}
                l.size:=dst_size;
{$endif x86}
               end;
              cg.a_load_loc_reg(list,dst_size,l,hregister);
{$ifndef x86}
              if (TCGSize2Size[dst_size]<TCGSize2Size[l.size]) then
                l.size:=dst_size;
{$endif not x86}
            end;
        end;
        if (l.loc <> LOC_CREGISTER) or
           not maybeconst then
          location_reset(l,LOC_REGISTER,dst_size)
        else
          location_reset(l,LOC_CREGISTER,dst_size);
        l.register:=hregister;
        { Release temp when it was a reference }
        if oldloc.loc=LOC_REFERENCE then
          location_freetemp(list,oldloc);
      end;
{$endif cpu64bit}


    procedure location_force_fpureg(list:TAAsmoutput;var l: tlocation;maybeconst:boolean);
      var
        reg : tregister;
        href : treference;
      begin
        if (l.loc<>LOC_FPUREGISTER)  and
           ((l.loc<>LOC_CFPUREGISTER) or (not maybeconst)) then
          begin
            { if it's in an mm register, store to memory first }
            if (l.loc in [LOC_MMREGISTER,LOC_CMMREGISTER]) then
              begin
                tg.GetTemp(list,tcgsize2size[l.size],tt_normal,href);
                cg.a_loadmm_reg_ref(list,l.size,l.size,l.register,href,mms_movescalar);
                location_reset(l,LOC_REFERENCE,l.size);
                l.reference:=href;
              end;
            reg:=cg.getfpuregister(list,l.size);
            cg.a_loadfpu_loc_reg(list,l,reg);
            location_freetemp(list,l);
            location_reset(l,LOC_FPUREGISTER,l.size);
            l.register:=reg;
          end;
      end;


    procedure location_force_mmregscalar(list:TAAsmoutput;var l: tlocation;maybeconst:boolean);
      var
        reg : tregister;
        href : treference;
      begin
        if (l.loc<>LOC_MMREGISTER)  and
           ((l.loc<>LOC_CMMREGISTER) or (not maybeconst)) then
          begin
            { if it's in an fpu register, store to memory first }
            if (l.loc in [LOC_FPUREGISTER,LOC_CFPUREGISTER]) then
              begin
                tg.GetTemp(list,tcgsize2size[l.size],tt_normal,href);
                cg.a_loadfpu_reg_ref(list,l.size,l.register,href);
                location_reset(l,LOC_REFERENCE,l.size);
                l.reference:=href;
              end;
            reg:=cg.getmmregister(list,l.size);
            cg.a_loadmm_loc_reg(list,l.size,l,reg,mms_movescalar);
            location_freetemp(list,l);
            location_reset(l,LOC_MMREGISTER,l.size);
            l.register:=reg;
          end;
      end;


    procedure location_force_mem(list:TAAsmoutput;var l:tlocation);
      var
        r : treference;
      begin
        case l.loc of
          LOC_FPUREGISTER,
          LOC_CFPUREGISTER :
            begin
              tg.GetTemp(list,TCGSize2Size[l.size],tt_normal,r);
              cg.a_loadfpu_reg_ref(list,l.size,l.register,r);
              location_reset(l,LOC_REFERENCE,l.size);
              l.reference:=r;
            end;
          LOC_MMREGISTER,
          LOC_CMMREGISTER:
            begin
              tg.GetTemp(list,TCGSize2Size[l.size],tt_normal,r);
              cg.a_loadmm_reg_ref(list,l.size,l.size,l.register,r,mms_movescalar);
              location_reset(l,LOC_REFERENCE,l.size);
              l.reference:=r;
            end;
          LOC_CONSTANT,
          LOC_REGISTER,
          LOC_CREGISTER :
            begin
              tg.GetTemp(list,TCGSize2Size[l.size],tt_normal,r);
{$ifndef cpu64bit}
              if l.size in [OS_64,OS_S64] then
                cg64.a_load64_loc_ref(list,l,r)
              else
{$endif cpu64bit}
                cg.a_load_loc_ref(list,l.size,l,r);
              location_reset(l,LOC_REFERENCE,l.size);
              l.reference:=r;
            end;
          LOC_CREFERENCE,
          LOC_REFERENCE : ;
          else
            internalerror(200203219);
        end;
      end;


    procedure location_get_data_ref(list:TAAsmoutput;const l:tlocation;var ref:treference;loadref:boolean);
      begin
        case l.loc of
          LOC_REGISTER,
          LOC_CREGISTER :
            begin
              if not loadref then
                internalerror(200410231);
              reference_reset_base(ref,l.register,0);
            end;
          LOC_REFERENCE,
          LOC_CREFERENCE :
            begin
              if loadref then
                begin
                  reference_reset_base(ref,cg.getaddressregister(list),0);
                  cg.a_load_ref_reg(list,OS_ADDR,OS_ADDR,l.reference,ref.base);
                end
              else
                ref:=l.reference;
            end;
          else
            internalerror(200309181);
        end;
      end;


{*****************************************************************************
                                  Maybe_Save
*****************************************************************************}

    function maybe_pushfpu(list:taasmoutput;needed : byte;var l:tlocation) : boolean;
      begin
{$ifdef i386}
        if (needed>=maxfpuregs) and
           (l.loc = LOC_FPUREGISTER) then
          begin
            location_force_mem(list,l);
            maybe_pushfpu:=true;
          end
        else
          maybe_pushfpu:=false;
{$else i386}
        maybe_pushfpu:=false;
{$endif i386}
      end;


{****************************************************************************
                            Init/Finalize Code
****************************************************************************}

    procedure copyvalueparas(p : tnamedindexitem;arg:pointer);
      var
        href : treference;
        hreg : tregister;
        list : TAAsmoutput;
        hsym : tparavarsym;
        l    : longint;
        localcopyloc : tlocation;
      begin
        list:=taasmoutput(arg);
        if (tsym(p).typ=paravarsym) and
           (tparavarsym(p).varspez=vs_value) and
           (paramanager.push_addr_param(tparavarsym(p).varspez,tparavarsym(p).vartype.def,current_procinfo.procdef.proccalloption)) then
         begin
           location_get_data_ref(list,tparavarsym(p).localloc,href,true);
           if is_open_array(tparavarsym(p).vartype.def) or
              is_array_of_const(tparavarsym(p).vartype.def) then
            begin
              { cdecl functions don't have a high pointer so it is not possible to generate
                a local copy }
              if not(current_procinfo.procdef.proccalloption in [pocall_cdecl,pocall_cppdecl]) then
                begin
                  hsym:=tparavarsym(tsym(p).owner.search('high'+p.name));
                  if not assigned(hsym) then
                    internalerror(200306061);
                  hreg:=cg.getaddressregister(list);
                  cg.g_copyvaluepara_openarray(list,href,hsym.localloc,tarraydef(tparavarsym(p).vartype.def).elesize,hreg);
                  cg.a_load_reg_loc(list,OS_ADDR,hreg,tparavarsym(p).localloc);
                end;
            end
           else
            begin
              { Allocate space for the local copy }
              l:=tparavarsym(p).getsize;
              localcopyloc.loc:=LOC_REFERENCE;
              localcopyloc.size:=int_cgsize(l);
              tg.GetLocal(list,l,tparavarsym(p).vartype.def,localcopyloc.reference);
              { Copy data }
              if is_shortstring(tparavarsym(p).vartype.def) then
                begin
                  { this code is only executed before the code for the body and the entry/exit code is generated
                    so we're allowed to include pi_do_call here; after pass1 is run, this isn't allowed anymore
                  }
                  include(current_procinfo.flags,pi_do_call);
                  cg.g_copyshortstring(list,href,localcopyloc.reference,tstringdef(tparavarsym(p).vartype.def).len)
                end
              else
                cg.g_concatcopy(list,href,localcopyloc.reference,tparavarsym(p).vartype.def.size);
              { update localloc of varsym }
              tg.Ungetlocal(list,tparavarsym(p).localloc.reference);
              tparavarsym(p).localloc:=localcopyloc;
            end;
         end;
      end;


    { initializes the regvars from staticsymtable with 0 }
    procedure initialize_regvars(p : tnamedindexitem;arg:pointer);
      begin
        if (tsym(p).typ=globalvarsym) then
         begin
           case tglobalvarsym(p).localloc.loc of
             LOC_CREGISTER :
               cg.a_load_const_reg(taasmoutput(arg),reg_cgsize(tglobalvarsym(p).localloc.register),0,
                   tglobalvarsym(p).localloc.register);
             LOC_REFERENCE : ;
             else
               internalerror(200410124);
           end;
         end;
      end;


    { generates the code for initialisation of local data }
    procedure initialize_data(p : tnamedindexitem;arg:pointer);
      var
        oldexprasmlist : TAAsmoutput;
        hp : tnode;
      begin
        if (tsym(p).typ in [globalvarsym,localvarsym]) and
           (tabstractvarsym(p).refs>0) and
           not(is_class(tabstractvarsym(p).vartype.def)) and
           tabstractvarsym(p).vartype.def.needs_inittable then
         begin
           oldexprasmlist:=exprasmlist;
           exprasmlist:=taasmoutput(arg);
           hp:=initialize_data_node(cloadnode.create(tsym(p),tsym(p).owner));
           firstpass(hp);
           secondpass(hp);
           hp.free;
           exprasmlist:=oldexprasmlist;
         end;
      end;


    procedure finalize_sym(asmlist:taasmoutput;sym:tsym);
      var
        hp : tnode;
        oldexprasmlist : TAAsmoutput;
      begin
        include(current_procinfo.flags,pi_needs_implicit_finally);
        oldexprasmlist:=exprasmlist;
        exprasmlist:=asmlist;
        hp:=finalize_data_node(cloadnode.create(sym,sym.owner));
        firstpass(hp);
        secondpass(hp);
        hp.free;
        exprasmlist:=oldexprasmlist;
      end;


    { generates the code for finalisation of local variables }
    procedure finalize_local_vars(p : tnamedindexitem;arg:pointer);
      begin
        if (tsym(p).typ=localvarsym) and
           (tlocalvarsym(p).refs>0) and
           not(vo_is_funcret in tlocalvarsym(p).varoptions) and
           not(is_class(tlocalvarsym(p).vartype.def)) and
           tlocalvarsym(p).vartype.def.needs_inittable then
          finalize_sym(taasmoutput(arg),tsym(p));
      end;


    { generates the code for finalisation of local typedconsts }
    procedure finalize_local_typedconst(p : tnamedindexitem;arg:pointer);
      var
        i : longint;
        pd : tprocdef;
      begin
        case tsym(p).typ of
          typedconstsym :
            begin
              if ttypedconstsym(p).is_writable and
                 ttypedconstsym(p).typedconsttype.def.needs_inittable then
                finalize_sym(taasmoutput(arg),tsym(p));
            end;
          procsym :
            begin
              for i:=1 to tprocsym(p).procdef_count do
                begin
                  pd:=tprocsym(p).procdef[i];
                  if assigned(pd.localst) and
                     (pd.procsym=tprocsym(p)) and
                     (pd.localst.symtabletype<>staticsymtable) then
                    pd.localst.foreach_static(@finalize_local_typedconst,arg);
                end;
            end;
        end;
      end;


    { generates the code for finalization of static symtable and
      all local (static) typedconsts }
    procedure finalize_static_data(p : tnamedindexitem;arg:pointer);
      var
        i : longint;
        pd : tprocdef;
      begin
        case tsym(p).typ of
          globalvarsym :
            begin
              if (tglobalvarsym(p).refs>0) and
                 not(vo_is_funcret in tglobalvarsym(p).varoptions) and
                 not(is_class(tglobalvarsym(p).vartype.def)) and
                 tglobalvarsym(p).vartype.def.needs_inittable then
                finalize_sym(taasmoutput(arg),tsym(p));
            end;
          typedconstsym :
            begin
              if ttypedconstsym(p).is_writable and
                 ttypedconstsym(p).typedconsttype.def.needs_inittable then
                finalize_sym(taasmoutput(arg),tsym(p));
            end;
          procsym :
            begin
              for i:=1 to tprocsym(p).procdef_count do
                begin
                  pd:=tprocsym(p).procdef[i];
                  if assigned(pd.localst) and
                     (pd.procsym=tprocsym(p)) and
                     (pd.localst.symtabletype<>staticsymtable) then
                    pd.localst.foreach_static(@finalize_local_typedconst,arg);
                end;
            end;
        end;
      end;


    { generates the code for incrementing the reference count of parameters and
      initialize out parameters }
    procedure init_paras(p : tnamedindexitem;arg:pointer);
      var
        href : treference;
        tmpreg : tregister;
        list : TAAsmoutput;
      begin
        list:=taasmoutput(arg);
        if (tsym(p).typ=paravarsym) and
           not is_class_or_interface(tparavarsym(p).vartype.def) and
           tparavarsym(p).vartype.def.needs_inittable then
         begin
           case tparavarsym(p).varspez of
             vs_value :
               begin
                 location_get_data_ref(list,tparavarsym(p).localloc,href,is_open_array(tparavarsym(p).vartype.def));
                 cg.g_incrrefcount(list,tparavarsym(p).vartype.def,href);
               end;
             vs_out :
               begin
                 tmpreg:=cg.getaddressregister(list);
                 cg.a_load_loc_reg(list,OS_ADDR,tparavarsym(p).localloc,tmpreg);
                 reference_reset_base(href,tmpreg,0);
                 cg.g_initialize(list,tparavarsym(p).vartype.def,href);
               end;
           end;
         end;
      end;


    { generates the code for decrementing the reference count of parameters }
    procedure final_paras(p : tnamedindexitem;arg:pointer);
      var
        list : TAAsmoutput;
        href : treference;
      begin
        if not(tsym(p).typ=paravarsym) then
          exit;
        list:=taasmoutput(arg);
        if not is_class_or_interface(tparavarsym(p).vartype.def) and
           tparavarsym(p).vartype.def.needs_inittable then
         begin
           if (tparavarsym(p).varspez=vs_value) then
            begin
              include(current_procinfo.flags,pi_needs_implicit_finally);
              location_get_data_ref(list,tparavarsym(p).localloc,href,is_open_array(tparavarsym(p).vartype.def));
              cg.g_decrrefcount(list,tparavarsym(p).vartype.def,href);
            end;
         end
        else
         if (tparavarsym(p).varspez=vs_value) and
            (is_open_array(tparavarsym(p).vartype.def) or
             is_array_of_const(tparavarsym(p).vartype.def)) then
           begin
             { cdecl functions don't have a high pointer so it is not possible to generate
               a local copy }
             if not(current_procinfo.procdef.proccalloption in [pocall_cdecl,pocall_cppdecl]) then
               cg.g_releasevaluepara_openarray(list,tparavarsym(p).localloc);
           end;
      end;


    { Initialize temp ansi/widestrings,interfaces }
    procedure inittempvariables(list:taasmoutput);
      var
        hp : ptemprecord;
        href : treference;
      begin
        hp:=tg.templist;
        while assigned(hp) do
         begin
           if assigned(hp^.def) and
              hp^.def.needs_inittable then
            begin
              reference_reset_base(href,current_procinfo.framepointer,hp^.pos);
              cg.g_initialize(list,hp^.def,href);
            end;
           hp:=hp^.next;
         end;
      end;


    procedure finalizetempvariables(list:taasmoutput);
      var
        hp : ptemprecord;
        href : treference;
      begin
        hp:=tg.templist;
        while assigned(hp) do
         begin
           if assigned(hp^.def) and
              hp^.def.needs_inittable then
            begin
              include(current_procinfo.flags,pi_needs_implicit_finally);
              reference_reset_base(href,current_procinfo.framepointer,hp^.pos);
              cg.g_finalize(list,hp^.def,href);
            end;
           hp:=hp^.next;
         end;
      end;


    procedure gen_load_return_value(list:TAAsmoutput);
      var
{$ifndef cpu64bit}
        href   : treference;
{$endif cpu64bit}
        ressym : tabstractnormalvarsym;
        resloc,
        restmploc : tlocation;
        hreg   : tregister;
        funcretloc : tlocation;
      begin
        { Is the loading needed? }
        if (current_procinfo.procdef.funcretloc[calleeside].loc=LOC_VOID) or
           (
            (po_assembler in current_procinfo.procdef.procoptions) and
            (not(assigned(current_procinfo.procdef.funcretsym)) or
             (tabstractvarsym(current_procinfo.procdef.funcretsym).refs=0))
           ) then
           exit;

        funcretloc:=current_procinfo.procdef.funcretloc[calleeside];

        { constructors return self }
        if (current_procinfo.procdef.proctypeoption=potype_constructor) then
          ressym:=tabstractnormalvarsym(current_procinfo.procdef.parast.search('self'))
        else
          ressym:=tabstractnormalvarsym(current_procinfo.procdef.funcretsym);
        if (ressym.refs>0) then
          begin
{$ifdef OLDREGVARS}
            case ressym.localloc.loc of
              LOC_CFPUREGISTER,
              LOC_FPUREGISTER:
                begin
                  location_reset(restmploc,LOC_CFPUREGISTER,funcretloc^.size);
                  restmploc.register:=ressym.localloc.register;
                end;

              LOC_CREGISTER,
              LOC_REGISTER:
                begin
                  location_reset(restmploc,LOC_CREGISTER,funcretloc^.size);
                  restmploc.register:=ressym.localloc.register;
                end;

              LOC_MMREGISTER:
                begin
                  location_reset(restmploc,LOC_CMMREGISTER,funcretloc^.size);
                  restmploc.register:=ressym.localloc.register;
                end;

              LOC_REFERENCE:
                begin
                  location_reset(restmploc,LOC_REFERENCE,funcretloc^.size);
                  restmploc.reference:=ressym.localloc.reference;
                end;
              else
                internalerror(200309184);
            end;
{$else}
            restmploc:=ressym.localloc;
{$endif}

            { Here, we return the function result. In most architectures, the value is
              passed into the FUNCTION_RETURN_REG, but in a windowed architecure like sparc a
              function returns in a register and the caller receives it in an other one }
            case funcretloc.loc of
              LOC_REGISTER:
                begin
{$ifndef cpu64bit}
                  if current_procinfo.procdef.funcretloc[calleeside].size in [OS_64,OS_S64] then
                    begin
                      resloc:=current_procinfo.procdef.funcretloc[calleeside];
                      if resloc.loc<>LOC_REGISTER then
                        internalerror(200409141);
                      { Load low and high register separate to generate better register
                        allocation info }
                      if getsupreg(resloc.register64.reglo)<first_int_imreg then
                        begin
                          cg.getcpuregister(list,resloc.register64.reglo);
                          cg.ungetcpuregister(list,resloc.register64.reglo);
                          { for the optimizer }
                          cg.a_reg_alloc(list,resloc.register64.reglo);
                        end;
                      case restmploc.loc of
                        LOC_REFERENCE :
                          begin
                            href:=restmploc.reference;
                            if target_info.endian=ENDIAN_BIG then
                              inc(href.offset,4);
                            cg.a_load_ref_reg(list,OS_32,OS_32,href,resloc.register64.reglo);
                          end;
                        LOC_CREGISTER :
                          cg.a_load_reg_reg(list,OS_32,OS_32,restmploc.register64.reglo,resloc.register64.reglo);
                        else
                          internalerror(200409203);
                      end;
                      if getsupreg(resloc.register64.reghi)<first_int_imreg then
                        begin
                          cg.getcpuregister(list,resloc.register64.reghi);
                          cg.ungetcpuregister(list,resloc.register64.reghi);
                          { for the optimizer }
                          cg.a_reg_alloc(list,resloc.register64.reghi);
                        end;
                      case restmploc.loc of
                        LOC_REFERENCE :
                          begin
                            href:=restmploc.reference;
                            if target_info.endian=ENDIAN_LITTLE then
                              inc(href.offset,4);
                            cg.a_load_ref_reg(list,OS_32,OS_32,href,resloc.register64.reghi);
                          end;
                        LOC_CREGISTER :
                          cg.a_load_reg_reg(list,OS_32,OS_32,restmploc.register64.reghi,resloc.register64.reghi);
                        else
                          internalerror(200409204);
                      end;
                    end
                  else
{$endif cpu64bit}
                    begin
                      hreg:=cg.makeregsize(list,funcretloc.register,funcretloc.size);
                      if getsupreg(funcretloc.register)<first_int_imreg then
                        begin
                          cg.getcpuregister(list,funcretloc.register);
                          cg.ungetcpuregister(list,hreg);
                          { for the optimizer }
                          cg.a_reg_alloc(list,funcretloc.register);
                        end;
                      { it could be that a structure is passed in memory but the function is expected to
                        return a pointer to this memory }
                      if paramanager.ret_in_param(current_procinfo.procdef.rettype.def,current_procinfo.procdef.proccalloption) then
                        cg.a_load_loc_reg(list,OS_ADDR,restmploc,hreg)
                      else
                      cg.a_load_loc_reg(list,restmploc.size,restmploc,hreg);
                    end;
                end;
              LOC_FPUREGISTER:
                begin
                  if getsupreg(funcretloc.register)<first_fpu_imreg then
                    begin
                      cg.getcpuregister(list,funcretloc.register);
                      cg.ungetcpuregister(list,funcretloc.register);
                    end;
                  cg.a_loadfpu_loc_reg(list,restmploc,funcretloc.register);
                end;
              LOC_MMREGISTER:
                begin
                  if getsupreg(funcretloc.register)<first_mm_imreg then
                    begin
                      cg.getcpuregister(list,funcretloc.register);
                      cg.ungetcpuregister(list,funcretloc.register);
                    end;
                  cg.a_loadmm_loc_reg(list,restmploc.size,restmploc,funcretloc.register,mms_movescalar);
                end;
              LOC_INVALID,
              LOC_REFERENCE:
                ;
              else
                internalerror(200405025);
            end;
         end;
      end;


    procedure gen_load_para_value(list:TAAsmoutput);


       procedure get_para(const paraloc:TCGParaLocation);
         begin
            case paraloc.loc of
              LOC_REGISTER :
                begin
                  if getsupreg(paraloc.register)<first_int_imreg then
                    cg.getcpuregister(list,paraloc.register);
                end;
              LOC_MMREGISTER :
                begin
                  if getsupreg(paraloc.register)<first_mm_imreg then
                    cg.getcpuregister(list,paraloc.register);
                end;
              LOC_FPUREGISTER :
                begin
                  if getsupreg(paraloc.register)<first_fpu_imreg then
                    cg.getcpuregister(list,paraloc.register);
                end;
            end;
         end;


       procedure unget_para(const paraloc:TCGParaLocation);
         begin
            case paraloc.loc of
              LOC_REGISTER :
                begin
                  if getsupreg(paraloc.register)<first_int_imreg then
                    cg.ungetcpuregister(list,paraloc.register);
                end;
              LOC_MMREGISTER :
                begin
                  if getsupreg(paraloc.register)<first_mm_imreg then
                    cg.ungetcpuregister(list,paraloc.register);
                end;
              LOC_FPUREGISTER :
                begin
                  if getsupreg(paraloc.register)<first_fpu_imreg then
                    cg.ungetcpuregister(list,paraloc.register);
                end;
            end;
         end;


       procedure gen_load_ref(const paraloc:TCGParaLocation;const ref:treference;sizeleft:aint);
         var
           href : treference;
         begin
            case paraloc.loc of
              LOC_REGISTER :
                cg.a_load_reg_ref(list,paraloc.size,paraloc.size,paraloc.register,ref);
              LOC_MMREGISTER :
                cg.a_loadmm_reg_ref(list,paraloc.size,paraloc.size,paraloc.register,ref,mms_movescalar);
              LOC_FPUREGISTER :
                cg.a_loadfpu_reg_ref(list,paraloc.size,paraloc.register,ref);
              LOC_REFERENCE :
                begin
                  reference_reset_base(href,paraloc.reference.index,paraloc.reference.offset);
                  { use concatcopy, because it can also be a float which fails when
                    load_ref_ref is used. Don't copy data when the references are equal }
                  if not((href.base=ref.base) and (href.offset=ref.offset)) then
                    cg.g_concatcopy(list,href,ref,sizeleft);
                end;
              else
                internalerror(2002081302);
            end;
         end;


       procedure gen_load_reg(const paraloc:TCGParaLocation;reg:tregister);
         var
           href : treference;
         begin
            case paraloc.loc of
              LOC_REGISTER :
                cg.a_load_reg_reg(list,paraloc.size,paraloc.size,paraloc.register,reg);
              LOC_MMREGISTER :
                cg.a_loadmm_reg_reg(list,paraloc.size,paraloc.size,paraloc.register,reg,mms_movescalar);
              LOC_FPUREGISTER :
                cg.a_loadfpu_reg_reg(list,paraloc.size,paraloc.register,reg);
              LOC_REFERENCE :
                begin
                  reference_reset_base(href,paraloc.reference.index,paraloc.reference.offset);
                  case getregtype(reg) of
                    R_INTREGISTER :
                      cg.a_load_ref_reg(list,paraloc.size,paraloc.size,href,reg);
                    R_FPUREGISTER :
                      cg.a_loadfpu_ref_reg(list,paraloc.size,href,reg);
                    R_MMREGISTER :
                      cg.a_loadmm_ref_reg(list,paraloc.size,paraloc.size,href,reg,mms_movescalar);
                    else
                      internalerror(2004101012);
                  end;
                end;
              else
                internalerror(2002081302);
            end;
         end;

      var
        i : longint;
        currpara : tparavarsym;
        paraloc  : pcgparalocation;
        href     : treference;
        sizeleft : aint;
{$ifdef sparc}
        tempref  : treference;
{$endif sparc}
      begin
        if (po_assembler in current_procinfo.procdef.procoptions) then
          exit;

        { Allocate registers used by parameters }
        for i:=0 to current_procinfo.procdef.paras.count-1 do
          begin
            currpara:=tparavarsym(current_procinfo.procdef.paras[i]);
            paraloc:=currpara.paraloc[calleeside].location;
            while assigned(paraloc) do
              begin
                if paraloc^.loc in [LOC_REGISTER,LOC_FPUREGISTER,LOC_MMREGISTER] then
                  get_para(paraloc^);
                paraloc:=paraloc^.next;
              end;
          end;

        { Copy parameters to local references/registers }
        for i:=0 to current_procinfo.procdef.paras.count-1 do
          begin
            currpara:=tparavarsym(current_procinfo.procdef.paras[i]);
            paraloc:=currpara.paraloc[calleeside].location;
            { skip e.g. empty records }
            if (paraloc^.loc = LOC_VOID) then
              continue;
            if not assigned(paraloc) then
              internalerror(200408203);
            case currpara.localloc.loc of
              LOC_REFERENCE :
                begin
                  { If the parameter location is reused we don't need to copy
                    anything }
                  if not paramanager.param_use_paraloc(currpara.paraloc[calleeside]) then
                    begin
                      href:=currpara.localloc.reference;
                      sizeleft:=currpara.paraloc[calleeside].intsize;
                      while assigned(paraloc) do
                        begin
                          unget_para(paraloc^);
                          if (paraloc^.size=OS_NO) then
                            begin
                              { Can only be a reference that contains the rest
                                of the parameter }
                              if (paraloc^.loc<>LOC_REFERENCE) or
                                 assigned(paraloc^.next) then
                                internalerror(2005013010);
                              gen_load_ref(paraloc^,href,sizeleft);
                              inc(href.offset,sizeleft);
                              sizeleft:=0;
                            end
                          else
                            begin
                              gen_load_ref(paraloc^,href,tcgsize2size[paraloc^.size]);
                              inc(href.offset,TCGSize2Size[paraloc^.size]);
                              dec(sizeleft,TCGSize2Size[paraloc^.size]);
                            end;
                          paraloc:=paraloc^.next;
                        end;
                    end;
                end;
              LOC_CREGISTER :
                begin
{$ifndef cpu64bit}
                  if (currpara.paraloc[calleeside].size in [OS_64,OS_S64]) and
                     is_64bit(currpara.vartype.def) then
                    begin
                      case paraloc^.loc of
                        LOC_REGISTER:
                          begin
                            if not assigned(paraloc^.next) then
                              internalerror(200410104);
                            if (target_info.endian=ENDIAN_BIG) then
                              begin
                                { paraloc^ -> high
                                  paraloc^.next -> low }
                                unget_para(paraloc^);
                                gen_load_reg(paraloc^,currpara.localloc.register64.reghi);
                                unget_para(paraloc^.next^);
                                gen_load_reg(paraloc^.next^,currpara.localloc.register64.reglo);
                              end
                            else
                              begin
                                { paraloc^ -> low
                                  paraloc^.next -> high }
                                unget_para(paraloc^);
                                gen_load_reg(paraloc^,currpara.localloc.register64.reglo);
                                unget_para(paraloc^.next^);
                                gen_load_reg(paraloc^.next^,currpara.localloc.register64.reghi);
                              end;
                          end;
                        LOC_REFERENCE:
                          begin
                            reference_reset_base(href,paraloc^.reference.index,paraloc^.reference.offset);
                            cg64.a_load64_ref_reg(list,href,currpara.localloc.register64);
                            unget_para(paraloc^);
                          end;
                        else
                          internalerror(2005101501);
                      end
                    end
                  else
{$endif cpu64bit}
                    begin
                      if assigned(paraloc^.next) then
                        internalerror(200410105);
                      unget_para(paraloc^);
                      gen_load_reg(paraloc^,currpara.localloc.register);
                    end;
                end;
              LOC_CFPUREGISTER :
                begin
{$ifdef sparc}
                  { Sparc passes floats in int registers, when loading to fpu register
                    we need a temp }
                  sizeleft := TCGSize2Size[currpara.localloc.size];
                  tg.GetTemp(list,sizeleft,tt_normal,tempref);
                  href:=tempref;
                  while assigned(paraloc) do
                    begin
                      unget_para(paraloc^);
                      gen_load_ref(paraloc^,href,sizeleft);
                      inc(href.offset,TCGSize2Size[paraloc^.size]);
                      dec(sizeleft,TCGSize2Size[paraloc^.size]);
                      paraloc:=paraloc^.next;
                    end;
                  cg.a_loadfpu_ref_reg(list,currpara.localloc.size,tempref,currpara.localloc.register);
                  tg.UnGetTemp(list,tempref);
{$else sparc}
                  unget_para(paraloc^);
                  gen_load_reg(paraloc^,currpara.localloc.register);
                  if assigned(paraloc^.next) then
                    internalerror(200410109);
{$endif sparc}
                end;
              LOC_CMMREGISTER :
                begin
                  unget_para(paraloc^);
                  gen_load_reg(paraloc^,currpara.localloc.register);
                  if assigned(paraloc^.next) then
                    internalerror(200410108);
                end;
            end;
          end;

        { generate copies of call by value parameters, must be done before
          the initialization and body is parsed because the refcounts are
          incremented using the local copies }
        current_procinfo.procdef.parast.foreach_static({$ifndef TP}@{$endif}copyvalueparas,list);
{$ifdef powerpc}
        { unget the register that contains the stack pointer before the procedure entry, }
        { which is used to access the parameters in their original callee-side location  }
        cg.a_reg_dealloc(list,NR_R12);
{$endif powerpc}
      end;


    procedure gen_initialize_code(list:TAAsmoutput);
      begin
        { initialize local data like ansistrings }
        case current_procinfo.procdef.proctypeoption of
           potype_unitinit:
             begin
                { this is also used for initialization of variables in a
                  program which does not have a globalsymtable }
                if assigned(current_module.globalsymtable) then
                  tsymtable(current_module.globalsymtable).foreach_static({$ifndef TP}@{$endif}initialize_data,list);
                tsymtable(current_module.localsymtable).foreach_static({$ifndef TP}@{$endif}initialize_data,list);
                tsymtable(current_module.localsymtable).foreach_static({$ifndef TP}@{$endif}initialize_regvars,list);
             end;
           { units have seperate code for initilization and finalization }
           potype_unitfinalize: ;
           { program init/final is generated in separate procedure }
           potype_proginit:
             begin
               tsymtable(current_module.localsymtable).foreach_static({$ifndef TP}@{$endif}initialize_regvars,list);
             end;
           else
             current_procinfo.procdef.localst.foreach_static({$ifndef TP}@{$endif}initialize_data,list);
        end;

        { initialisizes temp. ansi/wide string data }
        inittempvariables(list);

        { initialize ansi/widesstring para's }
        if not(po_assembler in current_procinfo.procdef.procoptions) then
          current_procinfo.procdef.parast.foreach_static({$ifndef TP}@{$endif}init_paras,list);

{$ifdef OLDREGVARS}
        load_regvars(list,nil);
{$endif OLDREGVARS}
      end;


    procedure gen_finalize_code(list:TAAsmoutput);
      begin
{$ifdef OLDREGVARS}
        cleanup_regvars(list);
{$endif OLDREGVARS}

        { finalize temporary data }
        finalizetempvariables(list);

        { finalize local data like ansistrings}
        case current_procinfo.procdef.proctypeoption of
           potype_unitfinalize:
             begin
                { this is also used for initialization of variables in a
                  program which does not have a globalsymtable }
                if assigned(current_module.globalsymtable) then
                  tsymtable(current_module.globalsymtable).foreach_static({$ifndef TP}@{$endif}finalize_static_data,list);
                tsymtable(current_module.localsymtable).foreach_static({$ifndef TP}@{$endif}finalize_static_data,list);
             end;
           { units/progs have separate code for initialization and finalization }
           potype_unitinit: ;
           { program init/final is generated in separate procedure }
           potype_proginit: ;
           else
             current_procinfo.procdef.localst.foreach_static({$ifndef TP}@{$endif}finalize_local_vars,list);
        end;

        { finalize paras data }
        if assigned(current_procinfo.procdef.parast) and
           not(po_assembler in current_procinfo.procdef.procoptions) then
          current_procinfo.procdef.parast.foreach_static({$ifndef TP}@{$endif}final_paras,list);
      end;


    procedure gen_entry_code(list:TAAsmoutput);
      var
        href : treference;
        paraloc1,
        paraloc2,
        paraloc3 : tcgpara;
        hp   : tused_unit;
      begin
        paraloc1.init;
        paraloc2.init;

        { the actual profile code can clobber some registers,
          therefore if the context must be saved, do it before
          the actual call to the profile code
        }
        if (cs_profile in aktmoduleswitches) and
           not(po_assembler in current_procinfo.procdef.procoptions) then
          begin
            { non-win32 can call mcout even in main }
            if not (target_info.system in [system_i386_win32,system_i386_wdosx]) or
               not (current_procinfo.procdef.proctypeoption=potype_proginit) then
              begin
                cg.alloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_cdecl));
                cg.g_profilecode(list);
                cg.dealloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_cdecl));
              end;
          end;

        { call startup helpers from main program }
        if (current_procinfo.procdef.proctypeoption=potype_proginit) then
         begin
           if ((target_info.system = system_powerpc_darwin) or
               (target_info.system = system_powerpc_macos)) and
              not(current_module.islibrary) then
             begin
              { the parameters are already in the right registers }
              cg.a_call_name(list,target_info.cprefix+'FPC_SYSTEMMAIN');
             end;
           
           { initialize units }
           cg.alloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));
           cg.a_call_name(list,'FPC_INITIALIZEUNITS');
           cg.dealloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));

{$ifdef GDB}
           if (cs_debuginfo in aktmoduleswitches) then
            if target_info.system <> system_powerpc_macos then
             begin
               { include reference to all debuginfo sections of used units }
               hp:=tused_unit(usedunits.first);
               while assigned(hp) do
                 begin
                   If (hp.u.flags and uf_has_debuginfo)=uf_has_debuginfo then
                     current_procinfo.aktlocaldata.concat(Tai_const.Createname(make_mangledname('DEBUGINFO',hp.u.globalsymtable,''),AT_DATA,0));
                   hp:=tused_unit(hp.next);
                 end;
               { include reference to debuginfo for this program }
               current_procinfo.aktlocaldata.concat(Tai_const.Createname(make_mangledname('DEBUGINFO',current_module.localsymtable,''),AT_DATA,0));
             end;
{$endif GDB}
         end;

{$ifdef GDB}
        if (cs_debuginfo in aktmoduleswitches) then
         list.concat(Tai_force_line.Create);
{$endif GDB}

{$ifdef OLDREGVARS}
        load_regvars(list,nil);
{$endif OLDREGVARS}

        paraloc1.done;
        paraloc2.done;
      end;


    procedure gen_exit_code(list:TAAsmoutput);
      begin
        { call __EXIT for main program }
        if (not DLLsource) and
           (current_procinfo.procdef.proctypeoption=potype_proginit) then
          cg.a_call_name(list,'FPC_DO_EXIT');
      end;


{****************************************************************************
                                Entry/Exit
****************************************************************************}

    procedure alloc_proc_symbol(pd: tprocdef);
     var
        item: tstringlistitem;
      begin
        item := tstringlistitem(pd.aliasnames.first);
        while assigned(item) do
          begin
            if (cs_profile in aktmoduleswitches) or
               (po_global in current_procinfo.procdef.procoptions) then
               objectlibrary.newasmsymbol(item.str,AB_GLOBAL,AT_FUNCTION)
            else
               objectlibrary.newasmsymbol(item.str,AB_GLOBAL,AT_FUNCTION);
            item := tstringlistitem(item.next);
          end;
       end;


    procedure gen_proc_symbol(list:Taasmoutput);
      var
        hs : string;
      begin
        { add symbol entry point as well as debug information                 }
        { will be inserted in front of the rest of this list.                 }
        { Insert alignment and assembler names }
        { Align, gprof uses 16 byte granularity }
        if (cs_profile in aktmoduleswitches) then
          list.concat(Tai_align.create(16))
        else
          list.concat(Tai_align.create(aktalignment.procalign));

{$ifdef GDB}
        if (cs_debuginfo in aktmoduleswitches) then
          begin
            if (po_global in current_procinfo.procdef.procoptions) then
              Tprocsym(current_procinfo.procdef.procsym).is_global:=true;
            current_procinfo.procdef.concatstabto(list);
            Tprocsym(current_procinfo.procdef.procsym).isstabwritten:=true;
          end;
{$endif GDB}

        repeat
          hs:=current_procinfo.procdef.aliasnames.getfirst;
          if hs='' then
            break;
{$ifdef GDB}
          if (cs_debuginfo in aktmoduleswitches) and
             target_info.use_function_relative_addresses then
          list.concat(Tai_stab_function_name.create(strpnew(hs)));
{$endif GDB}
          if (cs_profile in aktmoduleswitches) or
             (po_global in current_procinfo.procdef.procoptions) then
            list.concat(Tai_symbol.createname_global(hs,AT_FUNCTION,0))
          else
            list.concat(Tai_symbol.createname(hs,AT_FUNCTION,0));
        until false;
      end;



    procedure gen_proc_symbol_end(list:Taasmoutput);
{$ifdef GDB}
      var
        stabsendlabel : tasmlabel;
        mangled_length : longint;
        p : pchar;
{$endif GDB}
      begin
        list.concat(Tai_symbol_end.Createname(current_procinfo.procdef.mangledname));
{$ifdef GDB}
        if (cs_debuginfo in aktmoduleswitches) then
          begin
            objectlibrary.getlabel(stabsendlabel);
            cg.a_label(list,stabsendlabel);
            { define calling EBP as pseudo local var PM }
            { this enables test if the function is a local one !! }
            {if  assigned(current_procinfo.parent) and
                (current_procinfo.procdef.parast.symtablelevel>normal_function_level) then
              list.concat(Tai_stabs.Create(strpnew(
               '"parent_ebp:'+tstoreddef(voidpointertype.def).numberstring+'",'+
               tostr(N_LSYM)+',0,0,'+tostr(current_procinfo.parent_framepointer_offset)))); }

            if assigned(current_procinfo.procdef.funcretsym) and
               (tabstractnormalvarsym(current_procinfo.procdef.funcretsym).refs>0) then
              begin
                if tabstractnormalvarsym(current_procinfo.procdef.funcretsym).localloc.loc=LOC_REFERENCE then
                  begin
{$warning Need to add gdb support for ret in param register calling}
                    if paramanager.ret_in_param(current_procinfo.procdef.rettype.def,current_procinfo.procdef.proccalloption) then
                      begin
                        list.concat(Tai_stabs.Create(strpnew(
                           '"'+current_procinfo.procdef.procsym.name+':X*'+tstoreddef(current_procinfo.procdef.rettype.def).numberstring+'",'+
                           tostr(N_tsym)+',0,0,'+tostr(tabstractnormalvarsym(current_procinfo.procdef.funcretsym).localloc.reference.offset))));
                        if (m_result in aktmodeswitches) then
                          list.concat(Tai_stabs.Create(strpnew(
                             '"RESULT:X*'+tstoreddef(current_procinfo.procdef.rettype.def).numberstring+'",'+
                             tostr(N_tsym)+',0,0,'+tostr(tabstractnormalvarsym(current_procinfo.procdef.funcretsym).localloc.reference.offset))))
                      end
                    else
                      begin
                        list.concat(Tai_stabs.Create(strpnew(
                           '"'+current_procinfo.procdef.procsym.name+':X'+tstoreddef(current_procinfo.procdef.rettype.def).numberstring+'",'+
                           tostr(N_tsym)+',0,0,'+tostr(tabstractnormalvarsym(current_procinfo.procdef.funcretsym).localloc.reference.offset))));
                        if (m_result in aktmodeswitches) then
                          list.concat(Tai_stabs.Create(strpnew(
                             '"RESULT:X'+tstoreddef(current_procinfo.procdef.rettype.def).numberstring+'",'+
                             tostr(N_tsym)+',0,0,'+tostr(tabstractnormalvarsym(current_procinfo.procdef.funcretsym).localloc.reference.offset))));
                       end;
                  end;
              end;
            mangled_length:=length(current_procinfo.procdef.mangledname);
            getmem(p,2*mangled_length+50);
            strpcopy(p,'192,0,0,');
            strpcopy(strend(p),current_procinfo.procdef.mangledname);
            if (target_info.use_function_relative_addresses) then
              begin
                strpcopy(strend(p),'-');
                strpcopy(strend(p),current_procinfo.procdef.mangledname);
              end;
            list.concat(Tai_stabn.Create(strnew(p)));
            {List.concat(Tai_stabn.Create(strpnew('192,0,0,'
             +current_procinfo.procdef.mangledname))));
            p[0]:='2';p[1]:='2';p[2]:='4';
            strpcopy(strend(p),'_end');}
            strpcopy(p,'224,0,0,'+stabsendlabel.name);
            if (target_info.use_function_relative_addresses) then
              begin
                strpcopy(strend(p),'-');
                strpcopy(strend(p),current_procinfo.procdef.mangledname);
              end;
            list.concatlist(withdebuglist);
            list.concat(Tai_stabn.Create(strnew(p)));
             { strpnew('224,0,0,'
             +current_procinfo.procdef.mangledname+'_end'))));}
            freemem(p,2*mangled_length+50);
          end;
{$endif GDB}
      end;


    procedure gen_proc_entry_code(list:Taasmoutput);
      var
        hitemp,
        lotemp : longint;
      begin
        { generate call frame marker for dwarf call frame info }
        dwarfcfi.start_frame(list);

        { All temps are know, write offsets used for information }
        if (cs_asm_source in aktglobalswitches) then
          begin
            if tg.direction>0 then
              begin
                lotemp:=current_procinfo.tempstart;
                hitemp:=tg.lasttemp;
              end
            else
              begin
                lotemp:=tg.lasttemp;
                hitemp:=current_procinfo.tempstart;
              end;
            list.concat(Tai_comment.Create(strpnew('Temps allocated between '+std_regname(current_procinfo.framepointer)+
              tostr_with_plus(lotemp)+' and '+std_regname(current_procinfo.framepointer)+tostr_with_plus(hitemp))));
          end;

         { generate target specific proc entry code }
         cg.g_proc_entry(list,current_procinfo.calc_stackframe_size,(po_nostackframe in current_procinfo.procdef.procoptions));
      end;


    procedure gen_proc_exit_code(list:Taasmoutput);
      var
        parasize : longint;
      begin
        { c style clearstack does not need to remove parameters from the stack, only the
          return value when it was pushed by arguments }
        if current_procinfo.procdef.proccalloption in clearstack_pocalls then
          begin
            parasize:=0;
            if paramanager.ret_in_param(current_procinfo.procdef.rettype.def,current_procinfo.procdef.proccalloption) then
              inc(parasize,sizeof(aint));
          end
        else
          parasize:=current_procinfo.para_stack_size;

        { generate target specific proc exit code }
        cg.g_proc_exit(list,parasize,(po_nostackframe in current_procinfo.procdef.procoptions));

        { release return registers, needed for optimizer }
        if not is_void(current_procinfo.procdef.rettype.def) then
          location_free(list,current_procinfo.procdef.funcretloc[calleeside]);

        { end of frame marker for call frame info }
        dwarfcfi.end_frame(list);
      end;


    procedure gen_stack_check_size_para(list:Taasmoutput);
      var
        paraloc1   : tcgpara;
      begin
        paraloc1.init;
        paramanager.getintparaloc(pocall_default,1,paraloc1);
        paramanager.allocparaloc(list,paraloc1);
        cg.a_param_const(list,OS_INT,current_procinfo.calc_stackframe_size,paraloc1);
        paramanager.freeparaloc(list,paraloc1);
        paraloc1.done;
      end;


    procedure gen_stack_check_call(list:Taasmoutput);
      var
        paraloc1   : tcgpara;
      begin
        paraloc1.init;
        { Also alloc the register needed for the parameter }
        paramanager.getintparaloc(pocall_default,1,paraloc1);
        paramanager.allocparaloc(list,paraloc1);
        paramanager.freeparaloc(list,paraloc1);
        { Call the helper }
        cg.alloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));
        cg.a_call_name(list,'FPC_STACKCHECK');
        cg.dealloccpuregisters(list,R_INTREGISTER,paramanager.get_volatile_registers_int(pocall_default));
        paraloc1.done;
      end;


    procedure gen_save_used_regs(list:TAAsmoutput);
      begin
        { Pure assembler routines need to save the registers themselves }
        if (po_assembler in current_procinfo.procdef.procoptions) then
          exit;

        { oldfpccall expects all registers to be destroyed }
        if current_procinfo.procdef.proccalloption<>pocall_oldfpccall then
          cg.g_save_standard_registers(list);
      end;


    procedure gen_restore_used_regs(list:TAAsmoutput);
      begin
        { Pure assembler routines need to save the registers themselves }
        if (po_assembler in current_procinfo.procdef.procoptions) then
          exit;

        { oldfpccall expects all registers to be destroyed }
        if current_procinfo.procdef.proccalloption<>pocall_oldfpccall then
          cg.g_restore_standard_registers(list);
      end;


{****************************************************************************
                           External handling
****************************************************************************}

    procedure gen_external_stub(list:taasmoutput;pd:tprocdef;const externalname:string);
      begin
        { add the procedure to the codesegment }
        maybe_new_object_file(list);
        new_section(list,sec_code,lower(pd.mangledname),aktalignment.procalign);
        list.concat(Tai_align.create(aktalignment.procalign));
        if (po_global in pd.procoptions) then
          list.concat(Tai_symbol.createname_global(pd.mangledname,AT_FUNCTION,0))
        else
          list.concat(Tai_symbol.createname(pd.mangledname,AT_FUNCTION,0));
        cg.a_jmp_name(list,externalname);
      end;

{****************************************************************************
                               Const Data
****************************************************************************}

    procedure insertbssdata(sym : tglobalvarsym);
      var
        l,varalign : longint;
        storefilepos : tfileposinfo;
      begin
        storefilepos:=aktfilepos;
        aktfilepos:=sym.fileinfo;
        l:=sym.getsize;
        if (vo_is_thread_var in sym.varoptions) then
          inc(l,sizeof(aint));
        varalign:=var_align(l);
        maybe_new_object_file(bssSegment);
        new_section(bssSegment,sec_bss,lower(sym.mangledname),varalign);
{$ifdef GDB}
        if (cs_debuginfo in aktmoduleswitches) then
          sym.concatstabto(bssSegment);
{$endif GDB}
        if (sym.owner.symtabletype=globalsymtable) or
           maybe_smartlink_symbol or
           DLLSource or
           (assigned(current_procinfo) and
            (po_inline in current_procinfo.procdef.procoptions)) or
           (vo_is_exported in sym.varoptions) or
           (vo_is_C_var in sym.varoptions) then
          bssSegment.concat(Tai_datablock.Create_global(sym.mangledname,l))
        else
          bssSegment.concat(Tai_datablock.Create(sym.mangledname,l));
        aktfilepos:=storefilepos;
      end;


    procedure gen_alloc_symtable(list:TAAsmoutput;st:tsymtable);
      var
        sym     : tsym;
        isaddr  : boolean;
        cgsize  : tcgsize;
      begin
        sym:=tsym(st.symindex.first);
        while assigned(sym) do
          begin
            if (sym.typ in [globalvarsym,localvarsym,paravarsym]) then
              begin
                with tabstractnormalvarsym(sym) do
                  begin
                    { Parameters passed to assembler procedures need to be kept
                      in the original location }
                    if (sym.typ=paravarsym) and
                       (po_assembler in current_procinfo.procdef.procoptions) then
                      begin
                        tparavarsym(sym).paraloc[calleeside].get_location(localloc);
                      end
                    else
                      begin
                        isaddr:=(st.symtabletype=parasymtable) and
                                paramanager.push_addr_param(varspez,vartype.def,current_procinfo.procdef.proccalloption);
                        if isaddr then
                          cgsize:=OS_ADDR
                        else
                          cgsize:=def_cgsize(vartype.def);
{$ifndef OLDREGVARS}
                        { When there is assembler code we can't use regvars }
                        if is_regvar then
                          begin
                            localloc.size:=cgsize;
                            case varregable of
                              vr_intreg :
                                begin
                                  localloc.loc:=LOC_CREGISTER;
{$ifndef cpu64bit}
                                  if cgsize in [OS_64,OS_S64] then
                                    begin
                                      localloc.register64.reglo:=cg.getintregister(list,OS_32);
                                      localloc.register64.reghi:=cg.getintregister(list,OS_32);
                                    end
                                  else
{$endif cpu64bit}
                                    localloc.register:=cg.getintregister(list,cgsize);
                                end;
                              vr_fpureg :
                                begin
                                  localloc.loc:=LOC_CFPUREGISTER;
                                  localloc.register:=cg.getfpuregister(list,cgsize);
                                end;
                              vr_mmreg :
                                begin
                                  localloc.loc:=LOC_CMMREGISTER;
                                  localloc.register:=cg.getmmregister(list,cgsize);
                                end;
                              else
                                internalerror(2004101010);
                            end;
                            { Allocate register already, to prevent first allocation to be
                              inside a loop }
{$ifndef cpu64bit}
                            if cgsize in [OS_64,OS_S64] then
                              begin
                                cg.a_reg_sync(list,localloc.register64.reglo);
                                cg.a_reg_sync(list,localloc.register64.reghi);
                              end
                            else
{$endif cpu64bit}
                              cg.a_reg_sync(list,localloc.register);
                          end
                        else
{$endif NOT OLDREGVARS}
                          begin
                            localloc.loc:=LOC_REFERENCE;
                            localloc.size:=cgsize;
                            case st.symtabletype of
                              parasymtable :
                                begin
                                  { Reuse the parameter location for values to are at a single location on the stack }
                                  if paramanager.param_use_paraloc(tparavarsym(sym).paraloc[calleeside]) then
                                    begin
                                      reference_reset_base(localloc.reference,tparavarsym(sym).paraloc[calleeside].location^.reference.index,
                                          tparavarsym(sym).paraloc[calleeside].location^.reference.offset);
                                    end
                                  else
                                    begin
                                      if isaddr then
                                        tg.GetLocal(list,sizeof(aint),voidpointertype.def,localloc.reference)
                                      else
                                        tg.GetLocal(list,getsize,vartype.def,localloc.reference);
                                    end;
                                end;
                              localsymtable,
                              stt_exceptsymtable :
                                begin
                                  tg.GetLocal(list,getsize,vartype.def,localloc.reference);
                                end;
                              staticsymtable :
                                begin
                                  { PIC, DLL and Threadvar need extra code and are handled in ncgld }
                                  if not(vo_is_dll_var in varoptions) and
                                     not(vo_is_thread_var in varoptions) then
                                    reference_reset_symbol(localloc.reference,objectlibrary.newasmsymbol(mangledname,AB_EXTERNAL,AT_DATA),0);
                                end;
                              else
                                internalerror(200410103);
                            end;
                          end;
                      end;
                    if cs_asm_source in aktglobalswitches then
                      begin
                        case localloc.loc of
                          LOC_REGISTER,
                          LOC_CREGISTER :
                            begin
                              if (cs_no_regalloc in aktglobalswitches) then
                                list.concat(Tai_comment.Create(strpnew('Var '+realname+' located in register '+
                                   std_regname(localloc.register))))
                              else
                                list.concat(Tai_comment.Create(strpnew('Var '+realname+' located in register')));
                            end;
                          LOC_REFERENCE :
                            begin
                              if not assigned(localloc.reference.symbol) then
                                list.concat(Tai_comment.Create(strpnew('Var '+realname+' located at '+
                                   std_regname(localloc.reference.base)+tostr_with_plus(localloc.reference.offset))));
                            end;
                        end;
                      end;
                  end;
              end;
            sym:=tsym(sym.indexnext);
          end;
      end;


    procedure gen_free_symtable(list:TAAsmoutput;st:tsymtable);
      var
        sym : tsym;
      begin
        sym:=tsym(st.symindex.first);
        while assigned(sym) do
          begin
            if (sym.typ in [globalvarsym,localvarsym,paravarsym]) then
              begin
                with tabstractnormalvarsym(sym) do
                  begin
                    { Note: We need to keep the data available in memory
                      for the sub procedures that can access local data
                      in the parent procedures }
                    case localloc.loc of
                      LOC_CREGISTER :
{$ifndef cpu64bit}
                        if def_cgsize(vartype.def) in [OS_64,OS_S64] then
                          begin
                            cg.a_reg_sync(list,localloc.register64.reglo);
                            cg.a_reg_sync(list,localloc.register64.reghi);
                          end
                        else
{$endif cpu64bit}
                          cg.a_reg_sync(list,localloc.register);
                      LOC_CFPUREGISTER,
                      LOC_CMMREGISTER:
                        cg.a_reg_sync(list,localloc.register);
                      LOC_REFERENCE :
                        begin
                          case st.symtabletype of
                            localsymtable,
                            parasymtable,
                            stt_exceptsymtable :
                              tg.Ungetlocal(list,localloc.reference);
                          end;
                        end;
                    end;
                  end;
              end;
            sym:=tsym(sym.indexnext);
          end;
      end;


{$ifdef PASS2INLINE}
    procedure gen_alloc_inline_parast(list:TAAsmoutput;pd:tprocdef);
      var
        sym : tsym;
        calleeparaloc,
        callerparaloc : pcgparalocation;
      begin
        if (po_assembler in pd.procoptions) then
          exit;
        sym:=tsym(pd.parast.symindex.first);
        while assigned(sym) do
          begin
            if sym.typ=paravarsym then
              begin
                with tparavarsym(sym) do
                  begin
                    { for localloc <> LOC_REFERENCE, we need regvar support inside inlined procedures }
                    localloc.loc:=LOC_REFERENCE;
                    localloc.size:=int_cgsize(paramanager.push_size(varspez,vartype.def,pd.proccalloption));
                    tg.GetLocal(list,tcgsize2size[localloc.size],vartype.def,localloc.reference);
                    calleeparaloc:=paraloc[calleeside].location;
                    callerparaloc:=paraloc[callerside].location;
                    while assigned(calleeparaloc) do
                      begin
                        if not assigned(callerparaloc) then
                          internalerror(200408281);
                        if calleeparaloc^.loc<>callerparaloc^.loc then
                          internalerror(200408282);
                        case calleeparaloc^.loc of
                          LOC_FPUREGISTER:
                            begin
                              calleeparaloc^.register:=cg.getfpuregister(list,calleeparaloc^.size);
                              callerparaloc^.register:=calleeparaloc^.register;
                            end;
                          LOC_REGISTER:
                            begin
                              calleeparaloc^.register:=cg.getintregister(list,calleeparaloc^.size);
                              callerparaloc^.register:=calleeparaloc^.register;
                            end;
                          LOC_MMREGISTER:
                            begin
                              calleeparaloc^.register:=cg.getmmregister(list,calleeparaloc^.size);
                              callerparaloc^.register:=calleeparaloc^.register;
                            end;
                          LOC_REFERENCE:
                            begin
                              calleeparaloc^.reference.offset := localloc.reference.offset;
                              calleeparaloc^.reference.index := localloc.reference.base;
                              callerparaloc^.reference.offset := localloc.reference.offset;
                              callerparaloc^.reference.index := localloc.reference.base;
                            end;
                        end;
                        calleeparaloc:=calleeparaloc^.next;
                        callerparaloc:=callerparaloc^.next;
                      end;
                    if cs_asm_source in aktglobalswitches then
                      begin
                        case localloc.loc of
                          LOC_REFERENCE :
                            list.concat(Tai_comment.Create(strpnew('Para '+realname+' allocated at '+
                                std_regname(localloc.reference.base)+tostr_with_plus(localloc.reference.offset))));
                        end;
                      end;
                  end;
              end;
            sym:=tsym(sym.indexnext);
          end;
      end;


    procedure gen_alloc_inline_funcret(list:TAAsmoutput;pd:tprocdef);
      var
        callerparaloc : tlocation;
      begin
        if not assigned(pd.funcretsym) or
           (po_assembler in pd.procoptions) then
          exit;
        { for localloc <> LOC_REFERENCE, we need regvar support inside inlined procedures }
        with tabstractnormalvarsym(pd.funcretsym) do
          begin
            localloc.loc:=LOC_REFERENCE;
            localloc.size:=int_cgsize(paramanager.push_size(varspez,vartype.def,pd.proccalloption));
            tg.GetLocal(list,tcgsize2size[localloc.size],vartype.def,localloc.reference);
            callerparaloc:=pd.funcretloc[callerside];
            case pd.funcretloc[calleeside].loc of
              LOC_FPUREGISTER:
                begin
                  pd.funcretloc[calleeside].register:=cg.getfpuregister(list,pd.funcretloc[calleeside].size);
                  pd.funcretloc[callerside].register:=pd.funcretloc[calleeside].register;
                end;
              LOC_REGISTER:
                begin
  {$ifndef cpu64bit}
                  if callerparaloc.size in [OS_64,OS_S64] then
                    begin
                    end
                  else
  {$endif cpu64bit}
                    begin
                      pd.funcretloc[calleeside].register:=cg.getintregister(list,pd.funcretloc[calleeside].size);
                      pd.funcretloc[callerside].register:=pd.funcretloc[calleeside].register;
                    end;
                end;
              LOC_MMREGISTER:
                begin
                  pd.funcretloc[calleeside].register:=cg.getmmregister(list,pd.funcretloc[calleeside].size);
                  pd.funcretloc[callerside].register:=pd.funcretloc[calleeside].register;
                end;
              LOC_REFERENCE:
                begin
                  pd.funcretloc[calleeside].reference.offset := localloc.reference.offset;
                  pd.funcretloc[calleeside].reference.index := localloc.reference.base;
                  pd.funcretloc[callerside].reference.offset := localloc.reference.offset;
                  pd.funcretloc[callerside].reference.index := localloc.reference.base;
                end;
              LOC_VOID:
                ;
              else
                internalerror(200411191);
            end;
            if cs_asm_source in aktglobalswitches then
              begin
                case localloc.loc of
                  LOC_REFERENCE :
                    list.concat(Tai_comment.Create(strpnew('Funcret '+realname+' allocated at '+
                        std_regname(localloc.reference.base)+tostr_with_plus(localloc.reference.offset))));
                end;
              end;
          end;
      end;
{$endif PASS2INLINE}


    { persistent rtti generation }
    procedure generate_rtti(p:Ttypesym);
      var
        rsym : trttisym;
        def  : tstoreddef;
      begin
        { rtti can only be generated for classes that are always typesyms }
        def:=tstoreddef(ttypesym(p).restype.def);
        { there is an error, skip rtti info }
        if (def.deftype=errordef) or (Errorcount>0) then
          exit;
        { only create rtti once for each definition }
        if not(df_has_rttitable in def.defoptions) then
         begin
           { definition should be in the same symtable as the symbol }
           if p.owner<>def.owner then
            internalerror(200108262);
           { create rttisym }
           rsym:=trttisym.create(p.name,fullrtti);
           p.owner.insert(rsym);
           { register rttisym in definition }
           include(def.defoptions,df_has_rttitable);
           def.rttitablesym:=rsym;
           { write rtti data }
           def.write_child_rtti_data(fullrtti);
           maybe_new_object_file(rttilist);
           new_section(rttilist,sec_rodata,rsym.get_label.name,const_align(sizeof(aint)));
           rttiList.concat(Tai_symbol.Create_global(rsym.get_label,0));
           def.write_rtti_data(fullrtti);
           rttiList.concat(Tai_symbol_end.Create(rsym.get_label));
         end;
      end;


    { persistent init table generation }
    procedure generate_inittable(p:tsym);
      var
        rsym : trttisym;
        def  : tstoreddef;
      begin
        { anonymous types are also allowed for records that can be varsym }
        case p.typ of
          typesym :
            def:=tstoreddef(ttypesym(p).restype.def);
          globalvarsym,
          localvarsym,
          paravarsym :
            def:=tstoreddef(tabstractvarsym(p).vartype.def);
          else
            internalerror(200108263);
        end;
        { only create inittable once for each definition }
        if not(df_has_inittable in def.defoptions) then
         begin
           { definition should be in the same symtable as the symbol }
           if p.owner<>def.owner then
            internalerror(200108264);
           { create rttisym }
           rsym:=trttisym.create(p.name,initrtti);
           p.owner.insert(rsym);
           { register rttisym in definition }
           include(def.defoptions,df_has_inittable);
           def.inittablesym:=rsym;
           { write inittable data }
           def.write_child_rtti_data(initrtti);
           maybe_new_object_file(rttilist);
           new_section(rttilist,sec_rodata,rsym.get_label.name,const_align(sizeof(aint)));
           rttiList.concat(Tai_symbol.Create_global(rsym.get_label,0));
           def.write_rtti_data(initrtti);
           rttiList.concat(Tai_symbol_end.Create(rsym.get_label));
         end;
      end;



    procedure gen_intf_wrapper(list:taasmoutput;_class:tobjectdef);
      var
        i,j,
        proccount : longint;
        tmps : string;
      begin
        for i:=1 to _class.implementedinterfaces.count do
          begin
            { only if implemented by this class }
            if _class.implementedinterfaces.implindex(i)=i then
              begin
                proccount:=_class.implementedinterfaces.implproccount(i);
                for j:=1 to proccount do
                  begin
                    tmps:=make_mangledname('WRPR',_class.owner,_class.objname^+'_$_'+
                      _class.implementedinterfaces.interfaces(i).objname^+'_$_'+
                      tostr(j)+'_$_'+_class.implementedinterfaces.implprocs(i,j).mangledname);
                    { create wrapper code }
                    new_section(list,sec_code,lower(tmps),0);
                    cg.init_register_allocators;
                    cg.g_intf_wrapper(list,_class.implementedinterfaces.implprocs(i,j),tmps,_class.implementedinterfaces.ioffsets(i));
                    cg.done_register_allocators;
                  end;
              end;
          end;
      end;


    procedure gen_intf_wrappers(list:taasmoutput;st:tsymtable);
      var
        def : tstoreddef;
      begin
        def:=tstoreddef(st.defindex.first);
        while assigned(def) do
          begin
            if is_class(def) then
              gen_intf_wrapper(list,tobjectdef(def));
            def:=tstoreddef(def.indexnext);
          end;
      end;


    procedure gen_load_vmt_register(list:taasmoutput;objdef:tobjectdef;selfloc:tlocation;var vmtreg:tregister);
      var
        href : treference;
      begin
        if is_object(objdef) then
          begin
            case selfloc.loc of
              LOC_CREFERENCE,
              LOC_REFERENCE:
                begin
                  reference_reset_base(href,cg.getaddressregister(list),objdef.vmt_offset);
                  cg.a_loadaddr_ref_reg(list,selfloc.reference,href.base);
                end;
              else
                internalerror(200305056);
            end;
          end
        else
          begin
            case selfloc.loc of
              LOC_REGISTER:
                begin
{$ifdef cpu_uses_separate_address_registers}
                  if getregtype(left.location.register)<>R_ADDRESSREGISTER then
                    begin
                      reference_reset_base(href,cg.getaddressregister(list),objdef.vmt_offset);
                      cg.a_load_reg_reg(list,OS_ADDR,OS_ADDR,selfloc.register,href.base);
                    end
                  else
{$endif cpu_uses_separate_address_registers}
                    reference_reset_base(href,selfloc.register,objdef.vmt_offset);
                end;
              LOC_CREGISTER,
              LOC_CREFERENCE,
              LOC_REFERENCE:
                begin
                    reference_reset_base(href,cg.getaddressregister(list),objdef.vmt_offset);
                    cg.a_load_loc_reg(list,OS_ADDR,selfloc,href.base);
                end;
              else
                internalerror(200305057);
            end;
          end;
        vmtreg:=cg.getaddressregister(list);
        cg.g_maybe_testself(list,href.base);
        cg.a_load_ref_reg(list,OS_ADDR,OS_ADDR,href,vmtreg);
        cg.g_maybe_testvmt(list,vmtreg,objdef);
      end;

end.
