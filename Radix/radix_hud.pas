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
// DESCRIPTION:
//  HUD drawing
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_hud;

interface

procedure RX_InitRadixHud;

procedure RX_ShutDownRadixHud;

procedure RX_HudDrawer;

implementation

uses
  d_delphi,
  doomdef,
  am_map,
  d_net,
  d_player,
  g_game,
  mt_utils,
  mn_font,
  m_fixed,
  tables,
  p_local,
  p_maputl,
  p_mobj_h,
  p_setup,
  p_tick,
  p_user,
  r_defs,
  r_main,
  r_data,
  v_data,
  v_video,
  w_wad,
  z_zone;

const
  STATUSBAR_HEIGHT = 41;

type
  speedindicatorcolumn_t = packed array[0..6] of byte;
  Pspeedindicatorcolumn_t = ^speedindicatorcolumn_t;

var
  hud_speed_factor: float;
  radar_list: TDNumberList;
  cockpitspeed: speedindicatorcolumn_t;
  statusbarspeed: speedindicatorcolumn_t;
  cockpit: Ppatch_t;
  statusbarimage: Ppatch_t;
  weaponimages: array[0..6] of Ppatch_t;
  WeaponNumOn: array[0..6] of Ppatch_t;
  WeaponNumOff: array[0..6] of Ppatch_t;
  WeaponNumUse: array[0..6] of Ppatch_t;
  treatimages: array[boolean] of Ppatch_t;
  ArmourBar: Ppatch_t;
  ShieldBar: Ppatch_t;
  EnergyBar: Ppatch_t;
  hud_player: Pplayer_t;

procedure RX_InitRadixHud;
var
  i: integer;
  stmp: string;
begin
  hud_speed_factor := 15 / sqrt(2 * sqr(MAXMOVETHRESHOLD / FRACUNIT));
  radar_list := TDNumberList.Create;
  cockpitspeed[0] := aprox_black;
  cockpitspeed[1] := aprox_black;
  cockpitspeed[2] := aprox_black;
  cockpitspeed[3] := aprox_black;
  cockpitspeed[4] := aprox_black;
  cockpitspeed[5] := aprox_black;
  cockpitspeed[6] := aprox_black;
  statusbarspeed[0] := 244;
  statusbarspeed[1] := 241;
  statusbarspeed[2] := 236;
  statusbarspeed[3] := 239;
  statusbarspeed[4] := 242;
  statusbarspeed[5] := 244;
  statusbarspeed[6] := 247;
  cockpit := W_CacheLumpName('COCKPIT', PU_STATIC);
  statusbarimage := W_CacheLumpName('StatusBarImage', PU_STATIC);
  for i := 0 to 6 do
  begin
    sprintf(stmp, 'Weapon%dImage', [i + 1]);
    weaponimages[i] := W_CacheLumpName(stmp, PU_STATIC);
    sprintf(stmp, 'WeaponNumOn%d', [i + 1]);
    WeaponNumOn[i] := W_CacheLumpName(stmp, PU_STATIC);
    sprintf(stmp, 'WeaponNumOff%d', [i + 1]);
    WeaponNumOff[i] := W_CacheLumpName(stmp, PU_STATIC);
    sprintf(stmp, 'WeaponNumUse%d', [i + 1]);
    WeaponNumUse[i] := W_CacheLumpName(stmp, PU_STATIC);
  end;
  treatimages[true] := W_CacheLumpName('ThreatOnMap', PU_STATIC);
  treatimages[false] := W_CacheLumpName('ThreatOffMap', PU_STATIC);
  ArmourBar := W_CacheLumpName('ArmourBar', PU_STATIC);
  ShieldBar := W_CacheLumpName('ShieldBar', PU_STATIC);
  EnergyBar := W_CacheLumpName('EnergyBar', PU_STATIC);
end;

procedure RX_ShutDownRadixHud;
begin
  radar_list.Free;
end;

procedure RX_HudDrawTime(const x, y: integer);
var
  secs: integer;
begin
  if leveltime <= 99 * 60 + 59 then
  begin
    secs := leveltime div TICRATE;
    M_WriteSmallText(x, y, IntToStrzFill(2, secs div 60) + ':', SCN_HUD);
    M_WriteSmallText(x + 14, y, IntToStrzFill(2, secs mod 60), SCN_HUD);
  end
  else
    M_WriteSmallText(x, y, 'SUCKS', SCN_HUD); // JVAL 20200316 - SUCKS easter egg
end;

procedure RX_HudDrawSpeedIndicator(const x, y: integer; const column: Pspeedindicatorcolumn_t; const up: boolean);
var
  speed: float;
  cnt: integer;
  dest: PByte;
  pitch: integer;
  xpos: integer;
  xadd: integer;
