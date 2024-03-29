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
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit r_intrpl;

// JVAL
// Frame interpolation to exceed the 35fps limit
//

interface

uses
  m_fixed;

//==============================================================================
//
// R_InitInterpolations
//
//==============================================================================
procedure R_InitInterpolations;

//==============================================================================
//
// R_ResetInterpolationBuffer
//
//==============================================================================
procedure R_ResetInterpolationBuffer;

//==============================================================================
//
// R_StoreInterpolationData
//
//==============================================================================
procedure R_StoreInterpolationData(const tick: integer; const counts: integer);

//==============================================================================
//
// R_RestoreInterpolationData
//
//==============================================================================
procedure R_RestoreInterpolationData;

//==============================================================================
//
// R_Interpolate
//
//==============================================================================
function R_Interpolate: boolean;

//==============================================================================
//
// R_InterpolateTicker
//
//==============================================================================
procedure R_InterpolateTicker;

//==============================================================================
//
// R_SetInterpolateSkipTicks
//
//==============================================================================
procedure R_SetInterpolateSkipTicks(const ticks: integer);

var
  interpolate: boolean;
  interpolateprecise: boolean = true;
  interpolateoncapped: boolean = false;
  interpolationstarttime: fixed_t = 0;
  didinterpolations: boolean;
  ticfrac: fixed_t;

implementation

uses
  d_delphi,
  d_player,
  d_think,
  c_cmds,
  m_misc,
  g_game,
  mt_utils,
  i_system,
  p_setup,
  p_tick,
  p_mobj,
  p_mobj_h,
  p_pspr_h,
  radix_level,
  r_defs,
  r_main,
  tables;

type
  itype = (iinteger, iinteger2, ismallint, ibyte, iangle, ifloat, imobj);

  // Interpolation item
  //  Holds information about the previous and next values and interpolation type
  iitem_t = record
    lastaddress: pointer;
    address: pointer;
    case _type: itype of
      iinteger: (iprev, inext: integer);
      iinteger2: (iprev2, inext2: integer);
      ismallint: (siprev, sinext: smallint);
      ibyte: (bprev, bnext: byte);
      iangle: (aprev, anext: LongWord);
      ifloat: (fprev, fnext: float);
  end;
  Piitem_t = ^iitem_t;
  iitem_tArray = array[0..$FFFF] of iitem_t;
  Piitem_tArray = ^iitem_tArray;

  // Interpolation structure
  //  Holds the global interpolation items list
  istruct_t = record
    numitems: integer;
    realsize: integer;
    items: Piitem_tArray;
  end;

const
  IGROWSTEP = 256;

var
  istruct: istruct_t;
  imobjs: array[0..$FFFF] of Pmobj_t;
  numismobjs: integer;

//==============================================================================
//
// CmdInterpolate
//
//==============================================================================
procedure CmdInterpolate(const parm: string = '');
var
  newval: boolean;
