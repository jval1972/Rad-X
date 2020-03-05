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
//   Radix Actions
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_actions;

interface

uses
  d_delphi;

procedure ATR_ScrollingWall(const params: pointer);

procedure ATR_MovingSurface(const params: pointer);

procedure ATR_SwitchWallBitmap(const params: pointer);

procedure ATR_SwitchSecBitmap(const params: pointer);

procedure ATR_ToggleWallBitmap(const params: pointer);

procedure ATR_ToggleSecBitmap(const params: pointer);

procedure ATR_CircleBitmap(const params: pointer);

procedure ATR_LightFlicker(const params: pointer);

procedure ATR_LightsOff(const params: pointer);

procedure ATR_LightsOn(const params: pointer);

procedure ATR_LightOscilate(const params: pointer);

procedure ATR_PlaneTeleport(const params: pointer);

procedure ATR_PlaneTranspo(const params: pointer);

procedure ATR_NewMovingSurface(const params: pointer);

procedure ATR_PlaySound(const params: pointer);

procedure ATR_RandLightsFlicker(const params: pointer);

procedure ATR_EndOfLevel(const params: pointer);

procedure ATR_SpriteTriggerActivate(const params: pointer);

procedure ATR_SectorBasedGravity(const params: pointer);

procedure ATR_DeactivateTrigger(const params: pointer);

procedure ATR_ActivateTrigger(const params: pointer);

procedure ATR_CompleteMissileWall(const params: pointer);

procedure ATR_ScannerJam(const params: pointer);

procedure ATR_PrintMessage(const params: pointer);

procedure ATR_FloorMissileWall(const params: pointer);

procedure ATR_CeilingMissileWall(const params: pointer);

procedure ATR_BigSpriteTrig(const params: pointer);

procedure ATR_MassiveExplosion(const params: pointer);

procedure ATR_WallDeadCheck(const params: pointer);

procedure ATR_SecondaryObjective(const params: pointer);

procedure ATR_SeekCompleteMissileWall(const params: pointer);

procedure ATR_LightMovement(const params: pointer);

procedure ATR_MultLightOscilate(const params: pointer);

procedure ATR_MultRandLightsFlicker(const params: pointer);

procedure ATR_SkillRatio(const params: pointer);

procedure ATR_HurtPlayerExplosion(const params: pointer);

procedure ATR_SwitchShadeType(const params: pointer);

procedure ATR_SixLightMovement(const params: pointer);

procedure ATR_SurfacePowerUp(const params: pointer);

procedure ATR_SecretSprite(const params: pointer);

procedure ATR_BossEyeHandler(const params: pointer);

procedure ATR_VertExplosion(const params: pointer);

implementation

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 0
type
  radixscrollingwall_t = packed record
    wall_number: smallint;
    direction: byte; // left/right/top/bottom ?
    speed: byte;
  end;
  radixscrollingwall_p = ^radixscrollingwall_t;

procedure ATR_ScrollingWall(const params: pointer);
var
  parms: radixscrollingwall_t;
begin
  parms := radixscrollingwall_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 1
type
  radixmovingsurface_t = packed record
    surface: smallint;
    max_height: smallint;
    min_height: smallint;
    max_delay: smallint;
    speed: byte;
    surface_type: byte;
    direction: byte;
    stop_position: byte;
  end;
  radixmovingsurface_p = ^radixmovingsurface_t;

procedure ATR_MovingSurface(const params: pointer);
var
  parms: radixmovingsurface_t;
begin
  parms := radixmovingsurface_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 2
type
  radixswitchwallbitmap_t = packed record
    element_number: smallint;
    switch_bitmap: smallint;
    do_floor: byte;
  end;
  radixswitchwallbitmap_p = ^radixswitchwallbitmap_t;

procedure ATR_SwitchWallBitmap(const params: pointer);
var
  parms: radixswitchwallbitmap_t;
begin
  parms := radixswitchwallbitmap_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 3
type
  radixswitchsecbitmap_t = packed record
    element_number: smallint; // sector id
    switch_bitmap: smallint;
    do_floor: byte;
  end;
  radixswitchsecbitmap_p = ^radixswitchsecbitmap_t;