begin
  speed := sqrt(sqr(hud_player.mo.momx / FRACUNIT) + sqr(hud_player.mo.momy / FRACUNIT) + sqr(hud_player.mo.momz / FRACUNIT));

  cnt := GetIntegerInRange(15 - round(speed * hud_speed_factor), 0, 15);
  if cnt = 0 then
    exit;

  xpos := x;
  if up then
  begin
    xadd := 2;
    cnt := 15 - cnt;
  end
  else
    xadd := -2;
  while cnt > 0 do
  begin
    pitch := V_GetScreenWidth(SCN_HUD);
    dest := @screens[SCN_HUD][pitch * y + xpos];
    dest^ := column[0];
    inc(dest, pitch);
    dest^ := column[1];
    inc(dest, pitch);
    dest^ := column[2];
    inc(dest, pitch);
    dest^ := column[3];
    inc(dest, pitch);
    dest^ := column[4];
    inc(dest, pitch);
    dest^ := column[5];
    inc(dest, pitch);
    dest^ := column[6];
    xpos := xpos + xadd;
    dec(cnt);
  end;
end;

function PIT_AddRadarThing(thing: Pmobj_t): boolean;
begin
  if thing.flags and MF_COUNTKILL <> 0 then
    radar_list.Add(integer(thing));
  result := true;
end;

procedure RX_DrawRadar(const x, y: integer; const range: integer);
const
  RADAR_SHIFT_BITS = 8;
  RADAR_SHIFT_UNIT = 1 shl RADAR_SHIFT_BITS;
  RADAR_RANGE_FACTOR = 64 * (1 shl (FRACBITS - RADAR_SHIFT_BITS));
var
  r: fixed_t;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  i: integer;
  mo: Pmobj_t;
  px, py: integer;
  xpos, ypos: integer;
  pitch: integer;
  sqdist: integer;
  maxsqdist: integer;
  tmp: fixed_t;
  an: angle_t;
  asin, acos: fixed_t;
begin
  r := range * 64 * FRACUNIT;
  xl := MapBlockInt(hud_player.mo.x - r - bmaporgx);
  xh := MapBlockInt(hud_player.mo.x + r - bmaporgx);
  yl := MapBlockInt(hud_player.mo.y - r - bmaporgy);
  yh := MapBlockInt(hud_player.mo.y + r - bmaporgy);

  radar_list.FastClear;
  for bx := xl to xh do
    for by := yl to yh do
      P_BlockThingsIterator(bx, by, PIT_AddRadarThing);

  pitch := V_GetScreenWidth(SCN_HUD);
  screens[SCN_HUD][pitch * y + x] := aprox_blue;

  an := (ANG90 - hud_player.mo.angle) div FRACUNIT;
  asin := fixedsine[an];
  acos := fixedcosine[an];

  px := hud_player.mo.x div RADAR_SHIFT_UNIT;
  py := hud_player.mo.y div RADAR_SHIFT_UNIT;
  maxsqdist := range * range;
  for i := 0 to radar_list.Count - 1 do
  begin
    mo := Pmobj_t(radar_list.Numbers[i]);
    xpos := (px - mo.x div RADAR_SHIFT_UNIT);
    if xpos < 0 then
      xpos := xpos - RADAR_RANGE_FACTOR div 2
    else
      xpos := xpos + RADAR_RANGE_FACTOR div 2;
    xpos := xpos div RADAR_RANGE_FACTOR;
    ypos := (py - mo.y div RADAR_SHIFT_UNIT);
    if ypos < 0 then
      ypos := ypos - RADAR_RANGE_FACTOR div 2
    else
      ypos := ypos + RADAR_RANGE_FACTOR div 2;
    ypos := ypos div RADAR_RANGE_FACTOR;
    sqdist := xpos * xpos + ypos * ypos;
    if sqdist <= maxsqdist then
    begin
      tmp := FixedMul(ypos, asin) - FixedMul(xpos, acos);
      ypos := FixedMul(xpos, asin) + FixedMul(ypos, acos);
      xpos := x + tmp;
      ypos := y + ypos;
      screens[SCN_HUD][pitch * ypos + xpos] := aprox_green;
    end;
  end;
end;

procedure RX_HudDrawBar(const x, y: integer; const bar: Ppatch_t; const pct: integer);
var
  i, j: integer;
  xx: integer;
  dest: PByte;
  b: byte;
  pitch: integer;
begin
  if pct <= 0 then
    exit;

  pitch := V_GetScreenWidth(SCN_HUD);
  b := screens[SCN_HUD][pitch * y + x]; // JVAL: 20200316 - Keep background color
  V_DrawPatch(x, y, SCN_HUD, bar, false);

  if pct >= 100 then
    exit;

  // Fill with background color:
  xx := bar.width * pct div 100;

  for j := y to y + bar.height - 1 do
  begin
    dest := @screens[SCN_HUD][j * pitch + x + xx];
    for i := xx to bar.width - 1 do
    begin
      dest^ := b;
      inc(dest);
    end;
  end;
end;

procedure RX_HudDrawerStatusbar;
var
  p: Ppatch_t;
  i: integer;
  stmp: string;
