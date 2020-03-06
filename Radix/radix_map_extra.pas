//
//  RAD: Recreation of the game "Radix - beyond the void"
//       powered by the DelphiDoom engine
//
//  Copyright (C) 1995 by Epic MegaGames, Inc.
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2020 by Jim Valavanis
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
  m_fixed,
  r_defs;

function RX_RadixX2Doom(const sec: Psector_t; const x: integer): integer;

function RX_RadixY2Doom(const sec: Psector_t; const y: integer): integer;

procedure RX_CalcFloorSlope(const sec: Psector_t);

procedure RX_CalcCeilingSlope(const sec: Psector_t);

// Parse map lump for extra information about radix level
procedure RX_LoadRadixMapInfo(const lumpnum: integer);

function RX_CalculateRadixMidOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixTopOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixBottomOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixSlopeMidOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixSlopeTopOffs(const seg: PSeg_t): fixed_t;

function RX_CalculateRadixSlopeBottomOffs(const seg: PSeg_t): fixed_t;

function RX_LightLevel(const l: integer): byte;

implementation

uses
  d_delphi,
  p_setup,
  r_data,
  r_main,
  r_segs,
  radix_level,
  sc_engine,
  sc_tokens,
  w_wad;

// radixmapXmult & radixmapYmult must be -1 or 1, no other values allowed :)
function RX_RadixX2Doom(const sec: Psector_t; const x: integer): integer;
begin
  result := x * sec.radixmapXmult + sec.radixmapXadd;
end;

function RX_RadixY2Doom(const sec: Psector_t; const y: integer): integer;
begin
  result := y * sec.radixmapYmult + sec.radixmapYadd;
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
        end;
      9: // floorangle_y
        begin
          sc.MustGetLongWord;
          sectors[cursector].radixfloorslope.y := sc._LongWord;
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
        end;
     12: // ceilingangle_y
        begin
          sc.MustGetLongWord;
          sectors[cursector].radixceilingslope.y := sc._LongWord;
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
          lines[curline].radixflags := sc._Integer;
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
    end;  // case
  end;

  sc.Free;
  tokens.Free;
end;

function RX_CalculateRadixMidOffs(const seg: PSeg_t): fixed_t;
var
  line: Pline_t;
begin
  line := seg.linedef;
  if line.radixflags and RWF_PEGTOP_FLOOR = 0 then
    result := -viewz
  else if line.radixflags and RWF_PEGBOTTOM_FLOOR <> 0 then
    result := worldlow
  else
    result := worldtop;
end;

function RX_CalculateRadixTopOffs(const seg: PSeg_t): fixed_t;
var
  line: Pline_t;
begin
  line := seg.linedef;
  if line.radixflags and RWF_PEGTOP_CEILING = 0 then
    result := seg.linedef.backsector.ceilingheight - viewz
  else if line.radixflags and RWF_PEGBOTTOM_CEILING <> 0 then
    result := worldlow
  else
    result := worldtop;
end;

function RX_CalculateRadixBottomOffs(const seg: PSeg_t): fixed_t;
var
  line: Pline_t;
begin
  line := seg.linedef;
  if line.radixflags and RWF_PEGTOP_FLOOR = 0 then
    result := -viewz
  else if line.radixflags and RWF_PEGBOTTOM_FLOOR <> 0 then
    result := worldlow
  else
    result := worldtop;
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
  if line.radixflags and (RWF_PEGBOTTOM_CEILING or RWF_PEGTOP_CEILING) = 0 then
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
  if line.radixflags and (RWF_PEGBOTTOM_FLOOR or RWF_PEGTOP_FLOOR) = 0 then
    result := -viewz
  else if line.radixflags and RWF_PEGBOTTOM_FLOOR <> 0 then
    result := line.frontsector.floorheight - viewz
  else
    result := line.backsector.floorheight - viewz;
end;

function RX_LightLevel(const l: integer): byte;
begin
  result := l * 4 + 2;
end;

end.
