#!/bin/bash

SHELL_SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
cd $SHELL_SCRIPT_DIR/..

ast-grep scan --rule ast-grep/.workshop-prepare-code/remove-plugins-from-tsconfig-json.yml --update-all
ast-grep scan --rule ast-grep/.workshop-prepare-code/remove-property-decorator-type-when-boolean.yml --update-all
ast-grep scan --rule ast-grep/.workshop-prepare-code/remove-property-decorator-attribute-when-string.yml --update-all
yarn pretty-quick