procedure ATR_SwitchSecBitmap(const params: pointer);
var
  parms: radixswitchsecbitmap_t;
begin
  parms := radixswitchsecbitmap_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 4 - Not presend in radix.dat
procedure ATR_ToggleWallBitmap(const params: pointer);
var
  element_number, switch_bitmap, do_floor: integer;
begin
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 5 - Not presend in radix.dat
procedure ATR_ToggleSecBitmap(const params: pointer);
var
  element_number, switch_bitmap, do_floor: integer;
begin
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 6
type
  radixcirclebitmap_t = packed record
    max_delay: integer;
    bitmap_1: smallint;
    bitmap_2: smallint;
    bitmap_3: smallint;
  end;
  radixcirclebitmap_p = ^radixcirclebitmap_t;

procedure ATR_CircleBitmap(const params: pointer);
var
  parms: radixcirclebitmap_t;
begin
  parms := radixcirclebitmap_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 7
type
  radixlightflicker_t = packed record
    off_delay: smallint;
    on_delay: integer;
    off_light_level: smallint;  // 0-63
    on_light_level: smallint; // 0-63
    sector: smallint;
  end;
  radixlightflicker_p = ^radixlightflicker_t;

procedure ATR_LightFlicker(const params: pointer);
var
  parms: radixlightflicker_t;
begin
  parms := radixlightflicker_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 8
type
  radixlightsoff_t = packed record
    foo1, foo2, foo3: smallint;
    off_light_level: integer; // 0-63
    sector: smallint;
  end;
  radixlightsoff_p = ^radixlightsoff_t;

procedure ATR_LightsOff(const params: pointer);
var
  parms: radixlightsoff_t;
begin
  parms := radixlightsoff_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 9
type
  radixlightson_t = packed record
    foo1, foo2, foo3, foo4: smallint; // Always 0 inside radix.dat
    on_light_level: smallint; // 0-63
    sector: smallint;
  end;
  radixlightson_p = ^radixlightson_t;

procedure ATR_LightsOn(const params: pointer);
var
  parms: radixlightson_t;
begin
  parms := radixlightson_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 10
type
  radixlightoscilate_t = packed record
    max_light: smallint;
    min_light: smallint;
    direction: smallint;
    speed: smallint;
    sector: smallint;
  end;
  radixlightoscilate_p = ^radixlightoscilate_t;

procedure ATR_LightOscilate(const params: pointer);
var
  parms: radixlightoscilate_t;
begin
  parms := radixlightoscilate_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 11
type
  radixplaneteleport_t = packed record
    new_angle: smallint; // 0-256
    new_x: LongWord;
    new_y: LongWord;
    change_height: byte;
    new_height: smallint;
    change_speed: byte;
    new_speed:  smallint;
    new_height_angle: smallint; // 0-256
    delay: smallint;
  end;
  radixplaneteleport_p = ^radixplaneteleport_t;

procedure ATR_PlaneTeleport(const params: pointer);
var
  parms: radixplaneteleport_t;
begin
  parms := radixplaneteleport_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 12 (forcefield)
type
  radixplanetranspo_t = packed record
    target_x: LongWord;
    target_y: LongWord;
    target_height: smallint; // can be negative ?
    approx_start_x: LongWord;
    approx_start_y: LongWord;
    approx_start_height: integer; // can be negative ?
    tick_count: smallint;
    line_angle: smallint;
  end;
  radixplanetranspo_p = ^radixplanetranspo_t;

procedure ATR_PlaneTranspo(const params: pointer);
var
  parms: radixplanetranspo_t;
begin
  parms := radixplanetranspo_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 13
type
  radixnewmovingsurface_t = packed record
    surface: smallint;
    max_height: smallint;
    min_height: smallint;
    max_delay: integer;
    speed: byte;
    surface_type: byte;
    direction: byte;
    stop_position: byte;
    approx_x: LongWord;
    approx_y: LongWord;
    start_sound: smallint;
    stop_sound: smallint;
    activate_trig: smallint;
    trigger_number: smallint;
  end;
  radixnewmovingsurface_p = ^radixnewmovingsurface_t;

