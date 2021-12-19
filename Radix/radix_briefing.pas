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

unit radix_briefing;

interface

uses
  d_event;

function RB_Start(const epi, map: integer): Boolean;

procedure RB_Ticker;

procedure RB_Drawer;

procedure RB_Exit;

function RB_Responder(ev: Pevent_t): boolean;

var
  showbriefingscreen: Boolean = true;

implementation

uses
  d_delphi,
  doomdata,
  doomdef,
  d_main,
  d_player,
  g_game,
  m_fixed,
  mn_font,
  p_setup,
  sc_engine,
  radix_level,
  r_data,
  r_defs,
  r_draw,
  v_data,
  v_video,
  w_wad,
  z_zone;

type
  rbframedrawinfo_t = record
    curmappos: integer;
    targmappos: integer;
    mapscrollspeed: integer;
    curmsg: string;
    curanimtex: string;
    mapcreated: boolean;
    finished: boolean;
  end;
  Prbframedrawinfo_t = ^rbframedrawinfo_t;

const
  MAXBRIEFINGCOMMANDS = 512;

type
  cmdproc_t = function (const cmd: pointer): boolean;

  rbcommand_t = record
    cmd: cmdproc_t;
    sparam: string;
    iparams: array[0..4] of integer;
    tic: integer;
    active: boolean;
  end;
  Prbcommand_t = ^rbcommand_t;
  rbcommand_tArray = array[0..MAXBRIEFINGCOMMANDS] of rbcommand_t;
  Prbcommand_tArray = ^rbcommand_tArray;

var
  curdrawinfo: rbframedrawinfo_t;
  commands: rbcommand_tArray;
  numcommands: integer;
  acceleratestage: Boolean = false;

const
  MAPX = 100;
  MAPY = 4000;

var
  mapscreen: array[0..MAPY - 1] of array [0..MAPX - 1] of Byte;
  mapscale: int64;
  mapleft: fixed_t;
  maptop: fixed_t;
  mapwidth: fixed_t;
  mapheight: integer;

// --- Command procs
function RB_CmdClearAnimWindow(const cmd: Prbcommand_t): Boolean;
begin
  curdrawinfo.curanimtex := '';
  cmd.active := false;
  Result := True;
end;

function RB_CmdClearTextWindow(const cmd: Prbcommand_t): Boolean;
begin
  curdrawinfo.curmsg := '';
  cmd.active := false;
  Result := True;
end;

function RB_CmdDelay(const cmd: Prbcommand_t): Boolean;
begin
  if acceleratestage then
  begin
    cmd.tic := cmd.iparams[0];
    acceleratestage := False;
  end;

  if cmd.tic < cmd.iparams[0] then
    Inc(cmd.tic);
  cmd.active := cmd.tic < cmd.iparams[0];
  Result := not cmd.active;
end;

function RB_CmdDisplayAnimation(const cmd: Prbcommand_t): Boolean;
var
  nanims: integer;
  anim: string;
begin
  if cmd.iparams[2] = -1 then
  begin
    cmd.iparams[2] := 1;
    curdrawinfo.curanimtex := cmd.sparam;
  end;
  if cmd.tic < cmd.iparams[1] then
    Inc(cmd.tic, 3)
  else
  begin
    cmd.tic := 0;
    nanims := cmd.iparams[0];
    if nanims > 0 then
    begin
      if cmd.iparams[2] >= nanims then
        cmd.iparams[2] := 1
      else
        Inc(cmd.iparams[2]);
    end;
  end;
  anim := cmd.sparam;
  SetLength(anim, Length(anim) - 1);
  anim := anim + itoa(cmd.iparams[2]);
  curdrawinfo.curanimtex := anim;
  Result := True;
end;

function RB_CmdDisplayImage(const cmd: Prbcommand_t): Boolean;
begin
  curdrawinfo.curanimtex := cmd.sparam;
  cmd.active := True;
  Result := True;
end;

function RB_CmdPrint(const cmd: Prbcommand_t): Boolean;
begin
  if acceleratestage then
  begin
    cmd.tic := Length(cmd.sparam);
    curdrawinfo.curmsg := cmd.sparam;
    acceleratestage := False;
  end;
  if cmd.tic < Length(cmd.sparam) then
  begin
    Inc(cmd.tic);
    curdrawinfo.curmsg := curdrawinfo.curmsg + cmd.sparam[cmd.tic];
    cmd.active := True;
  end
  else
    cmd.active := False;
  Result := not cmd.active;
