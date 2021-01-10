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

procedure RA_KillRatio(const action: Pradixaction_t);

procedure RA_HurtPlayerExplosion(const action: Pradixaction_t);

procedure RA_SwitchShadeType(const action: Pradixaction_t);

procedure RA_SixLightMovement(const action: Pradixaction_t);

procedure RA_SurfacePowerUp(const action: Pradixaction_t);

procedure RA_SecretSprite(const action: Pradixaction_t);

procedure RA_BossEyeHandler(const action: Pradixaction_t);

procedure RA_VertExplosion(const action: Pradixaction_t);

procedure RA_ChangeFloorOffsets(const action: Pradixaction_t);

procedure RA_MassiveLightMovement(const action: Pradixaction_t);

implementation

uses
  doomdef,
  d_player,
  d_think,
  g_game,
  m_rnd,
  m_fixed,
  tables,
  p_inter,
  p_map,
  p_mobj_h,
  p_mobj,
  p_telept,
  p_tick,
  p_setup,
  p_genlin,
  p_user,
  radix_defs,
  radix_map_extra,
  radix_messages,
  radix_logic,
  radix_objects,
  radix_sounds,
  radix_player,
  radix_teleport,
  r_data,
  r_main,
  r_defs,
  s_sound,
  w_wad;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 0
type
  radixscrollingwall_t = packed record
    wall_number: smallint;
    direction: byte; // Only 0 (right) in radix.dat - Extended to left, up & down
    speed: byte;
  end;
  radixscrollingwall_p = ^radixscrollingwall_t;

procedure RA_ScrollingWall(const action: Pradixaction_t);
var
  parms: radixscrollingwall_p;
  li: Pline_t;
  s1, s2: Pside_t;
  dx: fixed_t;
begin
  parms := radixscrollingwall_p(@action.params);

  dx := parms.speed * FRACUNIT;
  if dx = 0 then
    exit; // No scroll

  li := @lines[parms.wall_number];

  // JVAL: 20200307 - Set interpolate flag
  li.radixflags := li.radixflags or RWF_FORCEINTERPOLATE;

  if li.sidenum[0] > 0 then
    s1 := @sides[li.sidenum[0]]
  else
    s1 := nil;
  if li.sidenum[1] > 0 then
    s2 := @sides[li.sidenum[1]]
  else
    s2 := nil;

  case parms.direction of
    0:  // Only 0 in radix.dat v2 remix (right)
      begin
        if s1 <> nil then
          s1.textureoffset := s1.textureoffset - dx;
        if s2 <> nil then
          s2.textureoffset := s2.textureoffset - dx;
      end;
    // JVAL: 20200307 - Let's extend the direction field
    //   1 -> scroll left
    //   2 -> scroll up
    //   3 -> scroll down
    1, 255:  // left
      begin
        if s1 <> nil then
          s1.textureoffset := s1.textureoffset + dx;
        if s2 <> nil then
          s2.textureoffset := s2.textureoffset + dx;
      end;
    2:  // up
      begin
        if s1 <> nil then
          s1.rowoffset := s1.rowoffset + dx;
        if s2 <> nil then
          s2.rowoffset := s2.rowoffset + dx;
      end;
    3:  // down
      begin
        if s1 <> nil then
          s1.rowoffset := s1.rowoffset - dx;
        if s2 <> nil then
          s2.rowoffset := s2.rowoffset - dx;
      end;
  end;
end;

const
  MOVINGSURFACETHRESHHOLD = 10;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 1
type
  radixmovingsurface_t = packed record
    surface: smallint;
    max_height: smallint;
    min_height: smallint;
    max_delay: smallint;  // JVAL: 20200416 -> 0, 35, 70 in RADIX.DAT
    speed: byte;          // JVAL: 20200416 -> 0, 1, 3, 4, 6, 7, 8, 9, 10 & 12 in RADIX.DAT
    surface_type: byte;   // JVAL: 20200416 -> 0, 1 in RADIX.DAT
    direction: byte;      // JVAL: 20200416 -> 1, 255 in RADIX.DAT
    stop_position: byte;  // JVAL: 20200416 -> 1, 2 in RADIX.DAT
    // RTL
    initialized: boolean;
  end;
  radixmovingsurface_p = ^radixmovingsurface_t;

procedure RA_MovingSurface(const action: Pradixaction_t);
var
  parms: radixmovingsurface_p;
  sec: Psector_t;
  dest_height: fixed_t;
  step: fixed_t;
  finished: boolean;

  function playercheck(const fl, cl: fixed_t): boolean;
  var
    i: integer;
    mo: Pmobj_t;
  begin
    for i := 0 to MAXPLAYERS - 1 do
      if playeringame[i] then
      begin
        mo := players[i].mo;
        if cl - fl <= players[i].mo.height then
          if (Psubsector_t(mo.subsector).sector = sec) or
             (R_PointInSubsector(mo.x - mo.radius, mo.y - mo.radius).sector = sec) or
             (R_PointInSubsector(mo.x + mo.radius, mo.y - mo.radius).sector = sec) or
             (R_PointInSubsector(mo.x + mo.radius, mo.y + mo.radius).sector = sec) or
             (R_PointInSubsector(mo.x - mo.radius, mo.y + mo.radius).sector = sec) then
          begin
            result := false;
            exit;
          end;
      end;
    result := true;
  end;

begin
  parms := radixmovingsurface_p(@action.params);

  if parms.max_delay > 0 then
  begin
    dec(parms.max_delay);
    exit;
  end;

  sec := @sectors[parms.surface];

  if parms.direction = 1 then // Up
  begin
    dest_height := parms.max_height * FRACUNIT;
    if parms.speed > MOVINGSURFACETHRESHHOLD then
      step := (1 shl MOVINGSURFACETHRESHHOLD) * FRACUNIT
    else
      step := (1 shl parms.speed) * FRACUNIT;
  end
  else if parms.direction = $FF then // Down
  begin
    dest_height := parms.min_height * FRACUNIT;
    if parms.speed > MOVINGSURFACETHRESHHOLD then
      step := -(1 shl MOVINGSURFACETHRESHHOLD) * FRACUNIT
    else
      step := -(1 shl parms.speed) * FRACUNIT;
  end
  else
    exit; // ouch

  // JVAL: 20200403 - Avoid interpolation for fast moving sectors
  if parms.speed > MOVINGSURFACETHRESHHOLD - 2 then
    sec.renderflags := sec.renderflags or SRF_NO_INTERPOLATE;

  case parms.surface_type of
    1: // floor
      begin
        if step > 0 then
          if not playercheck(sec.floorheight + step, sec.ceilingheight) then
            exit;

        sec.floorheight := sec.floorheight + step;

        if parms.direction = 1 then // Up
          finished := sec.floorheight >= dest_height
        else // if parms.direction = -1 then // Down
          finished := sec.floorheight <= dest_height;
        if finished then
        begin
          sec.floorheight := dest_height;
          action.suspend := 1;  // JVAL: 20200306 - Disable action
        end;
      end;
    0: // ceiling
      begin
        if step < 0 then
          if not playercheck(sec.floorheight, sec.ceilingheight + step) then
            exit;
            
        sec.ceilingheight := sec.ceilingheight + step;

        if parms.direction = 1 then // Up
          finished := sec.ceilingheight >= dest_height
        else // if parms.direction = -1 then // Down
          finished := sec.ceilingheight <= dest_height;
        if finished then
        begin
          sec.ceilingheight := dest_height;
          action.suspend := 1;  // JVAL: 202003 - Disable action
        end;
      end;
  end;

  P_ChangeSector(sec, true);  // JVAL: 20200313
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 2
type
  radixswitchwallbitmap_t = packed record
    element_number: smallint;
    switch_bitmap: smallint;
    do_floor: smallint;
  end;
  radixswitchwallbitmap_p = ^radixswitchwallbitmap_t;

procedure RA_SwitchWallBitmap(const action: Pradixaction_t);
var
  parms: radixswitchwallbitmap_p;
  li: Pline_t;
  s1, s2: Pside_t;
  texid: integer;
begin
  parms := radixswitchwallbitmap_p(@action.params);

  li := @lines[parms.element_number];

  if li.sidenum[0] > 0 then
    s1 := @sides[li.sidenum[0]]
  else
    s1 := nil;
  if li.sidenum[1] > 0 then
    s2 := @sides[li.sidenum[1]]
  else
    s2 := nil;

  texid := R_TextureNumForName(RX_WALL_PREFIX + IntToStrzFill(4, parms.switch_bitmap + 1));

  if parms.do_floor = 0 then  // Ceiling or mid
  begin
    if s1 <> nil then
    begin
      if s1.toptexture <> 0 then
        s1.toptexture := texid;
      if s1.midtexture <> 0 then
        s1.midtexture := texid;
    end;
    if s2 <> nil then
    begin
      if s2.toptexture <> 0 then
        s2.toptexture := texid;
      if s2.midtexture <> 0 then
        s2.midtexture := texid;
    end;
  end
  else if parms.do_floor = 256 then  // Floor or mid
  begin
    if s1 <> nil then
    begin
      if s1.bottomtexture <> 0 then
        s1.bottomtexture := texid;
      if s1.midtexture <> 0 then
        s1.midtexture := texid;
    end;
    if s2 <> nil then
    begin
      if s2.bottomtexture <> 0 then
        s2.bottomtexture := texid;
      if s2.midtexture <> 0 then
        s2.midtexture := texid;
    end;
  end;

  action.suspend := 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 3
