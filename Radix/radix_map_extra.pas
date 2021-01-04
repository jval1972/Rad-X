//
//  RAD: Recreation of the game "Radix - beyond the void"
//       powered by the DelphiDoom engine
//
//  Copyright (C) 1995 by Epic MegaGames, Inc.
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2021 by Jim Valavanis
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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//   Load radix extra map information
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_map_extra;

interface

uses
  d_delphi,
  m_fixed,
  r_defs;

function RX_RadixX2Doom(const sec: Psector_t; const x: integer): integer; overload;

function RX_RadixX2Doom(const x, y: integer): integer; overload;

function RX_RadixY2Doom(const sec: Psector_t; const y: integer): integer; overload;

function RX_RadixY2Doom(const x, y: integer): integer; overload;

procedure RX_CalcFloorSlope(const sec: Psector_t);

procedure RX_CalcCeilingSlope(const sec: Psector_t);

procedure PS_SetFloorSlope(const secid: integer; const x1, y1, z1: fixed_t;
  const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);

procedure PS_SetCeilingSlope(const secid: integer; const x1, y1, z1: fixed_t;
  const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);

// Parse map lump for extra information about radix level
procedure RX_LoadRadixMapInfo(const lumpnum: integer);

{$IFNDEF OPENGL}
function RX_CalculateRadixMidOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixTopOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixBottomOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixSlopeMidOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixSlopeTopOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixSlopeBottomOffs(const seg: PSeg_t): fixed_t;
{$ENDIF}

function RX_LightLevel(const l: integer; const flags: integer): byte;

procedure RX_DamageLine(const l: Pline_t; const damage: integer);

function RX_ShootableLine(const l: Pline_t): boolean;

function RX_LineLengthf(li: Pline_t): float;

procedure RX_LineTrace(const fromx, fromy, fromz: fixed_t; const tox, toy, toz: fixed_t; out newx, newy, newz: fixed_t);

function RX_PointLineSqrDistance(const x, y: fixed_t; const line: Pline_t): integer;

var
  level_position_hack: boolean;

const
  RADIX_TICRATE = 35;

implementation

uses
  m_rnd,
  m_bbox,
  p_setup,
  p_3dfloors,
  p_local,
  p_mobj_h,
  p_maputl,
  p_map,
  p_spec,
  p_genlin,
  p_slopes,
  r_data,
  r_main,
  {$IFNDEF OPENGL}
  r_segs,
  {$ENDIF}
  radix_level,
  radix_logic,
  radix_objects,
  radix_sounds,
  sc_engine,
  sc_tokens,
  tables,
  w_wad;

// radixmapXmult & radixmapYmult must be -1 or 1, no other values allowed :)
function RX_RadixX2Doom(const sec: Psector_t; const x: integer): integer;
begin
  result := x * sec.radixmapXmult + sec.radixmapXadd;
end;

function RX_RadixX2Doom(const x, y: integer): integer;
begin
  if level_position_hack then
  begin
    if x > E3M2_SPLIT_X then
      result := x * RADIX_MAP_X_MULT + RADIX_MAP_X_ADD2
    else
      result := x * RADIX_MAP_X_MULT + RADIX_MAP_X_ADD;
  end
  else
    result := x * RADIX_MAP_X_MULT + RADIX_MAP_X_ADD;
end;

function RX_RadixY2Doom(const sec: Psector_t; const y: integer): integer;
begin
  result := y * sec.radixmapYmult + sec.radixmapYadd;
end;

function RX_RadixY2Doom(const x, y: integer): integer;
begin
  if level_position_hack then
  begin
    if x > E3M2_SPLIT_X then
      result := y * RADIX_MAP_Y_MULT + RADIX_MAP_Y_ADD2
    else
      result := y * RADIX_MAP_Y_MULT + RADIX_MAP_Y_ADD;
  end
  else
    result := y * RADIX_MAP_Y_MULT + RADIX_MAP_Y_ADD;
end;

//
// JVAL: 20200227
//
// Caclulate radix plane from radixheightnodesx, radixheightnodesy & radixfloorheights
// Note about RADIX slopes:
//   The radix sector already contains the a, b, c & d operants of the plane equation,
//   but due to some precision/integer overflow cause it does not fit well to DelphiDoom's
//   slope system.
//   Fortunatelly, the sector contains the 3 points that define the plane, so we
//   caclulate the a, b, c, & d using floating point precision :)
procedure calc_radix_plane(
  const x1, y1, z1: float;
  const x2, y2, z2: float;
  const x3, y3, z3: float;
  out fa, fb, fc, fd: float);
var
  a1, b1, c1: float;
  a2, b2, c2: float;
