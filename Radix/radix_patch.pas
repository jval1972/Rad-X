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
//   Radix patches
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

unit radix_patch;

interface

uses
  d_delphi;

//==============================================================================
//
// RX_CreateDoomPatch
//
//==============================================================================
procedure RX_CreateDoomPatch(const img: PByteArray; const width, height: integer;
  const solid: boolean; out p: pointer; out size: integer; const offsx: integer = -255; const offsy: integer = -255);

//==============================================================================
//
// RX_CreateDoomPatchFromLumpData
//
//==============================================================================
procedure RX_CreateDoomPatchFromLumpData(const img: PByteArray;
  const solid: boolean; out p: pointer; out size: integer);

//==============================================================================
//
// RX_CreateDoomPatchFromLumpDataPal
//
//==============================================================================
procedure RX_CreateDoomPatchFromLumpDataPal(const img: PByteArray;
  const solid: boolean; const defpal: PLongWordArray; out p: pointer; out size: integer);

//==============================================================================
//
// RX_CreateOpaqueDoomPatchFromLumpDataPal
//
//==============================================================================
procedure RX_CreateOpaqueDoomPatchFromLumpDataPal(const img: PByteArray;
  const bgcolor: integer; const defpal: PLongWordArray; out p: pointer; out size: integer);

//==============================================================================
//
// RX_CreateDoomSkyPatch
//
//==============================================================================
procedure RX_CreateDoomSkyPatch(const img: PByteArray; out p: pointer; out size: integer);

implementation

uses
  r_defs,
  v_video;

type
  patchheader_t = packed record
    width: smallint; // bounding box size
    height: smallint;
    leftoffset: smallint; // pixels to the left of origin
    topoffset: smallint;  // pixels below the origin
  end;

//==============================================================================
//
// RX_CreateDoomPatch
//
//==============================================================================
procedure RX_CreateDoomPatch(const img: PByteArray; const width, height: integer;
  const solid: boolean; out p: pointer; out size: integer; const offsx: integer = -255; const offsy: integer = -255);
var
  x, y: integer;
  c: LongWord;
  m, fs: TDMemoryStream;
  patch: patchheader_t;
  column: column_t;
  columnofs: TDNumberList;
  columndata: TDByteList;
  i: integer;

  procedure flashcolumnend;
  begin
    column.topdelta := 255;
    column.length := 0;
    m.Write(column, SizeOf(column_t));
  end;

  procedure flashcolumndata;
  var
    bb: byte;
  begin
    if columndata.Count > 0 then
    begin
      column.topdelta := y - columndata.Count;
      column.length := columndata.Count;
      m.Write(column, SizeOf(column_t));
      bb := 0;
      m.Write(bb, SizeOf(bb));
      m.Write(columndata.List^, columndata.Count);
      m.Write(bb, SizeOf(bb));
      columndata.FastClear;
    end;
  end;

begin
  m := TDMemoryStream.Create;
  fs := TDMemoryStream.Create;
  columnofs := TDNumberList.Create;
  columndata := TDByteList.Create;
  try
    patch.width := width;
    patch.height := height;
    if offsx = -255 then
      patch.leftoffset := width div 2
    else
      patch.leftoffset := offsx;
    if offsy = -255 then
      patch.topoffset := height
    else
      patch.topoffset := offsy;
    fs.Write(patch, SizeOf(patchheader_t));

    for x := 0 to width - 1 do
    begin
      columnofs.Add(m.Position + SizeOf(patchheader_t) + width * SizeOf(integer));
      columndata.FastClear;
      for y := 0 to height - 1 do
      begin
        c := img[x * height + y];
        if not solid then
          if c = 254 then
          begin
            flashcolumndata;
            continue;
          end;
        columndata.Add(c);
      end;
      flashcolumndata;
      flashcolumnend;
    end;

    for i := 0 to columnofs.Count - 1 do
    begin
      x := columnofs.Numbers[i];
      fs.Write(x, SizeOf(integer));
    end;

    size := fs.Size + m.Size;
    p := malloc(size);

    memcpy(p, fs.Memory, fs.Size);
    memcpy(pointer(integer(p) + fs.Size), m.Memory, m.Size);

  finally
    m.Free;
    columnofs.Free;
    columndata.Free;
    fs.Free;
  end;
