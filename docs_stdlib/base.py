import subprocess
import pytest
import os


def bash_script(dir_path):
    cmd = 'cd {};sudo bash -c "/usr/bin/time -v bash {} &>/dev/stdout"'
    for file_name in os.listdir(dir_path):
        if ".bash" in file_name:
            print(file_name)
            break
    print(file_name)
    result = subprocess.run(
        cmd.format(dir_path, file_name),
        shell=True,
        capture_output=True,
        text=True,
        errors='ignore'  # Ignore characters that can't be decoded
    )
    print(result.stdout)
    assert result.returncode == 0
