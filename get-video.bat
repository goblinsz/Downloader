@echo off
chcp 65001 >nul

echo Downloading...
echo.

yt-dlp --js-runtimes deno ^
    -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]" ^
    --merge-output-format mp4 ^
    -o "%USERPROFILE%\Videos\YouTube\%%(title)s.%%(ext)s" ^
    %1

echo.
echo Ready! File in: %USERPROFILE%\Videos\YouTube\
pause