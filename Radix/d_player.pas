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
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit d_player;

interface

uses
// The player data structure depends on a number
// of other structs: items (internal inventory),
// animation states (closely tied to the sprites
// used to represent them, unfortunately).
  p_pspr_h,
// In addition, the player is just a special
// case of the generic moving object/actor.
  p_mobj_h,
// Finally, for odd reasons, the player input
// is buffered within the player data struct,
// as commands per game tick.
  d_ticcmd,
  m_fixed,
  tables,
  radix_messages,
  doomdef;

//
// Player states.
//

type
  playerstate_t = (
  // Playing or camping.
    PST_LIVE,
  // Dead on the ground, view follows killer.
    PST_DEAD,
  // Ready to restart/respawn???
    PST_REBORN);

//
// Player internal flags, for cheats and debug.
//

const
  // No clipping, walk through barriers.
  CF_NOCLIP = 1;
  // No damage, no health loss.
  CF_GODMODE = 2;
  // Not really a cheat, just a debug aid.
  CF_NOMOMENTUM = 4;
  // Low gravity cheat
  CF_LOWGRAVITY = 8;

// Radix Weapons Flags and consts
const
  MAXNEUTRONCANNONLEVEL = 7;

type
  neutroncannoninfo_t = record
    level: integer;
    firelevel: integer;
    msg: string[34];
  end;

const
  neutroncannoninfo: array[0..MAXNEUTRONCANNONLEVEL - 1] of neutroncannoninfo_t = (
    (level: 0; firelevel: 0; msg: ''),
    (level: 1; firelevel: 1; msg: 'Level 2 Neutron Cannons Acquired'),
    (level: 2; firelevel: 1; msg: '1 Powerup required for next level'),
    (level: 3; firelevel: 2; msg: 'Level 3 Neutron Cannons Acquired'),
    (level: 4; firelevel: 2; msg: '2 Powerups required for next level'),
    (level: 5; firelevel: 2; msg: '1 Powerup required for next level'),
    (level: 6; firelevel: 3; msg: 'Level 4 Neutron Cannons Acquired')
  );

  epcupgrademessages: array[1..2] of string[32] = (
    'Enchanced EPC aquired',
    'Super EPC aquired'
  );

const
  PWF_NEURONCANNON = 1;
  PWF_NUKE = 2;
  PWF_PHASETORPEDO = 4;

type
  playerscore_t = record
    episode: integer;
    map: integer;
    secondary_pct: integer;
    killratio_pct: integer;
    flyingtime_pct: integer;
    secrets_pct: integer;
    proficientflying_pct: integer;
  end;
  Pplayerscore_t = ^playerscore_t;

const
  PILOTNAMESIZE = 16;

var
  pilotNameString: string[PILOTNAMESIZE] = '';
  pilotname: string;


