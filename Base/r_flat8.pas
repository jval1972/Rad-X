//
//  RAD: Recreation of the game "Radix - beyond the void"
//       powered by the DelphiDoom engine
//
//  Copyright (C) 1995 by Epic MegaGames, Inc.
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Multithreading flat rendering - 8 bit color
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit r_flat8;

interface

uses
  d_delphi,
  m_fixed,
  r_span;

type
  flatrenderinfo8_t = record
    ds_source: PByteArray;
    ds_colormap: PByteArray;
    ds_y, ds_x1, ds_x2: integer;
    ds_xfrac: fixed_t;
    ds_yfrac: fixed_t;
    ds_xstep: fixed_t;
    ds_ystep: fixed_t;
    ds_ripple: PIntegerArray;
    ds_scale: dsscale_t;
    ds_checkzbuffer3dfloors: boolean;
    db_distance: LongWord;
    func: PPointerParmProcedure;
  end;
  Pflatrenderinfo8_t = ^flatrenderinfo8_t;

  flatrenderinfo8_tArray = array[0..$FFF] of flatrenderinfo8_t;
  Pflatrenderinfo8_tArray = ^flatrenderinfo8_tArray;

//==============================================================================
//
// R_StoreFlatSpan8
//
//==============================================================================
procedure R_StoreFlatSpan8;

//==============================================================================
//
// R_InitFlatsCache8
//
//==============================================================================
procedure R_InitFlatsCache8;

//==============================================================================
//
// R_ShutDownFlatsCache8
//
//==============================================================================
procedure R_ShutDownFlatsCache8;

//==============================================================================
//
// R_RenderMultiThreadFlats8
//
//==============================================================================
procedure R_RenderMultiThreadFlats8;

//==============================================================================
//
// R_RenderMultiThreadFFloors8
//
//==============================================================================
procedure R_RenderMultiThreadFFloors8;

var
  force_numflatrenderingthreads_8bit: integer = 0;

//==============================================================================
//
// R_DrawSpanMediumMT
//
//==============================================================================
procedure R_DrawSpanMediumMT(const fi: pointer);

implementation

uses
  i_system,
  i_threads,
  mt_utils,
  r_draw,
  r_main,
  r_ripple,
  r_3dfloors,
  r_zbuffer,
  r_depthbuffer;

var
  flatcache8: Pflatrenderinfo8_tArray;
  flatcachesize8: integer;
  flatcacherealsize8: integer;

//==============================================================================
//
// R_GrowFlatsCache8
//
//==============================================================================
procedure R_GrowFlatsCache8;
begin
  if flatcachesize8 >= flatcacherealsize8 then
  begin
    realloc(Pointer(flatcache8), flatcacherealsize8 * SizeOf(flatrenderinfo8_t), (64 + flatcacherealsize8) * SizeOf(flatrenderinfo8_t));
    flatcacherealsize8 := flatcacherealsize8 + 64;
  end;
end;

//==============================================================================
//
// R_StoreFlatSpan8
//
//==============================================================================
procedure R_StoreFlatSpan8;
var
  flat: Pflatrenderinfo8_t;
begin
  if ds_x2 - ds_x1 < 0 then
    exit;

  R_GrowFlatsCache8;
  flat := @flatcache8[flatcachesize8];
  flat.ds_source := ds_source;
  flat.ds_colormap := ds_colormap;
  flat.ds_y := ds_y;
  flat.ds_x1 := ds_x1;
  flat.ds_x2 := ds_x2;
  flat.ds_xfrac := ds_xfrac;
  flat.ds_yfrac := ds_yfrac;
  flat.ds_xstep := ds_xstep;
  flat.ds_ystep := ds_ystep;
  flat.ds_ripple := ds_ripple;
  flat.ds_scale := ds_scale;
  flat.ds_checkzbuffer3dfloors := checkzbuffer3dfloors;
  flat.db_distance := db_distance;
  flat.func := spanfuncMT;
  inc(flatcachesize8);
end;

//==============================================================================
//
// R_InitFlatsCache8
//
//==============================================================================
procedure R_InitFlatsCache8;
begin
  flatcache8 := nil;
  flatcachesize8 := 0;
  flatcacherealsize8 := 0;
end;