type
  radixswitchsecbitmap_t = packed record
    element_number: smallint; // sector id
    switch_bitmap: smallint;
    do_floor: smallint;
  end;
  radixswitchsecbitmap_p = ^radixswitchsecbitmap_t;

procedure RA_SwitchSecBitmap(const action: Pradixaction_t);
var
  parms: radixswitchsecbitmap_p;
  texid: integer;
begin
  parms := radixswitchsecbitmap_p(@action.params);

  texid := R_FlatNumForName(RX_FLAT_PREFIX + IntToStrzFill(4, parms.switch_bitmap + 1));

  if parms.do_floor = 257 then  // floor texture
    sectors[parms.element_number].floorpic := texid
  else
    sectors[parms.element_number].ceilingpic := texid;

  action.suspend := 1; // Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 4 - Not presend in radix.dat
type
  radixtogglewallbitmap_t = packed record
    element_number: smallint;
    switch_bitmap: smallint;
    do_floor: smallint;
    // RTL
    initialize_flag: LongWord;
    new_switch_bitmap_top1: char8_t;
    new_switch_bitmap_mid1: char8_t;
    new_switch_bitmap_bot1: char8_t;
    new_switch_bitmap_top2: char8_t;
    new_switch_bitmap_mid2: char8_t;
    new_switch_bitmap_bot2: char8_t;
  end;
  radixtogglewallbitmap_p = ^radixtogglewallbitmap_t;

procedure RA_ToggleWallBitmap(const action: Pradixaction_t);
var
  parms: radixtogglewallbitmap_p;
  li: Pline_t;
  s1, s2: Pside_t;
  texid_top1: integer;
  texid_mid1: integer;
  texid_bot1: integer;
  texid_top2: integer;
  texid_mid2: integer;
  texid_bot2: integer;
begin
  parms := radixtogglewallbitmap_p(@action.params);

  li := @lines[parms.element_number];

  if li.sidenum[0] > 0 then
    s1 := @sides[li.sidenum[0]]
  else
    s1 := nil;
  if li.sidenum[1] > 0 then
    s2 := @sides[li.sidenum[1]]
  else
    s2 := nil;

  if parms.initialize_flag <> $FFFFDDDD then
  begin
    parms.new_switch_bitmap_top1 := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, parms.switch_bitmap + 1));
    parms.new_switch_bitmap_bot1 := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, parms.switch_bitmap + 1));
    parms.new_switch_bitmap_mid1 := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, parms.switch_bitmap + 1));
    parms.new_switch_bitmap_top2 := parms.new_switch_bitmap_top1;
    parms.new_switch_bitmap_bot2 := parms.new_switch_bitmap_bot1;
    parms.new_switch_bitmap_mid2 := parms.new_switch_bitmap_mid1;
    parms.initialize_flag := $FFFFDDDD;
  end;

  texid_top1 := R_SafeTextureNumForName(parms.new_switch_bitmap_top1);
  texid_mid1 := R_SafeTextureNumForName(parms.new_switch_bitmap_mid1);
  texid_bot1 := R_SafeTextureNumForName(parms.new_switch_bitmap_bot1);
  texid_top2 := R_SafeTextureNumForName(parms.new_switch_bitmap_top2);
  texid_mid2 := R_SafeTextureNumForName(parms.new_switch_bitmap_mid2);
  texid_bot2 := R_SafeTextureNumForName(parms.new_switch_bitmap_bot2);

  if s1 <> nil then
  begin
    parms.new_switch_bitmap_top1 := R_NameForSideTexture(s1.toptexture);
    parms.new_switch_bitmap_bot1 := R_NameForSideTexture(s1.bottomtexture);
    parms.new_switch_bitmap_mid1 := R_NameForSideTexture(s1.midtexture);
  end
  else
  begin
    parms.new_switch_bitmap_top1 := stringtochar8('-');
    parms.new_switch_bitmap_bot1 := stringtochar8('-');
    parms.new_switch_bitmap_mid1 := stringtochar8('-');
  end;

  if s2 <> nil then
  begin
    parms.new_switch_bitmap_top2 := R_NameForSideTexture(s2.toptexture);
    parms.new_switch_bitmap_bot2 := R_NameForSideTexture(s2.bottomtexture);
    parms.new_switch_bitmap_mid2 := R_NameForSideTexture(s2.midtexture);
  end
  else
  begin
    parms.new_switch_bitmap_top2 := stringtochar8('-');
    parms.new_switch_bitmap_bot2 := stringtochar8('-');
    parms.new_switch_bitmap_mid2 := stringtochar8('-');
  end;

  if parms.do_floor = 0 then  // Ceiling or mid
  begin
    if s1 <> nil then
    begin
      if s1.toptexture <> 0 then
        s1.toptexture := texid_top1;
      if s1.midtexture <> 0 then
        s1.midtexture := texid_mid1;
    end;
    if s2 <> nil then
    begin
      if s2.toptexture <> 0 then
        s2.toptexture := texid_top2;
      if s2.midtexture <> 0 then
        s2.midtexture := texid_mid2;
    end;
  end
  else if parms.do_floor = 256 then  // Floor or mid
  begin
    if s1 <> nil then
    begin
      if s1.bottomtexture <> 0 then
        s1.bottomtexture := texid_bot1;
      if s1.midtexture <> 0 then
        s1.midtexture := texid_mid1;
    end;
    if s2 <> nil then
    begin
      if s2.bottomtexture <> 0 then
        s2.bottomtexture := texid_bot2;
      if s2.midtexture <> 0 then
        s2.midtexture := texid_mid2;
    end;
  end;

  action.suspend := 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 5 - Not presend in radix.dat
type
  radixtongglesecbitmap_t = packed record
    element_number: smallint; // sector id
    switch_bitmap: smallint;
    do_floor: smallint;
    // RTL
    initialize_flag: LongWord;
    new_switch_bitmap: smallint;
  end;
  radixtongglesecbitmap_p = ^radixtongglesecbitmap_t;

procedure RA_ToggleSecBitmap(const action: Pradixaction_t);
var
  parms: radixtongglesecbitmap_p;
  texid: integer;
begin
  parms := radixtongglesecbitmap_p(@action.params);

  if parms.initialize_flag <> $FFFFDDDD then
  begin
    parms.new_switch_bitmap := R_FlatNumForName(RX_FLAT_PREFIX + IntToStrzFill(4, parms.switch_bitmap + 1));
    parms.initialize_flag := $FFFFDDDD;
  end;

  texid := parms.new_switch_bitmap;

  if parms.do_floor = 257 then  // floor texture
  begin
    parms.new_switch_bitmap := sectors[parms.element_number].floorpic;
    sectors[parms.element_number].floorpic := texid;
  end
  else
  begin
    parms.new_switch_bitmap := sectors[parms.element_number].ceilingpic;
    sectors[parms.element_number].ceilingpic := texid;
  end;

  action.suspend := 1; // Disable action
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
    // RTL
    countdown: integer;
    oncountdown: boolean;
  end;
  radixlightflicker_p = ^radixlightflicker_t;

procedure RA_LightFlicker(const action: Pradixaction_t);
var
  parms: radixlightflicker_p;
begin
  parms := radixlightflicker_p(@action.params);

  if parms.countdown > 0 then
  begin
    dec(parms.countdown);
    exit;
  end;

  if parms.oncountdown then
  begin
    sectors[parms.sector].lightlevel := RX_LightLevel(parms.on_light_level, sectors[parms.sector].radixflags);
    parms.countdown := parms.on_delay;
  end
  else
  begin
    sectors[parms.sector].lightlevel := RX_LightLevel(parms.off_light_level, sectors[parms.sector].radixflags);
    parms.countdown := parms.off_delay;
  end;

  parms.oncountdown := not parms.oncountdown;
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

  sectors[parms.sector].lightlevel := RX_LightLevel(parms.off_light_level, sectors[parms.sector].radixflags);

  action.suspend := 1; // Disable action
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

  sectors[parms.sector].lightlevel := RX_LightLevel(parms.on_light_level, sectors[parms.sector].radixflags);

  action.suspend := 1; // Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 10
type
  radixlightoscilate_t = packed record
    max_light: smallint; // JVAL: Values > 63 in radix.dat (fog ?)
    min_light: smallint; // JVAL: Values > 63 in radix.dat (fog ?)
    direction: smallint;
    speed: smallint;
    sector: smallint;
    // RTL
    curlevel: integer;
  end;
  radixlightoscilate_p = ^radixlightoscilate_t;

procedure RA_LightOscilate(const action: Pradixaction_t);
var
  parms: radixlightoscilate_p;
