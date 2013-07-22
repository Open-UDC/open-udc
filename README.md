=======
OpenUDC
=======

What does OpenUDC mean ?
========================

**[OpenUDC] (http://openudc.org)** means Open Universal Dividend Currency. In other words, it is an open protocol for creating
and exchanging currencies.

It aims to be secure, reliable and to solve some debt, crisis or globalization issues.  
It notably permits to apply Universal monetary Dividend to the individuals that accept to use the currency.  
It is based upon the OpenPGP protocol ([RFC4880] (http://tools.ietf.org/html/rfc4880)).  

About Universal monetary Dividend, please read the [Theory of Money Relativity from Stephane Laborde] (http://www.creationmonetaire.info/2011/06/theorie-relative-de-la-monnaie-20.html) (in french)
or at least other studies about [Social Credit] (http://en.wikipedia.org/wiki/Social_Credit).


Quickstart
==========

The OpenUDC repository contain the documentation, a lot of obsolete files to be cleaned, and as git submodules:
 * ludc, an OpenUDC client (previously known as lud).
 * thttpgpd/ludd, an HTTP server with OpenPGP features, wich may also become an OpenUDC node (cf. configure options).


To get all this from our git repository:
::

    $ git clone https://github.com/Open-UDC/open-udc.git
    $ cd open-udc
    $ git submodule update --init


Note: By default this won't take the last versions of the git submodules ludc/lud and thttpgpd/ludd.

Please read also the README files of the client (lud or ludc directory) and of the node (ludd directory) if you want to use them.


To get only lud/ludc (last developpement version) :
::
    $ git clone https://github.com/Open-UDC/lud

To get only thttpgpd/ludd (last developpement version) :
::
    $ git clone https://github.com/Open-UDC/thttpgpd

Licenses
========

Copyright (c) 2010-2012 The openudc.org team.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

The file 'geolist_ITA' is available under the Creative Commons
Attribution 3.0 License.   It was generated from the IT.zip database
from geonames.org, using the script published [here] (https://bitbucket.org/rev22/geolist-ita-openudc).
