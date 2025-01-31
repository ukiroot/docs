#!/bin/bash

set -o xtrace
set -o verbose
set -o errexit

export PYTHONDONTWRITEBYTECODE=1
export PYTHONPATH=./docs_stdlib/:$PYTHONPATH
python3 -m venv .docs_venv
source .docs_venv/bin/activate
pip3 install -r requirements.txt

pytest -m ${1:-mvt}
