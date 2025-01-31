import sys
import os

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../../../docs_stdlib')))
from base import pytest
import base

@pytest.mark.bootstrap
def test_bash_script():
    base.bash_script(os.path.dirname(__file__))
