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
//   Radix weapon codepointers
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_weapons;

interface

uses
  d_player,
  p_mobj_h,
  p_pspr_h;

procedure RX_InitWeaponStates;

procedure A_RaiseRadixWeapon(player: Pplayer_t; psp: Ppspdef_t);

procedure A_LowerRadixWeapon(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixPlasma(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixStandardEPC(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixEnhancedEPC(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixSuperEPC1(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixSuperEPC2(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixPlasmaSpread(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixSeekingMissiles(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixNuke(player: Pplayer_t; psp: Ppspdef_t);

procedure A_FireRadixPhaseTorpedo(player: Pplayer_t; psp: Ppspdef_t);

procedure A_PhaseTorpedoSplit(actor: Pmobj_t);

procedure A_FireRadixGravityWave(player: Pplayer_t; psp: Ppspdef_t);

implementation

uses
  d_delphi,
  doomdef,
  d_think,
  d_items,
  g_game,
  info,
  info_h,
  info_common,
  m_rnd,
  m_fixed,
  tables,
  p_tick,
  p_pspr,
  p_mobj;

//
// RX_CheckNextRefire
// JVAL: 20200401 - Check if weapon can refire
//
function RX_CheckNextRefire(const p: Pplayer_t): boolean;
begin
  if leveltime - p.lastfire[Ord(p.readyweapon)] < weaponinfo[Ord(p.readyweapon)].refiretics then
  begin
    result := false;
    exit;
  end;

  p.lastfire[Ord(p.readyweapon)] := leveltime;
  result := true;
end;

function RX_NewWeaponState(const tics: integer; const proc: actionf_p2): integer;
var
  st: Pstate_t;
begin
  result := Info_GetNewState;
  st := @states[result];
  st.sprite := Ord(SPR_TNT1);
  st.frame := 0;
  st.tics := tics;
  st.nextstate := statenum_t(result);
  st.action.acp2 := proc;
end;

procedure A_RaiseRadixWeapon(player: Pplayer_t; psp: Ppspdef_t);
var
  newstate: statenum_t;
begin
  // The weapon has been raised all the way,
  //  so change to the ready state.
  newstate := statenum_t(weaponinfo[Ord(player.readyweapon)].readystate);

  P_SetPsprite(player, Ord(ps_weapon), newstate);
end;

procedure A_LowerRadixWeapon(player: Pplayer_t; psp: Ppspdef_t);
begin
  // Player is dead.
  if player.playerstate = PST_DEAD then
    // don't bring weapon back up
    exit;

  // The old weapon has been lowered off the screen,
  // so change the weapon and start raising it
  if player.health = 0 then
  begin
    // Player is dead, so keep the weapon off screen.
    P_SetPsprite(player, Ord(ps_weapon), S_NULL);
    exit;
  end;

  player.readyweapon := player.pendingweapon;

  P_BringUpWeapon(player);
end;

procedure RX_InitWeaponStates;
var
  sraise: integer;
  slower: integer;
  sready: integer;
  sflash: integer;
  st, st2: integer;

  procedure get_def_weapon_states;
  begin
    sraise := RX_NewWeaponState(1, @A_RaiseRadixWeapon);
    slower := RX_NewWeaponState(1, @A_LowerRadixWeapon);
    sready := RX_NewWeaponState(1, @A_WeaponReady);
    sflash := RX_NewWeaponState(5, @A_Light1);
    states[sflash].nextstate := S_LIGHTDONE;
  end;

begin
  get_def_weapon_states;
  weaponinfo[Ord(wp_neutroncannons)].upstate := sraise;
  weaponinfo[Ord(wp_neutroncannons)].downstate := slower;
  weaponinfo[Ord(wp_neutroncannons)].readystate := sready;
  weaponinfo[Ord(wp_neutroncannons)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixPlasma);
  weaponinfo[Ord(wp_neutroncannons)].atkstate := st;
  states[st].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_neutroncannons)].refiretics, @A_Refire));
  states[Ord(states[st].nextstate)].nextstate := statenum_t(sready);

  get_def_weapon_states;
  weaponinfo[Ord(wp_standardepc)].upstate := sraise;
  weaponinfo[Ord(wp_standardepc)].downstate := slower;
  weaponinfo[Ord(wp_standardepc)].readystate := sready;
  weaponinfo[Ord(wp_standardepc)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixStandardEPC);
  weaponinfo[Ord(wp_standardepc)].atkstate := st;
  st2 := RX_NewWeaponState(1, @A_FireRadixStandardEPC);
  states[st].nextstate := statenum_t(st2);
  states[st2].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_standardepc)].refiretics, @A_Refire));
  states[Ord(states[st2].nextstate)].nextstate := statenum_t(sready);

  get_def_weapon_states;
  weaponinfo[Ord(wp_plasmaspreader)].upstate := sraise;
  weaponinfo[Ord(wp_plasmaspreader)].downstate := slower;
  weaponinfo[Ord(wp_plasmaspreader)].readystate := sready;
  weaponinfo[Ord(wp_plasmaspreader)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixPlasmaSpread);
  weaponinfo[Ord(wp_plasmaspreader)].atkstate := st;
  states[st].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_plasmaspreader)].refiretics, @A_Refire));
  states[Ord(states[st].nextstate)].nextstate := statenum_t(sready);

  get_def_weapon_states;
  weaponinfo[Ord(wp_seekingmissiles)].upstate := sraise;
  weaponinfo[Ord(wp_seekingmissiles)].downstate := slower;
  weaponinfo[Ord(wp_seekingmissiles)].readystate := sready;
  weaponinfo[Ord(wp_seekingmissiles)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixSeekingMissiles);
  weaponinfo[Ord(wp_seekingmissiles)].atkstate := st;
  states[st].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_seekingmissiles)].refiretics, @A_Refire));
  states[Ord(states[st].nextstate)].nextstate := statenum_t(sready);

  get_def_weapon_states;
  weaponinfo[Ord(wp_nuke)].upstate := sraise;
  weaponinfo[Ord(wp_nuke)].downstate := slower;
  weaponinfo[Ord(wp_nuke)].readystate := sready;
  weaponinfo[Ord(wp_nuke)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixNuke);
  weaponinfo[Ord(wp_nuke)].atkstate := st;
  states[st].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_nuke)].refiretics, @A_Refire));
  states[Ord(states[st].nextstate)].nextstate := statenum_t(sready);

  get_def_weapon_states;
  weaponinfo[Ord(wp_phasetorpedoes)].upstate := sraise;
  weaponinfo[Ord(wp_phasetorpedoes)].downstate := slower;
  weaponinfo[Ord(wp_phasetorpedoes)].readystate := sready;
  weaponinfo[Ord(wp_phasetorpedoes)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixPhaseTorpedo);
  weaponinfo[Ord(wp_phasetorpedoes)].atkstate := st;
  states[st].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_phasetorpedoes)].refiretics, @A_Refire));
  states[Ord(states[st].nextstate)].nextstate := statenum_t(sready);

  get_def_weapon_states;
  weaponinfo[Ord(wp_gravitywave)].upstate := sraise;
  weaponinfo[Ord(wp_gravitywave)].downstate := slower;
  weaponinfo[Ord(wp_gravitywave)].readystate := sready;
  weaponinfo[Ord(wp_gravitywave)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixGravityWave);
  weaponinfo[Ord(wp_gravitywave)].atkstate := st;
  states[st].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_gravitywave)].refiretics, @A_Refire));
  states[Ord(states[st].nextstate)].nextstate := statenum_t(sready);

  get_def_weapon_states;
  weaponinfo[Ord(wp_enchancedepc)].upstate := sraise;
  weaponinfo[Ord(wp_enchancedepc)].downstate := slower;
  weaponinfo[Ord(wp_enchancedepc)].readystate := sready;
  weaponinfo[Ord(wp_enchancedepc)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixEnhancedEPC);
  weaponinfo[Ord(wp_enchancedepc)].atkstate := st;
  st2 := RX_NewWeaponState(1, @A_FireRadixEnhancedEPC);
  states[st].nextstate := statenum_t(st2);
  states[st2].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_enchancedepc)].refiretics, @A_Refire));
  states[Ord(states[st2].nextstate)].nextstate := statenum_t(sready);

  get_def_weapon_states;
  weaponinfo[Ord(wp_superepc)].upstate := sraise;
  weaponinfo[Ord(wp_superepc)].downstate := slower;
  weaponinfo[Ord(wp_superepc)].readystate := sready;
  weaponinfo[Ord(wp_superepc)].flashstate := sflash;
  st := RX_NewWeaponState(1, @A_FireRadixSuperEPC1);
  weaponinfo[Ord(wp_superepc)].atkstate := st;
  st2 := RX_NewWeaponState(1, @A_FireRadixSuperEPC2);
  states[st].nextstate := statenum_t(st2);
  states[st2].nextstate := statenum_t(RX_NewWeaponState(weaponinfo[Ord(wp_superepc)].refiretics, @A_Refire));
  states[Ord(states[st2].nextstate)].nextstate := statenum_t(sready);