//==============================================================================
//
// R_ShutDownFlatsCache8
//
//==============================================================================
procedure R_ShutDownFlatsCache8;
begin
  if flatcacherealsize8 <> 0 then
  begin
    memfree(pointer(flatcache8), flatcacherealsize8 * SizeOf(flatrenderinfo8_t));
    flatcacherealsize8 := 0;
  end;
end;

const
  MAXFLATRENDERINGTHREADS8 = 16;

type
  Pflatthreadparams8_t = ^flatthreadparams8_t;
  flatthreadparams8_t = record
    start, stop: integer;
    next: Pflatthreadparams8_t;
  end;

var
  R: array[0..MAXFLATRENDERINGTHREADS8 - 1] of flatthreadparams8_t; // JVAL: 20220320 - Made global

//==============================================================================
//
// _flat_thread_worker8
//
//==============================================================================
function _flat_thread_worker8(parms: Pflatthreadparams8_t): integer; stdcall;
var
  item: Pflatrenderinfo8_t;
  start, stop, part: integer;
  i: integer;
begin
  while parms.start <= parms.stop do
  begin
    item := @flatcache8[parms.start];
    item.func(item);
    ThreadInc(parms.start);
  end;

  // No further operations in main thread
  if parms = @R[0] then
  begin
    Result := 0;
    Exit;
  end;

  while true do
  begin
    parms := parms.next;
    start := parms.start;
    stop := parms.stop;
    part := (stop - start) div 2;
    if part > 2 then
    begin
      ThreadSet(parms.stop, parms.stop - part);
      start := parms.stop + 1;
      for i := start to stop do
      begin
        item := @flatcache8[i];
        item.func(item);
      end;
    end
    else if part < 1 then
      Break;
  end;

  result := 0;
end;

//==============================================================================
//
// R_RenderMultiThreadFlats8
//
//==============================================================================
procedure R_RenderMultiThreadFlats8;
var
  step: float;
  numthreads: integer;
  i: integer;
