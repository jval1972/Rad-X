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
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit r_draw;

interface

uses
  d_delphi,
  doomdef,
  r_defs,
// Needs access to LFB (guess what).
  v_video;

//==============================================================================
//
// R_VideoErase
//
//==============================================================================
procedure R_VideoErase(const ofs: integer; const count: integer);

//==============================================================================
//
// R_VideoBlanc
//
//==============================================================================
procedure R_VideoBlanc(const scn: integer; const ofs: integer; const count: integer; const black: byte = 0);

//==============================================================================
//
// R_PlayerViewBlanc
//
//==============================================================================
procedure R_PlayerViewBlanc(const black: byte);

//==============================================================================
//
// R_InitBuffer
//
//==============================================================================
procedure R_InitBuffer(width, height: integer);

//==============================================================================
// R_InitTranslationTables
//
// Initialize color translation tables,
//  for player rendering etc.
//
//==============================================================================
procedure R_InitTranslationTables;

//==============================================================================
// R_FillBackScreen
//
// Rendering function.
//
//==============================================================================
procedure R_FillBackScreen;

//==============================================================================
// R_DrawViewBorder
//
// If the view size is not full screen, draws a border around it.
//
//==============================================================================
procedure R_DrawViewBorder;

//==============================================================================
// R_DrawDiskBusy
//
// Draw disk busy patch
//
//==============================================================================
procedure R_DrawDiskBusy;

var
  displaydiskbusyicon: boolean = true;

  translationtables: PByteArray;
  dc_translation: PByteArray;

  viewwidth: integer;
  viewheight: integer;
  scaledviewwidth: integer;

  viewwindowx: integer;
  viewwindowy: integer;

//
// All drawing to the view buffer is accomplished in this file.
// The other refresh files only know about ccordinates,
//  not the architecture of the frame buffer.
// Conveniently, the frame buffer is a linear one,
//  and we need only the base address,
//  and the total size == width*height*depth/8.,
//

var
  ylookup: array[0..MAXHEIGHT - 1] of PByteArray;
  ylookupl: array[0..MAXHEIGHT - 1] of PLongWordArray;
  columnofs: array[0..MAXWIDTH - 1] of integer;

var
  brdr_t: integer = -1;
  brdr_b: integer = -1;
  brdr_l: integer = -1;
  brdr_r: integer = -1;
  brdr_tl: integer = -1;
  brdr_tr: integer = -1;
  brdr_bl: integer = -1;
  brdr_br: integer = -1;

type
  crange_idx_e = (
    CR_BRICK,   //0
    CR_TAN,     //1
    CR_GRAY,    //2
    CR_GREEN,   //3
    CR_BROWN,   //4
    CR_GOLD,    //5
    CR_RED,     //6
    CR_BLUE,    //7
    CR_ORANGE,  //8
    CR_YELLOW,  //9
    CR_BLUE2,   //10
    CR_LIMIT    //11
  );

var
  colorregions: array[0..Ord(CR_LIMIT) - 1] of PByteArray;
{$IFDEF OPENGL}
  diskbusy_height: integer = 0;
{$ENDIF}

implementation

uses
  am_map,
  m_argv,
  m_menu,
  w_wad,
  z_zone,
  st_stuff,
  i_system,
{$IFDEF OPENGL}
  gl_render,
{$ELSE}
  r_hires,
{$ENDIF}
  v_data;

//==============================================================================
//
// R_InitTranslationTables
// Creates the translation tables to map
//  the green color ramp to gray, brown, red.
// Assumes a given structure of the PLAYPAL.
// Could be read from a lump instead.
//
//==============================================================================
procedure R_InitTranslationTables;
var
  i, j: integer;
  lump: integer;
