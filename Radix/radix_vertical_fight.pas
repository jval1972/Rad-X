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
//  Movement, collision handling.
//  Shooting and aiming.
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

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  info,
  info_h,
  g_game,
  r_defs,
  r_main,
  p_common,
  p_mobj,
  p_sounds,
  p_setup,
  sc_states;

function P_PtInMap(const x, y, z: fixed_t; const radius: fixed_t): boolean;
var
  s: Psubsector_t;
  sec: Psector_t;
begin
  s := R_PointInSubsector(x, y);
  if s.sector.midsec >= 0 then
  begin
    sec := @sectors[s.sector.midsec];
    result := (z >= sec.floorheight - radius) and (z <= sec.ceilingheight + radius);
  end
  else
    result := false;
  if not result then
    result := (z + radius > s.sector.floorheight) and (z - radius < s.sector.ceilingheight);
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

end.
