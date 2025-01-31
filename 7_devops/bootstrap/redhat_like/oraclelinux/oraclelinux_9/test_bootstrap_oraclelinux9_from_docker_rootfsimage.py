import sys
import os
from base import pytest
import base


@pytest.mark.bootstrap
def test_bash_script():
    base.bash_script(os.path.dirname(__file__))