begin
  a1 := x2 - x1;
  b1 := y2 - y1;
  c1 := z2 - z1;
  a2 := x3 - x1;
  b2 := y3 - y1;
  c2 := z3 - z1;
  fa := b1 * c2 - b2 * c1;
  fb := a2 * c1 - a1 * c2;
  fc := a1 * b2 - b1 * a2;
  fd := (- fa * x1 - fb * y1 - fc * z1);
end;

procedure RX_CalcFloorSlope(const sec: Psector_t);
var
  fa, fb, fc, fd: float;
begin
  calc_radix_plane(
    RX_RadixX2Doom(sec, sec.radixheightnodesx[0]), RX_RadixY2Doom(sec, sec.radixheightnodesy[0]), sec.radixfloorheights[0],
    RX_RadixX2Doom(sec, sec.radixheightnodesx[1]), RX_RadixY2Doom(sec, sec.radixheightnodesy[1]), sec.radixfloorheights[1],
    RX_RadixX2Doom(sec, sec.radixheightnodesx[2]), RX_RadixY2Doom(sec, sec.radixheightnodesy[2]), sec.radixfloorheights[2],
    fa, fb, fc, fd);
  sec.fa := fa;
  sec.fb := fb;
  sec.fic := 1 / fc;
  sec.fd := fd;
end;

procedure RX_CalcCeilingSlope(const sec: Psector_t);
var
  ca, cb, cc, cd: float;
begin
  calc_radix_plane(
    RX_RadixX2Doom(sec, sec.radixheightnodesx[0]), RX_RadixY2Doom(sec, sec.radixheightnodesy[0]), sec.radixceilingheights[0],
    RX_RadixX2Doom(sec, sec.radixheightnodesx[1]), RX_RadixY2Doom(sec, sec.radixheightnodesy[1]), sec.radixceilingheights[1],
    RX_RadixX2Doom(sec, sec.radixheightnodesx[2]), RX_RadixY2Doom(sec, sec.radixheightnodesy[2]), sec.radixceilingheights[2],
    ca, cb, cc, cd);
  sec.ca := ca;
  sec.cb := cb;
  sec.cic := 1 / cc;
  sec.cd := cd;
end;

procedure PS_SetFloorSlope(const secid: integer; const x1, y1, z1: fixed_t;
  const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);
var
  fx1, fy1, fz1: float;
  fx2, fy2, fz2: float;
  fx3, fy3, fz3: float;
  fa, fb, fc, fd: float;
  sec: Psector_t;
begin
  if (secid < 0) or (secid >= numsectors) then
    exit;

  sec := @sectors[secid];
  if (z1 = z2) and (z2 = z3) then
  begin
    sec.renderflags := sec.renderflags and not SRF_SLOPEFLOOR;
    sec.renderflags := sec.renderflags and not SRF_INTERPOLATE_FLOORSLOPE;
    sec.floorheight := z1;
    P_ChangeSector(sec, true);
  end
  else
  begin
    fx1 := x1 / FRACUNIT;
    fy1 := y1 / FRACUNIT;
    fz1 := z1 / FRACUNIT;
    fx2 := x2 / FRACUNIT;
    fy2 := y2 / FRACUNIT;
    fz2 := z2 / FRACUNIT;
    fx3 := x3 / FRACUNIT;
    fy3 := y3 / FRACUNIT;
    fz3 := z3 / FRACUNIT;
    calc_radix_plane(
      fx1, fy1, fz1,
      fx2, fy2, fz2,
      fx3, fy3, fz3,
      fa, fb, fc, fd);
    sec.fa := fa;
    sec.fb := fb;
    sec.fic := 1 / fc;
    sec.fd := fd;
    sec.renderflags := sec.renderflags or SRF_SLOPEFLOOR;
    P_SlopesAlignPlane(sec, nil, SRF_SLOPEFLOOR, false);
    sec.slopeline := sec.lines[0];
    sec.slopeline.renderflags := sec.slopeline.renderflags or LRF_SLOPED;
    sec.renderflags := sec.renderflags or SRF_INTERPOLATE_FLOORSLOPE;
    P_FixSlopedMobjs(sec);
  end;
end;

procedure PS_SetCeilingSlope(const secid: integer; const x1, y1, z1: fixed_t;
  const x2, y2, z2: fixed_t; const x3, y3, z3: fixed_t);
var
  fx1, fy1, fz1: float;
  fx2, fy2, fz2: float;
  fx3, fy3, fz3: float;
  ca, cb, cc, cd: float;
  sec: Psector_t;