begin
  translationtables := Z_Malloc(256 * 3 + 255, PU_STATIC, nil);
  translationtables := PByteArray((integer(translationtables) + 255 ) and (not 255));

  // translate just the 16 green colors
  for i := 0 to 255 do
    if (i >= $70) and (i <= $7f) then
    begin
      // map green ramp to gray, brown, red
      translationtables[i] := $60 + (i and $f);
      translationtables[i + 256] := $40 + (i and $f);
      translationtables[i + 512] := $20 + (i and $f);
    end
    else
    begin
      // Keep all other colors as is.
      translationtables[i] := i;
      translationtables[i + 256] := i;
      translationtables[i + 512] := i;
    end;

  // JVAL: Initialize ColorRegions
  lump := W_CheckNumForName('CR_START');
  for i := 0 to Ord(CR_LIMIT) - 1 do
    colorregions[i] := Z_Malloc(256, PU_STATIC, nil);
  if lump = -1 then
  begin
    printf(#13#10); // JVAL: keep stdout happy...
    I_Warning('Colormap extensions not found, using default translations'#13#10);
    for i := 0 to Ord(CR_LIMIT) - 1 do
      for j := 0 to 255 do
        colorregions[i][j] := j;
  end
  else
  begin
    for i := 0 to Ord(CR_LIMIT) - 1 do
    begin
      inc(lump);
      W_ReadLump(lump, colorregions[i]);
    end;
  end;

end;

//==============================================================================
//
// R_InitBuffer
// Creats lookup tables that avoid
//  multiplies and other hazzles
//  for getting the framebuffer address
//  of a pixel to draw.
//
//==============================================================================
procedure R_InitBuffer(width, height: integer);
var
  i: integer;
begin
  // Handle resize,
  //  e.g. smaller view windows
  //  with border and/or status bar.
  viewwindowx := (SCREENWIDTH - width) div 2;

  // Column offset. For windows.
  for i := 0 to width - 1 do
    columnofs[i] := viewwindowx + i;

  // Same with base row offset.
  if width = SCREENWIDTH then
  begin
    viewwindowy := 0;
  end
  else
  begin
  {$IFDEF OPENGL}
    viewwindowy := (trunc(ST_Y * SCREENHEIGHT / 200) - height) div 2;
  {$ELSE}
    viewwindowy := (V_PreserveY(ST_Y) - height) div 2;
  {$ENDIF}
  end;

{$IFNDEF OPENGL}
  // Preclaculate all row offsets.
  for i := 0 to height - 1 do
  begin
    ylookup[i] := PByteArray(integer(screens[SCN_FG]) + (i + viewwindowy) * SCREENWIDTH);
    ylookupl[i] := PLongWordArray(@screen32[(i + viewwindowy) * SCREENWIDTH]);
  end;
{$ENDIF}
end;

//==============================================================================
//
// R_ScreenBlanc
//
//==============================================================================
procedure R_ScreenBlanc(const scn: integer; const black: byte = 0);
var
  x, i: integer;
begin
  x := viewwindowy * SCREENWIDTH + viewwindowx;
  for i := 0 to viewheight - 1 do
  begin
    R_VideoBlanc(scn, x, scaledviewwidth, black);
    inc(x, SCREENWIDTH);
  end;
end;

//==============================================================================
//
// R_FillBackScreen
// Fills the back screen with a pattern
//  for variable screen sizes
// Also draws a beveled edge.
//
//==============================================================================
procedure R_FillBackScreen;
var
{$IFNDEF OPENGL}
  src: PByteArray;
  dest: PByteArray;
  x: integer;
  y: integer;
  patch: Ppatch_t;
  tviewwindowx: integer;
  tviewwindowy: integer;
  tviewheight: integer;
  tscaledviewwidth: integer;
{$ENDIF}
  name: string;
begin
  if scaledviewwidth = SCREENWIDTH then
    exit;

  name := menubackgroundflat;

{$IFDEF OPENGL}
  gld_DrawBackground(name);
{$ELSE}

  needsbackscreen := false;

  src := W_CacheLumpName(name, PU_STATIC);

  dest := screens[SCN_TMP];

  for y := 0 to 200 - ST_HEIGHT + 1 do
  begin
    for x := 0 to 320 div 64 - 1 do
    begin
      memcpy(dest, PByteArray(integer(src) + _SHL(y and 63, 6)), 64);
      dest := @dest[64];
    end;
    if 320 and 63 <> 0 then
    begin
      memcpy(dest, PByteArray(integer(src) + _SHL(y and 63, 6)), 320 and 63);
      dest := @dest[64];
    end;
  end;

  Z_ChangeTag(src, PU_CACHE);

  tviewwindowx := viewwindowx * 320 div SCREENWIDTH + 1;
  tviewwindowy := viewwindowy * 200 div SCREENHEIGHT + 1;
  tviewheight := viewheight * 200 div SCREENHEIGHT - 2;
  tscaledviewwidth := scaledviewwidth * 320 div SCREENWIDTH - 2;

  if brdr_t < 0 then
    brdr_t := W_GetNumForName('brdr_t');
  if brdr_b < 0 then
    brdr_b := W_GetNumForName('brdr_b');
  if brdr_l < 0 then
    brdr_l := W_GetNumForName('brdr_l');
  if brdr_r < 0 then
    brdr_r := W_GetNumForNAme('brdr_r');
  if brdr_tl < 0 then
    brdr_tl := W_GetNumForName('brdr_tl');
  if brdr_tr < 0 then
    brdr_tr := W_GetNumForName('brdr_tr');
  if brdr_bl < 0 then
    brdr_bl := W_GetNumForName('brdr_bl');
  if brdr_br < 0 then
    brdr_br := W_GetNumForName('brdr_br');

  patch := W_CacheLumpNum(brdr_t, PU_STATIC);
  x := 0;
  while x < tscaledviewwidth do
  begin
    V_DrawPatch(tviewwindowx + x - 4, tviewwindowy - 4, SCN_TMP, patch, false);
    x := x + 8;
  end;
  V_DrawPatch(tviewwindowx + tscaledviewwidth - 8, tviewwindowy - 4, SCN_TMP, patch, false);
  Z_ChangeTag(patch, PU_CACHE);

  patch := W_CacheLumpNum(brdr_b, PU_STATIC);
  x := 0;
  while x < tscaledviewwidth do
  begin
    V_DrawPatch(tviewwindowx + x - 4, tviewwindowy + tviewheight, SCN_TMP, patch, false);
    x := x + 8;
  end;
  V_DrawPatch(tviewwindowx + tscaledviewwidth - 8, tviewwindowy + tviewheight, SCN_TMP, patch, false);
  Z_ChangeTag(patch, PU_CACHE);

  patch := W_CacheLumpNum(brdr_l, PU_STATIC);
  y := 0;
  while y < tviewheight do
  begin
    V_DrawPatch(tviewwindowx - 4, tviewwindowy + y - 4, SCN_TMP, patch, false);
    y := y + 8;
  end;
  V_DrawPatch(tviewwindowx - 4, tviewwindowy + tviewheight - 8, SCN_TMP, patch, false);
  Z_ChangeTag(patch, PU_CACHE);

  patch := W_CacheLumpNum(brdr_r, PU_STATIC);
  y := 0;
  while y < tviewheight do
  begin
    V_DrawPatch(tviewwindowx + tscaledviewwidth, tviewwindowy + y - 4, SCN_TMP, patch, false);
    y := y + 8;
  end;
  V_DrawPatch(tviewwindowx + tscaledviewwidth, tviewwindowy + tviewheight - 8, SCN_TMP, patch, false);
  Z_ChangeTag(patch, PU_CACHE);

  // Draw beveled edge.
  V_DrawPatch(tviewwindowx - 4, tviewwindowy - 4, SCN_TMP,
    brdr_tl, false);

  V_DrawPatch(tviewwindowx + tscaledviewwidth, tviewwindowy - 4, SCN_TMP,
    brdr_tr, false);

  V_DrawPatch(tviewwindowx - 4, tviewwindowy + tviewheight, SCN_TMP,
    brdr_bl, false);

  V_DrawPatch(tviewwindowx + tscaledviewwidth, tviewwindowy + tviewheight, SCN_TMP,
    brdr_br, false);

  V_RemoveTransparency(SCN_TMP, 0, -1);
  V_CopyRect(0, 0, SCN_TMP, V_GetScreenWidth(SCN_TMP), V_GetScreenHeight(SCN_TMP), 0, 0, SCN_BG, true);

  R_ScreenBlanc(SCN_BG);
  x := V_PreserveY(ST_Y) * V_GetScreenWidth(SCN_BG); //SCREENWIDTH;
  R_VideoBlanc(SCN_BG, x, (V_GetScreenHeight(SCN_BG) - V_PreserveY(ST_Y)) * V_GetScreenWidth(SCN_BG));
{$ENDIF}
end;

//==============================================================================
// R_VideoErase
//
// Copy a screen buffer.
//
//==============================================================================
procedure R_VideoErase(const ofs: integer; const count: integer);
var
  i: integer;
  src: PByte;
  dest: PLongWord;
begin
  // LFB copy.
  // This might not be a good idea if memcpy
  //  is not optiomal, e.g. byte by byte on
  //  a 32bit CPU, as GNU GCC/Linux libc did
  //  at one point.
{$IFNDEF OPENGL}
  if videomode = vm32bit then
  begin
{$ENDIF}
    src := PByte(integer(screens[SCN_BG]) + ofs);
    dest := @screen32[ofs];
    for i := 1 to count do
    begin
      dest^ := videopal[src^];
      inc(dest);
      inc(src);
    end;
{$IFNDEF OPENGL}
  end
  else
    memcpy(Pointer(integer(screens[SCN_FG]) + ofs), Pointer(integer(screens[SCN_BG]) + ofs), count);
{$ENDIF}
end;

//==============================================================================
//
// R_VideoBlanc
//
//==============================================================================
procedure R_VideoBlanc(const scn: integer; const ofs: integer; const count: integer; const black: byte = 0);
var
  start: PByte;
  lstrart: PLongWord;
  i: integer;
  lblack: LongWord;
begin
  if {$IFNDEF OPENGL}(videomode = vm32bit) and{$ENDIF} (scn = SCN_FG) then
  begin
    lblack := curpal[black];
    lstrart := @screen32[ofs];
    for i := 0 to count - 1 do
    begin
      lstrart^ := lblack;
      inc(lstrart);
    end;
  end
  else
  begin
    start := @screens[scn][ofs];
    memset(start, black, count);
  end;
end;

//==============================================================================
//
// R_PlayerViewBlanc
//
//==============================================================================
procedure R_PlayerViewBlanc(const black: byte);
begin
  R_ScreenBlanc(SCN_FG, black);
end;

//==============================================================================
//
// R_DrawViewBorder
// Draws the border around the view
//  for different size windows?
//
//==============================================================================
procedure R_DrawViewBorder;
begin
  if scaledviewwidth < SCREENWIDTH then
    if (gamestate = GS_LEVEL) and (amstate <> am_only) then
      V_CopyScreenTransparent(SCN_BG, SCN_FG);
end;

var
  disklump: integer = -2;
  diskpatch: Ppatch_t = nil;

//==============================================================================
//
// R_DrawDiskBusy
//
//==============================================================================
procedure R_DrawDiskBusy;
begin
  {$IFDEF OPENGL}
  diskbusy_height := 0;
  {$ENDIF}
  if not displaydiskbusyicon then
    exit;

// Draw disk busy patch
  if disklump = -2 then
  begin
    if M_CheckParmCDROM then
      disklump := W_CheckNumForName('STCDROM');
    if disklump < 0 then
      disklump := W_CheckNumForName('STDISK');
    if disklump >= 0 then
      diskpatch := W_CacheLumpNum(disklump, PU_STATIC)
    else
    begin
      I_Warning('Disk busy lump not found!'#13#10);
      exit;
    end;
  end;

  if diskpatch <> nil then
    V_DrawPatch(318 - diskpatch.width, 2, SCN_FG,
      diskpatch, true);
  {$IFDEF OPENGL}
  if diskpatch <> nil then
    diskbusy_height := diskpatch.height + 3;
  {$ENDIF}
end;

end.
