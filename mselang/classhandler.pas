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
unit classhandler;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 parserglob;

type
 classdefheaderty = record
  allocsize: integer;
  fieldsize: integer;
  parentclass: dataoffsty;
 end;
 classdefinfoty = record
  header: classdefheaderty;
  virtualmethods: record //array of opaddressty
  end;
 end;
 pclassdefinfoty = ^classdefinfoty;
 
const 
 virtualtableoffset = sizeof(classdefheaderty);

procedure copyvirtualtable(const source,dest: segaddressty;
                                                 const itemcount: integer);

procedure handleclassdefstart();
procedure handleclassdeferror();
procedure handleclassdefreturn();
procedure handleclassdefparam2();
procedure handleclassdefparam3a();
procedure handleclassprivate();
procedure handleclassprotected();
procedure handleclasspublic();
procedure handleclasspublished();
procedure handleclassfield();
procedure handlemethfunctionentry();
procedure handlemethprocedureentry();
procedure handlemethconstructorentry();
procedure handlemethdestructorentry();
procedure handleconstructorentry();
procedure handledestructorentry();

implementation
uses
 elements,handler,errorhandler,unithandler,grammar,handlerglob,handlerutils,
 parser,typehandler,opcode,subhandler,segmentutils,interfacehandler;
{
const
 vic_private = vis_3;
 vic_protected = vis_2;
 vic_public = vis_1;
 vic_published = vis_0;
}
{
procedure classesscopeset();
var
 po2: pclassesdataty;
begin
 po2:= @pelementinfoty(
          ele.eleinfoabs(info.unitinfo^.classeselement))^.data;
 po2^.scopebefore:= ele.elementparent;
 ele.elementparent:= info.unitinfo^.classeselement;
end;

procedure classesscopereset();
var
 po2: pclassesdataty;
begin
 po2:= @pelementinfoty(
          ele.eleinfoabs(info.unitinfo^.classeselement))^.data;
 ele.elementparent:= po2^.scopebefore;
end;
}
procedure copyvirtualtable(const source,dest: segaddressty;
                                                 const itemcount: integer);
var
 ps,pd,pe: popaddressty;
begin
 ps:= getsegmentpo(seg_globconst,source.address + virtualtableoffset);
 pd:= getsegmentpo(seg_globconst,dest.address + virtualtableoffset);
 pe:= pd+itemcount;
 while pd < pe do begin
  if pd^ = 0 then begin
   pd^:= ps^;
  end;
  inc(ps);
  inc(pd);
 end;
end;

procedure handleclassdefstart();
var
 po1: ptypedataty;
 id1: identty;

begin
{$ifdef mse_debugparser}
 outhandle('CLASSDEFSTART');
{$endif}
 with info do begin
 {$ifdef mse_checkinternalerror}
  if stackindex < 3 then begin
   internalerror(ie_handler,'20140325D');
  end;
 {$endif}
  include(currentstatementflags,stf_classdef);
  if sublevel > 0 then begin
   errormessage(err_localclassdef,[]);
  end;
  with contextstack[stackindex] do begin
   d.kind:= ck_classdef;
   d.cla.visibility:= classpublishedvisi;
   d.cla.fieldoffset:= pointersize; //pointer to virtual methodtable
   d.cla.virtualindex:= 0;
  end;
  with contextstack[stackindex-2] do begin
   if (d.kind = ck_ident) and 
                  (contextstack[stackindex-1].d.kind = ck_typetype) then begin
    id1:= d.ident.ident; //typedef
   end
   else begin
    errormessage(err_anonclassdef,[]);
    exit;
   end;
  end;
  contextstack[stackindex].b.eleparent:= ele.elementparent;
  with contextstack[stackindex-1] do begin
   if not ele.pushelement(id1,globalvisi,ek_type,d.typ.typedata) then begin
    identerror(stacktop-stackindex,err_duplicateidentifier,erl_fatal);
   end;
   currentcontainer:= d.typ.typedata;
   po1:= ele.eledataabs(currentcontainer);
   inittypedatasize(po1^,dk_class,d.typ.indirectlevel,das_pointer);
   with po1^ do begin
   {
    kind:= dk_class;
    bytesize:= pointersize;
    bitsize:= pointersize*8;
    datasize:= das_pointer;
    ancestor:= 0;
    }
    fieldchain:= 0;
    infoclass.impl:= 0;
    infoclass.defs.address:= 0;
    infoclass.flags:= [];
    infoclass.pendingdescends:= 0;
    infoclass.interfacecount:= 0;
    infoclass.interfacechain:= 0;
    infoclass.interfacesubcount:= 0;
   end;
  end;
 end;
