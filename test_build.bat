@echo off
cd /d "C:\Users\milos\vulkanR"
"C:\Program Files\R\R-4.5.1\bin\x64\R.exe" --vanilla -e "rextendr::clean(); rextendr::document(); rextendr::register_extendr()"
pause