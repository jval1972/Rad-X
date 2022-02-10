//
//  RAD: Recreation of the game "Radix - beyond the void"
//       powered by the DelphiDoom engine
//
//  Copyright (C) 1995 by Epic MegaGames, Inc.
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
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
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//   radix.dat lump definition
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

unit radix_defs;

interface

type
  radixheader_t = packed record
    id: packed array[0..10] of char;
    unknown: packed array[0..5] of byte;
    numlumps: integer;
    start: integer;
  end;

  radixlump_t = packed record
    name: array[0..31] of char;
    position: integer;
    length: integer;
    unknown_word16: smallint;
    unknown_int32: integer;
  end;
  Pradixlump_t = ^radixlump_t;
  radixlump_tArray = array[0..$FFF] of radixlump_t;
  Pradixlump_tArray = ^radixlump_tArray;

  radixbitmaplump_t = packed record
    name: array[0..31] of char;
    position: integer;
    height: smallint;
    width: smallint;
  end;
  Pradixbitmaplump_t = ^radixbitmaplump_t;
  radixbitmaplump_tArray = array[0..$FFF] of radixbitmaplump_t;
  Pradixbitmaplump_tArray = ^radixbitmaplump_tArray;

  radixpalitem_t = packed record
    r, g, b: byte;
  end;

  radixcolumn_t = packed record
    offs: word;
    start: byte;
    size: byte;
  end;

  radixcolumn_tArray = array[0..$FFF] of radixcolumn_t;
  Pradixcolumn_tArray = ^radixcolumn_tArray;

//==============================================================================
//
// radixlumpname
//
//==============================================================================
function radixlumpname(const l: radixlump_t): string; overload;

//==============================================================================
//
// radixlumpname
//
//==============================================================================
function radixlumpname(const l: radixbitmaplump_t): string; overload;

const
  RX_WALL_PREFIX = 'RDXW';
  RX_FLAT_PREFIX = 'RDXF';

implementation

//==============================================================================
//
// radixlumpname
//
//==============================================================================
function radixlumpname(const l: radixlump_t): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to 31 do
  begin
    if l.name[i] = #0 then
      break;
    result := result + l.name[i];
  end;
end;

//==============================================================================
//
// radixlumpname
//
//==============================================================================
function radixlumpname(const l: radixbitmaplump_t): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to 31 do
  begin
    if l.name[i] = #0 then
      break;
    result := result + l.name[i];
  end;
end;

end.

