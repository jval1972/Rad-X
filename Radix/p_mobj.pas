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
// DESCRIPTION:
//  Map Objects, MObj, definition and handling.
//  Moving object handling. Spawn functions.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit p_mobj;

interface

uses
  p_mobj_h,
  tables,
// We need the WAD data structure for Map things,
// from the THINGS lump.
  doomdata,
// States are tied to finite states are
//  tied to animation frames.
// Needs precompiled tables/data structures.
  info_h,
  m_fixed;

function P_TicsFromState(const st: Pstate_t): integer;

function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;

function P_SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean;

procedure P_ExplodeMissile(mo: Pmobj_t);

procedure P_MobjThinker(mobj: Pmobj_t);

function P_SpawnMobj(x, y, z: fixed_t; _type: integer; const mthing: Pmapthing_t = nil): Pmobj_t;

function P_SpawnPlayerMissileMobj(x, y, z: fixed_t; _type: integer): Pmobj_t;

procedure P_RemoveMobj(mobj: Pmobj_t);

function P_SpawnPlayer(mthing: Pmapthing_t): Pmobj_t;

function P_SpawnMapThing(mthing: Pmapthing_t): Pmobj_t;

procedure P_SpawnPuff(x, y, z: fixed_t);

function P_SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;

function P_SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;

function P_SpawnMissileAngleZ(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t): Pmobj_t;

function P_SpawnMissileAngleZSpeed(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t; owner: Pmobj_t): Pmobj_t;

procedure P_SpawnPlayerMissile(source: Pmobj_t; _type: integer);

// JVAL: 20200422 - New function
procedure P_SpawnRadixPlayerMissile(source: Pmobj_t; _type: integer);

procedure P_RespawnSpecials;

procedure P_SpawnBlood(x, y, z: fixed_t; damage: integer);

procedure P_SpawnGreenBlood(x, y, z: fixed_t; damage: integer);

procedure P_SpawnBlueBlood(x, y, z: fixed_t; damage: integer);

function P_CheckMissileSpawn(th: Pmobj_t): boolean;

function P_SeekerMissile(actor: Pmobj_t; thresh, turnMax: angle_t): boolean;

procedure P_HitFloor(thing: Pmobj_t);

function P_GetThingFloorType(thing: Pmobj_t): byte;

function P_GetThingCeilingType(thing: Pmobj_t): byte;

procedure MObj_Init;

procedure MObj_ShutDown;

var
  iquehead: integer; // Initialized at p_setup
  iquetail: integer; // Initialized at p_setup

function P_FindMobjFromKey(const key: LongWord): Pmobj_t;

var
  spawnmask: LongWord = $FFFFFFFF;

implementation

uses
  d_delphi,
  c_cmds,
  sc_engine,
  doomstat,
  d_player,
  d_think,
  d_main,
  m_vectors,
  g_game,
  g_gameplay,
  i_system,
  z_zone,
  m_rnd,
  doomdef,
  p_gravity,
  p_local,
  p_map,
  p_maputl,
  p_mobjlist,
  p_tick,
  p_pspr,
  p_setup,
  p_common,
  p_terrain,
  p_sounds,
  p_3dfloors, // JVAL: 3d floors
  p_slopes, // JVAL: Slopes
  p_params,
  p_ladder,
  p_musinfo,
  radix_map_extra,
  radix_sounds,
  radix_player,
  radix_messages,
  radix_forcefield,
  radix_teleport,
  r_defs,
  r_sky,
  r_main,
  r_data,
  st_stuff,
  hu_stuff,
  s_sound,
  sounds,
  sound_data,
  info,
  info_rnd,
  info_common;

function P_TicsFromState(const st: Pstate_t): integer;
begin
  if st.flags_ex and MF_EX_STATE_RANDOM_SELECT <> 0 then
  begin
    if P_Random < 128 then
      result := st.tics
    else
      result := st.tics2;
  end
  else if st.flags_ex and MF_EX_STATE_RANDOM_RANGE <> 0 then
  begin
    if st.tics2 > st.tics then
      result := st.tics + P_Random mod (st.tics2 - st.tics + 1)
    else if st.tics2 < st.tics then
      result := st.tics + P_Random mod (st.tics - st.tics2 + 1)
    else
      result := st.tics;
  end
  else
    result := st.tics;
end;

// From Chocolate-Doom
// Use a heuristic approach to detect infinite state cycles: Count the number
// of times the loop in P_SetMobjState() executes and exit with an error once
// an arbitrary very large limit is reached.
const
  MOBJ_CYCLE_LIMIT = 1000000;

//
// P_SetMobjState
// Returns true if the mobj is still present.
//
function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;
var
  st: Pstate_t;
  cycle_counter: integer;
begin
  cycle_counter := 0;
  repeat
    if state = S_NULL then
    begin
      if mobj.flags_ex and MF_EX_DONOTREMOVE = 0 then // JVAL Do not remove missile
      begin
        mobj.state := @states[Ord(S_NULL)];
        P_RemoveMobj(mobj);
      end;
      result := false;
      exit;
    end;

    if mobj.validcount <> validcount then
    begin
      mobj.validcount := validcount;
      mobj.prevstate := mobj.state;
    end;

    st := @states[Ord(state)];

    mobj.state := st;
    mobj.tics := P_TicsFromState(st);
    mobj.sprite := st.sprite;
    mobj.frame := st.frame;

    // Modified handling.
    // Call action functions when the state is set
    if Assigned(st.action.acp1) then
    begin
      if st.params <> nil then
        st.params.Actor := mobj;
      st.action.acp1(mobj);
    end;

    state := st.nextstate;

    inc(cycle_counter);
    if cycle_counter > MOBJ_CYCLE_LIMIT then
      I_Error('P_SetMobjState(): Infinite state cycle detected!');
  until mobj.tics <> 0;

  result := true;
end;

//----------------------------------------------------------------------------
//
// FUNC P_SetMobjStateNF
//
// Same as P_SetMobjState, but does not call the state function.
//
//----------------------------------------------------------------------------
function P_SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean;
var
  st: Pstate_t;
begin
  if state = S_NULL then
  begin // Remove mobj
    if mobj.flags_ex and MF_EX_DONOTREMOVE = 0 then // JVAL Do not remove missile
    begin
      mobj.state := @states[Ord(S_NULL)];
      P_RemoveMobj(mobj);
    end;
    result := false;
  end
  else
  begin
    st := @states[Ord(state)];
    mobj.state := st;
    mobj.tics := P_TicsFromState(st);
    if mobj.tics = 0 then
      mobj.tics := 1;
    mobj.sprite := st.sprite;
    mobj.frame := st.frame;
    result := true;
  end;
end;

//
// P_ExplodeMissile
//
procedure P_ExplodeMissile(mo: Pmobj_t);
begin
  if mo.z + mo.momz < mo.floorz + 4 * FRACUNIT then
  begin
    mo.z := mo.floorz;
    P_HitFloor(mo);
    mo.flags2_ex := mo.flags2_ex and not MF2_EX_NOHITFLOOR;
  end;
  
  mo.momx := 0;
  mo.momy := 0;
  mo.momz := 0;

  P_SetMobjState(mo, statenum_t(mo.info.deathstate));

  mo.tics := mo.tics - (P_Random and 3);

  if mo.tics < 1 then
    mo.tics := 1;

  mo.flags := mo.flags and not MF_MISSILE;

  // JVAL: 20200328 - Missile Damage Wall
  if tmline <> nil then
  begin
    // JVAL: 20200501 - Only missiles with MF3_EX_CANDAMAGEWALLS can damage walls
    if mo.flags3_ex and MF3_EX_CANDAMAGEWALLS <> 0 then
      RX_DamageLine(tmline, P_GetThingDamage(mo) * ((P_Random mod 3) + 1));
    tmline := nil;
  end;

  A_DeathSound(mo, mo);
end;

procedure P_ResolveBounceBehaviour(const mo: Pmobj_t);
begin
  if mo.flags3_ex and MF3_EX_LIMITBOUNCECONTROL <> 0 then
  begin
    if mo.bouncecnt > 0 then
      dec(mo.bouncecnt);
    if mo.bouncecnt = 0 then
      mo.flags3_ex := mo.flags3_ex and not MF3_EX_BOUNCE;
  end;
end;

//
// P_XYMovement
//
const
  STOPSPEED = $1000;
  FRICTION = $e800;

procedure P_XYMovement(mo: Pmobj_t);
var
  ptryx: fixed_t;
  ptryy: fixed_t;
  player: Pplayer_t;
  xmove: fixed_t;
  ymove: fixed_t;
  wasonfloorz: boolean;
  wasonslope: boolean;
  oldsector: Psector_t;
  speed: fixed_t;
  tangle, langle: angle_t;
  anglediff, newangle: angle_t;
  dobounce: boolean;
  sfront, sback: Psector_t;
  ltop, lbottom: fixed_t;

  function xy_check_missile_explode: boolean;
  begin
    if (ceilingline <> nil) and
       (ceilingline.backsector <> nil) and
       (ceilingline.backsector.ceilingpic = skyflatnum) then
      // JVAL: 20200416 - Extra check for lower textures up to ceiling
      if mo.z >= ceilingline.backsector.floorheight then
      begin
        // Hack to prevent missiles exploding
        // against the sky.
        // Does not handle sky floors.
        P_RemoveMobj(mo);
        result := false;
        exit;
      end;
    P_ExplodeMissile(mo);
    result := true;
  end;