begin
  parms := radixlightoscilate_p(@action.params);

  if parms.direction = 0 then
  begin
    inc(parms.curlevel);
    parms.curlevel := GetIntegerInRange(parms.curlevel, parms.min_light, parms.max_light);
    if parms.curlevel = parms.max_light then
      parms.direction := 1;
  end
  else
  begin
    dec(parms.curlevel);
    parms.curlevel := GetIntegerInRange(parms.curlevel, parms.min_light, parms.max_light);
    if parms.curlevel = parms.min_light then
      parms.direction := 0;
  end;

  sectors[parms.sector].lightlevel := RX_LightLevel(parms.curlevel, sectors[parms.sector].radixflags);
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
  p: Pplayer_t;
  x, y: fixed_t;
  s, c: fixed_t;
  momx, momy: fixed_t;
  angle: angle_t;
  deltaviewheight: integer;
begin
  parms := radixplaneteleport_p(@action.params);
                 
  if parms.delay > 0 then
  begin
    dec(parms.delay);
    exit;
  end;

  p := @players[radixplayer];

  x := RX_RadixX2Doom(parms.new_x, parms.new_y) * FRACUNIT;
  y := RX_RadixY2Doom(parms.new_x, parms.new_y) * FRACUNIT;

  // Momentum of thing crossing teleporter linedef
  momx := p.mo.momx;
  momy := p.mo.momy;

  // JVAL: 20200504 - Disappear teleport fog
  RX_SpawnTeleportForceField(p.mo);

  if not P_TeleportMove(p.mo, x, y) then
    exit;

  angle := parms.new_angle * (ANGLE_MAX div 256);
  // Sine, cosine of angle adjustment
  s := finesine[angle shr ANGLETOFINESHIFT];
  c := finecosine[angle shr ANGLETOFINESHIFT];

  if parms.change_height <> 0 then
    p.mo.z := parms.new_height * FRACUNIT;
  if p.mo.z < p.mo.floorz then
    p.mo.z := p.mo.floorz
  else if p.mo.z > p.mo.ceilingz - p.mo.height then
    p.mo.z := p.mo.ceilingz - p.mo.height;

  p.mo.angle := angle;

  // Rotate thing's momentum to come out of exit just like it entered
  p.mo.momx := FixedMul(momx, c) - FixedMul(momy, s);
  p.mo.momy := FixedMul(momy, c) + FixedMul(momx, s);

  // Save the current deltaviewheight, used in stepping
  deltaviewheight := p.deltaviewheight;

  // Clear deltaviewheight, since we don't want any changes
  p.deltaviewheight := 0;

  // Set player's view according to the newly set parameters
  P_CalcHeight(p);

  // Reset the delta to have the same dynamics as before
  p.deltaviewheight := deltaviewheight;

  p.mo.reactiontime := 18;
  p.teleporttics := TELEPORTZOOM;

  // JVAL: 20200504 - Reappear teleport fog
  RX_SpawnTeleportForceField(p.mo);

  action.suspend := 1;
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
    line_angle: word;
  end;
  radixplanetranspo_p = ^radixplanetranspo_t;

procedure RA_PlaneTranspo(const action: Pradixaction_t);
var
  parms: radixplanetranspo_p;
  p: Pplayer_t;
begin
  parms := radixplanetranspo_p(@action.params);

  p := @players[radixplayer];

  if p.planetranspo_tics > 0 then
  begin
    action.suspend := 1;
    exit; // Already transported
  end;

  p.planetranspo_start_x := p.mo.x;
  p.planetranspo_start_y := p.mo.y;
  p.planetranspo_start_z := p.mo.z;
  p.planetranspo_start_a := p.mo.angle;

  p.planetranspo_target_x := RX_RadixX2Doom(parms.target_x, parms.target_y) * FRACUNIT;
  p.planetranspo_target_y := RX_RadixY2Doom(parms.target_x, parms.target_y) * FRACUNIT;
  p.planetranspo_target_z := parms.target_height * FRACUNIT;
  p.planetranspo_target_a := parms.line_angle * (ANGLE_MAX div 256);

  p.planetranspo_start_tics := parms.tick_count;
  p.planetranspo_tics := parms.tick_count;

  action.suspend := 1;
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
    surface_type: byte; // 1-> floor, 0-> ceiling
    direction: byte;  // 1-> up, 0-> delayed, -1($FF) -> down
    stop_position: byte; // 0-> no stop, 1-> maxstop, 2-> minstop, 3-> allstop
    approx_x: LongWord;
    approx_y: LongWord;
    start_sound: smallint;
    stop_sound: smallint;
    activate_trig: smallint;
    trigger_number: smallint;
    // RTL
    sound_initialized: boolean;
    delay_saved: boolean;
    save_delay: integer;
    dir_initialized: boolean;
    initial_direction: byte;
  end;
  radixnewmovingsurface_p = ^radixnewmovingsurface_t;

procedure RA_NewMovingSurface(const action: Pradixaction_t);
var
  parms: radixnewmovingsurface_p;
  sec: Psector_t;
  dest_height: fixed_t;
  step: fixed_t;
  finished: boolean;
  changed_direction: boolean;
label
  finish_move;

  // After finishing checks if need to change direction
  procedure finishcheck;
  begin
    // JVAL: 20200405
    //  If "direction" is Up (1) and "stop position" is Min (2)
    //  We continue changing movement down
    if (parms.direction = 1) and (parms.stop_position = 2) then
    begin
      changed_direction := true;
      parms.direction := $FF;
      parms.stop_position := 1;
    end
    // JVAL: 20200405
    //  If "direction" is Down ($FF) and "stop position" is Max (1)
    //  We continue changing movement up
    else if (parms.direction = $FF) and (parms.stop_position = 1) then
    begin
      changed_direction := true;
      parms.direction := 1;
      parms.stop_position := 2;
    end;
  end;

  function playercheck(const fl, cl: fixed_t): boolean;
  var
    i: integer;
    mo: Pmobj_t;
  begin
    for i := 0 to MAXPLAYERS - 1 do
      if playeringame[i] then
      begin
        mo := players[i].mo;
        if cl - fl <= players[i].mo.height then
          if (Psubsector_t(mo.subsector).sector = sec) or
             (R_PointInSubsector(mo.x - mo.radius, mo.y - mo.radius).sector = sec) or
             (R_PointInSubsector(mo.x + mo.radius, mo.y - mo.radius).sector = sec) or
             (R_PointInSubsector(mo.x + mo.radius, mo.y + mo.radius).sector = sec) or
             (R_PointInSubsector(mo.x - mo.radius, mo.y + mo.radius).sector = sec) then
          begin
            result := false;
            exit;
          end;
      end;
    result := true;
  end;

begin
  parms := radixnewmovingsurface_p(@action.params);

  if not parms.delay_saved then
  begin
    parms.save_delay := parms.max_delay;
    parms.delay_saved := true;
  end;

  if parms.max_delay > 0 then
  begin
    dec(parms.max_delay);
    exit;
  end;

  sec := @sectors[parms.surface];

  if not parms.sound_initialized then
  begin
    S_AmbientSound(sec.soundorg.x, sec.soundorg.y, radixsounds[parms.start_sound].name);
    parms.sound_initialized := true;
  end;

  if not parms.dir_initialized then
  begin
    parms.initial_direction := parms.direction;
    parms.dir_initialized := true;
  end;

  if parms.direction = 1 then // Up
  begin
    dest_height := parms.max_height * FRACUNIT;
    if parms.speed = 35 then
      step := 10 * FRACUNIT
    else if parms.speed > MOVINGSURFACETHRESHHOLD then
      step := (1 shl MOVINGSURFACETHRESHHOLD) * FRACUNIT
    else
      step := (1 shl parms.speed) * FRACUNIT;
  end
  else if (parms.direction = $FF) or ((parms.direction = 0) and (parms.stop_position = 2)) then // Down
  begin
    dest_height := parms.min_height * FRACUNIT;
    if parms.speed = 35 then
      step := -10 * FRACUNIT
    else if parms.speed > MOVINGSURFACETHRESHHOLD then
      step := -(1 shl MOVINGSURFACETHRESHHOLD) * FRACUNIT
    else
      step := -(1 shl parms.speed) * FRACUNIT;
  end
  else if parms.direction = 0 then
  begin
    if parms.surface_type = 1 then // floor
    begin
      parms.direction := $FF; // Down
      parms.stop_position := 1;
      dest_height := parms.min_height;
    end
    else
    begin
      parms.direction := 1; // Up
      parms.stop_position := 2;
      dest_height := parms.max_height;
    end;
    exit; // ouch
  end
  else
    exit;

  changed_direction := false;
  // JVAL: 20200403 - Avoid interpolation for fast moving sectors
  if parms.speed > MOVINGSURFACETHRESHHOLD div 2 then
    sec.renderflags := sec.renderflags or SRF_NO_INTERPOLATE;

  case parms.surface_type of
    1: // floor
      begin
        if step > 0 then
          if not playercheck(sec.floorheight + step, sec.ceilingheight) then
            exit;

        sec.floorheight := sec.floorheight + step;

        if parms.direction = 1 then // Up
          finished := sec.floorheight >= dest_height
        else // if parms.direction = -1 then // Down
          finished := sec.floorheight <= dest_height;
        if finished then
        begin
          sec.floorheight := dest_height;
          finishcheck;
          goto finish_move;
        end;
      end;
    0: // ceiling
      begin
        if step < 0 then
          if not playercheck(sec.floorheight, sec.ceilingheight + step) then
            exit;
            
        sec.ceilingheight := sec.ceilingheight + step;

        if parms.direction = 1 then // Up
          finished := sec.ceilingheight >= dest_height
        else // if parms.direction = -1 then // Down
          finished := sec.ceilingheight <= dest_height;
        if finished then
        begin
          sec.ceilingheight := dest_height;
          finishcheck;
          goto finish_move;
        end;
      end;
  end;

  P_ChangeSector(sec, true);  // JVAL: 20200313
  exit;