end;

function RB_CmdScrollMapX(const cmd: Prbcommand_t): Boolean;
begin
  curdrawinfo.targmappos := cmd.iparams[0];
  curdrawinfo.mapscrollspeed := Abs(curdrawinfo.curmappos - curdrawinfo.targmappos) div (2 * TICRATE);
  if curdrawinfo.mapscrollspeed > 256 then
    curdrawinfo.mapscrollspeed := 256;
  cmd.active := False;
  Result := True;
end;

function RB_CmdNextPoint(const cmd: Prbcommand_t): Boolean;
begin
  Result := True;
end;

function RB_CmdShowScreen(const cmd: Prbcommand_t): Boolean;
begin
  Result := True;
end;

function RB_CmdWaitAction(const cmd: Prbcommand_t): Boolean;
begin
  if acceleratestage then
  begin
    Result := True;
    acceleratestage := False;
    cmd.active := False;
  end
  else
    Result := False;
end;

// --- Map drawing
procedure RB_PointToRadix(const pl: Pline_t; const x, y: integer; var rx, ry: integer);
var
  sec: Psector_t;
begin
  sec := pl.frontsector;
  if sec = nil then
    sec := pl.backsector;
  rx := sec.radixmapXmult * (x div FRACUNIT - sec.radixmapXadd);
  ry := sec.radixmapYmult * (y div FRACUNIT - sec.radixmapYadd);
end;

function RB_RadixYToMapX(const x: integer): integer;
begin
  Result := MAPY - Trunc((x - mapleft) / mapscale * FRACUNIT) - 1;
end;

function RB_RadixXToMapY(const y: integer): integer;
begin
  Result := Trunc((y - maptop) / mapscale * FRACUNIT);
end;

procedure RB_PointToMap(const pl: Pline_t; const x, y: integer; var mx, my: integer);
var
  rx, ry: integer;
begin
  RB_PointToRadix(pl, x, y, rx, ry);
  mx := RB_RadixXToMapY(ry);
  my := RB_RadixYToMapX(rx);
end;

function RB_CmdPointMap(const cmd: Prbcommand_t): Boolean;
var
  x, y, i: integer;
  r, g, b, c: byte;
begin
  if curdrawinfo.mapcreated then
  begin
    y := RB_RadixYToMapX(cmd.iparams[0]);
    x := RB_RadixXToMapY(cmd.iparams[1]);
    r := cmd.iparams[2] * 4 + 2;
    g := cmd.iparams[3] * 4 + 2;
    b := cmd.iparams[4] * 4 + 2;
    c := V_FindAproxColorIndex(@curpal, b + g shl 8 + r shl 16, 1, 255);
    for i := -2 to 2 do
    begin
      mapscreen[y + i, x + i] := c;
      mapscreen[y + i, x - i] := c;
    end;
    cmd.active := False;
  end;
  Result := True;
end;

function RB_CmdMapPrint(const cmd: Prbcommand_t): Boolean;
var
  x, y, i, j, w, h: integer;
  src, dest: PByteArray;
begin
  if curdrawinfo.mapcreated then
  begin
    ZeroMemory(screens[SCN_ST], V_ScreensSize(SCN_ST));
    y := RB_RadixYToMapX(cmd.iparams[0]);
    x := RB_RadixXToMapY(cmd.iparams[1]);
    w := M_SmallStringWidthNarrow(cmd.sparam);
    h := M_SmallStringHeight(cmd.sparam);
    M_WriteSmallTextNarrow(x, 1, cmd.sparam, SCN_ST);
    for i := 0 to h + 1 do
    begin
      src := @screens[SCN_ST][i * V_GetScreenWidth(SCN_ST) + x - 1];
      dest := @mapscreen[ibetween(y + i, 0, MAPY - 1)][ibetween(x - 1, 0, MAPX - 1)];
      for j := 0 to w + 1 do
        dest[j] := src[j];
    end;
    cmd.active := False;
  end;
  Result := True;
end;

procedure RB_FindBoundaries;
var
  i: integer;
  rx, ry: integer;
  pl: Pline_t;
  min_x, min_y, max_x, max_y: integer;
  i64: int64;
