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
// DESCRIPTION:
//   Menu widget stuff, episode selection and such.
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit m_menu;

interface

uses
  d_event;

//
// MENUS
//

{ Called by main loop, }
{ saves config file and calls I_Quit when user exits. }
{ Even when the menu is not displayed, }
{ this can resize the view and change game parameters. }
{ Does all the real work of the menu interaction. }

function M_Responder(ev: Pevent_t): boolean;

{ Called by main loop, }
{ draws the menus directly into the screen buffer. }
procedure M_Drawer;

{ Called by D_DoomMain, }
{ loads the config file. }
procedure M_Init;

{ Called by intro code to force menu up upon a keypress, }
{ does nothing if menu is already up. }
procedure M_StartControlPanel;

var
//
// defaulted values
//
  mouseSensitivity: integer;  // has default
  mouseSensitivityX: integer;
  mouseSensitivityY: integer;

// Show messages has default, 0 = off, 1 = on
  showMessages: integer;

  shademenubackground: integer;

  keepsavegamename: boolean;

  menuactive: boolean;

  inhelpscreens: boolean;

  menubackgroundflat: string = 'RDXF0000';

const
  DEFMENUBACKGROUNDFLAT = 'RDXF0000';

procedure M_ShutDownMenus;

procedure M_InitMenus;

procedure M_SetKeyboardMode(const mode: integer);

implementation

uses
  d_delphi,
  doomstat,
  doomdef,
  am_map,
  c_cmds,
  dstrings,
  d_englsh,
  d_main,
  d_player,
  d_notifications,
  g_game,
  g_gameplay,
  m_argv,
  m_misc,
  m_fixed,
  mn_font,
  mn_screenshot,
  mt_utils,
  i_system,
  i_threads,
  i_io,
  i_mp3,
  i_sound,
  i_displaymodes,
{$IFDEF OPENGL}
  gl_main,
  gl_defs,
  gl_models,
  gl_voxels,
  gl_lightmaps,
  gl_shadows,
  gl_tex,
{$ELSE}
  i_video,
  r_batchcolumn,
  r_scale,
  r_slopes, // JVAL: Slopes
{$ENDIF}
  e_endoom,
  p_setup,
  p_mobj_h,
  p_terrain,
  p_enemy,
  p_user,
  p_adjust,
  radix_hud,
  radix_sounds,
  radix_score,
  r_aspect,
  r_data,
  r_defs,
  r_main,
  r_hires,
  r_lights,
  r_intrpl,
{$IFNDEF OPENGL}
  r_fake3d,
  r_softlights,
{$ENDIF}
  r_camera,
  r_draw,
  r_sky,
  t_main,
  vx_voxelsprite,
  v_data,
  v_video,
  hu_stuff,
  s_sound,
  sounds,
  sound_data,
  w_wad,
  z_zone;

var
// temp for screenblocks (0-9)
  m_screensize: integer;

// -1 = no quicksave slot picked!
  quickSaveSlot: integer;

 // 1 = message to be printed
  messageToPrint: integer;
// ...and here is the message string!
  messageString: string;

  messageLastMenuActive: boolean;

// timed message = no input from user
  messageNeedsInput: boolean;

type
  PmessageRoutine = function(i: integer): pointer;

var
  messageRoutine: PmessageRoutine;


var
  gammamsg: array[0..GAMMASIZE - 1] of string;

// we are going to be entering a savegame string
  saveStringEnter: integer = 0;
  saveSlot: integer;  // which slot to save in
  saveCharIndex: integer; // which char we're editing
// old save description before edit
  saveOldString: string;

var
  p_leftarrow: Ppatch_t;
  p_rightarrow: Ppatch_t;

const
  ARROWXOFFS = -8;
  ARROWYOFFS = -1;
  BIGLINEHEIGHT = 16;
  SAVELOADLINEHEIGHT = 15;
  SMALLLINEHEIGHT = 8;


var
  savegamestrings: array[0..Ord(load_end) - 1] of string;
  savegameshots: array[0..Ord(load_end) - 1] of menuscreenbuffer_t;

type
  menuitem_t = record
    // 0 = no cursor here, 1 = ok, 2 = arrows ok
    status: smallint;

    name: string;
    cmd: string;

    // choice = menu item #.
    // if status = 2,
    //   choice=0:leftarrow,1:rightarrow
    routine: PmessageRoutine;

    // Yes/No location
    pBoolVal: PBoolean;
    // hotkey in menu
    alphaKey: char;
  end;
  Pmenuitem_t = ^menuitem_t;
  menuitem_tArray = packed array[0..$FFFF] of menuitem_t;
  Pmenuitem_tArray = ^menuitem_tArray;

const
  FLG_MN_TEXTUREBK = 1;
  FLG_MN_DRAWITEMON = 2;

type
  Pmenu_t = ^menu_t;
  menu_t = record
    numitems: smallint;         // # of menu items
    prevMenu: Pmenu_t;          // previous menu
    leftMenu: Pmenu_t;          // left menu
    rightMenu: Pmenu_t;         // right menu
    menuitems: Pmenuitem_tArray;// menu items
    drawproc: PProcedure;       // draw routine
    x: smallint;
    y: smallint;                // x,y of menu
    lastOn: smallint;           // last item user was on in menu
    itemheight: integer;
    flags: LongWord;
  end;

var
  itemOn: smallint;             // selected menu item 

// current menudef
  currentMenu: Pmenu_t;

//
//      Menu Functions
//
procedure M_HorzLine(const x1, x2, y: integer; const color: byte);
var
  i: integer;
begin
  for i := y * 320 + x1 to y * 320 + x2 do
    screens[SCN_TMP][i] := color;
end;

procedure M_VertLine(const x, y1, y2: integer; const color: byte);
var
  i: integer;
begin
  for i := y1 to y2 do
    screens[SCN_TMP][i * 320 + x] := color;
end;

procedure M_Frame3d(const x1, y1, x2, y2: integer; const color1, color2, color3: byte);
var
  i: integer;
begin
  M_HorzLine(x1, x2, y1, color1);
  M_HorzLine(x1, x2, y2, color2);
  M_VertLine(x1, y1, y2, color2);
  M_VertLine(x2, y1, y2, color1);
  for i := y1 + 1 to y2 - 1 do
    M_HorzLine(x1 + 1, x2 - 1, i, color3);
end;

procedure M_DrawHeadLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, 64);
  M_HorzLine(0, 319, y + 15, 80);
  for i := y + 1 to y + 14 do
    M_HorzLine(0, 319, i, 63);

  M_WriteBigTextRedCenter(y, str, SCN_TMP);
end;

procedure M_DrawSubHeadLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, 64);
  M_HorzLine(0, 319, y + 15, 80);
  for i := y + 1 to y + 14 do
    M_HorzLine(0, 319, i, 63);

  M_WriteBigTextGray(25, y, str, SCN_TMP);
end;

procedure M_DrawSmallLine(const y: integer; const str: string);
var
  i: integer;
begin
  M_HorzLine(0, 319, y, 64);
  M_HorzLine(0, 319, y + 9, 80);
  for i := y + 1 to y + 8 do
    M_HorzLine(0, 319, i, 63);

  M_WriteSmallWhiteTextCenter(y + 2, str, SCN_TMP);
end;

const
  DEF_MENU_ITEMS_START_X = 32;
  DEF_MENU_ITEMS_START_Y = 65;

procedure M_DrawThermo(x, y, thermWidth, thermDot: integer; numdots: integer = -1);
var
  i: integer;
  p: integer;
begin
  M_Frame3d(x, y, x + thermWidth * 8 + 2, y + 10, 64, 80, 72);

  if numdots <= 1 then
    numdots := thermWidth;
  if numdots < 2 then
    numdots := 2;
  p := Round(thermDot / (numdots - 1) * thermWidth * 8 + 1);
  for i := 1 to thermWidth * 8 do
    if not odd(i) then
    begin
      if i < p then
        M_VertLine(x + i, y + 2, y + 8, 136)
      else
        M_VertLine(x + i, y + 2, y + 8, 251);
    end;
end;

procedure M_StartMessage(const str: string; routine: PmessageRoutine; const input: boolean);
begin
  messageLastMenuActive := menuactive;
  messageToPrint := 1;
  messageString := str;
  if Assigned(routine) then
    @messageRoutine := @routine
  else
    messageRoutine := nil;
  messageNeedsInput := input;
  mn_makescreenshot := true;
  menuactive := true;
end;

procedure M_StopMessage;
begin
  menuactive := messageLastMenuActive;
  messageToPrint := 0;
end;

//
// M_ClearMenus
//
procedure M_ClearMenus;
begin
  menuactive := false;
end;

//
// M_SetupNextMenu
//
procedure M_SetupNextMenu(menudef: Pmenu_t);
begin
  currentMenu := menudef;
  itemOn := currentMenu.lastOn;
end;

//
// MENU DEFINITIONS
//
type
//
// DOOM MENU
//
  main_e = (
    mm_newgame,
    mm_options,
    mm_loadgame,
    mm_savegame,
    mm_readthis,
    mm_topten,
    mm_quitradix,
    main_end
  );

var
  MainMenu: array[0..Ord(main_end) - 1] of menuitem_t;
  MainDef: menu_t;

type
//
// EPISODE SELECT
//
  episodes_e = (
    ep1,
    ep2,
    ep3,
    ep_end
  );

var
  EpisodeMenu: array[0..Ord(ep_end) - 1] of menuitem_t;
  EpiDef: menu_t;

type
  pilotname_e = (
    pilotname1,
    pn_end
  );

var
  PilotNameMenu: array[0..Ord(pn_end) - 1] of menuitem_t;
  PilotNameDef: menu_t;

var
// we are going to be entering the pilot's name
  pilotStringEnter: integer = 0;
  pilotCharIndex: integer = 0; // which char we're editing
// old pilot name before edit
  pilotOldString: string;

type
//
// NEW GAME
//
  newgame_e = (
    newg_killthings,
    newg_toorough,
    newg_hurtme,
    newg_violence,
    newg_end
  );

var
  NewGameMenu: array[0..Ord(newg_end) - 1] of menuitem_t;
  NewDef: menu_t;

type
//
// OPTIONS MENU
//
  options_e = (
    opt_general,
    opt_display,
    opt_sound,
    opt_gameplay,
    opt_compatibility,
    opt_controls,
    opt_system,
    opt_end
  );

var
  OptionsMenu: array[0..Ord(opt_end) - 1] of menuitem_t;
  OptionsDef: menu_t;

//
// Top Ten
//
type
  topten_e = (
    topten1,
    tt_end
  );

var
  TopTenMenu: array[0..Ord(tt_end) - 1] of menuitem_t;
  TopTenDef: menu_t;

// GENERAL MENU
type
  optionsgeneral_e = (
    endgame,
    messages,
    scrnsize,
    option_empty1,
    mousesens,
    option_empty2,
    optgen_end
  );

var
  OptionsGeneralMenu: array[0..Ord(optgen_end) - 1] of menuitem_t;
  OptionsGeneralDef: menu_t;

// DISPLAY MENU
type
  optionsdisplay_e = (
{$IFDEF OPENGL}
    od_opengl,
{$ELSE}
    od_detail,
{$ENDIF}
    od_automap,
    od_appearance,
    od_advanced,
    od_32bitsetup,
    optdisp_end
  );

var
  OptionsDisplayMenu: array[0..Ord(optdisp_end) - 1] of menuitem_t;
  OptionsDisplayDef: menu_t;

// DISPLAY DETAIL MENU
type
  optionsdisplaydetail_e = (
    od_setvideomode,
    od_detaillevel,
    optdispdetail_end
  );

var
  OptionsDisplayDetailMenu: array[0..Ord(optdispdetail_end) - 1] of menuitem_t;
  OptionsDisplayDetailDef: menu_t;

type
  optionsdisplayvideomode_e = (
    odm_fullscreen,
    odm_screensize,
    odm_filler1,
    odm_filler2,
    odm_setvideomode,
    optdispvideomode_end
  );

var
  OptionsDisplayVideoModeMenu: array[0..Ord(optdispvideomode_end) - 1] of menuitem_t;
  OptionsDisplayVideoModeDef: menu_t;

// DISPLAY APPEARANCE MENU
type
  optionsdisplayappearance_e = (
    od_drawfps,
    od_shademenubackground,
    od_displaydiskbusyicon,
    od_displayendscreen,
    od_showdemoplaybackprogress,
    od_drawcrosshair,
    od_drawkeybar,
    optdispappearance_end
  );

var
  OptionsDisplayAppearanceMenu: array[0..Ord(optdispappearance_end) - 1] of menuitem_t;
  OptionsDisplayAppearanceDef: menu_t;

// DISPLAY AUTOMAP MENU
type
  optionsdisplayautomap_e = (
    od_allowautomapoverlay,
    od_allowautomaprotate,
    od_texturedautomap,
    od_automapgrid,
    optdispautomap_end
  );

var
  OptionsDisplayAutomapMenu: array[0..Ord(optdispautomap_end) - 1] of menuitem_t;
  OptionsDisplayAutomapDef: menu_t;

// DISPLAY ADVANCED MENU
type
  optionsdisplayadvanced_e = (
    od_aspect,
    od_camera,
{$IFNDEF OPENGL}
    od_lightmap,
{$ENDIF}
{$IFNDEF OPENGL}
    od_bltasync,
{$ENDIF}
    od_usetransparentsprites,
{$IFNDEF OPENGL}
    od_diher8bittransparency,
{$ENDIF}
    od_interpolate,
    od_interpolateoncapped,
{$IFNDEF OPENGL}
    od_usefake3d,
{$ENDIF}
    od_fixstallhack,
    od_skydrawmode,
    od_autoadjustmissingtextures,
{$IFNDEF OPENGL}
    od_optimizedcolumnrendering,
    od_optimizedthingsrendering,
    od_precisescalefromglobalangle,
    od_preciseslopedrawing, // JVAL: Slopes
{$ENDIF}
    optdispadvanced_end
  );

var
  OptionsDisplayAdvancedMenu: array[0..Ord(optdispadvanced_end) - 1] of menuitem_t;
  OptionsDisplayAdvancedDef: menu_t;

// DISPLAY ASPECT RATIO MENU
type
  optionsdisplayaspectratio_e = (
    oda_widescreensupport,
    oda_excludewidescreenplayersprites,
    oda_forceaspectratio,
    oda_intermissionaspect,
    optdispaspect_end
  );

var
  OptionsDisplayAspectRatioMenu: array[0..Ord(optdispaspect_end) - 1] of menuitem_t;
  OptionsDisplayAspectRatioDef: menu_t;

//
// DISPLAY CAMERA MENU
type
  optionsdisplaycamera_e = (
    odc_zaxisshift,
    odc_chasecamera,
    odc_chasecameraxy,
    odc_filler3,
    odc_filler4,
    odc_chasecameraz,
    odc_filler5,
    odc_filler6,
    optdispcamera_end
  );

var
  OptionsDisplayCameraMenu: array[0..Ord(optdispcamera_end) - 1] of menuitem_t;
  OptionsDisplayCameraDef: menu_t;

{$IFNDEF OPENGL}
type
  optionslightmap_e = (
    ol_uselightmaps,
    ol_lightmapfunc,
    ol_colorintensity,
    ol_filler1,
    ol_filler2,
    ol_lightwidthfactor,
    ol_filler3,
    ol_filler4,
    od_resettodefaults,
    ol_lightmap_end
  );

var
  OptionsLightmapMenu: array[0..Ord(ol_lightmap_end) - 1] of menuitem_t;
  OptionsLightmapDef: menu_t;
{$ENDIF}

// DISPLAY 32 BIT RENDERING MENU
type
  optionsdisplay32bit_e = (
    od_uselightboost,
    od_forcecolormaps,
    od_32bittexturepaletteeffects,
    od_use32bitfuzzeffect,
    od_useexternaltextures,
    od_preferetexturesnamesingamedirectory,
    optdisp32bit_end
  );

var
  OptionsDisplay32bitMenu: array[0..Ord(optdisp32bit_end) - 1] of menuitem_t;
  OptionsDisplay32bitDef: menu_t;

{$IFDEF OPENGL}
// DISPLAY OPENGL RENDERING MENU
type
  optionsdisplayopengl_e = (
    od_glsetvideomode,
    od_glmodels,
    od_glvoxels,
    od_filter,
    od_usefog,
    {$IFDEF DEBUG}
    od_gl_drawsky,
    {$ENDIF}
    od_gl_stencilsky,
    od_gl_renderwireframe,
    od_gl_uselightmaps,
    od_gl_drawshadows,
    od_gl_add_all_lines,
    od_gl_useglnodesifavailable,
    od_gl_autoloadgwafiles,
    od_gl_screensync,
    optdispopengl_end
  );

