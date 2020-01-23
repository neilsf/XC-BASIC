; -- 64Bit.iss --
; Demonstrates installation of a program built for the x64 (a.k.a. AMD64)
; architecture.
; To successfully run this installation and the program it installs,
; you must have a "x64" edition of Windows.

; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

[Setup]
AppName="XC=BASIC"
AppVersion=2.2.03
WizardStyle=modern
DefaultDirName={autopf}\xcbasic64
DisableDirPage=yes
AlwaysShowDirOnReadyPage=yes
DefaultGroupName="XC=BASIC"
UninstallDisplayIcon={app}\xcbasic.ico
Compression=lzma2
SolidCompression=yes
OutputDir=userdocs:Inno Setup Examples Output
; "ArchitecturesAllowed=x64" specifies that Setup cannot run on
; anything but x64.
ArchitecturesAllowed=x64
; "ArchitecturesInstallIn64BitMode=x64" requests that the install be
; done in "64-bit mode" on x64, meaning it should use the native
; 64-bit Program Files directory and the 64-bit view of the registry.
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "xcbasic64.exe"; DestDir: "{app}"
Source: "xcbcmd.bat"; DestDir: "{app}"
Source: "xcbasic.conf"; DestDir: "{app}"
Source: "VERSION.txt"; DestDir: "{app}"
Source: "LICENSE.txt"; DestDir: "{app}"
Source: "RELNOTES.txt"; DestDir: "{app}"
Source: "dasm\*"; DestDir: "{app}/dasm"

[Icons]
Name: "{group}\XC=BASIC command prompt"; Filename: "{app}\xcbcmd.bat"
Name: "{group}\Uninstall XC=BASIC"; Filename: "{app}\unins000.exe"

[Registry]
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; \
    ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; \
    Check: NeedsAddPath('{app}')

[Code]
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  { look for the path with leading and trailing semicolon }
  { Pos() returns 0 if not found }
  Result := Pos(';' + Param + ';', ';' + OrigPath + ';') = 0;
end;