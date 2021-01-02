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
//  Multithreading flat rendering - 8 bit color (ripple)
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit r_flat8_ripple;

interface

procedure R_DrawSpanMedium_RippleMT(const fi: pointer);

implementation

uses
  d_delphi,
  m_fixed,
  r_draw,
  r_main,
  r_precalc,
  r_ripple,
  r_span,
  r_flat8,
  r_3dfloors,
  r_zbuffer,
  r_depthbuffer;


procedure R_DrawSpanMedium_RippleMT(const fi: pointer);
var
  ds_source: PByteArray;
  ds_colormap: PByteArray;
  ds_y, ds_x1, ds_x2: integer;
  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;
  ds_scale: dsscale_t;
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  dest: PByte;
  count: integer;
  i: integer;
  spot: integer;
  rpl: PIntegerArray;
  fb: fourbytes_t;
  docheckzbuffer3dfloors: boolean;
  db_distance: LongWord;
  x: integer;
begin
  ds_source := Pflatrenderinfo8_t(fi).ds_source;
  ds_colormap := Pflatrenderinfo8_t(fi).ds_colormap;
  ds_y := Pflatrenderinfo8_t(fi).ds_y;
  ds_x1 := Pflatrenderinfo8_t(fi).ds_x1;
  ds_x2 := Pflatrenderinfo8_t(fi).ds_x2;
  ds_xfrac := Pflatrenderinfo8_t(fi).ds_xfrac;
  ds_yfrac := Pflatrenderinfo8_t(fi).ds_yfrac;
  ds_xstep := Pflatrenderinfo8_t(fi).ds_xstep;
  ds_ystep := Pflatrenderinfo8_t(fi).ds_ystep;
  rpl := Pflatrenderinfo8_t(fi).ds_ripple;
  ds_scale := Pflatrenderinfo8_t(fi).ds_scale;
  docheckzbuffer3dfloors := Pflatrenderinfo8_t(fi).ds_checkzbuffer3dfloors;

  dest := @((ylookup[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  x := ds_x1;
  count := ds_x2 - x;

  if docheckzbuffer3dfloors then
  begin
    db_distance := Pflatrenderinfo8_t(fi).db_distance;
    {$DEFINE RIPPLE}
    {$DEFINE CHECK3DFLOORSZ}
    {$I R_DrawSpanMedium.inc}
  end
  else
  begin
    {$DEFINE RIPPLE}
    {$UNDEF CHECK3DFLOORSZ}
    {$I R_DrawSpanMedium.inc}
  end;
end;


end.
 
