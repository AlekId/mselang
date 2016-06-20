{ MSElang Copyright (c) 2013-2016 by Martin Schreiber
   
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
unit handlerutils;
{$ifdef FPC}{$mode objfpc}{$h+}{$goto on}{$endif}
interface
uses
 globtypes,handlerglob,parserglob,opglob,elements,msestrings,msetypes;

type
 datasizetyxx = type integer;
 
 systypeinfoty = record
  name: string;
  data: typedataty;
 end;
 sysconstinfoty = record
  name: string;
  ctyp: systypety;
  cval: dataty;
 end;
  
 opsinfoty = record
  ops: array[stackdatakindty] of opcodety;
  wantedtype: systypety;
  opname: string;
 end;

var
 unitsele: elementoffsetty;
 sysdatatypes: array[systypety] of typeinfoty;
 emptyset: typeinfoty;

const
 basedatatypes: array[databitsizety] of systypety = (
 //das_none,das_1,   das_2_7,das_8,  das_9_15,das_16,  das_17_31,das_32,
  st_none,  st_bool1,st_none,st_int8,st_int16,st_int16,st_int32, st_int32,
//das_33_63,das_64,  das_pointer,das_f16,das_f32,das_f64,   das_sub,das_meta
  st_int64, st_int64,st_pointer, st_none,st_none,st_flo64,st_none,st_none
 );

 stackdatakinds: array[datakindty] of stackdatakindty = (
   //dk_none,dk_pointer,dk_boolean,dk_cardinal,dk_integer,dk_float,dk_kind,
    sdk_none,sdk_pointer,sdk_bool1,sdk_card32, sdk_int32, sdk_flo64,sdk_none,
  //dk_address,dk_record,dk_string,dk_dynarray,dk_openarray,dk_array,
    sdk_pointer,  sdk_none, sdk_none, sdk_none,sdk_none,    sdk_none,
  //dk_class,dk_interface
    sdk_none,sdk_none,
  //dk_sub
    sdk_pointer,
  //dk_enum,dk_enumitem, dk_set,   dk_character,dk_data
    sdk_none,   sdk_none, sdk_none,sdk_card32,  sdk_none);
                
 resultdatakinds: array[stackdatakindty] of datakindty =
          //sdk_none,sdk_pointer,sdk_bool1,sdk_card32,sdk_int32,sdk_flo64,
           (dk_none,dk_pointer,dk_boolean,dk_cardinal,dk_integer,dk_float,
          //sdk_set32
            dk_set);
 resultdatatypes: array[stackdatakindty] of systypety =
          //sdk_none,sdk_pointer,sdk_bool1,sdk_card32,sdk_int32,sdk_flo64
           (st_none, st_pointer, st_bool1, st_card32, st_int32, st_flo64,
          //sdk_set32
            st_card32);

 popindioptable: array[databitsizety] of opcodety = (
 //das_none,      das_1,          das_2_7,        das_8,
   oc_popindirect,oc_popindirect8,oc_popindirect8,oc_popindirect8,
 //das_9_15,        das_16,          das_17_31,       das_32,
   oc_popindirect16,oc_popindirect16,oc_popindirect32,oc_popindirect32,
 //das_33_63,       das_64,          das_pointer
   oc_popindirect64,oc_popindirect64,oc_popindirectpo,
 //das_f16,          das_f32,          das_f64
   oc_popindirectf16,oc_popindirectf32,oc_popindirectf64,
 //das_sub,         das_meta
   oc_popindirectpo,oc_none
   );
 
function getidents(const astackoffset: integer;
                     out idents: identvecty): boolean; overload;
function getidents(const astackoffset: integer): identvecty; overload;
 
function findkindelementdata(const aident: contextdataty;
              const akinds: elementkindsty; const visibility: visikindsty;
                                    out ainfo: pointer): boolean;
function findkindelements(
           const astackoffset: integer; const akinds: elementkindsty; 
           const visibility: visikindsty; out aelement: pelementinfoty;
           out firstnotfound: integer; out idents: identvecty;
            const remainder: int32 = 0): boolean;
function findkindelements(
           const astackoffset: integer; const akinds: elementkindsty; 
           const visibility: visikindsty; out aelement: pelementinfoty;
           const noerror: boolean = false): boolean;
function findkindelementsdata(
              const astackoffset: integer; const akinds: elementkindsty;
              const visibility: visikindsty; out ainfo: pointer;
              out firstnotfound: integer; out idents: identvecty;
              const rest: int32 = 0): boolean;
function findkindelementsdata(
              const astackoffset: integer; const akinds: elementkindsty;
              const visibility: visikindsty; out ainfo: pointer): boolean;

function findvar(const astackoffset: integer; 
        const visibility: visikindsty; out varinfo: vardestinfoty): boolean;
function addvar(const aname: identty; const avislevel: visikindsty;
          var chain: elementoffsetty; out aelementdata: pvardataty): boolean;

procedure addfactbinop(const poa,pob: pcontextitemty;const aopcode: opcodety);
procedure resolveshortcuts(const posource,podest: pcontextitemty);
procedure updateop(const opsinfo: opsinfoty);
function convertconsts(const poa,pob: pcontextitemty): stackdatakindty;
function compaddress(const a,b: addressvaluety): integer;

function getcontextopoffset(const stackoffset: int32): int32;
            //returns opcount in context

function getvalue(const acontext: pcontextitemty; const adatasize: databitsizety;
                               const retainconst: boolean = false): boolean;
//function getvalue(const stackoffset: integer; const adatasize: databitsizety;
//                               const retainconst: boolean = false): boolean;
function getaddress(const acontext: pcontextitemty;
                                  const endaddress: boolean): boolean;
function getassignaddress(const acontext: pcontextitemty;
                                  const endaddress: boolean): boolean;
//function getassignaddress(const stackoffset: integer;
//                                  const endaddress: boolean): boolean;
procedure getclassvalue(const acontext: pcontextitemty);

function pushtemp(const address: addressvaluety;
                                      const alloc: typeallocinfoty): int32;
                                                              //returns ssad
function pushtempindi(const address: addressvaluety;
                                      const alloc: typeallocinfoty): int32;
                                                              //returns ssad
function pushtemppo(const address: addressvaluety): int32;
                                                              //returns ssad
procedure poptemp(const asize: int32);

procedure push(const avalue: boolean); overload;
procedure push(const avalue: integer); overload;
procedure push(const avalue: real); overload;
procedure push( const atype: typeinfoty; const avalue: addressvaluety;
                const offset: dataoffsty{; const indirect: boolean}); overload;
procedure push(const avalue: datakindty); overload;
//procedure pushconst(var avalue: contextdataty);
procedure pushdata(const address: addressvaluety;
                   const varele: elementoffsetty;
                   const offset: dataoffsty;
                   const opdatatype: typeallocinfoty);
function getaddreftype(const aref: addressrefty): ptypedataty;
function pushaddr(const aref: addressrefty{; const atype: ptypedataty;}
                            {const assaindex: int32}): int32; //returns ssad

procedure pushinsertstack(const stackoffset: int32; //context stack
               const aopoffset: int32; const sourceoffset: int32{;
                                              const adatasize: databitsizety});
procedure pushinsertstackindi(const stackoffset: int32; //context stack
                          const aopoffset: int32; const sourceoffset: int32{;
                                              const adatasize: databitsizety});

procedure pushinsert(const stackoffset: integer; const aopoffset: int32;
                  const avalue: datakindty); overload;
procedure pushinsert(const stackoffset: integer; const aopoffset: int32;
            const atype: typeinfoty;
            const avalue: addressvaluety; const offset: dataoffsty{;
                                            const indirect: boolean}); overload;
            //class field address
function pushinsertvar(const stackoffset: int32; const aopoffset: int32;
              const indirectlevel: int32; const atype: ptypedataty): integer;
procedure pushinsertsegaddresspo(const stackoffset: integer;
                            const aopoffset: int32; const address: segaddressty);
procedure pushinsertdata(const stackoffset: integer; const aopoffset: int32;
                  const address: addressvaluety;
                  const varele: elementoffsetty;
                  const offset: dataoffsty;
                  const opdatatype: typeallocinfoty);
procedure pushinsertaddress(const stackoffset: integer; const aopoffset: int32);
procedure pushinsertconst(const stackoffset: integer; const aopoffset: int32;
                                              const adatasize: databitsizety);
procedure pushinsertconst(const stackoffset: int32; const constval: dataty;
                       const aopoffset: int32; const adatasize: databitsizety);

procedure offsetad(const stackoffset: integer; const aoffset: dataoffsty);
procedure checkneedsunique(const stackoffset: int32);


//procedure setcurrentloc(const indexoffset: integer);
procedure setcurrentlocbefore(const indexoffset: integer);
procedure setlocbefore(const destindexoffset,sourceindexoffset: integer);
//procedure setloc(const destindexoffset,sourceindexoffset: integer);

procedure getordrange(const typedata: ptypedataty; out range: ordrangety);
function getordrange(const typedata: ptypedataty): ordrangety; inline;
function getordcount(const typedata: ptypedataty): int64;
function getordconst(const avalue: dataty): int64;
function getdatabitsize(const avalue: int64): databitsizety;

function getcontextssa(const stackoffset: int32): int32;

function getstackindex(const acontext: pcontextitemty): int32;
function getstackoffset(const acontext: pcontextitemty): int32;
function getpreviousnospace(const astackindex: int32): int32;
function getpreviousnospace(const apo: pcontextitemty): pcontextitemty;
function getnextnospace(const current: pcontextitemty): pcontextitemty;
function getnextnospace(const astackindex: int32): int32;
function getnextnospace(const astackindex: int32; 
                                out apo: pcontextitemty): boolean;
                                   //true if found
function getnextnospace(const current: pcontextitemty;
                                      out apo: pcontextitemty): boolean;
                                   //true if found
function getspacecount(const astackindex: int32): int32;
               //counts ck_space from astackindex to stacktop
function getitemcount(const acontext: pcontextitemty): int32;
               //counts not ck_space from acontext to stacktop
function getitemcount(const astackindex: int32): int32;
               //counts not ck_space from astackindex to stacktop
function getfactstart(const astackindex: int32;
                        out acontext: pcontextitemty): boolean; 
                                     //converts ck_list, false on error

procedure initdatacontext(var acontext: contextdataty;
                                             const akind: contextkindty);
procedure initfactcontext(const stackoffset: int32);
procedure initblockcontext(const stackoffset: int32);
procedure newblockcontext(const stackoffset: int32);
procedure finiblockcontext(const stackoffset: int32);

function initopenarrayconst(var adata: dataty; const itemcount: int32;
                                     const itemsize: int32): pointer;
                                         //returns pointer to data block
//procedure trackalloc(const asize: integer; var address: addressvaluety);
procedure trackalloc(const adatasize: databitsizety; const asize: integer; 
                                 var address: segaddressty);
//procedure trackalloc(const asize: integer; var address: addressvaluety);
//procedure allocsubvars(const asub: psubdataty; out allocs: suballocinfoty);
procedure tracklocalaccess(var aaddress: locaddressty; 
                                 const avarele: elementoffsetty;
                                 const aopdatatype: typeallocinfoty);
function trackaccess(const avar: pvardataty): addressvaluety;
function trackaccess(const asub: psubdataty): int32;

procedure resetssa();
function getssa(const aopcode: opcodety): integer;
function getssa(const aopcode: opcodety; const count: integer): integer;
//function getssaext(const aopcode: opcodety; const hasext: boolean): integer;
                                               //false -> 0
function getopdatatype(const atypeinfo: typeinfoty): typeallocinfoty;
function getopdatatype(const atypedata: elementoffsetty;
                           const aindirectlevel: integer): typeallocinfoty;
function getopdatatype(const atypedata: ptypedataty;
                           const aindirectlevel: integer): typeallocinfoty;
function getopdatatype(const adest: vardestinfoty): typeallocinfoty;
function getbytesize(const aopdatatype: typeallocinfoty): integer;
function getbasetypedata(const abitsize: databitsizety): ptypedataty;
function getbasetypeele(const abitsize: databitsizety): elementoffsetty;
function issametype(const a,b: ptypedataty): boolean; 
                                        //follow typex = typey chain
function issametype(const a,b: elementoffsetty): boolean; 

function getsystypeele(const atype: systypety): elementoffsetty;
procedure setsysfacttype(var acontextdata: contextdataty; 
                                             const atype: systypety);

procedure sethandlerflag(const avalue: handlerflagty);
procedure sethandlererror();

procedure setenumconst(const aenumitem: infoenumitemty; 
                                   var acontextitem: contextitemty);
//procedure setcurrentscope(const ascope: metavaluety);
procedure pushcurrentscope(const ascope: metavaluety);
procedure popcurrentscope();

procedure initsubdef(const aflags: subflagsty);

procedure init();
procedure deinit();

{$ifdef mse_debugparser}
procedure outhandle(const text: string);
procedure outinfo(const text: string; const indent: boolean = true);
procedure dumpelements();
{$endif}

implementation
uses
 errorhandler,typinfo,opcode,stackops,parser,sysutils,mseformatstr,
 syssubhandler,managedtypes,grammar,segmentutils,valuehandler,unithandler,
 identutils,llvmbitcodes,llvmlists;
   
const
 mindouble = -1.7e308;
 maxdouble = 1.7e308; //todo: use exact values
 
  //will be replaced by systypes.mla
 systypeinfos: array[systypety] of systypeinfoty = (
   (name: 'none'; data: (h: (ancestor: 0; kind: dk_none;
       base: 0; rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 0; bytesize: 0; datasize: das_none; next: 0);
       dummy1: 0)),
   (name: 'pointer'; data: (h: (ancestor: 0; kind: dk_pointer;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 1;
       bitsize: pointerbitsize; bytesize: pointersize;
                                      datasize: das_pointer; next: 0);
       dummy1: 0)),
   (name: 'bool1'; data: (h: (ancestor: 0; kind: dk_boolean;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 1; bytesize: 1; datasize: das_1; next: 0);
       dummy1: 0)),
   (name: 'int8'; data: (h: (ancestor: 0; kind: dk_integer;
       base: 0;  rtti: 0; manageproc: nil; flags: [];indirectlevel: 0;
       bitsize: 8; bytesize: 1; datasize: das_8; next: 0);
       infoint8:(min: int8($80); max: $7f))),
   (name: 'int16'; data: (h: (ancestor: 0; kind: dk_integer;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 16; bytesize: 2; datasize: das_16; next: 0);
       infoint16:(min: int16($8000); max: $7fff))),
   (name: 'int32'; data: (h: (ancestor: 0; kind: dk_integer;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 32; bytesize: 4; datasize: das_32; next: 0);
      infoint32:(min: int32($80000000); max: $7fffffff))),
   (name: 'int64'; data: (h: (ancestor: 0; kind: dk_integer;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 64; bytesize: 8; datasize: das_64; next: 0);
       infoint64:(min: int64($8000000000000000); max: $7fffffffffffffff))),
   (name: 'card8'; data: (h: (ancestor: 0; kind: dk_cardinal;
       base: 0;  rtti: 0; manageproc: nil; flags: [];indirectlevel: 0;
       bitsize: 8; bytesize: 1; datasize: das_8; next: 0);
       infocard8:(min: int8($00); max: $ff))),
   (name: 'card16'; data: (h: (ancestor: 0; kind: dk_cardinal;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 16; bytesize: 2; datasize: das_16; next: 0);
       infocard16:(min: int16($0000); max: $ffff))),
   (name: 'card32'; data: (h: (ancestor: 0; kind: dk_cardinal;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 32; bytesize: 4; datasize: das_32; next: 0);
      infocard32:(min: int32($00000000); max: $ffffffff))),
   (name: 'card64'; data: (h: (ancestor: 0; kind: dk_cardinal;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 64; bytesize: 8; datasize: das_64; next: 0);
       infocard64:(min: $0000000000000000; max: card64($ffffffffffffffff)))),
   (name: 'flo64'; data: (h: (ancestor: 0; kind: dk_float;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 64; bytesize: 8; datasize: das_f64; next: 0);
       infofloat64:(min: mindouble; max: maxdouble))),
   (name: 'char8'; data: (h: (ancestor: 0; kind: dk_character;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 8; bytesize: 1; datasize: das_8; next: 0);
       infochar8:(min: int8($00000000); max: $ff))),
   (name: 'char16'; data: (h: (ancestor: 0; kind: dk_character;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 16; bytesize: 2; datasize: das_16; next: 0);
       infochar16:(min: int16($00000000); max: $ffff))),
   (name: 'char32'; data: (h: (ancestor: 0; kind: dk_character;
       base: 0;  rtti: 0; manageproc: nil; flags: []; indirectlevel: 0;
       bitsize: 32; bytesize: 4; datasize: das_32; next: 0);
       infochar32:(min: int32($00000000); max: $ffffffff))),
   (name: 'string8'; data: (h: (ancestor: 0; kind: dk_string8;
       base: 0;  rtti: 0; manageproc: @managestring8;
       flags: [tf_needsmanage,tf_managed]; indirectlevel: 0;
       bitsize: pointerbitsize; bytesize: pointersize;
                                          datasize: das_pointer; next: 0);
       itemsize: 1; dummy2: 0))
  );
 sysconstinfos: array[0..2] of sysconstinfoty = (
   (name: 'false'; ctyp: st_bool1; cval:(kind: dk_boolean; vboolean: false)),
   (name: 'true'; ctyp: st_bool1; cval:(kind: dk_boolean; vboolean: true)),
   (name: 'nil'; ctyp: st_pointer; cval:(kind: dk_pointer; 
             vaddress: (flags: [af_nil]; indirectlevel: 0; poaddress: 0)))
  );
    
{ 
procedure error(const error: comperrorty;
                   const pos: pchar=nil);
begin
 outcommand([],'*ERROR* '+errormessages[error]);
end;
}
procedure initsubdef(const aflags: subflagsty);
begin
 with info,contextstack[s.stackindex].d do begin
  kind:= ck_subdef;
  subdef.flags:= aflags;
 end;
end;

function findkindelementdata(const aident: contextdataty;
              const akinds: elementkindsty;
              const visibility: visikindsty; out ainfo: pointer): boolean;
var
 po1: pelementinfoty;
 ele1: elementoffsetty;
begin
 result:= false;
 if aident.kind = ck_ident then begin
  if ele.findcurrent(aident.ident.ident,akinds,visibility,ele1) then begin
   po1:= ele.eleinfoabs(ele1);
   ainfo:= @po1^.data;
   result:= true;
  end;
 end;
end;

function findkindelementdata(
              const astackoffset: integer;
              const akinds: elementkindsty;
              const visibility: visikindsty; out ainfo: pointer): boolean;
begin
 with info do begin
  result:= findkindelementdata(contextstack[s.stackindex+astackoffset].d,
                                                      akinds,visibility,ainfo);
 end;
end;

function getidents(const astackoffset: integer;
                     out idents: identvecty): boolean;
var
 po1: pcontextitemty;
 int1: integer;
 identcount: integer;
begin
 with info do begin
  po1:= @contextstack[s.stackindex+astackoffset];
  identcount:= -1;
  for int1:= 0 to high(idents.d) do begin
   idents.d[int1]:= po1^.d.ident.ident;
   if not (idf_continued in po1^.d.ident.flags) then begin
    identcount:= int1;
    break;
   end;
   inc(po1);
  end;
  idents.high:= identcount;
  inc(identcount);
  result:= true;
  if identcount = 0 then begin
   result:= false;
  end;
  if identcount > high(idents.d) then begin
   errormessage(err_toomanyidentifierlevels,[],astackoffset+identcount);
  end;
 end;
end;

function getidents(const astackoffset: integer): identvecty;
begin
 getidents(astackoffset,result); 
end;

function findkindelements(const astackoffset: integer;
            const akinds: elementkindsty; 
            const visibility: visikindsty;
            out aelement: pelementinfoty;
            out firstnotfound: integer; out idents: identvecty;
            const remainder: int32 = 0): boolean;
var
 eleres,ele1,ele2: elementoffsetty;
 int1: integer;
begin
 result:= false;
 aelement:= nil;
 if getidents(astackoffset,idents) then begin
  idents.high:= idents.high - remainder;
  if idents.high < 0 then begin
   idents.high:= -1;
   exit;
  end;
  with info do begin
   if ele.findparentscope(idents.d[0],akinds,visibility,eleres) then begin
    result:= true;
    firstnotfound:= 0;
   end
   else begin
    result:= ele.findupward(idents,akinds,visibility,eleres,firstnotfound);
    if not result then begin //todo: use cache
     ele2:= ele.elementparent;
     for int1:= 0 to high(info.s.unitinfo^.implementationuses) do begin
      ele.elementparent:=
        info.s.unitinfo^.implementationuses[int1]^.interfaceelement;
      result:= ele.findupward(idents,akinds,visibility,eleres,firstnotfound);
      if result then begin
       break;
      end;
     end;
     if not result then begin
      for int1:= 0 to high(info.s.unitinfo^.interfaceuses) do begin
       ele.elementparent:=
         info.s.unitinfo^.interfaceuses[int1]^.interfaceelement;
       result:= ele.findupward(idents,akinds,visibility,eleres,firstnotfound);
       if result then begin
        break;
       end;
      end;
     end;
     ele.elementparent:= ele2;
    end;
   end;
  end;
 end;
 if result then begin
  aelement:= ele.eleinfoabs(eleres);
 end;
end;

function findkindelements(const astackoffset: integer;
           const akinds: elementkindsty; 
           const visibility: visikindsty;
           out aelement: pelementinfoty;
           const noerror: boolean = false): boolean;
var
 idents: identvecty;
 firstnotfound: integer;
begin
 result:= findkindelements(astackoffset,akinds,visibility,
                              aelement,firstnotfound,idents) and 
                              (firstnotfound > idents.high);
 if not result and not noerror then begin
  identerror(astackoffset+firstnotfound,err_identifiernotfound);
 end;
end;

(*
function findkindelements(const astackoffset: integer;
           const akinds: elementkindsty; 
           const visibility: vislevelty; out aelement: pelementinfoty): boolean;
var
 eleres,ele1,ele2: elementoffsetty;
 int1: integer;
 idents: identvecty;
 lastident: integer;
begin
 result:= false;
 aelement:= nil;
 if getidents(astackoffset,idents) then begin
  with info do begin
   result:= ele.findupward(idents,[],visibility,eleres,lastident); //exact
   if not result then begin //todo: use cache
    ele2:= ele.elementparent;
    for int1:= 0 to high(info.unitinfo^.implementationuses) do begin
     ele.elementparent:=
       info.unitinfo^.implementationuses[int1]^.interfaceelement;
     result:= ele.findupward(idents,[],visibility,eleres,lastident); //exact
     if result then begin
      break;
     end;
    end;
    if not result then begin
     for int1:= 0 to high(info.unitinfo^.interfaceuses) do begin
      ele.elementparent:=
        info.unitinfo^.interfaceuses[int1]^.interfaceelement;
      result:= ele.findupward(idents,[],visibility,eleres,lastident); //exact
      if result then begin
       break;
      end;
     end;
    end;
    ele.elementparent:= ele2;
   end;
  end;
 end;
 if result then begin
  aelement:= ele.eleinfoabs(eleres);
  result:= (akinds = []) or (aelement^.header.kind in akinds);
 end;
end;
*)

function findkindelementsdata(
             const astackoffset: integer;
             const akinds: elementkindsty; const visibility: visikindsty; 
             out ainfo: pointer; out firstnotfound: integer;
             out idents: identvecty;
             const rest: int32 = 0): boolean;
begin
 result:= findkindelements(astackoffset,akinds,visibility,ainfo,
                                firstnotfound,idents,rest);
 if result then begin
  ainfo:= @pelementinfoty(ainfo)^.data;
 end;
end;

function findkindelementsdata(
             const astackoffset: integer;
             const akinds: elementkindsty; const visibility: visikindsty; 
             out ainfo: pointer): boolean;
begin
 result:= findkindelements(astackoffset,akinds,visibility,ainfo);
 if result then begin
  ainfo:= @pelementinfoty(ainfo)^.data;
 end;
end;

function findvar(const astackoffset: integer; 
                   const visibility: visikindsty;
                           out varinfo: vardestinfoty): boolean;
var
 idents,types: identvecty;	
 po1: pvardataty;
 po2: ptypedataty;
 po3: pfielddataty;
 ele1,ele2: elementoffsetty;
 int1: integer;
begin
 result:= false;
 if getidents(astackoffset,idents) then begin
  result:= ele.findupward(idents,[ek_var],visibility,ele1,int1);
  if result then begin
   po1:= ele.eledataabs(ele1);
   varinfo.address:= po1^.address;
   ele2:= po1^.vf.typ;
   if int1 < idents.high then begin
    for int1:= int1+1 to idents.high do begin //fields
     result:= ele.findchild(ele2,idents.d[int1],[ek_field],visibility,ele2);
     if not result then begin
      identerror(astackoffset+int1,err_identifiernotfound);
      exit;
     end;
     po3:= ele.eledataabs(ele2);
     varinfo.address.poaddress:= varinfo.address.poaddress + po3^.offset;
    end;
    varinfo.typ:= ele.eledataabs(po3^.vf.typ);
   end
   else begin
    po2:= ele.eledataabs(ele2);
    varinfo.typ:= po2;
   end;
  end
  else begin
   identerror(astackoffset,err_identifiernotfound);
  end;
 end;
end;                           

function addvar(const aname: identty; const avislevel: visikindsty;
          var chain: elementoffsetty; out aelementdata: pvardataty): boolean;
var                                                     //!!codenavig
 po1: pelementinfoty;
begin
 result:= false;
 po1:= ele.addelement(aname,ek_var,avislevel);
 if po1 <> nil then begin
  aelementdata:= @po1^.data;
  aelementdata^.vf.next:= chain;
  aelementdata^.vf.flags:= [];
  aelementdata^.vf.defaultconst:= 0;
  chain:= ele.eleinforel(po1);
  result:= true;
 end;
end;

(*
procedure parsererror(const info: pparseinfoty; const text: string);
begin
 with info^ do begin
  contextstack[s.stackindex].d.kind:= ck_error;
  writeln(' ***ERROR*** '+text);
 end; 
end;

procedure identnotfounderror(const info: contextitemty; const text: string);
begin
 writeln(' ***ERROR*** ident '+lstringtostring(info.start.po,info.d.ident.len)+
                   ' not found. '+text);
end;

procedure wrongidentkinderror(const info: contextitemty; 
       wantedtype: elementkindty; const text: string);
begin
 writeln(' ***ERROR*** wrong ident kind '+
               lstringtostring(info.start.po,info.d.ident.len)+
                   ', expected '+
         getenumname(typeinfo(elementkindty),ord(wantedtype))+'. '+text);
end;
*)
(*
procedure outcommand(const items: array of integer;
                     const text: string);
var
 int1: integer;
begin
 with info do begin
  for int1:= 0 to high(items) do begin
   with contextstack[s.stacktop+items[int1]].d do begin
    command.write([getenumname(typeinfo(kind),ord(kind)),': ']);
    case kind of
     ck_const: begin
      with constval do begin
       case kind of
        dk_boolean: begin
         command.write(vboolean);
        end;
        dk_integer: begin
         command.write(vinteger);
        end;
        dk_float: begin
         command.write(vfloat);
        end;
       end;
      end;
     end;
    end;
    command.write(',');
   end;
  end;
  command.writeln([' ',text]);
 end;
end;
*)
function pushinsertvar(const stackoffset: int32; const aopoffset: int32;
              const indirectlevel: int32; const atype: ptypedataty): integer;
begin
 with insertitem(oc_push,stackoffset,aopoffset)^ do begin
  if indirectlevel > 0 then begin
   result:= pointersize;
  end
  else begin
   result:= atype^.h.bytesize; //todo: alignment
  end;
  setimmsize(result,par);
 end;
end;

procedure pushinsertsegaddresspo(const stackoffset: integer;
                             const aopoffset: int32;
                             const address: segaddressty);
begin
 if address.segment = seg_nil then begin
  insertitem(oc_pushnil,stackoffset,aopoffset);
 end
 else begin
  with insertitem(oc_pushsegaddr,stackoffset,aopoffset,
                                 pushsegaddrssaar[address.segment])^ do begin
   par.memop.segdataaddress.a:= address;
   par.memop.segdataaddress.offset:= 0;
   par.memop.t:= bitoptypes[das_pointer];
//   par.memop.segdataaddress.datasize:= 0; //todo!
  end;
 end;
end;

procedure pushinsertaddress(const stackoffset: integer; const aopoffset: int32);
var
 i1,i2: integer;
 po1: psubdataty;
begin
 with info,contextstack[s.stackindex+stackoffset].d.dat do begin
  if af_segment in ref.c.address.flags then begin
   with insertitem(oc_pushsegaddr,stackoffset,aopoffset,
                 pushsegaddrssaar[ref.c.address.segaddress.segment])^ do begin
    par.memop.segdataaddress.a:= ref.c.address.segaddress; //todo:typelistindex
    par.memop.segdataaddress.offset:= ref.offset;
    par.memop.t:= getopdatatype(datatyp);
    if tf_subad in datatyp.flags then begin
     po1:= ele.eledataabs(ref.c.address.segaddress.element);
     if co_llvm in compileoptions then begin
      par.memop.segdataaddress.a.address:= po1^.globid;
     end
     else begin
      if po1^.address = 0 then begin
       linkmark(po1^.adlinks,getsegaddress(seg_op,
                                         @par.memop.segdataaddress.a.address));
      end
      else begin
       par.memop.segdataaddress.a.address:= po1^.address;
      end;
     end;
    end;
   end;
  end
  else begin
   i1:= info.sublevel-ref.c.address.locaddress.framelevel-1;
   i2:= 0;
   if i1 >= 0 then begin
    i2:= getssa(ocssa_nestedvarad);
   end;
   with insertitem(oc_pushlocaddr,stackoffset,aopoffset,i2)^ do begin
    tracklocalaccess(ref.c.address.locaddress,ref.c.varele,
                 getopdatatype(datatyp.typedata, datatyp.indirectlevel));
    par.memop.locdataaddress.a:= ref.c.address.locaddress;
    par.memop.locdataaddress.a.framelevel:= i1;
    par.memop.locdataaddress.offset:= ref.offset;
    par.memop.t:= getopdatatype(datatyp);
   end;
  end;
 end;
 initfactcontext(stackoffset);
end;

function getopdatatype(const atypedata: ptypedataty;
                           const aindirectlevel: integer): typeallocinfoty;
begin
 if aindirectlevel > 0 then begin
  result:= bitoptypes[das_pointer];
 end
 else begin
  if (atypedata^.h.datasize = das_none) and 
                             (co_llvm in info.compileoptions) then begin
   result.listindex:= info.s.unitinfo^.llvmlists.typelist.
                                    addbytevalue(atypedata^.h.bytesize);
  end
  else begin
   result.listindex:= ord(atypedata^.h.datasize);
  end;
  result.kind:= atypedata^.h.datasize;
  if result.kind in byteopdatakinds then begin
   result.size:= atypedata^.h.bytesize;
  end
  else begin
   result.size:= atypedata^.h.bitsize;
  end;
  result.flags:= [];
 end;
end;

function getopdatatype(const atypedata: elementoffsetty;
                           const aindirectlevel: integer): typeallocinfoty;
begin
 if aindirectlevel > 0 then begin
  result:= bitoptypes[das_pointer];
 end
 else begin
  result:= getopdatatype(ele.eledataabs(atypedata),aindirectlevel);
 end;
end;

function getopdatatype(const atypeinfo: typeinfoty): typeallocinfoty;
begin
 result:= getopdatatype(atypeinfo.typedata,atypeinfo.indirectlevel);
end;

function getopdatatype(const adest: vardestinfoty): typeallocinfoty;
var
 i1: int32;
begin
 i1:= adest.address.indirectlevel;
 if af_paramindirect in adest.address.flags then begin
  dec(i1);
 end;
 result:= getopdatatype(adest.typ,i1);
 result.flags:= adest.address.flags;
{
 if af_aggregate in adest.address.flags then begin
  result:= getopdatatype(adest.typ,adest.address.indirectlevel);
 end
 else begin
  result.listindex:= -1; //none
 end;
}
end;

function getbytesize(const aopdatatype: typeallocinfoty): integer;
begin
 if aopdatatype.kind = das_none then begin
  result:= aopdatatype.size;
 end
 else begin
  result:= bytesizes[aopdatatype.kind];
 end;
end;

function getbasetypeele(const abitsize: databitsizety): elementoffsetty;
var
 typ1: systypety;
begin
 typ1:= basedatatypes[abitsize];
{$ifdef mse_checkinternalerror}
 if typ1 = st_none then begin
  internalerror(ie_handler,'20150319A');
 end;
{$endif}
 result:= sysdatatypes[typ1].typedata;
end;

function getbasetypedata(const abitsize: databitsizety): ptypedataty;
begin
 result:= ele.eledataabs(getbasetypeele(abitsize));
end;

function getsystypeele(const atype: systypety): elementoffsetty;
begin
 result:= sysdatatypes[atype].typedata;
end;

procedure setsysfacttype(var acontextdata: contextdataty;
                                             const atype: systypety);
begin
 with acontextdata do begin
  dat.datatyp:= sysdatatypes[atype];
  dat.fact.opdatatype:= getopdatatype(dat.datatyp);
 end;
end;

function issametype(const a,b: ptypedataty): boolean; 
                                        //follow typex = typey chain
begin
 result:= (a = b) or (a^.h.indirectlevel = b^.h.indirectlevel) and
  (
   (a^.h.base <> 0) and 
       ((a^.h.base = b^.h.base) or (ele.eledatarel(b) = a^.h.base)) or
   (b^.h.base <> 0) and 
       ((b^.h.base = a^.h.base) or (ele.eledatarel(a) = b^.h.base))
  );
end;

function issametype(const a,b: elementoffsetty): boolean; 
begin
{$ifdef mse_checkinternalerror}
 if (ele.eleinfoabs(a)^.header.kind <> ek_type) or
          (ele.eleinfoabs(b)^.header.kind <> ek_type) then begin
  internalerror(ie_handler,'20160515B');
 end;
{$endif}
 result:= (a = b) or issametype(ele.eledataabs(a),ele.eledataabs(b));
end;

procedure pushinsertconst(const stackoffset: int32;
                          const constval: dataty;
                          const aopoffset: int32;
                                               const adatasize: databitsizety);
var
// po1: pcontextitemty;
 isimm: boolean;
 segad1: segaddressty;
 si1: databitsizety;
begin
 with info do begin
//  po1:= @contextstack[s.stackindex+stackoffset];
  isimm:= true;
  case constval.kind of
   dk_boolean: begin
    si1:= das_1;
    with insertitem(oc_pushimm1,stackoffset,aopoffset)^ do begin
     setimmboolean(constval.vboolean,par);
    end;
   end;
   dk_integer,dk_cardinal,dk_enum: begin //todo: datasize warning
    if adatasize in [das_none,das_pointer] then begin //todo das_1..das_16
     si1:= das_32;
     if constval.kind = dk_cardinal then begin
      if constval.vcardinal > $ffffffff then begin
       si1:= das_64;
      end;
     end
     else begin
      if (constval.vinteger > $7ffffff) or 
               (constval.vinteger < -$80000000) then begin
       si1:= das_64;
      end;
     end;
    end
    else begin
     si1:= adatasize;
    end;
    case si1 of
     das_1: begin
      with insertitem(oc_pushimm1,stackoffset,aopoffset)^ do begin
       setimmint1(constval.vinteger,par);
      end;
     end;
     das_8: begin
      with insertitem(oc_pushimm8,stackoffset,aopoffset)^ do begin
       setimmint8(constval.vinteger,par);
      end;
     end;
     das_16: begin
      with insertitem(oc_pushimm16,stackoffset,aopoffset)^ do begin
       setimmint16(constval.vinteger,par);
      end;
     end;
     das_32: begin
      with insertitem(oc_pushimm32,stackoffset,aopoffset)^ do begin
       setimmint32(constval.vinteger,par);
      end;
     end;
     das_64: begin
      with insertitem(oc_pushimm64,stackoffset,aopoffset)^ do begin
       setimmint64(constval.vinteger,par);
      end;
     end;
     else begin
      internalerror1(ie_handler,'20150501A');
     end;
    end;
   end;
   dk_set: begin
    si1:= das_32;           //todo: arbitrary size
    with insertitem(oc_pushimm32,stackoffset,aopoffset)^ do begin
     setimmint32(constval.vset.value,par);
    end;
   end;
   dk_float: begin
    si1:= das_f64;
    with insertitem(oc_pushimmf64,stackoffset,aopoffset)^ do begin
     setimmfloat64(constval.vfloat,par);
    end;
   end;
   dk_string8: begin
    si1:= das_pointer;
    isimm:= false;
    segad1:= allocstringconst(constval.vstring);
    if segad1.segment = seg_nil then begin
     insertitem(oc_pushnil,stackoffset,aopoffset);
    end
    else begin
     with insertitem(oc_pushsegaddr,stackoffset,aopoffset,
                               pushsegaddrssaar[segad1.segment])^ do begin
      par.memop.segdataaddress.a:= segad1;
      par.memop.segdataaddress.offset:= 0;
      par.memop.t:= bitoptypes[das_pointer];
     end;
    end;
   end;
   dk_character: begin
    si1:= das_8; //todo: size
    with insertitem(oc_pushimm8,stackoffset,aopoffset)^ do begin
     setimmint8(constval.vcharacter,par);
    end;
   end;
   dk_pointer: begin
    si1:= das_pointer;
    with constval do begin
     if af_nil in vaddress.flags then begin
      insertitem(oc_pushnil,stackoffset,aopoffset);
     end
     else begin
      if af_segment in vaddress.flags then begin
       with insertitem(oc_pushsegaddr,stackoffset,aopoffset,
                  pushsegaddrssaar[vaddress.segaddress.segment])^ do begin
        par.memop.segdataaddress.a:= vaddress.segaddress;//todo:typelistindex
        par.memop.segdataaddress.offset:= 0;
        par.memop.t:= bitoptypes[das_pointer];
       end;
      end
      else begin
       with insertitem(oc_pushlocaddr{ess},stackoffset,aopoffset)^ do begin
        par.memop.locdataaddress.a:= vaddress.locaddress;
        par.memop.locdataaddress.offset:= 0;
        par.memop.t:= bitoptypes[das_pointer];
       end;
      end;
     end;
    end;
   end;
   dk_openarray: begin
    segad1:= allocdataconst(constval.vopenarray);
    si1:= das_none;
    with insertitem(oc_pushsegopenar,stackoffset,aopoffset)^ do begin
     par.memop.segdataaddress.openarhigh:= constval.vopenarray.high;
     par.memop.segdataaddress.a:= segad1;
     par.memop.segdataaddress.offset:= 0;
     par.memop.t:= bitoptypes[das_pointer];
    end; 

   {
    with insertitem(oc_pushimm32,stackoffset,aopoffset)^ do begin
     setimmint32(constval.vopenarray.high,par);
    end;
    with insertitem(oc_pushsegaddr,stackoffset,aopoffset,
               pushsegaddrssaar[constval.vopenarray.address.segment])^ do begin
     par.memop.segdataaddress.a:= segad1;
     par.memop.segdataaddress.offset:= 0;
     par.memop.t:= bitoptypes[das_pointer];
    end;
   }
   end;
  {$ifdef mse_checkinternalerror}                             
   else begin
    internalerror(ie_handler,'20131121A');
   end;
  {$endif}
  end;
  with contextstack[stackoffset+s.stackindex] do begin
   if not (constval.kind in [dk_enum,dk_set,dk_string8,dk_openarray]) then begin
    d.dat.datatyp.typedata:= getbasetypeele(si1);
   end;
   initfactcontext(stackoffset);
   d.dat.fact.opdatatype:= getopdatatype(d.dat.datatyp.typedata,
                                             d.dat.datatyp.indirectlevel);
  end;
 end;
end;

procedure pushinsertconst(const stackoffset: integer; const aopoffset: int32;
                                               const adatasize: databitsizety);
begin
 with info do begin
 {$ifdef mse_checkinternalerror}
  if contextstack[s.stackindex+stackoffset].d.kind <> ck_const then begin
   internalerror(ie_handler,'20160521C');
  end;
 {$endif}
  with contextstack[s.stackindex+stackoffset] do begin
   pushinsertconst(stackoffset,d.dat.constval,aopoffset,adatasize);
  end;
 end;
end;

//todo: optimize
procedure pushinsertconst(const acontext: pcontextitemty; const aopoffset: int32;
                                               const adatasize: databitsizety);
begin
 pushinsertconst(getstackoffset(acontext),aopoffset,adatasize);
end;

procedure checkneedsunique(const stackoffset: int32);
var
 i1: int32;
begin
 with info,contextstack[s.stackindex+stackoffset] do begin
  if hf_needsunique in d.handlerflags then begin
  {$ifdef mse_checkinternalerror}
   if not (d.kind in factcontexts) then begin
    internalerror(ie_handler,'20160405B');
   end;
  {$endif}
   case ptypedataty(ele.eledataabs(d.dat.datatyp.typedata))^.h.kind of
    dk_character: begin
     i1:= d.dat.fact.opoffset;
     with insertitem(oc_pushduppo,stackoffset,i1)^ do begin
      par.voffset:= -pointersize;
      par.ssas1:= getoppo(opmark.address + i1-1)^.par.ssad;
     end;
     inc(i1);
     with insertitem(oc_uniquestr8,stackoffset,i1)^ do begin
      par.ssas1:= getoppo(opmark.address + i1-1)^.par.ssad;
     end;
    end
    else begin
     internalerror1(ie_handler,'20160405A');
    end;
   end;
  end;
 end;
end;

procedure offsetad(const stackoffset: integer; const aoffset: dataoffsty);
var
 ssabefore: int32;
begin
 if aoffset <> 0 then begin
  with info do begin
   ssabefore:= contextstack[s.stackindex+stackoffset].d.dat.fact.ssaindex;
   with insertitem(oc_offsetpoimm32,stackoffset,-1)^ do begin
    setimmint32(aoffset,par);
    par.ssas1:= ssabefore;
   end;
  end;
 end;
end;

const                                         //getlocaddress() checks af_temp
 pushtempops: array[databitsizety] of opcodety = ( 
 //das_none,das_1,    das_2_7,    das_8,
  oc_none,oc_pushloc8,oc_pushloc8,oc_pushloc8,
 //das_9_15,   das_16,      das_17_31,   das_32,
  oc_pushloc16,oc_pushloc16,oc_pushloc32,oc_pushloc32,
 //das_33_63,  das_64,      das_pointer,
  oc_pushloc64,oc_pushloc64,oc_pushlocpo, 
 //das_f16,     das_f32,      das_f64,      das_sub,das_meta 
  oc_pushlocf16,oc_pushlocf32,oc_pushlocf64,oc_none,oc_none);

function pushtemp(const address: addressvaluety;
                                      const alloc: typeallocinfoty): int32;
begin
 with additem(pushtempops[alloc.kind])^ do begin
 {$ifdef mse_checkinternalerror}
  if op.op = oc_none then begin
   internalerror(ie_handler,'20150914A');
  end;
  if not (af_temp in address.flags) then begin
   internalerror(ie_handler,'20160314B');
  end;
 {$endif}
  par.memop.t:= alloc;
  par.memop.t.flags:= address.flags;
  par.memop.tempdataaddress.a:= address.tempaddress;
  par.memop.tempdataaddress.offset:= 0; //???
  result:= par.ssad;
 end;
end;

function pushtemppo(const address: addressvaluety): int32;
begin
 {$ifdef mse_checkinternalerror}
  if not (af_temp in address.flags) then begin
   internalerror(ie_handler,'20160314C');
  end;
 {$endif}
 with additem(oc_pushlocpo)^ do begin
  par.memop.t:= bitoptypes[das_pointer];
  par.memop.t.flags:= address.flags;
  par.memop.tempdataaddress.a:= address.tempaddress;
  par.memop.tempdataaddress.offset:= 0; //???
  result:= par.ssad;
 end;
end;

procedure poptemp(const asize: int32);
begin
 with additem(oc_pop)^ do begin
  par.imm.vsize:= asize;
 end;
end;

const                                //getlocaddress() checks af_temp
 pushtempindiops: array[databitsizety] of opcodety = (
 //das_none,das_1,        das_2_7,        das_8,
  oc_none,oc_pushlocindi8,oc_pushlocindi8,oc_pushlocindi8,
 //das_9_15,       das_16,          das_17_31,       das_32,
  oc_pushlocindi16,oc_pushlocindi16,oc_pushlocindi32,oc_pushlocindi32,
 //das_33_63,      das_64,          das_pointer,
  oc_pushlocindi64,oc_pushlocindi64,oc_pushlocindipo, 
 //das_f16,         das_f32,          das_f64,          das_sub,das_meta 
  oc_pushlocindif16,oc_pushlocindif32,oc_pushlocindif64,oc_none,oc_none);
                  
function pushtempindi(const address: addressvaluety;
                                      const alloc: typeallocinfoty): int32;
begin
 with additem(pushtempindiops[alloc.kind])^ do begin
 {$ifdef mse_checkinternalerror}
  if op.op = oc_none then begin
   internalerror(ie_handler,'2050914B');
  end;
  if not (af_temp in address.flags) then begin
   internalerror(ie_handler,'20160314D');
  end;
 {$endif}
  par.memop.t:= alloc;
  par.memop.t.flags:= address.flags;
  par.memop.tempdataaddress.a:= address.tempaddress;
  par.memop.tempdataaddress.offset:= 0; //???
  result:= par.ssad;
 end;
end;

function addpushimm(const aop: opcodety): popinfoty; 
                                 {$ifndef mse_debugparser} inline; {$endif}
begin
 result:= additem(aop);
// result^.par.ssad:= info.ssaindex;
end;

procedure push(const avalue: boolean);
begin
 with addpushimm(oc_pushimm8)^ do begin
  setimmboolean(avalue,par);
 end;
end;

procedure push(const avalue: integer);
begin
 with addpushimm(oc_pushimm32)^ do begin
  setimmint32(avalue,par);
 end;
end;

procedure push(const avalue: real);
begin
 with addpushimm(oc_pushimm64)^ do begin
  setimmfloat64(avalue,par);
 end;
end;

function getaddreftype(const aref: addressrefty): ptypedataty;
begin
 case aref.kind of
  ark_vardata,ark_vardatanoaggregate: begin
   with pvardataty(aref.vardata)^ do begin 
    if af_segment in address.flags then begin
     result:= ele.eledataabs(vf.typ);
    end
    else begin
     notimplementederror('');
    end;
   end;
  end;
  ark_contextdata: begin
   with pcontextdataty(aref.contextdata)^ do begin
    result:= ele.eledataabs(dat.datatyp.typedata);
   end;
  end
  else begin
   notimplementederror('');
  end;
 end;
end;

function pushaddr(const aref: addressrefty{ const atype: ptypedataty;
                                             const assaindex: int32}): int32;
var
 op1: popinfoty;

 procedure pushad(const ad: addressvaluety);
 begin
  if af_segment in ad.flags then begin
   op1:= additem(oc_pushsegaddr,
                 pushsegaddrssaar[ad.segaddress.segment]);
   with op1^.par.memop.segdataaddress do begin
    a.address:= ad.segaddress.address;
    a.segment:= ad.segaddress.segment;
    offset:= aref.offset;
    a.element:= 0;
   end;
  end
  else begin
   notimplementederror('');
  end;
 end;

begin
 case aref.kind of
  ark_vardata,ark_vardatanoaggregate: begin
   with pvardataty(aref.vardata)^ do begin
    pushad(address);
{
    if af_segment in address.flags then begin
     op1:= additem(oc_pushsegaddr,
                   pushsegaddrssaar[address.segaddress.segment]);
     with op1^.par.memop.segdataaddress do begin
      a.address:= address.segaddress.address;
      a.segment:= address.segaddress.segment;
      offset:= aref.offset;
      a.element:= 0;
     end;
    end
    else begin
     notimplementederror('');
    end;
}
   end;
  end;
  ark_contextdata: begin
   with pcontextdataty(aref.contextdata)^ do begin
    if kind = ck_ref then begin
     pushad(dat.ref.c.address);
    end
    else begin
     notimplementederror('');
    end;
   end;
  end;
  else begin
   notimplementederror('');
  end;
 end;
// op1^.par.memop.t:= bitoptypes[das_pointer];
 result:= op1^.par.ssad;
(*
 case avalue.base of
  ab_segment: begin
   op1:= additem(oc_pushsegaddr,
                 pushsegaddrssaar[avalue.segment]);
   with op1^.par.memop.segdataaddress do begin
    a.address:= avalue.address;
    offset:= avalue.offset;
    a.segment:= avalue.segment;
    a.element:= 0;
   end;
  end;
  ab_frame: begin
   op1:= additem(oc_pushlocaddr);
   with op1^.par.memop.locdataaddress do begin
    a.address:= avalue.address;
    offset:= avalue.offset;
    a.framelevel:= -1;
   end;
  end;
  ab_stack: begin
   op1:= additem(oc_pushstackaddr);
   with op1^.par.memop do begin
    tempdataaddress.a.address:= avalue.address; 
                                  //todo: use common record type in
                                  //addressrefty and tempdataaddressty
    if co_llvm in info.compileoptions then begin
     tempdataaddress.a.ssaindex:= assaindex;
     t:= getopdatatype(atype,avalue.indirectlevel);
     tempdataaddress.offset:= 
        info.s.unitinfo^.llvmlists.constlist.adddataoffs(avalue.offset).listid;
    end
    else begin
     tempdataaddress.offset:= avalue.offset;
    end;
   end;
  end;
  else begin
   notimplementederror('20160314A');
  end;
 end;
// op1^.par.memop.t:= bitoptypes[das_pointer];
 result:= op1^.par.ssad;
*)
end;

procedure pushins(const ains: boolean; const stackoffset: integer;
          const aopoffset: int32; const atype: typeinfoty;
          const avalue: addressvaluety; const offset: dataoffsty{;
                                           const indirect: boolean});
                 //push address on stack
//todo: optimize

 function getop(const aop: opcodety; const ssaextension: int32 = 0): popinfoty;
 begin
  if ains then begin
   result:= insertitem(aop,stackoffset,aopoffset,ssaextension);
  end
  else begin
   result:= additem(aop,ssaextension);
  end;
 end;

var
 po1: popinfoty;
 i1,i2: int32;
begin
 if af_nil in avalue.flags then begin
  with getop(oc_pushaddr)^ do begin
   setimmpointer(0,par);
  end;
 end
 else begin
  if af_segment in avalue.flags then begin
   po1:= getop(oc_pushsegaddr,
                 pushsegaddrssaar[avalue.segaddress.segment]);
   with po1^ do begin
    par.memop.segdataaddress.a:= avalue.segaddress;
    par.memop.segdataaddress.offset:= offset;
    par.memop.t:= getopdatatype(atype);
   end;
  end
  else begin
   i1:= info.sublevel-avalue.locaddress.framelevel-1;
   i2:= 0;
   if i1 >= 0 then begin
    i2:= getssa(ocssa_nestedvarad);
   end;
   po1:= getop(oc_pushlocaddr,i2);
   with po1^ do begin
    par.memop.locdataaddress.a:= avalue.locaddress;
    par.memop.locdataaddress.a.framelevel:= i1;
    par.memop.locdataaddress.offset:= offset;
    par.memop.t:= getopdatatype(atype);
   end;
  end;
 end;
end;

procedure pushinsertstack(const stackoffset: int32; //context stack
                          const aopoffset: int32; const sourceoffset: int32);
var
 i1: int32;
begin
 with info do begin
  i1:= s.stackindex + stackoffset;
  with contextstack[i1] do begin
  end;
 end;
end;

procedure pushinsertstackindi(const stackoffset: int32; //context stack
                          const aopoffset: int32; const sourceoffset: int32);
var                     //todo: optimize
 i1: int32;
 typ1: typeallocinfoty;
begin
 with info do begin
  i1:= s.stackindex + stackoffset;
  with contextstack[i1] do begin
 {$ifdef mse_debugparser}
   if not (d.kind in factcontexts) then begin
    internalerror(ie_handler,'20150913A');
   end;
  {$endif}
   typ1:= getopdatatype(d.dat.datatyp.typedata,d.dat.datatyp.indirectlevel-1);
//   with insertitem(pushstackindiops[typ1.kind],stackoffset,before)^ do begin
//   end;
  end;
 end;
end;

procedure push(const atype: typeinfoty; const avalue: addressvaluety;
            const offset: dataoffsty{;
            const indirect: boolean}); overload;
begin
 pushins(false,0,-1,atype,avalue,offset{,indirect});
end;

procedure pushinsert(const stackoffset: integer; const aopoffset: int32;
            const atype: typeinfoty;
            const avalue: addressvaluety; const offset: dataoffsty{;
            const indirect: boolean}); overload;
begin
 pushins(true,stackoffset,aopoffset,atype,avalue,offset{,indirect});
end;

procedure push(const avalue: datakindty); overload;
      //no alignsize
begin
 with addpushimm(oc_pushimmdatakind)^ do begin
  setimmdatakind(avalue,par);
 end;
end;

function insertpushimm(const aop: opcodety; const stackoffset: integer;
                       const aopoffset: int32): popinfoty; 
                                 {$ifndef mse_debugparser} inline; {$endif}
begin
 result:= insertitem(aop,stackoffset,aopoffset);
// result^.par.ssad:= info.ssaindex;
end;

procedure pushinsert(const stackoffset: integer; const aopoffset: int32;
                                    const avalue: datakindty); overload;
      //no alignsize
begin
 with insertpushimm(oc_pushimmdatakind,stackoffset,aopoffset)^ do begin
  setimmdatakind(avalue,par);
 end;
end;

procedure int32toflo64({; const index: integer});
begin
 additem(oc_int32toflo64);
end;
{
procedure setcurrentloc(const indexoffset: integer);
begin 
 with info do begin
  getoppo(
   contextstack[s.stackindex+indexoffset].opmark.address)^.par.opaddress:=
                                                                     opcount-1;
 end; 
end;
}
procedure setcurrentlocbefore(const indexoffset: integer);
begin 
 with info do begin
  with getoppo(contextstack[s.stackindex+indexoffset].
                                             opmark.address-1)^ do begin
   par.opaddress.opaddress:= opcount-1;
//   par.opaddress.bbindex:= info.s.ssa.blockindex;
  end;
//  addlabel();
 end;
end;

procedure setlocbefore(const destindexoffset,sourceindexoffset: integer);
var
 dest: integer;
begin
 with info do begin
  dest:= contextstack[s.stackindex+sourceindexoffset].opmark.address;
  getoppo(contextstack[s.stackindex+destindexoffset].opmark.address-1)^.
                                            par.opaddress.opaddress:= dest-1;
 end; 
end;
{
procedure setloc(const destindexoffset,sourceindexoffset: integer);
var
 dest: integer;
begin
 with info do begin
  dest:= contextstack[s.stackindex+sourceindexoffset].opmark.address;
  getoppo(
    contextstack[s.stackindex+destindexoffset].opmark.address)^.par.opaddress:=
                                                                        dest-1;
  include(getoppo(dest)^.op.flags,opf_label);
 end; 
end;
}
function compaddress(const a,b: addressvaluety): integer;
        //todo: handle runtime address calculation
begin
 result:= maxint;
 if a.flags * addresscompflags = b.flags * addresscompflags then begin
  if af_nil in a.flags then begin
   result:= 0;
  end
  else begin
   result:= a.poaddress - b.poaddress;
  end;
 end;
end;

function convertconsts(const poa,pob: pcontextitemty): stackdatakindty;
                //convert s.stacktop, s.stacktop-2
//var
// poa,pob: pcontextitemty;
begin
 with info do begin
//  poa:= @contextstack[s.stacktop-2];
//  pob:= @contextstack[s.stacktop];
 {$ifdef checkinternalerror}
  if poa^.d.kind <> ck_const) or 
     pob^.d.kind <> ck_const then begin
   internalerror(ie_handler,'200151130A');
  end;
 {$endif}
  result:= stackdatakinds[poa^.d.dat.constval.kind];
  if poa^.d.dat.constval.kind <> pob^.d.dat.constval.kind then begin
   case pob^.d.dat.constval.kind of
    dk_float: begin
     result:= sdk_flo64;
     case poa^.d.dat.constval.kind of
      dk_integer: begin
       poa^.d.dat.constval.vfloat:= poa^.d.dat.constval.vinteger;
       poa^.d.dat.constval.kind:= dk_float;
       poa^.d.dat.datatyp:= pob^.d.dat.datatyp;
      end;
      else begin
       result:= sdk_none;
      end;
     end;
    end;
    dk_integer: begin
     case poa^.d.dat.constval.kind of
      dk_float: begin
       pob^.d.dat.constval.vfloat:= pob^.d.dat.constval.vinteger;
       pob^.d.dat.constval.kind:= dk_float;
       pob^.d.dat.datatyp:= poa^.d.dat.datatyp;
      end;
      else begin
       result:= sdk_none;
      end;
     end;
    end;
    else begin
     result:= sdk_none;
    end;
   end;
  end
  else begin
   case poa^.d.dat.constval.kind of
    dk_enum: begin
     if poa^.d.dat.datatyp.typedata = pob^.d.dat.datatyp.typedata then begin
      result:= sdk_int32; //todo: different sizes
     end;
    end;
    dk_set: begin                          //todo: basetype?
     if ptypedataty(ele.eledataabs(
            poa^.d.dat.datatyp.typedata))^.infoset.itemtype = 
            ptypedataty(ele.eledataabs(
                      pob^.d.dat.datatyp.typedata))^.infoset.itemtype then begin
      result:= sdk_set32; //todo: different sizes
     end;
    end;
   end;
  end;
  if result = sdk_none then begin
   incompatibletypeserror(poa^.d,pob^.d);
  end;
 end;
