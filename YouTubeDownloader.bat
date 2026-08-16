@echo off
setlocal EnableDelayedExpansion
title YouTube Downloader
cd /d "%~dp0"

set "CONFIG=%~dp0settings.ini"
set "HIST=%~dp0history.txt"
set "YDLP="

call :check_components
if errorlevel 1 exit /b 1
call :load_config

:main
cls
call :banner
echo   [1] Video (single)
echo   [2] Music (MP3)
echo   [3] Playlist - video
echo   [4] Playlist - music
echo   [5] Whole channel
echo   [6] Download from list file
echo   [7] Settings
echo   [8] Update yt-dlp
echo   [9] Check components
echo   [a] Open save folder
echo   [0] Exit
echo.
set "m="
set /p "m=   Your choice: "
if "%m%"=="" set "m=0"
if "%m%"=="1" call :dl_video
if "%m%"=="2" call :dl_music
if "%m%"=="3" call :dl_playlist
if "%m%"=="4" call :dl_playlist_music
if "%m%"=="5" call :dl_channel
if "%m%"=="6" call :dl_list
if "%m%"=="7" call :settings
if "%m%"=="8" call :update_ytdlp
if "%m%"=="9" call :check_info
if /i "%m%"=="a" call :open_folder
if "%m%"=="0" exit /b 0
goto main

:banner
echo.
echo   ==================================================
echo        YouTube Downloader  ^|  yt-dlp + ffmpeg
echo   ==================================================
echo.
exit /b 0

:dl_video
set "mode=video"
call :dl_run
exit /b 0

:dl_music
set "mode=music"
call :dl_run
exit /b 0

:dl_playlist
set "mode=playlist"
call :dl_run
exit /b 0

:dl_playlist_music
set "mode=playlist_music"
call :dl_run
exit /b 0

:dl_channel
set "mode=channel"
call :dl_run
exit /b 0

:dl_run
if "%url%"=="" (
  cls
  call :banner
  call :mode_title
  call :ask_url
  if "!url!"=="" exit /b 0
)
set "last_mode=!mode!"
call :ensure_folder
if "!mode!"=="channel" call :channel_n
call :build_args !mode!
call :run_dl !mode!
call :after_dl !mode!
exit /b 0

