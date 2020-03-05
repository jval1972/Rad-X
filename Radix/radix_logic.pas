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
     0: ATR_ScrollingWall(@action);
     1: ATR_MovingSurface(@action);
     2: ATR_SwitchWallBitmap(@action);
     3: ATR_SwitchSecBitmap(@action);
     4: ATR_ToggleWallBitmap(@action);
     5: ATR_ToggleSecBitmap(@action);
     6: ATR_CircleBitmap(@action);
     7: ATR_LightFlicker(@action);
     8: ATR_LightsOff(@action);
     9: ATR_LightsOn(@action);
    10: ATR_LightOscilate(@action);
    11: ATR_PlaneTeleport(@action);
    12: ATR_PlaneTranspo(@action);
    13: ATR_NewMovingSurface(@action);
    14: ATR_PlaySound(@action);
    15: ATR_RandLightsFlicker(@action);
    16: ATR_EndOfLevel(@action);
    17: ATR_SpriteTriggerActivate(@action);
    18: ATR_SectorBasedGravity(@action);
    19: ATR_DeactivateTrigger(@action);
    20: ATR_ActivateTrigger(@action);
    21: ATR_CompleteMissileWall(@action);
    22: ATR_ScannerJam(@action);
    23: ATR_PrintMessage(@action);
    24: ATR_FloorMissileWall(@action);
    25: ATR_CeilingMissileWall(@action);
    26: ATR_BigSpriteTrig(@action);
    27: ATR_MassiveExplosion(@action);
    28: ATR_WallDeadCheck(@action);
    29: ATR_SecondaryObjective(@action);
    30: ATR_SeekCompleteMissileWall(@action);
    31: ATR_LightMovement(@action);
    32: ATR_MultLightOscilate(@action);
    33: ATR_MultRandLightsFlicker(@action);
    34: ATR_SkillRatio(@action);
    35: ATR_HurtPlayerExplosion(@action);
    36: ATR_SwitchShadeType(@action);
    37: ATR_SixLightMovement(@action);
    38: ATR_SurfacePowerUp(@action);
    39: ATR_SecretSprite(@action);
    40: ATR_BossEyeHandler(@action);
    41: ATR_VertExplosion(@action);
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

