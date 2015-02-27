
@CLS
@ECHO on
@CLS
@PUSHD %~dp0

@TITLE (APK ZIP签名功能) 右键菜单添加工具

@ECHO.
@ECHO  开始添加右键...
@ECHO.

@IF EXIST %SystemRoot%\system32\signapk.jar (del /F /Q %SystemRoot%\system32\signapk.jar)
@COPY /V /Y .\signapk.jar %SystemRoot%\system32\

@IF EXIST %SystemRoot%\system32\testkey.x509.pem (del /F /Q %SystemRoot%\system32\testkey.x509.pem)
@COPY /V /Y .\testkey.x509.pem %SystemRoot%\system32\

@IF EXIST %SystemRoot%\system32\testkey.pk8 (del /F /Q %SystemRoot%\system32\testkey.pk8)
@COPY /V /Y .\testkey.pk8 %SystemRoot%\system32\

@IF EXIST %SystemRoot%\system32\singapk.cmd (del /F /Q %SystemRoot%\system32\singapk.cmd)
@COPY /V /Y .\singapk.cmd %SystemRoot%\system32\

@REG ADD "HKCR\*\shell\Android 签名工具\command" /v "" /t REG_SZ /d "%SystemRoot%\system32\singapk.cmd \"%%1\"" /f >nul 2>nul

@ECHO.
@ECHO  添加右键完成！
@ECHO.

@PAUSE
@POPD
@EXIT