begin
  if flatcachesize8 = 0 then
    exit;

  if force_numflatrenderingthreads_8bit > 0 then
  begin
    numthreads := force_numflatrenderingthreads_8bit;
    if numthreads < 2 then
    begin
      numthreads := 2;
      force_numflatrenderingthreads_8bit := 2;
    end
    else if numthreads > MAXFLATRENDERINGTHREADS8 then
    begin
      numthreads := MAXFLATRENDERINGTHREADS8;
      force_numflatrenderingthreads_8bit := MAXFLATRENDERINGTHREADS8;
    end;
  end
  else
  begin
    numthreads := I_GetNumCPUs;
    if numthreads < 2 then
      numthreads := 2
    else if numthreads > MAXFLATRENDERINGTHREADS8 then
      numthreads := MAXFLATRENDERINGTHREADS8;
  end;

  if flatcachesize8 < numthreads then
  begin
    R[0].start := 0;
    R[0].stop := flatcachesize8 - 1;
    R[0].next := @R[0];
    _flat_thread_worker8(@R[0]);
    flatcachesize8 := 0;
    exit;
  end;

  step := flatcachesize8 / numthreads;
  R[0].start := 0;
  for i := 1 to numthreads - 1 do
    R[i].start := Round(step * i);
  for i := 0 to numthreads - 2 do
    R[i].stop := R[i + 1].start - 1;
  R[numthreads - 1].stop := flatcachesize8 - 1;

  for i := 0 to numthreads - 2 do
    R[i].next := @R[i + 1];
  R[numthreads - 1].next := @R[0];

  case numthreads of
   2:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1]
    );
   3:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2]
    );
   4:
    MT_Execute4i(
      @_flat_thread_worker8,
      @R[0], @R[1], @R[2], @R[3]
    );
   5:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2],
      @_flat_thread_worker8, @R[3],
      @_flat_thread_worker8, @R[4]
    );
   6:
    MT_Execute6i(
      @_flat_thread_worker8,
      @R[0], @R[1], @R[2], @R[3], @R[4], @R[5]
    );
   7:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2],
      @_flat_thread_worker8, @R[3],
      @_flat_thread_worker8, @R[4],
      @_flat_thread_worker8, @R[5],
      @_flat_thread_worker8, @R[6]
    );
   8:
    MT_Execute8i(
      @_flat_thread_worker8,
      @R[0], @R[1], @R[2], @R[3], @R[4], @R[5], @R[6], @R[7]
    );
   9:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2],
      @_flat_thread_worker8, @R[3],
      @_flat_thread_worker8, @R[4],
      @_flat_thread_worker8, @R[5],
      @_flat_thread_worker8, @R[6],
      @_flat_thread_worker8, @R[7],
      @_flat_thread_worker8, @R[8]
    );
  10:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2],
      @_flat_thread_worker8, @R[3],
      @_flat_thread_worker8, @R[4],
      @_flat_thread_worker8, @R[5],
      @_flat_thread_worker8, @R[6],
      @_flat_thread_worker8, @R[7],
      @_flat_thread_worker8, @R[8],
      @_flat_thread_worker8, @R[9]
    );
  11:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2],
      @_flat_thread_worker8, @R[3],
      @_flat_thread_worker8, @R[4],
      @_flat_thread_worker8, @R[5],
      @_flat_thread_worker8, @R[6],
      @_flat_thread_worker8, @R[7],
      @_flat_thread_worker8, @R[8],
      @_flat_thread_worker8, @R[9],
      @_flat_thread_worker8, @R[10]
    );
  12:
    MT_Execute12i(
      @_flat_thread_worker8,
      @R[0], @R[1], @R[2], @R[3], @R[4], @R[5],
      @R[6], @R[7], @R[8], @R[9], @R[10], @R[11]
    );
  13:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2],
      @_flat_thread_worker8, @R[3],
      @_flat_thread_worker8, @R[4],
      @_flat_thread_worker8, @R[5],
      @_flat_thread_worker8, @R[6],
      @_flat_thread_worker8, @R[7],
      @_flat_thread_worker8, @R[8],
      @_flat_thread_worker8, @R[9],
      @_flat_thread_worker8, @R[10],
      @_flat_thread_worker8, @R[11],
      @_flat_thread_worker8, @R[12]
    );
  14:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2],
      @_flat_thread_worker8, @R[3],
      @_flat_thread_worker8, @R[4],
      @_flat_thread_worker8, @R[5],
      @_flat_thread_worker8, @R[6],
      @_flat_thread_worker8, @R[7],
      @_flat_thread_worker8, @R[8],
      @_flat_thread_worker8, @R[9],
      @_flat_thread_worker8, @R[10],
      @_flat_thread_worker8, @R[11],
      @_flat_thread_worker8, @R[12],
      @_flat_thread_worker8, @R[13]
    );
  15:
    MT_Execute(
      @_flat_thread_worker8, @R[0],
      @_flat_thread_worker8, @R[1],
      @_flat_thread_worker8, @R[2],
      @_flat_thread_worker8, @R[3],
      @_flat_thread_worker8, @R[4],
      @_flat_thread_worker8, @R[5],
      @_flat_thread_worker8, @R[6],
      @_flat_thread_worker8, @R[7],
      @_flat_thread_worker8, @R[8],
      @_flat_thread_worker8, @R[9],
      @_flat_thread_worker8, @R[10],
      @_flat_thread_worker8, @R[11],
      @_flat_thread_worker8, @R[12],
      @_flat_thread_worker8, @R[13],
      @_flat_thread_worker8, @R[14]
    );
  else
    MT_Execute16i(
      @_flat_thread_worker8,
      @R[0], @R[1], @R[2], @R[3], @R[4], @R[5], @R[6], @R[7],
      @R[8], @R[9], @R[10], @R[11], @R[12], @R[13], @R[14], @R[15]
    );
  end;

  flatcachesize8 := 0;
end;

//==============================================================================
//
// _flat3D_thread_worker8
//
//==============================================================================
function _flat3D_thread_worker8(parms: Pflatthreadparams8_t): integer; stdcall;
var
  item1, item2: Pflatrenderinfo8_t;
  start, finish: integer;
begin
  item1 := @flatcache8[0];
  item2 := @flatcache8[flatcachesize8 - 1];
  start := parms.start;
  finish := parms.stop;
  while integer(item1) <= integer(item2) do
  begin
    if item1.ds_y >= start then
      if item1.ds_y <= finish then
        item1.func(item1);
    inc(item1);
  end;

  Result := 0;
end;