begin
  if (secid < 0) or (secid >= numsectors) then
    exit;

  sec := @sectors[secid];
  if (z1 = z2) and (z2 = z3) then
  begin
    sec.renderflags := sec.renderflags and not SRF_SLOPECEILING;
    sec.renderflags := sec.renderflags and not SRF_INTERPOLATE_CEILINGSLOPE;
    sec.ceilingheight := z1;
    P_ChangeSector(sec, true);
  end
  else
  begin
    fx1 := x1 / FRACUNIT;
    fy1 := y1 / FRACUNIT;
    fz1 := z1 / FRACUNIT;
    fx2 := x2 / FRACUNIT;
    fy2 := y2 / FRACUNIT;
    fz2 := z2 / FRACUNIT;
    fx3 := x3 / FRACUNIT;
    fy3 := y3 / FRACUNIT;
    fz3 := z3 / FRACUNIT;
    calc_radix_plane(
      fx1, fy1, fz1,
      fx2, fy2, fz2,
      fx3, fy3, fz3,
      ca, cb, cc, cd);
    sec.ca := ca;
    sec.cb := cb;
    sec.cic := 1 / cc;
    sec.cd := cd;
    sec.renderflags := sec.renderflags or SRF_SLOPECEILING;
    P_SlopesAlignPlane(sec, nil, SRF_SLOPECEILING, false);
    sec.slopeline := sec.lines[0];
    sec.slopeline.renderflags := sec.slopeline.renderflags or LRF_SLOPED;
    sec.renderflags := sec.renderflags or SRF_INTERPOLATE_CEILINGSLOPE;
    P_FixSlopedMobjs(sec);
  end;
end;

procedure RX_LoadRadixMapInfo(const lumpnum: integer);
var
  sc: TScriptEngine;
  tokens: TTokenList;
  token: string;
  token_idx: integer;
  cursector: integer;
  curline: integer;
  a, b, c, d: integer;
  ang: LongWord;
begin
  if lumpnum < 0 then
    exit;

  tokens := TTokenList.Create;
  tokens.Add('SECTORID'); // 0
  tokens.Add('FLOORSLOPE'); // 1
  tokens.Add('CEILINGSLOPE'); // 2
  tokens.Add('XMUL'); // 3
  tokens.Add('XADD'); // 4
  tokens.Add('YMUL'); // 5
  tokens.Add('YADD'); // 6
  tokens.Add('FLOORANGLE'); // 7
  tokens.Add('FLOORANGLE_X'); // 8
  tokens.Add('FLOORANGLE_Y'); // 9
  tokens.Add('CEILINGANGLE'); // 10
  tokens.Add('CEILINGANGLE_X'); // 11
  tokens.Add('CEILINGANGLE_Y'); // 12
  tokens.Add('HEIGHTNODESX'); // 13
  tokens.Add('HEIGHTNODESY'); // 14
  tokens.Add('FLOORHEIGHTS'); // 15
  tokens.Add('CEILINGHEIGHTS'); // 16
  tokens.Add('WALLID'); // 17
  tokens.Add('WALLFLAGS'); // 18
  tokens.Add('WALLHITPOINTS'); // 19
  tokens.Add('WALLTRIGGER'); // 20
  tokens.Add('SECTORFLAGS'); // 21

  cursector := 0;
  curline := 0;
  sc := TScriptEngine.Create(W_TextLumpNum(lumpnum));
  while sc.GetString do
  begin
    token := strupper(sc._String);
    token_idx := tokens.IndexOfToken(token);
    case token_idx of
      0:  // sectorid
        begin
          sc.MustGetInteger;
          cursector := sc._Integer;
        end;
      1:  // floorslope
        begin
          sc.MustGetInteger;
          a := sc._Integer;
          sc.MustGetInteger;
          b := sc._Integer;
          sc.MustGetInteger;
          c := sc._Integer;
          sc.MustGetInteger;
          d := sc._Integer;

          // Set temporary values for the slope parameters
          // The values will be calced again, to eliminate
          // precision/integer-overflow errors
          // See also calc_radix_plane()
          sectors[cursector].fa := -a / (6 * FRACUNIT);
          sectors[cursector].fb := -c / (6 * FRACUNIT);
          sectors[cursector].fic := -1 / (b / (6 * FRACUNIT));
          sectors[cursector].fd := -d / (6 * FRACUNIT);

          sectors[cursector].radixfloorslope.a := a;
          sectors[cursector].radixfloorslope.b := b;
          sectors[cursector].radixfloorslope.c := c;
          sectors[cursector].radixfloorslope.d := d;
          sectors[cursector].renderflags := sectors[cursector].renderflags or SRF_SLOPEFLOOR or SRF_RADIXSLOPEFLOOR;
        end;
      2:  // ceilingslope
        begin
          sc.MustGetInteger;
          a := sc._Integer;
          sc.MustGetInteger;
          b := sc._Integer;
          sc.MustGetInteger;
          c := sc._Integer;
          sc.MustGetInteger;
          d := sc._Integer;

          // Set temporary values for the slope parameters
          // The values will be calced again, to eliminate
          // precision/integer-overflow errors
          // See also calc_radix_plane()
          sectors[cursector].ca := -a / (6 * FRACUNIT);
          sectors[cursector].cb := -c / (6 * FRACUNIT);
          sectors[cursector].cic := -1 / (b / (6 * FRACUNIT));
          sectors[cursector].cd := -d / (6 * FRACUNIT);

          sectors[cursector].radixceilingslope.a := a;
          sectors[cursector].radixceilingslope.b := b;
          sectors[cursector].radixceilingslope.c := c;
          sectors[cursector].radixceilingslope.d := d;
          sectors[cursector].renderflags := sectors[cursector].renderflags or SRF_SLOPECEILING or SRF_RADIXSLOPECEILING;
        end;
      3:  // xmul
        begin
          sc.MustGetInteger;
          sectors[cursector].radixmapXmult := sc._Integer;
        end;
      4:  // xadd
        begin
          sc.MustGetInteger;
          sectors[cursector].radixmapXAdd := sc._Integer;
        end;
      5:  // ymul
        begin
          sc.MustGetInteger;
          sectors[cursector].radixmapYmult := sc._Integer;
        end;
      6:  // yadd
        begin
          sc.MustGetInteger;
          sectors[cursector].radixmapYAdd := sc._Integer;
          if sectors[cursector].radixmapYAdd = RADIX_MAP_Y_ADD2 then
            level_position_hack := true;
        end;
      7: // floorangle
        begin
          sc.MustGetLongWord;
          ang := sc._LongWord;
          if ang >= 2048 then
            ang := ang - 2048;
          sectors[cursector].floorangle := ang * $200000;
        end;
      8: // floorangle_x
        begin
          sc.MustGetLongWord;
          sectors[cursector].radixfloorslope.x := sc._LongWord;