begin
  min_x := MAXINT;
  min_y := MAXINT;
  max_x := -MAXINT;
  max_y := -MAXINT;

  pl := @lines[0];
  for i := 0 to numlines - 1 do
  begin
    if pl.flags and ML_AUTOMAPIGNOGE = 0 then
    begin
      RB_PointToRadix(pl, pl.v1.x, pl.v1.y, rx, ry);
      if rx < min_x then
        min_x := rx
      else if rx > max_x then
        max_x := rx;

      if ry < min_y then
        min_y := ry
      else if ry > max_y then
        max_y := ry;

      RB_PointToRadix(pl, pl.v2.x, pl.v2.y, rx, ry);
      if rx < min_x then
        min_x := rx
      else if rx > max_x then
        max_x := rx;

      if ry < min_y then
        min_y := ry
      else if ry > max_y then
        max_y := ry;
    end;

    Inc(pl);
  end;

  mapleft := min_x;
  maptop := min_y;
  mapwidth := max_x - min_x + 1;
  mapheight := max_y - min_y + 1;
  i64 := mapwidth;
  i64 := i64 * FRACUNIT div MAPY;
  mapscale := i64;
  i64 := mapheight;
  i64 := i64 * FRACUNIT div MAPX;
  if mapscale < i64 then
    mapscale := i64;
end;

procedure RB_DrawLine(const pl: Pline_t; const twosided: boolean);
var
  x1, y1, x2, y2: integer;
  x, y: integer;
  dx, dy: integer;
  sx, sy: integer;
  ax, ay: integer;
  d: integer;
  color: byte;
  sec, sec1, sec2: Psector_t;
begin
  if pl.flags and ML_AUTOMAPIGNOGE <> 0 then
    exit;

  sec := pl.frontsector;
  if sec = nil then
    sec := pl.backsector;
  if sec = nil then
    Exit; // ?

  if sec.radixflags and RSF_HIDDEN <> 0 then
    exit;

  if twosided and (pl.flags and ML_TWOSIDED <> 0) then
  begin
    color := aprox_lightblue;
    sec1 := pl.frontsector;
    sec2 := pl.backsector;
    if (sec1 <> nil) and (sec2 <> nil) then
      if (sec1.radixflags and RSF_HIDDEN <> 0) or (sec2.radixflags and RSF_HIDDEN <> 0) then
        color := aprox_red;
  end
  else if not twosided and (pl.flags and ML_TWOSIDED = 0) then
    color := aprox_red
  else
    exit;


  RB_PointToMap(pl, pl.v1.x, pl.v1.y, x1, y1);
  RB_PointToMap(pl, pl.v2.x, pl.v2.y, x2, y2);

  dx := x2 - x1;
  ax := 2 * abs(dx);
  if dx < 0 then
    sx := -1
  else
    sx := 1;

  dy := y2 - y1;
  ay := 2 * abs(dy);
  if dy < 0 then
    sy := -1
  else
    sy := 1;

  x := x1;
  y := y1;

  if ax > ay then
  begin
    d := ay - ax div 2;
    while true do
    begin
      mapscreen[ibetween(y, 0, MAPY - 1), ibetween(x, 0, MAPX - 1)] := color;
      if x = x2 then
        exit;
      if d >= 0 then
      begin
        y := y + sy;
        d := d - ax;
      end;
      x := x + sx;
      d := d + ay;
    end;
  end
  else
  begin
    d := ax - ay div 2;
    while true do
    begin
      mapscreen[ibetween(y, 0, MAPY - 1), ibetween(x, 0, MAPX - 1)] := color;
      if y = y2 then
        exit;
      if d >= 0 then
      begin
        x := x + sx;
        d := d - ay;
      end;
      y := y + sy;
      d := d + ax;
    end;
  end;
end;

procedure RB_DrawLines(const twosided: boolean);
var
  i: integer;
  pl: Pline_t;
begin
  pl := @lines[0];
  for i := 0 to numlines - 1 do
  begin
    RB_DrawLine(pl, twosided);
    inc(pl);
  end;
end;

procedure RB_CreateMap;
begin
  if curdrawinfo.mapcreated then
    exit;

  RB_FindBoundaries;

  ZeroMemory(@mapscreen, SizeOf(mapscreen));
  RB_DrawLines(True);   // Two-sided lines first
  RB_DrawLines(False);  // Single-sided lines

  curdrawinfo.mapcreated := True;
