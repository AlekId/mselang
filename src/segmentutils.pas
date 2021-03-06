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
unit segmentutils;
{$ifdef FPC}{$mode objfpc}{$goto on}{$h+}{$endif}
interface
uses
 globtypes,opglob,msetypes,classes,mclasses;
type
 bufferinfoty = record
  data: pointer;
  toppo: pointer;
  endpo: pointer;
 end;
 pbufferinfoty = ^bufferinfoty;
 unitsegmentinfoty = array[unitsegmentty] of bufferinfoty;
 
 segmentstatety = record
  segment: segmentty;
  data: pointer;
  toppo: pointer;
 end;

 subsegmentstatety = record
  segment: segmentty;
  state: bufferinfoty;
 end;
 subsegmentty = record
  segment: segmentty;
  start: int32;
  size: int32;
 end;
  
  //todo: use inline
const
 mlasignature = ord('M') or (ord('L') shl 8) or (ord('A') shl 16) or
                                                          (ord('0') shl 24);
 mlafileversion = 0;
type
 mlafilekindty = (mlafk_rtunit,mlafk_rtprogram);
const
 filekindstep = 10;
 minsegmentreserve = 32; //at least free bytes at buffer end  

const
 unitsegmentcount = 5;
 unitsegments: array[0..unitsegmentcount-1] of segmentty = 
               (seg_unitintf,seg_unitidents,seg_unitlinks,seg_unitimpl,
                seg_unitconstbuf);
type
 unitsegmentsstatety = array[0..unitsegmentcount-1] of bufferinfoty;

procedure resetbuffer(var abuffer: bufferinfoty);
procedure freebuffer(var abuffer: bufferinfoty);
function allocbufferoffset(var abuffer: bufferinfoty; asize: int32;
                                               out adata: pointer): dataoffsty;
function allocbufferpo(var abuffer: bufferinfoty; asize: int32): pointer;
function getbufferbase(const abuffer: bufferinfoty): pointer;
function getbuffertop(const abuffer: bufferinfoty): pointer;

procedure freesegments(var asegments: unitsegmentinfoty);

function getfilekind(const akind: mlafilekindty): int32;

function allocsegment(const asegment: segmentty;
                                    asize: integer): segaddressty;
function allocsegment(const asegment: segmentty; asize: integer;
                                            out adata: pointer): segaddressty;
function allocsegmentoffset(const asegment: segmentty;
                                    asize: integer): dataoffsty;
function allocsegmentoffset(const asegment: segmentty; asize: integer; 
                                               out adata: pointer): dataoffsty;
function allocsegmentpo(const asegment: segmentty;
                                    asize: integer): pointer;
function allocsegmentpounaligned(const asegment: segmentty;
                                                const asize: integer): pointer;
function allocsegmentpo(const asegment: segmentty;
                                 asize: integer; var buffer: pointer): pointer;
                                                 //relocates buffer
procedure reallocsegment(const address: segaddressty; 
                                oldsize,newsize: int32); 
                                   //for reducing last alloc only
procedure checksegmentcapacity(const asegment: segmentty;
                               asize: integer; var buffer: pointer);
function checksegmentcapacity(const asegment: segmentty;
                                asize: integer): pointer;
                                 //returns alloc top

procedure setsegmenttop(const asegment: segmentty; const atop: pointer);
procedure setsegmenttop(const asegment: segmentty; const atop: dataoffsty);
procedure movesegmenttop(const asegment: segmentty; const adelta: int32);
procedure resetsegment(const asegment: segmentty);
function savesegment(const asegment: segmentty): segmentstatety;
procedure restoresegment(const aseg: segmentstatety);
function getbuffersize(const aseg: segmentstatety): int32;

function getfullsegment(const asegment: segmentty;
                                const offset: int32 = 0): subsegmentty;
function getsubsegment(const asegment: segmentty): subsegmentty;
function setsubsegment(const asubseg: subsegmentty; 
                    const aoffset: int32 = 0): subsegmentstatety;
                                //returns old state, do not change size