//          sectors[cursector].flooranglex := RX_RadixX2Doom(@sectors[cursector], sc._LongWord) * FRACUNIT;
//          sectors[cursector].floor_xoffs := -sectors[cursector].flooranglex;
        end;
      9: // floorangle_y
        begin
          sc.MustGetLongWord;
          sectors[cursector].radixfloorslope.y := sc._LongWord;
//          sectors[cursector].floorangley := RX_RadixY2Doom(@sectors[cursector], sc._LongWord) * FRACUNIT;
//          sectors[cursector].floor_yoffs := -sectors[cursector].floorangley;
        end;
     10: // ceilingangle
        begin
          sc.MustGetLongWord;
          ang := sc._LongWord;
          if ang >= 2048 then
            ang := ang - 2048;
          sectors[cursector].ceilingangle := ang * $200000;
        end;
     11: // ceilingangle_x
        begin
          sc.MustGetLongWord;
          sectors[cursector].radixceilingslope.x := sc._LongWord;
//          sectors[cursector].ceilinganglex := RX_RadixX2Doom(@sectors[cursector], sc._LongWord) * FRACUNIT;
//          sectors[cursector].ceiling_xoffs := -sectors[cursector].ceilinganglex;
        end;
     12: // ceilingangle_y
        begin
          sc.MustGetLongWord;
          sectors[cursector].radixceilingslope.y := sc._LongWord;
