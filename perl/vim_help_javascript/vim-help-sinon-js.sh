#! /usr/bin/env sh

# Creates sinon.js vim-help file

git clone https://github.com/sinonjs/sinon.git
cat sinon/docs/_releases/v3.2.1.md sinon/docs/_releases/v3.2.1/*.md > sinon_bundle.md
vim-markdown-helpfile/bin/vim-helpfile --name sinon sinon_bundle.md > doc/vim-help-sinon-js.txt