end;

procedure P_SpawnPlayerMissileOffsZ(source: Pmobj_t; _type: integer; const doffs, dz: fixed_t);
var
  oldx, oldy, oldz: fixed_t;
  dx, dy: fixed_t;
  ang: angle_t;
begin
  oldx := source.x;
  oldy := source.y;
  oldz := source.z;

  ang := (source.angle - ANG90) shr ANGLETOFINESHIFT;

  dx := FixedMul(doffs, finecosine[ang]);
  dy := FixedMul(doffs, finesine[ang]);

  source.x := source.x + dx;
  source.y := source.y + dy;
  source.z := source.z + dz;

  P_SpawnPlayerMissile(source, _type);

  source.x := oldx;
  source.y := oldy;
  source.z := oldz;
end;

const
  PLASMAENERGYDRAINTICS = 5;
  PLASMAENERGYFIRETICS = TICRATE;

procedure RX_DrainPlasmaEnergy(const p: Pplayer_t; const amount: integer);
begin
  p.energyweaponfiretics := PLASMAENERGYFIRETICS;
  if p.plasmaenergycountdown <= 0 then
  begin
    if p.energy > 0 then
      dec(p.energy);
    p.plasmaenergycountdown := PLASMAENERGYDRAINTICS;
    exit;
  end;
  dec(p.plasmaenergycountdown, amount);