end;

procedure tracklocalaccess(var aaddress: locaddressty; 
                                 const avarele: elementoffsetty;
                                 const aopdatatype: typeallocinfoty);

var
 int1: integer;
 parentbefore,ele1: elementoffsetty;
 po1: pnestedvardataty;
 first: boolean;
 bo1: boolean;
 addressbefore: dataoffsty;
begin
 if co_llvm in info.compileoptions then begin
  int1:= info.sublevel-aaddress.framelevel;
  if int1 > 0 then begin   //var in outer sub
   addressbefore:= aaddress.address;
   parentbefore:= ele.elementparent;
   first:= true;
   for int1:= int1-1 downto 0 do begin
    with psubdataty(ele.parentdata())^ do begin //current sub
     include(flags,sf_hasnestedaccess);
    end;
    ele.decelementparent();
   {$ifdef mse_checkinternalerror}
    if ele.parentelement()^.header.kind <> ek_sub then begin
     internalerror(ie_elements,'20140811A');
    end;
   {$endif}
    with psubdataty(ele.parentdata())^ do begin //parent sub
     bo1:= ele.adduniquechilddata(nestedvarele,[avarele],ek_nestedvar,
                                                       allvisi,po1);
     if bo1 then begin
      include(flags,sf_hasnestedref);
      po1^.next:= nestedvarchain;
      po1^.address.datatype:= aopdatatype;
      po1^.address.arrayoffset:= info.s.unitinfo^.llvmlists.constlist.
                              addi32((nestedvarcount{-1})*pointersize).listid;
      po1^.address.origin:= addressbefore;
      po1^.address.nested:= true;
      if int1 = 0 then begin //last
       po1^.address.nested:= false;
      end;
      nestedvarchain:= ele.eledatarel(po1);
      inc(nestedvarcount);
     end;
     if first then begin
      aaddress.address:= po1^.address.arrayoffset; //nested var offset
      first:= false;
     end;
     {
     if int1 = 0 then begin //last
      po1^.address.address:= addressbefore; //restore
      po1^.address.nested:= false;
     end;
     }
    end;
    if not bo1 then begin //already tracked
     break;
    end;
   end;
   ele.elementparent:= parentbefore; //restore
  end;
 end;
