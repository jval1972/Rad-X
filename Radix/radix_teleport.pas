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
//   Radix teleport
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_teleport;

interface

uses
  p_mobj_h;

procedure RX_SpawnTeleportForceField(const mo: Pmobj_t);

implementation

uses
  d_delphi,
  m_fixed,
  m_rnd,
  tables,
  info_common,
  p_mobj,
  radix_sounds;

const
  TELEPORTDENSITY = 1000;

var
  radixteleportforcefield_id: integer = -1;

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

end.
