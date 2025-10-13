##
# Project Title
#
# @file
# @version 0.1

dist/elm.js: src/Main.elm
	npx elm make src/Main.elm --output=dist/elm.js

deploy: dist/elm.js
	terraform apply

# end
