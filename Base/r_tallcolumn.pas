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

unit r_tallcolumn;

interface

uses
  d_delphi,
  m_fixed,
  r_main;

// Column drawers
procedure R_DrawTallColumnMedium;
procedure R_DrawTallColumnHi;
procedure R_DrawTallColumnBase32;

var
//
// R_DrawTallColumn
// Source is the top of the column to scale.
//
  dc_height: LongWord;

implementation

uses
  doomdef,
  doomtype,
  r_precalc,
  r_column,
  r_draw;

procedure R_DrawTallColumnMedium;
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
    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);

    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];
    inc(dest, swidth);
    inc(frac, fracstep);
  end;

  while frac <= fraclimit do
  begin
  // Re-map color indices from wall texture column
  //  using a lighting/special effects LUT.
    dest^ := dc_colormap[dc_local[(LongWord(frac) shr FRACBITS) mod dc_height]];

    inc(dest, swidth);
    inc(frac, fracstep);
  end;
end;

procedure R_DrawTallColumnBase32;
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
    spot := (LongWord(frac) shr FRACBITS) mod dc_height;
    destl^ := dc_colormap32[dc_source[spot]];

    inc(destl, SCREENWIDTH);
    inc(frac, fracstep);
  end;
end;

procedure R_DrawTallColumnHi;
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
  bf_r: PIntegerArray;
  bf_g: PIntegerArray;
  bf_b: PIntegerArray;
  mod_height: LongWord;
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
    mod_height := dc_height * (1 shl dc_texturefactorbits);
  end
  else
    mod_height := dc_height;

  swidth := SCREENWIDTH32PITCH;
  lfactor := dc_lightlevel;
  if fracstep > 2 * FRACUNIT div 5 then
  begin
    if lfactor >= 0 then
    begin
      R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
      {$UNDEF INVERSECOLORMAPS}
      {$UNDEF FOG}
      {$UNDEF MASKEDCOLUMN}
      {$UNDEF SMALLSTEPOPTIMIZER}
      {$I R_DrawTallColumnHi.inc}
    end
    else
    begin
      {$DEFINE INVERSECOLORMAPS}
      {$UNDEF FOG}
      {$UNDEF MASKEDCOLUMN}
      {$UNDEF SMALLSTEPOPTIMIZER}
      {$I R_DrawTallColumnHi.inc}
    end;
  end
  else
  begin
    lspot := MININT;
    ldest := 0;
    if lfactor >= 0 then
    begin
      R_GetPrecalc32Tables(lfactor, bf_r, bf_g, bf_b);
      {$UNDEF INVERSECOLORMAPS}
      {$UNDEF FOG}
      {$UNDEF MASKEDCOLUMN}
      {$DEFINE SMALLSTEPOPTIMIZER}
      {$I R_DrawTallColumnHi.inc}
    end
    else
    begin
      {$DEFINE INVERSECOLORMAPS}
      {$UNDEF FOG}
      {$UNDEF MASKEDCOLUMN}
      {$DEFINE SMALLSTEPOPTIMIZER}
      {$I R_DrawTallColumnHi.inc}
    end;
  end;
end;

end.

