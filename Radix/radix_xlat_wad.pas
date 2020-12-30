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
//   Convert RADIX.DAT to id-tech1 WAD
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_xlat_wad;

interface

uses
  d_delphi;

const
  R2W_PALETTE = 1;
  R2W_TRANSLATION = 2;
  R2W_TEXTURES = 4;
  R2W_LEVELS = 8;
  R2W_FLATS = 16;
  R2W_MAINGRAPHICS = 32;
  R2W_ADDITIONALGRAPHICS = 64;
  R2W_SMALLMENUFONT = 128;
  R2W_BIGMENUFONT = 256;
  R2W_CONSOLEFONT = 512;
  R2W_MENUTRANSLATION = 1024;
  R2W_SPRITES = 2048;
  R2W_MUSIC = 4096;
  R2W_COCKPIT = 8192;
  R2W_SOUNDS = 16384;
  R2W_OBJECTIVES = 32768;
  R2W_ENDTEXT = 65536;
  R2W_DOOMPALETTE = $20000;
  R2W_DOOMTEXTURES = $40000;
  R2W_DOOMLEVELS = $80000;
  R2W_EXTRASPRITES = $100000;

procedure Radix2WAD_Game(const fin, fout: string);

procedure Radix2Stream_Game(const fin: string; const strm: TDStream);

procedure Radix2WAD_Edit(const fin, fout: string);

procedure Radix2Stream_Edit(const fin: string; const strm: TDStream);

procedure Radix2WAD(const fin, fout: string; const flags: LongWord);

procedure Radix2Stream(const fin: string; const strm: TDStream; const flags: LongWord);

procedure Radix2CSV(const fin: string; const pathout: string);

implementation

uses
  Math,
  i_system,
  radix_defs,
  radix_palette,
  radix_patch,
  radix_level,
  radix_things,
  radix_bitmap,
  radix_font,
  radix_sounds,
  radix_extra_sprites,
  r_defs,
  v_video,
  v_data,
  w_pak,
  w_wadwriter,
  w_wad,
  z_zone;

type
  TRadixToWADConverter = class(TObject)
  private
    wadwriter: TWadWriter;
    header: radixheader_t;
    f: TFile;
    lumps: Pradixlump_tArray;
    numlumps: integer;
    def_pal: packed array[0..767] of byte;
    def_palL: array[0..255] of LongWord;
    redfromblue_tr: array[0..255] of byte;
    greenfromblue_tr: array[0..255] of byte;
    yellowfromblue_tr: array[0..255] of byte;
    texturewidths: PIntegerArray;
    textureheights: PIntegerArray;
    aliases: TDStringList;
    textures: TDStringList;
    markflats: PBooleanArray;
    numflats: integer;
    ffilename: string;
    fmakeallflats: boolean;
    function AddPAKFileSystemEntry(const lumpname: string; const aliasname: string): boolean;
  protected
    function ReadLump(const l: Pradixlump_tArray; const numl: integer;
      const lmp: string; var buf: pointer; var size: integer): boolean;
    function FindLump(const l: Pradixlump_tArray; const numl: integer;
       const lmp: string): integer;
    procedure Clear;
    function ReadHeader: boolean;
    function ReadDirectory: boolean;
    function GeneratePalette(const pname, cname: string): boolean;
    function GenerateTranslationTables: boolean;
    function GenerateTextures(const pnames, texture1: string): boolean;
    function GenerateLevels: boolean;
    function GenerateSimpleLevels: boolean;
    function GenerateCSVs(const path: string): boolean;
    function GenerateFlats: boolean;
    function GenerateGraphicWithOutPalette(const rname, wname: string; const solid: boolean; const opaqueindex: integer = -1): boolean;
    function GenerateGraphicWithPalette(const rname, wname: string; const solid: boolean): boolean;
    function GenerateOpaqueGraphicWithPalette(const rname, wname: string; const bgcolor: byte): boolean;
    function AddEntryFromWAD(const wname: string): boolean;
    function AddEntryDirect(const wname: string; const buf: pointer; const size: integer): boolean;
    function GenerateMainGraphics: boolean;
    function GenerateAdditionalGraphics: boolean;
    function GenerateSmallFont: boolean;
    function GenerateBigFonts: boolean;
    function GenerateDosFonts: boolean;
    function GenerateMenuTranslation: boolean;
    function GenerateSprites: boolean;
    function GenerateExtraSprites: boolean;
    function GenerateMusic: boolean;
    function GenerateCockpitOverlay: boolean;
    function GenerateSounds: boolean;
    function GenerateMissionText: boolean;
    function GenerateEndText: boolean;
    procedure WritePK3Entry;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Convert_Game(const fname: string);
    procedure Convert_Edit(const fname: string);
    procedure Convert(const fname: string; const flags: LongWord);
    procedure SaveToFile(const fname: string);
    procedure SaveToSream(const strm: TDStream);
    property makeallflats: boolean read fmakeallflats write fmakeallflats;
  end;

constructor TRadixToWADConverter.Create;
begin
  f := nil;
  wadwriter := nil;
  lumps := nil;
  numlumps := 0;
  aliases := nil;
  textures := nil;
  markflats := nil;
  numflats := 0;
  texturewidths := nil;
  textureheights := nil;
  ffilename := '';
  fmakeallflats := false;
  Inherited;
end;

destructor TRadixToWADConverter.Destroy;
begin
  Clear;
  Inherited;
end;

procedure TRadixToWADConverter.Clear;
begin
  if wadwriter <> nil then
    wadwriter.Free;

  if f <> nil then
    f.Free;

  if aliases <> nil then
    aliases.Free;

  if textures <> nil then
    textures.Free;

  if markflats <> nil then
    memfree(pointer(markflats), numflats * SizeOf(boolean));

  if texturewidths <> nil then
    memfree(pointer(texturewidths), numflats * SizeOf(integer));

  if textureheights <> nil then
    memfree(pointer(textureheights), numflats * SizeOf(integer));

  if numlumps <> 0 then
  begin
    memfree(pointer(lumps), numlumps * SizeOf(radixlump_t));
    numlumps := 0;
  end;
end;

function TRadixToWADConverter.AddPAKFileSystemEntry(const lumpname: string; const aliasname: string): boolean;
var
  lump: integer;