//          sectors[cursector].ceilingangley := RX_RadixY2Doom(@sectors[cursector], sc._LongWord) * FRACUNIT;
//          sectors[cursector].ceiling_yoffs := -sectors[cursector].ceilingangley;
        end;
     13: // heightnodesx
        begin
          sc.MustGetInteger;
          sectors[cursector].radixheightnodesx[0] := sc._Integer;
          sc.MustGetInteger;
          sectors[cursector].radixheightnodesx[1] := sc._Integer;
          sc.MustGetInteger;
          sectors[cursector].radixheightnodesx[2] := sc._Integer;
        end;
     14: // heightnodesy
        begin
          sc.MustGetInteger;
          sectors[cursector].radixheightnodesy[0] := sc._Integer;
          sc.MustGetInteger;
          sectors[cursector].radixheightnodesy[1] := sc._Integer;
          sc.MustGetInteger;
          sectors[cursector].radixheightnodesy[2] := sc._Integer;
        end;
     15:  // floorheights
        begin
          sc.MustGetInteger;
          sectors[cursector].radixfloorheights[0] := sc._Integer;
          sc.MustGetInteger;
          sectors[cursector].radixfloorheights[1] := sc._Integer;
          sc.MustGetInteger;
          sectors[cursector].radixfloorheights[2] := sc._Integer;
        end;
     16:  // ceilingheights
        begin
          sc.MustGetInteger;
          sectors[cursector].radixceilingheights[0] := sc._Integer;
          sc.MustGetInteger;
          sectors[cursector].radixceilingheights[1] := sc._Integer;
          sc.MustGetInteger;
          sectors[cursector].radixceilingheights[2] := sc._Integer;
          RX_CalcCeilingSlope(@sectors[cursector]);
        end;
     17:  // wallid
        begin
          sc.MustGetInteger;
          curline := sc._Integer;
        end;
     18:  // wallflags
        begin
          sc.MustGetInteger;
          lines[curline].radixflags := sc._Integer
        end;
     19:  // wallhitpoints
        begin
          sc.MustGetInteger;
          lines[curline].radixhitpoints := sc._Integer;
        end;
     20:  // walltrigger
        begin
          sc.MustGetInteger;
          lines[curline].radixtrigger := sc._Integer;
        end;
     21: // sectorflags
        begin
          sc.MustGetInteger;
          sectors[cursector].radixflags := sc._Integer;
        end;
    end;  // case
  end;

  sc.Free;
  tokens.Free;
end;

{$IFNDEF OPENGL}
function RX_CalculateRadixMidOffs(const seg: PSeg_t): fixed_t;
var
  line: Pline_t;
begin
  line := seg.linedef;
  if line.radixflags and RWF_PEGTOP_FLOOR <> 0 then
    result := worldtop
  else if line.radixflags and RWF_PEGTOP_CEILING <> 0 then
    result := line.frontsector.floorheight + textureheight[sides[line.sidenum[0]].midtexture] - viewz
  else
    result := -viewz;
end;

function RX_CalculateRadixTopOffs(const seg: PSeg_t): fixed_t;
var
  line: Pline_t;
begin
  line := seg.linedef;
  if line.radixflags and RWF_PEGBOTTOM_FLOOR <> 0 then
    result := worldtop
  else if line.radixflags and RWF_PEGBOTTOM_CEILING <> 0 then
    result := line.backsector.ceilingheight - viewz
  else
    result := -viewz;
end;

function RX_CalculateRadixBottomOffs(const seg: PSeg_t): fixed_t;
var
  line: Pline_t;
begin
  line := seg.linedef;
  if line.radixflags and RWF_PEGTOP_FLOOR <> 0 then
    result := line.backsector.floorheight - viewz
  else if line.radixflags and RWF_PEGTOP_CEILING <> 0 then
    result := worldtop //
  else
    result := -viewz;
end;

function RX_CalculateRadixSlopeMidOffs(const seg: PSeg_t): fixed_t;
begin
  result := -viewz;
end;

function RX_CalculateRadixSlopeTopOffs(const seg: PSeg_t): fixed_t;
var
  line: Pline_t;
begin
  line := seg.linedef;
  if line.radixflags and (RWF_PEGBOTTOM_CEILING or RWF_PEGBOTTOM_FLOOR) = 0 then
    result := - viewz
  else if line.radixflags and RWF_PEGBOTTOM_CEILING <> 0 then
    result := line.backsector.ceilingheight - viewz
  else
    result := line.frontsector.ceilingheight - viewz;
end;

function RX_CalculateRadixSlopeBottomOffs(const seg: PSeg_t): fixed_t;
var
  line: Pline_t;
begin
  line := seg.linedef;
  if line.radixflags and (RWF_PEGTOP_CEILING or RWF_PEGTOP_FLOOR) = 0 then
    result := -viewz
  else if line.radixflags and RWF_PEGTOP_CEILING <> 0 then
    result := line.frontsector.floorheight - viewz
  else
    result := line.backsector.floorheight - viewz;
end;
{$ENDIF}

const
  MAXRADIXLIGHTLEVEL = 64;

function RX_LightLevel(const l: integer; const flags: integer): byte;
begin
  if flags and (RSF_FOG or RSF_DARKNESS) = 0 then
    result := 200 + l div 2
  else if l >= MAXRADIXLIGHTLEVEL then
    result := 255
  else
    result := l * 4 + 2;
end;

const
  WALLEXPLOSIONOFFSET = 24;

const
  LEF_DELAY = 0;
  LEF_NODELAY = 1;

procedure RX_ExplosionParade(const x1, x2, y1, y2, z1, z2: integer; const side: integer;
  const fracdensity: integer; const flags: LongWord);
