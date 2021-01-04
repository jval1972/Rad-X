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
// DESCRIPTION:
//  Slopes.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit p_slopes;

interface

uses
  m_fixed,
  r_defs;

function P_FloorHeight(const sec: Psector_t; const x, y: fixed_t): fixed_t; overload;

function P_FloorHeight(const x, y: fixed_t): fixed_t; overload;

function P_CeilingHeight(const sec: Psector_t; const x, y: fixed_t): fixed_t; overload;

function P_CeilingHeight(const x, y: fixed_t): fixed_t; overload;

procedure P_SlopesSetup;

procedure P_FixSlopedMobjs(const s: Psector_t);

procedure P_DynamicSlope(const sec: Psector_t);

procedure P_SlopesAlignPlane(const sec: Psector_t; const line: Pline_t; const flag: LongWord;
  const calcpivotline: boolean = true);

const
  SLOPECOUNTDOWN = 4;

implementation

uses
  d_delphi,
  Math,
  doomdata,
  m_vectors,
  radix_map_extra,
  p_gravity,
  p_setup,
  p_mobj_h,
  p_spec,
  r_main,
  tables;

function ZatPointFloor(const s: Psector_t; const x, y: fixed_t): fixed_t;
begin
  result := Round(((-s.fa * (x / FRACUNIT) - s.fb * (y / FRACUNIT) - s.fd) * s.fic) * FRACUNIT);
end;

function ZatPointCeiling(const s: Psector_t; const x, y: fixed_t): fixed_t;
begin
  result := Round(((-s.ca * (x / FRACUNIT) - s.cb * (y / FRACUNIT) - s.cd) * s.cic) * FRACUNIT);
end;

function P_FloorHeight(const sec: Psector_t; const x, y: fixed_t): fixed_t; overload;
begin
  if sec.renderflags and SRF_SLOPEFLOOR <> 0 then
    result := ZatPointFloor(sec, x, y)
  else
    result := sec.floorheight;
end;

function P_FloorHeight(const x, y: fixed_t): fixed_t; overload;
begin
  result := P_FloorHeight(R_PointInSubSector(x, y).sector, x, y);
end;

function P_CeilingHeight(const sec: Psector_t; const x, y: fixed_t): fixed_t; overload;
begin
  if sec.renderflags and SRF_SLOPECEILING <> 0 then
    result := ZatPointCeiling(sec, x, y)
  else
    result := sec.ceilingheight;
end;

function P_CeilingHeight(const x, y: fixed_t): fixed_t; overload;
begin
  result := P_CeilingHeight(R_PointInSubSector(x, y).sector, x, y);
end;

type
  zvertex_t = record
    zc, zf: fixed_t;
  end;
  Pzvertex_t = ^zvertex_t;
  zvertex_tArray = array[0..$FFF] of zvertex_t;
  Pzvertex_tArray = ^zvertex_tArray;

function zvertex(const v: Pvertex_t; const A: Pzvertex_tArray): Pzvertex_t;
var
  id: integer;
begin
  id := pDiff(v, vertexes, SizeOf(vertex_t));
  if id < 0 then
    result := nil
  else if id >= numvertexes then
    result := nil
  else
    result := @A[id];
end;

function linelen(const l: Pline_t): float;
var
  dx, dy: float;
begin
  dx := l.dx / FRACUNIT;
  dy := l.dy / FRACUNIT;
  result := sqrt(dx * dx + dy * dy);
end;

procedure P_SlopesAlignPlane(const sec: Psector_t; const line: Pline_t; const flag: LongWord;
  const calcpivotline: boolean = true);
var
  refsec: Psector_t;
  i, j: integer;
  side: integer;
  bestdist, dist: integer;
  refvert: Pvertex_t;
  refline: Pline_t;
  srcheight, destheight: fixed_t;
  v1, v2, cross: vec3_t;
  vert: Pvertex_t;
  sid: integer;
  zvertexes: Pzvertex_tArray;
  sd: Pside_t;
  start: integer;
