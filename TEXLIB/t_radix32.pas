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
// DESCRIPTION:
//  RADIX Paletted bitmap image format.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit t_radix32;

interface

uses
  d_delphi,
  t_main;

type
  TRadix32TextureManager = object(TTextureManager)
  private
    head_width: integer;
    head_height: integer;
    img: PLongWordArray;
  public
    constructor Create;
    function LoadHeader(stream: TDStream): boolean; virtual;
    function LoadImage(stream: TDStream): boolean; virtual;
    destructor Destroy; virtual;
  end;

implementation

constructor TRadix32TextureManager.Create;
begin
  img := nil;
  inherited Create;
  SetFileExt('.RADIX32');
end;

//==============================================================================
//
// TRadix32TextureManager.LoadHeader
//
//==============================================================================
function TRadix32TextureManager.LoadHeader(stream: TDStream): boolean;
var
  buf: PByteArray;
  bufsi: PSmallIntArray;
  x, size: integer;
  fpal: array[0..767] of byte;
  i, j: integer;
  z: integer;
  palmult: integer;
begin
  size := stream.Size;
  if size < 800 then
  begin
    result := false;
    exit;
  end;

  stream.seek(0, sFromBeginning);
  buf := malloc(size);
  stream.Read(buf^, size);
  bufsi := PSmallIntArray(buf);

  head_width := bufsi[1];
  head_height := bufsi[2];
  if size <> head_width * head_height + 800 then
  begin
    memfree(pointer(buf), size);
    result := false;
    exit;
  end;

  palmult := 4;
  for x := 0 to 767 do
  begin
    fpal[x] := buf^[32 + x];
    if fpal[x] > 63 then
      palmult := 1;
  end;

  FBitmap^.SetBytesPerPixel(4);
  FBitmap^.SetWidth(head_width);
  FBitmap^.SetHeight(head_height);

  img := mallocz(head_width * head_height * 4);

  x := 0;
  for j := 0 to head_height - 1 do
    for i := 0 to head_width - 1 do
    begin
      z := buf^[800 + j * head_width + i];
      img[x] := (fpal[3 * z] * palmult) shl 16 + (fpal[3 * z + 1] * palmult) shl 8 + (fpal[3 * z + 2] * palmult);
      inc(x);
    end;

  memfree(pointer(buf), size);
  result := true;
end;

//==============================================================================
//
// TRadix32TextureManager.LoadImage
//
//==============================================================================
function TRadix32TextureManager.LoadImage(stream: TDStream): boolean;
begin
  memcpy(FBitmap.GetImage, img, head_width * head_height * 4);
  memfree(pointer(img), head_width * head_height * 4);
  result := true;
end;

destructor TRadix32TextureManager.Destroy;
begin
  Inherited destroy;
end;

end.

