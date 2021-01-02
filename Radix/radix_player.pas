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
//   Radix Player Thing
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_player;

interface

uses
  doomdef,
  d_player,
  p_mobj_h,
  m_fixed;

type
  playertrace_t = record
    x, y, z: fixed_t;
    leveltime: integer;
  end;
  Pplayertrace_t = ^playertrace_t;

const
  NUMPLAYERTRACEHISTORY = 1024;
  HISTORYIGNOREDISTANCE = 64 * FRACUNIT;

type
  playertracehistory_t = record
    numitems: integer;
    rover: integer;
    data: array[0..NUMPLAYERTRACEHISTORY - 1] of playertrace_t;
  end;
  Pplayertracehistory_t = ^playertracehistory_t;

var
  playerhistory: array[0..MAXPLAYERS - 1] of playertracehistory_t;

const
  PLAYERFOLLOWDISTANCE = 2048 * FRACUNIT;

procedure RX_ClearPlayerHistory(const p: Pplayer_t);

function RX_FollowPlayer(const mo: Pmobj_t; const p: Pplayer_t): boolean;

procedure RX_PlayerThink(p: Pplayer_t);

function RX_PlayerMessage(p: Pplayer_t; const msgid: integer): boolean;

procedure RX_PlaneHitWall(const p: Pplayer_t; const tryx, tryy: fixed_t);

procedure RX_PlaneHitFloor(const p: Pplayer_t);

function RX_NearestPlayer(const mo: Pmobj_t): Pplayer_t;

implementation

uses
  d_delphi,
  d_event,
  g_game,
  m_rnd,
  r_defs,
  r_main,
  radix_level,
  radix_map_extra,
  radix_messages,
  radix_objects,
  radix_sounds,
  radix_weapons,
  info,
  info_h,
  info_common,
  p_local,
  p_setup,
  p_map,
  p_maputl,
  p_tick,
  p_mobj,
  p_terrain,
  p_slopes,
  p_sight,
  s_sound,
  tables;

function PlayerToId(const p: Pplayer_t): integer;
var
  i: integer;
begin
  for i := 0 to MAXPLAYERS - 1 do
    if p = @players[i] then
    begin
      result := i;
      exit;
    end;

  result := -1;
end;

procedure RX_PlayerHistoryNotify(const p: Pplayer_t);
var
  pid: integer;
  history: Pplayertracehistory_t;
  nrover: integer;
  dist: fixed_t;
  pmo: Pmobj_t;
  item: Pplayertrace_t;
begin
  pid := PlayerToId(p);
  if (pid < 0) or not playeringame[pid] then
    exit;

  history := @playerhistory[pid];

  pmo := p.mo;
  if history.numitems = 0 then
    nrover := 0
  else
  begin
    item := @history.data[history.rover];
    dist := P_AproxDistance(pmo.x - item.x, pmo.y - item.y);
    if dist < HISTORYIGNOREDISTANCE then
      exit;
    nrover := history.rover + 1;
    if nrover >= NUMPLAYERTRACEHISTORY then
      nrover := nrover - NUMPLAYERTRACEHISTORY;
  end;

  item := @history.data[nrover];
  item.x := pmo.x;
  item.y := pmo.y;
  item.z := pmo.z;
  item.leveltime := leveltime;
  history.rover := nrover;
  if history.numitems < NUMPLAYERTRACEHISTORY then
    inc(history.numitems);
end;

procedure RX_ClearPlayerHistory(const p: Pplayer_t);
var
  pid: integer;
  history: Pplayertracehistory_t;
begin
  pid := PlayerToId(p);
  if (pid < 0) or not playeringame[pid] then
    exit;

  history := @playerhistory[pid];
  ZeroMemory(history, SizeOf(playertracehistory_t));
end;

