#!/usr/bin/env bash
set -e

source "$(dirname ${0})/../util/common.sh"

if [ ${USER} == "kaendfinger" ]
then
  cd ~/chromiumos
  echo "##teamcity[blockOpened name='Chromium OS Build System']"
  ./build.sh ${BOARD}
  echo "##teamcity[blockClosed name='Chromium OS Build System']"
else
  sudo -u kaendfinger ${0}
fi
