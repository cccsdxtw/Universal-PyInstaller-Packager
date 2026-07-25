@echo off
chcp 65001 >nul
title 萬用打包神器 

echo ==========================================
echo    🚀 萬用 PyInstaller 拖曳打包神器 (絕對路徑防呆版)
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

echo/
echo ==========================================
echo    ⚡ 開始執行打包作業 請稍候
echo ==========================================

:: 判斷有沒有拖曳圖示進來 決定要跑哪一段打包指令
if "%ICO_FILE%"=="" (
    pyinstaller -F -w --collect-all selenium --distpath "%TARGET_DIR%" --workpath "%TARGET_DIR%\build" --specpath "%TARGET_DIR%" "%PY_FILE%"
) else (
    pyinstaller -F -w --icon="%UNIQUE_ICON_NAME%" --add-data "%UNIQUE_ICON_NAME%;." --collect-all selenium --distpath "%TARGET_DIR%" --workpath "%TARGET_DIR%\build" --specpath "%TARGET_DIR%" "%PY_FILE%"
)

:: 🌟 毀屍滅跡：打包完畢後 把暫時產生的改名圖示刪除 保持環境乾淨
if exist "%UNIQUE_ICON_NAME%" del "%UNIQUE_ICON_NAME%"

echo/
echo ==========================================
echo    🎉 打包大功告成！
echo    你的 EXE 已經安穩地放在【%TARGET_DIR%】資料夾裡面了！
echo ==========================================
pause