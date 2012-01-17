#!/bin/bash

coffee --compile --output ./static/lib/  main.coffee
DEPLOY_DIR=../socrenchus-deploy/
mkdir $DEPLOY_DIR
cp handlers.py $DEPLOY_DIR
cp rpc.py $DEPLOY_DIR
cp database.py $DEPLOY_DIR
cp json.py $DEPLOY_DIR
cp app.yaml $DEPLOY_DIR
cp -r templates $DEPLOY_DIR
cp -r static $DEPLOY_DIR
cp -r ndb $DEPLOY_DIR
java -jar ~/Downloads/compiler-latest/compiler.jar --js static/lib/main.js --js_output_file ../socrenchus-deploy/static/lib/main.js
