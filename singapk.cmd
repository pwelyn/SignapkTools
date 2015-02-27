


@CLS
@ECHO off
@TITLE APK ZIP签名工具
@CLS
@PUSHD %~dp0

@SET sjar=%~dp0signapk.jar
@SET tpem=%~dp0testkey.x509.pem
@SET tpk8=%~dp0testkey.pk8

@ECHO.
@ECHO  开始对 %~nx1 进行签名...
@java -jar %sjar% -w %tpem% %tpk8% %~1 %~dp1pwelyn_%~nx1
@if errorlevel 1 (
    @ECHO.
    @ECHO  签名错误！
    @PAUSE
    @EXIT
)
@ECHO.
@ECHO  签名完成！
@ECHO.

@PAUSE
@POPD
@EXIT
