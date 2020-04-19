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
//   Radix things
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

unit radix_things;

interface

// Original Radix Thing IDs
const
  _MTRX_FULLARMOR = 0; // full armor (pickup)
  _MTRX_FULLSHIED = 1; // full shield (pickup)
  _MTRX_FULLENERGY = 2; // full energy (pickup)
  _MTRX_SUPERCHARGE = 3; // supercharge (pickup)
  _MTRX_RAPIDSHIELD = 4; // rapid shield regeneration (pickup)
  _MTRX_RAPIDENERGY = 5; // rapid energy regeneration (pickup)
  _MTRX_MANEUVERJETS = 6; // maneuvering jets (pickup)
  _MTRX_NIGHTVISION = 7; // night vision (full bright) (pickup)
  _MTRX_PLASMABOMB = 8; // plasma bomb (pickup)
  _MTRX_ALDS = 9; // A.L.D.S (pickup)
  _MTRX_ULTRASHIELDS = 10; // ultra shields (pickup)
  _MTRX_LEVEL2NEUTRONCANNONS = 11; // level 2 neutron cannons (pickup)
  _MTRX_STANDARDEPC = 12; // standard EPC (pickup)
  _MTRX_LEVEL1PLASMASPREADER = 13; // level 1 plasma spreader (pickup) - weapon 3
  _MTRX_NUCLEARCAPABILITY = 14; // nuclear capability (pickup) - weapon 5
  _MTRX_MISSILECAPABILITY = 15; // missile capability (pickup) - weapon 4
  _MTRX_TORPEDOCAPABILITY = 16; // torpedo capability (pickup) - weapon 6
  _MTRX_GRAVITYDEVICE = 17; // gravity device (pickup) - weapon 7
  _MTRX_250SHELLS = 18; // 250 cells (pickup) ammo #1
  _MTRX_500SHELLS = 19; // 500 cells (pickup) ammo #1
  _MTRX_1000SHELLS = 20; // 1000 cells (pickup) ammo #1
  _MTRX_4NUKES = 21; // 4 NUKES (pickup) ammo #4
  _MTRX_10NUKES = 22; // 10 NUKES (pickup) ammo #4
  _MTRX_15TORPEDOES = 23; // 15 torpedoes (pickup) ammo #3
  _MTRX_75TORPEDOES = 24; // 75 torpedoes (pickup) ammo #3
  _MTRX_20MISSILES = 25; // 20 missiles (pickup) ammo #2
  _MTRX_50MISSILES = 26; // 50 missiles (pickup) ammo #2
  _MTRX_BOOMPACK = 27; // boom pack - 5000 cells & 100 missiles (pickup) ammo #1 & ammo #2
  _MTRX_BIOMINE1 = 28; // bio-mine 1 (weak) (enemy)
  _MTRX_BIOMINE2 = 29; // bio-mine 2 (strong) (enemy)
  _MTRX_ALIENFODDER = 30; // alien fodder
  _MTRX_DEFENCEDRONE_STUB1 = 31; // unmovable stub defence drones (enemy) - do not shoot - can not be shoot
  _MTRX_DEFENCEDRONE_STUB2 = 32; // movable stub defence drones (enemy) - do not shoot - can be shoot
  _MTRX_BATTLEDRONE1 = 33; // battle drone (enemy)
  _MTRX_MISSILEBOAT = 34; // missile boat (enemy)
  _MTRX_STORMBIRDHEAVYBOMBER = 35; // stormhead heavy bomber (enemy)
  _MTRX_SKYFIREASSULTFIGHTER = 36; // skyfire assult fighter (enemy)
  _MTRX_SPAWNER = 37; // spawner (enemy)
  _MTRX_EXODROID = 38; // exodroid (enemy)
  _MTRX_SNAKEDEAMON = 39; // snake demon (enemy) (final boss)
  _MTRX_MINE = 40; // mine (moving) (enemy)
  _MTRX_ROTATINGRADAR1 = 41; // rotating radar dish (obstacle) - RadarDish1.bmp
  _MTRX_DEFENCEDRONE_STUB3 = 42; // unmovable stub defence drones (enemy) - do not shoot - can be shoot
  _MTRX_SHIELDGENERATOR1 = 43; // Shield generator #1 (obstacle) - ShieldGen1.bmp
  _MTRX_SECONDCOOLAND1 = 44; // second cooland animated (obstacle) - SecondCoolant1.bmp (but moving - hidden animation inside patch?)
  _MTRX_BIOMECHUP = 45; // bio-mechs (enemy) - fires upward (BioMech9.bmp)
  _MTRX_ENGINECORE = 46; // engine core (obstacle)
  _MTRX_DEFENCEDRONE1 = 47; // defence drones (enemy) (DroneB1.bmp)
  _MTRX_BATTLEDRONE2 = 48; // battle drone (enemy) (DroneA_1.bmp) - unused in original
  _MTRX_SKYFIREASSULTFIGHTER2 = 49; // skyfire assult fighter (enemy) LightAssault1.bmp
  _MTRX_SKYFIREASSULTFIGHTER3 = 50; // skyfire assult fighter (enemy) LightAssault1.bmp
  _MTRX_SKYFIREASSULTFIGHTER4 = 51; // skyfire assult fighter (enemy) LightAssault1.bmp
  _MTRX_BIOMECH = 52; // bio-mechs (enemy) BioMech1.bmp
  _MTRX_DEFENCEDRONE2 = 53; // defence drones (enemy)
  _MTRX_RUI = 54; // rui
  _MTRX_SHIELDGENERATOR2 = 55; // Shield generator #2 (obstacle) - ShldGenerator1.bmp
  _MTRX_COOLANDGENERATOR = 56; // Cooland generator (obstacle) - CoolantGener1.bmp
  _MTRX_ROTATINGRADAR2 = 57; // rotating radar dish (obstacle) - RadarDish1.bmp
  _MTRX_MISSILEBOAT2 = 58; // missile boat (enemy) - DroneC1.bmp
  _MTRX_BATTLEDRONE3 = 59; // battle drone (enemy) - DroneA_1.bmp
  _MTRX_ROTATINGLIGHT = 60; // rotating light (obstacle) - RotatingLight2.bmp
  _MTRX_EGG = 61; // egg (obstacle) - Egg.bmp
  _MTRX_BARREL = 62; // barrel - shootable (obstacle) - Barrel.bmp
  _MTRX_DOZZER = 63; // dozer - shootable (vehicle) - Dozer1.bmp
  _MTRX_LIFT = 64; // lift - shootable (vehicle) - Lift1.bmp
  _MTRX_SECONDCOOLAND2 = 65; // second cooland - not animated (obstacle) - SecondCoolant1.bmp
  _MTRX_SECONDCOOLAND3 = 66; // second cooland - not animated - spawned on top (obstacle) - SecondCoolant1.bmp
  _MTRX_RADIXMAXEDITORTHING = _MTRX_SECONDCOOLAND3; // Maximum thing id in radix maps
  // Runtime thing ids (without doom editor number)
  _MTTX_RADIXPLASMA = 67;
  _MTTX_RADIXEPCSHELL = 68;
  _MTTX_RADIXSEEKINGMISSILE = 69;
  _MTTX_RADIXBIGEXPLOSION = 70;
  _MTTX_RADIXSMALLEXPLOSION = 71;
  _MTTX_RADIXBIGSMOKE = 72;
  _MTTX_RADIXBURNERSMOKE = 73;
  _MTTX_RADIXFIREBALLPUFF = 74;
  _MTTX_RADIXNUKE = 75;
  _MTTX_RADIXNUKESMOKE = 76;
  _MTTX_RADIXPHASETORPEDO = 77;
  _MTTX_RADIXGRAVITYWAVE = 78;
  _MTTX_RADIXGRAVITYWAVEEXPOLOSION = 79;
  _MTTX_RADIXGRAVITYWAVEEXPOLOSION2 = 80;
  _MTTX_ENEMYMISSILE = 81;
  _MTTX_ENEMYSEEKERMISSILE = 82;
  _MTTX_DRONEBODYB = 83;
  _MTTX_ENEMYLASER = 84;
  _MTTX_DRONEBODYA = 85;
  _MTTX_CHUNK = 86;
  _MTTX_ALDSLASER = 87;
  _MTTX_LASER = 88;

