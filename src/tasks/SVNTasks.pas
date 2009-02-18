(****************************************************************************
 * WANT - A build management tool.                                          *
 * Copyright (c) 2001-2003 Juancarlo Anez, Caracas, Venezuela.              *
 * All rights reserved.                                                     *
 *                                                                          *
 * This library is free software; you can redistribute it and/or            *
 * modify it under the terms of the GNU Lesser General Public               *
 * License as published by the Free Software Foundation; either             *
 * version 2.1 of the License, or (at your option) any later version.       *
 *                                                                          *
 * This library is distributed in the hope that it will be useful,          *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU        *
 * Lesser General Public License for more details.                          *
 *                                                                          *
 * You should have received a copy of the GNU Lesser General Public         *
 * License along with this library; if not, write to the Free Software      *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA *
 ****************************************************************************)
{
    @brief SVN tasks

    @author ������ ������� aka Zapped
}

{ Notes:
    Code idea (and fragments) are taken from CVSTasks

    Cvs             attributes "error" and "append" are not implemented.
                    attributes "passfile" and "port" are not implemented too,
                    because CVSNT does not use these environment variables
                    (http://ant.apache.org/manual/CoreTasks/cvs.html)
    CvsTagDiff      attribute  "rootdir" is not implemented
                    (http://ant.apache.org/manual/CoreTasks/cvstagdiff.html)
    CvsPass         Added property emptypassword for login to CVS servers without
                    password specified (for example sourceforge CVS).
                    Only acceptable value for "emptypassword" is "true".
                    if CVSNT is used, default password file is not regular
                    file, but passwords are stored in Windows registry key
                    HKEY_CURRENT_USER/Software/Cvsnt/cvspass
                    This task (on MsWindows) is trying to write password to
                    registry and when it fails, then write password
                    to $HOME/.cvspass
                    On Linux it tries only $HOME/.cvspass
                    (http://ant.apache.org/manual/CoreTasks/cvspass.html)
    CvsChangeLog    Added two properties - dateformat and timeformat
                    These properties are used to format date or time written
                    into changelog (XML file). Default: yyyy-mm-dd and hh:mm
                    Format string is compatible with Delphi date-time format
                    string (see "Date-Time values, formatting" in Delphi help)
                    (http://ant.apache.org/manual/CoreTasks/changelog.html)

}

unit SVNTasks;

interface

{$IFDEF VER130}
{$DEFINE MSWINDOWS}
{$ENDIF VER130}

uses
  SysUtils,
  SysConst,
  Classes,
{$IFNDEF VER130}
  DateUtils,
{$ENDIF VER130}

  {$IFDEF MSWINDOWS}
  JclRegistry,
  Windows,
  {$ENDIF}
  JclSysInfo,
  JclFileUtils,
  JclShell,
  JclStrings,

  OTRPerlRE,

  IniFiles, {Hashed stringlist}
  Contnrs, {TObjectList}
  WildPaths,
  ExecTasks,
  WantClasses,
  Properties,
  CVSTasks,
  TempFileTasks,
  PatternSets,

  uSVNObjects;

type
  TFilterPathFunction = function (const Path, Status: string): boolean of object;

  // property for SVNLastRevision entity
  TSubPropertyElement = class(TPropertyElement)
  public
    procedure Init; override;

    class function TagName :string; override;

    property path;
    property _file;
    property section;
  end;

  // authorization entity
  TSVNAuthTask = class(TTask)
  private
    function GetPassword: string;
    function GetUser: string;
    procedure SetPassword(const Value: string);
    procedure SetUser(const Value: string);
  public
    procedure Init; override;
  published
    property user: string read GetUser write SetUser;
    property password: string read GetPassword write SetPassword;
  end;

  // basic class for SVN operations
  TCustomSVNTask = class(TCustomExecTask)
  private
    FCommand: string;
    FDest: string;
    Frepo: TPath;
    Fbranches: TPath;
    Ftrunk: TPath;
    Ftags: TPath;
    FExecOutput: TStringList;
    FOutputIsUTF8: boolean;
    FConvertSVNOutput: boolean;
    FIncrementalOutput: boolean;
    Frevision: string;
    function GetRepo: TPath; virtual;
    function ExTURLD(const Value: string): string;
    function InTURLD(const Value: string): string;
    function EncodeURL(Value: string): string;
    function DecodeURL(Value: string): string;
    function GetRepoPath(const pRepo, pPath: string): string;
    function MoveURL(const pPath, pFromBase: string;
      const pToBase: string = ''): string;
    function Getbranches: TPath; virtual;
    function Gettags: TPath; virtual;
    function Gettrunk: TPath; virtual;
    procedure DoRevision;
  protected
    function BuildArguments: string; override;

    procedure BuildArgumentsGlobal; virtual;
    procedure BuildArgumentsCommand; virtual;
    procedure BuildArgumentsSpecific; virtual;
    procedure DoFirstArgument; virtual;
    procedure DoNextArguments; virtual;
    procedure HandleOutputLine(Line :string); override;
    function DoConvertOutputLineHandle(const Line: string): string; virtual;
    function ConvertOutputLineHandle(const Line: string): string;
    procedure DoParseOutput; virtual;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor Destroy; override;

    procedure Execute; override;

    property ConvertSVNOutput: boolean read FConvertSVNOutput write FConvertSVNOutput;
    property IncrementalOutput: boolean read FIncrementalOutput write FIncrementalOutput;
    property OutputIsUTF8: boolean read FOutputIsUTF8 write FOutputIsUTF8;

    property quiet;
    property branches: TPath read Getbranches write Fbranches;
    property command: string read FCommand write FCommand;
    property dest: string read FDest write FDest;
    property repo: TPath read GetRepo write Frepo;
    property revision: string read Frevision write Frevision;
    property tags: TPath read Gettags write Ftags;
    property trunk: TPath read Gettrunk write Ftrunk;
  published
  end;

  // svn any command
  TSVNTask = class(TCustomSVNTask)
  public
    procedure Execute; override;
    procedure BuildArgumentsCommand; override;
  published
    property output;
    property failonerror;
    property Arguments;
    property ArgumentList stored False;

    property quiet;
    property branches;
    property command;
    property dest;
    property repo;
    property revision;
    property tags;
    property trunk;
  end;

  // class for retrieving N-th last revision from /tags
  TSVNLastRevisionTask = class(TCustomSVNTask)
  private
    Flast: Integer;
    FLastRevision: string;
    Ffullpath: boolean;
    function GetRepo: TPath; override;
    procedure SetLastRevision(const Value: string);
  protected
    procedure DoParseOutput; override;
  public
    constructor Create(Owner: TScriptElement); override;
    procedure Execute; override;
    procedure Init; override;

    property LastRevision: string read FLastRevision write SetLastRevision;
  published
    function CreateProperty: TSubPropertyElement;
    property fullpath: boolean read Ffullpath write Ffullpath;
    property last: Integer read Flast write Flast;

    property output;
    property failonerror;

    property quiet;
    property repo;
    property tags;
  end;

  // class for getting info about SVN-files
  TSVNInfoTask = class(TCustomSVNTask)
  private
    FFiles: TStringList;
    FInfo: TSVNInfoInfo;
    FCurrentItemIndex: Integer;
    function GetItems(Index: Integer): TSVNInfoEntry;
    function GetItemsCount: Integer;
  protected
    procedure DoFirstArgument; override;
    procedure DoNextArguments; override;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor Destroy; override;
    procedure Execute; override;
    procedure Execute_(Incremental: boolean);
    function AddItem(const pItem: string): Integer;

    property CurrentItemIndex: Integer read FCurrentItemIndex write FCurrentItemIndex;
    property ItemsCount: Integer read GetItemsCount;
    property Items[Index: Integer]: TSVNInfoEntry read GetItems;
  end;

  // class for getting status info about SVN-files
  TSVNStatusTask = class(TCustomSVNTask)
  private
    FStatus: TSVNInfoStatus;
    Fverbose: boolean;
    function GetItems(Index: Integer): TSVNInfoEntry;
    function GetItemsCount: Integer;
    function GetItemsUnVersioned(Index: Integer): TSVNInfoEntry;
    function GetItemsUnVersionedCount: Integer;
  protected
    procedure DoFirstArgument; override;
    procedure DoParseOutput; override;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor Destroy; override;

    property ItemsCount: Integer read GetItemsCount;
    property Items[Index: Integer]: TSVNInfoEntry read GetItems;
    property ItemsUnVersionedCount: Integer read GetItemsUnVersionedCount;
    property ItemsUnVersioned[Index: Integer]: TSVNInfoEntry read GetItemsUnVersioned;
  published
    property dest;
    property verbose: boolean read Fverbose write Fverbose;
  end;

  // class for retrieving SVN-file/folder
  TSVNGetFileTask = class(TCustomSVNTask)
  private
    FFileInfo: TSVNInfoEntry;
    Ffilesonly: boolean;
    function GetFileName: string;
  protected
    procedure DoFirstArgument; override;
    procedure DoNextArguments; override;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor Destroy; override;
    procedure Execute; override;
    procedure SetFileInfo(RepoBase: string; pFileInfo: TSVNInfoEntry);

    property FileName: string read GetFileName;
    property filesonly: boolean read Ffilesonly write Ffilesonly;
  end;

  // class for retrieving files/folders changed between two branches/tags/trunk
  TSVNDiffTask = class(TCustomSVNTask)
  private
    Flast: Integer;
    Finclude: string;
    Ffilesonly: boolean;
    Flist: string;
    Freleases: string;
    Freleases_re: string;
    Freleases_prefix: string;
    FLastRevisionTask: TSVNLastRevisionTask;
    FStatuses: TStringList;
    FInfoTask: TSVNInfoTask;
    Finc_info: boolean;
    Fnames: string;
    Ffolders: string;
    Fcleandest: boolean;
    function GetFolders: string;
    procedure SetFolders(const Value: string);
    function GetNames: string;
    procedure SetNames(const Value: string);
    procedure SetReleases(const Value: string);
    procedure SetReleases_re(const Value: string);
  protected
    procedure DoFirstArgument; override;
    procedure DoNextArguments; override;
    procedure BuildArgumentsGlobal; override;
    procedure DoParseOutput; override;
    procedure DoInclude;
    procedure FilterPaths;
    function FilterPathsByStatus(const Path, Status: string): boolean;
    function FilterPathsByNames(const Path, Status: string): boolean;
    function FilterPathsByFolders(const Path, Status: string): boolean;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor Destroy; override;
    procedure Execute; override;

    procedure GetInfos;
    procedure SaveFiles;
    procedure CleanDestination;

    // is there reason to do <cleandest> property published? I don't think so
    property cleandest: boolean read Fcleandest write Fcleandest;
  published
    property filesonly: boolean read Ffilesonly write Ffilesonly;
    property folders: string read GetFolders write SetFolders;
    property include: string read Finclude write Finclude;
    property inc_info: boolean read Finc_info write Finc_info;
    property last: Integer read Flast write Flast;
    property list: string read Flist write Flist;
    property names: string read GetNames write SetNames;
    property releases: string read Freleases write SetReleases;
    property releases_re: string read Freleases_re write SetReleases_re;
    property releases_prefix: string read Freleases_prefix write freleases_prefix;

    property output;
    property failonerror;

    property quiet;
    property dest;
    property repo;
    property tags;
    property trunk;
  end;

  TIncludeFilesElement = class(TCustomFileSet);

  // class for adding files to WC (working copy)
  TSVNAddTask = class(TCustomSVNTask)
  private
    FIncludeFiles: TIncludeFilesElement;
  protected
    procedure DoFirstArgument; override;
    procedure DoNextArguments; override;
    procedure AddIncludes; virtual;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor Destroy; override;
    procedure Init; override;
    procedure Execute; override;
    property IncludeFiles: TIncludeFilesElement read FIncludeFiles;
  published
    function CreateIncludeFiles: TIncludeFilesElement;
    property dest;
  end;

  // class for adding and committing files to SVN
  TSVNCommitTask = class(TCustomSVNTask)
  private
    FMessageFileName: string;
    Fmessage: string;
    FIncludeFiles: TIncludeFilesElement;
    Fall: boolean;
    function GetMessageFile: string;
  protected
    procedure DoFirstArgument; override;
    procedure DoNextArguments; override;
    procedure AddIncludes; virtual;
    procedure PrepareNonVersioned;

    property MessageFile: string read GetMessageFile;
    property IncludeFiles: TIncludeFilesElement read FIncludeFiles;
  public
    constructor Create(Owner: TScriptElement); override;
    destructor Destroy; override;
    procedure Init; override;
    procedure Execute; override;
  published
    function CreateIncludeFiles: TIncludeFilesElement;
    property dest;
    property _message: string read Fmessage write Fmessage;
    property all: boolean read Fall write Fall;
  end;

const
  URLDelimiter = '/';
  // regexp for parsing "svn diff --summarize" output
  StatusParseRE = '^\s*(\w+)\s+(.+)';

implementation

uses RTLConsts, TypInfo,
  JALOwnedTrees,
  StrNatCmp, uProps, uConsole;

var
  SVNUser, SVNPassword: string;

{ TCustomSVNTask }

function TCustomSVNTask.BuildArguments: string;
begin
  BuildArgumentsCommand;
  BuildArgumentsSpecific;
  BuildArgumentsGlobal;

  Result := inherited BuildArguments;
end;

procedure TCustomSVNTask.BuildArgumentsCommand;
begin
//  Log(vlVerbose, 'command=' + FCommand);
  ArgumentList.AddValue(FCommand);
end;

procedure TCustomSVNTask.BuildArgumentsGlobal;
begin
  if SVNUser <> '' then
    ArgumentList.AddOption('--username=', SVNUser);

  if SVNPassword <> '' then
    ArgumentList.AddOption('--password=', SVNPassword);

  ArgumentList.AddOption('--no-auth-cache');
  ArgumentList.AddOption('--non-interactive');
end;

procedure TCustomSVNTask.BuildArgumentsSpecific;
begin
  DoFirstArgument;
  DoRevision;
  DoNextArguments;
end;

constructor TCustomSVNTask.Create(Owner: TScriptElement);
begin
  inherited;
  ConvertSVNOutput := True;
  FConvertOutput := False;
  quiet := True;
  {$IFDEF LINUX}
  Executable := 'svn';
  {$ELSE}
  Executable := 'svn.exe';
  {$ENDIF}
  FExecOutput := TStringList.Create;
end;

destructor TCustomSVNTask.Destroy;
begin
  FreeAndNil(FExecOutput);
  inherited;
end;

procedure TCustomSVNTask.DoFirstArgument;
begin
  if repo <> '' then
  begin
    Log(vlVerbose, 'repo=' + repo);
    ArgumentList.AddValue(repo);
  end;
end;

procedure TCustomSVNTask.DoNextArguments;
begin
  if FDest <> '' then
  begin
    Log(vlVerbose, 'dest=' + ToSystemPath(FDest));
    ArgumentList.AddValue(ToSystemPath(FDest));
  end;
end;

function TCustomSVNTask.ExTURLD(const Value: string): string;
begin
  Result := Trim(Value);
  if Result = '' then
    Exit;
  if Result[Length(Result)] = URLDelimiter then
    Result := Copy(Result, 1, Length(Result) - 1);
end;

function TCustomSVNTask.GetRepo: TPath;
begin
  Result := Frepo;
end;

procedure TCustomSVNTask.HandleOutputLine(Line: string);
begin
  FExecOutput.Add(ConvertOutputLineHandle(Line));
  inherited;
end;

function TCustomSVNTask.InTURLD(const Value: string): string;
begin
  Result := Trim(Value);
  if Result = '' then
    Exit;
  if Result[Length(Result)] <> URLDelimiter then
    Result := Result + URLDelimiter;
end;

function TCustomSVNTask.DecodeURL(Value: string): string;
// function implementation copied from the unit IdURI
// class function TIdURI.URLDecode;
var
  i: integer;
  ESC: string[2];
  CharCode: integer;
begin
  Result := '';    {Do not Localize}
  Value := StringReplace(Value, '+', ' ', [rfReplaceAll]);  {do not localize}
  i := 1;
  while i <= Length(Value) do
  begin
    if Value[i] <> '%' then {do not localize}
      Result := Result + Value[i]
    else
    begin
      Inc(i); // skip the % char
      ESC := Copy(Value, i, 2); // Copy the escape code
      Inc(i, 1); // Then skip it.
      try
        CharCode := StrToInt('$' + ESC);  {do not localize}
        if (CharCode > 0) and (CharCode < 256) then
          Result := Result + Char(CharCode);
      except
      end;
    end;
    Inc(i);
  end;
end;

procedure TCustomSVNTask.DoParseOutput;
begin
// do nothing
end;

procedure TCustomSVNTask.Execute;
begin
  ArgumentList.Clear;
  if not IncrementalOutput then
    FExecOutput.Clear;
  inherited;
  DoParseOutput;
end;

function TCustomSVNTask.GetRepoPath(const pRepo, pPath: string): string;
begin
  // returns path of pPath relative to pRepo if it is begun with /
  // otherwise pPath
  if pPath <> '' then
    if Pos(URLDelimiter, pPath) = 1 then
      Result := ExTURLD(pRepo) + pPath
    else
      Result := pPath
  else
    Result := pRepo;
end;

function TCustomSVNTask.EncodeURL(Value: string): string;
// function implementation copied from the unit IdURI
// class function TIdURI.PathEncode
const
  UnsafeChars = ['*', '#', '%', '<', '>', '+', ' '];  {do not localize}
var
  i: Integer;
begin
  Result := '';    {Do not Localize}
  for i := 1 to Length(Value) do
  begin
    if (Value[i] in UnsafeChars) or (Value[i] >= #$80) or (Value[1] < #32) then
      Result := Result + '%' + IntToHex(Ord(Value[i]), 2)  {do not localize}
    else
      Result := Result + Value[i];
  end;
end;

function TCustomSVNTask.MoveURL(const pPath, pFromBase: string;
  const pToBase: string = ''): string;
begin
  // delete base path
  Result :=  StringReplace(pPath, pFromBase, '', [rfIgnoreCase]);
  if (Result <> '') and (Result[1] = URLDelimiter) then
    Delete(Result, 1, 1);
  // change base path to a new one
  Result := InTURLD(pToBase) + Result;
  if (Result <> '') and (Result[1] = URLDelimiter) then
    Delete(Result, 1, 1);
end;

function TCustomSVNTask.Getbranches: TPath;
begin
  Result := GetRepoPath(Frepo, Fbranches);
end;

function TCustomSVNTask.Gettags: TPath;
begin
  Result := GetRepoPath(Frepo, Ftags);
end;

function TCustomSVNTask.Gettrunk: TPath;
begin
  Result := GetRepoPath(Frepo, Ftrunk);
end;

procedure TCustomSVNTask.DoRevision;
begin
  if Frevision <> '' then
  begin
    Log(vlVerbose, 'Revision=%s', [Frevision]);
    ArgumentList.AddOption('-r ', Frevision);
  end;
end;

function TCustomSVNTask.ConvertOutputLineHandle(const Line: string): string;
begin
  Result := Line;
  if ConvertSVNOutput then
    Result := DoConvertOutputLineHandle(Result);
  if OutputIsUTF8 then
    Result := Utf8ToAnsi(Result);
end;

function TCustomSVNTask.DoConvertOutputLineHandle(
  const Line: string): string;
begin
  Result := ConvertOemToAnsi(Line);
  // trick for SVN which outputs non-latin symbols URL-encoded
  // when they are in the repo path only, but not in a trunk/tag/file-path
  if OutputIsUTF8 then
    Result := AnsiToUtf8(Result);
  Result := DecodeURL(Result);
end;

{ TSVNTask }

procedure TSVNTask.BuildArgumentsCommand;
begin
  if FCommand = '' then
    FCommand := 'checkout';
  inherited;
end;

procedure TSVNTask.Execute;
var
  bOldDir: TPath;
begin
  bOldDir := CurrentDir;
  if FDest <> '' then
  begin
//    ChangeDir(FDest, True);
  end;
  inherited;
  ChangeDir(bOldDir);
end;

{ TSVNAuthTask }

function TSVNAuthTask.GetPassword: string;
begin
  Result := SVNPassword;
end;

function TSVNAuthTask.GetUser: string;
begin
  Result := SVNUser;
end;

procedure TSVNAuthTask.Init;
begin
  inherited;
  RequireAttribute('user');
end;

procedure TSVNAuthTask.SetPassword(const Value: string);
begin
  SVNPassword := Value;
  Log(vlVerbose, 'password=' + SVNPassword);
end;

procedure TSVNAuthTask.SetUser(const Value: string);
begin
  SVNUser := Value;
  Log(vlVerbose, 'username=' + SVNUser);
end;

{ TSVNDiffTask }

procedure TSVNDiffTask.BuildArgumentsGlobal;
begin
  inherited;
  ArgumentList.AddOption('--summarize');
  ArgumentList.AddOption('--no-diff-deleted');
end;

procedure TSVNDiffTask.CleanDestination;
begin
  if not cleandest then
    Exit;
  Log(vlVerbose, 'Cleaning destination folder');
  SHDeleteFiles(0,
    IncludeTrailingPathDelimiter(ToSystemPathInherited(dest)) + '*.*',
    [doSilent]);
end;

constructor TSVNDiffTask.Create(Owner: TScriptElement);
begin
  inherited;
  command := 'diff';
  OutputIsUTF8 := True;
  cleandest := True;
  FLastRevisionTask := TSVNLastRevisionTask.Create(Self);
  FStatuses := TStringList.Create;
  FInfoTask := TSVNInfoTask.Create(Self);
  FInfoTask.OutputIsUTF8 := True;
end;

destructor TSVNDiffTask.Destroy;
begin
  FreeAndNil(FLastRevisionTask);
  FreeAndNil(FStatuses);
  FreeAndNil(FInfoTask);
  inherited;
end;

procedure TSVNDiffTask.DoFirstArgument;
begin
  ArgumentList.AddValue(FLastRevisionTask.LastRevision);
end;

procedure TSVNDiffTask.DoInclude;
var
  TSL: TStringList;
  i: Integer;
begin
  TSL := TStringList.Create;
  try
    ExtractStrings([';'], [], PAnsiChar(finclude), TSL);
    for i := 0 to TSL.Count - 1 do
      FStatuses.Values[MoveURL(TSL.Strings[i], '',
        FLastRevisionTask.LastRevision)] := 'M';
  finally
    FreeAndNil(TSL);
  end;
end;

procedure TSVNDiffTask.DoNextArguments;
begin
  ArgumentList.AddValue(GetRepoPath(repo, trunk));
end;

procedure TSVNDiffTask.DoParseOutput;
var
  i: Integer;
begin
  inherited;
  FStatuses.Clear;
  for i := 0 to FExecOutput.Count - 1 do
    if OTRPerlRE.regex.ExMatch(StatusParseRE, FExecOutput.Strings[i]) then
      FStatuses.Values[OTRPerlRE.regex.SubExp[2]] := OTRPerlRE.regex.SubExp[1];
  FilterPaths;
end;

procedure TSVNDiffTask.Execute;
var
  s: WideString;
begin
  Log(vlNormal, 'Getting diff');
//  FLastRevisionTask.Assign(Self);
  FLastRevisionTask.repo := frepo;
  FLastRevisionTask.tags := ftags;
  FLastRevisionTask.last := last;
  FLastRevisionTask.fullpath := True;
  FLastRevisionTask.Execute;
  inherited;
  DoInclude;
  GetInfos;
  CleanDestination;
  SaveFiles;
end;

procedure TSVNDiffTask.FilterPaths;
var
  i: Integer;
begin
  i := 0;
  while i < FStatuses.Count do
  begin
    // check functions return True if path is NOT filtered
    if FilterPathsByStatus(FStatuses.Names[i],
          FStatuses.ValueFromIndex[i])
        and FilterPathsByFolders(FStatuses.Names[i],
          FStatuses.ValueFromIndex[i])
        and FilterPathsByNames(FStatuses.Names[i],
          FStatuses.ValueFromIndex[i]) then
      Inc(i)
    else
      FStatuses.Delete(i);
  end;
end;

function TSVNDiffTask.FilterPathsByFolders(const Path,
  Status: string): boolean;
var
  s: string;
begin
  s := Copy(Path, Length(tags) + 1, Length(Path));
  Result := OTRPerlRE.Match(Folders, s);
end;

function TSVNDiffTask.FilterPathsByNames(const Path,
  Status: string): boolean;
var
  s: string;
begin
  s := Copy(Path, Length(tags) + 1, Length(Path));
  Result := OTRPerlRE.Match(Names, s);
end;

function TSVNDiffTask.FilterPathsByStatus(const Path,
  Status: string): boolean;
begin
  Result := Status <> 'D';
end;

function TSVNDiffTask.GetFolders: string;
begin
  Result := Ffolders;
end;

procedure TSVNDiffTask.GetInfos;
var
  i: Integer;
begin
  if FStatuses.Count = 0 then
    Exit;
  for i := 0 to FStatuses.Count - 1 do
    FInfoTask.AddItem(MoveURL(FStatuses.Names[i],
      FLastRevisionTask.LastRevision, GetRepoPath(repo, trunk)));
  FInfoTask.Execute_(inc_info);
end;

function TSVNDiffTask.GetNames: string;
begin
  Result := Fnames;
end;

procedure TSVNDiffTask.SaveFiles;
var
  i: Integer;
  TGFT: TSVNGetFileTask;
begin
  TGFT := TSVNGetFileTask.Create(Self);
  try
    TGFT.dest := dest;
    TGFT.filesonly := filesonly;
    for i := 0 to FInfoTask.ItemsCount - 1 do
    begin
      TGFT.SetFileInfo(GetRepoPath(repo, trunk), FInfoTask.Items[i]);
      TGFT.Execute;
    end;
  finally
    FreeAndNil(TGFT);
  end;
end;

procedure TSVNDiffTask.SetFolders(const Value: string);
begin
  Ffolders := Value;
end;

procedure TSVNDiffTask.SetNames(const Value: string);
begin
  Fnames := Value;
end;

procedure TSVNDiffTask.SetReleases(const Value: string);
begin
  Freleases := Value;
end;

procedure TSVNDiffTask.SetReleases_re(const Value: string);
begin
  Freleases_re := Value;
end;

{ TSVNLastRevisionTask }

constructor TSVNLastRevisionTask.Create(Owner: TScriptElement);
begin
  inherited;
  command := 'list';
  last := 0;
end;

function TSVNLastRevisionTask.CreateProperty: TSubPropertyElement;
begin
  Result := TSubPropertyElement.Create(Self);
end;

procedure TSVNLastRevisionTask.DoParseOutput;
var
  i: Integer;
begin
  inherited;
  FExecOutput.Text := Trim(FExecOutput.Text);
  if FExecOutput.Text <> '' then
  begin
    InvertCompare_NaturalSort := True;
    FExecOutput.CustomSort(Compare_NaturalSort);
    if last > FExecOutput.Count - 1 then
      TaskError(Format('<last> parameter (%d) is greater then revisions count (%d)',
        [last, FExecOutput.Count]));
    LastRevision := ExTURLD(FExecOutput.Strings[last]);
    for i := 0 to ChildCount - 1 do
      if Children[i] is TSubPropertyElement then
        Project.SetProperty(TSubPropertyElement(Children[i]).name,
          LastRevision, TSubPropertyElement(Children[i]).overwrite);
  end
  else
    TaskError('There are no any revision');
end;

procedure TSVNLastRevisionTask.Execute;
begin
  Log(vlNormal, 'Getting revisions from tags');
  inherited;
end;

function TSVNLastRevisionTask.GetRepo: TPath;
begin
  Result := tags;
end;

procedure TSVNLastRevisionTask.Init;
begin
  inherited;
  if last < 0 then
    WantError('<last> parameter must be greater than 0');
end;

procedure TSVNLastRevisionTask.SetLastRevision(const Value: string);
begin
  if fullpath then
  begin
    Log(vlDebug, 'fullpath is on');
    FLastRevision := InTURLD(repo) + Value;
  end
  else
    FLastRevision := Value;
  Log(vlNormal, 'LastRevision=' + LastRevision);
end;

{ TSubPropertyElement }

procedure TSubPropertyElement.Init;
begin
  RequireAttribute('name');
end;

class function TSubPropertyElement.TagName: string;
begin
  Result := 'property';
end;

{ TSVNInfoTask }

function TSVNInfoTask.AddItem(const pItem: string): Integer;
begin
  Result := FFiles.Add(pItem); 
end;

constructor TSVNInfoTask.Create(Owner: TScriptElement);
begin
  inherited;
  command := 'info';
  FFiles := TStringList.Create;
  CurrentItemIndex := -1;
end;

destructor TSVNInfoTask.Destroy;
begin
  FreeAndNil(FFiles);
  FreeAndNil(FInfo);
  inherited;
end;

procedure TSVNInfoTask.DoFirstArgument;
begin
  ArgumentList.AddOption('--xml');
end;

procedure TSVNInfoTask.DoNextArguments;
var
  i: Integer;
begin
  // if incremental add current item
  if CurrentItemIndex <> -1 then
  begin
    ArgumentList.AddOption('--incremental');
    ArgumentList.AddValue(FFiles.Strings[CurrentItemIndex]);
  end
  else
  // if all add all
    for i := 0 to FFiles.Count - 1 do
      ArgumentList.AddValue(FFiles.Strings[i]);
end;

procedure TSVNInfoTask.Execute;
var
  i: Integer;
begin
  if FFiles.Count = 0 then
    TaskError('There are no files for info');
  Log(vlNormal, 'Getting info');
  inherited;
end;

procedure TSVNInfoTask.Execute_(Incremental: boolean);
var
  i: Integer;
begin
  IncrementalOutput := Incremental;
  if not Incremental then
    Execute
  else
  begin
    for i := 0 to FFiles.Count - 1 do
    begin
      CurrentItemIndex := i;
      Execute;
    end;
    FExecOutput.Insert(0, '<info>');
    FExecOutput.Add('</info>');
  end;
  FInfo := TSVNInfoInfo.CreateByContext(FExecOutput.Text);
end;

function TSVNInfoTask.GetItems(Index: Integer): TSVNInfoEntry;
begin
  Result := FInfo.Entries[Index];
end;

function TSVNInfoTask.GetItemsCount: Integer;
begin
  Result := 0;
  if Assigned(FInfo) then
    Result := FInfo.Count;
end;

{ TSVNGetFile }

constructor TSVNGetFileTask.Create(Owner: TScriptElement);
begin
  inherited;
  command := 'cat';
  ConvertSVNOutput := False;
end;

destructor TSVNGetFileTask.Destroy;
begin
  FreeAndNil(FFileInfo);
  inherited;
end;

procedure TSVNGetFileTask.DoFirstArgument;
begin
  ArgumentList.AddValue(FFileInfo.URL);
end;

procedure TSVNGetFileTask.DoNextArguments;
begin
end;

procedure TSVNGetFileTask.Execute;
var
  s: string;
begin
  // change path of a previous revision to the latest one
  s := MoveURL(FFileInfo.URL, repo);
  // avoid getting quoted path which has spaces
  s := ToSystemPathInherited(s, dest);
  if filesonly then
  begin
    s := ExtractFileName(s);
    s := ToSystemPathInherited(MovePath(s, '', dest));
  end;           
  if not FFileInfo.IsFile then
  begin
    if filesonly then
      Log(vlVerbose, 'Ignoring creating dir due to settings')
    else
    begin
      Log(vlNormal, Format('Creating dir "%s"', [s]));
      ForceDirectories(s);
    end;
  end
  else
  begin
    Log(vlNormal, Format('Saving file "%s"', [s]));
    ForceDirectories(ExtractFilePath(s));
    output := ToPath(s);
    inherited;
  end;
end;

function TSVNGetFileTask.GetFileName: string;
begin
  Result := FFileInfo.URL;
end;

procedure TSVNGetFileTask.SetFileInfo(RepoBase: string; pFileInfo: TSVNInfoEntry);
begin
  repo := RepoBase;
  if not Assigned(FFileInfo) then
    FFileInfo := TSVNInfoEntry.Create;
  FFileInfo.Assign(pFileInfo);
end;

{ TSVNCommitTask }

procedure TSVNCommitTask.AddIncludes;
var
  i: Integer;
begin
  for i := Low(FIncludeFiles.Paths) to High(FIncludeFiles.Paths) do
    ArgumentList.AddValue(ToSystemPath(FIncludeFiles.Paths[i]));
end;

constructor TSVNCommitTask.Create(Owner: TScriptElement);
begin
  inherited;
  command := 'commit';
  FIncludeFiles := TIncludeFilesElement.Create(Self);
end;

function TSVNCommitTask.CreateIncludeFiles: TIncludeFilesElement;
begin
  Result := FIncludeFiles;
end;

destructor TSVNCommitTask.Destroy;
begin
  FreeAndNil(FIncludeFiles);
  inherited;
end;

procedure TSVNCommitTask.DoFirstArgument;
begin
//  ArgumentList.AddValue(dest);
end;

procedure TSVNCommitTask.DoNextArguments;
begin
  if All then
    inherited;
  ArgumentList.AddOption('-F ', ToSystemPath(MessageFile));
  StringToFile(ToSystemPath(MessageFile), _message);
  AddIncludes;
end;

procedure TSVNCommitTask.Execute;
begin
  PrepareNonVersioned;
  if Length(FIncludeFiles.Paths) <> 0 then
  begin
    Log('Committing...');
    inherited;
  end
  else
    Log(vlVerbose, 'No files to commit');
end;

function TSVNCommitTask.GetMessageFile: string;
var
  TFT: TTempFileTask;
begin
  if FMessageFileName = '' then
  begin
    try
      TFT := TTempFileTask.Create(nil);
      TFT.prefix := 'svn.commit_';
      TFT.destdir := Evaluate('%{temp}');
      TFT.Execute;
      FMessageFileName := TFT.FileName;
    finally
      FreeAndNil(TFT);
    end;
  end;
  Result := FMessageFileName; 
end;

procedure TSVNCommitTask.Init;
begin
  inherited;
  RequireAttribute('message');
  FIncludeFiles.BaseDir := dest;
end;

procedure TSVNCommitTask.PrepareNonVersioned;
var
//  tSt: TSVNStatusTask;
  tAddF: TSVNAddTask;
//  i: Integer;
begin
  try
    tAddF := TSVNAddTask.Create(Self);
    tAddF.dest := dest;
    tAddF.Init;
    tAddF.IncludeFiles.AddPatternSet(FIncludeFiles);
    tAddF.IncludeFiles.AddDefaultPatterns;
    tAddF.Execute;
{
    TSt := TSVNStatusTask.Create(Self);
    TSt.dest := dest;
    TSt.Execute;
    for i := 0 to TSt.ItemsUnVersionedCount - 1 do
      ArgumentList.AddValue(TSt.ItemsUnVersioned[i].Path);
}
  finally
    FreeAndNil(tAddF);
//    FreeAndNil(TSt);
  end;
end;

{ TSVNStatusTask }

constructor TSVNStatusTask.Create(Owner: TScriptElement);
begin
  inherited;
  command := 'status';
  ConvertSVNOutput := False;
  OutputIsUTF8 := True;
end;

destructor TSVNStatusTask.Destroy;
begin
  FreeAndNil(FStatus);
  inherited;
end;

procedure TSVNStatusTask.DoFirstArgument;
begin
  ArgumentList.AddOption('--xml');
  if verbose then
    ArgumentList.AddOption('-v');
end;

procedure TSVNStatusTask.DoParseOutput;
var
  i: Integer;
begin
  FStatus := TSVNInfoStatus.CreateByContext(FExecOutput.Text);
end;

function TSVNStatusTask.GetItems(Index: Integer): TSVNInfoEntry;
begin
  Result := FStatus.Entries[Index];
end;

function TSVNStatusTask.GetItemsCount: Integer;
begin
  Result := 0;
  if Assigned(FStatus) then
    Result := FStatus.Count;
end;

function TSVNStatusTask.GetItemsUnVersioned(
  Index: Integer): TSVNInfoEntry;
var
  i, j: Integer;
begin
  j := 0;
  Result := nil;
  for i := 0 to ItemsCount - 1 do
  begin
    if Assigned(Items[i].GetFirstByClass(TSVNInfoWC_Status))
        and TSVNInfoWC_Status(Items[i].GetFirstByClass(TSVNInfoWC_Status)).unversioned then
    begin
      if j = Index then
      begin
        Result := Items[i];
        Break;
      end;
      Inc(j);
    end;
  end;
end;

function TSVNStatusTask.GetItemsUnVersionedCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to ItemsCount - 1 do
    if Assigned(Items[i].GetFirstByClass(TSVNInfoWC_Status))
        and TSVNInfoWC_Status(Items[i].GetFirstByClass(TSVNInfoWC_Status)).unversioned then
      Inc(Result);
end;

{ TSVNAddTask }

procedure TSVNAddTask.AddIncludes;
var
  i: Integer;
begin
  for i := Low(FIncludeFiles.Paths) to High(FIncludeFiles.Paths) do
  begin
    Log('Adding ' + ToSystemPath(FIncludeFiles.Paths[i]));
    ArgumentList.AddValue(ToSystemPath(FIncludeFiles.Paths[i]));
  end;
end;

constructor TSVNAddTask.Create(Owner: TScriptElement);
begin
  inherited;
  command := 'add';
  FIncludeFiles := TIncludeFilesElement.Create(Self);
end;

function TSVNAddTask.CreateIncludeFiles: TIncludeFilesElement;
begin
  Result := FIncludeFiles;
end;

destructor TSVNAddTask.Destroy;
begin
  FreeAndNil(FIncludeFiles);
  inherited;
end;

procedure TSVNAddTask.DoFirstArgument;
begin
  AddIncludes;
end;

procedure TSVNAddTask.DoNextArguments;
begin
// do nothing
end;

procedure TSVNAddTask.Execute;
begin
  Log('Adding files to WC...');
  inherited;
end;

procedure TSVNAddTask.Init;
begin
  inherited;
  FIncludeFiles.BaseDir := dest;
end;

initialization
  RegisterTasks([TSVNTask, TSVNAuthTask, TSVNDiffTask, TSVNLastRevisionTask,
    TSVNCommitTask]);
  RegisterElements(TSVNLastRevisionTask, [TSubPropertyElement]);
end.