:mode_title
if "!mode!"=="video" echo   -- VIDEO --
if "!mode!"=="music" echo   -- MUSIC (MP3) --
if "!mode!"=="playlist" echo   -- PLAYLIST (VIDEO) --
if "!mode!"=="playlist_music" echo   -- PLAYLIST (MUSIC) --
if "!mode!"=="channel" echo   -- WHOLE CHANNEL --
if "!mode!"=="channel" echo   Paste a channel link (e.g. https://www.youtube.com/@Channel). All channel content will be downloaded.
exit /b 0

:channel_n
set "pl_items="
set "cn="
set /p "cn=   All channel videos (Enter) or download last N: "
if defined cn if !cn! gtr 0 set "pl_items=--playlist-items 1-!cn!"
set "cn="
exit /b 0

:dl_list
cls
call :banner
echo   -- DOWNLOAD FROM LIST FILE --
echo   File format: one URL per line (lines starting with # are ignored).
echo.
echo   Mode for all links:
echo   [1] Video  [2] Music  [3] Playlist  [4] Playlist music  [5] Channel
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "mode=video"
if "%m%"=="2" set "mode=music"
if "%m%"=="3" set "mode=playlist"
if "%m%"=="4" set "mode=playlist_music"
if "%m%"=="5" set "mode=channel"
if not defined mode exit /b 0
set "last_mode=!mode!"
set "lf="
set /p "lf=   List file path (Enter - list.txt): "
if not defined lf set "lf=%~dp0list.txt"
if not exist "!lf!" (
  echo   File not found: !lf!
  pause
  exit /b 0
)
call :ensure_folder
for /f "usebackq eol=# delims=" %%l in ("!lf!") do (
  set "url=%%l"
  if defined url (
    call :build_args !mode!
    call :run_dl !mode!
  )
)
set "url="
set "mode="
echo.
echo   List finished.
pause
exit /b 0

:ask_url
set "url="
set /p "url=   Paste the link (Enter - menu): "
exit /b 0

:current_folder
set "cm=!mode!"
if not "%1"=="" set "cm=%1"
set "fld=!cfg_folder_video!"
if "!cm!"=="music" set "fld=!cfg_folder_music!"
if "!cm!"=="playlist_music" set "fld=!cfg_folder_music!"
if "!cm!"=="channel" set "fld=!cfg_folder_channel!"
exit /b 0

:ensure_folder
call :current_folder
if not exist "!fld!" mkdir "!fld!"
exit /b 0

:build_args
set "rclient=%2"
if not defined rclient set "rclient=!cfg_client!"
set "args="
call :current_folder
set "args=!args! -o "!cfg_template!" -P "!fld!""
set "args=!args! --embed-metadata"
if "!cfg_thumb!"=="yes" set "args=!args! --embed-thumbnail"
call :subs_args
if not "!rclient!"=="default" set "args=!args! --extractor-args "youtube:player_client=!rclient!""
if not "!cfg_cookies!"=="none" call :cookies_args
if defined pl_items set "args=!args! !pl_items!"
if "%1"=="music" goto :music_only
if "%1"=="playlist_music" goto :music_only
call :video_format_args
if "%1"=="video" set "args=!args! --no-playlist"
if "%1"=="music" set "args=!args! --no-playlist"
if "%1"=="playlist" set "args=!args! --yes-playlist"
if "%1"=="playlist_music" set "args=!args! --yes-playlist"
if "%1"=="channel" set "args=!args! --yes-playlist"
exit /b 0

:music_only
set "ac=0"
if "!cfg_audio!"=="256" set "ac=1"
if "!cfg_audio!"=="192" set "ac=2"
if "!cfg_audio!"=="128" set "ac=5"
set "args=!args! -x --audio-format mp3 --audio-quality !ac!"
if "%1"=="music" set "args=!args! --no-playlist"
if "%1"=="playlist_music" set "args=!args! --yes-playlist"
exit /b 0

:video_format_args
set "vf=bv*+ba/b"
if "!cfg_quality!"=="1080" set "vf=bv*[height<=1080]+ba/b[height<=1080]"
if "!cfg_quality!"=="720" set "vf=bv*[height<=720]+ba/b[height<=720]"
if "!cfg_quality!"=="480" set "vf=bv*[height<=480]+ba/b[height<=480]"
set "args=!args! -f "!vf!""
if "!cfg_container!"=="mp4" set "args=!args! --merge-output-format mp4"
if "!cfg_container!"=="mkv" set "args=!args! --merge-output-format mkv"
exit /b 0

:subs_args
if "!cfg_subs!"=="none" exit /b 0
if "!cfg_subs!"=="ru" set "args=!args! --write-subs --sub-langs "ru.*" --sub-format srt/best"
if "!cfg_subs!"=="ruauto" set "args=!args! --write-subs --write-auto-subs --sub-langs "ru.*" --sub-format srt/best"
if "!cfg_subs!"=="all" set "args=!args! --write-subs --write-auto-subs --sub-langs "all""
exit /b 0

:cookies_args
set "ck=!cfg_cookies!"
if "!ck:~0,8!"=="browser:" (
  set "args=!args! --cookies-from-browser !ck:~8!"
) else (
  if "!ck:~0,5!"=="file:" set "args=!args! --cookies "!ck:~5!""
)
exit /b 0

:run_dl
echo.
echo   Command: !YDLP! !args! "!url!"
echo   Downloading...
echo.
"!YDLP!" !args! "!url!"
set "rc=!errorlevel!"
if "!rc!"=="0" (
  call :history_add
  powershell -NoProfile -Command "[console]::beep(900,120)" >nul 2>&1
  exit /b 0
)
echo.
echo   Download failed (exit code !rc!).
set "rc="
set /p "rc=   Retry with another player client? ([1] Android VR [2] Mobile web [3] TV [4] iOS [0] no): "
if "%rc%"=="1" call :build_args %1 android_vr
if "%rc%"=="2" call :build_args %1 mweb
if "%rc%"=="3" call :build_args %1 tv
if "%rc%"=="4" call :build_args %1 ios
if "%rc%"=="0" exit /b 0
if not defined rc exit /b 0
echo   Retrying...
"!YDLP!" !args! "!url!"
set "rc=!errorlevel!"
if "!rc!"=="0" (
  call :history_add
  powershell -NoProfile -Command "[console]::beep(900,120)" >nul 2>&1
)
exit /b 0

:after_dl
echo.
echo   -- DONE --
set "url="
:next_prompt
set "next="
set /p "next=   Next link (same mode) or [v: m: p: pm: ch:] switch, [o] folder, [h] history, [q] menu: "
if not defined next exit /b 0
if /i "!next!"=="q" exit /b 0
if /i "!next!"=="o" (
  call :current_folder
  if not exist "!fld!" mkdir "!fld!"
  explorer "!fld!"
  goto :next_prompt
)
if /i "!next!"=="h" (
  call :history_show
  if not "!url!"=="" goto :dl_run
  goto :next_prompt
)
set "nl="
set "cand="
for /f "tokens=1 delims=:" %%a in ("!next!") do set "cand=%%a"
if /i "!cand!"=="v" set "nl=video"
if /i "!cand!"=="m" set "nl=music"
if /i "!cand!"=="p" set "nl=playlist"
if /i "!cand!"=="pm" set "nl=playlist_music"
if /i "!cand!"=="ch" set "nl=channel"
if defined nl (
  set "mode=!nl!"
  set "nl="
  set "cand="
  for /f "tokens=1,* delims=:" %%a in ("!next!") do set "url=%%b"
  goto :dl_run
)
set "url=!next!"
set "next="
goto :dl_run

:history_add
if not defined url exit /b 0
echo !url!>> "%HIST%"
for /f %%n in ('find /c /v "" ^< "%HIST%"') do set "hc=%%n"
if !hc! gtr 50 (
  set /a "hc=!hc!-30"
  set "skip=!hc!"
  set "tmp=%HIST%.tmp"
  if exist "!tmp!" del "!tmp!"
  for /f "skip=!skip! delims=" %%l in ("%HIST%") do echo %%l>> "!tmp!"
  move /y "!tmp!" "%HIST%" >nul
)
exit /b 0

:history_show
if not exist "%HIST%" (
  echo   History is empty.
  exit /b 0
)
set "url="
for /f %%n in ('find /c /v "" ^< "%HIST%"') do set "hc=%%n"
echo   Recent downloads:
if !hc! gtr 20 (
  set /a "skip=!hc!-20"
  for /f "skip=!skip! tokens=1,* delims=:" %%a in ('findstr /n "^" "%HIST%"') do echo   [%%a] %%b
) else (
  for /f "tokens=1,* delims=:" %%a in ('findstr /n "^" "%HIST%"') do echo   [%%a] %%b
)
set "hn="
set /p "hn=   Number to redownload (Enter - back): "
if not defined hn exit /b 0
for /f "tokens=1,* delims=:" %%a in ('findstr /n "^" "%HIST%"') do if "%%a"=="!hn!" set "url=%%b"
exit /b 0

:settings
cls
call :banner
set "cookies_disp=None"
if "!cfg_cookies!"=="browser:chrome" set "cookies_disp=Chrome"
if "!cfg_cookies!"=="browser:edge" set "cookies_disp=Edge"
if "!cfg_cookies!"=="browser:firefox" set "cookies_disp=Firefox"
if "!cfg_cookies!"=="browser:brave" set "cookies_disp=Brave"
if "!cfg_cookies!"=="browser:opera" set "cookies_disp=Opera"
if "!cfg_cookies!"=="browser:vivaldi" set "cookies_disp=Vivaldi"
if "!cfg_cookies:~0,5!"=="file:" set "cookies_disp=File: !cfg_cookies:~5!"
set "client_disp=Default"
if "!cfg_client!"=="android_vr" set "client_disp=Android VR"
if "!cfg_client!"=="mweb" set "client_disp=Mobile web"
if "!cfg_client!"=="tv" set "client_disp=TV"
if "!cfg_client!"=="ios" set "client_disp=iOS"
if "!cfg_client!"=="android" set "client_disp=Android"
echo   -- SETTINGS --
echo   [1] Video folder:    !cfg_folder_video!
echo   [2] Music folder:    !cfg_folder_music!
echo   [3] Channel folder:  !cfg_folder_channel!
echo   [4] Video quality:    !cfg_quality!
echo   [5] Container:         !cfg_container!
echo   [6] Audio quality:    !cfg_audio! kbps
echo   [7] Subtitles:          !cfg_subs!
echo   [8] Thumbnail:           !cfg_thumb!
echo   [9] File name:         !cfg_template!
echo   [a] Cookies:          !cookies_disp!
echo   [b] Player client:    !client_disp!
echo   [c] Choose folder (browser dialog)
echo   [r] Reset settings
echo   [0] Back
echo.
set "m="
set /p "m=   Your choice: "
if "%m%"=="1" call :set_folder video
if "%m%"=="2" call :set_folder music
if "%m%"=="3" call :set_folder channel
if "%m%"=="4" call :set_quality
if "%m%"=="5" call :set_container
if "%m%"=="6" call :set_audio
if "%m%"=="7" call :set_subs
if "%m%"=="8" call :set_thumb
if "%m%"=="9" call :set_template
if /i "%m%"=="a" call :set_cookies
if /i "%m%"=="b" call :set_client
if /i "%m%"=="c" call :set_folder_picker
if /i "%m%"=="r" call :reset_config
if "%m%"=="0" exit /b 0
goto settings

:set_folder
echo   Current: !cfg_folder_%1!
set "nf="
set /p "nf=   New folder (Enter - cancel): "
if not defined nf exit /b 0
set "cfg_folder_%1=!nf!"
set "nf="
call :save_config
exit /b 0

:set_folder_picker
echo   Which folder to change?
echo   [1] Video  [2] Music  [3] Channels  [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "ft=video"
if "%m%"=="2" set "ft=music"
if "%m%"=="3" set "ft=channel"
if not defined ft exit /b 0
for /f "delims=" %%d in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f=New-Object System.Windows.Forms.FolderBrowserDialog; $f.Description='Select folder'; if($f.ShowDialog() -eq 'OK'){ $f.SelectedPath }"') do set "cfg_folder_!ft!=%%d"
set "ft="
call :save_config
exit /b 0

:set_cookies
echo.
echo   Cookies (fixes YouTube blocks: 403, "confirm you are not a bot"):
echo   [1] None
echo   [2] Chrome
echo   [3] Edge
echo   [4] Firefox
echo   [5] Brave
echo   [6] Opera
echo   [7] Cookies file (exported cookies.txt)
echo   [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "cfg_cookies=none"
if "%m%"=="2" set "cfg_cookies=browser:chrome"
if "%m%"=="3" set "cfg_cookies=browser:edge"
if "%m%"=="4" set "cfg_cookies=browser:firefox"
if "%m%"=="5" set "cfg_cookies=browser:brave"
if "%m%"=="6" set "cfg_cookies=browser:opera"
if "%m%"=="7" call :set_cookies_file
if not "%m%"=="0" call :save_config
exit /b 0

:set_cookies_file
set "cf="
set /p "cf=   Path to cookies.txt file (Enter - cancel): "
if not defined cf exit /b 0
set "cfg_cookies=file:!cf!"
set "cf="
exit /b 0

:set_client
echo.
echo   YouTube player client:
echo   [1] Default (recommended)
echo   [2] Android VR
echo   [3] Mobile web
echo   [4] TV
echo   [5] iOS
echo   [6] Android
echo   [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "cfg_client=default"
if "%m%"=="2" set "cfg_client=android_vr"
if "%m%"=="3" set "cfg_client=mweb"
if "%m%"=="4" set "cfg_client=tv"
if "%m%"=="5" set "cfg_client=ios"
if "%m%"=="6" set "cfg_client=android"
if not "%m%"=="0" call :save_config
exit /b 0

:set_quality
echo.
echo   Video quality:
echo   [1] Best (no limit)
echo   [2] Up to 1080p
echo   [3] Up to 720p
echo   [4] Up to 480p
echo   [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "cfg_quality=best"
if "%m%"=="2" set "cfg_quality=1080"
if "%m%"=="3" set "cfg_quality=720"
if "%m%"=="4" set "cfg_quality=480"
if not "%m%"=="0" call :save_config
exit /b 0

:set_container
echo.
echo   Container:
echo   [1] mp4 (compatible)
echo   [2] mkv (lossless)
echo   [3] As is (no remux)
echo   [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "cfg_container=mp4"
if "%m%"=="2" set "cfg_container=mkv"
if "%m%"=="3" set "cfg_container=best"
if not "%m%"=="0" call :save_config
exit /b 0

:set_audio
echo.
echo   MP3 audio quality:
echo   [1] 320 kbps (best)
echo   [2] 256 kbps
echo   [3] 192 kbps
echo   [4] 128 kbps
echo   [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "cfg_audio=320"
if "%m%"=="2" set "cfg_audio=256"
if "%m%"=="3" set "cfg_audio=192"
if "%m%"=="4" set "cfg_audio=128"
if not "%m%"=="0" call :save_config
exit /b 0

:set_subs
echo.
echo   Subtitles:
echo   [1] None
echo   [2] Russian
echo   [3] Russian + auto subs
echo   [4] All languages + auto subs
echo   [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "cfg_subs=none"
if "%m%"=="2" set "cfg_subs=ru"
if "%m%"=="3" set "cfg_subs=ruauto"
if "%m%"=="4" set "cfg_subs=all"
if not "%m%"=="0" call :save_config
exit /b 0

:set_thumb
echo.
echo   Embed thumbnail into file:
echo   [1] Yes
echo   [2] No
echo   [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "cfg_thumb=yes"
if "%m%"=="2" set "cfg_thumb=no"
if not "%m%"=="0" call :save_config
exit /b 0

:set_template
echo.
echo   File name template:
echo   [1] %%(title)s.%%(ext)s
echo   [2] %%(channel)s - %%(title)s.%%(ext)s
echo   [3] %%(uploader)s\%%(title)s.%%(ext)s
echo   [4] %%(title)s [%%(id)s].%%(ext)s
echo   [5] %%(playlist_title)s\%%(playlist_index)02d - %%(title)s.%%(ext)s
echo   [6] Custom template
echo   [0] Back
set "m="
set /p "m=   Choice: "
if "%m%"=="1" set "cfg_template=%%(title)s.%%(ext)s"
if "%m%"=="2" set "cfg_template=%%(channel)s - %%(title)s.%%(ext)s"
if "%m%"=="3" set "cfg_template=%%(uploader)s\%%(title)s.%%(ext)s"
if "%m%"=="4" set "cfg_template=%%(title)s [%%(id)s].%%(ext)s"
if "%m%"=="5" set "cfg_template=%%(playlist_title)s\%%(playlist_index)02d - %%(title)s.%%(ext)s"
if "%m%"=="6" call :set_template_custom
if not "%m%"=="0" call :save_config
exit /b 0

:set_template_custom
set "nt="
set /p "nt=   Template (e.g. %%(title)s.%%(ext)s): "
if not defined nt exit /b 0
set "cfg_template=!nt!"
set "nt="
exit /b 0

:update_ytdlp
cls
call :banner
echo   Updating yt-dlp...
"!YDLP!" -U
echo.
pause
exit /b 0

:check_info
cls
call :banner
echo   -- CHECK COMPONENTS --
"!YDLP!" --version
if exist "%~dp0bin\ffmpeg.exe" (
  echo   ffmpeg: found (bin\ffmpeg.exe)
) else (
  where ffmpeg >nul 2>&1
  if errorlevel 1 (
    echo   ffmpeg: NOT FOUND (audio and merging may not work)
  ) else (
    echo   ffmpeg: found in PATH
  )
)
echo   Video folder:    !cfg_folder_video!
echo   Music folder:    !cfg_folder_music!
echo   Channel folder:  !cfg_folder_channel!
echo.
pause
exit /b 0

:open_folder
if not defined last_mode set "last_mode=video"
call :current_folder !last_mode!
if not exist "!fld!" mkdir "!fld!"
explorer "!fld!"
exit /b 0

:load_config
if not exist "%CONFIG%" call :create_defaults
for /f "usebackq eol=# delims=" %%a in ("%CONFIG%") do (
  for /f "tokens=1,* delims==" %%b in ("%%a") do set "cfg_%%b=%%c"
)
if not defined cfg_folder set "cfg_folder=%USERPROFILE%\Downloads\YouTube"
if not defined cfg_folder_video set "cfg_folder_video=!cfg_folder!\Video"
if not defined cfg_folder_music set "cfg_folder_music=!cfg_folder!\Music"
if not defined cfg_folder_channel set "cfg_folder_channel=!cfg_folder!\Channels"
if not defined cfg_quality set "cfg_quality=best"
if not defined cfg_container set "cfg_container=mp4"
if not defined cfg_audio set "cfg_audio=320"
if not defined cfg_subs set "cfg_subs=none"
if not defined cfg_thumb set "cfg_thumb=yes"
if not defined cfg_template set "cfg_template=%%(title)s.%%(ext)s"
if not defined cfg_cookies set "cfg_cookies=none"
if not defined cfg_client set "cfg_client=default"
exit /b 0

:create_defaults
set "cfg_folder=%USERPROFILE%\Downloads\YouTube"
set "cfg_folder_video=!cfg_folder!\Video"
set "cfg_folder_music=!cfg_folder!\Music"
set "cfg_folder_channel=!cfg_folder!\Channels"
set "cfg_quality=best"
set "cfg_container=mp4"
set "cfg_audio=320"
set "cfg_subs=none"
set "cfg_thumb=yes"
set "cfg_template=%%(title)s.%%(ext)s"
set "cfg_cookies=none"
set "cfg_client=default"
call :save_config
exit /b 0

:save_config
(
  echo # YouTube Downloader configuration
  echo folder_video=!cfg_folder_video!
  echo folder_music=!cfg_folder_music!
  echo folder_channel=!cfg_folder_channel!
  echo quality=!cfg_quality!
  echo container=!cfg_container!
  echo audio=!cfg_audio!
  echo subs=!cfg_subs!
  echo thumb=!cfg_thumb!
  echo template=!cfg_template!
  echo cookies=!cfg_cookies!
  echo client=!cfg_client!
) > "%CONFIG%"
exit /b 0

:reset_config
call :create_defaults
echo   Settings reset.
pause
exit /b 0

:check_components
if exist "%~dp0yt-dlp.exe" (
  set "YDLP="%~dp0yt-dlp.exe""
) else (
  where yt-dlp >nul 2>&1
  if not errorlevel 1 (
    set "YDLP=yt-dlp"
  ) else (
    echo   yt-dlp not found.
    set "yn="
    set /p "yn=   Download yt-dlp.exe to this folder? (y/n): "
    if /i "!yn!"=="y" powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe' -OutFile '%~dp0yt-dlp.exe'"
    if exist "%~dp0yt-dlp.exe" (
      set "YDLP="%~dp0yt-dlp.exe""
      echo   yt-dlp installed.
    ) else (
      echo   yt-dlp is not available. Program terminated.
      exit /b 1
    )
  )
)
if exist "%~dp0bin\ffmpeg.exe" (
  set "PATH=%~dp0bin;%PATH%"
) else (
  where ffmpeg >nul 2>&1
  if errorlevel 1 echo   Warning: ffmpeg not found, audio and merging may not work.
)
exit /b 0