finish_move:
  P_ChangeSector(sec, true);  // JVAL: 20200313
  S_AmbientSound(
    sec.soundorg.x,
    sec.soundorg.y,
    radixsounds[parms.stop_sound].name);
  parms.sound_initialized := false;
  if not changed_direction then
    action.suspend := 1  // JVAL: 202003 - Disable action
  else if (parms.initial_direction = parms.direction) and (parms.stop_position in [1, 2]) then
    action.suspend := 1;
  parms.max_delay := parms.save_delay;  // JVAL: 20200405 - Restore old delay
  if parms.activate_trig <> 0 then
  begin
    radixtriggers[parms.trigger_number].suspended := 0;
    RX_RunTrigger(parms.trigger_number);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 14
type
  radixplaysound_t = packed record
    sound_number: smallint; // Values 17 - 31
    repeating: smallint;
    x_pos: LongWord;
    y_pos: LongWord;
    // RTL
    doom_x: fixed_t;
    doom_y: fixed_t;
    countdown: integer;
    calced: boolean;
  end;
  radixplaysound_p = ^radixplaysound_t;

procedure RA_PlaySound(const action: Pradixaction_t);
var
  parms: radixplaysound_p;
  cnt: integer;
begin
  parms := radixplaysound_p(@action.params);

  if parms.countdown > 0 then
  begin
    dec(parms.countdown);
    exit;
  end;

  if not parms.calced then
  begin
    parms.doom_x := RX_RadixX2Doom(parms.x_pos, parms.y_pos) * FRACUNIT;
    parms.doom_y := RX_RadixY2Doom(parms.x_pos, parms.y_pos) * FRACUNIT;
    parms.calced := true;
  end;

  S_AmbientSound(
      parms.doom_x,
      parms.doom_y,
      radixsounds[parms.sound_number].name);

  if parms.repeating = 0 then
    action.suspend := 1
  else
  begin
    cnt := S_RadixSoundDuration(parms.sound_number);
    if cnt < 0 then
      parms.countdown := 10 * TICRATE // JVAL: 10 seconds to replay sound
    else
      parms.countdown := cnt; // JVAL: 20200312 - Restart sound after it finishes 
  end;
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
      sectors[parms.sector].lightlevel := RX_LightLevel(parms.on_light_level, sectors[parms.sector].radixflags);
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
      sectors[parms.sector].lightlevel := RX_LightLevel(parms.off_light_level, sectors[parms.sector].radixflags);
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
    // RTL
    initialized: boolean;
    tics: integer;
  end;
  radixendoflevel_p = ^radixendoflevel_t;

procedure RA_EndOfLevel(const action: Pradixaction_t);
var
  parms: radixendoflevel_p;
begin
  parms := radixendoflevel_p(@action.params);

  if not parms.initialized then
  begin
    parms.tics := S_RadixSoundDuration(Ord(sfx_SndEndOfLevel)) + 1;

    S_AmbientSound(
      players[radixplayer].mo.x,
      players[radixplayer].mo.y,
      radixsounds[Ord(sfx_SndEndOfLevel)].name
    );

    parms.initialized := true;
    exit;
  end;

  if parms.tics > 0 then
  begin
    dec(parms.tics);
    exit;
  end;

  G_ExitRadixLevel(parms.return_value);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 17
type
  radixspritetriggeractivate_t = packed record
    trigger_number: integer;
    the_sprites: packed array[0..4] of integer; // JVAL: 20200310 - sprite in editor
  end;
  radixspritetriggeractivate_p = ^radixspritetriggeractivate_t;

procedure RA_SpriteTriggerActivate(const action: Pradixaction_t);
var
  parms: radixspritetriggeractivate_p;
  i: integer;
  radix_id: integer;
  think: Pthinker_t;
  mo: Pmobj_t;
begin
  parms := radixspritetriggeractivate_p(@action.params);

  for i := 0 to 4 do
  begin
    radix_id := parms.the_sprites[i];
    if radix_id >= 0 then
    begin
      think := thinkercap.next;
      while think <> @thinkercap do
      begin
        if @think._function.acp1 <> @P_MobjThinker then
        begin
          think := think.next;
          continue;
        end;

        mo := Pmobj_t(think);
        if mo.player = nil then
          if mo.spawnpoint.options or MTF_RADIXTHING <> 0 then
            if mo.spawnpoint.radix_id = radix_id then
              if mo.flags and MF_SHOOTABLE <> 0 then
                if mo.health > 0 then
                  exit;

        think := think.next;
      end;
    end;
  end;

  radixtriggers[parms.trigger_number].suspended := 0;
  RX_RunTrigger(parms.trigger_number);

  action.suspend := 1;  // JVAL: 20200411 - Disable action
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
    // RTL
    doom_x: fixed_t;
    doom_y: fixed_t;
    sndcountdown: integer;
    sndcalced: boolean;
  end;
  radixsectorbasedgravity_p = ^radixsectorbasedgravity_t;

procedure RA_SectorBasedGravity(const action: Pradixaction_t);
var
  parms: radixsectorbasedgravity_p;
  cnt: integer;
  i: integer;
  mo: Pmobj_t;
  momz: fixed_t;
begin
  parms := radixsectorbasedgravity_p(@action.params);

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
    begin
      mo := players[i].mo;
      if mo <> nil then
        if Psubsector_t(mo.subsector).sector.iSectorID = parms.sector_id then
        begin
          momz := mo.momz;
          if IsIntegerInRange(momz, -16 * FRACUNIT, 16 * FRACUNIT) then
          begin
            momz := GetIntegerInRange(momz + parms.direction * 8192 * (1 shl parms.strength), -16 * FRACUNIT, 16 * FRACUNIT);
            mo.momz := momz;
          end;
        end;
    end;

  if not parms.sndcalced then
  begin
    parms.doom_x := RX_RadixX2Doom(parms.approx_x, parms.approx_y) * FRACUNIT;
    parms.doom_y := RX_RadixY2Doom(parms.approx_x, parms.approx_y) * FRACUNIT;
    parms.sndcalced := true;
  end;

  if parms.sndcountdown > 0 then
  begin
    dec(parms.sndcountdown);
    exit;
  end;

  S_AmbientSound(
      parms.doom_x,
      parms.doom_y,
      radixsounds[Ord(sfx_SndGravityWell)].name);

  cnt := S_RadixSoundDuration(Ord(sfx_SndGravityWell));
  if cnt < 0 then
    parms.sndcountdown := 10 * TICRATE // JVAL: 10 seconds to replay sound
  else
    parms.sndcountdown := cnt; // JVAL: 20200415 - Restart sound after it finishes
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
//  RX_RunTrigger(parms.trigger);
  action.suspend := 1;  // JVAL: 202003 - Disable action
end;

const
  WALLMISSILEOFFSET = 16;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 21
type
  radixcompletemissilewall_t = packed record
    wall_number: smallint;
    //RTL
    initialized: boolean;
    mobjid: LongWord;
    linelength: integer;
    baseangle: angle_t;
    nextticfire: integer;
  end;
  radixcompletemissilewall_p = ^radixcompletemissilewall_t;

procedure RA_CompleteMissileWall(const action: Pradixaction_t);
var
  parms: radixcompletemissilewall_p;
  li: Pline_t;
  x, y, z: integer;
  xlen, zlen: integer;
  xpos, zpos: integer;
  an: angle_t;
  c, s: fixed_t;
  mo: Pmobj_t;
  target: Pmobj_t;
