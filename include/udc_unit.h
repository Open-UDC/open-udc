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

#ifndef _TIME_H
#include <time.h>
#endif


typedef struct {
    union {
        uint64_t sn;
        struct {
            uint64_t mult : 4;
            uint64_t ind : 2;
            uint64_t count : 14;
            uint64_t num : 44;
        };
    };
    union {
        uint64_t data1;
        struct {
            uint64_t ud_15_5 : 4;
            uint64_t ud_15_2 : 4;
            uint64_t ud_15_1 : 4;
            uint64_t ud_14_5 : 4;
            uint64_t ud_14_2 : 4;
            uint64_t ud_14_1 : 4;
            uint64_t ud_13_5 : 4;
            uint64_t ud_13_2 : 4;
            uint64_t ud_13_1 : 4;
            uint64_t ud_12_5 : 4;
            uint64_t ud_12_2 : 4;
            uint64_t ud_12_1 : 4;
            uint64_t ud_11_5 : 4;
            uint64_t ud_11_2 : 4;
            uint64_t ud_11_1 : 4;
            uint64_t ud_10_5 : 4;
        };
    };
    union {
        uint64_t data2;
        struct {
            uint64_t ud_10_2 : 4;
            uint64_t ud_10_1 : 4;
            uint64_t ud_09_5 : 4;
            uint64_t ud_09_2 : 4;
            uint64_t ud_09_1 : 4;
            uint64_t ud_08_5 : 4;
            uint64_t ud_08_2 : 4;
            uint64_t ud_08_1 : 4;
            uint64_t ud_07_5 : 4;
            uint64_t ud_07_2 : 4;
            uint64_t ud_07_1 : 4;
            uint64_t ud_06_5 : 4;
            uint64_t ud_06_2 : 4;
            uint64_t ud_06_1 : 4;
            uint64_t ud_05_5 : 4;
            uint64_t ud_05_2 : 4;
        };
    };
    union {
        uint64_t data3;
        struct {
            uint64_t ud_05_1 : 4;
            uint64_t ud_04_5 : 4;
            uint64_t ud_04_2 : 4;
            uint64_t ud_04_1 : 4;
            uint64_t ud_03_5 : 4;
            uint64_t ud_03_2 : 4;
            uint64_t ud_03_1 : 4;
            uint64_t ud_02_5 : 4;
            uint64_t ud_02_2 : 4;
            uint64_t ud_02_1 : 4;
            uint64_t ud_01_5 : 4;
            uint64_t ud_01_2 : 4;
            uint64_t ud_01_1 : 4;
            uint64_t ud_00_5 : 4;
            uint64_t ud_00_2 : 4;
            uint64_t ud_00_1 : 4;
        };
    };
    union {
        uint64_t data4;
        struct {
            uint64_t magic : 8;
            uint64_t totalids : 40;
            uint64_t crc16 : 16;
        };
    };
} udcBill_t ;

typedef struct {
    union {
        uint64_t full;
        struct {
            char ccode[5] ; //currency code
            struct {
                uint8_t version : 4;
                uint8_t position : 1;
                uint8_t unused : 3;
            };
            uint16_t nbBills;
        };
    };
} udcHead_t ;

typedef struct {
        udcHead_t header;
        udcBill_t * bills;
        udcHead_t footer;
} udcUnit_t ;

