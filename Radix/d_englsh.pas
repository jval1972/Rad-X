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
// DESCRIPTION:
//  Printed strings for translation.
//  English language support (default).
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit d_englsh;

interface

//
//  Printed strings for translation
//

//
// D_Main.C
//

var
  D_DEVSTR: string =
    'Development mode ON.' + #13#10;
  D_CDROM: string =
    'CD-ROM Version: RAD.ini from c:\doomdata' + #13#10;

//
//  M_Menu.C
//
  PRESSKEY: string =
    'press a key.';
  PRESSYN: string =
    'press y or n.';

  QUITMSG: string =
    'are you sure you want to' + #13#10 +
    'quit this great game?';

  LOADNET: string =
    'you can''t do load while in a net game!' + #13#10;

  QLOADNET: string =
    'you can''t quickload during a netgame!' + #13#10;

  QSAVESPOT: string =
    'you haven''t picked a quicksave slot yet!' + #13#10;

  SAVEDEAD: string =
    'you can''t save if you aren''t playing!' + #13#10;

  QSPROMPT: string =
    'quicksave over your game named' + #13#10 + #13#10 +
    '''%s''?' + #13#10;

  QLPROMPT: string =
    'do you want to quickload the game named' + #13#10 + #13#10 +
    '''%s''?' + #13#10;

  SNEWGAME: string =
    'you can''t start a new game' + #13#10 +
    'while in a network game.' + #13#10;

  SNIGHTMARE: string =
    'are you sure? this skill level' + #13#10 +
    'isn''t even remotely fair.';

  SWSTRING: string =
    'this is the shareware version.' + #13#10 +
    'you need to order the entire trilogy.';

  MSGOFF: string =
    'Messages OFF';
  MSGON: string =
    'Messages ON';

  NETEND: string =
    'you can''t end a netgame!' + #13#10;
  SENDGAME : string =
    'are you sure you want to end the game?' + #13#10;

  DOSY: string =
    '(press y to quit)';

var
  DETAILNORM: string = 'Normal detail';
  DETAILMED: string = 'Medium detail';
  GAMMALVL0: string = 'Gamma correction OFF';
  GAMMALVL1: string = 'Gamma correction level 1';
  GAMMALVL2: string = 'Gamma correction level 2';
  GAMMALVL3: string = 'Gamma correction level 3';
  GAMMALVL4: string = 'Gamma correction level 4';
  EMPTYSTRING: string = 'empty slot';

//
//  P_inter.C
//
var
  GOTARMOR: string = 'Picked up the armor.';
  GOTMEGA: string = 'Picked up the MegaArmor!';
  GOTHTHBONUS: string = 'Picked up a health bonus.';
  GOTARMBONUS: string = 'Picked up an armor bonus.';
  GOTSTIM: string = 'Picked up a stimpack.';
  GOTMEDINEED: string = 'Picked up a medikit that you REALLY need!';
  GOTMEDIKIT: string = 'Picked up a medikit.';
  GOTSUPER: string = 'Supercharge!';

  GOTBLUECARD: string = 'Picked up a blue keycard.';
  GOTYELWCARD: string = 'Picked up a yellow keycard.';
  GOTREDCARD: string = 'Picked up a red keycard.';
  GOTBLUESKUL: string = 'Picked up a blue skull key.';
  GOTYELWSKUL: string = 'Picked up a yellow skull key.';
  GOTREDSKULL: string = 'Picked up a red skull key.';

  GOTINVUL: string = 'Invulnerability!';
  GOTBERSERK: string = 'Berserk!';
  GOTINVIS: string = 'Partial Invisibility';
  GOTSUIT: string = 'Radiation Shielding Suit';
  GOTMAP: string = 'Computer Area Map';
  GOTVISOR: string = 'Light Amplification Visor';
  GOTMSPHERE: string = 'MegaSphere!';

  GOTCLIP: string = 'Picked up a clip.';
  GOTCLIPBOX: string = 'Picked up a box of bullets.';
  GOTROCKET: string = 'Picked up a rocket.';
  GOTROCKBOX: string = 'Picked up a box of rockets.';
  GOTCELL: string = 'Picked up an energy cell.';
  GOTCELLBOX: string = 'Picked up an energy cell pack.';
  GOTSHELLS: string = 'Picked up 4 shotgun shells.';