begin
  parms := radixcompletemissilewall_p(@action.params);

  if parms.wall_number < 0 then
    exit;

  li := @lines[parms.wall_number];

  if li.backsector <> nil then
    exit;

  if li.radixhitpoints <= 0 then  // Died
  begin
    if sides[li.sidenum[0]].midtexture = R_TextureNumForName(RX_WALL_PREFIX + '0064') then
      sides[li.sidenum[0]].midtexture := R_TextureNumForName(RX_WALL_PREFIX + '0083');
    action.suspend := 1;
    exit;
  end;

  if not parms.initialized then
  begin
    target :=
      PX_SpawnWallMissileObject(
        li.v1.x div 2 + li.v2.x div 2,
        li.v1.y div 2 + li.v2.y div 2,
        li.frontsector.ceilingheight div 2 + li.frontsector.floorheight div 2
      );
    parms.mobjid := target.key;
    parms.linelength := round(RX_LineLengthf(li));
    parms.baseangle := R_PointToAngle2(li.v1.x, li.v1.y, li.v2.x, li.v2.y) - ANG90;
    parms.nextticfire := -1;
    parms.initialized := true;
  end
  else
    target := P_FindMobjFromKey(parms.mobjid);

  if leveltime < parms.nextticfire then
    exit;

  parms.nextticfire := leveltime + TICRATE;

  xlen := (parms.linelength + 64) div 128;
  zlen := (li.frontsector.ceilingheight div FRACUNIT - li.frontsector.floorheight div FRACUNIT + 32) div 64;

  if xlen = 0 then
  begin
    x := li.v1.x div 2 + li.v2.x div 2;
    y := li.v1.y div 2 + li.v2.y div 2;
  end
  else
  begin
    xpos := Sys_Random mod xlen;
    x := round((li.v1.x div xlen) * (xpos + 0.5) + (li.v2.x div xlen) * (xlen - xpos - 0.5));
    y := round((li.v1.y div xlen) * (xpos + 0.5) + (li.v2.y div xlen) * (xlen - xpos - 0.5));
  end;

  if zlen = 0 then
    z := li.frontsector.ceilingheight div 2 + li.frontsector.floorheight div 2
  else
  begin
    zpos := Sys_Random mod zlen;
    z := round((li.frontsector.ceilingheight div zlen) * (zpos + 0.5) + (li.frontsector.floorheight div zlen) * (zlen - zpos - 0.5));
  end;

  an := parms.baseangle + _SHLW(P_Random - P_Random, 21);
  c := finecosine[an shr ANGLETOFINESHIFT];
  s := finesine[an shr ANGLETOFINESHIFT];
  x := x + WALLMISSILEOFFSET * c;
  y := y + WALLMISSILEOFFSET * s;

  mo := RX_SpawnRadixEnemyMissile(x, y, z);
  if mo = nil then
    exit;

  mo.angle := an;
  mo.target := target;
  mo.momx := FixedMul(mo.info.speed, c);
  mo.momy := FixedMul(mo.info.speed, s);
  P_CheckMissileSpawn(mo);
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

  players[radixplayer].scannerjam := parms.on_off = 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 23
type
  radixprintmessage_t = packed record
    message_id: integer; // id's 0-12
    // RTL
    nextsoundtime: integer;
    initialized: boolean;
    playcount: integer;
  end;
  radixprintmessage_p = ^radixprintmessage_t;

procedure RA_PrintMessage(const action: Pradixaction_t);
var
  parms: radixprintmessage_p;
  snd: integer;
begin
  parms := radixprintmessage_p(@action.params);

  if not parms.initialized then
  begin
    parms.nextsoundtime := -1;
    parms.initialized := true;
    parms.playcount := 0;
  end;

  if IsIntegerInRange(parms.message_id, 0, NUMRADIXMESSAGES - 1) then
    if not radixmessages[parms.message_id].autodisable or (parms.playcount = 0) then  // Avoid repeating some messages
      if RX_PlayerMessage(@players[radixplayer], parms.message_id) then
      begin
        inc(parms.playcount);
        if leveltime >= parms.nextsoundtime then
        begin
          snd := radixmessages[parms.message_id].radix_snd;
          if snd >= 0 then
            S_StartSound(players[radixplayer].messagesoundtarget, radixsounds[snd].name, true);
          parms.nextsoundtime := leveltime + S_RadixSoundDuration(snd) + 1;
        end;
      end;

  action.suspend := 1;  // JVAL: 20200306 - Disable action
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 24
type
  radixfloormissilewall_t = packed record
    wall_number: smallint;
    //RTL
    initialized: boolean;
    mobjid: LongWord;
    linelength: integer;
    baseangle: angle_t;
    nextticfire: integer;
    destheight: fixed_t;
  end;
  radixfloormissilewall_p = ^radixfloormissilewall_t;

procedure RA_FloorMissileWall(const action: Pradixaction_t);
var
  parms: radixfloormissilewall_p;
  li: Pline_t;
  x, y, z: integer;
  xlen, zlen: integer;
  xpos, zpos: integer;
  an: angle_t;
  c, s: fixed_t;
  mo: Pmobj_t;
  target: Pmobj_t;
begin
  parms := radixfloormissilewall_p(@action.params);

  if parms.wall_number < 0 then
    exit;

  li := @lines[parms.wall_number];

  if li.backsector = nil then
    exit;

  if li.radixhitpoints <= 0 then  // Died
  begin
    if sides[li.sidenum[0]].bottomtexture = R_TextureNumForName(RX_WALL_PREFIX + '0064') then
      sides[li.sidenum[0]].bottomtexture := R_TextureNumForName(RX_WALL_PREFIX + '0083');
    if sides[li.sidenum[1]].bottomtexture = R_TextureNumForName(RX_WALL_PREFIX + '0064') then
      sides[li.sidenum[1]].bottomtexture := R_TextureNumForName(RX_WALL_PREFIX + '0083');
    action.suspend := 1;
    exit;
  end;

  if not parms.initialized then
  begin
    target :=
      PX_SpawnWallMissileObject(
        li.v1.x div 2 + li.v2.x div 2,
        li.v1.y div 2 + li.v2.y div 2,
        li.frontsector.ceilingheight div 2 + li.frontsector.floorheight div 2
      );
    parms.mobjid := target.key;
    parms.linelength := round(RX_LineLengthf(li));
    parms.baseangle := R_PointToAngle2(li.v1.x, li.v1.y, li.v2.x, li.v2.y) - ANG90;
    parms.nextticfire := -1;
    parms.destheight := li.backsector.ceilingheight;
    parms.initialized := true;
  end
  else
    target := P_FindMobjFromKey(parms.mobjid);

  // JVAL: 20200413 - Raise backsector's floor
  if li.backsector.floorheight < parms.destheight then
  begin
    li.backsector.floorheight := li.backsector.floorheight + 2 * FRACUNIT;
    if li.backsector.floorheight > parms.destheight then
      li.backsector.floorheight := parms.destheight;
  end;

  if leveltime < parms.nextticfire then
    exit;

  parms.nextticfire := leveltime + TICRATE;

  xlen := (parms.linelength + 64) div 128;
  if li.frontsector.floorheight > li.backsector.floorheight then
    zlen := (li.frontsector.floorheight div FRACUNIT - li.backsector.floorheight div FRACUNIT + 32) div 64  // back side
  else
    zlen := (li.backsector.floorheight div FRACUNIT - li.frontsector.floorheight div FRACUNIT + 32) div 64; // front side

  if zlen = 0 then
    exit;
    
  if xlen = 0 then
  begin
    x := li.v1.x div 2 + li.v2.x div 2;
    y := li.v1.y div 2 + li.v2.y div 2;
  end
  else
  begin
    xpos := Sys_Random mod xlen;
    x := round((li.v1.x div xlen) * (xpos + 0.5) + (li.v2.x div xlen) * (xlen - xpos - 0.5));
    y := round((li.v1.y div xlen) * (xpos + 0.5) + (li.v2.y div xlen) * (xlen - xpos - 0.5));
  end;

  if zlen = 0 then
    z := li.frontsector.floorheight div 2 + li.backsector.floorheight div 2
  else
  begin
    zpos := Sys_Random mod zlen;
    z := round((li.frontsector.floorheight div zlen) * (zpos + 0.5) + (li.backsector.floorheight div zlen) * (zlen - zpos - 0.5));
  end;

  an := parms.baseangle + _SHLW(P_Random - P_Random, 21);
  c := finecosine[an shr ANGLETOFINESHIFT];
  s := finesine[an shr ANGLETOFINESHIFT];
  x := x + WALLMISSILEOFFSET * c;
  y := y + WALLMISSILEOFFSET * s;

  mo := RX_SpawnRadixEnemyMissile(x, y, z);
  if mo = nil then
    exit;

  mo.angle := an;
  mo.target := target;
  mo.momx := FixedMul(mo.info.speed, c);
  mo.momy := FixedMul(mo.info.speed, s);
  P_CheckMissileSpawn(mo);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 25
type
  radixceilingmissilewall_t = packed record
    wall_number: smallint;
    //RTL
    initialized: boolean;
    mobjid: LongWord;
    linelength: integer;
    baseangle: angle_t;
    nextticfire: integer;
    destheight: fixed_t;
  end;
  radixceilingmissilewall_p = ^radixceilingmissilewall_t;

procedure RA_CeilingMissileWall(const action: Pradixaction_t);
var
  parms: radixceilingmissilewall_p;
  li: Pline_t;
  x, y, z: integer;
  xlen, zlen: integer;
  xpos, zpos: integer;
  an: angle_t;
  c, s: fixed_t;
  mo: Pmobj_t;
  target: Pmobj_t;
