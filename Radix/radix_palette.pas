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
//   Radix palette
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

// From dcolors.c (Doom Utilities Source - https://www.doomworld.com/idgames/historic/dmutils)
unit radix_palette;

interface

uses
  d_delphi,
  v_video;

function RX_ScaleRadixPalette(const inppal: PByteArray): boolean;

procedure RX_CreateDoomPalette(const inppal: PByteArray; const outpal: PByteArray; const colormap: PByteArray);

// From palette frompal to palette topal create translation table
// All arrays must be allocated in memory before calling it
procedure RX_CreateTranslation(const frompal, topal: PByteArray; const trans: PByteArray);

implementation

procedure	RX_ColorShiftPalette(const inpal: PByteArray; const outpal: PByteArray;
  const r, g, b: integer; const shift: integer; const steps: integer);
var
	i: integer;
	dr, dg, db: integer;
	in_p, out_p: PByteArray;
begin
	in_p := inpal;
	out_p := outpal;

	for i := 0 to 255 do
	begin
		dr := r - in_p[0];
		dg := g - in_p[1];
		db := b - in_p[2];

		out_p[0] := in_p[0] + (dr * shift) div steps;
		out_p[1] := in_p[1] + (dg * shift) div steps;
		out_p[2] := in_p[2] + (db * shift) div steps;

		in_p := @in_p[3];
		out_p := @out_p[3];
	end;
end;

procedure RX_CopyPalette(const inppal, outpal: PByteArray);
var
  i: integer;
begin
  for i := 0 to 767 do
    outpal[i] := inppal[i];
end;

function RX_BestColor(const r, g, b: byte; const palette: PByteArray; const rangel, rangeh: integer): byte;
var
	i: integer;
	dr, dg, db: integer;
	bestdistortion, distortion: integer;
	bestcolor: integer;
	pal: PByteArray;
begin
//
// let any color go to 0 as a last resort
//
	bestdistortion := (r * r + g * g + b * b ) * 2;
	bestcolor := 0;

	pal := @palette[rangel * 3];
	for i := rangel to rangeh do
	begin
    dr := r - pal[0];
    dg := g - pal[1];
    db := b - pal[2];
    pal := @pal[3];
    distortion := dr * dr + dg * dg + db * db;
    if distortion < bestdistortion then
    begin
      if distortion = 0 then
      begin
        result := i;  // perfect match
        exit;
      end;

      bestdistortion := distortion;
      bestcolor := i;
		end;
	end;

  result := bestcolor;
end;

function RX_ScaleRadixPalette(const inppal: PByteArray): boolean;
var
  i: integer;
  mx: integer;
begin
  mx := inppal[0];
  for i := 1 to 767 do
    if inppal[i] > mx then
      mx := inppal[i];

  if mx < 64 then
  begin
    for i := 0 to 767 do
      inppal[i] := 4 * inppal[i];
    result := true;
  end
  else
    result := false;
end;

procedure RX_CreateDoomPalette(const inppal: PByteArray; const outpal: PByteArray; const colormap: PByteArray);
const
  NUMLIGHTS = 32;
var
  lightpalette: packed array[0..NUMLIGHTS + 1, 0..255] of byte;
	i, l, c: integer;
  red, green, blue: integer;
  palsrc: PByte;
  gray: double;
begin
  RX_ScaleRadixPalette(inppal);

  RX_CopyPalette(inppal, outpal);

  for i := 1 to 8 do
		RX_ColorShiftPalette(inppal, @outpal[768 * i], 255, 0, 0, i, 9);

  for i := 1 to 4 do
    RX_ColorShiftPalette(inppal, @outpal[768 * (i + 8)], 215, 186, 69, i, 8);

	RX_ColorShiftPalette(inppal, @outpal[768 * 13], 0, 256, 0, 1, 8);

  for l := 0 to NUMLIGHTS - 1 do
	begin
    palsrc := @inppal[0];
    for c := 0 to 255 do
    begin
      red := palsrc^; inc(palsrc);
      green := palsrc^; inc(palsrc);
      blue := palsrc^; inc(palsrc);

      red := (red * (NUMLIGHTS - l) + NUMLIGHTS div 2) div NUMLIGHTS;
      green := (green * (NUMLIGHTS - l) + NUMLIGHTS div 2) div NUMLIGHTS;
      blue := (blue * (NUMLIGHTS - l) + NUMLIGHTS div 2) div NUMLIGHTS;

      lightpalette[l][c] := RX_BestColor(red, green, blue, inppal, 0, 255);
    end;
  end;

  palsrc := @inppal[0];
  for c := 0 to 255 do
  begin
    red := palsrc^; inc(palsrc);
    green := palsrc^; inc(palsrc);
    blue := palsrc^; inc(palsrc);

    // https://doomwiki.org/wiki/Carmack%27s_typo
    // Correct Carmack's typo
    gray := red * 0.299 / 256 + green * 0.587 / 265 + blue * 0.114 / 256;
    gray := 1.0 - gray;
    lightpalette[NUMLIGHTS][c] := RX_BestColor(trunc(gray * 255), trunc(gray * 255), trunc(gray * 255), inppal, 0, 255);
  end;

  for c := 0 to 255 do
    lightpalette[NUMLIGHTS + 1][c] := 0;

  for i := 0 to NUMLIGHTS + 1 do
    for c := 0 to 255 do
      colormap[i * 256 + c] := lightpalette[i][c];

end;

// From palette frompal to palette topal create translation table
// All arrays must be allocated in memory before calling it
procedure RX_CreateTranslation(const frompal, topal: PByteArray; const trans: PByteArray);
var
  i: integer;
  r, g, b: byte;
begin
  for i := 0 to 255 do
  begin
    r := topal[i * 3];
    g := topal[i * 3 + 1];
    b := topal[i * 3 + 2];
    trans[i] := RX_BestColor(r, g, b, frompal, 0, 255);
  end;
end;

end.

