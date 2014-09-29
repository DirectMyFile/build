#!/usr/bin/env bash

open_block() { 
  echo "##teamcity[blockOpened name='${@}']"
}

close_block() {
  echo "##teamcity[blockClosed name='${@}']"
}