end;

procedure RB_DrawMap;
var
  dest: PByteArray;
  src: PByteArray;
  i, drow, srow: integer;
begin
  if not curdrawinfo.mapcreated then
    exit;

  for drow := 6 to 194 do
  begin
    srow := RB_RadixYToMapX(curdrawinfo.curmappos) + drow - 94;
    if IsIntegerInRange(srow, 0, MAPY - 1) then
    begin
      src := @mapscreen[srow][0];
      dest := @screens[SCN_TMP][drow * 320 + 9];
      for i := 0 to MAPX - 1 do
        if src[i] <> 0 then
          dest[i] := src[i];
    end;
  end;
end;

function RB_Start(const epi, map: integer): Boolean;
var
  utoken: string;
  sc: TScriptEngine;
  lumpname: string;
  stmp, s1, s2: string;
  sl: TDStringList;
  i, p: integer;
  cmd: Prbcommand_t;
  printparm: string;
begin
  acceleratestage := False;
  curdrawinfo.mapcreated := False;
  curdrawinfo.finished := False;
  curdrawinfo.curmappos := 0;
  curdrawinfo.targmappos := 0;
  curdrawinfo.mapscrollspeed := 128;
  curdrawinfo.curmsg := '';
  curdrawinfo.curanimtex := '';

  sl := TDStringList.Create;

  sprintf(lumpname, 'MissionBrief[%d][%d]', [epi, map]);

  sl.Text := W_TextLumpName(lumpname);

  for i := sl.Count - 1 downto 0 do
  begin
    stmp := strtrim(sl.Strings[i]);
    if (Pos(';', stmp) = 1) or (Pos('//', stmp) = 1) or (stmp = '') then
      sl.Delete(i)
    else
    begin
      p := Pos(':', stmp);
      if p > 0 then
        stmp[p] := ' ';
      splitstring(stmp, s1, s2);
      if (strupper(s1) = 'PRINT') or (strupper(s1) = 'PRINTLN') then
        if s2 = '' then
          stmp := s1 + ' "$"';
      sl.Strings[i] := stmp;
    end;
  end;

  if sl.Count = 0 then
  begin
    sl.Free;
    Result := False;
    Exit;
  end;

  sc := TScriptEngine.Create(sl.Text);

  sl.Free;

  ZeroMemory(@commands, SizeOf(commands));
  numcommands := 0;
  printparm := '';

  while sc.GetString do
  begin
    utoken := strupper(sc._String);
    cmd := @commands[numcommands];
    cmd.active := True;
    if utoken = 'CLEARANIMWINDOW' then
    begin
      cmd.cmd := @RB_CmdClearAnimWindow;
    end
    else if utoken = 'CLEARTEXTWINDOW' then
    begin
      cmd.cmd := @RB_CmdClearTextWindow;
    end
    else if utoken = 'DELAY' then
    begin
      cmd.cmd := @RB_CmdDelay;
      sc.MustGetInteger;
      cmd.iparams[0] := sc._Integer;
    end
    else if utoken = 'DISPLAYANIMATION' then
    begin
      cmd.cmd := @RB_CmdDisplayAnimation;
      sc.MustGetString;
      cmd.sparam := sc._String;
      for i := 0 to 2 do
      begin
        sc.MustGetInteger;
        cmd.iparams[i] := sc._Integer;
      end;
    end
    else if utoken = 'DISPLAYIMAGE' then
    begin
      cmd.cmd := @RB_CmdDisplayImage;
      sc.MustGetString;
      cmd.sparam := sc._String;
      for i := 0 to 1 do
      begin
        sc.MustGetInteger;
        cmd.iparams[i] := sc._Integer;
      end;
    end
    else if utoken = 'MAPPRINT' then
    begin
      cmd.cmd := @RB_CmdMapPrint;
      for i := 0 to 1 do
      begin
        sc.MustGetInteger;
        cmd.iparams[i] := sc._Integer;
      end;
      cmd.sparam := sc.GetStringEOL;
    end
    else if utoken = 'NEXTPOINT' then
    begin
      cmd.cmd := @RB_CmdNextPoint;
    end
    else if utoken = 'POINTMAP' then
    begin
      cmd.cmd := @RB_CmdPointMap;
      for i := 0 to 4 do
      begin
        sc.MustGetInteger;
        cmd.iparams[i] := sc._Integer;
      end;
    end
    else if (utoken = 'PRINT') or (utoken = 'PRINTLN') or (utoken = 'PRINTNAME') then
    begin
      while true do
      begin
        if utoken = 'PRINT' then
        begin
          stmp := sc.GetStringEOLUnChanged;
          if strtrim(stmp) = '"$"' then
            stmp := ''
          else
          begin
            for i := Length(stmp) downto 1 do
            begin
              if stmp[i] = '$' then
                stmp[i] := ' '
              else if stmp[i] = '''' then
                stmp[i] := '`';
            end;
          end;
          printparm := printparm + stmp;
        end
        else if utoken = 'PRINTLN' then
        begin
          stmp := sc.GetStringEOLUnChanged;
          if strtrim(stmp) = '"$"' then
            stmp := ''
          else
          begin
            for i := Length(stmp) downto 1 do
            begin
              if stmp[i] = '$' then
                stmp[i] := ' '
              else if stmp[i] = '''' then
                stmp[i] := '`';
            end;
          end;
          printparm := printparm + stmp + #13#10;
        end
        else if utoken = 'PRINTNAME' then
          printparm := printparm + pilotname
        else
        begin
          sc.UnGet;
          Break;
        end;
        if not sc.GetString then
          Break
        else
          utoken := strupper(sc._String);
      end;
    end
    else if utoken = 'SCROLLMAPX' then
    begin
      cmd.cmd := @RB_CmdScrollMapX;
      sc.MustGetInteger;
      cmd.iparams[0] := sc._Integer;
    end
    else if utoken = 'SHOWSCREEN' then
    begin
      cmd.cmd := @RB_CmdShowScreen;
    end
    else if utoken = 'WAITACTION' then
    begin
      cmd.cmd := @RB_CmdWaitAction;
    end;

    if printparm <> '' then
    begin
      cmd.cmd := @RB_CmdPrint;
      cmd.sparam := printparm;
      printparm := '';
    end;

    if Assigned(cmd.cmd) then
      Inc(numcommands);
  end;

  sc.Free;

  Result := numcommands > 0;