end;

procedure classheader(const ainterface: boolean);
var
 po1,po2: ptypedataty;
 po3: pclassintfdataty;
begin
 with info do begin
  po1:= ele.eledataabs(currentcontainer);
  ele.checkcapacity(ek_classintf);
  ele.pushelementparent();
  ele.decelementparent(); //interface or implementation
  if findkindelementsdata(1,[ek_type],allvisi,po2) then begin
   if ainterface then begin
    if po2^.kind <> dk_interface then begin
     errormessage(err_interfacetypeexpected,[]);
    end
    else begin
     ele.popelementparent;
     if ele.addelementduplicatedata(
           contextstack[stackindex+1].d.ident.ident,
           [vik_global],ek_classintf,po3,allvisi-[vik_ancestor]) then begin
      with po3^ do begin
       intftype:= ele.eledatarel(po2);
       next:= po1^.infoclass.interfacechain;
       po1^.infoclass.interfacechain:= ele.eledatarel(po3);
      end;
     end
     else begin
      identerror(1,err_duplicateidentifier);
     end;
     exit;
    end;
   end
   else begin
    if po2^.kind <> dk_class then begin
     errormessage(err_classtypeexpected,[]);
    end
    else begin
     po1^.ancestor:= ele.eledatarel(po2);
     po1^.infoclass.interfacecount:= po2^.infoclass.interfacecount;
     po1^.infoclass.interfacesubcount:= po2^.infoclass.interfacesubcount;
     with contextstack[stackindex-2] do begin
      d.cla.fieldoffset:= po2^.infoclass.allocsize;
      d.cla.virtualindex:= po2^.infoclass.virtualcount;
     end;
    end;
   end;
  end;
  ele.popelementparent;
 end;
end;

procedure handleclassdefparam2();
begin
{$ifdef mse_debugparser}
 outhandle('CLASSDEFPARAM2');
{$endif}
 classheader(false); //ancestordef
end;

procedure handleclassdefparam3a();
begin
{$ifdef mse_debugparser}
 outhandle('CLASSDEFPARAM3A');
{$endif}
 classheader(true); //interfacedef
 with info do begin
//  dec(stackindex);
 end;
end;

function checkinterface(const instanceshift: integer;
                               const ainterface: pclassintfdataty): dataoffsty;
             //todo: name alias, delegation end the like

type
 scaninfoty = record
  intfele: elementoffsetty;
  sub: pintfitemty;
  seg: segaddressty;
 end;
              
 procedure dointerface(var scaninfo: scaninfoty);
 var
  intftype: ptypedataty;
  ele1: elementoffsetty;
  po1: pelementinfoty;
  po2: psubdataty;
  po3: pintfancestordataty;
 begin
  with scaninfo do begin
   intftype:= ele.eledataabs(intfele);
   ele1:= intftype^.infointerface.subchain;
   while ele1 <> 0 do begin
    dec(sub);
    dec(seg.address,sizeof(intfitemty));
    po1:= ele.eleinfoabs(ele1);
                    //todo: overloaded subs
    if (ele.findcurrent(po1^.header.name,[ek_sub],allvisi,po2) <> ek_sub)
                                or not checkparams(@po1^.data,po2) then begin
               //todo: compose parameter message
     errormessage(err_nomatchingimplementation,[
         getidentname(ele.eleinfoabs(ainterface^.intftype)^.header.name)+'.'+
         getidentname(po1^.header.name)]);
    end
    else begin
     if po2^.address = 0 then begin
      linkmark(po2^.links,seg);
     end
     else begin
      sub^.subad:= po2^.address;
     end;
    end;
    sub^.instanceshift:= instanceshift;
    ele1:= psubdataty(@po1^.data)^.next;
   end;
   ele1:= intftype^.infointerface.ancestorchain;
   while ele1 <> 0 do begin
    po3:= ele.eledataabs(ele1);
    intfele:= po3^.intftype;
    dointerface(scaninfo);
    ele1:= po3^.next;
   end;
  end;
 end;
 
