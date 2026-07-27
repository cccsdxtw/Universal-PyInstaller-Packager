@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title 萬用打包神器 

echo ==========================================
echo    🚀 萬用 PyInstaller 拖曳打包神器 (智慧依賴偵測版)
echo ==========================================
echo/

set /p PY_FILE="1 請把你要打包的 Python 檔案【拖曳】到這個黑視窗裡 然後按 Enter："
echo/
set /p ICO_FILE="2 請把你的圖示【拖曳】進來 (沒有請直接按 Enter 跳過)："

:: 去除 Windows 拖曳檔案時自動加上的雙引號
set PY_FILE=%PY_FILE:"=%
set ICO_FILE=%ICO_FILE:"=%

:: 自動抓取你的 Python 檔名 用來建立專屬資料夾
for %%F in ("%PY_FILE%") do set PROJECT_NAME=%%~nF
set TARGET_DIR=打包成品_%PROJECT_NAME%

:: 🌟 關鍵修復：加上 %CD%\ 強制使用絕對路徑！
set UNIQUE_ICON_NAME=%CD%\app_master_icon.ico

echo/
echo ==========================================
echo    🧹 正在為 %PROJECT_NAME% 清理舊環境
echo ==========================================
rmdir /s /q "%TARGET_DIR%" 2>nul

:: 🌟 魔法區域：偷偷把拖進來的圖示複製一份 並改成專屬名稱
if not "%ICO_FILE%"=="" (
    echo/
    echo    🔄 正在將你的圖示自動重新命名為核心素材：app_master_icon.ico
    copy /Y "%ICO_FILE%" "%UNIQUE_ICON_NAME%" >nul
)

:: ==========================================
:: 🧠 智慧偵測：只打包腳本真正用到的東西
:: ==========================================
echo/
echo ==========================================
echo    🔍 正在掃描腳本依賴 避免多餘打包
echo ==========================================

set "EXTRA_ARGS="
set "WINDOW_MODE="
set "HAS_HEAVY=0"

:: --- GUI 偵測：有視窗套件才關黑框 (-w)，否則保留命令列方便除錯 ---
findstr /I /C:"import tkinter" /C:"from tkinter" /C:"import customtkinter" /C:"from customtkinter" /C:"import PyQt5" /C:"from PyQt5" /C:"import PyQt6" /C:"from PyQt6" /C:"import PySide2" /C:"from PySide2" /C:"import PySide6" /C:"from PySide6" /C:"import wx" /C:"from wx" "%PY_FILE%" >nul 2>&1
if not errorlevel 1 (
    echo    ✅ 偵測到 GUI 套件 → 使用無黑框模式 (-w)
    set "WINDOW_MODE=-w"
) else (
    echo    ℹ️  未偵測到 GUI 套件 → 保留命令列視窗 (方便看錯誤訊息)
)

:: --- 需要 --collect-all 的重量級套件（沒偵測到就不塞，省空間） ---
call :DetectCollectAll selenium "Selenium"
call :DetectCollectAll customtkinter "CustomTkinter"
call :DetectCollectAll playwright "Playwright"
call :DetectCollectAll ttkbootstrap "ttkbootstrap"

if "!HAS_HEAVY!"=="0" (
    echo    ✨ 無需額外重量級資源，將以精簡模式打包
)

echo/
echo ==========================================
echo    ⚡ 開始執行打包作業 請稍候
echo ==========================================

:: 判斷有沒有拖曳圖示進來 決定要跑哪一段打包指令
if "%ICO_FILE%"=="" (
    pyinstaller -F !WINDOW_MODE! !EXTRA_ARGS! --distpath "%TARGET_DIR%" --workpath "%TARGET_DIR%\build" --specpath "%TARGET_DIR%" "%PY_FILE%"
) else (
    pyinstaller -F !WINDOW_MODE! --icon="%UNIQUE_ICON_NAME%" --add-data "%UNIQUE_ICON_NAME%;." !EXTRA_ARGS! --distpath "%TARGET_DIR%" --workpath "%TARGET_DIR%\build" --specpath "%TARGET_DIR%" "%PY_FILE%"
)

:: 🌟 毀屍滅跡：打包完畢後 把暫時產生的改名圖示刪除 保持環境乾淨
if exist "%UNIQUE_ICON_NAME%" del "%UNIQUE_ICON_NAME%"

echo/
echo ==========================================
echo    🎉 打包大功告成！
echo    你的 EXE 已經安穩地放在【%TARGET_DIR%】資料夾裡面了！
echo ==========================================
pause
endlocal
goto :eof

:: ------------------------------------------
:: 子程序：偵測套件，有用到才加 --collect-all
:: 參數 %1=套件名  %2=顯示名稱
:: ------------------------------------------
:DetectCollectAll
findstr /I /C:"import %~1" /C:"from %~1" "%PY_FILE%" >nul 2>&1
if not errorlevel 1 (
    echo    ✅ 偵測到 %~2 → 一併打包完整資源 (--collect-all %~1)
    set "EXTRA_ARGS=!EXTRA_ARGS! --collect-all %~1"
    set "HAS_HEAVY=1"
)
goto :eof
