{ MSElang Copyright (c) 2015-2018 by Martin Schreiber
   
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
unit unitreader;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 parserglob,unitglob;
{$goto on}
 
function readunitfile(const aunit: punitinfoty): boolean; //true if ok

implementation
uses
 filehandler,segmentutils,msestream,
 msetypes,msestrings,msesys,msesystypes,globtypes,msefileutils,
 msearrayutils,elements,sysutils,handlerglob,handlerutils,unithandler,
 identutils,opglob,opcode,errorhandler,bcunitglob,elementcache;

type
 relocinfoty = record
  base: targetadty; //first!
  offset: targetoffsty;
  size: targetsizety;
 end;
 prelocinfoty = ^relocinfoty;
 relocinfoarty = array of relocinfoty;
  
{$if sizeof(targetadty) = 4}
function cmpreloc(const l,r): integer;
begin
 result:= relocinfoty(l).base-relocinfoty(r).base;
end;
{$endif}
{
function reloc(const list: relocinfoarty; var ad: targetadty): boolean;
                 //list <> nil
var
 ilo,ihi,i1: int32;
begin
 result:= false;
 ilo:= 0;
 ihi:= high(list);
 while ilo <= ihi do begin
  i1:= (ilo+ihi+1) div 2;
  with list[i1] do begin
   if ad >= base then begin
    ilo:= i1;
    if ihi = ilo then begin
     break;
    end;
   end
   else begin
    ihi:= i1-1;
   end;
  end;
 end;
 if (ihi >= 0) then begin
  with list[ihi] do begin
   result:= ad < base + size;
   ad:= ad + offset;
  end;
 end;
end;
}
procedure reloc(const list: relocinfoarty; var ad: targetadty);
                 //list <> nil
var
 ilo,ihi,i1: int32;
begin
 ilo:= 0;
 ihi:= high(list);
 while ilo <= ihi do begin
  i1:= (ilo+ihi+1) div 2;
  with list[i1] do begin
   if ad >= base then begin
    ilo:= i1;
    if ihi = ilo then begin
     break;
    end;
   end
   else begin
    ihi:= i1-1;
   end;
  end;
 end;
 if (ihi >= 0) then begin
  with list[ihi] do begin
   if ad < base + size then begin
    ad:= ad + offset;
   end;
  end;
 end;
end;

function readunitfile(const aunit: punitinfoty): boolean; //true if ok
var
 names1,anons1: identarty;
 pd,pe: pint32;
 ns,ne: pchar;
 poend: pointer;
 po3: plenitemty;
 idmin1,idmax1: int32;
 baseoffset: elementoffsetty;
 linksstart,linksend: pointer;
 
 function updateident(var aident: int32): boolean;
 begin
  result:= false;
  if (aident < idmin1) or (aident > idmax1) then begin
   exit;
  end;
  if aident >= 0 then begin
   aident:= names1[aident];
  end
  else begin
   aident:= anons1[-1-aident];
  end;
  result:= true;
 end; //updateident

 function getdata(var source: plenitemty; out dest: usesitemarty): boolean;
 var
  ps,pd,pe: pusesitemty;
 begin
  result:= false;
  allocuninitedarray(source^.len,sizeof(usesitemty),dest);
  ps:= @source^.data;
  pe:= ps+source^.len;
  if pointer(pe) > poend then begin
   exit;
  end;
  pd:= pointer(dest);
  while ps < pe do begin
   pd^:= ps^;
   if not updateident(int32(pd^.id)) then begin
    exit;
   end;
   inc(pd);
   inc(ps);
  end;
  source:= pointer(pe);
  result:= true;
 end; //getdata

var
 mainparent: elementoffsetty;
 mainpath: identty;
 
 procedure updateref(var ref: elementoffsetty; out path: identty);
  
  procedure doexcept();
  begin
   raise exception.create('');
  end; //doexcept()
  
 var
  po1: punitlinkty;
  po2,pe: pidentty;
  po3: pelementinfoty;
 begin
  if ref > 0 then begin
   ref:= ref + baseoffset-1;
   po3:= ele.eleinfoabs(ref);
   path:= po3^.header.path+po3^.header.name;
  end
  else begin
   if ref < 0 then begin
    if (ref = -1) and (mainparent >= 0) then begin
     ref:= mainparent;
     path:= mainpath;
    end
    else begin
     po1:= linksstart - ref - 1;
     if po1 >= linksend then begin
      doexcept();
     end;
     po2:= @po1^.ids;
     pe:= po2+po1^.len;
     if pe > linksend then begin
      doexcept();
     end;
     path:= 0;
     while po2 < pe do begin
      if not updateident(int32(po2^)) then begin
       doexcept();
      end;
      path:= path + po2^;
      inc(po2);
     end;
     po2:= @po1^.ids;
     if not ele.findreverse(po1^.len,po2,ref) then begin
      doexcept();
     end;
    end;
   end;
  end;
 end;

type
 relocinfoarty = array of relocinfoty;

 function dosort(var ar: relocinfoarty): boolean;
 var
  i1: int32;
 begin
  result:= true;
  if ar <> nil then begin
   sortarray(ar,sizeof(ar[0]),@cmpreloc);
   for i1:= 0 to high(ar) - 1 do begin
    with ar[i1] do begin
     if base + size > ar[i1+1].base then begin
      result:= false;
      break;
     end;
    end;
   end;
  end;
 end;

 procedure addrelocitem(const abase: targetadty; const aref: targetadty;
                            const asize: targetadty; 
                                 var alist: relocinfoarty; var acount: int32);
 begin
  with alist[acount] do begin
   offset:= aref-abase;
   if offset <> 0 then begin
    size:= asize;
    base:= abase;
    inc(acount);
   end;
  end;
 end;

var
// globreloc1: relocinfoarty;
// opreloc1: relocinfoarty;
 elereloc1: relocinfoarty;
 globvarreloccount: int32;
// opreloccount: int32;
 elereloccount: int32;

 procedure addrelocs(const aunit: punitinfoty; const auses: unitrelocty);
 begin
  with auses do begin
{
   addrelocitem(interfaceglobstart,
        aunit^.reloc.interfaceglobstart,aunit^.reloc.interfaceglobsize,
        globreloc1,globvarreloccount);
   addrelocitem(opstart,
        aunit^.reloc.opstart,aunit^.reloc.opsize,
        opreloc1,opreloccount);
}
  end;
 end;//addrelocs()
 
 function checkfilematch(const aunit: punitinfoty;
                           const amatchinfo: usesitemty): boolean;
 begin
  result:= aunit <> nil;
  if result then begin
   with amatchinfo do begin
    if not comparemem(@aunit^.filematch.guid,@filematchx.guid,
                                            sizeof(filematchx.guid)) or
       (aunit^.filematch.timestamp <> filematchx.timestamp){ or
       (aunit^.reloc.interfaceglobsize <> reloc.interfaceglobsize) or 
       (aunit^.reloc.opsize <> reloc.opsize)} then begin
     result:= false;
    end;
   end;
  end;
 end;//checkfilematch()

var
 unitsegments1: unitsegmentsstatety;
 segmentssaved: boolean;

 procedure savesegs();
 begin
  saveunitsegments(unitsegments1);
  segmentssaved:= true;
 end; //savesegs

 procedure restoresegs();
 begin
  restoreunitsegments(unitsegments1);
  segmentssaved:= false;
 end; //restoresegs
 
var
 stream1,stream2: tmsefilestream;
 fna1,fna2: filenamety;
 intf: punitintfinfoty;
 interfaceuses1,implementationuses1: usesitemarty;
 interfaceunits1: unitinfopoarty;
 pele1: pelementinfoty;
 po: pointer;
 i1,i2: int32;
 startref: markinfoty;
 segstate1: segmentstatety;
 haselereloc: boolean;
 unit1: punitinfoty;
// globvaroffset: elementoffsetty;
// opoffset1: targetoffsty;
 op1,ope: popinfoty;
 isub1: internalsubty;
 bcheader1: bcunitheaderty;
 bo1: boolean;
 pe1,pee: pelementoffsetty;
 id1: identty;
 mop1: managedopty;
 sa1: objsubattachty;
 str1: lstringty;
 p1: pointer;
label
 errorlab,fatallab,oklab,endlab;
begin
 result:= false;
 segmentssaved:= false;
 fna1:= getcompunitfile(aunit);
{$ifdef mse_debugparser}
 writeln('***** reading unit '+fna1);
{$endif}
 if (fna1 <> '') and 
       (tmsefilestream.trycreate(stream1,fna1,fm_read) = sye_ok) then begin
  inc(info.compileinfo.unitcount);
  aunit^.rtfilepath:= fna1;
  resetunitsegments();
  ele.markelement(startref);
  try
   result:= checksegmentdata(stream1,getfilekind(mlafk_rtunit),
                                              aunit^.filematch.timestamp) and
             readsegmentdata(stream1,getfilekind(mlafk_rtunit),
                [seg_unitintf,seg_unitlinks,seg_unitidents,seg_unitconstbuf]);
   if result then begin
    result:= false;
    if getsegmentsize(seg_unitintf) < sizeof(unitintfinfoty) then begin
     goto endlab; //invalid
    end;
    linksstart:= getsegmentbase(seg_unitlinks);
    linksend:= linksstart + getsegmentsize(seg_unitlinks);
    intf:= getsegmentbase(seg_unitintf);
    if intf^.header.anoncount < 1 then begin
     goto endlab; //invalid, no parserglob.idstart
    end;
    aunit^.filematch.guid:= intf^.header.filematch.guid;
    if co_llvm in info.o.compileoptions then begin
     if co_objmodules in info.o.compileoptions then begin
      fna2:= getobjunitfile(aunit);
      if fna2 = '' then begin
       goto endlab; //*.o file not found
      end;
      if getfilemodtime(fna2) < getfilemodtime(fna1) then begin
       goto endlab; //invalid     //todo: use guid
      end;
      aunit^.objfilepath:= fna2;
     end
     else begin
      fna1:= getbcunitfile(aunit);
      if fna1 = '' then begin
       goto endlab; //llvm bc file not found
      end;
      if tmsefilestream.trycreate(stream2,fna1) <> sye_ok then begin
       goto endlab;
      end;
      bo1:= (stream2.tryreadbuffer(bcheader1,sizeof(bcheader1)) = sye_ok) and
               (comparebyte(bcheader1.header.guid,
                                      aunit^.filematch.guid,sizeof(tguid)) = 0);
      stream2.destroy();
      if not bo1 then begin
       goto endlab;
      end;
      aunit^.bcfilepath:= fna1;
     end;
    end;
    allocuninitedarray(intf^.header.anoncount,sizeof(identty),anons1);
    pd:= pointer(anons1);
    pe:= pd + length(anons1);
    pd^:= idstart;
    inc(pd);
    while pd < pe do begin
     pd^:= getident();
     inc(pd);
    end;
    allocuninitedarray(intf^.header.namecount,sizeof(identty),names1);
    pd:= pointer(names1);
    pe:= pd + length(names1);
    ne:= getsegmentbase(seg_unitidents);
    poend:= pointer(ne) + getsegmentsize(seg_unitidents);     
    while pd < pe do begin
     ns:= @pidentstringty(ne)^.data;
     ne:= ns + pidentstringty(ne)^.len;
     if ne > poend then begin
      goto endlab; //invalid
     end;
     pd^:= getident(ns,ne);
     inc(pd);
    end;
    idmin1:= -length(anons1);
    idmax1:= high(names1);
    po3:= @intf^.interfaceuses;
    poend:= getsegmenttop(seg_unitintf);
    if not getdata(po3,interfaceuses1) or
                              not getdata(po3,implementationuses1) then begin
     goto endlab;
    end;
//    setlength(globreloc1,length(interfaceuses1)+length(implementationuses1)+3);
         //max, + own interface and implementation globvar block,
         //exitcode todo: remove this
//    setlength(opreloc1,length(globreloc1)); //max
//    setlength(elereloc1,length(globreloc1)); //max
    setlength(elereloc1,length(interfaceuses1)+length(implementationuses1)+3);
         //max, + own interface and implementation globvar block,
    globvarreloccount:= 0;
//    opreloccount:= 0;
    elereloccount:= 0;

    include(aunit^.state,us_interfaceparsed);
    savesegs();
    setlength(interfaceunits1,length(interfaceuses1));
    for i1:= 0 to high(interfaceuses1) do begin
     unit1:= loadunitbyid(interfaceuses1[i1].id);
     interfaceunits1[i1]:= unit1;
     if not checkfilematch(unit1,interfaceuses1[i1]) then begin
      restoresegs();
      goto endlab;
     end;
     addrelocs(unit1,interfaceuses1[i1].reloc);
    end;
    for i1:= 0 to high(implementationuses1) do begin
     with implementationuses1[i1] do begin
      if getunittimestamp(id) <> filematchx.timestamp then begin
       goto endlab; //needs recompilation
      end;
     end;
    end;
    restoresegs();

//    inc(info.globdatapo,intf^.header.reloc.interfaceglobsize); 

//    ele.markelement(startref);
    if not updateident(int32({ptrint(}intf^.header.key{)})) then begin
     goto errorlab;
    end;
    beginunit(intf^.header.key,true);

    baseoffset:= ele.eletopoffset;

    aunit^.reloc:= intf^.header.reloc;
//    aunit^.reloc.interfaceglobstart:= info.globdatapo;
    aunit^.reloc.interfaceelestart:= baseoffset;
    with intf^.header.reloc do begin       
{
     addrelocitem(interfaceglobstart,info.globdatapo,interfaceglobsize,
                                                 globreloc1,globvarreloccount);
                                                 //own interface globvars
     globvaroffset:= info.globdatapo-interfaceglobstart;
}
     addrelocitem(interfaceelestart,aunit^.reloc.interfaceelestart,
                   interfaceelesize,elereloc1,elereloccount);
                                                 //own interface elements
    end;
    for i1:= 0 to high(interfaceunits1) do begin
     with interfaceunits1[i1]^ do begin
      addrelocitem(interfaceuses1[i1].reloc.interfaceelestart,
           reloc.interfaceelestart,reloc.interfaceelesize,
           elereloc1,elereloccount);
     end;
    end;
    setlength(elereloc1,elereloccount);
    haselereloc:= elereloc1 <> nil;
    if not dosort(elereloc1) then begin
     goto errorlab;
    end;
    i1:= getsegmentsize(seg_unitintf) + 
                        (getsegmentbase(seg_unitintf)-pointer(po3));
    pele1:= ele.addbuffer(i1);
    poend:= pointer(pele1) + i1;
    move(po3^,pele1^,i1); //todo: read segment data directly to ele buffer
    mainparent:= -1;
    while pele1 < poend do begin
     with pele1^ do begin
      if not updateident(int32(header.name)) then begin
       goto errorlab;
      end;
      header.defunit:= aunit;
     {$ifdef mse_debugparser}
      inc(header.next,baseoffset);
     {$endif}
      if (header.parentlevel >= maxidentvector) or 
                         (header.parentlevel < 0) then begin
       goto errorlab; //invalid
      end;

      if mainparent < 0 then begin
       if header.parent <> -1 then begin
        goto errorlab;
       end;
       updateref(mainparent,mainpath);
       with ele.eleinfoabs(mainparent)^ do begin
        if (header.kind <> ek_unit) or (header.parentlevel <> 2) then begin
         goto errorlab;
        end;
       end;
      end;

      updateref(header.parent,header.path);
      ele.enterbufferitem(pele1); //enter in hash and data table
      po:= @data;
      case header.kind of
       ek_type: begin
        with ptypedataty(po)^ do begin
         if not updateident(int32(h.signature)) then begin
          goto errorlab;
         end;
         updateref(h.base,id1);
         updateref(h.ancestor,id1);
         case h.kind of
          dk_enum: begin
           updateref(infoenum.first,id1);
           updateref(infoenum.last,id1);
          end;
          dk_enumitem: begin
           updateref(infoenumitem.enum,id1);
           updateref(infoenumitem.next,id1);
          end;
          dk_set: begin
           updateref(infoset.itemtype,id1);
          end;
          dk_array: begin
           updateref(infoarray.i.itemtypedata,id1);
           updateref(infoarray.indextypedata,id1);
          end;
          dk_dynarray,dk_openarray: begin
           updateref(infodynarray.i.itemtypedata,id1);
          end;
          dk_record,dk_class,dk_object: begin
//           if (tf_needsmanage in h.flags) or (h.kind <> dk_record){ or 
//                               (h.manageproc = mpk_record)} then begin
           if tf_managehandlervalid in h.flags then begin
            for mop1:= low(mop1) to high(mop1) do begin
             updateref(recordmanagehandlers[mop1],id1);
            end;
           end;
           updateref(fieldchain,id1);
           case h.kind of
            dk_class,dk_object: begin
             updateref(infoclass.subchain,id1);
             for sa1:= low(infoclass.subattach) to 
                            high(infoclass.subattach) do begin
              updateref(infoclass.subattach[sa1],id1);
             end;
            end;
           end;
          end;
          dk_sub,dk_method: begin
           updateref(infosub.sub,id1);
          end;
         end;
        end;
       end;
       ek_field: begin
        with pfielddataty(po)^ do begin
         updateref(vf.typ,id1);
         updateref(vf.next,id1);
        end;
       end;
       ek_var: begin
        with pvardataty(po)^ do begin
         updateref(vf.typ,id1);
         updateref(vf.defaultconst,id1);
         updateref(vf.next,id1);
        end;
       end;
       ek_property: begin
        with ppropertydataty(po)^ do begin
         updateref(typ,id1);
         updateref(readele,id1);
         updateref(writeele,id1);
  //      if not updateref(defaultconst) then begin
  //       goto errorlab
  //      end;
        end;
       end;
       ek_const: begin
        with pconstdataty(po)^ do begin
         updateref(val.typ.typedata,id1);
         case val.d.kind of
          dk_string: begin
           if not getsegmentpo(seg_unitconstbuf,val.d.vstring.offset,
                                                 sizeof(int32),p1) then begin
            goto errorlab;
           end;
           str1.len:= pint32(p1)^;
           if not getsegmentpo(seg_unitconstbuf,
                val.d.vstring.offset+sizeof(int32),str1.len,str1.po) then begin
            goto errorlab;
           end;
           val.d.vstring:= newstringconst(str1);
          end;
          dk_set: begin
           if val.d.vset.kind = das_bigint then begin
            if not getsegmentpo(seg_unitconstbuf,val.d.vset.bigsetvalue.offset,
                                                  sizeof(int32),p1) then begin
             goto errorlab;
            end;
            str1.len:= pint32(p1)^;
            if not getsegmentpo(seg_unitconstbuf,
               val.d.vset.bigsetvalue.offset+sizeof(int32),
                                                  str1.len,str1.po) then begin
             goto errorlab;
            end;
            val.d.vset.bigsetvalue:= newstringconst(str1);
           end;
          end;
         end;
        end;
       end;
       ek_ref: begin
        with prefdataty(po)^ do begin
         updateref(ref,id1);
        end;
       end;
       ek_sub: begin
        with psubdataty(po)^ do begin
         updateref(next,id1);
         updateref(nextoverload,id1);
         updateref(typ,id1);
         updateref(resulttype.typeele,id1);
         pe1:= @paramsrel;
         pee:= pe1+paramcount;
         while pointer(pe1) < pointer(pee) do begin
          updateref(pe1^,id1);
          inc(pe1);
         end;
         inc(pointer(pele1),paramcount*sizeof(elementoffsetty));
        end;
       end;
       ek_internalsub: begin
       end;
       ek_alias: begin
       end;
       ek_operator: begin
        with poperatordataty(po)^ do begin
         updateref(methodele,id1);
        end;
       end;
       ek_unit: begin
       end;
       ek_implementation: begin
        with pimplementationdataty(po)^ do begin
        end;
       end;
       ek_uses: begin
       end;
       ek_condition: begin
       end;
       ek_none: begin
       end;
       ek_classintfnamenode: begin
       end;
       ek_classintftypenode: begin
       end;
       ek_classimpnode: begin
       end;
       else begin
        goto errorlab;
       end;
      end;
      inc(pointer(pele1),elesizes[header.kind]);
     end;     
    end;
    if pele1 <> poend then begin
     goto errorlab;
    end;

    savesegs();
    for i1:= 0 to high(implementationuses1) do begin
     unit1:= loadunitbyid(implementationuses1[i1].id);
     if not checkfilematch(unit1,implementationuses1[i1]) then begin
      restoresegs();
                  //todo: try restart instead of fatal error
      if unit1 <> nil then begin
       errormessage(err_invalidunitfile,[unit1^.filepath]);
      end
      else begin
       errormessage(err_invalidunitfile,
                                   [getidentname(implementationuses1[i1].id)]);
      end;
      goto errorlab;
     end;
     addrelocs(unit1,implementationuses1[i1].reloc);
    end;
    restoresegs();
    aunit^.implementationglobstart:= info.globdatapo;
    with intf^.header do begin            
{
     addrelocitem(implementationglobstart,info.globdatapo,
                          implementationglobsize,globreloc1,globvarreloccount);
                                      //own implementation globvars
}
//     addrelocitem(reloc.opstart,info.opcount,reloc.opsize,
//                                                    opreloc1,opreloccount);
                                      //own op segment
//     opoffset1:= info.opcount-reloc.opstart;
     aunit^.internalsubnames:= internalsubnames;
    end;
//    setlength(globreloc1,globvarreloccount);
//    setlength(opreloc1,opreloccount);
    aunit^.implementationglobsize:= intf^.header.implementationglobsize;
    inc(info.globdatapo,intf^.header.implementationglobsize);
(*
    if not dosort(globreloc1) {or not dosort(opreloc1)} then begin
     errormessage(err_invalidunitfile,[aunit^.filepath]);
     goto fatallab;
    end;
*)
    goto oklab;
fatallab:
    include(info.s.state,ps_abort);
errorlab:
    ele.releaseelement(startref);
    goto endlab;
oklab:
    with aunit^ do begin
//     mainad:= intf^.header.mainad + opoffset1;
    end;
    if co_llvm in info.o.compileoptions then begin
     result:= true;
    end
    else begin
     stream1.position:= 0;           //todo: reduce file seeking
     segstate1:= savesegment(seg_op);
     op1:= getsegmenttop(seg_op);
     result:= readsegmentdata(stream1,getfilekind(mlafk_rtunit),[seg_op]);
{
     if (globreloc1 <> nil) and result then begin
      pointer(op1):= pointer(op1)+(getsegmentbase(seg_op)-segstate1.data);
      ope:= getsegmenttop(seg_op);
      while op1 < ope do begin
       with optable^[op1^.op.op] do begin
        if of_relocseg in flags then begin
         reloc(globreloc1,targetadty(op1^.par.memop.segdataaddress.a.address));
        end;
       end;
       inc(op1);
      end;
     end;
}
     if result then begin
//      inc(info.opcount,intf^.header.reloc.opsize);
     end
     else begin
      restoresegment(segstate1);
     end;
    end;
endlab:
   end;
  except //catch all exceptions of an invalid unit file
   result:= false;
   ele.releaseelement(startref);
   if segmentssaved then begin
    restoresegs();
   end;
  end;
  stream1.destroy();
  resetunitsegments();
  if not result then begin
//   info.globdatapo:= globpobefore; not possible because of uses modules
   exclude(aunit^.state,us_interfaceparsed);
   include(aunit^.state,us_invalidunitfile);
  end;
 end;
 if result and (co_compilefileinfo in info.o.compileoptions) then begin
  writeln('load '+quotefilename(fna1));
 end;
{$ifdef mse_debugparser}
 if result then begin
  writeln('** read unit '+fna1+' OK');
 end
 else begin
  writeln('** read unit '+fna1+' ***ERROR***');
 end;
{$endif}
 end;
end.
