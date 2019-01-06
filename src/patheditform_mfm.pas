unit patheditform_mfm;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}

interface

implementation
uses
 mseclasses,patheditform;

const
 objdata: record size: integer; data: array[0..1921] of byte end =
      (size: 1922; data: (
  84,80,70,48,11,116,112,97,116,104,101,100,105,116,102,111,10,112,97,116,
  104,101,100,105,116,102,111,4,104,105,110,116,6,47,82,105,103,104,116,45,
  99,108,105,99,107,32,116,111,32,97,100,100,32,114,111,119,44,32,40,108,
  105,107,101,32,45,70,117,47,104,111,109,101,47,116,104,101,112,114,111,106,
  41,8,98,111,117,110,100,115,95,120,3,220,1,8,98,111,117,110,100,115,
  95,121,3,176,0,9,98,111,117,110,100,115,95,99,120,3,235,1,9,98,
  111,117,110,100,115,95,99,121,3,150,1,26,99,111,110,116,97,105,110,101,
  114,46,102,114,97,109,101,46,108,111,99,97,108,112,114,111,112,115,11,0,
  27,99,111,110,116,97,105,110,101,114,46,102,114,97,109,101,46,108,111,99,
  97,108,112,114,111,112,115,49,11,0,16,99,111,110,116,97,105,110,101,114,
  46,98,111,117,110,100,115,1,2,0,2,0,3,235,1,3,150,1,0,7,
  111,112,116,105,111,110,115,11,14,102,111,95,102,114,101,101,111,110,99,108,
  111,115,101,14,102,111,95,99,97,110,99,101,108,111,110,101,115,99,15,102,
  111,95,97,117,116,111,114,101,97,100,115,116,97,116,16,102,111,95,97,117,
  116,111,119,114,105,116,101,115,116,97,116,10,102,111,95,115,97,118,101,112,
  111,115,13,102,111,95,115,97,118,101,122,111,114,100,101,114,12,102,111,95,
  115,97,118,101,115,116,97,116,101,0,7,99,97,112,116,105,111,110,6,18,
  85,110,105,116,115,32,80,97,116,104,32,69,100,105,116,111,114,32,13,119,
  105,110,100,111,119,111,112,97,99,105,116,121,5,0,0,0,0,0,0,0,
  128,255,255,8,111,110,108,111,97,100,101,100,7,8,108,111,97,100,101,100,
  101,118,12,111,110,99,108,111,115,101,113,117,101,114,121,7,13,99,108,111,
  115,101,113,117,101,114,121,100,101,102,15,109,111,100,117,108,101,99,108,97,
  115,115,110,97,109,101,6,8,116,109,115,101,102,111,114,109,0,11,116,119,
  105,100,103,101,116,103,114,105,100,12,116,119,105,100,103,101,116,103,114,105,
  100,49,13,102,114,97,109,101,46,99,97,112,116,105,111,110,6,19,67,111,
  109,112,105,108,101,114,32,112,97,114,97,109,101,116,101,114,115,16,102,114,
  97,109,101,46,108,111,99,97,108,112,114,111,112,115,11,0,17,102,114,97,
  109,101,46,108,111,99,97,108,112,114,111,112,115,49,11,0,16,102,114,97,
  109,101,46,111,117,116,101,114,102,114,97,109,101,1,2,0,2,17,2,0,
  2,0,0,8,116,97,98,111,114,100,101,114,2,1,8,98,111,117,110,100,
  115,95,120,2,0,8,98,111,117,110,100,115,95,121,2,6,9,98,111,117,
  110,100,115,95,99,120,3,232,1,9,98,111,117,110,100,115,95,99,121,3,
  141,1,7,97,110,99,104,111,114,115,11,7,97,110,95,108,101,102,116,6,
  97,110,95,116,111,112,8,97,110,95,114,105,103,104,116,9,97,110,95,98,
  111,116,116,111,109,0,11,111,112,116,105,111,110,115,103,114,105,100,11,15,
  111,103,95,114,111,119,105,110,115,101,114,116,105,110,103,14,111,103,95,114,
  111,119,100,101,108,101,116,105,110,103,19,111,103,95,102,111,99,117,115,99,
  101,108,108,111,110,101,110,116,101,114,15,111,103,95,97,117,116,111,102,105,
  114,115,116,114,111,119,13,111,103,95,97,117,116,111,97,112,112,101,110,100,
  20,111,103,95,99,111,108,99,104,97,110,103,101,111,110,116,97,98,107,101,
  121,10,111,103,95,119,114,97,112,99,111,108,12,111,103,95,97,117,116,111,
  112,111,112,117,112,17,111,103,95,109,111,117,115,101,115,99,114,111,108,108,
  99,111,108,0,14,100,97,116,97,99,111,108,115,46,99,111,117,110,116,2,
  1,14,100,97,116,97,99,111,108,115,46,105,116,101,109,115,14,7,8,102,
  117,118,97,108,117,101,115,1,5,119,105,100,116,104,3,227,1,7,111,112,
  116,105,111,110,115,11,7,99,111,95,102,105,108,108,12,99,111,95,115,97,
  118,101,118,97,108,117,101,12,99,111,95,115,97,118,101,115,116,97,116,101,
  17,99,111,95,109,111,117,115,101,115,99,114,111,108,108,114,111,119,0,10,
  119,105,100,103,101,116,110,97,109,101,6,8,102,117,118,97,108,117,101,115,
  9,100,97,116,97,99,108,97,115,115,7,22,116,103,114,105,100,109,115,101,
  115,116,114,105,110,103,100,97,116,97,108,105,115,116,0,0,13,100,97,116,
  97,114,111,119,104,101,105,103,104,116,2,16,13,114,101,102,102,111,110,116,
  104,101,105,103,104,116,2,14,0,11,116,115,116,114,105,110,103,101,100,105,
  116,8,102,117,118,97,108,117,101,115,14,111,112,116,105,111,110,115,119,105,
  100,103,101,116,49,11,19,111,119,49,95,102,111,110,116,103,108,121,112,104,
  104,101,105,103,104,116,0,11,111,112,116,105,111,110,115,115,107,105,110,11,
  19,111,115,107,95,102,114,97,109,101,98,117,116,116,111,110,111,110,108,121,
  0,8,116,97,98,111,114,100,101,114,2,1,7,118,105,115,105,98,108,101,
  8,8,98,111,117,110,100,115,95,120,2,0,8,98,111,117,110,100,115,95,
  121,2,0,9,98,111,117,110,100,115,95,99,120,3,227,1,9,98,111,117,
  110,100,115,95,99,121,2,16,13,114,101,102,102,111,110,116,104,101,105,103,
  104,116,2,14,0,0,0,7,116,98,117,116,116,111,110,8,116,98,117,116,
  116,111,110,49,8,116,97,98,111,114,100,101,114,2,2,8,98,111,117,110,
  100,115,95,120,3,108,1,8,98,111,117,110,100,115,95,121,2,2,9,98,
  111,117,110,100,115,95,99,120,2,50,9,98,111,117,110,100,115,95,99,121,
  2,20,7,97,110,99,104,111,114,115,11,6,97,110,95,116,111,112,8,97,
  110,95,114,105,103,104,116,0,5,115,116,97,116,101,11,10,97,115,95,100,
  101,102,97,117,108,116,15,97,115,95,108,111,99,97,108,100,101,102,97,117,
  108,116,15,97,115,95,108,111,99,97,108,99,97,112,116,105,111,110,0,7,
  99,97,112,116,105,111,110,6,2,79,75,11,109,111,100,97,108,114,101,115,
  117,108,116,7,5,109,114,95,111,107,0,0,7,116,98,117,116,116,111,110,
  8,116,98,117,116,116,111,110,50,8,98,111,117,110,100,115,95,120,3,164,
  1,8,98,111,117,110,100,115,95,121,2,2,9,98,111,117,110,100,115,95,
  99,120,2,50,9,98,111,117,110,100,115,95,99,121,2,20,7,97,110,99,
  104,111,114,115,11,6,97,110,95,116,111,112,8,97,110,95,114,105,103,104,
  116,0,5,115,116,97,116,101,11,15,97,115,95,108,111,99,97,108,99,97,
  112,116,105,111,110,0,7,99,97,112,116,105,111,110,6,6,67,97,110,99,
  101,108,11,109,111,100,97,108,114,101,115,117,108,116,7,9,109,114,95,99,
  97,110,99,101,108,0,0,7,116,98,117,116,116,111,110,8,116,98,117,116,
  116,111,110,51,8,116,97,98,111,114,100,101,114,2,3,8,98,111,117,110,
  100,115,95,120,3,136,0,8,98,111,117,110,100,115,95,121,2,2,9,98,
  111,117,110,100,115,95,99,120,2,66,9,98,111,117,110,100,115,95,99,121,
  2,20,5,115,116,97,116,101,11,15,97,115,95,108,111,99,97,108,99,97,
  112,116,105,111,110,17,97,115,95,108,111,99,97,108,111,110,101,120,101,99,
  117,116,101,22,97,115,95,108,111,99,97,108,111,110,97,102,116,101,114,101,
  120,101,99,117,116,101,0,7,99,97,112,116,105,111,110,6,7,65,100,100,
  32,114,111,119,9,111,110,101,120,101,99,117,116,101,7,6,97,100,100,114,
  111,119,0,0,7,116,98,117,116,116,111,110,8,116,98,117,116,116,111,110,
  52,8,116,97,98,111,114,100,101,114,2,4,8,98,111,117,110,100,115,95,
  120,3,208,0,8,98,111,117,110,100,115,95,121,2,2,9,98,111,117,110,
  100,115,95,99,120,2,66,9,98,111,117,110,100,115,95,99,121,2,20,5,
  115,116,97,116,101,11,15,97,115,95,108,111,99,97,108,99,97,112,116,105,
  111,110,17,97,115,95,108,111,99,97,108,111,110,101,120,101,99,117,116,101,
  22,97,115,95,108,111,99,97,108,111,110,97,102,116,101,114,101,120,101,99,
  117,116,101,0,7,99,97,112,116,105,111,110,6,7,68,101,108,32,114,111,
  119,9,111,110,101,120,101,99,117,116,101,7,6,100,101,108,114,111,119,0,
  0,0)
 );

initialization
 registerobjectdata(@objdata,tpatheditfo,'');
end.