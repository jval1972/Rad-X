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
//  Player related stuff.
//  Bobbing POV/weapon, movement.
//  Pending weapon.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit p_user;

interface

uses
  m_fixed,
  p_mobj_h,
  d_player;

procedure P_PlayerThink(player: Pplayer_t);

procedure P_CalcHeight(player: Pplayer_t);

procedure P_PlayerFaceMobj(const player: Pplayer_t; const face: Pmobj_t; const ticks: integer);

var
  allowplayerbreath: Boolean = false;

const
  MAXMOVETHRESHOLD = 18 * FRACUNIT;

implementation

uses
  d_delphi,
  d_englsh,
  d_items,
  m_rnd,
  tables,
  d_ticcmd,
  d_event,
  info_h,
  info,
{$IFDEF DEBUG}
  i_io,
{$ENDIF}
  g_game,
  p_genlin,
  p_mobj,
  p_tick,
  p_pspr,
  p_local,
  p_setup,    // JVAL: 3d Floors
  p_slopes,   // JVAL: Slopes
  p_spec,
  p_map,
  p_maputl,
  radix_player,
  radix_weapons,
  r_main,
  r_defs,
  sounds,
  s_sound,
  doomdef,
  doomstat;

//
// Movement.
//
const
// 16 pixels of bob
  MAXBOB = $100000;

var
  onground: boolean;

//
// P_Thrust
// Moves the given origin along a given angle.
//
procedure P_Thrust(player: Pplayer_t; angle: angle_t; const mv: fixed_t);
var
  pmo: Pmobj_t;
begin
  if mv = 0 then
    exit;
  angle := angle div FRACUNIT;

  pmo := player.mo;
  pmo.momx := pmo.momx + FixedMul(mv, fixedcosine[angle]);
  pmo.momy := pmo.momy + FixedMul(mv, fixedsine[angle]);
end;

// JVAL: Slopes
procedure P_CalcHeight(player: Pplayer_t);
var
  angle: integer;
  oldviewz: fixed_t;
  oldviewz2: fixed_t;
  viewbob: fixed_t; // JVAL: Slopes
  pmo: Pmobj_t;
begin
  // Regular movement bobbing
  // (needs to be calculated for gun swing
  // even if not on ground)
  // OPTIMIZE: tablify angle
  // Note: a LUT allows for effects
  //  like a ramp with low health.
  pmo := player.mo;
  player.bob := FixedMul(pmo.momx, pmo.momx) +
                FixedMul(pmo.momy, pmo.momy);
  player.bob := player.bob div 4;

  if player.bob > MAXBOB then
    player.bob := MAXBOB;

  oldviewz := player.viewz;

  if (player.cheats and CF_NOMOMENTUM <> 0) or not onground then
  begin
    player.viewz := pmo.z + PVIEWHEIGHT;

    // JVAL: 20200427 - New field (interpolated)
    player.bobviewz := 2 * finesine[(leveltime * (FINEANGLES div 64)) and FINEMASK];

    if player.viewz > pmo.ceilingz - 4 * FRACUNIT then
      player.viewz := pmo.ceilingz - 4 * FRACUNIT;

    player.oldviewz := oldviewz;

    exit;
  end;

  player.bobviewz := 0;

  angle := (FINEANGLES div 20 * leveltime) and FINEMASK;
  if pmo.flags3_ex and MF3_EX_DOOMBOB <> 0 then
    viewbob := FixedMul(player.bob div 2, finesine[angle]) div (player.slopetics + 1)
  else
    viewbob := 0;

  // move viewheight
  if player.playerstate = PST_LIVE then
  begin
    player.viewheight := player.viewheight + player.deltaviewheight;

    if player.viewheight > PVIEWHEIGHT then
    begin
      player.viewheight := PVIEWHEIGHT;
      player.deltaviewheight := 0;
    end;

    if player.viewheight < PVIEWHEIGHT div 2 then
    begin
      player.viewheight := PVIEWHEIGHT div 2;
      if player.deltaviewheight <= 0 then
        player.deltaviewheight := 1;
    end;

    if player.deltaviewheight <> 0 then
    begin
      if player.slopetics > 0 then
        player.deltaviewheight := player.deltaviewheight + (FRACUNIT div 4) * player.slopetics
      else
        player.deltaviewheight := player.deltaviewheight + FRACUNIT div 4;
      if player.deltaviewheight = 0 then
        player.deltaviewheight := 1;
    end;
  end;

  if player.slopetics > 0 then
  begin
    oldviewz2 := player.oldviewz;

    player.viewz :=
      (player.slopetics * player.viewz +
       pmo.z + player.viewheight + viewbob) div (player.slopetics + 1); // Extra smooth

    if oldviewz2 < oldviewz then
    begin
      if player.viewz < oldviewz then
        player.viewz := oldviewz;
    end
    else if oldviewz2 > oldviewz then
    begin
      if player.viewz > oldviewz then
        player.viewz := oldviewz;
    end;

    if player.viewz < pmo.floorz + PVIEWHEIGHT div 2 - 4 * FRACUNIT then
      player.viewz := pmo.floorz + PVIEWHEIGHT div 2 - 4 * FRACUNIT;
    if player.viewz < pmo.floorz + 4 * FRACUNIT then
      player.viewz := pmo.floorz + 4 * FRACUNIT;
  end
  else
    player.viewz := pmo.z + player.viewheight + viewbob;

  if player.viewz > pmo.ceilingz - 4 * FRACUNIT then
    player.viewz := pmo.ceilingz - 4 * FRACUNIT;

  if player.viewz < pmo.floorz + 4 * FRACUNIT then
    player.viewz := pmo.floorz + 4 * FRACUNIT;

  player.oldviewz := oldviewz;