function RX_FollowPlayer(const mo: Pmobj_t; const p: Pplayer_t): boolean;
var
  pid: integer;
  history: Pplayertracehistory_t;
  i: integer;
  hpos: integer;
  item: Pplayertrace_t;
  bestitem: Pplayertrace_t;
  bestitem2: Pplayertrace_t;
  bestleveltime: fixed_t;
  bestleveltime2: fixed_t;
  dist: fixed_t;
  distfromplayer: fixed_t;
  tracefromplayer: fixed_t;
  tics: integer;
  ang: angle_t;
  speed: integer;
  newx, newy, newz: fixed_t;

  procedure _follow_item;
  begin
    mo.target := p.mo;
    ang := R_PointToAngle2(mo.x, mo.y, item.x, item.y);
    mo.angle := ang;
    speed := mo.info.speed;
    if speed > FRACUNIT then
      speed := speed div FRACUNIT;
    mo.momx := speed * finecosine[ang shr ANGLETOFINESHIFT];
    mo.momy := speed * finesine[ang shr ANGLETOFINESHIFT];
    dist := P_AproxDistance(item.x - mo.x, item.y - mo.y);
    tics := (dist - PLAYERFOLLOWDISTANCE) div (speed * FRACUNIT);
    if tics < TICRATE div 5 then
      tics := TICRATE div 5;
    mo.momz := (item.z - mo.z) div tics;
    mo.playerfollowtime := leveltime + tics;
    mo.tracefollowtimestamp := item.leveltime;
  end;

begin
  result := false;
  if p = nil then
    exit;

  if P_CheckSight(mo, p.mo) then
    if mo.target <> nil then
      if mo.target <> p.mo then
        exit;

  distfromplayer := P_AproxDistance(mo.x - p.mo.x, mo.y - p.mo.y);
  if distfromplayer < PLAYERFOLLOWDISTANCE then
    exit;

  pid := PlayerToId(p);
  if (pid < 0) or not playeringame[pid] then
    exit;

  history := @playerhistory[pid];
  bestitem := nil;
  bestitem2 := nil;
  bestleveltime := -1;
  bestleveltime2 := -1;
  for i := history.rover downto history.rover - history.numitems + 1 do
  begin
    if i < 0 then
      hpos := NUMPLAYERTRACEHISTORY + i
    else
      hpos := i;
    item := @history.data[hpos];
    if item.leveltime > mo.tracefollowtimestamp then
    begin
      if P_CheckSightXYZ(item.x, item.y, item.z, mo) then
      begin
        if item.leveltime > bestleveltime then
        begin
          bestleveltime := item.leveltime;
          bestitem := item;
        end;
        tracefromplayer := P_AproxDistance(item.x - p.mo.x, item.y - p.mo.y);
        if tracefromplayer < distfromplayer then
        begin
          _follow_item;
          result := true;
          exit;
        end;
      end
      else if Sys_Random < 32 then
      begin
        RX_LineTrace(mo.x, mo.y, mo.z, item.x, item.y, item.z, newx, newy, newz);
        if (newx = item.x) and (newy = item.y) then
        begin
          if item.leveltime > bestleveltime2 then
          begin
            bestleveltime2 := item.leveltime;
            bestitem2 := item;
          end;
          tracefromplayer := P_AproxDistance(item.x - p.mo.x, item.y - p.mo.y);
          if tracefromplayer < distfromplayer then
          begin
            _follow_item;
            result := true;
            exit;
          end;
        end;
      end;
    end;
  end;

  if bestitem <> nil then
  begin
    item := bestitem;
    _follow_item;
    result := true;
    exit;
  end;

  if bestitem2 <> nil then
  begin
    item := bestitem2;
    _follow_item;
    result := true;
    exit;
  end;
end;

const
  STR_ENGINESOUND = 'ENGINESOUND';

var
  enginesound_id: integer = -1;

procedure RX_PlayerEngineSound(p: Pplayer_t);
var
  sndid: integer;
begin
  if p.enginesoundtarget = nil then
  begin
    if enginesound_id = -1 then
      enginesound_id := Info_GetMobjNumForName(STR_ENGINESOUND);

    p.enginesoundtarget := P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, enginesound_id);
  end
  else
  begin
    p.enginesoundtarget.x := p.mo.x;
    p.enginesoundtarget.y := p.mo.y;
    p.enginesoundtarget.z := p.mo.z;
  end;

  if p.enginesoundtarget.reactiontime <= 0 then
  begin
    if (p.radixpowers[Ord(rpu_maneuverjets)] > 0) or (p.cmd.buttons2 and BT2_AFTERBURNER <> 0) then
      sndid := Ord(sfx_SndEngineAfter)
    else
      sndid := Ord(sfx_SndEngine);

    S_StartSound(p.enginesoundtarget, radixsounds[sndid].name);
    p.enginesoundtarget.reactiontime := S_RadixSoundDuration(sndid);
  end;

  dec(p.enginesoundtarget.reactiontime);
