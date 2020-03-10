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

const
  NUMRADIXMESSAGES = 13;

var
  radixmessages: array[0..NUMRADIXMESSAGES - 1] of string;

implementation

initialization
  radixmessages[0] := S_RADIX_MESSAGE_0;
  radixmessages[1] := S_RADIX_MESSAGE_1;
  radixmessages[2] := S_RADIX_MESSAGE_2;
  radixmessages[3] := S_RADIX_MESSAGE_3;
  radixmessages[4] := S_RADIX_MESSAGE_4;
  radixmessages[5] := S_RADIX_MESSAGE_5;
  radixmessages[6] := S_RADIX_MESSAGE_6;
  radixmessages[7] := S_RADIX_MESSAGE_7;
  radixmessages[8] := S_RADIX_MESSAGE_8;
  radixmessages[9] := S_RADIX_MESSAGE_9;
  radixmessages[10] := S_RADIX_MESSAGE_10;
  radixmessages[11] := S_RADIX_MESSAGE_11;

end.
