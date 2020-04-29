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
//   Radix Forcefields
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_forcefield;

interface

procedure RX_InitForceFields;

procedure RX_RunForceFields;

implementation

uses
  d_delphi,
  m_fixed,
  m_rnd,
  info_common,
  p_mobj_h,
  p_mobj,
  r_defs,
  r_main,
  radix_grid,
  radix_level,
  radix_logic,
  z_zone;

type
  forcefielditem_t = record
    xpos: fixed_t;
    ypos: fixed_t;
    sector: Psector_t;
    triggersuspended: PByte;
  end;
  Pforcefielditem_t = ^forcefielditem_t;
  forcefielditem_tArray = array[0..$FFF] of forcefielditem_t;
  Pforcefielditem_tArray = ^forcefielditem_tArray;

var
  numforcefielditems: integer;
  forcefield: Pforcefielditem_tArray;

procedure RX_AddForceFieldItem(const xpos, ypos: integer; const trigger: Pradixtrigger_t);
var
  i: integer;
  has_ff: boolean;
  xx, yy: fixed_t;
begin
  has_ff := false;
  for i := 0 to trigger.numactions - 1 do
    if radixactions[trigger.actions[i].actionid].action_type = 12 then // forcefield
    begin
      has_ff := true;
      break;
    end;

  if not has_ff then
    exit;

  xx := xpos * FRACUNIT;
  yy := ypos * FRACUNIT;

  // Check if already positioned
  for i := 0 to numforcefielditems - 1 do
    if (forcefield[i].xpos = xx) and (forcefield[i].xpos = yy) then
      exit;

  if numforcefielditems = 0 then
    forcefield := Z_Malloc(SizeOf(forcefielditem_t), PU_LEVEL, nil)
  else
    forcefield := Z_Realloc(forcefield, (numforcefielditems + 1) * SizeOf(forcefielditem_t), PU_LEVEL, nil);

  forcefield[numforcefielditems].xpos := xx;
  forcefield[numforcefielditems].ypos := yy;
  forcefield[numforcefielditems].sector := R_PointInSubSector(xx, yy).sector;
  forcefield[numforcefielditems].triggersuspended := @trigger.suspended;
  inc(numforcefielditems);
end;

procedure RX_InitForceFields;
var
  i: integer;
  x, y: integer;
  trig_id: integer;
begin
  numforcefielditems := 0;

  x := 0;
  y := 0;
  for i := 0 to RX_RadixGridX * RX_RadixGridY - 1 do
  begin
    trig_id := radixgrid[i];
    if trig_id >= 0 then
      if RX_GridToMap(i, x, y) then
        RX_AddForceFieldItem(x, y, @radixtriggers[trig_id]);
  end;
end;

var
  radixforcefield_id: integer = -1;

const
  FF_DENSITY = 1;  // How many to spawn in a 64x64x64 cube

procedure RX_SpawnForceFields(const idx: integer);
var
  item: Pforcefielditem_t;
  th: Pmobj_t;
  i: integer;
  numff: integer;
  x, y, z: fixed_t;
  zstep: fixed_t;
begin
  item := @forcefield[idx];

  if item.triggersuspended^ <> 0 then
    exit;
    
  zstep := ((RADIXGRIDCELLSIZE * FRACUNIT) div FF_DENSITY);
  numff := (item.sector.ceilingheight - item.sector.floorheight) div zstep;

  z := item.sector.floorheight + zstep div 2;
  for i := 0 to numff - 1 do
    if Sys_Random < 128 then
    begin
      x := item.xpos + Sys_Random * 256 * RADIXGRIDCELLSIZE;
      y := item.ypos - Sys_Random * 256 * RADIXGRIDCELLSIZE;
      th := P_SpawnMobj(x, y, z, radixforcefield_id);
      th.momz := Isign(Sys_Random - 128) * Sys_Random * 1024;
      z := z + zstep;
    end;
end;

procedure RX_RunForceFields;
var
  i: integer;
begin
  if radixforcefield_id < 0 then
    radixforcefield_id := Info_GetMobjNumForName('MT_FORCEFIELD');

  for i := 0 to numforcefielditems - 1 do
    RX_SpawnForceFields(i);
end;

end.
