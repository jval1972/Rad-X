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

var
  showbriefingscreen: Boolean = true;

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  g_game,
  m_fixed,
  mn_font,
  sc_engine,
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
    curmsg: string;
    curanimtex: string;
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
    Inc(cmd.tic)
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
  cmd.active := False;
  Result := True;
end;

function RB_CmdMapPrint(const cmd: Prbcommand_t): Boolean;
begin
  Result := True;
end;

function RB_CmdNextPoint(const cmd: Prbcommand_t): Boolean;
begin
  Result := True;
end;

function RB_CmdPointMap(const cmd: Prbcommand_t): Boolean;
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
              if stmp[i] = '$' then
                stmp[i] := ' ';
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
              if stmp[i] = '$' then
                stmp[i] := ' ';
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

  acceleratestage := false;

  Result := numcommands > 0;
end;

procedure RB_Ticker;
var
  i: integer;
  player: Pplayer_t;
begin
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

  for i := 0 to numcommands - 1 do
    if commands[i].active then
      if not commands[i].cmd(@commands[i]) then
        Exit;

  gamestate := GS_LEVEL;
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
  RB_DrawFrame(136, 2, 170, 88);
  RB_DrawFrame(136, 107, 170, 88);
  M_WriteSmallTextNarrow(140, 113, curdrawinfo.curmsg, SCN_TMP);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);

  if curdrawinfo.curanimtex <> '' then
  begin
    ZeroMemory(screens[SCN_TMP640], 640 * 400);
    p := W_CacheLumpName(curdrawinfo.curanimtex, PU_LEVEL);
    V_DrawPatch(448, 92 + p.topoffset - p.height div 2, SCN_TMP640, p, false);
    V_CopyRectTransparent(0, 0, SCN_TMP640, 640, 400, 0, 0, SCN_FG, True);
  end;

  V_FullScreenStretch;
end;

end.
