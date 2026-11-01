#ifndef GameVersion
  #define GameVersion "0.3.0"
#endif

[Setup]
AppId={{A4A8B5A9-2E8B-4A12-9E1D-0300A4A8B5A9}
AppName=Operation: Iron Veil
AppVersion={#GameVersion}
AppPublisher=Yukkuri P
DefaultDirName={autopf}\Operation Iron Veil
DefaultGroupName=Operation: Iron Veil
OutputDir=..\release
OutputBaseFilename=Operation-Iron-Veil-Setup-{#GameVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\Operation-Iron-Veil.exe

[Files]
Source: "..\release\Operation-Iron-Veil.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Operation: Iron Veil"; Filename: "{app}\Operation-Iron-Veil.exe"
Name: "{autodesktop}\Operation: Iron Veil"; Filename: "{app}\Operation-Iron-Veil.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "デスクトップにショートカットを作成"; GroupDescription: "追加オプション:"
