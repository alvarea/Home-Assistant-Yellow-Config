#! /bin/bash

WGET="/usr/bin/wget"

$WGET -q --tries=20 --timeout=10 http://www.google.com -O /tmp/google.idx &> /dev/null
if [ ! -s /tmp/google.idx ]
then
  echo "Down"
else
  echo "Up"
  rm -f /tmp/google.idx
fi