end;

const
  PLASMAENERGYMIN = 2;  // At least 2 points energy to fire energy weapons

//
// A_FireRadixPlasma
//
var
  radixplasma_id: integer = -1;

procedure A_FireRadixPlasma(player: Pplayer_t; psp: Ppspdef_t);

  procedure spawn_neutron(offs, z: fixed_t);
  begin
    P_SpawnPlayerMissileOffsZ(
      player.mo, radixplasma_id,
      offs, z
    );
  end;

var
  nlevel: integer;
begin
  if not RX_CheckNextRefire(player) then
    exit;

  // JVAL: 20200412 -> Do not fire if low on energy
  if player.energy < PLASMAENERGYMIN then
    exit;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  if radixplasma_id < 0 then
    radixplasma_id := Info_GetMobjNumForName('MT_RADIXPLASMA');

  // JVAL: Decide the neutron cannon level
  nlevel := neutroncannoninfo[player.neutroncannonlevel].firelevel;
  if nlevel > 0 then
    if player.energy < 2 * PLASMAENERGYMIN then
      nlevel := 0;  // JVAL: 20200412 -> When low energy only fire the base level

  RX_DrainPlasmaEnergy(player, decide(nlevel = 0, 2, 3));

  case nlevel of
    0:
      begin
        if player.weaponflags and PWF_NEURONCANNON <> 0 then
        begin
          spawn_neutron(-32 * FRACUNIT, -8 * FRACUNIT);
          player.weaponflags := player.weaponflags and not PWF_NEURONCANNON;
        end
        else
        begin
          spawn_neutron(32 * FRACUNIT, -8 * FRACUNIT);
          player.weaponflags := player.weaponflags or PWF_NEURONCANNON;
        end;
      end;
    1:
      begin
        spawn_neutron(-32 * FRACUNIT, -32 * FRACUNIT);
        spawn_neutron(32 * FRACUNIT, -32 * FRACUNIT);
      end;
    2:
      begin
        spawn_neutron(-32 * FRACUNIT, -32 * FRACUNIT);
        spawn_neutron(0, 32 * FRACUNIT);
        spawn_neutron(32 * FRACUNIT, -32 * FRACUNIT);
      end;
  else
    spawn_neutron(-32 * FRACUNIT, -32 * FRACUNIT);
    spawn_neutron(-32 * FRACUNIT, 32 * FRACUNIT);
    spawn_neutron(32 * FRACUNIT, -32 * FRACUNIT);
    spawn_neutron(32 * FRACUNIT, 32 * FRACUNIT);
  end;
