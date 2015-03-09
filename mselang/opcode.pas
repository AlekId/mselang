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
unit opcode;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 parserglob,opglob;
type
 addressbasety = (ab_segment,ab_frame,ab_reg0,ab_stack,ab_stackref);
 
type
 addressrefty = record
  offset: dataoffsty;
  case base: addressbasety of
   ab_segment: (segment: segmentty);
 end;

 loopinfoty = record
  start: opaddressty;
  size: databitsizety;
 end;

var
 optable: poptablety;
 ssatable: pssatablety;
 
  
function getglobvaraddress(const adatasize: databitsizety; const asize: integer;
                                    var aflags: addressflagsty): segaddressty;
procedure inclocvaraddress(const asize: integer);
function getlocvaraddress(const asize: integer; var aflags: addressflagsty;
                                       const shift: integer = 0): locaddressty;
function getglobconstaddress(const asize: integer; var aflags: addressflagsty;
                                       const shift: integer = 0): segaddressty;
procedure setimmboolean(const value: boolean; var par: opparamty);
procedure setimmcard8(const value: card8; var par: opparamty);
procedure setimmcard16(const value: card16; var par: opparamty);
procedure setimmcard32(const value: card32; var par: opparamty);
procedure setimmcard64(const value: card64; var par: opparamty);
procedure setimmint8(const value: int8; var par: opparamty);
procedure setimmint16(const value: int16; var par: opparamty);
procedure setimmint32(const value: int32; var par: opparamty);
procedure setimmint64(const value: int64; var par: opparamty);
procedure setimmfloat64(const value: float64; var par: opparamty);
procedure setimmsize(const value: datasizety; var par: opparamty);
procedure setimmpointer(const value: dataaddressty; var par: opparamty);
procedure setimmoffset(const value: dataoffsty; var par: opparamty);
procedure setimmdatakind(const value: datakindty; var par: opparamty);

function additem(const aopcode: opcodety;
                               const ssaextension: integer = 0): popinfoty;
function insertitem(const aopcode: opcodety; const stackoffset: integer;
                          const before: boolean;
                          const ssaextension: integer = 0): popinfoty;
function getitem(const index: integer): popinfoty;
function addcontrolitem(const aopcode: opcodety;
                               const ssaextension: integer = 0): popinfoty;

procedure addlabel();

          //refcount helpers
procedure inipointer(const aaddress: addressrefty; const count: datasizety;
                                                     const ssaindex: integer);
procedure finirefsize(const aaddress: addressrefty; const count: datasizety;
                                                     const ssaindex: integer);
procedure increfsize(const aaddress: addressrefty; const count: datasizety;
                                                     const ssaindex: integer);
procedure decrefsize(const aaddress: addressrefty; const count: datasizety;
                                                     const ssaindex: integer);

procedure beginforloop(out ainfo: loopinfoty; const count: loopcountty);
procedure endforloop(const ainfo: loopinfoty);

procedure setoptable(const aoptable: poptablety; const assatable: pssatablety);

{$ifdef mse_debugparser}
procedure dumpops();
{$endif}
implementation
uses
 stackops,handlerutils,errorhandler,segmentutils,typinfo,elements;
 
type
 opadsty = array[addressbasety] of opcodety;
 aropadsty = array[boolean] of opadsty; 

{$ifdef mse_debugparser}
procedure dumpops();
var
 int1: integer;
 po1: popinfoty;
begin
 writeln('n ssad ssa1 ssa2 ----OPS---- ',info.s.ssa.index,' ',info.s.ssa.nextindex);
 po1:= getsegmentpo(seg_op,0);
 for int1:= 0 to info.opcount-1 do begin
  with po1^.par do begin
   writeln(int1,' ',ssad,' ',ssas1,' ',ssas2,' ',
            getenumname(typeinfo(opcodety),ord(po1^.op.op)));
  end;
  inc(po1);
 end;
end;
{$endif}

procedure setoptable(const aoptable: poptablety; const assatable: pssatablety);
begin
 optable:= aoptable;
 ssatable:= assatable;
end;
 
