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
  @abstract Delphi project file for minimal WANT

  @author Simon Gilli (http://want.gilbertsoft.org)
}
program want_min;

{$APPTYPE CONSOLE}

uses
  ShareMem,
  SysUtils,
  SysConst,
  WantMain,
  WantMinimalTasks in 'WantMinimalTasks.pas';

{$R wantver.res}

begin
  Run;
end.

