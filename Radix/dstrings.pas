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
//  Globally defined strings.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit dstrings;

interface

// Misc. other strings.
var
  SAVEGAMENAME: string = 'gamesav';

const
//
// File locations,
// relative to current position.
// Path names are OS-sensitive.
//
  DEVMAPS = 'devmaps\';
  DEVDATA = 'devdata\';

// Start-up messages
  NUM_STARTUPMESSAGES = 5;

var
  startmsg: array[0..NUM_STARTUPMESSAGES - 1] of string;

implementation

initialization
  startmsg[0] := '';
  startmsg[1] := '';
  startmsg[2] := '';
  startmsg[3] := '';
  startmsg[4] := '';

end.

