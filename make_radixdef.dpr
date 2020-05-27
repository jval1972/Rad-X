program make_radixdef;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes;

var
  fout: string;
  i: integer;
  sout: TStringList;

procedure AddFile(const fname: string);
var
  x, y: integer;
  sinp: TStringList;
  s1, s2: string;
begin
  sinp := TStringList.Create;
  try
    sinp.LoadFromFile(fname);
    for x := 0 to sinp.Count - 1 do
    begin
      s1 := sinp.Strings[x];
      s2 := '';
      for y := 1 to Length(s1) do
      begin
        if s1[y] = '''' then
          s2 := s2 + '''' + ''''
        else
          s2 := s2 + s1[y];
      end;
      sout.Add('    ''' + s2 + '''#13#10 +');
    end;
  finally
    sinp.Free;
  end;
end;

begin
  { TODO -oUser -cConsole Main : Insert code here }
  fout := '';
  for i := 0 to ParamCount - 2 do
    if UpperCase(ParamStr(i)) = '-O' then
      fout := ParamStr(i + 1);
  if fout = '' then
  begin
    writeln('Please specify the output file (-o filename)');
    halt(1);
  end;

  sout := TStringList.Create;
  for i := 0 to ParamCount - 2 do
    if UpperCase(ParamStr(i)) = '-I' then
      AddFile(ParamStr(i + 1));
  sout.Add('    '''';');
  sout.SaveToFile(fout);
  sout.Free;
end.
