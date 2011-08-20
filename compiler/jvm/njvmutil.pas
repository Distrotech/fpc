{
    Copyright (c) 20011 by Jonas Maebe

    JVM version of some node tree helper routines

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
unit njvmutil;

{$i fpcdefs.inc}

interface

  uses
    node,
    ngenutil,
    symtype,symconst,symsym;


  type
    tjvmnodeutils = class(tnodeutils)
      class function initialize_data_node(p:tnode):tnode; override;
      class function finalize_data_node(p:tnode):tnode; override;
      class function force_init: boolean; override;
      class procedure insertbssdata(sym: tstaticvarsym); override;
      class function create_main_procdef(const name: string; potype: tproctypeoption; ps: tprocsym): tdef; override;
      class procedure InsertInitFinalTable; override;
      class procedure InsertThreadvarTablesTable; override;
      class procedure InsertThreadvars; override;
      class procedure InsertWideInitsTablesTable; override;
      class procedure InsertWideInits; override;
      class procedure InsertResourceTablesTable; override;
      class procedure InsertResourceInfo(ResourcesUsed : boolean); override;
      class procedure InsertMemorySizes; override;
     strict protected
       class procedure add_main_procdef_paras(pd: tdef); override;
    end;


implementation

    uses
      verbose,cutils,globals,constexp,fmodule,
      aasmdata,aasmtai,cpubase,aasmcpu,
      symdef,symbase,symtable,defutil,jvmdef,
      nbas,ncnv,ncon,ninl,ncal,
      ppu,
      pass_1;

  class function tjvmnodeutils.initialize_data_node(p:tnode):tnode;
    begin
      if not assigned(p.resultdef) then
        typecheckpass(p);
      if ((p.resultdef.typ=stringdef) and
          not is_shortstring(p.resultdef) and
          not is_longstring(p.resultdef)) or
         is_dynamic_array(p.resultdef) then
        begin
          { Always initialise with empty string/array rather than nil. Java
            makes a distinction between an empty string/array and a null
            string/array,  but we don't. We therefore have to pick which one we
            use to represent empty strings/arrays. I've chosen empty rather than
            null structures, because otherwise it becomes impossible to return
            an empty string to Java code (it would return null).

            On the consumer side, we do interpret both null and empty as the same
            thing, so Java code can pass in null strings/arrays and we'll
            interpret them correctly.
          }
          result:=cinlinenode.create(in_setlength_x,false,
            ccallparanode.create(genintconstnode(0),
              ccallparanode.create(p,nil)));
        end
      else
        begin
          p.free;
          { records/arrays/... are automatically initialised }
          result:=cnothingnode.create;
        end;
    end;


  class function tjvmnodeutils.finalize_data_node(p:tnode):tnode;
    begin
      // do nothing
      p.free;
      result:=cnothingnode.create;
    end;


  class function tjvmnodeutils.force_init: boolean;
    begin
      { we need an initialisation in case the al_globals list is not empty
        (that's where the initialisation for global records etc is added) }
      { problem: some bss symbols are only registered while processing the main
        program (e.g. constant sets) -> cannot predict whether or not we'll
        need it in advance }
      result:=true;
    end;

  class procedure tjvmnodeutils.insertbssdata(sym: tstaticvarsym);
    begin
      { handled while generating the unit/program init code, or class
        constructor; add something to al_globals to indicate that we need to
        insert an init section though }
      if current_asmdata.asmlists[al_globals].empty and
         jvmimplicitpointertype(sym.vardef) then
        current_asmdata.asmlists[al_globals].concat(cai_align.Create(1));
    end;


  class function tjvmnodeutils.create_main_procdef(const name: string; potype: tproctypeoption; ps: tprocsym): tdef;
    begin
      if (potype=potype_proginit) then
        begin
          result:=inherited create_main_procdef('main', potype, ps);
          include(tprocdef(result).procoptions,po_global);
          tprocdef(result).visibility:=vis_public;
        end
      else
        result:=inherited create_main_procdef(name, potype, ps);
    end;


  class procedure tjvmnodeutils.InsertInitFinalTable;
    var
      hp : tused_unit;
      unitinits : TAsmList;
      unitclassname: string;
      mainpsym: tsym;
      mainpd: tprocdef;
    begin
      unitinits:=TAsmList.Create;
      hp:=tused_unit(usedunits.first);
      while assigned(hp) do
        begin
          { class constructors are automatically handled by the JVM }

          { call the unit init code and make it external }
          if (hp.u.flags and (uf_init or uf_finalize))<>0 then
            begin
              { trigger init code by referencing the class representing the
                unit; if necessary, it will register the fini code to run on
                exit}
              unitclassname:='';
              if assigned(hp.u.namespace) then
                begin
                  unitclassname:=hp.u.namespace^+'/';
                  replace(unitclassname,'.','/');
                end;
              unitclassname:=unitclassname+hp.u.realmodulename^;
              unitinits.concat(taicpu.op_sym(a_new,current_asmdata.RefAsmSymbol(unitclassname)));
              unitinits.concat(taicpu.op_none(a_pop));
            end;
          hp:=tused_unit(hp.next);
        end;
      { insert in main program routine }
      mainpsym:=tsym(current_module.localsymtable.find(mainaliasname));
      if not assigned(mainpsym) or
         (mainpsym.typ<>procsym) then
        internalerror(2011041901);
      mainpd:=tprocsym(mainpsym).find_procdef_bytype(potype_proginit);
      if not assigned(mainpd) then
        internalerror(2011041902);
      mainpd.exprasmlist.insertList(unitinits);
      unitinits.free;
    end;


  class procedure tjvmnodeutils.InsertThreadvarTablesTable;
    begin
      { not yet supported }
    end;


  class procedure tjvmnodeutils.InsertThreadvars;
    begin
      { not yet supported }
    end;


  class procedure tjvmnodeutils.InsertWideInitsTablesTable;
    begin
      { not required }
    end;


  class procedure tjvmnodeutils.InsertWideInits;
    begin
      { not required }
    end;


  class procedure tjvmnodeutils.InsertResourceTablesTable;
    begin
      { not supported }
    end;


  class procedure tjvmnodeutils.InsertResourceInfo(ResourcesUsed: boolean);
    begin
      { not supported }
    end;


  class procedure tjvmnodeutils.InsertMemorySizes;
    begin
      { not required }
    end;


  class procedure tjvmnodeutils.add_main_procdef_paras(pd: tdef);
    var
      pvs: tparavarsym;
    begin
      if (tprocdef(pd).proctypeoption=potype_proginit) then
        begin
          { add the args parameter }
          pvs:=tparavarsym.create('$args',1,vs_const,search_system_type('TJSTRINGARRAY').typedef,[]);
          tprocdef(pd).parast.insert(pvs);
          tprocdef(pd).calcparas;
        end;
    end;


begin
  cnodeutils:=tjvmnodeutils;
end.