begin
  if (mo.momx = 0) and (mo.momy = 0) then
  begin
    if mo.flags and MF_SKULLFLY <> 0 then
    begin
      // the skull slammed into something
      mo.flags := mo.flags and not MF_SKULLFLY;
      mo.momx := 0;
      mo.momy := 0;
      mo.momz := 0;

      P_SetMobjState(mo, statenum_t(mo.info.spawnstate));
    end;
    exit;
  end;

  wasonfloorz := mo.z <= mo.floorz;
  oldsector := Psubsector_t(mo.subsector).sector;
  wasonslope := oldsector.renderflags and SRF_SLOPED <> 0;

  player := mo.player;

  if mo.flags3_ex and MF3_EX_NOMAXMOVE = 0 then
  begin
    if mo.momx > MAXMOVE then
      mo.momx := MAXMOVE
    else if mo.momx < -MAXMOVE then
      mo.momx := -MAXMOVE;

    if mo.momy > MAXMOVE then
      mo.momy := MAXMOVE
    else if mo.momy < -MAXMOVE then
      mo.momy := -MAXMOVE;
  end;

  xmove := mo.momx;
  ymove := mo.momy;

  repeat
    if (xmove > MAXMOVE div 2) or (ymove > MAXMOVE div 2) or
       (xmove < -MAXMOVE div 2) or (ymove < -MAXMOVE div 2) then
    begin
      xmove := xmove div 2;
      ymove := ymove div 2;
      ptryx := mo.x + xmove;
      ptryy := mo.y + ymove;
    end
    else
    begin
      ptryx := mo.x + xmove;
      ptryy := mo.y + ymove;
      xmove := 0;
      ymove := 0;
    end;

    tmfloorz := P_3dFloorHeight(ptryx, ptryy, mo.z);
    tmceilingz := P_3dCeilingHeight(ptryx, ptryy, mo.z);

    // JVAL: 20200328 - Missile Damage Wall
    tmline := nil;

    if not P_TryMove(mo, ptryx, ptryy) then
    begin
      // blocked move
      if mo.player <> nil then
      begin
        if tmforcefieldline <> nil then
          RX_ForceFieldThrust(mo.player, tmforcefieldline)
        else if not P_LadderMove(mo) then
        begin
          P_SlideMove(mo); // try to slide along it
          RX_PlaneHitWall(mo.player, ptryx, ptryy);
        end;
      end
      // JVAL: 20200308 - Bounce on walls
      else if mo.flags3_ex and MF3_EX_WALLBOUNCE <> 0 then
      begin
        if tmbounceline <> nil then
        begin
          if tmbounceline.flags and ML_BLOCKING <> 0 then
            dobounce := not RX_ShootableLine(tmbounceline)
          else if (tmbounceline.sidenum[1] = -1) or (tmbounceline.sidenum[0] = -1) then
            dobounce := not RX_ShootableLine(tmbounceline)
          else
          begin
            if not RX_ShootableLine(tmbounceline) then
            begin
              sfront := sides[tmbounceline.sidenum[0]].sector;
              sback := sides[tmbounceline.sidenum[1]].sector;
              ltop := MinI(sfront.ceilingheight, sback.ceilingheight);
              lbottom := MaxI(sfront.floorheight, sback.floorheight);
              dobounce := not IsIntegerInRange(mo.z, lbottom, ltop);
            end
            else
              dobounce := false;
          end;
          if dobounce then
          begin
            speed := P_AproxDistance(mo.momx, mo.momy);
            tangle := mo.angle;
            langle := R_PointToAngle2(tmbounceline.v1.x, tmbounceline.v1.y, tmbounceline.v2.x, tmbounceline.v2.y);
            anglediff := tangle - langle;
            newangle := langle - anglediff;
            mo.angle := newangle;
            newangle := newangle shr ANGLETOFINESHIFT;
            mo.momx := FixedMul(speed, finecosine[newangle]);
            mo.momy := FixedMul(speed, finesine[newangle]);
          end;
        end
        else if not tmfailfromptinair then
        begin
          dobounce := true;
          if mo.flags3_ex and MF3_EX_WALLBOUNCEFACTOR <> 0 then
          begin
            mo.momx := FixedMul(mo.momx, mo.wallbouncefactor);
            mo.momy := FixedMul(mo.momy, mo.wallbouncefactor);
          end
          else
          begin
            mo.momx := mo.momx div 2;
            mo.momy := mo.momy div 2;
          end;

          if P_TryMove(mo, mo.x - xmove, ymove + mo.y) then
            mo.momy := -mo.momy
          else
            mo.momx := -mo.momx;

          mo.angle := R_PointToAngle2(0, 0, -mo.momx, -mo.momy);
        end
        else
          dobounce := false;

        if dobounce then
        begin
          P_ResolveBounceBehaviour(mo);
          xmove := 0;
          ymove := 0;
        end
        else if mo.flags and MF_MISSILE <> 0 then
        begin
          if mo.flags3_ex and (MF3_EX_FLOORBOUNCE or MF3_EX_CEILINGBOUNCE) = 0 then
            if not xy_check_missile_explode then
              exit;
          if (mo.flags3_ex and MF3_EX_FLOORBOUNCE <> 0) and (mo.z <= mo.floorz) then
          begin
            if Psubsector_t(mo.subsector).sector.floorpic = skyflatnum then
            begin
              P_RemoveMobj(mo);
              exit;
            end;
            speed := mo.info.speed;
            mo.momz := speed;
          end
          else if (mo.flags3_ex and MF3_EX_CEILINGBOUNCE <> 0) and (mo.z >= mo.ceilingz) then
          begin
            if Psubsector_t(mo.subsector).sector.ceilingpic = skyflatnum then
            begin
              P_RemoveMobj(mo);
              exit;
            end;
            speed := mo.info.speed;
            mo.momz := -speed;
          end;
        end;
      end
      else if mo.flags and MF_MISSILE <> 0 then
      begin
        if not xy_check_missile_explode then
          exit;
      end
      else
      begin
        mo.momx := 0;
        mo.momy := 0;
      end;
    end;
  until not ((xmove <> 0) or (ymove <> 0));

  // slow down
  if (player <> nil) and (player.cheats and CF_NOMOMENTUM <> 0) then
  begin
    // debug option for no sliding at all
    mo.momx := 0;
    mo.momy := 0;
    exit;
  end;

  if (mo.flags and (MF_MISSILE or MF_SKULLFLY)) <> 0 then
    exit; // no friction for missiles ever

  if mo.flags3_ex and MF3_EX_BOUNCE <> 0 then
    exit; // no friction for bouncing objects

  if (player <> nil) and (player.laddertics > 0) then
  else
    if mo.z > mo.floorz then
    begin
      if wasonfloorz and wasonslope and (oldsector = Psubsector_t(mo.subsector).sector) then
      begin
        if oldsector.flags and SF_SLIPSLOPEDESCENT <> 0 then
          exit; // Slip sector while descenting slope
        mo.z := mo.floorz;
      end
      else
        exit;
    end;

  if mo.flags and MF_CORPSE <> 0 then
  begin
    // do not stop sliding
    //  if halfway off a step with some momentum
    if (mo.momx > FRACUNIT div 4) or
       (mo.momx < -FRACUNIT div 4) or
       (mo.momy > FRACUNIT div 4) or
       (mo.momy < -FRACUNIT div 4) then
    begin
      if mo.floorz <> P_3dFloorHeight(mo) then // JVAL: 3d floors
        exit;
    end;
  end;

  if (mo.momx > -STOPSPEED) and
     (mo.momx < STOPSPEED) and
     (mo.momy > -STOPSPEED) and
     (mo.momy < STOPSPEED) and
     ((player = nil) or
      ((player.cmd.forwardmove = 0) and
       (player.cmd.sidemove = 0))) then
  begin
    // if in a walking frame, stop moving
    if (player <> nil) and
       (LongWord((pDiff(player.mo.state, @states[0], SizeOf(states[0]))) - Ord(S_PLAY_RUN1)) < 4) then
      P_SetMobjState(player.mo, S_PLAY);

    mo.momx := 0;
    mo.momy := 0;
  end
  else
  begin
    mo.momx := FixedMul(mo.momx, FRICTION);
    mo.momy := FixedMul(mo.momy, FRICTION);
  end;
end;

//
// P_ZMovement
//
procedure P_ZMovement(mo: Pmobj_t);
var
  dist: fixed_t;
  delta: fixed_t;
  ceilz: fixed_t;
  grav: integer;
  momomz: fixed_t;
  ladderticks: integer;
  player: Pplayer_t;
  sec: Psector_t;
  bouncing: boolean;
begin
  ladderticks := 0;
  player := Pplayer_t(mo.player);
  if player <> nil then
  begin
    if player.laddertics > 0 then
    begin
      Dec(player.laddertics);
      ladderticks := player.laddertics;
    end;
    if player.slopetics > 0 then
      Dec(player.slopetics);

    // check for smooth step up
    if (mo.z < mo.floorz) and (ladderticks = 0) then
    begin
      player.viewheight := player.viewheight - (mo.floorz - mo.z);
      player.deltaviewheight :=
        _SHR((PVIEWHEIGHT - player.viewheight), 3);
    end;
  end;

  // adjust height
  if ladderticks > 0 then
  begin
    mo.z := mo.z + mo.momz;
    mo.momz := (mo.momz * 7) div 8;
    if mo.momz < FRACUNIT div 16 then
      mo.momz := 0;
  end
  else
    mo.z := mo.z + mo.momz;

  bouncing := false;

  if (mo.flags and MF_FLOAT <> 0) and (mo.target <> nil) then
  begin
    // float down towards target if too close
    if ((mo.flags and MF_SKULLFLY) = 0) and
       ((mo.flags and MF_INFLOAT) = 0) then
    begin
      dist := P_AproxDistance(mo.x - mo.target.x, mo.y - mo.target.y);

      delta := (mo.target.z + mo.height div 2) - mo.z; // JVAL is it right ???

      if (delta < 0) and (dist < -(delta * 3)) then
        mo.z := mo.z - FLOATSPEED
      else if (delta > 0) and (dist < (delta * 3)) then
        mo.z := mo.z + FLOATSPEED;
    end;
  end;

  sec := Psubsector_t(mo.subsector).sector;
  // clip movement
  if mo.z <= mo.floorz then
  begin
    // hit the floor

    if (mo.flags3_ex and MF3_EX_FLOORBOUNCE <> 0) and (sec.floorpic <> skyflatnum) then
    begin
      // villsa [STRIFE] affect reactiontime
      // momz is also shifted by 1
      if mo.flags and MF_MISSILE <> 0 then
        mo.momz := -mo.momz
      else
        mo.momz := -mo.momz div 2;
      mo.reactiontime := mo.reactiontime div 2;

      // villsa [STRIFE] get terrain type
      if P_GetThingFloorType(mo) > FLOOR_SKY then
      begin
        mo.flags3_ex := mo.flags3_ex and not MF3_EX_FLOORBOUNCE;
        bouncing := false;
        mo.bouncecnt := 0;
      end
      else
      begin
        P_ResolveBounceBehaviour(mo);
        bouncing := true;
      end;
    end
    else if (mo.flags and MF_MISSILE <> 0) and (mo.flags3_ex and MF3_EX_FLOORBOUNCE <> 0) and (sec.floorpic = skyflatnum) then
    begin
      P_ExplodeMissile(mo);
      exit;
    end;

    if mo.flags and MF_SKULLFLY <> 0 then
    begin
      // the skull slammed into something
      mo.momz := -mo.momz;
    end;

    momomz := mo.momz;
    if mo.momz < 0 then
    begin
      if (player <> nil) and (mo.momz < -P_GetMobjGravity(mo) * 8) then
      begin
        // Squat down.
        // Decrease viewheight for a moment
        // after hitting the ground (hard),
        // and utter appropriate sound.
        player.deltaviewheight := _SHR(mo.momz, 3);
      end;
      mo.momz := 0;
    end;

    if mo.z - momomz > mo.floorz then
    begin // Spawn splashes, etc.
      P_HitFloor(mo);
    end;

    mo.z := mo.floorz;

    if (mo.flags and MF_MISSILE <> 0) and (mo.flags and MF_NOCLIP = 0) and not bouncing then
    begin
      P_ExplodeMissile(mo);
      exit;
    end;

    if (mo.info.crashstate > 0) and
       (mo.flags and MF_CORPSE <> 0) then
    begin
      P_SetMobjState(mo, statenum_t(mo.info.crashstate));
      exit;
    end;

  end
  else if mo.flags and MF_NOGRAVITY = 0 then
  begin
    grav := P_GetMobjGravity(mo);
    // JVAL
    // Low gravity cheat
    if player <> nil then
      if player.cheats and CF_LOWGRAVITY <> 0 then
        grav := grav div 2;

    if mo.momz = 0 then
      mo.momz := - grav * 2
    else
      mo.momz := mo.momz - grav;

    // JVAL
    // Low gravity flag
    if mo.flags_ex and MF_EX_LOWGRAVITY <> 0 then
      mo.momz := mo.momz div 2
    else if mo.flags2_ex and MF2_EX_MEDIUMGRAVITY <> 0 then
      mo.momz := mo.momz * 3 div 4;

  end;

  ceilz := mo.ceilingz + P_SectorJumpOverhead(sec, mo);

  if mo.z + mo.height > ceilz then
  begin
    // hit the ceiling
    if mo.momz > 0 then
    begin
      if (mo.flags3_ex and MF3_EX_CEILINGBOUNCE <> 0) and (sec.ceilingpic <> skyflatnum) then
      begin
        if mo.flags and MF_MISSILE <> 0 then
          mo.momz := -mo.momz
        else
          mo.momz := -mo.momz div 2;
        P_ResolveBounceBehaviour(mo);
      end
      else
      begin
        if mo.flags and MF_MISSILE <> 0 then
        begin
          P_ExplodeMissile(mo);
          exit;
        end;
        mo.momz := 0;
      end;

      bouncing := true;
    end;

    mo.z := ceilz - mo.height;

    if mo.flags and MF_SKULLFLY <> 0 then
      mo.momz := -mo.momz; // the skull slammed into something

    if (mo.flags and MF_MISSILE <> 0) and (mo.flags and MF_NOCLIP = 0) and not bouncing then
    begin
      P_ExplodeMissile(mo);
      exit;
    end;
  end;