end;

const
  STR_MESSAGESOUND = 'MESSAGESOUND';

var
  messagesound_id: integer = -1;

procedure RX_PlayerMessageSound(p: Pplayer_t);
begin
  if p.messagesoundtarget = nil then
  begin
    if messagesound_id = -1 then
      messagesound_id := Info_GetMobjNumForName(STR_MESSAGESOUND);

    p.messagesoundtarget := P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, messagesound_id);
  end
  else
  begin
    p.messagesoundtarget.x := p.mo.x;
    p.messagesoundtarget.y := p.mo.y;
    p.messagesoundtarget.z := p.mo.z;
  end;
end;

const
  MAXFRIENDRADIUS = 512 * FRACUNIT;

var
  radixplayermo: Pmobj_t;

function RIT_HandleFriendsNearMe(mo: Pmobj_t): boolean;
var
  dist1: fixed_t;
  dist2: fixed_t;
  speed: fixed_t;
  realangle: angle_t;
  zlo, zhi: fixed_t;
begin
  result := true;

  if mo.flags2_ex and MF2_EX_FRIEND = 0 then
    exit;

  if mo.health <= 0 then
    exit;

  dist1 := P_AproxDistance(mo.x - radixplayermo.x, mo.y - radixplayermo.y);
  if dist1 > MAXFRIENDRADIUS then
    exit;

  if mo.health < mo.info.spawnhealth then
    inc(mo.health);

  dist2 := P_AproxDistance(mo.x + mo.velx - radixplayermo.x - radixplayermo.velx, mo.y + mo.vely - radixplayermo.y - radixplayermo.vely);
  if dist2 > dist1 then // Going away
  begin
    mo.momx := mo.momx * 15 div 16;
    mo.momy := mo.momy * 15 div 16;
    mo.momz := mo.momz * 15 div 16;
    exit;
  end;

  if dist1 < MAXFRIENDRADIUS div 2 then
  begin
    if mo.x < radixplayermo.x then
      mo.momx := -mo.info.speed * FRACUNIT
    else
      mo.momx := mo.info.speed * FRACUNIT;
    if mo.y < radixplayermo.y then
      mo.momy := -mo.info.speed * FRACUNIT
    else
      mo.momy := mo.info.speed * FRACUNIT;
    exit;
  end;

  speed := MaxI(radixplayermo.velocityxy + FRACUNIT, GetIntegerInRange(mo.velocityxy, mo.info.speed * FRACUNIT div 2, mo.info.speed * FRACUNIT));

  realangle := R_PointToAngle2(mo.x, mo.y, radixplayermo.x, radixplayermo.y) - ANG180;

  mo.momx := FixedMul(speed, finecosine[realangle shr ANGLETOFINESHIFT]);
  mo.momy := FixedMul(speed, finesine[realangle shr ANGLETOFINESHIFT]);

  // Adjust momz
  zlo := radixplayermo.z - radixplayermo.floorz;
  zhi := radixplayermo.ceilingz - radixplayermo.z;
  if (mo.z < radixplayermo.z) and (zhi > zlo) then
    if mo.momz < 2 * FRACUNIT then
      mo.momz := mo.momz + FRACUNIT div 2;
  if (mo.z > radixplayermo.z) and (zhi < zlo) then
    if mo.momz > -2 * FRACUNIT then
      mo.momz := mo.momz - FRACUNIT div 2;
end;

procedure RX_HandleFriendsNearMe;
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
begin
  yh := MapBlockIntY(int64(viewy) + MAXFRIENDRADIUS - int64(bmaporgy));
  yl := MapBlockIntY(int64(viewy) - MAXFRIENDRADIUS - int64(bmaporgy));
  xh := MapBlockIntX(int64(viewx) + MAXFRIENDRADIUS - int64(bmaporgx));
  xl := MapBlockIntX(int64(viewx) - MAXFRIENDRADIUS - int64(bmaporgx));

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, RIT_HandleFriendsNearMe);
end;