begin
  parms := radixceilingmissilewall_p(@action.params);

  if parms.wall_number < 0 then
    exit;

  li := @lines[parms.wall_number];

  if li.backsector = nil then
    exit;

  if li.radixhitpoints <= 0 then  // Died
  begin
    if sides[li.sidenum[0]].toptexture = R_TextureNumForName(RX_WALL_PREFIX + '0064') then
      sides[li.sidenum[0]].toptexture := R_TextureNumForName(RX_WALL_PREFIX + '0083');
    if sides[li.sidenum[1]].toptexture = R_TextureNumForName(RX_WALL_PREFIX + '0064') then
      sides[li.sidenum[1]].toptexture := R_TextureNumForName(RX_WALL_PREFIX + '0083');
    action.suspend := 1;
    exit;
  end;

  if not parms.initialized then
  begin
    target :=
      PX_SpawnWallMissileObject(
        li.v1.x div 2 + li.v2.x div 2,
        li.v1.y div 2 + li.v2.y div 2,
        li.frontsector.ceilingheight div 2 + li.frontsector.floorheight div 2
      );
    parms.mobjid := target.key;
    parms.linelength := round(RX_LineLengthf(li));
    parms.baseangle := R_PointToAngle2(li.v1.x, li.v1.y, li.v2.x, li.v2.y) - ANG90;
    parms.nextticfire := -1;
    parms.destheight := li.backsector.floorheight;
    parms.initialized := true;
  end
  else
    target := P_FindMobjFromKey(parms.mobjid);

  // JVAL: 20200414 - Raise backsector's floor
  if li.backsector.ceilingheight > parms.destheight then
  begin
    li.backsector.ceilingheight := li.backsector.ceilingheight - 2 * FRACUNIT;
    if li.backsector.ceilingheight < parms.destheight then
      li.backsector.ceilingheight := parms.destheight;
  end;

  if leveltime < parms.nextticfire then
    exit;

  parms.nextticfire := leveltime + TICRATE;

  xlen := (parms.linelength + 64) div 128;
  if li.frontsector.ceilingheight > li.backsector.ceilingheight then
    zlen := (li.frontsector.ceilingheight div FRACUNIT - li.backsector.ceilingheight div FRACUNIT + 32) div 64  // front side
  else
    zlen := (li.backsector.ceilingheight div FRACUNIT - li.frontsector.ceilingheight div FRACUNIT + 32) div 64; // back side

  if zlen = 0 then
    exit;

  if xlen = 0 then
  begin
    x := li.v1.x div 2 + li.v2.x div 2;
    y := li.v1.y div 2 + li.v2.y div 2;
  end
  else
  begin
    xpos := Sys_Random mod xlen;
    x := round((li.v1.x div xlen) * (xpos + 0.5) + (li.v2.x div xlen) * (xlen - xpos - 0.5));
    y := round((li.v1.y div xlen) * (xpos + 0.5) + (li.v2.y div xlen) * (xlen - xpos - 0.5));
  end;

  if zlen = 0 then
    z := li.frontsector.ceilingheight div 2 + li.backsector.ceilingheight div 2
  else
  begin
    zpos := Sys_Random mod zlen;
    z := round((li.frontsector.ceilingheight div zlen) * (zpos + 0.5) + (li.backsector.ceilingheight div zlen) * (zlen - zpos - 0.5));
  end;

  an := parms.baseangle + _SHLW(P_Random - P_Random, 21);
  c := finecosine[an shr ANGLETOFINESHIFT];
  s := finesine[an shr ANGLETOFINESHIFT];
  x := x + WALLMISSILEOFFSET * c;
  y := y + WALLMISSILEOFFSET * s;

  mo := RX_SpawnRadixEnemyMissile(x, y, z);
  if mo = nil then
    exit;

  mo.angle := an;
  mo.target := target;
  mo.momx := FixedMul(mo.info.speed, c);
  mo.momy := FixedMul(mo.info.speed, s);
  P_CheckMissileSpawn(mo);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 26
type
  radixbigspritetrig_t = packed record
    trigger_number: integer;
    the_sprites: packed array[0..19] of integer; // Zero and negative do not count
  end;
  radixbigspritetrig_p = ^radixbigspritetrig_t;

procedure RA_BigSpriteTrig(const action: Pradixaction_t);
var
  parms: radixbigspritetrig_p;
  i: integer;
  radix_id: integer;
  think: Pthinker_t;
  mo: Pmobj_t;
begin
  parms := radixbigspritetrig_p(@action.params);

  for i := 0 to 19 do
  begin
    radix_id := parms.the_sprites[i];
    if radix_id >= 0 then
    begin
      think := thinkercap.next;
      while think <> @thinkercap do
      begin
        if @think._function.acp1 <> @P_MobjThinker then
        begin
          think := think.next;
          continue;
        end;

        mo := Pmobj_t(think);
        if mo.player = nil then
          if mo.spawnpoint.options or MTF_RADIXTHING <> 0 then
            if mo.spawnpoint.radix_id = radix_id then
              if mo.flags and MF_SHOOTABLE <> 0 then
                if mo.health > 0 then
                  exit;

        think := think.next;
      end;
    end;
  end;

  radixtriggers[parms.trigger_number].suspended := 0;
  RX_RunTrigger(parms.trigger_number);

  action.suspend := 1; // JVAL: 20200315 - Disable action
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
    // RTL
    delay_cnt: integer;
  end;
  radixmassiveexplosion_p = ^radixmassiveexplosion_t;

procedure RA_MassiveExplosion(const action: Pradixaction_t);
var
  parms: radixmassiveexplosion_p;
  i: integer;
  x, y, z: fixed_t;
  x1, y1, z1: fixed_t;
  mo: Pmobj_t;
begin
  parms := radixmassiveexplosion_p(@action.params);

  if parms.number_of_explosions <= 0 then
  begin
    action.suspend := 1;
    exit;
  end;

  if parms.delay_cnt <= 0 then
  begin
    x1 := RX_RadixX2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    y1 := RX_RadixY2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    z1 := parms.height * FRACUNIT;
    for i := 0 to parms.number_of_bitmaps_per - 1 do
    begin
      x := x1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
      y := y1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
      z := z1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
      mo := RX_SpawnRadixBigExplosion(x, y, z);
      mo.flags3_ex := mo.flags3_ex or MF3_EX_NOSOUND;
    end;
    if parms.number_of_explosions and 1 <> 0 then // JVAL: 20200506 - Do not bottleneck sound system
      S_AmbientSound(x1, y1, 'radix/SndExplode');
    parms.x_coord := parms.x_coord + parms.delta_x;
    parms.y_coord := parms.y_coord + parms.delta_y;
    parms.delay_cnt := parms.delay_length;
    dec(parms.number_of_explosions);
  end
  else
    dec(parms.delay_cnt);
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
  i: integer;
  w: integer;
begin
  parms := radixwalldeadcheck_p(@action.params);

  for i := 0 to 4 do
  begin
    w := parms.the_walls[i];
    if w >= 0 then
      if lines[w].radixhitpoints > 0 then
        exit;
  end;

  radixtriggers[parms.trigger].suspended := 0;
  RX_RunTrigger(parms.trigger);

  action.suspend := 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 29
type
  radixsecondaryobjective_t = packed record
    return_value: integer;
    // RTL
    nextsoundtime: integer;
    initialized: boolean;
  end;
  radixsecondaryobjective_p = ^radixsecondaryobjective_t;

procedure RA_SecondaryObjective(const action: Pradixaction_t);
const
  MSG_SECONDARY = 12;
var
  parms: radixsecondaryobjective_p;
  snd: integer;
begin
  parms := radixsecondaryobjective_p(@action.params);

  if not parms.initialized then
  begin
    parms.nextsoundtime := -1;
    parms.initialized := true;
  end;

  players[radixplayer].secondaryobjective := true;
  if RX_PlayerMessage(@players[radixplayer], MSG_SECONDARY) then
    if leveltime >= parms.nextsoundtime then
    begin
      snd := radixmessages[MSG_SECONDARY].radix_snd;
      if snd >= 0 then
        S_StartSound(players[radixplayer].messagesoundtarget, radixsounds[snd].name, true);
      parms.nextsoundtime := leveltime + S_RadixSoundDuration(snd) + 1;
    end;

  action.suspend := 1; // Disable action;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type 30
type
  radixseekcompletemissilewall_t = packed record
    wall_number: smallint;
    //RTL
    initialized: boolean;
    mobjid: LongWord;
    linelength: integer;
    baseangle: angle_t;
    nextticfire: integer;
  end;
  radixseekcompletemissilewall_p = ^radixseekcompletemissilewall_t;

procedure RA_SeekCompleteMissileWall(const action: Pradixaction_t);
var
  parms: radixseekcompletemissilewall_p;
  li: Pline_t;
  x, y, z: integer;
  xlen, zlen: integer;
  xpos, zpos: integer;
  an: angle_t;
  c, s: fixed_t;
  mo: Pmobj_t;
  target: Pmobj_t;