var
  i: integer;
  area, cnt: integer;
  mo: Pmobj_t;
  x, y, z: integer;
  dx, dy, dz: integer;
  angle: angle_t;
  c, s: fixed_t;
begin
  dx := x2 div FRACUNIT - x1 div FRACUNIT;
  dy := y2 div FRACUNIT - y1 div FRACUNIT;
  dz := z2 div FRACUNIT - z1 div FRACUNIT;

  // Every 64x64 px area 1 explosion when fracdensity = FRACUNIT
  area := (P_AproxDistance(x2 - x1, y2 - y1) div FRACUNIT * dz) div (64 * 64);
  cnt := (area * fracdensity) div FRACUNIT;

  if cnt <= 0 then
    cnt := 1;  // At least one explosion

  for i := 0 to cnt - 1 do
  begin
    x := x1 + dx * Sys_Random * 256;
    y := y1 + dy * Sys_Random * 256;
    z := z1 + dz * Sys_Random * 256;

    if side = 0 then
      angle := R_PointToAngle2(x1, y1, x2, y2) - ANG90
    else
      angle := R_PointToAngle2(x1, y1, x2, y2) + ANG90;

    angle := angle shr ANGLETOFINESHIFT;
    c := finecosine[angle];
    s := finesine[angle];
    x := x + WALLEXPLOSIONOFFSET * c;
    y := y + WALLEXPLOSIONOFFSET * s;

    mo := RX_SpawnRadixBigExplosion(x, y, z);
    mo.flags3_ex := mo.flags3_ex or MF3_EX_NOSOUND;
    if flags and LEF_NODELAY <> 0 then
    begin
      mo.tics := P_Random mod mo.tics;
      if mo.tics = 0 then
        mo.tics := 1;
    end
    else
      mo.tics := mo.tics + (P_Random and 63); // Some delay
  end;

  S_AmbientSound(x1 div 2 + x2 div 2, y1 div 2 + y2 div 2, 'radix/SndExplode');
end;

procedure RX_LineExplosion(const l: Pline_t; const flags: LongWord);
var
  x1, x2, y1, y2: integer;
  z1, z2: integer;
begin
  x1 := l.v1.x;
  y1 := l.v1.y;
  x2 := l.v2.x;
  y2 := l.v2.y;
  if l.backsector = nil then
  begin
    z1 := l.frontsector.floorheight;
    z2 := l.frontsector.ceilingheight;
    RX_ExplosionParade(x1, x2, y1, y2, z1, z2, 0, 2 * FRACUNIT, flags);
  end
  else
  begin
    if (l.frontsector.ceilingheight < l.backsector.ceilingheight) and
       (l.backsector.renderflags or SRF_SLOPECEILING <> 0) then
    begin
      z1 := l.frontsector.ceilingheight;
      z2 := l.backsector.ceilingheight;
      RX_ExplosionParade(x1, x2, y1, y2, z1, z2, 1, 2 * FRACUNIT, flags);
    end;
    if (l.frontsector.ceilingheight > l.backsector.ceilingheight) and
       (l.frontsector.renderflags or SRF_SLOPECEILING <> 0) then
    begin
      z1 := l.backsector.ceilingheight;
      z2 := l.frontsector.ceilingheight;
      RX_ExplosionParade(x1, x2, y1, y2, z1, z2, 0, 2 * FRACUNIT, flags);
    end;
    if (l.frontsector.floorheight < l.backsector.floorheight) and
       (l.frontsector.renderflags or SRF_SLOPEFLOOR <> 0) then
    begin
      z1 := l.frontsector.floorheight;
      z2 := l.backsector.floorheight;
      RX_ExplosionParade(x1, x2, y1, y2, z1, z2, 0, 2 * FRACUNIT, flags);
    end;
    if (l.frontsector.floorheight > l.backsector.floorheight) and
       (l.backsector.renderflags or SRF_SLOPEFLOOR <> 0) then
    begin
      z1 := l.backsector.floorheight;
      z2 := l.frontsector.floorheight;
      RX_ExplosionParade(x1, x2, y1, y2, z1, z2, 1, 2 * FRACUNIT, flags);
    end;
  end;
end;

procedure RX_LowerSectorToLowestFloor(const sec: Psector_t);
begin
  sec.floorheight := P_FindLowestFloorSurrounding(sec);
end;

procedure RX_RaiseSectorToHighestCeiling(const sec: Psector_t);
begin
  sec.ceilingheight := P_FindHighestCeilingSurrounding(sec);
end;

