unit i_debug;

interface

implementation

uses
  Windows;

procedure PatchCode(Address: Pointer; const NewCode; Size: Integer);
var
  OldProtect: DWORD;
begin
  if VirtualProtect(Address, Size, PAGE_EXECUTE_READWRITE, OldProtect) then 
  begin
    Move(NewCode, Address^, Size);
    FlushInstructionCache(GetCurrentProcess, Address, Size);
    VirtualProtect(Address, Size, OldProtect, @OldProtect);
  end;
end;

type
  PInstruction = ^TInstruction;
  TInstruction = packed record
    Opcode: Byte;
    Offset: Integer;
  end;

procedure RedirectProcedure(OldAddress, NewAddress: Pointer);
var
  NewCode: TInstruction;
begin
  NewCode.Opcode := $E9;//jump relative
  NewCode.Offset := NativeInt(NewAddress)-NativeInt(OldAddress)-SizeOf(NewCode);
  PatchCode(OldAddress, NewCode, SizeOf(NewCode));
end;

var
  NewMove_1_Exceptions: integer = 0;

procedure NewMove_1(const Source; var Dest; Count : Integer);
var
  sP, dP: ^byte;
  cnt: integer;
begin
  try
    sP := @Source;
    dP := @Dest;
    for cnt := 0 to Count - 1 do
    begin
      dP^ := sP^;
      inc(sP);
      inc(dP);
    end;
  except
    inc(NewMove_1_Exceptions);
  end;
end;

initialization
  RedirectProcedure(@Move, @NewMove_1);

end.