end;

//
// P_EPCFire
//
var
  radixepcshell_id: integer = -1;

type
  epccoord_t = record
    offs, z: fixed_t;
  end;
  Pepccoord_t = ^epccoord_t;
  epccoord_tArray = array[0..$FF] of epccoord_t;
  Pepccoord_tArray = ^epccoord_tArray;

procedure P_EPCFire(const player: Pplayer_t; const tbl: Pepccoord_tArray; const sz: integer; const accuracy: integer);
var
  ammoid: integer;
  i, actualammo: integer;
  doffs, dz: fixed_t;
begin
  ammoid := Ord(weaponinfo[Ord(player.readyweapon)].ammo);

  // Find the actual ammo
  if player.ammo[ammoid] >= sz then
  begin
    player.ammo[ammoid] := player.ammo[ammoid] - sz;
    actualammo := sz;
  end
  else
  begin
    actualammo := player.ammo[ammoid];
    player.ammo[ammoid] := 0;
  end;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  if radixepcshell_id < 0 then
    radixepcshell_id := Info_GetMobjNumForName('MT_RADIXEPCSHELL');

  for i := 0 to actualammo - 1 do
  begin
    // accuracy -> lower values, better accuracy
    if accuracy = 0 then
    begin
      doffs := 0;
      dz := 0;
    end
    else
    begin
      doffs := (P_Random mod accuracy) * FRACUNIT - (P_Random mod accuracy) * FRACUNIT;
      dz := (P_Random mod accuracy) * FRACUNIT - (P_Random mod accuracy) * FRACUNIT;
    end;

    P_SpawnPlayerMissileOffsZ(
      player.mo, radixepcshell_id,
        tbl[i].offs + doffs, tbl[i].z + dz);
  end;
end;

//
// A_FireRadixStandardEPC
//
const
  standardEPCtbl: array[0..1] of epccoord_t = (
    (offs: -32 * FRACUNIT; z: -32 * FRACUNIT),
    (offs:  32 * FRACUNIT; z: -32 * FRACUNIT)
  );

