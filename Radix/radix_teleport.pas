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
//  DESCRIPTION:
//   Radix teleport
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_teleport;

interface

uses
  m_fixed,
  p_mobj_h;

//==============================================================================
//
// RX_SpawnTeleportForceField
//
//==============================================================================
procedure RX_SpawnTeleportForceField(const mo: Pmobj_t);

//==============================================================================
//
// RX_SpawnTeleportForceFieldXYZ
//
//==============================================================================
procedure RX_SpawnTeleportForceFieldXYZ(const x, y, z: fixed_t);

//==============================================================================
//
// RX_DoomFogPresent
//
//==============================================================================
function RX_DoomFogPresent: boolean;

implementation

uses
  d_delphi,
  m_rnd,
  tables,
  info,
  info_h,
  info_common,
  p_mobj,
  p_pspr,
  radix_sounds,
  w_wad;

const
  TELEPORTDENSITY = 1000;

var
  radixteleportforcefield_id: integer = -1;

//==============================================================================
//
// RX_SpawnTeleportForceField
//
//==============================================================================
procedure RX_SpawnTeleportForceField(const mo: Pmobj_t);
var
  i: integer;
  tt: Pmobj_t;
  an: angle_t;
  dist: integer;
begin
  if radixteleportforcefield_id < 0 then
    radixteleportforcefield_id := Info_GetMobjNumForName('MT_TELEPORTFORCEFIELD');

  for i := 0 to TELEPORTDENSITY - 1 do
  begin
    an := Sys_Random * (FINEANGLES div 256);
    dist := 32 + P_Random and 63;
    tt := P_SpawnMobj(mo.x + dist * finecosine[an],
                      mo.y + dist * finesine[an],
                      mo.z + (P_Random - 128) * FRACUNIT, radixteleportforcefield_id);
    tt.momx := finecosine[an] * (256 + Sys_Random) div 256;
    tt.momy := finesine[an] * (256 + Sys_Random) div 256;
    tt.momz := mo.momz + Isign(P_Random - 128) * Sys_Random * 1024;
  end;

  S_AmbientSound(mo.x, mo.y, 'radix/SndTelePort');
end;

//==============================================================================
//
// RX_SpawnTeleportForceFieldXYZ
//
//==============================================================================
procedure RX_SpawnTeleportForceFieldXYZ(const x, y, z: fixed_t);
var
  i: integer;
  tt: Pmobj_t;
  an: angle_t;
  dist: integer;
begin
  if radixteleportforcefield_id < 0 then
    radixteleportforcefield_id := Info_GetMobjNumForName('MT_TELEPORTFORCEFIELD');

  for i := 0 to TELEPORTDENSITY - 1 do
  begin
    an := Sys_Random * (FINEANGLES div 256);
    dist := 32 + P_Random and 63;
    tt := P_SpawnMobj(x + dist * finecosine[an],
                      y + dist * finesine[an],
                      z + (P_Random - 128) * FRACUNIT, radixteleportforcefield_id);
    tt.momx := finecosine[an] * (256 + Sys_Random) div 256;
    tt.momy := finesine[an] * (256 + Sys_Random) div 256;
  end;

  S_AmbientSound(x, y, 'radix/SndTelePort');
end;

var
  doomfogpresent: boolean;
  doomfogpresent_checked: boolean = false;

//==============================================================================
//
// RX_DoomFogPresent
//
//==============================================================================
function RX_DoomFogPresent: boolean;
var
  st: integer;
  spr: string;
begin
  if doomfogpresent_checked then
  begin
    result := doomfogpresent;
    exit;
  end;

  doomfogpresent_checked := true;
  result := false;
  doomfogpresent := result;
  st := mobjinfo[Ord(MT_TFOG)].spawnstate;
  if st < 0 then
    exit;

  spr :=
    Chr(sprnames[states[st].sprite] and $FF) +
    Chr((sprnames[states[st].sprite] shr 8) and $FF) +
    Chr((sprnames[states[st].sprite] shr 16) and $FF) +
    Chr((sprnames[states[st].sprite] shr 24) and $FF) +
    Chr(Ord('A') + states[st].frame and FF_FRAMEMASK);

  result := (W_CheckNumForName(spr + '0') >= 0) or (W_CheckNumForName(spr + '1') >= 0);
  doomfogpresent := result;
end;

end.