begin
  // Draw statusbar
  V_DrawPatch(0, 200 - STATUSBAR_HEIGHT, SCN_HUD, statusbarimage, false);

  // Draw ready weapon
  case Ord(hud_player.readyweapon) of
    0: p := weaponimages[0];
    1: p := weaponimages[1];
    2: p := weaponimages[2];
    3: p := weaponimages[3];
    4: p := weaponimages[4];
    5: p := weaponimages[5];
  else
    p := weaponimages[6];
  end;
  V_DrawPatch(5, 200 - STATUSBAR_HEIGHT + 4, SCN_HUD, p, false);

  // Draw weapon indicators
  for i := 0 to 6 do
  begin
    if Ord(hud_player.readyweapon) = i then
      p := WeaponNumUse[i]
    else if hud_player.weaponowned[i] <> 0 then
      p := WeaponNumOn[i]
    else
      p := WeaponNumOff[i];
    V_DrawPatch(6 + i * 8, 200 - STATUSBAR_HEIGHT + 31, SCN_HUD, p, false);
  end;

  // Draw kills
  if hud_player.killcount > 998 then
    stmp := '999'
  else
    stmp := IntToStrzFill(3, hud_player.killcount);
  M_WriteSmallText(204, 200 - STATUSBAR_HEIGHT + 30, stmp, SCN_HUD);

  if totalkills > 998 then
    stmp := '999'
  else
    stmp := IntToStrzFill(3, totalkills);
  M_WriteSmallText(227, 200 - STATUSBAR_HEIGHT + 30, stmp, SCN_HUD);

  // Draw threat indicator
  V_DrawPatch(290, 200 - STATUSBAR_HEIGHT + 16, SCN_HUD, treatimages[hud_player.threat], false);

  // Draw armor, shield and energy bars
  RX_HudDrawBar(189, 200 - STATUSBAR_HEIGHT + 7, ArmourBar, hud_player.armorpoints);
  RX_HudDrawBar(189, 200 - STATUSBAR_HEIGHT + 14, ShieldBar, hud_player.shield);
  RX_HudDrawBar(189, 200 - STATUSBAR_HEIGHT + 21, EnergyBar, hud_player.energy);

  // Draw time
  RX_HudDrawTime(93, 200 - STATUSBAR_HEIGHT + 30);

  // Draw speed indicator
  RX_HudDrawSpeedIndicator(128, 200 - STATUSBAR_HEIGHT + 30, @statusbarspeed, true);

  // Draw radar
  RX_DrawRadar(269, 200 - STATUSBAR_HEIGHT + 19, 12);
end;

procedure RX_HudDrawerCockpit;
var
  p: Ppatch_t;
  i: integer;
  stmp: string;
begin
  // Draw cockpit
  V_DrawPatch(0, 0, SCN_HUD, cockpit, false);

  // Draw ready weapon
  case Ord(hud_player.readyweapon) of
    0: p := weaponimages[0];
    1: p := weaponimages[1];
    2: p := weaponimages[2];
    3: p := weaponimages[3];
    4: p := weaponimages[4];
    5: p := weaponimages[5];
  else
    p := weaponimages[6];
  end;
  V_DrawPatch(23, 142, SCN_HUD, p, false);

  // Draw weapon indicators
  for i := 0 to 6 do
  begin
    if Ord(hud_player.readyweapon) = i then
      p := WeaponNumUse[i]
    else if hud_player.weaponowned[i] <> 0 then
      p := WeaponNumOn[i]
    else
      continue; // Already in cockpit patch
    V_DrawPatchStencil(26 + i * 8, 162, SCN_HUD, p, false, 0);
  end;

  // Draw kills
  if hud_player.killcount > 998 then
    stmp := '999'
  else
    stmp := IntToStrzFill(3, hud_player.killcount);
  M_WriteSmallText(145, 141, stmp, SCN_HUD);

  if totalkills > 998 then
    stmp := '999'
  else
    stmp := IntToStrzFill(3, totalkills);
  M_WriteSmallText(168, 141, stmp, SCN_HUD);

  // Draw threat indicator
  V_DrawPatch(147, 23, SCN_HUD, treatimages[hud_player.threat], false);

  // Draw armor, shield and energy bars
  RX_HudDrawBar(202, 156, ArmourBar, hud_player.armorpoints);
  RX_HudDrawBar(202, 171, ShieldBar, hud_player.shield);
  RX_HudDrawBar(233, 186, EnergyBar, hud_player.energy);

  // Draw time
  RX_HudDrawTime(107, 183);

  // Draw speed indicator
  RX_HudDrawSpeedIndicator(136, 148, @cockpitspeed, false);

  // Draw radar
  RX_DrawRadar(163, 171, 15);
end;

procedure RX_HudDrawer;
begin
  if (screenblocks > 11) and (amstate <> am_only) then
    exit;

  if firstinterpolation then
  begin
    hud_player := @players[consoleplayer];

    MT_ZeroMemory(screens[SCN_HUD], 320 * 200);

    if (screenblocks = 11) and (amstate <> am_only) then
      RX_HudDrawerCockpit
    else
      RX_HudDrawerStatusbar;
  end;
  
  V_CopyRectTransparent(0, 0, SCN_HUD, 320, 200, 0, 0, SCN_FG, true);
end;

end.