//==============================================================================
//
// R_RenderMultiThreadFFloors8
//
//==============================================================================
procedure R_RenderMultiThreadFFloors8;
var
  step: float;
  numthreads: integer;
  i: integer;
begin
  if flatcachesize8 = 0 then
    exit;

  if force_numflatrenderingthreads_8bit > 0 then
  begin
    numthreads := force_numflatrenderingthreads_8bit;
    if numthreads < 2 then
    begin
      numthreads := 2;
      force_numflatrenderingthreads_8bit := 2;
    end
    else if numthreads > MAXFLATRENDERINGTHREADS8 then
    begin
      numthreads := MAXFLATRENDERINGTHREADS8;
      force_numflatrenderingthreads_8bit := MAXFLATRENDERINGTHREADS8;
    end;
  end
  else
  begin
    numthreads := I_GetNumCPUs;
    if numthreads < 2 then
      numthreads := 2
    else if numthreads > MAXFLATRENDERINGTHREADS8 then
      numthreads := MAXFLATRENDERINGTHREADS8;
  end;

  if viewheight < numthreads then
  begin
    R[0].start := 0;
    R[0].stop := viewheight - 1;
    R[0].next := @R[0];
    _flat3D_thread_worker8(@R[0]);
    flatcachesize8 := 0;
    exit;
  end;

  step := viewheight / numthreads;
  R[0].start := 0;
  for i := 1 to numthreads - 1 do
    R[i].start := Round(step * i);
  for i := 0 to numthreads - 2 do
    R[i].stop := R[i + 1].start - 1;
  R[numthreads - 1].stop := viewheight - 1;

  for i := 0 to numthreads - 2 do
    R[i].next := @R[i + 1];
  R[numthreads - 1].next := @R[0];

  case numthreads of
   2:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1]
    );
   3:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2]
    );
   4:
    MT_Execute4i(
      @_flat3D_thread_worker8,
      @R[0], @R[1], @R[2], @R[3]
    );
   5:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2],
      @_flat3D_thread_worker8, @R[3],
      @_flat3D_thread_worker8, @R[4]
    );
   6:
    MT_Execute6i(
      @_flat3D_thread_worker8,
      @R[0], @R[1], @R[2], @R[3], @R[4], @R[5]
    );
   7:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2],
      @_flat3D_thread_worker8, @R[3],
      @_flat3D_thread_worker8, @R[4],
      @_flat3D_thread_worker8, @R[5],
      @_flat3D_thread_worker8, @R[6]
    );
   8:
    MT_Execute8i(
      @_flat3D_thread_worker8,
      @R[0], @R[1], @R[2], @R[3], @R[4], @R[5], @R[6], @R[7]
    );
   9:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2],
      @_flat3D_thread_worker8, @R[3],
      @_flat3D_thread_worker8, @R[4],
      @_flat3D_thread_worker8, @R[5],
      @_flat3D_thread_worker8, @R[6],
      @_flat3D_thread_worker8, @R[7],
      @_flat3D_thread_worker8, @R[8]
    );
  10:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2],
      @_flat3D_thread_worker8, @R[3],
      @_flat3D_thread_worker8, @R[4],
      @_flat3D_thread_worker8, @R[5],
      @_flat3D_thread_worker8, @R[6],
      @_flat3D_thread_worker8, @R[7],
      @_flat3D_thread_worker8, @R[8],
      @_flat3D_thread_worker8, @R[9]
    );
  11:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2],
      @_flat3D_thread_worker8, @R[3],
      @_flat3D_thread_worker8, @R[4],
      @_flat3D_thread_worker8, @R[5],
      @_flat3D_thread_worker8, @R[6],
      @_flat3D_thread_worker8, @R[7],
      @_flat3D_thread_worker8, @R[8],
      @_flat3D_thread_worker8, @R[9],
      @_flat3D_thread_worker8, @R[10]
    );
  12:
    MT_Execute12i(
      @_flat3D_thread_worker8,
      @R[0], @R[1], @R[2], @R[3], @R[4], @R[5],
      @R[6], @R[7], @R[8], @R[9], @R[10], @R[11]
    );
  13:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2],
      @_flat3D_thread_worker8, @R[3],
      @_flat3D_thread_worker8, @R[4],
      @_flat3D_thread_worker8, @R[5],
      @_flat3D_thread_worker8, @R[6],
      @_flat3D_thread_worker8, @R[7],
      @_flat3D_thread_worker8, @R[8],
      @_flat3D_thread_worker8, @R[9],
      @_flat3D_thread_worker8, @R[10],
      @_flat3D_thread_worker8, @R[11],
      @_flat3D_thread_worker8, @R[12]
    );
  14:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2],
      @_flat3D_thread_worker8, @R[3],
      @_flat3D_thread_worker8, @R[4],
      @_flat3D_thread_worker8, @R[5],
      @_flat3D_thread_worker8, @R[6],
      @_flat3D_thread_worker8, @R[7],
      @_flat3D_thread_worker8, @R[8],
      @_flat3D_thread_worker8, @R[9],
      @_flat3D_thread_worker8, @R[10],
      @_flat3D_thread_worker8, @R[11],
      @_flat3D_thread_worker8, @R[12],
      @_flat3D_thread_worker8, @R[13]
    );
  15:
    MT_Execute(
      @_flat3D_thread_worker8, @R[0],
      @_flat3D_thread_worker8, @R[1],
      @_flat3D_thread_worker8, @R[2],
      @_flat3D_thread_worker8, @R[3],
      @_flat3D_thread_worker8, @R[4],
      @_flat3D_thread_worker8, @R[5],
      @_flat3D_thread_worker8, @R[6],
      @_flat3D_thread_worker8, @R[7],
      @_flat3D_thread_worker8, @R[8],
      @_flat3D_thread_worker8, @R[9],
      @_flat3D_thread_worker8, @R[10],
      @_flat3D_thread_worker8, @R[11],
      @_flat3D_thread_worker8, @R[12],
      @_flat3D_thread_worker8, @R[13],
      @_flat3D_thread_worker8, @R[14]
    );
  else
    MT_Execute16i(
      @_flat3D_thread_worker8,
      @R[0], @R[1], @R[2], @R[3], @R[4], @R[5], @R[6], @R[7],
      @R[8], @R[9], @R[10], @R[11], @R[12], @R[13], @R[14], @R[15]
    );
  end;

  flatcachesize8 := 0;
