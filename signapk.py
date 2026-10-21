#!/usr/bin/env python3
"""Portable command-line wrapper for the bundled legacy Java signer."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def sign(input_file, output_file=None):
    source = Path(input_file).absolute()
    if not source.is_file():
        raise ValueError(f'Input must be an existing file: {source}')
    if source.suffix.lower() not in ('.apk', '.zip', '.jar'):
        raise ValueError('Supported inputs: .apk, .zip, .jar')
    output = Path(output_file).absolute() if output_file else source.with_name('pwelyn_' + source.name)
    # lexists also rejects broken symlinks, which must never be followed or replaced.
    if os.path.lexists(output):
        raise ValueError(f'Output already exists; choose another path: {output}')
    if not output.parent.is_dir():
        raise ValueError(f'Output directory does not exist: {output.parent}')
    java = shutil.which('java')
    if not java:
        raise ValueError('Java not found. Install a Java runtime and add java to PATH.')
    root = Path(__file__).resolve().parent
    dependencies = [root / name for name in ('signapk.jar', 'testkey.x509.pem', 'testkey.pk8')]
    for dependency in dependencies:
        if not dependency.is_file():
            raise ValueError(f'Missing dependency: {dependency}')
    # Use the output filesystem so a hard link can publish the result atomically.
    # A racing writer or symlink cannot cause an existing destination to be replaced.
    with tempfile.TemporaryDirectory(prefix='.signapk-', dir=output.parent) as temporary:
        signed = Path(temporary) / 'signed.zip'
        result = subprocess.run([java, '-jar', str(dependencies[0]), '-w',
                                 str(dependencies[1]), str(dependencies[2]), str(source), str(signed)])
        if result.returncode:
            raise ValueError(f'Signing failed (Java exit code {result.returncode}).')
        os.link(signed, output)
    print(f'Signed: {output}')


def main():
    # Windows redirected consoles may use an encoding without Chinese characters.
    # Reporting a completed signature must not turn success into an encoding error.
    sys.stdout.reconfigure(errors='backslashreplace')
    sys.stderr.reconfigure(errors='backslashreplace')
    parser = argparse.ArgumentParser(description='Sign APK/ZIP/JAR with the bundled public test key (legacy signatures).')
    parser.add_argument('input', help='input APK, ZIP, or JAR')
    parser.add_argument('output', nargs='?', help='output path; default: pwelyn_<input name>')
    args = parser.parse_args()
    try:
        sign(args.input, args.output)
    except (OSError, ValueError) as error:
        print(f'Error: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
