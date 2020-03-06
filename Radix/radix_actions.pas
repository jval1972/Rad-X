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
  d_delphi,
  radix_level;

procedure RA_ScrollingWall(const action: Pradixaction_t);

procedure RA_MovingSurface(const action: Pradixaction_t);

procedure RA_SwitchWallBitmap(const action: Pradixaction_t);

procedure RA_SwitchSecBitmap(const action: Pradixaction_t);

procedure RA_ToggleWallBitmap(const action: Pradixaction_t);

procedure RA_ToggleSecBitmap(const action: Pradixaction_t);

procedure RA_CircleBitmap(const action: Pradixaction_t);

procedure RA_LightFlicker(const action: Pradixaction_t);

procedure RA_LightsOff(const action: Pradixaction_t);

procedure RA_LightsOn(const action: Pradixaction_t);

procedure RA_LightOscilate(const action: Pradixaction_t);

procedure RA_PlaneTeleport(const action: Pradixaction_t);

procedure RA_PlaneTranspo(const action: Pradixaction_t);

procedure RA_NewMovingSurface(const action: Pradixaction_t);

procedure RA_PlaySound(const action: Pradixaction_t);

procedure RA_RandLightsFlicker(const action: Pradixaction_t);

procedure RA_EndOfLevel(const action: Pradixaction_t);

procedure RA_SpriteTriggerActivate(const action: Pradixaction_t);

procedure RA_SectorBasedGravity(const action: Pradixaction_t);

procedure RA_DeactivateTrigger(const action: Pradixaction_t);

procedure RA_ActivateTrigger(const action: Pradixaction_t);

procedure RA_CompleteMissileWall(const action: Pradixaction_t);

procedure RA_ScannerJam(const action: Pradixaction_t);

procedure RA_PrintMessage(const action: Pradixaction_t);

procedure RA_FloorMissileWall(const action: Pradixaction_t);

procedure RA_CeilingMissileWall(const action: Pradixaction_t);

procedure RA_BigSpriteTrig(const action: Pradixaction_t);

procedure RA_MassiveExplosion(const action: Pradixaction_t);

procedure RA_WallDeadCheck(const action: Pradixaction_t);

procedure RA_SecondaryObjective(const action: Pradixaction_t);

procedure RA_SeekCompleteMissileWall(const action: Pradixaction_t);

procedure RA_LightMovement(const action: Pradixaction_t);

procedure RA_MultLightOscilate(const action: Pradixaction_t);

procedure RA_MultRandLightsFlicker(const action: Pradixaction_t);

procedure RA_SkillRatio(const action: Pradixaction_t);

procedure RA_HurtPlayerExplosion(const action: Pradixaction_t);

procedure RA_SwitchShadeType(const action: Pradixaction_t);

procedure RA_SixLightMovement(const action: Pradixaction_t);

procedure RA_SurfacePowerUp(const action: Pradixaction_t);

procedure RA_SecretSprite(const action: Pradixaction_t);

procedure RA_BossEyeHandler(const action: Pradixaction_t);

procedure RA_VertExplosion(const action: Pradixaction_t);

implementation

uses
  m_rnd,
  p_setup,
  radix_defs,
  radix_map_extra,
  radix_logic,
  r_data;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 0
type
  radixscrollingwall_t = packed record
    wall_number: smallint;
    direction: byte; // left/right/top/bottom ?
    speed: byte;
  end;
  radixscrollingwall_p = ^radixscrollingwall_t;

procedure RA_ScrollingWall(const action: Pradixaction_t);
var
  parms: radixscrollingwall_p;
begin
  parms := radixscrollingwall_p(@action.params);
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

procedure RA_MovingSurface(const action: Pradixaction_t);
var
  parms: radixmovingsurface_p;
begin
  parms := radixmovingsurface_p(@action.params);
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

procedure RA_SwitchWallBitmap(const action: Pradixaction_t);
var
  parms: radixswitchwallbitmap_p;
