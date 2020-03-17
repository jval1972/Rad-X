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
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit r_column;

interface

uses
  d_delphi,
  m_fixed,
  r_main;

// Column drawers
procedure R_DrawColumnMedium;
procedure R_DrawColumnHi;

procedure R_DrawColumnBase32;

var
//
// R_DrawColumn
// Source is the top of the column to scale.
//
  dc_colormap: PByteArray;
  dc_colormap32: PLongWordArray;
  dc_lightlevel: fixed_t;
  dc_llindex: integer;

  dc_iscale: fixed_t;
  dc_texturemid: fixed_t;
  dc_x: integer;
  dc_yl: integer;
  dc_yh: integer;
  dc_mod: integer; // JVAL for hi resolution
  dc_texturemod: integer; // JVAL for external textures
  dc_texturefactorbits: integer; // JVAL for hi resolution
  dc_palcolor: LongWord;
  dc_alpha: fixed_t;

const
  MAXTEXTUREFACTORBITS = 3; // JVAL: Allow hi resolution textures x 8

var
// first pixel in a column (possibly virtual)
  dc_source: PByteArray;
// JVAL for hi resolution
  dc_source32: PLongWordArray;

implementation

uses
  doomdef,
  doomtype,
  r_precalc,
  r_data,
  r_draw,
  r_hires,
  v_video;

//
// A column is a vertical slice/span from a wall texture that,
//  given the DOOM style restrictions on the view orientation,
//  will always have constant z depth.
// Thus a special case loop for very fast rendering can
//  be used. It has also been used with Wolfenstein 3D.
//
procedure R_DrawColumnMedium;
var
  count: integer;
  dest: PByte;
  frac: fixed_t;
  fracstep: fixed_t;
  fraclimit: fixed_t;
  fraclimit2: fixed_t;
  swidth: integer;
  dc_local: PByteArray;
begin
  count := dc_yh - dc_yl;

  // Zero length, column does not exceed a pixel.
  if count < 0 then
    exit;

  // Framebuffer destination address.
  // Use ylookup LUT to avoid multiply with ScreenWidth.
  // Use columnofs LUT for subwindows?
  dest := @((ylookup[dc_yl]^)[columnofs[dc_x]]);

  // Determine scaling,
  //  which is the only mapping to be done.
  fracstep := dc_iscale;
  frac := dc_texturemid + (dc_yl - centery) * fracstep;
  fraclimit := frac + count * fracstep;
  fraclimit2 := frac + (count - 16) * fracstep;
  swidth := SCREENWIDTH;
  dc_local := dc_source;

  // Inner loop that does the actual texture mapping,
  //  e.g. a DDA-lile scaling.
  // This is as fast as it gets.
  while frac <= fraclimit2 do
  begin
  // Re-map color indices from wall texture column
  //  using a lighting/special effects LUT.
    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];
    inc(dest, swidth);
    inc(frac, fracstep);
  end;

  while frac <= fraclimit do
  begin
  // Re-map color indices from wall texture column
  //  using a lighting/special effects LUT.
    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) and 127]];

    inc(dest, swidth);
    inc(frac, fracstep);
  end;
end;

procedure R_DrawColumnBase32;
var
  count: integer;
  i: integer;
  destl: PLongWord;
  frac: fixed_t;
  fracstep: fixed_t;
  spot: integer;
begin
  count := dc_yh - dc_yl;

  if count < 0 then
    exit;

  destl := @((ylookupl[dc_yl]^)[columnofs[dc_x]]);

  fracstep := dc_iscale;
  frac := dc_texturemid + (dc_yl - centery) * fracstep;
  for i := 0 to count do
  begin
    spot := (LongWord(frac) shr FRACBITS) and 127;
    destl^ := dc_colormap32[dc_source[spot]];

    inc(destl, SCREENWIDTH);
    inc(frac, fracstep);
  end;
end;

procedure R_DrawColumnHi;
var
  count: integer;
  destl: PLongWord;
  frac: fixed_t;
  fracstep: fixed_t;
  fraclimit: fixed_t;
  fraclimit2: fixed_t;
  spot: integer;
  swidth: integer;

  r1, g1, b1: byte;
  c: LongWord;
  lfactor: integer;
  lspot: integer;
  ldest: LongWord;
  and_mask: integer;
  bf_r: PIntegerArray;
  bf_g: PIntegerArray;
  bf_b: PIntegerArray;
begin
  count := dc_yh - dc_yl;

  if count < 0 then
    exit;

  destl := @((ylookupl[dc_yl]^)[columnofs[dc_x]]);

  fracstep := dc_iscale;
  frac := dc_texturemid + (dc_yl - centery) * fracstep;

  if dc_texturefactorbits > 0 then
  begin
    fracstep := fracstep * (1 shl dc_texturefactorbits);
    frac := frac * (1 shl dc_texturefactorbits);
    and_mask := 128 * (1 shl dc_texturefactorbits) - 1;
  end
  else
    and_mask := 127;

  swidth := SCREENWIDTH32PITCH;
  lfactor := dc_lightlevel;
  if fracstep > 2 * FRACUNIT div 5 then
  begin
    if lfactor >= 0 then
    begin
      R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
      {$UNDEF INVERSECOLORMAPS}
      {$UNDEF MASKEDCOLUMN}
      {$UNDEF SMALLSTEPOPTIMIZER}
      {$I R_DrawColumnHi.inc}
    end
    else
    begin
      {$DEFINE INVERSECOLORMAPS}
      {$UNDEF MASKEDCOLUMN}
      {$UNDEF SMALLSTEPOPTIMIZER}
      {$I R_DrawColumnHi.inc}
    end;
  end
  else if fracstep > FRACUNIT div 6 then
  begin
    lspot := MININT;
    ldest := 0;
    if lfactor >= 0 then
    begin
      R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
      {$UNDEF INVERSECOLORMAPS}
      {$UNDEF MASKEDCOLUMN}
      {$DEFINE SMALLSTEPOPTIMIZER}
      {$I R_DrawColumnHi.inc}
    end
    else
    begin
      {$DEFINE INVERSECOLORMAPS}
      {$UNDEF MASKEDCOLUMN}
      {$DEFINE SMALLSTEPOPTIMIZER}
      {$I R_DrawColumnHi.inc}
    end;
  end
  else
  begin
    lspot := MININT;
    ldest := 0;
    fraclimit := frac + count * fracstep;
    if lfactor >= 0 then
    begin
      R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
      {$UNDEF INVERSECOLORMAPS}
      {$UNDEF MASKEDCOLUMN}
      {$DEFINE SMALLSTEPOPTIMIZER}
      while frac <= fraclimit do
      begin
      {$I R_DrawColumnHi_SmallStepLoop.inc}
      end;
    end
    else
    begin
      {$DEFINE INVERSECOLORMAPS}
      {$UNDEF MASKEDCOLUMN}
      {$DEFINE SMALLSTEPOPTIMIZER}
      while frac <= fraclimit do
      begin
      {$I R_DrawColumnHi_SmallStepLoop.inc}
      end;
    end;
  end;
end;

end.

