import subprocess
import pytest
import os

@pytest.mark.bootstrap
@pytest.mark.bootstrap_redhat_like
def test_bootstrap():
    current_path = os.path.dirname(__file__)
    result = subprocess.run(
        'cd {}; sudo bash `ls -1 | grep bash`'.format(current_path),
        shell=True,
        capture_output=True,
        text=True,
        errors='ignore'  # Ignore characters that can't be decoded
    )
    assert result.returncode == 0
