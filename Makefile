# $Id: Makefile

OCAMLLIB=/usr/lib/ocaml/

OCAMLYACC=ocamlyacc
OCAMLC=ocamlfind ocamlc
OCAMLOPT=ocamlfind ocamlopt
OCAMLDEP=ocamlfind ocamldep
OCAMLMKLIB=ocamlfind ocamlmklib

INCLUDES=-I tools -I api

SYNTAX=camlp4o
PACKAGES=threads expat pcre netstring netclient netcgi2 zip

# LIB=zip.cma expat.cma unix.cma pcre.cma equeue.cma netsys.cma netstring.cma netcgi.cma netclient.cma

OCAMLFLAGS=$(INCLUDES) -thread -w s $(addprefix -package , $(PACKAGES))
OCAMLOPTFLAGS=$(INCLUDES) -thread -w s $(addprefix -package , $(PACKAGES))
OCAMLYACCFLAGS=
OCAMLDEPFLAGS=$(INCLUDES)
OCAMLMKLIBFLAGS=$(INCLUDES)

SOURCE = tools/cookie.cmo tools/netgzip.cmo tools/xml.cmo api/make.cmo
API_EXPORTED = api/call.cmo api/datatypes.cmi api/utils.cmo api/options.cmo api/site.cmo api/login.cmo api/prop.cmo api/enum.cmo api/edit.cmo api/misc.cmo api/meta.cmo

INSTALLED=META mediawiki.cmi mediawiki.cma mediawiki.cmxa mediawiki.a

OSOURCE=$(patsubst %.cmo,%.cmx,$(SOURCE))
OAPI_EXPORTED=$(patsubst %.cmo,%.cmx, $(API_EXPORTED))

# Common rules
.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(if $(findstring $@, $(API_EXPORTED)), $(OCAMLC) $(OCAMLFLAGS) -for-pack Mediawiki -c $<, $(OCAMLC) $(OCAMLFLAGS) -c $<)

.mli.cmi:
	$(OCAMLC) $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(if $(findstring $@, $(OAPI_EXPORTED)), $(OCAMLOPT) $(OCAMLOPTFLAGS) -for-pack Mediawiki -c $<, $(OCAMLOPT) $(OCAMLOPTFLAGS) -c $<)


all: dep runlib optlib

run: dep $(SOURCE) $(API_EXPORTED)

runlib: run
	$(OCAMLC) $(OCAMLFLAGS) -pack $(API_EXPORTED) -o mediawiki.cmo
	$(OCAMLC) $(OCAMLFLAGS) -a  $(SOURCE) mediawiki.cmo -o mediawiki.cma

opt: dep $(OSOURCE) $(OAPI_EXPORTED)

optlib: opt
	$(OCAMLOPT) $(OCAMLFLAGS) -pack $(OAPI_EXPORTED) -o mediawiki.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -a  $(OSOURCE) mediawiki.cmx -o mediawiki.cmxa

dep:
	$(OCAMLDEP) $(OCAMLDEPFLAGS) $(shell find . -name "*.ml") $(shell find . -name "*.mli") > .depend

yacc:

clean:
	rm -rf $(shell find . -name "*.cm[aoix]*") $(shell find . -name "*.o")

install:
	mkdir -p $(OCAMLLIB)/mediawiki
	cp  $(INSTALLED) $(OCAMLLIB)/mediawiki
# 	for $f in $(INSTALLED) echo $i
# 	chown root:root $(OCAMLLIB)/mediawiki/$(INSTALLED)
# 	chmod 644 $(OCAMLLIB)/mediawiki/$(INSTALLED)

include .depend 
