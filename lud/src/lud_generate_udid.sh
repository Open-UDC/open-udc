#!/bin/bash
# -*- mode: sh; tabstop: 4; shiftwidth: 4; softtabstop: 4; -*-

. ${0%/*}/uset.env
UDinit
. ugenid.env
UDgenudid "$@"
