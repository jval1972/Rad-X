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
//   Radix Messages
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_messages;

interface

const
  S_RADIX_MESSAGE_0 = 'Primary target ahead';
  S_RADIX_MESSAGE_1 = 'Secondary target ahead';
  S_RADIX_MESSAGE_2 = 'Shoot doors to gain entry';
  S_RADIX_MESSAGE_3 = 'Multiple targets ahead';
  S_RADIX_MESSAGE_4 = 'Kill enemies to continue';
  S_RADIX_MESSAGE_5 = 'Powerful Enemy approaching';
  S_RADIX_MESSAGE_6 = 'Exit above current position';
  S_RADIX_MESSAGE_7 = 'Exit below current position';
  S_RADIX_MESSAGE_8 = 'Watch For Seeking Missiles';
  S_RADIX_MESSAGE_9 = 'Primary Objective Completed';
  S_RADIX_MESSAGE_10 = 'Primary Objective Incomplete';
  S_RADIX_MESSAGE_11 = 'Kill all Skyfires to continue';
  S_RADIX_MESSAGE_12 = 'Secondary Objective Completed';

  S_RADIX_STARTUP_MESSAGE_1 = 'PRESS F1 FOR HELP. F12 FOR MISSION OBJECTIVES';
  S_RADIX_STARTUP_MESSAGE_2 = 'PRESS F12 FOR MISSION OBJECTIVES';

const
  NUMRADIXMESSAGES = 13;

type
  radixmessage_t = record
    radix_msg: string;
    radix_snd: integer;
    autodisable: boolean;
  end;
  Pradixmessage_t = ^radixmessage_t;

var
  radixmessages: array[0..NUMRADIXMESSAGES - 1] of radixmessage_t;

function RX_StartUpMessage(const episode, map: integer): string;

implementation

uses
  radix_sounds;

function RX_StartUpMessage(const episode, map: integer): string;
begin
  if episode = 1 then
  begin
    if map < 5 then
      result := S_RADIX_STARTUP_MESSAGE_1
    else
      result := S_RADIX_STARTUP_MESSAGE_2;
  end
  else if episode = 2 then
  begin
    if map < 4 then
      result := S_RADIX_STARTUP_MESSAGE_1
    else
      result := S_RADIX_STARTUP_MESSAGE_2;
  end
  else if episode = 3 then
  begin
    if map = 1 then
      result := S_RADIX_STARTUP_MESSAGE_1
    else
      result := S_RADIX_STARTUP_MESSAGE_2;
  end
  else
    result := S_RADIX_STARTUP_MESSAGE_2;
end;

initialization
  radixmessages[0].radix_msg := S_RADIX_MESSAGE_0;
  radixmessages[0].radix_snd := Ord(sfx_SndPrimAhead);
  radixmessages[0].autodisable := false;

  radixmessages[1].radix_msg := S_RADIX_MESSAGE_1;
  radixmessages[1].radix_snd := Ord(sfx_SndSecAhead);
  radixmessages[1].autodisable := false;

  radixmessages[2].radix_msg := S_RADIX_MESSAGE_2;
  radixmessages[2].radix_snd := -1;
  radixmessages[2].autodisable := false;

  radixmessages[3].radix_msg := S_RADIX_MESSAGE_3;
  radixmessages[3].radix_snd := Ord(sfx_SndTargetsAhead);
  radixmessages[3].autodisable := false;

  radixmessages[4].radix_msg := S_RADIX_MESSAGE_4;
  radixmessages[4].radix_snd := Ord(sfx_SndEnemy);
  radixmessages[4].autodisable := false;

  radixmessages[5].radix_msg := S_RADIX_MESSAGE_5;
  radixmessages[5].radix_snd := -1;
  radixmessages[5].autodisable := false;

  radixmessages[6].radix_msg := S_RADIX_MESSAGE_6;
  radixmessages[6].radix_snd := -1;
  radixmessages[6].autodisable := false;

  radixmessages[7].radix_msg := S_RADIX_MESSAGE_7;
  radixmessages[7].radix_snd := -1;
  radixmessages[7].autodisable := false;

  radixmessages[8].radix_msg := S_RADIX_MESSAGE_8;
  radixmessages[8].radix_snd := -1;
  radixmessages[8].autodisable := false;

  radixmessages[9].radix_msg := S_RADIX_MESSAGE_9;
  radixmessages[9].radix_snd := Ord(sfx_SndPrimComplete);
  radixmessages[9].autodisable := true;

  radixmessages[10].radix_msg := S_RADIX_MESSAGE_10;
  radixmessages[10].radix_snd := Ord(sfx_SndPrimInComplete);
  radixmessages[10].autodisable := false;

  radixmessages[11].radix_msg := S_RADIX_MESSAGE_11;
  radixmessages[11].radix_snd := -1;
  radixmessages[11].autodisable := false;

  radixmessages[12].radix_msg := S_RADIX_MESSAGE_12;
  radixmessages[12].radix_snd := Ord(sfx_SndSecComplete);
  radixmessages[12].autodisable := true;

end.