end;

function P_GetMoveFactor(const mo: Pmobj_t): fixed_t;
var
  momentum, friction: integer;
begin
  result := ORIG_FRICTION_FACTOR;

  // If the floor is icy or muddy, it's harder to get moving. This is where
  // the different friction factors are applied to 'trying to move'. In
  // p_mobj.c, the friction factors are applied as you coast and slow down.

  if (mo.flags and (MF_NOGRAVITY or MF_NOCLIP) = 0) and
     (mo.flags_ex and MF_EX_LOWGRAVITY = 0) then
  begin
    friction := mo.friction;
    if friction = ORIG_FRICTION then            // normal floor

    else if friction > ORIG_FRICTION then       // ice
    begin
      result := mo.movefactor;
      mo.movefactor := ORIG_FRICTION_FACTOR;    // reset
    end
    else                                        // sludge
    begin

      // phares 3/11/98: you start off slowly, then increase as
      // you get better footing

      momentum := P_AproxDistance(mo.momx, mo.momy);
      result := mo.movefactor;
      if momentum > MORE_FRICTION_MOMENTUM shl 2 then
        result := result shl 3
      else if momentum > MORE_FRICTION_MOMENTUM shl 1 then
        result := result shl 2
      else if momentum > MORE_FRICTION_MOMENTUM then
        result := result shl 1;

      mo.movefactor := ORIG_FRICTION_FACTOR;  // reset
    end;
  end;
end;

function R_CalcPlaneTranspoAngle(const prev, next: angle_t; const tics, starttics: fixed_t): angle_t;
var
  prev_e, next_e, mid_e: float;
  frac: float;
begin
  if prev = next then
    result := prev
  else
  begin
    frac := 1.0 - tics / starttics;
    if ((prev < ANG90) and (next > ANG270)) or
       ((next < ANG90) and (prev > ANG270)) then
    begin
      prev_e := prev / ANGLE_MAX;
      next_e := next / ANGLE_MAX;
      if prev > next then
        next_e := next_e + 1.0
      else
        prev_e := prev_e + 1.0;

      mid_e := prev_e + (next_e - prev_e) * frac;
      if mid_e > 1.0 then
        mid_e := mid_e - 1.0;
      result := Round(mid_e * ANGLE_MAX);
    end
    else if prev > next then
    begin
      result := prev - round((prev - next) * frac);
    end
    else
    begin
      result := prev + round((next - prev) * frac);
    end;
  end;
