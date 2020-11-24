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
//   Compress/Decompress utilities
//
//------------------------------------------------------------------------------
//  Site: https://sourceforge.net/projects/rad-x/
//------------------------------------------------------------------------------

{$I RAD.inc}

unit m_compress;

interface

function M_FastPack(Source, Target: Pointer; SourceSize: integer): integer; { Return TargetSize }
function M_FastUnPack(Source, Target: Pointer; SourceSize: integer): integer; {Return TargetSize }

function M_PackString(Source: string): string;
function M_UnPackString(Source: string): string;

function M_PackFile(SourceFileName, TargetFileName: string): boolean; { Return FALSE if IOError }
function M_UnPackFile(SourceFileName, TargetFileName: string): boolean; { Return FALSE if IOError }

implementation

uses
  d_delphi;

type
  LongType = record
    case Word of
      0: (Ptr: Pointer);
      1: (Long: integer);
      2: (Lo: Word;
          Hi: Word);
  end;

function FastPackSeg(Source, Target: Pointer; SourceSize: Word): Word;
begin
  asm
    push esi
    push edi
    push eax
    push ebx
    push ecx
    push edx

    cld
    xor  ecx, ecx
    mov  cx, SourceSize
    mov  edi, Target

    mov  esi, Source
    add  esi, ecx
    dec  esi
    lodsb
    inc  eax
    mov  [esi], al

    mov  ebx, edi
    add  ebx, ecx
    inc  ebx
    mov  esi, Source
    add  ecx, esi
    add  edi, 2
@CyclePack:
    cmp  ecx, esi
    je   @Konec
    lodsw
    stosb
    dec  esi
    cmp  al, ah
    jne  @CyclePack
    cmp  ax, [esi+1]
    jne  @CyclePack
    cmp  al, [esi+3]
    jne  @CyclePack
    sub  ebx, 2
    push edi
    sub  edi, Target
    mov  [ebx], di
    pop  edi
    mov  edx, esi
    add  esi, 3
@Nimnul:
    inc  esi
    cmp  al, [esi]
    je   @Nimnul
    mov  eax, esi
    sub  eax, edx
    or   ah, ah
    jz   @M256
    mov  byte ptr [edi], 0
    inc  edi
    stosw
    jmp  @CyclePack
@M256:
    stosb
    jmp  @CyclePack
@Konec:
    push ebx
    mov  ebx, Target
    mov  eax, edi
    sub  eax, ebx
    mov  [ebx], ax
    pop  ebx
    inc  ecx
    cmp  ebx, ecx
    je   @Lock1
    mov  esi, ebx
    sub  ebx, Target
    sub  ecx, Source
    sub  ecx, ebx
    rep  movsb
@Lock1:
    sub  edi, Target
    mov  Result, di

    pop     edx
    pop     ecx
    pop     ebx
    pop     eax
    pop     edi
    pop     esi
  end;
end;

function FastUnPackSeg(Source, Target: Pointer; SourceSize: Word): Word;
begin
  asm
    push esi
    push edi
    push eax
    push ebx
    push ecx
    push edx
    cld
    mov  esi, Source
    mov  edi, Target
    mov  ebx, esi
    xor  edx, edx
    mov  dx, SourceSize
    add  ebx, edx
    mov  dx, word ptr [esi]
    add  edx, esi
    add  esi, 2
@UnPackCycle:
    cmp  edx, ebx
    je   @Konec2
    sub  ebx, 2
    xor  ecx, ecx
    mov  cx, word ptr [ebx]
    add  ecx, Source
    sub  ecx, esi
    dec  ecx
    rep  movsb
    lodsb
    mov  cl, byte ptr [esi]
    inc  esi
    or   cl, cl
    jnz  @Low1
    xor  ecx, ecx
    mov  cx, word ptr [esi]
    add  esi, 2
@Low1:
    inc  ecx
    rep  stosb
    jmp  @UnPackCycle
@Konec2:
    mov  ecx, edx
    sub  ecx, esi
    rep  movsb
    sub  edi, Target
    mov  Result, di

    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    pop  edi
    pop  esi
  end;
end;

function M_FastPack(Source, Target: Pointer; SourceSize: integer): integer;
var
  w, tmp: Word;
  Sourc, Targ: LongType;
  t, s: Pointer;
