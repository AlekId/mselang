{ MSElang Copyright (c) 2013-2015 by Martin Schreiber
   
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
unit varhandler;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}

interface
uses
 parserglob;
 
const 
 pointervarkinds = [dk_class,dk_interface];
 
procedure handlevardefstart();
procedure handlevar3();
procedure handlepointervar();

implementation
uses
 handlerutils,elements,errorhandler,handlerglob,opcode,grammar;
 
procedure handlevardefstart();
begin
{$ifdef mse_debugparser}
 outhandle('VARDEFSTART');
{$endif}
 with info,contextstack[s.stackindex] do begin
  d.kind:= ck_var;
  d.vari.indirectlevel:= 0;
//  d.vari.flags:= [];
 end;
end;

procedure handlevar3();
var
 po1: pvardataty;
 po2: pelementinfoty;
 po3: pelementoffsetty;
 datasize1: databitsizety;
 size1: integer;
 ident1: identty;
 ele1: elementoffsetty;
 bo1: boolean;
 i1: int32;
begin
{$ifdef mse_debugparser}
 outhandle('VAR3');
{$endif}
 with info do begin
 {$ifdef mse_checkinternalerror}
  if (s.stacktop-s.stackindex < 3) or 
            (contextstack[s.stacktop].d.kind <> ck_fieldtype) then begin
   internalerror(ie_handler,'20140325B');
  end;
 {$endif}
  for i1:= s.stackindex+2 to s.stacktop - 1 do begin
 {$ifdef mse_checkinternalerror}
   if contextstack[i1].d.kind <> ck_ident then begin
    internalerror(ie_handler,'20150320A0');
   end;
 {$endif}
   ident1:= contextstack[i1].d.ident.ident;
   bo1:= false;
   if (currentcontainer = 0) or not ele.findchild(info.currentcontainer,ident1,
                                                    [],allvisi,ele1) then begin
    if sublevel > 0 then begin
     ele.checkcapacity(elesizes[ek_var]); //no change by addvar
     po3:= @(psubdataty(ele.parentdata)^.varchain);
    end
    else begin
     po3:= @s.unitinfo^.varchain;
    end;
    bo1:= addvar(ident1,allvisi,po3^,po1);
 //   po1:= ele.addelement(ident1,allvisi,ek_var);
   end;
   if not bo1 then begin //duplicate
    identerror(i1-s.stackindex,err_duplicateidentifier);
   end
   else begin
    with po1^ do begin
     address.flags:= [];
     vf.typ:= contextstack[s.stacktop].d.typ.typedata;
     po2:= ele.eleinfoabs(vf.typ);
     address.indirectlevel:= contextstack[s.stacktop].d.typ.indirectlevel;
     with ptypedataty(@po2^.data)^ do begin
 //     address.indirectlevel:= address.indirectlevel+indirectlevel;
      datasize1:= h.datasize;
      if h.kind in pointervarkinds then begin
       inc(address.indirectlevel);
      end;
      if address.indirectlevel = 0 then begin
       size1:= h.bytesize;
       if tf_hasmanaged in h.flags then begin
        include(s.currentstatementflags,stf_hasmanaged);
        include(vf.flags,tf_hasmanaged);
       end;
      end
      else begin
       size1:= pointersize;
      end;
      if sublevel = 0 then begin
       if address.indirectlevel > 0 then begin
        datasize1:= das_pointer;
        include(address.flags,af_segmentpo);
       end;
       address.segaddress:= getglobvaraddress(datasize1,size1,address.flags);
      end
      else begin
       address.locaddress:= getlocvaraddress(datasize1,size1,address.flags,
                                                                  -frameoffset);
      end;
     end;
    end;
   end;
  end;
 end;
end;

procedure handlepointervar();
begin
{$ifdef mse_debugparser}
 outhandle('POINTERVAR');
{$endif}
 with info,contextstack[s.stackindex].d.vari do begin
  if indirectlevel > 0 then begin
   errormessage(err_typeidentexpected,[]);
  end;
  inc(indirectlevel);
 end;
end;

end.