begin
  parms := radixseekcompletemissilewall_p(@action.params);

  if parms.wall_number < 0 then
    exit;

  li := @lines[parms.wall_number];

  if li.backsector <> nil then
    exit;

  if li.radixhitpoints <= 0 then  // Died
  begin
    if sides[li.sidenum[0]].midtexture = R_TextureNumForName(RX_WALL_PREFIX + '0064') then
      sides[li.sidenum[0]].midtexture := R_TextureNumForName(RX_WALL_PREFIX + '0083');
    action.suspend := 1;
    exit;
  end;

  if not parms.initialized then
  begin
    target :=
      PX_SpawnWallMissileObject(
        li.v1.x div 2 + li.v2.x div 2,
        li.v1.y div 2 + li.v2.y div 2,
        li.frontsector.ceilingheight div 2 + li.frontsector.floorheight div 2
      );
    parms.mobjid := target.key;
    parms.linelength := round(RX_LineLengthf(li));
    parms.baseangle := R_PointToAngle2(li.v1.x, li.v1.y, li.v2.x, li.v2.y) - ANG90;
    parms.nextticfire := -1;
    parms.initialized := true;
  end
  else
    target := P_FindMobjFromKey(parms.mobjid);

  if leveltime < parms.nextticfire then
    exit;

  parms.nextticfire := leveltime + TICRATE;

  xlen := (parms.linelength + 64) div 128;
  zlen := (li.frontsector.ceilingheight div FRACUNIT - li.frontsector.floorheight div FRACUNIT + 32) div 64;

  if xlen = 0 then
  begin
    x := li.v1.x div 2 + li.v2.x div 2;
    y := li.v1.y div 2 + li.v2.y div 2;
  end
  else
  begin
    xpos := Sys_Random mod xlen;
    x := round((li.v1.x div xlen) * (xpos + 0.5) + (li.v2.x div xlen) * (xlen - xpos - 0.5));
    y := round((li.v1.y div xlen) * (xpos + 0.5) + (li.v2.y div xlen) * (xlen - xpos - 0.5));
  end;

  if zlen = 0 then
    z := li.frontsector.ceilingheight div 2 + li.frontsector.floorheight div 2
  else
  begin
    zpos := Sys_Random mod zlen;
    z := round((li.frontsector.ceilingheight div zlen) * (zpos + 0.5) + (li.frontsector.floorheight div zlen) * (zlen - zpos - 0.5));
  end;

  an := parms.baseangle + _SHLW(P_Random - P_Random, 21);
  c := finecosine[an shr ANGLETOFINESHIFT];
  s := finesine[an shr ANGLETOFINESHIFT];
  x := x + WALLMISSILEOFFSET * c;
  y := y + WALLMISSILEOFFSET * s;

  mo := RX_SpawnRadixEnemySeekerMissile(x, y, z);
  if mo = nil then
    exit;

  mo.angle := an;
  mo.target := target;
  mo.momx := FixedMul(mo.info.speed, c);
  mo.momy := FixedMul(mo.info.speed, s);
  P_CheckMissileSpawn(mo);
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
  sec0, sec1, sec2, sec3: integer;
begin
  parms := radixspritelightmovement_p(@action.params);

  if parms.tick = 0 then
    parms.tick := 4 * parms.delay;

  dec(parms.tick);

  sec0 := parms.the_sectors[0];
  sec1 := parms.the_sectors[1];
  sec2 := parms.the_sectors[2];
  sec3 := parms.the_sectors[3];
  case parms.tick div parms.delay of
    0:
      begin
        if sec0 >= 0 then
          sectors[sec0].lightlevel := RX_LightLevel(parms.on_level, sectors[sec0].radixflags);
        if sec1 >= 0 then
          sectors[sec1].lightlevel := RX_LightLevel(parms.off_level, sectors[sec1].radixflags);
        if sec2 >= 0 then
          sectors[sec2].lightlevel := RX_LightLevel(parms.off_level, sectors[sec2].radixflags);
        if sec3 >= 0 then
          sectors[sec3].lightlevel := RX_LightLevel(parms.off_level, sectors[sec3].radixflags);
      end;
    1:
      begin
        if sec0 >= 0 then
          sectors[sec0].lightlevel := RX_LightLevel(parms.off_level, sectors[sec0].radixflags);
        if sec1 >= 0 then
          sectors[sec1].lightlevel := RX_LightLevel(parms.on_level, sectors[sec1].radixflags);
        if sec2 >= 0 then
          sectors[sec2].lightlevel := RX_LightLevel(parms.off_level, sectors[sec2].radixflags);
        if sec3 >= 0 then
          sectors[sec3].lightlevel := RX_LightLevel(parms.off_level, sectors[sec3].radixflags);
      end;
    2:
      begin
        if sec0 >= 0 then
          sectors[sec0].lightlevel := RX_LightLevel(parms.off_level, sectors[sec0].radixflags);
        if sec1 >= 0 then
          sectors[sec1].lightlevel := RX_LightLevel(parms.off_level, sectors[sec1].radixflags);
        if sec2 >= 0 then
          sectors[sec2].lightlevel := RX_LightLevel(parms.on_level, sectors[sec2].radixflags);
        if sec3 >= 0 then
          sectors[sec3].lightlevel := RX_LightLevel(parms.off_level, sectors[sec3].radixflags);
      end;
    3:
      begin
        if sec0 >= 0 then
          sectors[sec0].lightlevel := RX_LightLevel(parms.off_level, sectors[sec0].radixflags);
        if sec1 >= 0 then
          sectors[sec1].lightlevel := RX_LightLevel(parms.off_level, sectors[sec1].radixflags);
        if sec2 >= 0 then
          sectors[sec2].lightlevel := RX_LightLevel(parms.off_level, sectors[sec2].radixflags);
        if sec3 >= 0 then
          sectors[sec3].lightlevel := RX_LightLevel(parms.on_level, sectors[sec3].radixflags);
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
    // RTL
    curlevel: integer;
  end;
  radixmultlightoscilate_p = ^radixmultlightoscilate_t;

procedure RA_MultLightOscilate(const action: Pradixaction_t);
var
  parms: radixmultlightoscilate_p;
  i: integer;
  secid: integer;
begin
  parms := radixmultlightoscilate_p(@action.params);

  if parms.direction = 0 then
  begin
    inc(parms.curlevel);
    parms.curlevel := GetIntegerInRange(parms.curlevel, parms.min_light, parms.max_light);
    if parms.curlevel = parms.max_light then
      parms.direction := 1;
  end
  else
  begin
    dec(parms.curlevel);
    parms.curlevel := GetIntegerInRange(parms.curlevel, parms.min_light, parms.max_light);
    if parms.curlevel = parms.min_light then
      parms.direction := 0;
  end;

  for i := 0 to 29 do
  begin
    secid := parms.the_sectors[i];
    if secid >= 0 then
      sectors[secid].lightlevel := RX_LightLevel(parms.curlevel, sectors[secid].radixflags);
  end;
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
    // RTL
    on_off: byte;
    off_countdown: integer;
    on_countdown: integer;
  end;
  radixmultrandlightsflicker_p = ^radixmultrandlightsflicker_t;

procedure RA_MultRandLightsFlicker(const action: Pradixaction_t);
var
  parms: radixmultrandlightsflicker_p;
  i: integer;
begin
  parms := radixmultrandlightsflicker_p(@action.params);

  if parms.on_off = 0 then
  begin
    if parms.off_countdown <= 0 then
    begin
      for i := 0 to 4 do
      begin
        if parms.info[i].sector < 0 then
          Continue;
        sectors[parms.info[i].sector].lightlevel := RX_LightLevel(parms.info[i].on_light_level, sectors[parms.info[i].sector].radixflags);
      end;
      parms.on_countdown := P_RandomInRange(parms.on_min_delay, parms.on_max_delay);
      parms.on_off := 1;
    end
    else
      dec(parms.off_countdown);
  end
  else
  begin
    if parms.on_countdown <= 0 then
    begin
      for i := 0 to 4 do
      begin
        if parms.info[i].sector < 0 then
          Continue;
        sectors[parms.info[i].sector].lightlevel := RX_LightLevel(parms.info[i].off_light_level, sectors[parms.info[i].sector].radixflags);
      end;
      parms.off_countdown := P_RandomInRange(parms.off_min_delay, parms.off_max_delay);
      parms.on_off := 0;
    end
    else
      dec(parms.on_countdown);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 34
type
  radixkillratio_t = packed record
    trigger_number: integer;
    percentage: smallint;
  end;
  radixkillratio_p = ^radixkillratio_t;

procedure RA_KillRatio(const action: Pradixaction_t);
var
  parms: radixkillratio_p;
  runtrigger: boolean;
  mo: Pmobj_t;
  think: Pthinker_t;
  living: integer;
begin
  parms := radixkillratio_p(@action.params);

  runtrigger := false;
  if (totalradixkills = 0) or (totalkills = 0) then
    runtrigger := true
  else if players[radixplayer].killcount >= totalkills then
    runtrigger := true
  else if (players[radixplayer].killcount * 100) div totalkills >= parms.percentage then
    runtrigger := true
  else if leveltime and 31 = 0 then
  begin
    // JVAL: 20200429 - To compensate for dead enemies that the player didn't kill (count living radix map enemies)
    living := 0;
    think := thinkercap.next;
    while think <> @thinkercap do
    begin
      if @think._function.acp1 <> @P_MobjThinker then
      begin
        think := think.next;
        continue;
      end;

      mo := Pmobj_t(think);

      if (mo.flags and MF_COUNTKILL = 0) or (mo.health <= 0) or (mo.player <> nil) then
      begin // Not a valid monster
        think := think.next;
        continue;
      end;

      if mo.spawnpoint.options and MTF_RADIXTHING <> 0 then
        inc(living);

      think := think.next;
    end;

    if totalradixkills - living * 100 div totalkills >= parms.percentage then
      runtrigger := true;
  end;

  if runtrigger then
  begin
    radixtriggers[parms.trigger_number].suspended := 0;
    RX_RunTrigger(parms.trigger_number);

    action.suspend := 1; // JVAL: 20200414 - Disable action
  end;
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
    // RTL
    delay_cnt: integer;
  end;
  radixhurtplayerexplosion_p = ^radixhurtplayerexplosion_t;