end;

function llvmlink(const adata: pointer; out destunitid: identty;
                                              out globid: int32): boolean;
                                              // -1 -> new
var
 po1: pelementinfoty;
 po2: plinkdataty;
begin
 with info do begin
  result:= modularllvm;
  if result then begin
   po1:= datatoele(adata);
   destunitid:= po1^.header.defunit^.key;
   result:= destunitid <> s.unitinfo^.key;
   if result then begin
    po2:= info.s.unitinfo^.llvmlists.globlist.linklist.find(
                                              ele.eledatarel(adata));
    if po2 <> nil then begin
     globid:= po2^.globid;
    end
    else begin
     globid:= -1; //new
    end;
   end;
  end;
 end;
end;

function trackaccess(const avar: pvardataty): addressvaluety;
var
 unitid: identty;
 globid: int32;
begin
 result:= avar^.address;
 if af_segment in avar^.address.flags then begin
  if llvmlink(avar,unitid,globid) then begin
   if globid < 0 then begin
    result.segaddress.address:= info.s.unitinfo^.llvmlists.globlist.addvalue(
                                                         avar,li_external,true);
   end
   else begin
    result.segaddress.address:= globid;
   end;
  end;
 end;
{
 if info.compileoptions * [co_llvm,co_writeunits] = 
                                            [co_llvm,co_writeunits] then begin
  if af_segment in avar^.address.flags then begin
   po1:= datatoele(avar);
   if po1^.header.defunit <> info.s.unitinfo then begin
   end;
  end;
 end;
}
end;

