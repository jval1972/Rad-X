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
//   Tool to create an Editing WAD - Options form
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit frm_rad2wadoptions;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls;

type
  TOptionsForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    TexturesCheckBox: TCheckBox;
    Panel3: TPanel;
    FlatsCheckBox: TCheckBox;
    Panel4: TPanel;
    SpritesCheckBox: TCheckBox;
    Panel5: TPanel;
    HUDCheckBox: TCheckBox;
    Panel6: TPanel;
    FontsCheckBox: TCheckBox;
    Panel7: TPanel;
    MusicCheckBox: TCheckBox;
    Panel8: TPanel;
    SoundCheckBox: TCheckBox;
    Panel9: TPanel;
    TextCheckBox: TCheckBox;
    Panel10: TPanel;
    LevelsCheckBox: TCheckBox;
    Panel11: TPanel;
    Button1: TButton;
    Button2: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;


function GetConvertionOptions(var flags: LongWord): boolean;

implementation

{$R *.dfm}

uses
  radix_xlat_wad;

function GetConvertionOptions(var flags: LongWord): boolean;
var
  f: TOptionsForm;
begin
  result := false;
  f := TOptionsForm.Create(nil);
  try
    f.TexturesCheckBox.Checked := flags and R2W_DOOMTEXTURES <> 0;
    f.FlatsCheckBox.Checked := flags and R2W_FLATS <> 0;
    f.SpritesCheckBox.Checked := flags and R2W_SPRITES <> 0;
    f.HUDCheckBox.Checked := flags and (R2W_MAINGRAPHICS or R2W_ADDITIONALGRAPHICS or R2W_COCKPIT) <> 0;
    f.FontsCheckBox.Checked := flags and (R2W_SMALLMENUFONT or R2W_BIGMENUFONT or R2W_CONSOLEFONT or R2W_MENUTRANSLATION) <> 0;
    f.MusicCheckBox.Checked := flags and R2W_MUSIC <> 0;
    f.SoundCheckBox.Checked := flags and R2W_SOUNDS <> 0;
    f.TextCheckBox.Checked := flags and (R2W_OBJECTIVES or R2W_ENDTEXT) <> 0;
    f.LevelsCheckBox.Checked := flags and R2W_DOOMLEVELS <> 0;
    f.ShowModal;
    if f.ModalResult = mrOK then
    begin
      flags := 0;
      if f.TexturesCheckBox.Checked then flags := flags or R2W_DOOMTEXTURES;
      if f.FlatsCheckBox.Checked then flags := flags or R2W_FLATS;
      if f.SpritesCheckBox.Checked then flags := flags or R2W_SPRITES;
      if f.HUDCheckBox.Checked then flags := flags or (R2W_MAINGRAPHICS or R2W_ADDITIONALGRAPHICS or R2W_COCKPIT);
      if f.FontsCheckBox.Checked then flags := flags or (R2W_SMALLMENUFONT or R2W_BIGMENUFONT or R2W_CONSOLEFONT or R2W_MENUTRANSLATION);
      if f.MusicCheckBox.Checked then flags := flags or R2W_MUSIC;
      if f.SoundCheckBox.Checked then flags := flags or R2W_SOUNDS;
      if f.TextCheckBox.Checked then flags := flags or (R2W_OBJECTIVES or R2W_ENDTEXT);
      if f.LevelsCheckBox.Checked then flags := flags or R2W_DOOMLEVELS;
      result := true;
    end;
  finally
    f.Free;
  end;
end;

end.
