#!/bin/bash

. ${0%/*}/uset.env
UDinit
. ugenid.env
UDgenudid "$@"