procedure restoresubsegment(const aseg: subsegmentstatety);
procedure setsubsegmentsize(var asubseg: subsegmentty);

//procedure setsegment(const aseg: segmentstatety);
//procedure getsegment(out aseg: segmentstatety);
//procedure freesegment(const aseg: segmentstatety);

function getsegmentoffset(const asegment: segmentty;
                                    const apo: pointer): dataoffsty;

function getsegmentpo(const asegment: segmentty;
                                    const aoffset: dataoffsty): pointer;
function getsegmentpo(const asegment: segmentty; const aoffset: dataoffsty; 
                                 const len: int32; out po: pointer): boolean;
                                          //false on error
function getsegmentpo(const aaddress: segaddressty): pointer;
function getsegaddress(const asegment: segmentty;
                             const aaddress: dataoffsty): segaddressty;
function getsegaddress(const asegment: segmentty;
                             const aref: pointer): segaddressty;

function getsegmentbase(const asegment: segmentty): pointer;
function getsegmenttop(const asegment: segmentty): pointer;
function getsegmenttopoffs(const asegment: segmentty): dataoffsty;
function getsegmentsize(const asegment: segmentty): integer;

procedure init();
procedure deinit();

procedure writesegmentdata(const adest: tstream; const akind: int32;
                              const astoredsegments: segmentsty;
                                          const atimestamp: tdatetime);
function readsegmentdata(const asource: tstream; const akind: int32;
                                  const astoredsegments: segmentsty): boolean;
                     //true if ok
function checksegmentdata(const asource: tstream; const akind: int32;
                                const atimestamp: tdatetime): boolean;

procedure resetunitsegments();
procedure saveunitsegments(out state: unitsegmentsstatety);
procedure restoreunitsegments(const state: unitsegmentsstatety);

implementation
uses
 errorhandler,stackops,mseformatstr,msesystypes,msestream,msestrings,parserglob,
 llvmlists,unitglob;

procedure resetbuffer(var abuffer: bufferinfoty);
begin
 with abuffer do begin
  toppo:= data;
 end;
end;

procedure freebuffer(var abuffer: bufferinfoty);
begin
 with abuffer do begin
  if data <> nil then begin
   freemem(data);
   data:= nil;
   toppo:= nil;
   endpo:= nil;
  end;
 end;
end;

procedure topalign(var abuffer: bufferinfoty; const asize: int32); 
                                             {$ifdef mse_inline}inline;{$endif}
begin
 with abuffer do begin
  toppo:= pointer(ptruint((ptruint(toppo)+alignstep-1) and ptruint(alignmask)));
 end;
end;

procedure grow(var abuffer: bufferinfoty; var ref: pointer);
var
 po1: pointer;
 int1: integer;
begin
 with abuffer do begin
  int1:= (toppo-data)*2 + 1024;
  po1:= data;
  reallocmem(data,int1+minsegmentreserve);
  endpo:= data + int1;
  toppo:= toppo + (data - po1);
  ref:= ref + (data - po1);
 end;
end;

function allocbufferoffset(var abuffer: bufferinfoty; asize: int32;
                                               out adata: pointer): dataoffsty;
begin
 with abuffer do begin
  topalign(abuffer,asize);
  adata:= toppo;
  result:= toppo-pointer(data);
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(abuffer,adata);
  end;
 end;
end;

function allocbufferpo(var abuffer: bufferinfoty; asize: int32): pointer;
begin
 allocbufferoffset(abuffer,asize,result);
end;

function getbufferbase(const abuffer: bufferinfoty): pointer;
begin
 result:= abuffer.data;
end;

function getbuffertop(const abuffer: bufferinfoty): pointer;
begin
 result:= abuffer.endpo;
end;

procedure freesegments(var asegments: unitsegmentinfoty);
var
 seg1: segmentty;
begin
 for seg1:= low(asegments) to high(asegments) do begin
  freebuffer(asegments[seg1]);
 end;
end;
 