const
 storenilops: aropadsty = (
  (
  //ab_segment,   ab_frame,      ab_reg0,
   oc_storesegnil,oc_storeframenil,oc_storereg0nil,
  //ab_stack,      ab_stackref
   oc_storestacknil,oc_storestackrefnil),
  (
  //ab_segment,     ab_frame,        ab_reg0,
   oc_storesegnilar,oc_storeframenilar,oc_storereg0nilar,
  //ab_stack,       ab_stackref
   oc_storestacknilar,oc_storestackrefnilar)
 );

 finirefsizeops: aropadsty = (
  (
  //ab_segment,         ab_frame,            ab_reg0,
   oc_finirefsizeseg,oc_finirefsizeframe,oc_finirefsizereg0,
  //ab_stack,           ab_stackref
   oc_finirefsizestack,oc_finirefsizestackref),
  (
  //ab_segment,           ab_frame,              ab_reg0,
   oc_finirefsizesegar,oc_finirefsizeframear,oc_finirefsizereg0ar,
  //ab_stack,             ab_stackref
   oc_finirefsizestackar,oc_finirefsizestackrefar)
 );

 increfsizeops: aropadsty = (
  (
  //ab_segment,         ab_frame,            ab_reg0,
   oc_increfsizeseg,oc_increfsizeframe,oc_increfsizereg0,
  //ab_stack,           ab_stackref
   oc_increfsizestack,oc_increfsizestackref),
  (
  //ab_segment,           ab_frame,              ab_reg0,
   oc_increfsizesegar,oc_increfsizeframear,oc_increfsizereg0ar,
  //ab_stack,             ab_stackref
   oc_increfsizestackar,oc_increfsizestackrefar)
 );

 decrefsizeops: aropadsty = (
  (
  //ab_segment,         ab_frame,            ab_reg0,
   oc_decrefsizeseg,oc_decrefsizeframe,oc_decrefsizereg0,
  //ab_stack,           ab_stackref
   oc_decrefsizestack,oc_decrefsizestackref),
  (
  //ab_global,           ab_frame,              ab_reg0,
   oc_decrefsizesegar,oc_decrefsizeframear,oc_decrefsizereg0ar,
  //ab_stack,             ab_stackref
   oc_decrefsizestackar,oc_decrefsizestackrefar)
 );

procedure addmanagedop(const opsar: aropadsty; 
               const aaddress: addressrefty; const count: datasizety;
               const ssaindex: integer);
begin
 if count > 1 then begin
  with additem(opsar[true][aaddress.base])^ do begin
   par.memop.t.size:= count;
   if aaddress.base = ab_segment then begin
    par.memop.segdataaddress.a.address:= aaddress.offset;
    par.memop.segdataaddress.a.segment:= aaddress.segment;
    par.memop.segdataaddress.offset:= 0;
    par.memop.t:= bitoptypes[das_pointer];
   end
   else begin
    par.memop.podataaddress:= aaddress.offset;
   end;
  end;
 end
 else begin
  with additem(opsar[false][aaddress.base])^ do begin
   if aaddress.base = ab_segment then begin
    par.memop.segdataaddress.a.address:= aaddress.offset;
    par.memop.segdataaddress.a.segment:= aaddress.segment;
    par.memop.segdataaddress.offset:= 0;
    par.memop.t:= bitoptypes[das_pointer];
   end
   else begin
    par.vaddress:= aaddress.offset;
   end;
  end;
 end;
end;

procedure inipointer(const aaddress: addressrefty; const count: datasizety;
                                                     const ssaindex: integer);
begin
 addmanagedop(storenilops,aaddress,count,ssaindex);
end;

procedure finirefsize(const aaddress: addressrefty; const count: datasizety;
                                                     const ssaindex: integer);
begin
 addmanagedop(finirefsizeops,aaddress,count,ssaindex);
end;

procedure increfsize(const aaddress: addressrefty; const count: datasizety;
                                                     const ssaindex: integer);
begin
 addmanagedop(increfsizeops,aaddress,count,ssaindex);
end;

procedure decrefsize(const aaddress: addressrefty; const count: datasizety;
                                                     const ssaindex: integer);
begin
 addmanagedop(decrefsizeops,aaddress,count,ssaindex);
end;

function getglobvaraddress(const adatasize: databitsizety; const asize: integer;
                                    var aflags: addressflagsty): segaddressty;
begin
 with info do begin
  result.address:= globdatapo;
//  result.size:= asize; //necessary for llvm global aggregate types
                       //todo: remove it, not necessary for bitcode
  globdatapo:= globdatapo + alignsize(asize);
  result.segment:= seg_globvar;
  aflags:= aflags - addresskindflags + [af_segment];
  if adatasize = das_none then begin
   include(aflags,af_aggregate);
  end;
  trackalloc(adatasize,asize,result);
 end;
