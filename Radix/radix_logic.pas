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

unit radix_logic;

interface

uses
  d_delphi;

procedure ATR_ScrollingWall(const params: PSmallIntArray);

procedure ATR_MovingSurface(const params: PSmallIntArray);

procedure ATR_SwitchWallBitmap(const params: PSmallIntArray);

procedure ATR_SwitchSecBitmap(const params: PSmallIntArray);

procedure ATR_ToggleWallBitmap(const params: PSmallIntArray);

procedure ATR_ToggleSecBitmap(const params: PSmallIntArray);

procedure ATR_CircleBitmap(const params: PSmallIntArray);

procedure ATR_LightFlicker(const params: PSmallIntArray);

procedure ATR_LightsOff(const params: PSmallIntArray);

procedure ATR_LightsOn(const params: PSmallIntArray);

procedure ATR_LightOscilate(const params: PSmallIntArray);

procedure ATR_PlaneTeleport(const params: PSmallIntArray);

procedure ATR_PlaneTranspo(const params: PSmallIntArray);

procedure ATR_NewMovingSurface(const params: PSmallIntArray);

procedure ATR_PlaySound(const params: PSmallIntArray);

procedure ATR_RandLightsFlicker(const params: PSmallIntArray);

procedure ATR_EndOfLevel(const params: PSmallIntArray);

procedure ATR_SpriteTriggerActivate(const params: PSmallIntArray);

procedure ATR_SectorBasedGravity(const params: PSmallIntArray);

procedure ATR_DeactivateTrigger(const params: PSmallIntArray);

procedure ATR_ActivateTrigger(const params: PSmallIntArray);

procedure ATR_CompleteMissileWall(const params: PSmallIntArray);

procedure ATR_ScannerJam(const params: PSmallIntArray);

procedure ATR_PrintMessage(const params: PSmallIntArray);

procedure ATR_FloorMissileWall(const params: PSmallIntArray);

procedure ATR_CeilingMissileWall(const params: PSmallIntArray);

procedure ATR_BigSpriteTrig(const params: PSmallIntArray);

procedure ATR_MassiveExplosion(const params: PSmallIntArray);

procedure ATR_WallDeadCheck(const params: PSmallIntArray);

procedure ATR_SecondaryObjective(const params: PSmallIntArray);

procedure ATR_SeekCompleteMissileWall(const params: PSmallIntArray);

procedure ATR_LightMovement(const params: PSmallIntArray);

procedure ATR_MultLightOscilate(const params: PSmallIntArray);

procedure ATR_MultLightEffects(const params: PSmallIntArray);

procedure ATR_SkillRation(const params: PSmallIntArray);

procedure ATR_HurtPlayerExplosion(const params: PSmallIntArray);

procedure ATR_SwitchLightLevel(const params: PSmallIntArray);

procedure ATR_SixLightMovement(const params: PSmallIntArray);

procedure ATR_SurfacePowerUp(const params: PSmallIntArray);

procedure ATR_SecretSprite(const params: PSmallIntArray);

procedure ATR_BossEyeHandler(const params: PSmallIntArray);

procedure ATR_VertExplosion(const params: PSmallIntArray);

implementation

procedure ATR_ScrollingWall(const params: PSmallIntArray);
var
  wall_number, direction, speed: integer;
begin
end;

procedure ATR_MovingSurface(const params: PSmallIntArray);
var
  surface, max_height, min_height, max_delay, speed, surface_type, direction, stop_position: integer;
begin
end;

procedure ATR_SwitchWallBitmap(const params: PSmallIntArray);
var
  element_number, switch_bitmap, do_floor: integer;
begin
end;

procedure ATR_SwitchSecBitmap(const params: PSmallIntArray);
var
  element_number, switch_bitmap, do_floor: integer;
begin
end;

procedure ATR_ToggleWallBitmap(const params: PSmallIntArray);
var
  element_number, switch_bitmap, do_floor: integer;
begin
end;

procedure ATR_ToggleSecBitmap(const params: PSmallIntArray);
var
  element_number, switch_bitmap, do_floor: integer;
begin
end;

procedure ATR_CircleBitmap(const params: PSmallIntArray);
var
  max_delay, bitmap_1, bitmap_2, bitmap_3: integer;
begin
end;

procedure ATR_LightFlicker(const params: PSmallIntArray);
var
  off_delay, on_delay, off_light_level, on_light_level, sector: integer;
begin
end;

procedure ATR_LightsOff(const params: PSmallIntArray);
var
  off_light_level, sector: integer;
begin
end;

procedure ATR_LightsOn(const params: PSmallIntArray);
var
  on_light_level, sector: integer;
begin
end;

procedure ATR_LightOscilate(const params: PSmallIntArray);
var
  max_light, min_light, direction, speed, sector: integer;
begin
end;

procedure ATR_PlaneTeleport(const params: PSmallIntArray);
var
  new_angle, new_x, new_y, change_height, new_height, change_speed, new_speed, new_height_angle, delay: integer;
begin
end;

