#!/usr/bin/env bash

set -e

if [ ${USER} == "kaendfinger" ]
then
  cd ~/chromiumos
  ./build.sh ${BOARD}
else
  sudo -u kaendfinger ${0}
fi
