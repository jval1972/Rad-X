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
//   Radix bitmap stuff
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

unit radix_bitmap;

interface

uses
  d_delphi;

//==============================================================================
//
// RX_RotatebitmapBuffer90
//
//==============================================================================
procedure RX_RotatebitmapBuffer90(const buf: PByteArray; const w, h: integer);

//==============================================================================
//
// RX_FlipbitmapbufferHorz
//
//==============================================================================
procedure RX_FlipbitmapbufferHorz(const buf: PByteArray; const w, h: integer);

//==============================================================================
//
// RX_BltImageBuffer
//
//==============================================================================
procedure RX_BltImageBuffer(const inbuf: PByteArray; const inw, inh: integer;
  const outbuf: PByteArray; const x1, x2: integer; const y1, y2: integer);

//==============================================================================
//
// RX_ColorReplace
//
//==============================================================================
procedure RX_ColorReplace(const buf: PByteArray; const w, h: integer; const oldc, newc: byte);

type
  TRadixBitmap = class
  private
    fwidth, fheight: integer;
    fimg: PByteArray;
    function pos2idx(const x, y: integer): integer;
  protected
    procedure SetWidth(const awidth: integer); virtual;
    procedure SetHeight(const aheight: integer); virtual;
    function GetPixel(x, y: integer): byte; virtual;
    procedure SetPixel(x, y: integer; const apixel: byte); virtual;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure ApplyTranslationTable(const trans: PByteArray);
    procedure AttachImage(const buf: PByteArray; const awidth, aheight: integer);
    procedure Clear(const color: byte);
    procedure Crop(const nw, nh: integer);
    function BottomCrop: boolean;
    property width: integer read fwidth write SetWidth;
    property height: integer read fheight write SetHeight;
    property Pixels[x, y: integer]: byte read GetPixel write SetPixel; default;
    property Image: PByteArray read fimg;
  end;

implementation

//==============================================================================
//
// RX_RotatebitmapBuffer90
//
//==============================================================================
procedure RX_RotatebitmapBuffer90(const buf: PByteArray; const w, h: integer);
var
  i, j: integer;
  img: PByteArray;
  b: byte;
begin
  img := mallocz(w * h);
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := buf[j * w + i];
      img[i * h + j] := b;
    end;
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := img[j * w + i];
      buf[j * w + i] := b;
    end;
  memfree(pointer(img), w * h);
end;

//==============================================================================
//
// RX_FlipbitmapbufferHorz
//
//==============================================================================
procedure RX_FlipbitmapbufferHorz(const buf: PByteArray; const w, h: integer);
var
  i, j: integer;
  img: PByteArray;
  b: byte;
begin
  img := mallocz(w * h);
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := buf[j * w + i];
      img[(h - j - 1) * w + i] := b;
    end;
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
    begin
      b := img[j * w + i];
      buf[j * w + i] := b;
    end;
  memfree(pointer(img), w * h);
end;

//==============================================================================
//
// RX_BltImageBuffer
//
//==============================================================================
procedure RX_BltImageBuffer(const inbuf: PByteArray; const inw, inh: integer;
  const outbuf: PByteArray; const x1, x2: integer; const y1, y2: integer);
var
  i, j: integer;
  b: byte;
  outh: integer;
begin
  outh := y2 - y1 + 1;
  for i := x1 to x2 do
    for j := y1 to y2 do
    begin
      b := inbuf[i * inh + j];
      outbuf[(i - x1) * outh + (j - y1)] := b;
    end;
end;

//==============================================================================
//
// RX_ColorReplace
//
//==============================================================================
procedure RX_ColorReplace(const buf: PByteArray; const w, h: integer; const oldc, newc: byte);
var
  i: integer;
begin
  for i := 0 to w * h - 1 do
    if buf[i] = oldc then
      buf[i] := newc;
end;

// TRadixBitmap

constructor TRadixBitmap.Create;
begin
  fwidth := 0;
  fheight := 0;
  fimg := nil;
  inherited;
end;