begin
  lump := FindLump(lumps, numlumps, lumpname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;

  result := true;

  PAK_AddEntry(lumps[lump].position, lumps[lump].length, aliasname, ffilename);
end;

function TRadixToWADConverter.ReadLump(const l: Pradixlump_tArray; const numl: integer;
  const lmp: string; var buf: pointer; var size: integer): boolean;
var
  i: integer;
begin
  for i := 0 to numl - 1 do
    if radixlumpname(l[i]) = lmp then
    begin
      f.Seek(l[i].position, sFrombeginning);
      size := l[i].length;
      buf := malloc(size);
      f.Read(buf^, size);
      result := true;
      exit;
    end;
  buf := nil;
  size := 0;
  result := false;
end;

function TRadixToWADConverter.FindLump(const l: Pradixlump_tArray; const numl: integer;
  const lmp: string): integer;
var
  i: integer;
begin
  for i := 0 to numl - 1 do
    if radixlumpname(l[i]) = lmp then
    begin
      result := i;
      exit;
    end;
  result := -1;
end;

function TRadixToWADConverter.ReadHeader: boolean;
var
  i: integer;
  s: string;
begin
  f.Seek(0, sFromBeginning);
  f.Read(header, SizeOf(radixheader_t));
  s := '';
  for i := 0 to 10 do
    s := s + header.id[i];
  result := s = 'NSRes:Radix';
end;

function TRadixToWADConverter.ReadDirectory: boolean;
begin
  numlumps := header.numlumps;
  lumps := mallocz(numlumps * SizeOf(radixlump_t));
  f.Seek(header.start, sFromBeginning);
  result := f.Read(lumps^, numlumps * SizeOf(radixlump_t)) = numlumps * SizeOf(radixlump_t);
end;

function TRadixToWADConverter.GeneratePalette(const pname, cname: string): boolean;
var
  p: pointer;
  pal: PByteArray;
  size: integer;
  playpal: packed array[0..768 * 22 - 1] of byte;
  colormap: packed array[0..34 * 256 - 1] of byte;
  i: integer;
  r, g, b: LongWord;
begin
  result := ReadLump(lumps, numlumps, 'Palette[1]', p, size);
  if not result then
    exit;
  pal := p;
  RX_CreateDoomPalette(pal, @playpal, @colormap);

  // Keep def_pal AFTER RX_CreateDoomPalette call
  for i := 0 to 767 do
  begin
    def_pal[i] := pal[i];
    def_radix_palette[i] := pal[i];
  end;
  for i := 0 to 255 do
  begin
    r := def_pal[3 * i];
    if r > 255 then r := 255;
    g := def_pal[3 * i + 1];
    if g > 255 then g := 255;
    b := def_pal[3 * i + 2];
    if b > 255 then b := 255;
    def_palL[i] := (r shl 16) + (g shl 8) + (b);
  end;

  wadwriter.AddData(pname, @playpal, SizeOf(playpal));
  wadwriter.AddData(cname, @colormap, SizeOf(colormap));
  memfree(p, size);
end;

function TRadixToWADConverter.GenerateTranslationTables: boolean;
var
  p1, p2, p3: pointer;
  pal1, pal2, pal3: PByteArray;
  size1, size2, size3: integer;
  ret1, ret2, ret3: boolean;
begin
  ret1 := ReadLump(lumps, numlumps, 'RedFromBluePal', p1, size1);
  pal1 := p1;
  RX_ScaleRadixPalette(pal1);

  ret2 := ReadLump(lumps, numlumps, 'GreenFromBluePal', p2, size2);
  pal2 := p2;
  RX_ScaleRadixPalette(pal2);

  ret3 := ReadLump(lumps, numlumps, 'YellowFromBluePal', p3, size3);
  pal3 := p3;
  RX_ScaleRadixPalette(pal3);

  result := ret1 and ret2 and ret3;

  if result then
  begin
    RX_CreateTranslation(@def_pal, pal1, @redfromblue_tr);
    wadwriter.AddData('TRN_RED', @redfromblue_tr, 256);
    RX_CreateTranslation(@def_pal, pal2, @greenfromblue_tr);
    wadwriter.AddData('TRN_GREE', @greenfromblue_tr, 256);
    RX_CreateTranslation(@def_pal, pal3, @yellowfromblue_tr);
    wadwriter.AddData('TRN_YELL', @yellowfromblue_tr, 256);
  end;

  memfree(p1, size1);
  memfree(p2, size2);
  memfree(p3, size3);
end;

function TRadixToWADConverter.GenerateTextures(const pnames, texture1: string): boolean;
var
  position: integer;
  bstart: integer;
  bnumlumps: word;
  blumps: Pradixbitmaplump_tArray;
  i: integer;
  buf: PByteArray;
  bufsize: integer;
  p: pointer;
  size: integer;
  stmp: string;
  mp, mt: TDMemoryStream;
  psize: integer;
  c8: char8_t;
  tex: maptexture_t;
  extraskypatch: mappatch_t;
  texname: string;
  foundsky: boolean;
begin
  i := FindLump(lumps, numlumps, 'WallBitmaps');
  if i < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  position := lumps[i].position;
  f.Seek(position, sFromBeginning);
  f.Read(bnumlumps, SizeOf(word));

  blumps := mallocz(bnumlumps * SizeOf(radixbitmaplump_t));

  // Keep flats after loading levels
  numflats := bnumlumps + 1;
  markflats := mallocz(numflats * SizeOf(boolean));
  texturewidths := mallocz(numflats * SizeOf(integer));
  textureheights := mallocz(numflats * SizeOf(integer));

  f.Read(bstart, SizeOf(integer));
  f.Seek(bstart, sFromBeginning);
  f.Read(blumps^, bnumlumps * SizeOf(radixbitmaplump_t));

  wadwriter.AddSeparator('P_START');

  mp := TDMemoryStream.Create;  // PNAMES
  mt := TDMemoryStream.Create;  // TEXTURE1

  psize := bnumlumps + 7; // 1 stub + 3x2 skies

  // PNAMES header
  mp.Write(psize, SizeOf(integer));

  // TEXTURE1 header
  psize := psize - 3; // 3 less - count for double skies
  mt.Write(psize, SizeOf(integer));
  psize := 0;
  for i := 0 to bnumlumps do
  begin
    psize := (bnumlumps + 4) * 4 + 4 + i * SizeOf(maptexture_t);
    mt.Write(psize, SizeOf(integer));
  end;
  // Skies have two patches
  for i := 1 to 3 do
  begin
    psize := psize + SizeOf(maptexture_t);
    if i > 1 then
      psize := psize + SizeOf(mappatch_t);
    mt.Write(psize, SizeOf(integer));
  end;

  // Stub texture
  buf := mallocz(32 * 32);
  RX_CreateDoomPatch(buf, 32, 32, true, p, size);
  texturewidths[0] := 32;
  textureheights[0] := 32;
  stmp := RX_WALL_PREFIX + '0000';
  wadwriter.AddData(stmp, p, size);
  memfree(p, size);

  // Save PNAMESx entry
  c8 := stringtochar8(stmp);
  mp.Write(c8, 8);

  // Save TEXTUREx entry
  ZeroMemory(@tex, SizeOf(maptexture_t));
  tex.name := c8;
  tex.width := 32;
  tex.height := 32;
  tex.patchcount := 1;
  tex.patches[0].patch := 0;
  mt.Write(tex, SizeOf(maptexture_t));

  memfree(pointer(buf), 32 * 32);

  for i := 0 to bnumlumps - 1 do
  begin
    buf := malloc(blumps[i].width * blumps[i].height);

    f.Seek(blumps[i].position, sFromBeginning);
    f.Read(buf^, blumps[i].width * blumps[i].height);

    RX_CreateDoomPatch(buf, blumps[i].width, blumps[i].height, true, p, size);
    texturewidths[i + 1] := blumps[i].width;
    textureheights[i + 1] := blumps[i].height;
    if blumps[i].width = blumps[i].height then
      markflats[i + 1] := true;

    stmp := RX_WALL_PREFIX + IntToStrZFill(4, i + 1);
    wadwriter.AddData(stmp, p, size);
    memfree(p, size);

    // Save PNAMESx entry
    c8 := stringtochar8(stmp);
    mp.Write(c8, 8);

    // Save TEXTUREx entry
    ZeroMemory(@tex, SizeOf(maptexture_t));
    tex.name := c8;
    tex.width := blumps[i].width;
    tex.height := blumps[i].height;
    tex.patchcount := 1;
    tex.patches[0].patch := i + 1;
    mt.Write(tex, SizeOf(maptexture_t));

    texname := radixlumpname(blumps[i]);
    // Save PK3ENTRY entry
    aliases.Add(stmp + '=' + texname);

    // Save Texture name
    textures.Add(texname);

    memfree(pointer(buf), blumps[i].width * blumps[i].height);
  end;

  extraskypatch.originx := 256;
  extraskypatch.originy := 0;
  for i := 1 to 3 do
  begin
    foundsky := FindLump(lumps, numlumps, 'MainEpisodeImage[' + itoa(i) + ']') >= 0;
    if foundsky then
      texname := 'MainEpisodeImage[' + itoa(i) + ']'
    else
      texname := 'MainEpisodeImage[1]';
    if ReadLump(lumps, numlumps, texname, pointer(buf), bufsize) then
    begin
      RX_CreateDoomSkyPatch(buf, p, size);

      stmp := 'RSKY' + itoa(i);
      wadwriter.AddData(stmp, p, size);

      // Save PNAMESx entry
      c8 := stringtochar8(stmp);
      mp.Write(c8, 8);

      // Save TEXTUREx entry
      ZeroMemory(@tex, SizeOf(maptexture_t));
      tex.name := stringtochar8('SKY' + itoa(i));
      tex.width := PSmallIntArray(p)[0] * 2;
      tex.height := PSmallIntArray(p)[1];
      memfree(p, size);
      tex.patchcount := 2;
      tex.patches[0].patch := bnumlumps + 2 * i - 1;
      mt.Write(tex, SizeOf(maptexture_t));

      // Save PK3ENTRY entry
      if foundsky then
        aliases.Add(stmp + '=' + texname);

      // Save Texture name
      textures.Add('SKY' + itoa(i));

      memfree(pointer(buf), bufsize);
    end;

    if foundsky then
      texname := 'FillEpisodeImage[' + itoa(i) + ']'
    else
      texname := 'FillEpisodeImage[1]';
    if ReadLump(lumps, numlumps, texname, pointer(buf), bufsize) then
    begin
      RX_CreateDoomSkyPatch(buf, p, size);

      stmp := 'RSKY' + itoa(i) + 'B';
      wadwriter.AddData(stmp, p, size);

      // Save PNAMESx entry
      c8 := stringtochar8(stmp);
      mp.Write(c8, 8);

      // Save TEXTUREx entry - extra patch
      memfree(p, size);
      extraskypatch.patch := bnumlumps + 2 * i;
      mt.Write(extraskypatch, SizeOf(mappatch_t));

      // Save PK3ENTRY entry
      if foundsky then
        aliases.Add(stmp + '=' + texname);

      memfree(pointer(buf), bufsize);
    end;
  end;

  wadwriter.AddSeparator('P_END');

  wadwriter.AddData(texture1, mt.Memory, mt.Size);
  wadwriter.AddData(pnames, mp.Memory, mp.Size);

  mp.Free;
  mt.Free;

  memfree(pointer(blumps), bnumlumps * SizeOf(radixbitmaplump_t));

end;

function TRadixToWADConverter.GenerateLevels: boolean;
var
  i, j: integer;
  rlevel: pointer;
  rsize: integer;
  ret: boolean;
begin
  result := false;

  for i := 1 to 3 do
    for j := 1 to 9 do
    begin
      if ReadLump(lumps, numlumps, 'WorldData[' + itoa(i) +'][' + itoa(j) + ']', rlevel, rsize) then
      begin
        ret := RX_CreateDoomLevel('E' + itoa(i) + 'M' + itoa(j), rlevel, rsize, markflats, texturewidths, textureheights, true, wadwriter);
        result := result or ret;
        memfree(rlevel, rsize);
      end;
    end;
end;

function TRadixToWADConverter.GenerateSimpleLevels: boolean;
var
  i, j: integer;
  rlevel: pointer;
  rsize: integer;
  ret: boolean;
begin
  result := false;

  for i := 1 to 3 do
    for j := 1 to 9 do
    begin
      if ReadLump(lumps, numlumps, 'WorldData[' + itoa(i) +'][' + itoa(j) + ']', rlevel, rsize) then
      begin
        ret := RX_CreateDoomLevel('E' + itoa(i) + 'M' + itoa(j), rlevel, rsize, markflats, texturewidths, textureheights, false, wadwriter);
        result := result or ret;
        memfree(rlevel, rsize);
      end;
    end;
end;

function TRadixToWADConverter.GenerateCSVs(const path: string): boolean;
var
  i, j: integer;
  rlevel: pointer;
  rsize: integer;
  ret: boolean;

  procedure CreateAll(const prefix: string);
  var
    ii, jj, kk: integer;
    lsts: array[1..3,1..9] of TDStringList;
    l: TDStringList;
    finp: string;
    apath: string;
    header: string;
  begin
    apath := path;
    if apath <> '' then
      if apath[length(apath)] <> '\' then
        apath := apath + '\';
    header := '';
    for ii := 1 to 3 do
      for jj := 1 to 9 do
      begin
        lsts[ii, jj] := TDStringList.Create;
        finp := apath + '\' + 'E' + itoa(ii) + 'M' + itoa(jj) + '_' + prefix + '.txt';
        if fexists(finp) then
        begin
          lsts[ii, jj].LoadFromFile(finp);
          if lsts[ii, jj].Count > 0 then
          begin
            header := 'level' + ',' + lsts[ii, jj].Strings[0];
            lsts[ii, jj].Delete(0);
          end;
        end;
      end;
    l := TDStringList.Create;
    l.Add(header);
    for ii := 1 to 3 do
      for jj := 1 to 9 do
      begin
        for kk := 0 to lsts[ii, jj].Count - 1 do
          l.Add('E' + itoa(ii) + 'M' + itoa(jj) + ',' + lsts[ii, jj].Strings[kk]);
        lsts[ii, jj].Free;
      end;
    l.SaveToFile(apath + '\' + 'ALL' + '_' + prefix + '.txt');
    l.Free;
  end;

begin
  result := true;

  for i := 1 to 3 do
    for j := 1 to 9 do
    begin
      if ReadLump(lumps, numlumps, 'WorldData[' + itoa(i) +'][' + itoa(j) + ']', rlevel, rsize) then
      begin
        ret := RX_CreateRadixMapCSV('E' + itoa(i) + 'M' + itoa(j), path, rlevel, rsize);
        result := result or ret;
        memfree(rlevel, rsize);
      end;
    end;

  CreateAll('sectors');
  CreateAll('actions');
  CreateAll('things');
  CreateAll('walls');
  CreateAll('triggers');
  CreateAll('gridtable1');
  CreateAll('gridtable2');
end;


function TRadixToWADConverter.GenerateFlats: boolean;
type
  flat32x32_t = packed array[0..31, 0..31] of byte;
  flat32x32_p = ^flat32x32_t;
  flat32x64_t = packed array[0..31, 0..63] of byte;
  flat32x64_p = ^flat32x64_t;
  flat32x128_t = packed array[0..31, 0..127] of byte;
  flat32x128_p = ^flat32x128_t;
  flat64x64_t = packed array[0..63, 0..63] of byte;
  flat64x64_p = ^flat64x64_t;
  flat64x128_t = packed array[0..63, 0..127] of byte;
  flat64x128_p = ^flat64x128_t;
  flat128x64_t = packed array[0..127, 0..63] of byte;
  flat128x64_p = ^flat128x64_t;
  flat128x128_t = packed array[0..127, 0..127] of byte;
  flat128x128_p = ^flat128x128_t;
var
  position: integer;
  bstart: integer;
  bnumlumps: word;
  blumps: Pradixbitmaplump_tArray;
  i, j, k: integer;
  buf: PByteArray;
  f32x32: flat32x32_p;
  f32x64: flat32x64_p;
  f32x128: flat32x128_p;
  f64x64: flat64x64_p;
  buf64x64: flat64x64_p;
  f64x128: flat64x128_p;
  f128x64: flat128x64_p;
  f128x128: flat128x128_p;
  buf128x128: flat128x128_p;
  stmp: string;
  c: byte;
  t: integer;
begin
  i := FindLump(lumps, numlumps, 'WallBitmaps');
  if i < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  position := lumps[i].position;
  f.Seek(position, sFromBeginning);
  f.Read(bnumlumps, SizeOf(word));

  blumps := mallocz(bnumlumps * SizeOf(radixbitmaplump_t));

  f.Read(bstart, SizeOf(integer));
  f.Seek(bstart, sFromBeginning);
  f.Read(blumps^, bnumlumps * SizeOf(radixbitmaplump_t));

  wadwriter.AddSeparator('F_START');

  t := FindLump(lumps, numlumps, 'TileBitmap');
  if t >= 0 then
    if lumps[t].length = 4100 then
    begin
      buf := malloc(4096);

      f.Seek(lumps[t].position + 4, sFromBeginning);
      f.Read(buf^, 4096);

      for i := 0 to 4095 do
        if buf[i] = 0 then
          buf[i] := 63;

      stmp := RX_FLAT_PREFIX + '0000';
      wadwriter.AddData(stmp, buf, 4096);

      memfree(pointer(buf), 4096);
    end;

  for i := 0 to bnumlumps - 1 do
    if fmakeallflats or markflats[i + 1] then
    begin
      buf := malloc(blumps[i].width * blumps[i].height);

      f.Seek(blumps[i].position, sFromBeginning);
      f.Read(buf^, blumps[i].width * blumps[i].height);

      stmp := RX_FLAT_PREFIX + IntToStrZFill(4, i + 1);

      if (blumps[i].width = 32) and (blumps[i].height = 32) then
      begin
        f32x32 := flat32x32_p(buf);
        f64x64 := malloc(SizeOf(flat64x64_t));
        for j := 0 to 31 do
          for k := 0 to 31 do
          begin
            f64x64[k, j] := f32x32[j, k];
            f64x64[k, j + 32] := f32x32[j, k];
            f64x64[k + 32, j] := f32x32[j, k];
            f64x64[k + 32, j + 32] := f32x32[j, k];
          end;
        wadwriter.AddData(stmp, f64x64, 64 * 64);
        memfree(pointer(f64x64), SizeOf(flat64x64_t));
      end
      else if (blumps[i].width = 32) and (blumps[i].height = 64) then
      begin
        f32x64 := flat32x64_p(buf);
        f64x64 := malloc(SizeOf(flat64x64_t));
        for j := 0 to 31 do
          for k := 0 to 63 do
          begin
            f64x64[k, j] := f32x64[j, k];
            f64x64[k, j + 32] := f32x64[j, k];
          end;
        wadwriter.AddData(stmp, f64x64, 64 * 64);
        memfree(pointer(f64x64), SizeOf(flat64x64_t));
      end
      else if (blumps[i].width = 32) and (blumps[i].height = 128) then
      begin
        f32x128 := flat32x128_p(buf);
        f128x128 := malloc(SizeOf(flat128x128_t));
        for j := 0 to 31 do
          for k := 0 to 127 do
          begin
            f128x128[k, j] := f32x128[j, k];
            f128x128[k, j + 32] := f32x128[j, k];
            f128x128[k, j + 64] := f32x128[j, k];
            f128x128[k, j + 96] := f32x128[j, k];
          end;
        wadwriter.AddData(stmp, f128x128, 128 * 128);
        memfree(pointer(f128x128), SizeOf(flat128x128_t));
      end
      else if (blumps[i].width = 64) and (blumps[i].height = 128) then
      begin
        f64x128 := flat64x128_p(buf);
        f128x128 := malloc(SizeOf(flat128x128_t));
        for j := 0 to 63 do
          for k := 0 to 127 do
          begin
            f128x128[k, j] := f64x128[j, k];
            f128x128[k, j + 64] := f64x128[j, k];
          end;
        wadwriter.AddData(stmp, f128x128, 128 * 128);
        memfree(pointer(f128x128), SizeOf(flat128x128_t));
      end
      else if (blumps[i].width = 128) and (blumps[i].height = 64) then
      begin
        f128x64 := flat128x64_p(buf);
        f128x128 := malloc(SizeOf(flat128x128_t));
        for j := 0 to 127 do
          for k := 0 to 63 do
          begin
            f128x128[k, j] := f128x64[j, k];
            f128x128[k + 64, j] := f128x64[j, k];
          end;
        wadwriter.AddData(stmp, f128x128, 128 * 128);
        memfree(pointer(f128x128), SizeOf(flat128x128_t));
      end
      else if (blumps[i].width = 64) and (blumps[i].height = 64) then
      begin
        buf64x64 := flat64x64_p(buf);
        f64x64 := malloc(SizeOf(flat64x64_t));
        for j := 0 to 63 do
          for k := 0 to 63 do
            f64x64[k, j] := buf64x64[j, k];
        wadwriter.AddData(stmp, f64x64, 64 * 64);
        memfree(pointer(f64x64), SizeOf(flat64x64_t));
      end
      else if (blumps[i].width = 128) and (blumps[i].height = 128) then
      begin
        buf128x128 := flat128x128_p(buf);
        f128x128 := malloc(SizeOf(flat128x128_t));
        for j := 0 to 127 do
          for k := 0 to 127 do
            f128x128[k, j] := buf128x128[j, k];
        wadwriter.AddData(stmp, f128x128, 128 * 128);
        memfree(pointer(f128x128), SizeOf(flat128x128_t));
      end
      else
        wadwriter.AddData(stmp, buf, blumps[i].width * blumps[i].height);

      memfree(pointer(buf), blumps[i].width * blumps[i].height);
    end;

  // Create F_SKY1
  buf := malloc(64 * 64);
  c := V_FindAproxColorIndex(@def_palL, 77 shl 16 + 179 shl 8 + 255);
  memset(buf, c, 64 * 64);
  wadwriter.AddData('F_SKY1', buf, 64 * 64);
  memfree(pointer(buf), 64 * 64);

  wadwriter.AddSeparator('F_END');

  memfree(pointer(blumps), bnumlumps * SizeOf(radixbitmaplump_t));
end;

function TRadixToWADConverter.GenerateGraphicWithOutPalette(const rname, wname: string;
  const solid: boolean; const opaqueindex: integer = -1): boolean;
var
  lump: integer;
  buf: pointer;
  bufsize: integer;
  p: pointer;
  i, size: integer;
  pb: PByteArray;
begin
  lump := FindLump(lumps, numlumps, rname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  bufsize := lumps[lump].length;
  buf := malloc(bufsize);
  f.Seek(lumps[lump].position, sFromBeginning);
  f.Read(buf^, bufsize);

  if not solid and (opaqueindex >= 0) then
  begin
    pb := buf;
    for i := 4 to bufsize - 1 do
    begin
      if pb[i] = opaqueindex then
        pb[i] := 254
      else if pb[i] = 254 then
        pb[i] := 252;
    end;
  end;

  RX_CreateDoomPatchFromLumpData(buf, solid, p, size);

  wadwriter.AddData(wname, p, size);
  memfree(p, size);
  memfree(buf, bufsize);
end;

function TRadixToWADConverter.GenerateGraphicWithPalette(const rname, wname: string; const solid: boolean): boolean;
var
  lump: integer;
  buf: pointer;
  bufsize: integer;
  p: pointer;
  size: integer;
begin
  lump := FindLump(lumps, numlumps, rname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  bufsize := lumps[lump].length;
  buf := malloc(bufsize);
  f.Seek(lumps[lump].position, sFromBeginning);
  f.Read(buf^, bufsize);

  RX_CreateDoomPatchFromLumpDataPal(buf, solid, @def_palL, p, size);

  wadwriter.AddData(wname, p, size);
  memfree(p, size);
  memfree(buf, bufsize);
end;

function TRadixToWADConverter.GenerateOpaqueGraphicWithPalette(const rname, wname: string; const bgcolor: byte): boolean;
var
  lump: integer;
  buf: pointer;
  bufsize: integer;
  p: pointer;
  size: integer;
begin
  lump := FindLump(lumps, numlumps, rname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  bufsize := lumps[lump].length;
  buf := malloc(size);
  f.Seek(lumps[lump].position, sFromBeginning);
  f.Read(buf^, bufsize);

  RX_CreateOpaqueDoomPatchFromLumpDataPal(buf, bgcolor, @def_palL, p, size);

  wadwriter.AddData(wname, p, size);
  memfree(p, size);
  memfree(buf, bufsize);
end;

function TRadixToWADConverter.AddEntryFromWAD(const wname: string): boolean;
var
  lump: integer;
  buf: pointer;
begin
  lump := W_CheckNumForName(wname);
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  buf := W_CacheLumpName(wname, PU_STATIC);
  wadwriter.AddData(wname, buf, W_LumpLength(lump));
  Z_ChangeTag(buf, PU_CACHE);
end;

function TRadixToWADConverter.AddEntryDirect(const wname: string; const buf: pointer; const size: integer): boolean;
begin
  wadwriter.AddData(wname, buf, size);
  result := true;
end;

function TRadixToWADConverter.GenerateMainGraphics: boolean;
var
  rname, wname: string;
  i: integer;
begin
  for i := 1 to 99 do
  begin
    rname := 'OrderInfo[' + itoa(i) + ']';
    wname := 'HELP' + IntToStrzFill(2, i);
    if not GenerateGraphicWithOutPalette(rname, wname, true) then
      break;
    aliases.Add(wname + '=' + rname);
  end;

  rname := 'MainTitle';
  wname := 'TITLEPIC';
  GenerateGraphicWithPalette(rname, wname, true);
  AddPAKFileSystemEntry(rname, wname + '.RADIX32');
  aliases.Add(wname + '=' + rname);

  rname := 'DemoDecal';
  wname := 'M_RADIX';
  GenerateOpaqueGraphicWithPalette(rname, wname, 0);
  aliases.Add(wname + '=' + rname);

  rname := 'BriefScreen';
  wname := 'M_BRIEF';
  GenerateOpaqueGraphicWithPalette(rname, wname, 0);
  aliases.Add(wname + '=' + rname);

  result := true;
end;

function TRadixToWADConverter.GenerateAdditionalGraphics: boolean;
var
  i, j, patchid: integer;

  procedure AddGraphicWithPalette(const rname: string);
  var
    wname: string;
  begin
    wname := 'RADIX' + IntToStrzFill(3, patchid);
    if GenerateGraphicWithPalette(rname, wname, true) then
    begin
      aliases.Add(wname + '=' + rname);
      inc(patchid);
    end;
  end;

  procedure AddGraphicWithOutPalette(const rname: string; const opaqueindex: integer = -1; const wnameset: string = '');
  var
    wname: string;
  begin
    if wnameset = '' then
      wname := 'RADIX' + IntToStrzFill(3, patchid)
    else
      wname := wnameset;
    if GenerateGraphicWithOutPalette(rname, wname, false, opaqueindex) then
    begin
      aliases.Add(wname + '=' + rname);
      inc(patchid);
    end;
  end;

  function AddWeaponNums(const lumpname: string): boolean;
  var
    lump: integer;
    buf: pointer;
    bufsize: integer;
    imginp: PByteArray;
    imgout: PByteArray;
    j: integer;
    p: pointer;
    size: integer;
    wname: string;
    rname: string;
  begin
    lump := FindLump(lumps, numlumps, lumpname);
    if lump < 0 then
    begin
      result := false;
      exit;
    end;
    if lumps[lump].length <> 508 then
    begin
      result := false;
      exit;
    end;
    result := true;

    bufsize := lumps[lump].length;
    buf := malloc(lumps[lump].length);
    f.Seek(lumps[lump].position, sFromBeginning);
    f.Read(buf^, bufsize);

    imginp := @PByteArray(buf)[4];
    RX_ColorReplace(imginp, 56, 9, 254, 252);
    RX_RotatebitmapBuffer90(imginp, 56, 9);
    imgout := malloc(8 * 9);

    for j := 1 to 7 do
    begin
      RX_BltImageBuffer(imginp, 56, 9, imgout, (j - 1) * 8, j * 8 - 1, 0, 8);
      RX_CreateDoomPatch(imgout, 8, 9, false, p, size, 0, 0);

      wname := 'RADIX' + IntToStrzFill(3, patchid);
      rname := lumpname + itoa(j);
      inc(patchid);

      wadwriter.AddData(wname, p, size);
      memfree(p, size);

      aliases.Add(wname + '=' + rname);
    end;

    memfree(pointer(imgout), 8 * 9);
    memfree(pointer(buf), lumps[lump].length);
  end;

begin
  result := true;

  patchid := 1;

  AddGraphicWithPalette('SelectSkill');
  AddGraphicWithPalette('SkillButton1');
  AddGraphicWithPalette('SkillButton2');
  AddGraphicWithPalette('SkillButton3');
  AddGraphicWithPalette('SkillButton4');
  AddGraphicWithPalette('PlayerNameBox');
  AddGraphicWithPalette('SelectEpisode');
  AddGraphicWithPalette('EpisodeButton1');
  AddGraphicWithPalette('EpisodeButton2');
  AddGraphicWithPalette('EpisodeButton3');
  AddGraphicWithPalette('SkillPicture1');
  AddGraphicWithPalette('SkillPicture2');
  AddGraphicWithPalette('SkillPicture3');
  AddGraphicWithPalette('SkillPicture4');
  AddGraphicWithPalette('TopTenScreen');
  AddGraphicWithPalette('NetworkMenu');
  AddGraphicWithPalette('NetworkMenuOverlay');
  AddGraphicWithPalette('StatsScreen');
  AddGraphicWithPalette('DebriefScreen1');
  AddGraphicWithPalette('DebriefScreen2');
  AddGraphicWithPalette('DebriefScreen3');
  AddGraphicWithPalette('NetDebriefScreen');
  AddGraphicWithPalette('NetFlag');
  AddGraphicWithPalette('StartLogo');
  AddGraphicWithPalette('MainMenu');
  AddGraphicWithPalette('MainMenuButton1');
  AddGraphicWithPalette('MainMenuButton2');
  AddGraphicWithPalette('MainMenuButton3');
  AddGraphicWithPalette('MainMenuButton4');
  AddGraphicWithPalette('MainMenuButton5');
  AddGraphicWithPalette('MainMenuButton6');
  AddGraphicWithPalette('MainMenuButton7');
  AddGraphicWithPalette('MainMenuButton8');
  AddGraphicWithPalette('OptionMenu');
  AddGraphicWithPalette('Option1');
  AddGraphicWithPalette('Option2');
  AddGraphicWithPalette('Option3');
  AddGraphicWithPalette('NeuralLogo');

  AddGraphicWithOutPalette('ArmourBar');
  AddGraphicWithOutPalette('BackViewOn', 0);
  AddGraphicWithOutPalette('CockpitNumOn', 0);
  AddGraphicWithOutPalette('CockpitNumUse', 0);
  AddGraphicWithOutPalette('CockPitRadar');
  AddGraphicWithOutPalette('CrossHair', 0);
  AddGraphicWithOutPalette('CrossLock1', 0);
  AddGraphicWithOutPalette('CrossLock2', 0);
  AddGraphicWithOutPalette('CrossLock3', 0);
  AddGraphicWithOutPalette('CrossLock4', 0);
  AddGraphicWithOutPalette('CrossLock5', 0);
  AddGraphicWithOutPalette('CrossLock6', 0);
  AddGraphicWithOutPalette('EnergyBar');
  AddGraphicWithOutPalette('EnhancedEPCWeaponPicture');
  AddGraphicWithOutPalette('HelpScreen');
  AddGraphicWithOutPalette('HelpScreen2');
  AddGraphicWithOutPalette('LeftArrow', 0);
  AddGraphicWithOutPalette('MissionBack');
  AddGraphicWithOutPalette('MissionBegin');
  AddGraphicWithOutPalette('MissionForward');
  AddGraphicWithOutPalette('MissionLoad');
  AddGraphicWithOutPalette('MissionPause');
  AddGraphicWithOutPalette('MissionQuit');
  AddGraphicWithOutPalette('MissionReverse');
  AddGraphicWithOutPalette('MissionSave');
  AddGraphicWithOutPalette('MissionScreen');
  AddGraphicWithOutPalette('MissionStats');
  AddGraphicWithOutPalette('NetworkChatScreen');
  AddGraphicWithOutPalette('PlasmaIcon', 0);
  AddGraphicWithOutPalette('PowerUpIcon[1]', 0);
  AddGraphicWithOutPalette('PowerUpIcon[2]', 0);
  AddGraphicWithOutPalette('PowerUpIcon[3]', 0);
  AddGraphicWithOutPalette('PowerUpIcon[4]', 0);
  AddGraphicWithOutPalette('PowerUpIcon[5]', 0);
  AddGraphicWithOutPalette('RadarOverlay');
  AddGraphicWithOutPalette('RightArrow', 0);
  AddGraphicWithOutPalette('SaveLoadScreen');
  AddGraphicWithOutPalette('ShieldBar');
  AddGraphicWithOutPalette('SmallCrossHair', 0);
  AddGraphicWithOutPalette('SmallCrossLock', 0);
  AddGraphicWithOutPalette('StatAmmo1');
  AddGraphicWithOutPalette('StatAmmo2');
  AddGraphicWithOutPalette('StatAmmo3');
  AddGraphicWithOutPalette('StatAmmo4');
  AddGraphicWithOutPalette('StatAmmo5');
  AddGraphicWithOutPalette('StatAmmo6');
  AddGraphicWithOutPalette('StatAmmo7');
  AddGraphicWithOutPalette('StatAmmo8');
  AddGraphicWithOutPalette('StatusBarFlag');
  AddGraphicWithOutPalette('StatusBarImage');
  AddGraphicWithOutPalette('StatusBarKill');
  AddGraphicWithOutPalette('SuperEPCWeaponPicture');
  AddGraphicWithOutPalette('ThreatOffMap');
  AddGraphicWithOutPalette('ThreatOnMap');
  AddGraphicWithOutPalette('TileBitmap');
  AddGraphicWithOutPalette('Weapon1Image');
  AddGraphicWithOutPalette('Weapon2Image');
  AddGraphicWithOutPalette('Weapon3Image');
  AddGraphicWithOutPalette('Weapon4Image');
  AddGraphicWithOutPalette('Weapon5Image');
  AddGraphicWithOutPalette('Weapon6Image');
  AddGraphicWithOutPalette('Weapon7Image');
  AddGraphicWithOutPalette('WeaponNumOff');
  AddGraphicWithOutPalette('WeaponNumOn');
  AddGraphicWithOutPalette('WeaponNumUse');

  for i := 1 to 3 do
    for j := 1 to 9 do
    begin
      AddGraphicWithOutPalette('MissionPrimary[' + itoa(i) + '][' + itoa(j) + ']', -1, 'OBJ' + itoa(i) + itoa(j) + 'PRI');
      AddGraphicWithOutPalette('MissionSecondary[' + itoa(i) + '][' + itoa(j) + ']', -1, 'OBJ' + itoa(i) + itoa(j) + 'SEC');
    end;

  AddWeaponNums('WeaponNumOn');
  AddWeaponNums('WeaponNumOff');
  AddWeaponNums('WeaponNumUse');
end;

function TRadixToWADConverter.GenerateSmallFont: boolean;
var
  lump: integer;
  buf: pointer;
  bufsize: integer;
  imginp: PByteArray;
  imgout: PByteArray;
  p: pointer;
  size: integer;
  fnt: string;
  idx: integer;
  ch: char;
  found: boolean;
begin
  lump := FindLump(lumps, numlumps, 'SmallFont');
  if lump < 0 then
  begin
    result := false;
    exit;
  end;
  if lumps[lump].length <> 2222 then
  begin
    result := false;
    exit;
  end;
  result := true;

  bufsize := lumps[lump].length;
  buf := malloc(lumps[lump].length);
  f.Seek(lumps[lump].position, sFromBeginning);
  f.Read(buf^, bufsize);

  imginp := @PByteArray(buf)[8];
  RX_ColorReplace(imginp, 368, 6, 0, 254);
  RX_ColorReplace(imginp, 368, 6, 1, 254);
  RX_ColorReplace(imginp, 368, 6, 6, 254);
  RX_ColorReplace(imginp, 368, 6, 28, 254);

  RX_CreateDoomPatch(imginp, 368, 6, false, p, size, 0, 0);

  wadwriter.AddData('SMALLFNT', p, size);
  memfree(p, size);

  imgout := malloc(5 * 6);
  memset(imgout, 254, 5 * 6);
  fnt := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.?[]!:;"`,-0123456789_';


  for ch := Chr(33) to Chr(128) do
  begin
    found := false;
    for idx := 1 to length(fnt) do
      if fnt[idx] <> ' ' then
        if fnt[idx] = ch then
        begin
          RX_BltImageBuffer(imginp, 368, 6, imgout, (idx - 1) * 5, idx * 5 - 2, 0, 5);
          RX_ColorReplace(imgout, 5, 6, 0, 254);
          RX_CreateDoomPatch(imgout, 5, 6, false, p, size, 0, 0);

          wadwriter.AddData('FNTA' + IntToStrzFill(3, Ord(ch)), p, size);
          memfree(p, size);
          fnt[idx] := ' ';
          found := true;
          break;
        end;
    if not found then
      if not (ch in ['%', '(', ')', '*', '+', '#', '/', '<', '=', '>']) then
      begin
        memset(imgout, 254, 5 * 6);
        RX_CreateDoomPatch(imgout, 5, 6, false, p, size, 0, 0);
        wadwriter.AddData('FNTA' + IntToStrzFill(3, Ord(ch)), p, size);
        memfree(p, size);
      end;
  end;

  memfree(pointer(imgout), 4 * 6);
  memfree(buf, bufsize);
end;

function TRadixToWADConverter.GenerateBigFonts: boolean;
const
  NUM_BIG_FONT_COLORS = 3;
var
  imgsize: integer;
  imginp: PByteArray;
  imgout: PByteArray;
  imgoutw: PByteArray;
  p: pointer;
  size: integer;
  i: integer;
  ch: char;
  COLORS: array[0..NUM_BIG_FONT_COLORS - 1] of LongWord;
  cidx: integer;
  pnoise: double;
  c: LongWord;
  r1, g1, b1: LongWord;
  r, g, b: integer;
  x, y: integer;
  fnt: string;
  fidx: integer;
  widx: integer;
  w: integer;

  function Interpolate(const a, b, frac: double): double;
  begin
    result := (1.0 - cos(pi * frac)) * 0.5;
    result:= a * (1 - result) + b * result;
  end;

  function Noise(const x,y: double): double;
  var
    n: integer;
  begin
    n := trunc(x + y * 57);
    n := (n shl 13) xor n;
    result := (1.0 - ( (n * (n * n * $EC4D + $131071F) + $5208DD0D) and $7FFFFFFF) / $40000000);
  end;

  function SmoothedNoise(const x, y: double): double;
  var
    corners: double;
    sides: double;
    center: double;
  begin
    corners := (Noise(x - 1, y - 1) + Noise(x + 1, y - 1) + Noise(x - 1, y + 1) + Noise(x + 1, y + 1) ) / 16;
    sides := (Noise(x - 1, y) + Noise(x + 1, y) + Noise(x, y - 1) + Noise(x, y + 1)) / 8;
    center := Noise(x, y) / 4;
    result := corners + sides + center
  end;

  function InterpolatedNoise(const x, y: double): double;
  var
    i1, i2: double;
    v1, v2, v3, v4: double;
    xInt: double;
    yInt: double;
    xFrac: double;
    yFrac: double;
  begin
    xInt := Int(x);
    xFrac := Frac(x);

    yInt := Int(y);
    yFrac := Frac(y);

    v1 := SmoothedNoise(xInt, yInt);
    v2 := SmoothedNoise(xInt + 1, yInt);
    v3 := SmoothedNoise(xInt, yInt + 1);
    v4 := SmoothedNoise(xInt + 1, yInt + 1);

    i1 := Interpolate(v1, v2, xFrac);
    i2 := Interpolate(v3, v4, xFrac);

    result := Interpolate(i1, i2, yFrac);
  end;

  function PerlinNoise(const x, y: integer): double;
  const
    PERSISTENCE = 0.50;
    LOOPCOUNT = 3;
    VARIATION = 16;
  var
    amp: double;
    ii: integer;
    freq: integer;
  begin
    freq := 1;
    result := 0.0;
    for ii := 0 to LOOPCOUNT - 1 do
    begin
      amp := Power(PERSISTENCE, ii);
      result := result + InterpolatedNoise(x * freq, y * freq) * amp;
      freq := freq shl 1;
    end;
    result := result * VARIATION;
  end;

begin
  result := true;

  imgsize := SizeOf(BIG_FONT_BUFFER);
  imginp := malloc(imgsize);

  COLORS[0] := $800000;
  COLORS[1] := $808080;
  COLORS[2] := $C47C0C;

  fnt := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890`~!@#$%^&*()-_=+*/<>.,\[]|;:''"{}';
  imgout := malloc(18 * 21);
  for cidx := 0 to NUM_BIG_FONT_COLORS - 1 do
  begin
    r1 := (COLORS[cidx] shr 16) and $FF;
    g1 := (COLORS[cidx] shr 8) and $FF;
    b1 := COLORS[cidx] and $FF;
    for i := 0 to imgsize - 1 do
    begin
      if BIG_FONT_BUFFER[i] = 0 then
        imginp[i] := 254
      else
      begin
        if BIG_FONT_BUFFER[i] = 255 then
          pnoise := PerlinNoise(i mod 1984, i div 1984)
        else
          pnoise := 0.0;
        r := round(r1 * BIG_FONT_BUFFER[i] / 256 + pnoise);
        if r > 255 then
          r := 255
        else if r < 0 then
          r := 0;
        g := round(g1 * BIG_FONT_BUFFER[i] / 256 + pnoise);
        if g > 255 then
          g := 255
        else if g < 0 then
          g := 0;
        b := round(b1 * BIG_FONT_BUFFER[i] / 256 + pnoise);
        if b > 255 then
          b := 255
        else if b < 0 then
          b := 0;
        c := r shl 16 + g shl 8 + b;
        imginp[i] := V_FindAproxColorIndex(@def_palL, c, 0, 253);
        if def_palL[imginp[i]] = 0 then
          imginp[i] := 254;
      end;
    end;

    for ch := Chr(33) to Chr(128) do
    begin
      fidx := Pos(ch, fnt);
      if fidx > 0 then
      begin
        x := 0;
        y := 4 + (fidx - 1) * 21;
        RX_BltImageBuffer(imginp, 18, 1984, imgout, x, x + 17, y, y + 20);
        // Right trim image
        widx := 18 * 21 - 1;
        while widx > 0 do
        begin
          if imgout[widx] <> 254 then
            break;
          dec(widx);
        end;
        if widx < 16 * 21 then
        begin
          w := (widx div 21) + 1;
          imgoutw := malloc(21 * w);
          memcpy(imgoutw, imgout, w * 21);
          RX_CreateDoomPatch(imgoutw, w, 21, false, p, size, 4, 1);
          memfree(pointer(imgoutw), 21 * w);
        end
        else
          RX_CreateDoomPatch(imgout, 18, 21, false, p, size, 4, 1);
      end
      else
      begin
        memset(imgout, 254, 18 * 21);
        RX_CreateDoomPatch(imgout, 5, 21, false, p, size, 4, 1);
      end;
      wadwriter.AddData('BIGF' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 18 * 21);
end;

// Generate DOS font in various colors
function TRadixToWADConverter.GenerateDosFonts: boolean;
const
  NUM_DOS_FONT_COLORS = 2;
var
  imgsize: integer;
  imginp: PByteArray;
  imgout: PByteArray;
  p: pointer;
  size: integer;
  i, j: integer;
  ch: char;
  COLORS: array[0..NUM_DOS_FONT_COLORS - 1] of LongWord;
  cidx: integer;
  c: LongWord;
  r1, g1, b1: LongWord;
  r, g, b: LongWord;
  x, y, fpos: integer;
begin
  result := true;

  COLORS[0] := 192 shl 16 + 14 shl 8 + 14 shl 8;
  COLORS[1] := $FFFFFF;

  // Big dos font
  imgsize := $10000;
  imginp := malloc(imgsize);

  imgout := malloc(14 * 14);
  for cidx := 0 to NUM_DOS_FONT_COLORS - 1 do
  begin
    r1 := (COLORS[cidx] shr 16) and $FF;
    g1 := (COLORS[cidx] shr 8) and $FF;
    b1 := COLORS[cidx] and $FF;
    for i := 0 to imgsize - 1 do
    begin
      if DOS_FONT_BUFFER[i] = 0 then
        imginp[i] := 254
      else
      begin
        r := round(r1 * DOS_FONT_BUFFER[i] / 256);
        if r > 255 then
          r := 255;
        g := round(g1 * DOS_FONT_BUFFER[i] / 256);
        if g > 255 then
          g := 255;
        b := round(b1 * DOS_FONT_BUFFER[i] / 256);
        if b > 255 then
          b := 255;
        c := r shl 16 + g shl 8 + b;
        imginp[i] := V_FindAproxColorIndex(@def_palL, c, 0, 253);
        if def_palL[imginp[i]] = 0 then
          imginp[i] := 254;
      end;
    end;

    for ch := Chr(33) to Chr(128) do
    begin
      x := Ord(ch) mod 16;
      y := Ord(ch) div 16;
      RX_BltImageBuffer(imginp, 256, 256, imgout, x * 16 + 1, x * 16 + 14, y * 16 + 2, y * 16 + 15);
      RX_CreateDoomPatch(imgout, 14, 14, false, p, size, 3, 1);
      wadwriter.AddData('DOSF' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 14 * 14);

  // Small dos font
  imgsize := 128 * 128;
  imginp := malloc(imgsize);

  imgout := malloc(8 * 8);
  for cidx := 0 to NUM_DOS_FONT_COLORS - 1 do
  begin
    r1 := (COLORS[cidx] shr 16) and $FF;
    g1 := (COLORS[cidx] shr 8) and $FF;
    b1 := COLORS[cidx] and $FF;
    for i := 0 to imgsize - 1 do
    begin
      if SMALL_DOS_FONT_BUFFER[i] = 0 then
        imginp[i] := 254
      else
      begin
        r := round(r1 * SMALL_DOS_FONT_BUFFER[i] / 256);
        if r > 255 then
          r := 255;
        g := round(g1 * SMALL_DOS_FONT_BUFFER[i] / 256);
        if g > 255 then
          g := 255;
        b := round(b1 * SMALL_DOS_FONT_BUFFER[i] / 256);
        if b > 255 then
          b := 255;
        c := r shl 16 + g shl 8 + b;
        imginp[i] := V_FindAproxColorIndex(@def_palL, c, 0, 253);
        if def_palL[imginp[i]] = 0 then
          imginp[i] := 254;
      end;
    end;

    for ch := Chr(33) to Chr(128) do
    begin
      x := (Ord(ch) - 1) mod 16;
      y := (Ord(ch) - 1) div 16;
      for j := 0 to 7 do
      begin
        fpos := x * 8 + (y * 8 + j) * 128;
        for i := 0 to 7 do
        begin
          imgout[i * 8 + j] := imginp[fpos];
          inc(fpos);
        end;
      end;
      RX_CreateDoomPatch(imgout, 8, 8, false, p, size, 0, 0);
      wadwriter.AddData('DOSS' + Chr(Ord('A') + cidx) + IntToStrzFill(3, Ord(ch)), p, size);
      memfree(p, size);
    end;
  end;

  memfree(pointer(imginp), imgsize);
  memfree(pointer(imgout), 8 * 8);
end;

function TRadixToWADConverter.GenerateMenuTranslation: boolean;
var
  trn: packed array[0..255] of byte;
  i: integer;
begin
  result := true;
  for i := 0 to 255 do
    trn[i] := i;
  for i := 0 to 15 do
    trn[208 + i] := 128 + i;
  wadwriter.AddData('TRN_MENU', @trn, 256);
end;

type
  spriteinfo_t = record
    rname: string[32];
    dname: string[8];
    translation: PByteArray;
    xoffs, yoffs: integer;
    centeroffs: boolean;
    defaultoffs: boolean;
  end;
  Pspriteinfo_t = ^spriteinfo_t;

var
  TNT1A0: array[0..87] of Byte = (
    $10, $00, $10, $00, $08, $00, $08, $00, $48, $00, $00, $00, $49, $00, $00,
    $00, $4A, $00, $00, $00, $4B, $00, $00, $00, $4C, $00, $00, $00, $4D, $00,
    $00, $00, $4E, $00, $00, $00, $4F, $00, $00, $00, $50, $00, $00, $00, $51,
    $00, $00, $00, $52, $00, $00, $00, $53, $00, $00, $00, $54, $00, $00, $00,
    $55, $00, $00, $00, $56, $00, $00, $00, $57, $00, $00, $00, $FF, $FF, $FF,
    $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
  );

  GEAR1A0: array[0..2912] of Byte = (
    $40, $00, $40, $00, $20, $00, $20, $00, $08, $01, $00, $00, $09, $01, $00,
    $00, $0A, $01, $00, $00, $0B, $01, $00, $00, $1D, $01, $00, $00, $31, $01,
    $00, $00, $45, $01, $00, $00, $5A, $01, $00, $00, $7B, $01, $00, $00, $A3,
    $01, $00, $00, $CF, $01, $00, $00, $FE, $01, $00, $00, $2C, $02, $00, $00,
    $5C, $02, $00, $00, $8E, $02, $00, $00, $C2, $02, $00, $00, $F8, $02, $00,
    $00, $2E, $03, $00, $00, $66, $03, $00, $00, $9C, $03, $00, $00, $D1, $03,
    $00, $00, $05, $04, $00, $00, $37, $04, $00, $00, $67, $04, $00, $00, $93,
    $04, $00, $00, $C5, $04, $00, $00, $F8, $04, $00, $00, $2B, $05, $00, $00,
    $5E, $05, $00, $00, $8F, $05, $00, $00, $C0, $05, $00, $00, $F1, $05, $00,
    $00, $22, $06, $00, $00, $53, $06, $00, $00, $84, $06, $00, $00, $B5, $06,
    $00, $00, $E6, $06, $00, $00, $18, $07, $00, $00, $4B, $07, $00, $00, $7E,
    $07, $00, $00, $B3, $07, $00, $00, $E2, $07, $00, $00, $0F, $08, $00, $00,
    $40, $08, $00, $00, $72, $08, $00, $00, $A6, $08, $00, $00, $DC, $08, $00,
    $00, $13, $09, $00, $00, $4B, $09, $00, $00, $81, $09, $00, $00, $B6, $09,
    $00, $00, $EA, $09, $00, $00, $1C, $0A, $00, $00, $4C, $0A, $00, $00, $7A,
    $0A, $00, $00, $AA, $0A, $00, $00, $D6, $0A, $00, $00, $FB, $0A, $00, $00,
    $15, $0B, $00, $00, $29, $0B, $00, $00, $3D, $0B, $00, $00, $51, $0B, $00,
    $00, $5F, $0B, $00, $00, $60, $0B, $00, $00, $FF, $FF, $FF, $19, $0D, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $FF,
    $18, $0F, $97, $97, $97, $97, $96, $96, $96, $96, $96, $96, $97, $97, $97,
    $97, $97, $97, $97, $FF, $18, $0F, $97, $97, $96, $96, $96, $96, $96, $96,
    $96, $96, $97, $97, $97, $97, $97, $97, $97, $FF, $18, $10, $97, $97, $96,
    $96, $96, $96, $96, $96, $96, $96, $97, $97, $97, $97, $97, $97, $97, $97,
    $FF, $10, $02, $96, $96, $97, $97, $17, $11, $97, $97, $97, $96, $96, $96,
    $92, $92, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $2E, $01,
    $99, $99, $99, $FF, $0E, $05, $96, $96, $96, $96, $97, $97, $97, $17, $11,
    $97, $97, $97, $96, $96, $96, $92, $92, $92, $92, $92, $92, $92, $95, $97,
    $97, $97, $97, $97, $2C, $05, $97, $97, $97, $97, $99, $99, $99, $FF, $0D,
    $07, $96, $96, $96, $95, $95, $95, $97, $97, $97, $17, $11, $97, $97, $97,
    $96, $96, $95, $92, $92, $92, $92, $92, $92, $92, $93, $97, $97, $97, $97,
    $97, $2B, $07, $97, $97, $97, $97, $97, $97, $99, $9B, $9B, $FF, $0C, $1D,
    $96, $96, $96, $95, $95, $95, $95, $95, $96, $97, $97, $97, $97, $96, $96,
    $96, $93, $92, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97,
    $97, $2A, $09, $97, $97, $97, $97, $97, $97, $97, $97, $99, $9B, $9B, $FF,
    $0B, $29, $96, $96, $96, $95, $95, $95, $95, $95, $95, $95, $95, $97, $97,
    $96, $96, $96, $96, $92, $92, $92, $92, $92, $92, $92, $92, $92, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $9B, $9B,
    $FF, $0A, $2B, $96, $96, $96, $95, $95, $95, $95, $92, $95, $95, $95, $95,
    $95, $96, $96, $96, $96, $96, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $93, $97, $97, $97, $97,
    $97, $9B, $9B, $FF, $09, $2D, $96, $96, $96, $95, $95, $95, $95, $92, $92,
    $92, $94, $95, $95, $95, $96, $96, $96, $96, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $97, $93, $93,
    $93, $97, $97, $97, $97, $9B, $9B, $9B, $FF, $08, $2F, $96, $96, $96, $94,
    $95, $95, $95, $92, $92, $92, $92, $92, $92, $95, $95, $96, $96, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $97, $97,
    $97, $97, $94, $93, $93, $93, $93, $93, $97, $97, $97, $97, $9B, $9B, $9B,
    $FF, $07, $31, $96, $96, $96, $94, $94, $95, $95, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $93, $93, $93, $93, $93, $93, $93, $93,
    $93, $93, $97, $97, $97, $97, $9B, $9B, $9B, $FF, $07, $31, $96, $96, $94,
    $94, $94, $95, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $92, $93, $93, $93, $93, $93, $93, $93, $93, $93, $93, $93, $97, $97, $97,
    $97, $9B, $9B, $FF, $06, $33, $96, $96, $96, $94, $94, $94, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $97,
    $97, $97, $97, $97, $97, $97, $93, $92, $92, $92, $92, $93, $93, $93, $93,
    $93, $93, $93, $93, $93, $93, $93, $93, $97, $97, $97, $9B, $9B, $9B, $FF,
    $07, $31, $96, $96, $95, $94, $94, $95, $92, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $92, $92, $93, $93, $93, $93, $93, $93, $93, $93, $93,
    $93, $93, $97, $97, $97, $99, $9B, $9B, $FF, $08, $30, $96, $96, $94, $94,
    $95, $95, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $93,
    $93, $93, $93, $93, $93, $93, $93, $93, $93, $97, $97, $97, $97, $9B, $9B,
    $9B, $FF, $08, $2F, $96, $96, $96, $94, $95, $95, $95, $92, $92, $92, $92,
    $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $93, $93, $93, $93, $93, $93, $93,
    $93, $96, $97, $97, $97, $9B, $9B, $9B, $FF, $09, $2D, $96, $96, $96, $95,
    $95, $95, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $93, $93, $93, $93, $93, $93, $93, $97, $97, $97, $9B, $9B, $9B, $FF, $0A,
    $2B, $96, $96, $95, $95, $95, $94, $92, $92, $92, $92, $92, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $97, $93, $93, $93, $93, $93, $94, $97, $97, $97, $9B,
    $9B, $FF, $0A, $11, $96, $96, $95, $95, $95, $92, $92, $92, $92, $92, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $24, $12, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $93, $93, $93, $93, $93, $97, $97, $97, $9B, $9B, $9B,
    $FF, $05, $15, $96, $96, $96, $96, $96, $96, $95, $95, $95, $95, $92, $92,
    $92, $92, $96, $97, $97, $97, $97, $97, $97, $97, $97, $26, $14, $97, $97,
    $97, $97, $97, $97, $97, $97, $93, $93, $93, $93, $97, $97, $97, $97, $9B,
    $9B, $9B, $9B, $9B, $9B, $FF, $03, $15, $96, $96, $96, $96, $96, $95, $94,
    $94, $94, $95, $95, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97,
    $97, $27, $15, $97, $97, $97, $97, $97, $97, $97, $93, $93, $93, $93, $93,
    $97, $97, $97, $97, $97, $9B, $9B, $9B, $9B, $9B, $9B, $FF, $03, $15, $96,
    $96, $94, $94, $94, $94, $94, $94, $94, $95, $95, $92, $92, $92, $92, $96,
    $97, $97, $97, $97, $97, $97, $97, $28, $15, $97, $97, $97, $97, $97, $97,
    $97, $93, $93, $93, $93, $97, $97, $97, $97, $97, $99, $99, $9B, $9B, $9B,
    $9B, $9B, $FF, $02, $15, $96, $96, $96, $94, $94, $94, $94, $94, $94, $94,
    $95, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $28, $15,
    $97, $97, $97, $97, $97, $97, $97, $93, $93, $93, $93, $93, $97, $97, $97,
    $97, $99, $99, $9B, $9B, $9B, $9B, $9B, $FF, $02, $14, $96, $96, $96, $94,
    $94, $94, $93, $92, $92, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97,
    $97, $97, $97, $29, $14, $97, $97, $97, $97, $97, $97, $93, $93, $93, $93,
    $93, $93, $93, $93, $93, $96, $99, $9B, $9B, $9B, $9B, $9B, $FF, $02, $14,
    $96, $96, $95, $94, $94, $93, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $94, $97, $97, $97, $97, $97, $97, $29, $14, $97, $97, $97, $97, $97, $97,
    $97, $93, $93, $93, $93, $93, $93, $93, $93, $93, $94, $9B, $9B, $9B, $9B,
    $9B, $FF, $02, $14, $96, $96, $95, $94, $94, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $29, $14, $97, $97,
    $97, $97, $97, $97, $97, $93, $93, $93, $93, $93, $93, $93, $93, $93, $93,
    $9B, $9B, $9B, $9B, $9B, $FF, $02, $14, $96, $96, $95, $94, $94, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97,
    $29, $14, $97, $97, $97, $97, $97, $97, $97, $93, $93, $93, $93, $93, $93,
    $93, $93, $93, $93, $9B, $9B, $9B, $9B, $9B, $FF, $02, $14, $96, $96, $94,
    $94, $94, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97,
    $97, $97, $97, $97, $29, $14, $97, $97, $97, $97, $97, $97, $97, $93, $93,
    $93, $93, $93, $93, $93, $93, $93, $93, $9B, $9B, $9B, $9B, $9B, $FF, $02,
    $14, $96, $96, $95, $94, $94, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $92, $97, $97, $97, $97, $97, $97, $97, $29, $14, $97, $97, $97, $97, $97,
    $97, $97, $93, $93, $93, $93, $93, $93, $93, $93, $93, $93, $9B, $9B, $9B,
    $9B, $9B, $FF, $02, $14, $96, $96, $95, $94, $94, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $29, $14, $97,
    $97, $97, $97, $97, $97, $97, $93, $93, $93, $93, $93, $93, $93, $93, $93,
    $93, $9B, $9B, $9B, $9B, $9B, $FF, $02, $14, $96, $96, $95, $94, $94, $93,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $93, $97, $97, $97, $97, $97,
    $97, $29, $14, $97, $97, $97, $97, $97, $97, $96, $93, $93, $93, $93, $93,
    $93, $93, $93, $93, $94, $9B, $9B, $9B, $9B, $9B, $FF, $02, $15, $96, $96,
    $96, $94, $94, $94, $94, $94, $93, $92, $92, $92, $92, $92, $92, $92, $97,
    $97, $97, $97, $97, $97, $97, $29, $14, $97, $97, $97, $97, $97, $97, $93,
    $93, $93, $93, $93, $93, $93, $96, $97, $99, $99, $9B, $9B, $9B, $9B, $9B,
    $FF, $02, $15, $96, $96, $96, $94, $94, $94, $94, $94, $94, $94, $95, $94,
    $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $28, $15, $97, $97,
    $97, $97, $97, $97, $97, $93, $93, $93, $93, $95, $97, $97, $97, $97, $99,
    $99, $9B, $9B, $9B, $9B, $9B, $FF, $03, $15, $96, $96, $94, $94, $94, $94,
    $94, $94, $94, $95, $95, $92, $92, $92, $92, $94, $97, $97, $97, $97, $97,
    $97, $97, $27, $15, $97, $97, $97, $97, $97, $97, $97, $97, $93, $93, $93,
    $93, $97, $97, $97, $97, $97, $99, $99, $9B, $9B, $9B, $9B, $FF, $03, $16,
    $96, $96, $96, $96, $96, $96, $96, $96, $94, $95, $95, $93, $92, $92, $92,
    $92, $97, $97, $97, $97, $97, $97, $97, $97, $26, $16, $97, $97, $97, $97,
    $97, $97, $97, $97, $93, $93, $93, $93, $93, $97, $97, $97, $9B, $9B, $9B,
    $9B, $9B, $9B, $9B, $9B, $FF, $07, $13, $96, $96, $96, $96, $96, $95, $95,
    $95, $92, $92, $92, $92, $93, $97, $97, $97, $97, $97, $97, $97, $97, $25,
    $13, $97, $97, $97, $97, $97, $97, $97, $97, $95, $93, $93, $93, $93, $97,
    $97, $97, $9B, $9B, $9B, $9B, $9B, $FF, $0A, $12, $96, $96, $95, $95, $95,
    $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $23, $12, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $93, $93, $93,
    $93, $93, $97, $97, $97, $9B, $9B, $FF, $0A, $2C, $96, $96, $95, $95, $95,
    $94, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $93,
    $93, $93, $93, $93, $94, $97, $97, $97, $9B, $9B, $9B, $FF, $09, $2D, $96,
    $96, $95, $95, $95, $95, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $97, $97, $97, $93, $93, $93, $93, $93, $93, $93, $97, $97, $97, $97, $9B,
    $9B, $FF, $08, $2F, $96, $96, $96, $94, $95, $95, $93, $92, $92, $92, $92,
    $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $93, $93, $93, $93, $93, $93, $93,
    $93, $93, $97, $97, $97, $9B, $9B, $9B, $FF, $07, $31, $96, $96, $96, $94,
    $94, $95, $95, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $94,
    $93, $93, $93, $93, $93, $93, $93, $93, $93, $93, $97, $97, $97, $97, $9B,
    $9B, $9B, $FF, $07, $32, $96, $96, $94, $94, $94, $95, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $93, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $94, $92, $92, $93, $93, $93, $93, $93, $93,
    $93, $93, $93, $93, $93, $97, $97, $97, $97, $9B, $9B, $9B, $FF, $06, $33,
    $96, $96, $96, $94, $94, $94, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $96, $97, $97, $97, $96, $93,
    $92, $92, $92, $92, $92, $93, $93, $93, $93, $93, $93, $93, $93, $93, $93,
    $93, $93, $97, $97, $97, $9B, $9B, $9B, $FF, $07, $31, $96, $96, $95, $94,
    $94, $95, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $93, $93, $93, $93, $93, $93, $93, $93, $93, $93, $93, $97, $97, $97, $99,
    $9B, $9B, $FF, $08, $30, $96, $96, $94, $94, $95, $95, $92, $92, $92, $92,
    $92, $92, $92, $92, $95, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $92, $93, $97, $93, $93, $93, $93, $93,
    $93, $93, $93, $97, $97, $97, $97, $9B, $9B, $9B, $FF, $08, $2F, $96, $96,
    $96, $94, $95, $95, $95, $92, $92, $92, $92, $92, $94, $95, $95, $96, $96,
    $94, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $92, $94,
    $97, $97, $97, $97, $97, $93, $93, $93, $93, $93, $97, $97, $97, $97, $9B,
    $9B, $9B, $FF, $09, $2D, $96, $96, $96, $95, $95, $95, $95, $92, $92, $92,
    $95, $95, $95, $95, $96, $96, $96, $96, $95, $92, $92, $92, $92, $92, $92,
    $92, $92, $92, $94, $97, $97, $97, $97, $97, $97, $97, $97, $93, $93, $93,
    $97, $97, $97, $97, $9B, $9B, $9B, $FF, $0A, $2B, $96, $96, $96, $95, $95,
    $95, $95, $92, $95, $95, $95, $95, $95, $96, $96, $96, $96, $96, $92, $92,
    $92, $92, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97, $97, $97,
    $97, $97, $93, $97, $97, $97, $97, $9B, $9B, $9B, $FF, $0B, $29, $96, $96,
    $96, $95, $95, $95, $95, $95, $95, $95, $97, $97, $97, $97, $96, $96, $96,
    $92, $92, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97, $97, $97, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $9B, $9B, $9B, $FF, $0C, $09, $96,
    $96, $96, $95, $95, $95, $95, $95, $97, $97, $97, $17, $11, $97, $97, $96,
    $96, $96, $93, $92, $92, $92, $92, $92, $92, $92, $92, $97, $97, $97, $97,
    $97, $2A, $09, $97, $97, $97, $97, $97, $97, $97, $97, $9B, $9B, $9B, $FF,
    $0D, $07, $96, $96, $96, $96, $95, $95, $97, $97, $97, $17, $11, $97, $97,
    $97, $96, $96, $95, $92, $92, $92, $92, $92, $92, $92, $93, $97, $97, $97,
    $97, $97, $2B, $07, $97, $97, $97, $97, $97, $97, $99, $9B, $9B, $FF, $0F,
    $03, $96, $96, $96, $97, $97, $17, $11, $97, $97, $97, $96, $96, $96, $92,
    $92, $92, $92, $92, $92, $92, $96, $97, $97, $97, $97, $97, $2D, $04, $97,
    $97, $99, $99, $99, $99, $FF, $18, $10, $97, $97, $96, $96, $96, $96, $94,
    $93, $93, $93, $94, $96, $97, $97, $97, $97, $97, $97, $2E, $01, $99, $99,
    $99, $FF, $18, $0F, $97, $97, $96, $96, $96, $96, $96, $96, $96, $96, $97,
    $97, $97, $97, $97, $97, $97, $FF, $18, $0F, $97, $97, $96, $96, $96, $96,
    $96, $96, $96, $96, $97, $97, $97, $97, $97, $97, $97, $FF, $18, $0F, $97,
    $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $97, $FF, $1B, $09, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97, $97,
    $FF, $FF, $FF
  );

function TRadixToWADConverter.GenerateSprites: boolean;
const
  MAX_SPR_INFO = 1024;
  NUMEXTRASPRITENAMES = 6;
const
  SPREXTRANAMES: array[0..NUMEXTRASPRITENAMES - 1] of string[4] = (
    'EXPB', 'EXPS', 'SMOB', 'SMOS', 'PUFF', 'PLAY'
  );
var
  position: integer;
  bstart: integer;
  bnumlumps: word;
  blumps: Pradixbitmaplump_tArray;
  bl: Pradixbitmaplump_t;
  i, j: integer;
  splash_bmps: array[1..6] of TDNumberList;
  buf: PByteArray;
  stmp: string;
  SPRITEINFO: array[0..MAX_SPR_INFO - 1] of spriteinfo_t;
  spr: Pspriteinfo_t;
  numsprinfo: integer;
  bmp: TRadixBitmap;
  rcol: radixcolumn_t;
  pc: Pradixcolumn_tArray;
  x, y, z: integer;
  p: pointer;
  size: integer;
  ch: char;
  radixlumpnames: TDStringList;

  function remove_underline(const s: string): string;
  var
    ii: integer;
  begin
    result := '';
    for ii := 1 to length(s) do
      if s[ii] <> '_' then
        result := result + s[ii];
  end;

  procedure check_sprite_overflow;
  begin
    if numsprinfo >= MAX_SPR_INFO then
      I_Error('TRadixToWADConverter.GenerateSprites(): Sprite table overflow, numsprinfo=%d', [numsprinfo]);
  end;

  function get_sprite_name(const ids: integer): string;
  begin
    if ids <= _MTRX_RADIXMAXEDITORTHING then
      result := 'XR' + IntToStrzFill(2, ids)
    else if ids < _DOOM_THING_2_RADIX_ then
      result := 'X' + IntToStrzFill(3, ids)
    else if ids < _DOOM_THING_2_RADIX_ + NUMEXTRASPRITENAMES then
      result := SPREXTRANAMES[ids - _DOOM_THING_2_RADIX_]
    else
      result := IntToStrzFill(4, ids)
  end;

  procedure MakeNonRotatingSprite(const rprefix: string; const r_id: integer;
    const numframes: integer; const trans: PByteArray = nil;
    const xofs: integer = -255; const yofs: integer = -255;
    const cofs: boolean = true; const defofs: boolean = true;
    const startframe: char = 'A');
  var
    ii: integer;
  begin
    for ii := 1 to numframes do
    begin
      check_sprite_overflow;

      spr.rname := rprefix + '_' + itoa(ii);
      spr.dname := get_sprite_name(r_id) + Chr(Ord(startframe) + ii - 1) + '0';
      spr.translation := trans;
      spr.xoffs := xofs;
      spr.yoffs := yofs;
      spr.centeroffs := cofs;
      spr.defaultoffs := defofs;
      inc(spr);
      inc(numsprinfo);
    end;
  end;

  procedure MakeRotatingSprite8(const rprefix: string; const r_id: integer;
    const numframes: integer; const trans: PByteArray = nil;
    const xofs: integer = -255; const yofs: integer = -255;
    const cofs: boolean = true; const defofs: boolean = true;
    const startframe: char = 'A');
  var
    ii: integer;
    jj: integer;
  begin
    for ii := 1 to numframes do
      for jj := 1 to 8 do
      begin
        check_sprite_overflow;

        spr.rname := rprefix + '_' + itoa(jj + (ii - 1) * 8);
        spr.dname := get_sprite_name(r_id) + Chr(Ord(startframe) + ii - 1) + itoa(jj);
        spr.translation := trans;
        spr.xoffs := xofs;
        spr.yoffs := yofs;
        spr.centeroffs := cofs;
        spr.defaultoffs := defofs;
        inc(spr);
        inc(numsprinfo);
      end;
  end;

  procedure MakeRotatingSprite16(const rprefix: string; const r_id: integer;
    const numframes: integer; const trans: PByteArray = nil;
    const xofs: integer = -255; const yofs: integer = -255;
    const cofs: boolean = true; const defofs: boolean = true;
    const mask: integer = -1; const startframe: char = 'A');
  const
    SPR16 = '192A3B4C5D6E7F8G';
  var
    ii: integer;
    jj: integer;
  begin
    for ii := 1 to numframes do
      for jj := 1 to 16 do
        if (mask = -1) or (jj = mask) then
        begin
          check_sprite_overflow;

          spr.rname := rprefix + '_' + itoa(jj + (ii - 1) * 16);
          spr.dname := get_sprite_name(r_id) + Chr(Ord(startframe) + ii - 1) + SPR16[jj];
          spr.translation := trans;
          spr.xoffs := xofs;
          spr.yoffs := yofs;
          spr.centeroffs := cofs;
          spr.defaultoffs := defofs;
          inc(spr);
          inc(numsprinfo);
        end;
  end;

  procedure MakeOneSprite(const rname: string; const r_id: integer;
    const trans: PByteArray = nil;
    const xofs: integer = -255; const yofs: integer = -255;
    const cofs: boolean = true; const defofs: boolean = true;
    const frm: char = 'A'; const spriteangle: char = '0'; const extraframe: string = '');
  begin
    check_sprite_overflow;

    spr.rname := rname;
    spr.dname := get_sprite_name(r_id) + frm + spriteangle + extraframe;
    spr.translation := trans;
    spr.xoffs := xofs;
    spr.yoffs := yofs;
    spr.centeroffs := cofs;
    spr.defaultoffs := defofs;
    inc(spr);
    inc(numsprinfo);
  end;

begin
  i := FindLump(lumps, numlumps, 'ObjectBitmaps');
  if i < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;

  position := lumps[i].position;
  f.Seek(position, sFromBeginning);
  f.Read(bnumlumps, SizeOf(word));

  blumps := mallocz(bnumlumps * SizeOf(radixbitmaplump_t));

  f.Read(bstart, SizeOf(integer));
  f.Seek(bstart, sFromBeginning);
  f.Read(blumps^, bnumlumps * SizeOf(radixbitmaplump_t));

  // JVAL: 20201211 - Speed up a bit :)
  radixlumpnames := TDStringList.Create;
  for i := 0 to bnumlumps - 1 do
    radixlumpnames.Add(radixlumpname(blumps[i]));

  // JVAL: 20200426 - Patch doublicated names of ObjectBitmaps

  if bnumlumps > 2 then
  begin
    if (radixlumpnames.Strings[0] = 'SecondCoolant1') and
       (radixlumpnames.Strings[1] = 'SecondCoolant1') and
       (radixlumpnames.Strings[2] = 'SecondCoolant1') then
    begin
      blumps[1].name[13] := '2';
      radixlumpnames.Strings[1] := radixlumpname(blumps[1]);
      blumps[2].name[13] := '3';
      radixlumpnames.Strings[2] := radixlumpname(blumps[2]);
    end;
  end;

  if bnumlumps > 8 then
  begin
    if (radixlumpnames.Strings[6] = 'CoolantGener1') and
       (radixlumpnames.Strings[7] = 'CoolantGener1') and
       (radixlumpnames.Strings[8] = 'CoolantGener1') then
    begin
      blumps[7].name[12] := '2';
      radixlumpnames.Strings[7] := radixlumpname(blumps[7]);
      blumps[8].name[12] := '3';
      radixlumpnames.Strings[8] := radixlumpname(blumps[8]);
    end;
  end;

  // JVAL: 20200501 - Check splashes
  for i := 1 to 6 do
    splash_bmps[i] := TDNumberList.Create;

  // Check watersplash
  for j := 0 to bnumlumps - 1 do
    for i := 1 to 6 do
      if radixlumpnames.Strings[j] = 'WaterSplash' + itoa(i) then
        splash_bmps[i].Add(j);

  if splash_bmps[1].Count = 2 then
  begin
    blumps[splash_bmps[1].Numbers[0]].name[11] := '7';
    radixlumpnames.Strings[splash_bmps[1].Numbers[0]] := radixlumpname(blumps[splash_bmps[1].Numbers[0]]);
  end;
  if splash_bmps[2].Count = 2 then
  begin
    blumps[splash_bmps[2].Numbers[0]].name[11] := '8';
    radixlumpnames.Strings[splash_bmps[2].Numbers[0]] := radixlumpname(blumps[splash_bmps[2].Numbers[0]]);
  end;
  if splash_bmps[3].Count = 2 then
  begin
    blumps[splash_bmps[3].Numbers[0]].name[11] := '9';
    radixlumpnames.Strings[splash_bmps[3].Numbers[0]] := radixlumpname(blumps[splash_bmps[3].Numbers[0]]);
  end;

  for i := 1 to 6 do
    splash_bmps[i].FastClear;

  // Check mudsplash
  for j := 0 to bnumlumps - 1 do
    for i := 1 to 6 do
      if radixlumpnames.Strings[j] = 'MudSplash' + itoa(i) then
        splash_bmps[i].Add(j);

  if splash_bmps[1].Count = 2 then
  begin
    blumps[splash_bmps[1].Numbers[0]].name[9] := '7';
    radixlumpnames.Strings[splash_bmps[1].Numbers[0]] := radixlumpname(blumps[splash_bmps[1].Numbers[0]]);
  end;
  if splash_bmps[2].Count = 2 then
  begin
    blumps[splash_bmps[2].Numbers[0]].name[9] := '8';
    radixlumpnames.Strings[splash_bmps[2].Numbers[0]] := radixlumpname(blumps[splash_bmps[2].Numbers[0]]);
  end;
  if splash_bmps[3].Count = 2 then
  begin
    blumps[splash_bmps[3].Numbers[0]].name[9] := '9';
    radixlumpnames.Strings[splash_bmps[3].Numbers[0]] := radixlumpname(blumps[splash_bmps[3].Numbers[0]]);
  end;

  for i := 1 to 6 do
    splash_bmps[i].FastClear;

  // Check LavaSplash
  for j := 0 to bnumlumps - 1 do
    for i := 1 to 6 do
      if radixlumpnames.Strings[j] = 'LavaSplash' + itoa(i) then
        splash_bmps[i].Add(j);

  if splash_bmps[1].Count = 2 then
  begin
    blumps[splash_bmps[1].Numbers[0]].name[10] := '7';
    radixlumpnames.Strings[splash_bmps[1].Numbers[0]] := radixlumpname(blumps[splash_bmps[1].Numbers[0]]);
  end;
  if splash_bmps[2].Count = 2 then
  begin
    blumps[splash_bmps[2].Numbers[0]].name[10] := '8';
    radixlumpnames.Strings[splash_bmps[2].Numbers[0]] := radixlumpname(blumps[splash_bmps[2].Numbers[0]]);
  end;
  if splash_bmps[3].Count = 2 then
  begin
    blumps[splash_bmps[3].Numbers[0]].name[10] := '9';
    radixlumpnames.Strings[splash_bmps[3].Numbers[0]] := radixlumpname(blumps[splash_bmps[3].Numbers[0]]);
  end;

  for i := 1 to 6 do
    splash_bmps[i].Free;
  // JVAL: 20200501 - End of splashes check

  wadwriter.AddSeparator('S_START');

  wadwriter.AddData('GEAR1A0', @GEAR1A0, SizeOf(GEAR1A0));

  numsprinfo := 0;

  spr := @SPRITEINFO[0];

  // MT_FULLARMOR
  MakeNonRotatingSprite('FullArmour', _MTRX_FULLARMOR, 3);

  // MT_FULLSHIED
  MakeNonRotatingSprite('FullShield', _MTRX_FULLSHIED, 3);

  // MT_FULLENERGY
  MakeNonRotatingSprite('FullEnergy', _MTRX_FULLENERGY, 3);

  // MT_SUPERCHARGE
  MakeNonRotatingSprite('SuperCharge', _MTRX_SUPERCHARGE, 3);

  // MT_RAPIDSHIELD
  MakeNonRotatingSprite('RapidShld.Recharger', _MTRX_RAPIDSHIELD, 3);

  // MT_RAPIDENERGY
  MakeNonRotatingSprite('RapidEngy.Energizer', _MTRX_RAPIDENERGY, 3);

  // MT_MANEUVERJETS
  MakeNonRotatingSprite('ManeuveringJets', _MTRX_MANEUVERJETS, 3);

  // MT_NIGHTVISION
  MakeNonRotatingSprite('NightVisionSys', _MTRX_NIGHTVISION, 3);

  // MT_PLASMABOMB
  MakeNonRotatingSprite('PlasmaBomb', _MTRX_PLASMABOMB, 3);

  // MT_ALDS
  MakeNonRotatingSprite('A.L.D.S', _MTRX_ALDS, 3);

  // MT_ULTRASHIELDS
  MakeNonRotatingSprite('GodMode', _MTRX_ULTRASHIELDS, 3);

  // MT_LEVEL2NEUTRONCANNONS
  MakeNonRotatingSprite('LaserCannons', _MTRX_LEVEL2NEUTRONCANNONS, 3);

  // MT_STANDARDEPC
  MakeNonRotatingSprite('ExplosiveCannon', _MTRX_STANDARDEPC, 3);

  // MT_LEVEL1PLASMASPREADER
  MakeNonRotatingSprite('PlasmaCannon', _MTRX_LEVEL1PLASMASPREADER, 3);

  // MT_NUCLEARCAPABILITY
  MakeNonRotatingSprite('NuclearWeaponSystem', _MTRX_NUCLEARCAPABILITY, 3);

  // MT_MISSILECAPABILITY
  MakeNonRotatingSprite('SeekingMissileSystem', _MTRX_MISSILECAPABILITY, 3);

  // MT_TORPEDOCAPABILITY
  MakeNonRotatingSprite('PhaseTorpedoSystem', _MTRX_TORPEDOCAPABILITY, 3);

  // MT_GRAVITYDEVICE
  MakeNonRotatingSprite('GravityWaveDevice', _MTRX_GRAVITYDEVICE, 3);

  // MT_250SHELLS
  MakeNonRotatingSprite('250ShellPack', _MTRX_250SHELLS, 3);

  // MT_500SHELLS
  MakeNonRotatingSprite('500ShellPack', _MTRX_500SHELLS, 3);

  // MT_1000SHELLS
  MakeNonRotatingSprite('1000ShellPack', _MTRX_1000SHELLS, 3);

  // MT_4NUKES
  MakeNonRotatingSprite('5Nukes', _MTRX_4NUKES, 3);

  // MT_10NUKES
  MakeNonRotatingSprite('25Nukes', _MTRX_10NUKES, 3);

  // MT_15TORPEDOES
  MakeNonRotatingSprite('10Torps', _MTRX_15TORPEDOES, 3);

  // MT_75TORPEDOES
  MakeNonRotatingSprite('50Torps', _MTRX_75TORPEDOES, 3);

  // MT_20MISSILES
  MakeNonRotatingSprite('20Missiles', _MTRX_20MISSILES, 3);

  // MT_50MISSILES
  MakeNonRotatingSprite('50Missiles', _MTRX_50MISSILES, 3);

  // MT_BOOMPACK
  MakeNonRotatingSprite('BoomPack', _MTRX_BOOMPACK, 3);

  // MT_BIOMINE1
  MakeNonRotatingSprite('WeakBiomine', _MTRX_BIOMINE1, 3);
  MakeOneSprite('WeakBio-MineFall', _MTRX_BIOMINE1, nil, 31, 37, false, false, 'D');
  MakeOneSprite('WeakBio-MineDead1', _MTRX_BIOMINE1, nil, 8, 9, false, false, 'E');
  MakeOneSprite('WeakBio-MineDead2', _MTRX_BIOMINE1, nil, 18, 20, false, false, 'F');
  MakeOneSprite('WeakBio-MineDead3', _MTRX_BIOMINE1, nil, 14, 22, false, false, 'G');
  MakeOneSprite('WeakBioChunk1', _MTRX_BIOMINE1, nil, 29, 46, false, false, 'H');
  MakeOneSprite('WeakBioChunk2', _MTRX_BIOMINE1, nil, 41, 46, false, false, 'I');
  MakeOneSprite('WeakBioChunk3', _MTRX_BIOMINE1, nil, 50, 38, false, false, 'J');
  MakeOneSprite('WeakBioChunk4', _MTRX_BIOMINE1, nil, 49, 25, false, false, 'K');
  MakeOneSprite('WeakBioChunk5', _MTRX_BIOMINE1, nil, 39, 18, false, false, 'L');
  MakeOneSprite('WeakBioChunk6', _MTRX_BIOMINE1, nil, 25, 17, false, false, 'M');
  MakeOneSprite('WeakBioChunk7', _MTRX_BIOMINE1, nil, 18, 26, false, false, 'N');
  MakeOneSprite('WeakBioChunk8', _MTRX_BIOMINE1, nil, 20, 34, false, false, 'O');

  // MT_BIOMINE2
  MakeNonRotatingSprite('PowerBiomine', _MTRX_BIOMINE2, 3);
  MakeOneSprite('BlackBioBottom', _MTRX_BIOMINE2, nil, 32, 32, false, false, 'D');
  MakeOneSprite('BlackBioChunk', _MTRX_BIOMINE2, nil, 7, 14, false, false, 'E');
  MakeOneSprite('BlackBioTop', _MTRX_BIOMINE2, nil, 31, 22, false, false, 'F');


  // MT_ALIENFODDER
  MakeRotatingSprite8('AlienFodder', _MTRX_ALIENFODDER, 3, nil, 68, 101, false, false);
  MakeOneSprite('FodderFire1', _MTRX_ALIENFODDER, nil, 68, 101, false, false, 'D', '1');
  MakeOneSprite('FodderFire2', _MTRX_ALIENFODDER, nil, 68, 101, false, false, 'D', '2');
  MakeOneSprite('FodderFire3', _MTRX_ALIENFODDER, nil, 75, 101, false, false, 'D', '3');
  MakeOneSprite('FodderFire4', _MTRX_ALIENFODDER, nil, 75, 101, false, false, 'D', '4');
  MakeOneSprite('FodderFire5', _MTRX_ALIENFODDER, nil, 75, 101, false, false, 'D', '5');
  MakeOneSprite('FodderFire6', _MTRX_ALIENFODDER, nil, 75, 101, false, false, 'D', '6');
  MakeOneSprite('FodderFire7', _MTRX_ALIENFODDER, nil, 75, 101, false, false, 'D', '7');
  MakeOneSprite('FodderFire8', _MTRX_ALIENFODDER, nil, 75, 101, false, false, 'D', '8');
  MakeOneSprite('FodderBust1', _MTRX_ALIENFODDER, nil, 71, 102, false, false, 'E');
  MakeOneSprite('FodderBust2', _MTRX_ALIENFODDER, nil, 71, 102, false, false, 'F');
  MakeOneSprite('FodderBust3', _MTRX_ALIENFODDER, nil, 71, 108, false, false, 'G');
  MakeOneSprite('FodderBust4', _MTRX_ALIENFODDER, nil, 86, 123, false, false, 'H');
  MakeOneSprite('FodderBust5', _MTRX_ALIENFODDER, nil, 71, 108, false, false, 'I');
  MakeOneSprite('FodderDEAD', _MTRX_ALIENFODDER, nil, 71, 108, false, false, 'J');
  MakeOneSprite('FodderHead1', _MTRX_ALIENFODDER, nil, 51, 58, false, false, 'K');
  MakeOneSprite('FodderHead2', _MTRX_ALIENFODDER, nil, 46, 68, false, false, 'L');
  MakeOneSprite('FodderHead3', _MTRX_ALIENFODDER, nil, 53, 93, false, false, 'M');
  MakeOneSprite('FodderHead4', _MTRX_ALIENFODDER, nil, 68, 85, false, false, 'N');
  MakeOneSprite('FodderHead5', _MTRX_ALIENFODDER, nil, 79, 85, false, false, 'O');
  MakeOneSprite('FodderHead6', _MTRX_ALIENFODDER, nil, 62, 74, false, false, 'P');
  MakeOneSprite('FodderHead7', _MTRX_ALIENFODDER, nil, 68, 84, false, false, 'Q');
  MakeOneSprite('FodderHead8', _MTRX_ALIENFODDER, nil, 66, 71, false, false, 'R');
  MakeOneSprite('FodderShot', _MTRX_ALIENFODDER, nil, 8, 8, false, false, 'S');

  // MT_DEFENCEDRONE_STUB1
  MakeRotatingSprite8('DroneB', _MTRX_DEFENCEDRONE_STUB1, 1, nil, 63, 67, false, false);

  // MT_DEFENCEDRONE_STUB2
  MakeRotatingSprite8('DroneB', _MTRX_DEFENCEDRONE_STUB2, 1, nil, 63, 67, false, false);

  // MT_BATTLEDRONE1
  MakeRotatingSprite8('DroneA', _MTRX_BATTLEDRONE1, 1, nil, 91, 50, false, false);
  MakeOneSprite('DroneA1Chunk1', _MTRX_BATTLEDRONE1, nil, 27, 35, false, false, 'B');
  MakeOneSprite('DroneA1Chunk2', _MTRX_BATTLEDRONE1, nil, 31, 34, false, false, 'C');
  MakeOneSprite('DroneA1Chunk3', _MTRX_BATTLEDRONE1, nil, 35, 25, false, false, 'D');
  MakeOneSprite('DroneA1Chunk4', _MTRX_BATTLEDRONE1, nil, 30, 19, false, false, 'E');
  MakeOneSprite('DroneA1Chunk5', _MTRX_BATTLEDRONE1, nil, 25, 15, false, false, 'F');
  MakeOneSprite('DroneA1Chunk6', _MTRX_BATTLEDRONE1, nil, 19, 18, false, false, 'G');
  MakeOneSprite('DroneA1Chunk7', _MTRX_BATTLEDRONE1, nil, 14, 25, false, false, 'H');
  MakeOneSprite('DroneA1Chunk8', _MTRX_BATTLEDRONE1, nil, 17, 31, false, false, 'I');
  MakeOneSprite('DroneA3Chunk', _MTRX_BATTLEDRONE1, nil, 7, 11, false, false, 'J');

  // MT_MISSILEBOAT1
  MakeRotatingSprite8('DroneC', _MTRX_MISSILEBOAT1, 1, nil, 83, 68, false, false);
  MakeOneSprite('DroneCLeftChunk1', _MTRX_MISSILEBOAT1, nil, 46, 46, false, false, 'B');
  MakeOneSprite('DroneCLeftChunk2', _MTRX_MISSILEBOAT1, nil, 44, 50, false, false, 'C');
  MakeOneSprite('DroneCLeftChunk3', _MTRX_MISSILEBOAT1, nil, 38, 45, false, false, 'D');
  MakeOneSprite('DroneCLeftChunk4', _MTRX_MISSILEBOAT1, nil, 35, 39, false, false, 'E');
  MakeOneSprite('DroneCLeftChunk5', _MTRX_MISSILEBOAT1, nil, 37, 34, false, false, 'F');
  MakeOneSprite('DroneCLeftChunk6', _MTRX_MISSILEBOAT1, nil, 41, 36, false, false, 'G');
  MakeOneSprite('DroneCLeftChunk7', _MTRX_MISSILEBOAT1, nil, 42, 35, false, false, 'H');
  MakeOneSprite('DroneCLeftChunk8', _MTRX_MISSILEBOAT1, nil, 44, 35, false, false, 'I');
  MakeRotatingSprite8('MissileBoatBody', _MTRX_MISSILEBOAT1, 1, nil, 85, 42, false, false, 'J');
  MakeOneSprite('DroneCSingleChunk1', _MTRX_MISSILEBOAT1, nil, 11, 17, false, false, 'K');
  MakeOneSprite('DroneCSingleChunk2', _MTRX_MISSILEBOAT1, nil, 17, 16, false, false, 'L');

  // MT_SKYFIREASSULTFIGHTER1
  MakeRotatingSprite8('LightAssault', _MTRX_SKYFIREASSULTFIGHTER1, 1, nil, 62, 51, false, false);
  MakeOneSprite('StormBirdChunk5', _MTRX_SKYFIREASSULTFIGHTER1, nil, 50, 45, false, false, 'B');
  MakeRotatingSprite8('SkyFireBodyBusted', _MTRX_SKYFIREASSULTFIGHTER1, 1, nil, 72, 31, false, false, 'C');

  // MT_STORMBIRDHEAVYBOMBER
  MakeRotatingSprite8('HeavyFighter', _MTRX_STORMBIRDHEAVYBOMBER, 1, nil, 86, 54, false, false);
  MakeOneSprite('SkyFireChunk1', _MTRX_STORMBIRDHEAVYBOMBER, nil, 51, 53, false, false, 'B');
  MakeRotatingSprite8('StormBirdBodyBust', _MTRX_STORMBIRDHEAVYBOMBER, 1, nil, 82, 48, false, false, 'C');

  // MT_SPAWNER
  MakeRotatingSprite8('Spawner', _MTRX_SPAWNER, 1, nil, 146, 154, false, false);

  // MT_EXODROID
  MakeRotatingSprite8('ExoDroid', _MTRX_EXODROID, 3, nil, 113, 188, false, false);
  MakeOneSprite('ExoDroidFire1', _MTRX_EXODROID, nil, 56, 192, false, false, 'D', '1', 'E1');
  MakeOneSprite('ExoDroidFire2', _MTRX_EXODROID, nil, 100, 192, false, false, 'D', '2', 'E8');
  MakeOneSprite('ExoDroidFire3', _MTRX_EXODROID, nil, 126, 188, false, false, 'D', '3', 'E7');
  MakeOneSprite('ExoDroidFire4', _MTRX_EXODROID, nil, 94, 190, false, false, 'D', '4', 'E6');
  MakeOneSprite('ExoDroidFire5', _MTRX_EXODROID, nil, 48, 188, false, false, 'D', '5', 'E5');
  MakeOneSprite('ExoDroidFire6', _MTRX_EXODROID, nil, 98, 188, false, false, 'D', '6', 'E4');
  MakeOneSprite('ExoDroidFire7', _MTRX_EXODROID, nil, 121, 188, false, false, 'D', '7', 'E3');
  MakeOneSprite('ExoDroidFire8', _MTRX_EXODROID, nil, 117, 191, false, false, 'D', '8', 'E2');
  MakeOneSprite('Exo-DroidArm1', _MTRX_EXODROID, nil, 58, 63, false, false, 'F');
  MakeOneSprite('Exo-DroidArm2', _MTRX_EXODROID, nil, 64, 56, false, false, 'G');
  MakeOneSprite('Exo-DroidArm3', _MTRX_EXODROID, nil, 64, 46, false, false, 'H');
  MakeOneSprite('Exo-DroidArm4', _MTRX_EXODROID, nil, 55, 35, false, false, 'I');
  MakeOneSprite('Exo-DroidArm5', _MTRX_EXODROID, nil, 46, 33, false, false, 'J');
  MakeOneSprite('Exo-DroidArm6', _MTRX_EXODROID, nil, 42, 38, false, false, 'K');
  MakeOneSprite('Exo-DroidArm7', _MTRX_EXODROID, nil, 40, 48, false, false, 'L');
  MakeOneSprite('Exo-DroidArm8', _MTRX_EXODROID, nil, 45, 55, false, false, 'M');
  MakeOneSprite('Exo-DroidDeadBitmap', _MTRX_EXODROID, nil, 65, 24, false, false, 'N');

  // MT_SNAKEDEAMON
  MakeNonRotatingSprite('SnakeDemonBadassHead', _MTRX_SNAKEDEAMON, 3, nil, 57, 109, false, false);
  MakeOneSprite('SnakeDemonBadassBody', _MTRX_SNAKEDEAMON, nil, 41, 34, false, false, 'D');
  MakeOneSprite('SnakeDemonBadassBody', _MTRX_SNAKEDEAMON, nil, 41, 65, false, false, 'E');

  // MT_MINE
  MakeNonRotatingSprite('Airmine', _MTRX_MINE, 3, nil, 51, 93, false, false);

  // MT_ROTATINGRADAR1
  MakeRotatingSprite8('RadarDish', _MTRX_ROTATINGRADAR1, 1, nil, 53, 91, false, false);

  // MT_SHIELDGENERATOR1
  MakeNonRotatingSprite('ShieldGen', _MTRX_SHIELDGENERATOR1, 3, nil, 34, 135, false, false);

  // MT_SECONDCOOLAND1
  MakeNonRotatingSprite('SecondCoolant', _MTRX_SECONDCOOLAND1, 3, nil, 64, 183, false, false);

  // MT_BIOMECHUP
  MakeOneSprite('BioMech9', _MTRX_BIOMECHUP, nil, 45, 89, false, false);
  MakeOneSprite('BioMechBodyBust1', _MTRX_BIOMECHUP, nil, 75, 47, false, false, 'B', '1', 'C1');
  MakeOneSprite('BioMechBodyBust2', _MTRX_BIOMECHUP, nil, 75, 47, false, false, 'B', '2', 'C8');
  MakeOneSprite('BioMechBodyBust3', _MTRX_BIOMECHUP, nil, 75, 47, false, false, 'B', '3', 'C7');
  MakeOneSprite('BioMechBodyBust4', _MTRX_BIOMECHUP, nil, 75, 47, false, false, 'B', '4', 'C6');
  MakeOneSprite('BioMechBodyBust5', _MTRX_BIOMECHUP, nil, 75, 47, false, false, 'B', '5', 'C5');
  MakeOneSprite('BioMechBodyBust6', _MTRX_BIOMECHUP, nil, 75, 47, false, false, 'B', '6', 'C4');
  MakeOneSprite('BioMechBodyBust7', _MTRX_BIOMECHUP, nil, 75, 47, false, false, 'B', '7', 'C3');
  MakeOneSprite('BioMechBodyBust8', _MTRX_BIOMECHUP, nil, 75, 47, false, false, 'B', '8', 'C2');
  MakeOneSprite('BioMechChunk', _MTRX_BIOMECHUP, nil, 14, 14, false, false, 'D');
  MakeOneSprite('BioXplode1', _MTRX_BIOMECHUP, nil, 35, 29, false, false, 'E');
  MakeOneSprite('BioXplode2', _MTRX_BIOMECHUP, nil, 57, 44, false, false, 'F');
  MakeOneSprite('BioXplode3', _MTRX_BIOMECHUP, nil, 58, 48, false, false, 'G');
  MakeOneSprite('BioXplode4', _MTRX_BIOMECHUP, nil, 62, 60, false, false, 'H');
  MakeOneSprite('BioXplode5', _MTRX_BIOMECHUP, nil, 63, 56, false, false, 'I');
  MakeOneSprite('BioChunk1', _MTRX_BIOMECHUP, nil, 24, 20, false, false, 'J');
  MakeOneSprite('BioChunk2', _MTRX_BIOMECHUP, nil, 7, 18, false, false, 'K');
  MakeOneSprite('BioChunk3', _MTRX_BIOMECHUP, nil, 9, 11, false, false, 'L');
  MakeOneSprite('BioChunk4', _MTRX_BIOMECHUP, nil, 6, 13, false, false, 'M');

  // MT_ENGINECORE
  MakeNonRotatingSprite('EngineCore', _MTRX_ENGINECORE, 3, nil, 59, 184, false, false);

  // MT_DEFENCEDRONE1
  MakeRotatingSprite8('DroneB', _MTRX_DEFENCEDRONE1, 1, nil, 63, 67, false, false);

  // MT_BATTLEDRONE2
  MakeRotatingSprite8('DroneA', _MTRX_BATTLEDRONE2, 1, nil, 91, 50, false, false);

  // MT_MISSILEBOAT2
  MakeRotatingSprite8('DroneC', _MTRX_MISSILEBOAT2, 1, nil, 83, 68, false, false);

  // MT_SKYFIREASSULTFIGHTER2
  MakeRotatingSprite8('LightAssault', _MTRX_SKYFIREASSULTFIGHTER2, 1, nil, 62, 51, false, false);

  // MT_SKYFIREASSULTFIGHTER4
  MakeRotatingSprite8('LightAssault', _MTRX_SKYFIREASSULTFIGHTER4, 1, nil, 62, 51, false, false);

  // MT_BIOMECH
  MakeRotatingSprite8('BioMech', _MTRX_BIOMECH, 1, nil, 73, 60, false, false);

  // MT_DEFENCEDRONE2
  MakeRotatingSprite8('DroneB', _MTRX_DEFENCEDRONE2, 1, nil, 63, 67, false, false);

  // MT_RUI
  MakeOneSprite('Rui_1', _MTRX_RUI, nil, 16, 58, false, false, 'A');
  MakeOneSprite('Rui_2', _MTRX_RUI, nil, 25, 58, false, false, 'B');
  MakeOneSprite('Rui_3', _MTRX_RUI, nil, 31, 64, false, false, 'C');
  MakeOneSprite('RuiBust_1', _MTRX_RUI, nil, 32, 58, false, false, 'D');
  MakeOneSprite('RuiBust_2', _MTRX_RUI, nil, 32, 58, false, false, 'E');
  MakeOneSprite('RuiBust_3', _MTRX_RUI, nil, 32, 58, false, false, 'F');
  MakeOneSprite('RuiFall', _MTRX_RUI, nil, 42, 52, false, false, 'G');
  MakeOneSprite('RuiDead', _MTRX_RUI, nil, 54, 19, false, false, 'H');

  // MT_SHIELDGENERATOR2
  MakeNonRotatingSprite('ShldGenerator', _MTRX_SHIELDGENERATOR2, 3, nil, 44, 176, false, false);

  // MT_COOLANDGENERATOR
  MakeNonRotatingSprite('CoolantGener', _MTRX_COOLANDGENERATOR, 3, nil, 55, 190, false, false);

  // MT_ROTATINGRADAR2
  MakeRotatingSprite8('RadarDish', _MTRX_ROTATINGRADAR2, 1, nil, 53, 91, false, false);

  // MT_MISSILEBOAT_STUB
  MakeRotatingSprite8('DroneC', _MTRX_MISSILEBOAT_STUB, 1, nil, 83, 68, false, false);

  // MT_BATTLEDRONE3
  MakeRotatingSprite8('DroneA', _MTRX_BATTLEDRONE3, 1, nil, 91, 50, false, false);

  // MT_ROTATINGLIGHT
  MakeOneSprite('RotatingLight2', _MTRX_ROTATINGLIGHT, nil, 10, 61, true, true, 'A');
  MakeOneSprite('RotatingLight3', _MTRX_ROTATINGLIGHT, nil, 10, 61, true, true, 'B');
  MakeOneSprite('RotatingLight4', _MTRX_ROTATINGLIGHT, nil, 10, 61, true, true, 'C');
  MakeOneSprite('RotatingLight5', _MTRX_ROTATINGLIGHT, nil, 10, 61, true, true, 'D');
  MakeOneSprite('RotatingLight6', _MTRX_ROTATINGLIGHT, nil, 10, 61, true, true, 'E');
  MakeOneSprite('RotatingLight7', _MTRX_ROTATINGLIGHT, nil, 10, 61, true, true, 'F');
  MakeOneSprite('RotatingLight8', _MTRX_ROTATINGLIGHT, nil, 10, 61, true, true, 'G');
  MakeOneSprite('RotatingLight9', _MTRX_ROTATINGLIGHT, nil, 10, 61, true, true, 'H');
  MakeOneSprite('RotatingLightBUST', _MTRX_ROTATINGLIGHT, nil, 10, 37, true, true, 'I');

  // MT_EGG
  MakeOneSprite('Egg', _MTRX_EGG, nil, 62, 82, false, false, 'A');
  MakeOneSprite('Eggbust', _MTRX_EGG, nil, 62, 82, false, false, 'B');

  // MT_RADIXBARREL
  MakeOneSprite('Barrel', _MTRX_RADIXBARREL, nil, 25, 57, false, false, 'A');
  MakeOneSprite('BarrelDUDbust', _MTRX_RADIXBARREL, nil, 22, 23, false, false, 'B');

  MakeOneSprite('BarrelRotate1', _MTRX_RADIXBARREL, nil, 41, 77, false, false, 'C');
  MakeOneSprite('BarrelRotate2', _MTRX_RADIXBARREL, nil, 41, 77, false, false, 'D');
  MakeOneSprite('BarrelRotate3(end)', _MTRX_RADIXBARREL, nil, 41, 77, false, false, 'E');
  MakeOneSprite('BarrelRotate4', _MTRX_RADIXBARREL, nil, 41, 77, false, false, 'F');
  MakeOneSprite('BarrelRotate5(end)', _MTRX_RADIXBARREL, nil, 41, 77, false, false, 'G');
  MakeOneSprite('BarrelRotate6', _MTRX_RADIXBARREL, nil, 41, 77, false, false, 'H');
  MakeOneSprite('BarrelRotate7(end)', _MTRX_RADIXBARREL, nil, 41, 77, false, false, 'I');
  MakeOneSprite('BarrelRotate8', _MTRX_RADIXBARREL, nil, 41, 77, false, false, 'J');
  MakeOneSprite('BarrelRotate3(end)', _MTRX_RADIXBARREL, nil, 41, 60, false, false, 'K');
  MakeOneSprite('BarrelRotate5(end)', _MTRX_RADIXBARREL, nil, 41, 60, false, false, 'L');
  MakeOneSprite('BarrelRotate7(end)', _MTRX_RADIXBARREL, nil, 41, 60, false, false, 'M');

  // MT_DOZZER
  MakeOneSprite('Dozer1', _MTRX_DOZZER, nil, 98, 70, false, false, 'A', '1');
  MakeOneSprite('Dozer2', _MTRX_DOZZER, nil, 98, 70, false, false, 'A', '2', 'A8');
  MakeOneSprite('Dozer3', _MTRX_DOZZER, nil, 98, 70, false, false, 'A', '3', 'A7');
  MakeOneSprite('Dozer4', _MTRX_DOZZER, nil, 98, 78, false, false, 'A', '4', 'A6');
  MakeOneSprite('Dozer5', _MTRX_DOZZER, nil, 98, 70, false, false, 'A', '5');

  // MT_LIFT
  MakeRotatingSprite8('Lift', _MTRX_LIFT, 1, nil, 110, 88, false, false);

  // MT_SECONDCOOLAND2
  MakeNonRotatingSprite('SecondCoolant', _MTRX_SECONDCOOLAND2, 1, nil, 64, 183, false, false);

  // MT_SECONDCOOLAND3
  MakeNonRotatingSprite('SecondCoolant', _MTRX_SECONDCOOLAND3, 1, nil, 64, 183, false, false);

  // Radix things without doom editor number (runtime)
  // MT_RADIXPLASMA
  MakeNonRotatingSprite('Plasma', _MTTX_RADIXPLASMA, 3, nil, 21, 24, false, false);
  MakeOneSprite('NeutronCannonPuff1', _MTTX_RADIXPLASMA, nil, 13, 12, false, false, 'D');
  MakeOneSprite('PlasmaPuf1', _MTTX_RADIXPLASMA, nil, 16, 16, false, false, 'E');
  MakeOneSprite('PlasmaPuf2', _MTTX_RADIXPLASMA, nil, 12, 12, false, false, 'F');
  MakeOneSprite('PlasmaPuf3', _MTTX_RADIXPLASMA, nil, 9, 11, false, false, 'G');

  // MT_RADIXEPCSHELL
  MakeOneSprite('FireSmoke1', _MTTX_RADIXEPCSHELL, nil, 8, 7, false, false, 'A');
  MakeOneSprite('FireSmoke2', _MTTX_RADIXEPCSHELL, nil, 8, 7, false, false, 'B');
  MakeOneSprite('FireSmoke3', _MTTX_RADIXEPCSHELL, nil, 7, 7, false, false, 'C');

  // MT_RADIXSEEKINGMISSILE
  MakeRotatingSprite16('Seeker', _MTTX_RADIXSEEKINGMISSILE, 1, nil, 49, 17, false, false);

  // Radix sprites shared between objects
  MakeNonRotatingSprite('10FrameExplosion', _DOOM_THING_2_RADIX_ + 0, 10, nil, 49, 46, false, false);
  MakeNonRotatingSprite('SmallXplode', _DOOM_THING_2_RADIX_ + 1, 5, nil, 26, 21, false, false);
  MakeNonRotatingSprite('RisingSmoke', _DOOM_THING_2_RADIX_ + 2, 10, nil, 75, 62, false, false);
  MakeOneSprite('BurnerSmoke1', _DOOM_THING_2_RADIX_ + 3, nil, 8, 7, false, false, 'A');
  MakeOneSprite('BurnerSmoke2', _DOOM_THING_2_RADIX_ + 3, nil, 8, 7, false, false, 'B');
  MakeOneSprite('BurnerSmoke3', _DOOM_THING_2_RADIX_ + 3, nil, 7, 7, false, false, 'C');
  MakeOneSprite('FireballPuff1', _DOOM_THING_2_RADIX_ + 4, nil, 12, 11, false, false, 'A');
  MakeOneSprite('FireballPuff2', _DOOM_THING_2_RADIX_ + 4, nil, 12, 11, false, false, 'B');
  MakeOneSprite('FireballPuff3', _DOOM_THING_2_RADIX_ + 4, nil, 12, 11, false, false, 'C');

  // MT_RADIXNUKE
  MakeRotatingSprite16('Nuke', _MTTX_RADIXNUKE, 1, nil, 42, 16, false, false);

  // MT_RADIXPHASETORPEDO
  MakeOneSprite('PhaseTorpedo1', _MTTX_RADIXPHASETORPEDO, nil, 16, 17, false, false, 'A');
  MakeOneSprite('PhaseTorpedo2', _MTTX_RADIXPHASETORPEDO, nil, 15, 17, false, false, 'B');
  MakeOneSprite('PhaseTorpedo3', _MTTX_RADIXPHASETORPEDO, nil, 18, 17, false, false, 'C');

  // MT_RADIXGRAVITYWAVE
  MakeOneSprite('GravityWave1', _MTTX_RADIXGRAVITYWAVE, nil, 99, 28, false, false, 'A');
  MakeOneSprite('GravityWave2', _MTTX_RADIXGRAVITYWAVE, nil, 99, 28, false, false, 'B');
  MakeOneSprite('GravityWave3', _MTTX_RADIXGRAVITYWAVE, nil, 99, 28, false, false, 'C');

  // MT_RADIXGRAVITYWAVEEXPOLOSION
  MakeOneSprite('GravityWavePuf1', _MTTX_RADIXGRAVITYWAVEEXPOLOSION, nil, 19, 20, false, false, 'A');
  MakeOneSprite('GravityWavePuf2', _MTTX_RADIXGRAVITYWAVEEXPOLOSION, nil, 19, 20, false, false, 'B');
  MakeOneSprite('GravityWavePuf3', _MTTX_RADIXGRAVITYWAVEEXPOLOSION, nil, 19, 18, false, false, 'C');
  MakeOneSprite('GravityWavePuf4', _MTTX_RADIXGRAVITYWAVEEXPOLOSION, nil, 19, 18, false, false, 'D');
  MakeOneSprite('GravityWavePuf5', _MTTX_RADIXGRAVITYWAVEEXPOLOSION, nil, 11, 15, false, false, 'E');

  // MT_ENEMYMISSILE
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 14, 12, false, false, 1);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 22, 12, false, false, 2);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 32, 12, false, false, 3);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 37, 12, false, false, 4);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 37, 12, false, false, 5);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 36, 13, false, false, 6);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 31, 14, false, false, 7);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 23, 14, false, false, 8);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 14, 13, false, false, 9);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 23, 14, false, false, 10);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 31, 14, false, false, 11);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 36, 13, false, false, 12);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 38, 13, false, false, 13);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 37, 12, false, false, 14);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 32, 12, false, false, 15);
  MakeRotatingSprite16('Missile', _MTTX_ENEMYMISSILE, 1, nil, 22, 12, false, false, 16);

  // MT_DRONEBODYB
  MakeRotatingSprite8('DroneBBody', _MTTX_DRONEBODYB, 1, nil, 93, 48, false, false);

  // MT_ENEMYLASER
  MakeOneSprite('EnemyLaser1', _MTTX_ENEMYLASER, nil, 19, 18, false, false, 'A');
  MakeOneSprite('EnemyLaser2', _MTTX_ENEMYLASER, nil, 16, 18, false, false, 'B');
  MakeOneSprite('EnemyLaser3', _MTTX_ENEMYLASER, nil, 17, 18, false, false, 'C');

  // MT_DRONEBODYA
  MakeOneSprite('DroneABodyBusted1', _MTTX_DRONEBODYA, nil, 63, 37, false, false);

  // MT_CHUNK
  MakeOneSprite('StrongBio-MineDead1', _MTTX_CHUNK, nil, 11, 13, false, false, 'A');
  MakeOneSprite('StrongBio-MineDead2', _MTTX_CHUNK, nil, 15, 15, false, false, 'B');
  MakeOneSprite('StrongBio-MineDead3', _MTTX_CHUNK, nil, 17, 24, false, false, 'C');
  MakeOneSprite('MetalChunk1', _MTTX_CHUNK, nil, 8, 8, false, false, 'D');
  MakeOneSprite('MetalChunk2', _MTTX_CHUNK, nil, 9, 10, false, false, 'E');
  MakeOneSprite('MetalChunk3', _MTTX_CHUNK, nil, 10, 15, false, false, 'F');
  MakeOneSprite('MetalChunk4', _MTTX_CHUNK, nil, 11, 14, false, false, 'G');

  // MT_ALDSLASER
  MakeRotatingSprite16('ALDSLaser', _MTTX_ALDSLASER, 1, nil, 24, 4, false, false);

  // MT_LASER
  MakeRotatingSprite16('Laser', _MTTX_LASER, 1, nil, 24, 4, false, false);

  // MT_BLOODSPLAT
  MakeNonRotatingSprite('BloodSplat', _MTTX_BLOODSPLAT, 3, nil, 31, 33, false, false);

  // MT_SPARKS
  MakeNonRotatingSprite('Sparks', _MTTX_SPARKS, 5, nil, 73, 63, false, false);

  // MT_RADIXWATERSPLASH
  MakeNonRotatingSprite('WaterSplash', _MTTX_RADIXWATERSPLASH, 6, nil, 35, 43, false, false);
  MakeOneSprite('WaterSplash7', _MTTX_RADIXWATERSPLASH, nil, 55, 33, false, false, 'G');
  MakeOneSprite('WaterSplash8', _MTTX_RADIXWATERSPLASH, nil, 55, 33, false, false, 'H');
  MakeOneSprite('WaterSplash9', _MTTX_RADIXWATERSPLASH, nil, 55, 33, false, false, 'I');

  // MT_RADIXMUDSPLASH
  MakeNonRotatingSprite('MudSplash', _MTTX_RADIXMUDSPLASH, 6, nil, 35, 43, false, false);
  MakeOneSprite('MudSplash7', _MTTX_RADIXMUDSPLASH, nil, 55, 33, false, false, 'G');
  MakeOneSprite('MudSplash8', _MTTX_RADIXMUDSPLASH, nil, 55, 33, false, false, 'H');
  MakeOneSprite('MudSplash9', _MTTX_RADIXMUDSPLASH, nil, 55, 33, false, false, 'I');

  // MT_RADIXLAVASPLASH
  MakeNonRotatingSprite('LavaSplash', _MTTX_RADIXLAVASPLASH, 6, nil, 35, 43, false, false);
  MakeOneSprite('LavaSplash7', _MTTX_RADIXLAVASPLASH, nil, 55, 33, false, false, 'G');
  MakeOneSprite('LavaSplash8', _MTTX_RADIXLAVASPLASH, nil, 55, 33, false, false, 'H');
  MakeOneSprite('LavaSplash9', _MTTX_RADIXLAVASPLASH, nil, 55, 33, false, false, 'I');

  // 'PLAY' sprite
  MakeRotatingSprite8('NetRadixPlane', _DOOM_THING_2_RADIX_ + 5, 1);
  for ch := 'B' to 'W' do
    MakeRotatingSprite8('NetRadixPlane', _DOOM_THING_2_RADIX_ + 5, 1, nil, -255, -255, true, true, ch);

  bmp := TRadixBitmap.Create;

  for j := 0 to numsprinfo - 1 do
  begin
    spr := @SPRITEINFO[j];
    if spr.dname = 'XR63A7' then
      continue;

    bl := nil;
    for i := 0 to bnumlumps - 1 do
      if radixlumpnames.Strings[i] = spr.rname then
      begin
        bl := @blumps[i];
        break;
      end;

    if bl = nil then
    begin
      spr.rname := remove_underline(spr.rname);
      for i := 0 to bnumlumps - 1 do
        if radixlumpnames.Strings[i] = spr.rname then
        begin
          bl := @blumps[i];
          break;
        end;
    end;

    if bl = nil then
    begin
      stmp := spr.dname;
      wadwriter.AddData(stmp, @TNT1A0, SizeOf(TNT1A0));
      Continue;
    end;

    f.Seek(bl.position + (bl.width - 1) * SizeOf(radixcolumn_t), sFromBeginning);
    f.Read(rcol, SizeOf(radixcolumn_t));
    f.Seek(bl.position, sFromBeginning);

    buf := malloc(rcol.offs + rcol.size);
    f.Read(buf^, rcol.offs + rcol.size);

    bmp.width := bl.width;
    bmp.height := bl.height;

    bmp.Clear(254);

    pc := Pradixcolumn_tArray(buf);

    for x := 0 to bl.width - 1 do
      for y := pc[x].start to pc[x].start + pc[x].size - 1 do
      begin
        z := pc[x].offs - pc[x].start + y;
        z := buf[z];
        if z < 255 then
          bmp.Pixels[x, y] := z;
      end;

    if spr.translation <> nil then
      bmp.ApplyTranslationTable(spr.translation);

    if (spr.dname = 'XR38B1') or (spr.dname = 'XR38B2') or (spr.dname = 'XR38B8') then
    begin
      for x := 0 to bmp.width - 1 do
        if bmp.Pixels[x, 0] = 0 then
          bmp.Pixels[x, 0] := 254;
    end
    else if (spr.dname = 'XR38A5') or (spr.dname = 'XR38A6') or (spr.dname = 'XR38C4') or (spr.dname = 'XR38C5') then
    begin
      for x := 0 to bmp.width - 1 do
        if bmp.Pixels[x, bmp.height - 1] = 0 then
          bmp.Pixels[x, bmp.height - 1] := 254;
    end
    else if (spr.dname = 'XR63A3') then
    begin
      spr.dname := 'XR63A3A7';
      spr.yoffs := 77;
    end
    else if (spr.dname = 'XR64A4') or (spr.dname = 'XR64A6') then
    begin
      bl.height := 96;
      bmp.Crop(bmp.width, 96);
    end;

    if spr.defaultoffs then
      RX_CreateDoomPatch(bmp.Image, bl.width, bl.height, false, p, size)
    else if spr.centeroffs then
      RX_CreateDoomPatch(bmp.Image, bl.width, bl.height, false, p, size, bl.width div 2, bl.height div 2)
    else
      RX_CreateDoomPatch(bmp.Image, bl.width, bl.height, false, p, size, spr.xoffs, spr.yoffs);

    stmp := spr.dname;

    wadwriter.AddData(stmp, p, size);

    memfree(pointer(buf), rcol.offs + rcol.size);
    memfree(p, size);
  end;

  radixlumpnames.Free;
  bmp.Free;

  wadwriter.AddSeparator('S_END');

  memfree(pointer(blumps), bnumlumps * SizeOf(radixbitmaplump_t));
end;

function TRadixToWADConverter.GenerateExtraSprites: boolean;
begin
  result := true;
  wadwriter.AddSeparator('S_START');
  AddEntryDirect('IFOGA0', @IFOGA0_RawData, SizeOf(IFOGA0_RawData));
  AddEntryDirect('IFOGB0', @IFOGB0_RawData, SizeOf(IFOGB0_RawData));
  AddEntryDirect('IFOGC0', @IFOGC0_RawData, SizeOf(IFOGC0_RawData));
  AddEntryDirect('IFOGD0', @IFOGD0_RawData, SizeOf(IFOGD0_RawData));
  AddEntryDirect('IFOGE0', @IFOGE0_RawData, SizeOf(IFOGE0_RawData));
  AddEntryDirect('TFOGA0', @TFOGA0_RawData, SizeOf(TFOGA0_RawData));
  AddEntryDirect('TFOGB0', @TFOGB0_RawData, SizeOf(TFOGB0_RawData));
  AddEntryDirect('TFOGC0', @TFOGC0_RawData, SizeOf(TFOGC0_RawData));
  AddEntryDirect('TFOGD0', @TFOGD0_RawData, SizeOf(TFOGD0_RawData));
  AddEntryDirect('TFOGE0', @TFOGE0_RawData, SizeOf(TFOGE0_RawData));
  AddEntryDirect('TFOGF0', @TFOGF0_RawData, SizeOf(TFOGF0_RawData));
  AddEntryDirect('TFOGG0', @TFOGG0_RawData, SizeOf(TFOGG0_RawData));
  AddEntryDirect('TFOGH0', @TFOGH0_RawData, SizeOf(TFOGH0_RawData));
  AddEntryDirect('TFOGI0', @TFOGI0_RawData, SizeOf(TFOGI0_RawData));
  AddEntryDirect('TFOGJ0', @TFOGJ0_RawData, SizeOf(TFOGJ0_RawData));
  AddEntryDirect('BKEYA0', @BKEYA0_RawData, SizeOf(BKEYA0_RawData));
  AddEntryDirect('BKEYB0', @BKEYB0_RawData, SizeOf(BKEYB0_RawData));
  AddEntryDirect('BSKUA0', @BSKUA0_RawData, SizeOf(BSKUA0_RawData));
  AddEntryDirect('BSKUB0', @BSKUB0_RawData, SizeOf(BSKUB0_RawData));
  AddEntryDirect('RKEYA0', @RKEYA0_RawData, SizeOf(RKEYA0_RawData));
  AddEntryDirect('RKEYB0', @RKEYB0_RawData, SizeOf(RKEYB0_RawData));
  AddEntryDirect('RSKUA0', @RSKUA0_RawData, SizeOf(RSKUA0_RawData));
  AddEntryDirect('RSKUB0', @RSKUB0_RawData, SizeOf(RSKUB0_RawData));
  AddEntryDirect('YKEYA0', @YKEYA0_RawData, SizeOf(YKEYA0_RawData));
  AddEntryDirect('YKEYB0', @YKEYB0_RawData, SizeOf(YKEYB0_RawData));
  AddEntryDirect('YSKUA0', @YSKUA0_RawData, SizeOf(YSKUA0_RawData));
  AddEntryDirect('YSKUB0', @YSKUB0_RawData, SizeOf(YSKUB0_RawData));
  wadwriter.AddSeparator('S_END');
end;

function TRadixToWADConverter.GenerateMusic: boolean;
var
  i, j: integer;
  mbuffer: pointer;
  msize: integer;
begin
  result := ReadLump(lumps, numlumps, 'IntroMusic', mbuffer, msize);
  if not result then
    exit;

  result := true;
  wadwriter.AddData('D_INTRO', mbuffer, msize);
  memfree(mbuffer, msize);

  for i := 1 to 3 do
    for j := 1 to 9 do
    begin
      if ReadLump(lumps, numlumps, 'MusicModule[' + itoa(i) +'][' + itoa(j) + ']', mbuffer, msize) then
      begin
        wadwriter.AddData('D_E' + itoa(i) + 'M' + itoa(j), mbuffer, msize);
        memfree(mbuffer, msize);
      end;
    end;
end;

function TRadixToWADConverter.GenerateCockpitOverlay: boolean;
var
  l: integer;
  startpos: integer;
  sizes: packed array[0..3] of smallint;
  positions: packed array[0..3] of smallint;
  idx: integer;
  i: integer;
  imgpos: integer;
  x, y: integer;
  b: byte;
  bmp: TRadixBitmap;
  p: pointer;
  size: integer;

  procedure imgpos2xy;
  var
    x1: integer;
    x2: integer;
    y1: integer;
    y2: integer;
  begin
    x := imgpos mod 320;
    y := imgpos div 320;
    x1 := x div 80;
    x2 := x mod 80;
    y1 := y div 50;
    y2 := y mod 50;
    x := x2 * 4 + y1;
    y := y2 * 4 + x1;
  end;

begin
  l := FindLump(lumps, numlumps, 'CockPitOverlay');
  if l < 0 then
  begin
    result := false;
    exit;
  end;
  result := true;


  bmp := TRadixBitmap.Create;
  bmp.width := 320;
  bmp.height := 200;
  bmp.Clear(254);

  startpos := lumps[l].position;
  f.Seek(startpos, sFromBeginning);

  f.Read(sizes, SizeOf(sizes));
  positions[0] := 12;
  positions[1] := sizes[0] + positions[0];
  positions[2] := sizes[1] + positions[1];
  positions[3] := sizes[2] + positions[2];
  for idx := 0 to 3 do
  begin
    imgpos := 320 * 50 * idx;
    f.Seek(startpos + positions[idx], sFromBeginning);
    for i := 0 to sizes[idx] - 1 do
    begin
      f.Read(b, SizeOf(byte));
      if b = 255 then
        break;
      if b = 0 then
      begin
        f.Read(b, SizeOf(b));
        imgpos := imgpos + b;
      end
      else
      begin
        if imgpos < 320 * 200 then
        begin
          imgpos2xy;
          bmp.Pixels[x, y] := b;
        end;
        imgpos := imgpos + 1;
      end;
    end;
  end;

  RX_CreateDoomPatch(bmp.Image, 320, 200, false, p, size, 0, 0);

  wadwriter.AddData('COCKPIT', p, size);

  memfree(p, size);
  bmp.Free;
end;

function TRadixToWADConverter.GenerateSounds: boolean;
var
  i: integer;
  sbuffer: pointer;
  ssize: integer;
  wname, rname: string;
  sndinfo: TDStringList;
begin
  sndinfo := TDStringList.Create;
  sndinfo.Add('// Radix Sounds');
  sndinfo.Add('');
  result := false;
  for i := 0 to Ord(sfx_NumRadixSnd) - 1 do
  begin
    rname := radixsounds[i].name;
    if ReadLump(lumps, numlumps, rname, sbuffer, ssize) then
    begin
      wname := 'DS_' + IntToStrzFill(5, i);
      wadwriter.AddData(wname, sbuffer, ssize);
      memfree(sbuffer, ssize);
      aliases.Add(wname + '=' + rname);
      sndinfo.Add('radix/' + rname + ' ' + wname);
      result := true;
    end;
  end;
  if result then
    wadwriter.AddString('SNDINFO', sndinfo.Text);
  sndinfo.Free;
end;

function TRadixToWADConverter.GenerateMissionText: boolean;
var
  rname, wname: string;
  i, j: integer;
  tbuffer: pointer;
  tsize: integer;
begin
  result := false;
  for i := 1 to 3 do
    for j := 1 to 9 do
    begin
      rname := 'MissionText[' + itoa(i) +'][' + itoa(j) + ']';
      if ReadLump(lumps, numlumps, rname, tbuffer, tsize) then
      begin
        wname := 'MNTEXT' + itoa(i) + itoa(j);
        wadwriter.AddData(wname, tbuffer, tsize);
        aliases.Add(wname + '=' + rname);
        result := true;
        memfree(tbuffer, tsize);
      end;
    end;
end;

function TRadixToWADConverter.GenerateEndText: boolean;
var
  rname, wname: string;
  i: integer;
  tbuffer: pointer;
  tsize: integer;
begin
  result := false;
  for i := 1 to 3 do
  begin
    rname := 'EndEpisode' + itoa(i) + 'Text';
    if ReadLump(lumps, numlumps, rname, tbuffer, tsize) then
    begin
      wname := 'C' + itoa(i) + 'TEXT';
      wadwriter.AddData(wname, tbuffer, tsize);
      aliases.Add(wname + '=' + rname);
      result := true;
      memfree(tbuffer, tsize);
    end;
  end;
end;

procedure TRadixToWADConverter.WritePK3Entry;
begin
  if aliases = nil then
    exit;
  if aliases.Count = 0 then
    exit;

  wadwriter.AddString(S_RADIXINF, aliases.Text);
end;

procedure TRadixToWADConverter.Convert_Game(const fname: string);
begin
  if not fexists(fname) then
    exit;

  Clear;

  ffilename := fname;
  f := TFile.Create(fname, fOpenReadOnly);
  wadwriter := TWadWriter.Create;
  aliases := TDStringList.Create;
  textures := TDStringList.Create;

  ReadHeader;
  ReadDirectory;
  GeneratePalette(PALETTE_LUMP_NAME, COLOMAP_LUMP_NAME);
  GenerateTranslationTables;
  GenerateTextures('PNAMES0', 'TEXTURE0');
  GenerateLevels;
  GenerateFlats;
  GenerateMainGraphics;
  GenerateAdditionalGraphics;
  GenerateSmallFont;
  GenerateBigFonts;
  GenerateDosFonts;
  GenerateMenuTranslation;
  GenerateSprites;
  GenerateMusic;
  GenerateCockpitOverlay;
  GenerateSounds;
  GenerateMissionText;
  GenerateEndText;
  WritePK3Entry;

  ffilename := '';
end;

procedure TRadixToWADConverter.Convert_Edit(const fname: string);
begin
  if not fexists(fname) then
    exit;

  Clear;

  ffilename := fname;
  f := TFile.Create(fname, fOpenReadOnly);
  wadwriter := TWadWriter.Create;
  aliases := TDStringList.Create;
  textures := TDStringList.Create;

  ReadHeader;
  ReadDirectory;
  GeneratePalette(DOOM_PALETTE_NAME, DOOM_COLORMAP_NAME);
  GenerateTextures('PNAMES', 'TEXTURE1');
  GenerateFlats;
  GenerateSprites;
  GenerateMusic;
  GenerateSounds;
  GenerateMissionText;
  GenerateEndText;

  ffilename := '';
end;

procedure TRadixToWADConverter.Convert(const fname: string; const flags: LongWord);
begin
  if not fexists(fname) then
    exit;

  Clear;

  ffilename := fname;
  f := TFile.Create(fname, fOpenReadOnly);
  wadwriter := TWadWriter.Create;
  aliases := TDStringList.Create;
  textures := TDStringList.Create;

  ReadHeader;
  ReadDirectory;
  if flags and R2W_PALETTE <> 0 then
    GeneratePalette(PALETTE_LUMP_NAME, COLOMAP_LUMP_NAME);
  if flags and R2W_DOOMPALETTE <> 0 then
    GeneratePalette(DOOM_PALETTE_NAME, DOOM_COLORMAP_NAME);
  if flags and R2W_TRANSLATION <> 0 then
    GenerateTranslationTables;
  if flags and R2W_TEXTURES <> 0 then
    GenerateTextures('PNAMES0', 'TEXTURE0');
  if flags and R2W_DOOMTEXTURES <> 0 then
    GenerateTextures('PNAMES', 'TEXTURE1');
  if flags and R2W_LEVELS <> 0 then
    GenerateLevels;
  if flags and R2W_DOOMLEVELS <> 0 then
    GenerateSimpleLevels;
  if flags and R2W_FLATS <> 0 then
    GenerateFlats;
  if flags and R2W_MAINGRAPHICS <> 0 then
    GenerateMainGraphics;
  if flags and R2W_ADDITIONALGRAPHICS <> 0 then
    GenerateAdditionalGraphics;
  if flags and R2W_SMALLMENUFONT <> 0 then
    GenerateSmallFont;
  if flags and R2W_BIGMENUFONT <> 0 then
    GenerateBigFonts;
  if flags and R2W_CONSOLEFONT <> 0 then
    GenerateDosFonts;
  if flags and R2W_MENUTRANSLATION <> 0 then
    GenerateMenuTranslation;
  if flags and R2W_SPRITES <> 0 then
    GenerateSprites;
  if flags and R2W_EXTRASPRITES <> 0 then
    GenerateExtraSprites;
  if flags and R2W_MUSIC <> 0 then
    GenerateMusic;
  if flags and R2W_COCKPIT <> 0 then
    GenerateCockpitOverlay;
  if flags and R2W_SOUNDS <> 0 then
    GenerateSounds;
  if flags and R2W_OBJECTIVES <> 0 then
    GenerateMissionText;
  if flags and R2W_ENDTEXT <> 0 then
    GenerateEndText;
  WritePK3Entry;

  ffilename := '';
end;

procedure TRadixToWADConverter.SaveToFile(const fname: string);
begin
  wadwriter.SaveToFile(fname);
end;

procedure TRadixToWADConverter.SaveToSream(const strm: TDStream);
begin
  wadwriter.SaveToStream(strm);
end;

procedure Radix2WAD_Game(const fin, fout: string);
var
  cnv: TRadixToWADConverter;
begin
  cnv := TRadixToWADConverter.Create;
  try
    cnv.makeallflats := true;
    cnv.Convert_Game(fin);
    cnv.SaveToFile(fout);
  finally
    cnv.Free;
  end;
end;

procedure Radix2Stream_Game(const fin: string; const strm: TDStream);
var
  cnv: TRadixToWADConverter;
begin
  cnv := TRadixToWADConverter.Create;
  try
    cnv.makeallflats := true;
    cnv.Convert_Game(fin);
    cnv.SaveToSream(strm);
  finally
    cnv.Free;
  end;
end;

procedure Radix2WAD_Edit(const fin, fout: string);
var
  cnv: TRadixToWADConverter;
begin
  cnv := TRadixToWADConverter.Create;
  try
    cnv.makeallflats := true;
    cnv.Convert_Edit(fin);
    cnv.SaveToFile(fout);
  finally
    cnv.Free;
  end;
end;

procedure Radix2Stream_Edit(const fin: string; const strm: TDStream);
var
  cnv: TRadixToWADConverter;
begin
  cnv := TRadixToWADConverter.Create;
  try
    cnv.makeallflats := true;
    cnv.Convert_Edit(fin);
    cnv.SaveToSream(strm);
  finally
    cnv.Free;
  end;
end;

procedure Radix2WAD(const fin, fout: string; const flags: LongWord);
var
  cnv: TRadixToWADConverter;
begin
  cnv := TRadixToWADConverter.Create;
  try
    cnv.makeallflats := true;
    cnv.Convert(fin, flags);
    cnv.SaveToFile(fout);
  finally
    cnv.Free;
  end;
end;

procedure Radix2Stream(const fin: string; const strm: TDStream; const flags: LongWord);
var
  cnv: TRadixToWADConverter;
begin
  cnv := TRadixToWADConverter.Create;
  try
    cnv.makeallflats := true;
    cnv.Convert(fin, flags);
    cnv.SaveToSream(strm);
  finally
    cnv.Free;
  end;
end;

procedure Radix2CSV(const fin: string; const pathout: string);
var
  cnv: TRadixToWADConverter;
begin
  cnv := TRadixToWADConverter.Create;
  try
    cnv.makeallflats := true;
    cnv.Convert_Game(fin);
    cnv.GenerateCSVs(pathout);
  finally
    cnv.Free;
  end;
end;

end.