procedure RA_HurtPlayerExplosion(const action: Pradixaction_t);
var
  parms: radixhurtplayerexplosion_p;
  x, y, z: fixed_t;
  x1, y1, z1: fixed_t;
  mo: Pmobj_t;
  i: integer;
  dist, maxdist: fixed_t;
  damage: integer;
  max_radius: integer;
begin
  parms := radixhurtplayerexplosion_p(@action.params);

  if parms.number_of_explosions <= 0 then
  begin
    action.suspend := 1;
    exit;
  end;

  if parms.delay_cnt <= 0 then
  begin
    x1 := RX_RadixX2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    y1 := RX_RadixY2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    z1 := parms.height * FRACUNIT;
    x := x1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
    y := y1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
    z := z1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
    RX_SpawnRadixBigExplosion(x, y, z);
    parms.x_coord := parms.x_coord + parms.delta_x;
    parms.y_coord := parms.y_coord + parms.delta_y;
    parms.delay_cnt := parms.delay_length;
    dec(parms.number_of_explosions);

    max_radius := parms.radious_one_third * 3;
    for i := 0 to MAXPLAYERS - 1 do
      if playeringame[i] then
      begin
        mo := players[i].mo;
        if mo <> nil then
        begin
          maxdist := 0;
          dist := abs(x - mo.x);
          if dist > maxdist then
            maxdist := dist;
          dist := abs(y - mo.y);
          if dist > maxdist then
            maxdist := dist;
          dist := abs(z - mo.z);
          if dist > maxdist then
            maxdist := dist;
          maxdist := maxdist div FRACUNIT;
          if maxdist < max_radius then
          begin
            damage := (parms.hit_points_at_center * PLAYERSPAWNSHIELD div 300) * (max_radius - maxdist) div max_radius;
            P_DamageMobj(mo, nil, nil, damage);
          end;
        end;
      end;
  end
  else
    dec(parms.delay_cnt);
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

  sectors[parms.sector_id].lightlevel := RX_LightLevel(parms.new_light_level, sectors[parms.sector_id].radixflags);

  action.suspend := 1;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 37
type
  radix6lightmovement_t = packed record
    on_level: smallint; // 0-63
    off_level: smallint;  // 0-63
    delay: smallint; // 1-20 in radix.dat v2
    the_sectors: packed array[0..11] of  smallint; // -1 -> no sector
    // RTL
    currid: integer;
    countdown: integer;
    initialized: boolean;
  end;
  radix6lightmovement_p = ^radix6lightmovement_t;

procedure RA_SixLightMovement(const action: Pradixaction_t);
var
  parms: radix6lightmovement_p;
  i: integer;
  secid: integer;
begin
  parms := radix6lightmovement_p(@action.params);

  if not parms.initialized then
  begin
    parms.currid := -1;
    parms.initialized := true;
  end;

  if parms.countdown > 0 then
  begin
    dec(parms.countdown);
    exit;
  end;

  inc(parms.currid);
  if parms.currid = 12 then
    parms.currid := 0
  else if parms.the_sectors[parms.currid] = -1 then
    parms.currid := 0;

  for i := 0 to 11 do
  begin
    secid := parms.the_sectors[i];
    if secid >= 0 then
    begin
      if i = parms.currid then
        sectors[secid].lightlevel := RX_LightLevel(parms.on_level, sectors[secid].radixflags)
      else
        sectors[secid].lightlevel := RX_LightLevel(parms.off_level, sectors[secid].radixflags)
    end;
  end;
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
  i: integer;
  sec: integer;
begin
  parms := radixsurfacepowerup_p(@action.params);

  if leveltime and 7 = 0 then
    for i := 0 to MAXPLAYERS - 1 do
      if playeringame[i] then
      begin
        sec := Psubsector_t(players[i].mo.subsector).sector.iSectorID;
        if sec = parms.sector_id then
        begin
          players[i].armorpoints := players[i].armorpoints + parms.armour_inc;
          players[i].armorpoints := GetIntegerInRange(players[i].armorpoints, 0, PLAYERMAXARMOR);
          players[i].health := players[i].health + parms.shield_inc;
          players[i].health := GetIntegerInRange(players[i].health, 0, PLAYERMAXSHIELD);
          players[i].energy := players[i].energy + parms.energy_inc;
          players[i].energy := GetIntegerInRange(players[i].energy, 0, PLAYERMAXENERGY);
        end;
      end;
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
  i: integer;
  secid: integer;
begin
  parms := radixsecretsprite_p(@action.params);

  for i := 0 to 14 do
  begin
    secid := parms.the_sectors[i];
    if secid >= 0 then
      if sectors[secid].special and SECRET_MASK = 0 then
      begin
        sectors[secid].special := sectors[secid].special or SECRET_MASK; // JVAL: 20200311 -> Use BOOM generalized type
        inc(totalsecret);
      end;
  end;

  action.suspend := 1;
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
    // RTL
    delay_cnt: integer;
  end;
  radixvertexplosion_p = ^radixvertexplosion_t;

procedure RA_VertExplosion(const action: Pradixaction_t);
var
  parms: radixvertexplosion_p;
  i: integer;
  x, y, z: fixed_t;
  x1, y1, z1: fixed_t;
  mo: Pmobj_t;
begin
  parms := radixvertexplosion_p(@action.params);

  if parms.number_of_explosions <= 0 then
  begin
    action.suspend := 1;
    exit;
  end;

  if parms.delay_cnt <= 0 then
  begin
    x1 := RX_RadixX2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    y1 := RX_RadixY2Doom(parms.x_coord, parms.y_coord) * FRACUNIT;
    z1 := parms.height * FRACUNIT;
    for i := 0 to parms.number_of_bitmaps_per - 1 do
    begin
      x := x1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
      y := y1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
      z := z1 + (2 * (P_Random - P_Random) * parms.radious_one_third) * (FRACUNIT div 256);
      mo := RX_SpawnRadixBigExplosion(x, y, z);
      mo.flags3_ex := mo.flags3_ex or MF3_EX_NOSOUND;
    end;
    if parms.number_of_explosions and 1 <> 0 then // JVAL: 20200506 - Do not bottleneck sound system
      S_AmbientSound(x1, y1, 'radix/SndExplode');
    parms.x_coord := parms.x_coord + parms.delta_x;
    parms.y_coord := parms.y_coord + parms.delta_y;
    parms.height := parms.height + parms.delta_height;
    parms.delay_cnt := parms.delay_length;
    dec(parms.number_of_explosions);
  end
  else
    dec(parms.delay_cnt);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 42
type
  radixchangeflooroffsets_t = packed record
    sector: smallint;
    x_offs: smallint;
    y_offs: smallint;
  end;
  radixchangeflooroffsets_p = ^radixchangeflooroffsets_t;

procedure RA_ChangeFloorOffsets(const action: Pradixaction_t);
var
  parms: radixchangeflooroffsets_p;
  sec: Psector_t;
begin
  parms := radixchangeflooroffsets_p(@action.params);

  if parms.sector < 0 then
    exit;

  sec := @sectors[parms.sector];
  sec.floor_xoffs := sec.floor_xoffs + parms.x_offs * FRACUNIT;
  sec.floor_yoffs := sec.floor_yoffs + parms.y_offs * FRACUNIT;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite type = 43
type
  radixmassivelightmovement_t = packed record
    on_light_level: smallint;
    off_light_level: smallint;
    speed: smallint;
    the_sectors: packed array[0..40] of smallint;  // Sector can be -1
    //RTL
    currsectoridx: integer;
    countdown: integer;
  end;
  radixmassivelightmovement_p = ^radixmassivelightmovement_t;

procedure RA_MassiveLightMovement(const action: Pradixaction_t);
var
  parms: radixmassivelightmovement_p;
  i: integer;
  secid: integer;
begin
  parms := radixmassivelightmovement_p(@action.params);

  if parms.countdown <= 0 then
    parms.countdown := parms.speed;

  dec(parms.countdown);
  if parms.countdown <= 0 then
  begin
    for i := 0 to 40 do
    begin
      secid := parms.the_sectors[i];
      if secid >= 0 then
      begin
        if i = parms.currsectoridx then
          sectors[secid].lightlevel := RX_LightLevel(parms.on_light_level, sectors[secid].radixflags)
        else
          sectors[secid].lightlevel := RX_LightLevel(parms.off_light_level, sectors[secid].radixflags);
      end;
    end;
    inc(parms.currsectoridx);
    if parms.the_sectors[parms.currsectoridx] < 0 then
      parms.currsectoridx := 0;
  end;
end;

end.

