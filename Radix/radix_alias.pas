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
//  Radix.dat Aliases
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit radix_alias;

interface

//==============================================================================
//
// RX_InitRadixAlias
//
//==============================================================================
procedure RX_InitRadixAlias;

//==============================================================================
//
// RX_ShutDownRadixAlias
//
//==============================================================================
procedure RX_ShutDownRadixAlias;

//==============================================================================
//
// RX_FindAliasLump
//
//==============================================================================
function RX_FindAliasLump(const lumpname: string): integer;

implementation

uses
  d_delphi,
  w_wad;

const
  NUM_ALIAS_LISTS = 16;

var
  rx_aliases: array[0..NUM_ALIAS_LISTS - 1] of TDStringList;

//==============================================================================
//
// RX_FindAliasList
//
//==============================================================================
function RX_FindAliasList(const r_entry: string): integer;
begin
  if r_entry = '' then
    result := 0
  else
    result := Ord(r_entry[1]) mod NUM_ALIAS_LISTS;
end;

//==============================================================================
//
// RX_ParseAlias
//
//==============================================================================
procedure RX_ParseAlias(const in_text: string);
var
  i: integer;
  lst: TDStringList;
  w_entry, r_entry: string;
  lump: integer;
  lid: integer;
begin
  lst := TDStringList.Create;
  try
    lst.Text := in_text;
    for i := lst.Count - 1 downto 0 do
    begin
      splitstring(lst.Strings[i], w_entry, r_entry, '=');
      lump := W_CheckNumForName(w_entry);
      if lump >= 0 then
      begin
        lid := RX_FindAliasList(r_entry);
        rx_aliases[lid].AddObject(strupper(r_entry), TInteger.Create(lump));
      end;
    end;
  finally
    lst.Free;
  end;
end;

//==============================================================================
//
// RX_InitRadixAlias
//
//==============================================================================
procedure RX_InitRadixAlias;
var
  i: integer;
begin
  for i := 0 to NUM_ALIAS_LISTS - 1 do
    rx_aliases[i] := TDStringList.Create;
  for i := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(i)) = S_RADIXINF then
      RX_ParseAlias(W_TextLumpNum(i));
end;

//==============================================================================
//
// RX_ShutDownRadixAlias
//
//==============================================================================
procedure RX_ShutDownRadixAlias;
var
  i, j: integer;
begin
  for i := 0 to NUM_ALIAS_LISTS - 1 do
  begin
    for j := 0 to rx_aliases[i].Count - 1 do
      rx_aliases[i].Objects[j].Free;
    rx_aliases[i].Free;
  end;
end;

//==============================================================================
//
// RX_FindAliasLump
//
//==============================================================================
function RX_FindAliasLump(const lumpname: string): integer;
var
  lid: integer;
  idx: integer;
  ulumpname: string;
begin
  ulumpname := strupper(lumpname);
  lid := RX_FindAliasList(ulumpname);
  idx := rx_aliases[lid].IndexOf(ulumpname);
  if idx >= 0 then
    result := (rx_aliases[lid].Objects[idx] as TInteger).intnum
  else
    result := -1;
end;

end.