const
  _DOOM_THING_2_RADIX_ = 1000;

// Doom Engine Radix Thing Editor Numbers
const
  MT_FULLARMOR = _DOOM_THING_2_RADIX_ + _MTRX_FULLARMOR;
  MT_FULLSHIED = _DOOM_THING_2_RADIX_ + _MTRX_FULLSHIED;
  MT_FULLENERGY = _DOOM_THING_2_RADIX_ + _MTRX_FULLENERGY;
  MT_SUPERCHARGE = _DOOM_THING_2_RADIX_ + _MTRX_SUPERCHARGE;
  MT_RAPIDSHIELD = _DOOM_THING_2_RADIX_ + _MTRX_RAPIDSHIELD;
  MT_RAPIDENERGY = _DOOM_THING_2_RADIX_ + _MTRX_RAPIDENERGY;
  MT_MANEUVERJETS = _DOOM_THING_2_RADIX_ + _MTRX_MANEUVERJETS;
  MT_NIGHTVISION = _DOOM_THING_2_RADIX_ + _MTRX_NIGHTVISION;
  MT_PLASMABOMB = _DOOM_THING_2_RADIX_ + _MTRX_PLASMABOMB;
  MT_ALDS = _DOOM_THING_2_RADIX_ + _MTRX_ALDS;
  MT_ULTRASHIELDS = _DOOM_THING_2_RADIX_ + _MTRX_ULTRASHIELDS;
  MT_LEVEL2NEUTRONCANNONS = _DOOM_THING_2_RADIX_ + _MTRX_LEVEL2NEUTRONCANNONS;
  MT_STANDARDEPC = _DOOM_THING_2_RADIX_ + _MTRX_STANDARDEPC;
  MT_LEVEL1PLASMASPREADER = _DOOM_THING_2_RADIX_ + _MTRX_LEVEL1PLASMASPREADER;
  MT_NUCLEARCAPABILITY = _DOOM_THING_2_RADIX_ + _MTRX_NUCLEARCAPABILITY;
  MT_MISSILECAPABILITY = _DOOM_THING_2_RADIX_ + _MTRX_MISSILECAPABILITY;
  MT_TORPEDOCAPABILITY = _DOOM_THING_2_RADIX_ + _MTRX_TORPEDOCAPABILITY;
  MT_GRAVITYDEVICE = _DOOM_THING_2_RADIX_ + _MTRX_GRAVITYDEVICE;
  MT_250SHELLS = _DOOM_THING_2_RADIX_ + _MTRX_250SHELLS;
  MT_500SHELLS = _DOOM_THING_2_RADIX_ + _MTRX_500SHELLS;
  MT_1000SHELLS = _DOOM_THING_2_RADIX_ + _MTRX_1000SHELLS;
  MT_4NUKES = _DOOM_THING_2_RADIX_ + _MTRX_4NUKES;
  MT_10NUKES = _DOOM_THING_2_RADIX_ + _MTRX_10NUKES;
  MT_15TORPEDOES = _DOOM_THING_2_RADIX_ + _MTRX_15TORPEDOES;
  MT_75TORPEDOES = _DOOM_THING_2_RADIX_ + _MTRX_75TORPEDOES;
  MT_20MISSILES = _DOOM_THING_2_RADIX_ + _MTRX_20MISSILES;
  MT_50MISSILES = _DOOM_THING_2_RADIX_ + _MTRX_50MISSILES;
  MT_BOOMPACK = _DOOM_THING_2_RADIX_ + _MTRX_BOOMPACK;
  MT_BIOMINE1 = _DOOM_THING_2_RADIX_ + _MTRX_BIOMINE1;
  MT_BIOMINE2 = _DOOM_THING_2_RADIX_ + _MTRX_BIOMINE2;
  MT_ALIENFODDER = _DOOM_THING_2_RADIX_ + _MTRX_ALIENFODDER;
  MT_DEFENCEDRONE_STUB1 = _DOOM_THING_2_RADIX_ + _MTRX_DEFENCEDRONE_STUB1;
  MT_DEFENCEDRONE_STUB2 = _DOOM_THING_2_RADIX_ + _MTRX_DEFENCEDRONE_STUB2;
  MT_BATTLEDRONE1 = _DOOM_THING_2_RADIX_ + _MTRX_BATTLEDRONE1;
  MT_MISSILEBOAT = _DOOM_THING_2_RADIX_ + _MTRX_MISSILEBOAT;
  MT_STORMBIRDHEAVYBOMBER = _DOOM_THING_2_RADIX_ + _MTRX_STORMBIRDHEAVYBOMBER;
  MT_SKYFIREASSULTFIGHTER = _DOOM_THING_2_RADIX_ + _MTRX_SKYFIREASSULTFIGHTER;
  MT_SPAWNER = _DOOM_THING_2_RADIX_ + _MTRX_SPAWNER;
  MT_EXODROID = _DOOM_THING_2_RADIX_ + _MTRX_EXODROID;
  MT_SNAKEDEAMON = _DOOM_THING_2_RADIX_ + _MTRX_SNAKEDEAMON;
  MT_MINE = _DOOM_THING_2_RADIX_ + _MTRX_MINE;
  MT_ROTATINGRADAR1 = _DOOM_THING_2_RADIX_ + _MTRX_ROTATINGRADAR1;
  MT_DEFENCEDRONE_STUB3 = _DOOM_THING_2_RADIX_ + _MTRX_DEFENCEDRONE_STUB3;
  MT_SHIELDGENERATOR1 = _DOOM_THING_2_RADIX_ + _MTRX_SHIELDGENERATOR1;
  MT_SECONDCOOLAND1 = _DOOM_THING_2_RADIX_ + _MTRX_SECONDCOOLAND1;
  MT_BIOMECHUP = _DOOM_THING_2_RADIX_ + _MTRX_BIOMECHUP;
  MT_ENGINECORE = _DOOM_THING_2_RADIX_ + _MTRX_ENGINECORE;
  MT_DEFENCEDRONE1 = _DOOM_THING_2_RADIX_ + _MTRX_DEFENCEDRONE1;
  MT_BATTLEDRONE2 = _DOOM_THING_2_RADIX_ + _MTRX_BATTLEDRONE2;
  MT_SKYFIREASSULTFIGHTER2 = _DOOM_THING_2_RADIX_ + _MTRX_SKYFIREASSULTFIGHTER2;
  MT_SKYFIREASSULTFIGHTER3 = _DOOM_THING_2_RADIX_ + _MTRX_SKYFIREASSULTFIGHTER3;
  MT_SKYFIREASSULTFIGHTER4 = _DOOM_THING_2_RADIX_ + _MTRX_SKYFIREASSULTFIGHTER4;
  MT_BIOMECH = _DOOM_THING_2_RADIX_ + _MTRX_BIOMECH;
  MT_DEFENCEDRONE2 = _DOOM_THING_2_RADIX_ + _MTRX_DEFENCEDRONE2;
  MT_RUI = _DOOM_THING_2_RADIX_ + _MTRX_RUI;
  MT_SHIELDGENERATOR2 = _DOOM_THING_2_RADIX_ + _MTRX_SHIELDGENERATOR2;
  MT_COOLANDGENERATOR = _DOOM_THING_2_RADIX_ + _MTRX_COOLANDGENERATOR;
  MT_ROTATINGRADAR2 = _DOOM_THING_2_RADIX_ + _MTRX_ROTATINGRADAR2;
  MT_MISSILEBOAT2 = _DOOM_THING_2_RADIX_ + _MTRX_MISSILEBOAT2;
  MT_BATTLEDRONE3 = _DOOM_THING_2_RADIX_ + _MTRX_BATTLEDRONE3;
  MT_ROTATINGLIGHT = _DOOM_THING_2_RADIX_ + _MTRX_ROTATINGLIGHT;
  MT_EGG = _DOOM_THING_2_RADIX_ + _MTRX_EGG;
  MT_BARREL = _DOOM_THING_2_RADIX_ + _MTRX_BARREL;
  MT_DOZZER = _DOOM_THING_2_RADIX_ + _MTRX_DOZZER;
  MT_LIFT = _DOOM_THING_2_RADIX_ + _MTRX_LIFT;
  MT_SECONDCOOLAND2 = _DOOM_THING_2_RADIX_ + _MTRX_SECONDCOOLAND2;
  MT_SECONDCOOLAND3 = _DOOM_THING_2_RADIX_ + _MTRX_SECONDCOOLAND3;
  // Not actual editor number for the following objects:
  MT_RADIXPLASMA = _DOOM_THING_2_RADIX_ + _MTTX_RADIXPLASMA;
  MT_RADIXEPCSHELL = _DOOM_THING_2_RADIX_ + _MTTX_RADIXEPCSHELL;
  MT_RADIXSEEKINGMISSILE = _DOOM_THING_2_RADIX_ + _MTTX_RADIXSEEKINGMISSILE;
  MT_RADIXBIGEXPLOSION = _DOOM_THING_2_RADIX_ + _MTTX_RADIXBIGEXPLOSION;
  MT_RADIXSMALLEXPLOSION = _DOOM_THING_2_RADIX_ + _MTTX_RADIXSMALLEXPLOSION;
  MT_RADIXBIGSMOKE = _DOOM_THING_2_RADIX_ + _MTTX_RADIXBIGSMOKE;
  MT_RADIXBURNERSMOKE = _DOOM_THING_2_RADIX_ + _MTTX_RADIXBURNERSMOKE;
  MT_RADIXFIREBALLPUFF = _DOOM_THING_2_RADIX_ + _MTTX_RADIXFIREBALLPUFF;
  MT_RADIXNUKE = _DOOM_THING_2_RADIX_ + _MTTX_RADIXNUKE;
  MT_RADIXNUKESMOKE = _DOOM_THING_2_RADIX_ + _MTTX_RADIXNUKESMOKE;
  MT_RADIXPHASETORPEDO = _DOOM_THING_2_RADIX_ + _MTTX_RADIXPHASETORPEDO;
  MT_RADIXGRAVITYWAVE = _DOOM_THING_2_RADIX_ + _MTTX_RADIXGRAVITYWAVE;
  MT_RADIXGRAVITYWAVEEXPOLOSION = _DOOM_THING_2_RADIX_ + _MTTX_RADIXGRAVITYWAVEEXPOLOSION;
  MT_RADIXGRAVITYWAVEEXPOLOSION2 = _DOOM_THING_2_RADIX_ + _MTTX_RADIXGRAVITYWAVEEXPOLOSION2;
  MT_ENEMYMISSILE = _DOOM_THING_2_RADIX_ + _MTTX_ENEMYMISSILE;
  MT_ENEMYSEEKERMISSILE = _DOOM_THING_2_RADIX_ + _MTTX_ENEMYSEEKERMISSILE;
  MT_DRONEBODYB = _DOOM_THING_2_RADIX_ + _MTTX_DRONEBODYB;
  MT_ENEMYLASER = _DOOM_THING_2_RADIX_ + _MTTX_ENEMYLASER;
  MT_DRONEBODYA = _DOOM_THING_2_RADIX_ + _MTTX_DRONEBODYA;
  MT_CHUNK = _DOOM_THING_2_RADIX_ + _MTTX_CHUNK;
  MT_ALDSLASER = _DOOM_THING_2_RADIX_ + _MTTX_ALDSLASER;
  MT_LASER = _DOOM_THING_2_RADIX_ + _MTTX_LASER;

implementation

end.