const
 minsize: array[low(segmentty)..lastdatasegment] of integer = (
//{seg_constdef,}seg_classdef,seg_nil,seg_stack,seg_globvar,seg_globconst,
  {1024,}        1024,        0,      0,        0,          1024,         
//seg_reloc,
  1024,     
//seg_op,{seg_classinfo,}seg_rtti,
  1024,  {1024,}         1024,
//seg_intf,seg_paralloc,{seg_classintfcount,}seg_intfitemcount,
  1024,    1024,        {1024,}              1024,             
//seg_unitintf,seg_unitidents,seg_unitlinks,seg_unitimpl,
  1024,        1024,          1024,         1024,
//seg_unitconstbuf,
  1024,
//seg_temp
  1024);          
  
var
 segmentsx: array[low(segmentty)..lastdatasegment] of bufferinfoty;
 useunitsegments: boolean;
 
function getsegbuffer(const asegment: segmentty): pbufferinfoty; 
                               {$ifndef mse_debugparser}inline;{$endif}
begin
 if not useunitsegments or (asegment > high(unitsegmentty)) then begin
  result:= @segmentsx[asegment];
 end
 else begin
  result:= @info.s.unitinfo^.segments[asegment];
 end;
end;

function getfilekind(const akind: mlafilekindty): int32;
begin
 result:= ord(akind)*filekindstep;
{$ifdef mse_debugparser}
// inc(result); 
{$endif} 
end;

type
 segmentflagty = (shf_load);
 segmentflagsty = set of segmentflagty;
 
 segmentitemty = record
  kind: segmentty;
  flags: segmentflagsty;
  size: int32;
 end;
 
 segmentfileheaderty = record
  signature: card32;
  version: int32;
  kind: int32;
  segmentcount: int32;
  reftimestamp: tdatetime;
 end;
 
 segmentfileinfoty = record
  header: segmentfileheaderty;
  data: record
   //array [segmencount] of segmentitemty;
   //segmentdata
  end;
//  case integer of
//   0: (items: array [segmentty] of segmentitemty);
 end;

procedure writesegmentdata(const adest: tstream; const akind: int32;
                           const astoredsegments: segmentsty;
                           const atimestamp: tdatetime);

 function writedata(const adata; const alen: int32): boolean;
 var
  i1: int32;
 begin
  result:= checksysok(adest.write(adata,alen,i1),err_cannotwritetargetfile,[]);
 end; //writedata
 
var
 info1: segmentfileinfoty;
 segitems: array[segmentty] of segmentitemty;
 seg1: segmentty;
 i1: integer;
begin
 fillchar(info1,sizeof(info1),0);
 with info1.header do begin
  signature:= mlasignature;
  kind:= akind;
  version:= mlafileversion;
  reftimestamp:= atimestamp;
  i1:= 0;
  for seg1:= low(segmentsty) to high(segmentsty) do begin
   if seg1 in astoredsegments then begin
    with segitems[segmentty(i1)] do begin
     kind:= seg1;
     flags:= [shf_load];
     with getsegbuffer(seg1)^ do begin
      size:= toppo - data;
     end;
    end;
    inc(i1);
   end;
  end;
  segmentcount:= i1;
 end;
 if writedata(info1,sizeof(info1)) and 
      writedata(segitems,
                  info1.header.segmentcount*sizeof(segmentitemty)) then begin
  for seg1:= low(segmentsty) to high(segmentsty) do begin
   if seg1 in astoredsegments then begin
    with getsegbuffer(seg1)^ do begin
     if not writedata(data^,toppo-data) then begin
      break;
     end;
    end;
   end;
{
   with info1.items[seg1] do begin
    if shf_load in flags then begin
     if not checksysok(dest.write(segments[seg1].data^,size,int1),
                                    err_cannotwritetargetfile,[]) then begin
      break;
     end;
    end;
   end;
}
  end;  
 end;
end;

function checksegmentdata(const asource: tstream; const akind: int32;
                                        const atimestamp: tdatetime): boolean;
