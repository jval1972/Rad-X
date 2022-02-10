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
//   Tool to create an Editing WAD - Main form
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Panel2: TPanel;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Edit2: TEdit;
    Panel3: TPanel;
    Memo1: TMemo;
    BitBtn3: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
  private
    { Private declarations }
    finpfilename: string;
    foutfilename: string;
    flags: LongWord;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  d_delphi,
  w_pak,
  radix_xlat_wad,
  frm_rad2wadoptions;

//==============================================================================
//
// println
//
//==============================================================================
procedure println(const s: string);
begin
  Form1.Memo1.Lines.Add(s);
  if Form1.Memo1.Lines.Count > 200 then
    Form1.Memo1.Lines.Delete(0);
end;

//==============================================================================
//
// TForm1.FormCreate
//
//==============================================================================
procedure TForm1.FormCreate(Sender: TObject);
begin
  finpfilename := '';
  foutfilename := '';
  BitBtn2.Enabled := false;
  BitBtn3.Enabled := false;
  Edit1.Text := '';
  Edit2.Text := '';
  Memo1.Lines.Clear;
  println('RAD2WAD v1.0, (c) 2020-2022 by Jim Valavanis');
  println('Use this tool to create an editing WAD from RADIX.DAT.');
  println('The output WAD can be used by editors to create custom levels for RAD.');
  println('IMPORTANT: ');
  println('    The output WAD is not required to be loaded from RAD.');
  println('    RAD loads all the resources it needs from RADIX.DAT.');
  println('');
  println('For updates please visit https://sourceforge.net/projects/rad-x/');
  println('');
  flags := R2W_DOOMPALETTE or R2W_DOOMTEXTURES or R2W_FLATS or R2W_SPRITES;
end;

//==============================================================================
//
// TForm1.BitBtn1Click
//
//==============================================================================
procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    Edit1.Text := OpenDialog1.FileName;
    finpfilename := OpenDialog1.FileName;
    println('Input file: ' + finpfilename);
    BitBtn2.Enabled := true;
  end;
end;

//==============================================================================
//
// TForm1.BitBtn2Click
//
//==============================================================================
procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    Edit2.Text := SaveDialog1.FileName;
    foutfilename := SaveDialog1.FileName;
    println('Output file: ' + foutfilename);
    BitBtn3.Enabled := true;
    BitBtn3Click(Sender);
  end;
end;

//==============================================================================
//
// TForm1.BitBtn3Click
//
//==============================================================================
procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  finpfilename := Trim(finpfilename);
  if finpfilename = '' then
  begin
    println('Please select input file!');
    exit;
  end;

  if not fexists(finpfilename) then
  begin
    println('Input file "' + finpfilename + '" does not exist!');
    exit;
  end;

  foutfilename := Trim(foutfilename);
  if foutfilename = '' then
  begin
    println('Please select output file!');
    exit;
  end;

  if UpperCase(ExpandFileName(foutfilename)) = UpperCase(ExpandFileName(finpfilename)) then
  begin
    println('Input and output file must be different!');
    exit;
  end;

  if GetConvertionOptions(flags) then
  begin
    flags := flags or R2W_DOOMPALETTE;

    println('Converting ' + fname(finpfilename) + ' to ' + fname(foutfilename));
    Screen.Cursor := crHourglass;
    try
      PAK_InitFileSystem;
      Radix2WAD(finpfilename, foutfilename, flags);
      PAK_ShutDown;
    finally
      Screen.Cursor := crDefault;
    end;
    MessageBeep(0);
    if fexists(foutfilename) then
      println('Conversion finished!')
    else
      println('Conversion failed!')
  end;
end;

end.