end;

procedure RB_Ticker;
const
  SCROLLBRAKEDIST = 1024;
  SCROLLSPEEDMIN = 16;
var
  i: integer;
  player: Pplayer_t;
  scrollspeed: integer;
begin
  if curdrawinfo.finished then
    exit;

  RB_CreateMap;

  // check for button presses to skip delays
  for i := 0 to MAXPLAYERS - 1 do
  begin
    player := @players[i];

    if playeringame[i] then
    begin

      if player.cmd.buttons and BT_ATTACK <> 0 then
      begin
        if not player.attackdown then
          acceleratestage := True;
        player.attackdown := True;
      end
      else
        player.attackdown := False;

      if player.cmd.buttons and BT_USE <> 0 then
      begin
        if not player.usedown then
          acceleratestage := True;
        player.usedown := True;
      end
      else
        player.usedown := False;
    end;
  end;

  scrollspeed := curdrawinfo.mapscrollspeed;
  if curdrawinfo.curmappos > curdrawinfo.targmappos then
  begin
    if curdrawinfo.curmappos - curdrawinfo.targmappos < SCROLLBRAKEDIST then
    begin
      scrollspeed := scrollspeed * (curdrawinfo.curmappos - curdrawinfo.targmappos) div SCROLLBRAKEDIST;
      if scrollspeed < SCROLLSPEEDMIN then
        scrollspeed := SCROLLSPEEDMIN;
    end;
    curdrawinfo.curmappos := curdrawinfo.curmappos - scrollspeed;
    if curdrawinfo.curmappos < curdrawinfo.targmappos then
      curdrawinfo.curmappos := curdrawinfo.targmappos;
  end
  else if curdrawinfo.curmappos < curdrawinfo.targmappos then
  begin
    if curdrawinfo.targmappos - curdrawinfo.curmappos < SCROLLBRAKEDIST then
    begin
      scrollspeed := scrollspeed * (curdrawinfo.targmappos - curdrawinfo.curmappos) div SCROLLBRAKEDIST;
      if scrollspeed < SCROLLSPEEDMIN then
        scrollspeed := SCROLLSPEEDMIN;
    end;
    curdrawinfo.curmappos := curdrawinfo.curmappos + scrollspeed;
    if curdrawinfo.curmappos > curdrawinfo.targmappos then
      curdrawinfo.curmappos := curdrawinfo.targmappos;
  end;

  for i := 0 to numcommands - 1 do
    if commands[i].active then
      if not commands[i].cmd(@commands[i]) then
        Exit;

  curdrawinfo.finished := True;
