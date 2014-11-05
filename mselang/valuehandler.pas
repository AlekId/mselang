{ MSElang Copyright (c) 2013-2014 by Martin Schreiber
   
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
}
unit valuehandler;
{$ifdef FPC}{$mode objfpc}{$goto on}{$h+}{$endif}
interface
uses
 parserglob,handlerglob;
 
function tryconvert(const stackoffset: integer;
          const dest: ptypedataty; const destindirectlevel: integer): boolean;

procedure handlevalueidentifier();

implementation
uses
 errorhandler,elements,handlerutils,opcode,stackops,segmentutils,opglob,
 subhandler,grammar,unithandler,syssubhandler,classhandler,interfacehandler;

function tryconvert(const stackoffset: integer;{var context: contextitemty;}
          const dest: ptypedataty; const destindirectlevel: integer): boolean;
var                     //todo: optimize, use tables, complete
 source1: ptypedataty;
 int1: integer;
begin
 with info,contextstack[stackindex+stackoffset] do begin
  source1:= ele.eledataabs(d.dat.datatyp.typedata);
  result:= destindirectlevel = d.dat.datatyp.indirectlevel;
  if result then begin
   result:= dest^.kind = source1^.kind;
   if not result then begin
    case d.kind of
     ck_const: begin
      case dest^.kind of //todo: use table
       dk_float: begin
        case source1^.kind of
         dk_integer: begin //todo: adjust data size
          with d,dat.constval do begin
           kind:= dk_float;
           vfloat:= vinteger;
          end;
          result:= true;
         end;
        end;
       end;
      end;
     end;
     ck_fact: begin
      case dest^.kind of //todo: use table
       dk_float: begin
        case source1^.kind of
         dk_integer: begin //todo: adjust data size
          with additem(oc_int32toflo64)^ do begin
          end;
          result:= true;
         end;
        end;
       end;
      end;
     end;
    {$ifdef mse_checkinternalerror}
     else begin
      internalerror(ie_handler,'20131121B');
     end;
    {$endif}
    end;
   end;
  end
  else begin
   if (d.kind in [ck_fact,ck_ref]) and (destindirectlevel = 0) and
         (d.dat.datatyp.indirectlevel = 1) and 
         (source1^.kind = dk_class) and (dest^.kind = dk_interface) then begin
    if getclassinterfaceoffset(source1,dest,int1) then begin
     if getvalue(stackoffset) then begin
      with insertitem(oc_offsetpoimm32,stackoffset,false)^ do begin
       setimmint32(int1,par);
      end;
      result:= true;
     end;
    end;
   end;
  end;
  if result then begin
   d.dat.datatyp.typedata:= ele.eledatarel(dest);
  end;
 end;
end;
 
procedure handlevalueidentifier();
var
 paramco: integer;

 function checknoparam: boolean;
 begin
  result:= paramco = 0;
  if not result then begin
   with info,contextstack[stackindex].d do begin
    errormessage(err_syntax,[';'],1,ident.len);
   end;
  end;
 end;