begin
  if calcpivotline then
  begin
    {$IFDEF HEXEN}
    if line.arg1 <> 0 then
    {$ELSE}
    if line.tag <> 0 then
    {$ENDIF}
    begin
      start := -1;
      sid := P_FindSectorFromLineTag2(line, start);
      if sid < 0 then
        exit;
      refsec := @sectors[sid];
    end
    else if line.flags and ML_TWOSIDED <> 0 then
    begin
      refsec := line.backsector;
      if refsec = sec then
        refsec := line.frontsector;
      if refsec = nil then
        exit;
    end
    else
      exit;

    refvert := line.v1;

    sec.slopeline := line;
    refsec.slopesec := sec;
    if flag = SRF_SLOPEFLOOR then
    begin
      srcheight := sec.floorheight;
      destheight := refsec.floorheight;
    end
    else
    begin
      srcheight := sec.ceilingheight;
      destheight := refsec.ceilingheight;
    end;

    if srcheight = destheight then
    begin
      sec.renderflags := sec.renderflags and not SRF_SLOPED;
      for i := 0 to sec.linecount - 1 do
      begin
        refline := sec.lines[i];
        if refline.frontsector.renderflags and SRF_SLOPED = 0 then
        begin
          if refline.backsector = nil then
            refline.renderflags := refline.renderflags and not LRF_SLOPED
          else if refline.backsector.renderflags and SRF_SLOPED = 0 then // JVAL: Sos
            refline.renderflags := refline.renderflags and not LRF_SLOPED;
        end;
        exit;
      end;
    end;

    if flag = SRF_SLOPEFLOOR then
      sec.renderflags := sec.renderflags or SRF_SLOPEFLOOR
    else
      sec.renderflags := sec.renderflags or SRF_SLOPECEILING;

    bestdist := 0;
    for i := 0 to sec.linecount - 1 do
    begin
      // First vertex
      vert := sec.lines[i].v1;
      dist := abs(
        ((line.v1.y - vert.y) div FRACUNIT) * (line.dx div FRACUNIT) -
        ((line.v1.x - vert.x) div FRACUNIT) * (line.dy div FRACUNIT)
      );
      if dist > bestdist then
      begin
        bestdist := dist;
        refvert := vert;
      end;
      // Second vertex
      vert := sec.lines[i].v2;
      dist := abs(
        ((line.v1.y - vert.y) div FRACUNIT) * (line.dx div FRACUNIT) -
        ((line.v1.x - vert.x) div FRACUNIT) * (line.dy div FRACUNIT)
      );
      if dist > bestdist then
      begin
        bestdist := dist;
        refvert := vert;
      end;
    end;

    v1[0] := line.dx / FRACUNIT;
    v1[1] := line.dy / FRACUNIT;
    v1[2] := 0.0;
    v2[0] := (refvert.x - line.v1.x) / FRACUNIT;
    v2[1] := (refvert.y - line.v1.y) / FRACUNIT;
    v2[2] := (srcheight - destheight) / FRACUNIT;

    CrossProduct(@v1, @v2, @cross);
    VectorNormalize(@cross);

    if ((cross[2] < 0) and (flag = SRF_SLOPEFLOOR)) or ((cross[2] > 0) and (flag = SRF_SLOPECEILING)) then
    begin
      cross[0] := -cross[0];
      cross[1] := -cross[1];
      cross[2] := -cross[2];
    end;

    if flag = SRF_SLOPEFLOOR then
    begin
      sec.fa := cross[0];
      sec.fb := cross[1];
      sec.fic := 1.0 / cross[2];
      sec.fd := -cross[0] * (line.v1.x / FRACUNIT) -
                 cross[1] * (line.v1.y / FRACUNIT) -
                 cross[2] * (destheight / FRACUNIT);
    end
    else
    begin
      sec.ca := cross[0];
      sec.cb := cross[1];
      sec.cic := 1.0 / cross[2];
      sec.cd := -cross[0] * (line.v1.x / FRACUNIT) -
                 cross[1] * (line.v1.y / FRACUNIT) -
                 cross[2] * (destheight / FRACUNIT);
    end;
  end;

  zvertexes := mallocz(numvertexes * SizeOf(zvertex_t));

  for i := numsubsectors - 1 downto 0 do
    if subsectors[i].sector = sec then
      for j := subsectors[i].firstline + subsectors[i].numlines - 1 downto subsectors[i].firstline do
      begin
        if flag = SRF_SLOPEFLOOR then
          zvertex(segs[j].v1, zvertexes).zf := ZatPointFloor(sec, segs[j].v1.x, segs[j].v1.y)
        else
          zvertex(segs[j].v1, zvertexes).zc := ZatPointCeiling(sec, segs[j].v1.x, segs[j].v1.y);
      end;

  for i := sec.linecount - 1 downto 0 do
  begin
    refline := sec.lines[i];
    sd := @sides[refline.sidenum[0]];
    if sd.sector = sec then
      side := 0
    else
      side := 1;
    refline.renderflags := refline.renderflags or LRF_SLOPED;
    if flag = SRF_SLOPEFLOOR then
      refline.flslopestep[side] :=
        ((zvertex(refline.v1, zvertexes).zf - zvertex(refline.v2, zvertexes).zf) / FRACUNIT) / linelen(refline)
    else
      refline.clslopestep[side] :=
        ((zvertex(refline.v1, zvertexes).zc - zvertex(refline.v2, zvertexes).zc) / FRACUNIT) / linelen(refline);
  end;

  memfree(Pointer(zvertexes), SizeOf(zvertex_t));
