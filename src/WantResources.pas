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
  @abstract WANT resources and constants

  @author Juancarlo Añez
  @author Simon Gilli (http://want.gilbertsoft.org)
}
unit WantResources;

interface

uses
  Windows,
  Classes,
  SysUtils,
  JclSysUtils,
  JclFileUtils,
  JclStrings;

const
  SwitchChars = ['-', '/'];

resourcestring
  F_WantStartupFailed = 'Want startup failed';

  F_WantError   = '!!! %s !!!';
  F_TaskError   = '!!! %s !!!';
  F_TaskFailure = '%s';

  F_BuildStartMsg   = 'buildfile: %s';
  F_BuildDoneMsg    = 'Build complete.';
  F_BuildDoneMsgAnt = 'BUILD SUCCESSFUL';
  F_BuildFailedMsg  = 'BUILD FAILED';

  F_BuildFileNotFound         = 'Cannot find %s';
  F_BuildTargetUnhandledError = '%s: %s';
  F_BuildTargetNotFound       = 'target [%s] not found';

  F_TargetStartMsg = '--> %s';

  F_ExpectedTagError    = 'expected <%s>';
  F_ParseError          = '(%d): %s';
  F_ParseAttributeError = '(%d): Unknown attribute %s.%s';
  F_ParseChildError     = '(%d): Unknown element <%s><%s>';
  F_ParseChildTextError = '(%d): Element <%s> does not accept text';

  F_WantClassNotFound  = 'Want class <%s> not found';
  F_DuplicateWantClass = 'Duplicate Want tag <%s> in class <%s>';


function ConvertToBoolean(const AValue: string): boolean;

function Copyright: string;
function License: string;
procedure Usage;

function GetResourceString(const ResName: string; ResType: PChar = RT_RCDATA): string;

function WantVersion: string;

implementation

{$R usage.res}
{$R license.res}

const
  C_EOL = AnsiLineBreak;

  LICENSE_TEXT = 'LICENSE';
  USAGE_TEXT = 'USAGE';

var
  LWantVersion: string;

function WantVersion: string;
begin
  Result := LWantVersion;
end;

function ConvertToBoolean(const AValue: string): boolean;
var
  s: string;
begin
  s := LowerCase(Trim(aValue)) + ' ';

  case s[1] of
    'f': Result := False;
    'n': Result := False;
    '0': Result := False;
  else
    Result := True;
  end;
end;

function GetResourceString(const ResName: string; ResType: PChar): string;
var
  Res: TResourceStream;
  Str: TStringStream;
begin
  Res := TResourceStream.Create(HInstance, ResName, ResType);
  try
    Str := TStringStream.Create('');
    try
      Res.SaveToStream(Str);
      Result := Str.DataString;
    finally
      Str.Free;
    end;
  finally
    Res.Free;
  end;
end;

function Copyright: string;
begin
  Result :=
    'WANT - A Pascal-Friendly Build Tool - Version ' + WantVersion + C_EOL +
    'Copyright (C) 2001-2003  Juancarlo Anez, Caracas, Venezuela' + C_EOL +
    'Copyright (C) 2008-2013  Alexey Shumkin aka Zapped' + C_EOL +
    'Copyright (C) 2017       Simon Gilli, Gilbertsoft, Switzerland' + C_EOL +
    C_EOL +
    'This program comes with ABSOLUTELY NO WARRANTY; for details type ''show w''.' + C_EOL +
    'This is free software, and you are welcome to redistribute it' + C_EOL +
    'under certain conditions; type ''show c'' for details.' + C_EOL;
end;

function License: string;
begin
  try
    Result := GetResourceString(LICENSE_TEXT);
  except
    Result := Copyright;
  end;
end;

procedure Usage;
begin
  Writeln(GetResourceString(USAGE_TEXT));
end;

initialization
  LWantVersion := VersionFixedFileInfoString(GetModuleName(HInstance), vfFull, '?.?.?.?');;

end.

