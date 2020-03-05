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
//   Radix trigger grid
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_grid;

interface

uses
  r_defs,
  p_mobj_h,
  radix_level;

var
  radixgrid: radixgrid_t;

//
// JVAL: 20200203 -  Initialize Radix Trigger Grid
//
procedure RX_InitRadixGrid(const x, y: integer; const pgrid: Pradixgrid_t);

function RX_RadixGridX: integer;

function RX_RadixGridY: integer;

function RX_PosInGrid(const mo: Pmobj_t): integer;

implementation

uses
  d_delphi,
  m_fixed,
  i_system;

var
  grid_X_size: integer;
  grid_Y_size: integer;

procedure RX_InitRadixGrid(const x, y: integer; const pgrid: Pradixgrid_t);
var
  sz: integer;
begin
  sz := x * y;
  if sz <> 0 then
    if sz <> RADIXGRIDSIZE then
      I_Error('RX_SetGridSize(): Invalid grid size (%d, %d)', [x, y]);

  grid_X_size := x;
  grid_Y_size := y;

  if pgrid = nil then
    memsetsi(@radixgrid, -1, RADIXGRIDSIZE)
  else
    memcpy(@radixgrid, pgrid, RADIXGRIDSIZE * SizeOf(smallint));
end;

function RX_RadixGridX: integer;
begin
  result := grid_X_size;
end;

function RX_RadixGridY: integer;
begin
  result := grid_Y_size;
end;

function RX_PosInGrid(const mo: Pmobj_t): integer;
var
  sec: Psector_t;
  rx, ry: integer;
begin
  if (grid_X_size = 0) or (grid_Y_size = 0) or (mo = nil) then
  begin
    result := -1;
    exit;
  end;

  sec := Psubsector_t(mo.subsector).sector;

  // JVAL: 20200305 - Works only when ::radixmapXmult & ::radixmapYmult are -1 or 1
  rx := (sec.radixmapXmult * (mo.x div FRACUNIT) - sec.radixmapXadd) div 64;
  ry := (sec.radixmapYmult * (mo.y div FRACUNIT) - sec.radixmapYadd) div 64;

  result := ry * grid_X_size + rx;
end;

end.