end;

//
// JVAL: 20200313 - New function (RA_PlaneTranspo action)
// P_PlaneTranspoMove
//
procedure P_PlaneTranspoMove(player: Pplayer_t);
var
  dx, dy, dz: int64;
  pmo: Pmobj_t;
begin
  dec(player.planetranspo_tics);
  pmo := player.mo;
  if player.planetranspo_tics <= 0 then
  begin
    pmo.momx := 0;
    pmo.momy := 0;
    pmo.momz := 0;
    pmo.angle := player.planetranspo_target_a;
    exit;
  end;

  dx := (int64(player.planetranspo_target_x) - int64(player.planetranspo_start_x)) div player.planetranspo_start_tics;
  dy := (int64(player.planetranspo_target_y) - int64(player.planetranspo_start_y)) div player.planetranspo_start_tics;
  dz := (int64(player.planetranspo_target_z) - int64(player.planetranspo_start_z)) div player.planetranspo_start_tics;
  pmo.momx := dx * (player.planetranspo_start_tics - player.planetranspo_tics) div (player.planetranspo_start_tics div 2);
  pmo.momy := dy * (player.planetranspo_start_tics - player.planetranspo_tics) div (player.planetranspo_start_tics div 2);
  pmo.momz := dz * (player.planetranspo_start_tics - player.planetranspo_tics) div (player.planetranspo_start_tics div 2);
  pmo.angle := R_CalcPlaneTranspoAngle(player.planetranspo_start_a, player.planetranspo_target_a, player.planetranspo_tics, player.planetranspo_start_tics);
end;

