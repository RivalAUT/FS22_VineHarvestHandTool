@ECHO OFF
for %%a in ("%~dp0\.") do set "filename=%%~nxa"
echo Zip wird erstellt...
"%ProgramFiles%\WinRAR\WinRAR.exe" a -afzip -ibck -r %filename%.zip *.i3d
"%ProgramFiles%\WinRAR\WinRAR.exe" a -afzip -ibck -r %filename%.zip *.i3d.shapes
"%ProgramFiles%\WinRAR\WinRAR.exe" a -afzip -ibck -r %filename%.zip *.lua
"%ProgramFiles%\WinRAR\WinRAR.exe" a -afzip -ibck -r %filename%.zip *.dds
"%ProgramFiles%\WinRAR\WinRAR.exe" a -afzip -ibck -r %filename%.zip *.xml
echo Zip wird in Modordner kopiert...
copy %filename%.zip "%UserProfile%\Documents\My Games\FarmingSimulator2022\mods\%filename%.zip"

CHOICE /C YN /T 2 /D N /M "LS starten? (Y/N)"
IF %ERRORLEVEL% NEQ 1 GOTO END
start steam://rungameid/1248130
:END
