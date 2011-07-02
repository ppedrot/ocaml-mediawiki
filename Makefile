# $Id: Makefile

OCAMLLIB=/usr/lib/ocaml/

OCAMLYACC=ocamlyacc
OCAMLC=ocamlfind ocamlc
OCAMLOPT=ocamlfind ocamlopt
OCAMLDEP=ocamlfind ocamldep
OCAMLMKLIB=ocamlfind ocamlmklib
OCAMLDOC=ocamlfind ocamldoc

INCLUDES=-I tools -I api

SYNTAX=camlp4o
PACKAGES=threads expat pcre netstring netclient netcgi2 zip

# LIB=zip.cma expat.cma unix.cma pcre.cma equeue.cma netsys.cma netstring.cma netcgi.cma netclient.cma

OCAMLFLAGS=$(INCLUDES) -thread -w s $(addprefix -package , $(PACKAGES))
OCAMLOPTFLAGS=$(INCLUDES) -thread -w s $(addprefix -package , $(PACKAGES))
OCAMLYACCFLAGS=
OCAMLDEPFLAGS=$(INCLUDES)
OCAMLMKLIBFLAGS=$(INCLUDES)

# SOURCE = tools/cookie.cmo tools/netgzip.cmo tools/xml.cmo
# API_EXPORTED = api/call.cmo api/datatypes.cmi api/utils.cmo api/make.cmo api/options.cmo api/site.cmo api/login.cmo api/prop.cmo api/enum.cmo api/edit.cmo api/misc.cmo api/meta.cmo

INTERFACE=tools/xml.mli api/call.mli api/datatypes.mli api/utils.mli api/site.mli api/login.mli api/prop.mli api/enum.mli api/edit.mli api/misc.mli api/meta.mli

OBJS=tools/cookie.cmo tools/netgzip.cmo tools/xml.cmo api/call.cmo api/datatypes.cmi api/utils.cmo api/make.cmo api/options.cmo api/site.cmo api/login.cmo api/prop.cmo api/enum.cmo api/edit.cmo api/misc.cmo api/meta.cmo

OPTOBJS=$(patsubst %.cmo,%.cmx, $(OBJS))

CMOS=$(filter %.cmo,$(OBJS))
CMXS=$(patsubst %.cmo,%.cmx, $(CMOS))


INSTALLED=META mediawiki.cmi mediawiki.cma mediawiki.cmxa mediawiki.a

# OSOURCE=$(patsubst %.cmo,%.cmx,$(SOURCE))
# OAPI_EXPORTED=$(patsubst %.cmo,%.cmx, $(API_EXPORTED))

# Common rules
.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(OCAMLC) $(OCAMLFLAGS) -for-pack Mediawiki -c $<

.mli.cmi:
	$(OCAMLC) $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -for-pack Mediawiki -c $<

all: dep runlib optlib

run: $(OBJS)

runlib: run mediawiki.cmi
	$(OCAMLC) $(OCAMLFLAGS) -pack $(OBJS) -o mediawiki.cmo
	$(OCAMLC) $(OCAMLFLAGS) -a mediawiki.cmo -o mediawiki.cma

opt: $(OPTOBJS)

optlib: opt mediawiki.cmi 
	$(OCAMLOPT) $(OCAMLFLAGS) -pack $(OPTOBJS) -o mediawiki.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -a $(CMXS) -o mediawiki.cmxa

dep:
	$(OCAMLDEP) $(OCAMLDEPFLAGS) $(shell find . -name "*.ml") $(shell find . -name "*.mli") > .depend

yacc:

clean:
	rm -f mediawiki.mli mediawiki.cmi mediawiki.cma mediawiki.cmxa mediawiki.a
	rm -rf $(shell find . -name "*.cm[aoix]*") $(shell find . -name "*.o")

install:
	mkdir -p $(OCAMLLIB)/mediawiki
	cp  $(INSTALLED) $(OCAMLLIB)/mediawiki

mediawiki.mli:
	ocaml make_interface.ml $(INTERFACE)

include .depend 