var
 idents: identvecty;
 firstnotfound: integer;
 po1: pelementinfoty;
 po2: pointer;

 procedure dosub(const asub: psubdataty);
 var
  po1: popinfoty;
  po3: ptypedataty;
  po5: pelementoffsetty;
  po6: pvardataty;
  po7: pelementinfoty;
  paramco1: integer;
  int1: integer;
  parallocstart: dataoffsty;
                     //todo: paralloc info for hidden params
 begin
  with info do begin
   po5:= @asub^.paramsrel;
   paramco1:= paramco;
   if [sf_function,sf_constructor] * asub^.flags <> [] then begin
    inc(paramco1); //result parameter
   end;
   if sf_method in asub^.flags then begin
    inc(paramco1); //self parameter
   end;
   if paramco1 <> asub^.paramcount then begin
    identerror(idents.high+1,err_wrongnumberofparameters);
   end
   else begin
    if sf_method in asub^.flags then begin
     inc(po5); //instance pointer
    end;
    
    parallocstart:= getsegmenttopoffs(seg_localloc);    
    if sf_function in asub^.flags then begin
     with pparallocinfoty(
               allocsegmentpo(seg_localloc,sizeof(parallocinfoty)))^ do begin
      ssaindex:= 0;
      po3:= ele.eledataabs(asub^.resulttype);
      size:= getopdatatype(po3,po3^.indirectlevel);
      {
      if po3^.indirectlevel > 0 then begin
       bitsize:= pointerbitsize;
      end
      else begin
       bitsize:= po3^.bitsize;
      end;
      }
     end;
    end;

    for int1:= stackindex+3+idents.high to stacktop do begin
     po6:= ele.eledataabs(po5^);
     with contextstack[int1] do begin
      if af_paramindirect in po6^.address.flags then begin
       case d.kind of
        ck_const: begin
         if not (af_const in po6^.address.flags) then begin
          errormessage(err_variableexpected,[],int1-stackindex);
         end
         else begin
          internalerror1(ie_notimplemented,'20140405B'); //todo
         end;
        end;
        ck_ref: begin
         pushinsertaddress(int1-stackindex,false);
        end;
       end;
      end
      else begin
       case d.kind of
        ck_const: begin
         pushinsertconst(int1-stackindex,false);
        end;
        ck_ref: begin
         getvalue(int1-stackindex{,true});
        end;
       end;
      end;
      if d.dat.datatyp.typedata <> po6^.vf.typ then begin
       errormessage(err_incompatibletypeforarg,
                   [int1-stackindex-3,typename(d),
                   typename(ptypedataty(ele.eledataabs(po6^.vf.typ))^)],
                                                        int1-stackindex);
      end;
      with pparallocinfoty(
                allocsegmentpo(seg_localloc,sizeof(parallocinfoty)))^ do begin
       ssaindex:= d.dat.fact.ssaindex;
       size:= getopdatatype(po6^.vf.typ,po6^.address.indirectlevel);
      {
       if po6^.address.indirectlevel > 0 then begin
        bitsize:= pointerbitsize;
       end
       else begin
        bitsize:= ptypedataty(ele.eledataabs(po6^.vf.typ))^.bitsize;
       end;
      }
      end;
     end;
     inc(po5);
    end;
              //todo: exeenv flag for constructor and destructor
    with contextstack[stackindex] do begin //result data
     if [sf_constructor,sf_function] * asub^.flags <> [] then begin
      po6:= ele.eledataabs(po5^);
      if (sf_constructor in asub^.flags) and 
                                  (ele.lastdescendent <> 0) then begin
       po3:= ptypedataty(ele.eledataabs(ele.lastdescendent));
      end
      else begin
       po3:= ptypedataty(ele.eledataabs(po6^.vf.typ));
      end;
      if not backendhasfunction then begin
       int1:= pushinsertvar(parent-stackindex,false,po3); 
                                    //alloc space for return value
      end;
      initfactcontext(0); //set ssaindex
      d.kind:= ck_subres;
      d.dat.datatyp.indirectlevel:= po6^.address.indirectlevel;
      d.dat.fact.opdatatype:= getopdatatype(po3,d.dat.datatyp.indirectlevel);
      if not backendhasfunction then begin
       dec(d.dat.datatyp.indirectlevel);
      end;
      d.dat.datatyp.typedata:= po6^.vf.typ;        
      if not backendhasfunction then begin
       with additem(oc_pushstackaddr)^ do begin //result var param
        par.voffset:= -asub^.paramsize+stacklinksize-int1;
       end;
       if sf_constructor in asub^.flags then begin
        pushinsertsegaddress(parent-stackindex,false,po3^.infoclass.defs);
                                    //class type
       end;
      end;
     end
     else begin
      d.kind:= ck_subcall;
      if (sf_method in asub^.flags) and (idents.high = 0) then begin
                 //owned method
      {$ifdef mse_checkinternalerror}
       if ele.findcurrent(tks_self,[],allvisi,po6) <> ek_var then begin
        internalerror(ie_value,'20140505A');
       end;
      {$else}
       ele.findcurrent(tks_self,[],allvisi,po6);
      {$endif}
       with insertitem(oc_pushlocpo,parent-stackindex,false)^ do begin
        par.memop.locdataaddress.a.framelevel:= -1;
        par.memop.locdataaddress.a.address:= po6^.address.poaddress;
        par.memop.locdataaddress.offset:= 0;
       end;
      end;
     end;
    end;
   end;
   if asub^.flags * [sf_virtual,sf_override,sf_interface] <> [] then begin
    if sf_interface in asub^.flags then begin
     po1:= additem(oc_callintf);
     po1^.par.virtcallinfo.virtoffset:= asub^.tableindex*sizeof(intfitemty);
    end
    else begin
     po1:= additem(oc_callvirt);
     po1^.par.virtcallinfo.virtoffset:= asub^.tableindex*sizeof(opaddressty)+
                                                          virtualtableoffset;
    end;
    po1^.par.virtcallinfo.selfinstance:= -asub^.paramsize;
   end
   else begin
    if (asub^.nestinglevel = 0) or 
                     (asub^.nestinglevel = sublevel) then begin
     if sf_function in asub^.flags then begin
      po1:= additem(oc_callfunc);
     end
     else begin
      po1:= additem(oc_call);
     end;
     po1^.par.callinfo.linkcount:= -1;
    end
    else begin
     int1:= sublevel-asub^.nestinglevel;
     if sf_function in asub^.flags then begin
      po1:= additem(oc_callfuncout,getssa(ocssa_nestedcallout,int1));
     end
     else begin
      po1:= additem(oc_callout,getssa(ocssa_nestedcallout,int1));
     end;
     po1^.par.callinfo.linkcount:= int1-2;      //for downto 0
     po7:= ele.parentelement;
     include(psubdataty(@po7^.data)^.flags,sf_hasnestedaccess);
     for int1:= int1-1 downto 0 do begin
      po7:= ele.eleinfoabs(po7^.header.parent);
      include(psubdataty(@po7^.data)^.flags,sf_hasnestedref);
      if int1 <> 0 then begin
       include(psubdataty(@po7^.data)^.flags,sf_hasnestedaccess);
       include(psubdataty(@po7^.data)^.flags,sf_hascallout);
      end;
     end;
    end;
    if asub^.address = 0 then begin //unresolved header
     linkmark(asub^.links,getsegaddress(seg_op,@po1^.par.callinfo.ad));
    end;
    with po1^ do begin
     par.callinfo.flags:= asub^.flags;
     par.callinfo.params:= parallocstart;
     par.callinfo.paramcount:= paramco1;    
     par.callinfo.ad:= asub^.address-1; //possibly invalid
    end;
   end;
  end;
 end; //dosub
 
 procedure donotfound(const typeele: elementoffsetty);
 var
  int1: integer;
  po4: pointer;
  ele1: elementoffsetty;
  offs1: dataoffsty;
 begin
  if firstnotfound <= idents.high then begin
   ele1:= typeele;
   offs1:= 0;
   with info do begin
    for int1:= firstnotfound to idents.high do begin //fields
     case ele.findchild(ele1,idents.d[int1],[],allvisi,ele1,po4) of
      ek_none: begin
       identerror(1+int1,err_identifiernotfound);
       exit;
      end;
      ek_field: begin
       with contextstack[stackindex],pfielddataty(po4)^ do begin
        ele1:= pfielddataty(po4)^.vf.typ;
        case d.kind of
         ck_ref: begin
          if af_classfield in flags then begin
           dec(d.dat.indirection);
          end;
          d.dat.ref.offset:= d.dat.ref.offset + offset;
         end;
         ck_fact: begin     //todo: check indirection
          offs1:= offs1 + offset;
         end;
        {$ifdef mse_checkinternalerror}
         else begin
          internalerror(ie_value,'20140427A');
         end;
        {$endif}
        end;
        d.dat.datatyp.typedata:= ele1; //todo: adress operator
        d.dat.datatyp.indirectlevel:= 
                       ptypedataty(ele.eledataabs(ele1))^.indirectlevel;
       end;
      end;
      ek_sub: begin
       if int1 <> idents.high then begin
        errormessage(err_illegalqualifier,[],int1+1,0,erl_fatal);
        exit;
       end;
       case po1^.header.kind of
        ek_var: begin //todo: check class procedures
         pushinsertdata(0,false,pvardataty(po2)^.address,ele.eledatarel(po2),
                                                         offs1,pointeroptype);
        end;
        ek_type: begin
         if not (sf_constructor in psubdataty(po4)^.flags) then begin
          errormessage(err_classref,[],int1+1);
          exit;
         end;
         pushinsert(0,false,nilad,0,false);
        end;
        else begin
         internalerror1(ie_notimplemented,'20140417A');
        end;
       end;
       dosub(psubdataty(po4));
       exit;
      end;
      else begin
       identerror(1+int1,err_wrongtype,erl_fatal);
       exit;
      end;
     end;
    end;
    if offs1 <> 0 then begin
     offsetad(-1,offs1);
    end;
   end;
  end; 
 end;//donotfound
  
