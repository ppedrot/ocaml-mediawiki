# $Id: Makefile

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

SOURCE = tools/cookie.cmo tools/netgzip.cmo tools/xml.cmo api/utils.cmo api/options.cmo
API_EXPORTED = api/call.cmo api/datatypes.cmi api/site.cmo api/login.cmo api/prop.cmo api/enum.cmo

OSOURCE=$(patsubst %.cmo,%.cmx,$(SOURCE))
OAPI_EXPORTED=$(patsubst %.cmo,%.cmx, $(API_EXPORTED))

# Common rules
.SUFFIXES: .ml .mli .cmo .cmi .cmx

.ml.cmo:
	$(if $(findstring $@, $(API_EXPORTED)), $(OCAMLC) $(OCAMLFLAGS) -for-pack Mediawiki -c $<, $(OCAMLC) $(OCAMLFLAGS) -c $<)

.mli.cmi:
	$(OCAMLC) $(OCAMLFLAGS) -c $<

.ml.cmx:
	$(if $(findstring $@, $(OAPI_EXPORTED)), $(OCAMLC) $(OCAMLFLAGS) -for-pack Mediawiki -c $<, $(OCAMLC) $(OCAMLFLAGS) -c $<)


all: dep $(SOURCE) $(API_EXPORTED)

lib: all
	$(OCAMLC) $(OCAMLFLAGS) -pack $(API_EXPORTED) -o mediawiki.cmo
	$(OCAMLC) $(OCAMLFLAGS) -a  $(SOURCE) mediawiki.cmo -o mediawiki.cma

opt: dep $(OSOURCE) $(OAPI_EXPORTED)

optlib: opt
	$(OCAMLOPT) $(OCAMLFLAGS) -pack $(OAPI_EXPORTED) -o mediawiki.cmx
	$(OCAMLOPT) $(OCAMLFLAGS) -a  $(OSOURCE) mediawiki.cmx -o mediawiki.cmxa

opt:
	@echo $(OSOURCE)

dep:
	$(OCAMLDEP) $(OCAMLDEPFLAGS) $(shell find . -name "*.ml") $(shell find . -name "*.mli") > .depend

yacc:

clean:
	rm -rf $(shell find . -name "*.cm[aoix]*") $(shell find . -name "*.o")

include .depend 
