#!/usr/bin/env python2

#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Authors:
# Caner Candan <caner@candan.fr>, http://caner.candan.fr
#

import time, sys, os
from pyme import errors, core
from pyme.core import Context, Data, pubkey_algo_name
from pyme.constants import validity, status, keylist, sig, sigsum

def load_keys():
    "Download keys from the keyring"
    context = Context()
    sec_keys = {}
    for key in context.op_keylist_all(None, 1):
        sec_keys[key.subkeys[0].fpr] = 1
    # print sec_keys
    context.set_keylist_mode(keylist.mode.SIGS)
    for key in context.op_keylist_all(None, 0):
        secret = sec_keys.has_key(key.subkeys[0].fpr)
        # print key, secret
        if key.can_encrypt: print key

if __name__ == '__main__':
    print 'main'
    load_keys()
