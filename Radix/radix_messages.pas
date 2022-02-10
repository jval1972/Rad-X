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
//   Radix Messages
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_messages;

interface

const
  S_RADIX_MESSAGE_0 = 'Primary target ahead';
  S_RADIX_MESSAGE_1 = 'Secondary target ahead';
  S_RADIX_MESSAGE_2 = 'Shoot doors to gain entry';
  S_RADIX_MESSAGE_3 = 'Multiple targets ahead';
  S_RADIX_MESSAGE_4 = 'Kill enemies to continue';
  S_RADIX_MESSAGE_5 = 'Powerful Enemy approaching';
  S_RADIX_MESSAGE_6 = 'Exit above current position';
  S_RADIX_MESSAGE_7 = 'Exit below current position';
  S_RADIX_MESSAGE_8 = 'Watch For Seeking Missiles';
  S_RADIX_MESSAGE_9 = 'Primary Objective Completed';
  S_RADIX_MESSAGE_10 = 'Primary Objective Incomplete';
  S_RADIX_MESSAGE_11 = 'Kill all Skyfires to continue';
  S_RADIX_MESSAGE_12 = 'Secondary Objective Completed';

  S_RADIX_STARTUP_MESSAGE_1 = 'PRESS F1 FOR HELP. F12 FOR MISSION OBJECTIVES';
  S_RADIX_STARTUP_MESSAGE_2 = 'PRESS F12 FOR MISSION OBJECTIVES';

const
  NUMRADIXMESSAGES = 13;

type
  radixmessage_t = record
    radix_msg: string;
    radix_snd: integer;
    autodisable: boolean;
  end;
  Pradixmessage_t = ^radixmessage_t;

var
  radixmessages: array[0..NUMRADIXMESSAGES - 1] of radixmessage_t;

//==============================================================================
//
// RX_StartUpMessage
//
//==============================================================================
function RX_StartUpMessage(const episode, map: integer): string;

const
  NUMHIDDENMESSAGES = 147;