// JVAL: 7/12/2007 Correctly display the amound of picked-up shells
  GOTONESHELL: string = 'Picked up a shotgun shell.';
  GOTMANYSHELLS: string = 'Picked up %d shotgun shells.';

  GOTSHELLBOX: string = 'Picked up a box of shotgun shells.';
  GOTBACKPACK: string = 'Picked up a backpack full of ammo!';

  GOTBFG9000: string = 'You got the BFG9000!  Oh, yes.';
  GOTCHAINGUN: string = 'You got the chaingun!';
  GOTCHAINSAW: string = 'A chainsaw!  Find some meat!';
  GOTLAUNCHER: string = 'You got the rocket launcher!';
  GOTPLASMA: string = 'You got the plasma gun!';
  GOTSHOTGUN: string = 'You got the shotgun!';
  GOTSHOTGUN2: string = 'You got the super shotgun!';

  MSGSECRETSECTOR: string = 'Found a secret area!!';

//
// P_Doors.C
//
var
  PD_BLUEO: string = 'You need a blue key to activate this object';
  PD_REDO: string = 'You need a red key to activate this object';
  PD_YELLOWO: string = 'You need a yellow key to activate this object';
  PD_BLUEK: string = 'You need a blue key to open this door';
  PD_REDK: string = 'You need a red key to open this door';
  PD_YELLOWK: string = 'You need a yellow key to open this door';
//jff 02/05/98 Create messages specific to card and skull keys
  PD_BLUEC: string = 'You need a blue card to open this door';
  PD_REDC: string = 'You need a red card to open this door';
  PD_YELLOWC: string = 'You need a yellow card to open this door';
  PD_BLUES: string = 'You need a blue skull to open this door';
  PD_REDS: string = 'You need a red skull to open this door';
  PD_YELLOWS: string = 'You need a yellow skull to open this door';
  PD_ANY: string = 'Any key will open this door';
  PD_ALL3: string = 'You need all three keys to open this door';
  PD_ALL6: string = 'You need all six keys to open this door';

//
// G_game.C
//
var
  GGSAVED: string = 'game saved.';

const
//
//  HU_stuff.C
//

  HUSTR_E1M1 = 'THETA 2: Mission 1';
  HUSTR_E1M2 = 'THETA 2: Mission 2';
  HUSTR_E1M3 = 'THETA 2: Mission 3';
  HUSTR_E1M4 = 'THETA 2: Mission 4';
  HUSTR_E1M5 = 'THETA 2: Mission 5';
  HUSTR_E1M6 = 'THETA 2: Mission 6';
  HUSTR_E1M7 = 'THETA 2: Mission 7';
  HUSTR_E1M8 = 'THETA 2: Mission 8';
  HUSTR_E1M9 = 'THETA 2: Secret Mission';

  HUSTR_E2M1 = 'VENGEANCE: Mission 1';
  HUSTR_E2M2 = 'VENGEANCE: Mission 2';
  HUSTR_E2M3 = 'VENGEANCE: Mission 3';
  HUSTR_E2M4 = 'VENGEANCE: Mission 4';
  HUSTR_E2M5 = 'VENGEANCE: Mission 5';
  HUSTR_E2M6 = 'VENGEANCE: Mission 6';
  HUSTR_E2M7 = 'VENGEANCE: Mission 7';
  HUSTR_E2M8 = 'VENGEANCE: Mission 8';
  HUSTR_E2M9 = 'VENGEANCE: Secret Mission';

  HUSTR_E3M1 = 'THE VOID: Mission 1';
  HUSTR_E3M2 = 'THE VOID: Mission 2';
  HUSTR_E3M3 = 'THE VOID: Mission 3';
  HUSTR_E3M4 = 'THE VOID: Mission 4';
  HUSTR_E3M5 = 'THE VOID: Mission 5';
  HUSTR_E3M6 = 'THE VOID: Mission 6';
  HUSTR_E3M7 = 'THE VOID: Mission 7';
  HUSTR_E3M8 = 'THE VOID: Mission 8';
  HUSTR_E3M9 = 'THE VOID: Secret Mission';

  HUSTR_E4M1 = 'Episode 4: Mission 1';
  HUSTR_E4M2 = 'Episode 4: Mission 2';
  HUSTR_E4M3 = 'Episode 4: Mission 3';
  HUSTR_E4M4 = 'Episode 4: Mission 4';
  HUSTR_E4M5 = 'Episode 4: Mission 5';
  HUSTR_E4M6 = 'Episode 4: Mission 6';
  HUSTR_E4M7 = 'Episode 4: Mission 7';
  HUSTR_E4M8 = 'Episode 4: Mission 8';
  HUSTR_E4M9 = 'Episode 4: Secret Mission';

  HUSTR_CHATMACRO1 = 'I''m ready to kick butt!';
  HUSTR_CHATMACRO2 = 'I''m OK.';
  HUSTR_CHATMACRO3 = 'I''m not looking too good!';
  HUSTR_CHATMACRO4 = 'Help!';
  HUSTR_CHATMACRO5 = 'You suck!';
  HUSTR_CHATMACRO6 = 'Next time, scumbag...';
  HUSTR_CHATMACRO7 = 'Come here!';
  HUSTR_CHATMACRO8 = 'I''ll take care of it.';
  HUSTR_CHATMACRO9 = 'Yes';
  HUSTR_CHATMACRO0 = 'No';

