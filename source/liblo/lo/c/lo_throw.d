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

module lo.c.lo_throw;
public import lo.c.lo_types;

extern(C):

void lo_throw(lo_server s, int errnum, const(char) *message, const(char) *path);

/*! Since the liblo error handler does not provide a context pointer,
 *  it can be provided by associating it with a particular server
 *  through this thread-safe API. */

void *lo_error_get_context();

void lo_server_set_error_context(lo_server s, void *user_data);
