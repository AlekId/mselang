unit main;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 mseglob,mseguiglob,mseguiintf,mseapplication,msestat,msemenus,msegui,
 msegraphics,msegraphutils,mseevent,mseclasses,mseforms,msedataedits,mseedit,
 mseifiglob,msestrings,msetypes,msestatfile,msesimplewidgets,msewidgets,msegrids;

type
 tmainfo = class(tmainform)
   ed: tmemoedit;
   tstatfile1: tstatfile;
   tbutton1: tbutton;
   grid: tstringgrid;
   procedure parseexe(const sender: TObject);
 end;
var
 mainfo: tmainfo;
  
implementation
uses
 main_mfm,mseexpint,msestream;
 
procedure tmainfo.parseexe(const sender: TObject);
var
 ar1: stringarty;
 stream1: ttextstream;
begin
 writeln('*****************************************');
 stream1:= ttextstream.create;
 parse(ed.value,stream1);
 stream1.position:= 0;
 grid[0].datalist.loadfromstream(stream1);
 stream1.free;
end;

end.
