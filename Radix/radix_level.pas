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
//   Radix level
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_level;

interface

uses
  d_delphi,
  w_wadwriter;

function RX_CreateDoomLevel(const levelname: string;
  const rlevel: pointer; const rsize: integer; const markflats: PBooleanArray;
  const texturewidths, textureheights: PIntegerArray; const wadwriter: TWadWriter): boolean;

function RX_CreateRadixMapCSV(const levelname: string; const apath: string;
  const rlevel: pointer; const rsize: integer): boolean;

const
  RADIXMAPMAGIC = $FFFFFEE7;
  RADIXSECTORNAMESIZE = 26;
  RADIXNUMPLAYERSTARTS = 8;

// Sector Flags
const
  RSF_DARKNESS = 1;
  RSF_FOG = 2;
  RSF_FLOORSLOPE = 4;
  RSF_CEILINGSLOPE = 8;
  RSF_CEILINGSKY = 16;
  RSF_HIDDEN = 32;
  RSF_FLOORSKY = 64;

// Wall Flags
const
  RWF_SINGLESIDED = 1;
  RWF_FLOORWALL = 2;
  RWF_CEILINGWALL = 4;
  // 20200216 -> new flags
  RWF_PEGTOP_FLOOR = 32;
  RWF_PEGTOP_CEILING = 64;
  RWF_PEGBOTTOM_FLOOR = 128;
  RWF_PEGBOTTOM_CEILING = 256;
  RWF_TWOSIDEDCOMPLETE = 512;
  RWF_ACTIVATETRIGGER = 1024;
  RWF_MISSILEWALL = 2048;
  // JVAL 20200307 - Set at runtime
  RWF_FORCEINTERPOLATE = $10000000;
  // JVAL 20200302 - Mark radix walls
  RWF_RADIXWALL = $20000000;
  // JVAL 20200218 - Mark stub walls
  RWF_STUBWALL = $40000000;

type
  radixlevelheader_t = packed record
    id: LongWord;
    numtriggers: integer;
    numactions: integer;
    _unknown1: packed array[0..16] of byte;
    numwalls: integer;
    numsectors: integer;
    _unknown2: packed array[0..3] of byte;
    numthings: integer;
    _unknown3: packed array[0..19] of byte;
    orthogonalmap: smallint;
    _unknown4: packed array[0..1] of byte;
    playerstartoffsets: integer;
  end;

  radixplayerstart_t = packed record
    x, y, z: integer;
    angle: byte;
  end;

type
  // Radix sector - size is 142 bytes
  radixsector_t = packed record
    _unknown1: packed array[0..1] of byte; // Always [1, 0]
    nameid: packed array[0..RADIXSECTORNAMESIZE - 1] of char;
    floortexture: smallint;
    ceilingtexture: smallint;
    floorheight: smallint;
    ceilingheight: smallint;
    lightlevel: byte;
    flags: byte;
    // Floor slope
    fa: integer;
    fb: integer;
    fc: integer;
    fd: integer;
    // Ceiling slope
    ca: integer;
    cb: integer;
    cc: integer;
    cd: integer;
    // Texture angle
    floorangle: LongWord;
    ceilingangle: LongWord;
    // Texture rotation - floor and ceiling height data for slopes
    heightnodesx: packed array[0..2] of integer;
    floorangle_x: integer;  // Pivot for rotating floor texture - x coord
    heightnodesy: packed array[0..2] of integer;
    floorangle_y: integer;  // Pivot for rotating floor texture - y coord
    floorheights: packed array[0..2] of integer;
    ceilingangle_x: integer;  // Pivot for rotating ceiling texture - x coord
    ceilingheights: packed array[0..2] of integer;
    ceilingangle_y: integer;  // Pivot for rotating ceiling texture - y coord
  end;
  Pradixsector_t = ^radixsector_t;
  radixsector_tArray = array[0..$FFF] of radixsector_t;
  Pradixsector_tArray = ^radixsector_tArray;

  // Radix wall - size os 86 bytes
  radixwall_t = packed record
    _unknown1: packed array[0..9] of byte;
    v1_x: integer;
    v1_y: integer;
    v2_x: integer;
    v2_y: integer;
    frontsector: smallint;
    backsector: smallint;
    _unknown2: packed array[0..41] of byte;
    flags: LongWord;
    bitmapoffset: smallint; // 20200216 - bitmapoffset
    wfloortexture: smallint;
    wceilingtexture: smallint;
    hitpoints: smallint; // 20200216 - VALUE = 100 -> default , VALUE = 2000 -> special ?
    trigger: smallint;  // 20200216 - Trigger id
  end;
  Pradixwall_t = ^radixwall_t;
  radixwall_tArray = array[0..$FFF] of radixwall_t;
  Pradixwall_tArray = ^radixwall_tArray;

  // Radix thing - Size is 34 bytes
  radixthing_t = packed record
    skill: byte;
    _unknown1: smallint;
    _unknown2: smallint;
    x: integer;
    y: integer;
    angle: byte;
    ground: smallint;
    _unknown7: smallint;
    _unknown8: integer;
    radix_type: integer;
    speed: smallint;
    thing_key: smallint;
    height_speed: smallint;
    _unknown12: smallint;
  end;
  Pradixthing_t = ^radixthing_t;
  radixthing_tArray = array[0..$FFF] of radixthing_t;
  Pradixthing_tArray = ^radixthing_tArray;

const
  RADIXGRIDSIZE = 40960;

const
  RADIXGRIDCELLSIZE = 64; // JVAL: 20200429 - Size of a grid cell in units

type
  radixgrid_t = packed array[0..RADIXGRIDSIZE - 1] of smallint;
  Pradixgrid_t = ^radixgrid_t;

type
  radixgridinfo_t = packed record
    x, y: integer;
    grid: radixgrid_t;
  end;
  Pradixgridinfo_t = ^radixgridinfo_t;

type
  radixdoommappoint_t = packed record
    x, y: smallint;
  end;

type
  radixmappointsgrid_t = packed array[0..RADIXGRIDSIZE - 1] of radixdoommappoint_t;
  Pradixmappointsgrid_t = ^radixmappointsgrid_t;

const
  MAX_RADIX_ACTION_PARAMS = 64;

type
  radixaction_t = packed record
    unknown1: byte; // always 1
    enabled: byte;  // 0-> disabled/hiden, 1 -> enabled/shown
    nameid: packed array[0..25] of char;
    extradata: smallint;
    // Offset to parameters
    // All parameters from all sprites/actions are stored in a table
    // dataoffset point to the first item (from ::suspend to the last of the params)
    // dataoffset = "[last dataoffset] + [extradata] + 6"
    dataoffset: smallint;
    action_type: smallint;
    suspend: integer; // 0 -> Run at level start, -1 -> Run on trigger
    _unknown2: word; // 20200217
    params: packed array[0..MAX_RADIX_ACTION_PARAMS - 1] of smallint;
  end;
  Pradixaction_t = ^radixaction_t;
  radixaction_tArray = array[0..$FFF] of radixaction_t;
  Pradixaction_tArray = ^radixaction_tArray;

const
  MAX_RADIX_TRIGGER_ACTIONS = 150; // 133 max in radix.dat v2 remix

const
// activationflags of radixtriggeraction_t
  SPR_FLG_ACTIVATE = 0;
  SPR_FLG_DEACTIVATE = 1;
  SPR_FLG_ACTIVATEONSPACE = 2;
  SPR_FLG_TONGLE = 3;

type
  radixtriggeraction_t = packed record
    dataoffset: smallint;
    actionid: smallint;
    trigger: smallint;
    activationflags: smallint;  // JVAL: 20200301 - SPR_FLG_ flags
    _unknown2: packed array[0..1] of smallint;
  end;
  Pradixtriggeraction_t = ^radixtriggeraction_t;
  radixtriggeraction_tArray = array[0..$FFF] of radixtriggeraction_t;
  Pradixtriggeraction_tArray = ^radixtriggeraction_tArray;

  radixtrigger_t = packed record
    _unknown1: byte; // always 1
    suspended: byte;  // 1-> hidden/suspended
    nameid: packed array[0..25] of char;
    numactions: integer;
    _unknown2: word; // 20200217
    actions: packed array[0..MAX_RADIX_TRIGGER_ACTIONS - 1] of radixtriggeraction_t;
  end;
  Pradixtrigger_t = ^radixtrigger_t;
  radixtrigger_tArray = packed array[0..$FFF] of radixtrigger_t;
  Pradixtrigger_tArray = ^radixtrigger_tArray;

const
  E3M2_SPLIT_X = 48000;
  RADIX_MAP_X_MULT = 1;
  RADIX_MAP_X_ADD = -32767;
  RADIX_MAP_X_ADD2 = -65536;
  RADIX_MAP_Y_MULT = -1;
  RADIX_MAP_Y_ADD = 0;
  RADIX_MAP_Y_ADD2 = -4096;

implementation

uses
  doomdef,
  radix_defs,
  radix_things,
  radix_grid,
  radix_map_extra,
  m_crc32,
  doomdata,
  w_wad;

function Radix_v10_levelCRC(const lname: string): string;
begin
  if lname ='E1M1' then result := '508E903B'
  else if lname ='E1M2' then result := '6456995C'
  else if lname ='E1M3' then result := '4FCE4AC0'
  else if lname ='E1M4' then result := 'D341760C'
  else if lname ='E1M5' then result := 'EE73818A'
  else if lname ='E1M6' then result := '827D20E4'
  else if lname ='E1M7' then result := 'D30FD83B'
  else if lname ='E1M8' then result := '66256496'
  else if lname ='E1M9' then result := 'CB48D934'
  else if lname ='E2M1' then result := '5351174C'
  else if lname ='E2M2' then result := 'A89AA971'
  else if lname ='E2M3' then result := 'C48C5B0E'
  else if lname ='E2M4' then result := '7CD6BAA6'
  else if lname ='E2M5' then result := '39D60BA5'
  else if lname ='E2M6' then result := 'A01810C0'
  else if lname ='E2M7' then result := '3BD5E170'
  else if lname ='E2M8' then result := '91FF1A54'
  else if lname ='E2M9' then result := '0A65F0FA'
  else if lname ='E3M1' then result := '0F790FDC'
  else if lname ='E3M2' then result := '51B675E4'
  else if lname ='E3M3' then result := '0D288E2B'
  else if lname ='E3M4' then result := '86B0E033'
  else if lname ='E3M5' then result := 'F948451E'
  else if lname ='E3M6' then result := '3020CCF0'
  else if lname ='E3M7' then result := '18F8424C'
  else if lname ='E3M8' then result := '100FEEFD'
  else if lname ='E3M9' then result := '6EDAD08A'
  else result := '';
  result := strupper(result);
end;

function Radix_v11_levelCRC(const lname: string): string;
begin
  if lname ='E1M1' then result := '9332AD1B'
  else if lname ='E1M2' then result := 'BC330015'
  else if lname ='E1M3' then result := '4FCE4AC0'
  else if lname ='E1M4' then result := 'D341760C'
  else if lname ='E1M5' then result := 'EE73818A'
  else if lname ='E1M6' then result := '827D20E4'
  else if lname ='E1M7' then result := 'D30FD83B'
  else if lname ='E1M8' then result := '66256496'
  else if lname ='E1M9' then result := 'CB48D934'
  else result := '';
  result := strupper(result);
