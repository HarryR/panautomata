#!/bin/bash
REALSELF=`realpath $0`
MYDIR=`dirname $REALSELF`
$MYDIR/../node_modules/.bin/truffle debug $*