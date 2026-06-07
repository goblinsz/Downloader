@echo off
chcp 65001 >nul

echo Downloading..
echo.

yt-dlp --js-runtimes deno ^
    -x ^
    --audio-format mp3 ^
    --audio-quality 0 ^
    --embed-thumbnail ^
    --embed-metadata ^
    -o "%USERPROFILE%\Music\YouTube\%%(title)s.%%(ext)s" ^
    %1

echo.
echo Ready! File in: %USERPROFILE%\Music\YouTube\
pause