end;

//==============================================================================
//
// RX_CreateDoomPatchFromLumpData
//
//==============================================================================
procedure RX_CreateDoomPatchFromLumpData(const img: PByteArray;
  const solid: boolean; out p: pointer; out size: integer);
var
  x, y: integer;
  c: LongWord;
  m, fs: TDMemoryStream;
  patch: patchheader_t;
  column: column_t;
  columnofs: TDNumberList;
  columndata: TDByteList;
  i: integer;
  width, height: smallint;

  procedure flashcolumnend;
  begin
    column.topdelta := 255;
    column.length := 0;
    m.Write(column, SizeOf(column_t));
  end;

  procedure flashcolumndata;
  var
    bb: byte;
  begin
    if columndata.Count > 0 then
    begin
      column.topdelta := y - columndata.Count;
      column.length := columndata.Count;
      m.Write(column, SizeOf(column_t));
      bb := 0;
      m.Write(bb, SizeOf(bb));
      m.Write(columndata.List^, columndata.Count);
      m.Write(bb, SizeOf(bb));
      columndata.FastClear;
    end;
  end;

begin
  m := TDMemoryStream.Create;
  fs := TDMemoryStream.Create;
  columnofs := TDNumberList.Create;
  columndata := TDByteList.Create;
  width := PSmallint(@img[0])^;
  height := PSmallint(@img[2])^;
  try
    patch.width := width;
    patch.height := height;
    patch.leftoffset := 0;
    patch.topoffset := 0;
    fs.Write(patch, SizeOf(patchheader_t));

    for x := 0 to width - 1 do
    begin
      columnofs.Add(m.Position + SizeOf(patchheader_t) + width * SizeOf(integer));
      columndata.FastClear;
      for y := 0 to height - 1 do
      begin
        c := img[4 + y * width + x];
        if not solid then
          if c = 254 then
          begin
            flashcolumndata;
            continue;
          end;
        columndata.Add(c);
      end;
      flashcolumndata;
      flashcolumnend;
    end;

    for i := 0 to columnofs.Count - 1 do
    begin
      x := columnofs.Numbers[i];
      fs.Write(x, SizeOf(integer));
    end;

    size := fs.Size + m.Size;
    p := malloc(size);

    memcpy(p, fs.Memory, fs.Size);
    memcpy(pointer(integer(p) + fs.Size), m.Memory, m.Size);

  finally
    m.Free;
    columnofs.Free;
    columndata.Free;
    fs.Free;
  end;
end;

//==============================================================================
//
// RX_CreateDoomPatchFromLumpDataPal
//
//==============================================================================
procedure RX_CreateDoomPatchFromLumpDataPal(const img: PByteArray;
  const solid: boolean; const defpal: PLongWordArray; out p: pointer; out size: integer);
var
  i: integer;
  newimg: PByteArray;
  newsize: integer;
  width, height: smallint;
  r, g, b: LongWord;
  c: LongWord;
begin
  width := PSmallint(@img[2])^;
  height := PSmallint(@img[4])^;
  newsize := 4 + width * height;
  newimg := malloc(newsize);
  PSmallint(@newimg[0])^ := width;
  PSmallint(@newimg[2])^ := height;
  for i := 0 to width * height - 1 do
  begin
    r := img[32 + 3 * img[800 + i]] * 4;
    if r > 255 then r := 255;
    g := img[32 + 3 * img[800 + i] + 1] * 4;
    if g > 255 then g := 255;
    b := img[32 + 3 * img[800 + i] + 2] * 4;
    if b > 255 then b := 255;
    c := r shl 16 + g shl 8 + b;
    newimg[i + 4] := V_FindAproxColorIndex(defpal, c, 0, 255);
  end;
  RX_CreateDoomPatchFromLumpData(newimg, solid, p, size);
  memfree(pointer(newimg), newsize);