end;

//
// P_NightmareRespawn
//
procedure P_NightmareRespawn(mobj: Pmobj_t);
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psubsector_t;
  mo: Pmobj_t;
  mthing: Pmapthing_t;
  h: fixed_t; // JVAL: 3d floors
begin
  x := mobj.spawnpoint.x * FRACUNIT;
  y := mobj.spawnpoint.y * FRACUNIT;

  // somthing is occupying it's position?
  if not P_CheckPosition(mobj, x, y) then
    exit; // no respwan

  // spawn a teleport fog at old spot
  // because of removal of the body?
  mo := P_SpawnMobj(mobj.x, mobj.y, mobj.z, Ord(MT_TFOG));  // JVAL: 3d floors

  // initiate teleport sound
  if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
    S_StartSound(mo, Ord(sfx_telept));
  // spawn a teleport fog at the new spot
  ss := R_PointInSubsector(x, y);

// JVAL: 3d floors
  h := P_FloorHeight(ss.sector, mo.x, mo.y);
  if ss.sector.midsec >= 0 then
    if mobj.spawnpoint.options and MTF_ONMIDSECTOR <> 0 then
      h := sectors[ss.sector.midsec].ceilingheight;

  mo := P_SpawnMobj(x, y, h, Ord(MT_TFOG));

  if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
    S_StartSound(mo, Ord(sfx_telept));

  // spawn the new monster
  mthing := @(mobj.spawnpoint);

  // spawn it
  if mobj.info.flags and MF_SPAWNCEILING <> 0 then
    z := ONCEILINGZ
  else if mobj.info.flags_ex and MF_EX_SPAWNFLOAT <> 0 then
    z := ONFLOATZ
  else
    z := ONFLOORZ;

  // inherit attributes from deceased one
  mo := P_SpawnMobj(x, y, z, Ord(mobj._type), mthing);
  mo.spawnpoint := mobj.spawnpoint;
  if mo.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    mo.angle := ANG1 * mthing.angle
  else
    mo.angle := ANG45 * (mthing.angle div 45);

  if mthing.options and MTF_DONOTTRIGGERSCRIPTS <> 0 then
    mobj.flags2_ex := mobj.flags2_ex or MF2_EX_DONTRUNSCRIPTS;

  if mthing.options and MTF_AMBUSH <> 0 then
    mo.flags := mo.flags or MF_AMBUSH;

  // JVAL: 20200517 - Inactive (stub) enemies
  if mthing.options and MTF_INACTIVE <> 0 then
    mo.flags3_ex := mo.flags3_ex or MF3_EX_INACTIVE;

  // killough 11/98: transfer friendliness from deceased
  if mobj.flags2_ex and MF2_EX_FRIEND = 0 then
    mo.flags2_ex := mo.flags2_ex and not MF2_EX_FRIEND
  else
    mo.flags2_ex := mo.flags2_ex or MF2_EX_FRIEND;

  mo.reactiontime := 18;

  // remove the old monster,
  P_RemoveMobj(mobj);
end;

procedure P_FixPlayerViewz(const p: Pplayer_t);
var
  floorz, ceilingz: fixed_t;
begin
  floorz := P_3DFloorHeight(p.mo);
  ceilingz := P_3DCeilingHeight(p.mo);

  if p.viewz > ceilingz - 4 * FRACUNIT then
    p.viewz := ceilingz - 4 * FRACUNIT;

  if p.viewz < floorz + 4 * FRACUNIT then
    p.viewz := floorz + 4 * FRACUNIT;
end;

procedure P_VelocityHandler(const mobj: Pmobj_t);
begin
  if mobj.flags3_ex and MF3_EX_IDLEEXPLODE <> 0 then
  begin
    // Explode in very low speeds
    if mobj.velocity <= mobj.idleexplodespeed then
    begin
      mobj.flags3_ex := mobj.flags3_ex and not MF3_EX_IDLEEXPLODE;
      P_ExplodeMissile(mobj);
      exit;
    end;
    // Accelerate in low (but not very low) speeds
    if mobj.velocity < mobj.info.speed div 4 then
    begin
      mobj.momx := mobj.momx * 5 div 4;
      mobj.momy := mobj.momy * 5 div 4;
      mobj.momz := mobj.momz * 5 div 4;
    end;
  end;

  if mobj.flags and MF_MISSILE <> 0 then
  begin
    if mobj.z <= mobj.floorz - FRACUNIT then
    begin
      P_ExplodeMissile(mobj);
      exit;
    end;

    if mobj.z >= mobj.ceilingz + FRACUNIT then
    begin
      P_ExplodeMissile(mobj);
      exit;
    end;
  end;
end;

//
// P_MobjThinker
//
procedure P_DoMobjThinker(mobj: Pmobj_t);
var
  onmo: Pmobj_t;
begin
  // momentum movement
  if (mobj.momx <> 0) or
     (mobj.momy <> 0) or
     (mobj.flags and MF_SKULLFLY <> 0) then
  begin
    P_XYMovement(mobj);

    if mobj.player <> nil then
      P_FixPlayerViewz(mobj.player);

    if not Assigned(mobj.thinker._function.acv) then
    begin
      exit; // mobj was removed
    end;
  end;

  if mobj.flags_ex and MF_EX_FLOATBOB <> 0 then
  begin
    mobj.z := mobj.floorz + FloatBobOffsets[mobj.floatbob];
    mobj.floatbob := (mobj.floatbob + 1) and FLOATBOBMASK;
  end
  else
  begin
    // JVAL: 20200417 - MF3_EX_BOBING flag
    if mobj.flags3_ex and MF3_EX_BOBING <> 0 then
    begin
      mobj.momz := mobj.momz - FloatBobOffsets[mobj.floatbob] div 4;
      mobj.floatbob := (mobj.floatbob + 1) and FLOATBOBMASK;
      mobj.momz := mobj.momz + FloatBobOffsets[mobj.floatbob] div 4;
    end;
    if (mobj.z <> mobj.floorz) or (mobj.momz <> 0) then
    begin
      if mobj.flags2_ex and MF2_EX_PASSMOBJ <> 0 then
      begin
        onmo := P_CheckOnmobj(mobj);
        if onmo = nil then
          P_ZMovement(mobj)
        else
        begin
          if (mobj.player <> nil) and (mobj.momz < 0) then
          begin
            mobj.flags2_ex := mobj.flags2_ex or MF2_EX_ONMOBJ;
            mobj.momz := 0;
          end;
          if (mobj.player <> nil) and (onmo.player <> nil) then
          begin
            mobj.momx := onmo.momx;
            mobj.momy := onmo.momy;
            if onmo.z < onmo.floorz then
            begin
              mobj.z := mobj.z + onmo.floorz - onmo.z;
              if onmo.player <> nil then
              begin
                Pplayer_t(onmo.player).viewheight := Pplayer_t(onmo.player).viewheight - (onmo.floorz - onmo.z);
                Pplayer_t(onmo.player).deltaviewheight := (PVIEWHEIGHT - Pplayer_t(onmo.player).viewheight) div 8;
              end;
              onmo.z := onmo.floorz;
            end;
          end;
        end;
      end
      else
        P_ZMovement(mobj);

      if mobj.player <> nil then
        P_FixPlayerViewz(mobj.player);

      if not Assigned(mobj.thinker._function.acv) then
        exit; // mobj was removed
    end;
  end;


  // cycle through states,
  // calling action functions at transitions
  if mobj.tics <> -1 then
  begin
    mobj.tics := mobj.tics - 1;

    // you can cycle through multiple states in a tic
    if mobj.tics = 0 then
      if not P_SetMobjState(mobj, mobj.state.nextstate) then
        exit; // freed itself
  end
  else
  begin
    // check for nightmare respawn
    if mobj.flags and MF_COUNTKILL = 0 then
      exit;

    if not respawnmonsters then
      exit;

    mobj.movecount := mobj.movecount + 1;

    if mobj.movecount < 12 * TICRATE then
    begin
      exit;
    end;

    if leveltime and 31 <> 0 then
      exit;

    if P_Random > 4 then
      exit;

    P_NightmareRespawn(mobj);
  end;
end;

procedure P_MobjThinker(mobj: Pmobj_t);
begin
  // JVAL: 20200507 - Actual (real) velocity
  mobj.velx := mobj.x - mobj.oldx;
  mobj.vely := mobj.y - mobj.oldy;
  mobj.velz := mobj.z - mobj.oldz;

  // JVAL: 20200503 - Caclulate velocity
  mobj.velocityxy := P_AproxDistance(mobj.velx, mobj.vely);
  mobj.velocity := P_AproxDistance(mobj.velocityxy, mobj.velz);

  if mobj.flags and MF_JUSTAPPEARED = 0 then
    P_VelocityHandler(mobj);

  if mobj.player <> nil then
    RX_PlaneHitFloor(mobj.player);

  // JVAL: 20200503 - Keep previous tic position
  mobj.oldx := mobj.x;
  mobj.oldy := mobj.y;
  mobj.oldz := mobj.z;

  // JVAL: Clear just spawned flag
  mobj.flags := mobj.flags and not MF_JUSTAPPEARED;

  P_DoMobjThinker(mobj);

  if not Assigned(mobj.thinker._function.acv) then
    exit; // mobj was removed