function trackaccess(const asub: psubdataty): int32;
var
 unitid: identty;
 globid: int32;
begin
 if llvmlink(asub,unitid,globid) then begin
  if globid < 0 then begin
   result:= info.s.unitinfo^.llvmlists.globlist.addsubvalue(asub,true);
  end
  else begin
   result:= globid;
  end;
 end
 else begin
  result:= asub^.globid;
 end;
end;

type
 opsizety = (ops_none,ops_8,ops_16,ops_32,ops_64,ops_po);

const
 pushseg: array[opsizety] of opcodety =
           (oc_pushseg,oc_pushseg8,oc_pushseg16,
            oc_pushseg32,oc_pushseg64,oc_pushsegpo);
 pushloc: array[opsizety] of opcodety =
           (oc_pushloc,oc_pushloc8,oc_pushloc16,
            oc_pushloc32,oc_pushloc64,oc_pushlocpo);
 pushlocindi: array[opsizety] of opcodety =
           (oc_pushlocindi,oc_pushlocindi8,oc_pushlocindi16,
            oc_pushlocindi32,oc_pushlocindi64,oc_pushlocindipo);
 pushpar: array[opsizety] of opcodety =
           (oc_pushpar,oc_pushpar8,oc_pushpar16,
            oc_pushpar32,oc_pushpar64,oc_pushparpo);
 
