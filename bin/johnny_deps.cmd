@echo off

rem The Godeps file is expected to have lines like so:
rem
rem github.com/VividCortex/robustly v2.6
rem
rem where the first element is the import path and the second is a tag
rem in the project.

set GODEPS=Godeps
set CURRENT=%cd%

if not "%1"=="" set GODEPS=%1

echo %GODEPS%

for /f "tokens=1,2" %%i in (%GODEPS%) do (
  echo "%%i %%j"
  go get -v -u -d "%%i" || goto :error
  echo "Setting %%i to version %%j"
  cd "%GOPATH%\src\%%i" && git checkout "%%j" || goto :error
  echo "Installing %%i"
  go install "%%i" || goto :error
)

:success
cd CURRENT
exit /b

:error
echo "Failed with error %errorlevel%."
cd CURRENT
exit /b %errorlevel%
