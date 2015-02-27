
@CLS
@ECHO on
@CLS
@PUSHD %~dp0

@TITLE (APK ZIP签名功能) 右键菜单卸载工具

@ECHO.
@ECHO  开始卸载右键...
@ECHO.

@IF EXIST %SystemRoot%\system32\signapk.jar (del /F /Q %SystemRoot%\system32\signapk.jar)

@IF EXIST %SystemRoot%\system32\testkey.x509.pem (del /F /Q %SystemRoot%\system32\testkey.x509.pem)

@IF EXIST %SystemRoot%\system32\testkey.pk8 (del /F /Q %SystemRoot%\system32\testkey.pk8)

@IF EXIST %SystemRoot%\system32\singapk.cmd (del /F /Q %SystemRoot%\system32\singapk.cmd)

@REG DELETE "HKCR\*\shell\Android 签名工具" /f >nul 2>nul

@ECHO.
@ECHO  卸载右键完成！
@ECHO.

@PAUSE
@POPD
@EXIT

@CLS
REM @ECHO off
@CLS
@PUSHD %~dp0


pause
@POPD
@EXIT