destructor TRadixBitmap.Destroy;
begin
  if fimg <> nil then
    memfree(pointer(fimg), fwidth * fheight);
  inherited;
end;

//==============================================================================
//
// TRadixBitmap.ApplyTranslationTable
//
//==============================================================================
procedure TRadixBitmap.ApplyTranslationTable(const trans: PByteArray);
var
  i: integer;
begin
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := trans[fimg[i]];
end;

//==============================================================================
//
// TRadixBitmap.AttachImage
//
//==============================================================================
procedure TRadixBitmap.AttachImage(const buf: PByteArray; const awidth, aheight: integer);
var
  i: integer;
begin
  SetWidth(awidth);
  SetHeight(aheight);
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := buf[i];
end;

//==============================================================================
//
// TRadixBitmap.Clear
//
//==============================================================================
procedure TRadixBitmap.Clear(const color: byte);
var
  i: integer;
begin
  for i := 0 to fwidth * fheight - 1 do
    fimg[i] := color;
end;

//==============================================================================
//
// TRadixBitmap.pos2idx
//
//==============================================================================
function TRadixBitmap.pos2idx(const x, y: integer): integer;
begin
  result := x * fheight + y;
end;

//==============================================================================
//
// TRadixBitmap.Crop
//
//==============================================================================
procedure TRadixBitmap.Crop(const nw, nh: integer);
var
  tmp: TRadixBitmap;
  i, j: integer;
  w, h: integer;
begin
  tmp := TRadixBitmap.Create;
  tmp.AttachImage(fimg, fwidth, fheight);
  SetWidth(nw);
  SetHeight(nh);
  w := MinI(fwidth, nw);
  h := MinI(fheight, nh);
  for i := 0 to w - 1 do
    for j := 0 to h - 1 do
      fimg[pos2idx(i, j)] := tmp.Pixels[i, j];
  tmp.Free;
end;

//==============================================================================
//
// TRadixBitmap.BottomCrop
//
//==============================================================================
function TRadixBitmap.BottomCrop: boolean;
var
  i: integer;
begin
  if fheight < 2 then
  begin
    result := false;
    exit;
  end;

  for i := 0 to fwidth - 1 do
    if fimg[pos2idx(i, fheight - 1)] <> 254 then
    begin
      result := false;
      exit;
    end;

  Crop(fwidth, fheight - 1);
  result := true;
end;

//==============================================================================
//
// TRadixBitmap.SetWidth
//
//==============================================================================
procedure TRadixBitmap.SetWidth(const awidth: integer);
var
  oldsz, newsz: integer;
begin
  if awidth = fwidth then
    exit;
  oldsz := fwidth * fheight;
  fwidth := awidth;
  newsz := fwidth * fheight;
  if newsz <> oldsz then
    realloc(pointer(fimg), oldsz, newsz);
end;

//==============================================================================
//
// TRadixBitmap.SetHeight
//
//==============================================================================
procedure TRadixBitmap.SetHeight(const aheight: integer);
var
  oldsz, newsz: integer;
begin
  if aheight = fheight then
    exit;
  oldsz := fwidth * fheight;
  fheight := aheight;
  newsz := fwidth * fheight;
  if newsz <> oldsz then
    realloc(pointer(fimg), oldsz, newsz);
end;

//==============================================================================
//
// TRadixBitmap.GetPixel
//
//==============================================================================
function TRadixBitmap.GetPixel(x, y: integer): byte;
begin
  if not IsIntegerInRange(x, 0, fwidth - 1) then
  begin
    result := 0;
    exit;
  end;
  if not IsIntegerInRange(y, 0, fheight - 1) then
  begin
    result := 0;
    exit;
  end;
  result := fimg[pos2idx(x, y)];
end;

//==============================================================================
//
// TRadixBitmap.SetPixel
//
//==============================================================================
procedure TRadixBitmap.SetPixel(x, y: integer; const apixel: byte);
begin
  if not IsIntegerInRange(x, 0, fwidth - 1) then
    exit;
  if not IsIntegerInRange(y, 0, fheight - 1) then
    exit;
  fimg[pos2idx(x, y)] := apixel;
end;

end.
