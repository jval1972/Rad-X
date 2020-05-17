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
// DESCRIPTION:
//  Vertical fighting actions
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_vertical_fight;

interface

uses
  m_fixed,
  p_mobj_h;

function P_FindVericalPlayerTarget(vthing: Pmobj_t; const z1, z2: fixed_t; const radius: fixed_t): Pmobj_t;

procedure A_VericalLookForPlayers(actor: Pmobj_t);

procedure A_VerticalMissileUp(actor: Pmobj_t);

procedure A_VerticalMissileDown(actor: Pmobj_t);

implementation

uses
  d_delphi,
  doomdef,
  i_system,
  d_player,
  info,
  info_h,
  info_common,
  g_game,
  r_defs,
  r_main,
  p_common,
  p_mobj,
  p_sounds,
  p_setup,
  sc_states;

//
// P_PtInMap
// Checks if a given point is in map boundaries, also checks 3d floors
//
function P_PtInMap(const x, y, z: fixed_t; const step: fixed_t): boolean;
var
  s: Psubsector_t;
  sec: Psector_t;
begin
  s := R_PointInSubsector(x, y);
  if s.sector.midsec >= 0 then
  begin
    sec := @sectors[s.sector.midsec];
    result := (z >= sec.floorheight - step) and (z <= sec.ceilingheight + step);
  end
  else
    result := false;
  if not result then
    result := (z + step > s.sector.floorheight) and (z - step < s.sector.ceilingheight);
end;


var
  vsthing: Pmobj_t;
  vsz1, vsz2: fixed_t;
  vsradius: fixed_t;

const
  VSRADIUSSTEP = 32;

//
// PIT_CheckVerticalSight
//
function PIT_CheckVerticalSight(thing: Pmobj_t): boolean;
var
  x1, y1, z1: fixed_t;
  x2, y2, z2: fixed_t;
  dx, dy, dz: integer;
  maxstep: integer;
  i, iters: integer;
begin
  if thing = vsthing then
  begin // Don't check against self
    result := true;
    exit;
  end;

  if (abs(thing.x - vsthing.x) >= vsradius) or (abs(thing.y - vsthing.y) >= vsradius) then
  begin // Don't see thing
    result := true;
    exit;
  end;

  if thing.z > MaxI(vsz1, vsz2) then
  begin
    result := true;
    exit;
  end
  else if thing.z + thing.height < MinI(vsz1, vsz2) then
  begin // under thing
    result := true;
    exit;
  end;

  // JVAL: 20200424 - Trace to catch 3d floors or  sector obstacles
  x1 := thing.x;
  y1 := thing.y;
  z1 := thing.z;
  x2 := vsthing.x;
  y2 := vsthing.y;
  z2 := vsthing.z;
  dx := x2 - x1;
  dy := y2 - y1;
  dz := z2 - z1;

  maxstep := Max3I(abs(dx), abs(dy), abs(dz));
  iters := (maxstep div VSRADIUSSTEP) div FRACUNIT + 1;
  dx := dx div iters;
  dy := dy div iters;
  dz := dz div iters;

  for i := 0 to iters do
  begin
    x2 := x1 + i * dx;
    y2 := y1 + i * dy;
    z2 := z1 + i * dz;
    if not P_PtInMap(x2, y2, z2, VSRADIUSSTEP * FRACUNIT) then
    begin
      result := true;
      exit;
    end;
  end;

  result := false;
end;

function P_FindVericalPlayerTarget(vthing: Pmobj_t; const z1, z2: fixed_t; const radius: fixed_t): Pmobj_t;
var
  i: integer;
begin
  vsthing := vthing;
  vsz1 := z1;
  vsz2 := z2;
  vsradius := radius;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      if players[i].mo <> nil then
        if not PIT_CheckVerticalSight(players[i].mo) then
        begin
          result := players[i].mo;
          exit;
        end;
  result := nil;
end;

//
// A_VericalLookForPlayers(z1, z1, radius=128,[state=see])
//
procedure A_VericalLookForPlayers(actor: Pmobj_t);
var
  z1, z2: fixed_t;
  radius: fixed_t;
  targ: Pmobj_t;
  st: integer;