begin
  t := malloc($FFFF);
  s := malloc($FFFF);
  Sourc.Ptr := Source;
  Targ.Ptr := Target;
  Result := 0;
  while SourceSize <> 0 do
  begin
    if SourceSize > $FFFA then
      tmp := $FFFA
    else
      tmp := SourceSize;
    dec(SourceSize, tmp);
    move(Sourc.Ptr^, s^, tmp);
    w := FastPackSeg(s, t, tmp);
    inc(Sourc.Long, tmp);
    Move(w, Targ.Ptr^, 2);
    inc(Targ.Long, 2);
    Move(t^, Targ.Ptr^, w);
    inc(Targ.Long, w);
    Result := Result + w + 2;
  end;
  memfree(t, $FFFF);
  memfree(s, $FFFF);
end;

function M_FastUnPack(Source, Target: Pointer; SourceSize: integer): integer;
var
  Increment, i: integer;
  tmp: Word;
  Swap: LongType;
  t: Pointer;
begin
  t := malloc($FFFF);
  Increment := 0;
  Result := 0;
  while SourceSize <> 0 do
  begin
    Swap.Ptr := Source;
    inc(Swap.Long, Increment);
    Move(Swap.Ptr^, tmp, 2);
    inc(Swap.Long, 2);
    dec(SourceSize, tmp + 2);
    i := FastUnPackSeg(Swap.Ptr, t, tmp);
    Swap.Ptr := Target;
    inc(Swap.Long, Result);
    inc(Result, i);
    Move(t^, Swap.Ptr^, i);
    inc(Increment, tmp + 2);
  end;
  memfree(t, $FFFF);
end;

function M_PackString(Source: string): string;
var
  PC, PC2: PChar;
  SS, TS: Integer;
begin
  SS := Length(Source);
  PC := malloc(SS);
  PC2 := malloc(SS + 8); // If line can't be packed its size can be longer
  Move(Source[1], PC^, SS);
  TS := M_FastPack(PC, PC2, SS);
  SetLength(Result, TS + 4);
  Move(SS, Result[1], 4);
  Move(PC2^, Result[5], TS);
  memfree(pointer(PC2), SS);
  memfree(pointer(PC), SS + 8);
end;


function M_UnPackString(Source: string): string;
var
  PC, PC2: PChar;
  SS, TS: Integer;
begin
  SS := Length(Source) - 4;
  PC := malloc(SS);
  Move(Source[1], TS, 4);
  PC2 := malloc(TS);
  Move(Source[5], PC^, SS);
  TS := M_FastUnPack(PC, PC2, SS);
  SetLength(Result, TS);
  Move(PC2^, Result[1], TS);
  memfree(pointer(PC2), TS);
  memfree(pointer(PC), SS);
end;

function M_PackFile(SourceFileName, TargetFileName: string): boolean; { Return FALSE if IOError }
var
  Source, Target: Pointer;
  SourceFile, TargetFile: file;
  RequiredMaxSize, TargetFSize, FSize: integer;
begin
  AssignFile(SourceFile, SourceFileName);
  Reset(SourceFile, 1);
  FSize := FileSize(SourceFile);

  RequiredMaxSize := FSize + (FSize div $FFFF + 1) * 2;
  Source := malloc(RequiredMaxSize);
  Target := malloc(RequiredMaxSize);

  BlockRead(SourceFile, Source^, FSize);
  CloseFile(SourceFile);

  TargetFSize := M_FastPack(Source, Target, FSize);

  AssignFile(TargetFile, TargetFileName);
  Rewrite(TargetFile, 1);
  { Also, you may put header }
  BlockWrite(TargetFile, FSize, SizeOf(FSize)); { Original file size (Only from 3.0) }
  BlockWrite(TargetFile, Target^, TargetFSize);
  CloseFile(TargetFile);

  memfree(Target, RequiredMaxSize);
  memfree(Source, RequiredMaxSize);

  Result := IOResult = 0;
end;

function M_UnPackFile(SourceFileName, TargetFileName: string): boolean; { Return FALSE if IOError }
var
  Source, Target: Pointer;
  SourceFile, TargetFile: file;
  OriginalFileSize, FSize: integer;
begin
  AssignFile(SourceFile, SourceFileName);
  Reset(SourceFile, 1);
  FSize := FileSize(SourceFile) - SizeOf(OriginalFileSize);

  { Read header ? }
  BlockRead(SourceFile, OriginalFileSize, SizeOf(OriginalFileSize));

  Source := malloc(FSize);
  Target := malloc(OriginalFileSize);

  BlockRead(SourceFile, Source^, FSize);
  CloseFile(SourceFile);

  M_FastUnPack(Source, Target, FSize);

  AssignFile(TargetFile, TargetFileName);
  Rewrite(TargetFile, 1);
  BlockWrite(TargetFile, Target^, OriginalFileSize);
  CloseFile(TargetFile);

  memfree(Target, OriginalFileSize);
  memfree(Source, FSize);

  Result := IOResult = 0;
end;

end.

