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

::

    $ git clone https://github.com/Open-UDC/open-udc.git
    $ cd open-udc
    $ git submodule init
    $ git submodule update


Install *lud* :

::

    $ cd lud
    $ sudo make install

Now ``/usr/local/bin/lud.sh`` is installed.

::

    $ /usr/local/bin/lud.sh
    lud.sh:Warning: Using versions 2.x of GnuPG is recommanded (only "1.4.12" is installed here).
    gpg: directory `/home/vagrant/.gnupg' created
    gpg: new configuration file `/home/vagrant/.gnupg/gpg.conf' created
    gpg: WARNING: options in `/home/vagrant/.gnupg/gpg.conf' are not yet active during this run
    gpg: keyring `/home/vagrant/.gnupg/secring.gpg' created
    gpg: keyring `/home/vagrant/.gnupg/pubring.gpg' created
    gpg: /home/vagrant/.gnupg/trustdb.gpg: trustdb created

    lud.sh:Warning: No private key found here.

     Have you already an OpenPGP certificate to import on this machine (y/n) ?

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