end;

procedure P_FixSlopedMobjs(const s: Psector_t);
var
  mo: Pmobj_t;
  grav: fixed_t;
begin
  mo := s.thinglist;
  // JVAL: 20200429 - Sector thinglist consistency
  inc(sectorvalidcount);
  while (mo <> nil) and (mo.sectorvalidcount <> sectorvalidcount) do
  begin
    mo.sectorvalidcount := sectorvalidcount;

    if mo.flags and MF_NOGRAVITY <> 0 then
      grav := 0
    else
      grav := FixedMul(P_GetSectorGravity(s), mo.gravity);

    mo.floorz := P_FloorHeight(s, mo.x, mo.y);
    mo.ceilingz := P_CeilingHeight(s, mo.x, mo.y);

    if mo.z - grav < mo.floorz then
      mo.z := mo.floorz
    else if (grav = 0) or (mo.z > mo.ceilingz) then
      mo.z := mo.ceilingz;

    mo := mo.snext;
  end;
end;

procedure P_DynamicSlope(const sec: Psector_t);
var
 s: Psector_t;
 sl: Pline_t;
begin
  if sec.slopesec <> nil then
    s := sec.slopesec
  else
    s := sec;
  sl := s.slopeline;
  if sl <> nil then
  begin
    if (sl.special = 386) or
       (sl.special = 388) or
       (sl.special = 389) or
       (sl.special = 391) then
    begin
      s.renderflags := s.renderflags and not SRF_RADIXSLOPEFLOOR;
      P_SlopesAlignPlane(s, sl, SRF_SLOPEFLOOR);
    end;

    if (sl.special = 387) or
       (sl.special = 388) or
       (sl.special = 390) or
       (sl.special = 391) then
    begin
      s.renderflags := s.renderflags and not SRF_RADIXSLOPECEILING;
      P_SlopesAlignPlane(s, sl, SRF_SLOPECEILING);
    end;
    P_FixSlopedMobjs(s);
  end;
end;

procedure P_SlopesSetup;
var
  i, j: integer;