end;

//
// P_SpawnMobj
//
function P_SpawnMobj(x, y, z: fixed_t; _type: integer; const mthing: Pmapthing_t = nil): Pmobj_t;
var
  mobj: Pmobj_t;
  st: Pstate_t;
  info: Pmobjinfo_t;
  i: integer;
  space: fixed_t;
  sec: Psector_t;
  msec: Psector_t;  // JVAL: 3d floors
  lowfloorheight, hifloorheight: fixed_t; // JVAL: 3d floors
  onmidfloor: Boolean;
  spawnfloorheight, spawnceilingheight: fixed_t;  // JVAL: Slopes
begin
  if _type < 0 then
  begin
    result := nil;
    exit;
  end;
  
  mobj := Z_Malloc(SizeOf(mobj_t), PU_LEVEL, nil);

  ZeroMemory(mobj, SizeOf(mobj_t));

  mobj.key := P_GenGlobalMobjKey;
  mobj.randseed := Sys_Random; // JVAL: 20200510 - Random seed

  info := @mobjinfo[_type];
  mobj._type := _type;
  mobj.info := info;
  mobj.x := x;
  mobj.y := y;
  mobj.radius := info.radius;
  mobj.height := info.height;
  // JVAL: Set MF_JUSTAPPEARED flag
  mobj.flags := info.flags or MF_JUSTAPPEARED;
  mobj.flags_ex := info.flags_ex;
  mobj.flags2_ex := info.flags2_ex;
  mobj.flags3_ex := info.flags3_ex;
  mobj.flags4_ex := info.flags4_ex;
  mobj.scale := info.scale;
  mobj.gravity := info.gravity;
  mobj.pushfactor := info.pushfactor;
  mobj.renderstyle := info.renderstyle;
  mobj.alpha := info.alpha;
  if (mobj.flags_ex and MF_EX_FLOATBOB <> 0) or (mobj.flags3_ex and MF3_EX_BOBING <> 0) then
    mobj.floatbob := N_Random and FLOATBOBMASK;
  mobj.health := info.spawnhealth;

  mobj.armour_inc := info.armour_inc;  // JVAL 20200321 - Armour inc for pickable objects
  mobj.energy_inc := info.energy_inc;  // JVAL 20200321 - Energy inc for pickable objects
  mobj.shield_inc := info.shield_inc;  // JVAL 20200321 - Shield inc for pickable objects
  mobj.armour_set := info.armour_set;  // JVAL 20200321 - Armour set for pickable objects
  mobj.energy_set := info.energy_set;  // JVAL 20200321 - Energy set for pickable objects
  mobj.shield_set := info.shield_set;  // JVAL 20200321 - Shield set for pickable objects
  for i := 0 to Ord(NUMAMMO) - 1 do
    mobj.ammo_inc[i] := info.ammo_inc[i]; // JVAL 20200321 - Ammo inc for pickable objects
  for i := 0 to Ord(NUMWEAPONS) - 1 do  // JVAL 20200321 - Weapon pickable objects
    mobj.weapon_inc[i] := info.weapon_inc[i];

  mobj.patrolrange := mobj.info.patrolrange;  // JVAL: 20200501 - Patrol Range

  if gameskill <> sk_nightmare then
    mobj.reactiontime := info.reactiontime;

  mobj.lastlook := P_Random mod MAXPLAYERS;
  // do not set the state with P_SetMobjState,
  // because action routines can not be called yet

  // Set the state, but do not use P_SetMobjState, because action
  // routines can't be called yet.  If the spawnstate has an action
  // routine, it will not be called.
  st := @states[info.spawnstate];

  mobj.state := st;
  mobj.prevstate := st;
  mobj.validcount := validcount;
  mobj.tics := P_TicsFromState(st);
  mobj.sprite := st.sprite;
  mobj.frame := st.frame;
  mobj.touching_sectorlist := nil; // NULL head of sector list // phares 3/13/98

  // set subsector and/or block links
  P_SetThingPosition(mobj);

  sec := Psubsector_t(mobj.subsector).sector;

  // JVAL: Slopes
  spawnfloorheight := P_FloorHeight(sec, x, y);
  spawnceilingheight := P_CeilingHeight(sec, x, y);
  mobj.floorz := spawnfloorheight;  // JVAL: Slopes
  mobj.ceilingz := spawnceilingheight;  // JVAL: Slopes
  onmidfloor := false;

// JVAL: 3d floors
  if sec.midsec >= 0 then
  begin
    msec := @sectors[sec.midsec];
    if mthing <> nil then
      if mthing.options and MTF_ONMIDSECTOR <> 0 then
        onmidfloor := true;
    if onmidfloor then
      mobj.floorz := msec.ceilingheight
    else if not onmidfloor and (z = ONCEILINGZ) then
      mobj.ceilingz := msec.floorheight
    else if z = ONFLOATZ then
    begin
      lowfloorheight := msec.floorheight - spawnfloorheight;  // JVAL: Slopes
      hifloorheight := spawnceilingheight - msec.ceilingheight; // JVAL: Slopes
      if lowfloorheight < mobj.info.height then
        mobj.floorz := msec.ceilingheight
      else if hifloorheight < mobj.info.height then
        mobj.ceilingz := msec.floorheight
      else if mthing = nil then
      begin
        if N_Random < Round(lowfloorheight / (lowfloorheight + hifloorheight) * 255) then
          mobj.ceilingz := msec.floorheight
        else
          mobj.floorz := msec.ceilingheight;
      end;
    end
    else
    begin
      if z > msec.floorheight then
        mobj.floorz := msec.ceilingheight
      else
        mobj.ceilingz := msec.floorheight;
    end;
  end
  else
    msec := nil;

  if z = ONFLOORZ then
    mobj.z := mobj.floorz
  else if z = ONCEILINGZ then
    mobj.z := mobj.ceilingz - mobj.info.height
  else if z = ONFLOATZ then
  begin
    space := mobj.ceilingz - mobj.info.height - mobj.floorz;
    if space > 48 * FRACUNIT then
    begin
      space := space - 40 * FRACUNIT;
      mobj.z := FixedMul(space, N_Random * 256) + mobj.floorz + 40 * FRACUNIT
    end
    else
      mobj.z := mobj.floorz
  end
  else
    mobj.z := z;

  if (msec <> nil) or (sec.renderflags and SRF_SLOPED <> 0) then  // JVAL: Slopes
  begin
    if mobj.z > mobj.ceilingz - mobj.info.height then
      mobj.z := mobj.ceilingz - mobj.info.height;
    if mobj.z < mobj.floorz then
      mobj.z := mobj.floorz;

    if (mobj.flags2_ex and MF2_EX_FLOORCLIP <> 0) and
       (P_GetThingFloorType(mobj) > FLOOR_SKY) and
       (mobj.z = mobj.floorz) then
      mobj.floorclip := FOOTCLIPSIZE
    else
      mobj.floorclip := 0;
  end
  else
  begin
    if (mobj.flags2_ex and MF2_EX_FLOORCLIP <> 0) and
       (P_GetThingFloorType(mobj) > FLOOR_SKY) and
       (mobj.z = sec.floorheight) then
      mobj.floorclip := FOOTCLIPSIZE
    else
      mobj.floorclip := 0;
  end;

  mobj.momz := mobj.info.vspeed;

  mobj.thinker._function.acp1 := @P_MobjThinker;

  P_AddThinker(@mobj.thinker);

  mobj.prevx := mobj.x;
  mobj.prevy := mobj.y;
  mobj.prevz := mobj.z;
  mobj.nextx := mobj.x;
  mobj.nexty := mobj.y;
  mobj.nextz := mobj.z;
  mobj.prevangle := mobj.angle;
  mobj.nextangle := mobj.angle;
  mobj.intrplcnt := 0;

  result := mobj;
end;

function P_SpawnPlayerMissileMobj(x, y, z: fixed_t; _type: integer): Pmobj_t;
var
  mobj: Pmobj_t;
  st: Pstate_t;
  info: Pmobjinfo_t;
  i: integer;
  space: fixed_t;
  sec: Psector_t;
  msec: Psector_t;  // JVAL: 3d floors
  lowfloorheight, hifloorheight: fixed_t; // JVAL: 3d floors
  spawnfloorheight, spawnceilingheight: fixed_t;  // JVAL: Slopes
begin
  if _type < 0 then
  begin
    result := nil;
    exit;
  end;

  mobj := Z_Malloc(SizeOf(mobj_t), PU_LEVEL, nil);

  ZeroMemory(mobj, SizeOf(mobj_t));

  mobj.key := P_GenGlobalMobjKey;

  info := @mobjinfo[_type];
  mobj._type := _type;
  mobj.info := info;
  mobj.x := x;
  mobj.y := y;
  mobj.radius := info.radius;
  mobj.height := info.height;
// JVAL: Set MF_JUSTAPPEARED flag
  mobj.flags := info.flags or MF_JUSTAPPEARED;
  mobj.flags_ex := info.flags_ex;
  mobj.flags2_ex := info.flags2_ex;
  mobj.flags3_ex := info.flags3_ex;
  mobj.flags4_ex := info.flags4_ex;
  mobj.scale := info.scale;
  mobj.gravity := info.gravity;
  mobj.pushfactor := info.pushfactor;
  mobj.renderstyle := info.renderstyle;
  mobj.alpha := info.alpha;
  if (mobj.flags_ex and MF_EX_FLOATBOB <> 0) or (mobj.flags3_ex and MF3_EX_BOBING <> 0) then
    mobj.floatbob := N_Random and FLOATBOBMASK;
  mobj.health := info.spawnhealth;

  mobj.armour_inc := info.armour_inc;  // JVAL 20200321 - Armour inc for pickable objects
  mobj.energy_inc := info.energy_inc;  // JVAL 20200321 - Energy inc for pickable objects
  mobj.shield_inc := info.shield_inc;  // JVAL 20200321 - Shield inc for pickable objects
  mobj.armour_set := info.armour_set;  // JVAL 20200321 - Armour set for pickable objects
  mobj.energy_set := info.energy_set;  // JVAL 20200321 - Energy set for pickable objects
  mobj.shield_set := info.shield_set;  // JVAL 20200321 - Shield set for pickable objects
  for i := 0 to Ord(NUMAMMO) - 1 do
    mobj.ammo_inc[i] := info.ammo_inc[i]; // JVAL 20200321 - Ammo inc for pickable objects
  for i := 0 to Ord(NUMWEAPONS) - 1 do  // JVAL 20200321 - Weapon pickable objects
    mobj.weapon_inc[i] := info.weapon_inc[i];

  mobj.patrolrange := mobj.info.patrolrange;  // JVAL: 20200501 - Patrol Range

  if gameskill <> sk_nightmare then
    mobj.reactiontime := info.reactiontime;

  mobj.lastlook := P_Random mod MAXPLAYERS;
  // do not set the state with P_SetMobjState,
  // because action routines can not be called yet

  // Set the state, but do not use P_SetMobjState, because action
  // routines can't be called yet.  If the spawnstate has an action
  // routine, it will not be called.
  st := @states[info.spawnstate];

  mobj.state := st;
  mobj.prevstate := st;
  mobj.validcount := validcount;
  mobj.tics := P_TicsFromState(st);
  mobj.sprite := st.sprite;
  mobj.frame := st.frame;
  mobj.touching_sectorlist := nil; // NULL head of sector list // phares 3/13/98

  // set subsector and/or block links
  P_SetThingPosition(mobj);

  sec := Psubsector_t(mobj.subsector).sector;

  // JVAL: Slopes
  spawnfloorheight := P_FloorHeight(sec, x, y);
  spawnceilingheight := P_CeilingHeight(sec, x, y);
  mobj.floorz := spawnfloorheight;  // JVAL: Slopes
  mobj.ceilingz := spawnceilingheight;  // JVAL: Slopes