var
 po3: ptypedataty;
 po4: pointer;
 po5: pelementoffsetty;
 po6: pvardataty;
 po7: pointer;
 ele1,ele2: elementoffsetty;
 int1,int2,int3: integer;
 si1: datasizety;
// offs1: dataoffsty;
 indirect1: indirectlevelty;
 stacksize1: datasizety;
 paramco1: integer;
 isgetfact: boolean;
label
 endlab;
begin
{$ifdef mse_debugparser}
 outhandle('VALUEIDENTIFIER');
{$endif}
 with info do begin
  ele.pushelementparent();
  isgetfact:= false;
  with contextstack[stackindex-1] do begin
   case d.kind of
    ck_getfact: begin
     isgetfact:= true;
    end;
    ck_ref: begin
     po3:= ele.eledataabs(d.dat.datatyp.typedata);
     if (d.dat.datatyp.indirectlevel <> 0) or 
                                (po3^.kind <> dk_record) then begin
      errormessage(err_illegalqualifier,[]);
      goto endlab;
     end
     else begin
      ele.elementparent:= d.dat.datatyp.typedata;
     end;
    end;
    else begin
     internalerror1(ie_notimplemented,'20140406A');
    end;
   end;
  end;
  if findkindelements(1,[],allvisi,po1,firstnotfound,idents) then begin
   paramco:= stacktop-stackindex-2-idents.high;
   if paramco < 0 then begin
    paramco:= 0; //no paramsend context
   end;
  end
  else begin
   identerror(1,err_identifiernotfound);
   goto endlab;
  end;
  if po1^.header.kind = ek_ref then begin
   po1:= ele.eleinfoabs(prefdataty(@po1^.data)^.ref);
  end;
  po2:= @po1^.data;
  with contextstack[stackindex] do begin
   d.dat.indirection:= 0;
   case po1^.header.kind of
    ek_var,ek_field: begin
     if po1^.header.kind = ek_field then begin
      with pfielddataty(po2)^ do begin
       if isgetfact then begin
        if af_classfield in flags then begin
         if not ele.findcurrent(tks_self,[],allvisi,ele2) then begin
          errormessage(err_noclass,[],0);
          goto endlab;
         end;
       {$ifdef mse_checkinternalerror}
        end
        else begin
         internalerror(ie_value,'201400427B');
         goto endlab;
       {$endif}
        end;
        initfactcontext(0); 
        d.dat.datatyp.typedata:= vf.typ;
        d.dat.datatyp.indirectlevel:= indirectlevel;
        d.dat.indirection:= -1;
        d.dat.ref.c.address:= pvardataty(ele.eledataabs(ele2))^.address;
        d.dat.ref.offset:= offset;
        d.dat.ref.c.varele:= 0;
       end
       else begin
        d:= contextstack[stackindex-1].d; 
                  //todo: no double copy by handlefact
        case d.kind of
         ck_ref: begin
          d.dat.datatyp.typedata:= vf.typ;
          d.dat.datatyp.indirectlevel:= indirectlevel;
          d.dat.ref.offset:= offset;
          d.dat.ref.c.varele:= 0;
         end;
         ck_fact: begin
          internalerror1(ie_notimplemented,'20140427E'); //todo
         end;
        {$ifdef mse_checkinternalerror}
         else begin
          internalerror(ie_value,'20140427D');
         end;
        {$endif}
        end;
       end;
       donotfound(d.dat.datatyp.typedata);
      end;
     end
     else begin //ek_var
      if isgetfact then begin
       d.kind:= ck_ref;
       d.dat.ref.c.address:= pvardataty(po2)^.address;
       d.dat.ref.offset:= 0;
       d.dat.ref.c.varele:= ele.eledatarel(po2); //used to store ssaindex
       d.dat.datatyp.typedata:= pvardataty(po2)^.vf.typ;
       d.dat.datatyp.indirectlevel:= d.dat.ref.c.address.indirectlevel +
           ptypedataty(ele.eledataabs(d.dat.datatyp.typedata))^.indirectlevel;
       d.dat.indirection:= 0;
      end
      else begin
       with contextstack[stackindex-1] do begin
        if d.dat.indirection <> 0 then begin
         getaddress(-1,false);
         dec(d.dat.indirection); //pending dereference
        end;
        contextstack[stackindex].d:= d; 
                  //todo: no double copy by handlefact
       end;
      end;
      donotfound(pvardataty(po2)^.vf.typ);
     end;
    end;
    ek_const: begin
     if checknoparam then begin
      d.kind:= ck_const;
      d.dat.indirection:= 0;
      d.dat.datatyp:= pconstdataty(po2)^.val.typ;
      d.dat.constval:= pconstdataty(po2)^.val.d;
     end;
    end;
    ek_sub: begin
     dosub(psubdataty(po2));
    end;
    ek_sysfunc: begin
     with contextstack[stackindex] do begin
      d.kind:= ck_subcall;
     end;
     with psysfuncdataty(po2)^ do begin
      sysfuncs[func](paramco);
     end;
    end;
    ek_type: begin
     if firstnotfound > idents.high then begin
      if paramco = 0 then begin
       with ptypedataty(po2)^ do begin
        if kind = dk_enumitem then begin
         d.kind:= ck_const;
         d.dat.indirection:= 0;
         d.dat.datatyp.flags:= [];
         d.dat.datatyp.typedata:= infoenumitem.enum;
         d.dat.datatyp.indirectlevel:= 0;
         d.dat.constval.kind:= dk_enum;
         d.dat.constval.vinteger:= infoenumitem.value;
        end
        else begin         
         with ptypedataty(po2)^ do begin
          d.kind:= ck_typearg;
          d.typ.flags:= flags;
          d.typ.typedata:= ele.eledatarel(po2);
          d.typ.indirectlevel:= indirectlevel;
          if not isgetfact then begin
           d.typ.indirectlevel:= d.typ.indirectlevel +
                    contextstack[stackindex-1].d.dat.indirection;
          end;
         end;
         
       {
         errormessage(err_illegalexpression,[],stacktop-stackindex);
       }
        end;
       end;
      end
      else begin          //type conversion
       if paramco > 1 then begin
        errormessage(err_closeparentexpected,[],4,-1);
       end
       else begin
        if not tryconvert(stacktop-stackindex,po2,
                                 ptypedataty(po2)^.indirectlevel) then begin
         illegalconversionerror(contextstack[stacktop].d,po2,
                                     ptypedataty(po2)^.indirectlevel);
        end
        else begin
         contextstack[stackindex].d:= contextstack[stacktop].d;
        end;
       end;
      end;
     end
     else begin
      donotfound(ele.eleinforel(po1));
     end;
    end;
   end;
  end;
endlab:
  ele.popelementparent();
  stacktop:= stackindex;
  dec(stackindex);
 end;
end;

end.