procedure ATR_NewMovingSurface(const params: pointer);
var
  parms: radixnewmovingsurface_t;
begin
  parms := radixnewmovingsurface_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 14
type
  radixplaysound_t = packed record
    sound_number: smallint; // Values 17 - 31
    repeating: smallint;
    x_pos: LongWord;
    y_pos: LongWord;
  end;
  radixplaysound_p = ^radixplaysound_t;

procedure ATR_PlaySound(const params: pointer);
var
  parms: radixplaysound_t;
begin
  parms := radixplaysound_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 15
type
  radixrandlightsflicker_t = packed record
    foo: LongWord;
    off_min_delay: smallint;
    off_max_delay: smallint;
    on_min_delay: smallint;
    on_max_delay: integer;
    off_light_level: smallint;
    on_light_level: smallint;
    sector: smallint;
  end;
  radixrandlightsflicker_p = ^radixrandlightsflicker_t;

procedure ATR_RandLightsFlicker(const params: pointer);
var
  parms: radixrandlightsflicker_t;
begin
  parms := radixrandlightsflicker_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 16
type
  radixendoflevel_t = packed record
    // return_value = -1 -> End of episode
    // return_value = 9 -> End level, go to secret level (E?M9)
    // return_value = 0 -> End level, go to next level
    // return_value <> 0 -> End secret level, go to next level normal (non secret) level
    return_value: smallint;
  end;
  radixendoflevel_p = ^radixendoflevel_t;

procedure ATR_EndOfLevel(const params: pointer);
var
  parms: radixendoflevel_t;
begin
  parms := radixendoflevel_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 17
type
  radixspritetriggeractivate_t = packed record
    trigger: integer;
    sprites: packed array[0..4] of integer;
  end;
  radixspritetriggeractivate_p = ^radixspritetriggeractivate_t;

procedure ATR_SpriteTriggerActivate(const params: pointer);
var
  parms: radixspritetriggeractivate_t;
begin
  parms := radixspritetriggeractivate_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 18
type
  radixsectorbasedgravity_t = packed record
    direction: smallint; // 1/-1 inside radix.dat
    strength: smallint; // from 0 to 3 inside radix.dat
    sector_id: smallint;
    approx_x: LongWord;
    approx_y: LongWord;
  end;
  radixsectorbasedgravity_p = ^radixsectorbasedgravity_t;

procedure ATR_SectorBasedGravity(const params: pointer);
var
  parms: radixsectorbasedgravity_t;
begin
  parms := radixsectorbasedgravity_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 19
type
  radixdeactivatetrigger_t = packed record
    trigger: byte;
  end;
  radixdeactivatetrigger_p = ^radixdeactivatetrigger_t;

procedure ATR_DeactivateTrigger(const params: pointer);
var
  parms: radixdeactivatetrigger_t;
begin
  parms := radixdeactivatetrigger_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 20
type
  radixactivatetrigger_t = packed record
    trigger: byte;
  end;
  radixactivatetrigger_p = ^radixactivatetrigger_t;

procedure ATR_ActivateTrigger(const params: pointer);
var
  parms: radixactivatetrigger_t;
begin
  parms := radixactivatetrigger_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 21
type
  radixcompletemissilewall_t = packed record
    wall_number: smallint;
  end;
  radixcompletemissilewall_p = ^radixcompletemissilewall_t;

procedure ATR_CompleteMissileWall(const params: pointer);
var
  parms: radixcompletemissilewall_t;
begin
  parms := radixcompletemissilewall_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 22
type
  radixscannerjam_t = packed record
    on_off: smallint; // 1-> jam radar, 0-> enable radar
  end;
  radixscannerjam_p = ^radixscannerjam_t;

procedure ATR_ScannerJam(const params: pointer);
var
  parms: radixscannerjam_t;
begin
  parms := radixscannerjam_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 23
type
  radixprintmessage_t = packed record
    message_id: byte; // id's 0-11
  end;
  radixprintmessage_p = ^radixprintmessage_t;

