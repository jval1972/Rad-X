//
//  RAD: Recreation of the game "Radix - beyond the void"
//       powered by the DelphiDoom engine
//
//  Copyright (C) 1995 by Epic MegaGames, Inc.
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  Internally used data structures for virtually everything,
//  key definitions, lots of other stuff.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit doomdef;

interface

uses
  d_delphi;

//
// Global parameters/defines.
//
// DOOM version
const
  VERSION099 = 99;
  VERSION110 = 110;
  VERSION111 = 111;
  VERSION112 = 112;
  VERSION113 = 113;
  VERSION114 = 114;
  VERSION115 = 115;
  VERSION116 = 116;
  VERSION117 = 117;
  VERSION118 = 118;
  VERSION119 = 119;
  VERSION120 = 120;
  VERSION121 = 121;
  VERSION122 = 122;
  VERSION203 = 203;
  VERSION204 = 204;
  VERSION205 = 205;
  VERSION = VERSION205;
{$IFDEF OPENGL}
  VERSIONSLOPES = VERSION122;
{$ENDIF}

type
// Game mode handling - identify version
  GameMode_t = (
    shareware,      // shareware, E1, M9
    registered,     // registered, E3, M27
    indetermined    // Well, no IWAD found.
  );

// Identify language to use, software localization.
  Language_t = (
    english,
    french,
    german,
    unknown
  );

const
  // MAX RENDERING DIMENTIONS
  MAXWIDTH = 4096;
  MAXHEIGHT = 3072;

const
  // MIN RENDERING DIMENTIONS
  MINWIDTH = 320;
  MINHEIGHT = 200;

var
// Rendering Engine Screen Dimentions
  SCREENWIDTH: integer;
  SCREENHEIGHT: integer;
{$IFNDEF OPENGL}
// Window Screen Dimentions
  WINDOWWIDTH: integer;
  WINDOWHEIGHT: integer;
{$ENDIF}

  SCREENWIDTH32PITCH: integer;

  fullscreen: {$IFDEF OPENGL}boolean{$ELSE}integer = 0{$ENDIF};
  zaxisshift: boolean = true;

const
// The maximum number of players, multiplayer/networking.
  MAXPLAYERS = 4;

// State updates, number of tics / second.
  TICRATE = 35;

// The current state of the game: whether we are
// playing, gazing at the intermission screen,
// the game final animation, or a demo.
type
  gamestate_t = (
    GS_INDETERMINED,
    GS_LEVEL,
    GS_BRIEFING,
    GS_INTERMISSION,
    GS_FINALE,
    GS_DEMOSCREEN,
    GS_ENDOOM
  );

var
  gamestate: gamestate_t;
  oldgamestate: integer = -1;
  gamedirectories: TDStringList;

const
//
// Difficulty/skill settings/filters.
//

// Skill flags.
  MTF_EASY = 1;
  MTF_NORMAL = 2;
  MTF_HARD = 4;

// Deaf monsters/do not react to sound.
  MTF_AMBUSH = 8;

// killough 11/98
  MTF_NOTSINGLE = 16;
  MTF_NOTDM = 32;
  MTF_NOTCOOP = 64;
// DelphiDoom
  MTF_COMPATIBILITY = 31;
  MTF_ONMIDSECTOR = 128;  // JVAL: 3d floors
  MTF_DONOTTRIGGERSCRIPTS = 256;  // JVAL: Script Events
  MTF_FRIEND = 512; // JVAL: version 205
  MTF_INACTIVE = 1024; // JVAL: 20200517 - Inactive (stub) enemies
  MTF_SPAWNMIDFLOAT = 2048; // JVAL: 20200517 - Spawn float in middle (for no gravity enemies and player)
  MTF_SPAWNRANDOMFLOAT = 4096; // JVAL: 20200517 - Spawn float random (for no gravity enemies and player)
  MTF_RADIXTHING = 8192; // JVAL: 20200311 - Spawned from Radix map

