; NSIS installer script for ClassFlow (Windows)
; Requires NSIS on the build machine (makensis)

!define APP_NAME "ClassFlow"
!define COMPANY_NAME "OmgRod"
!define VERSION "1.0.0"
!define INSTALLER_NAME "classflow-setup-${VERSION}.exe"

; Output installer
OutFile "${INSTALLER_NAME}"

; Install directory
InstallDir "$PROGRAMFILES\${COMPANY_NAME}\${APP_NAME}"

; Request admin (for Program Files write)
RequestExecutionLevel admin

; Use modern UI
!include MUI2.nsh

; Icon (optional) - path relative to this script directory (installer/windows)
; Adjust to reach actual icon under repo/windows/runner/resources
!define MUI_ICON "..\..\windows\runner\resources\app_icon.ico"
Icon "..\..\windows\runner\resources\app_icon.ico"
UninstallIcon "..\..\windows\runner\resources\app_icon.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"

Section "Install"
  ; Create install dir
  SetOutPath "$INSTDIR"
  ; Copy built release files from Flutter build output
  ; Expect `flutter build windows` output under build/windows/x64/runner/Release
  ; Verify build output exists before attempting to package
  IfFileExists "build\windows\x64\runner\Release\classflow.exe" 0 checkUpper
  Goto continue
  checkUpper:
    IfFileExists "build\windows\x64\runner\Release\ClassFlow.exe" 0 buildMissing
    Goto continue
  buildMissing:
    MessageBox MB_OK "Windows release build not found. Run 'flutter build windows --release' first."
    Abort
  continue:
  File /r "build/windows/x64/runner/Release/*"

  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" "" "$INSTDIR\${APP_NAME}.exe" 0
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_NAME}.exe" "" "$INSTDIR\${APP_NAME}.exe" 0

SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\${APP_NAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APP_NAME}"
  RMDir /r "$INSTDIR"
SectionEnd
