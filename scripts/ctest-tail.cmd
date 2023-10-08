@echo off

set bash="%programfiles%\Git\bin\bash.exe"

if exist %bash% (
  %bash% -c "$(cygpath --unix '%~dp0')/ctest-tail.sh %* && exit"
) else (
  echo toolchains: Could not locate Git Bash for Windows at expected location %bash%
  echo toolchains: You can try installing it with "winget install --id Git.Git -e --source winget"
  exit /b 1
)
