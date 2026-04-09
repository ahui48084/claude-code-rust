@echo off
chcp 65001 >nul
set "PATH=C:\msys64\mingw64\bin;%PATH%"

:: 如果没有 .env 文件，自动创建并提示用户配置
if not exist ".env" (
    echo [首次运行] 正在创建 .env 配置文件...
    copy .env.example .env >nul
    echo.
    echo 请编辑 .env 文件，填入你的 ANTHROPIC_API_KEY
    echo.
    notepad .env
    exit /b 1
)

:: 运行主程序，透传所有参数
.\claude-code.exe %*