var
  attackingenemynear: boolean;

function RIT_AttackingEnemyNearMe(mo: Pmobj_t): boolean;
begin
  result := true;

  if mo.flags2_ex and MF2_EX_FRIEND <> 0 then
    exit;

  if mo.health <= 0 then
    exit;

  if mo.flags and MF_COUNTKILL = 0 then
    exit;

  if (mo.info.missilestate > 0) or (mo.info.meleestate > 0) then
    if P_CheckSight(mo, radixplayermo) then
    begin
      result := false;
      attackingenemynear := true;
    end;
end;

procedure RX_AttackingEnemiesNearMe;
const
  ATTACHINGWARNRANGE = 2048 * FRACUNIT;
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
begin
  yh := MapBlockIntY(int64(viewy) + ATTACHINGWARNRANGE - int64(bmaporgy));
  yl := MapBlockIntY(int64(viewy) - ATTACHINGWARNRANGE - int64(bmaporgy));
  xh := MapBlockIntX(int64(viewx) + ATTACHINGWARNRANGE - int64(bmaporgx));
  xl := MapBlockIntX(int64(viewx) - ATTACHINGWARNRANGE - int64(bmaporgx));

  attackingenemynear := false;
  for y := yl to yh do
    for x := xl to xh do
    begin
      P_BlockThingsIterator(x, y, RIT_AttackingEnemyNearMe);
      if attackingenemynear then
        exit;
    end;
end;

const
  DOOMLEVELRADIUS = 16 * FRACUNIT;

procedure RX_PlayerThink(p: Pplayer_t);
var
  new_health: integer;
  new_energy: integer;
  x, y: fixed_t;
  dist: integer;
  an: angle_t;
  mo: Pmobj_t;
  sec: Psector_t;
