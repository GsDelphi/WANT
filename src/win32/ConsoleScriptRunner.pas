(****************************************************************************
 * WANT - A Pascal-Friendly Build Tool.                                     *
 * Copyright (C) 2001-2003  Juancarlo Anez, Caracas, Venezuela              *
 * Copyright (C) 2008-2013  Alexey Shumkin aka Zapped                       *
 * Copyright (C) 2017       Simon Gilli, Gilbertsoft, Switzerland           *
 *                                                                          *
 * This program is free software: you can redistribute it and/or modify     *
 * it under the terms of the GNU General Public License as published by     *
 * the Free Software Foundation, either version 3 of the License, or        *
 * (at your option) any later version.                                      *
 *                                                                          *
 * This program is distributed in the hope that it will be useful,          *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            *
 * GNU General Public License for more details.                             *
 *                                                                          *
 * You should have received a copy of the GNU General Public License        *
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.    *
 ****************************************************************************)
{
  @abstract Script runner on windows

  @author Juancarlo Aсez
  @author Simon Gilli (http://want.gilbertsoft.org)
}
unit ConsoleScriptRunner;

interface

uses
  SysUtils,
  Classes,
  JclStrings,
  JalStrings,
  CRT32,
  WildPaths,
  WantUtils,
  WantClasses,
  WantResources,
  ConsoleListener,
  ScriptRunner;

const
  rcs_id: string = '#(@)$Id: ConsoleScriptRunner.pas 706 2003-05-14 22:13:46Z hippoman $';

type
  TConsoleScriptRunner = class(TScriptRunner)
  protected
    FBuildFile: string;
    FTargets:   TStringArray;

    procedure ParseCommandLine(Project: TProject); overload; virtual;
    function ParseArgument(Project: TProject; var N: integer;
      const Argument: string): boolean; virtual;
    function ParseOption(Project: TProject; var N: integer; Switch: string;
      CommandLine: TStringList): boolean; virtual;

    function GetUseColor: boolean;
    procedure SetUseColor(Value: boolean);
  public
    procedure ParseCommandLine(Project: TProject; CommandLine: TStringList);
      overload; virtual;
    procedure CreateListener; override;
    property UseColor: boolean Read GetUseColor Write SetUseColor;

    procedure Execute; virtual;
  end;

implementation

{ TConsoleScriptRunner }

procedure TConsoleScriptRunner.CreateListener;
begin
  FListener := TConsoleListener.Create;
end;

function TConsoleScriptRunner.GetUseColor: boolean;
begin
  Result := TConsoleListener(Listener).UseColor;
end;

procedure TConsoleScriptRunner.SetUseColor(Value: boolean);
begin
  TConsoleListener(Listener).UseColor := Value;
end;

procedure More(Text: string);
var
  S: TStrings;
  i: integer;
begin
  S := TStringList.Create;
  try
    S.Text := Text;
    i := 0;
    while i < S.Count do
    begin
      if (Pos('---', S[i]) <> 1) then
      begin
        Writeln(S[i]);
        Inc(i);
      end
      else
      begin
        Write(Format('-- More (%d%%) --'#13, [100 * (i + 2) div S.Count]));
        Inc(i);
        repeat
        until ReadKey in [' ', #13, #10, 'q'];
        writeln(#13' ': 70);
      end;
    end;
  finally
    S.Free;
  end;
end;

procedure TConsoleScriptRunner.Execute;
var
  Project: TProject;
begin
  Project := TProject.Create;
  try
    Project.Listener := Listener;
    ParseCommandLine(Project);
    Log(vlDebug, Format('WANT (v%s) started at %s',
      [WantVersion, FormatDateTime('yyyy-dd-mm hh:nn:ss', Now)]));
    if FBuildFile = '' then
      FBuildFile := FindBuildFile(True);
    LoadProject(Project, FBuildFile);
    Listener.BuildStarted;
    BuildProject(Project, FTargets);
    Listener.BuildFinished;
  finally
    FreeAndNil(Project);
  end;
end;

procedure TConsoleScriptRunner.ParseCommandLine(Project: TProject);
var
  i: integer;
  TSL: TStringList;
begin
  TSL := TStringList.Create;
  try
    for i := 1 to ParamCount do
      TSL.Add(ParamStr(i));
    ParseCommandLine(Project, TSL);
  finally
    FreeAndNil(TSL);
  end;
end;

function TConsoleScriptRunner.ParseArgument(Project: TProject;
  var N: integer; const Argument: string): boolean;
begin
  SetLength(FTargets, 1 + Length(FTargets));
  FTargets[High(FTargets)] := Argument;
  Result := True;
end;

function TConsoleScriptRunner.ParseOption(Project: TProject; var N: integer;
  Switch: string; CommandLine: TStringList): boolean;
var
  PropName: string;
  PropValue: string;
  EqPos: integer;

  function GetNextParam: string;
  begin
    Result := '';
    Inc(N);
    if N < CommandLine.Count then
      Result := CommandLine[N];
  end;

begin
  Result := True;
  if (Switch = 'h') or (Switch = 'H') or (Switch = '?') or (Switch = 'help') then
  begin
    WriteLn(Copyright);
    Usage;
    Abort;
  end
  else if (Switch = 'v') then
    if Listener.AntCompatibilityOn then
      Result := ParseOption(Project, N, 'verbose', CommandLine)
    else
      Result := ParseOption(Project, N, 'version', CommandLine)
  else if (Switch = 'version') or (Switch = '-version') then
  begin
    WriteLn(Copyright);
    Abort;
  end
  else if (Switch = 'L') then
  begin
    More(License);
    Abort;
  end
  else if (Switch = 'buildfile') or (Switch = 'b') or
    (((Switch = 'f') or (Switch = 'file')) and Listener.AntCompatibilityOn) then
    FBuildFile := ToPath(GetNextParam())
  else if Switch = 'verbose' then
    Listener.Level := vlVerbose
  else if Switch = 'ansi' then
    Listener.ANSI := True
  else if (Switch = 'is') or (Switch = '-ignore-scratch') then
    Listener.IgnoreScratch := True
  else if (Switch = 'debug') or ((Switch = 'd') and Listener.AntCompatibilityOn) then
  begin
    Listener.Level := vlDebug;
    Log(vlDebug, 'Parsing commandline');
  end
  else if Switch = 'log' then
  begin
    Switch := Trim(GetNextParam());
    // если следующий параметр - ключ
    if Copy(Switch, 1, 1) = '-' then
      Dec(N) // возвращаем счётчик параметров
    else
      Listener.LogFile := ToSystemPath(ToPath(Switch));
  end
  else if AnsiSameText('ant', Switch) or AnsiSameText('dsv', Switch) then
    Listener.AntCompatibilityOn := True
  else if (Switch = 'quiet') or (Switch = 'q') or (Switch = 'warnings') then
    Listener.Level := vlQuiet
  else if (Switch = 'n') then
    Project.NoChanges := True
  else if Switch = 'nocolor' then
    UseColor := False
  else if Copy(Switch, 1, 1) = 'D' then
  begin
    Delete(Switch, 1, 1);

    EqPos := Pos('=', Switch);

    if EqPos = 0 then
      EqPos := 1 + Length(Switch);

    PropName  := Copy(Switch, 1, EqPos - 1);
    PropValue := Copy(Switch, EqPos + 1, Length(Switch));

    PropValue := StrTrimQuotes(PropValue);

    Project.SetProperty(PropName, PropValue);
  end
  // unknown switches
  else if Listener.AntCompatibilityOn then
  begin
    if Switch = 'logger' then
      GetNextParam()
    else if (Switch = 'e') or (Switch = 'emacs') then
    else
      Result := False;
  end
  else
    Result := False;
end;

procedure TConsoleScriptRunner.ParseCommandLine(Project: TProject;
  CommandLine: TStringList);
var
  p: integer;
  Param: string;
begin
  try
    p := 0;
    while p < CommandLine.Count do
    begin
      Param := CommandLine.Strings[p];
      if Param[1] in SwitchChars then
      begin
        if not ParseOption(Project, p, Copy(Param, 2, Length(Param)), CommandLine) then
          raise EWantError.Create('Unknown commandline option: ' + Param);
      end
      else if not ParseArgument(Project, p, Param) then
        raise EWantError.Create('Don''t know what to do with argument : ' + Param);
      Inc(p);
    end;
  except
    on E: EAbort do
    begin
      raise;
    end;
    on E: Exception do
    begin
      Listener.BuildFailed(Project, E.Message);
      raise;
    end;
  end;
end;

end.

