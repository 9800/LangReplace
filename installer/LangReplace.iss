; LangReplace Installer Script — Inno Setup 6
; Programmer: Nikan Rayan

[Setup]
AppName=LangReplace
AppVersion=1.0
AppVerName=LangReplace 1.0
AppPublisher=Nikan Rayan
AppPublisherURL=https://github.com/
DefaultDirName={autopf}\LangReplace
DefaultGroupName=LangReplace
OutputDir=Output
OutputBaseFilename=LangReplace-Setup
SetupIconFile=..\resources\icon.ico
UninstallDisplayIcon={app}\LangReplace.exe
UninstallDisplayName=LangReplace
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ShowLanguageDialog=no
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
Name: "autostart"; Description: "&Start LangReplace with Windows"; GroupDescription: "Startup:"; Flags: unchecked

[Files]
Source: "..\zig-out\bin\LangReplace.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\LangReplace"; Filename: "{app}\LangReplace.exe"
Name: "{group}\Uninstall LangReplace"; Filename: "{uninstallexe}"
Name: "{autodesktop}\LangReplace"; Filename: "{app}\LangReplace.exe"; Tasks: desktopicon

[Registry]
; ✅ اجرای خودکار هنگام شروع ویندوز (هم‌نام با کلید داخل خود برنامه)
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "LangReplace"; ValueData: """{app}\LangReplace.exe"""; Flags: uninsdeletevalue; Tasks: autostart

[Run]
Filename: "{app}\LangReplace.exe"; Description: "Launch LangReplace"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\langreplace_debug.log"