// Hidden messages from https://www.tcrf.net/Radix:_Beyond_the_Void
var
  radixhiddenmessages: array[0..NUMHIDDENMESSAGES - 1] of string = (
   'So you''ve beat the Bio-Spawner?! Wait til you meet Ryan!',
   'WOOOF! The crack paper can wait!',
   'Ma Ma Ma My Sharona plays radix too!',
   'Drive Select is different from motor on!',
   'You guys are the pop-up surprise men!',
   'It''s just that simple!',
   'Hey, Lets try it with the turbo off!',
   'Still no quote of the day today.',
   'You too, whatever!',
   'Get outta here ya pansy!',
   'Get some besterd insurance!',
   'Nice living room guys!',
   'Dan Dufeu. That''s D-A-N D-U-F-E-U.',
   'Greg MacMartin. That''s G-R-E-G M-C-M-U-F-F-I-N.',
   '20 McMuffins a day, you''re on!!',
   'Watch for the T101 in search mode for RASMUS.',
   'Battlestations everyone!! Prepare for falling prices!!',
   'Smell that burning rubber?? Time to back up into a lake.',
   'Military artillery range?? Time to back up!!',
   'Dan, why are we backing up into a lake?',
   'Down on the ground! Hands behind your head!... Just Kidding.',
   'Shpeed? I shend check, you shend shuper?',
   'Texas? I have an auntie who lives in Texas.',
   'Barbara? No. Jerry. Like Tom and Jerry? Like cartoon?',
   'Martha ZIP?!',
   'Ya I''m ok, no blood! Wait a minute.. gurgle, gurgle, gurgle.',
   'Remember to get our sign off the door... RIP!',
   'Hmm, why is there a coat hanger inside the vending machine?',
   'Middletown, Indiana? Must be wrong ZIP. Yeah ha ha sure...',
   'Dan is on safari, a Kanata safari.',
   'Too bad about that stop sign, eh.',
   'Blue-suited freak? What blue-suited freak???',
   'WARNING: Watch out for the radioactive pizza in the garage.',
   'How is that ketchup. Glub glub glub glub. ewww!',
   'Yes, sir. Yes. Ok, sir. Can I go now?',
   'Enough quotes already.',
   'What did you say? ... Football all gone!',
   'Watch for the Kanata COPS show, coming soon.',
   'Pablo honey? Buy Radix Pablo. Take me into the void, Pablo.',
   'Hey, whats up there fruit cake?!',
   'Doonga, I looking foh Radix. Doonga ooh ha. Punja oh yes?',
   'Honey, will you just give me a chance? I will freak you out!',
   'Two-Hundred and Eighty Six? I don''t think so, Olaf.',
   'You hava da expairiance playing Radix?',
   'Had problems which yer boss?',
   'BOOM! BOOM! BOOM! Network play? You better believe it!',
   'AAAAAAAAAAHHHHHHHHHHHHHH! Poison Radix!',
   'Lookin for a job driving a truck? How bout a Radix instead?',
   'Quoctogooooooooooooooooooooooooooooon. huh?',
   'Yes, we used Watcom for the final compile.',
   'Floppy access slows my kapewter.',
   'I''m asking you for help here!',
   'Truly Loony! Truly Loony! Truly Loony!',
   'I''m calling you cause I need a little help...',
   'The dog is inside the computer. He''s snappin and barking.',
   'Are you Feddy???',
   'HONK! HONK! Appropro????',
   'If you show us you can do it, and you know you can do it...',
   'You guys work for Quantum??',
   'Lickity split, palette trick!!!',
   'This ain''t no bjipping flight-sim!',
   'Radix and PC Cola. That''s all we do out here in Kanata.',
   'Ya know guyz, these quotes add perceived value.',
   'I never played football in high school, so now I play Radix.',
   'Maybe we should get him to sign something, you know?',
   'I LUV playing Radix. Why don''t you join me at 1-900-RADIXXX.',
   'Don''t be a big pink elephant bagwan like some people.',
   'Rev up Radix with the Rabbit!',
   'Earth and a crosshair? What the BEEP are you talking about?!',
   'Radix. What would we do without that assembler book??',
   'I was in Radix, and my screen-saver popped up.',
   'Your cat is under my truck playing Radix.',
   'Do you have a licence? Is it valid?!',
   'I have life insurance, but its through a friend.',
   'Man, these quotes that keep popping up are really annoying!',
   'Mega meals. Mmmmmm, I love mega meals!',
   'I''m gonna go home tonight and tell my wife I met God today!',
   'Net play? Ya, simple. You just sync em up. Its automatic!',
   'Ever driven a Ferrari under an 18-wheeler?? Its AWESOME!',
   'Oooh, aahh. I just hit a brick wall at 180 in my Porsche!',
   'These quotes make no sense, whatsoever! Or do they...',
   'Honk for Wahoo! HONK! HONK!',
   'White Rose, beautiful!',
   'I''m not mad at you Dan, I''m mad at you Jon! Ennnhhhh!',
   'If you don''t play dis game, its like stebbing me in de beck!',
   'This is really nice.',
   'Question.... Inquiry....?',
   'Thats it! Business? Fine! Friends? FORGET IT!! Ennnhhhh.',
   'Never order from Popeye or TLC (Thick Load of Cheese).',
   'Never contract out a nipple.',
   'Never piss in the wind.',
   'Always practice offensive driving.',
   'A hit game will buy you an island the size of Australia!',
   'Want us to be working in a prison? No...',
   'Earwigs? In a prison? Long story...',
   '4DOS memory allocation error? I don''t think so...',
   'GER PRENANT!!! GER PRENAAAAANNNNT!!!',
   'The window busted itself! Honest...',
   'That laptop just FLEW off the desk! Honest...',
   'Damn my tooth hurts... rip rip',
   'Go for a long bomb... watch out for that sideways car...',
   'You''re going to the crack? What''s that????',
   'Get CRACKING!',
   'No more pucks... ewww!',
   'Six free Boisson GAAAAAAZZEUS?',
   'Know the settings for this drive? No, we only do IC here.',
   'Ya that''s the rock they shot thru the window. You insured?',
   'Joystick? No the mouse kicks...',
   'Sure you want the desks back? There seems to be some holes.',
   'Is this Shawzod guy ever coming beck? Ennnhhhh.',
   'What does dis have dat de Castle of de Wolfenshteen doesn''t?',
   'Mind over Matter, enh?',
   'Interactive multimedia applications?? Nah!!!!',
   'FPP engine? What the BEEP is that?!',
   'Those VM guyz are really counting on you! Ennnhhhh.',
   'Saturn?!?! With this palette?? IMPOSSIBLE!! Can''t be done!!',
   'ICE? I thought that''s what you put in your drink?! Ennnhhhh.',
   'It''s called ICE, cuz all de glaciers hev surrounded de city.',
   'I don''t pay dese guyz $20 an hour to go enh, enh. No, sorry!',
   'Gonna get these windows fixed?? Oh yeah, yeah. -sip, sip-',
   'Mmmmmm, thick load of cheese. I LOVE thick loads of cheese!',
   'Reverse mouse?? Check your INI file!',
   'WAHOO BNART!!!',
   'Hitch on!',
   'Watch for RADIX: Beyond the Polka Dots!! As seen on TV.',
   'What ever happened to Radix''s propeller??',
   'There are NO bugs in the map editor.',
   'Is dis Eric guy going to do de map editor, Jonatin? Ennnhhh.',
   'It cost me 4 touzan dollars a mont to stay open. It''s no jok!',
   'Special thanks to Karim, from Larry.',
   'RADIX 2 can be in de Parliament Buildings, rite guyz?!',
   'Hallo, my name is Pico.',
   'Time to pump some serious coad guyz. Ennnhhhh.',
   'Most of these quotes are inside jokes. No Joke.',
   'Lar... these guys had to change their name -blah blah- Quantum.',
   'No Jay, the animation IS 256 color.',
   'Are you using that fridge? Micro? Board? Chairs? Mouse?....',
   'Jon busted another keyboard?',
   'You have a wooden mouse, that would be a hot seller!!',
   'Jeez, this SGI sim feels like my real helicopter!',
   'I am not signing dis piece of crep! Ennnhhhh.',
   'Stop breathing... Just say it! Ennnhhhh.',
   'One anonymous user!!! What a piece of BEEP!',
   'I am calling from Spain. I am a hahha.',
   'ACHOO!!!!',
   'No quote of the day today.',
   'Radix REMIX 2.0 is brought to you by Greg and Dan!'
  );

