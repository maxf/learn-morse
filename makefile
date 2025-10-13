##
# Project Title
#
# @file
# @version 0.1

dist/elm.js: src/Main.elm
	npx elm make src/Main.elm --output=dist/elm.js

prepare-template:
	cp dist/index.html dist/index.html.template || true

init-terraform:
	terraform init -upgrade

deploy: dist/elm.js prepare-template
	terraform apply

# end
