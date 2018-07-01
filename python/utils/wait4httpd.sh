#!/bin/bash
# Copyright (c) 2018 HarryR. All Rights Reserved.
# SPDX-License-Identifier: GPL-3.0+
# Waits until a HTTP server is up and running

if [[ -z "$1" ]]; then
	echo "Usage: `basename $0` <http-url>"
	exit 1
fi

while true; do
	curl "$1" &> /dev/null
	if [[ $? -eq 0 ]]; then
		exit 0
	fi
done