begin
  parms := radixswitchwallbitmap_p(@action.params);
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

procedure RA_SwitchSecBitmap(const action: Pradixaction_t);
var
  parms: radixswitchsecbitmap_p;
begin
  parms := radixswitchsecbitmap_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 4 - Not presend in radix.dat
procedure RA_ToggleWallBitmap(const action: Pradixaction_t);
var
  element_number, switch_bitmap, do_floor: integer;
begin
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 5 - Not presend in radix.dat
procedure RA_ToggleSecBitmap(const action: Pradixaction_t);
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
    // RTL params here
    calced: boolean;
    flat_1: integer;
    flat_2: integer;
    flat_3: integer;
    texture_1: integer;
    texture_2: integer;
    texture_3: integer;
    tick: integer;
  end;
  radixcirclebitmap_p = ^radixcirclebitmap_t;

procedure RA_CircleBitmap(const action: Pradixaction_t);
var
  parms: radixcirclebitmap_p;
begin
  parms := radixcirclebitmap_p(@action.params);

  if not parms.calced then
  begin
    parms.flat_1 := R_FlatNumForName(RX_FLAT_PREFIX + IntToStrzFill(4, parms.bitmap_1 + 1));
    parms.flat_2 := R_FlatNumForName(RX_FLAT_PREFIX + IntToStrzFill(4, parms.bitmap_2 + 1));
    parms.flat_3 := R_FlatNumForName(RX_FLAT_PREFIX + IntToStrzFill(4, parms.bitmap_3 + 1));
    parms.texture_1 := R_TextureNumForName(RX_WALL_PREFIX + IntToStrzFill(4, parms.bitmap_1 + 1));
    parms.texture_2 := R_TextureNumForName(RX_WALL_PREFIX + IntToStrzFill(4, parms.bitmap_2 + 1));
    parms.texture_3 := R_TextureNumForName(RX_WALL_PREFIX + IntToStrzFill(4, parms.bitmap_3 + 1));
    parms.calced := true;
    parms.tick := 0;
  end;

  if parms.tick = 0 then
    parms.tick := 3 * parms.max_delay;

  dec(parms.tick);
  case parms.tick div parms.max_delay of
    0:
      begin
        flats[parms.flat_1].translation := parms.flat_1;
        texturetranslation[parms.texture_1] := parms.texture_1;
      end;
    1:
      begin
        flats[parms.flat_1].translation := parms.flat_2;
        texturetranslation[parms.texture_1] := parms.texture_2;
      end;
    2:
      begin
        flats[parms.flat_1].translation := parms.flat_3;
        texturetranslation[parms.texture_1] := parms.texture_3;
      end;
  end;
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

procedure RA_LightFlicker(const action: Pradixaction_t);
var
  parms: radixlightflicker_p;
begin
  parms := radixlightflicker_p(@action.params);
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

procedure RA_LightsOff(const action: Pradixaction_t);
var
  parms: radixlightsoff_p;
begin
  parms := radixlightsoff_p(@action.params);
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

procedure RA_LightsOn(const action: Pradixaction_t);
var
  parms: radixlightson_p;
begin
  parms := radixlightson_p(@action.params);
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

procedure RA_LightOscilate(const action: Pradixaction_t);
var
  parms: radixlightoscilate_p;
begin
  parms := radixlightoscilate_p(@action.params);
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

procedure RA_PlaneTeleport(const action: Pradixaction_t);
var
  parms: radixplaneteleport_p;
begin
  parms := radixplaneteleport_p(@action.params);
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

procedure RA_PlaneTranspo(const action: Pradixaction_t);
var
  parms: radixplanetranspo_p;
begin
  parms := radixplanetranspo_p(@action.params);
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
    surface_type: byte; // 1-> floor, 2-> ceiling
    direction: byte;  // 1-> up, 0-> delayed, -1 -> down
    stop_position: byte; // 0-> no stop, 1-> maxstop, 2-> minstop, 3-> allstop
    approx_x: LongWord;
    approx_y: LongWord;
    start_sound: smallint;
    stop_sound: smallint;
    activate_trig: smallint;
    trigger_number: smallint;
  end;
  radixnewmovingsurface_p = ^radixnewmovingsurface_t;