//
// P_MovePlayer
//
procedure P_MovePlayer(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  look16: integer; // JVAL Smooth Look Up/Down
  look2: integer;
  movefactor: fixed_t;
  xyspeed: fixed_t;
  an: angle_t;
  flyupdown: integer;
  has_mj: boolean; // JVAL: 20200322 - Maneuvering jets physics
  pmo: Pmobj_t;
begin
  cmd := @player.cmd;

  if player.planetranspo_tics > 0 then
  begin
    P_PlaneTranspoMove(player);
    exit;
  end;

  pmo := player.mo;
  pmo.angle := pmo.angle + _SHLW(cmd.angleturn, 16);

  // JVAL: 20200322 - Maneuvering jets physics
  has_mj := player.radixpowers[Ord(rpu_maneuverjets)] > 0;

  // Do not let the player control movement
  //  if not onground.
  onground := pmo.z <= pmo.floorz;

  if not onground then
    onground := pmo.flags2_ex and MF2_EX_ONMOBJ <> 0;

  movefactor := ORIG_FRICTION_FACTOR;

  if Psubsector_t(pmo.subsector).sector.special and FRICTION_MASK <> 0 then
    movefactor := P_GetMoveFactor(pmo);

  if has_mj then
    movefactor := FixedMul(movefactor, MJ_FACTOR);

  if cmd.forwardmove <> 0 then
    P_Thrust(player, pmo.angle, cmd.forwardmove * movefactor);

  if cmd.sidemove <> 0 then
    P_Thrust(player, pmo.angle - ANG90, cmd.sidemove * movefactor);

  // JVAL: 20200322 - Maneuvering jets physics - Faster slowdown
  if has_mj then
  begin
    pmo.momx := pmo.momx * 7 div 8;
    pmo.momy := pmo.momy * 7 div 8;
  end
  else
  begin
    pmo.momx := pmo.momx * 15 div 16;
    pmo.momy := pmo.momy * 15 div 16;
  end;

  if ((cmd.forwardmove <> 0) or (cmd.sidemove <> 0)) and
     (pmo.state = @states[Ord(S_PLAY)]) then
    P_SetMobjState(pmo, S_PLAY_RUN1);

// JVAL Look UP and DOWN
  if zaxisshift then
  begin
    // JVAL Smooth Look Up/Down
    look16 := cmd.lookupdown16;
    if look16 > 7 * 256 then
      look16 := look16 - 16 * 256;

    if player.angletargetticks > 0 then
      player.centering := true
    else if look16 <> 0 then
    begin
      if look16 = TOCENTER * 256 then
        player.centering := true
      else
      begin
        player.lookdir16 := player.lookdir16 + Round(5 * look16 / 16);

        if player.lookdir16 > MAXLOOKDIR * 16 then
          player.lookdir16 := MAXLOOKDIR * 16
        else if player.lookdir16 < MINLOOKDIR * 16 then
          player.lookdir16 := MINLOOKDIR * 16;
      end;
    end;

    if player.centering then
    begin
      // JVAL Smooth Look Up/Down
      if player.lookdir16 > 0 then
        player.lookdir16 := player.lookdir16 - 8 * 16
      else if player.lookdir16 < 0 then
        player.lookdir16 := player.lookdir16 + 8 * 16;

      if abs(player.lookdir16) < 8 * 16 then
      begin
        player.lookdir16 := 0;
        player.centering := false;
      end;
    end;
  end;

  pmo.momz :=  pmo.momz - player.thrustmomz;
  player.thrustmomz := 0;

  pmo.momz := pmo.momz * 15 div 16;

  if player.lookdir16 <> 0 then
  begin
    an := (R_PointToAngle2(0, 0, pmo.momx, pmo.momy) - pmo.angle) shr FRACBITS;
    xyspeed := FixedMul(FixedSqrt(FixedMul(pmo.momx, pmo.momx) + FixedMul(pmo.momy, pmo.momy)), fixedcosine[an]);
    if xyspeed <> 0 then
    begin
      player.thrustmomz := ((xyspeed div 16) * player.lookdir16) div 256; //ORIG_FRICTION_FACTOR;
      pmo.momz :=  pmo.momz + player.thrustmomz;
    end;
  end;

  if not G_NeedsCompatibilityMode then
  begin
  // JVAL Look LEFT and RIGHT
    look2 := cmd.lookleftright;
    if look2 > 7 then
      look2 := look2 - 16;

    if player.angletargetticks > 0 then
      player.forwarding := true
    else if look2 <> 0 then
    begin
      if look2 = TOFORWARD then
        player.forwarding := true
      else
      begin
        player.lookdir2 := (player.lookdir2 + 2 * look2) and 255;
        if player.lookdir2 in [64..127] then
          player.lookdir2 := 63
        else if player.lookdir2 in [128..191] then
          player.lookdir2 := 192;
      end;
    end
    else
      if player.oldlook2 <> 0 then
        player.forwarding := true;

    if player.forwarding then
    begin
      if player.lookdir2 in [3..63] then
        player.lookdir2 := player.lookdir2 - 6
      else if player.lookdir2 in [192..251] then
        player.lookdir2 := player.lookdir2 + 6;

      if (player.lookdir2 < 8) or (player.lookdir2 > 247) then
      begin
        player.lookdir2 := 0;
        player.forwarding := false;
      end;
    end;
    pmo.viewangle := player.lookdir2 shl 24;

    player.oldlook2 := look2;

    flyupdown := cmd.flyup;
    flyupdown := flyupdown - cmd.flydown;
    if flyupdown > 0 then
      pmo.momz := 8 * FRACUNIT
    else if flyupdown < 0 then
      pmo.momz := -8 * FRACUNIT
  end
  else
    player.lookdir2 := 0;
end;

//
// P_DeathThink
// Fall on your face when dying.
// Decrease POV height to floor height.
//
const
  ANG5 = ANG90 div 18;
  ANG355 = ANG270 +  ANG5 * 17; // add by JVAL

procedure P_DeathThink(player: Pplayer_t);
var
  angle: angle_t;
  delta: angle_t;
  pmo: Pmobj_t;
begin
  P_MovePsprites(player);
  pmo := player.mo;

  // fall to the ground
  if player.viewheight > 6 * FRACUNIT then
    player.viewheight := player.viewheight - FRACUNIT;

  if player.viewheight < 6 * FRACUNIT then
    player.viewheight := 6 * FRACUNIT;

  if player.viewheight > 6 * FRACUNIT then
    if player.lookdir16 < 45 * 16 then
      player.lookdir16 := player.lookdir16 + 5 * 16; // JVAL Smooth Look Up/Down

  player.deltaviewheight := 0;
  onground := pmo.z <= pmo.floorz;
  P_CalcHeight(player); // JVAL: Slopes

  if (player.attacker <> nil) and (player.attacker <> pmo) then
  begin

    angle := R_PointToAngle2(
      pmo.x, pmo.y, player.attackerx, player.attackery);

    delta := angle - pmo.angle;

    if (delta < ANG5) or (delta > ANG355) then
    begin
      // Looking at killer,
      //  so fade damage flash down.
      pmo.angle := angle;

      if player.damagecount <> 0 then
        player.damagecount := player.damagecount - 1;
    end
    else if delta < ANG180 then
      pmo.angle := pmo.angle + ANG5
    else
      pmo.angle := pmo.angle - ANG5;

  end
  else if player.damagecount <> 0 then
    player.damagecount := player.damagecount - 1;

  if player.cmd.buttons and BT_USE <> 0 then
    player.playerstate := PST_REBORN;
end;

var
  brsnd: integer = -1;
  brsnd2: integer = -1;
  rnd_breath: Integer = 0;

procedure A_PlayerBreath(p: Pplayer_t);
var
  sndidx: integer;
begin
  if p.health <= 0 then
    exit;

  if p.playerstate = PST_DEAD then
    exit;

  if leveltime - p.lastbreath < 3 * TICRATE + (C_Random(rnd_breath) mod TICRATE) then
    exit;

  p.lastbreath := leveltime;

  if allowplayerbreath then
  begin
    if p.hardbreathtics > 0 then
    begin
      if brsnd2 < 0 then
        brsnd2 := S_GetSoundNumForName('player/breath2');
      sndidx := brsnd2;
    end
    else
    begin
      if brsnd < 0 then
        brsnd := S_GetSoundNumForName('player/breath');
      sndidx := brsnd;
    end;
    if sndidx > 0 then
      S_StartSound(p.mo, sndidx);
  end;
end;

procedure P_AngleTarget(player: Pplayer_t);
var
  ticks: LongWord;
  angle: angle_t;
  diff: angle_t;
  pmo: Pmobj_t;
begin
  if player.angletargetticks <= 0 then
    exit;

  player.cmd.angleturn := 0;
  pmo := player.mo;
  angle := R_PointToAngle2(pmo.x, pmo.y, player.angletargetx, player.angletargety);
  diff := pmo.angle - angle;

  ticks := player.angletargetticks;
  if diff > ANG180 then
  begin
    diff := ANGLE_MAX - diff;
    pmo.angle := pmo.angle + (diff div ticks);
  end
  else
    pmo.angle := pmo.angle - (diff div ticks);

  dec(player.angletargetticks);
end;

procedure P_PlayerFaceMobj(const player: Pplayer_t; const face: Pmobj_t; const ticks: integer);
begin
  player.angletargetx := face.x;
  player.angletargety := face.y;
  player.angletargetticks := ticks;
end;

//
// P_PlayerThink
//
procedure P_PlayerThink(player: Pplayer_t);
var
  cmd: Pticcmd_t;
  newweapon: weapontype_t;
  sec: Psector_t; // JVAL: 3d Floors
  pmo: Pmobj_t;
begin
  // fixme: do this in the cheat code
  pmo := player.mo;
  if pmo = nil then
    exit;

  if player.cheats and CF_NOCLIP <> 0 then
    pmo.flags := pmo.flags or MF_NOCLIP
  else
    pmo.flags := pmo.flags and not MF_NOCLIP;

  // chain saw run forward
  cmd := @player.cmd;
  if pmo.flags and MF_JUSTATTACKED <> 0 then
  begin
    cmd.angleturn := 0;
    cmd.forwardmove := $c800 div 512;
    cmd.sidemove := 0;
    pmo.flags := pmo.flags and not MF_JUSTATTACKED;
  end;

  if player.quaketics > 0 then
  begin
    Dec(player.quaketics, FRACUNIT);
    if player.quaketics < 0 then
    begin
      player.quaketics := 0;
      player.quakeintensity := 0;
    end;
  end;

  if player.teleporttics > 0 then
  begin
    Dec(player.teleporttics, FRACUNIT);
    if player.teleporttics < 0 then
      player.teleporttics := 0;
  end;

  RX_PlayerThink(player); // JVAL: 20200412 - Special RADIX logic for players

  if player.playerstate = PST_DEAD then
  begin
    P_DeathThink(player);
    exit;
  end;

  P_AngleTarget(player);

  // Move around.
  // Reactiontime is used to prevent movement
  //  for a bit after a teleport.
  if pmo.reactiontime <> 0 then
    pmo.reactiontime := pmo.reactiontime - 1
  else
    P_MovePlayer(player);

  P_CalcHeight(player); // JVAL: Slopes

  // JVAL: 3d Floors
  sec := Psubsector_t(pmo.subsector).sector;
  if sec.special <> 0 then
    P_PlayerInSpecialSector(player, sec, P_FloorHeight(sec, pmo.x, pmo.y));    // JVAL: 3d Floors
  if sec.midsec >= 0 then
    if sectors[sec.midsec].special <> 0 then
      P_PlayerInSpecialSector(player, @sectors[sec.midsec], sectors[sec.midsec].ceilingheight);  // JVAL: 3d Floors

  // Check for weapon change.

  // A special event has no other buttons.
  if cmd.buttons and BT_SPECIAL <> 0 then
    cmd.buttons := 0;

  if (cmd.buttons and BT_CHANGE <> 0) and (player.weaponchangetics <= 0) then
  begin
    // The actual changing of the weapon is done
    //  when the weapon psprite can do it
    //  (read: not in the middle of an attack).
    newweapon := weapontype_t(_SHR(cmd.buttons and BT_WEAPONMASK, BT_WEAPONSHIFT));

    if (newweapon = wp_standardepc) and
       (player.weaponowned[Ord(wp_enchancedepc)] <> 0) and
       (player.readyweapon = wp_standardepc) then
    begin
      newweapon := wp_enchancedepc;
    end
    else if (newweapon = wp_standardepc) and
       (player.weaponowned[Ord(wp_superepc)] <> 0) and
       (player.readyweapon = wp_enchancedepc) then
    begin
      newweapon := wp_superepc
    end;

    if (player.weaponowned[Ord(newweapon)] <> 0) and
       (newweapon <> player.readyweapon) then
      // Do not go to plasma or BFG in shareware,
      //  even if cheated.
      if ((newweapon <> wp_phasetorpedoes) and (newweapon <> wp_gravitywave) and (newweapon <> wp_nuke) and (newweapon <> wp_enchancedepc) and (newweapon <> wp_superepc)) or
         (gamemode <> shareware) then
      begin
        player.pendingweapon := newweapon;
        player._message := weaponinfo[Ord(player.pendingweapon)].selecttext;  // JVAL: 20200508 - Select weapon message
      end;
    // JVAL: 20200507 - Avoid rapid repeating weapon changes
    if newweapon <> player.readyweapon then
      player.weaponchangetics := TICRATE div 4;
  end;

  // check for use
  if cmd.buttons and BT_USE <> 0 then
  begin
    if not player.usedown then
    begin
      P_UseLines(player);
      player.usedown := true;
    end;
  end
  else
    player.usedown := false;

  if cmd.buttons2 and BT2_PLASMABOMB <> 0 then
  begin
    if not player.plasmabombdown then
    begin
      RX_FirePlasmaBomb(player);
      player.plasmabombdown := true;
    end;
  end
  else
    player.plasmabombdown := false;

  // cycle psprites
  P_MovePsprites(player);

  // Counters, time dependend power ups.

  // Strength counts up to diminish fade.
  if player.powers[Ord(pw_strength)] <> 0 then
    player.powers[Ord(pw_strength)] := player.powers[Ord(pw_strength)] + 1;

  if player.powers[Ord(pw_invulnerability)] <> 0 then
    player.powers[Ord(pw_invulnerability)] := player.powers[Ord(pw_invulnerability)] - 1;

  if player.powers[Ord(pw_invisibility)] <> 0 then
  begin
    player.powers[Ord(pw_invisibility)] := player.powers[Ord(pw_invisibility)] - 1;
    if player.powers[Ord(pw_invisibility)] = 0 then
      pmo.flags := pmo.flags and not MF_SHADOW;
  end;

  if player.powers[Ord(pw_infrared)] <> 0 then
    player.powers[Ord(pw_infrared)] := player.powers[Ord(pw_infrared)] - 1;

  if player.powers[Ord(pw_ironfeet)] <> 0 then
    player.powers[Ord(pw_ironfeet)] := player.powers[Ord(pw_ironfeet)] - 1;

  if player.damagecount <> 0 then
    player.damagecount := player.damagecount - 1;

  if player.hardbreathtics > 0 then
    player.hardbreathtics := player.hardbreathtics - 1;

  if player.bonuscount <> 0 then
    player.bonuscount := player.bonuscount - 1;


  // Handling colormaps.
  if player.powers[Ord(pw_invulnerability)] <> 0 then
  begin
    if (player.powers[Ord(pw_invulnerability)] > 4 * 32) or
       (player.powers[Ord(pw_invulnerability)] and 8 <> 0) then
      player.fixedcolormap := INVERSECOLORMAP
    else
      player.fixedcolormap := 0;
  end
  else if player.powers[Ord(pw_infrared)] <> 0 then
  begin
    if (player.powers[Ord(pw_infrared)] > 4 * 32) or
       (player.powers[Ord(pw_infrared)] and 8 <> 0) then
      // almost full bright
      player.fixedcolormap := 1
    else
      player.fixedcolormap := 0;
  end
  else
    player.fixedcolormap := 0;

  // JVAL 20200322: Radix power ups dec in every tick
  if player.radixpowers[Ord(rpu_rapidshield)] > 0 then
  begin
    dec(player.radixpowers[Ord(rpu_rapidshield)]);
    if player.radixpowers[Ord(rpu_rapidshield)] = 0 then
      player._message := S_RAPID_SHIELD_DEPLETED;
  end;

  if player.radixpowers[Ord(rpu_rapidenergy)] > 0 then
  begin
    dec(player.radixpowers[Ord(rpu_rapidenergy)]);
    if player.radixpowers[Ord(rpu_rapidenergy)] = 0 then
      player._message := S_RAPID_ENERGY_DEPLETED;
  end;

  if player.radixpowers[Ord(rpu_maneuverjets)] > 0 then
  begin
    dec(player.radixpowers[Ord(rpu_maneuverjets)]);
    if player.radixpowers[Ord(rpu_maneuverjets)] = 0 then
      player._message := S_MANEUVER_JETS_DEPLETED;
  end;

  if player.radixpowers[Ord(rpu_nightvision)] > 0 then
  begin
    dec(player.radixpowers[Ord(rpu_nightvision)]);
    if player.fixedcolormap = 0 then
    begin
      if (player.radixpowers[Ord(rpu_nightvision)] > 4 * 32) or
         (player.radixpowers[Ord(rpu_nightvision)] and 8 <> 0) then
        player.fixedcolormap := 1
      else
        player.fixedcolormap := 0;
    end;
    if player.radixpowers[Ord(rpu_nightvision)] = 0 then
      player._message := S_NIGHTVISION_DEPLETED;
  end;

  if player.radixpowers[Ord(rpu_alds)] > 0 then
  begin
    dec(player.radixpowers[Ord(rpu_alds)]);
    if player.radixpowers[Ord(rpu_alds)] = 0 then
      player._message := S_ALDS_DEPLETED;
  end;

  A_PlayerBreath(player);
end;

end.