var
  HUSTR_TALKTOSELF1: string = 'You mumble to yourself';
  HUSTR_TALKTOSELF2: string = 'Who''s there?';
  HUSTR_TALKTOSELF3: string = 'You scare yourself';
  HUSTR_TALKTOSELF4: string = 'You start to rave';
  HUSTR_TALKTOSELF5: string = 'You''ve lost it...';

  HUSTR_MESSAGESENT: string = '[Message Sent]';
  HUSTR_MSGU: string = '[Message unsent]';

  { The following should NOT be changed unless it seems }
  { just AWFULLY necessary }
  HUSTR_PLRGREEN: string = 'Green:';
  HUSTR_PLRINDIGO: string = 'Indigo:';
  HUSTR_PLRBROWN: string = 'Brown:';
  HUSTR_PLRRED: string = 'Red:';

  HUSTR_KEYGREEN: string = 'g';
  HUSTR_KEYINDIGO: string = 'i';
  HUSTR_KEYBROWN: string = 't';
  HUSTR_KEYRED: string = 'r';

//
//  AM_map.C
//
  AMSTR_FOLLOWON: string = 'Follow Mode ON';
  AMSTR_FOLLOWOFF: string = 'Follow Mode OFF';
  AMSTR_GRIDON: string = 'Grid ON';
  AMSTR_GRIDOFF: string = 'Grid OFF';
  AMSTR_ROTATEON: string = 'Rotate ON';
  AMSTR_ROTATEOFF: string = 'Rotate OFF';
  AMSTR_MARKEDSPOT: string = 'Marked Spot';
  AMSTR_MARKSCLEARED: string = 'All Marks Cleared';

//
//  ST_stuff.C
//
  STSTR_MUS: string = 'Music Change';
  STSTR_NOMUS: string = 'IMPOSSIBLE SELECTION';
  STSTR_DQDON: string = 'Degreelessness Mode On';
  STSTR_DQDOFF: string = 'Degreelessness Mode Off';
  STSTR_LGON: string = 'Low Gravity Mode On';
  STSTR_LGOFF: string = 'Low Gravity Mode Off';

  STSTR_KEYSADDED: string = 'Keys Added';
  STSTR_KFAADDED: string = 'Very Happy Ammo Added';
  STSTR_FAADDED: string = 'Ammo (no keys) Added';

  STSTR_NCON: string = 'No Clipping Mode ON';
  STSTR_NCOFF: string = 'No Clipping Mode OFF';

  STSTR_BEHOLD: string = 'inVuln, Str, Inviso, Rad, Allmap, or Lite-amp';
  STSTR_BEHOLDX: string = 'Power-up Toggled';

  STSTR_CHOPPERS: string = '... doesn''t suck - GM';
  STSTR_CLEV: string = 'Changing Level...';

  STSTR_WLEV: string = 'Level specified not found';

  STSTR_MASSACRE: string = 'Massacre';