end;

//==============================================================================
//
// RX_CreateOpaqueDoomPatchFromLumpDataPal
//
//==============================================================================
procedure RX_CreateOpaqueDoomPatchFromLumpDataPal(const img: PByteArray;
  const bgcolor: integer; const defpal: PLongWordArray; out p: pointer; out size: integer);
var
  i: integer;
  newimg: PByteArray;
  newsize: integer;
  width, height: smallint;
  r, g, b: LongWord;
  c: LongWord;
begin
  width := PSmallint(@img[2])^;
  height := PSmallint(@img[4])^;
  newsize := 4 + width * height;
  newimg := malloc(newsize);
  PSmallint(@newimg[0])^ := width;
  PSmallint(@newimg[2])^ := height;
  for i := 0 to width * height - 1 do
  begin
    if img[800 + i] = bgcolor then
      newimg[i + 4] := 254
    else
    begin
      r := img[32 + 3 * img[800 + i]] * 4;
      if r > 255 then r := 255;
      g := img[32 + 3 * img[800 + i] + 1] * 4;
      if g > 255 then g := 255;
      b := img[32 + 3 * img[800 + i] + 2] * 4;
      if b > 255 then b := 255;
      c := r shl 16 + g shl 8 + b;
      newimg[i + 4] := V_FindAproxColorIndex(defpal, c, 0, 255);
      if newimg[i + 4] = 254 then
        newimg[i + 4] := 252;
    end;
  end;
  RX_CreateDoomPatchFromLumpData(newimg, false, p, size);
  memfree(pointer(newimg), newsize);
end;

//==============================================================================
//
// RX_CreateDoomSkyPatch
//
//==============================================================================
procedure RX_CreateDoomSkyPatch(const img: PByteArray; out p: pointer; out size: integer);
var
  x, y: integer;
  c: LongWord;
  m, fs: TDMemoryStream;
  patch: patchheader_t;
  column: column_t;
  columnofs: TDNumberList;
  columndata: TDByteList;
  i: integer;
  width, height: smallint;

  procedure flashcolumnend;
  begin
    column.topdelta := 255;
    column.length := 0;
    m.Write(column, SizeOf(column_t));
  end;

  procedure flashcolumndata;
  var
    bb: byte;
  begin
    if columndata.Count > 0 then
    begin
      column.topdelta := y - columndata.Count;
      column.length := columndata.Count;
      m.Write(column, SizeOf(column_t));
      bb := 0;
      m.Write(bb, SizeOf(bb));
      m.Write(columndata.List^, columndata.Count);
      m.Write(bb, SizeOf(bb));
      columndata.FastClear;
    end;
  end;

begin
  m := TDMemoryStream.Create;
  fs := TDMemoryStream.Create;
  columnofs := TDNumberList.Create;
  columndata := TDByteList.Create;
  height := PSmallint(@img[0])^;
  width := PSmallint(@img[2])^;
  try
    patch.width := width;
    patch.height := height;
    patch.leftoffset := width div 2;
    patch.topoffset := height;
    fs.Write(patch, SizeOf(patchheader_t));

    for x := 0 to width - 1 do
    begin
      columnofs.Add(m.Position + SizeOf(patchheader_t) + width * SizeOf(integer));
      columndata.FastClear;
      for y := 0 to height - 1 do
      begin
        c := img[4 + x * height + y];
        columndata.Add(c);
      end;
      flashcolumndata;
      flashcolumnend;
    end;

    for i := 0 to columnofs.Count - 1 do
    begin
      x := columnofs.Numbers[i];
      fs.Write(x, SizeOf(integer));
    end;

    size := fs.Size + m.Size;
    p := malloc(size);

    memcpy(p, fs.Memory, fs.Size);
    memcpy(pointer(integer(p) + fs.Size), m.Memory, m.Size);

  finally
    m.Free;
    columnofs.Free;
    columndata.Free;
    fs.Free;
  end;
end;

end.