procedure pushd(const ains: boolean; const stackoffset: integer;
          const aopoffset: int32;
          const aaddress: addressvaluety; const avarele: elementoffsetty;
          const offset: dataoffsty; const aopdatatype: typeallocinfoty);
//todo: optimize

var
 ssaextension1: integer;

 function getop(const aop: opcodety): popinfoty;
 begin
  if ains then begin
   result:= insertitem(aop,stackoffset,aopoffset,ssaextension1);
  end
  else begin
   result:= additem(aop,ssaextension1);
  end;
 end;

var
 po1: popinfoty;
 framelevel1: integer;
 opsize1: opsizety;
 opflags1: addressflagsty;
begin
 opsize1:= ops_none;
 case aopdatatype.kind of
  das_pointer: begin
   opsize1:= ops_po;
  end;
  else begin
   if aopdatatype.kind in bitopdatakinds then begin
    case aopdatatype.size of
     1..8: begin 
      opsize1:= ops_8;
     end;
     9..16: begin
      opsize1:= ops_16;
     end;
     17..32: begin
      opsize1:= ops_32;
     end;
     33..64: begin
      opsize1:= ops_64;
     end;
    end;
   end; 
  end;
 end;
  
 with aaddress do begin //todo: use table
  opflags1:= flags;
  if aaddress.indirectlevel > 0 then begin
   exclude(opflags1,af_aggregate);
  end;
  if af_aggregate in opflags1 then begin
   ssaextension1:= getssa(ocssa_aggregate);
  end
  else begin
   ssaextension1:= 0;
  end;
  if af_segment in flags then begin
   po1:= getop(pushseg[opsize1]);
   with po1^ do begin
    par.memop.segdataaddress.a:= segaddress;
    par.memop.segdataaddress.offset:= offset;
   end;
  end
  else begin
   if af_temp in opflags1 then begin
    po1:= getop(pushloc[opsize1]);
    with po1^ do begin
     par.memop.tempdataaddress.a:= tempaddress;
     par.memop.tempdataaddress.offset:= 0; //???
    end;
   end
   else begin
    framelevel1:= info.sublevel-locaddress.framelevel-1;
    if framelevel1 >= 0 then begin
     ssaextension1:= ssaextension1 + getssa(ocssa_pushnestedvar);
    end;
    if af_param in flags then begin
     if af_paramindirect in flags then begin
      po1:= getop(pushlocindi[opsize1]);
     end
     else begin
      po1:= getop(pushpar[opsize1]);
     end;
    end
    else begin   
     po1:= getop(pushloc[opsize1]);
    end;
    with po1^ do begin
     par.memop.locdataaddress.a:= locaddress;
     tracklocalaccess(par.memop.locdataaddress.a,avarele,aopdatatype);
     par.memop.locdataaddress.a.framelevel:= framelevel1;
     par.memop.locdataaddress.offset:= offset;
    end;
   end;
  end;
  po1^.par.memop.t:= aopdatatype;
  po1^.par.memop.t.flags:= opflags1;
//  po1^.par.memop.t.flags:= aaddress.flags;
//  par.ssad:= ssaindex;
 end;
end;

//todo: optimize call
procedure pushdata(const address: addressvaluety;
                   const varele: elementoffsetty;
                   const offset: dataoffsty;
                         const opdatatype: typeallocinfoty);
begin
 pushd(false,0,-1,address,varele,offset,opdatatype);
end;

procedure pushinsertdata(const stackoffset: integer; const aopoffset: int32;
                  const address: addressvaluety;
                  const varele: elementoffsetty;
                  const offset: dataoffsty;
                  const opdatatype: typeallocinfoty);
begin
 pushd(true,stackoffset,aopoffset,address,varele,offset,opdatatype);
end;

function getstackindex(const acontext: pcontextitemty): int32;
begin
 result:= acontext - pcontextitemty(pointer(info.contextstack));
{$ifdef mse_checkinternalerror}
 if (result  < 0) or (result  > info.s.stacktop) then begin
  internalerror(ie_handler,'20160606B');
 end;
{$endif}
end;

function getstackoffset(const acontext: pcontextitemty): int32;
begin
 result:= acontext - pcontextitemty(pointer(info.contextstack)) - 
                                                 info.s.stackindex;
{$ifdef mse_checkinternalerror}
 if (result + info.s.stackindex < 0) or 
                (result + info.s.stackindex > info.s.stacktop) then begin
  internalerror(ie_handler,'20160602C');
 end;
{$endif}
end;

function getcontextssa(const stackoffset: integer): int32;
var
 i1: int32;
 op1: opaddressty;
begin
 with info do begin
  i1:= s.stackindex+stackoffset;
  with info.contextstack[i1] do begin
   if i1 >= s.stacktop then begin
    result:= s.ssa.nextindex-1;
   end
   else begin
    op1:= contextstack[i1+1].opmark.address;
    if op1 >= opmark.address then begin
     result:= getoppo(op1-1)^.par.ssad; //use last op of context
    end
    else begin
     if op1 >= opcount-1 then begin
      result:= s.ssa.index;
     end
     else begin
      result:= getoppo(op1)^.par.ssad; //use current op
     end;
    end;
   end;
  end;
 end;
end;

function getpreviousnospace(const astackindex: int32): int32;
var
 i1: int32;
begin
 with info do begin
  i1:= astackindex;
  while true do begin
  {$ifdef mse_checkinternalerror}
   if (i1 < 0) or (i1 > s.stacktop) then begin
    internalerror(ie_handler,'20160603A');
   end;
  {$endif}
   with contextstack[i1] do begin
    if (d.kind <> ck_space) and not (hf_listitem in d.handlerflags) then begin
     result:= i1;
     break;
    end;
   end;
   dec(i1);
  end;
 end;
end;

function getpreviousnospace(const apo: pcontextitemty): pcontextitemty;
var
 po1: pcontextitemty;
begin
 po1:= apo;
{$ifdef mse_checkinternalerror}
 with info do begin
  if (po1 < @contextstack) then begin
   internalerror(ie_handler,'20160603D');
  end;
 end;
{$endif}
 while (po1^.d.kind = ck_space) or 
                              (hf_listitem in po1^.d.handlerflags) do begin
 {$ifdef mse_checkinternalerror}
  with info do begin
   if (po1 < @contextstack) then begin
    internalerror(ie_handler,'20160603D');
   end;
  end;
 {$endif}
  dec(po1);
 end;
 result:= po1;
end;

function getnextnospace(const astackindex: int32;
                                     out apo: pcontextitemty): boolean;
                                                              //true if found
var
 po1,pe: pcontextitemty;
begin
 result:= false;
 with info do begin
 {$ifdef mse_checkinternalerror}
  if (astackindex < 0) or (astackindex > s.stacktop) then begin
   internalerror(ie_handler,'20160603B');
  end;
 {$endif}
  po1:= @contextstack[astackindex];
  pe:= @contextstack[s.stacktop];
  while po1 <= pe do begin
   if (po1^.d.kind <> ck_space) and 
                          not (hf_listitem in po1^.d.handlerflags) then begin
    apo:= po1;
    result:= true;
    break;
   end;
   inc(po1);
  end;
 end;
end;

function getnextnospace(const current: pcontextitemty;
                                      out apo: pcontextitemty): boolean;
                                   //true if found
var
 po1,pe: pcontextitemty;
begin
 result:= false;
 with info do begin
  po1:= current;
  pe:= @contextstack[s.stacktop];
  while po1 <= pe do begin
   if (po1^.d.kind <> ck_space) and 
                          not (hf_listitem in po1^.d.handlerflags) then begin
    apo:= po1;
    result:= true;
    break;
   end;
   inc(po1);
  end;
 end;
end;

function getnextnospace(const current: pcontextitemty): pcontextitemty;
var
 po1,pe: pcontextitemty;
begin
 with info do begin
  po1:= current;
  while (po1^.d.kind = ck_space) or 
                           (hf_listitem in po1^.d.handlerflags) do begin
   inc(po1);
  {$ifdef mse_checkinternalerror}
   if (po1 > @contextstack[s.stacktop]) then begin
    internalerror(ie_handler,'20160604A');
   end;
  {$endif}
  end;
 end;
 result:= po1;
end;

function getnextnospace(const astackindex: int32): int32;
var
 po1,pe: pcontextitemty;
begin
 with info do begin
  po1:= @contextstack[astackindex];
  while (po1^.d.kind = ck_space) or 
                        (hf_listitem in po1^.d.handlerflags) do begin
   inc(po1);
  {$ifdef mse_checkinternalerror}
   if (po1 > @contextstack[s.stacktop]) then begin
    internalerror(ie_handler,'20160604A');
   end;
  {$endif}
  end;
  result:= po1 - pcontextitemty(@contextstack[0]);
 end;
