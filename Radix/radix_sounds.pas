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

type
  radixsoundinfo_t = record
    name: string[32];
    duration: integer; // in tics
  end;

const
  radixsounds: array[0..Ord(sfx_NumRadixSnd) - 1] of radixsoundinfo_t = (
    (name: 'SndScrape'; duration: -1),
    (name: 'SndShot'; duration: -1),
    (name: 'SndMoveSurface'; duration: -1),
    (name: 'SndStopSurface'; duration: -1),
    (name: 'SndMissle'; duration: -1),
    (name: 'SndExplode'; duration: -1),
    (name: 'SndExplodeShort'; duration: -1),
    (name: 'SndMissile'; duration: -1),
    (name: 'SndMissileOther'; duration: -1),
    (name: 'SndGravityWell'; duration: -1),
    (name: 'SndExplodeOther'; duration: -1),
    (name: 'SndGravityWave'; duration: -1),
    (name: 'SndPlasma'; duration: -1),
    (name: 'SndSiren'; duration: -1),
    (name: 'SndTelePort'; duration: -1),
    (name: 'SndPowerUp'; duration: -1),
    (name: 'SndEndOfLevel'; duration: -1),
    (name: 'SndButtonClick'; duration: -1),
    (name: 'SndAlert'; duration: -1),
    (name: 'SndSpawnShot'; duration: -1),
    (name: 'SndEngine'; duration: -1),
    (name: 'SndEngineAfter'; duration: -1),
    (name: 'SndShip'; duration: -1),
    (name: 'SndPlanet'; duration: -1),
    (name: 'SndDroid'; duration: -1),
    (name: 'SndPlaneHit'; duration: -1),
    (name: 'SndGenAlarm'; duration: -1),
    (name: 'SndEOLAlarm'; duration: -1),
    (name: 'SndBioSpawn'; duration: -1),
    (name: 'SndRadar'; duration: -1),
    (name: 'SndAlienHum'; duration: -1),
    (name: 'SndLoudHum'; duration: -1),
    (name: 'SndFodderExp'; duration: -1),
    (name: 'SndPlasmaBomb'; duration: -1),
    (name: 'SndCannon'; duration: -1),
    (name: 'SndTranspo'; duration: -1),
    (name: 'SndEnemyFire'; duration: -1),
    (name: 'SndPrimAhead'; duration: -1),
    (name: 'SndPrimComplete'; duration: -1),
    (name: 'SndPrimInComplete'; duration: -1),
    (name: 'SndTargetsAhead'; duration: -1),
    (name: 'SndEnemy'; duration: -1),
    (name: 'SndSecAhead'; duration: -1),
    (name: 'SndSecComplete'; duration: -1),
    (name: 'SndSplash'; duration: -1)
  );

//==============================================================================
//
// S_AmbientSound
//
//==============================================================================
function S_AmbientSound(const x, y: integer; const sndname: string): Pmobj_t;

//==============================================================================
//
// S_AmbientSoundFV
//
//==============================================================================
function S_AmbientSoundFV(const x, y: integer; const sndname: string): Pmobj_t;

//==============================================================================
// S_RadixSoundDuration
//
// Returns duration of sound in tics
//
//==============================================================================
function S_RadixSoundDuration(const radix_snd: integer): integer;

//==============================================================================
//
// A_AmbientSound
//
//==============================================================================
procedure A_AmbientSound(actor: Pmobj_t);

//==============================================================================
//
// A_AmbientSoundFV
//
//==============================================================================
procedure A_AmbientSoundFV(actor: Pmobj_t);

implementation

uses
  d_delphi,
  doomdef,
  m_fixed,
  info_common,
  p_common,
  p_local,
  p_mobj,
  s_sound,
  w_wad,
  z_zone;

var
  m_ambient: integer = -1;

const
  STR_AMBIENTSOUND = 'AMBIENTSOUND';

//==============================================================================
//
// S_AmbientSound
//
//==============================================================================
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

//==============================================================================
//
// S_AmbientSoundFV
//
//==============================================================================
function S_AmbientSoundFV(const x, y: integer; const sndname: string): Pmobj_t;
begin
  if m_ambient = -1 then
    m_ambient := Info_GetMobjNumForName(STR_AMBIENTSOUND);

  if m_ambient = -1 then
  begin
    result := nil;
    exit;
  end;

  result := P_SpawnMobj(x, y, ONFLOATZ, m_ambient);
  S_StartSound(result, sndname, true);
