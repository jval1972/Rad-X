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
//   Radix sounds
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_sounds;

interface

uses
  p_mobj_h;

type
  radixsound_t = (
    sfx_SndScrape,
    sfx_SndShot,
    sfx_SndMoveSurface,
    sfx_SndStopSurface,
    sfx_SndMissle,
    sfx_SndExplode,
    sfx_SndExplodeShort,
    sfx_SndMissile,
    sfx_SndMissileOther,
    sfx_SndGravityWell,
    sfx_SndExplodeOther,
    sfx_SndGravityWave,
    sfx_SndPlasma,
    sfx_SndSiren,
    sfx_SndTelePort,
    sfx_SndPowerUp,
    sfx_SndEndOfLevel,
    sfx_SndButtonClick,
    sfx_SndAlert,
    sfx_SndSpawnShot,
    sfx_SndEngine,
    sfx_SndEngineAfter,
    sfx_SndShip,
    sfx_SndPlanet,
    sfx_SndDroid,
    sfx_SndPlaneHit,
    sfx_SndGenAlarm,
    sfx_SndEOLAlarm,
    sfx_SndBioSpawn,
    sfx_SndRadar,
    sfx_SndAlienHum,
    sfx_SndLoudHum,
    sfx_SndFodderExp,
    sfx_SndPlasmaBomb,
    sfx_SndCannon,
    sfx_SndTranspo,
    sfx_SndEnemyFire,
    sfx_SndPrimAhead,
    sfx_SndPrimComplete,
    sfx_SndPrimInComplete,
    sfx_SndTargetsAhead,
    sfx_SndEnemy,
    sfx_SndSecAhead,
    sfx_SndSecComplete,
    sfx_SndSplash,
    sfx_NumRadixSnd
  );

const
  radixsounds: array[0..Ord(sfx_NumRadixSnd) - 1] of string[32] = (
    'SndScrape',
    'SndShot',
    'SndMoveSurface',
    'SndStopSurface',
    'SndMissle',
    'SndExplode',
    'SndExplodeShort',
    'SndMissile',
    'SndMissileOther',
    'SndGravityWell',
    'SndExplodeOther',
    'SndGravityWave',
    'SndPlasma',
    'SndSiren',
    'SndTelePort',
    'SndPowerUp',
    'SndEndOfLevel',
    'SndButtonClick',
    'SndAlert',
    'SndSpawnShot',
    'SndEngine',
    'SndEngineAfter',
    'SndShip',
    'SndPlanet',
    'SndDroid',
    'SndPlaneHit',
    'SndGenAlarm',
    'SndEOLAlarm',
    'SndBioSpawn',
    'SndRadar',
    'SndAlienHum',
    'SndLoudHum',
    'SndFodderExp',
    'SndPlasmaBomb',
    'SndCannon',
    'SndTranspo',
    'SndEnemyFire',
    'SndPrimAhead',
    'SndPrimComplete',
    'SndPrimInComplete',
    'SndTargetsAhead',
    'SndEnemy',
    'SndSecAhead',
    'SndSecComplete',
    'SndSplash'
  );

function S_AmbientSound(const x, y: integer; const sndname: string): Pmobj_t;

implementation

uses
  info_common,
  p_local,
  p_mobj,
  s_sound;

var
  m_ambient: integer = -1;

const
  STR_AMBIENTSOUND = 'AMBIENTSOUND';

function S_AmbientSound(const x, y: integer; const sndname: string): Pmobj_t;
begin
  if m_ambient = -1 then
    m_ambient := Info_GetMobjNumForName(STR_AMBIENTSOUND);

  if m_ambient = -1 then
  begin
    result := nil;
    exit;
  end;

  result := P_SpawnMobj(x, y, ONFLOATZ, m_ambient);
  S_StartSound(result, sndname);
end;

end.