end;

function getspacecount(const astackindex: int32): int32;
               //counts ck_space from astackindex to stacktop
var
 po1,pe: pcontextitemty;
begin
 result:= 0;
 with info do begin
 {$ifdef mse_checkinternalerror}
  if (astackindex < 0) or (astackindex > s.stacktop) then begin
   internalerror(ie_handler,'20160603C');
  end;
 {$endif}
  po1:= @contextstack[astackindex];
  pe:= @contextstack[s.stacktop];
  while po1 <= pe do begin
   if po1^.d.kind = ck_space then begin
    inc(result);
   end;
   inc(po1);
  end;
 end;
end;

function getitemcount(const acontext: pcontextitemty): int32;
               //counts not ck_space from astackindex to stacktop
var
 po1,pe: pcontextitemty;
begin
 result:= 0;
 with info do begin
 {$ifdef mse_checkinternalerror}
  if (acontext < @contextstack) or 
                           (acontext > @contextstack[s.stacktop]) then begin
   internalerror(ie_handler,'20160604C');
  end;
 {$endif}
  po1:= acontext;
  pe:= @contextstack[s.stacktop];
  while po1 <= pe do begin
   if po1^.d.kind <> ck_space then begin
    inc(result);
   end;
   inc(po1);
  end;
 end;
end;

function getitemcount(const astackindex: int32): int32;
               //counts not ck_space from astackindex to stacktop
var
 po1,pe: pcontextitemty;
begin
 result:= 0;
 with info do begin
  po1:= @contextstack[astackindex];
 {$ifdef mse_checkinternalerror}
  if (po1 < @contextstack) or (po1 > @contextstack[s.stacktop]) then begin
   internalerror(ie_handler,'20160604C');
  end;
 {$endif}
  pe:= @contextstack[s.stacktop];
  while po1 <= pe do begin
   if po1^.d.kind <> ck_space then begin
    inc(result);
   end;
   inc(po1);
  end;
 end;
end;

function getfactstart(const astackindex: int32;
                               out acontext: pcontextitemty): boolean;
begin
 result:= true;
 with info do begin
  acontext:= @contextstack[astackindex];
  if hf_propindex in acontext^.d.handlerflags then begin
   acontext:= @contextstack[acontext^.parent-1];
  {$ifdef mse_checkinternalerror}
   if (acontext^.d.kind <> ck_prop) or 
                            ((acontext+1)^.d.kind <> ck_index) then begin
    internalerror(ie_handler,'20160608A');
   end;
  {$endif}
  end;
  acontext:= getpreviousnospace(acontext);
  if acontext^.d.kind = ck_list then begin
   result:= listtoset(acontext);
  end;
 end;
end;

procedure initdatacontext(var acontext: contextdataty;
                                             const akind: contextkindty);
begin
{$ifdef mse_checkinternalerror}
 if not (akind in datacontexts) then begin
  internalerror(ie_handler,'20160602A');
 end;
{$endif}
 acontext.kind:= akind;
 with acontext.dat do begin
//  flags:= [];
  indirection:= 0;
 end;
end;

procedure initfactcontext(const stackoffset: int32);
var
 po1: pcontextitemty;
begin
 with info do begin
  po1:= @contextstack[s.stackindex+stackoffset];
  initdatacontext(po1^.d,ck_fact);
  with po1^ do begin
   d.dat.fact.ssaindex:= getcontextssa(stackoffset);
  end;
 end;
end;

procedure initblockcontext(const stackoffset: int32);
begin
 with info,contextstack[s.stackindex+stackoffset] do begin
  d.kind:= ck_block;
  d.block.blockidbefore:= currentblockid;
  inc(s.blockid);
  currentblockid:= s.blockid;
 end;
end;

procedure newblockcontext(const stackoffset: int32);
begin
 with info,contextstack[s.stackindex+stackoffset] do begin
  inc(s.blockid);
  currentblockid:= s.blockid;
 end;
end;

procedure finiblockcontext(const stackoffset: int32);
begin
 with info,contextstack[s.stackindex+stackoffset] do begin
  currentblockid:= d.block.blockidbefore;
 end;
end;

//todo: use better and universal algorithm
function pushindirection(const stackoffset: integer;
                                       const address: boolean): boolean;
var
 i1,i2,i3: integer;
 po1: popinfoty;
 bo1,isstartoffset: boolean;
 ssabefore: int32;
begin
 result:= true;
 with info,contextstack[s.stackindex+stackoffset] do begin;
 {$ifdef mse_checkinternalerror}
  if not (d.kind in [ck_ref,ck_prop]) then begin
   internalerror(ie_handler,'20150413A');
  end;
 {$endif}
  if d.dat.indirection <= 0 then begin
   bo1:= (d.dat.datatyp.indirectlevel =
                                 d.dat.ref.c.address.indirectlevel);
   isstartoffset:= af_startoffset in d.dat.ref.c.address.flags;
   i3:= 0;
   if isstartoffset then begin
    i3:= d.dat.ref.offset;
   end;
   if address and not bo1 then begin
    i2:= 0;
    if d.dat.indirection = 0 then begin
     pushd(true,stackoffset,-1,d.dat.ref.c.address,d.dat.ref.c.varele,
                i3,bitoptypes[das_pointer]);
     if not isstartoffset and (d.dat.ref.offset <> 0) then begin
      ssabefore:= getcontextssa(stackoffset);
      with insertitem(oc_offsetpoimm32,stackoffset,-1)^ do begin
       par.ssas1:= ssabefore;
       setimmint32(d.dat.ref.offset,par);
      end;
      inc(d.dat.indirection);
     end;
     i2:= -1;
    end
    else begin
     pushinsert(stackoffset,-1,d.dat.datatyp,d.dat.ref.c.address,
                                                        d.dat.ref.offset);
    end;
   end
   else begin
    pushd(true,stackoffset,-1,d.dat.ref.c.address,d.dat.ref.c.varele,
                i3,bitoptypes[das_pointer]);
    i2:= -1;
   end;
   for i1:= d.dat.indirection to i2 do begin
    with insertitem(oc_indirectpo,stackoffset,-1)^ do begin
     par.memop.t:= bitoptypes[das_pointer];
     par.ssas1:= par.ssad - getssa(oc_indirectpo);
    end;
   end;
   initfactcontext(stackoffset);
   if (not address or bo1) and not isstartoffset then begin
    offsetad(stackoffset,d.dat.ref.offset);
   end;
    {
    po1:= insertitem(oc_indirectpooffs,stackoffset,false);
    with po1^ do begin
     par.voffset:= d.dat.ref.offset;
     if info.backend = bke_llvm then begin
      par.voffset:= constlist.addi32(par.voffset).listid;
     end;
     par.ssas1:= par.ssad - getssa(oc_indirectpooffs);
    end;
    }
//   end;
//   inc(d.dat.datatyp.indirectlevel,d.dat.indirection);
  end
  else begin
   errormessage(err_cannotassigntoaddr,[],stackoffset);
   result:= false;
  end;
 end;
end;

function initopenarrayconst(var adata: dataty; const itemcount: int32;
                                     const itemsize: int32): pointer;
                                         //returns pointer to data block
var
 flags1: addressflagsty;
begin
 with adata do begin
  kind:= dk_openarray;
  vopenarray.size:= itemcount*itemsize;
  vopenarray.high:= itemcount-1;
  vopenarray.address:= getglobconstaddress(vopenarray.size,result);
 end;
end;

function getcontextopoffset(const stackoffset: int32): int32;
            //returns opcount in context
var
 i1: int32;
begin
 with info do begin
  i1:= s.stackindex + stackoffset;
  if i1 >= s.stacktop then begin
   result:= opcount;
  end
  else begin
   result:= contextstack[i1+1].opmark.address;
  end;
  result:= result - contextstack[i1].opmark.address;
 end;
end;

const
 indirect: array[databitsizety] of opcodety = (
 //das_none,   das_1,       das_2_7,     das_8,
   oc_indirect,oc_indirect8,oc_indirect8,oc_indirect8,
 //das_9_15,     das_16,       das_17_31,    das_32,
   oc_indirect16,oc_indirect16,oc_indirect32,oc_indirect32,
 //das_33_63,    das_64,       das_pointer,
   oc_indirect64,oc_indirect64,oc_indirectpo,
 //das_f16,       das_f32,       das_f64        das_sub,      das_meta
   oc_indirectf16,oc_indirectf32,oc_indirectf64,oc_indirectpo,oc_none);

function getvalue(const acontext: pcontextitemty; const adatasize: databitsizety;
                               const retainconst: boolean = false): boolean;
var
 opdata1: typeallocinfoty;
 stackoffset: int32;

 procedure doindirect();
 var
  op1: opcodety;
  si1: databitsizety;
  ssabefore: integer;
 begin
  with acontext^ do begin
   if d.dat.datatyp.typedata > 0 then begin
    opdata1:= getopdatatype(d.dat.datatyp.typedata,d.dat.datatyp.indirectlevel);
    ssabefore:= d.dat.fact.ssaindex;
    with insertitem(indirect[opdata1.kind],stackoffset,-1)^ do begin
     par.ssas1:= ssabefore;
     par.memop.t:= opdata1;
     d.dat.fact.ssaindex:= par.ssad;
     d.dat.fact.opdatatype:= opdata1;
    end;
   end;
  end;
 end; //doindirect

 procedure doref();
 begin
  with acontext^ do begin
   if d.dat.indirection < 0 then begin //dereference
    inc(d.dat.indirection); //correct addr handling
    if not pushindirection(stackoffset,false) then begin
     exit;
    end;
//      dec(d.dat.datatyp.indirectlevel); //correct addr handling
    doindirect;
   end
   else begin
    opdata1:= getopdatatype(d.dat.datatyp.typedata,
                                           d.dat.datatyp.indirectlevel);
    pushinsertdata(stackoffset,-1,d.dat.ref.c.address,
                             d.dat.ref.c.varele,d.dat.ref.offset,opdata1);
   end;
  end;
 end; //doref

var
 po1: ptypedataty;
 op1: popinfoty;
 i1,i2: integer;
 pocont1,pocont2: pcontextitemty;
label
 errlab; 

begin                    //todo: optimize
 result:= false;
 stackoffset:= getstackoffset(acontext);
 with info,acontext^ do begin
  if d.kind = ck_list then begin
   if not listtoset(acontext) then begin
    goto errlab;
   end;
  end;
  po1:= ptypedataty(ele.eledataabs(d.dat.datatyp.typedata));
  case d.kind of
   ck_ref: begin
    if d.dat.datatyp.indirectlevel < 0 then begin
     errormessage(err_invalidderef,[],stackoffset);
     exit;
    end;
    if af_paramindirect in d.dat.ref.c.address.flags then begin
     dec(d.dat.indirection);
     dec(d.dat.datatyp.indirectlevel);
     if d.dat.datatyp.indirectlevel > 0 then begin
      d.dat.ref.c.address.flags:= d.dat.ref.c.address.flags - 
                                            [af_aggregate,af_paramindirect];
                //??? correct?
     end;
    end;
    if d.dat.indirection > 0 then begin //@ operator
     if d.dat.indirection = 1 then begin
      pushinsertaddress(stackoffset,-1);
      d.dat.datatyp:= sysdatatypes[st_pointer]; //untyped pointer
     end
     else begin
      errormessage(err_cannotassigntoaddr,[],stackoffset);
      exit;
     end;
    end
    else begin
     doref();
    end;
   end;
   ck_reffact: begin
    doindirect();
   end;
   ck_prop: begin
    if d.dat.datatyp.indirectlevel < 0 then begin
     errormessage(err_invalidderef,[],stackoffset);
     exit;
    end;
    if d.dat.indirection > 0 then begin //@ operator
     errormessage(err_variableexpected,[],stackoffset);
     exit;
    end;
    with ppropertydataty(ele.eledataabs(d.dat.prop.propele))^ do begin
     if pof_readfield in flags then begin
      d.dat.ref.offset:= d.dat.ref.offset + readoffset;
      doref();
     end
     else begin
      if pof_readsub in flags then begin
       getclassvalue(acontext);
       ele.pushelementparent(readele);
       i2:= s.stackindex;
       inc(s.stackindex,stackoffset); //class instance
       i1:= 0; //result, class instance
       pocont1:= acontext+1;
       if pocont1^.d.kind = ck_index then begin
        i1:= pocont1^.d.index.count;
        pocont1^.d.kind:= ck_space;
       end;
       dosub(psubdataty(ele.eledataabs(readele)),s.stackindex+1,i1,[]);
       s.stackindex:= i2;
       ele.popelementparent();
       result:= true;
      end
      else begin
       errormessage(err_nomemberaccessproperty,[],stackoffset);
      end;
      exit;
     end;
    end;
   end;
   ck_const: begin
    if retainconst then begin
     result:= true;
     exit;
    end;
    pushinsertconst(stackoffset,-1,adatasize);
   end;
   ck_subres,ck_fact: begin
    if d.dat.indirection < 0 then begin
     for i1:= d.dat.indirection+2 to 0 do begin
      insertitem(oc_indirectpo,stackoffset,-1);
     end;
     d.dat.indirection:= 0;
     doindirect();
    end
    else begin
     if d.dat.indirection > 0 then begin
      errormessage(err_cannotaddressexp,[],stackoffset);
      exit;
     end;
    end;
   end;
   ck_typearg,ck_controltoken,ck_label: begin
    errormessage(err_valueexpected,[],stackoffset);
    goto errlab;
   end;
   ck_subcall: begin
    errormessage(err_subnovalue,[],stackoffset);
    exit;
   end;
   ck_error,ck_none: begin
    exit;
   end;
  {$ifdef mse_checkinternalerror}                             
   else begin
    internalerror(ie_notimplemented,'20140401B');
   end;
  {$endif}
  end;
  result:= true;
errlab:
  if not (d.kind in factcontexts) then begin
   initfactcontext(stackoffset);
   d.dat.fact.opdatatype:= opdata1;
  end;
 end;
end;
{
function getvalue(const stackoffset: integer; const adatasize: databitsizety;
                                  const retainconst: boolean = false): boolean;
begin
 with info do begin
  result:= getvalue(@contextstack[s.stackindex+stackoffset],
                                                adatasize,retainconst);
 end;
end;
}
function getaddress(const acontext: pcontextitemty;
                                const endaddress: boolean): boolean;
var
 si1: databitsizety;
 stackoffset: int32;
