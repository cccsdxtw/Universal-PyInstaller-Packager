@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title 萬用打包神器

echo ==========================================
echo    🚀 萬用 PyInstaller 拖曳打包神器 (多檔專案版)
echo ==========================================
echo/
echo    提示：請拖【主程式】進來（你平常 python xxx.py 的那個）。
echo    同資料夾 / 子資料夾裡互叫的其它 .py 會自動一併打包。
echo    也可以直接把整個專案資料夾拖進來。
echo/

set "PY_RAW="
set /p PY_RAW="1 請把主程式 .py（或專案資料夾）【拖曳】到這個黑視窗裡 然後按 Enter："
echo/
set /p ICO_FILE="2 請把你的圖示【拖曳】進來 (沒有請直接按 Enter 跳過)："

if "!PY_RAW!"=="" (
    echo ❌ 沒有收到 Python 檔案或資料夾，請重新執行。
    pause
    exit /b 1
)

:: 一次拖多個檔案時，第一個當主程式；其餘交給後面的自動掃描
set "PY_FILE="
for %%A in (%PY_RAW%) do (
    if not defined PY_FILE set "PY_FILE=%%~A"
)

:: 去除圖示路徑可能帶的雙引號
set ICO_FILE=%ICO_FILE:"=%

:: 若拖進來的是資料夾：優先找 main.py / app.py，否則請使用者指定主程式檔名
if exist "!PY_FILE!\" (
    set "FOLDER=!PY_FILE!"
    if exist "!FOLDER!\main.py" (
        set "PY_FILE=!FOLDER!\main.py"
        echo    📂 偵測到專案資料夾 → 使用 main.py 當主程式
    ) else if exist "!FOLDER!\app.py" (
        set "PY_FILE=!FOLDER!\app.py"
        echo    📂 偵測到專案資料夾 → 使用 app.py 當主程式
    ) else (
        echo    📂 這是資料夾，但根目錄沒有 main.py / app.py
        echo    根目錄的 .py 檔：
        dir /b "!FOLDER!\*.py" 2>nul
        echo/
        set /p MAIN_NAME="請輸入主程式檔名（例如 bot.py）："
        set "MAIN_NAME=!MAIN_NAME:"=!"
        set "PY_FILE=!FOLDER!\!MAIN_NAME!"
    )
)

if not exist "!PY_FILE!" (
    echo ❌ 找不到檔案：!PY_FILE!
    pause
    exit /b 1
)

:: 自動抓取你的 Python 檔名 用來建立專屬資料夾
for %%F in ("!PY_FILE!") do (
    set "PROJECT_NAME=%%~nF"
    set "PY_DIR=%%~dpF"
    set "PY_FILE=%%~fF"
)
set TARGET_DIR=打包成品_!PROJECT_NAME!

:: --paths 不能讓路徑結尾的 \ 把引號吃掉
set "PY_PATHS=!PY_DIR!"
if "!PY_PATHS:~-1!"=="\" set "PY_PATHS=!PY_PATHS:~0,-1!"

:: 🌟 關鍵修復：加上 %CD%\ 強制使用絕對路徑！
set UNIQUE_ICON_NAME=%CD%\app_master_icon.ico

echo/
echo ==========================================
echo    🧹 正在為 !PROJECT_NAME! 清理舊環境
echo ==========================================
rmdir /s /q "!TARGET_DIR!" 2>nul

:: 🌟 魔法區域：偷偷把拖進來的圖示複製一份 並改成專屬名稱
if not "!ICO_FILE!"=="" (
    echo/
    echo    🔄 正在將你的圖示自動重新命名為核心素材：app_master_icon.ico
    copy /Y "!ICO_FILE!" "!UNIQUE_ICON_NAME!" >nul
)

:: ==========================================
:: 🧠 智慧偵測：掃描整個專案（主程式 + 互叫的本地模組）
:: ==========================================
echo/
echo ==========================================
echo    🔍 正在掃描專案依賴與本地模組
echo    📂 專案目錄：!PY_PATHS!
echo    📄 主程式：!PROJECT_NAME!.py
echo ==========================================

set "EXTRA_ARGS="
set "HIDDEN_IMPORTS="
set "WINDOW_MODE="
set "HAS_HEAVY=0"
set "HAS_GUI=0"
set "LOCAL_COUNT=0"

for /R "!PY_PATHS!" %%P in (*.py) do (
    call :ShouldSkip "%%P"
    if "!SKIP_FILE!"=="0" (
        call :RegisterLocalModule "%%P"
        call :ScanFileDeps "%%P"
    )
)

if "!HAS_GUI!"=="1" (
    echo    ✅ 偵測到 GUI 套件 → 使用無黑框模式 (-w)
    set "WINDOW_MODE=-w"
) else (
    echo    ℹ️  未偵測到 GUI 套件 → 保留命令列視窗 (方便看錯誤訊息)
)