end;

// radix 2.0 crc32
function Radix_v2_levelCRC(const lname: string): string;
begin
  if lname ='E1M1' then result := '1e621abe'
  else if lname ='E1M2' then result := '59b387ad'
  else if lname ='E1M3' then result := 'd29684c0'
  else if lname ='E1M4' then result := 'd341760c'
  else if lname ='E1M5' then result := '6baf74a2'
  else if lname ='E1M6' then result := '827d20e4'
  else if lname ='E1M7' then result := 'd30fd83b'
  else if lname ='E1M8' then result := '5b4c0e64'
  else if lname ='E1M9' then result := 'cb48d934'
  else if lname ='E2M1' then result := '5351174c'
  else if lname ='E2M2' then result := 'a89aa971'
  else if lname ='E2M3' then result := '76fc4e82'
  else if lname ='E2M4' then result := '3e7efcc7'
  else if lname ='E2M5' then result := '39d60ba5'
  else if lname ='E2M6' then result := 'a01810c0'
  else if lname ='E2M7' then result := '3bd5e170'
  else if lname ='E2M8' then result := '91ff1a54'
  else if lname ='E2M9' then result := 'd014181f'
  else if lname ='E3M1' then result := '0f790fdc'
  else if lname ='E3M2' then result := '51b675e4'
  else if lname ='E3M3' then result := '0d288e2b'
  else if lname ='E3M4' then result := '86b0e033'
  else if lname ='E3M5' then result := '714ef22b'
  else if lname ='E3M6' then result := '5b73ac44'
  else if lname ='E3M7' then result := '18f8424c'
  else if lname ='E3M8' then result := '8fe243cd'
  else if lname ='E3M9' then result := '6edad08a'
  else result := '';
  result := strupper(result);
end;

type
  radixmapsectorextra_t = packed record
    xmul, xadd, ymul, yadd: integer;
  end;
  Pradixmapsectorextra_t = ^radixmapsectorextra_t;
  radixmapsectorextra_tArray = array[0..$FFFF] of radixmapsectorextra_t;
  Pradixmapsectorextra_tArray = ^radixmapsectorextra_tArray;

function RX_CreateDoomLevel(const levelname: string;
  const rlevel: pointer; const rsize: integer; const markflats: PBooleanArray;
  const texturewidths, textureheights: PIntegerArray; const wadwriter: TWadWriter): boolean;
