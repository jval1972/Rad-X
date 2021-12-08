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
//  Sky rendering.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit r_sky;

interface

// SKY, store the number for name.
const
  SKYFLATNAME = 'F_SKY1';

// JVAL 20200218 - RADIX sky is 256*200*2 maps. - Change ANGLETOSKYSHIFT
  ANGLETOSKYSHIFT = 23;
  ANGLETOSKYUNIT = 1 shl 23;

var
  skyflatnum: integer;
  skytexture: integer;
  skytexturemid: integer;
  billboardsky: boolean = true;

procedure R_InitSkyMap;

implementation

uses
  m_fixed; // Needed for FRACUNIT.

//
// R_InitSkyMap
// Called whenever the view size changes.
//
procedure R_InitSkyMap;
begin
  skytexturemid := 100 * FRACUNIT;
end;

end.