begin
  radixplayermo := p.mo;

  if Psubsector_t(radixplayermo).sector.radixflags and RSF_RADIXSECTOR = 0 then
    radixplayermo.radius := DOOMLEVELRADIUS
  else
    radixplayermo.radius := mobjinfo[Ord(MT_PLAYER)].radius;

  RX_PlayerHistoryNotify(p);

  RX_HandleFriendsNearMe;

  RX_PlayerMessageSound(p);

  if p.playerstate = PST_DEAD then
  begin
    // JVAL: 20200501 - Linetarget is null when dead
    p.plinetarget := nil;
    // JVAL: 20200423 - Spawn random smoke when player dies
    p.threat := false;
    if (leveltime and 15 = 0) or (P_Random < 50) then
    begin
      an := P_Random * 32;
      dist := 16 + (P_Random and 31);
      x := p.mo.x + dist * finecosine[an];
      y := p.mo.y + dist * finesine[an];
      mo := RX_SpawnRadixBigSmoke(x, y, p.mo.z);
      mo.momz := FRACUNIT div 2 + P_Random * 128;
    end;
    exit;
  end;

  // JVAL: 20200501 - Engine Sound
  RX_PlayerEngineSound(p);

  // JVAL: 20200504 - Plasma bomb count down
  if p.plasmabombcount > 0 then
    dec(p.plasmabombcount);

  if p.planehittics > 0 then
    dec(p.planehittics);

  // JVAL: 20200507 - Avoid rapid repeating weapon changes
  if p.weaponchangetics > 0 then
    dec(p.weaponchangetics);

  // JVAL: 20200507 - Slide to floors/ceilings
  if p.floorslidetics > 0 then
    dec(p.floorslidetics);

  // JVAL: 20200501 - Retrieve Linetarget
  P_AimLineAttack(p.mo, p.mo.angle, 16 * 64 * FRACUNIT);
  if (p.plinetarget = nil) and (linetarget <> nil) then
    p.pcrosstic := leveltime;
  p.plinetarget := linetarget;

  // JVAL: 20200503 - ALDS
  if (p.radixpowers[Ord(rpu_alds)] > 0) and (leveltime and $3 = 0) then
  begin
    if linetarget = nil then
    begin
      P_AimLineAttack(p.mo, p.mo.angle + $4000000, 16 * 64 * FRACUNIT);
      if linetarget = nil then
        P_AimLineAttack(p.mo, p.mo.angle - $4000000, 16 * 64 * FRACUNIT);
    end;
    if linetarget <> nil then
      A_FireALDS(p);
  end;

  p.threat := p.health < p.mo.info.spawnhealth div 4;
  // JVAL: 20200514 - Siren when on low health and enemies near
  if p.threat then
  begin
    if leveltime mod (S_RadixSoundDuration(Ord(sfx_SndSiren)) + 1) = 0 then
    begin
      RX_AttackingEnemiesNearMe;
      if attackingenemynear then
        S_AmbientSound(
          radixplayermo.x,
          radixplayermo.y,
          radixsounds[Ord(sfx_SndSiren)].name
        );
    end;
  end;

  if leveltime and 7 = 0 then
    if p.cmd.buttons2 and BT2_AFTERBURNER <> 0 then
    begin
      if p.energy_reserve > 0 then
        dec(p.energy_reserve)
      else if p.energy > 0 then
        dec(p.energy);
    end;

  if p.energyweaponfiretics > 0 then
    dec(p.energyweaponfiretics);  // JVAL: 20201204

  sec := Psubsector_t(radixplayermo.subsector).sector;
  if sec.special <> 11 then  // JVAL: 20200515 - E1M8 exit sector super damage
    if leveltime and 31 = 0 then
      if p.damagecount = 0 then
      begin
        // Regenerate shield / health
        if p.radixpowers[Ord(rpu_rapidshield)] > 0 then
          new_health := p.health + 2
        else
          new_health := p.health + 1;
        if new_health <= mobjinfo[Ord(MT_PLAYER)].spawnhealth then
        begin
          p.health := new_health;
          p.mo.health := new_health;
        end;

        // Regenerate energy
        new_energy := p.energy;
        if p.energyweaponfiretics = 0 then
        begin // JVAL: 20200412 - If we do not refire energy weapon faster regeneration
          if p.radixpowers[Ord(rpu_rapidenergy)] > 0 then
            new_energy := p.energy + 2
          else
            new_energy := p.energy + 1;
        end
        else
        begin  // JVAL: 20200412 - If we refire energy weapon regenerate only if rapid energy
          if p.radixpowers[Ord(rpu_rapidenergy)] > 0 then
          begin
            // JVAL: 20200423 - Added energy when refiring
            if p.energy_reserve < PLAYERRESERVEENERGY then
              p.energy_reserve := p.energy_reserve + 1;
            new_energy := p.energy;
          end;
        end;

        if new_energy <= PLAYERSPAWNENERGY then
        begin
          p.energy := new_energy;
        end;
      end;

end;

const
  MSGTIMEOUT = 4 * TICRATE;

function RX_PlayerMessage(p: Pplayer_t; const msgid: integer): boolean;
begin
  if IsIntegerInRange(msgid, 0, NUMRADIXMESSAGES - 1) then
    if (p.radixmessages[msgid] = 0) or (leveltime > p.radixmessages[msgid] + MSGTIMEOUT) then
    begin
      p._message := radixmessages[msgid].radix_msg;
      p.radixmessages[msgid] := leveltime;
      result := true;
      exit;
    end;
  result := false;
end;

var
  id_radixdronehitwallsmoke1: integer = -1;
  id_radixdronehitwallsmoke2: integer = -1;

procedure RX_PlaneHitWall(const p: Pplayer_t; const tryx, tryy: fixed_t);
var
  mo, pmo: Pmobj_t;
