(****************************************************************************
 * WANT - A Pascal-Friendly Build Tool.                                     *
 * Copyright (C) 2001-2003  Juancarlo Añez                                  *
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
    @abstract Want main unit

    @author Simon Gilli (http://want.gilbertsoft.org)
}
unit WantMain;

interface

{ Main procedure }
procedure Run;

implementation

uses
  ConsoleScriptRunner,
  WantClasses,
  SysUtils;

procedure Run;
var
  Runner: TConsoleScriptRunner;
begin
  try
    Runner := TConsoleScriptRunner.Create;
    try
      Runner.Execute;
    finally
      Runner.Free;
    end;
  except
    on E: EAbort do
    begin
      ExitCode := 0;
      Exit;
    end;
    on E: EWantException do
    begin
      ExitCode := 1;
      Exit;
    end;
    on E: Exception do
    begin
      Writeln(E.Message);
      ExitCode := 2;
      Exit;
    end;
  end;
end;

end.