procedure ATR_PrintMessage(const params: pointer);
var
  parms: radixprintmessage_t;
begin
  parms := radixprintmessage_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 24
type
  radixfloormissilewall_t = packed record
    wall_number: smallint;
  end;
  radixfloormissilewall_p = ^radixfloormissilewall_t;

procedure ATR_FloorMissileWall(const params: pointer);
var
  parms: radixfloormissilewall_t;
begin
  parms := radixfloormissilewall_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 25
type
  radixceilingmissilewall_t = packed record
    wall_number: smallint;
  end;
  radixceilingmissilewall_p = ^radixceilingmissilewall_t;

procedure ATR_CeilingMissileWall(const params: pointer);
var
  parms: radixceilingmissilewall_t;
begin
  parms := radixceilingmissilewall_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 26
type
  radixbigspritetrig_t = packed record
    trigger: integer;
    the_sprites: packed array[0..19] of integer; // Zero and negative do not count
  end;
  radixbigspritetrig_p = ^radixbigspritetrig_t;

procedure ATR_BigSpriteTrig(const params: pointer);
var
  parms: radixbigspritetrig_t;
begin
  parms := radixbigspritetrig_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 27
type
  radixmassiveexplosion_t = packed record
    number_of_explosions: integer;
    x_coord: integer;
    y_coord: integer;
    height: integer;
    delta_x: integer;
    delta_y: integer;
    delay_length: integer;
    radious_one_third: integer;
    number_of_bitmaps_per: smallint;
  end;
  radixmassiveexplosion_p = ^radixmassiveexplosion_t;

procedure ATR_MassiveExplosion(const params: pointer);
var
  parms: radixmassiveexplosion_t;
begin
  parms := radixmassiveexplosion_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 28
type
  radixwalldeadcheck_t = packed record
    trigger: integer;
    the_walls: packed array[0..4] of integer; // Wall values can be negative
  end;
  radixwalldeadcheck_p = ^radixwalldeadcheck_t;

procedure ATR_WallDeadCheck(const params: pointer);
var
  parms: radixwalldeadcheck_t;
begin
  parms := radixwalldeadcheck_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 29
type
  radixsecondaryobjective_t = packed record
    return_value: byte;
  end;
  radixsecondaryobjective_p = ^radixsecondaryobjective_t;

procedure ATR_SecondaryObjective(const params: pointer);
var
  parms: radixsecondaryobjective_t;
begin
  parms := radixsecondaryobjective_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 30
type
  radixseekcompletemissilewall_t = packed record
    wall_number: smallint;
  end;
  radixseekcompletemissilewall_p = ^radixseekcompletemissilewall_t;

procedure ATR_SeekCompleteMissileWall(const params: pointer);
var
  parms: radixseekcompletemissilewall_t;
begin
  parms := radixseekcompletemissilewall_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 31
type
  radixspritelightmovement_t = packed record
    on_level: smallint;   // light level from 0 to 63
    off_level: smallint;  // light level from 0 to 63
    delay: smallint;
    the_sectors: packed array[0..3] of smallint;  // Sector can be -1
  end;
  radixspritelightmovement_p = ^radixspritelightmovement_t;

procedure ATR_LightMovement(const params: pointer);
var
  parms: radixspritelightmovement_t;
begin
  parms := radixspritelightmovement_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 32
type
  radixmultlightoscilate_t = packed record
    max_light: smallint; // light level from 0 to 63, grater values mask to sector color ?
    min_light: smallint; // light level from 0 to 63
    direction: smallint;
    speed: smallint;
    the_sectors: packed array[0..29] of smallint; // Negative values (-1) means no sector
  end;
  radixmultlightoscilate_p = ^radixmultlightoscilate_t;

procedure ATR_MultLightOscilate(const params: pointer);
var
  parms: radixmultlightoscilate_t;
begin
  parms := radixmultlightoscilate_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 33