var
  ms: TAttachableMemoryStream;
  header: radixlevelheader_t;
  rsectors: Pradixsector_tArray;
  rwalls: Pradixwall_tArray;
  rthings: Pradixthing_tArray;
  ractions: Pradixaction_tArray;
  rtriggers: Pradixtrigger_tArray;
  doomthings: Pdoommapthing_tArray;
  doomthingsextra: Pradixmapthingextra_tArray; // Extra lump 'RTHINGS'
  numdoomthings: integer;
  doomlinedefs: Pmaplinedef_tArray;
  numdoomlinedefs: integer;
  doomsidedefs: Pmapsidedef_tArray;
  numdoomsidedefs: integer;
  doomvertexes: Pmapvertex_tArray;
  numdoomvertexes: integer;
  doomsectors: Pmapsector_tArray;
  doomsectorsextra: Pradixmapsectorextra_tArray;
  numdoomsectors: integer;
  gridinfoextra: Pradixgridinfo_t;
  mappointsgridextra: Pradixmappointsgrid_t;
  doommapscript: TDStringList;
  grid_X_size: integer;
  grid_Y_size: integer;
  i, j: integer;
  minx, maxx, miny, maxy: integer;
  sectormapped: PBooleanArray;
  tmpwall: radixwall_t;
  rplayerstarts: packed array[0..RADIXNUMPLAYERSTARTS - 1] of radixplayerstart_t;
  lcrc32: string;
  islevel_v: integer;
  e3m2special: boolean;
  v1x, v1y, v2x, v2y: integer;
  stubx, stuby: integer;

  procedure fix_wall_coordXYdef(var xx: integer; var yy: integer);
  begin
    xx := RADIX_MAP_X_MULT * xx + RADIX_MAP_X_ADD;
    yy := RADIX_MAP_Y_MULT * yy + RADIX_MAP_Y_ADD;
  end;

  procedure fix_wall_coordXY(var xx: integer; var yy: integer);
  begin
    if xx >= E3M2_SPLIT_X then
    begin
      if e3m2special then
      begin
        xx := RADIX_MAP_X_MULT * xx + RADIX_MAP_X_ADD2;
        yy := RADIX_MAP_Y_MULT * yy + RADIX_MAP_Y_ADD2;
        exit;
      end;
    end;
    fix_wall_coordXYdef(xx, yy);
  end;

  function RadixSkillToDoomSkill(const sk: integer): integer;
  begin
    if (sk = 0) or (sk = 1) then
      result := MTF_EASY or MTF_NORMAL or MTF_HARD
    else if sk = 2 then
      result := MTF_NORMAL or MTF_HARD
    else if sk = 3 then
      result := MTF_HARD
    else
      result := MTF_EASY or MTF_NORMAL or MTF_HARD or MTF_NOTSINGLE;
  end;

  // angle is in 0-256
  procedure AddThingToWad(const x, y, z: integer; const speed, height_speed: smallint;
    const angle: smallint; const mtype: word; const options: smallint; const radix_skill: integer;
    const radix_id: integer);
  var
    mthing: Pdoommapthing_t;
    xx, yy: integer;
  begin
    realloc(pointer(doomthings), numdoomthings * SizeOf(doommapthing_t), (numdoomthings + 1) * SizeOf(doommapthing_t));
    mthing := @doomthings[numdoomthings];

    xx := x;
    yy := y;
    fix_wall_coordXY(xx, yy);
    mthing.x := xx;
    mthing.y := yy;

    mthing.angle := round((angle / 256) * 360);
    mthing._type := mtype;
    mthing.options := options;

    realloc(pointer(doomthingsextra), numdoomthings * SizeOf(radixmapthingextra_t), (numdoomthings + 1) * SizeOf(radixmapthingextra_t));
    doomthingsextra[numdoomthings].z := z;
    doomthingsextra[numdoomthings].speed := speed;
    doomthingsextra[numdoomthings].height_speed := height_speed;
    doomthingsextra[numdoomthings].radix_skill := radix_skill;
    doomthingsextra[numdoomthings].radix_id := radix_id;

    inc(numdoomthings);
  end;

  procedure AddDoomThingToWad(const x, y: integer; const angle: smallint; const mtype: word; const options: smallint);
  var
    mthing: Pdoommapthing_t;
  begin
    realloc(pointer(doomthings), numdoomthings * SizeOf(doommapthing_t), (numdoomthings + 1) * SizeOf(doommapthing_t));
    mthing := @doomthings[numdoomthings];

    mthing.x := x;
    mthing.y := y;

    mthing.angle := angle;
    mthing._type := mtype;
    mthing.options := options;

    realloc(pointer(doomthingsextra), numdoomthings * SizeOf(radixmapthingextra_t), (numdoomthings + 1) * SizeOf(radixmapthingextra_t));
    doomthingsextra[numdoomthings].z := 0;
    doomthingsextra[numdoomthings].speed := 0;
    doomthingsextra[numdoomthings].height_speed := 0;
    doomthingsextra[numdoomthings].radix_skill := -1;
    doomthingsextra[numdoomthings].radix_id := -1;

    inc(numdoomthings);
  end;

  procedure AddPlayerStarts;
  var
    j: integer;
  begin
    // Player starts - DoomEdNum 1 thru 4
    for j := 0 to 3 do
      AddThingToWad(rplayerstarts[j].x, rplayerstarts[j].y, rplayerstarts[j].z, 0, 0, rplayerstarts[j].angle, j + 1, 7, -1, -1);
    // Deathmatch starts - DoomEdNum 11
    for j := 4 to RADIXNUMPLAYERSTARTS - 1 do
      AddThingToWad(rplayerstarts[j].x, rplayerstarts[j].y, rplayerstarts[j].z, 0, 0, rplayerstarts[j].angle, 11, 7, -1, -1);
  end;

  procedure ReadRadixGrid(const pgrid: Pradixgridinfo_t);
  var
    grid: Pradixgrid_t;
    i_grid_x, i_grid_y: integer;
    g, l, k: smallint;
    ii: integer;
  begin
    if header.orthogonalmap <> 0 then
    begin
      grid_X_size := 320;
      grid_Y_size := 128;
    end
    else
    begin
      grid_X_size := 1280;
      grid_Y_size := 32;
    end;
    grid := mallocz(grid_X_size * grid_Y_size * SizeOf(smallint));

    for i_grid_y := 0 to grid_Y_size - 1 do
    begin
      i_grid_x := 0;
      repeat
        ms.Read(g, SizeOf(smallint));
        if g = -32000 then
        begin
          ms.Read(g, SizeOf(smallint));
          ms.Read(l, SizeOf(smallint));
          for k := 0 to l - 1 do
          begin
            grid[i_grid_y * grid_X_size + i_grid_x] := g;
            inc(i_grid_x);
          end;
        end
        else
        begin
          grid[i_grid_y * grid_X_size + i_grid_x] := g;
          inc(i_grid_x);
        end;
      until i_grid_x >= grid_X_size;
    end;

    if pgrid <> nil then
    begin
      pgrid.x := grid_X_size;
      pgrid.y := grid_Y_size;
      for ii := 0 to RADIXGRIDSIZE - 1 do
        pgrid.grid[ii] := grid[ii];
    end;

    memfree(pointer(grid), grid_X_size * grid_Y_size * SizeOf(smallint));
  end;

  procedure CreateRadixMapToGrid;
  var
    i_grid_x, i_grid_y: integer;
    idx: integer;
    xx, yy: integer;
  begin
    idx := 0;
    for i_grid_y := 0 to grid_Y_size - 1 do
    begin
      for i_grid_x := 0 to grid_X_size - 1 do
      begin
        xx := i_grid_x * RADIXGRIDCELLSIZE;
        yy := i_grid_y * RADIXGRIDCELLSIZE;
        fix_wall_coordXY(xx, yy);
        mappointsgridextra[idx].x := xx;
        mappointsgridextra[idx].y := yy;
        inc(idx);
      end;
    end;
  end;

  function get_flat_texture(const id: integer): char8_t;
  begin
    result := stringtochar8(RX_FLAT_PREFIX + IntToStrzFill(4, id + 1));
    markflats[id + 1] := true;
  end;

  procedure AddSectorToWAD(const ss: Pradixsector_t);
  var
    dsec: Pmapsector_t;
  begin
    realloc(pointer(doomsectors), numdoomsectors * SizeOf(mapsector_t), (numdoomsectors  + 1) * SizeOf(mapsector_t));
    //Create classic map
    dsec := @doomsectors[numdoomsectors];
    dsec.floorheight := ss.floorheight;
    dsec.ceilingheight := ss.ceilingheight;
    if ss.flags and RSF_FLOORSKY <> 0 then
      dsec.floorpic := stringtochar8('F_SKY1')
    else
      dsec.floorpic := get_flat_texture(ss.floortexture);
    if ss.flags and RSF_CEILINGSKY <> 0 then
      dsec.ceilingpic := stringtochar8('F_SKY1')
    else
      dsec.ceilingpic := get_flat_texture(ss.ceilingtexture);
    dsec.lightlevel := RX_LightLevel(ss.lightlevel, ss.flags);
    dsec.special := 0;
    dsec.tag := 0;


    // Create extra data stored in MAP header
    doommapscript.Add('sectorid ' + itoa(numdoomsectors));
    doommapscript.Add('xmul ' + itoa(doomsectorsextra[numdoomsectors].xmul));
    doommapscript.Add('xadd ' + itoa(doomsectorsextra[numdoomsectors].xadd));
    doommapscript.Add('ymul ' + itoa(doomsectorsextra[numdoomsectors].ymul));
    doommapscript.Add('yadd ' + itoa(doomsectorsextra[numdoomsectors].yadd));
    doommapscript.Add('sectorflags ' + itoa(ss.flags));

    if ss.flags and RSF_FLOORSLOPE <> 0 then
      doommapscript.Add('floorslope ' + itoa(ss.fa) + ' ' + itoa(ss.fb) + ' ' + itoa(ss.fc) + ' ' + itoa(ss.fd));

    if ss.flags and RSF_CEILINGSLOPE <> 0 then
      doommapscript.Add('ceilingslope ' + itoa(ss.ca) + ' ' + itoa(ss.cb) + ' ' + itoa(ss.cc) + ' ' + itoa(ss.cd));

    if ss.flags and (RSF_FLOORSLOPE or RSF_CEILINGSLOPE) <> 0 then
    begin
      doommapscript.Add('heightnodesx ' + itoa(ss.heightnodesx[0]) + ' ' + itoa(ss.heightnodesx[1]) + ' ' + itoa(ss.heightnodesx[2]));
      doommapscript.Add('heightnodesy ' + itoa(ss.heightnodesy[0]) + ' ' + itoa(ss.heightnodesy[1]) + ' ' + itoa(ss.heightnodesy[2]));
      if ss.flags and RSF_FLOORSLOPE <> 0 then
        doommapscript.Add('floorheights ' + itoa(ss.floorheights[0]) + ' ' + itoa(ss.floorheights[1]) + ' ' + itoa(ss.floorheights[2]));
      if ss.flags and RSF_CEILINGSLOPE <> 0 then
        doommapscript.Add('ceilingheights ' + itoa(ss.ceilingheights[0]) + ' ' + itoa(ss.ceilingheights[1]) + ' ' + itoa(ss.ceilingheights[2]));
    end;

    if ss.floorangle <> 0 then
    begin
      doommapscript.Add('floorangle ' + itoa(ss.floorangle));
      doommapscript.Add('floorangle_x ' + itoa(ss.floorangle_x));
      doommapscript.Add('floorangle_y ' + itoa(ss.floorangle_x));
    end;
    if ss.ceilingangle <> 0 then
    begin
      doommapscript.Add('ceilingangle ' + itoa(ss.ceilingangle));
      doommapscript.Add('ceilingangle_x ' + itoa(ss.ceilingangle_x));
      doommapscript.Add('ceilingangle_y ' + itoa(ss.ceilingangle_y));
    end;
    doommapscript.Add('');

    inc(numdoomsectors);
  end;

  function AddVertexToWAD(const x, y: smallint): integer;
  var
    j: integer;
  begin
    for j := 0 to numdoomvertexes - 1 do
      if (doomvertexes[j].x = x) and (doomvertexes[j].y = y) then
      begin
        result := j;
        exit;
      end;
    realloc(pointer(doomvertexes), numdoomvertexes * SizeOf(mapvertex_t), (numdoomvertexes  + 1) * SizeOf(mapvertex_t));
    doomvertexes[numdoomvertexes].x := x;
    doomvertexes[numdoomvertexes].y := y;
    result := numdoomvertexes;
    inc(numdoomvertexes);
  end;

  function AddSidedefToWAD(const toff: smallint; const toptex, bottomtex, midtex: char8_t;
    const sector: smallint; const force_new: boolean = true): integer;
  var
    j: integer;
    pside: Pmapsidedef_t;
    roff: smallint;
  begin
    roff := 0;

    if not force_new then // JVAL: 20200309 - If we pack sidedefs of radix level, the triggers may not work :(
      for j := 0 to numdoomsidedefs - 1 do
        if (doomsidedefs[j].textureoffset = toff) and (doomsidedefs[j].rowoffset = roff) and
           (doomsidedefs[j].toptexture = toptex) and (doomsidedefs[j].bottomtexture = bottomtex) and (doomsidedefs[j].midtexture = midtex) and
           (doomsidedefs[j].sector = sector) then
        begin
          result := j;
          exit;
        end;

    realloc(pointer(doomsidedefs), numdoomsidedefs * SizeOf(mapsidedef_t), (numdoomsidedefs  + 1) * SizeOf(mapsidedef_t));
    pside := @doomsidedefs[numdoomsidedefs];
    if toff < 0 then
      pside.textureoffset := toff
    else
      pside.textureoffset := toff mod 128;
    pside.rowoffset := roff;
    pside.toptexture := toptex;
    pside.bottomtexture := bottomtex;
    pside.midtexture := midtex;
    pside.sector := sector;
    result := numdoomsidedefs;
    inc(numdoomsidedefs);
  end;

  procedure AddWallToWAD(const w: Pradixwall_t);
  var
    dline: Pmaplinedef_t;
    v1, v2: integer;
    s1, s2: integer;
    news1, news2: boolean;
    toptex, bottomtex, midtex: char8_t;
    ftex, ctex: integer;
  begin
    // Front Sidedef
    news1 := true;
    news2 := true;
    ftex := w.wfloortexture + 1; // Add 1 to compensate for stub texture RDXW0000
    ctex := w.wceilingtexture + 1; // Add 1 to compensate for stub texture RDXW0000
    if w.frontsector >= 0 then
    begin
      if (w.flags and RWF_STUBWALL = 0) and
         (rsectors[w.frontsector].floortexture = 0) and
         (rsectors[w.frontsector].ceilingtexture = 0) and
         (rsectors[w.frontsector].floorheight = rsectors[w.frontsector].ceilingheight) then // sos <- WHAT ABOUT DOORS ?
         s1 := -1
      else
      begin
        if w.flags and RWF_SINGLESIDED <> 0 then
        begin
          toptex := stringtochar8('-');
          bottomtex := stringtochar8('-');
          midtex := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, ftex));
        end
        else
        begin
          if w.flags and RWF_FLOORWALL <> 0 then
            bottomtex := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, ftex))
          else
            bottomtex := stringtochar8('-');
          if w.flags and RWF_CEILINGWALL <> 0 then
            toptex := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, ctex))
          else
            toptex := stringtochar8('-');
          if w.flags and RWF_TWOSIDEDCOMPLETE <> 0 then
            midtex := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, ftex))
          else
            midtex := stringtochar8('-');
        end;
        s1 := AddSidedefToWAD(w.bitmapoffset, toptex, bottomtex, midtex, w.frontsector);
        news1 := s1 = numdoomsidedefs - 1;
      end;
    end
    else
      s1 := -1;

    // Back Sidedef
    if w.backsector >= 0 then
    begin
      if (rsectors[w.backsector].floortexture = 0) and
         (rsectors[w.backsector].ceilingtexture = 0) and
         (rsectors[w.backsector].floorheight = rsectors[w.backsector].ceilingheight) then
         s2 := -1
      else
      begin
        if w.flags and RWF_SINGLESIDED <> 0 then
        begin
          toptex := stringtochar8('-');
          bottomtex := stringtochar8('-');
          midtex := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, ftex));
        end
        else
        begin
          if w.flags and RWF_FLOORWALL <> 0 then
            bottomtex := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, ftex))
          else
            bottomtex := stringtochar8('-');
          if w.flags and RWF_CEILINGWALL <> 0 then
            toptex := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, ctex))
          else
            toptex := stringtochar8('-');
          if w.flags and RWF_TWOSIDEDCOMPLETE <> 0 then
            midtex := stringtochar8(RX_WALL_PREFIX + IntToStrzFill(4, ftex))
          else
            midtex := stringtochar8('-');
        end;
        s2 := AddSidedefToWAD(w.bitmapoffset, toptex, bottomtex, midtex, w.backsector);
        news2 := s2 = numdoomsidedefs - 1;
      end;
    end
    else
      s2 := -1;

    // Find vertexes
    v1 := AddVertexToWAD(w.v1_x, w.v1_y);
    v2 := AddVertexToWAD(w.v2_x, w.v2_y);

    // Add Doom lidedef
    realloc(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t), (numdoomlinedefs  + 1) * SizeOf(maplinedef_t));
    dline := @doomlinedefs[numdoomlinedefs];

    if s1 < 0 then
    begin
      dline.v1 := v2;
      dline.v2 := v1;
    end
    else
    begin
      dline.v1 := v1;
      dline.v2 := v2;
    end;

    dline.flags := 0;
    if (s1 >= 0) and (s2 >= 0) then
      dline.flags := dline.flags or ML_TWOSIDED;

    if w.flags and RWF_STUBWALL <> 0 then
      dline.flags := dline.flags or ML_DONTDRAW or ML_AUTOMAPIGNOGE;

    dline.special := 0;
    dline.tag := 0;

    if s1 < 0 then
    begin
      dline.sidenum[0] := s2;
      dline.sidenum[1] := -1;
    end
    else
    begin
      dline.sidenum[0] := s1;
      dline.sidenum[1] := s2;
    end;

    if (dline.flags and ML_TWOSIDED = 0) and (dline.sidenum[0] >= 0) then
    begin
      dline.flags := dline.flags or ML_BLOCKING;
      if doomsidedefs[dline.sidenum[0]].midtexture = stringtochar8('-') then
      begin
        if news1 and news2 then
          doomsidedefs[dline.sidenum[0]].midtexture := doomsidedefs[dline.sidenum[0]].toptexture
        else
          dline.sidenum[0] := AddSidedefToWAD(w.bitmapoffset, stringtochar8('-'), stringtochar8('-'), doomsidedefs[dline.sidenum[0]].toptexture, doomsidedefs[dline.sidenum[0]].sector);
      end;
    end;

    // Create extra data stored in MAP header
    doommapscript.Add('wallid ' + itoa(numdoomlinedefs));
    doommapscript.Add('wallflags ' + itoa((w.flags and not RWF_STUBWALL) or RWF_RADIXWALL));
    doommapscript.Add('wallhitpoints ' + itoa(w.hitpoints));
    doommapscript.Add('walltrigger ' + itoa(w.trigger));
    doommapscript.Add('');

    inc(numdoomlinedefs);
  end;

  procedure fix_changevertexes(const x1, y1, x2, y2: integer);
  var
    v1, v2, j: integer;
  begin
    v1 := -1;
    for j := 0 to numdoomvertexes - 1 do
      if (doomvertexes[j].x = x1) and (doomvertexes[j].y = y1) then
      begin
        v1 := j;
        break;
      end;
    v2 := -1;
    for j := 0 to numdoomvertexes - 1 do
      if (doomvertexes[j].x = x2) and (doomvertexes[j].y = y2) then
      begin
        v2 := j;
        break;
      end;
    if (v1 >= 0) and (v2 >= 0) then
      for j := 0 to numdoomlinedefs - 1 do
      begin
        if doomlinedefs[j].v1 = v1 then
          doomlinedefs[j].v1 := v2;
        if doomlinedefs[j].v2 = v1 then
          doomlinedefs[j].v2 := v2;
      end;
  end;

  procedure fix_movevertex(const x1, y1, x2, y2: integer);
  var
    j: integer;
  begin
    for j := 0 to numdoomvertexes - 1 do
      if (doomvertexes[j].x = x1) and (doomvertexes[j].y = y1) then
      begin
        doomvertexes[j].x := x2;
        doomvertexes[j].y := y2;
        exit;
      end;
  end;

  procedure fix_cloneandmovewall(const wid: integer; const dx, dy: integer);
  var
    wall: radixwall_t;
  begin
    wall := rwalls[wid];
    wall.v1_x := wall.v1_x + dx;
    wall.v1_y := wall.v1_y + dy;
    wall.v2_x := wall.v2_x + dx;
    wall.v2_y := wall.v2_y + dy;
    AddWallToWad(@wall);
  end;

  procedure fix_slide_line(const x1, y1, x2, y2: integer); overload;
  var
    dx, dy: integer;
    stepx, stepy: integer;
    xx, yy: integer;
    iters: integer;
    j: integer;
  begin
    dx := x2 - x1;
    dy := y2 - y1;

    iters := round(sqrt(dx * dx + dy * dy) / 64 + 0.4999);
    if iters < 1 then
      iters := 1;
    xx := x1;
    yy := y1;
    for j := 0 to iters - 1 do
    begin
      stepx := dx div (iters - j);
      stepy := dy div (iters - j);
      AddDoomThingToWad(xx + stepx div 2, yy + stepy div 2, 0, MT_PLAYERFLOORSLIDE64, MTF_EASY or MTF_NORMAL or MTF_HARD);
      xx := xx + stepx;
      yy := yy + stepy;
      dx := dx - stepx;
      dy := dy - stepy;
    end;
  end;

  procedure fix_slide_line(const ln: integer); overload;
  var
    x1, y1, x2, y2: integer;
  begin
    x1 := doomvertexes[doomlinedefs[ln].v1].x;
    y1 := doomvertexes[doomlinedefs[ln].v1].y;
    x2 := doomvertexes[doomlinedefs[ln].v2].x;
    y2 := doomvertexes[doomlinedefs[ln].v2].y;
    fix_slide_line(x1, y1, x2, y2);
  end;

  procedure fix_slide_corridor(const ln1, ln2: integer);
  var
    v21, v22: integer;
    dist1, dist2: integer;
    dx, dy: integer;
    x1, y1, x2, y2: integer;
  begin
    dx := doomvertexes[doomlinedefs[ln1].v1].x - doomvertexes[doomlinedefs[ln2].v1].x;
    dy := doomvertexes[doomlinedefs[ln1].v1].y - doomvertexes[doomlinedefs[ln2].v1].y;
    dist1 := dx * dx + dy * dy;
    dx := doomvertexes[doomlinedefs[ln1].v1].x - doomvertexes[doomlinedefs[ln2].v2].x;
    dy := doomvertexes[doomlinedefs[ln1].v1].y - doomvertexes[doomlinedefs[ln2].v2].y;
    dist2 := dx * dx + dy * dy;
    if dist1 < dist2 then
    begin
      v21 := doomlinedefs[ln2].v1;
      v22 := doomlinedefs[ln2].v2;
    end
    else
    begin
      v21 := doomlinedefs[ln2].v2;
      v22 := doomlinedefs[ln2].v1;
    end;
    x1 := (doomvertexes[doomlinedefs[ln1].v1].x + doomvertexes[v21].x) div 2;
    y1 := (doomvertexes[doomlinedefs[ln1].v1].y + doomvertexes[v21].y) div 2;
    x2 := (doomvertexes[doomlinedefs[ln1].v2].x + doomvertexes[v22].x) div 2;
    y2 := (doomvertexes[doomlinedefs[ln1].v2].y + doomvertexes[v22].y) div 2;
    fix_slide_line(x1, y1, x2, y2);
  end;

  procedure make_slide_line(const ln: integer);
  begin
    doomlinedefs[ln].flags := doomlinedefs[ln].flags or ML_SLIDELINE;
  end;

  procedure make_blocking_line(const ln: integer);
  begin
    doomlinedefs[ln].flags := doomlinedefs[ln].flags or ML_BLOCKING;
  end;

  function fix_radix_level_v10: boolean;
  begin
    result := false;
  end;

  function fix_doom_level_v10: boolean;
  begin
    result := false;
    if levelname = 'E2M4' then
    begin
      result := true;

      // Fix final arena sky
      doomsectors[48].ceilingheight := 1312;
      doomsectors[49].ceilingheight := 1312;
    end
    else if levelname = 'E3M6' then
    begin
      result := true;
      doomsectors[62].ceilingheight := 1408;
    end;
  end;

  function fix_radix_level_v11: boolean;
  begin
    result := false;
  end;

  function fix_doom_level_v11: boolean;
  var
    j: integer;
  begin
    result := false;
    if levelname = 'E1M1' then
    begin
      result := true;
      for j := 0 to numdoomsidedefs - 1 do
        if doomsidedefs[j].sector = 206 then
          doomsidedefs[j].sector := 0
        else if doomsidedefs[j].sector = 211 then
          doomsidedefs[j].sector := 212;
    end;
  end;

  function fix_radix_level_v2: boolean;
  begin
    result := false;
    if levelname = 'E1M6' then
    begin
      result := true;
      rsectors[156].ceilingheights[0] := rsectors[156].ceilingheights[0] + 64;
      rsectors[156].ceilingheights[1] := rsectors[156].ceilingheights[1] + 64;
      rsectors[156].ceilingheights[2] := rsectors[156].ceilingheights[2] + 64;
      rsectors[157].ceilingheight := rsectors[157].ceilingheight + 64;
    end
    else if levelname = 'E3M2' then
    begin
      result := true;
      rsectors[143].flags := rsectors[142].flags and not (RSF_FLOORSLOPE or RSF_CEILINGSLOPE);
    end;
  end;

  function fix_doom_level_v2: boolean;
  var
    j: integer;
    sd: integer;
    vv: integer;
    v1, v2: integer;
  begin
    result := false;
    if levelname = 'E1M1' then
    begin
      result := true;
      fix_slide_line(172);
      fix_slide_line(198);
      fix_slide_line(146);
      fix_slide_line(269);
      for j := 0 to numdoomsidedefs - 1 do
        if doomsidedefs[j].sector = 206 then
          doomsidedefs[j].sector := 0
        else if doomsidedefs[j].sector = 211 then
          doomsidedefs[j].sector := 212;
      // E1M1 blocking lines
      make_blocking_line(44);
      make_blocking_line(45);
      make_blocking_line(639);
      // E1M1 slide lines
      make_slide_line(1);
      make_slide_line(3);
      make_slide_line(4);
      make_slide_line(5);
      make_slide_line(6);
      make_slide_line(41);
      make_slide_line(44);
      make_slide_line(45);
      make_slide_line(48);
      make_slide_line(47);
      make_slide_line(49);
      make_slide_line(379);
      make_slide_line(632);
      make_slide_line(636);
      make_slide_line(639);
    end
    else if levelname = 'E1M2' then
    begin
      result := true;
      AddDoomThingToWad(-28735, -1376, 0, MT_PLAYERFLOORSLIDE64, MTF_EASY or MTF_NORMAL or MTF_HARD);
      AddDoomThingToWad(-28735, -1312, 0, MT_PLAYERFLOORSLIDE64, MTF_EASY or MTF_NORMAL or MTF_HARD);
      AddDoomThingToWad(-28415, -1376, 0, MT_PLAYERFLOORSLIDE64, MTF_EASY or MTF_NORMAL or MTF_HARD);
      AddDoomThingToWad(-28415, -1312, 0, MT_PLAYERFLOORSLIDE64, MTF_EASY or MTF_NORMAL or MTF_HARD);
      fix_slide_line(103);
      fix_slide_line(108);
      fix_slide_line(107);
      fix_slide_line(113);
      fix_slide_line(112);
      fix_slide_line(116);
      fix_slide_line(118);
      // E1M2 slide lines
      make_slide_line(104);
      make_slide_line(106);
      make_slide_line(109);
      make_slide_line(111);
      make_slide_line(115);
      make_slide_line(117);
      make_slide_line(401);
      make_slide_line(449);
    end
    else if levelname = 'E1M5' then
    begin
      result := true;
      doomsidedefs[413].textureoffset := -16; // JVAL: 20200428 - Does not work :(
    end
    else if levelname = 'E1M6' then
    begin
      result := true;
      fix_movevertex(-27583, -2624, -27584, -2592);
      fix_movevertex(-27583, -2560, -27584, -2560);
      fix_movevertex(-27583, -2688, -27584, -2688);
      fix_movevertex(-27583, -2752, -27584, -2752);
      doomsidedefs[758].textureoffset := 42;
      doomsidedefs[1365].textureoffset := 0;
      fix_slide_corridor(427, 431);
    end
    else if levelname = 'E1M9' then
    begin
      result := true;
      doomsectors[18].ceilingheight := 704;
      doomsectors[172].ceilingheight := 704;
    end
    else if levelname = 'E2M1' then
    begin
      result := true;
      for j := 0 to numdoomsidedefs - 1 do
        if doomsidedefs[j].sector = 64 then
          doomsidedefs[j].sector := 65;
    end
    else if levelname = 'E2M3' then
    begin
      result := true;
      doomsidedefs[329].textureoffset := 0;
      doomsidedefs[330].textureoffset := 0;
    end
    else if levelname = 'E2M4' then
    begin
      result := true;

      doomsidedefs[529].textureoffset := 0;
      fix_changevertexes(1473, -1344, 1537, -1344);

      // Fix final arena sky
      doomsectors[48].ceilingheight := 1312;
      doomsectors[49].ceilingheight := 1312;
    end
    else if levelname = 'E2M5' then
    begin
      result := true;
      for j := 0 to numdoomsidedefs - 1 do
        if doomsidedefs[j].sector = 2 then
          doomsidedefs[j].sector := 1;
      doomsectors[140].ceilingheight := 768;
      doomsectors[160].ceilingpic := stringtochar8('F_SKY1');
    end
    else if levelname = 'E2M7' then
    begin
      result := true;
      for j := 0 to numdoomsidedefs - 1 do
        if doomsidedefs[j].sector = 102 then
          doomsidedefs[j].sector := 52;

      fix_changevertexes(-19135, -4096, -19135, -4160);

      sd := doomlinedefs[19].sidenum[1];
      if sd >= 0 then
        doomsidedefs[sd].toptexture := doomsidedefs[sd].bottomtexture;
    end
    else if levelname = 'E3M1' then
    begin
      result := true;
      sd := doomlinedefs[45].sidenum[0];

      doomlinedefs[31].sidenum[1] := -1;
      doomlinedefs[31].sidenum[0] := sd;
      doomlinedefs[31].flags := doomlinedefs[31].flags and not ML_TWOSIDED;
      doomlinedefs[31].flags := doomlinedefs[31].flags or ML_BLOCKING;

      doomlinedefs[37].sidenum[1] := -1;
      doomlinedefs[37].sidenum[0] := sd;
      doomlinedefs[37].flags := doomlinedefs[37].flags and not ML_TWOSIDED;
      doomlinedefs[37].flags := doomlinedefs[37].flags or ML_BLOCKING;

      doomlinedefs[39].sidenum[1] := -1;
      doomlinedefs[39].sidenum[0] := sd;
      doomlinedefs[39].flags := doomlinedefs[39].flags and not ML_TWOSIDED;
      doomlinedefs[39].flags := doomlinedefs[39].flags or ML_BLOCKING;

      doomlinedefs[43].sidenum[1] := -1;
      doomlinedefs[43].sidenum[0] := sd;
      doomlinedefs[43].flags := doomlinedefs[43].flags and not ML_TWOSIDED;
      doomlinedefs[43].flags := doomlinedefs[43].flags or ML_BLOCKING;

      doomlinedefs[85].sidenum[1] := -1;
      doomlinedefs[85].sidenum[0] := sd;
      doomlinedefs[85].flags := doomlinedefs[85].flags and not ML_TWOSIDED;
      doomlinedefs[85].flags := doomlinedefs[85].flags or ML_BLOCKING;

      doomlinedefs[86].sidenum[1] := -1;
      doomlinedefs[86].sidenum[0] := sd;
      doomlinedefs[86].flags := doomlinedefs[86].flags and not ML_TWOSIDED;
      doomlinedefs[86].flags := doomlinedefs[86].flags or ML_BLOCKING;
    end
    else if levelname = 'E3M2' then
    begin
      result := true;

      fix_changevertexes(10112, -4160, 10176, -4160);
      fix_changevertexes(13120, -4160, 13056, -4160);

      // Fix sector 142
      fix_cloneandmovewall(184, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);
      fix_cloneandmovewall(429, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);
      fix_cloneandmovewall(534, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);

      // Clone sector 141
      fix_cloneandmovewall(665, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);
      fix_cloneandmovewall(665, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);
      fix_cloneandmovewall(536, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);
      fix_cloneandmovewall(538, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);
      fix_cloneandmovewall(535, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);
      fix_cloneandmovewall(537, RADIX_MAP_X_ADD2 - RADIX_MAP_X_ADD, RADIX_MAP_Y_ADD2 - RADIX_MAP_Y_ADD);

      // Clone sector 143
      fix_cloneandmovewall(573, RADIX_MAP_X_ADD - RADIX_MAP_X_ADD2, RADIX_MAP_Y_ADD - RADIX_MAP_Y_ADD2);
      fix_cloneandmovewall(610, RADIX_MAP_X_ADD - RADIX_MAP_X_ADD2, RADIX_MAP_Y_ADD - RADIX_MAP_Y_ADD2);
      fix_cloneandmovewall(570, RADIX_MAP_X_ADD - RADIX_MAP_X_ADD2, RADIX_MAP_Y_ADD - RADIX_MAP_Y_ADD2);
      fix_cloneandmovewall(574, RADIX_MAP_X_ADD - RADIX_MAP_X_ADD2, RADIX_MAP_Y_ADD - RADIX_MAP_Y_ADD2);
      fix_cloneandmovewall(609, RADIX_MAP_X_ADD - RADIX_MAP_X_ADD2, RADIX_MAP_Y_ADD - RADIX_MAP_Y_ADD2);

      // Fix arena sky
      doomsectors[291].ceilingpic := stringtochar8('F_SKY1');
      doomsectors[292].ceilingpic := stringtochar8('F_SKY1');
      doomsectors[293].ceilingpic := stringtochar8('F_SKY1');
      doomsectors[295].ceilingpic := stringtochar8('F_SKY1');

      // Fix secondary target room
      doomsectors[323].ceilingheight := 1280;
      doomsectors[324].ceilingheight := 1280;

      // Fix sector 143 ending line (linedef #1174)
      doomlinedefs[1174].sidenum[1] := -1;
      doomsidedefs[doomlinedefs[1174].sidenum[0]].midtexture := doomsidedefs[doomlinedefs[1174].sidenum[0]].bottomtexture;
      doomlinedefs[1174].flags := doomlinedefs[1174].flags or ML_BLOCKING;
      doomlinedefs[1174].flags := doomlinedefs[1174].flags and not ML_TWOSIDED;

      // Fix sector 141 ending line (linedef #1169)
      vv := doomlinedefs[1169].v1;
      doomlinedefs[1169].v1 := doomlinedefs[1169].v2;
      doomlinedefs[1169].v2 := vv;
      doomlinedefs[1169].sidenum[0] := doomlinedefs[1169].sidenum[1];
      doomlinedefs[1169].sidenum[1] := -1;
      doomsidedefs[doomlinedefs[1169].sidenum[0]].midtexture := doomsidedefs[doomlinedefs[1169].sidenum[0]].bottomtexture;
      doomlinedefs[1169].flags := doomlinedefs[1169].flags or ML_BLOCKING;
      doomlinedefs[1169].flags := doomlinedefs[1169].flags and not ML_TWOSIDED;

      // Deny access to monsters in the trans-corridor
      doomlinedefs[537].flags := doomlinedefs[537].flags or ML_BLOCKMONSTERS;
      doomlinedefs[609].flags := doomlinedefs[609].flags or ML_BLOCKMONSTERS;

      // Move map things from trans-corridor
      for j := 0 to numdoomthings - 1 do
      begin
        if (doomthings[j].x = 14200) and (doomthings[j].y = -1506) then
        begin
          doomthings[j].x := 13120;
          doomthings[j].y := -544;
        end
        else if (doomthings[j].x = 14823) and (doomthings[j].y = -1501) then
        begin
          doomthings[j].x := 13248;
          doomthings[j].y := -256;
        end
        else if (doomthings[j].x = -17140) and (doomthings[j].y = -5602) then
        begin
          doomthings[j].x := -14208;
          doomthings[j].y := -4576;
        end
        else if (doomthings[j].x = -16380) and (doomthings[j].y = -5576) then
        begin
          doomthings[j].x := -13856;
          doomthings[j].y := -4576;
        end
        else if (doomthings[j].x = -16180) and (doomthings[j].y = -5610) then
        begin
          doomthings[j].x := -13888;
          doomthings[j].y := -5472;
        end
        else if (doomthings[j].x = -15860) and (doomthings[j].y = -5610) then
        begin
          doomthings[j].x := -12640;
          doomthings[j].y := -5472;
        end;
      end;

      doomsidedefs[doomlinedefs[609].sidenum[0]].toptexture := stringtochar8('RDXW0194');
      doomsidedefs[doomlinedefs[609].sidenum[0]].bottomtexture := stringtochar8('RDXW0194');
      doomsidedefs[doomlinedefs[609].sidenum[1]].toptexture := stringtochar8('RDXW0194');
      doomsidedefs[doomlinedefs[609].sidenum[1]].bottomtexture := stringtochar8('RDXW0194');
      doomsidedefs[doomlinedefs[1174].sidenum[0]].toptexture := stringtochar8('RDXW0194');
      doomsidedefs[doomlinedefs[1174].sidenum[0]].midtexture := stringtochar8('RDXW0194');
      doomsidedefs[doomlinedefs[1174].sidenum[0]].bottomtexture := stringtochar8('RDXW0194');

      // Silent teleport
      sd := AddSidedefToWAD(0, stringtochar8('-'), stringtochar8('-'), stringtochar8('-'), 142);
      v1 := AddVertexToWAD(15393, -1345);
      v2 := AddVertexToWAD(15393, -1663);

      realloc(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t), (numdoomlinedefs  + 1) * SizeOf(maplinedef_t));
      doomlinedefs[numdoomlinedefs].v1 := v1;
      doomlinedefs[numdoomlinedefs].v2 := v2;
      doomlinedefs[numdoomlinedefs].flags := ML_TWOSIDED;
      doomlinedefs[numdoomlinedefs].special := 244;
      doomlinedefs[numdoomlinedefs].tag := 1;
      doomlinedefs[numdoomlinedefs].sidenum[0] := sd;
      doomlinedefs[numdoomlinedefs].sidenum[1] := sd;
      inc(numdoomlinedefs);

      v1 := AddVertexToWAD(-17376, -5759);
      v2 := AddVertexToWAD(-17376, -5441);

      realloc(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t), (numdoomlinedefs  + 1) * SizeOf(maplinedef_t));
      doomlinedefs[numdoomlinedefs].v1 := v1;
      doomlinedefs[numdoomlinedefs].v2 := v2;
      doomlinedefs[numdoomlinedefs].flags := ML_TWOSIDED;
      doomlinedefs[numdoomlinedefs].special := 244;
      doomlinedefs[numdoomlinedefs].tag := 1;
      doomlinedefs[numdoomlinedefs].sidenum[0] := sd;
      doomlinedefs[numdoomlinedefs].sidenum[1] := sd;
      inc(numdoomlinedefs);

      // Fix animated textures
      ractions[67].enabled := 1;
      ractions[68].enabled := 1;
      ractions[69].enabled := 1;
    end
    else if levelname = 'E3M3' then
    begin
      result := true;
      sd := doomlinedefs[320].sidenum[0];
      if sd >= 0 then
        doomsidedefs[sd].sector := 48;

      sd := doomlinedefs[321].sidenum[0];
      if sd >= 0 then
        doomsidedefs[sd].sector := 48;

      sd := doomlinedefs[587].sidenum[0];
      if sd >= 0 then
        doomsidedefs[sd].sector := 48;

      sd := doomlinedefs[590].sidenum[0];
      if sd >= 0 then
        doomsidedefs[sd].sector := 48;
    end
    else if levelname = 'E3M7' then
    begin
      result := true;

      fix_changevertexes(-32703, -3520, -32703, -3584);

      doomlinedefs[410].sidenum[1] := -1;
      doomlinedefs[410].flags := doomlinedefs[86].flags and not ML_TWOSIDED;
      doomlinedefs[410].flags := doomlinedefs[86].flags or ML_BLOCKING;
      sd := doomlinedefs[410].sidenum[0];
      if sd >= 0 then
        doomsidedefs[sd].midtexture := doomsidedefs[sd].bottomtexture;

      doomlinedefs[411].sidenum[1] := -1;
      doomlinedefs[411].flags := doomlinedefs[86].flags and not ML_TWOSIDED;
      doomlinedefs[411].flags := doomlinedefs[86].flags or ML_BLOCKING;
      sd := doomlinedefs[411].sidenum[0];
      if sd >= 0 then
        doomsidedefs[sd].midtexture := doomsidedefs[sd].bottomtexture;
    end;
  end;

  // Slpit long linedefs
  function split_long_lidedefs: boolean;
  const
    SPLITDELTA = 260.0;
    SPLITSIZE = 256.0;
  var
    j: integer;
    cnt: integer;
    flen: float;
    dx, dy: integer;
    dline1, dline2: Pmaplinedef_t;
    newx, newy: integer;
    newv: integer;
    A: PBooleanArray;
    at: byte;
  begin
    A := mallocz(numdoomlinedefs);

    for j := 0 to header.numactions - 1 do
    begin
      at := ractions[j].action_type;
      if at in [0, 2, 4, 5, 21, 24, 25, 30, 40] then
      begin
        if ractions[j].params[0] >= 0 then
          A[ractions[j].params[0]] := true;
      end
      else if at = 28 then
      begin
        if ractions[j].params[2] >= 0 then
          A[ractions[j].params[2]] := true;
        if ractions[j].params[3] >= 0 then
          A[ractions[j].params[3]] := true;
        if ractions[j].params[4] >= 0 then
          A[ractions[j].params[4]] := true;
        if ractions[j].params[5] >= 0 then
          A[ractions[j].params[5]] := true;
        if ractions[j].params[6] >= 0 then
          A[ractions[j].params[6]] := true;
      end;
    end;

    for j := 0 to header.numwalls - 1 do
      if rwalls[j].flags and RWF_TWOSIDEDCOMPLETE <> 0 then
        A[j] := true;

    cnt := numdoomlinedefs;
    result := false;
    for j := 0 to cnt - 1 do
      if not A[j] then
      begin
        dline1 := @doomlinedefs[j];
        dx := doomvertexes[dline1.v1].x - doomvertexes[dline1.v2].x;
        dy := doomvertexes[dline1.v1].y - doomvertexes[dline1.v2].y;
        flen := sqr(dx) + sqr(dy);
        if flen > SPLITDELTA * SPLITDELTA then
        begin
          flen := sqrt(flen);

          newx := doomvertexes[dline1.v1].x - round(SPLITSIZE * dx / flen);
          newy := doomvertexes[dline1.v1].y - round(SPLITSIZE * dy / flen);

          newv := AddVertexToWAD(newx, newy);

          realloc(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t), (numdoomlinedefs  + 1) * SizeOf(maplinedef_t));
          dline2 := @doomlinedefs[numdoomlinedefs];
          inc(numdoomlinedefs);

          dline2^ := dline1^;

          dline1.v2 := newv;
          dline2.v1 := newv;
          result := true;
        end;
      end;

    memfree(pointer(A), numdoomlinedefs);
  end;

