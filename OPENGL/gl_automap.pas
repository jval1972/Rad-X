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
//   OpenGL AutoMap
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit gl_automap;

interface

uses
  r_defs;

//==============================================================================
//
// gld_InitAutomap
//
//==============================================================================
procedure gld_InitAutomap;

//==============================================================================
//
// gld_ShutDownAutomap
//
//==============================================================================
procedure gld_ShutDownAutomap;

//==============================================================================
//
// gld_ClearAMBuffer
//
//==============================================================================
procedure gld_ClearAMBuffer(const fw, fh: integer; const cc: LongWord);

//==============================================================================
//
// gld_AddAutomapLine
//
//==============================================================================
procedure gld_AddAutomapLine(const x1, y1, x2, y2: integer; const cc: LongWord);

//==============================================================================
//
// gld_AddAutomapPatch
//
//==============================================================================
procedure gld_AddAutomapPatch(const x, y: integer; const lump: integer);

procedure gld_AddAutomapTriangle(
  const x1, y1, u1, v1: integer;
  const x2, y2, u2, v2: integer;
  const x3, y3, u3, v3: integer;
  const cc: LongWord; const fwidth: integer; const lump: integer; const sec: Psector_t);

//==============================================================================
//
// gld_DrawAutomap
//
//==============================================================================
procedure gld_DrawAutomap;

implementation

uses
  dglOpenGL,
  doomdef,
  d_delphi,
  m_fixed,
  tables,
  gl_defs,
  gl_tex,
  gl_render,
  v_data,
  v_video;

const
  GL_AM_QUAD = 0;
  GL_AM_LINE = 1;
  GL_AM_TRIANGLE = 2;
  GL_AM_PATCH = 3;

type
  glamrenderitem_t = record
    itemtype: integer;
    x1, y1, x2, y2, x3, y3: integer;
    u1, v1, u2, v2, u3, v3: float;
    lump: integer;
    hasangle: boolean;
    angle: float;
    anglex, angley: float;
    r, g, b: float;
  end;
  Pglamrenderitem_t = ^glamrenderitem_t;
  glamrenderitem_tArray = array[0..$FFF] of glamrenderitem_t;
  Pglamrenderitem_tArray = ^glamrenderitem_tArray;

var
  amrenderitems: Pglamrenderitem_tArray = nil;
  numamitems: integer = 0;
  realnumamitems: integer = 0;

//==============================================================================
//
// gld_InitAutomap
//
//==============================================================================
procedure gld_InitAutomap;
begin
  amrenderitems := nil;
  numamitems := 0;
  realnumamitems := 0;
end;

//==============================================================================
//
// gld_ShutDownAutomap
//
//==============================================================================
procedure gld_ShutDownAutomap;
begin
  memfree(pointer(amrenderitems), realnumamitems * SizeOf(glamrenderitem_t));
  numamitems := 0;
  realnumamitems := 0;
end;

//==============================================================================
//
// gld_GrowAutomapLines
//
//==============================================================================
procedure gld_GrowAutomapLines;
const
  GROWSTEP = 64;
begin
  if numamitems >= realnumamitems then
  begin
    realloc(pointer(amrenderitems), realnumamitems * SizeOf(glamrenderitem_t), (realnumamitems + GROWSTEP) * SizeOf(glamrenderitem_t));
    realnumamitems := realnumamitems + GROWSTEP;
  end;
end;

//==============================================================================
//
// gld_ClearAMBuffer
//
//==============================================================================
procedure gld_ClearAMBuffer(const fw, fh: integer; const cc: LongWord);
var
  l: Pglamrenderitem_t;
begin
  gld_GrowAutomapLines;

  l := @amrenderitems[numamitems];
  l.itemtype := GL_AM_QUAD;
  l.x1 := 0;
  l.y1 := 0;
  l.x2 := fw;
  l.y2 := fh;
  l.r := ((cc shr 16) and $FF) / 255;
  l.g := ((cc shr 8) and $FF) / 255;
  l.b := (cc and $FF) / 255;

  inc(numamitems);
end;

//==============================================================================
//
// gld_AddAutomapLine
//
//==============================================================================
procedure gld_AddAutomapLine(const x1, y1, x2, y2: integer; const cc: LongWord);
var
  l: Pglamrenderitem_t;
begin
  gld_GrowAutomapLines;

  l := @amrenderitems[numamitems];
  l.itemtype := GL_AM_LINE;
  l.x1 := x1;
  l.y1 := y1;
  l.x2 := x2;
  l.y2 := y2;
  l.r := ((cc shr 16) and $FF) / 255;
  l.g := ((cc shr 8) and $FF) / 255;
  l.b := (cc and $FF) / 255;

  inc(numamitems);
end;

//==============================================================================
//
// gld_AddAutomapPatch
//
//==============================================================================
procedure gld_AddAutomapPatch(const x, y: integer; const lump: integer);
var
  l: Pglamrenderitem_t;
begin
  gld_GrowAutomapLines;

  l := @amrenderitems[numamitems];
  l.itemtype := GL_AM_PATCH;
  l.x1 := x;
  l.y1 := y;
  l.lump := lump;

  inc(numamitems);