begin
 result:= false;
 stackoffset:= getstackoffset(acontext);
 with acontext^ do begin
  if d.kind in [ck_none,ck_error] then begin
   exit;
  end;
 {$ifdef mse_checkinternalerror}                             
  if not (d.kind in datacontexts) then begin
   internalerror(ie_handler,'20140405A');
  end;
 {$endif}
  inc(d.dat.indirection);
  inc(d.dat.datatyp.indirectlevel);
  if d.dat.datatyp.indirectlevel <= 0 then begin
   errormessage(err_cannotassigntoaddr,[]);
   exit;
  end;
  case d.kind of
   ck_ref: begin
    if not (af_segment in d.dat.ref.c.address.flags) then begin
     tracklocalaccess(d.dat.ref.c.address.locaddress,d.dat.ref.c.varele,
                           getopdatatype(d.dat.datatyp.typedata,
                                                d.dat.datatyp.indirectlevel));
    end;
    if d.dat.indirection = 1 then begin
     if endaddress then begin
      pushinsert(stackoffset,-1,d.dat.datatyp,d.dat.ref.c.address,
                                                       d.dat.ref.offset);
                  //address pointer on stack
      initfactcontext(stackoffset);
      d.dat.fact.opdatatype:= bitoptypes[das_pointer];
     end
     else begin
      inc(d.dat.ref.c.address.indirectlevel,d.dat.indirection);
      d.dat.indirection:= 0;
     end;
    end
    else begin
     if not pushindirection(stackoffset,true) then begin
      exit;
     end;
    end;
   end;
   ck_reffact: begin //
    d.kind:= ck_fact;
    result:= true;
//    internalerror1(ie_notimplemented,'20140404B'); //todo
//    exit;
   end;
   ck_fact,ck_subres: begin
    if d.dat.indirection <> 0 then begin
     result:= getvalue(acontext,das_none);
     exit;
    end;
   end;
  {$ifdef mse_checkinternalerror}
   else begin
    internalerror(ie_handler,'20140401A');
   end;
  {$endif}
  end;
 end;
 result:= true;
end;

function getaddress(const stackoffset: integer;
                                const endaddress: boolean): boolean;
begin
 with info do begin
  result:= getaddress(@contextstack[s.stackindex+stackoffset],endaddress);
 end;
end;

function getassignaddress(const acontext: pcontextitemty;
                                  const endaddress: boolean): boolean;
begin
 result:= false;
 with acontext^ do begin
  if (d.kind in datacontexts) then begin
   result:= getaddress(acontext,endaddress);
  end
  else begin
   errormessage(err_argnotassign,[],getstackoffset(acontext));
  end;
 end;
end;
{
function getassignaddress(const stackoffset: integer;
                                  const endaddress: boolean): boolean;
begin
 with info do begin
  result:= getassignaddress(@contextstack[s.stackindex+stackoffset],endaddress);
 end;
end;
}
procedure getclassvalue(const acontext: pcontextitemty);
begin
 with info,acontext^ do begin
 {$ifdef mse_debugparser}
  if d.kind <> ck_prop then begin
   internalerror(ie_handler,'20160202A');
  end;
  if ptypedataty(ele.eledataabs(
          ele.eleinfoabs(d.dat.prop.propele)^.header.parent))^.h.kind <> 
                                                       dk_class then begin
   internalerror(ie_handler,'20160202A');
  end;
 {$endif} 
  d.kind:= ck_ref;
  d.dat.datatyp.flags:= [];
  d.dat.datatyp.typedata:= ele.eleinfoabs(d.dat.prop.propele)^.header.parent;
  d.dat.datatyp.indirectlevel:= 1;
  inc(d.dat.indirection);
  getvalue(acontext,das_none);
 end;
end;

procedure sethandlerflag(const avalue: handlerflagty);
begin
 with info do begin
  include(contextstack[s.stackindex].d.handlerflags,avalue);
 end;
end;

procedure sethandlererror();
begin
 sethandlerflag(hf_error);
end;

procedure init();
var
 ty1: systypety;
 po1: pelementinfoty;
 po2: ptypedataty;
 int1: integer;
begin
 ele.addelement(tks_units,ek_none,globalvisi,unitsele);
 for ty1:= low(systypety) to high(systypety) do begin
  with systypeinfos[ty1] do begin
   po1:= ele.addelement(getident(name),ek_type,globalvisi);
   po2:= @po1^.data;
   po2^:= data;
   with sysdatatypes[ty1] do begin
    flags:= data.h.flags;
    indirectlevel:= data.h.indirectlevel;
    typedata:= ele.eleinforel(po1);
   end;
  end;
 end;
 for int1:= low(sysconstinfos) to high(sysconstinfos) do begin
  with sysconstinfos[int1] do begin
   po1:= ele.addelement(getident(name),ek_const,globalvisi);
   with pconstdataty(@po1^.data)^ do begin
    val.d:= cval;
    val.typ:= sysdatatypes[ctyp];
   end;
  end;
 end;
 po2:= ele.addelementdata(getident(),ek_type,globalvisi);
 fillchar(po2^,sizeof(po2^),0);
 po2^.h.kind:= dk_set;
 fillchar(emptyset,sizeof(emptyset),0);
 emptyset.typedata:= ele.eledatarel(po2);
 
 syssubhandler.init();
end;

procedure deinit;
begin
 syssubhandler.deinit();
end;

procedure resetssa();
begin
 with info do begin
  s.ssa.index:= 0;
  s.ssa.nextindex:= 0;
  s.ssa.bbindex:= 0;
 end;
end;

function getssa(const aopcode: opcodety; const count: integer): integer;
begin
 with info do begin
  result:= optable^[aopcode].ssa*count;
 end;
end;

function getssa(const aopcode: opcodety): integer;
begin
 with info do begin
  result:= optable^[aopcode].ssa;
 end;
end;
{
function getssaext(const aopcode: opcodety; const hasext: boolean): integer;
begin
 if hasext then begin
  with info do begin
   result:= optable^[aopcode].ssa;
  end;
 end
 else begin
  result:= 0;
 end;
end;
}
procedure addfactbinop(const poa,pob: pcontextitemty; const aopcode: opcodety);
//var
// poa,pob: pcontextitemty;
begin
 with info do begin
//  pob:= @contextstack[s.stacktop];
//  poa:= getpreviousnospace(pob)-1;
  with poa^ do begin
   with additem(aopcode)^ do begin      
    par.ssas1:= d.dat.fact.ssaindex;
    par.ssas2:= pob^.d.dat.fact.ssaindex;
    par.stackop.t:= getopdatatype(d.dat.datatyp.typedata,
                                    d.dat.datatyp.indirectlevel);
   end;
   d.kind:= ck_fact;
   d.dat.fact.ssaindex:= s.ssa.nextindex-1;
   d.dat.indirection:= 0;   
  end;
 end;
end;

procedure resolveshortcuts(const posource,podest: pcontextitemty);
var
 philist: dataoffsty;
begin
 with info,posource^ do begin
  if (d.kind = ck_shortcutexp) and (d.shortcutexp.shortcuts <> 0) then begin
  {$ifdef mse_checkinternalerror}
   with podest^ do begin
    if not (d.kind in factcontexts) then begin
     internalerror(ie_handler,'20151017B');
    end;
   end;
  {$endif}
   addlabel();
   linkresolvephi(d.shortcutexp.shortcuts,opcount-1,
                                         podest^.d.dat.fact.ssaindex,philist);
   with podest^ do begin
    with additem(oc_phi)^ do begin
     par.phi.t:= d.dat.fact.opdatatype;
     par.phi.philist:=philist;
    end;
    d.dat.fact.ssaindex:= s.ssa.nextindex-1;
   end;
   d.shortcutexp.shortcuts:= 0;
  end;
 end;
end;

procedure updateop(const opsinfo: opsinfoty);
 procedure div0error();
 begin
  with info do begin
   errormessage(err_div0,[],s.stacktop-s.stackindex);
  end;
 end; //div0error
 
var
 kinda,kindb: datakindty;
 int1: integer;
 sd1: stackdatakindty;
 op1: opcodety;
 po1: ptypedataty;
 bo1,bo2: boolean;
 si1: databitsizety;
 po2: pointer;
 poa,pob: pcontextitemty;
label
 endlab;
begin
 with info do begin
  bo1:= false;
  if not getfactstart(s.stackindex-1,poa) or
                not getfactstart(s.stacktop,pob) then begin
   goto endlab;
  end;
  with poa^ do begin
   if not (d.kind in alldatacontexts) or 
             not (pob^.d.kind in alldatacontexts)then begin
    errormessage(err_illegalexpression,[]);
    goto endlab;
   end;
   if not (d.kind in datacontexts) or 
              not (pob^.d.kind in datacontexts) or
                       (d.dat.datatyp.typedata <= 0) or 
                             (pob^.d.dat.datatyp.typedata <= 0) then begin
    goto endlab; //errorstate
   end;
   bo2:= true;
   if d.kind <> ck_const then begin
    bo2:= getvalue(poa,das_none);
   end;
   if pob^.d.kind <> ck_const then begin
    if not getvalue(pob,das_none) then begin
     bo2:= false;
    end;
   end;
   if not bo2 then begin
    goto endlab;
   end;
   if opsinfo.wantedtype <> st_none then begin
    if not tryconvert(pob,opsinfo.wantedtype) then begin
     operationnotsupportederror(d,contextstack[s.stacktop].d,opsinfo.opname);
     goto endlab;
    end;
    if not tryconvert(poa,opsinfo.wantedtype) then begin
     operationnotsupportederror(d,poa^.d,opsinfo.opname);
     goto endlab;
    end;
    bo1:= true;
    po1:= ele.eledataabs(d.dat.datatyp.typedata);
   end
   else begin   
    po1:= ele.eledataabs(d.dat.datatyp.typedata);
    int1:= d.dat.datatyp.indirectlevel;
    if not tryconvert(pob,po1,int1,[coo_notrunk]) then begin
     with pob^ do begin
      po1:= ele.eledataabs(d.dat.datatyp.typedata);
      int1:= d.dat.datatyp.indirectlevel;
     end;
     if tryconvert(poa,po1,int1,[coo_notrunk]) then begin
      bo1:= true;
     end;
    end
    else begin
     bo1:= true;
    end;
   end;
   if not bo1 then begin
    incompatibletypeserror(poa^.d,pob^.d);
    goto endlab;
   end
   else begin
    if int1 > 0 then begin //indirectlevel
     sd1:= sdk_pointer;
    end
    else begin
     case po1^.h.kind of
      dk_enum: begin
       sd1:= stackdatakinds[dk_integer];
      end;
      dk_set: begin
       sd1:= sdk_set32; //todo: arbitrary size
      end;
      else begin
       sd1:= stackdatakinds[po1^.h.kind];
      end;
     end;
    end;
    op1:= opsinfo.ops[sd1];
    if op1 = oc_none then begin
     operationnotsupportederror(d,pob^.d,opsinfo.opname);
     s.stacktop:= s.stackindex-1;
    end
    else begin
     bo2:= false;
     if (d.kind = ck_const) and (pob^.d.kind = ck_const) then begin
      bo2:= true;
      po2:= @pob^.d.dat.constval.vinteger;
      case op1 of //add and sub handled in addsubterm()
       oc_mulcard32: begin       
        d.dat.constval.vcardinal:= card32(d.dat.constval.vinteger) *
                                                       card32(pcard64(po2)^);
       end;
       oc_mulint32: begin
        d.dat.constval.vinteger:= int32(d.dat.constval.vinteger) *
                                                         int32(pint64(po2)^);
       end;
       oc_mulflo64: begin
        d.dat.constval.vfloat:= d.dat.constval.vfloat * (pflo64(po2)^);
       end;
       oc_divcard32: begin
        if pcard64(po2)^ = 0 then begin
         div0error();
         goto endlab;
        end;
        d.dat.constval.vcardinal:= card32(d.dat.constval.vinteger) div
                                                       card32(pcard64(po2)^);
       end;
       oc_divint32: begin
        if pint64(po2)^ = 0 then begin
         div0error();
         goto endlab;
        end;
        d.dat.constval.vinteger:= int32(d.dat.constval.vinteger) div
                                                         int32(pint64(po2)^);
       end;
       oc_divflo64: begin
        if pflo64(po2)^ = 0 then begin
         div0error();
         goto endlab;
        end;
        d.dat.constval.vfloat:= d.dat.constval.vfloat / pflo64(po2)^;
       end;
       oc_and32: begin
        d.dat.constval.vinteger:= int32(d.dat.constval.vinteger) and
                                                         int32(pint64(po2)^);
       end;
       oc_or32: begin
        d.dat.constval.vinteger:= int32(d.dat.constval.vinteger) or
                                                         int32(pint64(po2)^);
       end;
       oc_xor32: begin
        d.dat.constval.vinteger:= int32(d.dat.constval.vinteger) xor
                                                         int32(pint64(po2)^);
       end;
       oc_shl32: begin
        d.dat.constval.vinteger:= int32(d.dat.constval.vinteger) shl
                                                         int32(pint64(po2)^);
       end;
       oc_shr32: begin
        d.dat.constval.vinteger:= int32(d.dat.constval.vinteger) shr
                                                         int32(pint64(po2)^);
       end; //todo: handle all ops
       else begin
        bo2:= false;
       end;
      end;
     end;
     if bo2 then begin
      goto endlab;
     end;

     if int1 > 0 then begin
      si1:= das_pointer;
     end
     else begin
      si1:= po1^.h.datasize;
     end;
     if d.kind = ck_const then begin
      pushinsertconst(poa,-1,si1);
     end;
     with pob^ do begin
      if d.kind = ck_const then begin
       pushinsertconst(pob,-1,si1);
      end;
     end;
     addfactbinop(poa,pob,op1);
    end;
endlab:
    s.stacktop:= getstackindex(poa);
//    s.stacktop:= s.stackindex-1;
   end;
  end;
  s.stackindex:= getpreviousnospace(s.stacktop-1); 
 end;
end;

