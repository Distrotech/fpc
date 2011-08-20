{
    Copyright (c) 2011 by Jonas Maebe

    This unit provides helpers for creating new syms/defs based on string
    representations.

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
{$i fpcdefs.inc}

unit symcreat;

interface

  uses
    finput,tokens,scanner,
    symconst,symdef,symbase;


  type
    tscannerstate = record
      old_scanner: tscannerfile;
      old_token: ttoken;
      old_c: char;
      valid: boolean;
    end;

  { save/restore the scanner state before/after injecting }
  procedure replace_scanner(const tempname: string; out sstate: tscannerstate);
  procedure restore_scanner(const sstate: tscannerstate);

  { parses a (class or regular) method/constructor/destructor declaration from
    str, as if it were declared in astruct's declaration body

    WARNING: save the scanner state before calling this routine, and restore
      when done. }
  function str_parse_method_dec(str: ansistring; is_classdef: boolean; astruct: tabstractrecorddef; out pd: tprocdef): boolean;

  { parses a (class or regular)  method/constructor/destructor implementation
    from str, as if it appeared in the current unit's implementation section

      WARNING: save the scanner state before calling this routine, and restore
        when done. }
  function str_parse_method_impl(str: ansistring; is_classdef: boolean):boolean;


  { in the JVM, constructors are not automatically inherited (so you can hide
    them). To emulate the Pascal behaviour, we have to automatically add
    all parent constructors to the current class as well.}
  procedure add_missing_parent_constructors_intf(obj: tobjectdef);
//  procedure add_missing_parent_constructors_impl(obj: tobjectdef);

  { goes through all defs in st to add implementations for synthetic methods
    added earlier }
  procedure add_synthetic_method_implementations(st: tsymtable);

implementation

  uses
    verbose,systems,
    symtype,symsym,symtable,defutil,
    pbase,pdecobj,psub,
    defcmp;

  procedure replace_scanner(const tempname: string; out sstate: tscannerstate);
    begin
      { would require saving of idtoken, pattern etc }
      if (token=_ID) then
        internalerror(2011032201);
      sstate.old_scanner:=current_scanner;
      sstate.old_token:=token;
      sstate.old_c:=c;
      sstate.valid:=true;
      current_scanner:=tscannerfile.Create('_Macro_.'+tempname);
    end;


  procedure restore_scanner(const sstate: tscannerstate);
    begin
      if sstate.valid then
        begin
          current_scanner.free;
          current_scanner:=sstate.old_scanner;
          token:=sstate.old_token;
          c:=sstate.old_c;
        end;
    end;


  function str_parse_method_dec(str: ansistring; is_classdef: boolean; astruct: tabstractrecorddef; out pd: tprocdef): boolean;
    var
      oldparse_only: boolean;
    begin
      Message1(parser_d_internal_parser_string,str);
      oldparse_only:=parse_only;
      parse_only:=true;
      result:=false;
      { inject the string in the scanner }
      str:=str+'end;';
      current_scanner.substitutemacro('meth_head_macro',@str[1],length(str),current_scanner.line_no,current_scanner.inputfile.ref_index);
      current_scanner.readtoken(false);
      { and parse it... }
      pd:=method_dec(astruct,is_classdef);
      if assigned(pd) then
        result:=true;
      parse_only:=oldparse_only;
    end;


  function str_parse_method_impl(str: ansistring; is_classdef: boolean):boolean;
     var
       oldparse_only: boolean;
     begin
      Message1(parser_d_internal_parser_string,str);
      oldparse_only:=parse_only;
      parse_only:=false;
      result:=false;
      { inject the string in the scanner }
      str:=str+'end;';
      current_scanner.substitutemacro('meth_impl_macro',@str[1],length(str),current_scanner.line_no,current_scanner.inputfile.ref_index);
      current_scanner.readtoken(false);
      { and parse it... }
      read_proc(is_classdef);
      parse_only:=oldparse_only;
      result:=true;
     end;


  procedure add_missing_parent_constructors_intf(obj: tobjectdef);
    var
      parent: tobjectdef;
      def: tdef;
      pd: tprocdef;
      newpd,
      parentpd: tprocdef;
      i: longint;
      srsym: tsym;
      srsymtable: tsymtable;
      isclassmethod: boolean;
      str: ansistring;
      sstate: tscannerstate;
    begin
      if not assigned(obj.childof) then
        exit;
      sstate.valid:=false;
      parent:=obj.childof;
      { find all constructor in the parent }
      for i:=0 to tobjectsymtable(parent.symtable).deflist.count-1 do
        begin
          def:=tdef(tobjectsymtable(parent.symtable).deflist[i]);
          if (def.typ<>procdef) or
             (tprocdef(def).proctypeoption<>potype_constructor) then
            continue;
          pd:=tprocdef(def);
          { do we have this constructor too? (don't use
            search_struct_member/searchsym_in_class, since those will
            search parents too) }
          if searchsym_in_record(obj,pd.procsym.name,srsym,srsymtable) then
            begin
              { there's a symbol with the same name, is it a constructor
                with the same parameters? }
              if srsym.typ=procsym then
                begin
                  parentpd:=tprocsym(srsym).find_procdef_bytype_and_para(
                    potype_constructor,pd.paras,tprocdef(def).returndef,
                    [cpo_ignorehidden,cpo_ignoreuniv,cpo_openequalisexact]);
                  if assigned(parentpd) then
                    continue;
                end;
            end;
          { if we get here, we did not find it in the current objectdef ->
            add }
          if not sstate.valid then
            replace_scanner('parent_constructors_intf',sstate);
          isclassmethod:=
            (po_classmethod in tprocdef(pd).procoptions) and
            not(tprocdef(pd).proctypeoption in [potype_constructor,potype_destructor]);
          { + 'overload' for Delphi modes }
          str:=tprocdef(pd).customprocname([pno_proctypeoption,pno_paranames,pno_noclassmarker])+'overload;';
          if not str_parse_method_dec(str,isclassmethod,obj,newpd) then
            internalerror(2011032001);
          newpd.synthetickind:=tsk_anon_inherited;
        end;
      restore_scanner(sstate);
    end;


  procedure implement_anon_inherited(pd: tprocdef);
    var
      str: ansistring;
      isclassmethod: boolean;
    begin
      isclassmethod:=
        (po_classmethod in pd.procoptions) and
        not(pd.proctypeoption in [potype_constructor,potype_destructor]);
      str:=pd.customprocname([pno_proctypeoption,pno_paranames,pno_ownername,pno_noclassmarker]);
      str:=str+'begin inherited end;';
      str_parse_method_impl(str,isclassmethod);
    end;


  procedure implement_jvm_clone(pd: tprocdef);
    var
      struct: tabstractrecorddef;
      str: ansistring;
      i: longint;
      sym: tsym;
      fsym: tfieldvarsym;
    begin
      if not(pd.owner.defowner.typ in [recorddef,objectdef]) then
        internalerror(2011032802);
      struct:=tabstractrecorddef(pd.owner.defowner);
      { anonymous record types must get an artificial name, so we can generate
        a typecast at the scanner level }
      if (struct.typ=recorddef) and
         not assigned(struct.typesym) then
        internalerror(2011032812);
      str:=pd.customprocname([pno_proctypeoption,pno_paranames,pno_ownername,pno_noclassmarker]);
      { the inherited clone will already copy all fields in a shallow way ->
        copy records/regular arrays in a regular way }
      str:=str+'begin result:=inherited;';
      for i:=0 to struct.symtable.symlist.count-1 do
        begin
          sym:=tsym(struct.symtable.symlist[i]);
          if (sym.typ=fieldvarsym) then
            begin
              fsym:=tfieldvarsym(sym);
              if (fsym.vardef.typ=recorddef) or
                 ((fsym.vardef.typ=arraydef) and
                  not is_dynamic_array(fsym.vardef)) or
                 ((fsym.vardef.typ=setdef) and
                  not is_smallset(fsym.vardef)) then
                str:=str+struct.typesym.realname+'(result).'+fsym.realname+':='+fsym.realname+';';
            end;
        end;
      str:=str+'end;';
      str_parse_method_impl(str,false);
    end;


  procedure implement_record_deepcopy(pd: tprocdef);
    var
      struct: tabstractrecorddef;
      str: ansistring;
      i: longint;
      sym: tsym;
      fsym: tfieldvarsym;
    begin
      if not(pd.owner.defowner.typ in [recorddef,objectdef]) then
        internalerror(2011032810);
      struct:=tabstractrecorddef(pd.owner.defowner);
      { anonymous record types must get an artificial name, so we can generate
        a typecast at the scanner level }
      if (struct.typ=recorddef) and
         not assigned(struct.typesym) then
        internalerror(2011032811);
      str:=pd.customprocname([pno_proctypeoption,pno_paranames,pno_ownername,pno_noclassmarker]);
      { copy all fields }
      str:=str+'begin ';
      for i:=0 to struct.symtable.symlist.count-1 do
        begin
          sym:=tsym(struct.symtable.symlist[i]);
          if (sym.typ=fieldvarsym) then
            begin
              fsym:=tfieldvarsym(sym);
              str:=str+'result.'+fsym.realname+':='+fsym.realname+';';
            end;
        end;
      str:=str+'end;';
      str_parse_method_impl(str,false);
    end;


  procedure add_synthetic_method_implementations_for_struct(struct: tabstractrecorddef);
    var
      i   : longint;
      def : tdef;
      pd  : tprocdef;
    begin
      for i:=0 to struct.symtable.deflist.count-1 do
        begin
          def:=tdef(struct.symtable.deflist[i]);
          if (def.typ<>procdef) then
            continue;
          pd:=tprocdef(def);
          case pd.synthetickind of
            tsk_none:
              ;
            tsk_anon_inherited:
              implement_anon_inherited(pd);
            tsk_jvm_clone:
              implement_jvm_clone(pd);
            tsk_record_deepcopy:
              implement_record_deepcopy(pd);
            else
              internalerror(2011032801);
          end;
        end;
    end;


  procedure add_synthetic_method_implementations(st: tsymtable);
    var
      i: longint;
      def: tdef;
      sstate: tscannerstate;
    begin
      { only necessary for the JVM target currently }
      if not (target_info.system in [system_jvm_java32]) then
        exit;
      sstate.valid:=false;
      for i:=0 to st.deflist.count-1 do
        begin
          def:=tdef(st.deflist[i]);
          if (is_javaclass(def) and
              not(oo_is_external in tobjectdef(def).objectoptions)) or
              (def.typ=recorddef) then
           begin
             if not sstate.valid then
               replace_scanner('synthetic_impl',sstate);
            add_synthetic_method_implementations_for_struct(tabstractrecorddef(def));
           end;
        end;
      restore_scanner(sstate);
    end;


end.

