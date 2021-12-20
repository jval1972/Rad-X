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
//  DESCRIPTION:
//   Convert DOOM wad to RADIX palette
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_doom_wad;

interface

uses
  d_delphi;

function Wad2RadixPaletteWAD(const fin, fout: string): boolean;

function Wad2RadixPaletteStream(const fin: string; const strm: TDStream): boolean;

function RX_IsPaletteWAD(const fin: string): boolean;

implementation

uses
  i_system,
  e_endoom,
  r_defs,
  radix_palette,
  v_data,
  v_video,
  w_pak,
  w_wad,
  w_wadwriter,
  w_wadreader;

const
  DOOM_END_NAME = 'ENDOOM';

type
  TWADConverter = class(TObject)
  private
    wadreader: TWadReader;
    wadwriter: TWadWriter;
    xlatpalette: array[0..255] of byte;
  protected
    procedure Clear; virtual;
    function CreateXlatPalette: boolean; virtual;
    function CopyEntry(const id: integer; const newname: string = ''): boolean;
    function CreatePalette(const id: integer): boolean;
    function ConvertFlat(const id: integer): boolean;
    function ConvertPatch(const id: integer; const newname: string = ''): boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function Convert(const fname: string): boolean;
    procedure SaveToFile(const fname: string);
    procedure SaveToSream(const strm: TDStream);
  end;

constructor TWADConverter.Create;
var
  i: integer;
begin
  wadwriter := nil;
  wadreader := nil;
  for i := 0 to 255 do
    xlatpalette[i] := i;
  Inherited Create;
end;

destructor TWADConverter.Destroy;
begin
  Clear;
  Inherited;
end;

procedure TWADConverter.Clear;
begin
  if wadwriter <> nil then
  begin
    wadwriter.Free;
    wadwriter := nil;
  end;
  if wadreader <> nil then
  begin
    wadreader.Free;
    wadreader := nil;
  end;
end;

function TWADConverter.CreateXlatPalette: boolean;
var
  rpal: array[0..255] of LongWord;
  dpal: PByteArray;
  buf: pointer;
  bufsize: integer;
  i: integer;
begin
  result := wadreader.ReadEntry(DOOM_PALETTE_NAME, buf, bufsize);
  if not result then
    exit;

  for i := 0 to 255 do
    rpal[i] := def_radix_palette[3 * i] shl 16 + def_radix_palette[3 * i + 1] shl 8 + def_radix_palette[3 * i + 2];

  dpal := buf;
  for i := 0 to 255 do
    xlatpalette[i] := V_FindAproxColorIndexExcluding(@rpal, dpal[3 * i] shl 16 + dpal[3 * i + 1] shl 8 + dpal[3 * i + 2], 0, 255, 254);

  memfree(buf, bufsize);
end;

function TWADConverter.CopyEntry(const id: integer; const newname: string = ''): boolean;
var
  buf: pointer;
  bufsize: integer;
begin
  result := wadreader.ReadEntry(id, buf, bufsize);
  if not result then
    exit;

  if newname <> '' then
    wadwriter.AddData(newname, buf, bufsize)
  else
    wadwriter.AddData(wadreader.EntryName(id), buf, bufsize);

  memfree(buf, bufsize);
end;

function TWADConverter.CreatePalette(const id: integer): boolean;
begin
  wadwriter.AddData(DOOM_PALETTE_NAME, @def_radix_palette, 768);
  result := true;
end;

function TWADConverter.ConvertFlat(const id: integer): boolean;
var
  i: integer;
  buf: pointer;
  bufsize: integer;
  flat: PByteArray;
begin
  result := wadreader.ReadEntry(id, buf, bufsize);
  if not result then
    exit;

  flat := buf;
  for i := 0 to bufsize - 1 do
    flat[i] := xlatpalette[flat[i]];

  wadwriter.AddData(wadreader.EntryName(id), flat, bufsize);

  memfree(buf, bufsize);
end;

function TWADConverter.ConvertPatch(const id: integer; const newname: string = ''): boolean;
var
  buf: pointer;
  bufsize: integer;
  column: Pcolumn_t;
  patch: Ppatch_t;
  strm: TAttachableMemoryStream;
  h: array[0..3] of byte;
  N: integer;
  isimage: boolean;
  col, w: integer;
  count: integer;
  source: PByte;