procedure getordrange(const typedata: ptypedataty; out range: ordrangety);
begin
 with typedata^ do begin
  case h.kind of
   dk_cardinal: begin
    if h.datasize <= das_8 then begin
     range.min:= infocard8.min;
     range.max:= infocard8.max;
    end
    else begin
     if h.datasize <= das_16 then begin
      range.min:= infocard16.min;
      range.max:= infocard16.max;
     end
     else begin
      range.min:= infocard32.min;
      range.max:= infocard32.max;
     end;
    end;
   end;
   dk_integer: begin
    if h.datasize <= das_8 then begin
     range.min:= infoint8.min;
     range.max:= infoint8.max;
    end
    else begin
     if h.datasize <= das_16 then begin
      range.min:= infoint16.min;
      range.max:= infoint16.max;
     end
     else begin
      range.min:= infoint32.min;
      range.max:= infoint32.max;
     end;
    end;
   end;
   dk_boolean: begin
    range.min:= 0;
    range.max:= 1;
   end;
   dk_enum: begin
    range.min:= ptypedataty(ele.eledataabs(typedata^.infoenum.first))^.
                                                         infoenumitem.value;
    range.max:= ptypedataty(ele.eledataabs(typedata^.infoenum.last))^.
                                                         infoenumitem.value;
   end;
  {$ifdef mse_checkinternalerror}
   else begin
    internalerror(ie_handler,'20120327B');
   end;
  {$endif}
  end;
 end;
end;

function getordrange(const typedata: ptypedataty): ordrangety; inline;
begin
 getordrange(typedata,result);
end;

function getordcount(const typedata: ptypedataty): int64;
var
 ra1: ordrangety;
begin
 getordrange(typedata,ra1);
 result:= ra1.max - ra1.min + 1;
end;

function getordconst(const avalue: dataty): int64;
begin
 with avalue do begin
  case kind of
   dk_integer: begin
    result:= vinteger;
   end;
   dk_boolean: begin
    if vboolean then begin
     result:= 1;
    end
    else begin
     result:= 0;
    end;
   end;
  {$ifdef mse_checkinternalerror}
   else begin
    internalerror(ie_handler,'20140329A');
   end;
  {$endif}
  end;
 end;
end;

function getdatabitsize(const avalue: int64): databitsizety;
begin
 result:= das_8;
 if avalue < 0 then begin
  if avalue < -$80 then begin
   if avalue < -$8000 then begin
    if avalue < -$80000000 then begin
     result:= das_64;
    end
    else begin
     result:= das_32;
    end;
   end
   else begin
    result:= das_16;
   end;
  end;   
 end
 else begin
  if avalue > $7f then begin
   if avalue > $7fff then begin
    if avalue > $7fffffff then begin
     result:= das_64;
    end
    else begin
     result:= das_32;
    end;
   end
   else begin
    result:= das_16;
   end;
  end;   
 end;
end;

procedure trackalloc(const adatasize: databitsizety; const asize: integer; 
                                 var address: segaddressty);
begin
 if co_llvm in info.compileoptions then begin
  if address.segment = seg_globvar then begin
   if adatasize = das_none then begin
    address.address:= info.s.unitinfo^.llvmlists.globlist.
                                      addbytevalue(asize,info.s.globlinkage);
   end
   else begin
    address.address:= info.s.unitinfo^.llvmlists.globlist.
                                      addbitvalue(adatasize,info.s.globlinkage);
   end;
  end;
 end;
end;

procedure setenumconst(const aenumitem: infoenumitemty; 
                                   var acontextitem: contextitemty);
begin
 with acontextitem do begin
  initdatacontext(acontextitem.d,ck_const);
  d.dat.datatyp.flags:= [];
  d.dat.datatyp.typedata:= aenumitem.enum;
  d.dat.datatyp.indirectlevel:= 0;
  d.dat.constval.kind:= dk_enum;
  d.dat.constval.vinteger:= aenumitem.value;
 end;
end;

procedure pushcurrentscope(const ascope: metavaluety);
begin
 with info do begin
  inc(scopemetaindex);  //dummy 0 on scopemetastack[0]
  if high(scopemetastack) < scopemetaindex then begin
   setlength(scopemetastack,scopemetaindex*2+256);
  end;
  scopemetastack[scopemetaindex]:= ascope;
  currentscopemeta:= ascope;
 end;
 postlineinfo();
end;

procedure popcurrentscope();
begin
 with info do begin
  dec(scopemetaindex); //dummy 0 on scopemetastack[0]
  if scopemetaindex < 0 then begin 
   internalerror1(ie_unit,'20160229A');
  end;               
  currentscopemeta:= scopemetastack[scopemetaindex];
 end;
// postlineinfo();
end;

{
procedure setcurrentscope(const ascope: metavaluety);
begin
 info.s.currentscopemeta:= ascope;
 postlineinfo();
end;
}
{$ifdef mse_debugparser}
procedure outhandle(const text: string);
begin
 outinfo('*'+text+'*',false);
end;

procedure outinfo(const text: string; const indent: boolean = true);

 procedure writetype(const ainfo: contextdataty);
 var
  po1: ptypedataty;
 begin
  with ainfo.dat.datatyp do begin
   po1:= ele.eledataabs(typedata);
   write('T:',typedata,' ',
          getenumname(typeinfo(datakindty),ord(po1^.h.kind)));
   if po1^.h.kind <> dk_none then begin
    write(' F:',settostring(ptypeinfo(typeinfo(typeflagsty)),
                  integer(po1^.h.flags),true),
          ' I:',indirectlevel,':',ainfo.dat.indirection,
          ' F:',settostring(ptypeinfo(typeinfo(typeflagsty)),
                                            integer(flags),true),' ');
   end;
  end;
 end;//writetype

 procedure writetyp(const atyp: typeinfoty);
 var
  po1: ptypedataty;
 begin
  with atyp do begin
   if typedata = 0 then begin
    write('NIL');
   end
   else begin
    po1:= ele.eledataabs(typedata);
    write('T:',typedata,' ',
           getenumname(typeinfo(datakindty),ord(po1^.h.kind)));
    if po1^.h.kind <> dk_none then begin
     write(' F:',settostring(ptypeinfo(typeinfo(typeflagsty)),
                  integer(po1^.h.flags),true),
           ' I:',indirectlevel);
    end;
   end;
  end;
 end;//writetyp

 procedure writetypedata(const adata: ptypedataty);
 begin
   write(getidentname(pelementinfoty(pointer(adata)-eledatashift)^.header.name),
          ':',getenumname(typeinfo(datakindty),ord(adata^.h.kind)))
  end;
 
 procedure writeaddress(const aaddress: addressvaluety);
 begin
  with aaddress do begin
   write('I:',inttostr(indirectlevel),' A:',inttostr(integer(poaddress)),' ');
   write(settostring(ptypeinfo(typeinfo(addressflagsty)),
                                                     integer(flags),true),' ');
   if af_stack in flags then begin
    write(' F:',inttostr(locaddress.framelevel),' ');
   end;
   if af_segment in flags then begin
    write(' S:',getenumname(typeinfo(segmentty),ord(segaddress.segment)),' ');
   end;
  end;
 end;//writeaddress

 procedure writedat(const adat: datacontextty);
 begin
//  write('F:',settostring(ptypeinfo(typeinfo(datacontextflagsty)),
//                                                integer(adat.flags),true),' ');
 end;
  
 procedure writeref(const ainfo: contextdataty);
 begin
  writedat(ainfo.dat);
  with ainfo.dat.ref do begin
   writeaddress(c.address);
   write('O:',offset,' ');
  end;
 end;//writeref
 
var
 int1: integer;
begin
 with info do begin
  if not (cos_internaldebug in s.compilerswitches) then begin
   exit;
  end;
  if indent then begin
   write('  ');
  end;
  write(text,' I:',s.stackindex,' T:',s.stacktop,' O:',opcount,
  ' S:',s.ssa.index,' N:',s.ssa.nextindex,
  ' cont:',currentcontainer);
  if currentcontainer <> 0 then begin
   write(' ',getidentname(ele.eleinfoabs(currentcontainer)^.header.name));
  end;
  write(' ',settostring(ptypeinfo(typeinfo(statementflagsty)),
                         integer(s.currentstatementflags),true));
  write(' L:'+inttostr(s.source.line+1)+':''',psubstr(s.debugsource,s.source.po)+''','''+
                         singleline(s.source.po),'''');
  writeln;
  for int1:= 0 to s.stacktop do begin
   write(fitstring(inttostrmse(int1),3,sp_right));
   if int1 = s.stackindex then begin
    write('*');
   end
   else begin
    write(' ');
   end;
   if (int1 < s.stacktop) and (int1 = contextstack[int1+1].parent) then begin
    write('-');
   end
   else begin
    write(' ');
   end;
   with contextstack[int1] do begin
    write(fitstring(inttostrmse(parent),3,sp_right),' ');
    if bf_continue in transitionflags then begin
     write('>');
    end
    else begin
     write(' ');
    end;
    if context <> nil then begin
     with context^ do begin
      if cutbefore then begin
       write('-');
      end
      else begin
       write(' ');
      end;
      if pop then begin
       write('^');
      end
      else begin
       write(' ');
      end;
      if popexe then begin
       write('!');
      end
      else begin
       write(' ');
      end;
      if cutafter then begin
       write('-');
      end
      else begin
       write(' ');
      end;
     end;
     write(fitstring(inttostrmse(opmark.address),3,sp_right));
     write('<',context^.caption,'> ');
    end
    else begin
     write(fitstring(inttostrmse(opmark.address),3,sp_right));
     write('<NIL> ');
    end;
    write(getenumname(typeinfo(d.kind),ord(d.kind)));
    if d.kind <> ck_space then begin
     write(settostring(ptypeinfo(typeinfo(handlerflagsty)),
                                               int32(d.handlerflags),true),' ');
     case d.kind of
      ck_block: begin
       write('idbefore:'+inttostrmse(d.block.blockidbefore));
      end;
      ck_label: begin
       write('lab:'+inttostrmse(d.dat.lab));
      end;
      ck_ident: begin
       write('$',hextostr(d.ident.ident,8),':',d.ident.len);
       write(' ',getidentname(d.ident.ident));
       write(' flags:',settostring(ptypeinfo(typeinfo(identflagsty)),
                                            integer(d.ident.flags),true));
      end;
      ck_list: begin
       write('itemcount:',d.list.itemcount,' contextcount:',d.list.contextcount,
        ' flags:',settostring(ptypeinfo(typeinfo(listflagsty)),
                                            integer(d.list.flags),true));
      end;
      ck_fact,ck_subres: begin
       writedat(d.dat);
       write('ssa:',d.dat.fact.ssaindex,' ');
       writetype(d);
      end;
      ck_ref: begin
       writeref(d);
       writetype(d);
      end;
      ck_prop: begin
       writeref(d);
       writetype(d);
       writeln();
       write(' E:',d.dat.prop.propele);
      end;
      ck_reffact: begin
       writedat(d.dat);
       writetype(d);
      end;
      ck_const: begin
       writedat(d.dat);
       writetype(d);
       write('V:');
       case d.dat.constval.kind of
        dk_boolean: begin
         write(d.dat.constval.vboolean,' ');
        end;
        dk_integer: begin
         write(d.dat.constval.vinteger,' ');
        end;
        dk_cardinal: begin
         write(d.dat.constval.vcardinal,' ');
        end;
        dk_float: begin
         write(d.dat.constval.vfloat,' ');
        end;
        dk_address: begin
         writeaddress(d.dat.constval.vaddress);
        end;
        dk_enum: begin
         write(d.dat.constval.venum.value,' ');
        end;
        dk_set: begin
         write(hextostr(card32(d.dat.constval.vset.value)),' '); 
                   //todo: arbitrary size, set format
        end;
        dk_openarray: begin
         write('size:',inttostrmse(d.dat.constval.vopenarray.size),
               ' high:',inttostrmse(d.dat.constval.vopenarray.size));
        end;
       end;
      end;
      ck_subdef: begin
       write('fl:',settostring(ptypeinfo(typeinfo(subflagsty)),
                                            integer(d.subdef.flags),true),
             ' ma:',d.subdef.match,
                             ' ps:',d.subdef.paramsize,' vs:',d.subdef.varsize);
      end;
      ck_paramdef: begin
       with d.paramdef do begin
        write('kind:',getenumname(typeinfo(kind),ord(kind)),
                       ' def:',defaultconst);
       end;
      end;
      ck_recorddef: begin
       write('foffs:',d.rec.fieldoffset);
      end;
      ck_classdef: begin
       write('foffs:',d.cla.fieldoffset,' virt:',d.cla.virtualindex);
      end;
      ck_classprop: begin
       write(' flags:',settostring(ptypeinfo(typeinfo(propflagsty)),
                                            integer(d.classprop.flags),true));
       if d.classprop.flags * canreadprop <> [] then begin
        write(' read:',inttostrmse(d.classprop.readele),
                    ':',inttostrmse(d.classprop.readoffset));
       end;
       if d.classprop.flags * canwriteprop <> [] then begin
        write(' write:',inttostrmse(d.classprop.writeele),
                    ':',inttostrmse(d.classprop.writeoffset));
       end;
      end;
      ck_index: begin
       write({'opshiftmark:'+inttostrmse(d.index.opshiftmark)+}
                'count:'+inttostrmse(d.index.count));
      end;
      ck_getindex: begin
 //      write('itemtype:'+inttostrmse(d.getindex.itemtype)+' ');
 //      writetypedata(ele.eledataabs(d.getindex.itemtype));
      end;
      ck_typedata: begin
       writetypedata(d.typedata);
      end;
      ck_typeref: begin
       write(' T:'+inttostrmse(d.typeref)+' ');
       writetypedata(ele.eledataabs(d.typeref));
      end;
      ck_typetype,ck_fieldtype: begin
       writetyp(d.typ);
      end;
      ck_control: begin
       with d.control do begin
        write('kind:',getenumname(typeinfo(kind),ord(kind)),' OP1:',
                                                        opmark1.address);
       end;
      end;
      ck_shortcutexp: begin
       write('op:',d.shortcutexp.op,' shortcuts:',
                          inttostr(d.shortcutexp.shortcuts));
      end;
     end;
     writeln(' '+inttostr(start.line+1)+':''',
              psubstr(debugstart,start.po),''',''',singleline(start.po),'''');
    end
    else begin
     writeln(); //ck_space
    end;
   end;
  end;
 end;
end;

{$endif}

{$ifdef mse_debugparser}
procedure dumpelements();
var
 ar1: msestringarty;
 int1: integer;
begin
 writeln('--ELEMENTS---------------------------------------------------------');
 ar1:= ele.dumpelements;
 for int1:= 0 to high(ar1) do begin
  writeln(ar1[int1]);
 end;
 writeln('-------------------------------------------------------------------');
end;
{$endif}

end.