//
// F_Finale.C
//
  E1TEXT: string =
    'Once you beat the big badasses and' + #13#10 +
    'clean out the moon base you''re supposed' + #13#10 +
    'to win, aren''t you? Aren''t you? Where''s' + #13#10 +
    'your fat reward and ticket home? What' + #13#10 +
    'the hell is this? It''s not supposed to' + #13#10 +
    'end this way!' + #13#10 +
    ' ' + #13#10 +
    'It stinks like rotten meat, but looks' + #13#10 +
    'like the lost Deimos base.  Looks like' + #13#10 +
    'you''re stuck on The Shores of Hell.' + #13#10 +
    'The only way out is through.' + #13#10 +
    ' ' + #13#10 +
    'To continue the DOOM experience, play' + #13#10 +
    'The Shores of Hell and its amazing' + #13#10 +
    'sequel, Inferno!' + #13#10;

  E2TEXT: string =
    'You''ve done it! The hideous cyber-' + #13#10 +
    'demon lord that ruled the lost Deimos' + #13#10 +
    'moon base has been slain and you' + #13#10 +
    'are triumphant! But ... where are' + #13#10 +
    'you? You clamber to the edge of the' + #13#10 +
    'moon and look down to see the awful' + #13#10 +
    'truth.' + #13#10 +
    ' ' + #13#10 +
    'Deimos floats above Hell itself!' + #13#10 +
    'You''ve never heard of anyone escaping' + #13#10 +
    'from Hell, but you''ll make the bastards' + #13#10 +
    'sorry they ever heard of you! Quickly,' + #13#10 +
    'you rappel down to  the surface of' + #13#10 +
    'Hell.' + #13#10 +
    ' ' + #13#10 +
    'Now, it''s on to the final chapter of' + #13#10 +
    'DOOM! -- Inferno.';

  E3TEXT: string =
    'The loathsome spiderdemon that' + #13#10 +
    'masterminded the invasion of the moon' + #13#10 +
    'bases and caused so much death has had' + #13#10 +
    'its ass kicked for all time.' + #13#10 +
    '' + #13#10 +
    'A hidden doorway opens and you enter.' + #13#10 +
    'You''ve proven too tough for Hell to' + #13#10 +
    'contain, and now Hell at last plays' + #13#10 +
    'fair -- for you emerge from the door' + #13#10 +
    'to see the green fields of Earth!' + #13#10 +
    'Home at last.' + #13#10 +
    ' ' + #13#10 +
    'You wonder what''s been happening on' + #13#10 +
    'Earth while you were battling evil' + #13#10 +
    'unleashed. It''s good that no Hell-' + #13#10 +
    'spawn could have come through that' + #13#10 +
    'door with you ...';

  E4TEXT: string =
    'the spider mastermind must have sent forth' + #13#10 +
    'its legions of hellspawn before your' + #13#10 +
    'final confrontation with that terrible' + #13#10 +
    'beast from hell.  but you stepped forward' + #13#10 +
    'and brought forth eternal damnation and' + #13#10 +
    'suffering upon the horde as a true hero' + #13#10 +
    'would in the face of something so evil.' + #13#10 +
    ' ' + #13#10 +
    'besides, someone was gonna pay for what' + #13#10 +
    'happened to daisy, your pet rabbit.' + #13#10 +
    ' ' + #13#10 +
    'but now, you see spread before you more' + #13#10 +
    'potential pain and gibbitude as a nation' + #13#10 +
    'of demons run amok among our cities.' + #13#10 +
    ' ' + #13#10 +
    'next stop, hell on earth!';

// after level 6, put this:

  C1TEXT: string =
    'YOU HAVE ENTERED DEEPLY INTO THE INFESTED' + #13#10 +
    'STARPORT. BUT SOMETHING IS WRONG. THE' + #13#10 +
    'MONSTERS HAVE BROUGHT THEIR OWN REALITY' + #13#10 +
    'WITH THEM, AND THE STARPORT''S TECHNOLOGY' + #13#10 +
    'IS BEING SUBVERTED BY THEIR PRESENCE.' + #13#10 +
    ' ' + #13#10 +
    'AHEAD, YOU SEE AN OUTPOST OF HELL, A' + #13#10 +
    'FORTIFIED ZONE. IF YOU CAN GET PAST IT,' + #13#10 +
    'YOU CAN PENETRATE INTO THE HAUNTED HEART' + #13#10 +
    'OF THE STARBASE AND FIND THE CONTROLLING' + #13#10 +
    'SWITCH WHICH HOLDS EARTH''S POPULATION' + #13#10 +
    'HOSTAGE.';

