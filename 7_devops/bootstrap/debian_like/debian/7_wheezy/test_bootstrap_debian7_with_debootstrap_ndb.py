import sys
import os
from base import pytest
import base


@pytest.mark.bootstrap
@pytest.mark.dependency(name="deploy_debian7")
def test_bash_script():
    base.bash_script(os.path.dirname(__file__))

@pytest.mark.dependency(depends=["deploy_debian7"])
def test_smoke_run():
    assert True
