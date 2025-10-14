##
# Project Title
#
# @file
# @version 0.1

dist/elm.js: src/Main.elm
	npx elm make src/Main.elm --output=dist/elm.js

init-terraform:
	terraform init -upgrade

deploy: dist/elm.js
	sed -i "s/<timestamp: [^>]*>/<timestamp: $$(date -u +"%Y-%m-%d %H:%M:%S UTC")>/g" dist/index.html                                                                                                                                                                                                
	terraform apply

# end