var
 header1: segmentfileheaderty;
 posbefore: int64;
begin
 result:= false;
 posbefore:= asource.position;
 if asource.tryreadbuffer(header1,sizeof(header1)) = sye_ok then begin
  with header1 do begin
   result:= (signature = mlasignature) and (version = mlafileversion) and 
            (kind = akind) and (reftimestamp = atimestamp);
  end;
 end;
 asource.position:= posbefore;
end;

function readsegmentdata(const asource: tstream; const akind: int32;
                        const astoredsegments: segmentsty): boolean;
var
 fna1: filenamety;
 
 function readdata(out adata; const alen: int32): boolean;
 var
  i1: int32;
 begin
  result:= checksysok(asource.read(adata,alen,i1),err_fileread,[fna1],erl_note)
 end; //readdata

 function skipdata(const alen: int32): boolean;
 var
  i1: int64;
 begin
  result:= checksysok(asource.seek(int64(alen),socurrent,i1),
                                              err_fileread,[fna1],erl_note);
 end; //skipdata
 
var
 info1: segmentfileinfoty;
 segitems: array[segmentty] of segmentitemty;
 seg1: segmentty;
 i1: integer;
 segs1: segmentsty;
begin
 result:= false;
 if asource is tmsefilestream then begin
  fna1:= tmsefilestream(asource).filename;
 end
 else begin
  fna1:= '<none>';
 end;
 if readdata(info1,sizeof(info1)) then begin
  with info1.header do begin
   if signature <> mlasignature then begin
    errormessage1(err_wrongsignature,[]);
   end
   else begin
    if kind <> akind then begin
     errormessage1(err_wrongkind,[]);
    end
    else begin
     if version <> mlafileversion then begin
      errormessage1(err_wrongversion,[inttostrmse(version),
                                         inttostrmse(mlafileversion)]);
     end
     else begin
      if (segmentcount <= ord(high(segmentty))+1) and 
            readdata(segitems,segmentcount*sizeof(segmentitemty))then begin
       segs1:= [];
       result:= true;
       for i1:= 0 to segmentcount-1 do begin
        with segitems[segmentty(i1)] do begin
         if (kind in segs1) {or not (kind in storedsegments)} then begin
          result:= false;
          break;
         end;         
         if kind in astoredsegments then begin
          if not readdata(allocsegmentpo(kind,size)^,size) then begin
           result:= false;
           exit;
          end;
          include(segs1,kind);
         end
         else begin
          if not skipdata(size) then begin
           result:= false;
           exit;
          end;
         end;
        end;
       end;
       result:= result and (segs1 = astoredsegments);
       if not result then begin
        errormessage1(err_invalidprogram,[]);
       end;
      end;
     end;
    end;
   end;
  end;
 end;
{    
  if info1.header.version <> 0 then begin
   errormessage1(err_wrongversion,[inttostrmse(info1.header.version),'0']);
  end
  else begin
   segs1:= [];
   for seg1:= low(segmentty) to high(segmentty) do begin
    with info1.items[seg1] do begin
     if shf_load in flags then begin
      if seg1 in segs1 then begin
       errormessage1(err_invalidprogram,[]);
       goto endlab;
      end;
      include(segs1,seg1);
      if not checksysok(source.read(allocsegmentpo(seg1,size)^,size,int1),
                                                 err_fileread,[]) then begin
       goto endlab;
      end;
     end;
    end;
   end;
   if (segs1 * storedsegments <> storedsegments) or 
                       (segs1 - storedsegments <> []) then begin
    errormessage1(err_invalidprogram,[]);
    goto endlab;
   end;
   result:= true;
  end;
}
end;

procedure grow(const asegment: segmentty; var ref: pointer);
var
 po1: pointer;
 int1: integer;
begin
 with getsegbuffer(asegment)^ do begin
  int1:= (toppo-data)*2 + minsize[asegment];
  po1:= data;
  reallocmem(data,int1+minsegmentreserve);
  endpo:= data + int1;
  toppo:= toppo + (data - po1);
  ref:= ref + (data - po1);
 end;