procedure A_FireRadixStandardEPC(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  P_EPCFire(player, @standardEPCtbl, 2, 1);
end;

//
// A_FireRadixEnhancedEPC
//
const
  enchancedEPCtbl: array[0..3] of epccoord_t = (
    (offs: -32 * FRACUNIT; z:  32 * FRACUNIT),
    (offs:  32 * FRACUNIT; z:  32 * FRACUNIT),
    (offs: -32 * FRACUNIT; z: -32 * FRACUNIT),
    (offs:  32 * FRACUNIT; z: -32 * FRACUNIT)
  );

procedure A_FireRadixEnhancedEPC(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  P_EPCFire(player, @enchancedEPCtbl, 4, 2);
end;

//
// A_FireRadixSuperEPC
//
const
  superEPCtbl1: array[0..5] of epccoord_t = (
    (offs: 0 * FRACUNIT; z:  32 * FRACUNIT),
    (offs: 28 * FRACUNIT; z:  16 * FRACUNIT),
    (offs: 28 * FRACUNIT; z:  -16 * FRACUNIT),
    (offs: 0 * FRACUNIT; z:  -32 * FRACUNIT),
    (offs: -28 * FRACUNIT; z:  -16 * FRACUNIT),
    (offs: -28 * FRACUNIT; z:  16 * FRACUNIT)
  );
  superEPCtbl2: array[0..5] of epccoord_t = (
    (offs: 16 * FRACUNIT; z:  28 * FRACUNIT),
    (offs: 32 * FRACUNIT; z:  0 * FRACUNIT),
    (offs: 16 * FRACUNIT; z:  -28 * FRACUNIT),
    (offs: -16 * FRACUNIT; z:  -28 * FRACUNIT),
    (offs: -32 * FRACUNIT; z:  0 * FRACUNIT),
    (offs: -16 * FRACUNIT; z:  28 * FRACUNIT)
  );

procedure A_FireRadixSuperEPC1(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  P_EPCFire(player, @superEPCtbl1, 6, 3);
end;

procedure A_FireRadixSuperEPC2(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  P_EPCFire(player, @superEPCtbl2, 6, 3);
end;

//
// A_FireRadixPlasmaSpread
//
var
  radixplasmaspreadleft_id: integer = -1;
  radixplasmaspreadright_id: integer = -1;

procedure A_FireRadixPlasmaSpread(player: Pplayer_t; psp: Ppspdef_t);
begin
  if not RX_CheckNextRefire(player) then
    exit;

  // JVAL: 20200412 -> Do not fire if low on energy
  if player.energy < PLASMAENERGYMIN then
    exit;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  if radixplasmaspreadleft_id < 0 then
    radixplasmaspreadleft_id := Info_GetMobjNumForName('MT_RADIXPLASMASPREADLEFT');

  if radixplasmaspreadright_id < 0 then
    radixplasmaspreadright_id := Info_GetMobjNumForName('MT_RADIXPLASMASPREADRIGHT');

  RX_DrainPlasmaEnergy(player, 2);

  P_SpawnPlayerMissileOffsZ(
    player.mo, radixplasmaspreadleft_id,
      -32 * FRACUNIT, -8 * FRACUNIT
  );

  P_SpawnPlayerMissileOffsZ(
    player.mo, radixplasmaspreadright_id,
      32 * FRACUNIT, -8 * FRACUNIT
  );

end;


//
// A_FireRadixTorpedos
//
var
  radixseekingmissile_id: integer = -1;

procedure A_FireRadixSeekingMissiles(player: Pplayer_t; psp: Ppspdef_t);
var
  ammoid: integer;
begin
  if not RX_CheckNextRefire(player) then
    exit;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  if radixseekingmissile_id < 0 then
    radixseekingmissile_id := Info_GetMobjNumForName('MT_RADIXSEEKINGMISSILE');

  ammoid := Ord(weaponinfo[Ord(player.readyweapon)].ammo);

  if player.ammo[ammoid] <= 0 then
    exit;
  dec(player.ammo[ammoid]);

  P_SpawnPlayerMissileOffsZ(
    player.mo, radixseekingmissile_id,
      -32 * FRACUNIT, -8 * FRACUNIT
  );

  if player.ammo[ammoid] <= 0 then
    exit;
  dec(player.ammo[ammoid]);

  P_SpawnPlayerMissileOffsZ(
    player.mo, radixseekingmissile_id,
      32 * FRACUNIT, -8 * FRACUNIT
  );
end;

//
// A_FireRadixNuke
//
var
  radixnuke_id: integer = -1;

procedure A_FireRadixNuke(player: Pplayer_t; psp: Ppspdef_t);
var
  ammoid: integer;
begin
  if not RX_CheckNextRefire(player) then
    exit;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  if radixnuke_id < 0 then
    radixnuke_id := Info_GetMobjNumForName('MT_RADIXNUKE');

  ammoid := Ord(weaponinfo[Ord(player.readyweapon)].ammo);

  if player.ammo[ammoid] <= 0 then
    exit;
  dec(player.ammo[ammoid]);

  if player.weaponflags and PWF_NUKE <> 0 then
  begin
    P_SpawnPlayerMissileOffsZ(
      player.mo, radixnuke_id,
        -32 * FRACUNIT, -8 * FRACUNIT
    );
    player.weaponflags := player.weaponflags and not PWF_NUKE;
  end
  else
  begin
    P_SpawnPlayerMissileOffsZ(
      player.mo, radixnuke_id,
        32 * FRACUNIT, -8 * FRACUNIT
    );
    player.weaponflags := player.weaponflags or PWF_NUKE;
  end;
end;

//
// A_FireRadixPhaseTorpedo
//
var
  radixphasetorpedo_id: integer = -1;

procedure A_FireRadixPhaseTorpedo(player: Pplayer_t; psp: Ppspdef_t);
var
  ammoid: integer;
begin
  if not RX_CheckNextRefire(player) then
    exit;

  P_SetPsprite(player,
    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

  if radixphasetorpedo_id < 0 then
    radixphasetorpedo_id := Info_GetMobjNumForName('MT_RADIXPHASETORPEDO');

  ammoid := Ord(weaponinfo[Ord(player.readyweapon)].ammo);

  if player.ammo[ammoid] <= 0 then
    exit;
  dec(player.ammo[ammoid]);

  if player.weaponflags and PWF_PHASETORPEDO <> 0 then
  begin
    P_SpawnPlayerMissileOffsZ(
      player.mo, radixphasetorpedo_id,
        -32 * FRACUNIT, 8 * FRACUNIT
    );
    player.weaponflags := player.weaponflags and not PWF_PHASETORPEDO;
  end
  else
  begin
    P_SpawnPlayerMissileOffsZ(
      player.mo, radixphasetorpedo_id,
        32 * FRACUNIT, 8 * FRACUNIT
    );
    player.weaponflags := player.weaponflags or PWF_PHASETORPEDO;
  end;
end;

procedure A_PhaseTorpedoSplit(actor: Pmobj_t);
var
  mo: Pmobj_t;
  mv: fixed_t;
  ang: angle_t;
begin
  if actor.flags3_ex and MF3_EX_NOPHASETORPEDOSPLIT <> 0 then
    exit;

  actor.flags3_ex := actor.flags3_ex or MF3_EX_NOPHASETORPEDOSPLIT;

  if radixphasetorpedo_id < 0 then
    radixphasetorpedo_id := Info_GetMobjNumForName('MT_RADIXPHASETORPEDO');

  mo := P_SpawnMobj(actor.x + actor.momx, actor.y + actor.momy, actor.z + actor.momz, radixphasetorpedo_id);
  mo.flags3_ex := actor.flags3_ex or MF3_EX_NOPHASETORPEDOSPLIT;
  mo.target := actor.target;
  mo.tracer := actor.tracer;
  mo.momx := actor.momx;
  mo.momy := actor.momy;
  mo.momz := actor.momz;

  mv := (4 + P_Random and 1) * FRACUNIT div 4;
  ang := (actor.angle - ANG90 - ANG5) shr ANGLETOFINESHIFT;
  mo.momx := mo.momx + FixedMul(mv, finecosine[ang]);
  mo.momy := mo.momy + FixedMul(mv, finesine[ang]);
  mo.momz := mo.momz - (4 + P_Random and 1) * FRACUNIT div 16;

  mo := P_SpawnMobj(actor.x + actor.momx, actor.y + actor.momy, actor.z + actor.momz, radixphasetorpedo_id);
  mo.flags3_ex := actor.flags3_ex or MF3_EX_NOPHASETORPEDOSPLIT;
  mo.target := actor.target;
  mo.tracer := actor.tracer;
  mo.momx := actor.momx;
  mo.momy := actor.momy;
  mo.momz := actor.momz;

  mv := (4 + P_Random and 1) * FRACUNIT div 4;
  ang := (actor.angle + ANG90 + ANG5) shr ANGLETOFINESHIFT;
  mo.momx := mo.momx + FixedMul(mv, finecosine[ang]);
  mo.momy := mo.momy + FixedMul(mv, finesine[ang]);
  mo.momz := mo.momz - (4 + P_Random and 1) * FRACUNIT div 16;

  actor.momz := actor.momz + (4 + P_Random and 1) * FRACUNIT div 16;
end;

//
// A_FireRadixGravityWave
//
var
  radixgravitywave_id: integer = -1;

procedure A_FireRadixGravityWave(player: Pplayer_t; psp: Ppspdef_t);
var
  i: integer;
begin
  if RX_CheckNextRefire(player) then
  begin

//  P_SetPsprite(player,
//    Ord(ps_flash), statenum_t(weaponinfo[Ord(player.readyweapon)].flashstate + (P_Random and 1)));

    if (player.gravitywave > 0) and (player.energy >= GRAVITYWAVEENERGY) then
    begin
      if radixgravitywave_id < 0 then
        radixgravitywave_id := Info_GetMobjNumForName('MT_RADIXGRAVITYWAVE');

      dec(player.gravitywave);
      player.energy := player.energy - GRAVITYWAVEENERGY;
      P_SpawnPlayerMissileOffsZ(player.mo, radixgravitywave_id, 0, 0);
    end;
  end;

  if player.gravitywave = 0 then
    for i := Ord(wp_gravitywave) - 1 downto 0 do
      if player.weaponowned[i] <> 0 then
        player.pendingweapon := weapontype_t(i);
end;

end.