// JVAL: 3d floors
  if sec.midsec >= 0 then
  begin
    msec := @sectors[sec.midsec];
    if z = ONCEILINGZ then
      mobj.ceilingz := msec.floorheight
    else if z = ONFLOATZ then
    begin
      lowfloorheight := msec.floorheight - spawnfloorheight;  // JVAL: Slopes
      hifloorheight := spawnceilingheight - msec.ceilingheight; // JVAL: Slopes
      if lowfloorheight < mobj.info.height then
        mobj.floorz := msec.ceilingheight
      else if hifloorheight < mobj.info.height then
        mobj.ceilingz := msec.floorheight
      else
      begin
        if N_Random < Round(lowfloorheight / (lowfloorheight + hifloorheight) * 255) then
          mobj.ceilingz := msec.floorheight
        else
          mobj.floorz := msec.ceilingheight;
      end;
    end
    else
    begin
      if z > msec.floorheight then
        mobj.floorz := msec.ceilingheight
      else
        mobj.ceilingz := msec.floorheight;
    end;
  end;

  if z = ONFLOORZ then
    mobj.z := mobj.floorz
  else if z = ONCEILINGZ then
    mobj.z := mobj.ceilingz - mobj.info.height
  else if z = ONFLOATZ then
  begin
    space := mobj.ceilingz - mobj.info.height - mobj.floorz;
    if space > 48 * FRACUNIT then
    begin
      space := space - 40 * FRACUNIT;
      mobj.z := FixedMul(space, N_Random * 256) + mobj.floorz + 40 * FRACUNIT
    end
    else
      mobj.z := mobj.floorz
  end
  else
    mobj.z := z;

  if (mobj.flags2_ex and MF2_EX_FLOORCLIP <> 0) and
     (P_GetThingFloorType(mobj) > FLOOR_SKY) and
     (mobj.z = sec.floorheight) then
    mobj.floorclip := FOOTCLIPSIZE
  else
    mobj.floorclip := 0;

  mobj.momz := mobj.info.vspeed;

  mobj.thinker._function.acp1 := @P_MobjThinker;

  P_AddThinker(@mobj.thinker);

  mobj.oldx := mobj.x;
  mobj.oldy := mobj.y;
  mobj.oldz := mobj.z;
  mobj.prevx := mobj.x;
  mobj.prevy := mobj.y;
  mobj.prevz := mobj.z;
  mobj.nextx := mobj.x;
  mobj.nexty := mobj.y;
  mobj.nextz := mobj.z;
  mobj.prevangle := mobj.angle;
  mobj.nextangle := mobj.angle;
  mobj.intrplcnt := 0;

  result := mobj;
end;

//
// P_RemoveMobj
//
const
// Time interval for item respawning.
  ITEMQUESIZE = 128;

var
  itemrespawnque: array[0..ITEMQUESIZE - 1] of mapthing_t;
  itemrespawntime: array[0..ITEMQUESIZE - 1] of integer;

procedure P_RemoveMobj(mobj: Pmobj_t);
begin
  if ((mobj.flags and MF_SPECIAL) <> 0) and
     ((mobj.flags and MF_DROPPED) = 0) and
     (mobj._type <> Ord(MT_INV)) and
     (mobj._type <> Ord(MT_INS)) then
  begin
    itemrespawnque[iquehead] := mobj.spawnpoint;
    itemrespawntime[iquehead] := leveltime;
    iquehead := (iquehead + 1) and (ITEMQUESIZE - 1);

    // lose one off the end?
    if iquehead = iquetail then
      iquetail := (iquetail + 1) and (ITEMQUESIZE - 1);
  end;

  // unlink from sector and block lists
  P_UnsetThingPosition(mobj);

  // Delete all nodes on the current sector_list               phares 3/16/98

  if sector_list <> nil then
    while sector_list <> nil do
      sector_list := P_DelSecnode(sector_list);

  // stop any playing sound
  S_StopSound(mobj);

  P_RemoveMobjCustomParams(mobj.customparams);

  // free block
  P_RemoveThinker(Pthinker_t(mobj));
end;

//
// P_RespawnSpecials
//
procedure P_RespawnSpecials;
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psubsector_t;
  mo: Pmobj_t;
  mthing: Pmapthing_t;
  i: integer;
begin
  // only respawn items in deathmatch
  if deathmatch <> 2 then
    exit; //

  // nothing left to respawn?
  if iquehead = iquetail then
    exit;

  // wait at least 30 seconds
  if leveltime - itemrespawntime[iquetail] < 30 * TICRATE then
    exit;

  mthing := @itemrespawnque[iquetail];

  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  // spawn a teleport fog at the new spot
  ss := R_PointInSubsector(x, y);
  mo := P_SpawnMobj(x, y, ss.sector.floorheight, Ord(MT_IFOG), mthing);  // JVAL: Slopes
  if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
    S_StartSound(mo, Ord(sfx_itmbk));

  // find which type to spawn
  i := 0;
  while i < nummobjtypes do
  begin
    if mthing._type = mobjinfo[i].doomednum then
      break;
    inc(i);
  end;

  // spawn it
  if mobjinfo[i].flags and MF_SPAWNCEILING <> 0 then
    z := ONCEILINGZ
  else if mobjinfo[i].flags_ex and MF_EX_SPAWNFLOAT <> 0 then
    z := ONFLOATZ
  else
    z := ONFLOORZ;

  mo := P_SpawnMobj(x, y, z, i, mthing);
  mo.spawnpoint := mthing^;
  if mo.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    mo.angle := ANG1 * mthing.angle
  else
    mo.angle := ANG45 * (mthing.angle div 45);

  // pull it from the que
  iquetail := (iquetail + 1) and (ITEMQUESIZE - 1);
end;

//
// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.
//
function P_SpawnPlayer(mthing: Pmapthing_t): Pmobj_t;
var
  p: Pplayer_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  i: integer;
  plnum: integer;
  ss: Psubsector_t;
  rnd: integer;
begin
  // not playing?
  if not playeringame[mthing._type - 1] then
  begin
    result := nil;
    exit;
  end;

  plnum := mthing._type - 1;
  p := @players[plnum];

  if plnum = consoleplayer then
    p.playername := pilotname;

  if p.playerstate = PST_REBORN then
    G_PlayerReborn(plnum)
  else
  begin
    // JVAL: 20200509 - New map player clean-up
    p.angletargetx := 0;
    p.angletargety := 0;
    p.angletargetticks := 0;
    p.laddertics := 0;
    p.slopetics := 0;
    p.oldviewz := 0;
    p.teleporttics := 0;
    p.quaketics := 0;
    p.quakeintensity := 0;
    p.last_grid_trigger := 0;
    p.planehittics := 0;
    p.floorslidetics := 0;
    p.plinetarget := nil;
    p.pcrosstic := 0;
    p.enginesoundtarget := nil;
    p.messagesoundtarget := nil;
    p.planetranspo_start_x := 0;
    p.planetranspo_start_y := 0;
    p.planetranspo_start_z := 0;
    p.planetranspo_start_a := 0;
    p.planetranspo_target_x := 0;
    p.planetranspo_target_y := 0;
    p.planetranspo_target_z := 0;
    p.planetranspo_target_a := 0;
    p.planetranspo_start_tics := 0;
    p.planetranspo_tics := 0;
    for i := 0 to NUMRADIXMESSAGES - 1 do
      p.radixmessages[i] := 0;
    for i := 0 to Ord(NUMWEAPONS) - 1 do
      p.lastfire[i] := 0;
    RX_ClearPlayerHistory(p);
  end;

  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  ss := R_PointInSubsector(x, y);

  if mthing.options and MTF_RADIXTHING <> 0 then
  begin
    z := mthing.z * FRACUNIT;

    // JVAL: 20200428 - Spawn Player Position
    if z < ss.sector.floorheight then
      z := ss.sector.floorheight
    else if z > ss.sector.ceilingheight - mobjinfo[Ord(MT_PLAYER)].height then
      z := ss.sector.ceilingheight - mobjinfo[Ord(MT_PLAYER)].height;
  end
  else
  begin
    if mthing.options and MTF_SPAWNMIDFLOAT <> 0 then
    // JVAL: 20200517 - Spawn float (for no gravity enemies and player)
    //       Do not leave FLOATZ since P_SpawnMobj will set z to random
      z := P_FloorHeight(ss.sector, x, y) div 2 + P_CeilingHeight(ss.sector, x, y) div 2
    else if mthing.options and MTF_SPAWNRANDOMFLOAT <> 0 then
    begin
      rnd := P_Random;
      z := (P_FloorHeight(ss.sector, x, y) div 256) * rnd + (P_CeilingHeight(ss.sector, x, y) div 256 * (256 - rnd));
    end
    else
      z := P_FloorHeight(ss.sector, x, y);
    // JVAL: 20191209 - 3d floors - Fixed Player spawned in 3d floor
    if ss.sector.midsec >= 0 then
      if mthing.options and MTF_ONMIDSECTOR <> 0 then
        z := sectors[ss.sector.midsec].ceilingheight;
  end;
  
  result := P_SpawnMobj(x, y, z, Ord(MT_PLAYER), @mthing);

  // set color translations for player sprites
  if mthing._type > 1 then
    result.flags := result.flags or _SHL(plnum, MF_TRANSSHIFT);

  if result.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    result.angle := ANG1 * mthing.angle
  else
    result.angle := ANG45 * (mthing.angle div 45);
  result.player := p;
  result.health := p.health;
  result.customparams := nil; // JVAL: Should keep the old params!

  p.mo := result;
  p.playerstate := PST_LIVE;
  p.refire := 0;
  p._message := RX_StartUpMessage(gameepisode, gamemap); // JVAL: 20200514 - Startup player messages
  p.damagecount := 0;
  p.bonuscount := 0;
  p.extralight := 0;
  p.fixedcolormap := 0;
  p.viewheight := PVIEWHEIGHT;

  // setup gun psprite
  P_SetupPsprites(p);

  // give all cards in death match mode
  if deathmatch <> 0 then
    for i := 0 to Ord(NUMCARDS) - 1 do
      p.cards[i] := true;

  if plnum = consoleplayer then
  begin
    // wake up the status bar
    ST_Start;
    // wake up the heads up text
    HU_Start;

    p_justspawned := true;
  end;
