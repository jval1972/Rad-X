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
//  Radix specific script
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit psi_radix;

interface

procedure PS_SetHasSecondaryObjective(const value: boolean);
function PS_GetHasSecondaryObjective: boolean;

procedure PS_SetSecondaryObjective(const value: boolean);
function PS_GetSecondaryObjective: boolean;

implementation

uses
  doomdef,
  d_player,
  g_game;

procedure PS_SetHasSecondaryObjective(const value: boolean);
begin
  levelhassecondaryobjective := value;
end;

function PS_GetHasSecondaryObjective: boolean;
begin
  result := levelhassecondaryobjective;
end;

procedure PS_SetSecondaryObjective(const value: boolean);
var
  i: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      players[i].secondaryobjective := value;
end;

function PS_GetSecondaryObjective: boolean;
var
  i: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
    begin
      result := players[i].secondaryobjective;
      if result then
        exit;
    end;
  result := false;
end;

end.
 
