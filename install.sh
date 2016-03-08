#!/bin/bash

RELEASE="rt-4.4.0"

FEATURES="--enable-graphviz --enable-gd"
WEB_USER=nginx
WEB_GROUP=nginx
PREFIX=/opt/rt4

wget https://download.bestpractical.com/pub/rt/release/${RELEASE}.tar.gz
tar xzvf ${RELEASE}.tar.gz
cd ${RELEASE}

./configure ${FEATURES} --with-web-user=${WEB_USER} --with-web-group=${WEB_GROUP} --prefix=${PREFIX}
make fixdeps
make install