end;

//
// P_SpawnMapThing
// The fields of the mapthing should
// already be in host byte order.
//
var
  helperdrone_id: integer = -1;

function P_SpawnMapThing(mthing: Pmapthing_t): Pmobj_t;
var
  i: integer;
  bit: integer;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psubsector_t; // JVAL: 3d floors
  msec: Psector_t;  // JVAL: 3d floors
  musinfoparam: integer;
  doplayerz: boolean;
begin
  mthing.options := mthing.options and spawnmask;

  // Count deathmatch start positions
  if mthing._type = 11 then
  begin
    if deathmatch_p < MAX_DEATHMATCH_STARTS then
    begin
      memcpy(@deathmatchstarts[deathmatch_p], mthing, SizeOf(mthing^));
      inc(deathmatch_p);
    end;
    result := nil;
    exit;
  end;

  // phares 5/14/98: Ignore Player 5-8 starts (for now)
  if (mthing._type = DEN_PLAYER5) or
     (mthing._type = DEN_PLAYER6) or
     (mthing._type = DEN_PLAYER7) or
     (mthing._type = DEN_PLAYER8) then
  begin
    result := nil;
    exit;
  end;

  // check for players specially
  doplayerz := false;
  if mthing._type <= 4 then
  begin
    // save spots for respawning in network games
    if not netgame and (mthing._type > 1) and (mthing._type <= helperdrones + 1) then
    begin
      // use secretcount to avoid multiple dogs in case of multiple starts
      players[mthing._type - 1].secretcount := 1;
      if helperdrone_id < 0 then
        helperdrone_id := Info_GetMobjNumForName('MT_HELPERDRONE');
      mthing._type := mobjinfo[helperdrone_id].doomednum;
      if mthing._type <= 0 then
      begin
        result := nil;
        exit;
      end;
      mthing.options := mthing.options or MTF_FRIEND;
      doplayerz := true;
    end
    else
    begin
      playerstarts[mthing._type - 1] := mthing^;
      if deathmatch = 0 then
        result := P_SpawnPlayer(mthing)
      else
        result := nil;
      exit;
    end;
  end;

  if mthing.options and MTF_RADIXTHING <> 0 then
  begin
    if mthing.radix_skill > Ord(gameskill) then
    begin
      if netgame then
      begin
        if mthing.radix_skill <> 4 then
        begin
          result := nil;
          exit;
        end;
      end
      else
      begin
        result := nil;
        exit;
      end;
    end;
  end
  else
  begin
    // check for apropriate skill level
    if not netgame and (mthing.options and 16 <> 0) then
    begin
      result := nil;
      exit;
    end;

    //jff 3/30/98 implement "not deathmatch" thing flag
    if netgame and (deathmatch <> 0) and (mthing.options and 32 <> 0) then
    begin
      result := nil;
      exit;
    end;

    //jff 3/30/98 implement "not cooperative" thing flag
    if netgame and (deathmatch = 0) and (mthing.options and 64 <> 0) then
    begin
      result := nil;
      exit;
    end;

    if gameskill = sk_baby then
      bit := 1
    else if gameskill = sk_nightmare then
      bit := 4
    else
      bit := _SHL(1, Ord(gameskill) - 1);

    if mthing.options and bit = 0 then
    begin
      result := nil;
      exit;
    end;
  end;

  musinfoparam := -1;
  if (mthing._type >= MUSICCHANGER_LO) and (mthing._type <= MUSICCHANGER_HI) then
  begin
    musinfoparam := mthing._type - MUSICCHANGER_LO;
    mthing._type := MUSICCHANGER;
  end;

  // find which type to spawn
  i := Info_GetMobjNumForDoomNum(mthing._type);
  if i < 0 then
  begin
    I_Warning('P_SpawnMapThing(): Unknown type %d at (%d, %d)'#13#10,
      [mthing._type, mthing.x, mthing.y]);
    i := Info_GetMobjNumForName('UNKNOWN');
    if i < 0 then
    begin
      result := nil;
      exit;
    end;
  end;

  // don't spawn keycards and players in deathmatch
  if (deathmatch <> 0) and (mobjinfo[i].flags and MF_NOTDMATCH <> 0) then
  begin
    result := nil;
    exit;
  end;

  // don't spawn any monsters if -nomonsters
  if nomonsters and
    ((i = Ord(MT_SKULL)) or (mobjinfo[i].flags and MF_COUNTKILL <> 0)) then
  begin
    result := nil;
    exit;
  end;

  // spawn it
  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  // JVAL
  // Random map enemies
  if spawnrandommonsters and Info_IsMonster(i) and (mthing.options and MTF_FRIEND = 0) and (mobjinfo[i].flags2_ex and MF2_EX_FRIEND = 0) then
    i := Info_SelectRandomMonster(i);

  if mthing.options and MTF_RADIXTHING <> 0 then
  begin
    if doplayerz then
      z := mthing.z * FRACUNIT
    else
    begin
      ss := R_PointInSubsector(x, y);
      z := ss.sector.floorheight + integer(mthing.z) * FRACUNIT;
    end;
    result := P_SpawnMobj(x, y, z, i, mthing);
  end
  else
  begin
    // JVAL: 20200517 - Spawn float (for no gravity enemies and player)
    if mthing.options and (MTF_SPAWNMIDFLOAT or MTF_SPAWNRANDOMFLOAT) <> 0 then
      z := ONFLOATZ
    else if mobjinfo[i].flags and MF_SPAWNCEILING <> 0 then
      z := ONCEILINGZ
    else if mobjinfo[i].flags_ex and MF_EX_SPAWNFLOAT <> 0 then
      z := ONFLOATZ
    else
      z := ONFLOORZ;

    // JVAL: 3d floors
    ss := R_PointInSubsector(x, y);
    if ss.sector.midsec >= 0 then
    begin
      msec := @sectors[ss.sector.midsec];
      if mthing.options and MTF_ONMIDSECTOR <> 0 then
      begin
        if z = ONFLOATZ then
          z := (msec.ceilingheight + P_CeilingHeight(ss.sector, x, y)) div 2
        else if z = ONFLOORZ then
          z := msec.ceilingheight;
      end
      else
      begin
        if z = ONFLOATZ then
          z := (P_FloorHeight(ss.sector, x, y) + msec.floorheight) div 2
        else if z = ONCEILINGZ then
          z := msec.floorheight;
      end;
    end
    else if mthing.options and MTF_SPAWNMIDFLOAT <> 0 then
    // JVAL: 20200517 - Spawn float (for no gravity enemies and player)
    //       Do not leave FLOATZ since P_SpawnMobj will set z to random
      z := P_FloorHeight(ss.sector, x, y) div 2 + P_CeilingHeight(ss.sector, x, y) div 2;
    result := P_SpawnMobj(x, y, z, i, mthing);
  end;

  result.spawnpoint := mthing^;

  if mthing.options and MTF_FRIEND <> 0 then
    result.flags2_ex := result.flags2_ex or MF2_EX_FRIEND;

  if musinfoparam >= 0 then
    P_SetMobjCustomParam(result, S_MUSINFO_PARAM, musinfoparam);

  if result.tics > 0 then
    result.tics := 1 + (P_Random mod result.tics);
  if result.flags and MF_COUNTKILL <> 0 then
  begin
    inc(totalkills);
    // JVAL: 20200429 - To compensate for dead enemies that the player didn't kill
    if mthing.options and MTF_RADIXTHING <> 0 then
      inc(totalradixkills);
  end;
  if result.flags and MF_COUNTITEM <> 0 then
    inc(totalitems);

  if result.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    result.angle := ANG1 * mthing.angle
  else
    result.angle := ANG45 * (mthing.angle div 45);
  if mthing.options and MTF_AMBUSH <> 0 then
    result.flags := result.flags or MF_AMBUSH;
  // JVAL: 20200517 - Inactive (stub) enemies
  if mthing.options and MTF_INACTIVE <> 0 then
    result.flags3_ex := result.flags3_ex or MF3_EX_INACTIVE;
end;

//
// GAME SPAWN FUNCTIONS
//


//
// P_SpawnPuff
//
var
  radixfireballpuff_id: integer = -1;

procedure P_SpawnPuff(x, y, z: fixed_t);
var
  th: Pmobj_t;
begin
  if radixfireballpuff_id < 0 then
    radixfireballpuff_id := Info_GetMobjNumForName('MT_RADIXFIREBALLPUFF');

  z := z + _SHL(P_Random - P_Random, 10);

  th := P_SpawnMobj(x, y, z, radixfireballpuff_id);
  th.momz := FRACUNIT;
end;

//
// P_SpawnBlood
//
procedure P_SpawnBlood(x, y, z: fixed_t; damage: integer);
var
  th: Pmobj_t;
