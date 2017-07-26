{ MSElang Copyright (c) 2013-2017 by Martin Schreiber
   
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
unit grammarglob;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 globtypes,parserglob,elements;
 
const
 tks_none = 0;
 tks_void = $00000201;
 tks_classes = $00000202;
 tks_private = $00000203;
 tks_protected = $00000204;
 tks_public = $00000205;
 tks_published = $00000206;
 tks_classintfname = $00000207;
 tks_classintftype = $00000208;
 tks_classimp = $00000209;
 tks_objpotype = $0000020A;
 tks_self = $0000020B;
 tks_units = $0000020C;
 tks_ancestors = $0000020D;
 tks_nestedvarref = $0000020E;
 tks_defines = $0000020F;
 tks_ini = $00000210;
 tks_fini = $00000211;
 tks_incref = $00000212;
 tks_decref = $00000213;
 tks_decrefindi = $00000214;
 tks_destroy = $00000215;
 tks_method = $00000216;
 tks_operators = $00000217;
 tks_operatorsright = $00000218;
 tks_system = $00000219;
 tk_mselang = $0000021A;
 tk_pascal = $0000021B;
 tk_nil = $0000021C;
 tk_result = $0000021D;
 tk_exitcode = $0000021E;
 tk_sizeof = $0000021F;
 tk_defined = $00000220;
 tk_break = $00000221;
 tk_continue = $00000222;
 tk_self = $00000223;
 tk_b = $00000224;
 tk_booleval = $00000225;
 tk_internaldebug = $00000226;
 tk_nozeroinit = $00000227;
 tk_zeroinit = $00000228;
 tk_virtual = $00000229;
 tk_except = $0000022A;
 tk_end = $0000022B;
 tk_afterconstruct = $0000022C;
 tk_beforedestruct = $0000022D;
 tk_ini = $0000022E;
 tk_fini = $0000022F;
 tk_operator = $00000230;
 tk_operatorright = $00000231;
 tk_default = $00000232;
 tk_unit = $00000233;
 tk_program = $00000234;
 tk_interface = $00000235;
 tk_implementation = $00000236;
 tk_uses = $00000237;
 tk_type = $00000238;
 tk_const = $00000239;
 tk_var = $0000023A;
 tk_label = $0000023B;
 tk_class = $0000023C;
 tk_procedure = $0000023D;
 tk_function = $0000023E;
 tk_method = $0000023F;
 tk_initialization = $00000240;
 tk_finalization = $00000241;
 tk_constructor = $00000242;
 tk_destructor = $00000243;
 tk_begin = $00000244;
 tk_mode = $00000245;
 tk_dumpelements = $00000246;
 tk_dumpopcode = $00000247;
 tk_abort = $00000248;
 tk_stoponerror = $00000249;
 tk_nop = $0000024A;
 tk_include = $0000024B;
 tk_define = $0000024C;
 tk_undef = $0000024D;
 tk_ifdef = $0000024E;
 tk_ifndef = $0000024F;
 tk_if = $00000250;
 tk_else = $00000251;
 tk_endif = $00000252;
 tk_ifend = $00000253;
 tk_h = $00000254;
 tk_inline = $00000255;
 tk_on = $00000256;
 tk_off = $00000257;
 tk_constref = $00000258;
 tk_out = $00000259;
 tk_override = $0000025A;
 tk_overload = $0000025B;
 tk_of = $0000025C;
 tk_object = $0000025D;
 tk_external = $0000025E;
 tk_forward = $0000025F;
 tk_sub = $00000260;
 tk_finally = $00000261;
 tk_do = $00000262;
 tk_with = $00000263;
 tk_case = $00000264;
 tk_while = $00000265;
 tk_repeat = $00000266;
 tk_for = $00000267;
 tk_try = $00000268;
 tk_raise = $00000269;
 tk_goto = $0000026A;
 tk_then = $0000026B;
 tk_until = $0000026C;
 tk_to = $0000026D;
 tk_downto = $0000026E;
 tk_set = $0000026F;
 tk_packed = $00000270;
 tk_record = $00000271;
 tk_array = $00000272;
 tk_private = $00000273;
 tk_protected = $00000274;
 tk_public = $00000275;
 tk_published = $00000276;
 tk_property = $00000277;
 tk_read = $00000278;
 tk_write = $00000279;
 tk_div = $0000027A;
 tk_mod = $0000027B;
 tk_and = $0000027C;
 tk_shl = $0000027D;
 tk_shr = $0000027E;
 tk_or = $0000027F;
 tk_xor = $00000280;
 tk_in = $00000281;
 tk_is = $00000282;
 tk_not = $00000283;
 tk_as = $00000284;
 tk_inherited = $00000285;

 tokens: array[0..133] of string = ('',
  '.void','.classes','.private','.protected','.public','.published',
  '.classintfname','.classintftype','.classimp','.objpotype','.self','.units',
  '.ancestors','.nestedvarref','.defines','.ini','.fini','.incref','.decref',
  '.decrefindi','.destroy','.method','.operators','.operatorsright','.system',
  'mselang','pascal','nil','result','exitcode','sizeof','defined','break',
  'continue','self','b','booleval','internaldebug','nozeroinit','zeroinit',
  'virtual','except','end','afterconstruct','beforedestruct','ini','fini',
  'operator','operatorright','default','unit','program','interface',
  'implementation','uses','type','const','var','label','class','procedure',
  'function','method','initialization','finalization','constructor',
  'destructor','begin','mode','dumpelements','dumpopcode','abort','stoponerror',
  'nop','include','define','undef','ifdef','ifndef','if','else','endif','ifend',
  'h','inline','on','off','constref','out','override','overload','of','object',
  'external','forward','sub','finally','do','with','case','while','repeat',
  'for','try','raise','goto','then','until','to','downto','set','packed',
  'record','array','private','protected','public','published','property','read',
  'write','div','mod','and','shl','shr','or','xor','in','is','not','as',
  'inherited');

 tokenids: array[0..133] of identty = (
  $00000000,$00000201,$00000202,$00000203,$00000204,$00000205,$00000206,
  $00000207,$00000208,$00000209,$0000020A,$0000020B,$0000020C,$0000020D,
  $0000020E,$0000020F,$00000210,$00000211,$00000212,$00000213,$00000214,
  $00000215,$00000216,$00000217,$00000218,$00000219,$0000021A,$0000021B,
  $0000021C,$0000021D,$0000021E,$0000021F,$00000220,$00000221,$00000222,
  $00000223,$00000224,$00000225,$00000226,$00000227,$00000228,$00000229,
  $0000022A,$0000022B,$0000022C,$0000022D,$0000022E,$0000022F,$00000230,
  $00000231,$00000232,$00000233,$00000234,$00000235,$00000236,$00000237,
  $00000238,$00000239,$0000023A,$0000023B,$0000023C,$0000023D,$0000023E,
  $0000023F,$00000240,$00000241,$00000242,$00000243,$00000244,$00000245,
  $00000246,$00000247,$00000248,$00000249,$0000024A,$0000024B,$0000024C,
  $0000024D,$0000024E,$0000024F,$00000250,$00000251,$00000252,$00000253,
  $00000254,$00000255,$00000256,$00000257,$00000258,$00000259,$0000025A,
  $0000025B,$0000025C,$0000025D,$0000025E,$0000025F,$00000260,$00000261,
  $00000262,$00000263,$00000264,$00000265,$00000266,$00000267,$00000268,
  $00000269,$0000026A,$0000026B,$0000026C,$0000026D,$0000026E,$0000026F,
  $00000270,$00000271,$00000272,$00000273,$00000274,$00000275,$00000276,
  $00000277,$00000278,$00000279,$0000027A,$0000027B,$0000027C,$0000027D,
  $0000027E,$0000027F,$00000280,$00000281,$00000282,$00000283,$00000284,
  $00000285);

implementation
end.