var
 intftypepo: ptypedataty;
 int1: integer;
 scaninfo: scaninfoty;
 
begin
 scaninfo.intfele:= ainterface^.intftype;
 intftypepo:= ptypedataty(ele.eledataabs(scaninfo.intfele));
 int1:= intftypepo^.infointerface.subcount*sizeof(intfitemty);
 result:= allocsegmentoffset(seg_intf,int1);
 with scaninfo do begin
  seg.address:= result+int1;       //top-down
  sub:= getsegmentpo(seg_intf,seg.address);
  seg.segment:= seg_intf;
 end;
 dointerface(scaninfo); 
end;

//class instance layout:
// header, pointer to virtual table
// fields
// interface table  <- fieldsize
//                  <- allocsize

procedure handleclassdefreturn();
var
// po2: pclassesdataty;
 ele1: elementoffsetty;
 classdefs1: segaddressty;
 classinfo1: pclassinfoty;
 parentinfoclass1: pinfoclassty;
 intfcount: integer;
 intfsubcount: integer;
 fla1: addressflagsty;
 int1: integer;
 
begin
{$ifdef mse_debugparser}
 outhandle('CLASSDEFRETURN');
{$endif}
 with info do begin
  exclude(currentstatementflags,stf_classdef);
  with contextstack[stackindex-1],ptypedataty(ele.eledataabs(
                                                d.typ.typedata))^ do begin
   regclass(d.typ.typedata);
   flags:= d.typ.flags;
   indirectlevel:= d.typ.indirectlevel;
   classinfo1:= @contextstack[stackindex].d.cla;

                     
   intfcount:= 0;
   intfsubcount:= 0;
   ele1:= infoclass.interfacechain;
   while ele1 <> 0 do begin          //count interfaces
    with pclassintfdataty(ele.eledataabs(ele1))^ do begin
     intfsubcount:= intfsubcount + 
            ptypedataty(ele.eledataabs(intftype))^.infointerface.subcount;
     ele1:= next;
    end;
    inc(intfcount);
   end;
   infoclass.interfacecount:= infoclass.interfacecount + intfcount;
   infoclass.interfacesubcount:= infoclass.interfacesubcount + intfsubcount;

         //alloc classinfo
   infoclass.allocsize:= classinfo1^.fieldoffset + 
          infoclass.interfacecount*pointersize;
   infoclass.virtualcount:= classinfo1^.virtualindex;
   classdefs1:= getglobconstaddress(sizeof(classdefinfoty)+
                                   pointersize*infoclass.virtualcount,fla1);
   infoclass.defs:= classdefs1;   
   with pclassdefinfoty(getsegmentpo(classdefs1))^ do begin
    header.allocsize:= infoclass.allocsize;
    header.fieldsize:= classinfo1^.fieldoffset;
    header.parentclass:= 0;
    if ancestor <> 0 then begin 
     parentinfoclass1:= @ptypedataty(ele.eledataabs(ancestor))^.infoclass;
     header.parentclass:= parentinfoclass1^.defs.address; //todo: relocate
     if parentinfoclass1^.virtualcount > 0 then begin
      fillchar(virtualmethods,parentinfoclass1^.virtualcount*pointersize,0);
      if icf_virtualtablevalid in parentinfoclass1^.flags then begin
       copyvirtualtable(infoclass.defs,classdefs1,
                                       parentinfoclass1^.virtualcount);
      end
      else begin
       regclassdescendent(d.typ.typedata,ancestor);
      end;
     end;
    end;
   end;
   ele1:= ele.addelementduplicate1(tks_classimp,globalvisi,ek_classimp);
   ptypedataty(ele.eledataabs(d.typ.typedata))^.infoclass.impl:= ele1;
              //possible capacity change
    
    //todo: init instance interface table
              
   if intfcount <> 0 then begin       //alloc interface table
    int1:= -infoclass.allocsize;
    ele1:= infoclass.interfacechain;
    while ele1 <> 0 do begin
     dec(int1,pointersize);
     checkinterface(int1,ele.eledataabs(ele1));
     ele1:= pclassintfdataty(ele.eledataabs(ele1))^.next;
    end;
   end;
  end;
  ele.elementparent:= contextstack[stackindex].b.eleparent;
  currentcontainer:= 0;
 end;