begin
  z := z + _SHL(P_Random - P_Random, 10);
  th := P_SpawnMobj(x, y, z, Ord(MT_BLOOD));
  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (P_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if (damage <= 12) and (damage >= 9) then
    P_SetMobjState(th, S_BLOOD2)
  else if damage < 9 then
    P_SetMobjState(th, S_BLOOD3);
end;

procedure P_SpawnGreenBlood(x, y, z: fixed_t; damage: integer);
var
  th: Pmobj_t;
begin
  z := z + _SHL(N_Random - N_Random, 10);
  th := P_SpawnMobj(x, y, z, Ord(MT_GREENBLOOD));
  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (N_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if (damage <= 12) and (damage >= 9) then
    P_SetMobjState(th, S_GREENBLOOD2)
  else if damage < 9 then
    P_SetMobjState(th, S_GREENBLOOD3);
end;

procedure P_SpawnBlueBlood(x, y, z: fixed_t; damage: integer);
var
  th: Pmobj_t;
begin
  z := z + _SHL(N_Random - N_Random, 10);
  th := P_SpawnMobj(x, y, z, Ord(MT_BLUEBLOOD));
  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (N_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if (damage <= 12) and (damage >= 9) then
    P_SetMobjState(th, S_BLUEBLOOD2)
  else if damage < 9 then
    P_SetMobjState(th, S_BLUEBLOOD3);
end;


//
// P_CheckMissileSpawn
// Moves the missile forward a bit
//  and possibly explodes it right there.
//
function P_CheckMissileSpawn(th: Pmobj_t): boolean;
var
  maxmom: fixed_t;
  dx, dy, dz: fixed_t;
  dxstep, dystep, dzstep: fixed_t;
  xtest, ytest, ztest: fixed_t;
  i: integer;
  steps: integer;
  halfradius: fixed_t;
begin
  th.tics := th.tics - (P_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if th.radius < 2 * FRACUNIT then
    halfradius := FRACUNIT
  else
    halfradius := th.radius div 2;
  maxmom := Max3I(abs(th.momx), abs(th.momy), abs(th.momz));
  if maxmom > 64 * FRACUNIT then
  begin
    dx := FixedMul(th.momx, FixedDiv(64 * FRACUNIT, maxmom)) div 2;
    dy := FixedMul(th.momy, FixedDiv(64 * FRACUNIT, maxmom)) div 2;
    dz := FixedMul(th.momz, FixedDiv(64 * FRACUNIT, maxmom)) div 2;
    maxmom := 64 * FRACUNIT;
  end
  else
  begin
    dx := th.momx div 2;
    dy := th.momy div 2;
    dz := th.momz div 2;
  end;

  steps := maxmom div halfradius + 1;

  dxstep := dx div steps;
  dystep := dy div steps;
  dzstep := dz div steps;

  xtest := th.x;
  ytest := th.y;
  ztest := th.z;

  // move a little forward so an angle can
  // be computed if it immediately explodes
  for i := 0 to steps - 1 do
  begin
    inc(xtest, dxstep);
    inc(ytest, dystep);
    inc(ztest, dzstep);
    // JVAL: 20200501 - Extra missile check
    if not P_PtInAir(xtest, ytest, ztest, th.radius div 2) then
    begin
      // JVAL: 20200502 - Position between valid and invalid point
      th.x := xtest - dxstep div 2;
      th.y := ytest - dystep div 2;
      th.z := ztest - dzstep div 2;
      // Step back if invalid position
      if not P_PtInAir(th.x, th.y, th.y, th.radius div 2) then
      begin
        th.x := th.x - dxstep div 2;
        th.y := th.y - dystep div 2;
        th.z := th.z - dzstep div 2;
      end;
      P_ExplodeMissile(th);
      result := false;
      exit;
    end;
  end;

  th.x := th.x + dx;
  th.y := th.y + dy;
  th.z := th.z + dz;

  if not P_TryMove(th, th.x, th.y) then
  begin
    P_ExplodeMissile(th);
    result := false;
  end
  else
    result := true;
end;

//
// P_SpawnMissile
//

function P_SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  dist: integer;
  z: fixed_t;
begin
  // JVAL: Prevent savegame bug
  if (dest = nil) or (source = nil) then
  begin
    result := nil;
    exit;
  end;

  if source.info.missileheight = 0 then
    z := source.z + 4 * 8 * FRACUNIT
  else if source.info.missileheight < FRACUNIT div 2 then
    z := source.z + source.info.missileheight * FRACUNIT
  else
    z := source.z + source.info.missileheight;

  if source.flags3_ex and MF3_EX_NOADJUSTMISSILECEILING = 0 then
    if z + source.info.height > source.ceilingz - 4 * FRACUNIT then
      z := source.ceilingz - 4 * FRACUNIT - source.info.height;

  th := P_SpawnMobj(source.x, source.y, z, _type);

  A_SeeSound(th, th);

  th.target := source;  // where it came from
  an := R_PointToAngle2(source.x, source.y, dest.x, dest.y);

  // fuzzy player
  if dest.flags and MF_SHADOW <> 0 then
    if source.flags2_ex and MF2_EX_SEEINVISIBLE = 0 then
      an := an + _SHLW(P_Random - P_Random, 20);

  th.angle := an;
  {$IFDEF FPC}
  an := _SHRW(an, ANGLETOFINESHIFT);
  {$ELSE}
  an := an shr ANGLETOFINESHIFT;
  {$ENDIF}
  th.momx := FixedMul(th.info.speed, finecosine[an]);
  th.momy := FixedMul(th.info.speed, finesine[an]);

  if IsIntegerInRange(th.z, dest.z, dest.z + dest.height) then
    th.momz := 0
  else
  begin
    dist := P_AproxDistance(dest.x - source.x, dest.y - source.y);
    // JVAL: If forgot to set custom missile speed we use default (12 * FRACUNIT)
    if th.info.speed = 0 then
      dist := dist div (12 * FRACUNIT)
    else
      dist := dist div th.info.speed;

    if dist < 1 then
      dist := 1;

    th.momz := (dest.z + dest.height div 2 - th.z) div dist;
  end;

  P_CheckMissileSpawn(th);

  result := th;
end;

function P_SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
var
  flags_ex: integer;
  th: Pmobj_t;
  velocity: vec3_t;
  speed: float;
  an: angle_t;
begin
  P_SaveRandom;

  flags_ex := mobjinfo[Ord(_type)].flags_ex;

  if flags_ex and MF_EX_FLOORHUGGER <> 0 then
    z := source.floorz
  else if flags_ex and MF_EX_CEILINGHUGGER <> 0 then
    z := source.ceilingz
  else if z <> ONFLOORZ then
    z := z - source.floorz;

  th := P_SpawnMobj(x, y, z, _type);

  A_SeeSound(th, th);

  th.target := source;  // record missile's originator

  speed := th.info.speed;

  velocity[0] := dest.x - source.x;
  velocity[1] := dest.y - source.y;
  // Floor and ceiling huggers should never have a vertical component to their velocity
  if flags_ex and (MF_EX_FLOORHUGGER or MF_EX_CEILINGHUGGER) <> 0 then
    velocity[2] := 0.0
  else
  begin
    velocity[2] := dest.z - source.z;
    if dest.height <= z - source.z then
      velocity[2] := velocity[2] + dest.height - z + source.z;
  end;

  VectorNormalize(@velocity);
  th.momx := round(velocity[0] * speed);
  th.momy := round(velocity[1] * speed);
  th.momz := round(velocity[2] * speed);

  // fuzzy player
  if dest.flags and MF_SHADOW <> 0 then
    if source.flags2_ex and MF2_EX_SEEINVISIBLE = 0 then
    begin
      an := _SHLW(P_Random - P_Random, 20);
      an := an shr ANGLETOFINESHIFT;
      th.momx := th.momx + FixedMul(th.info.speed, finecosine[an]);
      th.momy := th.momy + FixedMul(th.info.speed, finesine[an]);
    end;

  th.angle := R_PointToAngle2(0, 0, th.momx, th.momy);

  if P_CheckMissileSpawn(th) then
    result := th
  else
    result := nil;

  P_RestoreRandom;
end;

function P_SpawnMissileAngleZSpeed(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t; owner: Pmobj_t): Pmobj_t;
var
  mo: Pmobj_t;
  flags_ex: integer;
begin
  P_SaveRandom;

  flags_ex := mobjinfo[Ord(_type)].flags_ex;

  if flags_ex and MF_EX_FLOORHUGGER <> 0 then
    z := source.floorz
  else if flags_ex and MF_EX_CEILINGHUGGER <> 0 then
    z := source.ceilingz
  else if z <> ONFLOORZ then
    z := z - source.floorz;

  mo := P_SpawnMobj(source.x, source.y, z, _type);

  A_SeeSound(mo, mo);

  if owner <> nil then
    mo.target := owner
  else
    mo.target := source;  // Originator
  mo.angle := angle;
  angle := angle shr ANGLETOFINESHIFT;
  mo.momx := FixedMul(speed, finecosine[angle]);
  mo.momy := FixedMul(speed, finesine[angle]);
  mo.momz := momz;
  if P_CheckMissileSpawn(mo) then
    result := mo
  else
    result := nil;

  P_RestoreRandom;
end;

function P_SpawnMissileAngleZ(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t): Pmobj_t;
begin
  result := P_SpawnMissileAngleZSpeed(source, z, _type, angle, momz, mobjinfo[Ord(_type)].speed, nil);
end;

//
// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
//
procedure P_SpawnPlayerMissile(source: Pmobj_t; _type: integer);
var
  th: Pmobj_t;
  an: angle_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  slope: fixed_t;
  speed: fixed_t;
begin
  // see which target is to be aimed at
  an := source.angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

  if linetarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

    if linetarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

      if linetarget = nil then
      begin
        an := source.angle;
        slope := (Pplayer_t(source.player).lookdir16 * (FRACUNIT div 16)) div 173;
      end;

    end;
  end;

  x := source.x;
  y := source.y;
  // Also z axis shift calculation
  if zaxisshift then
    z := source.z + 4 * 8 * FRACUNIT + (Pplayer_t(source.player).lookdir16 * (FRACUNIT div 16)) div 173
  else
    z := source.z + 4 * 8 * FRACUNIT;

  th := P_SpawnMobj(x, y, z, _type);

  A_SeeSound(th, th);

  th.target := source;
  th.angle := an;
  an := an shr ANGLETOFINESHIFT;
  speed := th.info.speed;
  th.momx := FixedMul(speed, finecosine[an]);
  th.momy := FixedMul(speed, finesine[an]);
  th.momz := FixedMul(speed, slope);

  P_CheckMissileSpawn(th);
end;

// JVAL: 20200422 - New function
procedure P_SpawnRadixPlayerMissile(source: Pmobj_t; _type: integer);
var
  th: Pmobj_t;
  an: angle_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  slope: fixed_t;
  speed: fixed_t;
begin
  // see which target is to be aimed at
  an := source.angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

  if linetarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

    if linetarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

      if linetarget = nil then
      begin
        an := source.angle;
        slope := (Pplayer_t(source.player).lookdir16 * (FRACUNIT div 16)) div 173;
      end;

    end;
  end;

  x := source.x;
  y := source.y;
  z := source.z;

  th := P_SpawnPlayerMissileMobj(x, y, z, _type);

  A_SeeSound(th, th);

  th.target := source;
  th.angle := an;
  an := an shr ANGLETOFINESHIFT;
  speed := th.info.speed;
  th.momx := FixedMul(speed, finecosine[an]);
  th.momy := FixedMul(speed, finesine[an]);
  th.momz := FixedMul(speed, slope);

  P_CheckMissileSpawn(th);
end;

//----------------------------------------------------------------------------
//
// FUNC P_FaceMobj
//
// Returns 1 if 'source' needs to turn clockwise, or 0 if 'source' needs
// to turn counter clockwise.  'delta' is set to the amount 'source'
// needs to turn.
//
//----------------------------------------------------------------------------
function P_FaceMobj(source: Pmobj_t; target: Pmobj_t; var delta: angle_t): integer;
var
  diff: angle_t;
  angle1: angle_t;
  angle2: angle_t;
begin
  angle1 := source.angle;
  angle2 := R_PointToAngle2(source.x, source.y, target.x, target.y);
  if angle2 > angle1 then
  begin
    diff := angle2 - angle1;
    if diff > ANG180 then
    begin
      delta := ANGLE_MAX - diff;
      result := 0;
    end
    else
    begin
      delta := diff;
      result := 1;
    end;
  end
  else
  begin
    diff := angle1 - angle2;
    if diff > ANG180 then
    begin
      delta := ANGLE_MAX - diff;
      result := 1;
    end
    else
    begin
      delta := diff;
      result := 0;
    end;
  end;
end;

//----------------------------------------------------------------------------
//
// FUNC P_SeekerMissile
//
// The missile's tracer field must be the target.  Returns true if
// target was tracked, false if not.
//
//----------------------------------------------------------------------------
function P_SeekerMissile(actor: Pmobj_t; thresh, turnMax: angle_t): boolean;
var
  dir: integer;
  dist: integer;
  delta: angle_t;
  angle: angle_t;
  target: Pmobj_t;
  speed: fixed_t;
begin
  target := actor.tracer;
  speed := P_AproxDistance(actor.momx, actor.momy);
  if (target = nil) or (speed = 0) then
  begin
    result := false;
    exit;
  end;

  if target.flags and MF_SHOOTABLE = 0 then
  begin // Target died
    actor.tracer := nil;
    result := false;
    exit;
  end;

  dir := P_FaceMobj(actor, target, delta);
  if delta > thresh then
  begin
    delta := delta shr 1;
    if delta > turnMax then
      delta := turnMax;
  end;

  if dir <> 0 then
  begin // Turn clockwise
    actor.angle := actor.angle + delta;
  end
  else
  begin // Turn counter clockwise
    actor.angle := actor.angle - delta;
  end;

  angle := actor.angle shr ANGLETOFINESHIFT;
  actor.momx := FixedMul(speed, finecosine[angle]);
  actor.momy := FixedMul(speed, finesine[angle]);
  if (actor.z + actor.height < target.z) or
     (target.z + target.height < actor.z) then
  begin // Need to seek vertically
    dist := P_AproxDistance(target.x - actor.x, target.y - actor.y);
    dist := dist div speed;
    if dist < 1 then
      dist := 1;
    actor.momz := ((target.z + target.height div 2) - (actor.z + actor.height div 2)) div dist;
  end;
  result := true;
end;

//---------------------------------------------------------------------------
//
// FUNC P_GetThingFloorType
//
//---------------------------------------------------------------------------
// JVAL: 9 December 2007, Added terrain types
function P_GetThingFloorType(thing: Pmobj_t): byte;
begin
  result := flats[Psubsector_t(thing.subsector).sector.floorpic].terraintype;
end;

//---------------------------------------------------------------------------
//
// FUNC P_GetThingFloorType
//
//---------------------------------------------------------------------------
// JVAL: 20200506 - Added ceiling terrain types
function P_GetThingCeilingType(thing: Pmobj_t): byte;
begin
  result := flats[Psubsector_t(thing.subsector).sector.ceilingpic].terraintype;
end;

//---------------------------------------------------------------------------
//
// FUNC P_HitFloor
//
//---------------------------------------------------------------------------
var
  id_radixwatersplash: integer = -1;
  id_radixmudsplash: integer = -1;
  id_radixlavasplash: integer = -1;

procedure P_HitFloor(thing: Pmobj_t);
var
  mo: Pmobj_t;
  sec: Psector_t;
  z: fixed_t; // JVAL: 3d Floors
  ss: Psubsector_t;
begin
  // don't splash if has MF2_EX_NOHITFLOOR flag
  if thing.flags2_ex and MF2_EX_NOHITFLOOR <> 0 then
    exit;

  // Exit if playing old engine demo or in compatibility mode
  if G_NeedsCompatibilityMode then
    exit;

  ss := thing.subsector;

  if ss.flags and SSF_BRIDGE <> 0 then
    exit;

  sec := ss.sector;

  // don't splash if landing on the edge above water/lava/etc....
  if thing.floorz <> sec.floorheight then
    exit;

  if sec.heightsec <> -1 then
    exit;

  if thing.player <> nil then
    inc(Pplayer_t(thing.player).wallhits, TICRATE); // JVAL: 20200428 - inc wall count to use in score

  // JVAL: 3d Floors
  z := thing.floorz;

  case P_GetThingFloorType(thing) of
    FLOOR_WATER:
      begin
      // JVAL
      // If we record a demo or playing demo (version > 114)
      // then we force splashes
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SPLASHBASE));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SPLASH));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := 2 * FRACUNIT + (P_Random * 256);
          if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_StartSound(mo, Ord(sfx_gloop));
        end;
        exit;
      end;
    FLOOR_LAVA:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_LAVASPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_LAVASMOKE));
          mo.momz := FRACUNIT + (P_Random * 128);
          if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_StartSound(mo, Ord(sfx_burn));
        end;
        exit;
      end;
    FLOOR_SLUDGE:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SLUDGESPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SLUDGECHUNK));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := FRACUNIT + (P_Random * 256);
          if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_StartSound(mo, Ord(sfx_sgloop));
        end;
        exit;
      end;
    FLOOR_NUKAGE:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_NUKAGESPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_NUKAGECHUNK));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := FRACUNIT + (P_Random * 256);
          if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_StartSound(mo, Ord(sfx_sgloop));
        end;
        exit;
      end;
    FLOOR_RADIXLAVA:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          if id_radixlavasplash < 0 then
            id_radixlavasplash := Info_GetMobjNumForName('MT_RADIXLAVASPLASH');
          mo := P_SpawnMobj(thing.x, thing.y, z, id_radixlavasplash);
          if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_AmbientSound(mo.x, mo.y, 'radix/SndSplash');
        end;
        exit;
      end;
    FLOOR_RADIXMUD:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          if id_radixmudsplash < 0 then
            id_radixmudsplash := Info_GetMobjNumForName('MT_RADIXMUDSPLASH');
          mo := P_SpawnMobj(thing.x, thing.y, z, id_radixmudsplash);
          if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_AmbientSound(mo.x, mo.y, 'radix/SndSplash');
        end;
        exit;
      end;
    FLOOR_RADIXWATER:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          if id_radixwatersplash < 0 then
            id_radixwatersplash := Info_GetMobjNumForName('MT_RADIXWATERSPLASH');
          mo := P_SpawnMobj(thing.x, thing.y, z, id_radixwatersplash);
          if mo.flags3_ex and MF3_EX_NOSOUND = 0 then
            S_AmbientSound(mo.x, mo.y, 'radix/SndSplash');
        end;
        exit;
      end;
  end;
