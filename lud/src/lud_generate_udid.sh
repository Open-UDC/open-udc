#!/bin/bash
# -*- mode: sh; tabstop: 4; shiftwidth: 4; softtabstop: 4; -*-

. ${0%/*}/lud_set.env
lud_init
. lud_generator.env
lud_generator_udid "$@"
