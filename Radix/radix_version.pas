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
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_version;

interface

uses
  doomdef;

var
  radix_crc32: string = '';

type
  radixversion_t = (
    rv10sha, rv10reg,
    rv11sha, rv11reg,
    rv20sha, rv20reg,
    rvunknown
  );

var
  radixversion: radixversion_t = rvunknown;

type
  radixversioninfo_t = record
    version: radixversion_t;
    crc32: string[8];
    gamemode: GameMode_t;
    versionstring: string[32];
  end;

const
  NUM_RADIX_VERSION_INFO = 6;

const
  radixversioninfo: array[0..NUM_RADIX_VERSION_INFO - 1] of radixversioninfo_t = (
    (version: rv10sha; crc32: '745cf789'; gamemode: shareware; versionstring: 'Radix v1.0 Shareware'),
    (version: rv10reg; crc32: 'f7d737a5'; gamemode: registered; versionstring: 'Radix v1.0 Registered'),
    (version: rv11sha; crc32: '681b6be8'; gamemode: shareware; versionstring: 'Radix v1.1 Shareware'),
    (version: rv10reg; crc32: '4947eb68'; gamemode: shareware; versionstring: 'Radix v1.1 Registered'),
    (version: rv20sha; crc32: '593759be'; gamemode: shareware; versionstring: 'Radix v2.0 Remix Shareware'),
    (version: rv20reg; crc32: '67f5000c'; gamemode: registered; versionstring: 'Radix v2.0 Remix Registered')
  );

function RX_GameModeFromCrc32(const crc: string): Gamemode_t;

function RX_RadixVersionFromCrc32(const crc: string): radixversion_t;

function RX_VersionStringFromCrc32(const crc: string): string;

implementation

uses
  d_delphi;

function RX_GameModeFromCrc32(const crc: string): Gamemode_t;
var
  i: integer;
begin
  for i := 0 to NUM_RADIX_VERSION_INFO - 1 do
  begin
    if strupper(crc) = strupper(radixversioninfo[i].crc32) then
    begin
      result := radixversioninfo[i].gamemode;
      exit;
    end;
  end;
  result := indetermined;
end;

function RX_RadixVersionFromCrc32(const crc: string): radixversion_t;
var
  i: integer;
begin
  for i := 0 to NUM_RADIX_VERSION_INFO - 1 do
  begin
    if strupper(crc) = strupper(radixversioninfo[i].crc32) then
    begin
      result := radixversioninfo[i].version;
      exit;
    end;
  end;
  result := rvunknown;
end;


function RX_VersionStringFromCrc32(const crc: string): string;
var
  i: integer;
begin
  for i := 0 to NUM_RADIX_VERSION_INFO - 1 do
  begin
    if strupper(crc) = strupper(radixversioninfo[i].crc32) then
    begin
      result := radixversioninfo[i].versionstring;
      exit;
    end;
  end;
  result := 'Game mode indeterminate';
end;

end.