end;

procedure CmdSpawnMobj(const parm1, parm2: string);
var
  sc: TScriptEngine;
  x, y, z: fixed_t;
  mobjno, dn: integer;
  angle: angle_t;
  parm, tmp: string;
  mo: Pmobj_t;
begin
  if (gamestate <> GS_LEVEL) or demoplayback or demorecording or netgame then
  begin
    printf('You can''t specify the command at this time.'#13#10);
    exit;
  end;

  parm := strtrim(parm1 + ' ' + parm2);
  if parm = '' then
  begin
    printf('Usage:'#13#10' spawnmobj [x y z angle doomednum/doomname]'#13#10);
    exit;
  end;

  sc := TScriptEngine.Create(parm);
  sc.MustGetInteger;
  x := sc._Integer * FRACUNIT;
  sc.MustGetInteger;
  y := sc._Integer * FRACUNIT;
  sc.MustGetString;
  tmp := strupper(sc._String);
  if (tmp = 'ONFLOORZ') or (tmp = 'FLOORZ') then
    z := ONFLOORZ
  else if (tmp = 'ONFLOATZ') or (tmp = 'FLOATZ') then
    z := ONFLOATZ
  else if (tmp = 'ONCEILINGZ') or (tmp = 'CEILINGZ') then
    z := ONCEILINGZ
  else
    z := atoi(tmp, ONFLOORZ) * FRACUNIT;

  sc.MustGetInteger;
  angle := sc._Integer * ANG1;

  tmp := '';
  while sc.GetString do
    tmp := tmp + sc._String + ' ';
  tmp := strupper(strtrim(tmp));

  dn := atoi(tmp, 0);
  if dn >= 1 then
    mobjno := Info_GetMobjNumForDoomNum(dn)
  else
    mobjno := Info_GetMobjNumForName(tmp);
  if (mobjno > 0) and (mobjno < nummobjtypes) then
  begin
    mo := P_SpawnMobj(x, y, z, mobjno);
    if mo <> nil then
    begin
      mo.angle := angle;
      printf('spawnmobj: mobj %s spawned, key=%d'#13#10, [tmp, mo.key]);
    end
    else
      printf('spawnmobj: mobj %s can not be spawned'#13#10, [tmp]);
  end
  else
    printf('Unknown mobj %s'#13#10, [tmp]);
  sc.Free;
end;

procedure CmdSummon(const parm1, parm2: string);
var
  x, y, z: fixed_t;
  mobjno, dn: integer;
  an, angle: angle_t;
  parm: string;
  mo: Pmobj_t;
  dist: fixed_t;
begin
  if (gamestate <> GS_LEVEL) or demoplayback or demorecording or netgame then
  begin
    printf('You can''t specify the command at this time.'#13#10);
    exit;
  end;

  parm := strtrim(parm1);
  if parm = '' then
  begin
    printf('Usage:'#13#10' summon doomednum/doomname'#13#10);
    exit;
  end;

  dn := atoi(parm, 0);
  if dn >= 1 then
    mobjno := Info_GetMobjNumForDoomNum(dn)
  else
    mobjno := Info_GetMobjNumForName(parm);

  if (mobjno <= 0) or (mobjno >= nummobjtypes) then
  begin
    printf('Unknown mobj %s'#13#10, [parm]);
    exit;
  end;

  if players[consoleplayer].mo = nil then
    exit;

  angle := players[consoleplayer].mo.angle;
  an := angle shr ANGLETOFINESHIFT;
  dist := mobjinfo[Ord(MT_PLAYER)].radius + mobjinfo[mobjno].radius + 32 * FRACUNIT;
  x := players[consoleplayer].mo.x + FixedMul(dist, finecosine[an]);
  y := players[consoleplayer].mo.y + FixedMul(dist, finesine[an]);
  if mobjinfo[mobjno].flags and MF_SPAWNCEILING <> 0 then
    z := ONCEILINGZ
  else if mobjinfo[mobjno].flags_ex and MF_EX_SPAWNFLOAT <> 0 then
    z := ONFLOATZ
  else
    z := ONFLOORZ;

  mo := P_SpawnMobj(x, y, z, mobjno);
  if mo <> nil then
  begin
    mo.angle := angle;
    printf('summon: mobj %s spawned, key=%d'#13#10, [parm, mo.key]);
  end
  else
    printf('summon: mobj %s can not be spawned'#13#10, [parm]);
end;

procedure MObj_Init;
begin
  mobjlist := TMobjList.Create;
  C_AddCmd('spawnmobj, p_spawnmobj', @CmdSpawnMobj);
  C_AddCmd('summon', @CmdSummon);
end;

procedure MObj_ShutDown;
begin
  mobjlist.Free;
end;

//
// FUNC P_FindMobjFromKey
//
function P_FindMobjFromKey(const key: LongWord): Pmobj_t;
var
  currentthinker: Pthinker_t;
begin
  if key = 0 then
  begin
    result := nil;
    exit;
  end;
  
  currentthinker := thinkercap.next;
  while Pointer(currentthinker) <> Pointer(@thinkercap) do
  begin
    if (@currentthinker._function.acp1 = @P_MobjThinker) and
       (Pmobj_t(currentthinker).key = key) then
    begin
      result := Pmobj_t(currentthinker);
      exit;
    end;
    currentthinker := currentthinker.next;
  end;

  result := nil;
end;

end.

