{ MSElang Copyright (c) 2015 by Martin Schreiber
   
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
unit rtunitwriter;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 parserglob,rtunitglob;
  
function writeunitfile(const aunit: punitinfoty): boolean; //true if ok

implementation
uses
 elements,segmentutils,globtypes,errorhandler,msestrings,handlerglob,msestream,
 msefileutils,msesys,msesystypes,filehandler,handlerutils,identutils,
 sysutils;
{
type
 unitrecheaderty = record
  kind: elementkindty;
  size: int32;
 end;
 punitrecheaderty = ^unitrecheaderty;
 
 unitrecty = record
  header: unitrecheaderty;
  data: record
  end;
 end;
 punitrecty = ^unitrecty;
} 

type
 identbufferdataty = record
  header: identheaderty;
  nameindex: int32;
 end;
 pidentbufferdataty = ^identbufferdataty;
 
 tidentlist = class(tidenthashdatalist)
  private
  public
   constructor create();
 end;

{ tidentlist }

constructor tidentlist.create;
begin
 inherited create(sizeof(identbufferdataty));
end;
 
function putunit(const aunit: punitinfoty): boolean; 
//true if ok
var
 s1,s2: ptrint;
 ps,pd,pe: pelementinfoty;
 identlist: tidentlist;
 po2: punitintfinfoty;
 po: pointer;
 nameindex1,anonindex1: int32;
 elestart,eleend: elementoffsetty;
 deststart: pointer;

 function updateident(const aident: identty): identty;
 var
  po1: pidentbufferdataty;
  lstr1: lstringty;
 begin
  if identlist.adduniquedata(aident,po1) then begin
   if getidentname(aident,lstr1) then begin
    with pidentstringty(allocsegmentpounaligned(seg_unitidents,
                       lstr1.len + sizeof(identstringty)))^ do begin
     len:= lstr1.len;
     move(lstr1.po^,data,lstr1.len);
    end;
    po1^.nameindex:= nameindex1;
    inc(nameindex1);
   end
   else begin
    po1^.nameindex:= anonindex1;
    dec(anonindex1);
   end;
  end;
  result:= po1^.nameindex;
 end; //updateident

 procedure putdata(var po: pointer; const adata: unitinfopoarty);
 var
  pd,pe: pidentty;
  ps: ppunitinfoty;
 begin
  pint32(po)^:= length(adata);
  pd:= pointer(pint32(po)+1);
  pe:= pd+length(adata);
  ps:= pointer(adata);
  while pd < pe do begin
   pd^:= updateident(ps^^.key);
   inc(ps);
   inc(pd);
  end;
  po:= pe;
 end; //putdata

 procedure updateref(var ref: elementoffsetty);
          //>= 0 -> relative offset, -seg_unitlinks offset - 1 otherwise
 var
  po1: punitlinkty;
  po2,pe: pidentty;
  po3: pelementinfoty;
  i1: int32;
 begin
  if (ref >= elestart) and (ref < eleend) then begin
   ref:= ref - elestart;
  end
  else begin //not in streamed segment
   po1:= checksegmentcapacity(seg_unitlinks,sizeof(unitlinkty) +
                            (maxidentvector+1)*sizeof(identty));
//   po1^.dest:= @ref-deststart;
   po2:= @po1^.ids;
   po3:= ele.eleinfoabs(ref);
   while true do begin
    po2^:= updateident(po3^.header.name);
    inc(po2);
    if po3^.header.parentlevel <= 0 then begin
     break;
    end;
    po3:= ele.eleinfoabs(po3^.header.parent);
   end;
   po1^.len:= po2 - pidentty(@po1^.ids);
   setsegmenttop(seg_unitlinks,po2);
   ref:= -getsegmentoffset(seg_unitlinks,po1)-1;
  end;
 end;

 procedure puteledata(ps,pd: pelementinfoty; const s1: int32);
 var
  pe: pelementinfoty;
 begin
  move(ps^,pd^,s1);
  deststart:= pd;
  pe:= pointer(pd) + s1;
  while pd < pe do begin
   with pd^ do begin
    header.name:= updateident(header.name);
   {$ifdef mse_debugparser}
    dec(header.next,elestart);
   {$endif}
    updateref(header.parent);
    po:= @data;
    case header.kind of
     ek_type: begin
      with ptypedataty(po)^ do begin
      end;
     end;
     ek_field: begin
      with pfielddataty(po)^ do begin
      end;
     end;
     ek_var: begin
      with pvardataty(po)^ do begin
      end;
     end;
     ek_const: begin
      with pconstdataty(po)^ do begin
      end;
     end;
     ek_ref: begin
      with prefdataty(po)^ do begin
      end;
     end;
     ek_sub: begin
      with psubdataty(po)^ do begin
       inc(pointer(pd),paramcount*sizeof(elementoffsetty));
      end;
     end;
     ek_unit: begin
     end;
     ek_uses: begin
     end;
     ek_implementation: begin
      with pimplementationdataty(po)^ do begin
      end;
     end;
     ek_none: begin
     end;
     else begin
      internalerror1(ie_module,'20150523A');
     end;
    end;
    inc(pointer(pd),elesizes[header.kind]);
   end;
  end;
 end; //puteledata

begin
 result:= false;
 elestart:= aunit^.interfacestart.bufferref;
 s1:= aunit^.implementationstart.bufferref - aunit^.interfacestart.bufferref;
 eleend:= elestart + s1;
 s2:= 2*sizeof(lenidentty) + 
       (length(aunit^.interfaceuses)+length(aunit^.implementationuses)) * 
                                                               sizeof(identty);
 resetunitsegments();
 
 po2:= allocsegmentpo(seg_unitintf,sizeof(unitintfheaderty)+s1+s2);
 nameindex1:= 0;
 anonindex1:= -1;
 identlist:= tidentlist.create;
 try
  updateident(idstart);
  with po2^ do begin
   header.key:= updateident(aunit^.key);
   header.mainad:= aunit^.mainad; //todo: relocate
   header.interfaceglobstart:= aunit^.interfaceglobstart;
   header.interfaceglobsize:= aunit^.interfaceglobsize;
   header.implementationglobstart:= aunit^.implementationglobstart;
   header.implementationglobsize:= aunit^.implementationglobsize;
   po:= @interfaceuses;
   putdata(po,aunit^.interfaceuses);
   putdata(po,aunit^.implementationuses);
   pd:= po;
  end;
  ps:= ele.eleinfoabs(elestart);
  puteledata(ps,pd,s1);
  with po2^.header do begin
   sourcetimestamp:= aunit^.filetimestamp;
   namecount:= nameindex1;
   anoncount:= -anonindex1 - 1;
  end;
  result:= true;
 finally
  identlist.destroy();
 end;
end;

function writeunitfile(const aunit: punitinfoty): boolean; //true if ok
var
 stat1: subsegmentstatety;
 stream1: tmsefilestream;
 fna1: filenamety;
begin
 result:= putunit(aunit);
 if result then begin
  fna1:= getrtunitfilename(aunit^.filepath);
  if tmsefilestream.trycreate(stream1,fna1,fm_create) = sye_ok then begin
   stat1:= setsubsegment(aunit^.opseg);
   writesegmentdata(stream1,getfilekind(mlafk_rtunit),
            [seg_unitintf,seg_unitidents,seg_unitlinks,seg_op],
                                                     aunit^.filetimestamp);
                               //todo: complete 
   restoresubsegment(stat1);
   stream1.destroy();
  end
  else begin
   filewriteerror(fna1);
  end;
 end;
 resetunitsegments();
end;

end.