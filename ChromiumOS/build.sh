#!/usr/bin/env bash
if [ ${USER} == "kaendfinger" ]
then
  cd ~/chromiumos
  ./build.sh ${BOARD} ${BOARD_ARCH}
else
  sudo -u kaendfinger ${0}
fi
