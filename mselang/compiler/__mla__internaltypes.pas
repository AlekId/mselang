{ MSEgui Copyright (c) 2014-2015 by Martin Schreiber

    See the file COPYING.MSE, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
unit __mla__internaltypes;
//{$internaldebug on}
interface
type
 ppointer = ^pointer;

type
{$ifdef mse_compiler}
 targetptrintty = int32;
 card32 = longword;
 card64 = qword;
{$endif}
 cint = int32;
 
 ptrint = int32;
 pptrint = ^ptrint;
 ptrcard = card32;
 
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
 
 string8headerty = record
  ref: refinfoty;
  len: stringsizety;
  data: record
  end; //stringdata + terminating #0
 end; 
 pstring8headerty = ^string8headerty;

 dynarrayheaderty = record
  ref: refinfoty;
  len: dynarraysizety;
  data: record //data array
  end;
 end;
 pdynarrayheaderty = ^dynarrayheaderty;

const
 string8headersize = sizeof(string8headerty);
 string8allocsize = string8headersize+1; //terminating #0
 dynarrayheadersize = sizeof(dynarrayheaderty);
 dynarrayallocsize = dynarrayheadersize;

type
 allocsinfoty = record
  size: int32;
  instanceinterfacestart: int32; //offset in instance record
  classdefinterfacestart: int32; //offset in classdefheaderty
 end;
{$ifdef mse_compiler}
 pclassdefinfoty = targetptrintty;
 classdefinfopoty = ^classdefinfoty;
{$else}
 pclassdefinfoty = ^classdefinfoty;
{$endif}
 classdefheaderty = record
  parentclass: pclassdefinfoty;
  interfaceparent: pclassdefinfoty; //last parent class with interfaces
  allocs: allocsinfoty;
 end;
 pclassdefheaderty = ^classdefheaderty;
 
 classdefinfoty = record
  header: classdefheaderty;
  virtualmethods: record //array of targetpointer to sub
  end;
  interfaces: record     //array of targetpointer to intfdefinfoty,
                         //copied to instance
  end;  
 end;
 
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

const            //M S E   m l a
 mlaexceptionid = $4d5345006d6c6100;
type
 _Unwind_Reason_Code = (
  _URC_NO_REASON,// = 0,
  _URC_FOREIGN_EXCEPTION_CAUGHT,// = 1,
  _URC_FATAL_PHASE2_ERROR,// = 2,
  _URC_FATAL_PHASE1_ERROR,// = 3,
  _URC_NORMAL_STOP,// = 4,
  _URC_END_OF_STACK,// = 5,
  _URC_HANDLER_FOUND,// = 6,
  _URC_INSTALL_CONTEXT,// = 7,
  _URC_CONTINUE_UNWIND);// = 8

 p_Unwind_Exception = ^_Unwind_Exception;
 _Unwind_Exception_Cleanup_Fn = procedure(reason: _Unwind_Reason_Code;
                                                      exc: p_Unwind_Exception);
 _Unwind_Exception_Class = card64;
 _Unwind_Word = card32;
 _Unwind_Sword = int32;
 
 _Unwind_Exception = record
  exception_class: _Unwind_Exception_Class;
  exception_cleanup: _Unwind_Exception_Cleanup_Fn;
  private_1: _Unwind_Word;
  private_2: _Unwind_Word;
 end;
 exceptinfoty = record
  header: _Unwind_Exception;
  data: pointer;
 end;
 pexceptinfoty = ^exceptinfoty;
 _Unwind_Context = record
 end;
 p_Unwind_Context = ^_Unwind_Context;
 
 _Unwind_Action = cint;
const
 _UA_SEARCH_PHASE = 1;
 _UA_CLEANUP_PHASE = 2;
 _UA_HANDLER_FRAME = 4;
 _UA_FORCE_UNWIND = 8;
 exco_unhandledexception = 217;

implementation
end.