implementation

uses
  radix_sounds;

//==============================================================================
//
// RX_StartUpMessage
//
//==============================================================================
function RX_StartUpMessage(const episode, map: integer): string;
begin
  if episode = 1 then
  begin
    if map < 5 then
      result := S_RADIX_STARTUP_MESSAGE_1
    else
      result := S_RADIX_STARTUP_MESSAGE_2;
  end
  else if episode = 2 then
  begin
    if map < 4 then
      result := S_RADIX_STARTUP_MESSAGE_1
    else
      result := S_RADIX_STARTUP_MESSAGE_2;
  end
  else if episode = 3 then
  begin
    if map = 1 then
      result := S_RADIX_STARTUP_MESSAGE_1
    else
      result := S_RADIX_STARTUP_MESSAGE_2;
  end
  else
    result := S_RADIX_STARTUP_MESSAGE_2;
end;

initialization
  radixmessages[0].radix_msg := S_RADIX_MESSAGE_0;
  radixmessages[0].radix_snd := Ord(sfx_SndPrimAhead);
  radixmessages[0].autodisable := false;

  radixmessages[1].radix_msg := S_RADIX_MESSAGE_1;
  radixmessages[1].radix_snd := Ord(sfx_SndSecAhead);
  radixmessages[1].autodisable := false;

  radixmessages[2].radix_msg := S_RADIX_MESSAGE_2;
  radixmessages[2].radix_snd := -1;
  radixmessages[2].autodisable := false;

  radixmessages[3].radix_msg := S_RADIX_MESSAGE_3;
  radixmessages[3].radix_snd := Ord(sfx_SndTargetsAhead);
  radixmessages[3].autodisable := false;

  radixmessages[4].radix_msg := S_RADIX_MESSAGE_4;
  radixmessages[4].radix_snd := Ord(sfx_SndEnemy);
  radixmessages[4].autodisable := false;

  radixmessages[5].radix_msg := S_RADIX_MESSAGE_5;
  radixmessages[5].radix_snd := -1;
  radixmessages[5].autodisable := false;

  radixmessages[6].radix_msg := S_RADIX_MESSAGE_6;
  radixmessages[6].radix_snd := -1;
  radixmessages[6].autodisable := false;

  radixmessages[7].radix_msg := S_RADIX_MESSAGE_7;
  radixmessages[7].radix_snd := -1;
  radixmessages[7].autodisable := false;

  radixmessages[8].radix_msg := S_RADIX_MESSAGE_8;
  radixmessages[8].radix_snd := -1;
  radixmessages[8].autodisable := false;

  radixmessages[9].radix_msg := S_RADIX_MESSAGE_9;
  radixmessages[9].radix_snd := Ord(sfx_SndPrimComplete);
  radixmessages[9].autodisable := true;

  radixmessages[10].radix_msg := S_RADIX_MESSAGE_10;
  radixmessages[10].radix_snd := Ord(sfx_SndPrimInComplete);
  radixmessages[10].autodisable := false;

  radixmessages[11].radix_msg := S_RADIX_MESSAGE_11;
  radixmessages[11].radix_snd := -1;
  radixmessages[11].autodisable := false;

  radixmessages[12].radix_msg := S_RADIX_MESSAGE_12;
  radixmessages[12].radix_snd := Ord(sfx_SndSecComplete);
  radixmessages[12].autodisable := true;

end.