end;

procedure handleclassdeferror();
begin
{$ifdef mse_debugparser}
 outhandle('CLASSDEFERROR');
{$endif}
 tokenexpectederror(tk_end);
end;

procedure handleclassprivate();
begin
{$ifdef mse_debugparser}
 outhandle('CLASSPRIVATE');
{$endif}
 with info,contextstack[stackindex] do begin
  d.cla.visibility:= classprivatevisi;
 end;
end;

procedure handleclassprotected();
begin
{$ifdef mse_debugparser}
 outhandle('CLASSPROTECTED');
{$endif}
 with info,contextstack[stackindex] do begin
  d.cla.visibility:= classprotectedvisi;
 end;
end;

procedure handleclasspublic();
begin
{$ifdef mse_debugparser}
 outhandle('CLASSPUBLIC');
{$endif}
 with info,contextstack[stackindex] do begin
  d.cla.visibility:= classpublicvisi;
 end;
end;

procedure handleclasspublished();
begin
{$ifdef mse_debugparser}
 outhandle('CLASSPUBLISHED');
{$endif}
 with info,contextstack[stackindex] do begin
  d.cla.visibility:= classpublishedvisi;
 end;
end;

procedure handleclassfield();
var
 po1: pvardataty;
 po2: ptypedataty;
 ele1: elementoffsetty;
begin
{$ifdef mse_debugparser}
 outhandle('CLASSFIELD');
{$endif}
 with info,contextstack[stackindex-1] do begin
  checkrecordfield(d.cla.visibility,[af_classfield],d.cla.fieldoffset,
                                   contextstack[stackindex-2].d.typ.flags);
 end;
end;

procedure handlemethprocedureentry();
begin
{$ifdef mse_debugparser}
 outhandle('METHPROCEDUREENTRY');
{$endif}
 with info,contextstack[stackindex].d do begin
  kind:= ck_subdef;
  subdef.flags:= [sf_header,sf_method];
 end;
end;

procedure handlemethfunctionentry();
begin
{$ifdef mse_debugparser}
 outhandle('METHFUNCTIONENTRY');
{$endif}
 with info,contextstack[stackindex].d do begin
  kind:= ck_subdef;
  subdef.flags:= [sf_function,sf_header,sf_method];
 end;
end;

procedure handlemethconstructorentry();
begin
{$ifdef mse_debugparser}
 outhandle('METHCONSTRUCTORENTRY');
{$endif}
 with info,contextstack[stackindex].d do begin
  kind:= ck_subdef;
  subdef.flags:= [sf_header,sf_method,sf_constructor];
 end;
end;

procedure handlemethdestructorentry();
begin
{$ifdef mse_debugparser}
 outhandle('METHDESTRUCTORENTRY');
{$endif}
 with info,contextstack[stackindex].d do begin
  kind:= ck_subdef;
  subdef.flags:= [sf_header,sf_method,sf_destructor];
 end;
end;

procedure handleconstructorentry();
begin
{$ifdef mse_debugparser}
 outhandle('CONSTRUCTORENTRY');
{$endif}
 with info,contextstack[stackindex].d do begin
  kind:= ck_subdef;
  subdef.flags:= [sf_method,sf_constructor];
 end;
end;

procedure handledestructorentry();
begin
{$ifdef mse_debugparser}
 outhandle('DESTRUCTORENTRY');
{$endif}
 with info,contextstack[stackindex].d do begin
  kind:= ck_subdef;
  subdef.flags:= [sf_method,sf_destructor];
 end;
end;

end.