procedure RA_NewMovingSurface(const action: Pradixaction_t);
var
  parms: radixnewmovingsurface_p;
begin
  parms := radixnewmovingsurface_p(@action.params);
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

procedure RA_PlaySound(const action: Pradixaction_t);
var
  parms: radixplaysound_p;
begin
  parms := radixplaysound_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 15
type
  radixrandlightsflicker_t = packed record
    off_countdown: smallint;  // RTL
    on_countdown: smallint;   // RTL
    off_min_delay: smallint;
    off_max_delay: smallint;
    on_min_delay: smallint;
    on_max_delay: smallint;
    on_off: smallint;         // RTL
    off_light_level: smallint;
    on_light_level: smallint;
    sector: smallint;
  end;
  radixrandlightsflicker_p = ^radixrandlightsflicker_t;

procedure RA_RandLightsFlicker(const action: Pradixaction_t);
var
  parms: radixrandlightsflicker_p;
begin
  parms := radixrandlightsflicker_p(@action.params);

  if parms.on_off = 0 then
  begin
    if parms.off_countdown = 0 then
    begin
      sectors[parms.sector].lightlevel := RX_LightLevel(parms.on_light_level);
      parms.on_countdown := P_RandomInRange(parms.on_min_delay, parms.on_max_delay);
      parms.on_off := 1;
    end
    else
      dec(parms.off_countdown);
  end
  else
  begin
    if parms.on_countdown = 0 then
    begin
      sectors[parms.sector].lightlevel := RX_LightLevel(parms.off_light_level);
      parms.off_countdown := P_RandomInRange(parms.off_min_delay, parms.off_max_delay);
      parms.on_off := 0;
    end
    else
      dec(parms.on_countdown);
  end;
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

procedure RA_EndOfLevel(const action: Pradixaction_t);
var
  parms: radixendoflevel_p;
begin
  parms := radixendoflevel_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 17
type
  radixspritetriggeractivate_t = packed record
    trigger: integer;
    sprites: packed array[0..4] of integer;
  end;
  radixspritetriggeractivate_p = ^radixspritetriggeractivate_t;

procedure RA_SpriteTriggerActivate(const action: Pradixaction_t);
var
  parms: radixspritetriggeractivate_p;
begin
  parms := radixspritetriggeractivate_p(@action.params);
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

procedure RA_SectorBasedGravity(const action: Pradixaction_t);
var
  parms: radixsectorbasedgravity_p;
begin
  parms := radixsectorbasedgravity_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 19
type
  radixdeactivatetrigger_t = packed record
    trigger: byte;
  end;
  radixdeactivatetrigger_p = ^radixdeactivatetrigger_t;

procedure RA_DeactivateTrigger(const action: Pradixaction_t);
var
  parms: radixdeactivatetrigger_p;
begin
  parms := radixdeactivatetrigger_p(@action.params);
  radixtriggers[parms.trigger].suspended := 1;
  action.suspend := 1;  // JVAL: 202003 - Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 20
type
  radixactivatetrigger_t = packed record
    trigger: byte;
  end;
  radixactivatetrigger_p = ^radixactivatetrigger_t;

procedure RA_ActivateTrigger(const action: Pradixaction_t);
var
  parms: radixactivatetrigger_p;
begin
  parms := radixactivatetrigger_p(@action.params);
  radixtriggers[parms.trigger].suspended := 0;
  action.suspend := 1;  // JVAL: 202003 - Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 21
type
  radixcompletemissilewall_t = packed record
    wall_number: smallint;
  end;
  radixcompletemissilewall_p = ^radixcompletemissilewall_t;

procedure RA_CompleteMissileWall(const action: Pradixaction_t);
var
  parms: radixcompletemissilewall_p;
