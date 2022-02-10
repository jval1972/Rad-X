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
//   Radix objects
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_objects;

interface

uses
  m_fixed,
  p_mobj_h;

//==============================================================================
//
// RX_SpawnRadixBigExplosion
//
//==============================================================================
function RX_SpawnRadixBigExplosion(const x, y, z: fixed_t): Pmobj_t;

//==============================================================================
//
// RX_SpawnRadixSmallExplosion
//
//==============================================================================
function RX_SpawnRadixSmallExplosion(const x, y, z: fixed_t): Pmobj_t;

//==============================================================================
//
// PX_SpawnWallMissileObject
//
//==============================================================================
function PX_SpawnWallMissileObject(const x, y, z: fixed_t): Pmobj_t;

//==============================================================================
//
// RX_SpawnRadixEnemyMissile
//
//==============================================================================
function RX_SpawnRadixEnemyMissile(const x, y, z: fixed_t): Pmobj_t;

//==============================================================================
//
// RX_SpawnRadixEnemySeekerMissile
//
//==============================================================================
function RX_SpawnRadixEnemySeekerMissile(const x, y, z: fixed_t): Pmobj_t;

//==============================================================================
//
// RX_SpawnRadixBigSmoke
//
//==============================================================================
function RX_SpawnRadixBigSmoke(const x, y, z: fixed_t): Pmobj_t;

//==============================================================================
//
// RX_SpawnAlienBlood
//
//==============================================================================
procedure RX_SpawnAlienBlood(x, y, z: fixed_t);

implementation

uses
  d_delphi,
  m_rnd,
  info_common,
  p_mobj;

var
  radixbigexposion_id: integer = -1;

//==============================================================================
//
// RX_SpawnRadixBigExplosion
//
//==============================================================================
function RX_SpawnRadixBigExplosion(const x, y, z: fixed_t): Pmobj_t;
begin
  if radixbigexposion_id < 0 then
    radixbigexposion_id := Info_GetMobjNumForName('MT_RADIXBIGEXPLOSION');

  result := P_SpawnMobj(x, y, z, radixbigexposion_id);
end;

var
  radixsmallexplosion_id: integer = -1;

//==============================================================================
//
// RX_SpawnRadixSmallExplosion
//
//==============================================================================
function RX_SpawnRadixSmallExplosion(const x, y, z: fixed_t): Pmobj_t;
begin
  if radixsmallexplosion_id < 0 then
    radixsmallexplosion_id := Info_GetMobjNumForName('MT_RADIXSMALLEXPLOSION');

  result := P_SpawnMobj(x, y, z, radixsmallexplosion_id);
end;

var
  wallmissile_id: integer = -1;

//==============================================================================
//
// PX_SpawnWallMissileObject
//
//==============================================================================
function PX_SpawnWallMissileObject(const x, y, z: fixed_t): Pmobj_t;
begin
  if wallmissile_id < 0 then
    wallmissile_id := Info_GetMobjNumForName('MT_MISSILEWALL');

  result := P_SpawnMobj(x, y, z, wallmissile_id);
end;

var
  radixenemymissile_id: integer = -1;

//==============================================================================
//
// RX_SpawnRadixEnemyMissile
//
//==============================================================================
function RX_SpawnRadixEnemyMissile(const x, y, z: fixed_t): Pmobj_t;
begin
  if radixenemymissile_id < 0 then
    radixenemymissile_id := Info_GetMobjNumForName('MT_ENEMYMISSILE');

  result := P_SpawnMobj(x, y, z, radixenemymissile_id);
end;

var
  radixenemyseekermissile_id: integer = -1;

//==============================================================================
//
// RX_SpawnRadixEnemySeekerMissile
//
//==============================================================================
function RX_SpawnRadixEnemySeekerMissile(const x, y, z: fixed_t): Pmobj_t;
begin
  if radixenemyseekermissile_id < 0 then
    radixenemyseekermissile_id := Info_GetMobjNumForName('MT_ENEMYSEEKERMISSILE');

  result := P_SpawnMobj(x, y, z, radixenemyseekermissile_id);
end;

var
  radixbigsmoke_id: integer = -1;

//==============================================================================
//
// RX_SpawnRadixBigSmoke
//
//==============================================================================
function RX_SpawnRadixBigSmoke(const x, y, z: fixed_t): Pmobj_t;
begin
  if radixbigsmoke_id < 0 then
    radixbigsmoke_id := Info_GetMobjNumForName('MT_RADIXBIGSMOKE');

  result := P_SpawnMobj(x, y, z, radixbigsmoke_id);
end;

var
  radixalienblood_id: integer = -1;

//==============================================================================
//
// RX_SpawnAlienBlood
//
//==============================================================================
procedure RX_SpawnAlienBlood(x, y, z: fixed_t);
var
  th: Pmobj_t;
begin
  if radixalienblood_id < 0 then
    radixalienblood_id := Info_GetMobjNumForName('MT_BLOODSPLAT');

  z := z + _SHL(P_Random - P_Random, 10);
  th := P_SpawnMobj(x, y, z, radixalienblood_id);
  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (P_Random and 3);

  if th.tics < 1 then
    th.tics := 1;
end;

end.
