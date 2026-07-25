@echo off
chcp 65001 >nul
title 萬用打包神器 

echo ==========================================
echo    🚀 萬用 PyInstaller 拖曳打包神器 (單一資源極速版)
echo ==========================================
echo.

set /p PY_FILE="1. 請把你要打包的 Python 檔案【拖曳】到這個黑視窗裡，然後按 Enter："
echo.
set /p ICO_FILE="2. 請把你的 .ico 萬用圖示【拖曳】進來 (沒有請直接按 Enter 跳過)："

:: 去除 Windows 拖曳檔案時自動加上的雙引號
set PY_FILE=%PY_FILE:"=%
set ICO_FILE=%ICO_FILE:"=%

:: 自動抓取你的 Python 檔名，用來建立專屬資料夾
for %%F in ("%PY_FILE%") do set PROJECT_NAME=%%~nF
set TARGET_DIR=打包成品_%PROJECT_NAME%

echo.
echo ==========================================
echo    🧹 正在為 %PROJECT_NAME% 清理舊環境...
echo ==========================================
rmdir /s /q "%TARGET_DIR%" 2>nul

echo.
echo ==========================================
echo    ⚡ 開始執行打包作業，請稍候...
echo ==========================================

:: 判斷有沒有拖曳圖示進來，決定要跑哪一段打包指令
if "%ICO_FILE%"=="" (
    pyinstaller -F -w --collect-all selenium --distpath "%TARGET_DIR%" --workpath "%TARGET_DIR%\build" --specpath "%TARGET_DIR%" "%PY_FILE%"
) else (
    pyinstaller -F -w --icon="%ICO_FILE%" --add-data "%ICO_FILE%;." --collect-all selenium --distpath "%TARGET_DIR%" --workpath "%TARGET_DIR%\build" --specpath "%TARGET_DIR%" "%PY_FILE%"
)

echo.
echo ==========================================
echo    🎉 打包大功告成！
echo    你的 EXE 已經安穩地放在【%TARGET_DIR%】資料夾裡面了！
echo ==========================================
pause