type
  radixmultrandlightsinfo_t = packed record
    off_light_level: smallint; // Range is 0-63
    on_light_level: smallint; // Range is 0-63
    sector: smallint; // Sector value can be negative (-1)
  end;

  radixmultrandlightsflicker_t = packed record
    foo: LongWord;
    off_min_delay: smallint;
    off_max_delay: smallint;
    on_min_delay: smallint;
    on_max_delay: integer;
    info: packed array[0..4] of radixmultrandlightsinfo_t;
  end;
  radixmultrandlightsflicker_p = ^radixmultrandlightsflicker_t;

procedure ATR_MultRandLightsFlicker(const params: pointer);
var
  parms: radixmultrandlightsflicker_t;
begin
  parms := radixmultrandlightsflicker_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 34
type
  radixskillratio_t = packed record
    trigger: integer;
    percentage: smallint;
  end;
  radixskillratio_p = ^radixskillratio_t;

procedure ATR_SkillRatio(const params: pointer);
var
  parms: radixskillratio_t;
begin
  parms := radixskillratio_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 35
type
  radixhurtplayerexplosion_t = packed record
    hit_points_at_center: integer;
    number_of_explosions: integer;
    x_coord: LongWord;
    y_coord: LongWord;
    height: integer;
    delta_x: integer;
    delta_y: integer;
    delay_length: integer;
    radious_one_third: integer;
  end;
  radixhurtplayerexplosion_p = ^radixhurtplayerexplosion_t;

procedure ATR_HurtPlayerExplosion(const params: pointer);
var
  parms: radixhurtplayerexplosion_t;
begin
  parms := radixhurtplayerexplosion_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 36
type
  radixswitchshadetype_t = packed record
    sector_id: smallint;
    new_light_level: smallint; // Can be > 63, first 6 bits (0-63) is lightlevel, bits 7 & 8 are shade type?
  end;
  radixswitchshadetype_p = ^radixswitchshadetype_t;

procedure ATR_SwitchShadeType(const params: pointer);
var
  parms: radixswitchshadetype_t;
begin
  parms := radixswitchshadetype_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 37
type
  radix6lightmovement_t = packed record
    on_level: smallint; // 0-63
    off_level: smallint;  // 0-63
    delay: smallint; // 1-20 in radix.dat v2
    the_sectors: packed array[0..11] of  smallint; // -1 -> no sector
  end;
  radix6lightmovement_p = ^radix6lightmovement_t;

procedure ATR_SixLightMovement(const params: pointer);
var
  parms: radix6lightmovement_t;
begin
  parms := radix6lightmovement_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 38
type
  radixsurfacepowerup_t = packed record
    sector_id: smallint;
    armour_inc: smallint;
    shield_inc: smallint;
    energy_inc: smallint;
  end;
  radixsurfacepowerup_p = ^radixsurfacepowerup_t;

procedure ATR_SurfacePowerUp(const params: pointer);
var
  parms: radixsurfacepowerup_t;
begin
  parms := radixsurfacepowerup_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 39
type
  radixsecretsprite_t = packed record
    the_sectors: packed array[0..14] of smallint; // Sector value can be -1
  end;
  radixsecretsprite_p = ^radixsecretsprite_t;

procedure ATR_SecretSprite(const params: pointer);
var
  parms: radixsecretsprite_t;
begin
  parms := radixsecretsprite_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 40
type
  radixbosseyehandler_t = packed record
    wall_number: smallint;
  end;
  radixbosseyehandler_p = ^radixbosseyehandler_t;

procedure ATR_BossEyeHandler(const params: pointer);
var
  parms: radixbosseyehandler_t;
begin
  parms := radixbosseyehandler_p(params)^;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 41
type
  radixvertexplosion_t = packed record
    number_of_explosions: integer;
    x_coord: LongWord;
    y_coord: LongWord;
    height: integer;
    delta_x: integer;
    delta_y: integer;
    delta_height: integer;
    delay_length: integer; // Value 2-3 inside dat files
    radious_one_third: integer;
    number_of_bitmaps_per: smallint;
  end;
  radixvertexplosion_p = ^radixvertexplosion_t;

procedure ATR_VertExplosion(const params: pointer);
var
  parms: radixvertexplosion_t;
begin
  parms := radixvertexplosion_p(params)^;
end;

end.

