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
//   Radix A.I.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_logic;

interface

uses
  radix_level;

var
  radixactions: Pradixaction_tArray;
  numradixactions: integer;
  radixtriggers: Pradixtrigger_tArray;
  numradixtriggers: integer;

procedure RX_RunTriggers;

procedure RX_RunTrigger(const trig_id: integer);

procedure RX_RunActions;

var
  radixplayer: integer; // The player that activates a radix trigger

implementation

uses
  doomdef,
  d_player,
  g_game,
  radix_actions,
  radix_grid;

procedure RX_RunTriggerAction(const ra: Pradixtriggeraction_t);
begin
  case ra.activationflags of
    SPR_FLG_ACTIVATE:
      radixactions[ra.actionid].suspend := 0;
    SPR_FLG_DEACTIVATE:
      radixactions[ra.actionid].suspend := 1; // Distinguist from $FFFF in radix.dat
    SPR_FLG_ACTIVATEONSPACE: ; // ?
    SPR_FLG_TONGLE:
      if radixactions[ra.actionid].suspend = 0 then
        radixactions[ra.actionid].suspend := 1
      else
        radixactions[ra.actionid].suspend := 0
  end;
end;

procedure RX_RunTrigger(const trig_id: integer);
var
  trig: Pradixtrigger_t;
  i: integer;
begin
  trig := @radixtriggers[trig_id];
  if trig.suspended = 0 then
    for i := 0 to trig.numactions - 1 do
      RX_RunTriggerAction(@trig.actions[i]);
end;

//
// JVAL: Handle radix triggers
// Note: No voodoo dolls
//
procedure RX_RunTriggers;
var
  i: integer;
  grid_id: integer;
  trig_id: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
    begin
      radixplayer := i;
      grid_id := RX_PosInGrid(players[i].mo);
      if (grid_id >= 0) and (grid_id < RADIXGRIDSIZE) then
      begin
        trig_id := radixgrid[grid_id];
        if trig_id >= 0 then
        begin
          RX_RunTrigger(trig_id);
          radixgrid[grid_id] := -1; // Clear trigger from grid
        end;
      end;
    end;
end;

procedure RX_RunAction(const action: Pradixaction_t);
begin
  case action.action_type of
     0: RA_ScrollingWall(action);
     1: RA_MovingSurface(action);
     2: RA_SwitchWallBitmap(action);
     3: RA_SwitchSecBitmap(action);
     4: RA_ToggleWallBitmap(action);
     5: RA_ToggleSecBitmap(action);
     6: RA_CircleBitmap(action);
     7: RA_LightFlicker(action);
     8: RA_LightsOff(action);
     9: RA_LightsOn(action);
    10: RA_LightOscilate(action);
    11: RA_PlaneTeleport(action);
    12: RA_PlaneTranspo(action);
    13: RA_NewMovingSurface(action);
    14: RA_PlaySound(action);
    15: RA_RandLightsFlicker(action);
    16: RA_EndOfLevel(action);
    17: RA_SpriteTriggerActivate(action);
    18: RA_SectorBasedGravity(action);
    19: RA_DeactivateTrigger(action);
    20: RA_ActivateTrigger(action);
    21: RA_CompleteMissileWall(action);
    22: RA_ScannerJam(action);
    23: RA_PrintMessage(action);
    24: RA_FloorMissileWall(action);
    25: RA_CeilingMissileWall(action);
    26: RA_BigSpriteTrig(action);
    27: RA_MassiveExplosion(action);
    28: RA_WallDeadCheck(action);
    29: RA_SecondaryObjective(action);
    30: RA_SeekCompleteMissileWall(action);
    31: RA_LightMovement(action);
    32: RA_MultLightOscilate(action);
    33: RA_MultRandLightsFlicker(action);
    34: RA_SkillRatio(action);
    35: RA_HurtPlayerExplosion(action);
    36: RA_SwitchShadeType(action);
    37: RA_SixLightMovement(action);
    38: RA_SurfacePowerUp(action);
    39: RA_SecretSprite(action);
    40: RA_BossEyeHandler(action);
    41: RA_VertExplosion(action);
  end;
end;

procedure RX_RunActions;
var
  i: integer;
  action: Pradixaction_t;
begin
  action := @radixactions[0];
  for i := 0 to numradixactions - 1 do
  begin
    if action.enabled = 1 then
      if action.suspend = 0 then
        RX_RunAction(action);
    inc(action);
  end;
end;

end.

