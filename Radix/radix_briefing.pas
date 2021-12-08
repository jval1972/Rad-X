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

function RB_Start(const epi, map: integer): Boolean;

implementation

uses
  d_delphi,
  d_player,
  sc_engine,
  w_wad;

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
  cmdproc_t = procedure (const cmd: pointer);

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

// --- Command procs
procedure RB_CmdClearAnimWindow(const cmd: Prbcommand_t);
begin
  curdrawinfo.curanimtex := '';
  cmd.active := false;
end;

procedure RB_CmdClearTextWindow(const cmd: Prbcommand_t);
begin
  curdrawinfo.curmsg := '';
  cmd.active := false;
end;

procedure RB_CmdDelay(const cmd: Prbcommand_t);
begin
  if cmd.tic < cmd.iparams[0] then
    Inc(cmd.tic);
  cmd.active := cmd.tic < cmd.iparams[0];
end;

procedure RB_CmdDisplayAnimation(const cmd: Prbcommand_t);
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
    anim := cmd.sparam;
    if nanims > 0 then
    begin
      if cmd.iparams[2] >= nanims then
        cmd.iparams[2] := 1
      else
        Inc(cmd.iparams[2]);
      SetLength(anim, Length(anim) - 1);
      anim := anim + itoa(cmd.iparams[2]);
      curdrawinfo.curanimtex := anim;
    end;
  end;
end;

procedure RB_CmdDisplayImage(const cmd: Prbcommand_t);
begin
  curdrawinfo.curanimtex := cmd.sparam;
  cmd.active := False;
end;

procedure RB_CmdPrint(const cmd: Prbcommand_t);
begin
  if cmd.tic < Length(cmd.sparam) then
  begin
    Inc(cmd.tic);
    curdrawinfo.curmsg := curdrawinfo.curmsg + cmd.sparam[cmd.tic];
    cmd.active := True;
  end
  else
    cmd.active := False;
end;

procedure RB_CmdScrollMapX(const cmd: Prbcommand_t);
begin
  curdrawinfo.targmappos := cmd.iparams[0];
  cmd.active := False;
end;

procedure RB_CmdMapPrint(const cmd: Prbcommand_t);
begin

end;

procedure RB_CmdNextPoint(const cmd: Prbcommand_t);
begin

end;

procedure RB_CmdPointMap(const cmd: Prbcommand_t);
begin

end;

procedure RB_CmdShowScreen(const cmd: Prbcommand_t);
begin

end;

procedure RB_CmdWaitAction(const cmd: Prbcommand_t);
begin

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
      for i := 0 to 2 do
      begin
        sc.MustGetInteger;
        cmd.iparams[i] := sc._Integer;
      end;
    end
    else if utoken = 'DISPLAYIMAGE' then
    begin
      cmd.cmd := @RB_CmdDisplayImage;
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
      sc.MustGetString;
      cmd.sparam := sc._String;
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
                Delete(stmp, i, 1);
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
                Delete(stmp, i, 1);
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

end.
