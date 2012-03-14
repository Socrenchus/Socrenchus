#!/bin/bash

coffee --compile --output ./client/static/lib/  ./client/main.coffee
DEPLOY_DIR=../socrenchus-deploy/
mkdir $DEPLOY_DIR
cp handlers.py $DEPLOY_DIR
cp rpc.py $DEPLOY_DIR
cp database.py $DEPLOY_DIR
cp json.py $DEPLOY_DIR
cp app.yaml $DEPLOY_DIR
cp -r templates $DEPLOY_DIR
cp -r static $DEPLOY_DIR
java -jar ~/Downloads/compiler-latest/compiler.jar --js ./client/static/lib/main.js --js_output_file ../socrenchus-deploy/client/static/lib/main.js
