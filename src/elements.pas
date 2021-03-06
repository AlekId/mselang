{ MSElang Copyright (c) 2013-2018 by Martin Schreiber
   
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
//
//todo: use efficient data structures and procedures, 
//this is a proof of concept only
//
unit elements;
{$ifdef FPC}{$mode objfpc}{$h+}{$goto on}{$endif}
interface
uses
 msestrings,msetypes,msehash,parserglob,handlerglob,segmentutils,globtypes,
 classhandler,mselist,llvmlists,elementcache;

const
 pointertypeid = -1;
 
{
 identbufty = record
  po: pidentty;
  high: int32;
 end;
}
type
 elementoffsetaty = array[0..0] of elementoffsetty;
 pelementoffsetaty = ^elementoffsetaty;
 
 aliasdataty = record
  base: elementoffsetty;
 end;
 paliasdataty = ^aliasdataty;
 
 elementkindty = (ek_none,ek_alias,ek_ref,ek_type,ek_const,ek_var,
                  ek_field,ek_property,ek_labeldef,ek_classintfname,
                  ek_classintftype,
                  ek_ancestorchain,
                  ek_sysfunc,ek_sub,ek_internalsub,ek_operator,
                  ek_nestedvar,
                  ek_global,ek_unit,ek_implementation,
                  ek_classimpnode,ek_classintfnamenode,ek_classintftypenode,
                  ek_uses,ek_condition);
 elementkindsty = set of elementkindty;
 
 elementheaderty = record
 {$ifdef mse_debugparser}
 // size: integer; //for debugging
  next: elementoffsetty; //for debugging
 {$endif}
  name: identty;
  path: identty;
  parent: elementoffsetty; //offset in data array
  parentlevel: integer;    //max = maxidentvector-1
  kind: elementkindty;
  visibility: visikindsty;
  defunit: punitinfoty;
 end;
 
 elementinfoty = record
  header: elementheaderty;
  data: record
  end;
 end;
 pelementinfoty = ^elementinfoty;

 elementdataty = record
  key: identty;
  data: elementoffsetty; //offset in elementdata
 end;
 pelementdataty = ^elementdataty;
 elementhashdataty = record
  header: hashheaderty;
  data: elementdataty;
 end;
 pelementhashdataty = ^elementhashdataty;
 
const
 elesize = sizeof(elementinfoty);
 eledatashift = sizeof(elementheaderty);
 maxparents = 255;

 elesizes: array[elementkindty] of integer = (
//ek_none,ek_alias,                   ek_ref,                   
  elesize,sizeof(aliasdataty)+elesize,sizeof(refdataty)+elesize,
//ek_type,                   ek_const,         
  sizeof(typedataty)+elesize,sizeof(constdataty)+elesize,
//ek_var,                   ek_field,                
  sizeof(vardataty)+elesize,sizeof(fielddataty)+elesize,
//ek_property,
  sizeof(propertydataty)+elesize,
//ek_labeldef
  sizeof(labeldefdataty)+elesize,
//ek_classintfname,                   ek_classintftype,
  sizeof(classintfnamedataty)+elesize,sizeof(classintftypedataty)+elesize,
//ek_ancestorchain,
  sizeof(ancestorchaindataty)+elesize,
//ek_sysfunc,                   ek_sub,
  sizeof(sysfuncdataty)+elesize,sizeof(subdataty)+elesize,
//ek_internalsub,                   ek_operator,
  sizeof(internalsubdataty)+elesize,sizeof(operatordataty)+elesize,
//ek_nestedvar,
  sizeof(nestedvardataty)+elesize,
//ek_classes,                   ek_class,
 {sizeof(classesdataty)+elesize,}{sizeof(classdataty)+elesize,}
//ek_global,
  sizeof(globaldataty)+elesize,
//ek_unit,                   ek_implementation  
  sizeof(unitdataty)+elesize,sizeof(implementationdataty)+elesize,
//ek_classimpnode,                   ek_classintfnamenode,
  sizeof(classimpnodedataty)+elesize,sizeof(classintfnamenodedataty)+elesize,
//ek_classintftypenode,
  sizeof(classintftypenodedataty)+elesize,
//ek_uses                    ek_condition
  sizeof(usesdataty)+elesize,sizeof(conditiondataty)+elesize
 );

type
 elehandlerprocty = procedure(const aelement: pelementinfoty; var adata;
                                                     var terminate: boolean);
 scopeinfoty = record
  name: identty;
  element: elementoffsetty;
  childparent: elementoffsetty;
 end;
 pscopeinfoty = ^scopeinfoty;
 
 telementhashdatalist = class(thashdatalist)
  private
//   ffindvislevel: visikindsty;
   fscopes: pointer;
   fscopespo: pscopeinfoty;
   fscopesend: pointer;
   fscopestack: integerarty;
   fscopestackpo: integer;
   fscopestacksize: integer;
//   fdestroying: boolean;
   fparents: array[0..maxparents] of elementoffsetty;
   fparentindex: integer;
   flastdescendent: elementoffsetty;
  protected
   felementdata: string;
   fnextelement: elementoffsetty;
   felementlen: elementoffsetty;
   felementpath: identty; //sum of names in hierarchy 
   felementparent: elementoffsetty;
   fparentlevel: integer;
   function hashkey(const akey): hashvaluety; override;
   function checkkey(const akey; const aitem: phashdataty): boolean; override;
   procedure addelement(const aident: identty; const avislevel: visikindsty;
                                              const aelement: elementoffsetty);
   procedure setelementparent(const element: elementoffsetty);
   procedure checkbuffersize;
   function getrecordsize: int32 override;
   function findchild(aparent: elementoffsetty;
               const achildtree: pidentty; const ahigh: int32; 
               const akinds: elementkindsty;
               avislevel: visikindsty; out element: elementoffsetty): boolean;
   function findchilddata(const aparent: elementoffsetty;
               const achildtree: pidentty; const ahigh: int32;
               const akinds: elementkindsty;
               const avislevel: visikindsty; out adata: pointer): boolean;
   function adduniquechilddata(const aparent: elementoffsetty;
               const achild: pidentty; const ahigh: int32; 
               const akind: elementkindty;const avislevel: visikindsty;
                                            out aelementdata: pointer): boolean;
   procedure inieleheader(var aheader: elementheaderty;
                       const aname: identty; const akind: elementkindty;
                       const avislevel: visikindsty);
  public
//todo: use faster calling, less parameters
   constructor create();
   procedure clear(); override;
   procedure checkcapacity(const areserve: integer);
   procedure checkcapacity(const akind: elementkindty;
                                        const acount: integer = 1);
   procedure checkcapacity(const akind: elementkindty;
                               const acount: integer; var reloc: pointer);
   procedure checkcapacity(const akind: elementkindty;
                           const acount: integer; var reloc1,reloc2: pointer);
   function addbuffer(const asize: int32): pointer;
   procedure enterbufferitem(const adata: pelementinfoty);

   function forallcurrent(const aident: identty; const akinds: elementkindsty;
                 const avislevel: visikindsty; const ahandler: elehandlerprocty;
                 var adata): boolean; //returns terminated flag
   function forallancestor(const aident: identty; const akinds: elementkindsty;
                 const avislevel: visikindsty; const ahandler: elehandlerprocty;
                 var adata): boolean; //returns terminated flag

   function checkancestor(var aele: elementoffsetty;
                                        var avislevel: visikindsty): boolean;
   
   function findcurrent(const aident: identty; const akinds: elementkindsty;
             avislevel: visikindsty; out element: elementoffsetty): boolean;
   function findcurrent(const aident: identty; const akinds: elementkindsty;
             avislevel: visikindsty; out adata: pointer): elementkindty;
                  //searches in current scope and ancestors
   function findupward(const aident: identty; const akinds: elementkindsty;
                  const avislevel: visikindsty;
                  out element: elementoffsetty): visikindsty; overload;
                  //searches in current scope and above
                  //returns ored visikinds of path or [] if not found
   function findupward(const aidents: identvecty;
                      const akinds: elementkindsty;
                      const avislevel: visikindsty;
                      out element: elementoffsetty;
                      out firstnotfound: integer;
                      const start: int32 = 0): visikindsty; overload;
                  //searches in current scope and above,
                  //firstnotfound = index of first not matching in aident
                  //returns ored visikinds of path or [] if not found
   function findreverse(const alen: int32; const aids: pidentty;
                        out element: elementoffsetty): boolean;
                  //last id is top, returns true if found

   function findchild(aparent: elementoffsetty; 
                 const achild: identty; const akinds: elementkindsty;
                 avislevel: visikindsty; 
                               out element: elementoffsetty): boolean;
   function findchilddata(const aparent: elementoffsetty; 
                 const achild: identty; const akinds: elementkindsty;
                 const avislevel: visikindsty; out adata: pointer): boolean;
   function findchild(const aparent: elementoffsetty;
                 const achild: identty; const akinds: elementkindsty; 
                 const avislevel: visikindsty; 
               out element: elementoffsetty; out adata: pointer): elementkindty;
   function findchild(aparent: elementoffsetty; 
                 const achildtree: array of identty;
                 const akinds: elementkindsty;
                 avislevel: visikindsty; 
                               out element: elementoffsetty): boolean;
   function findchild(aparent: elementoffsetty; 
                 const achildtree: identvecty;
                 const akinds: elementkindsty;
                 avislevel: visikindsty; 
                               out element: elementoffsetty): boolean;
{
   function findchild(aparent: elementoffsetty; 
                 const achildtree: identvecty;
                 const akinds: elementkindsty;
                 avislevel: visikindsty; 
                 out element: elementoffsetty;
                 out firstnotfound: int32): boolean;
}
   function findchilddata(const aparent: elementoffsetty; 
                 const achildtree: array of identty;
                 const akinds: elementkindsty;
                 const avislevel: visikindsty; 
                               out adata: pointer): boolean;
   function findchilddata(const aparent: elementoffsetty; 
                 const achildtree: identvecty;
                 const akinds: elementkindsty;
                 const avislevel: visikindsty; 
                               out adata: pointer): boolean;
   function hasscope(const aname: identty): boolean;
   function findparentscope(const aident: identty; const akinds: elementkindsty;
           const avislevel: visikindsty; out aparent: elementoffsetty;
           out anamed: boolean): boolean;
                  //searches in scopestack, returns parent
   property lastdescendent: elementoffsetty read flastdescendent;
   function elebase: pointer; inline;
   function eledatabase: pointer; inline;
   function eleoffset: ptruint; inline;
   function eledataoffset: ptruint; inline;
   function eleinfoabs(const aelement: elementoffsetty): pelementinfoty; inline;
   function eleinforel(const aelement: pelementinfoty): elementoffsetty; inline;
   function eledataabs(const aelement: elementoffsetty): pointer; inline;
   function eledatarel(const aelement: pointer): elementoffsetty; inline;
   property eletopoffset: elementoffsetty read fnextelement;
   function basetype(const aelement: elementoffsetty): ptypedataty;
   
  {$ifdef mse_debugparser}
   function dumpelements: msestringarty;
   function dumppath(const aelement: pelementinfoty): msestring;
  {$endif}
   function pushelementduplicate(const aname: identty;
                   const akind: elementkindty; const avislevel: visikindsty;
                                  const sizeextend: integer): pelementinfoty;
   function pushelementduplicatedata(const aname: identty;
                   const akind: elementkindty; const avislevel: visikindsty;
                                                  out adata: pointer): boolean;
                  //false if duplicate
   function pushelement(const aname: identty; const akind: elementkindty;
                   const avislevel: visikindsty{;
                  const asize: integer}): pelementinfoty; //nil if duplicate
   function pushelement(const aname: identty; const akind: elementkindty;
                  const avislevel: visikindsty;                  
                  out aelementdata: pointer): boolean;
                                                       //false if duplicate
   function pushelementorduplicate(const aname: identty;
                const akind: elementkindty;  
                const avislevel: visikindsty;                
                const sizeextend: integer; out aelementdata: pointer): boolean;
                                                       //false if duplicate
   function pushelement(const aname: identty; const akind: elementkindty;
           const avislevel: visikindsty;                         
           out aelementdata: elementoffsetty): boolean;
                                                       //false if duplicate
   function popelement: pelementinfoty;
   function addelementduplicate(const aname: identty;
                                const akind: elementkindty;
                                const avislevel: visikindsty): pelementinfoty;
   function addelementduplicatedata(const aname: identty;
               const akind: elementkindty;
               const avislevel: visikindsty;
               out aelementdata: pointer;
               const asearchlevel: visikindsty = allvisi): boolean;
                                                       //false if duplicate
   function addelementduplicate1(const aname: identty;
                                 const akind: elementkindty;
                                 const avislevel: visikindsty): elementoffsetty;
   function addelementduplicatedata1(const aname: identty;
                                const akind: elementkindty;
                                const avislevel: visikindsty): pointer;
   function addelement(const aname: identty; const akind: elementkindty;
                       const avislevel: visikindsty): pelementinfoty; 
                                              //nil if duplicate
   function addelement(const aname: identty; const akind: elementkindty;
                       const avislevel: visikindsty; 
                          out aelement: pelementinfoty): boolean; 
                      //false if duplicate, aelement = new or duplicate
   function addelementdata(const aname: identty; const akind: elementkindty;
                       const avislevel: visikindsty): pointer; 
                                              //nil if duplicate
   function addelementdata(const aname: identty; const akind: elementkindty;
              const avislevel: visikindsty;
              out aelementdata: pointer): boolean;
         //false if duplicate, aelementdata = new or duplicate
   function addelement(const aname: identty; const akind: elementkindty;
              const avislevel: visikindsty;
              out aelementoffset: elementoffsetty): boolean;
         //false if duplicate, aelementoffset = 0 if duplicate
   function adduniquechilddata(const aparent: elementoffsetty;
                           const achild: array of identty; 
                           const akind: elementkindty;
                           const avislevel: visikindsty;
                           out aelementdata: pointer): boolean;
                                          //true if new
   function adduniquechilddata(const aparent: elementoffsetty;
                           const achild: identvecty; 
                           const akind: elementkindty;
                           const avislevel: visikindsty;
                           out aelementdata: pointer): boolean;
                                          //true if new
   function addchildduplicatedata(const aparent: elementoffsetty;
                           const achild: array of identty;
                           const akind: elementkindty;
                           const avislevel: visikindsty): pointer;
   function addalias(const aname: identty; const abase: elementoffsetty;
                                     const avislevel: visikindsty): boolean;
                                 //false if duplicate
                           
   procedure pushscopelevel();
   procedure popscopelevel();
   function addscope(const aname: identty; const akind: elementkindty;
                        const achildparent: elementoffsetty): pointer;
   
   function decelementparent: elementoffsetty; //returns old offset
   procedure markelement(out ref: markinfoty);
   procedure releaseelement(const ref: markinfoty);
   procedure hideelementdata(const adata: pointer); //for error handling only
   property elementparent: elementoffsetty read felementparent 
                                                 write setelementparent;
   function parentdata: pointer;
   function parentelement: pelementinfoty;
   procedure pushelementparent(); //save current on stack
   procedure pushelementparent(const aparent: elementoffsetty);
   procedure popelementparent;
//   property findvislevel: visikindsty read ffindvislevel write ffindvislevel;
 end;

procedure clear;
procedure init;
procedure initunit(const aunit: punitinfoty);
procedure deinitunit(const aunit: punitinfoty; const aftercompile: boolean);
procedure interfaceend(const aunit: punitinfoty);
procedure implementationend(const aunit: punitinfoty);

function eletodata(const aele: pelementinfoty): pointer; inline;
function datatoele(const adata: pointer): pelementinfoty; inline;

//todo: code unit sizes
function newbigintconst(const buffer: pointer;
                                    const bitsize: int32): stringvaluety;
function newstringconst(): stringvaluety; //save info.unitinfo^.stringbuffer
function newstringconst(const avalue: lstringty): stringvaluety;
function getstringconst(const astring: stringvaluety): lstringty;
function stringconstlen(const astring: stringvaluety): int32;
function ischarstringconst(const astring: stringvaluety;
                                 const aitemsize: int32): boolean;
procedure trackstringref(const astring: stringvaluety);
                    //can not been concatenated in place
procedure concatstringconsts(var dest: stringvaluety; const b: stringvaluety);
function allocstringconst(const astring: stringvaluety): segaddressty;
function allocstringconst(const astring: string): segaddressty;
function allocdataconst(const adata: openarrayvaluety): segaddressty;

var
 ele: telementhashdatalist;
 globllvmlists: tllvmlists;

implementation
uses
 msearrayutils,sysutils,typinfo,mseformatstr,
 mselinklist,msesysutils,opcode,handlerutils,unithandler,
 {internaltypes,}__mla__internaltypes,errorhandler,identutils,grammarglob;

const
 recursionmax = 1024;

function eletodata(const aele: pelementinfoty): pointer; inline;
begin
 result:= pointer(aele)+sizeof(elementheaderty);
end;

function datatoele(const adata: pointer): pelementinfoty; inline;
begin
 result:= adata-sizeof(elementheaderty);
end;
 
const
 mindatasize = 1024; 

type
 stringbufflagty = (sbf_referenced);   //can not been concateniated in place
 stringbufflagsty = set of stringbufflagty;
 
 stringbufdataty = record
  len: integer;
  offset: ptruint; //offset in fbuffer
  flags: stringbufflagsty;
  constoffset8,constoffset16,constoffset32: dataoffsty; 
                      //offset in constdata, -1 -> not assigned
 end;
 pstringbufdataty = ^stringbufdataty;
 stringbufhashdataty = record
  header: hashheaderty;
  data: stringbufdataty;
 end;
 pstringbufhashdataty = ^stringbufhashdataty;
 
 tstringbuffer = class(thashdatalist)
  private
   fbuffer: pointer;
   fbufsize: ptruint;
   fbufcapacity: ptruint;
  protected
   procedure initbuffer;
   function hashkey(const akey): hashvaluety; override;
   function checkkey(const akey; const aitem: phashdataty): boolean; override;
   function getrecordsize(): int32 override;
   function checkgrow(): boolean;
   function getbufpo(const astring: stringvaluety;
                          out datapo: pointer): pstringbufhashdataty;
  public
   constructor create;
   destructor destroy; override;
   procedure clear; override;
   procedure mark(out ref: stringbufmarkty);
   procedure release(const ref: stringbufmarkty);
   function add(const avalue: string): stringvaluety;
   function add(const avalue: lstringty): stringvaluety;
   function allocconst(const astring: stringvaluety): segaddressty;
   function getlength(const astring: stringvaluety): int32;
   function getstring(const astring: stringvaluety): lstringty;
   procedure trackstringref(const astring: stringvaluety);
                  //can not been concatenated in place
   procedure concatstringconsts(var dest: stringvaluety;
                                        const b: stringvaluety);
 end;
{
 elementhashdataty = record
  header: hashheaderty;
  data: elementdataty;
 end;
 pelementhashdataty = ^elementhashdataty;
}
var
 stringbuf: tstringbuffer; //used for monolythic compile
 
function allocdataconst(const adata: openarrayvaluety): segaddressty;
                                //overwrites seg_globconst
var
 i1: int32;
 p1,pe: pstringvaluety;
 p0,p2: pint32;
begin
{$ifdef mse_checkinternalerror}
 if adata.address.segment <> seg_globconst then begin
  internalerror(ie_handler,'20170614A');
 end;
{$endif}
 result:= adata.address;
 if adata.itemkind = dk_string then begin
  if co_llvm in info.o.compileoptions then begin
   p1:= getsegmentpo(result);
   p0:= pointer(p1);
   p2:= pointer(p1);
   pe:= pointer(p1) + adata.size;
   while p1 < pe do begin
    if strf_empty in p1^.flags then begin
     i1:= ord(nco_pointer);
    end
    else begin
     i1:= allocstringconst(p1^).address;
     i1:= info.s.unitinfo^.llvmlists.constlist.addaddress(
                                       i1,sizeof(stringheaderty)).listid;
    end;
    p2^:= i1;
    inc(p2);
    inc(p1);
   end;
   i1:= info.s.unitinfo^.llvmlists.constlist.addpointerarray(
                                             pe-pstringvaluety(p0),p0).listid;
   result.address:= info.s.unitinfo^.llvmlists.globlist.addinitvalue(
                                              gak_const,i1,info.s.globlinkage);
  end
  else begin
   notimplementederror('20180812A');
  end;
 end
 else begin
  if co_llvm in info.o.compileoptions then begin
   i1:= info.s.unitinfo^.llvmlists.constlist.addvalue(
                                  getsegmentpo(result)^,adata.size).listid;
   result.address:= info.s.unitinfo^.llvmlists.globlist.addinitvalue(
                                       gak_const,i1,info.s.globlinkage);
  end;
 end;
end;

function newbigintconst(const buffer: pointer;
                                const bitsize: int32): stringvaluety;
var
 ls1: lstringty;
begin
 ls1.po:= buffer;
 ls1.len:= (bitsize+7) div 8;
 result:= newstringconst(ls1);
end;

function newstringconst(): stringvaluety;
begin
 result:= tstringbuffer(info.s.unitinfo^.stringbuffer).add(info.stringbuffer);
end;

function newstringconst(const avalue: lstringty): stringvaluety;
begin
 result:= tstringbuffer(info.s.unitinfo^.stringbuffer).add(avalue);
end;

function getstringbuf(const avalue: stringvaluety): tstringbuffer;
begin
 if strf_ele in avalue.flags then begin
  result:= tstringbuffer(ele.eleinfoabs(avalue.offset)^.header.defunit^.
                                                               stringbuffer);
 end
 else begin
  result:= tstringbuffer(info.s.unitinfo^.stringbuffer)
 end;
end;

function getstringbuf(const aele: pelementinfoty): tstringbuffer;
begin
 result:= tstringbuffer(aele^.header.defunit^.stringbuffer);
end;

function allocstringconst(const astring: stringvaluety): segaddressty;
begin
 result:= getstringbuf(astring).allocconst(astring);
end;

function allocstringconst(const astring: string): segaddressty;
var
 sv1: stringvaluety;
begin
 sv1:= newstringconst(stringtolstring(astring));
 result:= allocstringconst(sv1);
end;

function getstringconst(const astring: stringvaluety): lstringty;
begin
 result:= getstringbuf(astring).getstring(astring);
end;

function stringconstlen(const astring: stringvaluety): int32;
begin
 result:= getstringbuf(astring).getlength(astring);
end;

const
 errorcodepoint = $3f; //?

procedure getcodepoint(var ps: pcard8; const pe: pcard8;
                                  out ares: card32);
 function checkok(var acodepoint: card32): boolean; //inline;
 var
  c1: card8;
 begin
  result:= false;
  inc(ps);
  if ps >= pe then begin
   acodepoint:= errorcodepoint;
  end
  else begin
   c1:= ps^ - %10000000;
   if c1 > %00111111 then begin
    acodepoint:= errorcodepoint;
   end
   else begin
    acodepoint:= (acodepoint shl 6) or c1;
    result:= true;
   end;
  end;
 end;

begin
 if ps^ < %10000000 then begin  //1 byte
  ares:= ps^;
 end
 else begin
  if ps^ <= %11100000 then begin //2 bytes
   ares:= ps^ and %00011111;
   if checkok(ares) then begin
    if ares < %1000000 then begin
     ares:= errorcodepoint; //overlong
    end;
   end;
  end
  else begin
   if ps^ < %11110000 then begin //3 bytes
    ares:= ps^ and %00001111;
    if checkok(ares) and checkok(ares) then begin
     if ares < %100000000000 then begin
      ares:= errorcodepoint; //overlong
     end;
    end;
   end
   else begin
    if ps^ < %11111000 then begin //4 bytes
     ares:= ps^ and %00000111;
     if checkok(ares) and checkok(ares) and checkok(ares) then begin
      if ares < %10000000000000000 then begin
       ares:= errorcodepoint; //overlong
      end;
     end;
    end
    else begin
     ares:= errorcodepoint;
    end;
   end;
  end;
 end;
 inc(ps);
 if (ares >= $d800) and (ares <= $dfff) then begin
  ares:= errorcodepoint; //surrogate
 end;
end;

function ischarstringconst(const astring: stringvaluety;
                                 const aitemsize: int32): boolean;
var
 ls1: lstringty;
 c1: card32;
begin
 result:= false;
 ls1:= getstringbuf(astring).getstring(astring);
 if ls1.len > 0 then begin
  getcodepoint(pointer(ls1.po),pointer(ls1.po)+ls1.len,c1);
  case aitemsize of
   1: begin
    result:= c1 < 128;
   end;
   2: begin
    result:= c1 < $10000;
   end;
   4: begin
    result:= true;
   end;
  end;
 end;
end;

procedure trackstringref(const astring: stringvaluety);
                    //can not been concatenated in place
begin
 getstringbuf(astring).trackstringref(astring);
end;

procedure concatstringconsts(var dest: stringvaluety; const b: stringvaluety);
begin
 tstringbuffer(info.s.unitinfo^.stringbuffer).concatstringconsts(dest,b);
end;

function telementhashdatalist.elebase: pointer; inline;
begin
 result:= pointer(felementdata);
end;

function telementhashdatalist.eledatabase: pointer;
begin
 result:= pointer(felementdata) + eledatashift;
end;

function telementhashdatalist.eleoffset: ptruint; inline;
begin
 result:= ptruint(felementdata);
end;

function telementhashdatalist.eledataoffset: ptruint; inline;
begin
 result:= ptruint(felementdata) + eledatashift;
end;

function telementhashdatalist.eleinforel(
                          const aelement: pelementinfoty): elementoffsetty;
begin
 result:= aelement-pointer(felementdata);
end;

function telementhashdatalist.eleinfoabs(
                    const aelement: elementoffsetty): pelementinfoty; inline;
begin
 result:= aelement+pointer(felementdata);
end;

function telementhashdatalist.eledatarel(
                    const aelement: pointer): elementoffsetty; inline;
begin
 result:= aelement-pointer(felementdata)-eledatashift;
end;

function telementhashdatalist.basetype(
              const aelement: elementoffsetty): ptypedataty;
begin
 result:= eledataabs(aelement);
{$ifdef mse_checkinternalerror}
 if datatoele(result)^.header.kind <> ek_type then begin
  internalerror(ie_elements,'20160525A');
 end;
{$endif}
 if result^.h.base > 0 then begin
  result:= ele.eledataabs(result^.h.base);
 end;
end;

function telementhashdatalist.eledataabs(
                           const aelement: elementoffsetty): pointer; inline;
begin
 result:= aelement+pointer(felementdata)+eledatashift;
end;

function telementhashdatalist.parentdata: pointer;
begin
 result:= pointer(felementdata)+felementparent+eledatashift;
end;

function telementhashdatalist.parentelement: pelementinfoty;
begin
 result:= pointer(felementdata)+felementparent;
end;

type
 dumpinfoty = record
  text: msestring;
  offset: elementoffsetty;
  parent: elementoffsetty;
  parents: array[0..255] of elementoffsetty;
  parentlevel: integer;
 end;
 dumpinfoarty = array of dumpinfoty;

function compdump(const l,r): integer;
var
 int1: integer;
 int2: integer;
 levell,levelr: integer;
begin
 result:= 0;
 levell:= dumpinfoty(l).parentlevel;
 levelr:= dumpinfoty(r).parentlevel;
 int1:= levell;
 if int1 > levelr then begin
  int1:= levelr;
 end;
 int2:= int1;
 for int1:= 0 to int2 do begin
  result:= dumpinfoty(l).parents[int1]-dumpinfoty(r).parents[int1];
  if result <> 0 then begin
   break;
  end;
 end;
 if result = 0 then begin
  if levell > levelr then begin
   result:= dumpinfoty(l).parents[int2+1]-dumpinfoty(r).offset;
  end
  else begin
   if levelr > levell then begin
    result:= dumpinfoty(l).parents[int2+1]-dumpinfoty(r).offset;
   end;
  end;
 end;
end;

procedure clear1();
begin
 ele.clear;
 freeandnil(stringbuf); //possibly used for monolyhic compile
// stringbuf.clear;
 globllvmlists.clear();
end;

procedure clear;
begin
 clear1();
 identutils.clear();
end;

procedure init;
var
 int1: integer;
 tk1: integer;
begin
 identutils.clear();
 identutils.init(); //first because of id init
 for tk1:= 1 to high(tokens) do begin
  getident(tokens[tk1]);
 end;
 clear1();
 info.rootelement:= ele.eleinforel(ele.pushelement(tks_rootele,ek_none,[]));
end;

function alignsize(const asize: int32): int32; inline;
begin
 result:= (asize+3) and not 3;
end;

{ telementhashdatalist }

constructor telementhashdatalist.create();
begin
// ffindvislevel:= nonevisi;
// inherited create(sizeof(elementdataty));
 inherited;
 clear();
end;

function telementhashdatalist.getrecordsize: int32;
begin
 result:= sizeof(elementhashdataty);
end;

procedure telementhashdatalist.clear();
var
 int1: integer;
begin
 inherited;
 fnextelement:= 0;
 felementlen:= 0;
 felementparent:= 0;
 felementpath:= 0;
 fparentlevel:= 0;
 if hls_destroying in fstate then begin
  if fscopes <> nil then begin
   freemem(fscopes);
   fscopes:= nil;
  end;
 end
 else begin
  reallocmem(fscopes,16*sizeof(fscopes));
 end;
 fscopespo:= nil;
 fscopestack:= nil;
 fscopestackpo:= -1;
 fscopestacksize:= 0;
 fparentindex:= 0;
end;

function telementhashdatalist.hashkey(const akey): hashvaluety;
begin
 result:= elementdataty(akey).key;
end;

function telementhashdatalist.checkkey(const akey;
                                    const aitem: phashdataty): boolean;
begin
 result:= identty(akey) = pelementhashdataty(aitem)^.data.key;
end;

procedure telementhashdatalist.addelement(const aident: identty;
               const avislevel: visikindsty; const aelement: elementoffsetty);
begin
// with pelementhashdataty(internaladdhash(scramble1(aident)))^.data do begin
 with pelementhashdataty(internaladdhash(aident))^.data do begin
  key:= aident;
  data:= aelement;
 end;
end;

procedure telementhashdatalist.enterbufferitem(const adata: pelementinfoty);
var
 id1: identty;
begin
 id1:= adata^.header.path+adata^.header.name;
 with pelementhashdataty(internaladdhash(id1))^.data do begin
  key:= id1;
  data:= eleinforel(adata);
 end;
end;

function telementhashdatalist.forallcurrent(const aident: identty;
                 const akinds: elementkindsty;
                 const avislevel: visikindsty; const ahandler: elehandlerprocty;
                 var adata): boolean; //returns terminated flag
var
 uint1: ptruint;
 po1: pelementhashdataty;
 po2: pelementinfoty;
 id1: identty;
begin
 result:= false;
 if count > 0 then begin
  id1:= felementpath+aident;
  uint1:= fhashtable[id1 and fmask];
  if uint1 <> 0 then begin
   po1:= pelementhashdataty(pchar(fdata) + uint1);
   while not result do begin
    if (po1^.data.key = id1) then begin
     po2:= pelementinfoty(pointer(felementdata)+po1^.data.data);
     with po2^.header do begin
      if (name = aident) and (parent = felementparent) and 
             ((visibility * avislevel <> []) or 
          (vik_sameunit in visibility) and (defunit = info.s.unitinfo)) and 
                                ((akinds = []) or (kind in akinds)) then begin
       ahandler(po2,adata,result);
      end;
     end;
    end;
    if po1^.header.nexthash = 0 then begin
     exit;
    end;
    po1:= pelementhashdataty(pchar(fdata) + po1^.header.nexthash);
   end;
  end;
 end;
end;

function telementhashdatalist.forallancestor(const aident: identty;
                 const akinds: elementkindsty;
                 const avislevel: visikindsty; const ahandler: elehandlerprocty;
                 var adata): boolean; //returns terminated flag
var
 po1: pelementinfoty;
 po2: ptypedataty;
 parentbefore: elementoffsetty;
begin
 result:= false;
 po1:= eleinfoabs(felementparent);
 if (po1^.header.kind = ek_type) then begin
  po2:= @po1^.data;
  if po2^.h.kind in ancestordatakinds then begin
   parentbefore:= elementparent;
   while not result and (po2^.h.ancestor <> 0) do begin
    elementparent:= po2^.h.ancestor;
    po2:= eledataabs(po2^.h.ancestor);
    result:= forallcurrent(aident,akinds,avislevel,ahandler,adata);
   end;
   elementparent:= parentbefore;
  end;
 end;
end;

function telementhashdatalist.checkancestor(var aele: elementoffsetty;
                                        var avislevel: visikindsty): boolean;
begin
 result:= false;
 if vik_ancestor in avislevel then begin
  with pelementinfoty(pointer(felementdata)+aele)^ do begin
   if header.kind = ek_type then begin
    with ptypedataty(@data)^ do begin
     if h.kind in ancestordatakinds then begin
      aele:= h.ancestor;
      result:= aele <> 0;
      include(avislevel,vik_descendent);
     end
     else begin
      if h.kind in ancestorchaindatakinds then begin
       internalerror1(ie_elements,'20150425A');
         //todo
      end;
     end;
    end;
   end;
  end;
 end;
end;

function telementhashdatalist.findcurrent(const aident: identty;
              const akinds: elementkindsty; avislevel: visikindsty;
                                        out element: elementoffsetty): boolean;
var
 uint1: ptruint;
 po1: pelementhashdataty;
 po2: pelementinfoty;
 id1: identty;
 int1,int2: integer;
 parentele: elementoffsetty;
 classdescend: elementoffsetty;
 elepath: identty;
 recursioncount: int32;
label
 endlab;
begin
 element:= -1;
 result:= false;
 if count > 0 then begin
  classdescend:= 0;
  parentele:= felementparent;
  elepath:= felementpath;
  recursioncount:= recursionmax;
  while true do begin
   id1:= elepath+aident;
   uint1:= fhashtable[id1 and fmask];
   if uint1 <> 0 then begin
    po1:= pelementhashdataty(pchar(fdata) + uint1);
    while true do begin
     if (po1^.data.key = id1) then begin
      po2:= pelementinfoty(pointer(felementdata)+po1^.data.data);
      if (po2^.header.name = aident) and 
                 (po2^.header.parent = parentele) then begin
       if po2^.header.kind = ek_alias then begin
        po2:= pointer(felementdata) + paliasdataty(@po2^.data)^.base;
       end;
       with po2^.header do begin
        if ((avislevel = []) or (visibility * avislevel <> []) or 
          (vik_sameunit in visibility) and (defunit = info.s.unitinfo)) and 
                           ((akinds = []) or (kind in akinds)) then begin
         element:= pointer(po2) - pointer(felementdata);
         goto endlab;
        end;
       end;
      end;
     end;
     if po1^.header.nexthash = 0 then begin
      break;
     end;
     po1:= pelementhashdataty(pchar(fdata) + po1^.header.nexthash);
    end;
   end;
   if vik_ancestor in avislevel then begin
    with eleinfoabs(parentele)^ do begin
     if (header.kind = ek_type) and 
            (ptypedataty(@data)^.h.kind in [dk_object,dk_class]) then begin
      if classdescend = 0 then begin
       classdescend:= parentele;
      end;
      parentele:= ptypedataty(@data)^.h.ancestor;
      if parentele <> 0 then begin
       with eleinfoabs(parentele)^ do begin
        elepath:= header.path+header.name;
       end;
       include(avislevel,vik_descendent);
       dec(recursioncount);
       if recursioncount <= 0 then begin
        errormessage(err_recursiveancestor,[getidentname(aident)]);
        break;
       end;
       continue;
      end;
     end;
    end;
   end;
   break;
  end;
 end;
endlab:
 result:= element >= 0;
 if result then begin
  flastdescendent:= classdescend;
 end;
end;

function telementhashdatalist.findcurrent(const aident: identty;
             const akinds: elementkindsty;
             avislevel: visikindsty; out adata: pointer): elementkindty;
var
 ele1: elementoffsetty;
 po1: pelementinfoty;
begin
 result:= ek_none;
 if findcurrent(aident,akinds,avislevel,ele1) then begin
  po1:= eleinfoabs(ele1);
  result:= po1^.header.kind;
  adata:= @po1^.data;
 end;
end;

function telementhashdatalist.findupward(const aident: identty;
      const akinds: elementkindsty;
      const avislevel: visikindsty; out element: elementoffsetty): visikindsty;
var
 parentbefore: elementoffsetty;
 pathbefore: identty;
 p1: pelementinfoty;
label
 endlab;
begin
 parentbefore:= felementparent;
 pathbefore:= felementpath;
 result:= [];
 while true do begin
  p1:= pelementinfoty(pointer(felementdata)+felementparent);
//  result:= result + p1^.header.visibility;
  result:= p1^.header.visibility;
  if p1^.header.name = aident then begin
   element:= pointer(p1)-pointer(felementdata);
   include(result,vik_found);
   exclude(result,vik_nochildren);
   break;
  end;
  if findcurrent(aident,akinds,avislevel,element) then begin
   include(result,vik_found);
   break;
  end;
  with p1^.header do begin    
   if path = 0 then begin
    result:= [];
    break;
   end;
  {$ifdef mse_checkinternalerror}
   if felementparent = 0 then begin
    internalerror(ie_elements,'20150503A');
   end;
  {$endif}
   felementpath:= felementpath-name;
   felementparent:= parent;
  end;
 end;
endlab:
 felementparent:= parentbefore;
 felementpath:= pathbefore;
end;

function telementhashdatalist.findupward(const aidents: identvecty;
              const akinds: elementkindsty; const avislevel: visikindsty;
              out element: elementoffsetty;
              out firstnotfound: integer; const start: int32 = 0): visikindsty;
var
 parentbefore: elementoffsetty;
 pathbefore: identty;
 ele1: elementoffsetty;
 po1: pelementinfoty;
 b1: boolean;
 k1: elementkindsty;
begin //todo: optimize
 result:= [];
 element:= -1;
 firstnotfound:= 0;
 if aidents.high >= start then begin
  k1:= [];
  if aidents.high = 0 then begin
   k1:= akinds;
  end;
  result:= findupward(aidents.d[start],k1,avislevel,element);
  if result <> [] then begin
   firstnotfound:= start+1;
   if (aidents.high > start) and not (vik_nochildren in result) then begin
    parentbefore:= felementparent;
    pathbefore:= felementpath;
    po1:= pointer(felementdata)+element;
    with po1^.header do begin
     if kind = ek_uses then begin
      element:= pusesdataty(pointer(po1)+eledatashift)^.ref;
     end;
    end;
    felementparent:= element; //parentlevel
    with pelementinfoty(pointer(felementdata)+element)^.header do begin
     felementpath:= path + name;
    end;
    b1:= false;
    while true do begin
     if vik_stoponstarttype in avislevel then begin
      po1:= pointer(felementdata)+element;
      with po1^.header do begin
       if not b1 then begin
        if kind = ek_type then begin
         break;
        end;
        if kind = ek_var then begin
         b1:= true;
        end;
       end;
      end;
     end;
     if not findcurrent(aidents.d[firstnotfound],[],allvisi,ele1) then begin
      break;
     end;
     element:= ele1;
     felementparent:= ele1;
     felementpath:= felementpath+aidents.d[firstnotfound];
     inc(firstnotfound);
     if firstnotfound > aidents.high then begin
      break;
     end;
    end;
    felementparent:= parentbefore;
    felementpath:= pathbefore;
   end;
  end;
 end;
end;

function telementhashdatalist.findreverse(const alen: int32;
               const aids: pidentty; out element: elementoffsetty): boolean;
var
 po1,pe: pidentty;
 h1: hashvaluety;
 lca1: ptruint;
 po2: pelementhashdataty;
 po3,po4: pelementinfoty;
label
 nextlab;
begin
 h1:= 0;
 po1:= aids;
 pe:= po1 + alen;
 while po1 < pe do begin
  h1:= h1 + po1^;
  inc(po1);
 end;
 lca1:= fhashtable[h1 and fmask];
 if lca1 <> 0 then begin
  po2:= fdata + lca1;
  while true do begin
   if (po2^.data.key = h1) then begin
    po3:= pointer(felementdata)+po2^.data.data;
    po4:= po3;
    po1:= aids;
    while po1 < pe do begin
     with po3^.header do begin
      if name <> po1^ then begin
       goto nextlab;
      end;
      inc(po1);
      if (parentlevel = 0) and (po1 = pe) then begin
       element:= eleinforel(po4);
       result:= true;
       exit;
      end;
      po3:= pointer(felementdata)+parent;
     end;
    end;
   end;
nextlab:
   if po2^.header.nexthash = 0 then begin
    break;
   end;
   po2:= pelementhashdataty(fdata + po2^.header.nexthash);
  end;
 end;
 result:= false;
 element:= -1;
end;

(*
function telementhashdatalist.findupward(const aidents: identvecty;
              const akinds: elementkindsty; const avislevel: visikindsty;
              out element: elementoffsetty;
              out lastident: integer): boolean;
//todo: optimize
var
 parentbefore: elementoffsetty;
 pathbefore: identty;
 path1: identty;
 id1: identty;
 uint1: ptruint;
 po1: pelementhashdataty;
 po2: pelementinfoty;
 hash1: hashvaluety;
 int1: integer;
 first: elementoffsetty;
begin
 result:= false;
 element:= -1;
 lastident:= aidents.high;
 if aidents.high >= 0 then begin
  if aidents.high = 0 then begin
   result:= findupward(aidents.d[0],akinds,avislevel,element);
  end
  else begin
   path1:= aidents.d[0];
   for int1:= 1 to aidents.high do begin
    if aidents.d[int1] = 0 then begin
     break;
    end;
    path1:= path1 + aidents.d[int1];
   end;
   parentbefore:= felementparent;
   pathbefore:= felementpath;
   while true do begin
    if not findupward(aidents.d[0],[],avislevel,first) then begin //find root
     break; //not found
    end;
    with pelementinfoty(pointer(felementdata)+first)^.header do begin
     felementparent:= parent;
     felementpath:= path;
    end;
    repeat
     id1:= felementpath+path1; //complete path
     uint1:= fhashtable[id1 and fmask];
     if uint1 <> 0 then begin //there are candidates
      po1:= pelementhashdataty(pchar(fdata) + uint1);
      while true do begin
       if (po1^.data.key = id1) then begin
        element:= po1^.data.data;
        po2:= pelementinfoty(pointer(felementdata)+element);
        if (akinds = []) or (po2^.header.kind in akinds) then begin
         for int1:= lastident downto 1 do begin //check ancestor chain
          if po2^.header.name <> aidents.d[int1] then begin
           element:= -1; //ancestoor chain broken
           break;
          end;
          po2:= pointer(felementdata)+po2^.header.parent;
         end;
         if (element >= 0) and (po2^.header.parent = felementparent) then begin
          result:= true;
          break; //ancestor chain ok
         end;
        end
        else begin
         element:= -1;
        end;
       end;
       if po1^.header.nexthash = 0 then begin
        break; //not found
       end;
       po1:= pelementhashdataty(pchar(fdata) + po1^.header.nexthash);
      end;
     end
     else begin
      element:= -1;
     end;
     if result then begin
      break; //found
     end;
     path1:= path1 - aidents.d[lastident];
     dec(lastident);
    until (akinds = []) or (lastident < 0);
    if result or (felementparent = 0) then begin
     break;
    end;
    with pelementinfoty(pointer(felementdata)+felementparent)^.header do begin
     felementparent:= parent; //parentlevel
     felementpath:= path;
    end;
   end;
   felementparent:= parentbefore;
   felementpath:= pathbefore;
  end;
 end;
end;
*)
{
function telementhashdatalist.findchild(const aparent: elementoffsetty; 
           const achild: identty; const akinds: elementkindsty;
           const avislevel: visikindsty; out element: elementoffsetty): boolean;
//todo: optimize
var 
 ele1: elementoffsetty;
begin
 ele1:= elementparent;
 elementparent:= aparent;
 result:= findcurrent(achild,akinds,avislevel,element);
 elementparent:= ele1;
end;
}
function telementhashdatalist.findchild(aparent: elementoffsetty;
               const achildtree: pidentty; const ahigh: int32; 
               const akinds: elementkindsty;
               avislevel: visikindsty; out element: elementoffsetty): boolean;
var
 int1: integer;
 id1: identty;
 uint1: ptruint;
 po1: pelementhashdataty;
 po2,po3: pelementinfoty;
label
 next;
begin
 result:= false;
 if ahigh >= 0 then begin
  repeat
   with pelementinfoty(pointer(felementdata)+aparent)^ do begin
    id1:= header.path + header.name;
   end;
   for int1:= 0 to ahigh do begin
    id1:= id1 + achildtree[int1];
   end;
   uint1:= fhashtable[id1 and fmask];
   if uint1 <> 0 then begin
    po1:= pelementhashdataty(pchar(fdata) + uint1);
    while true do begin
     if po1^.data.key = id1 then begin
      po2:= pelementinfoty(pointer(felementdata)+po1^.data.data);
      if po2^.header.kind = ek_alias then begin
       po2:= pointer(felementdata) + paliasdataty(@po2^.data)^.base;
      end;
      po3:= po2; //searched child
      for int1:= ahigh downto 0 do begin
       if (po2^.header.name <> achildtree[int1]) or 
              (po2^.header.visibility*avislevel = []) then begin
        goto next;
       end;
       po2:= pointer(felementdata)+po2^.header.parent;
      end;
      if (pointer(po2)-pointer(felementdata) = aparent) then begin
       element:= po1^.data.data;
       result:= (akinds = []) or (po3^.header.kind in akinds);
       exit;
      end;
     end;
 next:
     if po1^.header.nexthash = 0 then begin
      break;
     end;
     po1:= pelementhashdataty(pchar(fdata) + po1^.header.nexthash);
    end;
   end;
  until not checkancestor(aparent,avislevel);
 end;
end;

function telementhashdatalist.findchild(aparent: elementoffsetty;
               const achildtree: identvecty; const akinds: elementkindsty;
               avislevel: visikindsty; out element: elementoffsetty): boolean;
begin
 result:= findchild(aparent,@achildtree.d[0],achildtree.high,
                                                  akinds,avislevel,element);
end;

function telementhashdatalist.findchild(aparent: elementoffsetty; 
                 const achildtree: array of identty;
                 const akinds: elementkindsty;
                 avislevel: visikindsty;
                               out element: elementoffsetty): boolean;
begin
 result:= findchild(aparent,@achildtree[0],high(achildtree),
                                                akinds,avislevel,element);
end;

function telementhashdatalist.findchilddata(const aparent: elementoffsetty;
               const achildtree: pidentty; const ahigh: int32;
               const akinds: elementkindsty;
               const avislevel: visikindsty; out adata: pointer): boolean;
var
 ele1: elementoffsetty;
begin
 adata:= nil;
 result:= findchild(aparent,achildtree,ahigh,akinds,avislevel,ele1);
 if result then begin
  adata:= ele1+pointer(felementdata)+eledatashift;
 end;
end;

function telementhashdatalist.findchilddata(const aparent: elementoffsetty;
               const achildtree: identvecty; const akinds: elementkindsty;
               const avislevel: visikindsty; out adata: pointer): boolean;
begin
 result:= findchilddata(aparent,@achildtree.d[0],achildtree.high,
                                                   akinds,avislevel,adata);
end;

function telementhashdatalist.findchilddata(const aparent: elementoffsetty; 
                 const achildtree: array of identty;
                 const akinds: elementkindsty;
                 const avislevel: visikindsty;
                               out adata: pointer): boolean;
begin
 result:= findchilddata(aparent,@achildtree[0],high(achildtree),
                                                   akinds,avislevel,adata);
end;

function telementhashdatalist.findchild(aparent: elementoffsetty; 
                 const achild: identty;
                 const akinds: elementkindsty;
                 avislevel: visikindsty;
                               out element: elementoffsetty): boolean;
var
 int1: integer;
 id1: identty;
 uint1: ptruint;
 po1: pelementhashdataty;
 po2,po3: pelementinfoty;
 recursioncount: int32;
 vis1: visikindsty;
label
 next;
begin
 result:= false;
 recursioncount:= recursionmax;
 repeat
  with pelementinfoty(pointer(felementdata)+aparent)^ do begin
   id1:= header.path + header.name + achild;
  end;
  uint1:= fhashtable[id1 and fmask];
  if uint1 <> 0 then begin
   po1:= pelementhashdataty(pchar(fdata) + uint1);
   while true do begin
    if po1^.data.key = id1 then begin
     po2:= pelementinfoty(pointer(felementdata)+po1^.data.data);
     if (po2^.header.name <> achild) or 
                           (po2^.header.parent <> aparent) then begin
      goto next;
     end;
     if po2^.header.kind = ek_alias then begin
      element:= paliasdataty(@po2^.data)^.base;
      po2:= pointer(felementdata) + element;
     end
     else begin
      element:= po1^.data.data;
     end;
     vis1:= po2^.header.visibility*avislevel;
     if po2^.header.defunit <> info.s.unitinfo then begin
      exclude(vis1,vik_sameunit);
     end;
     result:= (vis1 <> []) and
                 ((akinds = []) or (po2^.header.kind in akinds));
     exit;
    end;
next:
    if po1^.header.nexthash = 0 then begin
     break;
    end;
    po1:= pelementhashdataty(pchar(fdata) + po1^.header.nexthash);
   end;
  end;
  dec(recursioncount);
  if recursioncount <= 0 then begin
   errormessage(err_recursiveancestor,[getidentname(achild)],minint,0,erl_fatal);
   exit;
  end;
 until not checkancestor(aparent,avislevel);
end;

function telementhashdatalist.findchilddata(const aparent: elementoffsetty; 
                 const achild: identty; const akinds: elementkindsty;
                 const avislevel: visikindsty;
                               out adata: pointer): boolean;
var
 ele1: elementoffsetty;
begin
 adata:= nil;
 result:= findchild(aparent,achild,akinds,avislevel,ele1);
 if result then begin
  adata:= ele1+pointer(felementdata)+eledatashift;
 end;
end;

function telementhashdatalist.findchild(const aparent: elementoffsetty;
                 const achild: identty; const akinds: elementkindsty;
                 const avislevel: visikindsty; 
               out element: elementoffsetty; out adata: pointer): elementkindty;
begin
 result:= ek_none;
 adata:= nil;
 if findchild(aparent,achild,akinds,avislevel,element) then begin
  adata:= element+pointer(felementdata)+eledatashift;
  result:= pelementinfoty(adata-eledatashift)^.header.kind;
 end;
end;

{
function telementhashdatalist.findchild(const aparent: elementoffsetty; 
                 const achild: identty; const avislevel: visikindsty; 
               out element: elementoffsetty; out adata: pointer): elementkindty;
var 
 ele1: elementoffsetty;
begin
 ele1:= elementparent;
 elementparent:= aparent;
 if findcurrent(achild,[],avislevel,element) then begin
  adata:= eleinfoabs(element);
  result:= pelementinfoty(adata)^.header.kind;
  inc(adata,eledatashift);
 end
 else begin
  result:= ek_none;
  adata:= nil;
 end;
 elementparent:= ele1;
end;
}

function telementhashdatalist.hasscope(const aname: identty): boolean;
var
 p1: pscopeinfoty;
begin
 result:= false;
 p1:= fscopespo;
 if p1 <> nil then begin
  while p1 >= fscopes do begin
   if p1^.name = aname then begin
    result:= true;
    break;
   end;
   dec(p1);
  end;
 end;
end;

function telementhashdatalist.findparentscope(const aident: identty;
               const akinds: elementkindsty; const avislevel: visikindsty;
               out aparent: elementoffsetty; out anamed: boolean): boolean;
var
 uint1: ptruint;
 po1: pelementhashdataty;
 po2: pelementinfoty;
 po3: pscopeinfoty;
 id1: identty;
label
 endloop;
begin
 result:= false;
 anamed:= false;
 if (fscopespo <> nil) and (count > 0) then begin // check "with" and the like 
  po3:= fscopespo;
  while true do begin
   if po3^.name <> 0 then begin
    if po3^.name = aident then begin
     aparent:= po3^.element;
     result:= true;
     anamed:= true;
     exit;
    end;
   end
   else begin
    with pelementinfoty(pointer(felementdata)+po3^.childparent)^ do begin
     id1:= header.path+header.name+aident;
     uint1:= fhashtable[id1 and fmask];
     if uint1 <> 0 then begin
      po1:= pelementhashdataty(pchar(fdata) + uint1);
      while true do begin
       if (po1^.data.key = id1) then begin
        with pelementinfoty(
               pointer(felementdata)+po1^.data.data)^.header do begin    //child
         if (name = aident) and (parent = po3^.childparent) then begin
          po2:= pelementinfoty(pointer(felementdata) + po3^.childparent);//parent
          if po2^.header.kind = ek_alias then begin
           po2:= pointer(felementdata) + paliasdataty(@po2^.data)^.base;
          end;
          with po2^.header do begin 
           if ((visibility * avislevel <> [])  or 
           (vik_sameunit in visibility) and (defunit = info.s.unitinfo)) and 
                              ((akinds = []) or (kind in akinds)) then begin
            aparent:= po3^.element;
            result:= true;
            exit;
           end;
          end;
         end;
        end;
       end;
       if po1^.header.nexthash = 0 then begin
        goto endloop; //not found
       end;
       po1:= pelementhashdataty(pchar(fdata) + po1^.header.nexthash);
      end;
     end;
    end;
   end;
endloop:
   if po3 = fscopes then begin
    break;
   end;
   dec(po3);
  end; 
 end;
end;

{$ifdef mse_debugparser}
function telementhashdatalist.dumpelements: msestringarty;

var
 po1: pelementinfoty;
 
 function getidentstring(const ident: identty): msestring;
 begin
  if ident = 0 then begin
   result:= '''''';
  end
  else begin
   result:= ''''+msestring(getidentname(ident))+'''';
  end;
 end;
 
 function dumptyp(const atyp: elementoffsetty): msestring;
 var
  po2: pelementinfoty;
  cami,cama: card64;
  intmi,intma: int64;
 begin
  if atyp < 0 then begin
   result:= ' T:invalid';
  end
  else begin
   po2:= eleinfoabs(atyp);
   with ptypedataty(@po2^.data)^ do begin
    result:= ' T:'+inttostrmse(atyp)+':S'+inttostrmse(h.signature)+':N'+
                         inttostrmse(po2^.header.name)+':'+
                         msestring(getidentname(po2^.header.name));
    result:= result+' B:'+inttostrmse(h.base);
    result:= result+' K:'+msestring(getenumname(typeinfo(h.kind),ord(h.kind)));
    if h.kind = dk_string then begin
     result:= result+inttostrmse(itemsize*8);
    end;
    if h.kind <> dk_none then begin
     result:= result+
     ' F:'+msestring(
           settostring(ptypeinfo(typeinfo(h.flags)),integer(h.flags),true))+
     ' D:'+msestring(getenumname(typeinfo(h.datasize),ord(h.datasize)))+
     ' S:'+inttostrmse(h.bytesize)+' I:'+inttostrmse(h.indirectlevel);
     case h.kind of
      dk_cardinal: begin
       case h.datasize of
        das_1,das_2_7,das_8: begin
         cami:= infocard8.min;
         cama:= infocard8.max;
        end;
        das_9_15,das_16:  begin
         cami:= infocard16.min;
         cama:= infocard16.max;
        end;
        das_17_31,das_32:  begin
         cami:= infocard32.min;
         cama:= infocard32.max;
        end;
        das_33_63,das_64:  begin
         cami:= infocard64.min;
         cama:= infocard64.max;
        end;
       end;
       result:= result+' MI:'+inttostrmse(cami)+' MA:'+inttostrmse(cama);
      end;
      dk_integer: begin
       case h.datasize of
        das_1,das_2_7,das_8: begin
         intmi:= infoint8.min;
         intma:= infoint8.max;
        end;
        das_9_15,das_16:  begin
         intmi:= infoint16.min;
         intma:= infoint16.max;
        end;
        das_17_31,das_32:  begin
         intmi:= infoint32.min;
         intma:= infoint32.max;
        end;
        das_33_63,das_64:  begin
         intmi:= infoint64.min;
         intma:= infoint64.max;
        end;
       end;
       result:= result+' MI:'+inttostrmse(intmi)+' MA:'+inttostrmse(intma);
      end;
      dk_enum: begin
       result:= result+' first:'+inttostrmse(infoenum.first)+
                       ' last:'+inttostrmse(infoenum.last)+
                       ' itemcount:'+inttostrmse(infoenum.itemcount)+
                     ' flags:'+msestring(settostring(
                                        ptypeinfo(typeinfo(infoenum.flags)),
                                                integer(infoenum.flags),true));
                       
      end;
      dk_enumitem: begin
       result:= result+' value:'+inttostrmse(infoenumitem.value)+
                       ' enum:'+inttostrmse(infoenumitem.enum)+
                       ' next:'+inttostrmse(infoenumitem.next);
      end;
      dk_set: begin
       result:= result+' itemtyp:'+inttostrmse(infoset.itemtype);
      end;
      dk_interface: begin
       result:= result+' subco:'+inttostrmse(infointerface.subcount);
      end;
      dk_sub,dk_method: begin
       result:= result+' sub:'+inttostrmse(infosub.sub);
      end;
      dk_array: begin
       with infoarray do begin
        result:= result+' index:'+inttostrmse(indextypedata)+
                    ' itemtype:'+inttostrmse(i.itemtypedata)+
                           ' I:'+inttostrmse(i.itemindirectlevel);
                        
       end;
      end;
      dk_classof: begin
       with infoclassof do begin
        result:= result + ' cla:'+inttostrmse(classtyp);
       end;
      end;
     end;
    end;
   end;
  end;
 end; //dumptyp

 function dumpconstvalue(const avalue: dataty): msestring;
 begin
  with avalue do begin
   result:= msestring(getenumname(typeinfo(kind),ord(kind)))+' ';
   case kind of
    dk_boolean: begin
     result:= result + msestring(booltostr(vboolean));
    end;
    dk_integer: begin
     result:= result + inttostrmse(vinteger);
    end;
    dk_cardinal: begin
     result:= result + inttostrmse(vcardinal);
    end;
    dk_float: begin
     result:= result + realtostrmse(vfloat);
    end;
    dk_address: begin
     result:= result + inttostrmse(vaddress.poaddress);
    end;
    dk_enum: begin
     result:= result + inttostrmse(venum.value);
    end;
    dk_set: begin
     if vset.kind = das_bigint then begin
      if strf_ele in vset.bigsetvalue.flags then begin
       result:= result+'bigint ele:'
      end
      else begin
       result:= result+'bigint:';
      end;
      result:= result+inttostr(vset.bigsetvalue.offset);
     end
     else begin
      result:= result + hextostrmse(card32(vset.setvalue)); 
               //todo: arbitrary size, set format
     end;
    end;
    dk_string{8,dk_string16,dk_string32}: begin
     if not (strf_ele in vstring.flags) then begin
      result:= result + lstringtostring(getstringbuf(po1).getstring(vstring));
     end
     else begin
     {
     if (data <> nil) and (data^.nameid >= 0) then begin
      include(strval1.flags,strf_ele);
      strval1.offset:= eledatarel(data);
     end;
     }
      result:= result + msestring(lstringtostring(getstringconst(vstring)));
     end;
    end;
   end;
  end;
 end;

 function dumpconst(const avalue: datainfoty): msestring;
 begin
  with avalue do begin
   result:= ' T:'+inttostrmse(typ.typedata)+' '+dumpconstvalue(d);
  end; 
 end; //dumpconst
  
var
 int1,int2,int3,int4,int5,int6: integer;
 po2,po3: pelementinfoty;
 mstr1,mstr2: msestring;
 ar1: dumpinfoarty;
 off1: elementoffsetty;
 ar2: msestringarty;
 po4: pscopeinfoty;
 po5: popaddressty;
 po6: pconstdataty;
begin
 int1:= 0;
 int2:= 0;
// int5:= pelementinfoty(pointer(felementdata))^.header.name; //root
 int5:= 0; //root
 while int1 < fnextelement do begin
  msearrayutils.additem(ar1,typeinfo(dumpinfoty),int2);
  po1:= pelementinfoty(pointer(felementdata)+int1);
  off1:= int1;
  if pointer(po1)-pointer(felementdata) = felementparent then begin
   mstr1:= '*';
  end
  else begin
   mstr1:= ' ';
  end;
  if po1 <> pointer(felementdata) then begin
   po2:= pelementinfoty(pointer(felementdata)+po1^.header.parent);
   if po1^.header.path <> po2^.header.path + po2^.header.name then begin
    mstr1:= mstr1 + '*WRONG PATH $'+hextostrmse(po1^.header.path,8)+'* ';
   end;
  end;
  mstr1:= mstr1+'O:'+inttostrmse(int1) +
            ' P:'+inttostrmse(po1^.header.parent)+{' N:$'+
            hextostrmse(po1^.header.name,8)}
            ' N'+inttostrmse(po1^.header.name)+
            'P'+inttostrmse(po1^.header.path+po1^.header.name)+
            ' '+msestring(getidentname(po1^.header.name)) + 
            ' '+msestring(
                 getenumname(typeinfo(po1^.header.kind),ord(po1^.header.kind)))+
             ' V:'+msestring(
             settostring(ptypeinfo(typeinfo(po1^.header.visibility)),
                                 integer(po1^.header.visibility),true));
  case po1^.header.kind of
   ek_labeldef: begin
    with plabeldefdataty(@po1^.data)^ do begin
     mstr1:= mstr1+lineend+' B:'+inttostrmse(blockid)+
                                           ' A:'+inttostrmse(address);     
    end;
   end;
   ek_var: begin
    with pvardataty(@po1^.data)^ do begin
     mstr1:= mstr1+lineend+' A:'+inttostrmse(address.poaddress)+' I:'+
               inttostrmse(address.indirectlevel)+ ' ' +
           msestring(settostring(ptypeinfo(typeinfo(address.flags)),
                                         integer(address.flags),true));
     if af_segment in address.flags then begin
      mstr1:= mstr1+' S:'+msestring(getenumname(typeinfo(segmentty),
                                    ord(address.segaddress.segment)));
     end
     else begin
      mstr1:= mstr1+' L:'+inttostrmse(address.locaddress.framelevel);
     end;               

     mstr1:= mstr1 + ' def: '+inttostrmse(vf.defaultconst)+lineend+
             dumptyp(vf.typ);
     {
     po2:= eleinfoabs(vf.typ);
     mstr1:= mstr1+' T:'+inttostr(vf.typ)+':'+getidentname(po2^.header.name);
     with ptypedataty(@po2^.data)^ do begin
      mstr1:= mstr1+' K:'+getenumname(typeinfo(kind),ord(kind))+
       ' S:'+inttostr(bytesize)+' I:'+inttostr(indirectlevel);
     end;
     }
    end;
   end;
   ek_field: begin
    with pfielddataty(@po1^.data)^ do begin
     mstr1:= mstr1+lineend+' O:'+inttostrmse(offset)+
          ' I:'+inttostrmse(indirectlevel)+' '+
           msestring(settostring(ptypeinfo(typeinfo(flags)),
                                         integer(flags),true));
     mstr1:= mstr1+dumptyp(vf.typ);
    {
     po2:= eleinfoabs(vf.typ);
     mstr1:= mstr1+' T:'+inttostr(vf.typ)+':'+getidentname(po2^.header.name);
     with ptypedataty(@po2^.data)^ do begin
      mstr1:= mstr1+' K:'+getenumname(typeinfo(kind),ord(kind))+
       ' S:'+inttostr(bytesize);
     end;
    }
    end;
   end;
   ek_property: begin
    with ppropertydataty(@po1^.data)^ do begin
     mstr1:= mstr1 + ' T:'+ inttostrmse(typ) + ' F:' +
                     msestring(settostring(ptypeinfo(typeinfo(flags)),
                                         integer(flags),true));
     if flags * canreadprop <> [] then begin
      mstr1:= mstr1 + ' R:' + inttostrmse(readele);
     end;
     if flags * canwriteprop <> [] then begin
      mstr1:= mstr1 + ' W:' + inttostrmse(writeele);
     end;
     if pof_default in flags then begin
      mstr1:= mstr1 + ' default:' + dumpconst(defaultconst);
     end;
    end;
   end;
   ek_type: begin
    with ptypedataty(@po1^.data)^ do begin
     mstr1:= mstr1+lineend+dumptyp(off1);
     {
     ' K:'+getenumname(typeinfo(kind),ord(kind))+
                      ' S:'+inttostr(bytesize)+' I:'+inttostr(indirectlevel);
     }
     if h.kind in ancestordatakinds then begin
      mstr1:= mstr1+' A:'+inttostrmse(h.ancestor);
      case h.kind of
       dk_class,dk_object: begin
        if icf_defvalid in infoclass.flags then begin
         mstr1:= mstr1+' fcount:'+inttostrmse(fieldcount)+lineend+
            ' flags:'+
              msestring(settostring(ptypeinfo(typeinfo(infoclass.flags)),
                                         integer(infoclass.flags),true))+
               ' alloc:'+inttostrmse(infoclass.allocsize)+
               ' virt:'+inttostrmse(infoclass.virtualcount)+
               ' intf:'+inttostrmse(infoclass.interfacecount)+
               ' isub:'+inttostrmse(infoclass.interfacesubcount)+
               ' defs:'+inttostrmse(infoclass.defs.address)+lineend+
               ' ini:'+inttostrmse(infoclass.subattach[osa_ini])+
               ' fini:'+inttostrmse(infoclass.subattach[osa_fini])+
               ' aftconst:'+inttostrmse(infoclass.subattach[osa_afterconstruct])+
               ' befdest:'+inttostrmse(infoclass.subattach[osa_beforedestruct])+
               ' incref:'+inttostrmse(infoclass.subattach[osa_incref])+
               ' decref:'+inttostrmse(infoclass.subattach[osa_decref])+
               ' destroy:'+inttostrmse(infoclass.subattach[osa_destroy])+
               ' assign:'+inttostrmse(infoclass.subattach[osa_assign]);
{
         po5:= @classdefinfoty(getsegmentpo(infoclass.defs)^).virtualmethods;
         for int6:= 0 to infoclass.virtualcount-1 do begin
          if int6 mod 5 = 0 then begin
           mstr1:= mstr1+lineend+'  ';
          end;
          mstr1:= mstr1+inttostrlenmse(po5^,4)+' ';
          inc(po5);
         end;
}
        end
        else begin
         mstr1:= mstr1 + ' forward';
        end;
       end;
      end;
     end;
     po3:= po1;
    end;
   end;
   ek_const: begin
    po6:= pconstdataty(@po1^.data);
    mstr1:= mstr1+lineend+' N:'+inttostrmse(po6^.nameid)+dumpconst(po6^.val);
   end;
   ek_sub: begin
    with psubdataty(@po1^.data)^ do begin
     mstr1:= mstr1+lineend+
     ' F:'+msestring(
            settostring(ptypeinfo(typeinfo(flags)),integer(flags),true))+
            msestring(
            settostring(ptypeinfo(typeinfo(flags1)),integer(flags1),true))+
     ' idx:'+inttostrmse(tableindex)+' impl:'+inttostrmse(impl)+
     ' ovl:'+inttostrmse(nextoverload)+
     ' op:'+inttostrmse(address)+
     ' def:'+inttostrmse(defaultparamcount);
     if flags * [sf_functiontype,sf_constructor] <> [] then begin
      mstr1:= mstr1+lineend+' result:'+'I:'+
               inttostrmse(resulttype.indirectlevel)+
               dumptyp(resulttype.typeele);
     end;
     if (libname <> 0) or (funcname <> 0) then begin
      mstr1:= mstr1+lineend+' lib:'+getidentstring(libname)+
                            ' func:'+getidentstring(funcname);
     end;
    end;
   end;
   ek_internalsub: begin
    with pinternalsubdataty(@po1^.data)^ do begin
     mstr1:= mstr1 + ' N:'+inttostrmse(nameid);
    end;
   end;
   ek_operator: begin
    with poperatordataty(@po1^.data)^ do begin
     mstr1:= mstr1+' m:'+inttostrmse(methodele);
    end;
   end;
   ek_uses: begin
    with pusesdataty(@po1^.data)^ do begin
     mstr1:= mstr1 + ' U:'+inttostrmse(ref);
    end;
   end;
   ek_ref: begin
    with prefdataty(@po1^.data)^ do begin
     mstr1:= mstr1 + ' R:'+inttostrmse(ref);
    end;
   end;
   ek_alias: begin
    with paliasdataty(@po1^.data)^ do begin
     mstr1:= mstr1 + ' R:'+inttostrmse(base);
    end;
   end;
   ek_condition: begin
    with pconditiondataty(@po1^.data)^ do begin
     mstr1:= mstr1 + ' D:';
     if deleted then begin
      mstr1:= mstr1 + 'true';
     end
     else begin
      mstr1:= mstr1 + 'false';
     end;
     if value.kind <> dk_none then begin
      mstr1:= mstr1+lineend+' value:'+dumpconstvalue(value);
     end;
    end;
   end;
  end;
  int4:= 0;
  int1:= po1^.header.next;
  with ar1[int2-1] do begin
   parent:= po1^.header.parent;
   int3:= po1^.header.parentlevel;
   parentlevel:= int3;
   parents[int3]:= off1;
   for int6:= int3-1 downto 0 do begin
    parents[int6]:= po1^.header.parent;
    int4:= int4 + po1^.header.name;
    po1:= pelementinfoty(pointer(felementdata)+po1^.header.parent);
   end;
   ar2:= breaklines(mstr1);
   if mstr1[1] = '*' then begin
    ar2[0][1]:= ' ';
    mstr2:= '*';
   end
   else begin
    mstr2:= ' ';
   end;
   ar2[0]:= mstr2+charstring(msechar('.'),int3)+'$'+
                 hextostrmse(longword(int5+int4+po1^.header.name),8)+ar2[0];
//                 hextostr(longword(po1^.header.path),8)+ar2[0];
   mstr2:= charstring(msechar(' '),int3+1);
   for int6:= 1 to high(ar2) do begin
    ar2[int6]:= mstr2+ar2[int6];
   end;
   text:= concatstrings(ar2,lineend);
   offset:= off1;
  end;
 end;
 setlength(ar1,int2);
 sortarray(ar1,sizeof(ar1[0]),@compdump);
 setlength(result,int2+1);
 result[0]:= 'elementpath: $'+hextostrmse(felementpath,8);
 for int1:= 0 to int2-1 do begin
  result[int1+1]:= ar1[int1].text;
 end;
 msearrayutils.additem(result,'---SCOPES');
 if fscopespo <> nil then begin
  int1:= length(result);
  setlength(result,length(result)+(fscopespo-pscopeinfoty(fscopes))+1);
  po4:= fscopes;
  for int1:= int1 to high(result) do begin
   po1:= ele.eleinfoabs(po4^.element);
   mstr1:= msestring(
              getenumname(typeinfo(po1^.header.kind),ord(po1^.header.kind)));
   po1:= ele.eleinfoabs(po4^.childparent);
   mstr1:= mstr1+' CP:'+
    msestring(getenumname(typeinfo(po1^.header.kind),ord(po1^.header.kind))+
    ' '+getidentname(po1^.header.name));
   result[int1]:= mstr1;
   inc(po4);
  end;
 end;
end;

function telementhashdatalist.dumppath(
                               const aelement: pelementinfoty): msestring;
var
 po1: pelementinfoty;
begin
 result:= '';
 po1:= aelement;
 result:= msestring(getidentname(po1^.header.name));
 while po1^.header.parent <> 0 do begin
  po1:= pointer(felementdata)+po1^.header.parent;
  result:= msestring(getidentname(po1^.header.name)+'.')+result;
 end;
end;
{$endif}

procedure telementhashdatalist.checkbuffersize;

begin
 if fnextelement >= felementlen then begin
  felementlen:= fnextelement*2+mindatasize;
  setlength(felementdata,felementlen);
 end;
end;

procedure telementhashdatalist.checkcapacity(const areserve: integer);
begin
 if fnextelement+areserve >= felementlen then begin
  felementlen:= fnextelement*2+mindatasize+areserve;
  setlength(felementdata,felementlen);
 end;
end;

procedure telementhashdatalist.checkcapacity(const akind: elementkindty;
                                                  const acount: integer = 1);
var
 ele1: elementoffsetty;
begin
 ele1:= elesizes[akind]*acount;
 if fnextelement+ele1 >= felementlen then begin
  felementlen:= fnextelement*2+mindatasize+ele1;
  setlength(felementdata,felementlen);
 end;
end;

procedure telementhashdatalist.checkcapacity(const akind: elementkindty;
               const acount: integer; var reloc: pointer);
var
 p1: pointer;
begin
 p1:= pointer(felementdata);
 checkcapacity(akind,acount);
 if reloc <> nil then begin
  reloc:= reloc + (pointer(felementdata)-p1);
 end;
end;

procedure telementhashdatalist.checkcapacity(const akind: elementkindty;
               const acount: integer; var reloc1,reloc2: pointer);
var
 p1: pointer;
begin
 p1:= pointer(felementdata);
 checkcapacity(akind,acount);
 if reloc1 <> nil then begin
  reloc1:= reloc1 + (pointer(felementdata)-p1);
 end;
 if reloc2 <> nil then begin
  reloc2:= reloc2 + (pointer(felementdata)-p1);
 end;
end;

function telementhashdatalist.addbuffer(const asize: int32): pointer;
var
 ele1: elementoffsetty;
begin
 ele1:= fnextelement;
 fnextelement:= fnextelement+alignsize(asize);
 checkbuffersize();
 result:= pointer(felementdata)+ele1;
end;

procedure telementhashdatalist.inieleheader(var aheader: elementheaderty;
                       const aname: identty; const akind: elementkindty;
                       const avislevel: visikindsty);
begin
 with aheader do begin
 {$ifdef mse_debugparser}
  next:= fnextelement; //for debugging
 {$endif}
  parent:= felementparent;
  parentlevel:= fparentlevel;
  path:= felementpath;
  name:= aname;
  visibility:= avislevel;
  defunit:= info.s.unitinfo;
  if (defunit <> nil) and 
               not (us_implementation in info.s.unitinfo^.state) then begin
   include(visibility,vik_interfacedef);
  end;
  kind:= akind;
 end;
end;

function telementhashdatalist.pushelementduplicate(const aname: identty;
                  const akind: elementkindty;
                  const avislevel: visikindsty;
                  const sizeextend: integer): pelementinfoty;
var
 ele1: elementoffsetty;
begin
 ele1:= fnextelement;
 fnextelement:= fnextelement+(elesizes[akind])+alignsize(sizeextend);
 checkbuffersize;
 result:= pointer(felementdata)+ele1;
 inieleheader(result^.header,aname,akind,avislevel);
 felementparent:= ele1;
 inc(fparentlevel);
 if fparentlevel >= maxidentvector then begin
  errormessage(err_toomanynestinglevels,[]);
 end;
 felementpath:= felementpath+aname;
 addelement(felementpath,avislevel,ele1);
end;

function telementhashdatalist.pushelementduplicatedata(const aname: identty;
               const akind: elementkindty; const avislevel: visikindsty;
               out adata: pointer): boolean;
var
 ele1: elementoffsetty;
begin
 result:= not findcurrent(aname,[],allvisi,ele1);
 adata:= pointer(pushelementduplicate(aname,akind,avislevel,0)) + eledatashift;
end;

function telementhashdatalist.pushelement(const aname: identty;
             const akind: elementkindty; 
             const avislevel: visikindsty): pelementinfoty; //nil if duplicate
var
 ele1: elementoffsetty;
begin
 result:= nil;
 if not findcurrent(aname,[],allvisi{ffindvislevel},ele1) then begin
  result:= pushelementduplicate(aname,akind,avislevel,0);
 end;
end;

function telementhashdatalist.pushelement(const aname: identty;
            const akind: elementkindty; const avislevel: visikindsty;
                   out aelementdata: pointer): boolean; //false if duplicate
begin
 aelementdata:= pushelement(aname,akind,avislevel);
 result:= aelementdata <> nil;
 if result then begin
  aelementdata:= @(pelementinfoty(aelementdata)^.data);
 end;
end;

function telementhashdatalist.pushelement(const aname: identty;
           const akind: elementkindty; const avislevel: visikindsty;
           out aelementdata: elementoffsetty): boolean;
                                                    //false if duplicate
var
 po1: pelementinfoty;
begin
 po1:= pushelement(aname,akind,avislevel);
 result:= po1 <> nil;
 if result then begin
  aelementdata:= pointer(po1)-pointer(felementdata);
 end;
end;

function telementhashdatalist.pushelementorduplicate(const aname: identty;
       const akind: elementkindty;                  
       const avislevel: visikindsty;
       const sizeextend: integer; out aelementdata: pointer): boolean;
                                                       //false if duplicate
var
 po1: pelementinfoty;
 ele1: elementoffsetty;
begin
 result:= false;
 if not findcurrent(aname,[],allvisi{ffindvislevel},ele1) then begin
  po1:= pushelementduplicate(aname,akind,avislevel,sizeextend);
  aelementdata:= @(po1^.data);
 end
 else begin
  aelementdata:= ele.eledataabs(ele1);
  pushelementparent(ele1);
 end;
end;

function telementhashdatalist.addelementduplicate1(const aname: identty;
                                const akind: elementkindty;
                                const avislevel: visikindsty): elementoffsetty;
//var
// ele1: elementoffsetty;
begin
 result:= fnextelement;
 fnextelement:= fnextelement+elesizes[akind];
 checkbuffersize;
// result:= pointer(felementdata)+ele1;
 inieleheader(eleinfoabs(result)^.header,aname,akind,avislevel);
 addelement(felementpath+aname,avislevel,result);
end;

function telementhashdatalist.addelementduplicatedata1(const aname: identty;
                                const akind: elementkindty;
                                const avislevel: visikindsty): pointer;
begin
 result:= addelementduplicate1(aname,akind,avislevel) +
                        pointer(felementdata) + eledatashift;
end;

function telementhashdatalist.addelementduplicate(const aname: identty;
                                const akind: elementkindty;
                                const avislevel: visikindsty): pelementinfoty;
begin
 result:= eleinfoabs(addelementduplicate1(aname,akind,avislevel));
end;

function telementhashdatalist.addelementduplicatedata(const aname: identty;
               const akind: elementkindty;
               const avislevel: visikindsty; out aelementdata: pointer;
               const asearchlevel: visikindsty = allvisi): boolean;
var
 ele1: elementoffsetty;
begin
 result:= not findcurrent(aname,[],asearchlevel,ele1);
 aelementdata:= eledataabs(addelementduplicate1(aname,akind,avislevel));
end;             

function telementhashdatalist.addelement(const aname: identty;
              const akind: elementkindty; 
              const avislevel: visikindsty): pelementinfoty;   
                                                   //nil if duplicate
var
 scopebefore: pscopeinfoty;
 ele1: elementoffsetty;
begin
 result:= nil;
 scopebefore:= fscopespo;
 fscopespo:= nil;
 if not findcurrent(aname,[],allvisi{ffindvislevel},ele1) then begin
  result:= addelementduplicate(aname,akind,avislevel);
 end;
 fscopespo:= scopebefore;
end;

function telementhashdatalist.addelement(const aname: identty;
               const akind: elementkindty; const avislevel: visikindsty;
               out aelement: pelementinfoty): boolean;
                      //false if duplicate, aelement = new or duplicate
var
 scopebefore: pscopeinfoty;
 ele1: elementoffsetty;
begin
 scopebefore:= fscopespo;
 fscopespo:= nil;
 if not findcurrent(aname,[],allvisi{ffindvislevel},ele1) then begin
  aelement:= addelementduplicate(aname,akind,avislevel);
  result:= true;
 end
 else begin
  aelement:= eledataabs(ele1);
  result:= false;
 end;
 fscopespo:= scopebefore;
end;

function telementhashdatalist.addelementdata(const aname: identty; 
                       const akind: elementkindty;
                       const avislevel: visikindsty): pointer; 
                                              //nil if duplicate
begin
 result:= addelement(aname,akind,avislevel);
 if result <> nil then begin
  result:= @pelementinfoty(result)^.data;
 end;
end;

function telementhashdatalist.addelementdata(const aname: identty;
           const akind: elementkindty; const avislevel: visikindsty;
           out aelementdata: pointer): boolean;
         //false if duplicate, aelementdata = new or duplicate
var
 scopebefore: pscopeinfoty;
 ele1: elementoffsetty;
 vk1: visikindsty;
begin
 scopebefore:= fscopespo;
 fscopespo:= nil;
 vk1:= avislevel;
 if vik_noancestor in vk1 then begin
  vk1:= vk1 - [vik_ancestor,vik_noancestor];
 end;
 result:= not findcurrent(aname,[],{avislevel}vk1{allvisi}{ffindvislevel},ele1);
 if result then begin
  aelementdata:= eledataabs(addelementduplicate1(
                                aname,akind,avislevel-[vik_noancestor]));
 end
 else begin
  aelementdata:= eledataabs(ele1);
 end;
 fscopespo:= scopebefore;
end;

function telementhashdatalist.addelement(const aname: identty;
              const akind: elementkindty;
              const avislevel: visikindsty;
              out aelementoffset: elementoffsetty): boolean;
         //false if duplicate, aelementoffset = 0 if duplicate
var
 po1: pelementinfoty;
begin
 po1:= addelement(aname,akind,avislevel);
 result:= po1 <> nil;
 if result then begin
  aelementoffset:= pointer(po1)-pointer(felementdata);
 end
 else begin
  aelementoffset:= 0;
 end;
end;

function telementhashdatalist.adduniquechilddata(const aparent: elementoffsetty;
               const achild: pidentty; const ahigh: int32; 
               const akind: elementkindty;const avislevel: visikindsty;
                                            out aelementdata: pointer): boolean;
var
 parentbefore: elementoffsetty;
 i1: int32;
 ele1: elementoffsetty;
begin
 result:= not findchilddata(aparent,achild,ahigh,[akind],avislevel,aelementdata);
 if result then begin
  parentbefore:= felementparent;
  ele1:= aparent;
  for i1:= 0 to ahigh - 1 do begin
   if not findchild(ele1,[achild[i1]],[],allvisi,ele1) then begin
    elementparent:= ele1;
    ele1:= addelementduplicate1(achild[i1],ek_none,allvisi);
   end;
  end;
  elementparent:= ele1;
  aelementdata:= addelementduplicatedata1(achild[ahigh],akind,avislevel);
  elementparent:= parentbefore;
 end;
end;

function telementhashdatalist.adduniquechilddata(const aparent: elementoffsetty;
               const achild: identvecty; const akind: elementkindty;
               const avislevel: visikindsty;
               out aelementdata: pointer): boolean;
begin
 result:= adduniquechilddata(aparent,@achild.d[0],achild.high,
                                               akind,avislevel,aelementdata);
end;

function telementhashdatalist.adduniquechilddata(const aparent: elementoffsetty;
                           const achild: array of identty;
                           const akind: elementkindty;
                           const avislevel: visikindsty;
                           out aelementdata: pointer): boolean;
begin
 result:= adduniquechilddata(aparent,@achild[0],high(achild),
                                              akind,avislevel,aelementdata);
end;

function telementhashdatalist.addchildduplicatedata(
                           const aparent: elementoffsetty;
                           const achild: array of identty; 
                           const akind: elementkindty;
                           const avislevel: visikindsty): pointer;
var
 parentbefore: elementoffsetty;
 i1: int32;
 ele1: elementoffsetty;
begin
 parentbefore:= felementparent;
 ele1:= aparent;
 for i1:= 0 to high(achild) - 1 do begin
  if not findchild(ele1,[achild[i1]],[],allvisi,ele1) then begin
   elementparent:= ele1;
   ele1:= addelementduplicate1(achild[i1],ek_none,allvisi);
  end;
 end;
 elementparent:= ele1;
 result:= addelementduplicatedata1(achild[high(achild)],akind,avislevel);
 elementparent:= parentbefore;
end;

function telementhashdatalist.addalias(const aname: identty;
                                  const abase: elementoffsetty;
                                     const avislevel: visikindsty): boolean;
var
 parent1: elementoffsetty;
 ele1: elementoffsetty;
 po1: paliasdataty;
begin
 parent1:= pelementinfoty(pointer(felementdata)+abase)^.header.parent;
 result:= not findchild(parent1,aname,[],avislevel,ele1);
 if result then begin
  ele1:= felementparent;
  setelementparent(parent1);
  po1:= addelementduplicatedata1(aname,ek_alias,avislevel);
  po1^.base:= abase;
  setelementparent(ele1);
 end;
end;

function telementhashdatalist.popelement: pelementinfoty;
begin
 result:= pelementinfoty(pointer(felementdata)+felementparent);
 felementparent:= result^.header.parent;
 fparentlevel:= result^.header.parentlevel;
 felementpath:= result^.header.path;
end;

function telementhashdatalist.decelementparent: elementoffsetty; 
                    //returns old offset
begin
 result:= felementparent;
 with pelementinfoty(pointer(felementdata)+felementparent)^ do begin
  felementparent:= header.parent;
  fparentlevel:= header.parentlevel;
  felementpath:= header.path;
 end;
end;

procedure telementhashdatalist.setelementparent(const element: elementoffsetty);
var
 po1: pelementinfoty;
begin
 felementparent:= element;
 with pelementinfoty(pointer(felementdata)+felementparent)^ do begin
  felementpath:= header.path + header.name;
  fparentlevel:= header.parentlevel+1;
 end;
end;
{
function telementhashdatalist.findelement(const aname: identty;
              const akinds: elementkindsty;
              const avislevel: vislevelty): pelementinfoty; //nil if not found
var
 ele1: elementoffsetty;
begin
 result:= nil;
 ele1:= findcurrent(aname,akinds,avislevel);
 if ele1 >= 0 then begin
  result:= pelementinfoty(pointer(felementdata)+ele1);
 end;
end;

function telementhashdatalist.findelementupward(const aname: identty;
              const akinds: elementkindsty;
              const avislevel: vislevelty): pelementinfoty; //nil if not found
var
 ele1: elementoffsetty;
begin
 result:= nil;
 ele1:= findupward(aname,akinds,avislevel);
 if ele1 >= 0 then begin
  result:= pelementinfoty(pointer(felementdata)+ele1);
 end;
end;

function telementhashdatalist.findelementupward(const aname: identty;
                     const akinds: elementkindsty;
                     const avislevel: vislevelty;
                     out element: elementoffsetty): pelementinfoty; overload;
                                                    //nil if not found
begin
 result:= nil;
 element:= findupward(aname,akinds,avislevel);
 if element >= 0 then begin
  result:= pelementinfoty(pointer(felementdata)+element);
 end;
end;

function telementhashdatalist.findelementsupward(const anames: identvectorty;
                     const akinds: elementkindsty;
                     const avislevel: vislevelty;
                     out element: elementoffsetty): pelementinfoty;
                                                    //nil if not found
begin
 result:= nil;
 element:= findupward(anames,akinds,avislevel);
 if element >= 0 then begin
  result:= pelementinfoty(pointer(felementdata)+element);
 end;
end;

function telementhashdatalist.findelementsupward(const anames: identarty;
                     const akinds: elementkindsty;
                        const avislevel: vislevelty;
                        out element: elementoffsetty): pelementinfoty;
                                                       //nil if not found
var
 vec1: identvectorty;
begin
 vec1.high:= high(anames);
 if vec1.high > maxidentvector then begin
  raise exception.create('Internal error E20131103A');
 end;
 move(anames[0],vec1.d,(vec1.high+1)*sizeof(vec1.d[0]));
 result:= findelementsupward(vec1,akinds,avislevel,element);
end;

function telementhashdatalist.findelementsupward(const anames: identvectorty;
                     out element: elementoffsetty): pelementinfoty;
                                                    //nil if not found
//todo: use identvectorty directly
var
 ar1: identarty;
 int1,int2: integer;
begin
 setlength(ar1,high(anames)+1);
 int2:= 0;
 for int1:= 0 to high(anames) do begin
  ar1[int1]:= anames[int1];
  if ar1[int1] = 0 then begin
   int2:= int1;
   break;
  end;
 end;
 setlength(ar1,int2);
 result:= findelementsupward(ar1,element);
end;
}
procedure telementhashdatalist.markelement(out ref: markinfoty);
begin
 mark(ref.hashref);
 ref.bufferref:= fnextelement;
// markunitstate(ref);
end;

procedure telementhashdatalist.releaseelement(const ref: markinfoty);
begin
// releaseunitstate(ref);
 release(ref.hashref);
 fnextelement:= ref.bufferref;
end;

procedure telementhashdatalist.hideelementdata(const adata: pointer);
begin
 with pelementinfoty(adata-sizeof(elementheaderty))^.header do begin
  path:= path-name;
  name:= 0;
 end;
end;

procedure telementhashdatalist.pushscopelevel;
begin
 inc(fscopestackpo);
 if fscopestackpo >= fscopestacksize then begin
  fscopestacksize:= fscopestacksize*2+16;
  setlength(fscopestack,fscopestacksize);
 end;
 if fscopes = nil then begin
  fscopestack[fscopestackpo]:= -1;
 end
 else begin
  fscopestack[fscopestackpo]:= pointer(fscopespo)-fscopes;
 end;
end;

procedure telementhashdatalist.popscopelevel;
var
 int1,int2: integer;
begin
 if fscopestackpo < 0 then begin
 {$ifdef mse_checkinternalerror}
  internalerror(ie_elements,'E20140406C');
 {$endif}
 end
 else begin
  int2:= fscopestack[fscopestackpo];
  if int2 < 0 then begin
   fscopespo:= nil;
  end
  else begin
   fscopespo:= fscopes + int2;
  end;
  dec(fscopestackpo);
 end; 
end;

function telementhashdatalist.addscope(const aname: identty;
                                 const akind: elementkindty;
                                 const achildparent: elementoffsetty): pointer;
var
 int1: integer;
begin
 if fscopespo = nil then begin
  fscopespo:= fscopes;
 end
 else begin
  inc(fscopespo);
  if fscopespo >= fscopesend then begin
   int1:= fscopespo-fscopes;
   reallocmem(fscopes,int1*2);
   fscopesend:= fscopes + int1*2;
   fscopespo:= fscopes + int1;
  end;
 end;
 result:= addelement(getident(),akind,globalvisi);
 if result = nil then begin
 {$ifdef mse_checkinternalerror}
  internalerror(ie_elements,'20140407B'); //duplicate id
 {$endif}
 end;
 with fscopespo^ do begin
  name:= aname;
  element:= result-pointer(felementdata);
  childparent:= achildparent;
 end;
 inc(result,eledatashift);
end;

procedure telementhashdatalist.pushelementparent(
                                           const aparent: elementoffsetty);
begin
{$ifdef mse_checkinternalerror}
 if fparentindex > maxparents then begin
  internalerror(ie_elements,'201400412A');
 end;
{$endif}
 fparents[fparentindex]:= elementparent;
 elementparent:= aparent;
 inc(fparentindex);
end;

procedure telementhashdatalist.pushelementparent(); //save current on stack
begin
{$ifdef mse_checkinternalerror}
 if fparentindex > maxparents then begin
  internalerror(ie_elements,'201400412A');
 end;
{$endif}
 fparents[fparentindex]:= elementparent;
 inc(fparentindex);
end;

procedure telementhashdatalist.popelementparent;
begin
{$ifdef mse_checkinternalerror}
 if fparentindex = 0 then begin
  internalerror(ie_elements,'201400412B');
 end;
{$endif}
 dec(fparentindex);
 elementparent:= fparents[fparentindex];
end;

{
function elementcount: integer;
begin
 result:= elementlist.count;
end;
}
{ tstringbuffer }

constructor tstringbuffer.create;
begin
// inherited create(sizeof(stringbufdataty));
 inherited;
 initbuffer;
end;

function tstringbuffer.getrecordsize(): int32;
begin
 result:= sizeof(stringbufhashdataty);
end;

destructor tstringbuffer.destroy;
begin
 inherited;
 freemem(fbuffer);
end;

function tstringbuffer.hashkey(const akey): hashvaluety;
begin
 result:= stringhash(lstringty(akey));
end;
{
function tstringbuffer.hashkey(const akey): hashvaluety;
var
 h1: hashvaluety;
 p1,pe: pcard8;
begin
 h1:= 0;
 with lstringty(akey) do begin
  p1:= pointer(po);
  pe:= p1 + len;
  while p1 < pe do begin
   h1:= h1+p1^;
   inc(p1);
  end;
 end;
 result:= h1;
end;
}
function tstringbuffer.checkkey(const akey; const aitem: phashdataty): boolean;
begin
 with pstringbufhashdataty(aitem)^ do begin
  result:= (lstringty(akey).len = data.len) and
       comparemem(lstringty(akey).po,
                       fbuffer+data.offset,data.len);
 end;
end;

function tstringbuffer.checkgrow(): boolean;
begin
 result:= false;
 if fbufsize > fbufcapacity then begin
  fbufcapacity:= fbufsize*2;
  reallocmem(fbuffer,fbufcapacity);
  result:= true;
 end;
end;

function tstringbuffer.add(const avalue: lstringty): stringvaluety;
var
 hash: longword;
 po1: pstringbufhashdataty;
 offs1: ptruint;
// len1: integer;
begin
 hash:= stringhash(avalue);
 po1:= pointer(internalfind(avalue,hash));
 if po1 = nil then begin
//  len1:= length(avalue);
  po1:= pointer(internaladdhash(hash));
  po1^.data.offset:= fbufsize;
  po1^.data.flags:= [];
  po1^.data.constoffset8:= -1;
  po1^.data.constoffset16:= -1;
  po1^.data.constoffset32:= -1;
  po1^.data.len:= avalue.len;
  fbufsize:= fbufsize + avalue.len;
  checkgrow();
  move(avalue.po^,(fbuffer+po1^.data.offset)^,avalue.len);
 end;
 result.offset:= pointer(po1)-fdata;
 if avalue.len = 0 then begin
  result.flags:= [strf_empty];
 end
 else begin
  result.flags:= [];
 end;
end;

function tstringbuffer.add(const avalue: string): stringvaluety;
begin
 result:= add(stringtolstring(avalue));
end;

procedure tstringbuffer.clear;
begin
 initbuffer;
 inherited; 
end;

procedure tstringbuffer.mark(out ref: stringbufmarkty);
begin
 inherited mark(ref.hashmark);
 ref.size:= fbufsize;
end;

procedure tstringbuffer.release(const ref: stringbufmarkty);
begin
 inherited release(ref.hashmark);
 if ref.size = 0 then begin
  freemem(fbuffer);
  fbuffer:= nil;
 end
 else begin
  reallocmem(fbuffer,ref.size);
 end;
 fbufsize:= ref.size;
 fbufcapacity:= fbufsize;
end;

procedure tstringbuffer.initbuffer;
const
 minbuffersize = $16;// $10000; //todo: use bigger size for production
begin
 fbufsize:= 0;
 fbufcapacity:= minbuffersize;
 reallocmem(fbuffer,fbufcapacity);
end;
 
function tstringbuffer.allocconst(const astring: stringvaluety): segaddressty;

var
 po1: pstringheaderty;
 fla1: addressflagsty;
 i1: int32;
 p1: pdataoffsty;
 ps,pe: pcard8;
 pd: pointer;
 p8: pcard8;
 p16: pcard16;
 p32: pcard32;
 c1: card32;
 len1: int32;
 hash1: hashvaluety;
 lstr1: lstringty;
 stringbuf1: pstringbufhashdataty;
 hashbuf2: phashdataty;
 bufferstart: segmentstatety;
begin
 if strf_empty in astring.flags then begin
  result.address:= 0;
  result.segment:= seg_nil;
  exit;
 end;
 stringbuf1:= pstringbufhashdataty(fdata+astring.offset);
 if stringbuf1^.data.len = 0 then begin
  result.address:= 0;
  result.segment:= seg_nil;
 end
 else begin
  bufferstart:= savesegment(seg_globconst);
  if stringbuf1^.header.prevhash < 0 then begin //temp string
   lstr1.len:= stringbuf1^.data.len;
   lstr1.po:= fbuffer + stringbuf1^.data.offset;
   hash1:= hashkey(lstr1);
   hashbuf2:= internalfind(lstr1,hash1);
   if hashbuf2 <> nil then begin
    stringbuf1:= pointer(hashbuf2);
   end
   else begin
    inserthash(hash1,pointer(stringbuf1));
   end;
  end;
  with stringbuf1^.data do begin
   ps:= fbuffer+offset;
   pe:= ps+len;
   if strf_16 in astring.flags then begin
    p1:= @constoffset16;
    if p1^ = -1 then begin
     i1:= sizeof(stringheaderty)+(len+1)*2; //max
     result:= getglobconstaddress(i1,pd); 
     pd:= pd+sizeof(stringheaderty);
     p16:= pd;
     while ps < pe do begin
      getcodepoint(ps,pe,c1);
      if c1 > $ffff then begin
       c1:= c1 - $10000;
       p16^:= (c1 shr 10) or $d800;
       inc(p16);
       p16^:= c1 and %1111111111 or $dc00;
      end
      else begin
       p16^:= c1;
      end;
      inc(p16);
     end;
     p16^:= 0;       //terminating zero
     len1:= p16-pcard16(pd);
     reallocsegment(result,i1,sizeof(stringheaderty)+(len1+1)*2);
    end;
   end
   else begin
    if strf_32 in astring.flags then begin
     p1:= @constoffset32;
     if p1^ = -1 then begin
      i1:= sizeof(stringheaderty)+(len+1)*4; //max
      result:= getglobconstaddress(i1,pd); 
      pd:= pd+sizeof(stringheaderty);
      p32:= pd;
      while ps < pe do begin
       getcodepoint(ps,pe,p32^);
       inc(p32);
      end;
      p32^:= 0;       //terminating zero
      len1:= p32-pcard32(pd);
      reallocsegment(result,i1,sizeof(stringheaderty)+(len1+1)*4);
     end;
    end
    else begin
     len1:= len;
     p1:= @constoffset8;
     if p1^ = -1 then begin
      if strf_set in astring.flags then begin
       result:= getglobconstaddress(len1,pd);
       p8:= pd;
       move((fbuffer+offset)^,p8^,len1);
      end
      else begin
       result:= getglobconstaddress(sizeof(stringheaderty)+(len1+1),pd);
       p8:= pd+sizeof(stringheaderty);
       move((fbuffer+offset)^,p8^,len1);
       p8[len1]:= 0;
      end;
     end;
    end;
   end;
   if p1^ = -1 then begin
    p1^:= result.address;
    if not (strf_set in astring.flags) then begin
     with info do begin    
      po1:= getsegmentpo(result);
      po1^.ref.count:= -1;
      po1^.len:= len1;
     end;
    end;
    if co_llvm in info.o.compileoptions then begin
     i1:= info.s.unitinfo^.llvmlists.constlist.addvalue(po1^,
                                         getbuffersize(bufferstart)).listid;
     p1^:= info.s.unitinfo^.llvmlists.globlist.addinitvalue(
                                         gak_const,i1,info.s.globlinkage);
     restoresegment(bufferstart);
    end;
   end;
   result.segment:= seg_globconst;
   result.address:= p1^;
  end;
 end;
end;

function tstringbuffer.getlength(const astring: stringvaluety): int32;
begin
 with pstringbufhashdataty(fdata+astring.offset)^ do begin
  result:= data.len;
 end;
end;

function tstringbuffer.getbufpo(const astring: stringvaluety;
                           out datapo: pointer): pstringbufhashdataty;
var
 p1: pconstdataty;
begin
 if strf_ele in astring.flags then begin
 {$ifdef mse_checkinternalerror}
  if (ele.eleinfoabs(astring.offset)^.header.kind <> ek_const) or
     not (pconstdataty(ele.eledataabs(astring.offset))^.val.d.kind in
                                               [dk_string,dk_set]) then begin
   internalerror(ie_elements,'20180903B');
  end;
 {$endif}
  p1:= ele.eledataabs(astring.offset);
  with tstringbuffer(datatoele(p1)^.header.defunit^.stringbuffer) do begin
   if p1^.val.d.kind = dk_set then begin
    result:= fdata+p1^.val.d.vset.bigsetvalue.offset;
   end
   else begin
    result:= fdata+p1^.val.d.vstring.offset;
   end;
   datapo:= fbuffer+result^.data.offset;
  end;
 end
 else begin
  result:= fdata+astring.offset;
  datapo:= fbuffer+result^.data.offset;
 end;
end;

function tstringbuffer.getstring(const astring: stringvaluety): lstringty;
var
 po1: pointer;
begin
 with getbufpo(astring,result.po)^ do begin
  result.len:= data.len;
 end;
end;

procedure tstringbuffer.trackstringref(const astring: stringvaluety);
var
 p1: pointer;
begin
 with getbufpo(astring,p1)^ do begin
  include(data.flags,sbf_referenced);
 end; 
end;

procedure tstringbuffer.concatstringconsts(var dest: stringvaluety;
               const b: stringvaluety);
var
 pa,pb: pstringbufhashdataty;
 pac,pbc: pointer;
 p1: pointer;
 i1: int32;
 lstr1: lstringty;
 hash1: hashvaluety;
begin
// pa:= pstringbufhashdataty(fdata+dest.offset);
// pb:= pstringbufhashdataty(fdata+b.offset);
 pa:= getbufpo(dest,pac);
 pb:= getbufpo(b,pbc);
 if not (strf_ele in dest.flags) and 
          (pb^.data.offset + pb^.data.len = fbufsize) and 
                       (pa^.data.offset + pa^.data.len = pb^.data.offset) and
                       //last two entries
           not (sbf_referenced in pa^.data.flags) and 
           not (sbf_referenced in pb^.data.flags) and
           not (strf_ele in dest.flags) and
           (pa^.data.constoffset8 = -1) and (pa^.data.constoffset16 = -1) and
               (pa^.data.constoffset32 = -1) and
           (pb^.data.constoffset8 = -1) and (pb^.data.constoffset16 = -1) and
               (pb^.data.constoffset32 = -1) then begin 
     //concat in place
  removehash(pointer(pa));
  pa^.data.len:= pa^.data.len + pb^.data.len;
  internaldelete(b.offset);
 end
 else begin
  i1:= pa^.data.len + pb^.data.len;
  fbufsize:= fbufsize + i1;
  if checkgrow() then begin
   pa:= getbufpo(dest,pac);
   pb:= getbufpo(b,pbc);
//   pa:= pstringbufhashdataty(fdata+dest.offset);
//   pb:= pstringbufhashdataty(fdata+b.offset);
  end;
  lstr1.po:= fbuffer+fbufsize-i1;
  lstr1.len:= i1;
  move(pac^,lstr1.po^,pa^.data.len);
  move(pbc^,(fbuffer+fbufsize-pb^.data.len)^,
                                                         pb^.data.len);
  hash1:= stringhash(lstr1);
  pa:= pointer(internalfind(lstr1,hash1));
  if pa = nil then begin
   pa:= pointer(internaladdhash(hash1));
   pa^.data.offset:= fbufsize-i1;
   pa^.data.flags:= [];
   pa^.data.constoffset8:= -1;
   pa^.data.constoffset16:= -1;
   pa^.data.constoffset32:= -1;
   pa^.data.len:= i1;
  end
  else begin
   fbufsize:= fbufsize-i1;
//   include(pa^.data.flags,sbf_referenced); 
  end;
  dest.offset:= pointer(pa)-fdata;
  dest.flags:= [];
 end;
end;

procedure initunit(const aunit: punitinfoty);
begin
 if info.modularllvm then begin
  aunit^.stringbuffer:= tstringbuffer.create();
 end
 else begin
  if stringbuf = nil then begin
   stringbuf:= tstringbuffer.create();
  end;
  aunit^.stringbuffer:= stringbuf;
 end;
end;

procedure deinitunit(const aunit: punitinfoty; const aftercompile: boolean);
begin
 if not aftercompile then begin
  if info.modularllvm then begin
   freeandnil(tstringbuffer(aunit^.stringbuffer));
  end
  else begin
   aunit^.stringbuffer:= nil;
  end;
 end;
end;

procedure interfaceend(const aunit: punitinfoty);
begin
 if info.modularllvm then begin
  with aunit^ do begin
   tstringbuffer(stringbuffer).mark(implementationstringbufstart);
  end;
 end;
end;

procedure implementationend(const aunit: punitinfoty);
begin
 if info.modularllvm then begin
  with aunit^ do begin
   tstringbuffer(stringbuffer).release(implementationstringbufstart);
  end;
 end;
end;

initialization
// stringbuf:= tstringbuffer.create; //todo: use per unit string buffer
 ele:= telementhashdatalist.create;
 globllvmlists:= tllvmlists.create();
// typelist:= ttypehashdatalist.create();
// constlist:= tconsthashdatalist.create(typelist);
// globlist:= tgloballocdatalist.create(typelist,constlist);
 clear();
finalization
// stringbuf.free();
 ele.free();
 globllvmlists.free();
// typelist.free();
// constlist.free();
// globlist.free();
end.
