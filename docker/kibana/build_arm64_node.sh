#!/bin/bash
echo $1
echo "[INFO] Using alternative installation with official node binary"
NODE_VERSION=$(grep -oP '"node":\s*"\K[^"]+' /usr/share/kibana/package.json)
NODE_FILE="node-v${NODE_VERSION}-linux-arm64"
echo "Download node version ${NODE_VERSION}"
cd /tmp
curl https://nodejs.org/dist/v${NODE_VERSION}/${NODE_FILE}.tar.gz -O
tar -zxf ${NODE_FILE}.tar.gz
/tmp/${NODE_FILE}/bin/node --version
cp /usr/share/kibana/bin/kibana-plugin /usr/share/kibana/bin/kibana-plugin-node
sed -i "s|^NODE=.*|NODE=\"/tmp/${NODE_FILE}/bin/node\"|"  /usr/share/kibana/bin/kibana-plugin-node
/usr/share/kibana/bin/kibana-plugin-node install $1
rm  -r /tmp/${NODE_FILE} ${NODE_FILE}.tar.gz  /usr/share/kibana/bin/kibana-plugin-node 