if "!LOCAL_COUNT!"=="0" (
    echo    ℹ️  同專案沒有其它 .py，將只打包主程式
) else (
    echo    📦 已登記 !LOCAL_COUNT! 個本地模組，會以 hidden-import 一併打進 EXE
)

if "!HAS_HEAVY!"=="0" (
    echo    ✨ 無需額外重量級資源，將以精簡模式打包
)

echo/
echo ==========================================
echo    ⚡ 開始執行打包作業 請稍候
echo ==========================================

:: 判斷有沒有拖曳圖示進來 決定要跑哪一段打包指令
if "!ICO_FILE!"=="" (
    pyinstaller -F !WINDOW_MODE! --paths "!PY_PATHS!" !EXTRA_ARGS! !HIDDEN_IMPORTS! --distpath "!TARGET_DIR!" --workpath "!TARGET_DIR!\build" --specpath "!TARGET_DIR!" "!PY_FILE!"
) else (
    pyinstaller -F !WINDOW_MODE! --paths "!PY_PATHS!" --icon="!UNIQUE_ICON_NAME!" --add-data "!UNIQUE_ICON_NAME!;." !EXTRA_ARGS! !HIDDEN_IMPORTS! --distpath "!TARGET_DIR!" --workpath "!TARGET_DIR!\build" --specpath "!TARGET_DIR!" "!PY_FILE!"
)

:: 🌟 毀屍滅跡：打包完畢後 把暫時產生的改名圖示刪除 保持環境乾淨
if exist "!UNIQUE_ICON_NAME!" del "!UNIQUE_ICON_NAME!"

echo/
echo ==========================================
echo    🎉 打包大功告成！
echo    你的 EXE 已經安穩地放在【!TARGET_DIR!】資料夾裡面了！
echo ==========================================
pause
endlocal
goto :eof

:: ------------------------------------------
:: 略過虛擬環境、快取、版本庫等雜訊目錄
:: ------------------------------------------
:ShouldSkip
set "SKIP_FILE=0"
echo "%~1" | findstr /I /C:"\__pycache__\" /C:"\venv\" /C:"\.venv\" /C:"\site-packages\" /C:"\.git\" /C:"\node_modules\" >nul 2>&1
if not errorlevel 1 set "SKIP_FILE=1"
goto :eof

:: ------------------------------------------
:: 把專案內其它 .py 轉成 Python 模組名，交給 PyInstaller
:: ------------------------------------------
:RegisterLocalModule
if /I "%~1"=="!PY_FILE!" goto :eof

set "MOD_DIR=%~dp1"
set "MOD_NAME=%~n1"
set "RELDIR=!MOD_DIR:%PY_DIR%=!"
set "MOD="

if /I "!MOD_NAME!"=="__init__" (
    set "MOD=!RELDIR:\=.!"
    if "!MOD:~-1!"=="." set "MOD=!MOD:~0,-1!"
) else (
    set "MOD=!RELDIR:\=.!!MOD_NAME!"
)

if "!MOD!"=="" goto :eof
if "!MOD:~-1!"=="." goto :eof

echo(!MOD!| findstr /C:"-" /C:" " >nul 2>&1
if not errorlevel 1 (
    echo    ⚠️  略過無法當成模組名稱的檔案：%~nx1
    goto :eof
)

echo    📄 本地模組：!MOD!
set "HIDDEN_IMPORTS=!HIDDEN_IMPORTS! --hidden-import !MOD!"
set /a LOCAL_COUNT+=1
goto :eof

:: ------------------------------------------
:: 掃描單一檔案的 GUI / 重量級套件
:: ------------------------------------------
:ScanFileDeps
findstr /I /C:"import tkinter" /C:"from tkinter" /C:"import customtkinter" /C:"from customtkinter" /C:"import PyQt5" /C:"from PyQt5" /C:"import PyQt6" /C:"from PyQt6" /C:"import PySide2" /C:"from PySide2" /C:"import PySide6" /C:"from PySide6" /C:"import wx" /C:"from wx" "%~1" >nul 2>&1
if not errorlevel 1 set "HAS_GUI=1"

call :DetectCollectAll selenium "Selenium" "%~1"
call :DetectCollectAll customtkinter "CustomTkinter" "%~1"
call :DetectCollectAll playwright "Playwright" "%~1"
call :DetectCollectAll ttkbootstrap "ttkbootstrap" "%~1"
goto :eof

:: ------------------------------------------
:: 子程序：偵測套件，有用到才加 --collect-all
:: 參數 %1=套件名  %2=顯示名稱  %3=檔案路徑
:: ------------------------------------------
:DetectCollectAll
if "!COLLECTED_%~1!"=="1" goto :eof

findstr /I /C:"import %~1" /C:"from %~1" "%~3" >nul 2>&1
if not errorlevel 1 (
    echo    ✅ 偵測到 %~2 （%~nx3）→ 一併打包完整資源 (--collect-all %~1)
    set "EXTRA_ARGS=!EXTRA_ARGS! --collect-all %~1"
    set "HAS_HEAVY=1"
    set "COLLECTED_%~1=1"
)
goto :eof