end;

procedure RB_DrawFrame(const bx, by, bw, bh: integer);
var
  p: Ppatch_t;
  x, y, pix: Integer;
  cmap: PByteArray;
begin
  cmap := @def_colormaps[(NUMCOLORMAPS div 2) * 256];
  for y := by to by + bh do
    for x := bx to bx + bw do
    begin
      pix := y * 320 + x;
      screens[SCN_TMP][pix] := cmap[screens[SCN_TMP][pix]];
    end;

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

  p := W_CacheLumpNum(brdr_t, PU_STATIC);
  x := bx;
  y := by;
  while x < bx + bw do
  begin
    if x + p.width > bx + bw then
      x := bx + bw - p.width;
    V_DrawPatch(x, y, SCN_TMP, p, false);
    x := x + 8;
  end;
  Z_ChangeTag(p, PU_CACHE);

  p := W_CacheLumpNum(brdr_b, PU_STATIC);
  x := bx;
  y := by + bh;
  while x < bx + bw do
  begin
    if x + p.width > bx + bw then
      x := bx + bw - p.width;
    V_DrawPatch(x, y, SCN_TMP, p, false);
    x := x + 8;
  end;
  Z_ChangeTag(p, PU_CACHE);

  p := W_CacheLumpNum(brdr_l, PU_STATIC);
  x := bx;
  y := by;
  while y < by + bh do
  begin
    if y + p.height > by + bh then
      y := by + bh - p.height;
    V_DrawPatch(x, y, SCN_TMP, p, false);
    y := y + 8;
  end;
  Z_ChangeTag(p, PU_CACHE);

  p := W_CacheLumpNum(brdr_r, PU_STATIC);
  x := bx + bw;
  y := by;
  while y < by + bh do
  begin
    if y + p.height > by + bh then
      y := by + bh - p.height;
    V_DrawPatch(x, y, SCN_TMP, p, false);
    y := y + 8;
  end;
  Z_ChangeTag(p, PU_CACHE);

  // Draw beveled edge.
  V_DrawPatch(bx, by, SCN_TMP, brdr_tl, false);

  V_DrawPatch(bx + bw, y, SCN_TMP, brdr_tr, false);

  V_DrawPatch(bx, by + bh, SCN_TMP, brdr_bl, false);

  V_DrawPatch(bx + bw, by + bh, SCN_TMP, brdr_br, false);
end;

procedure RB_Drawer;
var
  p: Ppatch_t;
begin
  V_DrawPatchFullScreenTMP320x200('BACKIMG');

  RB_DrawFrame(2, 2, 110, 193);
  RB_DrawMap;
  RB_DrawFrame(136, 2, 170, 84);
  RB_DrawFrame(136, 103, 170, 84);
  M_WriteSmallTextNarrow(140, 109, curdrawinfo.curmsg, SCN_TMP);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);

  if curdrawinfo.curanimtex <> '' then
  begin
    ZeroMemory(screens[SCN_TMP640], V_ScreensSize(SCN_TMP640));
    p := W_CacheLumpName(curdrawinfo.curanimtex, PU_LEVEL);
    V_DrawPatch(448, 88 + p.topoffset - p.height div 2, SCN_TMP640, p, false);
    V_CopyRectTransparent(0, 0, SCN_TMP640, 640, 400, 0, 0, SCN_FG, True);
  end;

  V_FullScreenStretch;
end;

procedure RB_Exit;
begin
  wipegamestate := -1;
  gamestate := GS_LEVEL;
end;

function RB_Responder(ev: Pevent_t): boolean;
begin
  if ev._type <> ev_keydown then
  begin
    Result := False;
    exit;
  end;

  if curdrawinfo.finished then
  begin
    wipegamestate := -1;
    gamestate := GS_LEVEL;
    Result := True;
    exit;
  end;
  Result := False;
end;

end.