type
  skill_t = (
    sk_baby,
    sk_easy,
    sk_medium,
    sk_hard,
    sk_nightmare
  );

//
// Key cards.
//
  card_t = (
    it_bluecard,
    it_yellowcard,
    it_redcard,
    it_blueskull,
    it_yellowskull,
    it_redskull,
    NUMCARDS
  );

// The defined weapons,
//  including a marker indicating
//  user has not changed weapon.
  weapontype_t = (
    wp_neutroncannons,
    wp_standardepc,
    wp_plasmaspreader,
    wp_seekingmissiles,
    wp_nuke,
    wp_phasetorpedoes,
    wp_gravitywave,
    wp_enchancedepc,
    wp_superepc,
    NUMWEAPONS,
    // No pending weapon change.
    wp_nochange
  );

// Ammunition types defined.
  ammotype_t = (
    am_radixshell,
    am_radixmisl,
    am_radixtorp,
    am_radixnuke,
    NUMAMMO,
    am_noammo // Unlimited for chainsaw / fist.
  );

// Power up artifacts.
  powertype_t = (
    pw_invulnerability,
    pw_strength,
    pw_invisibility,
    pw_ironfeet,
    pw_allmap,
    pw_infrared,
    NUMPOWERS
  );
  Ppowertype_t = ^powertype_t;

// Radix power Ups
  radixpowerup_t = (
    rpu_rapidshield,
    rpu_rapidenergy,
    rpu_maneuverjets,
    rpu_nightvision,
    rpu_alds, // JVAL: 20200322 - Automated Laser Defence System
    NUMRADIXPOWERUPS
  );
  Pradixpowerup_t = ^radixpowerup_t;

//
// Power up durations,
//  how many seconds till expiration,
//  assuming TICRATE is 35 ticks/second.
//
const
  INVULNTICS = 30 * TICRATE;
  INVISTICS = 60 * TICRATE;
  INFRATICS = 120 * TICRATE;
  IRONTICS = 60 * TICRATE;

//
// DOOM keyboard definition.
// This is the stuff configured by Setup.Exe.
// Most key data are simple ascii (uppercased).
//
const
  KEY_RIGHTARROW = $ae;
  KEY_LEFTARROW = $ac;
  KEY_UPARROW = $ad;
  KEY_DOWNARROW = $af;
  KEY_ESCAPE = 27;
  KEY_ENTER = 13;
  KEY_TAB = 9;

  KEY_F1 = $80 + $3b;
  KEY_F2 = $80 + $3c;
  KEY_F3 = $80 + $3d;
  KEY_F4 = $80 + $3e;
  KEY_F5 = $80 + $3f;
  KEY_F6 = $80 + $40;
  KEY_F7 = $80 + $41;
  KEY_F8 = $80 + $42;
  KEY_F9 = $80 + $43;
  KEY_F10 = $80 + $44;
  KEY_F11 = $80 + $57;
  KEY_F12 = $80 + $58;

  KEY_PRNT = $80 + $59;

  KEY_CON = 126;
  KEY_BACKSPACE = 127;
  KEY_PAUSE = $ff;

  KEY_EQUALS = $3d;
  KEY_MINUS = $2d;

  KEY_RSHIFT = $80 + $36;
  KEY_RCTRL = $80 + $1d;
  KEY_RALT = $80 + $38;

  KEY_PAGEDOWN = $80 + $45;
  KEY_PAGEUP = $80 + $46;
  KEY_INS = $80 + $47;

  KEY_HOME = $80 + $48;
  KEY_END = $80 + $49;
  KEY_DELETE = $80 + $4a;

  KEY_LALT = KEY_RALT;

const
  DEN_PLAYER5 = 4001;
  DEN_PLAYER6 = 4002;
  DEN_PLAYER7 = 4003;
  DEN_PLAYER8 = 4004;

implementation

end.