begin
  if parm = '' then
  begin
    printf('Current setting: interpolate = %s.'#13#10, [truefalseStrings[interpolate]]);
    exit;
  end;

  newval := C_BoolEval(parm, interpolate);
  if newval <> interpolate then
  begin
    interpolate := newval;
    R_SetInterpolateSkipTicks(1);
  end;

  CmdInterpolate;
end;

//==============================================================================
//
// CmdInterpolateOncapped
//
//==============================================================================
procedure CmdInterpolateOncapped(const parm: string = '');
var
  newval: boolean;
begin
  if parm = '' then
  begin
    printf('Current setting: interpolateoncapped = %s.'#13#10, [truefalseStrings[interpolateoncapped]]);
    exit;
  end;

  newval := C_BoolEval(parm, interpolateoncapped);
  if newval <> interpolateoncapped then
  begin
    interpolateoncapped := newval;
    R_SetInterpolateSkipTicks(1);
  end;

  CmdInterpolateOncapped;
end;

//==============================================================================
//
// R_InitInterpolations
//
//==============================================================================
procedure R_InitInterpolations;
begin
  istruct.numitems := 0;
  istruct.realsize := 0;
  istruct.items := nil;
  MT_ZeroMemory(@imobjs, SizeOf(imobjs));
  numismobjs := 0;
  C_AddCmd('interpolate, interpolation, setinterpolation, r_interpolate', @CmdInterpolate);
  C_AddCmd('interpolateoncapped, r_interpolateoncapped', @CmdInterpolateOncapped);
end;

//==============================================================================
//
// R_ResetInterpolationBuffer
//
//==============================================================================
procedure R_ResetInterpolationBuffer;
begin
  memfree(pointer(istruct.items), istruct.realsize * SizeOf(iitem_t));
  istruct.numitems := 0;
  istruct.realsize := 0;
  numismobjs := 0;
end;

//==============================================================================
//
// R_InterpolationCalcIF
//
//==============================================================================
function R_InterpolationCalcIF(const prev, next: fixed_t; const frac: fixed_t): fixed_t;
begin
  if next = prev then
    result := prev
  else
    result := prev + round((next - prev) / FRACUNIT * frac);
end;

//==============================================================================
//
// R_InterpolationCalcSIF
//
//==============================================================================
function R_InterpolationCalcSIF(const prev, next: smallint; const frac: fixed_t): smallint;
begin
  if next = prev then
    result := prev
  else
    result := prev + round((next - prev) / FRACUNIT * frac);
end;

//==============================================================================
//
// R_InterpolationCalcI
//
//==============================================================================
procedure R_InterpolationCalcI(const pi: Piitem_t; const frac: fixed_t);
begin
  if pi.inext = pi.iprev then
    exit;

  PInteger(pi.address)^ := pi.iprev + round((pi.inext - pi.iprev) / FRACUNIT * frac);
end;

//==============================================================================
//
// R_InterpolationCalcI2
//
//==============================================================================
procedure R_InterpolationCalcI2(const pi: Piitem_t; const frac: fixed_t);
const
  II2MARGIN = 8 * FRACUNIT;
var
  diff: integer;
begin
  if pi.inext2 = pi.iprev2 then
    exit;

  diff := pi.inext2 - pi.iprev2;
  if (diff > II2MARGIN) or (diff < -II2MARGIN) then
  begin
    if frac < FRACUNIT div 2 then
      PInteger(pi.address)^ := pi.iprev2
    else
      PInteger(pi.address)^ := pi.inext2
  end
  else
    PInteger(pi.address)^ := pi.iprev2 + round((pi.inext2 - pi.iprev2) / FRACUNIT * frac);
end;

//==============================================================================
//
// R_InterpolationCalcSI
//
//==============================================================================
procedure R_InterpolationCalcSI(const pi: Piitem_t; const frac: fixed_t);
begin
  if pi.sinext = pi.siprev then
    exit;

  PSmallInt(pi.address)^ := pi.siprev + round((pi.sinext - pi.siprev) / FRACUNIT * frac);
end;

//==============================================================================
//
// R_InterpolationCalcB
//
//==============================================================================
function R_InterpolationCalcB(const prev, next: byte; const frac: fixed_t): byte;
begin
  if next = prev then
    result := prev
  else if (next = 0) or (prev = 0) then // Hack for player.lookdir2
    result := next
  else if ((next > 247) and (prev < 8)) or ((next < 8) and (prev > 247)) then // Hack for player.lookdir2
    result := 0
  else
    result := prev + (next - prev) * frac div FRACUNIT;
end;

//==============================================================================
//
// R_InterpolationCalcA
//
//==============================================================================
function R_InterpolationCalcA(const prev, next: angle_t; const frac: fixed_t): angle_t;
var
  prev_e, next_e, mid_e: Extended;
begin
  if prev = next then
    result := prev
  else
  begin
    if ((prev < ANG90) and (next > ANG270)) or
       ((next < ANG90) and (prev > ANG270)) then
    begin
      prev_e := prev / ANGLE_MAX;
      next_e := next / ANGLE_MAX;
      if prev > next then
        next_e := next_e + 1.0
      else
        prev_e := prev_e + 1.0;

      mid_e := prev_e + (next_e - prev_e) / FRACUNIT * frac;
      if mid_e > 1.0 then
        mid_e := mid_e - 1.0;
      result := Round(mid_e * ANGLE_MAX);
    end
    else if prev > next then
    begin
      result := prev - round((prev - next) / FRACUNIT * frac);
    end
    else
    begin
      result := prev + round((next - prev) / FRACUNIT * frac);
    end;
  end;
end;

//==============================================================================
//
// R_InterpolationCalcF
//
//==============================================================================
procedure R_InterpolationCalcF(const pi: Piitem_t; const frac: fixed_t);
begin
  if pi.fnext = pi.fprev then
    exit;

  Pfloat(pi.address)^ := pi.fprev + (pi.fnext - pi.fprev) / FRACUNIT * frac;
end;

//==============================================================================
//
// R_AddInterpolationItem
//
//==============================================================================
procedure R_AddInterpolationItem(const addr: pointer; const typ: itype);
var
  newrealsize: integer;
  pi: Piitem_t;
begin
  if typ = imobj then
  begin
    imobjs[numismobjs] := addr;
    if numismobjs < $FFFF then
      inc(numismobjs);
    Pmobj_t(addr).prevx := Pmobj_t(addr).nextx;
    Pmobj_t(addr).prevy := Pmobj_t(addr).nexty;
    Pmobj_t(addr).prevz := Pmobj_t(addr).nextz;
    Pmobj_t(addr).prevangle := Pmobj_t(addr).nextangle;
    Pmobj_t(addr).nextx := Pmobj_t(addr).x;
    Pmobj_t(addr).nexty := Pmobj_t(addr).y;
    Pmobj_t(addr).nextz := Pmobj_t(addr).z;
    Pmobj_t(addr).nextangle := Pmobj_t(addr).angle;
    inc(Pmobj_t(addr).intrplcnt);
    exit;
  end;

  if istruct.realsize <= istruct.numitems then
  begin
    newrealsize := istruct.realsize + IGROWSTEP;
    realloc(pointer(istruct.items), istruct.realsize * SizeOf(iitem_t), newrealsize * SizeOf(iitem_t));
    ZeroMemory(@istruct.items[istruct.realsize], IGROWSTEP * SizeOf(iitem_t));
    istruct.realsize := newrealsize;
  end;
  pi := @istruct.items[istruct.numitems];
  pi.lastaddress := pi.address;
  pi.address := addr;
  pi._type := typ;
  case typ of
    iinteger:
      begin
        pi.iprev := pi.inext;
        pi.inext := PInteger(addr)^;
      end;
    iinteger2:
      begin
        pi.iprev2 := pi.inext2;
        pi.inext2 := PInteger(addr)^;
      end;
    ismallint:
      begin
        pi.siprev := pi.sinext;
        pi.sinext := PSmallInt(addr)^;
      end;
    ibyte:
      begin
        pi.bprev := pi.bnext;
        pi.bnext := PByte(addr)^;
      end;
    iangle:
      begin
        pi.aprev := pi.anext;
        pi.anext := Pangle_t(addr)^;
      end;
    ifloat:
      begin
        pi.fprev := pi.fnext;
        pi.fnext := Pfloat(addr)^;
      end;
  end;
  inc(istruct.numitems);
end;

var
  interpolationcount: integer = 0;
  prevtic: fixed_t = 0;

// JVAL: Skip interpolation if we have teleport
var
  skipinterpolationticks: integer = -1;

//==============================================================================
//
// R_StoreInterpolationData
//
//==============================================================================
procedure R_StoreInterpolationData(const tick: integer; const counts: integer);
var
  sec: Psector_t;
  li: Pline_t;
  si: PSide_t;
  i, j: integer;
  player: Pplayer_t;
  th: Pthinker_t;
begin
  if prevtic > 0 then
    if gametic = prevtic then
      exit;

  {$IFDEF DEBUG}
  I_DevWarning('R_StoreInterpolationData(): - start - fractime = %5.3f, gametic = %d'#13#10, [I_GetFracTime / FRACUNIT, gametic]);
  I_DevWarning('R_StoreInterpolationData(): - gametic = %d, tick = %d, time = %d'#13#10, [gametic, tick, I_GetTime]);
  {$ENDIF}
  prevtic := gametic;
  interpolationcount := counts;
  istruct.numitems := 0;
  numismobjs := 0;

  // Interpolate player
  player := @players[displayplayer];
  R_AddInterpolationItem(@player.lookdir16, iinteger); // JVAL Smooth Look Up/Down
  R_AddInterpolationItem(@player.lookdir2, ibyte);
  R_AddInterpolationItem(@player.teleporttics, iinteger);
  R_AddInterpolationItem(@player.quaketics, iinteger);
  R_AddInterpolationItem(@player.bobviewz, iinteger);

  // Interpolate Sectors
  sec := @sectors[0];
  for i := 0 to numsectors - 1 do
  begin
    if sec.renderflags and SRF_NO_INTERPOLATE = 0 then
    begin
      // JVAL: 20220107 - Auto fix instant moving sectors
      //  See also: https://www.doomworld.com/forum/topic/110185-eternity-uncapped-framerate-issue/?tab=comments#comment-2044505
      R_AddInterpolationItem(@sec.floorheight, iinteger2);
      R_AddInterpolationItem(@sec.ceilingheight, iinteger2);
      R_AddInterpolationItem(@sec.lightlevel, ismallint);
      {$IFDEF DOOM_OR_STRIFE}
      // JVAL: 30/9/2009
      // JVAL: 9/11/2015 Added strife offsets
      R_AddInterpolationItem(@sec.floor_xoffs, iinteger2);
      R_AddInterpolationItem(@sec.floor_yoffs, iinteger2);
      R_AddInterpolationItem(@sec.ceiling_xoffs, iinteger2);
      R_AddInterpolationItem(@sec.ceiling_yoffs, iinteger2);
      {$ENDIF}
      if sec.renderflags and SRF_INTERPOLATE_ROTATE <> 0 then
      begin
        R_AddInterpolationItem(@sec.floorangle, iangle);
        R_AddInterpolationItem(@sec.flooranglex, iinteger);
        R_AddInterpolationItem(@sec.floorangley, iinteger);
        R_AddInterpolationItem(@sec.ceilingangle, iangle);
        R_AddInterpolationItem(@sec.ceilinganglex, iinteger);
        R_AddInterpolationItem(@sec.ceilingangley, iinteger);
      end;
      if sec.renderflags and SRF_INTERPOLATE_FLOORSLOPE <> 0 then
      begin
        R_AddInterpolationItem(@sec.fa, ifloat);
        R_AddInterpolationItem(@sec.fb, ifloat);
        R_AddInterpolationItem(@sec.fd, ifloat);
        R_AddInterpolationItem(@sec.fic, ifloat);
      end;
      if sec.renderflags and SRF_INTERPOLATE_CEILINGSLOPE <> 0 then
      begin
        R_AddInterpolationItem(@sec.ca, ifloat);
        R_AddInterpolationItem(@sec.cb, ifloat);
        R_AddInterpolationItem(@sec.cd, ifloat);
        R_AddInterpolationItem(@sec.cic, ifloat);
      end;
    end;
    inc(sec);
  end;

  for i := 0 to Ord(NUMPSPRITES) - 1 do
  begin
    R_AddInterpolationItem(@player.psprites[i].sx, iinteger);
    R_AddInterpolationItem(@player.psprites[i].sy, iinteger);
  end;

  // Interpolate Lines
  li := @lines[0];
  for i := 0 to numlines - 1 do
  begin
    if (li.special <> 0) or (li.radixflags and RWF_FORCEINTERPOLATE <> 0) then
      for j := 0 to 1 do
      begin
        if li.sidenum[j] > -1 then
        begin
          si := @sides[li.sidenum[j]];
          R_AddInterpolationItem(@si.textureoffset, iinteger2);
          R_AddInterpolationItem(@si.rowoffset, iinteger2);
        end;
      end;
    inc(li);
  end;

  // Map Objects
  th := thinkercap.next;
  while (th <> nil) and (th <> @thinkercap) do
  begin
    if @th._function.acp1 = @P_MobjThinker then
    {$IFDEF STRIFE}
      if Pmobj_t(th).flags2_ex and MF2_EX_JUSTAPPEARED = 0 then
    {$ELSE}
      if Pmobj_t(th).flags and MF_JUSTAPPEARED = 0 then
    {$ENDIF}
    // JVAL: 20200105 - Interpolate only mobjs that the renderer touched
      if (Pmobj_t(th).rendervalidcount = rendervalidcount) or (Pmobj_t(th).player <> nil) then
        R_AddInterpolationItem(th, imobj);
    th := th.next;
  end;

  sec := R_PointInSubsector(viewx, viewy).sector;
  if sec.renderflags and SRF_NO_INTERPOLATE = 0 then
//    if player.mo.z = player.mo.floorz then
      R_AddInterpolationItem(@player.viewz, iinteger);

  {$IFDEF DEBUG}
  I_DevWarning('R_StoreInterpolationData(): - finished - fractime = %5.3f, gametic = %d'#13#10, [I_GetFracTime / FRACUNIT, gametic]);
  {$ENDIF}
end;

//==============================================================================
//
// R_RestoreInterpolationData_thr1
//
//==============================================================================
function R_RestoreInterpolationData_thr1(p: pointer): integer; stdcall;
var
  i: integer;
  pi: Piitem_t;
  r: mt_range_p;
begin
  r := mt_range_p(p);
  pi := @istruct.items[r.start];
  for i := r.start to r.finish do
  begin
    case pi._type of
      iinteger: PInteger(pi.address)^ := pi.inext;
      iinteger2: PInteger(pi.address)^ := pi.inext2;
      ismallint: PSmallInt(pi.address)^ := pi.sinext;
      ibyte: PByte(pi.address)^ := pi.bnext;
      iangle: Pangle_t(pi.address)^ := pi.anext;
      ifloat: Pfloat(pi.address)^ := pi.fnext;
    end;
    inc(pi);
  end;
  result := 0;
end;

//==============================================================================
//
// R_RestoreInterpolationData_thr2
//
//==============================================================================
function R_RestoreInterpolationData_thr2(p: pointer): integer; stdcall;
var
  i: integer;
  mo: Pmobj_t;
begin
  for i := 0 to numismobjs - 1 do
  begin
    mo := imobjs[i];
    mo.x := mo.nextx;
    mo.y := mo.nexty;
    mo.z := mo.nextz;
    mo.angle := mo.nextangle;
  end;
  result := 0;
end;

//==============================================================================
//
// R_RestoreInterpolationData_Single_Thread
//
//==============================================================================
procedure R_RestoreInterpolationData_Single_Thread;
var
  i: integer;
  pi: Piitem_t;
  mo: Pmobj_t;
begin
  pi := @istruct.items[0];
  for i := 0 to istruct.numitems - 1 do
  begin
    case pi._type of
      iinteger: PInteger(pi.address)^ := pi.inext;
      iinteger2: PInteger(pi.address)^ := pi.inext2;
      ismallint: PSmallInt(pi.address)^ := pi.sinext;
      ibyte: PByte(pi.address)^ := pi.bnext;
      iangle: Pangle_t(pi.address)^ := pi.anext;
      ifloat: Pfloat(pi.address)^ := pi.fnext;
    end;
    inc(pi);
  end;

  for i := 0 to numismobjs - 1 do
  begin
    mo := imobjs[i];
    mo.x := mo.nextx;
    mo.y := mo.nexty;
    mo.z := mo.nextz;
    mo.angle := mo.nextangle;
  end;
end;

//==============================================================================
//
// R_RestoreInterpolationData
//
//==============================================================================
procedure R_RestoreInterpolationData;
var
  r1, r2, r3: mt_range_t;
begin
  if usemultithread and (I_GetNumCPUs >= 4) and (istruct.numitems + numismobjs >= 4096) then
  begin
    r1.start := 0;
    r1.finish := istruct.numitems div 3;
    r2.start := r1.finish + 1;
    r2.finish := r1.finish * 2;
    r3.start := r2.finish + 1;
    r3.finish := istruct.numitems - 1;
    MT_Execute4(
      @R_RestoreInterpolationData_thr1, @r1,
      @R_RestoreInterpolationData_thr1, @r2,
      @R_RestoreInterpolationData_thr1, @r3,
      @R_RestoreInterpolationData_thr2, nil
    );
  end
  else
    R_RestoreInterpolationData_Single_Thread;
end;

//==============================================================================
//
// R_DoInterpolate_thr1
//
//==============================================================================
function R_DoInterpolate_thr1(p: pointer): integer; stdcall;
var
  pi, pi2: Piitem_t;
begin
  pi := @istruct.items[mt_range_p(p).start];
  pi2 := @istruct.items[mt_range_p(p).finish];
  while integer(pi) <= integer(pi2) do
  begin
    if pi.address = pi.lastaddress then
    begin
      case pi._type of
        iinteger: R_InterpolationCalcI(pi, ticfrac);
        iinteger2: R_InterpolationCalcI2(pi, ticfrac);
        ismallint: R_InterpolationCalcSI(pi, ticfrac);
        ibyte: PByte(pi.address)^ := R_InterpolationCalcB(pi.bprev, pi.bnext, ticfrac);
        iangle: PAngle_t(pi.address)^ := R_InterpolationCalcA(pi.aprev, pi.anext, ticfrac);
        ifloat: R_InterpolationCalcF(pi, ticfrac);
      end;
    end;
    inc(pi);
  end;
  result := 0;
end;

//==============================================================================
//
// R_DoInterpolate_thr2
//
//==============================================================================
function R_DoInterpolate_thr2(p: pointer): integer; stdcall;
var
  i: integer;
  mo: Pmobj_t;
begin
  for i := 0 to numismobjs - 1 do
  begin
    mo := imobjs[i];
    if mo.intrplcnt > 1 then
    begin
      mo.x := R_InterpolationCalcIF(mo.prevx, mo.nextx, ticfrac);
      mo.y := R_InterpolationCalcIF(mo.prevy, mo.nexty, ticfrac);
      mo.z := R_InterpolationCalcIF(mo.prevz, mo.nextz, ticfrac);
      mo.angle := R_InterpolationCalcA(mo.prevangle, mo.nextangle, ticfrac);
    end;
  end;
  result := 0;
end;

var
  frametime: integer = 0;

//==============================================================================
//
// R_Interpolate
//
//==============================================================================
function R_Interpolate: boolean;
var
  i: integer;
  pi: Piitem_t;
  fractime: fixed_t;
  mo: Pmobj_t;
  r1, r2, r3: mt_range_t;
begin
  if skipinterpolationticks >= 0 then
  begin
    result := false;
    exit;
  end;

  fractime := I_GetFracTime;
  ticfrac := fractime - interpolationstarttime;
  if interpolateprecise then
    ticfrac := ticfrac + frametime;
  frametime := fractime;
  {$IFDEF DEBUG}
  I_Warning('R_Interpolate(): fractime = %5.3f, gametic = %d'#13#10, [fractime / FRACUNIT, gametic]);
  {$ENDIF}
  if ticfrac > FRACUNIT then
  begin
  // JVAL
  // frac > FRACUNIT should rarelly happen,
  // we don't calc, we just use the Xnext values for interpolation frame
    {$IFDEF DEBUG}
    I_Warning('R_Interpolate(): ticfrac > FRACUNIT (%d), interpolationcount = %d'#13#10, [ticfrac, interpolationcount]);
    {$ENDIF}
    result := false;
  end
  else
  begin
    result := true;
    if usemultithread and (I_GetNumCPUs >= 4) and (istruct.numitems + numismobjs >= 4096) then
    begin
      r1.start := 0;
      r1.finish := istruct.numitems div 3;
      r2.start := r1.finish + 1;
      r2.finish := r1.finish * 2;
      r3.start := r2.finish + 1;
      r3.finish := istruct.numitems - 1;
      MT_Execute4(
        @R_DoInterpolate_thr1, @r1,
        @R_DoInterpolate_thr1, @r2,
        @R_DoInterpolate_thr1, @r3,
        @R_DoInterpolate_thr2, nil
      );
    end
    else
    begin
      pi := @istruct.items[0];
      for i := 0 to istruct.numitems - 1 do
      begin
        if pi.address = pi.lastaddress then
        begin
          case pi._type of
            iinteger: R_InterpolationCalcI(pi, ticfrac);
            iinteger2: R_InterpolationCalcI2(pi, ticfrac);
            ismallint: R_InterpolationCalcSI(pi, ticfrac);
            ibyte: PByte(pi.address)^ := R_InterpolationCalcB(pi.bprev, pi.bnext, ticfrac);
            iangle: PAngle_t(pi.address)^ := R_InterpolationCalcA(pi.aprev, pi.anext, ticfrac);
            ifloat: R_InterpolationCalcF(pi, ticfrac);
          end;
        end;
        inc(pi);
      end;
      for i := 0 to numismobjs - 1 do
      begin
        mo := imobjs[i];
        if mo.intrplcnt > 1 then
        begin
          mo.x := R_InterpolationCalcIF(mo.prevx, mo.nextx, ticfrac);
          mo.y := R_InterpolationCalcIF(mo.prevy, mo.nexty, ticfrac);
          mo.z := R_InterpolationCalcIF(mo.prevz, mo.nextz, ticfrac);
          mo.angle := R_InterpolationCalcA(mo.prevangle, mo.nextangle, ticfrac);
        end;
      end;
    end;

  end;
  frametime := I_GetFracTime - frametime;
end;

//==============================================================================
//
// R_InterpolateTicker
//
//==============================================================================
procedure R_InterpolateTicker;
begin
  if skipinterpolationticks >= 0 then
    dec(skipinterpolationticks);
end;

//==============================================================================
//
// R_SetInterpolateSkipTicks
//
//==============================================================================
procedure R_SetInterpolateSkipTicks(const ticks: integer);
begin
  skipinterpolationticks := ticks;
  frametime := 0;
end;

end.

