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
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit p_terrain;

interface

//==============================================================================
//
// P_TerrainTypeForName
//
//==============================================================================
function P_TerrainTypeForName(flatname: string): integer;

var
  allowterrainsplashes: boolean;

const
  FLOOR_SOLID = 0;
  FLOOR_SKY = 1;
  FLOOR_WATER = 2;
  FLOOR_LAVA = 3;
  FLOOR_SLUDGE = 4;
  FLOOR_NUKAGE = 5;
  FLOOR_RADIXLAVA = 6;
  FLOOR_RADIXMUD = 7;
  FLOOR_RADIXWATER = 8;

implementation

uses
  d_delphi;

type
  terraintypedef_t = record
    name: string;
    _type: integer;
  end;

var
  terraintypedefs: array[0..33] of terraintypedef_t = (
    (name: 'F_SKY1'; _type: FLOOR_SKY),
    (name: 'FWATER1'; _type: FLOOR_WATER),
    (name: 'FWATER2'; _type: FLOOR_WATER),
    (name: 'FWATER3'; _type: FLOOR_WATER),
    (name: 'FWATER4'; _type: FLOOR_WATER),
    (name: 'LAVA1'; _type: FLOOR_LAVA),
    (name: 'LAVA2'; _type: FLOOR_LAVA),
    (name: 'LAVA3'; _type: FLOOR_LAVA),
    (name: 'LAVA4'; _type: FLOOR_LAVA),
    (name: 'SLIME01'; _type: FLOOR_SLUDGE),
    (name: 'SLIME02'; _type: FLOOR_SLUDGE),
    (name: 'SLIME03'; _type: FLOOR_SLUDGE),
    (name: 'SLIME04'; _type: FLOOR_SLUDGE),
    (name: 'SLIME05'; _type: FLOOR_SLUDGE),
    (name: 'SLIME06'; _type: FLOOR_SLUDGE),
    (name: 'SLIME07'; _type: FLOOR_SLUDGE),
    (name: 'SLIME08'; _type: FLOOR_SLUDGE),
    (name: 'SLIME09'; _type: FLOOR_SLUDGE),
    (name: 'SLIME10'; _type: FLOOR_SLUDGE),
    (name: 'SLIME11'; _type: FLOOR_SLUDGE),
    (name: 'SLIME12'; _type: FLOOR_SLUDGE),
    (name: 'NUKAGE1'; _type: FLOOR_NUKAGE),
    (name: 'NUKAGE2'; _type: FLOOR_NUKAGE),
    (name: 'NUKAGE3'; _type: FLOOR_NUKAGE),
    // JVAL: 20200501 - Radix terrain types
    (name: 'RDXF0088'; _type: FLOOR_RADIXLAVA),
    (name: 'RDXF0089'; _type: FLOOR_RADIXLAVA),
    (name: 'RDXF0090'; _type: FLOOR_RADIXLAVA),
    (name: 'RDXF0120'; _type: FLOOR_RADIXMUD),
    (name: 'RDXF0121'; _type: FLOOR_RADIXMUD),
    (name: 'RDXF0122'; _type: FLOOR_RADIXMUD),
    (name: 'RDXF0123'; _type: FLOOR_RADIXWATER),
    (name: 'RDXF0124'; _type: FLOOR_RADIXWATER),
    (name: 'RDXF0125'; _type: FLOOR_RADIXWATER),

    (name: 'END'; _type: -1)
  );

//==============================================================================
//
// P_TerrainTypeForName
//
//==============================================================================
function P_TerrainTypeForName(flatname: string): integer;
var
  i: integer;
begin
  i := 0;
  flatname := strupper(flatname);
  while terraintypedefs[i]._type <> -1 do
  begin
    if terraintypedefs[i].name = flatname then
    begin
      result := terraintypedefs[i]._type;
      exit;
    end;
    inc(i);
  end;
  result := 0;
end;

end.
