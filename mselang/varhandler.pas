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
 with info,contextstack[stackindex] do begin
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
 size1: integer;
 ident1: identty;
 ele1: elementoffsetty;
 bo1: boolean;
begin
{$ifdef mse_debugparser}
 outhandle('VAR3');
{$endif}
 with info do begin
 {$ifdef mse_checkinternalerror}
  if (stacktop-stackindex < 2) or 
            (contextstack[stackindex+2].d.kind <> ck_fieldtype) then begin
   internalerror(ie_handler,'20140325B');
  end;
 {$endif}
  ident1:= contextstack[stackindex+1].d.ident.ident;
  bo1:= false;
  if (currentcontainer = 0) or not ele.findchild(info.currentcontainer,ident1,
                                                   [],allvisi,ele1) then begin
   if sublevel > 0 then begin
    ele.checkcapacity(elesizes[ek_var]); //no change by addvar
    po3:= @(psubdataty(ele.parentdata)^.varchain);
   end
   else begin
    po3:= @unitinfo^.varchain;
   end;
   bo1:= addvar(ident1,allvisi,po3^,po1);
//   po1:= ele.addelement(ident1,allvisi,ek_var);
  end;
  if not bo1 then begin //duplicate
   identerror(1,err_duplicateidentifier);
  end
  else begin
   with po1^ do begin
    address.flags:= [];
    vf.typ:= contextstack[stackindex+2].d.typ.typedata;
    po2:= ele.eleinfoabs(vf.typ);
    address.indirectlevel:= contextstack[stackindex+2].d.typ.indirectlevel;
    with ptypedataty(@po2^.data)^ do begin
     address.indirectlevel:= address.indirectlevel+indirectlevel;
     if kind in pointervarkinds then begin
      inc(address.indirectlevel);
     end;
     if address.indirectlevel = 0 then begin
      size1:= bytesize;
      if tf_hasmanaged in flags then begin
       include(currentstatementflags,stf_hasmanaged);
       include(vf.flags,tf_hasmanaged);
      end;
     end
     else begin
      size1:= pointersize;
     end;
     if sublevel = 0 then begin
      address.segaddress:= getglobvaraddress(size1,address.flags);
      if address.indirectlevel > 0 then begin
       address.segaddress.size:= 0;
      end
      else begin
       if not (datasize in databytesizes) then begin
        address.segaddress.size:= -bitsize;
       end;
      end;
     end
     else begin
      address.locaddress:= getlocvaraddress(size1,address.flags,-frameoffset);
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
 with info,contextstack[stackindex].d.vari do begin
  if indirectlevel > 0 then begin
   errormessage(err_typeidentexpected,[]);
  end;
  inc(indirectlevel);
 end;
end;

end.