// After level 11, put this:

  C2TEXT: string =
    'YOU HAVE WON! YOUR VICTORY HAS ENABLED' + #13#10 +
    'HUMANKIND TO EVACUATE EARTH AND ESCAPE' + #13#10 +
    'THE NIGHTMARE.  NOW YOU ARE THE ONLY' + #13#10 +
    'HUMAN LEFT ON THE FACE OF THE PLANET.' + #13#10 +
    'CANNIBAL MUTATIONS, CARNIVOROUS ALIENS,' + #13#10 +
    'AND EVIL SPIRITS ARE YOUR ONLY NEIGHBORS.' + #13#10 +
    'YOU SIT BACK AND WAIT FOR DEATH, CONTENT' + #13#10 +
    'THAT YOU HAVE SAVED YOUR SPECIES.' + #13#10 +
    ' ' + #13#10 +
    'BUT THEN, EARTH CONTROL BEAMS DOWN A' + #13#10 +
    'MESSAGE FROM SPACE: ''SENSORS HAVE LOCATED' + #13#10 +
    'THE SOURCE OF THE ALIEN INVASION. IF YOU' + #13#10 +
    'GO THERE, YOU MAY BE ABLE TO BLOCK THEIR' + #13#10 +
    'ENTRY.  THE ALIEN BASE IS IN THE HEART OF' + #13#10 +
    'YOUR OWN HOME CITY, NOT FAR FROM THE' + #13#10 +
    'STARPORT.'' SLOWLY AND PAINFULLY YOU GET' + #13#10 +
    'UP AND RETURN TO THE FRAY.';

// After level 20, put this:

  C3TEXT: string =
    'YOU ARE AT THE CORRUPT HEART OF THE CITY,' + #13#10 +
    'SURROUNDED BY THE CORPSES OF YOUR ENEMIES.' + #13#10 +
    'YOU SEE NO WAY TO DESTROY THE CREATURES' + #13#10 +
    'ENTRYWAY ON THIS SIDE, SO YOU CLENCH YOUR' + #13#10 +
    'TEETH AND PLUNGE THROUGH IT.' + #13#10 +
    ' ' + #13#10 +
    'THERE MUST BE A WAY TO CLOSE IT ON THE' + #13#10 +
    'OTHER SIDE. WHAT DO YOU CARE IF YOU''VE' + #13#10 +
    'GOT TO GO THROUGH HELL TO GET TO IT?';

// After level 29, put this:

  C4TEXT: string =
    'THE HORRENDOUS VISAGE OF THE BIGGEST' + #13#10 +
    'DEMON YOU''VE EVER SEEN CRUMBLES BEFORE' + #13#10 +
    'YOU, AFTER YOU PUMP YOUR ROCKETS INTO' + #13#10 +
    'HIS EXPOSED BRAIN. THE MONSTER SHRIVELS' + #13#10 +
    'UP AND DIES, ITS THRASHING LIMBS' + #13#10 +
    'DEVASTATING UNTOLD MILES OF HELL''S' + #13#10 +
    'SURFACE.' + #13#10 +
    ' ' + #13#10 +
    'YOU''VE DONE IT. THE INVASION IS OVER.' + #13#10 +
    'EARTH IS SAVED. HELL IS A WRECK. YOU' + #13#10 +
    'WONDER WHERE BAD FOLKS WILL GO WHEN THEY' + #13#10 +
    'DIE, NOW. WIPING THE SWEAT FROM YOUR' + #13#10 +
    'FOREHEAD YOU BEGIN THE LONG TREK BACK' + #13#10 +
    'HOME. REBUILDING EARTH OUGHT TO BE A' + #13#10 +
    'LOT MORE FUN THAN RUINING IT WAS.' + #13#10;

// Before level 31, put this:

  C5TEXT: string =
    'CONGRATULATIONS, YOU''VE FOUND THE SECRET' + #13#10 +
    'LEVEL! LOOKS LIKE IT''S BEEN BUILT BY' + #13#10 +
    'HUMANS, RATHER THAN DEMONS. YOU WONDER' + #13#10 +
    'WHO THE INMATES OF THIS CORNER OF HELL' + #13#10 +
    'WILL BE.';

// Before level 32, put this:

  C6TEXT: string =
    'CONGRATULATIONS, YOU''VE FOUND THE' + #13#10 +
    'SUPER SECRET LEVEL!  YOU''D BETTER' + #13#10 +
    'BLAZE THROUGH THIS ONE!' + #13#10;

