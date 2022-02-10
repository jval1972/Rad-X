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
//   Radix palette
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

// From dcolors.c (Doom Utilities Source - https://www.doomworld.com/idgames/historic/dmutils)
unit radix_palette;

interface

uses
  d_delphi;

//==============================================================================
//
// RX_ScaleRadixPalette
//
//==============================================================================
function RX_ScaleRadixPalette(const inppal: PByteArray): boolean;

//==============================================================================
//
// RX_CreateDoomPalette
//
//==============================================================================
procedure RX_CreateDoomPalette(const inppal: PByteArray; const outpal: PByteArray; const colormap: PByteArray);

//==============================================================================
// RX_CreateTranslation
//
// From palette frompal to palette topal create translation table
// All arrays must be allocated in memory before calling it
//
//==============================================================================
procedure RX_CreateTranslation(const frompal, topal: PByteArray; const trans: PByteArray);

var
  def_radix_palette: packed array[0..767] of byte = (
    $00, $00, $00, $C4, $BC, $B8, $BC, $B4, $B0, $B0, $A8, $A4, $AC, $A4, $A4,
    $A4, $9C, $9C, $A0, $98, $94, $98, $90, $8C, $90, $88, $88, $88, $80, $80,
    $84, $7C, $78, $7C, $74, $74, $74, $6C, $6C, $6C, $64, $64, $68, $60, $60,
    $64, $5C, $5C, $60, $58, $58, $5C, $54, $54, $54, $50, $50, $50, $4C, $4C,
    $4C, $48, $48, $48, $44, $44, $44, $40, $40, $40, $3C, $3C, $3C, $38, $38,
    $38, $34, $34, $30, $30, $30, $28, $28, $28, $20, $20, $20, $18, $18, $18,
    $10, $10, $10, $00, $00, $00, $C0, $C0, $CC, $B8, $B8, $C4, $B0, $B0, $BC,
    $AC, $AC, $B4, $A4, $A4, $B0, $98, $98, $A4, $90, $90, $9C, $88, $88, $90,
    $80, $80, $8C, $7C, $7C, $84, $74, $74, $7C, $70, $70, $7C, $6C, $6C, $74,
    $64, $64, $6C, $60, $60, $68, $5C, $5C, $64, $58, $58, $60, $54, $54, $5C,
    $50, $50, $58, $4C, $4C, $54, $48, $48, $4C, $44, $44, $4C, $40, $40, $44,
    $3C, $3C, $40, $38, $38, $3C, $34, $34, $38, $30, $30, $30, $2C, $2C, $30,
    $28, $28, $28, $20, $20, $20, $14, $14, $14, $00, $00, $00, $CC, $B4, $88,
    $C4, $AC, $80, $C0, $A8, $7C, $B8, $A0, $74, $B4, $98, $70, $AC, $94, $68,
    $A8, $8C, $64, $A0, $88, $5C, $9C, $80, $58, $94, $7C, $54, $90, $74, $50,
    $88, $70, $48, $84, $68, $44, $7C, $64, $40, $78, $60, $3C, $70, $58, $38,
    $6C, $54, $34, $64, $4C, $30, $60, $48, $2C, $58, $44, $28, $54, $3C, $24,
    $4C, $38, $20, $48, $34, $1C, $40, $30, $18, $3C, $2C, $14, $38, $24, $14,
    $30, $20, $10, $2C, $1C, $0C, $24, $18, $08, $20, $14, $08, $18, $10, $04,
    $14, $0C, $04, $54, $BC, $AC, $4C, $B0, $A0, $48, $A4, $90, $40, $98, $84,
    $38, $8C, $78, $34, $84, $6C, $2C, $78, $60, $28, $6C, $58, $24, $60, $4C,
    $1C, $54, $40, $18, $4C, $38, $14, $40, $2C, $10, $34, $24, $0C, $28, $1C,
    $08, $1C, $14, $04, $14, $0C, $80, $E8, $64, $74, $D8, $58, $68, $C4, $4C,
    $60, $B4, $44, $54, $A8, $3C, $4C, $98, $34, $44, $88, $2C, $3C, $7C, $24,
    $34, $70, $1C, $2C, $60, $18, $24, $50, $10, $20, $44, $10, $18, $38, $0C,
    $10, $2C, $08, $0C, $20, $04, $08, $14, $04, $FC, $FC, $FC, $FC, $FC, $D0,
    $FC, $FC, $A4, $FC, $FC, $7C, $FC, $FC, $50, $FC, $FC, $24, $FC, $FC, $00,
    $FC, $E8, $00, $F0, $C8, $00, $E4, $B0, $00, $D8, $94, $00, $D0, $7C, $00,
    $C4, $68, $00, $B8, $54, $00, $AC, $40, $00, $A4, $30, $00, $B4, $B8, $FC,
    $A8, $A4, $FC, $8C, $94, $F4, $68, $70, $F4, $58, $5C, $EC, $48, $48, $E4,
    $3C, $38, $DC, $2C, $24, $D4, $1C, $10, $CC, $1C, $08, $C4, $18, $00, $B8,
    $14, $00, $9C, $10, $00, $80, $08, $00, $60, $04, $00, $44, $00, $00, $28,
    $EC, $D8, $D8, $E0, $CC, $CC, $D4, $C0, $C0, $C8, $B4, $B4, $BC, $A8, $A8,
    $B0, $9C, $9C, $A4, $90, $90, $98, $84, $84, $FC, $F4, $78, $F8, $D4, $60,
    $E4, $B8, $4C, $D4, $9C, $3C, $C0, $80, $2C, $B0, $64, $20, $9C, $4C, $14,
    $7C, $30, $10, $A0, $9C, $64, $98, $94, $60, $90, $8C, $58, $84, $80, $54,
    $7C, $78, $4C, $74, $70, $48, $6C, $68, $40, $64, $60, $3C, $58, $54, $34,
    $50, $4C, $30, $48, $44, $28, $40, $3C, $24, $38, $34, $1C, $2C, $28, $18,
    $24, $20, $10, $1C, $18, $0C, $FC, $00, $FC, $E4, $00, $E4, $CC, $00, $CC,
    $B4, $00, $B4, $98, $00, $9C, $80, $00, $84, $68, $00, $6C, $50, $00, $54,
    $FC, $E4, $E4, $FC, $D4, $C4, $FC, $C0, $A8, $FC, $B4, $8C, $FC, $A0, $70,
    $FC, $94, $54, $FC, $80, $38, $FC, $74, $18, $F0, $68, $18, $E8, $64, $10,
    $DC, $5C, $10, $D8, $58, $0C, $CC, $50, $08, $C4, $48, $00, $BC, $40, $00,
    $B4, $3C, $00, $AC, $38, $00, $A0, $34, $00, $98, $30, $00, $8C, $2C, $00,
    $84, $28, $00, $78, $24, $00, $70, $20, $00, $64, $1C, $00, $F0, $BC, $BC,
    $F0, $AC, $AC, $F4, $9C, $9C, $F4, $8C, $8C, $F4, $7C, $7C, $F4, $6C, $6C,
    $F8, $60, $60, $F8, $50, $50, $F8, $40, $40, $F8, $30, $30, $FC, $20, $20,
    $F0, $20, $20, $E0, $1C, $1C, $D4, $1C, $1C, $C4, $18, $18, $B8, $18, $18,
    $A8, $14, $14, $9C, $14, $14, $8C, $10, $10, $80, $10, $10, $70, $0C, $0C,
    $64, $0C, $0C, $54, $08, $08, $48, $08, $08, $38, $04, $04, $2C, $04, $04,
    $1C, $00, $00, $10, $00, $00, $84, $58, $58, $A0, $38, $00, $84, $58, $58,
    $FC, $F8, $FC
  );

implementation

//==============================================================================
//
// RX_ColorShiftPalette
//
//==============================================================================
procedure RX_ColorShiftPalette(const inpal: PByteArray; const outpal: PByteArray;
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

//==============================================================================
//
// RX_CopyPalette
//
//==============================================================================
procedure RX_CopyPalette(const inppal, outpal: PByteArray);
var
  i: integer;
begin
  for i := 0 to 767 do
    outpal[i] := inppal[i];
end;

//==============================================================================
//
// RX_BestColor
//
//==============================================================================
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

//==============================================================================
//
// RX_ScaleRadixPalette
//
//==============================================================================
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

//==============================================================================
//
// RX_CreateDoomPalette
//
//==============================================================================
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

  for i := 1 to 8 do
    RX_ColorShiftPalette(inppal, @outpal[768 * (i + 13)], 255, 255, 255, i, 9);

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

//==============================================================================
// RX_CreateTranslation
//
// From palette frompal to palette topal create translation table
// All arrays must be allocated in memory before calling it
//
//==============================================================================
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

