/* udc_unit.h
 * Copyright (C) 2010 Jean-Jacques BRUCKER (open-udc@googlegroups.com).
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

typedef struct {
	uint8_t[] pubkey;      // public key of the owner
	time_t date;		   // transaction date
	uint8_t[] signature;   // signature of the previous owner
	sign_chain * next;     // null at the end of the chain
} udcchain_t ;

typedef struct {
	char * cur;             // currency name
	uint8_t version;		// udcunit version
	uint32_t value;			// amount of value in the currency
	uint8_t[8] serial;      // serial number
	time_t cdate;           // creation date
	uint8_t[] csign;        // creation signature
	uint8_t chaine_version; // version of the signature chain
	char * ename;           // emission name (transmitter)
	sign_chain first;       // first owner in the chain
} udcunit_t ;