begin
  ms := TAttachableMemoryStream.Create;
  ms.Attach(rlevel, rsize);
  lcrc32 := strupper(GetBufCRC32(ms.memory, ms.Size));
  if Radix_v2_levelCRC(levelname) = lcrc32 then
    islevel_v := 2
  else if Radix_v10_levelCRC(levelname) = lcrc32 then
    islevel_v := 10
  else if Radix_v11_levelCRC(levelname) = lcrc32 then
    islevel_v := 11
  else
    islevel_v := 0;

  e3m2special := (levelname = 'E3M2') and (islevel_v = 2);

  // Read Radix level header
  ms.Read(header, SizeOf(radixlevelheader_t));
  if header.id <> RADIXMAPMAGIC then
  begin
    result := false;
    ms.Free;
    exit;
  end;
  result := true;

  // Read Radix sectors
  rsectors := malloc(header.numsectors * SizeOf(radixsector_t));
  doomsectorsextra := malloc(header.numsectors * SizeOf(radixmapsectorextra_t));

  ms.Read(rsectors^, header.numsectors * SizeOf(radixsector_t));

  for i := 0 to header.numsectors - 1 do
  begin
    doomsectorsextra[i].xmul := RADIX_MAP_X_MULT;
    doomsectorsextra[i].xadd := RADIX_MAP_X_ADD;
    doomsectorsextra[i].ymul := RADIX_MAP_Y_MULT;
    doomsectorsextra[i].yadd := RADIX_MAP_Y_ADD;
  end;

  // Read Radix walls
  rwalls := malloc(header.numwalls * SizeOf(radixwall_t));
  ms.Read(rwalls^, header.numwalls * SizeOf(radixwall_t));
  for i := 0 to header.numwalls - 1 do
  begin
    if e3m2special and (rwalls[i].v1_x > E3M2_SPLIT_X) and (rwalls[i].v2_x > E3M2_SPLIT_X) then
    begin
      v1x := rwalls[i].v1_x;
      v1y := rwalls[i].v1_y;
      fix_wall_coordXY(v1x, v1y);
      rwalls[i].v1_x := v1x;
      rwalls[i].v1_y := v1y;

      v2x := rwalls[i].v2_x;
      v2y := rwalls[i].v2_y;
      fix_wall_coordXY(v2x, v2y);
      rwalls[i].v2_x := v2x;
      rwalls[i].v2_y := v2y;

      if rwalls[i].frontsector >= 0 then
      begin
        doomsectorsextra[rwalls[i].frontsector].xmul := RADIX_MAP_X_MULT;
        doomsectorsextra[rwalls[i].frontsector].xadd := RADIX_MAP_X_ADD2;
        doomsectorsextra[rwalls[i].frontsector].ymul := RADIX_MAP_Y_MULT;
        doomsectorsextra[rwalls[i].frontsector].yadd := RADIX_MAP_Y_ADD2;
      end;

      if rwalls[i].backsector >= 0 then
      begin
        doomsectorsextra[rwalls[i].backsector].xmul := RADIX_MAP_X_MULT;
        doomsectorsextra[rwalls[i].backsector].xadd := RADIX_MAP_X_ADD2;
        doomsectorsextra[rwalls[i].backsector].ymul := RADIX_MAP_Y_MULT;
        doomsectorsextra[rwalls[i].backsector].yadd := RADIX_MAP_Y_ADD2;
      end;

    end
    else
    begin
      v1x := rwalls[i].v1_x;
      v1y := rwalls[i].v1_y;
      fix_wall_coordXYdef(v1x, v1y);
      rwalls[i].v1_x := v1x;
      rwalls[i].v1_y := v1y;

      v2x := rwalls[i].v2_x;
      v2y := rwalls[i].v2_y;
      fix_wall_coordXYdef(v2x, v2y);
      rwalls[i].v2_x := v2x;
      rwalls[i].v2_y := v2y;
    end;
  end;

  // Read and unpack the 320x128 or 1280x32 grid (RLE compressed)
  // Used for advancing the position of input stream
  ReadRadixGrid(nil); // Line blocking information (unused in doom engine)

  // Read Radix things
  rthings := malloc(header.numthings * SizeOf(radixthing_t));
  ms.Read(rthings^, header.numthings * SizeOf(radixthing_t));

  // Allocate grid trigger grid structure
  gridinfoextra := malloc(SizeOf(radixgridinfo_t));

  // Read Trigger's grid
  ReadRadixGrid(gridinfoextra);

  // Allocate grid to map convertion matrix
  mappointsgridextra := malloc(SizeOf(radixmappointsgrid_t));
  CreateRadixMapToGrid; // Must run after read grid

  // Read Radix sprites/actions
  ractions := mallocz(header.numactions * SizeOf(radixaction_t)); // SOS -> use mallocz
  for i := 0 to header.numactions - 1 do
  begin
    ms.Read(ractions[i], 40); // Read the first 40 bytes
    ms.Read(ractions[i].params, ractions[i].extradata);
  end;

  // Read Radix triggers
  rtriggers := mallocz(header.numtriggers * SizeOf(radixtrigger_t)); // SOS -> use mallocz
  for i := 0 to header.numtriggers - 1 do
  begin
    ms.Read(rtriggers[i], 34); // Read the first 34 bytes
    for j := 0 to rtriggers[i].numactions - 1 do
      ms.Read(rtriggers[i].actions[j], SizeOf(radixtriggeraction_t));
  end;

  // Read Radix player starts
  ms.Seek(header.playerstartoffsets, sFromBeginning);
  ms.Read(rplayerstarts, SizeOf(rplayerstarts));

  if islevel_v = 2 then
    fix_radix_level_v2
  else if islevel_v = 11 then
    fix_radix_level_v11
  else if islevel_v = 10 then
    fix_radix_level_v10;
  fix_radix_level_v10;

  doomthings := nil;
  doomthingsextra := nil;
  numdoomthings := 0;
  doomlinedefs := nil;
  numdoomlinedefs := 0;
  doomsidedefs := nil;
  numdoomsidedefs := 0;
  doomvertexes := nil;
  numdoomvertexes := 0;
  doomsectors := nil;
  numdoomsectors := 0;

  // Create script entry for map - holds extra info
  doommapscript := TDStringList.Create;

  // Create Player starts
  AddPlayerStarts;

  // Create Doom Sectors
  for i := 0 to header.numsectors - 1 do
    AddSectorToWAD(@rsectors[i]);

  // Create Doom Vertexes, Linesdefs & Sidedefs
  for i := 0 to header.numwalls - 1 do
    AddWallToWAD(@rwalls[i]);

  for i := 0 to header.numthings - 1 do
  begin
    if (rthings[i].thing_key >= 0) and (rthings[i].radix_type >= 0) then
      AddThingToWad(
        rthings[i].x, rthings[i].y, rthings[i].ground, rthings[i].speed, rthings[i].height_speed,
        rthings[i].angle, rthings[i].radix_type + _DOOM_THING_2_RADIX_, RadixSkillToDoomSkill(rthings[i].skill),
        rthings[i].skill, rthings[i].thing_key);
  end;

  // Find Doom map bounding box;
  minx := 100000;
  maxx := -100000;
  miny := 100000;
  maxy := -100000;
  for i := 0 to numdoomvertexes - 1 do
  begin
    if doomvertexes[i].x > maxx then
      maxx := doomvertexes[i].x;
    if doomvertexes[i].x < minx then
      minx := doomvertexes[i].x;
    if doomvertexes[i].y > maxy then
      maxy := doomvertexes[i].y;
    if doomvertexes[i].y < miny then
      miny := doomvertexes[i].y;
  end;

  if islevel_v = 2 then
    fix_doom_level_v2
  else if islevel_v = 11 then
    fix_doom_level_v11
  else if islevel_v = 10 then
    fix_doom_level_v10;

  // Find mapped sectors
  sectormapped := mallocz(numdoomsectors);
  for i := 0 to numdoomsidedefs - 1 do
    sectormapped[doomsidedefs[i].sector] := true;

  // Create stub unmapped sectors
  ZeroMemory(@tmpwall, SizeOf(radixwall_t));
  tmpwall.backsector := -1;
  tmpwall.flags := RWF_SINGLESIDED or RWF_STUBWALL;
  tmpwall.wfloortexture := 1;
  for i := 0 to numdoomsectors - 1 do
    if not sectormapped[i] then
    begin
      tmpwall.frontsector := i;

      tmpwall.v1_x := minx + i * 16 + 8;
      tmpwall.v1_y := maxy + 128;
      tmpwall.v2_x := minx + i * 16;
      tmpwall.v2_y := maxy + 136;
      AddWallToWAD(@tmpwall);

      tmpwall.v1_x := minx + i * 16;
      tmpwall.v1_y := maxy + 136;
      tmpwall.v2_x := minx + i * 16 + 8;
      tmpwall.v2_y := maxy + 144;
      AddWallToWAD(@tmpwall);

      tmpwall.v1_x := minx + i * 16 + 8;
      tmpwall.v1_y := maxy + 144;
      tmpwall.v2_x := minx + i * 16 + 8;
      tmpwall.v2_y := maxy + 128;
      AddWallToWAD(@tmpwall);
    end;

  memfree(pointer(sectormapped), numdoomsectors);