end;

procedure gld_AddAutomapTriangle(
  const x1, y1, u1, v1: integer;
  const x2, y2, u2, v2: integer;
  const x3, y3, u3, v3: integer;
  const cc: LongWord; const fwidth: integer; const lump: integer; const sec: Psector_t);
var
  l: Pglamrenderitem_t;
begin
  gld_GrowAutomapLines;

  l := @amrenderitems[numamitems];
  l.itemtype := GL_AM_TRIANGLE;

  l.x1 := x1;
  l.y1 := y1;
  l.u1 := u1 / FRACUNIT / fwidth;
  l.v1 := v1 / FRACUNIT / fwidth;

  l.x2 := x2;
  l.y2 := y2;
  l.u2 := u2 / FRACUNIT / fwidth;
  l.v2 := v2 / FRACUNIT / fwidth;

  l.x3 := x3;
  l.y3 := y3;
  l.u3 := u3 / FRACUNIT / fwidth;
  l.v3 := v3 / FRACUNIT / fwidth;

  l.r := ((cc shr 16) and $FF) / 255;
  l.g := ((cc shr 8) and $FF) / 255;
  l.b := (cc and $FF) / 255;

  l.lump := lump;

  l.hasangle := sec.floorangle <> 0;
  if l.hasangle then
  begin
    l.angle := (sec.floorangle / ANGLE_MAX) * 360.0;
    l.anglex := sec.flooranglex / (FRACUNIT * fwidth);
    l.angley := sec.floorangley / (FRACUNIT * fwidth);
  end;

  inc(numamitems);
end;

//==============================================================================
//
// gld_DrawAMQuad
//
//==============================================================================
procedure gld_DrawAMQuad(const l: Pglamrenderitem_t);
begin
  glColor4f(l.r, l.g, l.b, 1.0);

  glBegin(GL_QUADS);
    glVertex2i(l.x1, l.y1);
    glVertex2i(l.x2, l.y1);
    glVertex2i(l.x2, l.y2);
    glVertex2i(l.x1, l.y2);
  glEnd;
end;

//==============================================================================
//
// gld_DrawAMLine
//
//==============================================================================
procedure gld_DrawAMLine(const l: Pglamrenderitem_t);
begin
  glColor4f(l.r, l.g, l.b, 1.0);

  glBegin(GL_LINES);
    glVertex2i(l.x1, l.y1);
    glVertex2i(l.x2, l.y2);
  glEnd;
end;

//==============================================================================
//
// gld_DrawAMPatch
//
//==============================================================================
procedure gld_DrawAMPatch(const l: Pglamrenderitem_t);
begin
  glEnable(GL_TEXTURE_2D);

  glColor4f(1.0, 1.0, 1.0, 1.0);

  gld_DrawNumPatch(l.x1, l.y1, l.lump, 0, VPT_NOUNLOAD, SCREENWIDTH / 320, SCREENHEIGHT / 200);

  glDisable(GL_TEXTURE_2D);
end;

//==============================================================================
//
// gld_DrawAMTriangle
//
//==============================================================================
procedure gld_DrawAMTriangle(const l: Pglamrenderitem_t);
var
  tex: PGLTexture;
begin
  glEnable(GL_TEXTURE_2D);

  glColor4f(l.r, l.g, l.b, 1.0);

  tex := gld_RegisterFlat(l.lump, true);
  gld_BindFlat(tex, -1);

  if l.hasangle then
  begin
    glMatrixMode(GL_TEXTURE);
    glPushMatrix;
    glTranslatef(
      l.anglex,
      -l.angley,
      0.0);
    glRotatef(l.angle, 0, 0, 1);
    glTranslatef(
      -l.anglex,
      l.angley,
      0.0);
  end;

  glBegin(GL_TRIANGLES);
    glTexCoord2f(l.v1, l.u1);
    glVertex2i(l.x1, l.y1);
    glTexCoord2f(l.v2, l.u2);
    glVertex2i(l.x2, l.y2);
    glTexCoord2f(l.v3, l.u3);
    glVertex2i(l.x3, l.y3);
  glEnd;

  if l.hasangle then
  begin
    glMatrixMode(GL_TEXTURE);
    glPopMatrix;
    glMatrixMode(GL_MODELVIEW);
  end;

  glDisable(GL_TEXTURE_2D);
end;

//==============================================================================
//
// gld_DrawAutomap
//
//==============================================================================
procedure gld_DrawAutomap;
var
  i: integer;
  l: Pglamrenderitem_t;
begin
  glDisable(GL_TEXTURE_2D);

  for i := 0 to numamitems - 1 do
  begin
    l := @amrenderitems[i];
    if l.itemtype = GL_AM_LINE then
      gld_DrawAMLine(l)
    else if l.itemtype = GL_AM_QUAD then
      gld_DrawAMQuad(l)
    else if l.itemtype = GL_AM_TRIANGLE then
      gld_DrawAMTriangle(l)
    else if l.itemtype = GL_AM_PATCH then
      gld_DrawAMPatch(l);
  end;

  glEnable(GL_TEXTURE_2D);
  numamitems := 0;
end;

end.