begin
  inc(p.wallhits); // JVAL: 20200428 - inc wall count to use in score
  pmo := p.mo;
  if p.planehittics <= 0 then
  begin
    if pmo.flags3_ex and MF3_EX_NOSOUND = 0 then
    begin
      if Psubsector_t(pmo.subsector).sector.radixflags and RSF_RADIXSECTOR <> 0 then
      begin
        S_AmbientSound(pmo.x, pmo.y, 'radix/SndScrape');
        p.planehittics := S_RadixSoundDuration(Ord(sfx_SndScrape));
      end
      else
      begin
        S_AmbientSound(pmo.x, pmo.y, 'radix/SndPlaneHit');
        p.planehittics := S_RadixSoundDuration(Ord(sfx_SndPlaneHit));
      end;
    end;
  end;

  if id_radixdronehitwallsmoke1 < 0 then
    id_radixdronehitwallsmoke1 := Info_GetMobjNumForName('MT_RADIXDRONEHITWALLSMOKE1');
  if id_radixdronehitwallsmoke1 < 0 then
    exit;

  if id_radixdronehitwallsmoke2 < 0 then
    id_radixdronehitwallsmoke2 := Info_GetMobjNumForName('MT_RADIXDRONEHITWALLSMOKE2');
  if id_radixdronehitwallsmoke2 < 0 then
    exit;

  if Sys_Random < 128 then
  begin
    if Sys_Random < 128 then
      mo := P_SpawnMobj(pmo.x div 2 + tryx div 2, pmo.y div 2 + tryy div 2, pmo.z + (pmo.height div 256 * Sys_Random), id_radixdronehitwallsmoke1)
    else
      mo := P_SpawnMobj(pmo.x div 2 + tryx div 2, pmo.y div 2 + tryy div 2, pmo.z + (pmo.height div 256 * Sys_Random), id_radixdronehitwallsmoke2);
    mo.momx := pmo.velx + (Sys_Random - Sys_Random) * 64;
    mo.momy := pmo.vely + (Sys_Random - Sys_Random) * 64;
    mo.momz := pmo.velz + (Sys_Random - Sys_Random) * 64;
  end;
end;

procedure RX_PlaneHitFloor(const p: Pplayer_t);

  procedure _spawn_burner_smoke_floor(const dir: integer; const num_hit_smokes: LongWord);
  var
    i: integer;
    an, an1: angle_t;
    dist: fixed_t;
    x, y, z: fixed_t;
    momx, momy, momz: fixed_t;
    psec, sec: Psector_t;
    mo: Pmobj_t;
  begin
    if id_radixdronehitwallsmoke1 < 0 then
      id_radixdronehitwallsmoke1 := Info_GetMobjNumForName('MT_RADIXDRONEHITWALLSMOKE1');
    if id_radixdronehitwallsmoke1 < 0 then
      exit;

    if id_radixdronehitwallsmoke2 < 0 then
      id_radixdronehitwallsmoke2 := Info_GetMobjNumForName('MT_RADIXDRONEHITWALLSMOKE2');
    if id_radixdronehitwallsmoke2 < 0 then
      exit;

    an := p.mo.angle;
    an1 := 0;
    momx := p.mo.velx;
    momy := p.mo.vely;
    psec := Psubsector_t(p.mo.subsector).sector;
    for i := 0 to num_hit_smokes - 1 do
    begin
      dist := p.mo.radius + Sys_Random * 1024;
      x := p.mo.x + FixedMul(dist, finecosine[an shr ANGLETOFINESHIFT]);
      y := p.mo.y + FixedMul(dist, finesine[an shr ANGLETOFINESHIFT]);
      sec := R_PointInSubsector(x, y).sector;
      if sec = psec then
      begin
        if dir < 0 then
        begin
          z := P_FloorHeight(sec, x, y) + 4 * FRACUNIT;
          momz := FRACUNIT div 2 + Sys_Random * 64;
        end
        else
        begin
          z := P_CeilingHeight(sec, x, y) - 4 * FRACUNIT;
          momz := -FRACUNIT div 2 - Sys_Random * 64;
        end;
        if Sys_Random < 128 then
          mo := P_SpawnMobj(x, y, z, id_radixdronehitwallsmoke1)
        else
          mo := P_SpawnMobj(x, y, z, id_radixdronehitwallsmoke2);
        dist := Sys_Random * 64;
        mo.momx := momx + FixedMul(dist, finecosine[an1 shr ANGLETOFINESHIFT]);
        mo.momy := momy + FixedMul(dist, finesine[an1 shr ANGLETOFINESHIFT]);
        mo.momz := momz;
      end;
      an1 := an1 + ANGLE_MAX div num_hit_smokes;
      an := an + ANGLE_MAX div num_hit_smokes;
    end;
  end;

