# SignapkTools

APK/ZIP/JAR 测试签名工具，支持 Windows、Linux 和 macOS。共用仓库中原有的 Java 签名器，支持中文、空格路径和自定义输出。默认输出同目录 `pwelyn_原文件名`，不会覆盖已有文件；失败返回非零退出码并清理临时输出。

## Linux / macOS

需要 PATH 中可用的 Java（推荐 OpenJDK 21）和 Python 3.9+，不需要 PowerShell。下载或克隆整个仓库，保持 JAR、密钥和脚本在同一目录：

```sh
./signapk.sh '/path/to/my app.zip'
./signapk.sh '/path/to/my app.zip' '/path/to/signed.zip'
# 也可以直接使用 Python 入口
python3 signapk.py '/path/to/my app.apk' '/path/to/signed.apk'
```

如果下载 ZIP 后丢失执行权限，先运行 `chmod +x signapk.sh`。可用 `SIGNAPK_PYTHON=/path/to/python3` 指定 Python。输出目录必须存在、可写且位于支持硬链接的文件系统（例如 ext4、APFS）上，以原子方式生成结果；不需要系统安装，也不会添加文件管理器右键菜单。用 `java -version` 和 `python3 --version` 检查依赖。

## Windows

需要 Windows PowerShell 5.1+ 和 PATH 中可用的 Java（推荐 OpenJDK 21）。

双击 `Install.cmd` 安装到 `%LOCALAPPDATA%\SignapkTools`，仅为当前用户添加 APK/ZIP 右键菜单，无需管理员权限。Windows 11 可能需要先点“显示更多选项”。双击 `Uninstall.cmd` 卸载本版本，保留目录中的其他文件。

无需安装也可在 PowerShell 中运行：

```powershell
.\Sign.ps1 -InputFile 'C:\Files\my app.zip'
.\Sign.ps1 -InputFile 'C:\Files\my app.zip' -OutputFile 'C:\Files\signed.zip'
```

输出目录必须存在且可写。设置 `SIGNAPK_NO_PAUSE=1` 关闭批处理暂停。安装 Python 3.9+ 后也能使用 `python signapk.py INPUT [OUTPUT]`。

批处理和右键菜单为各自启动的 PowerShell 进程指定 `-ExecutionPolicy Bypass`，不修改系统或用户的持久执行策略；组织组策略仍优先。如果组织政策阻止运行，请按要求使用签名脚本。直接调用 `.ps1` 时也受当前执行策略约束。旧版本写入 System32/HKCR，请先用旧版卸载脚本以管理员权限卸载；新版不会删除旧版系统级安装。

## 签名限制

附带私钥是**公开测试密钥，不能用于正式发布**。保留原始 JAR 和密钥，使用与旧版一致的 `-w` 传统 JAR/v1 和 whole-file 签名。它不提供 APK v2/v3/v4 或 zipalign，不能保证现代 Android 设备安装成功。现代 APK 发布应使用 Android SDK 的 `apksigner`、`zipalign` 和自己的发布密钥。

## 验证

仓库没有 Java 源码或构建流程。测试需要 Java、Python 3.9+ 和 OpenSSL：

```sh
python3 tests/smoke.py                    # Linux/macOS shell 入口
python3 tests/smoke.py --backend python  # Python 入口，支持三平台
```

Windows 使用 `python tests/smoke.py --backend powershell`，需要 PowerShell；可用 `SIGNAPK_POWERSHELL` 指定路径。OpenSSL 不在 PATH 中时可用 `SIGNAPK_OPENSSL` 指定。macOS 可使用 Homebrew 的 OpenSSL 3。

测试检查中文/空格路径、内容完整性、密码学签名、篡改检测、防覆盖、默认输出、缺失依赖及错误输入清理。自签测试证书仅跳过信任链检查，保留密码学签名验证。GitHub Actions 配置了 Linux、macOS、Windows 三平台测试，Windows 另检查当前用户注册表安装/卸载；Explorer 菜单交互仍需 Windows 实机验证。
