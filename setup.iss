; Preprocessor: ensure AppVersion is defined (overridden by /DAppVersion=...)
#ifndef AppVersion
#define AppVersion "0.0.0"
#endif

[Setup]
AppName=Matchify Desktop
AppVersion={#AppVersion}
AppPublisher=MrArvand
AppPublisherURL=https://github.com/MrArvand/matchify-desktop
AppSupportURL=https://github.com/MrArvand/matchify-desktop
AppUpdatesURL=https://github.com/MrArvand/matchify-desktop
AppId={{8F4C8B2A-1E3D-4F5A-9B6C-7D8E9F0A1B2C}
DefaultDirName={autopf}\Matchify Desktop
DefaultGroupName=Matchify Desktop
AllowNoIcons=yes
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
OutputDir=output
OutputBaseFilename=matchify-desktop-setup-v{#AppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
CloseApplications=yes
RestartApplications=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.17763

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Matchify Desktop"; Filename: "{app}\matchify_desktop.exe"
Name: "{group}\{cm:UninstallProgram,Matchify Desktop}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Matchify Desktop"; Filename: "{app}\matchify_desktop.exe"; Tasks: desktopicon


[Run]
Filename: "{app}\matchify_desktop.exe"; Description: "{cm:LaunchProgram,Matchify Desktop}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\Matchify Desktop"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Matchify Desktop"; ValueType: string; ValueName: "Version"; ValueData: "{#AppVersion}"; Flags: uninsdeletekey