begin
  if p.planehittics <= 0 then
  begin
    // Floor
    if p.mo.z <= p.mo.floorz then
    begin
      if P_GetThingFloorType(p.mo) = FLOOR_SOLID then
      begin
        if abs(p.mo.velz) > 8 * FRACUNIT then
        begin
          if p.mo.flags3_ex and MF3_EX_NOSOUND = 0 then
          begin
            if Psubsector_t(p.mo.subsector).sector.radixflags and RSF_RADIXSECTOR <> 0 then
            begin
              S_AmbientSound(p.mo.x, p.mo.y, 'radix/SndScrape');
              p.planehittics := S_RadixSoundDuration(Ord(sfx_SndScrape));
            end
            else
            begin
              S_AmbientSound(p.mo.x, p.mo.y, 'radix/SndPlaneHit');
              p.planehittics := S_RadixSoundDuration(Ord(sfx_SndPlaneHit));
            end;
          end;
          inc(p.wallhits, 2 * TICRATE);  // JVAL: 20200506 - Big penalty for bad pilot
          _spawn_burner_smoke_floor(-1, 16);  // Spawn more smoke to floor
          exit;
        end
        else if abs(p.mo.velz) > 4 * FRACUNIT then
        begin
          if p.mo.flags3_ex and MF3_EX_NOSOUND = 0 then
          begin
            if Psubsector_t(p.mo.subsector).sector.radixflags and RSF_RADIXSECTOR <> 0 then
            begin
              S_AmbientSound(p.mo.x, p.mo.y, 'radix/SndScrape');
              p.planehittics := S_RadixSoundDuration(Ord(sfx_SndScrape));
            end
            else
            begin
              S_AmbientSound(p.mo.x, p.mo.y, 'radix/SndPlaneHit');
              p.planehittics := S_RadixSoundDuration(Ord(sfx_SndPlaneHit));
            end;
          end;
          inc(p.wallhits, TICRATE);  // JVAL: 20200506 - Small penalty for bad pilot
          _spawn_burner_smoke_floor(-1, 8);  // Spawn less smoke to floor
          exit;
        end;
      end;
    end;
    // Ceiling
    if p.mo.z + p.mo.height >= p.mo.ceilingz then
    begin
      if P_GetThingCeilingType(p.mo) = FLOOR_SOLID then
      begin
        if abs(p.mo.velz) > 8 * FRACUNIT then
        begin
          if p.mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_AmbientSound(p.mo.x, p.mo.y, 'radix/SndScrape');
          p.planehittics := S_RadixSoundDuration(Ord(sfx_SndScrape));
          inc(p.wallhits, 2 * TICRATE);  // JVAL: 20200506 - Big penalty for bad pilot
          _spawn_burner_smoke_floor(1, 16); // Spawn more smoke to ceiling
          exit;
        end
        else if abs(p.mo.velz) > 4 * FRACUNIT then
        begin
          if p.mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_AmbientSound(p.mo.x, p.mo.y, 'radix/SndScrape');
          p.planehittics := S_RadixSoundDuration(Ord(sfx_SndScrape));
          inc(p.wallhits, TICRATE);  // JVAL: 20200506 - Small penalty for bad pilot
          _spawn_burner_smoke_floor(1, 8); // Spawn less smoke to ceiling
          exit;
        end;
      end
    end;
  end;
end;

function RX_NearestPlayer(const mo: Pmobj_t): Pplayer_t;
var
  i: integer;
  nearest: fixed_t;
  dist: fixed_t;
begin
  result := nil;
  nearest := MAXINT;

  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      if (players[i].mo <> nil) and (players[i].mo <> mo) then
        if players[i].mo.health >= 0 then
        begin
          dist := P_AproxDistance(players[i].mo.x - mo.x, players[i].mo.y - mo.y);
          if dist < nearest then
          begin
            nearest := dist;
            result := @players[i];
          end;
        end;
end;

end.