// after map 06

  P1TEXT: string =
    'You gloat over the steaming carcass of the' + #13#10 +
    'Guardian.  With its death, you''ve wrested' + #13#10 +
    'the Accelerator from the stinking claws' + #13#10 +
    'of Hell.  You relax and glance around the' + #13#10 +
    'room.  Damn!  There was supposed to be at' + #13#10 +
    'least one working prototype, but you can''t' + #13#10 +
    'see it. The demons must have taken it.' + #13#10 +
    ' ' + #13#10 +
    'You must find the prototype, or all your' + #13#10 +
    'struggles will have been wasted. Keep' + #13#10 +
    'moving, keep fighting, keep killing.' + #13#10 +
    'Oh yes, keep living, too.';

// after map 11

  P2TEXT: string =
    'Even the deadly Arch-Vile labyrinth could' + #13#10 +
    'not stop you, and you''ve gotten to the' + #13#10 +
    'prototype Accelerator which is soon' + #13#10 +
    'efficiently and permanently deactivated.' + #13#10 +
    ' ' + #13#10 +
    'You''re good at that kind of thing.';

// after map 20

  P3TEXT: string =
    'You''ve bashed and battered your way into' + #13#10 +
    'the heart of the devil-hive.  Time for a' + #13#10 +
    'Search-and-Destroy mission, aimed at the' + #13#10 +
    'Gatekeeper, whose foul offspring is' + #13#10 +
    'cascading to Earth.  Yeah, he''s bad. But' + #13#10 +
    'you know who''s worse!' + #13#10 +
    ' ' + #13#10 +
    'Grinning evilly, you check your gear, and' + #13#10 +
    'get ready to give the bastard a little Hell' + #13#10 +
    'of your own making!';

// after map 30

  P4TEXT: string =
    'The Gatekeeper''s evil face is splattered' + #13#10 +
    'all over the place.  As its tattered corpse' + #13#10 +
    'collapses, an inverted Gate forms and' + #13#10 +
    'sucks down the shards of the last' + #13#10 +
    'prototype Accelerator, not to mention the' + #13#10 +
    'few remaining demons.  You''re done. Hell' + #13#10 +
    'has gone back to pounding bad dead folks ' + #13#10 +
    'instead of good live ones.  Remember to' + #13#10 +
    'tell your grandkids to put a rocket' + #13#10 +
    'launcher in your coffin. If you go to Hell' + #13#10 +
    'when you die, you''ll need it for some' + #13#10 +
    'final cleaning-up ...';

// before map 31

  P5TEXT: string =
    'You''ve found the second-hardest level we' + #13#10 +
    'got. Hope you have a saved game a level or' + #13#10 +
    'two previous.  If not, be prepared to die' + #13#10 +
    'aplenty. For master marines only.';