//  repeat until not split_long_lidedefs;

  // Move stub linedefs
  stubx := minx + 64;
  stuby := maxy + 256;
  for i := 0 to numdoomlinedefs - 1 do
    if doomlinedefs[i].sidenum[0] < 0 then
      if doomlinedefs[i].sidenum[1] < 0 then
      begin
        doomlinedefs[i].v1 := AddVertexToWAD(stubx, stuby);
        doomlinedefs[i].v2 := AddVertexToWAD(stubx + 32, stuby);
        doomlinedefs[i].flags := doomlinedefs[i].flags or ML_AUTOMAPIGNOGE;
        stubx := stubx + 32;
      end;

  {$IFDEF DEBUG}
  for i := 0 to numdoomlinedefs - 1 do
    if doomlinedefs[i].sidenum[0] >= 0 then
      if doomlinedefs[i].sidenum[1] >= 0 then
      begin
        if doomsectors[doomsidedefs[doomlinedefs[i].sidenum[0]].sector].ceilingheight <> doomsectors[doomsidedefs[doomlinedefs[i].sidenum[1]].sector].ceilingheight then
          if doomsectors[doomsidedefs[doomlinedefs[i].sidenum[0]].sector].ceilingpic = stringtochar8('F_SKY1') then
            if doomsectors[doomsidedefs[doomlinedefs[i].sidenum[1]].sector].ceilingpic = stringtochar8('F_SKY1') then
              if doomsidedefs[doomlinedefs[i].sidenum[0]].toptexture = stringtochar8('-') then
                if doomsidedefs[doomlinedefs[i].sidenum[1]].toptexture = stringtochar8('-') then
                  printf('level %s, line %d joins skies with different ceiling heights'#13#10, [levelname, i]);
      end;
  {$ENDIF}

  wadwriter.AddSeparator(levelname);
  wadwriter.AddData('THINGS', doomthings, numdoomthings * SizeOf(doommapthing_t));
  wadwriter.AddData('LINEDEFS', doomlinedefs, numdoomlinedefs * SizeOf(maplinedef_t));
  wadwriter.AddData('SIDEDEFS', doomsidedefs, numdoomsidedefs * SizeOf(mapsidedef_t));
  wadwriter.AddData('VERTEXES', doomvertexes, numdoomvertexes * SizeOf(mapvertex_t));
  wadwriter.AddSeparator('SEGS');
  wadwriter.AddSeparator('SSECTORS');
  wadwriter.AddSeparator('NODES');
  wadwriter.AddData('SECTORS', doomsectors, numdoomsectors * SizeOf(mapsector_t));
  wadwriter.AddSeparator('REJECT');
  wadwriter.AddSeparator('BLOCKMAP');
  // Radix extra lumps
  // Sectors & walls extra data (scripted)
  wadwriter.AddString('RMAP', doommapscript.Text);
  // THINGS extra stuff (binary)
  wadwriter.AddData('RTHINGS', doomthingsextra, numdoomthings * SizeOf(radixmapthingextra_t));
  // Trigger grid (binary)
  wadwriter.AddData('RGRID', gridinfoextra, SizeOf(radixgridinfo_t));
  // Grid to map convertion matrix
  wadwriter.AddData('RMAPGRID', mappointsgridextra, SizeOf(radixmappointsgrid_t));
  // Sprites/Actions (binary)
  wadwriter.AddData('RACTION', ractions, header.numactions * SizeOf(radixaction_t));
  // Triggers (binary)
  wadwriter.AddData('RTRIGGER', rtriggers, header.numtriggers * SizeOf(radixtrigger_t));

  // Free Radix data
  memfree(pointer(rsectors), header.numsectors * SizeOf(radixsector_t));
  memfree(pointer(rwalls), header.numwalls * SizeOf(radixwall_t));
  memfree(pointer(rthings), header.numthings * SizeOf(radixthing_t));
  memfree(pointer(ractions), header.numactions * SizeOf(radixaction_t));
  memfree(pointer(rtriggers), header.numtriggers * SizeOf(radixtrigger_t));

  // Free Doom data
  memfree(pointer(doomthings), numdoomthings * SizeOf(doommapthing_t));
  memfree(pointer(doomlinedefs), numdoomlinedefs * SizeOf(maplinedef_t));
  memfree(pointer(doomsidedefs), numdoomsidedefs * SizeOf(mapsidedef_t));
  memfree(pointer(doomvertexes), numdoomvertexes * SizeOf(mapvertex_t));
  memfree(pointer(doomsectors), numdoomsectors * SizeOf(mapsector_t));

  // Free extra lumps
  memfree(pointer(doomthingsextra), numdoomthings * SizeOf(radixmapthingextra_t));
  memfree(pointer(gridinfoextra), SizeOf(radixgridinfo_t));
  memfree(pointer(mappointsgridextra), SizeOf(radixmappointsgrid_t));

  // Free Extra Radix Data
  memfree(pointer(doomsectorsextra), numdoomsectors * SizeOf(radixmapsectorextra_t));
  doommapscript.Free;

  ms.Free;
end;

function RX_CreateRadixMapCSV(const levelname: string; const apath: string;
  const rlevel: pointer; const rsize: integer): boolean;
var
  ms: TAttachableMemoryStream;
  header: radixlevelheader_t;
  rsectors: Pradixsector_tArray;
  rwalls: Pradixwall_tArray;
  rthings: Pradixthing_tArray;
  ractions: Pradixaction_tArray;
  rtriggers: Pradixtrigger_tArray;
  csvsectors: TDStringList;
  csvwalls: TDStringList;
  csvthings: TDStringList;
  csvactions: TDStringList;
  csvtriggers: TDStringList;
  i, j: integer;
  path: string;

  // angle is in 0-256
  procedure AddThingToCSV(const th: Pradixthing_t);
  var
    stmp: string;
  begin
    if csvthings.Count = 0 then
      csvthings.Add(
      'skill,' +
      'unknown1,' +
      'unknown2,' +
      'x,' +
      'y,' +
      'angle,' +
      'ground,' +
      'unknown7,' +
      'unknown8,' +
      'radix_type,' +
      'speed,' +
      'thing_key,' +
      'height_speed,' +
      'unknown12');

    sprintf(stmp, '%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d', [
    th.skill,
    th._unknown1,
    th._unknown2,
    th.x,
    th.y,
    th.angle,
    th.ground,
    th._unknown7,
    th._unknown8,
    th.radix_type,
    th.speed,
    th.thing_key,
    th.height_speed,
    th._unknown12]);

    csvthings.Add(stmp);
  end;

  procedure AddActionToCSV(const spr: Pradixaction_t; const id: integer);
  var
    stmp: string;
    ii: integer;
  begin
    if csvactions.Count = 0 then
    begin
      stmp := 'id,unknown1,enabled,name,extradata,dataoffset,type,suspend,';
      stmp := stmp +'unknown2' + ',';
      for ii := 0 to MAX_RADIX_ACTION_PARAMS - 1 do
        stmp := stmp + 'param_' + itoa(ii) + ',';
      csvactions.Add(stmp);
    end;

    stmp := itoa(id) + ',' + itoa(spr.unknown1) + ',';
    stmp := stmp + itoa(spr.enabled) + ',';

    for ii := 0 to 25 do
    begin
      if spr.nameid[ii] = #0 then
        break
      else
        stmp := stmp + spr.nameid[ii];
    end;
    stmp := stmp + ',';

    stmp := stmp + itoa(spr.extradata) + ',';
    stmp := stmp + itoa(spr.dataoffset) + ',';
    stmp := stmp + itoa(spr.action_type) + ',';
    stmp := stmp + itoa(spr.suspend) + ',';

    stmp := stmp + uitoa(spr._unknown2) + ',';
    for ii := 0 to MAX_RADIX_ACTION_PARAMS - 1 do
      stmp := stmp + itoa(spr.params[ii]) + ',';

    csvactions.Add(stmp);
  end;

  procedure AddTriggerToCSV(const tr: Pradixtrigger_t; const id: integer);
  var
    stmp: string;
    ii, jj: integer;
  begin
    if csvtriggers.Count = 0 then
    begin
      stmp := 'id,unknown1,suspended,name,numactions,unknown2,';
      for ii := 0 to 47 {MAX_RADIX_TRIGGER_ACTIONS - 1} do
      begin
        stmp := stmp + 'dataoffset_' + itoa(ii) + ',';
        stmp := stmp + 'action_' + itoa(ii) + ',';
        stmp := stmp + 'trigger_' + itoa(ii) + ',';
        stmp := stmp + 'activationflags_' + itoa(ii) + ',';
        stmp := stmp + 'actiondata_' + itoa(ii) + ',';
      end;
      csvtriggers.Add(stmp);
    end;

    stmp := itoa(id) + ',' + itoa(tr._unknown1) + ',';
    stmp := stmp + itoa(tr.suspended) + ',';

    for ii := 0 to 25 do
    begin
      if tr.nameid[ii] = #0 then
        break
      else
        stmp := stmp + tr.nameid[ii];
    end;
    stmp := stmp + ',';

    stmp := stmp + itoa(tr.numactions) + ',';
    stmp := stmp + uitoa(tr._unknown2) + ',';

    for ii := 0 to 47 {MAX_RADIX_TRIGGER_ACTIONS - 1} do
    begin
      stmp := stmp + itoa(tr.actions[ii].dataoffset) + ',';
      stmp := stmp + itoa(tr.actions[ii].actionid) + ',';
      stmp := stmp + itoa(tr.actions[ii].trigger) + ',';
      stmp := stmp + itoa(tr.actions[ii].activationflags) + ',';
      for jj := 0 to 1 do
        stmp := stmp + itoa(tr.actions[ii]._unknown2[jj]) + ' ';
      stmp := stmp + ',';
    end;

    csvtriggers.Add(stmp);
  end;

  procedure ReadRadixGridAndCreateCSV(const gid: integer);
  var
    grid: Pradixgrid_t;
    grid_X_size: integer;
    grid_Y_size: integer;
    i_grid_x, i_grid_y: integer;
    g, l, k: smallint;
    csvgrid: TDStringList;
    csvgridtable: TDStringList;
    stmp: string;
    sitem: string;
  begin
    if header.orthogonalmap <> 0 then
    begin
      grid_X_size := 320;
      grid_Y_size := 128;
    end
    else
    begin
      grid_X_size := 1280;
      grid_Y_size := 32;
    end;
    grid := mallocz(grid_X_size * grid_Y_size * SizeOf(smallint));

    for i_grid_y := 0 to grid_Y_size - 1 do
    begin
      i_grid_x := 0;
      repeat
        ms.Read(g, SizeOf(smallint));
        if g = -32000 then
        begin
          ms.Read(g, SizeOf(smallint));
          ms.Read(l, SizeOf(smallint));
          for k := 0 to l - 1 do
          begin
            grid[i_grid_y * grid_X_size + i_grid_x] := g;
            inc(i_grid_x);
          end;
        end
        else
        begin
          grid[i_grid_y * grid_X_size + i_grid_x] := g;
          inc(i_grid_x);
        end;
      until i_grid_x >= grid_X_size;
    end;


    csvgrid := TDStringList.Create;
    csvgrid.Add('x=' + itoa(grid_X_size));
    csvgrid.Add('y=' + itoa(grid_Y_size));

    csvgridtable := TDStringList.Create;
    csvgridtable.Add('x,y,value');

    for i_grid_y := 0 to grid_Y_size - 1 do
    begin
      stmp := '';
      for i_grid_x := 0 to grid_X_size - 1 do
      begin
        g := grid[i_grid_y * grid_X_size + i_grid_x];
        sitem := itoa(g);
        while length(sitem) < 6 do sitem := ' ' + sitem;
        stmp := stmp + sitem + ' ';
        if g <> -1 then
          csvgridtable.Add(itoa(i_grid_x) + ',' + itoa(i_grid_y) + ',' + itoa(g));
      end;
      csvgrid.Add(stmp);
    end;
    
    csvgrid.SaveToFile(path + levelname + '_grid' + itoa(gid) + '.txt');
    csvgrid.Free;

    csvgridtable.SaveToFile(path + levelname + '_gridtable' + itoa(gid) + '.txt');
    csvgridtable.Free;

    memfree(pointer(grid), grid_X_size * grid_Y_size * SizeOf(smallint));
  end;

  procedure AddSectorToCSV(const ss: Pradixsector_t; const id: integer);
  var
    stmp: string;
    ii: integer;
  begin
    if csvsectors.Count = 0 then
      csvsectors.Add(
      'id,'+
      'unknown1_0,'+
      'unknown1_1,' +
      'name,' +
      'floortexture,' +
      'ceilingtexture,' +
      'floorheight,' +
      'ceilingheight,' +
      'lightlevel,' +
      'flags,' +
      'fa,' +
      'fb,' +
      'fc,' +
      'fd,' +
      'ca,' +
      'cb,' +
      'cc,' +
      'cd,' +
      'floorangle,' +
      'ceilingangle,'+
      'heightnodesx_1,' +
      'heightnodesx_2,' +
      'heightnodesx_3,' +
      'floorangle_x,' +
      'heightnodesy_1,' +
      'heightnodesy_2,' +
      'heightnodesy_3,' +
      'floorangle_y,' +
      'floorheight_1,' +
      'floorheight_2,' +
      'floorheight_3,' +
      'ceilingangle_x,' +
      'ceilingheight_1,' +
      'ceilingheight_2,' +
      'ceilingheight_3,' +
      'ceilingangle_y');

    stmp := itoa(id) + ',' + itoa(ss._unknown1[0]) + ',' + itoa(ss._unknown1[1]) + ',';

    ii := 0;
    while ii < RADIXSECTORNAMESIZE do
    begin
      if ss.nameid[ii] = #0 then
        break
      else
        stmp := stmp + ss.nameid[ii];
      inc(ii);
    end;
    stmp := stmp + ',';

    stmp := stmp +
    itoa(ss.floortexture) + ',' +
    itoa(ss.ceilingtexture) + ',' +
    itoa(ss.floorheight) + ',' +
    itoa(ss.ceilingheight) + ',' +
    itoa(ss.lightlevel) + ',' +
    itoa(ss.flags) + ',' +
    itoa(ss.fa) + ',' +
    itoa(ss.fb) + ',' +
    itoa(ss.fc) + ',' +
    itoa(ss.fd) + ',' +
    itoa(ss.ca) + ',' +
    itoa(ss.cb) + ',' +
    itoa(ss.cc) + ',' +
    itoa(ss.cd) + ',' +
    itoa(ss.floorangle) + ',' +
    itoa(ss.ceilingangle) + ',';

    stmp := stmp +
    itoa(ss.heightnodesx[0]) + ',' +
    itoa(ss.heightnodesx[1]) + ',' +
    itoa(ss.heightnodesx[2]) + ',' +
    itoa(ss.floorangle_x) + ',' +
    itoa(ss.heightnodesy[0]) + ',' +
    itoa(ss.heightnodesy[1]) + ',' +
    itoa(ss.heightnodesy[2]) + ',' +
    itoa(ss.floorangle_y) + ',';

    stmp := stmp +
    itoa(ss.floorheights[0]) + ',' +
    itoa(ss.floorheights[1]) + ',' +
    itoa(ss.floorheights[2]) + ',' +
    itoa(ss.ceilingangle_x) + ',' +
    itoa(ss.ceilingheights[0]) + ',' +
    itoa(ss.ceilingheights[1]) + ',' +
    itoa(ss.ceilingheights[2]) + ',' +
    itoa(ss.ceilingangle_y) + ',';

    csvsectors.Add(stmp);
  end;

  procedure AddWallToCSV(const w: Pradixwall_t; const id: integer);
  var
    ii: integer;
    stmp: string;
  begin
    if csvwalls.Count = 0 then
    begin
      stmp := 'id,';
      for ii := 0 to 9 do
        stmp := stmp + 'unknown1_' + itoa(ii) + ',';

      stmp := stmp + 'v1_x' + ',';
      stmp := stmp + 'v1_y' + ',';
      stmp := stmp + 'v2_x' + ',';
      stmp := stmp + 'v2_y' + ',';
      stmp := stmp + 'frontsector' + ',';
      stmp := stmp + 'backsector' + ',';

      for ii := 0 to 41 do
      stmp := stmp + 'unknown2_' + itoa(ii) + ',';

      stmp := stmp + 'flags' + ',';

      stmp := stmp + 'bitmapoffset' + ',';

      stmp := stmp + 'floortexture' + ',';
      stmp := stmp + 'ceilingtexture' + ',';
      stmp := stmp + 'hitpoints' + ',';
      stmp := stmp + 'trigger' + ',';

      csvwalls.Add(stmp);
    end;

    stmp := itoa(id) + ',';
    for ii := 0 to 9 do
      stmp := stmp + itoa(w._unknown1[ii]) + ',';

    stmp := stmp + itoa(w.v1_x) + ',';
    stmp := stmp + itoa(w.v1_y) + ',';
    stmp := stmp + itoa(w.v2_x) + ',';
    stmp := stmp + itoa(w.v2_y) + ',';
    stmp := stmp + itoa(w.frontsector) + ',';
    stmp := stmp + itoa(w.backsector) + ',';

    for ii := 0 to 41 do
    stmp := stmp + itoa(w._unknown2[ii]) + ',';

    stmp := stmp + itoa(w.flags) + ',';
    stmp := stmp + itoa(w.bitmapoffset) + ',';
    stmp := stmp + itoa(w.wfloortexture) + ',';
    stmp := stmp + itoa(w.wceilingtexture) + ',';

    stmp := stmp + itoa(w.hitpoints) + ',';
    stmp := stmp + itoa(w.trigger) + ',';

    csvwalls.Add(stmp);
  end;

begin
  ms := TAttachableMemoryStream.Create;
  ms.Attach(rlevel, rsize);

  // Read Radix level header
  ms.Read(header, SizeOf(radixlevelheader_t));
  if header.id <> RADIXMAPMAGIC then
  begin
    result := false;
    ms.Free;
    exit;
  end;
  result := true;

  path := apath;
  if path <> '' then
    if path[length(path)] <> '\' then
      path := path + '\';

  // Read Radix sectors
  rsectors := malloc(header.numsectors * SizeOf(radixsector_t));
  ms.Read(rsectors^, header.numsectors * SizeOf(radixsector_t));

  // Read Radix walls
  rwalls := malloc(header.numwalls * SizeOf(radixwall_t));
  ms.Read(rwalls^, header.numwalls * SizeOf(radixwall_t));

  // Read and unpack the 320x128 or 1280x32 grid (RLE compressed)
  // Used for advancing the position of input stream
  ReadRadixGridAndCreateCSV(1);

  // Read Radix things
  rthings := malloc(header.numthings * SizeOf(radixthing_t));
  ms.Read(rthings^, header.numthings * SizeOf(radixthing_t));

  // Read trigger's grid
  ReadRadixGridAndCreateCSV(2);

  // Read Radix sprites/actions
  ractions := mallocz(header.numactions * SizeOf(radixaction_t)); // SOS -> use mallocz
  for i := 0 to header.numactions - 1 do
  begin
    ms.Read(ractions[i], 40); // Read the first 40 bytes
    ms.Read(ractions[i].params, ractions[i].extradata);
  end;

  // Read Radix triggers
  rtriggers := mallocz(header.numtriggers * SizeOf(radixtrigger_t)); // SOS -> use mallocz
  for i := 0 to header.numtriggers - 1 do
  begin
    ms.Read(rtriggers[i], 34); // Read the first 34 bytes
    for j := 0 to rtriggers[i].numactions - 1 do
      ms.Read(rtriggers[i].actions[j], SizeOf(radixtriggeraction_t));
  end;

  // Read final grid ?
//  ReadRadixGridAndCreateCSV(3);

  csvsectors := TDStringList.Create;
  csvwalls := TDStringList.Create;
  csvthings := TDStringList.Create;
  csvactions := TDStringList.Create;
  csvtriggers := TDStringList.Create;

  // Add Sectors to CSV
  for i := 0 to header.numsectors - 1 do
    AddSectorToCSV(@rsectors[i], i);

  // Add Walls to CSV
  for i := 0 to header.numwalls - 1 do
    AddWallToCSV(@rwalls[i], i);

  // Add Things to CSV
  for i := 0 to header.numthings - 1 do
  begin
//    if rthings[i].radix_type > 0 then
      AddThingToCSV(@rthings[i]);
  end;

  // Add Sprites/actions to CSV
  for i := 0 to header.numactions - 1 do
    AddActionToCSV(@ractions[i], i);

  // Add Triggers to CSV
  for i := 0 to header.numtriggers - 1 do
    AddTriggerToCSV(@rtriggers[i], i);

  csvsectors.SaveToFile(path + levelname + '_sectors.txt');
  csvwalls.SaveToFile(path + levelname + '_walls.txt');
  csvthings.SaveToFile(path + levelname + '_things.txt');
  csvactions.SaveToFile(path + levelname + '_actions.txt');
  csvtriggers.SaveToFile(path + levelname + '_triggers.txt');

  csvsectors.Free;
  csvwalls.Free;
  csvthings.Free;
  csvactions.Free;
  csvtriggers.Free;

  // Free Radix data
  memfree(pointer(rsectors), header.numsectors * SizeOf(radixsector_t));
  memfree(pointer(rwalls), header.numwalls * SizeOf(radixwall_t));
  memfree(pointer(rthings), header.numthings * SizeOf(radixthing_t));
  memfree(pointer(ractions), header.numactions * SizeOf(radixaction_t));
  memfree(pointer(rtriggers), header.numtriggers * SizeOf(radixtrigger_t));


  ms.Free;
end;

end.