begin
  result := wadreader.ReadEntry(id, buf, bufsize);
  if not result then
    exit;

  strm := TAttachableMemoryStream.Create;
  strm.Attach(buf, bufsize);

  N := strm.Read(h, 4);
  if N <> 4 then
  begin
    strm.Free;
    if newname <> '' then
      wadwriter.AddData(newname, buf, bufsize)
    else
      wadwriter.AddData(wadreader.EntryName(id), buf, bufsize);
    memfree(buf, bufsize);
    Exit;
  end;

  isimage := false;
  if (h[1] = $50) and (h[2] = $4E) and (h[3] = $47) then // PNG
    isimage := true
  else if (h[0] = $42) and (h[1] = $4D) then // BMP
    isimage := true;

  strm.Free;

  if not isimage then
  begin
    patch := buf;
    col := 0;
    w := patch.width;

    while col < w do
    begin
      column := Pcolumn_t(integer(patch) + patch.columnofs[col]);
      // step through the posts in a column
      while column.topdelta <> $ff do
      begin
        source := PByte(integer(column) + 3);
        count := column.length;

        while count > 0 do
        begin
          source^ := xlatpalette[source^];
          inc(source);
          dec(count);
        end;
        column := Pcolumn_t(integer(column) + column.length + 4);
      end;
      inc(col);
    end;
  end;

  if newname <> '' then
    wadwriter.AddData(newname, buf, bufsize)
  else
    wadwriter.AddData(wadreader.EntryName(id), buf, bufsize);

  memfree(buf, bufsize);
end;

function TWADConverter.Convert(const fname: string): boolean;
var
  i: integer;
  ind_A: array[0..IND_MAX - 1] of integer;
  flags: integer;

  function _get_lump_flags(const name: string): integer;
  var
    x: integer;
  begin
    for x := 0 to NUMINDICATORS - 1 do
    begin
      if name = char8tostring(lumpindicators[x]._START) then
      begin
        inc(ind_A[lumpindicators[x]._type]);
        Break;
      end;
      if name = char8tostring(lumpindicators[x]._END) then
      begin
        dec(ind_A[lumpindicators[x]._type]);
        if ind_A[lumpindicators[x]._type] < 0 then
          I_Warning('TWADConverter.Convert(): Lump indicators misplaced, lump #%s (%s)'#13#10, [name, char8tostring(lumpindicators[x]._END)]);
        Break;
      end;
    end;
    result := 0;
    for x := 0 to IND_MAX - 1 do
      if ind_A[x] > 0 then
        result := result or (1 shl x);
  end;

begin
  if not fexists(fname) then
  begin
    result := false;
    exit;
  end;

  Clear;

  wadreader := TWadReader.Create;
  wadreader.OpenWadFile(fname);

  if not CreateXlatPalette then
  begin
    wadreader.Free;
    result := false;
    exit;
  end;

  wadwriter := TWadWriter.Create;

  CreateXlatPalette;

  ZeroMemory(@ind_A, SizeOf(ind_A));
  for i := 0 to wadreader.NumEntries - 1 do
  begin
    if wadreader.EntryName(i) = DOOM_PALETTE_NAME then
      CreatePalette(i)
    else if wadreader.EntryName(i) = DOOM_END_NAME then
      CopyEntry(i, EndLumpName)
    else if wadreader.EntryName(i) = 'DEMO1' then
    else if wadreader.EntryName(i) = 'DEMO2' then
    else if wadreader.EntryName(i) = 'DEMO3' then
    else if wadreader.EntryName(i) = 'DEMO4' then
    else if wadreader.EntryName(i) = 'HELP1' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'HELP2' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'TITLEPIC' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'STKEYS0' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'STKEYS1' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'STKEYS2' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'STKEYS3' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'STKEYS4' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'STKEYS5' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'STDISK' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'STCDROM' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'BRDR_TL' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'BRDR_T' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'BRDR_TR' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'BRDR_L' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'BRDR_R' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'BRDR_BL' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'BRDR_B' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'BRDR_BR' then
      ConvertPatch(i)
    else if wadreader.EntryName(i) = 'M_DOOM' then
      ConvertPatch(i, 'M_RADIX')
    else
    begin
      flags := _get_lump_flags(wadreader.EntryName(i));
      if flags and TYPE_FLOOR <> 0 then
        ConvertFlat(i)
      else if flags and (TYPE_SPRITE or TYPE_PATCH) <> 0 then
        ConvertPatch(i)
      else
        CopyEntry(i);
    end;
  end;

  result := true;
end;

procedure TWADConverter.SaveToFile(const fname: string);
begin
  wadwriter.SaveToFile(fname);
end;

procedure TWADConverter.SaveToSream(const strm: TDStream);
begin
  wadwriter.SaveToStream(strm);
end;

function Wad2RadixPaletteWAD(const fin, fout: string): boolean;
var
  cnv: TWADConverter;
begin
  result := false;
  cnv := TWADConverter.Create;
  try
    if cnv.Convert(fin) then
    begin
      cnv.SaveToFile(fout);
      result := true;
    end;
  finally
    cnv.Free;
  end;
end;

function Wad2RadixPaletteStream(const fin: string; const strm: TDStream): boolean;
var
  cnv: TWADConverter;
begin
  result := false;
  cnv := TWADConverter.Create;
  try
    if cnv.Convert(fin) then
    begin
      cnv.SaveToSream(strm);
      result := true;
    end;
  finally
    cnv.Free;
  end;
end;

function RX_IsPaletteWAD(const fin: string): boolean;
var
  wadreader: TWadReader;
begin
  wadreader := TWadReader.Create;
  wadreader.OpenWadFile(fin);
  result := wadreader.EntryId(DOOM_PALETTE_NAME) >= 0;
  wadreader.Free;
end;

end.