end;

procedure grow(const asegment: segmentty);
var
 po1: pointer;
begin
 grow(asegment,po1);
end;
(*
procedure sizealign(var asize: integer); {$ifdef mse_inline}inline;{$endif}
begin
 asize:= (asize+alignstep-1) and alignmask;
end;
*)
procedure topalign(const asegment: segmentty;
                          const asize: int32); {$ifdef mse_inline}inline;{$endif}
begin
 with getsegbuffer(asegment)^ do begin
  toppo:= pointer(ptruint((ptruint(toppo)+alignstep-1) and ptruint(alignmask)));
 end;
end;

function allocsegment(const asegment: segmentty;
                                    asize: integer): segaddressty;
begin
 with getsegbuffer(asegment)^ do begin
  topalign(asegment,asize);
  result.segment:= asegment;
  result.address:= toppo-pointer(data);
//  sizealign(asize);
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(asegment);
  end;
 end;
end;

procedure reallocsegment(const address: segaddressty; 
                                oldsize,newsize: int32); 
                                   //for reducing last alloc only
begin
// sizealign(oldsize);
// sizealign(newsize);
{$ifdef mse_checkinternalerror}
 if oldsize < newsize then begin
  internalerror(ie_segment,'20170326B');
 end;
{$endif}
 with getsegbuffer(address.segment)^ do begin
  dec(toppo,oldsize-newsize);
 end;
end;

function allocsegment(const asegment: segmentty;
                             asize: integer; out adata: pointer): segaddressty;
begin
 with getsegbuffer(asegment)^ do begin
  topalign(asegment,asize);
  result.segment:= asegment;
  adata:= toppo;
  result.address:= toppo-pointer(data);
//  sizealign(asize);
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(asegment,adata);
//   if adata = nil then begin
//    adata:= data;
//   end;
  end;
 end;
end;

function allocsegmentoffset(const asegment: segmentty;
                                    asize: integer): dataoffsty;
begin
 with getsegbuffer(asegment)^ do begin
  topalign(asegment,asize);
  result:= toppo-pointer(data);
//  sizealign(asize);
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(asegment);
  end;
 end;
end;

function allocsegmentoffset(const asegment: segmentty; asize: integer; 
                                               out adata: pointer): dataoffsty;
begin
 with getsegbuffer(asegment)^ do begin
  topalign(asegment,asize);
  adata:= toppo;
  result:= toppo-pointer(data);
//  sizealign(asize);
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(asegment,adata);
   if adata = nil then begin
    adata:= data;
   end;
  end;
 end;
end;

function allocsegmentpo(const asegment: segmentty;
                                    asize: integer): pointer;
begin
 with getsegbuffer(asegment)^ do begin
  topalign(asegment,asize);
  result:= toppo;
//  sizealign(asize);
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(asegment,result);
  end;
 end;
end;

function allocsegmentpounaligned(const asegment: segmentty;
                                                const asize: integer): pointer;
begin
 with getsegbuffer(asegment)^ do begin
  result:= toppo;
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(asegment,result);
  end;
 end;
end;

function allocsegmentpo(const asegment: segmentty;
                          asize: integer; var buffer: pointer): pointer;
var
 po1: pointer;
begin
 with getsegbuffer(asegment)^ do begin
  topalign(asegment,asize);
  result:= toppo;
//  sizealign(asize);
  inc(toppo,asize);
  if toppo > endpo then begin
   po1:= result;
   grow(asegment,result);
   buffer:= buffer + (result-po1);
  end;
 end;
end;

procedure checksegmentcapacity(const asegment: segmentty;
                               asize: integer; var buffer: pointer);
var
 p1,p2: pointer;
begin
 with getsegbuffer(asegment)^ do begin
  p1:= toppo;
  p2:= data;
  topalign(asegment,asize);
//  sizealign(asize);
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(asegment,buffer);
  end;
  toppo:= p1 + (data-p2);
 end;