var
  OptionsDisplayOpenGLMenu: array[0..Ord(optdispopengl_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLDef: menu_t;

// OpenGL Models
type
  optionsopenglmodels_e = (
    od_glm_drawmodels,
    od_glm_smoothmodelmovement,
    od_glm_precachemodeltextures,
    optglmodels_end
  );

var
  OptionsDisplayOpenGLModelsMenu: array[0..Ord(optglmodels_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLModelsDef: menu_t;

// OpenGL Voxels
type
  optionsopenglvoxels_e = (
    od_glv_drawvoxels,
    od_glv_optimize,
    {$IFDEF DEBUG}
    od_glv_pritesfromvoxels,
    {$ENDIF}
    optglvoxels_end
  );

var
  OptionsDisplayOpenGLVoxelsMenu: array[0..Ord(optglvoxels_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLVoxelsDef: menu_t;

// OpenGL Texture Filtering
type
  optionsopenglfilter_e = (
    od_glf_texture_filter,
    od_glf_texture_filter_anisotropic,
    od_glf_linear_hud,
    optglfilter_end
  );

var
  OptionsDisplayOpenGLFilterMenu: array[0..Ord(optglfilter_end) - 1] of menuitem_t;
  OptionsDisplayOpenGLFilterDef: menu_t;
{$ENDIF}


type
//
// Read This! MENU 1 & 2
//
  read_e = (
    rdthsempty1,
    read1_end
  );

var
  ReadMenu1: array[0..0] of menuitem_t;
  ReadDef1: menu_t;

type
  read_e2 = (
    rdthsempty2,
    read2_end
  );

var
  ReadMenu2: array[0..0] of menuitem_t;
  ReadDef2: menu_t;

//  https://www.doomworld.com/forum/topic/111465-boom-extended-help-screens-an-undocumented-feature/
// JVAL 20200122 - Extended help screens
var
  extrahelpscreens: TDNumberList;
  extrahelpscreens_idx: integer = -1;

type
  read_ext = (
    rdthsemptyext,
    readext_end
  );

var
  ReadMenuExt: array[0..0] of menuitem_t;
  ReadDefExt: menu_t;


type
//
// SOUND MENU
//
  sound_e = (
    snd_volume,
    snd_usemp3,
    snd_preferemp3namesingamedirectory,
    snd_usewav,
    snd_preferewavnamesingamedirectory,
    sound_end
  );

var
  SoundMenu: array[0..Ord(sound_end) - 1] of menuitem_t;
  SoundDef: menu_t;

type
//
// SOUND VOLUME MENU
//
  soundvol_e = (
    sfx_vol,
    sfx_empty1,
    sfx_empty2,
    music_vol,
    sfx_empty3,
    sfx_empty4,
    soundvol_end
  );

var
  SoundVolMenu: array[0..Ord(soundvol_end) - 1] of menuitem_t;
  SoundVolDef: menu_t;

type
//
// COMPATIBILITY MENU
//
  compatibility_e = (
    cmp_allowplayerjumps,
    cmp_allowplayerbreath,
    cmp_keepcheatsinplayerrebord,
    cmp_majorbossdeathendsdoom1level,
    cmp_spawnrandommonsters,
    cmp_allowterrainsplashes,
    cmp_continueafterplayerdeath,
    cmp_drones,
    cmp_end
  );

var
  CompatibilityMenu: array[0..Ord(cmp_end) - 1] of menuitem_t;
  CompatibilityDef: menu_t;

type
//
// GAMEPLAY MENU
//
  gameplaymenu_e = (
    gmp_vanillaplayerweapondamage,
    gmp_vanillal1neutroncannon,
    gmp_vanillal1plasmaspreader,
    gmp_fastweaponrefire,
    gmp_barrelexplode,
    gmp_droneexplode,
    gmp_end
  );

var
  GameplayMenu: array[0..Ord(gmp_end) - 1] of menuitem_t;
  GameplayDef: menu_t;

type
//
// CONTROLS MENU
//
  controls_e = (
    ctrl_usemouse,
    ctrl_invertmouselook,
    ctrl_invertmouseturn,
    cttl_mousesensitivity,
    ctrl_usejoystic,
    ctrl_autorun,
    ctrl_keyboardmode,
    ctrl_keybindings,
    ctrl_end
  );

var
  ControlsMenu: array[0..Ord(ctrl_end) - 1] of menuitem_t;
  ControlsDef: menu_t;

type
//
// MOUSE SENSITIVITY MENU
//
  sensitivity_e = (
    sens_mousesensitivity,
    sens_empty1,
    sens_empty2,
    sens_mousesensitivityx,
    sens_empty3,
    sens_empty4,
    sens_mousesensitivityy,
    sens_empty5,
    sens_empty6,
    sens_end
  );

var
  SensitivityMenu: array[0..Ord(sens_end) - 1] of menuitem_t;
  SensitivityDef: menu_t;


type
//
// KEY BINDINGS MENU
//
  keybindings_e = (
    kb_up,
    kb_down,
    kb_left,
    kb_right,
    kb_strafeleft,
    kb_straferight,
    kb_flyup,
    kb_flydown,
    kb_fire,
    kb_use,
    kb_strafe,
    bk_afterburner,
    kb_speed,

    kb_lookup,
    kb_lookdown,
    kb_lookcenter,
    kb_lookleft,
    kb_lookright,
    kb_weapon0,
    kb_weapon1,
    kb_weapon2,
    kb_weapon3,
    kb_weapon4,
    kb_weapon5,
    kb_weapon6,
    kb_weapon7,
    kb_plasmabomb,

    kb_am_gobigkey,
    kb_am_followkey,
    kb_am_gridkey,
    kb_am_rotatekey,
    kb_am_texturedautomap,
    kb_am_markkey,
    kb_am_clearmarkkey,

    kb_end
  );

var
  KeyBindingsMenu1: array[0..Ord(kb_lookup) - 1] of menuitem_t;
  KeyBindingsDef1: menu_t;
  KeyBindingsMenu2: array[0..Ord(kb_am_gobigkey) - Ord(kb_lookup) - 1] of menuitem_t;
  KeyBindingsDef2: menu_t;
  KeyBindingsMenu3: array[0..Ord(kb_end) - Ord(kb_am_gobigkey) - 1] of menuitem_t;
  KeyBindingsDef3: menu_t;

type
  bindinginfo_t = record
    text: string[25];
    pkey: PInteger;
  end;

const
  KeyBindingsInfo: array [0..Ord(kb_end) - 1] of bindinginfo_t = (
    (text: 'Move forward'; pkey: @key_up),
    (text: 'Move backward'; pkey: @key_down),
    (text: 'Turn left'; pkey: @key_left),
    (text: 'Turn right'; pkey: @key_right),
    (text: 'Strafe left'; pkey: @key_strafeleft),
    (text: 'Strafe right'; pkey: @key_straferight),
    (text: 'Fly up'; pkey: @key_flyup),
    (text: 'Fly down'; pkey: @key_flydown),
    (text: 'Fire'; pkey: @key_fire),
    (text: 'Use'; pkey: @key_use),
    (text: 'Strafe'; pkey: @key_strafe),
    (text: 'Afterburner'; pkey: @key_afterburner),
    (text: 'Run'; pkey: @key_speed),

    (text: 'Look up'; pkey: @key_lookup),
    (text: 'Look down'; pkey: @key_lookdown),
    (text: 'Look center'; pkey: @key_lookcenter),
    (text: 'Look left'; pkey: @key_lookleft),
    (text: 'Look right'; pkey: @key_lookright),
    (text: 'Neutron Cannon'; pkey: @key_weapon0),
    (text: 'Standard EPC'; pkey: @key_weapon1),
    (text: 'Plasma Spreader'; pkey: @key_weapon2),
    (text: 'Seeking Missiles'; pkey: @key_weapon3),
    (text: 'Nuke'; pkey: @key_weapon4),
    (text: 'Phase Torpedoes'; pkey: @key_weapon5),
    (text: 'Gravity Device'; pkey: @key_weapon6),
    (text: 'Enhanced EPC'; pkey: @key_weapon7),
    (text: 'Plasma Bomb'; pkey: @key_plasmabomb),

    (text: 'Automap max zoom'; pkey: @AM_GOBIGKEY),
    (text: 'Automap follow on/off'; pkey: @AM_FOLLOWKEY),
    (text: 'Automap grid on/off'; pkey: @AM_GRIDKEY),
    (text: 'Automap rotate on/off'; pkey: @AM_ROTATEKEY),
    (text: 'Automap texture on/off'; pkey: @AM_TEXTUREDAUTOMAP),
    (text: 'Automap add mark'; pkey: @AM_MARKKEY),
    (text: 'Automap clear mark'; pkey: @AM_CLEARMARKKEY)
  );

var
  bindkeyEnter: boolean;
  bindkeySlot: integer;
  saveOldkey: integer;

function M_KeyToString(const k: integer): string;
begin
  if (k >= 33) and (k <= 126) then
  begin
    result := Chr(k);
    if result = '=' then
      result := '+'
    else if result = ',' then
      result := '<'
    else if result = '.' then
      result := '>';
    exit;
  end;

  case k of
    32: result := 'SPACE';
    KEY_RIGHTARROW: result := 'RIGHTARROW';
    KEY_LEFTARROW: result := 'LEFTARROW';
    KEY_UPARROW: result := 'UPARROW';
    KEY_DOWNARROW: result := 'DOWNARROW';
    KEY_ESCAPE: result := 'ESCAPE';
    KEY_ENTER: result := 'ENTER';
    KEY_TAB: result := 'TAB';
    KEY_F1: result := 'F1';
    KEY_F2: result := 'F2';
    KEY_F3: result := 'F3';
    KEY_F4: result := 'F4';
    KEY_F5: result := 'F5';
    KEY_F6: result := 'F6';
    KEY_F7: result := 'F7';
    KEY_F8: result := 'F8';
    KEY_F9: result := 'F9';
    KEY_F10: result := 'F10';
    KEY_F11: result := 'F11';
    KEY_F12: result := 'F12';
    KEY_PRNT: result := 'PRNT';
    KEY_CON: result := 'CON';
    KEY_BACKSPACE: result := 'BACKSPACE';
    KEY_PAUSE: result := 'PAUSE';
    KEY_EQUALS: result := 'EQUALS';
    KEY_MINUS: result := 'MINUS';
    KEY_RSHIFT: result := 'SHIFT';
    KEY_RCTRL: result := 'CTRL';
    KEY_RALT: result := 'ALT';
    KEY_PAGEDOWN: result := 'PAGEDOWN';
    KEY_PAGEUP: result := 'PAGEUP';
    KEY_INS: result := 'INS';
    KEY_HOME: result := 'HOME';
    KEY_END: result := 'END';
    KEY_DELETE: result := 'DELETE';
  else
    result := '';
  end;
end;

function M_SetKeyBinding(const slot: integer; key: integer): boolean;
var
  i: integer;
  oldk: integer;
begin
  if (slot < 0) or (slot >= Ord(kb_end)) then
  begin
    result := false;
    exit;
  end;

  if key = 16 then
    key := KEY_RSHIFT
  else if key = 17 then
    key := KEY_RCTRL
  else if key = 18 then
    key := KEY_RALT;

  result := key in [32..125,
    KEY_RIGHTARROW,
    KEY_LEFTARROW,
    KEY_UPARROW,
    KEY_DOWNARROW,
    KEY_BACKSPACE,
    KEY_RSHIFT,
    KEY_RCTRL,
    KEY_RALT,
    KEY_PAGEDOWN,
    KEY_PAGEUP,
    KEY_INS,
    KEY_HOME,
    KEY_END,
    KEY_DELETE
  ];

  if not result then
    exit;

  oldk := KeyBindingsInfo[slot].pkey^;
  for i := 0 to Ord(kb_end) - 1 do
    if i <> slot then
     if KeyBindingsInfo[i].pkey^ = key then
       KeyBindingsInfo[i].pkey^ := oldk;
  KeyBindingsInfo[slot].pkey^ := key;
end;

procedure M_DrawBindings(const m: menu_t; const start, stop: integer);
var
  i: integer;
  len: integer;
  s: string;
  drawkey: boolean;
begin
  M_DrawHeadLine(15, 'Controls');
  M_DrawSubHeadLine(40, 'Key Bindings');

  for i := 0 to stop - start - 1 do
  begin
    s := KeyBindingsInfo[start + i].text + ': ';
    len := M_SmallStringWidth(s);
    M_WriteSmallText(m.x, m.y + m.itemheight * i, s, SCN_TMP);
    drawkey := true;
    if bindkeyEnter then
      if i = bindkeySlot - start then
        if (gametic div 18) mod 2 <> 0 then
          drawkey := false;
    if drawkey then
      M_WriteSmallWhiteText(m.x + len, m.y + m.itemheight * i, M_KeyToString(KeyBindingsInfo[start + i].pkey^), SCN_TMP);
  end;
end;

procedure M_DrawBindings1;
begin
  M_DrawBindings(KeyBindingsDef1, 0, Ord(kb_lookup));
end;

procedure M_DrawBindings2;
begin
  KeyBindingsInfo[Ord(kb_weapon0)].text := 'Neutron Cannon';
  KeyBindingsInfo[Ord(kb_weapon1)].text := 'Standard EPC';
  KeyBindingsInfo[Ord(kb_weapon2)].text := 'Plasma Spreader';
  KeyBindingsInfo[Ord(kb_weapon3)].text := 'Seeking Missiles';
  KeyBindingsInfo[Ord(kb_weapon4)].text := 'Nuke';
  KeyBindingsInfo[Ord(kb_weapon5)].text := 'Phase Torpedoes';
  KeyBindingsInfo[Ord(kb_weapon6)].text := 'Gravity Device';
  KeyBindingsInfo[Ord(kb_weapon7)].text := 'Enhanced EPC';

  M_DrawBindings(KeyBindingsDef2, Ord(kb_lookup), Ord(kb_am_gobigkey));
end;

procedure M_DrawBindings3;
begin
  M_DrawBindings(KeyBindingsDef3, Ord(kb_am_gobigkey), Ord(kb_end));
end;

//
// Select key binding
//
procedure M_KeyBindingSelect1(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := choice;

  saveOldkey := KeyBindingsInfo[choice].pkey^;
end;

procedure M_KeyBindingSelect2(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := Ord(kb_lookup) + choice;

  saveOldkey := KeyBindingsInfo[Ord(kb_lookup) + choice].pkey^;
end;

procedure M_KeyBindingSelect3(choice: integer);
begin
  bindkeyEnter := true;

  bindkeySlot := Ord(kb_am_gobigkey) + choice;

  saveOldkey := KeyBindingsInfo[Ord(kb_am_gobigkey) + choice].pkey^;
end;

//
// JVAL: 20200420 - In game mission briefing
//
type
  intextmenu_e = (
    intextmenuempty2,
    intextmenu_end
  );

var
  InTextMenu: array[0..Ord(intextmenu_end) - 1] of menuitem_t;
  InTextDef: menu_t;

procedure M_InTextMenu(choice: integer);
begin
end;

procedure M_DrawInMissionText;
var
  p: Ppatch_t;
  lump: integer;
  lst: TDStringList;
  i: integer;
begin
  p := W_CacheLumpName('BriefScreen', PU_STATIC);
  V_DrawPatch(InTextDef.x, InTextDef.y, SCN_TMP, p, false);
  Z_ChangeTag(p, PU_CACHE);

  lump := W_CheckNumForName('MissionPrimary[' + itoa(gameepisode) + '][' + itoa(gamemap) + ']');
  if lump >= 0 then
    V_DrawPatch(InTextDef.x + 4, InTextDef.y + 45, SCN_TMP, lump, false);

  lump := W_CheckNumForName('MissionSecondary[' + itoa(gameepisode) + '][' + itoa(gamemap) + ']');
  if lump >= 0 then
    V_DrawPatch(InTextDef.x + 160, InTextDef.y + 45, SCN_TMP, lump, false);

  lump := W_CheckNumForName('MissionText[' + itoa(gameepisode) + '][' + itoa(gamemap) + ']');
  if lump >= 0 then
  begin
    lst := TDStringList.Create;
    lst.Text := W_TextLumpNum(lump);
    for i := 0 to 7 do
    begin
      M_WriteSmallText(InTextDef.x + 2, 128 + i * 8, lst.Strings[i], SCN_TMP);
      M_WriteSmallText(InTextDef.x + 158, 128 + i * 8, lst.Strings[i + 8], SCN_TMP);
    end;
    lst.Free;
  end;
end;

type
//
// SYSTEM  MENU
//
  system_e = (
    sys_safemode,
    sys_usemmx,
    sys_criticalcpupriority,
    sys_usemultithread,
    sys_screenshottype,
    sys_end
  );

var
  SystemMenu: array[0..Ord(sys_end) - 1] of menuitem_t;
  SystemDef: menu_t;

var
  LoadMenu: array[0..Ord(load_end) - 1] of menuitem_t;
  LoadDef: menu_t;
  SaveMenu: array[0..Ord(load_end) - 1] of menuitem_t;
  SaveDef: menu_t;

//
// M_ReadSaveStrings
//  read the strings from the savegame files
//
procedure M_ReadSaveStrings;
var
  handle: file;
  i: integer;
  name: string;
begin
  for i := 0 to Ord(load_end) - 1 do
  begin
    sprintf(name, M_SaveFileName(SAVEGAMENAME) + '%d.sav', [i]);

    if not fopen(handle, name, fOpenReadOnly) then
    begin
      savegamestrings[i] := '';
      ZeroMemory(@savegameshots[i], SizeOf(menuscreenbuffer_t));
      LoadMenu[i].status := 0;
      continue;
    end;
    SetLength(savegamestrings[i], SAVESTRINGSIZE);
    BlockRead(handle, (@savegamestrings[i][1])^, SAVESTRINGSIZE);
    seek(handle, SAVESTRINGSIZE + SAVEVERSIONSIZE);
    BlockRead(handle, savegameshots[i], SizeOf(menuscreenbuffer_t));
    close(handle);
    LoadMenu[i].status := 1;
  end;
end;

//
// Draw border for the savegame description
//
procedure M_DrawSaveLoadBorder(x, y: integer);
begin
  M_Frame3d(x - 4, y - 4, x + 23 * 8 - 4, y + 10, 64, 80, 251);
end;

//
// M_DrawSaveLoadScreenShot
// JVAL: 20200303 - Draw Game Screenshot in Load/Save screens
//
procedure M_DrawSaveLoadScreenShot(const screenshot: Pmenuscreenbuffer_t);
const
  SHOT_X = 196;
  SHOT_Y = 14;
var
  x, y, spos: integer;
  b: byte;
begin
  if screenshot = nil then
    exit;

  // Draw screenshot starting at (SHOT_X,SHOT_Y) position
  for y := 0 to MN_SCREENSHOTHEIGHT - 1 do
  begin
    spos := (y + SHOT_Y) * 320 + SHOT_X;
    for x := 0 to MN_SCREENSHOTWIDTH - 1 do
    begin
      b := screenshot[y * MN_SCREENSHOTWIDTH + x];
      if b <> 0 then
        screens[SCN_TMP][spos] := b;
      inc(spos);
    end;
  end;
end;

//
// M_LoadGame & Cie.
//
procedure M_DrawLoad;
var
  i: integer;
begin
  V_DrawPatch(0, 0, SCN_TMP, 'SaveLoadScreen', false);
  M_WriteSmallText(270, 96, 'LOAD', SCN_TMP);

  for i := 0 to Ord(load_end) - 1 do
  begin
    if itemon = i then
    begin
      V_DrawPatch(LoadDef.x + ARROWXOFFS, LoadDef.y + i * LoadDef.itemheight + ARROWYOFFS, SCN_TMP, p_rightarrow, false);
      V_DrawPatch(LoadDef.x + (1 + SAVESTRINGSIZE) * 5 + ARROWXOFFS, LoadDef.y + i * LoadDef.itemheight + ARROWYOFFS, SCN_TMP, p_leftarrow, false);
      M_DrawSaveLoadScreenShot(@savegameshots[i]);
    end;
    M_WriteSmallText(LoadDef.x, LoadDef.y + LoadDef.itemheight * i, savegamestrings[i], SCN_TMP);
  end;
end;

//
// User wants to load this game
//
procedure M_LoadSelect(choice: integer);
var
  name: string;
begin
  sprintf(name, M_SaveFileName(SAVEGAMENAME) + '%d.sav', [choice]);
  G_LoadGame(name);
  M_ClearMenus;
end;

//
// Selected from DOOM menu
//
procedure M_LoadGame(choice: integer);
begin
  if netgame then
  begin
    M_StartMessage(LOADNET + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  M_SetupNextMenu(@LoadDef);
  M_ReadSaveStrings;
end;

//
//  M_SaveGame & Cie.
//
procedure M_DrawSave;
var
  i: integer;
begin
  V_DrawPatch(0, 0, SCN_TMP, 'SaveLoadScreen', false);
  M_WriteSmallText(270, 96, 'SAVE', SCN_TMP);

  for i := 0 to Ord(load_end) - 1 do
  begin
    if itemon = i then
    begin
      V_DrawPatch(SaveDef.x + ARROWXOFFS, SaveDef.y + i * SaveDef.itemheight + ARROWYOFFS, SCN_TMP, p_rightarrow, false);
      V_DrawPatch(SaveDef.x + (1 + SAVESTRINGSIZE) * 5 + ARROWXOFFS, SaveDef.y + i * SaveDef.itemheight + ARROWYOFFS, SCN_TMP, p_leftarrow, false);
    end;
    M_WriteSmallText(SaveDef.x, SaveDef.y + SaveDef.itemheight * i, savegamestrings[i], SCN_TMP);
  end;

  if saveStringEnter <> 0 then
    if Length(savegamestrings[saveSlot]) < SAVESTRINGSIZE then
    begin
      i := M_SmallStringWidth(savegamestrings[saveSlot]);
      if (gametic div 18) mod 2 = 0 then
        M_WriteSmallText(LoadDef.x + i, LoadDef.y + LoadDef.itemheight * saveSlot, '_', SCN_TMP);
    end;

  M_DrawSaveLoadScreenShot(@mn_screenshotbuffer);
end;

//
// M_Responder calls this when user is finished
//
procedure M_DoSave(slot: integer);
begin
  G_SaveGame(slot, savegamestrings[slot]);
  M_ClearMenus;

  // PICK QUICKSAVE SLOT YET?
  if quickSaveSlot = -2 then
    quickSaveSlot := slot;
end;

//
// User wants to save. Start string input for M_Responder
//
procedure M_SaveSelect(choice: integer);
var
  s: string;
  i: integer;
  c: char;
begin
  // we are going to be intercepting all chars
  saveStringEnter := 1;

  saveSlot := choice;
  saveOldString := savegamestrings[choice];
  // JVAL 21/4/2017
  if keepsavegamename then
  begin
    s := '';
    for i := 1 to Length(savegamestrings[choice]) do
    begin
      c := savegamestrings[choice][i];
      if c in [#0, #13, #10, ' '] then
        Break
      else
        s := s + c;
    end;
    savegamestrings[choice] := s;
  end
  else if savegamestrings[choice] <> '' then
    savegamestrings[choice] := '';
  saveCharIndex := Length(savegamestrings[choice]);
end;

//
// Selected from DOOM menu
//
procedure M_SaveGame(choice: integer);
begin
  if not usergame then
  begin
    M_StartMessage(SAVEDEAD + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  M_SetupNextMenu(@SaveDef);
  M_ReadSaveStrings;
end;

//
//      M_QuickSave
//
var
  menusnd: integer = -1;

procedure M_MenuSound;
begin
  if gamestate = GS_ENDOOM then
    exit;
  if menusnd = -1 then
    menusnd := S_GetSoundNumForName(radixsounds[Ord(sfx_SndButtonClick)].name);
  if menusnd > 0 then
    S_StartSound(nil, menusnd);
end;

procedure M_QuickSaveResponse(ch: integer);
begin
  if ch = Ord('y') then
  begin
    M_DoSave(quickSaveSlot);
    M_MenuSound;
  end;
end;

procedure M_QuickSave;
var
  tempstring: string;
begin
  if not usergame then
  begin
    M_MenuSound;
    exit;
  end;

  if gamestate <> GS_LEVEL then
    exit;

  if quickSaveSlot < 0 then
  begin
    M_StartControlPanel;
    M_ReadSaveStrings;
    M_SetupNextMenu(@SaveDef);
    quickSaveSlot := -2;  // means to pick a slot now
    exit;
  end;

  sprintf(tempstring, QSPROMPT + #13#10 + PRESSYN, [savegamestrings[quickSaveSlot]]);
  M_StartMessage(tempstring, @M_QuickSaveResponse, true);
end;

//
// M_QuickLoad
//
procedure M_QuickLoadResponse(ch: integer);
begin
  if ch = Ord('y') then
  begin
    M_LoadSelect(quickSaveSlot);
    M_MenuSound;
  end;
end;

procedure M_QuickLoad;
var
  tempstring: string;
begin
  if netgame then
  begin
    M_StartMessage(QLOADNET + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  if quickSaveSlot < 0 then
  begin
    M_StartMessage(QSAVESPOT + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  sprintf(tempstring, QLPROMPT + #13#10 + PRESSYN, [savegamestrings[quickSaveSlot]]);
  M_StartMessage(tempstring, @M_QuickLoadResponse, true);
end;

procedure M_DrawFlatBackground(const sflat: string);
var
  x, y: integer;
  src: PByteArray;
  dest: integer;
  iflat: integer;
begin
  iflat := R_FlatNumForName(sflat);
  if iflat < 0 then
  begin
    iflat := R_FlatNumForName(DEFMENUBACKGROUNDFLAT);
    if iflat < 0 then
      exit;
  end;

  src := W_CacheLumpNum(R_GetLumpForFlat(iflat), PU_STATIC);
  dest := 0;

  for y := 0 to 200 - 1 do
  begin
    for x := 0 to (320 div 64) - 1 do
    begin
      memcpy(@screens[SCN_TMP, dest], @src[_SHL(y and 63, 6)], 64);
      dest := dest + 64;
    end;

    if 320 and 63 <> 0 then
    begin
      memcpy(@screens[SCN_TMP, dest], @src[_SHL(y and 63, 6)], 320 and 63);
      dest := dest + (320 and 63);
    end;
  end;
  Z_ChangeTag(src, PU_CACHE);
end;

//
// Read This Menus
// Had a "quick hack to fix romero bug"
//
function M_WriteHelpText(const x, y: integer; const s1, s2: string): menupos_t;
var
  mp: menupos_t;
begin
  mp := M_WriteSmallWhiteText(x, y, s1 + ': ', SCN_TMP);
  result := M_WriteSmallText(mp.x, mp.y, s2, SCN_TMP);
end;

procedure M_DrawReadThis1;
var
  y: integer;
begin
  inhelpscreens := true;
  M_DrawFlatBackground(menubackgroundflat);

  M_DrawHeadLine(15, 'HELP');

  y := 34;
  M_DrawSmallLine(y, 'MISCELLANIOUS OPTIONS');

  y := y + 14;
  M_WriteHelpText(10, y, 'F1', 'HELP');
  M_WriteHelpText(110, y, 'F2', 'LOAD');
  M_WriteHelpText(210, y, 'F3', 'SAVE');

  y := y + 10;
  M_WriteHelpText(10, y, 'F4', 'SOUND VOLUME');
  M_WriteHelpText(110, y, 'F5', 'TOGGLE DETAIL');
  M_WriteHelpText(210, y, 'F6', 'QUICKSAVE');

  y := y + 10;
  M_WriteHelpText(10, y, 'F7', 'END GAME');
  M_WriteHelpText(110, y, 'F8', 'MESSAGES');
  M_WriteHelpText(210, y, 'F9', 'QUICKLOAD');

  y := y + 10;
  M_WriteHelpText(10, y, 'F10', 'QUIT GAME');
  M_WriteHelpText(110, y, 'F11', 'GAMMA');
  M_WriteHelpText(210, y, 'F12', 'OBJECTIVES');

  y := y + 10;
  M_WriteHelpText(10, y, 'TAB', 'AUTOMAP');
  M_WriteHelpText(110, y, 'ESC', 'MENU');
  M_WriteHelpText(210, y, '+/-', 'VIEW SIZE');

  y := y + 10;
  M_WriteHelpText(10, y, 'PRTSC', 'SCREENSHOT');
  M_WriteHelpText(110, y, 'PAUSE', 'PAUSE GAME');

  y := y + 14;
  M_DrawSmallLine(y, 'AUTOMAP');

  y := y + 14;
  M_WriteHelpText(10, y, 'F', 'FOLLOW MODE');
  M_WriteHelpText(110, y, 'M', 'ADD MARK');
  M_WriteHelpText(210, y, 'C', 'CLEAR MARKS');

  y := y + 10;
  M_WriteHelpText(10, y, 'G', 'TOGGLE GRID');
  M_WriteHelpText(110, y, 'T', 'TOGGLE TEXTURES');
  M_WriteHelpText(210, y, '+/-', 'ZOOM SIZE');

  y := y + 14;
  M_DrawSmallLine(y, 'MENU');

  y := y + 14;
  M_WriteHelpText(10, y, 'ARROWS', 'NAVIGATE');
  M_WriteHelpText(110, y, 'ENTER', 'SELECT');
  M_WriteHelpText(210, y, 'BACKSPACE', 'GO BACK');
end;

//
// Read This Menus - optional second page.
//
function M_WriteHelpControlText(const x, y: integer; const control: PInteger): menupos_t;
var
  i: integer;
begin
  for i := 0 to Ord(kb_end) - 1 do
    if KeyBindingsInfo[i].pkey = control then
    begin
      result := M_WriteSmallText(x, y, KeyBindingsInfo[i].text + ': ', SCN_TMP);
      result := M_WriteSmallWhiteText(result.x, result.y, M_KeyToString(control^), SCN_TMP);
      exit;
    end;

  result.x := x;
  result.y := y;
end;

procedure M_DrawReadThis2;
var
  y: integer;
begin
  inhelpscreens := true;
  M_DrawFlatBackground(menubackgroundflat);

  M_DrawHeadLine(15, 'HELP');

  y := 34;
  M_DrawSmallLine(y, 'MOVEMENT CONTROLS');

  y := y + 14;
  M_WriteHelpControlText(10, y, @key_up);
  M_WriteHelpControlText(160, y, @key_down);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_left);
  M_WriteHelpControlText(160, y, @key_right);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_strafeleft);
  M_WriteHelpControlText(160, y, @key_straferight);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_flyup);
  M_WriteHelpControlText(160, y, @key_flydown);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_fire);
  M_WriteHelpControlText(160, y, @key_use);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_afterburner);
  M_WriteHelpControlText(160, y, @key_speed);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_lookup);
  M_WriteHelpControlText(160, y, @key_lookdown);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_lookcenter);
  M_WriteHelpControlText(160, y, @key_lookleft);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_lookright);
  M_WriteHelpControlText(160, y, @key_strafe);

  y := y + 14;
  M_DrawSmallLine(y, 'WEAPON SELECTION');

  y := y + 14;
  M_WriteHelpControlText(10, y, @key_weapon0);
  M_WriteHelpControlText(160, y, @key_weapon1);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_weapon2);
  M_WriteHelpControlText(160, y, @key_weapon3);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_weapon4);
  M_WriteHelpControlText(160, y, @key_weapon5);

  y := y + 10;
  M_WriteHelpControlText(10, y, @key_weapon6);
  M_WriteHelpControlText(160, y, @key_plasmabomb);
//  M_WriteHelpControlText(160, y, @key_weapon7);
end;

procedure M_DrawReadThisExt;
begin
  inhelpscreens := true;
  V_PageDrawer(char8tostring(W_GetNameForNum(extrahelpscreens.Numbers[extrahelpscreens_idx])));
end;

//
// Change Sfx & Music volumes
//
procedure M_DrawSoundVol;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Volume Control');

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + SoundVolDef.itemheight * (Ord(sfx_vol) + 1), 16, snd_SfxVolume);

  M_DrawThermo(
    SoundVolDef.x, SoundVolDef.y + SoundVolDef.itemheight * (Ord(music_vol) + 1), 16, snd_MusicVolume);
end;

procedure M_ChangeDrones(choice: integer);
begin
  helperdrones := GetIntegerInRange(helperdrones, 0, MAXPLAYERS - 1);
  inc(helperdrones);
  if helperdrones >= MAXPLAYERS then
    helperdrones := 0;
end;

procedure M_SwitchPlayerWeaponDamage(choise: integer);
begin
  g_vanillaplayerweapondamage := not g_vanillaplayerweapondamage;
end;

procedure M_SwitchBarrelExplode(choise: integer);
begin
  g_bigbarrelexplosion := not g_bigbarrelexplosion;
end;

procedure M_SwitchDroneExplode(choise: integer);
begin
  g_bigdroneexplosion := not g_bigdroneexplosion;
end;

const
  VANILLA_PLAYER_WEAPON_DAMAGE_TEXT: array[boolean] of string = ('Challenging', 'Vanilla');

const
  EXPLOSION_SIZE_TEXT: array[boolean] of string = ('Small', 'Big');

procedure M_DrawGameplay;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Gameplay');

  ppos := M_WriteSmallText(GameplayDef.x, GameplayDef.y + GameplayDef.itemheight * Ord(gmp_vanillaplayerweapondamage), 'Player weapon damage: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, VANILLA_PLAYER_WEAPON_DAMAGE_TEXT[g_vanillaplayerweapondamage], SCN_TMP);
  ppos := M_WriteSmallText(GameplayDef.x, GameplayDef.y + GameplayDef.itemheight * Ord(gmp_barrelexplode), 'Barrel death explosion: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, EXPLOSION_SIZE_TEXT[g_bigbarrelexplosion], SCN_TMP);
  ppos := M_WriteSmallText(GameplayDef.x, GameplayDef.y + GameplayDef.itemheight * Ord(gmp_droneexplode), 'Drone death explosion: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, EXPLOSION_SIZE_TEXT[g_bigdroneexplosion], SCN_TMP);
end;

procedure M_DrawCompatibility;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Compatibility');

  helperdrones := GetIntegerInRange(helperdrones, 0, MAXPLAYERS - 1);
  ppos := M_WriteSmallText(CompatibilityDef.x, CompatibilityDef.y + CompatibilityDef.itemheight * Ord(cmp_drones), 'Helper drones: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, itoa(helperdrones), SCN_TMP);
end;

const
  mkeyboardmodes: array[0..3] of string = ('ARROWS', 'WASD', 'ESDF', 'CUSTOM');

procedure M_SetKeyboardMode(const mode: integer);
begin
  if mode = 0 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 173;
    key_down := 175;
    key_strafeleft := 44;
    key_straferight := 46;
    key_flyup := 97;
    key_flydown := 122;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_afterburner := 47;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('1');
    key_weapon1 := Ord('2');
    key_weapon2 := Ord('3');
    key_weapon3 := Ord('4');
    key_weapon4 := Ord('5');
    key_weapon5 := Ord('6');
    key_weapon6 := Ord('7');
    key_weapon7 := Ord('8');
    key_plasmabomb := Ord('b');
    AM_GOBIGKEY := Ord('0');
    AM_FOLLOWKEY := Ord('f');
    AM_GRIDKEY := Ord('g');
    AM_ROTATEKEY := Ord('r');
    AM_TEXTUREDAUTOMAP := Ord('t');
    AM_MARKKEY := Ord('m');
    AM_CLEARMARKKEY := Ord('c');
  end
  else if mode = 1 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 119;
    key_down := 115;
    key_strafeleft := 97;
    key_straferight := 100;
    key_flyup := 101;
    key_flydown := 113;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_afterburner := 47;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('1');
    key_weapon1 := Ord('2');
    key_weapon2 := Ord('3');
    key_weapon3 := Ord('4');
    key_weapon4 := Ord('5');
    key_weapon5 := Ord('6');
    key_weapon6 := Ord('7');
    key_weapon7 := Ord('8');
    key_plasmabomb := Ord('b');
    AM_GOBIGKEY := Ord('0');
    AM_FOLLOWKEY := Ord('f');
    AM_GRIDKEY := Ord('g');
    AM_ROTATEKEY := Ord('r');
    AM_TEXTUREDAUTOMAP := Ord('t');
    AM_MARKKEY := Ord('m');
    AM_CLEARMARKKEY := Ord('c');
  end
  else if mode = 2 then
  begin
    key_right := 174;
    key_left := 172;
    key_up := 101;
    key_down := 100;
    key_strafeleft := 115;
    key_straferight := 102;
    key_flyup := 97;
    key_flydown := 122;
    key_fire := 157;
    key_use := 32;
    key_strafe := 184;
    key_afterburner := 47;
    key_speed := 182;
    key_lookup := 197;
    key_lookdown := 202;
    key_lookcenter := 199;
    key_lookright := 198;
    key_lookleft := 200;
    key_lookforward := 13;
    key_weapon0 := Ord('1');
    key_weapon1 := Ord('2');
    key_weapon2 := Ord('3');
    key_weapon3 := Ord('4');
    key_weapon4 := Ord('5');
    key_weapon5 := Ord('6');
    key_weapon6 := Ord('7');
    key_weapon7 := Ord('8');
    key_plasmabomb := Ord('b');
    AM_GOBIGKEY := Ord('0');
    AM_FOLLOWKEY := Ord('f');
    AM_GRIDKEY := Ord('g');
    AM_ROTATEKEY := Ord('r');
    AM_TEXTUREDAUTOMAP := Ord('t');
    AM_MARKKEY := Ord('m');
    AM_CLEARMARKKEY := Ord('c');
  end;
end;

function M_GetKeyboardMode: integer;
begin
  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 173) and
     (key_down = 175) and
     (key_strafeleft = 44) and
     (key_straferight = 46) and
     (key_flyup = 97) and
     (key_flydown = 122) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_afterburner = 47) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('1')) and
     (key_weapon1 = Ord('2')) and
     (key_weapon2 = Ord('3')) and
     (key_weapon3 = Ord('4')) and
     (key_weapon4 = Ord('5')) and
     (key_weapon5 = Ord('6')) and
     (key_weapon6 = Ord('7')) and
     (key_weapon7 = Ord('8')) and
     (key_plasmabomb = Ord('b')) and
     (AM_GOBIGKEY = Ord('0')) and
     (AM_FOLLOWKEY = Ord('f')) and
     (AM_GRIDKEY = Ord('g')) and
     (AM_ROTATEKEY = Ord('r')) and
     (AM_TEXTUREDAUTOMAP = Ord('t')) and
     (AM_MARKKEY = Ord('m')) and
     (AM_CLEARMARKKEY = Ord('c')) then
  begin
    result := 0;
    exit;
  end;

  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 119) and
     (key_down = 115) and
     (key_strafeleft = 97) and
     (key_straferight = 100) and
     (key_flyup = 101) and
     (key_flydown = 113) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_afterburner = 47) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('1')) and
     (key_weapon1 = Ord('2')) and
     (key_weapon2 = Ord('3')) and
     (key_weapon3 = Ord('4')) and
     (key_weapon4 = Ord('5')) and
     (key_weapon5 = Ord('6')) and
     (key_weapon6 = Ord('7')) and
     (key_weapon7 = Ord('8')) and
     (key_plasmabomb = Ord('b')) and
     (AM_GOBIGKEY = Ord('0')) and
     (AM_FOLLOWKEY = Ord('f')) and
     (AM_GRIDKEY = Ord('g')) and
     (AM_ROTATEKEY = Ord('r')) and
     (AM_TEXTUREDAUTOMAP = Ord('t')) and
     (AM_MARKKEY = Ord('m')) and
     (AM_CLEARMARKKEY = Ord('c')) then
  begin
    result := 1;
    exit;
  end;

  if (key_right = 174) and
     (key_left = 172) and
     (key_up = 101) and
     (key_down = 100) and
     (key_strafeleft = 115) and
     (key_straferight = 102) and
     (key_flyup = 97) and
     (key_flydown = 122) and
     (key_fire = 157) and
     (key_use = 32) and
     (key_strafe = 184) and
     (key_afterburner = 47) and
     (key_speed = 182) and
     (key_lookup = 197) and
     (key_lookdown = 202) and
     (key_lookcenter = 199) and
     (key_lookright = 198) and
     (key_lookleft = 200) and
     (key_lookforward = 13) and
     (key_weapon0 = Ord('1')) and
     (key_weapon1 = Ord('2')) and
     (key_weapon2 = Ord('3')) and
     (key_weapon3 = Ord('4')) and
     (key_weapon4 = Ord('5')) and
     (key_weapon5 = Ord('6')) and
     (key_weapon6 = Ord('7')) and
     (key_weapon7 = Ord('8')) and
     (key_plasmabomb = Ord('b')) and
     (AM_GOBIGKEY = Ord('0')) and
     (AM_FOLLOWKEY = Ord('f')) and
     (AM_GRIDKEY = Ord('g')) and
     (AM_ROTATEKEY = Ord('r')) and
     (AM_TEXTUREDAUTOMAP = Ord('t')) and
     (AM_MARKKEY = Ord('m')) and
     (AM_CLEARMARKKEY = Ord('c')) then
  begin
    result := 2;
    exit;
  end;

  result := 3;
end;

procedure M_KeyboardModeArrows(choice: integer);
begin
  M_SetKeyboardMode(0);
end;

procedure M_KeyboardModeWASD(choice: integer);
begin
  M_SetKeyboardMode(1);
end;

procedure M_KeyboardModeESDF(choice: integer);
begin
  M_SetKeyboardMode(2);
end;

procedure M_SwitchKeyboardMode(choice: integer);
var
  old: integer;
begin
  old := M_GetKeyboardMode;
  case old of
    0: M_KeyboardModeWASD(choice);
    1: M_KeyboardModeESDF(choice);
  else
    M_KeyboardModeArrows(choice);
  end;
end;

procedure M_CmdKeyboardMode(const parm1, parm2: string);
var
  wrongparms: boolean;
  sparm1: string;
begin
  wrongparms := false;

  if (parm1 = '') or (parm2 <> '') then
    wrongparms := true;

  sparm1 := strupper(parm1);

  if (parm1 <> '0') and (parm1 <> '1') and (parm1 <> '2') and
     (sparm1 <> 'ARROWS') and (sparm1 <> 'WASD') and (sparm1 <> 'ESDF') then
    wrongparms := true;

  if wrongparms then
  begin
    printf('Specify the keyboard mode:'#13#10);
    printf('  0: Arrows'#13#10);
    printf('  1: WASD'#13#10);
    printf('  2: ESDF'#13#10);
    exit;
  end;

  if (parm1 = '0') or (sparm1 = 'ARROWS') then
    M_SetKeyboardMode(0)
  else if (parm1 = '1') or (sparm1 = 'WASD') then
    M_SetKeyboardMode(1)
  else
    M_SetKeyboardMode(2);
end;

procedure M_DrawControls;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Controls');

  ppos := M_WriteSmallText(ControlsDef.x, ControlsDef.y + ControlsDef.itemheight * Ord(ctrl_keyboardmode), 'Keyboard preset: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, mkeyboardmodes[M_GetKeyboardMode], SCN_TMP);
end;

procedure M_DrawSound;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Sound');
end;

procedure M_DrawSystem;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'System');

  M_FixScreenshotFormat;
  ppos := M_WriteSmallText(SystemDef.x, SystemDef.y + SystemDef.itemheight * Ord(sys_screenshottype), 'Screenshot format: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, screenshotformat, SCN_TMP);
end;

procedure M_OptionsSound(choice: integer);
begin
  M_SetupNextMenu(@SoundDef);
end;

procedure M_SoundVolume(choice: integer);
begin
  M_SetupNextMenu(@SoundVolDef);
end;

procedure M_OptionsConrols(choice: integer);
begin
  M_SetupNextMenu(@ControlsDef);
end;

procedure M_OptionsSensitivity(choice: integer);
begin
  M_SetupNextMenu(@SensitivityDef);
end;

procedure M_OptionsGameplay(choice: integer);
begin
  M_SetupNextMenu(@GameplayDef);
end;

procedure M_OptionsCompatibility(choice: integer);
begin
  M_SetupNextMenu(@CompatibilityDef);
end;

procedure M_OptionsSystem(choice: integer);
begin
  M_SetupNextMenu(@SystemDef);
end;

procedure M_OptionsGeneral(choice: integer);
begin
  M_SetupNextMenu(@OptionsGeneralDef);
end;

procedure M_OptionsDisplay(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayDef);
end;

procedure M_OptionsDisplayDetail(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayDetailDef);
end;

var
  mdisplaymode_idx: integer = 0;

procedure M_SetVideoMode(choice: integer);
var
  idx: integer;
begin
  idx := I_NearestDisplayModeIndex(SCREENWIDTH, SCREENHEIGHT);
  if idx >= 0 then
    mdisplaymode_idx := idx;
  OptionsDisplayVideoModeDef.lastOn := 0;
  itemOn := 0;
  M_SetupNextMenu(@OptionsDisplayVideoModeDef);
end;

procedure M_OptionsDisplayAutomap(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAutomapDef);
end;

procedure M_OptionsDisplayAppearance(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAppearanceDef);
end;

procedure M_OptionAspectRatio(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAspectRatioDef);
end;

procedure M_OptionCameraShift(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayCameraDef);
end;

{$IFNDEF OPENGL}
procedure M_OptionsDisplayLightmap(choice: integer);
begin
  M_SetupNextMenu(@OptionsLightmapDef);
end;
{$ENDIF}

procedure M_ChangeCameraXY(choice: integer);
begin
  case choice of
    0: chasecamera_viewxy := chasecamera_viewxy - 8;
    1: chasecamera_viewxy := chasecamera_viewxy + 8;
  end;
  chasecamera_viewxy := ibetween(chasecamera_viewxy, CHASECAMERA_XY_MIN, CHASECAMERA_XY_MAX);
end;

procedure M_ChangeCameraZ(choice: integer);
begin
  case choice of
    0: chasecamera_viewz := chasecamera_viewz - 4;
    1: chasecamera_viewz := chasecamera_viewz + 4;
  end;
  chasecamera_viewz := ibetween(chasecamera_viewz, CHASECAMERA_Z_MIN, CHASECAMERA_Z_MAX);
end;

const
  NUMSTRASPECTRATIOS = 5;
  straspectratios: array[0..NUMSTRASPECTRATIOS - 1] of string =
    ('AUTO', '4:3', '16:10', '16:9', '1.85:1');

var
  aspectratioidx: integer;

procedure M_SwitchForcedAspectRatio(choice: integer);
begin
  aspectratioidx := (aspectratioidx + 1) mod NUMSTRASPECTRATIOS;
  if aspectratioidx = 0 then
    forcedaspectstr := '0'
  else
  begin
    widescreensupport := true;
    forcedaspectstr := straspectratios[aspectratioidx];
  end;
  setsizeneeded := true;
end;

function _nearest_aspect_index: integer;
var
  asp: single;
  i: integer;
  diff, test, mx: single;
  ar, par: string;
begin
  result := 0;

  asp := R_ForcedAspect;
  if asp < 1.0 then
    exit;

  mx := 100000000.0;

  for i := 1 to NUMSTRASPECTRATIOS - 1 do
  begin
    splitstring(straspectratios[i], ar, par, [':', '/']);
    if par = '' then
      test := atof(ar)
    else
      test := atof(ar) / atof(par);
    diff := fabs(test - asp);
    if diff = 0 then
    begin
      result := i;
      exit;
    end;
    if diff < mx then
    begin
      result := i;
      mx := diff;
    end;
  end;
end;

procedure M_OptionsDisplayAdvanced(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayAdvancedDef);
end;

procedure M_OptionsDisplay32bit(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplay32bitDef);
end;

{$IFDEF OPENGL}
procedure M_OptionsDisplayOpenGL(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLDef);
end;

procedure M_OptionsDisplayOpenGLModels(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLModelsDef);
end;

procedure M_OptionsDisplayOpenGLVoxels(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLVoxelsDef);
end;

procedure M_OptionsDisplayOpenGLFilter(choice: integer);
begin
  M_SetupNextMenu(@OptionsDisplayOpenGLFilterDef);
end;
{$ENDIF}

procedure M_SfxVol(choice: integer);
begin
  case choice of
    0: if snd_SfxVolume <> 0 then dec(snd_SfxVolume);
    1: if snd_SfxVolume < 15 then inc(snd_SfxVolume);
  end;
  S_SetSfxVolume(snd_SfxVolume);
end;

procedure M_MusicVol(choice: integer);
begin
  case choice of
    0: if snd_MusicVolume <> 0 then dec(snd_MusicVolume);
    1: if snd_MusicVolume < 15 then inc(snd_MusicVolume);
  end;
  S_SetMusicVolume(snd_MusicVolume);
end;

//
// M_DrawMainMenu
//
procedure M_DrawMainMenu;
var
  p: Ppatch_t;
  i, y: integer;
begin
  p := W_CacheLumpName('M_RADIX', PU_STATIC);
  V_DrawPatch((320 - p.width) div 2, 6, SCN_TMP, p, false);
  Z_ChangeTag(p, PU_CACHE);

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(mm_newgame) to Ord(mm_quitradix) do
  begin
    if itemOn = i then
      M_WriteBigTextOrangeCenter(y, MainMenu[i].name, SCN_TMP)
    else
      M_WriteBigTextGrayCenter(y, MainMenu[i].name, SCN_TMP);
    y := y + 14;
  end;
end;

//
// M_NewGame
//
procedure M_DrawNewGame;
begin
  V_DrawPatch(0, 0, SCN_TMP, 'SelectSkill', false);

  case itemOn of
    0: V_DrawPatch(51, 16, SCN_TMP, 'SkillButton1', false);
    1: V_DrawPatch(50, 62, SCN_TMP, 'SkillButton2', false);
    2: V_DrawPatch(52, 106, SCN_TMP, 'SkillButton3', false);
    3: V_DrawPatch(52, 150, SCN_TMP, 'SkillButton4', false);
  end;
end;

procedure M_NewGame(choice: integer);
begin
  if netgame and not demoplayback then
  begin
    M_StartMessage(SNEWGAME + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  pilotStringEnter := 1;
  pilotOldString := pilotNameString;
  pilotCharIndex := Length(pilotNameString);
  M_SetupNextMenu(@PilotNameDef);
end;

//
//      M_Episode
//
var
  epi: integer;

procedure M_DrawEpisode;
begin
  V_DrawPatch(0, 0, SCN_TMP, 'SelectEpisode', false);

  case itemOn of
    0: V_DrawPatch(36, 22, SCN_TMP, 'EpisodeButton1', false);
    1: V_DrawPatch(36, 81, SCN_TMP, 'EpisodeButton2', false);
    2: V_DrawPatch(37, 142, SCN_TMP, 'EpisodeButton3', false);
  end;
end;

procedure M_DrawPilotName;
const
  XPILOT = 12;
  YPILOT = 22;
begin
  V_DrawPatch(0, 0, SCN_TMP, 'SelectEpisode', false);
  V_DrawPatch(PilotNameDef.x, PilotNameDef.y, SCN_TMP, 'PlayerNameBox', false);

  M_WriteSmallText(PilotNameDef.x + XPILOT, PilotNameDef.y + YPILOT, pilotNameString, SCN_TMP);

  if pilotStringEnter <> 0 then
    if Length(pilotNameString) < PILOTNAMESIZE then
      if (gametic div 18) mod 2 = 0 then
        M_WriteSmallText(PilotNameDef.x + XPILOT + M_SmallStringWidth(pilotNameString), PilotNameDef.y + YPILOT, '_', SCN_TMP);
end;

procedure M_VerifyNightmare(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  G_DeferedInitNew(sk_nightmare, epi + 1, 1); // JVAL nightmare become sk_nightmare
  M_ClearMenus;
end;

procedure M_ChooseSkill(choice: integer);
begin
  G_DeferedInitNew(skill_t(choice), epi + 1, 1);
  M_ClearMenus;
end;

procedure M_Episode(choice: integer);
begin
  if (gamemode = shareware) and (choice <> 0) then
  begin
    M_StartMessage(SWSTRING + #13#10 + PRESSKEY, nil, false);
    M_SetupNextMenu(@ReadDef1);
    exit;
  end;

  epi := choice;

  M_SetupNextMenu(@NewDef);
end;

procedure M_PilotName(choice: integer);
begin
  M_SetupNextMenu(@EpiDef);
end;

//
// M_Options
//
procedure M_DrawOptions;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'Options');

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(opt_general) to Ord(opt_system) do
  begin
    if itemOn = i then
      M_WriteBigTextOrangeCenter(y, OptionsMenu[i].name, SCN_TMP)
    else
      M_WriteBigTextGrayCenter(y, OptionsMenu[i].name, SCN_TMP);
    y := y + 14;
  end;
end;

procedure M_DrawGeneralOptions;
var
  i, y: integer;
  str: string;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'General');

  y := DEF_MENU_ITEMS_START_Y;
  for i := Ord(endgame) to Ord(mousesens) do
  begin
    str := OptionsGeneralMenu[i].name;
    if i = Ord(messages) then
      if showMessages = 1 then
        str := str + ': ON'
      else
        str := str + ': OFF';
    if itemOn = i then
      M_WriteBigTextOrangeCenter(y, str, SCN_TMP)
    else
      M_WriteBigTextGrayCenter(y, str, SCN_TMP);
    y := y + 14;
  end;

  M_DrawThermo(
    78, DEF_MENU_ITEMS_START_Y + 14 * (Ord(scrnsize) + 1) + 2, 20, m_screensize, 11);

  M_DrawThermo(
    78, DEF_MENU_ITEMS_START_Y + 14 * (Ord(mousesens) + 1) + 2, 20, mouseSensitivity, 20);
end;

procedure M_DrawSensitivity;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Mouse Sensitivity');

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivity) + 1), 20, mouseSensitivity);

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivityx) + 1), 11, mouseSensitivityX);

  M_DrawThermo(
    SensitivityDef.x, SensitivityDef.y + SensitivityDef.itemheight * (Ord(sens_mousesensitivityy) + 1), 11, mouseSensitivityY);
end;

procedure M_DrawDisplayOptions;
var
  i, y: integer;
begin
  M_DrawHeadLine(15, 'Options');
  M_DrawSubHeadLine(40, 'Display Options');

  y := DEF_MENU_ITEMS_START_Y;
  for i := 0 to Ord(optdisp_end) - 1 do
  begin
    if itemOn = i then
      M_WriteBigTextOrangeCenter(y, OptionsDisplayMenu[i].name, SCN_TMP)
    else
      M_WriteBigTextGrayCenter(y, OptionsDisplayMenu[i].name, SCN_TMP);
    y := y + 14;
  end;
end;

var
  colordepths: array[boolean] of string = ('8bit', '32bit');

procedure M_DrawDisplayDetailOptions;
var
  stmp: string;
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');

  M_DrawSubHeadLine(40, 'Detail');

  ppos := M_WriteSmallText(OptionsDisplayDetailDef.x, OptionsDisplayDetailDef.y + OptionsDisplayDetailDef.itemheight * Ord(od_detaillevel), 'Detail level: ', SCN_TMP);
  {$IFDEF OPENGL}
  sprintf(stmp, '%s (%dx%dx32)', [detailStrings[detailLevel], SCREENWIDTH, SCREENHEIGHT]);
  {$ELSE}
  sprintf(stmp, '%s (%dx%dx%s)', [detailStrings[detailLevel], SCREENWIDTH, SCREENHEIGHT, colordepths[videomode = vm32bit]]);
  {$ENDIF}
  M_WriteSmallWhiteText(ppos.x, ppos.y, stmp, SCN_TMP);
end;

procedure M_ChangeFullScreen(choice: integer);
begin
  {$IFDEF OPENGL}
  GL_ChangeFullScreen(not fullscreen);
  {$ELSE}
  I_ChangeFullScreen((fullscreen + 1) mod NUMFULLSCREEN_MODES);
  {$ENDIF}
end;

const
  strfullscreenmodes: array[0..NUMFULLSCREEN_MODES - 1] of string = (
    'SHARED', 'EXCLUSIVE', 'OFF'
  );

procedure M_DrawDisplaySetVideoMode;
var
  stmp: string;
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');

  M_DrawSubHeadLine(40, 'Set Video Mode');

  {$IFNDEF OPENGL}
  fullscreen := fullscreen mod NUMFULLSCREEN_MODES;
  {$ENDIF}
  ppos := M_WriteSmallText(OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_fullscreen), 'FullScreen: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, {$IFDEF OPENGL}yesnoStrings[fullscreen]{$ELSE}strfullscreenmodes[fullscreen]{$ENDIF}, SCN_TMP);

  if mdisplaymode_idx < 0 then
    mdisplaymode_idx := 0
  else if mdisplaymode_idx >= numdisplaymodes then
    mdisplaymode_idx := numdisplaymodes - 1;
  ppos := M_WriteSmallText(OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_screensize), 'Screen Size: ', SCN_TMP);
  sprintf(stmp, '(%dx%d)', [displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height]);
  M_WriteSmallWhiteText(ppos.x, ppos.y, stmp, SCN_TMP);

  M_DrawThermo(
    OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * (Ord(odm_screensize) + 1), 30, mdisplaymode_idx, numdisplaymodes);

  if (displaymodes[mdisplaymode_idx].width = SCREENWIDTH) and (displaymodes[mdisplaymode_idx].height = SCREENHEIGHT) then
    stmp := 'No change'
  else
    sprintf(stmp, 'Set video mode to %dx%d...', [displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height]);
  M_WriteSmallText(OptionsDisplayVideoModeDef.x, OptionsDisplayVideoModeDef.y + OptionsDisplayVideoModeDef.itemheight * Ord(odm_setvideomode), stmp, SCN_TMP);
end;

procedure M_SwitchShadeMode(choice: integer);
begin
  shademenubackground := (shademenubackground + 1) mod 3;
end;

const
  menubackrounds: array[0..2] of string =
    ('NONE', 'SHADOW', 'TEXTURE');

procedure M_DrawDisplayAppearanceOptions;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');

  M_DrawSubHeadLine(40, 'Appearence');

  ppos := M_WriteSmallText(OptionsDisplayAppearanceDef.x, OptionsDisplayAppearanceDef.y + OptionsDisplayAppearanceDef.itemheight * Ord(od_shademenubackground), 'Menu background: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, menubackrounds[shademenubackground mod 3], SCN_TMP);
end;

procedure M_DrawDisplayAutomapOptions;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Automap');
end;

procedure M_DrawOptionsDisplayAdvanced;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Advanced');
end;

procedure M_DrawOptionsDisplayAspectRatio;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Aspect Ratio');

  aspectratioidx := _nearest_aspect_index;
  ppos := M_WriteSmallText(OptionsDisplayAspectRatioDef.x, OptionsDisplayAspectRatioDef.y + OptionsDisplayAspectRatioDef.itemheight * Ord(oda_forceaspectratio), 'Force Aspect Ratio: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, straspectratios[_nearest_aspect_index], SCN_TMP);
end;

procedure M_DrawOptionsDisplayCamera;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Camera');

  chasecamera_viewxy := ibetween(chasecamera_viewxy, CHASECAMERA_XY_MIN, CHASECAMERA_XY_MAX);
  ppos := M_WriteSmallText(OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * Ord(odc_chasecameraxy), 'Chase Camera XY position: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, itoa(chasecamera_viewxy), SCN_TMP);

  chasecamera_viewz := ibetween(chasecamera_viewz, CHASECAMERA_Z_MIN, CHASECAMERA_Z_MAX);
  ppos := M_WriteSmallText(OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * Ord(odc_chasecameraz), 'Chase Camera Z position: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, itoa(chasecamera_viewz), SCN_TMP);

  M_DrawThermo(
    OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * (Ord(odc_chasecameraxy) + 1), 21, (chasecamera_viewxy - CHASECAMERA_XY_MIN) div 8, (CHASECAMERA_XY_MAX - CHASECAMERA_XY_MIN) div 8 + 1);

  M_DrawThermo(
    OptionsDisplayCameraDef.x, OptionsDisplayCameraDef.y + OptionsDisplayCameraDef.itemheight * (Ord(odc_chasecameraz) + 1), 21, (chasecamera_viewz - CHASECAMERA_Z_MIN) div 4, (CHASECAMERA_Z_MAX - CHASECAMERA_Z_MIN) div 4 + 1);
end;

{$IFNDEF OPENGL}
var
  lightmapcolorintensityidx: integer = DEFLMCOLORSENSITIVITY div 8;

procedure M_ChangeLightmapColorIntensity(choice: integer);
begin
  case choice of
    0: if lightmapcolorintensityidx > 0 then
         dec(lightmapcolorintensityidx);
    1: if lightmapcolorintensityidx < (MAXLMCOLORSENSITIVITY - MINLMCOLORSENSITIVITY) div 8 then
         inc(lightmapcolorintensityidx);
  end;
  lightmapcolorintensity := MINLMCOLORSENSITIVITY + lightmapcolorintensityidx * 8;
end;

procedure M_ChangeLightmapFadeoutFunc(choice: integer);
begin
  r_lightmapfadeoutfunc :=  (r_lightmapfadeoutfunc + 1) mod NUMLIGHTMAPFADEOUTFUNCS;
end;

procedure M_ChangeLightmapLightWidthFactor(choice: integer);
begin
  case choice of
    0: if lightwidthfactor > MINLIGHTWIDTHFACTOR then
         dec(lightwidthfactor);
    1: if lightwidthfactor < MAXLIGHTWIDTHFACTOR then
         inc(lightwidthfactor);
  end;
end;

procedure M_LightmapDefaults(choice: integer);
begin
  lightmapcolorintensity := DEFLMCOLORSENSITIVITY;
  lightwidthfactor := DEFLIGHTWIDTHFACTOR;
  r_lightmapfadeoutfunc := 0;
end;

const
  strlightmapfadefunc: array[0..NUMLIGHTMAPFADEOUTFUNCS - 1] of string =
    ('LINEAR', 'CURVED', 'PERSIST', 'COSINE', 'SIGMOID');

procedure M_DrawOptionsLightmap;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Lightmap');

  r_lightmapfadeoutfunc := ibetween(r_lightmapfadeoutfunc, 0, NUMLIGHTMAPFADEOUTFUNCS - 1);
  lightmapcolorintensityidx := (lightmapcolorintensity - 32) div 8;

  ppos := M_WriteSmallText(OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * Ord(ol_lightmapfunc), 'Fadeout function: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, strlightmapfadefunc[r_lightmapfadeoutfunc], SCN_TMP);

  ppos := M_WriteSmallText(OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * Ord(ol_colorintensity), 'Color intensity: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, itoa((lightmapcolorintensity * 100) div DEFLMCOLORSENSITIVITY) + '%', SCN_TMP);
  M_DrawThermo(
    OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * (Ord(ol_colorintensity) + 1), 21, lightmapcolorintensityidx, (MAXLMCOLORSENSITIVITY - MINLMCOLORSENSITIVITY) div 8 + 1);

  ppos := M_WriteSmallText(OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * Ord(ol_lightwidthfactor), 'Distance from source: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, itoa((lightwidthfactor * 100) div DEFLIGHTWIDTHFACTOR) + '%', SCN_TMP);
  M_DrawThermo(
    OptionsLightmapDef.x, OptionsLightmapDef.y + OptionsLightmapDef.itemheight * (Ord(ol_lightwidthfactor) + 1), 21, lightwidthfactor, MAXLIGHTWIDTHFACTOR + 1);
end;
{$ENDIF}

procedure M_DrawOptionsDisplay32bit;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'True Color Options');
end;

{$IFDEF OPENGL}
procedure M_DrawOptionsDisplayOpenGL;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'OpenGL');
end;

procedure M_DrawOptionsDisplayOpenGLModels;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Models');
end;

procedure M_ChangeVoxelOptimization(choice: integer);
begin
  vx_maxoptimizerpasscount := GetIntegerInRange(vx_maxoptimizerpasscount, 0, MAX_VX_OPTIMIZE);
  if vx_maxoptimizerpasscount = MAX_VX_OPTIMIZE then
    vx_maxoptimizerpasscount := 0
  else
    vx_maxoptimizerpasscount := vx_maxoptimizerpasscount + 1;
end;

const
  str_voxeloptimizemethod: array[0..MAX_VX_OPTIMIZE] of string = (
    'FAST', 'GOOD', 'BETTER', 'BEST'
  );

procedure M_DrawOptionsDisplayOpenGLVoxels;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Voxels');

  vx_maxoptimizerpasscount := GetIntegerInRange(vx_maxoptimizerpasscount, 0, MAX_VX_OPTIMIZE);
  ppos := M_WriteSmallText(OptionsDisplayOpenGLVoxelsDef.x, OptionsDisplayOpenGLVoxelsDef.y + OptionsDisplayOpenGLVoxelsDef.itemheight * Ord(od_glv_optimize), 'Voxel mesh optimization: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, str_voxeloptimizemethod[vx_maxoptimizerpasscount], SCN_TMP);
end;

procedure M_ChangeTextureFiltering(choice: integer);
begin
  gld_SetCurrTexFiltering(gl_filter_t((Ord(gld_GetCurrTexFiltering) + 1) mod Ord(NUM_GL_FILTERS)));
  gld_ClearTextureMemory;
end;

procedure M_DrawOptionsDisplayOpenGLFilter;
var
  ppos: menupos_t;
begin
  M_DrawHeadLine(15, 'Display Options');
  M_DrawSubHeadLine(40, 'Texture Filtering');

  ppos := M_WriteSmallText(OptionsDisplayOpenGLFilterDef.x, OptionsDisplayOpenGLFilterDef.y + OptionsDisplayOpenGLFilterDef.itemheight * Ord(od_glf_texture_filter), 'Filter: ', SCN_TMP);
  M_WriteSmallWhiteText(ppos.x, ppos.y, gl_tex_filter_string, SCN_TMP);
end;
{$ENDIF}

procedure M_Options(choice: integer);
begin
  M_SetupNextMenu(@OptionsDef);
end;

procedure M_TopTen(choice: integer);
begin
  M_SetupNextMenu(@TopTenDef);
end;

procedure M_TopTenExit(choice: integer);
begin
  M_SetupNextMenu(@MainDef);
end;

procedure M_DrawTopTen;
const
  AA_START = 18;
  NAME_START = 26;
  EPIDODE_START = 112;
  MAP_START = 174;
  SKILL_START = 204;
  SCORE_START = 250;
  Y_TITLE = 30;
  Y_START = 50;
  Y_SPACING = 12;
var
  i, y: integer;
  score: Pscrotetableitem_t;
  s: string;
  len: integer;
begin
  V_DrawPatch(0, 0, SCN_TMP, 'TopTenScreen', false);

  // Header
  M_WriteSmallWhiteText(NAME_START, Y_TITLE, 'Name', SCN_TMP);
  M_WriteSmallWhiteText(EPIDODE_START, Y_TITLE, 'Episode', SCN_TMP);
  M_WriteSmallWhiteText(MAP_START, Y_TITLE, 'Map', SCN_TMP);
  M_WriteSmallWhiteText(SKILL_START, Y_TITLE, 'Skill', SCN_TMP);
  M_WriteSmallWhiteText(SCORE_START, Y_TITLE, 'Score', SCN_TMP);

  // Scores
  for i := 0 to NUMSCORES - 1 do
  begin
    score := RX_GetScoreTableId(i);
    if score <> nil then
      if (score.episode <> 0) and (score.map <> 0) then
      begin
        y := Y_START + i * Y_SPACING;

        s := itoa(i + 1);
        len := M_SmallStringWidth(s);
        M_WriteSmallWhiteText(AA_START - len, y, s, SCN_TMP);

        M_WriteSmallText(NAME_START, y, score.name, SCN_TMP);

        case score.episode of
          1: s := 'THETA 2';
          2: s := 'VEGEANCE';
          3: s := 'THE VOID';
        else
          s := itoa(score.episode);
        end;
        M_WriteSmallText(EPIDODE_START, y, s, SCN_TMP);

        M_WriteSmallText(MAP_START, y, itoa(score.map), SCN_TMP);

        case Ord(score.skill) of
          0: s := 'Easiest';
          1: s := 'Easy';
          2: s := 'Normal';
          3: s := 'Hard';
        else
          s := itoa(Ord(score.skill));
        end;
        M_WriteSmallText(SKILL_START, y, s, SCN_TMP);

        M_WriteSmallText(SCORE_START, y, itoa(score.rating), SCN_TMP);
      end;
  end;
end;

//
//      Toggle messages on/off
//
procedure M_ChangeMessages(choice: integer);
begin
  showMessages := 1 - showMessages;

  if showMessages = 0 then
    players[consoleplayer]._message := MSGOFF
  else
    players[consoleplayer]._message := MSGON;

  message_dontfuckwithme := true;
end;

//
// M_EndGame
//
procedure M_EndGameResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  currentMenu.lastOn := itemOn;
  M_ClearMenus;
  D_StartTitle;
end;

procedure M_CmdEndGame;
begin
  if not usergame then
  begin
    M_MenuSound;
    exit;
  end;

  if netgame then
  begin
    M_StartMessage(NETEND + #13#10 + PRESSKEY, nil, false);
    exit;
  end;

  M_StartMessage(SENDGAME + #13#10 + PRESSYN, @M_EndGameResponse, true);
  C_ExecuteCmd('closeconsole', '1');
end;

procedure M_EndGame(choice: integer);
begin
  M_CmdEndGame;
end;

//
// M_ReadThis
//
procedure M_ReadThis(choice: integer);
begin
  M_SetupNextMenu(@ReadDef1);
end;

procedure M_ReadThis2(choice: integer);
begin
  M_SetupNextMenu(@ReadDef2);
end;

procedure M_FinishReadThis(choice: integer);
begin
  if extrahelpscreens.Count > 0 then
  begin
    extrahelpscreens_idx := 0;
    M_SetupNextMenu(@ReadDefExt);
  end
  else
    M_SetupNextMenu(@MainDef);
end;

procedure M_FinishReadExtThis(choice: integer);
begin
  inc(extrahelpscreens_idx);
  if extrahelpscreens_idx >= extrahelpscreens.Count then
  begin
    extrahelpscreens_idx := 0;
    M_SetupNextMenu(@MainDef);
  end;
end;

//
// M_QuitRADIX
//
procedure M_CmdQuit;
begin
  S_StartSound(nil, 'radix/SndTelePort');
  I_WaitVBL(1000);
  G_Quit;
end;


procedure M_QuitResponse(ch: integer);
begin
  if ch <> Ord('y') then
    exit;

  M_CmdQuit;
end;

procedure M_QuitRADIX(choice: integer);
var
  endstring: string;
begin
  sprintf(endstring, '%s'#13#10#13#10 + DOSY, [QUITMSG]);

  M_StartMessage(endstring, @M_QuitResponse, true);
end;

procedure M_ChangeSensitivity(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivity > 0 then
        dec(mouseSensitivity);
    1:
      if mouseSensitivity < 19 then
        inc(mouseSensitivity);
  end;
end;

procedure M_ChangeSensitivityX(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivityX > 0 then
        dec(mouseSensitivityX);
    1:
      if mouseSensitivityX < 10 then
        inc(mouseSensitivityX);
  end;
end;

procedure M_ChangeSensitivityY(choice: integer);
begin
  case choice of
    0:
      if mouseSensitivityY > 0 then
        dec(mouseSensitivityY);
    1:
      if mouseSensitivityY < 10 then
        inc(mouseSensitivityY);
  end;
end;

procedure M_KeyBindings(choice: integer);
begin
  M_SetupNextMenu(@KeyBindingsDef1);
end;

procedure M_ScreenShotCmd(choice: integer);
begin
  M_FixScreenshotFormat;
  if strupper(screenshotformat) = 'PNG' then
    screenshotformat := 'JPG'
  else if strupper(screenshotformat) = 'JPG' then
    screenshotformat := 'TGA'
  else if strupper(screenshotformat) = 'TGA' then
    screenshotformat := 'PNG'
  else
    screenshotformat := 'PNG';
end;

procedure M_ChangeDetail(choice: integer);
begin
  detailLevel := (detailLevel + 1) mod DL_NUMRESOLUTIONS;

  R_SetViewSize;

  case detailLevel of
    DL_MEDIUM:
      players[consoleplayer]._message := DETAILMED;
    DL_NORMAL:
      players[consoleplayer]._message := DETAILNORM;
  end;

end;

procedure M_ChangeScreenSize(choice: integer);
begin
  case choice of
    0:
      if mdisplaymode_idx > 0 then
        dec(mdisplaymode_idx);
    1:
      if mdisplaymode_idx < numdisplaymodes - 1 then
        inc(mdisplaymode_idx);
  end;
end;

procedure M_ApplyScreenSize(choice: integer);
begin
  if mdisplaymode_idx < 0 then
    mdisplaymode_idx := 0
  else if mdisplaymode_idx >= numdisplaymodes then
    mdisplaymode_idx := numdisplaymodes - 1;

  OptionsDisplayVideoModeDef.lastOn := 0;
  itemOn := 0;

  D_NotifyVideoModeChange(displaymodes[mdisplaymode_idx].width, displaymodes[mdisplaymode_idx].height);
end;

procedure M_BoolCmd(choice: integer);
var
  s: string;
begin
  s := currentMenu.menuitems[choice].cmd;
  if length(s) = 0 then
    I_Error('M_BoolCmd(): Unknown option');
  C_ExecuteCmd(s, yesnoStrings[not currentMenu.menuitems[choice].pBoolVal^]);
end;

procedure M_BoolCmdSetSize(choice: integer);
begin
  M_BoolCmd(choice);
  setsizeneeded := true;
end;

procedure M_SizeDisplay(choice: integer);
begin
  case choice of
    0:
      begin
        if m_screensize > 0 then
        begin
          dec(screenblocks);
          dec(m_screensize);
        end;
      end;
    1:
      begin
        if m_screensize < 10 then
        begin
          inc(screenblocks);
          inc(m_screensize);
        end;
      end;
  end;

  R_SetViewSize;
end;

//
// CONTROL PANEL
//

//
// M_Responder
//
var
  joywait: integer;
  mousewait: integer;
  mmousex: integer;
  mmousey: integer;
  mlastx: integer;
  mlasty: integer;
  m_altdown: boolean = false;

function M_Responder(ev: Pevent_t): boolean;
var
  ch: integer;
  i: integer;
  palette: PByteArray;
begin
  if gamestate = GS_ENDOOM then
  begin
    result := false;
    exit;
  end;

  if (ev.data1 = KEY_RALT) or (ev.data1 = KEY_LALT) then
  begin
    m_altdown := ev._type = ev_keydown;
    result := false;
    exit;
  end;

  ch := -1;

  if (ev._type = ev_joystick) and (joywait < I_GetTime) then
  begin
    if ev.data3 < 0 then
    begin
      ch := KEY_UPARROW;
      joywait := I_GetTime + 5;
    end
    else if ev.data3 > 0 then
    begin
      ch := KEY_DOWNARROW;
      joywait := I_GetTime + 5;
    end;

    if ev.data2 < 0 then
    begin
      ch := KEY_LEFTARROW;
      joywait := I_GetTime + 2;
    end
    else if ev.data2 > 0 then
    begin
      ch := KEY_RIGHTARROW;
      joywait := I_GetTime + 2;
    end;

    if ev.data1 and 1 <> 0 then
    begin
      ch := KEY_ENTER;
      joywait := I_GetTime + 5;
    end;
    if ev.data1 and 2 <> 0 then
    begin
      ch := KEY_BACKSPACE;
      joywait := I_GetTime + 5;
    end;
  end
  else if (ev._type = ev_mouse) and (mousewait < I_GetTime) then
  begin
    mmousey := mmousey + ev.data3;
    if mmousey < mlasty - 30 then
    begin
      ch := KEY_DOWNARROW;
      mousewait := I_GetTime + 5;
      mlasty := mlasty - 30;
      mmousey := mlasty;
    end
    else if mmousey > mlasty + 30 then
    begin
      ch := KEY_UPARROW;
      mousewait := I_GetTime + 5;
      mlasty := mlasty + 30;
      mmousey := mlasty;
    end;

    mmousex := mmousex + ev.data2;
    if mmousex < mlastx - 30 then
    begin
      ch := KEY_LEFTARROW;
      mousewait := I_GetTime + 5;
      mlastx := mlastx - 30;
      mmousex := mlastx;
    end
    else if mmousex > mlastx + 30 then
    begin
      ch := KEY_RIGHTARROW;
      mousewait := I_GetTime + 5;
      mlastx := mlastx + 30;
      mmousex := mlastx;
    end;

    if ev.data1 and 1 <> 0 then
    begin
      ch := KEY_ENTER;
      mousewait := I_GetTime + 15;
    end;

    if ev.data1 and 2 <> 0 then
    begin
      ch := KEY_BACKSPACE;
      mousewait := I_GetTime + 15;
    end
  end
  else if ev._type = ev_keydown then
    ch := ev.data1;

  if ch = -1 then
  begin
    result := false;
    exit;
  end;

  if pilotStringEnter <> 0 then
  begin
    case ch of
      KEY_BACKSPACE:
        begin
          if pilotCharIndex > 0 then
          begin
            dec(pilotCharIndex);
            SetLength(pilotNameString, pilotCharIndex);
            pilotname := pilotNameString;
          end;
        end;
      KEY_ESCAPE:
        begin
          pilotStringEnter := 0;
          pilotNameString := pilotOldString;
          pilotname := pilotNameString;
          M_PilotName(0);
        end;
      KEY_ENTER:
        begin
          pilotStringEnter := 0;
          players[consoleplayer].playername := pilotNameString;
          pilotname := pilotNameString;
          M_PilotName(0);
        end
    else
      begin
        ch := Ord(toupper(Chr(ch)));
        if ch <> 32 then
        if (ch - Ord(HU_FONTSTART) < 0) or (ch - Ord(HU_FONTSTART) >= HU_FONTSIZE) then
        else
        begin
          if (ch >= 32) and (ch <= 127) and
             (pilotCharIndex < PILOTNAMESIZE - 1) {and
             (M_SmallStringWidth(savegamestrings[saveSlot]) < (SAVESTRINGSIZE - 2) * 8)} then
          begin
            inc(pilotCharIndex);
            pilotNameString := pilotNameString + Chr(ch);
            pilotname := pilotNameString;
          end;
        end;
      end;
    end;
    result := true;
    exit;
  end;

  // Save Game string input
  if saveStringEnter <> 0 then
  begin
    case ch of
      KEY_BACKSPACE:
        begin
          if saveCharIndex > 0 then
          begin
            dec(saveCharIndex);
            SetLength(savegamestrings[saveSlot], saveCharIndex);
          end;
        end;
      KEY_ESCAPE:
        begin
          saveStringEnter := 0;
          savegamestrings[saveSlot] := saveOldString;
        end;
      KEY_ENTER:
        begin
          saveStringEnter := 0;
          if savegamestrings[saveSlot] <> '' then
            M_DoSave(saveSlot);
        end
    else
      begin
        ch := Ord(toupper(Chr(ch)));
        if ch <> 32 then
        if (ch - Ord(HU_FONTSTART) < 0) or (ch - Ord(HU_FONTSTART) >= HU_FONTSIZE) then
        else
        begin
          if (ch >= 32) and (ch <= 127) and
             (saveCharIndex < SAVESTRINGSIZE - 1) and
             (M_SmallStringWidth(savegamestrings[saveSlot]) < (SAVESTRINGSIZE - 2) * 8) then
          begin
            inc(saveCharIndex);
            savegamestrings[saveSlot] := savegamestrings[saveSlot] + Chr(ch);
          end;
        end;
      end;
    end;
    result := true;
    exit;
  end;

  // Key bindings
  if bindkeyEnter then
  begin
    case ch of
      KEY_ESCAPE:
        begin
          bindkeyEnter := false;
          KeyBindingsInfo[bindkeySlot].pkey^ := saveOldkey;
        end;
      KEY_ENTER:
        begin
          bindkeyEnter := false;
        end;
    else
      M_SetKeyBinding(bindkeySlot, ch);
      bindkeyEnter := false;
    end;
    result := true;
    exit;
  end;

  // Take care of any messages that need input
  if messageToPrint <> 0 then
  begin
    if messageNeedsInput and ( not(
      (ch = Ord(' ')) or (ch = Ord('n')) or (ch = Ord('y')) or (ch = KEY_ESCAPE))) then
    begin
      result := false;
      exit;
    end;

    menuactive := messageLastMenuActive;
    messageToPrint := 0;
    if Assigned(messageRoutine) then
      messageRoutine(ch);

    result := true;

    if I_GameFinished then
      exit;

    menuactive := false;
    M_MenuSound;
    exit;
  end;

  // F-Keys
  if not menuactive then
    case ch of
      KEY_MINUS:    // Screen size down
        begin
          if (amstate = am_only) or chat_on then
          begin
            result := false;
            exit;
          end;
          M_SizeDisplay(0);
          S_StartSound(nil, 'radix/SndPowerUp');
          result := true;
          exit;
        end;
      KEY_EQUALS, Ord('+'):   // Screen size up
        begin
          if (amstate = am_only) or chat_on then
          begin
            result := false;
            exit;
          end;
          M_SizeDisplay(1);
          S_StartSound(nil, 'radix/SndPowerUp');
          result := true;
          exit;
        end;
      KEY_F1:      // Help key
        begin
          M_StartControlPanel;
          currentMenu := @ReadDef1;

          itemOn := 0;
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F2:  // Save
        begin
          M_StartControlPanel;
          M_MenuSound;
          M_SaveGame(0);
          result := true;
          exit;
        end;
      KEY_F3:  // Load
        begin
          M_StartControlPanel;
          M_MenuSound;
          M_LoadGame(0);
          result := true;
          exit;
        end;
      KEY_F4:   // Sound Volume
        begin
          M_StartControlPanel;
          currentMenu := @SoundVolDef;
          itemOn := Ord(sfx_vol);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F5:   // Detail toggle
        begin
          M_ChangeDetail(0);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F6:   // Quicksave
        begin
          M_MenuSound;
          M_QuickSave;
          result := true;
          exit;
        end;
      KEY_F7:   // End game
        begin
          M_MenuSound;
          M_EndGame(0);
          result := true;
          exit;
        end;
      KEY_F8:   // Toggle messages
        begin
          M_ChangeMessages(0);
          M_MenuSound;
          result := true;
          exit;
        end;
      KEY_F9:   // Quickload
        begin
          M_MenuSound;
          M_QuickLoad;
          result := true;
          exit;
        end;
      KEY_F10:  // Quit DOOM
        begin
          M_MenuSound;
          M_QuitRADIX(0);
          result := true;
          exit;
        end;
      KEY_F11:  // gamma toggle
        begin
          inc(usegamma);
          if usegamma >= GAMMASIZE then
            usegamma := 0;
          players[consoleplayer]._message := gammamsg[usegamma];
          palette := V_ReadPalette(PU_STATIC);
          {$IFDEF OPENGL}
          I_SetPalette(palette);
          V_SetPalette(palette);
          {$ELSE}
          IV_SetPalette(palette);
          {$ENDIF}
          Z_ChangeTag(palette, PU_CACHE);
          result := true;
          exit;
        end;
      KEY_F12:  // JVAL: 20200420 - In game briefing/objectives
        begin
          if usergame and (gamestate = GS_LEVEL) then
          begin
            M_StartControlPanel;
            currentMenu := @InTextDef;

            itemOn := 0;
            M_MenuSound;
          end;
          result := true;
          exit;
        end;
      KEY_ENTER:
        begin
          if m_altdown then
          begin
          {$IFDEF OPENGL}
            GL_ChangeFullScreen(not fullscreen);
          {$ELSE}
            I_ChangeFullScreen((fullscreen + 1) mod NUMFULLSCREEN_MODES);
          {$ENDIF}
            result := true;
            exit;
          end;
        end;
    end;

  // Pop-up menu?
  if not menuactive then
  begin
    if ch = KEY_ESCAPE then
    begin
      M_StartControlPanel;
      M_MenuSound;
      result := true;
      exit;
    end;
    result := false;
    exit;
  end;

  // Keys usable within menu
  case ch of
    KEY_PAGEUP:
      begin
        itemOn := -1;
        repeat
          inc(itemOn);
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_PAGEDOWN:
      begin
        itemOn := currentMenu.numitems;
        repeat
          dec(itemOn);
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_DOWNARROW:
      begin
        repeat
          if itemOn + 1 > currentMenu.numitems - 1 then
            itemOn := 0
          else
            inc(itemOn);
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_UPARROW:
      begin
        repeat
          if itemOn = 0 then
            itemOn := currentMenu.numitems - 1
          else
            dec(itemOn);
          M_MenuSound;
        until currentMenu.menuitems[itemOn].status <> -1;
        result := true;
        exit;
      end;
    KEY_LEFTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          M_MenuSound;
          currentMenu.menuitems[itemOn].routine(0);
        end
        else if (currentMenu.leftMenu <> nil) and not (ev._type in [ev_mouse, ev_joystick]) then
        begin
          currentMenu.lastOn := itemOn;
          currentMenu := currentMenu.leftMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
        end;
        result := true;
        exit;
      end;
    KEY_RIGHTARROW:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status = 2) then
        begin
          M_MenuSound;
          currentMenu.menuitems[itemOn].routine(1);
        end
        else if (currentMenu.rightMenu <> nil) and not (ev._type in [ev_mouse, ev_joystick]) then
        begin
          currentMenu.lastOn := itemOn;
          currentMenu := currentMenu.rightMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
        end;
        result := true;
        exit;
      end;
    KEY_ENTER:
      begin
        if Assigned(currentMenu.menuitems[itemOn].routine) and
          (currentMenu.menuitems[itemOn].status <> 0) then
        begin
          currentMenu.lastOn := itemOn;
          if currentMenu.menuitems[itemOn].status = 2 then
          begin
            currentMenu.menuitems[itemOn].routine(1); // right arrow
            M_MenuSound;
          end
          else
          begin
            currentMenu.menuitems[itemOn].routine(itemOn);
            M_MenuSound;
          end;
        end;
        result := true;
        exit;
      end;
    KEY_ESCAPE:
      begin
        currentMenu.lastOn := itemOn;
        M_ClearMenus;
        M_MenuSound;
        result := true;
        exit;
      end;
    KEY_F12:
      begin
        if currentmenu = @InTextDef then
        begin
          currentMenu.lastOn := itemOn;
          M_ClearMenus;
          M_MenuSound;
        end;
        result := true;
        exit;
      end;
    KEY_BACKSPACE:
      begin
        currentMenu.lastOn := itemOn;
        // JVAL 20200122 - Extended help screens
        if (currentMenu = @ReadDefExt) and (extrahelpscreens_idx > 0) then
        begin
          dec(extrahelpscreens_idx);
          M_MenuSound;
        end
        else if currentMenu.prevMenu <> nil then
        begin
          currentMenu := currentMenu.prevMenu;
          itemOn := currentMenu.lastOn;
          M_MenuSound;
        end;
        result := true;
        exit;
      end;
  else
    begin
      for i := itemOn + 1 to currentMenu.numitems - 1 do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          M_MenuSound;
          result := true;
          exit;
        end;
      for i := 0 to itemOn do
        if currentMenu.menuitems[i].alphaKey = Chr(ch) then
        begin
          itemOn := i;
          M_MenuSound;
          result := true;
          exit;
        end;
    end;
  end;

  result := false;
end;

//
// M_StartControlPanel
//
procedure M_StartControlPanel;
begin
  // intro might call this repeatedly
  if menuactive then
    exit;

  mn_makescreenshot := true;
  menuactive := true;
  currentMenu := @MainDef;// JDC
  itemOn := currentMenu.lastOn; // JDC
end;

//
// JVAL
// Threaded shades the half screen
//
function M_Thr_ShadeScreen(p: pointer): integer; stdcall;
var
  half: integer;
begin
{$IFDEF OPENGL}
  half := V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) div 2;
  V_ShadeBackground(half, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) - half);
{$ELSE}
  half := SCREENWIDTH * SCREENHEIGHT div 2;
  V_ShadeScreen(SCN_FG, half, SCREENWIDTH * SCREENHEIGHT - half);
{$ENDIF}
  result := 0;
end;

var
  threadmenushader: TDThread;

procedure M_MenuShader;
begin
  shademenubackground := shademenubackground mod 3;
  if not wipedisplay and (shademenubackground >= 1) then
  begin
    if usemultithread then
    begin
    // JVAL
      threadmenushader.Activate(nil);
      {$IFDEF OPENGL}
      V_ShadeBackground(0, V_GetScreenWidth(SCN_FG) * V_GetScreenHeight(SCN_FG) div 2);
      {$ELSE}
      V_ShadeScreen(SCN_FG, 0, SCREENWIDTH * SCREENHEIGHT div 2);
      {$ENDIF}
      // Wait for extra thread to terminate.
      threadmenushader.Wait;
    end
    else
      {$IFDEF OPENGL}
      V_ShadeBackground;
      {$ELSE}
      V_ShadeScreen(SCN_FG);
      {$ENDIF}
  end;
end;

procedure M_FinishUpdate(const height: integer);
begin
  // JVAL
  // Menu is no longer drawn to primary surface,
  // Instead we use SCN_TMP and after the drawing we blit to primary surface
  if inhelpscreens then
  begin
    V_CopyRectTransparent(0, 0, SCN_TMP, 320, 200, 0, 0, SCN_FG, true);
    inhelpscreens := false;
  end
  else
  begin
    M_MenuShader;
    V_CopyRectTransparent(0, 0, SCN_TMP, 320, height, 0, 0, SCN_FG, true);
  end;
end;

//
// M_Drawer
// Called after the view has been rendered,
// but before it has been blitted.
//
procedure M_Drawer;
var
  i: integer;
  max: integer;
  str: string;
  len: integer;
  x, y: integer;
  mheight: integer;
  ppos: menupos_t;
  rstr: string;
  rlen: integer;
begin
  // Horiz. & Vertically center string and print it.
  if messageToPrint <> 0 then
  begin
    mheight := M_SmallStringHeight(messageString) + 2;
    y := (200 - mheight) div 2;
    mheight := y + mheight + 20;
    MT_ZeroMemory(screens[SCN_TMP], 320 * mheight);
    len := Length(messageString);
    str := '';
    for i := 1 to len do
    begin
      if messageString[i] = #13 then
      else if messageString[i] = #10 then
      begin
        y := y + hu_font[0].height + 2;
        x := (320 - M_SmallStringWidth(str)) div 2;
        M_WriteSmallText(x, y, str, SCN_TMP);
        str := '';
      end
      else
        str := str + messageString[i];
    end;
    if str <> '' then
    begin
      x := (320 - M_SmallStringWidth(str)) div 2;
      y := y + hu_font[0].height + 2;
      M_WriteSmallText(x, y, str, SCN_TMP);
    end;

    M_FinishUpdate(mheight);
    exit;
  end;

  if not menuactive then
    exit;

  MT_ZeroMemory(screens[SCN_TMP], 320 * 200);

  if (shademenubackground = 2) and (currentMenu.flags and FLG_MN_TEXTUREBK <> 0) then
    M_DrawFlatBackground(menubackgroundflat);

  // DRAW MENU
  x := DEF_MENU_ITEMS_START_X;
  y := DEF_MENU_ITEMS_START_Y;

  max := currentMenu.numitems;

  for i := 0 to max - 1 do
  begin
    str := currentMenu.menuitems[i].name;
    if str <> '' then
    begin
      if str[1] = '!' then // Draw text with Yes/No
      begin
        delete(str, 1, 1);
        if currentMenu.menuitems[i].pBoolVal <> nil then
        begin
          ppos := M_WriteSmallText(x, y, str + ': ', SCN_TMP);
          M_WriteSmallWhiteText(ppos.x, ppos.y, yesnoStrings[currentMenu.menuitems[i].pBoolVal^], SCN_TMP);
        end
        else
          M_WriteSmallText(x, y, str, SCN_TMP);
      end;
    end;
    y := y + currentMenu.itemheight;
  end;

  if Assigned(currentMenu.drawproc) then
    currentMenu.drawproc; // call Draw routine

  if currentMenu.leftMenu <> nil then
    M_WriteSmallWhiteText(5, 44, '<<', SCN_TMP);

  if currentMenu.rightMenu <> nil then
  begin
    rstr := '>>';
    rlen := M_SmallStringWidth(rstr);
    M_WriteSmallWhiteText(315 - rlen, 44, rstr, SCN_TMP);
  end;

  if currentMenu.flags and FLG_MN_DRAWITEMON <> 0 then
    V_DrawPatch(x + ARROWXOFFS, currentMenu.y + itemOn * currentMenu.itemheight + ARROWYOFFS, SCN_TMP, p_rightarrow, false);

  M_FinishUpdate(200);
end;

procedure M_CmdSetupNextMenu(menudef: Pmenu_t);
begin
  menuactive := true;
  if (menudef = @LoadDef) or (menudef = @SaveDef) then
    M_ReadSaveStrings;
  M_SetupNextMenu(menudef);
  C_ExecuteCmd('closeconsole');
end;

procedure M_CmdMenuMainDef;
begin
  M_CmdSetupNextMenu(@MainDef);
end;

procedure M_CmdMenuNewDef;
begin
  M_CmdSetupNextMenu(@NewDef);
end;

procedure M_CmdMenuOptionsDef;
begin
  M_CmdSetupNextMenu(@OptionsDef);
end;

procedure M_CmdMenuOptionsGeneralDef;
begin
  M_CmdSetupNextMenu(@OptionsGeneralDef);
end;

procedure M_CmdMenuOptionsDisplayDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayDef);
end;

procedure M_CmdMenuOptionsDisplayDetailDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayDetailDef);
end;

procedure M_CmdMenuOptionsDisplayAppearanceDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayAppearanceDef);
end;

procedure M_CmdMenuOptionsDisplayAdvancedDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplayAdvancedDef);
end;

procedure M_CmdMenuOptionsDisplay32bitDef;
begin
  M_CmdSetupNextMenu(@OptionsDisplay32bitDef);
end;

{$IFDEF OPENGL}
procedure M_CmdOptionsDisplayOpenGL;
begin
  M_CmdSetupNextMenu(@OptionsDisplayOpenGLDef);
end;
{$ENDIF}

procedure M_CmdMenuSoundDef;
begin
  M_CmdSetupNextMenu(@SoundDef);
end;

procedure M_CmdMenuSoundVolDef;
begin
  M_CmdSetupNextMenu(@SoundVolDef);
end;

procedure M_CmdMenuCompatibilityDef;
begin
  M_CmdSetupNextMenu(@CompatibilityDef);
end;

procedure M_CmdMenuControlsDef;
begin
  M_CmdSetupNextMenu(@ControlsDef);
end;

procedure M_CmdMenuSystemDef;
begin
  M_CmdSetupNextMenu(@SystemDef);
end;

procedure M_CmdMenuLoadDef;
begin
  M_CmdSetupNextMenu(@LoadDef);
end;

procedure M_CmdMenuSaveDef;
begin
  M_CmdSetupNextMenu(@SaveDef);
end;

//
// M_Init
//
procedure M_Init;
var
  i: integer;
  lump: integer;
begin
  currentMenu := @MainDef;
  menuactive := false;
  itemOn := currentMenu.lastOn;
  m_screensize := screenblocks - 4;
  messageToPrint := 0;
  messageString := '';
  messageLastMenuActive := menuactive;
  quickSaveSlot := -1;

  // Here we could catch other version dependencies,
  //  like HELP1/2, and four episodes.

  if gamemode = shareware then
  begin
    ReadDef2.x := 280;
    ReadDef2.y := 185; // x,y of menu
  end;

  // JVAL 20200122 - Extended help screens
  extrahelpscreens := TDNumberList.Create;
  for i := 1 to 99 do
  begin
    lump := W_CheckNumForName('HELP' + IntToStrzFill(2, i));
    if lump >= 0 then
      extrahelpscreens.Add(lump);
  end;
  extrahelpscreens_idx := 0;

  C_AddCmd('keyboardmode', @M_CmdKeyboardMode);
  C_AddCmd('exit, quit', @M_CmdQuit);
  C_AddCmd('halt', @I_Quit);
  C_AddCmd('set', @Cmd_Set);
  C_AddCmd('get', @Cmd_Get);
  C_AddCmd('typeof', @Cmd_TypeOf);
  C_AddCmd('endgame', @M_CmdEndGame);
  C_AddCmd('defaults, setdefaults', @M_SetDefaults);
  C_AddCmd('default, setdefault', @M_SetDefaults);
  C_AddCmd('menu_main', @M_CmdMenuMainDef);
  C_AddCmd('menu_newgame, menu_new', @M_CmdMenuNewDef);
  C_AddCmd('menu_options', @M_CmdMenuOptionsDef);
  C_AddCmd('menu_optionsgeneral, menu_generaloptions', @M_CmdMenuOptionsGeneralDef);
  C_AddCmd('menu_optionsdisplay, menu_displayoptions, menu_display', @M_CmdMenuOptionsDisplayDef);
{$IFDEF OPENGL}
  C_AddCmd('menu_optionsdisplayopengl, menu_optionsopengl, menu_opengl', @M_CmdOptionsDisplayOpenGL);
{$ELSE}
  C_AddCmd('menu_optionsdisplaydetail, menu_displaydetailoptions', @M_CmdMenuOptionsDisplayDetailDef);
{$ENDIF}
  C_AddCmd('menu_optionsdisplayappearence, menu_displayappearenceoptions, menu_displayappearence', @M_CmdMenuOptionsDisplayAppearanceDef);
  C_AddCmd('menu_optionsdisplayadvanced, menu_displayadvancedoptions, menu_displayadvanced', @M_CmdMenuOptionsDisplayAdvancedDef);
  C_AddCmd('menu_optionsdisplay32bit, menu_display32bitoptions, menu_display32bit', @M_CmdMenuOptionsDisplay32bitDef);
  C_AddCmd('menu_optionssound, menu_soundoptions, menu_sound', @M_CmdMenuSoundDef);
  C_AddCmd('menu_optionssoundvol, menu_soundvoloptions, menu_soundvol', @M_CmdMenuSoundVolDef);
  C_AddCmd('menu_optionscompatibility, menu_compatibilityoptions, menu_compatibility', @M_CmdMenuCompatibilityDef);
  C_AddCmd('menu_optionscontrols, menu_controlsoptions, menu_controls', @M_CmdMenuControlsDef);
  C_AddCmd('menu_optionssystem, menu_systemoptions, menu_system', @M_CmdMenuSystemDef);
  C_AddCmd('menu_load, menu_loadgame', @M_CmdMenuLoadDef);
  C_AddCmd('menu_save, menu_savegame', @M_CmdMenuSaveDef);
end;

procedure M_ShutDownMenus;
begin
  threadmenushader.Free;
  extrahelpscreens.Free;
end;

procedure M_InitMenus;
var
  i: integer;
  pmi: Pmenuitem_t;
begin
  threadmenushader := TDThread.Create(@M_Thr_ShadeScreen);

////////////////////////////////////////////////////////////////////////////////
//gammamsg
  gammamsg[0] := GAMMALVL0;
  gammamsg[1] := GAMMALVL1;
  gammamsg[2] := GAMMALVL2;
  gammamsg[3] := GAMMALVL3;
  gammamsg[4] := GAMMALVL4;

////////////////////////////////////////////////////////////////////////////////
  p_leftarrow := W_CacheLumpName('LeftArrow', PU_STATIC);
  p_rightarrow := W_CacheLumpName('RightArrow', PU_STATIC);

////////////////////////////////////////////////////////////////////////////////
// MainMenu
  pmi := @MainMenu[0];
  pmi.status := 1;
  pmi.name := 'New Game';
  pmi.cmd := '';
  pmi.routine := @M_NewGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'n';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Options';
  pmi.cmd := '';
  pmi.routine := @M_Options;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Load Game';
  pmi.cmd := '';
  pmi.routine := @M_LoadGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Save Game';
  pmi.cmd := '';
  pmi.routine := @M_SaveGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Ordering Info';
  pmi.cmd := '';
  pmi.routine := @M_ReadThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Top Ten';
  pmi.cmd := '';
  pmi.routine := @M_TopTen;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Quit';
  pmi.cmd := '';
  pmi.routine := @M_QuitRADIX;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'q';

////////////////////////////////////////////////////////////////////////////////
//MainDef
  MainDef.numitems := Ord(main_end);
  MainDef.prevMenu := nil;
  MainDef.menuitems := Pmenuitem_tArray(@MainMenu);
  MainDef.drawproc := @M_DrawMainMenu;  // draw routine
  MainDef.x := DEF_MENU_ITEMS_START_X;
  MainDef.y := DEF_MENU_ITEMS_START_Y;
  MainDef.lastOn := 0;
  MainDef.itemheight := BIGLINEHEIGHT;
  MainDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//EpisodeMenu
  pmi := @EpisodeMenu[0];
  pmi.status := 1;
  pmi.name := 'Episode 1 - Theta 2';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '1';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Episode 2 - Vegeance';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '2';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Episode 3 - The void';
  pmi.cmd := '';
  pmi.routine := @M_Episode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '3';

////////////////////////////////////////////////////////////////////////////////
//EpiDef
  EpiDef.numitems := Ord(ep_end); // # of menu items
  EpiDef.prevMenu := @MainDef; // previous menu
  EpiDef.menuitems := Pmenuitem_tArray(@EpisodeMenu);  // menu items
  EpiDef.drawproc := @M_DrawEpisode;  // draw routine
  EpiDef.x := DEF_MENU_ITEMS_START_X;
  EpiDef.y := DEF_MENU_ITEMS_START_Y;
  EpiDef.lastOn := Ord(ep1); // last item user was on in menu
  EpiDef.itemheight := BIGLINEHEIGHT;
  EpiDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//PilotNameMenu
  pmi := @PilotNameMenu[0];
  pmi.status := 1;
  pmi.name := 'Pilot name';
  pmi.cmd := '';
  pmi.routine := @M_PilotName;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'P';

////////////////////////////////////////////////////////////////////////////////
//PilotNameDef
  PilotNameDef.numitems := Ord(pn_end); // # of menu items
  PilotNameDef.prevMenu := @MainDef; // previous menu
  PilotNameDef.menuitems := Pmenuitem_tArray(@PilotNameMenu);  // menu items
  PilotNameDef.drawproc := @M_DrawPilotName;  // draw routine
  PilotNameDef.x := 108;
  PilotNameDef.y := 80;
  PilotNameDef.lastOn := Ord(pilotname1); // last item user was on in menu
  PilotNameDef.itemheight := BIGLINEHEIGHT;
  PilotNameDef.flags := 0;
                                   
////////////////////////////////////////////////////////////////////////////////
//NewGameMenu
  pmi := @NewGameMenu[0];
  pmi.status := 1;
  pmi.name := 'I can''t do this!';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'I''m as ready as I will ever be.';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'h';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Another glorious day in the core!';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'h';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Let''s kick some xonomorphic butt!';
  pmi.cmd := '';
  pmi.routine := @M_ChooseSkill;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'u';

////////////////////////////////////////////////////////////////////////////////
//NewDef
  NewDef.numitems := Ord(newg_end); // # of menu items
  NewDef.prevMenu := @EpiDef; // previous menu
  NewDef.menuitems := Pmenuitem_tArray(@NewGameMenu);  // menu items
  NewDef.drawproc := @M_DrawNewGame;  // draw routine
  NewDef.x := DEF_MENU_ITEMS_START_X;
  NewDef.y := DEF_MENU_ITEMS_START_Y;
  NewDef.lastOn := Ord(newg_toorough); // last item user was on in menu
  NewDef.itemheight := BIGLINEHEIGHT;
  NewDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//OptionsMenu
  pmi := @OptionsMenu[0];
  pmi.status := 1;
  pmi.name := 'General';
  pmi.cmd := '';
  pmi.routine := @M_OptionsGeneral;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Display';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplay;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Sound';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSound;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Gameplay';
  pmi.cmd := '';
  pmi.routine := @M_OptionsGameplay;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Compatibility';
  pmi.cmd := '';
  pmi.routine := @M_OptionsCompatibility;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Controls';
  pmi.cmd := '';
  pmi.routine := @M_OptionsConrols;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'System';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSystem;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'y';

////////////////////////////////////////////////////////////////////////////////
//OptionsDef
  OptionsDef.numitems := Ord(opt_end); // # of menu items
  OptionsDef.prevMenu := @MainDef; // previous menu
  OptionsDef.menuitems := Pmenuitem_tArray(@OptionsMenu);  // menu items
  OptionsDef.drawproc := @M_DrawOptions;  // draw routine
  OptionsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDef.lastOn := 0; // last item user was on in menu
  OptionsDef.itemheight := BIGLINEHEIGHT;
  OptionsDef.flags := FLG_MN_TEXTUREBK;

////////////////////////////////////////////////////////////////////////////////
//TopTenMenu
  pmi := @TopTenMenu[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_TopTenExit;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'g';


////////////////////////////////////////////////////////////////////////////////
//TopTenDef
  TopTenDef.numitems := Ord(tt_end); // # of menu items
  TopTenDef.prevMenu := @MainDef; // previous menu
  TopTenDef.menuitems := Pmenuitem_tArray(@TopTenMenu);  // menu items
  TopTenDef.drawproc := @M_DrawTopTen;  // draw routine
  TopTenDef.x := DEF_MENU_ITEMS_START_X;
  TopTenDef.y := DEF_MENU_ITEMS_START_Y;
  TopTenDef.lastOn := 0; // last item user was on in menu
  TopTenDef.itemheight := BIGLINEHEIGHT;
  TopTenDef.flags := FLG_MN_TEXTUREBK;

////////////////////////////////////////////////////////////////////////////////
//OptionsGeneralMenu
  pmi := @OptionsGeneralMenu[0];
  pmi.status := 1;
  pmi.name := 'End Game';
  pmi.cmd := '';
  pmi.routine := @M_EndGame;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Messages';
  pmi.cmd := '';
  pmi.routine := @M_ChangeMessages;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 2;
  pmi.name := 'Screen Size';
  pmi.cmd := '';
  pmi.routine := @M_SizeDisplay;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := 'Mouse Sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//OptionsGeneralDef
  OptionsGeneralDef.numitems := Ord(optgen_end); // # of menu items
  OptionsGeneralDef.prevMenu := @OptionsDef; // previous menu
  OptionsGeneralDef.leftMenu := @SystemDef;
  OptionsGeneralDef.rightMenu := @OptionsDisplayDef;
  OptionsGeneralDef.menuitems := Pmenuitem_tArray(@OptionsGeneralMenu);  // menu items
  OptionsGeneralDef.drawproc := @M_DrawGeneralOptions;  // draw routine
  OptionsGeneralDef.x := DEF_MENU_ITEMS_START_X;
  OptionsGeneralDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsGeneralDef.lastOn := 0; // last item user was on in menu
  OptionsGeneralDef.itemheight := BIGLINEHEIGHT;
  OptionsGeneralDef.flags := FLG_MN_TEXTUREBK;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayMenu
  pmi := @OptionsDisplayMenu[0];
  pmi.status := 1;
{$IFDEF OPENGL}
  pmi.name := 'OpenGL';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGL;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'o';
{$ELSE}
  pmi.name := 'Detail';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayDetail;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';
{$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Automap';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAutomap;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Appearence';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAppearance;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'Advanced';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayAdvanced;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := 1;
  pmi.name := 'True Color Options';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplay32bit;
  pmi.pBoolVal := nil;
  pmi.alphaKey := '3';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDef
  OptionsDisplayDef.numitems := Ord(optdisp_end); // # of menu items
  OptionsDisplayDef.prevMenu := @OptionsDef; // previous menu
  OptionsDisplayDef.leftMenu := @OptionsGeneralDef; // previous menu
  OptionsDisplayDef.rightMenu := @SoundDef; // previous menu
  OptionsDisplayDef.menuitems := Pmenuitem_tArray(@OptionsDisplayMenu);  // menu items
  OptionsDisplayDef.drawproc := @M_DrawDisplayOptions;  // draw routine
  OptionsDisplayDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayDef.itemheight := BIGLINEHEIGHT;
  OptionsDisplayDef.flags := FLG_MN_TEXTUREBK;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDetailMenu
  pmi := @OptionsDisplayDetailMenu[0];
  pmi.status := 1;
  pmi.name := '!Set video mode...';
  pmi.cmd := '';
  pmi.routine := @M_SetVideoMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeDetail;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayDetailDef
  OptionsDisplayDetailDef.numitems := Ord(optdispdetail_end); // # of menu items
  OptionsDisplayDetailDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayDetailDef.leftMenu := @OptionsDisplay32bitDef; // left menu
  OptionsDisplayDetailDef.rightMenu := @OptionsDisplayAutomapDef; // right menu
  OptionsDisplayDetailDef.menuitems := Pmenuitem_tArray(@OptionsDisplayDetailMenu);  // menu items
  OptionsDisplayDetailDef.drawproc := @M_DrawDisplayDetailOptions;  // draw routine
  OptionsDisplayDetailDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayDetailDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayDetailDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayDetailDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayDetailDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayVideoModeMenu
  pmi := @OptionsDisplayVideoModeMenu[0];
  pmi.status := 1;
  pmi.name := '!Fullscreen';
  pmi.cmd := '';
  pmi.routine := @M_ChangeFullScreen;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ChangeScreenSize;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ApplyScreenSize;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayVideoModeDef
  OptionsDisplayVideoModeDef.numitems := Ord(optdispvideomode_end); // # of menu items
  OptionsDisplayVideoModeDef.prevMenu := {$IFDEF OPENGL}@OptionsDisplayOpenGLDef{$ELSE}@OptionsDisplayDetailDef{$ENDIF}; // previous menu
  OptionsDisplayVideoModeDef.leftMenu := {$IFDEF OPENGL}@OptionsDisplayOpenGLDef{$ELSE}@OptionsDisplayDetailDef{$ENDIF}; // left menu
  OptionsDisplayVideoModeDef.menuitems := Pmenuitem_tArray(@OptionsDisplayVideoModeMenu);  // menu items
  OptionsDisplayVideoModeDef.drawproc := @M_DrawDisplaySetVideoMode;  // draw routine
  OptionsDisplayVideoModeDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayVideoModeDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayVideoModeDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayVideoModeDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayVideoModeDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAutomapMenu
  pmi := @OptionsDisplayAutomapMenu[0];
  pmi.status := 1;
  pmi.name := '!Allow automap overlay';
  pmi.cmd := 'allowautomapoverlay';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowautomapoverlay;
  pmi.alphaKey := 'o';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow automap rotation';
  pmi.cmd := 'allowautomaprotate';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowautomaprotate;
  pmi.alphaKey := 'r';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Textured Automap';
  pmi.cmd := 'texturedautomap';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @texturedautomap;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Automap grid';
  pmi.cmd := 'automapgrid';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @automapgrid;
  pmi.alphaKey := 'g';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAutomapDef
  OptionsDisplayAutomapDef.numitems := Ord(optdispautomap_end); // # of menu items
  OptionsDisplayAutomapDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAutomapDef.leftMenu := {$IFDEF OPENGL}@OptionsDisplayOpenGLDef{$ELSE}@OptionsDisplayDetailDef{$ENDIF}; // left menu
  OptionsDisplayAutomapDef.rightMenu := @OptionsDisplayAppearanceDef; // right menu
  OptionsDisplayAutomapDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAutomapMenu);  // menu items
  OptionsDisplayAutomapDef.drawproc := @M_DrawDisplayAutomapOptions;  // draw routine
  OptionsDisplayAutomapDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAutomapDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAutomapDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAutomapDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayAutomapDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAppearanceMenu
  pmi := @OptionsDisplayAppearanceMenu[0];
  pmi.status := 1;
  pmi.name := '!Display fps';
  pmi.cmd := 'drawfps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @drawfps;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Menu background';
  pmi.cmd := '';
  pmi.routine := @M_SwitchShadeMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display disk busy icon';
  pmi.cmd := 'displaydiskbusyicon';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @displaydiskbusyicon;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display ENDOOM screen';
  pmi.cmd := 'displayendscreen';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @displayendscreen;
  pmi.alphaKey := 'e';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Display demo playback progress';
  pmi.cmd := 'showdemoplaybackprogress';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @showdemoplaybackprogress;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw crosshair';
  pmi.cmd := 'drawcrosshair';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @drawcrosshair;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw keybar';
  pmi.cmd := 'drawkeybar';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @drawkeybar;
  pmi.alphaKey := 'k';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAppearanceDef
  OptionsDisplayAppearanceDef.numitems := Ord(optdispappearance_end); // # of menu items
  OptionsDisplayAppearanceDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAppearanceDef.leftMenu := @OptionsDisplayAutomapDef; // left menu
  OptionsDisplayAppearanceDef.rightMenu := @OptionsDisplayAdvancedDef; // rightmenu
  OptionsDisplayAppearanceDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAppearanceMenu);  // menu items
  OptionsDisplayAppearanceDef.drawproc := @M_DrawDisplayAppearanceOptions;  // draw routine
  OptionsDisplayAppearanceDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAppearanceDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAppearanceDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAppearanceDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayAppearanceDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedMenu
  pmi := @OptionsDisplayAdvancedMenu[0];
  pmi.status := 1;
  pmi.name := '!Aspect Ratio...';
  pmi.cmd := '';
  pmi.routine := @M_OptionAspectRatio;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Camera...';
  pmi.cmd := '';
  pmi.routine := @M_OptionCameraShift;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  {$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Lightmap...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayLightmap;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'l';
  {$ENDIF}

  {$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Asynchronous DirectX blit';
  pmi.cmd := 'r_bltasync';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @r_bltasync;
  pmi.alphaKey := 'a';
  {$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Transparent sprites';
  pmi.cmd := 'usetransparentsprites';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usetransparentsprites;
  pmi.alphaKey := 's';

{$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Diher 8 bit transparency';
  pmi.cmd := 'diher8bittransparency';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @diher8bittransparency;
  pmi.alphaKey := 'd';
{$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Uncapped framerate';
  pmi.cmd := 'interpolate';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @interpolate;
  pmi.alphaKey := 'u';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Interpolate on capped';
  pmi.cmd := 'interpolateoncapped';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @interpolateoncapped;
  pmi.alphaKey := 'i';

{$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!True 3d emulation';
  pmi.cmd := 'usefake3d';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usefake3d;
  pmi.alphaKey := 'f';
{$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Auto fix memory stall';
  pmi.cmd := 'fixstallhack';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @fixstallhack;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Billboard sky drawing';
  pmi.cmd := 'billboardsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @billboardsky;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Auto-adjust missing textures';
  pmi.cmd := 'autoadjustmissingtextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @autoadjustmissingtextures;
  pmi.alphaKey := 'a';

{$IFNDEF OPENGL}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Optimized column rendering';
  pmi.cmd := 'optimizedcolumnrendering';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @optimizedcolumnrendering;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Optimized things rendering';
  pmi.cmd := 'optimizedthingsrendering';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @optimizedthingsrendering;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Precise R_ScaleFromGlobalAngle';
  pmi.cmd := 'precisescalefromglobalangle';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @precisescalefromglobalangle;
  pmi.alphaKey := 'p';

  // JVAL: Slopes
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Precise but slow slope drawing';
  pmi.cmd := 'preciseslopedrawing';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preciseslopedrawing;
  pmi.alphaKey := 's';

{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAdvancedDef
  OptionsDisplayAdvancedDef.numitems := Ord(optdispadvanced_end); // # of menu items
  OptionsDisplayAdvancedDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayAdvancedDef.leftMenu := @OptionsDisplayAppearanceDef; // left menu
  OptionsDisplayAdvancedDef.rightMenu := @OptionsDisplay32bitDef; // right menu
  OptionsDisplayAdvancedDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAdvancedMenu);  // menu items
  OptionsDisplayAdvancedDef.drawproc := @M_DrawOptionsDisplayAdvanced;  // draw routine
  OptionsDisplayAdvancedDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAdvancedDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAdvancedDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAdvancedDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayAdvancedDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAspectRatioMenu
  pmi := @OptionsDisplayAspectRatioMenu[0];
  pmi.status := 1;
  pmi.name := '!Widescreen support';
  pmi.cmd := 'widescreensupport';
  pmi.routine := @M_BoolCmdSetSize;
  pmi.pBoolVal := @widescreensupport;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Player Sprites Stretch';
  pmi.cmd := 'excludewidescreenplayersprites';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @excludewidescreenplayersprites;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Force Aspect Ratio';
  pmi.cmd := '';
  pmi.routine := @M_SwitchForcedAspectRatio;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Intermission screens resize';
  pmi.cmd := 'intermissionstretch';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @intermissionstretch;
  pmi.alphaKey := 'i';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayAspectRatioDef
  OptionsDisplayAspectRatioDef.numitems := Ord(optdispaspect_end); // # of menu items
  OptionsDisplayAspectRatioDef.prevMenu := @OptionsDisplayAdvancedDef; // previous menu
  OptionsDisplayAspectRatioDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplayAspectRatioDef.menuitems := Pmenuitem_tArray(@OptionsDisplayAspectRatioMenu);  // menu items
  OptionsDisplayAspectRatioDef.drawproc := @M_DrawOptionsDisplayAspectRatio;  // draw routine
  OptionsDisplayAspectRatioDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayAspectRatioDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayAspectRatioDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayAspectRatioDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayAspectRatioDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayCameraMenu
  pmi := @OptionsDisplayCameraMenu[0];
  pmi.status := 1;
  pmi.name := '!Look Up/Down';
  pmi.cmd := 'zaxisshift';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @zaxisshift;
  pmi.alphaKey := 'z';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Chase camera';
  pmi.cmd := 'chasecamera';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @chasecamera;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Chase Camera XY position';
  pmi.cmd := '';
  pmi.routine := @M_ChangeCameraXY;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Chase Camera Z position';
  pmi.cmd := '';
  pmi.routine := @M_ChangeCameraZ;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'z';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;


////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayCameraDef
  OptionsDisplayCameraDef.numitems := Ord(optdispcamera_end); // # of menu items
  OptionsDisplayCameraDef.prevMenu := @OptionsDisplayAdvancedDef; // previous menu
  OptionsDisplayCameraDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplayCameraDef.menuitems := Pmenuitem_tArray(@OptionsDisplayCameraMenu);  // menu items
  OptionsDisplayCameraDef.drawproc := @M_DrawOptionsDisplayCamera;  // draw routine
  OptionsDisplayCameraDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayCameraDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayCameraDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayCameraDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayCameraDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

{$IFNDEF OPENGL}
////////////////////////////////////////////////////////////////////////////////
//OptionsLightmapMenu
  pmi := @OptionsLightmapMenu[0];

  pmi.status := 1;
  pmi.name := '!Light effects';
  pmi.cmd := 'r_uselightmaps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @r_uselightmaps;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Fadeout function';
  pmi.cmd := '';
  pmi.routine := @M_ChangeLightmapFadeoutFunc;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Color intensity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeLightmapColorIntensity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Distance from source';
  pmi.cmd := '';
  pmi.routine := @M_ChangeLightmapLightWidthFactor;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Reset to default...';
  pmi.cmd := '';
  pmi.routine := @M_LightmapDefaults;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'r';

////////////////////////////////////////////////////////////////////////////////
//OptionsLightmapDef
  OptionsLightmapDef.numitems := Ord(ol_lightmap_end); // # of menu items
  OptionsLightmapDef.prevMenu := @OptionsDisplayAdvancedDef; // previous menu
  OptionsLightmapDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsLightmapDef.menuitems := Pmenuitem_tArray(@OptionsLightmapMenu);  // menu items
  OptionsLightmapDef.drawproc := @M_DrawOptionsLightmap;  // draw routine
  OptionsLightmapDef.x := DEF_MENU_ITEMS_START_X;
  OptionsLightmapDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsLightmapDef.lastOn := 0; // last item user was on in menu
  OptionsLightmapDef.itemheight := SMALLLINEHEIGHT;
  OptionsLightmapDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;
{$ENDIF}
////////////////////////////////////////////////////////////////////////////////
//OptionsDisplay32bitMenu
  pmi := @OptionsDisplay32bitMenu[0];
  pmi.status := 1;
  pmi.name := '!Glow light effects';
  pmi.cmd := 'uselightboost';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @uselightboost;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use 32 bit colormaps';
  pmi.cmd := 'forcecolormaps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @forcecolormaps;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!32 bit palette effect simulation';
  pmi.cmd := '32bittexturepaletteeffects';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @dc_32bittexturepaletteeffects;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use classic fuzz effect in 32 bit';
  pmi.cmd := 'use32bitfuzzeffect';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @use32bitfuzzeffect;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external textures';
  pmi.cmd := 'useexternaltextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useexternaltextures;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search texture paths in PK3';
  pmi.cmd := 'preferetexturesnamesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferetexturesnamesingamedirectory;
  pmi.alphaKey := 'p';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplay32bitDef
  OptionsDisplay32bitDef.numitems := Ord(optdisp32bit_end); // # of menu items
  OptionsDisplay32bitDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplay32bitDef.leftMenu := @OptionsDisplayAdvancedDef; // left menu
  OptionsDisplay32bitDef.rightMenu := {$IFDEF OPENGL}@OptionsDisplayOpenGLDef{$ELSE}@OptionsDisplayDetailDef{$ENDIF}; // right menu
  OptionsDisplay32bitDef.menuitems := Pmenuitem_tArray(@OptionsDisplay32bitMenu);  // menu items
  OptionsDisplay32bitDef.drawproc := @M_DrawOptionsDisplay32bit;  // draw routine
  OptionsDisplay32bitDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplay32bitDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplay32bitDef.lastOn := 0; // last item user was on in menu
  OptionsDisplay32bitDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplay32bitDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

{$IFDEF OPENGL}
////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLMenu
  pmi := @OptionsDisplayOpenGLMenu[0];
  pmi.status := 1;
  pmi.name := '!Set video mode...';
  pmi.cmd := '';
  pmi.routine := @M_SetVideoMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Models...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLModels;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Voxels...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLVoxels;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Texture filtering...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsDisplayOpenGLFilter;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use fog';
  pmi.cmd := 'use_fog';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @use_fog;
  pmi.alphaKey := 'u';

  {$IFDEF DEBUG}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw Sky';
  pmi.cmd := 'gl_drawsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawsky;
  pmi.alphaKey := 's';
  {$ENDIF}

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use stencil buffer for sky';
  pmi.cmd := 'gl_stencilsky';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_stencilsky;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Render wireframe';
  pmi.cmd := 'gl_renderwireframe';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_renderwireframe;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use lightmaps';
  pmi.cmd := 'gl_uselightmaps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_uselightmaps;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw shadows';
  pmi.cmd := 'gl_drawshadows';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawshadows;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Draw all linedefs';
  pmi.cmd := 'gl_add_all_lines';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_add_all_lines;
  pmi.alphaKey := 'l';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use GL_NODES if available';
  pmi.cmd := 'useglnodesifavailable';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useglnodesifavailable;
  pmi.alphaKey := 'u';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Automatically load GWA files';
  pmi.cmd := 'autoloadgwafiles';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @autoloadgwafiles;
  pmi.alphaKey := 'g';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Limit framerate to screen sync';
  pmi.cmd := 'gl_screensync';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_screensync;
  pmi.alphaKey := 'y';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLDef
  OptionsDisplayOpenGLDef.numitems := Ord(optdispopengl_end); // # of menu items
  OptionsDisplayOpenGLDef.prevMenu := @OptionsDisplayDef; // previous menu
  OptionsDisplayOpenGLDef.leftMenu := @OptionsDisplay32bitDef; // left menu
  OptionsDisplayOpenGLDef.rightMenu := @OptionsDisplayAutomapDef; // right menu
  OptionsDisplayOpenGLDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLMenu);  // menu items
  OptionsDisplayOpenGLDef.drawproc := @M_DrawOptionsDisplayOpenGL;  // draw routine
  OptionsDisplayOpenGLDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayOpenGLDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLModelsMenu
  pmi := @OptionsDisplayOpenGLModelsMenu[0];
  pmi.status := 1;
  pmi.name := '!Draw models instead of sprites';
  pmi.cmd := 'gl_drawmodels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawmodels;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Smooth md2 model movement';
  pmi.cmd := 'gl_smoothmodelmovement';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_smoothmodelmovement;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Precache model textures';
  pmi.cmd := 'gl_precachemodeltextures';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_precachemodeltextures;
  pmi.alphaKey := 'p';

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLModelsDef
  OptionsDisplayOpenGLModelsDef.numitems := Ord(optglmodels_end); // # of menu items
  OptionsDisplayOpenGLModelsDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLModelsDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLModelsDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLModelsMenu);  // menu items
  OptionsDisplayOpenGLModelsDef.drawproc := @M_DrawOptionsDisplayOpenGLModels;  // draw routine
  OptionsDisplayOpenGLModelsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLModelsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLModelsDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLModelsDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayOpenGLModelsDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLVoxelsMenu
  pmi := @OptionsDisplayOpenGLVoxelsMenu[0];
  pmi.status := 1;
  pmi.name := '!Draw voxels instead of sprites';
  pmi.cmd := 'gl_drawvoxels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_drawvoxels;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Voxel mesh optimization';
  pmi.cmd := '';
  pmi.routine := @M_ChangeVoxelOptimization;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  {$IFDEF DEBUG}
  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Generate sprites from voxels';
  pmi.cmd := 'r_generatespritesfromvoxels';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @r_generatespritesfromvoxels;
  pmi.alphaKey := 'g';
  {$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLVoxelsDef
  OptionsDisplayOpenGLVoxelsDef.numitems := Ord(optglvoxels_end); // # of menu items
  OptionsDisplayOpenGLVoxelsDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLVoxelsDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLVoxelsDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLVoxelsMenu);  // menu items
  OptionsDisplayOpenGLVoxelsDef.drawproc := @M_DrawOptionsDisplayOpenGLVoxels;  // draw routine
  OptionsDisplayOpenGLVoxelsDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLVoxelsDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLVoxelsDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLVoxelsDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayOpenGLVoxelsDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLFilterMenu
  pmi := @OptionsDisplayOpenGLFilterMenu[0];
  pmi.status := 1;
  pmi.name := '!Filter';
  pmi.cmd := '';
  pmi.routine := @M_ChangeTextureFiltering;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Anisotropic texture filtering';
  pmi.cmd := 'gl_texture_filter_anisotropic';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_texture_filter_anisotropic;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Linear HUD filtering';
  pmi.cmd := 'gl_linear_hud';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @gl_linear_hud;
  pmi.alphaKey := 'l';
  
////////////////////////////////////////////////////////////////////////////////
//OptionsDisplayOpenGLFilterDef
  OptionsDisplayOpenGLFilterDef.numitems := Ord(optglfilter_end); // # of menu items
  OptionsDisplayOpenGLFilterDef.prevMenu := @OptionsDisplayOpenGLDef; // previous menu
  OptionsDisplayOpenGLFilterDef.leftMenu := @OptionsDisplayOpenGLDef; // left menu
  OptionsDisplayOpenGLFilterDef.menuitems := Pmenuitem_tArray(@OptionsDisplayOpenGLFilterMenu);  // menu items
  OptionsDisplayOpenGLFilterDef.drawproc := @M_DrawOptionsDisplayOpenGLFilter;  // draw routine
  OptionsDisplayOpenGLFilterDef.x := DEF_MENU_ITEMS_START_X;
  OptionsDisplayOpenGLFilterDef.y := DEF_MENU_ITEMS_START_Y;
  OptionsDisplayOpenGLFilterDef.lastOn := 0; // last item user was on in menu
  OptionsDisplayOpenGLFilterDef.itemheight := SMALLLINEHEIGHT;
  OptionsDisplayOpenGLFilterDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;
{$ENDIF}

////////////////////////////////////////////////////////////////////////////////
//ReadMenu1
  pmi := @ReadMenu1[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_ReadThis2;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef1
  ReadDef1.numitems := Ord(read1_end); // # of menu items
  ReadDef1.prevMenu := @MainDef; // previous menu
  ReadDef1.menuitems := Pmenuitem_tArray(@ReadMenu1);  // menu items
  ReadDef1.drawproc := @M_DrawReadThis1;  // draw routine
  ReadDef1.x := 330;
  ReadDef1.y := 165; // x,y of menu
  ReadDef1.lastOn := 0; // last item user was on in menu
  ReadDef1.itemheight := BIGLINEHEIGHT;
  ReadDef1.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//ReadMenu2
  pmi := @ReadMenu2[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_FinishReadThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDef2
  ReadDef2.numitems := Ord(read2_end); // # of menu items
  ReadDef2.prevMenu := @ReadDef1; // previous menu
  ReadDef2.menuitems := Pmenuitem_tArray(@ReadMenu2);  // menu items
  ReadDef2.drawproc := @M_DrawReadThis2;  // draw routine
  ReadDef2.x := 330;
  ReadDef2.y := 165; // x,y of menu
  ReadDef2.lastOn := 0; // last item user was on in menu
  ReadDef2.itemheight := BIGLINEHEIGHT;
  ReadDef2.flags := 0;

// JVAL 20200122 - Extended help screens
////////////////////////////////////////////////////////////////////////////////
//ReadMenuExt
  pmi := @ReadMenuExt[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_FinishReadExtThis;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//ReadDefExt
  ReadDefExt.numitems := Ord(readext_end); // # of menu items
  ReadDefExt.prevMenu := @ReadDef2; // previous menu
  ReadDefExt.menuitems := Pmenuitem_tArray(@ReadMenuExt);  // menu items
  ReadDefExt.drawproc := @M_DrawReadThisExt;  // draw routine
  ReadDefExt.x := 330;
  ReadDefExt.y := 165; // x,y of menu
  ReadDefExt.lastOn := 0; // last item user was on in menu
  ReadDefExt.itemheight := BIGLINEHEIGHT;
  ReadDefExt.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//SoundMenu
  pmi := @SoundMenu[0];
  pmi.status := 1;
  pmi.name := '!Volume Control...';
  pmi.cmd := '';
  pmi.routine := @M_SoundVolume;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'v';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external MP3 files';
  pmi.cmd := 'usemp3';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemp3;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search MP3 paths in PK3';
  pmi.cmd := 'preferemp3namesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferemp3namesingamedirectory;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use external WAV files';
  pmi.cmd := 'useexternalwav';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @useexternalwav;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Search WAV paths in PK3';
  pmi.cmd := 'preferewavnamesingamedirectory';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @preferewavnamesingamedirectory;
  pmi.alphaKey := 's';

////////////////////////////////////////////////////////////////////////////////
//SoundDef
  SoundDef.numitems := Ord(sound_end); // # of menu items
  SoundDef.prevMenu := @OptionsDef; // previous menu
  SoundDef.leftMenu := @OptionsDisplayDef; // left menu
  SoundDef.rightMenu := @CompatibilityDef; // left menu
  SoundDef.menuitems := Pmenuitem_tArray(@SoundMenu);  // menu items
  SoundDef.drawproc := @M_DrawSound;  // draw routine
  SoundDef.x := DEF_MENU_ITEMS_START_X;
  SoundDef.y := DEF_MENU_ITEMS_START_Y;
  SoundDef.lastOn := 0; // last item user was on in menu
  SoundDef.itemheight := SMALLLINEHEIGHT;
  SoundDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//SoundVolMenu
  pmi := @SoundVolMenu[0];
  pmi.status := 2;
  pmi.name := '!Sound FX Volume';
  pmi.cmd := '';
  pmi.routine := @M_SfxVol;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Music Volume';
  pmi.cmd := '';
  pmi.routine := @M_MusicVol;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//SoundVolDef
  SoundVolDef.numitems := Ord(soundvol_end); // # of menu items
  SoundVolDef.prevMenu := @SoundDef; // previous menu
  SoundVolDef.menuitems := Pmenuitem_tArray(@SoundVolMenu);  // menu items
  SoundVolDef.drawproc := @M_DrawSoundVol;  // draw routine
  SoundVolDef.x := DEF_MENU_ITEMS_START_X;
  SoundVolDef.y := DEF_MENU_ITEMS_START_Y;
  SoundVolDef.lastOn := 0; // last item user was on in menu
  SoundVolDef.itemheight := SMALLLINEHEIGHT;
  SoundVolDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//GaameplayMenu
  pmi := @GameplayMenu[0];
  pmi.status := 1;
  pmi.name := '!Player weapon damage';
  pmi.cmd := '';
  pmi.routine := @M_SwitchPlayerWeaponDamage;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'w';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Neutron cannon L1 vanilla fire';
  pmi.cmd := 'g_vanillalevel1neutroncannon';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @g_vanillalevel1neutroncannon;
  pmi.alphaKey := 'n';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Plasma spreader L1 vanilla fire';
  pmi.cmd := 'g_vanillalevel1plasmaspreader';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @g_vanillalevel1plasmaspreader;
  pmi.alphaKey := 'p';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Fast weapon refire';
  pmi.cmd := 'g_fastweaponrefire';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @g_fastweaponrefire;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Barrel death explosion';
  pmi.cmd := '';
  pmi.routine := @M_SwitchBarrelExplode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Drone death explosion';
  pmi.cmd := '';
  pmi.routine := @M_SwitchDroneExplode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';

////////////////////////////////////////////////////////////////////////////////
//GameplayDef
  GameplayDef.numitems := Ord(gmp_end); // # of menu items
  GameplayDef.prevMenu := @OptionsDef; // previous menu
  GameplayDef.leftMenu := @SoundDef; // left menu
  GameplayDef.rightMenu := @CompatibilityDef; // right menu
  GameplayDef.menuitems := Pmenuitem_tArray(@GameplayMenu);  // menu items
  GameplayDef.drawproc := @M_DrawGameplay;  // draw routine
  GameplayDef.x := DEF_MENU_ITEMS_START_X;
  GameplayDef.y := DEF_MENU_ITEMS_START_Y;
  GameplayDef.lastOn := 0; // last item user was on in menu
  GameplayDef.itemheight := SMALLLINEHEIGHT;
  GameplayDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//CompatibilityMenu
  pmi := @CompatibilityMenu[0];
  pmi.status := 1;
  pmi.name := '!Allow player jumps';
  pmi.cmd := 'allowplayerjumps';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowplayerjumps;
  pmi.alphaKey := 'j';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Allow player breath';
  pmi.cmd := 'allowplayerbreath';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowplayerbreath;
  pmi.alphaKey := 'b';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Keep cheats when reborn';
  pmi.cmd := 'keepcheatsinplayerreborn';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @keepcheatsinplayerreborn;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Boss death ends level';
  pmi.cmd := 'majorbossdeathendsdoom1level';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @majorbossdeathendsdoom1level;
  pmi.alphaKey := 'd';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Spawn random monsters';
  pmi.cmd := 'spawnrandommonsters';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @spawnrandommonsters;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Splashes on special terrains';
  pmi.cmd := 'allowterrainsplashes';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @allowterrainsplashes;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Monsters fight after player death';
  pmi.cmd := 'continueafterplayerdeath';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @continueafterplayerdeath;
  pmi.alphaKey := 'f';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Helper drones';
  pmi.cmd := '';
  pmi.routine := @M_ChangeDrones;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'd';


////////////////////////////////////////////////////////////////////////////////
//CompatibilityDef
  CompatibilityDef.numitems := Ord(cmp_end); // # of menu items
  CompatibilityDef.prevMenu := @OptionsDef; // previous menu
  CompatibilityDef.leftMenu := @GameplayDef; // left menu
  CompatibilityDef.rightMenu := @ControlsDef; // right menu
  CompatibilityDef.menuitems := Pmenuitem_tArray(@CompatibilityMenu);  // menu items
  CompatibilityDef.drawproc := @M_DrawCompatibility;  // draw routine
  CompatibilityDef.x := DEF_MENU_ITEMS_START_X;
  CompatibilityDef.y := DEF_MENU_ITEMS_START_Y;
  CompatibilityDef.lastOn := 0; // last item user was on in menu
  CompatibilityDef.itemheight := SMALLLINEHEIGHT;
  CompatibilityDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//ControlsMenu
  pmi := @ControlsMenu[0];
  pmi.status := 1;
  pmi.name := '!Use mouse';
  pmi.cmd := 'use_mouse';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemouse;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Invert mouse up/down look';
  pmi.cmd := 'invertmouselook';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @invertmouselook;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Invert mouse turn left/right';
  pmi.cmd := 'invertmouseturn';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @invertmouseturn;
  pmi.alphaKey := 'i';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Mouse sensitivity...';
  pmi.cmd := '';
  pmi.routine := @M_OptionsSensitivity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use joystic';
  pmi.cmd := 'use_joystick';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usejoystick;
  pmi.alphaKey := 'j';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Always run';
  pmi.cmd := 'autorunmode';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @autorunmode;
  pmi.alphaKey := 'a';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_SwitchKeyboardMode;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'k';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Key bindings...';
  pmi.cmd := '';
  pmi.routine := @M_KeyBindings;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'b';

////////////////////////////////////////////////////////////////////////////////
//ControlsDef
  ControlsDef.numitems := Ord(ctrl_end); // # of menu items
  ControlsDef.prevMenu := @OptionsDef; // previous menu
  ControlsDef.leftMenu := @CompatibilityDef; // left menu
  ControlsDef.rightMenu := @SystemDef; // left menu
  ControlsDef.menuitems := Pmenuitem_tArray(@ControlsMenu);  // menu items
  ControlsDef.drawproc := @M_DrawControls;  // draw routine
  ControlsDef.x := DEF_MENU_ITEMS_START_X;
  ControlsDef.y := DEF_MENU_ITEMS_START_Y;
  ControlsDef.lastOn := 0; // last item user was on in menu
  ControlsDef.itemheight := SMALLLINEHEIGHT;
  ControlsDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//SensitivityMenu
  pmi := @SensitivityMenu[0];
  pmi.status := 2;
  pmi.name := '!Global sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivity;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!X Axis sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivityX;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'x';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := 2;
  pmi.name := '!Y Axis sensitivity';
  pmi.cmd := '';
  pmi.routine := @M_ChangeSensitivityY;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 'y';

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

  inc(pmi);
  pmi.status := -1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := nil;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//SensitivityDef
  SensitivityDef.numitems := Ord(sens_end); // # of menu items
  SensitivityDef.prevMenu := @ControlsDef; // previous menu
  SensitivityDef.menuitems := Pmenuitem_tArray(@SensitivityMenu);  // menu items
  SensitivityDef.drawproc := @M_DrawSensitivity;  // draw routine
  SensitivityDef.x := DEF_MENU_ITEMS_START_X;
  SensitivityDef.y := DEF_MENU_ITEMS_START_Y;
  SensitivityDef.lastOn := 0; // last item user was on in menu
  SensitivityDef.itemheight := SMALLLINEHEIGHT;
  SensitivityDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//SystemMenu
  pmi := @SystemMenu[0];
  pmi.status := 1;
  pmi.name := '!Safe mode';
  pmi.cmd := 'safemode';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @safemode;
  pmi.alphaKey := 's';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Use mmx/AMD 3D-Now';
  pmi.cmd := 'mmx';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemmx;
  pmi.alphaKey := 'm';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Time critical CPU priority';
  pmi.cmd := 'criticalcpupriority';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @criticalcpupriority;
  pmi.alphaKey := 'c';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Multithreading functions';
  pmi.cmd := 'usemultithread';
  pmi.routine := @M_BoolCmd;
  pmi.pBoolVal := @usemultithread;
  pmi.alphaKey := 't';

  inc(pmi);
  pmi.status := 1;
  pmi.name := '!Screenshot format';
  pmi.cmd := '';
  pmi.routine := @M_ScreenShotCmd;
  pmi.pBoolVal := nil;
  pmi.alphaKey := 's';

////////////////////////////////////////////////////////////////////////////////
//SystemDef
  SystemDef.numitems := Ord(sys_end); // # of menu items
  SystemDef.prevMenu := @OptionsDef; // previous menu
  SystemDef.leftMenu := @ControlsDef; // left menu
  SystemDef.rightMenu := @OptionsGeneralDef; // right menu
  SystemDef.menuitems := Pmenuitem_tArray(@SystemMenu);  // menu items
  SystemDef.drawproc := @M_DrawSystem;  // draw routine
  SystemDef.x := DEF_MENU_ITEMS_START_X;
  SystemDef.y := DEF_MENU_ITEMS_START_Y;
  SystemDef.lastOn := 0; // last item user was on in menu
  SystemDef.itemheight := SMALLLINEHEIGHT;
  SystemDef.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu1
  pmi := @KeyBindingsMenu1[0];
  for i := 0 to Ord(kb_lookup) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect1;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef1
  KeyBindingsDef1.numitems := Ord(kb_lookup); // # of menu items
  KeyBindingsDef1.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef1.leftMenu := @KeyBindingsDef2; // left menu
  KeyBindingsDef1.rightMenu := @KeyBindingsDef2; // right menu
  KeyBindingsDef1.menuitems := Pmenuitem_tArray(@KeyBindingsMenu1);  // menu items
  KeyBindingsDef1.drawproc := @M_DrawBindings1;  // draw routine
  KeyBindingsDef1.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef1.y := DEF_MENU_ITEMS_START_Y;
  KeyBindingsDef1.lastOn := 0; // last item user was on in menu
  KeyBindingsDef1.itemheight := SMALLLINEHEIGHT;
  KeyBindingsDef1.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu2
  pmi := @KeyBindingsMenu2[0];
  for i := 0 to Ord(kb_am_gobigkey) - Ord(kb_lookup) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect2;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef2
  KeyBindingsDef2.numitems := Ord(kb_am_gobigkey) - Ord(kb_lookup); // # of menu items
  KeyBindingsDef2.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef2.leftMenu := @KeyBindingsDef3; // left menu
  KeyBindingsDef2.rightMenu := @KeyBindingsDef3; // right menu
  KeyBindingsDef2.menuitems := Pmenuitem_tArray(@KeyBindingsMenu2);  // menu items
  KeyBindingsDef2.drawproc := @M_DrawBindings2;  // draw routine
  KeyBindingsDef2.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef2.y := DEF_MENU_ITEMS_START_Y;
  KeyBindingsDef2.lastOn := 0; // last item user was on in menu
  KeyBindingsDef2.itemheight := SMALLLINEHEIGHT;
  KeyBindingsDef2.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsMenu3
  pmi := @KeyBindingsMenu3[0];
  for i := 0 to Ord(kb_end) - Ord(kb_am_gobigkey) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_KeyBindingSelect3;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//KeyBindingsDef3
  KeyBindingsDef3.numitems := Ord(kb_end) - Ord(kb_am_gobigkey); // # of menu items
  KeyBindingsDef3.prevMenu := @ControlsDef; // previous menu
  KeyBindingsDef3.leftMenu := @KeyBindingsDef1; // left menu
  KeyBindingsDef3.rightMenu := @KeyBindingsDef1; // right menu
  KeyBindingsDef3.menuitems := Pmenuitem_tArray(@KeyBindingsMenu3);  // menu items
  KeyBindingsDef3.drawproc := @M_DrawBindings3;  // draw routine
  KeyBindingsDef3.x := DEF_MENU_ITEMS_START_X;
  KeyBindingsDef3.y := DEF_MENU_ITEMS_START_Y;
  KeyBindingsDef3.lastOn := 0; // last item user was on in menu
  KeyBindingsDef3.itemheight := SMALLLINEHEIGHT;
  KeyBindingsDef3.flags := FLG_MN_TEXTUREBK or FLG_MN_DRAWITEMON;

////////////////////////////////////////////////////////////////////////////////
//InTextMenu
  pmi := @InTextMenu[0];
  pmi.status := 1;
  pmi.name := '';
  pmi.cmd := '';
  pmi.routine := @M_InTextMenu;
  pmi.pBoolVal := nil;
  pmi.alphaKey := #0;

////////////////////////////////////////////////////////////////////////////////
//InTextDef
  InTextDef.numitems := Ord(intextmenu_end); // # of menu items
  InTextDef.prevMenu := nil; // previous menu
  InTextDef.menuitems := Pmenuitem_tArray(@InTextMenu);  // menu items
  InTextDef.drawproc := @M_DrawInMissionText;  // draw routine
  InTextDef.x := 10;
  InTextDef.y := 8; // x,y of menu
  InTextDef.lastOn := 0; // last item user was on in menu
  InTextDef.itemheight := BIGLINEHEIGHT;
  InTextDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//LoadMenu
  pmi := @LoadMenu[0];
  for i := 0 to Ord(load_end) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_LoadSelect;
    pmi.pBoolVal := nil;
    pmi.alphaKey := Chr(Ord('1') + i);
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//LoadDef
  LoadDef.numitems := Ord(load_end); // # of menu items
  LoadDef.prevMenu := @MainDef; // previous menu
  LoadDef.menuitems := Pmenuitem_tArray(@LoadMenu);  // menu items
  LoadDef.drawproc := @M_DrawLoad;  // draw routine
  LoadDef.x := 26;
  LoadDef.y := 10; // x,y of menu
  LoadDef.lastOn := 0; // last item user was on in menu
  LoadDef.itemheight := SAVELOADLINEHEIGHT;
  LoadDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
//SaveMenu
  pmi := @SaveMenu[0];
  for i := 0 to Ord(load_end) - 1 do
  begin
    pmi.status := 1;
    pmi.name := '';
    pmi.cmd := '';
    pmi.routine := @M_SaveSelect;
    pmi.alphaKey := Chr(Ord('1') + i);
    pmi.pBoolVal := nil;
    inc(pmi);
  end;

////////////////////////////////////////////////////////////////////////////////
//SaveDef
  SaveDef.numitems := Ord(load_end); // # of menu items
  SaveDef.prevMenu := @MainDef; // previous menu
  SaveDef.menuitems := Pmenuitem_tArray(@SaveMenu);  // menu items
  SaveDef.drawproc := M_DrawSave;  // draw routine
  SaveDef.x := 26;
  SaveDef.y := 10; // x,y of menu
  SaveDef.lastOn := 0; // last item user was on in menu
  SaveDef.itemheight := SAVELOADLINEHEIGHT;
  SaveDef.flags := 0;

////////////////////////////////////////////////////////////////////////////////
  joywait := 0;
  mousewait := 0;
  mmousex := 0;
  mmousey := 0;
  mlastx := 0;
  mlasty := 0;

end;

end.