end;

procedure inclocvaraddress(const asize: integer);
begin
 with info do begin
  if backend <> bke_llvm then begin
   locdatapo:= locdatapo + alignsize(asize);
  end;
 end;
end;

function getlocvaraddress(const asize: integer; var aflags: addressflagsty;
                                       const shift: integer = 0): locaddressty;
begin
 with info do begin
  if backend = bke_llvm then begin
   result.address:= info.locallocid;
   inc(info.locallocid);
  end
  else begin
   result.address:= locdatapo+shift;
  {$ifdef mse_locvarssatracking}
   result.ssaindex:= 0;
  {$endif}
   locdatapo:= locdatapo + alignsize(asize);
  end;
  result.framelevel:= info.sublevel;
  aflags:= aflags - addresskindflags + [af_local];
 end;
end;

function getglobconstaddress(const asize: integer; var aflags: addressflagsty;
                                       const shift: integer = 0): segaddressty;
begin
 result:= allocsegment(seg_globconst,asize);
 result.address:= result.address + shift;
 aflags:= aflags - addresskindflags + [af_segment];
end;

procedure setimmboolean(const value: boolean; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi1(value);
 end
 else begin
  par.imm.vboolean:= value;
 end;
end;

procedure setimmcard8(const value: card8; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi8(value);
 end
 else begin
  par.imm.vcard8:= value;
 end;
end;

procedure setimmcard16(const value: card16; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi16(value);
 end
 else begin
  par.imm.vcard16:= value;
 end;
end;

procedure setimmcard32(const value: card32; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi32(value);
 end
 else begin
  par.imm.vcard32:= value;
 end;
end;

procedure setimmcard64(const value: card64; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi64(value);
 end
 else begin
  par.imm.vcard64:= value;
 end;
end;

procedure setimmint8(const value: int8; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi8(value);
 end
 else begin
  par.imm.vint8:= value;
 end;
end;

procedure setimmint16(const value: int16; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi16(value);
 end
 else begin
  par.imm.vint16:= value;
 end;
end;

procedure setimmint32(const value: int32; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi32(value);
 end
 else begin
  par.imm.vint32:= value;
 end;
end;

procedure setimmint64(const value: int64; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  par.imm.llvm:= constlist.addi64(value);
 end
 else begin
  par.imm.vint64:= value;
 end;
end;

procedure setimmfloat64(const value: float64; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  notimplementederror('20150109A');
 end
 else begin
  par.imm.vfloat64:= value;
 end;
end;

procedure setimmsize(const value: datasizety; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  notimplementederror('20150109B');
 end
 else begin
  par.imm.vsize:= value;
 end;
end;

procedure setimmpointer(const value: dataaddressty; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  notimplementederror('20150109C');
 end
 else begin
  par.imm.vpointer:= value;
 end;
end;

procedure setimmoffset(const value: dataoffsty; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  notimplementederror('20150109D');
 end
 else begin
  par.imm.voffset:= value;
 end;
end;

procedure setimmdatakind(const value: datakindty; var par: opparamty);
begin
 par.imm.datasize:= sizeof(value);
 if info.backend = bke_llvm then begin
  notimplementederror('20150109E');
 end
 else begin
  par.imm.vdatakind:= value;
 end;
end;

procedure beginforloop(out ainfo: loopinfoty; const count: loopcountty);
begin  //todo: ssaindex
 ainfo.size:= getdatabitsize(count);
 if ainfo.size > das_32 then begin
  with additem(oc_pushimm64)^ do begin
   par.imm.vint64:= count;
   ainfo.start:= info.opcount;
   with additem(oc_decloop64)^ do begin
   end;
  end;
 end
 else begin
  with additem(oc_pushimm32)^ do begin
   par.imm.vint32:= count;
   ainfo.start:= info.opcount;
   with additem(oc_decloop32)^ do begin
   end;
  end;
 end;
end;

procedure endforloop(const ainfo: loopinfoty);
begin
 with additem(oc_goto)^ do begin
  par.opaddress.opaddress:= ainfo.start-1;
 end;
 with getoppo(ainfo.start)^ do begin
  par.opaddress.opaddress:= info.opcount-1;
 end;
 with additem(oc_locvarpop)^ do begin
  if ainfo.size > das_32 then begin
   par.stacksize:= 8;
  end
  else begin
   par.stacksize:= 4;
  end;
 end;
end;

function additem(const aopcode: opcodety;
                            const ssaextension: integer = 0): popinfoty;
begin
 with info do begin
  s.ssa.index:= s.ssa.nextindex;
  inc(s.ssa.nextindex,ssatable^[aopcode]+ssaextension);
  result:= allocsegmentpo(seg_op,sizeof(opinfoty));
  with result^ do begin
   op.op:= aopcode;
//   op.flags:= [];
   par.ssad:= s.ssa.nextindex - 1;
  end;
  inc(opcount);
 end;
end;

function addcontrolitem(const aopcode: opcodety;
                               const ssaextension: integer = 0): popinfoty;
begin
{$ifdef mse_checkinternalerror}
 if not (aopcode in controlops) then begin
  internalerror(ie_parser,'20150113A');
 end;
{$endif}
 result:= additem(aopcode,ssaextension);
 inc(info.s.ssa.blockindex);
 result^.par.opaddress.bbindex:= info.s.ssa.blockindex;
end;

function getitem(const index: integer): popinfoty;
begin
 result:= getsegmentbase(seg_op);
 inc(result,index);
end;

procedure addlabel();
begin
 with addcontrolitem(oc_label)^ do begin
  par.opaddress.opaddress:= info.opcount-1;
  par.opaddress.bbindex:= info.s.ssa.blockindex;
 end;
end;

function insertitem(const aopcode: opcodety; const stackoffset: integer;
                    const before: boolean;
                    const ssaextension: integer = 0): popinfoty;
var
 int1,int2: integer;
 ad1: opaddressty;
 po1: popinfoty;
 poend: pointer;
 ssadelta: integer;
begin
 with info do begin
  int1:= stackoffset+s.stackindex;
  if (int1 > s.stacktop) or not before and (int1 = s.stacktop) then begin
   result:= additem(aopcode,ssaextension);
   if int1 = s.stacktop then begin
    with contextstack[s.stacktop] do begin
     if d.kind in factcontexts then begin
      d.dat.fact.ssaindex:= result^.par.ssad;
     end;
    end;
   end;
  end
  else begin
   ssadelta:= ssatable^[aopcode]+ssaextension;
   allocsegmentpo(seg_op,sizeof(opinfoty));
   {
   if high(ops) < opcount then begin
    setlength(ops,(high(ops)+257)*2);
   end;
   }
   if before then begin
    ad1:= contextstack[int1].opmark.address;
   end
   else begin
    ad1:= contextstack[int1+1].opmark.address
   end;
   result:= getoppo(ad1);
   move(result^,(result+1)^,(opcount-ad1)*sizeof(opinfoty));
   result^.op.op:= aopcode;
//   if ad1 = opcount then begin
//    result^.par.ssad:= ssa.nextindex;
//   end;
   result^.par.ssad:= (result-1)^.par.ssad + ssadelta; 
                //there is at least a subbegin op
   s.ssa.index:= s.ssa.nextindex;
   inc(s.ssa.nextindex,ssadelta);
   po1:= result+1;
   poend:= po1+opcount-ad1;
   inc(opcount);
   int2:= po1^.par.ssad;
   while po1 < poend do begin
    inc(po1^.par.ssad,ssadelta);
    if po1^.par.ssas1 >= int2 then begin
     inc(po1^.par.ssas1,ssadelta);
    end;
    if po1^.par.ssas2 >= int2 then begin
     inc(po1^.par.ssas2,ssadelta);
    end;
    inc(po1);
   end;
   for int1:= int1+1 to s.stacktop do begin
    with contextstack[int1] do begin
     inc(opmark.address);
     if d.kind in factcontexts then begin
      inc(d.dat.fact.ssaindex,ssadelta);
     end;
    end;
   end;
  end;
 end;
end;
{
function insertitemafter(const stackoffset: integer;
                                         const shift: integer=0): popinfoty;
begin
 with info do begin
  if stackoffset+s.stackindex > s.stacktop then begin
   result:= additem;
  end
  else begin
   result:= insertitem(
                 contextstack[s.stackindex+stackoffset+1].opmark.address+shift);
  end;
 end;
end;
}
{
procedure writeop(const operation: opty); inline;
begin
 with additem()^ do begin
  op:= operation
 end;
end;
}
end.
