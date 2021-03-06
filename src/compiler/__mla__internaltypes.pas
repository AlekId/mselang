//__mla__internaltypes
{ MSEgui Copyright (c) 2014-2018 by Martin Schreiber

    See the file COPYING.MSE, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
{$ifndef fpc} {$mode mselang} {$endif} //unit used in MSElang compiler
unit __mla__internaltypes;
interface
// {$internaldebug on}
//{$ifndef mse_compiler}
// procedure test(a: int32);
//{$endif}
 
type
 ppointer = ^pointer;

type
{$ifdef mse_compiler}
 targetptrintty = int32;
 ptargetptrintty = ^targetptrintty;
 card8 = byte;
 card16 = word;
 card32 = longword;
 card64 = qword;
 targetpointerty = card32;
 ptargetpointerty = ^targetpointerty;
 flo64 = double;
 char8 = char;
 char16 = unicodechar;
 char32 = card32;
 bytestring = targetptrintty;
 string8 = targetptrintty;
 string16 = targetptrintty;
 string32 = targetptrintty;
{$endif}
 cint = int32;
 
 ptrint = int32;
 pptrint = ^ptrint;
 ptrcard = card32;

 pcard8 = ^card8;
 pcard16 = ^card16;
 pcard32 = ^card32;
 
 pint64 = ^int64;
 pcard64 = ^card64;
 pflo64 = ^flo64;

 pchar8 = ^char8; 
 pchar16 = ^char16; 
 pchar32 = ^char32; 
 
 pbytestring = ^bytestring;
 pstring8 = ^string8;
 pstring16 = ^string16;
 pstring32 = ^string32;

{$ifdef fpc}
 flo64recty = packed record       //little endian
  case integer of
   0: (by0,by1,by2,by3,by4,by5,by6,by7: byte);
   1: (wo0,wo1,wo2,wo3: word);
   2: (lwo0,lwo1: longword);
   3: (qwo0: qword);
 end;
{$else}
//63,     62..52, 51..0
//sign(1) exp(11) mant(52)
 flo64recty = packed record       //little endian
  (by0,by1,by2,by3,by4,by5,by6,by7: byte);
  (wo0,wo1,wo2,wo3: word);
  (lwo0,lwo1: longword);
  (qwo0: qword);
 end;
{$endif}

 refcountty = int32;
 managedsizety = ptrint;
 stringsizety = managedsizety;
 pstringsizety = ^stringsizety;
 dynarraysizety = managedsizety;
 pdynarraysizety = ^dynarraysizety;
 
 refinfoty = record
  count: refcountty;
 end;
 prefinfoty = ^refinfoty;
 refsizeinfoty = record
  ref: refinfoty;
  sizedummy: managedsizety;
 end;
 prefsizeinfoty = ^refsizeinfoty;
 pprefsizeinfoty = ^prefsizeinfoty;

 stringheaderty = record
  ref: refinfoty;
  len: stringsizety;
  data: record
  end; //stringdata + terminating #0
 end; 
 pstringheaderty = ^stringheaderty;
 ppstringheaderty = ^pstringheaderty;

 dynarrayheaderty = record
  ref: refinfoty;
  high: dynarraysizety;
  data: record //data array
  end;
 end;
 pdynarrayheaderty = ^dynarrayheaderty;
 ppdynarrayheaderty = ^pdynarrayheaderty;
 
 openarrayty = record //layout fix
  high: int32;
 {$ifdef mse_compiler}
  data: targetpointerty;
 {$else}
  data: pointer;
 {$endif}
 end;
 popenarrayty = ^openarrayty;

 methodty = record
 {$ifdef mse_compiler}
  code: targetpointerty;
  data: targetpointerty;
 {$else}
  code: pointer;
  data: pointer;
 {$endif}
 end;
 
const
// string8headersize = sizeof(stringheaderty);
 stringheadersize = sizeof(stringheaderty);
 string8allocsize = stringheadersize+1; //terminating #0
 string16allocsize = stringheadersize+2; //terminating #0
 string32allocsize = stringheadersize+4; //terminating #0
 dynarrayheadersize = sizeof(dynarrayheaderty);
 dynarrayallocsize = dynarrayheadersize;

type
// filenamety = string16;

 rttikindty = (rtk_none,rtk_boolean,rtk_integer,rtk_cardinal,rtk_float,
               rtk_pointer,rtk_string,rtk_character,
               rtk_enum,rtk_enumitem,rtk_set,
               rtk_object,
               rtk_property);
const
 ordinalkinds = [rtk_boolean,rtk_integer,rtk_cardinal,rtk_enum];
type
 bitsizety = (bs_none,bs_1,bs_8,bs_16,bs_32,bs_64,bs_po);

 rttity = object
  size: int32;            //0
  kind: rttikindty;       //1
 {$ifdef mse_compiler}
  typename: string8;      //2
 {$else}
  typename: pointer;      //2
  data: record     //*rttity
  end;
 {$endif}
 end;
{$ifdef mse_compiler}
 prttity = targetptrintty;
 pobjectrttity = targetptrintty;
 pcrttity = ^rttity; 
{$else}
 prttity = ^rttity;
 pobjectrttity = ^objectrttity;
{$endif}

const
 classparentindex = 0;
 rttifieldcount = 3;
 classrttidefindex = rttifieldcount + 0;
 listrttifieldcount = 1;
 propertyrttifieldcount = 5;
 datarttifieldcount = 1;

type
 datarttity = object(rttity)
  datasize: bitsizety;
 end;
 pdatarttity = ^datarttity;
  
 intrttity = object(datarttity)  //rtk_integer
  bytesize: int32;   //0
  bitsize: int32;    //1
  min: int64;        //2
  max: int64;        //3
 end;
 pintrttity = ^intrttity;

 cardrttity = object(datarttity) //rtk_cardinal same layout as intrttity!
  bytesize: int32;   //0
  bitsize: int32;    //1
  min: card64;       //2
  max: card64;       //3
 end;
 pcardrttity = ^cardrttity;

 stringkindty = (stk_none,stk_byte,stk_8,stk_16,stk_32); 
 stringrttity = object(datarttity)
  stringkind: stringkindty; //0
 end;
 pstringrttity = ^stringrttity;
 
 enumrttiflagty = (erf_contiguous,erf_ascending);
 enumrttiflagsty = set of enumrttiflagty;

 enumitemrttity = record
  value: int32;
 {$ifdef mse_compiler}
  name: string8;
 {$else}
  name: pointer;
 {$endif}
 end;
{$ifdef mse_compiler}
 penumitemrttity = targetptrintty;
 pcenumitemrttity = ^enumitemrttity; 
{$else}
 penumitemrttity = ^enumitemrttity;
{$endif}

 enumrttity = object(datarttity) //rtk_enum
  itemcount: int32;                   //0
  min: int32;                         //1
  max: int32;                         //2
  flags: enumrttiflagsty;             //3
  items: record end; //array of enumitemrttity
 end;

type
{$ifdef mse_compiler}
 penumrttity = targetptrintty;
 pcenumrttity = ^enumrttity; 
{$else}
 penumrttity = ^enumrttity;
{$endif}

{$ifdef mse_compiler}
 pclassdefty = targetptrintty;
 classdefpoty = ^classdefty;
 classprocty = targetptrintty;
{$else}
 pclassdefty = ^classdefty;
 ppclassdefty = ^pclassdefty;
 procpoty = pointer;
 classprocty = procedure(instance: pointer);
{$endif}

 propertyflagty = (prf_readfield,prf_readproc,prf_virtualread,
                   prf_writefield,prf_writeproc,prf_virtualwrite,
                   prf_writeprocconst);
 propertyflagsty = set of propertyflagty;
 propertyaccessinfoty = record
 {$ifdef mse_compiler}
  case integer of
   0: (fieldoffset: int32);
   1: (accessproc: targetptrintty);
   2: (tableindex: int32);
 {$else}
  (fieldoffset: int32);
  (accessproc: pointer);
  (tableindex: int32);
 {$endif}
 end;
 
 propertyrttity = record
//  kind: rttikindty;                
 {$ifdef msecompiler}
  proptype: targetptrintty;
 {$else}
  proptype: pdatarttity;                 //0
 {$endif}
//  size: bitsizety;                 
  name: pointer;                     //1 const string8
  flags: propertyflagsty;            //2
  readaccess: propertyaccessinfoty;  //3
  writeaccess: propertyaccessinfoty; //4
 end;                                //propertyrttifieldcount
 ppropertyrttity = ^propertyrttity;

 rttilistty = record
  size: int32;                      //0
  items: record //array of rttity
  end;
 end;

 itemlistty = record
  size: int32;                     //0
  items: record //array of record
  end;
 end;
   
 objectrttity = object(rttity)
  classdef: pclassdefty;           //0 -> classrttidefindex
  properties: itemlistty;          //list of propertyrttity
 end;
 
 allocsinfoty = record
  size: int32;
  instanceinterfacestart: int32; //offset in instance record
  classdefinterfacestart: int32; //offset in classdefheaderty
 end;

 classdefprocty = (cdp_ini,cdp_fini,cdp_destruct);

 classdefheaderty = record 
   //layout fix, used in compiler llvmlists.tconsthashdatalist.addclassdef()
  parentclass: pclassdefty;                                              //0
  interfaceparent: pclassdefty;     //last parent class with interfaces  //1
  virttaboffset: int32;             //field offset in instance           //2
  rtti: pobjectrttity;                                                   //3
  procs: array[classdefprocty] of classprocty;  //4             
  allocs: allocsinfoty;                         //4+high(procs)+1
 end;
 pclassdefheaderty = ^classdefheaderty;
 
 classdefty = record
  header: classdefheaderty;                                //0
  virtualmethods: record //array of targetpointer to sub   //4+high(procs)+2
  end;
  interfaces: record     //array of targetpointer to intfdefinfoty,
                         //copied to instance
  end;  
 end;
 
const
 classvirttabindex = 4+ord(high(classdefprocty))+2;
type 
 intfdefheaderty = record
  instanceoffset: int32; //offset from interface pointer to class instance
 end;
 pintfdefheaderty = ^intfdefheaderty;
 
 intfdefinfoty = record
  header: intfdefheaderty;
  items: record          //array of targetpointer to sub
  end;
 end;
 pintfdefinfoty = ^intfdefinfoty;

 valuetypety = (vt_boolean,vt_int32,vt_card32,vt_int64,vt_card64,
                vt_pointer,
                vt_flo64,
                {vt_char8,vt_char16,}vt_char32,
                vt_string8,vt_string16,vt_string32
               );
{$ifdef mse_compiler}
 varrecty32 = record
  vtype: valuetypety;
  vpointer: card32;
 end;
 varrecty64 = record
  vtype: valuetypety;
  vpointer: card64;
 end;
{$else}
 varrecty = record
  vtype: valuetypety;
  (vboolean: boolean);
  (vint32: int32);
  (vcard32: card32);
  (vint64: pint64);
  (vcard64: pcard64);
  (vpointer: pointer);
  (vflo64: pflo64);
//  (vchar8: char8);
//  (vchar16: char16);
  (vchar32: char32);
  (vstring8: pointer);
  (vstring16: pointer);
  (vstring32: pointer);
 end;
 pvarrecty = ^varrecty;
{$endif}
//{$dumpelements}
//{$abort}
implementation

end.
