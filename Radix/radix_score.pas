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
//    Radix Score Tables
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_score;

interface

uses
  doomdef,
  d_player,
  m_sha1;

type
  scrotetableitem_t = packed record
    name: string[PILOTNAMESIZE];
    episode: integer;
    map: integer;
    skill: skill_t;
    rating: integer;
    sha1: string[SizeOf(T160BitDigest)];
  end;
  Pscrotetableitem_t = ^scrotetableitem_t;

const
  NUMSCORES = 10;

const
  SCOREPOSITIONTEXT: array[1..NUMSCORES] of string[4] = (
    '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th');

type
  scoretable_t = packed array[0..NUMSCORES - 1] of scrotetableitem_t;

function RX_QueryPlayerScorePosition(const psc: Pplayerscore_t): integer;

procedure RX_UpdateScoreTable(const p: Pplayer_t; const epi, map: integer; skill: skill_t);

procedure RX_LoadScoreTable;

procedure RX_SaveScoreTable;

function RX_GetScoreTableId(const id: integer): Pscrotetableitem_t;

implementation

uses
  d_delphi,
  i_system,
  m_base,
  m_argv;

var
  scoretable: scoretable_t;

function RX_CalculatePlayerSingleScore(const psc: Pplayerscore_t): integer;
begin
  result :=
    psc.secondary_pct +
    psc.secondary_pct +
    psc.killratio_pct +
    psc.flyingtime_pct +
    psc.secrets_pct +
    psc.proficientflying_pct;
end;

procedure RX_SortScoreTable;
var
  i, j: integer;
  item: scrotetableitem_t;
begin
  for i := 0 to NUMSCORES - 1 do
    for j := 0 to NUMSCORES - 1 - i do
      if scoretable[j].rating < scoretable[j + 1].rating then
      begin
        item := scoretable[j];
        scoretable[j] := scoretable[j + 1];
        scoretable[j + 1] := item;
      end;
end;

function RX_QueryPlayerScorePosition(const psc: Pplayerscore_t): integer;
var
  score: integer;
  x: integer;
begin
  RX_SortScoreTable;
  score := RX_CalculatePlayerSingleScore(@psc) * 9;
  for x := 0 to NUMSCORES - 1 do
    if score > scoretable[x].rating then
    begin
      result := x + 1;
      exit;
    end;
  result := NUMSCORES + 1;
end;

procedure RX_CalcScoreSha1(const x: integer);
var
  s: AnsiString;
begin
  s := SHA1_CalcSHA1Buf(scoretable[x], SizeOf(scrotetableitem_t) - SizeOf(T160BitDigest));
  scoretable[x].sha1 := s;
end;

procedure RX_CheckScoreSha1(const x: integer);
var
  s: AnsiString;
begin
  s := SHA1_CalcSHA1Buf(scoretable[x], SizeOf(scrotetableitem_t) - SizeOf(T160BitDigest));
  if scoretable[x].sha1 <> s then
  begin
    I_Warning('RX_CheckScoreSha1(): Score table #%d failed validation, score of player "%s" deleted'#13#10, [x, scoretable[x].name]);
    ZeroMemory(@scoretable[x], SizeOf(scrotetableitem_t) - SizeOf(T160BitDigest));
    RX_CalcScoreSha1(x);
  end;
end;

procedure RX_UpdateScoreTable(const p: Pplayer_t; const epi, map: integer; skill: skill_t);
var
  totalscore: integer;
  scorepos: integer;
  x: integer;
begin
  totalscore := 0;
  for x := 1 to 9 do
    totalscore := totalscore + RX_CalculatePlayerSingleScore(@p.scores[epi, x]);

  RX_SortScoreTable;
  scorepos := NUMSCORES + 1;
  for x := 0 to NUMSCORES - 1 do
    if totalscore > scoretable[x].rating then
    begin
      scorepos := x + 1;
      break;
    end;
  if IsIntegerInRange(scorepos, 1, NUMSCORES) then
  begin
    printf('RX_UpdateScoreTable(): Player "%s", achieved %s position in score table.'#13#10, [p.playername, SCOREPOSITIONTEXT[scorepos]]);
    scoretable[NUMSCORES - 1].name := p.playername;
    scoretable[NUMSCORES - 1].episode := epi;
    scoretable[NUMSCORES - 1].map := map;
    scoretable[NUMSCORES - 1].skill := skill;
    scoretable[NUMSCORES - 1].rating := totalscore;
    RX_CalcScoreSha1(NUMSCORES - 1);
    RX_SortScoreTable;
    RX_SaveScoreTable;
  end;
end;

procedure RX_LoadScoreTable;
var
  fname: string;
  handle: file;
  size: integer;
  count: integer;
  x: integer;
begin
  ZeroMemory(@scoretable, SizeOf(scoretable_t));
  for x := 0 to NUMSCORES - 1 do
    RX_CalcScoreSha1(x);
  fname := M_SaveFileName(APPNAME + '.sco');
  if fexists(fname) then
  begin
    if not fopen(handle, fname, fOpenReadOnly) then
      I_Warning('RX_LoadScoreTable(): Could not read file %s for input'#13#10, [fname])
    else
    begin
      size := FileSize(handle);
      if size <> SizeOf(scoretable_t) then
        I_Warning('RX_LoadScoreTable(): Invalid score table file %s'#13#10, [fname])
      else
      begin
        BlockRead(handle, scoretable, size, count);
        if count <> size then
        begin
          I_Warning('RX_LoadScoreTable(): Read %d bytes instead of %d bytes'#13#10, [count, size]);
          ZeroMemory(@scoretable, SizeOf(scoretable_t));
          for x := 0 to NUMSCORES - 1 do
            RX_CalcScoreSha1(x);
        end
        else
        begin
          for x := 0 to NUMSCORES - 1 do
            RX_CheckScoreSha1(x);
          RX_SortScoreTable;
        end;
      end;
      close(handle);
    end;
  end;
end;

procedure RX_SaveScoreTable;
var
  fname: string;
  handle: file;
  size: integer;
  count: integer;
  x: integer;
begin
  fname := M_SaveFileName(APPNAME + '.sco');
  if not fopen(handle, fname, fCreate) then
    I_Warning('RX_SaveScoreTable(): Could not open file %s for output'#13#10, [fname])
  else
  begin
    size := SizeOf(scoretable_t);
    RX_SortScoreTable;
    for x := 0 to NUMSCORES - 1 do
      RX_CalcScoreSha1(x);
    BlockWrite(handle, scoretable, size, count);
    if count <> size then
      I_Warning('RX_SaveScoreTable(): Wrote %d bytes instead of %d bytes'#13#10, [count, size]);
    close(handle);
  end;
end;

function RX_GetScoreTableId(const id: integer): Pscrotetableitem_t;
begin
  if IsIntegerInRange(id, 0, NUMSCORES - 1) then
    result := @scoretable[id]
  else
    result := nil;
end;

end.