end;

type
  char4_t = packed array[0..3] of char;

//==============================================================================
//
// char4tostring
//
//==============================================================================
function char4tostring(const c4: char4_t): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to 3 do
  begin
    if c4[i] in [#0, ' '] then
      exit;
    result := result + c4[i];
  end;
end;

//==============================================================================
//
// S_GetWaveLength
//
//==============================================================================
function S_GetWaveLength(const wavename: string): integer;
var
  groupID: char4_t;
  riffType: char4_t;
  BytesPerSec: integer;
  Stream: TAttachableMemoryStream;
  dataSize: integer;
  lump: integer;
  p: pointer;
  size: integer;
  // chunk seeking function,
  // -1 means: chunk not found

  function GotoChunk(const ID: string): Integer;
  var
    chunkID: char4_t;
    chunkSize: integer;
  begin
    result := -1;

    Stream.Seek(12, sFromBeginning);
    repeat
      // read next chunk
      Stream.Read(chunkID, 4);
      Stream.Read(chunkSize, 4);
      if char4tostring(chunkID) <> ID then
      // skip chunk
        Stream.Seek(Stream.Position + chunkSize, sFromBeginning);
    until (char4tostring(chunkID) = ID) or (Stream.Position >= Stream.Size);
    if char4tostring(chunkID) = ID then
      result := chunkSize;
  end;

begin
  Result := -1;

  lump := W_CheckNumForName(wavename);
  if lump < 0 then
    exit;

  size := W_LumpLength(lump);
  if size < 12 then
    exit;

  p := W_CacheLumpNum(lump, PU_STATIC);

  Stream := TAttachableMemoryStream.Create;
  Stream.Attach(p, size);
  Stream.Read(groupID, 4);
  Stream.Seek(8, sFromBeginning); // skip four bytes (file size)
  Stream.Read(riffType, 4);

  if (char4tostring(groupID) = 'RIFF') and (char4tostring(riffType) = 'WAVE') then
  begin
    // search for format chunk
    if GotoChunk('fmt') <> -1 then
    begin
      // found it
      Stream.Seek(Stream.Position + 8, sFromBeginning);
      Stream.Read(BytesPerSec, 4);
      //search for data chunk
      dataSize := GotoChunk('data');

      if dataSize > 0 then
        result := round(dataSize / BytesPerSec * TICRATE);
    end;
  end;
  Stream.Free;
  Z_ChangeTag(p, PU_CACHE);
end;

//==============================================================================
// S_RadixSoundDuration
//
// Returns duration of sound in tics
//
//==============================================================================
function S_RadixSoundDuration(const radix_snd: integer): integer;
begin
  if (radix_snd < Ord(sfx_SndScrape)) or (radix_snd >= Ord(sfx_NumRadixSnd)) then
  begin
    result := -1;
    exit;
  end;

  result := radixsounds[radix_snd].duration;
  if result < 0 then
  begin
    result := S_GetWaveLength(radixsounds[radix_snd].name);
    radixsounds[radix_snd].duration := result;
  end;
end;

//==============================================================================
//
// A_AmbientSound
//
//==============================================================================
procedure A_AmbientSound(actor: Pmobj_t);
var
  dx, dy: fixed_t;
  snd: string;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  dx := actor.state.params.FixedVal[0];
  dy := actor.state.params.FixedVal[1];

  // JVAL: 20200304 -
  //  Hack! Allow zero string length sound inside RANDOMPICK to avoid playing the sound :)
  snd := actor.state.params.StrVal[2];
  if snd <> '' then
    S_AmbientSound(actor.x + dx, actor.y + dy, snd);
end;

//==============================================================================
//
// A_AmbientSoundFV
//
//==============================================================================
procedure A_AmbientSoundFV(actor: Pmobj_t);
var
  dx, dy: fixed_t;
  snd: string;
begin
  if not P_CheckStateParams(actor, 3) then
    exit;

  dx := actor.state.params.FixedVal[0];
  dy := actor.state.params.FixedVal[1];

  // JVAL: 20200304 -
  //  Hack! Allow zero string length sound inside RANDOMPICK to avoid playing the sound :)
  snd := actor.state.params.StrVal[2];
  if snd <> '' then
    S_AmbientSoundFV(actor.x + dx, actor.y + dy, snd);
end;

end.