begin
  if not P_CheckStateParams(actor, 2, CSP_AT_LEAST) then
    exit;

  // JVAL: 20200517 - Inactive (stub) enemies
  if actor.flags3_ex and MF3_EX_INACTIVE <> 0 then
    exit;

  z1 := actor.state.params.FixedVal[0];
  z2 := actor.state.params.FixedVal[1];
  if actor.state.params.Count > 2 then
    radius := actor.state.params.FixedVal[2]
  else
    radius := 128 * FRACUNIT;

  targ := P_FindVericalPlayerTarget(actor, z1, z2, radius);
  if targ <> nil then
  begin
    actor.threshold := 0;
    actor.target := targ;

    if actor.info.seesound <> 0 then
      A_SeeSound(actor, actor);

    if actor.state.params.Count > 3 then
    begin
      st := P_GetStateFromNameWithOffsetCheck(actor, actor.state.params.StrVal[3]);
      if @states[st] <> actor.state then
        P_SetMobjState(actor, statenum_t(st));
    end
    else
      P_SetMobjState(actor, statenum_t(actor.info.seestate));
  end;
end;

//
// P_VerticalMissile
//
procedure P_VerticalMissile(actor: Pmobj_t; const direction: integer);
var
  targ, th: Pmobj_t;
  mobj_no: integer;
  x, y, z: fixed_t;
  speed: fixed_t;
  tics: integer;
  maxmomxy: fixed_t;
  dx, dy, dz: fixed_t;
begin
  if not P_CheckStateParams(actor, 4, CSP_AT_LEAST) then
    exit;

  targ := actor.target;
  if (targ = nil) or (targ = actor) then
    exit;

  if actor.state.params.IsComputed[0] then
    mobj_no := actor.state.params.IntVal[0]
  else
  begin
    mobj_no := Info_GetMobjNumForName(actor.state.params.StrVal[0]);
    actor.state.params.IntVal[0] := mobj_no;
  end;
  if mobj_no = -1 then
  begin
    I_Warning('P_VerticalMissile(): Unknown missile %s'#13#10, [actor.state.params.StrVal[0]]);
    exit;
  end;

  x := actor.x + actor.state.params.FixedVal[1];
  y := actor.y + actor.state.params.FixedVal[2];
  z := actor.z + actor.state.params.FixedVal[3];

  dx := targ.x - x;
  dy := targ.y - y;
  dz := targ.z - z;

  if Isign(dz) <> Isign(direction) then
    exit;

  th := P_SpawnMobj(x, y, z, mobj_no);

  speed := th.info.speed;
  if speed < 2048 then
    speed := speed * FRACUNIT;
  if speed = 0 then
    speed := 12 * FRACUNIT;

  tics := abs(dz) div speed;
  if tics < 1 then
    tics := 1;

  A_SeeSound(th, th);

  th.target := actor;  // where it came from

  th.momx := dx div tics;
  th.momy := dy div tics;

  // Match target velocity
  if (targ.flags and MF_SHADOW = 0) or (actor.flags2_ex and MF2_EX_SEEINVISIBLE <> 0) then
  begin
    th.momx := th.momx + targ.momx;
    th.momy := th.momy + targ.momy;
  end;

  if actor.state.params.Count >= 5 then
    maxmomxy := abs(actor.state.params.FixedVal[4])
  else
    maxmomxy := speed;
  // Limit speed
  th.momx := GetIntegerInRange(dx div tics, -maxmomxy, maxmomxy);
  th.momy := GetIntegerInRange(dy div tics, -maxmomxy, maxmomxy);

  if dz < 0 then
    th.momz := -speed
  else
    th.momz := speed;

  P_CheckMissileSpawn(th);
end;

//
// A_VerticalMissileUp(missiletype: string, x, y, z, maxmomxy)
//
procedure A_VerticalMissileUp(actor: Pmobj_t);
begin
  P_VerticalMissile(actor, 1);
end;

//
// A_VerticalMissileDown(missiletype: string, x, y, z, maxmomxy)
//
procedure A_VerticalMissileDown(actor: Pmobj_t);
begin
  P_VerticalMissile(actor, -1);
end;

end.