begin
  parms := radixcompletemissilewall_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 22
type
  radixscannerjam_t = packed record
    on_off: smallint; // 1-> jam radar, 0-> enable radar
  end;
  radixscannerjam_p = ^radixscannerjam_t;

procedure RA_ScannerJam(const action: Pradixaction_t);
var
  parms: radixscannerjam_p;
begin
  parms := radixscannerjam_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 23
type
  radixprintmessage_t = packed record
    message_id: byte; // id's 0-11
  end;
  radixprintmessage_p = ^radixprintmessage_t;

procedure RA_PrintMessage(const action: Pradixaction_t);
var
  parms: radixprintmessage_p;
begin
  parms := radixprintmessage_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 24
type
  radixfloormissilewall_t = packed record
    wall_number: smallint;
  end;
  radixfloormissilewall_p = ^radixfloormissilewall_t;

procedure RA_FloorMissileWall(const action: Pradixaction_t);
var
  parms: radixfloormissilewall_p;
begin
  parms := radixfloormissilewall_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 25
type
  radixceilingmissilewall_t = packed record
    wall_number: smallint;
  end;
  radixceilingmissilewall_p = ^radixceilingmissilewall_t;

procedure RA_CeilingMissileWall(const action: Pradixaction_t);
var
  parms: radixceilingmissilewall_p;
begin
  parms := radixceilingmissilewall_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 26
type
  radixbigspritetrig_t = packed record
    trigger: integer;
    the_sprites: packed array[0..19] of integer; // Zero and negative do not count
  end;
  radixbigspritetrig_p = ^radixbigspritetrig_t;

procedure RA_BigSpriteTrig(const action: Pradixaction_t);
var
  parms: radixbigspritetrig_p;
begin
  parms := radixbigspritetrig_p(@action.params);
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

procedure RA_MassiveExplosion(const action: Pradixaction_t);
var
  parms: radixmassiveexplosion_p;
begin
  parms := radixmassiveexplosion_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 28
type
  radixwalldeadcheck_t = packed record
    trigger: integer;
    the_walls: packed array[0..4] of integer; // Wall values can be negative
  end;
  radixwalldeadcheck_p = ^radixwalldeadcheck_t;

procedure RA_WallDeadCheck(const action: Pradixaction_t);
var
  parms: radixwalldeadcheck_p;
begin
  parms := radixwalldeadcheck_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 29
type
  radixsecondaryobjective_t = packed record
    return_value: byte;
  end;
  radixsecondaryobjective_p = ^radixsecondaryobjective_t;

procedure RA_SecondaryObjective(const action: Pradixaction_t);
var
  parms: radixsecondaryobjective_p;
begin
  parms := radixsecondaryobjective_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 30
type
  radixseekcompletemissilewall_t = packed record
    wall_number: smallint;
  end;
  radixseekcompletemissilewall_p = ^radixseekcompletemissilewall_t;

procedure RA_SeekCompleteMissileWall(const action: Pradixaction_t);
var
  parms: radixseekcompletemissilewall_p;
begin
  parms := radixseekcompletemissilewall_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 31
type
  radixspritelightmovement_t = packed record
    on_level: smallint;   // light level from 0 to 63
    off_level: smallint;  // light level from 0 to 63
    delay: smallint;
    the_sectors: packed array[0..3] of smallint;  // Sector can be -1
    // RTL
    tick: integer;
  end;
  radixspritelightmovement_p = ^radixspritelightmovement_t;

procedure RA_LightMovement(const action: Pradixaction_t);
var
  parms: radixspritelightmovement_p;
  l_off, l_on: integer;
