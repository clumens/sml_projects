# Build the automatically generated FFI glue code for the MySQL backend.
#
# $Id: Makefile,v 1.1 2004/01/04 22:15:43 chris Exp $

FILES = headers/mysql.h
H = LibmysqlH.libh
D = FFI
HF = ../libmysql-h.sml
CF = libmysql.h.cm

$(D)/$(CF): $(FILES)
	ml-nlffigen -include $(HF) -libhandle $(H) -dir $(D) -cmfile $(CF) $^

clean:
	-rm -r $(D) CM
