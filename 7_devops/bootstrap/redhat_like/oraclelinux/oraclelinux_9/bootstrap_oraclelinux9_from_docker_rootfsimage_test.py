import subprocess
import pytest
import os

@pytest.mark.bootstrap
def test_current_file_path():
    current_path = os.path.dirname(__file__)
    result = subprocess.run(
        'cd {}; sudo bash `ls -1 | grep bash`'.format(current_path),
        shell=True,
        capture_output=True,
        text=True
    )
    assert result.returncode == 0
