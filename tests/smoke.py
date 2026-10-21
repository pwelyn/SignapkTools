"""Functional checks of the shipped entry points; outputs stay outside the checkout."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--backend', choices=('shell', 'python', 'powershell'),
                    default='powershell' if os.name == 'nt' else 'shell')
BACKEND = parser.parse_args().backend
PS = os.environ.get('SIGNAPK_POWERSHELL') or shutil.which('powershell.exe') or shutil.which('pwsh')
OPENSSL = os.environ.get('SIGNAPK_OPENSSL') or shutil.which('openssl')
if BACKEND == 'powershell' and not PS:
    raise SystemExit('PowerShell required; set SIGNAPK_POWERSHELL.')
if not OPENSSL:
    raise SystemExit('OpenSSL required; set SIGNAPK_OPENSSL.')


def invoke(*arguments, success=True, cwd=None, launcher=None, env=None):
    if BACKEND == 'powershell':
        command = [PS, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(ROOT / 'Sign.ps1')]
    elif BACKEND == 'python':
        command = [sys.executable, str(ROOT / 'signapk.py')]
    else:
        command = [str(launcher or ROOT / 'signapk.sh')]
    result = subprocess.run(command + [str(arg) for arg in arguments], cwd=cwd,
                            capture_output=True, text=True, encoding='utf-8', errors='replace', env=env)
    assert (result.returncode == 0) == success, result.stdout + result.stderr
    return result


def verify(output, payload, directory):
    with zipfile.ZipFile(output) as archive:
        assert archive.read('payload.txt') == payload
        assert {'META-INF/MANIFEST.MF', 'META-INF/CERT.SF', 'META-INF/CERT.RSA'} <= set(archive.namelist())
    data = output.read_bytes()
    assert data[-4:-2] == b'\xff\xff'
    signature_size = int.from_bytes(data[-6:-4], 'little')
    comment_size = int.from_bytes(data[-2:], 'little')
    signature = directory / 'signature.der'
    content = directory / 'content.bin'
    signature.write_bytes(data[-signature_size:-6])
    content.write_bytes(data[:-comment_size-2])
    command = [OPENSSL, 'cms', '-verify', '-binary', '-inform', 'DER',
               '-in', str(signature), '-content', str(content), '-noverify', '-out', os.devnull]
    subprocess.run(command, check=True, capture_output=True)
    tampered = bytearray(content.read_bytes())
    tampered[0] ^= 1
    content.write_bytes(tampered)
    result = subprocess.run(command, capture_output=True)
    assert result.returncode != 0, 'Tampered content must fail signature verification'


with tempfile.TemporaryDirectory(prefix='signapk space ') as directory:
    path = Path(directory)
    tool = path / '工具 with spaces'
    tool.mkdir()
    for name in ('Sign.ps1', 'signapk.py', 'signapk.sh', 'signapk.jar', 'testkey.pk8', 'testkey.x509.pem'):
        shutil.copy2(ROOT / name, tool / name)
    ROOT = tool
    source, output = path / '测试 input.zip', path / 'signed output.zip'
    payload = b'SignapkTools functional test\n'
    with zipfile.ZipFile(source, 'w') as archive:
        archive.writestr('payload.txt', payload)
    original = source.read_bytes()
    invoke(source, output)
    verify(output, payload, path)
    data = output.read_bytes()
    invoke(source)
    default_output = path / ('pwelyn_' + source.name)
    verify(default_output, payload, path)
    invoke(source, output, success=False)
    assert output.read_bytes() == data
    invoke(source, source, success=False)
    assert source.read_bytes() == original
    invoke(path / 'missing.zip', path / 'missing-out.zip', success=False)
    assert not (path / 'missing-out.zip').exists()
    invoke(source, path / 'missing directory' / 'out.zip', success=False)
    assert not (path / 'missing directory').exists()
    invoke(source, tool, success=False)
    invoke(success=False)
    unsupported = path / 'unsupported.txt'
    unsupported.write_bytes(original)
    invoke(unsupported, path / 'unsupported-out.zip', success=False)
    assert not (path / 'unsupported-out.zip').exists()
    broken = path / 'broken.zip'
    broken.write_text('not a zip')
    invoke(broken, path / 'broken-out.zip', success=False)
    assert not (path / 'broken-out.zip').exists()
    # Dependency errors must not leave output files either.
    key = tool / 'testkey.pk8'
    backup = tool / 'testkey.pk8.backup'
    key.rename(backup)
    try:
        invoke(source, path / 'missing-key-out.zip', success=False)
        assert not (path / 'missing-key-out.zip').exists()
    finally:
        backup.rename(key)
    if BACKEND == 'python':
        environment = os.environ.copy()
        environment['PATH'] = ''
        result = invoke(source, path / 'missing-java-out.zip', success=False, env=environment, cwd=path)
        assert 'Java not found' in result.stderr
        assert not (path / 'missing-java-out.zip').exists()
    expected = {source.name, output.name, 'signature.der', 'content.bin', 'broken.zip',
                tool.name, default_output.name, unsupported.name}
    if os.name != 'nt':
        link = path / 'existing symlink.zip'
        link.symlink_to(path / 'absent.zip')
        invoke(source, link, success=False)
        assert link.is_symlink()
        assert not (path / 'absent.zip').exists()
        expected.add(link.name)
    if BACKEND == 'shell':
        launcher = path / 'sign tool'
        launcher.symlink_to(Path('工具 with spaces') / 'signapk.sh')
        invoke(source.name, 'relative output.zip', cwd=path, launcher=launcher)
        verify(path / 'relative output.zip', payload, path)
        expected.update((launcher.name, 'relative output.zip'))
    assert {p.name for p in path.iterdir()} == expected, 'Unexpected output or leftover temporary files'
print(f'PASS ({BACKEND}): Unicode/space paths, signatures/tampering, default output, no overwrite, invalid input and failure cleanup')
