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

module lo.c.lo_errors;

extern(C):

enum LO_ENOPATH      = 9901;
enum LO_ENOTYPE      = 9902;
enum LO_UNKNOWNPROTO = 9903;
enum LO_NOPORT       = 9904;
enum LO_TOOBIG       = 9905;
enum LO_INT_ERR      = 9906;
enum LO_EALLOC       = 9907;
enum LO_EINVALIDPATH = 9908;
enum LO_EINVALIDTYPE = 9909;
enum LO_EBADTYPE     = 9910;
enum LO_ESIZE        = 9911;
enum LO_EINVALIDARG  = 9912;
enum LO_ETERM        = 9913;
enum LO_EPAD         = 9914;
enum LO_EINVALIDBUND = 9915;
enum LO_EINVALIDTIME = 9916;
