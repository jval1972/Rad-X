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
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//   The status bar widget code.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit st_lib;

interface

uses
  d_delphi,
// We are referring to patches.
  r_defs;

type
//
// Typedefs of widgets
//

// Number widget

  st_number_t = record
    // upper right-hand corner
    //  of the number (right-justified)
    x: integer;
    y: integer;

    // max # of digits in number
    width: integer;

    // last number value
    oldnum: integer;

    // pointer to current value
    num: PInteger;

    // pointer to boolean stating
    //  whether to update number
    _on: PBoolean;

    // list of patches for 0-9
    p: Ppatch_tPArray;

    // user data
    data: integer;

  end;
  Pst_number_t = ^st_number_t;

// Percent widget ("child" of number widget,
//  or, more precisely, contains a number widget.)
  st_percent_t = record
    // number information
    n: st_number_t;

    // percent sign graphic
    p: Ppatch_t;
  end;
  Pst_percent_t = ^st_percent_t;

// Multiple Icon widget
  st_multicon_t = record
    // center-justified location of icons
    x: integer;
    y: integer;

    // last icon number
    oldinum: integer;

    // pointer to current icon
    inum: PInteger;

    // pointer to boolean stating
    //  whether to update icon
    _on: PBoolean;

    // list of icons
    p: Ppatch_tPArray;

    // user data
    data: integer;
  end;
  Pst_multicon_t = ^st_multicon_t;

// Binary Icon widget

  st_binicon_t = record
    // center-justified location of icon
    x: integer;
    y: integer;

    // last icon value
    oldval: boolean;

    // pointer to current icon status
    val: PBoolean;

    // pointer to boolean
    //  stating whether to update icon
    _on: PBoolean;


    p: Ppatch_t;   // icon
    data: integer; // user data
  end;
  Pst_binicon_t = ^st_binicon_t;

//
// Widget creation, access, and update routines
//

// Number widget routines
procedure STlib_initNum(n: Pst_number_t; x, y: integer; pl: Ppatch_tPArray;
  num: PInteger; _on: PBoolean; width: integer);

// Percent widget routines
procedure STlib_initPercent(p: Pst_percent_t; x, y: integer; pl: Ppatch_tPArray;
  num: PInteger; _on: PBoolean; percent: Ppatch_t);

// Multiple Icon widget routines
procedure STlib_initMultIcon(i: Pst_multicon_t; x, y: integer; il: Ppatch_tPArray;
  inum: PInteger; _on: PBoolean);

var
  largeammo: integer = 1994; // means "n/a"

implementation

// ?
procedure STlib_initNum(n: Pst_number_t; x, y: integer; pl: Ppatch_tPArray;
  num: PInteger; _on: PBoolean; width: integer);
begin
  n.x := x;
  n.y := y;
  n.oldnum := 0;
  n.width := width;
  n.num := num;
  n._on := _on;
  n.p := pl;
end;

//
//
procedure STlib_initPercent(p: Pst_percent_t; x, y: integer; pl: Ppatch_tPArray;
  num: PInteger; _on: PBoolean; percent: Ppatch_t);
begin
  STlib_initNum(@p.n, x, y, pl, num, _on, 3);
  p.p := percent;
end;

procedure STlib_initMultIcon(i: Pst_multicon_t; x, y: integer; il: Ppatch_tPArray;
  inum: PInteger; _on: PBoolean);
begin
  i.x  := x;
  i.y  := y;
  i.oldinum := -1;
  i.inum := inum;
  i._on := _on;
  i.p := il;
end;

end.