begin
  // JVAL: 20200225 - Create slopes from radix map
  for i := 0 to numsectors - 1 do
  begin
    if sectors[i].renderflags and SRF_RADIXSLOPEFLOOR <> 0 then
    begin
      RX_CalcFloorSlope(@sectors[i]);
      P_SlopesAlignPlane(@sectors[i], nil, SRF_SLOPEFLOOR, false);
      sectors[i].renderflags := sectors[i].renderflags and not SRF_RADIXSLOPEFLOOR;
      sectors[i].slopeline := sectors[i].lines[0];
      sectors[i].slopeline.renderflags := sectors[i].slopeline.renderflags or LRF_SLOPED;
    end;
    if sectors[i].renderflags and SRF_RADIXSLOPECEILING <> 0 then
    begin
      RX_CalcCeilingSlope(@sectors[i]);
      P_SlopesAlignPlane(@sectors[i], nil, SRF_SLOPECEILING, false);
      sectors[i].renderflags := sectors[i].renderflags and not SRF_RADIXSLOPECEILING;
      sectors[i].slopeline := sectors[i].lines[0];
      sectors[i].slopeline.renderflags := sectors[i].slopeline.renderflags or LRF_SLOPED;
    end;
    if sectors[i].renderflags and (SRF_RADIXSLOPEFLOOR or SRF_RADIXSLOPECEILING) <> 0 then
      for j := 0 to sectors[i].linecount - 1 do
        if sectors[i].lines[j].frontsector <> nil then
          if sectors[i].lines[j].backsector <> nil then
            sectors[i].lines[j].flags := sectors[i].lines[j].flags or ML_NOCLIP;
  end;

  for i := 0 to numlines - 1 do
  begin
    case lines[i].special of
    // JVAL: Use same specials as Eternity Engine
      386:  // The floor of the front sector is sloped to reach the height of
            // the back sector floor.
        if lines[i].frontsector <> nil then
        begin
          lines[i].frontsector.renderflags := lines[i].frontsector.renderflags and not SRF_RADIXSLOPEFLOOR;
          P_SlopesAlignPlane(lines[i].frontsector, @lines[i], SRF_SLOPEFLOOR);
        end;
      387:  // The ceiling of the front sector is sloped to reach the height of
            // the back sector ceiling.
        if lines[i].frontsector <> nil then
        begin
          lines[i].frontsector.renderflags := lines[i].frontsector.renderflags and not SRF_RADIXSLOPECEILING;
          P_SlopesAlignPlane(lines[i].frontsector, @lines[i], SRF_SLOPECEILING);
        end;
      388:  // The floor and the ceiling of the front sector are sloped to reach
            // the height of the back sector floor and ceiling respectively.
        if lines[i].frontsector <> nil then
        begin
          lines[i].frontsector.renderflags := lines[i].frontsector.renderflags and not SRF_RADIXSLOPEFLOOR;
          P_SlopesAlignPlane(lines[i].frontsector, @lines[i], SRF_SLOPEFLOOR);
          lines[i].frontsector.renderflags := lines[i].frontsector.renderflags and not SRF_RADIXSLOPECEILING;
          P_SlopesAlignPlane(lines[i].frontsector, @lines[i], SRF_SLOPECEILING);
        end;
      389:  // The floor of the back sector is sloped to reach the height of
            // the front sector floor.
        if lines[i].backsector <> nil then
        begin
          lines[i].backsector.renderflags := lines[i].backsector.renderflags and not SRF_RADIXSLOPEFLOOR;
          P_SlopesAlignPlane(lines[i].backsector, @lines[i], SRF_SLOPEFLOOR);
        end;
      390:  // The ceiling of the front sector is sloped to reach the height of
            // the front sector ceiling.
        if lines[i].backsector <> nil then
        begin
          lines[i].backsector.renderflags := lines[i].backsector.renderflags and not SRF_RADIXSLOPECEILING;
          P_SlopesAlignPlane(lines[i].backsector, @lines[i], SRF_SLOPECEILING);
        end;
      391:  // The floor and the ceiling of the back sector are sloped to reach
            // the height of the front sector floor and ceiling respectively.
        if lines[i].backsector <> nil then
        begin
          lines[i].backsector.renderflags := lines[i].backsector.renderflags and not SRF_RADIXSLOPEFLOOR;
          P_SlopesAlignPlane(lines[i].backsector, @lines[i], SRF_SLOPEFLOOR);
          lines[i].backsector.renderflags := lines[i].backsector.renderflags and not SRF_RADIXSLOPECEILING;
          P_SlopesAlignPlane(lines[i].backsector, @lines[i], SRF_SLOPECEILING);
        end;
    end
  end;
end;

end.

