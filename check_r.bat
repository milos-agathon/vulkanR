@echo off
echo Checking R installation and packages...
"C:\Program Files\R\R-4.5.1\bin\x64\R.exe" --vanilla -e "cat('R is working\n'); if(require(rextendr)) cat('rextendr is available\n') else cat('rextendr NOT available\n')"
echo.
echo Done.
pause