@echo off
setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='index.html';" ^
  "$coi='<script src=\"coi-serviceworker.js\"></script>';" ^
  "$idx='<script src=\"index.js\"></script>';" ^
  "$text=Get-Content -Raw -Encoding UTF8 $p;" ^
  "if ($text -notlike ('*' + $coi + '*')) {" ^
  "  $text=$text.Replace($idx, $coi + \"`r`n`t`t\" + $idx);" ^
  "  Set-Content -Encoding UTF8 -NoNewline $p $text;" ^
  "  Write-Host 'Added coi-serviceworker.js before index.js.'" ^
  "} else {" ^
  "  Write-Host 'coi-serviceworker.js is already present.'" ^
  "}"

git add -A
if errorlevel 1 goto failed

for /f %%i in ('git write-tree') do set TREE_HASH=%%i
if errorlevel 1 goto failed

for /f %%i in ('git commit-tree %TREE_HASH% -m "Publish web export"') do set COMMIT_HASH=%%i
if errorlevel 1 goto failed

git update-ref refs/heads/main %COMMIT_HASH%
if errorlevel 1 goto failed

git reflog expire --expire=now --expire-unreachable=now --all
if errorlevel 1 goto failed

git gc --prune=now --aggressive
if errorlevel 1 goto failed

echo.
echo Prepared single-snapshot commit: %COMMIT_HASH%
git count-objects -vH
echo.
echo Push it with:
echo git push --force-with-lease origin main
echo.
pause
exit /b 0

:failed
echo.
echo Failed. Check the message above.
pause
exit /b 1
