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

procedure RX_RunActions;

implementation

uses
  radix_actions;

procedure RX_RunAction(const action: Pradixaction_t);
begin
  case action.action_type of
     0: ATR_ScrollingWall(@action.params);
     1: ATR_MovingSurface(@action.params);
     2: ATR_SwitchWallBitmap(@action.params);
     3: ATR_SwitchSecBitmap(@action.params);
     4: ATR_ToggleWallBitmap(@action.params);
     5: ATR_ToggleSecBitmap(@action.params);
     6: ATR_CircleBitmap(@action.params);
     7: ATR_LightFlicker(@action.params);
     8: ATR_LightsOff(@action.params);
     9: ATR_LightsOn(@action.params);
    10: ATR_LightOscilate(@action.params);
    11: ATR_PlaneTeleport(@action.params);
    12: ATR_PlaneTranspo(@action.params);
    13: ATR_NewMovingSurface(@action.params);
    14: ATR_PlaySound(@action.params);
    15: ATR_RandLightsFlicker(@action.params);
    16: ATR_EndOfLevel(@action.params);
    17: ATR_SpriteTriggerActivate(@action.params);
    18: ATR_SectorBasedGravity(@action.params);
    19: ATR_DeactivateTrigger(@action.params);
    20: ATR_ActivateTrigger(@action.params);
    21: ATR_CompleteMissileWall(@action.params);
    22: ATR_ScannerJam(@action.params);
    23: ATR_PrintMessage(@action.params);
    24: ATR_FloorMissileWall(@action.params);
    25: ATR_CeilingMissileWall(@action.params);
    26: ATR_BigSpriteTrig(@action.params);
    27: ATR_MassiveExplosion(@action.params);
    28: ATR_WallDeadCheck(@action.params);
    29: ATR_SecondaryObjective(@action.params);
    30: ATR_SeekCompleteMissileWall(@action.params);
    31: ATR_LightMovement(@action.params);
    32: ATR_MultLightOscilate(@action.params);
    33: ATR_MultRandLightsFlicker(@action.params);
    34: ATR_SkillRatio(@action.params);
    35: ATR_HurtPlayerExplosion(@action.params);
    36: ATR_SwitchShadeType(@action.params);
    37: ATR_SixLightMovement(@action.params);
    38: ATR_SurfacePowerUp(@action.params);
    39: ATR_SecretSprite(@action.params);
    40: ATR_BossEyeHandler(@action.params);
    41: ATR_VertExplosion(@action.params);
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