procedure RX_DamageLine(const l: Pline_t; const damage: integer);
var
  s: integer;
  flags: LongWord;

  procedure search_texture_change;
  var
    i: integer;
    s1, s2: Pside_t;
  begin
    for i := 0 to numlines - 1 do
      if lines[i].special = 289 then
        if l.tag = lines[i].tag then
        begin
          if l.sidenum[0] >= 0 then
            if lines[i].sidenum[0] > 0 then
            begin
              s1 := @sides[l.sidenum[0]];
              s2 := @sides[lines[i].sidenum[0]];
              s1.toptexture := s2.toptexture;
              s1.bottomtexture := s2.bottomtexture;
              s1.midtexture := s2.midtexture;
            end;

          if l.sidenum[1] >= 0 then
            if lines[i].sidenum[1] > 0 then
            begin
              s1 := @sides[l.sidenum[1]];
              s2 := @sides[lines[i].sidenum[1]];
              s1.toptexture := s2.toptexture;
              s1.bottomtexture := s2.bottomtexture;
              s1.midtexture := s2.midtexture;
            end;

          break;
        end;
  end;

begin
  if l.radixflags and (RWF_ACTIVATETRIGGER or RWF_MISSILEWALL or RWF_SHOOTABLE) = 0 then
    exit;

  l.radixhitpoints := l.radixhitpoints - damage - (damage * P_Random) div 128;
  if l.radixhitpoints <= 0 then
  begin
    if l.radixflags and RWF_ACTIVATETRIGGER <> 0 then
    begin
      l.radixflags := l.radixflags and not RWF_ACTIVATETRIGGER;
      radixtriggers[l.radixtrigger].suspended := 0;
      RX_RunTrigger(l.radixtrigger);
    end;

    flags := LEF_DELAY;

    // JVAL: 20200519 - Shootable specials
    if l.radixflags and RWF_SHOOTABLE <> 0 then
    begin
      case l.special of
        286:  // Lower tagged sector floor
          begin
            flags := flags or LEF_NODELAY;
            RX_LineExplosion(l, flags);
            s := -1;
            while P_FindSectorFromLineTag2(l, s) >= 0 do
              RX_LowerSectorToLowestFloor(@sectors[s]);
            search_texture_change;
          end;
        287:  // raise tagged sector ceiling
          begin
            flags := flags or LEF_NODELAY;
            RX_LineExplosion(l, flags);
            s := -1;
            while P_FindSectorFromLineTag2(l, s) >= 0 do
              RX_RaiseSectorToHighestCeiling(@sectors[s]);
            search_texture_change;
          end;
        288:  // just explode
          begin
            RX_LineExplosion(l, flags);
            search_texture_change;
          end;
        290:  // disable forcefield
          begin
            RX_LineExplosion(l, flags);
            s := -1;
            while P_FindSectorFromLineTag2(l, s) >= 0 do
              sectors[s].special := sectors[s].special and not FORCEFIELD_MASK;
            search_texture_change;
          end;
      end;
    end
    else
      RX_LineExplosion(l, flags);

    l.radixflags := l.radixflags and not (RWF_MISSILEWALL or RWF_SHOOTABLE);
  end;
end;

function RX_ShootableLine(const l: Pline_t): boolean;
begin
  if l.radixflags and (RWF_ACTIVATETRIGGER or RWF_MISSILEWALL) = 0 then
  begin
    result := false;
    exit;
  end;

  result := l.radixhitpoints > 0;
end;

function RX_LineLengthf(li: Pline_t): float;
var
  fx, fy: float;
begin
  fx := (li.v2.x - li.v1.x) / FRACUNIT;
  fy := (li.v2.y - li.v1.y) / FRACUNIT;
  result := sqrt(fx * fx + fy * fy);
end;

var
  LTfromx, LTfromy, LTfromz: fixed_t;
  LTtox, LTtoy, LTtoz: fixed_t;
  LTbbox: array[0..3] of fixed_t;
  LTline: Pline_t;

function PIT_LineTrace(ld: Pline_t): boolean;
var
  A1, B1, C1: int64;
  A2, B2, C2: int64;
  det: int64;
  x, y: int64;
  dist1, dist2: int64;