begin
  parms := radixspritelightmovement_p(@action.params);

  if parms.tick = 0 then
    parms.tick := 4 * parms.delay;

  dec(parms.tick);

  l_off := RX_LightLevel(parms.off_level);
  l_on := RX_LightLevel(parms.on_level);
  case parms.tick div parms.delay of
    0:
      begin
        sectors[parms.the_sectors[0]].lightlevel := l_on;
        sectors[parms.the_sectors[1]].lightlevel := l_off;
        sectors[parms.the_sectors[2]].lightlevel := l_off;
        sectors[parms.the_sectors[3]].lightlevel := l_off;
      end;
    1:
      begin
        sectors[parms.the_sectors[0]].lightlevel := l_off;
        sectors[parms.the_sectors[1]].lightlevel := l_on;
        sectors[parms.the_sectors[2]].lightlevel := l_off;
        sectors[parms.the_sectors[3]].lightlevel := l_off;
      end;
    2:
      begin
        sectors[parms.the_sectors[0]].lightlevel := l_off;
        sectors[parms.the_sectors[1]].lightlevel := l_off;
        sectors[parms.the_sectors[2]].lightlevel := l_on;
        sectors[parms.the_sectors[3]].lightlevel := l_off;
      end;
    3:
      begin
        sectors[parms.the_sectors[0]].lightlevel := l_off;
        sectors[parms.the_sectors[1]].lightlevel := l_off;
        sectors[parms.the_sectors[2]].lightlevel := l_off;
        sectors[parms.the_sectors[3]].lightlevel := l_on;
      end;
  end;

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

procedure RA_MultLightOscilate(const action: Pradixaction_t);
var
  parms: radixmultlightoscilate_p;
begin
  parms := radixmultlightoscilate_p(@action.params);
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

procedure RA_MultRandLightsFlicker(const action: Pradixaction_t);
var
  parms: radixmultrandlightsflicker_p;
begin
  parms := radixmultrandlightsflicker_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 34
type
  radixskillratio_t = packed record
    trigger: integer;
    percentage: smallint;
  end;
  radixskillratio_p = ^radixskillratio_t;

procedure RA_SkillRatio(const action: Pradixaction_t);
var
  parms: radixskillratio_p;
begin
  parms := radixskillratio_p(@action.params);
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

procedure RA_HurtPlayerExplosion(const action: Pradixaction_t);
var
  parms: radixhurtplayerexplosion_p;
begin
  parms := radixhurtplayerexplosion_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 36
type
  radixswitchshadetype_t = packed record
    sector_id: smallint;
    new_light_level: smallint; // Can be > 63, first 6 bits (0-63) is lightlevel, bits 7 & 8 are shade type?
  end;
  radixswitchshadetype_p = ^radixswitchshadetype_t;

procedure RA_SwitchShadeType(const action: Pradixaction_t);
var
  parms: radixswitchshadetype_p;
begin
  parms := radixswitchshadetype_p(@action.params);
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

procedure RA_SixLightMovement(const action: Pradixaction_t);
var
  parms: radix6lightmovement_p;
begin
  parms := radix6lightmovement_p(@action.params);
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

procedure RA_SurfacePowerUp(const action: Pradixaction_t);
var
  parms: radixsurfacepowerup_p;
begin
  parms := radixsurfacepowerup_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 39
type
  radixsecretsprite_t = packed record
    the_sectors: packed array[0..14] of smallint; // Sector value can be -1
  end;
  radixsecretsprite_p = ^radixsecretsprite_t;

procedure RA_SecretSprite(const action: Pradixaction_t);
var
  parms: radixsecretsprite_p;
begin
  parms := radixsecretsprite_p(@action.params);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 40
type
  radixbosseyehandler_t = packed record
    wall_number: smallint;
  end;
  radixbosseyehandler_p = ^radixbosseyehandler_t;

procedure RA_BossEyeHandler(const action: Pradixaction_t);
var
  parms: radixbosseyehandler_p;
begin
  parms := radixbosseyehandler_p(@action.params);
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

procedure RA_VertExplosion(const action: Pradixaction_t);
var
  parms: radixvertexplosion_p;
begin
  parms := radixvertexplosion_p(@action.params);
end;

end.