procedure ATR_PlaneTranspo(const params: PSmallIntArray);
var
  target_x, target_y, target_height, approx_start_x, approx_start_y, approx_start_height, tick_count, line_angle: integer;
begin
end;

procedure ATR_NewMovingSurface(const params: PSmallIntArray);
var
  surface, max_height, min_height, max_delay, speed, surface_type, direction, stop_position, approx_x, approx_y, start_sound, stop_sound, activate_trig, trigger_number: integer;
begin
end;

procedure ATR_PlaySound(const params: PSmallIntArray);
var
  sound_number, repeating, x_pos, y_pos: integer;
begin
end;

procedure ATR_RandLightsFlicker(const params: PSmallIntArray);
var
  off_min_delay, off_max_delay, on_min_delay, on_max_delay, off_light_level, on_light_level, sector: integer;
begin
end;

procedure ATR_EndOfLevel(const params: PSmallIntArray);
var
  return_value: integer;
begin
end;

procedure ATR_SpriteTriggerActivate(const params: PSmallIntArray);
var
  trigger, sprite_1, sprite_2, sprite_3, sprite_4, sprite_5: integer;
begin
end;

procedure ATR_SectorBasedGravity(const params: PSmallIntArray);
var
  direction, strength, sector_id, approx_x, approx_y: integer;
begin
end;

procedure ATR_DeactivateTrigger(const params: PSmallIntArray);
var
  trigger: integer;
begin
end;

procedure ATR_ActivateTrigger(const params: PSmallIntArray);
var
  trigger: integer;
begin
end;

procedure ATR_CompleteMissileWall(const params: PSmallIntArray);
var
  wall_number: integer;
begin
end;

procedure ATR_ScannerJam(const params: PSmallIntArray);
var
  on_off: integer;
begin
end;

procedure ATR_PrintMessage(const params: PSmallIntArray);
var
  message_id: integer;
begin
end;

procedure ATR_FloorMissileWall(const params: PSmallIntArray);
var
  wall_number: integer;
begin
end;

procedure ATR_CeilingMissileWall(const params: PSmallIntArray);
var
  wall_number: integer;
begin
end;

procedure ATR_BigSpriteTrig(const params: PSmallIntArray);
var
  trigger: integer;
  the_sprites: array[1..20] of integer;
begin
end;

procedure ATR_MassiveExplosion(const params: PSmallIntArray);
var
  number_of_explosions, x_coord, y_coord, height, delta_x, delta_y, delay_length, radious_one_third, number_of_bitmaps_per: integer;
begin
end;

procedure ATR_WallDeadCheck(const params: PSmallIntArray);
var
  trigger, wall_1, wall_2, wall_3, wall_4, wall_5: integer;
begin
end;

procedure ATR_SecondaryObjective(const params: PSmallIntArray);
var
  return_value: integer;
begin
end;

procedure ATR_SeekCompleteMissileWall(const params: PSmallIntArray);
var
  wall_number: integer;
begin
end;

procedure ATR_LightMovement(const params: PSmallIntArray);
var
  on_level, off_level, delay, sector_1, sector_2, sector_3, sector_4: integer;
begin
end;

procedure ATR_MultLightOscilate(const params: PSmallIntArray);
var
  max_light, min_light, direction, speed: integer;
  the_sectors: array[1..30] of integer;
begin
end;

procedure ATR_MultLightEffects(const params: PSmallIntArray);
var
  off_min_delay, off_max_delay, on_min_delay, on_max_delay: integer;
  off_light_level_1, on_light_level_1, sector_1: integer;
  off_light_level_2, on_light_level_2, sector_2: integer;
  off_light_level_3, on_light_level_3, sector_3: integer;
  off_light_level_4, on_light_level_4, sector_4: integer;
  off_light_level_5, on_light_level_5, sector_5: integer;
begin
end;

procedure ATR_SkillRation(const params: PSmallIntArray);
var
  trigger, percentage: integer;
begin
end;

procedure ATR_HurtPlayerExplosion(const params: PSmallIntArray);
var
  hit_points_at_center, number_of_explosions, x_coord, y_coord, height, delta_x, delta_y, delay_length, radious_one_third: integer;
begin
end;

procedure ATR_SwitchLightLevel(const params: PSmallIntArray);
var
  sector_id, new_light_level: integer;
begin
end;

procedure ATR_SixLightMovement(const params: PSmallIntArray);
var
  on_level, off_level, delay: integer;
  the_sectors: array[1..12] of integer;
begin
end;

procedure ATR_SurfacePowerUp(const params: PSmallIntArray);
var
  sector_id, armour_inc, shield_inc, energy_inc: integer;
begin
end;

procedure ATR_SecretSprite(const params: PSmallIntArray);
var
  the_sectors: array[1..15] of integer;
begin
end;

procedure ATR_BossEyeHandler(const params: PSmallIntArray);
var
  wall_number: integer;
begin
end;

procedure ATR_VertExplosion(const params: PSmallIntArray);
var
  number_of_explosions, x_coord, y_coord, height, delta_x, delta_y, delta_height, delay_length, radious_one_third, number_of_bitmaps_per: integer;
begin
end;

end.

