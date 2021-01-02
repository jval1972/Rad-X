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
//  Gameplay options
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit g_gameplay;

interface

uses
  p_mobj_h;

var
  g_vanillaplayerweapondamage: boolean = false;
  g_vanillalevel1neutroncannon: boolean = false;
  g_vanillalevel1plasmaspreader: boolean = false;
  g_fastweaponrefire: boolean = false;
  g_bigbarrelexplosion: boolean = false;
  g_bigdroneexplosion: boolean = false;

function P_GetThingDamage(const th: Pmobj_t): integer;

implementation

uses
  g_game;

function P_GetThingDamage(const th: Pmobj_t): integer;
begin
  if demoplayback or demorecording then
    result := th.info.damage
  else if g_vanillaplayerweapondamage and (th.info.flags3_ex and MF3_EX_USEALTDAMAGE <> 0) then
    result := th.info.altdamage
  else
    result := th.info.damage
end;

end.
 
