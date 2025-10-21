#!/bin/bash

SHELL_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
cd $SHELL_SCRIPT_DIR/..

ast-grep scan --rule ast-grep/.workshop-prepare-code/rewrite-lit-deps-to-v3.yml --update-all
yarn install
