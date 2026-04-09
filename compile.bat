@echo off
chcp 65001 >nul
title Claude Code Rust - 编译脚本

echo ========================================
echo    Claude Code Rust - 编译脚本
echo ========================================
echo.

echo [准备工作] 设置 MSYS2 MinGW 环境...
set "PATH=C:\msys64\mingw64\bin;%PATH%"
set "CC=gcc"
set "CXX=g++"

echo       添加 Rust GNU 目标（如果尚未添加）...
rustup target add x86_64-pc-windows-gnu >nul 2>&1

echo.
echo [1/4] 清除旧编译产物...
cargo clean 2>nul
echo.

echo [2/4] 编译 Release 版本（主程序 claude-code）...
cargo build --release --target x86_64-pc-windows-gnu --bin claude-code
if errorlevel 1 (
    echo [错误] 主程序编译失败
    pause
    exit /b 1
)
echo       主程序编译成功
echo.

echo [3/4] 编译 GUI 版本（claude-code-gui）...
cargo build --release --target x86_64-pc-windows-gnu --bin claude-code-gui --features gui-egui
if errorlevel 1 (
    echo [警告] GUI 编译失败，可继续使用 CLI 版本
) else (
    echo       GUI 编译成功
)
echo.

echo [4/4] 复制可执行文件到根目录...
copy /Y "target\x86_64-pc-windows-gnu\release\claude-code.exe" "claude-code.exe" >nul
if exist "target\x86_64-pc-windows-gnu\release\claude-code-gui.exe" (
    copy /Y "target\x86_64-pc-windows-gnu\release\claude-code-gui.exe" "claude-code-gui.exe" >nul
    echo       GUI 版本也已复制
)
echo.

echo ========================================
echo    编译完成！
echo ========================================
echo.
echo 输出文件:
echo   - claude-code.exe    (CLI 命令行工具)
echo   - claaude-code-gui.exe (可选，GUI 桌面版)
echo.
echo 使用方法:
echo   claude-code.exe --help           查看帮助
echo   claude-code.exe repl             进入交互模式
echo   claude-code.exe "你的问题"       单次提问
echo.
pause