begin
  if ld.backsector <> nil then
  begin
    result := true;
    exit;
  end;

  if (LTbbox[BOXRIGHT] <= ld.bbox[BOXLEFT]) or
     (LTbbox[BOXLEFT] >= ld.bbox[BOXRIGHT]) or
     (LTbbox[BOXTOP] <= ld.bbox[BOXBOTTOM]) or
     (LTbbox[BOXBOTTOM] >= ld.bbox[BOXTOP]) then
  begin
    result := true;
    exit;
  end;

  if P_BoxOnLineSide(@LTbbox, ld) <> -1 then
  begin
    result := true;
    exit;
  end;

  A1 := LTtoy - LTfromy;
  B1 := LTfromx - LTtox;
  C1 := (A1 * LTfromx) div FRACUNIT + (B1 * LTfromy) div FRACUNIT;

  A2 := ld.v2.y - ld.v1.y;
  B2 := ld.v1.x - ld.v2.x;
  C2 := (A2 * ld.v1.x) div FRACUNIT + (B2 * ld.v1.y) div FRACUNIT;

  det := (A1 * B2) div FRACUNIT - (A2 * B1) div FRACUNIT;
  if det <> 0 then
  begin
    x := (B2 * C1 - B1 * C2) div det;
    y := (A1 * C2 - A2 * C1) div det;
    dist1 := ((LTfromx - x) div FRACUNIT) * (LTfromx - x) + ((LTfromy - y) div FRACUNIT) * (LTfromy - y);
    dist2 := ((LTfromx - LTtox) div FRACUNIT) * (LTfromx - LTtox) + ((LTfromy - LTtoy) div FRACUNIT) * (LTfromy - LTtoy);
    if dist1 < dist2 then
    begin
      LTtox := x;
      LTtoy := y;
      LTline := ld;
    end;
  end;

  result := true;
end;

procedure RX_LineTrace(const fromx, fromy, fromz: fixed_t; const tox, toy, toz: fixed_t; out newx, newy, newz: fixed_t);
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  floor, ceiling: fixed_t;
begin
  LTbbox[BOXLEFT] := MinI(fromx, tox);
  LTbbox[BOXRIGHT] := MaxI(fromx, tox);
  LTbbox[BOXBOTTOM] := MinI(fromy, toy);
  LTbbox[BOXTOP] := MaxI(fromy, toy);

  xl := MapBlockIntX(int64(LTbbox[BOXLEFT]) - int64(bmaporgx) - MAXRADIUS);
  xh := MapBlockIntX(int64(LTbbox[BOXRIGHT]) - int64(bmaporgx) + MAXRADIUS);
  yl := MapBlockIntY(int64(LTbbox[BOXBOTTOM]) - int64(bmaporgy) - MAXRADIUS);
  yh := MapBlockIntY(int64(LTbbox[BOXTOP]) - int64(bmaporgy) + MAXRADIUS);

  LTfromx := fromx;
  LTfromy := fromy;
  LTfromz := fromz;

  LTtox := tox;
  LTtoy := toy;
  LTtoz := toz;

  LTline := nil;
  for bx := xl to xh do
    for by := yl to yh do
      P_BlockLinesIterator(bx, by, PIT_LineTrace);

  newx := LTtox;
  newy := LTtoy;
  if LTline = nil then
  begin
    floor := P_3dFloorHeight(newx, newy, LTfromz);
    ceiling := P_3dCeilingHeight(newx, newy, LTfromz);
    newz := GetIntegerInRange(LTtoz, floor, ceiling);
  end
  else
  begin
    floor := P_3dFloorHeight(LTline.frontsector, newx, newy, LTfromz);
    ceiling := P_3dCeilingHeight(LTline.frontsector, newx, newy, LTfromz);
    newz := GetIntegerInRange(LTtoz, floor, ceiling);
  end;
end;

function RX_PointLineSqrDistance(const x, y: fixed_t; const line: Pline_t): integer;
var
  A, B, C, D: integer;
  dot: int64;
  len_sq: int64;
  param: int64;
  xx, yy: integer;
  dx, dy: integer;
  x1, x2, y1, y2: integer;
  ix, iy: integer;
begin
  x1 := line.v1.x div FRACUNIT;
  y1 := line.v1.y div FRACUNIT;
  x2 := line.v2.x div FRACUNIT;
  y2 := line.v2.y div FRACUNIT;
  ix := x div FRACUNIT;
  iy := y div FRACUNIT;

  A := ix - x1;
  B := iy - y1;
  C := x2 - x1;
  D := y2 - y1;

  dot := (A * C) + (B * D);
  len_sq := (C * C) + (D * D);
  param := -1;
  if len_sq <> 0 then
    param := (dot * FRACUNIT) div int64(len_sq);

  if param < 0 then
  begin
    xx := x1;
    yy := y1;
  end
  else if param > FRACUNIT then
  begin
    xx := x2;
    yy := y2;
  end
  else
  begin
    xx := x1 + (param * C) div FRACUNIT;
    yy := y1 + (param * D) div FRACUNIT;
  end;

  dx := ix - xx;
  dy := iy - yy;
  result := (dx * dx) + (dy * dy);
end;

end.