type
//
// Extended player object info: player_t
//
  player_t = packed record
    mo: Pmobj_t;
    playerstate: playerstate_t;

    // Determine POV,
    //  including viewpoint bobbing during movement.
    // Focal origin above r.z
    viewz: fixed_t;
    // JVAL: 20200427 - Separate field (interpolated)
    bobviewz: fixed_t;
    // Base height above floor for viewz.
    viewheight: fixed_t;
    // Bob/squat speed.
    deltaviewheight: fixed_t;
    // bounded/scaled total momentum.
    bob: fixed_t;

    // Look UP/DOWN support
    lookdir16: integer; // JVAL Smooth Look Up/Down
    centering: boolean;
    // Look LEFT/RIGHT support
    lookdir2: byte;
    oldlook2: integer;
    forwarding: boolean;

    // This is only used between levels,
    // mo->health is used during levels.
    health: integer;
    armorpoints: integer;
    // Armor type is 0-2.
    armortype: integer;

    energy: integer;  // JVAL: 20200314 - Radix energy
    energy_reserve: integer;  // JVAL: 20200423 - Added energy when refiring
    threat: boolean;  // JVAL: 20200314 - Player in threat

    plasmaenergycountdown: integer; // JVAL: 20200412 - How many plasma balls to drain energy
    energyweaponfiretics: integer;  // JVAL: 20200412 - Energy weapon has been fired - wait to zero to regenerate

    thrustmomz: fixed_t;  // JVAL: 20200318 - z momentum by forward/backward move

    // Power ups. invinc and invis are tic counters.
    powers: array[0..Ord(NUMPOWERS) - 1] of integer;
    cards: array[0..Ord(NUMCARDS) - 1] of boolean;
    backpack: boolean;
    radixpowers: array[0..Ord(NUMRADIXPOWERUPS) - 1] of integer;  // JVAL: 20200322 - Radix power ups
    plasmabombs: integer; // JVAL: 20200322 - Number of plasma bombs
    neutroncannonlevel: integer;  // JVAL: 20200324 - Neutro Cannons Level
    weaponflags: LongWord;  // JVAL: 20200328 - Weapon firing sequence information
    scannerjam: boolean;  // JVAL: 20200324 - When true can not see the radar in hud
    lastbonustime: integer; // JVAL: 20200407 - Last level time the player did bonus

    // Frags, kills of other players.
    frags: array[0..MAXPLAYERS - 1] of integer;
    readyweapon: weapontype_t;

    // Is wp_nochange if not changing.
    pendingweapon: weapontype_t;

    weaponowned: array[0..Ord(NUMWEAPONS) - 1] of integer;
    ammo: array[0..Ord(NUMAMMO) - 1] of integer;
    maxammo: array[0..Ord(NUMAMMO) - 1] of integer;
    lastfire: array[0..Ord(NUMWEAPONS) - 1] of integer; // JVAL: 20200401 - Refire control
    gravitywave: integer; // JVAL: 20200403 - Number of gravity wave shots
    weaponchangetics: integer; // JVAL: 20200507 - Avoid rapid repeating weapon changes 

    // True if button down last tic.
    attackdown: boolean;
    usedown: boolean;

    // Bit flags, for cheats and debug.
    // See cheat_t, above.
    cheats: integer;

    // Refired shots are less accurate.
    refire: integer;

    // For intermission stats.
    killcount: integer;
    itemcount: integer;
    secretcount: integer;

    secondaryobjective: boolean;

    // Hint messages.
    _message: string[255];

    // For screen flashing (red or bright).
    damagecount: integer;
    bonuscount: integer;

    // Who did damage (NULL for floors/ceilings).
    attacker: Pmobj_t;

    // So gun flashes light up areas.
    extralight: integer;

    // Current PLAYPAL, ???
    //  can be set to REDCOLORMAP for pain, etc.
    fixedcolormap: integer;

    // Player skin colorshift,
    //  0-3 for which color to draw player.
    colormap: integer; // JVAL: is it used somewhere?

    // Overlay view sprites (gun, etc).
    psprites: array[0..Ord(NUMPSPRITES) - 1] of pspdef_t;

    // True if secret level has been done.
    didsecret: boolean;

    attackerx: fixed_t;
    attackery: fixed_t;

    lastsoundstepx,
    lastsoundstepy: fixed_t;
    lastbreath: integer;
    hardbreathtics: integer;

    planetranspo_start_x: fixed_t;    // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_start_y: fixed_t;    // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_start_z: fixed_t;    // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_start_a: angle_t;    // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_target_x: fixed_t;   // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_target_y: fixed_t;   // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_target_z: fixed_t;   // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_target_a: angle_t;   // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_start_tics: integer; // JVAL: 20200313 - Radix (RA_PlaneTranspo)
    planetranspo_tics: integer;       // JVAL: 20200313 - Radix (RA_PlaneTranspo)

    radixmessages: array[0..NUMRADIXMESSAGES - 1] of integer; // JVAL: 20200423 - Last leveltime displayed

    playername: string[PILOTNAMESIZE];
    scoreskill: skill_t;
    scores: array[1..3] of array[1..9] of playerscore_t;
    currentscore: playerscore_t;
    wallhits: integer;

    plasmabombcount: integer; // JVAL: 20200504 - Plasma bomb palette
    plasmabombdown: boolean;  // JVAL: 20200504 - Plasma bomb key pressed

    planehittics: integer; // JVAL: 20200505 - For plane hit (sound duration)
    floorslidetics: integer; // JVAL: 20200507 - Slide to floors/ceilings

    plinetarget: Pmobj_t; // JVAL: 20200501 - Basically for the crosshair target
    pcrosstic: integer;

    enginesoundtarget: Pmobj_t; // JVAL: 20200501 - Engine sound target

    last_grid_trigger: integer;

    angletargetx: fixed_t;
    angletargety: fixed_t;
    angletargetticks: integer;
    laddertics: integer;
    slopetics: integer; // JVAL: Slopes
    oldviewz: fixed_t; // JVAL: Slopes
    teleporttics: integer;
    quaketics: integer;
    cmd: ticcmd_t;      // JVAL Smooth Look Up/Down
  end;
  Pplayer_t = ^player_t;

//
// INTERMISSION
// Structure passed e.g. to WI_Start(wb)
//

  wbplayerstruct_t = record
    _in: boolean; // whether the player is in game

    // Player stats, kills, collected items etc.
    skills: integer;
    sitems: integer;
    ssecret: integer;
    stime: integer;
    secondaryobjective: boolean;
    wallhits: integer;
    frags: array[0..3] of integer;
    score: integer; // current score on entry, modified on return
  end;
  Pwbplayerstruct_t = ^wbplayerstruct_t;
  wbplayerstruct_tArray = packed array[0..$FFFF] of wbplayerstruct_t;
  Pwbplayerstruct_tArray = ^wbplayerstruct_tArray;

  wbstartstruct_t = record
    epsd: integer; // episode # (0-2)

    // if true, splash the secret level
    didsecret: boolean;

    // previous and next levels, origin 0
    last: integer;
    next: integer;

    maxkills: integer;
    maxitems: integer;
    maxsecret: integer;
    maxfrags: integer;
    hassecondaryobjective: boolean;

    // the par time
    partime: integer;

    // index of this player in game
    pnum: integer;

    plyr: array[0..MAXPLAYERS - 1] of wbplayerstruct_t;
  end;
  Pwbstartstruct_t = ^wbstartstruct_t;

var
// JVAL -> moved from g_game
  players: array[0..MAXPLAYERS - 1] of player_t;

// JVAL Min and Max values for player.lookdir
const
  MINLOOKDIR = -110;
  MAXLOOKDIR = 90;

implementation

end.

