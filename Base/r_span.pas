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
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit r_span;

interface

uses
  d_delphi,
  m_fixed,
  tables, // JVAL: 20200221 - Texture angle
  r_main;

// Span blitting for rows, floor/ceiling.
// No Sepctre effect needed.
procedure R_DrawSpanMedium;
procedure R_DrawSpanMedium_Ripple;

var
  ds_y: integer;
  ds_x1: integer;
  ds_x2: integer;

  ds_colormap: PByteArray;

  ds_xfrac: fixed_t;
  ds_yfrac: fixed_t;
  ds_xstep: fixed_t;
  ds_ystep: fixed_t;
  ds_angle: angle_t;  // JVAL: 20200221 - Texture angle
  ds_anglex: fixed_t; // JVAL: 20201229 - Texture angle rover
  ds_angley: fixed_t; // JVAL: 20201229 - Texture angle rover
  ds_sine: float;     // JVAL: 20200225 - Texture angle
  ds_cosine: float;   // JVAL: 20200225 - Texture angle
  ds_viewsine: float;     // JVAL: 20200225 - Texture angle
  ds_viewcosine: float;   // JVAL: 20200225 - Texture angle

// start of a 64*64 tile image
  ds_source: PByteArray;


type
  dsscale_t = (ds64x64, ds128x128, ds256x256, ds512x512, ds1024x1024, ds2048x2048, NUMDSSCALES);

const
  dsscalesize: array[0..Ord(NUMDSSCALES) - 1] of integer = (
      64 *   64,
     128 *  128,
     256 *  256,
     512 *  512,
    1024 * 1024,
    2048 * 2048
  );

var
  ds_scale: dsscale_t;

implementation

uses
  r_draw,
  r_ripple,
  r_3dfloors,
  r_depthbuffer,
  r_zbuffer;
//
// R_DrawSpan
// With DOOM style restrictions on view orientation,
//  the floors and ceilings consist of horizontal slices
//  or spans with constant z depth.
// However, rotation around the world z axis is possible,
//  thus this mapping, while simpler and faster than
//  perspective correct texture mapping, has to traverse
//  the texture at an angle in all but a few cases.
// In consequence, flats are not stored by column (like walls),
//  and the inner loop has to step in texture space u and v.
//

//
// Draws the actual span (Low resolution).
//
//
// Draws the actual span (Medium resolution).
//
procedure R_DrawSpanMedium;
var
  xfrac: fixed_t;
  yfrac: fixed_t;
  xstep: fixed_t;
  ystep: fixed_t;
  dest: PByte;
  count: integer;
  i: integer;
  spot: integer;
  fb: fourbytes_t;
  x: integer;
begin
  dest := @((ylookup[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  x := ds_x1;
  count := ds_x2 - x;
  if count < 0 then
    exit;

  if checkzbuffer3dfloors then
  begin
    {$UNDEF RIPPLE}
    {$DEFINE CHECK3DFLOORSZ}
    {$I R_DrawSpanMedium.inc}
  end
  else
  begin
    {$UNDEF RIPPLE}
    {$UNDEF CHECK3DFLOORSZ}
    {$I R_DrawSpanMedium.inc}
  end;
end;

procedure R_DrawSpanMedium_Ripple;
var
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
  x: integer;
begin
  dest := @((ylookup[ds_y]^)[columnofs[ds_x1]]);

  // We do not check for zero spans here?
  x := ds_x1;
  count := ds_x2 - x;
  if count < 0 then
    exit;

  rpl := ds_ripple;

  if checkzbuffer3dfloors then
  begin
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