end;

function checksegmentcapacity(const asegment: segmentty; 
                                           asize: integer): pointer;
                                 //returns alloc top
var
 p1,p2: pointer;
begin
 with getsegbuffer(asegment)^ do begin
  p1:= toppo;
  p2:= data;
  topalign(asegment,asize);
//  sizealign(asize);
  inc(toppo,asize);
  if toppo > endpo then begin
   grow(asegment);
  end;
  toppo:= p1 + (data-p2);
//  dec(toppo,asize);
  result:= toppo;
 end;
end;
{
function alignsegment(const asegment: segmentty): pointer;
begin
 with segments[asegment] do begin
  toppo:= pointer((ptruint(toppo)+alignstep) and alignmask);
  if toppo > endpo then begin
   grow(asegment);
  end;
  result:= toppo;
 end;
end;

procedure alignsegment(var aaddress:segaddressty);
begin
 with segments[aaddress.segment] do begin
  toppo:= pointer((ptruint(toppo)+alignstep) and alignmask);
  if toppo > endpo then begin
   grow(aaddress.segment);
  end;
 end;
end;
}
procedure setsegmenttop(const asegment: segmentty; const atop: pointer);
begin
 with getsegbuffer(asegment)^ do begin
  toppo:= atop;
 end; 
end;

procedure setsegmenttop(const asegment: segmentty; const atop: dataoffsty);
begin
 with getsegbuffer(asegment)^ do begin
  toppo:= data+atop;
 {$ifdef mse_checkinternalerror}
  if (toppo < data) or (toppo > endpo) then begin
   internalerror(ie_segment,'20170622A');
  end;
 {$endif}
 end; 
end;

procedure movesegmenttop(const asegment: segmentty; const adelta: int32);
begin
 with getsegbuffer(asegment)^ do begin
  toppo:= toppo + adelta;
  if toppo > endpo then begin
   grow(seg_op);
  end;
 {$ifdef mse_checkinternalerror}
  if toppo < data then begin
   internalerror(ie_segment,'20170609B');
  end;
 {$endif}
 end; 
end;

procedure resetsegment(const asegment: segmentty);
begin
 with getsegbuffer(asegment)^ do begin
  toppo:= data;
 end; 
end;

function savesegment(const asegment: segmentty): segmentstatety;
begin
 result.segment:= asegment;
 with getsegbuffer(asegment)^ do begin
  result.data:= data;
  result.toppo:= toppo;
 end;
end;

procedure restoresegment(const aseg: segmentstatety);
begin
 with getsegbuffer(aseg.segment)^ do begin
  toppo:= aseg.toppo + (data-aseg.data);
  if toppo > endpo then begin
   internalerror1(ie_segment,'20150710B'); //invalid size
  end;
 end;
end;

function getbuffersize(const aseg: segmentstatety): int32;
begin
 with getsegbuffer(aseg.segment)^ do begin
  result:= (toppo + (aseg.data-data)) - aseg.toppo;
 end;
end;

function setsubsegment(const asubseg: subsegmentty;
                               const aoffset: int32 = 0): subsegmentstatety; 
                                                 //returns old state
begin
 result.segment:= asubseg.segment;
 result.state:= getsegbuffer(asubseg.segment)^;
 with getsegbuffer(asubseg.segment)^ do begin
  data:= data + asubseg.start+aoffset;
  toppo:= data + asubseg.size-aoffset;
 end;
end;

function getfullsegment(const asegment: segmentty;
                          const offset: int32 = 0): subsegmentty;
begin
 result.segment:= asegment;
 result.start:= offset;
 setsubsegmentsize(result)
end;

function getsubsegment(const asegment: segmentty): subsegmentty;
begin
 result.segment:= asegment;
 with getsegbuffer(asegment)^ do begin
  result.start:= toppo-data;
  result.size:= 0;
 end;
end;

procedure setsubsegmentsize(var asubseg: subsegmentty);
begin
 with getsegbuffer(asubseg.segment)^ do begin
  asubseg.size:= toppo - data - asubseg.start;
 end;
