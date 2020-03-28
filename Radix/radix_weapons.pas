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
//   Radix weapon codepointers
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_weapons;

interface

uses
  d_player,
  p_pspr_h;

procedure A_FireRadixPlasma(player: Pplayer_t; psp: Ppspdef_t);

implementation

uses
  d_items,
  info_h,
  info_common,
  m_rnd,
  p_pspr,
  p_mobj;

//
// A_FireRadixPlasma
//
var
  radixplasma_id: integer = -1;

procedure A_FireRadixPlasma(player: Pplayer_t; psp: Ppspdef_t);
begin
//  player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] :=
//    player.ammo[Ord(weaponinfo[Ord(player.readyweapon)].ammo)] - 1;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  if radixplasma_id < 0 then
    radixplasma_id := Info_GetMobjNumForName('MT_RADIXPLASMA');

  P_SpawnPlayerMissile(player.mo, radixplasma_id);
end;

end.
