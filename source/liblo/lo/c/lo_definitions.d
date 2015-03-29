/*
 *  Copyright (C) 2014 Steve Harris et al. (see AUTHORS)
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public License
 *  as published by the Free Software Foundation; either version 2.1
 *  of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  $Id$
 */

module lo.c.lo_definitions;

extern(C):

/* macros that have to be defined after function signatures */

/* \brief Maximum length of UDP messages in bytes
 */
enum LO_MAX_MSG_SIZE = 32768;

/* \brief A set of macros to represent different communications transports
 */
enum LO_DEFAULT = 0x0;
enum LO_UDP     = 0x1;
enum LO_UNIX    = 0x2;
enum LO_TCP     = 0x4;

/* an internal value, ignored in transmission but check against LO_MARKER in the
 * argument list. Used to do primitive bounds checking */
enum LO_MARKER_A = cast(void *)0xdeadbeefdeadbeefL;
enum LO_MARKER_B = cast(void *)0xf00baa23f00baa23L;
