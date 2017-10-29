(****************************************************************************
 * WANT - A Pascal-Friendly Build Tool.                                     *
 * Copyright (C) 2001-2003  Juancarlo Añez                                  *
 * Copyright (C) 2008-2013  Alexey Shumkin aka Zapped                       *
 * Copyright (C) 2017       Simon Gilli                                     *
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
    @abstract Delphi project file for WANT

    @author Juancarlo Añez
    @author Simon Gilli (http://want.gilbertsoft.org)
}
program want;

{$R 'usage.res' 'usage.rc'}
{%File 'usage.txt'}

uses
  ShareMem,
  SysUtils,
  SysConst,
  WantMain in 'WantMain.pas',
  WantClasses in 'WantClasses.pas',
  WantResources in 'WantResources.pas',
  WantStandardTasks in 'tasks\WantStandardTasks.pas',
  WantUtils in 'WantUtils.pas',
  BuildListeners in 'BuildListeners.pas',
  ScriptRunner in 'ScriptRunner.pas',
  ScriptParser in 'lib\ScriptParser.pas',
  WildPaths in 'lib\WildPaths.pas',
  ConsoleListener in 'win32\ConsoleListener.pas',
  ConsoleScriptRunner in 'win32\ConsoleScriptRunner.pas',
  CRT32 in 'win32\CRT32.pas',
  FileListener in 'win32\FileListener.pas',
  MSXMLEngineImpl in 'win32\MSXMLEngineImpl.pas',
  Resources in 'win32\Resources.pas',
  WIN32 in 'win32\WIN32.pas',
  Win32Implementations in 'win32\Win32Implementations.pas',
  DefaultInputHandler in 'input\DefaultInputHandler.pas',
  InputHandler in 'input\InputHandler.pas',
  InputRequest in 'input\InputRequest.pas',
  MultipleChoiceInputRequest in 'input\MultipleChoiceInputRequest.pas',
  StandardElements in 'elements\StandardElements.pas',
  Attributes in 'elements\Attributes.pas',
  PatternSets in 'elements\PatternSets.pas',
  Properties in 'elements\Properties.pas',
  RegexpElements in 'elements\RegexpElements.pas',
  TimeElements in 'elements\TimeElements.pas',
  StandardTasks in 'tasks\StandardTasks.pas',
  CustomTasks in 'tasks\CustomTasks.pas',
  CVSTasks in 'tasks\CVSTasks.pas',
  DelphiTasks in 'tasks\DelphiTasks.pas',
  DUnitTasks in 'tasks\DUnitTasks.pas',
  EchoTasks in 'tasks\EchoTasks.pas',
  EditTasks in 'tasks\EditTasks.pas',
  EncodeDecodeTasks in 'tasks\EncodeDecodeTasks.pas',
  ExecTasks in 'tasks\ExecTasks.pas',
  FileEditLoadTasks in 'tasks\FileEditLoadTasks.pas',
  FileTasks in 'tasks\FileTasks.pas',
  FilterElements in 'elements\FilterElements.pas',
  GZipTasks in 'tasks\GZipTasks.pas',
  HashTasks in 'tasks\HashTasks.pas',
  IniFileTasks in 'tasks\IniFileTasks.pas',
  InnoSetupTasks in 'tasks\InnoSetupTasks.pas',
  InputTasks in 'tasks\InputTasks.pas',
  LoadFileTasks in 'tasks\LoadFileTasks.pas',
  LoggerTask in 'tasks\LoggerTask.pas',
  StyleTasks in 'tasks\StyleTasks.pas',
  SVNTasks in 'tasks\SVNTasks.pas',
  TempFileTasks in 'tasks\TempFileTasks.pas',
  WantTasks in 'tasks\WantTasks.pas',
  XmlPropertyTasks in 'tasks\XmlPropertyTasks.pas',
  ZipTasks in 'tasks\ZipTasks.pas';

{$APPTYPE CONSOLE}

{$r wantver.res}
{$r license.res }

begin
  Run;
end.