end;

procedure restoresubsegment(const aseg: subsegmentstatety);
begin
 getsegbuffer(aseg.segment)^:= aseg.state;
end;

function getsegmentoffset(const asegment: segmentty;
                                    const apo: pointer): dataoffsty;
begin
 result:= apo - getsegbuffer(asegment)^.data;
end;

function getsegmentpo(const asegment: segmentty;
                                    const aoffset: dataoffsty): pointer;
begin
 result:= getsegbuffer(asegment)^.data + aoffset;
end;

function getsegmentpo(const asegment: segmentty; const aoffset: dataoffsty; 
                                 const len: int32; out po: pointer): boolean;
                                          //false on error
begin
 with getsegbuffer(asegment)^ do begin
  po:= data+aoffset;
  result:= (aoffset >= 0) and (po+len <= toppo);
 end;
end;

function getsegmentpo(const aaddress: segaddressty): pointer;
begin
 result:= getsegbuffer(aaddress.segment)^.data + aaddress.address;
end;

function getsegaddress(const asegment: segmentty;
                             const aaddress: dataoffsty): segaddressty;
begin
 result.segment:= asegment;
 result.address:= aaddress;
end;

function getsegaddress(const asegment: segmentty;
                             const aref: pointer): segaddressty;
begin
 result.segment:= asegment;
 result.address:= aref-getsegbuffer(asegment)^.data;
end;

function getsegmentbase(const asegment: segmentty): pointer;
begin
 result:= getsegbuffer(asegment)^.data;
end;

function getsegmenttop(const asegment: segmentty): pointer;
begin
 result:= getsegbuffer(asegment)^.toppo;
end;

function getsegmenttopoffs(const asegment: segmentty): dataoffsty;
begin
 with getsegbuffer(asegment)^ do begin
  result:= toppo-pointer(data);
 end;
end;

function getsegmentsize(const asegment: segmentty): integer;
begin
 with getsegbuffer(asegment)^ do begin
  result:= toppo-pointer(data);
 end;
end;

procedure resetunitsegments();
var
 i1: int32;
begin
 for i1:= 0 to high(unitsegments) do begin
  resetsegment(unitsegments[i1]);
 end;
end;

procedure saveunitsegments(out state: unitsegmentsstatety);
var
 i1: int32;
 po1: pbufferinfoty;
begin
 for i1:= 0 to high(state) do begin
  po1:= getsegbuffer(unitsegments[i1]);
  state[i1]:= po1^;
  with po1^ do begin
   data:= nil;
   toppo:= nil;
   endpo:= nil;
  end;   
 end;
end;

procedure restoreunitsegments(const state: unitsegmentsstatety);
var
 i1: int32;
 po1: pbufferinfoty;
begin
 for i1:= 0 to high(state) do begin
  po1:= getsegbuffer(unitsegments[i1]);
  if po1^.data <> nil then begin
   freemem(po1^.data);
  end;
  po1^:= state[i1];
 end;
end;

procedure dofinalize();
var
 seg1: segmentty;
begin
 for seg1:= low(segmentty) to lastdatasegment do begin
  with segmentsx[seg1] do begin
   if data <> nil then begin
    freemem(data);
   end;
  end;
 end;
end;

procedure init();
begin
 dofinalize();
 fillchar(segmentsx,sizeof(segmentsx),0);
 useunitsegments:= co_modular in info.o.compileoptions;
{
 with plocallocinfoty(allocsegmentpo(seg_localloc,
                                   sizeof(locallocinfoty)))^ do begin
  address:= 0;
  flags:= [];
  size:= bitoptypes[das_pointer];
  if (info.debugoptions <> []) and (co_llvm in compileoptions) then begin
   debuginfo:= 
  end
  else begin
   debuginfo:= dummymeta;
  end;
 end;
}
end;

procedure deinit();
begin
 //dummy
end;
 
finalization
 dofinalize();
end.
