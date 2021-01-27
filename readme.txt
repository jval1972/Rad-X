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

This is an engine remake of the 1995 game "Radix: Beyond the void".
You will need RADIX.DAT file to play the game.
Works with radix v2 remix edition.

History
-------
2021027 - v.1.0.15.747.r923
---------------------------
Fixed rotating textures OpenGL bug.
Can use flac & ogg sound files for sound effects.
Actor's tracer available in PascalScript.
Added Overlay.DrawLine & OverlayDrawLine PascalScript functions. params -> (const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer)
Added overlaydrawline console command. Usage is overlaydrawline [ticks] [x1] [y1] [x2] [y2] [red] [green] [blue].
Added Overlay.DrawRect & OverlayDrawRect PascalScript functions. params -> (const ticks: Integer; const red, green, blue: byte; const x1, y1, x2, y2: Integer)
Added overlaydrawrect console command. Usage is overlaydrawrect [ticks] [x1] [y1] [x2] [y2] [red] [green] [blue].
Added overlaydrawpatch console command, usage is "overlaydrawpatch [ticks] [x] [y] [patch]".
Added Overlay.DrawPatchStretched & OverlayDrawPatchStretched PascalScript functions. params -> (const ticks: Integer; const patchname: string; const x1, y1, x2, y2: Integer)
Added overlaydrawpatchstretched console command. Usage is overlaydrawpatchstretched [ticks] [x1] [y1] [x2] [y2] [patch].
Fixed problem with Overlay display after changing screen dimentions

2021010 - v.1.0.14.746.r914
---------------------------
Floor and ceiling texure angle corrections.
Texture angle in 3d floors.
Key bindings can now accept SHIFT & CTRL keys.
Easy angle things, rotate floor or ceiling texture around them.
Fixed secondcooland, coolandgenerator & splashes sprites disappear. The problem appeared in v.1.0.1.745.r873 (origins in loading speed optimizations)
Corrected menu Save/Load screenshot in OpenGL mode.
Floor and Ceiling angle properties available from PascalScipt.
Interpolate dynamic floor and ceiling texture rotation.
PascalScript can access keyboard, mouse keys and joystick keys. The access is allowed only in single player and while not record or playing demo.
Interpolate dynamic slopes (for uncapped framerate).
Avoid crash in OpenGL mode if sprite frames are missing.
Fixed potential DEHACKED conflict with demo playback.
Corrected DEHACKED export to ACTORDEF (renderstyle field).
No delay to return to desktop when finished.

20201228 - v.1.0.1.745.r873
---------------------------
Speed improvements to slope rendering (Software rendering).
Corrected serious bug in OpenGL branch (could not handle correctly large maps).
use_fog default (OpenGL) defaults to false.
Shade model in OpenGL defaults to GL_FLAT.
Blockmap consistancy in T_Pusher().
Does not recalc texture mapping tables if focallength has not changed.
Corrections to Doom patch detection algorithm.
Check for erronous width & height in command line parameter -geom.
Fixed ripple effect in large flats.
Corrected lump name character case for runtime loading.

20201211 - v.1.0.1.744.r852
---------------------------
Fixed memory corruption problems with the music playback thread.
Fixed potential me﻿mory corruption problem when loading WADs without a PNAMES lump.
Fixed potential memory corruption problem when working with the original data file, or a WAD file that does not contain a disk busy patch. (STCDROM or STDISK).
Fixed potential memory corruption problem when taking screenshots in OpenGL mode.
Fixed potential error with the shareware data file of RADIX.
Prevents infinite loop for erronous A_Chase() placement ﻿
Corrected dehacked parsing of the "CODEP FRAME" keyword ﻿
Loads a bit faster due to some optimizations. 
Fixed diskbuzy height calculation in OpenGL mode.

20201202 - v.1.0.1﻿.742.r838
---------------------------
Fixed problem in hud related to the OpenGL texture matrix.

20201202 - v.1.0.1﻿.742.r833
---------------------------
Fixed bug with score table sorting.

20201130 - v.1.0.1.741.r831
---------------------------
Added a new executable (RadGL.exe) with OpenGL rendering. It will run even with an Intel HD graphics card.
Improvements to the multi-th﻿reading software rendering
Key bindings for Automap actions ﻿

20200615 - v.1.0.1.739.r807
---------------------------
Fixed problem with inter-process communication with glbsp, the error was occurring when Rad was running from a directory with spaces in it's filename.

20200608 - v.1.0.1.739.r804
---------------------------
Support for flats with dimensions 2048x2048
Added support for (the forgotten) Afterburn key
Autorun mode is on by default (but the name has not changed yet) 
Gameplay compatibility options:
 - Player weapon damage (challenging/vanilla)
 - Neutron Cannon L1 vanilla fire (Yes/No)
 - Plasma Spreader L1 vanilla fire (Yes/No)
 - Fast weapon refire (Yes/No) ﻿
 - Barrel death explosion (Small/Big) ﻿
 - Drone death explosion (Small/Big) ﻿

20200530 - v.1.0.1.738﻿.r788
---------------------------
HUD displays player's keys (all 6 of them).
Important features of RADIX can now be used with classic Doom mapping tools: Forcefields (sector based), and various types of destructible lines.
Fixes/improvements i﻿n slope rendering
Fixes/improvements in 3d floors rendering
Support for ANIMDEFS lump
Support for flats with dimensions up to 1024x1024 px
New (easy)slope definition mechanism, slope a floor or ceiling by defining 3 points (things), or slope a vertex with a single thing to apply slope on all nearby triangle sectors. The new things are using the angle to identify the strength of the effect.
Dynamic slopes can be controlled by PascalScript.
Fixes to voxel clipping
A lot of other fixes to improve stability 

20200515 - v.1.0.1.737.r723
---------------------------
It is able to load DOOM.WAD and play Doom levels.

20200509 - v.1.0.1.737.r667
---------------------------
First public release
