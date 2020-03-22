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
// DESCRIPTION:
//    Head up display
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit hu_stuff;

interface

uses
  doomdef,
  d_event,
  r_defs;

const
//
// Globally visible constants.
//
  HU_FONTSTART = '!'; // the first font characters
  HU_FONTEND = 'z'; // the last font characters

// Calculate # of glyphs in font.
  HU_FONTSIZE = (Ord(HU_FONTEND) - Ord(HU_FONTSTART)) + 1;

  DOS_FONTSTART = '!'; // the first dos font characters
  DOS_FONTEND = #128; // the last dos font characters

// Calculate # of glyphs in font.
  DOS_FONTSIZE = (Ord(DOS_FONTEND) - Ord(DOS_FONTSTART)) + 1;

  BIG_FONTSTART = '!'; // the first dos font characters
  BIG_FONTEND = #128; // the last dos font characters

  BIG_FONTSIZE = (Ord(BIG_FONTEND) - Ord(BIG_FONTSTART)) + 1;

  HU_BROADCAST = 5;

  HU_MSGREFRESH = KEY_ENTER;
  HU_MSGX = 0;
  HU_MSGY = 0;
  HU_MSGHEIGHT = 1; // in lines

  HU_MSGTIMEOUT = 4 * TICRATE;

//
// HEADS UP TEXT
//
procedure HU_Init;

procedure HU_Start;

function HU_Responder(ev: Pevent_t): boolean;

procedure HU_Ticker;

procedure HU_Drawer;

{$IFDEF OPENGL}
function HU_Height: integer;
{$ENDIF}

function HU_dequeueChatChar: char;

procedure HU_Erase;

var
  hu_font: array[0..HU_FONTSIZE - 1] of Ppatch_t;

  dos_fontA: array[0..DOS_FONTSIZE - 1] of Ppatch_t;
  dos_fontB: array[0..DOS_FONTSIZE - 1] of Ppatch_t;

  big_fontA: array[0..DOS_FONTSIZE - 1] of Ppatch_t;
  big_fontB: array[0..DOS_FONTSIZE - 1] of Ppatch_t;
  big_fontC: array[0..DOS_FONTSIZE - 1] of Ppatch_t;

  chat_on: boolean;

  message_on: boolean;
  message_dontfuckwithme: boolean;
  message_nottobefuckedwith: boolean;

var
// DOOM shareware/registered/retail (Ultimate) names.
  mapnames: array[0..44] of string;

  player_names: array[0..3] of string;

var
  chat_macros: array[0..9] of string;

var
  destination_keys: array[0..MAXPLAYERS - 1] of string;
    
var
  shiftxform: array[0..127] of char;

procedure HU_DoFPSStuff;

function HU_FPS: integer;

var
  drawfps: boolean;

implementation

uses
  d_delphi,
  c_cmds,
  z_zone,
  w_wad,
  i_system,
  doomstat,
  am_map,
  dstrings,
  d_englsh,
  d_player,
  g_game,
  hu_lib,
  m_menu,
  m_fixed,
  p_tick,
  r_draw,
  s_sound,
  sound_data,
  sounds,
  v_data,
  v_video;

// FPS Stuff

const
  FPSSIZE = 128;
  FPSSIZE2 = 512;

var
  FPSHISTORY: array[0..FPSSIZE - 1] of integer;
  FPSHISTORY2: array[0..FPSSIZE2 - 1] of integer;
  fpshead: integer = -1;
  fpshead2: integer = -1;

procedure HU_DoFPSStuff;
var
  ftime: integer;
begin
  ftime := I_GetFracTime;
  fpshead := (fpshead + 1) mod FPSSIZE;
  FPSHISTORY[fpshead] := ftime;
  fpshead2 := (fpshead2 + 1) mod FPSSIZE2;
  FPSHISTORY2[fpshead2] := ftime;
end;

function HU_FPS: integer;
var
  fpsdiff: integer;
