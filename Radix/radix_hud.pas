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

procedure RX_HudDrawer;

implementation

uses
  d_delphi,
  am_map,
  d_player,
  g_game,
  mt_utils,
  r_defs,
  r_main,
  v_data,
  v_video,
  w_wad,
  z_zone;

const
  STATUSBAR_HEIGHT = 41;

var
  cockpit: Ppatch_t;
  statusbarimage: Ppatch_t;
  weaponimages: array[0..6] of Ppatch_t;
  WeaponNumOn: array[0..6] of Ppatch_t;
  WeaponNumOff: array[0..6] of Ppatch_t;
  WeaponNumUse: array[0..6] of Ppatch_t;
  treatimages: array[boolean] of Ppatch_t;
  hud_player: Pplayer_t;

procedure RX_InitRadixHud;
var
  i: integer;
  stmp: string;
begin
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
end;

procedure RX_HudDrawerStatusbar;
var
  p: Ppatch_t;
  i: integer;
begin
  // Draw statusbar
  V_DrawPatch(0, 200 - STATUSBAR_HEIGHT, SCN_TMP, statusbarimage, false);

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
  V_DrawPatch(5, 200 - STATUSBAR_HEIGHT + 4, SCN_TMP, p, false);

  // Draw weapon indicators
  for i := 0 to 6 do
  begin
    if Ord(hud_player.readyweapon) = i then
      p := WeaponNumUse[i]
    else if hud_player.weaponowned[i] <> 0 then
      p := WeaponNumOn[i]
    else
      p := WeaponNumOff[i];
    V_DrawPatch(6 + i * 8, 200 - STATUSBAR_HEIGHT + 31, SCN_TMP, p, false);
  end;

  // Draw threat indicator
  V_DrawPatch(290, 200 - STATUSBAR_HEIGHT + 16, SCN_TMP, treatimages[hud_player.threat], false);
end;

procedure RX_HudDrawerCockpit;
var
  p: Ppatch_t;
begin
  // Draw cockpit
  V_DrawPatchFullScreenTMP320x200(cockpit);

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
  V_DrawPatch(23, 142, SCN_TMP, p, false);

  // Draw threat indicator
  V_DrawPatch(147, 23, SCN_TMP, treatimages[hud_player.threat], false);
end;

procedure RX_HudDrawer;
begin
  if (screenblocks > 11) and (amstate <> am_only) then
    exit;

  hud_player := @players[consoleplayer];

  MT_ZeroMemory(screens[SCN_TMP], 320 * 200);

  if (screenblocks = 11) and (amstate <> am_only) then
    RX_HudDrawerCockpit
  else
    RX_HudDrawerStatusbar;

  V_CopyRectTransparent(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
end;

end.
