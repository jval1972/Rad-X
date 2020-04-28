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
//    Radix Intermission screen.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_intermission;

interface

// Called by main loop
procedure RX_Intermission_Ticker;

// Called by main loop,
// draws the intermission directly into the screen buffer.
procedure RX_Intermission_Drawer;

// Setup for an intermission screen.
procedure RX_Intermission_Start;

implementation

uses
  d_delphi,
  doomdef,
  m_fixed,
  d_player,
  d_event,
  g_game,
  mn_font,
  s_sound,
  sound_data,
  radix_score,
  v_data,
  v_video;

var
  in_tic: integer;
  in_struct: Pwbstartstruct_t;

procedure RX_CheckForInput;
var
  i: integer;
  player: Pplayer_t;
begin
  // check for button presses to skip delays
  for i := 0 to MAXPLAYERS - 1 do
  begin
    player := @players[i];

    if playeringame[i] then
      if (player.cmd.buttons and BT_ATTACK <> 0) or (player.cmd.buttons and BT_USE <> 0) then
        G_WorldDone;
  end;
end;

// Updates stuff each tick
procedure RX_Intermission_Ticker;
begin
  inc(in_tic);

  if in_tic = 1 then
  begin
    // intermission music
    S_ChangeMusic(Ord(mus_intro), true);
  end;

  RX_CheckForInput;
end;

function RX_TimeToString(const secs: integer): string;
var
  t: integer;
begin
  t := secs;
  result := IntToStrzFill(2, t div 3600); // Hours
  t := t mod 3600;
  result := result + ':' + IntToStrzFill(2, t div 60); // Minutes
  t := t mod 60;
  result := result + ':' + IntToStrzFill(2, t); // Seconds
end;

function RX_FracPercentToSring(const pctfrac: fixed_t): string;
begin
  sprintf(result, '%d', [(pctfrac * 100) div FRACUNIT]);
  while length(result) < 3 do
    result := ' ' + result;
end;

procedure RX_StorePlayerScore;
var
  score: Pplayerscore_t;
begin
  score := @players[consoleplayer].currentscore;
  score.episode := gameepisode;
  score.map := in_struct.last + 1;

  if not in_struct.hassecondaryobjective then
    score.secondary_pct := FRACUNIT
  else if in_struct.plyr[consoleplayer].secondaryobjective then
    score.secondary_pct := FRACUNIT
  else
    score.secondary_pct := 0;

  if in_struct.maxkills = 0 then
    score.killratio_pct := FRACUNIT
  else
    score.killratio_pct := (in_struct.plyr[consoleplayer].skills * FRACUNIT) div in_struct.maxkills;

  if (in_struct.plyr[consoleplayer].stime <= in_struct.partime) or (in_struct.plyr[consoleplayer].stime = 0) then
    score.flyingtime_pct := FRACUNIT
  else
    score.flyingtime_pct := (in_struct.partime * FRACUNIT) div in_struct.plyr[consoleplayer].stime;

  if in_struct.maxsecret = 0 then
    score.secrets_pct := FRACUNIT
  else
    score.secrets_pct := (in_struct.plyr[consoleplayer].ssecret * FRACUNIT) div in_struct.maxsecret;

  if (in_struct.plyr[consoleplayer].wallhits = 0) or (in_struct.partime div TICRATE = 0) then
    score.proficientflying_pct := FRACUNIT
  else
  begin
    score.proficientflying_pct := FRACUNIT - (in_struct.plyr[consoleplayer].wallhits div (in_struct.partime div TICRATE)) * FRACUNIT;
    if score.proficientflying_pct < 0 then
      score.proficientflying_pct := 0;
  end;

  if IsIntegerInRange(score.episode, 1, 3) then
    if IsIntegerInRange(score.map, 1, 9) then
      players[consoleplayer].scores[score.episode, score.map] := score^;

  if not netgame then
    if not demoplayback then
      RX_UpdateScoreTable(@players[consoleplayer], gameepisode, in_struct.last + 1, gameskill);
end;

procedure RX_Intermission_Drawer;
var
  backscreen: string;
  skillplace: integer;
  sobj: string;
  meanscore: fixed_t;
begin
  sprintf(backscreen, 'DebriefScreen%d', [gameepisode]);
  V_DrawPatchFullScreenTMP320x200(backscreen);

  M_WriteSmallTextCenter(30, 'MISSION ' + itoa(in_struct.last + 1) + ' COMPLETED', SCN_TMP);

  M_WriteSmallTextCenter(52, 'AT YOUR CURRENT SKILL RATING', SCN_TMP);

  skillplace := RX_QueryPlayerScorePosition(@players[consoleplayer].currentscore);

  if IsIntegerInRange(skillplace, 1, NUMSCORES) then
    M_WriteSmallTextCenter(60, 'YOU WILL ACHIEVE ' + SCOREPOSITIONTEXT[skillplace] + ' PLACE IN THE TOP TEN', SCN_TMP)
  else
    M_WriteSmallTextCenter(60, 'YOU WILL NOT ACHIEVE A PLACE IN THE TOP TEN', SCN_TMP);

  meanscore := (players[consoleplayer].currentscore.secondary_pct +
                players[consoleplayer].currentscore.killratio_pct +
                players[consoleplayer].currentscore.flyingtime_pct +
                players[consoleplayer].currentscore.secrets_pct +
                players[consoleplayer].currentscore.proficientflying_pct) div 5;
  M_WriteSmallText(121, 71, RX_FracPercentToSring(meanscore), SCN_TMP);
  if in_struct.hassecondaryobjective then
  begin
    if in_struct.plyr[consoleplayer].secondaryobjective then
      sobj := 'COMPLETE'
    else
      sobj := 'INCOMPLETE';
  end
  else
    sobj := 'NOT APPLICABLE';
  M_WriteSmallText(157, 81, sobj, SCN_TMP);

  M_WriteSmallText(108, 91, IntToStrBfill(3, in_struct.plyr[consoleplayer].skills), SCN_TMP);
  M_WriteSmallText(130, 91, itoa(in_struct.maxkills), SCN_TMP);

  M_WriteSmallText(144, 101, RX_FracPercentToSring(players[consoleplayer].currentscore.proficientflying_pct), SCN_TMP);
  M_WriteSmallText(114, 111, RX_TimeToString(in_struct.plyr[consoleplayer].stime div TICRATE), SCN_TMP);
  M_WriteSmallText(101, 121, RX_TimeToString(in_struct.partime div TICRATE), SCN_TMP);

  M_WriteSmallTextCenter(131, 'YOU HAVE FOUND ' + itoa(in_struct.plyr[consoleplayer].ssecret) + ' OF ' + itoa(in_struct.maxsecret) + ' SECRET AREAS', SCN_TMP);

  V_CopyRect(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);

  V_FullScreenStretch;
end;

procedure RX_Intermission_Start;
begin
  in_struct := @wminfo;
  RX_StorePlayerScore;
end;

end.
