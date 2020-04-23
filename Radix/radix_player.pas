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
//   Radix Player Thing
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_player;

interface

uses
  d_player;

procedure RX_PlayerThink(p: Pplayer_t);

function RX_PlayerMessage(p: Pplayer_t; const msgid: integer): boolean;

implementation

uses
  doomdef,
  d_delphi,
  g_game,
  m_rnd,
  m_fixed,
  radix_messages,
  radix_objects,
  info,
  info_h,
  p_tick,
  p_mobj_h,
  tables;

procedure RX_PlayerThink(p: Pplayer_t);
var
  new_health: integer;
  new_energy: integer;
  x, y: fixed_t;
  dist: integer;
  an: angle_t;
  mo: Pmobj_t;
begin
  if p.playerstate = PST_DEAD then
  begin
    // JVAL: 20200423 - Spawn random smoke when player dies
    if (leveltime and 15 = 0) or (P_Random < 50) then
    begin
      an := P_Random * 32;
      dist := 16 + (P_Random and 32);
      x := p.mo.x + dist * finecosine[an];
      y := p.mo.y + dist * finesine[an];
      mo := RX_SpawnRadixBigSmoke(x, y, p.mo.z);
      mo.momz := FRACUNIT div 2 + P_Random * 128;
    end;
    exit;
  end;

  if p.energyweaponfiretics > 0 then
    dec(p.energyweaponfiretics);  // JVAL: 20201204

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

end.