begin
  fpsdiff := FPSHISTORY[fpshead] - FPSHISTORY[(fpshead + 1) mod FPSSIZE] + 1;
  if fpsdiff > 0 then
  begin
    result :=  TICRATE * FPSSIZE * FRACUNIT div fpsdiff;
    if result > FPSSIZE then
    begin
      fpsdiff := FPSHISTORY2[fpshead2] - FPSHISTORY2[(fpshead2 + 1) mod FPSSIZE2] + 1;
      if fpsdiff > 0 then
        result :=  TICRATE * FPSSIZE2 * FRACUNIT div fpsdiff;
    end;
  end
  else
    result := TICRATE;
end;

procedure HU_CmdFPS;
begin
  printf('%d fps'#13#10, [HU_FPS]);
end;

procedure HU_CmdPlayerMessage(const parm1, parm2: string);
begin
  players[consoleplayer]._message := parm1 + ' ' + parm2;
end;

function HU_TITLE: string;
begin
  result := mapnames[(gameepisode - 1) * 9 + gamemap - 1];
end;

var
  plr: Pplayer_t;
  w_title: hu_textline_t;
  w_leveltime: hu_textline_t;
  w_chat: hu_itext_t;
  always_off: boolean = false;
  chat_dest: array[0..MAXPLAYERS - 1] of char;
  w_inputbuffer: array[0..MAXPLAYERS - 1] of hu_itext_t;

  w_message: hu_stext_t;
  message_counter: integer;

  headsupactive: boolean = false;


const
  HU_TITLEHEIGHT = 1;
  HU_TITLEX = 0;
  HU_LEVELTIMEX = 0;

function HU_TITLEY: integer;
begin
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 158 div 200{$ELSE}158{$ENDIF} - hu_font[0].height;
end;

function HU_LEVELTIMEY: integer;
begin
  result := {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG) * 158 div 200{$ELSE}158{$ENDIF} - 2 * hu_font[0].height - 3;
end;

const
  HU_INPUTTOGGLE: char = 't';

function HU_INPUTX: integer;
begin
  result := HU_MSGX;
end;

function HU_INPUTY: integer;
begin
  result := HU_MSGY + HU_MSGHEIGHT * (hu_font[0].height + 1)
end;

const
  HU_INPUTWIDTH = 64;
  HU_INPUTHEIGHT = 1;

const
  french_shiftxform: array[0..127] of char = (
    #0,
    #1, #2, #3, #4, #5, #6, #7, #8, #9, #10,
    #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
    #21, #22, #23, #24, #25, #26, #27, #28, #29, #30,
    #31,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', // shift-'
    '(', ')', '*', '+',
    '?', // shift-,
    '_', // shift--
    '>', // shift-.
    '?', // shift-/
    '0', // shift-0
    '1', // shift-1
    '2', // shift-2
    '3', // shift-3
    '4', // shift-4
    '5', // shift-5
    '6', // shift-6
    '7', // shift-7
    '8', // shift-8
    '9', // shift-9
    '/',
    '.', // shift-;
    '<',
    '+', // shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', // shift-[
    '!', // shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', // shift-]
    '"', '_',
    '''', // shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', #127
  );

const
  english_shiftxform: array[0..127] of char = (
    #0,
    #1, #2, #3, #4, #5, #6, #7, #8, #9, #10,
    #11, #12, #13, #14, #15, #16, #17, #18, #19, #20,
    #21, #22, #23, #24, #25, #26, #27, #28, #29, #30,
    #31,
    ' ', '!', '"', '#', '$', '%', '&',
    '"', // shift-'
    '(', ')', '*', '+',
    '<', // shift-,
    '_', // shift--
    '>', // shift-.
    '?', // shift-/
    ')', // shift-0
    '!', // shift-1
    '@', // shift-2
    '#', // shift-3
    '$', // shift-4
    '%', // shift-5
    '^', // shift-6
    '&', // shift-7
    '*', // shift-8
    '(', // shift-9
    ':',
    ':', // shift-;
    '<',
    '+', // shift-=
    '>', '?', '@',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '[', // shift-[
    '!', // shift-backslash - OH MY GOD DOES WATCOM SUCK
    ']', // shift-]
    '"', '_',
    '''', // shift-`
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N',
    'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    '{', '|', '}', '~', #127
  );

const
  frenchKeyMap: array[0..127] of char = (
    #0,
    #1,#2,#3,#4,#5,#6,#7,#8,#9,#10,
    #11,#12,#13,#14,#15,#16,#17,#18,#19,#20,
    #21,#22,#23,#24,#25,#26,#27,#28,#29,#30,
    #31,
    ' ','!','"','#','$','%','&','%','(',')','*','+',';','-',':','!',
    '0','1','2','3','4','5','6','7','8','9',':','M','<','=','>','?',
    '@','Q','B','C','D','E','F','G','H','I','J','K','L',',','N','O',
    'P','A','R','S','T','U','V','Z','X','Y','W','^','\','$','^','_',
    '@','Q','B','C','D','E','F','G','H','I','J','K','L',',','N','O',
    'P','A','R','S','T','U','V','Z','X','Y','W','^','\','$','^',#127
  );

function ForeignTranslation(ch: char): char;
begin
  if ch < #128 then
    result := frenchKeyMap[Ord(ch)]
  else
    result := ch;
end;

procedure HU_Init;
var
  i: integer;
  j: integer;
  buffer: string;
  lump: integer;
begin
  if language = french then
  begin
    for i := 0 to 127 do
      shiftxform[i] := french_shiftxform[i];
  end
  else
  begin
    for i := 0 to 127 do
      shiftxform[i] := english_shiftxform[i];
  end;

  // load the heads-up font
  j := Ord(HU_FONTSTART);
  for i := 0 to HU_FONTSIZE - 1 do
  begin
    buffer := 'FNTA' + IntToStrZfill(3, j);
    lump := W_CheckNumForName(buffer);
    if lump < 0 then
      lump := W_GetNumForName('TNT1A0');
    inc(j);
    hu_font[i] := W_CacheLumpNum(lump, PU_STATIC);
  end;

  // Red DOS font
  j := Ord(DOS_FONTSTART);
  for i := 0 to DOS_FONTSIZE - 1 do
  begin
    buffer := 'DOSFA' + IntToStrZfill(3, j);
    lump := W_CheckNumForName(buffer);
    if lump < 0 then
      lump := W_GetNumForName('TNT1A0');
    inc(j);
    dos_fontA[i] := W_CacheLumpNum(lump, PU_STATIC);
  end;

  // White DOS font
  j := Ord(DOS_FONTSTART);
  for i := 0 to DOS_FONTSIZE - 1 do
  begin
    buffer := 'DOSFB' + IntToStrZfill(3, j);
    lump := W_CheckNumForName(buffer);
    if lump < 0 then
      lump := W_GetNumForName('TNT1A0');
    inc(j);
    dos_fontB[i] := W_CacheLumpNum(lump, PU_STATIC);
  end;

  // Red BIG font
  j := Ord(BIG_FONTSTART);
  for i := 0 to BIG_FONTSIZE - 1 do
  begin
    buffer := 'BIGFA' + IntToStrZfill(3, j);
    lump := W_CheckNumForName(buffer);
    if lump < 0 then
      lump := W_GetNumForName('TNT1A0');
    inc(j);
    big_fontA[i] := W_CacheLumpNum(lump, PU_STATIC);
  end;

  // Gray BIG font
  j := Ord(BIG_FONTSTART);
  for i := 0 to BIG_FONTSIZE - 1 do
  begin
    buffer := 'BIGFB' + IntToStrZfill(3, j);
    lump := W_CheckNumForName(buffer);
    if lump < 0 then
      lump := W_GetNumForName('TNT1A0');
    inc(j);
    big_fontB[i] := W_CacheLumpNum(lump, PU_STATIC);
  end;

  // Orange BIG font
  j := Ord(BIG_FONTSTART);
  for i := 0 to BIG_FONTSIZE - 1 do
  begin
    buffer := 'BIGFC' + IntToStrZfill(3, j);
    lump := W_CheckNumForName(buffer);
    if lump < 0 then
      lump := W_GetNumForName('TNT1A0');
    inc(j);
    big_fontC[i] := W_CacheLumpNum(lump, PU_STATIC);
  end;

  for i := 0 to FPSSIZE - 1 do
    FPSHISTORY[i] := 0;

  for i := 0 to FPSSIZE2 - 1 do
    FPSHISTORY2[i] := 0;

  C_AddCmd('fps', @HU_CmdFPS);
  C_AddCmd('playermessage', @HU_CmdPlayerMessage);
end;

procedure HU_Stop;
begin
  headsupactive := false;
end;

procedure HU_Start;
var
  i: integer;
  s: string;
begin
  if headsupactive then
    HU_Stop;

  plr := @players[consoleplayer];
  message_on := false;
  message_dontfuckwithme := false;
  message_nottobefuckedwith := false;
  chat_on := false;

  // create the message widget
  HUlib_initSText(@w_message,
    HU_MSGX, HU_MSGY, HU_MSGHEIGHT,
    @hu_font,
    Ord(HU_FONTSTART), @message_on);

  // create the map title widget
  HUlib_initTextLine(@w_title,
    HU_TITLEX, HU_TITLEY,
    @hu_font,
    Ord(HU_FONTSTART));

  HUlib_initTextLine(@w_leveltime,
    HU_LEVELTIMEX, HU_LEVELTIMEY,
    @hu_font,
    Ord(HU_FONTSTART));

  s := HU_TITLE;

  for i := 1 to Length(s) do
    HUlib_addCharToTextLine(@w_title, s[i]);

  // create the chat widget
  HUlib_initIText(@w_chat,
    HU_INPUTX, HU_INPUTY,
    @hu_font,
    Ord(HU_FONTSTART), @chat_on);

  // create the inputbuffer widgets
  for i := 0 to MAXPLAYERS - 1 do
    HUlib_initIText(@w_inputbuffer[i], 0, 0, nil, 0, @always_off);

  headsupactive := true;
end;

{$IFDEF OPENGL}
var
  hu_h: integer = 0;

function HU_Height: integer;
begin
  result := hu_h;
end;
{$ENDIF}

var
  m_fps: string = '';
  fps_ticker: integer = 0;

procedure HU_DrawFPS;
var
  i: integer;
  x, y: integer;
  c: integer;
begin
{$IFDEF OPENGL}
  x := 272;
  y := 1;
  for i := length(m_fps) downto 1 do
  begin
    if m_fps[i] <> ' ' then
    begin
      c := Ord(toupper(m_fps[i])) - Ord(HU_FONTSTART);
      V_DrawPatch(x, y, SCN_FG, hu_font[c], false);
      x := x - 6;
    end
    else
      x := x - 4;
  end;
  hu_h := hu_h + 9;
{$ELSE}
  if (amstate = am_only) or (viewwindowx = 0) then
  begin
    x := 272;
    y := 1;
  end
  else
  begin
    x := (viewwindowx + viewwidth) * 320 div SCREENWIDTH - 9;
    y := viewwindowy * 200 div SCREENHEIGHT + 1;
  end;
  for i := length(m_fps) downto 1 do
  begin
    if m_fps[i] <> ' ' then
    begin
      c := Ord(toupper(m_fps[i])) - Ord(HU_FONTSTART);
      V_DrawPatch(x, y, SCN_FG, hu_font[c], true);
      x := x - 6;
    end
    else
      x := x - 4;
  end;
{$ENDIF}  
end;

// 19/9/2009 JVAL: For drawing demo progress
procedure HU_DrawDemoProgress;
var
  dp: Ppatch_t;
  i: integer;
  x, y: integer;
begin
  dp := W_CacheLumpName('DEMOTIME', PU_STATIC);
  x := viewwindowx{$IFDEF OPENGL} * 320 div SCREENWIDTH{$ENDIF};
  y := (viewwindowy + viewheight){$IFDEF OPENGL} * 200 div SCREENHEIGHT{$ENDIF};
{$IFDEF OPENGL}
  i := round(G_DemoProgress * viewwidth / SCREENWIDTH * 320 / FRACUNIT);
{$ELSE}
  i := G_DemoProgress * viewwidth div FRACUNIT;
{$ENDIF}  
  while i > 0 do
  begin
    V_DrawPatchTransparent(x, y, SCN_FG, dp, {$IFDEF OPENGL}true{$ELSE}false{$ENDIF});
    i := i - dp.width;
    x := x + dp.width;
  end;
  Z_ChangeTag(dp, PU_CACHE);
end;

procedure HU_Drawer;
var
  i, t: integer;
{$IFDEF OPENGL}
  i2, idx, lines: integer;
{$ENDIF}
  lt: string;
begin
{$IFDEF OPENGL}
  hu_h := 0;
{$ENDIF}
  if drawfps then
    HU_DrawFPS;
  if demoplayback and showdemoplaybackprogress then
    HU_DrawDemoProgress;

  HUlib_drawSText(@w_message);
  {$IFDEF OPENGL}
  if w_message._on^ then
    for i := 0 to w_message.height - 1 do
    begin
      idx := w_message.curline - i;
      if idx < 0 then
        idx := idx + w_message.height; // handle queue of lines
      lines := 0;
      for i2 := 0 to w_message.lines[idx].len - 1 do
        if w_message.lines[idx].line[i2] = #10 then
          inc(lines);
      if lines * 10 > hu_h then
        hu_h := lines * 10;
    end;
  {$ENDIF}
  HUlib_drawIText(@w_chat);
  if amstate = am_only then
  begin
    repeat
    until not HUlib_delCharFromTextLine(@w_leveltime);
    t := leveltime div TICRATE;
    lt := IntToStrZFill(2, t mod 60);
    t := t div 60;
    lt := IntToStrZFill(2, t mod 60) + ':' + lt;
    t := t div 60;
    lt := 'Time: ' + IntToStrZFill(2, t) + ':' + lt;

    for i := 1 to Length(lt) do
      HUlib_addCharToTextLine(@w_leveltime, lt[i]);
    HUlib_drawTextLine(@w_leveltime, false);
    HUlib_drawTextLine(@w_title, false);
  end;
end;

procedure HU_Erase;
begin
  HUlib_eraseSText(@w_message);
  HUlib_eraseIText(@w_chat);
  HUlib_eraseTextLine(@w_title);
end;

procedure HU_Ticker;
var
  i: integer;
  rc: boolean;
  c: char;
begin
  dec(fps_ticker);
  if fps_ticker <= 0 then
  begin
    m_fps := itoa(HU_FPS) + ' fps';
    fps_ticker := TICRATE div 2;
  end;

  // tick down message counter if message is up
  if message_counter <> 0 then
  begin
    dec(message_counter);
    if message_counter = 0 then
    begin
      HUlib_removeLineFromSText(@w_message);
      message_on := w_message.lines[w_message.curline].len > 0;
      if message_on then
        message_counter := HU_MSGTIMEOUT;
      message_nottobefuckedwith := false;
    end;
  end;

  if (showMessages <> 0) or message_dontfuckwithme then
  begin
    // display message if necessary
    if plr <> nil then
      if ((plr._message <> '') and (not message_nottobefuckedwith)) or
         ((plr._message <> '') and message_dontfuckwithme) then
      begin
        HUlib_addMessageToSText2(@w_message, '', plr._message);
        plr._message := '';
        message_on := true;
        message_counter := HU_MSGTIMEOUT;
        message_nottobefuckedwith := message_dontfuckwithme;
        message_dontfuckwithme := false;
      end;
  end; // else message_on = false;

  // check for incoming chat characters
  if netgame then
  begin
    for i := 0 to MAXPLAYERS - 1 do
    begin
      if not playeringame[i] then
        continue;
      c := Chr(players[i].cmd.chatchar);
      if (i <> consoleplayer) and (c <> #0) then
      begin
        if c <= Chr(HU_BROADCAST) then
          chat_dest[i] := c
        else
        begin
          if (c >= 'a') and (c <= 'z') then
            c := shiftxform[Ord(c)];
          rc := HUlib_keyInIText(@w_inputbuffer[i], Ord(c));
          if rc and (Ord(c) = KEY_ENTER) then
          begin
            if (w_inputbuffer[i].line.len <> 0) and
               ((Ord(chat_dest[i]) = consoleplayer + 1) or (Ord(chat_dest[i]) = HU_BROADCAST)) then
            begin
              HUlib_addMessageToSText(@w_message,
                player_names[i],
                w_inputbuffer[i].line.line);

              message_nottobefuckedwith := true;
              message_on := true;
              message_counter := HU_MSGTIMEOUT;
              S_StartSound(nil, Ord(sfx_tink));
            end;
            HUlib_resetIText(@w_inputbuffer[i]);
          end;
        end;
        players[i].cmd.chatchar := 0;
      end;
    end;
  end;
end;

const
  QUEUESIZE = 128;

var
  chatchars: array[0..QUEUESIZE - 1] of char;
  head: integer = 0;
  tail: integer = 0;

procedure HU_queueChatChar(c: char);
begin
  if ((head + 1) and (QUEUESIZE - 1)) = tail then
    plr._message := HUSTR_MSGU
  else
  begin
    chatchars[head] := c;
    head := (head + 1) and (QUEUESIZE - 1);
  end;
end;

function HU_dequeueChatChar: char;
begin
  if head <> tail then
  begin
    result := chatchars[tail];
    tail := (tail + 1) and (QUEUESIZE - 1);
  end
  else
    result := #0;
end;

var
  lastmessage: string;
  shiftdown: boolean = false;
  altdown: boolean = false;
  num_nobrainers: integer = 0;

function HU_Responder(ev: Pevent_t): boolean;
var
  macromessage: string;
  c: char;
  i: integer;
  numplayers: integer;
begin
  result := false;

  if ev.data1 = KEY_RSHIFT then
  begin
    shiftdown := ev._type = ev_keydown;
    exit;
  end
  else if (ev.data1 = KEY_RALT) or (ev.data1 = KEY_LALT) then
  begin
    altdown := ev._type = ev_keydown;
    exit;
  end;

  if ev._type <> ev_keydown then
    exit;

  numplayers := 0;
  for i := 0 to MAXPLAYERS - 1 do
    if playeringame[i] then
      inc(numplayers);

  if not chat_on then
  begin
    if ev.data1 = HU_MSGREFRESH then
    begin
      message_on := true;
      message_counter := HU_MSGTIMEOUT;
      result := true;
    end
    else if netgame and (ev.data1 = Ord(HU_INPUTTOGGLE)) then
    begin
      result := true;
      chat_on := true;
      HUlib_resetIText(@w_chat);
      HU_queueChatChar(Chr(HU_BROADCAST));
    end
    else if netgame and (numplayers > 2) then
    begin
      for i := 0 to MAXPLAYERS - 1 do
      begin
        if destination_keys[i] <> '' then
        begin
          if ev.data1 = Ord(destination_keys[i][1]) then
          begin
            if playeringame[i] and (i <> consoleplayer) then
            begin
              result := true;
              chat_on := true;
              HUlib_resetIText(@w_chat);
              HU_queueChatChar(Chr(i + 1));
              break;
            end
            else if i = consoleplayer then
            begin
              inc(num_nobrainers);
              if num_nobrainers < 3 then
                plr._message := HUSTR_TALKTOSELF1
              else if num_nobrainers < 6 then
                plr._message := HUSTR_TALKTOSELF2
              else if num_nobrainers < 9 then
                plr._message := HUSTR_TALKTOSELF3
              else if num_nobrainers < 32 then
                plr._message := HUSTR_TALKTOSELF4
              else
                plr._message := HUSTR_TALKTOSELF5;
            end
          end;
        end;
      end;
    end;
  end
  else
  begin
    c := Chr(ev.data1);
    // send a macro
    if altdown then
    begin
      c := Chr(Ord(c) - Ord('0'));
      if c > Chr(9) then
        exit;
      macromessage := chat_macros[Ord(c)];

      // kill last message with a '\n'
      HU_queueChatChar(Chr(KEY_ENTER)); // DEBUG!!!

      // send the macro message
      for i := 1 to Length(macromessage) do
        HU_queueChatChar(macromessage[i]);
      HU_queueChatChar(Chr(KEY_ENTER));

      // leave chat mode and notify that it was sent
      chat_on := false;
      lastmessage := chat_macros[Ord(c)];
      plr._message := lastmessage;
      result := true;
    end
    else
    begin
      if language = french then
        c := ForeignTranslation(c);
      if shiftdown or ((c >= 'a') and (c <= 'z')) then
        c := shiftxform[Ord(c)];
      result := HUlib_keyInIText(@w_chat, Ord(c));
      if result then
        HU_queueChatChar(c);
      if Ord(c) = KEY_ENTER then
      begin
        chat_on := false;
        if w_chat.line.len <> 0 then
        begin
          lastmessage := w_chat.line.line;
          plr._message := lastmessage;
        end
      end
      else if Ord(c) = KEY_ESCAPE then
        chat_on := false;
    end;
  end;
end;

initialization
  chat_macros[0] := HUSTR_CHATMACRO0;
  chat_macros[1] := HUSTR_CHATMACRO1;
  chat_macros[2] := HUSTR_CHATMACRO2;
  chat_macros[3] := HUSTR_CHATMACRO3;
  chat_macros[4] := HUSTR_CHATMACRO4;
  chat_macros[5] := HUSTR_CHATMACRO5;
  chat_macros[6] := HUSTR_CHATMACRO6;
  chat_macros[7] := HUSTR_CHATMACRO7;
  chat_macros[8] := HUSTR_CHATMACRO8;
  chat_macros[9] := HUSTR_CHATMACRO9;

  player_names[0] := HUSTR_PLRGREEN;
  player_names[1] := HUSTR_PLRINDIGO;
  player_names[2] := HUSTR_PLRBROWN;
  player_names[3] := HUSTR_PLRRED;

////////////////////////////////////////////////////////////////////////////////
//
// Builtin map names.
// The actual names can be found in DStrings.h.
//
////////////////////////////////////////////////////////////////////////////////

// DOOM shareware/registered/retail (Ultimate) names.

  mapnames[0] := HUSTR_E1M1;
  mapnames[1] := HUSTR_E1M2;
  mapnames[2] := HUSTR_E1M3;
  mapnames[3] := HUSTR_E1M4;
  mapnames[4] := HUSTR_E1M5;
  mapnames[5] := HUSTR_E1M6;
  mapnames[6] := HUSTR_E1M7;
  mapnames[7] := HUSTR_E1M8;
  mapnames[8] := HUSTR_E1M9;

  mapnames[9] := HUSTR_E2M1;
  mapnames[10] := HUSTR_E2M2;
  mapnames[11] := HUSTR_E2M3;
  mapnames[12] := HUSTR_E2M4;
  mapnames[13] := HUSTR_E2M5;
  mapnames[14] := HUSTR_E2M6;
  mapnames[15] := HUSTR_E2M7;
  mapnames[16] := HUSTR_E2M8;
  mapnames[17] := HUSTR_E2M9;

  mapnames[18] := HUSTR_E3M1;
  mapnames[19] := HUSTR_E3M2;
  mapnames[20] := HUSTR_E3M3;
  mapnames[21] := HUSTR_E3M4;
  mapnames[22] := HUSTR_E3M5;
  mapnames[23] := HUSTR_E3M6;
  mapnames[24] := HUSTR_E3M7;
  mapnames[25] := HUSTR_E3M8;
  mapnames[26] := HUSTR_E3M9;

  mapnames[27] := HUSTR_E4M1;
  mapnames[28] := HUSTR_E4M2;
  mapnames[29] := HUSTR_E4M3;
  mapnames[30] := HUSTR_E4M4;
  mapnames[31] := HUSTR_E4M5;
  mapnames[32] := HUSTR_E4M6;
  mapnames[33] := HUSTR_E4M7;
  mapnames[34] := HUSTR_E4M8;
  mapnames[35] := HUSTR_E4M9;

  mapnames[36] := 'NEWLEVEL';
  mapnames[37] := mapnames[36];
  mapnames[38] := mapnames[36];
  mapnames[39] := mapnames[36];
  mapnames[40] := mapnames[36];
  mapnames[41] := mapnames[36];
  mapnames[42] := mapnames[36];
  mapnames[43] := mapnames[36];
  mapnames[44] := mapnames[36];

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

  destination_keys[0] := HUSTR_KEYGREEN;
  destination_keys[1] := HUSTR_KEYINDIGO;
  destination_keys[2] := HUSTR_KEYBROWN;
  destination_keys[3] := HUSTR_KEYRED;

end.