// before map 32

  P6TEXT: string =
    'Betcha wondered just what WAS the hardest' + #13#10 +
    'level we had ready for ya?  Now you know.' + #13#10 +
    'No one gets out alive.';

  T1TEXT: string =
    'You''ve fought your way out of the infested' + #13#10 +
    'experimental labs.   It seems that UAC has' + #13#10 +
    'once again gulped it down.  With their' + #13#10 +
    'high turnover, it must be hard for poor' + #13#10 +
    'old UAC to buy corporate health insurance' + #13#10 +
    'nowadays..' + #13#10 +
    ' ' + #13#10 +
    'Ahead lies the military complex, now' + #13#10 +
    'swarming with diseased horrors hot to get' + #13#10 +
    'their teeth into you. With luck, the' + #13#10 +
    'complex still has some warlike ordnance' + #13#10 +
    'laying around.';

  T2TEXT: string =
    'You hear the grinding of heavy machinery' + #13#10 +
    'ahead.  You sure hope they''re not stamping' + #13#10 +
    'out new hellspawn, but you''re ready to' + #13#10 +
    'ream out a whole herd if you have to.' + #13#10 +
    'They might be planning a blood feast, but' + #13#10 +
    'you feel about as mean as two thousand' + #13#10 +
    'maniacs packed into one mad killer.' + #13#10 +
    ' ' + #13#10 +
    'You don''t plan to go down easy.';

  T3TEXT: string =
    'The vista opening ahead looks real damn' + #13#10 +
    'familiar. Smells familiar, too -- like' + #13#10 +
    'fried excrement. You didn''t like this' + #13#10 +
    'place before, and you sure as hell ain''t' + #13#10 +
    'planning to like it now. The more you' + #13#10 +
    'brood on it, the madder you get.' + #13#10 +
    'Hefting your gun, an evil grin trickles' + #13#10 +
    'onto your face. Time to take some names.';

  T4TEXT: string =
    'Suddenly, all is silent, from one horizon' + #13#10 +
    'to the other. The agonizing echo of Hell' + #13#10 +
    'fades away, the nightmare sky turns to' + #13#10 +
    'blue, the heaps of monster corpses start ' + #13#10 +
    'to evaporate along with the evil stench ' + #13#10 +
    'that filled the air. Jeeze, maybe you''ve' + #13#10 +
    'done it. Have you really won?' + #13#10 +
    ' ' + #13#10 +
    'Something rumbles in the distance.' + #13#10 +
    'A blue light begins to glow inside the' + #13#10 +
    'ruined skull of the demon-spitter.';

  T5TEXT: string =
    'What now? Looks totally different. Kind' + #13#10 +
    'of like King Tut''s condo. Well,' + #13#10 +
    'whatever''s here can''t be any worse' + #13#10 +
    'than usual. Can it?  Or maybe it''s best' + #13#10 +
    'to let sleeping gods lie..';

  T6TEXT: string =
    'Time for a vacation. You''ve burst the' + #13#10 +
    'bowels of hell and by golly you''re ready' + #13#10 +
    'for a break. You mutter to yourself,' + #13#10 +
    'Maybe someone else can kick Hell''s ass' + #13#10 +
    'next time around. Ahead lies a quiet town,' + #13#10 +
    'with peaceful flowing water, quaint' + #13#10 +
    'buildings, and presumably no Hellspawn.' + #13#10 +
    ' ' + #13#10 +
    'As you step off the transport, you hear' + #13#10 +
    'the stomp of a cyberdemon''s iron shoe.';

const
//
// Character cast strings F_FINALE.C
//
  CC_ZOMBIE  = 'ZOMBIEMAN';
  CC_SHOTGUN = 'SHOTGUN GUY';
  CC_HEAVY = 'HEAVY WEAPON DUDE';
  CC_IMP = 'IMP';
  CC_DEMON = 'DEMON';
  CC_LOST = 'LOST SOUL';
  CC_CACO = 'CACODEMON';
  CC_HELL = 'HELL KNIGHT';
  CC_BARON = 'BARON OF HELL';
  CC_ARACH = 'ARACHNOTRON';
  CC_PAIN = 'PAIN ELEMENTAL';
  CC_REVEN = 'REVENANT';
  CC_MANCU = 'MANCUBUS';
  CC_ARCH = 'ARCH-VILE';
  CC_SPIDER = 'THE SPIDER MASTERMIND';
  CC_CYBER = 'THE CYBERDEMON';
  CC_HERO = 'OUR HERO';

var
  MSG_MODIFIEDGAME: string =
      '===========================================================================' + #13#10 +
      '                ATTENTION:  This version has been modified.' + #13#10 +
      '===========================================================================' + #13#10;

  MSG_SHAREWARE: string =
        '===========================================================================' + #13#10 +
        '                                Shareware!' + #13#10 +
        '===========================================================================' + #13#10;

  MSG_COMMERCIAL: string =
        '===========================================================================' + #13#10 +
        '                 Commercial product - do not distribute!' + #13#10 +
        '===========================================================================' + #13#10;

  MSG_UNDETERMINED: string =
        '===========================================================================' + #13#10 +
        '                       Undetermined version! (Ouch)' + #13#10 +
        '===========================================================================' + #13#10;

var
  S_NIGHTVISION_DEPLETED: string = 'Night Vision Depleted';
  S_RAPID_ENERGY_DEPLETED: string = 'Rapid Energy Depleted';
  S_RAPID_SHIELD_DEPLETED: string = 'Rapid Shield Depleted';
  S_MANEUVER_JETS_DEPLETED: string = 'Maneuver Jets Depleted';
  S_ULTRA_SHIELDS_DEPLETED: string = 'Ultra Shields Depleted';
  S_ALDS_DEPLETED: string = 'A.L.D.S. Depleted';

var
  S_PRESS_SPACE_RESTART: string =
    'PRESS SPACE' + #13#10 +
    'TO RESTART LEVEL';

implementation

end.