end;

//==============================================================================
// R_DrawSpanMediumMT
//
// Draws the actual span (Medium resolution).
//
//==============================================================================
procedure R_DrawSpanMediumMT(const fi: pointer);
var
  ds_source: PByteArray;
  ds_colormap: PByteArray;
  ds_y, ds_x1, ds_x2: integer;
  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;
  ds_scale: dsscale_t;
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  dest: PByte;
  count: integer;
  i: integer;
  spot: integer;
  fb: fourbytes_t;
  docheckzbuffer3dfloors: boolean;
  db_distance: LongWord;
  x: integer;
begin
  ds_source := Pflatrenderinfo8_t(fi).ds_source;
  ds_colormap := Pflatrenderinfo8_t(fi).ds_colormap;
  ds_y := Pflatrenderinfo8_t(fi).ds_y;
  ds_x1 := Pflatrenderinfo8_t(fi).ds_x1;
  ds_x2 := Pflatrenderinfo8_t(fi).ds_x2;
  ds_xfrac := Pflatrenderinfo8_t(fi).ds_xfrac;
  ds_yfrac := Pflatrenderinfo8_t(fi).ds_yfrac;
  ds_xstep := Pflatrenderinfo8_t(fi).ds_xstep;
  ds_ystep := Pflatrenderinfo8_t(fi).ds_ystep;
  ds_scale := Pflatrenderinfo8_t(fi).ds_scale;
  docheckzbuffer3dfloors := Pflatrenderinfo8_t(fi).ds_checkzbuffer3dfloors;

  dest := @((ylookup[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  x := ds_x1;
  count := ds_x2 - x;

  if docheckzbuffer3dfloors then
  begin
    db_distance := Pflatrenderinfo8_t(fi).db_distance;
    {$UNDEF RIPPLE}
    {$DEFINE CHECK3DFLOORSZ}
    {$I R_DrawSpanMedium.inc}
  end
  else
  begin
    {$UNDEF RIPPLE}
    {$UNDEF CHECK3DFLOORSZ}
    {$I R_DrawSpanMedium.inc}
  end;
end;

end.

